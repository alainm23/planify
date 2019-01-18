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

#include "camel-folder.h"
#include "camel-folder-summary.h"
#include "camel-message-info.h"
#include "camel-string-utils.h"
#include "camel-vee-folder.h"
#include "camel-vee-summary.h"
#include "camel-vtrash-folder.h"

#include "camel-vee-message-info.h"

struct _CamelVeeMessageInfoPrivate {
	CamelFolderSummary *orig_summary;
};

G_DEFINE_TYPE (CamelVeeMessageInfo, camel_vee_message_info, CAMEL_TYPE_MESSAGE_INFO)

static CamelMessageInfo *
vee_message_info_clone (const CamelMessageInfo *mi,
			CamelFolderSummary *assign_summary)
{
	CamelMessageInfo *result;

	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO (mi), NULL);

	result = CAMEL_MESSAGE_INFO_CLASS (camel_vee_message_info_parent_class)->clone (mi, assign_summary);
	if (!result)
		return NULL;

	if (CAMEL_IS_VEE_MESSAGE_INFO (result)) {
		CamelVeeMessageInfo *vmi, *vmi_result;

		vmi = CAMEL_VEE_MESSAGE_INFO (mi);
		vmi_result = CAMEL_VEE_MESSAGE_INFO (result);

		if (vmi->priv->orig_summary)
			vmi_result->priv->orig_summary = g_object_ref (vmi->priv->orig_summary);
	}

	return result;
}

static void
vee_message_info_notify_mi_changed (CamelFolder *folder,
				    const gchar *mi_uid)
{
	CamelFolderChangeInfo *changes;

	g_return_if_fail (CAMEL_IS_VEE_FOLDER (folder));
	g_return_if_fail (mi_uid != NULL);

	changes = camel_folder_change_info_new ();
	camel_folder_change_info_change_uid (changes, mi_uid);
	camel_folder_changed (folder, changes);
	camel_folder_change_info_free (changes);
}

#define vee_call_from_parent_mi(_err_ret, _ret_type, _call_what, _call_args, _is_set) G_STMT_START {	\
		CamelVeeMessageInfo *vmi;							\
		CamelMessageInfo *orig_mi;							\
		CamelFolderSummary *this_summary, *sub_summary;					\
		CamelFolder *this_folder, *sub_folder;						\
		gboolean ignore_changes;							\
		const gchar *uid;								\
		_ret_type result;								\
												\
		g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO (mi), _err_ret);		\
												\
		vmi = CAMEL_VEE_MESSAGE_INFO (mi);						\
		if (!vmi->priv->orig_summary)							\
			return (_err_ret);							\
												\
		uid = camel_message_info_pooldup_uid (mi);					\
		g_return_val_if_fail (uid != NULL, _err_ret);					\
												\
		if (!uid[0] || !uid[1] || !uid[2] || !uid[3] || !uid[4] ||			\
		    !uid[5] || !uid[6] || !uid[7] || !uid[8]) {					\
			camel_pstring_free (uid);						\
			g_warn_if_reached ();							\
			return _err_ret;							\
		}										\
												\
		orig_mi = (CamelMessageInfo *) camel_folder_summary_get (vmi->priv->orig_summary, uid + 8);		\
		if (!orig_mi) {									\
			/* It can be NULL when it had been removed from the orig folder */	\
			camel_pstring_free (uid);						\
			return _err_ret;							\
		}										\
												\
		this_summary = camel_message_info_ref_summary (mi);				\
		this_folder = this_summary ? camel_folder_summary_get_folder (this_summary) : NULL; \
		sub_summary = camel_message_info_ref_summary (orig_mi);				\
		sub_folder = sub_summary ? camel_folder_summary_get_folder (sub_summary) : NULL; \
												\
		ignore_changes = _is_set && !CAMEL_IS_VTRASH_FOLDER (this_folder);		\
												\
		/* ignore changes done in the folder itself,					\
		 * unless it's a vTrash or vJunk folder */					\
		if (ignore_changes)								\
			camel_vee_folder_ignore_next_changed_event (CAMEL_VEE_FOLDER (this_folder), sub_folder); \
												\
		result = _call_what _call_args;							\
												\
		if (ignore_changes) {								\
			if (result)								\
				vee_message_info_notify_mi_changed (this_folder, uid);		\
			else									\
				camel_vee_folder_remove_from_ignore_changed_event (		\
					CAMEL_VEE_FOLDER (this_folder), sub_folder);		\
		}										\
												\
		g_clear_object (&this_summary);							\
		g_clear_object (&sub_summary);							\
		g_clear_object (&orig_mi);							\
		camel_pstring_free (uid);							\
												\
		return result;									\
	} G_STMT_END

