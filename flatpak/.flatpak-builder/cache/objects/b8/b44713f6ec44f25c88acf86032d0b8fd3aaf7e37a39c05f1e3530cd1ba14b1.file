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
#include "camel-maildir-summary.h"

#include "camel-maildir-message-info.h"

struct _CamelMaildirMessageInfoPrivate {
	gchar *filename;
};

enum {
	PROP_0,
	PROP_FILENAME
};

G_DEFINE_TYPE (CamelMaildirMessageInfo, camel_maildir_message_info, CAMEL_TYPE_MESSAGE_INFO_BASE)

static CamelMessageInfo *
maildir_message_info_clone (const CamelMessageInfo *mi,
			    CamelFolderSummary *assign_summary)
{
	CamelMessageInfo *result;

	g_return_val_if_fail (CAMEL_IS_MAILDIR_MESSAGE_INFO (mi), NULL);

	result = CAMEL_MESSAGE_INFO_CLASS (camel_maildir_message_info_parent_class)->clone (mi, assign_summary);
	if (!result)
		return NULL;

	if (CAMEL_IS_MAILDIR_MESSAGE_INFO (result)) {
		CamelMaildirMessageInfo *mmi, *mmi_result;

		mmi = CAMEL_MAILDIR_MESSAGE_INFO (mi);
		mmi_result = CAMEL_MAILDIR_MESSAGE_INFO (result);

		/* safe-guard that the mmi's filename doesn't change before it's copied to mmi_result */
		camel_message_info_property_lock (mi);

		camel_maildir_message_info_set_filename (mmi_result, camel_maildir_message_info_get_filename (mmi));

		camel_message_info_property_unlock (mi);
	}

	return result;
}

static gboolean
maildir_message_info_load (CamelMessageInfo *mi,
			   const CamelMIRecord *record,
			   /* const */ gchar **bdata_ptr)
{
	CamelMaildirMessageInfo *mmi;

	g_return_val_if_fail (CAMEL_IS_MAILDIR_MESSAGE_INFO (mi), FALSE);
	g_return_val_if_fail (record != NULL, FALSE);
	g_return_val_if_fail (bdata_ptr != NULL, FALSE);

	if (!CAMEL_MESSAGE_INFO_CLASS (camel_maildir_message_info_parent_class)->load ||
	    !CAMEL_MESSAGE_INFO_CLASS (camel_maildir_message_info_parent_class)->load (mi, record, bdata_ptr))
		return FALSE;

	mmi = CAMEL_MAILDIR_MESSAGE_INFO (mi);

	camel_maildir_message_info_take_filename (mmi, camel_maildir_summary_info_to_name (mi));

	return TRUE;
}

static void
maildir_message_info_set_property (GObject *object,
				   guint property_id,
				   const GValue *value,
				   GParamSpec *pspec)
{
	CamelMaildirMessageInfo *mmi = CAMEL_MAILDIR_MESSAGE_INFO (object);

	switch (property_id) {
	case PROP_FILENAME:
		camel_maildir_message_info_set_filename (mmi, g_value_get_string (value));
		return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
maildir_message_info_get_property (GObject *object,
				   guint property_id,
				   GValue *value,
				   GParamSpec *pspec)
{
	CamelMaildirMessageInfo *mmi = CAMEL_MAILDIR_MESSAGE_INFO (object);

	switch (property_id) {
	case PROP_FILENAME:
		g_value_set_string (value, camel_maildir_message_info_get_filename (mmi));
		return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
maildir_message_info_dispose (GObject *object)
{
	CamelMaildirMessageInfo *mmi = CAMEL_MAILDIR_MESSAGE_INFO (object);

	g_free (mmi->priv->filename);
	mmi->priv->filename = NULL;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (camel_maildir_message_info_parent_class)->dispose (object);
}

static void
camel_maildir_message_info_class_init (CamelMaildirMessageInfoClass *class)
{
	CamelMessageInfoClass *mi_class;
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelMaildirMessageInfoPrivate));

	mi_class = CAMEL_MESSAGE_INFO_CLASS (class);
	mi_class->clone = maildir_message_info_clone;
	mi_class->load = maildir_message_info_load;

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = maildir_message_info_set_property;
	object_class->get_property = maildir_message_info_get_property;
	object_class->dispose = maildir_message_info_dispose;

	/**
	 * CamelMaildirMessageInfo:filename
	 *
	 * File name of the message on the disk.
	 *
	 * Since: 3.24
	 **/
	g_object_class_install_property (
		object_class,
		PROP_FILENAME,
		g_param_spec_string (
			"filename",
			"Filename",
			NULL,
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_EXPLICIT_NOTIFY));
}

static void
camel_maildir_message_info_init (CamelMaildirMessageInfo *mmi)
{
	mmi->priv = G_TYPE_INSTANCE_GET_PRIVATE (mmi, CAMEL_TYPE_MAILDIR_MESSAGE_INFO, CamelMaildirMessageInfoPrivate);
}

const gchar *
camel_maildir_message_info_get_filename (const CamelMaildirMessageInfo *mmi)
{
	CamelMessageInfo *mi;
	const gchar *result;

	g_return_val_if_fail (CAMEL_IS_MAILDIR_MESSAGE_INFO (mmi), NULL);

	mi = CAMEL_MESSAGE_INFO (mmi);

	camel_message_info_property_lock (mi);
	result = mmi->priv->filename;
	camel_message_info_property_unlock (mi);

	return result;
}

gchar *
camel_maildir_message_info_dup_filename (const CamelMaildirMessageInfo *mmi)
{
	CamelMessageInfo *mi;
	gchar *result;

	g_return_val_if_fail (CAMEL_IS_MAILDIR_MESSAGE_INFO (mmi), NULL);

	mi = CAMEL_MESSAGE_INFO (mmi);

	camel_message_info_property_lock (mi);
	result = g_strdup (mmi->priv->filename);
	camel_message_info_property_unlock (mi);

	return result;
}

gboolean
camel_maildir_message_info_set_filename (CamelMaildirMessageInfo *mmi,
					 const gchar *filename)
{
	g_return_val_if_fail (CAMEL_IS_MAILDIR_MESSAGE_INFO (mmi), FALSE);

	return camel_maildir_message_info_take_filename (mmi, g_strdup (filename));
}

gboolean
camel_maildir_message_info_take_filename (CamelMaildirMessageInfo *mmi,
					  gchar *filename)
{
	CamelMessageInfo *mi;
	gboolean changed;

	g_return_val_if_fail (CAMEL_IS_MAILDIR_MESSAGE_INFO (mmi), FALSE);

	mi = CAMEL_MESSAGE_INFO (mmi);

	camel_message_info_property_lock (mi);

	changed = g_strcmp0 (mmi->priv->filename, filename) != 0;

	if (changed) {
		g_free (mmi->priv->filename);
		mmi->priv->filename = filename;
	} else if (filename != mmi->priv->filename) {
		g_free (filename);
	}

	camel_message_info_property_unlock (mi);

	if (changed && !camel_message_info_get_abort_notifications (mi)) {
		g_object_notify (G_OBJECT (mmi), "filename");
		camel_message_info_set_dirty (mi, TRUE);
	}

	return changed;
}
