module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Dict
import FileTree exposing (FileNode(..))
import Html exposing (..)
import Html.Attributes exposing (class, style)
import Http
import List
import MiscView
import Pages.Login exposing (loginView)
import Result exposing (Result(..))
import Routing exposing (Route(..))
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
    }



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Message )
init flags url key =
    ( { key = key
      , route = Routing.parseUrl url
      , loggedIn = True
      , filesState = Loading
      }
    , Http.get
        { url = "/files/list"
        , expect = Http.expectJson GotFiles FileTree.filesDecoder
        }
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

            RootRoute ->
                viewRoot model

            _ ->
                section [ class "hero is-primary is-fullheight" ]
                    [ div [ class "hero-body" ]
                        [ div [ class "container" ]
                            [ div [ class "columns is-centered" ]
                                [ div [ class "column is-5-tablet is-4-desktop is-3-widescreen" ]
                                    []
                                , div [ class "column" ]
                                    [ text ("Hello Elm! You are at: " ++ Routing.show model.route)
                                    , Routing.toLink Routing.RootRoute "Home"
                                    ]
                                ]
                            ]
                        ]
                    ]
        ]
    }


viewRoot : Model -> Html Message
viewRoot model =
    let
        filesState =
            model.filesState
    in
    case filesState of
        Loading ->
            div []
                [ text "Loading..." ]

        FilesError ->
            div []
                [ text "Error loading files" ]

        Success files ->
            renderFiles files


renderFiles : FileNode -> Html Message
renderFiles files =
    ul [] [ renderFile [] ( "", files ) ]


renderFile : List String -> ( String, FileNode ) -> Html Message
renderFile path ( name, node ) =
    case node of
        File file ->
            li [] [ text name ]

        Folder folder ->
            div []
                [ text name
                , folder.children
                    |> Dict.toList
                    |> List.map (renderFile (path ++ [ name ]))
                    |> ul []
                ]



-- MESSAGE


type Message
    = LinkClicked Browser.UrlRequest
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
