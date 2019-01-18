/*
 * Copyright (C) 2008 Matthias Braun <matze@braunis.de>
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
 * Authors: Matthias Braun <matze@braunis.de>
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <glib/gi18n-lib.h>

#include "libedataserver/libedataserver.h"

#include "e-book-backend-carddav.h"

#define E_WEBDAV_MAX_MULTIGET_AMOUNT 100 /* what's the maximum count of items to fetch within a multiget request */

#define E_WEBDAV_X_ETAG "X-EVOLUTION-WEBDAV-ETAG"

#define EDB_ERROR(_code) e_data_book_create_error (_code, NULL)
#define EDB_ERROR_EX(_code, _msg) e_data_book_create_error (_code, _msg)

struct _EBookBackendCardDAVPrivate {
	/* The main WebDAV session  */
	EWebDAVSession *webdav;
	GMutex webdav_lock;

	/* support for 'getctag' extension */
	gboolean ctag_supported;

	/* Whether talking to the Google server */
	gboolean is_google;
};

G_DEFINE_TYPE (EBookBackendCardDAV, e_book_backend_carddav, E_TYPE_BOOK_META_BACKEND)

static EWebDAVSession *
ebb_carddav_ref_session (EBookBackendCardDAV *bbdav)
{
	EWebDAVSession *webdav;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (bbdav), NULL);

	g_mutex_lock (&bbdav->priv->webdav_lock);
	if (bbdav->priv->webdav)
		webdav = g_object_ref (bbdav->priv->webdav);
	else
		webdav = NULL;
	g_mutex_unlock (&bbdav->priv->webdav_lock);

	return webdav;
}

