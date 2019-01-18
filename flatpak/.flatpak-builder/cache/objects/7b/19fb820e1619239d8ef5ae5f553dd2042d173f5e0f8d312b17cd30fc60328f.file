/*
 * e-source-refresh.c
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
 * SECTION: e-source-refresh
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for refresh settings
 *
 * The #ESourceRefresh extension tracks the interval for fetching
 * updates from a remote server.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceRefresh *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_REFRESH);
 * ]|
 **/

#include "e-source-refresh.h"

#define E_SOURCE_REFRESH_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_REFRESH, ESourceRefreshPrivate))

typedef struct _TimeoutNode TimeoutNode;

struct _ESourceRefreshPrivate {
	gboolean enabled;
	guint interval_minutes;

	GMutex timeout_lock;
	GHashTable *timeout_table;
	guint next_timeout_id;
};

struct _TimeoutNode {
	GSource *source;
	GMainContext *context;
	ESourceRefresh *extension;  /* not referenced */

	ESourceRefreshFunc callback;
	gpointer user_data;
	GDestroyNotify notify;
};

enum {
	PROP_0,
	PROP_ENABLED,
	PROP_INTERVAL_MINUTES
};

G_DEFINE_TYPE (
	ESourceRefresh,
	e_source_refresh,
	E_TYPE_SOURCE_EXTENSION)

static TimeoutNode *
timeout_node_new (ESourceRefresh *extension,
                  GMainContext *context,
                  ESourceRefreshFunc callback,
                  gpointer user_data,
                  GDestroyNotify notify)
{
	TimeoutNode *node;

	if (context != NULL)
		g_main_context_ref (context);

	node = g_slice_new0 (TimeoutNode);
	node->context = context;
	node->callback = callback;
	node->user_data = user_data;
	node->notify = notify;

	/* Do not reference.  The timeout node will
	 * not outlive the ESourceRefresh extension. */
	node->extension = extension;

	return node;
}

static gboolean
timeout_node_invoke (gpointer data)
{
	TimeoutNode *node = data;
	ESourceExtension *extension;
	ESource *source;

	extension = E_SOURCE_EXTENSION (node->extension);
	source = e_source_extension_ref_source (extension);
	g_return_val_if_fail (source != NULL, FALSE);

	/* We allow timeouts to be scheduled for disabled data sources
	 * but we don't invoke the callback.  Keeps the logic simple. */
	if (e_source_get_enabled (source))
		node->callback (source, node->user_data);

	g_object_unref (source);

	return TRUE;
}

static void
timeout_node_attach (TimeoutNode *node)
{
	guint interval_minutes;

	if (node->source != NULL)
		return;

	interval_minutes = e_source_refresh_get_interval_minutes (node->extension);
	if (interval_minutes > 0) {
		node->source = g_timeout_source_new_seconds (interval_minutes * 60);

		g_source_set_callback (
			node->source,
			timeout_node_invoke,
			node,
			(GDestroyNotify) NULL);

		g_source_attach (node->source, node->context);
	}
}

static void
timeout_node_detach (TimeoutNode *node)
{
	if (node->source == NULL)
		return;

	g_source_destroy (node->source);
	g_source_unref (node->source);
	node->source = NULL;
}

static void
timeout_node_free (TimeoutNode *node)
{
	if (node->source != NULL)
		timeout_node_detach (node);

	if (node->context != NULL)
		g_main_context_unref (node->context);

	if (node->notify != NULL)
		node->notify (node->user_data);

	g_slice_free (TimeoutNode, node);
}

static void
source_refresh_update_timeouts (ESourceRefresh *extension,
                                gboolean invoke_callbacks)
{
	GList *list, *link;

	g_mutex_lock (&extension->priv->timeout_lock);

	list = g_hash_table_get_values (extension->priv->timeout_table);

	for (link = list; link != NULL; link = g_list_next (link)) {
		TimeoutNode *node = link->data;

		timeout_node_detach (node);

		if (invoke_callbacks)
			timeout_node_invoke (node);

		if (e_source_refresh_get_enabled (extension))
			timeout_node_attach (node);
	}

	g_list_free (list);

	g_mutex_unlock (&extension->priv->timeout_lock);
}

