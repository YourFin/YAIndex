module Pages.Content exposing (..)

import DateFormat
import Dict
import FileTree exposing (FileNode(..))
import Filesize
import Html exposing (..)
import Html.Attributes exposing (class, href, id, style)
import List
import List.Nonempty as NE exposing (Nonempty(..))
import ListUtils as LU
import ListUtils.Nonempty as NEU
import Maybe exposing (Maybe(..))
import MiscView exposing (ariaHidden, ariaLabel)
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


contentView : Time.Zone -> FilesState -> Routing.ContentId -> Maybe String -> List (Html msg)
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

        fullBreadcrumb =
            NEU.appendToNonEmpty (NE.fromElement "Home") contentId

        -- [a,b] -> [(a, [a]), (b, [a,b])]
        zipBreadcrumb : Nonempty String -> Nonempty ( String, Nonempty String )
        zipBreadcrumb breadcrumb =
            case breadcrumb of
                NE.Nonempty head [] ->
                    NE.Nonempty ( head, NE.fromElement head ) []

                NE.Nonempty head (next :: tail) ->
                    NE.append
                        (zipBreadcrumb (Nonempty head (NEU.init (Nonempty next tail))))
                        (NE.fromElement ( NEU.last breadcrumb, breadcrumb ))

        zippedBreadcrumb =
            zipBreadcrumb fullBreadcrumb

        breadcrumbContainer item =
            section [ class "breadcrumb-section section" ]
                [ nav [ class "breadcrumb is-left is-medium", ariaLabel "breadcrumbs" ] [ item ]
                ]
    in
    [ breadcrumbContainer
        (ul []
            (zippedBreadcrumb
                |> NE.map
                    (\( item, NE.Nonempty _ path ) ->
                        Routing.toLink
                            (ContentRoute path Nothing)
                            item
                    )
                |> NEU.init
                |> List.map (\item -> li [] [ item ])
                |> (\lst ->
                        lst
                            ++ [ li [ class "is-active" ]
                                    [ a [ href "#" ]
                                        [ text <| NEU.last fullBreadcrumb ]
                                    ]
                               ]
                   )
            )
        )
    , div [ class "container is-fluid" ] [ body ]
    ]


renderFiles : Time.Zone -> FileNode -> Routing.ContentId -> Maybe String -> Html msg
renderFiles zone files contentId query =
    let
        makeHref : String -> Html.Attribute msg
        makeHref name =
            Routing.toHref (ContentRoute (contentId ++ [ name ]) Maybe.Nothing)

        thisItemName =
            Maybe.withDefault "/" (LU.last contentId)
    in
    case files of
        Folder folder ->
            table [ class "table", ariaLabel "List of files" ]
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

                                icon =
                                    case node of
                                        File _ ->
                                            i [ class "fas fa-file", ariaLabel "File" ] []

                                        Folder _ ->
                                            i [ class "fas fa-folder", ariaLabel "Folder" ] []
                            in
                            tr []
                                [ td []
                                    [ a [ makeHref name ]
                                        [ span [ class "icon is-small" ] [ icon ]
                                        , span [ id "content-table-name" ] [ text name ]
                                        ]
                                    ]
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
                , br [] []

                --, div [ class "buttons" ] [] - for multiple buttons
                , a [ Routing.contentIdRawHref contentId ]
                    [ button
                        [ class "button is-link" ]
                        [ span [] [ text "Open" ]
                        , span [ class "icon is-small", ariaHidden ]
                            [ i [ class "fas fa-chevron-circle-down" ] [] ]
                        ]
                    ]
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
