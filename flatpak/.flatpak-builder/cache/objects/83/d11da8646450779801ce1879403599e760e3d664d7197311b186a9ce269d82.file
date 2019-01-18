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
 *       Marco Barisione <marco.barisione@collabora.co.uk>
 *       Raul Gutierrez Segales <raul.gutierrez.segales@collabora.co.uk>
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using GLib;
using Gee;

/**
 * Object representing a postal mail address.
 *
 * The components of the address are never ``null``: an empty string
 * indicates that a property is not set.
 */
public class Folks.PostalAddress : Object
{
  private string _po_box = "";
  /**
   * The PO Box.
   *
   * The PO Box (also known as Postal office box or Postal box).
   */
  public string po_box
    {
      get { return _po_box; }
      construct set { _po_box = (value != null ? value : ""); }
    }

  private string _extension = "";
  /**
   * The address extension.
   *
   * Any additional part of the address, for instance a flat number.
   */
  public string extension
    {
      get { return _extension; }
      construct set { _extension = (value != null ? value : ""); }
    }

  private string _street = "";
  /**
   * The street name and number.
   *
   * The street name including the optional building number.
   * The number can be before or after the street name based on the
   * language and country.
   */
  public string street
    {
      get { return _street; }
      construct set { _street = (value != null ? value : ""); }
    }

  private string _locality = "";
  /**
   * The locality.
   *
   * The locality, for instance the city name.
   */
  public string locality
    {
      get { return _locality; }
      construct set { _locality = (value != null ? value : ""); }
    }

  private string _region = "";
  /**
   * The region.
   *
   * The region, for instance the name of the state or province.
   */
  public string region
    {
      get { return _region; }
      construct set { _region = (value != null ? value : ""); }
    }

  private string _postal_code = "";
  /**
   * The postal code.
   *
   * The postal code (also known as post code, postcode or ZIP code).
   */
  public string postal_code
    {
      get { return _postal_code; }
      construct set { _postal_code = (value != null ? value : ""); }
    }

  private string _country = "";
  /**
   * The country.
   *
   * The name of the country.
   */
  public string country
    {
      get { return _country; }
      construct set { _country = (value != null ? value : ""); }
    }

  private string _address_format = "";
  /**
   * The address format.
   *
   * The two letter country code that determines the format or exact
   * meaning of the other fields.
   */
  public string address_format
    {
      get { return _address_format; }
      construct set { _address_format = (value != null ? value : ""); }
    }

  private string _uid = "";
  /**
   * The UID of the Postal Address (if any).
   */
  [Version (deprecated = true, deprecated_since = "0.6.5",
      replacement = "AbstractFieldDetails.id")]
  public string uid
    {
      get { return _uid; }
      construct set { _uid = (value != null ? value : ""); }
    }

  /**
   * Create a PostalAddress.
   *
   * You can pass ``null`` if a component is not set.
   *
   * @param po_box the PO Box
   * @param extension the address extension
   * @param street the street name and number
   * @param locality the locality (city, town or village) name
   * @param region the region (state or province) name
   * @param postal_code the postal code
   * @param country the country name
   * @param address_format the address format
   * @param uid external UID for the address instance
   * @since 0.5.1
   */
  public PostalAddress (string? po_box, string? extension, string? street,
      string? locality, string? region, string? postal_code, string? country,
      string? address_format, string? uid)
    {
      Object (po_box:         po_box,
              extension:      extension,
              street:         street,
              locality:       locality,
              region:         region,
              postal_code:    postal_code,
              country:        country,
              address_format: address_format,
              uid:            uid);
    }

  /**
   * Whether none of the components is set.
   *
   * @return ``true`` if all the components are the empty string, ``false``
   * otherwise.
   *
   * @since 0.6.7
   */
  public bool is_empty ()
    {
      return this.po_box == "" &&
             this.extension == "" &&
             this.street == "" &&
             this.locality == "" &&
             this.region == "" &&
             this.postal_code == "" &&
             this.country == "" &&
             this.address_format == "";
    }

