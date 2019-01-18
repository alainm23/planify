/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourcemarkssequence.h
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

#ifndef GTK_SOURCE_MARKS_SEQUENCE_H
#define GTK_SOURCE_MARKS_SEQUENCE_H

#include <gtk/gtk.h>
#include "gtksourcetypes-private.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_MARKS_SEQUENCE             (_gtk_source_marks_sequence_get_type ())
#define GTK_SOURCE_MARKS_SEQUENCE(obj)             (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_MARKS_SEQUENCE, GtkSourceMarksSequence))
#define GTK_SOURCE_MARKS_SEQUENCE_CLASS(klass)     (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_MARKS_SEQUENCE, GtkSourceMarksSequenceClass))
#define GTK_SOURCE_IS_MARKS_SEQUENCE(obj)          (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_MARKS_SEQUENCE))
#define GTK_SOURCE_IS_MARKS_SEQUENCE_CLASS(klass)  (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_MARKS_SEQUENCE))
#define GTK_SOURCE_MARKS_SEQUENCE_GET_CLASS(obj)   (G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_MARKS_SEQUENCE, GtkSourceMarksSequenceClass))

typedef struct _GtkSourceMarksSequenceClass    GtkSourceMarksSequenceClass;
typedef struct _GtkSourceMarksSequencePrivate  GtkSourceMarksSequencePrivate;

struct _GtkSourceMarksSequence
{
	GObject parent;

	GtkSourceMarksSequencePrivate *priv;
};

struct _GtkSourceMarksSequenceClass
{
	GObjectClass parent_class;
};

G_GNUC_INTERNAL
GType			 _gtk_source_marks_sequence_get_type		(void) G_GNUC_CONST;

G_GNUC_INTERNAL
GtkSourceMarksSequence	*_gtk_source_marks_sequence_new			(GtkTextBuffer          *buffer);

G_GNUC_INTERNAL
gboolean		 _gtk_source_marks_sequence_is_empty		(GtkSourceMarksSequence *seq);

G_GNUC_INTERNAL
void			 _gtk_source_marks_sequence_add			(GtkSourceMarksSequence *seq,
									 GtkTextMark            *mark);

G_GNUC_INTERNAL
void			 _gtk_source_marks_sequence_remove		(GtkSourceMarksSequence *seq,
									 GtkTextMark            *mark);

G_GNUC_INTERNAL
GtkTextMark		*_gtk_source_marks_sequence_next		(GtkSourceMarksSequence *seq,
									 GtkTextMark            *mark);

G_GNUC_INTERNAL
GtkTextMark		*_gtk_source_marks_sequence_prev		(GtkSourceMarksSequence *seq,
									 GtkTextMark            *mark);

G_GNUC_INTERNAL
gboolean		 _gtk_source_marks_sequence_forward_iter	(GtkSourceMarksSequence *seq,
									 GtkTextIter            *iter);

G_GNUC_INTERNAL
gboolean		 _gtk_source_marks_sequence_backward_iter	(GtkSourceMarksSequence *seq,
									 GtkTextIter            *iter);

G_GNUC_INTERNAL
GSList			*_gtk_source_marks_sequence_get_marks_at_iter	(GtkSourceMarksSequence *seq,
									 const GtkTextIter      *iter);

G_GNUC_INTERNAL
GSList			*_gtk_source_marks_sequence_get_marks_in_range	(GtkSourceMarksSequence *seq,
									 const GtkTextIter      *iter1,
									 const GtkTextIter      *iter2);

G_END_DECLS

#endif /* GTK_SOURCE_MARKS_SEQUENCE_H */
