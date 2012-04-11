{- |
Module      :  $Header$
Description :  Import data generated by hol2hets into a DG
Copyright   :  (c) Jonathan von Schroeder, DFKI GmbH 2010
License     :  GPLv2 or higher, see LICENSE.txt

Maintainer  :  jonathan.von_schroeder@dfki.de
Stability   :  experimental
Portability :  portable

-}

module Isabelle.Isa2DG where

import Static.GTheory
import Static.DevGraph

import Static.DgUtils
import Static.History
import Static.ComputeTheory

import Logic.Prover
import Logic.ExtSign
import Logic.Grothendieck

import Common.LibName
import Common.Id
import Common.AS_Annotation
import Common.IRI (simpleIdToIRI)

import Isabelle.Logic_Isabelle
import Isabelle.IsaSign
import Isabelle.IsaImport (importIsaDataIO)

import Driver.Options

import qualified Data.Map as Map

import System.FilePath.Posix

makeNamedSentence :: (String, Term) -> Named Sentence
makeNamedSentence (n, t) = makeNamed n $ mkSen t

_insNodeDG :: Sign -> [Named Sentence] -> String
              -> DGraph -> DGraph
_insNodeDG sig sens n dg =
 let gt = G_theory Isabelle (makeExtSign Isabelle sig) startSigId
           (toThSens sens) startThId
     labelK = newInfoNodeLab
      (makeName (simpleIdToIRI (mkSimpleId n)))
      (newNodeInfo DGEmpty)
      gt
     k = getNewNodeDG dg
     insN = [InsertNode (k, labelK)]
     newDG = changesDGH dg insN
     labCh = [SetNodeLab labelK (k, labelK
      { globalTheory = computeLabelTheory Map.empty newDG
        (k, labelK) })]
     newDG1 = changesDGH newDG labCh in newDG1

anaIsaFile :: HetcatsOpts -> FilePath -> IO (Maybe (LibName, LibEnv))
anaIsaFile _ path = do
 (name,consts,axioms,theorems,types) <- importIsaDataIO path
 let sens = map makeNamedSentence (axioms ++ theorems
             ++ (foldl (\ l c -> case c of 
                          (_,_,Nothing) -> l
                          (n,_,Just tm) -> (n,tm):l) [] consts))
 let sgn = emptySign { constTab = foldl (\ m (n,t,_) -> Map.insert (mkVName n) t m) Map.empty consts, domainTab = types }
 let dg = _insNodeDG sgn sens name emptyDG
     le = Map.insert (emptyLibName
            (System.FilePath.Posix.takeBaseName path))
           dg Map.empty
 return $ Just (emptyLibName
  (System.FilePath.Posix.takeBaseName path),
  computeLibEnvTheories le)
