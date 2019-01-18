/*
 * Copyright (C) 2010 Collabora Ltd.
 * Copyright (C) 2013 Philip Withnall
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
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 *       Xavier Claessens <xavier.claessens@collabora.co.uk>
 */

using GLib;
using Gee;
using TelepathyGLib;
using Folks;

extern const string G_LOG_DOMAIN;
extern const string BACKEND_NAME;

/**
 * A persona store which is associated with a single Telepathy account. It will
 * create {@link Persona}s for each of the contacts in the account's
 * contact list.
 *
 * User must define contact features it wants on the #TpSimpleClientFactory of
 * the default #TpAccountManager returned by tp_account_manager_dup() *before*
 * preparing telepathy stores. Note that this is a behaviour change since
 * 0.7.0, folks won't force preparing any feature anymore.
 */
public class Tpf.PersonaStore : Folks.PersonaStore
{
  private string[] _always_writeable_properties = {};

  /* Sets of Personas exposed by this store.
   * This is the roster + self_contact */
  private HashMap<string, Persona> _personas;
  private Map<string, Persona> _personas_ro;
  private HashSet<Persona> _persona_set;

  /* Map from weakly-referenced TpContacts to their Persona.
   * This map contains all the TpContact we know about, could be more than the
   * the roster. Persona is kept in the map until its TpContact is disposed. */
  private HashMap<unowned Contact, Persona> _contact_persona_map;

  /* TpContact IDs. Note that this should *not* be cleared in _reset().
   * See bgo#630822. */
  private SmallSet<string> _favourite_ids = new SmallSet<string> ();

  /* Mapping from Persona IIDs to their avatars. This allows avatars to persist
   * between the cached (offline) personas and the online personas. Note that
   * this should *not* be cleared in _reset(). */
  private HashMap<string, File> _avatars = new HashMap<string, File> ();

  private Connection? _conn; /* null when disconnected */
  private AccountManager? _account_manager; /* only null before prepare() */
  private Logger _logger;
  private Persona? _self_persona;

  /* Connection's capabilities */
  private MaybeBool _can_add_personas = MaybeBool.UNSET;
  private MaybeBool _can_alias_personas = MaybeBool.UNSET;
  private MaybeBool _can_group_personas = MaybeBool.UNSET;
  private MaybeBool _can_remove_personas = MaybeBool.UNSET;

  private bool _is_prepared = false;
  private bool _prepare_pending = false;
  private bool _is_quiescent = false;
  private bool _got_initial_members = false;
  private bool _got_initial_self_contact = false;
  /* true iff in the middle of storing/loading the cache while disconnecting */
  private bool _disconnect_pending = false;
  /* true iff the store should be removed after disconnection is complete */
  private bool _removal_pending = false;

  private Debug _debug;
  private PersonaStoreCache _cache;
  private Cancellable? _load_cache_cancellable = null;
  /* Whether data in memory is dirty and needs flushing to the cache at some
   * point. For example, this will be true if a contact has updated their avatar
   * while we've been online. */
  private bool _cache_needs_update = false;

  /* marshalled from ContactInfo.SupportedFields */
  private SmallSet<string> _supported_fields;
  private Set<string> _supported_fields_ro;

  private Account _account;

  private FolksTpZeitgeist.Controller _zg_controller;

  /**
   * The Telepathy account this store is based upon.
   */
  [Description(nick = "basis account",
      blurb = "Telepathy account this store is based upon")]
  public Account account
    {
      get { return this._account; }
      construct
        {
          this._account = value;
          this._account.invalidated.connect (this._account_invalidated_cb);
        }
    }

  /**
   * The type of persona store this is.
   *
   * See {@link Folks.PersonaStore.type_id}.
   */
  public override string type_id { get { return BACKEND_NAME; } }

  /**
   * Whether this PersonaStore can add {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_add_personas}.
   *
   * @since 0.3.1
   */
  public override MaybeBool can_add_personas
    {
      get { return this._can_add_personas; }
    }

  /**
   * Whether this PersonaStore can set the alias of {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_alias_personas}.
   *
   * @since 0.3.1
   */
  public override MaybeBool can_alias_personas
    {
      get { return this._can_alias_personas; }
    }

  /**
   * Whether this PersonaStore can set the groups of {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_group_personas}.
   *
   * @since 0.3.1
   */
  public override MaybeBool can_group_personas
    {
      get { return this._can_group_personas; }
    }

  /**
   * Whether this PersonaStore can remove {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_remove_personas}.
   *
   * @since 0.3.1
   */
  public override MaybeBool can_remove_personas
    {
      get { return this._can_remove_personas; }
    }

