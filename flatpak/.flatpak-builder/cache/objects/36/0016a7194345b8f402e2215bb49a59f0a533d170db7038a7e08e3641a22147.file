/*
 * Copyright (C) 2008 Novell, Inc.
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
 * Authors: Patrick Ohly <patrick.ohly@gmx.de>
 */

#include "evolution-data-server-config.h"

#include <libical/ical.h>

#include "e-cal-check-timezones.h"
#include <libecal/e-cal.h>
#include <libecal/e-cal-client.h>
#include <string.h>
#include <ctype.h>

/*
 * Matches a location to a system timezone definition via a fuzzy
 * search and returns the matching TZID, or NULL if none found.
 *
 * Currently simply strips a suffix introduced by a hyphen,
 * as in "America/Denver-(Standard)".
 */
static const gchar *
e_cal_match_location (const gchar *location)
{
	icaltimezone *icomp;
	const gchar *tail;
	gsize len;
	gchar *buffer;

	icomp = icaltimezone_get_builtin_timezone (location);
	if (icomp) {
		return icaltimezone_get_tzid (icomp);
	}

	/* try a bit harder by stripping trailing suffix */
	tail = strrchr (location, '-');
	len = tail ? (tail - location) : strlen (location);
	buffer = g_malloc (len + 1);

	if (buffer) {
		memcpy (buffer, location, len);
		buffer[len] = 0;
		icomp = icaltimezone_get_builtin_timezone (buffer);
		g_free (buffer);
		if (icomp) {
			return icaltimezone_get_tzid (icomp);
		}
	}

	return NULL;
}

/**
 * e_cal_match_tzid:
 * @tzid: a timezone ID
 *
 * Matches @tzid against the system timezone definitions
 * and returns the matching TZID, or %NULL if none found
 *
 * Since: 2.24
 */
const gchar *
e_cal_match_tzid (const gchar *tzid)
{
	const gchar *location;
	const gchar *systzid = NULL;
	gsize len = strlen (tzid);
	gssize eostr;

	/*
	 * Try without any trailing spaces/digits: they might have been added
	 * by e_cal_check_timezones() in order to distinguish between
	 * different incompatible definitions. At that time mapping
	 * to system time zones must have failed, but perhaps now
	 * we have better code and it succeeds...
	 */
	eostr = len - 1;
	while (eostr >= 0 && isdigit (tzid[eostr])) {
		eostr--;
	}
	while (eostr >= 0 && isspace (tzid[eostr])) {
		eostr--;
	}
	if (eostr + 1 < len) {
		gchar *strippedtzid = g_strndup (tzid, eostr + 1);
		if (strippedtzid) {
			systzid = e_cal_match_tzid (strippedtzid);
			g_free (strippedtzid);
			if (systzid) {
				goto done;
			}
		}
	}

	/*
	 * old-style Evolution: /softwarestudio.org/Olson_20011030_5/America/Denver
	 *
	 * jump from one slash to the next and check whether the remainder
	 * is a known location; start with the whole string (just in case)
	 */
	for (location = tzid;
		 location && location[0];
		 location = strchr (location + 1, '/')) {
		systzid = e_cal_match_location (
			location[0] == '/' ?
			location + 1 : location);
		if (systzid) {
			goto done;
		}
	}

	/* TODO: lookup table for Exchange TZIDs */

 done:
	if (systzid && !strcmp (systzid, "UTC")) {
		/*
		 * UTC is special: it doesn't have a real VTIMEZONE in
		 * EDS. Matching some pseudo VTTIMEZONE with UTC in the TZID
		 * to our internal UTC "timezone" breaks
		 * e_cal_check_timezones() (it patches the event to use
		 * TZID=UTC, which cannot be exported correctly later on) and
		 * e_cal_get_timezone() (triggers an assert).
		 *
		 * So better avoid matching against it...
		 */
		return NULL;
	} else {
		return systzid;
	}
}

