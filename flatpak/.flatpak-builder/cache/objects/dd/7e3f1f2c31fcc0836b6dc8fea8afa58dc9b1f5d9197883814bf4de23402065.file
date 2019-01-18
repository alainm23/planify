/*
 * Copyright (C) 2011, 2013 Collabora Ltd.
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

/**
 * Structured name representation for human names.
 *
 * Represents a full name split in its constituent parts (given name,
 * family name, etc.). This structure corresponds to the "N" field in
 * vCards. The parts of the name are never ``null``: an empty string
 * indicates that a property is not set.
 *
 * @since 0.3.5
 */
public class Folks.StructuredName : Object
{
  private string _family_name = "";
  /**
   * The family name.
   *
   * The family name (also known as surname or last name) of a contact.
   *
   * @since 0.3.5
   */
  public string family_name
    {
      get { return this._family_name; }
      construct set { this._family_name = value != null ? value : ""; }
    }

  private string _given_name = "";
  /**
   * The given name.
   *
   * The family name (also known as first name) of a contact.
   *
   * @since 0.3.5
   */
  public string given_name
    {
      get { return this._given_name; }
      construct set { this._given_name = value != null ? value : ""; }
    }

  private string _additional_names = "";
  /**
   * Additional names.
   *
   * The additional names of a contact, for instance the contact's
   * middle name.
   *
   * @since 0.3.5
   */
  public string additional_names
    {
      get { return this._additional_names; }
      construct set { this._additional_names = value != null ? value : ""; }
    }

  private string _prefixes = "";
  /**
   * The prefixes of a name.
   *
   * The prefixes used in front of the name (for instance "Mr", "Mrs",
   * "Doctor" or honorific titles).
   *
   * @since 0.3.5
   */
  public string prefixes
    {
      get { return this._prefixes; }
      construct set { this._prefixes = value != null ? value : ""; }
    }

  private string _suffixes = "";
  /**
   * The suffixes of a name.
   *
   * The suffixes used after a name (for instance "PhD" or "Junior").
   *
   * @since 0.3.5
   */
  public string suffixes
    {
      get { return this._suffixes; }
      construct set { this._suffixes = value != null ? value : ""; }
    }

  /**
   * Create a StructuredName.
   *
   * You can pass ``null`` if a component is not set.
   *
   * @param family_name the family (last) name
   * @param given_name the given (first) name
   * @param additional_names additional names
   * @param prefixes prefixes of the name
   * @param suffixes suffixes of the name
   * @return a new StructuredName
   *
   * @since 0.3.5
   */
  public StructuredName (string? family_name, string? given_name,
      string? additional_names, string? prefixes, string? suffixes)
    {
      Object (family_name:      family_name,
              given_name:       given_name,
              additional_names: additional_names,
              prefixes:         prefixes,
              suffixes:         suffixes);
    }

  /**
   * Create a StructuredName.
   *
   * Shorthand for the common case of just having the family and given
   * name of a contact. It's equivalent to calling
   * {@link StructuredName.StructuredName} and passing ``null`` for all
   * the other components.
   *
   * @param family_name the family (last) name
   * @param given_name the given (first) name
   * @return a new StructuredName
   *
   * @since 0.3.5
   */
  public StructuredName.simple (string? family_name, string? given_name)
    {
      Object (family_name: family_name,
              given_name:  given_name);
    }

  /**
   * Whether none of the components is set.
   *
   * @return ``true`` if all the components are the empty string, ``false``
   * otherwise.
   *
   * @since 0.3.5
   */
  public bool is_empty ()
    {
      return this._family_name      == "" &&
             this._given_name       == "" &&
             this._additional_names == "" &&
             this._prefixes         == "" &&
             this._suffixes         == "";
    }

  /**
   * Whether two StructuredNames are the same.
   *
   * @param other the other structured name to compare with
   * @return ``true`` if all the components are the same, ``false``
   * otherwise.
   *
   * @since 0.5.0
   */
  public bool equal (StructuredName other)
    {
      return this._family_name      == other.family_name &&
             this._given_name       == other.given_name &&
             this._additional_names == other.additional_names &&
             this._prefixes         == other.prefixes &&
             this._suffixes         == other.suffixes;
    }