  /**
   * Whether this PersonaStore has been prepared.
   *
   * See {@link Folks.PersonaStore.is_prepared}.
   *
   * @since 0.3.0
   */
  public override bool is_prepared
    {
      get { return this._is_prepared; }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.2
   */
  public override string[] always_writeable_properties
    {
      get { return this._always_writeable_properties; }
    }

  /*
   * Whether this PersonaStore has reached a quiescent state.
   *
   * See {@link Folks.PersonaStore.is_quiescent}.
   *
   * @since 0.6.2
   */
  public override bool is_quiescent
    {
      get { return this._is_quiescent; }
    }

  private void _notify_if_is_quiescent ()
    {
      if (this._got_initial_members == true &&
          this._got_initial_self_contact == true &&
          this._is_quiescent == false)
        {
          this._is_quiescent = true;
          this.notify_property ("is-quiescent");
        }
    }

  private void _force_quiescent ()
    {
        this._got_initial_self_contact = true;
        this._got_initial_members = true;
        this._notify_if_is_quiescent ();
    }

  /**
   * The {@link Persona}s exposed by this PersonaStore.
   *
   * See {@link Folks.PersonaStore.personas}.
   */
  public override Map<string, Folks.Persona> personas
    {
      get { return this._personas_ro; }
    }

  internal Set<string> supported_fields
    {
      get { return this._supported_fields_ro; }
    }

  /**
   * Create a new PersonaStore.
   *
   * Create a new persona store to store the {@link Persona}s for the contacts
   * in the Telepathy account provided by ``account``.
   *
   * @param account the Telepathy account being represented by the persona store
   */
  public PersonaStore (Account account)
    {
      Object (account: account,
              display_name: account.display_name,
              id: account.get_object_path ());
    }

  construct
    {
      debug ("Creating new Tpf.PersonaStore %p ('%s') for TpAccount %p.",
          this, this.id, this.account);

      this._debug = Debug.dup ();
      this._debug.print_status.connect (this._debug_print_status);

      // Add to the map of persona stores by account
      PersonaStore._add_store_to_map (this);

      // Set up the cache
      this._cache = new PersonaStoreCache (this);

      this._reset ();
    }

  ~PersonaStore ()
    {
      debug ("Destroying Tpf.PersonaStore %p ('%s').", this, this.id);

      this._reset ();

      // Remove from the map of persona stores by account
      PersonaStore._remove_store_from_map (this);

      this._debug.print_status.disconnect (this._debug_print_status);
      this._debug = null;
      if (this._logger != null)
        this._logger.invalidated.disconnect (this._logger_invalidated_cb);

      this._account.invalidated.disconnect (this._account_invalidated_cb);

      if (this._account_manager != null)
        {
          this._account_manager.invalidated.disconnect (
              this._account_manager_invalidated_cb);
          this._account_manager = null;
        }

      this._zg_controller = null;
    }

  private string _format_maybe_bool (MaybeBool input)
    {
      switch (input)
        {
          case MaybeBool.UNSET:
            return "unset";
          case MaybeBool.TRUE:
            return "true";
          case MaybeBool.FALSE:
            return "false";
          default:
            assert_not_reached ();
        }
    }

  private void _debug_print_status (Debug debug)
    {
      const string domain = Debug.STATUS_LOG_DOMAIN;
      const LogLevelFlags level = LogLevelFlags.LEVEL_INFO;

      debug.print_heading (domain, level, "Tpf.PersonaStore (%p)", this);
      debug.print_key_value_pairs (domain, level,
          "ID", this.id,
          "Prepared?", this._is_prepared ? "yes" : "no",
          "Has initial members?", this._got_initial_members ? "yes" : "no",
          "Has self contact?", this._got_initial_self_contact ? "yes" : "no",
          "TpConnection", "%p".printf (this._conn),
          "TpAccountManager", "%p".printf (this._account_manager),
          "Self-Persona", "%p".printf (this._self_persona),
          "Can add personas?", this._format_maybe_bool (this._can_add_personas),
          "Can alias personas?",
              this._format_maybe_bool (this._can_alias_personas),
          "Can group personas?",
              this._format_maybe_bool (this._can_group_personas),
          "Can remove personas?",
              this._format_maybe_bool (this._can_remove_personas)
      );

      debug.print_line (domain, level, "%u Personas:", this._persona_set.size);
      debug.indent ();

      foreach (var persona in this._persona_set)
        {
          debug.print_heading (domain, level, "Persona (%p)", persona);
          debug.print_key_value_pairs (domain, level,
              "UID", persona.uid,
              "IID", persona.iid,
              "Display ID", persona.display_id,
              "User?", persona.is_user ? "yes" : "no",
              "In contact list?", persona.is_in_contact_list ? "yes" : "no",
              "TpContact", "%p".printf (persona.contact)
          );
        }

      debug.unindent ();

      debug.print_line (domain, level, "%u TpContact–Persona mappings:",
          this._contact_persona_map.size);
      debug.indent ();

      var iter1 = this._contact_persona_map.map_iterator ();
      while (iter1.next () == true)
        {
          debug.print_line (domain, level,
              "%s → %p", iter1.get_key ().get_identifier (), iter1.get_value ());
        }

      debug.unindent ();

      debug.print_line (domain, level, "%u favourite TpContact IDs:",
          this._favourite_ids.size);
      debug.indent ();

      foreach (var id in this._favourite_ids)
        {
          debug.print_line (domain, level, "%s", id);
        }

      debug.unindent ();

      debug.print_line (domain, level, "Cached avatars for %u personas:",
          this._avatars.size);
      debug.indent ();

      foreach (var id in this._avatars.keys)
        {
          debug.print_line (domain, level, "%s", id);
        }

      debug.unindent ();

      /* Finish with a blank line. The format string must be non-empty. */
      debug.print_line (domain, level, "%s", "");
    }

  private void _reset ()
    {
      debug ("Resetting Tpf.PersonaStore %p ('%s')", this, this.id);

      /* We do not trust local-xmpp or IRC at all, since Persona UIDs can be
       * faked by just changing hostname/username or nickname. */
      if (account.protocol_name == "local-xmpp" ||
          account.protocol_name == "irc")
        this.trust_level = PersonaStoreTrust.NONE;
      else
        this.trust_level = PersonaStoreTrust.PARTIAL;

      this._personas = new HashMap<string, Persona> ();
      this._personas_ro = this._personas.read_only_view;
      this._persona_set = new HashSet<Persona> ();
      this._cache_needs_update = false;

      if (this._conn != null)
        {
          this._conn.notify["self-contact"].disconnect (
              this._self_contact_changed_cb);
          this._conn.notify["contact-list-state"].disconnect (
              this._contact_list_state_changed_cb);
          this._conn.contact_list_changed.disconnect (
              this._contact_list_changed_cb);

          this._conn = null;
        }

      if (this._contact_persona_map != null)
        {
          var iter = this._contact_persona_map.map_iterator ();
          while (iter.next () == true)
            {
              var contact = iter.get_key ();
              contact.weak_unref (this._contact_weak_notify_cb);
            }
        }

      this._contact_persona_map = new HashMap<unowned Contact, Persona> ();

      this._supported_fields = new SmallSet<string> ();
      this._supported_fields_ro = this._supported_fields.read_only_view;
      this._self_persona = null;
    }

  private void _remove_store (Set<Persona> old_personas)
    {
      if (this._disconnect_pending == true)
        {
          /* The removal will be completed in _notify_connection_cb().
           * See: bgo#683390. */
          debug ("Delaying removing store %s (%p) due to pending disconnect.",
              this.id, this);
          this._removal_pending = true;
        }
      else
        {
          debug ("Removing store %s (%p)", this.id, this);
          this._removal_pending = false;

          this._emit_personas_changed (null, old_personas);
          this._cache.clear_cache.begin ();

          this.removed ();
        }
    }

  /**
   * Prepare the PersonaStore for use.
   *
   * See {@link Folks.PersonaStore.prepare}.
   *
   * @throws GLib.Error currently unused
   */
  public override async void prepare () throws GLib.Error
    {
      Internal.profiling_start ("preparing Tpf.PersonaStore (ID: %s)", this.id);

      if (this._is_prepared || this._prepare_pending)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;

          this._account_manager = AccountManager.dup ();

          /* FIXME: Add all contact features on AM's factory. We should not
           * force preparing all features but let app define what it needs,
           * but this is for backward compatibility.
           * Note that if application already prepared TpContacts before
           * preparing this store, this will have no effect on existing
           * contacts. */
          var factory = this._account_manager.get_factory ();
          factory.add_contact_features ({
              ContactFeature.ALIAS,
              ContactFeature.AVATAR_DATA,
              ContactFeature.AVATAR_TOKEN,
              ContactFeature.CAPABILITIES,
              ContactFeature.CLIENT_TYPES,
              ContactFeature.PRESENCE,
              ContactFeature.CONTACT_INFO,
              ContactFeature.CONTACT_GROUPS
          });

          this._account_manager.invalidated.connect (
              this._account_manager_invalidated_cb);

          /* Note: For the three signal handlers below, we do *not* need to
           * store personas to the cache before removing the store, as
           * _remove_store() deletes the cache file. */
          this._account_manager.account_removed.connect ((a) =>
            {
              if (this.account == a)
                {
                  debug ("Account %p (‘%s’) removed.", a, a.display_name);
                  this._remove_store (this._persona_set);
                }
            });
          this._account_manager.account_validity_changed.connect (
              (a, valid) =>
                {
                  if (!valid && this.account == a)
                    {
                      debug ("Account %p (‘%s’) invalid.", a,
                          a.display_name);
                      this._remove_store (this._persona_set);
                    }
                });
          this._account_manager.account_disabled.connect ((a) =>
            {
              if (this.account == a)
                {
                  debug ("Account %p (‘%s’) disabled.", a, a.display_name);
                  this._remove_store (this._persona_set);
                }
            });

          Internal.profiling_point ("created account manager in " +
              "Tpf.PersonaStore (ID: %s)", this.id);

          this._avatars.clear ();

          this._favourite_ids.clear ();
          this._logger = new Logger (this.id);
          this._logger.invalidated.connect (
              this._logger_invalidated_cb);
          this._logger.favourite_contacts_changed.connect (
              this._favourite_contacts_changed_cb);
          Internal.profiling_start ("initialising favourite contacts in " +
              "Tpf.PersonaStore (ID: %s)", this.id);
          this._initialise_favourite_contacts.begin ((o, r) =>
            {
              try
                {
                  this._initialise_favourite_contacts.end (r);
                  Internal.profiling_end ("initialising favourite " +
                      "contacts in Tpf.PersonaStore (ID: %s)", this.id);
                }
              catch (GLib.Error e)
                {
                  debug ("Failed to initialise favourite contacts: %s",
                      e.message);
                  this._logger = null;
                }
            });

          Internal.profiling_point ("created logger in Tpf.PersonaStore " +
              "(ID: %s)", this.id);

          this.account.notify["connection"].connect (
              this._notify_connection_cb);

          /* immediately handle accounts which are not currently being
           * disconnected */
          if (this.account.connection != null)
            {
              this._notify_connection_cb (this.account, null);
            }
          else
            {
              /* If we're disconnected, advertise personas from the cache
               * instead. */
              yield this._load_cache (null);
              this._force_quiescent ();
            }

          Internal.profiling_point ("loaded cache in Tpf.PersonaStore " +
              "(ID: %s)", this.id);

          this._is_prepared = true;
          this.notify_property ("is-prepared");
        }
      finally
        {
          this._prepare_pending = false;
        }

      Internal.profiling_end ("preparing Tpf.PersonaStore (ID: %s)", this.id);
    }

