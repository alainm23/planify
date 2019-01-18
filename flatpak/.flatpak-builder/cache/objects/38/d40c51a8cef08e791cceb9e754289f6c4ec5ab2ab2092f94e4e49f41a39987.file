/*
 * Copyright (C) 2010, 2015 Collabora Ltd.
 * Copyright (C) 2011, 2013 Philip Withnall
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

/**
 * Trust level for an {@link Individual} for use in the UI.
 *
 * @since 0.1.15
 */
public enum Folks.TrustLevel
{
  /**
   * The {@link Individual}'s {@link Persona}s aren't trusted at all.
   *
   * This is the trust level for an {@link Individual} which contains one or
   * more {@link Persona}s which cannot be guaranteed to be the same
   * {@link Persona}s as were originally linked together.
   *
   * For example, an {@link Individual} containing a link-local XMPP
   * {@link Persona} would have this trust level, since someone else could
   * easily spoof the link-local XMPP {@link Persona}'s identity.
   *
   * @since 0.1.15
   */
  NONE,

  /**
   * The {@link Individual}'s {@link Persona}s are trusted.
   *
   * This trust level is for {@link Individual}s where it can be guaranteed
   * that all the {@link Persona}s are the same ones as when they were
   * originally linked together.
   *
   * Note that this doesn't guarantee that the user who behind each
   * {@link Persona} is who they claim to be.
   *
   * @since 0.1.15
   */
  PERSONAS
}

/**
 * A physical person, aggregated from the various {@link Persona}s the person
 * might have, such as their different IM addresses or vCard entries. An
 * individual must always contain at least one {@link Persona}.
 *
 * When choosing the values of single-valued properties (such as
 * {@link Individual.alias} and {@link Individual.avatar}; but not multi-valued
 * properties such as {@link Individual.groups} and
 * {@link Individual.im_addresses}) from the {@link Persona}s in the
 * individual to present as the values of those properties of the individual,
 * it is guaranteed that if the individual contains a persona from the primary
 * persona store (see {@link IndividualAggregator.primary_store}), its property
 * values will be chosen above all others. This means that any changes to
 * property values made through folks (which are normally written to the primary
 * store) will always be used by {@link Folks.Individual}s.
 *
 * No further guarantees are made about the order of preference used for
 * choosing which property values to use for the {@link Folks.Individual}, other
 * than that the order may vary between properties, but is guaranteed to be
 * stable for a given property.
 */