static void
patch_tzids (icalcomponent *subcomp,
             GHashTable *mapping)
{
	gchar *tzid = NULL;

	if (icalcomponent_isa (subcomp) != ICAL_VTIMEZONE_COMPONENT) {
		icalproperty *prop = icalcomponent_get_first_property (
			subcomp, ICAL_ANY_PROPERTY);
		while (prop) {
			icalparameter *param = icalproperty_get_first_parameter (
				prop, ICAL_TZID_PARAMETER);
			while (param) {
				const gchar *oldtzid;
				const gchar *newtzid;

				g_free (tzid);
				tzid = g_strdup (icalparameter_get_tzid (param));

				if (!g_hash_table_lookup_extended (
					mapping, tzid,
					(gpointer *) &oldtzid,
					(gpointer *) &newtzid)) {
					/* Corresponding VTIMEZONE not seen before! */
					newtzid = e_cal_match_tzid (tzid);
				}
				if (newtzid) {
					icalparameter_set_tzid (param, newtzid);
				}
				param = icalproperty_get_next_parameter (
					prop, ICAL_TZID_PARAMETER);
			}
			prop = icalcomponent_get_next_property (
				subcomp, ICAL_ANY_PROPERTY);
		}
	}

	g_free (tzid);
}

static void
addsystemtz (gpointer key,
             gpointer value,
             gpointer user_data)
{
	const gchar *tzid = key;
	icalcomponent *comp = user_data;
	icaltimezone *zone;

	zone = icaltimezone_get_builtin_timezone_from_tzid (tzid);
	if (zone) {
		icalcomponent_add_component (
			comp,
			icalcomponent_new_clone (
			icaltimezone_get_component (zone)));
	}
}

/**
 * e_cal_check_timezones:
 * @comp:     a VCALENDAR containing a list of
 *            VTIMEZONE and arbitrary other components, in
 *            arbitrary order: these other components are
 *            modified by this call
 * @comps: (element-type icalcomponent) (allow-none): a list of #icalcomponent
 * instances which also have to be patched; may be %NULL
 * @tzlookup: (allow-none): a callback function which is called to retrieve
 *            a calendar's VTIMEZONE definition; the returned
 *            definition is *not* freed by e_cal_check_timezones()
 *            (to be compatible with e_cal_get_timezone());
 *            %NULL indicates that no such timezone exists
 *            or an error occurred
 * @custom:   an arbitrary pointer which is passed through to
 *            the tzlookup function
 * @error:    an error description in case of a failure
 *
 * This function cleans up VEVENT, VJOURNAL, VTODO and VTIMEZONE
 * items which are to be imported into Evolution.
 *
 * Using VTIMEZONE definitions is problematic because they cannot be
 * updated properly when timezone definitions change. They are also
 * incomplete (for compatibility reason only one set of rules for
 * summer saving changes can be included, even if different rules
 * apply in different years). This function looks for matches of the
 * used TZIDs against system timezones and replaces such TZIDs with
 * the corresponding system timezone. This works for TZIDs containing
 * a location (found via a fuzzy string search) and for Outlook TZIDs
 * (via a hard-coded lookup table).
 *
 * Some programs generate broken meeting invitations with TZID, but
 * without including the corresponding VTIMEZONE. Importing such
 * invitations unchanged causes problems later on (meeting displayed
 * incorrectly, e_cal_get_component_as_string() fails). The situation
 * where this occurred in the past (found by a SyncEvolution user) is
 * now handled via the location based mapping.
 *
 * If this mapping fails, this function also deals with VTIMEZONE
 * conflicts: such conflicts occur when the calendar already contains
 * an old VTIMEZONE definition with the same TZID, but different
 * summer saving rules. Replacing the VTIMEZONE potentially breaks
 * displaying of old events, whereas not replacing it breaks the new
 * events (the behavior in Evolution <= 2.22.1).
 *
 * The way this problem is resolved is by renaming the new VTIMEZONE
 * definition until the TZID is unique. A running count is appended to
 * the TZID. All items referencing the renamed TZID are adapted
 * accordingly.
 *
 * Returns: TRUE if successful, FALSE otherwise.
 *
 * Since: 2.24
 *
 * Deprecated: 3.2: Use e_cal_client_check_timezones() instead.
 */
