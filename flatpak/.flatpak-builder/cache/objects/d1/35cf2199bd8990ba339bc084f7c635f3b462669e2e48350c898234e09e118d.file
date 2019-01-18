/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-source-revision-guards.h - Revision Guard Configuration.
 *
 * Copyright (C) 2013 Intel Corporation
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Tristan Van Berkom <tristanvb@openismus.com>
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_REVISION_GUARDS_H
#define E_SOURCE_REVISION_GUARDS_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_REVISION_GUARDS \
	(e_source_revision_guards_get_type ())
#define E_SOURCE_REVISION_GUARDS(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_REVISION_GUARDS, ESourceRevisionGuards))
#define E_SOURCE_REVISION_GUARDS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_REVISION_GUARDS, ESourceRevisionGuardsClass))
#define E_IS_SOURCE_REVISION_GUARDS(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_REVISION_GUARDS))
#define E_IS_SOURCE_REVISION_GUARDS_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_REVISION_GUARDS))
#define E_SOURCE_REVISION_GUARDS_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_REVISION_GUARDS, ESourceRevisionGuardsClass))

/**
 * E_SOURCE_EXTENSION_REVISION_GUARDS:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceRevisionGuards.  This is also used as a group name in key files.
 *
 * Since: 3.8
 **/
#define E_SOURCE_EXTENSION_REVISION_GUARDS "Revision Guards"

G_BEGIN_DECLS

typedef struct _ESourceRevisionGuards ESourceRevisionGuards;
typedef struct _ESourceRevisionGuardsClass ESourceRevisionGuardsClass;
typedef struct _ESourceRevisionGuardsPrivate ESourceRevisionGuardsPrivate;

/**
 * ESourceRevisionGuards:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.8
 **/
struct _ESourceRevisionGuards {
	/*< private >*/
	ESourceExtension parent;
	ESourceRevisionGuardsPrivate *priv;
};

struct _ESourceRevisionGuardsClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_revision_guards_get_type
					(void) G_GNUC_CONST;
gboolean	e_source_revision_guards_get_enabled
					(ESourceRevisionGuards *extension);
void		e_source_revision_guards_set_enabled
					(ESourceRevisionGuards *extension,
					 gboolean enabled);

G_END_DECLS

#endif /* E_SOURCE_REVISION_GUARDS_H */
