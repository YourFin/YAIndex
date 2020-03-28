module MetadataRetrival exposing (..)

import Dict exposing (Dict)
import Http exposing (Expect)
import List
import Maybe exposing (Maybe(..))
import Platform.Cmd as Cmd
import Regex as Re
import RegexUtil as ReU
import Result exposing (Result(..))
import Routing exposing (ContentId)
import String
import Time
import Url


getMetadata : (Result () MetadataResult -> msg) -> ContentId -> Cmd msg
getMetadata toMsg location =
    Http.request
        { method = "HEAD"
        , headers = []
        , url = Routing.contentIdRawUrl location
        , body = Http.emptyBody
        , expect = expectMetadata toMsg
        , timeout = Nothing
        , tracker = Nothing
        }


type HeaderError
    = Unparseable
    | Nonexistant


type MetadataResult
    = ApplicationException String -- Message as to what the fuck happened
    | Retry String -- Message as to what happened
    | Inaccessable String String -- Returns statusText, url
    | IsFolder ContentId
    | IsFile
        { contentId : ContentId
        , modified : Result HeaderError String
        , contentType : Result HeaderError String
        , size : Result HeaderError Int
        }


expectMetadata : (Result () MetadataResult -> msg) -> Expect msg
expectMetadata toMsg =
    Http.expectBytesResponse toMsg <|
        \response ->
            Ok
                (case response of
                    Http.BadUrl_ url ->
                        ApplicationException ("Url: \"" ++ url ++ "\" was bad when trying to send head request.")

                    Http.Timeout_ ->
                        Retry "Timeout"

                    Http.NetworkError_ ->
                        Retry "Network Error"

                    Http.BadStatus_ metadata _ ->
                        Inaccessable metadata.statusText metadata.url

                    Http.GoodStatus_ metadata _ ->
                        let
                            maybeContentId =
                                metadata.url
                                    |> Url.fromString
                                    |> Maybe.map .path
                                    |> Maybe.map (String.split "/")
                                    |> Maybe.map (List.map Url.percentDecode)
                                    |> Maybe.andThen
                                        -- Checks for any Nothings in the list
                                        (List.foldl
                                            (\val prevMList ->
                                                case val of
                                                    Nothing ->
                                                        Nothing

                                                    Just val_ ->
                                                        Maybe.map
                                                            ((::) val_)
                                                            prevMList
                                            )
                                            (Just [])
                                        )
                                    |> Maybe.map (List.filter ((==) ""))
                                    |> Maybe.andThen List.tail
                        in
                        case maybeContentId of
                            Nothing ->
                                ApplicationException
                                    ("Could not parse raw url\""
                                        ++ metadata.url
                                        ++ "\" during head request metadata parse."
                                    )

                            Just contentId ->
                                if isFolder metadata.url then
                                    IsFolder contentId

                                else
                                    let
                                        parsed =
                                            parseFileHeaders metadata.headers
                                    in
                                    IsFile
                                        { modified = parsed.modified
                                        , contentType = parsed.contentType
                                        , size = parsed.contentLength
                                        , contentId = contentId
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
