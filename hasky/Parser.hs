{-
 -
 - Hasky, the Haskell interpreter
 - by Pavel Dvorak 2008-9
 -
 - Faculty of Informatics, Masaryk University
 -
 -}

-- | Parsing module
module Parser
( parseString
, parseFile
, parseShow
, getDecl
, getResult
, getImports
, getFunctions
, getModuleName
, getFunBody
, getFunType
) where

import Data.List
import Language.Haskell.Parser
import Language.Haskell.Syntax

{-|
  Take a string and parse it.
-}
parseString :: String -> Either String HsModule
parseString = parse . parseModule

{-|
  Take a name of a module, content of the module and parse it.
-}
parseFile :: String -> String -> Either String HsModule
parseFile name content =
    parse $ parseModuleWithMode (ParseMode name) content

{-|
  Load the expression or throw an error unless is correct.
-}
parse :: ParseResult HsModule -> Either String HsModule
parse (ParseFailed srcLoc notice) = Left  $ notice ++ position
    where position = " (" ++ (show $ srcLine      srcLoc) ++
                     ", " ++ (show $ adjustColumn srcLoc) ++ ")"
parse (ParseOk value)             = Right $ value

{-|
  Adjust value of the current column location.
  Default parse assignment is \"it = \" (length 5).
-}
adjustColumn :: SrcLoc -> Int
adjustColumn srcLoc
    | srcFilename srcLoc == "<unknown>" &&
      srcColumn   srcLoc >= 6 = srcColumn srcLoc - 5
    | otherwise               = srcColumn srcLoc

{-|
  Show the result of parsing.
-}
parseShow :: Either String HsModule -> String
parseShow (Left  msg) = msg
parseShow (Right mod) = showResult $ getDecl mod

{-|
  Throw away the unimportant parts and get module declarations.
-}
getDecl :: HsModule -> [HsDecl]
getDecl (HsModule _ _ _ _ decl) = decl

{-|
  Export declarations from the classes and instances.
-}
getRidOfClass :: HsDecl -> [HsDecl]
getRidOfClass (HsClassDecl _ _ _ _ decl) = decl
getRidOfClass (HsInstDecl  _ _ _ _ decl) = decl
getRidOfClass                      decl  = [decl]

{-|
   Throw away the unimportant parts and get module declarations without
   classes and instances.
-}
getCleanDecl :: HsModule -> [HsDecl]
getCleanDecl (HsModule _ _ _ _ decl) = concatMap getRidOfClass decl

{-|
  Get a list of imported modules in a Haskell modules.
-}
getImports :: HsModule -> [String]
getImports (HsModule _ _ _ imps _) = [getModule i | i <- imps]

{-|
  Throw away the unimportant parts and get name of the imported module.
-}
getModule :: HsImportDecl -> String
getModule (HsImportDecl _ mod _ _ _) = case mod of Module m -> m

{-|
  Throw away the unimportant parts and get actual module name.
-}
getModuleName :: HsModule -> String
getModuleName (HsModule _ mod _ _ _) = case mod of Module m -> m

{-|
  Get names of all defined (either body or type is enough)
  functions in the module.
-}
getFunctions :: HsModule -> [String]
getFunctions m = nub ((map getBodyName $ getCleanDecl m)
                   ++ concat (map getTypeName $ getCleanDecl m))

{-|
  Get definition of the requested function.
-}
getFunBody :: String -> HsModule -> [HsDecl]
getFunBody s m = filter (\x -> s == getBodyName x) $ getCleanDecl m

{-|
  Get name of the function definition.
-}
getBodyName :: HsDecl -> String
getBodyName (HsFunBind   matches) = getName . getMatch $ head matches
getBodyName (HsPatBind _ pat _ _) = getName $ getPat pat
getBodyName _ = ""

{-|
  Get type signature of the requested function. If it is not
  available, return the error message.
-}
getFunType :: String -> HsModule -> Either String HsDecl
getFunType s m =
    let dec = filter (\x -> s `elem` getTypeName x) $ getCleanDecl m
    in  if null dec
           then Left "Function has not declared any type."
           else Right $ head dec

