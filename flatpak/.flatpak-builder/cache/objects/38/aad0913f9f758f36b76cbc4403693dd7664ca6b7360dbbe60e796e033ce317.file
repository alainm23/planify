/*
 * camel-imapx-mailbox.c
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

/**
 * SECTION: camel-imapx-mailbox
 * @include: camel/camel.h
 * @short_description: Stores the state of an IMAP mailbox
 *
 * #CamelIMAPXMailbox models the current state of an IMAP mailbox as
 * accumulated from untagged IMAP server responses in the current session.
 *
 * In particular, a #CamelIMAPXMailbox should <emphasis>not</emphasis> be
 * populated with locally cached information from the previous session.
 * This is why instantiation requires a #CamelIMAPXListResponse.
 **/

#include "evolution-data-server-config.h"

#include "camel-imapx-mailbox.h"
#include "camel-imapx-utils.h"

#define CAMEL_IMAPX_MAILBOX_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_MAILBOX, CamelIMAPXMailboxPrivate))

struct _CamelIMAPXMailboxPrivate {
	gchar *name;
	gchar separator;
	CamelIMAPXNamespace *namespace;

	guint32 messages;
	guint32 recent;
	guint32 unseen;
	guint32 uidnext;
	guint32 uidvalidity;
	guint64 highestmodseq;
	guint32 permanentflags;

	volatile gint change_stamp;

	CamelIMAPXMailboxState state;

	GMutex property_lock;
	GMutex update_lock;
	gint update_count;

	/* Protected by the "property_lock". */
	GHashTable *attributes;
	GSequence *message_map;
	gchar **quota_roots;
};

G_DEFINE_TYPE (
	CamelIMAPXMailbox,
	camel_imapx_mailbox,
	G_TYPE_OBJECT)

static gint
imapx_mailbox_message_map_compare (gconstpointer a,
                                   gconstpointer b,
                                   gpointer unused)
{
	guint32 uid_a = GPOINTER_TO_UINT (a);
	guint32 uid_b = GPOINTER_TO_UINT (b);

	return (uid_a == uid_b) ? 0 : (uid_a < uid_b) ? -1 : 1;
}

static void
imapx_mailbox_dispose (GObject *object)
{
	CamelIMAPXMailboxPrivate *priv;

	priv = CAMEL_IMAPX_MAILBOX_GET_PRIVATE (object);

	g_clear_object (&priv->namespace);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_imapx_mailbox_parent_class)->dispose (object);
}

static void
imapx_mailbox_finalize (GObject *object)
{
	CamelIMAPXMailboxPrivate *priv;

	priv = CAMEL_IMAPX_MAILBOX_GET_PRIVATE (object);

	g_free (priv->name);

	g_mutex_clear (&priv->property_lock);
	g_mutex_clear (&priv->update_lock);
	g_hash_table_destroy (priv->attributes);
	g_sequence_free (priv->message_map);
	g_strfreev (priv->quota_roots);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_imapx_mailbox_parent_class)->finalize (object);
}

static void
camel_imapx_mailbox_class_init (CamelIMAPXMailboxClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelIMAPXMailboxPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = imapx_mailbox_dispose;
	object_class->finalize = imapx_mailbox_finalize;
}

static void
camel_imapx_mailbox_init (CamelIMAPXMailbox *mailbox)
{
	mailbox->priv = CAMEL_IMAPX_MAILBOX_GET_PRIVATE (mailbox);

	g_mutex_init (&mailbox->priv->property_lock);
	g_mutex_init (&mailbox->priv->update_lock);
	mailbox->priv->message_map = g_sequence_new (NULL);
	mailbox->priv->permanentflags = ~0;
	mailbox->priv->state = CAMEL_IMAPX_MAILBOX_STATE_CREATED;
	mailbox->priv->update_count = 0;
	mailbox->priv->change_stamp = 0;
}

/**
 * camel_imapx_mailbox_new:
 * @response: a #CamelIMAPXListResponse
 * @namespace_: a #CamelIMAPXNamespace
 *
 * Creates a new #CamelIMAPXMailbox from @response and @namespace.
 *
 * The mailbox's name, path separator character, and attribute set are
 * initialized from the #CamelIMAPXListResponse.
 *
 * Returns: a #CamelIMAPXMailbox
 *
 * Since: 3.12
 **/
