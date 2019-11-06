module Main exposing (..)

import Browser exposing (Document)
import Browser.Navigation as Nav
import Html exposing (Html, h1, text)
import Html.Attributes exposing (style)
import Routing
import Url



-- MODEL


type alias Model =
    { key : Nav.Key
    , route : Routing.Route
    }



-- INIT


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Message )
init flags url key =
    ( { key = key, route = Routing.parseUrl url }, Cmd.none )



-- VIEW


view : Model -> Document Message
view model =
    -- The inline style is being used for example purposes in order to keep this example simple and
    -- avoid loading additional resources. Use a proper stylesheet when building your own app.
    { title = "Browser"
    , body =
        [ h1 [ style "display" "flex", style "justify-content" "center" ]
            [ text ("Hello Elm! You are at: " ++ Routing.show model.route) ]
        ]
    }



{--
body : Model -> Html Message
body model =
--}
-- MESSAGE


type Message
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url



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