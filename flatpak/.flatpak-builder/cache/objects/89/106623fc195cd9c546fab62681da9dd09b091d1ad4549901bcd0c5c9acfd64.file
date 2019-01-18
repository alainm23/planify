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

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include <glib/gi18n-lib.h>

#include "camel-charset-map.h"
#include "camel-iconv.h"
#include "camel-mime-utils.h"
#include "camel-net-utils.h"
#include "camel-network-settings.h"
#ifdef G_OS_WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#ifdef HAVE_WSPIAPI_H
#include <wspiapi.h>
#endif
#endif
#include "camel-sasl-digest-md5.h"

#define d(x)

#define PARANOID(x) x

#define CAMEL_SASL_DIGEST_MD5_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SASL_DIGEST_MD5, CamelSaslDigestMd5Private))

/* Implements rfc2831 */

static CamelServiceAuthType sasl_digest_md5_auth_type = {
	N_("DIGEST-MD5"),

	N_("This option will connect to the server using a "
	   "secure DIGEST-MD5 password, if the server supports it."),

	"DIGEST-MD5",
	TRUE
};

enum {
	STATE_AUTH,
	STATE_FINAL
};

typedef struct {
	const gchar *name;
	guint type;
} DataType;

enum {
	DIGEST_REALM,
	DIGEST_NONCE,
	DIGEST_QOP,
	DIGEST_STALE,
	DIGEST_MAXBUF,
	DIGEST_CHARSET,
	DIGEST_ALGORITHM,
	DIGEST_CIPHER,
	DIGEST_UNKNOWN
};

static DataType digest_args[] = {
	{ "realm",     DIGEST_REALM     },
	{ "nonce",     DIGEST_NONCE     },
	{ "qop",       DIGEST_QOP       },
	{ "stale",     DIGEST_STALE     },
	{ "maxbuf",    DIGEST_MAXBUF    },
	{ "charset",   DIGEST_CHARSET   },
	{ "algorithm", DIGEST_ALGORITHM },
	{ "cipher",    DIGEST_CIPHER    },
	{ NULL,        DIGEST_UNKNOWN   }
};

#define QOP_AUTH           (1 << 0)
#define QOP_AUTH_INT       (1 << 1)
#define QOP_AUTH_CONF      (1 << 2)
#define QOP_INVALID        (1 << 3)

static DataType qop_types[] = {
	{ "auth",      QOP_AUTH      },
	{ "auth-int",  QOP_AUTH_INT  },
	{ "auth-conf", QOP_AUTH_CONF },
	{ NULL,        QOP_INVALID   }
};

#define CIPHER_DES         (1 << 0)
#define CIPHER_3DES        (1 << 1)
#define CIPHER_RC4         (1 << 2)
#define CIPHER_RC4_40      (1 << 3)
#define CIPHER_RC4_56      (1 << 4)
#define CIPHER_INVALID     (1 << 5)

static DataType cipher_types[] = {
	{ "des",    CIPHER_DES     },
	{ "3des",   CIPHER_3DES    },
	{ "rc4",    CIPHER_RC4     },
	{ "rc4-40", CIPHER_RC4_40  },
	{ "rc4-56", CIPHER_RC4_56  },
	{ NULL,     CIPHER_INVALID }
};

struct _param {
	gchar *name;
	gchar *value;
};

struct _DigestChallenge {
	GPtrArray *realms;
	gchar *nonce;
	guint qop;
	gboolean stale;
	gint32 maxbuf;
	gchar *charset;
	gchar *algorithm;
	guint cipher;
	GList *params;
};

struct _DigestURI {
	gchar *type;
	gchar *host;
	gchar *name;
};

struct _DigestResponse {
	gchar *username;
	gchar *realm;
	gchar *nonce;
	gchar *cnonce;
	gchar nc[9];
	guint qop;
	struct _DigestURI *uri;
	gchar resp[33];
	guint32 maxbuf;
	gchar *charset;
	guint cipher;
	gchar *authzid;
	gchar *param;
};

struct _CamelSaslDigestMd5Private {
	struct _DigestChallenge *challenge;
	struct _DigestResponse *response;
	gint state;
};

G_DEFINE_TYPE (CamelSaslDigestMd5, camel_sasl_digest_md5, CAMEL_TYPE_SASL)

static void
decode_lwsp (const gchar **in)
{
	const gchar *inptr = *in;

	while (isspace (*inptr))
		inptr++;

	*in = inptr;
}

