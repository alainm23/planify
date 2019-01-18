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
 */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <string.h>

#include <glib/gi18n-lib.h>

#include "camel-network-settings.h"
#include "camel-sasl-ntlm.h"
#include "camel-stream-process.h"

#define CAMEL_SASL_NTLM_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SASL_NTLM, CamelSaslNTLMPrivate))

struct _CamelSaslNTLMPrivate {
	gint placeholder;  /* allow for future expansion */
#ifndef G_OS_WIN32
	gboolean tried_helper;
	CamelStream *helper_stream;
	gchar *type1_msg;
#endif
};

static CamelServiceAuthType sasl_ntlm_auth_type = {
	N_("NTLM / SPA"),

	N_("This option will connect to a Windows-based server using "
	   "NTLM / Secure Password Authentication."),

	"NTLM",
	TRUE
};

G_DEFINE_TYPE (CamelSaslNTLM, camel_sasl_ntlm, CAMEL_TYPE_SASL)

#define NTLM_REQUEST "NTLMSSP\x00\x01\x00\x00\x00\x06\x82\x08\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x30\x00\x00\x00\x00\x00\x00\x00\x30\x00\x00\x00"

#define NTLM_CHALLENGE_DOMAIN_OFFSET		12
#define NTLM_CHALLENGE_FLAGS_OFFSET		20
#define NTLM_CHALLENGE_NONCE_OFFSET		24

#define NTLM_RESPONSE_HEADER         "NTLMSSP\x00\x03\x00\x00\x00"
#define NTLM_RESPONSE_FLAGS          "\x82\x01"
#define NTLM_RESPONSE_BASE_SIZE      64
#define NTLM_RESPONSE_LM_RESP_OFFSET 12
#define NTLM_RESPONSE_NT_RESP_OFFSET 20
#define NTLM_RESPONSE_DOMAIN_OFFSET  28
#define NTLM_RESPONSE_USER_OFFSET    36
#define NTLM_RESPONSE_HOST_OFFSET    44
#define NTLM_RESPONSE_FLAGS_OFFSET   60

#define NTLM_AUTH_HELPER "/usr/bin/ntlm_auth"

typedef struct {
	guint16 length;
	guint16 allocated;
	guint32 offset;
} SecurityBuffer;

static GString *
ntlm_get_string (GByteArray *ba,
                 gint offset)
{
	SecurityBuffer *secbuf;
	GString *string;
	gchar *buf_string;
	guint16 buf_length;
	guint32 buf_offset;

	secbuf = (SecurityBuffer *) &ba->data[offset];
	buf_length = GUINT16_FROM_LE (secbuf->length);
	buf_offset = GUINT32_FROM_LE (secbuf->offset);

	if (ba->len < buf_offset + buf_length)
		return NULL;

	string = g_string_sized_new (buf_length);
	buf_string = (gchar *) &ba->data[buf_offset];
	g_string_append_len (string, buf_string, buf_length);

	return string;
}

static void
ntlm_set_string (GByteArray *ba,
                 gint offset,
                 const gchar *data,
                 gint len)
{
	SecurityBuffer *secbuf;

	secbuf = (SecurityBuffer *) &ba->data[offset];
	secbuf->length = GUINT16_TO_LE (len);
	secbuf->offset = GUINT32_TO_LE (ba->len);
	secbuf->allocated = secbuf->length;

	g_byte_array_append (ba, (guint8 *) data, len);
}

/* MD4 */
static void md4sum                (const guchar *in,
				   gint                  nbytes,
				   guchar        digest[16]);

/* DES */
typedef guint32 DES_KS[16][2]; /* Single-key DES key schedule */

static void deskey                (DES_KS, guchar *, gint);

static void des                   (DES_KS, guchar *);

static void setup_schedule        (const guchar *key_56, DES_KS ks);

#define LM_PASSWORD_MAGIC "\x4B\x47\x53\x21\x40\x23\x24\x25" \
                          "\x4B\x47\x53\x21\x40\x23\x24\x25" \
			  "\x00\x00\x00\x00\x00"

static void
ntlm_lanmanager_hash (const gchar *password,
                      gchar hash[21])
{
	guchar lm_password[15];
	DES_KS ks;
	gint i;

	for (i = 0; i < 14 && password && password[i]; i++)
		lm_password[i] = toupper ((guchar) password[i]);

	for (; i < 15; i++)
		lm_password[i] = '\0';

	memcpy (hash, LM_PASSWORD_MAGIC, 21);

	setup_schedule (lm_password, ks);
	des (ks, (guchar *) hash);

	setup_schedule (lm_password + 7, ks);
	des (ks, (guchar *) hash + 8);
}

static void
ntlm_nt_hash (const gchar *password,
              gchar hash[21])
{
	guchar *buf, *p;

	if (!password)
		password = "";

	p = buf = g_malloc (strlen (password) * 2);

	while (*password) {
		*p++ = *password++;
		*p++ = '\0';
	}

	md4sum (buf, p - buf, (guchar *) hash);
	memset (hash + 16, 0, 5);

	g_free (buf);
}

