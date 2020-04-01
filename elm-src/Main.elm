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
import Routing exposing (ContentId, Route)
import Task
import Time
import Url



-- MODEL


type Model
    = Happy HappyModel
    | Sad String


type alias HappyModel =
    { key : Nav.Key
    , route : Route
    , roots : Routing.Roots
    , files : Files
    , zone : Time.Zone
    }


happyTuple : ( HappyModel, Cmd msg ) -> ( Model, Cmd msg )
happyTuple ( happyModel, cmd ) =
    ( Happy happyModel, cmd )



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
            sadPath msg


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
            Route contentId query

        fetchCmd =
            Files.Requests.metadata
                roots
                (GotInputInode contentId)
                contentId
    in
    ( Happy
        { key = key
        , route = route
        , roots = roots
        , files = Files.none
        , zone = Time.utc
        }
    , Cmd.batch
        [ fetchCmd
        , Task.perform GotZone Time.here
        ]
    )


sadPath : String -> ( Model, Cmd msg )
sadPath msg =
    ( Sad msg
    , Cmd.none
    )



-- VIEW


view : Model -> Document Message
view model =
    case model of
        Happy model_ ->
            happyView model_

        Sad msg ->
            { title = "YaIndex: Error"
            , body = [ h1 [] [ text msg ] ]
            }


happyView : HappyModel -> Document Message
happyView model =
    let
        route =
            model.route

        mainWrapper elements =
            [ main_ [] elements ]
    in
    { title = "Browser"
    , body =
        [ header [] [ MiscView.navbar model.roots ] ]
            ++ mainWrapper
                (contentView
                    model.zone
                    model.roots
                    model.files
                    model.route
                )
    }


type Message
    = LinkClicked Browser.UrlRequest
    | GotZone Time.Zone
    | RouteChanged Url.Url
    | GotInputInode ContentId (Result Http.Error InputInode)



-- UPDATE


update : Message -> Model -> ( Model, Cmd Message )
update message model =
    case model of
        Happy model_ ->
            happyTuple <| happyUpdate message model_

        Sad _ ->
            ( model, Cmd.none )


happyUpdate : Message -> HappyModel -> ( HappyModel, Cmd Message )
happyUpdate message model =
    case message of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    case Routing.parseUrl model.roots url of
                        Just ( newContentId, _ ) ->
                            ( model
                            , Cmd.batch
                                [ Nav.pushUrl model.key (Url.toString url)
                                , Files.Requests.metadata model.roots (GotInputInode newContentId) newContentId
                                ]
                            )

                        Nothing ->
                            ( model, Nav.load <| Url.toString url )

                Browser.External href ->
                    ( model, Nav.load href )

        RouteChanged url ->
            case Routing.parseUrl model.roots url of
                Just ( newContentId, query ) ->
                    ( { model | route = Route newContentId query }
                    , Cmd.none
                    )

                Nothing ->
                    ( model, Nav.load <| Url.toString url )

        GotInputInode inodePath result ->
            case result of
                Ok (UnexploredFolder x) ->
                    ( { model | files = Files.insertAt (UnexploredFolder x) inodePath model.files }
                    , Files.Requests.folder model.roots (GotInputInode inodePath) inodePath
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