  private void _account_manager_invalidated_cb (uint domain, int code,
      string message)
    {
      debug ("TpAccountManager invalidated (%u, %i, “%s”) for " +
          "Tpf.PersonaStore %p (‘%s’).", domain, code, message, this, this.id);
      this._remove_store (this._persona_set);
    }

  private void _account_invalidated_cb (uint domain, int code, string message)
    {
      debug ("TpAccount invalidated (%u, %i, “%s”) for " +
          "Tpf.PersonaStore %p (‘%s’).", domain, code, message, this, this.id);
      this._remove_store (this._persona_set);
    }

  private void _logger_invalidated_cb ()
    {
      this._logger.invalidated.disconnect (this._logger_invalidated_cb);

      debug ("Lost connection to the telepathy-logger service.");
      this._logger = null;
    }

  /* This method is not safe to call multiple times concurrently. */
  private async void _initialise_favourite_contacts () throws GLib.Error
    {
      if (this._logger == null)
        return;

      yield this._logger.prepare ();

      var contacts = yield this._logger.get_favourite_contacts ();
      this._favourite_contacts_changed_cb (contacts, {});

      this._always_writeable_properties += "is-favourite";
      this.notify_property ("always-writeable-properties");
    }

  private Persona? _lookup_persona_by_id (string id)
    {
      /* This is not efficient, but better than doing DBus roundtrip to get a
       * TpContact. */
      var iter = this._contact_persona_map.map_iterator ();
      while (iter.next ())
        {
          if (iter.get_key ().get_identifier () == id)
            {
              return iter.get_value ();
            }
        }
      return null;
    }

  private void _favourite_contacts_changed_cb (string[] added, string[] removed)
    {
      foreach (var id in added)
        {
          this._favourite_ids.add (id);
          var p = this._lookup_persona_by_id (id);
          if (p != null)
            {
              p._set_is_favourite (true);
            }
        }
      foreach (var id in removed)
        {
          this._favourite_ids.remove (id);
          var p = this._lookup_persona_by_id (id);
          if (p != null)
            {
              p._set_is_favourite (false);
            }
        }
    }

