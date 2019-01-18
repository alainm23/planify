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

using Folks;
using Gee;
using GLib;

/**
 * A persona subclass representing a single contact.
 *
 * This mocks up a ‘thin’ persona which implements none of the available
 * property interfaces provided by libfolks, and is designed as a base class to
 * be subclassed by personas which will implement one or more of these
 * interfaces. For example, {@link FolksDummy.FullPersona} is one such subclass
 * which implements all available interfaces.
 *
 * There are two sides to this class’ interface: the normal methods required by
 * {@link Folks.Persona}, such as
 * {@link Folks.Persona.linkable_property_to_links},
 * and the backend methods which should be called by test driver code to
 * simulate changes in the backing store providing this persona, such as
 * {@link FolksDummy.Persona.update_writeable_properties}. The ``update_``,
 * ``register_`` and ``unregister_`` prefixes are commonly used for backend
 * methods.
 *
 * All property changes for contact details of subclasses of
 * {@link FolksDummy.Persona} have a configurable delay before taking effect,
 * which can be controlled by {@link FolksDummy.Persona.property_change_delay}.
 *
 * The API in {@link FolksDummy} is unstable and may change wildly. It is
 * designed mostly for use by libfolks unit tests.
 *
 * @since 0.9.7
 */
public class FolksDummy.Persona : Folks.Persona
{
  private string[] _linkable_properties = new string[0];

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override string[] linkable_properties
    {
      get { return this._linkable_properties; }
    }

  private string[] _writeable_properties = new string[0];

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override string[] writeable_properties
    {
      get { return this._writeable_properties; }
    }

  /**
   * Create a new persona.
   *
   * Create a new persona for the {@link FolksDummy.PersonaStore} ``store``,
   * with the given construct-only properties.
   *
   * The persona’s {@link Folks.Persona.writeable_properties} are initialised to
   * the given ``store``’s
   * {@link Folks.PersonaStore.always_writeable_properties}. They may be updated
   * afterwards using {@link FolksDummy.Persona.update_writeable_properties}.
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
  public Persona (PersonaStore store, string contact_id,
      bool is_user = false, string[] linkable_properties = {})
    {
      var uid = Folks.Persona.build_uid (BACKEND_NAME, store.id, contact_id);
      var iid = store.id + ":" + contact_id;

      Object (display_id: contact_id,
              uid: uid,
              iid: iid,
              store: store,
              is_user: is_user);

      this._linkable_properties = linkable_properties;
      this._writeable_properties = this.store.always_writeable_properties;
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.9.7
   */
  public override void linkable_property_to_links (string prop_name,
      Folks.Persona.LinkablePropertyCallback callback)
    {
      if (prop_name == "im-addresses")
        {
          var persona = this as ImDetails;
          assert (persona != null);

          foreach (var protocol in persona.im_addresses.get_keys ())
            {
              var im_fds = persona.im_addresses.get (protocol);

              foreach (var im_fd in im_fds)
                {
                  callback (protocol + ":" + im_fd.value);
                }
            }
        }
      else if (prop_name == "local-ids")
        {
          var persona = this as LocalIdDetails;
          assert (persona != null);

          foreach (var id in persona.local_ids)
            {
              callback (id);
            }
        }
      else if (prop_name == "web-service-addresses")
        {
          var persona = this as WebServiceDetails;
          assert (persona != null);

          foreach (var web_service in persona.web_service_addresses.get_keys ())
            {
              var web_service_addresses =
                  persona.web_service_addresses.get (web_service);

              foreach (var ws_fd in web_service_addresses)
                {
                  callback (web_service + ":" + ws_fd.value);
                }
            }
        }
      else if (prop_name == "email-addresses")
        {
          var persona = this as EmailDetails;
          assert (persona != null);

          foreach (var email in persona.email_addresses)
            {
              callback (email.value);
            }
        }
      else
        {
          /* Chain up */
          base.linkable_property_to_links (prop_name, callback);
        }
    }


  /*
   * All the functions below here are to be used by testing code rather than by
   * libfolks clients. They form the interface which would normally be between
   * the Persona and a web service or backing store of some kind.
   */


