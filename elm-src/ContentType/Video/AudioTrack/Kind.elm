module ContentType.Video.AudioTrack.Kind exposing (..)

import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Util.Json.Decode as DecodeU


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack/kind>
-}
type Kind
    = Alternative
    | Descriptions
    | Main
    | MainDescription
    | Translation
    | Commentary
    | Unknown


encode : Kind -> Value
encode kind =
    case kind of
        Alternative ->
            Encode.string "alternative"

        Descriptions ->
            Encode.string "descriptions"

        Main ->
            Encode.string "main"

        MainDescription ->
            Encode.string "main-desc"

        Translation ->
            Encode.string "translation"

        Commentary ->
            Encode.string "commentary"

        Unknown ->
            Encode.string ""


decode : Decoder Kind
decode =
    Decode.oneOf
        [ DecodeU.symbols
            [ ( "alternative", Alternative )
            , ( "descriptions", Descriptions )
            , ( "main", Main )
            , ( "main-desc", MainDescription )
            , ( "translation", Translation )
            , ( "commentary", Commentary )
            ]
        , Decode.succeed Unknown
        ]
