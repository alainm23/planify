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

private class Folks.Inspect.Commands.PersonaStores : Folks.Inspect.Command
{
  public override string name
    {
      get { return "persona-stores"; }
    }

  public override string description
    {
      get
        {
          return "Inspect the persona stores loaded by the aggregator";
        }
    }

  public override string help
    {
      get
        {
          return "persona-stores                       List all known " +
              "persona stores.\n" +
              "persona-stores [persona store ID]    Display the details of " +
              "the specified persona store and list its personas.";
        }
    }

  public PersonaStores (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      if (command_string == null)
        {
          /* List all the persona stores */
          Collection<Backend> backends =
              this.client.backend_store.list_backends ();

          foreach (Backend backend in backends)
            {
              var stores = backend.persona_stores;

              foreach (var persona_store in stores.values)
                {
                  Utils.print_persona_store (persona_store, false);
                  Utils.print_blank_line ();
                }
            }
        }
      else
        {
          /* Show the details of a particular persona store */
          Collection<Backend> backends =
              this.client.backend_store.list_backends ();
          PersonaStore store = null;

          foreach (Backend backend in backends)
            {
              var stores = backend.persona_stores;
              store = stores.get (command_string);
              if (store != null)
                break;
            }

          if (store == null)
            {
              Utils.print_line ("Unrecognised persona store ID '%s'.",
                  command_string);
              return 1;
            }

          Utils.print_persona_store (store, true);
        }

      return 0;
    }

  public override string[]? complete_subcommand (string subcommand)
    {
      /* @subcommand should be a persona store ID */
      return Readline.completion_matches (subcommand,
          Utils.persona_store_id_completion_cb);
    }
}