CamelIMAPXMailbox *
camel_imapx_mailbox_new (CamelIMAPXListResponse *response,
                         CamelIMAPXNamespace *namespace)
{
	CamelIMAPXMailbox *mailbox;
	GHashTable *attributes;
	const gchar *name;
	gchar separator;

	g_return_val_if_fail (CAMEL_IS_IMAPX_LIST_RESPONSE (response), NULL);
	g_return_val_if_fail (CAMEL_IS_IMAPX_NAMESPACE (namespace), NULL);

	name = camel_imapx_list_response_get_mailbox_name (response);
	separator = camel_imapx_list_response_get_separator (response);
	attributes = camel_imapx_list_response_dup_attributes (response);

	/* The INBOX mailbox is case-insensitive. */
	if (g_ascii_strcasecmp (name, "INBOX") == 0)
		name = "INBOX";

	mailbox = g_object_new (CAMEL_TYPE_IMAPX_MAILBOX, NULL);
	mailbox->priv->name = g_strdup (name);
	mailbox->priv->separator = separator;
	mailbox->priv->namespace = g_object_ref (namespace);
	mailbox->priv->attributes = attributes;  /* takes ownership */

	return mailbox;
}

/**
 * camel_imapx_mailbox_clone:
 * @mailbox: a #CamelIMAPXMailbox
 * @new_mailbox_name: new name for the cloned mailbox
 *
 * Creates an identical copy of @mailbox, except for the mailbox name.
 * The copied #CamelIMAPXMailbox is given the name @new_mailbox_name.
 *
 * The @new_mailbox_name must be in the same IMAP namespace as @mailbox.
 *
 * This is primarily useful for handling mailbox renames.  It is safer to
 * create a new #CamelIMAPXMailbox instance with the new name than to try
 * and rename an existing #CamelIMAPXMailbox, which could disrupt mailbox
 * operations in progress as well as data structures that track mailboxes
 * by name.
 *
 * Returns: a copy of @mailbox, named @new_mailbox_name
 *
 * Since: 3.12
 **/
CamelIMAPXMailbox *
camel_imapx_mailbox_clone (CamelIMAPXMailbox *mailbox,
                           const gchar *new_mailbox_name)
{
	CamelIMAPXMailbox *clone;
	GHashTableIter iter;
	gpointer key;

	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);
	g_return_val_if_fail (new_mailbox_name != NULL, NULL);

	/* The INBOX mailbox is case-insensitive. */
	if (g_ascii_strcasecmp (new_mailbox_name, "INBOX") == 0)
		new_mailbox_name = "INBOX";

	clone = g_object_new (CAMEL_TYPE_IMAPX_MAILBOX, NULL);
	clone->priv->name = g_strdup (new_mailbox_name);
	clone->priv->separator = mailbox->priv->separator;
	clone->priv->namespace = g_object_ref (mailbox->priv->namespace);

	clone->priv->messages = mailbox->priv->messages;
	clone->priv->recent = mailbox->priv->recent;
	clone->priv->unseen = mailbox->priv->unseen;
	clone->priv->uidnext = mailbox->priv->uidnext;
	clone->priv->uidvalidity = mailbox->priv->uidvalidity;
	clone->priv->highestmodseq = mailbox->priv->highestmodseq;
	clone->priv->state = mailbox->priv->state;

	clone->priv->quota_roots = g_strdupv (mailbox->priv->quota_roots);

	/* Use camel_imapx_list_response_dup_attributes()
	 * as a guide for cloning the mailbox attributes. */

	clone->priv->attributes = g_hash_table_new (camel_strcase_hash, camel_strcase_equal);

	g_mutex_lock (&mailbox->priv->property_lock);

	g_hash_table_iter_init (&iter, mailbox->priv->attributes);

	while (g_hash_table_iter_next (&iter, &key, NULL))
		g_hash_table_add (clone->priv->attributes, key);

	g_mutex_unlock (&mailbox->priv->property_lock);

	return clone;
}

/**
 * camel_imapx_mailbox_get_state:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns current state of the mailbox. This is used for folder
 * structure updates, to identify newly created, updated, renamed
 * or removed mailboxes.
 *
 * Returns: Current (update) state of the mailbox.
 *
 * Since: 3.16
 **/
