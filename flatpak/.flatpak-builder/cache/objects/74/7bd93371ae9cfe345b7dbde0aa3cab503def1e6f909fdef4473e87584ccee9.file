/*
 * Copyright (C) 2013 Philip Withnall
 * Copyright (C) 2013 Canonical Ltd
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
 *       Renato Araujo Oliveira Filho <renato@canonical.com>
 */

using Folks;
using Gee;
using GLib;

/**
 * A persona store which allows {@link FolksDummy.Persona}s to be
 * programmatically created and manipulated, for the purposes of testing the
 * core of libfolks itself. This should not be used in user-visible
 * applications.
 *
 * There are two sides to this class’ interface: the methods and properties
 * declared by {@link Folks.PersonaStore}, which form the normal libfolks
 * persona store API; and the mock methods and properties (see for example
 * {@link FolksDummy.PersonaStore.set_add_persona_from_details_mock}) which are
 * intended to be used by test driver code to simulate the behaviour of a real
 * backing store. Calls to these mock methods effect state changes in the store
 * which are visible in the normal libfolks API. The ``update_``, ``register_``
 * and ``unregister_`` prefixes and the ``mock`` suffix are commonly used for
 * backing store methods.
 *
 * The main action performed with a dummy persona store is to change its set of
 * personas, adding and removing them dynamically to test client-side behaviour.
 * The client-side APIs ({@link Folks.PersonaStore.add_persona_from_details} and
 * {@link Folks.PersonaStore.remove_persona}) should //not// be used for this.
 * Instead, the mock APIs should be used:
 * {@link FolksDummy.PersonaStore.freeze_personas_changed},
 * {@link FolksDummy.PersonaStore.register_personas},
 * {@link FolksDummy.PersonaStore.unregister_personas} and
 * {@link FolksDummy.PersonaStore.thaw_personas_changed}. These can be used to
 * build up complex {@link Folks.PersonaStore.personas_changed} signal
 * emissions, which are only emitted after the final call to
 * {@link FolksDummy.PersonaStore.thaw_personas_changed}.
 *
 * The API in {@link FolksDummy} is unstable and may change wildly. It is
 * designed mostly for use by libfolks unit tests.
 *
 * @since 0.9.7
 */
public class FolksDummy.PersonaStore : Folks.PersonaStore
{
  private bool _is_prepared = false;
  private bool _prepare_pending = false;
  private bool _is_quiescent = false;
  private bool _quiescent_on_prepare = false;
  private int  _contact_id = 0;

  /**
   * The type of persona store this is.
   *
   * See {@link Folks.PersonaStore.type_id}.
   *
   * @since 0.9.7
   */
  public override string type_id { get { return BACKEND_NAME; } }

  private MaybeBool _can_add_personas = MaybeBool.FALSE;

  /**
   * Whether this PersonaStore can add {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_add_personas}.
   *
   * @since 0.9.7
   */
  public override MaybeBool can_add_personas
    {
      get
        {
          if (!this._is_prepared)
            {
              return MaybeBool.FALSE;
            }

          return this._can_add_personas;
        }
    }

  private MaybeBool _can_alias_personas = MaybeBool.FALSE;

  /**
   * Whether this PersonaStore can set the alias of {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_alias_personas}.
   *
   * @since 0.9.7
   */
  public override MaybeBool can_alias_personas
    {
      get
        {
          if (!this._is_prepared)
            {
              return MaybeBool.FALSE;
            }

          return this._can_alias_personas;
        }
    }

  /**
   * Whether this PersonaStore can set the groups of {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_group_personas}.
   *
   * @since 0.9.7
   */
  public override MaybeBool can_group_personas
    {
      get
        {
          return ("groups" in this._always_writeable_properties)
              ? MaybeBool.TRUE : MaybeBool.FALSE;
        }
    }

  private MaybeBool _can_remove_personas = MaybeBool.FALSE;

  /**
   * Whether this PersonaStore can remove {@link Folks.Persona}s.
   *
   * See {@link Folks.PersonaStore.can_remove_personas}.
   *
   * @since 0.9.7
   */
  public override MaybeBool can_remove_personas
    {
      get
        {
          if (!this._is_prepared)
            {
              return MaybeBool.FALSE;
            }

          return this._can_remove_personas;
        }
    }

