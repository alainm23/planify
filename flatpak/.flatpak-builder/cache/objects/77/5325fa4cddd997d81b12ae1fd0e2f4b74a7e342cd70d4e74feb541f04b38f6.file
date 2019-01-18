/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-store.h : Abstract class for an email store
 *
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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 *          Michael Zucchi <NotZed@ximian.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_STORE_H
#define CAMEL_STORE_H

#include <camel/camel-db.h>
#include <camel/camel-enums.h>
#include <camel/camel-folder.h>
#include <camel/camel-service.h>

/* Standard GObject macros */
#define CAMEL_TYPE_STORE \
	(camel_store_get_type ())
#define CAMEL_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_STORE, CamelStore))
#define CAMEL_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_STORE, CamelStoreClass))
#define CAMEL_IS_STORE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_STORE))
#define CAMEL_IS_STORE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_STORE))
#define CAMEL_STORE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_STORE, CamelStoreClass))

#define CAMEL_TYPE_FOLDER_INFO \
	(camel_folder_info_get_type ())
#define CAMEL_FOLDER_INFO(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_FOLDER_INFO, CamelFolderInfo))
#define CAMEL_IS_FOLDER_INFO(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_FOLDER_INFO))
/**
 * CAMEL_STORE_ERROR:
 *
 * Since: 2.32
 **/
#define CAMEL_STORE_ERROR \
	(camel_store_error_quark ())

/**
 * CAMEL_STORE_SETUP
 * @CAMEL_STORE_SETUP_ARCHIVE_FOLDER: Name of an Archive folder key
 * @CAMEL_STORE_SETUP_DRAFTS_FOLDER: Name of a Drafts folder key
 * @CAMEL_STORE_SETUP_SENT_FOLDER: Name of a Sent folder key
 * @CAMEL_STORE_SETUP_TEMPLATES_FOLDER: Name of a Templates folder key
 *
 * Key names to a hash table with values to preset for the account used
 * as in the camel_store_initial_setup_sync() function.
 *
 * The key name consists of up to four parts: Source:Extension:Property[:Type]
 * Source can be 'Collection', 'Account', 'Submission', 'Transport', 'Backend'.
 * Extension is any extension name; it's up to the key creator to make sure
 * the extension belongs to that particular Source.
 * Property is a property name in the Extension.
 * Type is an optional letter describing the type of the value; if not set, then
 * string is used. Available values are: 'b' for boolean, 'i' for integer,
 * 's' for string, 'f' for folder full path.
 * All the part values are case sensitive.
 *
 * Since: 3.20
 **/
#define CAMEL_STORE_SETUP_ARCHIVE_FOLDER	"Account:Mail Account:archive-folder:f"
#define CAMEL_STORE_SETUP_DRAFTS_FOLDER		"Submission:Mail Composition:drafts-folder:f"
#define CAMEL_STORE_SETUP_SENT_FOLDER		"Submission:Mail Submission:sent-folder:f"
#define CAMEL_STORE_SETUP_TEMPLATES_FOLDER	"Submission:Mail Composition:templates-folder:f"

G_BEGIN_DECLS

/**
 * CamelStoreError:
 * @CAMEL_STORE_ERROR_INVALID: an invalid store operation had been requested
 * @CAMEL_STORE_ERROR_NO_FOLDER: requested operation cannot be performed with the given folder
 *
 * Since: 2.32
 **/
typedef enum {
	CAMEL_STORE_ERROR_INVALID,
	CAMEL_STORE_ERROR_NO_FOLDER
} CamelStoreError;

typedef struct _CamelFolderInfo {
	struct _CamelFolderInfo *next;
	struct _CamelFolderInfo *parent;
	struct _CamelFolderInfo *child;

	gchar *full_name;
	gchar *display_name;

	CamelFolderInfoFlags flags;
	gint32 unread;
	gint32 total;
} CamelFolderInfo;

typedef struct _CamelStore CamelStore;
typedef struct _CamelStoreClass CamelStoreClass;
typedef struct _CamelStorePrivate CamelStorePrivate;

