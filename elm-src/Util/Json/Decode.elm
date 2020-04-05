module Util.Json.Decode exposing (nonemptyString, symbol, symbols)

import Json.Decode exposing (..)


nonemptyString : Decoder (Maybe String)
nonemptyString =
    let
        helper str =
            case str of
                "" ->
                    Nothing

                nonempty ->
                    Just nonempty
    in
    map helper string


{-| Decode a string that corresponds to a single symbol.
Mostly useful in a oneOf context.
-}
symbol : String -> a -> Decoder a
symbol expectedString symbolConstructor =
    string
        |> andThen
            (\str ->
                if str == expectedString then
                    succeed symbolConstructor

                else
                    "Expected string: \""
                        ++ expectedString
                        ++ "\", got \""
                        ++ str
                        ++ "\" instead."
                        |> fail
            )


symbols : List ( String, a ) -> Decoder a
symbols pairs =
    oneOf <|
        List.map
            (\( expected, symb ) -> symbol expected symb)
            pairs