#define KEYBITS(k,s) \
        (((k[(s) / 8] << ((s) % 8)) & 0xFF) | (k[(s) / 8 + 1] >> (8 - (s) % 8)))

/* DES utils */
/* Set up a key schedule based on a 56bit key */
static void
setup_schedule (const guchar *key_56,
                DES_KS ks)
{
	guchar key[8];
	gint i, c, bit;

	for (i = 0; i < 8; i++) {
		key[i] = KEYBITS (key_56, i * 7);

		/* Fix parity */
		for (c = bit = 0; bit < 8; bit++)
			if (key[i] & (1 << bit))
				c++;
		if (!(c & 1))
			key[i] ^= 0x01;
	}

	deskey (ks, key, 0);
}

static void
ntlm_calc_response (const guchar key[21],
                    const guchar plaintext[8],
                    guchar results[24])
{
	DES_KS ks;

	memcpy (results, plaintext, 8);
	memcpy (results + 8, plaintext, 8);
	memcpy (results + 16, plaintext, 8);

	setup_schedule (key, ks);
	des (ks, results);

	setup_schedule (key + 7, ks);
	des (ks, results + 8);

	setup_schedule (key + 14, ks);
	des (ks, results + 16);
}

/*
 * MD4 encoder. (The one everyone else uses is not GPL-compatible;
 * this is a reimplementation from spec.) This doesn't need to be
 * efficient for our purposes, although it would be nice to fix
 * it to not malloc()...
 */

#define F(X,Y,Z) ( ((X)&(Y)) | ((~(X))&(Z)) )
#define G(X,Y,Z) ( ((X)&(Y)) | ((X)&(Z)) | ((Y)&(Z)) )
#define H(X,Y,Z) ( (X)^(Y)^(Z) )
#define ROT(val, n) ( ((val) << (n)) | ((val) >> (32 - (n))) )

static void
md4sum (const guchar *in,
        gint nbytes,
        guchar digest[16])
{
	guchar *M;
	guint32 A, B, C, D, AA, BB, CC, DD, X[16];
	gint pbytes, nbits = nbytes * 8, i, j;

	/* There is *always* padding of at least one bit. */
	pbytes = ((119 - (nbytes % 64)) % 64) + 1;
	M = alloca (nbytes + pbytes + 8);
	memcpy (M, in, nbytes);
	memset (M + nbytes, 0, pbytes + 8);
	M[nbytes] = 0x80;
	M[nbytes + pbytes] = nbits & 0xFF;
	M[nbytes + pbytes + 1] = (nbits >> 8) & 0xFF;
	M[nbytes + pbytes + 2] = (nbits >> 16) & 0xFF;
	M[nbytes + pbytes + 3] = (nbits >> 24) & 0xFF;

	A = 0x67452301;
	B = 0xEFCDAB89;
	C = 0x98BADCFE;
	D = 0x10325476;

	for (i = 0; i < nbytes + pbytes + 8; i += 64) {
		for (j = 0; j < 16; j++) {
			X[j] = (M[i + j * 4]) |
				(M[i + j * 4 + 1] << 8) |
				(M[i + j * 4 + 2] << 16) |
				(M[i + j * 4 + 3] << 24);
		}

		AA = A;
		BB = B;
		CC = C;
		DD = D;

		A = ROT (A + F (B, C, D) + X[0], 3);
		D = ROT (D + F (A, B, C) + X[1], 7);
		C = ROT (C + F (D, A, B) + X[2], 11);
		B = ROT (B + F (C, D, A) + X[3], 19);
		A = ROT (A + F (B, C, D) + X[4], 3);
		D = ROT (D + F (A, B, C) + X[5], 7);
		C = ROT (C + F (D, A, B) + X[6], 11);
		B = ROT (B + F (C, D, A) + X[7], 19);
		A = ROT (A + F (B, C, D) + X[8], 3);
		D = ROT (D + F (A, B, C) + X[9], 7);
		C = ROT (C + F (D, A, B) + X[10], 11);
		B = ROT (B + F (C, D, A) + X[11], 19);
		A = ROT (A + F (B, C, D) + X[12], 3);
		D = ROT (D + F (A, B, C) + X[13], 7);
		C = ROT (C + F (D, A, B) + X[14], 11);
		B = ROT (B + F (C, D, A) + X[15], 19);

		A = ROT (A + G (B, C, D) + X[0] + 0x5A827999, 3);
		D = ROT (D + G (A, B, C) + X[4] + 0x5A827999, 5);
		C = ROT (C + G (D, A, B) + X[8] + 0x5A827999, 9);
		B = ROT (B + G (C, D, A) + X[12] + 0x5A827999, 13);
		A = ROT (A + G (B, C, D) + X[1] + 0x5A827999, 3);
		D = ROT (D + G (A, B, C) + X[5] + 0x5A827999, 5);
		C = ROT (C + G (D, A, B) + X[9] + 0x5A827999, 9);
		B = ROT (B + G (C, D, A) + X[13] + 0x5A827999, 13);
		A = ROT (A + G (B, C, D) + X[2] + 0x5A827999, 3);
		D = ROT (D + G (A, B, C) + X[6] + 0x5A827999, 5);
		C = ROT (C + G (D, A, B) + X[10] + 0x5A827999, 9);
		B = ROT (B + G (C, D, A) + X[14] + 0x5A827999, 13);
		A = ROT (A + G (B, C, D) + X[3] + 0x5A827999, 3);
		D = ROT (D + G (A, B, C) + X[7] + 0x5A827999, 5);
		C = ROT (C + G (D, A, B) + X[11] + 0x5A827999, 9);
		B = ROT (B + G (C, D, A) + X[15] + 0x5A827999, 13);

		A = ROT (A + H (B, C, D) + X[0] + 0x6ED9EBA1, 3);
		D = ROT (D + H (A, B, C) + X[8] + 0x6ED9EBA1, 9);
		C = ROT (C + H (D, A, B) + X[4] + 0x6ED9EBA1, 11);
		B = ROT (B + H (C, D, A) + X[12] + 0x6ED9EBA1, 15);
		A = ROT (A + H (B, C, D) + X[2] + 0x6ED9EBA1, 3);
		D = ROT (D + H (A, B, C) + X[10] + 0x6ED9EBA1, 9);
		C = ROT (C + H (D, A, B) + X[6] + 0x6ED9EBA1, 11);
		B = ROT (B + H (C, D, A) + X[14] + 0x6ED9EBA1, 15);
		A = ROT (A + H (B, C, D) + X[1] + 0x6ED9EBA1, 3);
		D = ROT (D + H (A, B, C) + X[9] + 0x6ED9EBA1, 9);
		C = ROT (C + H (D, A, B) + X[5] + 0x6ED9EBA1, 11);
		B = ROT (B + H (C, D, A) + X[13] + 0x6ED9EBA1, 15);
		A = ROT (A + H (B, C, D) + X[3] + 0x6ED9EBA1, 3);
		D = ROT (D + H (A, B, C) + X[11] + 0x6ED9EBA1, 9);
		C = ROT (C + H (D, A, B) + X[7] + 0x6ED9EBA1, 11);
		B = ROT (B + H (C, D, A) + X[15] + 0x6ED9EBA1, 15);

		A += AA;
		B += BB;
		C += CC;
		D += DD;
	}

	digest[0] = A & 0xFF;
	digest[1] = (A >> 8) & 0xFF;
	digest[2] = (A >> 16) & 0xFF;
	digest[3] = (A >> 24) & 0xFF;
	digest[4] = B & 0xFF;
	digest[5] = (B >> 8) & 0xFF;
	digest[6] = (B >> 16) & 0xFF;
	digest[7] = (B >> 24) & 0xFF;
	digest[8] = C & 0xFF;
	digest[9] = (C >> 8) & 0xFF;
	digest[10] = (C >> 16) & 0xFF;
	digest[11] = (C >> 24) & 0xFF;
	digest[12] = D & 0xFF;
	digest[13] = (D >> 8) & 0xFF;
	digest[14] = (D >> 16) & 0xFF;
	digest[15] = (D >> 24) & 0xFF;
}

