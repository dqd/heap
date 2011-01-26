{-
 -
 - Hasky, the Haskell interpreter
 - by Pavel Dvorak 2008-9
 -
 - Faculty of Informatics, Masaryk University
 -
 -}

-- | Main (starting) module
module Main where

import Parser
import Helpers
import Modules
import Type
import IO
import Char
import qualified Data.Map as Map

{-|
  Main function, is used for executing the program and showing
  the program description. It loads automatically the Prelude library.
-}
main :: IO ()
main = do
    putStrLn "Hasky -- version 0.01"
    putStrLn "(Haskell interpreter)"
    -- TODO: process the arguments, save settings to a structure
    mod <- loadModule "Prelude" (Modules Map.empty Map.empty)
    putStrLn $ loadedModules mod
    mainLoop mod

{-|
  Show prompt symbol, read line from input and process it.
  Colon character is the attribute for command -- for more information
  see function commands.
-}
mainLoop :: Modules -> IO ()
mainLoop m = do
    putStr "> "
    hFlush stdout
    input <- catch getLine (\_ -> return ":q")

    if (not . null $ trim input) && (head $ trim input) == ':'
        then commands (toLower $ trim input !! 1) (drop 2 $ trim input) m
        else do
             putStrLn "Evaluation is not implemented yet."
             putStrLn "Use :h for help."
             mainLoop m

{-|
  Interpreter commands:
  F      = show info about functions and loaded modules;
  H or ? = help;
  I      = show info about the function;
  L      = load the module;
  M      = show the parsed module -- beware, can be very voluminous;
  P      = parse the expression;
  Q      = quit;
  R      = reload currently loaded modules;
  S      = show the source code of the function;
  T      = type of the expression;
  U      = unload the module.
-}
commands :: Char -> String -> Modules -> IO ()
commands 'q' _ _ = putStrLn "Woof!" -- as a good old sled dog
commands '?' s m = commands 'h' s m
commands 'h' _ m = do
    putStrLn "Help:\n"
    putStrLn $ "   <expression>  evaluate the expression"
          ++ " (does not work yet)"
    putStrLn ":f               show info about functions and modules"
    putStrLn ":h               this help"
    putStrLn ":i <function>    show info about the function"
    putStrLn ":l <module>      load the module"
    putStrLn ":m <module>      show the parsed module (use carefully)"
    putStrLn ":p <expression>  parse the expression"
    putStrLn ":q               quit"
    putStrLn ":r               reload currently loaded modules"
    putStrLn ":s <function>    show source code of the function"
    putStrLn ":t <expression>  the type of the expression"
    putStrLn ":u <module>      unload the module"
    mainLoop m
commands 'f' _ m = do
    putStrLn $ loadedFunctions m
    mainLoop m
commands 'i' s m = do
    putStrLn $ functionInfo s m
    mainLoop m
commands 'l' s m = do
    mod <- loadModule s m
    putStrLn $ loadedModules mod
    mainLoop mod
commands 'm' s m = do
    putStrLn $ showModule s m
    mainLoop m
commands 'p' s m = do
    putStrLn . parseShow . parseString $ "it = " ++ trim s
    mainLoop m
commands 'r' _ m = do
    mod <- reloadModules m
    putStrLn $ loadedModules mod
    mainLoop mod
commands 's' s m = do
    putStrLn $ showFunction s m
    mainLoop m
commands 't' s m = do
    putStrLn $ showType ("it = " ++ trim s) m
    mainLoop m
commands 'u' s m = do
    mod <- unloadModule s m
    putStrLn $ loadedModules mod
    mainLoop mod
commands  c  _ m = do
    putStrLn $ "Unknown command: ':" ++ [c] ++ "'."
    putStrLn "Use :h for help."
    mainLoop m
