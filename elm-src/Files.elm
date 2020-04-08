module Files exposing
    ( FileAlias
    , Files
    , Inode(..)
    , InputInode(..)
    , RetrivalError(..)
    , at
    , insertAt
    , markInaccessable
    , none
    , updateAt
    )

import ContentType exposing (ContentType)
import Dict exposing (Dict)
import List.Nonempty exposing (Nonempty(..))
import Result exposing (Result(..))
import Routing exposing (ContentId)



--------------------------------------------------------------------------------
-- READER'S NOTE:                                                             --
--                                                                            --
-- All types that end with an underscore are internal types, which map pretty --
-- well onto their exposed counterparts. Underscores at the end of variable   --
-- names are typically just there to avoid shadowing.                         --
--------------------------------------------------------------------------------
----------------
-- Public Api --
----------------


{-| Known information about file system server-side

The "model" of this module, if you will. Files is deliberatly opaque, and should
be accessed through the various functions exposed in this module.

-}
type Files
    = Files FileNode_


type InputInode
    = InputFile FileAlias
    | UnexploredFolder (Maybe String)
    | ExploredFolder (Dict String InputInode)


type Inode
    = File FileAlias
    | Folder (Maybe String) (Dict String Inode)


type alias FileAlias =
    { contentType : ContentType
    , size : Int
    , modified : String
    }


{-| The empty Files object.

Primarily use is in "init" in main

-}
none : Files
none =
    Files (Placeholder_ Dict.empty)


{-| Get the Inode at a given content id, if it's there.
-}
at : ContentId -> Files -> Result RetrivalError Inode
at contentId files =
    let
        kernel : ContentId -> FileNode_ -> Result RetrivalError Inode
        kernel contentId_ node =
            case contentId_ of
                [] ->
                    fileNodeToInode node

                fname :: rest ->
                    Dict.get fname (fNodeChildren node)
                        |> Maybe.withDefault (Placeholder_ Dict.empty)
                        |> kernel rest
    in
    kernel contentId (filesToNode files)


{-| Insert an InputInode at a given ContentId.
-}
insertAt : InputInode -> ContentId -> Files -> Files
insertAt iinode contentId =
    let
        fileNode =
            iinodeToFileNode iinode
    in
    mapNode (insertNode contentId fileNode)


{-| Like insert at, but takes an Inode instead of an InputInode
-}
updateAt : Inode -> ContentId -> Files -> Files
updateAt inode contentId =
    let
        fileNode =
            inodeToFileNode inode
    in
    mapNode (insertNode contentId fileNode)


{-| Mark a given ContentId as inaccessable (i.e. returned a 40x).
-}
markInaccessable : ContentId -> Files -> Files
markInaccessable contentId =
    mapNode (insertNode contentId <| Inaccessable_ Dict.empty)


{-| Error type returned by at.
-}
type RetrivalError
    = Unknown --| The given ContentId has not been fetched before
    | Inaccessable --| The given ContentId is not accessable



-----------------------------------------
-- Public-Private Conversion Functions --
-----------------------------------------


fNodeChildren : FileNode_ -> FileTree_
fNodeChildren node =
    case node of
        File_ _ children ->
            children

        Folder_ _ children ->
            children

        Suspected_ _ children ->
            children

        Placeholder_ children ->
            children

        Inaccessable_ children ->
            children


inodeToFileNode : Inode -> FileNode_
inodeToFileNode inode =
    case inode of
        File info ->
            File_ info Dict.empty

        Folder mtime children ->
            Folder_ mtime <| Dict.map (always inodeToFileNode) children


iinodeToFileNode : InputInode -> FileNode_
iinodeToFileNode inode =
    case inode of
        InputFile info ->
            File_ info Dict.empty

        ExploredFolder children ->
            Folder_ Nothing <| Dict.map (always iinodeToFileNode) children

        UnexploredFolder mtime ->
            Folder_ mtime Dict.empty


fileNodeToInode : FileNode_ -> Result RetrivalError Inode
fileNodeToInode node =
    case node of
        File_ info _ ->
            Ok <| File info

        Folder_ mtime children ->
            Ok <| Folder mtime <| fileTreeToInodes children

        Inaccessable_ _ ->
            Err Inaccessable

        Placeholder_ _ ->
            Err Unknown

        Suspected_ _ _ ->
            -- This right here is /why/ we have the suspected type
            Err Unknown


filesToNode : Files -> FileNode_
filesToNode files =
    case files of
        Files node ->
            node


mapNode : (FileNode_ -> FileNode_) -> Files -> Files
mapNode f =
    filesToNode >> f >> Files


fileTreeToInodes : FileTree_ -> Dict String Inode
fileTreeToInodes =
    Dict.foldl fileTreeToInodesHelper Dict.empty


fileTreeToInodesHelper : String -> FileNode_ -> Dict String Inode -> Dict String Inode
fileTreeToInodesHelper key val soFar =
    case fileNodeToInode val of
        Ok inode ->
            Dict.insert key inode soFar

        Err _ ->
            soFar



