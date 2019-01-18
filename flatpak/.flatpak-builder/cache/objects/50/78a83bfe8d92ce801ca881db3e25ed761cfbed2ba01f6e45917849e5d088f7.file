/*
 * Copyright (C) 2011 Collabora Ltd.
 * Copyright (C) 2011 Philip Withnall
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
 *       Raul Gutierrez Segales <raul.gutierrez.segales@collabora.co.uk>
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using GLib;

/**
 * Birthday details for a contact.
 *
 * This allows representation of the birth date and associated calendar event ID
 * of a contact.
 *
 * @since 0.4.0
 */
public interface Folks.BirthdayDetails : Object
{
  /**
   * The birthday of the {@link Persona} and {@link Individual}. This
   * is assumed to be in UTC.
   *
   * If this is ``null``, the contact's birthday isn't known.
   *
   * @since 0.4.0
   */
  public abstract DateTime? birthday { get; set; }

  /**
   * Change the contact's birthday.
   *
   * It's preferred to call this rather than setting
   * {@link BirthdayDetails.birthday} directly, as this method gives error
   * notification and will only return once the birthday has been written to the
   * relevant backing store (or the operation's failed).
   *
   * @param birthday the new birthday (or ``null`` to unset the birthday)
   * @throws PropertyError if setting the birthday failed
   * @since 0.6.2
   */
  public virtual async void change_birthday (DateTime? birthday)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Birthday is not writeable on this contact."));
    }

  /**
   * The event ID of the birthday event from the source calendar.
   *
   * If this is ``null``, the birthday event is unknown. The semantics of the
   * event ID are left unspecified by folks.
   *
   * @since 0.4.0
   */
  public abstract string? calendar_event_id { get; set; }

  /**
   * Change the contact's birthday event ID.
   *
   * It's preferred to call this rather than setting
   * {@link BirthdayDetails.calendar_event_id} directly, as this method gives
   * error notification and will only return once the event has been written to
   * the relevant backing store (or the operation's failed).
   *
   * @param event_id the new birthday event ID (or ``null`` to unset the event
   * ID)
   * @throws PropertyError if setting the birthday event ID failed
   * @since 0.6.2
   */
  public virtual async void change_calendar_event_id (string? event_id)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Birthday event ID is not writeable on this contact."));
    }
}
