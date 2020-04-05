module Pages.File exposing (..)

import ContentType exposing (ContentType(..))
import ContentType.Video as Video
import Files exposing (FileAlias, Files)
import Filesize
import Html exposing (..)
import Html.Attributes as Attr exposing (class, href, id, style)
import MiscView exposing (ariaHidden, ariaLabel)
import Routing exposing (ContentId, Route)
import Util.List as LU


view : Routing.Roots -> Files -> Route -> FileAlias -> Html msg
view roots files route file =
    div [ class "content is-medium" ]
        [ h1 [ class "title" ]
            [ text <| itemName route.contentId ]
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
        , case file.contentType of
            Image ->
                a [ Routing.rawRef roots route.contentId ]
                    [ img
                        [ Attr.src <| Routing.rawUrl roots route.contentId
                        , Attr.alt <| itemName route.contentId
                        ]
                        []
                    ]

            Video model ->
                Video.view roots route.contentId model

            Unknown _ ->
                a [ Routing.rawRef roots route.contentId ]
                    [ button
                        [ class "button is-link" ]
                        [ span [] [ text "Open" ]
                        , span [ class "icon is-small", ariaHidden ]
                            [ i [ class "fa fa-chevron-circle-down" ] [] ]
                        ]
                    ]
        ]


itemName : ContentId -> String
itemName contentId =
    Maybe.withDefault "Root" (LU.last contentId)
