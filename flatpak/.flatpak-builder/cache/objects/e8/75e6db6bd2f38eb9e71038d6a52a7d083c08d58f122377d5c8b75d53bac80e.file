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

/* Debug states:
 * gpg:sign	dump canonicalised to-be-signed data to a file
 * gpg:verify	dump canonicalised verification and signature data to file
 * gpg:status	print gpg status-fd output to stdout
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <errno.h>
#include <ctype.h>

#include <glib.h>
#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#ifndef G_OS_WIN32
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <termios.h>
#endif

#include "camel-debug.h"
#include "camel-file-utils.h"
#include "camel-gpg-context.h"
#include "camel-iconv.h"
#include "camel-internet-address.h"
#include "camel-mime-filter-canon.h"
#include "camel-mime-filter-charset.h"
#include "camel-mime-part.h"
#include "camel-multipart-encrypted.h"
#include "camel-multipart-signed.h"
#include "camel-operation.h"
#include "camel-session.h"
#include "camel-stream-filter.h"
#include "camel-stream-fs.h"
#include "camel-stream-mem.h"
#include "camel-stream-null.h"
#include "camel-string-utils.h"

#define d(x)

#ifdef GPG_LOG
static gint logid;
#endif

#define CHECK_CALL(x) G_STMT_START { \
	if ((x) == -1) { \
		g_debug ("%s: Call of '" #x "' failed: %s", G_STRFUNC, g_strerror (errno)); \
	} \
	} G_STMT_END

#define CAMEL_GPG_CONTEXT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_GPG_CONTEXT, CamelGpgContextPrivate))

struct _CamelGpgContextPrivate {
	gboolean always_trust;
	gboolean prefer_inline;
};

enum {
	PROP_0,
	PROP_ALWAYS_TRUST,
	PROP_PREFER_INLINE
};

G_DEFINE_TYPE (CamelGpgContext, camel_gpg_context, CAMEL_TYPE_CIPHER_CONTEXT)

static const gchar *gpg_ctx_get_executable_name (void);

typedef struct _GpgRecipientsData {
	gchar *keyid;
	gchar *known_key_data;
} GpgRecipientsData;

static void
gpg_recipients_data_free (gpointer ptr)
{
	GpgRecipientsData *rd = ptr;

	if (rd) {
		g_free (rd->keyid);
		g_free (rd->known_key_data);
		g_free (rd);
	}
}

enum _GpgCtxMode {
	GPG_CTX_MODE_SIGN,
	GPG_CTX_MODE_VERIFY,
	GPG_CTX_MODE_ENCRYPT,
	GPG_CTX_MODE_DECRYPT
};

enum _GpgTrustMetric {
	GPG_TRUST_NONE,
	GPG_TRUST_NEVER,
	GPG_TRUST_UNDEFINED,
	GPG_TRUST_MARGINAL,
	GPG_TRUST_FULLY,
	GPG_TRUST_ULTIMATE
};

struct _GpgCtx {
	enum _GpgCtxMode mode;
	CamelSession *session;
	GCancellable *cancellable;
	GHashTable *userid_hint;
	pid_t pid;

	GSList *userids;
	gchar *sigfile;
	GPtrArray *recipients; /* GpgRecipientsData * */
	GSList *recipient_key_files; /* gchar * with filenames of keys in the tmp directory */
	CamelCipherHash hash;

	gint stdin_fd;
	gint stdout_fd;
	gint stderr_fd;
	gint status_fd;
	gint passwd_fd;  /* only needed for sign/decrypt */

	/* status-fd buffer */
	guchar *statusbuf;
	guchar *statusptr;
	guint statusleft;

	gchar *need_id;
	gchar *passwd;

	CamelStream *istream;
	CamelStream *ostream;

	GByteArray *diagbuf;
	CamelStream *diagnostics;

	gchar *photos_filename;
	gchar *viewer_cmd;

	GString *decrypt_extra_text; /* Text received during decryption, which is in the blob, but is not encrypted */

	gint exit_status;

	guint exited : 1;
	guint complete : 1;
	guint seen_eof1 : 1;
	guint seen_eof2 : 1;
	guint always_trust : 1;
	guint prefer_inline : 1;
	guint armor : 1;
	guint need_passwd : 1;
	guint send_passwd : 1;
	guint load_photos : 1;

	guint bad_passwds : 2;
	guint anonymous_recipient : 1;

	guint hadsig : 1;
	guint badsig : 1;
	guint errsig : 1;
	guint goodsig : 1;
	guint validsig : 1;
	guint nopubkey : 1;
	guint nodata : 1;
	guint trust : 3;
	guint processing : 1;
	guint bad_decrypt : 1;
	guint in_decrypt_stage : 1;
	guint noseckey : 1;
	GString *signers;
	GHashTable *signers_keyid;

	guint diagflushed : 1;

	guint utf8 : 1;

	guint padding : 10;
};

static struct _GpgCtx *
gpg_ctx_new (CamelCipherContext *context,
	     GCancellable *cancellable)
{
	struct _GpgCtx *gpg;
	const gchar *charset;
	CamelStream *stream;
	CamelSession *session;

	session = camel_cipher_context_get_session (context);

	gpg = g_new (struct _GpgCtx, 1);
	gpg->mode = GPG_CTX_MODE_SIGN;
	gpg->session = g_object_ref (session);
	gpg->cancellable = cancellable;
	gpg->userid_hint = g_hash_table_new (g_str_hash, g_str_equal);
	gpg->complete = FALSE;
	gpg->seen_eof1 = TRUE;
	gpg->seen_eof2 = FALSE;
	gpg->pid = (pid_t) -1;
	gpg->exit_status = 0;
	gpg->exited = FALSE;

	gpg->userids = NULL;
	gpg->sigfile = NULL;
	gpg->recipients = NULL;
	gpg->recipient_key_files = NULL;
	gpg->hash = CAMEL_CIPHER_HASH_DEFAULT;
	gpg->always_trust = FALSE;
	gpg->prefer_inline = FALSE;
	gpg->armor = FALSE;
	gpg->load_photos = FALSE;
	gpg->photos_filename = NULL;
	gpg->viewer_cmd = NULL;

	gpg->stdin_fd = -1;
	gpg->stdout_fd = -1;
	gpg->stderr_fd = -1;
	gpg->status_fd = -1;
	gpg->passwd_fd = -1;

	gpg->statusbuf = g_malloc (128);
	gpg->statusptr = gpg->statusbuf;
	gpg->statusleft = 128;

	gpg->bad_passwds = 0;
	gpg->anonymous_recipient = FALSE;
	gpg->need_passwd = FALSE;
	gpg->send_passwd = FALSE;
	gpg->need_id = NULL;
	gpg->passwd = NULL;

	gpg->nodata = FALSE;
	gpg->hadsig = FALSE;
	gpg->badsig = FALSE;
	gpg->errsig = FALSE;
	gpg->goodsig = FALSE;
	gpg->validsig = FALSE;
	gpg->nopubkey = FALSE;
	gpg->trust = GPG_TRUST_NONE;
	gpg->processing = FALSE;
	gpg->bad_decrypt = FALSE;
	gpg->in_decrypt_stage = FALSE;
	gpg->noseckey = FALSE;
	gpg->signers = NULL;
	gpg->signers_keyid = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, g_free);

	gpg->istream = NULL;
	gpg->ostream = NULL;
	gpg->decrypt_extra_text = NULL;

	gpg->diagbuf = g_byte_array_new ();
	gpg->diagflushed = FALSE;

	stream = camel_stream_mem_new_with_byte_array (gpg->diagbuf);

	if ((charset = camel_iconv_locale_charset ()) && g_ascii_strcasecmp (charset, "UTF-8") != 0) {
		CamelMimeFilter *filter;
		CamelStream *fstream;

		gpg->utf8 = FALSE;

		if ((filter = camel_mime_filter_charset_new (charset, "UTF-8"))) {
			fstream = camel_stream_filter_new (stream);
			camel_stream_filter_add (
				CAMEL_STREAM_FILTER (fstream), filter);
			g_object_unref (filter);
			g_object_unref (stream);

			stream = (CamelStream *) fstream;
		}
	} else {
		gpg->utf8 = TRUE;
	}

	gpg->diagnostics = stream;

	return gpg;
}

static void
gpg_ctx_set_mode (struct _GpgCtx *gpg,
                  enum _GpgCtxMode mode)
{
	gpg->mode = mode;
	gpg->need_passwd = ((gpg->mode == GPG_CTX_MODE_SIGN) || (gpg->mode == GPG_CTX_MODE_DECRYPT));
}

static void
gpg_ctx_set_hash (struct _GpgCtx *gpg,
                  CamelCipherHash hash)
{
	gpg->hash = hash;
}

static void
gpg_ctx_set_always_trust (struct _GpgCtx *gpg,
                          gboolean trust)
{
	gpg->always_trust = trust;
}

static void
gpg_ctx_set_prefer_inline (struct _GpgCtx *gpg,
			   gboolean prefer_inline)
{
	gpg->prefer_inline = prefer_inline;
}

static void
gpg_ctx_set_userid (struct _GpgCtx *gpg,
                    const gchar *userid)
{
	g_slist_free_full (gpg->userids, g_free);
	gpg->userids = NULL;

	if (userid && *userid) {
		gchar **uids = g_strsplit (userid, " ", -1);

		if (!uids) {
			gpg->userids = g_slist_append (gpg->userids, g_strdup (userid));
		} else {
			gint ii;

			for (ii = 0; uids[ii]; ii++) {
				const gchar *uid = uids[ii];

				if (*uid) {
					gpg->userids = g_slist_append (gpg->userids, g_strdup (uid));
				}
			}

			g_strfreev (uids);
		}
	}
}

static void
gpg_ctx_add_recipient (struct _GpgCtx *gpg,
                       const gchar *keyid,
		       const gchar *known_key_data)
{
	GpgRecipientsData *rd;
	gchar *safe_keyid;

	if (gpg->mode != GPG_CTX_MODE_ENCRYPT)
		return;

	if (!gpg->recipients)
		gpg->recipients = g_ptr_array_new ();

	g_return_if_fail (keyid != NULL);

	/* If the recipient looks like an email address,
	 * enclose it in brackets to ensure an exact match. */
	if (strchr (keyid, '@') != NULL) {
		safe_keyid = g_strdup_printf ("<%s>", keyid);
	} else {
		safe_keyid = g_strdup (keyid);
	}

	rd = g_new0 (GpgRecipientsData, 1);
	rd->keyid = safe_keyid;
	rd->known_key_data = g_strdup (known_key_data);

	g_ptr_array_add (gpg->recipients, rd);
}

static void
gpg_ctx_set_sigfile (struct _GpgCtx *gpg,
                     const gchar *sigfile)
{
	g_free (gpg->sigfile);
	gpg->sigfile = g_strdup (sigfile);
}

static void
gpg_ctx_set_armor (struct _GpgCtx *gpg,
                   gboolean armor)
{
	gpg->armor = armor;
}

static void
gpg_ctx_set_load_photos (struct _GpgCtx *gpg,
			 gboolean load_photos)
{
	gpg->load_photos = load_photos;
}

static void
gpg_ctx_set_istream (struct _GpgCtx *gpg,
                     CamelStream *istream)
{
	g_object_ref (istream);
	if (gpg->istream)
		g_object_unref (gpg->istream);
	gpg->istream = istream;
}

static void
gpg_ctx_set_ostream (struct _GpgCtx *gpg,
                     CamelStream *ostream)
{
	g_object_ref (ostream);
	if (gpg->ostream)
		g_object_unref (gpg->ostream);
	gpg->ostream = ostream;
	gpg->seen_eof1 = FALSE;
}

