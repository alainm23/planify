/*
 * Copyright (C) 2015 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_WEBDAV_DISCOVER_H
#define E_WEBDAV_DISCOVER_H

#include <glib.h>

#include <libedataserver/e-source.h>
#include <libedataserver/e-webdav-session.h>

G_BEGIN_DECLS

typedef enum {
	E_WEBDAV_DISCOVER_SUPPORTS_NONE			  = E_WEBDAV_RESOURCE_SUPPORTS_NONE,
	E_WEBDAV_DISCOVER_SUPPORTS_CONTACTS		  = E_WEBDAV_RESOURCE_SUPPORTS_CONTACTS,
	E_WEBDAV_DISCOVER_SUPPORTS_EVENTS		  = E_WEBDAV_RESOURCE_SUPPORTS_EVENTS,
	E_WEBDAV_DISCOVER_SUPPORTS_MEMOS		  = E_WEBDAV_RESOURCE_SUPPORTS_MEMOS,
	E_WEBDAV_DISCOVER_SUPPORTS_TASKS		  = E_WEBDAV_RESOURCE_SUPPORTS_TASKS,
	E_WEBDAV_DISCOVER_SUPPORTS_CALENDAR_AUTO_SCHEDULE = E_WEBDAV_RESOURCE_SUPPORTS_LAST << 1
} EWebDAVDiscoverSupports;

typedef struct _EWebDAVDiscoveredSource {
	gchar *href;
	guint32 supports;
	gchar *display_name;
	gchar *description;
	gchar *color;
} EWebDAVDiscoveredSource;

void		e_webdav_discover_free_discovered_sources
							(GSList *discovered_sources);

void		e_webdav_discover_sources		(ESource *source,
							 const gchar *url_use_path,
							 guint32 only_supports,
							 const ENamedParameters *credentials,
							 GCancellable *cancellable,
							 GAsyncReadyCallback callback,
							 gpointer user_data);

gboolean	e_webdav_discover_sources_finish	(ESource *source,
							 GAsyncResult *result,
							 gchar **out_certificate_pem,
							 GTlsCertificateFlags *out_certificate_errors,
							 GSList **out_discovered_sources,
							 GSList **out_calendar_user_addresses,
							 GError **error);

gboolean	e_webdav_discover_sources_sync		(ESource *source,
							 const gchar *url_use_path,
							 guint32 only_supports,
							 const ENamedParameters *credentials,
							 gchar **out_certificate_pem,
							 GTlsCertificateFlags *out_certificate_errors,
							 GSList **out_discovered_sources,
							 GSList **out_calendar_user_addresses,
							 GCancellable *cancellable,
							 GError **error);

/**
 * EWebDAVDiscoverRefSourceFunc:
 * @user_data: user data, as passed to e_webdav_discover_sources_full() or
 *     e_webdav_discover_sources_full_sync()
 * @uid: an #ESource UID to return
 *
 * Returns: (transfer full) (nullable): an #ESource with UID @uid, or %NULL, if not found.
 *    Dereference the returned non-NULL #ESource with g_object_unref(), when no longer needed.
 *
 * Since: 3.30
 **/
typedef ESource * (* EWebDAVDiscoverRefSourceFunc)	(gpointer user_data,
							 const gchar *uid);

void		e_webdav_discover_sources_full		(ESource *source,
							 const gchar *url_use_path,
							 guint32 only_supports,
							 const ENamedParameters *credentials,
							 EWebDAVDiscoverRefSourceFunc ref_source_func,
							 gpointer ref_source_func_user_data,
							 GCancellable *cancellable,
							 GAsyncReadyCallback callback,
							 gpointer user_data);

gboolean	e_webdav_discover_sources_full_sync	(ESource *source,
							 const gchar *url_use_path,
							 guint32 only_supports,
							 const ENamedParameters *credentials,
							 EWebDAVDiscoverRefSourceFunc ref_source_func,
							 gpointer ref_source_func_user_data,
							 gchar **out_certificate_pem,
							 GTlsCertificateFlags *out_certificate_errors,
							 GSList **out_discovered_sources,
							 GSList **out_calendar_user_addresses,
							 GCancellable *cancellable,
							 GError **error);

G_END_DECLS

#endif /* E_WEBDAV_DISCOVER_H */
