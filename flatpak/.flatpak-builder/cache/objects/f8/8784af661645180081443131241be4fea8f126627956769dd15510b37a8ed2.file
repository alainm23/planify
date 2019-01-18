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

public class Folks.Inspect.SignalManager : Object
{
  /* Map from class type → map from signal ID to hook ID */
  private HashMap<Type, HashMap<uint, ulong>> signals_by_class_type;
  /* Map from class instance → map from signal ID to hook ID */
  private HashMap<Object, HashMap<uint, ulong>> signals_by_class_instance;

  public SignalManager ()
    {
      this.signals_by_class_type =
          new HashMap<Type, HashMap<uint, ulong>> ();
      this.signals_by_class_instance =
          new HashMap<Object, HashMap<uint, ulong>> ();
    }

  public void list_signals (Type class_type,
      Object? class_instance)
    {
      if (class_type != Type.INVALID)
        {
          /* List the signals we're connected to via emission hooks on this
           * class type */
          HashMap<uint, ulong> hook_ids =
              this.signals_by_class_type.get (class_type);

          Utils.print_line ("Signals on all instances of class type '%s':",
              class_type.name ());
          Utils.indent ();
          this.list_signals_for_type (class_type, hook_ids);
          Utils.unindent ();
        }
      else if (class_instance != null)
        {
          /* List the signals we're connected to on this class instance */
          HashMap<uint, ulong> signal_handler_ids =
              this.signals_by_class_instance.get (class_instance);

          Utils.print_line ("Signals on instance %p of class type '%s':",
              class_instance, class_instance.get_type ().name ());
          Utils.indent ();
          this.list_signals_for_type (class_instance.get_type (),
              signal_handler_ids);
          Utils.unindent ();
        }
      else
        {
          /* List all the signals we're connected to on everything */
          MapIterator<Type, HashMap<uint, ulong>> class_type_iter =
              this.signals_by_class_type.map_iterator ();

          Utils.print_line ("Connected signals on all instances of classes:");

          Utils.indent ();
          while (class_type_iter.next () == true)
            {
              HashMap<uint, ulong> hook_ids = class_type_iter.get_value ();
              MapIterator<uint, ulong> hook_iter =  hook_ids.map_iterator ();

              string class_name = class_type_iter.get_key ().name ();
              while (hook_iter.next () == true)
                {
                  Utils.print_line ("%s::%s — connected", class_name,
                      Signal.name (hook_iter.get_key ()));
                }
            }
          Utils.unindent ();

          MapIterator<Object, HashMap<uint, ulong>> class_instance_iter =
              this.signals_by_class_instance.map_iterator ();

          Utils.print_line ("Connected signals on specific instances of " +
              "classes:");

          Utils.indent ();
          while (class_instance_iter.next () == true)
            {
              HashMap<uint, ulong> signal_handler_ids =
                  class_instance_iter.get_value ();
              MapIterator<uint, ulong> signal_handler_iter =
                  signal_handler_ids.map_iterator ();

              string class_name =
                  class_instance_iter.get_key ().get_type ().name ();
              while (signal_handler_iter.next () == true)
                {
                  Utils.print_line ("%s::%s — connected", class_name,
                      Signal.name (signal_handler_iter.get_key ()));
                }
            }
          Utils.unindent ();
        }
    }

  public void show_signal_details (Type class_type,
      string? signal_name,
      string? detail_string)
    {
      uint signal_id = Signal.lookup (signal_name, class_type);
      if (signal_id == 0)
        {
          Utils.print_line ("Unrecognised signal name '%s' on class '%s'.",
              signal_name, class_type.name ());
          return;
        }

      /* Query the signal's information */
      SignalQuery query_info;
      Signal.query (signal_id, out query_info);

      /* Print the query response */
      Utils.print_line ("Signal ID        %u", query_info.signal_id);
      Utils.print_line ("Signal name      %s", query_info.signal_name);
      Utils.print_line ("Emitting type    %s", query_info.itype.name ());
      Utils.print_line ("Signal flags     %s",
          SignalManager.signal_flags_to_string (query_info.signal_flags));
      Utils.print_line ("Return type      %s", query_info.return_type.name ());
      Utils.print_line ("Parameter types:");
      Utils.indent ();
      for (uint i = 0; i < query_info.n_params; i++)
        Utils.print_line ("%-4u  %s", i, query_info.param_types[i].name ());
      Utils.unindent ();
    }