/* Public domain DES implementation from Phil Karn */
static guint32 Spbox[8][64] = {
	{ 0x01010400, 0x00000000, 0x00010000, 0x01010404,
	  0x01010004, 0x00010404, 0x00000004, 0x00010000,
	  0x00000400, 0x01010400, 0x01010404, 0x00000400,
	  0x01000404, 0x01010004, 0x01000000, 0x00000004,
	  0x00000404, 0x01000400, 0x01000400, 0x00010400,
	  0x00010400, 0x01010000, 0x01010000, 0x01000404,
	  0x00010004, 0x01000004, 0x01000004, 0x00010004,
	  0x00000000, 0x00000404, 0x00010404, 0x01000000,
	  0x00010000, 0x01010404, 0x00000004, 0x01010000,
	  0x01010400, 0x01000000, 0x01000000, 0x00000400,
	  0x01010004, 0x00010000, 0x00010400, 0x01000004,
	  0x00000400, 0x00000004, 0x01000404, 0x00010404,
	  0x01010404, 0x00010004, 0x01010000, 0x01000404,
	  0x01000004, 0x00000404, 0x00010404, 0x01010400,
	  0x00000404, 0x01000400, 0x01000400, 0x00000000,
	  0x00010004, 0x00010400, 0x00000000, 0x01010004 },
	{ 0x80108020, 0x80008000, 0x00008000, 0x00108020,
	  0x00100000, 0x00000020, 0x80100020, 0x80008020,
	  0x80000020, 0x80108020, 0x80108000, 0x80000000,
	  0x80008000, 0x00100000, 0x00000020, 0x80100020,
	  0x00108000, 0x00100020, 0x80008020, 0x00000000,
	  0x80000000, 0x00008000, 0x00108020, 0x80100000,
	  0x00100020, 0x80000020, 0x00000000, 0x00108000,
	  0x00008020, 0x80108000, 0x80100000, 0x00008020,
	  0x00000000, 0x00108020, 0x80100020, 0x00100000,
	  0x80008020, 0x80100000, 0x80108000, 0x00008000,
	  0x80100000, 0x80008000, 0x00000020, 0x80108020,
	  0x00108020, 0x00000020, 0x00008000, 0x80000000,
	  0x00008020, 0x80108000, 0x00100000, 0x80000020,
	  0x00100020, 0x80008020, 0x80000020, 0x00100020,
	  0x00108000, 0x00000000, 0x80008000, 0x00008020,
	  0x80000000, 0x80100020, 0x80108020, 0x00108000 },
	{ 0x00000208, 0x08020200, 0x00000000, 0x08020008,
	  0x08000200, 0x00000000, 0x00020208, 0x08000200,
	  0x00020008, 0x08000008, 0x08000008, 0x00020000,
	  0x08020208, 0x00020008, 0x08020000, 0x00000208,
	  0x08000000, 0x00000008, 0x08020200, 0x00000200,
	  0x00020200, 0x08020000, 0x08020008, 0x00020208,
	  0x08000208, 0x00020200, 0x00020000, 0x08000208,
	  0x00000008, 0x08020208, 0x00000200, 0x08000000,
	  0x08020200, 0x08000000, 0x00020008, 0x00000208,
	  0x00020000, 0x08020200, 0x08000200, 0x00000000,
	  0x00000200, 0x00020008, 0x08020208, 0x08000200,
	  0x08000008, 0x00000200, 0x00000000, 0x08020008,
	  0x08000208, 0x00020000, 0x08000000, 0x08020208,
	  0x00000008, 0x00020208, 0x00020200, 0x08000008,
	  0x08020000, 0x08000208, 0x00000208, 0x08020000,
	  0x00020208, 0x00000008, 0x08020008, 0x00020200 },
	{ 0x00802001, 0x00002081, 0x00002081, 0x00000080,
	  0x00802080, 0x00800081, 0x00800001, 0x00002001,
	  0x00000000, 0x00802000, 0x00802000, 0x00802081,
	  0x00000081, 0x00000000, 0x00800080, 0x00800001,
	  0x00000001, 0x00002000, 0x00800000, 0x00802001,
	  0x00000080, 0x00800000, 0x00002001, 0x00002080,
	  0x00800081, 0x00000001, 0x00002080, 0x00800080,
	  0x00002000, 0x00802080, 0x00802081, 0x00000081,
	  0x00800080, 0x00800001, 0x00802000, 0x00802081,
	  0x00000081, 0x00000000, 0x00000000, 0x00802000,
	  0x00002080, 0x00800080, 0x00800081, 0x00000001,
	  0x00802001, 0x00002081, 0x00002081, 0x00000080,
	  0x00802081, 0x00000081, 0x00000001, 0x00002000,
	  0x00800001, 0x00002001, 0x00802080, 0x00800081,
	  0x00002001, 0x00002080, 0x00800000, 0x00802001,
	  0x00000080, 0x00800000, 0x00002000, 0x00802080 },
	{ 0x00000100, 0x02080100, 0x02080000, 0x42000100,
	  0x00080000, 0x00000100, 0x40000000, 0x02080000,
	  0x40080100, 0x00080000, 0x02000100, 0x40080100,
	  0x42000100, 0x42080000, 0x00080100, 0x40000000,
	  0x02000000, 0x40080000, 0x40080000, 0x00000000,
	  0x40000100, 0x42080100, 0x42080100, 0x02000100,
	  0x42080000, 0x40000100, 0x00000000, 0x42000000,
	  0x02080100, 0x02000000, 0x42000000, 0x00080100,
	  0x00080000, 0x42000100, 0x00000100, 0x02000000,
	  0x40000000, 0x02080000, 0x42000100, 0x40080100,
	  0x02000100, 0x40000000, 0x42080000, 0x02080100,
	  0x40080100, 0x00000100, 0x02000000, 0x42080000,
	  0x42080100, 0x00080100, 0x42000000, 0x42080100,
	  0x02080000, 0x00000000, 0x40080000, 0x42000000,
	  0x00080100, 0x02000100, 0x40000100, 0x00080000,
	  0x00000000, 0x40080000, 0x02080100, 0x40000100 },
	{ 0x20000010, 0x20400000, 0x00004000, 0x20404010,
	  0x20400000, 0x00000010, 0x20404010, 0x00400000,
	  0x20004000, 0x00404010, 0x00400000, 0x20000010,
	  0x00400010, 0x20004000, 0x20000000, 0x00004010,
	  0x00000000, 0x00400010, 0x20004010, 0x00004000,
	  0x00404000, 0x20004010, 0x00000010, 0x20400010,
	  0x20400010, 0x00000000, 0x00404010, 0x20404000,
	  0x00004010, 0x00404000, 0x20404000, 0x20000000,
	  0x20004000, 0x00000010, 0x20400010, 0x00404000,
	  0x20404010, 0x00400000, 0x00004010, 0x20000010,
	  0x00400000, 0x20004000, 0x20000000, 0x00004010,
	  0x20000010, 0x20404010, 0x00404000, 0x20400000,
	  0x00404010, 0x20404000, 0x00000000, 0x20400010,
	  0x00000010, 0x00004000, 0x20400000, 0x00404010,
	  0x00004000, 0x00400010, 0x20004010, 0x00000000,
	  0x20404000, 0x20000000, 0x00400010, 0x20004010 },
	{ 0x00200000, 0x04200002, 0x04000802, 0x00000000,
	  0x00000800, 0x04000802, 0x00200802, 0x04200800,
	  0x04200802, 0x00200000, 0x00000000, 0x04000002,
	  0x00000002, 0x04000000, 0x04200002, 0x00000802,
	  0x04000800, 0x00200802, 0x00200002, 0x04000800,
	  0x04000002, 0x04200000, 0x04200800, 0x00200002,
	  0x04200000, 0x00000800, 0x00000802, 0x04200802,
	  0x00200800, 0x00000002, 0x04000000, 0x00200800,
	  0x04000000, 0x00200800, 0x00200000, 0x04000802,
	  0x04000802, 0x04200002, 0x04200002, 0x00000002,
	  0x00200002, 0x04000000, 0x04000800, 0x00200000,
	  0x04200800, 0x00000802, 0x00200802, 0x04200800,
	  0x00000802, 0x04000002, 0x04200802, 0x04200000,
	  0x00200800, 0x00000000, 0x00000002, 0x04200802,
	  0x00000000, 0x00200802, 0x04200000, 0x00000800,
	  0x04000002, 0x04000800, 0x00000800, 0x00200002 },
	{ 0x10001040, 0x00001000, 0x00040000, 0x10041040,
	  0x10000000, 0x10001040, 0x00000040, 0x10000000,
	  0x00040040, 0x10040000, 0x10041040, 0x00041000,
	  0x10041000, 0x00041040, 0x00001000, 0x00000040,
	  0x10040000, 0x10000040, 0x10001000, 0x00001040,
	  0x00041000, 0x00040040, 0x10040040, 0x10041000,
	  0x00001040, 0x00000000, 0x00000000, 0x10040040,
	  0x10000040, 0x10001000, 0x00041040, 0x00040000,
	  0x00041040, 0x00040000, 0x10041000, 0x00001000,
	  0x00000040, 0x10040040, 0x00001000, 0x00041040,
	  0x10001000, 0x00000040, 0x10000040, 0x10040000,
	  0x10040040, 0x10000000, 0x00040000, 0x10001040,
	  0x00000000, 0x10041040, 0x00040040, 0x10000040,
	  0x10040000, 0x10001000, 0x10001040, 0x00000000,
	  0x10041040, 0x00041000, 0x00041000, 0x00001040,
	  0x00001040, 0x00040040, 0x10000000, 0x10041000 }
};

