{- |
Module      :  $Header$
Description :  A collection of data-structures, functions and instances for
                the THF modules.
Copyright   :  (c) A. Tsogias, DFKI Bremen 2011
License     :  GPLv2 or higher, see LICENSE.txt

Maintainer  :  Alexis.Tsogias@dfki.de
Stability   :  provisional
Portability :  portable

Data structures and functions used in Logic_THF and HasCASL2THF.
Note: Some of the implenentations depend on the THF0 Syntax.
-}

module THF.Cons where

import THF.As
import Common.Id

-- Some empty instances

--------------------------------------------------------------------------------
-- BasicSpecTHF
--------------------------------------------------------------------------------

data BasicSpecTHF =
    BasicSpecTHF [TPTP_THF] --replace THFBS using Sublogic.hs
    deriving (Show, Eq, Ord)

instance GetRange BasicSpecTHF

--------------------------------------------------------------------------------
-- SentenceTHF
--------------------------------------------------------------------------------

-- A Sentence is a THFFormula.
data SentenceTHF = Sentence
    { senRole       :: FormulaRole
    , senFormula    :: THFFormula
    , senAnno       :: Annotations }
    deriving (Show, Eq, Ord)

instance GetRange SentenceTHF

--------------------------------------------------------------------------------
-- SymbolTHF
--------------------------------------------------------------------------------

data SymbolTHF = Symbol
    { symId     :: Constant
    , symName   :: Name
    , symType   :: SymbolType
    } deriving (Show, Eq, Ord)

instance GetRange SymbolTHF

data SymbolType =
    ST_Const Type
  | ST_Type Kind
    deriving (Show, Eq, Ord)

data Type =
    TType
  | OType
  | IType
  | MapType Type Type
  | ProdType [Type]
  | CType Constant
  | SType Token
  | VType Token
  | ParType Type
    deriving (Show, Ord, Eq)

data Kind =
    Kind
  | MapKind Kind Kind Range
  | ProdKind [Kind]
  | SysType Token
  | VKind Token
  | ParKind Kind
    deriving (Show, Ord, Eq)