static gchar *
decode_quoted_string (const gchar **in)
{
	const gchar *inptr = *in;
	gchar *out = NULL, *outptr;
	gint outlen;
	gint c;

	decode_lwsp (&inptr);
	if (*inptr == '"') {
		const gchar *intmp;
		gint skip = 0;

		/* first, calc length */
		inptr++;
		intmp = inptr;
		while ((c = *intmp++) && c != '"') {
			if (c == '\\' && *intmp) {
				intmp++;
				skip++;
			}
		}

		outlen = intmp - inptr - skip;
		out = outptr = g_malloc (outlen + 1);

		while ((c = *inptr++) && c != '"') {
			if (c == '\\' && *inptr) {
				c = *inptr++;
			}
			*outptr++ = c;
		}
		*outptr = '\0';
	}

	*in = inptr;

	return out;
}

static gchar *
decode_token (const gchar **in)
{
	const gchar *inptr = *in;
	const gchar *start;

	decode_lwsp (&inptr);
	start = inptr;

	while (*inptr && *inptr != '=' && *inptr != ',')
		inptr++;

	if (inptr > start) {
		*in = inptr;
		return g_strndup (start, inptr - start);
	} else {
		return NULL;
	}
}

static gchar *
decode_value (const gchar **in)
{
	const gchar *inptr = *in;

	decode_lwsp (&inptr);
	if (*inptr == '"') {
		d (printf ("decoding quoted string token\n"));
		return decode_quoted_string (in);
	} else {
		d (printf ("decoding string token\n"));
		return decode_token (in);
	}
}

static GList *
parse_param_list (const gchar *tokens)
{
	GList *params = NULL;
	struct _param *param;
	const gchar *ptr;

	for (ptr = tokens; ptr && *ptr; ) {
		param = g_new0 (struct _param, 1);
		param->name = decode_token (&ptr);
		if (*ptr == '=') {
			ptr++;
			param->value = decode_value (&ptr);
		}

		params = g_list_prepend (params, param);

		if (*ptr == ',')
			ptr++;
	}

	return params;
}

static guint
decode_data_type (DataType *dtype,
                  const gchar *name)
{
	gint i;

	for (i = 0; dtype[i].name; i++) {
		if (!g_ascii_strcasecmp (dtype[i].name, name))
			break;
	}

	return dtype[i].type;
}

#define get_digest_arg(name) decode_data_type (digest_args, name)
#define decode_qop(name)     decode_data_type (qop_types, name)
#define decode_cipher(name)  decode_data_type (cipher_types, name)

static const gchar *
type_to_string (DataType *dtype,
                guint type)
{
	gint i;

	for (i = 0; dtype[i].name; i++) {
		if (dtype[i].type == type)
			break;
	}

	return dtype[i].name;
}

#define qop_to_string(type)    type_to_string (qop_types, type)
#define cipher_to_string(type) type_to_string (cipher_types, type)

static void
digest_abort (gboolean *have_type,
              gboolean *abort)
{
	if (*have_type)
		*abort = TRUE;
	*have_type = TRUE;
}

