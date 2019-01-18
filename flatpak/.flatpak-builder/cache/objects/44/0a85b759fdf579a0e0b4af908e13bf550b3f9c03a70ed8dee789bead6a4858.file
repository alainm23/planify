/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionwordslibrary.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom
 * Copyright (C) 2013 - Sébastien Wilmet
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

#include "gtksourcecompletionwordslibrary.h"

#include <string.h>

enum
{
	LOCK,
	UNLOCK,
	N_SIGNALS
};

struct _GtkSourceCompletionWordsLibraryPrivate
{
	GSequence *store;
	gboolean locked;
};

static guint signals[N_SIGNALS];

G_DEFINE_TYPE_WITH_PRIVATE (GtkSourceCompletionWordsLibrary, gtk_source_completion_words_library, G_TYPE_OBJECT)

static void
gtk_source_completion_words_library_finalize (GObject *object)
{
	GtkSourceCompletionWordsLibrary *library = GTK_SOURCE_COMPLETION_WORDS_LIBRARY (object);

	g_sequence_free (library->priv->store);

	G_OBJECT_CLASS (gtk_source_completion_words_library_parent_class)->finalize (object);
}

static void
gtk_source_completion_words_library_class_init (GtkSourceCompletionWordsLibraryClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->finalize = gtk_source_completion_words_library_finalize;

	signals[LOCK] =
		g_signal_new ("lock",
		              G_TYPE_FROM_CLASS (klass),
		              G_SIGNAL_RUN_LAST,
		              0,
		              NULL, NULL, NULL,
		              G_TYPE_NONE, 0);

	signals[UNLOCK] =
		g_signal_new ("unlock",
		              G_TYPE_FROM_CLASS (klass),
		              G_SIGNAL_RUN_LAST,
		              0,
		              NULL, NULL, NULL,
		              G_TYPE_NONE, 0);
}

static void
gtk_source_completion_words_library_init (GtkSourceCompletionWordsLibrary *self)
{
	self->priv = gtk_source_completion_words_library_get_instance_private (self);

	self->priv->store = g_sequence_new ((GDestroyNotify)g_object_unref);
}

GtkSourceCompletionWordsLibrary *
gtk_source_completion_words_library_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_COMPLETION_WORDS_LIBRARY, NULL);
}

static gint
compare_full (GtkSourceCompletionWordsProposal *a,
	      GtkSourceCompletionWordsProposal *b)
{
	if (a == b)
	{
		return 0;
	}

	return strcmp (gtk_source_completion_words_proposal_get_word (a),
	               gtk_source_completion_words_proposal_get_word (b));
}

static gint
compare_prefix (GtkSourceCompletionWordsProposal *a,
		GtkSourceCompletionWordsProposal *b,
		gpointer                          len)
{
	gint prefix_length = GPOINTER_TO_INT (len);

	return strncmp (gtk_source_completion_words_proposal_get_word (a),
			gtk_source_completion_words_proposal_get_word (b),
			prefix_length);
}

static gboolean
iter_match_prefix (GSequenceIter *iter,
                   const gchar   *word,
                   gint           len)
{
	GtkSourceCompletionWordsProposal *item;
	const gchar *proposal_word;

	item = gtk_source_completion_words_library_get_proposal (iter);
	proposal_word = gtk_source_completion_words_proposal_get_word (item);

	if (len == -1)
	{
		len = strlen (word);
	}

	return strncmp (proposal_word, word, len) == 0;
}

GtkSourceCompletionWordsProposal *
gtk_source_completion_words_library_get_proposal (GSequenceIter *iter)
{
	if (iter == NULL)
	{
		return NULL;
	}

	return GTK_SOURCE_COMPLETION_WORDS_PROPOSAL (g_sequence_get (iter));
}

/* Find the first item in the library with the prefix equal to @word.
 * If no such items exist, returns %NULL.
 */
