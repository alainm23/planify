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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 */

using GLib;
using Gee;
using TelepathyGLib;
using Folks;
using Folks.Backends.Tp;

extern const string BACKEND_NAME;

/**
 * A backend which connects to the Telepathy accounts service and creates a
 * {@link PersonaStore} for each valid account known to Telepathy.
 */
public class Folks.Backends.Tp.Backend : Folks.Backend
{
  private AccountManager _account_manager;
  private bool _is_prepared = false;
  private bool _prepare_pending = false; /* used by unprepare() too */
  private bool _is_quiescent = false;
  private Set<string>? _storeids = null;

  /**
   * {@inheritDoc}
   */
  public override string name { get { return BACKEND_NAME; } }

  /**
   * {@inheritDoc}
   */
  public override Map<string, Folks.PersonaStore> persona_stores
    {
      get { return Tpf.PersonaStore.list_persona_stores (); }
    }

  /**
   * {@inheritDoc}
   */
  public override void enable_persona_store (PersonaStore store)
    {
      if (this.persona_stores.has_key (store.id) == false)
        {
          this._add_store (store);
        }
    }
    
  /**
   * {@inheritDoc}
   */
  public override void disable_persona_store (PersonaStore store)
    {
      if (this.persona_stores.has_key (store.id))
        {
          this._remove_store (store);
        }
    }
    
  /**
   * {@inheritDoc}
   */
  public override void set_persona_stores (Set<string>? storeids)
    {
      this._storeids = storeids;
      
      bool added_stores = false;
      PersonaStore[] removed_stores = {};

      /* First handle adding any missing persona stores. */
      var accounts = this._account_manager.dup_valid_accounts ();
      foreach (Account account in accounts)
        {
          string id = account.get_object_path ();
          if (this.persona_stores.has_key (id) == false &&
             id in storeids)
            {
              var store = Tpf.PersonaStore.dup_for_account (account);
              this._add_store (store, false);
              added_stores = true;
            }
        }
        
      foreach (PersonaStore store in this.persona_stores.values)
        {
          if (!storeids.contains (store.id))
            {
              removed_stores += store;
            }
        }
        
      foreach (PersonaStore store in removed_stores)
        {
          this._remove_store ((Tpf.PersonaStore) store, false);
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
  public override async void prepare () throws GLib.Error
    {
      Internal.profiling_start ("preparing Tp.Backend");

      if (this._is_prepared || this._prepare_pending)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;
          this.freeze_notify ();

          this._account_manager = AccountManager.dup ();
          yield this._account_manager.prepare_async (null);
          this._account_manager.account_enabled.connect (
              this._account_enabled_cb);
          this._account_manager.account_validity_changed.connect (
              this._account_validity_changed_cb);

          var accounts = this._account_manager.dup_valid_accounts ();
          foreach (Account account in accounts)
            {
              this._account_enabled_cb (account);
            }

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

      Internal.profiling_end ("preparing Tp.Backend");
    }

  /**
   * {@inheritDoc}
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

          this._account_manager.account_enabled.disconnect (
              this._account_enabled_cb);
          this._account_manager.account_validity_changed.disconnect (
              this._account_validity_changed_cb);
          this._account_manager = null;

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

  private void _account_validity_changed_cb (Account account, bool valid)
    {
      if (valid)
        this._account_enabled_cb (account);
    }

  private void _account_enabled_cb (Account account)
    {
      if (!account.enabled)
        {
          return;
        }

      /* Ignore if this account's object path isn't in our storeids */
      if (this._storeids != null && (account.get_object_path () in
           this._storeids) == false)
        {
          return;
        }
        
      var store = Tpf.PersonaStore.dup_for_account (account);
      this._add_store (store);
    }

  private void _add_store (PersonaStore store, bool notify = true)
    {
      store.removed.connect (this._store_removed_cb);
      this.persona_store_added (store);

      if (notify)
        {
          this.notify_property ("persona-stores");
        }
    }
  
  private void _remove_store (PersonaStore store, bool notify = true)
    {
      store.removed.disconnect (this._store_removed_cb);
      this.persona_store_removed (store);
      
      if (notify)
      {
        this.notify_property ("persona-stores");
      }
    }
    
  private void _store_removed_cb (PersonaStore store)
    {
      this._remove_store (store);
    }
}