static struct _DigestChallenge *
parse_server_challenge (const gchar *tokens,
                        gboolean *abort)
{
	struct _DigestChallenge *challenge = NULL;
	GList *params, *p;
	const gchar *ptr;
#ifdef PARANOID
	gboolean got_algorithm = FALSE;
	gboolean got_stale = FALSE;
	gboolean got_maxbuf = FALSE;
	gboolean got_charset = FALSE;
#endif /* PARANOID */

	params = parse_param_list (tokens);
	if (!params) {
		*abort = TRUE;
		return NULL;
	}

	*abort = FALSE;

	challenge = g_new0 (struct _DigestChallenge, 1);
	challenge->realms = g_ptr_array_new ();
	challenge->maxbuf = 65536;

	for (p = params; p; p = p->next) {
		struct _param *param = p->data;
		gint type;

		type = get_digest_arg (param->name);
		switch (type) {
		case DIGEST_REALM:
			for (ptr = param->value; ptr && *ptr; ) {
				gchar *token;

				token = decode_token (&ptr);
				if (token)
					g_ptr_array_add (challenge->realms, token);

				if (*ptr == ',')
					ptr++;
			}
			g_free (param->value);
			g_free (param->name);
			g_free (param);
			break;
		case DIGEST_NONCE:
			g_free (challenge->nonce);
			challenge->nonce = param->value;
			g_free (param->name);
			g_free (param);
			break;
		case DIGEST_QOP:
			for (ptr = param->value; ptr && *ptr; ) {
				gchar *token;

				token = decode_token (&ptr);
				if (token)
					challenge->qop |= decode_qop (token);

				if (*ptr == ',')
					ptr++;
			}

			if (challenge->qop & QOP_INVALID)
				challenge->qop = QOP_INVALID;
			g_free (param->value);
			g_free (param->name);
			g_free (param);
			break;
		case DIGEST_STALE:
			PARANOID (digest_abort (&got_stale, abort));
			if (!g_ascii_strcasecmp (param->value, "true"))
				challenge->stale = TRUE;
			else
				challenge->stale = FALSE;
			g_free (param->value);
			g_free (param->name);
			g_free (param);
			break;
		case DIGEST_MAXBUF:
			PARANOID (digest_abort (&got_maxbuf, abort));
			challenge->maxbuf = atoi (param->value);
			g_free (param->value);
			g_free (param->name);
			g_free (param);
			break;
		case DIGEST_CHARSET:
			PARANOID (digest_abort (&got_charset, abort));
			g_free (challenge->charset);
			if (param->value && *param->value)
				challenge->charset = param->value;
			else
				challenge->charset = NULL;
			g_free (param->name);
			g_free (param);
			break;
		case DIGEST_ALGORITHM:
			PARANOID (digest_abort (&got_algorithm, abort));
			g_free (challenge->algorithm);
			challenge->algorithm = param->value;
			g_free (param->name);
			g_free (param);
			break;
		case DIGEST_CIPHER:
			for (ptr = param->value; ptr && *ptr; ) {
				gchar *token;

				token = decode_token (&ptr);
				if (token)
					challenge->cipher |= decode_cipher (token);

				if (*ptr == ',')
					ptr++;
			}
			if (challenge->cipher & CIPHER_INVALID)
				challenge->cipher = CIPHER_INVALID;
			g_free (param->value);
			g_free (param->name);
			g_free (param);
			break;
		default:
			challenge->params = g_list_prepend (challenge->params, param);
			break;
		}
	}

	g_list_free (params);

	return challenge;
}

static gchar *
digest_uri_to_string (struct _DigestURI *uri)
{
	if (uri->name)
		return g_strdup_printf ("%s/%s/%s", uri->type, uri->host, uri->name);
	else
		return g_strdup_printf ("%s/%s", uri->type, uri->host);
}

static void
compute_response (struct _DigestResponse *resp,
                  const gchar *passwd,
                  gboolean client,
                  guchar out[33])
{
	GString *buffer;
	GChecksum *checksum;
	guint8 *digest;
	gsize length;
	gchar *hex_a1;
	gchar *hex_a2;
	gchar *hex_kd;
	gchar *uri;

	buffer = g_string_sized_new (256);
	length = g_checksum_type_get_length (G_CHECKSUM_MD5);
	digest = g_alloca (length);

	/* Compute A1. */

	g_string_append (buffer, resp->username);
	g_string_append_c (buffer, ':');
	g_string_append (buffer, resp->realm);
	g_string_append_c (buffer, ':');
	g_string_append (buffer, passwd);

	checksum = g_checksum_new (G_CHECKSUM_MD5);
	g_checksum_update (
		checksum, (const guchar *) buffer->str, buffer->len);
	g_checksum_get_digest (checksum, digest, &length);
	g_checksum_free (checksum);

	/* Clear the buffer. */
	g_string_truncate (buffer, 0);

	g_string_append_len (buffer, (gchar *) digest, length);
	g_string_append_c (buffer, ':');
	g_string_append (buffer, resp->nonce);
	g_string_append_c (buffer, ':');
	g_string_append (buffer, resp->cnonce);
	if (resp->authzid != NULL) {
		g_string_append_c (buffer, ':');
		g_string_append (buffer, resp->authzid);
	}

	hex_a1 = g_compute_checksum_for_string (
		G_CHECKSUM_MD5, buffer->str, buffer->len);

	/* Clear the buffer. */
	g_string_truncate (buffer, 0);

	/* Compute A2. */

	if (client) {
		/* We are calculating the client response. */
		g_string_append (buffer, "AUTHENTICATE:");
	} else {
		/* We are calculating the server rspauth. */
		g_string_append_c (buffer, ':');
	}

	uri = digest_uri_to_string (resp->uri);
	g_string_append (buffer, uri);
	g_free (uri);

	if (resp->qop == QOP_AUTH_INT || resp->qop == QOP_AUTH_CONF)
		g_string_append (buffer, ":00000000000000000000000000000000");

	hex_a2 = g_compute_checksum_for_string (
		G_CHECKSUM_MD5, buffer->str, buffer->len);

	/* Clear the buffer. */
	g_string_truncate (buffer, 0);

	/* Compute KD. */

	g_string_append (buffer, hex_a1);
	g_string_append_c (buffer, ':');
	g_string_append (buffer, resp->nonce);
	g_string_append_c (buffer, ':');
	g_string_append_len (buffer, resp->nc, 8);
	g_string_append_c (buffer, ':');
	g_string_append (buffer, resp->cnonce);
	g_string_append_c (buffer, ':');
	g_string_append (buffer, qop_to_string (resp->qop));
	g_string_append_c (buffer, ':');
	g_string_append (buffer, hex_a2);

	hex_kd = g_compute_checksum_for_string (
		G_CHECKSUM_MD5, buffer->str, buffer->len);

	g_strlcpy ((gchar *) out, hex_kd, 33);

	g_free (hex_a1);
	g_free (hex_a2);
	g_free (hex_kd);

	g_string_free (buffer, TRUE);
}

