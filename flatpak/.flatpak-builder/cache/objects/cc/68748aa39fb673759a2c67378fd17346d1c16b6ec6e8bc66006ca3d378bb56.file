/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
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
 */

#ifndef CAMEL_IMAPX_UTILS_H
#define CAMEL_IMAPX_UTILS_H

#include <camel/camel.h>

#include "camel-imapx-input-stream.h"
#include "camel-imapx-mailbox.h"

G_BEGIN_DECLS

/* FIXME Split off a camel-imapx-types.h file with supplemental
 *       enum/struct definitions and helper macros, so we don't
 *       have these conflicting header dependencies. */
struct _CamelIMAPXCommand;
struct _CamelIMAPXStore;

/* list of strings we know about that can be *quickly* tokenised */
typedef enum _camel_imapx_id_t {
	IMAPX_UNKNOWN = 0,

	IMAPX_ALERT,
	IMAPX_APPENDUID,
	IMAPX_BAD,
	IMAPX_BODY,
	IMAPX_BODYSTRUCTURE,
	IMAPX_BYE,
	IMAPX_CAPABILITY,
	IMAPX_CLOSED,
	IMAPX_COPYUID,
	IMAPX_ENVELOPE,
	IMAPX_EXISTS,
	IMAPX_EXPUNGE,
	IMAPX_FETCH,
	IMAPX_FLAGS,
	IMAPX_HIGHESTMODSEQ,
	IMAPX_INTERNALDATE,
	IMAPX_LIST,
	IMAPX_LSUB,
	IMAPX_MESSAGES,
	IMAPX_MODSEQ,
	IMAPX_NAMESPACE,
	IMAPX_NEWNAME,
	IMAPX_NO,
	IMAPX_NOMODSEQ,
	IMAPX_OK,
	IMAPX_PARSE,
	IMAPX_PERMANENTFLAGS,
	IMAPX_PREAUTH,
	IMAPX_READ_ONLY,
	IMAPX_READ_WRITE,
	IMAPX_RECENT,
	IMAPX_RFC822_HEADER,
	IMAPX_RFC822_SIZE,
	IMAPX_RFC822_TEXT,
	IMAPX_STATUS,
	IMAPX_TRYCREATE,
	IMAPX_UID,
	IMAPX_UIDVALIDITY,
	IMAPX_UNSEEN,
	IMAPX_UIDNEXT,
	IMAPX_VANISHED,

	/* RFC 5530: IMAP Response Codes */
	IMAPX_ALREADYEXISTS,
	IMAPX_AUTHENTICATIONFAILED,
	IMAPX_AUTHORIZATIONFAILED,
	IMAPX_CANNOT,
	IMAPX_CLIENTBUG,
	IMAPX_CONTACTADMIN,
	IMAPX_CORRUPTION,
	IMAPX_EXPIRED,
	IMAPX_EXPUNGEISSUED,
	IMAPX_INUSE,
	IMAPX_LIMIT,
	IMAPX_NONEXISTENT,
	IMAPX_NOPERM,
	IMAPX_OVERQUOTA,
	IMAPX_PRIVACYREQUIRED,
	IMAPX_SERVERBUG,
	IMAPX_UNAVAILABLE,

	/* Sentinel for completeness check */
	IMAPX_LAST_ID_VALUE
} camel_imapx_id_t;

