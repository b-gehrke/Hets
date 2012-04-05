{-# LANGUAGE CPP, DeriveDataTypeable #-}
{- |
Module      :  $Header$
Copyright   :  (c) DFKI GmbH 2012
License     :  GPLv2 or higher, see LICENSE.txt

Maintainer  :  Eugen Kuksa <eugenk@informatik.uni-bremen.de>
Stability   :  provisional
Portability :  portable

This module defines functions for handling IRIs.  It is substantially the
same as the Network.URI module by Graham Klyne, but is extended to IRI
support [2] and even Manchester-Syntax-IRI [3], [4] and CURIE [5].

Four methods are provided for parsing different
kinds of IRI string (as noted in [1], [2]):
'parseIRI',
'parseIRIReference',
'parseRelativeReference' and
'parseAbsoluteIRI'.

An additional method is provided for parsing an abbreviated IRI according to
[3], [4]: 'parseIRIManchester' and according to [5]: 'parseIRICurie'

Further, four methods are provided for classifying different
kinds of IRI string (as noted in  [1], [2]):
'isIRI',
'isIRIReference',
'isRelativeReference' and
'isAbsoluteIRI'.

Additionally, classification of full, abbreviated and simple IRI is provided
by 'isIRIManchester', isIRICurie.

The abbreviated syntaxs [3], [4], [5] provide three different kinds of IRI: full,
abbreviated, simple, expandedAbbreviated and expandedSimple. An existing element
of type IRI can be classified in one of those kinds with 'iriType'.

Most of the code has been copied from the Network.URI implementation,
but it is extended to IRI, Manchester-syntax and CURIE.

References

(1) <http://www.ietf.org/rfc/rfc3986.txt>

(2) <http://www.ietf.org/rfc/rfc3987.txt>

(3) <http://www.w3.org/TR/2009/NOTE-owl2-manchester-syntax-20091027/>

(4) <http://www.w3.org/TR/2008/REC-rdf-sparql-query-20080115/>

(5) <http://www.w3.org/TR/curie/#s_syntax>

-}

module Common.IRI
    (
    -- * The IRI type
      IRI (..)
    , IRIAuth (..)
    , IRIType (..)
    , nullIRI
    , iriType

    -- * Conversion
    , simpleIdToIRI

    -- * Parsing
    , parseIRI
    , parseIRIReference
    , parseRelativeReference
    , parseAbsoluteIRI
    , parseCurie
    , parseIRICurie
    , parseIRIManchester

    -- * Test for strings containing various kinds of IRI
    , isIRI
    , isIRIReference
    , isRelativeReference
    , isAbsoluteIRI
    , isCurie
    , isIRICurie
    , isIRIManchester
    , isIPv6address
    , isIPv4address

    -- * Relative IRIs
    , relativeTo
    , nonStrictRelativeTo
    , relativeFrom

    -- * Operations on IRI strings

    {- | Support for putting strings into IRI-friendly
    escaped format and getting them back again. -}
    , iriToString
    , iriToStringUnsecure
    , iriToStringShort
    , iriToStringShortUnsecure
    , isReserved, isUnreserved
    , isAllowedInIRI, isUnescapedInIRI
    , escapeIRIChar
    , escapeIRIString
    , unEscapeString

    -- * Parser combinators, special additions to export list
    , iri
    , iriReference
    , irelativeRef
    , absoluteIRI
    , iriCurie
    , iriReferenceCurie
    , curie
    , iriManchester

    -- * IRI Normalization functions
    , expandCurie
    , normalizeCase
    , normalizeEscape
    , normalizePathSegments
    ) where

import Text.ParserCombinators.Parsec
    ( GenParser, ParseError
    , parse, (<|>), (<?>), try
    , option, many, many1, count, notFollowedBy
    , char, satisfy, oneOf, string, digit, eof
    , unexpected
    )

import Control.Monad (MonadPlus (..))
import Data.Char (ord, chr, isHexDigit, toLower, toUpper, digitToInt)
import Numeric (showIntAtBase)

import Data.Typeable (Typeable)

import Data.Map (Map, findWithDefault)

import Common.Id
import Common.Lexer
import Common.Parsec
import ATerm.Lib

-- * The IRI datatype

{- | Represents a general universal resource identifier using
its component parts.

For example, for the (full) IRI

>   foo://anonymous@www.haskell.org:42/ghc?query#frag

or the abbreviated IRI

>   prefix:abbrevPath

or the simple IRI

>  abbrevPath

the components are: -}
data IRI = IRI
    { iriScheme :: String         -- ^ @foo:@
    , iriAuthority :: Maybe IRIAuth -- ^ @\/\/anonymous\@www.haskell.org:42@
    , iriPath :: String           -- ^ local part @\/ghc@
    , iriQuery :: String          -- ^ @?query@
    , iriFragment :: String       -- ^ @#frag@
    , prefixName :: String        -- ^ @prefix@
    , abbrevPath :: String        -- ^ @abbrevPath@
    , iriPos :: Range             -- ^ position
    } deriving (Typeable)

-- | Type for authority value within a IRI
data IRIAuth = IRIAuth
    { iriUserInfo :: String       -- ^ @anonymous\@@
    , iriRegName :: String        -- ^ @www.haskell.org@
    , iriPort :: String           -- ^ @:42@
    } deriving (Eq, Typeable, Ord, Show)

data IRIType = Full | ExpandedAbbrev | ExpandedSimple | Abbreviated | Simple
  deriving (Eq, Show, Typeable, Ord)

-- | Blank IRI
nullIRI :: IRI
nullIRI = IRI
    { iriScheme = ""
    , iriAuthority = Nothing
    , iriPath = ""
    , iriQuery = ""
    , iriFragment = ""
    , prefixName = ""
    , abbrevPath = ""
    , iriPos = nullRange
    }

-- | Returns Type of an IRI
iriType :: IRI -> IRIType
iriType i =
  if (not . null) $ iriPath i then (
      if (null $ abbrevPath i) && (null $ prefixName i) then Full else
      if null $ prefixName i then ExpandedSimple else ExpandedAbbrev
  ) else if null $ prefixName i then Simple else Abbreviated

{- IRI as instance of Show.  Note that for secirity reasons, the default
behaviour is to suppress any iuserinfo field (see RFC3986, section 7.5).
This can be overridden by using iriToString directly with first
argument @id@ (noting that this returns a ShowS value rather than a string).

[[[Another design would be to embed the iuserinfo mapping function in
the IRIAuth value, with the default value suppressing iuserinfo formatting,
but providing a function to return a new IRI value with iuserinfo
data exposed by show.]]]
-}
instance Show IRI where
    showsPrec _ i = iriToString defaultUserInfoMap i

-- equal iff expansion is equal or abbreviation is equal
instance Eq IRI where
    (==) i j = compare i j == EQ

-- compares full/expanded IRI (if expanded) or abbreviated part if not expanded
instance Ord IRI where
    compare i j = case (iriType i, iriType j) of
        (Simple, Simple) -> abbrevPath i `compare` abbrevPath j
        (Abbreviated, Abbreviated) ->
            let pnC = prefixName i `compare` prefixName j
                apC = abbrevPath i `compare` abbrevPath j
            in if pnC /= EQ then pnC else apC
        _ ->
            let scC = iriScheme i    `compare` iriScheme j
                auC = iriAuthority i `compare` iriAuthority j
                paC = iriPath i      `compare` iriPath j
                quC = iriQuery i     `compare` iriQuery j
                frC = iriFragment i  `compare` iriFragment j
            in if scC /= EQ then scC else
               if auC /= EQ then auC else
               if paC /= EQ then paC else
               if quC /= EQ then quC else frC

-- |converts IRI to String of expanded form, also showing Auth info
iriToStringUnsecure :: IRI -> String
iriToStringUnsecure i = (iriToString id i) ""

-- |converts IRI to String of abbreviated form, also showing Auth info
iriToStringShortUnsecure :: IRI -> String
iriToStringShortUnsecure i = (iriToStringShort id i) ""

defaultUserInfoMap :: String -> String
defaultUserInfoMap uinf = user ++ newpass
    where
        (user, pass) = break (== ':') uinf
        newpass = if null pass || (pass == "@")
                                   || (pass == ":@")
                        then pass
                        else ":...@"

instance GetRange IRI where
    getRange = iriPos

-- | Converts a Simple_ID to an IRI
simpleIdToIRI :: SIMPLE_ID -> IRI
simpleIdToIRI sid = nullIRI { abbrevPath = tokStr sid
                            , iriPos = tokPos sid
                            }

-- * Parse a IRI

{- | Turn a string containing an RFC3987 IRI into an 'IRI'.
Returns 'Nothing' if the string is not a valid IRI;
(an absolute IRI with optional fragment identifier). -}
parseIRI :: String -> Maybe IRI
parseIRI = parseIRIAny iri

{- | Parse a IRI reference to an 'IRI' value.
Returns 'Nothing' if the string is not a valid IRI reference.
(an absolute or relative IRI with optional fragment identifier). -}
parseIRIReference :: String -> Maybe IRI
parseIRIReference = parseIRIAny iriReference

{- | Parse a relative IRI to an 'IRI' value.
Returns 'Nothing' if the string is not a valid relative IRI.
(a relative IRI with optional fragment identifier). -}
parseRelativeReference :: String -> Maybe IRI
parseRelativeReference = parseIRIAny irelativeRef

{- | Parse an absolute IRI to an 'IRI' value.
Returns 'Nothing' if the string is not a valid absolute IRI.
(an absolute IRI without a fragment identifier). -}
parseAbsoluteIRI :: String -> Maybe IRI
parseAbsoluteIRI = parseIRIAny absoluteIRI

-- | Turn a string containing a CURIE into an 'IRI'
parseCurie :: String -> Maybe IRI
parseCurie = parseIRIAny curie

{- | Turn a string containing an IRI or a CURIE into an 'IRI'.
Returns 'Nothing' if the string is not a valid IRI;
(an absolute IRI enclosed in '<' and '>' with optional fragment identifier
or a CURIE). -}
parseIRICurie :: String -> Maybe IRI
parseIRICurie = parseIRIAny iriCurie

{- | Turn a string containing an IRI (by Manchester-syntax) into an 'IRI'.
Returns 'Nothing' if the string is not a valid IRI;
(an absolute IRI enclosed in '<' and '>' with optional fragment identifier,
an abbreviated IRI or a simple IRI). -}
parseIRIManchester :: String -> Maybe IRI
parseIRIManchester = parseIRIAny iriManchester

{- |Test if string contains a valid IRI
(an absolute IRI with optional fragment identifier). -}
isIRI :: String -> Bool
isIRI = isValidParse iri

{- | Test if string contains a valid IRI reference
(an absolute or relative IRI with optional fragment identifier). -}
isIRIReference :: String -> Bool
isIRIReference = isValidParse iriReference

{- |Test if string contains a valid relative IRI
(a relative IRI with optional fragment identifier). -}
isRelativeReference :: String -> Bool
isRelativeReference = isValidParse irelativeRef

{- | Test if string contains a valid absolute IRI
(an absolute IRI without a fragment identifier). -}
isAbsoluteIRI :: String -> Bool
isAbsoluteIRI = isValidParse absoluteIRI

{- | Test if string contains a valid IRI or CURIE
(an absolute IRI enclosed in '<' and '>' with optional fragment identifier
or a CURIE). -}
isIRICurie :: String -> Bool
isIRICurie = isValidParse iriCurie

-- | Test if string contains a valid CURIE
isCurie :: String -> Bool
isCurie = isValidParse curie

{- | Test if string contains a valid IRI by Manchester-syntax
(an absolute IRI enclosed in '<' and '>' with optional fragment identifier,
an abbreviated IRI or a simple IRI). -}
isIRIManchester :: String -> Bool
isIRIManchester = isValidParse iriManchester

-- | Test if string contains a valid IPv6 address
isIPv6address :: String -> Bool
isIPv6address = isValidParse ipv6address

-- | Test if string contains a valid IPv4 address
isIPv4address :: String -> Bool
isIPv4address = isValidParse ipv4address

-- Helper function for turning a string into a IRI
parseIRIAny :: IRIParserDirect IRI -> String -> Maybe IRI
parseIRIAny parser iristr = case parseAll parser "" iristr of
        Left _ -> Nothing
        Right u -> Just u

-- Helper function to test a string match to a parser
isValidParse :: IRIParserDirect a -> String -> Bool
isValidParse parser iristr = case parseAll parser "" iristr of
        Left _ -> False
        Right _ -> True

parseAll :: IRIParserDirect a -> String -> String -> Either ParseError a
parseAll parser = parse (parser << eof)

-- * IRI parser body based on Parsec elements and combinators

-- Parser parser type. Currently:
type IRIParserDirect a = GenParser Char () a

type IRIParser st a = GenParser Char st a

-- RFC3986, section 2.1

-- | Parse and return a 'pct-encoded' sequence
escaped :: IRIParser st String
escaped =
    do { char '%'
        ; h1 <- hexDigitChar
        ; h2 <- hexDigitChar
        ; return $ ['%', h1, h2]
        }

-- RFC3986, section 2.2

{- | Returns 'True' if the character is a \"reserved\" character in a
IRI.  To include a literal instance of one of these characters in a
component of a IRI, it must be escaped. -}
isReserved :: Char -> Bool
isReserved c = isGenDelims c || isSubDelims c

isGenDelims :: Char -> Bool
isGenDelims c = c `elem` ":/?#[]@"

isSubDelims :: Char -> Bool
isSubDelims c = c `elem` "!$&'()*+,;="

subDelims :: IRIParser st String
subDelims = do { c <- satisfy isSubDelims ; return [c] }

-- RFC3986, section 2.3

{- |Returns 'True' if the character is an \"unreserved\" character in
a IRI.  These characters do not need to be escaped in a IRI.  The
only characters allowed in a IRI are either \"reserved\",
\"unreserved\", or an escape sequence (@%@ followed by two hex digits). -}
isUnreserved :: Char -> Bool
isUnreserved c = isAlphaNumChar c || (c `elem` "-_.~") || (isUcsChar c)

iunreservedChar :: IRIParser st String
iunreservedChar = do { c <- satisfy isUnreserved ; return [c] }

iriWithPos :: IRIParser st IRI -> IRIParser st IRI
iriWithPos parser = do
  p <- getPos
  i <- parser
  q <- getPos
  return $ i {iriPos = appRange (Range [p, q]) $ iriPos i}


-- BEGIN CURIE

-- | Parses an absolute IRI enclosed in '<', '>' or a CURIE
iriCurie :: IRIParser st IRI
iriCurie = do
    char '<'
    i <- iri
    char '>'
    skipSmart
    return i
  <|> curie

{- | Parses an absolute or relative IRI enclosed in '<', '>' or a CURIE
see @iriReference@ -}
iriReferenceCurie :: IRIParser st IRI
iriReferenceCurie = do
    char '<'
    i <- iri <|> irelativeRef
    char '>'
    skipSmart
    return i
  <|> curie

-- | Parses a CURIE <http://www.w3.org/TR/rdfa-core/#s_curies>
curie :: IRIParser st IRI
curie = iriWithPos $ do
    c <- string ":"
    i <- reference
    skipSmart
    return $ i { prefixName = c }
  <|> do
    pn <- try (do
        n <- ncname
        c <- string ":"
        return $ n ++ c
      )
    i <- reference
    skipSmart
    return $ i { prefixName = pn }
  <|> do
    r <- reference
    skipSmart
    return r

reference :: IRIParser st IRI
reference = iriWithPos $ do
  (_, up) <- ihierPartNoAuth
  uq <- option "" ( do { char '?' ; uiquery } )
  uf <- option "" ( do { char '#' ; uifragment } )
  return $ IRI
          { iriScheme = ""
          , iriAuthority = Nothing
          , iriPath = ""
          , iriQuery = uq
          , iriFragment = uf
          , prefixName = ""
          , abbrevPath = up
          , iriPos = nullRange
          }

-- http://www.w3.org/TR/2009/REC-xml-names-20091208/#NT-NCName
ncname :: GenParser Char st String
ncname = do
  c <- nameStartChar
  s <- many nameChar
  return $ c : s

nameStartChar :: GenParser Char st Char
nameStartChar = satisfy nameStartCharP

nameChar :: GenParser Char st Char
nameChar = satisfy nameCharP

{- NOTE: Usually ':' is allowed. Here, only ncname uses nameStartChar, however.
Thus we disallow ':' -}
nameStartCharP :: Char -> Bool
nameStartCharP c =
  let n = ord c in
  (c == '_') ||       -- usually: (c `elem` ":_") ||
  isAlphaChar c ||
  (0x00C0 <= n && n <= 0x00D6) ||
  (0x00D8 <= n && n <= 0x00F6) ||
  (0x00F8 <= n && n <= 0x02FF) ||
  (0x0370 <= n && n <= 0x037D) ||
  (0x037F <= n && n <= 0x1FFF) ||
  (0x200C <= n && n <= 0x200D) ||
  (0x2070 <= n && n <= 0x218F) ||
  (0x2C00 <= n && n <= 0x2FEF) ||
  (0x3001 <= n && n <= 0xD7FF) ||
  (0xF900 <= n && n <= 0xFDCF) ||
  (0xFDF0 <= n && n <= 0xFFFD) ||
  (0x10000 <= n && n <= 0xEFFFF)

nameCharP :: Char -> Bool
nameCharP c =
  let n = ord c in
  nameStartCharP c ||
  isDigitChar c ||
  c `elem` "-." ||
  n == 0xB7 ||
  (0x0300 <= n && n <= 0x036F) ||
  (0x203F <= n && n <= 0x2040)

-- END CURIE

-- BEGIN SPARQL

{- http://www.w3.org/TR/2008/REC-rdf-sparql-query-20080115/
Section 4.1 -}

pn_chars_baseP :: Char -> Bool
pn_chars_baseP c =
  let n = ord c in
  isAlphaChar c ||
  (0x00C0 <= n && n <= 0x00D6) ||
  (0x00D8 <= n && n <= 0x00F6) ||
  (0x00F8 <= n && n <= 0x02FF) ||
  (0x0370 <= n && n <= 0x037D) ||
  (0x037F <= n && n <= 0x1FFF) ||
  (0x200C <= n && n <= 0x200D) ||
  (0x2070 <= n && n <= 0x218F) ||
  (0x2C00 <= n && n <= 0x2FEF) ||
  (0x00D8 <= n && n <= 0x00F6) ||
  (0x3001 <= n && n <= 0xD7FF) ||
  (0xF900 <= n && n <= 0xFDCF) ||
  (0xFDF0 <= n && n <= 0xFFFD) ||
  (0x10000 <= n && n <= 0xEFFFF)

pn_chars_base :: GenParser Char st Char
pn_chars_base = satisfy pn_chars_baseP

pn_chars_u :: GenParser Char st Char
pn_chars_u = satisfy pn_chars_uP

pn_chars :: GenParser Char st Char
pn_chars = satisfy pn_charsP

pn_chars_uP :: Char -> Bool
pn_chars_uP c = (pn_chars_baseP c) || (c == '_')

pn_charsP :: Char -> Bool
pn_charsP c =
  let n = ord c in
  c == '-' ||
  pn_chars_uP c ||
  isDigitChar c ||
  (n == 0x00B7) ||
  (0x0300 <= n && n <= 0x036F) ||
  (0x203F <= n && n <= 0x2040)

{- http://www.w3.org/TR/2009/NOTE-owl2-manchester-syntax-20091027/
section 2.1 -}

{- fullIRI := an IRI as defined in [RFC 3987], enclosed in a pair of < (U+3C)
 and > (U+3E) characters
prefixName := a finite sequence of characters matching the PNAME_NS production
 of [SPARQL] and not matching any of the keyword terminals of the syntax
abbreviatedIRI := a finite sequence of characters matching the PNAME_LN#
 production of [SPARQL]
simpleIRI := a finite sequence of characters matching the PN_LOCAL production
 of [SPARQL] and not matching any of the keyword terminals of the syntax
IRI := fullIRI | abbreviatedIRI | simpleIRI -}

iriManchester :: IRIParser st IRI
iriManchester = iriWithPos $ do
    char '<'
    i <- iri <|> irelativeRef
    char '>'
    return i
  <|> do
    (PName_Ln prefix loc) <- try pname_ln
    return $ IRI
            { iriScheme = ""
            , iriAuthority = Nothing
            , iriPath = ""
            , iriQuery = ""
            , iriFragment = ""
            , prefixName = prefix
            , abbrevPath = loc
            , iriPos = nullRange
            }
  <|> do
    loc <- pn_local
    return $ IRI
            { iriScheme = ""
            , iriAuthority = Nothing
            , iriPath = ""
            , iriQuery = ""
            , iriFragment = ""
            , prefixName = ""
            , abbrevPath = loc
            , iriPos = nullRange
            }

data PNAME_LN = PName_Ln PNAME_NS PN_LOCAL deriving (Show, Eq, Ord)
type PNAME_NS = String
type PN_PREFIX = String
type PN_LOCAL = String

pname_ln :: GenParser Char st PNAME_LN
pname_ln = do
  ns <- pname_ns
  loc <- pn_local
  return $ PName_Ln ns loc

pname_ns :: GenParser Char st PNAME_NS
pname_ns = do
    char ':'
    return ":"
  <|> do
    prefix <- pn_prefix
    char ':'
    return $ prefix ++ ":"

pn_prefix :: GenParser Char st PN_PREFIX
pn_prefix = do
    c1 <- pn_chars_base
    t <- (
      do
          s1 <- many (pn_chars <|> char '.')
          if null s1 then return Nothing else case last s1 of
               '.' -> fail "Last character in prefix must not be '.'"
               _ -> return $ Just s1
        <|> return Nothing
      )
    case t of
      Just str -> return $ c1 : str
      Nothing -> return [c1]

pn_local :: GenParser Char st PN_LOCAL
pn_local = do
    c1 <- (pn_chars_u <|> digit)
    t <- (
      do
          s1 <- many (pn_chars <|> char '.')
          if null s1 then return Nothing else case last s1 of
               '.' -> fail "Last character in prefix must not be '.'"
               _ -> return $ Just s1
        <|> return Nothing
      )
    case t of
      Just str -> return $ c1 : str
      Nothing -> return [c1]

-- END SPARQL


-- RFC3987, section 2.2

-- IRI         = scheme ":" ihier-part [ "?" iquery ] [ "#" ifragment ]

{- ihier-part   = "//" iauthority ipath-abempty
/ ipath-absolute
/ ipath-rootless
/ ipath-empty -}

iri :: IRIParser st IRI
iri = iriWithPos $
    do { us <- try uscheme
        ; (ua, up) <- ihierPart
        ; uq <- option "" ( do { char '?' ; uiquery } )
        ; uf <- option "" ( do { char '#' ; uifragment } )
        ; return $ IRI
            { iriScheme = us
            , iriAuthority = ua
            , iriPath = up
            , iriQuery = uq
            , iriFragment = uf
            , prefixName = ""
            , abbrevPath = ""
            , iriPos = nullRange
            }
        }

ihierPart :: IRIParser st ((Maybe IRIAuth), String)
ihierPart =
        do { try (string "//")
            ; ua <- uiauthority
            ; up <- ipathAbEmpty
            ; return (ua, up)
            }
    <|> ihierPartNoAuth

ihierPartNoAuth :: IRIParser st ((Maybe IRIAuth), String)
ihierPartNoAuth =
        do { up <- ipathAbs
            ; return (Nothing, up)
            }
    <|> do { up <- ipathRootLess
            ; return (Nothing, up)
            }
    <|> do { return (Nothing, "")
            }

-- RFC3986, section 3.1

uscheme :: IRIParser st String
uscheme =
    do { s <- oneThenMany alphaChar (satisfy isSchemeChar)
        ; char ':'
        ; return $ s ++ ":"
        }

-- RFC3987, section 2.2

uiauthority :: IRIParser st (Maybe IRIAuth)
uiauthority =
    do { uu <- option "" (try iuserinfo)
        ; uh <- ihost
        ; up <- option "" port
        ; return $ Just $ IRIAuth
            { iriUserInfo = uu
            , iriRegName = uh
            , iriPort = up
            }
        }

-- RFC3987, section 2.2

iuserinfo :: IRIParser st String
iuserinfo =
    do { uu <- many (uchar ";:&=+$,")
        ; char '@'
        ; return (concat uu ++ "@")
        }

-- RFC3987, section 2.2

ihost :: IRIParser st String
ihost = ipLiteral <|> try ipv4address <|> iregName

ipLiteral :: IRIParser st String
ipLiteral =
    do { char '['
        ; ua <- ( ipv6address <|> ipvFuture )
        ; char ']'
        ; return $ "[" ++ ua ++ "]"
        }
    <?> "IP address literal"

ipvFuture :: IRIParser st String
ipvFuture =
    do { char 'v'
        ; h <- hexDigitChar
        ; char '.'
        ; a <- many1 (satisfy isIpvFutureChar)
        ; return $ 'c' : h : '.' : a
        }

isIpvFutureChar :: Char -> Bool
isIpvFutureChar c = isUnreserved c || isSubDelims c || (c == ';')

ipv6address :: IRIParser st String
ipv6address =
        try ( do
                { a2 <- count 6 h4c
                ; a3 <- ls32
                ; return $ concat a2 ++ a3
                } )
    <|> try ( do
                { string "::"
                ; a2 <- count 5 h4c
                ; a3 <- ls32
                ; return $ "::" ++ concat a2 ++ a3
                } )
    <|> try ( do
                { a1 <- opt_n_h4c_h4 0
                ; string "::"
                ; a2 <- count 4 h4c
                ; a3 <- ls32
                ; return $ a1 ++ "::" ++ concat a2 ++ a3
                } )
    <|> try ( do
                { a1 <- opt_n_h4c_h4 1
                ; string "::"
                ; a2 <- count 3 h4c
                ; a3 <- ls32
                ; return $ a1 ++ "::" ++ concat a2 ++ a3
                } )
    <|> try ( do
                { a1 <- opt_n_h4c_h4 2
                ; string "::"
                ; a2 <- count 2 h4c
                ; a3 <- ls32
                ; return $ a1 ++ "::" ++ concat a2 ++ a3
                } )
    <|> try ( do
                { a1 <- opt_n_h4c_h4 3
                ; string "::"
                ; a2 <- h4c
                ; a3 <- ls32
                ; return $ a1 ++ "::" ++ a2 ++ a3
                } )
    <|> try ( do
                { a1 <- opt_n_h4c_h4 4
                ; string "::"
                ; a3 <- ls32
                ; return $ a1 ++ "::" ++ a3
                } )
    <|> try ( do
                { a1 <- opt_n_h4c_h4 5
                ; string "::"
                ; a3 <- h4
                ; return $ a1 ++ "::" ++ a3
                } )
    <|> try ( do
                { a1 <- opt_n_h4c_h4 6
                ; string "::"
                ; return $ a1 ++ "::"
                } )
    <?> "IPv6 address"

opt_n_h4c_h4 :: Int -> IRIParser st String
opt_n_h4c_h4 n = option "" $
    do { a1 <- countMinMax 0 n h4c
        ; a2 <- h4
        ; return $ concat a1 ++ a2
        }

ls32 :: IRIParser st String
ls32 = try ( do
                { a1 <- h4c
                ; a2 <- h4
                ; return (a1 ++ a2)
                } )
    <|> ipv4address

h4c :: IRIParser st String
h4c = try $
    do { a1 <- h4
        ; char ':'
        ; notFollowedBy (char ':')
        ; return $ a1 ++ ":"
        }

h4 :: IRIParser st String
h4 = countMinMax 1 4 hexDigitChar

ipv4address :: IRIParser st String
ipv4address =
    do { a1 <- decOctet ; char '.'
        ; a2 <- decOctet ; char '.'
        ; a3 <- decOctet ; char '.'
        ; a4 <- decOctet
        ; return $ a1 ++ "." ++ a2 ++ "." ++ a3 ++ "." ++ a4
        }

decOctet :: IRIParser st String
decOctet =
    do { a1 <- countMinMax 1 3 digitChar
        ; if (read a1 :: Int) > 255 then
            fail "Decimal octet value too large"
          else
            return a1
        }

iregName :: IRIParser st String
iregName =
    do { ss <- countMinMax 0 255 ( iunreservedChar <|> escaped <|> subDelims )
        ; return $ concat ss
        }
    <?> "Registered name"

-- RFC3986, section 3.2.3

port :: IRIParser st String
port =
    do { char ':'
        ; p <- many digitChar
        ; return (':' : p)
        }


-- RFC3987, section 2.2

{- ipath          = ipath-abempty   ; begins with "/" or is empty
/ ipath-absolute  ; begins with "/" but not "//"
/ ipath-noscheme  ; begins with a non-colon isegment
/ ipath-rootless  ; begins with a isegment
/ ipath-empty     ; zero characters -}

{- ipath-abempty  = *( "/" iisegment )
ipath-absolute = "/" [ iisegment-nz *( "/" iisegment ) ]
ipath-noscheme = iisegment-nz-nc *( "/" iisegment )
ipath-rootless = iisegment-nz *( "/" iisegment )
ipath-empty    = 0<iipchar> -}

{- iisegment       = *iipchar
iisegment-nz    = 1*iipchar
iisegment-nz-nc = 1*( iunreserved / pct-encoded / sub-delims
/ "@" )
; non-zero-length isegment without any colon ":" -}

{- iipchar         = iunreserved / pct-encoded / sub-delims / ":"
/ "@" -}

ipathAbEmpty :: IRIParser st String
ipathAbEmpty =
    do { ss <- many slashIsegment
        ; return $ concat ss
        }

ipathAbs :: IRIParser st String
ipathAbs =
    do { char '/'
        ; ss <- option "" ipathRootLess
        ; return $ '/' : ss
        }

ipathRootLess :: IRIParser st String
ipathRootLess =
    do { s1 <- isegmentNz
        ; ss <- many slashIsegment
        ; return $ concat (s1 : ss)
        }

ipathNoScheme :: IRIParser st String
ipathNoScheme =
    do { s1 <- isegmentNzc
        ; ss <- many slashIsegment
        ; return $ concat (s1 : ss)
        }

slashIsegment :: IRIParser st String
slashIsegment =
    do { char '/'
        ; s <- isegment
        ; return ('/' : s)
        }

isegment :: IRIParser st String
isegment =
    do { ps <- many ipchar
        ; return $ concat ps
        }

isegmentNz :: IRIParser st String
isegmentNz =
    do { ps <- many1 ipchar
        ; return $ concat ps
        }

isegmentNzc :: IRIParser st String
isegmentNzc =
    do { ps <- many1 (uchar "@")
        ; return $ concat ps
        }

ipchar :: IRIParser st String
ipchar = uchar ":@"

-- helper function for ipchar and friends
uchar :: String -> IRIParser st String
uchar extras =
        iunreservedChar
    <|> escaped
    <|> subDelims
    <|> do { c <- oneOf extras ; return [c] }

-- RFC3987, section 2.2

uiquery :: IRIParser st String
uiquery =
    do { ss <- many iqueryPart
        ; return $ '?' : concat ss
        }

iqueryPart :: IRIParser st String
iqueryPart = (many1 iprivate) <|> (uchar $ ":@" ++ "/?")

-- RFC3987, section 2.2

uifragment :: IRIParser st String
uifragment =
    do { ss <- many $ uchar (":@" ++ "/?")
        ; return $ '#' : concat ss
        }

-- Reference, Relative and Absolute IRI forms

-- RFC3987, section 2.2

iriReference :: IRIParser st IRI
iriReference = iri <|> irelativeRef

-- RFC3987, section 2.2

-- irelative-ref  = irelative-part [ "?" iquery ] [ "#" ifragment ]

{- irelative-part = "//" iauthority ipath-abempty
/ ipath-absolute -}

irelativeRef :: IRIParser st IRI
irelativeRef = iriWithPos $
    do { notMatching uscheme
        ; (ua, up) <- irelativePart
        ; uq <- option "" ( do { char '?' ; uiquery } )
        ; uf <- option "" ( do { char '#' ; uifragment } )
        ; return $ IRI
            { iriScheme = ""
            , iriAuthority = ua
            , iriPath = up
            , iriQuery = uq
            , iriFragment = uf
            , prefixName = ""
            , abbrevPath = ""
            , iriPos = nullRange
            }
        }

irelativePart :: IRIParser st ((Maybe IRIAuth), String)
irelativePart =
        do { try (string "//")
            ; ua <- uiauthority
            ; up <- ipathAbEmpty
            ; return (ua, up)
            }
    <|> do { up <- ipathAbs
            ; return (Nothing, up)
            }
    <|> do { up <- ipathNoScheme
            ; return (Nothing, up)
            }
    <|> do { return (Nothing, "")
            }

-- RFC3987, section 2.2

absoluteIRI :: IRIParser st IRI
absoluteIRI = iriWithPos $
    do { us <- uscheme
        {- ; ua <- option Nothing ( do { try (string "//") ; uiauthority } )
        ; up <- upath -}
        ; (ua, up) <- ihierPart
        ; uq <- option "" ( do { char '?' ; uiquery } )
        ; return $ IRI
            { iriScheme = us
            , iriAuthority = ua
            , iriPath = up
            , iriQuery = uq
            , iriFragment = ""
            , prefixName = ""
            , abbrevPath = ""
            , iriPos = nullRange
            }
        }

-- Imports from RFC 2234

    {- NOTE: can't use isAlphaNum etc. because these deal with ISO 8859
    (and possibly Unicode!) chars.
    [[[Above was a comment originally in GHC Network/IRI.hs:
    when IRIs are introduced then most codepoints above 128(?) should
    be treated as unreserved, and higher codepoints for letters should
    certainly be allowed.
    ]]] -}

isAlphaChar :: Char -> Bool
isAlphaChar c = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')

isDigitChar :: Char -> Bool
isDigitChar c = (c >= '0' && c <= '9')

isAlphaNumChar :: Char -> Bool
isAlphaNumChar c = isAlphaChar c || isDigitChar c

isUcsChar :: Char -> Bool
isUcsChar c =
  let n = ord c
  in (0xA0 <= n && n <= 0xD7FF) ||
     (0x20000 <= n && n <= 0x2FFFD) ||
     (0x30000 <= n && n <= 0x3FFFD) ||
     (0x40000 <= n && n <= 0x4FFFD) ||
     (0x50000 <= n && n <= 0x5FFFD) ||
     (0x60000 <= n && n <= 0x6FFFD) ||
     (0x70000 <= n && n <= 0x7FFFD) ||
     (0x80000 <= n && n <= 0x8FFFD) ||
     (0x90000 <= n && n <= 0x9FFFD) ||
     (0xA0000 <= n && n <= 0xAFFFD) ||
     (0xB0000 <= n && n <= 0xBFFFD) ||
     (0xC0000 <= n && n <= 0xCFFFD) ||
     (0xD0000 <= n && n <= 0xDFFFD) ||
     (0xE0000 <= n && n <= 0xEFFFD)

isIprivate :: Char -> Bool
isIprivate c =
  let n = ord c
  in (0xE000 <= n && n <= 0xF8FF) ||
     (0xF000 <= n && n <= 0xFFFD) ||
     (0x100000 <= n && n <= 0x10FFFD)

isHexDigitChar :: Char -> Bool
isHexDigitChar c = isHexDigit c

isSchemeChar :: Char -> Bool
isSchemeChar c = (isAlphaNumChar c) || (c `elem` "+-.")

alphaChar :: IRIParser st Char
alphaChar = satisfy isAlphaChar         -- or: Parsec.letter ?

digitChar :: IRIParser st Char
digitChar = satisfy isDigitChar         -- or: Parsec.digit ?

hexDigitChar :: IRIParser st Char
hexDigitChar = satisfy isHexDigitChar   -- or: Parsec.hexDigit ?

iprivate :: IRIParser st Char
iprivate = satisfy isIprivate

-- Additional parser combinators for common patterns

oneThenMany :: GenParser t s a -> GenParser t s a -> GenParser t s [a]
oneThenMany p1 pr =
    do { a1 <- p1
        ; ar <- many pr
        ; return (a1 : ar)
        }

countMinMax :: Int -> Int -> GenParser t s a -> GenParser t s [a]
countMinMax m n p | m > 0 =
    do { a1 <- p
        ; ar <- countMinMax (m - 1) (n - 1) p
        ; return (a1 : ar)
        }
countMinMax _ n _ | n <= 0 = return []
countMinMax _ n p = option [] $
    do { a1 <- p
        ; ar <- countMinMax 0 (n - 1) p
        ; return (a1 : ar)
        }

notMatching :: Show a => GenParser tok st a -> GenParser tok st ()
notMatching p = do { a <- try p ; unexpected (show a) } <|> return ()

-- * Reconstruct a IRI string


{- | Turn an 'IRI' into a string.
Uses a supplied function to map the iuserinfo part of the IRI.
The Show instance for IRI uses a mapping that hides any password
that may be present in the IRI.  Use this function with argument @id@
to preserve the password in the formatted output. -}
iriToString :: (String -> String) -> IRI -> ShowS
iriToString iuserinfomap i@(IRI { iriScheme = scheme
                            , iriAuthority = authority
                            , iriPath = path
                            , iriQuery = query
                            , iriFragment = fragment
                            , prefixName = pname
                            , abbrevPath = aPath
                            }) = case iriType i of
  Simple -> (aPath ++)
  Abbreviated -> (pname ++) . (aPath ++)
  _ -> (scheme ++) . (iriAuthToString iuserinfomap authority)
                 . (path ++) . (query ++) . (fragment ++)

iriToStringShort :: (String -> String) -> IRI -> ShowS
iriToStringShort iuserinfomap i@(IRI { iriScheme = scheme
                            , iriAuthority = authority
                            , iriPath = path
                            , iriQuery = query
                            , iriFragment = fragment
                            , prefixName = pname
                            , abbrevPath = aPath
                            }) = case iriType i of
  Full -> (scheme ++) . (iriAuthToString iuserinfomap authority)
                 . (path ++) . (query ++) . (fragment ++)
  _ -> (pname ++) . (aPath ++)

iriAuthToString :: (String -> String) -> (Maybe IRIAuth) -> ShowS
iriAuthToString _ Nothing = id          -- shows ""
iriAuthToString iuserinfomap
        (Just IRIAuth { iriUserInfo = uinfo
                      , iriRegName = regname
                      , iriPort = iport
                      } ) =
    ("//" ++) . (if null uinfo then id else (iuserinfomap uinfo ++))
             . (regname ++)
             . (iport ++)

-- * Character classes

-- | Returns 'True' if the character is allowed in a IRI.
isAllowedInIRI :: Char -> Bool
isAllowedInIRI c = isReserved c || isUnreserved c || c == '%' -- escape char

-- | Returns 'True' if the character is allowed unescaped in a IRI.
isUnescapedInIRI :: Char -> Bool
isUnescapedInIRI c = isReserved c || isUnreserved c

-- * Escape sequence handling

{- | Escape character if supplied predicate is not satisfied,
otherwise return character as singleton string. -}
escapeIRIChar :: (Char -> Bool) -> Char -> String
escapeIRIChar p c
    | p c = [c]
    | otherwise = '%' : myShowHex (ord c) ""
    where
        myShowHex :: Int -> ShowS
        myShowHex n r = case showIntAtBase 16 (toChrHex) n r of
            [] -> "00"
            [d] -> ['0', d]
            cs -> cs
        toChrHex d
            | d < 10 = chr (ord '0' + fromIntegral d)
            | otherwise = chr (ord 'A' + fromIntegral (d - 10))

-- | Can be used to make a string valid for use in a IRI.
escapeIRIString
    :: (Char -> Bool)     {- ^ a predicate which returns 'False'
                        if the character should be escaped -}
    -> String           -- ^ the string to process
    -> String           -- ^ the resulting IRI string
escapeIRIString p s = concatMap (escapeIRIChar p) s

{- | Turns all instances of escaped characters in the string back
into literal characters. -}
unEscapeString :: String -> String
unEscapeString [] = ""
unEscapeString ('%' : x1 : x2 : s) | isHexDigit x1 && isHexDigit x2 =
    chr (digitToInt x1 * 16 + digitToInt x2) : unEscapeString s
unEscapeString (c : s) = c : unEscapeString s

-- * Resolving a relative IRI relative to a base IRI

{- | Returns a new 'IRI' which represents the value of the
first 'IRI' interpreted as relative to the second 'IRI'.
For example:

> "foo" `relativeTo` "http://bar.org/" = "http://bar.org/foo"
> "http:foo" `nonStrictRelativeTo` "http://bar.org/" = "http://bar.org/foo"

Algorithm from RFC3986 [3], section 5.2.2 -}
nonStrictRelativeTo :: IRI -> IRI -> Maybe IRI
nonStrictRelativeTo ref base = relativeTo ref' base
    where
        ref' = if iriScheme ref == iriScheme base
               then ref { iriScheme = "" }
               else ref

isDefined :: ( MonadPlus m, Eq (m a) ) => m a -> Bool
isDefined a = a /= mzero

{- | Compute an absolute 'IRI' for a supplied IRI
relative to a given base. -}
relativeTo :: IRI -> IRI -> Maybe IRI
relativeTo ref base
    | isDefined ( iriScheme ref ) =
        just_isegments ref
    | isDefined ( iriAuthority ref ) =
        just_isegments ref { iriScheme = iriScheme base }
    | isDefined ( iriPath ref ) =
        if (head (iriPath ref) == '/') then
            just_isegments ref
                { iriScheme = iriScheme base
                , iriAuthority = iriAuthority base
                }
        else
            just_isegments ref
                { iriScheme = iriScheme base
                , iriAuthority = iriAuthority base
                , iriPath = mergePaths base ref
                }
    | isDefined ( iriQuery ref ) =
        just_isegments ref
            { iriScheme = iriScheme base
            , iriAuthority = iriAuthority base
            , iriPath = iriPath base
            }
    | otherwise =
        just_isegments ref
            { iriScheme = iriScheme base
            , iriAuthority = iriAuthority base
            , iriPath = iriPath base
            , iriQuery = iriQuery base
            }
    where
        just_isegments u =
            Just $ u { iriPath = removeDotSegments (iriPath u) }
        mergePaths b r
            | isDefined (iriAuthority b) && null pb = '/' : pr
            | otherwise = dropLast pb ++ pr
            where
                pb = iriPath b
                pr = iriPath r
        dropLast = fst . splitLast -- reverse . dropWhile (/='/') . reverse

-- Remove dot isegments, but protect leading '/' character
removeDotSegments :: String -> String
removeDotSegments ('/' : ps) = '/' : elimDots ps []
removeDotSegments ps = elimDots ps []

-- Second arg accumulates isegments processed so far in reverse order
elimDots :: String -> [String] -> String
elimDots [] [] = ""
elimDots [] rs = concat (reverse rs)
elimDots ( '.' : '/' : ps) rs = elimDots ps rs
elimDots ( '.' : [] ) rs = elimDots [] rs
elimDots ( '.' : '.' : '/' : ps) rs = elimDots ps (dropHead rs)
elimDots ( '.' : '.' : [] ) rs = elimDots [] (dropHead rs)
elimDots ps rs = elimDots ps1 (r : rs)
    where
        (r, ps1) = nextSegment ps

-- Return tail of non-null list, otherwise return null list
dropHead :: [a] -> [a]
dropHead [] = []
dropHead (_ : rs) = rs

{- Returns the next isegment and the rest of the path from a path string.
Each isegment ends with the next '/' or the end of string. -}
nextSegment :: String -> (String, String)
nextSegment ps =
    case break (== '/') ps of
        (r, '/' : ps1) -> (r ++ "/", ps1)
        (r, _) -> (r, [])

-- Split last (name) isegment from path, returning (path,name)
splitLast :: String -> (String, String)
splitLast path = (reverse revpath, reverse revname)
    where
        (revname, revpath) = break (== '/') $ reverse path

-- * Finding a IRI relative to a base IRI

{- | Returns a new 'IRI' which represents the relative location of
the first 'IRI' with respect to the second 'IRI'.  Thus, the
values supplied are expected to be absolute IRIs, and the result
returned may be a relative IRI.

Example:

> "http://example.com/Root/sub1/name2#frag"
>   `relativeFrom` "http://example.com/Root/sub2/name2#frag"
>   == "../sub1/name2#frag"

There is no single correct implementation of this function,
but any acceptable implementation must satisfy the following:

> (uabs `relativeFrom` ubase) `relativeTo` ubase == uabs

For any valid absolute IRI.
(cf. <http://lists.w3.org/Archives/Public/iri/2003Jan/0008.html>
<http://lists.w3.org/Archives/Public/iri/2003Jan/0005.html>) -}
relativeFrom :: IRI -> IRI -> IRI
relativeFrom uabs base
    | diff iriScheme uabs base = uabs
    | diff iriAuthority uabs base = uabs { iriScheme = "" }
    | diff iriPath uabs base = uabs
        { iriScheme = ""
        , iriAuthority = Nothing
        , iriPath = relPathFrom (removeBodyDotSegments $ iriPath uabs)
                                     (removeBodyDotSegments $ iriPath base)
        }
    | diff iriQuery uabs base = uabs
        { iriScheme = ""
        , iriAuthority = Nothing
        , iriPath = ""
        }
    | otherwise = uabs          -- Always carry fragment from uabs
        { iriScheme = ""
        , iriAuthority = Nothing
        , iriPath = ""
        , iriQuery = ""
        }
    where
        diff :: Eq b => (a -> b) -> a -> a -> Bool
        diff sel u1 u2 = sel u1 /= sel u2
        -- Remove dot isegments except the final isegment
        removeBodyDotSegments p = removeDotSegments p1 ++ p2
            where
                (p1, p2) = splitLast p

relPathFrom :: String -> String -> String
relPathFrom [] _ = "/"
relPathFrom pabs [] = pabs
relPathFrom pabs base =                 -- Construct a relative path isegments
    if sa1 == sb1                       -- if the paths share a leading isegment
        then if (sa1 == "/")            -- other than a leading '/'
            then if (sa2 == sb2)
                then relPathFrom1 ra2 rb2
                else pabs
            else relPathFrom1 ra1 rb1
        else pabs
    where
        (sa1, ra1) = nextSegment pabs
        (sb1, rb1) = nextSegment base
        (sa2, ra2) = nextSegment ra1
        (sb2, rb2) = nextSegment rb1

{- relPathFrom1 strips off trailing names from the supplied paths,
and calls difPathFrom to find the relative path from base to
target -}
relPathFrom1 :: String -> String -> String
relPathFrom1 pabs base = relName
    where
        (sa, na) = splitLast pabs
        (sb, nb) = splitLast base
        rp = relSegsFrom sa sb
        relName = if null rp then
                      if (na == nb) then ""
                      else if protect na then "./" ++ na
                      else na
                  else
                      rp ++ na
        -- Precede name with some path if it is null or contains a ':'
        protect n = null n || ':' `elem` n

{- relSegsFrom discards any common leading isegments from both paths,
then invokes difSegsFrom to calculate a relative path from the end
of the base path to the end of the target path.
The final name is handled separately, so this deals only with
"directory" segtments. -}
relSegsFrom :: String -> String -> String
relSegsFrom [] [] = ""      -- paths are identical
relSegsFrom sabs base =
    if sa1 == sb1
        then relSegsFrom ra1 rb1
        else difSegsFrom sabs base
    where
        (sa1, ra1) = nextSegment sabs
        (sb1, rb1) = nextSegment base

{- difSegsFrom calculates a path difference from base to target,
not including the final name at the end of the path
(i.e. results always ends with '/')

This function operates under the invariant that the supplied
value of sabs is the desired path relative to the beginning of
base.  Thus, when base is empty, the desired path has been found. -}
difSegsFrom :: String -> String -> String
difSegsFrom sabs "" = sabs
difSegsFrom sabs base = difSegsFrom ("../" ++ sabs) (snd $ nextSegment base)

-- * Other normalization functions

-- |Expands a CURIE to an IRI
expandCurie :: Map String IRI -> IRI -> IRI
expandCurie prefixMap c =
  if iriType c == Full then c else
  let i = findWithDefault nullIRI (prefixName c) prefixMap in
  mergeCurie c $ i { prefixName = prefixName c
                                , abbrevPath = abbrevPath c
                                }

-- |'mergeCurie' merges the CURIE @c@ into IRI @i@, appending path and query-part of @c@ to @i@. Also replacing fragment of @c@ with @i@ if both are not empty.
mergeCurie :: IRI -> IRI -> IRI
mergeCurie c i =
  i { iriPath = iriPath i ++ abbrevPath c
    , iriQuery = iriQuery i ++ if null $ iriQuery c then [] else '&':(tail $ iriQuery c)
    , iriFragment = if null $ iriFragment i then iriFragment c else iriFragment i
    }

{- | Case normalization; cf. RFC3986 section 6.2.2.1
NOTE:  authority case normalization is not performed -}
normalizeCase :: String -> String
normalizeCase iristr = ncScheme iristr
    where
        ncScheme (':' : cs) = ':' : ncEscape cs
        ncScheme (c : cs) | isSchemeChar c = toLower c : ncScheme cs
        ncScheme _ = ncEscape iristr -- no scheme present
        ncEscape ('%' : h1 : h2 : cs) =
            '%' : toUpper h1 : toUpper h2 : ncEscape cs
        ncEscape (c : cs) = c : ncEscape cs
        ncEscape [] = []

-- | Encoding normalization; cf. RFC3986 section 6.2.2.2
normalizeEscape :: String -> String
normalizeEscape ('%' : h1 : h2 : cs)
    | isHexDigit h1 && isHexDigit h2 && isUnreserved escval =
        escval : normalizeEscape cs
    where
        escval = chr (digitToInt h1 * 16 + digitToInt h2)
normalizeEscape (c : cs) = c : normalizeEscape cs
normalizeEscape [] = []

-- | Path isegment normalization; cf. RFC3986 section 6.2.2.4
normalizePathSegments :: String -> String
normalizePathSegments iristr = normstr jiri
    where
        jiri = parseIRI iristr
        normstr Nothing = iristr
        normstr (Just u) = show (normiri u)
        normiri u = u { iriPath = removeDotSegments (iriPath u) }


-- FIX: where do the instances fit the best?
instance ShATermConvertible IRI where
  toShATermAux att0 u = do
    (att1, is) <- toShATerm' att0 ((iriToString id u) "")
    return $ addATerm (ShAAppl "IRI" [is] []) att1
  fromShATermAux ix att0 =
    case getShATerm ix att0 of
      x@(ShAAppl "IRI" [is] _) ->
        case fromShATerm' is att0 of
          (att1, is') ->
            case parseIRICurie is' of
              Nothing ->
                case parseIRIReference is' of
                  Nothing -> fromShATermError "IRI" x
                  Just i -> (att1, i)
              Just i -> (att1, i)
      i -> fromShATermError "IRI" i