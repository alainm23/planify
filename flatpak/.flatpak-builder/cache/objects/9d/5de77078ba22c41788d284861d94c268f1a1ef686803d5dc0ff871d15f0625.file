/*
 * Copyright (C) 2010 Collabora Ltd.
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
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using Folks;
using GLib;

private class Folks.Inspect.Commands.Quit : Folks.Inspect.Command
{
  public override string name
    {
      get { return "quit"; }
    }

  public override string description
    {
      get
        {
          return "Quit the program.";
        }
    }

  public override string help
    {
      get
        {
          return "quit    Quit the program gracefully, like a cow lolloping " +
              "across a green field.";
        }
    }

  public Quit (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      Process.exit (0);
    }
}
