/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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
 * SECTION: e-source-registry-watcher
 * @include: libedataserver/libedataserver.h
 * @short_description: Watch changes in #ESource-s
 *
 * #ESourceRegistryWatcher watches for changes in an #ESourceRegistry
 * and notifies about newly added and enabled #ESource instances, the same
 * as about removed or disabled. The amount of notifications can be filtered
 * with #ESourceRegistryWatcher::filter signal.
 *
 * The watcher listens only for changes, thus it is not pre-populated after
 * its creation. That's because the owner usually wants to subscribe to
 * the #ESourceRegistryWatcher::filter, #ESourceRegistryWatcher::appeared
 * and #ESourceRegistryWatcher::disappeared signals. The owner should
 * call e_source_registry_watcher_reclaim() when it has all the needed
 * signal handlers connected.
 **/

#include "evolution-data-server-config.h"

#include "e-source-registry.h"
#include "e-source.h"
#include "e-source-collection.h"

#include "e-source-registry-watcher.h"

struct _ESourceRegistryWatcherPrivate {
	ESourceRegistry *registry;
	gchar *extension_name;

	GHashTable *known_uids; /* gchar * UID ~> ESource */

	GRecMutex lock;

	gulong added_id;
	gulong enabled_id;
	gulong disabled_id;
	gulong removed_id;
	gulong changed_id;
};

G_DEFINE_TYPE (ESourceRegistryWatcher, e_source_registry_watcher, G_TYPE_OBJECT)

enum {
	PROP_0,
	PROP_EXTENSION_NAME,
	PROP_REGISTRY
};

enum {
	FILTER,
	APPEARED,
	DISAPPEARED,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

static gboolean
source_registry_watcher_try_remove (ESourceRegistryWatcher *watcher,
				    ESource *source)
{
	gboolean removed;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	g_rec_mutex_lock (&watcher->priv->lock);
	removed = g_hash_table_remove (watcher->priv->known_uids, e_source_get_uid (source));
	g_rec_mutex_unlock (&watcher->priv->lock);

	if (removed)
		g_signal_emit (watcher, signals[DISAPPEARED], 0, source);

	return removed;
}

static gboolean
source_registry_watcher_try_add (ESourceRegistryWatcher *watcher,
				 ESource *source,
				 gboolean with_remove_check,
				 gboolean skip_appeared_emit)
{
	gboolean can_include = TRUE;
	gboolean added = FALSE;
	gchar *uid;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	uid = e_source_dup_uid (source);
	if (!uid)
		return FALSE;

	g_signal_emit (watcher, signals[FILTER], 0, source, &can_include);

	if (!can_include) {
		if (with_remove_check)
			source_registry_watcher_try_remove (watcher, source);

		g_free (uid);
		return FALSE;
	}

	g_rec_mutex_lock (&watcher->priv->lock);

	if (!g_hash_table_contains (watcher->priv->known_uids, uid)) {
		g_hash_table_insert (watcher->priv->known_uids, uid, g_object_ref (source));
		added = TRUE;
	} else {
		g_free (uid);
	}

	g_rec_mutex_unlock (&watcher->priv->lock);

	if (added && !skip_appeared_emit)
		g_signal_emit (watcher, signals[APPEARED], 0, source);

	return added;
}

static void
source_registry_watcher_reclaim_internal (ESourceRegistryWatcher *watcher,
					  gboolean merge_like)
{
	GHashTable *old_known_uids = NULL;
	GList *enabled, *link;

	g_return_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher));

	g_rec_mutex_lock (&watcher->priv->lock);
	if (merge_like) {
		old_known_uids = watcher->priv->known_uids;
		watcher->priv->known_uids = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_object_unref);
	} else {
		g_hash_table_remove_all (watcher->priv->known_uids);
	}

	enabled = e_source_registry_list_enabled (watcher->priv->registry, watcher->priv->extension_name);
	for (link = enabled; link; link = g_list_next (link)) {
		ESource *source = link->data;
		gboolean skip_appeared_emit;

		skip_appeared_emit = old_known_uids && g_hash_table_contains (old_known_uids, e_source_get_uid (source));

		if (source_registry_watcher_try_add (watcher, source, FALSE, skip_appeared_emit) && old_known_uids)
			g_hash_table_remove (old_known_uids, e_source_get_uid (source));
	}
	g_list_free_full (enabled, g_object_unref);

	g_rec_mutex_unlock (&watcher->priv->lock);

	if (old_known_uids) {
		GHashTableIter iter;
		gpointer value;

		g_hash_table_iter_init (&iter, old_known_uids);
		while (g_hash_table_iter_next (&iter, NULL, &value)) {
			ESource *source = value;

			g_signal_emit (watcher, signals[DISAPPEARED], 0, source);
		}

		g_hash_table_destroy (old_known_uids);
	}
}

