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
 * Avatar for a contact.
 *
 * This allows avatars to be associated with contacts. An avatar is a small
 * image file which represents the contact, such as a photo of them.
 *
 * @since 0.6.0
 */
public interface Folks.AvatarDetails : Object
{
  /**
   * An avatar for the contact.
   *
   * The avatar may be ``null`` if unset. Otherwise, the image data may be
   * asynchronously loaded using the methods of the {@link GLib.LoadableIcon}
   * implementation.
   *
   * @since 0.6.0
   */
  public abstract LoadableIcon? avatar { get; set; }

  /**
   * Change the contact's avatar.
   *
   * It's preferred to call this rather than setting
   * {@link AvatarDetails.avatar} directly, as this method gives error
   * notification and will only return once the avatar has been written to the
   * relevant backing store (or the operation's failed).
   *
   * @param avatar the new avatar (or ``null`` to unset the avatar)
   * @throws PropertyError if setting the avatar failed
   * @since 0.6.2
   */
  public virtual async void change_avatar (LoadableIcon? avatar)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Avatar is not writeable on this contact."));
    }
}
