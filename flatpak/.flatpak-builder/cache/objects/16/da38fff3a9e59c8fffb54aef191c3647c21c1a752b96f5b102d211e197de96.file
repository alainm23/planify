/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-movemail.c: mbox copying function
 *
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
 * Authors: Dan Winship <danw@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/uio.h>

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-lock-client.h"
#include "camel-mime-filter-from.h"
#include "camel-mime-filter.h"
#include "camel-mime-parser.h"
#include "camel-movemail.h"

#define d(x)

#define CHECK_CALL(x) G_STMT_START { \
	if ((x) == -1) { \
		g_debug ("%s: Call of '" #x "' failed: %s", G_STRFUNC, g_strerror (errno)); \
	} \
	} G_STMT_END

#ifdef MOVEMAIL_PATH
#include <sys/wait.h>

static void movemail_external (const gchar *source, const gchar *dest,
			       GError **error);
#endif

#ifdef ENABLE_BROKEN_SPOOL
static gint camel_movemail_copy_filter (gint fromfd, gint tofd, goffset start, gsize bytes, CamelMimeFilter *filter);
static gint camel_movemail_solaris (gint oldsfd, gint dfd, GError **error);
#else
/* these could probably be exposed as a utility? (but only mbox needs it) */
static gint camel_movemail_copy_file (gint sfd, gint dfd, GError **error);
#endif

#if 0
static gint camel_movemail_copy (gint fromfd, gint tofd, goffset start, gsize bytes);
#endif

/**
 * camel_movemail:
 * @source: source file
 * @dest: destination file
 * @error: return location for a #GError, or %NULL
 *
 * This copies an mbox file from a shared directory with multiple
 * readers and writers into a private (presumably Camel-controlled)
 * directory. Dot locking is used on the source file (but not the
 * destination).
 *
 * Return Value: Returns -1 on error or 0 on success.
 **/
gint
camel_movemail (const gchar *source,
                const gchar *dest,
                GError **error)
{
	gint lockid = -1;
	gint res = -1;
	gint sfd, dfd;
	struct stat st;

	/* open files */
	sfd = open (source, O_RDWR);
	if (sfd == -1 && errno != ENOENT) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not open mail file %s: %s"),
			source, g_strerror (errno));
		return -1;
	} else if (sfd == -1) {
		/* No mail. */
		return 0;
	}

	/* Stat the spool file. If it doesn't exist or
	 * is empty, the user has no mail. (There's technically a race
	 * condition here in that an MDA might have just now locked it
	 * to deliver a message, but we don't care. In that case,
	 * assuming it's unlocked is equivalent to pretending we were
	 * called a fraction earlier.)
	 */
	if (fstat (sfd, &st) == -1) {
		close (sfd);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not check mail file %s: %s"),
			source, g_strerror (errno));
		return -1;
	}

	if (st.st_size == 0) {
		close (sfd);
		return 0;
	}

	dfd = open (dest, O_WRONLY | O_CREAT | O_APPEND, S_IRUSR | S_IWUSR);
	if (dfd == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not open temporary mail file %s: %s"),
			dest, g_strerror (errno));
		close (sfd);
		return -1;
	}

	/* lock our source mailbox */
	lockid = camel_lock_helper_lock (source, error);
	if (lockid == -1) {
		close (sfd);
		close (dfd);
		return -1;
	}

#ifdef ENABLE_BROKEN_SPOOL
	res = camel_movemail_solaris (sfd, dfd, ex);
#else
	res = camel_movemail_copy_file (sfd, dfd, error);
#endif

	/* If no errors occurred copying the data, and we successfully
	 * close the destination file, then truncate the source file.
	 */
	if (res != -1) {
		if (close (dfd) == 0) {
			CHECK_CALL (ftruncate (sfd, 0));
		} else {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Failed to store mail in temp file %s: %s"),
				dest, g_strerror (errno));
			res = -1;
		}
	} else
		close (dfd);
	close (sfd);

	camel_lock_helper_unlock (lockid);

	return res;
}

