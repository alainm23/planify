/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*-
 * gtksourcecontextengine.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2003 - Gustavo Giráldez
 * Copyright (C) 2005 - Marco Barisione, Emanuele Aina
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

#ifndef GTK_SOURCE_CONTEXT_ENGINE_H
#define GTK_SOURCE_CONTEXT_ENGINE_H

#include "gtksourceengine.h"
#include "gtksourcetypes.h"
#include "gtksourcetypes-private.h"

G_BEGIN_DECLS

#define GTK_SOURCE_TYPE_CONTEXT_ENGINE            (_gtk_source_context_engine_get_type ())
#define GTK_SOURCE_CONTEXT_ENGINE(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), GTK_SOURCE_TYPE_CONTEXT_ENGINE, GtkSourceContextEngine))
#define GTK_SOURCE_CONTEXT_ENGINE_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), GTK_SOURCE_TYPE_CONTEXT_ENGINE, GtkSourceContextEngineClass))
#define GTK_SOURCE_IS_CONTEXT_ENGINE(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), GTK_SOURCE_TYPE_CONTEXT_ENGINE))
#define GTK_SOURCE_IS_CONTEXT_ENGINE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), GTK_SOURCE_TYPE_CONTEXT_ENGINE))
#define GTK_SOURCE_CONTEXT_ENGINE_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), GTK_SOURCE_TYPE_CONTEXT_ENGINE, GtkSourceContextEngineClass))

typedef struct _GtkSourceContextData          GtkSourceContextData;
typedef struct _GtkSourceContextReplace       GtkSourceContextReplace;
typedef struct _GtkSourceContextClass         GtkSourceContextClass;
typedef struct _GtkSourceContextEngineClass   GtkSourceContextEngineClass;
typedef struct _GtkSourceContextEnginePrivate GtkSourceContextEnginePrivate;

struct _GtkSourceContextEngine
{
	GObject parent_instance;

	/*< private >*/
	GtkSourceContextEnginePrivate *priv;
};

struct _GtkSourceContextEngineClass
{
	GObjectClass parent_class;
};

typedef enum _GtkSourceContextFlags {
	GTK_SOURCE_CONTEXT_EXTEND_PARENT	= 1 << 0,
	GTK_SOURCE_CONTEXT_END_PARENT		= 1 << 1,
	GTK_SOURCE_CONTEXT_END_AT_LINE_END	= 1 << 2,
	GTK_SOURCE_CONTEXT_FIRST_LINE_ONLY	= 1 << 3,
	GTK_SOURCE_CONTEXT_ONCE_ONLY		= 1 << 4,
	GTK_SOURCE_CONTEXT_STYLE_INSIDE		= 1 << 5
} GtkSourceContextFlags;

typedef enum _GtkSourceContextRefOptions {
	GTK_SOURCE_CONTEXT_IGNORE_STYLE		= 1 << 0,
	GTK_SOURCE_CONTEXT_OVERRIDE_STYLE	= 1 << 1,
	GTK_SOURCE_CONTEXT_REF_ORIGINAL		= 1 << 2
} GtkSourceContextRefOptions;

G_GNUC_INTERNAL
GType			 _gtk_source_context_engine_get_type		(void) G_GNUC_CONST;

G_GNUC_INTERNAL
GtkSourceContextData	*_gtk_source_context_data_new			(GtkSourceLanguage	 *lang);

G_GNUC_INTERNAL
GtkSourceContextData	*_gtk_source_context_data_ref			(GtkSourceContextData	 *data);

G_GNUC_INTERNAL
void			 _gtk_source_context_data_unref			(GtkSourceContextData	 *data);

G_GNUC_INTERNAL
GtkSourceContextClass	*gtk_source_context_class_new			(gchar const		 *name,
									 gboolean		  enabled);

G_GNUC_INTERNAL
void			 gtk_source_context_class_free			(GtkSourceContextClass	 *cclass);

G_GNUC_INTERNAL
GtkSourceContextEngine	*_gtk_source_context_engine_new			(GtkSourceContextData	 *data);

G_GNUC_INTERNAL
gboolean		 _gtk_source_context_data_define_context	(GtkSourceContextData	 *data,
									 const gchar		 *id,
									 const gchar		 *parent_id,
									 const gchar		 *match_regex,
									 const gchar		 *start_regex,
									 const gchar		 *end_regex,
									 const gchar		 *style,
									 GSList			 *context_classes,
									 GtkSourceContextFlags    flags,
									 GError			**error);

G_GNUC_INTERNAL
gboolean		 _gtk_source_context_data_add_sub_pattern	(GtkSourceContextData	 *data,
									 const gchar		 *id,
									 const gchar		 *parent_id,
									 const gchar		 *name,
									 const gchar		 *where,
									 const gchar		 *style,
									 GSList			 *context_classes,
									 GError			**error);

G_GNUC_INTERNAL
gboolean		 _gtk_source_context_data_add_ref		(GtkSourceContextData	 *data,
									 const gchar		 *parent_id,
									 const gchar		 *ref_id,
									 GtkSourceContextRefOptions options,
									 const gchar		 *style,
									 gboolean		  all,
									 GError			**error);

G_GNUC_INTERNAL
GtkSourceContextReplace	*_gtk_source_context_replace_new		(const gchar             *to_replace_id,
									 const gchar             *replace_with_id);

G_GNUC_INTERNAL
void			 _gtk_source_context_replace_free		(GtkSourceContextReplace *repl);

G_GNUC_INTERNAL
gboolean		 _gtk_source_context_data_finish_parse		(GtkSourceContextData	 *data,
									 GList                   *overrides,
									 GError			**error);

/* Only for lang files version 1, do not use it */
G_GNUC_INTERNAL
void			 _gtk_source_context_data_set_escape_char	(GtkSourceContextData	 *data,
									 gunichar		  esc_char);

G_END_DECLS

#endif /* GTK_SOURCE_CONTEXT_ENGINE_H */