public class Folks.Individual : Object,
    AliasDetails,
    AvatarDetails,
    BirthdayDetails,
    EmailDetails,
    ExtendedInfo,
    FavouriteDetails,
    GenderDetails,
    GroupDetails,
    ImDetails,
    InteractionDetails,
    LocalIdDetails,
    LocationDetails,
    NameDetails,
    NoteDetails,
    PresenceDetails,
    PhoneDetails,
    PostalAddressDetails,
    RoleDetails,
    UrlDetails,
    WebServiceDetails
{
  /* Stores the Personas contained in this Individual. */
  private SmallSet<Persona> _persona_set = new SmallSet<Persona> ();
  /* Read-only view of the above set */
  private Set<Persona> _persona_set_ro;
  /* Mapping from PersonaStore -> number of Personas from that store contained
   * in this Individual. There shouldn't be any entries with a number < 1.
   * This is used for working out when to disconnect from store signals. */
  private HashMap<unowned PersonaStore, uint> _stores =
      new HashMap<unowned PersonaStore, uint> (null, null);
  /* The number of Personas in this Individual which have
   * Persona.is_user == true. Iff this is > 0, Individual.is_user == true. */
  private uint _persona_user_count = 0;

  /**
   * The trust level of the Individual.
   *
   * This specifies how far the Individual can be trusted to be who it claims
   * to be. See the descriptions for the elements of {@link TrustLevel}.
   *
   * Clients should ''not'' allow linking of Individuals who have a trust level
   * of {@link TrustLevel.NONE}.
   *
   * @since 0.1.15
   */
  public TrustLevel trust_level { get; private set; }

  private LoadableIcon? _avatar = null;

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  [CCode (notify = false)]
  public LoadableIcon? avatar
    {
      get { return this._avatar; }
      set { this.change_avatar.begin (value); } /* not writeable */
    }

  /*
   * Change the individual's avatar.
   *
   * It's preferred to call this rather than setting {@link Individual.avatar}
   * directly, as this method gives error notification and will only return once
   * the avatar has been written to the relevant backing stores (or the
   * operation's failed).
   *
   * Setting this property is only guaranteed to succeed (and be written to
   * the backing store) if
   * {@link IndividualAggregator.ensure_individual_property_writeable} has been
   * called successfully on the individual for the property name ``avatar``.
   *
   * @param avatar the new avatar (or ``null`` to unset the avatar)
   * @throws PropertyError if setting the avatar failed
   * @since 0.6.3
   */
  public async void change_avatar (LoadableIcon? avatar) throws PropertyError
    {
      /* FIXME: Once https://bugzilla.gnome.org/show_bug.cgi?id=604827 is fixed,
       * this should be rewritten to use async delegates passed to a generic
       * _change_single_valued_property() method. */
      if ((this._avatar != null && ((!) this._avatar).equal (avatar)) ||
          (this._avatar == null && avatar == null))
        {
          return;
        }

      debug ("Setting avatar of individual '%s' to '%p'…", this.id, avatar);

      PropertyError? persona_error = null;
      var prop_changed = false;

      /* Try to write it to only the writeable Personas which have the
       * "avatar" property as writeable. */
      foreach (var p in this._persona_set)
        {
          var _a = p as AvatarDetails;
          if (_a == null)
            {
              continue;
            }
          var a = (!) _a;

          if ("avatar" in p.writeable_properties)
            {
              try
                {
                  yield a.change_avatar (avatar);
                  debug ("    written to writeable persona '%s'", p.uid);
                  prop_changed = true;
                }
              catch (PropertyError e)
                {
                  /* Store the first error so we can throw it if setting the
                   * avatar fails on every other persona. */
                  if (persona_error == null)
                    {
                      persona_error = e;
                    }
                }
            }
        }

      /* Failure? Changing the property failed on every suitable persona found
       * (and potentially zero suitable personas were found). */
      if (prop_changed == false)
        {
          if (persona_error == null)
            {
              persona_error = new PropertyError.NOT_WRITEABLE (
                  _("Failed to change property ‘%s’: No suitable personas were found."),
                  "avatar");
            }

          throw persona_error;
        }
    }

  /**
   * {@inheritDoc}
   */
  public Folks.PresenceType presence_type { get; set; }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public string presence_status { get; set; default = ""; }

  /**
   * {@inheritDoc}
   */
  public string presence_message { get; set; default = ""; }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.5
   */
  public string[] client_types { get; set; }

  /**
   * Whether the Individual is the user.
   *
   * Iff the Individual represents the user – the person who owns the
   * account in the backend for each {@link Persona} in the Individual –
   * this is ``true``.
   *
   * It is //not// guaranteed that every {@link Persona} in the Individual has
   * its {@link Persona.is_user} set to the same value as the Individual. For
   * example, the user could own two Telepathy accounts, and have added the
   * other account as a contact in each account. The accounts will expose a
   * {@link Persona} for the user (which will have {@link Persona.is_user} set
   * to ``true``) //and// a {@link Persona} for the contact for the other
   * account (which will have {@link Persona.is_user} set to ``false``).
   *
   * It is guaranteed that iff this property is set to ``true`` on an
   * Individual, there will be at least one {@link Persona} in the Individual
   * with its {@link Persona.is_user} set to ``true``.
   *
   * It is guaranteed that there will only ever be one Individual with this
   * property set to ``true``.
   *
   * @since 0.3.0
   */
  public bool is_user { get; private set; }

  /**
   * A unique identifier for the Individual.
   *
   * This uniquely identifies the Individual, and persists across
   * {@link IndividualAggregator} instances. It may not persist across linking
   * the Individual with other Individuals.
   *
   * This is an opaque string and has no structure.
   *
   * If an identifier is required which will be used for a long-lived link
   * between different stored data, it may be more desirable to use the
   * {@link Persona.uid} of the most relevant {@link Persona} in the Individual
   * instead. For example, if storing references to Individuals who are tagged
   * in a photo, it may be safer to store the UID of the Persona whose backend
   * provided the photo (e.g. Facebook).
   *
   * As a special case, the ID defaults to an empty string when the individual
   * has no personas (i.e. if it’s just been constructed).
   */
  public string id { get; private set; default = ""; }

  /**
   * Emitted when the last of the Individual's {@link Persona}s has been
   * removed.
   *
   * At this point, the Individual is invalid, so any client referencing it
   * should unreference it and remove it from their UI.
   *
   * @param replacement_individual the individual which has replaced this one
   * due to linking, or ``null`` if this individual was removed for another
   * reason
   * @since 0.1.13
   */
  public signal void removed (Individual? replacement_individual);

  private string _display_name = "";

  /**
   * The name of this Individual to display in the UI.
   *
   * This value is set according to the following list of possibilities, each
   * one being tried first on the primary persona, then on all other personas in
   * the Individual, before falling back to the next item on the list:
   * # Alias
   * # Full name, structured name or nickname
   * # E-mail address
   * # Phone number
   * # Display ID (e.g. foo@example.org)
   * # Postal address
   * # _("Unnamed Person")
   *
   * @since 0.9.7
   */
  [CCode (notify = false)]
  public string display_name
    {
      get { return this._display_name; }
    }

  private string _alias = "";

  /**
   * {@inheritDoc}
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
      /* FIXME: Once https://bugzilla.gnome.org/show_bug.cgi?id=604827 is fixed,
       * this should be rewritten to use async delegates passed to a generic
       * _change_single_valued_property() method. */
      if (this._alias == alias)
        {
          return;
        }

      debug ("Setting alias of individual '%s' to '%s'…", this.id, alias);

      PropertyError? persona_error = null;
      var prop_changed = false;

      /* Try to write it to only the writeable Personas which have "alias"
       * as a writeable property. */
      foreach (var p in this._persona_set)
        {
          var _a = p as AliasDetails;
          if (_a == null)
            {
              continue;
            }
          var a = (!) _a;

          if ("alias" in p.writeable_properties)
            {
              try
                {
                  yield a.change_alias (alias);
                  debug ("    written to writeable persona '%s'", p.uid);
                  prop_changed = true;
                }
              catch (PropertyError e)
                {
                  /* Store the first error so we can throw it if setting the
                   * alias fails on every other persona. */
                  if (persona_error == null)
                    {
                      persona_error = e;
                    }
                }
            }
        }

      /* Failure? Changing the property failed on every suitable persona found
       * (and potentially zero suitable personas were found). */
      if (prop_changed == false)
        {
          if (persona_error == null)
            {
              persona_error = new PropertyError.NOT_WRITEABLE (
                  _("Failed to change property ‘%s’: No suitable personas were found."),
                  "alias");
            }

          throw persona_error;
        }
    }

  private StructuredName? _structured_name = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public StructuredName? structured_name
    {
      get { return this._structured_name; }
      set { this.change_structured_name.begin (value); } /* not writeable */
    }

  private string _full_name = "";

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public string full_name
    {
      get { return this._full_name; }
      set { this.change_full_name.begin (value); } /* not writeable */
    }

  private string _nickname = "";

  /**
   * {@inheritDoc}
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
   * @since 0.6.2
   */
  public async void change_nickname (string nickname) throws PropertyError
    {
      /* FIXME: Once https://bugzilla.gnome.org/show_bug.cgi?id=604827 is fixed,
       * this should be rewritten to use async delegates passed to a generic
       * _change_single_valued_property() method. */

      // Normalise null values to the empty string
      if (nickname == null)
        {
          nickname = "";
        }

      if (this._nickname == nickname)
        {
          return;
        }

      debug ("Setting nickname of individual '%s' to '%s'…", this.id, nickname);

      PropertyError? persona_error = null;
      var prop_changed = false;

      /* Try to write it to only the writeable Personas which have "nickname"
       * as a writeable property. */
      foreach (var p in this._persona_set)
        {
          var _n = p as NameDetails;
          if (_n == null)
            {
              continue;
            }
          var n = (!) _n;

          if ("nickname" in p.writeable_properties)
            {
              try
                {
                  yield n.change_nickname (nickname);
                  debug ("    written to writeable persona '%s'", p.uid);
                  prop_changed = true;
                }
              catch (PropertyError e)
                {
                  /* Store the first error so we can throw it if setting the
                   * nickname fails on every other persona. */
                  if (persona_error == null)
                    {
                      persona_error = e;
                    }
                }
            }
        }

      /* Failure? Changing the property failed on every suitable persona found
       * (and potentially zero suitable personas were found). */
      if (prop_changed == false)
        {
          if (persona_error == null)
            {
              persona_error = new PropertyError.NOT_WRITEABLE (
                  _("Failed to change property ‘%s’: No suitable personas were found."),
                  "nickname");
            }

          throw persona_error;
        }
    }

  private Gender _gender = Gender.UNSPECIFIED;
  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Gender gender
    {
      get { return this._gender; }
      set { this.change_gender.begin (value); } /* not writeable */
    }

  private SmallSet<UrlFieldDetails>? _urls = null;
  private Set<UrlFieldDetails>? _urls_ro = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Set<UrlFieldDetails> urls
    {
      get
        {
          this._update_urls (true, false, false);
          return this._urls_ro;
        }
      set { this.change_urls.begin (value); } /* not writeable */
    }

  private SmallSet<PhoneFieldDetails>? _phone_numbers = null;
  private Set<PhoneFieldDetails>? _phone_numbers_ro = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Set<PhoneFieldDetails> phone_numbers
    {
      get
        {
          this._update_phone_numbers (true, false, false);
          return this._phone_numbers_ro;
        }
      set { this.change_phone_numbers.begin (value); } /* not writeable */
    }

  private SmallSet<EmailFieldDetails>? _email_addresses = null;
  private Set<EmailFieldDetails>? _email_addresses_ro = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Set<EmailFieldDetails> email_addresses
    {
      get
        {
          this._update_email_addresses (true, false, false);
          return this._email_addresses_ro;
        }
      set { this.change_email_addresses.begin (value); } /* not writeable */
    }

  private SmallSet<RoleFieldDetails>? _roles = null;
  private Set<RoleFieldDetails>? _roles_ro = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Set<RoleFieldDetails> roles
    {
      get
        {
          this._update_roles (true, false, false);
          return this._roles_ro;
        }
      set { this.change_roles.begin (value); } /* not writeable */
    }

  private SmallSet<string>? _local_ids = null;
  private Set<string>? _local_ids_ro = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Set<string> local_ids
    {
      get
        {
          this._update_local_ids (true, false, false);
          return this._local_ids_ro;
        }
      set { this.change_local_ids.begin (value); } /* not writeable */
    }

  private Location? _location = null;
  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Location? location
    {
      get { return this._location; }
      set { this.change_location.begin (value); } /* not writeable */
    }

  private DateTime? _birthday = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public DateTime? birthday
    {
      get { return this._birthday; }
      set { this.change_birthday.begin (value); } /* not writeable */
    }

  private string? _calendar_event_id = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public string? calendar_event_id
    {
      get { return this._calendar_event_id; }
      set { this.change_calendar_event_id.begin (value); } /* not writeable */
    }

  private SmallSet<NoteFieldDetails>? _notes = null;
  private Set<NoteFieldDetails>? _notes_ro = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Set<NoteFieldDetails> notes
    {
      get
        {
          this._update_notes (true, false, false);
          return this._notes_ro;
        }
      set { this.change_notes.begin (value); } /* not writeable */
    }

  private SmallSet<PostalAddressFieldDetails>? _postal_addresses = null;
  private Set<PostalAddressFieldDetails>? _postal_addresses_ro = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Set<PostalAddressFieldDetails> postal_addresses
    {
      get
        {
          this._update_postal_addresses (true, false, false);
          return this._postal_addresses_ro;
        }
      set { this.change_postal_addresses.begin (value); } /* not writeable */
    }

  private bool _is_favourite = false;

  /**
   * Whether this Individual is a user-defined favourite.
   *
   * This property is ``true`` if any of this Individual's {@link Persona}s are
   * favourites).
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
      /* FIXME: Once https://bugzilla.gnome.org/show_bug.cgi?id=604827 is fixed,
       * this should be rewritten to use async delegates passed to a generic
       * _change_single_valued_property() method. */
      if (this._is_favourite == is_favourite)
        {
          return;
        }

      debug ("Setting '%s' favourite status to %s…", this.id,
        is_favourite ? "TRUE" : "FALSE");

      PropertyError? persona_error = null;
      var prop_changed = false;

      /* Try to write it to only the Personas which have "is-favourite" as a
       * writeable property.
       *
       * NOTE: We don't check whether the persona's store is writeable, as we
       * want is-favourite status to propagate to all stores, if possible. This
       * is one property which is harmless to propagate. */
      foreach (var p in this._persona_set)
        {
          var _a = p as FavouriteDetails;
          if (_a == null)
            {
              continue;
            }
          var a = (!) _a;

          if ("is-favourite" in p.writeable_properties)
            {
              try
                {
                  yield a.change_is_favourite (is_favourite);
                  debug ("    written to persona '%s'", p.uid);
                  prop_changed = true;
                }
              catch (PropertyError e)
                {
                  /* Store the first error so we can throw it if setting the
                   * property fails on every other persona. */
                  if (persona_error == null)
                    {
                      persona_error = e;
                    }
                }
            }
        }

      /* Failure? Changing the property failed on every suitable persona found
       * (and potentially zero suitable personas were found). */
      if (prop_changed == false)
        {
          if (persona_error == null)
            {
              persona_error = new PropertyError.NOT_WRITEABLE (
                  _("Failed to change property ‘%s’: No suitable personas were found."),
                  "is-favourite");
            }

          throw persona_error;
        }
    }

  private SmallSet<string>? _groups = null;
  private Set<string>? _groups_ro = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public Set<string> groups
    {
      get
        {
          this._update_groups (true, false, false);
          return this._groups_ro;
        }
      set { this.change_groups.begin (value); }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.2
   */
  public async void change_groups (Set<string> groups) throws PropertyError
    {
      /* FIXME: Once https://bugzilla.gnome.org/show_bug.cgi?id=604827 is fixed,
       * this should be rewritten to use async delegates passed to a generic
       * _change_single_valued_property() method. */
      debug ("Setting '%s' groups…", this.id);

      PropertyError? persona_error = null;
      var prop_changed = false;

      /* Try to write it to only the Personas which have "groups" as a
       * writeable property. */
      foreach (var p in this._persona_set)
        {
          var _g = p as GroupDetails;
          if (_g == null)
            {
              continue;
            }
          var g = (!) _g;

          if ("groups" in p.writeable_properties)
            {
              try
                {
                  yield g.change_groups (groups);
                  debug ("    written to persona '%s'", p.uid);
                  prop_changed = true;
                }
              catch (PropertyError e)
                {
                  /* Store the first error so we can throw it if setting the
                   * property fails on every other persona. */
                  if (persona_error == null)
                    {
                      persona_error = e;
                    }
                }
            }
        }

      /* Failure? Changing the property failed on every suitable persona found
       * (and potentially zero suitable personas were found). */
      if (prop_changed == false)
        {
          if (persona_error == null)
            {
              persona_error = new PropertyError.NOT_WRITEABLE (
                  _("Failed to change property ‘%s’: No suitable personas were found."),
                  "groups");
            }

          throw persona_error;
        }
    }

  private HashMultiMap<string, ImFieldDetails>? _im_addresses = null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public MultiMap<string, ImFieldDetails> im_addresses
    {
      get
        {
          this._update_im_addresses (true, false, false);
          return this._im_addresses;
        }
      set { this.change_im_addresses.begin (value); } /* not writeable */
    }

  private HashMultiMap<string, WebServiceFieldDetails>? _web_service_addresses =
      null;

  /**
   * {@inheritDoc}
   */
  [CCode (notify = false)]
  public MultiMap<string, WebServiceFieldDetails> web_service_addresses
    {
      get
        {
          this._update_web_service_addresses (true, false, false);
          return this._web_service_addresses;
        }
      /* Not writeable: */
      set { this.change_web_service_addresses.begin (value); }
    }

  /**
   * {@inheritDoc}
   */
  public uint im_interaction_count
    {
      get
        {
          uint counter = 0;
          /* Iterate over all personas and sum up their IM interaction counts*/
          foreach (var persona in this._persona_set)
            {
              var my_interaction_details = persona as InteractionDetails;
              if (my_interaction_details != null)
                {
                  counter = counter + my_interaction_details.im_interaction_count;
                }
            }
          return counter;
        }
    }

  /**
   * {@inheritDoc}
   */
  private DateTime? _last_im_interaction_datetime = null;

  public DateTime? last_im_interaction_datetime
    {
      get
        {
          if (this._last_im_interaction_datetime == null)
            {
              /* Iterate over all personas and get the latest IM interaction datetime */
              foreach (var persona in this._persona_set)
                {
                  var my_interaction_details = persona as InteractionDetails;
                  if (my_interaction_details != null &&
                      my_interaction_details.last_im_interaction_datetime != null)
                    {
                      DateTime interaction_datetime = my_interaction_details.last_im_interaction_datetime;
                      if (this._last_im_interaction_datetime == null ||
                          interaction_datetime.compare (this._last_im_interaction_datetime) == 1)
                        {
                          this._last_im_interaction_datetime = my_interaction_details.last_im_interaction_datetime;
                        }
                    }
                }
            }
          return this._last_im_interaction_datetime;
        }
    }

  /**
   * {@inheritDoc}
   */
  public uint call_interaction_count
    {
      get
        {
          uint counter = 0;
          /* Iterate over all personas and sum up their call interaction counts*/
          foreach (var persona in this._persona_set)
            {
              var my_interaction_details = persona as InteractionDetails;
              if (my_interaction_details != null)
                {
                  counter = counter + my_interaction_details.call_interaction_count;
                }
            }
          return counter;
        }
    }

  /**
   * {@inheritDoc}
   */
  private DateTime? _last_call_interaction_datetime = null;

  public DateTime? last_call_interaction_datetime
    {
      get
        {
          if (this._last_call_interaction_datetime == null)
            {
              /* Iterate over all personas and get the latest IM interaction datetime */
              foreach (var persona in this._persona_set)
                {
                  var my_interaction_details = persona as InteractionDetails;
                  if (my_interaction_details != null &&
                      my_interaction_details.last_call_interaction_datetime != null)
                    {
                      var interaction_datetime = my_interaction_details.last_call_interaction_datetime;
                      if (this._last_call_interaction_datetime == null ||
                          interaction_datetime.compare (this._last_call_interaction_datetime) > 1)
                        {
                          this._last_call_interaction_datetime = my_interaction_details.last_call_interaction_datetime;
                        }
                    }
                }
            }
          return this._last_call_interaction_datetime;
        }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.11.0
   */
  public ExtendedFieldDetails? get_extended_field (string name)
    {
      debug ("Getting extended field '%s' on '%s'…", name, this.id);

      /* Try to get it from the writeable Personas which have "extended-info"
       * as a writeable property. */
      foreach (var p in this._persona_set)
        {
          if ("extended-info" in p.writeable_properties)
            {
              var e = p as ExtendedInfo;
              var details = e.get_extended_field (name);
              if (details != null)
                {
                  return details;
                }
            }
        }

      return null;
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.11.0
   */
  public async void change_extended_field (
      string name, ExtendedFieldDetails value) throws PropertyError
    {
      debug ("Setting extended field '%s' on '%s'…", name, this.id);

      PropertyError? persona_error = null;
      var prop_changed = false;

      /* Try to write it to only the writeable Personas which have "extended-info"
       * as a writeable property. */
      foreach (var p in this._persona_set)
        {
          if ("extended-info" in p.writeable_properties)
            {
              var e = p as ExtendedInfo;
              try
                {
                  yield e.change_extended_field (name, value);
                  debug ("    written to writeable persona '%s'", p.uid);
                  prop_changed = true;
                }
              catch (PropertyError e)
                {
                  /* Store the first error so we can throw it if setting the
                   * extended field fails on every other persona. */
                  if (persona_error == null)
                    {
                      persona_error = e;
                    }
                }
            }
        }

      /* Failure? Changing the property failed on every suitable persona found
       * (and potentially zero suitable personas were found). */
      if (prop_changed == false)
        {
          if (persona_error == null)
            {
              persona_error = new PropertyError.NOT_WRITEABLE (
                  _("Failed to change property ‘%s’: No suitable personas were found."),
                  "extended-info");
            }

          throw persona_error;
        }
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.11.0
   */
  public async void remove_extended_field (string name) throws PropertyError
    {
      debug ("Removing extended field '%s' on '%s'…", name, this.id);

      PropertyError? persona_error = null;

      /* Try to remove it from all writeable Personas. */
      foreach (var p in this._persona_set)
        {
          if ("extended-info" in p.writeable_properties)
            {
              var e = p as ExtendedInfo;
              try
                {
                  yield e.remove_extended_field (name);
                  debug ("    removed from writeable persona '%s'", p.uid);
                }
              catch (PropertyError e)
                {
                  /* Store the first error so we can throw it later. */
                  if (persona_error == null)
                    {
                      persona_error = e;
                    }
                }
            }
        }

      /* Failure? */
      if (persona_error != null)
        {
          throw persona_error;
        }
    }

  /**
   * The set of {@link Persona}s encapsulated by this Individual.
   *
   * There must always be at least one Persona in this set.
   *
   * No order is specified over the set of personas, as such an order may be
   * different across each of the properties implemented by the personas (e.g.
   * should they be ordered by presence, name, star sign, etc.?).
   *
   * Changing the set of personas may cause updates to the aggregated properties
   * provided by the Individual, resulting in property notifications for them.
   *
   * Changing the set of personas will not cause permanent linking/unlinking of
   * the added/removed personas to/from this Individual. To do that, call
   * {@link IndividualAggregator.link_personas} or
   * {@link IndividualAggregator.unlink_individual}, which will ensure the link
   * changes are written to the appropriate backend.
   *
   * @since 0.5.1
   */
  public Set<Persona> personas
    {
      get { return this._persona_set_ro; }
      set { this._set_personas (value, null); }
    }

  /**
   * Emitted when one or more {@link Persona}s are added to or removed from
   * the Individual. As the parameters are (unordered) sets, the orders of their
   * elements are undefined.
   *
   * @param added a set of {@link Persona}s which have been added
   * @param removed a set of {@link Persona}s which have been removed
   *
   * @since 0.5.1
   */
  public signal void personas_changed (Set<Persona> added,
      Set<Persona> removed);

  private static void _notify_alias_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_alias ();
    }

  private static void _notify_avatar_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_avatar ();
    }

  private static void _notify_full_name_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_full_name ();
    }

  private static void _notify_structured_name_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_structured_name ();
    }

  private static void _notify_nickname_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_nickname ();
    }

  private void _persona_group_changed_cb (string group, bool is_member)
    {
      this._update_groups (false);
    }

  private static void _notify_gender_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_gender ();
    }

  private static void _notify_urls_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_urls (false);
    }

  private static void _notify_phone_numbers_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_phone_numbers (false);
    }

  private static void _notify_postal_addresses_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_postal_addresses (false);
    }

  private static void _notify_email_addresses_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_email_addresses (false);
    }

  private static void _notify_roles_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_roles (false);
    }

  private static void _notify_birthday_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_birthday ();
    }

  private static void _notify_notes_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_notes (false);
    }

  private static void _notify_local_ids_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_local_ids (false);
    }

  private static void _notify_location_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_location ();
    }

  /**
   * Add or remove the Individual from the specified group.
   *
   * If ``is_member`` is ``true``, the Individual will be added to the
   * ``group``. If it is ``false``, they will be removed from the ``group``.
   *
   * The group membership change will propagate to every {@link Persona} in
   * the Individual.
   *
   * @param group a freeform group identifier
   * @param is_member whether the Individual should be a member of the group
   * @since 0.1.11
   */
  public async void change_group (string group, bool is_member)
    {
      foreach (var p in this._persona_set)
        {
          if (p is GroupDetails)
            ((GroupDetails) p).change_group.begin (group, is_member);
        }

      /* don't notify, since it hasn't happened in the persona backing stores
       * yet; react to that directly */
    }

  private static void _notify_presence_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_presence ();
    }

  private static void _notify_im_addresses_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_im_addresses (false);
    }

  private static void _notify_web_service_addresses_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_web_service_addresses (false);
    }

  private static void _notify_is_favourite_cb (Individual self, Persona p, ParamSpec ps)
    {
      self._update_is_favourite ();
    }

  private static void _notify_im_interaction_count_cb (Individual self, Persona p, ParamSpec ps)
    {
      /**
       * The property is pull rather than push. This function is called in
       * response to personas emitting a similar notification.
       */
      self.notify_property ("im-interaction-count");
    }

  private static void _notify_call_interaction_count_cb (Individual self, Persona p, ParamSpec ps)
    {
      /**
       * The property is pull rather than push. This function is called in
       * response to personas emitting a similar notification.
       */
      self.notify_property ("call-interaction-count");
    }

  private static void _notify_last_im_interaction_datetime_cb (Individual self, Persona p, ParamSpec ps)
    {
      /**
       * The property is pull rather than push. This function is called in
       * response to personas emitting a similar notification.
       */
      self._last_im_interaction_datetime = null;
      self.notify_property ("last-im-interaction-datetime");
    }

  private static void _notify_last_call_interaction_datetime_cb (Individual self, Persona p, ParamSpec ps)
    {
      /**
       * The property is pull rather than push. This function is called in
       * response to personas emitting a similar notification.
       */
      self._last_call_interaction_datetime = null;
      self.notify_property ("last-call-interaction-datetime");
    }

  [CCode (has_target = false)]
  private delegate void _UnboundNotifier (Individual self,
      Persona persona, ParamSpec ps);

  private struct _Notifier
    {
      unowned string property;
      _UnboundNotifier notify;
    }

  /* This contains static methods that take "this" as an explicit parameter,
   * so that we can have one big lookup table at the class level without
   * having to mess about with delegates.
   *
   * All keys in this array must be unique. */
  private const _Notifier _notifiers[] =
    {
      { "alias", Individual._notify_alias_cb },
      { "avatar", Individual._notify_avatar_cb },
      { "presence-message", Individual._notify_presence_cb },
      { "client-types", Individual._notify_presence_cb },
      { "presence-type", Individual._notify_presence_cb },
      { "im-addresses", Individual._notify_im_addresses_cb },
      { "web-service-addresses", Individual._notify_web_service_addresses_cb },
      { "is-favourite", Individual._notify_is_favourite_cb },
      { "structured-name", Individual._notify_structured_name_cb },
      { "full-name", Individual._notify_full_name_cb },
      { "nickname", Individual._notify_nickname_cb },
      { "gender", Individual._notify_gender_cb },
      { "urls", Individual._notify_urls_cb },
      { "phone-numbers", Individual._notify_phone_numbers_cb },
      { "email-addresses", Individual._notify_email_addresses_cb },
      { "roles", Individual._notify_roles_cb },
      { "birthday", Individual._notify_birthday_cb },
      { "notes", Individual._notify_notes_cb },
      { "postal-addresses", Individual._notify_postal_addresses_cb },
      { "local-ids", Individual._notify_local_ids_cb },
      { "location", Individual._notify_location_cb },
      { "im-interaction-count", Individual._notify_im_interaction_count_cb },
      { "call-interaction-count", Individual._notify_call_interaction_count_cb },
      { "last-im-interaction-datetime", Individual._notify_last_im_interaction_datetime_cb },
      { "last-call-interaction-datetime", Individual._notify_last_call_interaction_datetime_cb },
    };

  private void _persona_notify_cb (Object obj, ParamSpec ps)
    {
      var persona = (Persona) obj;  /* will abort on failure */

      /* It should not be possible for two Individuals to be simultaneously
       * connected to the same Persona (as _connect_to_persona() will disconnect
       * any previous Persona.individual), but warn (rather than asserting) just
       * in case, since this is a critical code path. */
      if (ps.name != "individual" &&
          persona.individual != this &&
          persona.individual != null)
        {
          warning ("Notification on property ‘%s’ of Persona %p (‘%s’) where " +
              "Persona.individual is %p but was expected to be %p.",
              ps.name, persona, persona.uid, persona.individual, this);
          return;
        }
      else if (ps.name == "individual")
        {
          if (persona.individual != this)
            {
              /* Remove the notified persona from our set of personas. */
              var remaining_personas = new SmallSet<Persona> ();
              remaining_personas.add_all (this._persona_set);
              remaining_personas.remove (persona);

              this._set_personas (remaining_personas, null);
            }

          return;
        }

      foreach (var notifier in Individual._notifiers)
        {
          if (ps.name == notifier.property)
            {
              notifier.notify (this, persona, ps);
              break;  /* assume all entries in notifiers are unique */
            }
        }
    }

  /**
   * Create a new Individual.
   *
   * The Individual can optionally be seeded with the {@link Persona}s in
   * ``personas``. Otherwise, it will have to have personas added using the
   * {@link Folks.Individual.personas} property after construction.
   *
   * @param personas a list of {@link Persona}s to initialise the
   * {@link Folks.Individual} with, or ``null``
   * @return a new Individual
   *
   * @since 0.5.1
   */
  public Individual (Set<Persona>? personas)
    {
      Object (personas: personas);

      debug ("Creating new Individual with %u Personas: %p",
          this._persona_set.size, this);
    }

  construct
    {
      this._persona_set_ro = this._persona_set.read_only_view;
    }

  ~Individual ()
    {
      debug ("Destroying Individual '%s': %p", this.id, this);
    }

  /* Emit the personas-changed signal, turning null parameters into empty sets
   * and ensuring that the signal is emitted with read-only views of the sets
   * so that signal handlers can't modify the sets. */
  private void _emit_personas_changed (Set<Persona>? added,
      Set<Persona>? removed)
    {
      var _added = added;
      var _removed = removed;

      if ((added == null || ((!) added).size == 0) &&
          (removed == null || ((!) removed).size == 0))
        {
          /* Emitting it with no added or removed personas is pointless */
          return;
        }
      else if (added == null)
        {
          _added = SmallSet.empty<Persona> ();
        }
      else if (removed == null)
        {
          _removed = SmallSet.empty<Persona> ();
        }

      // We've now guaranteed that both _added and _removed are non-null.
      this.personas_changed (((!) _added).read_only_view,
          ((!) _removed).read_only_view);
    }

  private void _store_removed_cb (PersonaStore store)
    {
      var remaining_personas = new SmallSet<Persona> ();

      /* Build a set of the remaining personas (those which weren't in the
       * removed store. */
      foreach (var persona in this._persona_set)
        {
          if (persona.store != store)
            {
              remaining_personas.add (persona);
            }
        }

      this._set_personas (remaining_personas, null);
    }

  private void _store_personas_changed_cb (PersonaStore store,
      Set<Persona> added,
      Set<Persona> removed,
      string? message,
      Persona? actor,
      GroupDetails.ChangeReason reason)
    {
      var remaining_personas = new SmallSet<Persona> ();

      /* Build a set of the remaining personas (those which aren't in the
       * set of removed personas). */
      foreach (var persona in this._persona_set)
        {
          if (!removed.contains (persona))
            {
              remaining_personas.add (persona);
            }
        }

      this._set_personas (remaining_personas, null);
    }

  private void _update_fields ()
    {
      this._update_groups (false);
      this._update_presence ();
      this._update_is_favourite ();
      this._update_avatar ();
      this._update_alias ();
      this._update_trust_level ();
      this._update_im_addresses (false);
      this._update_web_service_addresses (false);
      this._update_structured_name ();
      this._update_full_name ();
      this._update_nickname ();
      this._update_gender ();
      this._update_urls (false);
      this._update_phone_numbers (false);
      this._update_email_addresses (false);
      this._update_roles (false);
      this._update_birthday ();
      this._update_notes (false);
      this._update_postal_addresses (false);
      this._update_local_ids (false);
      this._update_location ();

      /* Entirely derived fields. */
      this._update_display_name ();
    }

  /* Delegate to update the value of a property on this individual from the
   * given chosen persona. The chosen_persona may be null, in which case we have
   * to set a default value.
   *
   * Used in _update_single_valued_property(), below. */
  private delegate void SingleValuedPropertySetter (Persona? chosen_persona);

  /* Delegate to filter a persona based on whether a given property is set.
   *
   * Used in _update_single_valued_property(), below. */
  private delegate bool PropertyFilter (Persona persona);

  /*
   * Update a single-valued property from the values in the personas.
   *
   * Single-valued properties are ones such as {@link Individual.alias} or
   * {@link Individual.gender} — as opposed to multi-valued ones (which are
   * generally sets) such as {@link Individual.im_addresses} or
   * {@link Individual.groups}.
   *
   * This function uses the given comparison function to order the personas in
   * this individual, with the highest-positioned persona (the “greatest”
   * persona in the total order) finally being passed to the setter function to
   * use in updating the individual's value for the given property. i.e. If
   * ``compare_func(a, b)`` is called and returns > 0, persona ``a`` will be
   * passed to the setter.
   *
   * At a level above ``compare_func``, the function always prefers personas
   * from the primary store (see {@link IndividualAggregator.primary_store})
   * over those which aren't.
   *
   * Note that if a suitable persona isn't found in the individual (if, for
   * example, no personas in the individual implement the desired interface),
   * ``null`` will be passed to ``setter``, which should then set the
   * individual's property to a default value.
   *
   * @param interface_type the type of interface which all personas under
   * consideration must implement ({@link Persona} to select all personas)
   * @param compare_func comparison function to order personas for selection
   * @param prop_name name of the property being set, as used in
   * {@link Persona.writeable_properties}
   * @param setter function to update the individual with the chosen value
   * @since 0.6.2
   */
  private void _update_single_valued_property (Type interface_type,
      PropertyFilter filter_func,
      CompareFunc<Persona> compare_func, string prop_name,
      SingleValuedPropertySetter setter)
    {
      CompareDataFunc<Persona> primary_compare_func = (a, b) =>
        {
          return_val_if_fail (a != null, 0);
          return_val_if_fail (b != null, 0);

          /* Always prefer values which are set over those which aren't. */
          var a_is_set = filter_func (a);
          var b_is_set = filter_func (b);

          if (a_is_set != b_is_set)
            {
              return (a_is_set ? 1 : 0) - (b_is_set ? 1 : 0);
            }

          var a_is_primary = a.store.is_primary_store;
          var b_is_primary = b.store.is_primary_store;

          if (a_is_primary != b_is_primary)
            {
              return (a_is_primary ? 1 : 0) - (b_is_primary ? 1 : 0);
            }

          /* If both personas have the same is-primary value, prefer personas
           * which have the given property as writeable over those which
           * don't. */
          var a_is_writeable = (prop_name in a.writeable_properties);
          var b_is_writeable = (prop_name in b.writeable_properties);

          if (a_is_writeable != b_is_writeable)
            {
              return (a_is_writeable ? 1 : 0) - (b_is_writeable ? 1 : 0);
            }

          /* If both personas have the same writeability for this property, fall
           * back to the given comparison function. If the comparison function
           * gives them an equal order, we use the personas' UIDs to ensure that
           * we end up with a total order over all personas in the individual
           * (otherwise we might end up with unstable property values). */
          var order = compare_func (a, b);

          if (order == 0)
            {
              order = strcmp (a.uid, b.uid);
            }

          return order;
        };

      Persona? candidate_p = null;

      foreach (var p in this._persona_set)
        {
          /* We only care about personas implementing the given interface. */
          if (p.get_type ().is_a (interface_type))
            {
              if (candidate_p == null ||
                  primary_compare_func (p, (!) candidate_p) > 0)
                {
                  candidate_p = p;
                }
            }
        }

      /* Update the property with the values from the best candidate persona we
       * found. Note that it's possible for candidate_p to be null if (e.g.)
       * none of this._persona_set implemented the interface. */
      setter (candidate_p);
    }

  /* Delegate to add the values of a property from all personas to the
   * collection of values for that property in this individual.
   *
   * Used in _update_multi_valued_property(), below. */
  private delegate bool MultiValuedPropertySetter ();

  /* Delegate to get whether a multi-valued property in this Individual has not
   * been initialised yet (and is thus still null).
   *
   * Used in _update_multi_valued_property(), below. */
  private delegate bool PropertyIsNull ();

  /* Delegate to create a new empty collection for a multi-valued property in
   * this Individual and assign it to the property.
   *
   * Used in _update_multi_valued_property(), below. */
  private delegate void CollectionCreator ();

  /*
   * Update a multi-valued property from the values in the personas.
   *
   * Multi-valued properties are ones such as {@link Individual.notes} or
   * {@link Individual.email_addresses} which have multiple values taken as the
   * union of the values listed by the personas for those properties.
   *
   * This function handles lazy instantiation of the multi-valued property. If
   * ``create_if_not_exist`` is ``true``, the property is guaranteed to be
   * created (by ``create_collection``) and set to a non-``null`` value before
   * this function returns.
   *
   * If ``create_if_not_exist`` is ``false``, however, the property may not be
   * instantiated if it hasn't already been accessed through its property
   * getter. In this case, a change notification will be emitted for the
   * property and this function will return immediately.
   *
   * If ``force_update`` is ``true``, then existing values get updated (if
   * the current value is different) or created (according to the
   * ``create_if_not_exist`` value). Otherwise the function only ensures
   * that there is a value (if ``create_if_not_exist`` is set) and leaves
   * existing values unchanged.
   *
   * If the property value is to be instantiated, or already has been
   * instantiated, its value is updated by ``setter`` from the values of the
   * property in the individual's personas.
   *
   * @param prop_name name of the property being set, as used in
   * {@link Persona.writeable_properties}
   * @param create_if_not_exist ``true`` to ensure the property is non-null;
   * ``false`` otherwise
   * @param prop_is_null function returning ``true`` iff the property is
   * currently ``null``
   * @param create_collection function creating a new collection/container for
   * the property values and assigning it to the property (and updating the
   * property's read-only view as necessary)
   * @param setter function which adds the values from the individual's
   * personas' values for the property to the individual's value for the
   * property; it returns ``true`` if the property value has changed
   * @since 0.7.4
   */
  private void _update_multi_valued_property (string prop_name,
      bool create_if_not_exist, PropertyIsNull prop_is_null,
      CollectionCreator create_collection, MultiValuedPropertySetter setter,
      bool emit_notification = true,
      bool force_update = true)
    {
      /* If the set of values doesn't exist, and we're not meant to lazily
       * create it, then simply emit a notification (since the set might've
       * changed — we can't be sure, but emitting is a safe over-estimate) and
       * return. */
      bool created = false;
      if (prop_is_null ())
        {
          /* Notify and return. */
          if (create_if_not_exist == false)
            {
              if (emit_notification)
                {
                  this.notify_property (prop_name);
                }
              return;
            }

          /* Lazily instantiate the set of IM addresses. */
          create_collection ();
          created = true;
        }

      /* Re-populate the collection as the union of the values in the
       * individual's personas. Do this when an empty property was just
       * created or we were asked to explicitly (usually because the caller
       * knows that the current value is out-dated).
       */
      if ((created || force_update) && setter () == true && emit_notification)
        {
          this.notify_property (prop_name);
        }
    }

  private void _update_groups (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      /* If the set of groups doesn't exist, and we're not meant to lazily
       * create it, then simply emit a notification (since the set might've
       * changed — we can't be sure, but emitting is a safe over-estimate) and
       * return. */
      bool created = false;
      if (this._groups == null && create_if_not_exist == false)
        {
          if (emit_notification)
            {
              this.notify_property ("groups");
            }
          return;
        }

      /* Lazily instantiate the set of groups. */
      else if (this._groups == null)
        {
          this._groups = new SmallSet<string> ();
          this._groups_ro = this._groups.read_only_view;
          created = true;
        }

      /* Don't touch existing content in get(). */
      if (!created && !force_update)
         return;

      var new_groups = new SmallSet<string> ();

      /* FIXME: this should partition the personas by store (maybe we should
       * keep that mapping in general in this class), and execute
       * "groups-changed" on the store (with the set of personas), to allow the
       * back-end to optimize it (like Telepathy will for MembersChanged for the
       * groups channel list) */
      foreach (var p in this._persona_set)
        {
          if (p is GroupDetails)
            {
              var persona = (GroupDetails) p;

              foreach (var group in persona.groups)
                {
                  new_groups.add (group);
                }
            }
        }

      foreach (var group in new_groups)
        {
          if (this._groups.add (group) && emit_notification)
            {
              this.group_changed (group, true);
            }
        }

      /* buffer the removals, so we don't remove while iterating */
      var removes = new GLib.List<string> ();
      foreach (var group in this._groups)
        {
          if (!new_groups.contains (group))
            removes.prepend (group);
        }

      removes.foreach ((l) =>
        {
          unowned string group = (string) l;
          this._groups.remove (group);
          if (emit_notification)
            {
              this.group_changed (group, false);
            }
        });
    }

  private void _update_presence ()
    {
      this._update_single_valued_property (typeof (PresenceDetails), (p) =>
        {
          return ((PresenceDetails) p).presence_type != PresenceType.UNSET;
        }, (a, b) =>
        {
          var a_presence = ((PresenceDetails) a).presence_type;
          var b_presence = ((PresenceDetails) b).presence_type;

          return PresenceDetails.typecmp (a_presence, b_presence);
        }, "presence", (p) =>
        {
          var presence_message = ""; /* must not be null */
          var presence_status = ""; /* must not be null */
          string[] client_types = {};
          var presence_type = Folks.PresenceType.UNSET;

          if (p != null)
            {
              presence_type = ((PresenceDetails) p).presence_type;
              presence_message = ((PresenceDetails) p).presence_message;
              presence_status = ((PresenceDetails) p).presence_status;
              client_types = ((PresenceDetails) p).client_types;
            }

          /* Only notify if any of the values have changed. */
          if (this.presence_type != presence_type ||
              this.presence_message != presence_message ||
              this.presence_status != presence_status ||
              this.client_types != client_types)
            {
              this.freeze_notify ();
              this.presence_message = presence_message;
              this.presence_type = presence_type;
              this.presence_status = presence_status;
              this.client_types = client_types;
              this.thaw_notify ();
            }
        });
    }

  private void _update_is_favourite ()
    {
      this._update_single_valued_property (typeof (FavouriteDetails), (p) =>
        {
          return ((FavouriteDetails) p).is_favourite;
        }, (a, b) =>
        {
          var a_is_favourite = ((FavouriteDetails) a).is_favourite;
          var b_is_favourite = ((FavouriteDetails) b).is_favourite;

          return ((a_is_favourite == true) ? 1 : 0) -
                 ((b_is_favourite == true) ? 1 : 0);
        }, "is-favourite", (p) =>
        {
          var favourite = false;

          if (p != null)
            {
              favourite = ((FavouriteDetails) p).is_favourite;
            }

          /* Only notify if the value has changed. We have to set the private
           * member and notify manually, or we'd end up propagating the new
           * favourite status back down to all our Personas. */
          if (this._is_favourite != favourite)
            {
              this._is_favourite = favourite;
              this.notify_property ("is-favourite");
            }
        });
    }

  private string _look_up_alias_for_display_name (Persona? p)
    {
      var a = p as AliasDetails;
      if (a != null && a.alias != null)
        {
          return a.alias;
        }

      return "";
    }

  private string _look_up_name_details_for_display_name (Persona? p)
    {
      var n = p as NameDetails;
      if (n != null)
        {
          if (n.full_name != "")
            {
              return n.full_name;
            }
          else if (n.structured_name != null)
            {
              return n.structured_name.to_string ();
            }
          else if (n.nickname != "")
            {
              return n.nickname;
            }
        }

      return "";
    }

  private string _look_up_email_address_for_display_name (Persona? p)
    {
      var e = p as EmailDetails;
      if (e != null)
        {
          foreach (var email_fd in ((!) e).email_addresses)
            {
              if (email_fd.value != null)
                {
                  return email_fd.value;
                }
            }
        }

      return "";
    }

  private string _look_up_phone_number_for_display_name (Persona? p)
    {
      var e = p as PhoneDetails;
      if (e != null)
        {
          foreach (var phone_fd in ((!) e).phone_numbers)
            {
              if (phone_fd.value != null)
                {
                  return phone_fd.value;
                }
            }
        }

      return "";
    }

  private string _look_up_display_id_for_display_name (Persona? p)
    {
      // Sometimes, the display_id will fall back to the IID.
      // The last condition makes sure we don't use that as a display name
      if (p != null && p.display_id != null && p.display_id != p.iid)
        {
          return p.display_id;
        }

      return "";
    }

  private string _look_up_postal_address_for_display_name (Persona? p)
    {
      var address_details = p as PostalAddressDetails;
      if (address_details != null)
        {
          foreach (var pa_fd in ((!) address_details).postal_addresses)
            {
              var pa = pa_fd.value;
              if (pa != null)
                {
                  return pa.to_string ();
                }
            }
        }

      return "";
    }

  private void _update_display_name ()
    {
      Persona? primary_persona = null;
      var new_display_name = "";

      /* Find the primary persona first. The primary persona's values will be
       * preferred in every case where they're set. */
      foreach (var p in this._persona_set)
        {
          if (p.store.is_primary_store)
            {
              primary_persona = p;
              break;
            }
        }

      /* See if any persona has an alias set. */
      new_display_name = this._look_up_alias_for_display_name (primary_persona);

      foreach (var p in this._persona_set)
        {
          if (new_display_name != "")
            {
              break;
            }

          new_display_name = this._look_up_alias_for_display_name (p);
        }

      /* Try NameDetails next. */
      if (new_display_name == "")
        {
          new_display_name =
              this._look_up_name_details_for_display_name (primary_persona);

          foreach (var p in this._persona_set)
            {
              if (new_display_name != "")
                {
                  break;
                }

              new_display_name =
                  this._look_up_name_details_for_display_name (p);
            }
        }

      /* Now the e-mail addresses. */
      if (new_display_name == "")
        {
          new_display_name =
              this._look_up_email_address_for_display_name (primary_persona);

          foreach (var p in this._persona_set)
            {
              if (new_display_name != "")
                {
                  break;
                }

              new_display_name =
                  this._look_up_email_address_for_display_name (p);
            }
        }

      /* Now the phone numbers. */
      if (new_display_name == "")
        {
          new_display_name =
              this._look_up_phone_number_for_display_name (primary_persona);

          foreach (var p in this._persona_set)
            {
              if (new_display_name != "")
                {
                  break;
                }

              new_display_name =
                  this._look_up_phone_number_for_display_name (p);
            }
        }

      /* Now the display-id. */
      if (new_display_name == "")
        {
          new_display_name =
              this._look_up_display_id_for_display_name (primary_persona);

          foreach (var p in this._persona_set)
            {
              if (new_display_name != "")
                {
                  break;
                }

              new_display_name =
                  this._look_up_display_id_for_display_name (p);
            }
        }

      /* Finally fall back to the postal address. */
      if (new_display_name == "")
        {
          new_display_name =
              this._look_up_postal_address_for_display_name (primary_persona);

          foreach (var p in this._persona_set)
            {
              if (new_display_name != "")
                {
                  break;
                }

              new_display_name =
                  this._look_up_postal_address_for_display_name (p);
            }
        }

      /* Ultimate fall back: a static string. */
      if (new_display_name == "")
        {
          /* Translators: This is the default name for an Individual
           * when displayed in the UI if no personal details are available
           * for them. */
          new_display_name = _("Unnamed Person");
        }

      if (new_display_name != this._display_name)
        {
          this._display_name = new_display_name;
          debug ("Setting display name ‘%s’", new_display_name);
          this.notify_property ("display-name");
        }
    }

  private void _update_alias ()
    {
      this._update_single_valued_property (typeof (AliasDetails), (p) =>
        {
          var alias = ((AliasDetails) p).alias;
          return_val_if_fail (alias != null, false);

          return (alias.strip () != ""); /* empty aliases are unset */
        }, (a, b) =>
        {
          var a_alias = ((AliasDetails) a).alias;
          var b_alias = ((AliasDetails) b).alias;

          return_val_if_fail (a_alias != null, 0);
          return_val_if_fail (b_alias != null, 0);

          var a_is_empty = (a_alias.strip () == "") ? 1 : 0;
          var b_is_empty = (b_alias.strip () == "") ? 1 : 0;

          /* We prefer to not have an alias which is the same as the Persona's
           * display-id, since having such an alias implies that it's the
           * default. However, we prefer using such an alias to using the
           * Persona's UID, which is our ultimate fallback (below). */
          var a_is_display_id = (a_alias == a.display_id) ? 1 : 0;
          var b_is_display_id = (b_alias == b.display_id) ? 1 : 0;

          return (b_is_empty + b_is_display_id) -
                 (a_is_empty + a_is_display_id);
        }, "alias", (p) =>
        {
          string alias = ""; /* must not be null */

          if (p != null)
            {
              alias = ((AliasDetails) p).alias.strip ();
            }

          /* Only notify if the value has changed. We have to set the private
           * member and notify manually, or we'd end up propagating the new
           * alias back down to all our Personas, even if it's a fallback
           * display ID or something else undesirable. */
          if (this._alias != alias)
            {
              this._alias = alias;
              debug ("Setting alias ‘%s’", alias);
              this.notify_property ("alias");

              this._update_display_name ();
            }
        });
    }

  private void _update_avatar ()
    {
      this._update_single_valued_property (typeof (AvatarDetails), (p) =>
        {
          return ((AvatarDetails) p).avatar != null;
        }, (a, b) =>
        {
          /* We can't compare two set avatars efficiently. See: bgo#652721. */
          return 0;
        }, "avatar", (p) =>
        {
          LoadableIcon? avatar = null;

          if (p != null)
            {
              avatar = ((AvatarDetails) p).avatar;
            }

          /* only notify if the value has changed */
          if ((this._avatar == null && avatar != null) ||
              (this._avatar != null &&
               (avatar == null || !((!) this._avatar).equal (avatar))))
            {
              this._avatar = avatar;
              this.notify_property ("avatar");
            }
        });
    }

  private void _update_trust_level ()
    {
      var trust_level = TrustLevel.PERSONAS;

      foreach (var p in this._persona_set)
        {
          if (p.is_user == false &&
              p.store.trust_level == PersonaStoreTrust.NONE)
            trust_level = TrustLevel.NONE;
        }

      /* Only notify if the value has changed */
      if (this.trust_level != trust_level)
        this.trust_level = trust_level;
    }

  private void _update_im_addresses (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      this._update_multi_valued_property ("im-addresses",
          create_if_not_exist, () => { return this._im_addresses == null; },
          () =>
            {
              this._im_addresses = new HashMultiMap<string, ImFieldDetails> (
                  null, null, AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);
            },
          () =>
            {
              var new_im_addresses = new HashMultiMap<string, ImFieldDetails> (
                  null, null, AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);

              foreach (var persona in this._persona_set)
                {
                  /* We only care about personas implementing the given interface. */
                  var im_details = persona as ImDetails;
                  if (im_details != null)
                    {
                      var iter = im_details.im_addresses.map_iterator ();

                      while (iter.next ())
                        new_im_addresses.set (iter.get_key (),
                            iter.get_value ());
                    }
                }

              if (!Utils.multi_map_str_afd_equal (new_im_addresses,
                  this._im_addresses))
                {
                  this._im_addresses = new_im_addresses;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  private void _update_web_service_addresses (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      this._update_multi_valued_property ("web-service-addresses",
          create_if_not_exist,
          () => { return this._web_service_addresses == null; },
          () =>
            {
              this._web_service_addresses =
                  new HashMultiMap<string, WebServiceFieldDetails> (null, null,
                      AbstractFieldDetails<string>.hash_static,
                      AbstractFieldDetails<string>.equal_static);
            },
          () =>
            {
              var new_web_service_addresses =
                  new HashMultiMap<string, WebServiceFieldDetails> (null, null,
                      AbstractFieldDetails<string>.hash_static,
                      AbstractFieldDetails<string>.equal_static);

              foreach (var persona in this._persona_set)
                {
                  /* We only care about personas implementing the given interface. */
                  var web_service_details = persona as WebServiceDetails;
                  if (web_service_details != null)
                    {
                      var iter = web_service_details.web_service_addresses.map_iterator ();

                      while (iter.next ())
                        new_web_service_addresses.set (iter.get_key (),
                            iter.get_value ());
                    }
                }

              if (!Utils.multi_map_str_afd_equal (new_web_service_addresses,
                  this._web_service_addresses))
                {
                  this._web_service_addresses = new_web_service_addresses;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  /* Note: This causes the Persona to be stolen away from its current
   * Individual. */
  private void _connect_to_persona (Persona persona)
    {
      if (persona.individual != null && persona.individual != this)
        {
          /* Disconnect the previous Individual. This atomically avoids having
           * two Individuals connected to the same Persona simultaneously. */
          persona.individual._disconnect_from_persona (persona, this);
        }

      persona.individual = this;

      /* We're interested in most, if not all, signals from a persona,
       * so avoid a significant amount of GObject signal overhead by
       * connecting to the entire signal and demultiplexing it ourselves. */
      persona.notify.connect (this._persona_notify_cb);

      if (persona is GroupDetails)
        {
          ((GroupDetails) persona).group_changed.connect (
              this._persona_group_changed_cb);
        }
    }

  private void _update_structured_name ()
    {
      this._update_single_valued_property (typeof (NameDetails), (p) =>
        {
          var name = ((NameDetails) p).structured_name;
          return (name != null && !((!) name).is_empty ());
        }, (a, b) =>
        {
          /* Can't compare two set names. */
          return 0;
        }, "structured-name", (p) =>
        {
          StructuredName? name = null;

          if (p != null)
            {
              name = ((NameDetails) p).structured_name;

              if (name != null && ((!) name).is_empty ())
                {
                  name = null;
                }
            }

          if ((this._structured_name == null && name != null) ||
              (this._structured_name != null &&
               (name == null || !((!) this._structured_name).equal ((!) name))))
            {
              this._structured_name = name;
              this.notify_property ("structured-name");

              this._update_display_name ();
            }
        });
    }

  private void _update_full_name ()
    {
      this._update_single_valued_property (typeof (NameDetails), (p) =>
        {
          var name = ((NameDetails) p).full_name;
          return_val_if_fail (name != null, false);

          return (name.strip () != ""); /* empty names are unset */
        }, (a, b) =>
        {
          /* Can't compare two set names. */
          return 0;
        }, "full-name", (p) =>
        {
          string new_full_name = ""; /* must not be null */

          if (p != null)
            {
              new_full_name = ((NameDetails) p).full_name.strip ();
            }

          if (new_full_name != this._full_name)
            {
              this._full_name = new_full_name;
              this.notify_property ("full-name");

              this._update_display_name ();
            }
        });
    }

  private void _update_nickname ()
    {
      this._update_single_valued_property (typeof (NameDetails), (p) =>
        {
          var nickname = ((NameDetails) p).nickname;
          return_val_if_fail (nickname != null, false);

          return (nickname.strip () != ""); /* empty names are unset */
        }, (a, b) =>
        {
          /* Can't compare two set names. */
          return 0;
        }, "nickname", (p) =>
        {
          string new_nickname = ""; /* must not be null */

          if (p != null)
            {
              new_nickname = ((NameDetails) p).nickname.strip ();
            }

          if (new_nickname != this._nickname)
            {
              this._nickname = new_nickname;
              this.notify_property ("nickname");

              this._update_display_name ();
            }
        });
    }

  private void _disconnect_from_persona (Persona persona,
      Individual? replacement_individual)
    {
      persona.notify.disconnect (this._persona_notify_cb);

      if (persona is GroupDetails)
        {
          ((GroupDetails) persona).group_changed.disconnect (
              this._persona_group_changed_cb);
        }

      /* Don't update the individual if the persona's been added to the new one
       * already (and thus the new individual has already changed
       * persona.individual).
       *
       * FIXME: Ideally, we'd assert that a persona can't be added to a new
       * individual before it's removed from the old one. However, this
       * currently isn't possible due to the way the aggregator works. When the
       * aggregator's rewritten, it would be nice to fix this. */
      if (persona.individual == this)
        {
          /* It may be the case that the persona's being removed from the
           * individual (i.e. the replacement individual is non-null, but
           * doesn't contain this persona). In this case, we need to set the
           * persona's individual to null. */
          if (replacement_individual != null &&
              persona in ((!) replacement_individual).personas)
            {
              persona.individual = replacement_individual;
            }
          else
            {
              persona.individual = null;
            }
        }
    }

  private void _update_gender ()
    {
      this._update_single_valued_property (typeof (GenderDetails), (p) =>
        {
          return ((GenderDetails) p).gender != Gender.UNSPECIFIED;
        }, (a, b) =>
        {
          /* It would be sexist to rank one gender over another.
           * Besides, how often will we see two personas in the same individual
           * which have different genders? */
          return 0;
        }, "gender", (p) =>
        {
          var new_gender = Gender.UNSPECIFIED;

          if (p != null)
            {
              new_gender = ((GenderDetails) p).gender;
            }

          if (new_gender != this.gender)
            {
              this._gender = new_gender;
              this.notify_property ("gender");
            }
        });
    }

  private void _update_urls (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      this._update_multi_valued_property ("urls", create_if_not_exist,
          () => { return this._urls == null; },
          () =>
            {
              this._urls = new SmallSet<UrlFieldDetails> (
                  AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);
              this._urls_ro = this._urls.read_only_view;
            },
          () =>
            {
              var new_urls = new SmallSet<UrlFieldDetails> (
                  AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);
              var urls_set = new HashMap<unowned string,
                  unowned UrlFieldDetails> (
                    null, null,  AbstractFieldDetails<string>.equal_static);

              foreach (var persona in this._persona_set)
                {
                  /* We only care about personas implementing the given
                   * interface. If the same URL exists multiple times we merge
                   * the parameters. */
                  var url_details = persona as UrlDetails;
                  if (url_details != null)
                    {
                      foreach (var url_fd in ((!) url_details).urls)
                        {
                          var existing = urls_set.get (url_fd.value);
                          if (existing != null)
                            {
                              existing.extend_parameters (url_fd.parameters);
                            }
                          else
                            {
                              var new_url_fd =
                                  new UrlFieldDetails (url_fd.value);
                              new_url_fd.extend_parameters (url_fd.parameters);
                              urls_set.set (new_url_fd.value, new_url_fd);
                              new_urls.add (new_url_fd);
                            }
                        }
                    }
                }

              if (!Utils.set_afd_equal (new_urls, this._urls))
                {
                  this._urls = new_urls;
                  this._urls_ro = new_urls.read_only_view;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  private void _update_phone_numbers (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      this._update_multi_valued_property ("phone-numbers", create_if_not_exist,
          () => { return this._phone_numbers == null; },
          () =>
            {
              this._phone_numbers = new SmallSet<PhoneFieldDetails> (
                  AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);
              this._phone_numbers_ro = this._phone_numbers.read_only_view;
            },
          () =>
            {
              var new_phone_numbers = new SmallSet<PhoneFieldDetails> (
                  AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);
              var phone_numbers_set = new HashMap<string, PhoneFieldDetails> (
                  null, null, AbstractFieldDetails<string>.equal_static);

              foreach (var persona in this._persona_set)
                {
                  /* We only care about personas implementing the given
                   * interface. If the same phone number exists multiple times
                   * we merge the parameters. */
                  var phone_details = persona as PhoneDetails;
                  if (phone_details != null)
                    {
                      foreach (var phone_fd in ((!) phone_details).phone_numbers)
                        {
                          var existing = phone_numbers_set.get (phone_fd.value);
                          if (existing != null)
                            {
                              existing.extend_parameters (phone_fd.parameters);
                            }
                          else
                            {
                              var new_fd =
                                  new PhoneFieldDetails (phone_fd.value);
                              new_fd.extend_parameters (phone_fd.parameters);
                              phone_numbers_set.set (new_fd.value, new_fd);
                              new_phone_numbers.add (new_fd);
                            }
                        }
                    }
                }

              if (!Utils.set_string_afd_equal (new_phone_numbers, this._phone_numbers))
                {
                  this._phone_numbers = new_phone_numbers;
                  this._phone_numbers_ro = new_phone_numbers.read_only_view;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  private void _update_email_addresses (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      this._update_multi_valued_property ("email-addresses",
          create_if_not_exist, () => { return this._email_addresses == null; },
          () =>
            {
              this._email_addresses = new SmallSet<EmailFieldDetails> (
                  AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);
              this._email_addresses_ro = this._email_addresses.read_only_view;
            },
          () =>
            {
              var new_email_addresses = new SmallSet<EmailFieldDetails> (
                  AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);
              var emails_set = new HashMap<string, EmailFieldDetails> (
                  null, null, AbstractFieldDetails<string>.equal_static);

              foreach (var persona in this._persona_set)
                {
                  /* We only care about personas implementing the given
                   * interface. If the same e-mail address exists multiple times
                   * we merge the parameters. */
                  var email_details = persona as EmailDetails;
                  if (email_details != null)
                    {
                      foreach (var email_fd in ((!) email_details).email_addresses)
                        {
                          var existing = emails_set.get (email_fd.value);
                          if (existing != null)
                            {
                              existing.extend_parameters (email_fd.parameters);
                            }
                          else
                            {
                              var new_email_fd =
                                  new EmailFieldDetails (email_fd.value,
                                      email_fd.parameters);
                              emails_set.set (new_email_fd.value, new_email_fd);
                              new_email_addresses.add (new_email_fd);
                            }
                        }
                    }
                }

              if (!Utils.set_afd_equal (new_email_addresses,
                  this._email_addresses))
                {
                  this._email_addresses = new_email_addresses;
                  this._email_addresses_ro = new_email_addresses.read_only_view;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  private void _update_roles (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      this._update_multi_valued_property ("roles", create_if_not_exist,
          () => { return this._roles == null; },
          () =>
            {
              this._roles = new SmallSet<RoleFieldDetails> (
                  AbstractFieldDetails<Role>.hash_static,
                  AbstractFieldDetails<Role>.equal_static);
              this._roles_ro = this._roles.read_only_view;
            },
          () =>
            {
              var new_roles = new SmallSet<RoleFieldDetails> (
                  AbstractFieldDetails<Role>.hash_static,
                  AbstractFieldDetails<Role>.equal_static);

              foreach (var persona in this._persona_set)
                {
                  var role_details = persona as RoleDetails;
                  if (role_details != null)
                    {
                      foreach (var role_fd in ((!) role_details).roles)
                        {
                          new_roles.add (role_fd);
                        }
                    }
                }

              if (!Utils.set_afd_equal (new_roles, this._roles))
                {
                  this._roles = new_roles;
                  this._roles_ro = new_roles.read_only_view;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  private void _update_local_ids (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      this._update_multi_valued_property ("local-ids", create_if_not_exist,
          () => { return this._local_ids == null; },
          () =>
            {
              this._local_ids = new SmallSet<string> ();
              this._local_ids_ro = this._local_ids.read_only_view;
            },
          () =>
            {
              var new_local_ids = new SmallSet<string> ();

              foreach (var persona in this._persona_set)
                {
                  var local_id_details = persona as LocalIdDetails;
                  if (local_id_details != null)
                    {
                      foreach (var id in ((!) local_id_details).local_ids)
                        {
                          new_local_ids.add (id);
                        }
                    }
                }

              if (new_local_ids.size != this._local_ids.size ||
                  !new_local_ids.contains_all (this._local_ids))
                {
                  this._local_ids = new_local_ids;
                  this._local_ids_ro = new_local_ids.read_only_view;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  private void _update_location ()
    {
      this._update_single_valued_property (typeof (LocationDetails), (p) =>
        {
          return ((LocationDetails) p).location != null;
        }, (a, b) =>
        {
          // TODO (https://bugzilla.gnome.org/show_bug.cgi?id=627400): pick the "better" location information. For now, pick more or less randomly.
          return 0;
        }, "location", (p) =>
        {
          unowned Location? new_location = null;

          if (p != null)
            {
              new_location = ((LocationDetails) p).location;
            }

          if ((new_location == null) != (this.location == null) /* adding or removing a location? */ ||
              new_location != null && !new_location.equal (this.location) /* different value? */)
            {
              this._location = new_location;
              this.notify_property ("location");
            }
        });
    }

  private void _update_postal_addresses (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      /* FIXME: Detect duplicates somehow? */
      this._update_multi_valued_property ("postal-addresses",
          create_if_not_exist, () => { return this._postal_addresses == null; },
          () =>
            {
              this._postal_addresses = new SmallSet<PostalAddressFieldDetails> (
                  AbstractFieldDetails<PostalAddress>.hash_static,
                  AbstractFieldDetails<PostalAddress>.equal_static);
              this._postal_addresses_ro = this._postal_addresses.read_only_view;
            },
          () =>
            {
              var new_postal_addresses =
                  new SmallSet<PostalAddressFieldDetails> (
                      AbstractFieldDetails<PostalAddress>.hash_static,
                      AbstractFieldDetails<PostalAddress>.equal_static);

              foreach (var persona in this._persona_set)
                {
                  var postal_address_details = persona as PostalAddressDetails;
                  if (postal_address_details != null)
                    {
                      foreach (var pafd in
                          ((!) postal_address_details).postal_addresses)
                        {
                          new_postal_addresses.add (pafd);
                        }
                    }
                }

              if (!Utils.set_afd_equal (new_postal_addresses,
                  this._postal_addresses))
                {
                  this._postal_addresses = new_postal_addresses;
                  this._postal_addresses_ro =
                      new_postal_addresses.read_only_view;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  private void _update_birthday ()
    {
      this._update_single_valued_property (typeof (BirthdayDetails), (p) =>
        {
          var details = ((BirthdayDetails) p);
          return details.birthday != null && details.calendar_event_id != null;
        }, (a, b) =>
        {
          var a_birthday = ((BirthdayDetails) a).birthday;
          var b_birthday = ((BirthdayDetails) b).birthday;
          var a_event_id = ((BirthdayDetails) a).calendar_event_id;
          var b_event_id = ((BirthdayDetails) b).calendar_event_id;

          var a_birthday_is_set = (a_birthday != null) ? 1 : 0;
          var b_birthday_is_set = (b_birthday != null) ? 1 : 0;

          /* We consider the empty string as “set” because it's an opaque ID. */
          var a_event_id_is_set = (a_event_id != null) ? 1 : 0;
          var b_event_id_is_set = (b_event_id != null) ? 1 : 0;

          /* Prefer personas which have both properties set over those who have
           * only one set. We don't consider the case where the birthdays from
           * different personas don't match, because that's just scary. */
          return (a_birthday_is_set + a_event_id_is_set) -
                 (b_birthday_is_set + b_event_id_is_set);
        }, "birthday", (p) =>
        {
          unowned DateTime? bday = null;
          unowned string? calendar_event_id = null;

          if (p != null)
            {
              bday = ((BirthdayDetails) p).birthday;
              calendar_event_id = ((BirthdayDetails) p).calendar_event_id;
            }

          if ((this._birthday == null && bday != null) ||
              (this._birthday != null &&
               (bday == null || !((!) this._birthday).equal ((!) bday))) ||
              (this._calendar_event_id != calendar_event_id))
            {
              this._birthday = bday;
              this._calendar_event_id = calendar_event_id;

              this.freeze_notify ();
              this.notify_property ("birthday");
              this.notify_property ("calendar-event-id");
              this.thaw_notify ();
            }
        });
    }

  private void _update_notes (bool create_if_not_exist, bool emit_notification = true, bool force_update = true)
    {
      this._update_multi_valued_property ("notes", create_if_not_exist,
          () => { return this._notes == null; },
          () =>
            {
              this._notes = new SmallSet<NoteFieldDetails> (
                  AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);
              this._notes_ro = this._notes.read_only_view;
            },
          () =>
            {
              var new_notes = new SmallSet<NoteFieldDetails> (
                  AbstractFieldDetails<string>.hash_static,
                  AbstractFieldDetails<string>.equal_static);

              foreach (var persona in this._persona_set)
                {
                  var note_details = persona as NoteDetails;
                  if (note_details != null)
                    {
                      foreach (var n in ((!) note_details).notes)
                        {
                          new_notes.add (n);
                        }
                    }
                }

              if (!Utils.set_afd_equal (new_notes, this._notes))
                {
                  this._notes = new_notes;
                  this._notes_ro = new_notes.read_only_view;
                  return true;
                }

              return false;
            }, emit_notification, force_update);
    }

  private void _set_personas (Set<Persona>? personas,
      Individual? replacement_individual)
    {
      assert (replacement_individual == null || replacement_individual != this);

      var added = new SmallSet<Persona> ();
      var removed = new SmallSet<Persona> ();

      /* Determine which Personas have been added. If personas == null, we
       * assume it's an empty set. */
      if (personas != null)
        {
          foreach (var p in (!) personas)
            {
              if (!this._persona_set.contains (p))
                {
                  /* Keep track of how many Personas are users */
                  if (p.is_user)
                    this._persona_user_count++;

                  added.add (p);

                  this._persona_set.add (p);
                  this._connect_to_persona (p);

                  /* Increment the Persona count for this PersonaStore */
                  var store = p.store;
                  var num_from_store = this._stores.get (store);
                  if (num_from_store == 0)
                    {
                      this._stores.set (store, num_from_store + 1);
                    }
                  else
                    {
                      this._stores.set (store, 1);

                      store.removed.connect (this._store_removed_cb);
                      store.personas_changed.connect (
                          this._store_personas_changed_cb);
                    }
                }
            }
        }

      /* Determine which Personas have been removed */
      foreach (var p in this._persona_set)
        {
          if (personas == null || !((!) personas).contains (p))
            {
              /* Keep track of how many Personas are users */
              if (p.is_user)
                this._persona_user_count--;

              removed.add (p);

              /* Decrement the Persona count for this PersonaStore */
              var store = p.store;
              var num_from_store = this._stores.get (store);
              if (num_from_store > 1)
                {
                  this._stores.set (store, num_from_store - 1);
                }
              else
                {
                  store.removed.disconnect (this._store_removed_cb);
                  store.personas_changed.disconnect (
                      this._store_personas_changed_cb);

                  this._stores.unset (store);
                }

              this._disconnect_from_persona (p, replacement_individual);
            }
        }

      foreach (var p in removed)
        {
          this._persona_set.remove (p);
        }

      this._emit_personas_changed (added, removed);

      /* Update this.is_user */
      var new_is_user = (this._persona_user_count > 0) ? true : false;
      if (new_is_user != this.is_user)
        this.is_user = new_is_user;

      /* If all the Personas have been removed, remove the Individual */
      if (this._persona_set.size < 1)
        {
          this.removed (replacement_individual);
          return;
        }

      /* Update the ID. We choose the most interesting Persona in the
       * Individual and hash their UID. This is guaranteed to be globally
       * unique, and may not change (for one of the two Individuals) if we link
       * two Individuals together, which is nice though we can't rely on this
       * behaviour.
       *
       * This method of constructing an ID ensures that it'll be unique and
       * stable for a given Individual once the IndividualAggregator reaches
       * a quiescent state after startup. It guarantees that the ID will be
       * the same every time folks is used, until the Individual is linked
       * or unlinked to another Individual.
       *
       * We choose the most interesting Persona by ranking all the Personas
       * in the Individual by:
       *  1. store.is-primary-store
       *  2. store.trust-level
       *  3. store.id (alphabetically)
       *  4. persona.uid (alphabetically)
       *
       * Note that this heuristic shouldn't be changed without careful thought,
       * since stored references to IDs may be broken by the change.
       */
      if (this._persona_set.size > 0)
        {
          Persona? chosen_persona = null;

          foreach (var persona in this._persona_set)
            {
              if (chosen_persona == null)
                {
                  chosen_persona = persona;
                  continue;
                }

              var _chosen_persona = (!) chosen_persona;

              if ((_chosen_persona.store.is_primary_store == false &&
                      persona.store.is_primary_store == true) ||
                  (_chosen_persona.store.is_primary_store ==
                          persona.store.is_primary_store &&
                      _chosen_persona.store.trust_level >
                          persona.store.trust_level) ||
                  (_chosen_persona.store.is_primary_store ==
                          persona.store.is_primary_store &&
                      _chosen_persona.store.trust_level ==
                          persona.store.trust_level &&
                      _chosen_persona.store.id > persona.store.id) ||
                  (_chosen_persona.store.is_primary_store ==
                          persona.store.is_primary_store &&
                      _chosen_persona.store.trust_level ==
                          persona.store.trust_level &&
                      _chosen_persona.store.id == persona.store.id &&
                      _chosen_persona.uid > persona.uid)
                 )
               {
                 chosen_persona = persona;
               }
            }

          /* Hash the chosen persona's UID. We can guarantee chosen_persona is
           * non-null here because it's at least set to the first element of
           * this._persona_set, which we've checked is non-empty. */
          this.id = Checksum.compute_for_string (ChecksumType.SHA1,
              ((!) chosen_persona).uid);
        }
      else
        {
          /* Default if we have no personas. */
          this.id = "";
        }

      /* Update our aggregated fields and notify the changes */
      this._update_fields ();
    }

  internal void replace (Individual replacement_individual)
    {
      this._set_personas (null, replacement_individual);
    }

  /**
   * Anti-linked with a persona?
   *
   * Check whether this individual is anti-linked to {@link Persona} ``p`` at
   * all. If so, ``true`` will be returned — ``false`` will be returned
   * otherwise.
   *
   * Note that this will check for anti-links in either direction, since
   * anti-links are not necessarily symmetric.
   *
   * @param p persona to check for anti-links with
   * @return ``true`` if this individual is anti-linked with persona ``p``;
   * ``false``
   * otherwise
   * @since 0.7.3
   */
  public bool has_anti_link_with_persona (Persona p)
    {
      var al = p as AntiLinkable;

      foreach (var persona in this._persona_set)
        {
          var pl = persona as AntiLinkable;

          if ((al != null && ((!) al).has_anti_link_with_persona (persona)) ||
              (pl != null && ((!) pl).has_anti_link_with_persona (p)))
            {
              return true;
            }
        }

      return false;
    }

  /**
   * Anti-linked with an individual?
   *
   * Check whether this individual is anti-linked to any of the {@link Persona}s
   * in {@link Folks.Individual} ``i``. If so, ``true`` will be returned —
   * ``false`` will be returned otherwise.
   *
   * Note that this will check for anti-links in either direction, since
   * anti-links are not necessarily symmetric.
   *
   * @param i individual to check for anti-links with
   * @return ``true`` if this individual is anti-linked with individual ``i``;
   * ``false`` otherwise
   * @since 0.7.3
   */
  public bool has_anti_link_with_individual (Individual i)
    {
      foreach (var p in i.personas)
        {
          if (this.has_anti_link_with_persona (p) == true)
            {
              return true;
            }
        }

      return false;
    }
}
