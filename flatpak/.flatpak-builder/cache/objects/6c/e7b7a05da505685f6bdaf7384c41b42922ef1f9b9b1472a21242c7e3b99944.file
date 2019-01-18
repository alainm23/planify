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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <time.h>
#include <sys/stat.h>

#ifdef USE_DOT_LOCKING
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#endif

#ifdef USE_FCNTL_LOCKING
#include <fcntl.h>
#include <unistd.h>
#endif

#ifdef USE_FLOCK_LOCKING
#include <sys/file.h>
#endif

#include <gio/gio.h>
#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#ifdef G_OS_WIN32
#include <windows.h>
#endif

#include "camel-lock.h"

#define d(x) /*(printf("%s(%d): ", __FILE__, __LINE__),(x))*/

#define CHECK_CALL(x) G_STMT_START { \
	if ((x) == -1) { \
		g_debug ("%s: Call of '" #x "' failed: %s", G_STRFUNC, g_strerror (errno)); \
	} \
	} G_STMT_END

/**
 * camel_lock_dot:
 * @path: a path to lock
 * @error: return location for a #GError, or %NULL
 *
 * Create an exclusive lock using .lock semantics.
 * All locks are equivalent to write locks (exclusive).
 *
 * The function does nothing and returns success (zero),
 * when dot locking had not been compiled.
 *
 * Returns: -1 on error, sets @ex appropriately.
 **/
gint
camel_lock_dot (const gchar *path,
                GError **error)
{
#ifdef USE_DOT_LOCKING
	gchar *locktmp, *lock;
	gsize lock_len = 0;
	gsize locktmp_len = 0;
	gint retry = 0;
	gint fdtmp;
	struct stat st;

	/* TODO: Is there a reliable way to refresh the lock, if we're still busy with it?
	 * Does it matter?  We will normally also use fcntl too ... */

	/* use alloca, save cleaning up afterwards */
	lock_len = strlen (path) + strlen (".lock") + 1;
	lock = alloca (lock_len);
	g_snprintf (lock, lock_len, "%s.lock", path);
	locktmp_len = strlen (path) + strlen ("XXXXXX") + 1;
	locktmp = alloca (locktmp_len);

	while (retry < CAMEL_LOCK_DOT_RETRY) {

		d (printf ("trying to lock '%s', attempt %d\n", lock, retry));

		if (retry > 0)
			sleep (CAMEL_LOCK_DOT_DELAY);

		g_snprintf (locktmp, locktmp_len, "%sXXXXXX", path);
		fdtmp = g_mkstemp (locktmp);
		if (fdtmp == -1) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Could not create lock file for %s: %s"),
				path, g_strerror (errno));
			return -1;
		}
		close (fdtmp);

		/* apparently return code from link can be unreliable for nfs (see link(2)), so we ignore it */
		link (locktmp, lock);

		/* but we check stat instead (again, see link(2)) */
		if (g_stat (locktmp, &st) == -1) {
			d (printf ("Our lock file %s vanished!?\n", locktmp));

			/* well that was unexpected, try cleanup/retry */
			unlink (locktmp);
			unlink (lock);
		} else {
			d (printf ("tmp lock created, link count is %d\n", st.st_nlink));

			unlink (locktmp);

			/* if we had 2 links, we have created the .lock, return ok, otherwise we need to keep trying */
			if (st.st_nlink == 2)
				return 0;
		}

		/* check for stale lock, kill it */
		if (g_stat (lock, &st) == 0) {
			time_t now = time (NULL);
			printf ("There is an existing lock %" G_GINT64_FORMAT "seconds old\n", (gint64) now - (gint64) st.st_ctime);
			if (st.st_ctime < now - CAMEL_LOCK_DOT_STALE) {
				d (printf ("Removing it now\n"));
				unlink (lock);
			}
		}

		retry++;
	}

	d (printf ("failed to get lock after %d retries\n", retry));

	g_set_error (
		error, G_IO_ERROR, G_IO_ERROR_FAILED,
		_("Timed out trying to get lock file on %s.  "
		"Try again later."), path);
	return -1;
#else /* !USE_DOT_LOCKING */
	return 0;
#endif
}

