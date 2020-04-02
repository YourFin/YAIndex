module Util.Regex exposing (..)

import Maybe exposing (Maybe(..))
import Regex as Re


fromPat : String -> Re.Regex
fromPat =
    Re.fromString >> Maybe.withDefault Re.never


fromPatNoCase : String -> Re.Regex
fromPatNoCase =
    Re.fromStringWith { caseInsensitive = True, multiline = False }
        >> Maybe.withDefault Re.never


matches : String -> String -> Bool
matches pattern toMatch =
    Re.contains (fromPat pattern) toMatch


matchesNoCase : String -> String -> Bool
matchesNoCase pattern toMatch =
    Re.contains (fromPatNoCase pattern) toMatch


escape : String -> String
escape =
    Re.replace (fromPat "[.*+\\-?^${}()|[\\]\\\\]") (.match >> (++) "\\")
