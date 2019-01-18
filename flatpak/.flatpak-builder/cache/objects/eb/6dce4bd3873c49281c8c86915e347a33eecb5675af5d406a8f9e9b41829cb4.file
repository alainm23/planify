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
 *       Travis Reitter <travis.reitter@collabora.co.uk>
 */

using Gee;

/* TODO: This should be converted to a nested namespace, rather than a class,
 * when folks next breaks API. Having it as a class means that a GType is always
 * registered for it, and a C constructor function created, even though
 * instantiating it is pointless as all the methods are static (and should
 * remain so). */
/**
 * Utility functions to simplify common patterns in Folks client code.
 *
 * These may be used by folks clients as well, and are part of folks' supported
 * stable API.
 *
 * @since 0.6.0
 */
public class Folks.Utils : Object
{
  internal static bool _str_equal_safe (string a, string b)
    {
      return (a != "" && b != "" && a.down () == b.down ());
    }

  /**
   * Create a new utilities object.
   *
   * This method is useless and should never be used. It will be removed in a
   * future version in favour of making the Utils class into a nested namespace.
   *
   * @return a new utilities object
   * @since 0.6.0
   */
  [Version (deprecated = true, deprecated_since = "0.7.4",
      replacement = "Folks.Utils")]
  public Utils ()
    {
      base ();
    }

  /**
   * Check whether two multi-maps of strings to strings are equal. This performs
   * a deep check for equality, checking whether both maps are of the same size,
   * and that each key maps to the same set of values in both maps.
   *
   * @param a a multi-map to compare
   * @param b another multi-map to compare
   * @return ``true`` if the multi-maps are equal, ``false`` otherwise
   *
   * @since 0.6.0
   */
  public static bool multi_map_str_str_equal (
      MultiMap<string, string> a,
      MultiMap<string, string> b)
    {
      if (a == b)
        return true;

      var a_size = a.size;
      var b_size = b.size;

      if (a_size == 0 && b_size == 0)
        {
          /* fast path: avoid the actual iteration, which creates GObjects */
          return true;
        }
      else if (a_size == b_size)
        {
          foreach (var key in a.get_keys ())
            {
              if (b.contains (key))
                {
                  var a_values = a.get (key);
                  var b_values = b.get (key);
                  if (a_values.size != b_values.size)
                    return false;

                  foreach (var a_value in a_values)
                    {
                      if (!b_values.contains (a_value))
                        return false;
                    }
                }
              else
                {
                  return false;
                }
            }
        }
      else
        {
          return false;
        }

      return true;
    }

  /**
   * Check whether two multi-maps of strings to AbstractFieldDetails are equal.
   *
   * This performs a deep check for equality, checking whether both maps are of
   * the same size, and that each key maps to the same set of values in both
   * maps.
   *
   * @param a a multi-map to compare
   * @param b another multi-map to compare
   * @return ``true`` if the multi-maps are equal, ``false`` otherwise
   *
   * @since 0.6.0
   */
  public static bool multi_map_str_afd_equal (
      MultiMap<string, AbstractFieldDetails> a,
      MultiMap<string, AbstractFieldDetails> b)
    {
      if (a == b)
        return true;

      var a_size = a.size;
      var b_size = b.size;

      if (a_size == 0 && b_size == 0)
        {
          /* fast path: avoid the actual iteration, which creates GObjects */
          return true;
        }
      else if (a_size == b_size)
        {
          foreach (var key in a.get_keys ())
            {
              if (b.contains (key))
                {
                  var a_values = a.get (key);
                  var b_values = b.get (key);
                  if (a_values.size != b_values.size)
                    return false;

                  foreach (var a_value in a_values)
                    {
                      if (!b_values.contains (a_value))
                        return false;
                    }
                }
              else
                {
                  return false;
                }
            }
        }
      else
        {
          return false;
        }

      return true;
    }

  /**
   * Check whether a set of strings to AbstractFieldDetails are equal.
   *
   * This performs a deep check for equality, checking whether both sets are of
   * the same size, and that each key maps to the same set of values in both
   * maps.
   *
   * @param a a set to compare
   * @param b another set to compare
   * @return ``true`` if the sets are equal, ``false`` otherwise
   *
   * @since 0.6.0
   */
  public static bool set_afd_equal (
      Set<AbstractFieldDetails> a,
      Set<AbstractFieldDetails> b)
    {
      if (a == b)
        return true;

      var a_size = a.size;
      var b_size = b.size;

      if (a_size == 0 && b_size == 0)
        {
          /* fast path: avoid creating the iterator, which is a GObject */
          return true;
        }
      else if (a_size == b_size)
        {
          foreach (var val in a)
            {
              if (!b.contains (val))
                {
                  return false;
                }
            }
        }
      else
        {
          return false;
        }

      return true;
    }

  /**
   * Check whether a set of AbstractFieldDetails with string values are equal.
   *
   * This performs a deep check for equality, checking whether both sets are of
   * the same size, and that each set has the same values using string compation
   * instead of AbstractFieldDetails equal function
   *
   * @param a a set to compare
   * @param b another set to compare
   * @return ``true`` if the sets are equal, ``false`` otherwise
   *
   * @since 0.9.7
   */
  public static bool set_string_afd_equal (
      Set<AbstractFieldDetails<string> > a,
      Set<AbstractFieldDetails<string> > b)
    {
      if (a == b)
        return true;

      var a_size = a.size;
      var b_size = b.size;

      if (a_size == 0 && b_size == 0)
        {
          /* fast path: avoid creating the iterator, which is a GObject */
          return true;
        }
      else if (a_size == b_size)
        {
          foreach (var a_val in a)
            {
              bool found = false;
              foreach (var b_val in b)
                {
                  if (a_val.parameters_equal (b_val) &&
                      str_equal(a_val.value, b_val.value))
                    {
                      found = true;
                    }
                }
              if (!found)
                {
                  return false;
                }
            }
        }
      else
        {
          return false;
        }

      return true;
    }
}
