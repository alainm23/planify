/*
 * camel-sendmail-settings.c
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

#include "camel-sendmail-settings.h"

#define CAMEL_SENDMAIL_SETTINGS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SENDMAIL_SETTINGS, CamelSendmailSettingsPrivate))

struct _CamelSendmailSettingsPrivate {
	GMutex property_lock;
	gchar *custom_binary;
	gchar *custom_args;

	gboolean use_custom_binary;
	gboolean use_custom_args;
	gboolean send_in_offline;
};

enum {
	PROP_0,
	PROP_USE_CUSTOM_BINARY,
	PROP_USE_CUSTOM_ARGS,
	PROP_CUSTOM_BINARY,
	PROP_CUSTOM_ARGS,
	PROP_SEND_IN_OFFLINE
};

G_DEFINE_TYPE (CamelSendmailSettings, camel_sendmail_settings, CAMEL_TYPE_SETTINGS)

static void
sendmail_settings_set_property (GObject *object,
                                guint property_id,
                                const GValue *value,
                                GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_USE_CUSTOM_BINARY:
			camel_sendmail_settings_set_use_custom_binary (
				CAMEL_SENDMAIL_SETTINGS (object),
				g_value_get_boolean (value));
			return;

		case PROP_USE_CUSTOM_ARGS:
			camel_sendmail_settings_set_use_custom_args (
				CAMEL_SENDMAIL_SETTINGS (object),
				g_value_get_boolean (value));
			return;

		case PROP_CUSTOM_BINARY:
			camel_sendmail_settings_set_custom_binary (
				CAMEL_SENDMAIL_SETTINGS (object),
				g_value_get_string (value));
			return;

		case PROP_CUSTOM_ARGS:
			camel_sendmail_settings_set_custom_args (
				CAMEL_SENDMAIL_SETTINGS (object),
				g_value_get_string (value));
			return;

		case PROP_SEND_IN_OFFLINE:
			camel_sendmail_settings_set_send_in_offline (
				CAMEL_SENDMAIL_SETTINGS (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
sendmail_settings_get_property (GObject *object,
                                guint property_id,
                                GValue *value,
                                GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_USE_CUSTOM_BINARY:
			g_value_set_boolean (
				value,
				camel_sendmail_settings_get_use_custom_binary (
				CAMEL_SENDMAIL_SETTINGS (object)));
			return;

		case PROP_USE_CUSTOM_ARGS:
			g_value_set_boolean (
				value,
				camel_sendmail_settings_get_use_custom_args (
				CAMEL_SENDMAIL_SETTINGS (object)));
			return;

		case PROP_CUSTOM_BINARY:
			g_value_take_string (
				value,
				camel_sendmail_settings_dup_custom_binary (
				CAMEL_SENDMAIL_SETTINGS (object)));
			return;

		case PROP_CUSTOM_ARGS:
			g_value_take_string (
				value,
				camel_sendmail_settings_dup_custom_args (
				CAMEL_SENDMAIL_SETTINGS (object)));
			return;

		case PROP_SEND_IN_OFFLINE:
			g_value_set_boolean (
				value,
				camel_sendmail_settings_get_send_in_offline (
				CAMEL_SENDMAIL_SETTINGS (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
sendmail_settings_finalize (GObject *object)
{
	CamelSendmailSettingsPrivate *priv;

	priv = CAMEL_SENDMAIL_SETTINGS_GET_PRIVATE (object);

	g_mutex_clear (&priv->property_lock);

	g_free (priv->custom_binary);
	g_free (priv->custom_args);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_sendmail_settings_parent_class)->finalize (object);
}

static void
camel_sendmail_settings_class_init (CamelSendmailSettingsClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelSendmailSettingsPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = sendmail_settings_set_property;
	object_class->get_property = sendmail_settings_get_property;
	object_class->finalize = sendmail_settings_finalize;

	g_object_class_install_property (
		object_class,
		PROP_USE_CUSTOM_BINARY,
		g_param_spec_boolean (
			"use-custom-binary",
			"Use Custom Binary",
			"Whether the custom-binary property identifies binary to run",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_USE_CUSTOM_ARGS,
		g_param_spec_boolean (
			"use-custom-args",
			"Use Custom Arguments",
			"Whether the custom-args property identifies arguments to use",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_CUSTOM_BINARY,
		g_param_spec_string (
			"custom-binary",
			"Custom Binary",
			"Custom binary to run, instead of sendmail",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_CUSTOM_ARGS,
		g_param_spec_string (
			"custom-args",
			"Custom Arguments",
			"Custom arguments to use, instead of default (predefined) arguments",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_SEND_IN_OFFLINE,
		g_param_spec_boolean (
			"send-in-offline",
			"Send in offline",
			"Whether to allow message sending in offline mode",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_sendmail_settings_init (CamelSendmailSettings *settings)
{
	settings->priv = CAMEL_SENDMAIL_SETTINGS_GET_PRIVATE (settings);
	g_mutex_init (&settings->priv->property_lock);
}

/**
 * camel_sendmail_settings_get_use_custom_binary:
 * @settings: a #CamelSendmailSettings
 *
 * Returns whether the 'custom-binary' property should be used as binary to run, instead of sendmail.
 *
 * Returns: whether the 'custom-binary' property should be used as binary to run, instead of sendmail
 *
 * Since: 3.8
 **/
