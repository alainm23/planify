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
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using GLib;
using Gee;

/**
 * Object representing a email address that can have some parameters
 * associated with it.
 *
 * See {@link Folks.AbstractFieldDetails} for details on common parameter names
 * and values.
 *
 * @since 0.6.0
 */
public class Folks.EmailFieldDetails : AbstractFieldDetails<string>
{
  /**
   * Create a new EmailFieldDetails.
   *
   * @param value the value of the field, which should be a valid, non-empty
   * e-mail address
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to
   * an empty map of parameters.
   *
   * @return a new EmailFieldDetails
   *
   * @since 0.6.0
   */
  public EmailFieldDetails (string value,
      MultiMap<string, string>? parameters = null)
    {
      if (value == "")
        {
          warning ("Empty e-mail address passed to EmailFieldDetails.");
        }

      this.value = value;
      if (parameters != null)
        this.parameters = (!) parameters;
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public override bool equal (AbstractFieldDetails<string> that)
    {
      return base.equal (that);
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public override uint hash ()
    {
      return base.hash ();
    }
}

/**
 * Interface for classes that have email addresses, such as {@link Persona}
 * and {@link Individual}.
 *
 * @since 0.3.5
 */
public interface Folks.EmailDetails : Object
{
  /**
   * The email addresses of the contact.
   *
   * Each of the values in this property contains just an e-mail address (e.g.
   * “foo@bar.com”), rather than any other way of formatting an e-mail address
   * (such as “John Smith &lt;foo@bar.com&gt;”).
   *
   * @since 0.6.0
   */
  public abstract Set<EmailFieldDetails> email_addresses { get; set; }

  /**
   * Change the contact's set of e-mail addresses.
   *
   * It's preferred to call this rather than setting
   * {@link EmailDetails.email_addresses} directly, as this method gives error
   * notification and will only return once the e-mail addresses have been
   * written to the relevant backing store (or the operation's failed).
   *
   * @param email_addresses the new set of e-mail addresses
   * @throws PropertyError if setting the e-mail addresses failed
   * @since 0.6.2
   */
  public virtual async void change_email_addresses (
      Set<EmailFieldDetails> email_addresses) throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("E-mail addresses are not writeable on this contact."));
    }
}
