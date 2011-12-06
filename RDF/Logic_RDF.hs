{-# LANGUAGE CPP, MultiParamTypeClasses, TypeSynonymInstances #-}
{-# OPTIONS -w #-}
{- |
Module      :  $Header$
Description :  instance of the class Logic for RDF
Copyright   :  (c) Felix Mance
License     :  GPLv2 or higher, see LICENSE.txt

Maintainer  :  f.mance@jacobs-university.de
Stability   :  provisional
Portability :  non-portable

Here is the place where the class Logic is instantiated for RDF
-}

module RDF.Logic_RDF where

import Common.AS_Annotation
import Common.Doc
import Common.DocUtils
import Common.ProofTree
import Common.DefaultMorphism
import Common.Consistency
import Common.ProverTools

import ATC.ProofTree ()

import Logic.Logic

import RDF.AS
import RDF.ATC_RDF ()
import RDF.Parse
import RDF.Symbols
import RDF.Print
import RDF.Sign
import RDF.Morphism
import RDF.Sublogic

data RDF = RDF deriving Show

instance Language RDF where
  language_name _ = "RDF"
  description _ =
    "RDF -- Resource Description Framework http://www.w3.org/RDF/"

instance Category Sign RDFMorphism where
    ide sig = inclRDFMorphism sig sig
    dom = osource
    cod = otarget
    legal_mor = legalMor
    isInclusion = isRDFInclusion
    composeMorphisms = composeMor

instance Syntax RDF RDFGraph SymbItems SymbMapItems where
    parse_basic_spec RDF = undefined --Just basicSpec
    parse_symb_items RDF = Just symbItems
    parse_symb_map_items RDF = Just symbMapItems

instance Sentences RDF Axiom Sign RDFMorphism RDFEntity where
    map_sen RDF = mapSen
    print_named RDF namedSen = undefined
    sym_of RDF = singletonList . symOf
    symmap_of RDF = symMapOf

instance StaticAnalysis RDF RDFGraph Axiom
               SymbItems SymbMapItems
               Sign
               RDFMorphism
               RDFEntity RawSymb where
      basic_analysis RDF = undefined -- Just basicRDFAnalysis
      stat_symb_items RDF _ = undefined -- return . statSymbItems
      stat_symb_map_items RDF _ _ = undefined -- statSymbMapItems
      empty_signature RDF = emptySign
      signature_union RDF = undefined -- uniteSign
      signatureDiff RDF s = return . diffSig s
      final_union RDF = signature_union RDF
      is_subsig RDF = isSubSign
      subsig_inclusion RDF s = undefined --return . inclOWLMorphism s
      matches RDF = undefined --matchesSym
      symbol_to_raw RDF = undefined -- ASymbol
      induced_from_morphism RDF = undefined --inducedFromMor
      cogenerated_sign RDF = undefined --cogeneratedSign
      generated_sign RDF = undefined --generatedSign
      signature_colimit RDF = undefined --return . signColimit
#ifdef UNI_PACKAGE
      theory_to_taxonomy RDF = undefined --onto2Tax
#endif

instance Logic RDF RDFSub RDFGraph Axiom SymbItems SymbMapItems
               Sign
               RDFMorphism RDFEntity RawSymb ProofTree where
         empty_proof_tree RDF = emptyProofTree
#ifdef UNI_PACKAGE
         provers RDF = undefined
         cons_checkers RDF = undefined
         conservativityCheck RDF = undefined
#endif


{-
instance SemiLatticeWithTop ProfSub where
    join = maxS
    top = topS

instance SublogicName ProfSub where
    sublogicName = nameS

instance MinSublogic ProfSub Axiom where
    minSublogic = psAxiom

instance MinSublogic ProfSub OWLMorphism where
    minSublogic = sMorph

instance ProjectSublogic ProfSub OWLMorphism where
    projectSublogic = prMorph

instance MinSublogic ProfSub Sign where
    minSublogic = sSig

instance ProjectSublogic ProfSub Sign where
    projectSublogic = prSign

instance MinSublogic ProfSub SymbItems where
    minSublogic = const topS

instance MinSublogic ProfSub SymbMapItems where
    minSublogic = const topS

instance MinSublogic ProfSub Entity where
    minSublogic = const topS

instance MinSublogic ProfSub OntologyDocument where
    minSublogic = profilesAndSublogic

instance ProjectSublogicM ProfSub SymbItems where
    projectSublogicM = const Just

instance ProjectSublogicM ProfSub SymbMapItems where
    projectSublogicM = const Just

instance ProjectSublogicM ProfSub Entity where
    projectSublogicM = const Just

instance ProjectSublogic ProfSub OntologyDocument where
    projectSublogic = prOntDoc
-}