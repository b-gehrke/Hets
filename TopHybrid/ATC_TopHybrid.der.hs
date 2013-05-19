{-# OPTIONS -w -O0 #-}
{-# LANGUAGE StandaloneDeriving, DeriveDataTypeable #-}
{- |
Module      :  TopHybrid/ATC_TopHybrid.der.hs
Description :  generated Typeable, ShATermConvertible instances
Copyright   :  (c) DFKI GmbH 2012
License     :  GPLv2 or higher, see LICENSE.txt

Maintainer  :  Christian.Maeder@dfki.de
Stability   :  provisional
Portability :  non-portable(derive Typeable instances)

Automatic derivation of instances via DrIFT-rule Typeable, ShATermConvertible
  for the type(s):
'TopHybrid.AS_TopHybrid.TH_BSPEC'
'TopHybrid.AS_TopHybrid.TH_BASIC_ITEM'
'TopHybrid.AS_TopHybrid.TH_FORMULA'
'TopHybrid.AS_TopHybrid.Mor'
'TopHybrid.TopHybridSign.THybridSign'
-}

{-
Generated by 'genRules' (automatic rule generation for DrIFT). Don't touch!!
  dependency files:
TopHybrid/AS_TopHybrid.hs
TopHybrid/TopHybridSign.hs
-}

module TopHybrid.ATC_TopHybrid () where

import ATC.AS_Annotation
import ATerm.Lib
import Common.AS_Annotation
import Common.Id
import Common.Result
import Data.Set
import Data.Typeable
import Logic.Logic
import TopHybrid.AS_TopHybrid
import TopHybrid.TopHybridSign
import Unsafe.Coerce

{-! for TopHybrid.AS_TopHybrid.TH_BSPEC derive : Typeable !-}
{-! for TopHybrid.AS_TopHybrid.TH_BASIC_ITEM derive : Typeable !-}
{-! for TopHybrid.AS_TopHybrid.TH_FORMULA derive : Typeable !-}
{-! for TopHybrid.AS_TopHybrid.Mor derive : Typeable !-}
{-! for TopHybrid.TopHybridSign.THybridSign derive : Typeable !-}

{-! for TopHybrid.AS_TopHybrid.TH_BSPEC derive : ShATermConvertible !-}
{-! for TopHybrid.AS_TopHybrid.TH_BASIC_ITEM derive : ShATermConvertible !-}
{-! for TopHybrid.AS_TopHybrid.TH_FORMULA derive : ShATermConvertible !-}
{-! for TopHybrid.AS_TopHybrid.Mor derive : ShATermConvertible !-}
{-! for TopHybrid.TopHybridSign.THybridSign derive : ShATermConvertible !-}