  /* This is called when we go online, when the user chooses to go offline, or
   * when a CM crashes. */
  private void _notify_connection_cb (Object s, ParamSpec? p)
    {
      var account = s as TelepathyGLib.Account;

      debug ("Account '%s' connection changed to %p", this.id,
          account.connection);

      /* account disconnected */
      if (account.connection == null)
        {
          this._supported_fields.clear ();
          this.notify_property ("supported-fields");

          /* When disconnecting, we want the PersonaStore to remain alive, but
           * all its Personas to be removed. We do *not* want the PersonaStore
           * to be destroyed, as that makes coming back online hard.
           *
           * We have to start advertising personas from the cache instead.
           * This will implicitly notify about removal of the existing persona
           * set and call this._reset().
           *
           * Before we do this, we store the current set of personas to the
           * cache, assuming we were connected before. */
          if (this._conn != null)
            {
              this._disconnect_pending = true;

              /* Call reset immediately, otherwise TpConnection's invalidation
               * will cause all contacts to weak notify. See bug #675141 */
              var old_personas = this._persona_set;
              var old_cache_needs_update = this._cache_needs_update;
              this._reset ();

              if (old_cache_needs_update)
                {
                  this._set_cache_needs_update ();
                }

              this._store_cache.begin (old_personas, (o, r) =>
                {
                  this._store_cache.end (r);

                  this._disconnect_pending = false;

                  if (this._removal_pending == false)
                    {
                      this._load_cache.begin (old_personas, (o2, r2) =>
                        {
                          this._load_cache.end (r2);
                        });
                    }
                  else
                    {
                      /* If the PersonaStore has been invalidated or disabled,
                       * remove it. This is done here rather than in the
                       * signal handlers for account-disabled or
                       * account-validity-changed so that the cache is handled
                       * properly. See: bgo#683390. */
                      assert (this._disconnect_pending == false);
                      this._remove_store (old_personas);
                    }
                });
            }

          /* If the persona store starts offline, we've reached a quiescent
           * state. */
          this._force_quiescent ();

          return;
        }

      this._notify_connection_cb_async.begin ();
    }

  private async void _notify_connection_cb_async ()
    {
      debug ("_notify_connection_cb_async() for Tpf.PersonaStore %p ('%s').",
          this, this.id);

      Internal.profiling_start ("notify connection for Tpf.PersonaStore " +
          "(ID: %s)", this.id);

      /* Ensure the connection is prepared as necessary. */
      try
        {
          yield this.account.connection.prepare_async ({
              TelepathyGLib.Connection.get_feature_quark_contact_list (),
              TelepathyGLib.Connection.get_feature_quark_contact_groups (),
              TelepathyGLib.Connection.get_feature_quark_contact_info (),
              TelepathyGLib.Connection.get_feature_quark_connected (),
              TelepathyGLib.Connection.get_feature_quark_aliasing (),
              0
          });
        }
      catch (GLib.Error e)
        {
          debug ("Failed to connect CM for Tpf.PersonaStore %p ('%s'): %s",
              this, this.id, e.message);

          /* If we're disconnected, advertise personas from the cache
           * instead. */
          yield this._load_cache (null);
          this._force_quiescent ();

          return;
        }

      if (!this.account.connection.has_interface_by_id (
          iface_quark_connection_interface_contact_list ()))
        {
          debug ("Connection does not implement ContactList iface; " +
              "legacy CMs are not supported any more.");

          this._remove_store (this._persona_set);

          return;
        }

      // We're connected, so can stop advertising personas from the cache
      this._unload_cache ();

      this._conn = this.account.connection;

      /* Connect signals early so that cleaning up is easier if the connection
       * is disconnected during the 'yield' below. */
      this._conn.notify["self-contact"].connect (
          this._self_contact_changed_cb);
      this._conn.notify["contact-list-state"].connect (
          this._contact_list_state_changed_cb);

      /* Emit all the notifications after the 'yield' just in case the
       * connection disappears during it. This makes cleaning up easier. */
      this.freeze_notify ();
      this._marshall_supported_fields ();
      this.notify_property ("supported-fields");

      if (this._conn.get_group_storage () != ContactMetadataStorageType.NONE)
        {
          this._can_group_personas = MaybeBool.TRUE;

          this._always_writeable_properties += "groups";
          this.notify_property ("always-writeable-properties");
        }
      else
        {
          this._can_group_personas = MaybeBool.FALSE;
        }
      this.notify_property ("can-group-personas");

      if (this._conn.get_can_change_contact_list ())
        {
          this._can_add_personas = MaybeBool.TRUE;
          this._can_remove_personas = MaybeBool.TRUE;
        }
      else
        {
          this._can_add_personas = MaybeBool.FALSE;
          this._can_remove_personas = MaybeBool.FALSE;
        }
      this.notify_property ("can-add-personas");
      this.notify_property ("can-remove-personas");

      var new_can_alias = MaybeBool.FALSE;

      if (this._conn.can_set_contact_alias ())
        {
          new_can_alias = MaybeBool.TRUE;

          this._always_writeable_properties += "alias";
          this.notify_property ("always-writeable-properties");
        }

      this._can_alias_personas = new_can_alias;
      this.notify_property ("can-alias-personas");

      this.thaw_notify ();

      /* Add the local user */
      this._self_contact_changed_cb (this._conn, null);
      this._contact_list_state_changed_cb (this._conn, null);

      Internal.profiling_end ("notify connection for Tpf.PersonaStore " +
          "(ID: %s)", this.id);
    }

  private void _marshall_supported_fields ()
    {
      var connection = this.account.connection;
      if (connection != null)
        {
          this._supported_fields.clear ();

          var ci_flags = connection.get_contact_info_flags ();
          if ((ci_flags & ContactInfoFlags.CAN_SET) != 0)
            {
              var field_specs =
                connection.dup_contact_info_supported_fields ();
              foreach (var field_spec in field_specs)
                {
                  /* XXX: we ignore the maximum count for each type of
                    * field since the common-sense count for each
                    * corresponding field (eg, full-name max = 1) in
                    * Folks is already reflected in our API and we have
                    * no other way to express it; but this seems a very
                    * minor problem */
                  this._supported_fields.add (field_spec.name);
                }
            }
        }
    }