/**
 * camel_unlock_dot:
 * @path: a path to unlock
 *
 * Attempt to unlock a .lock lock.
 *
 * The function does nothing, when dot locking had not been compiled.
 **/
void
camel_unlock_dot (const gchar *path)
{
#ifdef USE_DOT_LOCKING
	gchar *lock;
	gsize lock_len;

	lock_len = strlen (path) + strlen (".lock") + 1;
	lock = alloca (lock_len);
	g_snprintf (lock, lock_len, "%s.lock", path);
	d (printf ("unlocking %s\n", lock));
	CHECK_CALL (unlink (lock));
#endif
}

/**
 * camel_lock_fcntl:
 * @fd: a file descriptor
 * @type: a #CamelLockType
 * @error: return location for a #GError, or %NULL
 *
 * Create a lock using fcntl(2).
 *
 * @type is CAMEL_LOCK_WRITE or CAMEL_LOCK_READ,
 * to create exclusive or shared read locks
 *
 * The function does nothing and returns success (zero),
 * when fcntl locking had not been compiled.
 *
 * Returns: -1 on error.
 **/
gint
camel_lock_fcntl (gint fd,
                  CamelLockType type,
                  GError **error)
{
#ifdef USE_FCNTL_LOCKING
	struct flock lock;

	d (printf ("fcntl locking %d\n", fd));

	memset (&lock, 0, sizeof (lock));
	lock.l_type = type == CAMEL_LOCK_READ ? F_RDLCK : F_WRLCK;
	if (fcntl (fd, F_SETLK, &lock) == -1) {
		/* If we get a 'locking not vailable' type error,
		 * we assume the filesystem doesn't support fcntl () locking */
		/* this is somewhat system-dependent */
		if (errno != EINVAL && errno != ENOLCK) {
			g_set_error (
				error, G_IO_ERROR,
				g_io_error_from_errno (errno),
				_("Failed to get lock using fcntl(2): %s"),
				g_strerror (errno));
			return -1;
		} else {
			static gint failed = 0;

			if (failed == 0)
				fprintf (stderr, "fcntl(2) locking appears not to work on this filesystem");
			failed++;
		}
	}
#endif
	return 0;
}

/**
 * camel_unlock_fcntl:
 * @fd: a file descriptor
 *
 * Unlock an fcntl lock.
 *
 * The function does nothing, when fcntl locking had not been compiled.
 **/
void
camel_unlock_fcntl (gint fd)
{
#ifdef USE_FCNTL_LOCKING
	struct flock lock;

	d (printf ("fcntl unlocking %d\n", fd));

	memset (&lock, 0, sizeof (lock));
	lock.l_type = F_UNLCK;
	CHECK_CALL (fcntl (fd, F_SETLK, &lock));
#endif
}

/**
 * camel_lock_flock:
 * @fd: a file descriptor
 * @type: a #CamelLockType
 * @error: return location for a #GError, or %NULL
 *
 * Create a lock using flock(2).
 *
 * @type is CAMEL_LOCK_WRITE or CAMEL_LOCK_READ,
 * to create exclusive or shared read locks
 *
 * The function does nothing and returns success (zero),
 * when flock locking had not been compiled.
 *
 * Returns: -1 on error.
 **/
gint
camel_lock_flock (gint fd,
                  CamelLockType type,
                  GError **error)
{
#ifdef USE_FLOCK_LOCKING
	gint op;

	d (printf ("flock locking %d\n", fd));

	if (type == CAMEL_LOCK_READ)
		op = LOCK_SH | LOCK_NB;
	else
		op = LOCK_EX | LOCK_NB;

	if (flock (fd, op) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Failed to get lock using flock(2): %s"),
			g_strerror (errno));
		return -1;
	}
#endif
	return 0;
}

/**
 * camel_unlock_flock:
 * @fd: a file descriptor
 *
 * Unlock an flock lock.
 *
 * The function does nothing, when flock locking had not been compiled.
 **/
void
camel_unlock_flock (gint fd)
{
#ifdef USE_FLOCK_LOCKING
	d (printf ("flock unlocking %d\n", fd));

	CHECK_CALL (flock (fd, LOCK_UN));
#endif
}

