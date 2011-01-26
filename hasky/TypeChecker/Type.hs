-----------------------------------------------------------------------------
-- Type:		Types
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

module TypeChecker.Type where 
import TypeChecker.Id
import TypeChecker.Kind


data Type  = TVar Tyvar | TCon Tycon | TAp  Type Type | TGen Int
             deriving (Show, Eq)

data Tyvar = Tyvar Id Kind
             deriving (Show, Eq)

data Tycon = Tycon Id Kind
             deriving (Show, Eq)

tUnit    = TCon (Tycon "()" Star)
tChar    = TCon (Tycon "Char" Star)
tInt     = TCon (Tycon "Int" Star)
tInteger = TCon (Tycon "Integer" Star)
tFloat   = TCon (Tycon "Float" Star)
tDouble  = TCon (Tycon "Double" Star)

tList    = TCon (Tycon "[]" (Kfun Star Star))
tArrow   = TCon (Tycon "(->)" (Kfun Star (Kfun Star Star)))
tTuple2  = TCon (Tycon "(,)" (Kfun Star (Kfun Star Star)))

tTuple3
 = TCon (Tycon "(,,)" (Kfun Star (Kfun Star (Kfun Star Star))))
tTuple4
 = TCon (Tycon "(,,,)" (Kfun Star (Kfun Star (Kfun Star (Kfun Star Star)))))
tTuple5
 = TCon (Tycon "(,,,,)" (Kfun Star (Kfun Star (Kfun Star (Kfun Star (Kfun Star Star))))))
tTuple6
 = TCon (Tycon "(,,,,,)" (Kfun Star (Kfun Star (Kfun Star (Kfun Star (Kfun Star (Kfun Star Star)))))))
tTuple7
 = TCon (Tycon "(,,,,,,)" (Kfun Star (Kfun Star (Kfun Star (Kfun Star (Kfun Star (Kfun Star (Kfun Star Star))))))))

tString    :: Type
tString     = list tChar

infixr      4 `fn`
fn         :: Type -> Type -> Type
a `fn` b    = TAp (TAp tArrow a) b

list       :: Type -> Type
list t      = TAp tList t

pair       :: Type -> Type -> Type
pair a b    = TAp (TAp tTuple2 a) b

class HasKind t where
  kind :: t -> Kind
instance HasKind Tyvar where
  kind (Tyvar v k) = k
instance HasKind Tycon where
  kind (Tycon v k) = k
instance HasKind Type where
  kind (TCon tc) = kind tc
  kind (TVar u)  = kind u
  kind (TAp t _) = case (kind t) of
                     (Kfun _ k) -> k

-----------------------------------------------------------------------------
