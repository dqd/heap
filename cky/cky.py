#! /usr/bin/python
# coding=utf-8

"""
The Cocke–Kasami–Younger algorithm

2010 Pavel Dvořák <id@dqd.cz>
"""

# Feel free to edit.
ENCODING = 'latin2'
AJKA_CMD = '/nlp/projekty/ajka/bin/ajka -b'
GRAMMAR_FILE = 'cky.data'
GRAMMAR_LIMIT = 100000

import re
import sys
import nltk
import getopt
import subprocess
import unicodedata
from os import path

sys.setrecursionlimit(10000) # Uh, oh.

def utfize(string):
    """
    Convert to the Unicode string when it is necessary.

    @param string: a string.
    @type string: String
    @return: a string in Unicode.
    @rtype: String
    """
    if isinstance(string, str):
        return string.decode('utf-8')

    return string

def tr(string, table):
    """
    Replace parts of the string according to the replacement table.

    @param string: a string.
    @type string: String
    @param table: a dictionary of replacements (keys to values).
    @type table: {a}
    @return: a string with applied replacements.
    @rtype: String
    """
    return re.compile('|'.join(map(re.escape, table))).sub(lambda x: table[x.group(0)], string)

def morph(word):
    """
    Perform the morphological analysis of the Czech word. It uses
    the external morphological analyser Ajka.
    
    @param word: any Czech word.
    @type word: String
    @return: A list of word classes. If the word is not known, an empty
    list is returned.
    @rtype: [String]
    """
    if re.match(r'\W+', word, re.UNICODE):
        return [word]

    ajka = subprocess.Popen(AJKA_CMD, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
    output = ajka.communicate(utfize(word).encode(ENCODING))[0].decode(ENCODING)

    if '--not found' in output or output[:5] != 'ajka>':
        return []

    return [wc[3:] for wc in filter(lambda x: x[:3] == '<c>', output.split())]

def cky(sentence, verbose):
    """
    Perform the syntactic analysis on the sentence. The function uses
    the Cocke–Kasami–Younger algorithm. If a word in the sentence is
    not recognized, the function terminate the program with an error
    message.

    @param sentence: any correctly formed Czech sentence.
    @type sentence: String
    @param verbose: verbose output.
    @type verbose: Bool
    """
    if verbose:
        print 'Lexical analysis...'

    lexical = []

    for word in nltk.tokenize.WordPunctTokenizer().tokenize(utfize(sentence)):
        classes = morph(word)

        if not classes:
            print 'Error: the word \'%s\' is not recognized by the morphological analyser Ajka.' % word
            sys.exit(1)

        lexical.append((word, classes))

    if verbose:
        for l in lexical:
            print '%s: %s' % (l[0], u', '.join(l[1]))

        print '\nLoading the grammar...'
    
    try:
        f = open(GRAMMAR_FILE, 'r')

        grammar = nltk.parse_cfg(f.read())

        f.close()
    except IOError, err:
        print 'Error: %s.' % err
        sys.exit(1)

    def rhs(x):
        terminals = grammar.productions(lhs=x)
        
        if not terminals:
            print 'Error: a correct terminal for the nonterminal \'%s\' cannot be found.' % x
            sys.exit(1)

        return grammar.productions(rhs=terminals[0].rhs()[0])

    def abc(x, y):
        return filter(lambda x: re.match(r'.* %s$' % y, str(x)), rhs(x))

    if verbose:
        print 'Performing the analysis...'

    chart = []

    for ls in lexical: 
        chart.append([set([g.lhs() for l in ls[1] for g in grammar.productions(rhs=l)])])

        if verbose:
            print ls[0], ' ',

    for j in range(1, len(lexical)):
        for i in range(len(lexical) - j):
            chart[i].insert(j, set([]))
            for k in range(j):
                chart[i][j].update([a.lhs() for b in chart[i][k] for c in chart[i + k + 1][j - k - 1] for a in abc(b, c)])

    if verbose:
        print

        for j in range(len(lexical)):
            for i in range(len(lexical) - j):
                print list(chart[i][j]), ' ',
            print

    print 'The sentence is',

    if not nltk.grammar.Nonterminal('S') in [b.lhs() for c in chart[0][-1] for b in grammar.productions(rhs=c)]:
        print 'NOT',

    print 'OK according to our Czech grammar.'

def generate(corpus, verbose):
    """
    Generate a grammar file of the given corpus. The corpus contains
    a set of sentences having their words tagged.
    The grammar is going to be in the Chomsky normal form (CNF), so
    the sentences should not be more complex than the context-free
    language.

    CNF is defined by the following rules:\n
    A → BC or\n
    A → α or\n
    S → ε.

    @param corpus: a filepath to the corpus (e.g. /nlp/corpora/vertical/desam/source).
    @type corpus: String
    @param verbose: verbose output.
    @type verbose: Bool
    """
    if not path.isfile(corpus):
        print 'Error: the corpus file \'%s\' does not exist.' % corpus
        sys.exit(1)

    try:
        f = open(corpus, 'r')
    except IOError, err:
        print 'Error: %s.' % err
        sys.exit(1)

    t = nltk.Tree('(S)')
    processing = False
    opening = False

    if verbose:
        print 'Generation of the sentences...'

    for line in f.readlines()[:GRAMMAR_LIMIT]:
        line = unicode(line, ENCODING)
        tag = re.match(r'^<.+>', line)
        word = unicodedata.normalize('NFKD', line.split()[-1]).encode('ascii', 'ignore')

        if not processing and opening and not tag and not re.match(r'^\d+\)', line):
            sentence = [word]
            processing = True
        elif processing and not tag:
            sentence.append(word)
        elif processing and tag:
            t = add(t, sentence)
            processing = False
        
        opening = re.match(r'^<\w+.*>', line)

    f.close()

    if verbose:
        print 'Done. Generated %d sentences.' % len(t)
        print 'Normalization to CNF...'

    t.chomsky_normal_form()

    if verbose:
        print 'Done. The tree now reaches a height of %d nodes.' % t.height()

    try:
        f = open(GRAMMAR_FILE, 'w')

        if verbose:
            print 'Transformation into the grammar...'
            i = 0

        for rule in set(t.productions()):
            rule = re.sub(r'<([\w-]+)>', r'\1', '%s\n' % rule)
            rule = re.sub(r'(\w+)-', r'\1_', rule) # this is not needed in the newer versions of NLTK
            rule = re.sub(r' S\|(.+)', r' \1', rule)
            rule = re.sub(r'^S\|([\w-]+) (.+)', r'S \2 \n\1 \2', rule)
            f.write(rule)

            if verbose:
                i += rule.count('\n')

        f.close()
    except IOError, err:
        print 'Error: %s.' % err
        sys.exit(1)

    if verbose:
        print 'Done. The grammar contains %d rules.' % i

def add(t, l):
    """
    Recursively add the list to the tree.

    @param t: a tree; defined in the nltk.Tree module.
    @type t: Tree
    @param l: a list of items -- in this case, it is a list of words.
    @type l: [a]
    """
    if not l:
        return t
    
    a = l.pop(0)

    table = {'[': 'LPAREN',
             ']': 'RPAREN',
             '+': 'PLUS',
             '=': 'EQUALS',
             '.': 'DOT',
             ':': 'COLON',
             ';': 'SEMIC',
             ',': 'COMMA',
             '`': 'BACKT',
             '!': 'EXCLAM',
             '?': 'QUEST',
             '|': 'PIPE',
             '"': 'QUOTE',
             "'": 'APOST',
             '-': 'DASH',
             '&': 'AMPER',
             '/': 'SLASH',
             '%': 'PERCEN',
             '*': 'ASTER'}

    a = tr(a, {'(': '[', ')': ']'}) # parenthesis are reserved
    b = tr(a, table)

    for x in t:
        if isinstance(x, nltk.Tree) and x.node == a:
            x = add(x, l)
            return t

    t.append(add(nltk.Tree('(X%s %s)' % (b, a)), l))

    return t

def usage(prog_name):
    """
    Usage: _name_ [OPTIONS]
    The Cocke–Kasami–Younger algorithm performs the syntactic analysis
    of a sentence using the grammar in a Chomsky normal form (CNF) and
    outputs a parsing table.
    The analysed sentence is expected to be entered by the standard input
    (e.g. echo "Model hradu v použitelném stavu." | _name_).

    OPTIONS:
    _tab_-h, --help             display this help and exit
    _tab_-g, --generate=CORPUS  generate a grammar file of the CORPUS
    _tab_-v, --verbose          verbose output

    The CORPUS file (e.g. /nlp/corpora/vertical/desam/source) should be
    saved in the _encoding_ encoding.
    """
    output = '\n'.join([line[4:] for line in usage.__doc__.splitlines()][1:-1])
    print tr(output, {'_name_': path.basename(prog_name), '_encoding_': ENCODING, '_tab_': '\t'})

def main(argv):
    """
    Handle the input parameters and run the program. If anything goes wrong,
    report an error.

    @param argv: input arguments.
    @type argv: [String]
    """
    try:
        opts, args = getopt.getopt(argv[1:], 'hg:v', ['help', 'generate=', 'verbose'])
    except getopt.GetoptError, err:
        print 'Error: %s.' % err
        sys.exit(1)

    g = ''
    v = False

    for opt, arg in opts:
        if opt in ['-h', '--help']:
            usage(argv[0])
            sys.exit()
        elif opt in ['-g', '--generate']:
            g = arg
        elif opt in ['-v', '--verbose']:
            v = True

    if g:
        generate(g, v)
        sys.exit()

    try:
        input = sys.stdin.readlines()
    except KeyboardInterrupt:
        print 'Error: enter the text and press the Ctrl + D key combination, not the Ctrl + C one.'
        sys.exit(1)

    if not input or not input[0].strip():
        print 'Error: you have to enter the analysed sentence by the standard input.'
        sys.exit(1)
    elif not path.isfile(GRAMMAR_FILE) or path.getsize(GRAMMAR_FILE) < 127: # Let's say 128 is a reasonably small grammar.
        print 'Error: the grammar file is empty. You have to generate it first.'
        sys.exit(1)

    cky(input[0], v)

if __name__ == "__main__":
    main(sys.argv)
