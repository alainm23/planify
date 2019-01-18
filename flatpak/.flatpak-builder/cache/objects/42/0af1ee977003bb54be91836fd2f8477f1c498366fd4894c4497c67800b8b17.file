/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcefilesaver.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2005-2007 - Paolo Borelli and Paolo Maggi
 * Copyright (C) 2007 - Steve Frécinaux
 * Copyright (C) 2008 - Jesse van den Kieboom
 * Copyright (C) 2014, 2016 - Sébastien Wilmet
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourcefilesaver.h"
#include "gtksourcefile.h"
#include "gtksourcebufferinputstream.h"
#include "gtksourceencoding.h"
#include "gtksourcebuffer.h"
#include "gtksourcebuffer-private.h"
#include "gtksourceview-enumtypes.h"
#include "gtksourceview-i18n.h"

/**
 * SECTION:filesaver
 * @Short_description: Save a GtkSourceBuffer into a file
 * @Title: GtkSourceFileSaver
 * @See_also: #GtkSourceFile, #GtkSourceFileLoader
 *
 * A #GtkSourceFileSaver object permits to save a #GtkSourceBuffer into a
 * #GFile.
 *
 * A file saver should be used only for one save operation, including errors
 * handling. If an error occurs, you can reconfigure the saver and relaunch the
 * operation with gtk_source_file_saver_save_async().
 */

/* The code has been written initially in gedit (GeditDocumentSaver).
 * It uses a GtkSourceBufferInputStream as input, create converter(s) if needed
 * for the encoding and the compression, and write the contents to a
 * GOutputStream (the file).
 */

#if 0
#define DEBUG(x) (x)
#else
#define DEBUG(x)
#endif

#define WRITE_CHUNK_SIZE 8192

#define QUERY_ATTRIBUTES G_FILE_ATTRIBUTE_TIME_MODIFIED

enum
{
	PROP_0,
	PROP_BUFFER,
	PROP_FILE,
	PROP_LOCATION,
	PROP_ENCODING,
	PROP_NEWLINE_TYPE,
	PROP_COMPRESSION_TYPE,
	PROP_FLAGS
};

struct _GtkSourceFileSaverPrivate
{
	/* Weak ref to the GtkSourceBuffer. A strong ref could create a
	 * reference cycle in an application. For example a subclass of
	 * GtkSourceBuffer can have a strong ref to the FileSaver.
	 */
	GtkSourceBuffer *source_buffer;

	/* Weak ref to the GtkSourceFile. A strong ref could create a reference
	 * cycle in an application. For example a subclass of GtkSourceFile can
	 * have a strong ref to the FileSaver.
	 */
	GtkSourceFile *file;

	GFile *location;

	const GtkSourceEncoding *encoding;
	GtkSourceNewlineType newline_type;
	GtkSourceCompressionType compression_type;
	GtkSourceFileSaverFlags flags;

	GTask *task;
};

typedef struct _TaskData TaskData;
struct _TaskData
{
	/* The output_stream contains the required converter(s) for the encoding
	 * and the compression type.
	 * The two streams cannot be spliced directly, because:
	 * (1) We need to call the progress callback.
	 * (2) Sync methods must be used for the input stream, and async
	 *     methods for the output stream.
	 */
	GtkSourceBufferInputStream *input_stream;
	GOutputStream *output_stream;

	GFileInfo *info;

	goffset total_size;
	GFileProgressCallback progress_cb;
	gpointer progress_cb_data;
	GDestroyNotify progress_cb_notify;

	/* This field is used when cancelling the output stream: an error occurs
	 * and is stored in this field, the output stream is cancelled
	 * asynchronously, and then the error is reported to the task.
	 */
	GError *error;

	gssize chunk_bytes_read;
	gssize chunk_bytes_written;
	gchar chunk_buffer[WRITE_CHUNK_SIZE];

	guint tried_mount : 1;
};

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceFileSaver, gtk_source_file_saver, G_TYPE_OBJECT)

static void read_file_chunk (GTask *task);
static void write_file_chunk (GTask *task);
static void recover_not_mounted (GTask *task);

static TaskData *
task_data_new (void)
{
	return g_new0 (TaskData, 1);
}

static void
task_data_free (gpointer data)
{
	TaskData *task_data = data;

	if (task_data == NULL)
	{
		return;
	}

	g_clear_object (&task_data->input_stream);
	g_clear_object (&task_data->output_stream);
	g_clear_object (&task_data->info);
	g_clear_error (&task_data->error);

	if (task_data->progress_cb_notify != NULL)
	{
		task_data->progress_cb_notify (task_data->progress_cb_data);
	}

	g_free (task_data);
}

