/*
 * Copyright (C) 2016 Red Hat, Inc. (www.redhat.com)
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

#include "evolution-data-server-config.h"

#include <gio/gio.h>

#include "e-network-monitor.h"

struct _ENetworkMonitorPrivate {
	GMutex property_lock;
	gchar *gio_name;
	GNetworkMonitor *gio_monitor;
	gulong network_available_notify_id;
	gulong network_metered_notify_id;
	gulong network_connectivity_notify_id;
	gulong network_changed_id;
	GSource *network_changed_source;
};

enum {
	PROP_0,
	PROP_GIO_NAME,
	PROP_CONNECTIVITY,
	PROP_NETWORK_METERED,
	PROP_NETWORK_AVAILABLE
};

static guint network_changed_signal = 0;

static void e_network_monitor_initable_iface_init (GInitableIface *iface);
static void e_network_monitor_gio_iface_init (GNetworkMonitorInterface *iface);

G_DEFINE_TYPE_WITH_CODE (ENetworkMonitor, e_network_monitor, G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (G_TYPE_INITABLE, e_network_monitor_initable_iface_init)
	G_IMPLEMENT_INTERFACE (G_TYPE_NETWORK_MONITOR, e_network_monitor_gio_iface_init))

static GNetworkConnectivity
e_network_monitor_get_connectivity (ENetworkMonitor *network_monitor)
{
	GNetworkConnectivity connectivity;

	g_return_val_if_fail (E_IS_NETWORK_MONITOR (network_monitor), G_NETWORK_CONNECTIVITY_LOCAL);

	g_mutex_lock (&network_monitor->priv->property_lock);

	if (network_monitor->priv->gio_monitor)
		connectivity = g_network_monitor_get_connectivity (network_monitor->priv->gio_monitor);
	else
		connectivity = G_NETWORK_CONNECTIVITY_FULL;

	g_mutex_unlock (&network_monitor->priv->property_lock);

	return connectivity;
}

static gboolean
e_network_monitor_get_network_available (ENetworkMonitor *network_monitor)
{
	gboolean network_available;

	g_return_val_if_fail (E_IS_NETWORK_MONITOR (network_monitor), FALSE);

	g_mutex_lock (&network_monitor->priv->property_lock);

	if (network_monitor->priv->gio_monitor)
		network_available = g_network_monitor_get_network_available (network_monitor->priv->gio_monitor);
	else
		network_available = TRUE;

	g_mutex_unlock (&network_monitor->priv->property_lock);

	return network_available;
}

static gboolean
e_network_monitor_get_network_metered (ENetworkMonitor *network_monitor)
{
	gboolean network_metered;

	g_return_val_if_fail (E_IS_NETWORK_MONITOR (network_monitor), FALSE);

	g_mutex_lock (&network_monitor->priv->property_lock);

	if (network_monitor->priv->gio_monitor)
		network_metered = g_network_monitor_get_network_metered (network_monitor->priv->gio_monitor);
	else
		network_metered = FALSE;

	g_mutex_unlock (&network_monitor->priv->property_lock);

	return network_metered;
}

static gboolean
e_network_monitor_emit_network_changed_idle_cb (gpointer user_data)
{
	ENetworkMonitor *network_monitor = user_data;
	gboolean is_available;

	g_return_val_if_fail (E_IS_NETWORK_MONITOR (network_monitor), FALSE);

	g_object_ref (network_monitor);

	is_available = e_network_monitor_get_network_available (network_monitor);
	g_signal_emit (network_monitor, network_changed_signal, 0, is_available);

	g_source_unref (network_monitor->priv->network_changed_source);
	network_monitor->priv->network_changed_source = NULL;

	g_object_unref (network_monitor);

	return FALSE;
}

static void
e_network_monitor_schedule_network_changed_emit (ENetworkMonitor *network_monitor)
{
	g_mutex_lock (&network_monitor->priv->property_lock);

	if (!network_monitor->priv->network_changed_source) {
		network_monitor->priv->network_changed_source = g_idle_source_new ();
		/* Use G_PRIORITY_HIGH_IDLE priority so that multiple
		 * network-change-related notifications coming in at
		 * G_PRIORITY_DEFAULT will get coalesced into one signal
		 * emission.
		 */
		g_source_set_priority (network_monitor->priv->network_changed_source, G_PRIORITY_HIGH_IDLE);
		g_source_set_callback (network_monitor->priv->network_changed_source,
			e_network_monitor_emit_network_changed_idle_cb, network_monitor, NULL);
		g_source_attach (network_monitor->priv->network_changed_source, NULL);
	}

	g_mutex_unlock (&network_monitor->priv->property_lock);
}

