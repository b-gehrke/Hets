{- |
Module      :  $Header$
Description :  Goal management GUI.
Copyright   :  (c) Rene Wagner, Klaus L�ttich, Uni Bremen 2005
License     :  similar to LGPL, see HetCATS/LICENSE.txt or LIZENZ.txt

Maintainer  :  luettich@tzi.de
Stability   :  provisional
Portability :  needs POSIX

Goal management GUI for the structured level similar to how 'SPASS.Prove'
works for SPASS.

-}

{- ToDo:

   -
-}

module GUI.ProofManagement (proofManagementGUI) where

import qualified Common.AS_Annotation as AS_Anno
import qualified Common.Doc as Pretty
import Common.Utils
import qualified Common.Result as Result
import qualified Common.Lib.Map as Map
import qualified Common.OrderedMap as OMap

import Data.List
import Data.Maybe
import Data.IORef

import HTk
import Separator
import Space
import XSelection

import GUI.HTkUtils

import Proofs.GUIState
import Logic.Logic
import Logic.Grothendieck
import Logic.Prover
import qualified Comorphisms.KnownProvers as KnownProvers
import qualified Static.DevGraph as DevGraph

-- debugging
-- import Debug.Trace

-- * Proof Management GUI

-- ** Defining the view

{- |
  Colors used by the GUI to indicate the status of a goal.
-}
data ProverStatusColour
  -- | Not running
  = Black
  -- | Running
  | Blue
   deriving (Bounded,Enum,Show)

data SelButtonFrame = SBF { selAllEv :: Event ()
                          , deselAllEv :: Event ()
                          , sbf_btns :: [Button]
                          , sbf_btnFrame :: Frame}

data SelAllListbox = SAL SelButtonFrame (ListBox String)

{- |
  Generates a ('ProverStatusColour', 'String') tuple.
-}
statusNotRunning :: (ProverStatusColour, String)
statusNotRunning = (Black, "No Prover Running")

{- |
  Generates a ('ProverStatusColour', 'String') tuple.
-}
statusRunning :: (ProverStatusColour, String)
statusRunning = (Blue, "Waiting for Prover")

{- |
  Converts a 'ProofGUIState' into a ('ProverStatusColour', 'String') tuple to be
  displayed by the GUI.
-}
toGuiStatus :: ProofGUIState lid sentence
            -> (ProverStatusColour, String)
toGuiStatus st = if proverRunning st
  then statusRunning
  else statusNotRunning

{- |
  Generates a list of 'GUI.HTkUtils.LBGoalView' representations of all goals
  from a 'SPASS.Prove.State'.

  Uses 'toStatusIndicator' internally.
-}
goalsView :: ProofGUIState lid sentence  -- ^ current global state
          -> [LBGoalView] -- ^ resulting ['LBGoalView'] list
goalsView = map toStatus . OMap.toList . goalMap
    where toStatus (l,st) =
              let tStatus = thmStatus st
                  si = if null tStatus
                       then LBIndicatorOpen
                       else indicatorFromBasicProof
                                (maximum $ map snd $ tStatus)
              in LBGoalView { statIndicator = si
                            , goalDescription = l}

-- ** GUI Implementation

-- *** Utility Functions

{- |
  Populates the "Pick Theorem Prover" 'ListBox' with prover names (or possibly
  paths to provers).
-}
populatePathsListBox :: ListBox String
                     -> KnownProvers.KnownProversMap
		     -> IO ()
populatePathsListBox lb prvs = do
  lb # HTk.value (Map.keys prvs)
  return ()

populateAxiomsList ::
    (Logic  lid1 sublogics1 basic_spec1 sentence1 symb_items1 symb_map_items1
            sign1 morphism1 symbol1 raw_symbol1 proof_tree1) =>
       ListBox String
    -> ProofGUIState lid1 sentence1
    -> IO ()
populateAxiomsList lbAxs s =
    do aM' <- axiomMap s
       lbAxs # HTk.value (OMap.keys aM')
       return ()

-- *** Callbacks

