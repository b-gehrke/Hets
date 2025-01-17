{- |
Module      :  ./OWL2/ParseOWL.hs
Copyright   :  Heng Jiang, Uni Bremen 2004-2007
License     :  GPLv2 or higher, see LICENSE.txt

Maintainer  :  Christian.Maeder@dfki.de
Stability   :  provisional
Portability :  non-portable 

analyse OWL files by calling the external Java parser.
-}

module OWL2.ParseOWL (parseOWL, convertOWL) where

import OWL2.AS

import qualified Data.ByteString as BS
import Data.List
import Data.Maybe ()
import qualified Data.Map as Map

import Common.XmlParser
import Common.ProverTools
import Common.Result
import Common.ResultT
import Common.Utils

import Control.Monad
import Control.Monad.Trans
import qualified Control.Monad.Fail as Fail

import OWL2.XML
import OWL2.Rename (unifyDocs)

import System.Directory
import System.Exit
import System.FilePath

import Text.XML.Light hiding (QName)

-- | call for owl parser (env. variable $HETS_OWL_TOOLS muss be defined)
parseOWL :: Bool                  -- ^ Sets Option.quick
         -> FilePath              -- ^ local filepath or uri
         -> ResultT IO (Map.Map String String, [OntologyDocument]) -- ^ map: uri -> OntologyFile
parseOWL quick fullFileName = do
    let fn = tryToStripPrefix "file://" fullFileName
    tmpFile <- lift $ getTempFile "" "owlTemp.xml"
    (exitCode, _, errStr) <- parseOWLAux quick fn ["-o", "xml", tmpFile]
    case (exitCode, errStr) of
      (ExitSuccess, "") -> do
          cont <- lift $ BS.readFile tmpFile
          lift $ removeFile tmpFile
          parseProc cont
      _ -> Fail.fail $ "process stop! " ++ shows exitCode "\n" ++ errStr

parseOWLAux :: Bool         -- ^ Sets Option.quick
         -> FilePath        -- ^ local filepath or uri
         -> [String]        -- ^ arguments for java parser
         -> ResultT IO (ExitCode, String, String)
parseOWLAux quick fn args = do
    let jar = "OWL2Parser.jar"
    (hasJar, toolPath) <- lift $ check4HetsOWLjar jar
    if hasJar
      then lift $ executeProcess "java" (["-Djava.util.logging.config.class=JulConfig", "-Dorg.semanticweb.owlapi.model.parameters.ConfigurationOptions.REPORT_STACK_TRACES=false", "-jar", toolPath </> jar]
        ++ args ++ [fn] ++ ["-qk" | quick]) ""
      else Fail.fail $ jar
        ++ " not found, check your environment variable: " ++ hetsOWLenv

-- | converts owl file to desired syntax using owl-api
convertOWL :: FilePath -> String -> IO String
convertOWL fn tp = do
  Result ds mRes <- runResultT
    $ parseOWLAux False fn ["-o-sys", tp]
  case mRes of
    Just (exitCode, content, errStr) -> case (exitCode, errStr) of
      (ExitSuccess, "") -> return content
      _ -> error $ "process stop! " ++ shows exitCode "\n" ++ errStr
    _ -> error $ showRelDiags 2 ds

parseProc :: BS.ByteString
              -> ResultT IO (Map.Map String String, [OntologyDocument])
parseProc str = do
  res <- lift $ parseXml str
  case res of
    Left err -> Fail.fail err
    Right el -> let
      es = elChildren el
      mis = concatMap (filterElementsName $ isSmth "Missing") es
      in do
        unless (null mis) . liftR . justWarn () $ "Missing imports: "
            ++ intercalate ", " (map strContent mis)
        return (Map.empty, unifyDocs . map (xmlBasicSpec Map.empty)
                       $ concatMap (filterElementsName $ isSmth "Ontology") es)