/**
 * CamelStoreGetFolderFlags:
 * @CAMEL_STORE_FOLDER_NONE: no flags
 * @CAMEL_STORE_FOLDER_CREATE: create the folder
 * @CAMEL_STORE_FOLDER_EXCL: deprecated, not honored
 * @CAMEL_STORE_FOLDER_BODY_INDEX: save the body index
 * @CAMEL_STORE_FOLDER_PRIVATE: a private folder that should not show up in
 *  unmatched, folder info's, etc.
 *
 * Open mode for folder.
 */
typedef enum {
	CAMEL_STORE_FOLDER_NONE = 0,
	CAMEL_STORE_FOLDER_CREATE = 1 << 0,
	CAMEL_STORE_FOLDER_EXCL = 1 << 1,
	CAMEL_STORE_FOLDER_BODY_INDEX = 1 << 2,
	CAMEL_STORE_FOLDER_PRIVATE    = 1 << 3
} CamelStoreGetFolderFlags;

struct _CamelStore {
	CamelService parent;
	CamelStorePrivate *priv;
};

struct _CamelStoreClass {
	CamelServiceClass parent_class;

	GHashFunc hash_folder_name;
	GEqualFunc equal_folder_name;

	/* Non-Blocking Methods */
	gboolean	(*can_refresh_folder)	(CamelStore *store,
						 CamelFolderInfo *info,
						 GError **error);

	/* Synchronous I/O Methods */
	CamelFolder *	(*get_folder_sync)	(CamelStore *store,
						 const gchar *folder_name,
						 CamelStoreGetFolderFlags flags,
						 GCancellable *cancellable,
						 GError **error);
	CamelFolderInfo *
			(*get_folder_info_sync)	(CamelStore *store,
						 const gchar *top,
						 CamelStoreGetFolderInfoFlags flags,
						 GCancellable *cancellable,
						 GError **error);
	CamelFolder *	(*get_inbox_folder_sync)
						(CamelStore *store,
						 GCancellable *cancellable,
						 GError **error);
	CamelFolder *	(*get_junk_folder_sync)	(CamelStore *store,
						 GCancellable *cancellable,
						 GError **error);
	CamelFolder *	(*get_trash_folder_sync)
						(CamelStore *store,
						 GCancellable *cancellable,
						 GError **error);
	CamelFolderInfo *
			(*create_folder_sync)	(CamelStore *store,
						 const gchar *parent_name,
						 const gchar *folder_name,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*delete_folder_sync)	(CamelStore *store,
						 const gchar *folder_name,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*rename_folder_sync)	(CamelStore *store,
						 const gchar *old_name,
						 const gchar *new_name,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*synchronize_sync)	(CamelStore *store,
						 gboolean expunge,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*initial_setup_sync)	(CamelStore *store,
						 GHashTable *out_save_setup,
						 GCancellable *cancellable,
						 GError **error);

	/* Padding for future expansion */
	gpointer reserved_methods[20];

	/* Signals */
	void		(*folder_created)	(CamelStore *store,
						 CamelFolderInfo *folder_info);
	void		(*folder_deleted)	(CamelStore *store,
						 CamelFolderInfo *folder_info);
	void		(*folder_opened)	(CamelStore *store,
						 CamelFolder *folder);
	void		(*folder_renamed)	(CamelStore *store,
						 const gchar *old_name,
						 CamelFolderInfo *folder_info);
	void		(*folder_info_stale)	(CamelStore *store);

	/* Padding for future expansion */
	gpointer reserved_signals[20];
};

GType		camel_store_get_type		(void);
GQuark		camel_store_error_quark		(void) G_GNUC_CONST;
CamelDB *	camel_store_get_db		(CamelStore *store);
CamelObjectBag *camel_store_get_folders_bag	(CamelStore *store);
GPtrArray *	camel_store_dup_opened_folders	(CamelStore *store);
guint32		camel_store_get_flags		(CamelStore *store);
void		camel_store_set_flags		(CamelStore *store,
						 guint32 flags);
guint32		camel_store_get_permissions	(CamelStore *store);
void		camel_store_set_permissions	(CamelStore *store,
						 guint32 permissions);
