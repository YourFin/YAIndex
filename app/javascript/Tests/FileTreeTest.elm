module Tests.FileTreeTest exposing (jsonSuite)

import Dict
import Expect
import FileTree exposing (..)
import Json.Decode exposing (decodeString)
import Result exposing (Result(..))
import Test exposing (Test, describe, test)
import Time exposing (millisToPosix)


decoderTest : String -> String -> FileNode -> Test
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
    describe "filesDecoder"
        [ decoderTest "should handle single directory"
            "{\"modified\": 124, \"children\": {}}"
          <|
            Folder
                { modified = millisToPosix 124
                , expanded = False
                , children = Dict.empty
                }
        , decoderTest
            "should handle directory w/ a single file"
            ("{\"modified\": 124, \"name\": \"Buzz\", \"children\":"
                ++ "{\"baz\": {\"size\": 12, \"modified\": 22}}"
                ++ "}"
            )
          <|
            Folder
                { modified = millisToPosix 124
                , expanded = False
                , children =
                    Dict.fromList
                        [ ( "baz"
                          , File
                                { modified = millisToPosix 22
                                , size = 12
                                }
                          )
                        ]
                }

        -- , decoderTest "should handle deeply nested folders"
        ]
