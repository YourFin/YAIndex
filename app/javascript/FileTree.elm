module FileTree exposing (FileNode(..), fileNodeDecoder)

import Json.Decode as Decode exposing (Decoder, field, int, lazy, list, map, map3, oneOf, string)
import Time


type FileNode
    = Folder
        { modified : Time.Posix
        , name : String
        , children : List FileNode
        }
    | File
        { modified : Time.Posix
        , name : String
        , size : Int
        }


type alias FolderAlias =
    { modified : Time.Posix
    , name : String
    , children : List FileNode
    }


type alias FileAlias =
    { modified : Time.Posix
    , name : String
    , size : Int
    }


folderDecoder : Decoder FileNode
folderDecoder =
    map Folder <|
        map3 FolderAlias
            (map Time.millisToPosix <| field "modified" int)
            (field "name" string)
            (field "children" (list <| lazy (\_ -> fileNodeDecoder)))


fileDecoder : Decoder FileNode
fileDecoder =
    map File <|
        map3 FileAlias
            (map Time.millisToPosix <| field "modified" int)
            (field "name" string)
            (field "size" int)


fileNodeDecoder : Decoder FileNode
fileNodeDecoder =
    oneOf [ folderDecoder, fileDecoder ]
