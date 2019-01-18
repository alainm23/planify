/*
 * This file is part of gtksourceview
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

#ifndef GTK_SOURCE_AUTOCLEANUPS_H
#define GTK_SOURCE_AUTOCLEANUPS_H

#if !defined (GTK_SOURCE_H_INSIDE) && !defined (GTK_SOURCE_COMPILATION)
#  if defined (__GNUC__)
#    warning "Only <gtksourceview/gtksource.h> can be included directly."
#  elif defined (G_OS_WIN32)
#    pragma message("Only <gtksourceview/gtksource.h> can be included directly.")
#  endif
#endif

#include <glib.h>
#include <gtksourceview/gtksourcetypes.h>

G_BEGIN_DECLS

#ifndef __GI_SCANNER__

G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceBuffer, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceCompletion, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceCompletionContext, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceCompletionInfo, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceCompletionItem, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceFile, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceFileLoader, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceFileSaver, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceGutter, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceGutterRenderer, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceGutterRendererPixbuf, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceGutterRendererText, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceLanguage, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceLanguageManager, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceMark, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceMap, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourcePrintCompositor, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceSearchContext, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceSearchSettings, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceSpaceDrawer, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceStyleScheme, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceStyleSchemeChooserButton, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceStyleSchemeChooserWidget, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceStyleSchemeManager, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceUndoManager, g_object_unref)
G_DEFINE_AUTOPTR_CLEANUP_FUNC(GtkSourceView, g_object_unref)

#endif /* __GI_SCANNER__ */

G_END_DECLS

#endif /* GTK_SOURCE_AUTOCLEANUPS_H */
