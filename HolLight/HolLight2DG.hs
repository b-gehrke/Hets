{- |
Module      :  $Header$
Description :  Import data generated by hol2hets into a DG
Copyright   :  (c) Jonathan von Schroeder, DFKI GmbH 2010
License     :  GPLv2 or higher, see LICENSE.txt

Maintainer  :  jonathan.von_schroeder@dfki.de
Stability   :  experimental
Portability :  portable

-}

module HolLight.HolLight2DG where

import Static.GTheory
import Static.DevGraph

import Static.DgUtils
import Static.History
import Static.ComputeTheory

import Logic.Logic
import Logic.Prover
import Logic.ExtSign
import Logic.Grothendieck

import Common.LibName
import Common.Id
import Common.AS_Annotation
import Common.Result
import Common.Utils (getTempFile, getEnvDef)

import HolLight.Sign
import HolLight.Sentence
import HolLight.Term
import HolLight.Logic_HolLight

import HolLight.Helper (names)

import Driver.Options

import Data.Graph.Inductive.Graph
import qualified Data.Map as Map
import qualified Data.Char
import Data.Maybe (fromJust,isJust)

import Control.Monad
import Control.Monad.Maybe
import Control.Monad.State

import System.Exit
import System.FilePath.Posix
import System.Directory (removeFile, canonicalizePath, doesFileExist)
import System.Process
import Control.Concurrent (forkIO)
import System.IO (hPutStr, hGetContents)

import Text.XML.Expat.SAX
import qualified Data.ByteString.Lazy as L

foldCatchLeft :: Monad m => (a -> MaybeT m a) -> a -> MaybeT m a
foldCatchLeft fn def =
 do
  MaybeT $ do
   v <- runMaybeT $ fn def
   case v of
    Just res -> do
     v1 <- runMaybeT $ foldCatchLeft fn res
     case v1 of
      Just _ -> return v1
      Nothing -> return v
    _ -> return (Just def)

whileM :: Monad m => MaybeT m a -> MaybeT m [a]
whileM fn = foldCatchLeft (\l ->
 do
  v <- fn
  return $ l++[v]) []

-- Strip whitespaces from the beginning and the end of s
trim :: String -> String
trim s = let rem_rev = \x -> reverse $ dropWhile Data.Char.isSpace x
         in rem_rev $ rem_rev s

type SaxEvL      = [SAXEvent String String]
type MSaxState a = MaybeT (State (SaxEvL,Maybe [String])) a

debugC :: Bool
debugC = False

debugS' :: String -> State (SaxEvL,Maybe [String]) (Maybe a)
debugS' s = do
 if debugC then
  do
   (evl,dbg) <- get
   case dbg of
    Just msg -> do
     put (evl,Just $ s:msg)
     return Nothing
    Nothing -> do
     put (evl, Just [s])
     return Nothing
 else return Nothing

debugS :: String -> MSaxState a
debugS s = do
 if debugC then
  do
   (evl,dbg) <- get
   case dbg of
    Just msg -> put (evl,Just $ s:msg)
    Nothing -> put (evl, Just [s])
 else fail s
 fail s

runMSaxState :: MSaxState a -> SaxEvL -> (Maybe a, (SaxEvL,Maybe [String]))
runMSaxState f evl = runState (runMaybeT f) (evl,Nothing)

parsexml :: L.ByteString -> SaxEvL
parsexml = parse defaultParseOptions

is_space :: String -> Bool
is_space = all Data.Char.isSpace

dropSpaces :: MSaxState ()
dropSpaces = do
 (evl,dbg) <- get
 put $ (dropWhile
  (\ e ->
     case e of
      (CharacterData d) -> is_space d
      _ -> False
  ) evl,dbg)

tag :: MSaxState (Bool,String)
tag = do
 dropSpaces
 (d,dbg) <- get
 case d of
  StartElement s _ : xs	-> do
   put (xs,dbg)
   return (True, s)
  EndElement   s   : xs	-> do
   put (xs,dbg)
   return (False,s)
  _ -> debugS $ "Expected a tag - instead got: " ++ (show (head d))

expectTag :: Bool -> String -> MSaxState String
expectTag st s = do
 d <- get
 MaybeT $ do
  v <- runMaybeT tag
  case v of
   Just (b,t) -> if s /= t || st /= b
                 then do
                  put d
                  debugS' $ "Expected tag " ++ (show (st,s))
                           ++ " but instead got: " ++ (show (b,t))
                 else return $ Just s
   Nothing    -> do
    put d
    debugS' $ "Expected a tag, but didn't find one - see previous message!"