static gboolean
ebb_carddav_connect_sync (EBookMetaBackend *meta_backend,
			  const ENamedParameters *credentials,
			  ESourceAuthenticationResult *out_auth_result,
			  gchar **out_certificate_pem,
			  GTlsCertificateFlags *out_certificate_errors,
			  GCancellable *cancellable,
			  GError **error)
{
	EBookBackendCardDAV *bbdav;
	EWebDAVSession *webdav;
	GHashTable *capabilities = NULL, *allows = NULL;
	ESource *source;
	gboolean success, is_writable = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (meta_backend), FALSE);
	g_return_val_if_fail (out_auth_result != NULL, FALSE);

	bbdav = E_BOOK_BACKEND_CARDDAV (meta_backend);

	g_mutex_lock (&bbdav->priv->webdav_lock);
	if (bbdav->priv->webdav) {
		g_mutex_unlock (&bbdav->priv->webdav_lock);
		return TRUE;
	}
	g_mutex_unlock (&bbdav->priv->webdav_lock);

	source = e_backend_get_source (E_BACKEND (meta_backend));

	webdav = e_webdav_session_new (source);

	e_soup_session_setup_logging (E_SOUP_SESSION (webdav), g_getenv ("WEBDAV_DEBUG"));

	e_binding_bind_property (
		bbdav, "proxy-resolver",
		webdav, "proxy-resolver",
		G_BINDING_SYNC_CREATE);

	/* Thinks the 'getctag' extension is available the first time, but unset it when realizes it isn't. */
	bbdav->priv->ctag_supported = TRUE;

	e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTING);

	e_soup_session_set_credentials (E_SOUP_SESSION (webdav), credentials);

	success = e_webdav_session_options_sync (webdav, NULL,
		&capabilities, &allows, cancellable, &local_error);

	/* iCloud and Google servers can return "404 Not Found" when issued OPTIONS on the addressbook collection */
	if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_NOT_FOUND)) {
		ESourceWebdav *webdav_extension;
		SoupURI *soup_uri;

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		soup_uri = e_source_webdav_dup_soup_uri (webdav_extension);
		if (soup_uri) {
			if (soup_uri->host && soup_uri->path && *soup_uri->path &&
			    e_util_utf8_strstrcase (soup_uri->host, ".icloud.com")) {
				/* Try parent directory */
				gchar *path;
				gint len = strlen (soup_uri->path);

				if (soup_uri->path[len - 1] == '/')
					soup_uri->path[len - 1] = '\0';

				path = g_path_get_dirname (soup_uri->path);
				if (path && g_str_has_prefix (soup_uri->path, path)) {
					gchar *uri;

					soup_uri_set_path (soup_uri, path);

					uri = soup_uri_to_string (soup_uri, FALSE);
					if (uri) {
						g_clear_error (&local_error);

						success = e_webdav_session_options_sync (webdav, uri,
							&capabilities, &allows, cancellable, &local_error);
					}

					g_free (uri);
				}

				g_free (path);
			} else if (soup_uri->host && e_util_utf8_strstrcase (soup_uri->host, ".googleusercontent.com")) {
				g_clear_error (&local_error);
				success = TRUE;

				/* Google's CardDAV doesn't like OPTIONS, hard-code it */
				capabilities = g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, g_free, NULL);
				g_hash_table_insert (capabilities, g_strdup (E_WEBDAV_CAPABILITY_ADDRESSBOOK), GINT_TO_POINTER (1));

				allows = g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, g_free, NULL);
				g_hash_table_insert (allows, g_strdup (SOUP_METHOD_PUT), GINT_TO_POINTER (1));
			}

			soup_uri_free (soup_uri);
		}
	}

	if (success && !g_cancellable_is_cancelled (cancellable)) {
		GSList *privileges = NULL, *link;

		/* Ignore any errors here */
		if (e_webdav_session_get_current_user_privilege_set_sync (webdav, NULL, &privileges, cancellable, NULL)) {
			for (link = privileges; link && !is_writable; link = g_slist_next (link)) {
				EWebDAVPrivilege *privilege = link->data;

				if (privilege) {
					is_writable = privilege->hint == E_WEBDAV_PRIVILEGE_HINT_WRITE ||
						privilege->hint == E_WEBDAV_PRIVILEGE_HINT_WRITE_CONTENT ||
						privilege->hint == E_WEBDAV_PRIVILEGE_HINT_ALL;
				}
			}

			g_slist_free_full (privileges, e_webdav_privilege_free);
		} else {
			is_writable = allows && (
				g_hash_table_contains (allows, SOUP_METHOD_PUT) ||
				g_hash_table_contains (allows, SOUP_METHOD_POST) ||
				g_hash_table_contains (allows, SOUP_METHOD_DELETE));
		}
	}

	if (success) {
		ESourceWebdav *webdav_extension;
		EBookCache *book_cache;
		SoupURI *soup_uri;
		gboolean addressbook;

		webdav_extension = e_source_get_extension (source, E_SOURCE_EXTENSION_WEBDAV_BACKEND);
		soup_uri = e_source_webdav_dup_soup_uri (webdav_extension);
		book_cache = e_book_meta_backend_ref_cache (meta_backend);

		addressbook = capabilities && g_hash_table_contains (capabilities, E_WEBDAV_CAPABILITY_ADDRESSBOOK);

		if (addressbook) {
			e_book_backend_set_writable (E_BOOK_BACKEND (bbdav), is_writable);

			e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_CONNECTED);

			bbdav->priv->is_google = soup_uri && soup_uri->host && (
				g_ascii_strcasecmp (soup_uri->host, "www.google.com") == 0 ||
				g_ascii_strcasecmp (soup_uri->host, "apidata.googleusercontent.com") == 0);
		} else {
			gchar *uri;

			uri = soup_uri_to_string (soup_uri, FALSE);

			success = FALSE;
			g_set_error (error, G_IO_ERROR, G_IO_ERROR_INVALID_DATA,
				_("Given URL “%s” doesn’t reference CardDAV address book"), uri);

			g_free (uri);

			e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
		}

		g_clear_object (&book_cache);
		soup_uri_free (soup_uri);
	}

	if (success) {
		gchar *ctag = NULL;

		/* Some servers, notably Google, allow OPTIONS when not
		   authorized (aka without credentials), thus try something
		   more aggressive, just in case.

		   The 'getctag' extension is not required, thuch check
		   for unauthorized error only. */
		if (!e_webdav_session_getctag_sync (webdav, NULL, &ctag, cancellable, &local_error) &&
		    g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_UNAUTHORIZED)) {
			success = FALSE;
		} else {
			g_clear_error (&local_error);
		}

		g_free (ctag);
	}

	if (success) {
		*out_auth_result = E_SOURCE_AUTHENTICATION_ACCEPTED;
	} else {
		gboolean credentials_empty;
		gboolean is_ssl_error;

		credentials_empty = (!credentials || !e_named_parameters_count (credentials)) &&
			e_soup_session_get_authentication_requires_credentials (E_SOUP_SESSION (webdav));
		is_ssl_error = g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_SSL_FAILED);

		*out_auth_result = E_SOURCE_AUTHENTICATION_ERROR;

		/* because evolution knows only G_IO_ERROR_CANCELLED */
		if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_CANCELLED)) {
			local_error->domain = G_IO_ERROR;
			local_error->code = G_IO_ERROR_CANCELLED;
		} else if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_FORBIDDEN) && credentials_empty) {
			*out_auth_result = E_SOURCE_AUTHENTICATION_REQUIRED;
		} else if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_UNAUTHORIZED)) {
			if (credentials_empty)
				*out_auth_result = E_SOURCE_AUTHENTICATION_REQUIRED;
			else
				*out_auth_result = E_SOURCE_AUTHENTICATION_REJECTED;
		} else if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CONNECTION_REFUSED) ||
			   (!e_soup_session_get_authentication_requires_credentials (E_SOUP_SESSION (webdav)) &&
			   g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND))) {
			*out_auth_result = E_SOURCE_AUTHENTICATION_REJECTED;
		} else if (!local_error) {
			g_set_error_literal (&local_error, G_IO_ERROR, G_IO_ERROR_FAILED,
				_("Unknown error"));
		}

		if (local_error) {
			g_propagate_error (error, local_error);
			local_error = NULL;
		}

		if (is_ssl_error) {
			*out_auth_result = E_SOURCE_AUTHENTICATION_ERROR_SSL_FAILED;

			e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_SSL_FAILED);
			e_soup_session_get_ssl_error_details (E_SOUP_SESSION (webdav), out_certificate_pem, out_certificate_errors);
		} else {
			e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
		}
	}

	if (capabilities)
		g_hash_table_destroy (capabilities);
	if (allows)
		g_hash_table_destroy (allows);

	if (success && !g_cancellable_set_error_if_cancelled (cancellable, error)) {
		g_mutex_lock (&bbdav->priv->webdav_lock);
		bbdav->priv->webdav = webdav;
		g_mutex_unlock (&bbdav->priv->webdav_lock);
	} else {
		if (success) {
			e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);
			success = FALSE;
		}

		g_clear_object (&webdav);
	}

	return success;
}

static gboolean
ebb_carddav_disconnect_sync (EBookMetaBackend *meta_backend,
			     GCancellable *cancellable,
			     GError **error)
{
	EBookBackendCardDAV *bbdav;
	ESource *source;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (meta_backend), FALSE);

	bbdav = E_BOOK_BACKEND_CARDDAV (meta_backend);

	g_mutex_lock (&bbdav->priv->webdav_lock);

	if (bbdav->priv->webdav)
		soup_session_abort (SOUP_SESSION (bbdav->priv->webdav));

	g_clear_object (&bbdav->priv->webdav);

	g_mutex_unlock (&bbdav->priv->webdav_lock);

	source = e_backend_get_source (E_BACKEND (meta_backend));
	e_source_set_connection_status (source, E_SOURCE_CONNECTION_STATUS_DISCONNECTED);

	return TRUE;
}

