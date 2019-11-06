module Routing exposing (Route, toUrlString, parseUrl, show)

import Maybe exposing (Maybe)
import Url exposing (Url)
import Url.Parser exposing (Parser, (<?>), (</>), map, oneOf, s, string, top)
import Url.Parser.Query as Query

type alias ContentId = String

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


toUrlString : Route -> String
toUrlString route =
    case route of
        RootRoute ->
            ""

        SearchResultsRoute query ->
            "search?q=" ++ Maybe.withDefault "" query

        ContentRoute contentId ->
            "c/" ++ contentId

        PageNotFoundRoute ->
            "404.html"

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
