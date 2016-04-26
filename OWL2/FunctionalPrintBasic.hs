{- |
Module      :  $Header$
Copyright   :  (c) Till Mossakowski, University of Magdeburg, 2016
License     :  GPLv2 or higher, see LICENSE.txt

Maintainer  :  Christian.Maeder@dfki.de
Stability   :  provisional
Portability :  portable

Pretty printing for the functional-style syntax of OWL 2.
-}

module OWL2.FunctionalPrintBasic where

import Common.Doc
import Common.DocUtils
import Common.Id
import Common.Keywords

import OWL2.AS
import OWL2.MS
import OWL2.Symbols
import OWL2.Keywords
import OWL2.ColonKeywords

import Data.List

import Debug.Trace

printCharacter :: Character -> Doc
printCharacter = printCharact . (++ "ObjectProperty") . show

printCharact :: String -> Doc
printCharact = text

printIRIWithColon :: QName -> Doc
printIRIWithColon q = 
 if namePrefix q == "" then text ":" <> printIRI q 
   else printIRI q 

printIRI :: QName -> Doc
printIRI q = text $ showQN q

printDataIRI :: QName -> Doc
printDataIRI q = if isDatatypeKey q then text $ showQN $ setDatatypePrefix q
 else printIRI q

-- | Symbols printing

printExtEntityType :: ExtEntityType -> Doc
printExtEntityType ety = case ety of
        AnyEntity -> empty
        EntityType ty -> keyword $ show ty
        PrefixO -> keyword "Prefix"

printSymbItems :: SymbItems -> Doc
printSymbItems (SymbItems m us) = printExtEntityType m
        <+> ppWithCommas2 printIRI us

printSymbMapItems :: SymbMapItems -> Doc
printSymbMapItems (SymbMapItems m us) = printExtEntityType m
        <+> sepByCommas
            (map (\ (s, ms) -> sep
                [ printIRI s
                , case ms of
                    Nothing -> empty
                    Just t -> mapsto <+> printIRI t]) us)

--instance GetRange RawSymb -- no position by default

{-instance Pretty RawSymb where
    pretty rs = case rs of
        ASymbol e -> pretty e
        AnUri u -> pretty u
        APrefix p -> pretty p
-}

cardinalityType :: CardinalityType -> Doc
cardinalityType MinCardinality = keyword "ObjectMinCardinality"
cardinalityType MaxCardinality = keyword "ObjectMaxCardinality"
cardinalityType ExactCardinality = keyword "ObjectExactCardinality"

quantifierType :: Bool -> QuantifierType -> Doc
quantifierType b AllValuesFrom = if b then keyword "DataAllValuesFrom" else keyword "ObjectAllValuesFrom"
quantifierType b SomeValuesFrom = if b then keyword "DataSomeValuesFrom" else keyword "ObjectSomeValuesFrom"

showRelationF :: Bool -> Relation -> String
showRelationF b r = case r of
    EDRelation ed -> showEquivOrDisjointF ed
    SubPropertyOf -> if b then "SubDataPropertyOf" else "SubObjectPropertyOf" 
    InverseOf -> "InverseObjectProperties"
    SubClass -> "SubClassOf"
    Types -> "ClassAssertion"
    DRRelation dr -> showDomainOrRangeF b dr
    SDRelation sd -> showSameOrDifferentF sd

showEquivOrDisjointF :: EquivOrDisjoint -> String
showEquivOrDisjointF ed = case ed of
    Equivalent -> "EquivalentClasses"
    Disjoint -> "DisjointClasses"

showDomainOrRangeF :: Bool -> DomainOrRange-> String
showDomainOrRangeF b dr = case dr of
    ADomain -> if b then "DataPropertyDomain" else "ObjectPropertyDomain" 
    ARange -> "ObjectPropertyRange"

showSameOrDifferentF :: SameOrDifferent -> String
showSameOrDifferentF sd = case sd of
    Same -> "SameIndividual"
    Different -> "DifferentIndividuals"

printRelation :: Bool -> Relation -> Doc
printRelation b = keyword . (showRelationF b) 


printEquivOrDisjointClasses :: EquivOrDisjoint -> Doc
printEquivOrDisjointClasses x = case x of
    Equivalent -> text "EquivalentClasses"
    Disjoint -> text "DisjointClasses"

printEquivOrDisjointProp :: EquivOrDisjoint -> Doc
printEquivOrDisjointProp e = case e of
    Disjoint -> text "DisjointProperties"
    Equivalent -> text "EquivalentProperties"

printPositiveOrNegative :: PositiveOrNegative -> Doc
printPositiveOrNegative x = case x of
    Positive -> empty
    Negative -> keyword notS

printSameOrDifferentInd :: SameOrDifferent -> Doc
printSameOrDifferentInd x = case x of
    Same -> keyword "SameIndividual"
    Different -> keyword "DifferentIndividuals"

printEntity :: Entity -> Doc 
printEntity (Entity _ ty e) = keyword (show ty) <+> printIRI e

printLiteral :: Literal -> Doc 
printLiteral lit = case lit of
        Literal lexi ty -> let
          escapeDQ c s = case s of
            "" -> ""
            h : t -> case h of
              '\\' -> h : escapeDQ (c + 1 :: Int) t
              _ | odd c || h /= '"' -> h : escapeDQ 0 t
              _ -> '\\' : h : escapeDQ 0 t
          in plainText ('"' : escapeDQ 0 lexi ++ "\"") <> case ty of
            Typed u -> keyword cTypeS <> printDataIRI u
            Untyped tag -> case tag of
              Nothing -> empty
              Just tag2 -> text asP <> text tag2
        NumberLit f -> text (show f)