CamelIMAPXMailboxState
camel_imapx_mailbox_get_state (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), CAMEL_IMAPX_MAILBOX_STATE_UNKNOWN);

	return mailbox->priv->state;
}

/**
 * camel_imapx_mailbox_set_state:
 * @mailbox: a #CamelIMAPXMailbox
 * @state: a new #CamelIMAPXMailboxState to set
 *
 * Sets current (update) state of the mailbox. This is used for folder
 * structure updates, to identify newly created, updated, renamed
 * or removed mailboxes.
 *
 * Since: 3.16
 **/
void
camel_imapx_mailbox_set_state (CamelIMAPXMailbox *mailbox,
			       CamelIMAPXMailboxState state)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	mailbox->priv->state = state;
}

/**
 * camel_imapx_mailbox_exists:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Convenience function returns whether @mailbox exists; that is, whether it
 * <emphasis>lacks</emphasis> a #CAMEL_IMAPX_LIST_ATTR_NONEXISTENT attribute.
 *
 * Non-existent mailboxes should generally be disregarded.
 *
 * Returns: whether @mailbox exists
 *
 * Since: 3.12
 **/
gboolean
camel_imapx_mailbox_exists (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	return !camel_imapx_mailbox_has_attribute (
		mailbox, CAMEL_IMAPX_LIST_ATTR_NONEXISTENT);
}

/**
 * camel_imapx_mailbox_compare:
 * @mailbox_a: the first #CamelIMAPXMailbox
 * @mailbox_b: the second #CamelIMAPXMailbox
 *
 * Compares two #CamelIMAPXMailbox instances by their mailbox names.
 *
 * Returns: a negative value if @mailbox_a compares before @mailbox_b,
 *          zero if they compare equal, or a positive value if @mailbox_a
 *          compares after @mailbox_b
 *
 * Since: 3.12
 **/
gint
camel_imapx_mailbox_compare (CamelIMAPXMailbox *mailbox_a,
                             CamelIMAPXMailbox *mailbox_b)
{
	const gchar *mailbox_name_a;
	const gchar *mailbox_name_b;

	mailbox_name_a = camel_imapx_mailbox_get_name (mailbox_a);
	mailbox_name_b = camel_imapx_mailbox_get_name (mailbox_b);

	return g_strcmp0 (mailbox_name_a, mailbox_name_b);
}

/**
 * camel_imapx_mailbox_matches:
 * @mailbox: a #CamelIMAPXMailbox
 * @pattern: mailbox name with possible wildcards
 *
 * Returns %TRUE if @mailbox's name matches @pattern.  The @pattern may
 * contain wildcard characters '*' and '%', which are interpreted similar
 * to the IMAP LIST command.
 *
 * Returns: %TRUE if @mailbox's name matches @pattern, %FALSE otherwise
 *
 * Since: 3.12
 **/
gboolean
camel_imapx_mailbox_matches (CamelIMAPXMailbox *mailbox,
                             const gchar *pattern)
{
	const gchar *name;
	gchar separator;
	gchar name_ch;
	gchar patt_ch;

	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);
	g_return_val_if_fail (pattern != NULL, FALSE);

	name = camel_imapx_mailbox_get_name (mailbox);
	separator = camel_imapx_mailbox_get_separator (mailbox);

	name_ch = *name++;
	patt_ch = *pattern++;

	while (name_ch != '\0' && patt_ch != '\0') {
		if (name_ch == patt_ch) {
			name_ch = *name++;
			patt_ch = *pattern++;
		} else if (patt_ch == '%') {
			if (name_ch != separator)
				name_ch = *name++;
			else
				patt_ch = *pattern++;
		} else {
			return (patt_ch == '*');
		}
	}

	return (name_ch == '\0') &&
		(patt_ch == '%' || patt_ch == '*' || patt_ch == '\0');
}

/**
 * camel_imapx_mailbox_get_name:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the mailbox name for @mailbox.
 *
 * Returns: the mailbox name
 *
 * Since: 3.12
 **/
const gchar *
camel_imapx_mailbox_get_name (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);

	return mailbox->priv->name;
}

/**
 * camel_imapx_mailbox_get_separator:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the path separator character for @mailbox.
 *
 * Returns: the mailbox path separator character
 *
 * Since: 3.12
 **/
