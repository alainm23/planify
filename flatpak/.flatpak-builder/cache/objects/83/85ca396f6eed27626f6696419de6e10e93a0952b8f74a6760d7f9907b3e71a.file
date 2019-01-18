/*
 * e-cal-backend.c
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
 * SECTION: e-cal-backend
 * @include: libedata-cal/libedata-cal.h
 * @short_description: An abstract class for implementing calendar backends
 *
 * This is the main server facing API for interfacing with calendar backends,
 * calendar backends must implement methods on this class.
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "e-cal-backend.h"
#include "e-cal-backend-cache.h"

#define E_CAL_BACKEND_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL_BACKEND, ECalBackendPrivate))

typedef struct _AsyncContext AsyncContext;
typedef struct _DispatchNode DispatchNode;
typedef struct _SignalClosure SignalClosure;

struct _ECalBackendPrivate {
	ESourceRegistry *registry;
	EDataCal *data_cal;

	gboolean opened;

	/* The kind of components for this backend */
	icalcomponent_kind kind;

	GMutex views_mutex;
	GList *views;

	GMutex property_lock;
	GProxyResolver *proxy_resolver;
	gchar *cache_dir;
	gboolean writable;

	ESource *authentication_source;
	gulong auth_source_changed_handler_id;

	GHashTable *zone_cache;
	GMutex zone_cache_lock;

	GMutex operation_lock;
	GThreadPool *thread_pool;
	GHashTable *operation_ids;
	GQueue pending_operations;
	guint32 next_operation_id;
	GSimpleAsyncResult *blocked;
	gboolean blocked_by_custom_op;
};

struct _AsyncContext {
	/* Inputs */
	gchar *uid;
	gchar *rid;
	gchar *alarm_uid;
	gchar *calobj;
	gchar *query;
	gchar *tzid;
	gchar *tzobject;
	ECalObjModType mod;
	time_t start;
	time_t end;
	GSList *compid_list;
	GSList *string_list;

	/* Outputs */
	GQueue result_queue;

	/* One of these should point to result_queue
	 * so any leftover resources can be released. */
	GQueue *object_queue;
	GQueue *string_queue;
};

struct _DispatchNode {
	/* This is the dispatch function
	 * that invokes the class method. */
	GSimpleAsyncThreadFunc dispatch_func;
	gboolean blocking_operation;

	GSimpleAsyncResult *simple;
	GCancellable *cancellable;

	GWeakRef *cal_backend_weak_ref;
	ECalBackendCustomOpFunc custom_func;
	gpointer custom_func_user_data;
	GDestroyNotify custom_func_user_data_free;
};

struct _SignalClosure {
	GWeakRef backend;
	icaltimezone *cached_zone;
};

enum {
	PROP_0,
	PROP_CACHE_DIR,
	PROP_KIND,
	PROP_PROXY_RESOLVER,
	PROP_REGISTRY,
	PROP_WRITABLE
};

enum {
	CLOSED,
	SHUTDOWN,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

/* Forward Declarations */
static void	e_cal_backend_timezone_cache_init
					(ETimezoneCacheInterface *iface);

G_DEFINE_TYPE_WITH_CODE (
	ECalBackend,
	e_cal_backend,
	E_TYPE_BACKEND,
	G_IMPLEMENT_INTERFACE (
		E_TYPE_TIMEZONE_CACHE,
		e_cal_backend_timezone_cache_init))

static void
async_context_free (AsyncContext *async_context)
{
	GQueue *queue;

	g_free (async_context->uid);
	g_free (async_context->rid);
	g_free (async_context->alarm_uid);
	g_free (async_context->calobj);
	g_free (async_context->query);
	g_free (async_context->tzid);
	g_free (async_context->tzobject);

	g_slist_free_full (
		async_context->compid_list,
		(GDestroyNotify) e_cal_component_free_id);

	g_slist_free_full (
		async_context->string_list,
		(GDestroyNotify) g_free);

	queue = async_context->object_queue;
	while (queue != NULL && !g_queue_is_empty (queue))
		g_object_unref (g_queue_pop_head (queue));

	queue = async_context->string_queue;
	while (queue != NULL && !g_queue_is_empty (queue))
		g_free (g_queue_pop_head (queue));

	g_slice_free (AsyncContext, async_context);
}

static void
dispatch_node_free (DispatchNode *dispatch_node)
{
	g_clear_object (&dispatch_node->simple);
	g_clear_object (&dispatch_node->cancellable);

	if (dispatch_node->custom_func_user_data_free)
		dispatch_node->custom_func_user_data_free (dispatch_node->custom_func_user_data);

	if (dispatch_node->cal_backend_weak_ref)
		e_weak_ref_free (dispatch_node->cal_backend_weak_ref);

	g_slice_free (DispatchNode, dispatch_node);
}

static void
signal_closure_free (SignalClosure *signal_closure)
{
	g_weak_ref_clear (&signal_closure->backend);

	/* The icaltimezone is cached in ECalBackend's internal
	 * "zone_cache" hash table and must not be freed here. */

	g_slice_free (SignalClosure, signal_closure);
}

static void
cal_backend_free_zone (icaltimezone *zone)
{
	icaltimezone_free (zone, 1);
}

static void
cal_backend_push_operation (ECalBackend *backend,
                            GSimpleAsyncResult *simple,
                            GCancellable *cancellable,
                            gboolean blocking_operation,
                            GSimpleAsyncThreadFunc dispatch_func)
{
	DispatchNode *node;

	g_return_if_fail (G_IS_SIMPLE_ASYNC_RESULT (simple));
	g_return_if_fail (dispatch_func != NULL);

	g_mutex_lock (&backend->priv->operation_lock);

	node = g_slice_new0 (DispatchNode);
	node->dispatch_func = dispatch_func;
	node->blocking_operation = blocking_operation;
	node->simple = g_object_ref (simple);

	if (G_IS_CANCELLABLE (cancellable))
		node->cancellable = g_object_ref (cancellable);

	g_queue_push_tail (&backend->priv->pending_operations, node);

	g_mutex_unlock (&backend->priv->operation_lock);
}

static void cal_backend_unblock_operations (ECalBackend *backend, GSimpleAsyncResult *simple);

static void
cal_backend_dispatch_thread (DispatchNode *node)
{
	GCancellable *cancellable = node->cancellable;
	GError *local_error = NULL;

	if (node->custom_func) {
		ECalBackend *cal_backend;

		cal_backend = g_weak_ref_get (node->cal_backend_weak_ref);
		if (cal_backend &&
		    !g_cancellable_is_cancelled (cancellable)) {
			node->custom_func (cal_backend, node->custom_func_user_data, cancellable, &local_error);

			if (local_error) {
				if (!g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED))
					e_cal_backend_notify_error (cal_backend, local_error->message);

				g_clear_error (&local_error);
			}
		}

		if (cal_backend) {
			cal_backend_unblock_operations (cal_backend, NULL);
			e_util_unref_in_thread (cal_backend);
		}
	} else if (g_cancellable_set_error_if_cancelled (cancellable, &local_error)) {
		g_simple_async_result_take_error (node->simple, local_error);
		g_simple_async_result_complete_in_idle (node->simple);
	} else {
		GAsyncResult *result;
		GObject *source_object;

		result = G_ASYNC_RESULT (node->simple);
		source_object = g_async_result_get_source_object (result);
		node->dispatch_func (node->simple, source_object, cancellable);
		g_object_unref (source_object);
	}

	dispatch_node_free (node);
}

static gboolean
cal_backend_dispatch_next_operation (ECalBackend *backend)
{
	DispatchNode *node;

	g_mutex_lock (&backend->priv->operation_lock);

	/* We can't dispatch additional operations
	 * while a blocking operation is in progress. */
	if (backend->priv->blocked != NULL ||
	    backend->priv->blocked_by_custom_op) {
		g_mutex_unlock (&backend->priv->operation_lock);
		return FALSE;
	}

	/* Pop the next DispatchNode off the queue. */
	node = g_queue_pop_head (&backend->priv->pending_operations);
	if (node == NULL) {
		g_mutex_unlock (&backend->priv->operation_lock);
		return FALSE;
	}

	/* If this a blocking operation, block any
	 * further dispatching until this finishes. */
	if (node->blocking_operation) {
		if (node->simple)
			backend->priv->blocked = g_object_ref (node->simple);
		else
			backend->priv->blocked_by_custom_op = TRUE;
	}

	g_mutex_unlock (&backend->priv->operation_lock);

	/* An error here merely indicates a thread could not be
	 * created, and so the node was queued.  We don't care. */
	g_thread_pool_push (backend->priv->thread_pool, node, NULL);

	return TRUE;
}

static void
cal_backend_unblock_operations (ECalBackend *backend,
                                GSimpleAsyncResult *simple)
{
	/* If the GSimpleAsyncResult was blocking the dispatch queue,
	 * unblock the dispatch queue.  Then dispatch as many waiting
	 * operations as we can. */

	g_mutex_lock (&backend->priv->operation_lock);
	if (backend->priv->blocked == simple)
		g_clear_object (&backend->priv->blocked);
	backend->priv->blocked_by_custom_op = FALSE;
	g_mutex_unlock (&backend->priv->operation_lock);

	while (cal_backend_dispatch_next_operation (backend))
		;
}

static guint32
cal_backend_stash_operation (ECalBackend *backend,
                             GSimpleAsyncResult *simple)
{
	guint32 opid;

	g_mutex_lock (&backend->priv->operation_lock);

	if (backend->priv->next_operation_id == 0)
		backend->priv->next_operation_id = 1;

	opid = backend->priv->next_operation_id++;

	g_hash_table_insert (
		backend->priv->operation_ids,
		GUINT_TO_POINTER (opid),
		g_object_ref (simple));

	g_mutex_unlock (&backend->priv->operation_lock);

	return opid;
}

static GSimpleAsyncResult *
cal_backend_claim_operation (ECalBackend *backend,
                             guint32 opid)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (opid > 0, NULL);

	g_mutex_lock (&backend->priv->operation_lock);

	simple = g_hash_table_lookup (
		backend->priv->operation_ids,
		GUINT_TO_POINTER (opid));

	if (simple != NULL) {
		/* Steal the hash table's reference. */
		g_hash_table_steal (
			backend->priv->operation_ids,
			GUINT_TO_POINTER (opid));
	}

	g_mutex_unlock (&backend->priv->operation_lock);

	return simple;
}

static void
cal_backend_set_default_cache_dir (ECalBackend *backend)
{
	ESource *source;
	icalcomponent_kind kind;
	const gchar *component_type;
	const gchar *user_cache_dir;
	const gchar *uid;
	gchar *filename;

	user_cache_dir = e_get_user_cache_dir ();

	kind = e_cal_backend_get_kind (backend);
	source = e_backend_get_source (E_BACKEND (backend));

	uid = e_source_get_uid (source);
	g_return_if_fail (uid != NULL);

	switch (kind) {
		case ICAL_VEVENT_COMPONENT:
			component_type = "calendar";
			break;
		case ICAL_VTODO_COMPONENT:
			component_type = "tasks";
			break;
		case ICAL_VJOURNAL_COMPONENT:
			component_type = "memos";
			break;
		default:
			g_return_if_reached ();
	}

	filename = g_build_filename (
		user_cache_dir, component_type, uid, NULL);
	e_cal_backend_set_cache_dir (backend, filename);
	g_free (filename);
}

