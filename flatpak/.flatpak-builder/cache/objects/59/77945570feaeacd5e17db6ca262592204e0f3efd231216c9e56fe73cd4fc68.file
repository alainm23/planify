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
 *
 */

#include "evolution-data-server-config.h"

#include <libebackend/libebackend.h>
#include <libedataserver/libedataserver.h>

#include "e-webdav-collection-backend.h"

struct _EWebDAVCollectionBackendPrivate {
	gboolean dummy;
};

G_DEFINE_TYPE (EWebDAVCollectionBackend, e_webdav_collection_backend, E_TYPE_COLLECTION_BACKEND)

static void
webdav_collection_add_uid_to_hashtable (gpointer source,
					gpointer known_sources)
{
	ESourceResource *resource;
	gchar *uid, *rid;

	if (!e_source_has_extension (source, E_SOURCE_EXTENSION_RESOURCE))
		return;

	resource = e_source_get_extension (source, E_SOURCE_EXTENSION_RESOURCE);

	uid = e_source_dup_uid (source);
	if (!uid || !*uid) {
		g_free (uid);
		return;
	}

	rid = e_source_resource_dup_identity (resource);
	if (!rid || !*rid) {
		g_free (rid);
		g_free (uid);
		return;
	}

	g_hash_table_insert (known_sources, rid, uid);
}

typedef struct _RemoveSourcesData {
	ESourceRegistryServer *server;
	EWebDAVCollectionBackend *webdav_backend;
} RemoveSourcesData;

static void
webdav_collection_remove_unknown_sources_cb (gpointer resource_id,
					     gpointer uid,
					     gpointer user_data)
{
	RemoveSourcesData *rsd = user_data;
	ESource *source;

	g_return_if_fail (rsd != NULL);

	source = e_source_registry_server_ref_source (rsd->server, uid);

	if (source) {
		if (!e_webdav_collection_backend_is_custom_source (rsd->webdav_backend, source))
			e_source_remove_sync (source, NULL, NULL);

		g_object_unref (source);
	}
}

