/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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
 */

/**
 * SECTION: e-source-locale-watcher
 * @include: libedata-book/libedata-book.h
 * @short_description: Watch changes of system locale
 *
 * #ESystemLocaleWatcher watches for changes of system locale.
 **/

#include "evolution-data-server-config.h"

#include <locale.h>
#include <string.h>

#include "e-dbus-localed.h"

#include "e-system-locale-watcher.h"

struct _ESystemLocaleWatcherPrivate {
	GMutex lock;

	/* Watching "org.freedesktop.locale1" for locale changes when not using backend-per-process */
	guint localed_watch_id;
	EDBusLocale1 *localed_proxy;
	GCancellable *localed_cancel;
	gchar *locale;
};

G_DEFINE_TYPE (ESystemLocaleWatcher, e_system_locale_watcher, G_TYPE_OBJECT)

enum {
	PROP_0,
	PROP_LOCALE
};

static gchar *
system_locale_watcher_interpret_locale_value (const gchar *value)
{
	gchar *interpreted_value = NULL;
	gchar **split;

	split = g_strsplit (value, "=", 2);

	if (split && split[0] && split[1])
		interpreted_value = g_strdup (split[1]);

	g_strfreev (split);

	if (!interpreted_value)
		g_warning ("Failed to interpret locale value: %s", value);

	return interpreted_value;
}

static gchar *
system_locale_watcher_interpret_locale (const gchar * const * locale)
{
	gint i;
	gchar *interpreted_locale = NULL;

	/* Prioritize LC_COLLATE and then LANG values
	 * in the 'locale' specified by localed.
	 *
	 * If localed explicitly specifies no locale, then
	 * default to checking system locale.
	 */
	if (locale) {
		for (i = 0; locale[i] != NULL && interpreted_locale == NULL; i++) {
			if (strncmp (locale[i], "LC_COLLATE", 10) == 0)
				interpreted_locale = system_locale_watcher_interpret_locale_value (locale[i]);
		}

		for (i = 0; locale[i] != NULL && interpreted_locale == NULL; i++) {
			if (strncmp (locale[i], "LANG", 4) == 0)
				interpreted_locale = system_locale_watcher_interpret_locale_value (locale[i]);
		}
	}

	if (!interpreted_locale) {
		const gchar *system_locale = setlocale (LC_COLLATE, NULL);

		interpreted_locale = g_strdup (system_locale);
	}

	return interpreted_locale;
}

static void
system_locale_watcher_set_locale (ESystemLocaleWatcher *watcher,
				  const gchar *locale)
{
	g_mutex_lock (&watcher->priv->lock);

	if (g_strcmp0 (watcher->priv->locale, locale) != 0) {

		g_free (watcher->priv->locale);
		watcher->priv->locale = g_strdup (locale);

		g_mutex_unlock (&watcher->priv->lock);

		g_object_notify (G_OBJECT (watcher), "locale");
	} else {
		g_mutex_unlock (&watcher->priv->lock);
	}
}

static void
system_locale_watcher_locale_changed (GObject *object,
				      GParamSpec *pspec,
				      gpointer user_data)
{
	EDBusLocale1 *locale_proxy = E_DBUS_LOCALE1 (object);
	ESystemLocaleWatcher *watcher = (ESystemLocaleWatcher *) user_data;
	const gchar * const *locale;
	gchar *interpreted_locale;

	locale = e_dbus_locale1_get_locale (locale_proxy);
	interpreted_locale = system_locale_watcher_interpret_locale (locale);

	system_locale_watcher_set_locale (watcher, interpreted_locale);

	g_free (interpreted_locale);
}

static void
system_locale_watcher_localed_ready (GObject *source_object,
				     GAsyncResult *res,
				     gpointer user_data)
{
	ESystemLocaleWatcher *watcher = (ESystemLocaleWatcher *) user_data;
	GError *error = NULL;

	watcher->priv->localed_proxy = e_dbus_locale1_proxy_new_finish (res, &error);

	if (!watcher->priv->localed_proxy) {
		g_warning ("Error fetching localed proxy: %s", error ? error->message : "Unknown error");
		g_clear_error (&error);
	}

	g_clear_object (&watcher->priv->localed_cancel);

	if (watcher->priv->localed_proxy) {
		g_signal_connect (
			watcher->priv->localed_proxy, "notify::locale",
			G_CALLBACK (system_locale_watcher_locale_changed), watcher);

		/* Initial refresh of the locale */
		system_locale_watcher_locale_changed (G_OBJECT (watcher->priv->localed_proxy), NULL, watcher);
	}
}

static void
system_locale_watcher_localed_appeared (GDBusConnection *connection,
					const gchar *name,
					const gchar *name_owner,
					gpointer user_data)
{
	ESystemLocaleWatcher *watcher = (ESystemLocaleWatcher *) user_data;

	watcher->priv->localed_cancel = g_cancellable_new ();

	e_dbus_locale1_proxy_new (
		connection,
		G_DBUS_PROXY_FLAGS_GET_INVALIDATED_PROPERTIES,
		"org.freedesktop.locale1",
		"/org/freedesktop/locale1",
		watcher->priv->localed_cancel,
		system_locale_watcher_localed_ready,
		watcher);
}