gboolean
e_cal_check_timezones (icalcomponent *comp,
                       GList *comps,
                       icaltimezone *(*tzlookup)(const gchar *tzid,
                                                 gconstpointer custom,
                                                 GError **error),
                       gconstpointer custom,
                       GError **error)
{
	gboolean success = TRUE;
	icalcomponent *subcomp = NULL;
	icaltimezone *zone = icaltimezone_new ();
	gchar *key = NULL, *value = NULL;
	gchar *buffer = NULL;
	gchar *zonestr = NULL;
	gchar *tzid = NULL;
	GList *l;

	/* a hash from old to new tzid; strings dynamically allocated */
	GHashTable *mapping = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	/* a hash of all system time zone IDs which have to be added; strings are shared with mapping hash */
	GHashTable *systemtzids = g_hash_table_new (g_str_hash, g_str_equal);

	*error = NULL;

	if (!mapping || !zone) {
		goto nomem;
	}

	/* iterate over all VTIMEZONE definitions */
	subcomp = icalcomponent_get_first_component (
		comp, ICAL_VTIMEZONE_COMPONENT);
	while (subcomp) {
		if (icaltimezone_set_component (zone, subcomp)) {
			g_free (tzid);
			tzid = g_strdup (icaltimezone_get_tzid (zone));
			if (tzid) {
				const gchar *newtzid = e_cal_match_tzid (tzid);
				if (newtzid) {
					/* matched against system time zone */
					g_free (key);
					key = g_strdup (tzid);
					if (!key) {
						goto nomem;
					}

					g_free (value);
					value = g_strdup (newtzid);
					if (!value) {
						goto nomem;
					}

					g_hash_table_insert (mapping, key, value);
					g_hash_table_insert (systemtzids, value, NULL);
					key =
						value = NULL;
				} else {
					gint counter;

					zonestr = icalcomponent_as_ical_string_r (subcomp);

					/* check for collisions with existing timezones */
					for (counter = 0;
						 counter < 100 /* sanity limit */;
						 counter++) {
						icaltimezone *existing_zone;

						if (counter) {
							g_free (value);
							value = g_strdup_printf ("%s %d", tzid, counter);
						}
						existing_zone = tzlookup (
							counter ? value : tzid,
							custom, error);
						if (!existing_zone) {
							if (*error) {
								goto failed;
							} else {
								break;
							}
						}
						g_free (buffer);
						buffer = icalcomponent_as_ical_string_r (icaltimezone_get_component (existing_zone));

						if (counter) {
							gchar *fulltzid = g_strdup_printf ("TZID:%s", value);
							gsize baselen = strlen ("TZID:") + strlen (tzid);
							gsize fulllen = strlen (fulltzid);
							gchar *tzidprop;
							/*
							 * Map TZID with counter suffix back to basename.
							 */
							tzidprop = strstr (buffer, fulltzid);
							if (tzidprop) {
								memmove (
									tzidprop + baselen,
									tzidprop + fulllen,
									strlen (tzidprop + fulllen) + 1);
							}
							g_free (fulltzid);
						}

						/*
						 * If the strings are identical, then the
						 * VTIMEZONE definitions are identical.  If
						 * they are not identical, then VTIMEZONE
						 * definitions might still be semantically
						 * correct and we waste some space by
						 * needlesly duplicating the VTIMEZONE. This
						 * is expected to occur rarely (if at all) in
						 * practice.
						 */
						if (!strcmp (zonestr, buffer)) {
							break;
						}
					}

					if (!counter) {
						/* does not exist, nothing to do */
					} else {
						/* timezone renamed */
						icalproperty *prop = icalcomponent_get_first_property (
							subcomp, ICAL_TZID_PROPERTY);
						while (prop) {
							icalproperty_set_value_from_string (prop, value, "NO");
							prop = icalcomponent_get_next_property (
								subcomp, ICAL_ANY_PROPERTY);
						}
						g_free (key);
						key = g_strdup (tzid);
						g_hash_table_insert (mapping, key, value);
						key = value = NULL;
					}
				}
			}
		}

		subcomp = icalcomponent_get_next_component (
			comp, ICAL_VTIMEZONE_COMPONENT);
	}

	/*
	 * now replace all TZID parameters in place
	 */
	subcomp = icalcomponent_get_first_component (
		comp, ICAL_ANY_COMPONENT);
	while (subcomp) {
		/*
		 * Leave VTIMEZONE unchanged, iterate over properties of
		 * everything else.
		 *
		 * Note that no attempt is made to remove unused VTIMEZONE
		 * definitions. That would just make the code more complex for
		 * little additional gain. However, newly used time zones are
		 * added below.
		 */
		patch_tzids (subcomp, mapping);
		subcomp = icalcomponent_get_next_component (
			comp, ICAL_ANY_COMPONENT);
	}

	for (l = comps; l; l = l->next) {
		patch_tzids (l->data, mapping);
	}

	/*
	 * add system time zones that we mapped to: adding them ensures
	 * that the VCALENDAR remains consistent
	 */
	g_hash_table_foreach (systemtzids, addsystemtz, comp);

	goto done;
 nomem:
	/* set gerror for "out of memory" if possible, otherwise abort via g_error() */
	*error = g_error_new(E_CALENDAR_ERROR, E_CALENDAR_STATUS_OTHER_ERROR, "out of memory");
	if (!*error) {
		g_error ("e_cal_check_timezones(): out of memory, cannot proceed - sorry!");
	}
 failed:
	/* gerror should have been set already */
	success = FALSE;
 done:
	if (mapping) {
		g_hash_table_destroy (mapping);
	}
	if (systemtzids) {
		g_hash_table_destroy (systemtzids);
	}
	if (zone) {
		icaltimezone_free (zone, 1);
	}
	g_free (tzid);
	g_free (zonestr);
	g_free (buffer);
	g_free (key);
	g_free (value);

	return success;
}

