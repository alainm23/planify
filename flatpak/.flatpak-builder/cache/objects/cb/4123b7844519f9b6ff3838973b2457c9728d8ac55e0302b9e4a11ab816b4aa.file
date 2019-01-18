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
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <glib/gi18n-lib.h>

#include "camel-lock-client.h"
#include "camel-lock-helper.h"
#include "camel-object.h"

#define d(x)

#define CHECK_CALL(x) G_STMT_START { \
	if ((x) == -1) { \
		g_debug ("%s: Call of '" #x "' failed: %s", G_STRFUNC, g_strerror (errno)); \
	} \
	} G_STMT_END

static GMutex lock_lock;
#define LOCK() g_mutex_lock(&lock_lock)
#define UNLOCK() g_mutex_unlock(&lock_lock)

static gint lock_sequence;
static gint lock_helper_pid = -1;
static gint lock_stdin_pipe[2], lock_stdout_pipe[2];

static gint read_n (gint fd, gpointer buffer, gint inlen)
{
	gchar *p = buffer;
	gint len, left = inlen;

	do {
		len = read (fd, p, left);
		if (len == -1) {
			if (errno != EINTR)
				return -1;
		} else {
			left -= len;
			p += len;
		}
	} while (left > 0 && len != 0);

	return inlen - left;
}

static gint write_n (gint fd, gpointer buffer, gint inlen)
{
	gchar *p = buffer;
	gint len, left = inlen;

	do {
		len = write (fd, p, left);
		if (len == -1) {
			if (errno != EINTR)
				return -1;
		} else {
			left -= len;
			p += len;
		}
	} while (left > 0);

	return inlen;
}

static gint
lock_helper_init (GError **error)
{
	gint i, dupfd1, dupfd2;

	lock_stdin_pipe[0] = -1;
	lock_stdin_pipe[1] = -1;
	lock_stdout_pipe[0] = -1;
	lock_stdout_pipe[1] = -1;
	if (pipe (lock_stdin_pipe) == -1
	    || pipe (lock_stdout_pipe) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot build locking helper pipe: %s"),
			g_strerror (errno));
		if (lock_stdin_pipe[0] != -1)
			close (lock_stdin_pipe[0]);
		if (lock_stdin_pipe[1] != -1)
			close (lock_stdin_pipe[1]);
		if (lock_stdout_pipe[0] != -1)
			close (lock_stdout_pipe[0]);
		if (lock_stdout_pipe[1] != -1)
			close (lock_stdout_pipe[1]);

		return -1;
	}

	lock_helper_pid = fork ();
	switch (lock_helper_pid) {
	case -1:
		close (lock_stdin_pipe[0]);
		close (lock_stdin_pipe[1]);
		close (lock_stdout_pipe[0]);
		close (lock_stdout_pipe[1]);
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Cannot fork locking helper: %s"),
			g_strerror (errno));
		return -1;
	case 0:
		close (STDIN_FILENO);
		dupfd1 = dup (lock_stdin_pipe[0]);
		close (STDOUT_FILENO);
		dupfd2 = dup (lock_stdout_pipe[1]);
		close (lock_stdin_pipe[0]);
		close (lock_stdin_pipe[1]);
		close (lock_stdout_pipe[0]);
		close (lock_stdout_pipe[1]);
		for (i = 3; i < 255; i++)
			     close (i);
		execl (CAMEL_LIBEXECDIR "/camel-lock-helper-" API_VERSION, "camel-lock-helper", NULL);

		if (dupfd1 != -1)
			close (dupfd1);
		if (dupfd2 != -1)
			close (dupfd2);

		/* it'll pick this up when it tries to use us */
		exit (255);
	default:
		close (lock_stdin_pipe[0]);
		close (lock_stdout_pipe[1]);

		/* so the child knows when we vanish */
		CHECK_CALL (fcntl (lock_stdin_pipe[1], F_SETFD, FD_CLOEXEC));
		CHECK_CALL (fcntl (lock_stdout_pipe[0], F_SETFD, FD_CLOEXEC));
	}

	return 0;
}

