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
 * Authors: Not Zed <notzed@lostzed.mmc.com.au>
 */

#ifndef CAMEL_MAILDIR_SUMMARY_H
#define CAMEL_MAILDIR_SUMMARY_H

#include "camel-maildir-message-info.h"
#include "camel-local-summary.h"

/* Standard GObject macros */
#define CAMEL_TYPE_MAILDIR_SUMMARY \
	(camel_maildir_summary_get_type ())
#define CAMEL_MAILDIR_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MAILDIR_SUMMARY, CamelMaildirSummary))
#define CAMEL_MAILDIR_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MAILDIR_SUMMARY, CamelMaildirSummaryClass))
#define CAMEL_IS_MAILDIR_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MAILDIR_SUMMARY))
#define CAMEL_IS_MAILDIR_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MAILDIR_SUMMARY))
#define CAMEL_MAILDIR_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MAILDIR_SUMMARY, CamelMaildirSummaryClass))

#ifdef G_OS_WIN32
#define CAMEL_MAILDIR_FLAG_SEP '!'
#define CAMEL_MAILDIR_FLAG_SEP_S "!"
#else
#define CAMEL_MAILDIR_FLAG_SEP ':'
#define CAMEL_MAILDIR_FLAG_SEP_S ":"
#endif

G_BEGIN_DECLS

typedef struct _CamelMaildirSummary CamelMaildirSummary;
typedef struct _CamelMaildirSummaryClass CamelMaildirSummaryClass;
typedef struct _CamelMaildirSummaryPrivate CamelMaildirSummaryPrivate;

struct _CamelMaildirSummary {
	CamelLocalSummary parent;
	CamelMaildirSummaryPrivate *priv;
};

struct _CamelMaildirSummaryClass {
	CamelLocalSummaryClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType	 camel_maildir_summary_get_type	(void);
CamelMaildirSummary	*camel_maildir_summary_new	(struct _CamelFolder *folder, const gchar *maildirdir, CamelIndex *index);

/* convert some info->flags to/from the messageinfo */
gchar *camel_maildir_summary_info_to_name (const CamelMessageInfo *info);
gchar *camel_maildir_summary_uid_and_flags_to_name (const gchar *uid, guint32 flags);
gboolean camel_maildir_summary_name_to_info (CamelMessageInfo *info, const gchar *name);

G_END_DECLS

#endif /* CAMEL_MAILDIR_SUMMARY_H */
