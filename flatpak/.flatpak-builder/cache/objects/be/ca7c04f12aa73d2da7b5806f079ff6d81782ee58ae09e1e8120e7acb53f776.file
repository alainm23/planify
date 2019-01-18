/*
 * Copyright (C) 2010-2011 Collabora Ltd.
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

/**
 * The possible presence states an object implementing {@link PresenceDetails}
 * could be in.
 *
 * These closely follow the
 * [[http://telepathy.freedesktop.org/spec/Connection_Interface_Simple_Presence.html#Connection_Presence_Type|SimplePresence]]
 * interface in the Telepathy specification.
 */
public enum Folks.PresenceType
{
  /**
   * never set
   */
  UNSET,
  /**
   * offline
   */
  OFFLINE,
  /**
   * available
   */
  AVAILABLE,
  /**
   * away from keyboard
   */
  AWAY,
  /**
   * away from keyboard for an extended period of time
   */
  EXTENDED_AWAY,
  /**
   * also known as "invisible" or "appear offline"
   */
  HIDDEN,
  /**
   * at keyboard, but too busy to chat
   */
  BUSY,
  /**
   * presence not received from server
   */
  UNKNOWN,
  /**
   * an error occurred with fetching the presence
   */
  ERROR
}

/**
 * Interface exposing a {@link Persona}'s or {@link Individual}'s presence;
 * their current availability, such as for chatting.
 *
 * If the {@link Backend} providing the {@link Persona} doesn't support
 * presence, the {@link Persona}'s ``presence_type`` will be set to
 * {@link PresenceType.UNSET} and their ``presence_message`` will be an empty
 * string.
 */
public interface Folks.PresenceDetails : Object
{
  /**
   * The contact's presence type.
   *
   * Each contact can have one and only one presence type at any one time,
   * representing their availability for communication. The default presence
   * type is {@link PresenceType.UNSET}.
   */
  public abstract Folks.PresenceType presence_type
    {
      get; set; default = Folks.PresenceType.UNSET;
    }

  /**
   * The contact's presence message.
   *
   * This is a short message written by the contact to add detail to their
   * presence type ({@link Folks.PresenceDetails.presence_type}). If the contact
   * hasn't set a message, it will be an empty string.
   */
  public abstract string presence_message { get; set; default = ""; }

  /**
   * The contact's client types.
   *
   * One can connect to instant messaging networks on a huge variety of devices,
   * from PCs, to phones to consoles.
   * The client types are represented in strings, using the values
   * [[http://xmpp.org/registrar/disco-categories.html#client|documented by the XMPP registrar]]
   *
   * @since 0.9.5
   */
  public abstract string[] client_types { get; set; }

  /**
   * The contact's detailed presence status.
   *
   * This is a more detailed representation of the contact's presence than
   * {@link PresenceDetails.presence_type}. It may be empty, or one of a
   * well-known set of strings, as defined in the Telepathy specification:
   * [[http://telepathy.freedesktop.org/spec/Connection_Interface_Simple_Presence.html#description|Telepathy Specification]]
   *
   * @since 0.6.0
   */
  public abstract string presence_status { get; set; default = ""; }

  /* Rank the presence types for comparison purposes, with higher numbers
   * meaning more available */
  private static int _type_availability (PresenceType type)
    {
      switch (type)
        {
          case PresenceType.UNSET:
            return 0;
          case PresenceType.UNKNOWN:
            return 1;
          case PresenceType.ERROR:
            return 2;
          case PresenceType.OFFLINE:
            return 3;
          case PresenceType.HIDDEN:
            return 4;
          case PresenceType.EXTENDED_AWAY:
            return 5;
          case PresenceType.AWAY:
            return 6;
          case PresenceType.BUSY:
            return 7;
          case PresenceType.AVAILABLE:
            return 8;
          default:
            return 1;
        }
    }

  /**
   * The default message for a presence type.
   *
   * @param type a {@link PresenceType} for which to retrieve a translated
   * display string
   * @return a default translated display string for the given
   * {@link PresenceType}
   * @since 0.7.1
   */
  public static unowned string get_default_message_from_type (PresenceType type)
    {
      switch (type)
        {
          default:
          case PresenceType.UNKNOWN:
            return _("Unknown status");
          case PresenceType.OFFLINE:
            return _("Offline");
          case PresenceType.UNSET:
            return "";
          case PresenceType.ERROR:
            return _("Error");
          case PresenceType.AVAILABLE:
            return _("Available");
          case PresenceType.AWAY:
            return _("Away");
          case PresenceType.EXTENDED_AWAY:
            return _("Extended away");
          case PresenceType.BUSY:
            return _("Busy");
          case PresenceType.HIDDEN:
            return _("Hidden");
        }
    }

  /**
   * Compare two {@link PresenceType}s.
   *
   * ``0`` will be returned if the types are equal, a positive number will be
   * returned if ``type_a`` is more available than ``type_b``, and a negative
   * number will be returned if the opposite is true.
   *
   * @param type_a the first {@link PresenceType} to compare
   * @param type_b the second {@link PresenceType} to compare
   * @return a number representing the similarity of the two types
   * @since 0.1.11
   */
  public static int typecmp (PresenceType type_a, PresenceType type_b)
    {
      return (PresenceDetails._type_availability (type_a) -
          PresenceDetails._type_availability (type_b));
    }

  /**
   * Whether the contact is online.
   *
   * This will be ``true`` if the contact's presence type is higher than
   * {@link PresenceType.OFFLINE}, as determined by
   * {@link PresenceDetails.typecmp}.
   *
   * @return ``true`` if the contact is online, ``false`` otherwise
   */
  public bool is_online ()
    {
      return (typecmp (this.presence_type, PresenceType.OFFLINE) > 0);
    }
}
