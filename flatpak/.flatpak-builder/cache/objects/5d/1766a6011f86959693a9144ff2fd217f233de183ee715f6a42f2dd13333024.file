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
 *          Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_SMIME_CONTEXT_H
#define CAMEL_SMIME_CONTEXT_H

#include <camel/camel-cipher-context.h>

/* Standard GObject macros */
#define CAMEL_TYPE_SMIME_CONTEXT \
	(camel_smime_context_get_type ())
#define CAMEL_SMIME_CONTEXT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_SMIME_CONTEXT, CamelSMIMEContext))
#define CAMEL_SMIME_CONTEXT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_SMIME_CONTEXT, CamelSMIMEContextClass))
#define CAMEL_IS_SMIME_CONTEXT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_SMIME_CONTEXT))
#define CAMEL_IS_SMIME_CONTEXT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_SMIME_CONTEXT))
#define CAMEL_SMIME_CONTEXT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_SMIME_CONTEXT, CamelSMIMEContextClass))

G_BEGIN_DECLS

typedef enum _camel_smime_sign_t {
	CAMEL_SMIME_SIGN_CLEARSIGN,
	CAMEL_SMIME_SIGN_ENVELOPED
} CamelSMIMESign;

typedef enum _camel_smime_describe_t {
	CAMEL_SMIME_SIGNED = 1 << 0,
	CAMEL_SMIME_ENCRYPTED = 1 << 1,
	CAMEL_SMIME_CERTS = 1 << 2,
	CAMEL_SMIME_CRLS = 1 << 3
} CamelSMIMEDescribe;

typedef struct _CamelSMIMEContext CamelSMIMEContext;
typedef struct _CamelSMIMEContextClass CamelSMIMEContextClass;
typedef struct _CamelSMIMEContextPrivate CamelSMIMEContextPrivate;

struct _CamelSMIMEContext {
	CamelCipherContext parent;
	CamelSMIMEContextPrivate *priv;
};

struct _CamelSMIMEContextClass {
	CamelCipherContextClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType camel_smime_context_get_type (void);

CamelCipherContext *camel_smime_context_new (CamelSession *session);

/* nick to use for SMIMEEncKeyPrefs attribute for signed data */
void camel_smime_context_set_encrypt_key (CamelSMIMEContext *context, gboolean use, const gchar *key);
/* set signing mode, clearsigned multipart/signed or enveloped */
void camel_smime_context_set_sign_mode (CamelSMIMEContext *context, CamelSMIMESign type);

guint32 camel_smime_context_describe_part (CamelSMIMEContext *context, struct _CamelMimePart *part);

G_END_DECLS

#endif /* CAMEL_SMIME_CONTEXT_H */
