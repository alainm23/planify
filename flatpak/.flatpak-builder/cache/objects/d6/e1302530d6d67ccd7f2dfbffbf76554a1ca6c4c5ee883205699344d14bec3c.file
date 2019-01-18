/*
 * camel-pop3-settings.c
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

#include "camel-pop3-settings.h"

#define CAMEL_POP3_SETTINGS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_POP3_SETTINGS, CamelPOP3SettingsPrivate))

struct _CamelPOP3SettingsPrivate {
	gint delete_after_days;
	gboolean delete_expunged;
	gboolean disable_extensions;
	gboolean keep_on_server;
	gboolean auto_fetch;
	guint32 last_cache_expunge;
};

enum {
	PROP_0,
	PROP_AUTH_MECHANISM,
	PROP_DELETE_AFTER_DAYS,
	PROP_DELETE_EXPUNGED,
	PROP_DISABLE_EXTENSIONS,
	PROP_HOST,
	PROP_KEEP_ON_SERVER,
	PROP_PORT,
	PROP_SECURITY_METHOD,
	PROP_USER,
	PROP_AUTO_FETCH,
	PROP_LAST_CACHE_EXPUNGE
};

G_DEFINE_TYPE_WITH_CODE (
	CamelPOP3Settings,
	camel_pop3_settings,
	CAMEL_TYPE_STORE_SETTINGS,
	G_IMPLEMENT_INTERFACE (
		CAMEL_TYPE_NETWORK_SETTINGS, NULL))

static void
pop3_settings_set_property (GObject *object,
                            guint property_id,
                            const GValue *value,
                            GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_AUTH_MECHANISM:
			camel_network_settings_set_auth_mechanism (
				CAMEL_NETWORK_SETTINGS (object),
				g_value_get_string (value));
			return;

		case PROP_DELETE_AFTER_DAYS:
			camel_pop3_settings_set_delete_after_days (
				CAMEL_POP3_SETTINGS (object),
				g_value_get_int (value));
			return;

		case PROP_DELETE_EXPUNGED:
			camel_pop3_settings_set_delete_expunged (
				CAMEL_POP3_SETTINGS (object),
				g_value_get_boolean (value));
			return;

		case PROP_DISABLE_EXTENSIONS:
			camel_pop3_settings_set_disable_extensions (
				CAMEL_POP3_SETTINGS (object),
				g_value_get_boolean (value));
			return;

		case PROP_HOST:
			camel_network_settings_set_host (
				CAMEL_NETWORK_SETTINGS (object),
				g_value_get_string (value));
			return;

		case PROP_KEEP_ON_SERVER:
			camel_pop3_settings_set_keep_on_server (
				CAMEL_POP3_SETTINGS (object),
				g_value_get_boolean (value));
			return;

		case PROP_LAST_CACHE_EXPUNGE:
			camel_pop3_settings_set_last_cache_expunge (
				CAMEL_POP3_SETTINGS (object),
				g_value_get_uint (value));
			return;

		case PROP_PORT:
			camel_network_settings_set_port (
				CAMEL_NETWORK_SETTINGS (object),
				g_value_get_uint (value));
			return;

		case PROP_SECURITY_METHOD:
			camel_network_settings_set_security_method (
				CAMEL_NETWORK_SETTINGS (object),
				g_value_get_enum (value));
			return;

		case PROP_USER:
			camel_network_settings_set_user (
				CAMEL_NETWORK_SETTINGS (object),
				g_value_get_string (value));
			return;

		case PROP_AUTO_FETCH:
			camel_pop3_settings_set_auto_fetch  (
				CAMEL_POP3_SETTINGS (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
pop3_settings_get_property (GObject *object,
                            guint property_id,
                            GValue *value,
                            GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_AUTH_MECHANISM:
			g_value_take_string (
				value,
				camel_network_settings_dup_auth_mechanism (
				CAMEL_NETWORK_SETTINGS (object)));
			return;

		case PROP_DELETE_AFTER_DAYS:
			g_value_set_int (
				value,
				camel_pop3_settings_get_delete_after_days (
				CAMEL_POP3_SETTINGS (object)));
			return;

		case PROP_DELETE_EXPUNGED:
			g_value_set_boolean (
				value,
				camel_pop3_settings_get_delete_expunged (
				CAMEL_POP3_SETTINGS (object)));
			return;

		case PROP_DISABLE_EXTENSIONS:
			g_value_set_boolean (
				value,
				camel_pop3_settings_get_disable_extensions (
				CAMEL_POP3_SETTINGS (object)));
			return;

		case PROP_HOST:
			g_value_take_string (
				value,
				camel_network_settings_dup_host (
				CAMEL_NETWORK_SETTINGS (object)));
			return;

		case PROP_KEEP_ON_SERVER:
			g_value_set_boolean (
				value,
				camel_pop3_settings_get_keep_on_server (
				CAMEL_POP3_SETTINGS (object)));
			return;

		case PROP_LAST_CACHE_EXPUNGE:
			g_value_set_uint (
				value,
				camel_pop3_settings_get_last_cache_expunge (
				CAMEL_POP3_SETTINGS (object)));
			return;

		case PROP_PORT:
			g_value_set_uint (
				value,
				camel_network_settings_get_port (
				CAMEL_NETWORK_SETTINGS (object)));
			return;

		case PROP_SECURITY_METHOD:
			g_value_set_enum (
				value,
				camel_network_settings_get_security_method (
				CAMEL_NETWORK_SETTINGS (object)));
			return;

		case PROP_USER:
			g_value_take_string (
				value,
				camel_network_settings_dup_user (
				CAMEL_NETWORK_SETTINGS (object)));
			return;

		case PROP_AUTO_FETCH:
			g_value_set_boolean (
				value,
				camel_pop3_settings_get_auto_fetch (
				CAMEL_POP3_SETTINGS (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
camel_pop3_settings_class_init (CamelPOP3SettingsClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelPOP3SettingsPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = pop3_settings_set_property;
	object_class->get_property = pop3_settings_get_property;

	/* Inherited from CamelNetworkSettings. */
	g_object_class_override_property (
		object_class,
		PROP_AUTH_MECHANISM,
		"auth-mechanism");

	/* Default to 0 days (i.e. do not delete) so we don't delete
	 * mail on the POP server when the user's not expecting it. */
	g_object_class_install_property (
		object_class,
		PROP_DELETE_AFTER_DAYS,
		g_param_spec_int (
			"delete-after-days",
			"Delete After Days",
			"Delete messages left on server after N days",
			0,
			365,
			0,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_DELETE_EXPUNGED,
		g_param_spec_boolean (
			"delete-expunged",
			"Delete Expunged",
			"Delete expunged from local Inbox",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_DISABLE_EXTENSIONS,
		g_param_spec_boolean (
			"disable-extensions",
			"Disable Extensions",
			"Disable support for all POP3 extensions",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/* Inherited from CamelNetworkSettings. */
	g_object_class_override_property (
		object_class,
		PROP_HOST,
		"host");

	g_object_class_install_property (
		object_class,
		PROP_KEEP_ON_SERVER,
		g_param_spec_boolean (
			"keep-on-server",
			"Keep On Server",
			"Leave messages on POP3 server",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_LAST_CACHE_EXPUNGE,
		g_param_spec_uint (
			"last-cache-expunge",
			"Last Cache Expunge",
			"Date as Julian value, when the cache had been checked for orphaned files the last time",
			0,
			G_MAXUINT32,
			0,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_AUTO_FETCH,
		g_param_spec_boolean (
			"auto-fetch",
			"Auto Fetch mails",
			"Automatically fetch additional mails that may be downloaded later.",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/* Inherited from CamelNetworkSettings. */
	g_object_class_override_property (
		object_class,
		PROP_PORT,
		"port");

	/* Inherited from CamelNetworkSettings. */
	g_object_class_override_property (
		object_class,
		PROP_SECURITY_METHOD,
		"security-method");

	/* Inherited from CamelNetworkSettings. */
	g_object_class_override_property (
		object_class,
		PROP_USER,
		"user");
}

static void
camel_pop3_settings_init (CamelPOP3Settings *settings)
{
	settings->priv = CAMEL_POP3_SETTINGS_GET_PRIVATE (settings);
}

/**
 * camel_pop3_settings_get_delete_after_days:
 * @settings: a #CamelPOP3Settings
 *
 * Returns the number of days to leave messages on the POP3 server before
 * automatically deleting them.  If the value is zero, messages will not
 * be automatically deleted.  The @settings's #CamelPOP3Settings:keep-on-server
 * property must be %TRUE for this to have any effect.
 *
 * Returns: the number of days to leave messages on the server before
 *          automatically deleting them
 *
 * Since: 3.2
 **/
gint
camel_pop3_settings_get_delete_after_days (CamelPOP3Settings *settings)
{
	g_return_val_if_fail (CAMEL_IS_POP3_SETTINGS (settings), 0);

	return settings->priv->delete_after_days;
}

/**
 * camel_pop3_settings_set_delete_after_days:
 * @settings: a #CamelPOP3Settings
 * @delete_after_days: the number of days to leave messages on the server
 *                     before automatically deleting them
 *
 * Sets the number of days to leave messages on the POP3 server before
 * automatically deleting them.  If the value is zero, messages will not
 * be automatically deleted.  The @settings's #CamelPOP3Settings:keep-on-server
 * property must be %TRUE for this to have any effect.
 *
 * Since: 3.2
 **/
void
camel_pop3_settings_set_delete_after_days (CamelPOP3Settings *settings,
                                           gint delete_after_days)
{
	g_return_if_fail (CAMEL_IS_POP3_SETTINGS (settings));

	if (settings->priv->delete_after_days == delete_after_days)
		return;

	settings->priv->delete_after_days = delete_after_days;

	g_object_notify (G_OBJECT (settings), "delete-after-days");
}

/**
 * camel_pop3_settings_get_delete_expunged:
 * @settings: a #CamelPOP3Settings
 *
 * Returns whether to delete corresponding messages left on the POP3 server
 * when expunging the local #CamelSettings.  The @settings's
 * #CamelPOP3Settings:keep-on-server property must be %TRUE for this to have
 * any effect.
 *
 * Returns: whether to delete corresponding messages on the server when
 *          expunging the local #CamelSettings
 *
 * Since: 3.2
 **/
gboolean
camel_pop3_settings_get_delete_expunged (CamelPOP3Settings *settings)
{
	g_return_val_if_fail (CAMEL_IS_POP3_SETTINGS (settings), FALSE);

	return settings->priv->delete_expunged;
}

/**
 * camel_pop3_settings_set_delete_expunged:
 * @settings: a #CamelPOP3Settings
 * @delete_expunged: whether to delete corresponding messages on the
 *                   server when expunging the local #CamelSettings
 *
 * Sets whether to delete corresponding messages left on the POP3 server
 * when expunging the local #CamelSettings.  The @settings's
 * #CamelPOP3Settings:keep-on-server property must be %TRUE for this to have
 * any effect.
 *
 * Since: 3.2
 **/
void
camel_pop3_settings_set_delete_expunged (CamelPOP3Settings *settings,
                                         gboolean delete_expunged)
{
	g_return_if_fail (CAMEL_IS_POP3_SETTINGS (settings));

	if (settings->priv->delete_expunged == delete_expunged)
		return;

	settings->priv->delete_expunged = delete_expunged;

	g_object_notify (G_OBJECT (settings), "delete-expunged");
}

/**
 * camel_pop3_settings_get_disable_extensions:
 * @settings: a #CamelPOP3Settings
 *
 * Returns whether to disable support for POP3 extensions.  If %TRUE, the
 * #CamelPOP3Engine will refrain from issuing a "CAPA" command to the server
 * upon connection.
 *
 * Returns: whether to disable support for POP3 extensions
 *
 * Since: 3.2
 **/
gboolean
camel_pop3_settings_get_disable_extensions (CamelPOP3Settings *settings)
{
	g_return_val_if_fail (CAMEL_IS_POP3_SETTINGS (settings), FALSE);

	return settings->priv->disable_extensions;
}

/**
 * camel_pop3_settings_set_disable_extensions:
 * @settings: a #CamelPOP3Settings
 * @disable_extensions: whether to disable support for POP3 extensions
 *
 * Sets whether to disable support for POP3 extensions.  If %TRUE, the
 * #CamelPOP3Engine will refrain from issuing a "CAPA" command to the server
 * upon connection.
 *
 * Since: 3.2
 **/
void
camel_pop3_settings_set_disable_extensions (CamelPOP3Settings *settings,
                                            gboolean disable_extensions)
{
	g_return_if_fail (CAMEL_IS_POP3_SETTINGS (settings));

	if (settings->priv->disable_extensions == disable_extensions)
		return;

	settings->priv->disable_extensions = disable_extensions;

	g_object_notify (G_OBJECT (settings), "disable-extensions");
}

/**
 * camel_pop3_settings_get_keep_on_server:
 * @settings: a #CamelPOP3Settings
 *
 * Returns whether to leave messages on the remote POP3 server after
 * downloading them to the local Inbox.
 *
 * Returns: whether to leave messages on the POP3 server
 *
 * Since: 3.2
 **/
gboolean
camel_pop3_settings_get_keep_on_server (CamelPOP3Settings *settings)
{
	g_return_val_if_fail (CAMEL_IS_POP3_SETTINGS (settings), FALSE);

	return settings->priv->keep_on_server;
}

/**
 * camel_pop3_settings_set_keep_on_server:
 * @settings: a #CamelPOP3Settings
 * @keep_on_server: whether to leave messages on the POP3 server
 *
 * Sets whether to leave messages on the remote POP3 server after
 * downloading them to the local Inbox.
 *
 * Since: 3.2
 **/
void
camel_pop3_settings_set_keep_on_server (CamelPOP3Settings *settings,
                                        gboolean keep_on_server)
{
	g_return_if_fail (CAMEL_IS_POP3_SETTINGS (settings));

	if (settings->priv->keep_on_server == keep_on_server)
		return;

	settings->priv->keep_on_server = keep_on_server;

	g_object_notify (G_OBJECT (settings), "keep-on-server");
}

/**
 * camel_pop3_settings_get_auto_fetch :
 * @settings: a #CamelPOP3Settings
 *
 * Returns whether to download additional mails that may be downloaded later on
 *
 * Returns: whether to download additional mails
 *
 * Since: 3.4
 **/
gboolean
camel_pop3_settings_get_auto_fetch (CamelPOP3Settings *settings)
{
	g_return_val_if_fail (CAMEL_IS_POP3_SETTINGS (settings), FALSE);

	return settings->priv->auto_fetch;
}

/**
 * camel_pop3_settings_set_auto_fetch :
 * @settings: a #CamelPOP3Settings
 * @auto_fetch: whether to download additional mails
 *
 * Sets whether to download additional mails that may be downloaded later on
 *
 * Since: 3.4
 **/
void
camel_pop3_settings_set_auto_fetch (CamelPOP3Settings *settings,
                                        gboolean auto_fetch)
{
	g_return_if_fail (CAMEL_IS_POP3_SETTINGS (settings));

	if (settings->priv->auto_fetch == auto_fetch)
		return;

	settings->priv->auto_fetch = auto_fetch;

	g_object_notify (G_OBJECT (settings), "auto-fetch");
}

guint32
camel_pop3_settings_get_last_cache_expunge (CamelPOP3Settings *settings)
{
	g_return_val_if_fail (CAMEL_IS_POP3_SETTINGS (settings), 0);

	return settings->priv->last_cache_expunge;
}

void
camel_pop3_settings_set_last_cache_expunge (CamelPOP3Settings *settings,
					    guint32 last_cache_expunge)
{
	g_return_if_fail (CAMEL_IS_POP3_SETTINGS (settings));

	if (settings->priv->last_cache_expunge == last_cache_expunge)
		return;

	settings->priv->last_cache_expunge = last_cache_expunge;

	g_object_notify (G_OBJECT (settings), "last-cache-expunge");
}