#undef F
#define	F(l,r,key){\
	work = ((r >> 4) | (r << 28)) ^ key[0];\
	l ^= Spbox[6][work & 0x3f];\
	l ^= Spbox[4][(work >> 8) & 0x3f];\
	l ^= Spbox[2][(work >> 16) & 0x3f];\
	l ^= Spbox[0][(work >> 24) & 0x3f];\
	work = r ^ key[1];\
	l ^= Spbox[7][work & 0x3f];\
	l ^= Spbox[5][(work >> 8) & 0x3f];\
	l ^= Spbox[3][(work >> 16) & 0x3f];\
	l ^= Spbox[1][(work >> 24) & 0x3f];\
}

/* Encrypt or decrypt a block of data in ECB mode */
static void
des (guint32 ks[16][2],
     guchar block[8])
{
	guint32 left, right, work;

	/* Read input block and place in left/right in big-endian order */
	left = ((guint32) block[0] << 24)
	 | ((guint32) block[1] << 16)
	 | ((guint32) block[2] << 8)
	 | (guint32) block[3];
	right = ((guint32) block[4] << 24)
	 | ((guint32) block[5] << 16)
	 | ((guint32) block[6] << 8)
	 | (guint32) block[7];

	/* Hoey's clever initial permutation algorithm, from Outerbridge
	 * (see Schneier p 478)
	 *
	 * The convention here is the same as Outerbridge: rotate each
	 * register left by 1 bit, i.e., so that "left" contains permuted
	 * input bits 2, 3, 4, ... 1 and "right" contains 33, 34, 35, ... 32
	 * (using origin-1 numbering as in the FIPS). This allows us to avoid
	 * one of the two rotates that would otherwise be required in each of
	 * the 16 rounds.
	 */
	work = ((left >> 4) ^ right) & 0x0f0f0f0f;
	right ^= work;
	left ^= work << 4;
	work = ((left >> 16) ^ right) & 0xffff;
	right ^= work;
	left ^= work << 16;
	work = ((right >> 2) ^ left) & 0x33333333;
	left ^= work;
	right ^= (work << 2);
	work = ((right >> 8) ^ left) & 0xff00ff;
	left ^= work;
	right ^= (work << 8);
	right = (right << 1) | (right >> 31);
	work = (left ^ right) & 0xaaaaaaaa;
	left ^= work;
	right ^= work;
	left = (left << 1) | (left >> 31);

	/* Now do the 16 rounds */
	F (left,right,ks[0]);
	F (right,left,ks[1]);
	F (left,right,ks[2]);
	F (right,left,ks[3]);
	F (left,right,ks[4]);
	F (right,left,ks[5]);
	F (left,right,ks[6]);
	F (right,left,ks[7]);
	F (left,right,ks[8]);
	F (right,left,ks[9]);
	F (left,right,ks[10]);
	F (right,left,ks[11]);
	F (left,right,ks[12]);
	F (right,left,ks[13]);
	F (left,right,ks[14]);
	F (right,left,ks[15]);

	/* Inverse permutation, also from Hoey via Outerbridge and Schneier */
	right = (right << 31) | (right >> 1);
	work = (left ^ right) & 0xaaaaaaaa;
	left ^= work;
	right ^= work;
	left = (left >> 1) | (left << 31);
	work = ((left >> 8) ^ right) & 0xff00ff;
	right ^= work;
	left ^= work << 8;
	work = ((left >> 2) ^ right) & 0x33333333;
	right ^= work;
	left ^= work << 2;
	work = ((right >> 16) ^ left) & 0xffff;
	left ^= work;
	right ^= work << 16;
	work = ((right >> 4) ^ left) & 0x0f0f0f0f;
	left ^= work;
	right ^= work << 4;

	/* Put the block back into the user's buffer with final swap */
	block[0] = right >> 24;
	block[1] = right >> 16;
	block[2] = right >> 8;
	block[3] = right;
	block[4] = left >> 24;
	block[5] = left >> 16;
	block[6] = left >> 8;
	block[7] = left;
}

