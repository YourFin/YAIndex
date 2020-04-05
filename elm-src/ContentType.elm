module ContentType exposing (ContentType(..), parse)

import ContentType.Video as Video
import Util exposing (flip)
import Util.Regex as ReU


type ContentType
    = Unknown String
    | Video Video.Model
    | Image



{--Takes an application-type header string and filename returns what
ContentType the file is.-}


parse : Maybe String -> String -> ContentType
parse mimeType filename =
    case mimeType of
        Just mimeType_ ->
            if ReU.matches "^image/" mimeType_ then
                Image

            else if ReU.matches "^video/" mimeType_ then
                Video Video.empty

            else
                Unknown filename

        Nothing ->
            if isImage filename then
                Image

            else
                Unknown filename


isImage : String -> Bool
isImage fname =
    [ "\\.jpg$", "\\.jpeg", "\\.png$", "\\.gif$" ]
        |> List.map (flip ReU.matchesNoCase fname)
        |> List.foldl (||) False