static void
webdav_collection_add_found_source (ECollectionBackend *collection,
				    EWebDAVDiscoverSupports source_type,
				    SoupURI *uri,
				    const gchar *display_name,
				    const gchar *color,
				    gboolean calendar_auto_schedule,
				    GHashTable *known_sources)
{
	ESourceRegistryServer *server;
	ESourceBackend *backend;
	ESource *source = NULL;
	const gchar *backend_name = NULL;
	const gchar *provider = NULL;
	const gchar *identity_prefix = NULL;
	const gchar *source_uid;
	gboolean is_new;
	gchar *url;
	gchar *identity;

	g_return_if_fail (collection != NULL);
	g_return_if_fail (uri != NULL);
	g_return_if_fail (display_name != NULL);
	g_return_if_fail (known_sources != NULL);

	switch (source_type) {
	case E_WEBDAV_DISCOVER_SUPPORTS_CONTACTS:
		backend_name = E_SOURCE_EXTENSION_ADDRESS_BOOK;
		provider = "carddav";
		identity_prefix = "contacts";
		break;
	case E_WEBDAV_DISCOVER_SUPPORTS_EVENTS:
		backend_name = E_SOURCE_EXTENSION_CALENDAR;
		provider = "caldav";
		identity_prefix = "events";
		break;
	case E_WEBDAV_DISCOVER_SUPPORTS_MEMOS:
		backend_name = E_SOURCE_EXTENSION_MEMO_LIST;
		provider = "caldav";
		identity_prefix = "memos";
		break;
	case E_WEBDAV_DISCOVER_SUPPORTS_TASKS:
		backend_name = E_SOURCE_EXTENSION_TASK_LIST;
		provider = "caldav";
		identity_prefix = "tasks";
		break;
	default:
		g_warn_if_reached ();
		return;
	}

	g_return_if_fail (backend_name != NULL);

	server = e_collection_backend_ref_server (collection);
	if (!server)
		return;

	url = soup_uri_to_string (uri, FALSE);
	identity = g_strconcat (identity_prefix, "::", url, NULL);
	source_uid = g_hash_table_lookup (known_sources, identity);
	is_new = !source_uid;
	if (is_new) {
		source = e_collection_backend_new_child (collection, identity);
		g_warn_if_fail (source != NULL);
	} else {
		source = e_source_registry_server_ref_source (server, source_uid);
		g_warn_if_fail (source != NULL);

		g_hash_table_remove (known_sources, identity);
	}

	if (source) {
		ESource *master_source;
		ESourceCollection *collection_extension;
		ESourceAuthentication *child_auth;
		ESourceResource *resource;
		ESourceWebdav *master_webdav, *child_webdav;

		master_source = e_backend_get_source (E_BACKEND (collection));
		master_webdav = e_source_get_extension (master_source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		collection_extension = e_source_get_extension (master_source, E_SOURCE_EXTENSION_COLLECTION);
		child_auth = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);
		child_webdav = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		resource = e_source_get_extension (source, E_SOURCE_EXTENSION_RESOURCE);

		e_source_authentication_set_user (child_auth, e_source_collection_get_identity (collection_extension));
		e_source_webdav_set_soup_uri (child_webdav, uri);
		e_source_resource_set_identity (resource, identity);

		if (is_new) {
			/* inherit ssl trust options */
			e_source_webdav_set_ssl_trust (child_webdav, e_source_webdav_get_ssl_trust (master_webdav));
		}
	}

	g_free (identity);
	g_free (url);

	/* these properties are synchronized always */
	if (source) {
		ESourceWebdav *webdav_extension;
		gint rr, gg, bb;

		backend = e_source_get_extension (source, backend_name);
		e_source_backend_set_backend_name (backend, provider);

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);

		if (is_new || g_strcmp0 (e_source_webdav_get_display_name (webdav_extension), e_source_get_display_name (source)) == 0)
			e_source_set_display_name (source, display_name);

		e_source_webdav_set_display_name (webdav_extension, display_name);
		e_source_set_enabled (source, TRUE);

		if (source_type != E_WEBDAV_DISCOVER_SUPPORTS_CONTACTS) {
			/* Also check whether the color format is as expected; cannot
			   use gdk_rgba_parse() here, because it requires gdk/gtk. */
			if (color && sscanf (color, "#%02x%02x%02x", &rr, &gg, &bb) == 3) {
				gchar *safe_color;

				/* In case an #RRGGBBAA is returned */
				safe_color = g_strdup_printf ("#%02x%02x%02x", rr, gg, bb);

				if (is_new || g_strcmp0 (e_source_webdav_get_color (webdav_extension), e_source_selectable_get_color (E_SOURCE_SELECTABLE (backend))) == 0)
					e_source_selectable_set_color (E_SOURCE_SELECTABLE (backend), safe_color);

				e_source_webdav_set_color (webdav_extension, safe_color);

				g_free (safe_color);
			}

			if (is_new && calendar_auto_schedule)
				e_source_webdav_set_calendar_auto_schedule (webdav_extension, TRUE);
		}

		if (is_new)
			e_source_registry_server_add_source (server, source);

		g_object_unref (source);
	}

	g_object_unref (server);
}

static void
webdav_collection_process_discovered_sources (ECollectionBackend *collection,
					      GSList *discovered_sources,
					      GHashTable *known_sources,
					      const EWebDAVDiscoverSupports *source_types,
					      gint n_source_types)
{
	GSList *link;
	gint ii;

	for (link = discovered_sources; link; link = g_slist_next (link)) {
		EWebDAVDiscoveredSource *discovered_source = link->data;
		SoupURI *soup_uri;

		if (!discovered_source || !discovered_source->href || !discovered_source->display_name)
			continue;

		soup_uri = soup_uri_new (discovered_source->href);
		if (!soup_uri)
			continue;

		for (ii = 0; ii < n_source_types; ii++) {
			if ((discovered_source->supports & source_types[ii]) == source_types[ii])
				webdav_collection_add_found_source (collection, source_types[ii], soup_uri,
					discovered_source->display_name, discovered_source->color,
					(discovered_source->supports & E_WEBDAV_DISCOVER_SUPPORTS_CALENDAR_AUTO_SCHEDULE) != 0,
					known_sources);
		}

		soup_uri_free (soup_uri);
	}
}