static void
cal_backend_update_proxy_resolver (ECalBackend *backend)
{
	GProxyResolver *proxy_resolver = NULL;
	ESourceAuthentication *extension;
	ESource *source = NULL;
	gboolean notify = FALSE;
	gchar *uid;

	extension = e_source_get_extension (
		backend->priv->authentication_source,
		E_SOURCE_EXTENSION_AUTHENTICATION);

	uid = e_source_authentication_dup_proxy_uid (extension);
	if (uid != NULL) {
		ESourceRegistry *registry;

		registry = e_cal_backend_get_registry (backend);
		source = e_source_registry_ref_source (registry, uid);
		g_free (uid);
	}

	if (source != NULL) {
		proxy_resolver = G_PROXY_RESOLVER (source);
		if (!g_proxy_resolver_is_supported (proxy_resolver))
			proxy_resolver = NULL;
	}

	g_mutex_lock (&backend->priv->property_lock);

	/* Emitting a "notify" signal unnecessarily might have
	 * unwanted side effects like cancelling a SoupMessage.
	 * Only emit if we now have a different GProxyResolver. */

	if (proxy_resolver != backend->priv->proxy_resolver) {
		g_clear_object (&backend->priv->proxy_resolver);
		backend->priv->proxy_resolver = proxy_resolver;

		if (proxy_resolver != NULL)
			g_object_ref (proxy_resolver);

		notify = TRUE;
	}

	g_mutex_unlock (&backend->priv->property_lock);

	if (notify)
		g_object_notify (G_OBJECT (backend), "proxy-resolver");

	g_clear_object (&source);
}

static void
cal_backend_auth_source_changed_cb (ESource *authentication_source,
                                    GWeakRef *backend_weak_ref)
{
	ECalBackend *backend;

	backend = g_weak_ref_get (backend_weak_ref);

	if (backend != NULL) {
		cal_backend_update_proxy_resolver (backend);
		g_object_unref (backend);
	}
}

static gchar *
cal_backend_get_backend_property (ECalBackend *backend,
                                  const gchar *prop_name)
{
	gchar *prop_value = NULL;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);
	g_return_val_if_fail (prop_name != NULL, NULL);

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_OPENED)) {
		prop_value = g_strdup ("TRUE");

	} else if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_OPENING)) {
		prop_value = g_strdup ("FALSE");

	} else if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_REVISION)) {
		prop_value = g_strdup ("0");

	} else if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_ONLINE)) {
		gboolean online;

		online = e_backend_get_online (E_BACKEND (backend));
		prop_value = g_strdup (online ? "TRUE" : "FALSE");

	} else if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_READONLY)) {
		gboolean readonly;

		readonly = e_cal_backend_is_readonly (backend);
		prop_value = g_strdup (readonly ? "TRUE" : "FALSE");

	} else if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CACHE_DIR)) {
		prop_value = e_cal_backend_dup_cache_dir (backend);
	}

	return prop_value;
}

static gboolean
cal_backend_emit_timezone_added_idle_cb (gpointer user_data)
{
	SignalClosure *signal_closure = user_data;
	ECalBackend *backend;

	backend = g_weak_ref_get (&signal_closure->backend);

	if (backend != NULL) {
		g_signal_emit_by_name (
			backend, "timezone-added",
			signal_closure->cached_zone);
		g_object_unref (backend);
	}

	return FALSE;
}

static void
cal_backend_set_kind (ECalBackend *backend,
                      icalcomponent_kind kind)
{
	backend->priv->kind = kind;
}

static void
cal_backend_set_registry (ECalBackend *backend,
                          ESourceRegistry *registry)
{
	g_return_if_fail (E_IS_SOURCE_REGISTRY (registry));
	g_return_if_fail (backend->priv->registry == NULL);

	backend->priv->registry = g_object_ref (registry);
}

