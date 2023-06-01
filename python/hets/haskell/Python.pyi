""" Auto generated python stubs for haskell module ../HetsAPI/Python.hs"""

import typing

from .Prelude import *
from .Internal import *
from .OMap import *

a = typing.TypeVar("a")
b = typing.TypeVar("b")
c = typing.TypeVar("c")

GenericTransportType = typing.Any
SignatureJSON = GenericTransportType
SymbolJSON = GenericTransportType
SentenceByName = OMap[str, Sentence]


def fstOf3(x0: typing.Tuple[a, b, c]) -> a: ...


def sndOf3(x0: typing.Tuple[a, b, c]) -> b: ...


def thd(x0: typing.Tuple[a, b, c]) -> c: ...


class PyTheory:
    ...


class PyProver:
    ...


class PyConsChecker:
    ...


class PyComorphism:
    ...


class PyProofTree:
    ...


class PyGMorphism:
    ...


class PyProofOptions:
    def __init__(self, proofOptsProver: Maybe[PyProver], proofOptsComorphism: Maybe[PyComorphism],
                 proofOptsUseTheorems: bool, proofOptsGoalsToProve: typing.List[str],
                 proofOptsAxiomsToInclude: typing.List[str], proofOptsTimeout: int): ...

    def proofOptsProver(self) -> Maybe[PyProver]: ...

    def proofOptsComorphism(self) -> Maybe[PyComorphism]: ...

    def proofOptsUseTheorems(self) -> bool: ...

    def proofOptsGoalsToProve(self) -> typing.List[str]: ...

    def proofOptsAxiomsToInclude(self) -> typing.List[str]: ...

    def proofOptsTimeout(self) -> int: ...

    ...


def mkPyProofOptions(x0: Maybe[PyProver]) -> typing.Callable[[Maybe[PyComorphism]], typing.Callable[
    [bool], typing.Callable[
        [typing.List[str]], typing.Callable[[typing.List[str]], typing.Callable[[int], PyProofOptions]]]]]: ...


class PyConsCheckingOptions:
    def __init__(self, consOptsConsChecker: Maybe[PyConsChecker], consOptsComorphism: Maybe[PyComorphism],
                 consOptsIncludeTheorems: bool, consOptsTimeout: int): ...

    def consOptsConsChecker(self) -> Maybe[PyConsChecker]: ...

    def consOptsComorphism(self) -> Maybe[PyComorphism]: ...

    def consOptsIncludeTheorems(self) -> bool: ...

    def consOptsTimeout(self) -> int: ...

    ...


def defaultProofOptions() -> PyProofOptions: ...


def defaultConsCheckingOptions() -> PyConsCheckingOptions: ...


def proverName(x0: PyProver) -> str: ...


def comorphismName(x0: PyComorphism) -> str: ...


def targetLogicName(x0: PyComorphism) -> str: ...


def targetLogicDescriptionName(x0: PyComorphism) -> str: ...


def sourceLogicName(x0: PyComorphism) -> str: ...


def sourceLogicDescriptionName(x0: PyComorphism) -> str: ...


def consCheckerName(x0: PyConsChecker) -> str: ...


def theoryOfNode(x0: DGNodeLab) -> PyTheory: ...


def getUsableProvers(x0: PyTheory) -> IO[typing.List[typing.Tuple[PyProver, PyComorphism]]]: ...


def proveNode(x0: PyTheory) -> typing.Callable[
    [PyProofOptions], IO[Result[typing.Tuple[PyTheory, typing.List[ProofStatus[PyProofTree]]]]]]: ...


def proveNodeAndRecord(x0: TheoryPointer) -> typing.Callable[[PyProofOptions], IO[
    Result[typing.Tuple[typing.Tuple[PyTheory, typing.List[ProofStatus[PyProofTree]]], LibEnv]]]]: ...


def translateTheory(x0: PyComorphism) -> typing.Callable[[PyTheory], Result[PyTheory]]: ...


def getAvailableComorphisms(x0: PyTheory) -> typing.List[PyComorphism]: ...


def getUsableConsistencyCheckers(x0: PyTheory) -> IO[typing.List[typing.Tuple[PyConsChecker, PyComorphism]]]: ...


