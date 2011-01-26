# coding=windows-1250

import os
import sys

def visit(arg, dirname, names):
    for i, name in enumerate(names):
        if reduce(lambda x, y: x or y in [u'\u2500', u'\u250c', u'\u251c', u'\u252c', u'\u253c'], name, False):
            try:
                fixedname = unicode(name.encode('cp852'), 'utf-8')
                oldname = os.path.join(dirname, name)
                newname = os.path.join(dirname, fixedname)

                print repr(oldname)

                if name != fixedname:
                    if os.path.isdir(oldname):
                        names[i] = fixedname

                    os.rename(oldname, newname)
            except (UnicodeDecodeError, UnicodeEncodeError, WindowsError), e:
                print e

print u'Tento program se pokusí opravit kódování souborů v této složce.'
print u'Funkčnost programu není zaručena, spouštíte ho na vlastní nebezpečí!'
print u'Pokračujte stiskem libovolné klávesy.'
sys.stdin.read(1)

os.path.walk(u'.', visit, None)
