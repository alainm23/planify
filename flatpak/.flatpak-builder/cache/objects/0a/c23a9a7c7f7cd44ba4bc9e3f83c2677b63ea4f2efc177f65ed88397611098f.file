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

#ifndef __AS_PROVIDED_PRIVATE_H
#define __AS_PROVIDED_PRIVATE_H

#include "as-provided.h"

G_BEGIN_DECLS
#pragma GCC visibility push(hidden)

/* NOTE: XML and YAML parsing is done in AsComponent, since we can not do it efficiently here */

void			as_provided_to_variant (AsProvided *prov,
						GVariantBuilder *builder);
gboolean		as_provided_set_from_variant (AsProvided *prov,
						      GVariant *variant);

#pragma GCC visibility pop
G_END_DECLS

#endif /* __AS_PROVIDED_PRIVATE_H */
