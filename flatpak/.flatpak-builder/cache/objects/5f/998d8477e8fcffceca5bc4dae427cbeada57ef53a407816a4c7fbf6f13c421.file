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

using GLib;
using Gee;
using Posix;

namespace Folks.Internal
{
  public static bool equal_sets<G> (Set<G> a, Set<G> b)
    {
      if (a.size != b.size)
        return false;

      foreach (var a_elem in a)
        {
          if (!b.contains (a_elem))
            return false;
        }

      return true;
    }

#if ENABLE_PROFILING
  /* See: http://people.gnome.org/~federico/news-2006-03.html#timeline-tools */
  [PrintfFormat]
  private static void profiling_markv (string format, va_list args)
    {
      var formatted = format.vprintf (args);
      var str = "MARK: %s-%p: %s".printf (Environment.get_prgname (), Thread.self<void> (), formatted);
      access (str, F_OK);
    }
#endif

  /**
   * Emit a profiling point.
   *
   * This emits a profiling point with the given message (printf-style), which
   * can be picked up by profiling tools and timing information extracted.
   *
   * @param format printf-style message format
   * @param ... message arguments
   * @since 0.7.2
   */
  [PrintfFormat]
  public static void profiling_point (string format, ...)
    {
#if ENABLE_PROFILING
      var args = va_list ();
      Internal.profiling_markv (format, args);
#endif
    }

  /**
   * Start a profiling block.
   *
   * This emits a profiling start point with the given message (printf-style),
   * which can be picked up by profiling tools and timing information extracted.
   *
   * This is typically used in a pair with {@link Internal.profiling_end} to
   * delimit blocks of processing which need timing.
   *
   * @param format printf-style message format
   * @param ... message arguments
   * @since 0.7.2
   */
  public static void profiling_start (string format, ...)
    {
#if ENABLE_PROFILING
      var args = va_list ();
      Internal.profiling_markv ("START: " + format, args);
#endif
    }

  /**
   * End a profiling block.
   *
   * This emits a profiling end point with the given message (printf-style),
   * which can be picked up by profiling tools and timing information extracted.
   *
   * This is typically used in a pair with {@link Internal.profiling_start} to
   * delimit blocks of processing which need timing.
   *
   * @param format printf-style message format
   * @param ... message arguments
   * @since 0.7.2
   */
  public static void profiling_end (string format, ...)
    {
#if ENABLE_PROFILING
      var args = va_list ();
      Internal.profiling_markv ("END: " + format, args);
#endif
    }
}
