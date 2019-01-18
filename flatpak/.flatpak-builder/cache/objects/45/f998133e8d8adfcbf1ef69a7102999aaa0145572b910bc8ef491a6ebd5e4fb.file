/*
 * Copyright (C) 2011 Collabora Ltd.
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
 */

using Gee;

/**
 * Likely-ness of a potential match.
 *
 * Note that the order should be maintained.
 *
 * @since 0.5.0
 */
public enum Folks.MatchResult
{
  /**
   * Zero likelihood of a match.
   *
   * This is used in situations where two individuals should never be linked,
   * such as when one of them has a {@link Individual.trust_level} of
   * {@link TrustLevel.NONE}, or when the individuals are explicitly
   * anti-linked.
   *
   * @since 0.6.8
   */
  NONE = -1,

  /**
   * Very low likelihood of a match.
   */
  VERY_LOW = 0,

  /**
   * Low likelihood of a match.
   */
  LOW = 1,

  /**
   * Medium likelihood of a match.
   */
  MEDIUM = 2,

  /**
   * High likelihood of a match.
   */
  HIGH = 3,

  /**
   * Very high likelihood of a match.
   */
  VERY_HIGH = 4,

  /**
   * Minimum likelihood of a match.
   */
  MIN = NONE,

  /**
   * Maximum likelihood of a match.
   */
  MAX = VERY_HIGH
}

/**
 * Match calculator for pairs of individuals.
 *
 * This provides functionality to explore the degree of a potential match
 * between two individuals. It compares the similarity of the individuals'
 * properties to determine how likely it is that the individuals represent the
 * same physical person.
 *
 * This can be used by folks clients to, for example, present suggestions of
 * pairs of individuals which should be linked by the user.
 *
 * @since 0.5.0
 */
public class Folks.PotentialMatch : Object
{
  private Folks.Individual _individual_a;
  private Folks.Individual _individual_b;

  /**
   * A set of e-mail addresses known to be aliases of each other, such as
   * various forms of administrator address.
   *
   * @since 0.5.1
   */
  public static Set<string> known_email_aliases = new SmallSet<string> ();

  private static double _DIST_THRESHOLD = 0.70;
  private const string _SEPARATORS = "._-+";

  static construct
    {
      PotentialMatch.known_email_aliases.add ("admin");
      PotentialMatch.known_email_aliases.add ("abuse");
      PotentialMatch.known_email_aliases.add ("webmaster");
    }

  /**
   * Create a new PotentialMatch.
   *
   * @return a new PotentialMatch
   *
   * @since 0.5.0
   */
  public PotentialMatch ()
    {
      base ();
    }

  /**
   * Whether two individuals are likely to be the same person.
   *
   * @param a an individual to compare
   * @param b another individual to compare
   *
   * @since 0.5.0
   */
  public MatchResult potential_match (Individual a, Individual b)
    {
      this._individual_a = a;
      this._individual_b = b;
      MatchResult result = MatchResult.MIN;

      /* Immediately discount a match if either of the individuals can't be
       * trusted (e.g. due to containing link-local XMPP personas, which can be
       * spoofed). */
      if (a.trust_level == TrustLevel.NONE || b.trust_level == TrustLevel.NONE)
        {
          return result;
        }

      /* Similarly, immediately discount a match if the individuals have been
       * anti-linked by the user. */
      if (a.has_anti_link_with_individual (b))
        {
          return result;
        }

      result = MatchResult.VERY_LOW;

      /* If individuals share gender. */
      if (this._individual_a.gender != Gender.UNSPECIFIED &&
          this._individual_b.gender != Gender.UNSPECIFIED &&
          this._individual_a.gender != this._individual_b.gender)
        {
          return result;
        }

      /* If individuals share common im-addresses */
      result = this._inspect_im_addresses (result);
      if (result == MatchResult.MAX)
        return result;

      /* If individuals share common e-mails */
      result = this._inspect_emails (result);
      if (result == MatchResult.MAX)
        return result;

      /* If individuals share common phone numbers */
      result = this._inspect_phone_numbers (result);
      if (result == MatchResult.MAX)
        return result;

      /* they have the same (normalised) name? */
      result = this._name_similarity (result);
      if (result == MatchResult.MAX)
        return result;

      return result;
    }

  private MatchResult _inspect_phone_numbers (MatchResult old_result)
    {
      var set_a = this._individual_a.phone_numbers;
      var set_b = this._individual_b.phone_numbers;

      foreach (var phone_fd_a in set_a)
        {
          foreach (var phone_fd_b in set_b)
            {
              if (phone_fd_a.values_equal (phone_fd_b))
                {
                  return MatchResult.HIGH;
                }
            }
        }

      return old_result;
    }

