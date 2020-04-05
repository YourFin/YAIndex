module ContentType exposing (ContentType(..), parse)

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
            if ReU.matches "$image/" mimeType_ then
                Image

            else
                Unknown filename

        Nothing ->
            -- TODO: implement filename parsing
            Unknown filename
