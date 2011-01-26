from distutils.core import setup
import py2exe

setup(windows=[{"script": "degen.py", "icon_resources": [(0, "icon.ico")]}], options={"py2exe":{"includes":["sip"]}})
