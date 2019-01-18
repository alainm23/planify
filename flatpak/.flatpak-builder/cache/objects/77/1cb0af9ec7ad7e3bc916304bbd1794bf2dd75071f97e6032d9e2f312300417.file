/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2018 Matthias Klumpp <matthias@tenstral.net>
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

#ifndef __AS_RELATION_PRIVATE_H
#define __AS_RELATION_PRIVATE_H

#include "as-relation.h"
#include "as-xml.h"
#include "as-yaml.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

/* NOTE: Some XML/YAML parsing is done in AsComponent, the routines here load single entries from
 * a requires/recommends block */

gboolean	as_relation_load_from_xml (AsRelation *relation,
					   AsContext *ctx,
					   xmlNode *node,
					   GError **error);
void		as_relation_to_xml_node (AsRelation *relation,
					AsContext *ctx,
					xmlNode *root);

gboolean	as_relation_load_from_yaml (AsRelation *relation,
						AsContext *ctx,
						GNode *node,
						GError **error);
void		as_relation_emit_yaml (AsRelation *relation,
					 AsContext *ctx,
					 yaml_emitter_t *emitter);

void		as_relation_to_variant (AsRelation *relation,
					  GVariantBuilder *builder);
gboolean	as_relation_set_from_variant (AsRelation *relation,
						GVariant *variant);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_RELATION_PRIVATE_H */
