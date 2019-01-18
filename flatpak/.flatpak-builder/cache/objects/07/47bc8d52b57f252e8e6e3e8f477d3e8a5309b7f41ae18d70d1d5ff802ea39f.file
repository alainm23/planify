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
 * A simple text-based contact query.
 *
 * This is a generic implementation of the {@link Query} interface which
 * supports general UI-style search use cases. It implements case-insensitive
 * prefix matching, with transliteration of accents and other non-ASCII
 * characters to improve matching against accented characters. It also
 * normalises phone numbers to make matches invariant to hyphenation and spacing
 * in phone numbers.
 *
 * @see SearchView
 * @since 0.11.0
 */
public class Folks.SimpleQuery : Folks.Query
{
  /* These are guaranteed to be non-null */
  private string _query_string;
  private string[] _query_tokens;
  /**
   * The text query string.
   *
   * This re-evaluates the query immediately, so most clients should implement
   * de-bouncing to ensure re-evaluation only happens when (for example) the
   * user has stopped typing a new query.
   *
   * @since 0.11.0
   */
  public string query_string
    {
      get { return this._query_string; }
      set
        {
          if (value == null)
              value = "";

          if (this._query_string == value)
              return;

          this._update_query_string (value, this._query_locale);
        }
    }

  private string? _query_locale = null;
  /**
   * Locale to interpret the {@link SimpleQuery.query_string} in.
   *
   * If possible, locale-specific query string transliteration is done to
   * increase the number of matches. Set this property to a POSIX locale name
   * (e.g. ‘en’, ‘de_DE’, ‘de_DE@euro’ or ‘C’) to potentially improve the
   * transliteration performed.
   *
   * This may be `null` if the locale is unknown, in which case the current
   * locale will be used. To perform transliteration for no specific locale,
   * use `C`.
   *
   * @since 0.11.0
   */
  public string? query_locale
    {
      get { return this._query_locale; }
      set
        {
          if (this._query_locale == value)
              return;

          this._update_query_string (this._query_string, value);
        }
    }

  private void _update_query_string (string query_string,
      string? query_locale)
    {
      this._query_string = query_string;
      this._query_locale = query_locale;
      this._query_tokens =
          this._query_string.tokenize_and_fold (this.query_locale, null);

      debug ("Created simple query with tokens:");
      foreach (var token in this._query_tokens)
          debug ("\t%s", token);

      /* Notify of the need to re-evaluate matches. */
      this.freeze_notify ();
      this.notify_property ("query-string");
      this.notify_property ("query-locale");
      this.thaw_notify ();
    }

  /**
   * Create a simple text query.
   *
   * @param query_string text to match contacts against. Results will match all
   * tokens within the whitespace-delimited string (logical-ANDing the tokens).
   * A value of "" will match all contacts. However, it is recommended to not
   * use a query at all if filtering is not required.
   * @param match_fields the field names to apply this query to. See
   * {@link Query.match_fields} for more details. An empty array will match all
   * contacts. However, it is recommended to use the
   * {@link IndividualAggregator} directly if filtering is not required.
   * {@link PersonaDetail} and {@link PersonaStore.detail_key} for pre-defined
   * field names.
   *
   * @since 0.11.0
   */
  public SimpleQuery (
      string query_string,
      string[] match_fields)
    {
      /* Elements of match_fields should be unique, but it's up to the caller
       * to not repeat themselves */

      /* The given match_fields isn't null-terminated by default in
       * code that uses our predefined match_fields vectors (like
       * Query.MATCH_FIELDS_NAMES), so we need to create a twin array that is;
       * see bgo#659305 */
      var match_fields_safe = match_fields;

      Object (query_string: query_string,
          match_fields: match_fields_safe,
          query_locale: Intl.setlocale (LocaleCategory.ALL, null));
    }

  /**
   * {@inheritDoc}
   *
   * @since 0.11.0
   */
  public override uint is_match (Individual individual)
    {
      /* Treat an empty query string or empty set of fields as "match all" */
      if (this._query_tokens.length < 1 || this.match_fields.length < 1)
        return 1;

      /* Only check for matches in tokens not yet found to minimize our work */
      var tokens_remaining = new HashSet<string> ();

      foreach (var t in this._query_tokens)
          tokens_remaining.add (t);

      /* FIXME: In the future, we should find a way to know this Individual’s
       * locale, and hence hook up translit_locale to improve matches. */
      string? individual_translit_locale = null;

      /* Check for all tokens within a given field before moving on to the next
       * field on the assumption that the vast majority of searches will have
       * all tokens within the same field (eg, both tokens in "Jane Doe" will
       * match in one of the name fields).
       *
       * Track the match score as we go. */
      uint match_score = 0;

      foreach (var prop_name in this.match_fields)
        {
          unowned ObjectClass iclass = individual.get_class ();
          var prop_spec = iclass.find_property (prop_name);
          if (prop_spec == null)
            {
              warning ("Folks.Individual does not contain property '%s'",
                  prop_name);
            }
          else
            {
              var iter = tokens_remaining.iterator ();
              while (iter.next ())
                {
                  var token = iter.get ();
                  var inc = this._prop_contains_token (individual,
                      individual_translit_locale, prop_name, prop_spec, token);
                  match_score += inc;

                  if (inc > 0)
                    {
                      iter.remove ();
                      if (tokens_remaining.size == 0)
                          return match_score;
                    }
                }
            }
        }

      /* Not all of the tokens matched. We do a boolean-and match, so fail. */
      assert (tokens_remaining.size > 0);
      return 0;
    }

