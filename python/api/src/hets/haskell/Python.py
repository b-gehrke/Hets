""" Auto generated python imports for haskell module HetsAPI.Python"""

from .base import *

from hs.HetsAPI.Python import (
    # type imports
    PyTheorySentence,
    PyTheorySentenceByName,
    LinkPointer,
    RefinementTreeLink,
    Sentence,
    SignatureJSON,
    SymbolJSON,
    TheoryPointer,
    TheorySentence,
    TheorySentenceByName,

    # class imports
    PyBasicProof,
    PyBasicProofConjectured,
    PyBasicProofGuessed,
    PyBasicProofHandwritten,
    PyComorphism,
    PyConsChecker,
    PyConsCheckingOptions,
    PyConservativityChecker,
    PyGMorphism,
    PyProofOptions,
    PyProofTree,
    PyProver,
    PyTheory,
    RefinementTreeNode,

    # function imports
    checkConservativityEdge,
    checkConservativityEdgeAndRecord,
    checkConsistency,
    checkConsistencyAndRecord,
    codomainOfGMorphism,
    comorphismDescriptionOfGMorphism,
    comorphismName,
    comorphismNameOfGMorphism,
    comorphismOfGMorphism,
    consCheckerName,
    consOptsComorphism,
    consOptsConsChecker,
    consOptsIncludeTheorems,
    consOptsTimeout,
    conservativityCheckerName,
    conservativityCheckerUsable,
    defaultConsCheckingOptions,
    defaultProofOptions,
    domainOfGMorphism,
    fstOf3,
    gMorphismToTransportType,
    getAllAxioms,
    getAllGoals,
    getAllSentences,
    getAvailableComorphisms,
    getDGNodeById,
    getProvenGoals,
    getTheoryForSelection,
    getUnprovenGoals,
    getUsableConservativityCheckers,
    getUsableConsistencyCheckers,
    getUsableProvers,
    globalTheory,
    gmorphismOfEdge,
    isGMorphismInclusion,
    logicDescriptionOfTheory,
    logicNameOfTheory,
    mkPyProofOptions,
    prettySentence,
    proofOptsAxiomsToInclude,
    proofOptsComorphism,
    proofOptsGoalsToProve,
    proofOptsProver,
    proofOptsTimeout,
    proofOptsUseTheorems,
    proveNode,
    proveNodeAndRecord,
    proverName,
    pyProofStatusOfPyBasicProof,
    recordProofResult,
    signatureOfGMorphism,
    signatureOfTheory,
    sndOf3,
    sourceLogicDescriptionName,
    sourceLogicName,
    sublogicOfPyTheory,
    targetLogicDescriptionName,
    targetLogicName,
    thd,
    theoryOfNode,
    theorySentenceBestProof,
    translateTheory,
    automatic,
    automaticHideTheoremShift,
    compositionProveEdges,
    computeColimit,
    conservativity,
    freeness,
    getAvailableSpecificationsForRefinement,
    getDevelopmentGraphNodeType,
    getEdgesFromDevelopmentGraph,
    getGraphForLibrary,
    getLEdgesFromDevelopmentGraph,
    getLNodesFromDevelopmentGraph,
    getLibraryDependencies,
    getNodesFromDevelopmentGraph,
    getRefinementTree,
    globalDecomposition,
    globalSubsume,
    isRootNode,
    libFlatDUnions,
    libFlatHeterogen,
    libFlatHiding,
    libFlatImports,
    libFlatRenamings,
    loadLibrary,
    localDecomposition,
    localInference,
    normalForm,
    qualifyLibEnv,
    recomputeNode,
    recordConservativityResult,
    rtNodeLab,
    showTheory,
    theoremHideShift,
    theorySentenceContent,
    theorySentenceGetTheoremStatus,
    theorySentenceIsAxiom,
    theorySentenceIsDefined,
    theorySentencePriority,
    theorySentenceWasTheorem,
    triangleCons,
)