{-|
   Get name of the function type declaration.
-}
getTypeName :: HsDecl -> [String]
getTypeName (HsTypeSig _ names _)            = map getName names
#if __GLASGOW_HASKELL__ >= 608
getTypeName (HsForeignImport _ _ _ _ name _) = [getName name]
#endif
getTypeName _ = [""]

{-|
  Transform name to a string.
-}
getName :: HsName -> String
getName (HsIdent  x) = x
getName (HsSymbol x) = x

{-|
  Throw away the unimportant parts and get name from the match.
-}
getMatch :: HsMatch -> HsName
getMatch (HsMatch _ name _ _ _) = name

{-|
  Throw away the unimportant parts and get name from the pattern.
-}
getPat :: HsPat -> HsName 
getPat (HsPVar name) = name

{-|
  Show declaration result.
-}
showResult :: [HsDecl] -> String
showResult [] = ""
showResult x  = (showExp              $ getResult (head x)) ++
                (concatMap (("; " ++) . showDecl) (tail x))

{-|
  Throw away the unimportant parts and get parsing result.
-}
getResult :: HsDecl -> HsExp
getResult (HsPatBind _ _ (HsUnGuardedRhs result) _) = result
getResult _                                         = error "parse failed"

{-|
  Throw away the unimportant parts and show declaration.
-}
showDecl :: HsDecl -> String
showDecl (HsTypeDecl _ name1 name2 hype)                     =
    "HsTypeDecl " ++ show name1 ++ " " ++ show name2
    ++ " " ++ show hype 
showDecl (HsDataDecl _ context name1 name2 conDecl qName)    =
    "HsDataDecl " ++ show context ++ " "
    ++ show name1 ++ " " ++ show name2 ++ " ["
    ++ concatMap showConDecl conDecl ++ "] " ++ show qName
showDecl (HsInfixDecl _ assoc int op)                        =
    "HsInfixDecl " ++ show assoc ++ " "
    ++ show int ++ " " ++ show op
showDecl (HsNewTypeDecl _ context name1 name2 conDecl qName) =
    "HsNewTypeDecl " ++ show context ++ " " ++ show name1
    ++ " " ++ show name2 ++ " " ++ showConDecl conDecl
    ++ show qName
showDecl (HsClassDecl _ context name1 name2 decl)            =
    "HsClassDecl "  ++ show context ++ " " ++ show name1
    ++ " " ++ show name2 ++ " ["
    ++ concatMap showDecl decl ++ "]"
showDecl (HsInstDecl _ context qName hype decl)              =
    "HsInstDecl " ++ show context ++ " " ++ show qName
    ++ " " ++ show hype ++ " ["
    ++ concatMap showDecl decl ++ "]"
showDecl (HsDefaultDecl _ hype)                              =
    "HsDefaultDecl " ++ show hype
showDecl (HsTypeSig _ name qualType)                         =
    "HsTypeSig " ++ show name ++ " " ++ show qualType
showDecl (HsFunBind match)                                   =
    "HsFunBind [" ++ concatMap showMatch match ++ "]"
showDecl (HsPatBind _ pat rhs decl)                          =
    "HsPatBind " ++ show pat ++ " "
    ++ showRhs rhs  ++ " ["
    ++ concatMap showDecl decl ++ "]"
#if __GLASGOW_HASKELL__ >= 608
showDecl (HsForeignImport _ str1 safety str2 name hype)      =
    "HsForeignImport "  ++  str1  ++ " " ++ show safety ++ " "
    ++ str2 ++ " " ++  show name  ++ " " ++ show hype
showDecl (HsForeignExport _ str1 str2 name hype)             =
    "HsForeignExport " ++ str1 ++ " " ++ str2
    ++ " " ++ show name ++ " " ++ show hype
#endif

{-|
  Throw away the unimportant parts and show constructor declaration.
-}
showConDecl :: HsConDecl -> String
showConDecl (HsConDecl _ name hype) = show name ++ " " ++ show hype

{-|
  Throw away the unimportant parts and show clauses of a function binding.
-}
showMatch :: HsMatch -> String
showMatch (HsMatch _ name pat rhs decl) = show name ++ " " ++ show pat
                                          ++ " " ++ showRhs rhs ++ " ["
                                          ++ concatMap showDecl decl
                                          ++ "]"

