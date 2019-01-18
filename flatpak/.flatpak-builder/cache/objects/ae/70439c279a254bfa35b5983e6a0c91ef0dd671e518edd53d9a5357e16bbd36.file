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

private class Folks.Inspect.Commands.Individuals : Folks.Inspect.Command
{
  public override string name
    {
      get { return "individuals"; }
    }

  public override string description
    {
      get
        {
          return "Inspect the individuals currently present in the aggregator";
        }
    }

  public override string help
    {
      get
        {
          return "individuals                    List all known " +
              "individuals.\n" +
              "individuals [individual ID]    Display the details of the " +
              "specified individual and list its personas.";
        }
    }

  public Individuals (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      if (command_string == null)
        {
          /* List all the individuals */
          foreach (var individual in this.client.aggregator.individuals.values)
            {
              Utils.print_individual (individual, false);
              Utils.print_blank_line ();
            }
        }
      else
        {
          /* Display the details of a single individual */
          var individual =
              this.client.aggregator.individuals.get (command_string);

          if (individual == null)
            {
              Utils.print_line ("Unrecognised individual ID '%s'.",
                  command_string);
              return 1;
            }

          Utils.print_individual (individual, true);
        }

      return 0;
    }

  public override string[]? complete_subcommand (string subcommand)
    {
      /* @subcommand should be an individual ID */
      return Readline.completion_matches (subcommand,
          Utils.individual_id_completion_cb);
    }
}