static void
source_registry_watcher_source_added_or_enabled_cb (ESourceRegistry *registry,
						    ESource *source,
						    gpointer user_data)
{
	ESourceRegistryWatcher *watcher = user_data;

	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher));

	if (e_source_registry_check_enabled (registry, source))
		source_registry_watcher_try_add (watcher, source, TRUE, FALSE);
}

static void
source_registry_watcher_source_removed_or_disabled_cb (ESourceRegistry *registry,
						       ESource *source,
						       gpointer user_data)
{
	ESourceRegistryWatcher *watcher = user_data;

	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher));

	source_registry_watcher_try_remove (watcher, source);
}

static void
source_registry_watcher_source_changed_cb (ESourceRegistry *registry,
					   ESource *source,
					   gpointer user_data)
{
	ESourceRegistryWatcher *watcher = user_data;

	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher));

	if (!watcher->priv->extension_name ||
	    e_source_has_extension (source, watcher->priv->extension_name)) {
		if (e_source_registry_check_enabled (registry, source))
			source_registry_watcher_try_add (watcher, source, TRUE, FALSE);
		else
			source_registry_watcher_try_remove (watcher, source);
	}
}

static void
source_registry_watcher_set_registry (ESourceRegistryWatcher *watcher,
				      ESourceRegistry *registry)
{
	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (watcher->priv->registry == NULL);

	watcher->priv->registry = g_object_ref (registry);
}

static void
source_registry_watcher_set_extension_name (ESourceRegistryWatcher *watcher,
					    const gchar *extension_name)
{
	if (g_strcmp0 (watcher->priv->extension_name, extension_name) != 0) {
		g_free (watcher->priv->extension_name);
		watcher->priv->extension_name = g_strdup (extension_name);
	}
}

