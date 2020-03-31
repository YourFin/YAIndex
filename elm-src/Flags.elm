module Flags exposing (Flags, decode)

import Json.Decode as D
import Routing exposing (Roots)


type alias Flags =
    { serverIndex : String
    , webappRoot : String
    }


decode : D.Value -> Result String Flags
decode value =
    D.decodeValue flagsDecoder value
        |> Result.mapError D.errorToString


flagsDecoder : D.Decoder Flags
flagsDecoder =
    D.map2 Flags
        (D.field "server-index" D.string)
        (D.field "webapp-root" D.string)
