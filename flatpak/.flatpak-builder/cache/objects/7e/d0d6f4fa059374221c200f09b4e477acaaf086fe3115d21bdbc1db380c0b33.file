/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcemarkssequence.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2013 - Sébastien Wilmet <swilmet@gnome.org>
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

#include "gtksourcemarkssequence.h"

/* An object for storing GtkTextMarks. The text marks are sorted internally with
 * a GSequence. Going to the previous or next text mark has a O(1) complexity.
 * Finding a text mark in the neighborhood of a text iter has a O(log n)
 * complexity, with 'n' the number of marks in the sequence.
 *
 * The GSequenceIter associated to a text mark is inserted into the text mark,
 * with g_object_set_qdata(). So the text mark knows its position in the
 * GSequence. This allows to use normal GtkTextMarks in the API, instead of
 * using a subclass or a custom iter.
 *
 * The MarksSequence has a weak reference to the text buffer.
 */

enum
{
	PROP_0,
	PROP_BUFFER,
};

struct _GtkSourceMarksSequencePrivate
{
	GtkTextBuffer *buffer;
	GSequence *seq;

	/* The quark used for storing the GSequenceIter into the text mark, with
	 * g_object_set_qdata().
	 */
	GQuark quark;
};

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceMarksSequence, _gtk_source_marks_sequence, G_TYPE_OBJECT)

static void
remove_qdata (GtkTextMark            *mark,
	      GtkSourceMarksSequence *seq)
{
	g_object_set_qdata (G_OBJECT (mark),
			    seq->priv->quark,
			    NULL);
}

static void
free_sequence (GtkSourceMarksSequence *seq)
{
	if (seq->priv->seq != NULL)
	{
		g_sequence_foreach (seq->priv->seq,
				    (GFunc)remove_qdata,
				    seq);

		g_sequence_free (seq->priv->seq);
		seq->priv->seq = NULL;
	}
}

static gint
compare_marks (GtkTextMark *mark1,
	       GtkTextMark *mark2)
{
	GtkTextBuffer *buffer;
	GtkTextIter iter1;
	GtkTextIter iter2;

	g_assert (GTK_IS_TEXT_MARK (mark1));
	g_assert (GTK_IS_TEXT_MARK (mark2));

	buffer = gtk_text_mark_get_buffer (mark1);

	g_assert (buffer == gtk_text_mark_get_buffer (mark2));

	gtk_text_buffer_get_iter_at_mark (buffer, &iter1, mark1);
	gtk_text_buffer_get_iter_at_mark (buffer, &iter2, mark2);

	return gtk_text_iter_compare (&iter1, &iter2);
}

static void
mark_set_cb (GtkTextBuffer          *buffer,
	     GtkTextIter            *location,
	     GtkTextMark            *mark,
	     GtkSourceMarksSequence *seq)
{
	GSequenceIter *seq_iter;

	seq_iter = g_object_get_qdata (G_OBJECT (mark), seq->priv->quark);

	if (seq_iter != NULL)
	{
		g_sequence_sort_changed (seq_iter,
					 (GCompareDataFunc)compare_marks,
					 NULL);
	}
}

static void
mark_deleted_cb (GtkTextBuffer          *buffer,
		 GtkTextMark            *mark,
		 GtkSourceMarksSequence *seq)
{
	_gtk_source_marks_sequence_remove (seq, mark);
}

static void
set_buffer (GtkSourceMarksSequence *seq,
	    GtkTextBuffer          *buffer)
{
	g_assert (seq->priv->buffer == NULL);

	seq->priv->buffer = buffer;

	g_object_add_weak_pointer (G_OBJECT (buffer),
				   (gpointer *)&seq->priv->buffer);

	g_signal_connect_object (buffer,
				 "mark-set",
				 G_CALLBACK (mark_set_cb),
				 seq,
				 0);

	g_signal_connect_object (buffer,
				 "mark-deleted",
				 G_CALLBACK (mark_deleted_cb),
				 seq,
				 0);
}