static void
gtk_source_file_saver_set_property (GObject      *object,
				    guint         prop_id,
				    const GValue *value,
				    GParamSpec   *pspec)
{
	GtkSourceFileSaver *saver = GTK_SOURCE_FILE_SAVER (object);

	switch (prop_id)
	{
		case PROP_BUFFER:
			g_assert (saver->priv->source_buffer == NULL);
			saver->priv->source_buffer = g_value_get_object (value);
			g_object_add_weak_pointer (G_OBJECT (saver->priv->source_buffer),
						   (gpointer *)&saver->priv->source_buffer);
			break;

		case PROP_FILE:
			g_assert (saver->priv->file == NULL);
			saver->priv->file = g_value_get_object (value);
			g_object_add_weak_pointer (G_OBJECT (saver->priv->file),
						   (gpointer *)&saver->priv->file);
			break;

		case PROP_LOCATION:
			g_assert (saver->priv->location == NULL);
			saver->priv->location = g_value_dup_object (value);
			break;

		case PROP_ENCODING:
			gtk_source_file_saver_set_encoding (saver, g_value_get_boxed (value));
			break;

		case PROP_NEWLINE_TYPE:
			gtk_source_file_saver_set_newline_type (saver, g_value_get_enum (value));
			break;

		case PROP_COMPRESSION_TYPE:
			gtk_source_file_saver_set_compression_type (saver, g_value_get_enum (value));
			break;

		case PROP_FLAGS:
			gtk_source_file_saver_set_flags (saver, g_value_get_flags (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_file_saver_get_property (GObject    *object,
				    guint       prop_id,
				    GValue     *value,
				    GParamSpec *pspec)
{
	GtkSourceFileSaver *saver = GTK_SOURCE_FILE_SAVER (object);

	switch (prop_id)
	{
		case PROP_BUFFER:
			g_value_set_object (value, saver->priv->source_buffer);
			break;

		case PROP_FILE:
			g_value_set_object (value, saver->priv->file);
			break;

		case PROP_LOCATION:
			g_value_set_object (value, saver->priv->location);
			break;

		case PROP_ENCODING:
			g_value_set_boxed (value, saver->priv->encoding);
			break;

		case PROP_NEWLINE_TYPE:
			g_value_set_enum (value, saver->priv->newline_type);
			break;

		case PROP_COMPRESSION_TYPE:
			g_value_set_enum (value, saver->priv->compression_type);
			break;

		case PROP_FLAGS:
			g_value_set_flags (value, saver->priv->flags);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_file_saver_dispose (GObject *object)
{
	GtkSourceFileSaver *saver = GTK_SOURCE_FILE_SAVER (object);

	if (saver->priv->source_buffer != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (saver->priv->source_buffer),
					      (gpointer *)&saver->priv->source_buffer);

		saver->priv->source_buffer = NULL;
	}

	if (saver->priv->file != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (saver->priv->file),
					      (gpointer *)&saver->priv->file);

		saver->priv->file = NULL;
	}

	g_clear_object (&saver->priv->location);
	g_clear_object (&saver->priv->task);

	G_OBJECT_CLASS (gtk_source_file_saver_parent_class)->dispose (object);
}

static void
gtk_source_file_saver_constructed (GObject *object)
{
	GtkSourceFileSaver *saver = GTK_SOURCE_FILE_SAVER (object);

	if (saver->priv->file != NULL)
	{
		const GtkSourceEncoding *encoding;
		GtkSourceNewlineType newline_type;
		GtkSourceCompressionType compression_type;

		encoding = gtk_source_file_get_encoding (saver->priv->file);
		gtk_source_file_saver_set_encoding (saver, encoding);

		newline_type = gtk_source_file_get_newline_type (saver->priv->file);
		gtk_source_file_saver_set_newline_type (saver, newline_type);

		compression_type = gtk_source_file_get_compression_type (saver->priv->file);
		gtk_source_file_saver_set_compression_type (saver, compression_type);

		if (saver->priv->location == NULL)
		{
			saver->priv->location = gtk_source_file_get_location (saver->priv->file);

			if (saver->priv->location != NULL)
			{
				g_object_ref (saver->priv->location);
			}
			else
			{
				g_warning ("GtkSourceFileSaver: the GtkSourceFile's location is NULL. "
					   "Use gtk_source_file_saver_new_with_target().");
			}
		}
	}

	G_OBJECT_CLASS (gtk_source_file_saver_parent_class)->constructed (object);
}

static void
gtk_source_file_saver_class_init (GtkSourceFileSaverClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->dispose = gtk_source_file_saver_dispose;
	object_class->set_property = gtk_source_file_saver_set_property;
	object_class->get_property = gtk_source_file_saver_get_property;
	object_class->constructed = gtk_source_file_saver_constructed;

	/**
	 * GtkSourceFileSaver:buffer:
	 *
	 * The #GtkSourceBuffer to save. The #GtkSourceFileSaver object has a
	 * weak reference to the buffer.
	 *
	 * Since: 3.14
	 */
	g_object_class_install_property (object_class,
					 PROP_BUFFER,
					 g_param_spec_object ("buffer",
							      "GtkSourceBuffer",
							      "",
							      GTK_SOURCE_TYPE_BUFFER,
							      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT_ONLY |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceFileSaver:file:
	 *
	 * The #GtkSourceFile. The #GtkSourceFileSaver object has a weak
	 * reference to the file.
	 *
	 * Since: 3.14
	 */
	g_object_class_install_property (object_class,
					 PROP_FILE,
					 g_param_spec_object ("file",
							      "GtkSourceFile",
							      "",
							      GTK_SOURCE_TYPE_FILE,
							      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT_ONLY |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceFileSaver:location:
	 *
	 * The #GFile where to save the buffer. By default the location is taken
	 * from the #GtkSourceFile at construction time.
	 *
	 * Since: 3.14
	 */
	g_object_class_install_property (object_class,
					 PROP_LOCATION,
					 g_param_spec_object ("location",
							      "Location",
							      "",
							      G_TYPE_FILE,
							      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT_ONLY |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceFileSaver:encoding:
	 *
	 * The file's encoding.
	 *
	 * Since: 3.14
	 */
	g_object_class_install_property (object_class,
					 PROP_ENCODING,
					 g_param_spec_boxed ("encoding",
							     "Encoding",
							     "",
							     GTK_SOURCE_TYPE_ENCODING,
							     G_PARAM_READWRITE |
							     G_PARAM_CONSTRUCT |
							     G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceFileSaver:newline-type:
	 *
	 * The newline type.
	 *
	 * Since: 3.14
	 */
	g_object_class_install_property (object_class,
					 PROP_NEWLINE_TYPE,
					 g_param_spec_enum ("newline-type",
					                    "Newline type",
							    "",
					                    GTK_SOURCE_TYPE_NEWLINE_TYPE,
					                    GTK_SOURCE_NEWLINE_TYPE_LF,
					                    G_PARAM_READWRITE |
					                    G_PARAM_CONSTRUCT |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceFileSaver:compression-type:
	 *
	 * The compression type.
	 *
	 * Since: 3.14
	 */
	g_object_class_install_property (object_class,
					 PROP_COMPRESSION_TYPE,
					 g_param_spec_enum ("compression-type",
					                    "Compression type",
					                    "",
					                    GTK_SOURCE_TYPE_COMPRESSION_TYPE,
					                    GTK_SOURCE_COMPRESSION_TYPE_NONE,
					                    G_PARAM_READWRITE |
					                    G_PARAM_CONSTRUCT |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceFileSaver:flags:
	 *
	 * File saving flags.
	 *
	 * Since: 3.14
	 */
	g_object_class_install_property (object_class,
					 PROP_FLAGS,
					 g_param_spec_flags ("flags",
							     "Flags",
							     "",
							     GTK_SOURCE_TYPE_FILE_SAVER_FLAGS,
							     GTK_SOURCE_FILE_SAVER_FLAGS_NONE,
							     G_PARAM_READWRITE |
							     G_PARAM_CONSTRUCT |
							     G_PARAM_STATIC_STRINGS));

	/* Due to potential deadlocks when registering types, we need to
	 * ensure the dependent private class GtkSourceBufferInputStream
	 * has been registered up front.
	 *
	 * See https://bugzilla.gnome.org/show_bug.cgi?id=780216
	 */
	g_type_ensure (GTK_SOURCE_TYPE_BUFFER_INPUT_STREAM);
}

static void
gtk_source_file_saver_init (GtkSourceFileSaver *saver)
{
	saver->priv = gtk_source_file_saver_get_instance_private (saver);
}

/* BEGIN NOTE:
 *
 * This fixes an issue in GOutputStream that applies the atomic replace save
 * strategy. The stream moves the written file to the original file when the
 * stream is closed. However, there is no way currently to tell the stream that
 * the save should be aborted (there could be a conversion error). The patch
 * explicitly closes the output stream in all these cases with a GCancellable in
 * the cancelled state, causing the output stream to close, but not move the
 * file. This makes use of an implementation detail in the local file stream
 * and should be properly fixed by adding the appropriate API in GIO. Until
 * then, at least we prevent data corruption for now.
 *
 * Relevant bug reports:
 *
 * Bug 615110 - write file ignore encoding errors (gedit)
 * https://bugzilla.gnome.org/show_bug.cgi?id=615110
 *
 * Bug 602412 - g_file_replace does not restore original file when there is
 *              errors while writing (glib/gio)
 * https://bugzilla.gnome.org/show_bug.cgi?id=602412
 */
static void
cancel_output_stream_ready_cb (GObject      *source_object,
			       GAsyncResult *result,
			       gpointer      user_data)
{
	GOutputStream *output_stream = G_OUTPUT_STREAM (source_object);
	GTask *task = G_TASK (user_data);
	TaskData *task_data;

	task_data = g_task_get_task_data (task);

	g_output_stream_close_finish (output_stream, result, NULL);

	if (task_data->error != NULL)
	{
		GError *error = task_data->error;
		task_data->error = NULL;
		g_task_return_error (task, error);
	}
	else
	{
		g_task_return_boolean (task, FALSE);
	}
}

static void
cancel_output_stream (GTask *task)
{
	TaskData *task_data;
	GCancellable *cancellable;

	DEBUG ({
	       g_print ("Cancel output stream\n");
	});

	task_data = g_task_get_task_data (task);

	cancellable = g_cancellable_new ();
	g_cancellable_cancel (cancellable);

	g_output_stream_close_async (task_data->output_stream,
				     g_task_get_priority (task),
				     cancellable,
				     cancel_output_stream_ready_cb,
				     task);

	g_object_unref (cancellable);
}

/*
 * END NOTE
 */

static void
query_info_cb (GObject      *source_object,
	       GAsyncResult *result,
	       gpointer      user_data)
{
	GFile *location = G_FILE (source_object);
	GTask *task = G_TASK (user_data);
	TaskData *task_data;
	GError *error = NULL;

	DEBUG ({
	       g_print ("Finished query info on file\n");
	});

	task_data = g_task_get_task_data (task);

	g_clear_object (&task_data->info);
	task_data->info = g_file_query_info_finish (location, result, &error);

	if (error != NULL)
	{
		DEBUG ({
		       g_print ("Query info failed: %s\n", error->message);
		});

		g_task_return_error (task, error);
		return;
	}

	g_task_return_boolean (task, TRUE);
}

static void
close_output_stream_cb (GObject      *source_object,
			GAsyncResult *result,
			gpointer      user_data)
{
	GOutputStream *output_stream = G_OUTPUT_STREAM (source_object);
	GTask *task = G_TASK (user_data);
	GtkSourceFileSaver *saver;
	GError *error = NULL;

	DEBUG ({
	       g_print ("%s\n", G_STRFUNC);
	});

	saver = g_task_get_source_object (task);

	g_output_stream_close_finish (output_stream, result, &error);

	if (error != NULL)
	{
		DEBUG ({
		       g_print ("Closing stream error: %s\n", error->message);
		});

		g_task_return_error (task, error);
		return;
	}

	/* Get the file info: note we cannot use
	 * g_file_output_stream_query_info_async() since it is not able to get
	 * the modification time.
	 */
	DEBUG ({
	       g_print ("Query info on file\n");
	});

	g_file_query_info_async (saver->priv->location,
			         QUERY_ATTRIBUTES,
			         G_FILE_QUERY_INFO_NONE,
				 g_task_get_priority (task),
				 g_task_get_cancellable (task),
			         query_info_cb,
			         task);
}

static void
write_complete (GTask *task)
{
	TaskData *task_data;
	GError *error = NULL;

	DEBUG ({
	       g_print ("Close input stream\n");
	});

	task_data = g_task_get_task_data (task);

	g_input_stream_close (G_INPUT_STREAM (task_data->input_stream),
			      g_task_get_cancellable (task),
			      &error);

	if (error != NULL)
	{
		DEBUG ({
		       g_print ("Closing input stream error: %s\n", error->message);
		});

		g_clear_error (&task_data->error);
		task_data->error = error;
		cancel_output_stream (task);
		return;
	}

	DEBUG ({
	       g_print ("Close output stream\n");
	});

	g_output_stream_close_async (task_data->output_stream,
				     g_task_get_priority (task),
				     g_task_get_cancellable (task),
				     close_output_stream_cb,
				     task);
}

static void
write_file_chunk_cb (GObject      *source_object,
		     GAsyncResult *result,
		     gpointer      user_data)
{
	GOutputStream *output_stream = G_OUTPUT_STREAM (source_object);
	GTask *task = G_TASK (user_data);
	TaskData *task_data;
	gssize bytes_written;
	GError *error = NULL;

	DEBUG ({
	       g_print ("%s\n", G_STRFUNC);
	});

	task_data = g_task_get_task_data (task);

	bytes_written = g_output_stream_write_finish (output_stream, result, &error);

	DEBUG ({
	       g_print ("Written: %" G_GSSIZE_FORMAT "\n", bytes_written);
	});

	if (error != NULL)
	{
		DEBUG ({
		       g_print ("Write error: %s\n", error->message);
		});

		g_clear_error (&task_data->error);
		task_data->error = error;
		cancel_output_stream (task);
		return;
	}

	task_data->chunk_bytes_written += bytes_written;

	/* Write again */
	if (task_data->chunk_bytes_written < task_data->chunk_bytes_read)
	{
		write_file_chunk (task);
		return;
	}

	if (task_data->progress_cb != NULL)
	{
		gsize total_chars_written;

		total_chars_written = _gtk_source_buffer_input_stream_tell (task_data->input_stream);

		task_data->progress_cb (total_chars_written,
					task_data->total_size,
					task_data->progress_cb_data);
	}

	read_file_chunk (task);
}

static void
write_file_chunk (GTask *task)
{
	TaskData *task_data;

	DEBUG ({
	       g_print ("%s\n", G_STRFUNC);
	});

	task_data = g_task_get_task_data (task);

	g_output_stream_write_async (task_data->output_stream,
				     task_data->chunk_buffer + task_data->chunk_bytes_written,
				     task_data->chunk_bytes_read - task_data->chunk_bytes_written,
				     g_task_get_priority (task),
				     g_task_get_cancellable (task),
				     write_file_chunk_cb,
				     task);
}

static void
read_file_chunk (GTask *task)
{
	TaskData *task_data;
	GError *error = NULL;

	DEBUG ({
	       g_print ("%s\n", G_STRFUNC);
	});

	task_data = g_task_get_task_data (task);

	task_data->chunk_bytes_written = 0;

	/* We use sync methods on doc stream since it is in memory. Using async
	 * would be racy and we could end up with invalid iters.
	 */
	task_data->chunk_bytes_read = g_input_stream_read (G_INPUT_STREAM (task_data->input_stream),
							   task_data->chunk_buffer,
							   WRITE_CHUNK_SIZE,
							   g_task_get_cancellable (task),
							   &error);

	if (error != NULL)
	{
		g_clear_error (&task_data->error);
		task_data->error = error;
		cancel_output_stream (task);
		return;
	}

	/* Check if we finished reading and writing. */
	if (task_data->chunk_bytes_read == 0)
	{
		write_complete (task);
		return;
	}

	write_file_chunk (task);
}

static void
replace_file_cb (GObject      *source_object,
		 GAsyncResult *result,
		 gpointer      user_data)
{
	GFile *location = G_FILE (source_object);
	GTask *task = G_TASK (user_data);
	GtkSourceFileSaver *saver;
	TaskData *task_data;
	GFileOutputStream *file_output_stream;
	GOutputStream *output_stream;
	GError *error = NULL;

	DEBUG ({
	       g_print ("%s\n", G_STRFUNC);
	});

	saver = g_task_get_source_object (task);
	task_data = g_task_get_task_data (task);

	file_output_stream = g_file_replace_finish (location, result, &error);

	if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_NOT_MOUNTED) &&
	    !task_data->tried_mount)
	{
		recover_not_mounted (task);
		g_error_free (error);
		return;
	}
	else if (error != NULL)
	{
		DEBUG ({
		       g_print ("Opening file failed: %s\n", error->message);
		});

		g_task_return_error (task, error);
		return;
	}

	if (saver->priv->compression_type == GTK_SOURCE_COMPRESSION_TYPE_GZIP)
	{
		GZlibCompressor *compressor;

		DEBUG ({
		       g_print ("Use gzip compressor\n");
		});

		compressor = g_zlib_compressor_new (G_ZLIB_COMPRESSOR_FORMAT_GZIP, -1);

		output_stream = g_converter_output_stream_new (G_OUTPUT_STREAM (file_output_stream),
							       G_CONVERTER (compressor));

		g_object_unref (compressor);
		g_object_unref (file_output_stream);
	}
	else
	{
		output_stream = G_OUTPUT_STREAM (file_output_stream);
	}

	/* FIXME: manage converter error? */

	DEBUG ({
	       g_print ("Encoding charset: %s\n",
			gtk_source_encoding_get_charset (saver->priv->encoding));
	});

	if (saver->priv->encoding != gtk_source_encoding_get_utf8 ())
	{
		GCharsetConverter *converter;

		converter = g_charset_converter_new (gtk_source_encoding_get_charset (saver->priv->encoding),
						     "UTF-8",
						     NULL);

		g_clear_object (&task_data->output_stream);
		task_data->output_stream = g_converter_output_stream_new (output_stream,
									  G_CONVERTER (converter));

		g_object_unref (converter);
		g_object_unref (output_stream);
	}
	else
	{
		g_clear_object (&task_data->output_stream);
		task_data->output_stream = G_OUTPUT_STREAM (output_stream);
	}

	task_data->total_size = _gtk_source_buffer_input_stream_get_total_size (task_data->input_stream);

	DEBUG ({
	       g_print ("Total number of characters: %" G_GINT64_FORMAT "\n", task_data->total_size);
	});

	read_file_chunk (task);
}

static void
begin_write (GTask *task)
{
	GtkSourceFileSaver *saver;
	gboolean create_backup;

	saver = g_task_get_source_object (task);

	create_backup = (saver->priv->flags & GTK_SOURCE_FILE_SAVER_FLAGS_CREATE_BACKUP) != 0;

	DEBUG ({
	       g_print ("Start replacing file contents\n");
	       g_print ("Make backup: %s\n", create_backup ? "yes" : "no");
	});

	g_file_replace_async (saver->priv->location,
			      NULL,
			      create_backup,
			      G_FILE_CREATE_NONE,
			      g_task_get_priority (task),
			      g_task_get_cancellable (task),
			      replace_file_cb,
			      task);
}

static void
check_externally_modified_cb (GObject      *source_object,
			      GAsyncResult *result,
			      gpointer      user_data)
{
	GFile *location = G_FILE (source_object);
	GTask *task = G_TASK (user_data);
	GtkSourceFileSaver *saver;
	TaskData *task_data;
	GFileInfo *info;
	GTimeVal old_mtime;
	GTimeVal cur_mtime;
	GError *error = NULL;

	DEBUG ({
	       g_print ("%s\n", G_STRFUNC);
	});

	saver = g_task_get_source_object (task);
	task_data = g_task_get_task_data (task);

	info = g_file_query_info_finish (location, result, &error);

	if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_NOT_MOUNTED) &&
	    !task_data->tried_mount)
	{
		recover_not_mounted (task);
		g_error_free (error);
		return;
	}

	/* It's perfectly fine if the file doesn't exist yet. */
	if (g_error_matches (error, G_IO_ERROR, G_IO_ERROR_NOT_FOUND))
	{
		g_clear_error (&error);
	}
	else if (error != NULL)
	{
		DEBUG ({
		       g_print ("Check externally modified failed: %s\n", error->message);
		});

		g_task_return_error (task, error);
		return;
	}

	if (_gtk_source_file_get_modification_time (saver->priv->file, &old_mtime) &&
	    info != NULL &&
	    g_file_info_has_attribute (info, G_FILE_ATTRIBUTE_TIME_MODIFIED))
	{
		g_file_info_get_modification_time (info, &cur_mtime);

		if (old_mtime.tv_sec != cur_mtime.tv_sec ||
		    old_mtime.tv_usec != cur_mtime.tv_usec)
		{
			DEBUG ({
			       g_print ("The file is externally modified\n");
			});

			g_task_return_new_error (task,
						 GTK_SOURCE_FILE_SAVER_ERROR,
						 GTK_SOURCE_FILE_SAVER_ERROR_EXTERNALLY_MODIFIED,
						 _("The file is externally modified."));
			g_object_unref (info);
			return;
		}
	}

	begin_write (task);

	if (info != NULL)
	{
		g_object_unref (info);
	}
}

static void
check_externally_modified (GTask *task)
{
	GtkSourceFileSaver *saver;
	gboolean save_as = FALSE;

	saver = g_task_get_source_object (task);

	if (saver->priv->file != NULL)
	{
		GFile *prev_location;

		prev_location = gtk_source_file_get_location (saver->priv->file);

		/* Don't check for externally modified for a "save as" operation,
		 * because the user has normally accepted to overwrite the file if it
		 * already exists.
		 */
		save_as = (prev_location == NULL ||
			   !g_file_equal (prev_location, saver->priv->location));
	}

	if (saver->priv->flags & GTK_SOURCE_FILE_SAVER_FLAGS_IGNORE_MODIFICATION_TIME ||
	    save_as)
	{
		begin_write (task);
		return;
	}

	DEBUG ({
	       g_print ("Check externally modified\n");
	});

	g_file_query_info_async (saver->priv->location,
			         G_FILE_ATTRIBUTE_TIME_MODIFIED,
			         G_FILE_QUERY_INFO_NONE,
				 g_task_get_priority (task),
				 g_task_get_cancellable (task),
			         check_externally_modified_cb,
			         task);
}

static void
mount_cb (GObject      *source_object,
	  GAsyncResult *result,
	  gpointer      user_data)
{
	GFile *location = G_FILE (source_object);
	GTask *task = G_TASK (user_data);
	GError *error = NULL;

	DEBUG ({
	       g_print ("%s\n", G_STRFUNC);
	});

	g_file_mount_enclosing_volume_finish (location, result, &error);

	if (error != NULL)
	{
		g_task_return_error (task, error);
		return;
	}

	check_externally_modified (task);
}

static void
recover_not_mounted (GTask *task)
{
	GtkSourceFileSaver *saver;
	TaskData *task_data;
	GMountOperation *mount_operation;

	saver = g_task_get_source_object (task);
	task_data = g_task_get_task_data (task);

	mount_operation = _gtk_source_file_create_mount_operation (saver->priv->file);

	DEBUG ({
	       g_print ("%s\n", G_STRFUNC);
	});

	task_data->tried_mount = TRUE;

	g_file_mount_enclosing_volume (saver->priv->location,
				       G_MOUNT_MOUNT_NONE,
				       mount_operation,
				       g_task_get_cancellable (task),
				       mount_cb,
				       task);

	g_object_unref (mount_operation);
}

GQuark
gtk_source_file_saver_error_quark (void)
{
	static GQuark quark = 0;

	if (G_UNLIKELY (quark == 0))
	{
		quark = g_quark_from_static_string ("gtk-source-file-saver-error");
	}

	return quark;
}

/**
 * gtk_source_file_saver_new:
 * @buffer: the #GtkSourceBuffer to save.
 * @file: the #GtkSourceFile.
 *
 * Creates a new #GtkSourceFileSaver object. The @buffer will be saved to the
 * #GtkSourceFile's location.
 *
 * This constructor is suitable for a simple "save" operation, when the @file
 * already contains a non-%NULL #GtkSourceFile:location.
 *
 * Returns: a new #GtkSourceFileSaver object.
 * Since: 3.14
 */
GtkSourceFileSaver *
gtk_source_file_saver_new (GtkSourceBuffer *buffer,
			   GtkSourceFile   *file)
{
	g_return_val_if_fail (GTK_SOURCE_IS_BUFFER (buffer), NULL);
	g_return_val_if_fail (GTK_SOURCE_IS_FILE (file), NULL);

	return g_object_new (GTK_SOURCE_TYPE_FILE_SAVER,
			     "buffer", buffer,
			     "file", file,
			     NULL);
}

/**
 * gtk_source_file_saver_new_with_target:
 * @buffer: the #GtkSourceBuffer to save.
 * @file: the #GtkSourceFile.
 * @target_location: the #GFile where to save the buffer to.
 *
 * Creates a new #GtkSourceFileSaver object with a target location. When the
 * file saving is finished successfully, @target_location is set to the @file's
 * #GtkSourceFile:location property. If an error occurs, the previous valid
 * location is still available in #GtkSourceFile.
 *
 * This constructor is suitable for a "save as" operation, or for saving a new
 * buffer for the first time.
 *
 * Returns: a new #GtkSourceFileSaver object.
 * Since: 3.14
 */
GtkSourceFileSaver *
gtk_source_file_saver_new_with_target (GtkSourceBuffer *buffer,
				       GtkSourceFile   *file,
				       GFile           *target_location)
{
	g_return_val_if_fail (GTK_SOURCE_IS_BUFFER (buffer), NULL);
	g_return_val_if_fail (GTK_SOURCE_IS_FILE (file), NULL);
	g_return_val_if_fail (G_IS_FILE (target_location), NULL);

	return g_object_new (GTK_SOURCE_TYPE_FILE_SAVER,
			     "buffer", buffer,
			     "file", file,
			     "location", target_location,
			     NULL);
}

/**
 * gtk_source_file_saver_get_buffer:
 * @saver: a #GtkSourceFileSaver.
 *
 * Returns: (transfer none): the #GtkSourceBuffer to save.
 * Since: 3.14
 */
GtkSourceBuffer *
gtk_source_file_saver_get_buffer (GtkSourceFileSaver *saver)
{
	g_return_val_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver), NULL);

	return saver->priv->source_buffer;
}

/**
 * gtk_source_file_saver_get_file:
 * @saver: a #GtkSourceFileSaver.
 *
 * Returns: (transfer none): the #GtkSourceFile.
 * Since: 3.14
 */
GtkSourceFile *
gtk_source_file_saver_get_file (GtkSourceFileSaver *saver)
{
	g_return_val_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver), NULL);

	return saver->priv->file;
}

/**
 * gtk_source_file_saver_get_location:
 * @saver: a #GtkSourceFileSaver.
 *
 * Returns: (transfer none): the #GFile where to save the buffer to.
 * Since: 3.14
 */
GFile *
gtk_source_file_saver_get_location (GtkSourceFileSaver *saver)
{
	g_return_val_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver), NULL);

	return saver->priv->location;
}

/**
 * gtk_source_file_saver_set_encoding:
 * @saver: a #GtkSourceFileSaver.
 * @encoding: (nullable): the new encoding, or %NULL for UTF-8.
 *
 * Sets the encoding. If @encoding is %NULL, the UTF-8 encoding will be set.
 * By default the encoding is taken from the #GtkSourceFile.
 *
 * Since: 3.14
 */
void
gtk_source_file_saver_set_encoding (GtkSourceFileSaver      *saver,
				    const GtkSourceEncoding *encoding)
{
	g_return_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver));
	g_return_if_fail (saver->priv->task == NULL);

	if (encoding == NULL)
	{
		encoding = gtk_source_encoding_get_utf8 ();
	}

	if (saver->priv->encoding != encoding)
	{
		saver->priv->encoding = encoding;
		g_object_notify (G_OBJECT (saver), "encoding");
	}
}

/**
 * gtk_source_file_saver_get_encoding:
 * @saver: a #GtkSourceFileSaver.
 *
 * Returns: the encoding.
 * Since: 3.14
 */
const GtkSourceEncoding *
gtk_source_file_saver_get_encoding (GtkSourceFileSaver *saver)
{
	g_return_val_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver), NULL);

	return saver->priv->encoding;
}

/**
 * gtk_source_file_saver_set_newline_type:
 * @saver: a #GtkSourceFileSaver.
 * @newline_type: the new newline type.
 *
 * Sets the newline type. By default the newline type is taken from the
 * #GtkSourceFile.
 *
 * Since: 3.14
 */
void
gtk_source_file_saver_set_newline_type (GtkSourceFileSaver   *saver,
					GtkSourceNewlineType  newline_type)
{
	g_return_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver));
	g_return_if_fail (saver->priv->task == NULL);

	if (saver->priv->newline_type != newline_type)
	{
		saver->priv->newline_type = newline_type;
		g_object_notify (G_OBJECT (saver), "newline-type");
	}
}

