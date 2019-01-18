#!/usr/bin/python

# Copyright (C) 2013 Canonical
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation; version 3.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA

import argparse
import imp
import importlib
import os
import sys

from gi.repository import Unity
from gi.repository import GLib

MODULE_TYPE = "python{0}".format(sys.version_info.major)
# An internal type to cover legacy "load_source" imports
SOURCE_TYPE = MODULE_TYPE + "-source"


class PythonScopeLoader(Unity.ScopeLoader):
  def do_get_scopes(self, name, module_type):
    if module_type == MODULE_TYPE:
      # Treat as module name
      module = importlib.import_module(name)
    elif module_type == SOURCE_TYPE:
      modulename, _ = os.path.splitext(os.path.basename(name))
      module = imp.load_source(modulename, name)
    else:
      raise RuntimeError("Unknown module type: {0}".format(module_type))
    return [module.load_scope()]

def load_scope(name, as_module):
  if as_module:
    # Treat as module name
    module = importlib.import_module(name)
  else:
    # Treat as source file name: use the file's base name as a module
    # name in the hope it is unique.
    modulename, _ = os.path.splitext(os.path.basename(name))
    module = imp.load_source(modulename, name)
  return module.load_scope()

def main(argv):
  GLib.threads_init()
  parser = argparse.ArgumentParser(
    description='A host process for Unity scopes written in Python')
  parser.add_argument(
    '-s', dest='as_scope_id', action='store_true',
    help='Treat arguments as scope IDs')
  parser.add_argument(
    '-g', dest='as_group', action='store_true',
    help='Treat arguments as groups')
  parser.add_argument(
    '-m', dest='as_module', action='store_true',
    help='Treat arguments as module names rather than file names')
  parser.add_argument(
    'names', metavar='names', nargs='+', type=str,
    help='The scopes to load')
  options = parser.parse_args(argv[1:])

  if sum([options.as_scope_id, options.as_group, options.as_module]) > 1:
    parser.error('Only one of -s, -g and -m can be used')

  loader = PythonScopeLoader()
  for name in options.names:
    if options.as_scope_id:
      loader.load_scope(name)
    elif options.as_group:
      loader.load_group(name)
    elif options.as_module:
      loader.load_module(name, MODULE_TYPE)
    else:
      loader.load_module(name, SOURCE_TYPE)
  # add manual handling for SIGTERM, since we don't use GLib.MainLoop
  # from python it wouldn't be handled properly
  GLib.unix_signal_add_full(0, 2, lambda x: Unity.ScopeDBusConnector.quit(), None)
  Unity.ScopeDBusConnector.run()

if __name__ == "__main__":
  main (sys.argv)

