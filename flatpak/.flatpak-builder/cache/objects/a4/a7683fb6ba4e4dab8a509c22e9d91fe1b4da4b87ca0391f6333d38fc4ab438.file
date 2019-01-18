/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecompletionmodel.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2009 - Jesse van den Kieboom <jessevdk@gnome.org>
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

#ifndef GTK_SOURCE_COMPLETION_MODEL_H
#define GTK_SOURCE_COMPLETION_MODEL_H

#include <gtk/gtk.h>
#include "gtksourcetypes.h"
#include "gtksourcetypes-private.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_COMPLETION_MODEL		(gtk_source_completion_model_get_type ())
#define GTK_SOURCE_COMPLETION_MODEL(obj)		(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_MODEL, GtkSourceCompletionModel))
#define GTK_SOURCE_COMPLETION_MODEL_CONST(obj)		(G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_COMPLETION_MODEL, GtkSourceCompletionModel const))
#define GTK_SOURCE_COMPLETION_MODEL_CLASS(klass)	(G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_COMPLETION_MODEL, GtkSourceCompletionModelClass))
#define GTK_SOURCE_IS_COMPLETION_MODEL(obj)		(G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_COMPLETION_MODEL))
#define GTK_SOURCE_IS_COMPLETION_MODEL_CLASS(klass)	(G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_COMPLETION_MODEL))
#define GTK_SOURCE_COMPLETION_MODEL_GET_CLASS(obj)	(G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_COMPLETION_MODEL, GtkSourceCompletionModelClass))

typedef struct _GtkSourceCompletionModelClass	GtkSourceCompletionModelClass;
typedef struct _GtkSourceCompletionModelPrivate	GtkSourceCompletionModelPrivate;

struct _GtkSourceCompletionModel {
	GObject parent;

	GtkSourceCompletionModelPrivate *priv;
};

struct _GtkSourceCompletionModelClass {
	GObjectClass parent_class;

	void (*providers_changed) 	(GtkSourceCompletionModel *model);
};

enum
{
	GTK_SOURCE_COMPLETION_MODEL_COLUMN_MARKUP,
	GTK_SOURCE_COMPLETION_MODEL_COLUMN_ICON,
	GTK_SOURCE_COMPLETION_MODEL_COLUMN_ICON_NAME,
	GTK_SOURCE_COMPLETION_MODEL_COLUMN_GICON,
	GTK_SOURCE_COMPLETION_MODEL_COLUMN_PROPOSAL,
	GTK_SOURCE_COMPLETION_MODEL_COLUMN_PROVIDER,
	GTK_SOURCE_COMPLETION_MODEL_COLUMN_IS_HEADER,
	GTK_SOURCE_COMPLETION_MODEL_N_COLUMNS
};

GTK_SOURCE_INTERNAL
GType    gtk_source_completion_model_get_type			(void) G_GNUC_CONST;

GTK_SOURCE_INTERNAL
GtkSourceCompletionModel *
         gtk_source_completion_model_new			(void);

GTK_SOURCE_INTERNAL
void     gtk_source_completion_model_add_proposals              (GtkSourceCompletionModel    *model,
								 GtkSourceCompletionProvider *provider,
								 GList                       *proposals);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_is_empty			(GtkSourceCompletionModel    *model,
								 gboolean                     only_visible);

GTK_SOURCE_INTERNAL
void     gtk_source_completion_model_set_visible_providers	(GtkSourceCompletionModel    *model,
								 GList                       *providers);

GTK_SOURCE_INTERNAL
GList   *gtk_source_completion_model_get_visible_providers	(GtkSourceCompletionModel    *model);

GTK_SOURCE_INTERNAL
GList   *gtk_source_completion_model_get_providers		(GtkSourceCompletionModel    *model);

GTK_SOURCE_INTERNAL
void     gtk_source_completion_model_set_show_headers		(GtkSourceCompletionModel    *model,
								 gboolean                     show_headers);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_iter_is_header		(GtkSourceCompletionModel    *model,
								 GtkTreeIter                 *iter);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_iter_previous		(GtkSourceCompletionModel    *model,
								 GtkTreeIter                 *iter);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_first_proposal             (GtkSourceCompletionModel    *model,
								 GtkTreeIter                 *iter);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_last_proposal              (GtkSourceCompletionModel    *model,
								 GtkTreeIter                 *iter);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_next_proposal              (GtkSourceCompletionModel    *model,
								 GtkTreeIter                 *iter);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_previous_proposal          (GtkSourceCompletionModel    *model,
								 GtkTreeIter                 *iter);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_has_info                   (GtkSourceCompletionModel    *model);

GTK_SOURCE_INTERNAL
gboolean gtk_source_completion_model_iter_equal			(GtkSourceCompletionModel    *model,
								 GtkTreeIter                 *iter1,
								 GtkTreeIter                 *iter2);

G_END_DECLS

#endif /* GTK_SOURCE_COMPLETION_MODEL_H */