/**
 * camel_lock_folder:
 * @path: Path to the file to lock (used for .locking only).
 * @fd: Open file descriptor of the right type to lock.
 * @type: Type of lock, CAMEL_LOCK_READ or CAMEL_LOCK_WRITE.
 * @error: return location for a #GError, or %NULL
 *
 * Attempt to lock a folder, multiple attempts will be made using all
 * locking strategies available.
 *
 * Returns: -1 on error, @ex will describe the locking system that failed.
 **/
gint
camel_lock_folder (const gchar *path,
                   gint fd,
                   CamelLockType type,
                   GError **error)
{
	gint retry = 0;

	while (retry < CAMEL_LOCK_RETRY) {
		if (retry > 0)
			g_usleep (CAMEL_LOCK_DELAY * 1000000);

		if (camel_lock_fcntl (fd, type, error) == 0) {
			if (camel_lock_flock (fd, type, error) == 0) {
				if (camel_lock_dot (path, error) == 0)
					return 0;
				camel_unlock_flock (fd);
			}
			camel_unlock_fcntl (fd);
		}
		retry++;
	}

	return -1;
}

/**
 * camel_unlock_folder:
 * @path: Filename of folder.
 * @fd: Open descrptor on which locks were placed.
 *
 * Free a lock on a folder.
 **/
void
camel_unlock_folder (const gchar *path,
                     gint fd)
{
	camel_unlock_dot (path);
	camel_unlock_flock (fd);
	camel_unlock_fcntl (fd);
}

#if 0
gint
main (gint argc,
      gchar **argv)
{
	GError *error = NULL;
	gint fd1, fd2;

#if 0
	if (camel_lock_dot ("mylock", &error) == 0) {
		if (camel_lock_dot ("mylock", &error) == 0) {
			printf ("Got lock twice?\n");
		} else {
			printf ("failed to get lock 2: %s\n", error->message);
		}
		camel_unlock_dot ("mylock");
	} else {
		printf ("failed to get lock 1: %s\n", error->message);
	}

	if (error != NULL)
		g_clear_error (&error);
#endif

	fd1 = open ("mylock", O_RDWR);
	if (fd1 == -1) {
		printf ("Could not open lock file (mylock): %s", g_strerror (errno));
		return 1;
	}
	fd2 = open ("mylock", O_RDWR);
	if (fd2 == -1) {
		printf ("Could not open lock file (mylock): %s", g_strerror (errno));
		close (fd1);
		return 1;
	}

	if (camel_lock_fcntl (fd1, CAMEL_LOCK_WRITE, &error) == 0) {
		printf ("got fcntl write lock once\n");
		g_usleep (5000000);
		if (camel_lock_fcntl (fd2, CAMEL_LOCK_WRITE, &error) == 0) {
			printf ("got fcntl write lock twice!\n");
		} else {
			printf ("failed to get write lock: %s\n", error->message);
		}

		if (error != NULL)
			g_clear_error (&error);

		if (camel_lock_fcntl (fd2, CAMEL_LOCK_READ, &error) == 0) {
			printf ("got fcntl read lock as well?\n");
			camel_unlock_fcntl (fd2);
		} else {
			printf ("failed to get read lock: %s\n", error->message);
		}

		if (error != NULL)
			g_clear_error (&error);
		camel_unlock_fcntl (fd1);
	} else {
		printf ("failed to get write lock at all: %s\n", error->message);
	}

	if (camel_lock_fcntl (fd1, CAMEL_LOCK_READ, &error) == 0) {
		printf ("got fcntl read lock once\n");
		g_usleep (5000000);
		if (camel_lock_fcntl (fd2, CAMEL_LOCK_WRITE, &error) == 0) {
			printf ("got fcntl write lock too?!\n");
		} else {
			printf ("failed to get write lock: %s\n", error->message);
		}

		if (error != NULL)
			g_clear_error (&error);

		if (camel_lock_fcntl (fd2, CAMEL_LOCK_READ, &error) == 0) {
			printf ("got fcntl read lock twice\n");
			camel_unlock_fcntl (fd2);
		} else {
			printf ("failed to get read lock: %s\n", error->message);
		}

		if (error != NULL)
			g_clear_error (&error);
		camel_unlock_fcntl (fd1);
	}

	close (fd1);
	close (fd2);

	return 0;
}
#endif