static const gchar *
gpg_ctx_get_diagnostics (struct _GpgCtx *gpg)
{
	if (!gpg->diagflushed) {
		gchar *prefix;

		gpg->diagflushed = TRUE;
		camel_stream_flush (gpg->diagnostics, NULL, NULL);
		if (gpg->diagbuf->len == 0)
			return NULL;

		/* Translators: The '%s' is replaced with the actual path and filename of the used gpg, like '/usr/bin/gpg2' */
		prefix = g_strdup_printf (_("Output from %s:"), gpg_ctx_get_executable_name ());

		if (prefix && *prefix) {
			g_byte_array_prepend (gpg->diagbuf, (const guint8 *) "\n", 1);
			g_byte_array_prepend (gpg->diagbuf, (const guint8 *) prefix, strlen (prefix));
		}

		g_byte_array_append (gpg->diagbuf, (guchar *) "", 1);

		g_free (prefix);
	}

	if (gpg->diagbuf->len == 0)
		return NULL;

	return (const gchar *) gpg->diagbuf->data;
}

static void
userid_hint_free (gpointer key,
                  gpointer value,
                  gpointer user_data)
{
	g_free (key);
	g_free (value);
}

static void
gpg_ctx_free (struct _GpgCtx *gpg)
{
	gint i;

	if (gpg == NULL)
		return;

	if (gpg->session)
		g_object_unref (gpg->session);

	g_hash_table_foreach (gpg->userid_hint, userid_hint_free, NULL);
	g_hash_table_destroy (gpg->userid_hint);

	g_slist_free_full (gpg->userids, g_free);

	g_free (gpg->sigfile);

	if (gpg->recipients) {
		for (i = 0; i < gpg->recipients->len; i++)
			gpg_recipients_data_free (gpg->recipients->pdata[i]);

		g_ptr_array_free (gpg->recipients, TRUE);
	}

	if (gpg->recipient_key_files) {
		GSList *link;

		for (link = gpg->recipient_key_files; link; link = g_slist_next (link)) {
			g_unlink (link->data);
		}

		g_slist_free_full (gpg->recipient_key_files, g_free);
		gpg->recipient_key_files = NULL;
	}

	if (gpg->stdin_fd != -1)
		close (gpg->stdin_fd);
	if (gpg->stdout_fd != -1)
		close (gpg->stdout_fd);
	if (gpg->stderr_fd != -1)
		close (gpg->stderr_fd);
	if (gpg->status_fd != -1)
		close (gpg->status_fd);
	if (gpg->passwd_fd != -1)
		close (gpg->passwd_fd);

	g_free (gpg->statusbuf);

	g_free (gpg->need_id);

	if (gpg->passwd) {
		memset (gpg->passwd, 0, strlen (gpg->passwd));
		g_free (gpg->passwd);
	}

	if (gpg->istream)
		g_object_unref (gpg->istream);

	if (gpg->ostream)
		g_object_unref (gpg->ostream);

	g_object_unref (gpg->diagnostics);

	if (gpg->signers)
		g_string_free (gpg->signers, TRUE);

	g_hash_table_destroy (gpg->signers_keyid);
	if (gpg->photos_filename)
		g_unlink (gpg->photos_filename);

	g_free (gpg->photos_filename);
	g_free (gpg->viewer_cmd);

	if (gpg->decrypt_extra_text)
		g_string_free (gpg->decrypt_extra_text, TRUE);

	g_free (gpg);
}

static const gchar *
gpg_ctx_get_executable_name (void)
{
	static gint index = -1;
	static gchar preset_binary[512 + 1];
	const gchar *names[] = {
		"",
		"gpg2", /* Prefer gpg2, which the seahorse might use too */
		"gpg",
		NULL
	};

	names[0] = preset_binary;

	if (index == -1) {
		GSettings *settings;
		gchar *path;

		settings = g_settings_new ("org.gnome.evolution-data-server");
		path = g_settings_get_string (settings, "camel-gpg-binary");
		g_clear_object (&settings);

		preset_binary[0] = 0;

		if (path && *path && g_file_test (path, G_FILE_TEST_IS_REGULAR)) {
			if (strlen (path) > 512) {
				g_warning ("%s: Path is longer than expected (max 512), ignoring it; value:'%s'", G_STRFUNC, path);
			} else {
				strcpy (preset_binary, path);
			}
		}

		g_free (path);

		for (index = 0; names[index]; index++) {
			if (!*(names[index]))
				continue;

			path = g_find_program_in_path (names[index]);

			if (path) {
				g_free (path);
				break;
			}
		}

		if (!names[index])
			index = 1;
	}

	return names[index];
}

#ifndef G_OS_WIN32

static const gchar *
gpg_hash_str (CamelCipherHash hash)
{
	switch (hash) {
	case CAMEL_CIPHER_HASH_MD2:
		return "--digest-algo=MD2";
	case CAMEL_CIPHER_HASH_MD5:
		return "--digest-algo=MD5";
	case CAMEL_CIPHER_HASH_SHA1:
		return "--digest-algo=SHA1";
	case CAMEL_CIPHER_HASH_SHA256:
		return "--digest-algo=SHA256";
	case CAMEL_CIPHER_HASH_SHA384:
		return "--digest-algo=SHA384";
	case CAMEL_CIPHER_HASH_SHA512:
		return "--digest-algo=SHA512";
	case CAMEL_CIPHER_HASH_RIPEMD160:
		return "--digest-algo=RIPEMD160";
	default:
		return NULL;
	}
}

static GPtrArray *
gpg_ctx_get_argv (struct _GpgCtx *gpg,
                  gint status_fd,
                  gchar **sfd,
                  gint passwd_fd,
                  gchar **pfd)
{
	const gchar *hash_str;
	GPtrArray *argv;
	gchar *buf;
	gint i;

	argv = g_ptr_array_new ();
	g_ptr_array_add (argv, (guint8 *) gpg_ctx_get_executable_name ());

	g_ptr_array_add (argv, (guint8 *) "--verbose");
	g_ptr_array_add (argv, (guint8 *) "--no-secmem-warning");
	g_ptr_array_add (argv, (guint8 *) "--no-greeting");
	g_ptr_array_add (argv, (guint8 *) "--no-tty");

	if (passwd_fd == -1) {
		/* only use batch mode if we don't intend on using the
		 * interactive --command-fd option */
		g_ptr_array_add (argv, (guint8 *) "--batch");
		g_ptr_array_add (argv, (guint8 *) "--yes");
	}

	*sfd = buf = g_strdup_printf ("--status-fd=%d", status_fd);
	g_ptr_array_add (argv, buf);

	if (passwd_fd != -1) {
		*pfd = buf = g_strdup_printf ("--command-fd=%d", passwd_fd);
		g_ptr_array_add (argv, buf);
	}

	if (gpg->load_photos) {
		if (!gpg->viewer_cmd) {
			gint filefd;

			filefd = g_file_open_tmp ("camel-gpg-photo-state-XXXXXX", &gpg->photos_filename, NULL);
			if (filefd) {
				gchar *viewer_filename;

				close (filefd);

				viewer_filename = g_build_filename (CAMEL_LIBEXECDIR, "camel-gpg-photo-saver", NULL);
				gpg->viewer_cmd = g_strdup_printf ("%s --state \"%s\" --photo \"%%i\" --keyid \"%%K\" --type \"%%t\"", viewer_filename, gpg->photos_filename);
				g_free (viewer_filename);
			}
		}

		if (gpg->viewer_cmd) {
			g_ptr_array_add (argv, (guint8 *) "--verify-options");
			g_ptr_array_add (argv, (guint8 *) "show-photos");

			g_ptr_array_add (argv, (guint8 *) "--photo-viewer");
			g_ptr_array_add (argv, (guint8 *) gpg->viewer_cmd);
		}
	}

	switch (gpg->mode) {
	case GPG_CTX_MODE_SIGN:
		if (gpg->prefer_inline) {
			g_ptr_array_add (argv, (guint8 *) "--clearsign");
		} else {
			g_ptr_array_add (argv, (guint8 *) "--sign");
			g_ptr_array_add (argv, (guint8 *) "--detach");
			if (gpg->armor)
				g_ptr_array_add (argv, (guint8 *) "--armor");
		}
		hash_str = gpg_hash_str (gpg->hash);
		if (hash_str)
			g_ptr_array_add (argv, (guint8 *) hash_str);
		if (gpg->userids) {
			GSList *uiter;

			for (uiter = gpg->userids; uiter; uiter = uiter->next) {
				g_ptr_array_add (argv, (guint8 *) "-u");
				g_ptr_array_add (argv, (guint8 *) uiter->data);
			}
		}
		g_ptr_array_add (argv, (guint8 *) "--output");
		g_ptr_array_add (argv, (guint8 *) "-");
		break;
	case GPG_CTX_MODE_VERIFY:
		if (!camel_session_get_online (gpg->session)) {
			/* this is a deprecated flag to gpg since 1.0.7 */
			/*g_ptr_array_add (argv, "--no-auto-key-retrieve");*/
			g_ptr_array_add (argv, (guint8 *) "--keyserver-options");
			g_ptr_array_add (argv, (guint8 *) "no-auto-key-retrieve");
		}
		g_ptr_array_add (argv, (guint8 *) "--verify");
		if (gpg->sigfile)
			g_ptr_array_add (argv, gpg->sigfile);
		g_ptr_array_add (argv, (guint8 *) "-");
		break;
	case GPG_CTX_MODE_ENCRYPT:
		g_ptr_array_add (argv, (guint8 *) "--encrypt");
		if (gpg->armor || gpg->prefer_inline)
			g_ptr_array_add (argv, (guint8 *) "--armor");
		if (gpg->always_trust)
			g_ptr_array_add (argv, (guint8 *) "--always-trust");
		if (gpg->userids) {
			GSList *uiter;

			for (uiter = gpg->userids; uiter; uiter = uiter->next) {
				g_ptr_array_add (argv, (guint8 *) "-u");
				g_ptr_array_add (argv, (guint8 *) uiter->data);
			}
		}
		if (gpg->recipients) {
			for (i = 0; i < gpg->recipients->len; i++) {
				const GpgRecipientsData *rd = gpg->recipients->pdata[i];
				gboolean add_with_keyid = TRUE;

				if (!rd)
					continue;

				if (rd->known_key_data && *(rd->known_key_data)) {
					gsize len = 0;
					guchar *data;

					data = g_base64_decode (rd->known_key_data, &len);
					if (data && len) {
						gchar *filename = NULL;
						gint filefd;

						filefd = g_file_open_tmp ("camel-gpg-key-XXXXXX", &filename, NULL);
						if (filefd) {
							gpg->recipient_key_files = g_slist_prepend (gpg->recipient_key_files, filename);

							if (camel_write (filefd, (const gchar *) data, len, gpg->cancellable, NULL) == len) {
								add_with_keyid = FALSE;
								g_ptr_array_add (argv, (guint8 *) "--recipient-file");
								g_ptr_array_add (argv, (guint8 *) filename);
							}

							close (filefd);
						}
					}

					g_free (data);
				}

				if (add_with_keyid) {
					g_ptr_array_add (argv, (guint8 *) "-r");
					g_ptr_array_add (argv, rd->keyid);
				}
			}
		}
		g_ptr_array_add (argv, (guint8 *) "--output");
		g_ptr_array_add (argv, (guint8 *) "-");
		break;
	case GPG_CTX_MODE_DECRYPT:
		g_ptr_array_add (argv, (guint8 *) "--decrypt");
		g_ptr_array_add (argv, (guint8 *) "--output");
		g_ptr_array_add (argv, (guint8 *) "-");
		break;
	}

	g_ptr_array_add (argv, NULL);

	return argv;
}

#endif

