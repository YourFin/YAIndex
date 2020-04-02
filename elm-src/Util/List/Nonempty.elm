module Util.List.Nonempty exposing (appendToNonEmpty, init, last)

import List.Nonempty as NE exposing (Nonempty(..))
import Maybe exposing (Maybe(..))


appendToNonEmpty : Nonempty a -> List a -> Nonempty a
appendToNonEmpty first second =
    case NE.fromList second of
        Nothing ->
            first

        Just snd ->
            NE.append first snd


last : Nonempty a -> a
last (Nonempty head tail) =
    case tail of
        [] ->
            head

        next :: rest ->
            last <| Nonempty next rest


init : Nonempty a -> List a
init lst =
    case lst of
        Nonempty head [] ->
            []

        Nonempty head (next :: tail) ->
            head :: (init <| Nonempty next tail)