static void
ebb_carddav_update_nfo_with_contact (EBookMetaBackendInfo *nfo,
				     EContact *contact,
				     const gchar *etag)
{
	const gchar *uid;

	g_return_if_fail (nfo != NULL);
	g_return_if_fail (E_IS_CONTACT (contact));

	uid = e_contact_get_const (contact, E_CONTACT_UID);

	if (!etag || !*etag)
		etag = nfo->revision;

	e_vcard_util_set_x_attribute (E_VCARD (contact), E_WEBDAV_X_ETAG, etag);

	g_warn_if_fail (nfo->object == NULL);
	nfo->object = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);

	if (!nfo->uid || !*(nfo->uid)) {
		g_free (nfo->uid);
		nfo->uid = g_strdup (uid);
	}

	if (g_strcmp0 (etag, nfo->revision) != 0) {
		gchar *copy = g_strdup (etag);

		g_free (nfo->revision);
		nfo->revision = copy;
	}
}

static gboolean
ebb_carddav_multiget_response_cb (EWebDAVSession *webdav,
				  xmlXPathContextPtr xpath_ctx,
				  const gchar *xpath_prop_prefix,
				  const SoupURI *request_uri,
				  const gchar *href,
				  guint status_code,
				  gpointer user_data)
{
	GSList **from_link = user_data;

	g_return_val_if_fail (from_link != NULL, FALSE);

	if (!xpath_prop_prefix) {
		e_xml_xpath_context_register_namespaces (xpath_ctx, "C", E_WEBDAV_NS_CARDDAV, NULL);
	} else if (status_code == SOUP_STATUS_OK) {
		gchar *address_data, *etag;

		g_return_val_if_fail (href != NULL, FALSE);

		address_data = e_xml_xpath_eval_as_string (xpath_ctx, "%s/C:address-data", xpath_prop_prefix);
		etag = e_webdav_session_util_maybe_dequote (e_xml_xpath_eval_as_string (xpath_ctx, "%s/D:getetag", xpath_prop_prefix));

		if (address_data) {
			EContact *contact;

			contact = e_contact_new_from_vcard (address_data);
			if (contact) {
				const gchar *uid;

				uid = e_contact_get_const (contact, E_CONTACT_UID);
				if (uid) {
					GSList *link;

					for (link = *from_link; link; link = g_slist_next (link)) {
						EBookMetaBackendInfo *nfo = link->data;

						if (!nfo)
							continue;

						if (g_strcmp0 (nfo->extra, href) == 0) {
							/* If the server returns data in the same order as it had been requested,
							   then this speeds up lookup for the matching object. */
							if (link == *from_link)
								*from_link = g_slist_next (*from_link);

							ebb_carddav_update_nfo_with_contact (nfo, contact, etag);

							break;
						}
					}
				}

				g_object_unref (contact);
			}
		}

		g_free (address_data);
		g_free (etag);
	}

	return TRUE;
}

static gboolean
ebb_carddav_multiget_from_sets_sync (EBookBackendCardDAV *bbdav,
				     EWebDAVSession *webdav,
				     GSList **in_link,
				     GSList **set2,
				     GCancellable *cancellable,
				     GError **error)
{
	EXmlDocument *xml;
	gint left_to_go = E_WEBDAV_MAX_MULTIGET_AMOUNT;
	GSList *link;
	gboolean success = TRUE;

	g_return_val_if_fail (in_link != NULL, FALSE);
	g_return_val_if_fail (*in_link != NULL, FALSE);
	g_return_val_if_fail (set2 != NULL, FALSE);

	xml = e_xml_document_new (E_WEBDAV_NS_CARDDAV, "addressbook-multiget");
	g_return_val_if_fail (xml != NULL, FALSE);

	e_xml_document_add_namespaces (xml, "D", E_WEBDAV_NS_DAV, NULL);

	e_xml_document_start_element (xml, E_WEBDAV_NS_DAV, "prop");
	e_xml_document_add_empty_element (xml, E_WEBDAV_NS_DAV, "getetag");
	e_xml_document_add_empty_element (xml, E_WEBDAV_NS_CARDDAV, "address-data");
	e_xml_document_end_element (xml); /* prop */

	link = *in_link;

	while (link && left_to_go > 0) {
		EBookMetaBackendInfo *nfo = link->data;
		SoupURI *suri;
		gchar *path = NULL;

		link = g_slist_next (link);
		if (!link) {
			link = *set2;
			*set2 = NULL;
		}

		if (!nfo)
			continue;

		left_to_go--;

		suri = soup_uri_new (nfo->extra);
		if (suri) {
			path = soup_uri_to_string (suri, TRUE);
			soup_uri_free (suri);
		}

		e_xml_document_start_element (xml, E_WEBDAV_NS_DAV, "href");
		e_xml_document_write_string (xml, path ? path : nfo->extra);
		e_xml_document_end_element (xml); /* href */

		g_free (path);
	}

	if (left_to_go != E_WEBDAV_MAX_MULTIGET_AMOUNT && success) {
		GSList *from_link = *in_link;

		success = e_webdav_session_report_sync (webdav, NULL, NULL, xml,
			ebb_carddav_multiget_response_cb, &from_link, NULL, NULL, cancellable, error);
	}

	g_object_unref (xml);

	*in_link = link;

	return success;
}

static gboolean
ebb_carddav_get_contact_items_cb (EWebDAVSession *webdav,
				  xmlXPathContextPtr xpath_ctx,
				  const gchar *xpath_prop_prefix,
				  const SoupURI *request_uri,
				  const gchar *href,
				  guint status_code,
				  gpointer user_data)
{
	GHashTable *known_items = user_data; /* gchar *href ~> EBookMetaBackendInfo * */

	g_return_val_if_fail (xpath_ctx != NULL, FALSE);
	g_return_val_if_fail (known_items != NULL, FALSE);

	if (xpath_prop_prefix &&
	    status_code == SOUP_STATUS_OK) {
		EBookMetaBackendInfo *nfo;
		gchar *etag;

		g_return_val_if_fail (href != NULL, FALSE);

		/* Skip collection resource, if returned by the server (like iCloud.com does) */
		if (g_str_has_suffix (href, "/") ||
		    (request_uri && request_uri->path && g_str_has_suffix (href, request_uri->path))) {
			return TRUE;
		}

		etag = e_webdav_session_util_maybe_dequote (e_xml_xpath_eval_as_string (xpath_ctx, "%s/D:getetag", xpath_prop_prefix));
		/* Return 'TRUE' to not stop on faulty data from the server */
		g_return_val_if_fail (etag != NULL, TRUE);

		/* UID is unknown at this moment */
		nfo = e_book_meta_backend_info_new ("", etag, NULL, href);

		g_free (etag);
		g_return_val_if_fail (nfo != NULL, FALSE);

		g_hash_table_insert (known_items, g_strdup (href), nfo);
	}

	return TRUE;
}