/**
 * gtk_source_file_saver_get_newline_type:
 * @saver: a #GtkSourceFileSaver.
 *
 * Returns: the newline type.
 * Since: 3.14
 */
GtkSourceNewlineType
gtk_source_file_saver_get_newline_type (GtkSourceFileSaver *saver)
{
	g_return_val_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver), GTK_SOURCE_NEWLINE_TYPE_DEFAULT);

	return saver->priv->newline_type;
}

/**
 * gtk_source_file_saver_set_compression_type:
 * @saver: a #GtkSourceFileSaver.
 * @compression_type: the new compression type.
 *
 * Sets the compression type. By default the compression type is taken from the
 * #GtkSourceFile.
 *
 * Since: 3.14
 */
void
gtk_source_file_saver_set_compression_type (GtkSourceFileSaver       *saver,
					    GtkSourceCompressionType  compression_type)
{
	g_return_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver));
	g_return_if_fail (saver->priv->task == NULL);

	if (saver->priv->compression_type != compression_type)
	{
		saver->priv->compression_type = compression_type;
		g_object_notify (G_OBJECT (saver), "compression-type");
	}
}

/**
 * gtk_source_file_saver_get_compression_type:
 * @saver: a #GtkSourceFileSaver.
 *
 * Returns: the compression type.
 * Since: 3.14
 */