def checkConsistency(x0: TheoryPointer) -> typing.Callable[[PyConsCheckingOptions], IO[ConsistencyStatus]]: ...


def checkConsistencyAndRecord(x0: TheoryPointer) -> typing.Callable[
    [PyConsCheckingOptions], IO[typing.Tuple[ConsistencyStatus, LibEnv]]]: ...


def getAllSentences(x0: PyTheory) -> SentenceByName: ...


def getAllAxioms(x0: PyTheory) -> SentenceByName: ...


def getAllGoals(x0: PyTheory) -> SentenceByName: ...


def getProvenGoals(x0: PyTheory) -> SentenceByName: ...


def getUnprovenGoals(x0: PyTheory) -> SentenceByName: ...


def prettySentence(x0: PyTheory) -> typing.Callable[[Sentence], str]: ...


def signatureOfTheory(x0: PyTheory) -> ExtSign[SignatureJSON, SymbolJSON]: ...


def logicNameOfTheory(x0: PyTheory) -> str: ...


def logicDescriptionOfTheory(x0: PyTheory) -> str: ...


def getDGNodeById(x0: DGraph) -> typing.Callable[[int], Maybe[DGNodeLab]]: ...


def globalTheory(x0: DGNodeLab) -> Maybe[PyTheory]: ...


def gmorphismOfEdge(x0: DGLinkLab) -> PyGMorphism: ...


def comorphismOfGMorphism(x0: PyGMorphism) -> PyComorphism: ...


def signatureOfGMorphism(x0: PyGMorphism) -> ExtSign[SignatureJSON, SymbolJSON]: ...


def comorphismNameOfGMorphism(x0: PyGMorphism) -> str: ...


def comorphismDescriptionOfGMorphism(x0: PyGMorphism) -> str: ...


def domainOfGMorphism(x0: PyGMorphism) -> GenericTransportType: ...


def codomainOfGMorphism(x0: PyGMorphism) -> GenericTransportType: ...


def isGMorphismInclusion(x0: PyGMorphism) -> bool: ...


def gMorphismToTransportType(x0: PyGMorphism) -> GenericTransportType: ...


TheoryPointer = typing.Tuple[typing.Any, typing.Any, typing.Any, typing.Any]


class Sentence: ...


def recomputeNode(thPtr: TheoryPointer) -> LibEnv: ...


def loadLibrary(path: str, opts: HetcatsOpts) -> IO[Result[typing.Tuple[LibName, LibEnv]]]: ...


def getGraphForLibrary(n: LibName, e: LibEnv) -> DGraph: ...


def automatic(name: LibName, env: LibEnv) -> LibEnv: ...


def globalSubsume(name: LibName, env: LibEnv) -> LibEnv: ...


def globalDecomposition(name: LibName, env: LibEnv) -> LibEnv: ...


def localInference(name: LibName, env: LibEnv) -> LibEnv: ...


def localDecomposition(name: LibName, env: LibEnv) -> LibEnv: ...


def compositionProveEdges(name: LibName, env: LibEnv) -> LibEnv: ...


def conservativity(name: LibName, env: LibEnv) -> LibEnv: ...


def automaticHideTheoremShift(name: LibName, env: LibEnv) -> LibEnv: ...


def theoremHideShift(name: LibName, env: LibEnv) -> LibEnv: ...


def computeColimit(name: LibName, env: LibEnv) -> LibEnv: ...


def normalForm(name: LibName, env: LibEnv) -> LibEnv: ...


def triangleCons(name: LibName, env: LibEnv) -> LibEnv: ...


def freeness(name: LibName, env: LibEnv) -> LibEnv: ...


def libFlatImports(name: LibName, env: LibEnv) -> LibEnv: ...


def libFlatDUnions(name: LibName, env: LibEnv) -> LibEnv: ...


def libFlatRenamings(name: LibName, env: LibEnv) -> LibEnv: ...


def libFlatHiding(name: LibName, env: LibEnv) -> LibEnv: ...


def libFlatHeterogen(name: LibName, env: LibEnv) -> LibEnv: ...


def qualifyLibEnv(name: LibName, env: LibEnv) -> LibEnv: ...