static void
cal_backend_set_property (GObject *object,
                          guint property_id,
                          const GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CACHE_DIR:
			e_cal_backend_set_cache_dir (
				E_CAL_BACKEND (object),
				g_value_get_string (value));
			return;

		case PROP_KIND:
			cal_backend_set_kind (
				E_CAL_BACKEND (object),
				g_value_get_ulong (value));
			return;

		case PROP_REGISTRY:
			cal_backend_set_registry (
				E_CAL_BACKEND (object),
				g_value_get_object (value));
			return;

		case PROP_WRITABLE:
			e_cal_backend_set_writable (
				E_CAL_BACKEND (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cal_backend_get_property (GObject *object,
                          guint property_id,
                          GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CACHE_DIR:
			g_value_take_string (
				value, e_cal_backend_dup_cache_dir (
				E_CAL_BACKEND (object)));
			return;

		case PROP_KIND:
			g_value_set_ulong (
				value, e_cal_backend_get_kind (
				E_CAL_BACKEND (object)));
			return;

		case PROP_PROXY_RESOLVER:
			g_value_take_object (
				value, e_cal_backend_ref_proxy_resolver (
				E_CAL_BACKEND (object)));
			return;

		case PROP_REGISTRY:
			g_value_set_object (
				value, e_cal_backend_get_registry (
				E_CAL_BACKEND (object)));
			return;

		case PROP_WRITABLE:
			g_value_set_boolean (
				value, e_cal_backend_get_writable (
				E_CAL_BACKEND (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
cal_backend_dispose (GObject *object)
{
	ECalBackendPrivate *priv;

	priv = E_CAL_BACKEND_GET_PRIVATE (object);

	if (priv->auth_source_changed_handler_id > 0) {
		g_signal_handler_disconnect (
			priv->authentication_source,
			priv->auth_source_changed_handler_id);
		priv->auth_source_changed_handler_id = 0;
	}

	g_clear_object (&priv->registry);
	g_clear_object (&priv->data_cal);
	g_clear_object (&priv->proxy_resolver);
	g_clear_object (&priv->authentication_source);

	g_hash_table_remove_all (priv->operation_ids);

	while (!g_queue_is_empty (&priv->pending_operations))
		g_object_unref (g_queue_pop_head (&priv->pending_operations));

	g_clear_object (&priv->blocked);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_cal_backend_parent_class)->dispose (object);
}

static void
cal_backend_finalize (GObject *object)
{
	ECalBackendPrivate *priv;

	priv = E_CAL_BACKEND_GET_PRIVATE (object);

	g_list_free (priv->views);
	g_mutex_clear (&priv->views_mutex);
	g_mutex_clear (&priv->property_lock);

	g_free (priv->cache_dir);

	g_hash_table_destroy (priv->zone_cache);
	g_mutex_clear (&priv->zone_cache_lock);

	g_mutex_clear (&priv->operation_lock);
	g_hash_table_destroy (priv->operation_ids);

	/* Return immediately, do not wait. */
	g_thread_pool_free (priv->thread_pool, TRUE, FALSE);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cal_backend_parent_class)->finalize (object);
}

static void
cal_backend_constructed (GObject *object)
{
	ECalBackend *backend;
	ECalBackendClass *klass;
	ESourceRegistry *registry;
	ESource *source;
	gint max_threads = -1;
	gboolean exclusive = FALSE;

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_cal_backend_parent_class)->constructed (object);

	backend = E_CAL_BACKEND (object);
	klass = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (klass != NULL);

	registry = e_cal_backend_get_registry (backend);
	source = e_backend_get_source (E_BACKEND (backend));

	/* If the backend specifies a serial dispatch queue, create
	 * a thread pool with one exclusive thread.  The thread pool
	 * will serialize operations for us. */
	if (klass->use_serial_dispatch_queue) {
		max_threads = 1;
		exclusive = TRUE;
	}

	/* XXX If creating an exclusive thread pool, technically there's
	 *     a small chance of error here but we'll risk it since it's
	 *     only for one exclusive thread. */
	backend->priv->thread_pool = g_thread_pool_new (
		(GFunc) cal_backend_dispatch_thread,
		NULL, max_threads, exclusive, NULL);

	/* Initialize the "cache-dir" property. */
	cal_backend_set_default_cache_dir (backend);

	/* Track the proxy resolver for this backend. */
	backend->priv->authentication_source =
		e_source_registry_find_extension (
		registry, source, E_SOURCE_EXTENSION_AUTHENTICATION);
	if (backend->priv->authentication_source != NULL) {
		gulong handler_id;

		handler_id = g_signal_connect_data (
			backend->priv->authentication_source, "changed",
			G_CALLBACK (cal_backend_auth_source_changed_cb),
			e_weak_ref_new (backend),
			(GClosureNotify) e_weak_ref_free, 0);
		backend->priv->auth_source_changed_handler_id = handler_id;

		cal_backend_update_proxy_resolver (backend);
	}
}

static void
cal_backend_prepare_shutdown (EBackend *backend)
{
	GList *list, *l;

	list = e_cal_backend_list_views (E_CAL_BACKEND (backend));

	for (l = list; l != NULL; l = g_list_next (l)) {
		EDataCalView *view = l->data;

		e_cal_backend_remove_view (E_CAL_BACKEND (backend), view);
	}

	g_list_free_full (list, g_object_unref);

	/* Chain up to parent's prepare_shutdown() method. */
	E_BACKEND_CLASS (e_cal_backend_parent_class)->prepare_shutdown (backend);
}

static void
cal_backend_shutdown (ECalBackend *backend)
{
	ESource *source;

	source = e_backend_get_source (E_BACKEND (backend));

	e_source_registry_debug_print (
		"The %s instance for \"%s\" is shutting down.\n",
		G_OBJECT_TYPE_NAME (backend),
		e_source_get_display_name (source));
}

/* Private function, not meant to be part of the public API */
void _e_cal_backend_remove_cached_timezones (ECalBackend *cal_backend);

void
_e_cal_backend_remove_cached_timezones (ECalBackend *cal_backend)
{
	g_return_if_fail (E_IS_CAL_BACKEND (cal_backend));

	g_mutex_lock (&cal_backend->priv->zone_cache_lock);
	g_hash_table_remove_all (cal_backend->priv->zone_cache);
	g_mutex_unlock (&cal_backend->priv->zone_cache_lock);
}

static void
cal_backend_add_cached_timezone (ETimezoneCache *cache,
                                 icaltimezone *zone)
{
	ECalBackendPrivate *priv;
	const gchar *tzid;

	priv = E_CAL_BACKEND_GET_PRIVATE (cache);

	/* XXX Apparently this function can sometimes return NULL.
	 *     I'm not sure when or why that happens, but we can't
	 *     cache the icaltimezone if it has no tzid string. */
	tzid = icaltimezone_get_tzid (zone);
	if (tzid == NULL)
		return;

	g_mutex_lock (&priv->zone_cache_lock);

	/* Avoid replacing an existing cache entry.  We don't want to
	 * invalidate any icaltimezone pointers that may have already
	 * been returned through e_timezone_cache_get_timezone(). */
	if (!g_hash_table_contains (priv->zone_cache, tzid)) {
		GSource *idle_source;
		GMainContext *main_context;
		SignalClosure *signal_closure;
		icalcomponent *icalcomp;
		icaltimezone *cached_zone;

		cached_zone = icaltimezone_new ();
		icalcomp = icaltimezone_get_component (zone);
		icalcomp = icalcomponent_new_clone (icalcomp);
		icaltimezone_set_component (cached_zone, icalcomp);

		g_hash_table_insert (
			priv->zone_cache,
			g_strdup (tzid), cached_zone);

		/* The closure's backend reference will keep the
		 * internally cached icaltimezone alive for the
		 * duration of the idle callback. */
		signal_closure = g_slice_new0 (SignalClosure);
		g_weak_ref_init (&signal_closure->backend, cache);
		signal_closure->cached_zone = cached_zone;

		main_context = e_backend_ref_main_context (E_BACKEND (cache));

		idle_source = g_idle_source_new ();
		g_source_set_callback (
			idle_source,
			cal_backend_emit_timezone_added_idle_cb,
			signal_closure,
			(GDestroyNotify) signal_closure_free);
		g_source_attach (idle_source, main_context);
		g_source_unref (idle_source);

		g_main_context_unref (main_context);
	}

	g_mutex_unlock (&priv->zone_cache_lock);
}

static icaltimezone *
cal_backend_get_cached_timezone (ETimezoneCache *cache,
                                 const gchar *tzid)
{
	ECalBackendPrivate *priv;
	icaltimezone *zone = NULL;
	icaltimezone *builtin_zone = NULL;
	icalcomponent *icalcomp;
	icalproperty *prop;
	const gchar *builtin_tzid;

	priv = E_CAL_BACKEND_GET_PRIVATE (cache);

	if (g_str_equal (tzid, "UTC"))
		return icaltimezone_get_utc_timezone ();

	g_mutex_lock (&priv->zone_cache_lock);

	/* See if we already have it in the cache. */
	zone = g_hash_table_lookup (priv->zone_cache, tzid);

	if (zone != NULL)
		goto exit;

	/* Try to replace the original time zone with a more complete
	 * and/or potentially updated built-in time zone.  Note this also
	 * applies to TZIDs which match built-in time zones exactly: they
	 * are extracted via icaltimezone_get_builtin_timezone_from_tzid(). */

	builtin_tzid = e_cal_match_tzid (tzid);

	if (builtin_tzid != NULL)
		builtin_zone = icaltimezone_get_builtin_timezone_from_tzid (
			builtin_tzid);

	if (builtin_zone == NULL)
		goto exit;

	/* Use the built-in time zone *and* rename it.  Likely the caller
	 * is asking for a specific TZID because it has an event with such
	 * a TZID.  Returning an icaltimezone with a different TZID would
	 * lead to broken VCALENDARs in the caller. */

	icalcomp = icaltimezone_get_component (builtin_zone);
	icalcomp = icalcomponent_new_clone (icalcomp);

	prop = icalcomponent_get_first_property (
		icalcomp, ICAL_ANY_PROPERTY);

	while (prop != NULL) {
		if (icalproperty_isa (prop) == ICAL_TZID_PROPERTY) {
			icalproperty_set_value_from_string (prop, tzid, "NO");
			break;
		}

		prop = icalcomponent_get_next_property (
			icalcomp, ICAL_ANY_PROPERTY);
	}

	if (icalcomp != NULL) {
		zone = icaltimezone_new ();
		if (icaltimezone_set_component (zone, icalcomp)) {
			tzid = icaltimezone_get_tzid (zone);
			g_hash_table_insert (
				priv->zone_cache,
				g_strdup (tzid), zone);
		} else {
			icalcomponent_free (icalcomp);
			icaltimezone_free (zone, 1);
			zone = NULL;
		}
	}

exit:
	g_mutex_unlock (&priv->zone_cache_lock);

	return zone;
}

static GList *
cal_backend_list_cached_timezones (ETimezoneCache *cache)
{
	ECalBackendPrivate *priv;
	GList *list;

	priv = E_CAL_BACKEND_GET_PRIVATE (cache);

	g_mutex_lock (&priv->zone_cache_lock);

	list = g_hash_table_get_values (priv->zone_cache);

	g_mutex_unlock (&priv->zone_cache_lock);

	return list;
}

static void
e_cal_backend_class_init (ECalBackendClass *class)
{
	GObjectClass *object_class;
	EBackendClass *backend_class;

	g_type_class_add_private (class, sizeof (ECalBackendPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = cal_backend_set_property;
	object_class->get_property = cal_backend_get_property;
	object_class->dispose = cal_backend_dispose;
	object_class->finalize = cal_backend_finalize;
	object_class->constructed = cal_backend_constructed;

	backend_class = E_BACKEND_CLASS (class);
	backend_class->prepare_shutdown = cal_backend_prepare_shutdown;

	class->use_serial_dispatch_queue = TRUE;
	class->get_backend_property = cal_backend_get_backend_property;
	class->shutdown = cal_backend_shutdown;

	g_object_class_install_property (
		object_class,
		PROP_CACHE_DIR,
		g_param_spec_string (
			"cache-dir",
			"Cache Dir",
			"The backend's cache directory",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_KIND,
		g_param_spec_ulong (
			"kind",
			"Kind",
			"The kind of iCalendar components "
			"this backend manages",
			ICAL_NO_COMPONENT,
			ICAL_XLICMIMEPART_COMPONENT,
			ICAL_NO_COMPONENT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (
		object_class,
		PROP_PROXY_RESOLVER,
		g_param_spec_object (
			"proxy-resolver",
			"Proxy Resolver",
			"The proxy resolver for this backend",
			G_TYPE_PROXY_RESOLVER,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

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

	g_object_class_install_property (
		object_class,
		PROP_WRITABLE,
		g_param_spec_boolean (
			"writable",
			"Writable",
			"Whether the backend will accept changes",
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ECalBackend::closed:
	 * @backend: the #ECalBackend which emitted the signal
	 * @sender: the bus name that invoked the "close" method
	 *
	 * Emitted when a client destroys its #ECalClient for @backend
	 *
	 * Since: 3.10
	 **/
	signals[CLOSED] = g_signal_new (
		"closed",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECalBackendClass, closed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 1,
		G_TYPE_STRING);

	/**
	 * ECalBackend::shutdown:
	 * @backend: the #ECalBackend which emitted the signal
	 *
	 * Emitted when the last client destroys its #ECalClient for
	 * @backend.  This signals the @backend to begin final cleanup
	 * tasks such as synchronizing data to permanent storage.
	 *
	 * Since: 3.10
	 **/
	signals[SHUTDOWN] = g_signal_new (
		"shutdown",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (ECalBackendClass, shutdown),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);
}

static void
e_cal_backend_timezone_cache_init (ETimezoneCacheInterface *iface)
{
	iface->add_timezone = cal_backend_add_cached_timezone;
	iface->get_timezone = cal_backend_get_cached_timezone;
	iface->list_timezones = cal_backend_list_cached_timezones;
}

static void
e_cal_backend_init (ECalBackend *backend)
{
	GHashTable *zone_cache;

	zone_cache = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) cal_backend_free_zone);

	backend->priv = E_CAL_BACKEND_GET_PRIVATE (backend);

	g_mutex_init (&backend->priv->views_mutex);
	g_mutex_init (&backend->priv->property_lock);

	backend->priv->zone_cache = zone_cache;
	g_mutex_init (&backend->priv->zone_cache_lock);

	g_mutex_init (&backend->priv->operation_lock);

	backend->priv->operation_ids = g_hash_table_new_full (
		(GHashFunc) g_direct_hash,
		(GEqualFunc) g_direct_equal,
		(GDestroyNotify) NULL,
		(GDestroyNotify) g_object_unref);
}

/**
 * e_cal_backend_get_kind:
 * @backend: an #ECalBackend
 *
 * Gets the kind of components the given backend stores.
 *
 * Returns: The kind of components for this backend.
 */
icalcomponent_kind
e_cal_backend_get_kind (ECalBackend *backend)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), ICAL_NO_COMPONENT);

	return backend->priv->kind;
}

/**
 * e_cal_backend_ref_data_cal:
 * @backend: an #ECalBackend
 *
 * Returns the #EDataCal for @backend.  The #EDataCal is essentially
 * the glue between incoming D-Bus requests and @backend's native API.
 *
 * An #EDataCal should be set only once after @backend is first created.
 * If an #EDataCal has not yet been set, the function returns %NULL.
 *
 * The returned #EDataCal is referenced for thread-safety and must be
 * unreferenced with g_object_unref() when finished with it.
 *
 * Returns: an #EDataCal, or %NULL
 *
 * Since: 3.10
 **/
EDataCal *
e_cal_backend_ref_data_cal (ECalBackend *backend)
{
	EDataCal *data_cal = NULL;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);

	if (backend->priv->data_cal != NULL)
		data_cal = g_object_ref (backend->priv->data_cal);

	return data_cal;
}

/**
 * e_cal_backend_set_data_cal:
 * @backend: an #ECalBackend
 * @data_cal: an #EDataCal
 *
 * Sets the #EDataCal for @backend.  The #EDataCal is essentially the
 * glue between incoming D-Bus requests and @backend's native API.
 *
 * An #EDataCal should be set only once after @backend is first created.
 *
 * Since: 3.10
 **/
void
e_cal_backend_set_data_cal (ECalBackend *backend,
                            EDataCal *data_cal)
{
	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (E_IS_DATA_CAL (data_cal));

	/* This should be set only once.  Warn if not. */
	g_warn_if_fail (backend->priv->data_cal == NULL);

	backend->priv->data_cal = g_object_ref (data_cal);
}

/**
 * e_cal_backend_ref_proxy_resolver:
 * @backend: an #ECalBackend
 *
 * Returns the #GProxyResolver for @backend (if applicable), as indicated
 * by the #ESourceAuthentication:proxy-uid of @backend's #EBackend:source
 * or one of its ancestors.
 *
 * The returned #GProxyResolver is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #GProxyResolver, or %NULL
 *
 * Since: 3.12
 **/
GProxyResolver *
e_cal_backend_ref_proxy_resolver (ECalBackend *backend)
{
	GProxyResolver *proxy_resolver = NULL;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);

	g_mutex_lock (&backend->priv->property_lock);

	if (backend->priv->proxy_resolver != NULL)
		proxy_resolver = g_object_ref (backend->priv->proxy_resolver);

	g_mutex_unlock (&backend->priv->property_lock);

	return proxy_resolver;
}

/**
 * e_cal_backend_get_registry:
 * @backend: an #ECalBackend
 *
 * Returns the data source registry to which #EBackend:source belongs.
 *
 * Returns: an #ESourceRegistry
 *
 * Since: 3.6
 **/
ESourceRegistry *
e_cal_backend_get_registry (ECalBackend *backend)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);

	return backend->priv->registry;
}

/**
 * e_cal_backend_get_writable:
 * @backend: an #ECalBackend
 *
 * Returns whether @backend will accept changes to its data content.
 *
 * Returns: whether @backend is writable
 *
 * Since: 3.8
 **/
gboolean
e_cal_backend_get_writable (ECalBackend *backend)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);

	return backend->priv->writable;
}

/**
 * e_cal_backend_set_writable:
 * @backend: an #ECalBackend
 * @writable: whether @backend is writable
 *
 * Sets whether @backend will accept changes to its data content.
 *
 * Since: 3.8
 **/
void
e_cal_backend_set_writable (ECalBackend *backend,
                            gboolean writable)
{
	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	if (writable == backend->priv->writable)
		return;

	backend->priv->writable = writable;

	g_object_notify (G_OBJECT (backend), "writable");
}

/**
 * e_cal_backend_is_opened:
 * @backend: an #ECalBackend
 *
 * Checks if @backend's storage has been opened (and
 * authenticated, if necessary) and the backend itself
 * is ready for accessing. This property is changed automatically
 * after the @backend is successfully opened.
 *
 * Returns: %TRUE if fully opened, %FALSE otherwise.
 *
 * Since: 3.2
 **/
gboolean
e_cal_backend_is_opened (ECalBackend *backend)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);

	return backend->priv->opened;
}