static void
e_network_monitor_notify_cb (GNetworkMonitor *gio_monitor,
			     GParamSpec *param,
			     ENetworkMonitor *network_monitor)
{
	g_return_if_fail (G_IS_NETWORK_MONITOR (gio_monitor));
	g_return_if_fail (param && param->name);
	g_return_if_fail (E_IS_NETWORK_MONITOR (network_monitor));

	g_object_notify (G_OBJECT (network_monitor), param->name);
}

static void
e_network_monitor_network_changed_cb (GNetworkMonitor *gio_monitor,
				      gboolean is_available,
				      ENetworkMonitor *network_monitor)
{
	g_return_if_fail (G_IS_NETWORK_MONITOR (gio_monitor));
	g_return_if_fail (E_IS_NETWORK_MONITOR (network_monitor));

	e_network_monitor_schedule_network_changed_emit (network_monitor);
}

static void
e_network_monitor_disconnect_gio_monitor_locked (ENetworkMonitor *network_monitor)
{
	if (!network_monitor->priv->gio_monitor)
		return;

	#define disconnect_signal(x) G_STMT_START { \
		if (network_monitor->priv->x) { \
			g_signal_handler_disconnect (network_monitor->priv->gio_monitor, network_monitor->priv->x); \
			network_monitor->priv->x = 0; \
		} \
		} G_STMT_END

	disconnect_signal (network_available_notify_id);
	disconnect_signal (network_metered_notify_id);
	disconnect_signal (network_connectivity_notify_id);
	disconnect_signal (network_changed_id);

	#undef disconnect_signal
}

