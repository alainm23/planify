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

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <string.h>

#include "camel-db.h"
#include "camel-folder.h"
#include "camel-folder-summary.h"
#include "camel-message-info-base.h"
#include "camel-string-utils.h"
#include "camel-weak-ref-group.h"

#include "camel-message-info.h"

struct _CamelMessageInfoPrivate {
	GRecMutex property_lock;

	CamelWeakRefGroup *summary_wrg;	/* CamelFolderSummary * */
	gboolean dirty;			/* whether requires save to local disk/summary */
	const gchar *uid;		/* allocated in the string pool */
	gboolean abort_notifications;
	gboolean thaw_notify_folder;
	gboolean thaw_notify_folder_with_counts;
	guint freeze_notifications;
	guint folder_flagged_stamp;
};

enum {
	PROP_0,
	PROP_SUMMARY,
	PROP_DIRTY,
	PROP_FOLDER_FLAGGED,
	PROP_FOLDER_FLAGGED_STAMP,
	PROP_ABORT_NOTIFICATIONS,
	PROP_UID,
	PROP_FLAGS,
	PROP_USER_FLAGS,
	PROP_USER_TAGS,
	PROP_SUBJECT,
	PROP_FROM,
	PROP_TO,
	PROP_CC,
	PROP_MLIST,
	PROP_SIZE,
	PROP_DATE_SENT,
	PROP_DATE_RECEIVED,
	PROP_MESSAGE_ID,
	PROP_REFERENCES,
	PROP_HEADERS
};

G_DEFINE_ABSTRACT_TYPE (CamelMessageInfo, camel_message_info, G_TYPE_OBJECT)

static CamelMessageInfo *
message_info_clone (const CamelMessageInfo *mi,
		    CamelFolderSummary *assign_summary)
{
	CamelMessageInfo *result;
	const gchar *uid;
	const GArray *references;
	const CamelNameValueArray *headers;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);
	if (assign_summary)
		g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (assign_summary), NULL);

	/* Make sure the 'mi' doesn't change while copying the values. */
	camel_message_info_property_lock (mi);

	if (!assign_summary) {
		CamelFolderSummary *mi_summary;

		mi_summary = camel_message_info_ref_summary (mi);
		result = camel_message_info_new (mi_summary);
		g_clear_object (&mi_summary);
	} else {
		result = camel_message_info_new (assign_summary);
	}

	g_object_freeze_notify (G_OBJECT (result));
	camel_message_info_set_abort_notifications (result, TRUE);

	uid = camel_message_info_pooldup_uid (mi);
	camel_message_info_set_uid (result, uid);
	camel_pstring_free (uid);

	camel_message_info_take_user_flags (result, camel_message_info_dup_user_flags (mi));
	camel_message_info_take_user_tags (result, camel_message_info_dup_user_tags (mi));
	camel_message_info_set_subject (result, camel_message_info_get_subject (mi));
	camel_message_info_set_from (result, camel_message_info_get_from (mi));
	camel_message_info_set_to (result, camel_message_info_get_to (mi));
	camel_message_info_set_cc (result, camel_message_info_get_cc (mi));
	camel_message_info_set_mlist (result, camel_message_info_get_mlist (mi));
	camel_message_info_set_size (result, camel_message_info_get_size (mi));
	camel_message_info_set_date_sent (result, camel_message_info_get_date_sent (mi));
	camel_message_info_set_date_received (result, camel_message_info_get_date_received (mi));
	camel_message_info_set_message_id (result, camel_message_info_get_message_id (mi));

	references = camel_message_info_get_references (mi);
	if (references && references->len) {
		GArray *copy;
		guint ii;

		copy = g_array_sized_new (FALSE, FALSE, sizeof (guint64), references->len);

		for (ii = 0; ii < references->len; ii++) {
			guint64 refr = g_array_index (references, guint64, ii);

			g_array_append_val (copy, refr);
		}

		camel_message_info_take_references (result, copy);
	}

	headers = camel_message_info_get_headers (mi);
	if (headers) {
		camel_message_info_take_headers (result,
			camel_name_value_array_copy (headers));
	}

	/* Set flags as the last, to not overwrite 'folder-flagged' flag by
	   the "changes" when copying fields. */
	camel_message_info_set_flags (result, ~0, camel_message_info_get_flags (mi));

	camel_message_info_property_unlock (mi);

	/* Also ensure 'dirty' flag, thus it can be eventually saved. */
	camel_message_info_set_dirty (result, TRUE);

	camel_message_info_set_abort_notifications (result, FALSE);
	g_object_thaw_notify (G_OBJECT (result));

	return result;
}

static gboolean
message_info_load (CamelMessageInfo *mi,
		   const CamelMIRecord *record,
		   /* const */ gchar **bdata_ptr)
{
	gint ii, count;
	gchar *part, *label;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (record != NULL, FALSE);
	g_return_val_if_fail (bdata_ptr != NULL, FALSE);

	camel_message_info_set_uid (mi, record->uid);
	camel_message_info_set_flags (mi, ~0, record->flags);
	camel_message_info_set_size (mi, record->size);
	camel_message_info_set_date_sent (mi, record->dsent);
	camel_message_info_set_date_received (mi, record->dreceived);

	camel_message_info_set_subject (mi, record->subject);
	camel_message_info_set_from (mi, record->from);
	camel_message_info_set_to (mi, record->to);
	camel_message_info_set_cc (mi, record->cc);
	camel_message_info_set_mlist (mi, record->mlist);

	/* Extract Message id & References */
	part = record->part;
	if (part) {
		CamelSummaryMessageID message_id;

		message_id.id.part.hi = camel_util_bdata_get_number (&part, 0);
		message_id.id.part.lo = camel_util_bdata_get_number (&part, 0);

		camel_message_info_set_message_id (mi, message_id.id.id);

		count = camel_util_bdata_get_number (&part, 0);

		if (count > 0) {
			GArray *references = g_array_sized_new (FALSE, FALSE, sizeof (guint64), count);

			for (ii = 0; ii < count; ii++) {
				message_id.id.part.hi = camel_util_bdata_get_number (&part, 0);
				message_id.id.part.lo = camel_util_bdata_get_number (&part, 0);

				g_array_append_val (references, message_id.id.id);
			}

			camel_message_info_take_references (mi, references);
		}
	}

	/* Extract User flags/labels */
	part = record->labels;
	if (part) {
		CamelNamedFlags *user_flags;

		user_flags = camel_named_flags_new ();

		label = part;
		for (ii = 0; part[ii]; ii++) {
			if (part[ii] == ' ') {
				part[ii] = 0;
				if (label && *label)
					camel_named_flags_insert (user_flags, label);
				label = &(part[ii + 1]);
				part[ii] = ' ';
			}
		}
		if (label && *label)
			camel_named_flags_insert (user_flags, label);

		camel_message_info_take_user_flags (mi, user_flags);
	}

	/* Extract User tags */
	part = record->usertags;
	if (part) {
		CamelNameValueArray *user_tags;

		count = camel_util_bdata_get_number (&part, 0);

		user_tags = camel_name_value_array_new_sized (count);

		for (ii = 0; ii < count; ii++) {
			gchar *name, *value;

			name = camel_util_bdata_get_string (&part, NULL);
			value = camel_util_bdata_get_string (&part, NULL);

			if (name)
				camel_name_value_array_set_named (user_tags, CAMEL_COMPARE_CASE_SENSITIVE, name, value ? value : "");

			g_free (name);
			g_free (value);
		}

		camel_message_info_take_user_tags (mi, user_tags);
	}

	return TRUE;
}

