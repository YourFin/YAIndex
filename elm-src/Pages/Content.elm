module Pages.Content exposing (..)

import DateFormat
import Dict
import Files exposing (Files, Inode(..), RetrivalError(..))
import Filesize
import FolderView
import Html exposing (..)
import Html.Attributes as Attr exposing (class, href, id, style)
import List
import List.Nonempty as NE exposing (Nonempty(..))
import Maybe exposing (Maybe(..))
import MiscView exposing (ariaHidden, ariaLabel)
import Pages.File as File
import Regex as Re
import Routing exposing (ContentId, Roots, Route)
import Time
import Url
import Util.List as LU
import Util.List.Nonempty as NEU


loading : Html msg
loading =
    div []
        [ text "Loading..." ]


contentView : Time.Zone -> Roots -> Files -> Route -> List (Html msg)
contentView zone roots files route =
    let
        body =
            case Files.at route.contentId files of
                Err Unknown ->
                    loading

                Err Inaccessable ->
                    div [ class "content" ]
                        [ text "Could not find file" ]

                Ok inode ->
                    renderFiles zone roots files inode route

        fullBreadcrumb =
            NEU.appendToNonEmpty (NE.fromElement "Home") route.contentId

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
                        Routing.contentLink
                            roots
                            path
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


renderFiles : Time.Zone -> Routing.Roots -> Files -> Inode -> Route -> Html msg
renderFiles zone roots files node route =
    let
        makeHref : String -> Html.Attribute msg
        makeHref name =
            Routing.contentRef roots (route.contentId ++ [ name ])

        thisItemName =
            Maybe.withDefault "/" (LU.last route.contentId)
    in
    case node of
        Folder _ children ->
            FolderView.view roots route children

        File file ->
            File.view roots files route file



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
