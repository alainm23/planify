/*
 * Copyright (C) 2013 Philip Withnall
 * Copyright (C) 2013 Collabora Ltd.
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

using Gee;
using GLib;
using Folks;

extern const string BACKEND_NAME;

/**
 * A backend which allows {@link FolksDummy.PersonaStore}s and
 * {@link FolksDummy.Persona}s to be programmatically created and manipulated,
 * for the purposes of testing the core of libfolks itself.
 *
 * This backend is not meant to be enabled in production use. The methods on
 * {@link FolksDummy.Backend} (and other classes) for programmatically
 * manipulating the backend's state are considered internal to libfolks and are
 * not stable.
 *
 * This backend maintains two sets of persona stores: the set of all persona
 * stores, and the set of enabled persona stores (which must be a subset of the
 * former). {@link FolksDummy.Backend.register_persona_stores} adds persona
 * stores to the set of all stores. Optionally it also enables them, adding them
 * to the set of enabled stores. The set of persona stores advertised by the
 * backend as {@link Folks.Backend.persona_stores} is the set of enabled stores.
 * libfolks may internally enable or disable stores using
 * {@link Folks.Backend.enable_persona_store},
 * {@link Folks.Backend.disable_persona_store}
 * and {@link Folks.Backend.set_persona_stores}.  The ``register_`` and
 * ``unregister_`` prefixes are commonly used for backend methods.
 *
 * The API in {@link FolksDummy} is unstable and may change wildly. It is
 * designed mostly for use by libfolks unit tests.
 *
 * @since 0.9.7
 */
public class FolksDummy.Backend : Folks.Backend
{
  private bool _is_prepared = false;
  private bool _prepare_pending = false; /* used for unprepare() too */
  private bool _is_quiescent = false;

  private HashMap<string, PersonaStore> _all_persona_stores;
  private HashMap<string, PersonaStore> _enabled_persona_stores;
  private Map<string, PersonaStore> _enabled_persona_stores_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public Backend ()
    {
      Object ();
    }

  construct
    {
      this._all_persona_stores = new HashMap<string, PersonaStore> ();
      this._enabled_persona_stores = new HashMap<string, PersonaStore> ();
      this._enabled_persona_stores_ro =
          this._enabled_persona_stores.read_only_view;
    }