/**
 * e_cal_backend_is_readonly:
 * @backend: an #ECalBackend
 *
 * Returns: Whether is backend read-only.
 *
 * Since: 3.2
 **/
gboolean
e_cal_backend_is_readonly (ECalBackend *backend)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);

	return !e_cal_backend_get_writable (backend);
}

/**
 * e_cal_backend_get_cache_dir:
 * @backend: an #ECalBackend
 *
 * Returns the cache directory path used by @backend.
 *
 * Returns: the cache directory path
 *
 * Since: 2.32
 **/
const gchar *
e_cal_backend_get_cache_dir (ECalBackend *backend)
{
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);

	return backend->priv->cache_dir;
}

/**
 * e_cal_backend_dup_cache_dir:
 * @backend: an #ECalBackend
 *
 * Thread-safe variation of e_cal_backend_get_cache_dir().
 * Use this function when accessing @backend from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated copy of #ECalBackend:cache-dir
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_dup_cache_dir (ECalBackend *backend)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);

	g_mutex_lock (&backend->priv->property_lock);

	protected = e_cal_backend_get_cache_dir (backend);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&backend->priv->property_lock);

	return duplicate;
}

/**
 * e_cal_backend_set_cache_dir:
 * @backend: an #ECalBackend
 * @cache_dir: a local cache directory path
 *
 * Sets the cache directory path for use by @backend.
 *
 * Note that #ECalBackend is initialized with a default cache directory
 * path which should suffice for most cases.  Backends should not override
 * the default path without good reason.
 *
 * Since: 2.32
 **/
void
e_cal_backend_set_cache_dir (ECalBackend *backend,
                             const gchar *cache_dir)
{
	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (cache_dir != NULL);

	g_mutex_lock (&backend->priv->property_lock);

	if (g_strcmp0 (backend->priv->cache_dir, cache_dir) == 0) {
		g_mutex_unlock (&backend->priv->property_lock);
		return;
	}

	g_free (backend->priv->cache_dir);
	backend->priv->cache_dir = g_strdup (cache_dir);

	g_mutex_unlock (&backend->priv->property_lock);

	g_object_notify (G_OBJECT (backend), "cache-dir");
}

/**
 * e_cal_backend_create_cache_filename:
 * @backend: an #ECalBackend
 * @uid: a component UID
 * @filename: a filename to use; can be NULL
 * @fileindex: index of a file; used only when @filename is NULL
 *
 * Returns: a filename for an attachment in a local cache dir. Free returned
 * pointer with a g_free().
 *
 * Since: 3.4
 **/
gchar *
e_cal_backend_create_cache_filename (ECalBackend *backend,
                                     const gchar *uid,
                                     const gchar *filename,
                                     gint fileindex)
{
	const gchar *cache_dir;

	g_return_val_if_fail (backend != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);

	cache_dir = e_cal_backend_get_cache_dir (backend);

	return e_filename_mkdir_encoded (cache_dir, uid, filename, fileindex);
}

/**
 * e_cal_backend_get_backend_property:
 * @backend: an #ECalBackend
 * @prop_name: a backend property name
 *
 * Obtains the value of the backend property named @prop_name.
 * Freed the returned string with g_free() when finished with it.
 *
 * Returns: the value for @prop_name
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_get_backend_property (ECalBackend *backend,
                                    const gchar *prop_name)
{
	ECalBackendClass *class;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);
	g_return_val_if_fail (prop_name != NULL, NULL);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_val_if_fail (class != NULL, NULL);
	g_return_val_if_fail (class->get_backend_property != NULL, NULL);

	return class->get_backend_property (backend, prop_name);
}

/**
 * e_cal_backend_add_view:
 * @backend: an #ECalBackend
 * @view: An #EDataCalView object.
 *
 * Adds a view to the list of live views being run by the given backend.
 * Doing so means that any listener on the view will get notified of any
 * change that affect the live view.
 *
 * Since: 3.2
 */
void
e_cal_backend_add_view (ECalBackend *backend,
                        EDataCalView *view)
{
	g_return_if_fail (backend != NULL);
	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	g_mutex_lock (&backend->priv->views_mutex);

	g_object_ref (view);
	backend->priv->views = g_list_append (backend->priv->views, view);

	g_mutex_unlock (&backend->priv->views_mutex);
}

/**
 * e_cal_backend_remove_view
 * @backend: an #ECalBackend
 * @view: An #EDataCalView object, previously added with @ref e_cal_backend_add_view.
 *
 * Removes view from the list of live views for the backend.
 *
 * Since: 3.2
 **/
void
e_cal_backend_remove_view (ECalBackend *backend,
                           EDataCalView *view)
{
	GList *list, *link;

	g_return_if_fail (backend != NULL);
	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	/* In case the view holds the last reference to backend */
	g_object_ref (backend);

	g_mutex_lock (&backend->priv->views_mutex);

	list = backend->priv->views;

	link = g_list_find (list, view);
	if (link != NULL) {
		g_object_unref (view);
		list = g_list_delete_link (list, link);
	}

	backend->priv->views = list;

	g_mutex_unlock (&backend->priv->views_mutex);

	g_object_unref (backend);
}

/**
 * e_cal_backend_list_views:
 * @backend: an #ECalBackend
 *
 * Returns a list of #EDataCalView instances added with
 * e_cal_backend_add_view().
 *
 * The views returned in the list are referenced for thread-safety.
 * They must each be unreferenced with g_object_unref() when finished
 * with them.  Free the returned list itself with g_list_free().
 *
 * An easy way to free the list properly in one step is as follows:
 *
 * |[
 *   g_list_free_full (list, g_object_unref);
 * ]|
 *
 * Returns: (element-type EDataCalView): a list of cal views
 *
 * Since: 3.8
 **/
GList *
e_cal_backend_list_views (ECalBackend *backend)
{
	GList *list;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);

	g_mutex_lock (&backend->priv->views_mutex);

	/* XXX Use g_list_copy_deep() once we require GLib >= 2.34. */
	list = g_list_copy (backend->priv->views);
	g_list_foreach (list, (GFunc) g_object_ref, NULL);

	g_mutex_unlock (&backend->priv->views_mutex);

	return list;
}

/**
 * e_cal_backend_open_sync:
 * @backend: an #ECalBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * "Opens" the @backend.  Opening a backend is something of an outdated
 * concept, but the operation is hanging around for a little while longer.
 * This usually involves some custom initialization logic, and testing of
 * remote authentication if applicable.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_open_sync (ECalBackend *backend,
                         GCancellable *cancellable,
                         GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_open (
		backend, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_open_finish (backend, result, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_open() */
static void
cal_backend_open_thread (GSimpleAsyncResult *simple,
                         GObject *source_object,
                         GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->open != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	if (e_cal_backend_is_opened (backend)) {
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		e_backend_ensure_online_state_updated (E_BACKEND (backend), cancellable);

		class->open (backend, data_cal, opid, cancellable, FALSE);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_open:
 * @backend: an #ECalBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously "opens" the @backend.  Opening a backend is something of
 * an outdated concept, but the operation is hanging around for a little
 * while longer.  This usually involves some custom initialization logic,
 * and testing of remote authentication if applicable.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_backend_open_finish() to get the result of the operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_open (ECalBackend *backend,
                    GCancellable *cancellable,
                    GAsyncReadyCallback callback,
                    gpointer user_data)
{
	GSimpleAsyncResult *simple;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback,
		user_data, e_cal_backend_open);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	cal_backend_push_operation (
		backend, simple, cancellable, TRUE,
		cal_backend_open_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_open_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_open().
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_open_finish (ECalBackend *backend,
                           GAsyncResult *result,
                           GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_open), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	backend->priv->opened = TRUE;

	return TRUE;
}

/**
 * e_cal_backend_refresh_sync:
 * @backend: an #ECalBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Initiates a refresh for @backend, if the @backend supports refreshing.
 * The actual refresh operation completes on its own time.  This function
 * merely initiates the operation.
 *
 * If an error occrs while initiating the refresh, the function will set
 * @error and return %FALSE.  If the @backend does not support refreshing,
 * the function will set an %E_CLIENT_ERROR_NOT_SUPPORTED error and return
 * %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_refresh_sync (ECalBackend *backend,
                            GCancellable *cancellable,
                            GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_refresh (
		backend, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_refresh_finish (backend, result, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_refresh() */
static void
cal_backend_refresh_thread (GSimpleAsyncResult *simple,
                            GObject *source_object,
                            GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	if (class->refresh == NULL) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_SUPPORTED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_SUPPORTED));
		g_simple_async_result_complete_in_idle (simple);

	} else if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->refresh (backend, data_cal, opid, cancellable);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_refresh:
 * @backend: an #ECalBackend
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously initiates a refresh for @backend, if the @backend supports
 * refreshing.  The actual refresh operation completes on its own time.  This
 * function, along with e_cal_backend_refresh_finish(), merely initiates the
 * operation.
 *
 * Once the refresh is initiated, @callback will be called.  You can then
 * call e_cal_backend_refresh_finish() to get the result of the initiation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_refresh (ECalBackend *backend,
                       GCancellable *cancellable,
                       GAsyncReadyCallback callback,
                       gpointer user_data)
{
	GSimpleAsyncResult *simple;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback,
		user_data, e_cal_backend_refresh);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_refresh_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_refresh_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the refresh initiation started with e_cal_backend_refresh().
 *
 * If an error occurred while initiating the refresh, the function will set
 * @error and return %FALSE.  If the @backend does not support refreshing,
 * the function will set an %E_CLIENT_ERROR_NOT_SUPPORTED error and return
 * %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_refresh_finish (ECalBackend *backend,
                              GAsyncResult *result,
                              GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_refresh), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	cal_backend_unblock_operations (backend, simple);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_backend_get_object_sync:
 * @backend: an #ECalBackend
 * @uid: a unique ID for an iCalendar object
 * @rid: a recurrence ID, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Obtains an iCalendar string for an object identified by its @uid and,
 * optionally, @rid.
 *
 * The returned string should be freed with g_free() when finished with it.
 *
 * If an error occurs, the function will set @error and return %NULL.
 *
 * Returns: an #ECalComponent, or %NULL
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_get_object_sync (ECalBackend *backend,
                               const gchar *uid,
                               const gchar *rid,
                               GCancellable *cancellable,
                               GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gchar *calobj;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);
	g_return_val_if_fail (uid != NULL, NULL);
	/* rid can be NULL */

	closure = e_async_closure_new ();

	e_cal_backend_get_object (
		backend, uid, rid, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	calobj = e_cal_backend_get_object_finish (backend, result, error);

	e_async_closure_free (closure);

	return calobj;
}

