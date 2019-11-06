module Routing exposing (Route(..), parseUrl, show, toLink, toUrlString)

import Html exposing (Html)
import Html.Attributes
import Maybe exposing (Maybe)
import Url exposing (Url)
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, s, string, top)
import Url.Parser.Query as Query


type alias ContentId =
    String


type Route
    = RootRoute
    | SearchResultsRoute (Maybe String)
    | ContentRoute ContentId
    | PageNotFoundRoute


show : Route -> String
show route =
    case route of
        RootRoute ->
            "RootRoute"

        SearchResultsRoute query ->
            "SearchResultsRoute for query: " ++ Maybe.withDefault "" query

        ContentRoute contentId ->
            "ContentRoute for content: " ++ contentId

        PageNotFoundRoute ->
            "PageNotFoundRoute"



---- EXPORT


toUrlString : Route -> String
toUrlString route =
    case route of
        RootRoute ->
            "/"

        SearchResultsRoute query ->
            "/search?q=" ++ Maybe.withDefault "" query

        ContentRoute contentId ->
            "/c/" ++ contentId

        PageNotFoundRoute ->
            "/404.html"


toLink : Route -> String -> Html msg
toLink route text =
    Html.li []
        [ Html.a
            [ Html.Attributes.href (toUrlString route) ]
            [ Html.text text ]
        ]



---- PARSING


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map RootRoute top
        , map SearchResultsRoute (s "search" <?> Query.string "q")
        , map ContentRoute (s "c" </> string)
        , map PageNotFoundRoute (s "404.html")
        ]


parseUrl : Url -> Route
parseUrl url =
    url
        |> Url.Parser.parse matchers
        |> Maybe.withDefault PageNotFoundRoute