/* Key schedule-related tables from FIPS-46 */

/* permuted choice table (key) */
static guchar pc1[] = {
	57, 49, 41, 33, 25, 17,  9,
	 1, 58, 50, 42, 34, 26, 18,
	10,  2, 59, 51, 43, 35, 27,
	19, 11,  3, 60, 52, 44, 36,

	63, 55, 47, 39, 31, 23, 15,
	 7, 62, 54, 46, 38, 30, 22,
	14,  6, 61, 53, 45, 37, 29,
	21, 13,  5, 28, 20, 12,  4
};

/* number left rotations of pc1 */
static guchar totrot[] = {
	1,2,4,6,8,10,12,14,15,17,19,21,23,25,27,28
};

/* permuted choice key (table) */
static guchar pc2[] = {
	14, 17, 11, 24,  1,  5,
	 3, 28, 15,  6, 21, 10,
	23, 19, 12,  4, 26,  8,
	16,  7, 27, 20, 13,  2,
	41, 52, 31, 37, 47, 55,
	30, 40, 51, 45, 33, 48,
	44, 49, 39, 56, 34, 53,
	46, 42, 50, 36, 29, 32
};

/* End of DES-defined tables */

/* bit 0 is left-most in byte */
static gint bytebit[] = {
	0200,0100,040,020,010,04,02,01
};

