{-
Module      :  $Header$
Copyright   :  (c) T. Mossakowski, Uni Bremen 2004
Licence     :  All rights reserved.

Maintainer  :  till@tzi.de
Stability   :  provisional
Portability :  portable

  printing AS_CoCASL and CoCASLSign data types
-}

module CoCASL.Print_AS where

import Common.Id
import Common.Keywords
import qualified Common.Lib.Set as Set
import Common.Lib.Pretty
import Common.PrettyPrint
import Common.PPUtils
import CASL.Print_AS_Basic
import CASL.Sign
import CoCASL.AS_CoCASL
import CoCASL.CoCASLSign
import Common.AS_Annotation
import CASL.AS_Basic_CASL 

instance PrettyPrint C_BASIC_ITEM where
    printText0 ga (CoFree_datatype l _) = 
	hang (ptext cofreeS <+> ptext cotypeS<>pluralS_doc l) 4 $ 
	     semiAnno_text ga l
    printText0 ga (CoSort_gen l _) = 
	hang (ptext cogeneratedS <+> condCotypeS) 4 $ 
	     condBraces (vcat (map (printText0 ga) l))
	where condCotypeS = 
		  if isOnlyDatatype then ptext cotypeS<>pluralS_doc l 
		  else empty
	      condBraces d = 
		  if isOnlyDatatype then 
		     case l of
		     [x] -> case x of
			    Annoted (Ext_SIG_ITEMS (CoDatatype_items l' _)) _ lans _ -> 
				vcat (map (printText0 ga) lans) 
					 $$ semiAnno_text ga l'
			    _ -> error "wrong implementation of isOnlyDatatype"
                     _ -> error "wrong implementation of isOnlyDatatype"
		  else braces d
	      isOnlyDatatype = 
		  case l of
		  [x] -> case x of 
			 Annoted (Ext_SIG_ITEMS (CoDatatype_items _ _)) _ _ _ -> True
			 _ -> False
		  _  -> False


instance PrettyPrint C_SIG_ITEM where
    printText0 ga (CoDatatype_items l _) = 
	text cotypeS<>pluralS_doc l <+> semiAnno_text ga l 

instance PrettyPrint CODATATYPE_DECL where
    printText0 ga (CoDatatype_decl s a _) = 
	printText0 ga s <+> 
	sep ((hang (text defnS) 4 (printText0 ga $ head a)):
	     (map (\x -> nest 2 $ ptext barS <+> nest 2 (printText0 ga x)) $ 
		  tail a))

instance PrettyPrint COALTERNATIVE where
    printText0 ga (CoTotal_construct n l _) = printText0 ga n 
				 <> if null l then empty 
				    else parens(semiT_text ga l)
    printText0 ga (CoPartial_construct n l _) = printText0 ga n 
				 <> parens(semiT_text ga l)
				 <> text quMark
    printText0 ga (CoSubsorts l _) = text sortS <+> commaT_text ga l 

instance PrettyPrint COCOMPONENTS where
    printText0 ga (CoSelect l s _) = commaT_text ga l 
				<> colon 
				<> printText0 ga s 


instance PrettyPrint C_FORMULA where
    printText0 ga (Box t f _) = 
       brackets (printText0 ga t) <> printText0 ga f
    printText0 ga (Diamond t f _) = 
	let sp = case t of 
			 Simple_mod _ -> (<>)
			 _ -> (<+>)
	    in ptext lessS `sp` printText0 ga t `sp` ptext greaterS 
		   <+> printText0 ga f
    printText0 ga (CoSort_gen_ax sorts ops _) = 
        text cogeneratedS <> 
        braces (text sortS <+> commaT_text ga sorts 
                <> semi <+> semiT_text ga ops)

instance PrettyPrint MODALITY where
    printText0 ga (Simple_mod ident) = 
	 printText0 ga ident
    printText0 ga (Term_mod t) = printText0 ga t

instance PrettyPrint CoCASLSign where
    printText0 ga s = empty

instance PrettyPrint a => PrettyPrint (Maybe a) where
    printText0 ga Nothing = empty
    printText0 ga (Just x) = printText0 ga x

instance ListCheck CODATATYPE_DECL where
    (CoDatatype_decl _ _ _) `innerListGT` _ = False
