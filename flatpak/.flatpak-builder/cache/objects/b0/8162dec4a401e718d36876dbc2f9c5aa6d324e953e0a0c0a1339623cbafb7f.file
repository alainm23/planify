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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>

#include <glib/gstdio.h>

#include "camel-enums.h"
#include "camel-enumtypes.h"
#include "camel-file-utils.h"
#include "camel-object.h"

#define d(x)

#define CAMEL_OBJECT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_OBJECT, CamelObjectPrivate))

struct _CamelObjectPrivate {
	gchar *state_filename;
};

enum {
	PROP_0,
	PROP_STATE_FILENAME
};

G_DEFINE_ABSTRACT_TYPE (CamelObject, camel_object, G_TYPE_OBJECT)

/* State file for CamelObject data.
 * Any later versions should only append data.
 *
 * version:uint32
 *
 * Version 0 of the file:
 *
 * version:uint32 = 0
 * count:uint32				-- count of meta-data items
 * ( name:string value:string ) *count		-- meta-data items
 *
 * Version 1 of the file adds:
 * count:uint32					-- count of persistent properties
 * ( tag:uing32 value:tagtype ) *count		-- persistent properties
 */

#define CAMEL_OBJECT_STATE_FILE_MAGIC "CLMD"

/* XXX This is a holdover from Camel's old homegrown type system.
 *     CamelArg was a kind of primitive version of GObject properties.
 *     The argument ID and data type were encoded into a 32-bit integer.
 *     Unfortunately the encoding was also used in the binary state file
 *     format, so we still need the secret decoder ring. */
enum camel_arg_t {
	CAMEL_ARG_END = 0,
	CAMEL_ARG_IGNORE = 1,	/* override/ignore an arg in-place */

	CAMEL_ARG_FIRST = 1024,	/* 1024 args reserved for arg system */

	CAMEL_ARG_TYPE = 0xf0000000, /* type field for tags */
	CAMEL_ARG_TAG = 0x0fffffff, /* tag field for args */

	CAMEL_ARG_OBJ = 0x00000000, /* object */
	CAMEL_ARG_INT = 0x10000000, /* gint */
	CAMEL_ARG_DBL = 0x20000000, /* gdouble */
	CAMEL_ARG_STR = 0x30000000, /* c string */
	CAMEL_ARG_PTR = 0x40000000, /* ptr */
	CAMEL_ARG_BOO = 0x50000000, /* bool */
	CAMEL_ARG_3ST = 0x60000000  /* three-state */
};

#define CAMEL_ARGV_MAX (20)

