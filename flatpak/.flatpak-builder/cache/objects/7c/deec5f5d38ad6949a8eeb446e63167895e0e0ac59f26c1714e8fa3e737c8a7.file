/*
 * gtksourcetypes.h
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2012-2016 - Sébastien Wilmet <swilmet@gnome.org>
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

#ifndef GTK_SOURCE_TYPES_H
#define GTK_SOURCE_TYPES_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <glib.h>
#include <gtksourceview/gtksourceversion.h>

G_BEGIN_DECLS

/* This header exists to avoid cycles in header inclusions, when header A needs
 * the type B and header B needs the type A. For an alternative way to solve
 * this problem (in C11), see:
 * https://bugzilla.gnome.org/show_bug.cgi?id=679424#c20
 */

typedef struct _GtkSourceBuffer			GtkSourceBuffer;
typedef struct _GtkSourceCompletionContext	GtkSourceCompletionContext;
typedef struct _GtkSourceCompletion		GtkSourceCompletion;
typedef struct _GtkSourceCompletionInfo		GtkSourceCompletionInfo;
typedef struct _GtkSourceCompletionItem		GtkSourceCompletionItem;
typedef struct _GtkSourceCompletionProposal	GtkSourceCompletionProposal;
typedef struct _GtkSourceCompletionProvider	GtkSourceCompletionProvider;
typedef struct _GtkSourceEncoding		GtkSourceEncoding;
typedef struct _GtkSourceFile			GtkSourceFile;
typedef struct _GtkSourceFileLoader		GtkSourceFileLoader;
typedef struct _GtkSourceFileSaver		GtkSourceFileSaver;
typedef struct _GtkSourceGutter			GtkSourceGutter;
typedef struct _GtkSourceGutterRenderer		GtkSourceGutterRenderer;
typedef struct _GtkSourceGutterRendererPixbuf	GtkSourceGutterRendererPixbuf;
typedef struct _GtkSourceGutterRendererText	GtkSourceGutterRendererText;
typedef struct _GtkSourceLanguage		GtkSourceLanguage;
typedef struct _GtkSourceLanguageManager	GtkSourceLanguageManager;
typedef struct _GtkSourceMap			GtkSourceMap;
typedef struct _GtkSourceMarkAttributes		GtkSourceMarkAttributes;
typedef struct _GtkSourceMark			GtkSourceMark;
typedef struct _GtkSourcePrintCompositor	GtkSourcePrintCompositor;
typedef struct _GtkSourceSearchContext		GtkSourceSearchContext;
typedef struct _GtkSourceSearchSettings		GtkSourceSearchSettings;
typedef struct _GtkSourceSpaceDrawer		GtkSourceSpaceDrawer;
typedef struct _GtkSourceStyle			GtkSourceStyle;
typedef struct _GtkSourceStyleScheme		GtkSourceStyleScheme;
typedef struct _GtkSourceStyleSchemeChooser	GtkSourceStyleSchemeChooser;
typedef struct _GtkSourceStyleSchemeChooserButton GtkSourceStyleSchemeChooserButton;
typedef struct _GtkSourceStyleSchemeChooserWidget GtkSourceStyleSchemeChooserWidget;
typedef struct _GtkSourceStyleSchemeManager	GtkSourceStyleSchemeManager;
typedef struct _GtkSourceUndoManager		GtkSourceUndoManager;
typedef struct _GtkSourceView			GtkSourceView;

G_END_DECLS

#endif /* GTK_SOURCE_TYPES_H */
