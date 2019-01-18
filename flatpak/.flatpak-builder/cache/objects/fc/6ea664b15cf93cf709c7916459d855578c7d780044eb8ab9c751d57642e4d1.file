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

#include <string.h>

#include "camel-mime-filter.h"

/*#define MALLOC_CHECK */ /* for some malloc checking, requires mcheck enabled */

/* only suitable for glibc */
#ifdef MALLOC_CHECK
#include <mcheck.h>
#endif

#define CAMEL_MIME_FILTER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_MIME_FILTER, CamelMimeFilterPrivate))

struct _CamelMimeFilterPrivate {
	gchar *inbuf;
	gsize inlen;
};

/* Compatible with filter() and complete() methods. */
typedef void	(*FilterMethod)			(CamelMimeFilter *filter,
						 const gchar *in,
						 gsize len,
						 gsize prespace,
						 gchar **out,
						 gsize *outlen,
						 gsize *outprespace);

#define PRE_HEAD (64)
#define BACK_HEAD (64)

G_DEFINE_ABSTRACT_TYPE (CamelMimeFilter, camel_mime_filter, G_TYPE_OBJECT)

static void
mime_filter_finalize (GObject *object)
{
	CamelMimeFilter *mime_filter;

	mime_filter = CAMEL_MIME_FILTER (object);

	g_free (mime_filter->outreal);
	g_free (mime_filter->backbuf);
	g_free (mime_filter->priv->inbuf);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_mime_filter_parent_class)->finalize (object);
}

static void
mime_filter_complete (CamelMimeFilter *mime_filter,
                      const gchar *in,
                      gsize len,
                      gsize prespace,
                      gchar **out,
                      gsize *outlen,
                      gsize *outprespace)
{
	/* default - do nothing */
}

static void
camel_mime_filter_class_init (CamelMimeFilterClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelMimeFilterPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = mime_filter_finalize;

	class->complete = mime_filter_complete;
}

static void
camel_mime_filter_init (CamelMimeFilter *mime_filter)
{
	mime_filter->priv = CAMEL_MIME_FILTER_GET_PRIVATE (mime_filter);

	mime_filter->outreal = NULL;
	mime_filter->outbuf = NULL;
	mime_filter->outsize = 0;

	mime_filter->backbuf = NULL;
	mime_filter->backsize = 0;
	mime_filter->backlen = 0;
}

/**
 * camel_mime_filter_new:
 *
 * Create a new #CamelMimeFilter object.
 *
 * Returns: a new #CamelMimeFilter
 **/
CamelMimeFilter *
camel_mime_filter_new (void)
{
	return g_object_new (CAMEL_TYPE_MIME_FILTER, NULL);
}

#ifdef MALLOC_CHECK
static void
checkmem (gpointer p)
{
	if (p) {
		gint status = mprobe (p);

		switch (status) {
		case MCHECK_HEAD:
			printf ("Memory underrun at %p\n", p);
			abort ();
		case MCHECK_TAIL:
			printf ("Memory overrun at %p\n", p);
			abort ();
		case MCHECK_FREE:
			printf ("Double free %p\n", p);
			abort ();
		}
	}
}
#endif

static void
filter_run (CamelMimeFilter *f,
            const gchar *in,
            gsize len,
            gsize prespace,
            gchar **out,
            gsize *outlen,
            gsize *outprespace,
            FilterMethod method)
{
#ifdef MALLOC_CHECK
	checkmem (f->outreal);
	checkmem (f->backbuf);
#endif
	/*
	 * here we take a performance hit, if the input buffer doesn't
	 * have the pre-space required.  We make a buffer that does ...
	*/
	if (f->backlen > 0) {
		struct _CamelMimeFilterPrivate *p;
		gint newlen;

		p = CAMEL_MIME_FILTER_GET_PRIVATE (f);

		newlen = len + prespace + f->backlen;
		if (p->inlen < newlen) {
			/* NOTE: g_realloc copies data, we dont need that (slower) */
			g_free (p->inbuf);
			p->inbuf = g_malloc (newlen + PRE_HEAD);
			p->inlen = newlen + PRE_HEAD;
		}

		/* copy to end of structure */
		memcpy (p->inbuf + p->inlen - len, in, len);
		in = p->inbuf + p->inlen - len;
		prespace = p->inlen - len;

		/* preload any backed up data */
		memcpy ((gchar *) in - f->backlen, f->backbuf, f->backlen);
		in -= f->backlen;
		len += f->backlen;
		prespace -= f->backlen;
		f->backlen = 0;
	}

#ifdef MALLOC_CHECK
	checkmem (f->outreal);
	checkmem (f->backbuf);
#endif

	method (f, in, len, prespace, out, outlen, outprespace);

#ifdef MALLOC_CHECK
	checkmem (f->outreal);
	checkmem (f->backbuf);
#endif

}

