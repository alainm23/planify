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

/**
 * Trust level for a {@link PersonaStore}'s {@link Persona}s for linking
 * purposes.
 *
 * Trust levels are set internally by the backends, and must not be modified by
 * clients.
 *
 * @since 0.1.13
 */
public enum Folks.PersonaStoreTrust
{
  /**
   * The {@link Persona}s aren't trusted at all, and cannot be linked.
   *
   * This should be used for {@link PersonaStore}s where even the
   * {@link Persona} UID could be maliciously edited to corrupt {@link Persona}
   * links, or where the UID changes regularly.
   *
   * @since 0.1.13
   */
  NONE,

  /**
   * Only the {@link Persona.uid} property is trusted for linking.
   *
   * In practice, this means that {@link Persona}s from this
   * {@link PersonaStore} will not contribute towards the linking process, but
   * can be linked together by their UIDs using data from {@link Persona}s from
   * a fully-trusted {@link PersonaStore}.
   *
   * @since 0.1.13
   */
  PARTIAL,

  /**
   * Every property in {@link Persona.linkable_properties} is trusted.
   *
   * This should only be used for user-controlled {@link PersonaStore}s, as if a
   * remote store is compromised, malicious changes could be made to its data
   * which corrupt the user's {@link Persona} links.
   *
   * @since 0.1.13
   */
  FULL
}
/**
 * Errors from {@link PersonaStore}s.
 */
public errordomain Folks.PersonaStoreError
{
  /**
   * An argument to the method was invalid.
   */
  INVALID_ARGUMENT,

  /**
   * Creation of a {@link Persona} failed.
   */
  CREATE_FAILED,

  /**
   * Such an operation may not be performed on a {@link Persona} with
   * {@link Persona.is_user} set to ``true``.
   *
   * @since 0.3.0
   */
  UNSUPPORTED_ON_USER,

  /**
   * The {@link PersonaStore} was offline (ie, this is a temporary failure).
   *
   * @since 0.3.0
   */
  STORE_OFFLINE,

  /**
   * The {@link PersonaStore} doesn't support write operations.
   *
   * @since 0.3.4
   */
  READ_ONLY,

  /**
   * The operation was denied due to not having sufficient permissions.
   *
   * @since 0.6.0
   */
  PERMISSION_DENIED,

  /**
   * Removal of a {@link Persona} failed. This is a generic error which is used
   * if no other error code (such as, e.g.,
   * {@link PersonaStoreError.PERMISSION_DENIED}) is applicable.
   *
   * @since 0.6.0
   */
  REMOVE_FAILED,

  /**
   * Such an operation may only be performed on a {@link Persona} with
   * {@link Persona.is_user} set to ``true``.
   *
   * @since 0.6.4
   */
  UNSUPPORTED_ON_NON_USER,
}

/**
 * Definition of the available fields to be looked up with
 * {@link PersonaStore.detail_key}.
 *
 * @since 0.5.0
 */
/* NOTE: Must be kept in sync with
 * {@link Folks.PersonaStore._PERSONA_DETAIL}. */
public enum Folks.PersonaDetail
{
  /**
   * Invalid field for use in error returns.
   *
   * @since 0.6.2
   */
  INVALID = -1,

  /**
   * Field for {@link AliasDetails.alias}.
   *
   * @since 0.5.0
   */
  ALIAS = 0,

  /**
   * Field for {@link AvatarDetails.avatar}.
   *
   * @since 0.5.0
   */
  AVATAR,

  /**
   * Field for {@link BirthdayDetails.birthday}.
   *
   * @since 0.5.0
   */
  BIRTHDAY,

  /**
   * Field for {@link EmailDetails.email_addresses}.
   *
   * @since 0.5.0
   */
  EMAIL_ADDRESSES,

  /**
   * Field for {@link NameDetails.full_name}.
   *
   * @since 0.5.0
   */
  FULL_NAME,

  /**
   * Field for {@link GenderDetails.gender}.
   *
   * @since 0.5.0
   */
  GENDER,

  /**
   * Field for {@link ImDetails.im_addresses}.
   *
   * @since 0.5.0
   */
  IM_ADDRESSES,

  /**
   * Field for {@link FavouriteDetails.is_favourite}.
   *
   * @since 0.5.0
   */
  IS_FAVOURITE,

  /**
   * Field for {@link LocalIdDetails.local_ids}.
   *
   * @since 0.5.0
   */
  LOCAL_IDS,