static gboolean
vee_message_info_read_flags_from_orig_summary (const CamelMessageInfo *mi,
					       guint32 *out_flags)
{
	CamelVeeMessageInfo *vmi;
	const gchar *uid;

	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (out_flags != NULL, FALSE);

	vmi = CAMEL_VEE_MESSAGE_INFO (mi);
	if (!vmi->priv->orig_summary)
		return FALSE;

	uid = camel_message_info_pooldup_uid (mi);
	g_return_val_if_fail (uid != NULL, FALSE);

	if (!uid[0] || !uid[1] || !uid[2] || !uid[3] || !uid[4] ||
	    !uid[5] || !uid[6] || !uid[7] || !uid[8]) {
		camel_pstring_free (uid);
		g_warn_if_reached ();
		return FALSE;
	}

	/* Flags can be read from summary, without a need to load the message info and
	   it is also required when adding to the summary, thus this should help when
	   populating summary of any vFolder. */
	*out_flags = camel_folder_summary_get_info_flags (vmi->priv->orig_summary, uid + 8);

	camel_pstring_free (uid);

	return *out_flags != (~0);
}

static guint32
vee_message_info_get_flags (const CamelMessageInfo *mi)
{
	guint32 flags = 0;

	if (vee_message_info_read_flags_from_orig_summary (mi, &flags)) {
		return flags;
	} else {
		vee_call_from_parent_mi (0, guint32, camel_message_info_get_flags, (orig_mi), FALSE);
	}
}

static gboolean
vee_message_info_set_flags_real (CamelMessageInfo *mi,
				 guint32 mask,
				 guint32 set)
{
	/* Do not propagate the only folder-flagged flag change to the original
	   message info, because this flag is managed by the original summary/folder,
	   rather than the virtual folder. The base summary also uses it to mark
	   new message infos as flagged, which is odd for virtual folders. */
	if (mask == CAMEL_MESSAGE_FOLDER_FLAGGED)
		return FALSE;

	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_flags, (orig_mi, mask, set), TRUE);
}

static gboolean
vee_message_info_set_flags (CamelMessageInfo *mi,
			    guint32 mask,
			    guint32 set)
{
	gboolean result;

	result = vee_message_info_set_flags_real (mi, mask, set);

	if (result) {
		CamelFolderSummary *summary;

		summary = camel_message_info_ref_summary (mi);
		if (summary)
			camel_folder_summary_replace_flags (summary, mi);
		g_clear_object (&summary);
	}

	return result;
}

static gboolean
vee_message_info_get_user_flag (const CamelMessageInfo *mi,
				const gchar *name)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_get_user_flag, (orig_mi, name), FALSE);
}

static gboolean
vee_message_info_set_user_flag (CamelMessageInfo *mi,
				const gchar *name,
				gboolean state)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_user_flag, (orig_mi, name, state), TRUE);
}

static const CamelNamedFlags *
vee_message_info_get_user_flags (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const CamelNamedFlags *, camel_message_info_get_user_flags, (orig_mi), FALSE);
}

static CamelNamedFlags *
vee_message_info_dup_user_flags (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, CamelNamedFlags *, camel_message_info_dup_user_flags, (orig_mi), FALSE);
}

static gboolean
vee_message_info_take_user_flags (CamelMessageInfo *mi,
				  CamelNamedFlags *user_flags)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_take_user_flags, (orig_mi, user_flags), TRUE);
}

static const gchar *
vee_message_info_get_user_tag (const CamelMessageInfo *mi,
			       const gchar *name)
{
	vee_call_from_parent_mi (NULL, const gchar *, camel_message_info_get_user_tag, (orig_mi, name), FALSE);
}

static gboolean
vee_message_info_set_user_tag (CamelMessageInfo *mi,
			       const gchar *name,
			       const gchar *value)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_user_tag, (orig_mi, name, value), TRUE);
}

static CamelNameValueArray *
vee_message_info_dup_user_tags (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, CamelNameValueArray *, camel_message_info_dup_user_tags, (orig_mi), FALSE);
}

static const CamelNameValueArray *
vee_message_info_get_user_tags (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const CamelNameValueArray *, camel_message_info_get_user_tags, (orig_mi), FALSE);
}

