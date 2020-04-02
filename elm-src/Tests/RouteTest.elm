module Tests.RouteTest exposing (dummyTest)

import Dict
import Expect
import Maybe exposing (Maybe(..))
import Result exposing (Result(..))
import Routing exposing (..)
import Test exposing (Test, describe, test)
import Url


dummyTest =
    test "dummy" <|
        \_ -> Expect.equal True True



-- parserTest : String -> String -> Route -> Test
-- parserTest msg urlPath expected =
--     let
--         url =
--             Url.fromString ("http://does-not-matter" ++ urlPath)
--         parsed =
--             Maybe.map parseUrl url
--     in
--     test msg <|
--         \_ ->
--             case parsed of
--                 Just route ->
--                     Expect.equal route expected
--                 Nothing ->
--                     Expect.false "Could not parse url" True
-- testInverse : Route -> Test
-- testInverse route =
--     parserTest ("Should handle route: " ++ show route) (toUrlString route) route
-- urlParserSuite =
--     describe "urlParser"
--         [ parserTest "should parse root"
--             "/"
--             (ContentRoute
--                 []
--                 Nothing
--             )
--         , parserTest "should parse base content route w/ trailing slash" "/c/" <|
--             ContentRoute [] Nothing
--         , parserTest "should parse base content route w/o trailing slash" "/c" <|
--             ContentRoute [] Nothing
--         , parserTest "should parse single child content route" "/c/foo" <|
--             ContentRoute [ "foo" ] Nothing
--         , parserTest "should parse base query route w/ trailing slash" "/c/?q=foo" <|
--             ContentRoute [] (Just "foo")
--         , parserTest "should parse base query w/o trailing slash" "/c?q=foo" <|
--             ContentRoute [] (Just "foo")
--         , parserTest "should parse nested path"
--             ("/c/"
--                 ++ Url.percentEncode "bar/baz"
--             )
--           <|
--             ContentRoute [ "bar", "baz" ] Nothing
--         , parserTest "should ignore empty paths"
--             ("/c/"
--                 ++ Url.percentEncode "///bar//baz//"
--             )
--           <|
--             ContentRoute [ "bar", "baz" ] Nothing
--         , describe "inverse"
--             [ testInverse <| ContentRoute [ "baz", "buzz" ] (Just "myQuery")
--             , testInverse <| ContentRoute [] Nothing
--             , testInverse <| ContentRoute [ "/" ] Nothing
--             , testInverse <| ContentRoute [ "/", "/" ] Nothing
--             , testInverse <| ContentRoute [ "\\" ] Nothing
--             , testInverse <| ContentRoute [ "\\\\" ] Nothing
--             , testInverse <| ContentRoute [ "\\\\/" ] Nothing
--             , testInverse <| ContentRoute [ "/\\" ] Nothing
--             , testInverse <| ContentRoute [ "\\/" ] Nothing
--             , testInverse <| ContentRoute [ "Hello, World!" ] Nothing
--             , testInverse <| ContentRoute [ "?q=foo" ] Nothing
--             , testInverse <| ContentRoute [ "\\/foo" ] (Just "bar")
--             , testInverse <| ContentRoute [ "\\/\\//\\/\\\\\\\\/" ] Nothing
--             ]
--         ]
-- isElmUrlSuite =
--     let
--         testInternal isElm msg path =
--             let
--                 url =
--                     Url.fromString ("http://does-not-matter" ++ path)
--                 mActualIsElmUrl =
--                     Maybe.map isElmUrl url
--                 actualIsElmUrl =
--                     Maybe.withDefault False mActualIsElmUrl
--             in
--             test msg <|
--                 \_ ->
--                     if isElm then
--                         Expect.true "Should be an elm internal url" actualIsElmUrl
--                     else
--                         Expect.false "Should be a non-elm url" actualIsElmUrl
--     in
--     describe "isExternalUrl"
--         [ testInternal True "Root should be internal" "/"
--         , testInternal True "Random content route should be internal" "/c/foo"
--         , testInternal True "Root content route should be internal" "/c/"
--         , testInternal True "Root content route should be internal w/o slash" "/c"
--         , testInternal True "Unknown path should be internal" "/unknown_untaken_path_/foo"
--         , testInternal True "404 should be internal" "/404.html"
--         , testInternal False "Root raw path should be external w/o slash" "/raw"
--         , testInternal False "Root raw path should be external" "/raw/"
--         , testInternal False "Simple raw path should be external" "/raw/foo"
--         , testInternal False "Double raw path should be external" "/raw/foo/bar"
--         , testInternal False "Root requests path should be external w/o slash" "/requests"
--         , testInternal False "Root requests path should be external" "/requests/"
--         , testInternal False "Simple requests path should be external" "/requests/foo"
--         , testInternal False "Double requests path should be external" "/requests/foo/bar"
--         ]
