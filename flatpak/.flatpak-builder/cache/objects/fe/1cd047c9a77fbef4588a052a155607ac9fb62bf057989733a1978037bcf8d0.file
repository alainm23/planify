/*
 * e-source-alarms.c
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
 * SECTION: e-source-alarms
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for alarm state
 *
 * The #ESourceAlarms extension tracks alarm state for a calendar.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceAlarms *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_ALARMS);
 * ]|
 **/

#include "e-source-alarms.h"

#define E_SOURCE_ALARMS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_ALARMS, ESourceAlarmsPrivate))

struct _ESourceAlarmsPrivate {
	gboolean include_me;
	gchar *last_notified;
};

enum {
	PROP_0,
	PROP_INCLUDE_ME,
	PROP_LAST_NOTIFIED
};

G_DEFINE_TYPE (
	ESourceAlarms,
	e_source_alarms,
	E_TYPE_SOURCE_EXTENSION)

static void
source_alarms_set_property (GObject *object,
                            guint property_id,
                            const GValue *value,
                            GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_INCLUDE_ME:
			e_source_alarms_set_include_me (
				E_SOURCE_ALARMS (object),
				g_value_get_boolean (value));
			return;

		case PROP_LAST_NOTIFIED:
			e_source_alarms_set_last_notified (
				E_SOURCE_ALARMS (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_alarms_get_property (GObject *object,
                            guint property_id,
                            GValue *value,
                            GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_INCLUDE_ME:
			g_value_set_boolean (
				value,
				e_source_alarms_get_include_me (
				E_SOURCE_ALARMS (object)));
			return;

		case PROP_LAST_NOTIFIED:
			g_value_take_string (
				value,
				e_source_alarms_dup_last_notified (
				E_SOURCE_ALARMS (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_alarms_finalize (GObject *object)
{
	ESourceAlarmsPrivate *priv;

	priv = E_SOURCE_ALARMS_GET_PRIVATE (object);

	g_free (priv->last_notified);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_alarms_parent_class)->finalize (object);
}

static void
e_source_alarms_class_init (ESourceAlarmsClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceAlarmsPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_alarms_set_property;
	object_class->get_property = source_alarms_get_property;
	object_class->finalize = source_alarms_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_ALARMS;

	g_object_class_install_property (
		object_class,
		PROP_INCLUDE_ME,
		g_param_spec_boolean (
			"include-me",
			"IncludeMe",
			"Include this source in alarm notifications",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_LAST_NOTIFIED,
		g_param_spec_string (
			"last-notified",
			"LastNotified",
			"Last alarm notification (in ISO 8601 format)",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_alarms_init (ESourceAlarms *extension)
{
	extension->priv = E_SOURCE_ALARMS_GET_PRIVATE (extension);
}

/**
 * e_source_alarms_get_include_me:
 * @extension: an #ESourceAlarms
 *
 * Returns whether the user should be alerted about upcoming appointments
 * in the calendar described by the #ESource to which @extension belongs.
 *
 * Alarm daemons such as evolution-alarm-notify can use this property to
 * decide which calendars to query for upcoming appointments.
 *
 * Returns: whether to show alarms for upcoming appointments
 *
 * Since: 3.6
 **/
gboolean
e_source_alarms_get_include_me (ESourceAlarms *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_ALARMS (extension), FALSE);

	return extension->priv->include_me;
}

/**
 * e_source_alarms_set_include_me:
 * @extension: an #ESourceAlarms
 * @include_me: whether to show alarms for upcoming appointments
 *
 * Sets whether the user should be alerted about upcoming appointments in
 * the calendar described by the #ESource to which @extension belongs.
 *
 * Alarm daemons such as evolution-alarm-notify can use this property to
 * decide which calendars to query for upcoming appointments.
 *
 * Since: 3.6
 **/
void
e_source_alarms_set_include_me (ESourceAlarms *extension,
                                gboolean include_me)
{
	g_return_if_fail (E_IS_SOURCE_ALARMS (extension));

	if (extension->priv->include_me == include_me)
		return;

	extension->priv->include_me = include_me;

	g_object_notify (G_OBJECT (extension), "include-me");
}

/**
 * e_source_alarms_get_last_notified:
 * @extension: an #ESourceAlarms
 *
 * Returns an ISO 8601 formatted timestamp of when the user was last
 * alerted about an upcoming appointment in the calendar described by
 * the #ESource to which @extension belongs.  If no valid timestamp
 * has been set, the function will return %NULL.
 *
 * Returns: (nullable): an ISO 8601 timestamp, or %NULL
 *
 * Since: 3.6
 **/
const gchar *
e_source_alarms_get_last_notified (ESourceAlarms *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_ALARMS (extension), NULL);

	return extension->priv->last_notified;
}

/**
 * e_source_alarms_dup_last_notified:
 * @extension: an #ESourceAlarms
 *
 * Thread-safe variation of e_source_alarms_get_last_notified().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: (nullable): a newly-allocated copy of #ESourceAlarms:last-notified
 *
 * Since: 3.6
 **/
gchar *
e_source_alarms_dup_last_notified (ESourceAlarms *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_ALARMS (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_alarms_get_last_notified (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_alarms_set_last_notified:
 * @extension: an #ESourceAlarms
 * @last_notified: (allow-none): an ISO 8601 timestamp, or %NULL
 *
 * Sets an ISO 8601 formatted timestamp of when the user was last
 * alerted about an upcoming appointment in the calendar described
 * by the #ESource to which @extension belongs.
 *
 * If @last_notified is non-%NULL, the function will validate the
 * timestamp before setting the #ESourceAlarms:last-notified property.
 * Invalid timestamps are discarded with a runtime warning.
 *
 * Generally, this function should only be called by an alarm daemon
 * such as evolution-alarm-notify.
 *
 * Since: 3.6
 **/
void
e_source_alarms_set_last_notified (ESourceAlarms *extension,
                                   const gchar *last_notified)
{
	g_return_if_fail (E_IS_SOURCE_ALARMS (extension));

	if (last_notified && !*last_notified)
		last_notified = NULL;

	if (last_notified != NULL) {
		GTimeVal time_val;

		if (!g_time_val_from_iso8601 (last_notified, &time_val)) {
			g_warning (
				"%s: Invalid timestamp: '%s'",
				G_STRFUNC, last_notified);
			return;
		}
	}

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (g_strcmp0 (extension->priv->last_notified, last_notified) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->last_notified);
	extension->priv->last_notified = g_strdup (last_notified);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "last-notified");
}
