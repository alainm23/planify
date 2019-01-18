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

private class Folks.Inspect.Utils
{
  /* The current indentation level, in spaces */
  private static uint indentation = 0;
  private static string indentation_string = "";

  /* The FILE we're printing output to. */
  public static unowned FileStream output_filestream = GLib.stdout;

  public static void init ()
    {
      Utils.indentation_string = "";
      Utils.indentation = 0;
      Utils.output_filestream = GLib.stdout;

      /* Register some general transformation functions */
      Value.register_transform_func (typeof (Object), typeof (string),
          Utils.transform_object_to_string);
      Value.register_transform_func (typeof (Folks.PersonaStore),
          typeof (string), Utils.transform_persona_store_to_string);
      Value.register_transform_func (typeof (string[]), typeof (string),
          Utils.transform_string_array_to_string);
      Value.register_transform_func (typeof (DateTime), typeof (string),
          Utils.transform_date_time_to_string);
    }

  private static void transform_object_to_string (Value src,
      out Value dest)
    {
      var output = "%p".printf (src.get_object ());
      dest = (owned) output;
    }

  private static void transform_persona_store_to_string (Value src,
      out Value dest)
    {
      var store = (Folks.PersonaStore) src;
      var output = "%p: %s, %s (%s)".printf (store, store.type_id,
          store.id, store.display_name);
      dest = (owned) output;
    }

  private static void transform_string_array_to_string (Value src,
      out Value dest)
    {
      unowned string[] array = (string[]) src;
      string output = "{ ";
      bool first = true;
      foreach (var element in array)
        {
          if (first == false)
            output += ", ";
          output += "'%s'".printf (element);
          first = false;
        }
      output += " }";
      dest = (owned) output;
    }

  private static void transform_date_time_to_string (Value src, out Value dest)
    {
      unowned DateTime? date_time = (DateTime?) src;
      string output = "(null)";
      if (date_time != null)
        {
          output = ((!) date_time).format ("%FT%T%z");
        }

      dest = (owned) output;
    }

  public static void indent ()
    {
      /* We indent in increments of two spaces */
      Utils.indentation += 2;
      Utils.indentation_string = string.nfill (Utils.indentation, ' ');
    }

  public static void unindent ()
    {
      Utils.indentation -= 2;
      Utils.indentation_string = string.nfill (Utils.indentation, ' ');
    }

  [PrintfFormat ()]
  public static void print_line (string format, ...)
    {
      /* FIXME: store the va_list temporarily to work around bgo#638308 */
      var valist = va_list ();
      string output = format.vprintf (valist);
      var str = "%s%s".printf (Utils.indentation_string, output);
      Utils.output_filestream.puts (str);
    }

  public static void print_blank_line ()
    {
      Utils.output_filestream.puts ("");
    }

  public static void print_individual (Individual individual,
      bool show_personas)
    {
      Utils.print_line ("Individual '%s' with %u personas:",
          individual.id, individual.personas.size);

      /* List the Individual's properties */
      var properties = individual.get_class ().list_properties ();

      Utils.indent ();
      foreach (var pspec in properties)
        {
          Value prop_value;
          string output_string;

          /* Ignore the personas property if we're printing the personas out */
          if (show_personas == true && pspec.get_name () == "personas")
            continue;

          prop_value = Value (pspec.value_type);
          individual.get_property (pspec.get_name (), ref prop_value);

          output_string = Utils.property_to_string (individual.get_type (),
              pspec.get_name (), prop_value);

          Utils.print_line ("%-20s  %s", pspec.get_nick (), output_string);
        }

      if (show_personas == true)
        {
          Utils.print_blank_line ();
          Utils.print_line ("Personas:");

          Utils.indent ();
          foreach (Persona persona in individual.personas)
            Utils.print_persona (persona);
          Utils.unindent ();
        }
      Utils.unindent ();
    }