  /**
   * Update the persona’s set of writeable properties.
   *
   * Update the {@link Folks.Persona.writeable_properties} property to contain
   * the union of {@link Folks.PersonaStore.always_writeable_properties} from
   * the persona’s store, and the given ``writeable_properties``.
   *
   * This should be used to simulate a change in the backing store for the
   * persona which affects the writeability of one or more of its properties.
   *
   * @since 0.9.7
   */
  public void update_writeable_properties (string[] writeable_properties)
    {
      var new_writeable_properties = new HashSet<string> ();

      foreach (var p in this.store.always_writeable_properties)
          new_writeable_properties.add (p);
      foreach (var p in writeable_properties)
          new_writeable_properties.add (p);

      /* Check for changes. */
      var changed = false;

      if (this._writeable_properties.length != new_writeable_properties.size)
        {
          changed = true;
        }
      else
        {
          foreach (var p in this._writeable_properties)
            {
              if (new_writeable_properties.contains (p) == false)
                {
                  changed = true;
                  break;
                }
            }
        }

      if (changed == true)
        {
          this._writeable_properties = new_writeable_properties.to_array ();
          this.notify_property ("writeable-properties");
        }
    }

  /**
   * Update the persona’s set of linkable properties.
   *
   * Update the {@link Folks.Persona.linkable_properties} property to contain
   * the given ``linkable_properties``.
   *
   * @param linkable_properties new set of linkable property names, in lower
   * case, hyphenated form
   * @since 0.9.7
   */
  public void update_linkable_properties (string[] linkable_properties)
    {
      var new_linkable_properties = new SmallSet<string> ();
      new_linkable_properties.add_all_array (linkable_properties);

      var old_linkable_properties = new SmallSet<string> ();
      old_linkable_properties.add_all_array (this._linkable_properties);

      if (!Folks.Internal.equal_sets<string> (old_linkable_properties,
              new_linkable_properties))
        {
          this._linkable_properties = linkable_properties;
          this.notify_property ("linkable-properties");
        }
    }

  /**
   * Delay between property changes and notifications.
   *
   * This sets an optional delay between client code requesting a property
   * change (e.g. by calling {@link Folks.NameDetails.change_nickname}) and the
   * property change taking place and a {@link Object.notify} signal being
   * emitted for it.
   *
   * Delays are in milliseconds. Negative delays mean that property change
   * notifications happen synchronously in the change method. A delay of 0
   * means that property change notifications happen in an idle callback
   * immediately after the change method. A positive delay means that property
   * change notifications happen that many milliseconds after the change method
   * is called.
   *
   * @since 0.9.7
   */
  protected int property_change_delay { get; set; default = 0; }

  /**
   * Callback to effect a property change in a backing store.
   *
   * This is called by {@link FolksDummy.Persona.change_property} after the
   * {@link FolksDummy.Persona.property_change_delay} has expired. It must
   * effect the property change in the simulated backing store, for example by
   * calling an ‘update’ method such as
   * {@link FolksDummy.FullPersona.update_nickname}.
   *
   * @since 0.9.7
   */
  protected delegate void ChangePropertyCallback ();

  /**
   * Change a property in the simulated backing store.
   *
   * This triggers a property change in the simulated backing store, applying
   * the current {@link FolksDummy.Persona.property_change_delay} before calling
   * the given ``callback`` which should actually effect the property change.
   *
   * @param property_name name of the property being changed
   * @param callback callback to call once the change delay has passed
   * @since 0.9.7
   */
  protected async void change_property (string property_name,
      ChangePropertyCallback callback)
    {
      if (this.property_change_delay < 0)
        {
          /* No delay. */
          callback ();
        }
      else if (this.property_change_delay == 0)
        {
          /* Idle delay. */
          Idle.add (() =>
            {
              callback ();
              this.change_property.callback ();
              return false;
            });

          yield;
        }
      else
        {
          /* Timed delay. */
          Timeout.add (this.property_change_delay, () =>
            {
              callback ();
              this.change_property.callback ();
              return false;
            });

          yield;
        }
    }
}
