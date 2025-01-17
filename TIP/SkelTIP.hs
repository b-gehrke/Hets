{-
Copyright (c) 2015, Dan Rosén
Copyright (c) 2016, Nick Smallbone

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

    * Neither the name of the copyright holder nor the names of other
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
-}
-- File generated by the BNF Converter (bnfc 2.9.4).

-- Templates for pattern matching on abstract syntax

{-# OPTIONS_GHC -fno-warn-unused-matches #-}

module TIP.SkelTIP where

import Prelude (($), Either(..), String, (++), Show, show)
import qualified TIP.AbsTIP

type Err = Either String
type Result = Err String

failure :: Show a => a -> Result
failure x = Left $ "Undefined case: " ++ show x

transUnquotedSymbol :: TIP.AbsTIP.UnquotedSymbol -> Result
transUnquotedSymbol x = case x of
  TIP.AbsTIP.UnquotedSymbol string -> failure x

transQuotedSymbol :: TIP.AbsTIP.QuotedSymbol -> Result
transQuotedSymbol x = case x of
  TIP.AbsTIP.QuotedSymbol string -> failure x

transKeyword :: TIP.AbsTIP.Keyword -> Result
transKeyword x = case x of
  TIP.AbsTIP.Keyword string -> failure x

transStart :: TIP.AbsTIP.Start -> Result
transStart x = case x of
  TIP.AbsTIP.Start decls -> failure x

transDecl :: TIP.AbsTIP.Decl -> Result
transDecl x = case x of
  TIP.AbsTIP.DeclareDatatype attrsymbol datatype -> failure x
  TIP.AbsTIP.DeclareDatatypes datatypenames datatypes -> failure x
  TIP.AbsTIP.DeclareSort attrsymbol integer -> failure x
  TIP.AbsTIP.DeclareConst attrsymbol consttype -> failure x
  TIP.AbsTIP.DeclareFun attrsymbol funtype -> failure x
  TIP.AbsTIP.DefineFun fundec expr -> failure x
  TIP.AbsTIP.DefineFunRec fundec expr -> failure x
  TIP.AbsTIP.DefineFunsRec bracketedfundecs exprs -> failure x
  TIP.AbsTIP.Formula assertion attrs expr -> failure x
  TIP.AbsTIP.FormulaPar assertion attrs par expr -> failure x

transAssertion :: TIP.AbsTIP.Assertion -> Result
transAssertion x = case x of
  TIP.AbsTIP.Assert -> failure x
  TIP.AbsTIP.Prove -> failure x

transPar :: TIP.AbsTIP.Par -> Result
transPar x = case x of
  TIP.AbsTIP.Par symbols -> failure x

transConstType :: TIP.AbsTIP.ConstType -> Result
transConstType x = case x of
  TIP.AbsTIP.ConstTypeMono type_ -> failure x
  TIP.AbsTIP.ConstTypePoly par type_ -> failure x

transInnerFunType :: TIP.AbsTIP.InnerFunType -> Result
transInnerFunType x = case x of
  TIP.AbsTIP.InnerFunType types type_ -> failure x

transFunType :: TIP.AbsTIP.FunType -> Result
transFunType x = case x of
  TIP.AbsTIP.FunTypeMono innerfuntype -> failure x
  TIP.AbsTIP.FunTypePoly par innerfuntype -> failure x

transInnerFunDec :: TIP.AbsTIP.InnerFunDec -> Result
transInnerFunDec x = case x of
  TIP.AbsTIP.InnerFunDec bindings type_ -> failure x

transFunDec :: TIP.AbsTIP.FunDec -> Result
transFunDec x = case x of
  TIP.AbsTIP.FunDecMono attrsymbol innerfundec -> failure x
  TIP.AbsTIP.FunDecPoly attrsymbol par innerfundec -> failure x

transBracketedFunDec :: TIP.AbsTIP.BracketedFunDec -> Result
transBracketedFunDec x = case x of
  TIP.AbsTIP.BracketedFunDec fundec -> failure x

transDatatypeName :: TIP.AbsTIP.DatatypeName -> Result
transDatatypeName x = case x of
  TIP.AbsTIP.DatatypeName attrsymbol integer -> failure x

transInnerDatatype :: TIP.AbsTIP.InnerDatatype -> Result
transInnerDatatype x = case x of
  TIP.AbsTIP.InnerDatatype constructors -> failure x

transDatatype :: TIP.AbsTIP.Datatype -> Result
transDatatype x = case x of
  TIP.AbsTIP.DatatypeMono innerdatatype -> failure x
  TIP.AbsTIP.DatatypePoly par innerdatatype -> failure x

transConstructor :: TIP.AbsTIP.Constructor -> Result
transConstructor x = case x of
  TIP.AbsTIP.Constructor attrsymbol bindings -> failure x

transBinding :: TIP.AbsTIP.Binding -> Result
transBinding x = case x of
  TIP.AbsTIP.Binding symbol type_ -> failure x

transLetDecl :: TIP.AbsTIP.LetDecl -> Result
transLetDecl x = case x of
  TIP.AbsTIP.LetDecl symbol expr -> failure x

transType :: TIP.AbsTIP.Type -> Result
transType x = case x of
  TIP.AbsTIP.TyVar symbol -> failure x
  TIP.AbsTIP.TyApp symbol types -> failure x
  TIP.AbsTIP.ArrowTy types -> failure x
  TIP.AbsTIP.IntTy -> failure x
  TIP.AbsTIP.RealTy -> failure x
  TIP.AbsTIP.BoolTy -> failure x

transExpr :: TIP.AbsTIP.Expr -> Result
transExpr x = case x of
  TIP.AbsTIP.Var polysymbol -> failure x
  TIP.AbsTIP.App head exprs -> failure x
  TIP.AbsTIP.Match expr cases -> failure x
  TIP.AbsTIP.Let letdecls expr -> failure x
  TIP.AbsTIP.Binder binder bindings expr -> failure x
  TIP.AbsTIP.Lit lit -> failure x

transLit :: TIP.AbsTIP.Lit -> Result
transLit x = case x of
  TIP.AbsTIP.LitInt integer -> failure x
  TIP.AbsTIP.LitNegInt integer -> failure x
  TIP.AbsTIP.LitTrue -> failure x
  TIP.AbsTIP.LitFalse -> failure x

transBinder :: TIP.AbsTIP.Binder -> Result
transBinder x = case x of
  TIP.AbsTIP.Lambda -> failure x
  TIP.AbsTIP.Forall -> failure x
  TIP.AbsTIP.Exists -> failure x

transCase :: TIP.AbsTIP.Case -> Result
transCase x = case x of
  TIP.AbsTIP.Case pattern_ expr -> failure x

transPattern :: TIP.AbsTIP.Pattern -> Result
transPattern x = case x of
  TIP.AbsTIP.Default -> failure x
  TIP.AbsTIP.ConPat symbol symbols -> failure x
  TIP.AbsTIP.SimplePat symbol -> failure x
  TIP.AbsTIP.LitPat lit -> failure x

transHead :: TIP.AbsTIP.Head -> Result
transHead x = case x of
  TIP.AbsTIP.Const polysymbol -> failure x
  TIP.AbsTIP.At -> failure x
  TIP.AbsTIP.IfThenElse -> failure x
  TIP.AbsTIP.And -> failure x
  TIP.AbsTIP.Or -> failure x
  TIP.AbsTIP.Not -> failure x
  TIP.AbsTIP.Implies -> failure x
  TIP.AbsTIP.Equal -> failure x
  TIP.AbsTIP.Distinct -> failure x
  TIP.AbsTIP.NumAdd -> failure x
  TIP.AbsTIP.NumSub -> failure x
  TIP.AbsTIP.NumMul -> failure x
  TIP.AbsTIP.NumDiv -> failure x
  TIP.AbsTIP.IntDiv -> failure x
  TIP.AbsTIP.IntMod -> failure x
  TIP.AbsTIP.NumGt -> failure x
  TIP.AbsTIP.NumGe -> failure x
  TIP.AbsTIP.NumLt -> failure x
  TIP.AbsTIP.NumLe -> failure x
  TIP.AbsTIP.NumWiden -> failure x

transPolySymbol :: TIP.AbsTIP.PolySymbol -> Result
transPolySymbol x = case x of
  TIP.AbsTIP.NoAs symbol -> failure x
  TIP.AbsTIP.As symbol types -> failure x

transAttrSymbol :: TIP.AbsTIP.AttrSymbol -> Result
transAttrSymbol x = case x of
  TIP.AbsTIP.AttrSymbol symbol attrs -> failure x

transAttr :: TIP.AbsTIP.Attr -> Result
transAttr x = case x of
  TIP.AbsTIP.NoValue keyword -> failure x
  TIP.AbsTIP.Value keyword symbol -> failure x

transSymbol :: TIP.AbsTIP.Symbol -> Result
transSymbol x = case x of
  TIP.AbsTIP.Unquoted unquotedsymbol -> failure x
  TIP.AbsTIP.Quoted quotedsymbol -> failure x