readWithTag :: MSaxState a -> String -> MSaxState a
readWithTag fn tagName = do
 expectTag True tagName
 d <- fn
 expectTag False tagName
 return d

readL :: Show a => MSaxState a -> String -> MSaxState [a]
readL fn = readWithTag (whileM fn)
 
foldS :: Show a => (a -> MSaxState a) -> a -> String -> MSaxState a
foldS fn def = readWithTag (foldCatchLeft fn def)

readTuple :: (Show a,Show b) => MSaxState a -> MSaxState b -> MSaxState (a,b)
readTuple f1 f2 = do
 expectTag True "tuple"
 t1 <- readWithTag f1 "fst"
 t2 <- readWithTag f2 "snd"
 expectTag False "tuple"
 return (t1,t2)

readWord :: MSaxState String
readWord = foldCatchLeft (\s ->
 do
  s' <- do
   dropSpaces
   (d,dbg) <- get
   case d of
    CharacterData s' : xs -> do
     put (xs,dbg)
     return s'
    _ -> debugS $ "Expected character data but instead got: "
                  ++ (show (head d))
  return $ s++(trim s')) []

readStr :: MSaxState String
readStr = readWithTag readWord "s"

readInt :: MSaxState Int
readInt = do
 w <- readWord
 return (read w :: Int)

readInt' :: MSaxState Int
readInt' = readWithTag readInt "i"

readMappedInt :: Map.Map Int a -> MSaxState a
readMappedInt m = do
 i <- readInt
 case Map.lookup i m of
  Just a -> return a
  _ -> debugS $ "readMappedInt: Integer " ++ (show i)
                ++ " not mapped"

listToTypes :: Map.Map Int HolType -> [Int] -> Maybe [HolType]
listToTypes m l = case l of
 x : xs -> case Map.lookup x m of
  Just t -> case listToTypes m xs of
   Just ts -> Just (t : ts)
   _ -> Nothing
  _ -> Nothing
 [] -> Just []

readSharedHolType :: Map.Map Int String -> Map.Map Int HolType
                      -> MSaxState (Map.Map Int HolType)
readSharedHolType sl m = do
 d <- get
 (b,t) <- tag
 case (b,t) of
  (True,"TyApp") -> do
   (i,l) <- readTuple readInt (whileM readInt')
   case (Map.lookup i sl,listToTypes m l) of
    (Just s,Just l') -> do
     expectTag False "TyApp"
     return $ Map.insert ((Map.size m)+1) (TyApp s $ reverse l') m
    (r1,r2) -> debugS $ "readSharedHolType: Couldn't build TyApp"
                        ++ " because the result of the lookup for "
                        ++ (show (i,l)) ++ " was " ++ (show (r1,r2))
  (True,"TyVar") -> do
   i <- readInt
   case Map.lookup i sl of
    Just s -> do
     expectTag False "TyVar"
     return $ Map.insert ((Map.size m)+1) (TyVar s) m
    _ -> debugS $ "readSharedHolType: Couldn't build TyVar"
                  ++ " because looking up " ++ (show i)
                  ++ " failed"
  _ -> do
   put d
   debugS $ "readSharedHolType: Expected a hol type but"
            ++ " instead got following tag: " ++ (show (b,t))

readParseType :: MSaxState HolParseType
readParseType = do
 (b,t) <- tag
 case (b,t) of
  (True,"Prefix") -> do
   expectTag False "Prefix"
   return Prefix
  (True,"InfixR") -> do
   i <- readInt
   expectTag False "InfixR"
   return $ InfixR i
  (True,"InfixL") -> do
   i <- readInt
   expectTag False "InfixL"
   return $ InfixL i
  (True,"Normal") -> do
   expectTag False "Normal"
   return Normal 
  (True,"Binder") -> do
   expectTag False "Binder"
   return Binder
  _ -> debugS $ "readParseType: Expected a parse type but"
                ++ " instead got following tag: " ++ (show (b,t))

readTermInfo :: MSaxState HolTermInfo
readTermInfo = do
 p <- readParseType
 MaybeT $ do
  v <- runMaybeT $ readTuple readWord readParseType
  case v of
   Just _ -> return $ Just $ HolTermInfo (p,v)
   _ -> return $ Just $ HolTermInfo (p,Nothing)

readSharedHolTerm :: Map.Map Int HolType -> Map.Map Int String
                      -> Map.Map Int Term -> MSaxState (Map.Map Int Term)
readSharedHolTerm ts sl m = do
 d <- get
 (b,tg) <- tag
 case (b,tg) of
  (True,"Var")   -> do
   (n,t) <- readTuple readInt readInt
   ti    <- readTermInfo
   case (Map.lookup n sl,Map.lookup t ts) of
    (Just name,Just tp) -> do
     expectTag False "Var"
     return $ Map.insert ((Map.size m)+1) (Var name tp ti) m
    (r1,r2) -> debugS $ "readSharedHolTerm: Couldn't build Var"
                  ++ " because the result of the lookup for "
                  ++ (show (n,t)) ++ " was " ++ (show (r1,r2))
  (True,"Const") -> do
   (n,t) <- readTuple readInt readInt
   ti    <- readTermInfo
   case (Map.lookup n sl,Map.lookup t ts) of
    (Just name,Just tp) -> do
     expectTag False "Const"
     return $ Map.insert ((Map.size m)+1) (Const name tp ti) m
    (r1,r2) -> debugS $ "readSharedHolTerm: Couldn't build Const"
                  ++ " because the result of the lookup for "
                  ++ (show (n,t)) ++ " was " ++ (show (r1,r2))
  (True,"Comb")  -> do
   (t1,t2) <- readTuple readInt readInt
   case (Map.lookup t1 m,Map.lookup t2 m) of
    (Just t1',Just t2') -> do
     expectTag False "Comb"
     return $ Map.insert ((Map.size m)+1) (Comb t1' t2') m
    (r1,r2) -> debugS $ "readSharedHolTerm: Couldn't build Comb"
                  ++ " because the result of the lookup for "
                  ++ (show (t1,t2)) ++ " was " ++ (show (r1,r2))
  (True,"Abs")   -> do
   (t1,t2) <- readTuple readInt readInt
   case (Map.lookup t1 m,Map.lookup t2 m) of
    (Just t1',Just t2') -> do
     expectTag False "Abs"
     return $ Map.insert ((Map.size m)+1) (Abs t1' t2') m
    (r1,r2) -> debugS $ "readSharedHoLTerm: Couldn't build Abs"
                  ++ " because the result of the lookup for "
                  ++ (show (t1,t2)) ++ " was " ++ (show (r1,r2))
  _ -> do
   put d
   debugS $ "readSharedHolTerm: Expected a hol term but"
            ++ " instead got following tag: " ++ (show (b,tg))

importData :: HetcatsOpts -> FilePath
  -> IO ([(String, [(String, Term)])], [(String, String)])
importData opts fp' = do
  fp <- canonicalizePath fp'
  dmtcpRestartPath <- getEnvDef "HETS_DMTCP_RESTART"
   "HolLight/OcamlTools/imageTools/dmtcp/bin/dmtcp_restart"
  imageFile <- getEnvDef "HETS_HOLLIGHT_IMAGE"
   "HolLight/OcamlTools/hol_light.dmtcp"
  e1 <- doesFileExist dmtcpRestartPath
  e2 <- doesFileExist imageFile
  unless e1 $ fail $ "dmtcp_restart not found" ++ dmtcpRestartPath
  unless e2 $ fail "hol_light.dmtcp not found"
  tempFile <- getTempFile "" (takeBaseName fp)
  (inp, sout, err, pid) <- runInteractiveProcess dmtcpRestartPath
   [imageFile] Nothing Nothing
  forkIO (hPutStr inp
   ("use_file " ++ show fp ++ ";;\n"
    ++ "inject_hol_include " ++ show fp ++ ";;\n"
    ++ "export_libs (get_libs()) " ++ show tempFile ++ ";;\n"
    ++ "exit 0;;\n"))
  ex <- waitForProcess pid
  case ex of
   ExitFailure _ -> do
    err' <- hGetContents err
    fail err'
   ExitSuccess -> do
    sout' <- hGetContents sout
    putIfVerbose opts 5 sout'
    s <- L.readFile tempFile
    e <- return ([], [])
    (r,evl,msgs) <- return $ case runMSaxState (do
     expectTag True "HolExport"
     sl <- readL readStr "Strings"
     let strings = Map.fromList (zip [1 ..] sl)
     hol_types <- foldS (readSharedHolType strings)
                   Map.empty "SharedHolTypes"
     hol_terms <- foldS (readSharedHolTerm hol_types strings)
                   Map.empty "SharedHolTerms"
     libs <- readL (readTuple readWord
                    (whileM (readTuple readWord
                             (readMappedInt hol_terms)))) "Libs"
     liblinks <- readL (readTuple readWord readWord) "LibLinks"
     return (libs,liblinks)) (parsexml s) of
      (Just d,msgs) -> (d,"Next 5 items: "
       ++ (show $ take 5 $ fst msgs), snd msgs)
      (Nothing,msgs) -> (e,"Next 5 items: "
       ++ (show $ take 5 $ fst msgs), snd msgs)
    when (debugC && isJust msgs) $ putIfVerbose opts 6 $
                                    (unlines $ reverse $ fromJust msgs)
                                    ++ evl
    removeFile tempFile
    return r

getTypes :: Map.Map String Int -> HolType -> Map.Map String Int
getTypes m t = case t of
 TyVar _ -> m
 TyApp s ts -> let m' = foldl getTypes m ts in
                     Map.insert s (length ts) m'

mergeTypesOps :: (Map.Map String Int, Map.Map String HolType)
                 -> (Map.Map String Int, Map.Map String HolType)
                 -> (Map.Map String Int, Map.Map String HolType)
mergeTypesOps (ts1, ops1) (ts2, ops2) =
 (ts1 `Map.union` ts2, ops1 `Map.union` ops2)

getOps :: Term
           -> (Map.Map String Int, Map.Map String HolType)
getOps tm = case tm of
 Var _ t _ -> let ts = getTypes Map.empty t
                     in (ts, Map.empty)
 Const s t _ -> let ts = getTypes Map.empty t
                     in (ts, Map.insert s t Map.empty)
 Comb t1 t2 -> mergeTypesOps
                  (getOps t1)
                  (getOps t2)
 Abs t1 t2 -> mergeTypesOps
                  (getOps t1)
                  (getOps t2)

calcSig :: [(String, Term)] -> Sign
calcSig tm = let (ts, os) = foldl
                      (\ p (_, t) -> (mergeTypesOps (getOps t) p))
                      (Map.empty, Map.empty) tm
                 in Sign {
                   types = ts
                  , ops = os }

sigDepends :: Sign -> Sign -> Bool
sigDepends s1 s2 = (Map.size (Map.intersection (types s1) (types s2)) /= 0) ||
                   (Map.size (Map.intersection (ops s1) (ops s2)) /= 0)

prettifyTypeVarsTp :: HolType -> Map.Map String String -> (HolType, Map.Map String String)
prettifyTypeVarsTp (TyVar s) m = case Map.lookup s m of
                                    Just s' -> (TyVar s', m)
                                    Nothing -> let s' = '\'' : (names !! Map.size m)
                                               in (TyVar s', Map.insert s s' m)
prettifyTypeVarsTp (TyApp s ts) m = let (ts', m') =
                                              foldl (\ (ts'', m'') t ->
                                                let (t', m''') = prettifyTypeVarsTp t m''
                                                in (t' : ts'', m''')
                                               ) ([], m) ts
                                   in (TyApp s ts', m')

prettifyTypeVarsTm :: Term -> Map.Map String String -> (Term, Map.Map String String)
prettifyTypeVarsTm (Const s t p) _ =
 let (t1, m1) = prettifyTypeVarsTp t Map.empty
 in (Const s t1 p, m1)
prettifyTypeVarsTm (Comb tm1 tm2) m =
 let (tm1', m1) = prettifyTypeVarsTm tm1 m
     (tm2', m2) = prettifyTypeVarsTm tm2 m1
 in (Comb tm1' tm2', m2)
prettifyTypeVarsTm (Abs tm1 tm2) m =
 let (tm1', m1) = prettifyTypeVarsTm tm1 m
     (tm2', m2) = prettifyTypeVarsTm tm2 m1
 in (Abs tm1' tm2', m2)
prettifyTypeVarsTm t m = (t, m)

prettifyTypeVars :: ([(String, [(String, Term)])], [(String, String)]) ->
                    ([(String, [(String, Term)])], [(String, String)])
prettifyTypeVars (libs, lnks) =
 let libs' = map (\ (s, terms) ->
      let terms' = foldl (\ tms (ts, t) ->
            let (t', _) = prettifyTypeVarsTm t Map.empty
            in ((ts, t') : tms))
             [] terms
      in (s, terms')
      ) libs
 in (libs', lnks)

treeLevels :: [(String, String)] -> Map.Map Int [(String, String)]
treeLevels l = let lk = foldr (\ (imp, t) l' -> case lookup t l' of
                                 Just (p, _) -> (imp, (p + 1, t)) : l'
                                 Nothing -> (imp, (1, t)) : (t, (0, "")) : l') [] l
                        in foldl (\ m (imp, (p, t)) ->
                            let s = Map.findWithDefault [] p m
                                in Map.insert p ((imp, t) : s) m) Map.empty lk

makeNamedSentence :: String -> Term -> Named Sentence
makeNamedSentence n t = makeNamed n Sentence { term = t, proof = Nothing }

_insNodeDG :: Sign -> [Named Sentence] -> String -> (DGraph, Map.Map String (String, Data.Graph.Inductive.Graph.Node, DGNodeLab)) -> (DGraph, Map.Map String (String, Data.Graph.Inductive.Graph.Node, DGNodeLab))
_insNodeDG sig sens n (dg, m) = let gt = G_theory HolLight (makeExtSign HolLight sig) startSigId
                                          (toThSens sens) startThId
                                    n' = snd (System.FilePath.Posix.splitFileName n)
                                    labelK = newInfoNodeLab
                                           (makeName (mkSimpleId n'))
                                           (newNodeInfo DGEmpty)
                                           gt
                                    k = getNewNodeDG dg
                                    m' = Map.insert n (n, k, labelK) m
                                    insN = [InsertNode (k, labelK)]
                                    newDG = changesDGH dg insN
                                    labCh = [SetNodeLab labelK (k, labelK
                                          { globalTheory = computeLabelTheory Map.empty newDG
                                            (k, labelK) })]
                                    newDG1 = changesDGH newDG labCh in (newDG1, m')

anaHolLightFile :: HetcatsOpts -> FilePath -> IO (Maybe (LibName, LibEnv))
anaHolLightFile opts path = do
   (libs_, lnks_) <- importData opts path
   let (libs, lnks) = prettifyTypeVars (libs_, lnks_)
   let h = treeLevels lnks
   let fixLinks m l = case l of
        (l1 : l2 : l') -> if snd l1 == snd l2 && sigDepends
                          (Map.findWithDefault emptySig (fst l1) m)
                          (Map.findWithDefault emptySig (fst l2) m) then
                       (fst l1, fst l2) : fixLinks m (l2 : l')
                      else l1 : l2 : fixLinks m l'
        l' -> l'
   let uniteSigs = foldl (\ m' (s, t) -> case resultToMaybe (sigUnion
                                                                   (Map.findWithDefault emptySig s m')
                                                                   (Map.findWithDefault emptySig t m')) of
                                                Nothing -> m'
                                                Just new_tsig -> Map.insert t new_tsig m')
   let m = foldl (\ m' (s, l) -> Map.insert s (calcSig l) m') Map.empty libs
   let (m', lnks') = foldr (\ lvl (m'', lnks_loc) -> let lvl' = Map.findWithDefault [] lvl h
                                                         lnks_next = fixLinks m'' (reverse lvl')
-- we'd probably need to take care of dependencies on previously imported files not imported by the file imported last
                                               in (uniteSigs m'' lnks_next, lnks_next ++ lnks_loc)
                    ) (m, []) [0 .. (Map.size h - 1)]
   let (dg', node_m) = foldr (\ (lname, lterms) (dg, node_m') ->
           let sig = Map.findWithDefault emptySig lname m'
               sens = map (uncurry makeNamedSentence) lterms in
           _insNodeDG sig sens lname (dg, node_m')) (emptyDG, Map.empty) libs
       dg'' = foldr (\ (source, target) dg -> case Map.lookup source node_m of
                                           Just (n, k, _) -> case Map.lookup target node_m of
                                             Just (n1, k1, _) -> let sig = Map.findWithDefault emptySig n m'
                                                                     sig1 = Map.findWithDefault emptySig n1 m' in
                                                          case resultToMaybe $ subsig_inclusion HolLight sig sig1 of
                                                            Nothing -> dg
                                                            Just incl ->
                                                              let inclM = gEmbed $ mkG_morphism HolLight incl
                                                                  insE = [InsertEdge (k, k1, globDefLink inclM DGLinkImports)]
                                                              in changesDGH dg insE
                                             Nothing -> dg
                                           Nothing -> dg) dg' lnks'
       le = Map.insert (emptyLibName (System.FilePath.Posix.takeBaseName path)) dg'' Map.empty
   return (Just (emptyLibName (System.FilePath.Posix.takeBaseName path), computeLibEnvTheories le))