static gboolean
message_info_save (const CamelMessageInfo *mi,
		   CamelMIRecord *record,
		   GString *bdata_str)
{
	GString *tmp;
	CamelSummaryMessageID message_id;
	const CamelNamedFlags *user_flags;
	const CamelNameValueArray *user_tags;
	const GArray *references;
	guint32 read_or_flags = CAMEL_MESSAGE_DELETED | CAMEL_MESSAGE_JUNK;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (record != NULL, FALSE);
	g_return_val_if_fail (bdata_str != NULL, FALSE);

	record->uid = (gchar *) camel_pstring_strdup (camel_message_info_get_uid (mi));
	record->flags = camel_message_info_get_flags (mi);

	if ((record->flags & CAMEL_MESSAGE_JUNK) != 0) {
		CamelFolderSummary *folder_summary;

		folder_summary = camel_message_info_ref_summary (mi);
		if (folder_summary) {
			CamelFolder *folder;

			folder = camel_folder_summary_get_folder (folder_summary);
			if (folder) {
				guint32 folder_flags = camel_folder_get_flags (folder);

				/* Do not consider Junk flag as message being read when it's a Junk folder */
				if ((folder_flags & CAMEL_FOLDER_IS_JUNK) != 0)
					read_or_flags = read_or_flags & (~CAMEL_MESSAGE_JUNK);
			}

			g_object_unref (folder_summary);
		}
	}

	record->read = ((record->flags & (CAMEL_MESSAGE_SEEN | read_or_flags))) ? 1 : 0;
	record->deleted = (record->flags & CAMEL_MESSAGE_DELETED) != 0 ? 1 : 0;
	record->replied = (record->flags & CAMEL_MESSAGE_ANSWERED) != 0 ? 1 : 0;
	record->important = (record->flags & CAMEL_MESSAGE_FLAGGED) != 0 ? 1 : 0;
	record->junk = (record->flags & CAMEL_MESSAGE_JUNK) != 0 ? 1 : 0;
	record->dirty = (record->flags & CAMEL_MESSAGE_FOLDER_FLAGGED) != 0 ? 1 : 0;
	record->attachment = (record->flags & CAMEL_MESSAGE_ATTACHMENTS) != 0 ? 1 : 0;

	record->size = camel_message_info_get_size (mi);
	record->dsent = camel_message_info_get_date_sent (mi);
	record->dreceived = camel_message_info_get_date_received (mi);

	record->subject = g_strdup (camel_message_info_get_subject (mi));
	record->from = g_strdup (camel_message_info_get_from (mi));
	record->to = g_strdup (camel_message_info_get_to (mi));
	record->cc = g_strdup (camel_message_info_get_cc (mi));
	record->mlist = g_strdup (camel_message_info_get_mlist (mi));

	record->followup_flag = g_strdup (camel_message_info_get_user_tag (mi, "follow-up"));
	record->followup_completed_on = g_strdup (camel_message_info_get_user_tag (mi, "completed-on"));
	record->followup_due_by = g_strdup (camel_message_info_get_user_tag (mi, "due-by"));

	tmp = g_string_new (NULL);
	message_id.id.id = camel_message_info_get_message_id (mi);
	g_string_append_printf (tmp, "%lu %lu ", (gulong) message_id.id.part.hi, (gulong) message_id.id.part.lo);
	references = camel_message_info_get_references (mi);
	if (references) {
		guint ii;

		g_string_append_printf (tmp, "%lu", (gulong) references->len);
		for (ii = 0; ii < references->len; ii++) {
			message_id.id.id = g_array_index (references, guint64, ii);

			g_string_append_printf (tmp, " %lu %lu", (gulong) message_id.id.part.hi, (gulong) message_id.id.part.lo);
		}
	} else {
		g_string_append (tmp, "0");
	}
	record->part = g_string_free (tmp, FALSE);

	tmp = g_string_new (NULL);
	user_flags = camel_message_info_get_user_flags (mi);
	if (user_flags) {
		guint ii, count;

		count = camel_named_flags_get_length (user_flags);
		for (ii = 0; ii < count; ii++) {
			const gchar *name = camel_named_flags_get (user_flags, ii);

			if (name && *name) {
				if (tmp->len)
					g_string_append (tmp, " ");
				g_string_append (tmp, name);
			}
		}
	}
	record->labels = g_string_free (tmp, FALSE);

	tmp = g_string_new (NULL);
	user_tags = camel_message_info_get_user_tags (mi);
	if (user_tags) {
		guint ii, count;

		count = camel_name_value_array_get_length (user_tags);
		g_string_append_printf (tmp, "%lu", (gulong) count);

		for (ii = 0; ii < count; ii++) {
			const gchar *name = NULL, *value = NULL;

			if (camel_name_value_array_get (user_tags, ii, &name, &value)) {
				if (!name)
					name = "";
				if (!value)
					value = "";

				g_string_append_printf (tmp, " %lu-%s %lu-%s", (gulong) strlen (name), name, (gulong) strlen (value), value);
			}
		}
	} else {
		g_string_append (tmp, "0");
	}
	record->usertags = g_string_free (tmp, FALSE);

	return TRUE;
}