  /**
   * Field for {@link LocationDetails.location}.
   *
   * @since 0.9.2
   */
  LOCATION,

  /**
   * Field for {@link NameDetails.nickname}.
   *
   * @since 0.5.0
   */
  NICKNAME,

  /**
   * Field for {@link NoteDetails.notes}.
   *
   * @since 0.5.0
   */
  NOTES,

  /**
   * Field for {@link PhoneDetails.phone_numbers}.
   *
   * @since 0.5.0
   */
  PHONE_NUMBERS,

  /**
   * Field for {@link PostalAddressDetails.postal_addresses}.
   *
   * @since 0.5.0
   */
  POSTAL_ADDRESSES,

  /**
   * Field for {@link RoleDetails.roles}.
   *
   * @since 0.5.0
   */
  ROLES,

  /**
   * Field for {@link NameDetails.structured_name}.
   *
   * @since 0.5.0
   */
  STRUCTURED_NAME,

  /**
   * Field for {@link UrlDetails.urls}.
   *
   * @since 0.5.0
   */
  URLS,

  /**
   * Field for {@link WebServiceDetails.web_service_addresses}.
   *
   * @since 0.5.0
   */
  WEB_SERVICE_ADDRESSES,

  /**
   * Field for {@link GroupDetails.groups}.
   *
   * @since 0.6.2
   */
  GROUPS,

  /**
   * Field for {@link InteractionDetails.im_interaction_count}.
   *
   * @since 0.7.1
   */
  IM_INTERACTION_COUNT,

  /**
   * Field for {@link InteractionDetails.last_im_interaction_datetime}.
   *
   * @since 0.7.1
   */
  LAST_IM_INTERACTION_DATETIME,

  /**
   * Field for {@link InteractionDetails.call_interaction_count}.
   *
   * @since 0.7.1
   */
  CALL_INTERACTION_COUNT,

  /**
   * Field for {@link InteractionDetails.last_call_interaction_datetime}.
   *
   * @since 0.7.1
   */
  LAST_CALL_INTERACTION_DATETIME,

  /**
   * Field for {@link AntiLinkable.anti_links}.
   *
   * @since 0.7.3
   */
  ANTI_LINKS,

  /**
   * Field for {@link ExtendedFieldDetails}.
   *
   * @since 0.11.0
   */
  EXTENDED_INFO,
}

/**
 * A store for {@link Persona}s.
 *
 * After creating a PersonaStore instance, you must connect to the
 * {@link PersonaStore.personas_changed} signal, //then// call
 * {@link PersonaStore.prepare}, otherwise a race condition may occur between
 * emission of {@link PersonaStore.personas_changed} and your code connecting to
 * it.
 */
public abstract class Folks.PersonaStore : Object
{
  construct
    {
      debug ("Constructing PersonaStore ‘%s’ (%p)", this.id, this);
    }

  ~PersonaStore ()
    {
      debug ("Destroying PersonaStore ‘%s’ (%p)", this.id, this);
    }

  /**
   * The following list of properties are the basic keys
   * that each PersonaStore with write capabilities should
   * support for {@link PersonaStore.add_persona_from_details}.
   *
   * Note that these aren't the only valid keys; backends are
   * allowed to support keys beyond the ones defined here
   * which might be specific to the backend in question.
   *
   * NOTE: MUST be kept in sync with {@link Folks.PersonaDetail}.
   *
   * @since 0.5.0
   */
  private const string _PERSONA_DETAIL[] = {
    "alias",
    "avatar",
    "birthday",
    "email-addresses",
    "full-name",
    "gender",
    "im-addresses",
    "is-favourite",
    "local-ids",
    "location",
    "nickname",
    "notes",
    "phone-numbers",
    "postal-addresses",
    "roles",
    "structured-name",
    "urls",
    "web-service-addresses",
    "groups",
    "im-interaction-count",
    "last-im-interaction-datetime",
    "call-interaction-count",
    "last-call-interaction-datetime",
    "anti-links",
    "extended-info"
  };

  /**
   * Returns the key corresponding to @detail, for use in
   * the details param of {@link PersonaStore.add_persona_from_details}.
   *
   * @param detail the {@link PersonaDetail} to lookup
   * @return the corresponding property name, or ``null`` if ``detail`` is
   * invalid
   *
   * @since 0.5.0
   */
  public static unowned string? detail_key (Folks.PersonaDetail detail)
    {
      if (detail == PersonaDetail.INVALID ||
          detail >= PersonaStore._PERSONA_DETAIL.length)
        {
          return null;
        }

      return PersonaStore._PERSONA_DETAIL[detail];
    }