{-|
  Throw away the unimportant parts and show unguarded right hand side.
-}
showRhs :: HsRhs -> String
showRhs (HsUnGuardedRhs  exp) = "HsUnGuardedRhs " ++ showExp exp
showRhs (HsGuardedRhss  grhs) = "HsGuardedRhss ["
                                ++ concatMap showGrhs grhs ++ "]"

{-|
  Throw away the unimportant parts and show guarded right hand side.
-}
showGrhs :: HsGuardedRhs -> String
showGrhs (HsGuardedRhs _ exp1 exp2) = "HsGuardedRhs " ++ showExp exp1
                                      ++ " " ++ showExp exp2

{-|
  Throw away the unimportant parts and show Haskell expression.
-}
showExp :: HsExp -> String
showExp (HsLambda     _ pat exp)          =
    "HsLambda " ++ show pat
    ++ " " ++ showExp exp
showExp (HsExpTypeSig _ exp qualType)     =
    "HsExpTypeSig " ++ showExp exp
    ++ show qualType
showExp (HsDo stmt)                       =
    "HsDo [" ++ concatMap showStmt stmt ++ "]"
showExp (HsListComp exp stmt)             =
    "HsListComp " ++ showExp exp
    ++ " [" ++ concatMap showStmt stmt ++ "]"
showExp (HsInfixApp exp1 qop exp2)        =
    "HsInfixApp " ++ showExp exp1
    ++ " " ++ show qop
    ++ " " ++ showExp exp2
showExp (HsApp exp1 exp2)                 =
    "HsApp " ++ showExp exp1 ++ " " ++ showExp exp2
showExp (HsNegApp exp)                    =
    "HsNegApp " ++ showExp exp
showExp (HsLet decl exp)                  =
    "HsLet [" ++ concatMap showDecl decl ++ "] "
    ++ showExp exp
showExp (HsIf exp1 exp2 exp3)             =
    "HsIf " ++ showExp exp1
    ++ " " ++  showExp exp2
    ++ " " ++  showExp exp3
showExp (HsCase exp alt)                  =
    "HsCase " ++ showExp exp
    ++ " [" ++ show alt ++ "]"
showExp (HsTuple exp)                     =
    "HsTuple ["
    ++ concatMap showExp exp ++ "]"
showExp (HsList exp)                      =
    "HsList ["
    ++ concatMap showExp exp ++ "]"
showExp (HsParen exp)                     =
    "HsParen " ++ showExp exp
showExp (HsLeftSection exp qop)           =
    "HsLeftSection " ++ showExp exp
    ++ " " ++ show qop
showExp (HsRightSection qop exp)          =
    "HsRightSection " ++ show qop
     ++ " " ++ showExp exp
showExp (HsRecUpdate exp field)           =
    "HsRecUpdate " ++ showExp exp
    ++ " " ++ show field
showExp (HsEnumFrom exp)                  =
    "HsEnumFrom " ++ showExp exp
showExp (HsEnumFromTo exp1 exp2)          =
    "HsEnumFromTo " 
    ++ showExp exp1 ++ " "
    ++ showExp exp2
showExp (HsEnumFromThen exp1 exp2)        =
    "HsEnumFromThen " 
    ++ showExp exp1 ++ " "
    ++ showExp exp2
showExp (HsEnumFromThenTo exp1 exp2 exp3) =
    "HsEnumFromThenTo "
    ++ showExp exp1 ++ " "
    ++ showExp exp2 ++ " "
    ++ showExp exp3
showExp (HsAsPat name exp)                =
    "HsAsPat " ++ show name
    ++ " " ++ showExp exp
showExp (HsIrrPat exp)                    =
    "HsIrrPat " ++ showExp exp
showExp x                                 = show x

{-|
  Throw away the unimportant parts and show Haskell statement.
-}
showStmt :: HsStmt -> String
showStmt (HsGenerator _ pat exp) = "HsGenerator " ++ show pat
                                   ++ " " ++ showExp exp
showStmt (HsQualifier       exp) = "HsQualifier " ++ showExp   exp
showStmt (HsLetStmt        decl) = "HsLetStmt ["
                                   ++ concatMap showDecl decl ++ "]"
