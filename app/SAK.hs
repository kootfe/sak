module SAK where

import Data.Char (isSpace)
import Data.List (isPrefixOf, stripPrefix)
import Data.Maybe (fromMaybe, listToMaybe, mapMaybe)
import KUtils

data SAKKey = SAKKey
  { key :: String
  , isActive :: Bool
  , desc :: Maybe String
  , name :: String
  , uuid :: String
  }

instance Show SAKKey where
  show k =
    -- Why LSP why?
    "# -SAK INFO-\n"
      ++ "# name: "
      ++ name k
      ++ "\n"
      ++ "# uuid: "
      ++ uuid k
      ++ "\n"
      ++ "# desc: "
      ++ des
      ++ "\n"
      ++ ap
      ++ key k
      ++ "\n"
      ++ "# -SAK INFO END-\n"
   where
    ap = if isActive k then "" else "# "
    des = fromMaybe "No desc" (desc k)

getSakBlock :: [String] -> [[String]]
getSakBlock [] = []
getSakBlock (x : xs)
  | checkSAKStart x = (x : block ++ take 1 rest) : getSakBlock (drop 1 rest)
  | otherwise = getSakBlock xs
 where
  (block, rest) = break checkSAKEnd xs

parseFiled :: String -> String -> Maybe String
parseFiled fl ln = fmap trim (stripPrefix prefix ln)
 where
  prefix = "# " ++ fl ++ ": "

parseKeyLine :: String -> Maybe (String, Bool)
parseKeyLine ln
  | checkKeyLine ln = Just (trim ln, True)
  | checkHash ln, checkKeyLine rest = Just (rest, False)
  | otherwise = Nothing
 where
  rest = trim (drop 1 ln)

parseSakBlock :: [String] -> Maybe SAKKey
parseSakBlock [] = Nothing
parseSakBlock (x : xs)
  | not (checkSAKStart x) = Nothing
  | otherwise = case (mName, mDesc, mUuid, mKey) of
      (Just n, _, Just u, Just (k, active)) ->
        Just
          SAKKey
            { key = k
            , isActive = active
            , name = n
            , desc = mDesc
            , uuid = u
            }
      _ -> Nothing
 where
  bl = xs
  mName = listToMaybe $ mapMaybe (parseFiled "name") bl
  mDesc = listToMaybe $ mapMaybe (parseFiled "desc") bl
  mUuid = listToMaybe $ mapMaybe (parseFiled "uuid") bl
  mKey = listToMaybe $ mapMaybe parseKeyLine bl

getLooseKeys :: [String] -> [String]
getLooseKeys [] = []
getLooseKeys (x : xs)
  | checkSAKStart x = getLooseKeys (drop 1 rest)
  | checkKeyLine (trim x), not (checkHash (trim x)) = trim x : getLooseKeys xs
  | otherwise = getLooseKeys xs
 where
  (_, rest) = break checkSAKEnd xs

checkUUID :: String -> [String] -> Bool
checkUUID uuid blk = any(\ln -> "# uuid: " ++ uuid == trim ln) blk

modifyBlock :: String -> Bool -> [String] -> [String]
modifyBlock uuid en blk =
  if checkUUID uuid blk 
    then map modifyLn blk
    else blk
  where
    modifyLn ln
      | checkKeyLine (trim ln) = if en then removeHash ln else addHash ln
      | checkKeyLine (trim (removeHash (trim ln))) = if en then removeHash ln else addHash ln
      | otherwise = ln