static void
object_set_property (GObject *object,
                     guint property_id,
                     const GValue *value,
                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STATE_FILENAME:
			camel_object_set_state_filename (
				CAMEL_OBJECT (object),
				g_value_get_string (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
object_get_property (GObject *object,
                     guint property_id,
                     GValue *value,
                     GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_STATE_FILENAME:
			g_value_set_string (
				value, camel_object_get_state_filename (
				CAMEL_OBJECT (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
object_finalize (GObject *object)
{
	CamelObjectPrivate *priv;

	priv = CAMEL_OBJECT_GET_PRIVATE (object);

	g_free (priv->state_filename);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_object_parent_class)->finalize (object);
}

static void
object_notify (GObject *object,
               GParamSpec *pspec)
{
	/* Placeholder so subclasses can safely chain up, since
	 * GObjectClass itself does not implement this method. */
}

static gint
object_state_read (CamelObject *object,
                   FILE *fp)
{
	GValue value = G_VALUE_INIT;
	GObjectClass *class;
	GParamSpec **properties;
	guint32 count, version;
	guint ii, jj, n_properties;

	if (camel_file_util_decode_uint32 (fp, &version) == -1)
		return -1;

	if (version > 2)
		return -1;

	if (camel_file_util_decode_uint32 (fp, &count) == -1)
		return -1;

	/* XXX Camel no longer supports meta-data in state
	 *     files, so we're just eating dead data here. */
	for (ii = 0; ii < count; ii++) {
		gchar *name = NULL;
		gchar *value = NULL;
		gboolean success;

		success =
			camel_file_util_decode_string (fp, &name) == 0 &&
			camel_file_util_decode_string (fp, &value) == 0;

		g_free (name);
		g_free (value);

		if (!success)
			return -1;
	}

	if (version == 0)
		return 0;

	if (camel_file_util_decode_uint32 (fp, &count) == -1)
		return 0;

	if (count == 0 || count > 1024)
		/* Maybe it was just version 0 afterall. */
		return 0;

	count = MIN (count, CAMEL_ARGV_MAX);

	class = G_OBJECT_GET_CLASS (object);
	properties = g_object_class_list_properties (class, &n_properties);

	for (ii = 0; ii < count; ii++) {
		gboolean property_set = FALSE;
		guint32 tag, v_uint32;
		gint32 v_int32;

		if (camel_file_util_decode_uint32 (fp, &tag) == -1)
			goto exit;

		/* Record state file values into GValues.
		 * XXX We currently only support booleans and three-state. */
		switch (tag & CAMEL_ARG_TYPE) {
			case CAMEL_ARG_BOO:
				if (camel_file_util_decode_uint32 (fp, &v_uint32) == -1)
					goto exit;
				g_value_init (&value, G_TYPE_BOOLEAN);
				g_value_set_boolean (&value, (gboolean) v_uint32);
				break;
			case CAMEL_ARG_INT:
				if (camel_file_util_decode_fixed_int32 (fp, &v_int32) == -1)
					goto exit;
				g_value_init (&value, G_TYPE_INT);
				g_value_set_int (&value, v_int32);
				break;
			case CAMEL_ARG_3ST:
				if (camel_file_util_decode_uint32 (fp, &v_uint32) == -1)
					goto exit;
				g_value_init (&value, CAMEL_TYPE_THREE_STATE);
				g_value_set_enum (&value, (CamelThreeState) v_uint32);
				break;
			default:
				g_warn_if_reached ();
				goto exit;
		}

		/* Now we have to match the legacy numeric CamelArg tag
		 * value with a GObject property.  The GObject property
		 * IDs have been set to the same legacy tag values, but
		 * we have to access a private GParamSpec field to get
		 * to them (pspec->param_id). */

		tag &= CAMEL_ARG_TAG;  /* filter out the type code */

		for (jj = 0; jj < n_properties; jj++) {
			GParamSpec *pspec = properties[jj];

			if (pspec->param_id != tag)
				continue;

			/* Sanity check. */
			g_warn_if_fail (pspec->flags & CAMEL_PARAM_PERSISTENT);
			if ((pspec->flags & CAMEL_PARAM_PERSISTENT) == 0)
				continue;

			if (version == 1 && pspec->value_type == CAMEL_TYPE_THREE_STATE &&
			    G_VALUE_HOLDS_BOOLEAN (&value)) {
				/* Convert from boolean to three-state value. Assign the 'TRUE' to 'On'
				   and the rest keep as 'Inconsistent'. */
				gboolean stored = g_value_get_boolean (&value);

				g_value_unset (&value);
				g_value_init (&value, CAMEL_TYPE_THREE_STATE);
				g_value_set_enum (&value, stored ? CAMEL_THREE_STATE_ON : CAMEL_THREE_STATE_INCONSISTENT);
			}

			g_object_set_property (
				G_OBJECT (object), pspec->name, &value);

			property_set = TRUE;
			break;
		}

		/* XXX This tag was used by the old IMAP backend.
		 *     It may still show up in accounts that were
		 *     migrated from IMAP to IMAPX.  Silence the
		 *     warning. */
		if (tag == 0x2500)
			property_set = TRUE;

		if (!property_set)
			g_warning (
				"Could not find a corresponding %s "
				"property for state file tag 0x%x",
				G_OBJECT_TYPE_NAME (object), tag);

		g_value_unset (&value);
	}

exit:
	g_free (properties);

	return 0;
}

static gint
object_state_write (CamelObject *object,
                    FILE *fp)
{
	GValue value = G_VALUE_INIT;
	GObjectClass *class;
	GParamSpec **properties;
	guint ii, n_properties;
	guint32 n_persistent = 0;

	class = G_OBJECT_GET_CLASS (object);
	properties = g_object_class_list_properties (class, &n_properties);

	/* Version = 2 */
	if (camel_file_util_encode_uint32 (fp, 2) == -1)
		goto exit;

	/* No meta-data items. */
	if (camel_file_util_encode_uint32 (fp, 0) == -1)
		goto exit;

	/* Count persistent properties. */
	for (ii = 0; ii < n_properties; ii++)
		if (properties[ii]->flags & CAMEL_PARAM_PERSISTENT)
			n_persistent++;

	if (camel_file_util_encode_uint32 (fp, n_persistent) == -1)
		goto exit;

	/* Write a tag + value pair for each persistent property.
	 * Tags identify the property ID and data type; they're an
	 * artifact of CamelArgs.  The persistent GObject property
	 * IDs are set to match the legacy CamelArg tag values. */

	for (ii = 0; ii < n_properties; ii++) {
		GParamSpec *pspec = properties[ii];
		guint32 tag, v_uint32;
		gint32 v_int32;

		if ((pspec->flags & CAMEL_PARAM_PERSISTENT) == 0)
			continue;

		g_value_init (&value, pspec->value_type);

		g_object_get_property (
			G_OBJECT (object), pspec->name, &value);

		tag = pspec->param_id;

		/* Record the GValue to the state file.
		 * XXX We currently only support booleans. */
		switch (pspec->value_type) {
			case G_TYPE_BOOLEAN:
				tag |= CAMEL_ARG_BOO;
				v_uint32 = g_value_get_boolean (&value);
				if (camel_file_util_encode_uint32 (fp, tag) == -1)
					goto exit;
				if (camel_file_util_encode_uint32 (fp, v_uint32) == -1)
					goto exit;
				break;
			case G_TYPE_INT:
				tag |= CAMEL_ARG_INT;
				v_int32 = g_value_get_int (&value);
				if (camel_file_util_encode_uint32 (fp, tag) == -1)
					goto exit;
				if (camel_file_util_encode_fixed_int32 (fp, v_int32) == -1)
					goto exit;
				break;
			default:
				if (pspec->value_type == CAMEL_TYPE_THREE_STATE) {
					tag |= CAMEL_ARG_3ST;
					v_uint32 = g_value_get_enum (&value);
					if (camel_file_util_encode_uint32 (fp, tag) == -1)
						goto exit;
					if (camel_file_util_encode_uint32 (fp, v_uint32) == -1)
						goto exit;
				} else {
					g_warn_if_reached ();
					goto exit;
				}
				break;
		}

		g_value_unset (&value);
	}

exit:
	g_free (properties);

	return 0;
}

static void
camel_object_class_init (CamelObjectClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelObjectPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = object_set_property;
	object_class->get_property = object_get_property;
	object_class->finalize = object_finalize;
	object_class->notify = object_notify;

	class->state_read = object_state_read;
	class->state_write = object_state_write;

	/**
	 * CamelObject:state-filename
	 *
	 * The file in which to store persistent property values for this
	 * instance.
	 **/
	g_object_class_install_property (
		object_class,
		PROP_STATE_FILENAME,
		g_param_spec_string (
			"state-filename",
			"State Filename",
			"File containing persistent property values",
			NULL,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY));
}

static void
camel_object_init (CamelObject *object)
{
	object->priv = CAMEL_OBJECT_GET_PRIVATE (object);
}

G_DEFINE_QUARK (camel-error-quark, camel_error)

/**
 * camel_object_state_read:
 * @object: a #CamelObject
 *
 * Read persistent object state from #CamelObject:state-filename.
 *
 * Returns: -1 on error.
 **/
gint
camel_object_state_read (CamelObject *object)
{
	CamelObjectClass *class;
	const gchar *state_filename;
	gint res = -1;
	FILE *fp;
	gchar magic[4];

	g_return_val_if_fail (CAMEL_IS_OBJECT (object), -1);

	class = CAMEL_OBJECT_GET_CLASS (object);
	g_return_val_if_fail (class != NULL, -1);

	state_filename = camel_object_get_state_filename (object);
	if (state_filename == NULL)
		return 0;

	fp = g_fopen (state_filename, "rb");
	if (fp != NULL) {
		if (fread (magic, 4, 1, fp) == 1
		    && memcmp (magic, CAMEL_OBJECT_STATE_FILE_MAGIC, 4) == 0)
			res = class->state_read (object, fp);
		fclose (fp);
	}

	return res;
}

/**
 * camel_object_state_write:
 * @object: a #CamelObject
 *
 * Write persistent object state #CamelObject:state-filename.
 *
 * Returns: -1 on error.
 **/
gint
camel_object_state_write (CamelObject *object)
{
	CamelObjectClass *class;
	const gchar *state_filename;
	gchar *savename, *dirname;
	gint res = -1;
	FILE *fp;

	g_return_val_if_fail (CAMEL_IS_OBJECT (object), -1);

	class = CAMEL_OBJECT_GET_CLASS (object);
	g_return_val_if_fail (class != NULL, -1);

	state_filename = camel_object_get_state_filename (object);
	if (state_filename == NULL)
		return 0;

	savename = camel_file_util_savename (state_filename);

	dirname = g_path_get_dirname (savename);
	g_mkdir_with_parents (dirname, 0700);
	g_free (dirname);

	fp = g_fopen (savename, "wb");
	if (fp != NULL) {
		if (fwrite (CAMEL_OBJECT_STATE_FILE_MAGIC, 4, 1, fp) == 1
		    && class->state_write (object, fp) == 0) {
			if (fclose (fp) == 0) {
				res = 0;
				if (g_rename (savename, state_filename) == -1)
					res = -1;
			}
		} else {
			fclose (fp);
		}
	} else {
		g_warning ("Could not save object state file to '%s': %s", savename, g_strerror (errno));
	}

	g_free (savename);

	return res;
}

/**
 * camel_object_get_state_filename:
 * @object: a #CamelObject
 *
 * Returns the name of the file in which persistent property values for
 * @object are stored.  The file is used by camel_object_state_write()
 * and camel_object_state_read() to save and restore object state.
 *
 * Returns: the name of the persistent property file
 *
 * Since: 2.32
 **/
const gchar *
camel_object_get_state_filename (CamelObject *object)
{
	g_return_val_if_fail (CAMEL_IS_OBJECT (object), NULL);

	return object->priv->state_filename;
}

/**
 * camel_object_set_state_filename:
 * @object: a #CamelObject
 * @state_filename: path to a local file
 *
 * Sets the name of the file in which persistent property values for
 * @object are stored.  The file is used by camel_object_state_write()
 * and camel_object_state_read() to save and restore object state.
 *
 * Since: 2.32
 **/
void
camel_object_set_state_filename (CamelObject *object,
                                 const gchar *state_filename)
{
	g_return_if_fail (CAMEL_IS_OBJECT (object));

	if (g_strcmp0 (object->priv->state_filename, state_filename) == 0)
		return;

	g_free (object->priv->state_filename);
	object->priv->state_filename = g_strdup (state_filename);

	g_object_notify (G_OBJECT (object), "state-filename");
}