static struct _DigestResponse *
generate_response (struct _DigestChallenge *challenge,
                   const gchar *host,
                   const gchar *protocol,
                   const gchar *user,
                   const gchar *passwd)
{
	struct _DigestResponse *resp;
	struct _DigestURI *uri;
	GChecksum *checksum;
	guint8 *digest;
	gsize length;
	gchar *bgen;

	length = g_checksum_type_get_length (G_CHECKSUM_MD5);
	digest = g_alloca (length);

	resp = g_new0 (struct _DigestResponse, 1);
	resp->username = g_strdup (user);
	/* FIXME: we should use the preferred realm */
	if (challenge->realms && challenge->realms->len > 0)
		resp->realm = g_strdup (challenge->realms->pdata[0]);
	else
		resp->realm = g_strdup ("");

	resp->nonce = g_strdup (challenge->nonce);

	/* generate the cnonce */
	bgen = g_strdup_printf (
		"%p:%lu:%lu",
		(gpointer) resp,
		(gulong) getpid (),
		(gulong) time (NULL));
	checksum = g_checksum_new (G_CHECKSUM_MD5);
	g_checksum_update (checksum, (guchar *) bgen, -1);
	g_checksum_get_digest (checksum, digest, &length);
	g_checksum_free (checksum);
	g_free (bgen);

	/* take our recommended 64 bits of entropy */
	resp->cnonce = g_base64_encode ((guchar *) digest, 8);

	/* we don't support re-auth so the nonce count is always 1 */
	g_strlcpy (resp->nc, "00000001", sizeof (resp->nc));

	/* choose the QOP */
	/* FIXME: choose - probably choose "auth" ??? */
	resp->qop = QOP_AUTH;

	/* create the URI */
	uri = g_new0 (struct _DigestURI, 1);
	uri->type = g_strdup (protocol);
	uri->host = g_strdup (host);
	uri->name = NULL;
	resp->uri = uri;

	/* charsets... yay */
	if (challenge->charset) {
		/* I believe that this is only ever allowed to be
		 * UTF-8. We strdup the charset specified by the
		 * challenge anyway, just in case it's not UTF-8.
		 */
		resp->charset = g_strdup (challenge->charset);
	}

	resp->cipher = CIPHER_INVALID;
	if (resp->qop == QOP_AUTH_CONF) {
		/* FIXME: choose a cipher? */
		resp->cipher = CIPHER_INVALID;
	}

	/* we don't really care about this... */
	resp->authzid = NULL;

	compute_response (resp, passwd, TRUE, (guchar *) resp->resp);

	return resp;
}

