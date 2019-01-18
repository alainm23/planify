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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 *       Marco Barisione <marco.barisione@collabora.co.uk>
 *       Raul Gutierrez Segales <raul.gutierrez.segales@collabora.co.uk>
 */

using Folks;
using Gee;
using GLib;

/**
 * A persona subclass representing a single ‘full’ contact.
 *
 * This mocks up a ‘full’ persona which implements all the available property
 * interfaces provided by libfolks. This is in contrast with
 * {@link FolksDummy.Persona}, which provides a base class implementing none of
 * libfolks’ interfaces.
 *
 * The full dummy persona can be used to simulate a persona from most libfolks
 * backends, if writing a custom {@link FolksDummy.Persona} subclass is not an
 * option.
 *
 * There are two sides to this class’ interface: the normal methods required by
 * the libfolks ‘details’ interfaces, such as
 * {@link Folks.GenderDetails.change_gender},
 * and the backend methods which should be called by test driver code to
 * simulate changes in the backing store providing this persona, such as
 * {@link FullPersona.update_gender}. For example, test driver code should call
 * {@link FullPersona.update_nickname} to simulate the user editing a contact’s
 * nickname in an online address book which is being exposed to libfolks. The
 * ``update_``, ``register_`` and ``unregister_`` prefixes are commonly used for
 * backend methods.
 *
 * The API in {@link FolksDummy} is unstable and may change wildly. It is
 * designed mostly for use by libfolks unit tests.
 *
 * @since 0.9.7
 */
