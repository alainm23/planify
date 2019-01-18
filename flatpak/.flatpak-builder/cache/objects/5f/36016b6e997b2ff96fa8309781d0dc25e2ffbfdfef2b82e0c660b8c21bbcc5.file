/*
 * Copyright (C) 2011 Collabora Ltd.
 * Copyright (C) 2011, 2013 Philip Withnall
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
 * Object representing a phone number that can have some parameters associated
 * with it.
 *
 * See {@link Folks.AbstractFieldDetails} for details on common parameter names
 * and values.
 *
 * @since 0.6.0
 */
public class Folks.PhoneFieldDetails : AbstractFieldDetails<string>
{
  private const char[] _extension_chars = { 'p', 'P', 'w', 'W', 'x', 'X' };
  private const char[] _common_delimiters = { ',', '.', '(', ')', '-', ' ',
      '\t', '/' };
  private const char[] _valid_digits = { '#', '*', '0', '1', '2', '3', '4',
      '5', '6', '7', '8', '9' };

  private string _id;
  /**
   * {@inheritDoc}
   */
  public override string id
    {
      get { return this._id; }
      set { this._id = (value != null ? value : ""); }
    }

  /**
   * Create a new PhoneFieldDetails.
   *
   * @param value the value of the field, which should be a non-empty phone
   * number (no particular format is mandated)
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to
   * an empty map of parameters.
   *
   * @return a new PhoneFieldDetails
   *
   * @since 0.6.0
   */
  public PhoneFieldDetails (string value,
      MultiMap<string, string>? parameters = null)
    {
      if (value == "")
        {
          warning ("Empty phone number passed to PhoneFieldDetails.");
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
   */
  public override bool values_equal (AbstractFieldDetails<string> that)
    {
      var _that_fd = that as PhoneFieldDetails;
      if (_that_fd == null)
        return false;
      PhoneFieldDetails that_fd = (!) _that_fd;

      var n1 = PhoneFieldDetails._drop_extension (this.get_normalised ());
      var n2 = PhoneFieldDetails._drop_extension (that_fd.get_normalised ());

      /* Based on http://blog.barisione.org/2010-06/handling-phone-numbers/ */
      if (n1.length >= 7 && n2.length >= 7)
        {
          var n1_reduced = n1.slice (-7, n1.length);
          var n2_reduced = n2.slice (-7, n2.length);

          debug ("[PhoneDetails.equal] Comparing %s with %s",
              n1_reduced, n2_reduced);

          return n1_reduced == n2_reduced;
        }

      return n1 == n2;
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

  /**
   * Return this object's normalised phone number.
   *
   * Typical normalisations:
   *
   *  - ``1-800-123-4567`` → ``18001234567``
   *  - ``+1-800-123-4567`` → ``+18001234567``
   *  - ``+1-800-123-4567P123`` → ``+18001234567P123``
   *
   * @return the normalised form of ``number``
   *
   * @since 0.6.0
   */
  public string get_normalised ()
    {
      var builder = new StringBuilder ();

      /* Based on http://blog.barisione.org/2010-06/handling-phone-numbers/ */
      for (uint i = 0; i < this.value.length; i++)
        {
          var digit = this.value[i];

          if (digit in PhoneFieldDetails._extension_chars)
            {
              /* Keep the extension characters P, W and X, but be sure they are
               * upper case. */
               digit = digit.toupper ();
            }
          else if (digit == '+')
            {
              /* "+" is valid only at the beginning of phone numbers or after
               * the number suppression prefix. */
              if (builder.str != "" &&
                  builder.str != "*31#" &&
                  builder.str != "#31#")
                {
                  /* Skip this "+". */
                  debug ("[PhoneDetails.get_normalised] Wrong '+' in %s",
                      this.value);
                  continue;
                }
            }
          else if (digit in PhoneFieldDetails._common_delimiters)
            {
              /* Skip this delimiter. */
              continue;
            }
          else if (digit in PhoneFieldDetails._valid_digits)
            {
              /* Ok, let's keep it. */
            }
          else
            {
              /* What is this? It doesn't seem valid but we just keep it */
              debug ("[PhoneDetails.get_normalised] Unknown character '%c' in '%s'",
                  digit, this.value);
            }

         builder.append_c (digit);
       }

      return builder.str;
    }

  /**
   * Returns the given number without its extension (if any).
   *
   * @param number the phone number to process
   * @return the number without its extension; if the number didn't have an
   * extension in the first place, the number is returned unmodified
   *
   * @since 0.6.0
   */
  internal static string _drop_extension (string number)
    {
      /* Based on http://blog.barisione.org/2010-06/handling-phone-numbers/ */
      var builder = new StringBuilder ();

      for (uint i = 0; i < number.length; i++)
        {
          var digit = number[i];
          if (digit in PhoneFieldDetails._extension_chars)
            {
              /* Extension character, drop this character and the rest of the
               * string. */
              break;
            }
          builder.append_c (digit);
        }

      return builder.str;
    }
}

/**
 * Interface for classes that can provide a phone number, such as
 * {@link Persona} and {@link Individual}.
 *
 * @since 0.3.5
 */
public interface Folks.PhoneDetails : Object
{
  /**
   * The phone numbers of the contact.
   *
   * A list of phone numbers associated to the contact.
   *
   * @since 0.6.0
   */
  public abstract Set<PhoneFieldDetails> phone_numbers { get; set; }

  /**
   * Change the contact's phone numbers.
   *
   * It's preferred to call this rather than setting
   * {@link PhoneDetails.phone_numbers} directly, as this method gives error
   * notification and will only return once the phone numbers have been written
   * to the relevant backing store (or the operation's failed).
   *
   * @param phone_numbers the set of phone numbers
   * @throws PropertyError if setting the phone numbers failed
   * @since 0.6.2
   */
  public virtual async void change_phone_numbers (
      Set<PhoneFieldDetails> phone_numbers) throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Phone numbers are not writeable on this contact."));
    }
}
