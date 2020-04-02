module Util.List exposing (last)


last : List a -> Maybe a
last lst =
    case lst of
        [] ->
            Maybe.Nothing

        [ item ] ->
            Maybe.Just item

        _ :: rest ->
            last rest