static gboolean
gpg_ctx_op_start (struct _GpgCtx *gpg,
                  GError **error)
{
#ifndef G_OS_WIN32
	gchar *status_fd = NULL, *passwd_fd = NULL;
	gint i, maxfd, errnosave, fds[10];
	GPtrArray *argv;
	gint flags;

	for (i = 0; i < 10; i++)
		fds[i] = -1;

	maxfd = gpg->need_passwd ? 10 : 8;
	for (i = 0; i < maxfd; i += 2) {
		if (pipe (fds + i) == -1)
			goto exception;
	}

	argv = gpg_ctx_get_argv (gpg, fds[7], &status_fd, fds[8], &passwd_fd);

	if (!(gpg->pid = fork ())) {
		/* child process */

		if ((dup2 (fds[0], STDIN_FILENO) < 0 ) ||
		    (dup2 (fds[3], STDOUT_FILENO) < 0 ) ||
		    (dup2 (fds[5], STDERR_FILENO) < 0 )) {
			_exit (255);
		}

		/* Dissociate from camel's controlling terminal so
		 * that gpg won't be able to read from it.
		 */
		setsid ();

		maxfd = sysconf (_SC_OPEN_MAX);
		/* Loop over all fds. */
		for (i = 3; i < maxfd; i++) {
			/* don't close the status-fd or passwd-fd */
			if (i != fds[7] && i != fds[8]) {
				if (fcntl (i, F_SETFD, FD_CLOEXEC) == -1) {
					/* Do nothing here. Cannot use CHECK_CALL() macro here, because
					   it makes the process stuck, possibly due to the debug print. */
				}
			}
		}

		/* run gpg */
		execvp (gpg_ctx_get_executable_name (), (gchar **) argv->pdata);
		_exit (255);
	} else if (gpg->pid < 0) {
		g_ptr_array_free (argv, TRUE);
		g_free (status_fd);
		g_free (passwd_fd);
		goto exception;
	}

	g_ptr_array_free (argv, TRUE);
	g_free (status_fd);
	g_free (passwd_fd);

	/* Parent */
	close (fds[0]);
	gpg->stdin_fd = fds[1];
	gpg->stdout_fd = fds[2];
	close (fds[3]);
	gpg->stderr_fd = fds[4];
	close (fds[5]);
	gpg->status_fd = fds[6];
	close (fds[7]);

	if (gpg->need_passwd) {
		close (fds[8]);
		gpg->passwd_fd = fds[9];
		flags = fcntl (gpg->passwd_fd, F_GETFL);
		CHECK_CALL (fcntl (gpg->passwd_fd, F_SETFL, flags | O_NONBLOCK));
	}

	flags = fcntl (gpg->stdin_fd, F_GETFL);
	CHECK_CALL (fcntl (gpg->stdin_fd, F_SETFL, flags | O_NONBLOCK));

	flags = fcntl (gpg->stdout_fd, F_GETFL);
	CHECK_CALL (fcntl (gpg->stdout_fd, F_SETFL, flags | O_NONBLOCK));

	flags = fcntl (gpg->stderr_fd, F_GETFL);
	CHECK_CALL (fcntl (gpg->stderr_fd, F_SETFL, flags | O_NONBLOCK));

	flags = fcntl (gpg->status_fd, F_GETFL);
	CHECK_CALL (fcntl (gpg->status_fd, F_SETFL, flags | O_NONBLOCK));

	return TRUE;

exception:

	errnosave = errno;

	for (i = 0; i < 10; i++) {
		if (fds[i] != -1)
			close (fds[i]);
	}

	errno = errnosave;
#else
	/* FIXME: Port me */
	g_warning ("%s: Not implemented", G_STRFUNC);

	errno = EINVAL;
#endif

	if (errno != 0)
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Failed to execute gpg: %s"),
			g_strerror (errno));
	else
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Failed to execute gpg: %s"), _("Unknown"));

	return FALSE;
}

#ifndef G_OS_WIN32

static const gchar *
next_token (const gchar *in,
            gchar **token)
{
	const gchar *start, *inptr = in;

	while (*inptr == ' ')
		inptr++;

	if (*inptr == '\0' || *inptr == '\n') {
		if (token)
			*token = NULL;
		return inptr;
	}

	start = inptr;
	while (*inptr && *inptr != ' ' && *inptr != '\n')
		inptr++;

	if (token)
		*token = g_strndup (start, inptr - start);

	return inptr;
}

static void
gpg_ctx_extract_signer_from_status (struct _GpgCtx *gpg,
				    const gchar *status)
{
	const gchar *tmp;

	g_return_if_fail (gpg != NULL);
	g_return_if_fail (status != NULL);

	/* there's a key ID, then the email address */
	tmp = status;

	status = strchr (status, ' ');
	if (status) {
		gchar *keyid;
		const gchar *str = status + 1;
		const gchar *eml = strchr (str, '<');

		keyid = g_strndup (tmp, status - tmp);

		if (eml && eml > str) {
			eml--;
			if (strchr (str, ' ') >= eml)
				eml = NULL;
		} else {
			eml = NULL;
		}

		if (gpg->signers) {
			g_string_append (gpg->signers, ", ");
		} else {
			gpg->signers = g_string_new ("");
		}

		if (eml) {
			g_string_append (gpg->signers, "\"");
			g_string_append_len (gpg->signers, str, eml - str);
			g_string_append (gpg->signers, "\"");
			g_string_append (gpg->signers, eml);
		} else {
			g_string_append (gpg->signers, str);
		}

		g_hash_table_insert (gpg->signers_keyid, g_strdup (str), keyid);
	}
}

static gint
gpg_ctx_parse_status (struct _GpgCtx *gpg,
                      GError **error)
{
	register guchar *inptr;
	const guchar *status;
	gsize nread, nwritten;
	gint len;

 parse:

	inptr = gpg->statusbuf;
	while (inptr < gpg->statusptr && *inptr != '\n')
		inptr++;

	if (*inptr != '\n') {
		/* we don't have enough data buffered to parse this status line */
		return 0;
	}

	*inptr++ = '\0';
	status = gpg->statusbuf;

	if (camel_debug ("gpg:status"))
		printf ("status: %s\n", status);

	if (strncmp ((const gchar *) status, "[GNUPG:] ", 9) != 0) {
		gchar *message;

		message = g_locale_to_utf8 (
			(const gchar *) status, -1, NULL, NULL, NULL);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Unexpected GnuPG status message encountered:\n\n%s"),
			message);
		g_free (message);

		return -1;
	}

	status += 9;

	if (!strncmp ((gchar *) status, "ENC_TO ", 7)) {
		gchar *key = NULL;

		status += 7;

		next_token ((gchar *) status, &key);
		if (key) {
			gboolean all_zero = *key == '0';
			gint i = 0;

			while (key[i] && all_zero) {
				all_zero = key[i] == '0';
				i++;
			}

			gpg->anonymous_recipient = all_zero;

			g_free (key);
		}
	} else if (!strncmp ((gchar *) status, "USERID_HINT ", 12)) {
		gchar *hint, *user;

		status += 12;
		status = (const guchar *) next_token ((gchar *) status, &hint);
		if (!hint) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Failed to parse gpg userid hint."));
			return -1;
		}

		if (g_hash_table_lookup (gpg->userid_hint, hint)) {
			/* we already have this userid hint... */
			g_free (hint);
			goto recycle;
		}

		if (gpg->utf8 || !(user = g_locale_to_utf8 ((gchar *) status, -1, &nread, &nwritten, NULL)))
			user = g_strdup ((gchar *) status);

		g_strstrip (user);

		g_hash_table_insert (gpg->userid_hint, hint, user);
	} else if (!strncmp ((gchar *) status, "NEED_PASSPHRASE ", 16)) {
		gchar *userid;

		status += 16;

		next_token ((gchar *) status, &userid);
		if (!userid) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Failed to parse gpg passphrase request."));
			return -1;
		}

		g_free (gpg->need_id);
		gpg->need_id = userid;
	} else if (!strncmp ((gchar *) status, "NEED_PASSPHRASE_PIN ", 20)) {
		gchar *userid;

		status += 20;

		next_token ((gchar *) status, &userid);
		if (!userid) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Failed to parse gpg passphrase request."));
			return -1;
		}

		g_free (gpg->need_id);
		gpg->need_id = userid;
	} else if (!strncmp ((gchar *) status, "GET_HIDDEN ", 11)) {
		const gchar *name = NULL;
		gchar *prompt, *passwd;
		guint32 flags;
		GError *local_error = NULL;

		status += 11;

		if (gpg->need_id && !(name = g_hash_table_lookup (gpg->userid_hint, gpg->need_id)))
			name = gpg->need_id;
		else if (!name)
			name = "";

		if (!strncmp ((gchar *) status, "passphrase.pin.ask", 18)) {
			prompt = g_markup_printf_escaped (
				_("You need a PIN to unlock the key for your\n"
				"SmartCard: “%s”"), name);
		} else if (!strncmp ((gchar *) status, "passphrase.enter", 16)) {
			prompt = g_markup_printf_escaped (
				_("You need a passphrase to unlock the key for\n"
				"user: “%s”"), name);
		} else {
			next_token ((gchar *) status, &prompt);
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Unexpected request from GnuPG for “%s”"),
				prompt);
			g_free (prompt);
			return -1;
		}

		if (gpg->anonymous_recipient) {
			gchar *tmp = prompt;

			/* FIXME Reword prompt message. */
			prompt = g_strconcat (
				tmp, "\n",
				_("Note the encrypted content doesn’t contain "
				"information about a recipient, thus there "
				"will be a password prompt for each of stored "
				"private key."), NULL);

			g_free (tmp);
		}

		flags = CAMEL_SESSION_PASSWORD_SECRET | CAMEL_SESSION_PASSPHRASE;
		if ((passwd = camel_session_get_password (gpg->session, NULL, prompt, gpg->need_id, flags, &local_error))) {
			if (!gpg->utf8) {
				gchar *opasswd = passwd;

				if ((passwd = g_locale_to_utf8 (passwd, -1, &nread, &nwritten, NULL))) {
					memset (opasswd, 0, strlen (opasswd));
					g_free (opasswd);
				} else {
					passwd = opasswd;
				}
			}

			gpg->passwd = g_strdup_printf ("%s\n", passwd);
			memset (passwd, 0, strlen (passwd));
			g_free (passwd);

			gpg->send_passwd = TRUE;
		} else {
			if (local_error == NULL)
				g_set_error (
					error, G_IO_ERROR,
					G_IO_ERROR_CANCELLED,
					_("Cancelled"));
			g_propagate_error (error, local_error);

			return -1;
		}

		g_free (prompt);
	} else if (!strncmp ((gchar *) status, "GOOD_PASSPHRASE", 15)) {
		gpg->bad_passwds = 0;
	} else if (!strncmp ((gchar *) status, "BAD_PASSPHRASE", 14)) {
		/* with anonymous recipient is user asked for his/her password for each stored key,
		 * thus here cannot be counted wrong passwords */
		if (!gpg->anonymous_recipient) {
			gpg->bad_passwds++;

			camel_session_forget_password (gpg->session, NULL, gpg->need_id, error);

			if (gpg->bad_passwds == 3) {
				g_set_error (
					error, CAMEL_SERVICE_ERROR,
					CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
					_("Failed to unlock secret key: "
					"3 bad passphrases given."));
				return -1;
			}
		}
	} else if (!strncmp ((const gchar *) status, "UNEXPECTED ", 11)) {
		/* this is an error */
		gchar *message;

		message = g_locale_to_utf8 (
			(const gchar *) status + 11, -1, NULL, NULL, NULL);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Unexpected response from GnuPG: %s"), message);
		g_free (message);

		return -1;
	} else if (!strncmp ((gchar *) status, "NODATA", 6)) {
		/* this is an error */
		/* But we ignore it anyway, we should get other response codes to say why */
		gpg->nodata = TRUE;
	} else {
		if (!strncmp ((gchar *) status, "BEGIN_", 6)) {
			gpg->processing = TRUE;
		} else if (!strncmp ((gchar *) status, "END_", 4)) {
			gpg->processing = FALSE;
		}

		/* check to see if we are complete */
		switch (gpg->mode) {
		case GPG_CTX_MODE_SIGN:
			if (!strncmp ((gchar *) status, "SIG_CREATED ", 12)) {
				/* SIG_CREATED <type> <pubkey algo> <hash algo> <class> <timestamp> <key fpr> */
				const gchar *str, *p;
				gint i = 0;

				str = (const gchar *) status + 12;
				while (p = strchr (str, ' '), i < 2 && p) {
					str = p + 1;
					i++;
				}

				if (*str && i == 2) {
					struct {
						gint gpg_hash_algo;
						CamelCipherHash camel_hash_algo;
					} hash_algos[] = {
						/* the rest are deprecated/not supported by gpg any more */
						{  2, CAMEL_CIPHER_HASH_SHA1 },
						{  3, CAMEL_CIPHER_HASH_RIPEMD160 },
						{  8, CAMEL_CIPHER_HASH_SHA256 },
						{  9, CAMEL_CIPHER_HASH_SHA384 },
						{ 10, CAMEL_CIPHER_HASH_SHA512 }
					};

					gint gpg_hash = strtoul (str, NULL, 10);

					for (i = 0; i < G_N_ELEMENTS (hash_algos); i++) {
						if (hash_algos[i].gpg_hash_algo == gpg_hash) {
							gpg->hash = hash_algos[i].camel_hash_algo;
							break;
						}
					}
				}
			}
			break;
		case GPG_CTX_MODE_DECRYPT:
			if (!strncmp ((gchar *) status, "BEGIN_DECRYPTION", 16)) {
				gpg->bad_decrypt = FALSE;
				/* Mark it's expected to get decrypted data on stdout */
				gpg->in_decrypt_stage = TRUE;
				break;
			} else if (!strncmp ((gchar *) status, "END_DECRYPTION", 14)) {
				/* Mark to no longer expect decrypted data */
				gpg->in_decrypt_stage = FALSE;
				break;
			} else if (!strncmp ((gchar *) status, "NO_SECKEY ", 10)) {
				gpg->noseckey = TRUE;
				break;
			} else if (!strncmp ((gchar *) status, "DECRYPTION_FAILED", 17)) {
				gpg->bad_decrypt = TRUE;
				break;
			}
			/* let if fall through to verify possible signatures too */
			/* break; */
			/* falls through */
		case GPG_CTX_MODE_VERIFY:
			if (!strncmp ((gchar *) status, "TRUST_", 6)) {
				status += 6;
				if (!strncmp ((gchar *) status, "NEVER", 5)) {
					gpg->trust = GPG_TRUST_NEVER;
				} else if (!strncmp ((gchar *) status, "MARGINAL", 8)) {
					gpg->trust = GPG_TRUST_MARGINAL;
				} else if (!strncmp ((gchar *) status, "FULLY", 5)) {
					gpg->trust = GPG_TRUST_FULLY;
				} else if (!strncmp ((gchar *) status, "ULTIMATE", 8)) {
					gpg->trust = GPG_TRUST_ULTIMATE;
				} else if (!strncmp ((gchar *) status, "UNDEFINED", 9)) {
					gpg->trust = GPG_TRUST_UNDEFINED;
				}
			} else if (!strncmp ((gchar *) status, "GOODSIG ", 8)) {
				gpg->goodsig = TRUE;
				gpg->hadsig = TRUE;

				gpg_ctx_extract_signer_from_status (gpg, (const gchar *) status + 8);
			} else if (!strncmp ((gchar *) status, "EXPKEYSIG ", 10)) {
				gpg_ctx_extract_signer_from_status (gpg, (const gchar *) status + 10);
			} else if (!strncmp ((gchar *) status, "VALIDSIG ", 9)) {
				gpg->validsig = TRUE;
			} else if (!strncmp ((gchar *) status, "BADSIG ", 7)) {
				gpg->badsig = FALSE;
				gpg->hadsig = TRUE;

				gpg_ctx_extract_signer_from_status (gpg, (const gchar *) status + 7);
			} else if (!strncmp ((gchar *) status, "ERRSIG ", 7)) {
				/* Note: NO_PUBKEY often comes after an ERRSIG */
				gpg->errsig = FALSE;
				gpg->hadsig = TRUE;
			} else if (!strncmp ((gchar *) status, "NO_PUBKEY ", 10)) {
				gpg->nopubkey = TRUE;
			}
			break;
		case GPG_CTX_MODE_ENCRYPT:
			if (!strncmp ((gchar *) status, "BEGIN_ENCRYPTION", 16)) {
				/* nothing to do... but we know to expect data on stdout soon */
			} else if (!strncmp ((gchar *) status, "END_ENCRYPTION", 14)) {
				/* nothing to do, but we know the end is near? */
			} else if (!strncmp ((gchar *) status, "NO_RECP", 7)) {
				g_set_error (
					error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
					_("Failed to encrypt: No valid recipients specified."));
				return -1;
			} else if (!strncmp ((gchar *) status, "INV_RECP ", 9)) {
				const gchar *addr;

				addr = strchr ((gchar *) status, '<');
				if (!addr)
					addr = ((gchar *) status) + 10;

				g_set_error (
					error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
					/* Translators: The first '%s' is replaced with the e-mail address, like '<user@example.com>';
					   the second '%s' is replaced with the actual path and filename of the used gpg, like '/usr/bin/gpg2' */
					_("Failed to encrypt: Invalid recipient %s specified. A common issue is that the %s doesn’t have imported public key for this recipient."),
					addr, gpg_ctx_get_executable_name ());
				return -1;
			}
			break;
		}
	}

 recycle:

	/* recycle our statusbuf by moving inptr to the beginning of statusbuf */
	len = gpg->statusptr - inptr;
	memmove (gpg->statusbuf, inptr, len);

	len = inptr - gpg->statusbuf;
	gpg->statusleft += len;
	gpg->statusptr -= len;

	/* if we have more data, try parsing the next line? */
	if (gpg->statusptr > gpg->statusbuf)
		goto parse;

	return 0;
}

