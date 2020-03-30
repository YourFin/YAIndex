module RequestTree exposing (mergeMetadata)

import ContentType exposing (ContentType)
import Dict exposing (Dict)
import FileTree exposing (FileNode(..), FileTree)
import Http exposing (Expect)
import List
import ListUtils as ListU
import Maybe exposing (Maybe(..))
import MetadataRetrival exposing (HeaderError, MetadataResult, getMetadata)
import Platform.Cmd as Cmd
import Regex as Re
import RegexUtil as ReU
import Result exposing (Result(..))
import Routing exposing (ContentId)
import String
import Time


mergeFolder : FileTree -> ContentId -> FileTree -> FileTree
mergeFolder prevTree location newFolderChildren =
    let
        makeFolder prevNode =
            case prevNode of
                Just (Suspected mtime _) ->
                    Folder mtime newFolderChildren

                Just (Folder mtime _) ->
                    Folder mtime newFolderChildren

                _ ->
                    Folder Nothing newFolderChildren
    in
    withMergeParents
        (Suspected Nothing)
        makeFolder
        prevTree
        location


{-| Takes in previous tree and a metadata result, and returns a new tree with
the metadata results merged in and possibly a ContentId that should have folder
data fetched.
-}
mergeMetadata : FileTree -> MetadataResult -> ( FileTree, Maybe ContentId )
mergeMetadata prevTree metadata =
    case metadata of
        MetadataRetrival.ApplicationException msg ->
            -- TODO: something more in this branch
            ( prevTree, Nothing )

        MetadataRetrival.Retry contentId ->
            -- TODO: Retries
            ( prevTree, Nothing )

        MetadataRetrival.Inaccessable _ contentId ->
            ( mergeInaccessable prevTree contentId, Nothing )

        MetadataRetrival.IsFolder contentId ->
            ( mergeFolderMetadata prevTree contentId, Just contentId )

        MetadataRetrival.IsFile info ->
            ( mergeFile prevTree info, Nothing )


mergeFile :
    FileTree
    ->
        { contentId : ContentId
        , modified : Result HeaderError String
        , contentType : Result HeaderError String
        , size : Result HeaderError Int
        }
    -> FileTree
mergeFile toMerge file =
    let
        makeFile _ =
            File
                { contentType =
                    ListU.last file.contentId
                        |> Maybe.map
                            (ContentType.parse
                                (Result.toMaybe file.contentType)
                            )
                        |> Maybe.withDefault (ContentType.Unknown "Unknown")
                , size = Result.withDefault 0 file.size
                , modified = Result.withDefault "Unknown" file.modified
                }
    in
    withMergeParents
        (Suspected Nothing)
        makeFile
        toMerge
        file.contentId


withMergeParents :
    (FileTree -> FileNode)
    -> (Maybe FileNode -> FileNode)
    -> FileTree
    -> ContentId
    -> FileTree
withMergeParents parentBuilder createItem toMerge item =
    let
        kernel prevTree partialId =
            case partialId of
                [] ->
                    Dict.empty

                [ fname ] ->
                    Dict.insert fname (createItem <| Dict.get fname prevTree) prevTree

                fname :: rest ->
                    case Dict.get fname prevTree of
                        Just (Suspected _ children) ->
                            Dict.insert fname
                                (parentBuilder <|
                                    kernel children rest
                                )
                                prevTree

                        Just (Placeholder children) ->
                            Dict.insert fname
                                (parentBuilder <|
                                    kernel children rest
                                )
                                prevTree

                        Just (Folder mtime children) ->
                            Dict.insert fname
                                (Folder mtime <|
                                    kernel children rest
                                )
                                prevTree

                        Just (File _) ->
                            Dict.insert fname
                                (Folder Nothing <|
                                    kernel Dict.empty rest
                                )
                                prevTree

                        Just (Inaccessable _) ->
                            Dict.insert fname
                                (Folder Nothing <|
                                    kernel Dict.empty rest
                                )
                                prevTree

                        Nothing ->
                            Dict.insert fname
                                (Folder Nothing <|
                                    kernel Dict.empty rest
                                )
                                prevTree
    in
    kernel toMerge item
