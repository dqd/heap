{-
 -
 - Hasky, the Haskell interpreter
 - by Pavel Dvorak 2008-9
 -
 - Faculty of Informatics, Masaryk University
 -
 -}

-- | Type evaluation
module Type (showType) where

import Parser
import Helpers
import Modules
import Data.Map
import Data.List
import Data.Char
import TypeChecker.Id
import TypeChecker.Kind
import TypeChecker.Type
import TypeChecker.Subst
import TypeChecker.Pred
import TypeChecker.Scheme
import TypeChecker.Assump
import TypeChecker.TIMonad
import TypeChecker.Infer
import TypeChecker.Lit
import TypeChecker.Pat
import TypeChecker.StaticPrelude
import TypeChecker.TIMain
import Language.Haskell.Syntax
import Language.Haskell.Pretty

{-|
  Search the type of the function.
-}
getTypeSig :: String -> String -> Modules -> Either String HsQualType
getTypeSig mod fun (Modules m f) =
    case Data.Map.lookup fun f of
         Just  x -> if not (Data.List.null mod) && mod `elem` x
                       then funSigToExpSig $ getFunType fun $ m ! mod
                       else if Data.List.null  mod && length x /= 1
                               then Left  $ unambiguousFunction fun x
                               else funSigToExpSig $ getFunType
                                    fun $ m ! (head x)
         Nothing -> Left sourceCodeNotFound

{-|
  Get the type part from the type signature.
-}
funSigToExpSig :: Either String HsDecl -> Either String HsQualType
funSigToExpSig (Right (HsTypeSig _ _ qual)) = Right $ qual
funSigToExpSig (Left                     x) = Left x

{-|
  Try to find out the type of the entered expression.
-}
parseType :: HsExp -> Modules -> Either String HsQualType
parseType (HsVar    (Qual mod fun)) m =
    getTypeSig (moduleName mod) (identName fun) m
parseType (HsVar      (UnQual fun)) m =
    getTypeSig ""               (identName fun) m
parseType (HsCon  (Special HsCons)) m =
    Right $ noCons (HsTyFun (HsTyVar (HsIdent "a"))
                   (HsTyFun (HsTyApp (HsTyCon (Special HsListCon))
                   (HsTyVar (HsIdent "a"))) (HsTyApp (HsTyCon
                   (Special HsListCon)) (HsTyVar (HsIdent "a")))))

-- Data constructors are not ready yet.
-- parseType (HsCon    (Qual mod con)) m = Left $ show con
-- parseType (HsCon      (UnQual con)) m = Left $ show con

parseType (HsApp         exp1 exp2) m = parseApp exp1 exp2 m
parseType (HsInfixApp exp1 op exp2) m = parseInfixApp op [exp1,exp2] m
parseType (HsLit               lit) m = Right . noCons $ getLit lit
parseType (HsList               []) m =
    Right . noCons $ HsTyCon (UnQual (HsIdent "[a]"))
parseType (HsList             list) m =
    case parseType (head list) m of
         Left msg -> Left msg
         Right  x -> Right . noCons . addList $ throwCons x
parseType (HsParen               x) m = parseType x m
parseType x                         m = Left $ show x ++ " -- TODO"

{-|
  Try to find out the type of the infix application.
-}
parseInfixApp :: HsQOp -> [HsExp] -> Modules -> Either String HsQualType
parseInfixApp (HsQVarOp op) (exp1:exp2:[]) m =
    let mod = fst $ qualName op
        fun = snd $ qualName op
    in case getTypeSig mod fun m of
            Left msg -> Left msg
            Right  x -> Right . fromThihType . runTI $ tiExpr initialEnv
                        [("f" :>: (toScheme $
                                   ((TVar (Tyvar "a" Star))  `fn`
                                    (TVar (Tyvar "a" Star))) `fn`
                                    (TVar (Tyvar "a" Star))))]
                        (Ap (Ap (Var "f") (toThihLit exp1))
                                          (toThihLit exp2))

-- TODO

{-|
  Get the last element from the type declaration.
-}
typeResult :: HsType -> HsType
typeResult (HsTyFun _ r) = typeResult r
typeResult            r  = r

