"""
Description :  Represents `Static.DevGraph.DGNodeLab`
Copyright   :  (c) Otto-von-Guericke University of Magdeburg
License     :  GPLv2 or higher, see LICENSE.txt
"""
import threading
from typing import Tuple, Optional, List

from .ConsistencyStatus import ConsistencyStatus
from .ConsistencyKind import ConsistencyKind
from .Comorphism import Comorphism
from .result import result_or_raise
from .ConsistencyChecker import ConsistencyChecker
from .LibName import LibName
from .ProofDetails import ProofDetails
from .Prover import Prover
from .HsWrapper import HsHierarchyElement
from .haskell import snd, theoryOfNode, DGNodeLab, fst, Just, Nothing, PyProver, PyComorphism, defaultProofOptions, \
    mkPyProofOptions, proveNode, recordProofResult, ConsistencyStatus as HsConsistencyStatus, PyConsChecker, \
    defaultConsCheckingOptions, \
    PyConsCheckingOptions, checkConsistencyAndRecord, TheoryPointer, globalTheory, recomputeNode, fromJust, \
    developmentGraphNodeLabelName, getDevelopmentGraphNodeType, nodeTypeIsReference, nodeTypeIsProven, \
    nodeTypeIsProvenConsistent, isInternalNode, showGlobalDoc, consistencyStatusType, CSUnchecked, CSTimeout, CSError, \
    CSInconsistent, CSConsistent, consistencyStatusMessage, isNodeReferenceNode, referencedNodeLibName

from .Theory import Theory