  public uint connect_to_signal (Type class_type,
      Object? class_instance,
      string? signal_name,
      string? detail_string)
    {
      /* We return the number of signals we connected to */
      if (class_type != Type.INVALID && signal_name != null)
        {
          /* Connecting to a given signal on all instances of a class */
          uint signal_id = Signal.lookup (signal_name, class_type);
          if (signal_id == 0)
            {
              Utils.print_line ("Unrecognised signal name '%s' on class '%s'.",
                  signal_name, class_type.name ());
              return 0;
            }

          if (this.add_emission_hook (class_type, signal_id,
              detail_string) == false)
            {
              Utils.print_line ("Not allowed to connect to signal '%s' on " +
                  "class '%s'.", signal_name, class_type.name ());
              return 0;
            }

          return 1;
        }
      else if (class_type != Type.INVALID && signal_name == null)
        {
          /* Connecting to all signals on all instances of a class */
          uint[] signal_ids = Signal.list_ids (class_type);
          uint signal_count = 0;

          foreach (uint signal_id in signal_ids)
            {
              if (this.add_emission_hook (class_type, signal_id, null) == true)
                signal_count++;
            }

          return signal_count;
        }
      else if (class_instance != null && signal_name != null)
        {
          /* Connecting to a given signal on a given class instance */
          uint signal_id =
              Signal.lookup (signal_name, class_instance.get_type ());
          if (signal_id == 0)
            {
              Utils.print_line ("Unrecognised signal name '%s' on instance " +
                  "%p of class '%s'.", signal_name, class_instance,
                  class_instance.get_type ().name ());
              return 0;
            }

          this.add_signal_handler (class_instance, signal_id, detail_string);

          return 1;
        }
      else if (class_instance != null && signal_name == null)
        {
          /* Connecting to all signals on a given class instance */
          uint[] signal_ids = Signal.list_ids (class_instance.get_type ());
          uint signal_count = 0;

          foreach (uint signal_id in signal_ids)
            {
              signal_count++;
              this.add_signal_handler (class_instance, signal_id, null);
            }

          return signal_count;
        }

      assert_not_reached ();
    }

  public uint disconnect_from_signal (Type class_type,
      Object? class_instance,
      string? signal_name,
      string? detail_string)
    {
      /* We return the number of signals we disconnected from */
      if (class_type != Type.INVALID && signal_name != null)
        {
          /* Disconnecting from a given signal on all instances of a class */
          uint signal_id = Signal.lookup (signal_name, class_type);
          if (signal_id == 0)
            {
              Utils.print_line ("Unrecognised signal name '%s' on class '%s'.",
                  signal_name, class_type.name ());
              return 0;
            }

          if (this.remove_emission_hook (class_type, signal_id) == false)
            {
              Utils.print_line ("Could not remove hook for signal '%s' on " +
                  "class '%s'.", signal_name, class_type.name ());
              return 0;
            }

          return 1;
        }
      else if (class_type != Type.INVALID && signal_name == null)
        {
          /* Disconnecting from all signals on all instances of a class */
          uint[] signal_ids = Signal.list_ids (class_type);
          uint signal_count = 0;

          foreach (uint signal_id in signal_ids)
            {
              if (this.remove_emission_hook (class_type, signal_id) == true)
                signal_count--;
            }

          return signal_count;
        }
      else if (class_instance != null && signal_name != null)
        {
          /* Disconnecting from a given signal on a given class instance */
          uint signal_id =
              Signal.lookup (signal_name, class_instance.get_type ());
          if (signal_id == 0)
            {
              Utils.print_line ("Unrecognised signal name '%s' on instance " +
                  "%p of class '%s'.", signal_name, class_instance,
                  class_instance.get_type ().name ());
              return 0;
            }

          this.remove_signal_handler (class_instance, signal_id);

          return 1;
        }
      else if (class_instance != null && signal_name == null)
        {
          /* Disconnecting from all signals on a given class instance */
          uint[] signal_ids = Signal.list_ids (class_instance.get_type ());
          uint signal_count = 0;

          foreach (uint signal_id in signal_ids)
            {
              if (this.remove_signal_handler (class_instance, signal_id))
                signal_count--;
            }

          return signal_count;
        }

      assert_not_reached ();
    }

