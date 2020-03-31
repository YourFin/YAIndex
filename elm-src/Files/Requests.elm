module Files.Requests exposing (folder, metadata)

import ContentId exposing (ContentId)
import ContentType exposing (ContentType)
import Dict exposing (Dict)
import Files exposing (InputInode(..))
import Http exposing (Expect)
import Json.Decode as JDecode
import List
import Maybe exposing (Maybe(..))
import Platform.Cmd as Cmd
import Regex as Re
import Result exposing (Result(..))
import Routing exposing (contentIdRawUrl)
import String
import Time
import Url
import Util.List as ListU
import Util.Maybe as MaybeU
import Util.Regex as ReU



-------------------------
-- Folder Get Requests --
-------------------------


folder : (Result Http.Error InputInode -> msg) -> ContentId -> Cmd msg
folder toMsg path =
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
        |> JDecode.map ExploredFolder


folderEntryDecoder : JDecode.Decoder ( String, InputInode )
folderEntryDecoder =
    JDecode.map2 (\name mtime -> ( name, UnexploredFolder (Just mtime) ))
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



----------------------------
-- Metadata Head Requests --
----------------------------


metadata : (Result Http.Error InputInode -> msg) -> ContentId -> Cmd msg
metadata toMsg location =
    Http.request
        { method = "HEAD"
        , headers = []
        , url = Routing.contentIdRawUrl location
        , body = Http.emptyBody
        , expect = expectMetadata toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


expectMetadata : (Result Http.Error InputInode -> msg) -> Expect msg
expectMetadata toMsg =
    Http.expectBytesResponse toMsg <|
        \response ->
            case response of
                Http.GoodStatus_ metadata_ _ ->
                    parseMetadata metadata_

                Http.BadUrl_ url ->
                    Err <| Http.BadUrl url

                Http.Timeout_ ->
                    Err <| Http.Timeout

                Http.NetworkError_ ->
                    Err <| Http.NetworkError

                Http.BadStatus_ metadata_ _ ->
                    Err <| Http.BadStatus metadata_.statusCode


parseMetadata : Http.Metadata -> Result Http.Error InputInode
parseMetadata metadata_ =
    let
        headers_ =
            Dict.foldr
                (\key value prevDict ->
                    Dict.insert
                        (String.toLower key)
                        value
                        prevDict
                )
                Dict.empty
                metadata_.headers
    in
    case parseUrl metadata_.url of
        Fail ->
            (Err << Http.BadBody) <|
                "Could not parse url: \""
                    ++ metadata_.url
                    ++ "\"."

        Folder ->
            Ok <| UnexploredFolder Nothing

        File name ->
            case
                ( ContentType.parse (Dict.get "content-type" headers_) name
                , Dict.get "last-modified" headers_
                , Maybe.andThen String.toInt <|
                    Dict.get "content-length" headers_
                )
            of
                ( contentType, Just modified, Just contentLength ) ->
                    Ok <|
                        InputFile
                            { contentType = contentType
                            , modified = modified
                            , size = contentLength
                            }

                _ ->
                    (Err << Http.BadBody) <|
                        "Could not parse headers for file metadata on url \""
                            ++ metadata_.url
                            ++ "\""


type UrlParseResult
    = Fail
    | Folder
    | File String


parseUrl : String -> UrlParseResult
parseUrl urlStr =
    case
        Url.fromString urlStr
            |> Maybe.map .path
            |> Maybe.map (String.split "/")
            |> Maybe.map (List.map Url.percentDecode)
            |> Maybe.andThen MaybeU.liftList
            |> Maybe.andThen ListU.last
    of
        Nothing ->
            Fail

        Just "" ->
            Folder

        Just name ->
            File name