static void
message_info_set_property (GObject *object,
			   guint property_id,
			   const GValue *value,
			   GParamSpec *pspec)
{
	CamelMessageInfo *mi = CAMEL_MESSAGE_INFO (object);

	switch (property_id) {
	case PROP_SUMMARY:
		camel_weak_ref_group_set (mi->priv->summary_wrg, g_value_get_object (value));
		return;

	case PROP_DIRTY:
		camel_message_info_set_dirty (mi, g_value_get_boolean (value));
		return;

	case PROP_FOLDER_FLAGGED:
		camel_message_info_set_folder_flagged (mi, g_value_get_boolean (value));
		return;

	case PROP_ABORT_NOTIFICATIONS:
		camel_message_info_set_abort_notifications (mi, g_value_get_boolean (value));
		return;

	case PROP_UID:
		camel_message_info_set_uid (mi, g_value_get_string (value));
		return;

	case PROP_FLAGS:
		camel_message_info_set_flags (mi, ~0, g_value_get_uint (value));
		return;

	case PROP_USER_FLAGS:
		camel_message_info_take_user_flags (mi, g_value_dup_boxed (value));
		return;

	case PROP_USER_TAGS:
		camel_message_info_take_user_tags (mi, g_value_dup_boxed (value));
		return;

	case PROP_SUBJECT:
		camel_message_info_set_subject (mi, g_value_get_string (value));
		return;

	case PROP_FROM:
		camel_message_info_set_from (mi, g_value_get_string (value));
		return;

	case PROP_TO:
		camel_message_info_set_to (mi, g_value_get_string (value));
		return;

	case PROP_CC:
		camel_message_info_set_cc (mi, g_value_get_string (value));
		return;

	case PROP_MLIST:
		camel_message_info_set_mlist (mi, g_value_get_string (value));
		return;

	case PROP_SIZE:
		camel_message_info_set_size (mi, g_value_get_uint (value));
		return;

	case PROP_DATE_SENT:
		camel_message_info_set_date_sent (mi, g_value_get_int64 (value));
		return;

	case PROP_DATE_RECEIVED:
		camel_message_info_set_date_received (mi, g_value_get_int64 (value));
		return;

	case PROP_MESSAGE_ID:
		camel_message_info_set_message_id (mi, g_value_get_uint64 (value));
		return;

	case PROP_REFERENCES:
		camel_message_info_take_references (mi, g_value_dup_boxed (value));
		return;

	case PROP_HEADERS:
		camel_message_info_take_headers (mi, g_value_dup_boxed (value));
		return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
message_info_get_property (GObject *object,
			   guint property_id,
			   GValue *value,
			   GParamSpec *pspec)
{
	CamelMessageInfo *mi = CAMEL_MESSAGE_INFO (object);

	switch (property_id) {
	case PROP_SUMMARY:
		g_value_take_object (value, camel_message_info_ref_summary (mi));
		return;

	case PROP_DIRTY:
		g_value_set_boolean (value, camel_message_info_get_dirty (mi));
		return;

	case PROP_FOLDER_FLAGGED:
		g_value_set_boolean (value, camel_message_info_get_folder_flagged (mi));
		return;

	case PROP_FOLDER_FLAGGED_STAMP:
		g_value_set_uint (value, camel_message_info_get_folder_flagged_stamp (mi));
		return;

	case PROP_ABORT_NOTIFICATIONS:
		g_value_set_boolean (value, camel_message_info_get_abort_notifications (mi));
		return;

	case PROP_UID:
		g_value_set_string (value, camel_message_info_get_uid (mi));
		return;

	case PROP_FLAGS:
		g_value_set_uint (value, camel_message_info_get_flags (mi));
		return;

	case PROP_USER_FLAGS:
		g_value_take_boxed (value, camel_message_info_dup_user_flags (mi));
		return;

	case PROP_USER_TAGS:
		g_value_take_boxed (value, camel_message_info_dup_user_tags (mi));
		return;

	case PROP_SUBJECT:
		g_value_set_string (value, camel_message_info_get_subject (mi));
		return;

	case PROP_FROM:
		g_value_set_string (value, camel_message_info_get_from (mi));
		return;

	case PROP_TO:
		g_value_set_string (value, camel_message_info_get_to (mi));
		return;

	case PROP_CC:
		g_value_set_string (value, camel_message_info_get_cc (mi));
		return;

	case PROP_MLIST:
		g_value_set_string (value, camel_message_info_get_mlist (mi));
		return;

	case PROP_SIZE:
		g_value_set_uint (value, camel_message_info_get_size (mi));
		return;

	case PROP_DATE_SENT:
		g_value_set_int64 (value, camel_message_info_get_date_sent (mi));
		return;

	case PROP_DATE_RECEIVED:
		g_value_set_int64 (value, camel_message_info_get_date_received (mi));
		return;

	case PROP_MESSAGE_ID:
		g_value_set_uint64 (value, camel_message_info_get_message_id (mi));
		return;

	case PROP_REFERENCES:
		g_value_take_boxed (value, camel_message_info_dup_references (mi));
		return;

	case PROP_HEADERS:
		g_value_take_boxed (value, camel_message_info_dup_headers (mi));
		return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
message_info_dispose (GObject *object)
{
	CamelMessageInfo *mi = CAMEL_MESSAGE_INFO (object);

	camel_weak_ref_group_set (mi->priv->summary_wrg, NULL);
	camel_pstring_free (mi->priv->uid);
	mi->priv->uid = NULL;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_message_info_parent_class)->dispose (object);
}

static void
message_info_finalize (GObject *object)
{
	CamelMessageInfo *mi = CAMEL_MESSAGE_INFO (object);

	camel_weak_ref_group_unref (mi->priv->summary_wrg);
	g_rec_mutex_clear (&mi->priv->property_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_message_info_parent_class)->finalize (object);
}

static void
camel_message_info_class_init (CamelMessageInfoClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelMessageInfoPrivate));

	class->clone = message_info_clone;
	class->load = message_info_load;
	class->save = message_info_save;

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = message_info_set_property;
	object_class->get_property = message_info_get_property;
	object_class->dispose = message_info_dispose;
	object_class->finalize = message_info_finalize;

	/**
	 * CamelMessageInfo:summary
	 *
	 * The #CamelFolderSummary to which the message info belongs, or %NULL.
	 * It can be set only during construction of the object.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_SUMMARY,
		g_param_spec_object (
			"summary",
			"Summary",
			NULL,
			CAMEL_TYPE_FOLDER_SUMMARY,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY));

	/**
	 * CamelMessageInfo:uid
	 *
	 * A unique ID of the message in its folder.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_UID,
		g_param_spec_string (
			"uid",
			"UID",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:dirty
	 *
	 * Flag, whether the info is changed and requires save to disk.
	 * Compare with CamelMessageInfo:folder-flagged
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_DIRTY,
		g_param_spec_boolean (
			"dirty",
			"Dirty",
			NULL,
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:folder-flagged
	 *
	 * Flag, whether the info is changed and requires save to
	 * the destination store/server. This is different from
	 * the CamelMessageInfo:dirty, which takes care of the local
	 * information only.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_FOLDER_FLAGGED,
		g_param_spec_boolean (
			"folder-flagged",
			"Folder Flagged",
			NULL,
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:folder-flagged-stamp
	 *
	 * The 'folder-flagged-stamp' is a stamp of the 'folder-flagged' flag. This stamp
	 * changes whenever anything would mark the @mi 'folder-flagged', regardless the @mi
	 * being already 'folder-flagged'. It can be used to recognize changes
	 * on the 'folder-flagged' flag during the time.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_FOLDER_FLAGGED_STAMP,
		g_param_spec_uint (
			"folder-flagged-stamp",
			"Folder Flagged Stamp",
			NULL,
			0, G_MAXUINT, 0,
			G_PARAM_READABLE));

	/**
	 * CamelMessageInfo:abort-notifications
	 *
	 * Flag, whether the info is currently aborting notifications. It is used to avoid
	 * unnecessary 'folder-flagged' and 'dirty' flags changes and also to avoid
	 * associated folder's "changed" signal.
	 *f
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_ABORT_NOTIFICATIONS,
		g_param_spec_boolean (
			"abort-notifications",
			"Abort Notifications",
			NULL,
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:flags
	 *
	 * Bit-or of #CamelMessageFlags.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_FLAGS,
		g_param_spec_uint (
			"flags",
			"Flags",
			NULL,
			0, G_MAXUINT32, 0,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:user-flags
	 *
	 * User flags for the associated message. Can be %NULL.
	 * Unlike user-tags, which can contain various values, the user-flags
	 * can only be set or not.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_USER_FLAGS,
		g_param_spec_boxed (
			"user-flags",
			"User Flags",
			NULL,
			CAMEL_TYPE_NAMED_FLAGS,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:user-tags
	 *
	 * User tags for the associated message. Can be %NULL.
	 * Unlike user-flags, which can be set or not, the user-tags
	 * can contain various values.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_USER_TAGS,
		g_param_spec_boxed (
			"user-tags",
			"User tags",
			NULL,
			CAMEL_TYPE_NAME_VALUE_ARRAY,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:subject
	 *
	 * Subject of the associated message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_SUBJECT,
		g_param_spec_string (
			"subject",
			"Subject",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:from
	 *
	 * From address of the associated message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_FROM,
		g_param_spec_string (
			"from",
			"From",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:to
	 *
	 * To address of the associated message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_TO,
		g_param_spec_string (
			"to",
			"To",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:cc
	 *
	 * CC address of the associated message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_CC,
		g_param_spec_string (
			"cc",
			"CC",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:mlist
	 *
	 * Mailing list address of the associated message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_MLIST,
		g_param_spec_string (
			"mlist",
			"mlist",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:size
	 *
	 * Size of the associated message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_SIZE,
		g_param_spec_uint (
			"size",
			"Size",
			NULL,
			0, G_MAXUINT32, 0,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:date-sent
	 *
	 * Sent Date of the associated message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_DATE_SENT,
		g_param_spec_int64 (
			"date-sent",
			"Date Sent",
			NULL,
			G_MININT64, G_MAXINT64, 0,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:date-received
	 *
	 * Received date of the associated message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_DATE_RECEIVED,
		g_param_spec_int64 (
			"date-received",
			"Date Received",
			NULL,
			G_MININT64, G_MAXINT64, 0,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:message-id
	 *
	 * Encoded Message-ID of the associated message as a guint64 number,
	 * partial MD5 sum. The value can be cast to #CamelSummaryMessageID.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_MESSAGE_ID,
		g_param_spec_uint64 (
			"message-id",
			"Message ID",
			NULL,
			0, G_MAXUINT64, 0,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:references
	 *
	 * Encoded In-Reply-To and References headers of the associated message
	 * as an array of guint64 numbers, partial MD5 sums. Each value can be
	 * cast to #CamelSummaryMessageID.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_REFERENCES,
		g_param_spec_boxed (
			"references",
			"References",
			NULL,
			G_TYPE_ARRAY,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));

	/**
	 * CamelMessageInfo:headers
	 *
	 * Headers of the associated message. Can be %NULL.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_HEADERS,
		g_param_spec_boxed (
			"headers",
			"Headers",
			NULL,
			CAMEL_TYPE_NAME_VALUE_ARRAY,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));
}

static void
camel_message_info_init (CamelMessageInfo *mi)
{
	mi->priv = G_TYPE_INSTANCE_GET_PRIVATE (mi, CAMEL_TYPE_MESSAGE_INFO, CamelMessageInfoPrivate);
	mi->priv->summary_wrg = camel_weak_ref_group_new ();

	g_rec_mutex_init (&mi->priv->property_lock);
}

/* Private function */
void _camel_message_info_unset_summary (CamelMessageInfo *mi);

void
_camel_message_info_unset_summary (CamelMessageInfo *mi)
{
	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (mi));

	camel_weak_ref_group_set (mi->priv->summary_wrg, NULL);
}

/**
 * camel_message_info_new:
 * @summary: (nullable) (type CamelFolderSummary): parent #CamelFolderSummary object, or %NULL
 *
 * Create a new #CamelMessageInfo object, optionally for given @summary.
 *
 * Returns: (transfer full): a new #CamelMessageInfo object
 *
 * Since: 3.24
 **/
CamelMessageInfo *
camel_message_info_new (CamelFolderSummary *summary)
{
	GType type = CAMEL_TYPE_MESSAGE_INFO_BASE;

	if (summary) {
		CamelFolderSummaryClass *klass;

		g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (summary), NULL);

		klass = CAMEL_FOLDER_SUMMARY_GET_CLASS (summary);
		g_return_val_if_fail (klass != NULL, NULL);

		type = klass->message_info_type;
	}

	return g_object_new (type, "summary", summary, NULL);
}

