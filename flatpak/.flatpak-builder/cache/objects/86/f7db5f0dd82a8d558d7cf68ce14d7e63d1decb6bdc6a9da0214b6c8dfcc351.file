/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Evolution calendar - iCalendar http backend
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Hans Petter Jansson <hpj@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <string.h>
#include <unistd.h>
#include <glib/gi18n-lib.h>

#include <libsoup/soup.h>
#include <libedata-cal/libedata-cal.h>

#include "e-cal-backend-http.h"

#define EDC_ERROR(_code) e_data_cal_create_error (_code, NULL)
#define EDC_ERROR_EX(_code, _msg) e_data_cal_create_error (_code, _msg)

G_DEFINE_TYPE (ECalBackendHttp, e_cal_backend_http, E_TYPE_CAL_META_BACKEND)

struct _ECalBackendHttpPrivate {
	ESoupSession *session;

	SoupRequestHTTP *request;
	GInputStream *input_stream;
	GRecMutex conn_lock;
	GHashTable *components; /* gchar *uid ~> icalcomponent * */
};

static gchar *
ecb_http_webcal_to_http_method (const gchar *webcal_str,
				gboolean secure)
{
	if (secure && (strncmp ("http://", webcal_str, sizeof ("http://") - 1) == 0))
		return g_strconcat ("https://", webcal_str + sizeof ("http://") - 1, NULL);

	if (strncmp ("webcal://", webcal_str, sizeof ("webcal://") - 1))
		return g_strdup (webcal_str);

	if (secure)
		return g_strconcat ("https://", webcal_str + sizeof ("webcal://") - 1, NULL);
	else
		return g_strconcat ("http://", webcal_str + sizeof ("webcal://") - 1, NULL);
}

static gchar *
ecb_http_dup_uri (ECalBackendHttp *cbhttp)
{
	ESource *source;
	ESourceSecurity *security_extension;
	ESourceWebdav *webdav_extension;
	SoupURI *soup_uri;
	gboolean secure_connection;
	const gchar *extension_name;
	gchar *uri_string, *uri;

	g_return_val_if_fail (E_IS_CAL_BACKEND_HTTP (cbhttp), NULL);

	source = e_backend_get_source (E_BACKEND (cbhttp));

	extension_name = E_SOURCE_EXTENSION_SECURITY;
	security_extension = e_source_get_extension (source, extension_name);

	extension_name = E_SOURCE_EXTENSION_WEBDAV_BACKEND;
	webdav_extension = e_source_get_extension (source, extension_name);

	secure_connection = e_source_security_get_secure (security_extension);

	soup_uri = e_source_webdav_dup_soup_uri (webdav_extension);
	uri_string = soup_uri_to_string (soup_uri, FALSE);
	soup_uri_free (soup_uri);

	if (!uri_string || !*uri_string) {
		g_free (uri_string);
		return NULL;
	}

	uri = ecb_http_webcal_to_http_method (uri_string, secure_connection);

	g_free (uri_string);

	return uri;
}

static gchar *
ecb_http_read_stream_sync (GInputStream *input_stream,
			   goffset expected_length,
			   GCancellable *cancellable,
			   GError **error)
{
	GString *icalstr;
	void *buffer;
	gsize nread = 0;
	gboolean success = FALSE;

	g_return_val_if_fail (G_IS_INPUT_STREAM (input_stream), NULL);

	icalstr = g_string_sized_new ((expected_length > 0 && expected_length <= 1024 * 1024) ? expected_length + 1 : 1024);

	buffer = g_malloc (16384);

	while (success = g_input_stream_read_all (input_stream, buffer, 16384, &nread, cancellable, error),
	       success && nread > 0) {
		g_string_append_len (icalstr, (const gchar *) buffer, nread);
	}

	g_free (buffer);

	return g_string_free (icalstr, !success);
}