#endif

#define status_backup(gpg, start, len) G_STMT_START { \
	if (gpg->statusleft <= len) { \
		guint slen, soff; \
 \
		slen = soff = gpg->statusptr - gpg->statusbuf; \
		slen = slen ? slen : 1; \
 \
		while (slen < soff + len) \
			slen <<= 1; \
 \
		gpg->statusbuf = g_realloc (gpg->statusbuf, slen + 1); \
		gpg->statusptr = gpg->statusbuf + soff; \
		gpg->statusleft = slen - soff; \
	} \
 \
	memcpy (gpg->statusptr, start, len); \
	gpg->statusptr += len; \
	gpg->statusleft -= len; \
} G_STMT_END

static void
gpg_ctx_op_cancel (struct _GpgCtx *gpg)
{
#ifndef G_OS_WIN32
	pid_t retval;
	gint status;

	if (gpg->exited)
		return;

	kill (gpg->pid, SIGTERM);
	sleep (1);
	retval = waitpid (gpg->pid, &status, WNOHANG);

	if (retval == (pid_t) 0) {
		/* no more mr nice guy... */
		kill (gpg->pid, SIGKILL);
		sleep (1);
		waitpid (gpg->pid, &status, WNOHANG);
	}
#endif
}

static gint
gpg_ctx_op_step (struct _GpgCtx *gpg,
                 GCancellable *cancellable,
                 GError **error)
{
#ifndef G_OS_WIN32
	GPollFD polls[6];
	gint status, i;
	gboolean read_data = FALSE, wrote_data = FALSE;
	gboolean was_in_decrypt_stage;

	for (i = 0; i < 6; i++) {
		polls[i].fd = -1;
		polls[i].events = 0;
	}

	if (!gpg->seen_eof1) {
		polls[0].fd = gpg->stdout_fd;
		polls[0].events = G_IO_IN;
	}

	if (!gpg->seen_eof2) {
		polls[1].fd = gpg->stderr_fd;
		polls[1].events = G_IO_IN;
	}

	if (!gpg->complete) {
		polls[2].fd = gpg->status_fd;
		polls[2].events = G_IO_IN;
	}

	polls[3].fd = gpg->stdin_fd;
	polls[3].events = G_IO_OUT;
	polls[4].fd = gpg->passwd_fd;
	polls[4].events = G_IO_OUT;
	polls[5].fd = g_cancellable_get_fd (cancellable);
	polls[5].events = G_IO_IN;

	do {
		for (i = 0; i < 6; i++)
			polls[i].revents = 0;
		status = g_poll (polls, 6, 30 * 1000);
	} while (status == -1 && errno == EINTR);

	if (status == 0)
		return 0;	/* timed out */
	else if (status == -1)
		goto exception;

	if ((polls[5].revents & G_IO_IN) &&
		g_cancellable_set_error_if_cancelled (cancellable, error)) {

		gpg_ctx_op_cancel (gpg);
		return -1;
	}

	/* Test each and every file descriptor to see if it's 'ready',
	 * and if so - do what we can with it and then drop through to
	 * the next file descriptor and so on until we've done what we
	 * can to all of them. If one fails along the way, return
	 * -1. */

	was_in_decrypt_stage = gpg->in_decrypt_stage;

	if (polls[2].revents & (G_IO_IN | G_IO_HUP)) {
		/* read the status message and decide what to do... */
		gchar buffer[4096];
		gssize nread;

		d (printf ("reading from gpg's status-fd...\n"));

		do {
			nread = read (gpg->status_fd, buffer, sizeof (buffer));
			d (printf ("   read %d bytes (%.*s)\n", (gint) nread, (gint) nread, buffer));
		} while (nread == -1 && (errno == EINTR || errno == EAGAIN));
		if (nread == -1)
			goto exception;

		if (nread > 0) {
			status_backup (gpg, buffer, nread);

			if (gpg_ctx_parse_status (gpg, error) == -1)
				return -1;
		} else {
			gpg->complete = TRUE;
		}
	}

	if ((polls[0].revents & (G_IO_IN | G_IO_HUP)) && gpg->ostream) {
		gchar buffer[4096];
		gssize nread;

		d (printf ("reading gpg's stdout...\n"));

		do {
			nread = read (gpg->stdout_fd, buffer, sizeof (buffer));
			d (printf ("   read %d bytes (%.*s)\n", (gint) nread, (gint) nread, buffer));
		} while (nread == -1 && (errno == EINTR || errno == EAGAIN));
		if (nread == -1)
			goto exception;

		if (nread > 0) {
			if (gpg->mode != GPG_CTX_MODE_DECRYPT ||
			    gpg->in_decrypt_stage || was_in_decrypt_stage) {
				gsize written = camel_stream_write (
					gpg->ostream, buffer, (gsize)
					nread, cancellable, error);
				if (written != nread)
					return -1;
			} else {
				if (!gpg->decrypt_extra_text)
					gpg->decrypt_extra_text = g_string_new ("");
				g_string_append_len (gpg->decrypt_extra_text, buffer, nread);
			}
		} else {
			gpg->seen_eof1 = TRUE;
		}

		read_data = TRUE;
	}

	if (polls[1].revents & (G_IO_IN | G_IO_HUP)) {
		gchar buffer[4096];
		gssize nread;

		d (printf ("reading gpg's stderr...\n"));

		do {
			nread = read (gpg->stderr_fd, buffer, sizeof (buffer));
			d (printf ("   read %d bytes (%.*s)\n", (gint) nread, (gint) nread, buffer));
		} while (nread == -1 && (errno == EINTR || errno == EAGAIN));
		if (nread == -1)
			goto exception;

		if (nread > 0) {
			camel_stream_write (
				gpg->diagnostics, buffer,
				nread, cancellable, error);
		} else {
			gpg->seen_eof2 = TRUE;
		}
	}

	if ((polls[4].revents & (G_IO_OUT | G_IO_HUP)) && gpg->need_passwd && gpg->send_passwd) {
		gssize w, nwritten = 0;
		gsize n;

		d (printf ("sending gpg our passphrase...\n"));

		/* send the passphrase to gpg */
		n = strlen (gpg->passwd);
		do {
			do {
				w = write (gpg->passwd_fd, gpg->passwd + nwritten, n - nwritten);
			} while (w == -1 && (errno == EINTR || errno == EAGAIN));

			if (w > 0)
				nwritten += w;
		} while (nwritten < n && w != -1);

		/* zero and free our passwd buffer */
		memset (gpg->passwd, 0, n);
		g_free (gpg->passwd);
		gpg->passwd = NULL;

		if (w == -1)
			goto exception;

		gpg->send_passwd = FALSE;
	}

	if ((polls[3].revents & (G_IO_OUT | G_IO_HUP)) && gpg->istream) {
		gchar buffer[4096];
		gssize nread;

		d (printf ("writing to gpg's stdin...\n"));

		/* write our stream to gpg's stdin */
		nread = camel_stream_read (
			gpg->istream, buffer,
			sizeof (buffer), cancellable, NULL);
		if (nread > 0) {
			gssize w, nwritten = 0;

			do {
				do {
					w = write (gpg->stdin_fd, buffer + nwritten, nread - nwritten);
				} while (w == -1 && (errno == EINTR || errno == EAGAIN));

				if (w > 0)
					nwritten += w;
			} while (nwritten < nread && w != -1);

			if (w == -1)
				goto exception;

			d (printf ("wrote %d (out of %d) bytes to gpg's stdin\n", (gint) nwritten, (gint) nread));
			wrote_data = TRUE;
		}

		if (camel_stream_eos (gpg->istream)) {
			d (printf ("closing gpg's stdin\n"));
			close (gpg->stdin_fd);
			gpg->stdin_fd = -1;
		}
	}

	if (gpg->need_id && !gpg->processing && !read_data && !wrote_data) {
		/* do not ask more than hundred times per second when looking for a pass phrase,
		 * in case user has the use-agent set, it'll not use the all CPU when
		 * agent is asking for a pass phrase, instead of us */
		g_usleep (G_USEC_PER_SEC / 100);
	}

	return 0;

 exception:
	/* always called on an i/o error */
	g_set_error (
		error, G_IO_ERROR,
		g_io_error_from_errno (errno),
		_("Failed to execute gpg: %s"), g_strerror (errno));
	gpg_ctx_op_cancel (gpg);
#endif
	return -1;
}

