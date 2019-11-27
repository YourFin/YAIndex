module Tests.FileTreeTest exposing (..)

import FileTree exposing (..)
import Test exposing (describe, test, Test)
import Expect

lame : Test
lame = describe "foo"
       [ test "bar" <| \_ -> Expect.true "buzz" True ]