#define CAMEL_IMAPX_UNTAGGED_BAD        "BAD"
#define CAMEL_IMAPX_UNTAGGED_BYE        "BYE"
#define CAMEL_IMAPX_UNTAGGED_CAPABILITY "CAPABILITY"
#define CAMEL_IMAPX_UNTAGGED_EXISTS     "EXISTS"
#define CAMEL_IMAPX_UNTAGGED_EXPUNGE    "EXPUNGE"
#define CAMEL_IMAPX_UNTAGGED_FETCH      "FETCH"
#define CAMEL_IMAPX_UNTAGGED_FLAGS      "FLAGS"
#define CAMEL_IMAPX_UNTAGGED_LIST       "LIST"
#define CAMEL_IMAPX_UNTAGGED_LSUB       "LSUB"
#define CAMEL_IMAPX_UNTAGGED_NAMESPACE  "NAMESPACE"
#define CAMEL_IMAPX_UNTAGGED_NO         "NO"
#define CAMEL_IMAPX_UNTAGGED_OK         "OK"
#define CAMEL_IMAPX_UNTAGGED_PREAUTH    "PREAUTH"
#define CAMEL_IMAPX_UNTAGGED_QUOTA      "QUOTA"
#define CAMEL_IMAPX_UNTAGGED_QUOTAROOT  "QUOTAROOT"
#define CAMEL_IMAPX_UNTAGGED_RECENT     "RECENT"
#define CAMEL_IMAPX_UNTAGGED_SEARCH     "SEARCH"
#define CAMEL_IMAPX_UNTAGGED_STATUS     "STATUS"
#define CAMEL_IMAPX_UNTAGGED_VANISHED   "VANISHED"

/* str MUST be in upper case, tokenised using gperf function */
camel_imapx_id_t
		imapx_tokenise			(register const gchar *str,
						 register guint len);

/* this flag should be part of imapfoldersummary */
enum {
	CAMEL_IMAPX_MESSAGE_RECENT = (1 << 21),
};

/* ********************************************************************** */