static gboolean
gpg_ctx_op_complete (struct _GpgCtx *gpg)
{
	return gpg->complete && gpg->seen_eof1 && gpg->seen_eof2;}

#if 0
static gboolean
gpg_ctx_op_exited (struct _GpgCtx *gpg)
{
	pid_t retval;
	gint status;

	if (gpg->exited)
		return TRUE;

	retval = waitpid (gpg->pid, &status, WNOHANG);
	if (retval == gpg->pid) {
		gpg->exit_status = status;
		gpg->exited = TRUE;
		return TRUE;
	}

	return FALSE;
}
#endif

static gint
gpg_ctx_op_wait (struct _GpgCtx *gpg)
{
#ifndef G_OS_WIN32
	sigset_t mask, omask;
	pid_t retval;
	gint status;

	if (!gpg->exited) {
		sigemptyset (&mask);
		sigaddset (&mask, SIGALRM);
		sigprocmask (SIG_BLOCK, &mask, &omask);
		alarm (1);
		retval = waitpid (gpg->pid, &status, 0);
		alarm (0);
		sigprocmask (SIG_SETMASK, &omask, NULL);

		if (retval == (pid_t) -1 && errno == EINTR) {
			/* The child is hanging: send a friendly reminder. */
			kill (gpg->pid, SIGTERM);
			sleep (1);
			retval = waitpid (gpg->pid, &status, WNOHANG);
			if (retval == (pid_t) 0) {
				/* Still hanging; use brute force. */
				kill (gpg->pid, SIGKILL);
				sleep (1);
				retval = waitpid (gpg->pid, &status, WNOHANG);
			}
		}
	} else {
		status = gpg->exit_status;
		retval = gpg->pid;
	}

	if (retval != (pid_t) -1 && WIFEXITED (status))
		return WEXITSTATUS (status);
	else
		return -1;
#else
	return -1;
#endif
}

static gchar *
swrite (CamelMimePart *sigpart,
        GCancellable *cancellable,
        GError **error)
{
	GFile *file;
	GFileIOStream *base_stream = NULL;
	CamelStream *stream = NULL;
	CamelDataWrapper *wrapper;
	gchar *path = NULL;
	gint ret;

	file = g_file_new_tmp ("evolution-pgp.XXXXXX", &base_stream, error);

	/* Sanity check. */
	g_return_val_if_fail (
		((file != NULL) && (base_stream != NULL)) ||
		((file == NULL) && (base_stream == NULL)), NULL);

	if (base_stream != NULL) {
		stream = camel_stream_new (G_IO_STREAM (base_stream));
		g_object_unref (base_stream);
	}

	if (stream == NULL)
		return NULL;

	wrapper = camel_medium_get_content (CAMEL_MEDIUM (sigpart));
	if (wrapper == NULL)
		wrapper = CAMEL_DATA_WRAPPER (sigpart);

	ret = camel_data_wrapper_decode_to_stream_sync (
		wrapper, stream, cancellable, error);
	if (ret != -1) {
		ret = camel_stream_flush (stream, cancellable, error);
		if (ret != -1)
			ret = camel_stream_close (stream, cancellable, error);
	}

	if (ret != -1)
		path = g_file_get_path (file);

	g_object_unref (file);
	g_object_unref (stream);

	return path;
}

static const gchar *
gpg_context_find_photo (GHashTable *photos, /* keyid ~> filename in tmp */
			GHashTable *signers_keyid, /* signer ~> keyid */
			const gchar *name,
			const gchar *email)
{
	GHashTableIter iter;
	gpointer key, value;
	const gchar *keyid = NULL;

	if (!photos || !signers_keyid || ((!name || !*name) && (!email || !*email)))
		return NULL;

	g_hash_table_iter_init (&iter, signers_keyid);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		if ((email && *email && strstr (key, email)) ||
		    (name && *name && strstr (key, name))) {
			keyid = value;
			break;
		}
	}

	if (keyid) {
		const gchar *filename;

		filename = g_hash_table_lookup (photos, keyid);
		if (filename)
			return camel_pstring_strdup (filename);
	}

	return NULL;
}

static void
camel_gpg_context_free_photo_filename (gpointer ptr)
{
	gchar *tmp_filename = g_strdup (ptr);

	camel_pstring_free (ptr);

	if (!camel_pstring_contains (tmp_filename) &&
	    g_file_test (tmp_filename, G_FILE_TEST_EXISTS | G_FILE_TEST_IS_REGULAR)) {
		g_unlink (tmp_filename);
	}

	g_free (tmp_filename);
}

static gpointer
camel_gpg_context_clone_photo_filename (gpointer ptr)
{
	return (gpointer) camel_pstring_strdup (ptr);
}

static CamelInternetAddress *
gpg_ctx_extract_email_addresses_from_text (const gchar *text)
{
	CamelInternetAddress *signers_alt_emails = NULL;
	const gchar *lt = NULL, *gt = NULL, *bs = NULL, *be = NULL;
	gssize ii;

	for (ii = 0; text && text[ii]; ii++) {
		switch (text[ii]) {
		case '<':
			lt = text + ii;
			gt = NULL;
			bs = NULL;
			be = NULL;
			break;
		case '>':
			if (lt) {
				gt = text + ii;
				bs = NULL;
				be = NULL;
			}
			break;
		case '[':
			if (lt && gt) {
				bs = text + ii;
				be = NULL;
			}
			break;
		case ']':
			if (lt && gt && bs) {
				be = text + ii;
			}
			break;
		case '\n':
			if (lt && lt < gt && gt < bs && bs < be) {
				gchar *email = g_strndup (lt + 1, gt - lt - 1);

				if (!signers_alt_emails)
					signers_alt_emails = camel_internet_address_new ();

				camel_internet_address_add (signers_alt_emails, NULL, email);
				g_free (email);
			}
			lt = NULL;
			gt = NULL;
			bs = NULL;
			be = NULL;
			break;
		default:
			break;
		}
	}

	if (lt && lt < gt && gt < bs && bs < be) {
		gchar *email = g_strndup (lt + 1, gt - lt - 1);

		if (!signers_alt_emails)
			signers_alt_emails = camel_internet_address_new ();

		camel_internet_address_add (signers_alt_emails, NULL, email);
		g_free (email);
	}

	return signers_alt_emails;
}

static void
add_signers (CamelCipherValidity *validity,
	     const gchar *diagnostics,
	     const GString *signers,
	     GHashTable *signers_keyid,
	     const gchar *photos_filename)
{
	CamelInternetAddress *address;
	GHashTable *photos = NULL;
	gint i, count;

	g_return_if_fail (validity != NULL);

	if (!signers || !signers->str || !*signers->str)
		return;

	address = camel_internet_address_new ();
	g_return_if_fail (address != NULL);

	if (photos_filename) {
		/* A short file is expected */
		gchar *content = NULL;
		GError *error = NULL;

		if (g_file_get_contents (photos_filename, &content, NULL, &error)) {
			gchar **lines;
			gint ii;

			/* Each line is encoded as: KeyID\tPhotoFilename */
			lines = g_strsplit (content, "\n", -1);

			for (ii = 0; lines && lines[ii]; ii++) {
				gchar *line, *filename;

				line = lines[ii];
				filename = strchr (line, '\t');

				if (filename) {
					*filename = '\0';
					filename++;
				}

				if (filename && g_file_test (filename, G_FILE_TEST_EXISTS | G_FILE_TEST_IS_REGULAR)) {
					if (!photos)
						photos = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, camel_gpg_context_free_photo_filename);

					g_hash_table_insert (photos, g_strdup (line), (gpointer) camel_pstring_strdup (filename));
				}
			}

			g_strfreev (lines);
		} else {
			g_warning ("CamelGPGContext: Failed to open photos file '%s': %s", photos_filename, error ? error->message : "Unknown error");
		}

		g_free (content);
		g_clear_error (&error);
	}

	count = camel_address_decode (CAMEL_ADDRESS (address), signers->str);
	for (i = 0; i < count; i++) {
		const gchar *name = NULL, *email = NULL;
		const gchar *photo_filename; /* allocated on the string pool */
		gint index;

		if (!camel_internet_address_get (address, i, &name, &email))
			break;

		photo_filename = gpg_context_find_photo (photos, signers_keyid, name, email);
		index = camel_cipher_validity_add_certinfo (validity, CAMEL_CIPHER_VALIDITY_SIGN, name, email);

		if (index != -1 && photo_filename) {
			camel_cipher_validity_set_certinfo_property (validity, CAMEL_CIPHER_VALIDITY_SIGN, index,
				CAMEL_CIPHER_CERT_INFO_PROPERTY_PHOTO_FILENAME, (gpointer) photo_filename,
				camel_gpg_context_free_photo_filename, camel_gpg_context_clone_photo_filename);
		} else if (photo_filename) {
			camel_gpg_context_free_photo_filename ((gpointer) photo_filename);
		}
	}

	if (photos)
		g_hash_table_destroy (photos);
	g_object_unref (address);

	if (diagnostics && !g_queue_is_empty (&validity->sign.signers)) {
		CamelInternetAddress *signers_alt_emails;

		signers_alt_emails = gpg_ctx_extract_email_addresses_from_text (diagnostics);
		if (signers_alt_emails && camel_address_length (CAMEL_ADDRESS (signers_alt_emails)) > 1) {
			gchar *addresses = camel_address_format (CAMEL_ADDRESS (signers_alt_emails));

			camel_cipher_validity_set_certinfo_property (validity, CAMEL_CIPHER_VALIDITY_SIGN, 0,
				CAMEL_CIPHER_CERT_INFO_PROPERTY_SIGNERS_ALT_EMAILS, addresses,
				g_free, (CamelCipherCloneFunc) g_strdup);
		}

		g_clear_object (&signers_alt_emails);
	}
}