  /**
   * Whether this Backend has been prepared.
   *
   * See {@link Folks.Backend.is_prepared}.
   *
   * @since 0.9.7
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
   * @since 0.9.7
   */
  public override bool is_quiescent
    {
      get { return this._is_quiescent; }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override string name { get { return BACKEND_NAME; } }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override Map<string, Folks.PersonaStore> persona_stores
    {
      get { return this._enabled_persona_stores_ro; }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override void disable_persona_store (Folks.PersonaStore store)
    {
      this._disable_persona_store (store);
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override void enable_persona_store (Folks.PersonaStore store)
    {
      this._enable_persona_store ((FolksDummy.PersonaStore) store);
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override void set_persona_stores (Set<string>? store_ids)
    {
      /* If the set is empty, load all unloaded stores then return. */
      if (store_ids == null)
        {
          this.freeze_notify ();
          foreach (var store in this._all_persona_stores.values)
            {
              this._enable_persona_store (store);
            }
          this.thaw_notify ();

          return;
        }

      /* First handle adding any missing persona stores. */
      this.freeze_notify ();

      foreach (var id in store_ids)
        {
          if (!this._enabled_persona_stores.has_key (id))
            {
              var store = this._all_persona_stores.get (id);
              if (store != null)
                {
                  this._enable_persona_store (store);
                }
            }
        }

      /* Keep persona stores to remove in a separate array so we don't
       * invalidate the list we are iterating over. */
      PersonaStore[] stores_to_remove = {};

      foreach (var store in this._enabled_persona_stores.values)
        {
          if (!store_ids.contains (store.id))
            {
              stores_to_remove += store;
            }
        }

      foreach (var store in stores_to_remove)
        {
          this._disable_persona_store (store);
        }

      this.thaw_notify ();
    }

  private void _enable_persona_store (PersonaStore store)
    {
      if (this._enabled_persona_stores.has_key (store.id))
        {
          return;
        }
      assert (this._all_persona_stores.has_key (store.id));

      store.removed.connect (this._store_removed_cb);

      this._enabled_persona_stores.set (store.id, store);

      this.persona_store_added (store);
      this.notify_property ("persona-stores");
    }

  private void _disable_persona_store (Folks.PersonaStore store)
    {
      if (!this._enabled_persona_stores.unset (store.id))
        {
          return;
        }
      assert (this._all_persona_stores.has_key (store.id));

      this.persona_store_removed (store);
      this.notify_property ("persona-stores");

      store.removed.disconnect (this._store_removed_cb);
    }

  private void _store_removed_cb (Folks.PersonaStore store)
    {
      this._disable_persona_store (store);
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override async void prepare () throws GLib.Error
    {
      Internal.profiling_start ("preparing Dummy.Backend");

      if (this._is_prepared || this._prepare_pending)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;
          this.freeze_notify ();

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

      Internal.profiling_end ("preparing Dummy.Backend");
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override async void unprepare () throws GLib.Error
    {
      if (!this._is_prepared || this._prepare_pending)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;
          this.freeze_notify ();

          var enabled_stores = this._enabled_persona_stores.values.to_array ();
          foreach (var persona_store in enabled_stores)
            {
              this._disable_persona_store (persona_store);
            }

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


  /*
   * All the functions below here are to be used by testing code rather than by
   * libfolks clients. They form the interface which would normally be between
   * the Backend and a web service or backing store of some kind.
   */


  /**
   * Register and enable some {@link FolksDummy.PersonaStore}s.
   *
   * For each of the persona stores in ``stores``, register it with this
   * backend. If ``enable_stores`` is ``true``, added stores will also be
   * enabled, emitting {@link Folks.Backend.persona_store_added} for each
   * newly-enabled store. After all addition signals are emitted, a change
   * notification for {@link Folks.Backend.persona_stores} will be emitted (but
   * only if at least one addition signal is emitted).
   *
   * Persona stores are identified by their {@link Folks.PersonaStore.id}; if a
   * store in ``stores`` has the same ID as a store previously registered
   * through this method, the duplicate will be ignored (so
   * {@link Folks.Backend.persona_store_added} won't be emitted for that store).
   *
   * Persona stores must be instances of {@link FolksDummy.PersonaStore} or
   * subclasses of it, allowing for different persona store implementations to
   * be tested.
   *
   * @param stores set of persona stores to register
   * @param enable_stores whether to automatically enable the stores
   * @since 0.9.7
   */
  public void register_persona_stores (Set<PersonaStore> stores,
      bool enable_stores = true)
    {
      this.freeze_notify ();

      foreach (var store in stores)
        {
          assert (store is FolksDummy.PersonaStore);

          if (this._all_persona_stores.has_key (store.id))
            {
              continue;
            }

          this._all_persona_stores.set (store.id, store);

          if (enable_stores == true)
            {
              this._enable_persona_store (store);
            }
        }

      this.thaw_notify ();
    }

  /**
   * Disable and unregister some {@link FolksDummy.PersonaStore}s.
   *
   * For each of the persona stores in ``stores``, disable it (if it was
   * enabled) and unregister it from the backend so that it cannot be re-enabled
   * using {@link Folks.Backend.enable_persona_store} or
   * {@link Folks.Backend.set_persona_stores}.
   *
   * {@link Folks.Backend.persona_store_removed} will be emitted for all persona
   * stores in ``stores`` which were previously enabled. After all removal
   * signals are emitted, a change notification for
   * {@link Folks.Backend.persona_stores} will be emitted (but only if at least
   * one removal signal is emitted).
   *
   * @since 0.9.7
   */
  public void unregister_persona_stores (Set<PersonaStore> stores)
    {
      this.freeze_notify ();

      foreach (var store in stores)
        {
          assert (store is FolksDummy.PersonaStore);

          if (!this._all_persona_stores.has_key (store.id))
            {
              continue;
            }

          this._disable_persona_store (store);
          this._all_persona_stores.unset (store.id);
        }

      this.thaw_notify ();
    }
}