static gboolean
source_refresh_idle_cb (gpointer user_data)
{
	ESource *source = E_SOURCE (user_data);

	if (e_source_get_enabled (source))
		e_source_refresh_force_timeout (source);

	return FALSE;
}

static void
source_refresh_notify_enabled_cb (ESource *source,
                                  GParamSpec *pspec,
                                  ESourceRefresh *extension)
{
	GSource *idle_source;
	GMainContext *main_context;

	main_context = e_source_ref_main_context (source);

	idle_source = g_idle_source_new ();
	g_source_set_callback (
		idle_source,
		source_refresh_idle_cb,
		g_object_ref (source),
		(GDestroyNotify) g_object_unref);
	g_source_attach (idle_source, main_context);
	g_source_unref (idle_source);

	g_main_context_unref (main_context);
}

static void
source_refresh_set_property (GObject *object,
                             guint property_id,
                             const GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ENABLED:
			e_source_refresh_set_enabled (
				E_SOURCE_REFRESH (object),
				g_value_get_boolean (value));
			return;

		case PROP_INTERVAL_MINUTES:
			e_source_refresh_set_interval_minutes (
				E_SOURCE_REFRESH (object),
				g_value_get_uint (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_refresh_get_property (GObject *object,
                             guint property_id,
                             GValue *value,
                             GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ENABLED:
			g_value_set_boolean (
				value,
				e_source_refresh_get_enabled (
				E_SOURCE_REFRESH (object)));
			return;

		case PROP_INTERVAL_MINUTES:
			g_value_set_uint (
				value,
				e_source_refresh_get_interval_minutes (
				E_SOURCE_REFRESH (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_refresh_dispose (GObject *object)
{
	ESourceRefreshPrivate *priv;

	priv = E_SOURCE_REFRESH_GET_PRIVATE (object);

	g_hash_table_remove_all (priv->timeout_table);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_source_refresh_parent_class)->dispose (object);
}

static void
source_refresh_finalize (GObject *object)
{
	ESourceRefreshPrivate *priv;

	priv = E_SOURCE_REFRESH_GET_PRIVATE (object);

	g_mutex_clear (&priv->timeout_lock);
	g_hash_table_destroy (priv->timeout_table);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_source_refresh_parent_class)->finalize (object);
}

static void
source_refresh_constructed (GObject *object)
{
	ESourceExtension *extension;
	ESource *source;

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_source_refresh_parent_class)->constructed (object);

	extension = E_SOURCE_EXTENSION (object);
	source = e_source_extension_ref_source (extension);

	/* There should be no lifecycle issues here
	 * since we get finalized with our ESource. */
	g_signal_connect (
		source, "notify::enabled",
		G_CALLBACK (source_refresh_notify_enabled_cb),
		extension);

	g_object_unref (source);
}

static void
e_source_refresh_class_init (ESourceRefreshClass *class)
{
	GObjectClass *object_class;
	ESourceExtensionClass *extension_class;

	g_type_class_add_private (class, sizeof (ESourceRefreshPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = source_refresh_set_property;
	object_class->get_property = source_refresh_get_property;
	object_class->dispose = source_refresh_dispose;
	object_class->finalize = source_refresh_finalize;
	object_class->constructed = source_refresh_constructed;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_REFRESH;

	g_object_class_install_property (
		object_class,
		PROP_ENABLED,
		g_param_spec_boolean (
			"enabled",
			"Enabled",
			"Whether to periodically refresh",
			TRUE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));

	g_object_class_install_property (
		object_class,
		PROP_INTERVAL_MINUTES,
		g_param_spec_uint (
			"interval-minutes",
			"Interval in Minutes",
			"Refresh interval in minutes",
			0, G_MAXUINT, 60,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS |
			E_SOURCE_PARAM_SETTING));
}

static void
e_source_refresh_init (ESourceRefresh *extension)
{
	GHashTable *timeout_table;

	timeout_table = g_hash_table_new_full (
		(GHashFunc) g_direct_hash,
		(GEqualFunc) g_direct_equal,
		(GDestroyNotify) NULL,
		(GDestroyNotify) timeout_node_free);

	extension->priv = E_SOURCE_REFRESH_GET_PRIVATE (extension);
	g_mutex_init (&extension->priv->timeout_lock);
	extension->priv->timeout_table = timeout_table;
	extension->priv->next_timeout_id = 1;
}

/**
 * e_source_refresh_get_enabled:
 * @extension: an #ESourceRefresh
 *
 * Returns whether to periodically fetch updates from a remote server.
 *
 * The refresh interval is determined by the #ESourceRefresh:interval-minutes
 * property.
 *
 * Returns: whether periodic refresh is enabled
 *
 * Since: 3.6
 **/
gboolean
e_source_refresh_get_enabled (ESourceRefresh *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_REFRESH (extension), FALSE);

	return extension->priv->enabled;
}

/**
 * e_source_refresh_set_enabled:
 * @extension: an #ESourceRefresh
 * @enabled: whether to enable periodic refresh
 *
 * Sets whether to periodically fetch updates from a remote server.
 *
 * The refresh interval is determined by the #ESourceRefresh:interval-minutes
 * property.
 *
 * Since: 3.6
 **/
void
e_source_refresh_set_enabled (ESourceRefresh *extension,
                              gboolean enabled)
{
	g_return_if_fail (E_IS_SOURCE_REFRESH (extension));

	extension->priv->enabled = enabled;

	g_object_notify (G_OBJECT (extension), "enabled");

	source_refresh_update_timeouts (extension, FALSE);
}

/**
 * e_source_refresh_get_interval_minutes:
 * @extension: an #ESourceRefresh
 *
 * Returns the interval for fetching updates from a remote server.
 *
 * Note this value is only effective when the #ESourceRefresh:enabled
 * property is %TRUE.
 *
 * Returns: the interval in minutes
 *
 * Since: 3.6
 **/
guint
e_source_refresh_get_interval_minutes (ESourceRefresh *extension)
{
	g_return_val_if_fail (E_IS_SOURCE_REFRESH (extension), FALSE);

	return extension->priv->interval_minutes;
}

/**
 * e_source_refresh_set_interval_minutes:
 * @extension: an #ESourceRefresh
 * @interval_minutes: the interval in minutes
 *
 * Sets the interval for fetching updates from a remote server.
 *
 * Note this value is only effective when the #ESourceRefresh:enabled
 * property is %TRUE.
 *
 * Since: 3.6
 **/
void
e_source_refresh_set_interval_minutes (ESourceRefresh *extension,
                                       guint interval_minutes)
{
	g_return_if_fail (E_IS_SOURCE_REFRESH (extension));

	if (interval_minutes == extension->priv->interval_minutes)
		return;

	extension->priv->interval_minutes = interval_minutes;

	g_object_notify (G_OBJECT (extension), "interval-minutes");

	source_refresh_update_timeouts (extension, FALSE);
}

/**
 * e_source_refresh_add_timeout:
 * @source: an #ESource
 * @context: (allow-none): a #GMainContext, or %NULL (if %NULL, the default
 *           context will be used)
 * @callback: function to call on each timeout
 * @user_data: data to pass to @callback
 * @notify: (allow-none): function to call when the timeout is removed,
 *          or %NULL
 *
 * This is a simple way to schedule a periodic data source refresh.
 *
 * Adds a timeout #GSource to @context and handles all the bookkeeping
 * if @source's refresh #ESourceRefresh:enabled state or its refresh
 * #ESourceRefresh:interval-minutes value changes.  The @callback is
 * expected to dispatch an asynchronous job to connect to and fetch
 * updates from a remote server.
 *
 * The returned ID can be passed to e_source_refresh_remove_timeout() to
 * remove the timeout from @context.  Note the ID is a private handle and
 * cannot be passed to g_source_remove().
 *
 * Returns: a refresh timeout ID
 *
 * Since: 3.6
 **/
guint
e_source_refresh_add_timeout (ESource *source,
                              GMainContext *context,
                              ESourceRefreshFunc callback,
                              gpointer user_data,
                              GDestroyNotify notify)
{
	ESourceRefresh *extension;
	const gchar *extension_name;
	TimeoutNode *node;
	guint timeout_id;
	gpointer key;

	g_return_val_if_fail (E_IS_SOURCE (source), 0);
	g_return_val_if_fail (callback != NULL, 0);

	extension_name = E_SOURCE_EXTENSION_REFRESH;
	extension = e_source_get_extension (source, extension_name);

	g_mutex_lock (&extension->priv->timeout_lock);

	timeout_id = extension->priv->next_timeout_id++;

	key = GUINT_TO_POINTER (timeout_id);
	node = timeout_node_new (
		extension, context, callback, user_data, notify);
	g_hash_table_insert (extension->priv->timeout_table, key, node);

	if (e_source_refresh_get_enabled (extension))
		timeout_node_attach (node);

	g_mutex_unlock (&extension->priv->timeout_lock);

	return timeout_id;
}

/**
 * e_source_refresh_force_timeout:
 * @source: an #ESource
 *
 * For all timeouts added with e_source_refresh_add_timeout(), invokes
 * the #ESourceRefreshFunc callback immediately and then, if the refresh
 * #ESourceRefresh:enabled state is TRUE, reschedules the timeout.
 *
 * This function is called automatically when the #ESource switches from
 * disabled to enabled, but can also be useful when a network connection
 * becomes available or when waking up from hibernation or suspend.
 *
 * Since: 3.6
 **/
void
e_source_refresh_force_timeout (ESource *source)
{
	ESourceRefresh *extension;
	const gchar *extension_name;

	g_return_if_fail (E_IS_SOURCE (source));

	extension_name = E_SOURCE_EXTENSION_REFRESH;
	extension = e_source_get_extension (source, extension_name);

	source_refresh_update_timeouts (extension, TRUE);
}

/**
 * e_source_refresh_remove_timeout:
 * @source: an #ESource
 * @refresh_timeout_id: a refresh timeout ID
 *
 * Removes a timeout #GSource added by e_source_refresh_add_timeout().
 *
 * Returns: %TRUE if the timeout was found and removed
 *
 * Since: 3.6
 **/
gboolean
e_source_refresh_remove_timeout (ESource *source,
                                 guint refresh_timeout_id)
{
	ESourceRefresh *extension;
	const gchar *extension_name;
	gboolean removed;
	gpointer key;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);
	g_return_val_if_fail (refresh_timeout_id > 0, FALSE);

	extension_name = E_SOURCE_EXTENSION_REFRESH;
	extension = e_source_get_extension (source, extension_name);

	g_mutex_lock (&extension->priv->timeout_lock);

	key = GUINT_TO_POINTER (refresh_timeout_id);
	removed = g_hash_table_remove (extension->priv->timeout_table, key);

	g_mutex_unlock (&extension->priv->timeout_lock);

	return removed;
}

/**
 * e_source_refresh_remove_timeouts_by_data:
 * @source: an #ESource
 * @user_data: user data to match against timeout callbacks
 *
 * Removes all timeout #GSource's added by e_source_refresh_add_timeout()
 * whose callback data pointer matches @user_data.
 *
 * Returns: the number of timeouts found and removed
 *
 * Since: 3.6
 **/
guint
e_source_refresh_remove_timeouts_by_data (ESource *source,
                                          gpointer user_data)
{
	ESourceRefresh *extension;
	const gchar *extension_name;
	GQueue trash = G_QUEUE_INIT;
	GHashTableIter iter;
	gpointer key, value;
	guint n_removed = 0;

	g_return_val_if_fail (E_IS_SOURCE (source), 0);

	extension_name = E_SOURCE_EXTENSION_REFRESH;
	extension = e_source_get_extension (source, extension_name);

	g_mutex_lock (&extension->priv->timeout_lock);

	g_hash_table_iter_init (&iter, extension->priv->timeout_table);

	while (g_hash_table_iter_next (&iter, &key, &value)) {
		TimeoutNode *node = value;

		if (node->user_data == user_data)
			g_queue_push_tail (&trash, key);
	}

	while ((key = g_queue_pop_head (&trash)) != NULL)
		if (g_hash_table_remove (extension->priv->timeout_table, key))
			n_removed++;

	g_mutex_unlock (&extension->priv->timeout_lock);

	return n_removed;
}

