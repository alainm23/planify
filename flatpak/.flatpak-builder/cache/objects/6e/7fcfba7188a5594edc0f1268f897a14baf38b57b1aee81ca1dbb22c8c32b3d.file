/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2014 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU General Public License Version 2
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the license, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef __ASCLI_UTILS_H
#define __ASCLI_UTILS_H

#include <glib-object.h>
#include "appstream.h"

G_BEGIN_DECLS

gchar		*ascli_format_long_output (const gchar *str,
					   guint indent_level);
void		ascli_print_key_value (const gchar *key,
				       const gchar *val,
				       gboolean highlight);
void		ascli_print_separator (void);

void		ascli_print_stdout (const gchar *format, ...);
void		ascli_print_stderr (const gchar *format, ...);
void		ascli_print_highlight (const gchar* msg);

void		ascli_print_component (AsComponent *cpt,
				       gboolean show_detailed);
void		ascli_print_components (GPtrArray *cpts,
					gboolean show_detailed);

void		ascli_set_output_colored (gboolean colored);
gboolean	ascli_get_output_colored (void);

G_END_DECLS

#endif /* __ASCLI_UTILS_H */
