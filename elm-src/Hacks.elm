module Hacks exposing (..)

import ContentType
import Debug exposing (..)
import Dict
import Files exposing (..)
import List.Nonempty as NE
import Maybe exposing (Maybe(..))


inac : Files -> List String -> Files
inac files p =
    markInaccessable p files


ins : Files -> List String -> InputInode -> Files
ins files p i =
    insertAt i p files


fi : InputInode
fi =
    InputFile
        { contentType = ContentType.Unknown ""
        , size = 0
        , modified = ""
        }


fo : InputInode
fo =
    UnexploredFolder ""


fol : List ( String, InputInode ) -> InputInode
fol lst =
    ExploredFolder Nothing (Dict.fromList lst)