  public static void print_persona (Persona persona)
    {
      Utils.print_line ("Persona '%s':", persona.uid);

      /* List the Persona's properties */
      var properties = persona.get_class ().list_properties ();

      Utils.indent ();
      foreach (var pspec in properties)
        {
          Value prop_value;
          string output_string;

          prop_value = Value (pspec.value_type);
          persona.get_property (pspec.get_name (), ref prop_value);

          output_string = Utils.property_to_string (persona.get_type (),
              pspec.get_name (), prop_value);

          Utils.print_line ("%-20s  %s", pspec.get_nick (), output_string);
        }
      Utils.unindent ();
    }

  public static void print_persona_store (PersonaStore store,
      bool show_personas)
    {
      if (store.is_prepared == false)
        {
          Utils.print_line ("Persona store '%s':", store.id);
          Utils.indent ();
          Utils.print_line ("Not prepared.");
          Utils.unindent ();

          return;
        }

      Utils.print_line ("Persona store '%s' with %u personas:",
          store.id, store.personas.size);

      /* List the store's properties */
      var properties = store.get_class ().list_properties ();

      Utils.indent ();
      foreach (var pspec in properties)
        {
          Value prop_value;
          string output_string;

          /* Ignore the personas property if we're printing the personas out */
          if (show_personas == true && pspec.get_name () == "personas")
            continue;

          prop_value = Value (pspec.value_type);
          store.get_property (pspec.get_name (), ref prop_value);

          output_string = Utils.property_to_string (store.get_type (),
              pspec.get_name (), prop_value);

          Utils.print_line ("%-20s  %s", pspec.get_nick (), output_string);
        }

      if (show_personas == true)
        {
          Utils.print_blank_line ();
          Utils.print_line ("Personas:");

          Utils.indent ();
          foreach (var persona in store.personas.values)
            {
              Utils.print_persona (persona);
            }
          Utils.unindent ();
        }
      Utils.unindent ();
    }

  private static string property_to_string (Type object_type,
      string prop_name,
      Value prop_value)
    {
      string output_string;

      /* Overrides for various known properties */
      if (object_type.is_a (typeof (Individual)) && prop_name == "personas")
        {
          Set<Persona> personas = (Set<Persona>) prop_value.get_object ();
          return "List of %u personas".printf (personas.size);
        }
      else if (object_type.is_a (typeof (PersonaStore)) &&
          prop_name == "personas")
        {
          Map<string, Persona> personas =
              (Map<string, Persona>) prop_value.get_object ();
          return "Set of %u personas".printf (personas.size);
        }
      else if (prop_name == "groups" ||
               prop_name == "local-ids" ||
               prop_name == "supported-fields" ||
               prop_name == "anti-links")
        {
          Set<string> groups = (Set<string>) prop_value.get_object ();
          output_string = "{ ";
          bool first = true;

          foreach (var group in groups)
            {
              if (first == false)
                output_string += ", ";
              output_string += "'%s'".printf (group);
              first = false;
            }

          output_string += " }";
          return output_string;
        }
      else if (prop_name == "avatar")
        {
          string ret = null;
          LoadableIcon? avatar = (LoadableIcon) prop_value.get_object ();

          if (avatar != null &&
              avatar is FileIcon && ((FileIcon) avatar).get_file () != null)
            {
              ret = "%p (file: %s)".printf (avatar,
                  ((FileIcon) avatar).get_file ().get_uri ());
            }
          else if (avatar != null)
            {
              ret = "%p".printf (avatar);
            }

          return ret;
        }
      else if (prop_name == "file")
        {
          string ret = null;
          File? file = (File) prop_value.get_object ();

          if (file != null)
            {
              ret = "%p (file: %s)".printf (file, file.get_uri ());
            }

          return ret;
        }
      else if (prop_name == "im-addresses" ||
               prop_name == "web-service-addresses")
        {
          var prop_list =
              (MultiMap<string, AbstractFieldDetails<string>>)
                  prop_value.get_object ();
          output_string = "{ ";
          bool first = true;

          foreach (var k in prop_list.get_keys ())
            {
              if (first == false)
                output_string += ", ";
              output_string += "'%s' : { ".printf (k);
              first = false;

              var v = prop_list.get (k);
              bool _first = true;
              foreach (var a in v)
                {
                  if (_first == false)
                    output_string += ", ";
                  output_string += "'%s'".printf (a.value);
                  _first = false;
                }

              output_string += " }";
            }

          output_string += " }";
          return output_string;
        }
      else if (prop_name == "email-addresses" ||
               prop_name == "phone-numbers" ||
               prop_name == "urls")
        {
          output_string = "{ ";
          bool first = true;
          var prop_list =
              (Set<AbstractFieldDetails<string>>) prop_value.get_object ();

          foreach (var p in prop_list)
            {
              if (!first)
                {
                  output_string += ", ";
                }
              output_string +=  p.value;
              first = false;
            }
            output_string += " }";

            return output_string;
        }
      else if (prop_name == "birthday")
        {
          unowned DateTime dobj = (DateTime) prop_value.get_boxed ();
          if (dobj != null)
            return dobj.to_string ();
          else
            return "";
        }
      else if (prop_name == "postal-addresses")
        {
          output_string = "{ ";
          bool first = true;
          var prop_list =
              (Set<PostalAddressFieldDetails>) prop_value.get_object ();

          foreach (var p in prop_list)
            {
              if (!first)
                {
                  output_string += ". ";
                }
              output_string +=  p.value.to_string ();
              first = false;
            }
            output_string += " }";

            return output_string;
        }
      else if (prop_name == "notes")
        {
          Set<NoteFieldDetails> notes =
              prop_value.get_object () as Set<NoteFieldDetails>;

          output_string = "{ ";
          bool first = true;

          foreach (var note in notes)
            {
              if (!first)
                {
                  output_string += ", ";
                }
              output_string += note.id;
              first = false;
            }
            output_string += " }";

            return output_string;
        }
      else if (prop_name == "roles")
        {
          var roles = (Set<RoleFieldDetails>) prop_value.get_object ();

          output_string = "{ ";
          bool first = true;

          foreach (var role in roles)
            {
              if (!first)
                {
                  output_string += ", ";
                }
              output_string += role.value.to_string ();
              first = false;
            }
            output_string += " }";

            return output_string;
        }
      else if (prop_name == "structured-name")
        {
          unowned StructuredName sn = (StructuredName) prop_value.get_object ();
          string ret = null;
          if (sn != null)
            ret = sn.to_string ();
          return ret;
        }

      return Utils.transform_value_to_string (prop_value);
    }

