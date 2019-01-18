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

private class Folks.Inspect.Commands.Backends : Folks.Inspect.Command
{
  public override string name
    {
      get { return "backends"; }
    }

  public override string description
    {
      get { return "Inspect the backends loaded by the aggregator."; }
    }

  public override string help
    {
      get
        {
          return "backends                   List all known backends.\n" +
              "backends [backend name]    Display the details of the " +
              "specified backend and list its persona stores.";
        }
    }

  public Backends (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      if (command_string == null)
        {
          /* List all the backends */
          Collection<Backend> backends =
              this.client.backend_store.list_backends ();

          Utils.print_line ("%u backends:", backends.size);

          Utils.indent ();
          foreach (Backend backend in backends)
            Utils.print_line ("%s", backend.name);
          Utils.unindent ();
        }
      else
        {
          /* Show the details of a particular backend */
          Backend backend =
              this.client.backend_store.dup_backend_by_name (command_string);

          if (backend == null)
            {
              Utils.print_line ("Unrecognised backend name '%s'.",
                  command_string);
              return 1;
            }

          Utils.print_line ("Backend '%s' with %u persona stores " +
              "(type ID, ID ('display name')):",
              backend.name, backend.persona_stores.size);

          /* List the backend's persona stores */
          Utils.indent ();
          foreach (var store in backend.persona_stores.values)
            {
              Utils.print_line ("%s, %s ('%s')", store.type_id, store.id,
                  store.display_name);
            }
          Utils.unindent ();
        }

      return 0;
    }

  public override string[]? complete_subcommand (string subcommand)
    {
      /* @subcommand should be a backend name */
      return Readline.completion_matches (subcommand,
          Utils.backend_name_completion_cb);
    }
}