---------------
-- Internals --
---------------


type
    FileNode_
    -- Yes, files have children. They should never be rendered, but this is
    -- required because users might try and visit a path for which a file is
    -- supposed to be a parent directory. Children should never be anything
    -- other than placeholders and inaccessable.
    = File_
        { contentType : ContentType
        , size : Int
        , modified : String
        }
        FileTree_
    | Folder_ (Maybe String) FileTree_
      -- Upon a 40x for a given ContentId.
      -- Has children to allow caching a 40x response for a node under an
      -- inaccessable parent.
      -- Should not be rendered as folder children.
    | Inaccessable_ FileTree_
      -- Tree branch inserted due to user request. Generally updated
      -- to something else at the end of a request cycle. Visiting a
      -- corresponding route will result in the loading screen.
      -- Placeholders should not be rendered as folder children.
    | Placeholder_ FileTree_
      -- Suspected: Represents a path part implied to exist by server-side
      -- data, but hasn't been actually visited. Could be a file or a folder.
    | Suspected_ (Maybe String) FileTree_


type alias FileTree_ =
    Dict String FileNode_


insertNode : ContentId -> FileNode_ -> FileNode_ -> FileNode_
insertNode contentId toInsert oldRoot =
    mergeNodes oldRoot (withParents contentId toInsert)


withParents : ContentId -> FileNode_ -> FileNode_
withParents contentId child =
    let
        parentBuilder : FileTree_ -> FileNode_
        parentBuilder =
            case child of
                File_ _ _ ->
                    Suspected_ Nothing

                Folder_ _ _ ->
                    Suspected_ Nothing

                Inaccessable_ _ ->
                    Placeholder_

                Placeholder_ _ ->
                    Placeholder_

                Suspected_ _ _ ->
                    Suspected_ Nothing

        kernel contentId_ =
            case contentId_ of
                [] ->
                    child

                fname :: rest ->
                    parentBuilder <| Dict.singleton fname <| kernel rest
    in
    kernel contentId



----
---- FileTree merging
----


{-| The meat of 'er
TODO: Folders need to clobber nonexistant children upon insertion
-}
mergeNodes : FileNode_ -> FileNode_ -> FileNode_
mergeNodes oldNode newNode =
    case ( oldNode, newNode ) of
        --- New File
        ( File_ oldInfo oldChildren, File_ newInfo newChildren ) ->
            File_ (mergeFiles oldInfo newInfo) <|
                mergeInaccessableTrees
                    -- Seperate recusion branch
                    oldChildren
                    newChildren

        ( Folder_ _ oldChildren, File_ info newChildren ) ->
            File_ info <|
                mergeInaccessableTrees
                    -- Seperate recusion branch
                    oldChildren
                    newChildren

        ( Inaccessable_ oldChildren, File_ info newChildren ) ->
            File_ info <|
                mergeInaccessableTrees
                    -- Seperate recusion branch
                    oldChildren
                    newChildren

        ( Placeholder_ oldChildren, File_ info newChildren ) ->
            File_ info <|
                mergeInaccessableTrees
                    -- Seperate recusion branch
                    oldChildren
                    newChildren

        ( Suspected_ _ oldChildren, File_ info newChildren ) ->
            File_ info <|
                mergeInaccessableTrees
                    -- Seperate recusion branch
                    oldChildren
                    newChildren

        --- New Folder
        ( Folder_ oldMtime oldChildren, Folder_ newMtime newChildren ) ->
            Folder_
                (mergeMaybe oldMtime newMtime)
                (mergeInTree oldChildren newChildren)

        ( Suspected_ oldMtime oldChildren, Folder_ newMtime newChildren ) ->
            Folder_
                (mergeMaybe oldMtime newMtime)
                (mergeInTree oldChildren newChildren)

        ( Placeholder_ oldChildren, Folder_ newMtime newChildren ) ->
            Folder_ newMtime (mergeInTree oldChildren newChildren)

        ( Inaccessable_ _, Folder_ newMtime newChildren ) ->
            -- If we see a new folder, it sorta makes sense to clober
            -- the inaccessable cache
            Folder_ newMtime newChildren

        ( File_ _ oldChildren, Folder_ mtime newChildren ) ->
            -- If we see a new folder, it sorta makes sense to clober
            -- the inaccessable cache
            Folder_ mtime newChildren

        --- New Inaccessable
        ( Inaccessable_ oldChildren, Inaccessable_ newChildren ) ->
            Inaccessable_ <|
                mergeInaccessableTrees
                    -- Seperate recusion branch
                    oldChildren
                    newChildren

        ( Placeholder_ oldChildren, Inaccessable_ newChildren ) ->
            Inaccessable_ <|
                mergeInaccessableTrees
                    oldChildren
                    newChildren

        ( File_ _ oldChildren, Inaccessable_ newChildren ) ->
            Inaccessable_ <|
                mergeInaccessableTrees
                    oldChildren
                    newChildren

        ( _, Inaccessable_ newChildren ) ->
            -- If it's supected or a folder, we have a pretty good idea
            -- that most of the children are now invalid
            Inaccessable_ newChildren

        -- New Placeholder
        ( File_ info oldChildren, Placeholder_ newChildren ) ->
            File_ info <| mergeInaccessableTrees oldChildren newChildren

        ( Folder_ mtime oldChildren, Placeholder_ newChildren ) ->
            Folder_ mtime <| mergeInTree oldChildren newChildren

        ( Inaccessable_ oldChildren, Placeholder_ newChildren ) ->
            Inaccessable_ <| mergeInaccessableTrees oldChildren newChildren

        ( Placeholder_ oldChildren, Placeholder_ newChildren ) ->
            Placeholder_ <| mergeInTree oldChildren newChildren

        ( Suspected_ mtime oldChildren, Placeholder_ newChildren ) ->
            Suspected_ mtime <| mergeInTree oldChildren newChildren

        --- New suspected
        ( File_ _ oldChildren, Suspected_ mtime newChildren ) ->
            Suspected_ mtime <| mergeInTree oldChildren newChildren

        ( Folder_ oldMtime oldChildren, Suspected_ newMtime newChildren ) ->
            Folder_
                (mergeMaybe oldMtime newMtime)
                (mergeInTree oldChildren newChildren)

        ( Inaccessable_ oldChildren, Suspected_ mtime newChildren ) ->
            Suspected_ mtime <| mergeInTree oldChildren newChildren

        ( Placeholder_ oldChildren, Suspected_ mtime newChildren ) ->
            Suspected_ mtime <| mergeInTree oldChildren newChildren

        ( Suspected_ oldMtime oldChildren, Suspected_ newMtime newChildren ) ->
            Folder_
                (mergeMaybe oldMtime newMtime)
                (mergeInTree oldChildren newChildren)


