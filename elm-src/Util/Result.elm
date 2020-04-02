module Util.Result exposing (..)

import Result exposing (Result(..))


andThen2 :
    (a -> b -> Result err c)
    -> Result err a
    -> Result err b
    -> Result err c
andThen2 f a b =
    case ( a, b ) of
        ( Ok aa, Ok bb ) ->
            f aa bb

        ( Err err, _ ) ->
            Err err

        ( _, Err err ) ->
            Err err
