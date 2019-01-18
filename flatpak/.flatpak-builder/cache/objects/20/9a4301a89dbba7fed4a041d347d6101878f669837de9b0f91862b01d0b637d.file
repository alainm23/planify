/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2014-2017 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_ICON_PRIVATE_H
#define __AS_ICON_PRIVATE_H

#include "as-image.h"
#include "as-xml.h"
#include "as-yaml.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

gboolean		as_icon_load_from_xml (AsIcon *icon,
						AsContext *ctx,
						xmlNode *node,
						GError **error);
void			as_icon_to_xml_node (AsIcon *icon,
						AsContext *ctx,
						xmlNode *root);

/* NOTE: For YAML, icons are loaded in AsComponent, because the YAML makes this the better option. */

void			as_icon_to_variant (AsIcon *icon,
						GVariantBuilder *builder);
gboolean		as_icon_set_from_variant (AsIcon *icon,
						  GVariant *variant);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_ICON_PRIVATE_H */
