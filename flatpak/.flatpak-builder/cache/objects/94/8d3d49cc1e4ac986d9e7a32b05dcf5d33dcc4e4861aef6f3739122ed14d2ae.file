/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-nntp-store.h : class for an nntp store
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
 */

#ifndef CAMEL_NNTP_STORE_H
#define CAMEL_NNTP_STORE_H

#include <camel/camel.h>

#include "camel-nntp-stream.h"
#include "camel-nntp-store-summary.h"

/* Standard GObject macros */
#define CAMEL_TYPE_NNTP_STORE \
	(camel_nntp_store_get_type ())
#define CAMEL_NNTP_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_NNTP_STORE, CamelNNTPStore))
#define CAMEL_NNTP_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_NNTP_STORE, CamelNNTPStoreClass))
#define CAMEL_IS_NNTP_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_NNTP_STORE))
#define CAMEL_IS_NNTP_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_NNTP_STORE))
#define CAMEL_NNTP_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_NNTP_STORE, CamelNNTPStoreClass))

G_BEGIN_DECLS

struct _CamelNNTPFolder;

typedef struct _CamelNNTPStore CamelNNTPStore;
typedef struct _CamelNNTPStoreClass CamelNNTPStoreClass;
typedef struct _CamelNNTPStorePrivate CamelNNTPStorePrivate;

typedef enum _xover_t {
	XOVER_STRING = 0,
	XOVER_MSGID,
	XOVER_SIZE
} xover_t;

struct _xover_header {
	struct _xover_header *next;

	const gchar *name;
	guint skip : 8;
	xover_t type : 8;
};

/* names of supported capabilities on the server */
typedef enum {
	CAMEL_NNTP_CAPABILITY_OVER = 1 << 0,  /* supports OVER command */
	CAMEL_NNTP_CAPABILITY_STARTTLS = 1 << 1  /* supports STARTTLS */
} CamelNNTPCapabilities;

struct _CamelNNTPStore {
	CamelOfflineStore parent;
	CamelNNTPStorePrivate *priv;

	struct _xover_header *xover;
};

struct _CamelNNTPStoreClass {
	CamelOfflineStoreClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_nntp_store_get_type	(void);
CamelDataCache *
		camel_nntp_store_ref_cache	(CamelNNTPStore *nntp_store);
CamelNNTPStream *
		camel_nntp_store_ref_stream	(CamelNNTPStore *nntp_store);
CamelNNTPStoreSummary *
		camel_nntp_store_ref_summary	(CamelNNTPStore *nntp_store);
const gchar *	camel_nntp_store_get_current_group
						(CamelNNTPStore *nntp_store);
gchar *		camel_nntp_store_dup_current_group
						(CamelNNTPStore *nntp_store);
void		camel_nntp_store_set_current_group
						(CamelNNTPStore *nntp_store,
						 const gchar *current_group);
void		camel_nntp_store_add_capabilities
						(CamelNNTPStore *nntp_store,
						 CamelNNTPCapabilities caps);
gboolean	camel_nntp_store_has_capabilities
						(CamelNNTPStore *nntp_store,
						 CamelNNTPCapabilities caps);
void		camel_nntp_store_remove_capabilities
						(CamelNNTPStore *nntp_store,
						 CamelNNTPCapabilities caps);
gint		camel_nntp_raw_commandv		(CamelNNTPStore *nntp_store,
						 GCancellable *cancellable,
						 GError **error,
						 gchar **line,
						 const gchar *fmt,
						 va_list ap);
gint		camel_nntp_raw_command		(CamelNNTPStore *nntp_store,
						 GCancellable *cancellable,
						 GError **error,
						 gchar **line,
						 const gchar *fmt,
						 ...);
gint		camel_nntp_raw_command_auth	(CamelNNTPStore *nntp_store,
						 GCancellable *cancellable,
						 GError **error,
						 gchar **line,
						 const gchar *fmt,
						 ...);
gint		camel_nntp_command		(CamelNNTPStore *nntp_store,
						 GCancellable *cancellable,
						 GError **error,
						 struct _CamelNNTPFolder *folder,
						 CamelNNTPStream **out_nntp_stream,
						 gchar **line,
						 const gchar *fmt,
						 ...);

G_END_DECLS

#endif /* CAMEL_NNTP_STORE_H */

