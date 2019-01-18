/*
 * e-source-backend.c
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
 * SECTION: e-source-backend
 * @include: libedataserver/libedataserver.h
 * @short_description: Base class for backend-based data sources
 *
 * #ESourceBackend is an abstract base class for data sources requiring
 * an associated backend to function.  The extension merely records the
 * name of the backend the data source should be paired with.
 **/

#include "e-source-backend.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_BACKEND_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_BACKEND, ESourceBackendPrivate))

struct _ESourceBackendPrivate {
	gchar *backend_name;
};

enum {
	PROP_0,
	PROP_BACKEND_NAME
};

G_DEFINE_ABSTRACT_TYPE (
	ESourceBackend,
	e_source_backend,
	E_TYPE_SOURCE_EXTENSION)

static void
source_backend_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BACKEND_NAME:
			e_source_backend_set_backend_name (
				E_SOURCE_BACKEND (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_backend_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_BACKEND_NAME:
			g_value_take_string (
				value,
				e_source_backend_dup_backend_name (
				E_SOURCE_BACKEND (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_backend_finalize (GObject *object)
{
	ESourceBackendPrivate *priv;

	priv = E_SOURCE_BACKEND_GET_PRIVATE (object);

	g_free (priv->backend_name);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_backend_parent_class)->finalize (object);
}

static void
e_source_backend_class_init (ESourceBackendClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ESourceBackendPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_backend_set_property;
	object_class->get_property = source_backend_get_property;
	object_class->finalize = source_backend_finalize;

	/* We do not provide an extension name,
	 * which is why the class is abstract. */

	g_object_class_install_property (
		object_class,
		PROP_BACKEND_NAME,
		g_param_spec_string (
			"backend-name",
			"Backend Name",
			"The name of the backend handling the data source",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_backend_init (ESourceBackend *extension)
{
	extension->priv = E_SOURCE_BACKEND_GET_PRIVATE (extension);
}

/**
 * e_source_backend_get_backend_name:
 * @extension: an #ESourceBackend
 *
 * Returns the backend name for @extension.
 *
 * Returns: the backend name for @extension
 *
 * Since: 3.6
 **/
const gchar *
e_source_backend_get_backend_name (ESourceBackend *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_BACKEND (extension), NULL);

	return extension->priv->backend_name;
}

/**
 * e_source_backend_dup_backend_name:
 * @extension: an #ESourceBackend
 *
 * Thread-safe variation of e_source_backend_get_backend_name().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceBackend:backend-name
 *
 * Since: 3.6
 **/
gchar *
e_source_backend_dup_backend_name (ESourceBackend *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_BACKEND (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_backend_get_backend_name (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_backend_set_backend_name:
 * @extension: an #ESourceBackend
 * @backend_name: (allow-none): a backend name, or %NULL
 *
 * Sets the backend name for @extension.
 *
 * The internal copy of @backend_name is automatically stripped of leading
 * and trailing whitespace.  If the resulting string is empty, %NULL is set
 * instead.
 *
 * Since: 3.6
 **/
void
e_source_backend_set_backend_name (ESourceBackend *extension,
                                   const gchar *backend_name)
{
	g_return_if_fail (E_IS_SOURCE_BACKEND (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->backend_name, backend_name) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->backend_name);
	extension->priv->backend_name = e_util_strdup_strip (backend_name);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	g_object_notify (G_OBJECT (extension), "backend-name");
}