void		camel_store_folder_created	(CamelStore *store,
						 CamelFolderInfo *folder_info);
void		camel_store_folder_deleted	(CamelStore *store,
						 CamelFolderInfo *folder_info);
void		camel_store_folder_opened	(CamelStore *store,
						 CamelFolder *folder);
void		camel_store_folder_renamed	(CamelStore *store,
						 const gchar *old_name,
						 CamelFolderInfo *folder_info);
void		camel_store_folder_info_stale	(CamelStore *store);
GType		camel_folder_info_get_type		(void);
CamelFolderInfo *
		camel_folder_info_new		(void);
void		camel_folder_info_free		(CamelFolderInfo *fi);
#ifndef CAMEL_DISABLE_DEPRECATED
CamelFolderInfo *
		camel_folder_info_build		(GPtrArray *folders,
						 const gchar *namespace_,
						 gchar separator,
						 gboolean short_names);
#endif /* CAMEL_DISABLE_DEPRECATED */
CamelFolderInfo *
		camel_folder_info_clone		(CamelFolderInfo *fi);
gboolean	camel_store_can_refresh_folder	(CamelStore *store,
						 CamelFolderInfo *info,
						 GError **error);

CamelFolder *	camel_store_get_folder_sync	(CamelStore *store,
						 const gchar *folder_name,
						 CamelStoreGetFolderFlags flags,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_get_folder		(CamelStore *store,
						 const gchar *folder_name,
						 CamelStoreGetFolderFlags flags,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelFolder *	camel_store_get_folder_finish	(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
CamelFolderInfo *
		camel_store_get_folder_info_sync
						(CamelStore *store,
						 const gchar *top,
						 CamelStoreGetFolderInfoFlags flags,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_get_folder_info	(CamelStore *store,
						 const gchar *top,
						 CamelStoreGetFolderInfoFlags flags,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelFolderInfo *
		camel_store_get_folder_info_finish
						(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
CamelFolder *	camel_store_get_inbox_folder_sync
						(CamelStore *store,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_get_inbox_folder	(CamelStore *store,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelFolder *	camel_store_get_inbox_folder_finish
						(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
CamelFolder *	camel_store_get_junk_folder_sync
						(CamelStore *store,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_get_junk_folder	(CamelStore *store,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelFolder *	camel_store_get_junk_folder_finish
						(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
CamelFolder *	camel_store_get_trash_folder_sync
						(CamelStore *store,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_get_trash_folder	(CamelStore *store,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelFolder *	camel_store_get_trash_folder_finish
						(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
CamelFolderInfo *
		camel_store_create_folder_sync	(CamelStore *store,
						 const gchar *parent_name,
						 const gchar *folder_name,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_create_folder	(CamelStore *store,
						 const gchar *parent_name,
						 const gchar *folder_name,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelFolderInfo *
		camel_store_create_folder_finish
						(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_store_delete_folder_sync	(CamelStore *store,
						 const gchar *folder_name,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_delete_folder	(CamelStore *store,
						 const gchar *folder_name,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_store_delete_folder_finish
						(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_store_rename_folder_sync	(CamelStore *store,
						 const gchar *old_name,
						 const gchar *new_name,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_rename_folder	(CamelStore *store,
						 const gchar *old_name,
						 const gchar *new_name,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_store_rename_folder_finish
						(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_store_synchronize_sync	(CamelStore *store,
						 gboolean expunge,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_synchronize		(CamelStore *store,
						 gboolean expunge,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_store_synchronize_finish	(CamelStore *store,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_store_initial_setup_sync	(CamelStore *store,
						 GHashTable **out_save_setup,
						 GCancellable *cancellable,
						 GError **error);
void		camel_store_initial_setup	(CamelStore *store,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_store_initial_setup_finish
						(CamelStore *store,
						 GAsyncResult *result,
						 GHashTable **out_save_setup,
						 GError **error);
gboolean	camel_store_maybe_run_db_maintenance
						(CamelStore *store,
						 GError **error);
void		camel_store_delete_cached_folder
						(CamelStore *store,
						 const gchar *folder_name);

G_END_DECLS

#endif /* CAMEL_STORE_H */
