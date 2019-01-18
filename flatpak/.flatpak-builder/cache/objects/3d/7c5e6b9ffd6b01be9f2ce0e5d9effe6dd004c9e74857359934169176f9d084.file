/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_CATEGORIES_H
#define E_CATEGORIES_H

#include <glib-object.h>

G_BEGIN_DECLS

G_DEPRECATED_FOR (e_categories_dup_list)
GList *		e_categories_get_list		(void);

GList *		e_categories_dup_list		(void);

/* 'unused' parameter was 'color', but it is deprecated now (see bug #308815) */
void		e_categories_add		(const gchar *category,
						 const gchar *unused,
						 const gchar *icon_file,
						 gboolean searchable);
void		e_categories_remove		(const gchar *category);
gboolean	e_categories_exist		(const gchar *category);
G_DEPRECATED_FOR (e_categories_dup_icon_file_for)
const gchar *	e_categories_get_icon_file_for	(const gchar *category);
gchar *		e_categories_dup_icon_file_for	(const gchar *category);
void		e_categories_set_icon_file_for	(const gchar *category,
						 const gchar *icon_file);
gboolean	e_categories_is_searchable	(const gchar *category);

void		e_categories_register_change_listener
						(GCallback listener,
						 gpointer user_data);
void		e_categories_unregister_change_listener
						(GCallback listener,
						 gpointer user_data);

G_END_DECLS

#endif /* E_CATEGORIES_H */