  /**
   * If our account is disconnected, we want to continue to export a static
   * view of personas from the cache. old_personas will be notified as removed.
   *
   * This method is safe to call multiple times concurrently. Previous calls
   * will be cancelled by subsequent calls.
   */
  private async void _load_cache (HashSet<Persona>? old_personas)
    {
      /* Only load from the cache if the account is enabled and valid. */
      if (this.account.enabled == false || this.account.valid == false)
        {
          debug ("Skipping loading cache for Tpf.PersonaStore %p ('%s'): " +
              "enabled: %s, valid: %s.", this, this.id,
              this.account.enabled ? "yes" : "no",
              this.account.valid ? "yes" : "no");

          return;
        }

      debug ("Loading cache for Tpf.PersonaStore %p ('%s').", this, this.id);

      var cancellable = new Cancellable ();

      if (this._load_cache_cancellable != null)
        {
          debug ("    Cancelling ongoing loading operation (cancellable: %p).",
              this._load_cache_cancellable);
          this._load_cache_cancellable.cancel ();
        }

      this._load_cache_cancellable = cancellable;

      // Load the persona set from the cache and notify of the change
      var cached_personas = yield this._cache.load_objects (cancellable);

      /* If the load operation was cancelled, don't change the state
       * of the persona store at all. */
      if (cancellable.is_cancelled () == true)
        {
          debug ("    Cancelled (cancellable: %p).", cancellable);
          return;
        }

      this._reset ();

      this._persona_set = new HashSet<Persona> ();
      if (cached_personas != null)
        {
          foreach (var p in cached_personas)
            {
              this._add_persona (p);
            }
        }

      this._emit_personas_changed (cached_personas, old_personas,
          null, null, GroupDetails.ChangeReason.NONE);

      this._can_add_personas = MaybeBool.FALSE;
      this._can_alias_personas = MaybeBool.FALSE;
      this._can_group_personas = MaybeBool.FALSE;
      this._can_remove_personas = MaybeBool.FALSE;

      if (this._logger != null)
        {
          this._always_writeable_properties = { "is-favourite" };
        }
      else
        {
          this._always_writeable_properties = {};
        }

      this.notify_property ("always-writeable-properties");
    }

  /* This method is safe to call multiple times concurrently. */
  public override async void flush ()
    {
      debug ("Flushing Tpf.PersonaStore %p (‘%s’).", this, this.id);

      /* Store the cache if it needs an update. */
      yield this._store_cache (this._persona_set);
    }

  /**
   * Called when a contact property is set which is not accessible when either
   * the contact is offline or we're offline. For example, a contact's avatar.
   * This will cause the cache to be stored when the PersonaStore is destroyed.
   */
  internal void _set_cache_needs_update ()
    {
      debug ("Setting cache as needing an update for Tpf.PersonaStore " +
          "%p (‘%s’).", this, this.id);
      this._cache_needs_update = true;
    }

  /**
   * When we're about to disconnect, store the current set of personas to the
   * cache file so that we can access them once offline.
   *
   * This method is safe to call multiple times concurrently.
   */
  private async void _store_cache (HashSet<Persona> old_personas)
    {
      /* Only store/load the cache if the account is enabled and valid;
       * otherwise, the PersonaStore will get removed and the cache
       * deleted later anyway. */
      if (!this.account.enabled || !this.account.valid)
        {
          debug ("Skipping storing cache for Tpf.PersonaStore %p (‘%s’) as " +
              "its TpAccount is disabled or invalid.", this, this.id);
          return;
        }
      else if (this._cache_needs_update == false)
        {
          debug ("Skipping storing cache for Tpf.PersonaStore %p (‘%s’) as " +
              "it doesn’t need an update.", this, this.id);
          return;
        }

      debug ("Storing cache for Tpf.PersonaStore %p ('%s').", this, this.id);

      yield this._cache.store_objects (old_personas);
      this._cache_needs_update = false;
    }

  /**
   * When our account is connected again, we can unload the the personas which
   * we're advertising from the cache.
   */
  private void _unload_cache ()
    {
      debug ("Unloading cache for Tpf.PersonaStore %p ('%s').", this, this.id);

      // If we're in the process of loading from the cache, cancel that
      if (this._load_cache_cancellable != null)
        {
          debug ("    Cancelling ongoing loading operation (cancellable: %p).",
              this._load_cache_cancellable);
          this._load_cache_cancellable.cancel ();
        }

      this._emit_personas_changed (null, this._persona_set, null, null,
          GroupDetails.ChangeReason.NONE);

      this._reset ();
    }

  internal void _update_avatar_cache (string persona_iid, File? avatar_file)
    {
      if (avatar_file == null)
        {
          this._avatars.unset (persona_iid);
        }
      else
        {
          this._avatars.set (persona_iid, (!) avatar_file);
        }
    }

  internal File? _query_avatar_cache (string persona_iid)
    {
      return this._avatars.get (persona_iid);
    }

  private bool _add_persona (Persona p)
    {
      if (this._persona_set.add (p))
        {
          debug ("Add persona %p with uid %s", p, p.uid);
          this._personas.set (p.iid, p);
          return true;
        }

      return false;
    }

  private bool _remove_persona (Persona p)
    {
      if (this._persona_set.remove (p))
        {
          debug ("Remove persona %p with uid %s", p, p.uid);
          this._personas.unset (p.iid);
          if (this._self_persona == p)
            {
              this._self_persona = null;
            }

          return true;
        }

      return false;
    }

  private void _contact_weak_notify_cb (Object obj)
    {
      if (this._contact_persona_map == null)
        {
          return;
        }

      Contact contact = obj as Contact;
      debug ("Weak notify for TpContact %s", contact.get_identifier ());

      Persona? persona = null;
      this._contact_persona_map.unset (contact, out persona);
      if (persona == null)
        {
          return;
        }

      persona._contact_weak_notify ();

      if (this._remove_persona (persona))
        {
          /* This should never happen because TpConnection keeps a ref on
           * self and roster TpContacts, so they should have been removed
           * already. But deal with it just in case... */
          warning ("A TpContact part of the ContactList is disposed");
          var personas = new SmallSet<Persona> ();
          personas.add (persona);
          this._emit_personas_changed (null, personas);
        }
    }

