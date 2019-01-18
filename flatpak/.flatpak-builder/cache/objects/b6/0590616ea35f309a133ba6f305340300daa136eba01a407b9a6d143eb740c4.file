/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_GPG_CONTEXT_H
#define CAMEL_GPG_CONTEXT_H

#include <camel/camel-cipher-context.h>
#include <camel/camel-session.h>

/* Standard GObject macros */
#define CAMEL_TYPE_GPG_CONTEXT \
	(camel_gpg_context_get_type ())
#define CAMEL_GPG_CONTEXT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_GPG_CONTEXT, CamelGpgContext))
#define CAMEL_GPG_CONTEXT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_GPG_CONTEXT, CamelGpgContextClass))
#define CAMEL_IS_GPG_CONTEXT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_GPG_CONTEXT))
#define CAMEL_IS_GPG_CONTEXT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_GPG_CONTEXT))
#define CAMEL_GPG_CONTEXT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_GPG_CONTEXT, CamelGpgContextClass))

G_BEGIN_DECLS

typedef struct _CamelGpgContext CamelGpgContext;
typedef struct _CamelGpgContextClass CamelGpgContextClass;
typedef struct _CamelGpgContextPrivate CamelGpgContextPrivate;

struct _CamelGpgContext {
	CamelCipherContext parent;
	CamelGpgContextPrivate *priv;
};

struct _CamelGpgContextClass {
	CamelCipherContextClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_gpg_context_get_type	(void);
CamelCipherContext *
		camel_gpg_context_new		(CamelSession *session);
gboolean	camel_gpg_context_get_always_trust
						(CamelGpgContext *context);
void		camel_gpg_context_set_always_trust
						(CamelGpgContext *context,
						 gboolean always_trust);
gboolean	camel_gpg_context_get_prefer_inline
						(CamelGpgContext *context);
void		camel_gpg_context_set_prefer_inline
						(CamelGpgContext *context,
						 gboolean prefer_inline);

G_END_DECLS

#endif /* CAMEL_GPG_CONTEXT_H */
