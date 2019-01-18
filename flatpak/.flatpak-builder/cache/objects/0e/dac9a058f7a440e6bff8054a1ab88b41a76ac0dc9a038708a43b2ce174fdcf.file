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

#ifndef CAMEL_MBOX_SUMMARY_H
#define CAMEL_MBOX_SUMMARY_H

#include "camel-local-summary.h"

/* Standard GObject macros */
#define CAMEL_TYPE_MBOX_SUMMARY \
	(camel_mbox_summary_get_type ())
#define CAMEL_MBOX_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MBOX_SUMMARY, CamelMboxSummary))
#define CAMEL_MBOX_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MBOX_SUMMARY, CamelMboxSummaryClass))
#define CAMEL_IS_MBOX_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MBOX_SUMMARY))
#define CAMEL_IS_MBOX_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MBOX_SUMMARY))
#define CAMEL_MBOX_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MBOX_SUMMARY, CamelMboxSummaryClass))

G_BEGIN_DECLS

typedef struct _CamelMboxSummary CamelMboxSummary;
typedef struct _CamelMboxSummaryClass CamelMboxSummaryClass;

struct _CamelMboxSummary {
	CamelLocalSummary parent;

	CamelFolderChangeInfo *changes;	/* used to build change sets */

	guint32 version;
	gsize folder_size;	/* size of the mbox file, last sync */

	guint xstatus:1;	/* do we store/honour xstatus/status headers */
};

struct _CamelMboxSummaryClass {
	CamelLocalSummaryClass parent_class;

	/* sync in-place */
	gint		(*sync_quick)		(CamelMboxSummary *cls,
						 gboolean expunge,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);

	/* sync requires copy */
	gint		(*sync_full)		(CamelMboxSummary *cls,
						 gboolean expunge,
						 CamelFolderChangeInfo *changeinfo,
						 GCancellable *cancellable,
						 GError **error);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mbox_summary_get_type	(void);
CamelMboxSummary *
		camel_mbox_summary_new		(CamelFolder *folder,
						 const gchar *mbox_name,
						 CamelIndex *index);

/* do we honor/use xstatus headers, etc */
void		camel_mbox_summary_xstatus	(CamelMboxSummary *mbs,
						 gint state);

/* build a new mbox from an existing mbox storing summary information */
gint		camel_mbox_summary_sync_mbox	(CamelMboxSummary *cls,
						 guint32 flags,
						 CamelFolderChangeInfo *changeinfo,
						 gint fd,
						 gint fdout,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_MBOX_SUMMARY_H */
