/* Command to manually force a compression/dump of an index file
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
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "camel-object.h"
#include "camel-text-index.h"

extern gint camel_init (const gchar *certdb_dir, gboolean nss_init);

G_GNUC_NORETURN static void
do_usage (gchar *argv0)
{
	fprintf (stderr, "Usage: %s [ compress | dump | info ] file(s) ...\n", argv0);
	fprintf (stderr, " compress - compress (an) index file(s)\n");
	fprintf (stderr, " dump - dump (an) index file's content to stdout\n");
	fprintf (stderr, " info - dump summary info to stdout\n");
	exit (1);
}

static gint
do_compress (gint argc,
             gchar **argv)
{
	gint i;
	CamelIndex *idx;

	for (i = 2; i < argc; i++) {
		printf ("Opening index file: %s\n", argv[i]);
		idx = (CamelIndex *) camel_text_index_new (argv[i], O_RDWR);
		if (idx) {
			printf (" Compressing ...\n");
			if (camel_index_compress (idx) == -1) {
				g_object_unref (idx);
				return 1;
			}
			g_object_unref (idx);
		} else {
			printf (" Failed: %s\n", g_strerror (errno));
			return 1;
		}
	}
	return 0;
}

static gint
do_dump (gint argc,
         gchar **argv)
{
	gint i;
	CamelIndex *idx;

	for (i = 2; i < argc; i++) {
		printf ("Opening index file: %s\n", argv[i]);
		idx = (CamelIndex *) camel_text_index_new (argv[i], O_RDONLY);
		if (idx) {
			printf (" Dumping ...\n");
			camel_text_index_dump ((CamelTextIndex *) idx);
			g_object_unref (idx);
		} else {
			printf (" Failed: %s\n", g_strerror (errno));
			return 1;
		}
	}
	return 0;
}

static gint
do_info (gint argc,
         gchar **argv)
{
	gint i;
	CamelIndex *idx;

	for (i = 2; i < argc; i++) {
		printf ("Opening index file: %s\n", argv[i]);
		idx = (CamelIndex *) camel_text_index_new (argv[i], O_RDONLY);
		if (idx) {
			camel_text_index_info ((CamelTextIndex *) idx);
			g_object_unref (idx);
		} else {
			printf (" Failed: %s\n", g_strerror (errno));
			return 0;
		}
	}
	return 1;
}

static gint
do_check (gint argc,
          gchar **argv)
{
	gint i;
	CamelIndex *idx;

	for (i = 2; i < argc; i++) {
		printf ("Opening index file: %s\n", argv[i]);
		idx = (CamelIndex *) camel_text_index_new (argv[i], O_RDONLY);
		if (idx) {
			camel_text_index_validate ((CamelTextIndex *) idx);
			g_object_unref (idx);
		} else {
			printf (" Failed: %s\n", g_strerror (errno));
			return 0;
		}
	}
	return 1;
}

static gint do_perf (gint argc, gchar **argv);

gint main (gint argc, gchar **argv)
{
	if (argc < 2)
		do_usage (argv[0]);

	camel_init (NULL, 0);

	if (!strcmp (argv[1], "compress"))
		return do_compress (argc, argv);
	else if (!strcmp (argv[1], "dump"))
		return do_dump (argc, argv);
	else if (!strcmp (argv[1], "info"))
		return do_info (argc, argv);
	else if (!strcmp (argv[1], "check"))
		return do_check (argc, argv);
	else if (!strcmp (argv[1], "perf"))
		return do_perf (argc, argv);

	do_usage (argv[0]);
	return 1;
}

#include <dirent.h>
#include "camel-stream-null.h"
#include "camel-stream-filter.h"
#include "camel-mime-filter-index.h"
#include "camel-stream-fs.h"

static gint
do_perf (gint argc,
         gchar **argv)
{
	CamelIndex *idx;
	DIR *dir;
	const gchar *path = "/home/notzed/evolution/local/Inbox/mbox/cur";
	struct dirent *d;
	CamelStream *null, *filter, *stream;
	CamelMimeFilter *filter_index;
	gchar *name;
	CamelIndexName *idn;

	dir = opendir (path);
	if (dir == NULL) {
		perror ("open dir");
		return 1;
	}

	idx = (CamelIndex *) camel_text_index_new (
		"/tmp/index", O_TRUNC | O_CREAT | O_RDWR);
	if (idx == NULL) {
		perror ("open index");
		closedir (dir);
		return 1;
	}

	null = camel_stream_null_new ();
	filter = camel_stream_filter_new (null);
	g_object_unref (null);
	filter_index = camel_mime_filter_index_new (idx);
	camel_stream_filter_add ((CamelStreamFilter *) filter, filter_index);

	while ((d = readdir (dir))) {
		printf ("indexing '%s'\n", d->d_name);

		idn = camel_index_add_name (idx, d->d_name);
		camel_mime_filter_index_set_name (
			CAMEL_MIME_FILTER_INDEX (filter_index), idn);
		name = g_strdup_printf ("%s/%s", path, d->d_name);
		stream = camel_stream_fs_new_with_name (name, O_RDONLY, 0, NULL);
		camel_stream_write_to_stream (stream, filter, NULL, NULL);
		g_object_unref (stream);
		g_free (name);

		camel_index_write_name (idx, idn);
		g_object_unref (idn);
		camel_mime_filter_index_set_name (
			CAMEL_MIME_FILTER_INDEX (filter_index), NULL);
	}

	closedir (dir);

	camel_index_sync (idx);
	g_object_unref (idx);

	g_object_unref (filter);
	g_object_unref (filter_index);

	return 0;
}