#ifdef MOVEMAIL_PATH
static void
movemail_external (const gchar *source,
                   const gchar *dest,
                   GError **error)
{
	sigset_t mask, omask;
	pid_t pid;
	gint fd[2], len = 0, nread, status;
	gchar buf[BUFSIZ], *output = NULL;

	/* Block SIGCHLD so the app can't mess us up. */
	sigemptyset (&mask);
	sigaddset (&mask, SIGCHLD);
	sigprocmask (SIG_BLOCK, &mask, &omask);

	if (pipe (fd) == -1) {
		sigprocmask (SIG_SETMASK, &omask, NULL);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not create pipe: %s"),
			g_strerror (errno));
		return;
	}

	pid = fork ();
	switch (pid) {
	case -1:
		close (fd[0]);
		close (fd[1]);
		sigprocmask (SIG_SETMASK, &omask, NULL);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not fork: %s"), g_strerror (errno));
		return;

	case 0:
		/* Child */
		close (fd[0]);
		close (STDIN_FILENO);
		dup2 (fd[1], STDOUT_FILENO);
		dup2 (fd[1], STDERR_FILENO);

		execl (MOVEMAIL_PATH, MOVEMAIL_PATH, source, dest, NULL);
		_exit (255);
		break;

	default:
		break;
	}

	/* Parent */
	close (fd[1]);

	/* Read movemail's output. */
	while ((nread = read (fd[0], buf, sizeof (buf))) > 0) {
		output = g_realloc (output, len + nread + 1);
		memcpy (output + len, buf, nread);
		len += nread;
		output[len] = '\0';
	}
	close (fd[0]);

	/* Now get the exit status. */
	while (waitpid (pid, &status, 0) == -1 && errno == EINTR)
		;
	sigprocmask (SIG_SETMASK, &omask, NULL);

	if (!WIFEXITED (status) || WEXITSTATUS (status) != 0) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Movemail program failed: %s"),
			output ? output : _("(Unknown error)"));
	}
	g_free (output);
}
#endif

#ifndef ENABLE_BROKEN_SPOOL
static gint
camel_movemail_copy_file (gint sfd,
                          gint dfd,
                          GError **error)
{
	gint nread, nwrote;
	gchar buf[4096];

	while (1) {
		gint written = 0;

		nread = read (sfd, buf, sizeof (buf));
		if (nread == 0)
			break;
		else if (nread == -1) {
			if (errno == EINTR)
				continue;
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Error reading mail file: %s"),
				g_strerror (errno));
			return -1;
		}

		while (nread) {
			nwrote = write (dfd, buf + written, nread);
			if (nwrote == -1) {
				if (errno == EINTR)
					continue; /* continues inner loop */
				g_set_error (
					error, G_IO_ERROR,
					g_io_error_from_errno (errno),
					_("Error writing mail temp file: %s"),
					g_strerror (errno));
				return -1;
			}
			written += nwrote;
			nread -= nwrote;
		}
	}

	return 0;
}
#endif

#if 0
static gint
camel_movemail_copy (gint fromfd,
                     gint tofd,
                     goffset start,
                     gsize bytes)
{
	gchar buffer[4096];
	gint written = 0;

	d (printf ("writing %d bytes ... ", bytes));

	if (lseek (fromfd, start, SEEK_SET) != start)
		return -1;

	while (bytes > 0) {
		gint toread, towrite;

		toread = bytes;
		if (bytes > 4096)
			toread = 4096;
		else
			toread = bytes;
		do {
			towrite = read (fromfd, buffer, toread);
		} while (towrite == -1 && errno == EINTR);

		if (towrite == -1)
			return -1;

                /* check for 'end of file' */
		if (towrite == 0) {
			d (printf ("end of file?\n"));
			break;
		}

		do {
			toread = write (tofd, buffer, towrite);
		} while (toread == -1 && errno == EINTR);

		if (toread == -1)
			return -1;

		written += toread;
		bytes -= toread;
	}

	d (printf ("written %d bytes\n", written));

	return written;
}
#endif

#define PRE_SIZE (32)

#ifdef ENABLE_BROKEN_SPOOL
static gint
camel_movemail_copy_filter (gint fromfd,
                            gint tofd,
                            goffset start,
                            gsize bytes,
                            CamelMimeFilter *filter)
{
	gchar buffer[4096 + PRE_SIZE];
	gint written = 0;
	gchar *filterbuffer;
	gint filterlen, filterpre;

	d (printf ("writing %d bytes ... ", bytes));

	camel_mime_filter_reset (filter);

	if (lseek (fromfd, start, SEEK_SET) != start)
		return -1;

	while (bytes > 0) {
		gint toread, towrite;

		toread = bytes;
		if (bytes > 4096)
			toread = 4096;
		else
			toread = bytes;
		do {
			towrite = read (fromfd, buffer + PRE_SIZE, toread);
		} while (towrite == -1 && errno == EINTR);

		if (towrite == -1)
			return -1;

		d (printf ("read %d unfiltered bytes\n", towrite));

                /* check for 'end of file' */
		if (towrite == 0) {
			d (printf ("end of file?\n"));
			camel_mime_filter_complete (
				filter, buffer + PRE_SIZE, towrite, PRE_SIZE,
				&filterbuffer, &filterlen, &filterpre);
			towrite = filterlen;
			if (towrite == 0)
				break;
		} else {
			camel_mime_filter_filter (
				filter, buffer + PRE_SIZE, towrite, PRE_SIZE,
				&filterbuffer, &filterlen, &filterpre);
			towrite = filterlen;
		}

		d (printf ("writing %d filtered bytes\n", towrite));

		do {
			toread = write (tofd, filterbuffer, towrite);
		} while (toread == -1 && errno == EINTR);

		if (toread == -1)
			return -1;

		written += toread;
		bytes -= toread;
	}

	d (printf ("written %d bytes\n", written));

	return written;
}