  /* Ensure that we have a Persona wrapping this TpContact. This will keep the
   * Persona internally only (won't emit personas_changed) and until the
   * TpContact is destroyed (we keep only weak ref). */
  internal Tpf.Persona _ensure_persona_for_contact (Contact contact)
    {
      Persona? persona = this._contact_persona_map[contact];
      if (persona != null)
        return (!) persona;

      persona = new Tpf.Persona (contact, this);
      this._contact_persona_map[contact] = persona;
      contact.weak_ref (this._contact_weak_notify_cb);

      var is_favourite = this._favourite_ids.contains (contact.get_identifier ());
      persona._set_is_favourite (is_favourite);

      debug ("Persona %p with uid %s created for TpContact %s, favourite: %s",
          persona, persona.uid, contact.get_identifier (),
          is_favourite ? "yes" : "no");

      return persona;
    }

  private void _self_contact_changed_cb (Object s, ParamSpec? p)
    {
      var contact = this._conn.self_contact;

      var personas_added = new SmallSet<Persona> ();
      var personas_removed = new SmallSet<Persona> ();

      /* Remove old self persona if not also part of roster. Keep a reference
       * to the persona so _remove_persona() doesn't unset it early. */
      var self_persona = this._self_persona;

      if (self_persona != null &&
          !self_persona.is_in_contact_list &&
          this._remove_persona (self_persona))
        {
          personas_removed.add (self_persona);
        }

      this._self_persona = null;

      if (contact != null)
        {
          /* Add the local user to roster */
          this._self_persona = this._ensure_persona_for_contact (contact);
          if (this._add_persona (this._self_persona))
            personas_added.add (this._self_persona);
        }

      this._emit_personas_changed (personas_added, personas_removed);

      this._got_initial_self_contact = true;
      this._notify_if_is_quiescent ();
    }

  private void _contact_list_state_changed_cb (Object s, ParamSpec? p)
    {
      /* Once the contact list is downloaded from server, state moves to
       * SUCCESS and won't change anymore */
      if (this._conn.contact_list_state != ContactListState.SUCCESS)
        return;

      this._conn.contact_list_changed.connect (this._contact_list_changed_cb);
      this._contact_list_changed_cb (this._conn.dup_contact_list (),
          new GLib.GenericArray<weak TelepathyGLib.Contact> ());

      this._got_initial_members = true;
      this._populate_counters.begin ();
      this._notify_if_is_quiescent ();
    }

  private void _contact_list_changed_cb (GLib.GenericArray<weak TelepathyGLib.Contact> added,
      GLib.GenericArray<weak TelepathyGLib.Contact> removed)
    {
      var personas_added = new HashSet<Persona> ();
      var personas_removed = new HashSet<Persona> ();

      debug ("contact list changed: %d added, %d removed",
          added.length, removed.length);

      foreach (Contact contact in added.data)
        {
          var persona = this._ensure_persona_for_contact (contact);

          if (!persona.is_in_contact_list)
            {
              persona.is_in_contact_list = true;
            }

          if (this._add_persona (persona))
            {
              personas_added.add (persona);
            }
        }

      foreach (Contact contact in removed.data)
        {
          var persona = this._contact_persona_map[contact];

          if (persona == null)
            {
              warning ("Unknown TpContact removed from ContactList: %s",
                  contact.get_identifier ());
              continue;
            }

          /* If self contact was also part of the roster but got removed,
           * we keep it in our persona store, but with is_in_contact_list=false.
           * This matches behaviour of _self_contact_changed_cb() where we add
           * the self persona into the user-visible set even if it is not part
           * of the roster. */
          if (persona == this._self_persona)
            {
              persona.is_in_contact_list = false;
              continue;
            }

          if (this._remove_persona (persona))
            {
              personas_removed.add (persona);
            }
        }

      this._emit_personas_changed (personas_added, personas_removed);
    }

  /**
   * Remove a {@link Persona} from the PersonaStore.
   *
   * See {@link Folks.PersonaStore.remove_persona}.
   *
   * @throws Folks.PersonaStoreError.UNSUPPORTED_ON_USER if ``persona`` is the
   * local user — removing the local user isn’t supported
   * @throws Folks.PersonaStoreError.REMOVE_FAILED if removing the contact
   * failed
   */
  public override async void remove_persona (Folks.Persona persona)
      throws Folks.PersonaStoreError
    {
      var tp_persona = (Tpf.Persona) persona;

      if (tp_persona.contact == null)
        {
          warning ("Skipping server-side removal of Tpf.Persona %p because " +
              "it has no attached TpContact", tp_persona);
          return;
        }

      if (persona == this._self_persona &&
          tp_persona.is_in_contact_list == false)
        {
          throw new PersonaStoreError.UNSUPPORTED_ON_USER (
              _("Telepathy contacts representing the local user may not be removed."));
        }

      try
        {
          yield tp_persona.contact.remove_async ();
        }
      catch (GLib.Error e)
        {
          throw new PersonaStoreError.REMOVE_FAILED (
              /* Translators: the parameter is an error message. */
              _("Failed to remove a persona from store: %s"), e.message);
        }
    }

  /* This method is safe to call multiple times concurrently for the same (or
   * different) contact ID, assuming Telepathy is safe. */
  private async Persona _ensure_persona_for_id (string contact_id)
      throws GLib.Error
    {
      var contact = yield this._conn.dup_contact_by_id_async (contact_id, {});
      return this._ensure_persona_for_contact (contact);
    }

