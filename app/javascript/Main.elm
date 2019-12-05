module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import DateFormat
import Dict
import FileTree exposing (FileNode(..))
import Filesize
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Http
import List
import Maybe
import MiscView
import Pages.Login exposing (loginView)
import Platform.Cmd as Cmd
import Result exposing (Result(..))
import Routing exposing (Route(..))
import Task
import Time
import Url



-- MODEL


type FilesState
    = Loading
    | FilesError
    | Success FileTree.FileNode


type alias Model =
    { key : Nav.Key
    , route : Routing.Route
    , loggedIn : Bool
    , filesState : FilesState
    , zone : Time.Zone
    }



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Message )
init flags url key =
    ( { key = key
      , route = Routing.parseUrl url
      , loggedIn = True
      , filesState = Loading
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
    in
    { title = "Browser"
    , body =
        [ MiscView.navbar
        , case route of
            LoginRoute redirect ->
                loginView redirect

            ContentRoute path query ->
                viewContent model.zone model.filesState path query

            _ ->
                section [ class "hero is-primary is-fullheight" ]
                    [ div [ class "hero-body" ]
                        [ div [ class "container" ]
                            [ div [ class "columns is-centered" ]
                                [ div [ class "column is-5-tablet is-4-desktop is-3-widescreen" ]
                                    []
                                , div [ class "column" ]
                                    [ text ("Hello Elm! You are at: " ++ Routing.show model.route)
                                    , Routing.toLink Routing.rootRoute "Home"
                                    ]
                                ]
                            ]
                        ]
                    ]
        ]
    }


loading : Html Message
loading =
    div []
        [ text "Loading..." ]


contentFileNode : FileNode -> Routing.ContentId -> Maybe FileNode
contentFileNode node path =
    -- Should probably switch Maybe with error, but meh
    case ( node, path ) of
        ( _, [] ) ->
            Maybe.Just node

        ( File file, _ ) ->
            Maybe.Nothing

        ( Folder folder, key :: rest ) ->
            case Dict.get key folder.children of
                Maybe.Just child ->
                    contentFileNode child rest

                Maybe.Nothing ->
                    Maybe.Nothing


viewContent : Time.Zone -> FilesState -> Routing.ContentId -> Maybe String -> Html Message
viewContent zone filesState contentId query =
    let
        body =
            case filesState of
                Loading ->
                    loading

                FilesError ->
                    div [ class "content" ]
                        [ text "Error loading files" ]

                Success files ->
                    case contentFileNode files contentId of
                        Maybe.Just fNode ->
                            renderFiles zone fNode contentId query

                        Maybe.Nothing ->
                            div [ class "content" ]
                                [ text "File not found" ]
    in
    div []
        [ nav [ class "breadcrumb is-right" ]
            [ ul []
                {- todo List.map (pathPart ->
                   li []
                   )
                -}
                [ text "todo" ]
            ]
        , body
        ]


lastItem : List a -> Maybe a
lastItem lst =
    case lst of
        [] ->
            Maybe.Nothing

        [ item ] ->
            Maybe.Just item

        _ :: rest ->
            lastItem rest


renderFiles : Time.Zone -> FileNode -> Routing.ContentId -> Maybe String -> Html Message
renderFiles zone files contentId query =
    let
        makeLink : String -> Html Message
        makeLink name =
            Routing.toLink (ContentRoute (contentId ++ [ name ]) Maybe.Nothing) name

        thisItemName =
            Maybe.withDefault "/" (lastItem contentId)
    in
    case files of
        Folder folder ->
            table [ class "table" ]
                [ thead []
                    [ th [] [ text "File" ]
                    , th [] [ text "Size" ]
                    , th [] [ text "Modified" ]
                    ]
                , Dict.toList folder.children
                    |> List.map
                        (\( name, node ) ->
                            let
                                sizeText =
                                    case node of
                                        File file ->
                                            Filesize.format file.size

                                        Folder _ ->
                                            "N/A"

                                modified =
                                    case node of
                                        File file ->
                                            file.modified

                                        Folder fol ->
                                            fol.modified
                            in
                            tr []
                                [ td [] [ makeLink name ]
                                , td [] [ text sizeText ]
                                , td []
                                    [ text
                                        (DateFormat.format
                                            [ DateFormat.yearNumber
                                            , DateFormat.text "-"
                                            , DateFormat.monthFixed
                                            , DateFormat.text "-"
                                            , DateFormat.dayOfMonthFixed
                                            , DateFormat.text " "
                                            , DateFormat.hourMilitaryNumber
                                            , DateFormat.text ":"
                                            , DateFormat.minuteFixed
                                            ]
                                            zone
                                            modified
                                        )
                                    ]
                                ]
                        )
                    |> tbody []
                ]

        File file ->
            div [ class "content is-medium" ]
                [ h1 [ class "title" ]
                    [ text thisItemName ]
                , text
                    ("Last modified: "
                        ++ DateFormat.format
                            [ DateFormat.monthNameAbbreviated
                            , DateFormat.text " "
                            , DateFormat.dayOfMonthSuffix
                            , DateFormat.text ", "
                            , DateFormat.yearNumber
                            , DateFormat.text " "
                            , DateFormat.hourFixed
                            , DateFormat.text ":"
                            , DateFormat.minuteFixed
                            , DateFormat.text " "
                            , DateFormat.amPmLowercase
                            ]
                            zone
                            file.modified
                    )
                , br [] []
                , text ("Size: " ++ Filesize.format file.size)
                ]



--renderFile : List String -> ( String, FileNode ) -> Html Message
--renderFile path ( name, node ) =
--    case node of
--        File file ->
--            li [] [ text name ]
--
--        Folder folder ->
--            if folder.expanded then
--                div []
--                    [ text name
--                    , folder.children
--                        |> Dict.toList
--                        |> List.map (renderFile (path ++ [ name ]))
--                        |> ul []
--                    ]
--
--            else
--                div []
--                    [ text name ]
-- MESSAGE


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
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( { model | route = Routing.parseUrl url }, Cmd.none )

        GotFiles res ->
            case res of
                Ok files ->
                    ( { model | filesState = Success files }, Cmd.none )

                Err _ ->
                    ( { model | filesState = FilesError }, Cmd.none )

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