/* Helper for e_cal_backend_get_object() */
static void
cal_backend_get_object_thread (GSimpleAsyncResult *simple,
                               GObject *source_object,
                               GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->get_object != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->get_object (
			backend, data_cal, opid, cancellable,
			async_context->uid,
			async_context->rid);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_get_object:
 * @backend: an #ECalBackend
 * @uid: a unique ID for an iCalendar object
 * @rid: a recurrence ID, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously obtains an #ECalComponent by its @uid and, optionally, @rid.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_backend_get_object_finish() to get the result of the operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_get_object (ECalBackend *backend,
                          const gchar *uid,
                          const gchar *rid,
                          GCancellable *cancellable,
                          GAsyncReadyCallback callback,
                          gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (uid != NULL);
	/* rid can be NULL */

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);
	async_context->rid = g_strdup (rid);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_get_object);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_get_object_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_get_object_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_get_object().
 *
 * The returned string is an iCalendar object describing either single component
 * or a vCalendar object, which includes also detached instances. It should be
 * freed when no longer needed.
 *
 * If an error occurs, the function will set @error and return %NULL.
 *
 * Returns: an #ECalComponent, or %NULL
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_get_object_finish (ECalBackend *backend,
                                 GAsyncResult *result,
                                 GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	gchar *calobj;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_get_object), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	calobj = g_queue_pop_head (&async_context->result_queue);

	g_warn_if_fail (g_queue_is_empty (&async_context->result_queue));

	return calobj;
}

/**
 * e_cal_backend_get_object_list_sync:
 * @backend: an #ECalBackend
 * @query: a search query in S-expression format
 * @out_objects: a #GQueue in which to deposit results
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Obtains a set of iCalendar string instances which satisfy the criteria
 * specified in @query, and deposits them in @out_objects.
 *
 * The returned instances should be freed with g_free() when finished with them.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 * Note that an empty result set does not necessarily imply an error.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_get_object_list_sync (ECalBackend *backend,
                                    const gchar *query,
                                    GQueue *out_objects,
                                    GCancellable *cancellable,
                                    GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (query != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_get_object_list (
		backend, query, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_get_object_list_finish (
		backend, result, out_objects, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_get_object_list() */
static void
cal_backend_get_object_list_thread (GSimpleAsyncResult *simple,
                                    GObject *source_object,
                                    GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->get_object_list != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->get_object_list (
			backend, data_cal, opid, cancellable,
			async_context->query);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_get_object_list:
 * @backend: an #ECalBackend
 * @query: a search query in S-expression format
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously obtains a set of iCalendar instances which satisfy
 * the criteria specified in @query.
 *
 * When the operation in finished, @callback will be called.  You can then
 * call e_cal_backend_get_object_list_finish() to get the result of the
 * operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_get_object_list (ECalBackend *backend,
                               const gchar *query,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (query != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->query = g_strdup (query);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_get_object_list);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_get_object_list_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_get_object_list_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @out_objects: a #GQueue in which to deposit results
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_get_object_list().
 *
 * The matching iCalendar instances are deposited in @out_objects.
 * The returned instances should be freed with g_free() when finished with them.
 *
 * If an error occurred, the function will set @error and return %FALSE.
 * Note that an empty result set does not necessarily imply an error.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_get_object_list_finish (ECalBackend *backend,
                                      GAsyncResult *result,
                                      GQueue *out_objects,
                                      GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_get_object_list), FALSE);
	g_return_val_if_fail (out_objects != NULL, FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	e_queue_transfer (&async_context->result_queue, out_objects);

	return TRUE;
}

/**
 * e_cal_backend_get_free_busy_sync:
 * @backend: an #ECalBackend
 * @start: start time
 * @end: end time
 * @users: a %NULL-terminated array of user strings
 * @out_freebusy: iCalendar strings with overall returned Free/Busy data
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Obtains a free/busy object for the list of @users in the time interval
 * between @start and @end.
 *
 * The free/busy results can be returned through the
 * e_data_cal_report_free_busy_data() function asynchronously. The out_freebusy
 * will contain all the returned data, possibly again, thus the client is
 * responsible for the data merge, if needed.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure.
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_get_free_busy_sync (ECalBackend *backend,
                                  time_t start,
                                  time_t end,
                                  const gchar * const *users,
				  GSList **out_freebusy,
                                  GCancellable *cancellable,
                                  GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (users != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_get_free_busy (
		backend, start, end, users, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_get_free_busy_finish (
		backend, result, out_freebusy, error);

	e_async_closure_free (closure);

	return success;
}

static void
cal_backend_get_free_busy_thread (GSimpleAsyncResult *simple,
                                  GObject *source_object,
                                  GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->get_free_busy != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->get_free_busy (
			backend, data_cal, opid, cancellable,
			async_context->string_list,
			async_context->start,
			async_context->end);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_get_free_busy:
 * @backend: an #ECalBackend
 * @start: start time
 * @end: end time
 * @users: a %NULL-terminated array of user strings
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously obtains a free/busy object for the list of @users in the
 * time interval between @start and @end.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call e_cal_backend_get_free_busy_finish() to get the result of
 * the operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_get_free_busy (ECalBackend *backend,
                             time_t start,
                             time_t end,
                             const gchar * const *users,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	GSList *list = NULL;
	gint ii;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (start != -1 && end != -1);
	g_return_if_fail (start <= end);
	g_return_if_fail (users != NULL);

	for (ii = 0; users[ii] != NULL; ii++)
		list = g_slist_prepend (list, g_strdup (users[ii]));

	async_context = g_slice_new0 (AsyncContext);
	async_context->start = start;
	async_context->end = end;
	async_context->string_list = g_slist_reverse (list);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_get_free_busy);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_get_free_busy_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_get_free_busy_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @out_freebusy: iCalendar strings with overall returned Free/Busy data
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_get_free_busy().
 *
 * The free/busy results can be returned through the
 * e_data_cal_report_free_busy_data() function asynchronously. The out_freebusy
 * will contain all the returned data, possibly again, thus the client is
 * responsible for the data merge, if needed.
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_get_free_busy_finish (ECalBackend *backend,
                                    GAsyncResult *result,
				    GSList **out_freebusy,
                                    GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	GSList *ical_strings = NULL;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_get_free_busy), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	/* Assume success unless a GError is set. */
	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	while (!g_queue_is_empty (&async_context->result_queue)) {
		gchar *ical_freebusy;

		ical_freebusy = g_queue_pop_head (&async_context->result_queue);
		if (out_freebusy)
			ical_strings = g_slist_prepend (ical_strings, ical_freebusy);
		else
			g_free (ical_freebusy);
	}

	if (out_freebusy)
		*out_freebusy = g_slist_reverse (ical_strings);

	return TRUE;
}

/**
 * e_cal_backend_create_objects_sync:
 * @backend: an #ECalBackend
 * @calobjs: a %NULL-terminated array of iCalendar strings
 * @out_uids: a #GQueue in which to deposit results
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Creates one or more new iCalendar objects from @calobjs, and deposits
 * the unique ID string for each newly-created object in @out_uids.
 *
 * Free the returned ID strings with g_free() when finished with them.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_create_objects_sync (ECalBackend *backend,
                                   const gchar * const *calobjs,
                                   GQueue *out_uids,
                                   GCancellable *cancellable,
                                   GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (calobjs != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_create_objects (
		backend, calobjs, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_create_objects_finish (
		backend, result, out_uids, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_create_objects() */
static void
cal_backend_create_objects_thread (GSimpleAsyncResult *simple,
                                   GObject *source_object,
                                   GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (class->create_objects == NULL) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_SUPPORTED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_SUPPORTED));
		g_simple_async_result_complete_in_idle (simple);

	} else if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->create_objects (
			backend, data_cal, opid, cancellable,
			async_context->string_list);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_create_objects:
 * @backend: an #ECalBackend
 * @calobjs: a %NULL-terminated array of iCalendar strings
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisifed
 * @user_data: data to pass to the callback function
 *
 * Asynchronously creates one or more new iCalendar objects from @calobjs.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_backend_create_objects_finish() to get the result of the
 * operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_create_objects (ECalBackend *backend,
                              const gchar * const *calobjs,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	GSList *list = NULL;
	gint ii;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (calobjs != NULL);

	for (ii = 0; calobjs[ii] != NULL; ii++)
		list = g_slist_prepend (list, g_strdup (calobjs[ii]));

	async_context = g_slice_new0 (AsyncContext);
	async_context->string_list = g_slist_reverse (list);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_create_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_create_objects_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_create_objects_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @out_uids: a #GQueue in which to deposit results
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_create_objects().
 *
 * A unique ID string for each newly-created object is deposited in @out_uids.
 * Free the returned ID strings with g_free() when finished with them.
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_create_objects_finish (ECalBackend *backend,
                                     GAsyncResult *result,
                                     GQueue *out_uids,
                                     GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	GQueue *string_queue;
	GQueue *component_queue;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_create_objects), FALSE);
	g_return_val_if_fail (out_uids != NULL, FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	/* XXX Packing GQueues in a GQueue is pretty awkward, but until
	 *     the backend methods can be updated I'm trying to make do
	 *     with a single data container for all kinds of results. */

	string_queue = g_queue_pop_head (&async_context->result_queue);
	component_queue = g_queue_pop_head (&async_context->result_queue);

	g_warn_if_fail (g_queue_is_empty (&async_context->result_queue));

	g_return_val_if_fail (string_queue != NULL, FALSE);
	g_return_val_if_fail (component_queue != NULL, FALSE);

	e_queue_transfer (string_queue, out_uids);

	while (!g_queue_is_empty (component_queue)) {
		ECalComponent *component;

		component = g_queue_pop_head (component_queue);
		e_cal_backend_notify_component_created (backend, component);
		g_object_unref (component);
	}

	g_queue_free (string_queue);
	g_queue_free (component_queue);

	return TRUE;
}

/**
 * e_cal_backend_modify_objects:
 * @backend: an #ECalBackend
 * @calobjs: a %NULL-terminated array of iCalendar strings
 * @mod: modification type for recurrences
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Modifies one or more iCalendar objects according to @calobjs and @mod.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_modify_objects_sync (ECalBackend *backend,
                                   const gchar * const *calobjs,
                                   ECalObjModType mod,
                                   GCancellable *cancellable,
                                   GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (calobjs != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_modify_objects (
		backend, calobjs, mod, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_modify_objects_finish (
		backend, result, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_modify_objects() */