gchar
camel_imapx_mailbox_get_separator (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), '\0');

	return mailbox->priv->separator;
}

/**
 * camel_imapx_mailbox_dup_folder_path:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the mailbox name as folder path.
 *
 * Returns: the mailbox name as folder path.
 *
 * Since: 3.16
 **/
gchar *
camel_imapx_mailbox_dup_folder_path (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);

	return camel_imapx_mailbox_to_folder_path (
		camel_imapx_mailbox_get_name (mailbox),
		camel_imapx_mailbox_get_separator (mailbox));
}

/**
 * camel_imapx_mailbox_get_namespace:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the #CamelIMAPXNamespace representing the IMAP server namespace
 * to which @mailbox belongs.
 *
 * Returns: a #CamelIMAPXNamespace
 *
 * Since: 3.12
 **/
CamelIMAPXNamespace *
camel_imapx_mailbox_get_namespace (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);

	return mailbox->priv->namespace;
}

/**
 * camel_imapx_mailbox_get_messages:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the last known number of messages in the mailbox.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Returns: the last known "MESSAGES" value
 *
 * Since: 3.12
 **/
guint32
camel_imapx_mailbox_get_messages (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), 0);

	return mailbox->priv->messages;
}

/**
 * camel_imapx_mailbox_set_messages:
 * @mailbox: a #CamelIMAPXMailbox
 * @messages: a newly-reported "MESSAGES" value
 *
 * Updates the last known number of messages in the mailbox.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_set_messages (CamelIMAPXMailbox *mailbox,
                                  guint32 messages)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	if (mailbox->priv->messages == messages)
		return;

	mailbox->priv->messages = messages;

	g_atomic_int_add (&mailbox->priv->change_stamp, 1);
}

/**
 * camel_imapx_mailbox_get_recent:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the last known number of messages with the \Recent flag set.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Returns: the last known "RECENT" value
 *
 * Since: 3.12
 **/
guint32
camel_imapx_mailbox_get_recent (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), 0);

	return mailbox->priv->recent;
}

/**
 * camel_imapx_mailbox_set_recent:
 * @mailbox: a #CamelIMAPXMailbox
 * @recent: a newly-reported "RECENT" value
 *
 * Updates the last known number of messages with the \Recent flag set.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_set_recent (CamelIMAPXMailbox *mailbox,
                                guint32 recent)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	if (mailbox->priv->recent == recent)
		return;

	mailbox->priv->recent = recent;

	g_atomic_int_add (&mailbox->priv->change_stamp, 1);
}

/**
 * camel_imapx_mailbox_get_unseen:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the last known number of messages which do not have the \Seen
 * flag set.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Returns: the last known "UNSEEN" value
 *
 * Since: 3.12
 **/
guint32
camel_imapx_mailbox_get_unseen (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), 0);

	return mailbox->priv->unseen;
}

/**
 * camel_imapx_mailbox_set_unseen:
 * @mailbox: a #CamelIMAPXMailbox
 * @unseen: a newly-reported "UNSEEN" value
 *
 * Updates the last known number of messages which do not have the \Seen
 * flag set.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_set_unseen (CamelIMAPXMailbox *mailbox,
                                guint32 unseen)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	if (mailbox->priv->unseen == unseen)
		return;

	mailbox->priv->unseen = unseen;

	g_atomic_int_add (&mailbox->priv->change_stamp, 1);
}

/**
 * camel_imapx_mailbox_get_uidnext:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the last known next unique identifier value of the mailbox.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Returns: the last known "UIDNEXT" value
 *
 * Since: 3.12
 **/
guint32
camel_imapx_mailbox_get_uidnext (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), 0);

	return mailbox->priv->uidnext;
}

/**
 * camel_imapx_mailbox_set_uidnext:
 * @mailbox: a #CamelIMAPXMailbox
 * @uidnext: a newly-reported "UIDNEXT" value
 *
 * Updates the last known next unique identifier value of the mailbox.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_set_uidnext (CamelIMAPXMailbox *mailbox,
                                 guint32 uidnext)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	if (mailbox->priv->uidnext == uidnext)
		return;

	mailbox->priv->uidnext = uidnext;

	g_atomic_int_add (&mailbox->priv->change_stamp, 1);
}

/**
 * camel_imapx_mailbox_get_uidvalidity:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the last known unique identifier validity value of the mailbox.
 *
 * This valud should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Returns: the last known "UIDVALIDITY" value
 *
 * Since: 3.12
 **/
