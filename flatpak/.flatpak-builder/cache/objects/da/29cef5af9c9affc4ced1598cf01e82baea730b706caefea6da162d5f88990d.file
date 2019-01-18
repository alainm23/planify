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

#include "camel-folder-summary.h"
#include "camel-message-info.h"

#include "camel-message-info-base.h"

struct _CamelMessageInfoBasePrivate {
	guint32 flags;		/* bit-or of CamelMessageFlags */
	CamelNamedFlags *user_flags;
	CamelNameValueArray *user_tags;
	gchar *subject;
	gchar *from;
	gchar *to;
	gchar *cc;
	gchar *mlist;
	guint32 size;
	gint64 date_sent;	/* aka time_t */
	gint64 date_received;	/* aka time_t */
	guint64 message_id;
	GArray *references;	/* guint64, aka CamelSummaryMessageID */
	CamelNameValueArray *headers;
};

G_DEFINE_TYPE (CamelMessageInfoBase, camel_message_info_base, CAMEL_TYPE_MESSAGE_INFO)

static guint32
message_info_base_get_flags (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	guint32 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), 0);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->flags;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_flags (CamelMessageInfo *mi,
			     guint32 mask,
			     guint32 set)
{
	CamelMessageInfoBase *bmi;
	guint32 old_flags;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	old_flags = bmi->priv->flags;
	bmi->priv->flags = (old_flags & ~mask) | (set & mask);
	changed = old_flags != bmi->priv->flags;
	camel_message_info_property_unlock (mi);

	return changed;
}

static gboolean
message_info_base_get_user_flag (const CamelMessageInfo *mi,
				 const gchar *name)
{
	CamelMessageInfoBase *bmi;
	gboolean result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	if (bmi->priv->user_flags)
		result = camel_named_flags_contains (bmi->priv->user_flags, name);
	else
		result = FALSE;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_user_flag (CamelMessageInfo *mi,
				 const gchar *name,
				 gboolean state)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	if (!bmi->priv->user_flags)
		bmi->priv->user_flags = camel_named_flags_new ();

	if (state)
		changed = camel_named_flags_insert (bmi->priv->user_flags, name);
	else
		changed = camel_named_flags_remove (bmi->priv->user_flags, name);
	camel_message_info_property_unlock (mi);

	return changed;
}

static const CamelNamedFlags *
message_info_base_get_user_flags (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const CamelNamedFlags *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->user_flags;
	camel_message_info_property_unlock (mi);

	return result;
}