/**
 * camel_message_info_clone:
 * @mi: a #CamelMessageInfo to clone
 * @assign_summary: (nullable) (type CamelFolderSummary): parent #CamelFolderSummary object, or %NULL, to set on the clone
 *
 * Clones the @mi as a new #CamelMessageInfo and eventually assigns
 * a new #CamelFolderSummary to it. If it's not set, then the same
 * summary as the one with @mi is used.
 *
 * Returns: (transfer full): a new #CamelMessageInfo object, clone of the @mi
 *
 * Since: 3.24
 **/
CamelMessageInfo *
camel_message_info_clone (const CamelMessageInfo *mi,
			  CamelFolderSummary *assign_summary)
{
	CamelMessageInfoClass *klass;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);
	if (assign_summary)
		g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (assign_summary), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->clone != NULL, NULL);

	return klass->clone (mi, assign_summary);
}

/**
 * camel_message_info_load:
 * @mi: a #CamelMessageInfo to load
 * @record: (type CamelMIRecord): a #CamelMIRecord to load the @mi from
 * @bdata_ptr: a backend specific data (bdata) pointer
 *
 * Load content of @mi from the data stored in @record. The @bdata_ptr points
 * to the current position of the record->bdata, where the read can continue.
 * Use helper functions camel_util_bdata_get_number() and camel_util_bdata_get_string()
 * to read data from it and also move forward the *bdata_ptr.
 *
 * After successful load of the @mi, the 'dirty' flag is unset.
 *
 * Returns: Whether the load was successful.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_load (CamelMessageInfo *mi,
			 const CamelMIRecord *record,
			 /* const */ gchar **bdata_ptr)
{
	CamelMessageInfoClass *klass;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (record != NULL, FALSE);
	g_return_val_if_fail (bdata_ptr != NULL, FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->load != NULL, FALSE);

	g_object_freeze_notify (G_OBJECT (mi));
	camel_message_info_property_lock (mi);
	camel_message_info_set_abort_notifications (mi, TRUE);

	success = klass->load (mi, record, bdata_ptr);

	if (success)
		camel_message_info_set_dirty (mi, FALSE);

	camel_message_info_set_abort_notifications (mi, FALSE);
	camel_message_info_property_unlock (mi);
	g_object_thaw_notify (G_OBJECT (mi));

	return success;
}

/**
 * camel_message_info_save:
 * @mi: a #CamelMessageInfo
 * @record: (type CamelMIRecord): a #CamelMIRecord to populate
 * @bdata_str: a #GString with a string to save as backend specific data (bdata)
 *
 * Save the @mi content to the message info record @record. It can populate all
 * but the record->bdata value, which is set fro mthe @bdata_str. Use helper functions
 * camel_util_bdata_put_number() and camel_util_bdata_put_string() to put data into the @bdata_str.
 *
 * Returns: Whether the save succeeded.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_save (const CamelMessageInfo *mi,
			 CamelMIRecord *record,
			 GString *bdata_str)
{
	CamelMessageInfoClass *klass;
	gboolean success;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (record != NULL, FALSE);
	g_return_val_if_fail (bdata_str != NULL, FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->save != NULL, FALSE);

	camel_message_info_property_lock (mi);

	success = klass->save (mi, record, bdata_str);

	camel_message_info_property_unlock (mi);

	return success;
}

/**
 * camel_message_info_ref_summary:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer full): Referenced #CamelFolderSummary to which the @mi belongs, or %NULL,
 * if there is none. Use g_object_unref() for non-NULL returned values when done with it.
 *
 * Since: 3.24
 **/
CamelFolderSummary *
camel_message_info_ref_summary (const CamelMessageInfo *mi)
{
	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	return camel_weak_ref_group_get (mi->priv->summary_wrg);
}

/**
 * camel_message_info_property_lock:
 * @mi: a #CamelMessageInfo
 *
 * Acquires a property lock, which is used to ensure thread safety
 * when properties are changing. Release the lock with
 * camel_message_info_property_unlock().
 *
 * Note: Make sure the CamelFolderSummary lock is held before this lock,
 * if there will be called any 'set' function on the @mi, to avoid deadlock
 * when the summary would be set as dirty while another thread might try
 * to read values from the @mi, waiting for the property lock and holding
 * the summary lock at the same time.
 *
 * Since: 3.24
 **/
void
camel_message_info_property_lock (const CamelMessageInfo *mi)
{
	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (mi));

	g_rec_mutex_lock (&mi->priv->property_lock);
}