guint32
camel_imapx_mailbox_get_uidvalidity (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), 0);

	return mailbox->priv->uidvalidity;
}

/**
 * camel_imapx_mailbox_set_uidvalidity:
 * @mailbox: a #CamelIMAPXMailbox
 * @uidvalidity: a newly-reported "UIDVALIDITY" value
 *
 * Updates the last known unique identifier validity value of the mailbox.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_set_uidvalidity (CamelIMAPXMailbox *mailbox,
                                     guint32 uidvalidity)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	if (mailbox->priv->uidvalidity == uidvalidity)
		return;

	mailbox->priv->uidvalidity = uidvalidity;

	g_atomic_int_add (&mailbox->priv->change_stamp, 1);
}

/**
 * camel_imapx_mailbox_get_highestmodseq:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the last known highest mod-sequence value of all messages in the
 * mailbox, or zero if the server does not support the persistent storage of
 * mod-sequences for the mailbox.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Returns: the last known "HIGHESTMODSEQ" value
 *
 * Since: 3.12
 **/
guint64
camel_imapx_mailbox_get_highestmodseq (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), 0);

	return mailbox->priv->highestmodseq;
}

/**
 * camel_imapx_mailbox_set_highestmodseq:
 * @mailbox: a #CamelIMAPXMailbox
 * @highestmodseq: a newly-reported "HIGHESTMODSEQ" value
 *
 * Updates the last known highest mod-sequence value of all messages in
 * the mailbox.  If the server does not support the persistent storage of
 * mod-sequences for the mailbox then the value should remain zero.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_set_highestmodseq (CamelIMAPXMailbox *mailbox,
                                       guint64 highestmodseq)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	if (mailbox->priv->highestmodseq == highestmodseq)
		return;

	mailbox->priv->highestmodseq = highestmodseq;

	g_atomic_int_add (&mailbox->priv->change_stamp, 1);
}

/**
 * camel_imapx_mailbox_get_permanentflags:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns: PERMANENTFLAGS response for the mailbox, or ~0, if the mailbox
 *    was not selected yet.
 *
 * Since: 3.16
 **/
guint32
camel_imapx_mailbox_get_permanentflags (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), ~0);

	return mailbox->priv->permanentflags;
}

/**
 * camel_imapx_mailbox_set_permanentflags:
 * @mailbox: a #CamelIMAPXMailbox
 * @permanentflags: a newly-reported "PERMANENTFLAGS" value
 *
 * Updates the last know value for PERMANENTFLAGS for this mailbox.
 *
 * Since: 3.16
 **/
void
camel_imapx_mailbox_set_permanentflags (CamelIMAPXMailbox *mailbox,
					guint32 permanentflags)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	if ((permanentflags & CAMEL_MESSAGE_USER) != 0) {
		permanentflags |= CAMEL_MESSAGE_JUNK;
		permanentflags |= CAMEL_MESSAGE_NOTJUNK;
	}

	mailbox->priv->permanentflags = permanentflags;
}

/**
 * camel_imapx_mailbox_dup_quota_roots:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Returns the last known list of quota roots for @mailbox as described
 * in <ulink url="http://tools.ietf.org/html/rfc2087">RFC 2087</ulink>,
 * or %NULL if no quota information for @mailbox is available.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * The returned newly-allocated, %NULL-terminated string array should
 * be freed with g_strfreev() when finished with it.
 *
 * Returns: the last known "QUOTAROOT" value
 *
 * Since: 3.12
 **/
gchar **
camel_imapx_mailbox_dup_quota_roots (CamelIMAPXMailbox *mailbox)
{
	gchar **quota_roots;

	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);

	g_mutex_lock (&mailbox->priv->property_lock);

	quota_roots = g_strdupv (mailbox->priv->quota_roots);

	g_mutex_unlock (&mailbox->priv->property_lock);

	return quota_roots;
}