static void
_gtk_source_marks_sequence_dispose (GObject *object)
{
	GtkSourceMarksSequence *seq = GTK_SOURCE_MARKS_SEQUENCE (object);

	if (seq->priv->buffer != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (seq->priv->buffer),
					      (gpointer *)&seq->priv->buffer);

		seq->priv->buffer = NULL;
	}

	free_sequence (seq);

	G_OBJECT_CLASS (_gtk_source_marks_sequence_parent_class)->dispose (object);
}

static void
_gtk_source_marks_sequence_get_property (GObject    *object,
					 guint       prop_id,
					 GValue     *value,
					 GParamSpec *pspec)
{
	GtkSourceMarksSequence *seq;

	g_return_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (object));

	seq = GTK_SOURCE_MARKS_SEQUENCE (object);

	switch (prop_id)
	{
		case PROP_BUFFER:
			g_value_set_object (value, seq->priv->buffer);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
_gtk_source_marks_sequence_set_property (GObject      *object,
					 guint         prop_id,
					 const GValue *value,
					 GParamSpec   *pspec)
{
	GtkSourceMarksSequence *seq;

	g_return_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (object));

	seq = GTK_SOURCE_MARKS_SEQUENCE (object);

	switch (prop_id)
	{
		case PROP_BUFFER:
			set_buffer (seq, g_value_get_object (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
_gtk_source_marks_sequence_class_init (GtkSourceMarksSequenceClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->dispose = _gtk_source_marks_sequence_dispose;
	object_class->get_property = _gtk_source_marks_sequence_get_property;
	object_class->set_property = _gtk_source_marks_sequence_set_property;

	g_object_class_install_property (object_class,
					 PROP_BUFFER,
					 g_param_spec_object ("buffer",
							      "Buffer",
							      "The text buffer",
							      GTK_TYPE_TEXT_BUFFER,
							      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT_ONLY |
							      G_PARAM_STATIC_STRINGS));
}

static void
_gtk_source_marks_sequence_init (GtkSourceMarksSequence *seq)
{
	gchar *unique_str;

	seq->priv = _gtk_source_marks_sequence_get_instance_private (seq);

	seq->priv->seq = g_sequence_new ((GDestroyNotify)g_object_unref);

	unique_str = g_strdup_printf ("gtk-source-marks-sequence-%p", seq);
	seq->priv->quark = g_quark_from_string (unique_str);
	g_free (unique_str);
}

GtkSourceMarksSequence *
_gtk_source_marks_sequence_new (GtkTextBuffer *buffer)
{
	g_return_val_if_fail (GTK_IS_TEXT_BUFFER (buffer), NULL);

	return g_object_new (GTK_SOURCE_TYPE_MARKS_SEQUENCE,
			     "buffer", buffer,
			     NULL);
}

gboolean
_gtk_source_marks_sequence_is_empty (GtkSourceMarksSequence *seq)
{
	g_return_val_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (seq), TRUE);

	return g_sequence_is_empty (seq->priv->seq);
}

void
_gtk_source_marks_sequence_add (GtkSourceMarksSequence *seq,
				GtkTextMark            *mark)
{
	GSequenceIter *seq_iter;

	g_return_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (seq));
	g_return_if_fail (GTK_IS_TEXT_MARK (mark));
	g_return_if_fail (gtk_text_mark_get_buffer (mark) == seq->priv->buffer);

	seq_iter = g_object_get_qdata (G_OBJECT (mark), seq->priv->quark);

	if (seq_iter != NULL)
	{
		/* The mark is already added. */
		return;
	}

	seq_iter = g_sequence_insert_sorted (seq->priv->seq,
					     mark,
					     (GCompareDataFunc)compare_marks,
					     NULL);

	g_object_ref (mark);
	g_object_set_qdata (G_OBJECT (mark),
			    seq->priv->quark,
			    seq_iter);
}

void
_gtk_source_marks_sequence_remove (GtkSourceMarksSequence *seq,
				   GtkTextMark            *mark)
{
	GSequenceIter *seq_iter;

	g_return_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (seq));
	g_return_if_fail (GTK_IS_TEXT_MARK (mark));

	seq_iter = g_object_get_qdata (G_OBJECT (mark), seq->priv->quark);

	if (seq_iter != NULL)
	{
		g_object_set_qdata (G_OBJECT (mark), seq->priv->quark, NULL);
		g_sequence_remove (seq_iter);
	}
}

GtkTextMark *
_gtk_source_marks_sequence_next (GtkSourceMarksSequence *seq,
				 GtkTextMark            *mark)
{
	GSequenceIter *seq_iter;

	g_return_val_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (seq), NULL);
	g_return_val_if_fail (GTK_IS_TEXT_MARK (mark), NULL);
	g_return_val_if_fail (gtk_text_mark_get_buffer (mark) == seq->priv->buffer, NULL);

	seq_iter = g_object_get_qdata (G_OBJECT (mark), seq->priv->quark);

	g_return_val_if_fail (seq_iter != NULL, NULL);

	seq_iter = g_sequence_iter_next (seq_iter);

	return g_sequence_iter_is_end (seq_iter) ? NULL : g_sequence_get (seq_iter);
}