/**
 * camel_message_info_property_unlock:
 * @mi: a #CamelMessageInfo
 *
 * Releases a property lock, previously acquired with
 * camel_message_info_property_lock().
 *
 * Since: 3.24
 **/
void
camel_message_info_property_unlock (const CamelMessageInfo *mi)
{
	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (mi));

	g_rec_mutex_unlock (&mi->priv->property_lock);
}

static void
camel_message_info_update_summary_and_folder (CamelMessageInfo *mi,
					      gboolean update_counts)
{
	CamelFolderSummary *summary;

	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (mi));

	camel_message_info_property_lock (mi);
	if (camel_message_info_get_notifications_frozen (mi)) {
		mi->priv->thaw_notify_folder = TRUE;
		mi->priv->thaw_notify_folder_with_counts |= update_counts;
		camel_message_info_property_unlock (mi);

		return;
	}
	camel_message_info_property_unlock (mi);

	summary = camel_message_info_ref_summary (mi);
	if (summary) {
		CamelFolder *folder;
		CamelMessageInfo *in_summary_mi = NULL;
		const gchar *uid;

		uid = camel_message_info_pooldup_uid (mi);

		/* This is for cases when a new message info had been created,
		   but not added into the summary yet. */
		if (uid && camel_folder_summary_check_uid (summary, uid) &&
		    (in_summary_mi = camel_folder_summary_peek_loaded (summary, uid)) == mi) {
			if (update_counts) {
				camel_folder_summary_lock (summary);
				g_object_freeze_notify (G_OBJECT (summary));

				camel_folder_summary_replace_flags (summary, mi);

				g_object_thaw_notify (G_OBJECT (summary));
				camel_folder_summary_unlock (summary);
			}

			folder = camel_folder_summary_get_folder (summary);
			if (folder) {
				CamelFolderChangeInfo *changes = camel_folder_change_info_new ();

				camel_folder_change_info_change_uid (changes, uid);
				camel_folder_changed (folder, changes);
				camel_folder_change_info_free (changes);
			}
		}

		g_clear_object (&in_summary_mi);
		g_clear_object (&summary);
		camel_pstring_free (uid);
	}
}

/**
 * camel_message_info_get_dirty:
 * @mi: a #CamelMessageInfo
 *
 * Returns: Whether the @mi is dirty, which means that it had been
 *   changed and a save to the local summary is required.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_get_dirty (const CamelMessageInfo *mi)
{
	gboolean result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	camel_message_info_property_lock (mi);
	result = mi->priv->dirty;
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_dirty:
 * @mi: a #CamelMessageInfo
 * @dirty: a dirty state to set
 *
 * Marks the @mi as dirty, which means a save to the local summary
 * is required.
 *
 * Since: 3.24
 **/
void
camel_message_info_set_dirty (CamelMessageInfo *mi,
			      gboolean dirty)
{
	gboolean changed, abort_notifications;

	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (mi));

	camel_message_info_property_lock (mi);

	changed = (!mi->priv->dirty) != (!dirty);
	if (changed)
		mi->priv->dirty = dirty;
	abort_notifications = mi->priv->abort_notifications;

	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "dirty");

		if (dirty) {
			CamelFolderSummary *summary;

			summary = camel_message_info_ref_summary (mi);
			if (summary)
				camel_folder_summary_touch (summary);

			g_clear_object (&summary);
		}
	}
}

/**
 * camel_message_info_get_folder_flagged:
 * @mi: a #CamelMessageInfo
 *
 * The folder flagged flag is used to mark the message infor as being changed
 * and this change should be propagated to the remote store (server). This is
 * different from the 'dirty' flag, which is set for local changes only. It
 * can happen that the 'folder-flagged' flag is set, but the 'dirty' flag not.
 *
 * This is only a convenient wrapper around CAMEL_MESSAGE_FOLDER_FLAGGED flag,
 * for better readiness of the code.
 *
 * Returns: Whether requires save of the local changes into the remote store.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_get_folder_flagged (const CamelMessageInfo *mi)
{
	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	return (camel_message_info_get_flags (mi) & CAMEL_MESSAGE_FOLDER_FLAGGED) != 0;
}

/**
 * camel_message_info_set_folder_flagged:
 * @mi: a #CamelMessageInfo
 * @folder_flagged: a value to set to
 *
 * Changes the folder-flagged flag to the @folder_flagged value. See
 * camel_message_info_get_folder_flagged() for more information about
 * the use of this flag.
 *
 * This is only a convenient wrapper around CAMEL_MESSAGE_FOLDER_FLAGGED flag,
 * for better readiness of the code.
 *
 * Returns: Whether the flag had been changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_folder_flagged (CamelMessageInfo *mi,
				       gboolean folder_flagged)
{
	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	/* g_object_notify (G_OBJECT (mi), "folder-flagged");
	   is called as part of the set_flags function */

	return camel_message_info_set_flags (mi, CAMEL_MESSAGE_FOLDER_FLAGGED,
		folder_flagged ? CAMEL_MESSAGE_FOLDER_FLAGGED : 0);
}

/**
 * camel_message_info_get_folder_flagged_stamp:
 * @mi: a #CamelMessageInfo
 *
 * The 'folder-flagged-stamp' is a stamp of the 'folder-flagged' flag. This stamp
 * changes whenever anything would mark the @mi as 'folder-flagged', regardless
 * the @mi being already 'folder-flagged'. It can be used to recognize changes
 * on the 'folder-flagged' flag during the time.
 *
 * Returns: Stamp of the 'folder-flagged' flag.
 *
 * Since: 3.24
 **/
guint
camel_message_info_get_folder_flagged_stamp (const CamelMessageInfo *mi)
{
	guint result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), ~0);

	camel_message_info_property_lock (mi);
	result = mi->priv->folder_flagged_stamp;
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_get_abort_notifications:
 * @mi: a #CamelMessageInfo
 *
 * Returns: Whether the @mi is aborting notifications, which means
 *   that it will not influence 'dirty' and 'folder-flagged' flags
 *   in the set/take functions, neither it will emit any GObject::notify
 *   signals on change, nor associated folder's "changed" signal.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_get_abort_notifications (const CamelMessageInfo *mi)
{
	gboolean result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	camel_message_info_property_lock (mi);
	result = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_abort_notifications:
 * @mi: a #CamelMessageInfo
 * @abort_notifications: a state to set
 *
 * Marks the @mi to abort any notifications, which means that it
 * will not influence 'dirty' and 'folder-flagged' flags in
 * the set/take functions, neither it will emit any GObject::notify
 * signals on change, nor associated folder's "changed" signal.
 *
 * Since: 3.24
 **/
void
camel_message_info_set_abort_notifications (CamelMessageInfo *mi,
					    gboolean abort_notifications)
{
	gboolean changed;
	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (mi));

	camel_message_info_property_lock (mi);
	changed = (!mi->priv->abort_notifications) != (!abort_notifications);
	if (changed)
		mi->priv->abort_notifications = abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed)
		g_object_notify (G_OBJECT (mi), "abort-notifications");
}

/**
 * camel_message_info_freeze_notifications:
 * @mi: a #CamelMessageInfo
 *
 * Freezes all the notifications until the camel_message_info_thaw_notifications() is called.
 * This function can be called multiple times, where the last thaw will do the notifications.
 *
 * Since: 3.24
 **/
void
camel_message_info_freeze_notifications (CamelMessageInfo *mi)
{
	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (mi));

	camel_message_info_property_lock (mi);
	mi->priv->freeze_notifications++;
	if (mi->priv->freeze_notifications == 1) {
		mi->priv->thaw_notify_folder = FALSE;
		mi->priv->thaw_notify_folder_with_counts = FALSE;
		g_object_freeze_notify (G_OBJECT (mi));
	}
	camel_message_info_property_unlock (mi);
}

