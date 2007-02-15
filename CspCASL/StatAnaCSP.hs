{- |
Module      :  $Header$
Copyright   :  (c) Markus Roggenbach, Till Mossakowski, Uni Bremen 2004-2005
License     :  similar to LGPL, see HetCATS/LICENSE.txt or LIZENZ.txt

Maintainer  :  M.Roggenbach@swansea.ac.uk
Stability   :  provisional
Portability :  portable

static analysis for CSP-CASL

-}

{- todo:
   most of the process and channel analysis missing

   sentences are completely missing:
   use equation systems of processes, like:

   spec hugo =
     data ...
     channel ...
     process A = a->A
     process P = ...A...Q...
             Q = ...P....
             R = a->P
     reveal R

reveal R should keep CASL data part, and reveal process R

-}

module CspCASL.StatAnaCSP where

import CASL.Sign
import Common.AS_Annotation
import Common.Result
import Common.GlobalAnnotations
import Common.Id
import qualified Common.Lib.Map as Map
import Common.Lib.State

import CspCASL.AS_CspCASL (BASIC_CSP_CASL_SPEC(..),
                           OLD_CSP_CASL_SPEC(..)
                          )
import CspCASL.AS_CspCASL_Process (PROCESS(..),
                                   PROCESS_DEFN(..),
                                   CHANNEL_DECL(..),
                                   CHANNEL_ITEM(..)
                                  )
import CspCASL.SignCSP

basicAnalysisCspCASL :: (BASIC_CSP_CASL_SPEC, CSPSign, GlobalAnnos)
        -> Result (OLD_CSP_CASL_SPEC, CSPSign, [Named ()])

basicAnalysisCspCASL (Basic_Csp_Casl_Spec _ _, sign, annos)
    = old_basic_analysis_CspCASL (Old_CspCASL_Spec (Channel_items []) (Process Skip), sign, annos)








old_basic_analysis_CspCASL ::
    (OLD_CSP_CASL_SPEC, CSPSign, GlobalAnnos)
        -> Result (OLD_CSP_CASL_SPEC, CSPSign, [Named ()])
old_basic_analysis_CspCASL
    (Old_CspCASL_Spec ch p, sigma, _ga) =
  do let ((ch',p'), accSig) = runState (ana_BASIC_CSP (ch,p)) sigma
         ds = reverse $ envDiags accSig
     Result ds (Just ()) -- insert diags
     return (Old_CspCASL_Spec ch' p', accSig, [])



-- | the main CspCASL analysis function
ana_BASIC_CSP :: (CHANNEL_DECL, PROCESS_DEFN)
         -> State CSPSign (CHANNEL_DECL, PROCESS_DEFN)
ana_BASIC_CSP (ch, p) = do
   ch' <- anaChannels ch
   p' <- anaProcesses p
   return (ch',p')

anaChannels :: CHANNEL_DECL -> State CSPSign CHANNEL_DECL
anaChannels (Channel_items cits) =
  fmap Channel_items $ mapM (anaChannel) cits

anaChannel :: CHANNEL_ITEM -> State CSPSign CHANNEL_ITEM
anaChannel chdecl@(Channel_decl newnames s) = do
  checkSorts [s]
  sig <- get
  let ext = extendedInfo sig
      oldchn = channelNames ext
  -- test for double declaration with different sorts should be added
  let ins m n = Map.insert (mkId [n]) s m
  put sig { extendedInfo = ext { channelNames = foldl ins oldchn newnames } }
  return chdecl

anaProcesses :: PROCESS_DEFN -> State CSPSign PROCESS_DEFN
anaProcesses p = return p



