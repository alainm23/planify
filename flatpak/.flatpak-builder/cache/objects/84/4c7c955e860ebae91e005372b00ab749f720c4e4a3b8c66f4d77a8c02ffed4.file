/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2018 Richard Hughes <richard@hughsie.com>
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

#ifndef __AS_AGREEMENT_PRIVATE_H
#define __AS_AGREEMENT_PRIVATE_H

#include <glib-object.h>

#include "as-context.h"
#include "as-agreement.h"
#include "as-xml.h"
#include "as-yaml.h"
#include "as-variant-cache.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

AsContext		*as_agreement_get_context (AsAgreement *agreement);
void			as_agreement_set_context (AsAgreement *agreement,
						 AsContext *context);


void			as_agreement_to_xml_node (AsAgreement *agreement,
						  AsContext *ctx,
						  xmlNode *root);
gboolean		as_agreement_load_from_xml (AsAgreement *agreement,
						    AsContext *ctx,
						    xmlNode *node,
						    GError **error);

gboolean		as_agreement_load_from_yaml (AsAgreement *agreement,
						     AsContext *ctx,
						     GNode *node,
						     GError **error);
void			as_agreement_emit_yaml (AsAgreement *agreement,
						AsContext *ctx,
						yaml_emitter_t *emitter);

void			as_agreement_to_variant (AsAgreement *agreement,
						 GVariantBuilder *builder);
gboolean		as_agreement_set_from_variant (AsAgreement *agreement,
						       GVariant *variant,
							const gchar *locale);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_AGREEMENT_PRIVATE_H */
