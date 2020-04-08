module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Dict
import Files exposing (Files, Inode(..), InputInode(..))
import Files.Requests
import Flags exposing (Flags)
import FolderView
import Html exposing (..)
import Html.Attributes as Attr exposing (class, style)
import Http
import Json.Decode
import List
import List.Nonempty as NE exposing (Nonempty(..))
import Maybe
import MiscView exposing (ariaHidden, ariaLabel)
import Pages.File
import Platform.Cmd as Cmd
import Result exposing (Result(..))
import Routing exposing (ContentId, Route)
import Task
import Time
import Url
import Util.List as LU
import Util.List.Nonempty as NEU



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


loading : Html msg
loading =
    div []
        [ text "Loading..." ]


contentView : Time.Zone -> Routing.Roots -> Files -> Route -> List (Html Message)
contentView zone roots files route =
    let
        body =
            case Files.at route.contentId files of
                Err Files.Unknown ->
                    loading

                Err Files.Inaccessable ->
                    div [ class "content" ]
                        [ text "Could not find file" ]

                Ok inode ->
                    renderFiles zone roots files inode route

        fullBreadcrumb =
            NEU.appendToNonEmpty (NE.fromElement "Home") route.contentId

        -- [a,b] -> [(a, [a]), (b, [a,b])]
        zipBreadcrumb : Nonempty String -> Nonempty ( String, Nonempty String )
        zipBreadcrumb breadcrumb =
            case breadcrumb of
                NE.Nonempty head [] ->
                    NE.Nonempty ( head, NE.fromElement head ) []

                NE.Nonempty head (next :: tail) ->
                    NE.append
                        (zipBreadcrumb (Nonempty head (NEU.init (Nonempty next tail))))
                        (NE.fromElement ( NEU.last breadcrumb, breadcrumb ))

        zippedBreadcrumb =
            zipBreadcrumb fullBreadcrumb

        breadcrumbContainer item =
            section [ class "breadcrumb-section section" ]
                [ nav [ class "breadcrumb is-left is-medium", ariaLabel "breadcrumbs" ] [ item ]
                ]
    in
    [ breadcrumbContainer
        (ul []
            (zippedBreadcrumb
                |> NE.map
                    (\( item, NE.Nonempty _ path ) ->
                        Routing.contentLink
                            roots
                            path
                            item
                    )
                |> NEU.init
                |> List.map (\item -> li [] [ item ])
                |> (\lst ->
                        lst
                            ++ [ li [ class "is-active" ]
                                    [ a [ Attr.href "#" ]
                                        [ text <| NEU.last fullBreadcrumb ]
                                    ]
                               ]
                   )
            )
        )
    , div [ class "container is-fluid" ] [ body ]
    ]


renderFiles : Time.Zone -> Routing.Roots -> Files -> Inode -> Route -> Html Message
renderFiles zone roots files node route =
    let
        makeHref : String -> Html.Attribute msg
        makeHref name =
            Routing.contentRef roots (route.contentId ++ [ name ])

        thisItemName =
            Maybe.withDefault "/" (LU.last route.contentId)
    in
    case node of
        Folder _ children ->
            FolderView.view roots route children

        File file ->
            Html.map (FileMsg route.contentId) <|
                Pages.File.view roots files route file



-- UPDATE


type Message
    = LinkClicked Browser.UrlRequest
    | GotZone Time.Zone
    | RouteChanged Url.Url
    | GotInputInode ContentId (Result Http.Error InputInode)
    | FileMsg ContentId Pages.File.Msg


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
                    -- TODO: Don't silently fail here
                    ( model, Cmd.none )

        GotZone zone ->
            ( { model | zone = zone }, Cmd.none )

        FileMsg contentId msg ->
            case Files.at model.route.contentId model.files of
                Ok (File file) ->
                    ( { model
                        | files =
                            Files.updateAt (File <| Pages.File.update file msg)
                                contentId
                                model.files
                      }
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )



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