/**
 * camel_imapx_mailbox_set_quota_roots:
 * @mailbox: a #CamelIMAPXMailbox
 * @quota_roots: a newly-reported "QUOTAROOT" value
 *
 * Updates the last known list of quota roots for @mailbox as described
 * in <ulink url="http://tools.ietf.org/html/rfc2087">RFC 2087</ulink>.
 *
 * This value should reflect the present state of the IMAP server as
 * reported through untagged server responses in the current session.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_set_quota_roots (CamelIMAPXMailbox *mailbox,
                                     const gchar **quota_roots)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	g_mutex_lock (&mailbox->priv->property_lock);

	g_strfreev (mailbox->priv->quota_roots);
	mailbox->priv->quota_roots = g_strdupv ((gchar **) quota_roots);

	g_mutex_unlock (&mailbox->priv->property_lock);
}

/**
 * camel_imapx_mailbox_copy_message_map:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Creates a copy of @mailbox's message map: a #GSequence of 32-bit integers
 * which map message sequence numbers (MSNs) to unique identifiers (UIDs).
 *
 * Free the returned #GSequence with g_sequence_free() when finished with it.
 *
 * Returns: a #GSequence mapping MSNs to UIDs
 *
 * Since: 3.12
 **/
GSequence *
camel_imapx_mailbox_copy_message_map (CamelIMAPXMailbox *mailbox)
{
	GSequence *copy;
	GSequenceIter *iter;

	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), NULL);

	copy = g_sequence_new (NULL);

	g_mutex_lock (&mailbox->priv->property_lock);

	iter = g_sequence_get_begin_iter (mailbox->priv->message_map);

	while (!g_sequence_iter_is_end (iter)) {
		gpointer data;

		data = g_sequence_get (iter);
		g_sequence_append (copy, data);

		iter = g_sequence_iter_next (iter);
	}

	g_mutex_unlock (&mailbox->priv->property_lock);

	return copy;
}

/**
 * camel_imapx_mailbox_take_message_map:
 * @mailbox: a #CamelIMAPXMailbox
 * @message_map: a #GSequence mapping MSNs to UIDs
 *
 * Takes ownership of a #GSequence of 32-bit integers which map message
 * sequence numbers (MSNs) to unique identifiers (UIDs) for @mailbox.
 *
 * The @message_map is expected to be assembled from a local cache of
 * previously fetched UIDs.  The @mailbox will update it as untagged
 * server responses are processed.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_take_message_map (CamelIMAPXMailbox *mailbox,
                                      GSequence *message_map)
{
	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));
	g_return_if_fail (message_map != NULL);

	g_mutex_lock (&mailbox->priv->property_lock);

	/* XXX GSequence is not reference counted. */
	if (message_map != mailbox->priv->message_map) {
		g_sequence_free (mailbox->priv->message_map);
		mailbox->priv->message_map = message_map;
	}

	g_mutex_unlock (&mailbox->priv->property_lock);
}

/**
 * camel_imapx_mailbox_get_msn_for_uid:
 * @mailbox: a #CamelIMAPXMailbox
 * @uid: a message's unique identifier
 * @out_msn: return location for the message's sequence number, or %NULL
 *
 * Given a message's unique identifier (@uid), write the message's sequence
 * number to @out_msn and return %TRUE.  If the unique identifier is unknown
 * (as far as @mailbox has been informed), the function returns %FALSE.
 *
 * Returns: whether @out_msn was set
 *
 * Since: 3.12
 **/
gboolean
camel_imapx_mailbox_get_msn_for_uid (CamelIMAPXMailbox *mailbox,
                                     guint32 uid,
                                     guint32 *out_msn)
{
	GSequence *message_map;
	GSequenceIter *iter;
	gboolean success = FALSE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	/* Remember: Message sequence numbers start at 1.
	 *           GSequence position numbers start at 0. */

	g_mutex_lock (&mailbox->priv->property_lock);

	message_map = mailbox->priv->message_map;
	iter = g_sequence_lookup (
		message_map, GUINT_TO_POINTER (uid),
		imapx_mailbox_message_map_compare, NULL);

	if (iter != NULL) {
		if (out_msn != NULL)
			*out_msn = g_sequence_iter_get_position (iter) + 1;
		success = TRUE;
	}

	g_mutex_unlock (&mailbox->priv->property_lock);

	return success;
}

