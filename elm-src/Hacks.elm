module Hacks exposing (..)

import ContentType
import Debug exposing (..)
import Dict
import Files exposing (..)
import List.Nonempty as NE
import Maybe exposing (Maybe(..))


unwrapR : Result x a -> a
unwrapR res =
    case res of
        Ok val ->
            val

        Err _ ->
            todo ""


unwrapM : Maybe a -> a
unwrapM m =
    case m of
        Just val ->
            val

        Nothing ->
            todo ""