gboolean
camel_sendmail_settings_get_use_custom_binary (CamelSendmailSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings), FALSE);

	return settings->priv->use_custom_binary;
}

/**
 * camel_sendmail_settings_set_use_custom_binary:
 * @settings: a #CamelSendmailSettings
 * @use_custom_binary: whether to use custom binary
 *
 * Sets whether to use custom binary, instead of sendmail.
 *
 * Since: 3.8
 **/
void
camel_sendmail_settings_set_use_custom_binary (CamelSendmailSettings *settings,
                                               gboolean use_custom_binary)
{
	g_return_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings));

	if (settings->priv->use_custom_binary == use_custom_binary)
		return;

	settings->priv->use_custom_binary = use_custom_binary;

	g_object_notify (G_OBJECT (settings), "use-custom-binary");
}

/**
 * camel_sendmail_settings_get_use_custom_args:
 * @settings: a #CamelSendmailSettings
 *
 * Returns whether the 'custom-args' property should be used as arguments to use, instead of default arguments.
 *
 * Returns: whether the 'custom-args' property should be used as arguments to use, instead of default arguments
 *
 * Since: 3.8
 **/
gboolean
camel_sendmail_settings_get_use_custom_args (CamelSendmailSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings), FALSE);

	return settings->priv->use_custom_args;
}

/**
 * camel_sendmail_settings_set_use_custom_args:
 * @settings: a #CamelSendmailSettings
 * @use_custom_args: whether to use custom arguments
 *
 * Sets whether to use custom arguments, instead of default arguments.
 *
 * Since: 3.8
 **/
void
camel_sendmail_settings_set_use_custom_args (CamelSendmailSettings *settings,
                                             gboolean use_custom_args)
{
	g_return_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings));

	if (settings->priv->use_custom_args == use_custom_args)
		return;

	settings->priv->use_custom_args = use_custom_args;

	g_object_notify (G_OBJECT (settings), "use-custom-args");
}

/**
 * camel_sendmail_settings_get_custom_binary:
 * @settings: a #CamelSendmailSettings
 *
 * Returns the custom binary to run, instead of sendmail.
 *
 * Returns: the custom binary to run, instead of sendmail, or %NULL
 *
 * Since: 3.8
 **/
const gchar *
camel_sendmail_settings_get_custom_binary (CamelSendmailSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings), NULL);

	return settings->priv->custom_binary;
}

/**
 * camel_sendmail_settings_dup_custom_binary:
 * @settings: a #CamelSendmailSettings
 *
 * Thread-safe variation of camel_sendmail_settings_get_custom_binary().
 * Use this function when accessing @settings from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #CamelSendmailSettings:custom-binary
 *
 * Since: 3.8
 **/
gchar *
camel_sendmail_settings_dup_custom_binary (CamelSendmailSettings *settings)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings), NULL);

	g_mutex_lock (&settings->priv->property_lock);

	protected = camel_sendmail_settings_get_custom_binary (settings);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&settings->priv->property_lock);

	return duplicate;
}

