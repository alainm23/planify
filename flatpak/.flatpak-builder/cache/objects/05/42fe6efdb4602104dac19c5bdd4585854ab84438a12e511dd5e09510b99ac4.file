/*
 * camel-filter-output-stream.h
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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_FILTER_OUTPUT_STREAM_H
#define CAMEL_FILTER_OUTPUT_STREAM_H

#include <gio/gio.h>
#include <camel/camel-mime-filter.h>

/* Standard GObject macros */
#define CAMEL_TYPE_FILTER_OUTPUT_STREAM \
	(camel_filter_output_stream_get_type ())
#define CAMEL_FILTER_OUTPUT_STREAM(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_FILTER_OUTPUT_STREAM, CamelFilterOutputStream))
#define CAMEL_FILTER_OUTPUT_STREAM_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_FILTER_OUTPUT_STREAM, CamelFilterOutputStreamClass))
#define CAMEL_IS_FILTER_OUTPUT_STREAM(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_FILTER_OUTPUT_STREAM))
#define CAMEL_IS_FILTER_OUTPUT_STREAM_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_FILTER_OUTPUT_STREAM))
#define CAMEL_FILTER_OUTPUT_STREAM_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_FILTER_OUTPUT_STREAM, CamelFilterOutputStreamClass))

G_BEGIN_DECLS

typedef struct _CamelFilterOutputStream CamelFilterOutputStream;
typedef struct _CamelFilterOutputStreamClass CamelFilterOutputStreamClass;
typedef struct _CamelFilterOutputStreamPrivate CamelFilterOutputStreamPrivate;

struct _CamelFilterOutputStream {
	GFilterOutputStream parent;
	CamelFilterOutputStreamPrivate *priv;
};

struct _CamelFilterOutputStreamClass {
	GFilterOutputStreamClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_filter_output_stream_get_type
					(void) G_GNUC_CONST;
GOutputStream *	camel_filter_output_stream_new
					(GOutputStream *base_stream,
					 CamelMimeFilter *filter);
CamelMimeFilter *
		camel_filter_output_stream_get_filter
					(CamelFilterOutputStream *filter_stream);

G_END_DECLS

#endif /* CAMEL_FILTER_OUTPUT_STREAM_H */

