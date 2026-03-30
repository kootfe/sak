module Main where

import Control.Exception (IOException, catch)
import Data.Char (toLower)
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import Data.UUID (UUID)
import qualified Data.UUID.V4 as UUIDv4
import KUtils
import SAK
import System.Directory (getHomeDirectory)
import System.Environment (getArgs)
import System.FilePath ((</>))

safeIndex :: [a] -> Int -> Maybe a
safeIndex xs i = listToMaybe (drop i xs)

getFile :: IO FilePath
getFile = do
  homeDir <- getHomeDirectory
  return (homeDir </> ".ssh" </> "authorized_keys")

doAction :: String -> [String] -> IO ()
doAction _ [] = helpMenu Nothing
doAction cont (cmdArgs : rest)
  | cmd == "list" = listIt cont
  | cmd == "help" = helpMenu Nothing
  | cmd == "add" = addKey (safeIndex rest 1) (safeIndex rest 0) (safeIndex rest 2)
  | cmd == "enable" || cmd == "disable" = case safeIndex rest 0 of
      Just uuid -> toggleKeyByUUID cont uuid (cmd == "enable")
      Nothing -> putStrLn "You need to give me a UUID!"
  | cmd == "remove" = case safeIndex rest 0 of
      Just uuid -> removeBlock uuid cont
      Nothing -> putStrLn "You need to give me a UUID!"
  | cmd == "uuid" = listUuid cont
  | cmd == "cmd" = listCmd
  | otherwise = helpMenu $ Just cmd
 where
  cmd = map toLower cmdArgs

listCmd :: IO ()
listCmd = do
  putStrLn "help"
  putStrLn "add"
  putStrLn "disable"
  putStrLn "enable"
  putStrLn "remove"
  putStrLn "list"

listIt :: String -> IO ()
listIt contents = do
  let l = lines contents
      sak = getSakBlock l
      keys = mapMaybe parseSakBlock sak
      lose_keys = getLooseKeys l
  mapM_ print keys
  mapM_ print lose_keys

listUuid :: String -> IO ()
listUuid cont = do
  mapM_ (putStrLn  . uuid) keys
 where
  l = lines cont
  sak = getSakBlock l
  keys = mapMaybe parseSakBlock sak

helpMenu :: Maybe String -> IO ()
helpMenu x = do
  case x of
    Just cmd -> putStrLn ("Can't find the command `" ++ cmd ++ "`")
    Nothing -> return ()
  putStrLn "Help menu:\nsak help -> This menu\nsak list -> lists keys\nsak add <name> <key> <?desc> -> Adds key, desc is optional\nsak disable <uuid> -> Disables a key\nsak enable <uuid> -> Enables a key.\nsak remove <uuid> -> Removes a key"

addKey :: Maybe String -> Maybe String -> Maybe String -> IO ()
addKey Nothing _ _ = putStrLn "You didn't give me a key!"
addKey _ Nothing _ = putStrLn "You didn't give me a name!"
addKey (Just key) (Just name) desc = do
  uuid <- UUIDv4.nextRandom
  filePath <- getFile
  let rawKey =
        SAKKey
          { key = key
          , isActive = True
          , desc = desc
          , name = name
          , uuid = show uuid
          }
      keyTxt = show rawKey
  safeAppend filePath keyTxt

toggleKeyByUUID :: String -> String -> Bool -> IO ()
toggleKeyByUUID cont uuid en = do
  filePath <- getFile
  safeWrite filePath newContents
 where
  l = lines cont
  blocks = getSakBlock l
  newBlocks = map (modifyBlock uuid en) blocks
  loseLines = filter (\l -> not (any (l `elem`) blocks)) l
  newContents = unlines $ concat newBlocks ++ loseLines

removeBlock :: String -> String -> IO ()
removeBlock uuid cont = do
  path <- getFile
  let new = go ls
  safeWrite path (unlines new)
 where
  ls = lines cont
  go [] = []
  go (x : xs)
    | checkSAKStart x =
        if checkUUID uuid blockF
          then go (drop 1 rest)
          else blockF ++ go (drop 1 rest)
    | otherwise = x : go xs
   where
    (block, rest) = break checkSAKEnd xs
    blockF = x : block ++ take 1 rest

main :: IO ()
main = do
  args <- getArgs
  filePath <- getFile
  contents <- readFile filePath `catch` handler
  doAction contents args
 where
  handler :: IOException -> IO String
  handler _ = do
    putStrLn "Cant open the file!"
    return ""
