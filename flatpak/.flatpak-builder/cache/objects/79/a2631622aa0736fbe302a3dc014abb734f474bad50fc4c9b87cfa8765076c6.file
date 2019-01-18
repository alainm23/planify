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

using Gee;
using GLib;

/**
 * This interface represents the list of {@link Persona.iid}s
 * corresponding to {@link Persona}s from backends with write
 * support so that they can be linked.
 *
 * This is necessary so that personas from the same backend
 * can be linked together even if they have no other linkeable
 * properties set.
 *
 * @since 0.5.0
 */
public interface Folks.LocalIdDetails : Object
{
  /**
   * The IIDs corresponding to {@link Persona}s in a
   * backend that we fully trust.
   *
   * @since 0.5.1
   */
  public abstract Set<string> local_ids { get; set; }

  /**
   * Change the contact's local IDs.
   *
   * It's preferred to call this rather than setting
   * {@link LocalIdDetails.local_ids} directly, as this method gives error
   * notification and will only return once the local IDs have been written to
   * the relevant backing store (or the operation's failed).
   *
   * @param local_ids the set of local IDs
   * @throws PropertyError if setting the local IDs failed
   * @since 0.6.2
   */
  public virtual async void change_local_ids (Set<string> local_ids)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Local IDs are not writeable on this contact."));
    }
}
