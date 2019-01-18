/*
 * Copyright (C) 2010 Collabora Ltd.
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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using GLib;

/**
 * Alias for a contact.
 *
 * This allows representation of aliases for contacts, where the user has chosen
 * their own name for the contact to better represent that contact to them. A
 * typical example of this is the use of user-chosen aliases for contacts in
 * instant messaging programs.
 */
public interface Folks.AliasDetails : Object
{
  /**
   * An alias for the contact.
   *
   * An alias is a user-given name, to be used in UIs as the sole way to
   * represent the contact to the user.
   *
   * This may not be ``null``: an empty string represents an unset alias.
   */
  public abstract string alias { get; set; }

  /**
   * Change the contact's alias.
   *
   * It's preferred to call this rather than setting {@link AliasDetails.alias}
   * directly, as this method gives error notification and will only return
   * once the alias has been written to the relevant backing store (or the
   * operation's failed).
   *
   * @param alias the new alias
   * @throws PropertyError if setting the alias failed
   * @since 0.6.2
   */
  public virtual async void change_alias (string alias) throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Alias is not writeable on this contact."));
    }
}
