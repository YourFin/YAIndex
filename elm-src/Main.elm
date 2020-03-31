module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Dict
import Files exposing (Files, Inode(..), InputInode(..))
import Files.Requests
import Flags exposing (Flags)
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Http
import Json.Decode
import List
import Maybe
import MiscView
import Pages.Content as Content exposing (contentView)
import Platform.Cmd as Cmd
import Result exposing (Result(..))
import Routing exposing (ContentId, Route(..))
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


init : Json.Decode.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Message )
init flagsVal url key =
    let
        flagsRes =
            Flags.decode flagsVal

        roots =
            case flagsRes of
                Ok flags ->
                    Routing.createRoots
                        flags.serverIndex
                        flags.webappRoot
                        url

                Err err ->
                    Err err
    in
    case roots of
        Ok roots_ ->
            happyPath roots_ url key

        Err msg ->
            sadPath msg key


happyPath : Routing.Roots -> Url.Url -> Nav.Key -> ( Model, Cmd Message )
happyPath roots url key =
    let
        ( contentId, query ) =
            -- Admitedly this is /kinda/ a hack,
            -- but the big thing we're worried about when we return a maybe
            -- (contentId, query) is that the query is outside the webapp,
            -- which /should not/ be a problem at the place that served the
            -- damn webapp.
            --
            -- There should probably be a check for that though, as it
            -- slips through the type system right now.
            Maybe.withDefault ( [], Nothing ) <|
                Routing.parseUrl roots url

        route =
            Routing.ContentRoute roots contentId query

        fetchCmd =
            Files.Requests.metadata
                roots
                (GotInputInode contentId)
                contentId
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


sadPath : String -> Nav.Key -> ( Model, Cmd msg )
sadPath msg key =
    ( { key = key
      , route = Routing.Fatal msg
      , files = Files.none
      , zone = Time.utc
      }
    , Cmd.none
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
        case route of
            ContentRoute roots path query ->
                [ header [] [ MiscView.navbar roots ] ]
                    ++ mainWrapper
                        (contentView
                            model.zone
                            roots
                            model.files
                            path
                            query
                        )

            Fatal msg ->
                [ h1 [] [ text msg ] ]
    }


type Message
    = LinkClicked Browser.UrlRequest
    | GotZone Time.Zone
    | RouteChanged Url.Url
    | GotInputInode ContentId (Result Http.Error InputInode)



-- UPDATE


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case model.route of
        Routing.ContentRoute roots contentId _ ->
            happyUpdate message model roots contentId

        Routing.Fatal _ ->
            ( model, Cmd.none )


happyUpdate : Message -> Model -> Routing.Roots -> ContentId -> ( Model, Cmd Message )
happyUpdate message model roots contentId =
    case message of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    case Routing.parseUrl roots url of
                        Just ( newContentId, _ ) ->
                            ( model
                            , Cmd.batch
                                [ Nav.pushUrl model.key (Url.toString url)
                                , Files.Requests.metadata roots (GotInputInode newContentId) newContentId
                                ]
                            )

                        Nothing ->
                            ( model, Nav.load <| Url.toString url )

                Browser.External href ->
                    ( model, Nav.load href )

        RouteChanged url ->
            case Routing.parseUrl roots url of
                Just ( newContentId, query ) ->
                    ( { model | route = Routing.ContentRoute roots newContentId query }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Nav.load <| Url.toString url )

        GotInputInode inodePath result ->
            case result of
                Ok (UnexploredFolder x) ->
                    ( { model | files = Files.insertAt (UnexploredFolder x) inodePath model.files }
                    , Files.Requests.folder roots (GotInputInode inodePath) inodePath
                    )

                Ok inode ->
                    ( { model | files = Files.insertAt inode inodePath model.files }
                    , Cmd.none
                    )

                Err (Http.BadStatus _) ->
                    ( { model | files = Files.markInaccessable inodePath model.files }
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


main : Program Json.Decode.Value Model Message
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = RouteChanged
        , onUrlRequest = LinkClicked
        }