/* ********************************************************************** */

static void
gpg_context_set_property (GObject *object,
                          guint property_id,
                          const GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ALWAYS_TRUST:
			camel_gpg_context_set_always_trust (
				CAMEL_GPG_CONTEXT (object),
				g_value_get_boolean (value));
			return;

		case PROP_PREFER_INLINE:
			camel_gpg_context_set_prefer_inline (
				CAMEL_GPG_CONTEXT (object),
				g_value_get_boolean (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
gpg_context_get_property (GObject *object,
                          guint property_id,
                          GValue *value,
                          GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_ALWAYS_TRUST:
			g_value_set_boolean (
				value,
				camel_gpg_context_get_always_trust (
				CAMEL_GPG_CONTEXT (object)));
			return;

		case PROP_PREFER_INLINE:
			g_value_set_boolean (
				value,
				camel_gpg_context_get_prefer_inline (
				CAMEL_GPG_CONTEXT (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static const gchar *
gpg_hash_to_id (CamelCipherContext *context,
                CamelCipherHash hash)
{
	switch (hash) {
	case CAMEL_CIPHER_HASH_MD2:
		return "pgp-md2";
	case CAMEL_CIPHER_HASH_MD5:
		return "pgp-md5";
	case CAMEL_CIPHER_HASH_SHA1:
	case CAMEL_CIPHER_HASH_DEFAULT:
		return "pgp-sha1";
	case CAMEL_CIPHER_HASH_SHA256:
		return "pgp-sha256";
	case CAMEL_CIPHER_HASH_SHA384:
		return "pgp-sha384";
	case CAMEL_CIPHER_HASH_SHA512:
		return "pgp-sha512";
	case CAMEL_CIPHER_HASH_RIPEMD160:
		return "pgp-ripemd160";
	case CAMEL_CIPHER_HASH_TIGER192:
		return "pgp-tiger192";
	case CAMEL_CIPHER_HASH_HAVAL5160:
		return "pgp-haval-5-160";
	}

	return NULL;
}

static CamelCipherHash
gpg_id_to_hash (CamelCipherContext *context,
                const gchar *id)
{
	if (id) {
		if (!strcmp (id, "pgp-md2"))
			return CAMEL_CIPHER_HASH_MD2;
		else if (!strcmp (id, "pgp-md5"))
			return CAMEL_CIPHER_HASH_MD5;
		else if (!strcmp (id, "pgp-sha1"))
			return CAMEL_CIPHER_HASH_SHA1;
		else if (!strcmp (id, "pgp-sha256"))
			return CAMEL_CIPHER_HASH_SHA256;
		else if (!strcmp (id, "pgp-sha384"))
			return CAMEL_CIPHER_HASH_SHA384;
		else if (!strcmp (id, "pgp-sha512"))
			return CAMEL_CIPHER_HASH_SHA512;
		else if (!strcmp (id, "pgp-ripemd160"))
			return CAMEL_CIPHER_HASH_RIPEMD160;
		else if (!strcmp (id, "tiger192"))
			return CAMEL_CIPHER_HASH_TIGER192;
		else if (!strcmp (id, "haval-5-160"))
			return CAMEL_CIPHER_HASH_HAVAL5160;
	}

	return CAMEL_CIPHER_HASH_DEFAULT;
}

static gboolean
gpg_context_decode_to_stream (CamelMimePart *part,
			      CamelStream *stream,
			      GCancellable *cancellable,
			      GError **error)
{
	CamelDataWrapper *wrapper;

	wrapper = camel_medium_get_content (CAMEL_MEDIUM (part));

	/* This is when encrypting already signed part */
	if (CAMEL_IS_MIME_PART (wrapper))
		wrapper = camel_medium_get_content (CAMEL_MEDIUM (wrapper));

	if (camel_data_wrapper_decode_to_stream_sync (wrapper, stream, cancellable, error) == -1 ||
	    camel_stream_flush (stream, cancellable, error) == -1)
		return FALSE;

	/* Reset stream position to beginning. */
	if (G_IS_SEEKABLE (stream))
		g_seekable_seek (G_SEEKABLE (stream), 0, G_SEEK_SET, NULL, NULL);

	return TRUE;
}

static gboolean
gpg_sign_sync (CamelCipherContext *context,
               const gchar *userid,
               CamelCipherHash hash,
               CamelMimePart *ipart,
               CamelMimePart *opart,
               GCancellable *cancellable,
               GError **error)
{
	struct _GpgCtx *gpg = NULL;
	CamelCipherContextClass *class;
	CamelGpgContext *ctx = (CamelGpgContext *) context;
	CamelStream *ostream = camel_stream_mem_new (), *istream;
	CamelDataWrapper *dw;
	CamelContentType *ct;
	CamelMimePart *sigpart;
	CamelMultipartSigned *mps;
	gboolean success = FALSE;
	gboolean prefer_inline;

	/* Note: see rfc2015 or rfc3156, section 5 */

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);

	prefer_inline = ctx->priv->prefer_inline &&
		camel_content_type_is (camel_mime_part_get_content_type (ipart), "text", "plain");

	/* FIXME: stream this, we stream output at least */
	istream = camel_stream_mem_new ();
	if ((prefer_inline && !gpg_context_decode_to_stream (ipart, istream, cancellable, error)) ||
	    (!prefer_inline && camel_cipher_canonical_to_stream (
		ipart, CAMEL_MIME_FILTER_CANON_STRIP |
		CAMEL_MIME_FILTER_CANON_CRLF |
		CAMEL_MIME_FILTER_CANON_FROM,
		istream, NULL, error) == -1)) {
		g_prefix_error (
			error, _("Could not generate signing data: "));
		goto fail;
	}

#ifdef GPG_LOG
	if (camel_debug_start ("gpg:sign")) {
		gchar *name;
		CamelStream *out;

		name = g_strdup_printf ("camel-gpg.%d.sign-data", logid++);
		out = camel_stream_fs_new_with_name (
			name, O_CREAT | O_TRUNC | O_WRONLY, 0666, NULL);
		if (out) {
			printf ("Writing gpg signing data to '%s'\n", name);
			camel_stream_write_to_stream (istream, out, NULL, NULL);
			g_seekable_seek (
				G_SEEKABLE (istream), 0,
				G_SEEK_SET, NULL, NULL);
			g_object_unref (out);
		}
		g_free (name);
		camel_debug_end ();
	}
#endif

	gpg = gpg_ctx_new (context, cancellable);
	gpg_ctx_set_mode (gpg, GPG_CTX_MODE_SIGN);
	gpg_ctx_set_hash (gpg, hash);
	gpg_ctx_set_armor (gpg, TRUE);
	gpg_ctx_set_userid (gpg, userid);
	gpg_ctx_set_istream (gpg, istream);
	gpg_ctx_set_ostream (gpg, ostream);
	gpg_ctx_set_prefer_inline (gpg, prefer_inline);

	if (!gpg_ctx_op_start (gpg, error))
		goto fail;

	while (!gpg_ctx_op_complete (gpg)) {
		if (gpg_ctx_op_step (gpg, cancellable, error) == -1) {
			gpg_ctx_op_cancel (gpg);
			goto fail;
		}
	}

	if (gpg_ctx_op_wait (gpg) != 0) {
		const gchar *diagnostics;

		diagnostics = gpg_ctx_get_diagnostics (gpg);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, "%s",
			(diagnostics != NULL && *diagnostics != '\0') ?
			diagnostics : _("Failed to execute gpg."));

		goto fail;
	}

	success = TRUE;

	dw = camel_data_wrapper_new ();
	g_seekable_seek (G_SEEKABLE (ostream), 0, G_SEEK_SET, NULL, NULL);
	camel_data_wrapper_construct_from_stream_sync (dw, ostream, NULL, NULL);

	if (gpg->prefer_inline) {
		CamelTransferEncoding encoding;

		encoding = camel_mime_part_get_encoding (ipart);

		if (encoding != CAMEL_TRANSFER_ENCODING_BASE64 &&
		    encoding != CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE)
			encoding = CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE;

		sigpart = camel_mime_part_new ();
		ct = camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (ipart));
		camel_data_wrapper_set_mime_type_field (dw, ct);

		camel_mime_part_set_encoding (sigpart, encoding);
		camel_medium_set_content ((CamelMedium *) sigpart, dw);
		g_object_unref (dw);

		camel_medium_set_content ((CamelMedium *) opart, (CamelDataWrapper *) sigpart);

		g_object_unref (sigpart);
	} else {
		sigpart = camel_mime_part_new ();
		ct = camel_content_type_new ("application", "pgp-signature");
		camel_content_type_set_param (ct, "name", "signature.asc");
		camel_data_wrapper_set_mime_type_field (dw, ct);
		camel_content_type_unref (ct);

		camel_medium_set_content ((CamelMedium *) sigpart, dw);
		g_object_unref (dw);

		camel_mime_part_set_description (sigpart, "This is a digitally signed message part");

		mps = camel_multipart_signed_new ();
		ct = camel_content_type_new ("multipart", "signed");
		camel_content_type_set_param (ct, "micalg", camel_cipher_context_hash_to_id (context, hash == CAMEL_CIPHER_HASH_DEFAULT ? gpg->hash : hash));
		camel_content_type_set_param (ct, "protocol", class->sign_protocol);
		camel_data_wrapper_set_mime_type_field ((CamelDataWrapper *) mps, ct);
		camel_content_type_unref (ct);
		camel_multipart_set_boundary ((CamelMultipart *) mps, NULL);

		camel_multipart_signed_set_signature (mps, sigpart);
		camel_multipart_signed_set_content_stream (mps, istream);

		g_object_unref (sigpart);

		camel_medium_set_content ((CamelMedium *) opart, (CamelDataWrapper *) mps);

		g_object_unref (mps);
	}

	g_seekable_seek (G_SEEKABLE (istream), 0, G_SEEK_SET, NULL, NULL);

fail:
	g_object_unref (ostream);

	if (gpg)
		gpg_ctx_free (gpg);

	return success;
}

static CamelCipherValidity *
gpg_verify_sync (CamelCipherContext *context,
                 CamelMimePart *ipart,
                 GCancellable *cancellable,
                 GError **error)
{
	CamelCipherContextClass *class;
	CamelCipherValidity *validity;
	const gchar *diagnostics = NULL;
	struct _GpgCtx *gpg = NULL;
	gchar *sigfile = NULL;
	CamelContentType *ct;
	CamelMimePart *sigpart;
	CamelStream *istream = NULL, *canon_stream;
	CamelMultipart *mps;
	CamelStream *filter;
	CamelMimeFilter *canon;
	gboolean is_retry = FALSE;

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);

	mps = (CamelMultipart *) camel_medium_get_content ((CamelMedium *) ipart);
	ct = camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (mps));

	/* Inline signature (using our fake mime type) or PGP/Mime signature */
	if (camel_content_type_is (ct, "multipart", "signed")) {
		/* PGP/Mime Signature */
		const gchar *tmp;

		tmp = camel_content_type_param (ct, "protocol");
		if (!CAMEL_IS_MULTIPART_SIGNED (mps)
		    || tmp == NULL
		    || g_ascii_strcasecmp (tmp, class->sign_protocol) != 0) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Cannot verify message signature: "
				"Incorrect message format"));
			return NULL;
		}

		if (!(istream = camel_multipart_signed_get_content_stream ((CamelMultipartSigned *) mps, NULL))) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Cannot verify message signature: "
				"Incorrect message format"));
			return NULL;
		}

		if (!(sigpart = camel_multipart_get_part (mps, CAMEL_MULTIPART_SIGNED_SIGNATURE))) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Cannot verify message signature: "
				"Incorrect message format"));
			g_object_unref (istream);
			return NULL;
		}
	} else if (camel_content_type_is (ct, "application", "x-inlinepgp-signed")) {
		/* Inline Signed */
		CamelDataWrapper *content;
		content = camel_medium_get_content ((CamelMedium *) ipart);
		istream = camel_stream_mem_new ();
		if (!camel_data_wrapper_decode_to_stream_sync (
			content, istream, cancellable, error))
			goto exception;
		g_seekable_seek (
			G_SEEKABLE (istream), 0, G_SEEK_SET, NULL, NULL);
		sigpart = NULL;
	} else {
		/* Invalid Mimetype */
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot verify message signature: "
			"Incorrect message format"));
		return NULL;
	}

	/* Now start the real work of verifying the message */
