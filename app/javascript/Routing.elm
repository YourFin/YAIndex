module Routing exposing (Route(..), parseUrl, show, toHref, toLink, toUrlString)

import Html exposing (Html)
import Html.Attributes
import List
import Maybe exposing (Maybe)
import Regex as Re
import String
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>), (<?>), Parser, map, oneOf, s, string, top)
import Url.Parser.Query as Query


type alias ContentId =
    List String


encodeContentId : ContentId -> String
encodeContentId id =
    let
        reFromStr str =
            Maybe.withDefault Re.never (Re.fromString str)

        backSlashPat =
            reFromStr "\\"

        forwardSlashPat =
            reFromStr "/"
    in
    id
        |> List.map (Re.replace backSlashPat (\_ -> "\\\\"))
        |> List.map (Re.replace forwardSlashPat (\_ -> "\\/"))
        |> String.join "/"



{- Pulls items off of str and pushes them on to soFar, keeping track of escaping
   and adding new lists where appropriate
   Ends up with a reversed list of reversed strings that need to be flipped afterwards
-}


splitOnUnescapedPathSepHelper : Bool -> List String -> List Char -> List String
splitOnUnescapedPathSepHelper escaped soFar str =
    let
        curStr =
            Maybe.withDefault "" <| List.head soFar

        tail =
            Maybe.withDefault [] <| List.tail soFar
    in
    case ( escaped, str ) of
        ( _, [] ) ->
            soFar

        ( _, '\\' :: rest ) ->
            splitOnUnescapedPathSepHelper (not escaped) (String.cons '\\' curStr :: tail) rest

        ( False, '/' :: rest ) ->
            splitOnUnescapedPathSepHelper False ("" :: soFar) rest

        ( _, char :: rest ) ->
            splitOnUnescapedPathSepHelper escaped (String.cons char curStr :: tail) rest


splitOnUnescapedPathSep : String -> List String
splitOnUnescapedPathSep str =
    let
        flipped =
            splitOnUnescapedPathSepHelper
                False
                [ "" ]
                (String.toList str)
    in
    flipped
        |> List.reverse
        |> List.map String.reverse


decodeContentId : String -> ContentId
decodeContentId input =
    let
        reFromStr string =
            Maybe.withDefault Re.never (Re.fromString string)
    in
    input
        |> splitOnUnescapedPathSep
        |> List.map (Re.replace (reFromStr "\\/") (\_ -> "/"))
        |> List.map (Re.replace (reFromStr "\\\\") (\_ -> "\\"))
        |> List.filter (\item -> not <| item == "")


type Route
    = RootRoute
    | ContentRoute ContentId (Maybe String)
    | PageNotFoundRoute
    | LoginRoute Route


show : Route -> String
show route =
    case route of
        RootRoute ->
            "RootRoute"

        ContentRoute contentId _ ->
            "ContentRoute for content: " ++ encodeContentId contentId

        PageNotFoundRoute ->
            "PageNotFoundRoute"

        LoginRoute redirRoute ->
            "LoginRoute redirecting to: " ++ show redirRoute



---- EXPORT


toUrlString : Route -> String
toUrlString route =
    case route of
        RootRoute ->
            Url.Builder.absolute [] []

        ContentRoute contentId possibleQuery ->
            Url.Builder.absolute [ "c", (encodeContentId >> Url.percentEncode) contentId ]
                (case possibleQuery of
                    Maybe.Just query ->
                        [ Url.Builder.string "q" query ]

                    Maybe.Nothing ->
                        []
                )

        PageNotFoundRoute ->
            Url.Builder.absolute [ "404" ] []

        LoginRoute redirRoute ->
            case redirRoute of
                RootRoute ->
                    Url.Builder.absolute [ "login" ] []

                LoginRoute _ ->
                    toUrlString redirRoute

                _ ->
                    Url.Builder.absolute
                        [ "login" ]
                        [ Url.Builder.string "redir" (toUrlString redirRoute) ]


toHref : Route -> Html.Attribute msg
toHref route =
    Html.Attributes.href (toUrlString route)


toLink : Route -> String -> Html msg
toLink route text =
    Html.a
        [ Html.Attributes.href (toUrlString route) ]
        [ Html.text text ]


contentIdParser : Parser (ContentId -> a) a
contentIdParser =
    Url.Parser.custom "URLsplit" <|
        \segment ->
            segment
                |> Url.percentDecode
                |> Maybe.withDefault ""
                |> decodeContentId
                |> Just


redirQuery : Query.Parser Route
redirQuery =
    Query.custom "redir" <|
        \stringList ->
            case stringList of
                [ str ] ->
                    "http://does-not-matter"
                        ++ str
                        |> Url.fromString
                        |> Maybe.map parseUrl
                        |> Maybe.withDefault RootRoute

                _ ->
                    RootRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map RootRoute top
        , map (ContentRoute []) (s "c" <?> Query.string "q")
        , map ContentRoute (s "c" </> contentIdParser <?> Query.string "q")
        , map PageNotFoundRoute (s "404.html")
        , map LoginRoute (s "login" <?> redirQuery)
        ]


parseUrl : Url -> Route
parseUrl url =
    url
        |> Url.Parser.parse matchers
        |> Maybe.withDefault PageNotFoundRoute