GArray *	imapx_parse_uids		(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
gboolean	imapx_parse_uids_with_callback	(CamelIMAPXInputStream *stream,
						 gboolean (* func) (guint32 uid, gpointer user_data),
						 gpointer user_data,
						 GCancellable *cancellable,
						 GError **error);
gboolean	imapx_parse_flags		(CamelIMAPXInputStream *stream,
						 guint32 *flagsp,
						 CamelNamedFlags *user_flags,
						 GCancellable *cancellable,
						 GError **error);
void		imapx_write_flags		(GString *string,
						 guint32 flags,
						 const CamelNamedFlags *user_flags);
gboolean	imapx_update_message_info_flags	(CamelMessageInfo *info,
						 guint32 server_flags,
						 const CamelNamedFlags *server_user_flags,
						 guint32 permanent_flags,
						 CamelFolder *folder,
						 gboolean unsolicited);
void		imapx_set_message_info_flags_for_new_message
						(CamelMessageInfo *info,
						 guint32 server_flags,
						 const CamelNamedFlags *server_user_flags,
						 gboolean force_user_flags,
						 const CamelNameValueArray *user_tags,
						 guint32 permanent_flags);
void		imapx_update_store_summary	(CamelFolder *folder);

gchar *		camel_imapx_dup_uid_from_summary_index
						(CamelFolder *folder,
						 guint summary_index);

/* ********************************************************************** */

/* Handy server capability test macros.
 * Both return FALSE if capabilities are unknown. */
#define CAMEL_IMAPX_HAVE_CAPABILITY(info, name) \
	((info) != NULL && ((info)->capa & IMAPX_CAPABILITY_##name) != 0)
#define CAMEL_IMAPX_LACK_CAPABILITY(info, name) \
	((info) != NULL && ((info)->capa & IMAPX_CAPABILITY_##name) == 0)

enum {
	IMAPX_CAPABILITY_IMAP4 = (1 << 0),
	IMAPX_CAPABILITY_IMAP4REV1 = (1 << 1),
	IMAPX_CAPABILITY_STATUS = (1 << 2),
	IMAPX_CAPABILITY_NAMESPACE = (1 << 3),
	IMAPX_CAPABILITY_UIDPLUS = (1 << 4),
	IMAPX_CAPABILITY_LITERALPLUS = (1 << 5),
	IMAPX_CAPABILITY_STARTTLS = (1 << 6),
	IMAPX_CAPABILITY_IDLE = (1 << 7),
	IMAPX_CAPABILITY_CONDSTORE = (1 << 8),
	IMAPX_CAPABILITY_QRESYNC = (1 << 9),
	IMAPX_CAPABILITY_LIST_STATUS = (1 << 10),
	IMAPX_CAPABILITY_LIST_EXTENDED = (1 << 11),
	IMAPX_CAPABILITY_QUOTA = (1 << 12),
	IMAPX_CAPABILITY_MOVE = (1 << 13),
	IMAPX_CAPABILITY_NOTIFY = (1 << 14),
	IMAPX_CAPABILITY_SPECIAL_USE = (1 << 15),
	IMAPX_CAPABILITY_X_GM_EXT_1 = (1 << 16),
	IMAPX_CAPABILITY_UTF8_ACCEPT = (1 << 17),
	IMAPX_CAPABILITY_UTF8_ONLY = (1 << 18)
};

struct _capability_info {
	guint32 capa;
	GHashTable *auth_types;
};

struct _capability_info *
		imapx_parse_capability		(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
void		imapx_free_capability		(struct _capability_info *);
guint32		imapx_register_capability	(const gchar *capability);
guint32		imapx_lookup_capability		(const gchar *capability);

gboolean	imapx_parse_param_list		(CamelIMAPXInputStream *stream,
						 struct _camel_header_param **plist,
						 GCancellable *cancellable,
						 GError **error);
struct _CamelContentDisposition *
		imapx_parse_ext_optional	(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
struct _CamelMessageContentInfo *
		imapx_parse_body_fields		(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
CamelHeaderAddress *
		imapx_parse_address_list	(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
CamelMessageInfo *
		imapx_parse_envelope		(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
CamelMessageContentInfo *
		imapx_parse_body		(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
gchar *		imapx_parse_section		(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);

/* ********************************************************************** */
/* all the possible stuff we might get from a fetch request */
/* this assumes the caller/server doesn't send any one of these types twice */
struct _fetch_info {
	guint32 got;		/* what we got, see below */
	GBytes *body;		/* BODY[.*](<.*>)? */
	GBytes *text;		/* RFC822.TEXT */
	GBytes *header;		/* RFC822.HEADER */
	CamelMessageInfo *minfo;	/* ENVELOPE */
	CamelMessageContentInfo *cinfo;	/* BODYSTRUCTURE,BODY */
	guint32 size;		/* RFC822.SIZE */
	guint32 offset;		/* start offset of a BODY[]<offset.length> request */
	guint32 flags;		/* FLAGS */
	guint64 modseq;		/* MODSEQ */
	CamelNamedFlags *user_flags;
	gchar *date;		/* INTERNALDATE */
	gchar *section;		/* section for a BODY[section] request */
	gchar *uid;		/* UID */
};

#define FETCH_BODY (1 << 0)
#define FETCH_TEXT (1 << 1)
#define FETCH_HEADER (1 << 2)
#define FETCH_MINFO (1 << 3)
#define FETCH_CINFO (1 << 4)
#define FETCH_SIZE (1 << 5)
#define FETCH_OFFSET (1 << 6)
#define FETCH_FLAGS (1 << 7)
#define FETCH_DATE (1 << 8)
#define FETCH_SECTION (1 << 9)
#define FETCH_UID (1 << 10)
#define FETCH_MODSEQ (1 << 11)

struct _fetch_info *
		imapx_parse_fetch		(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 GError **error);
void		imapx_free_fetch		(struct _fetch_info *finfo);
void		imapx_dump_fetch		(struct _fetch_info *finfo);

/* ********************************************************************** */

struct _status_info {
	camel_imapx_id_t result; /* ok/no/bad/preauth only, user_cancel - client response */
	camel_imapx_id_t condition; /* read-only/read-write/alert/parse/trycreate/newname/permanentflags/uidvalidity/unseen/highestmodseq */

	union {
		struct {
			gchar *oldname;
			gchar *newname;
		} newname;
		struct {
			guint64 uidvalidity;
			guint32 uid;
		} appenduid;
		struct {
			guint64 uidvalidity;
			GArray *uids;
			GArray *copied_uids;
		} copyuid;
		struct _capability_info *cinfo;
	} u;

	gchar *text;
};

struct _status_info *
		imapx_parse_status		(CamelIMAPXInputStream *stream,
						 CamelIMAPXMailbox *mailbox,
						 gboolean is_ok_no_bad,
						 GCancellable *cancellable,
						 GError **error);
struct _status_info *
		imapx_copy_status		(struct _status_info *sinfo);
void		imapx_free_status		(struct _status_info *sinfo);

/* ********************************************************************** */

gboolean	camel_imapx_command_add_qresync_parameter
						(struct _CamelIMAPXCommand *ic,
						 CamelFolder *folder);

/* ********************************************************************** */

gchar *		camel_imapx_parse_mailbox	(CamelIMAPXInputStream *stream,
						 gchar separator,
						 GCancellable *cancellable,
						 GError **error);
void		camel_imapx_normalize_mailbox	(gchar *mailbox_name,
						 gchar separator);
gboolean	camel_imapx_mailbox_is_inbox	(const gchar *mailbox_name);
gchar *		camel_imapx_mailbox_to_folder_path
						(const gchar *mailbox_name,
						 gchar separator);
gchar *		camel_imapx_folder_path_to_mailbox
						(const gchar *folder_path,
						 gchar separator);

/* ********************************************************************** */

gboolean	camel_imapx_parse_quota		(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 gchar **out_quota_root_name,
						 CamelFolderQuotaInfo **out_quota_info,
						 GError **error);
gboolean	camel_imapx_parse_quotaroot	(CamelIMAPXInputStream *stream,
						 GCancellable *cancellable,
						 gchar **out_mailbox_name,
						 gchar ***out_quota_roots,
						 GError **error);

/* ********************************************************************** */

extern guchar imapx_specials[256];

#define IMAPX_TYPE_CHAR (1 << 0)
#define IMAPX_TYPE_TEXT_CHAR (1 << 1)
#define IMAPX_TYPE_QUOTED_CHAR (1 << 2)
#define IMAPX_TYPE_ATOM_CHAR (1 << 3)
#define IMAPX_TYPE_TOKEN_CHAR (1 << 4)
#define IMAPX_TYPE_NOTID_CHAR (1 << 5)

guchar imapx_is_mask (const gchar *p);

#define imapx_is_quoted_char(c) \
	((imapx_specials[((guchar)(c)) & 0xff] & IMAPX_TYPE_QUOTED_CHAR) != 0)
#define imapx_is_token_char(c) \
	((imapx_specials[((guchar)(c)) & 0xff] & IMAPX_TYPE_TOKEN_CHAR) != 0)
#define imapx_is_notid_char(c) \
	((imapx_specials[((guchar)(c)) & 0xff] & IMAPX_TYPE_NOTID_CHAR) != 0)

extern gint camel_imapx_debug_flags;
#define CAMEL_IMAPX_DEBUG_command	(1 << 0)
#define CAMEL_IMAPX_DEBUG_debug		(1 << 1)
#define CAMEL_IMAPX_DEBUG_extra		(1 << 2)
#define CAMEL_IMAPX_DEBUG_io		(1 << 3)
#define CAMEL_IMAPX_DEBUG_token		(1 << 4)
#define CAMEL_IMAPX_DEBUG_parse		(1 << 5)
#define CAMEL_IMAPX_DEBUG_conman	(1 << 6)

/* Set this to zero to remove all debug output at build time */
#define CAMEL_IMAPX_DEBUG_ALL		(~0)

#define camel_debug_flag(type) \
	((camel_imapx_debug_flags & \
	CAMEL_IMAPX_DEBUG_ALL & CAMEL_IMAPX_DEBUG_ ## type) != 0)
#define camel_imapx_debug(type, tagprefix, fmt, ...) \
	G_STMT_START { \
		if (camel_debug_flag (type)) { \
			printf ("[imapx:%c] " fmt, tagprefix , ##__VA_ARGS__); \
			fflush (stdout); \
		} \
	} G_STMT_END

/* ********************************************************************** */

void imapx_utils_init (void);

/* chen adds from old imap provider - place it in right place */
gchar *		imapx_path_to_physical		(const gchar *prefix,
						 const gchar *vpath);
gchar *		imapx_get_temp_uid		(void);

gboolean	imapx_util_all_is_ascii		(const gchar *str);

gssize		imapx_splice_with_progress	(GOutputStream *output_stream,
						 GInputStream *input_stream,
						 goffset file_size,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_IMAPX_UTILS_H */