#ifdef GPG_LOG
	if (camel_debug_start ("gpg:sign")) {
		gchar *name;
		CamelStream *out;

		name = g_strdup_printf ("camel-gpg.%d.verify.data", logid);
		out = camel_stream_fs_new_with_name (
			name, O_CREAT | O_TRUNC | O_WRONLY, 0666, NULL);
		if (out) {
			printf ("Writing gpg verify data to '%s'\n", name);
			camel_stream_write_to_stream (istream, out, NULL, NULL);
			g_seekable_seek (
				G_SEEKABLE (istream),
				0, G_SEEK_SET, NULL, NULL);
			g_object_unref (out);
		}

		g_free (name);

		if (sigpart) {
			name = g_strdup_printf ("camel-gpg.%d.verify.signature", logid++);
			out = camel_stream_fs_new_with_name (
				name, O_CREAT | O_TRUNC | O_WRONLY, 0666, NULL);
			if (out) {
				printf ("Writing gpg verify signature to '%s'\n", name);
				camel_data_wrapper_write_to_stream_sync (
					CAMEL_DATA_WRAPPER (sigpart),
					out, NULL, NULL);
				g_object_unref (out);
			}
			g_free (name);
		}
		camel_debug_end ();
	}
#endif

	if (sigpart) {
		sigfile = swrite (sigpart, cancellable, error);
		if (sigfile == NULL) {
			g_prefix_error (
				error, _("Cannot verify message signature: "));
			goto exception;
		}
	}

 retry:
	g_seekable_seek (G_SEEKABLE (istream), 0, G_SEEK_SET, NULL, NULL);

	canon_stream = camel_stream_mem_new ();

	/* strip trailing white-spaces */
	filter = camel_stream_filter_new (istream);
	canon = camel_mime_filter_canon_new (CAMEL_MIME_FILTER_CANON_CRLF | (is_retry ? 0 : CAMEL_MIME_FILTER_CANON_STRIP));
	camel_stream_filter_add (CAMEL_STREAM_FILTER (filter), canon);
	g_object_unref (canon);

	camel_stream_write_to_stream (filter, canon_stream, NULL, NULL);

	g_object_unref (filter);

	g_seekable_seek (G_SEEKABLE (canon_stream), 0, G_SEEK_SET, NULL, NULL);

	gpg = gpg_ctx_new (context, cancellable);
	gpg_ctx_set_mode (gpg, GPG_CTX_MODE_VERIFY);
	gpg_ctx_set_load_photos (gpg, camel_cipher_can_load_photos ());
	if (sigfile)
		gpg_ctx_set_sigfile (gpg, sigfile);
	gpg_ctx_set_istream (gpg, canon_stream);

	if (!gpg_ctx_op_start (gpg, error)) {
		g_object_unref (canon_stream);
		goto exception;
	}

	while (!gpg_ctx_op_complete (gpg)) {
		if (gpg_ctx_op_step (gpg, cancellable, error) == -1) {
			gpg_ctx_op_cancel (gpg);
			g_object_unref (canon_stream);
			goto exception;
		}
	}

	/* report error only when no data or didn't found signature */
	if (gpg_ctx_op_wait (gpg) != 0 && (gpg->nodata || !gpg->hadsig)) {
		const gchar *diagnostics;

		diagnostics = gpg_ctx_get_diagnostics (gpg);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, "%s",
			(diagnostics != NULL && *diagnostics != '\0') ?
			diagnostics : _("Failed to execute gpg."));

		g_object_unref (canon_stream);

		goto exception;
	}

	if (!is_retry && !gpg->validsig && !gpg->nopubkey) {
		/* Retry without stripping trailing spaces */
		is_retry = TRUE;
		gpg_ctx_free (gpg);
		g_object_unref (canon_stream);
		goto retry;
	}

	validity = camel_cipher_validity_new ();
	diagnostics = gpg_ctx_get_diagnostics (gpg);
	camel_cipher_validity_set_description (validity, diagnostics);
	if (gpg->validsig) {
		if (gpg->trust == GPG_TRUST_UNDEFINED || gpg->trust == GPG_TRUST_NONE || gpg->trust == GPG_TRUST_MARGINAL)
			validity->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_UNKNOWN;
		else if (gpg->trust != GPG_TRUST_NEVER)
			validity->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_GOOD;
		else
			validity->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_BAD;
	} else if (gpg->nopubkey) {
		validity->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_NEED_PUBLIC_KEY;
	} else {
		validity->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_BAD;
	}

	add_signers (validity, diagnostics, gpg->signers, gpg->signers_keyid, gpg->photos_filename);

	gpg_ctx_free (gpg);

	if (sigfile) {
		g_unlink (sigfile);
		g_free (sigfile);
	}

	g_object_unref (canon_stream);
	g_clear_object (&istream);

	return validity;

 exception:

	if (gpg != NULL)
		gpg_ctx_free (gpg);

	if (istream)
		g_object_unref (istream);

	if (sigfile) {
		g_unlink (sigfile);
		g_free (sigfile);
	}

	return NULL;
}

static gboolean
gpg_encrypt_sync (CamelCipherContext *context,
                  const gchar *userid,
                  GPtrArray *recipients,
                  CamelMimePart *ipart,
                  CamelMimePart *opart,
                  GCancellable *cancellable,
                  GError **error)
{
	CamelCipherContextClass *class;
	CamelGpgContext *ctx = (CamelGpgContext *) context;
	struct _GpgCtx *gpg;
	CamelStream *istream, *ostream, *vstream;
	CamelMimePart *encpart, *verpart;
	CamelDataWrapper *dw;
	CamelContentType *ct;
	CamelMultipartEncrypted *mpe;
	gboolean success = FALSE;
	gboolean prefer_inline;
	GSList *gathered_keys = NULL, *link;
	gint i;

	class = CAMEL_CIPHER_CONTEXT_GET_CLASS (context);

	if (!camel_session_get_recipient_certificates_sync (camel_cipher_context_get_session (context),
		CAMEL_RECIPIENT_CERTIFICATE_PGP, recipients, &gathered_keys, cancellable, error))
		return FALSE;

	prefer_inline = ctx->priv->prefer_inline &&
		camel_content_type_is (camel_mime_part_get_content_type (ipart), "text", "plain");

	ostream = camel_stream_mem_new ();
	istream = camel_stream_mem_new ();
	if ((prefer_inline && !gpg_context_decode_to_stream (ipart, istream, cancellable, error)) ||
	    (!prefer_inline && camel_cipher_canonical_to_stream (
		ipart, CAMEL_MIME_FILTER_CANON_CRLF, istream, NULL, error) == -1)) {
		g_prefix_error (
			error, _("Could not generate encrypting data: "));
		goto fail1;
	}

	gpg = gpg_ctx_new (context, cancellable);
	gpg_ctx_set_mode (gpg, GPG_CTX_MODE_ENCRYPT);
	gpg_ctx_set_armor (gpg, TRUE);
	gpg_ctx_set_userid (gpg, userid);
	gpg_ctx_set_istream (gpg, istream);
	gpg_ctx_set_ostream (gpg, ostream);
	gpg_ctx_set_always_trust (gpg, ctx->priv->always_trust);
	gpg_ctx_set_prefer_inline (gpg, prefer_inline);

	if (gathered_keys && g_slist_length (gathered_keys) != recipients->len) {
		g_slist_free_full (gathered_keys, g_free);
		gathered_keys = NULL;
	}

	for (link = gathered_keys, i = 0; i < recipients->len; i++) {
		gpg_ctx_add_recipient (gpg, recipients->pdata[i], link ? link->data : NULL);
		link = g_slist_next (link);
	}

	if (!gpg_ctx_op_start (gpg, error))
		goto fail;

	/* FIXME: move this to a common routine */
	while (!gpg_ctx_op_complete (gpg)) {
		if (gpg_ctx_op_step (gpg, cancellable, error) == -1) {
			gpg_ctx_op_cancel (gpg);
			goto fail;
		}
	}

	if (gpg_ctx_op_wait (gpg) != 0) {
		const gchar *diagnostics;

		diagnostics = gpg_ctx_get_diagnostics (gpg);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, "%s",
			(diagnostics != NULL && *diagnostics != '\0') ?
			diagnostics : _("Failed to execute gpg."));
		goto fail;
	}

	success = TRUE;

	dw = camel_data_wrapper_new ();
	g_seekable_seek (G_SEEKABLE (ostream), 0, G_SEEK_SET, NULL, NULL);
	camel_data_wrapper_construct_from_stream_sync (dw, ostream, NULL, NULL);

	if (gpg->prefer_inline) {
		CamelTransferEncoding encoding;

		encoding = camel_mime_part_get_encoding (ipart);

		if (encoding != CAMEL_TRANSFER_ENCODING_BASE64 &&
		    encoding != CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE)
			encoding = CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE;

		encpart = camel_mime_part_new ();
		ct = camel_data_wrapper_get_mime_type_field (CAMEL_DATA_WRAPPER (ipart));
		camel_data_wrapper_set_mime_type_field (dw, ct);

		camel_mime_part_set_encoding (encpart, encoding);
		camel_medium_set_content ((CamelMedium *) encpart, dw);
		g_object_unref (dw);

		camel_medium_set_content ((CamelMedium *) opart, (CamelDataWrapper *) encpart);

		g_object_unref (encpart);
	} else {
		encpart = camel_mime_part_new ();
		ct = camel_content_type_new ("application", "octet-stream");
		camel_content_type_set_param (ct, "name", "encrypted.asc");
		camel_data_wrapper_set_mime_type_field (dw, ct);
		camel_content_type_unref (ct);

		camel_medium_set_content ((CamelMedium *) encpart, dw);
		g_object_unref (dw);

		camel_mime_part_set_description (encpart, _("This is a digitally encrypted message part"));

		vstream = camel_stream_mem_new ();
		camel_stream_write_string (vstream, "Version: 1\n", NULL, NULL);
		g_seekable_seek (G_SEEKABLE (vstream), 0, G_SEEK_SET, NULL, NULL);

		verpart = camel_mime_part_new ();
		dw = camel_data_wrapper_new ();
		camel_data_wrapper_set_mime_type (dw, class->encrypt_protocol);
		camel_data_wrapper_construct_from_stream_sync (
			dw, vstream, NULL, NULL);
		g_object_unref (vstream);
		camel_medium_set_content ((CamelMedium *) verpart, dw);
		g_object_unref (dw);

		mpe = camel_multipart_encrypted_new ();
		ct = camel_content_type_new ("multipart", "encrypted");
		camel_content_type_set_param (ct, "protocol", class->encrypt_protocol);
		camel_data_wrapper_set_mime_type_field ((CamelDataWrapper *) mpe, ct);
		camel_content_type_unref (ct);
		camel_multipart_set_boundary ((CamelMultipart *) mpe, NULL);

		camel_multipart_add_part ((CamelMultipart *) mpe, verpart);
		g_object_unref (verpart);
		camel_multipart_add_part ((CamelMultipart *) mpe, encpart);
		g_object_unref (encpart);

		camel_medium_set_content ((CamelMedium *) opart, (CamelDataWrapper *) mpe);

		g_object_unref (mpe);
	}