static gchar *
webdav_collection_backend_get_resource_id (EWebDAVCollectionBackend *webdav_backend,
					   ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	if (e_source_has_extension (source, E_SOURCE_EXTENSION_RESOURCE)) {
		ESourceResource *resource;

		resource = e_source_get_extension (source, E_SOURCE_EXTENSION_RESOURCE);
		return e_source_resource_dup_identity (resource);
	}

	return NULL;
}

static gboolean
webdav_collection_backend_is_custom_source (EWebDAVCollectionBackend *webdav_backend,
					    ESource *source)
{
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	return FALSE;
}

static void
webdav_collection_backend_populate (ECollectionBackend *collection)
{
	EWebDAVCollectionBackend *webdav_backend = E_WEBDAV_COLLECTION_BACKEND (collection);
	ESourceRegistryServer *server;
	ESourceCollection *collection_extension;
	ESource *source;
	GList *list, *liter;

	/* Chain up to parent's method. */
	E_COLLECTION_BACKEND_CLASS (e_webdav_collection_backend_parent_class)->populate (collection);

	server = e_collection_backend_ref_server (collection);
	list = e_collection_backend_claim_all_resources (collection);

	for (liter = list; liter; liter = g_list_next (liter)) {
		ESource *source = liter->data;
		gchar *resource_id;

		resource_id = e_webdav_collection_backend_get_resource_id (webdav_backend, source);
		if (resource_id) {
			ESource *child;

			child = e_collection_backend_new_child (collection, resource_id);
			if (child) {
				e_source_registry_server_add_source (server, source);
				g_object_unref (child);
			}

			g_free (resource_id);
		}
	}

	g_list_free_full (list, g_object_unref);

	source = e_backend_get_source (E_BACKEND (collection));
	collection_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);

	if (e_source_get_enabled (source) && (
	    e_source_collection_get_calendar_enabled (collection_extension) ||
	    e_source_collection_get_contacts_enabled (collection_extension))) {
		gboolean needs_credentials = TRUE;

		if (e_source_has_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION)) {
			ESourceAuthentication *auth_extension;
			gchar *method;

			auth_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_AUTHENTICATION);
			method = e_source_authentication_dup_method (auth_extension);
			needs_credentials = g_strcmp0 (method, "OAuth2") != 0 &&
				!e_oauth2_services_is_oauth2_alias (e_source_registry_server_get_oauth2_services (server), method);
			g_free (method);
		}

		if (needs_credentials) {
			e_backend_schedule_credentials_required (E_BACKEND (collection),
				E_SOURCE_CREDENTIALS_REASON_REQUIRED, NULL, 0, NULL, NULL, G_STRFUNC);
		} else {
			e_backend_schedule_authenticate (E_BACKEND (collection), NULL);
		}
	}

	g_object_unref (server);
}

static void
e_webdav_collection_backend_class_init (EWebDAVCollectionBackendClass *klass)
{
	ECollectionBackendClass *collection_backend_class;

	g_type_class_add_private (klass, sizeof (EWebDAVCollectionBackendPrivate));

	klass->get_resource_id = webdav_collection_backend_get_resource_id;
	klass->is_custom_source = webdav_collection_backend_is_custom_source;

	collection_backend_class = E_COLLECTION_BACKEND_CLASS (klass);
	collection_backend_class->populate = webdav_collection_backend_populate;
}

static void
e_webdav_collection_backend_init (EWebDAVCollectionBackend *webdav_backend)
{
	webdav_backend->priv = G_TYPE_INSTANCE_GET_PRIVATE (webdav_backend, E_TYPE_WEBDAV_COLLECTION_BACKEND, EWebDAVCollectionBackendPrivate);
}

/**
 * e_webdav_collection_backend_get_resource_id:
 * @webdav_backend: an #EWebDAVCollectionBackend
 * @source: an #ESource
 *
 * Verifies that the @source is expected here and returns its resource ID,
 * which is used in call to e_collection_backend_new_child(). It returns %NULL,
 * when the @source is not part of the backend and should be removed instead.
 * The default implementation allows all sources, which has %ESourceResource
 * extension defined.
 *
 * Returns: (transfer full) (nullable): a resource ID corresponding to @source,
 *    or %NULL, when the @source should be removed.
 *
 * Since: 3.26
 **/