/**
 * camel_imapx_mailbox_get_uid_for_msn:
 * @mailbox: a #CamelIMAPXMailbox
 * @msn: a message's sequence number (1..n)
 * @out_uid: return location for the message's unique identifier, or %NULL
 *
 * Given a message's sequence number (@msn), write the message's unique
 * identifier to @out_uid and return %TRUE.  If the sequence number is out of
 * range (as far as @mailbox has been informed), the function returns %FALSE.
 *
 * Returns: whether @out_uid was set
 *
 * Since: 3.12
 **/
gboolean
camel_imapx_mailbox_get_uid_for_msn (CamelIMAPXMailbox *mailbox,
                                     guint32 msn,
                                     guint32 *out_uid)
{
	GSequence *message_map;
	GSequenceIter *iter;
	gboolean success = FALSE;

	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);

	/* Remember: Message sequence numbers start at 1.
	 *           GSequence position numbers start at 0. */

	if (msn == 0)
		return FALSE;

	g_mutex_lock (&mailbox->priv->property_lock);

	message_map = mailbox->priv->message_map;
	iter = g_sequence_get_iter_at_pos (message_map, msn - 1);

	if (!g_sequence_iter_is_end (iter)) {
		if (out_uid != NULL) {
			gpointer data = g_sequence_get (iter);
			*out_uid = GPOINTER_TO_UINT (data);
		}
		success = TRUE;
	}

	g_mutex_unlock (&mailbox->priv->property_lock);

	return success;
}

/**
 * camel_imapx_mailbox_deleted:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Adds the #CAMEL_IMAPX_LIST_ATTR_NONEXISTENT attribute to @mailbox.
 *
 * Call this function after successfully completing a DELETE command.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_deleted (CamelIMAPXMailbox *mailbox)
{
	const gchar *attribute;

	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	attribute = CAMEL_IMAPX_LIST_ATTR_NONEXISTENT;

	g_mutex_lock (&mailbox->priv->property_lock);

	g_hash_table_add (
		mailbox->priv->attributes,
		(gpointer) g_intern_string (attribute));

	g_mutex_unlock (&mailbox->priv->property_lock);
}

/**
 * camel_imapx_mailbox_subscribed:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Add the #CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED attribute to @mailbox.
 *
 * Call this function after successfully completing a SUBSCRIBE command.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_subscribed (CamelIMAPXMailbox *mailbox)
{
	const gchar *attribute;

	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	attribute = CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED;

	g_mutex_lock (&mailbox->priv->property_lock);

	g_hash_table_add (
		mailbox->priv->attributes,
		(gpointer) g_intern_string (attribute));

	g_mutex_unlock (&mailbox->priv->property_lock);
}

/**
 * camel_imapx_mailbox_unsubscribed:
 * @mailbox: a #CamelIMAPXMailbox
 *
 * Removes the #CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED attribute from @mailbox.
 *
 * Call this function after successfully completing an UNSUBSCRIBE command.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_unsubscribed (CamelIMAPXMailbox *mailbox)
{
	const gchar *attribute;

	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));

	attribute = CAMEL_IMAPX_LIST_ATTR_SUBSCRIBED;

	g_mutex_lock (&mailbox->priv->property_lock);

	g_hash_table_remove (mailbox->priv->attributes, attribute);

	g_mutex_unlock (&mailbox->priv->property_lock);
}

/**
 * camel_imapx_mailbox_has_attribute:
 * @mailbox: a #CamelIMAPXMailbox
 * @attribute: a mailbox attribute
 *
 * Returns whether @mailbox includes the given mailbox attribute.
 * The @attribute should be one of the LIST attribute macros defined
 * for #CamelIMAPXListResponse.
 *
 * Returns: %TRUE if @mailbox has @attribute, or else %FALSE
 *
 * Since: 3.12
 **/
gboolean
camel_imapx_mailbox_has_attribute (CamelIMAPXMailbox *mailbox,
                                   const gchar *attribute)
{
	gboolean has_it;

	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), FALSE);
	g_return_val_if_fail (attribute != NULL, FALSE);

	g_mutex_lock (&mailbox->priv->property_lock);

	has_it = g_hash_table_contains (mailbox->priv->attributes, attribute);

	g_mutex_unlock (&mailbox->priv->property_lock);

	return has_it;
}