  /* Approach:
   * - taking in account family, given, prefix, suffix and additional names
   *   we give some points for each non-empty match
   *
   * @since 0.5.0
   */
  private MatchResult _name_similarity (MatchResult old_result)
    {
      double similarity = 0.0;
      bool exact_match = false;

      if (this._look_alike (this._individual_a.nickname,
              this._individual_b.nickname))
        {
          similarity += 0.20;
        }

      if (this._look_alike_or_identical (this._individual_a.full_name,
              this._individual_b.full_name,
              out exact_match) ||
          this._look_alike_or_identical (this._individual_a.alias,
              this._individual_b.full_name,
              out exact_match) ||
          this._look_alike_or_identical (this._individual_a.full_name,
              this._individual_b.alias,
              out exact_match) ||
          this._look_alike_or_identical (this._individual_a.alias,
              this._individual_b.alias,
              out exact_match))
        {
          similarity += 0.70;
        }

      var _a = this._individual_a.structured_name;
      var _b = this._individual_b.structured_name;

      if (_a != null && _b != null)
        {
          var a = (!) _a;
          var b = (!) _b;

          if (a.is_empty () == false && a.equal (b))
            {
              return MatchResult.HIGH;
            }

          if (Folks.Utils._str_equal_safe (a.given_name, b.given_name))
            similarity += 0.20;

          if (this._look_alike (a.family_name, b.family_name) &&
              this._look_alike (a.given_name, b.given_name))
            {
              similarity += 0.40;
            }

          if (Folks.Utils._str_equal_safe (a.additional_names,
                  b.additional_names))
            similarity += 0.5;

          if (Folks.Utils._str_equal_safe (a.prefixes, b.prefixes))
            similarity += 0.5;

          if (Folks.Utils._str_equal_safe (a.suffixes, b.suffixes))
            similarity += 0.5;
        }

      debug ("[name_similarity] Got %f\n", similarity);

      if (similarity >= PotentialMatch._DIST_THRESHOLD)
        {
          int inc = 2;
          /* We need exact matches to go to at least HIGH, or otherwise its
             not possible to get a HIGH match for e.g. a facebook telepathy
             persona, where alias is the only piece of information
             available */
          if (exact_match)
            inc += 1;
          return this._inc_match_level (old_result, inc);
        }

      return old_result;
    }

  /**
   * Number of equal IM addresses between two individuals.
   *
   * This compares the addresses without comparing their associated protocols.
   *
   * @since 0.5.0
   */
  private MatchResult _inspect_im_addresses (MatchResult old_result)
    {
      var addrs = new HashSet<string> ();

      foreach (var im_a in this._individual_a.im_addresses.get_values ())
        {
          addrs.add (im_a.value);
        }

      foreach (var im_b in this._individual_b.im_addresses.get_values ())
        {
          if (addrs.contains (im_b.value) == true)
            {
              return MatchResult.HIGH;
            }
        }

      return old_result;
    }

  /**
   * Inspect email addresses.
   *
   * @since 0.5.0
   */
  private MatchResult _inspect_emails (MatchResult old_result)
    {
      var set_a = this._individual_a.email_addresses;
      var set_b = this._individual_b.email_addresses;
      MatchResult result = old_result;

      foreach (var fd_a in set_a)
        {
          string[] email_split_a = fd_a.value.split ("@");

          /* Sanity check for valid e-mail addresses. */
          if (email_split_a.length < 2)
            {
              warning ("Invalid e-mail address when looking for potential " +
                  "match: %s", fd_a.value);
              continue;
            }

          string[] tokens_a =
            email_split_a[0].split_set (PotentialMatch._SEPARATORS);

          foreach (var fd_b in set_b)
            {
              string[] email_split_b = fd_b.value.split ("@");

              /* Sanity check for valid e-mail addresses. */
              if (email_split_b.length < 2)
                {
                  warning ("Invalid e-mail address when looking for " +
                      "potential match: %s", fd_b.value);
                  continue;
                }

              if (fd_a.value == fd_b.value)
                {
                  if (PotentialMatch.known_email_aliases.contains
                      (email_split_a[0]) == true)
                    {
                      if (result < MatchResult.HIGH)
                        {
                          result = MatchResult.LOW;
                        }
                    }
                  else
                    {
                      return MatchResult.HIGH;
                    }
                }
              else
                {
                  string[] tokens_b =
                    email_split_b[0].split_set (PotentialMatch._SEPARATORS);

                  /* Do we have: first.middle.last@ ~= fml@ ? */
                  if (this._check_initials_expansion (tokens_a, tokens_b))
                    {
                      result = MatchResult.MEDIUM;
                    }
                  /* So we have splitted the user part of the e-mail
                   * address into tokens. Lets see if there is some
                   * matches between tokens.
                   * As in: first.middle.last@ ~= [first,middle,..]@  */
                  else if (this._match_tokens (tokens_a, tokens_b))
                    {
                      result = MatchResult.MEDIUM;
                    }
               }
            }
        }

      return result;
    }

