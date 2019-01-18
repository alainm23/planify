/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2016-2017 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_RELEASE_PRIVATE_H
#define __AS_RELEASE_PRIVATE_H

#include "as-release.h"
#include "as-xml.h"
#include "as-yaml.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

AsContext		*as_release_get_context (AsRelease *release);
void			as_release_set_context (AsRelease *release,
						AsContext *context);

gboolean		as_release_load_from_xml (AsRelease *release,
						  AsContext *ctx,
						  xmlNode *node,
						  GError **error);
void			as_release_to_xml_node (AsRelease *release,
						AsContext *ctx,
						xmlNode *root);

gboolean		as_release_load_from_yaml (AsRelease *release,
						   AsContext *ctx,
						   GNode *node,
						   GError **error);
void			as_release_emit_yaml (AsRelease *release,
						AsContext *ctx,
						yaml_emitter_t *emitter);

void			as_release_to_variant (AsRelease *release,
						GVariantBuilder *builder);
gboolean		as_release_set_from_variant (AsRelease *release,
						     GVariant *variant,
						     const gchar *locale);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_RELEASE_PRIVATE_H */