/**
 * camel_imapx_mailbox_handle_list_response:
 * @mailbox: a #CamelIMAPXMailbox
 * @response: a #CamelIMAPXListResponse
 *
 * Updates the internal state of @mailbox from the data in @response.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_handle_list_response (CamelIMAPXMailbox *mailbox,
                                          CamelIMAPXListResponse *response)
{
	GHashTable *attributes;

	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));
	g_return_if_fail (CAMEL_IS_IMAPX_LIST_RESPONSE (response));

	attributes = camel_imapx_list_response_dup_attributes (response);

	g_mutex_lock (&mailbox->priv->property_lock);

	g_hash_table_destroy (mailbox->priv->attributes);
	mailbox->priv->attributes = attributes;  /* takes ownership */

	g_mutex_unlock (&mailbox->priv->property_lock);
}

/**
 * camel_imapx_mailbox_handle_lsub_response:
 * @mailbox: a #CamelIMAPXMailbox
 * @response: a #CamelIMAPXListResponse
 *
 * Updates the internal state of @mailbox from the data in @response.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_handle_lsub_response (CamelIMAPXMailbox *mailbox,
                                          CamelIMAPXListResponse *response)
{
	GHashTable *attributes;
	GHashTableIter iter;
	gpointer key;

	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));
	g_return_if_fail (CAMEL_IS_IMAPX_LIST_RESPONSE (response));

	/* LIST responses are more authoritative than LSUB responses,
	 * so instead of replacing the old attribute set as we would
	 * for a LIST response, we'll merge the LSUB attributes. */

	attributes = camel_imapx_list_response_dup_attributes (response);

	g_hash_table_iter_init (&iter, attributes);

	g_mutex_lock (&mailbox->priv->property_lock);

	while (g_hash_table_iter_next (&iter, &key, NULL))
		g_hash_table_add (mailbox->priv->attributes, key);

	g_mutex_unlock (&mailbox->priv->property_lock);

	g_hash_table_destroy (attributes);
}

/**
 * camel_imapx_mailbox_handle_status_response:
 * @mailbox: a #CamelIMAPXMailbox
 * @response: a #CamelIMAPXStatusResponse
 *
 * Updates the internal state of @mailbox from the data in @response.
 *
 * Since: 3.12
 **/
void
camel_imapx_mailbox_handle_status_response (CamelIMAPXMailbox *mailbox,
                                            CamelIMAPXStatusResponse *response)
{
	guint32 value32;
	guint64 value64;

	g_return_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox));
	g_return_if_fail (CAMEL_IS_IMAPX_STATUS_RESPONSE (response));

	if (camel_imapx_status_response_get_messages (response, &value32))
		camel_imapx_mailbox_set_messages (mailbox, value32);

	if (camel_imapx_status_response_get_recent (response, &value32))
		camel_imapx_mailbox_set_recent (mailbox, value32);

	if (camel_imapx_status_response_get_unseen (response, &value32))
		camel_imapx_mailbox_set_unseen (mailbox, value32);

	if (camel_imapx_status_response_get_uidnext (response, &value32))
		camel_imapx_mailbox_set_uidnext (mailbox, value32);

	if (camel_imapx_status_response_get_uidvalidity (response, &value32))
		camel_imapx_mailbox_set_uidvalidity (mailbox, value32);

	if (camel_imapx_status_response_get_highestmodseq (response, &value64))
		camel_imapx_mailbox_set_highestmodseq (mailbox, value64);
}

gint
camel_imapx_mailbox_get_update_count (CamelIMAPXMailbox *mailbox)
{
	gint res;

	g_mutex_lock (&mailbox->priv->update_lock);
	res = mailbox->priv->update_count;
	g_mutex_unlock (&mailbox->priv->update_lock);

	return res;
}

void
camel_imapx_mailbox_inc_update_count (CamelIMAPXMailbox *mailbox,
				      gint inc)
{
	g_mutex_lock (&mailbox->priv->update_lock);
	mailbox->priv->update_count += inc;
	g_mutex_unlock (&mailbox->priv->update_lock);
}

gint
camel_imapx_mailbox_get_change_stamp (CamelIMAPXMailbox *mailbox)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_MAILBOX (mailbox), 0);

	return mailbox->priv->change_stamp;
}
