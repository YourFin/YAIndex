module Routing exposing (Route(..), contentIdRawHref, contentIdRawUrl, isElmUrl, parseUrl, rootRoute, show, toHref, toLink, toUrlString)

import ContentId exposing (ContentId)
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


type Route
    = ContentRoute ContentId (Maybe String)
    | PageNotFoundRoute


rootRoute : Route
rootRoute =
    ContentRoute [] Nothing



{- Logic for parsing raw urls, might be useful later to parse raw routes and
   rework content


      |> Url.fromString
      |> Maybe.map .path
      |> Maybe.map (String.split "/")
      |> Maybe.map (List.map Url.percentDecode)
      |> Maybe.andThen
          -- Checks for any Nothings in the list
          (List.foldl
              (\val prevMList ->
                  case val of
                      Nothing ->
                          Nothing

                      Just val_ ->
                          Maybe.map
                              ((::) val_)
                              prevMList
              )
              (Just [])
          )
      |> Maybe.map (List.filter ((==) ""))
      |> Maybe.andThen List.tail
-}


encodeContentId : ContentId -> String
encodeContentId id =
    let
        reFromStr str =
            Maybe.withDefault Re.never (Re.fromString str)

        backSlashPat =
            reFromStr "\\\\"

        forwardSlashPat =
            reFromStr "/"
    in
    id
        |> List.map (Re.replace backSlashPat (\_ -> "\\\\"))
        |> List.map (Re.replace forwardSlashPat (\_ -> "\\/"))
        |> String.join "/"


{-| Pulls items off of str and pushes them on to soFar, keeping track of escaping
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
            splitOnUnescapedPathSepHelper False (String.cons char curStr :: tail) rest


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
        |> List.map (Re.replace (reFromStr "\\\\/") (\_ -> "/"))
        |> List.map (Re.replace (reFromStr "\\\\\\\\") (\_ -> "\\"))
        |> List.filter (\item -> not <| item == "")



---- EXPORT


show : Route -> String
show route =
    case route of
        ContentRoute contentId _ ->
            "ContentRoute for content: " ++ encodeContentId contentId

        PageNotFoundRoute ->
            "PageNotFoundRoute"


toUrlString : Route -> String
toUrlString route =
    case route of
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


toHref : Route -> Html.Attribute msg
toHref route =
    Html.Attributes.href (toUrlString route)


toLink : Route -> String -> Html msg
toLink route text =
    Html.a
        [ Html.Attributes.href (toUrlString route) ]
        [ Html.text text ]


contentIdRawUrl : ContentId -> String
contentIdRawUrl path =
    "/raw/" ++ String.join "/" path



-- Url.Builder.absolute
--     ([ "raw" ] ++ List.map Url.percentEncode path)
--     []


contentIdRawHref : ContentId -> Html.Attribute msg
contentIdRawHref path =
    let
        link =
            contentIdRawUrl path
    in
    Html.Attributes.href link



--- PARSING


{-| Returns false if the url should be redirected, despite being to the same
authority as the webapp. This is done because parsers cannot be written to handle
arbitrary path segments in elm, i.e. raw/foo/bar/baz.txt, which should, actually
redirect and not have the parser barf
-}
isElmUrl : Url -> Bool
isElmUrl url =
    let
        rawPat =
            Maybe.withDefault Re.never <| Re.fromString "^/raw"

        requestsPat =
            Maybe.withDefault Re.never <| Re.fromString "^/requests"
    in
    not <|
        List.foldl (\pat -> \state -> Re.contains pat url.path || state)
            False
            [ rawPat, requestsPat ]


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
                        |> Maybe.withDefault rootRoute

                _ ->
                    rootRoute


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map rootRoute top
        , map (ContentRoute []) (s "c" <?> Query.string "q")
        , map ContentRoute (s "c" </> contentIdParser <?> Query.string "q")
        , map PageNotFoundRoute (s "404.html")
        ]


parseUrl : Url -> Route
parseUrl url =
    url
        |> Url.Parser.parse matchers
        |> Maybe.withDefault PageNotFoundRoute
