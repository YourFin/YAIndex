module MetadataRetrival exposing (..)

import Dict exposing (Dict)
import Http exposing (Expect)
import List
import Maybe exposing (Maybe(..))
import Platform.Cmd as Cmd
import Regex as Re
import RegexUtil as ReU
import Result exposing (Result(..))
import Routing exposing (Path)
import String
import Time
import Url


getMetadata : (Result () MetadataResult -> msg) -> Path -> Cmd msg
getMetadata toMsg location =
    Http.request
        { method = "HEAD"
        , headers = []
        , url = Routing.contentIdRawUrl location
        , body = Http.emptyBody
        , expect = expectMetadata location toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


type HeaderError
    = Unparseable
    | Nonexistant


type MetadataResult
    = ApplicationException String -- Message as to what happened
    | Retry Path -- Message as to what happened
    | Inaccessable String Path -- Returns statusText, url
    | IsFolder Path
    | IsFile
        { path : Path
        , modified : Result HeaderError String
        , contentType : Result HeaderError String
        , size : Result HeaderError Int
        }


expectMetadata : Path -> (Result () MetadataResult -> msg) -> Expect msg
expectMetadata path toMsg =
    Http.expectBytesResponse toMsg <|
        \response ->
            Ok
                (case response of
                    Http.BadUrl_ url ->
                        ApplicationException ("Url: \"" ++ url ++ "\" was bad when trying to send head request.")

                    Http.Timeout_ ->
                        Retry path

                    Http.NetworkError_ ->
                        Retry path

                    Http.BadStatus_ metadata _ ->
                        Inaccessable metadata.statusText path

                    Http.GoodStatus_ metadata _ ->
                        if isFolder metadata.url then
                            IsFolder path

                        else
                            let
                                parsed =
                                    parseFileHeaders metadata.headers
                            in
                            IsFile
                                { modified = parsed.modified
                                , contentType = parsed.contentType
                                , size = parsed.contentLength
                                , path = path
                                }
                )


parseFileHeaders :
    Dict String String
    ->
        { modified : Result HeaderError String
        , contentType : Result HeaderError String
        , contentLength : Result HeaderError Int
        }
parseFileHeaders headers =
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
                headers
    in
    { contentType =
        Dict.get "content-type" headers_
            |> Result.fromMaybe Nonexistant
    , modified =
        Dict.get "last-modified" headers_
            |> Result.fromMaybe Nonexistant
    , contentLength =
        Dict.get "content-length" headers_
            |> Maybe.andThen String.toInt
            |> Result.fromMaybe Nonexistant
    }


isFolder : String -> Bool
isFolder =
    let
        endsWithSlash =
            Maybe.withDefault Re.never <| Re.fromString "/^"
    in
    Re.contains endsWithSlash
