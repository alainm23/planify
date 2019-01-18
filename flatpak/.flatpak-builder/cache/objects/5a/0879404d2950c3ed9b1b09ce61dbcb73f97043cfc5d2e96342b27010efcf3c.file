/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionwordslibrary.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom
 *
 * gtksourceview is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * gtksourceview is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifndef GTK_SOURCE_COMPLETION_WORDS_LIBRARY_H
#define GTK_SOURCE_COMPLETION_WORDS_LIBRARY_H

#include <glib-object.h>
#include "gtksourcecompletionwordsproposal.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_COMPLETION_WORDS_LIBRARY			(gtk_source_completion_words_library_get_type ())
#define GTK_SOURCE_COMPLETION_WORDS_LIBRARY(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_LIBRARY, GtkSourceCompletionWordsLibrary))
#define GTK_SOURCE_COMPLETION_WORDS_LIBRARY_CONST(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_LIBRARY, GtkSourceCompletionWordsLibrary const))
#define GTK_SOURCE_COMPLETION_WORDS_LIBRARY_CLASS(klass)		(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_COMPLETION_WORDS_LIBRARY, GtkSourceCompletionWordsLibraryClass))
#define GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY(obj)			(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_LIBRARY))
#define GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY_CLASS(klass)		(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_COMPLETION_WORDS_LIBRARY))
#define GTK_SOURCE_COMPLETION_WORDS_LIBRARY_GET_CLASS(obj)		(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_LIBRARY, GtkSourceCompletionWordsLibraryClass))

typedef struct _GtkSourceCompletionWordsLibrary			GtkSourceCompletionWordsLibrary;
typedef struct _GtkSourceCompletionWordsLibraryClass		GtkSourceCompletionWordsLibraryClass;
typedef struct _GtkSourceCompletionWordsLibraryPrivate		GtkSourceCompletionWordsLibraryPrivate;

struct _GtkSourceCompletionWordsLibrary {
	GObject parent;

	GtkSourceCompletionWordsLibraryPrivate *priv;
};

struct _GtkSourceCompletionWordsLibraryClass {
	GObjectClass parent_class;
};

GTK_SOURCE_INTERNAL
GType		 gtk_source_completion_words_library_get_type		(void) G_GNUC_CONST;

GTK_SOURCE_INTERNAL
GtkSourceCompletionWordsLibrary *
		 gtk_source_completion_words_library_new		(void);

/* Finding */
GTK_SOURCE_INTERNAL
GSequenceIter	*gtk_source_completion_words_library_find 		(GtkSourceCompletionWordsLibrary  *library,
									 GtkSourceCompletionWordsProposal *proposal);

GTK_SOURCE_INTERNAL
GSequenceIter	*gtk_source_completion_words_library_find_first		(GtkSourceCompletionWordsLibrary  *library,
									 const gchar                      *word,
									 gint                              len);

GTK_SOURCE_INTERNAL
GSequenceIter	*gtk_source_completion_words_library_find_next		(GSequenceIter                    *iter,
									 const gchar                      *word,
									 gint                              len);

/* Getting */
GTK_SOURCE_INTERNAL
GtkSourceCompletionWordsProposal *
		 gtk_source_completion_words_library_get_proposal 	(GSequenceIter                    *iter);

/* Adding/removing */
GTK_SOURCE_INTERNAL
GtkSourceCompletionWordsProposal *
		 gtk_source_completion_words_library_add_word 		(GtkSourceCompletionWordsLibrary  *library,
                                              				 const gchar                      *word);

GTK_SOURCE_INTERNAL
void		 gtk_source_completion_words_library_remove_word 	(GtkSourceCompletionWordsLibrary  *library,
                                                 			 GtkSourceCompletionWordsProposal *proposal);

GTK_SOURCE_INTERNAL
gboolean	 gtk_source_completion_words_library_is_locked 		(GtkSourceCompletionWordsLibrary  *library);

GTK_SOURCE_INTERNAL
void		 gtk_source_completion_words_library_lock 		(GtkSourceCompletionWordsLibrary  *library);

GTK_SOURCE_INTERNAL
void		 gtk_source_completion_words_library_unlock 		(GtkSourceCompletionWordsLibrary  *library);

G_END_DECLS

#endif /* GTK_SOURCE_COMPLETION_WORDS_LIBRARY_H */