static gboolean
ecb_http_connect_sync (ECalMetaBackend *meta_backend,
		       const ENamedParameters *credentials,
		       ESourceAuthenticationResult *out_auth_result,
		       gchar **out_certificate_pem,
		       GTlsCertificateFlags *out_certificate_errors,
		       GCancellable *cancellable,
		       GError **error)
{
	ECalBackendHttp *cbhttp;
	ESource *source;
	SoupRequestHTTP *request;
	GInputStream *input_stream = NULL;
	gchar *uri;
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_CAL_BACKEND_HTTP (meta_backend), FALSE);
	g_return_val_if_fail (out_auth_result != NULL, FALSE);

	cbhttp = E_CAL_BACKEND_HTTP (meta_backend);

	g_rec_mutex_lock (&cbhttp->priv->conn_lock);

	if (cbhttp->priv->request && cbhttp->priv->input_stream) {
		g_rec_mutex_unlock (&cbhttp->priv->conn_lock);
		return TRUE;
	}

	source = e_backend_get_source (E_BACKEND (meta_backend));

	g_clear_object (&cbhttp->priv->input_stream);
	g_clear_object (&cbhttp->priv->request);

	uri = ecb_http_dup_uri (cbhttp);

	if (!uri || !*uri) {
		g_rec_mutex_unlock (&cbhttp->priv->conn_lock);
		g_free (uri);

		g_propagate_error (error, EDC_ERROR_EX (OtherError, _("URI not set")));
		return FALSE;
	}

	e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTING);

	e_soup_session_set_credentials (cbhttp->priv->session, credentials);

	request = e_soup_session_new_request (cbhttp->priv->session, SOUP_METHOD_GET, uri, &local_error);
	success = request != NULL;

	if (success) {
		SoupMessage *message;

		message = soup_request_http_get_message (request);

		input_stream = e_soup_session_send_request_sync (cbhttp->priv->session, request, cancellable, &local_error);

		success = input_stream != NULL;

		if (success && message && !SOUP_STATUS_IS_SUCCESSFUL (message->status_code)) {
			if (input_stream && e_soup_session_get_log_level (cbhttp->priv->session) == SOUP_LOGGER_LOG_BODY) {
				gchar *response = ecb_http_read_stream_sync (input_stream, -1, cancellable, NULL);

				if (response) {
					printf ("%s\n", response);
					fflush (stdout);

					g_free (response);
				}
			}

			g_clear_object (&input_stream);
			success = FALSE;
		}

		if (success) {
			e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTED);
		} else {
			guint status_code = message ? message->status_code : SOUP_STATUS_MALFORMED;
			gboolean credentials_empty;

			credentials_empty = !credentials || !e_named_parameters_count (credentials);

			*out_auth_result = E_SOURCE_AUTHENTICATION_ERROR;

			/* because evolution knows only G_IO_ERROR_CANCELLED */
			if (status_code == SOUP_STATUS_CANCELLED) {
				g_set_error (error, G_IO_ERROR, G_IO_ERROR_CANCELLED,
					"%s", message->reason_phrase);
			} else if (status_code == SOUP_STATUS_FORBIDDEN && credentials_empty) {
				*out_auth_result = E_SOURCE_AUTHENTICATION_REQUIRED;
			} else if (status_code == SOUP_STATUS_UNAUTHORIZED) {
				if (credentials_empty)
					*out_auth_result = E_SOURCE_AUTHENTICATION_REQUIRED;
				else
					*out_auth_result = E_SOURCE_AUTHENTICATION_REJECTED;
			} else if (local_error) {
				g_propagate_error (error, local_error);
				local_error = NULL;
			} else {
				g_set_error_literal (error, SOUP_HTTP_ERROR, status_code,
					message ? message->reason_phrase : soup_status_get_phrase (status_code));
			}

			if (status_code == SOUP_STATUS_SSL_FAILED) {
				*out_auth_result = E_SOURCE_AUTHENTICATION_ERROR_SSL_FAILED;

				e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_SSL_FAILED);
				e_soup_session_get_ssl_error_details (cbhttp->priv->session, out_certificate_pem, out_certificate_errors);
			} else {
				e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
			}
		}

		g_clear_object (&message);
	} else {
		e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);

		g_set_error (error, E_DATA_CAL_ERROR, OtherError, _("Malformed URI “%s”: %s"),
			uri, local_error ? local_error->message : _("Unknown error"));
	}

	if (success) {
		cbhttp->priv->request = request;
		cbhttp->priv->input_stream = input_stream;

		*out_auth_result = E_SOURCE_AUTHENTICATION_ACCEPTED;
	} else {
		g_clear_object (&request);
		g_clear_object (&input_stream);
	}

	g_rec_mutex_unlock (&cbhttp->priv->conn_lock);
	g_clear_error (&local_error);
	g_free (uri);

	return success;
}

