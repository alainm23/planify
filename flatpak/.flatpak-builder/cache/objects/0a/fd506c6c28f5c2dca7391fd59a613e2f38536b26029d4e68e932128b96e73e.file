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
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using Gee;
using GLib;
using TelepathyGLib;
using Folks;

/**
 * A persona subclass which represents a single instant messaging contact from
 * Telepathy.
 *
 * There is a one-to-one correspondence between {@link Tpf.Persona}s and
 * {@link TelepathyGLib.Contact}s, although at any time the
 * {@link Tpf.Persona.contact} property of a persona may be ``null`` if the
 * contact's Telepathy connection isn't available (e.g. due to being offline).
 * In this case, the persona's properties persist from a local cache.
 */
public class Tpf.Persona : Folks.Persona,
    AliasDetails,
    AvatarDetails,
    BirthdayDetails,
    EmailDetails,
    FavouriteDetails,
    GroupDetails,
    InteractionDetails,
    ImDetails,
    NameDetails,
    PhoneDetails,
    PresenceDetails,
    UrlDetails
{
  private const string[] _linkable_properties =
    {
      "im-addresses",
      null /* FIXME: https://bugzilla.gnome.org/show_bug.cgi?id=682698 */
    };
  private string[] _writeable_properties = null;

  /* Whether we've finished being constructed; this is used to prevent
   * unnecessary trips to the Telepathy service to tell it about properties
   * being set which are actually just being set from data it's just given us.
   */
  private bool _is_constructed = false;

  /**
   * Whether the Persona is in the user's contact list.
   *
   * This will be true for most {@link Folks.Persona}s, but may not be true for
   * personas where {@link Folks.Persona.is_user} is true. If it's false in
   * this case, it means that the persona has been retrieved from the Telepathy
   * connection, but has not been added to the user's contact list.
   *
   * @since 0.3.5
   */
  public bool is_in_contact_list { get; set; }

  private LoadableIcon? _avatar = null;

  /**
   * An avatar for the Persona.
   *
   * See {@link Folks.AvatarDetails.avatar}.
   *
   * @since 0.6.0
   */
  [CCode (notify = false)]
  public LoadableIcon? avatar
    {
      get { return this._avatar; }
      set { this.change_avatar.begin (value); } /* not writeable */
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
   */
  [CCode (notify = false)]
  public StructuredName? structured_name
    {
      get { return null; }
      set { this.change_structured_name.begin (value); } /* not writeable */
    }

  private string _full_name = ""; /* must never be null */

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
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
   * @since 0.6.4
   */
  public async void change_full_name (string full_name) throws PropertyError
    {
      var tpf_store = this.store as Tpf.PersonaStore;

      if (full_name == this._full_name)
        return;

      if (this._is_constructed)
        {
          try
            {
              yield tpf_store.change_user_full_name (this, full_name);
            }
          catch (PersonaStoreError.INVALID_ARGUMENT e1)
            {
              throw new PropertyError.NOT_WRITEABLE (e1.message);
            }
          catch (PersonaStoreError.STORE_OFFLINE e2)
            {
              throw new PropertyError.UNKNOWN_ERROR (e2.message);
            }
          catch (PersonaStoreError e3)
            {
              throw new PropertyError.UNKNOWN_ERROR (e3.message);
            }
        }

      /* the change will be notified when we receive changes to
       * contact.contact_info */
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
   */
  [CCode (notify = false)]
  public string nickname
    {
      get { return ""; }
      set { this.change_nickname.begin (value); } /* not writeable */
    }

  /**
   * {@inheritDoc}
   *
   * ContactInfo has no equivalent field, so this is unsupported.
   *
   * @since 0.6.4
   */
  [CCode (notify = false)]
  public string? calendar_event_id
    {
      get { return null; } /* unsupported */
      set { this.change_calendar_event_id.begin (value); } /* not writeable */
    }

  private DateTime? _birthday = null;
  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
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
   * @since 0.6.4
   */
  public async void change_birthday (DateTime? birthday) throws PropertyError
    {
      var tpf_store = this.store as Tpf.PersonaStore;

      if (birthday != null && this._birthday != null &&
          birthday.equal (this._birthday))
        {
          return;
        }

      if (this._is_constructed)
        {
          try
            {
              yield tpf_store.change_user_birthday (this, birthday);
            }
          catch (PersonaStoreError.INVALID_ARGUMENT e1)
            {
              throw new PropertyError.NOT_WRITEABLE (e1.message);
            }
          catch (PersonaStoreError.STORE_OFFLINE e2)
            {
              throw new PropertyError.UNKNOWN_ERROR (e2.message);
            }
          catch (PersonaStoreError e3)
            {
              throw new PropertyError.UNKNOWN_ERROR (e3.message);
            }
        }

      /* the change will be notified when we receive changes to
       * contact.contact_info */
    }

  /**
   * The Persona's presence type.
   *
   * See {@link Folks.PresenceDetails.presence_type}.
   */
  public Folks.PresenceType presence_type { get; set; }

  /**
   * The Persona's presence status.
   *
   * See {@link Folks.PresenceDetails.presence_status}.
   *
   * @since 0.6.0
   */
  public string presence_status { get; set; }

  /**
   * The Persona's presence message.
   *
   * See {@link Folks.PresenceDetails.presence_message}.
   */
  public string presence_message { get; set; }

  /**
   * The Persona's client types.
   *
   * See {@link Folks.PresenceDetails.client_types}.
   *
   * @since 0.9.5
   */
  public string[] client_types { get; set; }

  /**
   * The names of the Persona's linkable properties.
   *
   * See {@link Folks.Persona.linkable_properties}.
   */
  public override string[] linkable_properties
    {
      get { return Tpf.Persona._linkable_properties; }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public override string[] writeable_properties
    {
      get { return this._writeable_properties; }
    }

  private string _alias = ""; /* must never be null */

  /**
   * An alias for the Persona.
   *
   * See {@link Folks.AliasDetails.alias}.
   */
  [CCode (notify = false)]
  public string alias
    {
      get { return this._alias; }
      set { this.change_alias.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.2
   */
  public async void change_alias (string alias) throws PropertyError
    {
      if (this._alias == alias)
        {
          return;
        }

      if (this._is_constructed)
        {
          yield ((Tpf.PersonaStore) this.store).change_alias (this, alias);
        }

      /* The change will be notified when we receive changes from the store. */
    }

  private bool _is_favourite = false;

  /**
   * Whether this Persona is a user-defined favourite.
   *
   * See {@link Folks.FavouriteDetails.is_favourite}.
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
   * @since 0.6.2
   */
  public async void change_is_favourite (bool is_favourite) throws PropertyError
    {
      if (this._is_favourite == is_favourite)
        {
          return;
        }

      if (this._is_constructed)
        {
          yield ((Tpf.PersonaStore) this.store).change_is_favourite (this,
              is_favourite);
        }

      /* The change will be notified when we receive changes from the store. */
    }

  /* Note: Only ever called by Tpf.PersonaStore. */
  internal void _set_is_favourite (bool is_favourite)
    {
      if (this._is_favourite == is_favourite)
        {
          return;
        }

      this._is_favourite = is_favourite;
      this.notify_property ("is-favourite");

      /* Mark the cache as needing to be updated. */
      ((Tpf.PersonaStore) this.store)._set_cache_needs_update ();
    }

  private SmallSet<EmailFieldDetails>? _email_addresses = null;
  private Set<EmailFieldDetails>? _email_addresses_ro = null;

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
   */
  [CCode (notify = false)]
  public Set<EmailFieldDetails> email_addresses
    {
      get
        {
          this._contact_notify_contact_info (true, false);
          return this._email_addresses_ro;
        }
      set { this.change_email_addresses.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
   */
  public async void change_email_addresses (
      Set<EmailFieldDetails> email_addresses) throws PropertyError
    {
      yield this._change_details<EmailFieldDetails> (email_addresses,
          this._email_addresses, "email");
    }

  /* NOTE: Other properties support lazy initialisation, but im-addresses
   * doesn't as it's a linkable property, so always has to be loaded anyway. */
  private HashMultiMap<string, ImFieldDetails> _im_addresses =
      new HashMultiMap<string, ImFieldDetails> (null, null,
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);

  /**
   * A mapping of IM protocol to an (unordered) set of IM addresses.
   *
   * See {@link Folks.ImDetails.im_addresses}.
   */
  [CCode (notify = false)]
  public MultiMap<string, ImFieldDetails> im_addresses
    {
      get { return this._im_addresses; }
      set { this.change_im_addresses.begin (value); }
    }

  private uint _im_interaction_count = 0;

  /**
   * A counter for IM interactions (send/receive message) with the persona.
   *
   * See {@link Folks.InteractionDetails.im_interaction_count}
   *
   * @since 0.7.1
   */
  public uint im_interaction_count
    {
      get { return this._im_interaction_count; }
    }

  internal DateTime? _last_im_interaction_datetime = null;

  /**
   * The latest datetime for IM interactions (send/receive message) with the
   * persona.
   *
   * See {@link Folks.InteractionDetails.last_im_interaction_datetime}
   *
   * @since 0.7.1
   */
  public DateTime? last_im_interaction_datetime
    {
      get { return this._last_im_interaction_datetime; }
    }

  private uint _call_interaction_count = 0;

  /**
   * A counter for call interactions (only successful calls) with the persona.
   *
   * See {@link Folks.InteractionDetails.call_interaction_count}
   *
   * @since 0.7.1
   */
  public uint call_interaction_count
    {
      get { return this._call_interaction_count; }
    }

  internal DateTime? _last_call_interaction_datetime = null;

  /**
   * The latest datetime for call interactions (only successful calls) with the
   * persona.
   *
   * See {@link Folks.InteractionDetails.last_call_interaction_datetime}
   *
   * @since 0.7.1
   */
  public DateTime? last_call_interaction_datetime
    {
      get { return this._last_call_interaction_datetime; }
    }

  private SmallSet<string> _groups = new SmallSet<string> ();
  private Set<string> _groups_ro;

  /**
   * A set group IDs for the groups the contact is a member of.
   *
   * See {@link Folks.GroupDetails.groups}.
   */
  [CCode (notify = false)]
  public Set<string> groups
    {
      get { return this._groups_ro; }
      set { this.change_groups.begin (value); }
    }

  /**
   * Add or remove the Persona from the specified group.
   *
   * See {@link Folks.GroupDetails.change_group}.
   *
   * @throws Folks.PropertyError.UNKNOWN_ERROR if changing group membership
   * failed
   */
  public async void change_group (string group, bool is_member)
      throws GLib.Error
    {
      /* Ensure we have a strong ref to the contact for the duration of the
       * operation. */
      var contact = (Contact?) this._contact;

      if (contact == null)
        {
          /* The Tpf.Persona is being served out of the cache. */
          throw new PropertyError.UNAVAILABLE (
              _("Failed to change group membership: %s"),
              /* Translators: "account" refers to an instant messaging
               * account. */
              _("Account is offline."));
        }

      try
        {
          if (is_member && !this._groups.contains (group))
            {
              yield contact.add_to_group_async (group);
            }
          else if (!is_member && this._groups.contains (group))
            {
              yield contact.remove_from_group_async (group);
            }
        }
      catch (GLib.Error e)
        {
          throw new PropertyError.UNKNOWN_ERROR (
              /* Translators: the parameter is an error message. */
              _("Failed to change group membership: %s"), e.message);
        }

      /* The change will be notified when we receive changes from the store. */
    }

  /* Note: Only ever called as a result of signals from Telepathy. */
  private void _contact_groups_changed (string[] added, string[] removed)
    {
      var changed = false;

      foreach (var group in added)
        {
          if (this._groups.add (group) == true)
            {
              changed = true;
              this.group_changed (group, true);
            }
        }

      foreach (var group in removed)
        {
          if (this._groups.remove (group) == true)
            {
              changed = true;
              this.group_changed (group, false);
            }
        }

      /* Notify if anything changed. */
      if (changed == true)
        {
          this.notify_property ("groups");

          /* Mark the cache as needing to be updated. */
          ((Tpf.PersonaStore) this.store)._set_cache_needs_update ();
        }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.2
   */
  public async void change_groups (Set<string> groups) throws PropertyError
    {
      var contact = (Contact?) this._contact;

      if (contact == null)
        {
          /* The Tpf.Persona is being served out of the cache. */
          throw new PropertyError.UNAVAILABLE (
              _("Failed to change group membership: %s"),
              /* Translators: "account" refers to an instant messaging
               * account. */
              _("Account is offline."));
        }

      try
        {
          yield contact.set_contact_groups_async (groups.to_array ());
        }
      catch (GLib.Error e)
        {
          throw new PropertyError.UNKNOWN_ERROR (
              /* Translators: the parameter is an error message. */
              _("Failed to change group membership: %s"), e.message);
        }

      /* The change will be notified when we receive changes from the store. */
    }

  /* We handle the weak ref ourself to be able to notify the "contact" property.
   * It is TpfPersonaStore who weak_ref() the TpContact and calls
   * _contact_weak_notify() on the persona.
   *
   * This isn't as easy as it seems, see bgo#702165 */
  private unowned Contact? _contact;

  internal void _contact_weak_notify ()
    {
      if (this._contact == null)
        return;

      debug ("TpContact %p destroyed; setting ._contact = null in Persona %p",
          this._contact, this);

      this._contact = null;
      this.notify_property ("contact");
    }

  /**
   * The Telepathy contact represented by this persona.
   *
   * Note that this may be ``null`` if the {@link PersonaStore} providing this
   * {@link Persona} isn't currently available (e.g. due to not being connected
   * to the network). In this case, most other properties of the {@link Persona}
   * are being retrieved from a cache and may not be current (though there's no
   * way to tell this).
   */
  public Contact? contact
    {
      get
        {
          /* FIXME: This property should be changed to transfer its reference
           * when the API is next broken. This is necessary because the
           * TpfPersona doesn't hold a strong ref to the TpContact, so any
           * pointer which is returned might be invalidated before reaching the
           * caller. Probably not a problem in practice since folks won't be
           * run multi-threaded. */
          return this._contact;
        }

      construct
        {
          this._contact = value;
        }
    }

  private SmallSet<PhoneFieldDetails>? _phone_numbers = null;
  private Set<PhoneFieldDetails>? _phone_numbers_ro = null;

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
   */
  [CCode (notify = false)]
  public Set<PhoneFieldDetails> phone_numbers
    {
      get
        {
          this._contact_notify_contact_info (true, false);
          return this._phone_numbers_ro;
        }
      set { this.change_phone_numbers.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
   */
  public async void change_phone_numbers (
      Set<PhoneFieldDetails> phone_numbers) throws PropertyError
    {
      yield this._change_details<PhoneFieldDetails> (phone_numbers,
          this._phone_numbers, "tel");
    }

  private SmallSet<UrlFieldDetails>? _urls = null;
  private Set<UrlFieldDetails>? _urls_ro = null;

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
   */
  [CCode (notify = false)]
  public Set<UrlFieldDetails> urls
    {
      get
        {
          this._contact_notify_contact_info (true, false);
          return this._urls_ro;
        }
      set { this.change_urls.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.4
   */
  public async void change_urls (Set<UrlFieldDetails> urls) throws PropertyError
    {
      yield this._change_details<UrlFieldDetails> (urls,
          this._urls, "url");
    }

  private async void _change_details<T> (
      Set<AbstractFieldDetails<string>> details,
      Set<AbstractFieldDetails<string>>? member_set,
      string field_name)
        throws PropertyError
    {
      var tpf_store = this.store as Tpf.PersonaStore;

      if (member_set != null &&
          Folks.Internal.equal_sets<T> (details, member_set))
        {
          return;
        }

      if (this._is_constructed)
        {
          try
            {
              yield tpf_store._change_user_details (this, details, field_name);
            }
          catch (PersonaStoreError.INVALID_ARGUMENT e1)
            {
              throw new PropertyError.NOT_WRITEABLE (e1.message);
            }
          catch (PersonaStoreError.STORE_OFFLINE e2)
            {
              throw new PropertyError.UNKNOWN_ERROR (e2.message);
            }
          catch (PersonaStoreError e3)
            {
              throw new PropertyError.UNKNOWN_ERROR (e3.message);
            }
        }

      /* the change will be notified when we receive changes to
       * contact.contact_info */
    }

  /**
   * Create a new persona.
   *
   * Create a new persona for the {@link PersonaStore} ``store``, representing
   * the Telepathy contact given by ``contact``.
   *
   * @param contact the Telepathy contact being represented by the persona
   * @param store the persona store to place the persona in
   */
  public Persona (Contact contact, PersonaStore store)
    {
      unowned string id = contact.get_identifier ();
      var connection = contact.connection;
      var account = connection.get_account ();
      var uid = Folks.Persona.build_uid (store.type_id, store.id, id);
      var is_user = false;

      if (connection.self_contact != null)
        {
          is_user = (contact.handle == connection.self_contact.handle);
        }

      Object (contact: contact,
              display_id: id,
              /* FIXME: This IID format should be moved out to the ImDetails
               * interface along with the code in
               * Kf.Persona.linkable_property_to_links(), but that depends on
               * bgo#624842 being fixed. */
              iid: account.protocol_name + ":" + id,
              uid: uid,
              store: store,
              is_user: is_user);

      debug ("Created new Tpf.Persona '%s' for service-specific UID '%s': %p",
          uid, id, this);
    }

  construct
    {
      this._groups_ro = this._groups.read_only_view;

      /* Contact can be null if we've been created from the cache. All the code
       * below this point is for non-cached personas. */
      var contact = (Contact?) this._contact;

      if (contact == null)
        {
          return;
        }

      /* Set our alias. */
      this._alias = contact.get_alias ();

      contact.notify["alias"].connect ((s, p) =>
          {
            var c = (Contact?) this._contact;
            assert (c != null); /* should never be called while cached */

            /* Tp guarantees that aliases are always non-null. */
            assert (c.alias != null);

            if (this._alias != c.alias)
              {
                this._alias = c.alias;
                this.notify_property ("alias");

                /* Mark the cache as needing to be updated. */
                ((Tpf.PersonaStore) this.store)._set_cache_needs_update ();
              }
          });

      /* Set our single IM address */
      var connection = contact.connection;
      var account = connection.get_account ();

      try
        {
          var im_addr = ImDetails.normalise_im_address (this.display_id,
              account.protocol_name);
          var im_fd = new ImFieldDetails (im_addr);
          this._im_addresses.set (account.protocol_name, im_fd);
        }
      catch (ImDetailsError e)
        {
          /* This should never happen…but if it does, warn of it and continue */
          warning (e.message);
        }

      contact.notify["avatar-file"].connect ((s, p) =>
        {
          this._contact_notify_avatar ();
        });
      this._contact_notify_avatar ();

      contact.notify["presence-message"].connect ((s, p) =>
        {
          this._contact_notify_presence_message ();
        });
      contact.notify["presence-type"].connect ((s, p) =>
        {
          this._contact_notify_presence_type ();
        });
      contact.notify["presence-status"].connect ((s, p) =>
        {
          this._contact_notify_presence_status ();
        });
      contact.notify["client-types"].connect ((s, p) =>
        {
          this._contact_notify_client_types ();
        });

      this._contact_notify_presence_message ();
      this._contact_notify_presence_type ();
      this._contact_notify_presence_status ();
      this._contact_notify_client_types ();

      contact.notify["contact-info"].connect ((s, p) =>
        {
          this._contact_notify_contact_info (false);
        });
      this._contact_notify_contact_info (false);

      contact.contact_groups_changed.connect ((added, removed) =>
        {
          this._contact_groups_changed (added, removed);
        });
      this._contact_groups_changed (contact.get_contact_groups (), {});

      var tpf_store = this.store as Tpf.PersonaStore;

      if (this.is_user)
        {
          tpf_store.notify["supported-fields"].connect ((s, p) =>
            {
              this._update_writeable_properties ();
            });
        }

      tpf_store.notify["always-writeable-properties"].connect ((s, p) =>
        {
          this._update_writeable_properties ();
        });

      this._update_writeable_properties ();
    }

  /* Called after all construction-time properties have been set. */
  public override void constructed ()
    {
      this._is_constructed = true;
    }

  private void _update_writeable_properties ()
    {
      var tpf_store = this.store as Tpf.PersonaStore;
      this._writeable_properties = this.store.always_writeable_properties;

      if (this.is_user)
        {
          if ("bday" in tpf_store.supported_fields)
            this._writeable_properties += "birthday";
          if ("email" in tpf_store.supported_fields)
            this._writeable_properties += "email-addresses";
          if ("fn" in tpf_store.supported_fields)
            this._writeable_properties += "full-name";
          if ("tel" in tpf_store.supported_fields)
            this._writeable_properties += "phone-numbers";
          if ("url" in tpf_store.supported_fields)
            this._writeable_properties += "urls";
        }
    }

  private void _contact_notify_contact_info (bool create_if_not_exists, bool emit_notification = true)
    {
      assert ((
          (this._email_addresses == null) &&
          (this._phone_numbers == null) &&
          (this._urls == null)
        ) || (
          (this._email_addresses != null) &&
          (this._phone_numbers != null) &&
          (this._urls != null)
        ));

      /* See the comments in Folks.Individual about the lazy instantiation
       * strategy for URIs, etc.
       *
       * It's necessary to notify for all three properties here, as this
       * function is called identically for all of them. */
      if (this._urls == null && create_if_not_exists == false)
        {
          if (emit_notification)
            {
              this.notify_property ("email-addresses");
              this.notify_property ("phone-numbers");
              this.notify_property ("urls");
            }
          return;
        }
      else if (this._urls == null)
        {
          this._urls = new SmallSet<UrlFieldDetails> (
              AbstractFieldDetails<string>.hash_static,
              AbstractFieldDetails<string>.equal_static);
          this._urls_ro = this._urls.read_only_view;

          this._email_addresses = new SmallSet<EmailFieldDetails> (
              AbstractFieldDetails<string>.hash_static,
              AbstractFieldDetails<string>.equal_static);
          this._email_addresses_ro = this._email_addresses.read_only_view;

          this._phone_numbers = new SmallSet<PhoneFieldDetails> (
              AbstractFieldDetails<string>.hash_static,
              AbstractFieldDetails<string>.equal_static);
          this._phone_numbers_ro = this._phone_numbers.read_only_view;
        }

      var contact = (Contact?) this._contact;
      if (contact == null)
        {
          /* If operating from the cache, bail out early. */
          return;
        }

      var changed = false;
      var new_birthday_str = "";
      var new_full_name = "";
      var new_email_addresses = new SmallSet<EmailFieldDetails> (
          AbstractFieldDetails<string>.hash_static,
          AbstractFieldDetails<string>.equal_static);
      var new_phone_numbers = new SmallSet<PhoneFieldDetails> (
           AbstractFieldDetails<string>.hash_static,
           AbstractFieldDetails<string>.equal_static);
      var new_urls = new SmallSet<UrlFieldDetails> (
           AbstractFieldDetails<string>.hash_static,
           AbstractFieldDetails<string>.equal_static);

      var contact_info = contact.dup_contact_info ();
      foreach (var info in contact_info)
        {
          if (info.field_name == "") {}
          else if (info.field_name == "bday")
            {
              new_birthday_str = info.field_value[0] ?? "";
            }
          else if (info.field_name == "email")
            {
              foreach (var email_addr in info.field_value)
                {
                  if (email_addr != "")
                    {
                      var parameters = this._afd_params_from_strv (info.parameters);
                      var email_fd = new EmailFieldDetails (email_addr, parameters);
                      new_email_addresses.add (email_fd);
                    }
                }
            }
          else if (info.field_name == "fn")
            {
              new_full_name = info.field_value[0];
              if (new_full_name == null)
                new_full_name = "";
            }
          else if (info.field_name == "tel")
            {
              foreach (var phone_num in info.field_value)
                {
                  if (phone_num != "")
                    {
                      var parameters = this._afd_params_from_strv (info.parameters);
                      var phone_fd = new PhoneFieldDetails (phone_num, parameters);
                      new_phone_numbers.add (phone_fd);
                    }
                }
            }
          else if (info.field_name == "url")
            {
              foreach (var url in info.field_value)
                {
                  if (url != "")
                    {
                      var parameters = this._afd_params_from_strv (info.parameters);
                      var url_fd = new UrlFieldDetails (url, parameters);
                      new_urls.add (url_fd);
                    }
                }
            }
        }

      if (new_birthday_str != "")
        {
          var timeval = TimeVal ();
          if (timeval.from_iso8601 (new_birthday_str))
            {
              var d = new DateTime.from_timeval_utc (timeval);

              /* d might be null if their birthday in Telepathy is something
               * that doesn't make sense, like 31st February. If so, ignore
               * it. */
              if (d != null && (this._birthday == null ||
                   (this._birthday != null &&
                     !this._birthday.equal (d.to_utc ()))))
                {
                  this._birthday = d.to_utc ();
                  if (emit_notification)
                    {
                      this.notify_property ("birthday");
                    }
                  changed = true;
                }
            }
          else
            {
              debug ("Failed to parse new birthday string '%s'",
                  new_birthday_str);
            }
        }
      else
        {
          if (this._birthday != null)
            {
              this._birthday = null;
              if (emit_notification)
                {
                  this.notify_property ("birthday");
                }
              changed = true;
            }
        }

      if (!Folks.Internal.equal_sets<EmailFieldDetails> (new_email_addresses,
              this._email_addresses))
        {
          this._email_addresses = new_email_addresses;
          this._email_addresses_ro = new_email_addresses.read_only_view;
          if (emit_notification)
            {
              this.notify_property ("email-addresses");
            }
          changed = true;
        }

      if (new_full_name != this._full_name)
        {
          this._full_name = new_full_name;
          this.notify_property ("full-name");
          changed = true;
        }

      if (!Utils.set_string_afd_equal (new_phone_numbers,
              this._phone_numbers))
        {
          this._phone_numbers = new_phone_numbers;
          this._phone_numbers_ro = new_phone_numbers.read_only_view;
          if (emit_notification)
            {
              this.notify_property ("phone-numbers");
            }
          changed = true;
        }

      if (!Folks.Internal.equal_sets<UrlFieldDetails> (new_urls, this._urls))
        {
          this._urls = new_urls;
          this._urls_ro = new_urls.read_only_view;
          this.notify_property ("urls");
          changed = true;
        }

      if (changed == true)
        {
          /* Mark the cache as needing to be updated. */
          ((Tpf.PersonaStore) this.store)._set_cache_needs_update ();
        }
    }

  private MultiMap<string, string> _afd_params_from_strv (string[] parameters)
    {
      var retval = new HashMultiMap<string, string> ();

      foreach (var entry in parameters)
        {
          var tokens = entry.split ("=", 2);
          if (tokens.length == 2)
            {
              retval.set (tokens[0], tokens[1]);
            }
          else
            {
              warning ("Failed to parse vCard parameter from string '%s'",
                  entry);
            }
        }

      return retval;
    }

  /**
   * Create a new persona for the {@link PersonaStore} ``store``, representing
   * a cached contact for which we currently have no Telepathy contact.
   *
   * @param store The persona store to place the persona in.
   * @param uid The cached UID of the persona.
   * @param iid The cached IID of the persona.
   * @param im_address The cached IM address of the persona (excluding
   * protocol).
   * @param protocol The cached protocol of the persona.
   * @param groups The cached set of groups the persona is in.
   * @param is_favourite Whether the persona is a favourite.
   * @param alias The cached alias for the persona.
   * @param is_in_contact_list Whether the persona is in the user's contact
   * list.
   * @param is_user Whether the persona is the user.
   * @param avatar The icon for the persona's cached avatar, or ``null`` if they
   * have no avatar.
   * @param birthday The date/time of birth of the persona, or ``null`` if it's
   * unknown.
   * @param full_name The persona's full name, or the empty string if it's
   * unknown.
   * @param email_addresses A set of the persona's e-mail addresses, which may
   * be empty (but may not be ``null``).
   * @param phone_numbers A set of the persona's phone numbers, which may be
   * empty (but may not be ``null``).
   * @param urls A set of the persona's URLs, which may be empty (but may not be
   * ``null``).
   * @return A new {@link Tpf.Persona} representing the cached persona.
   *
   * @since 0.6.0
   */
  internal Persona.from_cache (PersonaStore store, string uid, string iid,
      string im_address, string protocol, SmallSet<string> groups,
      bool is_favourite, string alias, bool is_in_contact_list, bool is_user,
      LoadableIcon? avatar, DateTime? birthday, string full_name,
      SmallSet<EmailFieldDetails> email_addresses,
      SmallSet<PhoneFieldDetails> phone_numbers, SmallSet<UrlFieldDetails> urls)
    {
      Object (contact: null,
              display_id: im_address,
              iid: iid,
              uid: uid,
              store: store,
              is_user: is_user);

      debug ("Created new Tpf.Persona '%s' from cache: %p", uid, this);

      // IM addresses
      var im_fd = new ImFieldDetails (im_address);
      this._im_addresses.set (protocol, im_fd);

      // Groups
      this._groups = groups;
      this._groups_ro = this._groups.read_only_view;

      // E-mail addresses
      this._email_addresses = email_addresses;
      this._email_addresses_ro = this._email_addresses.read_only_view;

      // Phone numbers
      this._phone_numbers = phone_numbers;
      this._phone_numbers_ro = this._phone_numbers.read_only_view;

      // URLs
      this._urls = urls;
      this._urls_ro = this._urls.read_only_view;

      // Other properties
      if (alias == null)
        {
          /* Deal with badly-behaved callers */
          alias = "";
        }

      if (full_name == null)
        {
          /* Deal with badly-behaved callers */
          full_name = "";
        }

      this._alias = alias;
      this._is_favourite = is_favourite;
      this.is_in_contact_list = is_in_contact_list;
      this._birthday = birthday;
      this._full_name = full_name;

      // Avatars
      this._avatar = avatar;
      var avatar_file =
          (avatar != null) ? ((FileIcon) avatar).get_file () : null;
      ((Tpf.PersonaStore) store)._update_avatar_cache (iid, avatar_file);

      // Make the persona appear offline
      this.presence_type = PresenceType.OFFLINE;
      this.presence_message = "";
      this.presence_status = "offline";
      this.client_types = {};

      this._writeable_properties = {};
    }

  ~Persona ()
    {
      debug ("Destroying Tpf.Persona '%s': %p", this.uid, this);
    }

  private void _contact_notify_presence_message ()
    {
      var contact = (Contact?) this._contact;
      assert (contact != null); /* should never be called while cached */
      this.presence_message = contact.get_presence_message ();
    }

  private void _contact_notify_presence_type ()
    {
      var contact = (Contact?) this._contact;
      assert (contact != null); /* should never be called while cached */
      this.presence_type = Tpf.Persona._folks_presence_type_from_tp (
          contact.get_presence_type ());
    }

  private void _contact_notify_client_types ()
    {
      var contact = (Contact?) this._contact;
      assert (contact != null); /* should never be called while cached */
      this.client_types = contact.get_client_types ();
    }

  private void _contact_notify_presence_status ()
    {
      var contact = (Contact?) this._contact;
      assert (contact != null); /* should never be called while cached */
      this.presence_status = contact.get_presence_status ();
    }

  private static PresenceType _folks_presence_type_from_tp (
      TelepathyGLib.ConnectionPresenceType type)
    {
      switch (type)
        {
          case TelepathyGLib.ConnectionPresenceType.AVAILABLE:
            return PresenceType.AVAILABLE;
          case TelepathyGLib.ConnectionPresenceType.AWAY:
            return PresenceType.AWAY;
          case TelepathyGLib.ConnectionPresenceType.BUSY:
            return PresenceType.BUSY;
          case TelepathyGLib.ConnectionPresenceType.ERROR:
            return PresenceType.ERROR;
          case TelepathyGLib.ConnectionPresenceType.EXTENDED_AWAY:
            return PresenceType.EXTENDED_AWAY;
          case TelepathyGLib.ConnectionPresenceType.HIDDEN:
            return PresenceType.HIDDEN;
          case TelepathyGLib.ConnectionPresenceType.OFFLINE:
            return PresenceType.OFFLINE;
          case TelepathyGLib.ConnectionPresenceType.UNKNOWN:
            return PresenceType.UNKNOWN;
          case TelepathyGLib.ConnectionPresenceType.UNSET:
            return PresenceType.UNSET;
          default:
            return PresenceType.UNKNOWN;
        }
    }

  private void _contact_notify_avatar ()
    {
      var contact = (Contact?) this._contact;
      assert (contact != null); /* should never be called while cached */

      var file = contact.avatar_file;
      var token = contact.avatar_token;
      Icon? icon = null;
      var from_cache = false;

      /* Handle all the different cases of avatars. */
      if (token == "")
        {
          /* Definitely know there's no avatar. */
          file = null;
          from_cache = false;
        }
      else if (token != null && file != null)
        {
          /* Definitely know there's some avatar, so leave the file alone. */
          from_cache = false;
        }
      else
        {
          /* Not sure about the avatar; fall back to any cached avatar. */
          file = ((Tpf.PersonaStore) this.store)._query_avatar_cache (this.iid);
          from_cache = true;
        }

      if (file != null)
        {
          icon = new FileIcon (file);
        }

      if ((this._avatar == null) != (icon == null) || !this._avatar.equal (icon))
        {
          this._avatar = (LoadableIcon) icon;
          this.notify_property ("avatar");

          if (from_cache == false)
            {
              /* Mark the persona cache as needing to be updated. */
              ((Tpf.PersonaStore) this.store)._set_cache_needs_update ();

              /* Update the avatar cache. */
              ((Tpf.PersonaStore) this.store)._update_avatar_cache (this.iid,
                  file);
            }
        }
    }

  /**
   * Look up a {@link Tpf.Persona} by its {@link TelepathyGLib.Contact}.
   *
   * If the {@link TelepathyGLib.Account} for the contact's
   * {@link TelepathyGLib.Connection} is ``null``, or if a
   * {@link Tpf.PersonaStore} can't be found for that account, ``null`` will be
   * returned. Otherwise, if a {@link Tpf.Persona} already exists for the given
   * contact, that will be returned; if one doesn't exist a new one will be
   * created and returned. In this case, the {@link Tpf.Persona} will be added
   * to the {@link PersonaStore} associated with the account, and will be
   * removed when ``contact`` is destroyed.
   *
   * @param contact the Telepathy contact of the persona
   * @return the persona associated with the contact, or ``null``
   * @since 0.6.6
   */
  public static Persona? dup_for_contact (Contact contact)
    {
      var account = contact.connection.get_account ();

      debug ("Tpf.Persona.dup_for_contact (%p): got account %p", contact,
          account);

      /* Account could be null; see the docs for tp_connection_get_account(). */
      if (account == null)
        {
          return null;
        }

      var store = PersonaStore.dup_for_account (account);
      return store._ensure_persona_for_contact (contact);
    }

  internal void _increase_im_interaction_counter (DateTime converted_datetime)
    {
      this._im_interaction_count++;
      this.notify_property ("im-interaction-count");
      if (this._last_im_interaction_datetime == null ||
          this._last_im_interaction_datetime.compare (converted_datetime) == -1)
        {
          this._last_im_interaction_datetime = converted_datetime;
          this.notify_property ("last-im-interaction-datetime");
        }
      debug ("Persona %s IM interaction details changed:\n" +
          " - count: %u \n - timestamp: %lld",
          this.iid, this._im_interaction_count,
          this._last_im_interaction_datetime.format ("%H %M %S - %d %m %y"));
    }

  internal void _increase_last_call_interaction_counter (DateTime converted_datetime)
    {
      this._call_interaction_count++;
      this.notify_property ("call-interaction-count");
      if (this._last_call_interaction_datetime == null ||
          this._last_call_interaction_datetime.compare (converted_datetime) == -1)
        {
          this._last_call_interaction_datetime = converted_datetime;
          this.notify_property ("last-call-interaction-datetime");
        }
      debug ("Persona %s Call interaction details changed:\n" +
          " - count: %u \n - timestamp: %lld",
          this.iid, this._call_interaction_count,
          this._last_call_interaction_datetime.format ("%H %M %S - %d %m %y"));
    }
}
