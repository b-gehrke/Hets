{-
the following code is automatically generated
-}
module <LogicName>.Logic_<LogicName> where

import Logic.Logic -- Logic and accompanying classes

import qualified <LogicName>.Sign as Sign
import qualified <LogicName>.Morphism as Morphism
import qualified <LogicName>.AS_BASIC_<LogicName> as AS
--import qualified <LogicName>.Tools as Tools
import qualified Generic.Tools as Generic
--import qualified <LogicName>.Sublogic as SL



-- Logic ID     lid
data <LogicName> = <LogicName> deriving Show

{-
-- language
instance Language <LogicName> where 
    description _ = "This is some logic generated by MMT\n"

-- instance of category
instance Category Sign.Sigs Morphism.Morphism where
--TODO place Morphism functions here

instance Sentences <LogicName> Form Sign.Sigs Morphism.Morphism AS.Symbol where
--TODO

-}

-- Logic instance, see Logic/Logic.hs:867
instance Logic <LogicName> 
    ()	--  SL.Sublogic -- sublogic
    () -- basic_spec
    AS.Form 
    ()  -- symb_items
    () -- symb_map_items
    Sign.Sigs -- sign
    Morphism.Morphism  -- sentence
    () -- symbol
    () -- raw symbol
    Generic.Tree -- proof tree
    where
    {-    
 logic_name = show 
 id lid = Morphism.id
 comp lid = Morphism.comp
 parse_basic_spec lid = Generic.parseSpec
 map_sen lid = Morphism.mapSen
 basic_analysis lid = Tools.theo_from_pt
 stat_symb_map lid = Tools.mor_from_pt
 minSublogic lid = SL.minSublogic
-}
-- static analysis is performed by MMT