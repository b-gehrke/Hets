
{---
  HetCATS/hetcats/WriteFn.hs
  @version $Id$
  @author Klaus L&uuml;ttich<BR>
  Year:   2002
  <p>
  This module provides functions to write a pretty printed abstract
  syntax and all the other formats.
  </p>
-}
module WriteFn where

import Options

import Common.Utils

import System.IO
import Syntax.Print_HetCASL
import Syntax.AS_Library (LIB_DEFN(), LIB_NAME()) 
import Syntax.GlobalLibraryAnnotations
import Version
import Common.ConvertGlobalAnnos
import Common.ATerm.Lib
import qualified Common.Lib.Map as Map

import Static.DevGraph
import ATC.DevGraph
import Common.SimpPretty (SDoc, TextDetails(..), fullRender)
-- for debugging
import Debug.Trace

{---
  Write the given LIB_DEFN in every format that HetcatsOpts includes.
  Filenames are determined by the output formats.
  @param opt - Options Either default or given on the comandline
  @param ld  - a LIB_DEFN read as ATerm or parsed
-}
write_LIB_DEFN :: FilePath -> HetcatsOpts -> LIB_DEFN -> IO ()
write_LIB_DEFN file opt ld = sequence_ $ map write_type $ outtypes opt
    where
    write_type :: OutType -> IO ()
    write_type t = 
        case t of 
            HetCASLOut OutASTree OutAscii -> printAscii t
	    PrettyOut PrettyAscii -> printAscii t 
            PrettyOut PrettyLatex -> do
                putIfVerbose opt 3 ("Generating OutType: " ++ (show t))
                write_casl_latex opt (casl_latex_filename file opt) ld
            _ -> do putStrLn ( "Error: the OutType \"" ++ 
                        show t ++ "\" is not implemented")
                    return ()
    printAscii ty = do
                putIfVerbose opt 3 ("Generating OutType: " ++ (show ty))
                write_casl_asc opt (casl_asc_filename file opt) ld
{---
  Produces the filename of the pretty printed CASL-file.
  @param opt   - Options from the command line 
  @return path - full path to the generated file
-}
casl_asc_filename :: FilePath -> HetcatsOpts -> FilePath
casl_asc_filename file opt =
    let (base,_,_) = fileparse [".casl",".tree.gen_trm"] file
    in (outdir opt) ++ "/" ++ base ++ ".pp.casl"
      -- maybe an optin out-file is better

write_casl_asc :: HetcatsOpts -> FilePath -> LIB_DEFN -> IO ()
write_casl_asc opt oup ld =
    do hout <- openFile oup WriteMode
       putIfVerbose opt 3 (show (printText0_eGA (initGlobalAnnos ld)))
       hPutStr hout $ printLIB_DEFN_text ld

casl_latex_filename :: FilePath -> HetcatsOpts -> FilePath
casl_latex_filename file opt =
    let (base,_,_) = fileparse [".casl",".tree.gen_trm"] file
    in (outdir opt) ++ "/" ++ base ++ ".pp.tex"
      -- maybe an optin out-file is better

debug_latex_filename :: FilePath -> FilePath
debug_latex_filename = (\(b,p,_) -> p++ b ++ ".debug.tex") . 
                       fileparse [".pp.tex"]

write_casl_latex :: HetcatsOpts -> FilePath -> LIB_DEFN -> IO ()
write_casl_latex opt oup ld =
    do hout <- openFile oup WriteMode
       putIfVerbose opt 3 (show (printText0_eGA (initGlobalAnnos ld)))
       hPutStr hout $ printLIB_DEFN_latex ld
       hClose hout
       doIfVerbose opt 5
        (do dout <- openFile (debug_latex_filename oup) WriteMode
            hPutStr dout $ printLIB_DEFN_debugLatex ld
            hClose dout)
       return ()

writeShATermFile :: (ATermConvertible a) => FilePath -> a -> IO ()
writeShATermFile fp atcon = writeFile fp $ toShATermString atcon 

writeShATermFileSDoc :: (ATermConvertible a) => FilePath -> a -> IO ()
writeShATermFileSDoc fp atcon =
    do let sDoc = writeSharedATermSDoc (versionedATermTable atcon)
       h <- openFile fp WriteMode
       hPutSDoc h sDoc
       hClose h

hPutSDoc :: Handle -> SDoc -> IO ()
hPutSDoc h sd = fullRender hPutTD (return ()) sd
    where hPutTD :: TextDetails -> IO () -> IO ()
	  hPutTD td io = case td of
			 Chr  c -> hPutChar h c >> io
			 Str  s -> hPutStr  h s >> io

versionedATermTable :: (ATermConvertible a) => a -> ATermTable
versionedATermTable atcon =     
    let (att0,versionnr) = toShATerm emptyATermTable hetcats_version
	(att1,aterm) = seq att0 $ toShATerm att0 atcon
    in seq att1 $ fst $ addATerm (ShAAppl "hets" [versionnr,aterm] []) att1
                           
toShATermString :: (ATermConvertible a) => a -> String
toShATermString atcon = writeSharedATerm (versionedATermTable atcon)
                        

globalContexttoShATerm :: FilePath -> GlobalContext -> IO ()
globalContexttoShATerm fp gc = writeShATermFileSDoc fp gc

rmSuffix :: String -> String
rmSuffix = reverse . tail . snd . break (=='.') . reverse

writeFileInfo :: HetcatsOpts -> String -> LIB_NAME -> LibEnv -> IO()
writeFileInfo opts file ln lenv = 
  case Map.lookup ln lenv of
    Nothing -> putStrLn ("*** Error: Cannot find library "++show ln)
    Just gctx -> do
      let envFile = rmSuffix file ++ ".env"
      --return ()
      --writeFile (envFile++"-string") (show gctx)
      putIfVerbose opts 1 ("Writing "++envFile); globalContexttoShATerm envFile gctx