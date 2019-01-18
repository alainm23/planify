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
 * Authors: Michael Zucchi <notzed@ximian.com>
 *          Jeffrey Stedfast <fejj@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_MIME_UTILS_H
#define CAMEL_MIME_UTILS_H

#include <time.h>
#include <glib.h>
#include <glib-object.h>
#include <camel/camel-enums.h>
#include <camel/camel-utils.h>
#include <camel/camel-name-value-array.h>

G_BEGIN_DECLS

/* maximum recommended size of a line from camel_header_fold() */
#define CAMEL_FOLD_SIZE (77)
/* maximum hard size of a line from camel_header_fold() */
#define CAMEL_FOLD_MAX_SIZE (998)

typedef enum {
	CAMEL_UUDECODE_STATE_INIT = 0,
	CAMEL_UUDECODE_STATE_BEGIN = (1 << 16),
	CAMEL_UUDECODE_STATE_END = (1 << 17)
} CamelUUDecodeState;

#define CAMEL_UUDECODE_STATE_MASK   (CAMEL_UUDECODE_STATE_BEGIN | CAMEL_UUDECODE_STATE_END)

typedef struct _camel_header_param {
	struct _camel_header_param *next;
	gchar *name;
	gchar *value;
} CamelHeaderParam;

/* describes a content-type */
typedef struct {
	gchar *type;
	gchar *subtype;
	struct _camel_header_param *params;
	guint refcount;
} CamelContentType;

typedef struct _CamelContentDisposition {
	gchar *disposition;
	struct _camel_header_param *params;
	guint refcount;
} CamelContentDisposition;

typedef enum _camel_header_address_t {
	CAMEL_HEADER_ADDRESS_NONE,	/* uninitialised */
	CAMEL_HEADER_ADDRESS_NAME,
	CAMEL_HEADER_ADDRESS_GROUP
} CamelHeaderAddressType;

typedef struct _camel_header_address {
	/* < private > */
	struct _camel_header_address *next;
	CamelHeaderAddressType type;
	gchar *name;
	union {
		gchar *addr;
		struct _camel_header_address *members;
	} v;
	guint refcount;
} CamelHeaderAddress;

/* Time utilities */
time_t		camel_mktime_utc		(struct tm *tm);
void		camel_localtime_with_offset	(time_t tt,
						 struct tm *tm,
						 gint *offset);

/* Address lists */
GType camel_header_address_get_type (void) G_GNUC_CONST;
CamelHeaderAddress *camel_header_address_new (void);
CamelHeaderAddress *camel_header_address_new_name (const gchar *name, const gchar *addr);
CamelHeaderAddress *camel_header_address_new_group (const gchar *name);
CamelHeaderAddress *camel_header_address_ref (CamelHeaderAddress *addrlist);
void camel_header_address_unref (CamelHeaderAddress *addrlist);
void camel_header_address_set_name (CamelHeaderAddress *addrlist, const gchar *name);
void camel_header_address_set_addr (CamelHeaderAddress *addrlist, const gchar *addr);
void camel_header_address_set_members (CamelHeaderAddress *addrlist, CamelHeaderAddress *group);
void camel_header_address_add_member (CamelHeaderAddress *addrlist, CamelHeaderAddress *member);
void camel_header_address_list_append_list (CamelHeaderAddress **addrlistp, CamelHeaderAddress **addrs);
void camel_header_address_list_append (CamelHeaderAddress **addrlistp, CamelHeaderAddress *addr);
void camel_header_address_list_clear (CamelHeaderAddress **addrlistp);

CamelHeaderAddress *camel_header_address_decode (const gchar *in, const gchar *charset);
CamelHeaderAddress *camel_header_mailbox_decode (const gchar *in, const gchar *charset);
/* for mailing */
gchar *camel_header_address_list_encode (CamelHeaderAddress *addrlist);
/* for display */
gchar *camel_header_address_list_format (CamelHeaderAddress *addrlist);

