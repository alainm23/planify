/*
 * Copyright (C) 2011, 2015 Collabora Ltd.
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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 *       Philip Withnall <philip.withnall@collabora.co.uk>
 */

using Gee;
using GLib;

/**
 * A contact query.
 *
 * If any properties of the query change such that matches may change, the
 * {@link GLib.Object.notify} signal will be emitted, potentially without a
 * detail string. Views which are using this query should re-evaluate their
 * matches on receiving this signal.
 *
 * @see SearchView
 * @since 0.11.0
 */
public abstract class Folks.Query : Object
{
  /* FIXME: make PersonaStore._PERSONA_DETAIL internal and use it here once
   * bgo#663886 is fixed */
  /**
   * Set of name match fields.
   *
   * These are ordered approximately by descending match likeliness to speed up
   * calls to {@link is_match} when used as-is.
   *
   * @since 0.11.0
   */
  public const string MATCH_FIELDS_NAMES[] =
    {
      "alias",
      "full-name",
      "nickname",
      "structured-name"
    };

  /* FIXME: make PersonaStore._PERSONA_DETAIL internal and use it here once
   * bgo#663886 is fixed */
  /**
   * Set of address (email, IM, postal, phone number, etc.) match fields.
   *
   * These are ordered approximately by descending match likeliness to speed up
   * calls to {@link is_match} when used as-is.
   *
   * @since 0.11.0
   */
  public const string MATCH_FIELDS_ADDRESSES[] =
    {
      "email-addresses",
      "im-addresses",
      "phone-numbers",
      "postal-addresses",
      "web-service-addresses",
      "urls"
    };

  /* FIXME: make PersonaStore._PERSONA_DETAIL internal and use it here once
   * bgo#663886 is fixed */
  /**
   * Set of miscellaneous match fields.
   *
   * These are ordered approximately by descending match likeliness to speed up
   * calls to {@link is_match} when used as-is.
   *
   * @since 0.11.0
   */
  public const string MATCH_FIELDS_MISC[] =
    {
      "groups",
      "roles",
      "notes"
    };

  private string[] _match_fields = MATCH_FIELDS_NAMES;
  /**
   * The names of the fields to match within
   *
   * The names of valid fields are available via
   * {@link PersonaStore.detail_key}.
   *
   * The ordering of the fields determines the order they are checked for
   * matches, which can have performance implications (these should ideally be
   * ordered from most- to least-likely to match).
   *
   * Also note that more fields (particularly rarely-matched fields) will
   * negatively impact performance, so only include important fields.
   *
   * Default value is {@link Query.MATCH_FIELDS_NAMES}.
   *
   * @since 0.11.0
   * @see PersonaDetail
   * @see PersonaStore.detail_key
   * @see Query.MATCH_FIELDS_NAMES
   * @see Query.MATCH_FIELDS_ADDRESSES
   * @see Query.MATCH_FIELDS_MISC
   */
  public virtual string[] match_fields
    {
      get { return this._match_fields; }
      protected construct { this._match_fields = value; }
    }

  /**
   * Determines whether a given {@link Individual} matches this query.
   *
   * This returns a match strength, which is on an arbitrary scale which is not
   * part of libfolks’ public API. These strengths should not be stored by user
   * applications, or examined numerically — they should only be used for
   * pairwise strength comparisons.
   *
   * This function is intended to be used in the {@link SearchView}
   * implementation only. Use {@link SearchView.individuals} to retrieve search
   * results.
   *
   * @param individual an {@link Individual} to match against
   * @return a positive integer if the individual matches this query, or zero
   *   if they do not match; higher numbers indicate a better match
   * @since 0.11.0
   */
  public abstract uint is_match (Individual individual);
}
