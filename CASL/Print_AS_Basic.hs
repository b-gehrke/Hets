{- |
Module      :  $Header$
Copyright   :  (c) Klaus L�ttich, Christian Maeder and Uni Bremen 2002-2003 
Licence     :  similar to LGPL, see HetCATS/LICENCE.txt or LIZENZ.txt

Maintainer  :  hets@tzi.de
Stability   :  experimental
Portability :  portable
    
   pretty printing data types of 'BASIC_SPEC'

-}

module CASL.Print_AS_Basic where



import Data.List (mapAccumL)
import Data.Char (isDigit)

import Common.Id
import Common.Lib.Parsec.Pos (sourceLine,sourceColumn)
import CASL.AS_Basic_CASL
import Common.AS_Annotation
import Common.GlobalAnnotations
import CASL.LiteralFuns

import Common.Print_AS_Annotation

import Common.Keywords
import Common.Lib.Pretty
import Common.PrettyPrint
import Common.PPUtils

-- import Debug.Trace
-- trace :: String -> a -> a
-- trace _ a = a

instance PrettyPrint BASIC_SPEC where
    printText0 ga (Basic_spec l) = 
	if null l then braces empty else vcat (map (printText0 ga) l) 

instance PrettyPrint BASIC_ITEMS where
    printText0 ga (Sig_items s) = printText0 ga s
    printText0 ga (Free_datatype l _) = 
	hang (ptext freeS <+> ptext typeS<>pluralS_doc l) 4 $ 
	     semiAnno_text ga l
    printText0 ga (Sort_gen l _) = 
	hang (ptext generatedS <+> condTypeS) 4 $ 
	     condBraces (vcat (map (printText0 ga) l))
	where condTypeS = 
		  if isOnlyDatatype then ptext typeS<>pluralS_doc l 
		  else empty
	      condBraces d = 
		  if isOnlyDatatype then 
		     case l of
		     [x] -> case x of
			    Annoted (Datatype_items l' _) _ lans _ -> 
				vcat (map (printText0 ga) lans) 
					 $$ semiAnno_text ga l'
			    _ -> error "wrong implementation of isOnlyDatatype"
                     _ -> error "wrong implementation of isOnlyDatatype"
		  else braces d
	      isOnlyDatatype = 
		  case l of
		  [x] -> case x of 
			 Annoted (Datatype_items _ _) _ _ _ -> True
			 _ -> False
		  _  -> False
    printText0 ga (Var_items l _) = 
	text varS<>pluralS_doc l <+> semiT_text ga l
    printText0 ga (Local_var_axioms l f p) = 
	text forallS <+> semiT_text ga l
		 $$ printText0 ga (Axiom_items f p)
    printText0 ga (Axiom_items f _) = 
	vcat $ map (printAnnotedFormula_Text0 ga) f

printAnnotedFormula_Text0 :: GlobalAnnos -> Annoted FORMULA -> Doc
printAnnotedFormula_Text0 ga (Annoted i _ las ras) =
	let i'   = char '.' <+> printText0 ga i
	    las' = if not $ null las then 
	               ptext "\n" <> printAnnotationList_Text0 ga las
		   else
		       empty
	    (la,ras') = splitAndPrintRAnnos printText0 
				    printAnnotationList_Text0 
				    (<+>)
				    (empty) ga ras
        in las' $+$ (hang i' 0 la) $$ ras'

instance PrettyPrint SIG_ITEMS where
    printText0 ga (Sort_items l _) =  
	text sortS<>pluralS_doc l <+> semiAnno_text ga l
    printText0 ga (Op_items l _) =  
	text opS<>pluralS_doc l <+> semiAnno_text ga l 
    printText0 ga (Pred_items l _) =  
	text predS<>pluralS_doc l <+> semiAnno_text ga l 
    printText0 ga (Datatype_items l _) = 
	text typeS<>pluralS_doc l <+> semiAnno_text ga l 

instance PrettyPrint SORT_ITEM where
    printText0 ga (Sort_decl l _) = commaT_text ga l
    printText0 ga (Subsort_decl l t _) = 
	hang (commaT_text ga l) 4 $ text lessS <+> printText0 ga t
    printText0 ga (Subsort_defn s v t f _) = 
	-- TODO: lannos of f should printed after the equal sign 
	printText0 ga s <+> ptext equalS <+> 
	   braces (hang (printText0 ga v <+> colon <+> printText0 ga t) 
		         4 (ptext "." <+> printText0 ga f))
    printText0 ga (Iso_decl l _) = 
	fsep $ punctuate  (space <>text equalS) $ map (printText0 ga) l


instance PrettyPrint OP_ITEM where
    printText0 ga (Op_decl l t a _) = 
	hang (hang (commaT_text ga l) 
	            4 
	            (colon <> printText0 ga t <> condComma)) 
             4 $
	       if na then empty 
	       else commaT_text ga a
	where na = null a
	      condComma = if na then empty
			  else comma
    printText0 ga (Op_defn n h t _) = printText0 ga n 
				  <> printText0 ga h
                                  <+> text equalS
				  <+> printText0 ga t

instance PrettyPrint OP_TYPE where
    printText0 ga (Total_op_type l s _) = (if null l then empty
					   else space 
					        <> crossT_text ga l 
				                <+> text funS)
				           <> space <> printText0 ga s
    printText0 ga (Partial_op_type l s _) = (if null l then text quMark 
					     else space 
                                                  <> crossT_text ga l 
					          <+> text (funS ++ quMark))
					    <+> printText0 ga s

instance PrettyPrint OP_HEAD where
    printText0 ga (Total_op_head l s _) = 
	(if null l then empty 
	 else parens(semiT_text ga l))
	<> colon
	<+> printText0 ga s
    printText0 ga (Partial_op_head l s _) = 
	(if null l then empty 
	 else parens(semiT_text ga l))
	<> text (colonS ++ quMark)
        <+> printText0 ga s

instance PrettyPrint ARG_DECL where
    printText0 ga (Arg_decl l s _) = commaT_text ga l 
			      <+> colon
			      <> printText0 ga s

instance PrettyPrint OP_ATTR where
    printText0 _ (Assoc_op_attr)   = text assocS
    printText0 _ (Comm_op_attr)    = text commS 
    printText0 _ (Idem_op_attr)    = text idemS
    printText0 ga (Unit_op_attr t) = text unitS <+> printText0 ga t

instance PrettyPrint PRED_ITEM where
    printText0 ga (Pred_decl l t _) = commaT_text ga l 
				  <+> colon <+> printText0 ga t
    printText0 ga (Pred_defn n h f _) = printText0 ga n 
				        <> printText0 ga h
                                        <+> text equivS
				        <+> printText0 ga f

instance PrettyPrint PRED_TYPE where
    printText0 _ (Pred_type [] _) = parens empty
    printText0 ga (Pred_type l _) = crossT_text ga l

instance PrettyPrint PRED_HEAD where
    printText0 ga (Pred_head l _) = parens (semiT_text ga l)

instance PrettyPrint DATATYPE_DECL where
    printText0 ga (Datatype_decl s a _) = 
	printText0 ga s <+> 
	sep ((hang (text defnS) 4 (printText0 ga $ head a)):
	     (map (\x -> nest 2 $ ptext barS <+> nest 2 (printText0 ga x)) $ 
		  tail a))

instance PrettyPrint ALTERNATIVE where
    printText0 ga (Total_construct n l _) = printText0 ga n 
				 <> if null l then empty 
				    else parens(semiT_text ga l)
    printText0 ga (Partial_construct n l _) = printText0 ga n 
				 <> parens(semiT_text ga l)
				 <> text quMark
    printText0 ga (Subsorts l _) = text sortS <+> commaT_text ga l 

instance PrettyPrint COMPONENTS where
    printText0 ga (Total_select l s _) = commaT_text ga l 
				<> colon 
				<> printText0 ga s 
    printText0 ga (Partial_select l s _) = commaT_text ga l 
				<> text (colonS ++ quMark) 
				<> printText0 ga s 
    printText0 ga (Sort s) = printText0 ga s 	  

instance PrettyPrint VAR_DECL where
    printText0 ga (Var_decl l s _) = commaT_text ga l 
				<> colon 
				<> printText0 ga s 

instance PrettyPrint FORMULA where
    printText0 ga (Quantification q l f _) = 
	hang (printText0 ga q <+> semiT_text ga l) 4 $ 
	     char '.' <+> printText0 ga f
    printText0 ga (Conjunction l _) = 
	sep $ prepPunctuate (ptext lAnd <> space) $ 
	    map (condParensXjunction printText0 parens ga) l
    printText0 ga (Disjunction  l _) = 
	sep $ prepPunctuate (ptext lOr <> space) $ 
	    map (condParensXjunction printText0 parens ga) l
    printText0 ga i@(Implication f g p) = 
	if if_detect f p 
	then (
        hang (condParensImplEquiv printText0 parens ga i g 
	      <+> ptext "if") 4 $ 
	     condParensImplEquiv printText0 parens ga i f)
	else (
        hang (condParensImplEquiv printText0 parens ga i f 
	      <+> ptext implS) 4 $ 
	     condParensImplEquiv printText0 parens ga i g)
    printText0 ga e@(Equivalence  f g _) = 
	hang (condParensImplEquiv printText0 parens ga e f 
	      <+> ptext equivS) 4 $
	     condParensImplEquiv printText0 parens ga e g
    printText0 ga (Negation f _) = ptext "not" <+> printText0 ga f
    printText0 _ (True_atom _)  = ptext trueS
    printText0 _ (False_atom _) = ptext falseS
    printText0 ga (Predication p l _) = 
	let (p_id,isQual) = 
		case p of
		       Pred_name i          -> (i,False)
		       Qual_pred_name i _ _ -> (i,True)
	    p' = printText0 ga p
	in if isQual then 
	     print_prefix_appl_text ga p' l  
	   else condPrint_Mixfix_text ga p_id l
    printText0 ga (Definedness f _) = text defS <+> printText0 ga f
    printText0 ga (Existl_equation f g _) = 
	hang (printText0 ga f <+> ptext exEqual) 4 $ printText0 ga g
    printText0 ga (Strong_equation f g _) = 
	hang (printText0 ga f <+> ptext equalS) 4 $ printText0 ga g 
    printText0 ga (Membership f g _) = 
	printText0 ga f <+> ptext inS <+> printText0 ga g
    printText0 ga (Mixfix_formula t) = printText0 ga t
    printText0 _ (Unparsed_formula s _) = text s 
    printText0 ga (Sort_gen_ax sorts ops) = 
	text generatedS <> braces (text sortS <+> commaT_text ga sorts 
				   <> semi <+> semiT_text ga ops) 

instance PrettyPrint QUANTIFIER where
    printText0 _ (Universal) = ptext forallS
    printText0 _ (Existential) = ptext existsS
    printText0 _ (Unique_existential) = ptext (existsS ++ exMark)

instance PrettyPrint PRED_SYMB where
    printText0 ga (Pred_name n) = printText0 ga n
    printText0 ga (Qual_pred_name n t _) = 
	parens $ ptext predS <+> printText0 ga n <+> colon <+> printText0 ga t

instance PrettyPrint TERM where
    printText0 ga (Simple_id i) = printText0 ga i
    printText0 ga (Qual_var n t _) = 
	parens $ text varS <+> printText0 ga n <+> colon <+> printText0 ga t
    printText0 ga (Application o l _) = 
	let (o_id,isQual) = 
		case o of
		       Op_name i          -> (i,False)
		       Qual_op_name i _ _ -> (i,True)
	    o' = printText0 ga o
	in if isQual then 
	     print_prefix_appl_text ga (parens o') l
	   else 
	     if isLiteral ga o_id l then
	       {-trace ("a literal application: " 
		      ++ show (Application o l [])) $ -}
		     print_Literal_text ga o_id l
	     else
	       condPrint_Mixfix_text ga o_id l
    printText0 ga (Sorted_term t s _) = 
	printText0 ga t	<+> colon <+> printText0 ga s
    printText0 ga (Cast  t s _) = 
	printText0 ga t <+> text asS <+> printText0 ga s
    printText0 ga(Conditional u f v _) = 
	hang (printText0 ga u) 4 $ 
	     sep ((text whenS <+> printText0 ga f):
		     [text elseS <+> printText0 ga v])
    printText0 _ (Unparsed_term s _) = text s
    printText0 ga (Mixfix_qual_pred p) = printText0 ga p
    printText0 ga (Mixfix_term l) = 
	cat(punctuate space (map (printText0 ga) l))
    printText0 ga (Mixfix_token t) = printText0 ga t
    printText0 ga (Mixfix_sorted_term s _) = colon
					     <> printText0 ga s
    printText0 ga (Mixfix_cast s _) = text asS
				     <+> printText0 ga s
    printText0 ga (Mixfix_parenthesized l _) = parens (commaT_text ga l)
    printText0 ga (Mixfix_bracketed l _) =   brackets (commaT_text ga l)
    printText0 ga (Mixfix_braced l _) =        braces (commaT_text ga l)

instance PrettyPrint OP_SYMB where
    printText0 ga (Op_name o) = printText0 ga o
    printText0 ga (Qual_op_name o t _) = 
	text opS <+> printText0 ga o <+> colon <> printText0 ga t

instance PrettyPrint SYMB_ITEMS where
    printText0 ga (Symb_items k l _) = 
	printText0 ga k <> ptext (pluralS_symb_list k l) 
		        <+> commaT_text ga l

instance PrettyPrint SYMB_ITEMS_LIST where
    printText0 ga (Symb_items_list l _) = commaT_text ga l

instance PrettyPrint SYMB_MAP_ITEMS where
    printText0 ga (Symb_map_items k l _) = 
	printText0 ga k <> ptext (pluralS_symb_list k l) 
		        <+> commaT_text ga l

instance PrettyPrint SYMB_MAP_ITEMS_LIST where 
    printText0 ga (Symb_map_items_list l _) = commaT_text ga l

instance PrettyPrint SYMB_KIND where 
    printText0 _ Implicit   = empty
    printText0 _ Sorts_kind = ptext sortS
    printText0 _ Ops_kind   = ptext opS
    printText0 _ Preds_kind = ptext predS

instance PrettyPrint SYMB where 
    printText0 ga (Symb_id i) = printText0 ga i
    printText0 ga (Qual_id i t _) = 
	printText0 ga i <+> colon <+> printText0 ga t

instance PrettyPrint TYPE where 
    printText0 ga (O_type t) = printText0 ga t
    printText0 ga (P_type t) = printText0 ga t
    printText0 ga (A_type t) = printText0 ga t

instance PrettyPrint SYMB_OR_MAP where 
    printText0 ga (Symb s) = printText0 ga s
    printText0 ga (Symb_map s t _) = 
	printText0 ga s <+> text mapsTo <+> printText0 ga t

---- helpers ----------------------------------------------------------------

pluralS_symb_list :: SYMB_KIND -> [a] -> String
pluralS_symb_list k l = case k of
		       Implicit -> ""
		       _        -> if length l > 1 
				   then "s" 
				   else ""

condPrint_Mixfix :: (Token -> Doc)
		 -> (Id -> Doc)
		 -> (TERM -> Doc)
		 -> (Doc -> Doc)    -- ^ a function that surrounds 
				    -- the given Doc with appropiate 
				    -- parens
		 -> (Doc -> Doc -> Doc) -- ^ a beside with space 
					-- like <+> or <\+>
		 -> ([Doc] -> Doc)    -- ^ a list concat with space and 
				      -- fill the line policy  like
				      -- fsep or fsep_latex
		 -> Doc -- comma doc
		 -> Maybe (Token -> Doc) -- ^ this function should be 
					 -- given to print a Token in a 
					 -- special way 
		 -> (Maybe Display_format)
		 ->  GlobalAnnos -> Id -> [TERM] -> Doc
condPrint_Mixfix pTok pId pTrm parens_fun
		 beside_fun fsep_fun comma_doc mpt_fun mdf
		 ga i l =
    if isMixfix i then
       if length (filter isPlace tops) == length l then
	  print_mixfix_appl pTok pId pTrm parens_fun 
			    beside_fun fsep_fun mpt_fun mdf ga i l 
       else 
          print_prefix_appl pTrm parens_fun fsep_fun comma_doc o' l
    else print_prefix_appl pTrm parens_fun fsep_fun comma_doc o' l
    where tops = case i of Id tp _ _ -> tp 
	  o' = pId i
{- TODO: consider string-, number-, list- and floating-annotations -}

condPrint_Mixfix_text :: GlobalAnnos -> Id -> [TERM] -> Doc
condPrint_Mixfix_text ga =
    condPrint_Mixfix (printText0 ga) (printText0 ga) 
		  (printText0 ga) parens 
		     (<+>) fsep comma Nothing Nothing ga

-- printing consitent mixfix application or predication
{- TODO: consider string-, number-, list- and floating-annotations -}
print_mixfix_appl :: (Token -> Doc)  -- ^ print a Token
		  -> (Id -> Doc)     -- ^ print an Id
		  -> (TERM -> Doc)   -- ^ print TERM recursively 	 
		  -> (Doc -> Doc)   -- ^ a function that surrounds 
				     -- the given Doc with appropiate 
				     -- parens
		  -> (Doc -> Doc -> Doc)    -- ^ a beside with space 
					    -- like <+> or <\+>
		  -> ([Doc] -> Doc)    -- ^ a list concat with space and 
				       -- fill the line policy  like
				       -- fsep or fsep_latex
		  -> Maybe (Token -> Doc) -- ^ this function should be 
					  -- given to print a Token in a 
					  -- special way if Nothing is given
					  -- pf is used
		  -> Maybe Display_format
		  -> GlobalAnnos -> Id -> [TERM] -> Doc
print_mixfix_appl pTok pId pTrm parens_fun 
		  beside_fun fsep_fun 
		  mpt_fun mdf
		  ga oid terms = 
		      d_terms_b_comp <> c `beside_fun` d_terms_a_comp
    where (tops,cs) = maybe (case oid of Id x1 x2 _ -> (x1,x2))
		            (\x -> (x,[]))
			    md_tops
	  md_tops = maybe Nothing (\x -> lookupDisplay ga x oid) mdf
	  c = if null cs then text "" -- an empty String works for ASCII 
				      -- and LaTeX ensuring a space after 
				      -- the last token of the identifier 
				      -- if the compound is empty
	      else pId (Id [] cs [])
          (tps_b_comp,places) = splitMixToken tops
	  nr_places = length $ filter isPlace tps_b_comp
	  (terms_b_comp,terms_a_comp) = splitAt nr_places terms
	  d_terms_b_comp = fsep_fun (first_term 
				     : fillIn tps_b_comp' terms_b_comp')
	  d_terms_a_comp = fsep_fun (fillIn places' terms_a_comp'
				     ++ [last_term])
	  tps_b_comp' :: [Token]
	  terms_b_comp' :: [TERM]
	  first_term    :: Doc
	  (tps_b_comp',terms_b_comp',first_term) = 
	      if null tps_b_comp then -- invisible Id 
		([], terms_b_comp, empty) 
	      else if (isPlace $ head tps_b_comp) 
	      then
	         (tail tps_b_comp,
		  tail terms_b_comp,
		  condParensAppl pTrm parens_fun 
		                 ga oid (head terms_b_comp)
		                 (Just ALeft))
	      else
	         (tps_b_comp,terms_b_comp,empty)
	  (places',terms_a_comp',last_term) = 
	      if (not $ null places)  
	      then
	         (init places,init terms_a_comp,
		  condParensAppl pTrm parens_fun
		                 ga oid (last terms_a_comp) 
		                 (Just ARight))
	      else
	         (places,terms_a_comp,empty)
	  fillIn :: [Token] -> [TERM] -> [Doc]
	  fillIn tps ts = let (_,nl) = mapAccumL pr ts tps in nl
	  pr :: [TERM] -> Token -> ([TERM],Doc)
	  pr [] top = ([], pf' top)
	  pr tS@(t:ts) top 
	      | isPlace top = (ts, pTrm t)
	      | otherwise   = (tS,pf' top)	  
	  pf' = maybe pTok (\ f -> maybe pTok (\ _ -> f) md_tops) mpt_fun

-- printing consistent prefix application and predication
print_prefix_appl :: (TERM -> Doc)   -- ^ print TERM recursively 
		  -> (Doc -> Doc)    -- ^ a function that surrounds 
				     -- the given Doc with appropiate 
				     -- parens
	          -> ([Doc] -> Doc)    -- ^ a list concat without space and 
				   -- fill the line policy  like
				   -- fsep or fsep_latex
		  -> Doc -- comma
		  -> Doc -> [TERM] -> Doc 
print_prefix_appl pTrm parens_fun fsep_fun comma_doc po' l = po' <> 
            (if null l then empty 
	     else parens_fun $ fsep_fun $ punctuate comma_doc $ map pTrm l)

print_prefix_appl_text :: GlobalAnnos -> Doc -> [TERM] -> Doc
print_prefix_appl_text ga =
    print_prefix_appl (printText0 ga) parens fsep comma

print_Literal :: (Token -> Doc)  -- ^ print a Token
              -> (Id -> Doc)     -- ^ print an Id
	      -> (TERM -> Doc)   -- ^ print TERM recursively 	 
	      -> (Doc -> Doc)    -- ^ a function that surrounds 
				 -- the given Doc with appropiate 
				 -- parens
	      -> (Doc -> Doc -> Doc)    -- ^ a beside with space 
					-- like <+> or <\+>
	      -> ([Doc] -> Doc)    -- ^ a list concat without space and 
				   -- fill the line policy  like
				   -- fsep or fsep_latex
	      -> Doc   -- ^ a comma 
	      -> Doc   -- ^ a document containing the dot for a Fraction
	      -> Doc   -- ^ a document containing the 'E' of a Floating
	      -> Maybe (Token -> Doc) -- ^ this function should be 
				      -- given to print a Token in a 
				      -- special way 
	      -> (Maybe Display_format)
	      -> GlobalAnnos -> Id -> [TERM] -> Doc
print_Literal pTok pId pTrm parens_fun 
	      beside_fun fsep_fun comma_doc dot_doc e_doc mpt_fun mdf
	      ga li ts 
    | isSignedNumber ga li ts = let [t_ts] = ts
				in pId li <> 
				       ((uncurry p_l) (splitAppl t_ts))
    | isNumber ga li ts = pTok $ tokNumber li
    | isFrac   ga li ts = let [lt,rt] = ts
			      (lni,lnt) = splitAppl lt
			      (rni,rnt) = splitAppl rt
			      ln = p_l lni lnt
			      rn = p_l rni rnt
			  in ln <> dot_doc <> rn
    | isFloat  ga li ts = let [bas,ex] = ts
			      (bas_i,bas_t) = splitAppl bas
			      (ex_i,ex_t)   = splitAppl ex
			      bas_d = p_l bas_i bas_t
			      ex_d  = p_l ex_i ex_t
			  in bas_d <> e_doc <> ex_d
    | isList   ga li ts = let list_body = fsep_fun $ punctuate comma_doc 
					  $ map pTrm $ listElements li
			      (openL, closeL, comps) = getListBrackets $ 
						       listBrackets li
 			  in hcat(map pTok openL) <+> list_body 
			     <+> hcat(map pTok closeL)
			     <> pId (Id [] comps [])
    | isString ga li ts = ptext $ 
			  (\s -> let r = '"':(s ++ "\"") in seq r r) $ 
			  concatMap convCASLChar $ toksString li
    | otherwise = condPrint_Mixfix pTok pId pTrm parens_fun 
		                   beside_fun fsep_fun comma_doc mpt_fun mdf
				   ga li ts
    where p_l = print_Literal pTok pId pTrm parens_fun 
	      beside_fun fsep_fun comma_doc dot_doc e_doc mpt_fun mdf
	      ga
	  tokNumber i   = if tokIsDigit then
			     tok
			   else
			    {-trace ("Number: "++show ts) $ -}
			     mergeTok $ map (termToTok "number") $
			         collectElements (Nothing) i ts
	     where tok = case i of
			 Id []     _ _ -> error "malformed Id!!!"
			 Id (x:_) _ _ -> x 
		   tokIsDigit = (isDigit $ head $ tokStr $ tok) && null ts
	  toksString i   = case getLiteralType ga i of 
			   StringNull -> []
			   StringCons n -> map (termToTok "string") $ 
				   collectElements (Just n) i ts
			   _ -> error "toksString"
	  termToTok tokType x = case basicTerm x of
				Just tokk -> tokk
				Nothing   -> error ("malformed " ++ tokType)
	  listElements i = case getLiteralType ga i of
			   ListNull _ -> []
			   ListCons _ n -> collectElements (Just n) i ts
			   _ -> error "listElements"
	  listBrackets i = case getLiteralType ga i of
			   ListNull b -> b
			   ListCons b _ -> b
			   _ -> error "listBrackets"

mergeTok :: [Token] -> Token
mergeTok ts 
    | not (null ts) = foldr merge initTok ts
    | otherwise = error "mergeTok: wrong call with empty list" 
    where initTok = Token {tokStr="",tokPos = tokPos (head ts)}
	  merge tok newTok = newTok {tokStr = tokStr tok ++ tokStr newTok} 

print_Literal_text :: GlobalAnnos -> Id -> [TERM] -> Doc
print_Literal_text ga =
    print_Literal (printText0 ga) (printText0 ga) (printText0 ga) 
         parens (<+>) fsep comma  (char '.') (char 'E') Nothing Nothing ga

condParensAppl :: (TERM -> Doc)
	       -> (Doc -> Doc)    -- ^ a function that surrounds 
				  -- the given Doc with appropiate 
				  -- parens
	       -> GlobalAnnos -> Id -> TERM -> Maybe AssocEither -> Doc
condParensAppl pf parens_fun ga o_i t mdir = 
    case t of
    Simple_id _ -> t'
    Application _ [] _ -> t'
    Application o it _
	| isLiteral ga i_i it -> t'
        -- ordinary appl (no place)
	| isOrdAppl i_i -> t' 
	-- postfix appl
	| isOrdAppl o_i && isPostfix i_i -> t' 
	-- prefix appl w/o parens
	| isOrdAppl o_i && isPrefix  i_i -> t'
	-- both mixfix and in <> prec relation so parens
	| isMixfix o_i && isMixfix i_i 
	  && explicitGrouping o_i i_i    -> parens_fun t'
	| isPostfix o_i && isPrefix  i_i -> parens_fun t'
	| isPrefix  o_i && isPostfix i_i -> t'
	| isPrefix  o_i && isInfix   i_i -> parens_fun t'
	| isInfix   o_i && isPrefix  i_i -> t'
	| isInfix   o_i && isPostfix i_i -> t'
	-- infix appl (left and right arg/place)
	|    (isInfix i_i && isSurround o_i)
	  || (isInfix o_i && isSurround i_i) -> t'
	| isInfix i_i && o_i == i_i -> 
	    case mdir of
		      Nothing -> condParensPrec 
		      Just ass | isAssoc ass amap o_i -> t'
			       | otherwise -> parens_fun t'
	| otherwise -> condParensPrec 
    	where i_i = case o of
			  Op_name i          -> i
			  Qual_op_name i _ _ -> i
	      condParensPrec = case precRel (prec_annos ga) o_i i_i of
			       Lower -> t'
			       _     -> parens_fun t'
	      amap = assoc_annos ga
	      explicitGrouping :: Id -> Id -> Bool
	      explicitGrouping i1 i2 = 
		  case precRel (prec_annos ga) i1 i2 of
		  BothDirections -> True
		  _              -> False
    Sorted_term _ _ _ -> t'
    Cast _ _ _ -> t'
    _ -> parens_fun t'
    where t' = pf t


condParensImplEquiv :: (GlobalAnnos -> FORMULA -> Doc)
		    -> (Doc -> Doc)    -- ^ a function that surrounds 
				       -- the given Doc with appropiate 
				       -- parens
		    -> GlobalAnnos -> FORMULA -> FORMULA -> Doc
condParensImplEquiv pf parens_fun ga e_i f =  
    case e_i of 
    Implication _ _ _ -> case f of Implication _ _ _ -> f'
				   Disjunction _ _ -> f'
				   Conjunction _ _ -> f'
				   Negation _ _ -> f' 
				   True_atom _  -> f' 
				   False_atom _ -> f'
				   Predication _ _ _ -> f' 
				   Existl_equation _ _ _ -> f'
				   Definedness _ _ -> f'
				   Strong_equation _ _ _ -> f'		   
				   _           -> parens_fun f'
    Equivalence _ _ _ -> case f of Disjunction _ _ -> f'
				   Conjunction _ _ -> f'
				   Negation _ _ -> f' 
				   True_atom _  -> f' 
				   False_atom _ -> f'
				   Predication _ _ _ -> f'
				   Quantification _ _ _ _ -> f'
				   Existl_equation _ _ _ -> f'
				   Strong_equation _ _ _ -> f'
				   Definedness _ _ -> f'
				   _           -> parens_fun f'
    _ ->  error "Wrong call: condParensImplEquiv"
    where f' = pf ga f
condParensXjunction :: (GlobalAnnos -> FORMULA -> Doc)
		    -> (Doc -> Doc)    -- ^ a function that surrounds 
				       -- the given Doc with appropiate 
				       -- parens
		    -> GlobalAnnos -> FORMULA -> Doc
condParensXjunction pf parens_fun ga x = 
    case x of Negation _ _ -> x' 
	      True_atom _  -> x' 
	      False_atom _ -> x'
	      Predication _ _ _ -> x'
	      Existl_equation _ _ _ -> x'
	      Strong_equation _ _ _ -> x'
	      Definedness _ _ -> x'
	      _            -> parens_fun x' 
    where x' = pf ga x

left_most_pos :: FORMULA -> Pos
left_most_pos f = 
    case f of
    Quantification _ _ _ pl -> headPos pl 
    Conjunction _ pl   -> headPos pl 
    Disjunction _ pl   -> headPos pl 
    Implication _ _ pl -> headPos pl 
    Equivalence _ _ pl -> headPos pl 
    Negation _ pl -> headPos pl 
    True_atom pl -> headPos pl 
    False_atom pl -> headPos pl 
    Predication pre _ pl -> 
	let p = headPos pl
	    p' = posOfId (case pre of
			  Pred_name i          -> i
			  Qual_pred_name i _ _ -> i)
	in if isNullPos p 
	   then p'
	   else p	       
    Definedness _ pl -> headPos pl 
    Existl_equation _ _ pl -> headPos pl 
    Strong_equation _ _ pl -> headPos pl 
    Membership _ _ pl -> headPos pl 
    Unparsed_formula _ pl -> headPos pl 
    Mixfix_formula t -> getMyPos t
    Sort_gen_ax sorts _ -> firstPos sorts []

if_detect :: FORMULA -> [Pos] -> Bool
if_detect _ []    = False
if_detect f (p_impl:_) = 
        (line p_impl, column p_impl) < (line p_form, column p_form)
    where p_form = left_most_pos f
          line   = sourceLine
	  column = sourceColumn

---- instances of ListCheck for various data types of AS_Basic_CASL ---
instance ListCheck SIG_ITEMS where
    (Sort_items l _)     `innerListGT` i = length l > i
    (Op_items l _)       `innerListGT` i = length l > i
    (Pred_items l _)     `innerListGT` i = length l > i
    (Datatype_items l _) `innerListGT` i = length l > i

instance ListCheck SORT_ITEM where
    (Sort_decl l _)          `innerListGT` i = length l > i
    (Subsort_decl l _ _)     `innerListGT` i = length l > i
    (Subsort_defn _ _ _ _ _) `innerListGT` _ = False
    (Iso_decl _ _)           `innerListGT` _ = False

instance ListCheck OP_ITEM where
    (Op_decl l _ _ _) `innerListGT` i = length l > i
    (Op_defn _ _ _ _) `innerListGT` _ = False

instance ListCheck PRED_ITEM where
    (Pred_decl l _ _)   `innerListGT` i = length l > i
    (Pred_defn _ _ _ _) `innerListGT` _ = False

instance ListCheck DATATYPE_DECL where
    (Datatype_decl _ _ _) `innerListGT` _ = False

instance ListCheck VAR_DECL where
    (Var_decl l _ _) `innerListGT` i = length l > i

-----------------------------------------------------------------------------