  private string _extract_initials (string names)
    {
      /* Extract the first letter of each word (where a word is a group of
       * characters following whitespace or a hyphen.
       * I've made this up since the documentation on
       * http://lh.2xlibre.net/values/name_fmt/ doesn't specify how to extract
       * the initials from a set of names. It should work for Western names,
       * but I'm not so sure about other names. */
      var output = new StringBuilder ();
      var at_start_of_word = true;
      int index = 0;
      unichar c;

      while (names.get_next_char (ref index, out c) == true)
        {
          /* Grab a new initial from any word preceded by a space or a hyphen,
           * so (e.g.) ‘Mary-Jane’ becomes ‘MJ’. */
          if (c.isspace () || c == '-')
            {
              at_start_of_word = true;
            }
          else if (at_start_of_word)
            {
              output.append_unichar (c);
              at_start_of_word = false;
            }
        }

      return output.str;
    }

  /**
   * Formatted version of the structured name.
   *
   * @return name formatted according to the current locale
   * @since 0.4.0
   */
  public string to_string ()
    {
      /* FIXME: Ideally we’d use a format string translated to the locale of the
       * persona whose name is being formatted, but no backend provides
       * information about personas’ locales, so we have to settle for the
       * current user’s locale.
       *
       * We thought about using nl_langinfo(_NL_NAME_NAME_FMT) here, but
       * decided against it because:
       *  1. It’s not the best documented API in the world, and its stability
       *     is in question.
       *  2. An attempt to improve the interface in glibc met with a wall of
       *     complaints: https://sourceware.org/bugzilla/show_bug.cgi?id=14641.
       *
       * However, we do re-use the string format placeholders from
       * _NL_NAME_NAME_FMT (as documented here:
       * http://lh.2xlibre.net/values/name_fmt/) because there’s a chance glibc
       * might eventually grow a useful interface for this.
       *
       * It does mean we have to implement our own parser for the name_fmt
       * format though, since glibc doesn’t provide a formatting function. */

      /* Translators: This is a format string used to convert structured names
       * to a single string. It should be translated to the predominant
       * semi-formal name format for your locale, using the placeholders
       * documented here: http://lh.2xlibre.net/values/name_fmt/. You may be
       * able to re-use the existing glibc format string for your locale on that
       * page if it’s suitable.
       *
       * More explicitly: the supported placeholders are %f, %F, %g, %G, %m, %M,
       * %t. The romanisation modifier (e.g. %Rf) is recognized but ignored.
       * %s, %S and %d are all replaced by the same thing (the ‘Honorific
       * Prefixes’ from vCard) so please avoid using more than one.
       *
       * For example, the format string ‘%g%t%m%t%f’ expands to ‘John Andrew
       * Lees’ when used for a persona with first name ‘John’, additional names
       * ‘Andrew’ and family names ‘Lees’.
       *
       * If you need additional placeholders with other information or
       * punctuation, please file a bug against libfolks:
       *   https://gitlab.gnome.org/GNOME/folks/issues
       */
      var name_fmt = _("%g%t%m%t%f");

      return this.to_string_with_format (name_fmt);
    }

  /**
   * Formatted version of the structured name.
   *
   * This allows a custom format string to be specified, using the placeholders
   * described on [[http://lh.2xlibre.net/values/name_fmt/]]. This ``name_fmt``
   * must almost always be translated to the current locale. (Ideally it would
   * be translated to the locale of the persona whose name is being formatted,
   * but such locale information isn’t available.)
   *
   * @param name_fmt format string for the name
   * @return name formatted according to the given format
   * @since 0.9.7
   */
  public string to_string_with_format (string name_fmt)
    {
      var output = new StringBuilder ();
      var in_field_descriptor = false;
      var field_descriptor_romanised = false;
      var field_descriptor_empty = true;
      int index = 0;
      unichar c;

      while (name_fmt.get_next_char (ref index, out c) == true)
        {
          /* Start of a field descriptor. */
          if (c == '%')
            {
              in_field_descriptor = !in_field_descriptor;

              /* If entering a field descriptor, reset the state
               * and continue to the next character. */
              if (in_field_descriptor)
                {
                  field_descriptor_romanised = false;
                  continue;
                }
            }

          if (in_field_descriptor)
            {
              /* Romanisation, e.g. using a field descriptor ‘%Rg’. */
              if (c == 'R')
                {
                  /* FIXME: Romanisation isn't supported yet. */
                  field_descriptor_romanised = true;
                  continue;
                }

              var val = "";

              /* Handle the different types of field descriptor. */
              if (c == 'f')
                {
                  val = this._family_name;
                }
              else if (c == 'F')
                {
                  val = this._family_name.up ();
                }
              else if (c == 'g')
                {
                  val = this._given_name;
                }
              else if (c == 'G')
                {
                  val = this._extract_initials (this._given_name);
                }
              else if (c == 'm')
                {
                  val = this._additional_names;
                }
              else if (c == 'M')
                {
                  val = this._extract_initials (this._additional_names);
                }
              else if (c == 's' || c == 'S' || c == 'd')
                {
                  /* FIXME: Not ideal, but prefixes will have to do. */
                  val = this._prefixes;
                }
              else if (c == 't')
                {
                  val = (field_descriptor_empty == false) ? " " : "";
                }
              else if (c == 'l' || c == 'o' || c == 'p')
                {
                  /* FIXME: Not supported. */
                  val = "";
                }

              /* Append the value of the field descriptor. */
              output.append (val);
              in_field_descriptor = false;
              field_descriptor_empty = (val == "");
            }
          else
            {
              /* Handle non-field descriptor characters. */
              output.append_unichar (c);
            }
        }

      return output.str;
    }
}