printObjPropExp :: ObjectPropertyExpression -> Doc
printObjPropExp obExp = case obExp of
    ObjectProp ou -> printIRIWithColon ou
    ObjectInverseOf iopExp -> keyword inverseS <+> printObjPropExp iopExp

printFV :: (ConstrainingFacet, RestrictionValue) -> Doc
printFV (facet, restValue) = pretty (fromCF facet) <+> printLiteral restValue

fromCF :: ConstrainingFacet -> String
fromCF (QN "xsd" ">=" _ _ _) = "xsd:maxInclusive"
fromCF (QN "xsd" "<=" _ _ _) = "xsd:minInclusive" -- TODO: improve or add all other xsd defaults
fromCF f
    | iriType f == Full = showQU f \\ "http://www.w3.org/2001/XMLSchema#"
    | otherwise = localPart f

printDatatypeFacet :: DatatypeFacet -> Doc
printDatatypeFacet = keyword . showFacet

printDataRange :: DataRange -> Doc
printDataRange dr = case dr of
    DataType dtype l ->
      if null l then printIRIWithColon dtype 
      else text "DatatypeRestriction" <> parens (printIRIWithColon dtype <+> ppWithSpaces2 printFV l)
    DataComplementOf drange -> keyword "DataComplementOf" <> parens (printDataRange drange)
    DataOneOf constList -> keyword "DataOneOf" <> parens (ppWithSpaces2 printLiteral constList)
    DataJunction ty drlist -> let
      k = case ty of
          UnionOf -> text "DataUnionOf"
          IntersectionOf -> text "DataIntersectionOf"
      in  k <> parens (ppWithSpaces2 printDataRange drlist)

-- | Printing the ClassExpression
printClassExpression :: ClassExpression -> Doc
printClassExpression desc = case desc of
   Expression ocUri -> printIRIWithColon ocUri
   ObjectJunction ty ds -> let
      (k, p) = case ty of
          UnionOf -> ("ObjectUnionOf", printClassExpression)
          IntersectionOf -> ("ObjectIntersectionOf", printClassExpression)
      in text k <> parens (fsep $ prepPunctuate space $ map p ds)
   ObjectComplementOf d -> keyword "ObjectComplementOf" <> (parens $ printClassExpression d)
   ObjectOneOf indUriList -> keyword "ObjectOneOf" <> (parens $ ppWithSpaces2 printIRIWithColon indUriList)
   ObjectValuesFrom ty opExp d ->
      quantifierType False ty <> parens (printObjPropExp opExp <+> printClassExpression d)
   ObjectHasSelf opExp ->
      printObjPropExp opExp <+> keyword selfS
   ObjectHasValue opExp indUri ->
      keyword "ObjectHasValue" <> parens (printObjPropExp opExp <+> printIRI indUri)
   ObjectCardinality (Cardinality ty card opExp maybeDesc) ->
      cardinalityType ty 
       <> parens (text (show card) <+> printObjPropExp opExp 
                  <+> maybe empty printPrimary maybeDesc)
   DataValuesFrom ty dpExp dRange -> trace (show dRange) $ 
       quantifierType True ty <> parens( printIRIWithColon dpExp
        <+> printDataRange dRange)
   DataHasValue dpExp cons -> text "ObjectHasValue" <> parens (printIRIWithColon dpExp <+> printLiteral cons)
   DataCardinality (Cardinality ty card dpExp maybeRange) ->
        cardinalityType ty <> parens(printIRIWithColon dpExp <+> text (show card)
         <+> maybe empty printDataRange maybeRange)

printPrimary :: ClassExpression -> Doc
printPrimary d = let dd = printClassExpression d in case d of
  ObjectJunction {} -> parens dd
  _ -> dd

printNegatedPrimary :: ClassExpression -> Doc
printNegatedPrimary d = let r = parens $ printClassExpression d in case d of
  ObjectComplementOf _ -> r
  ObjectValuesFrom {} -> r
  DataValuesFrom {} -> r
  ObjectHasValue {} -> r
  DataHasValue {} -> r
  _ -> printPrimary d

-- | annotations printing
printAnnotationValue :: AnnotationValue -> Doc
printAnnotationValue x = case x of
        AnnValue iri -> printIRI iri
        AnnValLit lit -> printLiteral lit

printAnnotation :: OWL2.AS.Annotation -> Doc
printAnnotation (Annotation ans ap av) =
    sep [printAnnotations ans, sep [printIRI ap, printAnnotationValue av]]

printAnnotations :: Annotations -> Doc
printAnnotations l = case l of
    _ -> empty -- restore annos!
    _ -> keyword annotationsC <+>
          vcat (punctuate comma (map (\ (Annotation ans ap av) ->
            printAnnotations ans $+$ printAnnotation (Annotation [] ap av)) l) )

printAnnotatedList :: Pretty a => AnnotatedList a -> Doc
printAnnotatedList l =
    vcat $  map
        ( \ (ans, a) -> printAnnotations ans $+$ pretty a) l

printAnnotatedList2 :: (a -> Doc) -> AnnotatedList a -> Doc
printAnnotatedList2 g l =
    vcat $  map
        ( \ (ans, a) -> printAnnotations ans $+$ g a) l
