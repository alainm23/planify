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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_VEE_SUMMARY_H
#define CAMEL_VEE_SUMMARY_H

#include <camel/camel-folder-summary.h>
#include <camel/camel-vee-message-info.h>

/* Standard GObject macros */
#define CAMEL_TYPE_VEE_SUMMARY \
	(camel_vee_summary_get_type ())
#define CAMEL_VEE_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_VEE_SUMMARY, CamelVeeSummary))
#define CAMEL_VEE_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_VEE_SUMMARY, CamelVeeSummaryClass))
#define CAMEL_IS_VEE_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_VEE_SUMMARY))
#define CAMEL_IS_VEE_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_VEE_SUMMARY))
#define CAMEL_VEE_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_VEE_SUMMARY, CamelVeeSummaryClass))

G_BEGIN_DECLS

struct _CamelVeeMessageInfoData;
struct _CamelVeeFolder;
struct _CamelFolder;

typedef struct _CamelVeeSummary CamelVeeSummary;
typedef struct _CamelVeeSummaryClass CamelVeeSummaryClass;
typedef struct _CamelVeeSummaryPrivate CamelVeeSummaryPrivate;

struct _CamelVeeSummary {
	CamelFolderSummary parent;

	CamelVeeSummaryPrivate *priv;
};

struct _CamelVeeSummaryClass {
	CamelFolderSummaryClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_vee_summary_get_type	(void);
CamelFolderSummary *
		camel_vee_summary_new		(CamelFolder *parent);
CamelVeeMessageInfo *
		camel_vee_summary_add		(CamelVeeSummary *summary,
						 struct _CamelVeeMessageInfoData *mi_data);
void		camel_vee_summary_remove	(CamelVeeSummary *summary,
						 const gchar *vuid,
						 CamelFolder *subfolder);
void		camel_vee_summary_replace_flags	(CamelVeeSummary *summary,
						 const gchar *uid);
GHashTable *	camel_vee_summary_get_uids_for_subfolder
						(CamelVeeSummary *summary,
						 CamelFolder *subfolder);

G_END_DECLS

#endif /* CAMEL_VEE_SUMMARY_H */