/* structured header prameters */
struct _camel_header_param *camel_header_param_list_decode (const gchar *in);
gchar *camel_header_param (struct _camel_header_param *params, const gchar *name);
struct _camel_header_param *camel_header_set_param (struct _camel_header_param **paramsp, const gchar *name, const gchar *value);
void camel_header_param_list_format_append (GString *out, struct _camel_header_param *params);
gchar *camel_header_param_list_format (struct _camel_header_param *params);
void camel_header_param_list_free (struct _camel_header_param *params);

/* Content-Type header */
GType camel_content_type_get_type (void) G_GNUC_CONST;
CamelContentType *camel_content_type_new (const gchar *type, const gchar *subtype);
CamelContentType *camel_content_type_decode (const gchar *in);
void camel_content_type_unref (CamelContentType *content_type);
CamelContentType *camel_content_type_ref (CamelContentType *content_type);
const gchar *camel_content_type_param (CamelContentType *content_type, const gchar *name);
void camel_content_type_set_param (CamelContentType *content_type, const gchar *name, const gchar *value);
gboolean camel_content_type_is (const CamelContentType *content_type, const gchar *type, const gchar *subtype);
gchar *camel_content_type_format (CamelContentType *content_type);
gchar *camel_content_type_simple (CamelContentType *content_type);

/* DEBUGGING function */
void camel_content_type_dump (CamelContentType *content_type);

/* Content-Disposition header */
GType camel_content_disposition_get_type (void) G_GNUC_CONST;
CamelContentDisposition *camel_content_disposition_new (void);
CamelContentDisposition *camel_content_disposition_decode (const gchar *in);
CamelContentDisposition *camel_content_disposition_ref (CamelContentDisposition *disposition);
void camel_content_disposition_unref (CamelContentDisposition *disposition);
gchar *camel_content_disposition_format (CamelContentDisposition *disposition);
gboolean camel_content_disposition_is_attachment (const CamelContentDisposition *disposition, const CamelContentType *content_type);
gboolean camel_content_disposition_is_attachment_ex (const CamelContentDisposition *disposition, const CamelContentType *content_type, const CamelContentType *parent_content_type);

/* decode the contents of a content-encoding header */
gchar *camel_content_transfer_encoding_decode (const gchar *in);

/* fold a header */
gchar *camel_header_address_fold (const gchar *in, gsize headerlen);
gchar *camel_header_fold (const gchar *in, gsize headerlen);
gchar *camel_header_unfold (const gchar *in);

gchar *camel_headers_dup_mailing_list (const CamelNameValueArray *headers);

/* decode a header which is a simple token */
gchar *camel_header_token_decode (const gchar *in);

gint camel_header_decode_int (const gchar **in);

/* decode/encode a string type, like a subject line */
gchar *camel_header_decode_string (const gchar *in, const gchar *default_charset);
gchar *camel_header_encode_string (const guchar *in);

/* decode (text | comment) - a one-way op */
gchar *camel_header_format_ctext (const gchar *in, const gchar *default_charset);

/* encode a phrase, like the real name of an address */
gchar *camel_header_encode_phrase (const guchar *in);

/* FIXME: these are the only 2 functions in this header which are ch_(action)_type
 * rather than ch_type_(action) */

/* decode an email date field into a GMT time, + optional offset */
time_t camel_header_decode_date (const gchar *str, gint *tz_offset);
gchar *camel_header_format_date (time_t date, gint tz_offset);

/* decode a message id */
gchar *camel_header_msgid_decode (const gchar *in);
gchar *camel_header_contentid_decode (const gchar *in);

/* generate msg id */
gchar *camel_header_msgid_generate (const gchar *domain);

/* decode a References or In-Reply-To header */
GSList *camel_header_references_decode (const gchar *in);

/* decode content-location */
gchar *camel_header_location_decode (const gchar *in);

/* nntp stuff */
GSList *camel_header_newsgroups_decode (const gchar *in);

const gchar *camel_transfer_encoding_to_string (CamelTransferEncoding encoding);
CamelTransferEncoding camel_transfer_encoding_from_string (const gchar *string);

