module ContentType.Video exposing (..)

import Array exposing (Array)
import ContentType.Video.AudioTrack as AudioTrack exposing (AudioTrack)
import ContentType.Video.MediaTime as MediaTime exposing (MediaTime)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode exposing (Value)


type alias Model =
    { currentTime : MediaTime
    , muted : Bool
    , volume : Float
    , duration : MediaTime
    , videoTrackIdx : Int
    , audioTrackIdx : Int
    , subTrackIdx : Maybe Int
    }


{-| Internal video bits that are /not/ saved
-}
type alias Ephemerals =
    { audioTracks : Array AudioTrack
    , videoTracks : () -- Probably a dict?
    , subTracks : ()
    , playing : Bool
    }
