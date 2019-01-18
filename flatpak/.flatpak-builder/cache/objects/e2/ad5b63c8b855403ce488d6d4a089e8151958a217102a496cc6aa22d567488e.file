/*
 * e-source-security.c
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
 * SECTION: e-source-security
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for security settings
 *
 * The #ESourceSecurity extension tracks settings for establishing a
 * secure connection with a remote server.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceSecurity *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_SECURITY);
 * ]|
 **/

#include "e-source-security.h"

#include <libedataserver/e-data-server-util.h>

#define E_SOURCE_SECURITY_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_SECURITY, ESourceSecurityPrivate))

#define SECURE_METHOD "tls"

struct _ESourceSecurityPrivate {
	gchar *method;
};

enum {
	PROP_0,
	PROP_METHOD,
	PROP_SECURE
};

G_DEFINE_TYPE (
	ESourceSecurity,
	e_source_security,
	E_TYPE_SOURCE_EXTENSION)

static void
source_security_set_property (GObject *object,
                              guint property_id,
                              const GValue *value,
                              GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_METHOD:
			e_source_security_set_method (
				E_SOURCE_SECURITY (object),
				g_value_get_string (value));
			return;

		case PROP_SECURE:
			e_source_security_set_secure (
				E_SOURCE_SECURITY (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_security_get_property (GObject *object,
                              guint property_id,
                              GValue *value,
                              GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_METHOD:
			g_value_take_string (
				value,
				e_source_security_dup_method (
				E_SOURCE_SECURITY (object)));
			return;

		case PROP_SECURE:
			g_value_set_boolean (
				value,
				e_source_security_get_secure (
				E_SOURCE_SECURITY (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_security_finalize (GObject *object)
{
	ESourceSecurityPrivate *priv;

	priv = E_SOURCE_SECURITY_GET_PRIVATE (object);

	g_free (priv->method);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_security_parent_class)->finalize (object);
}

static void
e_source_security_class_init (ESourceSecurityClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceSecurityPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_security_set_property;
	object_class->get_property = source_security_get_property;
	object_class->finalize = source_security_finalize;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_SECURITY;

	g_object_class_install_property (
		object_class,
		PROP_METHOD,
		g_param_spec_string (
			"method",
			"Method",
			"Security method",
			"none",
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_SECURE,
		g_param_spec_boolean (
			"secure",
			"Secure",
			"Secure the network connection",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
e_source_security_init (ESourceSecurity *extension)
{
	extension->priv = E_SOURCE_SECURITY_GET_PRIVATE (extension);
}

/**
 * e_source_security_get_method:
 * @extension: an #ESourceSecurity
 *
 * Returns the method used to establish a secure network connection to a
 * remote account.  There are no pre-defined method names; backends are
 * free to set this however they wish.  If a secure connection is not
 * desired, the convention is to set #ESourceSecurity:method to "none".
 *
 * Returns: the method used to establish a secure network connection
 *
 * Since: 3.6
 **/
const gchar *
e_source_security_get_method (ESourceSecurity *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_SECURITY (extension), NULL);

	return extension->priv->method;
}

/**
 * e_source_security_dup_method:
 * @extension: an #ESourceSecurity
 *
 * Thread-safe variation of e_source_security_get_method().
 * Use this function when accessing @extension from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ESourceSecurity:method
 *
 * Since: 3.6
 **/
gchar *
e_source_security_dup_method (ESourceSecurity *extension)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_SOURCE_SECURITY (extension), NULL);

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	protected = e_source_security_get_method (extension);
	duplicate = g_strdup (protected);

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	return duplicate;
}

/**
 * e_source_security_set_method:
 * @extension: an #ESourceSecurity
 * @method: (allow-none): security method, or %NULL
 *
 * Sets the method used to establish a secure network connection to a
 * remote account.  There are no pre-defined method names; backends are
 * free to set this however they wish.  If a secure connection is not
 * desired, the convention is to set #ESourceSecurity:method to "none".
 * In keeping with that convention, #ESourceSecurity:method will be set
 * to "none" if @method is %NULL or an empty string.
 *
 * Since: 3.6
 **/
void
e_source_security_set_method (ESourceSecurity *extension,
                              const gchar *method)
{
	GObject *object;

	g_return_if_fail (E_IS_SOURCE_SECURITY (extension));

	e_source_extension_property_lock (E_SOURCE_EXTENSION (extension));

	if (e_util_strcmp0 (extension->priv->method, method) == 0) {
		e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));
		return;
	}

	g_free (extension->priv->method);
	extension->priv->method = e_util_strdup_strip (method);

	if (extension->priv->method == NULL)
		extension->priv->method = g_strdup ("none");

	e_source_extension_property_unlock (E_SOURCE_EXTENSION (extension));

	object = G_OBJECT (extension);
	g_object_freeze_notify (object);
	g_object_notify (object, "method");
	g_object_notify (object, "secure");
	g_object_thaw_notify (object);
}

/**
 * e_source_security_get_secure:
 * @extension: an #ESourceSecurity
 *
 * This is a convenience function which returns whether a secure network
 * connection is desired, regardless of the method used.  This relies on
 * the convention of setting #ESourceSecurity:method to "none" when a
 * secure network connection is <emphasis>not</emphasis> desired.
 *
 * Returns: whether a secure network connection is desired
 *
 * Since: 3.6
 **/
gboolean
e_source_security_get_secure (ESourceSecurity *extension)
{
	const gchar *method;

	g_return_val_if_fail (E_IS_SOURCE_SECURITY (extension), FALSE);

	method = e_source_security_get_method (extension);
	g_return_val_if_fail (method != NULL, FALSE);

	return (g_strcmp0 (method, "none") != 0);
}

/**
 * e_source_security_set_secure:
 * @extension: an #ESourceSecurity
 * @secure: whether a secure network connection is desired
 *
 * This function provides a simpler way to set #ESourceSecurity:method
 * when using a secure network connection is a yes or no option and the
 * exact method name is unimportant.  If @secure is %FALSE, the
 * #ESourceSecurity:method property is set to "none".  If @secure is
 * %TRUE, the function assumes the backend will use Transport Layer
 * Security and sets the #ESourceSecurity:method property to "tls".
 *
 * Since: 3.6
 **/
void
e_source_security_set_secure (ESourceSecurity *extension,
                              gboolean secure)
{
	const gchar *method;

	g_return_if_fail (E_IS_SOURCE_SECURITY (extension));

	method = secure ? SECURE_METHOD : "none";
	e_source_security_set_method (extension, method);
}
