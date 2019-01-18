/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2016 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_SPDX_H
#define __AS_SPDX_H

#include <glib.h>

G_BEGIN_DECLS

gboolean	 as_is_spdx_license_id (const gchar *license_id);
gboolean	 as_is_spdx_license_expression (const gchar *license);

gchar		**as_spdx_license_tokenize (const gchar *license);
gchar		*as_spdx_license_detokenize (gchar **license_tokens);

gchar		*as_license_to_spdx_id (const gchar *license);

gboolean	as_license_is_metadata_license (const gchar *license);

G_END_DECLS

#endif /* __AS_SPDX_H */
