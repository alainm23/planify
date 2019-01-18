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

#ifndef E_SECRET_STORE_H
#define E_SECRET_STORE_H

#include <glib.h>
#include <gio/gio.h>

G_BEGIN_DECLS

gboolean	e_secret_store_store_sync	(const gchar *uid,
						 const gchar *secret,
						 const gchar *label,
						 gboolean permanently,
						 GCancellable *cancellable,
						 GError **error);

gboolean	e_secret_store_lookup_sync	(const gchar *uid,
						 gchar **out_secret,
						 GCancellable *cancellable,
						 GError **error);

gboolean	e_secret_store_delete_sync	(const gchar *uid,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* E_SECRET_STORE_H */
