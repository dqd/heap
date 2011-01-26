-----------------------------------------------------------------------------
-- Lit:		Literals
-- 
-- Part of `Typing Haskell in Haskell', version of November 23, 2000
-- Copyright (c) Mark P Jones and the Oregon Graduate Institute
-- of Science and Technology, 1999-2000
-- 
-- This program is distributed as Free Software under the terms
-- in the file "License" that is included in the distribution
-- of this software, copies of which may be obtained from:
--             http://www.cse.ogi.edu/~mpj/thih/
-- 
-----------------------------------------------------------------------------

module TypeChecker.Lit where
import TypeChecker.Kind
import TypeChecker.Type
import TypeChecker.Pred
import TypeChecker.TIMonad
import TypeChecker.Infer

data Literal = LitInt  Integer
             | LitChar Char
             | LitRat  Rational
             | LitStr  String
	deriving (Show)
tiLit            :: Literal -> TI ([Pred],Type)
tiLit (LitChar _) = return ([], tChar)
tiLit (LitInt _)  = do v <- newTVar Star
                       return ([IsIn "Num" [v]], v)
tiLit (LitStr _)  = return ([], tString)
tiLit (LitRat _)  = do v <- newTVar Star
                       return ([IsIn "Fractional" [v]], v)

-----------------------------------------------------------------------------