/**
 * e_cal_tzlookup_ecal:
 * @tzid: ID of the timezone to lookup
 * @custom: must be a valid #ECal pointer
 * @error: an error description in case of a failure
 *
 * An implementation of the tzlookup callback which clients
 * can use. Calls e_cal_get_timezone().
 *
 * Returns: A timezone object, or %NULL on failure. This object is owned
 *   by the @custom, thus do not free it.
 *
 * Since: 2.24
 *
 * Deprecated: 3.2: Use e_cal_client_tzlookup() instead.
 */
icaltimezone *
e_cal_tzlookup_ecal (const gchar *tzid,
                     gconstpointer custom,
                     GError **error)
{
	ECal *ecal = (ECal *) custom;
	icaltimezone *zone = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (ecal != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL (ecal), NULL);

	if (e_cal_get_timezone (ecal, tzid, &zone, &local_error)) {
		g_warn_if_fail (local_error == NULL);
		return zone;
	}

	if (g_error_matches (local_error, E_CALENDAR_ERROR,
		E_CALENDAR_STATUS_OBJECT_NOT_FOUND)) {
		/* We had to trigger this error to check for the
		 * timezone existance, clear it and return NULL. */
		g_clear_error (&local_error);
	}

	g_propagate_error (error, local_error);

	return NULL;
}