static GByteArray *
digest_response (struct _DigestResponse *resp)
{
	GByteArray *buffer;
	const gchar *str;
	gchar *buf;

	buffer = g_byte_array_new ();
	g_byte_array_append (buffer, (guint8 *) "username=\"", 10);
	if (resp->charset) {
		/* Encode the username using the requested charset */
		gchar *username, *outbuf;
		const gchar *charset;
		gsize len, outlen;
		const gchar *inbuf;
		GIConv cd;

		charset = camel_iconv_locale_charset ();
		if (!charset)
			charset = "iso-8859-1";

		cd = camel_iconv_open (resp->charset, charset);

		len = strlen (resp->username);
		outlen = 2 * len; /* plenty of space */

		outbuf = username = g_malloc0 (outlen + 1);
		inbuf = resp->username;
		if (cd == (GIConv) -1 || camel_iconv (cd, &inbuf, &len, &outbuf, &outlen) == (gsize) -1) {
			/* We can't convert to UTF-8 - pretend we never got a charset param? */
			g_free (resp->charset);
			resp->charset = NULL;

			/* Set the username to the non-UTF-8 version */
			g_free (username);
			username = g_strdup (resp->username);
		}

		if (cd != (GIConv) -1)
			camel_iconv_close (cd);

		g_byte_array_append (buffer, (guint8 *) username, strlen (username));
		g_free (username);
	} else {
		g_byte_array_append (buffer, (guint8 *) resp->username, strlen (resp->username));
	}

	g_byte_array_append (buffer, (guint8 *) "\",realm=\"", 9);
	g_byte_array_append (buffer, (guint8 *) resp->realm, strlen (resp->realm));

	g_byte_array_append (buffer, (guint8 *) "\",nonce=\"", 9);
	g_byte_array_append (buffer, (guint8 *) resp->nonce, strlen (resp->nonce));

	g_byte_array_append (buffer, (guint8 *) "\",cnonce=\"", 10);
	g_byte_array_append (buffer, (guint8 *) resp->cnonce, strlen (resp->cnonce));

	g_byte_array_append (buffer, (guint8 *) "\",nc=", 5);
	g_byte_array_append (buffer, (guint8 *) resp->nc, 8);

	g_byte_array_append (buffer, (guint8 *) ",qop=", 5);
	str = qop_to_string (resp->qop);
	g_byte_array_append (buffer, (guint8 *) str, strlen (str));

	g_byte_array_append (buffer, (guint8 *) ",digest-uri=\"", 13);
	buf = digest_uri_to_string (resp->uri);
	g_byte_array_append (buffer, (guint8 *) buf, strlen (buf));
	g_free (buf);

	g_byte_array_append (buffer, (guint8 *) "\",response=", 11);
	g_byte_array_append (buffer, (guint8 *) resp->resp, 32);

	if (resp->maxbuf > 0) {
		g_byte_array_append (buffer, (guint8 *) ",maxbuf=", 8);
		buf = g_strdup_printf ("%u", resp->maxbuf);
		g_byte_array_append (buffer, (guint8 *) buf, strlen (buf));
		g_free (buf);
	}

	if (resp->charset) {
		g_byte_array_append (buffer, (guint8 *) ",charset=", 9);
		g_byte_array_append (buffer, (guint8 *) resp->charset, strlen ((gchar *) resp->charset));
	}

	if (resp->cipher != CIPHER_INVALID) {
		str = cipher_to_string (resp->cipher);
		if (str) {
			g_byte_array_append (buffer, (guint8 *) ",cipher=\"", 9);
			g_byte_array_append (buffer, (guint8 *) str, strlen (str));
			g_byte_array_append (buffer, (guint8 *) "\"", 1);
		}
	}

	if (resp->authzid) {
		g_byte_array_append (buffer, (guint8 *) ",authzid=\"", 10);
		g_byte_array_append (buffer, (guint8 *) resp->authzid, strlen (resp->authzid));
		g_byte_array_append (buffer, (guint8 *) "\"", 1);
	}

	return buffer;
}

static void
sasl_digest_md5_finalize (GObject *object)
{
	CamelSaslDigestMd5 *sasl = CAMEL_SASL_DIGEST_MD5 (object);
	struct _DigestChallenge *c = sasl->priv->challenge;
	struct _DigestResponse *r = sasl->priv->response;
	GList *p;
	gint i;

	if (c != NULL) {
		for (i = 0; i < c->realms->len; i++)
			g_free (c->realms->pdata[i]);
		g_ptr_array_free (c->realms, TRUE);

		g_free (c->nonce);
		g_free (c->charset);
		g_free (c->algorithm);
		for (p = c->params; p; p = p->next) {
			struct _param *param = p->data;

			g_free (param->name);
			g_free (param->value);
			g_free (param);
		}
		g_list_free (c->params);
		g_free (c);
	}

	if (r != NULL) {
		g_free (r->username);
		g_free (r->realm);
		g_free (r->nonce);
		g_free (r->cnonce);
		if (r->uri) {
			g_free (r->uri->type);
			g_free (r->uri->host);
		g_free (r->uri->name);
		}
		g_free (r->charset);
		g_free (r->authzid);
		g_free (r->param);
		g_free (r);
	}

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_sasl_digest_md5_parent_class)->finalize (object);
}