class DevGraphNode(HsHierarchyElement):
    _prove_lock: threading.Lock

    def __init__(self, hs_node: Tuple[int, DGNodeLab], parent: Optional[HsHierarchyElement]) -> None:
        super().__init__(parent)

        self._prove_lock = threading.Lock()

        self._hs_node = hs_node

        self._theory: Optional[Theory] = None

    def hs_obj(self):
        return self._hs_node

    def id(self) -> int:
        return fst(self._hs_node)

    def _label(self) -> DGNodeLab:
        return snd(self._hs_node)

    def name(self) -> str:
        return developmentGraphNodeLabelName(self._label())

    def is_internal(self) -> bool:
        return isInternalNode(self._label())

    def _theory_pointer(self) -> TheoryPointer:
        node = self.hs_obj()
        graph = self.parent().hs_obj()
        env_name = self.parent().parent().hs_obj()

        name = fst(env_name)
        env = snd(env_name)

        return name, env, graph, node

    def prove(self,
              prover: Optional[Prover] = None,
              comorphism: Optional[Comorphism] = None,
              use_theorems: Optional[bool] = None,
              goals_to_prove: Optional[List[str]] = None,
              axioms_to_include: Optional[List[str]] = None,
              timeout: Optional[int] = None
              ) -> List[ProofDetails]:
        prover_maybe = Just(prover._hs_prover) if prover else Nothing().subst(a=PyProver())
        comorphism_maybe = Just(comorphism._hs_comorphism) if comorphism else Nothing().subst(a=PyComorphism())

        default_opts = defaultProofOptions

        opts = mkPyProofOptions(
            prover_maybe,
            comorphism_maybe)(
            use_theorems if use_theorems is not None else default_opts.proofOptsUseTheorems(),
            goals_to_prove if goals_to_prove is not None else default_opts.proofOptsGoalsToProve(),
            axioms_to_include if axioms_to_include is not None else default_opts.proofOptsAxiomsToInclude(),
            timeout if timeout is not None else default_opts.proofOptsTimeout(),
        )

        prove_result = proveNode(self._theory_pointer(), opts).act()
        result = result_or_raise(prove_result)

        self._prove_lock.acquire()
        new_env = recordProofResult(self._theory_pointer(), result)

        self.root().hs_update(new_env)
        self._prove_lock.release()

        goal_statuses = snd(result)

        return list(ProofDetails(x) for x in goal_statuses)

    def check_consistency(self,
                          cons_checker: Optional[ConsistencyChecker] = None,
                          comorphism: Optional[Comorphism] = None,
                          include_theorems: Optional[bool] = None,
                          timeout: Optional[int] = None
                          ) -> Tuple[ConsistencyKind, str]:
        cc_maybe = Just(cons_checker._hs_cons_checker) if cons_checker else Nothing().subst(a=PyConsChecker())
        comorphism_maybe = Just(comorphism._hs_comorphism) if comorphism else Nothing().subst(a=PyComorphism())

        default_opts = defaultConsCheckingOptions

        opts = PyConsCheckingOptions(
            cc_maybe,
            comorphism_maybe,
            include_theorems if include_theorems is not None else default_opts.consOptsIncludeTheorems(),
            timeout if timeout is not None else default_opts.consOptsTimeout(),
        )

        result = checkConsistencyAndRecord(self._theory_pointer(), opts).act()
        cc_result, new_env = fst(result), snd(result)

        self.root().hs_update(new_env)

        status_type = consistencyStatusType(cc_result)
        status_message = consistencyStatusMessage(cc_result)

        if isinstance(status_type, CSUnchecked):
            return ConsistencyKind.UNKNOWN, status_message
        elif isinstance(status_type, CSTimeout):
            return ConsistencyKind.TIMED_OUT, status_message
        elif isinstance(status_type, CSError):
            return ConsistencyKind.ERROR, status_message
        elif isinstance(status_type, CSInconsistent):
            return ConsistencyKind.INCONSISTENT, status_message
        elif isinstance(status_type, CSConsistent):
            return ConsistencyKind.PROOF_THEORETICALLY_CONSERVATIVE, status_message
        else:
            return ConsistencyKind.UNKNOWN, status_message

    def global_theory(self) -> Optional[Theory]:
        node_lab = snd(self._hs_node)

        py_theory_maybe = globalTheory(node_lab)

        if isinstance(py_theory_maybe, Just):
            py_theory = fromJust(py_theory_maybe)
            return Theory(py_theory, self)

        return None

    def recompute(self) -> None:
        new_lib_env = recomputeNode(self._theory_pointer())

        root = self.parent().parent()
        root.hs_update(new_lib_env)

    def hs_update(self, new_hs_obj) -> None:
        self._hs_node = new_hs_obj

        if self._theory:
            node_lab = snd(self._hs_node)
            hs_theory = theoryOfNode(node_lab)
            self._theory.hs_update(hs_theory)
        
    def theory(self) -> Theory:
        if self._theory is None:
            self._theory = Theory(theoryOfNode(snd(self._hs_node)), self)

        return self._theory

    def is_reference_node(self) -> bool:
        return nodeTypeIsReference(getDevelopmentGraphNodeType(self._label()))

    def is_proven_node(self) -> bool:
        return nodeTypeIsProven(getDevelopmentGraphNodeType(self._label()))

    def is_consistency_proven(self) -> bool:
        return nodeTypeIsProvenConsistent(getDevelopmentGraphNodeType(self._label()))

    def info(self) -> str:
        dev_graph = self.parent()
        return showGlobalDoc(dev_graph.global_annotations()._hs_global_annos, self._label(), "")


class LocalDevGraphNode(DevGraphNode):
    def consistency_status(self) -> ConsistencyStatus:
        node_lab = snd(self._hs_node)
        hs_cons_status = node_lab.getNodeConsStatus()
        return ConsistencyStatus(hs_cons_status)


class ReferenceDevGraphNode(DevGraphNode):
    def referenced_libname(self) -> LibName:
        return LibName(referencedNodeLibName(self._label()))


def dev_graph_node_from_hs(hs_node: Tuple[int, DGNodeLab], parent: Optional[HsHierarchyElement]) -> DevGraphNode:
    label = snd(hs_node)
    if isNodeReferenceNode(label):
        return ReferenceDevGraphNode(hs_node, parent)
    else:
        return LocalDevGraphNode(hs_node, parent)