  private void list_signals_for_type (Type type,
      HashMap<uint, ulong>? signal_id_map)
    {
      uint[] signal_ids = Signal.list_ids (type);

      /* Print information about the signals on this type */
      if (signal_ids != null)
        {
          string type_name = type.name ();
          foreach (uint signal_id in signal_ids)
            {
              unowned string signal_name = Signal.name (signal_id);

              if (signal_id_map != null &&
                  signal_id_map.has_key (signal_id) == true)
                {
                  Utils.print_line ("%s::%s — connected",
                      type_name, signal_name);
                }
              else
                {
                  Utils.print_line ("%s::%s",
                      type_name, signal_name);
                }
            }
        }

      /* Recurse to the type's interfaces */
      Type[] interfaces = type.interfaces ();
      foreach (Type interface_type in interfaces)
        this.list_signals_for_type (interface_type, signal_id_map);

      /* Chain up to the type's parent */
      Type parent_type = type.parent ();
      if (parent_type != Type.INVALID)
        this.list_signals_for_type (parent_type, signal_id_map);
    }

  /* FIXME: This is necessary because if we do sizeof(Closure), Vala will
   * generate the following C code: sizeof(GClosure*).
   * This is not what we want. */
  [CCode (cname = "sizeof (GClosure)")] extern const int CLOSURE_STRUCT_SIZE;

  private void add_signal_handler (Object class_instance,
      uint signal_id,
      string? detail_string)
    {
      Closure closure = new Closure (SignalManager.CLOSURE_STRUCT_SIZE, this);
      closure.set_meta_marshal (null, SignalManager.signal_meta_marshaller);

      Quark detail_quark = 0;
      if (detail_string != null)
        detail_quark = Quark.try_string (detail_string);

      ulong signal_handler_id = Signal.connect_closure_by_id (class_instance,
          signal_id, detail_quark, closure, false);

      /* Store the signal handler ID so we can list or remove it later */
      HashMap<uint, ulong> signal_handler_ids =
          this.signals_by_class_instance.get (class_instance);
      if (signal_handler_ids == null)
        {
          signal_handler_ids = new HashMap<uint, ulong> ();
          this.signals_by_class_instance.set (class_instance,
              signal_handler_ids);
        }

      signal_handler_ids.set (signal_id, signal_handler_id);
    }

  private bool remove_signal_handler (Object class_instance,
      uint signal_id)
    {
      HashMap<uint, ulong> signal_handler_ids =
          this.signals_by_class_instance.get (class_instance);

      if (signal_handler_ids == null ||
          signal_handler_ids.has_key (signal_id) == false)
        {
          return false;
        }

      ulong signal_handler_id = signal_handler_ids.get (signal_id);
      SignalHandler.disconnect (class_instance, signal_handler_id);
      signal_handler_ids.unset (signal_id);

      return true;
    }