fail:
	gpg_ctx_free (gpg);
fail1:
	g_slist_free_full (gathered_keys, g_free);
	g_object_unref (istream);
	g_object_unref (ostream);

	return success;
}

static CamelCipherValidity *
gpg_decrypt_sync (CamelCipherContext *context,
                  CamelMimePart *ipart,
                  CamelMimePart *opart,
                  GCancellable *cancellable,
                  GError **error)
{
	struct _GpgCtx *gpg = NULL;
	CamelCipherValidity *valid = NULL;
	CamelStream *ostream, *istream;
	CamelDataWrapper *content;
	CamelMimePart *encrypted;
	CamelMultipart *mp;
	CamelContentType *ct;
	gboolean success;

	if (!ipart) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot decrypt message: Incorrect message format"));
		return NULL;
	}

	content = camel_medium_get_content ((CamelMedium *) ipart);

	if (!content) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot decrypt message: Incorrect message format"));
		return NULL;
	}

	ct = camel_data_wrapper_get_mime_type_field (content);
	/* Encrypted part (using our fake mime type) or PGP/Mime multipart */
	if (camel_content_type_is (ct, "multipart", "encrypted")) {
		mp = (CamelMultipart *) camel_medium_get_content ((CamelMedium *) ipart);
		if (!(encrypted = camel_multipart_get_part (mp, CAMEL_MULTIPART_ENCRYPTED_CONTENT))) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Failed to decrypt MIME part: "
				"protocol error"));
			return NULL;
		}

		content = camel_medium_get_content ((CamelMedium *) encrypted);
	} else if (camel_content_type_is (ct, "application", "x-inlinepgp-encrypted")) {
		content = camel_medium_get_content ((CamelMedium *) ipart);
	} else {
		/* Invalid Mimetype */
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Cannot decrypt message: Incorrect message format"));
		return NULL;
	}

	istream = camel_stream_mem_new ();
	if (!camel_data_wrapper_decode_to_stream_sync (
		content, istream, cancellable, error)) {
		g_object_unref (istream);
		return NULL;
	}

	g_seekable_seek (G_SEEKABLE (istream), 0, G_SEEK_SET, NULL, NULL);

	ostream = camel_stream_mem_new ();
	camel_stream_mem_set_secure ((CamelStreamMem *) ostream);

	gpg = gpg_ctx_new (context, cancellable);
	gpg_ctx_set_mode (gpg, GPG_CTX_MODE_DECRYPT);
	gpg_ctx_set_load_photos (gpg, camel_cipher_can_load_photos ());
	gpg_ctx_set_istream (gpg, istream);
	gpg_ctx_set_ostream (gpg, ostream);

	gpg->bad_decrypt = TRUE;

	if (!gpg_ctx_op_start (gpg, error))
		goto fail;

	while (!gpg_ctx_op_complete (gpg)) {
		if (gpg_ctx_op_step (gpg, cancellable, error) == -1) {
			gpg_ctx_op_cancel (gpg);
			goto fail;
		}
	}

	/* Report errors only if nothing was decrypted; missing sender's key used
	 * for signature of a signed and encrypted messages causes GPG to return
	 * failure, thus count with it.
	 */
	if (gpg_ctx_op_wait (gpg) != 0 && (gpg->nodata || (gpg->bad_decrypt && !gpg->noseckey))) {
		const gchar *diagnostics;

		diagnostics = gpg_ctx_get_diagnostics (gpg);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC, "%s",
			(diagnostics != NULL && *diagnostics != '\0') ?
			diagnostics : _("Failed to execute gpg."));
		goto fail;
	}

	/* Decrypted nothing, write at least CRLF */
	if (!g_seekable_tell (G_SEEKABLE (ostream))) {
		g_warn_if_fail (2 == camel_stream_write (ostream, "\r\n", 2, cancellable, NULL));
	}

	g_seekable_seek (G_SEEKABLE (ostream), 0, G_SEEK_SET, NULL, NULL);

	if (gpg->bad_decrypt && gpg->noseckey) {
		success = FALSE;
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Failed to decrypt MIME part: Secret key not found"));
	} else if (camel_content_type_is (ct, "multipart", "encrypted")) {
		CamelDataWrapper *dw;
		CamelStream *null = camel_stream_null_new ();

		/* Multipart encrypted - parse a full mime part */
		success = camel_data_wrapper_construct_from_stream_sync (
			CAMEL_DATA_WRAPPER (opart),
			ostream, NULL, error);

		dw = camel_medium_get_content ((CamelMedium *) opart);
		if (!camel_data_wrapper_decode_to_stream_sync (
			dw, null, cancellable, NULL)) {
			/* nothing had been decoded from the stream, it doesn't
			 * contain any header, like Content-Type or such, thus
			 * write it as a message body */
			success = camel_data_wrapper_construct_from_stream_sync (
				dw, ostream, cancellable, error);
		}

		g_object_unref (null);
	} else {
		/* Inline signed - raw data (may not be a mime part) */
		CamelDataWrapper *dw;
		dw = camel_data_wrapper_new ();
		success = camel_data_wrapper_construct_from_stream_sync (
			dw, ostream, NULL, error);
		camel_data_wrapper_set_mime_type (dw, "application/octet-stream");
		camel_medium_set_content ((CamelMedium *) opart, dw);
		g_object_unref (dw);
		/* Set mime/type of this new part to application/octet-stream to force type snooping */
		camel_mime_part_set_content_type (opart, "application/octet-stream");
	}

	if (success) {
		valid = camel_cipher_validity_new ();
		if (gpg->decrypt_extra_text)
			valid->encrypt.description = g_strdup_printf (_("GPG blob contains unencrypted text: %s"), gpg->decrypt_extra_text->str);
		else
			valid->encrypt.description = g_strdup (_("Encrypted content"));
		valid->encrypt.status = CAMEL_CIPHER_VALIDITY_ENCRYPT_ENCRYPTED;

		if (gpg->hadsig) {
			if (gpg->validsig) {
				if (gpg->trust == GPG_TRUST_UNDEFINED || gpg->trust == GPG_TRUST_NONE)
					valid->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_UNKNOWN;
				else if (gpg->trust != GPG_TRUST_NEVER)
					valid->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_GOOD;
				else
					valid->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_BAD;
			} else if (gpg->nopubkey) {
				valid->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_NEED_PUBLIC_KEY;
			} else {
				valid->sign.status = CAMEL_CIPHER_VALIDITY_SIGN_BAD;
			}

			add_signers (valid, gpg_ctx_get_diagnostics (gpg), gpg->signers, gpg->signers_keyid, gpg->photos_filename);
		}
	}

 fail:
	g_object_unref (ostream);
	g_object_unref (istream);
	gpg_ctx_free (gpg);

	return valid;
}

static void
camel_gpg_context_class_init (CamelGpgContextClass *class)
{
	GObjectClass *object_class;
	CamelCipherContextClass *cipher_context_class;

	g_type_class_add_private (class, sizeof (CamelGpgContextPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = gpg_context_set_property;
	object_class->get_property = gpg_context_get_property;

	cipher_context_class = CAMEL_CIPHER_CONTEXT_CLASS (class);
	cipher_context_class->sign_protocol = "application/pgp-signature";
	cipher_context_class->encrypt_protocol = "application/pgp-encrypted";
	cipher_context_class->key_protocol = "application/pgp-keys";
	cipher_context_class->hash_to_id = gpg_hash_to_id;
	cipher_context_class->id_to_hash = gpg_id_to_hash;
	cipher_context_class->sign_sync = gpg_sign_sync;
	cipher_context_class->verify_sync = gpg_verify_sync;
	cipher_context_class->encrypt_sync = gpg_encrypt_sync;
	cipher_context_class->decrypt_sync = gpg_decrypt_sync;

	g_object_class_install_property (
		object_class,
		PROP_ALWAYS_TRUST,
		g_param_spec_boolean (
			"always-trust",
			"Always Trust",
			NULL,
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY));

	g_object_class_install_property (
		object_class,
		PROP_PREFER_INLINE,
		g_param_spec_boolean (
			"prefer-inline",
			"Prefer Inline",
			NULL,
			FALSE,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT |
			G_PARAM_EXPLICIT_NOTIFY));
}

static void
camel_gpg_context_init (CamelGpgContext *context)
{
	context->priv = CAMEL_GPG_CONTEXT_GET_PRIVATE (context);
}

/**
 * camel_gpg_context_new:
 * @session: session
 *
 * Creates a new gpg cipher context object.
 *
 * Returns: a new gpg cipher context object.
 **/
CamelCipherContext *
camel_gpg_context_new (CamelSession *session)
{
	g_return_val_if_fail (CAMEL_IS_SESSION (session), NULL);

	return g_object_new (
		CAMEL_TYPE_GPG_CONTEXT,
		"session", session, NULL);
}

/**
 * camel_gpg_context_get_always_trust:
 * @context: a #CamelGpgContext
 *
 * Since: 2.32
 **/
gboolean
camel_gpg_context_get_always_trust (CamelGpgContext *context)
{
	g_return_val_if_fail (CAMEL_IS_GPG_CONTEXT (context), FALSE);

	return context->priv->always_trust;
}

/**
 * camel_gpg_context_set_always_trust:
 * @context: gpg context
 * @always_trust: always trust flag
 *
 * Sets the @always_trust flag on the gpg context which is used for
 * encryption.
 **/
void
camel_gpg_context_set_always_trust (CamelGpgContext *context,
                                    gboolean always_trust)
{
	g_return_if_fail (CAMEL_IS_GPG_CONTEXT (context));

	if (context->priv->always_trust == always_trust)
		return;

	context->priv->always_trust = always_trust;

	g_object_notify (G_OBJECT (context), "always-trust");
}

/**
 * camel_gpg_context_get_prefer_inline:
 * @context: a #CamelGpgContext
 *
 * Returns: Whether prefer inline sign/encrypt (%TRUE), or as multiparts (%FALSE)
 *
 * Since: 3.20
 **/
gboolean
camel_gpg_context_get_prefer_inline (CamelGpgContext *context)
{
	g_return_val_if_fail (CAMEL_IS_GPG_CONTEXT (context), FALSE);

	return context->priv->prefer_inline;
}

/**
 * camel_gpg_context_set_prefer_inline:
 * @context: gpg context
 * @prefer_inline: whether prefer inline sign/encrypt
 *
 * Sets the @prefer_inline flag on the gpg context.
 *
 * Since: 3.20
 **/
void
camel_gpg_context_set_prefer_inline (CamelGpgContext *context,
				     gboolean prefer_inline)
{
	g_return_if_fail (CAMEL_IS_GPG_CONTEXT (context));

	if (context->priv->prefer_inline == prefer_inline)
		return;

	context->priv->prefer_inline = prefer_inline;

	g_object_notify (G_OBJECT (context), "prefer-inline");
}
