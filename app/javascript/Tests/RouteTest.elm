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


testSuite =
    describe "urlParser"
        [ parserTest "should parse root"
            "/"
            RootRoute
        , parserTest "should parse base content route" "/c/" <|
            ContentRoute [] Nothing
        ]
