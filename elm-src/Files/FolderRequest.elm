module Files.FolderRequest exposing (..)

import ContentType exposing (ContentType)
import Dict exposing (Dict)
import Files exposing (Inode(..))
import Http
import Json.Decode as JDecode
import Result exposing (Result(..))
import Routing exposing (ContentId, contentIdRawUrl)


retrieveFolder : (Result Http.Error FileTree -> msg) -> ContentId -> Cmd msg
retrieveFolder toMsg path =
    Http.get
        { url = contentIdRawUrl path
        , expect = Http.expectJson toMsg folderDecoder
        }


folderDecoder : JDecode.Decoder FileTree
folderDecoder =
    JDecode.oneOf
        [ assertField "type" "directory" folderEntryDecoder
        , assertField "type" "file" fileEntryDecoder
        ]
        |> JDecode.list
        |> JDecode.map Dict.fromList


folderEntryDecoder : JDecode.Decoder ( String, FileNode )
folderEntryDecoder =
    JDecode.map2 (\name mtime -> ( name, Folder (Just mtime) Dict.empty ))
        (JDecode.field "name" JDecode.string)
        (JDecode.field "mtime" JDecode.string)


fileEntryDecoder : JDecode.Decoder ( String, FileNode )
fileEntryDecoder =
    JDecode.map3 fileEntry
        (JDecode.field "name" JDecode.string)
        (JDecode.field "mtime" JDecode.string)
        (JDecode.field "size" JDecode.int)


fileEntry : String -> String -> Int -> ( String, FileNode )
fileEntry name mtime size =
    let
        contentType =
            ContentType.parse Nothing name
    in
    ( name
    , File
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