  private static void signal_meta_marshaller (Closure closure,
      out Value? return_value,
      Value[] param_values,
      void *invocation_hint,
      void *marshal_data)
    {
      SignalInvocationHint* hint = (SignalInvocationHint*) invocation_hint;

      /* Default output */
      return_value = null;

      SignalQuery query_info;
      Signal.query (hint->signal_id, out query_info);

      Utils.print_line ("Signal '%s::%s' emitted with parameters:",
          query_info.itype.name (), query_info.signal_name);

      Utils.indent ();
      uint i = 0;
      foreach (Value param_value in param_values)
        {
          Utils.print_line ("%-4u  %-10s  %s", i++, param_value.type ().name (),
              Utils.transform_value_to_string (param_value));
        }
      Utils.unindent ();
    }

  private bool add_emission_hook (Type class_type,
      uint signal_id,
      string? detail_string)
    {
      Quark detail_quark = 0;
      if (detail_string != null)
        detail_quark = Quark.try_string (detail_string);

      /* Query the signal to check it supports emission hooks */
      SignalQuery query;
      Signal.query (signal_id, out query);

      /* FIXME: It would be nice if we could find some way to support NO_HOOKS
       * signals. */
      if ((query.signal_flags & SignalFlags.NO_HOOKS) != 0)
        return false;

      ulong hook_id = Signal.add_emission_hook (signal_id,
#if VALA_0_42
          detail_quark, this.emission_hook_cb);
#else
          detail_quark, this.emission_hook_cb, null);
#endif

      /* Store the hook ID so we can list or remove it later */
      HashMap<uint, ulong> hook_ids =
          this.signals_by_class_type.get (class_type);
      if (hook_ids == null)
        {
          hook_ids = new HashMap<uint, ulong> ();
          this.signals_by_class_type.set (class_type, hook_ids);
        }

      hook_ids.set (signal_id, hook_id);

      return true;
    }

  private bool remove_emission_hook (Type class_type,
      uint signal_id)
    {
      HashMap<uint, ulong> hook_ids =
          this.signals_by_class_type.get (class_type);

      if (hook_ids == null || hook_ids.has_key (signal_id) == false)
        return false;

      ulong hook_id = hook_ids.get (signal_id);
      Signal.remove_emission_hook (signal_id, hook_id);
      hook_ids.unset (signal_id);

      return true;
    }

  private bool emission_hook_cb (SignalInvocationHint hint,
      Value[] param_values)
    {
      SignalQuery query_info;
      Signal.query (hint.signal_id, out query_info);

      Utils.print_line ("Signal '%s::%s' emitted with parameters:",
          query_info.itype.name (), query_info.signal_name);

      Utils.indent ();
      uint i = 0;
      foreach (Value param_value in param_values)
        {
          Utils.print_line ("%-4u  %-10s  %s", i++, param_value.type ().name (),
              Utils.transform_value_to_string (param_value));
        }
      Utils.unindent ();

      return true;
    }

  private static string signal_flags_to_string (SignalFlags flags)
    {
      string output = "";

      if ((flags & SignalFlags.RUN_FIRST) != 0)
        output += "G_SIGNAL_RUN_FIRST";
      if ((flags & SignalFlags.RUN_LAST) != 0)
        output += ((output != "") ? " | " : "") + "G_SIGNAL_RUN_LAST";
      if ((flags & SignalFlags.RUN_CLEANUP) != 0)
        output += ((output != "") ? " | " : "") + "G_SIGNAL_RUN_CLEANUP";
      if ((flags & SignalFlags.DETAILED) != 0)
        output += ((output != "") ? " | " : "") + "G_SIGNAL_DETAILED";
      if ((flags & SignalFlags.ACTION) != 0)
        output += ((output != "") ? " | " : "") + "G_SIGNAL_ACTION";
      if ((flags & SignalFlags.NO_HOOKS) != 0)
        output += ((output != "") ? " | " : "") + "G_SIGNAL_NO_HOOKS";

      return output;
    }
}
