module Routing exposing (Route(..), parseUrl, show, toHref, toLink, toUrlString)

import Html exposing (Html)
import Html.Attributes
import List
import Maybe exposing (Maybe)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, s, string, top)
import Url.Parser.Query as Query


type alias ContentId =
    String


type Route
    = RootRoute
    | SearchResultsRoute (Maybe String)
    | ContentRoute ContentId
    | PageNotFoundRoute
    | LoginRoute (Maybe Route)


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

        LoginRoute possibleSubRoute ->
            case possibleSubRoute of
                Maybe.Nothing ->
                    "LoginRoute"

                Maybe.Just subRoute ->
                    "LoginRoute for subroute: " ++ show subRoute



---- EXPORT


toUrlString : Route -> String
toUrlString route =
    case route of
        RootRoute ->
            Url.Builder.absolute [] []

        SearchResultsRoute possibleQuery ->
            case possibleQuery of
                Maybe.Just query ->
                    Url.Builder.absolute [ "search" ] [ Url.Builder.string "q" query ]

                Maybe.Nothing ->
                    Url.Builder.absolute [ "search" ] []

        ContentRoute contentId ->
            Url.Builder.absolute [ "c", contentId ] []

        PageNotFoundRoute ->
            Url.Builder.absolute [ "404" ] []

        LoginRoute possibleSubRoute ->
            case possibleSubRoute of
                Maybe.Nothing ->
                    Url.Builder.absolute [ "login" ] []

                Maybe.Just subRoute ->
                    case subRoute of
                        LoginRoute _ ->
                            toUrlString subRoute

                        finalRedirRoute ->
                            Url.Builder.absolute
                                [ "login" ]
                                [ Url.Builder.string "redir" (toUrlString finalRedirRoute) ]


toHref : Route -> Html.Attribute msg
toHref route =
    Html.Attributes.href (toUrlString route)


toLink : Route -> String -> Html msg
toLink route text =
    Html.a
        [ Html.Attributes.href (toUrlString route) ]
        [ Html.text text ]



---- PARSING


redirQuery : Query.Parser (Maybe Route)
redirQuery =
    Query.custom "redir" <|
        \stringList ->
            case stringList of
                [ str ] ->
                    Maybe.map parseUrl <| Url.fromString ("http://does-not-matter" ++ str)

                _ ->
                    Maybe.Nothing


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map RootRoute top
        , map SearchResultsRoute (s "search" <?> Query.string "q")
        , map ContentRoute (s "c" </> string)
        , map PageNotFoundRoute (s "404.html")
        , map LoginRoute (s "login" <?> redirQuery)
        ]


parseUrl : Url -> Route
parseUrl url =
    url
        |> Url.Parser.parse matchers
        |> Maybe.withDefault PageNotFoundRoute
