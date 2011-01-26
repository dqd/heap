#!/usr/bin/python
# -*- coding: UTF-8 -*-

import imp, os, sys, hashlib
from PyQt4 import QtGui, QtCore

class Main(QtGui.QMainWindow):
    def __init__(self, parent=None):
        QtGui.QMainWindow.__init__(self)

        self.placement()

        self.setWindowTitle(u"Danobossův erotogenní generátor")
        self.setWindowIcon(QtGui.QIcon("icon.png"))
        self.statusBar().showMessage(u"Generování připraveno. Zadej své požadavky, krabe.")

        about = QtGui.QAction(QtGui.QIcon("about.png"), u"&O programu", self)
        about.setShortcut("Ctrl+O")
        about.setStatusTip(u"Vypsání informací o degenovi.")
        self.connect(about, QtCore.SIGNAL("triggered()"), self.about_dialog)

        exit = QtGui.QAction(QtGui.QIcon("exit.png"), u"&Ukončit", self)
        exit.setShortcut("Ctrl+Q")
        exit.setStatusTip(u"Ukončení téhle skvělé aplikace.")
        self.connect(exit, QtCore.SIGNAL("triggered()"), QtCore.SLOT("close()"))

        menubar = self.menuBar()
        menu = menubar.addMenu("Me&nu")
        menu.addAction(about)
        menu.addAction(exit)

        grid = QtGui.QGridLayout()

        domainLabel = QtGui.QLabel(u"&Doména (slovo)")
        domainLabel.setToolTip(u"Doména, pro kterou se kód bude používat.\nPokud nejde o doménu, jedná se o klíčové slovo.")
        self.domainInput = QtGui.QLineEdit()
        domainLabel.setBuddy(self.domainInput)

        pass1Label = QtGui.QLabel(u"&Heslo (nepovinné)")
        pass1Label.setToolTip(u"Heslo, ze kterého se má přístupový kód generovat.")
        self.pass1Input = QtGui.QLineEdit()
        self.pass1Input.setEchoMode(QtGui.QLineEdit.Password)
        pass1Label.setBuddy(self.pass1Input)

        pass2Label = QtGui.QLabel(u"H&eslo (znovu)")
        pass2Label.setToolTip(u"Heslo, ze kterého se má přístupový kód generovat (ještě jednou).")
        self.pass2Input = QtGui.QLineEdit()
        self.pass2Input.setEchoMode(QtGui.QLineEdit.Password)
        pass2Label.setBuddy(self.pass2Input)

        lengthLabel = QtGui.QLabel(u"Dé&lka kódu")
        lengthLabel.setToolTip(u"Počet znaků generovaného kódu.")
        self.lengthInput = QtGui.QLineEdit()
        self.lengthInput.setMaximumWidth(40)
        self.lengthInput.setMaxLength(3)
        self.lengthInput.setText("10")
        lengthLabel.setBuddy(self.lengthInput)

        self.lowercase = QtGui.QCheckBox(u"&Minusky (a, b, c…)")
        self.lowercase.setToolTip(u"Vygenerovaný kód bude obsahovat malá písmena.")
        self.lowercase.toggle()

        self.uppercase = QtGui.QCheckBox(u"&Verzálky (A, B, C…)")
        self.uppercase.setToolTip(u"Vygenerovaný kód bude obsahovat velká písmena.")
        self.uppercase.toggle()

        self.numbers = QtGui.QCheckBox(u"Čísli&ce (0, 1, 2…)")
        self.numbers.setToolTip(u"Vygenerovaný kód bude obsahovat číslice.")
        self.numbers.toggle()

        self.specials = QtGui.QCheckBox(u"&Speciální znaky (!, @, #…)")
        self.specials.setToolTip(u"Vygenerovaný kód bude obsahovat několik vybraných speciálních znaků.")

        buttonBox = QtGui.QDialogButtonBox()
        button = buttonBox.addButton(u"Vy&generovat", QtGui.QDialogButtonBox.ApplyRole)
        self.connect(button, QtCore.SIGNAL("clicked()"), self.generate_code)

        layout = (
            (domainLabel, self.domainInput),
            (pass1Label, self.pass1Input),
            (pass2Label, self.pass2Input),
            (lengthLabel, self.lengthInput),
            (None, self.lowercase),
            (None, self.uppercase),
            (None, self.numbers),
            (None, self.specials),
            (None, buttonBox),
        )

        r = 0
        c = 0

        for row in layout:
            for col in row:
                if col is not None:
                    grid.addWidget(col, r, c)

                c += 1

            c  = 0
            r += 1

        space = QtGui.QWidget()
        space.setLayout(grid)

        self.setCentralWidget(space)
    
    def placement(self):
        self.resize(300, 250)
        screen = QtGui.QDesktopWidget().screenGeometry()
        size =  self.geometry()
        self.move((screen.width()  - size.width())  / 2,
                  (screen.height() - size.height()) / 2)

    def about_dialog(self):
        title = u"O programu"
        text = u"Danobossův erotogenní generátor sestaví přístupový kód dle zadaných kritérií.<br><br>" + \
               u"Napsal <i>hodný stín</i> pro <i>zlého kraba</i>.<br>" + \
               u"Vytvořeno v průběhu července 2009.<br><a href='http://dqd.cz/'>http://dqd.cz/</a>"
        QtGui.QMessageBox.information(self, title, text, QtGui.QMessageBox.Ok)

    def generate_code(self):
        if str(self.pass1Input.text()).strip() != str(self.pass2Input.text()).strip():
            return QtGui.QMessageBox.information(self, u"Chyba", u"Zadaná hesla se liší.", QtGui.QMessageBox.Ok)

        sha = hashlib.sha256()
        sha.update(str(self.pass1Input.text()).strip())
        sha.update(str(self.domainInput.text()).strip())

        dict = []

        if self.lowercase.isChecked():
            dict.extend(map(chr, range(97, 123))) # a-z

        if self.uppercase.isChecked():
            dict.extend(map(chr, range(65, 91))) # A-Z

        if self.numbers.isChecked():
            dict.extend(map(str, range(0, 10)))

        if self.specials.isChecked():
            dict.extend(['!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '{', '}', '[', ']', '<', '>', '?', '+', '_', '-', '=', '~', ',', '.'])

        if dict == []:
            return QtGui.QMessageBox.information(self, u"Chyba", u"Je potřeba vybrat nějaké znaky, ze kterých se bude generovat.", QtGui.QMessageBox.Ok)

        try:
            length = int(self.lengthInput.text())
        except ValueError:
            return QtGui.QMessageBox.information(self, u"Chyba", u"Je potřeba zadat délku generovaného kódu.", QtGui.QMessageBox.Ok)

        code = ""

        for i in range(0, length):
            code += dict[int(sha.hexdigest(), 16) % len(dict)]
            sha.update(sha.hexdigest())

        cb = QtGui.QApplication.clipboard()
        cb.setText(code, QtGui.QClipboard.Clipboard)
        self.statusBar().showMessage(u"Kód vygenerován a zkopírován do schránky.")

app = QtGui.QApplication(sys.argv)

main = Main()
main.show()

sys.exit(app.exec_())
