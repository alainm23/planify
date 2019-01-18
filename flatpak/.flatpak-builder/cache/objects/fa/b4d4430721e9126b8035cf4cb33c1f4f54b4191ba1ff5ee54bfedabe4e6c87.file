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
using Gee;
using GLib;

private class Folks.Inspect.Commands.Linking : Folks.Inspect.Command
{
  private const string[] _valid_subcommands =
    {
      "link-personas",
      "link-individuals",
      "unlink-individual",
    };

  public override string name
    {
      get { return "linking"; }
    }

  public override string description
    {
      get
        {
          return "Link and unlink personas";
        }
    }

  public override string help
    {
      get
        {
          return "linking link-personas [persona 1 UID] " +
              "[persona 2 UID] …           " +
                  "Link the given personas.\n" +
              "linking link-individuals [individual 1 ID] " +
                  "[individual 2 ID] …    " +
                  "Link the personas in the given individuals.\n" +
              "linking unlink-individual " +
                  "[individual ID]                         " +
                  "Unlink the given individual.";
        }
    }

  public Linking (Client client)
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
              Linking._valid_subcommands))
          return 1;

      if (parts[0] == "link-personas" || parts[0] == "link-individuals")
        {
          var personas = new HashSet<Persona> (); /* set of personas to link */

          if (parts.length < 2)
            {
              if (parts[0] == "link-personas")
                {
                  Utils.print_line ("Must pass at least one persona to a " +
                      "'link-personas' subcommand.");
                }
              else
                {
                  Utils.print_line ("Must pass at least one individual to a " +
                      "'link-individuals' subcommand.");
                }

              return 1;
            }

          /* Link the personas in the given individuals. We must have at least
           * one. */
          for (uint i = 1; i < parts.length; i++)
            {
              if (parts[i] == null || parts[i].strip () == "")
                {
                  if (parts[0] == "link-personas")
                    {
                      Utils.print_line ("Unrecognised persona UID '%s'.",
                          parts[i]);
                    }
                  else
                    {
                      Utils.print_line ("Unrecognised individual ID '%s'.",
                          parts[i]);
                    }

                  return 1;
                }

              var found = false;

              if (parts[0] == "link-personas")
                {
                  var uid = parts[i].strip ();

                  foreach (var individual in
                      this.client.aggregator.individuals.values)
                    {
                      foreach (Persona persona in individual.personas)
                        {
                          if (persona.uid == uid)
                            {
                              personas.add (persona);
                              found = true;
                              break;
                            }
                        }

                      if (found == true)
                        {
                          break;
                        }
                    }

                  if (found == false)
                    {
                      Utils.print_line ("Unrecognised persona UID '%s'.",
                          parts[i]);
                      return 1;
                    }
                }
              else
                {
                  var id = parts[i].strip ();

                  foreach (var individual in
                      this.client.aggregator.individuals.values)
                    {
                      if (individual.id == id)
                        {
                          foreach (Persona persona in individual.personas)
                            {
                              personas.add (persona);
                            }

                          found = true;
                          break;
                        }
                    }

                  if (found == false)
                    {
                      Utils.print_line ("Unrecognised individual ID '%s'.",
                          parts[i]);
                      return 1;
                    }
                }
            }

          /* Link the personas */
          try
            {
              yield this.client.aggregator.link_personas (personas);
            }
          catch (IndividualAggregatorError e)
            {
              Utils.print_line ("Error (domain: %u, code: %u) linking %u " +
                      "personas: %s",
                  e.domain, e.code, personas.size, e.message);
              return 1;
            }

          /* We can't print out the individual which was produced, as
           * more than one may have been produced (due to anti-links)
           * or several others may have been consumed in the process.
           *
           * Chaos, really. */
          Utils.print_line ("Linking of %u personas was successful.",
              personas.size);
        }
      else if (parts[0] == "unlink-individual")
        {
          if (parts.length != 2)
            {
              Utils.print_line ("Must pass exactly one individual ID to an " +
                  "'unlink-individual' subcommand.");
              return 1;
            }

          var ind = this.client.aggregator.individuals.get (parts[1]);

          if (ind == null)
            {
              Utils.print_line ("Unrecognised individual ID '%s'.", parts[1]);
              return 1;
            }

          /* Unlink the individual. */
          try
            {
              yield this.client.aggregator.unlink_individual (ind);
            }
          catch (Error e)
            {
              Utils.print_line ("Error (domain: %u, code: %u) unlinking " +
                      "individual '%s': %s",
                  e.domain, e.code, ind.id, e.message);
              return 1;
            }

          /* Success! */
          Utils.print_line ("Unlinking of individual '%s' was successful.",
              ind.id);
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

  /* Complete a subcommand name (either “link-personas”, “link-individuals”
   * or “unlink-individual”), starting with @word. */
  public static string? subcommand_name_completion_cb (string word,
      int state)
    {
      /* Initialise state. I may have said this before, but whoever wrote the
       * readline API should be shot. */
      if (state == 0)
        {
          string[] parts = word.split (" ");

          if (parts.length > 0 &&
              (parts[0] == "link-personas" || parts[0] == "link-individuals"))
            {
              var last_part = parts[parts.length - 1];

              if (parts[0] == "link-personas")
                {
                  subcommand_completions =
                      Readline.completion_matches (last_part,
                          Utils.persona_uid_completion_cb);
                }
              else
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
          else if (parts.length > 0 && parts[0] == "unlink-individual")
            {
              /* Only accepts one argument */
              if (parts.length != 2)
                {
                  /* Clean up */
                  subcommand_completions = null;
                  completion_count = 0;
                  prefix = "";

                  return null;
                }

              subcommand_completions =
                  Readline.completion_matches (parts[1],
                      Utils.individual_id_completion_cb);
              prefix = "unlink-individual ";
            }
          else
            {
              subcommand_completions = Linking._valid_subcommands;
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
      /* @subcommand should be either “link-personas”, “link-individuals”
       * or “unlink-individual” */
      return Readline.completion_matches (subcommand,
          Linking.subcommand_name_completion_cb);
    }
}

/* vim: filetype=vala textwidth=80 tabstop=2 expandtab: */
