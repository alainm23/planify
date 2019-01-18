/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionwordsproposal.h
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

#ifndef GTK_SOURCE_COMPLETION_WORDS_PROPOSAL_H
#define GTK_SOURCE_COMPLETION_WORDS_PROPOSAL_H

#include <glib-object.h>
#include <gtksourceview/gtksourcecompletionproposal.h>

#include "gtksourceview/gtksourcetypes-private.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_COMPLETION_WORDS_PROPOSAL			(gtk_source_completion_words_proposal_get_type ())
#define GTK_SOURCE_COMPLETION_WORDS_PROPOSAL(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_PROPOSAL, GtkSourceCompletionWordsProposal))
#define GTK_SOURCE_COMPLETION_WORDS_PROPOSAL_CONST(obj)			(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_PROPOSAL, GtkSourceCompletionWordsProposal const))
#define GTK_SOURCE_COMPLETION_WORDS_PROPOSAL_CLASS(klass)		(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_COMPLETION_WORDS_PROPOSAL, GtkSourceCompletionWordsProposalClass))
#define GTK_SOURCE_IS_COMPLETION_WORDS_PROPOSAL(obj)			(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_PROPOSAL))
#define GTK_SOURCE_IS_COMPLETION_WORDS_PROPOSAL_CLASS(klass)		(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_COMPLETION_WORDS_PROPOSAL))
#define GTK_SOURCE_COMPLETION_WORDS_PROPOSAL_GET_CLASS(obj)		(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_COMPLETION_WORDS_PROPOSAL, GtkSourceCompletionWordsProposalClass))

typedef struct _GtkSourceCompletionWordsProposal		GtkSourceCompletionWordsProposal;
typedef struct _GtkSourceCompletionWordsProposalClass		GtkSourceCompletionWordsProposalClass;
typedef struct _GtkSourceCompletionWordsProposalPrivate		GtkSourceCompletionWordsProposalPrivate;

struct _GtkSourceCompletionWordsProposal {
	GObject parent;

	GtkSourceCompletionWordsProposalPrivate *priv;
};

struct _GtkSourceCompletionWordsProposalClass {
	GObjectClass parent_class;
};

GTK_SOURCE_INTERNAL
GType		 gtk_source_completion_words_proposal_get_type	(void) G_GNUC_CONST;

GTK_SOURCE_INTERNAL
GtkSourceCompletionWordsProposal *
		 gtk_source_completion_words_proposal_new 	(const gchar                      *word);

GTK_SOURCE_INTERNAL
const gchar 	*gtk_source_completion_words_proposal_get_word 	(GtkSourceCompletionWordsProposal *proposal);

GTK_SOURCE_INTERNAL
void		 gtk_source_completion_words_proposal_use 	(GtkSourceCompletionWordsProposal *proposal);

GTK_SOURCE_INTERNAL
void		 gtk_source_completion_words_proposal_unuse 	(GtkSourceCompletionWordsProposal *proposal);

G_END_DECLS

#endif /* GTK_SOURCE_COMPLETION_WORDS_PROPOSAL_H */