  public static string transform_value_to_string (Value prop_value)
    {
      if (Value.type_transformable (prop_value.type (), typeof (string)))
        {
          /* Convert to a string value */
          Value string_value = Value (typeof (string));
          prop_value.transform (ref string_value);
          return string_value.get_string ();
        }
      else
        {
          /* Can't convert the property value to a string */
          return "Can't convert from type '%s' to '%s'".printf (
              prop_value.type ().name (), typeof (string).name ());
        }
    }

  /* FIXME: This can't be in the command_completion_cb() function because Vala
   * doesn't allow static local variables. Erk. */
  private static MapIterator<string, Command>? command_name_iter = null;

  /* Complete a command name, starting with @word. */
  public static string? command_name_completion_cb (string word,
      int state)
    {
      /* Initialise state. Whoever wrote the readline API should be shot. */
      if (state == 0)
        Utils.command_name_iter = main_client.commands.map_iterator ();

      while (Utils.command_name_iter.next () == true)
        {
          string command_name = Utils.command_name_iter.get_key ();
          if (command_name.has_prefix (word))
            return command_name;
        }

      /* Clean up */
      Utils.command_name_iter = null;
      return null;
    }

  /* FIXME: This can't be in the individual_id_completion_cb() function because
   * Vala doesn't allow static local variables. Erk. */
  private static MapIterator<string, Individual>? individual_id_iter = null;

  /* Complete an individual's ID, starting with @word. */
  public static string? individual_id_completion_cb (string word,
      int state)
    {
      /* Initialise state. Whoever wrote the readline API should be shot. */
      if (state == 0)
        {
          Utils.individual_id_iter =
              main_client.aggregator.individuals.map_iterator ();
        }

      while (Utils.individual_id_iter.next () == true)
        {
          var id = Utils.individual_id_iter.get_key ();
          if (id.has_prefix (word))
            return id;
        }

      /* Clean up */
      Utils.individual_id_iter = null;
      return null;
    }

