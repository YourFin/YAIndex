module FolderView exposing (..)

import DateFormat
import Dict exposing (Dict)
import Files exposing (Files, Inode(..), RetrivalError(..))
import Filesize
import Html exposing (..)
import Html.Attributes as Attr exposing (class, href, id, style)
import List
import List.Nonempty as NE exposing (Nonempty(..))
import Maybe exposing (Maybe(..))
import MiscView exposing (ariaHidden, ariaLabel)
import Regex as Re
import Routing exposing (ContentId, Roots, Route)
import Time
import Url
import Util.List as LU
import Util.List.Nonempty as NEU


view : Roots -> Route -> Dict String Inode -> Html msg
view roots route children =
    table [ class "table", ariaLabel "List of files" ]
        [ thead []
            [ th [] [ text "File" ]
            , th [] [ text "Size" ]
            , th [] [ text "Modified" ]
            ]
        , Dict.toList children
            |> List.map
                (\( name, node ) ->
                    let
                        sizeText =
                            case node of
                                File file ->
                                    Filesize.format file.size

                                Folder _ _ ->
                                    "N/A"

                        modified =
                            case node of
                                File file ->
                                    file.modified

                                Folder mtime _ ->
                                    Maybe.withDefault "Unknown" mtime

                        icon =
                            case node of
                                File _ ->
                                    i [ class "fa fa-file", ariaLabel "File" ] []

                                Folder _ _ ->
                                    i [ class "fa fa-folder", ariaLabel "Folder" ] []
                    in
                    tr []
                        [ td []
                            [ a [ Routing.contentRef roots (route.contentId ++ [ name ]) ]
                                [ span [ class "icon is-small" ] [ icon ]
                                , span [ id "content-table-name" ] [ text name ]
                                ]
                            ]
                        , td [] [ text sizeText ]
                        , td []
                            [ text modified

                            --     (DateFormat.format
                            --         [ DateFormat.yearNumber
                            --         , DateFormat.text "-"
                            --         , DateFormat.monthFixed
                            --         , DateFormat.text "-"
                            --         , DateFormat.dayOfMonthFixed
                            --         , DateFormat.text " "
                            --         , DateFormat.hourMilitaryNumber
                            --         , DateFormat.text ":"
                            --         , DateFormat.minuteFixed
                            --         ]
                            --         zone
                            --         modified
                            --     )
                            ]
                        ]
                )
            |> tbody []
        ]