GtkTextMark *
_gtk_source_marks_sequence_prev (GtkSourceMarksSequence *seq,
				 GtkTextMark            *mark)
{
	GSequenceIter *seq_iter;

	g_return_val_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (seq), NULL);
	g_return_val_if_fail (GTK_IS_TEXT_MARK (mark), NULL);
	g_return_val_if_fail (gtk_text_mark_get_buffer (mark) == seq->priv->buffer, NULL);

	seq_iter = g_object_get_qdata (G_OBJECT (mark), seq->priv->quark);

	g_return_val_if_fail (seq_iter != NULL, NULL);

	if (g_sequence_iter_is_begin (seq_iter))
	{
		return NULL;
	}

	seq_iter = g_sequence_iter_prev (seq_iter);

	return g_sequence_get (seq_iter);
}

/* Moves @iter forward to the next position where there is at least one mark.
 * Returns %TRUE if @iter was moved.
 */
gboolean
_gtk_source_marks_sequence_forward_iter (GtkSourceMarksSequence *seq,
					 GtkTextIter            *iter)
{
	GtkTextMark *mark;
	GSequenceIter *seq_iter;

	g_return_val_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (seq), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (gtk_text_iter_get_buffer (iter) == seq->priv->buffer, FALSE);

	mark = gtk_text_buffer_create_mark (seq->priv->buffer,
					    NULL,
					    iter,
					    TRUE);

	seq_iter = g_sequence_search (seq->priv->seq,
				      mark,
				      (GCompareDataFunc)compare_marks,
				      NULL);

	gtk_text_buffer_delete_mark (seq->priv->buffer, mark);

	while (!g_sequence_iter_is_end (seq_iter))
	{
		GtkTextMark *cur_mark = g_sequence_get (seq_iter);
		GtkTextIter cur_iter;

		gtk_text_buffer_get_iter_at_mark (seq->priv->buffer, &cur_iter, cur_mark);

		if (gtk_text_iter_compare (iter, &cur_iter) < 0)
		{
			*iter = cur_iter;
			return TRUE;
		}

		seq_iter = g_sequence_iter_next (seq_iter);
	}

	return FALSE;
}

/* Moves @iter backward to the previous position where there is at least one
 * mark. Returns %TRUE if @iter was moved.
 */
gboolean
_gtk_source_marks_sequence_backward_iter (GtkSourceMarksSequence *seq,
					  GtkTextIter            *iter)
{
	GtkTextMark *mark;
	GSequenceIter *seq_iter;

	g_return_val_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (seq), FALSE);
	g_return_val_if_fail (iter != NULL, FALSE);
	g_return_val_if_fail (gtk_text_iter_get_buffer (iter) == seq->priv->buffer, FALSE);

	mark = gtk_text_buffer_create_mark (seq->priv->buffer,
					    NULL,
					    iter,
					    TRUE);

	seq_iter = g_sequence_search (seq->priv->seq,
				      mark,
				      (GCompareDataFunc)compare_marks,
				      NULL);

	gtk_text_buffer_delete_mark (seq->priv->buffer, mark);

	if (g_sequence_iter_is_end (seq_iter))
	{
		seq_iter = g_sequence_iter_prev (seq_iter);
	}

	if (g_sequence_iter_is_end (seq_iter))
	{
		/* The sequence is empty. */
		return FALSE;
	}

	while (TRUE)
	{
		GtkTextMark *cur_mark;
		GtkTextIter cur_iter;

		cur_mark = g_sequence_get (seq_iter);

		gtk_text_buffer_get_iter_at_mark (seq->priv->buffer, &cur_iter, cur_mark);

		if (gtk_text_iter_compare (&cur_iter, iter) < 0)
		{
			*iter = cur_iter;
			return TRUE;
		}

		if (g_sequence_iter_is_begin (seq_iter))
		{
			break;
		}

		seq_iter = g_sequence_iter_prev (seq_iter);
	}

	return FALSE;
}