typedef struct _CardDAVChangesData {
	GSList **out_modified_objects;
	GSList **out_removed_objects;
	GHashTable *known_items; /* gchar *href ~> EBookMetaBackendInfo * */
} CardDAVChangesData;

static gboolean
ebb_carddav_search_changes_cb (EBookCache *book_cache,
			       const gchar *uid,
			       const gchar *revision,
			       const gchar *object,
			       const gchar *extra,
			       EOfflineState offline_state,
			       gpointer user_data)
{
	CardDAVChangesData *ccd = user_data;

	g_return_val_if_fail (ccd != NULL, FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);

	/* The 'extra' can be NULL for added contacts in offline mode */
	if ((extra && *extra) || offline_state != E_OFFLINE_STATE_LOCALLY_CREATED) {
		EBookMetaBackendInfo *nfo;

		nfo = (extra && *extra) ? g_hash_table_lookup (ccd->known_items, extra) : NULL;
		if (nfo) {
			if (g_strcmp0 (revision, nfo->revision) == 0) {
				g_hash_table_remove (ccd->known_items, extra);
			} else {
				if (!nfo->uid || !*(nfo->uid)) {
					g_free (nfo->uid);
					nfo->uid = g_strdup (uid);
				}

				*(ccd->out_modified_objects) = g_slist_prepend (*(ccd->out_modified_objects),
					e_book_meta_backend_info_copy (nfo));

				g_hash_table_remove (ccd->known_items, extra);
			}
		} else {
			*(ccd->out_removed_objects) = g_slist_prepend (*(ccd->out_removed_objects),
				e_book_meta_backend_info_new (uid, revision, object, extra));
		}
	}

	return TRUE;
}

static void
ebb_carddav_check_credentials_error (EBookBackendCardDAV *bbdav,
				     EWebDAVSession *webdav,
				     GError *op_error)
{
	g_return_if_fail (E_IS_BOOK_BACKEND_CARDDAV (bbdav));

	if (g_error_matches (op_error, SOUP_HTTP_ERROR, SOUP_STATUS_SSL_FAILED) && webdav) {
		op_error->domain = E_DATA_BOOK_ERROR;
		op_error->code = E_DATA_BOOK_STATUS_TLS_NOT_AVAILABLE;
	} else if (g_error_matches (op_error, SOUP_HTTP_ERROR, SOUP_STATUS_UNAUTHORIZED) ||
		   g_error_matches (op_error, SOUP_HTTP_ERROR, SOUP_STATUS_FORBIDDEN)) {
		op_error->domain = E_DATA_BOOK_ERROR;
		op_error->code = E_DATA_BOOK_STATUS_AUTHENTICATION_REQUIRED;

		if (webdav) {
			ENamedParameters *credentials;

			credentials = e_soup_session_dup_credentials (E_SOUP_SESSION (webdav));
			if (credentials && e_named_parameters_count (credentials) > 0)
				op_error->code = E_DATA_BOOK_STATUS_AUTHENTICATION_FAILED;

			e_named_parameters_free (credentials);
		}
	}
}

static gboolean
ebb_carddav_get_changes_sync (EBookMetaBackend *meta_backend,
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
	EBookBackendCardDAV *bbdav;
	EWebDAVSession *webdav;
	EXmlDocument *xml;
	GHashTable *known_items; /* gchar *href ~> EBookMetaBackendInfo * */
	GHashTableIter iter;
	gpointer key = NULL, value = NULL;
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (meta_backend), FALSE);
	g_return_val_if_fail (out_new_sync_tag, FALSE);
	g_return_val_if_fail (out_created_objects, FALSE);
	g_return_val_if_fail (out_modified_objects, FALSE);
	g_return_val_if_fail (out_removed_objects, FALSE);

	*out_new_sync_tag = NULL;
	*out_created_objects = NULL;
	*out_modified_objects = NULL;
	*out_removed_objects = NULL;

	bbdav = E_BOOK_BACKEND_CARDDAV (meta_backend);
	webdav = ebb_carddav_ref_session (bbdav);

	if (bbdav->priv->ctag_supported) {
		gchar *new_sync_tag = NULL;

		success = e_webdav_session_getctag_sync (webdav, NULL, &new_sync_tag, cancellable, NULL);
		if (!success) {
			bbdav->priv->ctag_supported = g_cancellable_set_error_if_cancelled (cancellable, error);
			if (bbdav->priv->ctag_supported || !webdav) {
				g_clear_object (&webdav);
				return FALSE;
			}
		} else if (new_sync_tag && last_sync_tag && g_strcmp0 (last_sync_tag, new_sync_tag) == 0) {
			*out_new_sync_tag = new_sync_tag;
			g_clear_object (&webdav);
			return TRUE;
		}

		*out_new_sync_tag = new_sync_tag;
	}

	xml = e_xml_document_new (E_WEBDAV_NS_DAV, "propfind");
	g_return_val_if_fail (xml != NULL, FALSE);

	e_xml_document_start_element (xml, NULL, "prop");
	e_xml_document_add_empty_element (xml, NULL, "getetag");
	e_xml_document_end_element (xml); /* prop */

	known_items = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, e_book_meta_backend_info_free);

	success = e_webdav_session_propfind_sync (webdav, NULL, E_WEBDAV_DEPTH_THIS_AND_CHILDREN, xml,
		ebb_carddav_get_contact_items_cb, known_items, cancellable, &local_error);

	g_object_unref (xml);

	if (success) {
		EBookCache *book_cache;
		CardDAVChangesData ccd;

		ccd.out_modified_objects = out_modified_objects;
		ccd.out_removed_objects = out_removed_objects;
		ccd.known_items = known_items;

		book_cache = e_book_meta_backend_ref_cache (meta_backend);

		success = e_book_cache_search_with_callback (book_cache, NULL, ebb_carddav_search_changes_cb, &ccd, cancellable, &local_error);

		g_clear_object (&book_cache);
	}

	if (success) {
		g_hash_table_iter_init (&iter, known_items);
		while (g_hash_table_iter_next (&iter, &key, &value)) {
			*out_created_objects = g_slist_prepend (*out_created_objects, e_book_meta_backend_info_copy (value));
		}
	}

	g_hash_table_destroy (known_items);

	if (success && (*out_created_objects || *out_modified_objects)) {
		GSList *link, *set2 = *out_modified_objects;

		if (*out_created_objects) {
			link = *out_created_objects;
		} else {
			link = set2;
			set2 = NULL;
		}

		do {
			success = ebb_carddav_multiget_from_sets_sync (bbdav, webdav, &link, &set2, cancellable, &local_error);
		} while (success && link);
	}

	if (local_error) {
		ebb_carddav_check_credentials_error (bbdav, webdav, local_error);
		g_propagate_error (error, local_error);
	}

	g_clear_object (&webdav);

	return success;
}

