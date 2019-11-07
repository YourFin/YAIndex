module MiscView exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Maybe
import Routing


navbar : Bool -> Html msg
navbar =
    nav [ class "navbar has-shadow", role "navigation", ariaLabel "main navigation" ]
        [ div [ class "navbar-brand" ]
            [ a [ class "navbar-item", Routing.toHref Routing.RootRoute ]
                [ h1 [] [ text "Browser" ] ]
            , a
                [ role "button"
                , class "navbar-burger is-active"
                , ariaLabel "menu"
                , ariaExpanded "false"
                ]
                [ span [ ariaHidden "true" ]
                    [ Routing.toLink (Routing.SearchResultsRoute (Maybe.Just "testSearch")) "Search" ]
                ]
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


ariaHidden : String -> Attribute msg
ariaHidden =
    attribute "aria-hidden"


dataTarget : String -> Attribute msg
dataTarget =
    attribute "data-target"