GSList *
_gtk_source_marks_sequence_get_marks_in_range (GtkSourceMarksSequence *seq,
					       const GtkTextIter      *iter1,
					       const GtkTextIter      *iter2)
{
	GtkTextIter start;
	GtkTextIter end;
	GtkTextMark *mark_start;
	GSequenceIter *seq_iter;
	GSequenceIter *first_seq_iter = NULL;
	GSList *ret = NULL;

	g_return_val_if_fail (GTK_SOURCE_IS_MARKS_SEQUENCE (seq), NULL);
	g_return_val_if_fail (iter1 != NULL, NULL);
	g_return_val_if_fail (iter2 != NULL, NULL);
	g_return_val_if_fail (gtk_text_iter_get_buffer (iter1) == seq->priv->buffer, NULL);
	g_return_val_if_fail (gtk_text_iter_get_buffer (iter2) == seq->priv->buffer, NULL);

	start = *iter1;
	end = *iter2;

	gtk_text_iter_order (&start, &end);

	mark_start = gtk_text_buffer_create_mark (seq->priv->buffer,
						  NULL,
						  &start,
						  TRUE);

	seq_iter = g_sequence_search (seq->priv->seq,
				      mark_start,
				      (GCompareDataFunc)compare_marks,
				      NULL);

	gtk_text_buffer_delete_mark (seq->priv->buffer, mark_start);

	if (g_sequence_iter_is_end (seq_iter))
	{
		seq_iter = g_sequence_iter_prev (seq_iter);
	}

	if (g_sequence_iter_is_end (seq_iter))
	{
		/* The sequence is empty. */
		return NULL;
	}

	/* Find the first mark */

	while (TRUE)
	{
		GtkTextMark *cur_mark;
		GtkTextIter cur_iter;

		cur_mark = g_sequence_get (seq_iter);
		gtk_text_buffer_get_iter_at_mark (seq->priv->buffer, &cur_iter, cur_mark);

		if (gtk_text_iter_compare (&cur_iter, &start) < 0)
		{
			break;
		}

		first_seq_iter = seq_iter;

		if (g_sequence_iter_is_begin (seq_iter))
		{
			break;
		}

		seq_iter = g_sequence_iter_prev (seq_iter);
	}

	if (first_seq_iter == NULL)
	{
		/* The last mark in the sequence is before @start. */
		return NULL;
	}

	/* Go forward until @end to fill the list of marks */

	for (seq_iter = first_seq_iter;
	     !g_sequence_iter_is_end (seq_iter);
	     seq_iter = g_sequence_iter_next (seq_iter))
	{
		GtkTextMark *cur_mark;
		GtkTextIter cur_iter;

		cur_mark = g_sequence_get (seq_iter);
		gtk_text_buffer_get_iter_at_mark (seq->priv->buffer, &cur_iter, cur_mark);

		if (gtk_text_iter_compare (&end, &cur_iter) < 0)
		{
			break;
		}

		ret = g_slist_prepend (ret, cur_mark);
	}

	return ret;
}

GSList *
_gtk_source_marks_sequence_get_marks_at_iter (GtkSourceMarksSequence *seq,
					      const GtkTextIter      *iter)
{
	return _gtk_source_marks_sequence_get_marks_in_range (seq, iter, iter);
}
