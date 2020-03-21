module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Dict
import FileTree exposing (FileNode)
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Http
import List
import Maybe
import MiscView
import Pages.Content as Content exposing (contentView)
import Pages.Login exposing (loginView)
import Platform.Cmd as Cmd
import Result exposing (Result(..))
import Routing exposing (Route(..))
import Task
import Time
import Url



-- MODEL


type alias Model =
    { key : Nav.Key
    , route : Routing.Route
    , loggedIn : Bool
    , filesState : Content.FilesState
    , zone : Time.Zone
    }



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Message )
init flags url key =
    ( { key = key
      , route = Routing.parseUrl url
      , loggedIn = True
      , filesState = Content.Loading
      , zone = Time.utc
      }
    , Cmd.batch
        [ Http.get
            { url = "/files/list"
            , expect = Http.expectJson GotFiles FileTree.filesDecoder
            }
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
                    LoginRoute redirect ->
                        loginView redirect

                    ContentRoute path query ->
                        contentView model.zone model.filesState path query

                    _ ->
                        MiscView.notFoundView
                )
    }


type Message
    = LinkClicked Browser.UrlRequest
    | GotZone Time.Zone
    | UrlChanged Url.Url
    | GotFiles (Result Http.Error FileNode)



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

        UrlChanged url ->
            ( { model | route = Routing.parseUrl url }, Cmd.none )

        GotFiles res ->
            case res of
                Ok files ->
                    ( { model | filesState = Content.Success files }, Cmd.none )

                Err _ ->
                    ( { model | filesState = Content.FilesError }, Cmd.none )

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
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }
