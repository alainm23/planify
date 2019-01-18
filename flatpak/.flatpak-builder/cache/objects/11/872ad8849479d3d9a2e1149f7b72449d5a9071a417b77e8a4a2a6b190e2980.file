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

#ifndef CAMEL_MH_SUMMARY_H
#define CAMEL_MH_SUMMARY_H

#include "camel-local-summary.h"

/* Standard GObject macros */
#define CAMEL_TYPE_MH_SUMMARY \
	(camel_mh_summary_get_type ())
#define CAMEL_MH_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MH_SUMMARY, CamelMhSummary))
#define CAMEL_MH_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MH_SUMMARY, CamelMhSummaryClass))
#define CAMEL_IS_MH_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MH_SUMMARY))
#define CAMEL_IS_MH_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MH_SUMMARY))
#define CAMEL_MH_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MH_SUMMARY, CamelMhSummaryClass))

G_BEGIN_DECLS

typedef struct _CamelMhSummary	CamelMhSummary;
typedef struct _CamelMhSummaryClass CamelMhSummaryClass;
typedef struct _CamelMhSummaryPrivate CamelMhSummaryPrivate;

struct _CamelMhSummary {
	CamelLocalSummary parent;
	CamelMhSummaryPrivate *priv;
};

struct _CamelMhSummaryClass {
	CamelLocalSummaryClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_mh_summary_get_type	(void);
CamelMhSummary *
		camel_mh_summary_new		(CamelFolder *folder,
						 const gchar *mhdir,
						 CamelIndex *index);

G_END_DECLS

#endif /* CAMEL_MH_SUMMARY_H */
