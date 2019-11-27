module Tests.FileTreeTest exposing (jsonSuite)

import Expect
import FileTree exposing (..)
import Json.Decode exposing (decodeString)
import Result exposing (Result(..))
import Test exposing (Test, describe, test)
import Time exposing (millisToPosix)


decoderTest : String -> String -> List FileNode -> Test
decoderTest msg jsonStr expected =
    let
        decodeResult =
            decodeString filesDecoder jsonStr
    in
    test msg <|
        \_ ->
            case decodeResult of
                Ok fileNodes ->
                    Expect.equal fileNodes expected

                Err err ->
                    Expect.false (Json.Decode.errorToString err) True


jsonSuite =
    describe "Json tests"
        [ decoderTest "should handle empty case"
            "[]"
            []
        , decoderTest "should handle single file"
            "[{\"size\": 12, \"modified\": 22, \"name\": \"baz\"}]"
            [ File
                { modified = millisToPosix 22
                , size = 12
                , name = "baz"
                }
            ]
        , decoderTest "should handle single directory"
            "[{\"modified\": 124, \"name\": \"Buzz\", \"children\": []}]"
            [ Folder
                { modified = millisToPosix 124
                , expanded = False
                , children = []
                , name = "Buzz"
                }
            ]
        ]