static gboolean
ebb_carddav_extract_existing_cb (EWebDAVSession *webdav,
				 xmlXPathContextPtr xpath_ctx,
				 const gchar *xpath_prop_prefix,
				 const SoupURI *request_uri,
				 const gchar *href,
				 guint status_code,
				 gpointer user_data)
{
	GSList **out_existing_objects = user_data;

	g_return_val_if_fail (out_existing_objects != NULL, FALSE);

	if (!xpath_prop_prefix) {
		e_xml_xpath_context_register_namespaces (xpath_ctx, "C", E_WEBDAV_NS_CARDDAV, NULL);
	} else if (status_code == SOUP_STATUS_OK) {
		gchar *etag;
		gchar *address_data;

		g_return_val_if_fail (href != NULL, FALSE);

		etag = e_xml_xpath_eval_as_string (xpath_ctx, "%s/D:getetag", xpath_prop_prefix);
		address_data = e_xml_xpath_eval_as_string (xpath_ctx, "%s/C:address-data", xpath_prop_prefix);

		if (address_data) {
			EContact *contact;

			contact = e_contact_new_from_vcard (address_data);
			if (contact) {
				const gchar *uid;

				uid = e_contact_get_const (contact, E_CONTACT_UID);

				if (uid) {
					etag = e_webdav_session_util_maybe_dequote (etag);
					*out_existing_objects = g_slist_prepend (*out_existing_objects,
						e_book_meta_backend_info_new (uid, etag, NULL, href));
				}

				g_object_unref (contact);
			}
		}

		g_free (address_data);
		g_free (etag);
	}

	return TRUE;
}

static gboolean
ebb_carddav_list_existing_sync (EBookMetaBackend *meta_backend,
				gchar **out_new_sync_tag,
				GSList **out_existing_objects,
				GCancellable *cancellable,
				GError **error)
{
	EBookBackendCardDAV *bbdav;
	EWebDAVSession *webdav;
	EXmlDocument *xml;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (meta_backend), FALSE);
	g_return_val_if_fail (out_existing_objects != NULL, FALSE);

	*out_existing_objects = NULL;

	bbdav = E_BOOK_BACKEND_CARDDAV (meta_backend);

	xml = e_xml_document_new (E_WEBDAV_NS_CARDDAV, "addressbook-query");
	g_return_val_if_fail (xml != NULL, FALSE);

	e_xml_document_add_namespaces (xml, "D", E_WEBDAV_NS_DAV, NULL);

	e_xml_document_start_element (xml, E_WEBDAV_NS_DAV, "prop");
	e_xml_document_add_empty_element (xml, E_WEBDAV_NS_DAV, "getetag");
	e_xml_document_start_element (xml, E_WEBDAV_NS_CARDDAV, "address-data");
	e_xml_document_start_element (xml, E_WEBDAV_NS_CARDDAV, "prop");
	e_xml_document_add_attribute (xml, NULL, "name", "VERSION");
	e_xml_document_end_element (xml); /* prop / VERSION */
	e_xml_document_start_element (xml, E_WEBDAV_NS_CARDDAV, "prop");
	e_xml_document_add_attribute (xml, NULL, "name", "UID");
	e_xml_document_end_element (xml); /* prop / UID */
	e_xml_document_end_element (xml); /* address-data */
	e_xml_document_end_element (xml); /* prop */

	webdav = ebb_carddav_ref_session (bbdav);

	success = e_webdav_session_report_sync (webdav, NULL, E_WEBDAV_DEPTH_THIS, xml,
		ebb_carddav_extract_existing_cb, out_existing_objects, NULL, NULL, cancellable, &local_error);

	g_object_unref (xml);

	if (success)
		*out_existing_objects = g_slist_reverse (*out_existing_objects);

	if (local_error) {
		ebb_carddav_check_credentials_error (bbdav, webdav, local_error);
		g_propagate_error (error, local_error);
	}

	g_clear_object (&webdav);

	return success;
}