  /* We are after:
   * you.are.someone@ =~ yas@
   */
  private bool _check_initials_expansion (string[] tokens_a, string[] tokens_b)
    {
      if (tokens_a.length > tokens_b.length &&
          tokens_b.length == 1)
        {
          return this._do_check_initials_expansion (tokens_a, tokens_b[0]);
        }
      else if (tokens_b.length > tokens_a.length &&
          tokens_a.length == 1)
        {
          return this._do_check_initials_expansion (tokens_b, tokens_a[0]);
        }
      return false;
    }

  private bool _do_check_initials_expansion (string[] expanded_name,
      string initials)
    {
      if (expanded_name.length != initials.length)
        return false;

      for (int i=0; i<expanded_name.length; i++)
        {
          if (expanded_name[i][0] != initials[i])
            return false;
        }

      return true;
    }

  /*
   * We should probably count how many tokens matched?
   */
  private bool _match_tokens (string[] tokens_a, string[] tokens_b)
    {
      /* To find matching items from 2 sets its more efficient
       * to make the outer loop go with the smaller set. */
      if (tokens_a.length > tokens_b.length)
        return this._do_match_tokens (tokens_a, tokens_b);
      else
        return this._do_match_tokens (tokens_b, tokens_a);
    }

  private bool _do_match_tokens (string[] bigger_set, string[] smaller_set)
    {
      for (var i=0; i < smaller_set.length; i++)
        {
          for (var j=0; j < bigger_set.length; j++)
            {
              if (smaller_set[i] == bigger_set[j])
                return true;
            }
        }

      return false;
    }

  private MatchResult _inc_match_level (
      MatchResult current_level, int times = 1)
    {
      MatchResult ret = current_level + times;
      if (ret > MatchResult.MAX)
        ret = MatchResult.MAX;

      return ret;
    }

  private bool _look_alike_or_identical (string? a, string? b, out bool exact)
    {
      exact = false;
      if (a == null || a == "" || b == null || b == "")
        {
          return false;
        }

      return_val_if_fail (a.validate (), false);
      return_val_if_fail (b.validate (), false);

      var a_stripped = this._strip_string ((!) a);
      var b_stripped = this._strip_string ((!) b);

      var jaro_dist = this._jaro_dist (a_stripped, b_stripped);

      // a and b match exactly iff their Jaro distance is 1.
      if (jaro_dist == 1.0)
        {
          exact = true;
          return true;
        }

      // a and b look alike if their Jaro distance is over the threshold.
      return (jaro_dist >= PotentialMatch._DIST_THRESHOLD);
    }

  private bool _look_alike (string? a, string? b)
    {
      if (a == null || a == "" || b == null || b == "")
        {
          return false;
        }

      return_val_if_fail (a.validate (), false);
      return_val_if_fail (b.validate (), false);

      var a_stripped = this._strip_string ((!) a);
      var b_stripped = this._strip_string ((!) b);

      // a and b look alike if their Jaro distance is over the threshold.
      return (this._jaro_dist (a_stripped, b_stripped) >= PotentialMatch._DIST_THRESHOLD);
    }

  /* Based on:
   *  http://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance
   *
   * d = 1/3 * ( m/|s1| + m/|s2| + (m - t)/m )
   *
   *   where
   *
   * m = matching characters
   * t = number of transpositions
   */
  private double _jaro_dist (unichar[] s1, unichar[] s2)
    {
      double distance;
      int max = s1.length > s2.length ? s1.length : s2.length;
      int max_dist = (max / 2) - 1;
      double t;
      double m = (double) this._matches (s1, s2, max_dist, out t);
      double len_s1 = (double) s1.length;
      double len_s2 = (double) s2.length;
      double a = m / len_s1;
      double b = m / len_s2;
      double c = 0;

      if ((int) m > 0)
        c = (m - t) / m;

      distance = (1.0/3.0) * (a + b + c);

      debug ("Jaro distance: %f (a = %f, b = %f, c = %f)", distance, a, b, c);

      return distance;
    }

