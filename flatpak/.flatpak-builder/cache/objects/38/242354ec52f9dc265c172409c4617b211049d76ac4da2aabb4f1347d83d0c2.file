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

#include "camel/camel.h"
#include "camel-mbox-summary.h"

#include "camel-mbox-message-info.h"

struct _CamelMboxMessageInfoPrivate {
	goffset offset;
};

enum {
	PROP_0,
	PROP_OFFSET
};

G_DEFINE_TYPE (CamelMboxMessageInfo, camel_mbox_message_info, CAMEL_TYPE_MESSAGE_INFO_BASE)

static CamelMessageInfo *
mbox_message_info_clone (const CamelMessageInfo *mi,
			 CamelFolderSummary *assign_summary)
{
	CamelMessageInfo *result;

	g_return_val_if_fail (CAMEL_IS_MBOX_MESSAGE_INFO (mi), NULL);

	result = CAMEL_MESSAGE_INFO_CLASS (camel_mbox_message_info_parent_class)->clone (mi, assign_summary);
	if (!result)
		return NULL;

	if (CAMEL_IS_MBOX_MESSAGE_INFO (result)) {
		CamelMboxMessageInfo *mmi, *mmi_result;

		mmi = CAMEL_MBOX_MESSAGE_INFO (mi);
		mmi_result = CAMEL_MBOX_MESSAGE_INFO (result);

		camel_mbox_message_info_set_offset (mmi_result, camel_mbox_message_info_get_offset (mmi));
	}

	return result;
}

static gboolean
mbox_message_info_load (CamelMessageInfo *mi,
			const CamelMIRecord *record,
			/* const */ gchar **bdata_ptr)
{
	CamelMboxMessageInfo *mmi;
	gint64 offset;

	g_return_val_if_fail (CAMEL_IS_MBOX_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (record != NULL, FALSE);
	g_return_val_if_fail (bdata_ptr != NULL, FALSE);

	if (!CAMEL_MESSAGE_INFO_CLASS (camel_mbox_message_info_parent_class)->load ||
	    !CAMEL_MESSAGE_INFO_CLASS (camel_mbox_message_info_parent_class)->load (mi, record, bdata_ptr))
		return FALSE;

	mmi = CAMEL_MBOX_MESSAGE_INFO (mi);

	offset = camel_util_bdata_get_number (bdata_ptr, -1);
	if (offset < 0)
		return FALSE;

	camel_mbox_message_info_set_offset (mmi, offset);

	return TRUE;
}

static gboolean
mbox_message_info_save (const CamelMessageInfo *mi,
			CamelMIRecord *record,
			GString *bdata_str)
{
	CamelMboxMessageInfo *mmi;

	g_return_val_if_fail (CAMEL_IS_MBOX_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (record != NULL, FALSE);
	g_return_val_if_fail (bdata_str != NULL, FALSE);

	if (!CAMEL_MESSAGE_INFO_CLASS (camel_mbox_message_info_parent_class)->save ||
	    !CAMEL_MESSAGE_INFO_CLASS (camel_mbox_message_info_parent_class)->save (mi, record, bdata_str))
		return FALSE;

	mmi = CAMEL_MBOX_MESSAGE_INFO (mi);

	camel_util_bdata_put_number (bdata_str, camel_mbox_message_info_get_offset (mmi));

	return TRUE;
}

static gboolean
mbox_message_info_set_flags (CamelMessageInfo *mi,
			     guint32 mask,
			     guint32 set)
{
	CamelFolderSummary *summary;
	CamelMboxSummary *mbox_summary;

	summary = camel_message_info_ref_summary (mi);
	mbox_summary = summary ? CAMEL_MBOX_SUMMARY (summary) : NULL;

	/* Basically, if anything could change the Status line, presume it does */
	if (mbox_summary && mbox_summary->xstatus
	    && (mask & (CAMEL_MESSAGE_SEEN | CAMEL_MESSAGE_FLAGGED | CAMEL_MESSAGE_ANSWERED | CAMEL_MESSAGE_DELETED))) {
		mask |= CAMEL_MESSAGE_FOLDER_XEVCHANGE | CAMEL_MESSAGE_FOLDER_FLAGGED;
		set |= CAMEL_MESSAGE_FOLDER_XEVCHANGE | CAMEL_MESSAGE_FOLDER_FLAGGED;
	}

	g_clear_object (&summary);

	return CAMEL_MESSAGE_INFO_CLASS (camel_mbox_message_info_parent_class)->set_flags (mi, mask, set);
}

static void
mbox_message_info_set_property (GObject *object,
				guint property_id,
				const GValue *value,
				GParamSpec *pspec)
{
	CamelMboxMessageInfo *mmi = CAMEL_MBOX_MESSAGE_INFO (object);

	switch (property_id) {
	case PROP_OFFSET:
		camel_mbox_message_info_set_offset (mmi, g_value_get_int64 (value));
		return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
mbox_message_info_get_property (GObject *object,
			        guint property_id,
				GValue *value,
				GParamSpec *pspec)
{
	CamelMboxMessageInfo *mmi = CAMEL_MBOX_MESSAGE_INFO (object);

	switch (property_id) {
	case PROP_OFFSET:
		g_value_set_int64 (value, camel_mbox_message_info_get_offset (mmi));
		return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
camel_mbox_message_info_class_init (CamelMboxMessageInfoClass *class)
{
	CamelMessageInfoClass *mi_class;
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelMboxMessageInfoPrivate));

	mi_class = CAMEL_MESSAGE_INFO_CLASS (class);
	mi_class->clone = mbox_message_info_clone;
	mi_class->load = mbox_message_info_load;
	mi_class->save = mbox_message_info_save;
	mi_class->set_flags = mbox_message_info_set_flags;

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = mbox_message_info_set_property;
	object_class->get_property = mbox_message_info_get_property;

	/**
	 * CamelMboxMessageInfo:offset
	 *
	 * Offset in the file to the related message.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_OFFSET,
		g_param_spec_int64 (
			"offset",
			"Offset",
			NULL,
			0, G_MAXINT64, 0,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));
}

static void
camel_mbox_message_info_init (CamelMboxMessageInfo *mmi)
{
	mmi->priv = G_TYPE_INSTANCE_GET_PRIVATE (mmi, CAMEL_TYPE_MBOX_MESSAGE_INFO, CamelMboxMessageInfoPrivate);
}

goffset
camel_mbox_message_info_get_offset (const CamelMboxMessageInfo *mmi)
{
	CamelMessageInfo *mi;
	goffset result;

	g_return_val_if_fail (CAMEL_IS_MBOX_MESSAGE_INFO (mmi), 0);

	mi = CAMEL_MESSAGE_INFO (mmi);

	camel_message_info_property_lock (mi);
	result = mmi->priv->offset;
	camel_message_info_property_unlock (mi);

	return result;
}

gboolean
camel_mbox_message_info_set_offset (CamelMboxMessageInfo *mmi,
				    goffset offset)
{
	CamelMessageInfo *mi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MBOX_MESSAGE_INFO (mmi), FALSE);

	mi = CAMEL_MESSAGE_INFO (mmi);

	camel_message_info_property_lock (mi);

	changed = mmi->priv->offset != offset;

	if (changed)
		mmi->priv->offset = offset;

	camel_message_info_property_unlock (mi);

	if (changed && !camel_message_info_get_abort_notifications (mi)) {
		g_object_notify (G_OBJECT (mmi), "offset");
		camel_message_info_set_dirty (mi, TRUE);
	}

	return changed;
}