static void
system_locale_watcher_localed_vanished (GDBusConnection *connection,
					const gchar *name,
					gpointer user_data)
{
	ESystemLocaleWatcher *watcher = (ESystemLocaleWatcher *) user_data;

	if (watcher->priv->localed_cancel) {
		g_cancellable_cancel (watcher->priv->localed_cancel);
		g_clear_object (&watcher->priv->localed_cancel);
	}

	g_clear_object (&watcher->priv->localed_proxy);
}

static void
system_locale_watcher_get_property (GObject *object,
				    guint property_id,
				    GValue *value,
				    GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_LOCALE:
			g_value_take_string (
				value,
				e_system_locale_watcher_dup_locale (
				E_SYSTEM_LOCALE_WATCHER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
system_locale_watcher_constructed (GObject *object)
{
	ESystemLocaleWatcher *watcher = E_SYSTEM_LOCALE_WATCHER (object);
	GBusType bus_type = G_BUS_TYPE_SYSTEM;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_system_locale_watcher_parent_class)->constructed (object);

	/* When running tests, we pretend to be the "org.freedesktop.locale1" service
	 * on the session bus instead of the real location on the system bus.
	 */
	if (g_getenv ("EDS_TESTING") != NULL)
		bus_type = G_BUS_TYPE_SESSION;

	/* Watch system bus for locale change notifications */
	watcher->priv->localed_watch_id =
		g_bus_watch_name (
			bus_type,
			"org.freedesktop.locale1",
			G_BUS_NAME_WATCHER_FLAGS_NONE,
			system_locale_watcher_localed_appeared,
			system_locale_watcher_localed_vanished,
			watcher,
			NULL);
}

static void
system_locale_watcher_dispose (GObject *object)
{
	ESystemLocaleWatcher *watcher = E_SYSTEM_LOCALE_WATCHER (object);

	if (watcher->priv->localed_cancel)
		g_cancellable_cancel (watcher->priv->localed_cancel);

	g_clear_object (&watcher->priv->localed_cancel);
	g_clear_object (&watcher->priv->localed_proxy);

	if (watcher->priv->localed_watch_id > 0)
		g_bus_unwatch_name (watcher->priv->localed_watch_id);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_system_locale_watcher_parent_class)->dispose (object);
}

static void
system_locale_watcher_finalize (GObject *object)
{
	ESystemLocaleWatcher *watcher = E_SYSTEM_LOCALE_WATCHER (object);

	g_free (watcher->priv->locale);
	g_mutex_clear (&watcher->priv->lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_system_locale_watcher_parent_class)->finalize (object);
}

static void
e_system_locale_watcher_class_init (ESystemLocaleWatcherClass *klass)
{
	GObjectClass *object_class;

	g_type_class_add_private (klass, sizeof (ESystemLocaleWatcherPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->get_property = system_locale_watcher_get_property;
	object_class->constructed = system_locale_watcher_constructed;
	object_class->dispose = system_locale_watcher_dispose;
	object_class->finalize = system_locale_watcher_finalize;

	/**
	 * ESystemLocaleWatcher:locale:
	 *
	 * Current locale, as detected. It can be %NULL, when the locale
	 * was not detected yet.
	 *
	 * Since: 3.30
	 **/
	g_object_class_install_property (
		object_class,
		PROP_LOCALE,
		g_param_spec_string (
			"locale",
			"Locale",
			NULL,
			NULL,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));
}

static void
e_system_locale_watcher_init (ESystemLocaleWatcher *watcher)
{
	watcher->priv = G_TYPE_INSTANCE_GET_PRIVATE (watcher, E_TYPE_SYSTEM_LOCALE_WATCHER, ESystemLocaleWatcherPrivate);

	g_mutex_init (&watcher->priv->lock);

	watcher->priv->locale = NULL;
}

/**
 * e_system_locale_watcher_new:
 *
 * Creates a new #ESystemLocaleWatcher instance, which listens for D-Bus
 * notification on locale changes. It uses system bus, unless an environment
 * variable "EDS_TESTING" is defined, in which case it uses the session bus
 * instead.
 *
 * Returns: (transfer full): a new #ESystemLocaleWatcher
 *
 * Since: 3.30
 **/
ESystemLocaleWatcher *
e_system_locale_watcher_new (void)
{
	return g_object_new (E_TYPE_SYSTEM_LOCALE_WATCHER, NULL);
}

/**
 * e_system_locale_watcher_dup_locale:
 * @watcher: an #ESystemLocaleWatcher
 *
 * Returns the current locale, as detected by the @watcher. The string
 * is duplicated for thread safety. It can be %NULL, when the locale
 * was not detected yet.
 *
 * Free it with g_free(), when no longer needed.
 *
 * Returns: (transfer full) (nullable): the system locale, as detected by the @watcher
 *
 * Since: 3.30
 **/
gchar *
e_system_locale_watcher_dup_locale (ESystemLocaleWatcher *watcher)
{
	gchar *locale;

	g_return_val_if_fail (E_IS_SYSTEM_LOCALE_WATCHER (watcher), NULL);

	g_mutex_lock (&watcher->priv->lock);
	locale = g_strdup (watcher->priv->locale);
	g_mutex_unlock (&watcher->priv->lock);

	return locale;
}
