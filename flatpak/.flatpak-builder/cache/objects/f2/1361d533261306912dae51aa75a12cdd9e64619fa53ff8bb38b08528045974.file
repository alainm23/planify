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

#ifndef CAMEL_MESSAGE_INFO_H
#define CAMEL_MESSAGE_INFO_H

#include <glib-object.h>

#include <camel/camel-named-flags.h>
#include <camel/camel-name-value-array.h>
#include <camel/camel-utils.h>

/* Standard GObject macros */
#define CAMEL_TYPE_MESSAGE_INFO \
	(camel_message_info_get_type ())
#define CAMEL_MESSAGE_INFO(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_MESSAGE_INFO, CamelMessageInfo))
#define CAMEL_MESSAGE_INFO_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_MESSAGE_INFO, CamelMessageInfoClass))
#define CAMEL_IS_MESSAGE_INFO(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_MESSAGE_INFO))
#define CAMEL_IS_MESSAGE_INFO_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_MESSAGE_INFO))
#define CAMEL_MESSAGE_INFO_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_MESSAGE_INFO, CamelMessageInfoClass))

G_BEGIN_DECLS

/* Forward declarations */
struct _CamelFolderSummary;
struct _CamelMIRecord;

/* A summary messageid is a 64 bit identifier (partial md5 hash) */
typedef struct _CamelSummaryMessageID {
	union {
		guint64 id;
		guchar hash[8];
		struct {
			guint32 hi;
			guint32 lo;
		} part;
	} id;
} CamelSummaryMessageID;

/* system flag bits */
typedef enum _CamelMessageFlags {
	CAMEL_MESSAGE_ANSWERED = 1 << 0,
	CAMEL_MESSAGE_DELETED = 1 << 1,
	CAMEL_MESSAGE_DRAFT = 1 << 2,
	CAMEL_MESSAGE_FLAGGED = 1 << 3,
	CAMEL_MESSAGE_SEEN = 1 << 4,

	/* these aren't really system flag bits, but are convenience flags */
	CAMEL_MESSAGE_ATTACHMENTS = 1 << 5,
	CAMEL_MESSAGE_ANSWERED_ALL = 1 << 6,
	CAMEL_MESSAGE_JUNK = 1 << 7,
	CAMEL_MESSAGE_SECURE = 1 << 8,
	CAMEL_MESSAGE_NOTJUNK = 1 << 9,
	CAMEL_MESSAGE_FORWARDED = 1 << 10,

	/* following flags are for the folder, and are not really permanent flags */
	CAMEL_MESSAGE_FOLDER_FLAGGED = 1 << 16, /* for use by the folder implementation */
	/* flags after 1 << 16 are used by camel providers,
	 * if adding non permanent flags, add them to the end  */

	CAMEL_MESSAGE_JUNK_LEARN = 1 << 30, /* used when setting CAMEL_MESSAGE_JUNK flag
					     * to say that we request junk plugin
					     * to learn that message as junk/non junk */
	CAMEL_MESSAGE_USER = 1 << 31 /* supports user flags */
} CamelMessageFlags;

/* Changes to system flags will NOT trigger a folder changed event */
#define CAMEL_MESSAGE_SYSTEM_MASK (0xffff << 16)

typedef struct _CamelMessageInfo CamelMessageInfo;
typedef struct _CamelMessageInfoClass CamelMessageInfoClass;
typedef struct _CamelMessageInfoPrivate CamelMessageInfoPrivate;

struct _CamelMessageInfo {
	GObject parent;
	CamelMessageInfoPrivate *priv;
};

struct _CamelMessageInfoClass {
	GObjectClass parent_class;

