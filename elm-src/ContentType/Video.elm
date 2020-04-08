module ContentType.Video exposing (Model, Msg, empty, update, view)

import Array exposing (Array)
import ContentType.Video.MediaTime as MediaTime exposing (MediaTime)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)
import Routing exposing (ContentId)



-- MODEL


type alias Model =
    { currentTime : MediaTime
    , volume : Float
    , duration : Maybe MediaTime
    , ephemerals : Ephemerals
    }


empty : Model
empty =
    { currentTime = MediaTime.fromFloat 0
    , volume = 1
    , duration = Nothing
    , ephemerals = {}
    }


type alias Ephemerals =
    {}



-- UPDATE


type Msg
    = TimeUpdate MediaTime
    | GotLength MediaTime
    | VolumeChanged Float


update : Msg -> Model -> Model
update msg model =
    case msg of
        TimeUpdate time ->
            { model | currentTime = time }

        VolumeChanged vol ->
            { model | volume = vol }

        GotLength length ->
            { model | duration = Just length }



-- VIEW


view : Routing.Roots -> ContentId -> Model -> Html Msg
view roots contentId model =
    Html.node "elm-video"
        -- see: src/components/elm-video.js
        [ Attr.attribute "src" <| Routing.rawUrl roots contentId
        , Attr.attribute "volume" <| String.fromFloat model.volume
        , Attr.attribute "current-time" <| MediaTime.attrString model.currentTime
        , Events.on "time-updated" decodeTimeUpdate
        , Events.on "duration-found" decodeGotLength
        , Events.on "decodeVolumeChange" decodeVolumeChange
        ]
        []


decodeTimeUpdate : Decoder Msg
decodeTimeUpdate =
    Decode.map (MediaTime.fromFloat >> TimeUpdate)
        (Decode.at [ "detail", "time" ] Decode.float)


decodeGotLength : Decoder Msg
decodeGotLength =
    Decode.map (MediaTime.fromFloat >> GotLength)
        (Decode.at [ "detail", "duration" ] Decode.float)


decodeVolumeChange : Decoder Msg
decodeVolumeChange =
    Decode.map VolumeChanged
        (Decode.at [ "detail", "volume" ] Decode.float)
