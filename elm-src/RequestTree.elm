module RequestTree exposing (FileNode(..), FileTree, mergeMetadata)

import ContentType exposing (ContentType)
import Dict exposing (Dict)
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


type alias FileTree =
    Dict String FileNode


type FileNode
    = File
        { contentType : ContentType
        , size : Int
        , modified : String
        }
    | Folder (Dict String FileNode)
      -- Upon a 40x for a given ContentId
    | Inaccessable FileTree
      -- Tree branch inserted due to user request. Generally updated
      -- to something else at the end of a request cycle. Visiting a
      -- corresponding route will result in the loading screen.
    | Placeholder FileTree
      -- Suspected: Represents a path part we think exists, but haven't actually
      -- visited. Could be a file or a folder.
    | Suspected
        -- Modified time, if it has one
        -- TODO: Write a parser so this can be time.posix
        (Maybe String)
        -- Size, if it has one. Note that size should always be reset
        -- with time
        (Maybe Int)
        -- Children (often none)
        (Dict String FileNode)


type alias CacheState =
    Time.Posix


mergeMetadata : (Result () MetadataResult -> msg) -> FileTree -> MetadataResult -> ( FileTree, Cmd msg )
mergeMetadata toMsg prevTree metadata =
    case metadata of
        MetadataRetrival.ApplicationException msg ->
            -- TODO: something more in this branch
            ( prevTree, Cmd.none )

        MetadataRetrival.Retry contentId ->
            -- TODO: Retries
            ( prevTree, Cmd.none )

        MetadataRetrival.Inaccessable _ contentId ->
            ( addInaccessable prevTree contentId, Cmd.none )

        MetadataRetrival.IsFolder contentId ->
            ( addFolder prevTree contentId, Cmd.none )

        MetadataRetrival.IsFile info ->
            ( addFile prevTree info, Cmd.none )


addFolder : FileTree -> ContentId -> FileTree
addFolder toMerge folder =
    let
        makeFolder prevNode =
            case prevNode of
                Just (Suspected _ _ children) ->
                    Folder children

                Just (Folder children) ->
                    Folder children

                Just (Placeholder children) ->
                    Folder children

                Just (File _) ->
                    Folder Dict.empty

                Nothing ->
                    Folder Dict.empty

                Just (Inaccessable children) ->
                    -- Make the assumption that if it was previously
                    -- inaccessable, we should wipe away the previous children
                    Folder Dict.empty
    in
    withMergeParents
        (Suspected Nothing Nothing)
        makeFolder
        toMerge
        folder


addInaccessable : FileTree -> ContentId -> FileTree
addInaccessable =
    withMergeParents Placeholder (\_ -> Inaccessable Dict.empty)


addFile :
    FileTree
    ->
        { contentId : ContentId
        , modified : Result HeaderError String
        , contentType : Result HeaderError String
        , size : Result HeaderError Int
        }
    -> FileTree
addFile toMerge file =
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
        (Suspected Nothing Nothing)
        makeFile
        toMerge
        file.contentId


withMergeParents : (FileTree -> FileNode) -> (Maybe FileNode -> FileNode) -> FileTree -> ContentId -> FileTree
withMergeParents parentBuilder createItem toMerge item =
    let
        kernel prevTree toAdd =
            case toAdd of
                [] ->
                    Dict.empty

                [ fname ] ->
                    Dict.insert fname (createItem <| Dict.get fname prevTree) prevTree

                fname :: rest ->
                    case Dict.get fname prevTree of
                        Just (Suspected _ _ children) ->
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

                        Just (Folder children) ->
                            Dict.insert fname
                                (Folder <|
                                    kernel children rest
                                )
                                prevTree

                        Just (File _) ->
                            Dict.insert fname
                                (Folder <|
                                    kernel Dict.empty rest
                                )
                                prevTree

                        Just (Inaccessable _) ->
                            Dict.insert fname
                                (Folder <|
                                    kernel Dict.empty rest
                                )
                                prevTree

                        Nothing ->
                            Dict.insert fname
                                (Folder <|
                                    kernel Dict.empty rest
                                )
                                prevTree
    in
    kernel toMerge item



-- Things come in as suspected, whether they get fetched is a function of
--   how far they are from the present location, how close they are to cache
--   timeout (?), and whether they exist.
-- Cache exists on a
-- Functions:
-- Distance between current place and given item for cache updating
