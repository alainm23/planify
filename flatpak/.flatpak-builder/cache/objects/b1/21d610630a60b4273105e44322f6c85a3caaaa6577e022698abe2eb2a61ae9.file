/*
 * camel-imapx-input-stream.h
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

#ifndef CAMEL_IMAPX_INPUT_STREAM_H
#define CAMEL_IMAPX_INPUT_STREAM_H

#include <gio/gio.h>

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_INPUT_STREAM \
	(camel_imapx_input_stream_get_type ())
#define CAMEL_IMAPX_INPUT_STREAM(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_INPUT_STREAM, CamelIMAPXInputStream))
#define CAMEL_IMAPX_INPUT_STREAM_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_INPUT_STREAM, CamelIMAPXInputStreamClass))
#define CAMEL_IS_IMAPX_INPUT_STREAM(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_INPUT_STREAM))
#define CAMEL_IS_IMAPX_INPUT_STREAM_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_INPUT_STREAM))
#define CAMEL_IMAPX_INPUT_STREAM_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_INPUT_STREAM, CamelIMAPXInputStreamClass))

#define CAMEL_IMAPX_ERROR \
	(camel_imapx_error_quark ())

G_BEGIN_DECLS

typedef struct _CamelIMAPXInputStream CamelIMAPXInputStream;
typedef struct _CamelIMAPXInputStreamClass CamelIMAPXInputStreamClass;
typedef struct _CamelIMAPXInputStreamPrivate CamelIMAPXInputStreamPrivate;

typedef enum {
	CAMEL_IMAPX_ERROR_SERVER_RESPONSE_MALFORMED = 1,
	CAMEL_IMAPX_ERROR_IGNORE /* may ignore such errors */
} CamelIMAPXError;

typedef enum {
	IMAPX_TOK_ERROR = -1,
	IMAPX_TOK_TOKEN = 256,
	IMAPX_TOK_STRING,
	IMAPX_TOK_INT,
	IMAPX_TOK_LITERAL,
} camel_imapx_token_t;

struct _CamelIMAPXInputStream {
	GFilterInputStream parent;
	CamelIMAPXInputStreamPrivate *priv;
};

struct _CamelIMAPXInputStreamClass {
	GFilterInputStreamClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GQuark		camel_imapx_error_quark		(void) G_GNUC_CONST;
GType		camel_imapx_input_stream_get_type
						(void) G_GNUC_CONST;
GInputStream *	camel_imapx_input_stream_new	(GInputStream *base_stream);
gint		camel_imapx_input_stream_buffered
						(CamelIMAPXInputStream *is);

camel_imapx_token_t
		camel_imapx_input_stream_token	(CamelIMAPXInputStream *is,
						 guchar **start,
						 guint *len,
						 GCancellable *cancellable,
						 GError **error);

void		camel_imapx_input_stream_ungettoken
						(CamelIMAPXInputStream *is,
						 camel_imapx_token_t tok,
						 guchar *token,
						 guint len);
void		camel_imapx_input_stream_set_literal
						(CamelIMAPXInputStream *is,
						 guint literal);
gint		camel_imapx_input_stream_gets	(CamelIMAPXInputStream *is,
						 guchar **start,
						 guint *len,
						 GCancellable *cancellable,
						 GError **error);
gint		 camel_imapx_input_stream_getl	(CamelIMAPXInputStream *is,
						 guchar **start,
						 guint *len,
						 GCancellable *cancellable,
						 GError **error);

/* gets an atom, upper-cases */
gboolean	camel_imapx_input_stream_atom	(CamelIMAPXInputStream *is,
						 guchar **start,
						 guint *len,
						 GCancellable *cancellable,
						 GError **error);
/* gets an atom or string */
gboolean	camel_imapx_input_stream_astring
						(CamelIMAPXInputStream *is,
						 guchar **start,
						 GCancellable *cancellable,
						 GError **error);
/* gets a NIL or a string, start==NULL if NIL */
gboolean	camel_imapx_input_stream_nstring
						(CamelIMAPXInputStream *is,
						 guchar **start,
						 GCancellable *cancellable,
						 GError **error);
/* gets a NIL or string into a GBytes, bytes==NULL if NIL */
gboolean	camel_imapx_input_stream_nstring_bytes
						(CamelIMAPXInputStream *is,
						 GBytes **out_bytes,
						 gboolean with_progress,
						 GCancellable *cancellable,
						 GError **error);
/* gets 'text' */
gboolean	camel_imapx_input_stream_text	(CamelIMAPXInputStream *is,
						 guchar **text,
						 GCancellable *cancellable,
						 GError **error);

/* gets a 'number' */
gboolean	 camel_imapx_input_stream_number
						(CamelIMAPXInputStream *is,
						 guint64 *number,
						 GCancellable *cancellable,
						 GError **error);

/* skips the rest of a line, including literals, etc */
gboolean	camel_imapx_input_stream_skip	(CamelIMAPXInputStream *is,
						 GCancellable *cancellable,
						 GError **error);

gboolean	camel_imapx_input_stream_skip_until
						(CamelIMAPXInputStream *is,
						 const gchar *delimiters,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* CAMEL_IMAPX_INPUT_STREAM_H */
