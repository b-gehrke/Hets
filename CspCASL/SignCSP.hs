{- |
Module      :  $Id$
Description :  CspCASL signatures
Copyright   :  (c) Markus Roggenbach and Till Mossakowski and Uni Bremen 2004
License     :  similar to LGPL, see HetCATS/LICENSE.txt or LIZENZ.txt

Maintainer  :  M.Roggenbach@swansea.ac.uk
Stability   :  provisional
Portability :  portable

signatures for CSP-CASL

-}

-- todo:  implement isInclusion, computeExt

module CspCASL.SignCSP where

import CASL.AS_Basic_CASL (SORT)
import qualified CASL.Sign
import CASL.Morphism
import Common.Id
import qualified Data.Map as Map
import Common.Doc
import Common.DocUtils

-- | CspCASL signature fragments.
data CSPAddSign = CSPAddSign { channelNames' :: Map.Map Id SORT
                             , processNames :: Map.Map Id (Maybe SORT)
                             }
                  deriving (Eq, Show)

-- | CspCASL signatures.
type CSPSign = CASL.Sign.Sign () CSPAddSign

emptyCSPSign :: CSPSign
emptyCSPSign = CASL.Sign.emptySign emptyCSPAddSign

emptyCSPAddSign :: CSPAddSign
emptyCSPAddSign = CSPAddSign { channelNames' = Map.empty
                             , processNames = Map.empty
                             }

diffCSPAddSign :: CSPAddSign -> CSPAddSign -> CSPAddSign
diffCSPAddSign a b =
    a { channelNames' = channelNames' a `Map.difference` channelNames' b
      , processNames = processNames a `Map.difference` processNames b
      }

addCSPAddSign :: CSPAddSign -> CSPAddSign -> CSPAddSign
addCSPAddSign a b =
    a { channelNames' = channelNames' a `Map.union` channelNames' b
      , processNames = processNames a `Map.union` processNames b
      }

isInclusion :: CSPAddSign -> CSPAddSign -> Bool
isInclusion _ _ = True

data CSPAddMorphism = CSPAddMorphism
    { channelMap :: Map.Map Id Id
    , processMap :: Map.Map Id Id
    } deriving (Eq, Show)

type CSPMorphism = Morphism () CSPAddSign CSPAddMorphism

emptyCSPAddMorphism :: CSPAddMorphism
emptyCSPAddMorphism = CSPAddMorphism
  { channelMap = Map.empty -- ???
  , processMap = Map.empty }

-- dummy instances, need to be elaborated!
instance Pretty CSPAddSign where
  pretty = text . show
instance Pretty CSPAddMorphism where
  pretty = text . show