static void
e_network_monitor_set_property (GObject *object,
				guint property_id,
				const GValue *value,
				GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_GIO_NAME:
			e_network_monitor_set_gio_name (
				E_NETWORK_MONITOR (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_network_monitor_get_property (GObject *object,
				guint property_id,
				GValue *value,
				GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_GIO_NAME:
			g_value_take_string (
				value,
				e_network_monitor_dup_gio_name (
				E_NETWORK_MONITOR (object)));
			return;

		case PROP_CONNECTIVITY:
			g_value_set_enum (
				value,
				e_network_monitor_get_connectivity (
				E_NETWORK_MONITOR (object)));
			return;

		case PROP_NETWORK_METERED:
			g_value_set_boolean (
				value,
				e_network_monitor_get_network_metered (
				E_NETWORK_MONITOR (object)));
			return;

		case PROP_NETWORK_AVAILABLE:
			g_value_set_boolean (
				value,
				e_network_monitor_get_network_available (
				E_NETWORK_MONITOR (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
e_network_monitor_constructed (GObject *object)
{
	GSettings *settings;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_network_monitor_parent_class)->constructed (object);

	settings = g_settings_new ("org.gnome.evolution-data-server");
	g_settings_bind (
		settings, "network-monitor-gio-name",
		object, "gio-name",
		G_SETTINGS_BIND_DEFAULT);
	g_object_unref (settings);
}

static void
e_network_monitor_finalize (GObject *object)
{
	ENetworkMonitor *network_monitor = E_NETWORK_MONITOR (object);

	if (network_monitor->priv->network_changed_source) {
		g_source_destroy (network_monitor->priv->network_changed_source);
		g_source_unref (network_monitor->priv->network_changed_source);
		network_monitor->priv->network_changed_source = NULL;
	}

	g_mutex_lock (&network_monitor->priv->property_lock);
	e_network_monitor_disconnect_gio_monitor_locked (network_monitor);
	g_mutex_unlock (&network_monitor->priv->property_lock);

	g_mutex_clear (&network_monitor->priv->property_lock);
	g_clear_object (&network_monitor->priv->gio_monitor);
	g_free (network_monitor->priv->gio_name);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_network_monitor_parent_class)->finalize (object);
}

static void
e_network_monitor_class_init (ENetworkMonitorClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ENetworkMonitorPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = e_network_monitor_set_property;
	object_class->get_property = e_network_monitor_get_property;
	object_class->constructed = e_network_monitor_constructed;
	object_class->finalize = e_network_monitor_finalize;

	/**
	 * ENetworkMonitor:gio-name:
	 *
	 * The GIO name of the underlying #GNetworkMonitor to use.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_GIO_NAME,
		g_param_spec_string (
			"gio-name",
			"GIO name",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_override_property (object_class, PROP_NETWORK_AVAILABLE, "network-available");
	g_object_class_override_property (object_class, PROP_NETWORK_METERED, "network-metered");
	g_object_class_override_property (object_class, PROP_CONNECTIVITY, "connectivity");
}

static void
e_network_monitor_init (ENetworkMonitor *network_monitor)
{
	network_monitor->priv = G_TYPE_INSTANCE_GET_PRIVATE (network_monitor, E_TYPE_NETWORK_MONITOR, ENetworkMonitorPrivate);

	g_mutex_init (&network_monitor->priv->property_lock);
}

static gboolean
e_network_monitor_initable_init (GInitable *initable,
				 GCancellable *cancellable,
				 GError **error)
{
	return TRUE;
}

static void
e_network_monitor_initable_iface_init (GInitableIface *iface)
{
	iface->init = e_network_monitor_initable_init;
}

static gboolean
e_network_monitor_can_reach (GNetworkMonitor *monitor,
			     GSocketConnectable *connectable,
			     GCancellable *cancellable,
			     GError **error)
{
	ENetworkMonitor *network_monitor;
	GNetworkMonitor *use_gio_monitor = NULL;
	gboolean can_reach;

	g_return_val_if_fail (E_IS_NETWORK_MONITOR (monitor), FALSE);

	network_monitor = E_NETWORK_MONITOR (monitor);

	g_mutex_lock (&network_monitor->priv->property_lock);

	if (network_monitor->priv->gio_monitor)
		use_gio_monitor = g_object_ref (network_monitor->priv->gio_monitor);

	g_mutex_unlock (&network_monitor->priv->property_lock);

	if (use_gio_monitor)
		can_reach = g_network_monitor_can_reach (use_gio_monitor, connectable, cancellable, error);
	else
		can_reach = TRUE;

	g_clear_object (&use_gio_monitor);

	return can_reach;
}

static void
e_network_monitor_can_reach_async_thread (GTask *task,
					  gpointer source_object,
					  gpointer task_data,
					  GCancellable *cancellable)
{
	gboolean success;
	GError *local_error = NULL;

	success = e_network_monitor_can_reach (source_object, task_data, cancellable, &local_error);

	if (local_error)
		g_task_return_error (task, local_error);
	else
		g_task_return_boolean (task, success);
}

static void
e_network_monitor_can_reach_async (GNetworkMonitor *monitor,
				   GSocketConnectable *connectable,
				   GCancellable *cancellable,
				   GAsyncReadyCallback callback,
				   gpointer user_data)
{
	GTask *task;

	g_return_if_fail (E_IS_NETWORK_MONITOR (monitor));
	g_return_if_fail (G_IS_SOCKET_CONNECTABLE (connectable));

	task = g_task_new (monitor, cancellable, callback, user_data);
	g_task_set_source_tag (task, e_network_monitor_can_reach_async);
	g_task_set_task_data (task, g_object_ref (connectable), g_object_unref);

	g_task_run_in_thread (task, e_network_monitor_can_reach_async_thread);

	g_object_unref (task);
}

static gboolean
e_network_monitor_can_reach_finish (GNetworkMonitor *monitor,
				    GAsyncResult *result,
				    GError **error)
{
	g_return_val_if_fail (E_IS_NETWORK_MONITOR (monitor), FALSE);
	g_return_val_if_fail (g_task_is_valid (result, monitor), FALSE);

	g_return_val_if_fail (
		g_async_result_is_tagged (
		result, e_network_monitor_can_reach_async), FALSE);

	return g_task_propagate_boolean (G_TASK (result), error);
}

static void
e_network_monitor_gio_iface_init (GNetworkMonitorInterface *iface)
{
	iface->can_reach = e_network_monitor_can_reach;
	iface->can_reach_async = e_network_monitor_can_reach_async;
	iface->can_reach_finish = e_network_monitor_can_reach_finish;

	if (!network_changed_signal)
		network_changed_signal = g_signal_lookup ("network-changed", G_TYPE_NETWORK_MONITOR);
}

static GNetworkMonitor *
e_network_monitor_create_instance_for_gio_name (const gchar *gio_name)
{
	GIOExtensionPoint *pnt;
	GList *extensions, *link;

	if (!gio_name || !*gio_name)
		return NULL;

	/* To initialize the GIO extension point for the GNetworkMonitor */
	g_network_monitor_get_default ();

	pnt = g_io_extension_point_lookup (G_NETWORK_MONITOR_EXTENSION_POINT_NAME);
	if (!pnt)
		return NULL;

	extensions = g_io_extension_point_get_extensions (pnt);

	for (link = extensions; link; link = g_list_next (link)) {
		GIOExtension *ext = link->data;

		if (g_strcmp0 (g_io_extension_get_name (ext), gio_name) == 0)
			return g_initable_new (g_io_extension_get_type (ext), NULL, NULL, NULL);
	}

	return NULL;
}

/**
 * e_network_monitor_get_default:
 *
 * Gets the default #ENetworkMonitor. The caller should not unref the returned instance.
 * The #ENetworkMonitor implements the #GNetworkMonitor iterface.
 *
 * Returns: (transfer none): The default #ENetworkMonitor instance.
 *
 * Since: 3.22
 **/
GNetworkMonitor *
e_network_monitor_get_default (void)
{
	static GNetworkMonitor *network_monitor = NULL;
	G_LOCK_DEFINE_STATIC (network_monitor);

	G_LOCK (network_monitor);
	if (!network_monitor)
		network_monitor = g_initable_new (E_TYPE_NETWORK_MONITOR, NULL, NULL, NULL);
	G_UNLOCK (network_monitor);

	return network_monitor;
}

/**
 * e_network_monitor_list_gio_names:
 * @network_monitor: an #ENetworkMonitor
 *
 * Get a list of available GIO names for the #GNetworkMonitor implementations.
 * The strings can be used in e_network_monitor_set_gio_name().
 *
 * Returns: (transfer full) (element-type utf8): A newly allocated #GSList,
 *   with newly allocated strings, the GIO names. The #GSList should be freed
 *   with g_slist_free_full (gio_names, g_free); when no longer needed.
 *
 * Since: 3.22
 **/
GSList *
e_network_monitor_list_gio_names (ENetworkMonitor *network_monitor)
{
	GIOExtensionPoint *pnt;
	GList *extensions, *link;
	GSList *gio_names = NULL;

	g_return_val_if_fail (E_IS_NETWORK_MONITOR (network_monitor), NULL);

	/* To initialize the GIO extension point for the GNetworkMonitor */
	g_network_monitor_get_default ();

	pnt = g_io_extension_point_lookup (G_NETWORK_MONITOR_EXTENSION_POINT_NAME);
	if (!pnt)
		return NULL;

	extensions = g_io_extension_point_get_extensions (pnt);

	for (link = extensions; link; link = g_list_next (link)) {
		GIOExtension *ext = link->data;

		gio_names = g_slist_prepend (gio_names, g_strdup (g_io_extension_get_name (ext)));
	}

	return g_slist_reverse (gio_names);
}

/**
 * e_network_monitor_dup_gio_name:
 * @network_monitor: an #ENetworkMonitor
 *
 * Get currently set GIO name for the network availability checks.
 * See e_network_monitor_set_gio_name() for more details.
 *
 * Returns: (transfer full): A newly allocated string, a GIO name
 *   of the underlying GNetworkMonitor which is set to be used.
 *   The returned string should be freed with g_free(), when
 *   no longer needed.
 *
 * Since: 3.22
 **/
gchar *
e_network_monitor_dup_gio_name (ENetworkMonitor *network_monitor)
{
	gchar *gio_name;

	g_return_val_if_fail (E_IS_NETWORK_MONITOR (network_monitor), NULL);

	g_mutex_lock (&network_monitor->priv->property_lock);
	gio_name = g_strdup (network_monitor->priv->gio_name);
	g_mutex_unlock (&network_monitor->priv->property_lock);

	return gio_name;
}

/**
 * e_network_monitor_set_gio_name:
 * @network_monitor: an #ENetworkMonitor
 * @gio_name: (nullable): a GIO name of a #GNetworkMonitor implementation to use, or %NULL
 *
 * Set a @gio_name of the #GNetworkMonitor implementation to use, can be %NULL.
 * Use e_network_monitor_list_gio_names() for a list of available
 * implementations. A special value, %E_NETWORK_MONITOR_ALWAYS_ONLINE_NAME, can
 * be used to report the network as always reachable. When an unknown GIO
 * name is used the default #GNetworkMonitor implementation, as returned
 * by the g_network_monitor_get_default(), will be used.
 *
 * Since: 3.22
 **/
void
e_network_monitor_set_gio_name (ENetworkMonitor *network_monitor,
				const gchar *gio_name)
{
	GObject *object;

	g_return_if_fail (E_IS_NETWORK_MONITOR (network_monitor));

	g_mutex_lock (&network_monitor->priv->property_lock);

	if (g_strcmp0 (gio_name, network_monitor->priv->gio_name) == 0) {
		g_mutex_unlock (&network_monitor->priv->property_lock);
		return;
	}

	g_free (network_monitor->priv->gio_name);
	network_monitor->priv->gio_name = g_strdup (gio_name);

	if (network_monitor->priv->gio_monitor)
		e_network_monitor_disconnect_gio_monitor_locked (network_monitor);

	g_clear_object (&network_monitor->priv->gio_monitor);

	if (g_strcmp0 (network_monitor->priv->gio_name, E_NETWORK_MONITOR_ALWAYS_ONLINE_NAME) != 0) {
		GNetworkMonitor *gio_monitor;

		gio_monitor = e_network_monitor_create_instance_for_gio_name (network_monitor->priv->gio_name);
		if (!gio_monitor)
			gio_monitor = g_object_ref (g_network_monitor_get_default ());

		network_monitor->priv->gio_monitor = gio_monitor;

		if (gio_monitor) {
			network_monitor->priv->network_available_notify_id =
				g_signal_connect (network_monitor->priv->gio_monitor, "notify::network-available",
					G_CALLBACK (e_network_monitor_notify_cb), network_monitor);

			network_monitor->priv->network_metered_notify_id =
				g_signal_connect (network_monitor->priv->gio_monitor, "notify::network-metered",
					G_CALLBACK (e_network_monitor_notify_cb), network_monitor);

			network_monitor->priv->network_connectivity_notify_id =
				g_signal_connect (network_monitor->priv->gio_monitor, "notify::connectivity",
					G_CALLBACK (e_network_monitor_notify_cb), network_monitor);

			network_monitor->priv->network_changed_id =
				g_signal_connect (network_monitor->priv->gio_monitor, "network-changed",
					G_CALLBACK (e_network_monitor_network_changed_cb), network_monitor);
		}
	}

	g_mutex_unlock (&network_monitor->priv->property_lock);

	object = G_OBJECT (network_monitor);

	g_object_freeze_notify (object);
	g_object_notify (object, "gio-name");
	g_object_notify (object, "network-available");
	g_object_notify (object, "network-metered");
	g_object_notify (object, "connectivity");
	g_object_thaw_notify (object);

	e_network_monitor_schedule_network_changed_emit (network_monitor);
}
