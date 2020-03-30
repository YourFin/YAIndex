module Hacks exposing (..)

import ContentType
import Debug exposing (..)
import Dict
import Files exposing (..)
import List.Nonempty as NE
import Maybe exposing (Maybe(..))


inv : Files -> List String -> Files
inv files p =
    case p of
        [] ->
            Debug.todo ""

        first :: rest ->
            markInaccessable (NE.Nonempty first rest) files


ins : Files -> List String -> Inode -> Files
ins files p i =
    case p of
        [] ->
            Debug.todo "foo"

        first :: rest ->
            insertAt i (NE.Nonempty first rest) files


fi : Inode
fi =
    File
        { contentType = ContentType.Unknown ""
        , size = 0
        , modified = ""
        }


fo : Inode
fo =
    Folder Nothing Dict.empty


fol : List ( String, Inode ) -> Inode
fol lst =
    Folder Nothing (Dict.fromList lst)
