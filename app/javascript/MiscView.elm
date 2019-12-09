module MiscView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Maybe
import Routing


navbar : Html msg
navbar =
    nav [ class "navbar has-shadow", role "navigation", ariaLabel "main navigation" ]
        [ div [ class "navbar-brand" ]
            [ a [ class "navbar-item", Routing.toHref Routing.rootRoute ]
                [ h1 [] [ text "Browser" ] ]
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
