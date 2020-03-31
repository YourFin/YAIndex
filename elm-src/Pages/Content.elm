module Pages.Content exposing (..)

import DateFormat
import Dict
import Files exposing (Files, Inode(..), RetrivalError(..))
import Filesize
import Html exposing (..)
import Html.Attributes as Attr exposing (class, href, id, style)
import List
import List.Nonempty as NE exposing (Nonempty(..))
import Maybe exposing (Maybe(..))
import MiscView exposing (ariaHidden, ariaLabel)
import Regex as Re
import Routing exposing (ContentId, Route(..))
import Time
import Url
import Util.List as LU
import Util.List.Nonempty as NEU


loading : Html msg
loading =
    div []
        [ text "Loading..." ]


contentView : Time.Zone -> Files -> ContentId -> Maybe String -> List (Html msg)
contentView zone files contentId query =
    let
        body =
            case Files.at contentId files of
                Err Unknown ->
                    loading

                Err Inaccessable ->
                    div [ class "content" ]
                        [ text "Could not find file" ]

                Ok inode ->
                    renderFiles zone inode contentId query

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


renderFiles : Time.Zone -> Inode -> ContentId -> Maybe String -> Html msg
renderFiles zone files contentId query =
    let
        makeHref : String -> Html.Attribute msg
        makeHref name =
            Routing.toHref (ContentRoute (contentId ++ [ name ]) Maybe.Nothing)

        thisItemName =
            Maybe.withDefault "/" (LU.last contentId)

        isImage =
            [ "\\.jpg$", "\\.jpeg", "\\.png$", "\\.gif$" ]
                |> List.map Re.fromString
                |> List.map (Maybe.withDefault Re.never)
                |> List.map (\pat -> Re.contains pat thisItemName)
                |> List.foldl (||) False
    in
    case files of
        Folder _ children ->
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
                                    [ a [ makeHref name ]
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

        File file ->
            div [ class "content is-medium" ]
                [ h1 [ class "title" ]
                    [ text thisItemName ]
                , text
                    ("Last modified: "
                        -- ++ DateFormat.format
                        --     [ DateFormat.monthNameAbbreviated
                        --     , DateFormat.text " "
                        --     , DateFormat.dayOfMonthSuffix
                        --     , DateFormat.text ", "
                        --     , DateFormat.yearNumber
                        --     , DateFormat.text " "
                        --     , DateFormat.hourFixed
                        --     , DateFormat.text ":"
                        --     , DateFormat.minuteFixed
                        --     , DateFormat.text " "
                        --     , DateFormat.amPmLowercase
                        --     ]
                        --     zone
                        ++ file.modified
                    )
                , br [] []
                , text ("Size: " ++ Filesize.format file.size)
                , br [] []

                --, div [ class "buttons" ] [] - for multiple buttons
                , a [ Routing.contentIdRawHref contentId ]
                    (if isImage then
                        [ img
                            [ Attr.src <| Routing.contentIdRawUrl contentId
                            , Attr.alt thisItemName
                            ]
                            []
                        ]

                     else
                        [ button
                            [ class "button is-link" ]
                            [ span [] [ text "Open" ]
                            , span [ class "icon is-small", ariaHidden ]
                                [ i [ class "fa fa-chevron-circle-down" ] [] ]
                            ]
                        ]
                    )
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