static void
cal_backend_modify_objects_thread (GSimpleAsyncResult *simple,
                                   GObject *source_object,
                                   GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (class->modify_objects == NULL) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_SUPPORTED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_SUPPORTED));
		g_simple_async_result_complete_in_idle (simple);

	} else if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->modify_objects (
			backend, data_cal, opid, cancellable,
			async_context->string_list,
			async_context->mod);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_modify_objects:
 * @backend: an #ECalBackend
 * @calobjs: a %NULL-terminated array of iCalendar strings
 * @mod: modification type for recurrences
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously modifies one or more iCalendar objects according to
 * @calobjs and @mod.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_backend_modify_objects_finish() to get the result of the
 * operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_modify_objects (ECalBackend *backend,
                              const gchar * const *calobjs,
                              ECalObjModType mod,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	GSList *list = NULL;
	gint ii;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (calobjs != NULL);

	for (ii = 0; calobjs[ii] != NULL; ii++)
		list = g_slist_prepend (list, g_strdup (calobjs[ii]));

	async_context = g_slice_new0 (AsyncContext);
	async_context->string_list = g_slist_reverse (list);
	async_context->mod = mod;

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_modify_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_modify_objects_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_modify_objects_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_modify_objects().
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_modify_objects_finish (ECalBackend *backend,
                                     GAsyncResult *result,
                                     GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	GQueue *old_component_queue;
	GQueue *new_component_queue;
	guint length, ii;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_modify_objects), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	/* XXX Packing GQueues in a GQueue is pretty awkward, but until
	 *     the backend methods can be updated I'm trying to make do
	 *     with a single data container for all kinds of results. */

	old_component_queue = g_queue_pop_head (&async_context->result_queue);
	new_component_queue = g_queue_pop_head (&async_context->result_queue);

	g_warn_if_fail (g_queue_is_empty (&async_context->result_queue));

	g_return_val_if_fail (old_component_queue != NULL, FALSE);
	g_return_val_if_fail (new_component_queue != NULL, FALSE);

	length = MIN (
		g_queue_get_length (old_component_queue),
		g_queue_get_length (new_component_queue));

	for (ii = 0; ii < length; ii++) {
		ECalComponent *old_component;
		ECalComponent *new_component;

		old_component = g_queue_pop_head (old_component_queue);
		new_component = g_queue_pop_head (new_component_queue);

		e_cal_backend_notify_component_modified (
			backend, old_component, new_component);

		g_clear_object (&old_component);
		g_clear_object (&new_component);
	}

	g_warn_if_fail (g_queue_is_empty (old_component_queue));
	g_queue_free (old_component_queue);

	g_warn_if_fail (g_queue_is_empty (new_component_queue));
	g_queue_free (new_component_queue);

	return TRUE;
}

/**
 * e_cal_backend_remove_objects_sync:
 * @backend: an #ECalBackend
 * @component_ids: a #GList of #ECalComponentId structs
 * @mod: modification type for recurrences
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Removes one or more iCalendar objects according to @component_ids and @mod.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_remove_objects_sync (ECalBackend *backend,
                                   GList *component_ids,
                                   ECalObjModType mod,
                                   GCancellable *cancellable,
                                   GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (component_ids != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_remove_objects (
		backend, component_ids, mod, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_remove_objects_finish (
		backend, result, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_remove_objects() */
