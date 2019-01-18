/*
 * e-timezone-cache.c
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 */

/**
 * SECTION: e-timezone-cache
 * @include: libecal/libecal.h
 * @short_description: An interface for caching time zone data
 *
 * Several classes (both client-side and server-side) cache #icaltimezone
 * instances internally, indexed by their TZID strings.  Classes which do
 * this should implement #ETimezoneCacheInterface to provide a consistent
 * API for accessing time zone data.
 **/

#include "e-timezone-cache.h"

G_DEFINE_INTERFACE (
	ETimezoneCache,
	e_timezone_cache,
	G_TYPE_OBJECT)

static void
e_timezone_cache_default_init (ETimezoneCacheInterface *iface)
{
	/**
	 * ETimezoneCache::timezone-added:
	 * @cache: the #ETimezoneCache which emitted the signal
	 * @zone: the newly-added #icaltimezone
	 *
	 * Emitted when a new #icaltimezone is added to @cache.
	 **/
	g_signal_new (
		"timezone-added",
		G_OBJECT_CLASS_TYPE (iface),
		G_SIGNAL_RUN_FIRST,
		G_STRUCT_OFFSET (ETimezoneCacheInterface, timezone_added),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_POINTER);
}

/**
 * e_timezone_cache_add_timezone:
 * @cache: an #ETimezoneCache
 * @zone: an #icaltimezone
 *
 * Adds a copy of @zone to @cache and emits a
 * #ETimezoneCache::timezone-added signal.  The @cache will use the TZID
 * string returned by icaltimezone_get_tzid() as the lookup key, which can
 * be passed to e_timezone_cache_get_timezone() to obtain @zone again.
 *
 * If the @cache already has an #icaltimezone with the same TZID string
 * as @zone, the @cache will remain unchanged to avoid invalidating any
 * #icaltimezone pointers which may have already been returned through
 * e_timezone_cache_get_timezone().
 *
 * Since: 3.8
 **/
void
e_timezone_cache_add_timezone (ETimezoneCache *cache,
                               icaltimezone *zone)
{
	ETimezoneCacheInterface *iface;

	g_return_if_fail (E_IS_TIMEZONE_CACHE (cache));
	g_return_if_fail (zone != NULL);

	iface = E_TIMEZONE_CACHE_GET_INTERFACE (cache);
	g_return_if_fail (iface->add_timezone != NULL);

	iface->add_timezone (cache, zone);
}

/**
 * e_timezone_cache_get_timezone:
 * @cache: an #ETimezoneCache
 * @tzid: the TZID of a timezone
 *
 * Obtains an #icaltimezone by its TZID string.  If no match is found,
 * the function returns %NULL.  The returned #icaltimezone is owned by
 * the @cache and should not be modified or freed.
 *
 * Returns: an #icaltimezone, or %NULL
 *
 * Since: 3.8
 **/
icaltimezone *
e_timezone_cache_get_timezone (ETimezoneCache *cache,
                               const gchar *tzid)
{
	ETimezoneCacheInterface *iface;

	g_return_val_if_fail (E_IS_TIMEZONE_CACHE (cache), NULL);
	g_return_val_if_fail (tzid != NULL, NULL);

	iface = E_TIMEZONE_CACHE_GET_INTERFACE (cache);
	g_return_val_if_fail (iface->get_timezone != NULL, NULL);

	return iface->get_timezone (cache, tzid);
}

/**
 * e_timezone_cache_list_timezones:
 * @cache: an #ETimezoneCache
 *
 * Returns a list of #icaltimezone instances that were explicitly added to
 * the @cache through e_timezone_cache_add_timezone().  In particular, any
 * built-in time zone data that e_timezone_cache_get_timezone() may use to
 * match a TZID string is excluded from the returned list.
 *
 * Free the returned list with g_list_free().  The list elements are owned
 * by the @cache and should not be modified or freed.
 *
 * Returns: (transfer container) (element-type icaltimezone): a #GList of
 *          #icaltimezone instances
 *
 * Since: 3.8
 **/
GList *
e_timezone_cache_list_timezones (ETimezoneCache *cache)
{
	ETimezoneCacheInterface *iface;

	g_return_val_if_fail (E_IS_TIMEZONE_CACHE (cache), NULL);

	iface = E_TIMEZONE_CACHE_GET_INTERFACE (cache);
	g_return_val_if_fail (iface->list_timezones != NULL, NULL);

	return iface->list_timezones (cache);
}