  /* Return a match score: a positive integer on a match, zero on no match.
   *
   * The match score weightings in this function are fairly arbitrary and can
   * be tweaked. They were generally chosen to prefer names. */
  private uint _prop_contains_token (
      Individual individual,
      string? individual_translit_locale,
      string prop_name,
      ParamSpec prop_spec,
      string token)
    {
      /* It's safe to assume that this._query_tokens.length >= 1 */

      /* All properties ordered from most-likely-match to least-likely-match to
       * return as early as possible */
      if (false) {}
      else if (prop_spec.value_type == typeof (string))
        {
          string prop_value;
          individual.get (prop_name, out prop_value);

          if (prop_value == null || prop_value == "")
            return 0;

          var score = this._string_matches_token (prop_value, token,
              individual_translit_locale);
          if (score > 0)
            {
              /* Weight names more highly. */
              if (prop_name == "full-name" || prop_name == "nickname")
                  return score * 10;
              else
                  return score * 2;
            }
        }
      else if (prop_spec.value_type == typeof (StructuredName))
        {
          StructuredName prop_value;
          individual.get (prop_name, out prop_value);

          if (prop_value == null)
            return 0;

          var score = this._string_matches_token (prop_value.given_name, token,
              individual_translit_locale);
          if (score > 0)
            return score * 10;

          score = this._string_matches_token (prop_value.family_name, token,
              individual_translit_locale);
          if (score > 0)
            return score * 10;

          score = this._string_matches_token (prop_value.additional_names,
              token, individual_translit_locale);
          if (score > 0)
            return score * 5;

          /* Skip prefixes and suffixes because CPUs have better things to do */
        }
      else if (prop_spec.value_type == typeof (Gee.Set))
        {
          Gee.Set prop_value_set;
          individual.get (prop_name, out prop_value_set);

          if (prop_value_set == null || prop_value_set.is_empty)
            return 0;

          if (prop_value_set.element_type.is_a (typeof (AbstractFieldDetails)))
            {
              var prop_value_afd = prop_value_set
                as Gee.Set<AbstractFieldDetails>;
              foreach (var val in prop_value_afd)
                {
                  if (val.value_type == typeof (string))
                    {
                      /* E-mail addresses, phone numbers, URLs, notes. */
                      var score = this._prop_contains_token_fd_string (
                          individual, individual_translit_locale, prop_name,
                          prop_spec, val, token);
                      if (score > 0)
                        {
                          if (prop_name == "email-addresses")
                              return score * 4;
                          else
                              return score * 2;
                        }
                    }
                  else if (val.value_type == typeof (Role))
                    {
                      /* Roles. */
                      var score = this._prop_contains_token_fd_role (individual,
                          individual_translit_locale, prop_name, prop_spec, val,
                          token);
                      if (score > 0)
                        {
                          return score * 1;
                        }
                    }
                  else if (val.value_type == typeof (PostalAddress))
                    {
                      /* Postal addresses. */
                      var score = this._prop_contains_token_fd_postal_address (
                          individual, individual_translit_locale, prop_name,
                          prop_spec, val, token);
                      if (score > 0)
                        {
                          return score * 3;
                        }
                    }
                  else
                    {
                      warning ("Cannot check for match in detail type " +
                          "Gee.Set<AbstractFieldDetails<%s>>",
                          val.value_type.name ());
                      return 0;
                    }
                }
            }
          else if (prop_value_set.element_type == typeof (string))
            {
              /* Groups and local IDs. */
              var prop_value_string = prop_value_set as Gee.Set<string>;
              foreach (var val in prop_value_string)
                {
                  if (val == null || val == "")
                    continue;

                  var score = this._string_matches_token (val, token,
                      individual_translit_locale);
                  if (score > 0)
                    return score * 1;
                }
            }
          else
            {
              warning ("Cannot check for match in property ‘%s’, detail type " +
                  "Gee.Set<%s>", prop_name,
                  prop_value_set.element_type.name ());
              return 0;
            }

        }
      else if (prop_spec.value_type == typeof (Gee.MultiMap))
        {
          Gee.MultiMap prop_value_multi_map;
          individual.get (prop_name, out prop_value_multi_map);

          if (prop_value_multi_map == null || prop_value_multi_map.size < 1)
            return 0;

          var key_type = prop_value_multi_map.key_type;
          var value_type = prop_value_multi_map.value_type;

          if (key_type.is_a (typeof (string)) &&
              value_type.is_a (typeof (AbstractFieldDetails)))
            {
              var prop_value_multi_map_afd = prop_value_multi_map
                as Gee.MultiMap<string, AbstractFieldDetails>;
              var iter = prop_value_multi_map_afd.map_iterator ();

              while (iter.next ())
                {
                  var val = iter.get_value ();

                  /* IM addresses, web service addresses. */
                  if (val.value_type == typeof (string))
                    {
                      var score = this._prop_contains_token_fd_string (
                          individual, individual_translit_locale, prop_name,
                          prop_spec, val, token);
                      if (score > 0)
                        {
                          return score * 2;
                        }
                    }
                }
            }
          else
            {
              warning ("Cannot check for match in detail type " +
                  "Gee.MultiMap<%s, %s>",
                  key_type.name (), value_type.name ());
              return 0;
            }
        }
      else
        {
          warning ("Cannot check for match in detail type %s",
              prop_spec.value_type.name ());
        }

      return 0;
    }

