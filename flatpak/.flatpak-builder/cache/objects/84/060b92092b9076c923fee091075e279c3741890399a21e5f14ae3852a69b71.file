/*
 * Copyright (C) 2013 Intel Corp
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
 *       Patrick Ohly <patrick.ohly@intel.com>
 */

using GLib;

/**
 * A location. Typically latitude and longitude will
 * be based on WGS84. However, folks often has no
 * way of verifying that and just has to assume
 * it's true.
 *
 * @since 0.9.2
 */
public class Folks.Location : Object
{
  /**
   * The latitude.
   *
   * @since 0.9.2
   */
 public double latitude;
  /**
   * The longitude.
   *
   * @since 0.9.2
   */
 public double longitude;

  /**
   * Constructs a new instance with the given coordinates.
   * @param latitude latitude of the new instance
   * @param longitude longitude of the new instance
   * @since 0.9.2
   */
 public Location (double latitude, double longitude)
 {
   this.latitude = latitude;
   this.longitude = longitude;
 }

  /**
   * Compare this location to another by geographical position.
   *
   * @param other the instance to compare against
   * @return true iff the coordinates are exactly the same
   * @since 0.9.2
   */
 public bool equal (Location other)
 {
   return this.latitude == other.latitude &&
          this.longitude == other.longitude;
 }

  /**
   * Compare the geographical position of this location against
   * another position.
   *
   * @param latitude latitude of the other position
   * @param longitude longitude of the other position
   * @return true iff the coordinates are exactly the same
   * @since 0.9.2
   */
  public bool equal_coordinates (double latitude, double longitude)
  {
    return this.latitude == latitude &&
          this.longitude == longitude;
  }
}

/**
 * Location of a contact. folks tries to keep track of
* the current location and thus favors live data (say,
 * as advertised by a chat service) over static data (from
 * an address book). Static addresses, such as a contact's home or work address,
 * should be presented using the {@link PostalAddressDetails} interface.
 * {@link LocationDetails} is purely for exposing the contact's current or
 * recent location.
 *
 * Backends are expected to report only relevant changes
 * in a persona's location. For storage backends like EDS,
 * all changes must have been triggered by a person (e.g.
 * editing the contact) and thus all are relevant.
 *
 * A backend pulling in live data, for example from a GPS,
 * is expected to filter the data to minimize noise.
 *
 * folks itself will then apply all changes coming
 * from backends without further filtering.
 *
 * @since 0.9.2
 */
public interface Folks.LocationDetails : Object
{
  /**
   * The current location of the contact. Null if the contact’s
   * current location isn’t known, or they’re keeping it private.
   *
   * @since 0.9.2
   */
  public abstract Location? location { get; set; }

  /**
   * Set or remove the contact's currently advertised location.
   *
   * It's preferred to call this rather than setting
   * {@link LocationDetails.location} directly, as this method gives error
   * notification and will only return once the location has been written to the
   * relevant backing store (or the operation's failed).
   *
   * @param location the contact's location, null to remove the information
   * @throws PropertyError if setting the location failed
   * @since 0.9.2
   */
  public virtual async void change_location (Location? location) throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Location is not writeable on this contact."));
    }
}