  /**
   * Whether this PersonaStore has been prepared.
   *
   * See {@link Folks.PersonaStore.is_prepared}.
   *
   * @since 0.9.7
   */
  public override bool is_prepared
    {
      get { return this._is_prepared; }
    }

  private string[] _always_writeable_properties = {};
  private static string[] _always_writeable_properties_empty = {}; /* oh Vala */

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override string[] always_writeable_properties
    {
      get
        {
          if (!this._is_prepared)
            {
              return PersonaStore._always_writeable_properties_empty;
            }

          return this._always_writeable_properties;
        }
    }

  /*
   * Whether this PersonaStore has reached a quiescent state.
   *
   * See {@link Folks.PersonaStore.is_quiescent}.
   *
   * @since 0.9.7
   */
  public override bool is_quiescent
    {
      get { return this._is_quiescent; }
    }

  private HashMap<string, Persona> _personas;
  private Map<string, Persona> _personas_ro;

  /* Personas which have been registered but not yet emitted in a
   * personas-changed signal. */
  private HashSet<Persona> _pending_persona_registrations;

  /* Personas which have been unregistered but not yet emitted in a
   * personas-changed signal. */
  private HashSet<Persona> _pending_persona_unregistrations;

  /* Freeze counter for persona changes: personas-changed is only emitted when
   * this is 0. */
  private uint _personas_changed_frozen = 0;

  /**
   * The {@link Persona}s exposed by this PersonaStore.
   *
   * See {@link Folks.PersonaStore.personas}.
   *
   * @since 0.9.7
   */
  public override Map<string, Folks.Persona> personas
    {
      get { return this._personas_ro; }
    }

  /**
   * Create a new persona store.
   *
   * This store will have no personas to begin with; use
   * {@link FolksDummy.PersonaStore.register_personas} to add some, then call
   * {@link FolksDummy.PersonaStore.reach_quiescence} to signal the store
   * reaching quiescence.
   *
   * @param id The new store's ID.
   * @param display_name The new store's display name.
   * @param always_writeable_properties The set of always writeable properties.
   *
   * @since 0.9.7
   */
  public PersonaStore (string id, string display_name,
      string[] always_writeable_properties)
    {
      Object (
          id: id,
          display_name: display_name);

      this._always_writeable_properties = always_writeable_properties;
    }

  construct
    {
      this._personas = new HashMap<string, Persona> ();
      this._personas_ro = this._personas.read_only_view;
      this._pending_persona_registrations = new HashSet<Persona> ();
      this._pending_persona_unregistrations = new HashSet<Persona> ();
    }

