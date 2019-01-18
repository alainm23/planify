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
 * Authors: Sankar P <psankar@novell.com>
 *          Srinivasa Ragavan <sragavan@novell.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_DB_H
#define CAMEL_DB_H

#include <glib.h>
#include <glib-object.h>

/* Standard GObject macros */
#define CAMEL_TYPE_DB \
	(camel_db_get_type ())
#define CAMEL_DB(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_DB, CamelDB))
#define CAMEL_DB_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_DB, CamelDBClass))
#define CAMEL_IS_DB(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_DB))
#define CAMEL_IS_DB_CLASS(obj) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_DB))
#define CAMEL_DB_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_DB, CamelDBClass))

G_BEGIN_DECLS

typedef struct _CamelDB CamelDB;
typedef struct _CamelDBClass CamelDBClass;
typedef struct _CamelDBPrivate CamelDBPrivate;

/**
 * CamelDB:
 *
 * Since: 2.24
 **/
struct _CamelDB {
	/*< private >*/
	GObject parent;
	CamelDBPrivate *priv;
};

struct _CamelDBClass {
	/*< private >*/
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

/**
 * CamelDBCollate:
 * @enc: a used encoding (SQLITE_UTF8)
 * @length1: length of the @data1
 * @data1: the first value, of lenth @length1
 * @length2: length of the @data2
 * @data2: the second value, of lenth @length2
 *
 * A collation callback function.
 *
 * Returns: less than zero, zero, or greater than zero value, the same as for example strcmp() does.
 *
 * Since: 2.24
 **/
typedef gint (* CamelDBCollate)(gpointer enc, gint length1, gconstpointer data1, gint length2, gconstpointer data2);

/**
 * CAMEL_DB_FILE:
 *
 * Since: 2.24
 **/
#define CAMEL_DB_FILE "folders.db"

/* Hopefully no one will create a folder named EVO_IN_meM_hAnDlE */

/**
 * CAMEL_DB_IN_MEMORY_TABLE:
 *
 * Since: 2.26
 **/
#define CAMEL_DB_IN_MEMORY_TABLE "EVO_IN_meM_hAnDlE.temp"

/**
 * CAMEL_DB_IN_MEMORY_DB:
 *
 * Since: 2.26
 **/
#define CAMEL_DB_IN_MEMORY_DB "EVO_IN_meM_hAnDlE"

/**
 * CAMEL_DB_IN_MEMORY_TABLE_LIMIT:
 *
 * Since: 2.26
 **/
#define CAMEL_DB_IN_MEMORY_TABLE_LIMIT 100000


/**
 * CAMEL_DB_FREE_CACHE_SIZE:
 *
 * Since: 2.24
 **/
#define CAMEL_DB_FREE_CACHE_SIZE 2 * 1024 * 1024

/**
 * CAMEL_DB_SLEEP_INTERVAL:
 *
 * Since: 2.24
 **/
#define CAMEL_DB_SLEEP_INTERVAL 1*10*10

/**
 * CamelMIRecord:
 * @uid: Message UID
 * @flags: Camel Message info flags
 * @msg_type: unused
 * @dirty: whether the message info requires upload to the server; it corresponds to #CAMEL_MESSAGE_FOLDER_FLAGGED
 * @read: boolean read status
 * @deleted: boolean deleted status
 * @replied: boolean replied status
 * @important: boolean important status
 * @junk: boolean junk status
 * @attachment: boolean attachment status
 * @size: size of the mail
 * @dsent: date sent
 * @dreceived: date received
 * @subject: subject of the mail
 * @from: sender
 * @to: recipient
 * @cc: CC members
 * @mlist: message list headers
 * @followup_flag: followup flag / also can be queried to see for followup or not
 * @followup_completed_on: completed date, can be used to see if completed
 * @followup_due_by: to see the due by date
 * @part: part / references / thread id
 * @labels: labels of mails also called as userflags
 * @usertags: composite string of user tags
 * @cinfo: content info string - composite string
 * @bdata: provider specific data
 *
 * The extensive DB format, supporting basic searching and sorting.
 *
 * Since: 2.24
 **/
typedef struct _CamelMIRecord {
	gchar *uid;
	guint32 flags;
	guint32 msg_type;
	guint32 dirty;
	gboolean read;
	gboolean deleted;
	gboolean replied;
	gboolean important;
	gboolean junk;
	gboolean attachment;
	guint32 size;
	gint64 dsent; /* time_t */
	gint64 dreceived; /* time_t */
	gchar *subject;
	gchar *from;
	gchar *to;
	gchar *cc;
	gchar *mlist;
	gchar *followup_flag;
	gchar *followup_completed_on;
	gchar *followup_due_by;
	gchar *part;
	gchar *labels;
	gchar *usertags;
	gchar *cinfo;
	gchar *bdata;
} CamelMIRecord;

/**
 * CamelFIRecord:
 * @folder_name: name of the folder
 * @version: version of the saved information
 * @flags: folder flags
 * @nextuid: next free uid
 * @timestamp: timestamp of the summary
 * @saved_count: count of all messages
 * @unread_count: count of unread messages
 * @deleted_count: count of deleted messages
 * @junk_count: count of junk messages
 * @visible_count: count of visible (not deleted and not junk) messages
 * @jnd_count: count of junk and not deleted messages
 * @bdata: custom data of the #CamelFolderSummary descendants
 *
 * Values to store/load for single folder's #CamelFolderSummary structure.
 *
 * Since: 2.24
 **/
typedef struct _CamelFIRecord {
	gchar *folder_name;
	guint32 version;
	guint32 flags;
	guint32 nextuid;
	gint64 timestamp;
	guint32 saved_count;
	guint32 unread_count;
	guint32 deleted_count;
	guint32 junk_count;
	guint32 visible_count;
	guint32 jnd_count;  /* Junked not deleted */
	gchar *bdata;
} CamelFIRecord;

/**
 * CamelDBKnownColumnNames:
 * @CAMEL_DB_COLUMN_UNKNOWN: unknown column name
 * @CAMEL_DB_COLUMN_ATTACHMENT: attachment
 * @CAMEL_DB_COLUMN_BDATA: bdata
 * @CAMEL_DB_COLUMN_CINFO: cinfo
 * @CAMEL_DB_COLUMN_DELETED: deleted
 * @CAMEL_DB_COLUMN_DELETED_COUNT: deleted_count
 * @CAMEL_DB_COLUMN_DRECEIVED: dreceived
 * @CAMEL_DB_COLUMN_DSENT: dsent
 * @CAMEL_DB_COLUMN_FLAGS: flags
 * @CAMEL_DB_COLUMN_FOLDER_NAME: folder_name
 * @CAMEL_DB_COLUMN_FOLLOWUP_COMPLETED_ON: followup_completed_on
 * @CAMEL_DB_COLUMN_FOLLOWUP_DUE_BY: followup_due_by
 * @CAMEL_DB_COLUMN_FOLLOWUP_FLAG: followup_flag
 * @CAMEL_DB_COLUMN_IMPORTANT: important
 * @CAMEL_DB_COLUMN_JND_COUNT: jnd_count
 * @CAMEL_DB_COLUMN_JUNK: junk
 * @CAMEL_DB_COLUMN_JUNK_COUNT: junk_count
 * @CAMEL_DB_COLUMN_LABELS: labels
 * @CAMEL_DB_COLUMN_MAIL_CC: mail_cc
 * @CAMEL_DB_COLUMN_MAIL_FROM: mail_from
 * @CAMEL_DB_COLUMN_MAIL_TO: mail_to
 * @CAMEL_DB_COLUMN_MLIST: mlist
 * @CAMEL_DB_COLUMN_NEXTUID: nextuid
 * @CAMEL_DB_COLUMN_PART: part
 * @CAMEL_DB_COLUMN_READ: read
 * @CAMEL_DB_COLUMN_REPLIED: replied
 * @CAMEL_DB_COLUMN_SAVED_COUNT: saved_count
 * @CAMEL_DB_COLUMN_SIZE: size
 * @CAMEL_DB_COLUMN_SUBJECT: subject
 * @CAMEL_DB_COLUMN_TIME: time
 * @CAMEL_DB_COLUMN_UID: uid
 * @CAMEL_DB_COLUMN_UNREAD_COUNT: unread_count
 * @CAMEL_DB_COLUMN_USERTAGS: usertags
 * @CAMEL_DB_COLUMN_VERSION: version
 * @CAMEL_DB_COLUMN_VISIBLE_COUNT: visible_count
 * @CAMEL_DB_COLUMN_VUID: vuid
 *
 * An enum of all the known columns, which can be used for a quick column lookups.
 *
 * Since: 3.4
 **/
typedef enum {
	CAMEL_DB_COLUMN_UNKNOWN = -1,
	CAMEL_DB_COLUMN_ATTACHMENT,
	CAMEL_DB_COLUMN_BDATA,
	CAMEL_DB_COLUMN_CINFO,
	CAMEL_DB_COLUMN_DELETED,
	CAMEL_DB_COLUMN_DELETED_COUNT,
	CAMEL_DB_COLUMN_DRECEIVED,
	CAMEL_DB_COLUMN_DSENT,
	CAMEL_DB_COLUMN_FLAGS,
	CAMEL_DB_COLUMN_FOLDER_NAME,
	CAMEL_DB_COLUMN_FOLLOWUP_COMPLETED_ON,
	CAMEL_DB_COLUMN_FOLLOWUP_DUE_BY,
	CAMEL_DB_COLUMN_FOLLOWUP_FLAG,
	CAMEL_DB_COLUMN_IMPORTANT,
	CAMEL_DB_COLUMN_JND_COUNT,
	CAMEL_DB_COLUMN_JUNK,
	CAMEL_DB_COLUMN_JUNK_COUNT,
	CAMEL_DB_COLUMN_LABELS,
	CAMEL_DB_COLUMN_MAIL_CC,
	CAMEL_DB_COLUMN_MAIL_FROM,
	CAMEL_DB_COLUMN_MAIL_TO,
	CAMEL_DB_COLUMN_MLIST,
	CAMEL_DB_COLUMN_NEXTUID,
	CAMEL_DB_COLUMN_PART,
	CAMEL_DB_COLUMN_READ,
	CAMEL_DB_COLUMN_REPLIED,
	CAMEL_DB_COLUMN_SAVED_COUNT,
	CAMEL_DB_COLUMN_SIZE,
	CAMEL_DB_COLUMN_SUBJECT,
	CAMEL_DB_COLUMN_TIME,
	CAMEL_DB_COLUMN_UID,
	CAMEL_DB_COLUMN_UNREAD_COUNT,
	CAMEL_DB_COLUMN_USERTAGS,
	CAMEL_DB_COLUMN_VERSION,
	CAMEL_DB_COLUMN_VISIBLE_COUNT,
	CAMEL_DB_COLUMN_VUID
} CamelDBKnownColumnNames;

CamelDBKnownColumnNames camel_db_get_column_ident (GHashTable **hash, gint index, gint ncols, gchar **col_names);

/**
 * CamelDBSelectCB:
 * @user_data: a callback user data
 * @ncol: how many columns is provided
 * @colvalues: (array length=ncol): array of column values, as UTF-8 strings
 * @colnames: (array length=ncol): array of column names
 *
 * A callback called for the SELECT statements. The items at the same index of @colvalues
 * and @colnames correspond to each other.
 *
 * Returns: 0 to continue the SELECT execution, non-zero to abort the execution.
 *
 * Since: 2.24
 **/
typedef gint (* CamelDBSelectCB) (gpointer user_data, gint ncol, gchar **colvalues, gchar **colnames);

GType		camel_db_get_type		(void) G_GNUC_CONST;

CamelDB *	camel_db_new			(const gchar *filename,
						 GError **error);
const gchar *	camel_db_get_filename		(CamelDB *cdb);
gint		camel_db_command		(CamelDB *cdb,
						 const gchar *stmt,
						 GError **error);
gint		camel_db_transaction_command	(CamelDB *cdb,
						 const GList *qry_list,
						 GError **error);
gint		camel_db_begin_transaction	(CamelDB *cdb,
						 GError **error);
gint		camel_db_add_to_transaction	(CamelDB *cdb,
						 const gchar *query,
						 GError **error);
gint		camel_db_end_transaction	(CamelDB *cdb,
						 GError **error);
gint		camel_db_abort_transaction	(CamelDB *cdb,
						 GError **error);
gint		camel_db_clear_folder_summary	(CamelDB *cdb,
						 const gchar *folder_name,
						 GError **error);
gint		camel_db_rename_folder		(CamelDB *cdb,
						 const gchar *old_folder_name,
						 const gchar *new_folder_name,
						 GError **error);
gint		camel_db_delete_folder		(CamelDB *cdb,
						 const gchar *folder_name,
						 GError **error);
gint		camel_db_delete_uid		(CamelDB *cdb,
						 const gchar *folder_name,
						 const gchar *uid,
						 GError **error);
gint		camel_db_delete_uids		(CamelDB *cdb,
						 const gchar *folder_name,
						 const GList *uids,
						 GError **error);
gint		camel_db_create_folders_table	(CamelDB *cdb,
						 GError **error);
gint		camel_db_select			(CamelDB *cdb,
						 const gchar *stmt,
						 CamelDBSelectCB callback,
						 gpointer user_data,
						 GError **error);
gint		camel_db_write_folder_info_record
						(CamelDB *cdb,
						 CamelFIRecord *record,
						 GError **error);
gint		camel_db_read_folder_info_record
						(CamelDB *cdb,
						 const gchar *folder_name,
						 CamelFIRecord *record,
						 GError **error);
gint		camel_db_prepare_message_info_table
						(CamelDB *cdb,
						 const gchar *folder_name,
						 GError **error);
gint		camel_db_write_message_info_record
						(CamelDB *cdb,
						 const gchar *folder_name,
						 CamelMIRecord *record,
						 GError **error);
gint		camel_db_read_message_info_records
						(CamelDB *cdb,
						 const gchar *folder_name,
						 gpointer user_data,
						 CamelDBSelectCB callback,
						 GError **error);
gint		camel_db_read_message_info_record_with_uid
						(CamelDB *cdb,
						 const gchar *folder_name,
						 const gchar *uid,
						 gpointer user_data,
						 CamelDBSelectCB callback,
						 GError **error);
gint		camel_db_count_junk_message_info
						(CamelDB *cdb,
						 const gchar *table_name,
						 guint32 *count,
						 GError **error);
gint		camel_db_count_unread_message_info
						(CamelDB *cdb,
						 const gchar *table_name,
						 guint32 *count,
						 GError **error);
gint		camel_db_count_deleted_message_info
						(CamelDB *cdb,
						 const gchar *table_name,
						 guint32 *count,
						 GError **error);
gint		camel_db_count_total_message_info
						(CamelDB *cdb,
						 const gchar *table_name,
						 guint32 *count,
						 GError **error);
gint		camel_db_count_visible_message_info
						(CamelDB *cdb,
						 const gchar *table_name,
						 guint32 *count,
						 GError **error);
gint		camel_db_count_visible_unread_message_info
						(CamelDB *cdb,
						 const gchar *table_name,
						 guint32 *count,
						 GError **error);
gint		camel_db_count_junk_not_deleted_message_info
						(CamelDB *cdb,
						 const gchar *table_name,
						 guint32 *count,
						 GError **error);
gint		camel_db_count_message_info	(CamelDB *cdb,
						 const gchar *query,
						 guint32 *count,
						 GError **error);
gint		camel_db_get_folder_uids	(CamelDB *cdb,
						 const gchar *folder_name,
						 const gchar *sort_by,
						 const gchar *collate,
						 GHashTable *hash,
						 GError **error);
GPtrArray *	camel_db_get_folder_junk_uids	(CamelDB *cdb,
						 const gchar *folder_name,
						 GError **error);
GPtrArray *	camel_db_get_folder_deleted_uids
						(CamelDB *cdb,
						 const gchar *folder_name,
						 GError **error);
gint		camel_db_set_collate		(CamelDB *cdb,
						 const gchar *col,
						 const gchar *collate,
						 CamelDBCollate func);
gint		camel_db_start_in_memory_transactions
						(CamelDB *cdb,
						 GError **error);
gint		camel_db_flush_in_memory_transactions
						(CamelDB *cdb,
						 const gchar *folder_name,
						 GError **error);
gint		camel_db_reset_folder_version	(CamelDB *cdb,
						 const gchar *folder_name,
						 gint reset_version,
						 GError **error);
gboolean	camel_db_maybe_run_maintenance	(CamelDB *cdb,
						 GError **error);

void		camel_db_release_cache_memory	(void);

gchar *		camel_db_sqlize_string		(const gchar *string);
void		camel_db_free_sqlized_string	(gchar *string);
gchar *		camel_db_get_column_name	(const gchar *raw_name);
void		camel_db_camel_mir_free		(CamelMIRecord *record);

G_END_DECLS

#endif