static GByteArray *
sasl_digest_md5_challenge_sync (CamelSasl *sasl,
                                GByteArray *token,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelSaslDigestMd5 *sasl_digest = CAMEL_SASL_DIGEST_MD5 (sasl);
	struct _CamelSaslDigestMd5Private *priv = sasl_digest->priv;
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	struct _param *rspauth;
	GByteArray *ret = NULL;
	gboolean abort = FALSE;
	const gchar *ptr;
	guchar out[33];
	gchar *tokens;
	struct addrinfo *ai, hints;
	const gchar *service_name;
	const gchar *password;
	gchar *host;
	gchar *user;

	/* Need to wait for the server */
	if (!token)
		return NULL;

	service = camel_sasl_get_service (sasl);
	service_name = camel_sasl_get_service_name (sasl);

	settings = camel_service_ref_settings (service);
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	g_return_val_if_fail (user != NULL, NULL);

	if (!host || !*host) {
		g_free (host);
		host = g_strdup ("localhost");
	}

	password = camel_service_get_password (service);
	g_return_val_if_fail (password != NULL, NULL);

	switch (priv->state) {
	case STATE_AUTH:
		if (token->len > 2048) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Server challenge too long (>2048 octets)"));
			goto exit;
		}

		tokens = g_strndup ((gchar *) token->data, token->len);
		priv->challenge = parse_server_challenge (tokens, &abort);
		g_free (tokens);
		if (!priv->challenge || abort) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Server challenge invalid\n"));
			goto exit;
		}

		if (priv->challenge->qop == QOP_INVALID) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Server challenge contained invalid "
				"“Quality of Protection” token"));
			goto exit;
		}

		memset (&hints, 0, sizeof (hints));
		hints.ai_flags = AI_CANONNAME;
		ai = camel_getaddrinfo (
			host, NULL, &hints, cancellable, NULL);
		if (ai && ai->ai_canonname)
			ptr = ai->ai_canonname;
		else
			ptr = "localhost.localdomain";

		priv->response = generate_response (
			priv->challenge, ptr, service_name,
			user, password);
		if (ai)
			camel_freeaddrinfo (ai);
		ret = digest_response (priv->response);

		break;
	case STATE_FINAL:
		if (token->len)
			tokens = g_strndup ((gchar *) token->data, token->len);
		else
			tokens = NULL;

		if (!tokens || !*tokens) {
			g_free (tokens);
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Server response did not contain "
				"authorization data"));
			goto exit;
		}

		rspauth = g_new0 (struct _param, 1);

		ptr = tokens;
		rspauth->name = decode_token (&ptr);
		if (*ptr == '=') {
			ptr++;
			rspauth->value = decode_value (&ptr);
		}
		g_free (tokens);

		if (!rspauth->value) {
			g_free (rspauth->name);
			g_free (rspauth);
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Server response contained incomplete "
				"authorization data"));
			goto exit;
		}

		compute_response (priv->response, password, FALSE, out);
		if (memcmp (out, rspauth->value, 32) != 0) {
			g_free (rspauth->name);
			g_free (rspauth->value);
			g_free (rspauth);
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Server response does not match"));
			camel_sasl_set_authenticated (sasl, TRUE);
			goto exit;
		}

		g_free (rspauth->name);
		g_free (rspauth->value);
		g_free (rspauth);

		ret = g_byte_array_new ();

		camel_sasl_set_authenticated (sasl, TRUE);
	default:
		break;
	}

	priv->state++;

exit:
	g_free (host);
	g_free (user);

	return ret;
}

static void
camel_sasl_digest_md5_class_init (CamelSaslDigestMd5Class *class)
{
	GObjectClass *object_class;
	CamelSaslClass *sasl_class;

	g_type_class_add_private (class, sizeof (CamelSaslDigestMd5Private));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = sasl_digest_md5_finalize;

	sasl_class = CAMEL_SASL_CLASS (class);
	sasl_class->auth_type = &sasl_digest_md5_auth_type;
	sasl_class->challenge_sync = sasl_digest_md5_challenge_sync;
}

static void
camel_sasl_digest_md5_init (CamelSaslDigestMd5 *sasl)
{
	sasl->priv = CAMEL_SASL_DIGEST_MD5_GET_PRIVATE (sasl);
}