  /* FIXME: This can't be in the individual_id_completion_cb() function because
   * Vala doesn't allow static local variables. Erk. */
  private static Iterator<Persona>? persona_uid_iter = null;

  /* Complete an individual's ID, starting with @word. */
  public static string? persona_uid_completion_cb (string word,
      int state)
    {
      /* Initialise state. Whoever wrote the readline API should be shot. */
      if (state == 0)
        {
          Utils.individual_id_iter =
              main_client.aggregator.individuals.map_iterator ();
          Utils.persona_uid_iter = null;
        }

      while (Utils.persona_uid_iter != null ||
          Utils.individual_id_iter.next () == true)
        {
          var individual = Utils.individual_id_iter.get_value ();

          if (Utils.persona_uid_iter == null)
            {
              assert (individual != null);
              Utils.persona_uid_iter = individual.personas.iterator ();
            }

          while (Utils.persona_uid_iter.next ())
            {
              var persona = Utils.persona_uid_iter.get ();
              if (persona.uid.has_prefix (word))
                return persona.uid;
            }

          /* Clean up */
          Utils.persona_uid_iter = null;
        }

      /* Clean up */
      Utils.individual_id_iter = null;
      return null;
    }

  /* FIXME: This can't be in the backend_name_completion_cb() function because
   * Vala doesn't allow static local variables. Erk. */
  private static Iterator<Backend>? backend_name_iter = null;

  /* Complete an individual's ID, starting with @word. */
  public static string? backend_name_completion_cb (string word,
      int state)
    {
      /* Initialise state. Whoever wrote the readline API should be shot. */
      if (state == 0)
        {
          Utils.backend_name_iter =
              main_client.backend_store.list_backends ().iterator ();
        }

      while (Utils.backend_name_iter.next () == true)
        {
          Backend backend = Utils.backend_name_iter.get ();
          if (backend.name.has_prefix (word))
            return backend.name;
        }

      /* Clean up */
      Utils.backend_name_iter = null;
      return null;
    }

  /* FIXME: This can't be in the persona_store_id_completion_cb() function
   * because Vala doesn't allow static local variables. Erk. */
  private static MapIterator<string, PersonaStore>? persona_store_id_iter =
      null;

  /* Complete a persona store's ID, starting with @word. */
  public static string? persona_store_id_completion_cb (string word,
      int state)
    {
      /* Initialise state. Whoever wrote the readline API should be shot. */
      if (state == 0)
        {
          Utils.backend_name_iter =
              main_client.backend_store.list_backends ().iterator ();
          Utils.persona_store_id_iter = null;
        }

      while (Utils.persona_store_id_iter != null ||
          Utils.backend_name_iter.next () == true)
        {
          if (Utils.persona_store_id_iter == null)
            {
              Backend backend = Utils.backend_name_iter.get ();
              Utils.persona_store_id_iter =
                  backend.persona_stores.map_iterator ();
            }

          while (Utils.persona_store_id_iter.next () == true)
            {
              var id = Utils.persona_store_id_iter.get_key ();
              if (id.has_prefix (word))
                return id;
            }

          /* Clean up */
          Utils.persona_store_id_iter = null;
        }

      /* Clean up */
      Utils.backend_name_iter = null;
      return null;
    }

  /* Command validation code for commands which take a well-known set of
   * subcommands. */
  public static bool validate_subcommand (string command,
      string? command_string, string? subcommand, string[] valid_subcommands)
    {
      if (subcommand != null && subcommand in valid_subcommands)
          return true;

      /* Print an error. */
      Utils.print_line ("Unrecognised '%s' command '%s'.", command,
          (command_string != null) ? command_string : "");

      Utils.print_line ("Valid commands:");
      Utils.indent ();
      foreach (var c in valid_subcommands)
          Utils.print_line ("%s", c);
      Utils.unindent ();

      return false;
    }
}
