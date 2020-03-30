module Util exposing (..)


flip : (a -> b -> c) -> (b -> a -> c)
flip f =
    \a b -> f b a
