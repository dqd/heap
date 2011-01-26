{-
 -
 - Hasky, the Haskell interpreter
 - by Pavel Dvorak 2008-9
 -
 - Faculty of Informatics, Masaryk University
 -
 -}

-- | Haskell modules management
module Modules
( Modules(..)
, MapMods
, MapFuns
, loadModule
, unloadModule
, reloadModules
, loadedModules
, loadedFunctions
, showModule
, showFunction
, functionInfo
, unambiguousFunction
, sourceCodeNotFound
) where

import Parser
import Helpers
import IO
import Monad
import Directory
import Data.Map
import Data.List
import Text.Printf
import Language.Haskell.Syntax
import Language.Haskell.Pretty

type MapMods = Map String HsModule    -- map of modules
type MapFuns = Map String [String]    -- map of functions in modules
data Modules = Modules MapMods MapFuns

{-|
  Possible source code locations. It depends on order. 
-}
sourceLocations :: [String]
sourceLocations = ["haskell98/", "tests/", ""]

{-|
  Take a name of a Haskell module and load it. If there are some imports,
  load these modules too.
-}
loadModule :: String -> Modules -> IO Modules
loadModule s (Modules m f) = do
    let name = trim s
    mod <- openModule name
    case mod of
         Nothing -> return (Modules m f)
         Just  x -> resolveModules
                    ((getImports x) Data.List.\\ (name:(keys m)))
                    (Modules (Data.Map.insert name x m) (updateTable x f))

{-|
  Take a list of possible imports and try to load them. Does not support
  partial imports yet.
-}
resolveModules :: [String] -> Modules -> IO Modules
resolveModules []     ms  = return ms
resolveModules (x:xs) ms  = do
    mod <- loadModule x ms
    resolveModules xs mod

{-|
  Create list of all function that are defined in the module and
  write it to the lookup table.
-}
updateTable :: HsModule -> MapFuns -> MapFuns
updateTable m f = addToTable (getFunctions m) (getModuleName m) f

{-|
  Add a function name with corresponding module name if is
  not already present.
-}
addToTable :: [String] -> String -> MapFuns -> MapFuns
addToTable []  _ f = f
addToTable (x:xs) n f
    | Data.List.null x = addToTable xs n f
    | member x f       =
                 if n `elem` f ! x
                    then addToTable xs n f
                    else addToTable xs n (Data.Map.adjust (n:) x f) 
    | otherwise        = addToTable xs n (Data.Map.insert  x [n] f)

{-| 
  Try to find, open and parse a Haskell module file.
-}
openModule :: String -> IO (Maybe HsModule)
openModule name = do
    files <- filterM doesFileExist [pref ++ name ++ suff |
                                    pref <- sourceLocations,
                                    suff <- [".hs", ".lhs",  ""]]
    if Data.List.null files
       then do
            putStrLn $ "Module " ++ name ++ " was not found."
            return Nothing
       else do
            content <- openFile (head files) ReadMode >>= hGetContents 
            case parseFile name content of
                 Left  msg -> do
                              putStrLn msg
                              return Nothing
                 Right mod -> return $ Just mod

{-|
  List all loaded modules.
-}
loadedModules :: Modules -> String
loadedModules (Modules m _)
    | Data.Map.null m  = error "I need some modules!"
    | otherwise        = "Loaded modules: " ++  (head $ keys m)
                         ++ concatMap (", " ++) (tail $ keys m) ++ "."

{-|
  Unload a Haskell module, if is loaded.
-}
unloadModule :: String -> Modules -> IO Modules
unloadModule s (Modules m f) = do
    let name = trim s 
    if member name m
       then return (Modules (Data.Map.delete name m) (cleanTable name f))
       else do
            putStrLn $ moduleIsNotLoaded name
            return (Modules m f)

{-|
  Delete all values (or keys) from lookup table that are
  included in the module.
-}
cleanTable :: String -> MapFuns -> MapFuns
cleanTable s f = mapMaybe (deleteFromTable s) f

{-|
  Return nothing if the value contains only the name of the function.
  Otherwise just delete the name from the value if is present.
-}
deleteFromTable :: String -> [String] -> Maybe [String]
deleteFromTable s v
    | s `elem` v = if length v == 1
                      then Nothing
                      else Just $ Data.List.delete s v
    | otherwise  =         Just v

{-|
  Load again all loaded Haskell modules.
-}
reloadModules :: Modules -> IO Modules
reloadModules (Modules m _) = do
    putStrLn "Reloading modules..."
    foldr (\s m -> do mod <- m; loadModule s mod)
          (return (Modules empty empty)) (keys m)

{-|
  Error message about module that is not loaded.
-}
moduleIsNotLoaded :: String -> String
moduleIsNotLoaded name = "Module " ++ name ++ " is not loaded."

{-|
  Error message about function that is not defined.
-}
sourceCodeNotFound :: String
sourceCodeNotFound = "Source code was not found."

{-|
  Error message that should show when are two or more versions
  of the function present -- in more modules.
-}
unambiguousFunction :: String -> [String] -> String
unambiguousFunction f ms = "Unambiguous function -- did you mean "
                           ++ head ms ++ "." ++ f
                           ++ concatMap (\x -> " or " ++ x ++ "." ++ f) ms
                           ++ "?"

{-|
  Show parsed content of the module. Warning: can be very voluminous. 
-}
showModule :: String -> Modules -> String
showModule s (Modules m _) =
    let name = trim s
    in  case Data.Map.lookup name m of
             Just  x -> show x
             Nothing -> moduleIsNotLoaded name

{-|
  Show information about number of loaded modules and functions and
  display the name of all present functions.
-}
loadedFunctions :: Modules -> String
loadedFunctions (Modules m f) =
    "Number of the loaded modules:   " ++ printf "%3d" (size m) ++ "\n" ++
    "Number of the loaded functions: " ++ printf "%3d" (size f) ++ "\n" ++
    (trim $ concatMap (" " ++) $ keys f)

{-|
  Show information about the function. For now, it is just a module
  in which the function is defined.
-}
functionInfo :: String -> Modules -> String
functionInfo s (Modules m f) =
    let mod = (fst . ripFunction $ trim s)
        fun = (snd . ripFunction $ trim s)
    in  case Data.Map.lookup fun f of
             Just  x ->
                   if not (Data.List.null mod) && mod `elem` x 
                      then "Function " ++ fun    ++ " from module "
                           ++ mod ++ "."
                      else "Function " ++ trim s ++ " is defined in "
                           ++ "modules:" ++ concatMap (" " ++) x ++ "."
             Nothing -> sourceCodeNotFound


{-|
  Find a source code of a function and return the declarations.
-}
getFunction :: String -> Modules -> Either String [HsDecl]
getFunction s (Modules m f) =
    let mod = (fst $ ripFunction s)
        fun = (snd $ ripFunction s)
    in  case Data.Map.lookup fun f of
             Just  x ->
                   if not (Data.List.null mod) && mod `elem` x
                      then Right $ getFunBody fun $ m ! mod
                      else if Data.List.null  mod && length x /= 1
                              then Left  $ unambiguousFunction fun x
                              else Right $ getFunBody fun $ m ! (head x)
             Nothing -> Left sourceCodeNotFound

{-|
  Show source code of the desired function.
-}
showFunction :: String -> Modules -> String
showFunction s ms = case getFunction (dropParenthesis $ trim s) ms of
                         Left msg -> msg
                         Right [] -> sourceCodeNotFound
                         Right  f -> trim $ concatMap
                                     (\x -> prettyPrint x ++ "\n") f
