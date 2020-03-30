module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import ContentId exposing (ContentId)
import Dict
import Files exposing (Files, Inode(..), InputInode(..))
import Files.Requests
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Http
import List
import Maybe
import MiscView
import Pages.Content as Content exposing (contentView)
import Platform.Cmd as Cmd
import Result exposing (Result(..))
import Routing exposing (Route(..))
import Task
import Time
import Url



-- MODEL


type alias Model =
    { key : Nav.Key
    , route : Route
    , files : Files
    , zone : Time.Zone
    }



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Message )
init flags url key =
    let
        route =
            Routing.parseUrl url

        fetchCmd =
            case route of
                ContentRoute contentId _ ->
                    Files.Requests.metadata (GotInputInode contentId) contentId

                PageNotFoundRoute ->
                    Cmd.none
    in
    ( { key = key
      , route = route
      , files = Files.none
      , zone = Time.utc
      }
    , Cmd.batch
        [ fetchCmd
        , Task.perform GotZone Time.here
        ]
    )



-- VIEW


view : Model -> Document Message
view model =
    let
        route =
            model.route

        mainWrapper elements =
            [ main_ [] elements ]
    in
    { title = "Browser"
    , body =
        [ header [] [ MiscView.navbar ] ]
            ++ mainWrapper
                (case route of
                    ContentRoute path query ->
                        contentView model.zone model.files path query

                    _ ->
                        MiscView.notFoundView
                )
    }


type Message
    = LinkClicked Browser.UrlRequest
    | GotZone Time.Zone
    | RouteChanged Route
    | GotInputInode ContentId (Result Http.Error InputInode)



-- UPDATE


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case message of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    if Routing.isElmUrl url then
                        ( model, Nav.pushUrl model.key (Url.toString url) )

                    else
                        ( model, Nav.load <| Url.toString url )

                Browser.External href ->
                    ( model, Nav.load href )

        RouteChanged route ->
            ( { model | route = route }
            , case route of
                ContentRoute contentId _ ->
                    Files.Requests.metadata (GotInputInode contentId) contentId

                _ ->
                    Cmd.none
            )

        GotInputInode contentId result ->
            case result of
                Ok (UnexploredFolder x) ->
                    ( { model | files = Files.insertAt (UnexploredFolder x) contentId model.files }
                    , Files.Requests.folder (GotInputInode contentId) contentId
                    )

                Ok inode ->
                    ( { model | files = Files.insertAt inode contentId model.files }
                    , Cmd.none
                    )

                Err (Http.BadStatus _) ->
                    ( { model | files = Files.markInaccessable contentId model.files }
                    , Cmd.none
                    )

                Err error ->
                    Debug.log "Unhandled http error" ( model, Cmd.none )

        GotZone zone ->
            ( { model | zone = zone }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Message
subscriptions model =
    Sub.none



-- MAIN


main : Program () Model Message
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = RouteChanged << Routing.parseUrl
        , onUrlRequest = LinkClicked
        }
