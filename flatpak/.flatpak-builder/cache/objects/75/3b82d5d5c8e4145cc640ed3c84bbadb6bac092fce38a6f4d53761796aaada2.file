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

#ifndef CAMEL_SPOOL_SUMMARY_H
#define CAMEL_SPOOL_SUMMARY_H

#include <camel/camel.h>

#include "camel-mbox-summary.h"

/* Standard GObject macros */
#define CAMEL_TYPE_SPOOL_SUMMARY \
	(camel_spool_summary_get_type ())
#define CAMEL_SPOOL_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SPOOL_SUMMARY, CamelSpoolSummary))
#define CAMEL_SPOOL_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SPOOL_SUMMARY, CamelSpoolSummaryClass))
#define CAMEL_IS_SPOOL_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SPOOL_SUMMARY))
#define CAMEL_IS_SPOOL_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SPOOL_SUMMARY))
#define CAMEL_SPOOL_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SPOOL_SUMMARY, CamelSpoolSummaryClass))

G_BEGIN_DECLS

typedef struct _CamelSpoolSummary CamelSpoolSummary;
typedef struct _CamelSpoolSummaryClass CamelSpoolSummaryClass;

struct _CamelSpoolSummary {
	CamelMboxSummary parent;
};

struct _CamelSpoolSummaryClass {
	CamelMboxSummaryClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType	camel_spool_summary_get_type	(void);
void	camel_spool_summary_construct	(CamelSpoolSummary *new, const gchar *filename, const gchar *spool_name, CamelIndex *index);

/* create the summary, in-memory only */
CamelSpoolSummary *camel_spool_summary_new (struct _CamelFolder *, const gchar *filename);

/* load/check the summary */
gint camel_spool_summary_load (CamelSpoolSummary *cls, gint forceindex, GError **error);
/* check for new/removed messages */
gint camel_spool_summary_check (CamelSpoolSummary *cls, CamelFolderChangeInfo *, GError **error);
/* perform a folder sync or expunge, if needed */
gint camel_spool_summary_sync (CamelSpoolSummary *cls, gboolean expunge, CamelFolderChangeInfo *, GError **error);
/* add a new message to the summary */
CamelMessageInfo *camel_spool_summary_add (CamelSpoolSummary *cls, CamelMimeMessage *msg, const CamelMessageInfo *info, CamelFolderChangeInfo *, GError **error);

/* generate an X-Evolution header line */
gchar *camel_spool_summary_encode_x_evolution (CamelSpoolSummary *cls, const CamelMessageInfo *info);
gint camel_spool_summary_decode_x_evolution (CamelSpoolSummary *cls, const gchar *xev, CamelMessageInfo *info);

G_END_DECLS

#endif /* CAMEL_SPOOL_SUMMARY_H */
