module System where
import Prelude

foreign import ccall unsafe system :: String -> IO ExitCode
foreign import ccall unsafe progLine :: [String]
foreign import ccall unsafe getEnv :: String -> IO String

data ExitCode = ExitSuccess | ExitFailure Int deriving (Eq,Ord,Show,Read)
--instance Show ExitCode

getArgs :: IO [String]
getProgName :: IO String

getArgs = return progArgs
getProgName = return progName

exitWith :: ExitCode -> IO a
exitWith e = error ("exithWith "++show e)

exitFailure :: IO a
exitFailure = exitWith (ExitFailure 1) -- system dependent...

progName:progArgs=progLine
