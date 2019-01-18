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
 *       Alvaro Soliverez <alvaro.soliverez@collabora.co.uk>
 */

using Folks;
using Gee;
using GLib;

private class Folks.Inspect.Commands.Search : Folks.Inspect.Command
{
  public override string name
    {
      get { return "search"; }
    }

  public override string description
    {
      get
        {
          return "Search the individuals currently present in the aggregator";
        }
    }

  public override string help
    {
      get
        {
          return "search [string]             Search the name fields of " +
              "the known individuals for the given string";
        }
    }

  public Search (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      if (command_string == null)
        {
          /* A search string is required */
          Utils.print_line ("Please enter a search string");
        }
      else
        {
          var query = new SimpleQuery (
              command_string, Query.MATCH_FIELDS_NAMES);
          var search_view = new SearchView (this.client.aggregator, query);

          try
            {
              yield search_view.prepare ();
            }
          catch (GLib.Error e)
            {
              GLib.warning ("Error when calling prepare: %s", e.message);
            }

          foreach (var individual in search_view.individuals)
            {
              Utils.print_line ("%s  %s", individual.id,
                  individual.display_name);
            }
        }

      return 0;
    }
}
