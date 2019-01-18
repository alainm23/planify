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

#ifndef __AS_BUNDLE_PRIVATE_H
#define __AS_BUNDLE_PRIVATE_H

#include "as-bundle.h"
#include "as-xml.h"
#include "as-yaml.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

gboolean	as_bundle_load_from_xml (AsBundle *bundle,
					AsContext *ctx,
					xmlNode *node,
					GError **error);
void		as_bundle_to_xml_node (AsBundle *bundle,
				       AsContext *ctx,
				       xmlNode *root);

gboolean	as_bundle_load_from_yaml (AsBundle *bundle,
					  AsContext *ctx,
					  GNode *node,
					  GError **error);
void		as_bundle_emit_yaml (AsBundle *bundle,
					AsContext *ctx,
					yaml_emitter_t *emitter);

void		as_bundle_to_variant (AsBundle *bundle,
				      GVariantBuilder *builder);
gboolean	as_bundle_set_from_variant (AsBundle *bundle,
					    GVariant *variant);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_BUNDLE_PRIVATE_H */