/**
 * e_cal_tzlookup_icomp:
 * @tzid: ID of the timezone to lookup
 * @custom: must be a icalcomponent pointer which contains
 *          either a VCALENDAR with VTIMEZONEs or VTIMEZONES
 *          directly
 * @error: an error description in case of a failure
 *
 * An implementation of the tzlookup callback which backends
 * like the file backend can use. Searches for the timezone
 * in the component list.
 *
 * Returns: A timezone object, or %NULL if not found inside @custom. This object is owned
 *   by the @custom, thus do not free it.
 *
 * Since: 2.24
 *
 * Deprecated: 3.2: Use e_cal_client_tzlookup_icomp() instead.
 **/
icaltimezone *
e_cal_tzlookup_icomp (const gchar *tzid,
                      gconstpointer custom,
                      GError **error)
{
    icalcomponent *icomp = (icalcomponent *) custom;

    return icalcomponent_get_timezone (icomp, (gchar *) tzid);
}

/**
 * e_cal_client_check_timezones:
 * @comp:     a VCALENDAR containing a list of
 *            VTIMEZONE and arbitrary other components, in
 *            arbitrary order: these other components are
 *            modified by this call
 * @comps: (element-type icalcomponent) (allow-none): a list of #icalcomponent
 * instances which also have to be patched; may be %NULL
 * @tzlookup: a callback function which is called to retrieve
 *            a calendar's VTIMEZONE definition; the returned
 *            definition is *not* freed by e_cal_client_check_timezones()
 *            (to be compatible with e_cal_get_timezone());
 *            NULL indicates that no such timezone exists
 *            or an error occurred
 * @ecalclient: an arbitrary pointer which is passed through to
 *            the @tzlookup function
 * @cancellable: a #GCancellable to use in @tzlookup function
 * @error:    an error description in case of a failure
 *
 * This function cleans up VEVENT, VJOURNAL, VTODO and VTIMEZONE
 * items which are to be imported into Evolution.
 *
 * Using VTIMEZONE definitions is problematic because they cannot be
 * updated properly when timezone definitions change. They are also
 * incomplete (for compatibility reason only one set of rules for
 * summer saving changes can be included, even if different rules
 * apply in different years). This function looks for matches of the
 * used TZIDs against system timezones and replaces such TZIDs with
 * the corresponding system timezone. This works for TZIDs containing
 * a location (found via a fuzzy string search) and for Outlook TZIDs
 * (via a hard-coded lookup table).
 *
 * Some programs generate broken meeting invitations with TZID, but
 * without including the corresponding VTIMEZONE. Importing such
 * invitations unchanged causes problems later on (meeting displayed
 * incorrectly, e_cal_get_component_as_string() fails). The situation
 * where this occurred in the past (found by a SyncEvolution user) is
 * now handled via the location based mapping.
 *
 * If this mapping fails, this function also deals with VTIMEZONE
 * conflicts: such conflicts occur when the calendar already contains
 * an old VTIMEZONE definition with the same TZID, but different
 * summer saving rules. Replacing the VTIMEZONE potentially breaks
 * displaying of old events, whereas not replacing it breaks the new
 * events (the behavior in Evolution <= 2.22.1).
 *
 * The way this problem is resolved is by renaming the new VTIMEZONE
 * definition until the TZID is unique. A running count is appended to
 * the TZID. All items referencing the renamed TZID are adapted
 * accordingly.
 *
 * Returns: %TRUE if successful, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_client_check_timezones (icalcomponent *comp,
                              GList *comps,
                              icaltimezone *(*tzlookup) (const gchar *tzid,
                                                         gconstpointer ecalclient,
                                                         GCancellable *cancellable,
                                                         GError **error),
                              gconstpointer ecalclient,
                              GCancellable *cancellable,
                              GError **error)
{
	gboolean success = TRUE;
	icalcomponent *subcomp = NULL;
	icaltimezone *zone = icaltimezone_new ();
	gchar *key = NULL, *value = NULL;
	gchar *buffer = NULL;
	gchar *zonestr = NULL;
	gchar *tzid = NULL;
	GList *l;

	/* a hash from old to new tzid; strings dynamically allocated */
	GHashTable *mapping = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	/* a hash of all system time zone IDs which have to be added; strings are shared with mapping hash */
	GHashTable *systemtzids = g_hash_table_new (g_str_hash, g_str_equal);

	*error = NULL;

	if (!mapping || !zone) {
		goto nomem;
	}

	/* iterate over all VTIMEZONE definitions */
	subcomp = icalcomponent_get_first_component (comp, ICAL_VTIMEZONE_COMPONENT);
	while (subcomp) {
		if (icaltimezone_set_component (zone, subcomp)) {
			g_free (tzid);
			tzid = g_strdup (icaltimezone_get_tzid (zone));
			if (tzid) {
				const gchar *newtzid = e_cal_match_tzid (tzid);
				if (newtzid) {
					/* matched against system time zone */
					g_free (key);
					key = g_strdup (tzid);
					if (!key) {
						goto nomem;
					}

					g_free (value);
					value = g_strdup (newtzid);
					if (!value) {
						goto nomem;
					}

					g_hash_table_insert (mapping, key, value);
					g_hash_table_insert (systemtzids, value, NULL);
					key = value = NULL;
				} else {
					gint counter;

					zonestr = icalcomponent_as_ical_string_r (subcomp);

					/* check for collisions with existing timezones */
					for (counter = 0;
					     counter < 100 /* sanity limit */;
					     counter++) {
						icaltimezone *existing_zone;

						if (counter) {
							g_free (value);
							value = g_strdup_printf ("%s %d", tzid, counter);
						}
						existing_zone = tzlookup (counter ? value : tzid, ecalclient, cancellable, error);
						if (!existing_zone) {
							if (*error) {
								goto failed;
							} else {
								break;
							}
						}
						g_free (buffer);
						buffer = icalcomponent_as_ical_string_r (icaltimezone_get_component (existing_zone));

						if (counter) {
							gchar *fulltzid = g_strdup_printf ("TZID:%s", value);
							gsize baselen = strlen ("TZID:") + strlen (tzid);
							gsize fulllen = strlen (fulltzid);
							gchar *tzidprop;
							/*
							 * Map TZID with counter suffix back to basename.
							 */
							tzidprop = strstr (buffer, fulltzid);
							if (tzidprop) {
								memmove (
									tzidprop + baselen,
									tzidprop + fulllen,
									strlen (tzidprop + fulllen) + 1);
							}
							g_free (fulltzid);
						}

						/*
						 * If the strings are identical, then the
						 * VTIMEZONE definitions are identical.  If
						 * they are not identical, then VTIMEZONE
						 * definitions might still be semantically
						 * correct and we waste some space by
						 * needlesly duplicating the VTIMEZONE. This
						 * is expected to occur rarely (if at all) in
						 * practice.
						 */
						if (!strcmp (zonestr, buffer)) {
							break;
						}
					}

					if (!counter) {
						/* does not exist, nothing to do */
					} else {
						/* timezone renamed */
						icalproperty *prop = icalcomponent_get_first_property (subcomp, ICAL_TZID_PROPERTY);
						while (prop) {
							icalproperty_set_value_from_string (prop, value, "NO");
							prop = icalcomponent_get_next_property (subcomp, ICAL_ANY_PROPERTY);
						}
						g_free (key);
						key = g_strdup (tzid);
						g_hash_table_insert (mapping, key, value);
						key = value = NULL;
					}
				}
			}
		}

		subcomp = icalcomponent_get_next_component (comp, ICAL_VTIMEZONE_COMPONENT);
	}

	/*
	 * now replace all TZID parameters in place
	 */
	subcomp = icalcomponent_get_first_component (comp, ICAL_ANY_COMPONENT);
	while (subcomp) {
		/*
		 * Leave VTIMEZONE unchanged, iterate over properties of
		 * everything else.
		 *
		 * Note that no attempt is made to remove unused VTIMEZONE
		 * definitions. That would just make the code more complex for
		 * little additional gain. However, newly used time zones are
		 * added below.
		 */
		patch_tzids (subcomp, mapping);
		subcomp = icalcomponent_get_next_component (comp, ICAL_ANY_COMPONENT);
	}

	for (l = comps; l; l = l->next) {
		patch_tzids (l->data, mapping);
	}

	/*
	 * add system time zones that we mapped to: adding them ensures
	 * that the VCALENDAR remains consistent
	 */
	g_hash_table_foreach (systemtzids, addsystemtz, comp);

	goto done;
 nomem:
	/* set gerror for "out of memory" if possible, otherwise abort via g_error() */
	*error = g_error_new (E_CLIENT_ERROR, E_CLIENT_ERROR_OTHER_ERROR, "out of memory");
	if (!*error) {
		g_error ("e_cal_check_timezones(): out of memory, cannot proceed - sorry!");
	}
 failed:
	/* gerror should have been set already */
	success = FALSE;
 done:
	if (mapping) {
		g_hash_table_destroy (mapping);
	}
	if (systemtzids) {
		g_hash_table_destroy (systemtzids);
	}
	if (zone) {
		icaltimezone_free (zone, 1);
	}
	g_free (tzid);
	g_free (zonestr);
	g_free (buffer);
	g_free (key);
	g_free (value);

	return success;
}

