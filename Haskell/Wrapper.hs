{- HetCATS/Haskell/Wrapper.hs
   $Id$
   Authors: C. Maeder
   Year:    2003

   extract Haskell code from String
   stops at unbalanced "}" 

   "then" may be recognized if it is not preceded by "if"
   but that's not worth the trouble, because ...

   "and" is used by Haskell, 
   "with", "hide", "reveal", "within", "end"
   may be userdefined in Haskell
-}

module Haskell.Wrapper where

import Common.Lib.Parsec
import Common.Lexer
import Common.Token

 
hStuff, stuff :: GenParser Char st String
hStuff = flat $ many stuff 

stuff = lineComment <|> nestComment <|> stringLit <|> charLit
	<|> balanced "{}" 
	<|> balanced "()" 
	<|> balanced "[]" 
        <|> reserved casl_structured_reserved_words scanAnyWords
	<|> single (noneOf ("])}"++['A'..'Z'] ++ ['a'..'z']))

balanced :: String -> GenParser Char st String
balanced [o, c] = char o <:> hStuff <++> string [c]
balanced _ = error "balanced"

nestComment :: GenParser Char st String
nestComment = try (string "{-") <++> 
		 flat (many (single (noneOf "-{") 
			     <|> try (string "-" << notFollowedBy (char '}'))
		             <|> nestComment 
			     <|> string "{" ))
		 <++> string "-}"

lineComment, stringLit, charLit :: GenParser Char st String
lineComment = try (string "--") <++> many (noneOf "\n\r")
	      <++> many (oneOf "\n\r")  

stringLit = char '\"' <:> flat (many (single (noneOf "\\\"")
				 <|> char '\\' <:> single anyChar))
	    <++> string "\""

charLit = try (string "'''") <|>
	  char '\'' <:> flat (many (single (noneOf "\\\'")
				 <|> char '\\' <:> single anyChar))
          <++> string "\'"
 