{-| If either of the arguments have a value, return it in the output.
Precidence given to the second argument
-}
mergeMaybe : Maybe a -> Maybe a -> Maybe a
mergeMaybe old new =
    case ( old, new ) of
        ( _, Just new_ ) ->
            Just new_

        ( Just old_, Nothing ) ->
            Just old_

        ( Nothing, Nothing ) ->
            Nothing


{-| Merge two FileTrees, with precidence given to the SECOND one.
-}
mergeInTree : FileTree_ -> FileTree_ -> FileTree_
mergeInTree old new =
    Dict.merge Dict.insert inBoth Dict.insert old new Dict.empty


inBoth : String -> FileNode_ -> FileNode_ -> FileTree_ -> FileTree_
inBoth key old new =
    Dict.insert key <| mergeNodes old new


{-| Merge two inaccessable trees.

Main idea here is that we need to hold on to (and merge) placeholders and
inaccessable nodes, but everything else gets dropped.

-}
mergeInaccessableTrees : FileTree_ -> FileTree_ -> FileTree_
mergeInaccessableTrees old new =
    let
        inBoth_ : String -> FileNode_ -> FileNode_ -> FileTree_ -> FileTree_
        inBoth_ key oldVal newVal soFar =
            let
                insert node =
                    Dict.insert key node soFar
            in
            case ( oldVal, newVal ) of
                ( Inaccessable_ old_, Inaccessable_ new_ ) ->
                    insert <| Inaccessable_ <| mergeInaccessableTrees old_ new_

                ( Placeholder_ old_, Inaccessable_ new_ ) ->
                    insert <| Inaccessable_ <| mergeInaccessableTrees old_ new_

                ( Inaccessable_ old_, Placeholder_ new_ ) ->
                    insert <| Inaccessable_ <| mergeInaccessableTrees old_ new_

                ( Placeholder_ old_, Placeholder_ new_ ) ->
                    insert <| Placeholder_ <| mergeInaccessableTrees old_ new_

                ( _, Inaccessable_ new_ ) ->
                    -- Drop the old tree
                    insert <| Inaccessable_ new_

                ( _, Placeholder_ new_ ) ->
                    -- Drop the old tree
                    insert <| Placeholder_ new_

                ( _, _ ) ->
                    -- Filter out anything else
                    soFar
    in
    Dict.merge insertSurviving inBoth insertSurviving old new Dict.empty


mergeFiles : FileAlias -> FileAlias -> FileAlias
mergeFiles oldFile newFile =
    { contentType = ContentType.merge oldFile.contentType newFile.contentType
    , modified = newFile.modified
    , size = newFile.size
    }


insertSurviving : String -> FileNode_ -> FileTree_ -> FileTree_
insertSurviving key value soFar =
    if survivesInaccessable value then
        Dict.insert key value soFar

    else
        soFar


survivesInaccessable : FileNode_ -> Bool
survivesInaccessable node =
    case node of
        Inaccessable_ _ ->
            True

        Placeholder_ _ ->
            True

        _ ->
            False
