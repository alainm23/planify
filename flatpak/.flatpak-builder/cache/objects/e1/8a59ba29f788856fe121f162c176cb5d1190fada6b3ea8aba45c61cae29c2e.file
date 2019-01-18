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

#ifndef __AS_LAUNCHABLE_PRIVATE_H
#define __AS_LAUNCHABLE_PRIVATE_H

#include "as-launchable.h"
#include "as-xml.h"
#include "as-yaml.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

/* NOTE: The AsComponent load the AsLaunchable from XML, because it needs to aggregate multiple tags in one object. */

void		as_launchable_to_xml_node (AsLaunchable *launchable,
					AsContext *ctx,
					xmlNode *root);

gboolean	as_launchable_load_from_yaml (AsLaunchable *launch,
						AsContext *ctx,
						GNode *node,
						GError **error);
void		as_launchable_emit_yaml (AsLaunchable *launch,
					 AsContext *ctx,
					 yaml_emitter_t *emitter);

void		as_launchable_to_variant (AsLaunchable *launch,
					  GVariantBuilder *builder);
gboolean	as_launchable_set_from_variant (AsLaunchable *launch,
						GVariant *variant);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_LAUNCHABLE_PRIVATE_H */