static CamelNamedFlags *
message_info_base_dup_user_flags (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	CamelNamedFlags *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	if (bmi->priv->user_flags)
		result = camel_named_flags_copy (bmi->priv->user_flags);
	else
		result = NULL;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_take_user_flags (CamelMessageInfo *mi,
				   CamelNamedFlags *user_flags)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = !camel_named_flags_equal (bmi->priv->user_flags, user_flags);

	if (changed) {
		camel_named_flags_free (bmi->priv->user_flags);
		bmi->priv->user_flags = user_flags;
	} else {
		camel_named_flags_free (user_flags);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static const gchar *
message_info_base_get_user_tag (const CamelMessageInfo *mi,
				const gchar *name)
{
	CamelMessageInfoBase *bmi;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);
	g_return_val_if_fail (name != NULL, NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	if (bmi->priv->user_tags)
		result = camel_name_value_array_get_named (bmi->priv->user_tags, CAMEL_COMPARE_CASE_SENSITIVE, name);
	else
		result = NULL;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_user_tag (CamelMessageInfo *mi,
				const gchar *name,
				const gchar *value)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);
	g_return_val_if_fail (name != NULL, FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	if (!bmi->priv->user_tags)
		bmi->priv->user_tags = camel_name_value_array_new ();

	if (value)
		changed = camel_name_value_array_set_named (bmi->priv->user_tags, CAMEL_COMPARE_CASE_SENSITIVE, name, value);
	else
		changed = camel_name_value_array_remove_named (bmi->priv->user_tags, CAMEL_COMPARE_CASE_SENSITIVE, name, FALSE);
	camel_message_info_property_unlock (mi);

	return changed;
}

static const CamelNameValueArray *
message_info_base_get_user_tags (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const CamelNameValueArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->user_tags;
	camel_message_info_property_unlock (mi);

	return result;
}

static CamelNameValueArray *
message_info_base_dup_user_tags (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	CamelNameValueArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = camel_name_value_array_copy (bmi->priv->user_tags);
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_take_user_tags (CamelMessageInfo *mi,
				  CamelNameValueArray *user_tags)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = !camel_name_value_array_equal (bmi->priv->user_tags, user_tags, CAMEL_COMPARE_CASE_SENSITIVE);

	if (changed) {
		camel_name_value_array_free (bmi->priv->user_tags);
		bmi->priv->user_tags = user_tags;
	} else {
		camel_name_value_array_free (user_tags);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static const gchar *
message_info_base_get_subject (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->subject;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_subject (CamelMessageInfo *mi,
			       const gchar *subject)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = g_strcmp0 (bmi->priv->subject, subject) != 0;

	if (changed) {
		g_free (bmi->priv->subject);
		bmi->priv->subject = g_strdup (subject);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static const gchar *
message_info_base_get_from (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->from;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_from (CamelMessageInfo *mi,
			    const gchar *from)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = g_strcmp0 (bmi->priv->from, from) != 0;

	if (changed) {
		g_free (bmi->priv->from);
		bmi->priv->from = g_strdup (from);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static const gchar *
message_info_base_get_to (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->to;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_to (CamelMessageInfo *mi,
			  const gchar *to)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = g_strcmp0 (bmi->priv->to, to) != 0;

	if (changed) {
		g_free (bmi->priv->to);
		bmi->priv->to = g_strdup (to);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static const gchar *
message_info_base_get_cc (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->cc;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_cc (CamelMessageInfo *mi,
			  const gchar *cc)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = g_strcmp0 (bmi->priv->cc, cc) != 0;

	if (changed) {
		g_free (bmi->priv->cc);
		bmi->priv->cc = g_strdup (cc);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static const gchar *
message_info_base_get_mlist (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->mlist;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_mlist (CamelMessageInfo *mi,
			     const gchar *mlist)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = g_strcmp0 (bmi->priv->mlist, mlist) != 0;

	if (changed) {
		g_free (bmi->priv->mlist);
		bmi->priv->mlist = g_strdup (mlist);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static guint32
message_info_base_get_size (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	guint32 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), 0);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->size;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_size (CamelMessageInfo *mi,
			    guint32 size)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = bmi->priv->size != size;

	if (changed)
		bmi->priv->size = size;

	camel_message_info_property_unlock (mi);

	return changed;
}

static gint64
message_info_base_get_date_sent (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	gint64 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), 0);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->date_sent;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_date_sent (CamelMessageInfo *mi,
				 gint64 date_sent)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = bmi->priv->date_sent != date_sent;

	if (changed)
		bmi->priv->date_sent = date_sent;

	camel_message_info_property_unlock (mi);

	return changed;
}

static gint64
message_info_base_get_date_received (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	gint64 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), 0);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->date_received;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_date_received (CamelMessageInfo *mi,
				     gint64 date_received)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = bmi->priv->date_received != date_received;

	if (changed)
		bmi->priv->date_received = date_received;

	camel_message_info_property_unlock (mi);

	return changed;
}

static guint64
message_info_base_get_message_id (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	guint64 result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), 0);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->message_id;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_set_message_id (CamelMessageInfo *mi,
				  guint64 message_id)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = bmi->priv->message_id != message_id;

	if (changed)
		bmi->priv->message_id = message_id;

	camel_message_info_property_unlock (mi);

	return changed;
}

static const GArray *
message_info_base_get_references (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const GArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->references;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_references_equal (const GArray *references_a,
				    const GArray *references_b)
{
	guint ii, len;

	if (references_a == references_b)
		return TRUE;

	if (!references_a || !references_b)
		return FALSE;

	len = references_a->len;
	if (len != references_b->len)
		return FALSE;

	/* They can be still the same, only having the items on different indexes,
	   but that's too expensive to compare precisely. */
	for (ii = 0; ii < len; ii++) {
		if (g_array_index (references_a, guint64, ii) != g_array_index (references_b, guint64, ii))
			return FALSE;
	}

	return TRUE;
}

static gboolean
message_info_base_take_references (CamelMessageInfo *mi,
				   GArray *references)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = !message_info_base_references_equal (bmi->priv->references, references);

	if (changed) {
		if (bmi->priv->references)
			g_array_unref (bmi->priv->references);
		bmi->priv->references = references;
	} else if (references) {
		g_array_unref (references);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static const CamelNameValueArray *
message_info_base_get_headers (const CamelMessageInfo *mi)
{
	CamelMessageInfoBase *bmi;
	const CamelNameValueArray *result;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), NULL);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);
	result = bmi->priv->headers;
	camel_message_info_property_unlock (mi);

	return result;
}

static gboolean
message_info_base_take_headers (CamelMessageInfo *mi,
				CamelNameValueArray *headers)
{
	CamelMessageInfoBase *bmi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MESSAGE_INFO_BASE (mi), FALSE);

	bmi = CAMEL_MESSAGE_INFO_BASE (mi);

	camel_message_info_property_lock (mi);

	changed = !camel_name_value_array_equal (bmi->priv->headers, headers, CAMEL_COMPARE_CASE_SENSITIVE);

	if (changed) {
		camel_name_value_array_free (bmi->priv->headers);
		bmi->priv->headers = headers;
	} else {
		camel_name_value_array_free (headers);
	}

	camel_message_info_property_unlock (mi);

	return changed;
}

static void
message_info_base_dispose (GObject *object)
{
	CamelMessageInfoBase *bmi = CAMEL_MESSAGE_INFO_BASE (object);

	camel_named_flags_free (bmi->priv->user_flags);
	bmi->priv->user_flags = NULL;

	camel_name_value_array_free (bmi->priv->user_tags);
	bmi->priv->user_tags = NULL;

	#define free_ptr(x) G_STMT_START { g_free (x); x = NULL; } G_STMT_END

	free_ptr (bmi->priv->subject);
	free_ptr (bmi->priv->from);
	free_ptr (bmi->priv->to);
	free_ptr (bmi->priv->cc);
	free_ptr (bmi->priv->mlist);

	#undef free_ptr

	if (bmi->priv->references) {
		g_array_unref (bmi->priv->references);
		bmi->priv->references = NULL;
	}

	camel_name_value_array_free (bmi->priv->headers);
	bmi->priv->headers = NULL;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_message_info_base_parent_class)->dispose (object);
}

static void
camel_message_info_base_class_init (CamelMessageInfoBaseClass *class)
{
	CamelMessageInfoClass *mi_class;
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelMessageInfoBasePrivate));

	mi_class = CAMEL_MESSAGE_INFO_CLASS (class);
	mi_class->get_flags = message_info_base_get_flags;
	mi_class->set_flags = message_info_base_set_flags;
	mi_class->get_user_flag = message_info_base_get_user_flag;
	mi_class->set_user_flag = message_info_base_set_user_flag;
	mi_class->get_user_flags = message_info_base_get_user_flags;
	mi_class->dup_user_flags = message_info_base_dup_user_flags;
	mi_class->take_user_flags = message_info_base_take_user_flags;
	mi_class->get_user_tag = message_info_base_get_user_tag;
	mi_class->set_user_tag = message_info_base_set_user_tag;
	mi_class->get_user_tags = message_info_base_get_user_tags;
	mi_class->dup_user_tags = message_info_base_dup_user_tags;
	mi_class->take_user_tags = message_info_base_take_user_tags;
	mi_class->get_subject = message_info_base_get_subject;
	mi_class->set_subject = message_info_base_set_subject;
	mi_class->get_from = message_info_base_get_from;
	mi_class->set_from = message_info_base_set_from;
	mi_class->get_to = message_info_base_get_to;
	mi_class->set_to = message_info_base_set_to;
	mi_class->get_cc = message_info_base_get_cc;
	mi_class->set_cc = message_info_base_set_cc;
	mi_class->get_mlist = message_info_base_get_mlist;
	mi_class->set_mlist = message_info_base_set_mlist;
	mi_class->get_size = message_info_base_get_size;
	mi_class->set_size = message_info_base_set_size;
	mi_class->get_date_sent = message_info_base_get_date_sent;
	mi_class->set_date_sent = message_info_base_set_date_sent;
	mi_class->get_date_received = message_info_base_get_date_received;
	mi_class->set_date_received = message_info_base_set_date_received;
	mi_class->get_message_id = message_info_base_get_message_id;
	mi_class->set_message_id = message_info_base_set_message_id;
	mi_class->get_references = message_info_base_get_references;
	mi_class->take_references = message_info_base_take_references;
	mi_class->get_headers = message_info_base_get_headers;
	mi_class->take_headers = message_info_base_take_headers;

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = message_info_base_dispose;
}

static void
camel_message_info_base_init (CamelMessageInfoBase *bmi)
{
	bmi->priv = G_TYPE_INSTANCE_GET_PRIVATE (bmi, CAMEL_TYPE_MESSAGE_INFO_BASE, CamelMessageInfoBasePrivate);
}