static gboolean
vee_message_info_take_user_tags (CamelMessageInfo *mi,
				 CamelNameValueArray *user_tags)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_take_user_tags, (orig_mi, user_tags), TRUE);
}

static const gchar *
vee_message_info_get_subject (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const gchar *, camel_message_info_get_subject, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_subject (CamelMessageInfo *mi,
			      const gchar *subject)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_subject, (orig_mi, subject), TRUE);
}

static const gchar *
vee_message_info_get_from (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const gchar *, camel_message_info_get_from, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_from (CamelMessageInfo *mi,
			   const gchar *from)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_from, (orig_mi, from), TRUE);
}

static const gchar *
vee_message_info_get_to (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const gchar *, camel_message_info_get_to, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_to (CamelMessageInfo *mi,
			 const gchar *to)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_to, (orig_mi, to), TRUE);
}

static const gchar *
vee_message_info_get_cc (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const gchar *, camel_message_info_get_cc, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_cc (CamelMessageInfo *mi,
			 const gchar *cc)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_cc, (orig_mi, cc), TRUE);
}

static const gchar *
vee_message_info_get_mlist (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const gchar *, camel_message_info_get_mlist, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_mlist (CamelMessageInfo *mi,
			    const gchar *mlist)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_mlist, (orig_mi, mlist), TRUE);
}

static guint32
vee_message_info_get_size (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (0, guint32, camel_message_info_get_size, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_size (CamelMessageInfo *mi,
			   guint32 size)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_size, (orig_mi, size), TRUE);
}

static gint64
vee_message_info_get_date_sent (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (0, gint64, camel_message_info_get_date_sent, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_date_sent (CamelMessageInfo *mi,
				gint64 date_sent)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_date_sent, (orig_mi, date_sent), TRUE);
}

static gint64
vee_message_info_get_date_received (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (0, gint64, camel_message_info_get_date_received, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_date_received (CamelMessageInfo *mi,
				    gint64 date_received)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_date_received, (orig_mi, date_received), TRUE);
}

static guint64
vee_message_info_get_message_id (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (0, guint64, camel_message_info_get_message_id, (orig_mi), FALSE);
}

static gboolean
vee_message_info_set_message_id (CamelMessageInfo *mi,
				 guint64 message_id)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_set_message_id, (orig_mi, message_id), TRUE);
}

static const GArray *
vee_message_info_get_references (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const GArray *, camel_message_info_get_references, (orig_mi), FALSE);
}

static gboolean
vee_message_info_take_references (CamelMessageInfo *mi,
				  GArray *references)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_take_references, (orig_mi, references), TRUE);
}

static const CamelNameValueArray *
vee_message_info_get_headers (const CamelMessageInfo *mi)
{
	vee_call_from_parent_mi (NULL, const CamelNameValueArray *, camel_message_info_get_headers, (orig_mi), FALSE);
}

static gboolean
vee_message_info_take_headers (CamelMessageInfo *mi,
			       CamelNameValueArray *headers)
{
	vee_call_from_parent_mi (FALSE, gboolean, camel_message_info_take_headers, (orig_mi, headers), TRUE);
}

#undef vee_call_from_parent_mi

static void
vee_message_info_dispose (GObject *object)
{
	CamelVeeMessageInfo *vmi = CAMEL_VEE_MESSAGE_INFO (object);

	g_clear_object (&vmi->priv->orig_summary);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_vee_message_info_parent_class)->dispose (object);
}

