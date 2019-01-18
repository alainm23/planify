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

using GLib;
using Gee;
using Folks;
using Folks.Backends.Kf;

extern const string BACKEND_NAME;

/**
 * A backend which loads {@link Persona}s from a simple key file in
 * (XDG_DATA_HOME/folks/) and presents them through a single
 * {@link PersonaStore}.
 *
 * @since 0.1.13
 */
public class Folks.Backends.Kf.Backend : Folks.Backend
{
  private bool _is_prepared = false;
  private bool _prepare_pending = false; /* used for unprepare() too */
  private bool _is_quiescent = false;
  private HashMap<string, PersonaStore> _persona_stores;
  private Map<string, PersonaStore> _persona_stores_ro;

  /**
   * Whether this Backend has been prepared.
   *
   * See {@link Folks.Backend.is_prepared}.
   *
   * @since 0.3.0
   */
  public override bool is_prepared
    {
      get { return this._is_prepared; }
    }

  /**
   * Whether this Backend has reached a quiescent state.
   *
   * See {@link Folks.Backend.is_quiescent}.
   *
   * @since 0.6.2
   */
  public override bool is_quiescent
    {
      get { return this._is_quiescent; }
    }

  /**
   * {@inheritDoc}
   */
  public override string name { get { return BACKEND_NAME; } }

  /**
   * {@inheritDoc}
   */
  public override Map<string, Folks.PersonaStore> persona_stores
    {
      get { return this._persona_stores_ro; }
    }

  /**
   * {@inheritDoc}
   */
  public override void enable_persona_store (Folks.PersonaStore store)
    {
      if (this._persona_stores.has_key (store.id) == false)
        {
          this._add_store ((Kf.PersonaStore) store);
        }
    }
    
  /**
   * {@inheritDoc}
   */
  public override void disable_persona_store (Folks.PersonaStore store)
    {
      if (this._persona_stores.has_key (store.id))
        {
          this._store_removed_cb (store);
        }
    }

  private File _get_default_file (string basename = "relationships")
    {
      string filename = basename + ".ini";
      File file = File.new_for_path (Environment.get_user_data_dir ());
      file = file.get_child ("folks");
      file = file.get_child (filename);
      return file;
    }
    
  /**
   * {@inheritDoc}
   * In this implementation storeids are assumed to be base filenames for
   * ini files under user_data_dir()/folks/ like the default relationships 
   * {@link PersonaStore}.
   */
  public override void set_persona_stores (Set<string>? storeids)
    {
      /* All ids represent ini files in user_data_dir/folks/ */
      
      bool added_stores = false;
      PersonaStore[] removed_stores = {};
      
      /* First handle adding any missing persona stores. */
      foreach (string id in storeids)
        {
          if (this._persona_stores.has_key (id) == false)
            {
              File file = this._get_default_file (id);
              
              PersonaStore store = new Kf.PersonaStore (file);
              this._add_store (store, false);
              added_stores = true;
            }
        }
        
        foreach (PersonaStore store in this._persona_stores.values)
          {
            if (!storeids.contains (store.id))
              {
                removed_stores += store;
              }
          }
        
        for (int i = 0; i < removed_stores.length; ++i)
          {
            this._remove_store ((Kf.PersonaStore) removed_stores[i], false);
          }
        
        /* Finally, if anything changed, emit the persona-stores notification. */
        if (added_stores || removed_stores.length > 0)
          {
            this.notify_property ("persona-stores");
          }
    }
  
  /**
   * {@inheritDoc}
   */
  public Backend ()
    {
      Object ();
    }

  construct
    {
      this._persona_stores = new HashMap<string, PersonaStore> ();
      this._persona_stores_ro = this._persona_stores.read_only_view;
    }

  /**
   * {@inheritDoc}
   */
  public override async void prepare () throws GLib.Error
    {
      Internal.profiling_start ("preparing Kf.Backend");

      if (this._is_prepared || this._prepare_pending)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;
          this.freeze_notify ();

          File file;
          unowned string path = Environment.get_variable (
              "FOLKS_BACKEND_KEY_FILE_PATH");
          if (path == null)
            {
              file = this._get_default_file ();

              debug ("Using built-in key file '%s' (override with " +
                  "environment variable FOLKS_BACKEND_KEY_FILE_PATH)",
                  file.get_path ());
            }
          else
            {
              file = File.new_for_path (path);
              debug ("Using environment variable " +
                  "FOLKS_BACKEND_KEY_FILE_PATH = '%s' to load the key " +
                  "file.", path);
            }

          /* Create the PersonaStore for the key file */
          PersonaStore store = new Kf.PersonaStore (file);
          
          this._add_store (store);

          this._is_prepared = true;
          this.notify_property ("is-prepared");

          this._is_quiescent = true;
          this.notify_property ("is-quiescent");
        }
      finally
        {
          this.thaw_notify ();
          this._prepare_pending = false;
        }

      Internal.profiling_end ("preparing Kf.Backend");
    }

  /**
   * Utility function to add a persona store.
   *
   * @param store the store to add.
   * @param notify whether or not to emit notification signals.
   */
  private void _add_store (PersonaStore store, bool notify = true)
    {
      this._persona_stores.set (store.id, store);
      store.removed.connect (this._store_removed_cb);
      this.persona_store_added (store);
      if (notify)
        {
          this.notify_property ("persona-stores");
        }
    }
    
  /**
   * Utility function to remove a persona store.
   *
   * @param store the store to remove.
   * @param notify whether or not to emit notification signals.
   */
  private void _remove_store (PersonaStore store, bool notify = true)
    {
      store.removed.disconnect (this._store_removed_cb);
      this._persona_stores.unset (store.id);
      this.persona_store_removed (store);

      if (notify)
        {
          this.notify_property ("persona-stores");
        }
    }
  
  /**
   * {@inheritDoc}
   */
  public override async void unprepare () throws GLib.Error
    {
      if (!this._is_prepared || this._prepare_pending == true)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;
          this.freeze_notify ();

          foreach (var persona_store in this._persona_stores.values)
            {
              this.persona_store_removed (persona_store);
            }

          this._persona_stores.clear ();
          this.notify_property ("persona-stores");

          this._is_quiescent = false;
          this.notify_property ("is-quiescent");

          this._is_prepared = false;
          this.notify_property ("is-prepared");
        }
      finally
        {
          this.thaw_notify ();
          this._prepare_pending = false;
        }
    }

  private void _store_removed_cb (Folks.PersonaStore store)
    {
      this._remove_store ((Kf.PersonaStore) store);
    }
}
