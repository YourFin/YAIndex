module ContentType.Video.AudioTrack exposing (..)

import ContentType.Video.AudioTrack.Kind as Kind exposing (Kind)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Util.Json.Decode as DecodeU


{-| See: <https://developer.mozilla.org/en-US/docs/Web/API/AudioTrack>
-}
type alias AudioTrack =
    { id : String -- Unique identifier for the track
    , kind : Kind
    , label : Maybe String
    , lang : Maybe String -- Hopefully a RFC5646 string
    }


decode : Value -> Decoder AudioTrack
decode value =
    Decode.map4 AudioTrack
        (Decode.field "id" Decode.string)
        (Decode.field "kind" Kind.decode)
        (Decode.field "label" DecodeU.nonemptyString)
        (Decode.field "language" DecodeU.nonemptyString)


encode : AudioTrack -> Value
encode track =
    Encode.object
        [ ( "id", Encode.string track.id )
        , ( "kind", Kind.encode track.kind )
        , ( "label", Encode.string <| Maybe.withDefault "" track.label )
        , ( "language", Encode.string <| Maybe.withDefault "" track.lang )
        ]
