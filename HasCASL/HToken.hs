
{- HetCATS/HasCASL/HToken.hs
   $Id$
   Authors: Christian Maeder
   Year:    2002
   
   parser for HasCASL IDs
   adapted from HetCATS/CASL/Token.hs, v 1.9
-}

module HToken where

import Id
import Keywords
import Lexer
import Token(casl_reserved_ops, casl_reserved_words
	    , start, mixId)
import Parsec

-- ----------------------------------------------
-- further hascasl keyword
-- ----------------------------------------------

assignS, minusS, plusS, pFun, contFun, pContFun, lamS, asP :: String
assignS = ":="
minusS = "-"
plusS = "+"
pFun = funS ++ quMark
contFun = minusS ++ funS
pContFun = minusS ++ pFun
lamS = "\\"
asP = "@"

classS, programS, instanceS, caseS, ofS, letS, derivingS :: String
classS = "class"
programS = "program"
instanceS = "instance"
caseS = "case"
ofS = "of"
letS = "let"
derivingS = "deriving"

-- ----------------------------------------------
-- hascasl keyword handling
-- ----------------------------------------------
hascasl_reserved_ops, hascasl_type_ops :: [String]
hascasl_reserved_ops = [dotS++exMark, cDot++exMark, asP, assignS, lamS] 
		       ++ casl_reserved_ops

hascasl_type_ops = [funS, pFun, contFun, pContFun, prodS, timesS, quMark] 

hascasl_reserved_words :: [String]
hascasl_reserved_words = 
    [classS, instanceS, programS, caseS, ofS, letS, derivingS] 
			 ++ casl_reserved_words

scanWords, scanSigns :: GenParser Char st String
scanWords = reserved hascasl_reserved_words scanAnyWords 
scanSigns = reserved hascasl_reserved_ops scanAnySigns 
-- ----------------------------------------------
-- non-compound mixfix ids (variables)
-- ----------------------------------------------
hcKeys :: ([String], [String])
hcKeys = (hascasl_reserved_ops, hascasl_reserved_words)

var :: GenParser Char st Id
var = fmap (\l -> Id l [] []) (start hcKeys)

-- ----------------------------------------------
-- bracketed lists
-- ----------------------------------------------
bracketParser :: GenParser Char st a -> GenParser Char st Token 
	 -> GenParser Char st Token -> GenParser Char st Token
	 -> ([a] -> [Pos] -> b) -> GenParser Char st b

bracketParser parser op cl sep k = 
    do o <- op
       (ts, ps) <- option ([], []) 
		   (parser `separatedBy` sep)
       c <- cl
       return (k ts (toPos o ps c))

brackets :: GenParser Char st a -> ([a] -> [Pos] -> b) -> GenParser Char st b
brackets parser k = bracketParser parser oBracketT cBracketT commaT k

-- ----------------------------------------------
-- mixIds
-- ----------------------------------------------

hcMixId, uninstOpId, typeId :: GenParser Char st Id
hcMixId = mixId hcKeys hcKeys
uninstOpId = hcMixId
typeId = hcMixId

-- ----------------------------------------------
-- TYPE-VAR Ids
-- ----------------------------------------------

-- no compound ids (just a word) 
typeVar :: GenParser Char st Token
typeVar = pToken scanWords

-- simple id with compound list
classId :: GenParser Char st Id
classId = 
    do s <- typeVar
       (c, p) <- option ([], []) $ brackets hcMixId (,) 
       return (Id [s] c p)