gchar *
e_webdav_collection_backend_get_resource_id (EWebDAVCollectionBackend *webdav_backend,
					     ESource *source)
{
	EWebDAVCollectionBackendClass *klass;

	g_return_val_if_fail (E_IS_WEBDAV_COLLECTION_BACKEND (webdav_backend), NULL);
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	klass = E_WEBDAV_COLLECTION_BACKEND_GET_CLASS (webdav_backend);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_resource_id != NULL, NULL);

	return klass->get_resource_id (webdav_backend, source);
}

/**
 * e_webdav_collection_backend_is_custom_source:
 * @webdav_backend: an #EWebDAVCollectionBackend
 * @source: an #ESource
 *
 * Returns: %TRUE, when the @source is a custom source, thus it
 *    should not be removed as an obsolete source; %FALSE to not
 *    force to keep it. It still can be left, when it's one of
 *    the WebDAV-discovered sources.
 *
 * Since: 3.26
 **/
gboolean
e_webdav_collection_backend_is_custom_source (EWebDAVCollectionBackend *webdav_backend,
					      ESource *source)
{
	EWebDAVCollectionBackendClass *klass;

	g_return_val_if_fail (E_IS_WEBDAV_COLLECTION_BACKEND (webdav_backend), FALSE);
	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	klass = E_WEBDAV_COLLECTION_BACKEND_GET_CLASS (webdav_backend);
	g_return_val_if_fail (klass != NULL, FALSE);

	if (!klass->is_custom_source)
		return FALSE;

	return klass->is_custom_source (webdav_backend, source);
}

/**
 * e_webdav_collection_backend_discover_sync:
 * @webdav_backend: an #EWebDAVCollectionBackend
 * @calendar_url: (nullable): a URL to search calendars at, or %NULL
 * @contacts_url: (nullable): a URL to search contacts at, or %NULL
 * @credentials: credentials to use when running the discovery
 * @out_certificate_pem: (out) (nullable): optional return location
 *   for a server SSL certificate in PEM format, when the operation failed
 *   with an SSL error
 * @out_certificate_errors: (out) (nullable): optional #GTlsCertificateFlags,
 *   with certificate error flags when the operation failed with SSL error
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * This function is usually called in EBackend::authenticate_sync() implementation
 * of the descendant, causing discovery of CalDAV and CardDAV sources on given URLs.
 * If either of @calendar_url and @contacts_url is %NULL, that that part is skipped.
 * The @calendar_url covers all calendars, memo lists and task lists.
 *
 * The function also takes care of e_collection_backend_authenticate_children() on success.
 *
 * Returns: an #ESourceAuthenticationResult describing whether discovery on given
 *    addresses succeeded.
 *
 * Since: 3.26
 **/