static gchar *
ebb_carddav_uid_to_uri (EBookBackendCardDAV *bbdav,
		        const gchar *uid,
		        const gchar *extension)
{
	ESourceWebdav *webdav_extension;
	SoupURI *soup_uri;
	gchar *uri, *tmp, *filename, *uid_hash = NULL;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (bbdav), NULL);
	g_return_val_if_fail (uid != NULL, NULL);

	webdav_extension = e_source_get_extension (e_backend_get_source (E_BACKEND (bbdav)), E_SOURCE_EXTENSION_WEBDAV_BACKEND);
	soup_uri = e_source_webdav_dup_soup_uri (webdav_extension);
	g_return_val_if_fail (soup_uri != NULL, NULL);

	/* UIDs with forward slashes can cause trouble, because the destination server
	   can consider them as a path delimiter. For example Google book backend uses
	   URL as the contact UID. Double-encode the URL doesn't always work, thus
	   rather cause a mismatch between stored UID and its href on the server. */
	if (strchr (uid, '/')) {
		uid_hash = g_compute_checksum_for_string (G_CHECKSUM_SHA1, uid, -1);

		if (uid_hash)
			uid = uid_hash;
	}

	if (extension) {
		tmp = g_strconcat (uid, extension, NULL);
		filename = soup_uri_encode (tmp, NULL);
		g_free (tmp);
	} else {
		filename = soup_uri_encode (uid, NULL);
	}

	if (soup_uri->path) {
		gchar *slash = strrchr (soup_uri->path, '/');

		if (slash && !slash[1])
			*slash = '\0';
	}

	soup_uri_set_user (soup_uri, NULL);
	soup_uri_set_password (soup_uri, NULL);

	tmp = g_strconcat (soup_uri->path && *soup_uri->path ? soup_uri->path : "", "/", filename, NULL);
	soup_uri_set_path (soup_uri, tmp);
	g_free (tmp);

	uri = soup_uri_to_string (soup_uri, FALSE);

	soup_uri_free (soup_uri);
	g_free (filename);
	g_free (uid_hash);

	return uri;
}

static gboolean
ebb_carddav_load_contact_sync (EBookMetaBackend *meta_backend,
			       const gchar *uid,
			       const gchar *extra,
			       EContact **out_contact,
			       gchar **out_extra,
			       GCancellable *cancellable,
			       GError **error)
{
	EBookBackendCardDAV *bbdav;
	EWebDAVSession *webdav;
	gchar *uri = NULL, *href = NULL, *etag = NULL, *bytes = NULL;
	gsize length = -1;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (meta_backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (out_contact != NULL, FALSE);
	g_return_val_if_fail (out_extra != NULL, FALSE);

	bbdav = E_BOOK_BACKEND_CARDDAV (meta_backend);

	/* When called immediately after save and the server didn't change the vCard,
	   then the 'extra' contains "href" + "\n" + "vCard", to avoid unneeded GET
	   from the server. */
	if (extra && *extra) {
		const gchar *newline;

		newline = strchr (extra, '\n');
		if (newline && newline[1] && newline != extra) {
			EContact *contact;

			contact = e_contact_new_from_vcard (newline + 1);
			if (contact) {
				*out_extra = g_strndup (extra, newline - extra);
				*out_contact = contact;

				return TRUE;
			}
		}
	}

	webdav = ebb_carddav_ref_session (bbdav);

	if (extra && *extra) {
		uri = g_strdup (extra);

		success = e_webdav_session_get_data_sync (webdav, uri, &href, &etag, &bytes, &length, cancellable, &local_error);

		if (!success) {
			g_free (uri);
			uri = NULL;
		}
	}

	if (!success && bbdav->priv->ctag_supported) {
		gchar *new_sync_tag = NULL;

		if (e_webdav_session_getctag_sync (webdav, NULL, &new_sync_tag, cancellable, NULL) && new_sync_tag) {
			gchar *last_sync_tag;

			last_sync_tag = e_book_meta_backend_dup_sync_tag (meta_backend);

			/* The book didn't change, thus the contact cannot be there */
			if (g_strcmp0 (last_sync_tag, new_sync_tag) == 0) {
				g_clear_object (&webdav);
				g_clear_error (&local_error);
				g_free (last_sync_tag);
				g_free (new_sync_tag);

				g_propagate_error (error, EDB_ERROR (E_DATA_BOOK_STATUS_CONTACT_NOT_FOUND));

				return FALSE;
			}

			g_free (last_sync_tag);
		}

		g_free (new_sync_tag);
	}

	if (!success) {
		uri = ebb_carddav_uid_to_uri (bbdav, uid, bbdav->priv->is_google ? NULL : ".vcf");
		g_return_val_if_fail (uri != NULL, FALSE);

		g_clear_error (&local_error);

		success = e_webdav_session_get_data_sync (webdav, uri, &href, &etag, &bytes, &length, cancellable, &local_error);

		/* Do not try twice with Google, it's either without extension or not there.
		   The worst, it counts to the Error requests quota limit. */
		if (!success && !bbdav->priv->is_google && !g_cancellable_is_cancelled (cancellable) &&
		    g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_NOT_FOUND)) {
			g_free (uri);
			uri = ebb_carddav_uid_to_uri (bbdav, uid, NULL);

			if (uri) {
				g_clear_error (&local_error);

				success = e_webdav_session_get_data_sync (webdav, uri, &href, &etag, &bytes, &length, cancellable, &local_error);
			}
		}
	}

	if (success) {
		*out_contact = NULL;

		if (href && etag && bytes && length != ((gsize) -1)) {
			EContact *contact;

			contact = e_contact_new_from_vcard (bytes);
			if (contact) {
				e_vcard_util_set_x_attribute (E_VCARD (contact), E_WEBDAV_X_ETAG, etag);
				*out_contact = contact;
			}
		}

		if (!*out_contact) {
			success = FALSE;

			if (!href)
				g_propagate_error (&local_error, EDB_ERROR_EX (E_DATA_BOOK_STATUS_OTHER_ERROR, _("Server didn’t return object’s href")));
			else if (!etag)
				g_propagate_error (&local_error, EDB_ERROR_EX (E_DATA_BOOK_STATUS_OTHER_ERROR, _("Server didn’t return object’s ETag")));
			else
				g_propagate_error (&local_error, EDB_ERROR_EX (E_DATA_BOOK_STATUS_OTHER_ERROR, _("Received object is not a valid vCard")));
		} else if (out_extra) {
			*out_extra = g_strdup (href);
		}
	}

	g_free (uri);
	g_free (href);
	g_free (etag);
	g_free (bytes);

	if (local_error) {
		ebb_carddav_check_credentials_error (bbdav, webdav, local_error);
		g_propagate_error (error, local_error);
	}

	g_clear_object (&webdav);

	return success;
}

