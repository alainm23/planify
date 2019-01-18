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

/*
 * signals — list signals we're currently connected to
 * signals connect ClassName — connect to all the signals on all the instances
 *     of that class
 * signals connect ClassName::signal — connect to the given signal on all the
 *     instances of that class
 * signals connect 0xdeadbeef — connect to all the signals on a particular class
 *     instance
 * signals connect 0xdeadbeef::signal — connect to the given signal on a
 *     particular class instance
 * signals disconnect (as above)
 * signals disconnect — signal handler ID
 * signals ClassName — list all the signals on all the instances of that class,
 *     highlighting the ones we're currently connected to
 * signals 0xdeadbeef — list all the signals on a particular class instance,
 *     highlighting the ones we're currently connected to
 * signals ClassName::signal — show the details of this signal
 * signals 0xdeadbeef::signal — show the details of this signal
 */

private class Folks.Inspect.Commands.Signals : Folks.Inspect.Command
{
  private const string[] _valid_subcommands =
    {
      "connect",
      "disconnect",
    };

  public override string name
    {
      get { return "signals"; }
    }

  public override string description
    {
      get
        {
          return "Allow connection to and display of signals emitted by " +
              "libfolks.";
        }
    }

  public override string help
    {
      get
        {
          return "signals                                            " +
              "List signals we're currently connected to.\n" +
              "signals connect [class name]                       " +
              "Connect to all the signals on all the instances of that " +
              "class.\n" +
              "signals connect [class name]::[signal name]        " +
              "Connect to the given signal on all the instances of that " +
              "class.\n" +
              "signals connect [object pointer]                   " +
              "Connect to all the signals on a particular class instance.\n" +
              "signals connect [object pointer]::[signal name]    " +
              "Connect to the given signal on a particular class instance.\n" +
              "signals disconnect                                 " +
              "(As for 'connect'.)\n" +
              "signals [class name]                               " +
              "List all the signals on all the instances of that class, " +
              "highlighting the ones we're currently connected to.\n" +
              "signals [object pointer]                           " +
              "List all the signals on a particular class instance, " +
              "highlighting the ones we're currently connected to.\n" +
              "signals [class name]::[signal name]                " +
              "Show the details of this signal.\n" +
              "signals [object pointer]::[signal name]            " +
              "Show the details of this signal.";
        }
    }

  public Signals (Client client)
    {
      base (client);
    }

  public override async int run (string? command_string)
    {
      if (command_string == null)
        {
          /* List all the signals we're connected to */
          this.client.signal_manager.list_signals (Type.INVALID, null);
        }
      else
        {
          /* Parse subcommands */
          string[] parts = command_string.split (" ", 2);

          if (!Utils.validate_subcommand (this.name, command_string, parts[0],
                 Signals._valid_subcommands))
              return 1;

          Type class_type;
          Object class_instance;
          string signal_name;
          string detail_string;

          if (parts[0] == "connect" || parts[0] == "disconnect")
            {
              /* Connect to or disconnect from a signal */
              if (parts[1] == null || parts[1].strip () == "")
                {
                  Utils.print_line ("Unrecognised signal identifier '%s'.",
                      parts[1]);
                  return 1;
                }

              if (this.parse_signal_id (parts[1].strip (), out class_type,
                  out class_instance, out signal_name,
                  out detail_string) == false)
                {
                  return 1;
                }

              /* FIXME: Handle "disconnect <signal ID>" */
              if (parts[0] == "connect")
                {
                  uint signal_count =
                      this.client.signal_manager.connect_to_signal (class_type,
                          class_instance, signal_name, detail_string);
                  Utils.print_line ("Connected to %u signals.", signal_count);
                }
              else
                {
                  uint signal_count =
                      this.client.signal_manager.disconnect_from_signal (
                          class_type, class_instance, signal_name,
                              detail_string);
                  Utils.print_line ("Disconnected from %u signals.",
                      signal_count);
                }
            }
          else
            {
              /* List some of the signals we're connected to, or display
               * their details. */
              if (this.parse_signal_id (parts[0].strip (), out class_type,
                  out class_instance, out signal_name,
                  out detail_string) == false)
                {
                  return 1;
                }

              if (signal_name == null)
                {
                  this.client.signal_manager.list_signals (class_type,
                      class_instance);
                }
              else
                {
                  /* Get the class type from the instance */
                  if (class_type == Type.INVALID)
                    class_type = class_instance.get_type ();

                  this.client.signal_manager.show_signal_details (class_type,
                      signal_name, detail_string);
                }
            }
        }

      return 0;
    }

  public override string[]? complete_subcommand (string subcommand)
    {
      /* @subcommand should be a backend name */
      /* TODO */
      return Readline.completion_matches (subcommand,
          Utils.backend_name_completion_cb);
    }

  private bool parse_signal_id (string input,
      out Type class_type,
      out Object? class_instance,
      out string? signal_name,
      out string? detail_string)
    {
      /* We accept any of the following formats:
       *  ClassName::signal-name
       *  ClassName::signal-name::detail
       *  0xdeadbeef::signal-name
       *  0xdeadbeef::signal-name::detail
       *  ClassName
       *  0xdeadbeef
       *
       * We output exactly one of class_type and class_instance, and optionally
       * output signal_name and/or detail_string as appropriate.
       */
      assert (input != null && input != "");

      /* Default output */
      class_type = Type.INVALID;
      class_instance = null;
      signal_name = null;
      detail_string = null;

      string[] parts = input.split ("::", 3);
      string class_name_or_instance = parts[0];
      string signal_name_inner = (parts.length > 1) ? parts[1] : null;
      string detail_string_inner = (parts.length > 2) ? parts[2] : null;

      if (signal_name_inner == "" || detail_string_inner == "")
        {
          Utils.print_line ("Invalid signal identifier '%s'.", input);
          return false;
        }

      if (class_name_or_instance.length > 2 &&
          class_name_or_instance[0] == '0' && class_name_or_instance[1] == 'x')
        {
          /* We have a class instance. The ‘0x’ prefix ensures it will be
           * parsed in base 16. */
          var address = uint64.parse (class_name_or_instance);
          class_instance = (Object) address;
          assert (class_instance.get_type ().is_object ());
        }
      else
        {
          /* We have a class name */
          class_type = Type.from_name (class_name_or_instance);
          if (class_type == Type.INVALID ||
              (class_type.is_instantiatable () == false &&
               class_type.is_interface () == false))
            {
              Utils.print_line ("Unrecognised class name '%s'.",
                  class_name_or_instance);
              return false;
            }
        }

      signal_name = signal_name_inner;
      detail_string = detail_string_inner;

      return true;
    }
}