/**
 * camel_message_info_thaw_notifications:
 * @mi: a #CamelMessageInfo
 *
 * Reverses the call of the camel_message_info_freeze_notifications().
 * If this is the last freeze, then the associated folder is also notified
 * about the change, if any happened during the freeze.
 *
 * Since: 3.24
 **/
void
camel_message_info_thaw_notifications (CamelMessageInfo *mi)
{
	g_return_if_fail (CAMEL_IS_MESSAGE_INFO (mi));

	camel_message_info_property_lock (mi);
	if (!mi->priv->freeze_notifications) {
		camel_message_info_property_unlock (mi);

		g_warn_if_reached ();
		return;
	}

	mi->priv->freeze_notifications--;
	if (!mi->priv->freeze_notifications) {
		gboolean notify_folder, notify_folder_with_counts;

		notify_folder = mi->priv->thaw_notify_folder;
		notify_folder_with_counts = mi->priv->thaw_notify_folder_with_counts;

		camel_message_info_property_unlock (mi);

		g_object_thaw_notify (G_OBJECT (mi));

		if (notify_folder)
			camel_message_info_update_summary_and_folder (mi, notify_folder_with_counts);
	} else {
		camel_message_info_property_unlock (mi);
	}
}

/**
 * camel_message_info_get_notifications_frozen:
 * @mi: a #CamelMessageInfo
 *
 * Returns: Whether the notifications are frozen.
 *
 * See: camel_message_info_freeze_notifications()
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_get_notifications_frozen (const CamelMessageInfo *mi)
{
	gboolean result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	camel_message_info_property_lock (mi);
	result = mi->priv->freeze_notifications > 0;
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_get_uid:
 * @mi: a #CamelMessageInfo
 *
 * Get the UID of the #mi.
 *
 * Returns: (transfer none): The UID of the @mi.
 *
 * Since: 3.24
 **/
const gchar *
camel_message_info_get_uid (const CamelMessageInfo *mi)
{
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	camel_message_info_property_lock (mi);
	result = mi->priv->uid;
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_pooldup_uid:
 * @mi: a #CamelMessageInfo
 *
 * Get the UID of the #mi, duplicated on the Camel's string pool.
 * This is good for thread safety, though the UID should not change once set.
 *
 * Returns: A newly references string in the string pool, the #mi UID.
 *   Free it with camel_pstring_free() when no longer needed.
 *
 * Since: 3.24
 **/
const gchar *
camel_message_info_pooldup_uid (const CamelMessageInfo *mi)
{
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	camel_message_info_property_lock (mi);
	result = camel_pstring_strdup (mi->priv->uid);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_uid:
 * @mi: a #CamelMessageInfo
 * @uid: a UID to set
 *
 * Changes UID of the @mi to @uid. If it changes, the 'dirty' flag
 * of the @mi is set too, unless the @mi is aborting notifications. This change
 * does not influence the 'folder-flagged' flag.
 *
 * Returns: Whether the UID changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_uid (CamelMessageInfo *mi,
			    const gchar *uid)
{
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	camel_message_info_property_lock (mi);
	changed = mi->priv->uid != uid && g_strcmp0 (mi->priv->uid, uid) != 0;
	if (changed) {
		camel_pstring_free (mi->priv->uid);
		mi->priv->uid = camel_pstring_strdup (uid);
	}
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "uid");
		camel_message_info_set_dirty (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_flags:
 * @mi: a #CamelMessageInfo
 *
 * Returns: Bit-or of #CamelMessageFlags set on the @mi.
 *
 * Since: 3.24
 **/
guint32
camel_message_info_get_flags (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	guint32 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), 0);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, 0);
	g_return_val_if_fail (klass->get_flags != NULL, 0);

	camel_message_info_property_lock (mi);
	result = klass->get_flags (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_flags:
 * @mi: a #CamelMessageInfo
 * @mask: mask of flags to change
 * @set: state the flags should be changed to
 *
 * Change the state of the flags on the @mi. Both @mask and @set are bit-or
 * of #CamelMessageFlags.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is also emitted
 * folder's "changed" signal for this @mi, if necessary. In case
 * the CAMEL_MESSAGE_FOLDER_FLAGGED flag would be set and the @mi is
 * not aborting notifications, the 'folder-flagged-stamp' changes too.
 *
 * Returns: Whether the flags changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_flags (CamelMessageInfo *mi,
			      guint32 mask,
			      guint32 set)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_flags != NULL, FALSE);

	camel_message_info_property_lock (mi);

	changed = klass->set_flags (mi, mask, set);
	abort_notifications = mi->priv->abort_notifications;

	if (!abort_notifications &&
	    (mask & CAMEL_MESSAGE_FOLDER_FLAGGED) != 0 &&
	    (set & CAMEL_MESSAGE_FOLDER_FLAGGED) != 0)
		mi->priv->folder_flagged_stamp++;

	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "flags");
		camel_message_info_set_dirty (mi, TRUE);

		/* Only if the folder-flagged was not part of the change */
		if (!(mask & CAMEL_MESSAGE_FOLDER_FLAGGED))
			camel_message_info_set_folder_flagged (mi, TRUE);
		else
			g_object_notify (G_OBJECT (mi), "folder-flagged");

		camel_message_info_update_summary_and_folder (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_user_flag:
 * @mi: a #CamelMessageInfo
 * @name: user flag name
 *
 * Returns: Whther the user flag named @name is set.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_get_user_flag (const CamelMessageInfo *mi,
				  const gchar *name)
{
	CamelMessageInfoClass *klass;
	gboolean result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->get_user_flag != NULL, FALSE);

	camel_message_info_property_lock (mi);
	result = klass->get_user_flag (mi, name);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_user_flag:
 * @mi: a #CamelMessageInfo
 * @name: user flag name
 * @state: state to set for the flag
 *
 * Change @state of the flag named @name. Unlike user tags, user flags
 * can only be set or unset, while the user tags can contain certain values.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is also emitted
 * folder's "changed" signal for this @mi, if necessary.
 *
 * Returns: Whether the message info changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_user_flag (CamelMessageInfo *mi,
				  const gchar *name,
				  gboolean state)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_user_flag != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_user_flag (mi, name, state);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "user-flags");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);

		camel_message_info_update_summary_and_folder (mi, FALSE);
	}

	return changed;
}

/**
 * camel_message_info_get_user_flags:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer none) (nullable): A #CamelNamedFlags with all the currently set
 *   user flags on the @mi. Do not modify it.
 *
 * Since: 3.24
 **/
const CamelNamedFlags *
camel_message_info_get_user_flags (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const CamelNamedFlags *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_user_flags != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_user_flags (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_dup_user_flags:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer full): A newly allocated #CamelNamedFlags with all the currently set
 *   user flags on the @mi. Free the returned structure with camel_named_flags_free()
 *   when no londer needed.
 *
 * Since: 3.24
 **/
CamelNamedFlags *
camel_message_info_dup_user_flags (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	CamelNamedFlags *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->dup_user_flags != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->dup_user_flags (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_take_user_flags:
 * @mi: a #CamelMessageInfo
 * @user_flags: (transfer full) (nullable): user flags to set
 *
 * Takes all the @user_flags, which replaces any current user flags on the @mi.
 * The passed-in @user_flags is consumed by the @mi, which becomes an owner
 * of it. The caller should not change @user_flags afterwards.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is also emitted
 * folder's "changed" signal for this @mi, if necessary.
 *
 * Note that it's not safe to use the @user_flags after the call to this function,
 * because it can be freed due to no change.
 *
 * Returns: Whether the message info changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_take_user_flags (CamelMessageInfo *mi,
				    CamelNamedFlags *user_flags)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->take_user_flags != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->take_user_flags (mi, user_flags);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "user-flags");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);

		camel_message_info_update_summary_and_folder (mi, FALSE);
	}

	return changed;
}

