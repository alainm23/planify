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
 *          Dan Winship <danw@ximian.com>
 */

#ifndef CAMEL_IMAPX_SUMMARY_H
#define CAMEL_IMAPX_SUMMARY_H

#include <camel/camel.h>

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_SUMMARY \
	(camel_imapx_summary_get_type ())
#define CAMEL_IMAPX_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_SUMMARY, CamelIMAPXSummary))
#define CAMEL_IMAPX_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_SUMMARY, CamelIMAPXSummaryClass))
#define CAMEL_IS_IMAPX_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_SUMMARY))
#define CAMEL_IS_IMAPX_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_SUMMARY))
#define CAMEL_IMAPX_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_SUMMARY, CamelIMAPXSummaryClass))

#define CAMEL_IMAPX_SERVER_FLAGS \
	(CAMEL_MESSAGE_ANSWERED | \
	 CAMEL_MESSAGE_DELETED | \
	 CAMEL_MESSAGE_DRAFT | \
	 CAMEL_MESSAGE_FLAGGED | \
	 CAMEL_MESSAGE_JUNK | \
	 CAMEL_MESSAGE_NOTJUNK | \
	 CAMEL_MESSAGE_SEEN)

G_BEGIN_DECLS

typedef struct _CamelIMAPXSummary CamelIMAPXSummary;
typedef struct _CamelIMAPXSummaryClass CamelIMAPXSummaryClass;

struct _CamelIMAPXSummary {
	CamelFolderSummary parent;

	guint32 version;
	guint32 uidnext;
	guint64 validity;
	guint64 modseq;
};

struct _CamelIMAPXSummaryClass {
	CamelFolderSummaryClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_summary_get_type	(void);
CamelFolderSummary *
		camel_imapx_summary_new		(CamelFolder *folder);

G_END_DECLS

#endif /* CAMEL_IMAPX_SUMMARY_H */
