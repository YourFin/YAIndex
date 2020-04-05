module ContentType.Video.MediaTime exposing
    ( MediaTime
    , decoder
    , encode
    , fromFloat
    , hours
    , minutes
    , seconds
    , toHtml
    , toSeconds
    , toString
    )

import Html exposing (Html)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type MediaTime
    = MediaTime Float


toString : MediaTime -> String
toString ctime =
    case hours ctime of
        0 ->
            String.fromInt (minutes ctime)
                ++ ":"
                ++ String.fromInt (seconds ctime)

        hrs ->
            String.fromInt hrs
                ++ ":"
                ++ String.fromInt (minutes ctime)
                ++ ":"
                ++ String.fromInt (seconds ctime)


toHtml : MediaTime -> Html msg
toHtml =
    Html.text << toString


fromFloat : Float -> MediaTime
fromFloat =
    MediaTime


decoder : Decoder MediaTime
decoder =
    Decode.map fromFloat Decode.float


encode : MediaTime -> Value
encode (MediaTime ctime) =
    Encode.float ctime


seconds : MediaTime -> Int
seconds (MediaTime ctime) =
    modBy 60 <| floor ctime


minutes : MediaTime -> Int
minutes (MediaTime ctime) =
    modBy 60 <| floor ctime // 60


hours : MediaTime -> Int
hours (MediaTime ctime) =
    floor ctime // (60 * 60)


toSeconds : MediaTime -> Float
toSeconds (MediaTime ctime) =
    ctime