static gboolean
ecb_http_disconnect_sync (ECalMetaBackend *meta_backend,
			  GCancellable *cancellable,
			  GError **error)
{
	ECalBackendHttp *cbhttp;
	ESource *source;

	g_return_val_if_fail (E_IS_CAL_BACKEND_HTTP (meta_backend), FALSE);

	cbhttp = E_CAL_BACKEND_HTTP (meta_backend);

	g_rec_mutex_lock (&cbhttp->priv->conn_lock);

	g_clear_object (&cbhttp->priv->input_stream);
	g_clear_object (&cbhttp->priv->request);

	if (cbhttp->priv->session)
		soup_session_abort (SOUP_SESSION (cbhttp->priv->session));

	if (cbhttp->priv->components) {
		g_hash_table_destroy (cbhttp->priv->components);
		cbhttp->priv->components = NULL;
	}

	g_rec_mutex_unlock (&cbhttp->priv->conn_lock);

	source = e_backend_get_source (E_BACKEND (meta_backend));
	e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);

	return TRUE;
}

static gboolean
ecb_http_get_changes_sync (ECalMetaBackend *meta_backend,
			   const gchar *last_sync_tag,
			   gboolean is_repeat,
			   gchar **out_new_sync_tag,
			   gboolean *out_repeat,
			   GSList **out_created_objects,
			   GSList **out_modified_objects,
			   GSList **out_removed_objects,
			   GCancellable *cancellable,
			   GError **error)
{
	ECalBackendHttp *cbhttp;
	SoupMessage *message;
	gchar *icalstring;
	icalcompiter iter;
	icalcomponent *maincomp, *subcomp;
	icalcomponent_kind backend_kind = e_cal_backend_get_kind (E_CAL_BACKEND (meta_backend));
	GHashTable *components = NULL;
	gboolean success = TRUE;

	g_return_val_if_fail (E_IS_CAL_BACKEND_HTTP (meta_backend), FALSE);
	g_return_val_if_fail (out_new_sync_tag != NULL, FALSE);
	g_return_val_if_fail (out_created_objects != NULL, FALSE);
	g_return_val_if_fail (out_modified_objects != NULL, FALSE);
	g_return_val_if_fail (out_removed_objects != NULL, FALSE);

	cbhttp = E_CAL_BACKEND_HTTP (meta_backend);

	g_rec_mutex_lock (&cbhttp->priv->conn_lock);

	if (!cbhttp->priv->request || !cbhttp->priv->input_stream) {
		g_rec_mutex_unlock (&cbhttp->priv->conn_lock);
		g_propagate_error (error, EDC_ERROR (RepositoryOffline));
		return FALSE;
	}

	message = soup_request_http_get_message (cbhttp->priv->request);
	if (message) {
		const gchar *new_etag;

		new_etag = soup_message_headers_get_one (message->response_headers, "ETag");
		if (new_etag && !*new_etag) {
			new_etag = NULL;
		} else if (new_etag && g_strcmp0 (last_sync_tag, new_etag) == 0) {
			g_rec_mutex_unlock (&cbhttp->priv->conn_lock);
			/* Nothing changed */
			g_object_unref (message);

			ecb_http_disconnect_sync (meta_backend, cancellable, NULL);

			return TRUE;
		}

		*out_new_sync_tag = g_strdup (new_etag);
	}

	g_clear_object (&message);

	icalstring = ecb_http_read_stream_sync (cbhttp->priv->input_stream,
		soup_request_get_content_length (SOUP_REQUEST (cbhttp->priv->request)), cancellable, error);

	g_rec_mutex_unlock (&cbhttp->priv->conn_lock);

	if (!icalstring) {
		/* The error is already set */
		e_cal_meta_backend_empty_cache_sync (meta_backend, cancellable, NULL);
		ecb_http_disconnect_sync (meta_backend, cancellable, NULL);
		return FALSE;
	}

	if (e_soup_session_get_log_level (cbhttp->priv->session) == SOUP_LOGGER_LOG_BODY) {
		printf ("%s\n", icalstring);
		fflush (stdout);
	}

	/* Skip the UTF-8 marker at the beginning of the string */
	if (((guchar) icalstring[0]) == 0xEF &&
	    ((guchar) icalstring[1]) == 0xBB &&
	    ((guchar) icalstring[2]) == 0xBF)
		maincomp = icalparser_parse_string (icalstring + 3);
	else
		maincomp = icalparser_parse_string (icalstring);

	g_free (icalstring);

	if (!maincomp) {
		g_set_error (error, SOUP_HTTP_ERROR, SOUP_STATUS_MALFORMED, _("Bad file format."));
		e_cal_meta_backend_empty_cache_sync (meta_backend, cancellable, NULL);
		ecb_http_disconnect_sync (meta_backend, cancellable, NULL);
		return FALSE;
	}

	if (icalcomponent_isa (maincomp) != ICAL_VCALENDAR_COMPONENT &&
	    icalcomponent_isa (maincomp) != ICAL_XROOT_COMPONENT) {
		icalcomponent_free (maincomp);
		g_set_error (error, SOUP_HTTP_ERROR, SOUP_STATUS_MALFORMED, _("Not a calendar."));
		e_cal_meta_backend_empty_cache_sync (meta_backend, cancellable, NULL);
		ecb_http_disconnect_sync (meta_backend, cancellable, NULL);
		return FALSE;
	}

	if (icalcomponent_isa (maincomp) == ICAL_VCALENDAR_COMPONENT) {
		subcomp = maincomp;
	} else {
		iter = icalcomponent_begin_component (maincomp, ICAL_VCALENDAR_COMPONENT);
		subcomp = icalcompiter_deref (&iter);
	}

	while (subcomp && success) {
		if (subcomp != maincomp)
			icalcompiter_next (&iter);

		if (icalcomponent_isa (subcomp) == ICAL_VCALENDAR_COMPONENT) {
			success = e_cal_meta_backend_gather_timezones_sync (meta_backend, subcomp, TRUE, cancellable, error);
			if (success) {
				icalcomponent *icalcomp;

				while (icalcomp = icalcomponent_get_first_component (subcomp, backend_kind), icalcomp) {
					icalcomponent *existing_icalcomp;
					gpointer orig_key, orig_value;
					const gchar *uid;

					icalcomponent_remove_component (subcomp, icalcomp);

					if (!components)
						components = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, (GDestroyNotify) icalcomponent_free);

					if (!icalcomponent_get_first_property (icalcomp, ICAL_UID_PROPERTY)) {
						gchar *new_uid = e_util_generate_uid ();
						icalcomponent_set_uid (icalcomp, new_uid);
						g_free (new_uid);
					}

					uid = icalcomponent_get_uid (icalcomp);

					if (!g_hash_table_lookup_extended (components, uid, &orig_key, &orig_value)) {
						orig_key = NULL;
						orig_value = NULL;
					}

					existing_icalcomp = orig_value;
					if (existing_icalcomp) {
						if (icalcomponent_isa (existing_icalcomp) != ICAL_VCALENDAR_COMPONENT) {
							icalcomponent *vcal;

							vcal = e_cal_util_new_top_level ();

							g_warn_if_fail (g_hash_table_steal (components, uid));

							icalcomponent_add_component (vcal, existing_icalcomp);
							g_hash_table_insert (components, g_strdup (uid), vcal);

							g_free (orig_key);

							existing_icalcomp = vcal;
						}

						icalcomponent_add_component (existing_icalcomp, icalcomp);
					} else {
						g_hash_table_insert (components, g_strdup (uid), icalcomp);
					}
				}
			}
		}

		if (subcomp == maincomp)
			subcomp = NULL;
		else
			subcomp = icalcompiter_deref (&iter);
	}

	if (components) {
		g_warn_if_fail (cbhttp->priv->components == NULL);
		cbhttp->priv->components = components;

		icalcomponent_free (maincomp);

		success = E_CAL_META_BACKEND_CLASS (e_cal_backend_http_parent_class)->get_changes_sync (meta_backend,
			last_sync_tag, is_repeat, out_new_sync_tag, out_repeat, out_created_objects,
			out_modified_objects, out_removed_objects, cancellable, error);
	} else {
		icalcomponent_free (maincomp);
	}

	if (!success)
		ecb_http_disconnect_sync (meta_backend, cancellable, NULL);

	return success;
}

