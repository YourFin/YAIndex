module Routing.Roots exposing (Roots, create)

import Maybe exposing (Maybe(..))
import Regex as Re
import Result exposing (Result(..))
import Url exposing (Url)
import Util.Maybe as MaybeU
import Util.Regex as ReU
import Util.Result as ResultU


type Roots
    = Roots Roots_


{-| Create a Roots. Init-time function.
Takes as arguments a url string for the server index root, a url string for this
web-application's root, and Url that the application is actually visiting,
respectively. The first two arguments can be in the form of a full URI
(i.e. <https://github.com/>) or an absolute path relative to the current
authority (i.e. domain), like "/media/browser/". The third should generally be
from the second argument passed to Main.init.

Note that passing a full Url for the webapp route is not /really/ different from
passing an absolute path, as all webapp-to-webapp redirects strip out the
authority anyways. Doing so does, however, help check for collisions while
testing out this software directly from a administrator's filesystem.

This function, then, does two things: parse the two roots, and check both the
web-application root and the current url for possible collisions with the given
server index route.

Collisions:

A collision of two urls is here defined by one url being a "child" of the other.
Illustrative examples:

  - "/index/raw/" and "/index/" collide

  - "/moo" and "/moo/cow" collide

  - "/yaindex" and "/yaindex/" collide

  - "/fan" and "/fantastic" do not collide

  - "/" and ANYTHING will collide

  - ANYTHING and "/" will collide

  - "<http://batman/"> and "<http://robin/"> will not collide

  - "<http://192.168.0.1/"> and "<https://192.168.0.1/"> will collide

-}
create : String -> String -> Url -> Result String Roots
create serverIndexRoot webappRoot visitedUrl =
    let
        parsedServerIndex =
            parseRoot serverIndexRoot

        parsedWebapp =
            parseRoot webappRoot
    in
    ResultU.andThen2 (createHelper serverIndexRoot webappRoot visitedUrl) parsedServerIndex parsedWebapp


type alias Roots_ =
    { serverIndex : Root_
    , webapp : Root_
    }


type alias Root_ =
    Url



------------------
-- Root Parsing --
------------------


parseRoot : String -> Result String ParsedRoot_
parseRoot str =
    if ReU.matches "^/" str then
        parseAbsolute str

    else
        parseCrossOrigin str


type ParsedRoot_
    = Full Url
    | Absolute String


parseAbsolute : String -> Result String ParsedRoot_
parseAbsolute str =
    -- Note that str this is guaranteed to start with a slash
    "http://does-not-matter.com"
        ++ str
        |> Url.fromString
        |> Result.fromMaybe
            ("Whoops! I couldn't figure out how to use \""
                ++ str
                ++ "\" as an absolute url. Here are some good examples:\n"
                ++ "   /c/\n"
                ++ "   /c\n"
                ++ "   /files/browser/"
            )
        |> Result.andThen (checkQueryAndFragments str)
        -- Note that the url value gets dropped with the always in the next
        -- line. Everything above this comment is error checking
        |> Result.map (always <| Absolute str)


parseCrossOrigin : String -> Result String ParsedRoot_
parseCrossOrigin str =
    str
        |> Url.fromString
        |> Result.fromMaybe
            ("I couldn't figure out how to use \""
                ++ str
                ++ "\" as a url. Here are some good examples:\n"
                ++ "   /c/\n"
                ++ "   /c\n"
                ++ "   /files/browser/\n"
                ++ "   https://files.mydomain.com/\n"
                ++ "   http://files.mydomain.com:4032/\n"
                ++ "   http://my-computer/yaindex\n"
                ++ "   http://mydomain.com/files/browser/\n"
            )
        |> Result.andThen (checkQueryAndFragments str)
        |> Result.map Full


checkQueryAndFragments : String -> Url -> Result String Url
checkQueryAndFragments original url =
    case ( url.query, url.fragment ) of
        ( Just query, _ ) ->
            "\""
                ++ original
                ++ "\" contains a query section (like ?name=bob),"
                ++ " which is not allowed for root urls.\nIn this"
                ++ " case the query found was:\"?"
                ++ Maybe.withDefault "" url.query
                ++ "\". Maybe try removing that?"
                |> Err

        ( _, Just fragment ) ->
            "\""
                ++ original
                ++ "\" contains a fragment (like #paragraph1), which is not"
                ++ "allowed for root urls.\n"
                ++ "In this case the fragment found was: \"#"
                ++ fragment
                ++ "\". Maybe try removing that?"
                |> Err

        ( Nothing, Nothing ) ->
            Ok url



------------------------
-- Collision Checking --
------------------------


createHelper :
    String
    -> String
    -> Url
    -> ParsedRoot_
    -> ParsedRoot_
    -> Result String Roots
createHelper serverIndexRoot webappRoot visitedUrl parsedServerIndex parsedWebapp =
    let
        mergedWebapp =
            case parsedWebapp of
                Absolute str ->
                    { visitedUrl
                        | path = assertTrailingSlash str
                        , query = Nothing
                        , fragment = Nothing
                    }

                Full url ->
                    { visitedUrl
                        | path = assertTrailingSlash url.path
                        , query = Nothing
                        , fragment = Nothing
                    }

        mergedServerIndex =
            case parsedServerIndex of
                Absolute str ->
                    { visitedUrl
                        | path = assertTrailingSlash str
                        , query = Nothing
                        , fragment = Nothing
                    }

                Full url ->
                    url
    in
    if collides parsedServerIndex parsedWebapp then
        "The given server index root: \""
            ++ serverIndexRoot
            ++ "\" is a child of the given web-application root: \""
            ++ webappRoot
            ++ "\" or vice versa, which is likely to cause problems.\n\n"
            ++ "If you want to serve the webapp from the root of your "
            ++ "server, consider setting it up under something like"
            ++ "\"/browse/\", and then 308 redirect \"/\" to \"browse\"."
            |> Err

    else if
        collides
            parsedServerIndex
            (Full <| visitedUrl)
    then
        "The given server index root: \""
            ++ serverIndexRoot
            ++ "\" is a child of the url you are visiting: \""
            ++ Url.toString visitedUrl
            ++ "\" or vice versa, which is likely to cause problems.\n\n"
            ++ "If you want to serve the webapp from the root of your "
            ++ "server, consider setting it up under something like"
            ++ "\"/browse/\", and then 308 redirect \"/\" to \"browse\"."
            |> Err

    else
        Ok <| Roots <| Roots_ mergedServerIndex mergedWebapp


collides : ParsedRoot_ -> ParsedRoot_ -> Bool
collides rawRoute clientRoute =
    case ( rawRoute, clientRoute ) of
        ( Full rawUrl, Full clientUrl ) ->
            (rawUrl.host == clientUrl.host)
                && (rawUrl.port_ == clientUrl.port_)
                && collidesHelper
                    ((List.filter ((/=) "") << String.split "/") rawUrl.path)
                    ((List.filter ((/=) "") << String.split "/") clientUrl.path)

        ( Full url, Absolute str ) ->
            collidesHelper
                ((List.filter ((/=) "") << String.split "/") url.path)
                ((List.filter ((/=) "") << String.split "/") str)

        ( Absolute str, Full url ) ->
            collidesHelper
                ((List.filter ((/=) "") << String.split "/") str)
                ((List.filter ((/=) "") << String.split "/") url.path)

        ( Absolute raw, Absolute client ) ->
            collidesHelper
                ((List.filter ((/=) "") << String.split "/") raw)
                ((List.filter ((/=) "") << String.split "/") client)


collidesHelper : List String -> List String -> Bool
collidesHelper raw client =
    case ( Debug.log "Raw" raw, Debug.log "Client" client ) of
        ( _, [] ) ->
            True

        ( [], _ ) ->
            True

        ( rawFst :: rawRst, clientFst :: clientRst ) ->
            (rawFst == clientFst) && collidesHelper rawRst clientRst


assertTrailingSlash : String -> String
assertTrailingSlash str =
    if ReU.matches "/$" str then
        str

    else
        str ++ "/"


unwrap : Roots -> Roots_
unwrap root =
    case root of
        Roots root_ ->
            root_


map : (Roots_ -> Roots_) -> Roots -> Roots
map f =
    unwrap >> f >> Roots