GSequenceIter *
gtk_source_completion_words_library_find_first (GtkSourceCompletionWordsLibrary *library,
                                                const gchar                     *word,
                                                gint                             len)
{
	GtkSourceCompletionWordsProposal *proposal;
	GSequenceIter *iter;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY (library), NULL);
	g_return_val_if_fail (word != NULL, NULL);

	if (len == -1)
	{
		len = strlen (word);
	}

	proposal = gtk_source_completion_words_proposal_new (word);

	iter = g_sequence_lookup (library->priv->store,
				  proposal,
				  (GCompareDataFunc)compare_prefix,
				  GINT_TO_POINTER (len));

	g_clear_object (&proposal);

	if (iter == NULL)
	{
		return NULL;
	}

	while (!g_sequence_iter_is_begin (iter))
	{
		GSequenceIter *prev = g_sequence_iter_prev (iter);

		if (!iter_match_prefix (prev, word, len))
		{
			break;
		}

		iter = prev;
	}

	return iter;
}

GSequenceIter *
gtk_source_completion_words_library_find_next (GSequenceIter *iter,
                                               const gchar   *word,
                                               gint           len)
{
	g_return_val_if_fail (iter != NULL, NULL);
	g_return_val_if_fail (word != NULL, NULL);

	iter = g_sequence_iter_next (iter);

	if (!g_sequence_iter_is_end (iter) &&
	    iter_match_prefix (iter, word, len))
	{
		return iter;
	}

	return NULL;
}

GSequenceIter *
gtk_source_completion_words_library_find (GtkSourceCompletionWordsLibrary  *library,
					  GtkSourceCompletionWordsProposal *proposal)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY (library), NULL);
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_PROPOSAL (proposal), NULL);

	return g_sequence_lookup (library->priv->store,
				  proposal,
				  (GCompareDataFunc)compare_full,
				  NULL);
}

static void
on_proposal_unused (GtkSourceCompletionWordsProposal *proposal,
                    GtkSourceCompletionWordsLibrary  *library)
{
	GSequenceIter *iter = gtk_source_completion_words_library_find (library,
	                                                                proposal);

	if (iter != NULL)
	{
		g_sequence_remove (iter);
	}
}

GtkSourceCompletionWordsProposal *
gtk_source_completion_words_library_add_word (GtkSourceCompletionWordsLibrary *library,
                                              const gchar                     *word)
{
	GtkSourceCompletionWordsProposal *proposal;
	GSequenceIter *iter;

	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY (library), NULL);
	g_return_val_if_fail (word != NULL, NULL);

	/* Check if word already exists */
	proposal = gtk_source_completion_words_proposal_new (word);

	iter = gtk_source_completion_words_library_find (library, proposal);

	if (iter != NULL)
	{
		GtkSourceCompletionWordsProposal *iter_proposal;

		iter_proposal = gtk_source_completion_words_library_get_proposal (iter);

		/* Already exists, increase the use count */
		gtk_source_completion_words_proposal_use (iter_proposal);

		g_object_unref (proposal);
		return iter_proposal;
	}

	if (library->priv->locked)
	{
		g_object_unref (proposal);
		return NULL;
	}

	g_signal_connect (proposal,
	                  "unused",
	                  G_CALLBACK (on_proposal_unused),
	                  library);

	g_sequence_insert_sorted (library->priv->store,
	                          proposal,
	                          (GCompareDataFunc)compare_full,
	                          NULL);

	return proposal;
}

void
gtk_source_completion_words_library_remove_word (GtkSourceCompletionWordsLibrary  *library,
                                                 GtkSourceCompletionWordsProposal *proposal)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY (library));
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_PROPOSAL (proposal));

	gtk_source_completion_words_proposal_unuse (proposal);
}

void
gtk_source_completion_words_library_lock (GtkSourceCompletionWordsLibrary *library)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY (library));

	library->priv->locked = TRUE;
	g_signal_emit (library, signals[LOCK], 0);
}

void
gtk_source_completion_words_library_unlock (GtkSourceCompletionWordsLibrary *library)
{
	g_return_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY (library));

	library->priv->locked = FALSE;
	g_signal_emit (library, signals[UNLOCK], 0);
}

gboolean
gtk_source_completion_words_library_is_locked (GtkSourceCompletionWordsLibrary *library)
{
	g_return_val_if_fail (GTK_SOURCE_IS_COMPLETION_WORDS_LIBRARY (library), TRUE);

	return library->priv->locked;
}
