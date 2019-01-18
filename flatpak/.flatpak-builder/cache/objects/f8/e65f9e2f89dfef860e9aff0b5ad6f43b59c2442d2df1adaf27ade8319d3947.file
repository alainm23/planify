/*
 * camel-imapx-mailbox.h
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

#ifndef CAMEL_IMAPX_MAILBOX_H
#define CAMEL_IMAPX_MAILBOX_H

#include "camel-imapx-namespace.h"
#include "camel-imapx-list-response.h"
#include "camel-imapx-status-response.h"

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_MAILBOX \
	(camel_imapx_mailbox_get_type ())
#define CAMEL_IMAPX_MAILBOX(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_MAILBOX, CamelIMAPXMailbox))
#define CAMEL_IMAPX_MAILBOX_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_MAILBOX, CamelIMAPXMailboxClass))
#define CAMEL_IS_IMAPX_MAILBOX(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_MAILBOX))
#define CAMEL_IS_IMAPX_MAILBOX_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_MAILBOX))
#define CAMEL_IMAPX_MAILBOX_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_MAILBOX, CamelIMAPXMailboxClass))

G_BEGIN_DECLS

typedef struct _CamelIMAPXMailbox CamelIMAPXMailbox;
typedef struct _CamelIMAPXMailboxClass CamelIMAPXMailboxClass;
typedef struct _CamelIMAPXMailboxPrivate CamelIMAPXMailboxPrivate;

typedef enum {
	CAMEL_IMAPX_MAILBOX_STATE_UNKNOWN,
	CAMEL_IMAPX_MAILBOX_STATE_CREATED,
	CAMEL_IMAPX_MAILBOX_STATE_UPDATED,
	CAMEL_IMAPX_MAILBOX_STATE_RENAMED
} CamelIMAPXMailboxState;

/**
 * CamelIMAPXMailbox:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.12
 **/
struct _CamelIMAPXMailbox {
	/*< private >*/
	GObject parent;
	CamelIMAPXMailboxPrivate *priv;
};

struct _CamelIMAPXMailboxClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_mailbox_get_type
					(void) G_GNUC_CONST;
CamelIMAPXMailbox *
		camel_imapx_mailbox_new	(CamelIMAPXListResponse *response,
					 CamelIMAPXNamespace *namespace_);
CamelIMAPXMailbox *
		camel_imapx_mailbox_clone
					(CamelIMAPXMailbox *mailbox,
					 const gchar *new_mailbox_name);
CamelIMAPXMailboxState
		camel_imapx_mailbox_get_state
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_state
					(CamelIMAPXMailbox *mailbox,
					 CamelIMAPXMailboxState state);
gboolean	camel_imapx_mailbox_exists
					(CamelIMAPXMailbox *mailbox);
gint		camel_imapx_mailbox_compare
					(CamelIMAPXMailbox *mailbox_a,
					 CamelIMAPXMailbox *mailbox_b);
gboolean	camel_imapx_mailbox_matches
					(CamelIMAPXMailbox *mailbox,
					 const gchar *pattern);
const gchar *	camel_imapx_mailbox_get_name
					(CamelIMAPXMailbox *mailbox);
gchar		camel_imapx_mailbox_get_separator
					(CamelIMAPXMailbox *mailbox);
gchar *		camel_imapx_mailbox_dup_folder_path
					(CamelIMAPXMailbox *mailbox);
CamelIMAPXNamespace *
		camel_imapx_mailbox_get_namespace
					(CamelIMAPXMailbox *mailbox);
guint32		camel_imapx_mailbox_get_messages
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_messages
					(CamelIMAPXMailbox *mailbox,
					 guint32 messages);
guint32		camel_imapx_mailbox_get_recent
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_recent
					(CamelIMAPXMailbox *mailbox,
					 guint32 recent);
guint32		camel_imapx_mailbox_get_unseen
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_unseen
					(CamelIMAPXMailbox *mailbox,
					 guint32 unseen);
guint32		camel_imapx_mailbox_get_uidnext
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_uidnext
					(CamelIMAPXMailbox *mailbox,
					 guint32 uidnext);
guint32		camel_imapx_mailbox_get_uidvalidity
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_uidvalidity
					(CamelIMAPXMailbox *mailbox,
					 guint32 uidvalidity);
guint64		camel_imapx_mailbox_get_highestmodseq
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_highestmodseq
					(CamelIMAPXMailbox *mailbox,
					 guint64 highestmodseq);
guint32		camel_imapx_mailbox_get_permanentflags
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_permanentflags
					(CamelIMAPXMailbox *mailbox,
					 guint32 permanentflags);
gchar **	camel_imapx_mailbox_dup_quota_roots
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_set_quota_roots
					(CamelIMAPXMailbox *mailbox,
					 const gchar **quota_roots);
GSequence *	camel_imapx_mailbox_copy_message_map
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_take_message_map
					(CamelIMAPXMailbox *mailbox,
					 GSequence *message_map);
gboolean	camel_imapx_mailbox_get_msn_for_uid
					(CamelIMAPXMailbox *mailbox,
					 guint32 uid,
					 guint32 *out_msn);
gboolean	camel_imapx_mailbox_get_uid_for_msn
					(CamelIMAPXMailbox *mailbox,
					 guint32 msn,
					 guint32 *out_uid);
void		camel_imapx_mailbox_deleted
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_subscribed
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_unsubscribed
					(CamelIMAPXMailbox *mailbox);
gboolean	camel_imapx_mailbox_has_attribute
					(CamelIMAPXMailbox *mailbox,
					 const gchar *attribute);
void		camel_imapx_mailbox_handle_list_response
					(CamelIMAPXMailbox *mailbox,
					 CamelIMAPXListResponse *response);
void		camel_imapx_mailbox_handle_lsub_response
					(CamelIMAPXMailbox *mailbox,
					 CamelIMAPXListResponse *response);
void		camel_imapx_mailbox_handle_status_response
					(CamelIMAPXMailbox *mailbox,
					 CamelIMAPXStatusResponse *response);

gint		camel_imapx_mailbox_get_update_count
					(CamelIMAPXMailbox *mailbox);
void		camel_imapx_mailbox_inc_update_count
					(CamelIMAPXMailbox *mailbox,
					 gint inc);
gint		camel_imapx_mailbox_get_change_stamp
					(CamelIMAPXMailbox *mailbox);

G_END_DECLS

#endif /* CAMEL_IMAPX_MAILBOX_H */

