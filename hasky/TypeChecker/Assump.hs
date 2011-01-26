-----------------------------------------------------------------------------
-- Assump:	Assumptions
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

module TypeChecker.Assump where
import TypeChecker.Id
import TypeChecker.Scheme
import TypeChecker.Subst


data Assump = Id :>: Scheme
	deriving (Show)

instance Types Assump where
  apply s (i :>: sc) = i :>: (apply s sc)
  tv (i :>: sc)      = tv sc

find                 :: Monad m => Id -> [Assump] -> m Scheme
find i []             = fail ("unbound identifier: " ++ i)
find i ((i':>:sc):as) = if i==i' then return sc else find i as

-----------------------------------------------------------------------------
