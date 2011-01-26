module Directory where
import Prelude
import Time(ClockTime)

data Permissions
  = Permissions { readable, writable, executable, searchable :: Bool }
  deriving ( Eq, Ord, Read, Show )

foreign import ccall unsafe createDirectory :: FilePath -> IO ()
foreign import ccall unsafe removeDirectory :: FilePath -> IO ()
foreign import ccall unsafe removeFile :: FilePath -> IO ()
foreign import ccall unsafe renameDirectory  :: FilePath -> FilePath -> IO ()
foreign import ccall unsafe renameFile  :: FilePath -> FilePath -> IO ()

foreign import ccall unsafe getDirectoryContents  :: FilePath -> IO [FilePath]
foreign import ccall unsafe getCurrentDirectory  :: IO FilePath
foreign import ccall unsafe setCurrentDirectory  :: FilePath -> IO ()

foreign import ccall unsafe doesFileExist :: FilePath -> IO Bool
foreign import ccall unsafe doesDirectoryExist :: FilePath -> IO Bool

foreign import ccall unsafe getPermissions :: FilePath -> IO Permissions
foreign import ccall unsafe setPermissions :: FilePath -> Permissions -> IO ()

foreign import ccall unsafe getModificationTime :: FilePath -> IO ClockTime
