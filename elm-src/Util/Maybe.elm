module Util.Maybe exposing (..)


liftList : List (Maybe a) -> Maybe (List a)
liftList input =
    case input of
        [] ->
            Just []

        Nothing :: _ ->
            Nothing

        (Just head) :: rest ->
            Maybe.map ((::) head) <| liftList rest


hasValue : Maybe a -> Bool
hasValue input =
    case input of
        Just _ ->
            True

        Nothing ->
            False
