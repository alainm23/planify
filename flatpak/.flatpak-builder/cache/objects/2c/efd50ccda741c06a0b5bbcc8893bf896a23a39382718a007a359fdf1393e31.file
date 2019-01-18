/*
 * camel-imapx-store-summary.h
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

#ifndef CAMEL_IMAPX_STORE_SUMMARY_H
#define CAMEL_IMAPX_STORE_SUMMARY_H

#include <camel/camel.h>

#include "camel-imapx-mailbox.h"

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_STORE_SUMMARY \
	(camel_imapx_store_summary_get_type ())
#define CAMEL_IMAPX_STORE_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_STORE_SUMMARY, CamelIMAPXStoreSummary))
#define CAMEL_IMAPX_STORE_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_STORE_SUMMARY, CamelIMAPXStoreSummaryClass))
#define CAMEL_IS_IMAPX_STORE_SUMMARY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_STORE_SUMMARY))
#define CAMEL_IS_IMAPX_STORE_SUMMARY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_STORE_SUMMARY))
#define CAMEL_IMAPX_STORE_SUMMARY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_STORE_SUMMARY, CamelIMAPXStoreSummaryClass))

G_BEGIN_DECLS

typedef struct _CamelIMAPXStoreSummary CamelIMAPXStoreSummary;
typedef struct _CamelIMAPXStoreSummaryClass CamelIMAPXStoreSummaryClass;

typedef struct _CamelIMAPXStoreInfo CamelIMAPXStoreInfo;

struct _CamelIMAPXStoreInfo {
	CamelStoreInfo info;
	gchar *mailbox_name;
	gchar separator;
};

struct _CamelIMAPXStoreSummary {
	CamelStoreSummary parent;
};

struct _CamelIMAPXStoreSummaryClass {
	CamelStoreSummaryClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_store_summary_get_type
						(void) G_GNUC_CONST;
CamelIMAPXStoreInfo *
		camel_imapx_store_summary_mailbox
						(CamelStoreSummary *summary,
						 const gchar *mailbox_name);
CamelIMAPXStoreInfo *
		camel_imapx_store_summary_add_from_mailbox
						(CamelStoreSummary *summary,
						 CamelIMAPXMailbox *mailbox);

G_END_DECLS

#endif /* CAMEL_IMAP_STORE_SUMMARY_H */