gint
camel_lock_helper_lock (const gchar *path,
                        GError **error)
{
	struct _CamelLockHelperMsg *msg;
	gint len = strlen (path);
	gint res = -1;
	gint retry = 3;

	LOCK ();

	if (lock_helper_pid == -1) {
		if (lock_helper_init (error) == -1) {
			UNLOCK ();
			return -1;
		}
	}

	msg = alloca (len + sizeof (*msg));
again:
	msg->magic = CAMEL_LOCK_HELPER_MAGIC;
	msg->seq = lock_sequence;
	msg->id = CAMEL_LOCK_HELPER_LOCK;
	msg->data = len;
	memcpy (msg + 1, path, len);

	write_n (lock_stdin_pipe[1], msg, len + sizeof (*msg));

	do {
		/* should also have a timeout here?  cancellation? */
		len = read_n (lock_stdout_pipe[0], msg, sizeof (*msg));
		if (len == 0) {
			/* child quit, do we try ressurect it? */
			res = CAMEL_LOCK_HELPER_STATUS_PROTOCOL;
			/* if the child exited, this should get it, waidpid returns 0 if the child hasn't */
			if (waitpid (lock_helper_pid, NULL, WNOHANG) > 0) {
				lock_helper_pid = -1;
				close (lock_stdout_pipe[0]);
				close (lock_stdin_pipe[1]);
				lock_stdout_pipe[0] = -1;
				lock_stdin_pipe[1] = -1;
			}
			goto fail;
		}

		if (msg->magic != CAMEL_LOCK_HELPER_RETURN_MAGIC
		    || msg->seq > lock_sequence) {
			res = CAMEL_LOCK_HELPER_STATUS_PROTOCOL;
			d (printf ("lock child protocol error\n"));
			g_set_error (
				error, CAMEL_ERROR,
				CAMEL_ERROR_GENERIC,
				_("Could not lock “%s”: protocol "
				"error with lock-helper"), path);
			goto fail;
		}
	} while (msg->seq < lock_sequence);

	if (msg->seq == lock_sequence) {
		switch (msg->id) {
		case CAMEL_LOCK_HELPER_STATUS_OK:
			d (printf ("lock child locked ok, id is %d\n", msg->data));
			res = msg->data;
			break;
		default:
			g_set_error (
				error, CAMEL_ERROR,
				CAMEL_ERROR_GENERIC,
				_("Could not lock “%s”"), path);
			d (printf ("locking failed ! status = %d\n", msg->id));
			break;
		}
	} else if (retry > 0) {
		d (printf ("sequence failure, lost message? retry?\n"));
		retry--;
		goto again;
	} else {
		g_set_error (
			error, CAMEL_ERROR,
			CAMEL_ERROR_GENERIC,
			_("Could not lock “%s”: protocol "
			"error with lock-helper"), path);
	}

fail:
	lock_sequence++;

	UNLOCK ();

	return res;
}

gint camel_lock_helper_unlock (gint lockid)
{
	struct _CamelLockHelperMsg *msg;
	gint res = -1;
	gint retry = 3;
	gint len;

	d (printf ("unlocking lock id %d\n", lockid));

	LOCK ();

	/* impossible to unlock if we haven't locked yet */
	if (lock_helper_pid == -1) {
		UNLOCK ();
		return -1;
	}

	msg = alloca (sizeof (*msg));
again:
	msg->magic = CAMEL_LOCK_HELPER_MAGIC;
	msg->seq = lock_sequence;
	msg->id = CAMEL_LOCK_HELPER_UNLOCK;
	msg->data = lockid;

	write_n (lock_stdin_pipe[1], msg, sizeof (*msg));

	do {
		/* should also have a timeout here?  cancellation? */
		len = read_n (lock_stdout_pipe[0], msg, sizeof (*msg));
		if (len == 0) {
			/* child quit, do we try ressurect it? */
			res = CAMEL_LOCK_HELPER_STATUS_PROTOCOL;
			if (waitpid (lock_helper_pid, NULL, WNOHANG) > 0) {
				lock_helper_pid = -1;
				close (lock_stdout_pipe[0]);
				close (lock_stdin_pipe[1]);
				lock_stdout_pipe[0] = -1;
				lock_stdin_pipe[1] = -1;
			}
			goto fail;
		}

		if (msg->magic != CAMEL_LOCK_HELPER_RETURN_MAGIC
		    || msg->seq > lock_sequence) {
			goto fail;
		}
	} while (msg->seq < lock_sequence);

	if (msg->seq == lock_sequence) {
		switch (msg->id) {
		case CAMEL_LOCK_HELPER_STATUS_OK:
			d (printf ("lock child unlocked ok\n"));
			res = 0;
			break;
		default:
			d (printf ("locking failed !\n"));
			break;
		}
	} else if (retry > 0) {
		d (printf ("sequence failure, lost message? retry?\n"));
		lock_sequence++;
		retry--;
		goto again;
	}

fail:
	lock_sequence++;

	UNLOCK ();

	return res;
}

#if 0
gint main (gint argc, gchar **argv)
{
	gint id1, id2;

	d (printf ("locking started\n"));
	lock_helper_init ();

	id1 = camel_lock_helper_lock ("1 path 1");
	if (id1 != -1) {
		d (printf ("lock ok, unlock\n"));
		camel_lock_helper_unlock (id1);
	}

	id1 = camel_lock_helper_lock ("2 path 1");
	id2 = camel_lock_helper_lock ("2 path 2");
	camel_lock_helper_unlock (id2);
	camel_lock_helper_unlock (id1);

	id1 = camel_lock_helper_lock ("3 path 1");
	id2 = camel_lock_helper_lock ("3 path 2");
	camel_lock_helper_unlock (id1);
}
#endif