/* Generate key schedule for encryption or decryption
 * depending on the value of "decrypt"
 */
static void
deskey (DES_KS k,
        guchar *key,
        gint decrypt)
{
	guchar pc1m[56];		/* place to modify pc1 into */
	guchar pcr[56];		/* place to rotate pc1 into */
	register gint i,j,l;
	gint m;
	guchar ks[8];

	for (j=0; j<56; j++) {		/* convert pc1 to bits of key */
		l=pc1[j]-1;		/* integer bit location	 */
		m = l & 07;		/* find bit		 */
		pc1m[j]=(key[l>>3] &	/* find which key byte l is in */
			bytebit[m])	/* and which bit of that byte */
			? 1 : 0;	/* and store 1-bit result */
	}
	for (i=0; i<16; i++) {		/* key chunk for each iteration */
		memset (ks,0,sizeof (ks));	/* Clear key schedule */
		for (j=0; j<56; j++)	/* rotate pc1 the right amount */
			pcr[j] = pc1m[(l = j + totrot[decrypt? 15 - i : i]) < (j < 28? 28 : 56) ? l: l - 28];
			/* rotate left and right halves independently */
		for (j=0; j<48; j++){	/* select bits individually */
			/* check bit that goes to ks[j] */
			if (pcr[pc2[j]-1]) {
				/* mask it in if it's there */
				l= j % 6;
				ks[j / 6] |= bytebit[l] >> 2;
			}
		}
		/* Now convert to packed odd/even interleaved form */
		k[i][0] = ((guint32) ks[0] << 24)
		 | ((guint32) ks[2] << 16)
		 | ((guint32) ks[4] << 8)
		 | ((guint32) ks[6]);
		k[i][1] = ((guint32) ks[1] << 24)
		 | ((guint32) ks[3] << 16)
		 | ((guint32) ks[5] << 8)
		 | ((guint32) ks[7]);
	}
}