static void
cal_backend_remove_objects_thread (GSimpleAsyncResult *simple,
                                   GObject *source_object,
                                   GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->remove_objects != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->remove_objects (
			backend, data_cal, opid, cancellable,
			async_context->compid_list,
			async_context->mod);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_remove_objects:
 * @backend: an #ECalBackend
 * @component_ids: a #GList of #ECalComponentId structs
 * @mod: modification type for recurrences
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously removes one or more iCalendar objects according to
 * @component_ids and @mod.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_backend_remove_objects_finish() to get the result of the
 * operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_remove_objects (ECalBackend *backend,
                              GList *component_ids,
                              ECalObjModType mod,
                              GCancellable *cancellable,
                              GAsyncReadyCallback callback,
                              gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	GSList *list = NULL;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (component_ids != NULL);

	while (component_ids != NULL) {
		ECalComponentId *id = component_ids->data;
		list = g_slist_prepend (list, e_cal_component_id_copy (id));
		component_ids = g_list_next (component_ids);
	}

	async_context = g_slice_new0 (AsyncContext);
	async_context->compid_list = g_slist_reverse (list);
	async_context->mod = mod;

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_remove_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_remove_objects_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_remove_objects_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_remove_objects().
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_remove_objects_finish (ECalBackend *backend,
                                     GAsyncResult *result,
                                     GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	GQueue *component_id_queue;
	GQueue *old_component_queue;
	GQueue *new_component_queue;
	guint length, ii;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_remove_objects), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	/* XXX Packing GQueues in a GQueue is pretty awkward, but until
	 *     the backend methods can be updated I'm trying to make do
	 *     with a single data container for all kinds of results. */

	component_id_queue = g_queue_pop_head (&async_context->result_queue);
	old_component_queue = g_queue_pop_head (&async_context->result_queue);
	new_component_queue = g_queue_pop_head (&async_context->result_queue);

	g_warn_if_fail (g_queue_is_empty (&async_context->result_queue));

	g_return_val_if_fail (component_id_queue != NULL, FALSE);
	g_return_val_if_fail (old_component_queue != NULL, FALSE);
	/* new_component_queue may be NULL */

	length = MIN (
		g_queue_get_length (component_id_queue),
		g_queue_get_length (old_component_queue));

	for (ii = 0; ii < length; ii++) {
		ECalComponentId *component_id;
		ECalComponent *old_component;
		ECalComponent *new_component = NULL;

		component_id = g_queue_pop_head (component_id_queue);
		old_component = g_queue_pop_head (old_component_queue);
		if (new_component_queue != NULL)
			new_component = g_queue_pop_head (new_component_queue);

		e_cal_backend_notify_component_removed (
			backend, component_id, old_component, new_component);

		e_cal_component_free_id (component_id);
		g_clear_object (&old_component);
		g_clear_object (&new_component);
	}

	g_warn_if_fail (g_queue_is_empty (component_id_queue));
	g_queue_free (component_id_queue);

	g_warn_if_fail (g_queue_is_empty (old_component_queue));
	g_queue_free (old_component_queue);

	if (new_component_queue != NULL) {
		g_warn_if_fail (g_queue_is_empty (new_component_queue));
		g_queue_free (new_component_queue);
	}

	return TRUE;
}

/**
 * e_cal_backend_receive_objects_sync:
 * @backend: an #ECalBackend
 * @calobj: an iCalendar string
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Receives the set of iCalendar objects specified by @calobj.  This is used
 * for iTIP confirmation and cancellation messages for scheduled meetings.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_receive_objects_sync (ECalBackend *backend,
                                    const gchar *calobj,
                                    GCancellable *cancellable,
                                    GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (calobj != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_receive_objects (
		backend, calobj, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_receive_objects_finish (
		backend, result, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_receive_objects() */
static void
cal_backend_receive_objects_thread (GSimpleAsyncResult *simple,
                                    GObject *source_object,
                                    GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->receive_objects != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->receive_objects (
			backend, data_cal, opid, cancellable,
			async_context->calobj);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_receive_objects:
 * @backend: an #ECalBackend
 * @calobj: an iCalendar string
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously receives the set of iCalendar objects specified by
 * @calobj.  This is used for iTIP confirmation and cancellation messages
 * for scheduled meetings.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_backend_receive_objects_finish() to get the result of the
 * operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_receive_objects (ECalBackend *backend,
                               const gchar *calobj,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (calobj != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->calobj = g_strdup (calobj);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_receive_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_receive_objects_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_receive_objects_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_receive_objects().
 *
 * If an error occurred, the function will set @error and erturn %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_receive_objects_finish (ECalBackend *backend,
                                      GAsyncResult *result,
                                      GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_receive_objects), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	cal_backend_unblock_operations (backend, simple);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_backend_send_objects_sync:
 * @backend: an #ECalBackend
 * @calobj: an iCalendar string
 * @out_users: a #GQueue in which to deposit results
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Sends meeting information in @calobj.  The @backend may modify @calobj
 * and send meeting information only to particular users.  The function
 * returns the (maybe) modified @calobj and deposits the list of users the
 * meeting information was sent (to be send) to in @out_users.
 *
 * The returned pointer should be freed with g_free(), when no londer needed.
 *
 * If an error occurs, the function will set @error and return %NULL.
 *
 * Returns: a vCalendar string, or %NULL
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_send_objects_sync (ECalBackend *backend,
                                 const gchar *calobj,
                                 GQueue *out_users,
                                 GCancellable *cancellable,
                                 GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gchar *out_calobj;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);
	g_return_val_if_fail (calobj != NULL, NULL);

	closure = e_async_closure_new ();

	e_cal_backend_send_objects (
		backend, calobj, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	out_calobj = e_cal_backend_send_objects_finish (
		backend, result, out_users, error);

	e_async_closure_free (closure);

	return out_calobj;
}

/* Helper for e_cal_backend_send_objects() */
static void
cal_backend_send_objects_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->send_objects != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->send_objects (
			backend, data_cal, opid, cancellable,
			async_context->calobj);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_send_objects:
 * @backend: an #ECalBackend
 * @calobj: an iCalendar string
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously sends meeting information in @calobj.  The @backend may
 * modify @calobj and send meeting information only to particular users.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_backend_send_objects_finish() to get the result of the operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_send_objects (ECalBackend *backend,
                            const gchar *calobj,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (calobj != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->calobj = g_strdup (calobj);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_send_objects);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_send_objects_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_send_objects_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @out_users: a #GQueue in which to deposit results
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_send_objects().
 *
 * The function returns a string representation of a sent, or to be send,
 * vCalendar and deposits the list of users the meeting information was sent
 * to, or to be send to, in @out_users.
 *
 * Free the returned pointer with g_free(), when no longer needed.
 *
 * If an error occurs, the function will set @error and return %NULL.
 *
 * Returns: a newly allocated vCalendar string, or %NULL
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_send_objects_finish (ECalBackend *backend,
                                   GAsyncResult *result,
                                   GQueue *out_users,
                                   GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	gchar *calobj;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_send_objects), NULL);
	g_return_val_if_fail (out_users != NULL, NULL);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return NULL;

	calobj = g_queue_pop_head (&async_context->result_queue);

	e_queue_transfer (&async_context->result_queue, out_users);

	return calobj;
}

/**
 * e_cal_backend_get_attachment_uris_sync:
 * @backend: an #ECalBackend
 * @uid: a unique ID for an iCalendar object
 * @rid: a recurrence ID, or %NULL
 * @out_attachment_uris: a #GQueue in which to deposit results
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Inspects the iCalendar object specified by @uid and, optionally, @rid
 * for attachments and deposits a URI string for each attachment in
 * @out_attachment_uris.  Free the returned strings with g_free() when
 * finished with them.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 * Note that an empty result set does not necessarily imply an error.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_get_attachment_uris_sync (ECalBackend *backend,
                                        const gchar *uid,
                                        const gchar *rid,
                                        GQueue *out_attachment_uris,
                                        GCancellable *cancellable,
                                        GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	/* rid can be NULL */

	closure = e_async_closure_new ();

	e_cal_backend_get_attachment_uris (
		backend, uid, rid, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_get_attachment_uris_finish (
		backend, result, out_attachment_uris, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_get_attachment_uris() */
static void
cal_backend_get_attachment_uris_thread (GSimpleAsyncResult *simple,
                                        GObject *source_object,
                                        GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->get_attachment_uris != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->get_attachment_uris (
			backend, data_cal, opid, cancellable,
			async_context->uid,
			async_context->rid);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_get_attachment_uris:
 * @backend: an #ECalBackend
 * @uid: a unique ID for an iCalendar object
 * @rid: a recurrence ID, or %NULL
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously inspects the iCalendar object specified by @uid and,
 * optionally, @rid for attachments.
 *
 * When the operation is finished, @callback will be called.  You can then
 * call e_cal_backend_get_attachment_uris_finish() to get the result of the
 * operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_get_attachment_uris (ECalBackend *backend,
                                   const gchar *uid,
                                   const gchar *rid,
                                   GCancellable *cancellable,
                                   GAsyncReadyCallback callback,
                                   gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (uid != NULL);
	/* rid is optional */

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);
	async_context->rid = g_strdup (rid);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_get_attachment_uris);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_get_attachment_uris_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_get_attachment_uris_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @out_attachment_uris: a #GQueue in which to deposit results
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_get_attachment_uris().
 *
 * The requested attachment URI strings are deposited in @out_attachment_uris.
 * Free the returned strings with g_free() when finished with them.
 *
 * If an error occurred, the function will set @error and return %FALSE.
 * Note that an empty result set does not necessarily imply an error.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_get_attachment_uris_finish (ECalBackend *backend,
                                          GAsyncResult *result,
                                          GQueue *out_attachment_uris,
                                          GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_get_attachment_uris), FALSE);
	g_return_val_if_fail (out_attachment_uris != NULL, FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	e_queue_transfer (&async_context->result_queue, out_attachment_uris);

	return TRUE;
}

/**
 * e_cal_backend_discard_alarm_sync:
 * @backend: an #ECalBackend
 * @uid: a unique ID for an iCalendar object
 * @rid: a recurrence ID, or %NULL
 * @alarm_uid: a unique ID for an iCalendar VALARM object
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Discards the VALARM object with a unique ID of @alarm_uid from the
 * iCalendar object identified by @uid and, optionally, @rid.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_discard_alarm_sync (ECalBackend *backend,
                                  const gchar *uid,
                                  const gchar *rid,
                                  const gchar *alarm_uid,
                                  GCancellable *cancellable,
                                  GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	/* rid can be NULL */
	g_return_val_if_fail (alarm_uid != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_discard_alarm (
		backend, uid, rid, alarm_uid, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_discard_alarm_finish (
		backend, result, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_discard_alarm() */
static void
cal_backend_discard_alarm_thread (GSimpleAsyncResult *simple,
                                  GObject *source_object,
                                  GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (class->discard_alarm == NULL) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_SUPPORTED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_SUPPORTED));
		g_simple_async_result_complete_in_idle (simple);

	} else if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->discard_alarm (
			backend, data_cal, opid, cancellable,
			async_context->uid,
			async_context->rid,
			async_context->alarm_uid);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_discard_alarm:
 * @backend: an #ECalBackend
 * @uid: a unique ID for an iCalendar object
 * @rid: a recurrence ID, or %NULL
 * @alarm_uid: a unique ID for an iCalendar VALARM object
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously discards the VALARM object with a unique ID of @alarm_uid
 * from the iCalendar object identified by @uid and, optionally, @rid.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call e_cal_backend_discard_alarm_finish() to get the result of
 * the operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_discard_alarm (ECalBackend *backend,
                             const gchar *uid,
                             const gchar *rid,
                             const gchar *alarm_uid,
                             GCancellable *cancellable,
                             GAsyncReadyCallback callback,
                             gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (uid != NULL);
	/* rid can be NULL */
	g_return_if_fail (alarm_uid != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->uid = g_strdup (uid);
	async_context->rid = g_strdup (rid);
	async_context->alarm_uid = g_strdup (alarm_uid);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_discard_alarm);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_discard_alarm_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_discard_alarm_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_discard_alarm().
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_discard_alarm_finish (ECalBackend *backend,
                                    GAsyncResult *result,
                                    GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_discard_alarm), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	cal_backend_unblock_operations (backend, simple);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_backend_get_timezone_sync:
 * @backend: an #ECalBackend
 * @tzid: a unique ID for an iCalendar VTIMEZONE object
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Obtains the VTIMEZONE object identified by @tzid.  Free the returned
 * string with g_free() when finished with it.
 *
 * If an error occurs, the function will set @error and return %NULL.
 *
 * Returns: an iCalendar string, or %NULL
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_get_timezone_sync (ECalBackend *backend,
                                 const gchar *tzid,
                                 GCancellable *cancellable,
                                 GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gchar *tzobject;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);
	g_return_val_if_fail (tzid != NULL, NULL);

	closure = e_async_closure_new ();

	e_cal_backend_get_timezone (
		backend, tzid, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	tzobject = e_cal_backend_get_timezone_finish (
		backend, result, error);

	e_async_closure_free (closure);

	return tzobject;
}

/* Helper for e_cal_backend_get_timezone() */
static void
cal_backend_get_timezone_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->get_timezone != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->get_timezone (
			backend, data_cal, opid, cancellable,
			async_context->tzid);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_get_timezone:
 * @backend: an #ECalBackend
 * @tzid: a unique ID for an iCalendar VTIMEZONE object
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously obtains the VTIMEZONE object identified by @tzid.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call e_cal_backend_get_timezone_finish() to get the result of
 * the operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_get_timezone (ECalBackend *backend,
                            const gchar *tzid,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (tzid != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->tzid = g_strdup (tzid);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_get_timezone);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_get_timezone_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_get_timezone_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_get_timezone().
 *
 * Free the returned string with g_free() when finished with it.
 *
 * If an error occurred, the function will set @error and return %NULL.
 *
 * Returns: an iCalendar string, or %NULL
 *
 * Since: 3.10
 **/
gchar *
e_cal_backend_get_timezone_finish (ECalBackend *backend,
                                   GAsyncResult *result,
                                   GError **error)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;
	gchar *tzobject;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_get_timezone), NULL);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	cal_backend_unblock_operations (backend, simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return NULL;

	tzobject = g_queue_pop_head (&async_context->result_queue);

	if (!tzobject)
		g_set_error_literal (error,
			E_CAL_CLIENT_ERROR, E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND,
			e_cal_client_error_to_string (E_CAL_CLIENT_ERROR_OBJECT_NOT_FOUND));

	g_warn_if_fail (g_queue_is_empty (&async_context->result_queue));

	return tzobject;
}

/**
 * e_cal_backend_add_timezone_sync:
 * @backend: an #ECalBackend
 * @tzobject: an iCalendar VTIMEZONE string
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Adds the timezone described by @tzobject to @backend.
 *
 * If an error occurs, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_add_timezone_sync (ECalBackend *backend,
                                 const gchar *tzobject,
                                 GCancellable *cancellable,
                                 GError **error)
{
	EAsyncClosure *closure;
	GAsyncResult *result;
	gboolean success;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), FALSE);
	g_return_val_if_fail (tzobject != NULL, FALSE);

	closure = e_async_closure_new ();

	e_cal_backend_add_timezone (
		backend, tzobject, cancellable,
		e_async_closure_callback, closure);

	result = e_async_closure_wait (closure);

	success = e_cal_backend_add_timezone_finish (
		backend, result, error);

	e_async_closure_free (closure);

	return success;
}

/* Helper for e_cal_backend_add_timezone() */
static void
cal_backend_add_timezone_thread (GSimpleAsyncResult *simple,
                                 GObject *source_object,
                                 GCancellable *cancellable)
{
	ECalBackend *backend;
	ECalBackendClass *class;
	EDataCal *data_cal;
	AsyncContext *async_context;

	backend = E_CAL_BACKEND (source_object);

	class = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->add_timezone != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);
	g_return_if_fail (data_cal != NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (!e_cal_backend_is_opened (backend)) {
		g_simple_async_result_set_error (
			simple, E_CLIENT_ERROR,
			E_CLIENT_ERROR_NOT_OPENED,
			"%s", e_client_error_to_string (
			E_CLIENT_ERROR_NOT_OPENED));
		g_simple_async_result_complete_in_idle (simple);

	} else {
		guint32 opid;

		opid = cal_backend_stash_operation (backend, simple);

		class->add_timezone (
			backend, data_cal, opid, cancellable,
			async_context->tzobject);
	}

	g_object_unref (data_cal);
}

/**
 * e_cal_backend_add_timezone
 * @backend: an #ECalBackend
 * @tzobject: an iCalendar VTIMEZONE string
 * @cancellable: optional #GCancellable object, or %NULL
 * @callback: a #GAsyncReadyCallback to call when the request is satisfied
 * @user_data: data to pass to the callback function
 *
 * Asynchronously adds the timezone described by @tzobject to @backend.
 *
 * When the operation is finished, @callback will be called.  You can
 * then call e_cal_backend_add_timezone_finish() to get the result of
 * the operation.
 *
 * Since: 3.10
 **/
void
e_cal_backend_add_timezone (ECalBackend *backend,
                            const gchar *tzobject,
                            GCancellable *cancellable,
                            GAsyncReadyCallback callback,
                            gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (tzobject != NULL);

	async_context = g_slice_new0 (AsyncContext);
	async_context->tzobject = g_strdup (tzobject);

	simple = g_simple_async_result_new (
		G_OBJECT (backend), callback, user_data,
		e_cal_backend_add_timezone);

	g_simple_async_result_set_check_cancellable (simple, cancellable);

	g_simple_async_result_set_op_res_gpointer (
		simple, async_context, (GDestroyNotify) async_context_free);

	cal_backend_push_operation (
		backend, simple, cancellable, FALSE,
		cal_backend_add_timezone_thread);

	cal_backend_dispatch_next_operation (backend);

	g_object_unref (simple);
}

/**
 * e_cal_backend_add_timezone_finish:
 * @backend: an #ECalBackend
 * @result: a #GAsyncResult
 * @error: return location for a #GError, or %NULL
 *
 * Finishes the operation started with e_cal_backend_add_timezone().
 *
 * If an error occurred, the function will set @error and return %FALSE.
 *
 * Returns: %TRUE on success, %FALSE on failure
 *
 * Since: 3.10
 **/
gboolean
e_cal_backend_add_timezone_finish (ECalBackend *backend,
                                   GAsyncResult *result,
                                   GError **error)
{
	GSimpleAsyncResult *simple;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (backend),
		e_cal_backend_add_timezone), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);

	cal_backend_unblock_operations (backend, simple);

	/* Assume success unless a GError is set. */
	return !g_simple_async_result_propagate_error (simple, error);
}

/**
 * e_cal_backend_start_view:
 * @backend: an #ECalBackend
 * @view: The view to be started.
 *
 * Starts a new live view on the given backend.
 *
 * Since: 3.2
 */
void
e_cal_backend_start_view (ECalBackend *backend,
                          EDataCalView *view)
{
	ECalBackendClass *klass;

	g_return_if_fail (backend != NULL);
	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	klass = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (klass != NULL);
	g_return_if_fail (klass->start_view != NULL);

	klass->start_view (backend, view);
}

/**
 * e_cal_backend_stop_view:
 * @backend: an #ECalBackend
 * @view: The view to be stopped.
 *
 * Stops a previously started live view on the given backend.
 *
 * Since: 3.2
 */
void
e_cal_backend_stop_view (ECalBackend *backend,
                         EDataCalView *view)
{
	ECalBackendClass *klass;

	g_return_if_fail (backend != NULL);
	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	klass = E_CAL_BACKEND_GET_CLASS (backend);
	g_return_if_fail (klass != NULL);

	/* backward compatibility, do not force each backend define this function */
	if (klass->stop_view)
		klass->stop_view (backend, view);
}

/**
 * e_cal_backend_notify_component_created:
 * @backend: an #ECalBackend
 * @component: the newly created #ECalComponent
 *
 * Notifies each of the backend's listeners about a new object.
 *
 * Uses the #EDataCalView's fields-of-interest to filter out unwanted
 * information from ical strings sent over the bus.
 *
 * Since: 3.4
 **/
void
e_cal_backend_notify_component_created (ECalBackend *backend,
                                        ECalComponent *component)
{
	GList *list, *link;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (E_IS_CAL_COMPONENT (component));

	list = e_cal_backend_list_views (backend);

	for (link = list; link != NULL; link = g_list_next (link)) {
		EDataCalView *view = E_DATA_CAL_VIEW (link->data);

		if (e_data_cal_view_component_matches (view, component))
			e_data_cal_view_notify_components_added_1 (view, component);
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);
}

static void
match_view_and_notify_component (EDataCalView *view,
                                 ECalComponent *old_component,
                                 ECalComponent *new_component)
{
	gboolean old_match = FALSE, new_match = FALSE;

	if (old_component)
		old_match = e_data_cal_view_component_matches (view, old_component);

	new_match = e_data_cal_view_component_matches (view, new_component);

	if (old_match && new_match)
		e_data_cal_view_notify_components_modified_1 (view, new_component);
	else if (new_match)
		e_data_cal_view_notify_components_added_1 (view, new_component);
	else if (old_match) {

		ECalComponentId *id = e_cal_component_get_id (old_component);

		e_data_cal_view_notify_objects_removed_1 (view, id);

		e_cal_component_free_id (id);
	}
}

/**
 * e_cal_backend_notify_component_modified:
 * @backend: an #ECalBackend
 * @old_component: the #ECalComponent before the modification
 * @new_component: the #ECalComponent after the modification
 *
 * Notifies each of the backend's listeners about a modified object.
 *
 * Uses the #EDataCalView's fields-of-interest to filter out unwanted
 * information from ical strings sent over the bus.
 *
 * Since: 3.4
 **/
void
e_cal_backend_notify_component_modified (ECalBackend *backend,
                                         ECalComponent *old_component,
                                         ECalComponent *new_component)
{
	GList *list, *link;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (!old_component || E_IS_CAL_COMPONENT (old_component));
	g_return_if_fail (E_IS_CAL_COMPONENT (new_component));

	list = e_cal_backend_list_views (backend);

	for (link = list; link != NULL; link = g_list_next (link))
		match_view_and_notify_component (
			E_DATA_CAL_VIEW (link->data),
			old_component, new_component);

	g_list_free_full (list, (GDestroyNotify) g_object_unref);
}

/**
 * e_cal_backend_notify_component_removed:
 * @backend: an #ECalBackend
 * @id: the Id of the removed object
 * @old_component: the removed component
 * @new_component: the component after the removal. This only applies to recurrent 
 * appointments that had an instance removed. In that case, this function
 * notifies a modification instead of a removal.
 *
 * Notifies each of the backend's listeners about a removed object.
 *
 * Uses the #EDataCalView's fields-of-interest to filter out unwanted
 * information from ical strings sent over the bus.
 *
 * Since: 3.4
 **/
void
e_cal_backend_notify_component_removed (ECalBackend *backend,
                                        const ECalComponentId *id,
                                        ECalComponent *old_component,
                                        ECalComponent *new_component)
{
	GList *list, *link;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (id != NULL);

	if (old_component != NULL)
		g_return_if_fail (E_IS_CAL_COMPONENT (old_component));

	if (new_component != NULL)
		g_return_if_fail (E_IS_CAL_COMPONENT (new_component));

	list = e_cal_backend_list_views (backend);

	for (link = list; link != NULL; link = g_list_next (link)) {
		EDataCalView *view = E_DATA_CAL_VIEW (link->data);

		if (new_component != NULL)
			match_view_and_notify_component (
				view, old_component, new_component);

		else if (old_component == NULL)
			e_data_cal_view_notify_objects_removed_1 (view, id);

		else if (e_data_cal_view_component_matches (view, old_component))
			e_data_cal_view_notify_objects_removed_1 (view, id);
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);
}

/**
 * e_cal_backend_notify_error:
 * @backend: an #ECalBackend
 * @message: Error message
 *
 * Notifies each of the backend's listeners about an error
 **/
void
e_cal_backend_notify_error (ECalBackend *backend,
                            const gchar *message)
{
	EDataCal *data_cal;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (message != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);

	if (data_cal != NULL) {
		e_data_cal_report_error (data_cal, message);
		g_object_unref (data_cal);
	}
}

/**
 * e_cal_backend_notify_property_changed:
 * @backend: an #ECalBackend
 * @prop_name: property name, which changed
 * @prop_value: (nullable): new property value
 *
 * Notifies client about property value change.
 *
 * Since: 3.2
 **/
void
e_cal_backend_notify_property_changed (ECalBackend *backend,
                                       const gchar *prop_name,
                                       const gchar *prop_value)
{
	EDataCal *data_cal;

	g_return_if_fail (E_IS_CAL_BACKEND (backend));
	g_return_if_fail (prop_name != NULL);

	data_cal = e_cal_backend_ref_data_cal (backend);

	if (data_cal != NULL) {
		e_data_cal_report_backend_property_changed (data_cal, prop_name, prop_value ? prop_value : "");
		g_object_unref (data_cal);
	}
}

/**
 * e_cal_backend_empty_cache:
 * @backend: an #ECalBackend
 * @cache: Backend's cache to empty.
 *
 * Empties backend's cache with all notifications and so on, thus all listening
 * will know there is nothing in this backend.
 *
 * Since: 2.28
 **/
void
e_cal_backend_empty_cache (ECalBackend *backend,
                           ECalBackendCache *cache)
{
	GList *comps_in_cache;

	g_return_if_fail (backend != NULL);
	g_return_if_fail (E_IS_CAL_BACKEND (backend));

	if (!cache)
		return;

	g_return_if_fail (E_IS_CAL_BACKEND_CACHE (cache));

	e_file_cache_freeze_changes (E_FILE_CACHE (cache));

	for (comps_in_cache = e_cal_backend_cache_get_components (cache);
	     comps_in_cache;
	     comps_in_cache = comps_in_cache->next) {
		ECalComponentId *id;
		ECalComponent *comp = comps_in_cache->data;

		id = e_cal_component_get_id (comp);

		if (id) {
			e_cal_backend_cache_remove_component (cache, id->uid, id->rid);

			e_cal_backend_notify_component_removed (backend, id, comp, NULL);

			e_cal_component_free_id (id);
		}

		g_object_unref (comp);
	}

	g_list_free (comps_in_cache);

	e_file_cache_thaw_changes (E_FILE_CACHE (cache));
}

/**
 * e_cal_backend_prepare_for_completion:
 * @backend: an #ECalBackend
 * @opid: an operation ID given to #EDataCal
 * @result_queue: return location for a #GQueue, or %NULL
 *
 * Obtains the #GSimpleAsyncResult for @opid and sets @result_queue as a
 * place to deposit results prior to completing the #GSimpleAsyncResult.
 *
 * <note>
 *   <para>
 *     This is a temporary function to serve #EDataCal's "respond"
 *     functions until they can be removed.  Nothing else should be
 *     calling this function.
 *   </para>
 * </note>
 *
 * Returns: (transfer full): a #GSimpleAsyncResult
 *
 * Since: 3.10
 **/
GSimpleAsyncResult *
e_cal_backend_prepare_for_completion (ECalBackend *backend,
                                      guint32 opid,
                                      GQueue **result_queue)
{
	GSimpleAsyncResult *simple;
	AsyncContext *async_context;

	g_return_val_if_fail (E_IS_CAL_BACKEND (backend), NULL);
	g_return_val_if_fail (opid > 0, NULL);

	simple = cal_backend_claim_operation (backend, opid);
	g_return_val_if_fail (simple != NULL, NULL);

	async_context = g_simple_async_result_get_op_res_gpointer (simple);

	if (result_queue != NULL) {
		if (async_context != NULL)
			*result_queue = &async_context->result_queue;
		else
			*result_queue = NULL;
	}

	return simple;
}

/**
 * e_cal_backend_schedule_custom_operation:
 * @cal_backend: an #ECalBackend
 * @use_cancellable: (nullable): an optional #GCancellable to use for @func
 * @func: a function to call in a dedicated thread
 * @user_data: user data being passed to @func
 * @user_data_free: (nullable): optional destroy call back for @user_data
 *
 * Schedules user function @func to be run in a dedicated thread as
 * a blocking operation.
 *
 * The function adds its own reference to @use_cancellable, if not %NULL.
 *
 * The error returned from @func is propagated to client using
 * e_cal_backend_notify_error() function. If it's not desired,
 * then left the error unchanged and notify about errors manually.
 *
 * Since: 3.26
 **/
void
e_cal_backend_schedule_custom_operation (ECalBackend *cal_backend,
					 GCancellable *use_cancellable,
					 ECalBackendCustomOpFunc func,
					 gpointer user_data,
					 GDestroyNotify user_data_free)
{
	DispatchNode *node;

	g_return_if_fail (E_IS_CAL_BACKEND (cal_backend));
	g_return_if_fail (func != NULL);

	g_mutex_lock (&cal_backend->priv->operation_lock);

	node = g_slice_new0 (DispatchNode);
	node->blocking_operation = TRUE;
	node->cal_backend_weak_ref = e_weak_ref_new (cal_backend);
	node->custom_func = func;
	node->custom_func_user_data = user_data;
	node->custom_func_user_data_free = user_data_free;

	if (G_IS_CANCELLABLE (use_cancellable))
		node->cancellable = g_object_ref (use_cancellable);

	g_queue_push_tail (&cal_backend->priv->pending_operations, node);

	g_mutex_unlock (&cal_backend->priv->operation_lock);

	cal_backend_dispatch_next_operation (cal_backend);
}
