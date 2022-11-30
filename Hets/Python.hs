module Hets.Python (
    PyTheory
    , PyComorphism
    , PyProver
    -- Wrapped with PyTheory
    , getTheoryFromNode
    , usableProvers
    , autoProveNode

    -- Unchanged re-export from Hets.ProveCommands
    , HP.proveNode
    , HP.checkConsistency

    -- Unchanged re-export from Hets.Commands
    , HC.automatic
    , HC.globalSubsume
    , HC.globalDecomposition
    , HC.localInference
    , HC.localDecomposition
    , HC.compositionProveEdges
    , HC.conservativity
    , HC.automaticHideTheoremShift
    , HC.theoremHideShift
    , HC.computeColimit
    , HC.normalForm
    , HC.triangleCons
    , HC.freeness
    , HC.libFlatImports
    , HC.libFlatDUnions
    , HC.libFlatRenamings
    , HC.libFlatHiding
    , HC.libFlatHeterogen
    , HC.qualifyLibEnv
    , HC.loadLibrary
    , HC.getGraphForLibrary
    , HC.getNodesFromDevelopmentGraph
    , HC.getLNodesFromDevelopmentGraph
)

where

import qualified Hets.Commands as HC
import qualified Hets.ProveCommands as HP

import qualified Static.GTheory as GT
import Static.DevGraph (DGNodeLab (dgn_theory))
import Proofs.AbstractState (G_prover, ProofState, G_proof_tree)
import Logic.Comorphism (AnyComorphism)
import Common.ResultT (ResultT (runResultT))
import Logic.Prover (ProofStatus)
import Common.Result (Result)

-- TODO: Wrap all function calls that require existential datatypes like G_theory

data PyTheory = PyTheory GT.G_theory
data PyProver = PyProver G_prover
data PyComorphism = PyComorphism AnyComorphism

getTheoryFromNode :: DGNodeLab -> PyTheory
getTheoryFromNode = PyTheory . dgn_theory

-- | @usableProvers theory@ checks for usable provers available on the machine
usableProvers :: PyTheory -> IO [(PyProver, PyComorphism)]
usableProvers (PyTheory th) = do
    provers <- HP.usableProvers th
    let toPy (p, c) = (PyProver p, PyComorphism c)
    return $ fmap toPy provers

-- | @proveNode theory prover comorphism@ proves all goals in @theory@ using all
--   all axioms in @theory@. If @prover@ or @comorphism@ is @Nothing@ the first
--   usable prover or comorphism is used. 
autoProveNode :: PyTheory -> Maybe PyProver -> Maybe PyComorphism -> IO (Result (ProofState, [ProofStatus G_proof_tree]))
autoProveNode (PyTheory theory) prover comorphism = runResultT $
    HP.autoProveNode theory ((\(PyProver p) -> p) <$> prover) ((\(PyComorphism c) -> c) <$> comorphism)
