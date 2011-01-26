import Data.List
import Data.Maybe
import Data.Either
import Network.URI
import Network.HTTP
import Control.Monad
import System.IO
import System.Directory
import System.Environment

boundary :: String
boundary = "AaB03x"

eol :: String
eol = "\r\n"

input :: String -> String -> String
input name value = "--" ++ boundary ++ eol ++ "Content-Disposition: form-data; name=\"" ++ name ++ "\"" ++ eol ++ eol ++ value ++ eol

main :: IO ()
main = do
    dirs <- getDirectoryContents "."
    fdirs <- filterM doesDirectoryExist $ filter (\x -> head x /= '.') dirs
    files <- mapM getDirectoryContents fdirs
    mapM_ (\(d,fs) -> mapM_ (\f -> upload d f) fs) . zip fdirs $ map (filter (\x -> head x /= '.')) files

upload :: String -> String -> IO ()
upload directory filename = do
    let uri = fromJust $ parseURI "http://www.tvsubtitles.net/add1.php"
        release = drop 3 directory
        season = reverse . drop 2 . reverse $ takeWhile (/= ' ') filename
        episode = dropWhile (== '0') . reverse . take 2 . reverse $ takeWhile (/= ' ') filename
        pathname = directory ++ "/" ++ filename

    file <- readFile pathname
    let body = input "tvshow" "71" ++ input "season" season ++ input "episode" episode ++ input "lang" "cz" ++ input "rip" "DVDRip" ++ input "release" release ++ input "author" "south-park.cz" ++ input "comment" "http://south-park.cz/" ++ input "go" "1" ++ "--" ++ boundary ++ eol ++ "Content-Disposition: form-data; name=\"upfile\"; filename=\"" ++ filename ++ "\"" ++ eol ++ "Content-Type: text/plain" ++ eol ++ eol ++ file ++ eol ++ "--" ++ boundary ++ "--"
    response <- simpleHTTP $ Request { rqURI=uri
                                     , rqMethod=POST
                                     , rqHeaders=[ Header HdrUserAgent       "Haskell TVSubtitles Uploader"
                                                 , Header HdrReferer         "http://www.tvsubtitles.net/add.html"
                                                 , Header HdrContentEncoding "UTF-8"
                                                 , Header HdrContentType     ("multipart/form-data; boundary=" ++ boundary)
                                                 , Header HdrAccept          "text/plain"
                                                 , Header HdrContentLength   (show $ length body)
                                                 ]
                                     , rqBody=body
                                     }
    let code = either (\_ -> (5, 0, 0)) rspCode response
    putStr $ pathname ++ " "
    if code == (3, 0, 2)
        then putStrLn "UPLOADED"
        else putStrLn "FAILED"
