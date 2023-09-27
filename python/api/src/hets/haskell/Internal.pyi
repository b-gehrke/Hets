""" Auto generated python stubs for haskell module HetsAPI.Internal"""

import typing

from .custom import *
from .Prelude import *

G_0 = typing.TypeVar("G_0")  # sign
G_1 = typing.TypeVar("G_1")  # symbol
G_2 = typing.TypeVar("G_2")  # a
G_3 = typing.TypeVar("G_3")  # b
G_4 = typing.TypeVar("G_4")  # proof_tree
G_5 = typing.TypeVar("G_5")  # gr

LEdge = typing.Tuple[Node, Node, G_3]
LNode = typing.Tuple[Node, G_2]
LibEnv = Map[LibName,DGraph]

class DefinitionLink(DevGraphLinkType):
    def __init__(self, x0: DevGraphLinkKind, x1: bool, x2: bool): ...
class DevGraphLinkKind: ...
class DevGraphLinkType: ...
class LinkKindCofree(DevGraphLinkKind): ...
class LinkKindFree(DevGraphLinkKind): ...
class LinkKindGlobal(DevGraphLinkKind): ...
class LinkKindHiding(DevGraphLinkKind): ...
class LinkKindLocal(DevGraphLinkKind): ...
class TheoremLink(DevGraphLinkType):
    def __init__(self, x0: DevGraphLinkKind, x1: bool, x2: bool, x3: bool, x4: bool, x5: bool): ...
class CSConsistent(SType): ...
class CSError(SType): ...
class CSInconsistent(SType): ...
class CSTimeout(SType): ...
class CSUnchecked(SType): ...
class Cons(Conservativity): ...
class ConsStatus: ...
class Conservativity: ...
class ConsistencyStatus: ...
class DGLinkLab: ...
class DGNodeLab: ...
class DGNodeType: ...
class DGraph: ...
class Def(Conservativity): ...
class Diagnosis: ...
class Disproved(GoalStatus): ...
class ExtSign(typing.Generic[G_0, G_1]): ...
class GlobalAnnos: ...
class GoalStatus: ...
class Gr(typing.Generic[G_2, G_3]): ...
class HcOpt(HetcatsOpts):
    def __init__(self, x0: AnaType, x1: GuiType, x2: typing.List[typing.Tuple[str, str]], x3: typing.List[FilePath], x4: typing.List[SIMPLE_ID], x5: typing.List[SIMPLE_ID], x6: bool, x7: typing.List[SIMPLE_ID], x8: InType, x9: typing.List[FilePath], x10: FilePath, x11: int, x12: FilePath, x13: typing.List[OutType], x14: bool, x15: FilePath, x16: FilePath, x17: str, x18: str, x19: bool, x20: DBConfig, x21: DBContext, x22: FilePath, x23: bool, x24: int, x25: str, x26: str, x27: bool, x28: typing.List[CASLAmalgOpt], x29: bool, x30: int, x31: str, x32: bool, x33: bool, x34: bool, x35: bool, x36: typing.List[str], x37: bool, x38: Enc, x39: bool, x40: bool, x41: bool, x42: int, x43: FilePath, x44: typing.List[typing.List[str]], x45: typing.List[typing.List[str]], x46: bool, x47: bool, x48: bool, x49: bool, x50: bool, x51: str, x52: typing.List[str], x53: bool, x54: bool): ...
class HetcatsOpts: ...
class IRI: ...
class Id: ...
class Inconsistent(Conservativity): ...
class LibName: ...
class LiteralType: ...
class Mono(Conservativity): ...
class Open(GoalStatus):
    def __init__(self, x0: Reason): ...
class PCons(Conservativity): ...
class ProofState: ...
class ProofStatus(typing.Generic[G_4]): ...
class Proved(GoalStatus):
    def __init__(self, x0: bool): ...
class RTLink(RTLinkLab):
    def __init__(self, x0: RTLinkType): ...
class RTLinkLab: ...
class RTNodeLab: ...
class Result(typing.Generic[G_2]): ...
class SType: ...
class TacticScript: ...
class TimeOfDay: ...
class Token: ...
class Unknown(Conservativity):
    def __init__(self, x0: str): ...

