-----------------------------------------------------------------------------
-- StaticMaybe:		Static environment for Maybe
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

module TypeChecker.StaticMaybe(module TypeChecker.StaticPrelude, module TypeChecker.StaticMaybe) where
import TypeChecker.Static
import TypeChecker.StaticPrelude

maybeClasses = Just

-----------------------------------------------------------------------------