public class FolksDummy.FullPersona : FolksDummy.Persona,
    AntiLinkable,
    AvatarDetails,
    BirthdayDetails,
    EmailDetails,
    FavouriteDetails,
    GenderDetails,
    GroupDetails,
    ImDetails,
    LocalIdDetails,
    NameDetails,
    NoteDetails,
    PhoneDetails,
    RoleDetails,
    UrlDetails,
    PostalAddressDetails,
    WebServiceDetails
{
  private const string[] _default_linkable_properties =
    {
      "im-addresses",
      "email-addresses",
      "local-ids",
      "web-service-addresses",
      null /* FIXME: https://bugzilla.gnome.org/show_bug.cgi?id=682698 */
    };


  /**
   * Create a new ‘full’ persona.
   *
   * Create a new persona for the {@link FolksDummy.PersonaStore} ``store``,
   * with the given construct-only properties.
   *
   * @param store the store which will contain the persona
   * @param contact_id a unique free-form string identifier for the persona
   * @param is_user ``true`` if the persona represents the user, ``false``
   * otherwise
   * @param linkable_properties an array of names of the properties which should
   * be used for linking this persona to others
   *
   * @since 0.9.7
   */
  public FullPersona (PersonaStore store, string contact_id,
      bool is_user = false,
      string[] linkable_properties = {})
    {
      base (store, contact_id, is_user, linkable_properties);
    }

  construct
    {
      this._local_ids_ro = this._local_ids.read_only_view;
      this._postal_addresses_ro = this._postal_addresses.read_only_view;
      this._email_addresses_ro = this._email_addresses.read_only_view;
      this._phone_numbers_ro = this._phone_numbers.read_only_view;
      this._notes_ro = this._notes.read_only_view;
      this._urls_ro = this._urls.read_only_view;
      this._groups_ro = this._groups.read_only_view;
      this._roles_ro = this._roles.read_only_view;
      this._anti_links_ro = this._anti_links.read_only_view;
      this.update_linkable_properties (
          FullPersona._default_linkable_properties);
    }

  private HashMultiMap<string, WebServiceFieldDetails> _web_service_addresses =
      new HashMultiMap<string, WebServiceFieldDetails> (
          null, null,
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public MultiMap<string, WebServiceFieldDetails> web_service_addresses
    {
      get { return this._web_service_addresses; }
      set { this.change_web_service_addresses.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_web_service_addresses (
      MultiMap<string, WebServiceFieldDetails> web_service_addresses)
          throws PropertyError
    {
      yield this.change_property ("web-service-addresses", () =>
        {
          this.update_web_service_addresses (web_service_addresses);
        });
    }

  private HashSet<string> _local_ids = new HashSet<string> ();
  private Set<string> _local_ids_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<string> local_ids
    {
      get
        {
          if (this._local_ids.contains (this.iid) == false)
            {
              this._local_ids.add (this.iid);
            }
          return this._local_ids_ro;
        }
      set { this.change_local_ids.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_local_ids (Set<string> local_ids)
      throws PropertyError
    {
      yield this.change_property ("local-ids", () =>
        {
          this.update_local_ids (local_ids);
        });
    }

  private HashSet<PostalAddressFieldDetails> _postal_addresses =
      new HashSet<PostalAddressFieldDetails> ();
  private Set<PostalAddressFieldDetails> _postal_addresses_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<PostalAddressFieldDetails> postal_addresses
    {
      get { return this._postal_addresses_ro; }
      set { this.change_postal_addresses.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_postal_addresses (
      Set<PostalAddressFieldDetails> postal_addresses) throws PropertyError
    {
      yield this.change_property ("postal-addresses", () =>
        {
          this.update_postal_addresses (postal_addresses);
        });
    }

  private HashSet<PhoneFieldDetails> _phone_numbers =
      new HashSet<PhoneFieldDetails> ();
  private Set<PhoneFieldDetails> _phone_numbers_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<PhoneFieldDetails> phone_numbers
    {
      get { return this._phone_numbers_ro; }
      set { this.change_phone_numbers.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_phone_numbers (
      Set<PhoneFieldDetails> phone_numbers) throws PropertyError
    {
      yield this.change_property ("phone-numbers", () =>
        {
          this.update_phone_numbers (phone_numbers);
        });
    }

  private HashSet<EmailFieldDetails>? _email_addresses =
      new HashSet<EmailFieldDetails> (
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);
  private Set<EmailFieldDetails> _email_addresses_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<EmailFieldDetails> email_addresses
    {
      get { return this._email_addresses_ro; }
      set { this.change_email_addresses.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_email_addresses (
      Set<EmailFieldDetails> email_addresses) throws PropertyError
    {
      yield this.change_property ("email-addresses", () =>
        {
          this.update_email_addresses (email_addresses);
        });
    }

  private HashSet<NoteFieldDetails> _notes = new HashSet<NoteFieldDetails> ();
  private Set<NoteFieldDetails> _notes_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<NoteFieldDetails> notes
    {
      get { return this._notes_ro; }
      set { this.change_notes.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_notes (Set<NoteFieldDetails> notes)
      throws PropertyError
    {
      yield this.change_property ("notes", () =>
        {
          this.update_notes (notes);
        });
    }

  private LoadableIcon? _avatar = null;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public LoadableIcon? avatar
    {
      get { return this._avatar; }
      set { this.change_avatar.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_avatar (LoadableIcon? avatar) throws PropertyError
    {
      yield this.change_property ("avatar", () =>
        {
          this.update_avatar (avatar);
        });
    }

  private StructuredName? _structured_name = null;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public StructuredName? structured_name
    {
      get { return this._structured_name; }
      set { this.change_structured_name.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_structured_name (StructuredName? structured_name)
      throws PropertyError
    {
      yield this.change_property ("structured-name", () =>
        {
          this.update_structured_name (structured_name);
        });
    }

  private string _full_name = "";

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public string full_name
    {
      get { return this._full_name; }
      set { this.change_full_name.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_full_name (string full_name) throws PropertyError
    {
      yield this.change_property ("full-name", () =>
        {
          this.update_full_name (full_name);
        });
    }

  private string _nickname = "";

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public string nickname
    {
      get { return this._nickname; }
      set { this.change_nickname.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_nickname (string nickname) throws PropertyError
    {
      yield this.change_property ("nickname", () =>
        {
          this.update_nickname (nickname);
        });
    }

  private Gender _gender = Gender.UNSPECIFIED;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Gender gender
    {
      get { return this._gender; }
      set { this.change_gender.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_gender (Gender gender) throws PropertyError
    {
      yield this.change_property ("gender", () =>
        {
          this.update_gender (gender);
        });
    }

  private HashSet<UrlFieldDetails> _urls = new HashSet<UrlFieldDetails> ();
  private Set<UrlFieldDetails> _urls_ro;
  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<UrlFieldDetails> urls
    {
      get { return this._urls_ro; }
      set { this.change_urls.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_urls (Set<UrlFieldDetails> urls) throws PropertyError
    {
      yield this.change_property ("urls", () =>
        {
          this.update_urls (urls);
        });
    }

  private HashMultiMap<string, ImFieldDetails> _im_addresses =
      new HashMultiMap<string, ImFieldDetails> (null, null,
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public MultiMap<string, ImFieldDetails> im_addresses
    {
      get { return this._im_addresses; }
      set { this.change_im_addresses.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_im_addresses (
      MultiMap<string, ImFieldDetails> im_addresses) throws PropertyError
    {
      yield this.change_property ("im-addresses", () =>
        {
          this.update_im_addresses (im_addresses);
        });
    }

  private HashSet<string> _groups = new HashSet<string> ();
  private Set<string> _groups_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<string> groups
    {
      get { return this._groups_ro; }
      set { this.change_groups.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_group (string group, bool is_member)
      throws GLib.Error
    {
      /* Nothing to do? */
      if ((is_member == true && this._groups.contains (group) == true) ||
          (is_member == false && this._groups.contains (group) == false))
        {
          return;
        }

      /* Replace the current set of groups with a modified one. */
      var new_groups = new HashSet<string> ();
      foreach (var category_name in this._groups)
        {
          new_groups.add (category_name);
        }

      if (is_member == false)
        {
          new_groups.remove (group);
        }
      else
        {
          new_groups.add (group);
        }

      yield this.change_groups (new_groups);
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_groups (Set<string> groups) throws PropertyError
    {
      yield this.change_property ("groups", () =>
        {
          this.update_groups (groups);
        });
    }

  private string? _calendar_event_id = null;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public string? calendar_event_id
    {
      get { return this._calendar_event_id; }
      set { this.change_calendar_event_id.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_calendar_event_id (string? calendar_event_id)
      throws PropertyError
    {
      yield this.change_property ("calendar-event-id", () =>
        {
          this.update_calendar_event_id (calendar_event_id);
        });
    }

  private DateTime? _birthday = null;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public DateTime? birthday
    {
      get { return this._birthday; }
      set { this.change_birthday.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_birthday (DateTime? bday)
      throws PropertyError
    {
      yield this.change_property ("birthday", () =>
        {
          this.update_birthday (bday);
        });
    }

  private HashSet<RoleFieldDetails> _roles = new HashSet<RoleFieldDetails> ();
  private Set<RoleFieldDetails> _roles_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<RoleFieldDetails> roles
    {
      get { return this._roles_ro; }
      set { this.change_roles.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_roles (Set<RoleFieldDetails> roles)
      throws PropertyError
    {
      yield this.change_property ("roles", () =>
        {
          this.update_roles (roles);
        });
    }

  private bool _is_favourite = false;

  /**
   * Whether this contact is a user-defined favourite.
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public bool is_favourite
    {
      get { return this._is_favourite; }
      set { this.change_is_favourite.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_is_favourite (bool is_favourite) throws PropertyError
    {
      yield this.change_property ("is-favourite", () =>
        {
          this.update_is_favourite (is_favourite);
        });
    }

  private HashSet<string> _anti_links = new HashSet<string> ();
  private Set<string> _anti_links_ro;

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public Set<string> anti_links
    {
      get { return this._anti_links_ro; }
      set { this.change_anti_links.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public async void change_anti_links (Set<string> anti_links)
      throws PropertyError
    {
      yield this.change_property ("anti-links", () =>
        {
          this.update_anti_links (anti_links);
        });
    }


  /*
   * All the functions below here are to be used by testing code rather than by
   * libfolks clients. They form the interface which would normally be between
   * the Persona and a web service or backing store of some kind.
   */


  private HashSet<T> _dup_to_hash_set<T> (Set<T> input_set)
    {
      var output_set = new HashSet<T> ();
      output_set.add_all (input_set);
      return output_set;
    }

  private HashMultiMap<S, T> _dup_to_hash_multi_map<S, T> (
      MultiMap<S, T> input_multi_map)
    {
      var output_multi_map = new HashMultiMap<S, T> ();

      var iter = input_multi_map.map_iterator ();
      while (iter.next () == true)
          output_multi_map.set (iter.get_key (), iter.get_value ());

      return output_multi_map;
    }

  /**
   * Update persona's gender.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.GenderDetails.gender} property. It is intended to be used for
   * testing code which consumes this property. If the property value changes,
   * this results in a property change notification on the persona.
   *
   * @param gender persona's new gender
   * @since 0.9.7
   */
  public void update_gender (Gender gender)
    {
      if (this._gender != gender)
        {
          this._gender = gender;
          this.notify_property ("gender");
        }
    }

  /**
   * Update persona's birthday calendar event ID.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.BirthdayDetails.calendar_event_id} property. It is intended to
   * be used for testing code which consumes this property. If the property
   * value changes, this results in a property change notification on the
   * persona.
   *
   * @param calendar_event_id persona's new birthday calendar event ID
   * @since 0.9.7
   */
  public void update_calendar_event_id (string? calendar_event_id)
    {
      if (calendar_event_id != this._calendar_event_id)
        {
          this._calendar_event_id = calendar_event_id;
          this.notify_property ("calendar-event-id");
        }
    }

  /**
   * Update persona's birthday.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.BirthdayDetails.birthday} property. It is intended to be used
   * for testing code which consumes this property. If the property value
   * changes, this results in a property change notification on the persona.
   *
   * @param birthday persona's new birthday
   * @since 0.9.7
   */
  public void update_birthday (DateTime? birthday)
    {
      if ((this._birthday == null) != (birthday == null) ||
          (this._birthday != null && birthday != null &&
              !((!) this._birthday).equal ((!) birthday)))
        {
          this._birthday = birthday;
          this.notify_property ("birthday");
        }
    }

  /**
   * Update persona's roles.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.RoleDetails.roles} property. It is intended to be used for
   * testing code which consumes this property. If the property value changes,
   * this results in a property change notification on the persona.
   *
   * @param roles persona's new roles
   * @since 0.9.7
   */
  public void update_roles (Set<RoleFieldDetails> roles)
    {
      if (!Folks.Internal.equal_sets<RoleFieldDetails> (roles, this._roles))
        {
          this._roles = this._dup_to_hash_set<RoleFieldDetails> (roles);
          this._roles_ro = this._roles.read_only_view;
          this.notify_property ("roles");
        }
    }

  /**
   * Update persona's groups.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.GroupDetails.groups} property. It is intended to be used for
   * testing code which consumes this property. If the property value changes,
   * this results in a property change notification on the persona.
   *
   * @param groups persona's new groups
   * @since 0.9.7
   */
  public void update_groups (Set<string> groups)
    {
      if (!Folks.Internal.equal_sets<string> (groups, this._groups))
        {
          this._groups = this._dup_to_hash_set<string> (groups);
          this._groups_ro = this._groups.read_only_view;
          this.notify_property ("groups");
        }
    }

  /**
   * Update persona's web service addresses.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.WebServiceDetails.web_service_addresses} property. It is
   * intended to be used for testing code which consumes this property. If the
   * property value changes, this results in a property change notification on
   * the persona.
   *
   * @param web_service_addresses persona's new web service addresses
   * @since 0.9.7
   */
  public void update_web_service_addresses (
      MultiMap<string, WebServiceFieldDetails> web_service_addresses)
    {
      if (!Utils.multi_map_str_afd_equal (web_service_addresses,
              this._web_service_addresses))
        {
          this._web_service_addresses =
              this._dup_to_hash_multi_map<string, WebServiceFieldDetails> (
                  web_service_addresses);
          this.notify_property ("web-service-addresses");
        }
    }

  /**
   * Update persona's e-mail addresses.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.EmailDetails.email_addresses} property. It is intended to be
   * used for testing code which consumes this property. If the property value
   * changes, this results in a property change notification on the persona.
   *
   * @param email_addresses persona's new e-mail addresses
   * @since 0.9.7
   */
  public void update_email_addresses (Set<EmailFieldDetails> email_addresses)
    {
      if (!Folks.Internal.equal_sets<EmailFieldDetails> (email_addresses,
               this._email_addresses))
        {
          this._email_addresses =
              this._dup_to_hash_set<EmailFieldDetails> (email_addresses);
          this._email_addresses_ro = this._email_addresses.read_only_view;
          this.notify_property ("email-addresses");
       }
    }

  /**
   * Update persona's notes.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.NoteDetails.notes} property. It is intended to be used for
   * testing code which consumes this property. If the property value changes,
   * this results in a property change notification on the persona.
   *
   * @param notes persona's new notes
   * @since 0.9.7
   */
  public void update_notes (Set<NoteFieldDetails> notes)
    {
      if (!Folks.Internal.equal_sets<NoteFieldDetails> (notes, this._notes))
        {
          this._notes = this._dup_to_hash_set<NoteFieldDetails> (notes);
          this._notes_ro = this._notes.read_only_view;
          this.notify_property ("notes");
        }
    }

  /**
   * Update persona's full name.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.NameDetails.full_name} property. It is intended to be used for
   * testing code which consumes this property. If the property value changes,
   * this results in a property change notification on the persona.
   *
   * @param full_name persona's new full name
   * @since 0.9.7
   */
  public void update_full_name (string full_name)
    {
      if (this._full_name != full_name)
        {
          this._full_name = full_name;
          this.notify_property ("full-name");
        }
    }

  /**
   * Update persona's nickname.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.NameDetails.nickname} property. It is intended to be used for
   * testing code which consumes this property. If the property value changes,
   * this results in a property change notification on the persona.
   *
   * @param nickname persona's new nickname
   * @since 0.9.7
   */
  public void update_nickname (string nickname)
    {
      if (this._nickname != nickname)
        {
          this._nickname = nickname;
          this.notify_property ("nickname");
        }
    }

  /**
   * Update persona's structured name.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.NameDetails.structured_name} property. It is intended to be
   * used for testing code which consumes this property. If the property value
   * changes, this results in a property change notification on the persona.
   *
   * @param structured_name persona's new structured name
   * @since 0.9.7
   */
  public void update_structured_name (StructuredName? structured_name)
    {
      if (structured_name != null && !((!) structured_name).is_empty ())
        {
          this._structured_name = (!) structured_name;
          this.notify_property ("structured-name");
        }
      else if (this._structured_name != null)
        {
          this._structured_name = null;
          this.notify_property ("structured-name");
        }
    }

  /**
   * Update persona's avatar.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.AvatarDetails.avatar} property. It is intended to be used for
   * testing code which consumes this property. If the property value changes,
   * this results in a property change notification on the persona.
   *
   * @param avatar persona's new avatar
   * @since 0.9.7
   */
  public void update_avatar (LoadableIcon? avatar)
    {
      if ((this._avatar == null) != (avatar == null) ||
          (this._avatar != null && avatar != null &&
              !((!) this._avatar).equal ((!) avatar)))
        {
          this._avatar = avatar;
          this.notify_property ("avatar");
        }
    }

  /**
   * Update persona's URIs.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.UrlDetails.urls} property. It is intended to be used for
   * testing code which consumes this property. If the property value changes,
   * this results in a property change notification on the persona.
   *
   * @param urls persona's new URIs
   * @since 0.9.7
   */
  public void update_urls (Set<UrlFieldDetails> urls)
    {
      if (!Utils.set_afd_equal (urls, this._urls))
        {
          this._urls = this._dup_to_hash_set<UrlFieldDetails> (urls);
          this._urls_ro = this._urls.read_only_view;
          this.notify_property ("urls");
        }
    }

  /**
   * Update persona's IM addresses.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.ImDetails.im_addresses} property. It is intended to be used
   * for testing code which consumes this property. If the property value
   * changes, this results in a property change notification on the persona.
   *
   * @param im_addresses persona's new IM addresses
   * @since 0.9.7
   */
  public void update_im_addresses (
      MultiMap<string, ImFieldDetails> im_addresses)
    {
      if (!Utils.multi_map_str_afd_equal (im_addresses,
              this._im_addresses))
        {
          this._im_addresses =
              this._dup_to_hash_multi_map<string, ImFieldDetails> (
                  im_addresses);
          this.notify_property ("im-addresses");
        }
    }

  /**
   * Update persona's phone numbers.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.PhoneDetails.phone_numbers} property. It is intended to be
   * used for testing code which consumes this property. If the property value
   * changes, this results in a property change notification on the persona.
   *
   * @param phone_numbers persona's new phone numbers
   * @since 0.9.7
   */
  public void update_phone_numbers (Set<PhoneFieldDetails> phone_numbers)
    {
      if (!Utils.set_string_afd_equal (phone_numbers,
              this._phone_numbers))
        {
          this._phone_numbers =
              this._dup_to_hash_set<PhoneFieldDetails> (phone_numbers);
          this._phone_numbers_ro = this._phone_numbers.read_only_view;
          this.notify_property ("phone-numbers");
        }
   }

  /**
   * Update persona's postal addresses.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.PostalAddressDetails.postal_addresses} property. It is
   * intended to be used for testing code which consumes this property. If the
   * property value changes, this results in a property change notification on
   * the persona.
   *
   * @param postal_addresses persona's new postal addresses
   * @since 0.9.7
   */
  public void update_postal_addresses (
      Set<PostalAddressFieldDetails> postal_addresses)
    {
      if (!Folks.Internal.equal_sets<PostalAddressFieldDetails> (
              postal_addresses, this._postal_addresses))
        {
          this._postal_addresses =
              this._dup_to_hash_set<PostalAddressFieldDetails> (
                  postal_addresses);
          this._postal_addresses_ro = this._postal_addresses.read_only_view;
          this.notify_property ("postal-addresses");
        }
    }

  /**
   * Update persona's local IDs.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.LocalIdDetails.local_ids} property. It is intended to be used
   * for testing code which consumes this property. If the property value
   * changes, this results in a property change notification on the persona.
   *
   * @param local_ids persona's new local IDs
   * @since 0.9.7
   */
  public void update_local_ids (Set<string> local_ids)
    {
      if (!Folks.Internal.equal_sets<string> (local_ids, this.local_ids))
        {
          this._local_ids = this._dup_to_hash_set<string> (local_ids);
          this._local_ids_ro = this._local_ids.read_only_view;
          this.notify_property ("local-ids");
        }
    }

  /**
   * Update persona's status as a favourite.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.FavouriteDetails.is_favourite} property. It is intended to be
   * used for testing code which consumes this property. If the property value
   * changes, this results in a property change notification on the persona.
   *
   * @param is_favourite persona's new status as a favourite
   * @since 0.9.7
   */
  public void update_is_favourite (bool is_favourite)
    {
      if (is_favourite != this._is_favourite)
        {
          this._is_favourite = is_favourite;
          this.notify_property ("is-favourite");
        }
    }

  /**
   * Update persona's anti-links.
   *
   * This simulates a backing-store-side update of the persona's
   * {@link Folks.AntiLinkable.anti_links} property. It is intended to be used
   * for testing code which consumes this property. If the property value
   * changes, this results in a property change notification on the persona.
   *
   * @param anti_links persona's new anti-links
   * @since 0.9.7
   */
  public void update_anti_links (Set<string> anti_links)
    {
      if (!Folks.Internal.equal_sets<string> (anti_links, this._anti_links))
        {
          this._anti_links = this._dup_to_hash_set<string> (anti_links);
          this._anti_links_ro = this._anti_links.read_only_view;
          this.notify_property ("anti-links");
        }
    }
}
