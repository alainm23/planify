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
 *       Raul Gutierrez Segales <raul.gutierrez.segales@collabora.co.uk>
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using Gee;
using GLib;

/**
 * Object representing a note that can have some parameters associated with it.
 *
 * See {@link Folks.AbstractFieldDetails} for details on common parameter names
 * and values.
 *
 * @since 0.6.0
 */
public class Folks.NoteFieldDetails : AbstractFieldDetails<string>
{
  private string _id = "";
  /**
   * {@inheritDoc}
   */
  public override string id
    {
      get { return this._id; }
      set { this._id = (value != null ? value : ""); }
    }

  /**
   * The UID of the note (if any).
   */
  [Version (deprecated = true, deprecated_since = "0.6.5",
      replacement = "AbstractFieldDetails.id")]
  public string uid
    {
      get { return this.id; }
      set { this.id = value; }
    }

  /**
   * Create a new NoteFieldDetails.
   *
   * @param value the value of the field, which should be a non-empty free-form
   * UTF-8 string as entered by the user
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to
   * a empty map of parameters.
   * @param uid UID for the note object itself, if known. A ``null`` value means
   * the note has no unique ID.
   *
   * @return a new NoteFieldDetails
   *
   * @since 0.6.0
   */
  public NoteFieldDetails (string value,
      MultiMap<string, string>? parameters = null,
      string? uid = null)
    {
      if (value == "")
        {
          warning ("Empty note passed to NoteFieldDetails.");
        }

      Object (value: value,
              id: uid,
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
      return (this.value.hash () + this.id.hash ());
    }
}

/**
 * This interface represents the list of notes associated
 * to a {@link Persona} and {@link Individual}.
 *
 * @since 0.4.0
 */
public interface Folks.NoteDetails : Object
{
  /**
   * The notes about the contact.
   *
   * @since 0.5.1
   */
  public abstract Set<NoteFieldDetails> notes { get; set; }

  /**
   * Change the contact's notes.
   *
   * It's preferred to call this rather than setting {@link NoteDetails.notes}
   * directly, as this method gives error notification and will only return once
   * the notes have been written to the relevant backing store (or the
   * operation's failed).
   *
   * @param notes the set of notes
   * @throws PropertyError if setting the notes failed
   * @since 0.6.2
   */
  public virtual async void change_notes (Set<NoteFieldDetails> notes)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Notes are not writeable on this contact."));
    }
}
