/*
 * Copyright (C) 2010 Collabora Ltd.
 * Copyright (C) 2012 Philip Withnall
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

using Folks.Inspect.Commands;
using Folks;
using Readline;
using Gee;
using GLib;
using Posix;

/* We have to have a static global instance so that the readline callbacks can
 * access its data, since they don't pass closures around. */
static Inspect.Client main_client = null;

public class Folks.Inspect.Client : Object
{
  public HashMap<string, Command> commands;
  private static bool _is_readline_installed;
  private MainLoop main_loop;
  public IndividualAggregator aggregator { get; private set; }
  public BackendStore backend_store { get; private set; }
  public SignalManager signal_manager { get; private set; }

  /* To page or not to page? */
  private termios _original_termios_p;
  private bool _original_termios_p_valid = false;
  private bool _quit_after_pager_dies = false;
  private static Pid _pager_pid = 0;
  private IOChannel? _stdin_channel = null;
  private static uint _stdin_watch_id = 0;
  private FileStream? _pager_channel = null;
  private uint _pager_child_watch_id = 0;

  public static int main (string[] args)
    {
      int retval = 0;

      Intl.setlocale (LocaleCategory.ALL, "");
      Intl.bindtextdomain (BuildConf.GETTEXT_PACKAGE, BuildConf.LOCALE_DIR);
      Intl.textdomain (BuildConf.GETTEXT_PACKAGE);

      /* Parse command line options. */
      OptionContext context = new OptionContext ("[COMMAND]");
      context.set_summary ("Inspect meta-contact information in libfolks.");

      try
        {
          context.parse (ref args);
        }
      catch (OptionError e1)
        {
          GLib.stderr.printf ("Couldn’t parse command line options: %s\n",
              e1.message);
          return 1;
        }

      /* Create the client. */
      main_client = new Client ();

      /* Set up signal handling. */
#if VALA_0_40
      Unix.signal_add (Posix.Signal.TERM, () =>
#else
      Unix.signal_add (Posix.SIGTERM, () =>
#endif
        {
          /* Propagate the signal to our pager process, if it's running. */
          if (Client._pager_pid != 0)
            {
              main_client._quit_after_pager_dies = true;
#if VALA_0_40
              kill (Client._pager_pid, Posix.Signal.TERM);
#else
              kill (Client._pager_pid, Posix.SIGTERM);
#endif
            }
          else
            {
              /* Quit the client and let that exit the process. */
              main_client.quit ();
            }

          return false;
        });

      /* Run the command. */
      if (args.length == 1)
        {
          main_client.run_interactive.begin ();
          retval = 0;
        }
      else
        {
          GLib.assert (args.length > 1);

          /* Drop the first argument and parse the rest as a command line. If
           * the first argument is ‘--’ then the command was passed after some
           * flags. */
          string command_line;
          if (args[1] == "--")
            {
              command_line = string.joinv (" ", args[2:0]);
            }
          else
            {
              command_line = string.joinv (" ", args[1:0]);
            }

          main_client.run_non_interactive.begin (command_line, (obj, res) =>
          {
            retval = main_client.run_non_interactive.end (res);
            main_client.quit ();
          });
        }
        
      main_client.main_loop.run ();

      return retval;
    }

  public Client ()
    {
      Utils.init ();

      this.commands = new HashMap<string, Command> ();

      /* Register the commands we support */
      /* FIXME: This should be automatic */
      this.commands.set ("quit", new Commands.Quit (this));
      this.commands.set ("help", new Commands.Help (this));
      this.commands.set ("individuals", new Commands.Individuals (this));
      this.commands.set ("linking", new Commands.Linking (this));
      this.commands.set ("personas", new Commands.Personas (this));
      this.commands.set ("backends", new Commands.Backends (this));
      this.commands.set ("persona-stores", new Commands.PersonaStores (this));
      this.commands.set ("set", new Commands.Set (this));
      this.commands.set ("signals", new Commands.Signals (this));
      this.commands.set ("debug", new Commands.Debug (this));
      this.commands.set ("search", new Commands.Search (this));

      /* Create various bits of folks machinery. */
      this.main_loop = new MainLoop ();
      this.signal_manager = new SignalManager ();
      this.backend_store = BackendStore.dup ();
      this.aggregator = IndividualAggregator.dup ();
    }

  public void quit ()
    {
      /* Stop paging. */
      this._stop_paged_output ();

      /* Uninstall readline, if it's installed. */
      if (Client._is_readline_installed)
        {
          this._uninstall_readline_and_stdin ();
        }

      /* Restore the user's original terminal settings, since the pager might've
       * fiddled with them. */
      if (this._original_termios_p_valid)
        {
          tcsetattr (Posix.STDIN_FILENO, Posix.TCSADRAIN,
              this._original_termios_p);
        }

      /* Kill the main loop. */
      this.main_loop.quit ();
    }

  private async void _wait_for_quiescence () throws GLib.Error
    {
      var has_yielded = false;
      var signal_id = this.aggregator.notify["is-quiescent"].connect (
          (obj, pspec) =>
        {
          if (has_yielded == true)
            {
              this._wait_for_quiescence.callback ();
            }
        });

      try
        {
          yield this.aggregator.prepare ();

          if (this.aggregator.is_quiescent == false)
            {
              has_yielded = true;
              yield;
            }
        }
      finally
        {
          this.aggregator.disconnect (signal_id);
          GLib.assert (this.aggregator.is_quiescent == true);
        }
    }

  public async int run_non_interactive (string command_line)
    {
      /* Non-interactive mode: run a single command and output the results.
       * We do this all from the main thread, in a main loop, waiting for
       * quiescence before running the command. */

      /* Check we can parse the command first. */
      string subcommand;
      string command_name;
      var command = Client.parse_command_line (command_line, out command_name,
          out subcommand);

      if (command == null)
        {
          GLib.stdout.printf ("Unrecognised command ‘%s’.\n", command_name);
          return 1;
        }

      /* Wait until we reach quiescence, or the results will probably be
       * useless. */
      try
        {
          yield this._wait_for_quiescence ();
        }
      catch (GLib.Error e1)
        {
          GLib.stderr.printf ("Error preparing aggregator: %s\n", e1.message);
          return 1;
        }

      /* Run the command */
      int retval = yield command.run (subcommand);
      this.quit ();

      return retval;
    }

  public async int run_interactive ()
    {
      /* Interactive mode: have a little shell which allows the data from
       * libfolks to be browsed and edited in real time. We do this by watching
       * stdin in our main loop, and passing character notifications to
       * readline. The main loop also processes all the folks events, thus
       * preventing us having to run a second thread. */

      /* Copy the user's original terminal settings. */
      if (tcgetattr (Posix.STDIN_FILENO, out this._original_termios_p) == 0)
        {
          this._original_termios_p_valid = true;
        }

      /* Handle SIGINT. */
#if VALA_0_40
      Unix.signal_add (Posix.Signal.INT, () =>
#else
      Unix.signal_add (Posix.SIGINT, () =>
#endif
        {
          if (Client._is_readline_installed == false)
            {
              return true;
            }

          /* Tidy up. */
          Readline.free_line_state ();
          Readline.cleanup_after_signal ();
          Readline.reset_after_signal ();

          /* Display a fresh prompt. */
          GLib.stdout.printf ("^C");
          Readline.crlf ();
          Readline.reset_line_state ();
          Readline.replace_line ("", 0);
          Readline.redisplay ();

          return true;
        });

      /* Allow things to be set for folks-inspect in ~/.inputrc, and install our
       * own completion function. */
      Readline.readline_name = "folks-inspect";
      Readline.attempted_completion_function = Client.completion_cb;
      Readline.catch_signals = 0; /* go away, readline */

      /* Install readline and the stdin handler. */
      this._stdin_channel = new IOChannel.unix_new (GLib.stdin.fileno ());
      this._install_readline_and_stdin ();

      /* Run the aggregator and the main loop. */
      this.aggregator.prepare.begin ();

      return 0;
    }

  private void _install_readline_and_stdin ()
    {
      /* stdin handler. */
      Client._stdin_watch_id = this._stdin_channel.add_watch (IOCondition.IN,
          this._stdin_handler_cb);

      /* Callback for each character appearing on stdin. */
      Readline.callback_handler_install ("> ", Client._readline_handler_cb);
      Client._is_readline_installed = true;
    }

  private void _uninstall_readline_and_stdin ()
    {
      Readline.callback_handler_remove ();
      Client._is_readline_installed = false;

      Source.remove (Client._stdin_watch_id);
      Client._stdin_watch_id = 0;
    }

  /* This should only ever be called while readline is installed. */
  private bool _stdin_handler_cb (IOChannel source, IOCondition cond)
    {
      /* At least a single character is available on stdin, so let readline
       * consume it. */
      if ((cond & IOCondition.IN) != 0)
        {
          Readline.callback_read_char ();
          return true;
        }

      assert_not_reached ();
    }

  private static void _readline_handler_cb (string? _command_line)
    {
      if (_command_line == null)
        {
          /* EOF. If we've entered some text, don't do anything. Otherwise,
           * quit. */
          if (Readline.line_buffer != "")
            {
              Readline.ding ();
              return;
            }

          /* Quit. */
          main_client.quit ();

          return;
        }

      var command_line = (!) _command_line;

      command_line = command_line.strip ();
      if (command_line == "")
        {
          /* If the user's entered a blank line, just display a new prompt
           * without doing anything else. */
          return;
        }

      string subcommand;
      string command_name;
      Command command = Client.parse_command_line (command_line,
          out command_name, out subcommand);

      /* Run the command */
      if (command != null)
        {
          if (command_name != "quit")
            {
              /* Start paging output. This is stopped when the pager dies. */
              main_client._start_paged_output ();
            }

          command.run.begin (subcommand, (obj, res) =>
            {
              command.run.end (res);

              if (main_client._pager_channel != null)
                {
                  /* Close the stream to the pager so it knows it's
                   * reached EOF. */
                  main_client._pager_channel = null;
                  Utils.output_filestream = GLib.stdout;
                }
              else
                {
                  /* Failed to start the pager in the first place. */
                  Readline.reset_line_state ();
                  Readline.replace_line ("", 0);
                  Readline.redisplay ();
                }
            });

        }
      else
        {
          GLib.stdout.printf ("Unrecognised command ‘%s’.\n", command_name);
        }

      /* Store the command in the history, even if it failed */
      Readline.History.add (command_line);
    }

  private void _start_paged_output ()
    {
      /* If the output is not a TTY (because it's a pipe or a file or a
       * toaster) we don't page. */
      if (!isatty (1))
        {
          return;
        }

      var pager = Environment.get_variable ("PAGER");
      if (pager != null && pager == "")
        {
          return;
        }

      if (pager == null)
        {
          pager = "less -FRSX";
        }

      /* Convert command to null terminated array */
      string[] args;
      try
        {
          GLib.Shell.parse_argv (pager, out args);
        }
      catch (GLib.ShellError e)
        {
          warning ("Error parsing pager arguments: %s", e.message);
          return;
        }

      /* Remove the readline and stdin handlers while the pager is running. */
      this._uninstall_readline_and_stdin ();

      /* Store the readline terminal state so that we can restore them
       * after the pager has exited. */
      Readline.prep_terminal (1);

      /* Spawn the pager. */
      int pager_fd = 0;

      try
        {
          GLib.Process.spawn_async_with_pipes (null,
              args,
              null,
              GLib.SpawnFlags.LEAVE_DESCRIPTORS_OPEN |
                  GLib.SpawnFlags.SEARCH_PATH |
                  GLib.SpawnFlags.DO_NOT_REAP_CHILD /* we use a ChildWatch */,
              null,
              out Client._pager_pid,
              out pager_fd, // Std input
              null, // Std out
              null); // Std error
        }
      catch (SpawnError e2)
        {
          warning ("Error spawning pager: %s", e2.message);

          /* Reinstall the readline handler and stdin handler. */
          this._install_readline_and_stdin ();

          return;
        }

      /* Redirect our output to the pager. */
      this._pager_channel = FileStream.fdopen (pager_fd, "w");
      Utils.output_filestream = this._pager_channel;

      /* Watch for when the pager exits. */
      this._pager_child_watch_id = ChildWatch.add (Client._pager_pid,
          (pid, status) =>
            {
              /* $PAGER died or was killed. */
              this._stop_paged_output ();

              /* Reset the readline state ready to display a new prompt. If the
               * pager exited as the result of a signal, it probably didn't
               * tidy up after itself (e.g. ``less`` leaves a colon prompt
               * behind on the current line), so move to a new line. Doing this
               * normally just looks a bit weird. */
              if (Process.if_signaled (status))
                {
                  Readline.crlf ();
                }

              Readline.reset_line_state ();
              Readline.replace_line ("", 0);

              /* Are we supposed to quit (e.g. due to receiving a SIGTERM)? */
              if (this._quit_after_pager_dies)
                {
                  main_client.quit ();
                  return;
                }

              /* Reinstall the readline handler and stdin handler. */
              this._install_readline_and_stdin ();
            });
    }

  private void _stop_paged_output ()
    {
      if (Client._pager_pid == 0)
        {
          return;
        }

      Process.close_pid (Client._pager_pid);
      Source.remove (this._pager_child_watch_id);

      this._pager_channel = null;
      Utils.output_filestream = GLib.stdout;
      Client._pager_pid = 0;
      this._pager_child_watch_id = 0;

      /* Reset the terminal state (e.g. ECHO, which can get left turned
       * off if the pager was killed uncleanly). */
      Readline.deprep_terminal ();
      Readline.free_line_state ();
      Readline.cleanup_after_signal ();
      Readline.reset_after_signal ();
    }

  private static Command? parse_command_line (string command_line,
      out string command_name,
      out string? subcommand)
    {
      /* Default output */
      command_name = "";
      subcommand = null;

      string[] parts = command_line.split (" ", 2);

      if (parts.length < 1)
        return null;

      command_name = parts[0];
      if (parts.length == 2 && parts[1] != "")
        subcommand = parts[1];
      else
        subcommand = null;

      /* Extract the first part of the command and see if it matches anything in
       * this.commands */
      return main_client.commands.get (parts[0]);
    }

  [CCode (array_length = false, array_null_terminated = true)]
  private static string[]? completion_cb (string word,
      int start,
      int end)
    {
      /* word is the word to complete, and start and end are its bounds inside
       * Readline.line_buffer, which contains the entire current line. */

      /* Command name completion */
      if (start == 0)
        {
          return Readline.completion_matches (word,
              Utils.command_name_completion_cb);
        }

      /* Command parameter completion is passed off to the Command objects */
      string command_name;
      string subcommand;
      Command command = Client.parse_command_line (Readline.line_buffer,
          out command_name,
          out subcommand);

      if (command != null)
        {
          if (subcommand == null)
            subcommand = "";
          return command.complete_subcommand (subcommand);
        }

      return null;
    }
}

public abstract class Folks.Inspect.Command
{
  protected Client client;

  public Command (Client client)
    {
      this.client = client;
    }

  public abstract string name { get; }
  public abstract string description { get; }
  public abstract string help { get; }

  public abstract async int run (string? command_string);

  public virtual string[]? complete_subcommand (string subcommand)
    {
      /* Default implementation */
      return null;
    }
}