  /**
   * Add a new {@link Persona} to the PersonaStore.
   *
   * Accepted keys for ``details`` are:
   * - PersonaStore.detail_key (PersonaDetail.AVATAR)
   * - PersonaStore.detail_key (PersonaDetail.BIRTHDAY)
   * - PersonaStore.detail_key (PersonaDetail.EMAIL_ADDRESSES)
   * - PersonaStore.detail_key (PersonaDetail.FULL_NAME)
   * - PersonaStore.detail_key (PersonaDetail.GENDER)
   * - PersonaStore.detail_key (PersonaDetail.IM_ADDRESSES)
   * - PersonaStore.detail_key (PersonaDetail.IS_FAVOURITE)
   * - PersonaStore.detail_key (PersonaDetail.PHONE_NUMBERS)
   * - PersonaStore.detail_key (PersonaDetail.POSTAL_ADDRESSES)
   * - PersonaStore.detail_key (PersonaDetail.ROLES)
   * - PersonaStore.detail_key (PersonaDetail.STRUCTURED_NAME)
   * - PersonaStore.detail_key (PersonaDetail.LOCAL_IDS)
   * - PersonaStore.detail_key (PersonaDetail.WEB_SERVICE_ADDRESSES)
   * - PersonaStore.detail_key (PersonaDetail.NOTES)
   * - PersonaStore.detail_key (PersonaDetail.URLS)
   *
   * See {@link Folks.PersonaStore.add_persona_from_details}.
   *
   * @param details key–value pairs giving the new persona’s details
   * @throws Folks.PersonaStoreError.STORE_OFFLINE if the store hasn’t been
   * prepared
   * @throws Folks.PersonaStoreError.CREATE_FAILED if creating the persona in
   * the dummy store failed
   *
   * @since 0.9.7
   */
  public override async Folks.Persona? add_persona_from_details (
      HashTable<string, Value?> details) throws PersonaStoreError
    {
      /* We have to have called prepare() beforehand. */
      if (!this._is_prepared)
        {
          throw new PersonaStoreError.STORE_OFFLINE (
              "Persona store has not yet been prepared.");
        }

      /* Allow overriding the class used. */
      var contact_id = this._contact_id.to_string();
      this._contact_id++;
      var uid = Folks.Persona.build_uid (BACKEND_NAME, this.id, contact_id);
      var iid = this.id + ":" + contact_id;

      var persona = Object.new (this._persona_type,
          "display-id", contact_id,
          "uid", uid,
          "iid", iid,
          "store", this,
          "is-user", false,
          null) as FolksDummy.Persona;
      assert (persona != null);
      persona.update_writeable_properties (this.always_writeable_properties);

      unowned Value? v;

      try
        {
          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.FULL_NAME));
          var p_name = persona as NameDetails;
          if (p_name != null && v != null)
            {
              string full_name = ((!) v).get_string () ?? "";
              yield p_name.change_full_name (full_name);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.STRUCTURED_NAME));
          if (p_name != null && v != null)
            {
              var sname = (StructuredName) ((!) v).get_object ();
              if (sname != null)
                  yield p_name.change_structured_name (sname);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.NICKNAME));
          if (p_name != null && v != null)
            {
              string nickname = ((!) v).get_string () ?? "";
              yield p_name.change_nickname (nickname);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.EMAIL_ADDRESSES));
          var p_email = persona as EmailDetails;
          if (p_email != null && v != null)
            {
              var email_addresses = (Set<EmailFieldDetails>) ((!) v).get_object ();
              if (email_addresses != null)
                  yield p_email.change_email_addresses (email_addresses);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.AVATAR));
          var p_avatar = persona as AvatarDetails;
          if (p_avatar != null && v != null)
            {
              var avatar = (LoadableIcon?) ((!) v).get_object ();
              if (avatar != null)
                  yield p_avatar.change_avatar (avatar);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.IM_ADDRESSES));
          var p_im = persona as ImDetails;
          if (p_im != null && v != null)
            {
              var im_addresses =
                  (MultiMap<string,ImFieldDetails>) ((!) v).get_object ();
              if (im_addresses != null)
                  yield p_im.change_im_addresses (im_addresses);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.PHONE_NUMBERS));
          var p_phone = persona as PhoneDetails;
          if (p_phone != null && v != null)
            {
              var phone_numbers = (Set<PhoneFieldDetails>) ((!) v).get_object ();
              if (phone_numbers != null)
                  yield p_phone.change_phone_numbers (phone_numbers);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.POSTAL_ADDRESSES));
          var p_postal = persona as PostalAddressDetails;
          if (p_postal != null && v != null)
            {
              var postal_fds =
                  (Set<PostalAddressFieldDetails>) ((!) v).get_object ();
              if (postal_fds != null)
                  yield p_postal.change_postal_addresses (postal_fds);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.LOCAL_IDS));
          var p_local = persona as LocalIdDetails;
          if (p_local != null && v != null)
            {
              var local_ids = (Set<string>) ((!) v).get_object ();
              if (local_ids != null)
                  yield p_local.change_local_ids (local_ids);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (
                  PersonaDetail.WEB_SERVICE_ADDRESSES));
          var p_web = persona as WebServiceDetails;
          if (p_web != null && v != null)
            {
              var addrs =
                  (HashMultiMap<string, WebServiceFieldDetails>)
                      ((!) v).get_object ();
              if (addrs != null)
                  yield p_web.change_web_service_addresses (addrs);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.NOTES));
          var p_note = persona as NoteDetails;
          if (p_note != null && v != null)
            {
              var notes = (Gee.HashSet<NoteFieldDetails>) ((!) v).get_object ();
              if (notes != null)
                  yield p_note.change_notes (notes);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.GENDER));
          var p_gender = persona as GenderDetails;
          if (p_gender != null && v != null)
            {
              var gender = (Gender) ((!) v).get_enum ();
              yield p_gender.change_gender (gender);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.URLS));
          var p_url = persona as UrlDetails;
          if (p_url != null && v != null)
            {
              var urls = (Set<UrlFieldDetails>) ((!) v).get_object ();
              if (urls != null)
                  yield p_url.change_urls (urls);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.BIRTHDAY));
          var p_birthday = persona as BirthdayDetails;
          if (p_birthday != null && v != null)
            {
              var birthday = (DateTime?) ((!) v).get_boxed ();
              if (birthday != null)
                  yield p_birthday.change_birthday (birthday);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.ROLES));
          var p_role = persona as RoleDetails;
          if (p_role != null && v != null)
            {
              var roles = (Set<RoleFieldDetails>) ((!) v).get_object ();
              if (roles != null)
                  yield p_role.change_roles (roles);
            }

          v = details.lookup (
              Folks.PersonaStore.detail_key (PersonaDetail.IS_FAVOURITE));
          var p_favourite = persona as FavouriteDetails;
          if (p_favourite != null && v != null)
            {
              bool is_fav = ((!) v).get_boolean ();
              yield p_favourite.change_is_favourite (is_fav);
            }
        }
      catch (PropertyError e1)
        {
          throw new PersonaStoreError.CREATE_FAILED (
              "Setting a property on the new persona failed: %s", e1.message);
        }

      /* Allow the caller to inject failures and delays into
       * add_persona_from_details() by providing a mock function. */
      if (this._add_persona_from_details_mock != null)
        {
          var delay = this._add_persona_from_details_mock (persona);
          yield this._implement_mock_delay (delay);
        }

      /* No simulated failure: continue adding the persona. */
      this._personas.set (persona.iid, persona);

      /* Notify of the new persona. */
      var added_personas = new HashSet<Persona> ();
      added_personas.add (persona);
      this._emit_personas_changed (added_personas, null);

      return persona;
    }

  /**
   * Remove a {@link Persona} from the PersonaStore.
   *
   * See {@link Folks.PersonaStore.remove_persona}.
   *
   * @param persona the persona that should be removed
   * @throws Folks.PersonaStoreError.STORE_OFFLINE if the store hasn’t been
   * prepared or has gone offline
   * @throws Folks.PersonaStoreError.PERMISSION_DENIED if the store denied
   * permission to delete the contact
   * @throws Folks.PersonaStoreError.READ_ONLY if the store is read only
   * @throws Folks.PersonaStoreError.REMOVE_FAILED if any other errors happened
   * in the store
   *
   * @since 0.9.7
   */
  public override async void remove_persona (Folks.Persona persona)
      throws PersonaStoreError
      requires (persona is FolksDummy.Persona)
    {
      /* We have to have called prepare() beforehand. */
      if (!this._is_prepared)
        {
          throw new PersonaStoreError.STORE_OFFLINE (
              "Persona store has not yet been prepared.");
        }

      /* Allow the caller to inject failures and delays. */
      if (this._remove_persona_mock != null)
        {
          var delay = this._remove_persona_mock ((FolksDummy.Persona) persona);
          yield this._implement_mock_delay (delay);
        }

      Persona? _persona = this._personas.get (persona.iid);
      if (_persona != null)
        {
          this._personas.unset (persona.iid);

          /* Handle the case where a contact is removed while persona changes
           * are frozen. */
          this._pending_persona_registrations.remove ((!) _persona);
          this._pending_persona_unregistrations.remove ((!) _persona);

          /* Notify of the removal. */
          var removed_personas = new HashSet<Folks.Persona> ();
          removed_personas.add ((!) persona);
          this._emit_personas_changed (null, removed_personas);
        }
    }

  /**
   * Prepare the PersonaStore for use.
   *
   * See {@link Folks.PersonaStore.prepare}.
   *
   * @throws Folks.PersonaStoreError.STORE_OFFLINE if the store is offline
   * @throws Folks.PersonaStoreError.PERMISSION_DENIED if permission was denied
   * to open the store
   * @throws Folks.PersonaStoreError.INVALID_ARGUMENT if any other error
   * occurred in the store
   *
   * @since 0.9.7
   */
  public override async void prepare () throws PersonaStoreError
    {
      Internal.profiling_start ("preparing Dummy.PersonaStore (ID: %s)",
          this.id);

      if (this._is_prepared == true || this._prepare_pending == true)
        {
          return;
        }

      try
        {
          this._prepare_pending = true;

          /* Allow the caller to inject failures and delays. */
          if (this._prepare_mock != null)
            {
              var delay = this._prepare_mock ();
              yield this._implement_mock_delay (delay);
            }

          this._is_prepared = true;
          this.notify_property ("is-prepared");

          /* If reach_quiescence() has been called already, signal
           * quiescence. */
          if (this._quiescent_on_prepare == true)
            {
              this.reach_quiescence ();
            }
        }
      finally
        {
          this._prepare_pending = false;
        }

      Internal.profiling_end ("preparing Dummy.PersonaStore");
    }


  /*
   * All the functions below here are to be used by testing code rather than by
   * libfolks clients. They form the interface which would normally be between
   * the PersonaStore and a web service or backing store of some kind.
   */


  /**
   * Delay for the given number of milliseconds.
   *
   * This implements an asynchronous delay (which should be yielded on) until
   * the given number of milliseconds has elapsed.
   *
   * If ``delay`` is negative, this function returns immediately. If it is
   * zero, this function returns in an idle callback.
   *
   * @param delay number of milliseconds to delay for
   *
   * @since 0.9.7
   */
  private async void _implement_mock_delay (int delay)
    {
      if (delay < 0)
        {
          /* No delay. */
          return;
        }
      else if (delay == 0)
        {
          /* Idle delay. */
          Idle.add (() =>
            {
              this._implement_mock_delay.callback ();
              return false;
            });

          yield;
        }
      else
        {
          /* Timed delay. */
          Timeout.add (delay, () =>
            {
              this._implement_mock_delay.callback ();
              return false;
            });

          yield;
        }
    }

  /**
   * Type of a mock function for
   * {@link Folks.PersonaStore.add_persona_from_details}.
   *
   * See {@link FolksDummy.PersonaStore.set_add_persona_from_details_mock}.
   *
   * @param persona the persona being added to the store, as constructed from
   * the details passed to {@link Folks.PersonaStore.add_persona_from_details}.
   * @throws PersonaStoreError to be thrown from
   * {@link Folks.PersonaStore.add_persona_from_details}
   * @return delay to apply to the add persona operation (negative delays
   * complete synchronously; zero delays complete in an idle callback; positive
   * delays complete after that many milliseconds)
   *
   * @since 0.9.7
   */
  public delegate int AddPersonaFromDetailsMock (Persona persona)
      throws PersonaStoreError;

  /**
   * Mock function for {@link Folks.PersonaStore.add_persona_from_details}.
   */
  private unowned AddPersonaFromDetailsMock? _add_persona_from_details_mock = null;

  /**
   * Type of a mock function for {@link Folks.PersonaStore.remove_persona}.
   *
   * See {@link FolksDummy.PersonaStore.set_remove_persona_mock}.
   *
   * @param persona the persona being removed from the store
   * @throws PersonaStoreError to be thrown from
   * {@link Folks.PersonaStore.remove_persona}
   * @return delay to apply to the remove persona operation (negative and zero
   * delays complete in an idle callback; positive
   * delays complete after that many milliseconds)
   *
   * @since 0.9.7
   */
  public delegate int RemovePersonaMock (Persona persona)
      throws PersonaStoreError;

  /**
   * Mock function for {@link Folks.PersonaStore.remove_persona}.
   */
  private unowned RemovePersonaMock? _remove_persona_mock = null;

  /**
   * Type of a mock function for {@link Folks.PersonaStore.prepare}.
   *
   * See {@link FolksDummy.PersonaStore.set_prepare_mock}.
   *
   * @throws PersonaStoreError to be thrown from
   * {@link Folks.PersonaStore.prepare}
   * @return delay to apply to the prepare operation (negative and zero delays
   * complete in an idle callback; positive
   * delays complete after that many milliseconds)
   *
   * @since 0.9.7
   */
  public delegate int PrepareMock () throws PersonaStoreError;

  /**
   * Mock function for {@link Folks.PersonaStore.prepare}.
   */
  private unowned PrepareMock? _prepare_mock = null;

  private Type _persona_type = typeof (FolksDummy.Persona);

  /**
   * Type of programmatically created personas.
   *
   * This is the type used to create new personas when
   * {@link Folks.PersonaStore.add_persona_from_details} is called. It must be a
   * subtype of {@link FolksDummy.Persona}.
   *
   * This may be modified at any time, with modifications taking effect for the
   * next call to {@link Folks.PersonaStore.add_persona_from_details} or
   * {@link FolksDummy.PersonaStore.register_personas}.
   *
   * @since 0.9.7
   */
  public Type persona_type
    {
      get { return this._persona_type; }
      set
        {
          assert (value.is_a (typeof (FolksDummy.Persona)));
          if (this._persona_type != value)
            {
              this._persona_type = value;
              this.notify_property ("persona-type");
            }
        }
    }

  /**
   * Set capabilities of the persona store.
   *
   * This sets the capabilities of the store, as if they were changed on a
   * backing store somewhere. This is intended to be used for testing code which
   * depends on the values of {@link Folks.PersonaStore.can_add_personas},
   * {@link Folks.PersonaStore.can_alias_personas} and
   * {@link Folks.PersonaStore.can_remove_personas}.
   *
   * @param can_add_personas whether the store can handle adding personas
   * @param can_alias_personas whether the store can handle and update
   * user-specified persona aliases
   * @param can_remove_personas whether the store can handle removing personas
   *
   * @since 0.9.7
   */
  public void update_capabilities (MaybeBool can_add_personas,
      MaybeBool can_alias_personas, MaybeBool can_remove_personas)
    {
      this.freeze_notify ();

      if (can_add_personas != this._can_add_personas)
        {
          this._can_add_personas = can_add_personas;
          this.notify_property ("can-add-personas");
        }

      if (can_alias_personas != this._can_alias_personas)
        {
          this._can_alias_personas = can_alias_personas;
          this.notify_property ("can-alias-personas");
        }

      if (can_remove_personas != this._can_remove_personas)
        {
          this._can_remove_personas = can_remove_personas;
          this.notify_property ("can-remove-personas");
        }

      this.thaw_notify ();
    }

  /**
   * Freeze persona changes in the store.
   *
   * This freezes externally-visible changes to the set of personas in the store
   * until {@link FolksDummy.PersonaStore.thaw_personas_changed} is called, at
   * which point all pending changes are made visible in the
   * {@link Folks.PersonaStore.personas} property and by emitting
   * {@link Folks.PersonaStore.personas_changed}.
   *
   * Calls to {@link FolksDummy.PersonaStore.freeze_personas_changed} and
   * {@link FolksDummy.PersonaStore.thaw_personas_changed} must be well-nested.
   * Pending changes will only be committed after the final call to
   * {@link FolksDummy.PersonaStore.thaw_personas_changed}.
   *
   * @see PersonaStore.thaw_personas_changed
   * @since 0.9.7
   */
  public void freeze_personas_changed ()
    {
      this._personas_changed_frozen++;
    }

  /**
   * Thaw persona changes in the store.
   *
   * This thaws externally-visible changes to the set of personas in the store.
   * If the number of calls to
   * {@link FolksDummy.PersonaStore.thaw_personas_changed} matches the number of
   * calls to {@link FolksDummy.PersonaStore.freeze_personas_changed}, all
   * pending changes are committed and made externally-visible.
   *
   * @see PersonaStore.freeze_personas_changed
   * @since 0.9.7
   */
  public void thaw_personas_changed ()
    {
      assert (this._personas_changed_frozen > 0);
      this._personas_changed_frozen--;

      if (this._personas_changed_frozen == 0)
        {
          /* Emit the queued changes. */
          this._emit_personas_changed (this._pending_persona_registrations,
              this._pending_persona_unregistrations);

          this._pending_persona_registrations.clear ();
          this._pending_persona_unregistrations.clear ();
        }
    }

  /**
   * Register new personas with the persona store.
   *
   * This registers a set of personas as if they had just appeared in the
   * backing store. If the persona store is not frozen (see
   * {@link FolksDummy.PersonaStore.freeze_personas_changed}) the changes are
   * made externally visible on the store immediately (e.g. in the
   * {@link Folks.PersonaStore.personas} property and through a
   * {@link Folks.PersonaStore.personas_changed} signal). If the store is
   * frozen, the changes will be pending until the store is next unfrozen.
   *
   * All elements in the @personas set be of type
   * {@link FolksDummy.PersonaStore.persona_type}.
   *
   * @param personas set of personas to register
   *
   * @since 0.9.7
   */
  public void register_personas (Set<Persona> personas)
    {
      Set<Persona> added_personas;
      var emit_notifications = (this._personas_changed_frozen == 0);

      /* If the persona store has persona changes frozen, queue up the
       * personas and emit a notification about them later. */
      if (emit_notifications == false)
          added_personas = this._pending_persona_registrations;
      else
          added_personas = new HashSet<Persona> ();

      foreach (var persona in personas)
        {
          assert (persona.get_type ().is_a (this._persona_type));

          /* Handle the case where a persona is unregistered while the store is
           * frozen, then registered again before it's unfrozen. */
          if (this._pending_persona_unregistrations.remove (persona))
              this._personas.unset (persona.iid);

          if (this._personas.has_key (persona.iid))
              continue;

          added_personas.add (persona);
          if (emit_notifications == true)
              this._personas.set (persona.iid, persona);
        }

      if (added_personas.size > 0 && emit_notifications == true)
          this._emit_personas_changed (added_personas, null);
    }

  /**
   * Unregister existing personas with the persona store.
   *
   * This unregisters a set of personas as if they had just disappeared from the
   * backing store. If the persona store is not frozen (see
   * {@link FolksDummy.PersonaStore.freeze_personas_changed}) the changes are
   * made externally visible on the store immediately (e.g. in the
   * {@link Folks.PersonaStore.personas} property and through a
   * {@link Folks.PersonaStore.personas_changed} signal). If the store is
   * frozen, the changes will be pending until the store is next unfrozen.
   *
   * @param personas set of personas to unregister
   *
   * @since 0.9.7
   */
  public void unregister_personas (Set<Persona> personas)
    {
      Set<Persona> removed_personas;
      var emit_notifications = (this._personas_changed_frozen == 0);

      /* If the persona store has persona changes frozen, queue up the
       * personas and emit a notification about them later. */
      if (emit_notifications == false)
          removed_personas = this._pending_persona_unregistrations;
      else
          removed_personas = new HashSet<Persona> ();

      foreach (var _persona in personas)
        {
          /* Handle the case where a persona is registered while the store is
           * frozen, then unregistered before it's unfrozen. */
          this._pending_persona_registrations.remove (_persona);

          Persona? persona = this._personas.get (_persona.iid);
          if (persona == null)
              continue;

          removed_personas.add ((!) persona);
        }

      /* Modify this._personas afterwards, just in case
       * personas == this._personas. */
       if (removed_personas.size > 0 && emit_notifications == true)
         {
           foreach (var _persona in removed_personas)
                this._personas.unset (_persona.iid);

           this._emit_personas_changed (null, removed_personas);
         }
    }

  /**
   * Reach quiescence on the store.
   *
   * If the {@link Folks.PersonaStore.prepare} method has already been called on
   * the store, this causes the store to signal that it has reached quiescence
   * immediately. If the store has not yet been prepared, this will set a flag
   * to ensure that quiescence is reached as soon as
   * {@link Folks.PersonaStore.prepare} is called.
   *
   * This must be called before the store will reach quiescence.
   *
   * @since 0.9.7
   */
  public void reach_quiescence ()
    {
      /* Can't reach quiescence until prepare() has been called. */
      if (this._is_prepared == false)
        {
          this._quiescent_on_prepare = true;
          return;
        }

      /* The initial query is complete, so signal that we've reached
       * quiescence (even if there was an error). */
      if (this._is_quiescent == false)
        {
          this._is_quiescent = true;
          this.notify_property ("is-quiescent");
        }
    }

  /**
   * Update the {@link Folks.PersonaStore.is_user_set_default} property.
   *
   * Backend method for use by test code to simulate a backing-store-driven
   * change in the {@link Folks.PersonaStore.is_user_set_default} property.
   *
   * @param is_user_set_default new value for the property
   *
   * @since 0.9.7
   */
  public void update_is_user_set_default (bool is_user_set_default)
    {
      /* Implemented as an ‘update_*()’ method to make it more explicit that
       * this is for test driver use only. */
      this.is_user_set_default = is_user_set_default;
    }

  /**
   * Update the {@link Folks.PersonaStore.trust_level} property.
   *
   * Backend method for use by test code to simulate a backing-store-driven
   * change in the {@link Folks.PersonaStore.trust_level} property.
   *
   * @param trust_level new value for the property
   *
   * @since 0.9.7
   */
  public void update_trust_level (PersonaStoreTrust trust_level)
    {
      /* Implemented as an ‘update_*()’ method to make it more explicit that
       * this is for test driver use only. */
      this.trust_level = trust_level;
    }

  /**
   * Mock function for {@link Folks.PersonaStore.add_persona_from_details}.
   *
   * This function is called whenever this store's
   * {@link Folks.PersonaStore.add_persona_from_details} method is called. It
   * allows the caller to determine whether adding the given persona should
   * fail, by throwing an error from this mock function. If no error is thrown
   * from this function, adding the given persona will succeed. This is useful
   * for testing error handling of calls to
   * {@link Folks.PersonaStore.add_persona_from_details}.
   *
   * The value returned by this function gives a delay which is imposed for
   * completion of the {@link Folks.PersonaStore.add_persona_from_details} call.
   * Negative or zero delays
   * result in completion in an idle callback, and positive delays result in
   * completion after that many milliseconds.
   *
   * If this is ``null``, all calls to
   * {@link Folks.PersonaStore.add_persona_from_details} will succeed.
   *
   * This mock function may be changed at any time; changes will take effect for
   * the next call to {@link Folks.PersonaStore.add_persona_from_details}.
   *
   * @since 0.9.7
   */
  public void set_add_persona_from_details_mock (AddPersonaFromDetailsMock? mock)
    {
      this._add_persona_from_details_mock = mock;
    }

  /**
   * Mock function for {@link Folks.PersonaStore.remove_persona}.
   *
   * This function is called whenever this store's
   * {@link Folks.PersonaStore.remove_persona} method is called. It allows
   * the caller to determine whether removing the given persona should fail, by
   * throwing an error from this mock function. If no error is thrown from this
   * function, removing the given persona will succeed. This is useful for
   * testing error handling of calls to
   * {@link Folks.PersonaStore.remove_persona}.
   *
   * See {@link FolksDummy.PersonaStore.set_add_persona_from_details_mock}.
   *
   * This mock function may be changed at any time; changes will take effect for
   * the next call to {@link Folks.PersonaStore.remove_persona}.
   *
   * @since 0.9.7
   */
  public void set_remove_persona_mock (RemovePersonaMock? mock)
    {
      this._remove_persona_mock = mock;
    }

  /**
   * Mock function for {@link Folks.PersonaStore.prepare}.
   *
   * This function is called whenever this store's
   * {@link Folks.PersonaStore.prepare} method is called on an unprepared store.
   * It allows the caller to determine whether preparing the store should fail,
   * by throwing an error from this mock function. If no error is thrown from
   * this function, preparing the store will succeed (and all future calls to
   * {@link Folks.PersonaStore.prepare} will return immediately without calling
   * this mock function). This is useful for testing error handling of calls to
   * {@link Folks.PersonaStore.prepare}.
   *
   * See {@link FolksDummy.PersonaStore.set_add_persona_from_details_mock}.
   *
   * This mock function may be changed at any time; changes will take effect for
   * the next call to {@link Folks.PersonaStore.prepare}.
   *
   * @since 0.9.7
   */
  public void set_prepare_mock (PrepareMock? mock)
    {
      this._prepare_mock = mock;
    }
}