  /**
   * stripped_char:
   *
   * Returns a stripped version of @ch, removing any case, accentuation
   * mark, or any special mark on it.
   *
   * Copied from Empathy's libempathy-gtk/empathy-live-search.c.
   *
   * Copyright (C) 2010 Collabora Ltd.
   * Copyright (C) 2007-2010 Nokia Corporation.
   *
   * Authors: Felix Kaser <felix.kaser@collabora.co.uk>
   *          Xavier Claessens <xavier.claessens@collabora.co.uk>
   *          Claudio Saavedra <csaavedra@igalia.com>
   */
  private unichar _stripped_char (unichar ch)
    {
      unichar retval[1] = { 0 };
      var utype = ch.type ();

      switch (utype)
        {
          case UnicodeType.CONTROL:
          case UnicodeType.FORMAT:
          case UnicodeType.UNASSIGNED:
          case UnicodeType.NON_SPACING_MARK:
          case UnicodeType.COMBINING_MARK:
          case UnicodeType.ENCLOSING_MARK:
            /* Ignore those */
            break;
          case UnicodeType.DECIMAL_NUMBER:
          case UnicodeType.LETTER_NUMBER:
          case UnicodeType.OTHER_NUMBER:
          case UnicodeType.CONNECT_PUNCTUATION:
          case UnicodeType.DASH_PUNCTUATION:
          case UnicodeType.CLOSE_PUNCTUATION:
          case UnicodeType.FINAL_PUNCTUATION:
          case UnicodeType.INITIAL_PUNCTUATION:
          case UnicodeType.OTHER_PUNCTUATION:
          case UnicodeType.OPEN_PUNCTUATION:
          case UnicodeType.CURRENCY_SYMBOL:
          case UnicodeType.MODIFIER_SYMBOL:
          case UnicodeType.MATH_SYMBOL:
          case UnicodeType.OTHER_SYMBOL:
          case UnicodeType.LINE_SEPARATOR:
          case UnicodeType.PARAGRAPH_SEPARATOR:
          case UnicodeType.SPACE_SEPARATOR:
            /* Replace punctuation with spaces. */
            retval[0] = ' ';
            break;
          case UnicodeType.PRIVATE_USE:
          case UnicodeType.SURROGATE:
          case UnicodeType.LOWERCASE_LETTER:
          case UnicodeType.MODIFIER_LETTER:
          case UnicodeType.OTHER_LETTER:
          case UnicodeType.TITLECASE_LETTER:
          case UnicodeType.UPPERCASE_LETTER:
          default:
            ch = ch.tolower ();
            ch.fully_decompose (false, retval);
            break;
        }

      return retval[0];
    }

  private unichar[] _strip_string (string s)
    {
      int next_idx = 0;
      uint write_idx = 0;
      unichar ch = 0;
      unichar[] output = new unichar[s.length]; // this is a safe overestimate

      while (s.get_next_char (ref next_idx, out ch))
        {
          ch = this._stripped_char (ch);
          if (ch != 0)
            {
              output[write_idx++] = ch;
            }
        }

      output.length = (int) write_idx;
      return output;
    }

  /* Calculate matches and transpositions as defined by the Jaro distance.
   */
  private int _matches (unichar[] s1, unichar[] s2, int max_dist, out double t)
    {
      int matches = 0;
      t = 0.0;
      var len_s1 = s1.length;

      unichar look_for = 0;

      for (uint idx = 0; idx < len_s1 && (look_for = s1[idx]) != 0; idx++)
        {
          int contains = this._contains (s2, look_for, idx, max_dist);
          if (contains >= 0)
            {
              matches++;
              if (contains > 0)
                t += 1.0;
            }
        }

      debug ("%d matches and %f / 2 transpositions", matches, t);

      t = t / 2.0;
      return matches;
    }

  /* If haystack contains c in pos return 0, if it contains
   * it withing the bounds of max_dist return abs(pos-pos_found).
   * If its not found, return -1.
   *
   * pos and max_dist are both in unichars.
   *
   * Note: haystack must have been validated using haystack.validate() before
   * being passed to this method. */
  private int _contains (unichar[] haystack, unichar c, uint pos, uint max_dist)
    {
      var haystack_len = haystack.length; /* in unichars */

      if (pos < haystack_len && haystack[pos] == c)
        return 0;

      uint idx = ((int) pos - (int) max_dist).clamp (0, haystack_len - 1);
      unichar ch = 0;

      while (idx < pos + max_dist && idx < haystack_len &&
          (ch = haystack[idx]) != 0)
        {
          if (ch == c)
            return ((int) pos - (int) idx).abs ();

          idx++;
        }

      return -1;
    }
}
