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
 *       Alban Crequy <alban.crequy@collabora.co.uk>
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using Gee;

/**
 * Object representing a web service contact that can have some parameters
 * associated with it.
 *
 * See {@link Folks.AbstractFieldDetails}.
 *
 * @since 0.6.0
 */
public class Folks.WebServiceFieldDetails : AbstractFieldDetails<string>
{
  /**
   * Create a new WebServiceFieldDetails.
   *
   * @param value the value of the field, a non-empty web service address
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to
   * an empty map of parameters.
   *
   * @return a new WebServiceFieldDetails
   *
   * @since 0.6.0
   */
  public WebServiceFieldDetails (string value,
      MultiMap<string, string>? parameters = null)
    {
      if (value == "")
        {
          warning ("Empty web service address passed to " +
              "WebServiceFieldDetails.");
        }

      Object (value: value,
              parameters: parameters);
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
 * Web service contact details.
 *
 * @since 0.5.0
 */
public interface Folks.WebServiceDetails : Object
{
  /**
   * A mapping of web service to an (unordered) set of web service addresses.
   *
   * Each mapping is from an arbitrary web service identifier to a set of web
   * service addresses for the contact, listed in no particular order.
   *
   * Web service addresses are guaranteed to be unique per web service, but
   * not necessarily unique amongst all web services.
   *
   * @since 0.6.0
   */
  public abstract
    Gee.MultiMap<string, WebServiceFieldDetails> web_service_addresses
    {
      get; set;
    }

  /**
   * Change the contact's web service addresses.
   *
   * It's preferred to call this rather than setting
   * {@link WebServiceDetails.web_service_addresses} directly, as this method
   * gives error notification and will only return once the addresses have been
   * written to the relevant backing store (or the operation's failed).
   *
   * @param web_service_addresses the set of addresses
   * @throws PropertyError if setting the addresses failed
   * @since 0.6.2
   */
  public virtual async void change_web_service_addresses (
      MultiMap<string, WebServiceFieldDetails> web_service_addresses)
          throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Web service addresses are not writeable on this contact."));
    }
}