static gboolean
ecb_http_list_existing_sync (ECalMetaBackend *meta_backend,
			     gchar **out_new_sync_tag,
			     GSList **out_existing_objects, /* ECalMetaBackendInfo * */
			     GCancellable *cancellable,
			     GError **error)
{
	ECalBackendHttp *cbhttp;
	ECalCache *cal_cache;
	icalcomponent_kind kind;
	GHashTableIter iter;
	gpointer key, value;

	g_return_val_if_fail (E_IS_CAL_BACKEND_HTTP (meta_backend), FALSE);
	g_return_val_if_fail (out_existing_objects != NULL, FALSE);

	cbhttp = E_CAL_BACKEND_HTTP (meta_backend);

	*out_existing_objects = NULL;

	g_return_val_if_fail (cbhttp->priv->components != NULL, FALSE);

	cal_cache = e_cal_meta_backend_ref_cache (meta_backend);
	g_return_val_if_fail (cal_cache != NULL, FALSE);

	kind = e_cal_backend_get_kind (E_CAL_BACKEND (meta_backend));

	g_hash_table_iter_init (&iter, cbhttp->priv->components);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		icalcomponent *icalcomp = value;
		ECalMetaBackendInfo *nfo;
		const gchar *uid;
		gchar *revision, *object;

		if (icalcomp && icalcomponent_isa (icalcomp) == ICAL_VCALENDAR_COMPONENT)
			icalcomp = icalcomponent_get_first_component (icalcomp, kind);

		if (!icalcomp)
			continue;

		uid = icalcomponent_get_uid (icalcomp);
		revision = e_cal_cache_dup_component_revision (cal_cache, icalcomp);
		object = icalcomponent_as_ical_string_r (value);

		nfo = e_cal_meta_backend_info_new (uid, revision, object, NULL);

		*out_existing_objects = g_slist_prepend (*out_existing_objects, nfo);

		g_free (revision);
		g_free (object);
	}

	g_object_unref (cal_cache);

	ecb_http_disconnect_sync (meta_backend, cancellable, NULL);

	return TRUE;
}

