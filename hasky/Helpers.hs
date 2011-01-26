{-
 -
 - Hasky, the Haskell interpreter
 - by Pavel Dvorak 2008-9
 -
 - Faculty of Informatics, Masaryk University
 -
 -}

-- | Support functions
module Helpers where

import Data.Char
import Data.List

{-|
  Drop all white space characters from the begin and the end of string.
-}
trim :: String -> String
trim = applyTwice (reverse . trim1)
       where trim1 = dropWhile isSpace
             applyTwice f = f . f

{-|
  Rip the entered name of the function to the module and function part.
  Function name can be written as \"function\" or \"module.function\".
-}
ripFunction :: String -> (String, String)
ripFunction s
    | not ('.' `elem` s) || last s == '.' = ("", s)
    | otherwise = let ripAt n s = (take n s, drop (n + 1) s)
                  in  ripAt (maximum $ findIndices (== '.') s) s

{-|
  Remove all matching parenthesis from the string. Example: ((x)) -> x.
-}
dropParenthesis :: String -> String
dropParenthesis [] = []
dropParenthesis x  = if head x == '(' && last x == ')'
                        then dropParenthesis . init $ tail x
                        else x
