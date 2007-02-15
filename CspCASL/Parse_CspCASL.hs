-- Parse_CspCASL.hs
--
-- WIP parser for CSP-CASL.
-- 
-- Maintainer: Andy Gimblett <a.m.gimblett@swan.ac.uk>
--
-- Changelog:
--  2005.11.04.1239 AMG v1.0
--                      Created (new version of CSP-CASL parser).

{- Parse_CspCASL.hs -- WIP parser for CSP-CASL.

This module contains a work-in-progress parser for a subset of
CSP-CASL.

2005.11.04 AMG

-}

module CspCASL.Parse_CspCASL (
    basicCspCaslSpec,
    old_parse_CspCASL_C_Spec
) where

import Text.ParserCombinators.Parsec

import CASL.Parse_AS_Basic (basicSpec)
import Common.AnnoState (AParser, asKey)
import Common.Keywords (endS)

import CspCASL.AS_CspCASL
import CspCASL.AS_CspCASL_Process
import CspCASL.CspCASL_Keywords
import CspCASL.Parse_CspCASL_Process (csp_casl_process)

basicCspCaslSpec :: AParser st BASIC_CSP_CASL_SPEC
-- The following is horrible, since if the spec _does_ end with "end",
-- it'll be parsed twice, the first time failing.  Alas, the more
-- sensible version (afterwards, commented out), doesn't work, and I
-- don't know why not.
basicCspCaslSpec = try (do asKey dataS
                           d <- dataDefn
                           asKey processS
                           p <- processDefn
                           eof
                           return (Basic_Csp_Casl_Spec d p)
                       )
                   <|> (do asKey dataS
                           d <- dataDefn
                           asKey processS
                           p <- processDefn
                           (asKey endS)
                           eof
                           return (Basic_Csp_Casl_Spec d p)
                       )

--cspCaslSpec = do asKey dataS
--                 d <- dataDefn
--                 asKey processS
--                 p <- processDefn
--                 (asKey endS)
--                 (try eof)
--                 return (Csp_Casl_Spec d p)

dataDefn :: AParser st DATA_DEFN
dataDefn = do d <- basicSpec csp_casl_keywords
              return (Spec d)

processDefn :: AParser st PROCESS
processDefn = do p <- csp_casl_process
                 return p



-- Hets compatability machinery, to be removed when I've completely
-- disentangled it.

old_parse_CspCASL_C_Spec :: AParser st OLD_CSP_CASL_SPEC
old_parse_CspCASL_C_Spec = do { return (Old_CspCASL_Spec (Channel_items []) (Process Skip))
                       }