ESourceAuthenticationResult
e_webdav_collection_backend_discover_sync (EWebDAVCollectionBackend *webdav_backend,
					   const gchar *calendar_url,
					   const gchar *contacts_url,
					   const ENamedParameters *credentials,
					   gchar **out_certificate_pem,
					   GTlsCertificateFlags *out_certificate_errors,
					   GCancellable *cancellable,
					   GError **error)
{
	ECollectionBackend *collection;
	ESourceRegistryServer *server;
	ESourceCollection *collection_extension;
	ESource *source;
	ESourceAuthenticationResult result;
	GHashTable *known_sources; /* resource-id ~> source's UID */
	GList *sources;
	GSList *discovered_sources = NULL;
	ENamedParameters *credentials_copy = NULL;
	gboolean any_success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_WEBDAV_COLLECTION_BACKEND (webdav_backend), E_SOURCE_AUTHENTICATION_ERROR);

	collection = E_COLLECTION_BACKEND (webdav_backend);
	source = e_backend_get_source (E_BACKEND (webdav_backend));
	collection_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_COLLECTION);

	if ((!e_source_collection_get_calendar_enabled (collection_extension) || !calendar_url) &&
	    (!e_source_collection_get_contacts_enabled (collection_extension) || !contacts_url))
		return E_SOURCE_AUTHENTICATION_ACCEPTED;

	if (credentials && !e_named_parameters_get (credentials, E_SOURCE_CREDENTIAL_USERNAME)) {
		credentials_copy = e_named_parameters_new_clone (credentials);
		e_named_parameters_set (credentials_copy, E_SOURCE_CREDENTIAL_USERNAME, e_source_collection_get_identity (collection_extension));
		credentials = credentials_copy;
	}

	known_sources = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	sources = e_collection_backend_list_calendar_sources (collection);
	g_list_foreach (sources, webdav_collection_add_uid_to_hashtable, known_sources);
	g_list_free_full (sources, g_object_unref);

	sources = e_collection_backend_list_contacts_sources (collection);
	g_list_foreach (sources, webdav_collection_add_uid_to_hashtable, known_sources);
	g_list_free_full (sources, g_object_unref);

	server = e_collection_backend_ref_server (collection);

	if (e_source_collection_get_calendar_enabled (collection_extension) && calendar_url &&
	    e_webdav_discover_sources_full_sync (source, calendar_url,
		E_WEBDAV_DISCOVER_SUPPORTS_EVENTS | E_WEBDAV_DISCOVER_SUPPORTS_MEMOS | E_WEBDAV_DISCOVER_SUPPORTS_TASKS | E_WEBDAV_DISCOVER_SUPPORTS_CALENDAR_AUTO_SCHEDULE,
		credentials, (EWebDAVDiscoverRefSourceFunc) e_source_registry_server_ref_source, server,
		out_certificate_pem, out_certificate_errors, &discovered_sources, NULL, cancellable, &local_error)) {
		EWebDAVDiscoverSupports source_types[] = {
			E_WEBDAV_DISCOVER_SUPPORTS_EVENTS,
			E_WEBDAV_DISCOVER_SUPPORTS_MEMOS,
			E_WEBDAV_DISCOVER_SUPPORTS_TASKS
		};

		webdav_collection_process_discovered_sources (collection, discovered_sources, known_sources, source_types, G_N_ELEMENTS (source_types));

		e_webdav_discover_free_discovered_sources (discovered_sources);
		discovered_sources = NULL;
		any_success = TRUE;
	}

	if (!local_error && e_source_collection_get_contacts_enabled (collection_extension) && contacts_url &&
	    e_webdav_discover_sources_full_sync (source, contacts_url, E_WEBDAV_DISCOVER_SUPPORTS_CONTACTS,
		credentials, (EWebDAVDiscoverRefSourceFunc) e_source_registry_server_ref_source, server,
		out_certificate_pem, out_certificate_errors, &discovered_sources, NULL, cancellable, &local_error)) {
		EWebDAVDiscoverSupports source_types[] = {
			E_WEBDAV_DISCOVER_SUPPORTS_CONTACTS
		};

		webdav_collection_process_discovered_sources (collection, discovered_sources, known_sources, source_types, G_N_ELEMENTS (source_types));

		e_webdav_discover_free_discovered_sources (discovered_sources);
		discovered_sources = NULL;
		any_success = TRUE;
	}

	if (any_success && server) {
		RemoveSourcesData rsd;

		rsd.server = server;
		rsd.webdav_backend = webdav_backend;

		g_hash_table_foreach (known_sources, webdav_collection_remove_unknown_sources_cb, &rsd);

		g_clear_error (&local_error);
	}

	g_clear_object (&server);

	if (local_error == NULL) {
		result = E_SOURCE_AUTHENTICATION_ACCEPTED;
		e_collection_backend_authenticate_children (collection, credentials);
	} else if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_UNAUTHORIZED) ||
		   g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_FORBIDDEN)) {
		result = E_SOURCE_AUTHENTICATION_REJECTED;
		g_clear_error (&local_error);
	} else if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_SSL_FAILED)) {
		result = E_SOURCE_AUTHENTICATION_ERROR_SSL_FAILED;
		g_propagate_error (error, local_error);
	} else {
		result = E_SOURCE_AUTHENTICATION_ERROR;
		g_propagate_error (error, local_error);
	}

	g_hash_table_destroy (known_sources);
	e_named_parameters_free (credentials_copy);

	return result;
}