  /**
   * Emitted when one or more {@link Persona}s are added to or removed from
   * the store.
   *
   * This will not be emitted until after {@link PersonaStore.prepare} has been
   * called.
   *
   * @param added a set of {@link Persona}s which have been removed
   * @param removed a set of {@link Persona}s which have been removed
   * @param message a string message from the backend, if any
   * @param actor the {@link Persona} who made the change, if known
   * @param reason the reason for the change
   *
   * @since 0.5.1
   */
  public signal void personas_changed (Set<Persona> added,
      Set<Persona> removed,
      string? message,
      Persona? actor,
      GroupDetails.ChangeReason reason);

  /* Emit the personas-changed signal, turning null parameters into empty sets
   * and only passing a read-only view to the signal handlers. */
  protected void _emit_personas_changed (Set<Persona>? added,
      Set<Persona>? removed,
      string? message = null,
      Persona? actor = null,
      GroupDetails.ChangeReason reason = GroupDetails.ChangeReason.NONE)
    {
      var _added = added;
      var _removed = removed;

      if ((added == null || ((!) added).size == 0) &&
          (removed == null || ((!) removed).size == 0))
        {
          /* Don't bother signalling if nothing's changed */
          return;
        }
      else if (added == null)
        {
          _added = new HashSet<Persona> ();
        }
      else if (removed == null)
        {
          _removed = new HashSet<Persona> ();
        }

      Internal.profiling_point ("emitting PersonaStore::personas-changed " +
          "(ID: %s, count: %u)", this.id, _added.size + _removed.size);

      // We've now guaranteed that both _added and _removed are non-null.
      this.personas_changed (((!) _added).read_only_view,
          ((!) _removed).read_only_view, message, actor, reason);
    }

  /**
   * Emitted when the backing store for this PersonaStore has been removed.
   *
   * At this point, the PersonaStore and all its {@link Persona}s are invalid,
   * so any client referencing it should unreference it.
   *
   * This will not be emitted until after {@link PersonaStore.prepare} has been
   * called.
   */
  public abstract signal void removed ();

  /**
   * The type of PersonaStore this is.
   *
   * This is the same for all PersonaStores provided by a given {@link Backend}.
   *
   * This is guaranteed to always be available; even before
   * {@link PersonaStore.prepare} is called. It is immutable over the life of
   * the {@link PersonaStore}.
   */
  public abstract string type_id
    {
      /* Note: the type_id must not contain colons because the primary writeable
       * store is configured, either via GSettings or the FOLKS_PRIMARY_STORE
       * env variable, with a string of the form 'type_id:store_id'. */
      get;
    }

  /**
   * The human-readable, service-specific name used to represent the
   * PersonaStore to the user.
   *
   * For example: ``foo@@xmpp.example.org``.
   *
   * This should be used whenever the user needs to be presented with a
   * familiar, service-specific name. For instance, in a prompt for the user to
   * select a specific IM account from which to initiate a chat.
   *
   * This is not guaranteed to be unique even within this PersonaStore's
   * {@link Backend}. Its value may change throughout the life of the store.
   *
   * @since 0.1.13
   */
  public string display_name { get; construct; }

  /**
   * The instance identifier for this PersonaStore.
   *
   * Since each {@link Backend} can provide multiple different PersonaStores
   * for different accounts or servers (for example), they each need an ID
   * which is unique within the backend.
   *
   * It is immutable over the life of the {@link PersonaStore}.
   */
  public string id { get; construct; }

  /**
   * The {@link Persona}s exposed by this PersonaStore.
   *
   * @since 0.5.1
   */
  public abstract Map<string, Persona> personas { get; }

  /**
   * Whether this {@link PersonaStore} can add {@link Persona}s.
   *
   * This value may change throughout the life of the {@link PersonaStore}.
   *
   * @since 0.3.1
   */
  public abstract MaybeBool can_add_personas { get; default = MaybeBool.UNSET; }

  /**
   * Whether this {@link PersonaStore} can set the alias of {@link Persona}s.
   *
   * @since 0.3.1
   */
  [Version (deprecated = true, deprecated_since = "0.6.3.1",
      replacement = "PersonaStore.always_writeable_properties")]
  public abstract MaybeBool can_alias_personas
    {
      get;
      default = MaybeBool.UNSET;
    }