static gboolean
ebb_carddav_save_contact_sync (EBookMetaBackend *meta_backend,
			       gboolean overwrite_existing,
			       EConflictResolution conflict_resolution,
			       /* const */ EContact *contact,
			       const gchar *extra,
			       gchar **out_new_uid,
			       gchar **out_new_extra,
			       GCancellable *cancellable,
			       GError **error)
{
	EBookBackendCardDAV *bbdav;
	EWebDAVSession *webdav;
	gchar *href = NULL, *etag = NULL, *uid = NULL;
	gchar *vcard_string = NULL;
	GError *local_error = NULL;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (meta_backend), FALSE);
	g_return_val_if_fail (E_IS_CONTACT (contact), FALSE);
	g_return_val_if_fail (out_new_uid, FALSE);
	g_return_val_if_fail (out_new_extra, FALSE);

	bbdav = E_BOOK_BACKEND_CARDDAV (meta_backend);
	webdav = ebb_carddav_ref_session (bbdav);

	uid = e_contact_get (contact, E_CONTACT_UID);
	etag = e_vcard_util_dup_x_attribute (E_VCARD (contact), E_WEBDAV_X_ETAG);

	e_vcard_util_set_x_attribute (E_VCARD (contact), E_WEBDAV_X_ETAG, NULL);

	vcard_string = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);

	if (uid && vcard_string && (!overwrite_existing || (extra && *extra))) {
		gchar *new_extra = NULL, *new_etag = NULL;
		gboolean force_write = FALSE;

		if (!extra || !*extra)
			href = ebb_carddav_uid_to_uri (bbdav, uid, ".vcf");

		if (overwrite_existing) {
			switch (conflict_resolution) {
			case E_CONFLICT_RESOLUTION_FAIL:
			case E_CONFLICT_RESOLUTION_USE_NEWER:
			case E_CONFLICT_RESOLUTION_KEEP_SERVER:
			case E_CONFLICT_RESOLUTION_WRITE_COPY:
				break;
			case E_CONFLICT_RESOLUTION_KEEP_LOCAL:
				force_write = TRUE;
				break;
			}
		}

		success = e_webdav_session_put_data_sync (webdav, (extra && *extra) ? extra : href,
			force_write ? "" : overwrite_existing ? etag : NULL, E_WEBDAV_CONTENT_TYPE_VCARD,
			vcard_string, -1, &new_extra, &new_etag, cancellable, &local_error);

		if (success) {
			/* Only if both are returned and it's not a weak ETag */
			if (new_extra && *new_extra && new_etag && *new_etag &&
			    g_ascii_strncasecmp (new_etag, "W/", 2) != 0) {
				gchar *tmp;

				e_vcard_util_set_x_attribute (E_VCARD (contact), E_WEBDAV_X_ETAG, new_etag);

				g_free (vcard_string);
				vcard_string = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);

				/* Encodes the href and the vCard into one string, which
				   will be decoded in the load function */
				tmp = g_strconcat (new_extra, "\n", vcard_string, NULL);
				g_free (new_extra);
				new_extra = tmp;
			}

			/* To read the vCard back, either from the new_extra
			   or from the server, because the server could change it */
			*out_new_uid = g_strdup (uid);

			if (out_new_extra)
				*out_new_extra = new_extra;
			else
				g_free (new_extra);
		}

		g_free (new_etag);
	} else if (uid && vcard_string) {
		success = FALSE;
		g_propagate_error (error, EDB_ERROR_EX (E_DATA_BOOK_STATUS_OTHER_ERROR, _("Missing information about vCard URL, local cache is possibly incomplete or broken. Remove it, please.")));
	} else {
		success = FALSE;
		g_propagate_error (error, EDB_ERROR_EX (E_DATA_BOOK_STATUS_OTHER_ERROR, _("Object to save is not a valid vCard")));
	}

	g_free (vcard_string);
	g_free (href);
	g_free (etag);
	g_free (uid);

	if (local_error) {
		ebb_carddav_check_credentials_error (bbdav, webdav, local_error);
		g_propagate_error (error, local_error);
	}

	g_clear_object (&webdav);

	return success;
}

static gboolean
ebb_carddav_remove_contact_sync (EBookMetaBackend *meta_backend,
				 EConflictResolution conflict_resolution,
				 const gchar *uid,
				 const gchar *extra,
				 const gchar *object,
				 GCancellable *cancellable,
				 GError **error)
{
	EBookBackendCardDAV *bbdav;
	EWebDAVSession *webdav;
	EContact *contact;
	gchar *etag = NULL;
	gboolean success;
	GError *local_error = NULL;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (meta_backend), FALSE);
	g_return_val_if_fail (uid != NULL, FALSE);
	g_return_val_if_fail (object != NULL, FALSE);

	bbdav = E_BOOK_BACKEND_CARDDAV (meta_backend);

	if (!extra || !*extra) {
		g_propagate_error (error, EDB_ERROR (E_DATA_BOOK_STATUS_INVALID_ARG));
		return FALSE;
	}

	contact = e_contact_new_from_vcard (object);
	if (!contact) {
		g_propagate_error (error, EDB_ERROR (E_DATA_BOOK_STATUS_INVALID_ARG));
		return FALSE;
	}

	if (conflict_resolution == E_CONFLICT_RESOLUTION_FAIL)
		etag = e_vcard_util_dup_x_attribute (E_VCARD (contact), E_WEBDAV_X_ETAG);

	webdav = ebb_carddav_ref_session (bbdav);

	success = e_webdav_session_delete_sync (webdav, extra,
		NULL, etag, cancellable, &local_error);

	if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_NOT_FOUND)) {
		gchar *href;

		href = ebb_carddav_uid_to_uri (bbdav, uid, ".vcf");
		if (href) {
			g_clear_error (&local_error);
			success = e_webdav_session_delete_sync (webdav, href,
				NULL, etag, cancellable, &local_error);

			g_free (href);
		}

		if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_NOT_FOUND)) {
			href = ebb_carddav_uid_to_uri (bbdav, uid, NULL);
			if (href) {
				g_clear_error (&local_error);
				success = e_webdav_session_delete_sync (webdav, href,
					NULL, etag, cancellable, &local_error);

				g_free (href);
			}
		}
	}

	g_object_unref (contact);
	g_free (etag);

	/* Ignore not found errors, this was a delete and the resource is gone.
	   It can be that it had been deleted on the server by other application. */
	if (g_error_matches (local_error, SOUP_HTTP_ERROR, SOUP_STATUS_NOT_FOUND)) {
		g_clear_error (&local_error);
		success = TRUE;
	}

	if (local_error) {
		ebb_carddav_check_credentials_error (bbdav, webdav, local_error);
		g_propagate_error (error, local_error);
	}

	g_clear_object (&webdav);

	return success;
}