static gboolean
ecb_http_load_component_sync (ECalMetaBackend *meta_backend,
			      const gchar *uid,
			      const gchar *extra,
			      icalcomponent **out_component,
			      gchar **out_extra,
			      GCancellable *cancellable,
			      GError **error)
{
	ECalBackendHttp *cbhttp;
	gpointer key = NULL, value = NULL;

	g_return_val_if_fail (E_IS_CAL_BACKEND_HTTP (meta_backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_component != NULL, FALSE);

	cbhttp = E_CAL_BACKEND_HTTP (meta_backend);
	g_return_val_if_fail (cbhttp->priv->components != NULL, FALSE);

	if (!cbhttp->priv->components ||
	    !g_hash_table_contains (cbhttp->priv->components, uid)) {
		g_propagate_error (error, EDC_ERROR (ObjectNotFound));
		return FALSE;
	}

	g_warn_if_fail (g_hash_table_lookup_extended (cbhttp->priv->components, uid, &key, &value));
	g_warn_if_fail (g_hash_table_steal (cbhttp->priv->components, uid));

	*out_component = value;

	g_free (key);

	if (!g_hash_table_size (cbhttp->priv->components)) {
		g_hash_table_destroy (cbhttp->priv->components);
		cbhttp->priv->components = NULL;

		ecb_http_disconnect_sync (meta_backend, cancellable, NULL);
	}

	return value != NULL;
}

static void
e_cal_backend_http_constructed (GObject *object)
{
	ECalBackendHttp *cbhttp = E_CAL_BACKEND_HTTP (object);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_cal_backend_http_parent_class)->constructed (object);

	cbhttp->priv->session = e_soup_session_new (e_backend_get_source (E_BACKEND (cbhttp)));

	e_soup_session_setup_logging (cbhttp->priv->session, g_getenv ("WEBCAL_DEBUG"));

	e_binding_bind_property (
		cbhttp, "proxy-resolver",
		cbhttp->priv->session, "proxy-resolver",
		G_BINDING_SYNC_CREATE);
}

