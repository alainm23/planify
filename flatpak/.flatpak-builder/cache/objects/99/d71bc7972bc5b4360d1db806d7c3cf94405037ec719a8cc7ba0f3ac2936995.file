/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2012 Red Hat, Inc. (www.redhat.com)
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
 * Authors: Milan Crha <mcrha@redhat.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_VEE_DATA_CACHE_H
#define CAMEL_VEE_DATA_CACHE_H

#include <camel/camel-folder.h>

/* Standard GObject macros */
#define CAMEL_TYPE_VEE_SUBFOLDER_DATA \
	(camel_vee_subfolder_data_get_type ())
#define CAMEL_VEE_SUBFOLDER_DATA(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_VEE_SUBFOLDER_DATA, CamelVeeSubfolderData))
#define CAMEL_VEE_SUBFOLDER_DATA_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_VEE_SUBFOLDER_DATA, CamelVeeSubfolderDataClass))
#define CAMEL_IS_VEE_SUBFOLDER_DATA(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_VEE_SUBFOLDER_DATA))
#define CAMEL_IS_VEE_SUBFOLDER_DATA_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_VEE_SUBFOLDER_DATA))
#define CAMEL_VEE_SUBFOLDER_DATA_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_VEE_SUBFOLDER_DATA, CamelVeeSubfolderDataClass))

#define CAMEL_TYPE_VEE_MESSAGE_INFO_DATA \
	(camel_vee_message_info_data_get_type ())
#define CAMEL_VEE_MESSAGE_INFO_DATA(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_VEE_MESSAGE_INFO_DATA, CamelVeeMessageInfoData))
#define CAMEL_VEE_MESSAGE_INFO_DATA_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_VEE_MESSAGE_INFO_DATA, CamelVeeMessageInfoDataClass))
#define CAMEL_IS_VEE_MESSAGE_INFO_DATA(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_VEE_MESSAGE_INFO_DATA))
#define CAMEL_IS_VEE_MESSAGE_INFO_DATA_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_VEE_MESSAGE_INFO_DATA))
#define CAMEL_VEE_MESSAGE_INFO_DATA_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_VEE_MESSAGE_INFO_DATA, CamelVeeMessageInfoDataClass))

#define CAMEL_TYPE_VEE_DATA_CACHE \
	(camel_vee_data_cache_get_type ())
#define CAMEL_VEE_DATA_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_VEE_DATA_CACHE, CamelVeeDataCache))
#define CAMEL_VEE_DATA_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_VEE_DATA_CACHE, CamelVeeDataCacheClass))
#define CAMEL_IS_VEE_DATA_CACHE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_VEE_DATA_CACHE))
#define CAMEL_IS_VEE_DATA_CACHE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_VEE_DATA_CACHE))
#define CAMEL_VEE_DATA_CACHE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_VEE_DATA_CACHE, CamelVeeDataCacheClass))

G_BEGIN_DECLS

typedef struct _CamelVeeSubfolderData CamelVeeSubfolderData;
typedef struct _CamelVeeSubfolderDataClass CamelVeeSubfolderDataClass;
typedef struct _CamelVeeSubfolderDataPrivate CamelVeeSubfolderDataPrivate;

typedef struct _CamelVeeMessageInfoData CamelVeeMessageInfoData;
typedef struct _CamelVeeMessageInfoDataClass CamelVeeMessageInfoDataClass;
typedef struct _CamelVeeMessageInfoDataPrivate CamelVeeMessageInfoDataPrivate;

typedef struct _CamelVeeDataCache CamelVeeDataCache;
typedef struct _CamelVeeDataCacheClass CamelVeeDataCacheClass;
typedef struct _CamelVeeDataCachePrivate CamelVeeDataCachePrivate;

/**
 * CamelForeachInfoData:
 * @mi_data: a #CamelVeeMessageInfoData
 * @subfolder: a #CamelFolder which @mi_data references
 * @user_data: custom user data
 *
 * A callback prototype for camel_vee_data_cache_foreach_message_info_data()
 **/
typedef void (*CamelForeachInfoData) (CamelVeeMessageInfoData *mi_data, CamelFolder *subfolder, gpointer user_data);

/**
 * CamelVeeSubfolderData:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _CamelVeeSubfolderData {
	/*< private >*/
	GObject parent;
	CamelVeeSubfolderDataPrivate *priv;
};

struct _CamelVeeSubfolderDataClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_vee_subfolder_data_get_type
						(void) G_GNUC_CONST;
CamelVeeSubfolderData *
		camel_vee_subfolder_data_new	(CamelFolder *folder);
CamelFolder *	camel_vee_subfolder_data_get_folder
						(CamelVeeSubfolderData *data);
const gchar *	camel_vee_subfolder_data_get_folder_id
						(CamelVeeSubfolderData *data);

/* ----------------------------------------------------------------------- */

/**
 * CamelVeeMessageInfoData:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _CamelVeeMessageInfoData {
	/*< private >*/
	GObject parent;
	CamelVeeMessageInfoDataPrivate *priv;
};

struct _CamelVeeMessageInfoDataClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_vee_message_info_data_get_type
						(void) G_GNUC_CONST;
CamelVeeMessageInfoData *
		camel_vee_message_info_data_new
						(CamelVeeSubfolderData *subfolder_data,
						 const gchar *orig_message_uid);
CamelVeeSubfolderData *
		camel_vee_message_info_data_get_subfolder_data
						(CamelVeeMessageInfoData *data);
const gchar *	camel_vee_message_info_data_get_orig_message_uid
						(CamelVeeMessageInfoData *data);
const gchar *	camel_vee_message_info_data_get_vee_message_uid
						(CamelVeeMessageInfoData *data);

/* ----------------------------------------------------------------------- */

/**
 * CamelVeeDataCache:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _CamelVeeDataCache {
	/*< private >*/
	GObject parent;
	CamelVeeDataCachePrivate *priv;
};

struct _CamelVeeDataCacheClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_vee_data_cache_get_type	(void) G_GNUC_CONST;
CamelVeeDataCache *
		camel_vee_data_cache_new	(void);
void		camel_vee_data_cache_add_subfolder
						(CamelVeeDataCache *data_cache,
						 CamelFolder *subfolder);
void		camel_vee_data_cache_remove_subfolder
						(CamelVeeDataCache *data_cache,
						 CamelFolder *subfolder);
CamelVeeSubfolderData *
		camel_vee_data_cache_get_subfolder_data
						(CamelVeeDataCache *data_cache,
						 CamelFolder *folder);
gboolean	camel_vee_data_cache_contains_message_info_data
						(CamelVeeDataCache *data_cache,
						 CamelFolder *folder,
						 const gchar *orig_message_uid);
CamelVeeMessageInfoData *
		camel_vee_data_cache_get_message_info_data
						(CamelVeeDataCache *data_cache,
						 CamelFolder *folder,
						 const gchar *orig_message_uid);
CamelVeeMessageInfoData *
		camel_vee_data_cache_get_message_info_data_by_vuid
						(CamelVeeDataCache *data_cache,
						 const gchar *vee_message_uid);
void		camel_vee_data_cache_foreach_message_info_data
						(CamelVeeDataCache *data_cache,
						 CamelFolder *fromfolder,
						 CamelForeachInfoData func,
						 gpointer user_data);
void		camel_vee_data_cache_remove_message_info_data
						(CamelVeeDataCache *data_cache,
						 CamelVeeMessageInfoData *mi_data);

G_END_DECLS

#endif /* CAMEL_VEE_DATA_CACHE_H */