/**
 * camel_mime_filter_filter:
 * @filter: a #CamelMimeFilter object
 * @in: (array length=len): input buffer
 * @len: length of @in
 * @prespace: amount of prespace
 * @out: (out) (array length=outlen): pointer to the output buffer (to be set)
 * @outlen: (out): pointer to the length of the output buffer (to be set)
 * @outprespace: (out): pointer to the output prespace length (to be set)
 *
 * Passes the input buffer, @in, through @filter and generates an
 * output buffer, @out.
 **/
void
camel_mime_filter_filter (CamelMimeFilter *filter,
                          const gchar *in,
                          gsize len,
                          gsize prespace,
                          gchar **out,
                          gsize *outlen,
                          gsize *outprespace)
{
	CamelMimeFilterClass *class;

	g_return_if_fail (CAMEL_IS_MIME_FILTER (filter));
	g_return_if_fail (in != NULL);

	class = CAMEL_MIME_FILTER_GET_CLASS (filter);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->filter != NULL);

	filter_run (
		filter, in, len, prespace, out,
		outlen, outprespace, class->filter);
}

/**
 * camel_mime_filter_complete:
 * @filter: a #CamelMimeFilter object
 * @in: (array length=len): input buffer
 * @len: length of @in
 * @prespace: amount of prespace
 * @out: (out) (array length=outlen): pointer to the output buffer (to be set)
 * @outlen: (out): pointer to the length of the output buffer (to be set)
 * @outprespace: (out): pointer to the output prespace length (to be set)
 *
 * Passes the input buffer, @in, through @filter and generates an
 * output buffer, @out and makes sure that all data is flushed to the
 * output buffer. This must be the last filtering call made, no
 * further calls to camel_mime_filter_filter() may be called on @filter
 * until @filter has been reset using camel_mime_filter_reset().
 **/
void
camel_mime_filter_complete (CamelMimeFilter *filter,
                            const gchar *in,
                            gsize len,
                            gsize prespace,
                            gchar **out,
                            gsize *outlen,
                            gsize *outprespace)
{
	CamelMimeFilterClass *class;

	g_return_if_fail (CAMEL_IS_MIME_FILTER (filter));
	g_return_if_fail (in != NULL);

	class = CAMEL_MIME_FILTER_GET_CLASS (filter);
	g_return_if_fail (class != NULL);
	g_return_if_fail (class->complete != NULL);

	filter_run (
		filter, in, len, prespace, out,
		outlen, outprespace, class->complete);
}

/**
 * camel_mime_filter_reset:
 * @filter: a #CamelMimeFilter object
 *
 * Resets the state on @filter so that it may be used again.
 **/
void
camel_mime_filter_reset (CamelMimeFilter *filter)
{
	CamelMimeFilterClass *class;

	g_return_if_fail (CAMEL_IS_MIME_FILTER (filter));

	class = CAMEL_MIME_FILTER_GET_CLASS (filter);
	g_return_if_fail (class != NULL);

	if (class->reset != NULL)
		class->reset (filter);

	/* could free some buffers, if they are really big? */
	filter->backlen = 0;
}

/**
 * camel_mime_filter_backup:
 * @filter: a #CamelMimeFilter object
 * @data: (array length=length): data buffer to backup
 * @length: length of @data
 *
 * Saves @data to be used as prespace input data to the next call to
 * camel_mime_filter_filter() or camel_mime_filter_complete().
 *
 * Note: New calls replace old data.
 **/
void
camel_mime_filter_backup (CamelMimeFilter *filter,
                          const gchar *data,
                          gsize length)
{
	if (filter->backsize < length) {
		/* g_realloc copies data, unnecessary overhead */
		g_free (filter->backbuf);
		filter->backbuf = g_malloc (length + BACK_HEAD);
		filter->backsize = length + BACK_HEAD;
	}
	filter->backlen = length;
	memcpy (filter->backbuf, data, length);
}

/**
 * camel_mime_filter_set_size:
 * @filter: a #CamelMimeFilter object
 * @size: requested amount of storage space
 * @keep: %TRUE to keep existing buffered data or %FALSE otherwise
 *
 * Ensure that @filter has enough storage space to store @size bytes
 * for filter output.
 **/
void
camel_mime_filter_set_size (CamelMimeFilter *filter,
                            gsize size,
                            gint keep)
{
	if (filter->outsize < size) {
		gint offset = filter->outptr - filter->outreal;
		if (keep) {
			filter->outreal = g_realloc (filter->outreal, size + PRE_HEAD * 4);
		} else {
			g_free (filter->outreal);
			filter->outreal = g_malloc (size + PRE_HEAD * 4);
		}
		filter->outptr = filter->outreal + offset;
		filter->outbuf = filter->outreal + PRE_HEAD * 4;
		filter->outsize = size;
		/* this could be offset from the end of the structure, but
		 * this should be good enough */
		filter->outpre = PRE_HEAD * 4;
	}
}
