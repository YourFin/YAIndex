module FileTree exposing (FileNode(..), filesDecoder)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, dict, field, int, lazy, list, map, map2, map3, oneOf, string, succeed)
import Time


type FileNode
    = Folder
        { modified : Time.Posix
        , children : Dict String FileNode
        , expanded : Bool
        }
    | File
        { modified : Time.Posix
        , size : Int
        }


type alias FolderAlias =
    { modified : Time.Posix
    , children : Dict String FileNode
    , expanded : Bool
    }


type alias FileAlias =
    { modified : Time.Posix
    , size : Int
    }


folderDecoder : Decoder FileNode
folderDecoder =
    map Folder <|
        map3 FolderAlias
            (map Time.millisToPosix <| field "modified" int)
            (field "children" (dict <| lazy (\_ -> fileNodeDecoder)))
            (succeed False)


fileDecoder : Decoder FileNode
fileDecoder =
    map File <|
        map2 FileAlias
            (map Time.millisToPosix <| field "modified" int)
            (field "size" int)


fileNodeDecoder : Decoder FileNode
fileNodeDecoder =
    oneOf [ folderDecoder, fileDecoder ]


filesDecoder : Decoder FileNode
filesDecoder =
    folderDecoder