GtkSourceCompressionType
gtk_source_file_saver_get_compression_type (GtkSourceFileSaver *saver)
{
	g_return_val_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver), GTK_SOURCE_COMPRESSION_TYPE_NONE);

	return saver->priv->compression_type;
}

/**
 * gtk_source_file_saver_set_flags:
 * @saver: a #GtkSourceFileSaver.
 * @flags: the new flags.
 *
 * Since: 3.14
 */
void
gtk_source_file_saver_set_flags (GtkSourceFileSaver      *saver,
				 GtkSourceFileSaverFlags  flags)
{
	g_return_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver));
	g_return_if_fail (saver->priv->task == NULL);

	if (saver->priv->flags != flags)
	{
		saver->priv->flags = flags;
		g_object_notify (G_OBJECT (saver), "flags");
	}
}

/**
 * gtk_source_file_saver_get_flags:
 * @saver: a #GtkSourceFileSaver.
 *
 * Returns: the flags.
 * Since: 3.14
 */
GtkSourceFileSaverFlags
gtk_source_file_saver_get_flags (GtkSourceFileSaver *saver)
{
	g_return_val_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver), GTK_SOURCE_FILE_SAVER_FLAGS_NONE);

	return saver->priv->flags;
}

/**
 * gtk_source_file_saver_save_async:
 * @saver: a #GtkSourceFileSaver.
 * @io_priority: the I/O priority of the request. E.g. %G_PRIORITY_LOW,
 *   %G_PRIORITY_DEFAULT or %G_PRIORITY_HIGH.
 * @cancellable: (nullable): optional #GCancellable object, %NULL to ignore.
 * @progress_callback: (scope notified) (nullable): function to call back with
 *   progress information, or %NULL if progress information is not needed.
 * @progress_callback_data: (closure): user data to pass to @progress_callback.
 * @progress_callback_notify: (nullable): function to call on
 *   @progress_callback_data when the @progress_callback is no longer needed, or
 *   %NULL.
 * @callback: (scope async): a #GAsyncReadyCallback to call when the request is
 *   satisfied.
 * @user_data: user data to pass to @callback.
 *
 * Saves asynchronously the buffer into the file. See the #GAsyncResult
 * documentation to know how to use this function.
 *
 * Since: 3.14
 */