static gboolean
sasl_ntlm_try_empty_password_sync (CamelSasl *sasl,
                                   GCancellable *cancellable,
                                   GError **error)
{
#ifndef G_OS_WIN32
	CamelStream *stream;
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	CamelSaslNTLM *ntlm = CAMEL_SASL_NTLM (sasl);
	CamelSaslNTLMPrivate *priv = ntlm->priv;
	const gchar *cp;
	gchar *user;
	gchar buf[1024];
	gsize s;
	gchar *command;
	gint ret;

	if (priv->tried_helper)
		return !!priv->helper_stream;

	priv->tried_helper = TRUE;

	if (access (NTLM_AUTH_HELPER, X_OK))
		return FALSE;

	service = camel_sasl_get_service (sasl);

	settings = camel_service_ref_settings (service);
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), FALSE);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	g_return_val_if_fail (user != NULL, FALSE);

	cp = strchr (user, '\\');
	if (cp != NULL) {
		command = g_strdup_printf (
			"%s --helper-protocol ntlmssp-client-1 "
			"--use-cached-creds --username '%s' "
			"--domain '%.*s'", NTLM_AUTH_HELPER,
			cp + 1, (gint)(cp - user), user);
	} else {
		command = g_strdup_printf (
			"%s --helper-protocol ntlmssp-client-1 "
			"--use-cached-creds --username '%s'",
			NTLM_AUTH_HELPER, user);
	}

	stream = camel_stream_process_new ();

	ret = camel_stream_process_connect (
		CAMEL_STREAM_PROCESS (stream), command, NULL, error);

	g_free (command);
	g_free (user);

	if (ret) {
		g_object_unref (stream);
		return FALSE;
	}

	if (camel_stream_write_string (stream, "YR\n", cancellable, error) < 0) {
		g_object_unref (stream);
		return FALSE;
	}

	s = camel_stream_read (stream, buf, sizeof (buf), cancellable, NULL);
	if (s < 4) {
		g_object_unref (stream);
		return FALSE;
	}

	if (buf[0] != 'Y' || buf[1] != 'R' || buf[2] != ' ' || buf[s - 1] != '\n') {
		g_object_unref (stream);
		return FALSE;
	}

	buf[s - 1] = 0;

	priv->helper_stream = stream;
	priv->type1_msg = g_strdup (buf + 3);
	return TRUE;
#else
	/* Win32 should be able to use SSPI here. */
	return FALSE;
#endif
}

