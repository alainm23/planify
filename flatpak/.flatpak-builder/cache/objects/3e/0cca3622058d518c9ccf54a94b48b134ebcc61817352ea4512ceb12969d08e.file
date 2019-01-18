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

#ifndef CAMEL_CIPHER_CONTEXT_H
#define CAMEL_CIPHER_CONTEXT_H

#include <camel/camel-mime-part.h>
#include <camel/camel-session.h>

/* Standard GObject macros */
#define CAMEL_TYPE_CIPHER_CONTEXT \
	(camel_cipher_context_get_type ())
#define CAMEL_CIPHER_CONTEXT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_CIPHER_CONTEXT, CamelCipherContext))
#define CAMEL_CIPHER_CONTEXT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_CIPHER_CONTEXT, CamelCipherContextClass))
#define CAMEL_IS_CIPHER_CONTEXT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_CIPHER_CONTEXT))
#define CAMEL_IS_CIPHER_CONTEXT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_CIPHER_CONTEXT))
#define CAMEL_CIPHER_CONTEXT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_CIPHER_CONTEXT, CamelCipherContextClass))

/**
 * CAMEL_CIPHER_CERT_INFO_PROPERTY_PHOTO_FILENAME:
 *
 * Name of the photo-filename property which can be stored
 * on a #CamelCipherCertInfo.
 *
 * Since: 3.22
 **/
#define CAMEL_CIPHER_CERT_INFO_PROPERTY_PHOTO_FILENAME "photo-filename"

/**
 * CAMEL_CIPHER_CERT_INFO_PROPERTY_SIGNERS_ALT_EMAILS:
 *
 * A string containing a list of email addresses of all signers
 * including their alternative emails. Use camel_address_unformat()
 * to break them back into separate addresses. This can be set
 * only on the first signer of the first validity, even the addresses
 * can belong to a different signer.
 *
 * Since: 3.28
 **/
#define CAMEL_CIPHER_CERT_INFO_PROPERTY_SIGNERS_ALT_EMAILS "signers-alt-emails"

G_BEGIN_DECLS

typedef gpointer (* CamelCipherCloneFunc) (gpointer value);

typedef struct _CamelCipherValidity CamelCipherValidity;
typedef struct _CamelCipherCertInfo CamelCipherCertInfo;
typedef struct _CamelCipherCertInfoProperty CamelCipherCertInfoProperty;

typedef struct _CamelCipherContext CamelCipherContext;
typedef struct _CamelCipherContextClass CamelCipherContextClass;
typedef struct _CamelCipherContextPrivate CamelCipherContextPrivate;

typedef enum {
	CAMEL_CIPHER_HASH_DEFAULT,
	CAMEL_CIPHER_HASH_MD2,
	CAMEL_CIPHER_HASH_MD5,
	CAMEL_CIPHER_HASH_SHA1,
	CAMEL_CIPHER_HASH_SHA256,
	CAMEL_CIPHER_HASH_SHA384,
	CAMEL_CIPHER_HASH_SHA512,
	CAMEL_CIPHER_HASH_RIPEMD160,
	CAMEL_CIPHER_HASH_TIGER192,
	CAMEL_CIPHER_HASH_HAVAL5160
} CamelCipherHash;

typedef enum _camel_cipher_validity_sign_t {
	CAMEL_CIPHER_VALIDITY_SIGN_NONE,
	CAMEL_CIPHER_VALIDITY_SIGN_GOOD,
	CAMEL_CIPHER_VALIDITY_SIGN_BAD,
	CAMEL_CIPHER_VALIDITY_SIGN_UNKNOWN,
	CAMEL_CIPHER_VALIDITY_SIGN_NEED_PUBLIC_KEY
} CamelCipherValiditySign;

typedef enum _camel_cipher_validity_encrypt_t {
	CAMEL_CIPHER_VALIDITY_ENCRYPT_NONE,
	CAMEL_CIPHER_VALIDITY_ENCRYPT_WEAK,
	CAMEL_CIPHER_VALIDITY_ENCRYPT_ENCRYPTED, /* encrypted, unknown strenght */
	CAMEL_CIPHER_VALIDITY_ENCRYPT_STRONG
} CamelCipherValidityEncrypt;

