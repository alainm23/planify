/*
 * Copyright (C) 2011 Philip Withnall
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors:
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using Folks;
using GLib;

private class Folks.Inspect.Commands.Debug : Folks.Inspect.Command
{
  public override string name
    {
      get { return "debug"; }
    }

  public override string description
    {
      get { return "Print debugging output from libfolks."; }
    }

  public override string help
    {
      get
        {
          return "debug    Print status information from libfolks.";
        }
    }

  public Debug (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      var debug = Folks.Debug.dup ();
      debug.emit_print_status ();
      return 0;
    }
}