{- |
   Updates the display of the status of the selected goals.
-}
updateDisplay :: ProofGUIState lid sentence -- ^ current global state
              -> Bool -- ^ set to 'True' if you want the 'ListBox' to be updated
              -> ListBox String -- ^ 'ListBox' displaying the status of all goals (see 'goalsView')
              -> ListBox String -- ^ 'ListBox' displaying possible morphism paths to prover logics
              -> Label -- ^ 'Label' displaying the status of the currently selected goal(s)
              -> IO ()
updateDisplay st updateLb goalsLb pathsLb statusLabel = do
    -- update goals listbox
    when updateLb
         (populateGoalsListBox goalsLb (goalsView st))
    -- set selected Prover
    let ind = if (isJust $ selectedProver st)
              then findIndex (==(fromJust $ selectedProver st))
                       $ Map.keys (proversMap st)
              else Nothing
    maybe (return ()) (\i -> selection i pathsLb >> return ()) ind
    -- update status label
    let (color, label) = toGuiStatus st
    statusLabel # text label
    statusLabel # foreground (show color)
    return ()

updateStateSelectAllAxs ::
    (Logic  lid1 sublogics1 basic_spec1 sentence1 symb_items1 symb_map_items1
            sign1 morphism1 symbol1 raw_symbol1 proof_tree1) =>
           IORef (ProofGUIState lid1 sentence1)
        -> IO ()