/**
 * e_cal_client_tzlookup:
 * @tzid: ID of the timezone to lookup
 * @ecalclient: must be a valid #ECalClient pointer
 * @cancellable: an optional #GCancellable to use, or %NULL
 * @error: an error description in case of a failure
 *
 * An implementation of the tzlookup callback which clients
 * can use. Calls e_cal_client_get_timezone_sync().
 *
 * Returns: A timezone object, or %NULL on failure. This object is owned
 *   by the @ecalclient, thus do not free it.
 *
 * Since: 3.2
 */
icaltimezone *
e_cal_client_tzlookup (const gchar *tzid,
                       gconstpointer ecalclient,
                       GCancellable *cancellable,
                       GError **error)
{
	ECalClient *cal_client = (ECalClient *) ecalclient;
	icaltimezone *zone = NULL;
	GError *local_error = NULL;

	g_return_val_if_fail (cal_client != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_CLIENT (cal_client), NULL);

	if (e_cal_client_get_timezone_sync (cal_client, tzid, &zone, cancellable, &local_error)) {
		g_warn_if_fail (local_error == NULL);
		return zone;
	}

	if (g_error_matches (local_error, E_CAL_CLIENT_ERROR, E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND)) {
		/* We had to trigger this error to check for the
		 * timezone existance, clear it and return NULL. */
		g_clear_error (&local_error);
	}

	if (local_error)
		g_propagate_error (error, local_error);

	return NULL;
}

/**
 * e_cal_client_tzlookup_icomp:
 * @tzid: ID of the timezone to lookup
 * @custom: must be a icalcomponent pointer which contains
 *          either a VCALENDAR with VTIMEZONEs or VTIMEZONES
 *          directly
 * @cancellable: an optional #GCancellable to use, or %NULL
 * @error: an error description in case of a failure
 *
 * An implementation of the tzlookup callback which backends
 * like the file backend can use. Searches for the timezone
 * in the component list.
 *
 * Returns: A timezone object, or %NULL if not found inside @custom. This object is owned
 *   by the @custom, thus do not free it.
 *
 * Since: 3.2
 */
icaltimezone *
e_cal_client_tzlookup_icomp (const gchar *tzid,
                             gconstpointer custom,
                             GCancellable *cancellable,
                             GError **error)
{
	icalcomponent *icomp = (icalcomponent *) custom;

	return icalcomponent_get_timezone (icomp, (gchar *) tzid);
}