{-|
  Try to find out the type of the function application.
-}
parseApp :: HsExp -> HsExp -> Modules -> Either String HsQualType
parseApp (HsVar exp1) exp2 m =
    let mod = fst $ qualName exp1
        fun = snd $ qualName exp1
    in case getTypeSig mod fun m of
        Left               msg -> Left msg
        Right (HsQualType _ x) -> Right . noCons $ typeResult x
parseApp _ _               m = Left "What about it?"

{-|
  Expand the type \"a\" to the type \"[a]\".
-}
addList :: HsType -> HsType
addList t = (HsTyApp (HsTyCon (Special HsListCon)) t)

{-|
  Transform the basic Haskell monomorphic types from Language.Haskell
  to Typing Haskell in Haskell form.
-}
toThihLit :: HsExp -> Expr
toThihLit (HsLit (HsChar   c)) = (Lit (LitChar c))
toThihLit (HsLit (HsString s)) = (Lit (LitStr  s))
toThihLit (HsLit (HsInt    i)) = (Lit (LitInt  i))
toThihLit (HsLit (HsFrac   f)) = (Lit (LitRat  f))

{-|
  Transform the types from Language.Haskell to Typing Haskell
  in Haskell form.
-}
toThihSig :: HsType -> Type
toThihSig (HsTyVar x) = (TVar (Tyvar (identName x) Star))
--toThihSig (HsTyFun x y) = TODO

{-|
  Transform the return type from Typing Haskell in Haskell
  to Language.Haskell form.
-}
fromThihType :: ([Pred], Type) -> HsQualType
fromThihType ([],   t) = (HsQualType [] (fromThihT t))
fromThihType (pred, t) =
    let c = (predHead $ head pred)
    in  (HsQualType [(UnQual (HsIdent c),[HsTyVar (HsIdent "a")])]
        (HsTyVar (HsIdent "a")))

{-|
  Transform the type from Typing Haskell in Haskell
  to Language.Haskell form.
-}
fromThihT :: Type -> HsType
fromThihT (TVar (Tyvar x _)) = (HsTyVar (HsIdent x))
fromThihT (TCon (Tycon x _)) = (HsTyCon (UnQual (HsIdent x)))

{-|
  The type does not have any type constraints.
-}
noCons :: HsType -> HsQualType
noCons x = (HsQualType [] x)

{-|
  Throw away the type constraints.
-}
throwCons :: HsQualType -> HsType
throwCons (HsQualType _ t) = t

{-|
  Get the name of the basic Haskell monomorphic types from literals.
-}
parseLit :: HsLiteral -> String
parseLit (HsChar   _) = "Char"
parseLit (HsString _) = "String"
parseLit (HsInt    _) = "Int"
parseLit (HsFrac   _) = "Double"

{-|
  Get the basic Haskell monomorphic types from literals.
-}
getLit :: HsLiteral -> HsType
getLit l = HsTyCon (UnQual (HsIdent (parseLit l)))

{-|
  Create the whole type signature from the expression and its type.
-}
makeTypeSig :: String -> HsQualType -> HsExp
makeTypeSig x y = HsExpTypeSig (SrcLoc "" 0 0)
                  (HsVar (UnQual (HsIdent x))) y

{-|
  Wrapper that tries to get the type of the expression.
-}
callParse :: HsExp -> String -> Modules -> Either String HsExp
callParse exp name m = case parseType exp m of
                            Left msg -> Left msg
                            Right  t -> Right $ makeTypeSig name t

{-|
  Get the name of the function/constructor.
-}
typeName :: HsType -> String
typeName (HsTyVar name) = identName name
typeName (HsTyCon name) = let n = qualName name in fst n ++ snd n
typeName              _ = ""

{-|
  Get the name from the module.
-}
moduleName :: Module -> String
moduleName (Module mod) = mod

{-|
  Get the name from the identifier.
-}
identName :: HsName -> String
identName (HsIdent ident) = ident
identName (HsSymbol  sym) = sym

{-|
  Get the module and th name of the function from the qualified name.
-}
qualName :: HsQName -> (String,String)
qualName (Qual  mod fun) = (moduleName mod, identName fun)
qualName (UnQual    fun) = ("",             identName fun)

{-|
  Show type signature of the desired function.
-}
showType :: String -> Modules -> String
showType s ms =
    case parseString s of
         Left msg -> msg
         Right  x -> case callParse (getResult . head $ getDecl x)
                                    (drop 5 s) ms of
                          Left msg -> msg
                          Right  t -> trim $ prettyPrint t