  /**
   * Whether this {@link PersonaStore} can set the groups of {@link Persona}s.
   *
   * @since 0.3.1
   */
  [Version (deprecated = true, deprecated_since = "0.6.3.1",
      replacement = "PersonaStore.always_writeable_properties")]
  public abstract MaybeBool can_group_personas
    {
      get;
      default = MaybeBool.UNSET;
    }

  /**
   * Whether this {@link PersonaStore} can remove {@link Persona}s.
   *
   * This value may change throughout the life of the {@link PersonaStore}.
   *
   * @since 0.3.1
   */
  public abstract MaybeBool can_remove_personas
    {
      get;
      default = MaybeBool.UNSET;
    }

  /**
   * Whether {@link PersonaStore.prepare} has successfully completed for this
   * store.
   *
   * It’s guaranteed that this will only ever change from ``false`` to ``true``
   * in the lifetime of the {@link PersonaStore}.
   *
   * @since 0.3.0
   */
  public abstract bool is_prepared { get; default = false; }

  /**
   * Whether the store has reached a quiescent state. This will happen at some
   * point after {@link PersonaStore.prepare} has successfully completed for the
   * store. A store is in a quiescent state when all the {@link Persona}s that
   * it originally knows about have been loaded.
   *
   * It's guaranteed that this property's value will only ever change after
   * {@link IndividualAggregator.is_prepared} has changed to ``true``.
   *
   * @since 0.6.2
   */
  public abstract bool is_quiescent { get; default = false; }

   /**
   * Whether the PersonaStore is writeable.
   *
   * Only if a PersonaStore is writeable will its {@link Persona}s be updated by
   * changes to the {@link Individual}s containing them, and those changes then
   * be written out to the relevant backing store.
   *
   * If this property is ``false``, it doesn't mean that {@link Persona}s in
   * this persona store aren't writeable at all. If their properties are updated
   * through the {@link Persona}, rather than through the {@link Individual}
   * containing that persona, changes may be propagated to the backing store.
   *
   * PersonaStores must not set this property themselves; it will be set as
   * appropriate by the {@link IndividualAggregator}.
   *
   * @since 0.1.13
   */
  [Version (deprecated = true, deprecated_since = "0.6.3",
      replacement = "PersonaStore.is_primary_store")]
  public bool is_writeable { get; set; default = false; }

  private PersonaStoreTrust _trust_level = PersonaStoreTrust.NONE;

  /**
   * The trust level of the PersonaStore for linking.
   *
   * Each {@link PersonaStore} is assigned a trust level by the
   * IndividualAggregator, designating whether to trust the properties of its
   * {@link Persona}s for linking to produce {@link Individual}s.
   *
   * This value may change throughout the life of the {@link PersonaStore}.
   *
   * The trust level may be queried by clients, but must not be set by them. The
   * setter for this property is for libfolks internal use only.
   *
   * @see PersonaStoreTrust
   * @since 0.1.13
   */
  public PersonaStoreTrust trust_level
    {
      get
        {
          return this._trust_level;
        }

      /* FIXME: At the next API break, make this an abstract property and have
       * implemented by the backends, to avoid exposing the setter in the C
       * API. The IndividualAggregator can always disregard the backend’s
       * suggested trust level.
       *
       * https://bugzilla.gnome.org/show_bug.cgi?id=722421 */
      set
        {
          if (value > trust_level)
            {
              this._trust_level = value;
              this.notify_property ("trust-level");
            }
          else
            {
              debug ("Unable to lower Persona Store trust_level");
            }
        }
    }

  /**
   * The names of the properties of the {@link Persona}s in this store which are
   * always writeable.
   *
   * If a property name is in this list, setting the property on a persona
   * should result in the updated value being stored in the backend's permanent
   * storage (unless it gets rejected due to being invalid, or a different error
   * occurs).
   *
   * This property value is guaranteed to be constant for a given persona store,
   * but may vary between persona stores in the same backend. It's guaranteed
   * that this will always be a subset of the value of
   * {@link Persona.writeable_properties} for the personas in this persona
   * store.
   *
   * @since 0.6.2
   */
  public abstract string[] always_writeable_properties { get; }

