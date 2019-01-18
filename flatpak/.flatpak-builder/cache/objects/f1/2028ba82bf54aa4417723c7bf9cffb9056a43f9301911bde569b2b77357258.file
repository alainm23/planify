/*
 * e-source-offline.c
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
 * SECTION: e-source-offline
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for offline settings
 *
 * The #ESourceOffline extension tracks whether data from a remote
 * server should be cached locally for viewing while offline.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceOffline *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_OFFLINE);
 * ]|
 **/

#include "e-source-offline.h"

#define E_SOURCE_OFFLINE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_OFFLINE, ESourceOfflinePrivate))

struct _ESourceOfflinePrivate {
	gboolean stay_synchronized;
};

enum {
	PROP_0,
	PROP_STAY_SYNCHRONIZED
};

G_DEFINE_TYPE (
	ESourceOffline,
	e_source_offline,
	E_TYPE_SOURCE_EXTENSION)

static void
source_offline_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STAY_SYNCHRONIZED:
			e_source_offline_set_stay_synchronized (
				E_SOURCE_OFFLINE (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_offline_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STAY_SYNCHRONIZED:
			g_value_set_boolean (
				value,
				e_source_offline_get_stay_synchronized (
				E_SOURCE_OFFLINE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_source_offline_class_init (ESourceOfflineClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceOfflinePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_offline_set_property;
	object_class->get_property = source_offline_get_property;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_OFFLINE;

	g_object_class_install_property (
		object_class,
		PROP_STAY_SYNCHRONIZED,
		g_param_spec_boolean (
			"stay-synchronized",
			"StaySynchronized",
			"Keep remote content synchronized locally",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_offline_init (ESourceOffline *extension)
{
	extension->priv = E_SOURCE_OFFLINE_GET_PRIVATE (extension);
}

/**
 * e_source_offline_get_stay_synchronized:
 * @extension: an #ESourceOffline
 *
 * Returns whether data from a remote server should be cached locally
 * for viewing while offline.  Backends are responsible for implementing
 * such caching.
 *
 * Returns: whether data should be cached for offline
 *
 * Since: 3.6
 **/
gboolean
e_source_offline_get_stay_synchronized (ESourceOffline *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_OFFLINE (extension), FALSE);

	return extension->priv->stay_synchronized;
}

/**
 * e_source_offline_set_stay_synchronized:
 * @extension: an #ESourceOffline
 * @stay_synchronized: whether data should be cached for offline
 *
 * Sets whether data from a remote server should be cached locally for
 * viewing while offline.  Backends are responsible for implementing
 * such caching.
 *
 * Since: 3.6
 **/
void
e_source_offline_set_stay_synchronized (ESourceOffline *extension,
                                        gboolean stay_synchronized)
{
	g_return_if_fail (E_IS_SOURCE_OFFLINE (extension));

	if (extension->priv->stay_synchronized == stay_synchronized)
		return;

	extension->priv->stay_synchronized = stay_synchronized;

	g_object_notify (G_OBJECT (extension), "stay-synchronized");
}