  /**
   * Add a new {@link Persona} to the PersonaStore.
   *
   * See {@link Folks.PersonaStore.add_persona_from_details}.
   *
   * This method is safe to call multiple times concurrently for the same (or
   * different) contact IDs (assuming Telepathy is safe).
   *
   * @throws Folks.PersonaStoreError.INVALID_ARGUMENT if the ``contact`` key was
   * not provided in ``details``
   * @throws Folks.PersonaStoreError.STORE_OFFLINE if the CM is offline
   * @throws Folks.PersonaStoreError.CREATE_FAILED if adding the contact failed
   */
  public override async Folks.Persona? add_persona_from_details (
      HashTable<string, Value?> details) throws Folks.PersonaStoreError
    {
      var contact_id = TelepathyGLib.asv_get_string (details, "contact");
      if (contact_id == null)
        {
          throw new PersonaStoreError.INVALID_ARGUMENT (
              /* Translators: the first two parameters are store identifiers and
               * the third is a contact identifier. */
              _("Persona store (%s, %s) requires the following details:\n    contact (provided: ‘%s’)\n"),
              this.type_id, this.id, contact_id);
        }

      // Optional message to pass to the new persona
      var add_message = TelepathyGLib.asv_get_string (details, "message");
      if (add_message == "")
        add_message = null;

      var status = this.account.get_connection_status (null);
      if ((status == TelepathyGLib.ConnectionStatus.DISCONNECTED) ||
          (status == TelepathyGLib.ConnectionStatus.CONNECTING) ||
          this._conn == null)
        {
          throw new PersonaStoreError.STORE_OFFLINE (
              _("Cannot create a new Telepathy contact while offline."));
        }

      try
        {
          var persona = yield this._ensure_persona_for_id (contact_id);
          var already_exists = persona.is_in_contact_list;
          var tp_persona = (Tpf.Persona) persona;
          yield tp_persona.contact.request_subscription_async (add_message);

          /* This function is supposed to return null if the persona was already
           * in the contact list. */
          return already_exists ? null : persona;
        }
      catch (GLib.Error e)
        {
          throw new PersonaStoreError.CREATE_FAILED (
              /* Translators: the parameter is an error message. */
              _("Failed to add a persona from details: %s"), e.message);
        }
    }

  /**
   * Change the favourite status of a persona in this store.
   *
   * This function is idempotent, but relies upon having a connection to the
   * Telepathy logger service, so may fail if that connection is not present.
   */
  internal async void change_is_favourite (Folks.Persona persona,
      bool is_favourite) throws PropertyError
    {
      /* It's possible for us to not be able to connect to the logger;
       * see _connection_ready_cb() */
      if (this._logger == null)
        {
          throw new PropertyError.UNKNOWN_ERROR (
              /* Translators: "telepathy-logger" is the name of an application,
               * and should not be translated. */
              _("Failed to change favorite without a connection to the telepathy-logger service."));
        }

      if (((Tpf.Persona) persona).contact == null)
        {
          throw new PropertyError.INVALID_VALUE (
              _("Failed to change favorite status of Telepathy Persona because it has no attached TpContact."));
        }

      try
        {
          /* Add or remove the persona to the list of favourites as
           * appropriate. */
          unowned string id = ((Tpf.Persona) persona).contact.get_identifier ();

          if (is_favourite)
            yield this._logger.add_favourite_contact (id);
          else
            yield this._logger.remove_favourite_contact (id);
        }
      catch (GLib.Error e)
        {
          throw new PropertyError.UNKNOWN_ERROR (
              /* Translators: the parameter is a contact identifier. */
              _("Failed to change favorite status for Telepathy contact ‘%s’."),
              ((Tpf.Persona) persona).contact.identifier);
        }
    }

  internal async void change_alias (Tpf.Persona persona, string alias)
      throws PropertyError
    {
      /* Deal with badly-behaved callers */
      if (alias == null)
        {
          alias = "";
        }

      if (persona.contact == null)
        {
          warning ("Skipping Tpf.Persona %p alias change to '%s' because it " +
              "has no attached TpContact", persona, alias);
          return;
        }

      try
        {
          debug ("Changing alias of persona %s to '%s'.",
              persona.contact.get_identifier (), alias);
          yield FolksTpLowlevel.connection_set_contact_alias_async (this._conn,
              (Handle) persona.contact.handle, alias);
        }
      catch (GLib.Error e1)
        {
          throw new PropertyError.UNKNOWN_ERROR (
              /* Translators: the parameter is an error message. */
              _("Failed to change contact’s alias: %s"), e1.message);
        }
    }

  internal async void change_user_birthday (Tpf.Persona persona,
      DateTime? birthday) throws PersonaStoreError
    {
      string birthday_str;

      if (birthday == null)
        birthday_str = "";
      else
        birthday_str = birthday.to_string ();

      var info_set = new SmallSet<ContactInfoField> ();
      string[] values = { birthday_str };
      string[] parameters = { null };

      var field = new ContactInfoField ("bday", parameters, values);
      info_set.add (field);

      yield this._change_user_contact_info (persona, info_set);
    }

  internal async void change_user_full_name (Tpf.Persona persona,
      string full_name) throws PersonaStoreError
    {
      /* Deal with badly-behaved callers */
      if (full_name == null)
        {
          full_name = "";
        }

      var info_set = new SmallSet<ContactInfoField> ();
      string[] values = { full_name };
      string[] parameters = { null };

      var field = new ContactInfoField ("fn", parameters, values);
      info_set.add (field);

      yield this._change_user_contact_info (persona, info_set);
    }

  internal async void _change_user_details (
      Tpf.Persona persona, Set<AbstractFieldDetails<string>> details,
      string field_name)
        throws PersonaStoreError
    {
      var info_set = new SmallSet<ContactInfoField> ();

      foreach (var afd in details)
        {
          string[] values = { afd.value };
          string[] parameters = {};

          var iter = afd.parameters.map_iterator ();

          while (iter.next ())
            {
              var param_name = iter.get_key ();
              var param_value = iter.get_value ();

              parameters += @"$param_name=$param_value";
            }

          if (parameters.length == 0)
            parameters = { null };

          var field = new ContactInfoField (field_name, parameters, values);
          info_set.add (field);
        }

      yield this._change_user_contact_info (persona, info_set);
    }