/**
 * camel_sendmail_settings_set_custom_binary:
 * @settings: a #CamelSendmailSettings
 * @custom_binary: a custom binary name, or %NULL
 *
 * Sets the custom binary name to run, instead of sendmail.
 *
 * Since: 3.8
 **/
void
camel_sendmail_settings_set_custom_binary (CamelSendmailSettings *settings,
                                           const gchar *custom_binary)
{
	g_return_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings));

	/* The default namespace is an empty string. */
	if (custom_binary && !*custom_binary)
		custom_binary = NULL;

	g_mutex_lock (&settings->priv->property_lock);

	if (g_strcmp0 (settings->priv->custom_binary, custom_binary) == 0) {
		g_mutex_unlock (&settings->priv->property_lock);
		return;
	}

	g_free (settings->priv->custom_binary);
	settings->priv->custom_binary = g_strdup (custom_binary);

	g_mutex_unlock (&settings->priv->property_lock);

	g_object_notify (G_OBJECT (settings), "custom-binary");
}

/**
 * camel_sendmail_settings_get_custom_args:
 * @settings: a #CamelSendmailSettings
 *
 * Returns the custom arguments to use, instead of default arguments.
 *
 * Returns: the custom arguments to use, instead of default arguments, or %NULL
 *
 * Since: 3.8
 **/
const gchar *
camel_sendmail_settings_get_custom_args (CamelSendmailSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings), NULL);

	return settings->priv->custom_args;
}

/**
 * camel_sendmail_settings_dup_custom_args:
 * @settings: a #CamelSendmailSettings
 *
 * Thread-safe variation of camel_sendmail_settings_get_custom_args().
 * Use this function when accessing @settings from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #CamelSendmailSettings:custom-args
 *
 * Since: 3.8
 **/
gchar *
camel_sendmail_settings_dup_custom_args (CamelSendmailSettings *settings)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings), NULL);

	g_mutex_lock (&settings->priv->property_lock);

	protected = camel_sendmail_settings_get_custom_args (settings);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&settings->priv->property_lock);

	return duplicate;
}

/**
 * camel_sendmail_settings_set_custom_args:
 * @settings: a #CamelSendmailSettings
 * @custom_args: a custom arguments, or %NULL
 *
 * Sets the custom arguments to use, instead of default arguments.
 *
 * Since: 3.8
 **/
void
camel_sendmail_settings_set_custom_args (CamelSendmailSettings *settings,
                                        const gchar *custom_args)
{
	g_return_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings));

	/* The default namespace is an empty string. */
	if (custom_args && !*custom_args)
		custom_args = NULL;

	g_mutex_lock (&settings->priv->property_lock);

	if (g_strcmp0 (settings->priv->custom_args, custom_args) == 0) {
		g_mutex_unlock (&settings->priv->property_lock);
		return;
	}

	g_free (settings->priv->custom_args);
	settings->priv->custom_args = g_strdup (custom_args);

	g_mutex_unlock (&settings->priv->property_lock);

	g_object_notify (G_OBJECT (settings), "custom-args");
}

/**
 * camel_sendmail_settings_get_send_in_offline:
 * @settings: a #CamelSendmailSettings
 *
 * Returns whether can send messages in offline mode.
 *
 * Returns: whether can send messages in offline mode
 *
 * Since: 3.10
 **/
gboolean
camel_sendmail_settings_get_send_in_offline (CamelSendmailSettings *settings)
{
	g_return_val_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings), FALSE);

	return settings->priv->send_in_offline;
}

/**
 * camel_sendmail_settings_set_send_in_offline:
 * @settings: a #CamelSendmailSettings
 * @send_in_offline: whether can send messages in offline mode
 *
 * Sets whether can send messages in offline mode.
 *
 * Since: 3.10
 **/
void
camel_sendmail_settings_set_send_in_offline (CamelSendmailSettings *settings,
                                             gboolean send_in_offline)
{
	g_return_if_fail (CAMEL_IS_SENDMAIL_SETTINGS (settings));

	if ((settings->priv->send_in_offline ? 1 : 0) == (send_in_offline ? 1 : 0))
		return;

	settings->priv->send_in_offline = send_in_offline;

	g_object_notify (G_OBJECT (settings), "send-in-offline");
}
