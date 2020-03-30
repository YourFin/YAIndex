module RequestTree.FolderRequests exposing (..)

import ContentType exposing (ContentType)
import Dict exposing (Dict)
import Files exposing (Files, InputInode(..))
import Http
import Json.Decode as JDecode
import Result exposing (Result(..))
import Routing exposing (ContentId, contentIdRawUrl)


retrieveFolder : (Result Http.Error InputInode -> msg) -> ContentId -> Cmd msg
retrieveFolder toMsg path =
    Http.get
        { url = contentIdRawUrl path
        , expect = Http.expectJson toMsg folderDecoder
        }


folderDecoder : JDecode.Decoder InputInode
folderDecoder =
    JDecode.oneOf
        [ assertField "type" "directory" folderEntryDecoder
        , assertField "type" "file" fileEntryDecoder
        ]
        |> JDecode.list
        |> JDecode.map Dict.fromList
        |> JDecode.map (ExploredFolder Nothing)


folderEntryDecoder : JDecode.Decoder ( String, InputInode )
folderEntryDecoder =
    JDecode.map2 (\name mtime -> ( name, UnexploredFolder mtime ))
        (JDecode.field "name" JDecode.string)
        (JDecode.field "mtime" JDecode.string)


fileEntryDecoder : JDecode.Decoder ( String, InputInode )
fileEntryDecoder =
    JDecode.map3 fileEntry
        (JDecode.field "name" JDecode.string)
        (JDecode.field "mtime" JDecode.string)
        (JDecode.field "size" JDecode.int)


fileEntry : String -> String -> Int -> ( String, InputInode )
fileEntry name mtime size =
    let
        contentType =
            ContentType.parse Nothing name
    in
    ( name
    , InputFile
        { contentType = contentType
        , size = size
        , modified = mtime
        }
        Dict.empty
    )


assertField : String -> String -> JDecode.Decoder a -> JDecode.Decoder a
assertField key expectedVal decoder =
    JDecode.field key JDecode.string
        |> JDecode.andThen
            (\str ->
                if str /= expectedVal then
                    JDecode.fail
                        ("Expected \""
                            ++ expectedVal
                            ++ "\" for key \""
                            ++ key
                            ++ "\". Instead found \""
                            ++ str
                            ++ "\"."
                        )

                else
                    decoder
            )