  private uint _prop_contains_token_fd_string (
      Individual individual,
      string? individual_translit_locale,
      string prop_name,
      ParamSpec prop_spec,
      AbstractFieldDetails<string> val,
      string token)
    {
      if (val.get_type () == typeof (PhoneFieldDetails))
        {
          /* If this doesn’t match, fall through and try and normal string
           * match. This allows for the case of, e.g. matching query ‘123-4567’
           * against ‘+01234567890’. The query string is tokenised to ‘123’ and
           * ‘4567’, neither of which would normally match against the full
           * phone number. */
          if (val.values_equal (new PhoneFieldDetails (token)))
              return 2;
        }

      return this._string_matches_token (val.value, token,
          individual_translit_locale);

      /* Intentionally ignore the params; they're not interesting */
    }

  private uint _prop_contains_token_fd_postal_address (
      Individual individual,
      string? individual_translit_locale,
      string prop_name,
      ParamSpec prop_spec,
      AbstractFieldDetails<PostalAddress> val,
      string token)
    {
      var score = this._string_matches_token (val.value.street, token,
          individual_translit_locale);
      if (score > 0)
          return score;

      score = this._string_matches_token (val.value.locality, token,
          individual_translit_locale);
      if (score > 0)
          return score;

      score = this._string_matches_token (val.value.region, token,
          individual_translit_locale);
      if (score > 0)
          return score;

      score = this._string_matches_token (val.value.country, token,
          individual_translit_locale);
      if (score > 0)
          return score;

      /* All other fields intentionally ignored due to general irrelevance */
      return 0;
    }

  private uint _prop_contains_token_fd_role (
      Individual individual,
      string? individual_translit_locale,
      string prop_name,
      ParamSpec prop_spec,
      AbstractFieldDetails<Role> val,
      string token)
    {
      var score = this._string_matches_token (val.value.organisation_name,
          token, individual_translit_locale);
      if (score > 0)
          return score;

      score = this._string_matches_token (val.value.title, token,
          individual_translit_locale);
      if (score > 0)
          return score;

      score = this._string_matches_token (val.value.role, token,
          individual_translit_locale);
      if (score > 0)
          return score;

      /* Intentionally ignore the params; they're not interesting */
      return 0;
    }

  private inline uint _string_matches_token (string str, string token,
      string? str_translit_locale = null)
    {
      debug ("Matching string ‘%s’ against token ‘%s’.", str, token);

      string[] alternates;
      var str_tokens =
          str.tokenize_and_fold (str_translit_locale, out alternates);

      /* FIXME: We have to use for() rather than foreach() because of:
       * https://bugzilla.gnome.org/show_bug.cgi?id=743877 */
      for (var i = 0; str_tokens[i] != null; i++)
        {
          var str_token = str_tokens[i];

          if (str_token == token)
              return 3;
          else if (str_token.has_prefix (token))
              return 2;
        }

      for (var i = 0; alternates[i] != null; i++)
        {
          var str_token = alternates[i];

          if (str_token == token)
              return 2;
          else if (str_token.has_prefix (token))
              return 1;
        }

      return 0;
    }
}
