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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 *       Philip Withnall <philip@tecnocode.co.uk>
 */

using GLib;
using Gee;

/**
 * Object representing a URL that can have some parameters associated with it.
 *
 * See {@link Folks.AbstractFieldDetails} for details on common parameter names
 * and values.
 *
 * @since 0.6.0
 */
public class Folks.UrlFieldDetails : AbstractFieldDetails<string>
{
  /**
   * Parameter value for URLs for the contact's home page.
   *
   * Value for a parameter with name {@link AbstractFieldDetails.PARAM_TYPE}.
   *
   * @since 0.6.3
   */
  public const string PARAM_TYPE_HOME_PAGE = "x-home-page";

  /**
   * Parameter value for URLs for the contact's personal or professional blog.
   *
   * Value for a parameter with name {@link AbstractFieldDetails.PARAM_TYPE}.
   *
   * @since 0.6.3
   */
  public const string PARAM_TYPE_BLOG = "x-blog";

  /**
   * Parameter value for URLs for the contact's social networking profile.
   *
   * Value for a parameter with name {@link AbstractFieldDetails.PARAM_TYPE}.
   *
   * @since 0.6.3
   */
  public const string PARAM_TYPE_PROFILE = "x-profile";

  /**
   * Parameter value for URLs for the contact's personal or professional FTP
   * server.
   *
   * Value for a parameter with name {@link AbstractFieldDetails.PARAM_TYPE}.
   *
   * @since 0.6.3
   */
  public const string PARAM_TYPE_FTP = "x-ftp";

  /**
   * Create a new UrlFieldDetails.
   *
   * @param value the value of the field, a non-empty URI
   * @param parameters initial parameters. See
   * {@link AbstractFieldDetails.parameters}. A ``null`` value is equivalent to
   * an empty map of parameters.
   *
   * @return a new UrlFieldDetails
   *
   * @since 0.6.0
   */
  public UrlFieldDetails (string value,
      MultiMap<string, string>? parameters = null)
    {
      if (value == "")
        {
          warning ("Empty URI passed to UrlFieldDetails.");
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
 * Associates a list of URLs with a contact.
 *
 * @since 0.3.5
 */
public interface Folks.UrlDetails : Object
{
  /**
   * The websites of the contact.
   *
   * A list or websites associated to the contact.
   *
   * @since 0.5.1
   */
  public abstract Set<UrlFieldDetails> urls { get; set; }

  /**
   * Change the contact's URLs.
   *
   * It's preferred to call this rather than setting {@link UrlDetails.urls}
   * directly, as this method gives error notification and will only return once
   * the URLs have been written to the relevant backing store (or the
   * operation's failed).
   *
   * @param urls the set of URLs
   * @throws PropertyError if setting the URLs failed
   * @since 0.6.2
   */
  public virtual async void change_urls (Set<UrlFieldDetails> urls)
      throws PropertyError
    {
      /* Default implementation. */
      throw new PropertyError.NOT_WRITEABLE (
          _("URLs are not writeable on this contact."));
    }
}