/**
 * camel_message_info_get_user_tag:
 * @mi: a #CamelMessageInfo
 * @name: user tag name
 *
 * Returns: (transfer none) (nullable): Value of the user tag, or %NULL when
 *   it is not set.
 *
 * Since: 3.24
 **/
const gchar *
camel_message_info_get_user_tag (const CamelMessageInfo *mi,
				 const gchar *name)
{
	CamelMessageInfoClass *klass;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);
	g_return_val_if_fail (name != NULL, NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_user_tag != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_user_tag (mi, name);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_dup_user_tag:
 * @mi: a #CamelMessageInfo
 * @name: user tag name
 *
 * Returns: (transfer full) (nullable): Value of the user tag as newly allocated
 *   string, or %NULL when it is not set. Free it with g_free() when no longer needed.
 *
 * Since: 3.24
 **/
gchar *
camel_message_info_dup_user_tag (const CamelMessageInfo *mi,
				 const gchar *name)
{
	gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);
	g_return_val_if_fail (name != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = g_strdup (camel_message_info_get_user_tag (mi, name));
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_user_tag:
 * @mi: a #CamelMessageInfo
 * @name: user tag name
 * @value: (nullable): user tag value, or %NULL to remove the user tag
 *
 * Set user tag @name to @value, or remove it, if @value is %NULL.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is also emitted
 * folder's "changed" signal for this @mi, if necessary.
 *
 * Returns: Whether the @mi changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_user_tag (CamelMessageInfo *mi,
				 const gchar *name,
				 const gchar *value)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_user_tag != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_user_tag (mi, name, value);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "user-tags");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);

		camel_message_info_update_summary_and_folder (mi, FALSE);
	}

	return changed;
}

/**
 * camel_message_info_get_user_tags:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer none) (nullable): a #CamelNameValueArray containing all set
 *   user tags of the @mi. Do not modify it.
 *
 * Since: 3.24
 **/
const CamelNameValueArray *
camel_message_info_get_user_tags (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const CamelNameValueArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_user_tags != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_user_tags (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_dup_user_tags:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer full) (nullable): a newly allocated #CamelNameValueArray containing all set
 *   user tags of the @mi. Free it with camel_name_value_array_free() when no longer needed.
 *
 * Since: 3.24
 **/
CamelNameValueArray *
camel_message_info_dup_user_tags (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	CamelNameValueArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->dup_user_tags != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->dup_user_tags (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_take_user_tags:
 * @mi: a #CamelMessageInfo
 * @user_tags: (transfer full) (nullable): user tags to set
 *
 * Takes all the @user_tags, which replaces any current user tags on the @mi.
 * The passed-in @user_tags is consumed by the @mi, which becomes an owner
 * of it. The caller should not change @user_tags afterwards.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is also emitted
 * folder's "changed" signal for this @mi, if necessary.
 *
 * Note that it's not safe to use the @user_tags after the call to this function,
 * because it can be freed due to no change.
 *
 * Returns: Whether the @mi changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_take_user_tags (CamelMessageInfo *mi,
				   CamelNameValueArray *user_tags)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->take_user_tags != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->take_user_tags (mi, user_tags);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "user-tags");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);

		camel_message_info_update_summary_and_folder (mi, FALSE);
	}

	return changed;
}

/**
 * camel_message_info_get_subject:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer none): Subject of the #mi.
 *
 * Since: 3.24
 **/
const gchar *
camel_message_info_get_subject (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_subject != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_subject (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_subject:
 * @mi: a #CamelMessageInfo
 * @subject: (nullable): a Subject to set
 *
 * Sets Subject from the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_subject (CamelMessageInfo *mi,
				const gchar *subject)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_subject != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_subject (mi, subject);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "subject");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_from:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer none): From address of the @mi.
 *
 * Since: 3.24
 **/
const gchar *
camel_message_info_get_from (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_from != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_from (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_from:
 * @mi: a #CamelMessageInfo
 * @from: (nullable): a From to set
 *
 * Sets From from the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_from (CamelMessageInfo *mi,
			     const gchar *from)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_from != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_from (mi, from);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "from");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_to:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer none): To address of the @mi.
 *
 * Since: 3.24
 **/
const gchar *
camel_message_info_get_to (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_to != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_to (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_to:
 * @mi: a #CamelMessageInfo
 * @to: (nullable): a To to set
 *
 * Sets To from the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_to (CamelMessageInfo *mi,
			   const gchar *to)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_to != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_to (mi, to);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "to");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_cc:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer none): CC address of the @mi.
 *
 * Since: 3.24
 **/
const gchar *
camel_message_info_get_cc (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_cc != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_cc (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_cc:
 * @mi: a #CamelMessageInfo
 * @cc: (nullable): a CC to set
 *
 * Sets CC from the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_cc (CamelMessageInfo *mi,
			   const gchar *cc)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_cc != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_cc (mi, cc);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "cc");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_mlist:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer none): Mailing list address of the @mi.
 *
 * Since: 3.24
 **/
const gchar *
camel_message_info_get_mlist (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_mlist != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_mlist (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_mlist:
 * @mi: a #CamelMessageInfo
 * @mlist: (nullable): a message list address to set
 *
 * Sets mesage list address from the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_mlist (CamelMessageInfo *mi,
			      const gchar *mlist)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_mlist != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_mlist (mi, mlist);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "mlist");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_size:
 * @mi: a #CamelMessageInfo
 *
 * Returns: Size of the associated message.
 *
 * Since: 3.24
 **/
guint32
camel_message_info_get_size (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	guint32 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), 0);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, 0);
	g_return_val_if_fail (klass->get_size != NULL, 0);

	camel_message_info_property_lock (mi);
	result = klass->get_size (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_size:
 * @mi: a #CamelMessageInfo
 * @size: a size to set
 *
 * Sets size of the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_size (CamelMessageInfo *mi,
			     guint32 size)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_size != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_size (mi, size);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "size");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_date_sent:
 * @mi: a #CamelMessageInfo
 *
 * Returns: time_t of the Date header of the message, encoded as gint64.
 *
 * Since: 3.24
 **/
gint64
camel_message_info_get_date_sent (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	gint64 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), 0);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, 0);
	g_return_val_if_fail (klass->get_date_sent != NULL, 0);

	camel_message_info_property_lock (mi);
	result = klass->get_date_sent (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_date_sent:
 * @mi: a #CamelMessageInfo
 * @date_sent: a sent date to set
 *
 * Sets sent date (the Date header) of the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_date_sent (CamelMessageInfo *mi,
				  gint64 date_sent)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_date_sent != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_date_sent (mi, date_sent);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "date-sent");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_date_received:
 * @mi: a #CamelMessageInfo
 *
 * Returns: time_t of the Received header of the message, encoded as gint64.
 *
 * Since: 3.24
 **/
