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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using Gee;
using GLib;

/**
 * Role a contact has in an organisation.
 *
 * This represents the role a {@link Persona} or {@link Individual} has in a
 * single given organisation, such as a company.
 *
 * @since 0.4.0
 */
public class Folks.Role : Object
{
  private string _organisation_name = "";
  /**
   * The name of the organisation in which the role is held.
   */
  public string organisation_name
    {
      get { return this._organisation_name; }
      set { this._organisation_name = (value != null ? value : ""); }
    }

  private string _title = "";
  /**
   * The title of the position held.
   *
   * For example: “Director, Ministry of Silly Walks”
   */
  public string title
    {
      get { return this._title; }
      set { this._title = (value != null ? value : ""); }
    }

  private string _role = "";
  /**
   * The role of the position.
   *
   * For example: “Programmer”
   *
   * @since 0.6.0
   */
  public string role
    {
      get { return this._role; }
      set { this._role = (value != null ? value : ""); }
    }

  private string _uid = "";
  /**
   * The UID that distinguishes this role.
   */
  [Version (deprecated = true, deprecated_since = "0.6.5",
      replacement = "AbstractFieldDetails.id")]
  public string uid
    {
      get { return _uid; }
      set { _uid = (value != null ? value : ""); }
    }

  /**
   * Default constructor.
   *
   * @param title title of the position
   * @param organisation_name organisation where the role is hold
   * @param uid a Unique ID associated to this Role
   * @return a new Role
   *
   * @since 0.4.0
   */
  public Role (string? title = null,
      string? organisation_name = null, string? uid = null)
    {
      Object (uid:                  uid,
              title:                title,
              organisation_name:    organisation_name);
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
      return this.organisation_name == "" &&
             this.title == "" &&
             this.role == "";
    }

  /**
   * Compare if two roles are equal. Roles are equal if their titles and
   * organisation names are equal.
   *
   * @param a a role to compare
   * @param b another role to compare
   * @return ``true`` if the roles are equal, ``false`` otherwise
   */
  public static bool equal (Role a, Role b)
    {
      return (a.title == b.title) &&
          (a.role == b.role) &&
          (a.organisation_name == b.organisation_name);
    }

  /**
   * Hash function for the class. Suitable for use as a hash table key.
   *
   * @param r a role to hash
   * @return hash value for the role instance
   */
  public static uint hash (Role r)
    {
      return r.organisation_name.hash () ^ r.title.hash () ^ r.role.hash ();
    }

  /**
   * Formatted version of this role.
   *
   * @since 0.4.0
   */
  public string to_string ()
    {
      var str = _("Title: %s, Organisation: %s, Role: %s");
      return str.printf (this.title, this.organisation_name, this.role);
    }
}

/**
 * Object representing details of a contact in an organisation which can have
 * some parameters associated with it.
 *
 * See {@link Folks.AbstractFieldDetails}.
 *
 * @since 0.6.0
 */
public class Folks.RoleFieldDetails : AbstractFieldDetails<Role>
{
  private string _id = "";
  /**
   * {@inheritDoc}
   */
  public override string id
    {
      get { return this._id; }
      set
        {
          this._id = (value != null ? value : "");

          /* Keep the Role.uid sync'd from our id */
          if (this._id != this.value.uid)
            this.value.uid = this._id;
        }
    }

  /**
   * Create a new RoleFieldDetails.
   *
   * @param value the non-empty {@link Role} of the field
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to an
   * empty map of parameters.
   *
   * @return a new RoleFieldDetails
   *
   * @since 0.6.0
   */
  public RoleFieldDetails (Role value,
      MultiMap<string, string>? parameters = null)
    {
      if (value.is_empty ())
        {
          warning ("Empty role passed to RoleFieldDetails.");
        }

      /* We keep id and value.uid synchronised in both directions. */
      Object (value: value,
              parameters: parameters,
              id: value.uid);
    }

  construct
    {
      /* Keep the Role.uid sync'd to our id */
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
  public override bool equal (AbstractFieldDetails<Role> that)
    {
      var _that_fd = that as RoleFieldDetails;
      if (_that_fd == null)
        return false;
      RoleFieldDetails that_fd = (!) _that_fd;

      if (!base.parameters_equal (that))
        return false;

      return Role.equal (this.value, that_fd.value);
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.6.0
   */
  public override uint hash ()
    {
      return str_hash (this.value.to_string ());
    }
}

/**
 * This interfaces represents the list of roles a {@link Persona} and
 * {@link Individual} might have.
 *
 * @since 0.4.0
 */
public interface Folks.RoleDetails : Object
{
  /**
   * The roles of the contact.
   *
   * @since 0.6.0
   */
  public abstract Set<RoleFieldDetails> roles { get; set; }

  /**
   * Change the contact's roles.
   *
   * It's preferred to call this rather than setting {@link RoleDetails.roles}
   * directly, as this method gives error notification and will only return once
   * the roles have been written to the relevant backing store (or the
   * operation's failed).
   *
   * @param roles the set of roles
   * @throws PropertyError if setting the roles failed
   * @since 0.6.2
   */
  public virtual async void change_roles (Set<RoleFieldDetails> roles)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("Roles are not writeable on this contact."));
    }
}