/* decode the mime-type header */
void camel_header_mime_decode (const gchar *in, gint *maj, gint *min);

gsize camel_uudecode_step (guchar *in, gsize inlen, guchar *out, gint *state, guint32 *save);

gsize camel_uuencode_step (guchar *in, gsize len, guchar *out, guchar *uubuf, gint *state,
		      guint32 *save);
gsize camel_uuencode_close (guchar *in, gsize len, guchar *out, guchar *uubuf, gint *state,
		       guint32 *save);

gsize camel_quoted_decode_step (guchar *in, gsize len, guchar *out, gint *savestate, gint *saveme);

gsize camel_quoted_encode_step (guchar *in, gsize len, guchar *out, gint *state, gint *save);
gsize camel_quoted_encode_close (guchar *in, gsize len, guchar *out, gint *state, gint *save);

/* camel ctype type functions for rfc822/rfc2047/other, which are non-locale specific */
enum {
	CAMEL_MIME_IS_CTRL = 1 << 0,
	CAMEL_MIME_IS_LWSP = 1 << 1,
	CAMEL_MIME_IS_TSPECIAL = 1 << 2,
	CAMEL_MIME_IS_SPECIAL = 1 << 3,
	CAMEL_MIME_IS_SPACE = 1 << 4,
	CAMEL_MIME_IS_DSPECIAL = 1 << 5,
	CAMEL_MIME_IS_QPSAFE = 1 << 6,
	CAMEL_MIME_IS_ESAFE	= 1 << 7,	/* encoded word safe */
	CAMEL_MIME_IS_PSAFE	= 1 << 8,	/* encoded word in phrase safe */
	CAMEL_MIME_IS_ATTRCHAR  = 1 << 9	/* attribute-char safe (rfc2184) */
};

extern gushort camel_mime_special_table[256];

#define camel_mime_is_ctrl(x) ((camel_mime_special_table[(guchar)(x)] & CAMEL_MIME_IS_CTRL) != 0)
#define camel_mime_is_lwsp(x) ((camel_mime_special_table[(guchar)(x)] & CAMEL_MIME_IS_LWSP) != 0)
#define camel_mime_is_tspecial(x) ((camel_mime_special_table[(guchar)(x)] & CAMEL_MIME_IS_TSPECIAL) != 0)
#define camel_mime_is_type(x, t) ((camel_mime_special_table[(guchar)(x)] & (t)) != 0)
#define camel_mime_is_ttoken(x) ((camel_mime_special_table[(guchar)(x)] & (CAMEL_MIME_IS_TSPECIAL|CAMEL_MIME_IS_LWSP|CAMEL_MIME_IS_CTRL)) == 0)
#define camel_mime_is_atom(x) ((camel_mime_special_table[(guchar)(x)] & (CAMEL_MIME_IS_SPECIAL|CAMEL_MIME_IS_SPACE|CAMEL_MIME_IS_CTRL)) == 0)
#define camel_mime_is_dtext(x) ((camel_mime_special_table[(guchar)(x)] & CAMEL_MIME_IS_DSPECIAL) == 0)
#define camel_mime_is_fieldname(x) ((camel_mime_special_table[(guchar)(x)] & (CAMEL_MIME_IS_CTRL|CAMEL_MIME_IS_SPACE)) == 0)
#define camel_mime_is_qpsafe(x) ((camel_mime_special_table[(guchar)(x)] & CAMEL_MIME_IS_QPSAFE) != 0)
#define camel_mime_is_especial(x) ((camel_mime_special_table[(guchar)(x)] & CAMEL_MIME_IS_ESPECIAL) != 0)
#define camel_mime_is_psafe(x) ((camel_mime_special_table[(guchar)(x)] & CAMEL_MIME_IS_PSAFE) != 0)
#define camel_mime_is_attrchar(x) ((camel_mime_special_table[(guchar)(x)] & CAMEL_MIME_IS_ATTRCHAR) != 0)

G_END_DECLS

#endif /* CAMEL_MIME_UTILS_H */
