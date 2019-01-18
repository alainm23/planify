/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Evolution calendar - generic backend class
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Rodrigo Moya <rodrigo@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include <glib/gi18n-lib.h>

#include "e-cal-backend-util.h"

/**
 * e_cal_backend_mail_account_get_default:
 * @registry: an #ESourceRegistry
 * @address: placeholder for default address
 * @name: placeholder for name
 *
 * Retrieve the default mail account as stored in Evolution configuration.
 *
 * Returns: TRUE if there is a default account, FALSE otherwise.
 */
gboolean
e_cal_backend_mail_account_get_default (ESourceRegistry *registry,
                                        gchar **address,
                                        gchar **name)
{
	ESource *source;
	ESourceMailIdentity *extension;
	const gchar *extension_name;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), FALSE);

	source = e_source_registry_ref_default_mail_identity (registry);

	if (source == NULL)
		return FALSE;

	extension_name = E_SOURCE_EXTENSION_MAIL_IDENTITY;
	extension = e_source_get_extension (source, extension_name);

	if (address != NULL)
		*address = e_source_mail_identity_dup_address (extension);

	if (name != NULL)
		*name = e_source_mail_identity_dup_name (extension);

	g_object_unref (source);

	return TRUE;
}

/**
 * e_cal_backend_mail_account_is_valid:
 * @registry: an #ESourceRegistry
 * @user: user name for the account to check
 * @name: placeholder for the account name
 *
 * Checks that a mail account is valid, and returns its name.
 *
 * Returns: TRUE if the account is valid, FALSE if not.
 */
gboolean
e_cal_backend_mail_account_is_valid (ESourceRegistry *registry,
                                     const gchar *user,
                                     gchar **name)
{
	GList *list, *iter;
	const gchar *extension_name;
	gboolean valid = FALSE;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), FALSE);
	g_return_val_if_fail (user != NULL, FALSE);

	extension_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;

	list = e_source_registry_list_enabled (registry, extension_name);

	for (iter = list; iter != NULL; iter = g_list_next (iter)) {
		ESource *source = E_SOURCE (iter->data);
		ESourceMailAccount *mail_account;
		ESourceMailIdentity *mail_identity;
		const gchar *uid;
		gboolean match = FALSE;
		gchar *address;

		extension_name = E_SOURCE_EXTENSION_MAIL_ACCOUNT;
		mail_account = e_source_get_extension (source, extension_name);
		uid = e_source_mail_account_get_identity_uid (mail_account);

		if (uid == NULL)
			continue;

		source = e_source_registry_ref_source (registry, uid);

		if (source == NULL)
			continue;

		extension_name = E_SOURCE_EXTENSION_MAIL_IDENTITY;

		if (!e_source_has_extension (source, extension_name)) {
			g_object_unref (source);
			continue;
		}

		mail_identity = e_source_get_extension (source, extension_name);
		address = e_source_mail_identity_dup_address (mail_identity);

		if (address != NULL) {
			match = (g_ascii_strcasecmp (address, user) == 0);
			g_free (address);
		}

		if (!match) {
			GHashTable *aliases;

			aliases = e_source_mail_identity_get_aliases_as_hash_table (mail_identity);
			if (aliases) {
				match = g_hash_table_contains (aliases, user);
				g_hash_table_destroy (aliases);
			}
		}

		if (match && name != NULL)
			*name = e_source_dup_display_name (source);

		g_object_unref (source);

		if (match) {
			valid = TRUE;
			break;
		}
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	return valid;
}

static gboolean
is_attendee_declined (GSList *declined_attendees,
                      const gchar *email,
		      GHashTable *aliases)
{
	GSList *iter;

	if (!email && !aliases)
		return FALSE;

	for (iter = declined_attendees; iter; iter = g_slist_next (iter)) {
		const gchar *attendee = iter->data;

		if (!attendee)
			continue;

		if ((email && g_ascii_strcasecmp (email, attendee) == 0) ||
		    (aliases && g_hash_table_contains (aliases, attendee))) {
			return TRUE;
		}
	}

	return FALSE;
}

/**
 * e_cal_backend_user_declined:
 * @registry: an #ESourceRegistry
 * @icalcomp: component where to check
 *
 * Returns: Whether icalcomp contains attendee with a mail same as any of
 *          configured enabled mail account and whether this user declined.
 *
 * Since: 2.26
 **/
gboolean
e_cal_backend_user_declined (ESourceRegistry *registry,
                             icalcomponent *icalcomp)
{
	GList *list, *iter;
	GSList *declined_attendees = NULL;
	gboolean declined = FALSE;
	icalproperty *prop;
	icalparameter *param;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), FALSE);
	g_return_val_if_fail (icalcomp != NULL, FALSE);

	/* First test whether there is any declined attendee at all and remember his/her address */
	for (prop = icalcomponent_get_first_property (icalcomp, ICAL_ATTENDEE_PROPERTY);
	     prop != NULL;
	     prop = icalcomponent_get_next_property (icalcomp, ICAL_ATTENDEE_PROPERTY)) {
		param = icalproperty_get_first_parameter (prop, ICAL_PARTSTAT_PARAMETER);

		if (param && icalparameter_get_partstat (param) == ICAL_PARTSTAT_DECLINED) {
			gchar *attendee;
			gchar *address;

			attendee = icalproperty_get_value_as_string_r (prop);
			if (attendee) {
				if (!g_ascii_strncasecmp (attendee, "mailto:", 7))
					address = g_strdup (attendee + 7);
				else
					address = g_strdup (attendee);

				address = g_strstrip (address);

				if (address && *address)
					declined_attendees = g_slist_prepend (declined_attendees, address);
				else
					g_free (address);

				g_free (attendee);
			}
		}
	}

	if (!declined_attendees)
		return FALSE;

	list = e_source_registry_list_enabled (registry, E_SOURCE_EXTENSION_MAIL_IDENTITY);

	for (iter = list; iter != NULL && !declined; iter = g_list_next (iter)) {
		ESource *source = E_SOURCE (iter->data);
		ESourceMailIdentity *extension;
		GHashTable *aliases;
		const gchar *address;

		extension = e_source_get_extension (source, E_SOURCE_EXTENSION_MAIL_IDENTITY);
		address = e_source_mail_identity_get_address (extension);
		aliases = e_source_mail_identity_get_aliases_as_hash_table (extension);

		declined = is_attendee_declined (declined_attendees, address, aliases);

		if (aliases)
			g_hash_table_destroy (aliases);
	}

	g_slist_free_full (declined_attendees, g_free);
	g_list_free_full (list, g_object_unref);

	return declined;
}