	CamelMessageInfo *	(* clone)	(const CamelMessageInfo *mi,
						 struct _CamelFolderSummary *assign_summary);
	gboolean		(* load)	(CamelMessageInfo *mi,
						 const struct _CamelMIRecord *record,
						 /* const */ gchar **bdata_ptr);
	gboolean		(* save)	(const CamelMessageInfo *mi,
						 struct _CamelMIRecord *record,
						 GString *bdata_str);
	guint32			(* get_flags)	(const CamelMessageInfo *mi);
	gboolean		(* set_flags)	(CamelMessageInfo *mi,
						 guint32 mask,
						 guint32 set);
	gboolean		(* get_user_flag)
						(const CamelMessageInfo *mi,
						 const gchar *name);
	gboolean		(* set_user_flag)
						(CamelMessageInfo *mi,
						 const gchar *name,
						 gboolean state);
	const CamelNamedFlags *	(* get_user_flags)
						(const CamelMessageInfo *mi);
	CamelNamedFlags *	(* dup_user_flags)
						(const CamelMessageInfo *mi);
	gboolean		(* take_user_flags)
						(CamelMessageInfo *mi,
						 CamelNamedFlags *user_flags);
	const gchar *		(* get_user_tag)(const CamelMessageInfo *mi,
						 const gchar *name);
	gboolean		(* set_user_tag)(CamelMessageInfo *mi,
						 const gchar *name,
						 const gchar *value);
	const CamelNameValueArray *
				(* get_user_tags)
						(const CamelMessageInfo *mi);
	CamelNameValueArray *	(* dup_user_tags)
						(const CamelMessageInfo *mi);
	gboolean		(* take_user_tags)
						(CamelMessageInfo *mi,
						 CamelNameValueArray *user_tags);
	const gchar *		(* get_subject)	(const CamelMessageInfo *mi);
	gboolean		(* set_subject)	(CamelMessageInfo *mi,
						 const gchar *subject);
	const gchar *		(* get_from)	(const CamelMessageInfo *mi);
	gboolean		(* set_from)	(CamelMessageInfo *mi,
						 const gchar *from);
	const gchar *		(* get_to)	(const CamelMessageInfo *mi);
	gboolean		(* set_to)	(CamelMessageInfo *mi,
						 const gchar *to);
	const gchar *		(* get_cc)	(const CamelMessageInfo *mi);
	gboolean		(* set_cc)	(CamelMessageInfo *mi,
						 const gchar *cc);
	const gchar *		(* get_mlist)	(const CamelMessageInfo *mi);
	gboolean		(* set_mlist)	(CamelMessageInfo *mi,
						 const gchar *mlist);
	guint32			(* get_size)	(const CamelMessageInfo *mi);
	gboolean		(* set_size)	(CamelMessageInfo *mi,
						 guint32 size);
	gint64			(* get_date_sent)
						(const CamelMessageInfo *mi);
	gboolean		(* set_date_sent)
						(CamelMessageInfo *mi,
						 gint64 date_sent);
	gint64			(* get_date_received)
						(const CamelMessageInfo *mi);
	gboolean		(* set_date_received)
						(CamelMessageInfo *mi,
						 gint64 date_received);
	guint64			(* get_message_id)
						(const CamelMessageInfo *mi);
	gboolean		(* set_message_id)
						(CamelMessageInfo *mi,
						 guint64 message_id);
	const GArray *		(* get_references)
						(const CamelMessageInfo *mi);
	gboolean		(* take_references)
						(CamelMessageInfo *mi,
						 GArray *references);
	const CamelNameValueArray *
				(* get_headers)	(const CamelMessageInfo *mi);
	gboolean		(* take_headers)(CamelMessageInfo *mi,
						 CamelNameValueArray *headers);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_message_info_get_type	(void);
CamelMessageInfo *
		camel_message_info_new		(struct _CamelFolderSummary *summary);
CamelMessageInfo *
		camel_message_info_clone	(const CamelMessageInfo *mi,
						 struct _CamelFolderSummary *assign_summary);
gboolean	camel_message_info_load		(CamelMessageInfo *mi,
						 const struct _CamelMIRecord *record,
						 /* const */ gchar **bdata_ptr);
gboolean	camel_message_info_save		(const CamelMessageInfo *mi,
						 struct _CamelMIRecord *record,
						 GString *bdata_str);
struct _CamelFolderSummary *
		camel_message_info_ref_summary	(const CamelMessageInfo *mi);
void		camel_message_info_property_lock
						(const CamelMessageInfo *mi);
void		camel_message_info_property_unlock
						(const CamelMessageInfo *mi);
gboolean	camel_message_info_get_dirty	(const CamelMessageInfo *mi);
void		camel_message_info_set_dirty	(CamelMessageInfo *mi,
						 gboolean dirty);
gboolean	camel_message_info_get_folder_flagged
						(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_folder_flagged
						(CamelMessageInfo *mi,
						 gboolean folder_flagged);
guint		camel_message_info_get_folder_flagged_stamp
						(const CamelMessageInfo *mi);
gboolean	camel_message_info_get_abort_notifications
						(const CamelMessageInfo *mi);
void		camel_message_info_set_abort_notifications
						(CamelMessageInfo *mi,
						 gboolean abort_notifications);
void		camel_message_info_freeze_notifications
						(CamelMessageInfo *mi);
void		camel_message_info_thaw_notifications
						(CamelMessageInfo *mi);
gboolean	camel_message_info_get_notifications_frozen
						(const CamelMessageInfo *mi);
const gchar *	camel_message_info_get_uid	(const CamelMessageInfo *mi);
const gchar *	camel_message_info_pooldup_uid	(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_uid	(CamelMessageInfo *mi,
						 const gchar *uid);
guint32		camel_message_info_get_flags	(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_flags	(CamelMessageInfo *mi,
						 guint32 mask,
						 guint32 set);
gboolean	camel_message_info_get_user_flag
						(const CamelMessageInfo *mi,
						 const gchar *name);
gboolean	camel_message_info_set_user_flag
						(CamelMessageInfo *mi,
						 const gchar *name,
						 gboolean state);
const CamelNamedFlags *
		camel_message_info_get_user_flags
						(const CamelMessageInfo *mi);
CamelNamedFlags *
		camel_message_info_dup_user_flags
						(const CamelMessageInfo *mi);
gboolean
		camel_message_info_take_user_flags
						(CamelMessageInfo *mi,
						 CamelNamedFlags *user_flags);
const gchar *	camel_message_info_get_user_tag	(const CamelMessageInfo *mi,
						 const gchar *name);
gchar *		camel_message_info_dup_user_tag	(const CamelMessageInfo *mi,
						 const gchar *name);
gboolean	camel_message_info_set_user_tag	(CamelMessageInfo *mi,
						 const gchar *name,
						 const gchar *value);
const CamelNameValueArray *
		camel_message_info_get_user_tags
						(const CamelMessageInfo *mi);
CamelNameValueArray *
		camel_message_info_dup_user_tags
						(const CamelMessageInfo *mi);
gboolean	camel_message_info_take_user_tags
						(CamelMessageInfo *mi,
						 CamelNameValueArray *user_tags);
const gchar *	camel_message_info_get_subject	(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_subject	(CamelMessageInfo *mi,
						 const gchar *subject);
const gchar *	camel_message_info_get_from	(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_from	(CamelMessageInfo *mi,
						 const gchar *from);
const gchar *	camel_message_info_get_to	(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_to	(CamelMessageInfo *mi,
						 const gchar *to);
const gchar *	camel_message_info_get_cc	(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_cc	(CamelMessageInfo *mi,
						 const gchar *cc);
const gchar *	camel_message_info_get_mlist	(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_mlist	(CamelMessageInfo *mi,
						 const gchar *mlist);
guint32		camel_message_info_get_size	(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_size	(CamelMessageInfo *mi,
						 guint32 size);
gint64		camel_message_info_get_date_sent
						(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_date_sent
						(CamelMessageInfo *mi,
						 gint64 date_sent);
gint64		camel_message_info_get_date_received
						(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_date_received
						(CamelMessageInfo *mi,
						 gint64 date_received);
guint64		camel_message_info_get_message_id
						(const CamelMessageInfo *mi);
gboolean	camel_message_info_set_message_id
						(CamelMessageInfo *mi,
						 guint64 message_id);
const GArray *	camel_message_info_get_references
						(const CamelMessageInfo *mi);
GArray *	camel_message_info_dup_references
						(const CamelMessageInfo *mi);
gboolean	camel_message_info_take_references
						(CamelMessageInfo *mi,
						 GArray *references);
const CamelNameValueArray *
		camel_message_info_get_headers	(const CamelMessageInfo *mi);
CamelNameValueArray *
		camel_message_info_dup_headers	(const CamelMessageInfo *mi);
gboolean	camel_message_info_take_headers	(CamelMessageInfo *mi,
						 CamelNameValueArray *headers);

/* Debugging functions */
void		camel_message_info_dump		(CamelMessageInfo *mi);

G_END_DECLS

#endif /* CAMEL_MESSAGE_INFO_H */