/* The GDestroyNotify is needed, currently the following bug is not fixed:
 * https://bugzilla.gnome.org/show_bug.cgi?id=616044
 */
void
gtk_source_file_saver_save_async (GtkSourceFileSaver     *saver,
				  gint                    io_priority,
				  GCancellable           *cancellable,
				  GFileProgressCallback   progress_callback,
				  gpointer                progress_callback_data,
				  GDestroyNotify          progress_callback_notify,
				  GAsyncReadyCallback     callback,
				  gpointer                user_data)
{
	TaskData *task_data;
	gboolean check_invalid_chars;
	gboolean implicit_trailing_newline;

	g_return_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver));
	g_return_if_fail (cancellable == NULL || G_IS_CANCELLABLE (cancellable));
	g_return_if_fail (saver->priv->task == NULL);

	saver->priv->task = g_task_new (saver, cancellable, callback, user_data);
	g_task_set_priority (saver->priv->task, io_priority);

	task_data = task_data_new ();
	g_task_set_task_data (saver->priv->task, task_data, task_data_free);

	task_data->progress_cb = progress_callback;
	task_data->progress_cb_data = progress_callback_data;
	task_data->progress_cb_notify = progress_callback_notify;

	if (saver->priv->source_buffer == NULL ||
	    saver->priv->file == NULL ||
	    saver->priv->location == NULL)
	{
		g_task_return_boolean (saver->priv->task, FALSE);
		return;
	}

	check_invalid_chars = (saver->priv->flags & GTK_SOURCE_FILE_SAVER_FLAGS_IGNORE_INVALID_CHARS) == 0;

	if (check_invalid_chars && _gtk_source_buffer_has_invalid_chars (saver->priv->source_buffer))
	{
		g_task_return_new_error (saver->priv->task,
					 GTK_SOURCE_FILE_SAVER_ERROR,
					 GTK_SOURCE_FILE_SAVER_ERROR_INVALID_CHARS,
					 _("The buffer contains invalid characters."));
		return;
	}

	DEBUG ({
	       g_print ("Start saving\n");
	});

	implicit_trailing_newline = gtk_source_buffer_get_implicit_trailing_newline (saver->priv->source_buffer);

	/* The BufferInputStream has a strong reference to the buffer.
	 * We create the BufferInputStream here so we are sure that the
	 * buffer will not be destroyed during the file saving.
	 */
	task_data->input_stream = _gtk_source_buffer_input_stream_new (GTK_TEXT_BUFFER (saver->priv->source_buffer),
								       saver->priv->newline_type,
								       implicit_trailing_newline);

	check_externally_modified (saver->priv->task);
}

