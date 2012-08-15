{- |
Module      :  $Header$
Description :  Parser of the Knowledge Interchange Format
Copyright   :  (c) Karl Luc, DFKI Bremen 2010, Soeren Schulze 2012
License     :  GPLv2 or higher

Maintainer  :  s.schulze@uni-bremen.de
Stability   :  experimental
Portability :  portable
-}

module CommonLogic.Lexer_KIF where

import Common.Id as Id
import qualified Common.Lexer as Lexer
import Common.Parsec

import Text.ParserCombinators.Parsec as Parsec
import Data.Char (isSpace, isUpper, isLower, isDigit, isAscii)
import Control.Monad (liftM)

-- literally from Lexer_CLIF.hs -- abstract?
skip :: CharParser st String
skip = liftM concat $ many white

pToken :: CharParser st String -> CharParser st Token
pToken p = Lexer.pToken p << skip

oParenT :: CharParser st Token
oParenT = pToken $ string "("

cParenT :: CharParser st Token
cParenT = pToken $ string ")"

parens :: CharParser st a -> CharParser st a
parens p = oParenT >> p << cParenT

key :: String -> CharParser st Id.Token
key s = pToken $ try $ string s << notFollowedBy (satisfy kifWordChar)

word :: CharParser st String
word = satisfy kifInitialChar <:> many (satisfy kifWordChar)

quotedChar :: CharParser st Char
quotedChar = do
  satisfy kifChar <|> satisfy kifUnofficial
  <|> (char '\\' >> char '\"')

quotedString :: CharParser st String
quotedString = do
  q1 <- char '\"'
  s  <- many quotedChar
  q2 <- char '\"'
  return $ q1:s++[q2]

variable :: CharParser st String
variable = oneOf "?@" <:> word

sign :: Num a => CharParser st a
sign = liftM (maybe 1 (const (-1))) (optionMaybe $ char '-')

number :: CharParser st String
number = do sgn <- sign
            prePoint <- many1 (satisfy kifDigit)
            postPoint <- optionMaybe $ char '.' >> many1 (satisfy kifDigit)
            ex <- optionMaybe $ liftM fromIntegral expo
            return $ show $ (sgn::Double) * case (postPoint, ex) of
              (Just pp, Just e)  -> (read $ prePoint ++ '.' : pp) * 10**e
              (Just pp, Nothing) -> (read $ prePoint ++ '.' : pp)
              (Nothing, Just e)  -> (read prePoint) * 10**e
              (Nothing, Nothing) -> read prePoint

expo :: CharParser st Int
expo = do char 'e'
          sgn <- sign
          e <- many1 (satisfy kifDigit)
          return $ sgn*(read e)

kifUpper :: Char -> Bool
kifUpper ch = Data.Char.isUpper ch && Data.Char.isAscii ch

kifLower :: Char -> Bool
kifLower ch = Data.Char.isLower ch && Data.Char.isAscii ch

kifSpecial :: Char -> Bool
kifSpecial ch = ch `elem` "!$%&*+-,./<=>?@_~"

-- These characters are used in documentation texts in SUMO.
kifUnofficial :: Char -> Bool
kifUnofficial ch = ch `elem` ",()#':{}`;^"

kifWordChar :: Char -> Bool
kifWordChar ch = kifUpper ch || kifLower ch || kifSpecial ch || kifDigit ch
                 || ch == '-'

kifChar :: Char -> Bool
kifChar ch = kifUpper ch || kifLower ch || kifSpecial ch || kifDigit ch
             || isSpace ch

kifInitialChar :: Char -> Bool
kifInitialChar ch = kifUpper ch || kifLower ch

kifDigit :: Char -> Bool
kifDigit = isDigit

commentLine :: CharParser st String
commentLine = char ';' <:> many (noneOf "\n")

white :: CharParser st String
white =
    many1 (satisfy isSpace)
  <|>
    commentLine