static void
e_cal_backend_http_dispose (GObject *object)
{
	ECalBackendHttp *cbhttp;

	cbhttp = E_CAL_BACKEND_HTTP (object);

	g_rec_mutex_lock (&cbhttp->priv->conn_lock);

	g_clear_object (&cbhttp->priv->request);
	g_clear_object (&cbhttp->priv->input_stream);

	if (cbhttp->priv->session)
		soup_session_abort (SOUP_SESSION (cbhttp->priv->session));

	if (cbhttp->priv->components) {
		g_hash_table_destroy (cbhttp->priv->components);
		cbhttp->priv->components = NULL;
	}

	g_rec_mutex_unlock (&cbhttp->priv->conn_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_cal_backend_http_parent_class)->dispose (object);
}

static void
e_cal_backend_http_finalize (GObject *object)
{
	ECalBackendHttp *cbhttp = E_CAL_BACKEND_HTTP (object);

	g_clear_object (&cbhttp->priv->session);
	g_rec_mutex_clear (&cbhttp->priv->conn_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_cal_backend_http_parent_class)->finalize (object);
}

static void
e_cal_backend_http_init (ECalBackendHttp *cbhttp)
{
	cbhttp->priv = G_TYPE_INSTANCE_GET_PRIVATE (cbhttp, E_TYPE_CAL_BACKEND_HTTP, ECalBackendHttpPrivate);

	g_rec_mutex_init (&cbhttp->priv->conn_lock);

	e_cal_backend_set_writable (E_CAL_BACKEND (cbhttp), FALSE);
}

static void
e_cal_backend_http_class_init (ECalBackendHttpClass *klass)
{
	GObjectClass *object_class;
	ECalBackendSyncClass *cal_backend_sync_class;
	ECalMetaBackendClass *cal_meta_backend_class;

	g_type_class_add_private (klass, sizeof (ECalBackendHttpPrivate));

	cal_meta_backend_class = E_CAL_META_BACKEND_CLASS (klass);
	cal_meta_backend_class->connect_sync = ecb_http_connect_sync;
	cal_meta_backend_class->disconnect_sync = ecb_http_disconnect_sync;
	cal_meta_backend_class->get_changes_sync = ecb_http_get_changes_sync;
	cal_meta_backend_class->list_existing_sync = ecb_http_list_existing_sync;
	cal_meta_backend_class->load_component_sync = ecb_http_load_component_sync;

	/* Setting these methods to NULL will cause "Not supported" error,
	   which is more accurate than "Permission denied" error */
	cal_backend_sync_class = E_CAL_BACKEND_SYNC_CLASS (klass);
	cal_backend_sync_class->create_objects_sync = NULL;
	cal_backend_sync_class->modify_objects_sync = NULL;
	cal_backend_sync_class->remove_objects_sync = NULL;

	object_class = G_OBJECT_CLASS (klass);
	object_class->constructed = e_cal_backend_http_constructed;
	object_class->dispose = e_cal_backend_http_dispose;
	object_class->finalize = e_cal_backend_http_finalize;
}