static GByteArray *
sasl_ntlm_challenge_sync (CamelSasl *sasl,
                          GByteArray *token,
                          GCancellable *cancellable,
                          GError **error)
{
#ifndef G_OS_WIN32
	CamelSaslNTLM *ntlm = CAMEL_SASL_NTLM (sasl);
	CamelSaslNTLMPrivate *priv = ntlm->priv;
#endif
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelService *service;
	GByteArray *ret;
	guchar nonce[8], hash[21], lm_resp[24], nt_resp[24];
	GString *domain = NULL;
	const gchar *password;
	const gchar *real_user;
	const gchar *cp;
	gchar *user = NULL;

	service = camel_sasl_get_service (sasl);

	settings = camel_service_ref_settings (service);
	g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	g_return_val_if_fail (user != NULL, NULL);

	password = camel_service_get_password (service);
	/* Assert a non-NULL password below, not here. */

	ret = g_byte_array_new ();

#ifndef G_OS_WIN32
	if (!priv->tried_helper && password == NULL)
		sasl_ntlm_try_empty_password_sync (sasl, cancellable, NULL);

	if (priv->helper_stream && password == NULL) {
		guchar *data;
		gsize length = 0;
		gchar buf[1024];
		gsize s = 0;
		buf[0] = 0;

		if (!token || !token->len) {
			if (priv->type1_msg) {
				data = g_base64_decode (priv->type1_msg, &length);
				g_byte_array_append (ret, data, length);
				g_free (data);
				g_free (priv->type1_msg);
				priv->type1_msg = NULL;
			}
			goto exit;
		} else {
			gchar *type2;
			gchar *string;

			type2 = g_base64_encode (token->data, token->len);
			string = g_strdup_printf ("TT %s\n", type2);
			if (camel_stream_write_string (
				priv->helper_stream, string, NULL, NULL) >= 0 &&
				(s = camel_stream_read (
					priv->helper_stream, buf,
					sizeof (buf), cancellable, NULL)) > 4 &&
				buf[0] == 'K' &&
				buf[1] == 'K' &&
				buf[2] == ' ' &&
				buf[s - 1] == '\n') {
				buf[s - 1] = 0;
				data = g_base64_decode (buf + 3, &length);
				g_byte_array_append (ret, data, length);
				g_free (data);
			} else
				g_warning ("Didn't get valid response from ntlm_auth helper");

			g_free (string);
			g_free (type2);
		}

		/* On failure, we just return an empty string. Setting the
		 * GError would cause the providers to abort the whole
		 * connection, and we want them to ask the user for a password
		 * and continue. */
		g_object_unref (priv->helper_stream);
		priv->helper_stream = NULL;

		goto exit;
	}
#endif

	g_return_val_if_fail (password != NULL, NULL);

	if (!token || token->len < NTLM_CHALLENGE_NONCE_OFFSET + 8)
		goto fail;

	/* 0x00080000: Negotiate NTLM2 Key */
	if (token->data[NTLM_CHALLENGE_FLAGS_OFFSET + 2] & 8) {
		/* NTLM2 session response */
		struct {
			guint32 srv[2];
			guint32 clnt[2];
		} sess_nonce;
		GChecksum *md5;
		guint8 digest[16];
		gsize digest_len = sizeof (digest);

		sess_nonce.clnt[0] = g_random_int ();
		sess_nonce.clnt[1] = g_random_int ();

		/* LM response is 8-byte client nonce, NUL-padded to 24 */
		memcpy (lm_resp, sess_nonce.clnt, 8);
		memset (lm_resp + 8, 0, 16);

		/* Session nonce is client nonce + server nonce */
		memcpy (
			sess_nonce.srv,
			token->data + NTLM_CHALLENGE_NONCE_OFFSET, 8);

		/* Take MD5 of session nonce */
		md5 = g_checksum_new (G_CHECKSUM_MD5);
		g_checksum_update (md5, (gpointer) &sess_nonce, 16);
		g_checksum_get_digest (md5, (gpointer) &digest, &digest_len);
		g_checksum_get_digest (md5, digest, &digest_len);

		g_checksum_free (md5);
		ntlm_nt_hash (password, (gchar *) hash);

		ntlm_calc_response (hash, digest, nt_resp);
	} else {
		/* NTLM1 */
		memcpy (nonce, token->data + NTLM_CHALLENGE_NONCE_OFFSET, 8);
		ntlm_lanmanager_hash (password, (gchar *) hash);
		ntlm_calc_response (hash, nonce, lm_resp);
		ntlm_nt_hash (password, (gchar *) hash);
		ntlm_calc_response (hash, nonce, nt_resp);
	}

	/* If a domain is supplied as part of the username, use it */
	cp = strchr (user, '\\');
	if (cp != NULL) {
		domain = g_string_new_len (user, cp - user);
		real_user = cp + 1;
	} else
		real_user = user;

	/* Otherwise, fall back to the domain of the server, if possible */
	if (domain == NULL)
		domain = ntlm_get_string (token, NTLM_CHALLENGE_DOMAIN_OFFSET);
	if (domain == NULL)
		goto fail;

	/* Don't jump to 'fail' label after this point. */
	g_byte_array_set_size (ret, NTLM_RESPONSE_BASE_SIZE);
	memset (ret->data, 0, NTLM_RESPONSE_BASE_SIZE);
	memcpy (
		ret->data, NTLM_RESPONSE_HEADER,
		sizeof (NTLM_RESPONSE_HEADER) - 1);
	memcpy (
		ret->data + NTLM_RESPONSE_FLAGS_OFFSET,
		NTLM_RESPONSE_FLAGS, sizeof (NTLM_RESPONSE_FLAGS) - 1);
	/* Mask in the NTLM2SESSION flag */
	ret->data[NTLM_RESPONSE_FLAGS_OFFSET + 2] |=
		token->data[NTLM_CHALLENGE_FLAGS_OFFSET + 2] & 8;

	ntlm_set_string (
		ret, NTLM_RESPONSE_DOMAIN_OFFSET,
		domain->str, domain->len);
	ntlm_set_string (
		ret, NTLM_RESPONSE_USER_OFFSET,
		real_user, strlen (real_user));
	ntlm_set_string (
		ret, NTLM_RESPONSE_HOST_OFFSET,
		"UNKNOWN", sizeof ("UNKNOWN") - 1);
	ntlm_set_string (
		ret, NTLM_RESPONSE_LM_RESP_OFFSET,
		(const gchar *) lm_resp, sizeof (lm_resp));
	ntlm_set_string (
		ret, NTLM_RESPONSE_NT_RESP_OFFSET,
		(const gchar *) nt_resp, sizeof (nt_resp));

	camel_sasl_set_authenticated (sasl, TRUE);

	g_string_free (domain, TRUE);

	goto exit;

fail:
	/* If the challenge is malformed, restart authentication.
	 * XXX A malicious server could make this loop indefinitely. */
	g_byte_array_append (
		ret, (guint8 *) NTLM_REQUEST,
		sizeof (NTLM_REQUEST) - 1);

exit:
	g_free (user);

	return ret;
}

static void
sasl_ntlm_finalize (GObject *object)
{
#ifndef G_OS_WIN32
	CamelSaslNTLM *ntlm = CAMEL_SASL_NTLM (object);
	CamelSaslNTLMPrivate *priv = ntlm->priv;

	if (priv->type1_msg)
		g_free (priv->type1_msg);
	if (priv->helper_stream)
		g_object_unref (priv->helper_stream);
#endif
	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_sasl_ntlm_parent_class)->finalize (object);
}

static void
camel_sasl_ntlm_class_init (CamelSaslNTLMClass *class)
{
	GObjectClass *object_class;
	CamelSaslClass *sasl_class;

	g_type_class_add_private (class, sizeof (CamelSaslNTLMPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = sasl_ntlm_finalize;

	sasl_class = CAMEL_SASL_CLASS (class);
	sasl_class->auth_type = &sasl_ntlm_auth_type;
	sasl_class->challenge_sync = sasl_ntlm_challenge_sync;
	sasl_class->try_empty_password_sync = sasl_ntlm_try_empty_password_sync;
}

static void
camel_sasl_ntlm_init (CamelSaslNTLM *sasl)
{
	sasl->priv = CAMEL_SASL_NTLM_GET_PRIVATE (sasl);
}
