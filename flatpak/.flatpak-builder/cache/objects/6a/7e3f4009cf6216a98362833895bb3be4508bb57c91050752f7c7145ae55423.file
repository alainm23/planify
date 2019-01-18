/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2017 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_CONTEXT_H
#define __AS_CONTEXT_H

#include <glib-object.h>
#include "as-metadata.h"

G_BEGIN_DECLS

#define AS_TYPE_CONTEXT (as_context_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsContext, as_context, AS, CONTEXT, GObject)

struct _AsContextClass
{
	GObjectClass parent_class;
	/*< private >*/
	void (*_as_reserved1) (void);
	void (*_as_reserved2) (void);
	void (*_as_reserved3) (void);
	void (*_as_reserved4) (void);
	void (*_as_reserved5) (void);
	void (*_as_reserved6) (void);
};

AsContext		*as_context_new (void);

AsFormatVersion		as_context_get_format_version (AsContext *ctx);
void			as_context_set_format_version (AsContext *ctx,
						       AsFormatVersion ver);

AsFormatStyle		as_context_get_style (AsContext *ctx);
void			as_context_set_style (AsContext *ctx,
						AsFormatStyle style);

gint			as_context_get_priority (AsContext *ctx);
void			as_context_set_priority (AsContext *ctx,
						 gint priority);

const gchar		*as_context_get_origin (AsContext *ctx);
void			as_context_set_origin (AsContext *ctx,
					       const gchar *value);

const gchar		*as_context_get_locale (AsContext *ctx);
void			as_context_set_locale (AsContext *ctx,
					       const gchar *value);

gboolean		as_context_has_media_baseurl (AsContext *ctx);
const gchar		*as_context_get_media_baseurl (AsContext *ctx);
void			as_context_set_media_baseurl (AsContext *ctx,
						      const gchar *value);

const gchar		*as_context_get_architecture (AsContext *ctx);
void			as_context_set_architecture (AsContext *ctx,
						     const gchar *value);

gboolean		as_context_get_all_locale_enabled (AsContext *ctx);

const gchar		*as_context_get_filename (AsContext *ctx);
void			as_context_set_filename (AsContext *ctx,
					       const gchar *fname);

G_END_DECLS

#endif /* __AS_CONTEXT_H */
