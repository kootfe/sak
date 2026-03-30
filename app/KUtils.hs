module KUtils where

import Data.Char (isSpace)
import Data.List (isPrefixOf)

import Control.Exception (IOException, catch)
import System.Directory (renameFile)
import System.FileLock (SharedExclusive (Exclusive), withFileLock)
import System.IO

startsWith :: String -> String -> Bool
startsWith prefix str = prefix `isPrefixOf` str

checkSAKStart :: String -> Bool
checkSAKStart = startsWith "# -SAK INFO-"

checkSAKEnd :: String -> Bool
checkSAKEnd = startsWith "# -SAK INFO END-"

checkHash :: String -> Bool
checkHash = startsWith "#"

checkKeyLine :: String -> Bool
checkKeyLine s = any (`isPrefixOf` s) ["ssh-", "ecdsa-"]

slice :: Int -> Int -> [a] -> [a]
slice x y arr = take (y - x + 1) (drop x arr)

trim :: String -> String
trim = f . f
 where
  f = reverse . dropWhile isSpace

safeAppend :: FilePath -> String -> IO ()
safeAppend path txt =
  withFileLock path Exclusive $ \_ -> do
    old <- readFile path `catch` handler
    let tmp = path ++ ".lock"

    withFile tmp WriteMode $ \h -> do
      hPutStr h (old ++ "\n" ++ txt)
      hFlush h
    renameFile tmp path
 where
  handler :: IOException -> IO String
  handler _ = return ""

safeWrite :: FilePath -> String -> IO ()
safeWrite path txt =
  withFileLock path Exclusive $ \_ -> do
    let tmp = path ++ ".lock"

    withFile tmp WriteMode $ \h -> do
      hPutStr h txt
      hFlush h
    renameFile tmp path

addHash :: String -> String
addHash ln
  | startsWith "# " ln = ln
  | otherwise = "# " ++ ln


removeHash :: String -> String
removeHash ln
  | startsWith "# " ln = drop 2 ln
  | otherwise = ln