/**
 * gtk_source_file_saver_save_finish:
 * @saver: a #GtkSourceFileSaver.
 * @result: a #GAsyncResult.
 * @error: a #GError, or %NULL.
 *
 * Finishes a file saving started with gtk_source_file_saver_save_async().
 *
 * If the file has been saved successfully, the following #GtkSourceFile
 * properties will be updated: the location, the encoding, the newline type and
 * the compression type.
 *
 * Since the 3.20 version, gtk_text_buffer_set_modified() is called with %FALSE
 * if the file has been saved successfully.
 *
 * Returns: whether the file was saved successfully.
 * Since: 3.14
 */
gboolean
gtk_source_file_saver_save_finish (GtkSourceFileSaver  *saver,
				   GAsyncResult        *result,
				   GError             **error)
{
	gboolean ok;

	g_return_val_if_fail (GTK_SOURCE_IS_FILE_SAVER (saver), FALSE);
	g_return_val_if_fail (error == NULL || *error == NULL, FALSE);
	g_return_val_if_fail (g_task_is_valid (result, saver), FALSE);

	ok = g_task_propagate_boolean (G_TASK (result), error);

	if (ok && saver->priv->file != NULL)
	{
		TaskData *task_data;

		gtk_source_file_set_location (saver->priv->file,
					      saver->priv->location);

		_gtk_source_file_set_encoding (saver->priv->file,
					       saver->priv->encoding);

		_gtk_source_file_set_newline_type (saver->priv->file,
						   saver->priv->newline_type);

		_gtk_source_file_set_compression_type (saver->priv->file,
						       saver->priv->compression_type);

		_gtk_source_file_set_externally_modified (saver->priv->file, FALSE);
		_gtk_source_file_set_deleted (saver->priv->file, FALSE);
		_gtk_source_file_set_readonly (saver->priv->file, FALSE);

		task_data = g_task_get_task_data (G_TASK (result));

		if (g_file_info_has_attribute (task_data->info, G_FILE_ATTRIBUTE_TIME_MODIFIED))
		{
			GTimeVal modification_time;

			g_file_info_get_modification_time (task_data->info, &modification_time);
			_gtk_source_file_set_modification_time (saver->priv->file, modification_time);
		}
	}

	if (ok && saver->priv->source_buffer != NULL)
	{
		gtk_text_buffer_set_modified (GTK_TEXT_BUFFER (saver->priv->source_buffer),
					      FALSE);
	}

	g_clear_object (&saver->priv->task);

	return ok;
}
