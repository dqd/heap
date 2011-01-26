all: ghc

clean:
	@rm -f *.hi *.o hasky
	@rm -f TypeChecker/*.hi TypeChecker/*.o
	@echo "Cleaned..."

clean-docs:
	@rm -rf docs

ghc:
	@echo "Compiling, please wait..."
	@ghc -o hasky -v0 -cpp --make Main.hs

# docdir depends on distribution
docweb=http://haskell.org/ghc/docs/latest/html/libraries/
docdir=/usr/share/doc/ghc6-doc/libraries/
version=`ghc --version | cut -d ' ' -f 8`

# src is on a stupid location on Debian
base=$(docweb)base,$(docdir)base/base.haddock
cont=$(docweb)containers,$(docdir)containers/containers.haddock
ghc=$(docweb)ghc-prim,$(docdir)ghc-prim/ghc-prim.haddock
int=$(docweb)integer,$(docdir)integer/integer.haddock
src=$(docweb)haskell-src,/usr/share/ghc6-doc/ghc-$(version)/haddock/haskell-src.haddock

docs: *.hs prologue.txt
	@[ -d docs ] || mkdir docs
	@haddock -o docs -h -t "Hasky" --optghc "-cpp" -p prologue.txt -i $(base) -i $(cont) -i $(int) -i $(ghc) -i $(src) *.hs
	@echo "Documentation generated..."