static void
source_registry_watcher_set_property (GObject *object,
				      guint property_id,
				      const GValue *value,
				      GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_EXTENSION_NAME:
			source_registry_watcher_set_extension_name (
				E_SOURCE_REGISTRY_WATCHER (object),
				g_value_get_string (value));
			return;

		case PROP_REGISTRY:
			source_registry_watcher_set_registry (
				E_SOURCE_REGISTRY_WATCHER (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_registry_watcher_get_property (GObject *object,
				      guint property_id,
				      GValue *value,
				      GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_EXTENSION_NAME:
			g_value_set_string (
				value,
				e_source_registry_watcher_get_extension_name (
				E_SOURCE_REGISTRY_WATCHER (object)));
			return;

		case PROP_REGISTRY:
			g_value_set_object (
				value,
				e_source_registry_watcher_get_registry (
				E_SOURCE_REGISTRY_WATCHER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
source_registry_watcher_constructed (GObject *object)
{
	ESourceRegistryWatcher *watcher = E_SOURCE_REGISTRY_WATCHER (object);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_source_registry_watcher_parent_class)->constructed (object);

	g_return_if_fail (watcher->priv->registry != NULL);

	watcher->priv->added_id = g_signal_connect (watcher->priv->registry, "source-added",
		G_CALLBACK (source_registry_watcher_source_added_or_enabled_cb), watcher);

	watcher->priv->enabled_id = g_signal_connect (watcher->priv->registry, "source-enabled",
		G_CALLBACK (source_registry_watcher_source_added_or_enabled_cb), watcher);

	watcher->priv->disabled_id = g_signal_connect (watcher->priv->registry, "source-disabled",
		G_CALLBACK (source_registry_watcher_source_removed_or_disabled_cb), watcher);

	watcher->priv->removed_id = g_signal_connect (watcher->priv->registry, "source-removed",
		G_CALLBACK (source_registry_watcher_source_removed_or_disabled_cb), watcher);

	watcher->priv->changed_id = g_signal_connect (watcher->priv->registry, "source-changed",
		G_CALLBACK (source_registry_watcher_source_changed_cb), watcher);
}

static void
source_registry_watcher_dispose (GObject *object)
{
	ESourceRegistryWatcher *watcher = E_SOURCE_REGISTRY_WATCHER (object);

#define unset_handler(x) G_STMT_START { \
	if (x) { \
		g_signal_handler_disconnect (watcher->priv->registry, x); \
		x = 0; \
	} } G_STMT_END

	unset_handler (watcher->priv->added_id);
	unset_handler (watcher->priv->enabled_id);
	unset_handler (watcher->priv->disabled_id);
	unset_handler (watcher->priv->removed_id);
	unset_handler (watcher->priv->changed_id);

#undef unset_handler

	g_clear_object (&watcher->priv->registry);

	g_hash_table_remove_all (watcher->priv->known_uids);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_source_registry_watcher_parent_class)->dispose (object);
}

static void
source_registry_watcher_finalize (GObject *object)
{
	ESourceRegistryWatcher *watcher = E_SOURCE_REGISTRY_WATCHER (object);

	g_hash_table_destroy (watcher->priv->known_uids);
	g_free (watcher->priv->extension_name);
	g_rec_mutex_clear (&watcher->priv->lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_source_registry_watcher_parent_class)->finalize (object);
}

static void
e_source_registry_watcher_class_init (ESourceRegistryWatcherClass *klass)
{
	GObjectClass *object_class;

	g_type_class_add_private (klass, sizeof (ESourceRegistryWatcherPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->set_property = source_registry_watcher_set_property;
	object_class->get_property = source_registry_watcher_get_property;
	object_class->constructed = source_registry_watcher_constructed;
	object_class->dispose = source_registry_watcher_dispose;
	object_class->finalize = source_registry_watcher_finalize;

	/**
	 * ESourceRegistryWatcher:extension-name:
	 *
	 * Optional extension name, to consider sources with only.
	 * It can be %NULL, to check for all sources. This is
	 * a complementary filter to #ESourceRegistryWatcher::filter
	 * signal.
	 *
	 * Since: 3.26
	 **/
	g_object_class_install_property (
		object_class,
		PROP_EXTENSION_NAME,
		g_param_spec_string (
			"extension-name",
			"ExtensionName",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ESourceRegistryWatcher:registry:
	 *
	 * The #ESourceRegistry manages #ESource instances.
	 *
	 * Since: 3.26
	 **/
	g_object_class_install_property (
		object_class,
		PROP_REGISTRY,
		g_param_spec_object (
			"registry",
			"Registry",
			"Data source registry",
			E_TYPE_SOURCE_REGISTRY,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ESourceRegistryWatcher::filter:
	 * @watcher: the #ESourceRegistryWatcher that received the signal
	 * @source: the #ESource to filter
	 *
	 * A filter signal which verifies whether the @source can be considered
	 * for inclusion in the watcher or not. If none is set then all the sources
	 * are included.
	 *
	 * Returns: %TRUE, when the @source can be included, %FALSE otherwise.
	 *
	 * Since: 3.26
	 **/
	signals[FILTER] = g_signal_new (
		"filter",
		G_TYPE_FROM_CLASS (klass),
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET (ESourceRegistryWatcherClass, filter),
		NULL, NULL, NULL,
		G_TYPE_BOOLEAN, 1,
		E_TYPE_SOURCE);

	/**
	 * ESourceRegistryWatcher::appeared:
	 * @watcher: the #ESourceRegistryWatcher that received the signal
	 * @source: the #ESource which appeared
	 *
	 * A signal emitted when the @source is enabled or added and it had been
	 * considered for inclusion with the @ESourceRegistryWatcher::filter signal.
	 *
	 * Since: 3.26
	 **/
	signals[APPEARED] = g_signal_new (
		"appeared",
		G_TYPE_FROM_CLASS (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ESourceRegistryWatcherClass, appeared),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		E_TYPE_SOURCE);

	/**
	 * ESourceRegistryWatcher::disappeared:
	 * @watcher: the #ESourceRegistryWatcher that received the signal
	 * @source: the #ESource which disappeared
	 *
	 * A signal emitted when the @source is disabled or removed and it had been
	 * considered for inclusion with the @ESourceRegistryWatcher::filter signal
	 * earlier.
	 *
	 * Since: 3.26
	 **/
	signals[DISAPPEARED] = g_signal_new (
		"disappeared",
		G_TYPE_FROM_CLASS (klass),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ESourceRegistryWatcherClass, disappeared),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		E_TYPE_SOURCE);
}

static void
e_source_registry_watcher_init (ESourceRegistryWatcher *watcher)
{
	watcher->priv = G_TYPE_INSTANCE_GET_PRIVATE (watcher, E_TYPE_SOURCE_REGISTRY_WATCHER, ESourceRegistryWatcherPrivate);

	g_rec_mutex_init (&watcher->priv->lock);

	watcher->priv->known_uids = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_object_unref);
}

/**
 * e_source_registry_watcher_new:
 * @registry: an #ESourceRegistry
 * @extension_name: (nullable): optional extension name to filter sources with, or %NULL
 *
 * Creates a new #ESourceRegistryWatcher instance.
 *
 * The @extension_name can be used as a complementary filter
 * to #ESourceRegistryWatcher::filter signal.
 *
 * Returns: (transfer full): an #ESourceRegistryWatcher
 *
 * Since: 3.26
 **/
ESourceRegistryWatcher *
e_source_registry_watcher_new (ESourceRegistry *registry,
			       const gchar *extension_name)
{
	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), NULL);

	return g_object_new (E_TYPE_SOURCE_REGISTRY_WATCHER,
		"registry", registry,
		"extension-name", extension_name,
		NULL);
}

/**
 * e_source_registry_watcher_get_registry:
 * @watcher: an #ESourceRegistryWatcher
 *
 * Returns the #ESourceRegistry passed to e_source_registry_watcher_new().
 *
 * Returns: (transfer none): an #ESourceRegistry
 *
 * Since: 3.26
 **/
ESourceRegistry *
e_source_registry_watcher_get_registry (ESourceRegistryWatcher *watcher)
{
	g_return_val_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher), NULL);

	return watcher->priv->registry;
}

/**
 * e_source_registry_watcher_get_extension_name:
 * @watcher: an #ESourceRegistryWatcher
 *
 * Returns: (nullable): The extension name passed to e_source_registry_watcher_new().
 *
 * Since: 3.26
 **/
const gchar *
e_source_registry_watcher_get_extension_name (ESourceRegistryWatcher *watcher)
{
	g_return_val_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher), NULL);

	return watcher->priv->extension_name;
}

/**
 * e_source_registry_watcher_reclaim:
 * @watcher: an #ESourceRegistryWatcher
 *
 * Reclaims all available sources satisfying the #ESourceRegistryWatcher::filter
 * signal. It doesn't notify about disappeared sources, it notifies only
 * on those appeared.
 *
 * Since: 3.26
 **/
void
e_source_registry_watcher_reclaim (ESourceRegistryWatcher *watcher)
{
	g_return_if_fail (E_IS_SOURCE_REGISTRY_WATCHER (watcher));

	source_registry_watcher_reclaim_internal (watcher, FALSE);
}