static gboolean
ebb_carddav_get_ssl_error_details (EBookMetaBackend *meta_backend,
				   gchar **out_certificate_pem,
				   GTlsCertificateFlags *out_certificate_errors)
{
	EBookBackendCardDAV *bbdav;
	EWebDAVSession *webdav;
	gboolean res;

	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (meta_backend), FALSE);

	bbdav = E_BOOK_BACKEND_CARDDAV (meta_backend);
	webdav = ebb_carddav_ref_session (bbdav);

	if (!webdav)
		return FALSE;

	res = e_soup_session_get_ssl_error_details (E_SOUP_SESSION (webdav), out_certificate_pem, out_certificate_errors);

	g_clear_object (&webdav);

	return res;
}

static gchar *
ebb_carddav_get_backend_property (EBookBackend *book_backend,
				  const gchar *prop_name)
{
	g_return_val_if_fail (E_IS_BOOK_BACKEND_CARDDAV (book_backend), NULL);
	g_return_val_if_fail (prop_name != NULL, NULL);

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CAPABILITIES)) {
		return g_strjoin (",",
			"net",
			"do-initial-query",
			"contact-lists",
			e_book_meta_backend_get_capabilities (E_BOOK_META_BACKEND (book_backend)),
			NULL);
	}

	/* Chain up to parent's method. */
	return E_BOOK_BACKEND_CLASS (e_book_backend_carddav_parent_class)->get_backend_property (book_backend, prop_name);
}

static gchar *
ebb_carddav_dup_contact_revision_cb (EBookCache *book_cache,
				     EContact *contact)
{
	g_return_val_if_fail (E_IS_CONTACT (contact), NULL);

	return e_vcard_util_dup_x_attribute (E_VCARD (contact), E_WEBDAV_X_ETAG);
}

static void
e_book_backend_carddav_constructed (GObject *object)
{
	EBookBackendCardDAV *bbdav = E_BOOK_BACKEND_CARDDAV (object);
	EBookCache *book_cache;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_book_backend_carddav_parent_class)->constructed (object);

	book_cache = e_book_meta_backend_ref_cache (E_BOOK_META_BACKEND (bbdav));

	g_signal_connect (book_cache, "dup-contact-revision",
		G_CALLBACK (ebb_carddav_dup_contact_revision_cb), NULL);

	g_clear_object (&book_cache);
}

static void
e_book_backend_carddav_dispose (GObject *object)
{
	EBookBackendCardDAV *bbdav = E_BOOK_BACKEND_CARDDAV (object);

	g_mutex_lock (&bbdav->priv->webdav_lock);
	g_clear_object (&bbdav->priv->webdav);
	g_mutex_unlock (&bbdav->priv->webdav_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_book_backend_carddav_parent_class)->dispose (object);
}

static void
e_book_backend_carddav_finalize (GObject *object)
{
	EBookBackendCardDAV *bbdav = E_BOOK_BACKEND_CARDDAV (object);

	g_mutex_clear (&bbdav->priv->webdav_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_book_backend_carddav_parent_class)->finalize (object);
}

static void
e_book_backend_carddav_init (EBookBackendCardDAV *bbdav)
{
	bbdav->priv = G_TYPE_INSTANCE_GET_PRIVATE (bbdav, E_TYPE_BOOK_BACKEND_CARDDAV, EBookBackendCardDAVPrivate);

	g_mutex_init (&bbdav->priv->webdav_lock);
}

static void
e_book_backend_carddav_class_init (EBookBackendCardDAVClass *klass)
{
	GObjectClass *object_class;
	EBookBackendClass *book_backend_class;
	EBookMetaBackendClass *book_meta_backend_class;

	g_type_class_add_private (klass, sizeof (EBookBackendCardDAVPrivate));

	book_meta_backend_class = E_BOOK_META_BACKEND_CLASS (klass);
	book_meta_backend_class->backend_module_filename = "libebookbackendcarddav.so";
	book_meta_backend_class->backend_factory_type_name = "EBookBackendCardDAVFactory";
	book_meta_backend_class->connect_sync = ebb_carddav_connect_sync;
	book_meta_backend_class->disconnect_sync = ebb_carddav_disconnect_sync;
	book_meta_backend_class->get_changes_sync = ebb_carddav_get_changes_sync;
	book_meta_backend_class->list_existing_sync = ebb_carddav_list_existing_sync;
	book_meta_backend_class->load_contact_sync = ebb_carddav_load_contact_sync;
	book_meta_backend_class->save_contact_sync = ebb_carddav_save_contact_sync;
	book_meta_backend_class->remove_contact_sync = ebb_carddav_remove_contact_sync;
	book_meta_backend_class->get_ssl_error_details = ebb_carddav_get_ssl_error_details;

	book_backend_class = E_BOOK_BACKEND_CLASS (klass);
	book_backend_class->get_backend_property = ebb_carddav_get_backend_property;

	object_class = G_OBJECT_CLASS (klass);
	object_class->constructed = e_book_backend_carddav_constructed;
	object_class->dispose = e_book_backend_carddav_dispose;
	object_class->finalize = e_book_backend_carddav_finalize;
}