typedef enum _camel_cipher_validity_mode_t {
	CAMEL_CIPHER_VALIDITY_SIGN,
	CAMEL_CIPHER_VALIDITY_ENCRYPT
} CamelCipherValidityMode;

struct _CamelCipherCertInfoProperty {
	gchar *name;
	gpointer value;

	GDestroyNotify value_free;
	CamelCipherCloneFunc value_clone;
};

struct _CamelCipherCertInfo {
	gchar *name;		/* common name */
	gchar *email;

	gpointer cert_data;  /* custom certificate data; can be NULL */
	GDestroyNotify cert_data_free; /* called to free cert_data; can be NULL only if cert_data is NULL */
	CamelCipherCloneFunc cert_data_clone; /* called to clone cert_data; can be NULL only if cert_data is NULL */

	GSList *properties; /* CamelCipherCertInfoProperty * */
};

struct _CamelCipherValidity {
	GQueue children;

	struct _sign {
		CamelCipherValiditySign status;
		gchar *description;
		GQueue signers;	/* CamelCipherCertInfo's */
	} sign;

	struct _encrypt {
		CamelCipherValidityEncrypt status;
		gchar *description;
		GQueue encrypters;	/* CamelCipherCertInfo's */
	} encrypt;
};

struct _CamelCipherContext {
	GObject parent;
	CamelCipherContextPrivate *priv;
};

struct _CamelCipherContextClass {
	GObjectClass parent_class;

	/* these MUST be set by implementors */
	const gchar *sign_protocol;
	const gchar *encrypt_protocol;
	const gchar *key_protocol;

	/* Non-Blocking Methods */
	CamelCipherHash	(*id_to_hash)		(CamelCipherContext *context,
						 const gchar *id);
	const gchar *	(*hash_to_id)		(CamelCipherContext *context,
						 CamelCipherHash hash);

