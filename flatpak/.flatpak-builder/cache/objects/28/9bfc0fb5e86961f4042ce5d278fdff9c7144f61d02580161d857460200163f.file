/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#if !defined (__APPSTREAM_H) && !defined (AS_COMPILATION)
#error "Only <appstream.h> can be included directly."
#endif

#ifndef __AS_STEMMER_H
#define __AS_STEMMER_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_STEMMER	(as_stemmer_get_type ())
G_DECLARE_FINAL_TYPE (AsStemmer, as_stemmer, AS, STEMMER, GObject)

AsStemmer		*as_stemmer_get (void);

void			as_stemmer_reload (AsStemmer *stemmer,
						const gchar *lang);
gchar			*as_stemmer_stem (AsStemmer *stemmer,
						const gchar *term);

G_END_DECLS

#endif /* __AS_STEMMER_H */