def associativityAnnotations(x0: GlobalAnnos) -> AssocMap: ...
def consistencyStatusMessage(x0: ConsistencyStatus) -> str: ...
def consistencyStatusType(x0: ConsistencyStatus) -> SType: ...
def developmentGraphEdgeLabelId(x0: DGLinkLab) -> int: ...
def developmentGraphEdgeLabelName(x0: DGLinkLab) -> str: ...
def developmentGraphNodeLabelName(x0: DGNodeLab) -> str: ...
def displayAnnos(x0: GlobalAnnos) -> DisplayMap: ...
def getDevGraphLinkType(x0: DGLinkLab) -> DevGraphLinkType: ...
def globalAnnotations(x0: DGraph) -> GlobalAnnos: ...
def isNodeReferenceNode(x0: DGNodeLab) -> bool: ...
def linkTypeIsConservativ(x0: DevGraphLinkType) -> bool: ...
def linkTypeIsHomogenoeous(x0: DevGraphLinkType) -> bool: ...
def linkTypeIsInclusion(x0: DevGraphLinkType) -> bool: ...
def linkTypeIsPending(x0: DevGraphLinkType) -> bool: ...
def linkTypeIsProven(x0: DevGraphLinkType) -> bool: ...
def linkTypeKind(x0: DevGraphLinkType) -> DevGraphLinkKind: ...
def literalAnnos(x0: GlobalAnnos) -> LiteralAnnos: ...
def nodeTypeIsProven(x0: DGNodeType) -> bool: ...
def nodeTypeIsProvenConsistent(x0: DGNodeType) -> bool: ...
def nodeTypeIsReference(x0: DGNodeType) -> bool: ...
def optsWithAccessToken(x0: HetcatsOpts, x1: str) -> HetcatsOpts: ...
def optsWithApplyAutomatic(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithBlacklist(x0: HetcatsOpts, x1: typing.List[typing.List[str]]) -> HetcatsOpts: ...
def optsWithComputeNormalForm(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithConnectH(x0: HetcatsOpts, x1: str) -> HetcatsOpts: ...
def optsWithConnectP(x0: HetcatsOpts, x1: int) -> HetcatsOpts: ...
def optsWithCounterSparQ(x0: HetcatsOpts, x1: int) -> HetcatsOpts: ...
def optsWithDatabaseConfigFile(x0: HetcatsOpts, x1: FilePath) -> HetcatsOpts: ...
def optsWithDatabaseDoMigrate(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithDatabaseFileVersionId(x0: HetcatsOpts, x1: str) -> HetcatsOpts: ...
def optsWithDatabaseOutputFile(x0: HetcatsOpts, x1: FilePath) -> HetcatsOpts: ...
def optsWithDatabaseReanalyze(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithDatabaseSubConfigKey(x0: HetcatsOpts, x1: str) -> HetcatsOpts: ...
def optsWithDefLogic(x0: HetcatsOpts, x1: str) -> HetcatsOpts: ...
def optsWithDefSyntax(x0: HetcatsOpts, x1: str) -> HetcatsOpts: ...
def optsWithDisableCertificateVerification(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithDumpOpts(x0: HetcatsOpts, x1: typing.List[str]) -> HetcatsOpts: ...
def optsWithFileType(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithFullSign(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithFullTheories(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithHttpRequestHeaders(x0: HetcatsOpts, x1: typing.List[str]) -> HetcatsOpts: ...
def optsWithInfiles(x0: HetcatsOpts, x1: typing.List[FilePath]) -> HetcatsOpts: ...
def optsWithInteractive(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithLibdirs(x0: HetcatsOpts, x1: typing.List[FilePath]) -> HetcatsOpts: ...
def optsWithListen(x0: HetcatsOpts, x1: int) -> HetcatsOpts: ...
def optsWithLossyTrans(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithModelSparQ(x0: HetcatsOpts, x1: FilePath) -> HetcatsOpts: ...
def optsWithOutdir(x0: HetcatsOpts, x1: FilePath) -> HetcatsOpts: ...
def optsWithOutputLogicGraph(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithOutputLogicList(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithOutputToStdout(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithPidFile(x0: HetcatsOpts, x1: FilePath) -> HetcatsOpts: ...
def optsWithPrintAST(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithRecurse(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithRunMMT(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithServe(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithSpecNames(x0: HetcatsOpts, x1: typing.List[SIMPLE_ID]) -> HetcatsOpts: ...
def optsWithTransNames(x0: HetcatsOpts, x1: typing.List[SIMPLE_ID]) -> HetcatsOpts: ...
def optsWithUncolored(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithUnlit(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithUrlCatalog(x0: HetcatsOpts, x1: typing.List[typing.Tuple[str, str]]) -> HetcatsOpts: ...
def optsWithUseLibPos(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithVerbose(x0: HetcatsOpts, x1: int) -> HetcatsOpts: ...
def optsWithViewNames(x0: HetcatsOpts, x1: typing.List[SIMPLE_ID]) -> HetcatsOpts: ...
def optsWithWhitelist(x0: HetcatsOpts, x1: typing.List[typing.List[str]]) -> HetcatsOpts: ...
def optsWithXmlFlag(x0: HetcatsOpts, x1: bool) -> HetcatsOpts: ...
def optsWithXupdate(x0: HetcatsOpts, x1: FilePath) -> HetcatsOpts: ...
def precedenceAnnotations(x0: GlobalAnnos) -> PrecedenceGraph: ...
def prefixMap(x0: GlobalAnnos) -> PrefixMap: ...
def referencedNodeLibName(x0: DGNodeLab) -> LibName: ...
def tacticScriptContent(x0: TacticScript) -> str: ...
def accessToken(x0: HetcatsOpts) -> str: ...
def analysis(x0: HetcatsOpts) -> AnaType: ...
def applyAutomatic(x0: HetcatsOpts) -> bool: ...
def blacklist(x0: HetcatsOpts) -> typing.List[typing.List[str]]: ...
def caslAmalg(x0: HetcatsOpts) -> typing.List[CASLAmalgOpt]: ...
def computeNormalForm(x0: HetcatsOpts) -> bool: ...
def connectH(x0: HetcatsOpts) -> str: ...
def connectP(x0: HetcatsOpts) -> int: ...
def conservativityUnknownReason(x0: Conservativity) -> str: ...
def counterSparQ(x0: HetcatsOpts) -> int: ...
def databaseConfig(x0: HetcatsOpts) -> DBConfig: ...
def databaseConfigFile(x0: HetcatsOpts) -> FilePath: ...
def databaseContext(x0: HetcatsOpts) -> DBContext: ...
def databaseDoMigrate(x0: HetcatsOpts) -> bool: ...
def databaseFileVersionId(x0: HetcatsOpts) -> str: ...
def databaseOutputFile(x0: HetcatsOpts) -> FilePath: ...
def databaseReanalyze(x0: HetcatsOpts) -> bool: ...
def databaseSubConfigKey(x0: HetcatsOpts) -> str: ...
def defLogic(x0: HetcatsOpts) -> str: ...
def defSyntax(x0: HetcatsOpts) -> str: ...
def defaultHetcatsOpts() -> HetcatsOpts: ...
def diags(x0: Result[G_2]) -> typing.List[Diagnosis]: ...
def disableCertificateVerification(x0: HetcatsOpts) -> bool: ...
def dumpOpts(x0: HetcatsOpts) -> typing.List[str]: ...
def fileType(x0: HetcatsOpts) -> bool: ...
def fromJust(x0: Maybe[G_2]) -> G_2: ...
def fullSign(x0: HetcatsOpts) -> bool: ...
def fullTheories(x0: HetcatsOpts) -> bool: ...
def getConsOfStatus(x0: ConsStatus) -> Conservativity: ...
def getEdgeConsStatus(x0: DGLinkLab) -> ConsStatus: ...
def getFilePath(x0: LibName) -> FilePath: ...
def getLibId(x0: LibName) -> IRI: ...
def getNodeConsStatus(x0: DGNodeLab) -> ConsStatus: ...
def goalName(x0: ProofStatus[G_4]) -> str: ...
def goalStatus(x0: ProofStatus[G_4]) -> GoalStatus: ...
def goalStatusOpenReason(x0: GoalStatus) -> Reason: ...
def guiType(x0: HetcatsOpts) -> GuiType: ...
def httpRequestHeaders(x0: HetcatsOpts) -> typing.List[str]: ...
def infiles(x0: HetcatsOpts) -> typing.List[FilePath]: ...
def interactive(x0: HetcatsOpts) -> bool: ...
def intype(x0: HetcatsOpts) -> InType: ...
def ioEncoding(x0: HetcatsOpts) -> Enc: ...
def isInternalNode(x0: DGNodeLab) -> bool: ...
def isProvenConsStatusLink(x0: ConsStatus) -> bool: ...
def labEdges(x0: G_5[G_2,G_3]) -> typing.List[LEdge[G_3]]: ...
def labNodes(x0: G_5[G_2,G_3]) -> typing.List[LNode[G_2]]: ...
def libVersion(x0: LibName) -> Maybe[VersionNumber]: ...
def libdirs(x0: HetcatsOpts) -> typing.List[FilePath]: ...
def linkStatus(x0: ConsStatus) -> ThmLinkStatus: ...
def listen(x0: HetcatsOpts) -> int: ...
def locIRI(x0: LibName) -> Maybe[IRI]: ...
def lossyTrans(x0: HetcatsOpts) -> bool: ...
def maybeResult(x0: Result[G_2]) -> Maybe[G_2]: ...
def mimeType(x0: LibName) -> Maybe[str]: ...
def modelSparQ(x0: HetcatsOpts) -> FilePath: ...
def nonImportedSymbols(x0: ExtSign[G_0,G_1]) -> Set[G_1]: ...
def outdir(x0: HetcatsOpts) -> FilePath: ...
def outputLogicGraph(x0: HetcatsOpts) -> bool: ...
def outputLogicList(x0: HetcatsOpts) -> bool: ...
def outputToStdout(x0: HetcatsOpts) -> bool: ...
def outtypes(x0: HetcatsOpts) -> typing.List[OutType]: ...
def pidFile(x0: HetcatsOpts) -> FilePath: ...
def plainSign(x0: ExtSign[G_0,G_1]) -> G_0: ...
def printAST(x0: HetcatsOpts) -> bool: ...
def proofLines(x0: ProofStatus[G_4]) -> typing.List[str]: ...
def proofTree(x0: ProofStatus[G_4]) -> G_4: ...
def provenConservativity(x0: ConsStatus) -> Conservativity: ...
def recurse(x0: HetcatsOpts) -> bool: ...
def requiredConservativity(x0: ConsStatus) -> Conservativity: ...
def resultToMaybe(x0: Result[G_2]) -> Maybe[G_2]: ...
def rtl_type(x0: RTLinkLab) -> RTLinkType: ...
def rtn_diag(x0: RTNodeLab) -> str: ...
def rtn_name(x0: RTNodeLab) -> str: ...
def rtn_type(x0: RTNodeLab) -> RTNodeType: ...
def runMMT(x0: HetcatsOpts) -> bool: ...
def serve(x0: HetcatsOpts) -> bool: ...
def showConsistencyStatus(x0: Conservativity) -> str: ...
def showDoc(x0: G_2) -> ShowS: ...
def showGlobalDoc(x0: GlobalAnnos, x1: G_2) -> ShowS: ...
def specNames(x0: HetcatsOpts) -> typing.List[SIMPLE_ID]: ...
def tacticScript(x0: ProofStatus[G_4]) -> TacticScript: ...
def transNames(x0: HetcatsOpts) -> typing.List[SIMPLE_ID]: ...
def uncolored(x0: HetcatsOpts) -> bool: ...
def unlit(x0: HetcatsOpts) -> bool: ...
def urlCatalog(x0: HetcatsOpts) -> typing.List[typing.Tuple[str, str]]: ...
def useLibPos(x0: HetcatsOpts) -> bool: ...
def usedAxioms(x0: ProofStatus[G_4]) -> typing.List[str]: ...
def usedProver(x0: ProofStatus[G_4]) -> str: ...
def usedTime(x0: ProofStatus[G_4]) -> TimeOfDay: ...
def verbose(x0: HetcatsOpts) -> int: ...
def viewNames(x0: HetcatsOpts) -> typing.List[SIMPLE_ID]: ...
def whitelist(x0: HetcatsOpts) -> typing.List[typing.List[str]]: ...
def xmlFlag(x0: HetcatsOpts) -> bool: ...
def xupdate(x0: HetcatsOpts) -> FilePath: ...