  private async void _change_user_contact_info (Tpf.Persona persona,
      SmallSet<ContactInfoField> info_set) throws PersonaStoreError
    {
      if (!persona.is_user)
        {
          throw new PersonaStoreError.UNSUPPORTED_ON_NON_USER (
              _("Extended information may only be set on the user’s Telepathy contact."));
        }

      var info_list = PersonaStore._contact_info_set_to_list (info_set);
      if (this.account.connection != null)
        {
          GLib.Error? error = null;
          bool success = false;
          try
            {
              success =
                yield this._conn.set_contact_info_async (
                  info_list);
            }
          catch (GLib.Error e)
            {
              error = e;
            }

          if (error != null || !success)
            {
              warning ("Failed to set extended information on user's " +
                  "Telepathy contact: %s",
                  error != null ? error.message : "(reason unknown)");
            }
        }
      else
        {
          throw new PersonaStoreError.STORE_OFFLINE (
              _("Extended information cannot be written because the store is disconnected."));
        }
    }

  private static GLib.List<ContactInfoField> _contact_info_set_to_list (
      SmallSet<ContactInfoField> info_set)
    {
      var info_list = new GLib.List<ContactInfoField> ();
      foreach (var info_field in info_set)
        {
          info_list.prepend (new ContactInfoField (
                info_field.field_name, info_field.parameters,
                info_field.field_value));
        }
      info_list.reverse ();

      return info_list;
    }

  /* Must be locked before being accessed. A ref. is held on each PersonaStore,
   * and they're only removed when they're finalised or their removed signal is
   * emitted. The map as a whole is lazily constructed and destroyed according
   * to when PersonaStores are constructed and destroyed. */
  private static HashMap<string /* Account object path */, PersonaStore>
      _persona_stores_by_account = null;
  private static Map<string, PersonaStore> _persona_stores_by_account_ro = null;

  /**
   * Get a map of all the currently constructed {@link Tpf.PersonaStore}s.
   *
   * If a {@link Folks.BackendStore} has been prepared, this map will be
   * complete, containing every store known to the Telepathy account manager. If
   * no {@link Folks.BackendStore} has been prepared, this map will only contain
   * the stores which have been created by calling
   * {@link Tpf.PersonaStore.dup_for_account}.
   *
   * This map is read-only. Use {@link Folks.BackendStore} or
   * {@link Tpf.PersonaStore.dup_for_account} to add stores.
   *
   * @return map from {@link Folks.PersonaStore.id} to {@link Tpf.PersonaStore}
   * @since 0.6.6
   */
  public static unowned Map<string, PersonaStore> list_persona_stores ()
    {
      unowned Map<string, PersonaStore> store;

      if (PersonaStore._persona_stores_by_account == null)
        {
          PersonaStore._persona_stores_by_account =
              new HashMap<string, PersonaStore> ();
          PersonaStore._persona_stores_by_account_ro =
              PersonaStore._persona_stores_by_account.read_only_view;
        }

      store = PersonaStore._persona_stores_by_account_ro;

      return store;
    }

  private static void _store_removed_cb (Folks.PersonaStore store)
    {
      /* Remove the store from the map. */
      PersonaStore._remove_store_from_map ((Tpf.PersonaStore) store);
    }

  private static void _add_store_to_map (PersonaStore store)
    {
      debug ("Adding PersonaStore %p ('%s') to map.", store, store.id);

      /* Lazy construction. */
      if (PersonaStore._persona_stores_by_account == null)
        {
          PersonaStore._persona_stores_by_account =
              new HashMap<string, PersonaStore> ();
          PersonaStore._persona_stores_by_account_ro =
              PersonaStore._persona_stores_by_account.read_only_view;
        }

      /* Bail if a store already exists for this account. */
      return_if_fail (
          !PersonaStore._persona_stores_by_account.has_key (store.id));

      /* Add the store. */
      PersonaStore._persona_stores_by_account.set (store.id, store);
      store.removed.connect (PersonaStore._store_removed_cb);
    }

  private static void _remove_store_from_map (PersonaStore store)
    {
      debug ("Removing PersonaStore %p ('%s') from map.", store, store.id);

      /* Bail if no store existed for this account. This can happen if the
       * store emits its removed() signal (correctly) before being
       * finalised; we remove the store from the map in both cases. */
      if (PersonaStore._persona_stores_by_account == null ||
          !PersonaStore._persona_stores_by_account.unset (store.id))
        {
          return;
        }

      store.removed.disconnect (PersonaStore._store_removed_cb);

      /* Lazy destruction. */
      if (PersonaStore._persona_stores_by_account.size == 0)
        {
          PersonaStore._persona_stores_by_account_ro = null;
          PersonaStore._persona_stores_by_account = null;
        }
    }

  /**
   * Look up a {@link Tpf.PersonaStore} by its {@link TelepathyGLib.Account}.
   *
   * If found, a new reference to the persona store will be returned. If not
   * found, a new {@link Tpf.PersonaStore} will be created for the account.
   *
   * See the documentation for {@link Tpf.PersonaStore.list_persona_stores} for
   * information on the lifecycle of these stores when a
   * {@link Folks.BackendStore} is and is not present.
   *
   * @param account the Telepathy account of the persona store
   * @return the persona store associated with the account
   * @since 0.6.6
   */
  public static PersonaStore dup_for_account (Account account)
    {
      PersonaStore? store = null;

      debug ("Tpf.PersonaStore.dup_for_account (%p):", account);

      /* If the store already exists, return it. */
      if (PersonaStore._persona_stores_by_account != null)
        {
          store =
              PersonaStore._persona_stores_by_account.get (
                  account.get_object_path ());
        }

      /* Otherwise, we have to create it. It's added to the map in its
       * constructor. */
      if (store == null)
        {
          debug ("    Creating new PersonaStore.");
          store = new PersonaStore (account);
        }
      else
        {
          debug ("    Found existing PersonaStore %p ('%s').", store,
              store.id);
        }

      return store;
    }

  /* This method is safe to call multiple times concurrently. */
  private async void _populate_counters ()
    {
      this._zg_controller = new FolksTpZeitgeist.Controller (this,
          this.account, (p, dt) =>
        {
          var persona = p as Tpf.Persona;
          assert (persona != null);
          persona._increase_im_interaction_counter (dt);
        },
          (p, dt) =>
        {
          var persona = p as Tpf.Persona;
          assert (persona != null);
          persona._increase_last_call_interaction_counter (dt);
        });
      yield this._zg_controller.populate_counters ();
      this._notify_if_is_quiescent ();
    }
}
