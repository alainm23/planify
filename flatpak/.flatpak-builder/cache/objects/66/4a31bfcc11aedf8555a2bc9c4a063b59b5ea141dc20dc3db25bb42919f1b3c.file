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
 *       Marco Barisione <marco.barisione@collabora.co.uk>
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using GLib;

/**
 * The gender of a contact
 *
 * @since 0.3.5
 */
public enum Folks.Gender
{
  /**
   * The gender of the contact is unknown or the contact didn't specify it.
   */
  UNSPECIFIED,
  /**
   * The contact is male.
   */
  MALE,
  /**
   * The contact is female.
   */
  FEMALE
}

/**
 * Gender of a contact.
 *
 * This allows representation of the gender of a contact.
 *
 * @since 0.3.5
 */
public interface Folks.GenderDetails : Object
{
  /**
   * The gender of the contact.
   *
   * @since 0.3.5
   */
  public abstract Gender gender { get; set; }

  /**
   * Change the contact's gender.
   *
   * It's preferred to call this rather than setting
   * {@link GenderDetails.gender} directly, as this method gives error
   * notification and will only return once the gender has been written to the
   * relevant backing store (or the operation's failed).
   *
   * @param gender the contact's gender
   * @throws PropertyError if setting the gender failed
   * @since 0.6.2
   */
  public virtual async void change_gender (Gender gender) throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Gender is not writeable on this contact."));
    }
}
