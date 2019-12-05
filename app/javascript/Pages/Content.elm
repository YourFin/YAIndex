module Pages.Content exposing (..)

import DateFormat
import Dict
import FileTree exposing (FileNode(..))
import Filesize
import Html exposing (..)
import Html.Attributes exposing (class, style)
import List
import ListUtils as Lst
import Maybe
import MiscView
import Routing exposing (Route(..))
import Time
import Url


type FilesState
    = Loading
    | FilesError
    | Success FileTree.FileNode


loading : Html msg
loading =
    div []
        [ text "Loading..." ]


contentFileNode : FileNode -> Routing.ContentId -> Maybe FileNode
contentFileNode node path =
    -- Should probably switch Maybe with error, but meh
    case ( node, path ) of
        ( _, [] ) ->
            Maybe.Just node

        ( File file, _ ) ->
            Maybe.Nothing

        ( Folder folder, key :: rest ) ->
            case Dict.get key folder.children of
                Maybe.Just child ->
                    contentFileNode child rest

                Maybe.Nothing ->
                    Maybe.Nothing


contentView : Time.Zone -> FilesState -> Routing.ContentId -> Maybe String -> Html msg
contentView zone filesState contentId query =
    let
        body =
            case filesState of
                Loading ->
                    loading

                FilesError ->
                    div [ class "content" ]
                        [ text "Error loading files" ]

                Success files ->
                    case contentFileNode files contentId of
                        Maybe.Just fNode ->
                            renderFiles zone fNode contentId query

                        Maybe.Nothing ->
                            div [ class "content" ]
                                [ text "File not found" ]
    in
    div []
        [ nav [ class "breadcrumb is-right" ]
            [ ul []
                {- todo List.map (pathPart ->
                   li []
                   )
                -}
                [ text "todo" ]
            ]
        , body
        ]


renderFiles : Time.Zone -> FileNode -> Routing.ContentId -> Maybe String -> Html msg
renderFiles zone files contentId query =
    let
        makeLink : String -> Html msg
        makeLink name =
            Routing.toLink (ContentRoute (contentId ++ [ name ]) Maybe.Nothing) name

        thisItemName =
            Maybe.withDefault "/" (Lst.last contentId)
    in
    case files of
        Folder folder ->
            table [ class "table" ]
                [ thead []
                    [ th [] [ text "File" ]
                    , th [] [ text "Size" ]
                    , th [] [ text "Modified" ]
                    ]
                , Dict.toList folder.children
                    |> List.map
                        (\( name, node ) ->
                            let
                                sizeText =
                                    case node of
                                        File file ->
                                            Filesize.format file.size

                                        Folder _ ->
                                            "N/A"

                                modified =
                                    case node of
                                        File file ->
                                            file.modified

                                        Folder fol ->
                                            fol.modified
                            in
                            tr []
                                [ td [] [ makeLink name ]
                                , td [] [ text sizeText ]
                                , td []
                                    [ text
                                        (DateFormat.format
                                            [ DateFormat.yearNumber
                                            , DateFormat.text "-"
                                            , DateFormat.monthFixed
                                            , DateFormat.text "-"
                                            , DateFormat.dayOfMonthFixed
                                            , DateFormat.text " "
                                            , DateFormat.hourMilitaryNumber
                                            , DateFormat.text ":"
                                            , DateFormat.minuteFixed
                                            ]
                                            zone
                                            modified
                                        )
                                    ]
                                ]
                        )
                    |> tbody []
                ]

        File file ->
            div [ class "content is-medium" ]
                [ h1 [ class "title" ]
                    [ text thisItemName ]
                , text
                    ("Last modified: "
                        ++ DateFormat.format
                            [ DateFormat.monthNameAbbreviated
                            , DateFormat.text " "
                            , DateFormat.dayOfMonthSuffix
                            , DateFormat.text ", "
                            , DateFormat.yearNumber
                            , DateFormat.text " "
                            , DateFormat.hourFixed
                            , DateFormat.text ":"
                            , DateFormat.minuteFixed
                            , DateFormat.text " "
                            , DateFormat.amPmLowercase
                            ]
                            zone
                            file.modified
                    )
                , br [] []
                , text ("Size: " ++ Filesize.format file.size)
                ]



--renderFile : List String -> ( String, FileNode ) -> Html Message
--renderFile path ( name, node ) =
--    case node of
--        File file ->
--            li [] [ text name ]
--
--        Folder folder ->
--            if folder.expanded then
--                div []
--                    [ text name
--                    , folder.children
--                        |> Dict.toList
--                        |> List.map (renderFile (path ++ [ name ]))
--                        |> ul []
--                    ]
--
--            else
--                div []
--                    [ text name ]
-- MESSAGE
