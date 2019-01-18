/*
 * Copyright (C) 2013, 2015 Collabora Ltd.
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
 *       Rodrigo Moya <rodrigo@gnome.org>
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using GLib;
using Gee;

/**
 * Object representing an arbitrary field that can have some parameters
 * associated with it. This is intended to be as general-purpose as, for
 * example, a vCard property. See the documentation for
 * {@link Folks.ExtendedInfo} for information on when using this object is
 * appropriate.
 *
 * See {@link Folks.AbstractFieldDetails} for details on common parameter names
 * and values.
 *
 * @since 0.11.0
 */
public class Folks.ExtendedFieldDetails : AbstractFieldDetails<string>
{
  /**
   * Create a new ExtendedFieldDetails.
   *
   * @param value the value of the field, which may be the empty string
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to
   * an empty map of parameters.
   *
   * @return a new ExtendedFieldDetails
   *
   * @since 0.11.0
   */
  public ExtendedFieldDetails (string value,
      MultiMap<string, string>? parameters = null)
    {
      this.value = value;
      if (parameters != null)
          this.parameters = (!) parameters;
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.11.0
   */
  public override bool equal (AbstractFieldDetails<string> that)
    {
      return base.equal (that);
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.11.0
   */
  public override uint hash ()
    {
      return base.hash ();
    }
}

/**
 * Arbitrary field interface.
 *
 * This interface allows clients to store arbitrary fields for contacts in
 * backends that support it.
 *
 * This interface should be used for application-specific data, in which case
 * the application should use the vCard approach to prefixing non-standard
 * property names: `X-[APPLICATION NAME]-*’. Note that this is a global
 * namespace, shared between all consumers of the backend’s data, so please
 * namespace application-specific data with the application’s name.
 *
 * This interface should not be used for more general-purpose data which could
 * be better represented with a type-safe interface implemented in libfolks.
 * It must not be used for data which is already represented with a type-safe
 * interface in libfolks.
 *
 * A good example of data which could be stored on this interface is an e-mail
 * application’s setting of whether a content prefers to receive HTML or
 * plaintext e-mail.
 *
 * A good example of data which should not be stored on this interface is a
 * contact’s anniversary. That should be added in a separate interface in
 * libfolks.
 *
 * @since 0.11.0
 */
public interface Folks.ExtendedInfo : Object
{
  /**
   * Retrieve the value for an arbitrary field.
   *
   * @return The value of the extended field, which may be empty, or `null` if
   *   the field is not set
   *
   * @since 0.11.0
   */
  public abstract ExtendedFieldDetails? get_extended_field (string name);

  /**
   * Change the value of an arbitrary field.
   *
   * @param name name of the arbitrary field to change value
   * @param value new value for the arbitrary field
   * @throws PropertyError if setting the value failed
   *
   * @since 0.11.0
   */
  public virtual async void change_extended_field (
      string name, ExtendedFieldDetails value) throws PropertyError
    {
      /* Default implementation */
      throw new PropertyError.NOT_WRITEABLE (
          _("Extended fields are not writeable on this contact."));
    }

  /**
   * Remove an arbitrary field.
   *
   * @param name name of the arbitrary field to remove
   * @throws PropertyError if removing the property failed
   *
   * @since 0.11.0
   */
  public virtual async void remove_extended_field (string name)
      throws PropertyError
    {
      /* Default implementation */
      throw new PropertyError.NOT_WRITEABLE (
          _("Extended fields are not writeable on this contact."));
    }
}
