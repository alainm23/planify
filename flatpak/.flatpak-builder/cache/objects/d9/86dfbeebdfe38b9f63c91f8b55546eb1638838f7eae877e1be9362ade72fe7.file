/*
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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#ifndef CAMEL_LOCAL_SUMMARY_H
#define CAMEL_LOCAL_SUMMARY_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_LOCAL_SUMMARY \
	(camel_local_summary_get_type ())
#define CAMEL_LOCAL_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_LOCAL_SUMMARY, CamelLocalSummary))
#define CAMEL_LOCAL_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_LOCAL_SUMMARY, CamelLocalSummaryClass))
#define CAMEL_IS_LOCAL_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_LOCAL_SUMMARY))
#define CAMEL_IS_LOCAL_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_LOCAL_SUMMARY))
#define CAMEL_LOCAL_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_LOCAL_SUMMARY, CamelLocalSummaryClass))

G_BEGIN_DECLS

typedef struct _CamelLocalSummary      CamelLocalSummary;
typedef struct _CamelLocalSummaryClass CamelLocalSummaryClass;

/* extra summary flags */
enum {
	CAMEL_MESSAGE_FOLDER_NOXEV = 1 << 17,
	CAMEL_MESSAGE_FOLDER_XEVCHANGE = 1 << 18,
	CAMEL_MESSAGE_FOLDER_NOTSEEN = 1 << 19 /* have we seen this in processing this loop? */
};

struct _CamelLocalSummary {
	CamelFolderSummary parent;

	guint32 version;	/* file version being loaded */

	gchar *folder_path;	/* name of matching folder */

	CamelIndex *index;
	guint index_force:1; /* do we force index during creation? */
	guint check_force:1; /* does a check force a full check? */
};

struct _CamelLocalSummaryClass {
	CamelFolderSummaryClass parent_class;

	gboolean (*load)(CamelLocalSummary *cls, gint forceindex, GError **error);
	gint (*check)(CamelLocalSummary *cls, CamelFolderChangeInfo *changeinfo, GCancellable *cancellable, GError **error);
	gint (*sync)(CamelLocalSummary *cls, gboolean expunge, CamelFolderChangeInfo *changeinfo, GCancellable *cancellable, GError **error);
	CamelMessageInfo *(*add)(CamelLocalSummary *cls, CamelMimeMessage *msg, const CamelMessageInfo *info, CamelFolderChangeInfo *, GError **error);

	gchar *(*encode_x_evolution)(CamelLocalSummary *cls, const CamelMessageInfo *info);
	gint (*decode_x_evolution)(CamelLocalSummary *cls, const gchar *xev, CamelMessageInfo *info);
	gint (*need_index)(void);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType	camel_local_summary_get_type	(void);
void	camel_local_summary_construct	(CamelLocalSummary *new, const gchar *local_name, CamelIndex *index);

/* load/check the summary */
gboolean camel_local_summary_load (CamelLocalSummary *cls, gint forceindex, GError **error);
/* check for new/removed messages */
gint camel_local_summary_check (CamelLocalSummary *cls, CamelFolderChangeInfo *, GCancellable *cancellable, GError **error);
/* perform a folder sync or expunge, if needed */
gint camel_local_summary_sync (CamelLocalSummary *cls, gboolean expunge, CamelFolderChangeInfo *, GCancellable *cancellable, GError **error);
/* add a new message to the summary */
CamelMessageInfo *camel_local_summary_add (CamelLocalSummary *cls, CamelMimeMessage *msg, const CamelMessageInfo *info, CamelFolderChangeInfo *, GError **error);

/* force the next check to be a full check/rebuild */
void camel_local_summary_check_force (CamelLocalSummary *cls);

/* generate an X-Evolution header line */
gchar *camel_local_summary_encode_x_evolution (CamelLocalSummary *cls, const CamelMessageInfo *info);
gint camel_local_summary_decode_x_evolution (CamelLocalSummary *cls, const gchar *xev, CamelMessageInfo *info);

/* utility functions - write headers to a file with optional X-Evolution header and/or status header */
gint camel_local_summary_write_headers (gint fd, CamelNameValueArray *headers, const gchar *xevline, const gchar *status, const gchar *xstatus);

G_END_DECLS

#endif /* CAMEL_LOCAL_SUMMARY_H */
