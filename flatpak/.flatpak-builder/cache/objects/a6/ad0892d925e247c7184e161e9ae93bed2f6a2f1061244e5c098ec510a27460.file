/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2016 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_VEE_MESSAGE_INFO_H
#define CAMEL_VEE_MESSAGE_INFO_H

#include <glib-object.h>

#include <camel/camel-message-info.h>

/* Standard GObject macros */
#define CAMEL_TYPE_VEE_MESSAGE_INFO \
	(camel_vee_message_info_get_type ())
#define CAMEL_VEE_MESSAGE_INFO(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_VEE_MESSAGE_INFO, CamelVeeMessageInfo))
#define CAMEL_VEE_MESSAGE_INFO_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_VEE_MESSAGE_INFO, CamelVeeMessageInfoClass))
#define CAMEL_IS_VEE_MESSAGE_INFO(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_VEE_MESSAGE_INFO))
#define CAMEL_IS_VEE_MESSAGE_INFO_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_VEE_MESSAGE_INFO))
#define CAMEL_VEE_MESSAGE_INFO_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_VEE_MESSAGE_INFO, CamelVeeMessageInfoClass))

G_BEGIN_DECLS

typedef struct _CamelVeeMessageInfo CamelVeeMessageInfo;
typedef struct _CamelVeeMessageInfoClass CamelVeeMessageInfoClass;
typedef struct _CamelVeeMessageInfoPrivate CamelVeeMessageInfoPrivate;

struct _CamelVeeMessageInfo {
	CamelMessageInfo parent;
	CamelVeeMessageInfoPrivate *priv;
};

struct _CamelVeeMessageInfoClass {
	CamelMessageInfoClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_vee_message_info_get_type	(void);
CamelMessageInfo *
		camel_vee_message_info_new	(CamelFolderSummary *summary,
						 CamelFolderSummary *original_summary,
						 const gchar *vuid);
CamelFolderSummary *
		camel_vee_message_info_get_original_summary
						(const CamelVeeMessageInfo *vmi);
CamelFolder *
		camel_vee_message_info_get_original_folder
						(const CamelVeeMessageInfo *vmi);

G_END_DECLS

#endif /* CAMEL_VEE_MESSAGE_INFO_H */
