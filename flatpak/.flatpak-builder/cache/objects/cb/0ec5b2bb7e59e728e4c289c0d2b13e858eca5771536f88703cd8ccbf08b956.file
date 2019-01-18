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
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using GLib;
using Gee;

/**
 * Errors related to IM addresses and IM address handling.
 */
public errordomain Folks.ImDetailsError
{
  /**
   * The specified IM address could not be parsed.
   */
  INVALID_IM_ADDRESS
}

/**
 * Object representing an IM address value that can have some parameters
 * associated with it.
 *
 * See {@link Folks.AbstractFieldDetails}.
 *
 * @since 0.6.0
 */
public class Folks.ImFieldDetails : AbstractFieldDetails<string>
{
  /**
   * Create a new ImFieldDetails.
   *
   * @param value the value of the field, which should be a valid, non-empty
   * IM address
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to
   * an empty map of parameters.
   *
   * @return a new ImFieldDetails
   *
   * @since 0.6.0
   */
  public ImFieldDetails (string value,
      MultiMap<string, string>? parameters = null)
    {
      if (value == "")
        {
          warning ("Empty IM address passed to ImFieldDetails.");
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
 * IM addresses exposed by an object implementing {@link PresenceDetails}.
 *
 * @since 0.1.13
 */
public interface Folks.ImDetails : Object
{
  /**
   * A mapping of IM protocol to an (unordered) set of IM addresses.
   *
   * Each mapping is from an arbitrary protocol identifier to a set of IM
   * addresses on that protocol for the contact, listed in no particular order.
   *
   * There must be no duplicate IM addresses in each set, though a given
   * IM address may be present in the sets for different protocols.
   *
   * All the IM addresses must be normalised using
   * {@link ImDetails.normalise_im_address} before being added to this property.
   *
   * @since 0.5.1
   */
  public abstract MultiMap<string, ImFieldDetails> im_addresses
    {
      get; set;
    }

  /**
   * Change the contact's set of IM addresses.
   *
   * It's preferred to call this rather than setting
   * {@link ImDetails.im_addresses} directly, as this method gives error
   * notification and will only return once the IM addresses have been written
   * to the relevant backing store (or the operation's failed).
   *
   * @param im_addresses the new map of protocols to IM addresses
   * @throws PropertyError if setting the IM addresses failed
   * @since 0.6.2
   */
  public virtual async void change_im_addresses (
      MultiMap<string, ImFieldDetails> im_addresses) throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("IM addresses are not writeable on this contact."));
    }

  /**
   * Normalise an IM address so that it's suitable for string comparison.
   *
   * IM addresses for various protocols can be represented in different ways,
   * only one of which is canonical. In order to allow simple string comparisons
   * of IM addresses to work, the IM addresses must be normalised beforehand.
   *
   * If the provided IM address is invalid,
   * {@link Folks.ImDetailsError.INVALID_IM_ADDRESS} will be thrown. Note that
   * this isn't guaranteed to be thrown for all invalid addresses, but if it is
   * thrown, the address is guaranteed to be invalid.
   *
   * @param im_address the address to normalise
   * @param protocol the protocol of this im_address
   *
   * @since 0.2.0
   * @throws Folks.ImDetailsError if the provided IM address was invalid
   */
  public static string normalise_im_address (string im_address, string protocol)
      throws Folks.ImDetailsError
    {
      if (protocol == "aim" || protocol == "myspace")
        {
          return im_address.replace (" ", "").down ().normalize ();
        }
      else if (protocol == "irc" || protocol == "yahoo" ||
          protocol == "yahoojp" || protocol == "groupwise")
        {
          return im_address.down ().normalize ();
        }
      else if (protocol == "jabber")
        {
          /* Parse the JID */
          string[] parts = im_address.split ("/", 2);

          if (parts.length < 1)
            {
              throw new ImDetailsError.INVALID_IM_ADDRESS (
                  /* Translators: the parameter is an IM address. */
                  _("The IM address ‘%s’ could not be understood."),
                  im_address);
            }

          string? resource = null;
          if (parts.length == 2)
            resource = parts[1];

          parts = parts[0].split ("@", 2);

          if (parts.length < 1)
            {
              throw new ImDetailsError.INVALID_IM_ADDRESS (
                  /* Translators: the parameter is an IM address. */
                  _("The IM address ‘%s’ could not be understood."),
                  im_address);
            }

          string? node, _domain;
          if (parts.length == 2)
            {
              node = parts[0];
              _domain = parts[1];
            }
          else
            {
              node = null;
              _domain = parts[0];
            }

          if ((node != null && node == "") ||
              (_domain == null || _domain == "") ||
              (resource != null && resource == ""))
            {
              throw new ImDetailsError.INVALID_IM_ADDRESS (
                  /* Translators: the parameter is an IM address. */
                  _("The IM address ‘%s’ could not be understood."),
                  im_address);
            }

          string domain = ((!) _domain).down ();
          if (node != null)
            node = ((!) node).down ();

          /* Build a new JID */
          string? normalised = null;

          if (node != null && resource != null)
            {
              normalised = "%s@%s/%s".printf ((!) node, domain, (!) resource);
            }
          else if (node != null)
            {
              normalised = "%s@%s".printf ((!) node, domain);
            }
          else if (resource != null)
            {
              normalised = "%s/%s".printf (domain, (!) resource);
            }
          else
            {
              throw new ImDetailsError.INVALID_IM_ADDRESS (
                  /* Translators: the parameter is an IM address. */
                  _("The IM address ‘%s’ could not be understood."),
                  im_address);
            }

          return ((!) normalised).normalize (-1, NormalizeMode.NFKC);
        }
      else
        {
          /* Fallback */
          return im_address.normalize ();
        }
    }
}