gint64
camel_message_info_get_date_received (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	gint64 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), 0);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, 0);
	g_return_val_if_fail (klass->get_date_received != NULL, 0);

	camel_message_info_property_lock (mi);
	result = klass->get_date_received (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_date_received:
 * @mi: a #CamelMessageInfo
 * @date_received: a received date to set
 *
 * Sets received date (the Received header) of the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_date_received (CamelMessageInfo *mi,
				      gint64 date_received)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_date_received != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_date_received (mi, date_received);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "date-received");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_message_id:
 * @mi: a #CamelMessageInfo
 *
 * Encoded Message-ID of the associated message as a guint64 number,
 * partial MD5 sum. The value can be cast to #CamelSummaryMessageID.
 *
 * Returns: Partial MD5 hash of the Message-ID header of the associated message.
 *
 * Since: 3.24
 **/
guint64
camel_message_info_get_message_id (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	guint64 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), 0);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, 0);
	g_return_val_if_fail (klass->get_message_id != NULL, 0);

	camel_message_info_property_lock (mi);
	result = klass->get_message_id (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_set_message_id:
 * @mi: a #CamelMessageInfo
 * @message_id: a message id to set
 *
 * Sets encoded Message-ID of the associated message as a guint64 number,
 * partial MD5 sum. The value can be cast to #CamelSummaryMessageID.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_set_message_id (CamelMessageInfo *mi,
				   guint64 message_id)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->set_message_id != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->set_message_id (mi, message_id);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "message-id");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_references:
 * @mi: a #CamelMessageInfo
 *
 * Gets encoded In-Reply-To and References headers of the associated
 * message as an array of guint64 numbers, partial MD5 sums. Each value
 * can be cast to #CamelSummaryMessageID.
 *
 * Returns: (transfer none) (nullable) (element-type guint64): A #GArray of
 *   guint64 encoded Message-ID-s; or %NULL when none are available.
 *
 * Since: 3.24
 **/
const GArray *
camel_message_info_get_references (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const GArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_references != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_references (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_dup_references:
 * @mi: a #CamelMessageInfo
 *
 * Duplicates encoded In-Reply-To and References headers of the associated
 * message as an array of guint64 numbers, partial MD5 sums. Each value
 * can be cast to #CamelSummaryMessageID.
 *
 * Returns: (transfer full) (nullable) (element-type guint64): A #GArray of
 *   guint64 encoded Message-ID-s; or %NULL when none are available. Free returned
 *   array with g_array_unref() when no longer needed.
 *
 * Since: 3.24
 **/
GArray *
camel_message_info_dup_references (const CamelMessageInfo *mi)
{
	const GArray *arr;
	GArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	camel_message_info_property_lock (mi);
	arr = camel_message_info_get_references (mi);
	if (arr) {
		guint ii;

		result = g_array_sized_new (FALSE, FALSE, sizeof (guint64), arr->len);
		for (ii = 0; ii < arr->len; ii++) {
			g_array_append_val (result, g_array_index (arr, guint64, ii));
		}
	} else {
		result = NULL;
	}
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_take_references:
 * @mi: a #CamelMessageInfo
 * @references: (element-type guint64) (transfer full) (nullable): a references to set
 *
 * Takes encoded In-Reply-To and References headers of the associated message
 * as an array of guint64 numbers, partial MD5 sums. Each value can be
 * cast to #CamelSummaryMessageID.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Note that it's not safe to use the @references after the call to this function,
 * because it can be freed due to no change.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_take_references (CamelMessageInfo *mi,
				    GArray *references)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->take_references != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->take_references (mi, references);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "references");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_get_headers:
 * @mi: a #CamelMessageInfo
 *
 * Returns: (transfer none) (nullable): All the message headers of the associated
 *   message, or %NULL, when none are available.
 *
 * Since: 3.24
 **/
const CamelNameValueArray *
camel_message_info_get_headers (const CamelMessageInfo *mi)
{
	CamelMessageInfoClass *klass;
	const CamelNameValueArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, NULL);
	g_return_val_if_fail (klass->get_headers != NULL, NULL);

	camel_message_info_property_lock (mi);
	result = klass->get_headers (mi);
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_dup_headers:
 * @mi: a #CamelMessageInfo
 *
 * Duplicates array of headers for the @mi.
 *
 * Returns: (transfer full) (nullable): All the message headers of the associated
 *   message, or %NULL, when none are available. Free returned array with
 *   camel_name_value_array_free() when no longer needed.
 *
 * Since: 3.24
 **/
CamelNameValueArray *
camel_message_info_dup_headers (const CamelMessageInfo *mi)
{
	const CamelNameValueArray *arr;
	CamelNameValueArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), NULL);

	camel_message_info_property_lock (mi);
	arr = camel_message_info_get_headers (mi);
	if (arr) {
		result = camel_name_value_array_copy (arr);
	} else {
		result = NULL;
	}
	camel_message_info_property_unlock (mi);

	return result;
}

/**
 * camel_message_info_take_headers:
 * @mi: a #CamelMessageInfo
 * @headers: (transfer full) (nullable): headers to set, as #CamelNameValueArray, or %NULL
 *
 * Takes headers of the associated message.
 *
 * This property is considered static, in a meaning that it should
 * not change during the life-time of the @mi, the same as it doesn't
 * change in the associated message.
 *
 * If the @mi changed, the 'dirty' flag and the 'folder-flagged' flag are
 * set automatically, unless the @mi is aborting notifications. There is not emitted
 * folder's "changed" signal for this @mi.
 *
 * Note that it's not safe to use the @headers after the call to this function,
 * because it can be freed due to no change.
 *
 * Returns: Whether the value changed.
 *
 * Since: 3.24
 **/
gboolean
camel_message_info_take_headers (CamelMessageInfo *mi,
				 CamelNameValueArray *headers)
{
	CamelMessageInfoClass *klass;
	gboolean changed, abort_notifications;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO (mi), FALSE);

	klass = CAMEL_MESSAGE_INFO_GET_CLASS (mi);
	g_return_val_if_fail (klass != NULL, FALSE);
	g_return_val_if_fail (klass->take_headers != NULL, FALSE);

	camel_message_info_property_lock (mi);
	changed = klass->take_headers (mi, headers);
	abort_notifications = mi->priv->abort_notifications;
	camel_message_info_property_unlock (mi);

	if (changed && !abort_notifications) {
		g_object_notify (G_OBJECT (mi), "headers");
		camel_message_info_set_dirty (mi, TRUE);
		camel_message_info_set_folder_flagged (mi, TRUE);
	}

	return changed;
}

/**
 * camel_message_info_dump:
 * @mi: a #CamelMessageInfo
 *
 * Dumps the mesasge info @mi to stdout. This is meand for debugging
 * purposes only.
 *
 * Since: 3.24
 **/
void
camel_message_info_dump (CamelMessageInfo *mi)
{
	if (!mi) {
		printf ("No message info\n");
		return;
	}

	camel_message_info_property_lock (mi);

	printf ("Message info %s:\n", G_OBJECT_TYPE_NAME (mi));
	printf ("   UID: %s\n", camel_message_info_get_uid (mi));
	printf ("   Flags: %04x\n", camel_message_info_get_flags (mi));
	printf ("   From: %s\n", camel_message_info_get_from (mi));
	printf ("   To: %s\n", camel_message_info_get_to (mi));
	printf ("   Cc: %s\n", camel_message_info_get_cc (mi));
	printf ("   Mailing list: %s\n", camel_message_info_get_mlist (mi));
	printf ("   Subject: %s\n", camel_message_info_get_subject (mi));

	camel_message_info_property_unlock (mi);
}