  /**
   * Compare if two postal addresses are equal. Addresses are equal if all their
   * components are equal (where ``null`` compares equal only with ``null``) and
   * they have the same set of types (or both have no types).
   *
   * This does not factor in the {@link PostalAddress.uid}.
   *
   * @param with another postal address to compare with
   * @return ``true`` if the addresses are equal, ``false`` otherwise
   */
  public bool equal (PostalAddress with)
    {
      if (this.po_box != with.po_box ||
          this.extension != with.extension ||
          this.street != with.street ||
          this.locality != with.locality ||
          this.region != with.region ||
          this.postal_code != with.postal_code ||
          this.country != with.country ||
          this.address_format != with.address_format)
        return false;

      return true;
    }

  /**
   * Get a formatted version of the address. The format is localised, and by
   * default is comma-separated.
   *
   * @return a formatted address.
   *
   * @since 0.4.0
   */
  public string to_string ()
    {
      var str = _("%s, %s, %s, %s, %s, %s, %s");
      return str.printf (this.po_box, this.extension, this.street,
          this.locality, this.region, this.postal_code, this.country);
    }
}

/**
 * Object representing a PostalAddress value that can have some parameters
 * associated with it.
 *
 * See {@link Folks.AbstractFieldDetails} for details on common parameter names
 * and values.
 *
 * @since 0.6.0
 */
public class Folks.PostalAddressFieldDetails :
    AbstractFieldDetails<PostalAddress>
{
  private string _id;
  /**
   * {@inheritDoc}
   */
  public override string id
    {
      get { return this._id; }
      set
        {
          this._id = (value != null ? value : "");

          /* Keep the PostalAddress.uid sync'd from our id */
          if (this._id != this.value.uid)
            this.value.uid = this._id;
        }
    }

  /**
   * Create a new PostalAddressFieldDetails.
   *
   * @param value the value of the field, a non-empty {@link PostalAddress}
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to
   * an empty map of parameters.
   *
   *
   * @return a new PostalAddressFieldDetails
   *
   * @since 0.6.0
   */
  public PostalAddressFieldDetails (PostalAddress value,
      MultiMap<string, string>? parameters = null)
    {
      if (value.is_empty ())
        {
          warning ("Empty postal address passed to PostalAddressFieldDetails.");
        }

      /* We keep id and value.uid synchronised in both directions. */
      Object (value: value,
              parameters: parameters,
              id: value.uid);
    }

  construct
    {
      /* Keep the PostalAddress.uid sync'd to our id */
      this.value.notify["uid"].connect ((s, p) =>
        {
          if (this.id != this.value.uid)
            this.id = this.value.uid;
        });
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public override bool equal (AbstractFieldDetails<PostalAddress> that)
    {
      if (!base.parameters_equal (that))
        return false;

      /* This is fairly-dumb but smart matching is an i10n nightmare. */
      return this.value.to_string () == that.value.to_string ();
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public override uint hash ()
    {
      /* This is basic because smart matching is very hard (see equal()). */
      return str_hash (this.value.to_string ());
    }
}

/**
 * Interface for classes that can provide postal addresses, such as
 * {@link Persona} and {@link Individual}.
 */
public interface Folks.PostalAddressDetails : Object
{
  /**
   * The postal addresses of the contact.
   *
   * A list of postal addresses associated to the contact.
   *
   * @since 0.5.1
   */
  public abstract Set<PostalAddressFieldDetails> postal_addresses { get; set; }

  /**
   * Change the contact's postal addresses.
   *
   * It's preferred to call this rather than setting
   * {@link PostalAddressDetails.postal_addresses} directly, as this method
   * gives error notification and will only return once the addresses have been
   * written to the relevant backing store (or the operation's failed).
   *
   * @param postal_addresses the set of postal addresses
   * @throws PropertyError if setting the addresses failed
   * @since 0.6.2
   */
  public virtual async void change_postal_addresses (
      Set<PostalAddressFieldDetails> postal_addresses) throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Postal addresses are not writeable on this contact."));
    }
}