/* write the headers back out again, but not he Content-Length header, because we dont
 * want	to maintain it! */
static gint
solaris_header_write (gint fd,
                      CamelNameValueArray *headers)
{
	struct iovec iv[4];
	gint outlen = 0, len;
	guint ii;
	const gchar *header_name = NULL, *header_value = NULL;

	iv[1].iov_base = ":";
	iv[1].iov_len = 1;
	iv[3].iov_base = "\n";
	iv[3].iov_len = 1;

	for (ii = 0; camel_name_value_array_get (headers, ii, &header_name, &header_value); ii++) {
		if (g_ascii_strcasecmp (header_name, "Content-Length")) {
			iv[0].iov_base = header_name;
			iv[0].iov_len = strlen (header_name);
			iv[2].iov_base = header_value;
			iv[2].iov_len = strlen (header_value);

			do {
				len = writev (fd, iv, 4);
			} while (len == -1 && errno == EINTR);

			if (len == -1)
				return -1;
			outlen += len;
		}
	}

	do {
		len = write (fd, "\n", 1);
	} while (len == -1 && errno == EINTR);

	if (len == -1)
		return -1;

	outlen += 1;

	d (printf ("Wrote %d bytes of headers\n", outlen));

	return outlen;
}

/* Well, since Solaris is a tad broken wrt its 'mbox' folder format,
 * we must convert it to a real mbox format.  Thankfully this is
 * mostly pretty easy */
static gint
camel_movemail_solaris (gint oldsfd,
                        gint dfd,
                        GError **error)
{
	CamelMimeParser *mp;
	gchar *buffer;
	gint len;
	gint sfd;
	CamelMimeFilter *ffrom;
	gint ret = 1;
	gchar *from = NULL;

	/* need to dup as the mime parser will close on finish */
	sfd = dup (oldsfd);
	if (sfd == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Error copying mail temp file: %s"),
			g_strerror (errno));
		return -1;
	}

	mp = camel_mime_parser_new ();
	camel_mime_parser_scan_from (mp, TRUE);
	camel_mime_parser_init_with_fd (mp, sfd);

	ffrom = camel_mime_filter_from_new ();

	while (camel_mime_parser_step (mp, &buffer, &len) == CAMEL_MIME_PARSER_STATE_FROM) {
		g_return_val_if_fail (camel_mime_parser_from_line (mp), -1);
		from = g_strdup (camel_mime_parser_from_line (mp));
		if (camel_mime_parser_step (mp, &buffer, &len) != CAMEL_MIME_PARSER_STATE_FROM_END) {
			CamelNameValueArray *headers;
			const gchar *cl;
			gint length;
			gint start, body;
			goffset newpos;

			ret = 0;

			start = camel_mime_parser_tell_start_from (mp);
			body = camel_mime_parser_tell (mp);

			if (write (dfd, from, strlen (from)) != strlen (from))
				goto fail;

			/* write out headers, but NOT content-length header */
			headers = camel_mime_parser_dup_headers (mp);
			if (solaris_header_write (dfd, headers) == -1) {
				camel_name_value_array_free (headers);
				goto fail;
			}

			camel_name_value_array_free (headers);
			cl = camel_mime_parser_header (mp, "content-length", NULL);
			if (cl == NULL) {
				g_warning ("Required Content-Length header is missing from solaris mail box @ %d", (gint) camel_mime_parser_tell (mp));
				camel_mime_parser_drop_step (mp);
				camel_mime_parser_drop_step (mp);
				camel_mime_parser_step (mp, &buffer, &len);
				camel_mime_parser_unstep (mp);
				length = camel_mime_parser_tell_start_from (mp) - body;
				newpos = -1;
			} else {
				length = atoi (cl);
				camel_mime_parser_drop_step (mp);
				camel_mime_parser_drop_step (mp);
				newpos = length + body;
			}
			/* copy body->length converting From lines */
			if (camel_movemail_copy_filter (sfd, dfd, body, length, ffrom) == -1)
				goto fail;
			if (newpos != -1)
				camel_mime_parser_seek (mp, newpos, SEEK_SET);
		} else {
			g_error ("Inalid parser state: %d", camel_mime_parser_state (mp));
		}
		g_free (from);
	}

	g_object_unref (mp);
	g_object_unref (ffrom);

	return ret;

fail:
	g_free (from);

	g_set_error (
		error, G_IO_ERROR,
		g_io_error_from_errno (errno),
		_("Error copying mail temp file: %s"),
		g_strerror (errno));

	g_object_unref (mp);
	g_object_unref (ffrom);

	return -1;
}
#endif /* ENABLE_BROKEN_SPOOL */