	/* Synchronous I/O Methods */
	gboolean	(*sign_sync)		(CamelCipherContext *context,
						 const gchar *userid,
						 CamelCipherHash hash,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 GCancellable *cancellable,
						 GError **error);
	CamelCipherValidity *
			(*verify_sync)		(CamelCipherContext *context,
						 CamelMimePart *ipart,
						 GCancellable *cancellable,
						 GError **error);
	gboolean	(*encrypt_sync)		(CamelCipherContext *context,
						 const gchar *userid,
						 GPtrArray *recipients,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 GCancellable *cancellable,
						 GError **error);
	CamelCipherValidity *
			(*decrypt_sync)		(CamelCipherContext *context,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 GCancellable *cancellable,
						 GError **error);

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_cipher_context_get_type	(void);
CamelCipherContext *
		camel_cipher_context_new	(CamelSession *session);
CamelSession *	camel_cipher_context_get_session
						(CamelCipherContext *context);

/* cipher context util routines */
CamelCipherHash	camel_cipher_context_id_to_hash	(CamelCipherContext *context,
						 const gchar *id);
const gchar *	camel_cipher_context_hash_to_id	(CamelCipherContext *context,
						 CamelCipherHash hash);

/* FIXME:
 * There are some inconsistencies here, the api's should probably handle CamelMimePart's as input/outputs,
 * Something that might generate a multipart/signed should do it as part of that processing, internally
 * to the cipher, etc etc. */

/* cipher routines */
gboolean	camel_cipher_context_sign_sync	(CamelCipherContext *context,
						 const gchar *userid,
						 CamelCipherHash hash,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 GCancellable *cancellable,
						 GError **error);
void		camel_cipher_context_sign	(CamelCipherContext *context,
						 const gchar *userid,
						 CamelCipherHash hash,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_cipher_context_sign_finish
						(CamelCipherContext *context,
						 GAsyncResult *result,
						 GError **error);
CamelCipherValidity *
		camel_cipher_context_verify_sync
						(CamelCipherContext *context,
						 CamelMimePart *ipart,
						 GCancellable *cancellable,
						 GError **error);
void		camel_cipher_context_verify	(CamelCipherContext *context,
						 CamelMimePart *ipart,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelCipherValidity *
		camel_cipher_context_verify_finish
						(CamelCipherContext *context,
						 GAsyncResult *result,
						 GError **error);
gboolean	camel_cipher_context_encrypt_sync
						(CamelCipherContext *context,
						 const gchar *userid,
						 GPtrArray *recipients,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 GCancellable *cancellable,
						 GError **error);
void		camel_cipher_context_encrypt	(CamelCipherContext *context,
						 const gchar *userid,
						 GPtrArray *recipients,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	camel_cipher_context_encrypt_finish
						(CamelCipherContext *context,
						 GAsyncResult *result,
						 GError **error);
CamelCipherValidity *
		camel_cipher_context_decrypt_sync
						(CamelCipherContext *context,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 GCancellable *cancellable,
						 GError **error);
void		camel_cipher_context_decrypt	(CamelCipherContext *context,
						 CamelMimePart *ipart,
						 CamelMimePart *opart,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
CamelCipherValidity *
		camel_cipher_context_decrypt_finish
						(CamelCipherContext *context,
						 GAsyncResult *result,
						 GError **error);

/* CamelCipherValidity utility functions */
GType		camel_cipher_validity_get_type	(void);
CamelCipherValidity *
		camel_cipher_validity_new	(void);
void		camel_cipher_validity_init	(CamelCipherValidity *validity);
gboolean	camel_cipher_validity_get_valid	(CamelCipherValidity *validity);
void		camel_cipher_validity_set_valid	(CamelCipherValidity *validity,
						 gboolean valid);
gchar *		camel_cipher_validity_get_description
						(CamelCipherValidity *validity);
void		camel_cipher_validity_set_description
						(CamelCipherValidity *validity,
						 const gchar *description);
void		camel_cipher_validity_clear	(CamelCipherValidity *validity);
CamelCipherValidity *
		camel_cipher_validity_clone	(CamelCipherValidity *vin);
gint		camel_cipher_validity_add_certinfo
						(CamelCipherValidity *vin,
						 CamelCipherValidityMode mode,
						 const gchar *name,
						 const gchar *email);
gint		camel_cipher_validity_add_certinfo_ex (
						CamelCipherValidity *vin,
						CamelCipherValidityMode mode,
						const gchar *name,
						const gchar *email,
						gpointer cert_data,
						GDestroyNotify cert_data_free,
						CamelCipherCloneFunc cert_data_clone);
gpointer	camel_cipher_validity_get_certinfo_property
						(CamelCipherValidity *vin,
						 CamelCipherValidityMode mode,
						 gint info_index,
						 const gchar *name);
void		camel_cipher_validity_set_certinfo_property
						(CamelCipherValidity *vin,
						 CamelCipherValidityMode mode,
						 gint info_index,
						 const gchar *name,
						 gpointer value,
						 GDestroyNotify value_free,
						 CamelCipherCloneFunc value_clone);
void		camel_cipher_validity_envelope	(CamelCipherValidity *parent,
						 CamelCipherValidity *valid);
void		camel_cipher_validity_free	(CamelCipherValidity *validity);

/* CamelCipherCertInfo utility functions */
gpointer	camel_cipher_certinfo_get_property
						(CamelCipherCertInfo *cert_info,
						 const gchar *name);
void		camel_cipher_certinfo_set_property
						(CamelCipherCertInfo *cert_info,
						 const gchar *name,
						 gpointer value,
						 GDestroyNotify value_free,
						 CamelCipherCloneFunc value_clone);

/* utility functions */
gint		camel_cipher_canonical_to_stream
						(CamelMimePart *part,
						 guint32 flags,
						 CamelStream *ostream,
						 GCancellable *cancellable,
						 GError **error);
gboolean	camel_cipher_can_load_photos	(void);

G_END_DECLS

#endif /* CAMEL_CIPHER_CONTEXT_H */