updateStateSelectAllAxs stateRef =
    do s <- readIORef stateRef
       aM' <- axiomMap s
       writeIORef stateRef (s{includedAxioms = OMap.keys aM' })

updateStateGetSelectedGoals ::
    (Logic  lid1 sublogics1 basic_spec1 sentence1 symb_items1 symb_map_items1
            sign1 morphism1 symbol1 raw_symbol1 proof_tree1) =>
           ProofGUIState lid1 sentence1
        -> ListBox String
        -> IO (ProofGUIState lid1 sentence1)
updateStateGetSelectedGoals s lb =
    do sel <- (getSelection lb) :: IO (Maybe [Int])
       return (s {selectedGoals =
                      maybe [] (map ((OMap.keys (goalMap s))!!)) sel})

updateStateGetSelectedSens ::
    (Logic  lid1 sublogics1 basic_spec1 sentence1 symb_items1 symb_map_items1
            sign1 morphism1 symbol1 raw_symbol1 proof_tree1) =>
           ProofGUIState lid1 sentence1
        -> ListBox String -- ^ axioms listbox
        -> ListBox String -- ^ theorems listbox
        -> IO (ProofGUIState lid1 sentence1)
updateStateGetSelectedSens s lbAxs lbThs =
    do aM <- axiomMap s
       selA <- (getSelection lbAxs) :: IO (Maybe [Int])
       selT <- (getSelection lbThs) :: IO (Maybe [Int])
       return (s { includedAxioms   = maybe [] (fil aM) selA
                 , includedTheorems = maybe [] (fil (goalMap s)) selT })
    where fil str = map ((OMap.keys str)!!)

{- |
 Depending on the first argument all entries in a ListBox are selected
  or deselected
-}
doSelectAllEntries :: Bool -- ^ indicates wether all entries should be selected
                         -- or deselected
		 -> ListBox a
                 -> IO ()
doSelectAllEntries selectAll lb =
  if selectAll
     then selectionRange (0::Int) EndOfText lb
              >> return ()
     else clearSelection lb

{- |
  Called whenever the button "Display" is clicked.
-}
doDisplayGoals ::
    (Logic  lid1 sublogics1 basic_spec1 sentence1 symb_items1 symb_map_items1
            sign1 morphism1 symbol1 raw_symbol1 proof_tree1) =>
       ProofGUIState lid1 sentence1
    -> IO ()
doDisplayGoals s@(ProofGUIState { theoryName = thName
                                , theory=DevGraph.G_theory lid1 sig1 _}) =
    do sens' <- DevGraph.coerceThSens (logicId s) lid1 "" sens
       createTextSaveDisplay ("Selected Goals from Theory " ++ thName)
                          (thName ++ "-goals.txt") (goalsText sens')
    where goalsText s' = show $
                      Pretty.vsep (map (print_named lid1
                                 . AS_Anno.mapNamed (simplify_sen lid1 sig1))
                                           $ toNamedList s')
          sens = selectedGoalMap s


{- |
  Called whenever the button "Show proof details" is clicked.
-}
doShowProofDetails ::
    (Logic lid
           sublogics1
           basic_spec1
           sentence
           symb_items1
           symb_map_items1
           sign1
           morphism1
           symbol1
           raw_symbol1
           proof_tree1) =>
       ProofGUIState lid sentence
    -> IO ()
doShowProofDetails s@(ProofGUIState { theoryName = thName}) =
     createTextSaveDisplay ("Proof Details of Selected Goals from Theory "
                            ++ thName)
                           (thName ++ "-proof-details.txt") (detailsText sens)
    where sens = selectedGoalMap s
          detailsText s' = show $
                      Pretty.vsep (map (\ (l, st) ->
                                 Pretty.cat [Pretty.text l,
                                      Pretty.space Pretty.<> printSenStat st ])
                            $ OMap.toList s')
          printSenStat st =
              if null $ thmStatus st
                 then stat "Open"
                 else Pretty.vcat $
                      map printCmWStat $
                      sortBy (comparing snd) $ thmStatus st
          stat str = Pretty.text "Status:" Pretty.<+> Pretty.text str
          printCmWStat (c, bp) =
              Pretty.cat [Pretty.text "Com:" Pretty.<+> Pretty.text (show c)
                  , Pretty.space Pretty.<> printBP bp]
          printBP bp = case bp of
                       DevGraph.BasicProof _ ps ->
                        stat (show $ goalStatus ps) Pretty.$+$
                        (case goalStatus ps of
                         Proved _ ->
                           (Pretty.text "Used axioms:") Pretty.$+$
                                  (Pretty.fsep (Pretty.punctuate
                                                     Pretty.comma
                                               (map (Pretty.text . show) $
                                                   usedAxioms ps)))
                         _ -> Pretty.empty)
                        Pretty.$+$ Pretty.text "Prover:" Pretty.<+>
                              Pretty.text (proverName ps)
                       otherProof -> stat (show otherProof)


{- |
  Called whenever a prover is selected from the "Pick Theorem Prover" ListBox.
-}
doSelectProverPath :: ProofGUIState lid sentence
		   -> ListBox String
                   -> IO (ProofGUIState lid sentence)
doSelectProverPath s lb =
    do selected <- (getSelection lb) :: IO (Maybe [Int])
       return (s {selectedProver =
                      maybe Nothing
                            (\ (index:_) ->
                                 Just (Map.keys (proversMap s) !! index))
                            selected
                 })

newSelectButtonsFrame :: (Container par) =>
                         par -> IO SelButtonFrame
newSelectButtonsFrame b3 =
  do
  selFrame <- newFrame b3 []
  pack selFrame [Expand Off, Fill None, Anchor South]

  selHBox <- newHBox selFrame []
  pack selHBox [Expand Off, Fill None]

  selectAllButton <- newButton selHBox [text "Select all"]
  pack selectAllButton [Expand Off, Fill None]

  deselectAllButton <- newButton selHBox [text "Deselect all"]
  pack deselectAllButton [Expand Off, Fill None]
  -- events
  selectAll <- clicked selectAllButton
  deselectAll <- clicked deselectAllButton

  return (SBF { selAllEv = selectAll
              , deselAllEv = deselectAll
              , sbf_btns = [deselectAllButton,selectAllButton]
              , sbf_btnFrame = selFrame })

newExtSelListBoxFrame :: (Container par) =>
                         par -> String -> Distance
                      -> IO SelAllListbox
newExtSelListBoxFrame b2 title hValue =
  do
  left <- newFrame b2 []
  pack left [Expand On, Fill Both]

  b3 <- newVBox left []
  pack b3 [Expand On, Fill Both]

  l0 <- newLabel b3 [text title]
  pack l0 [Anchor NorthWest]

  lbFrame <- newFrame b3 []
  pack lbFrame [Expand On, Fill Both]

  lb <- newListBox lbFrame [bg "white",exportSelection False,
                            selectMode Multiple,
                            height hValue] :: IO (ListBox String)

  pack lb [Expand On, Side AtLeft, Fill Both]
  sb <- newScrollBar lbFrame []
  pack sb [Expand On, Side AtRight, Fill Y]
  lb # scrollbar Vertical sb

  -- buttons for goal selection
  sbf <- newSelectButtonsFrame b3
  return (SAL sbf lb)



-- *** Main GUI
{- |
  Invokes the GUI.
-}
proofManagementGUI ::
    (Logic lid sublogics1
               basic_spec1
               sentence
               symb_items1
               symb_map_items1
               sign1
               morphism1
               symbol1
               raw_symbol1
               proof_tree1) =>
       lid
    -> (   ProofGUIState lid sentence
        -> IO (Result.Result (ProofGUIState lid sentence)))
    -- ^ called whenever the "Prove" button is clicked
    -> (   ProofGUIState lid sentence
        -> IO (Result.Result (ProofGUIState lid sentence)))
    -- ^ called whenever the "More fine grained selection" button is clicked
    -> String -- ^ theory name
    -> DevGraph.G_theory -- ^ theory
    -> KnownProvers.KnownProversMap -- ^ map of known provers
    -> [(G_prover,AnyComorphism)] -- ^ list of suitable comorphisms to provers
                       -- for sublogic of G_theory
    -> IO (Result.Result DevGraph.G_theory)
proofManagementGUI lid proveF fineGrainedSelectionF
                   thName th
                   knownProvers comorphList =
  do
  -- KnownProvers.showKnownProvers knownProvers
  -- initial backing data structure
  initState <- initialState lid thName th knownProvers comorphList
  stateRef <- newIORef initState

  -- main window
  main <- createToplevel [text $ thName ++ " - Select Goal(s) and Prove"]
  pack main [Expand On, Fill Both]

  -- VBox for the whole window
  b <- newVBox main []
  pack b [Expand On, Fill Both]

  -- HBox for the upper part (goals on the left, options/results on the right)
  b2 <- newHBox b []
  pack b2 [Expand On, Fill Both]

  -- ListBox for goal selection
  (SAL (SBF { selAllEv = selectAllGoals
            , deselAllEv = deselectAllGoals
            , sbf_btns = goalBtns
            , sbf_btnFrame = goalsBtnFrame}) lb)
      <- newExtSelListBoxFrame b2 "Goals:" 14

  -- button to select only the open goals
  selectOpenGoalsButton <- newButton goalsBtnFrame [text "Select Open Goals"]
  pack selectOpenGoalsButton [Expand Off, Fill None, Side AtLeft]

  -- put the labels in the listbox
  populateGoalsListBox lb (goalsView initState)

  -- right frame (options/results)
  right <- newFrame b2 []
  pack right [Expand On, Fill Both, Anchor NorthWest]

  let hindent = "   "
  let vspacing = cm 0.2

  rvb <- newVBox right []
  pack rvb [Expand On, Fill Both]

  l1 <- newLabel rvb [text "Selected Goal(s):"]
  pack l1 [Anchor NorthWest]

  rhb1 <- newHBox rvb []
  pack rhb1 [Expand On, Fill Both]

  hsp1 <- newLabel rhb1 [text hindent]
  pack hsp1 []

  displayGoalsButton <- newButton rhb1 [text "Display"]
  pack displayGoalsButton []

  proveButton <- newButton rhb1 [text "Prove"]
  pack proveButton []

  proofDetailsButton <- newButton rhb1 [text "Show proof details"]
  pack proofDetailsButton []

  vsp1 <- newSpace rvb vspacing []
  pack vsp1 []

  l2 <- newLabel rvb [text "Status:"]
  pack l2 [Anchor NorthWest]

  rhb2 <- newHBox rvb []
  pack rhb2 [Expand On, Fill Both]

  hsp2 <- newLabel rhb2 [text hindent]
  pack hsp2 []

  statusLabel <- newLabel rhb2 [text (snd statusNotRunning)]
  pack statusLabel []

  vsp2 <- newSpace rvb vspacing []
  pack vsp2 []

  l3 <- newLabel rvb [text "Pick Theorem Prover:"]
  pack l3 [Anchor NorthWest]

  rhb3 <- newHBox rvb []
  pack rhb3 [Expand On, Fill Both]

  hsp3 <- newLabel rhb3 [text hindent]
  pack hsp3 []

  pathsFrame <- newFrame rhb3 []
  pack pathsFrame []
  pathsLb <- newListBox pathsFrame [HTk.value $ ([]::[String]), bg "white",
                                    selectMode Single, exportSelection False,
                                    height 4, width 28] :: IO (ListBox String)
  populatePathsListBox pathsLb knownProvers
  pack pathsLb [Expand On, Side AtLeft, Fill Both]
  pathsSb <- newScrollBar pathsFrame []
  pack pathsSb [Expand On, Side AtRight, Fill Y]
  pathsLb # scrollbar Vertical pathsSb

  moreButton <- newButton rvb [text "More fine grained selection..."]
  pack moreButton [Anchor SouthEast]

  -- separator
  sp1 <- newSpace b (cm 0.15) []
  pack sp1 [Expand Off, Fill X, Side AtBottom]

  newHSeparator b

  sp2 <- newSpace b (cm 0.15) []
  pack sp2 [Expand Off, Fill X, Side AtBottom]

  -- theory composer frame (toggled with button)
  composer <- newFrame b []
  pack composer [Expand On, Fill Both]

  compBox <- newVBox composer []
  pack compBox [Expand On, Fill Both]

  newLabel compBox [text "Fine grained composition of theory:"] >>=
        (\ lab -> pack lab [])

  icomp <- newFrame compBox []
  pack icomp [Expand On, Fill Both]

  icBox <- newHBox icomp []
  pack icBox [Expand On, Fill Both]

  (SAL (SBF { selAllEv = selectAllAxs
            , deselAllEv = deselectAllAxs
            , sbf_btns = axsBtns}) lbAxs)
       <- newExtSelListBoxFrame icBox "Axioms to include:" 10

  (SAL (SBF { selAllEv = selectAllThs
            , deselAllEv = deselectAllThs
            , sbf_btns = thsBtns}) lbThs)
      <- newExtSelListBoxFrame icBox "Theorems to include if proven:" 10

  populateAxiomsList lbAxs initState
  lbThs # HTk.value (OMap.keys (goalMap initState))
  doSelectAllEntries True lbAxs
  doSelectAllEntries True lbThs

  -- separator
  spac1 <- newSpace b (cm 0.15) []
  pack spac1 [Expand Off, Fill X, Side AtBottom]

  newHSeparator b

  spac2 <- newSpace b (cm 0.15) []
  pack spac2 [Expand Off, Fill X, Side AtBottom]

  -- bottom frame (close button)
  bottom <- newFrame b []
  pack bottom [Expand Off, Fill Both]

  closeButton <- newButton bottom [text "Close"]
  pack closeButton [Expand Off, Fill None, Side AtRight,PadX (pp 13)]

  updateDisplay initState False lb pathsLb statusLabel

  let goalSpecificWids = map EnW [displayGoalsButton,proveButton,
                                  proofDetailsButton,moreButton]
      wids = [EnW pathsLb,EnW lbThs,EnW lb,EnW lbAxs] ++
             map EnW (selectOpenGoalsButton : closeButton :
                      axsBtns++goalBtns++thsBtns) ++
             goalSpecificWids

  disableWids goalSpecificWids
  putWinOnTop main

  -- events
  (selectProverPath, _) <- bindSimple pathsLb (ButtonPress (Just 1))
  (selectGoals, _) <- bindSimple lb (ButtonPress (Just 1))
  selectOpenGoals <- clicked selectOpenGoalsButton
  displayGoals <- clicked displayGoalsButton
  moreProverPaths <- clicked moreButton
  doProve <- clicked proveButton
  showProofDetails <- clicked proofDetailsButton
  close <- clicked closeButton
  (closeWindow,_) <- bindSimple main Destroy

  -- event handlers
  spawnEvent
    (forever
      (  (selectGoals >>> do
             enableWidsUponSelection lb goalSpecificWids
             done)
      +> (selectOpenGoals >>> do
             s <- readIORef stateRef
             clearSelection lb
             let isOpenGoal (_,st) =
                     let thst = thmStatus st
                     in if null thst
                        then True
                        else case maximum $ map snd $ thst of
                             DevGraph.BasicProof _ pst ->
                                 case goalStatus pst of
                                 Open -> True
                                 _ -> False
                             _ -> False
             mapM_ (\ i -> selection i lb)
                   (findIndices isOpenGoal $ OMap.toList $ goalMap s )
             enableWidsUponSelection lb goalSpecificWids
             done)
      +> (deselectAllGoals >>> do
	    doSelectAllEntries False lb
            disableWids goalSpecificWids
            modifyIORef stateRef (\s -> s{selectedGoals = []})
            done)
      +> (selectAllGoals >>> do
	    doSelectAllEntries True lb
            enableWids goalSpecificWids
            modifyIORef stateRef
                            (\s -> s{selectedGoals = OMap.keys (goalMap s)})
            done)
      +> (selectAllAxs >>> do
            doSelectAllEntries True lbAxs
            updateStateSelectAllAxs stateRef
            done)
      +> (selectAllThs >>> do
            doSelectAllEntries True lbThs
            modifyIORef stateRef
                        (\s -> s{includedTheorems =
                                     OMap.keys (goalMap s)})
            done)
      +> (deselectAllAxs >>> do
	    doSelectAllEntries False lbAxs
            modifyIORef stateRef (\s -> s{includedAxioms = []})
            done)
      +> (deselectAllThs >>> do
	    doSelectAllEntries False lbThs
            modifyIORef stateRef (\s -> s{includedTheorems = []})
            done)
      +> (displayGoals >>> do
            s <- readIORef stateRef
            s' <- updateStateGetSelectedGoals s lb
	    doDisplayGoals s'
            done)
      +> (selectProverPath>>> do
            s <- readIORef stateRef
	    s' <- doSelectProverPath s pathsLb
	    writeIORef stateRef s'
            done)
      +> (moreProverPaths >>> do
            s <- readIORef stateRef
	    let s' = s{proverRunning = True}
	    updateDisplay s' True lb pathsLb statusLabel
            disableWids wids
            prState <- (updateStateGetSelectedSens s' lbAxs lbThs >>=
                        (\ si -> updateStateGetSelectedGoals si lb))
            writeIORef stateRef prState
	    Result.Result ds ms'' <- fineGrainedSelectionF prState
            s'' <- case ms'' of
                   Nothing -> fail "fineGrainedSelection returned Nothing"
                   Just res -> return res
	    let s''' = s'' {proverRunning = False,accDiags = accDiags s'' ++ ds}
            enableWids wids
	    updateDisplay s''' True lb pathsLb statusLabel
            putWinOnTop main
	    writeIORef stateRef s'''
            done)
      +> (doProve >>> do
            s <- readIORef stateRef
	    let s' = s{proverRunning = True}
	    updateDisplay s' True lb pathsLb statusLabel
            disableWids wids
            prState <- (updateStateGetSelectedSens s' lbAxs lbThs >>=
                        (\ si -> updateStateGetSelectedGoals si lb))
            -- putStrLn (show (includedAxioms prState)++
            --                   ' ':show (includedTheorems prState))
            writeIORef stateRef prState
	    Result.Result ds ms'' <- proveF prState
            curSt <- readIORef stateRef
            if proofManagementDestroyed curSt
               then done
               else do
             s'' <- case ms'' of
                   Nothing -> fail "proveF returned Nothing"
                   Just res -> return res
	     let s''' = s''{proverRunning = False,
                           accDiags = accDiags s'' ++ ds}
             enableWids wids
	     updateDisplay s''' True lb pathsLb statusLabel
             putWinOnTop main
	     writeIORef stateRef s'''
             done)
      +> (showProofDetails >>> do
            s <- readIORef stateRef
            s' <- updateStateGetSelectedGoals s lb
	    doShowProofDetails s'
            done)
      ))
  sync ( (close >>> destroy main)
      +> (closeWindow >>> do modifyIORef stateRef
                                (\ s -> s {proofManagementDestroyed = True})
                             destroy main))

  -- read the global state back in
  s <- readIORef stateRef
  case theory s of
   DevGraph.G_theory lidT sigT sensT ->
    do gMap <- DevGraph.coerceThSens (logicId s) lidT "" (goalMap s)
       return (Result.Result {Result.diags = accDiags s,
                              Result.maybeResult =
                                  Just (DevGraph.G_theory lidT sigT
                                                    (Map.union sensT gMap))
                             }
              )
  -- TODO: do something with the resulting G_theory before returning it?

