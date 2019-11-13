module Pages.Login exposing (loginView)

import Html exposing (..)
import Html.Attributes exposing (class, style)
import Routing exposing (Route(..))


loginView : Route -> Html msg
loginView =
    loginForm


loginForm : Route -> Html msg
loginForm _ =
    form [ class "box" ]
        [ div [ class "field" ]
            [ label [ class "label" ] [ text "Username" ]
            , div [ class "control has-icons-left" ]
                [ input
                    [ class "input"
                    , Html.Attributes.type_ "username"
                    , Html.Attributes.placeholder "username"
                    ]
                    []
                , span [ class "icon is-small is-left" ]
                    [ i [ class "fas fa-user" ] [] ]
                ]
            ]
        , div [ class "field" ]
            [ label [ class "label" ] [ text "Password" ]
            , div [ class "control has-icons-left" ]
                [ input
                    [ class "input"
                    , Html.Attributes.type_ "password"
                    , Html.Attributes.placeholder "**********"
                    ]
                    []
                , span [ class "icon is-small is-left" ]
                    [ i [ class "fas fa-lock" ] [] ]
                ]
            ]
        , div [ class "field" ]
            [ button
                [ {--onClick TODO, --}
                  class "button is-success"
                ]
                [ text "Log in" ]
            ]
        ]
