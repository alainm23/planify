/*
 * Copyright (C) 2012 Jeremy Whiting <jeremy.whiting@collabora.com>
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
 *       Jeremy Whiting <jeremy.whiting@collabora.com>
 */

using Folks;
using Gee;
using GLib;

private class Folks.Inspect.Commands.Set : Folks.Inspect.Command
{
  private const string[] _valid_subcommands =
    {
      "alias",
    };

  public override string name
    {
      get { return "set"; }
    }

  public override string description
    {
      get
        {
          return "Set an individual's properties";
        }
    }

  public override string help
    {
      get
        {
          return "set alias [individual UID] [new alias]" +
                  "   Set the alias of the given individual.";
        }
    }

  public Set (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      string[] parts = {};

      if (command_string != null)
        {
          /* Parse subcommands */
          parts = command_string.split (" ");
        }

      if (!Utils.validate_subcommand (this.name, command_string, parts[0],
              Set._valid_subcommands))
          return 1;

      if (parts[0] == "alias")
        {
          if (parts.length < 3)
            {
              Utils.print_line ("Must pass at least one individual ID and a new alias to an " +
                  "'alias' subcommand.");

              return 1;
            }

          /* To set an attribute on an individual, we must have at least one. */
          if (parts[1] == null || parts[1].strip () == "")
            {
              Utils.print_line ("Unrecognised individual ID '%s'.",
                  parts[1]);

              return 1;
            }

          var id = parts[1].strip ();

          var individual = this.client.aggregator.individuals.get (id);
          if (individual == null)
            {
              Utils.print_line ("Unrecognized individual ID '%s'.", id);
              return 1;
            }
            
          try
            {
              var persona = yield this.client.aggregator.ensure_individual_property_writeable (individual, "alias");
              
              /* Since the individual may have changed, use the individual from the new persona. */
              persona.individual.alias = parts[2];
              Utils.print_line ("Setting of individual's alias to '%s' was successful.",
                  parts[2]);
            }
          catch (Folks.IndividualAggregatorError e)
            {
              Utils.print_line ("Setting of individual's alias to '%s' failed.",
                  parts[2]);
              return 1;
            }
        }
      else
        {
          assert_not_reached ();
        }

      return 0;
    }

  /* FIXME: These can't be in the subcommand_name_completion_cb() function
   * because Vala doesn't allow static local variables. Erk. */
  [CCode (array_length = false, array_null_terminated = true)]
  private static string[] subcommand_completions;
  private static uint completion_count;
  private static string prefix;

  /* Complete a subcommand name (“alias”), starting with @word. */
  public static string? subcommand_name_completion_cb (string word,
      int state)
    {
      if (state == 0)
        {
          string[] parts = word.split (" ");

          if (parts.length > 0 &&
              (parts[0] == "alias"))
            {
              var last_part = parts[parts.length - 1];

              if (parts[0] == "alias")
                {
                  subcommand_completions =
                      Readline.completion_matches (last_part,
                          Utils.individual_id_completion_cb);
                }

              if (last_part == "")
                {
                  prefix = word;
                }
              else
                {
                  prefix = word[0:-last_part.length];
                }
            }
          else
            {
              subcommand_completions = Set._valid_subcommands;
              prefix = "";
            }

          completion_count = 0;
        }

      while (completion_count < subcommand_completions.length)
        {
          var completion = subcommand_completions[completion_count];
          var candidate = prefix + completion;
          completion_count++;

          if (completion != null && completion != "" &&
              candidate.has_prefix (word))
            {
              return completion;
            }
        }

      /* Clean up */
      subcommand_completions = null;
      completion_count = 0;
      prefix = "";

      return null;
    }
  
  public override string[]? complete_subcommand (string subcommand)
    {
      /* @subcommand should be “alias” */
      return Readline.completion_matches (subcommand,
          subcommand_name_completion_cb);
    }
}

/* vim: filetype=vala textwidth=80 tabstop=2 expandtab: */
