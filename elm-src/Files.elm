module Files exposing
    ( Files
    , Inode(..)
    , RetrivalError
    , at
    , insertAt
    , markInaccessable
    , none
    )

import ContentId exposing (ContentId)
import ContentType exposing (ContentType)
import Dict exposing (Dict)
import List.Nonempty exposing (Nonempty(..))
import Result exposing (Result(..))



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


type Files
    = Files FileTree_


none : Files
none =
    Files Dict.empty


at : ContentId -> Files -> Result RetrivalError Inode
at contentId files =
    let
        fileTree =
            filesToTree files

        kernel : ContentId -> FileTree_ -> Result RetrivalError Inode
        kernel contentId_ tree =
            case contentId_ of
                Nonempty fname [] ->
                    Dict.get fname tree
                        |> Maybe.map fileNodeToInode
                        |> Maybe.withDefault (Err Unknown)

                Nonempty fname (first :: rest) ->
                    Dict.get fname tree
                        |> Maybe.withDefault (Placeholder_ Dict.empty)
                        |> fNodeChildren
                        |> kernel (Nonempty first rest)
    in
    kernel contentId (filesToTree files)


insertAt : Inode -> ContentId -> Files -> Files
insertAt inode contentId =
    let
        fileNode =
            inodeToFileNode inode
    in
    mapTree (insertNode contentId fileNode)


markInaccessable : ContentId -> Files -> Files
markInaccessable contentId =
    mapTree (insertNode contentId <| Inaccessable_ Dict.empty)


type Inode
    = File
        { contentType : ContentType
        , size : Int
        , modified : String
        }
    | Folder (Maybe String) (Dict String Inode)


type RetrivalError
    = Unknown
    | Inaccessable



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

        Suspected_ mtime children ->
            Ok <| Folder mtime <| fileTreeToInodes children


inodeToFileNode : Inode -> FileNode_
inodeToFileNode inode =
    case inode of
        File info ->
            File_ info Dict.empty

        Folder mtime children ->
            Folder_ mtime <| Dict.map (always inodeToFileNode) children


filesToTree : Files -> FileTree_
filesToTree files =
    case files of
        Files tree ->
            tree


mapTree : (FileTree_ -> FileTree_) -> Files -> Files
mapTree f =
    filesToTree >> f >> Files


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


insertNode : ContentId -> FileNode_ -> FileTree_ -> FileTree_
insertNode contentId toInsert oldTree =
    mergeInTree oldTree (withParents contentId toInsert)


withParents : ContentId -> FileNode_ -> FileTree_
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
                Nonempty fname [] ->
                    Dict.singleton fname child

                Nonempty fname (first :: rest) ->
                    Dict.singleton fname <|
                        parentBuilder <|
                            kernel <|
                                Nonempty first rest
    in
    kernel contentId


{-| Merge two FileTrees, with precidence given to the SECOND one.

Note: the meat of this is defined in the (unexported) function inBoth, which is
where you want to start to try and understand why trees merge the way they do

-}
mergeInTree : FileTree_ -> FileTree_ -> FileTree_
mergeInTree old new =
    Dict.merge Dict.insert inBoth Dict.insert old new Dict.empty


{-| Mutually recursive with mergeInTree, contains all the logic for merging
key collisions (where both the old and new tree share a key).
-}
inBoth : String -> FileNode_ -> FileNode_ -> FileTree_ -> FileTree_
inBoth key oldVal newVal soFar =
    let
        mergedNode =
            case ( oldVal, newVal ) of
                --- New File
                ( File_ _ oldChildren, File_ info newChildren ) ->
                    File_ info <|
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
    in
    Dict.insert key mergedNode soFar


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
