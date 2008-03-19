{- |
Module      :  $Header$
Description :  Instance of class Logic for Modal CASL
Copyright   :  (c) Till Mossakowski, Uni Bremen 2002-2004
License     :  similar to LGPL, see HetCATS/LICENSE.txt or LIZENZ.txt

Maintainer  :  luecke@informatik.uni-bremen.de
Stability   :  provisional
Portability :  portable

Instance of class Logic for modal logic.
-}

module Modal.Logic_Modal where

import Modal.AS_Modal
import Modal.ModalSign
import Modal.ATC_Modal()
import Modal.Parse_AS
import Modal.StatAna
import CASL.Sign
import CASL.Morphism
import CASL.SymbolMapAnalysis
import CASL.AS_Basic_CASL
import CASL.Parse_AS_Basic
import CASL.MapSentence
import CASL.SimplifySen
import CASL.SymbolParser
import CASL.Taxonomy
import CASL.Logic_CASL ()
import Logic.Logic

data Modal = Modal deriving Show

instance Language Modal  where
 description _ =
  "ModalCASL extends CASL by modal operators. Syntax for ordinary\n\
  \modalities, multi-modal logics as well as  term-modal\n\
  \logic (also covering dynamic logic) is provided.\n\
  \Specific modal logics can be obtained via restrictions to\n\
  \sublanguages."

type MSign = Sign M_FORMULA ModalSign
type ModalMor = Morphism M_FORMULA ModalSign ()
type ModalFORMULA = FORMULA M_FORMULA

instance Syntax Modal M_BASIC_SPEC SYMB_ITEMS SYMB_MAP_ITEMS where
    parse_basic_spec Modal = Just $ basicSpec modal_reserved_words
    parse_symb_items Modal = Just $ symbItems modal_reserved_words
    parse_symb_map_items Modal = Just $ symbMapItems modal_reserved_words

-- Modal logic

map_M_FORMULA :: MapSen M_FORMULA ModalSign ()
map_M_FORMULA mor (BoxOrDiamond b m f ps) =
    let newM = case m of
                   Simple_mod _ -> m
                   Term_mod t -> let newT = mapTerm map_M_FORMULA mor t
                                 in Term_mod newT
        newF = mapSen map_M_FORMULA mor f
    in BoxOrDiamond b newM newF ps

instance Sentences Modal ModalFORMULA MSign ModalMor Symbol where
      map_sen Modal m = return . mapSen map_M_FORMULA m
      parse_sentence Modal = Nothing
      sym_of Modal = symOf
      symmap_of Modal = morphismToSymbMap
      sym_name Modal = symName
      simplify_sen Modal = simplifySen minExpForm simModal

-- simplifySen for ExtFORMULA
simModal :: Sign M_FORMULA ModalSign -> M_FORMULA -> M_FORMULA
simModal sign (BoxOrDiamond b md form pos) =
    let mod' = case md of
                        Term_mod term -> Term_mod $ rmTypesT minExpForm
                                         simModal sign term
                        t -> t
    in BoxOrDiamond b mod'
                 (simplifySen minExpForm simModal sign form) pos

rmTypesExt :: a -> b -> b
rmTypesExt _ f = f

instance StaticAnalysis Modal M_BASIC_SPEC ModalFORMULA
               SYMB_ITEMS SYMB_MAP_ITEMS
               MSign
               ModalMor
               Symbol RawSymbol where
         basic_analysis Modal = Just $ basicModalAnalysis
         stat_symb_map_items Modal = statSymbMapItems
         stat_symb_items Modal = statSymbItems
         ensures_amalgamability Modal _ =
             fail "Modal: ensures_amalgamability nyi" -- ???

         sign_to_basic_spec Modal _sigma _sens = Basic_spec [] -- ???

         symbol_to_raw Modal = symbolToRaw
         id_to_raw Modal = idToRaw
         matches Modal = CASL.Morphism.matches

         empty_signature Modal = emptySign emptyModalSign
         signature_union Modal s = return . addSig addModalSign s
         morphism_union Modal = morphismUnion (const id) addModalSign
         final_union Modal = finalUnion addModalSign
         inclusion Modal = sigInclusion () isSubModalSign diffModalSign
         cogenerated_sign Modal = cogeneratedSign () isSubModalSign
         generated_sign Modal = generatedSign () isSubModalSign
         induced_from_morphism Modal = inducedFromMorphism () isSubModalSign
         induced_from_to_morphism Modal =
             inducedFromToMorphism () isSubModalSign diffModalSign
         theory_to_taxonomy Modal = convTaxo

instance Logic Modal ()
               M_BASIC_SPEC ModalFORMULA SYMB_ITEMS SYMB_MAP_ITEMS
               MSign
               ModalMor
               Symbol RawSymbol () where
         stability _ = Unstable
         empty_proof_tree _ = ()