/**
 * Interface for classes which represent contacts with names, such as
 * {@link Persona} and {@link Individual}.
 *
 * @since 0.3.5
 */
public interface Folks.NameDetails : Object
{
  /**
   * The contact name split in its constituent parts.
   *
   * Note that most of the time the structured name is not set (i.e.
   * it's ``null``) or just some of the components are set.
   * The components are immutable. To get notification of changes of
   * the structured name, you just have to connect to the ``notify`` signal
   * of this property.
   *
   * @since 0.3.5
   */
  public abstract StructuredName? structured_name { get; set; }

  /**
   * Change the contact's structured name.
   *
   * It's preferred to call this rather than setting
   * {@link NameDetails.structured_name} directly, as this method gives error
   * notification and will only return once the name has been written to the
   * relevant backing store (or the operation's failed).
   *
   * @param name the structured name (``null`` to unset it)
   * @throws PropertyError if setting the structured name failed
   * @since 0.6.2
   */
  public virtual async void change_structured_name (StructuredName? name)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Structured name is not writeable on this contact."));
    }

  /**
   * The full name of the contact.
   *
   * The full name is the name of the contact written in the way the contact
   * prefers. For instance for English names this is usually the given name
   * followed by the family name, but Chinese names are usually the family
   * name followed by the given name.
   * The full name could or could not contain additional names (like a
   * middle name), prefixes or suffixes.
   *
   * The full name must not be ``null``: the empty string represents an unset
   * full name.
   *
   * @since 0.3.5
   */
  public abstract string full_name { get; set; }

  /**
   * Change the contact's full name.
   *
   * It's preferred to call this rather than setting
   * {@link NameDetails.full_name} directly, as this method gives error
   * notification and will only return once the name has been written to the
   * relevant backing store (or the operation's failed).
   *
   * @param full_name the full name (empty string to unset it)
   * @throws PropertyError if setting the full name failed
   * @since 0.6.2
   */
  public virtual async void change_full_name (string full_name)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Full name is not writeable on this contact."));
    }

  /**
   * The nickname of the contact.
   *
   * The nickname is the name that the contact chose for himself. This is
   * different from {@link AliasDetails.alias} as aliases can be chosen by
   * the user and not by the contacts themselves.
   *
   * Consequently, setting the nickname only makes sense in the context of an
   * address book when updating the information a contact has specified about
   * themselves.
   *
   * The nickname must not be ``null``: the empty string represents an unset
   * nickname.
   *
   * @since 0.3.5
   */
  public abstract string nickname { get; set; }

  /**
   * Change the contact's nickname.
   *
   * It's preferred to call this rather than setting
   * {@link NameDetails.nickname} directly, as this method gives error
   * notification and will only return once the name has been written to the
   * relevant backing store (or the operation's failed).
   *
   * @param nickname the nickname (empty string to unset it)
   * @throws PropertyError if setting the nickname failed
   * @since 0.6.2
   */
  public virtual async void change_nickname (string nickname)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Nickname is not writeable on this contact."));
    }
}
