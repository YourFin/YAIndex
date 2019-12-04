module Tests.RouteTest exposing (parserTest, testSuite)

import Dict
import Expect
import Maybe exposing (Maybe(..))
import Result exposing (Result(..))
import Routing exposing (..)
import Test exposing (Test, describe, test)
import Url


parserTest : String -> String -> Route -> Test
parserTest msg urlPath expected =
    let
        url =
            Url.fromString ("http://does-not-matter" ++ urlPath)

        parsed =
            Maybe.map parseUrl url
    in
    test msg <|
        \_ ->
            case parsed of
                Just route ->
                    Expect.equal route expected

                Nothing ->
                    Expect.false "Could not parse url" True


testInverse : Route -> Test
testInverse route =
    parserTest ("Should handle route: " ++ show route) (toUrlString route) route


testSuite =
    describe "urlParser"
        [ parserTest "should parse root"
            "/"
            RootRoute
        , parserTest "should parse base content route w/ trailing slash" "/c/" <|
            ContentRoute [] Nothing
        , parserTest "should parse base content route w/o trailing slash" "/c" <|
            ContentRoute [] Nothing
        , parserTest "should parse single child content route" "/c/foo" <|
            ContentRoute [ "foo" ] Nothing
        , parserTest "should parse base query route w/ trailing slash" "/c/?q=foo" <|
            ContentRoute [] (Just "foo")
        , parserTest "should parse base query w/o trailing slash" "/c?q=foo" <|
            ContentRoute [] (Just "foo")
        , parserTest "should parse nested path"
            ("/c/"
                ++ Url.percentEncode "bar/baz"
            )
          <|
            ContentRoute [ "bar", "baz" ] Nothing
        , parserTest "should ignore empty paths"
            ("/c/"
                ++ Url.percentEncode "///bar//baz//"
            )
          <|
            ContentRoute [ "bar", "baz" ] Nothing
        , describe "inverse"
            [ testInverse <| ContentRoute [ "baz", "buzz" ] (Just "myQuery")
            , testInverse <| ContentRoute [ "\\/foo" ] (Just "bar")
            , testInverse <| ContentRoute [ "\\/\\//\\/\\\\\\\\/" ] Nothing
            ]
        ]