static void
camel_vee_message_info_class_init (CamelVeeMessageInfoClass *class)
{
	CamelMessageInfoClass *mi_class;
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelVeeMessageInfoPrivate));

	mi_class = CAMEL_MESSAGE_INFO_CLASS (class);
	mi_class->clone = vee_message_info_clone;
	mi_class->get_flags = vee_message_info_get_flags;
	mi_class->set_flags = vee_message_info_set_flags;
	mi_class->get_user_flag = vee_message_info_get_user_flag;
	mi_class->set_user_flag = vee_message_info_set_user_flag;
	mi_class->get_user_flags = vee_message_info_get_user_flags;
	mi_class->dup_user_flags = vee_message_info_dup_user_flags;
	mi_class->take_user_flags = vee_message_info_take_user_flags;
	mi_class->get_user_tag = vee_message_info_get_user_tag;
	mi_class->set_user_tag = vee_message_info_set_user_tag;
	mi_class->get_user_tags = vee_message_info_get_user_tags;
	mi_class->dup_user_tags = vee_message_info_dup_user_tags;
	mi_class->take_user_tags = vee_message_info_take_user_tags;
	mi_class->get_subject = vee_message_info_get_subject;
	mi_class->set_subject = vee_message_info_set_subject;
	mi_class->get_from = vee_message_info_get_from;
	mi_class->set_from = vee_message_info_set_from;
	mi_class->get_to = vee_message_info_get_to;
	mi_class->set_to = vee_message_info_set_to;
	mi_class->get_cc = vee_message_info_get_cc;
	mi_class->set_cc = vee_message_info_set_cc;
	mi_class->get_mlist = vee_message_info_get_mlist;
	mi_class->set_mlist = vee_message_info_set_mlist;
	mi_class->get_size = vee_message_info_get_size;
	mi_class->set_size = vee_message_info_set_size;
	mi_class->get_date_sent = vee_message_info_get_date_sent;
	mi_class->set_date_sent = vee_message_info_set_date_sent;
	mi_class->get_date_received = vee_message_info_get_date_received;
	mi_class->set_date_received = vee_message_info_set_date_received;
	mi_class->get_message_id = vee_message_info_get_message_id;
	mi_class->set_message_id = vee_message_info_set_message_id;
	mi_class->get_references = vee_message_info_get_references;
	mi_class->take_references = vee_message_info_take_references;
	mi_class->get_headers = vee_message_info_get_headers;
	mi_class->take_headers = vee_message_info_take_headers;

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = vee_message_info_dispose;
}

static void
camel_vee_message_info_init (CamelVeeMessageInfo *vmi)
{
	vmi->priv = G_TYPE_INSTANCE_GET_PRIVATE (vmi, CAMEL_TYPE_VEE_MESSAGE_INFO, CamelVeeMessageInfoPrivate);
}

/**
 * camel_vee_message_info_new:
 * @summary: a #CamelVeeSummary, the "owner" of the created message info
 * @original_summary: an original #CamelFolderSummary to reference to
 * @vuid: what UID to set on the resulting message info
 *
 * Creates a new instance of #CamelVeeMessageInfo which references
 * a message from the @original_summary internally.
 *
 * The @vuid should be encoded in a way which the vFolder understands,
 * which is like the one returned by camel_vee_message_info_data_get_vee_message_uid().
 *
 * Returns: (transfer full): a newly created #CamelVeeMessageInfo
 *   which references @orig_mi. Free with g_object_unref() when done
 *   with it.
 *
 * Since: 3.24
 **/
CamelMessageInfo *
camel_vee_message_info_new (CamelFolderSummary *summary,
			    CamelFolderSummary *original_summary,
			    const gchar *vuid)
{
	CamelMessageInfo *mi;
	CamelVeeMessageInfo *vmi;

	g_return_val_if_fail (CAMEL_IS_VEE_SUMMARY (summary), NULL);
	g_return_val_if_fail (CAMEL_IS_FOLDER_SUMMARY (original_summary), NULL);
	g_return_val_if_fail (vuid != NULL, NULL);
	g_return_val_if_fail (vuid[0] && vuid[1] && vuid[2] && vuid[3] && vuid[4] && vuid[5] && vuid[6] && vuid[7] && vuid[8], NULL);

	mi = camel_message_info_new (summary);
	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO (mi), NULL);

	vmi = CAMEL_VEE_MESSAGE_INFO (mi);
	vmi->priv->orig_summary = g_object_ref (original_summary);

	camel_message_info_set_uid (mi, vuid);

	return mi;
}

/**
 * camel_vee_message_info_get_original_summary:
 * @vmi: a #CamelVeeMessageInfo
 *
 * Returns: (transfer none): A #CamelFolderSummary of the original
 *   message info, which this @vmi is proxying.
 *
 * Since: 3.24
 **/
CamelFolderSummary *
camel_vee_message_info_get_original_summary (const CamelVeeMessageInfo *vmi)
{
	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO (vmi), NULL);

	return vmi->priv->orig_summary;
}

/**
 * camel_vee_message_info_get_original_folder:
 * @vmi: a #CamelVeeMessageInfo
 *
 * Returns: (transfer none): A #CamelFolder of the original
 *   message info, which this @vmi is proxying.
 *
 * Since: 3.24
 **/
CamelFolder *
camel_vee_message_info_get_original_folder (const CamelVeeMessageInfo *vmi)
{
	g_return_val_if_fail (CAMEL_IS_VEE_MESSAGE_INFO (vmi), NULL);

	if (!vmi->priv->orig_summary)
		return NULL;

	return camel_folder_summary_get_folder (vmi->priv->orig_summary);
}
