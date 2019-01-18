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
using Gee;
using GLib;

private class Folks.Inspect.Commands.Help : Folks.Inspect.Command
{
  public override string name
    {
      get { return "help"; }
    }

  public override string description
    {
      get { return "Get help on using the program."; }
    }

  public override string help
    {
      get
        {
          return "help                   Describe all the available " +
              "commands.\n" +
              "help [command name]    Give more detailed help on the " +
              "specified command.";
        }
    }

  public Help (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      if (command_string == null)
        {
          /* Help index */
          Utils.print_line ("Type 'help <command>' for more information " +
              "about a particular command.");

          MapIterator<string, Command> iter =
              this.client.commands.map_iterator ();

          Utils.indent ();
          while (iter.next () == true)
            {
              Utils.print_line ("%-20s  %s", iter.get_key (),
                  iter.get_value ().description);
            }
          Utils.unindent ();
        }
      else
        {
          /* Help for a given command */
          Command command = this.client.commands.get (command_string);
          if (command == null)
            {
              Utils.print_line ("Unrecognised command '%s'.", command_string);
              return 1;
            }
          else
            {
              Utils.print_line ("%s", command.help);
            }
        }

      return 0;
    }

  public override string[]? complete_subcommand (string subcommand)
    {
      /* @subcommand should be a command name */
      return Readline.completion_matches (subcommand,
          Utils.command_name_completion_cb);
    }
}