  /**
   * Prepare the PersonaStore for use.
   *
   * This connects the PersonaStore to whichever backend-specific services it
   * requires to be able to provide {@link Persona}s. This should be called
   * //after// connecting to the {@link PersonaStore.personas_changed} signal,
   * or a race condition could occur, with the signal being emitted before your
   * code has connected to it, and {@link Persona}s getting "lost" as a result.
   *
   * This is normally handled transparently by the {@link IndividualAggregator}.
   *
   * If this function throws an error, the PersonaStore will not be functional.
   *
   * This function is guaranteed to be idempotent (since version 0.3.0).
   *
   * Concurrent calls to this function from different threads will block until
   * preparation has completed. However, concurrent calls to this function from
   * a single thread might not, i.e. the first call will block but subsequent
   * calls might return before the first one. (Though they will be safe in every
   * other respect.)
   *
   * @throws GLib.Error if preparing the backend-specific services failed — this
   * will be a backend-specific error
   *
   * @since 0.1.11
   */
  public abstract async void prepare () throws GLib.Error;

  /**
   * Flush any pending changes to the PersonaStore's backing store.
   *
   * PersonaStores may (transparently) implement caching or I/O queueing which
   * means that changes to their {@link Persona}s may not be immediately written
   * to the PersonaStore's backing store. Calling this function will force all
   * pending changes to be flushed to the backing store.
   *
   * This must not be called before {@link PersonaStore.prepare}.
   *
   * @since 0.1.17
   */
  public virtual async void flush ()
    {
      /* Default implementation doesn't have to do anything */
    }

  /**
   * Add a new {@link Persona} to the PersonaStore.
   *
   * The {@link Persona} will be created by the PersonaStore backend from the
   * key-value pairs given in ``details``.
   *
   * All additions through this function will later be emitted through the
   * personas-changed signal to be notified of the new {@link Persona}. The
   * return value is purely for convenience, since it can be complicated to
   * correlate the provided details with the final Persona.
   *
   * If the store is offline (or {@link PersonaStore.prepare} hasn't yet been
   * called successfully), this function will throw
   * {@link PersonaStoreError.STORE_OFFLINE}. It's the responsibility of the
   * caller to cache details and re-try this function if it wishes to make
   * offline adds work.
   *
   * If the details are not recognised or are invalid,
   * {@link PersonaStoreError.INVALID_ARGUMENT} will be thrown. A default set
   * of possible details are defined by {@link Folks.PersonaDetail} but backends
   * can either support a subset or superset of the suggested defaults.
   *
   * If a {@link Persona} with the given details already exists in the store, no
   * error will be thrown and this function will return ``null``.
   *
   * @param details a key-value map of details to use in creating the new
   * {@link Persona}
   *
   * @return the new {@link Persona} or ``null`` if the corresponding Persona
   * already existed. If non-``null``, the new {@link Persona} will also be
   * amongst the {@link Persona}(s) in a future emission of
   * {@link PersonaStore.personas_changed}.
   * @throws PersonaStoreError if adding the persona failed
   */
  public abstract async Persona? add_persona_from_details (
      HashTable<string, Value?> details) throws Folks.PersonaStoreError;

  /**
   * Remove a {@link Persona} from the PersonaStore.
   *
   * It isn't guaranteed that the Persona will actually be removed by the time
   * this asynchronous function finishes. The successful removal of the Persona
   * will be signalled through emission of
   * {@link PersonaStore.personas_changed}.
   *
   * If the store is offline (or {@link PersonaStore.prepare} hasn't yet been
   * called successfully), this function will throw
   * {@link PersonaStoreError.STORE_OFFLINE}. It's the responsibility of the
   * caller to cache details and re-try this function if it wishes to make
   * offline removals work.
   *
   * @param persona the {@link Persona} to remove
   * @throws PersonaStoreError if removing the persona failed
   *
   * @since 0.1.11
   */
  public abstract async void remove_persona (Persona persona)
      throws Folks.PersonaStoreError;

  /**
   * Whether this {@link PersonaStore} is the primary store to be used for
   * linking {@link Persona}s.
   *
   * @since 0.6.3
   */
  public bool is_primary_store { get; internal set; default = false; }

  /* The setter folks_persona_store_set_is_user_set_default() is redeclared
   * in folks/redeclare-internal-api.h so that libfolks-eds can use it.
   * If you alter this property, check the generated C and update that
   * header if necessary. https://bugzilla.gnome.org/show_bug.cgi?id=697354 */
  /**
   * Whether this {@link PersonaStore} is marked as the default in its backend
   * by the user.
   *
   * i.e. A {@link PersonaStore} for the EDS backend would set this to ``true``
   * if it represents the user’s default address book.
   *
   * @since 0.6.3
   */
  public bool is_user_set_default { get; internal set; default = false; }
}
