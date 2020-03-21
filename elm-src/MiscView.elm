module MiscView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Maybe
import Routing


navbar : Html msg
navbar =
    nav [ class "navbar has-shadow is-primary", role "navigation", ariaLabel "main navigation" ]
        [ div [ class "navbar-brand" ]
            [ a [ class "navbar-item", Routing.toHref Routing.rootRoute ]
                [ h1 [] [ strong [] [ text "Browser" ] ] ]
            ]
        ]


role : String -> Attribute msg
role =
    attribute "role"


ariaLabel : String -> Attribute msg
ariaLabel =
    attribute "aria-label"


ariaExpanded : String -> Attribute msg
ariaExpanded =
    attribute "aria-expanded"


ariaHidden : Attribute msg
ariaHidden =
    attribute "aria-hidden" "true"


dataTarget : String -> Attribute msg
dataTarget =
    attribute "data-target"


notFoundView : List (Html msg)
notFoundView =
    [ section [ class "hero is-fullheight" ]
        [ div [ class "hero-body" ]
            [ div [ class "container" ]
                [ div [ class "columns is-centered" ]
                    [ div [ class "column is-5-tablet is-4-desktop is-3-widescreen" ]
                        []
                    , div [ class "column" ]
                        [ h1 [ class "title is-1 is-centered" ] [ text "Not found :(" ]
                        , h1 [ class "subtitle is-3 is-centered" ]
                            [ text "This page doesn't exist" ]
                        ]
                    ]
                ]
            ]
        ]
    ]
