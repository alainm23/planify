/*
 * camel-imapx-command.c
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

#include <string.h>
#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-imapx-job.h"
#include "camel-imapx-server.h"
#include "camel-imapx-store.h"

#include "camel-imapx-command.h"

#define c(...) camel_imapx_debug(command, __VA_ARGS__)

typedef struct _CamelIMAPXRealCommand CamelIMAPXRealCommand;

/* CamelIMAPXCommand + some private bits */
struct _CamelIMAPXRealCommand {
	CamelIMAPXCommand public;

	volatile gint ref_count;

	/* For building the part. */
	GString *buffer;

	/* For network/parse errors. */
	GError *error;
};

/* Safe to cast to a GQueue. */
struct _CamelIMAPXCommandQueue {
	GQueue g_queue;
};

CamelIMAPXCommand *
camel_imapx_command_new (CamelIMAPXServer *is,
                         guint32 job_kind,
                         const gchar *format,
                         ...)
{
	CamelIMAPXRealCommand *real_ic;
	static gint tag = 0;
	va_list ap;

	real_ic = g_slice_new0 (CamelIMAPXRealCommand);

	/* Initialize private bits. */
	real_ic->ref_count = 1;
	real_ic->buffer = g_string_sized_new (512);

	/* Initialize public bits. */
	real_ic->public.is = is;
	real_ic->public.tag = tag++;
	real_ic->public.job_kind = job_kind;
	real_ic->public.status = NULL;
	real_ic->public.completed = FALSE;
	real_ic->public.copy_move_expunged = NULL;
	g_queue_init (&real_ic->public.parts);

	if (format != NULL && *format != '\0') {
		va_start (ap, format);
		camel_imapx_command_addv (
			(CamelIMAPXCommand *) real_ic, format, ap);
		va_end (ap);
	}

	return (CamelIMAPXCommand *) real_ic;
}

CamelIMAPXCommand *
camel_imapx_command_ref (CamelIMAPXCommand *ic)
{
	CamelIMAPXRealCommand *real_ic;

	g_return_val_if_fail (CAMEL_IS_IMAPX_COMMAND (ic), NULL);

	real_ic = (CamelIMAPXRealCommand *) ic;

	g_atomic_int_inc (&real_ic->ref_count);

	return ic;
}

void
camel_imapx_command_unref (CamelIMAPXCommand *ic)
{
	CamelIMAPXRealCommand *real_ic;

	g_return_if_fail (CAMEL_IS_IMAPX_COMMAND (ic));

	real_ic = (CamelIMAPXRealCommand *) ic;

	if (g_atomic_int_dec_and_test (&real_ic->ref_count)) {
		CamelIMAPXCommandPart *cp;

		/* Free the public stuff. */

		imapx_free_status (ic->status);

		while ((cp = g_queue_pop_head (&ic->parts)) != NULL) {
			g_free (cp->data);
			if (cp->ob) {
				switch (cp->type & CAMEL_IMAPX_COMMAND_MASK) {
				case CAMEL_IMAPX_COMMAND_FILE:
				case CAMEL_IMAPX_COMMAND_STRING:
					g_free (cp->ob);
					break;
				default:
					g_object_unref (cp->ob);
				}
			}
			g_free (cp);
		}

		/* Free the private stuff. */

		g_string_free (real_ic->buffer, TRUE);
		g_slist_free (real_ic->public.copy_move_expunged);

		g_clear_error (&real_ic->error);

		/* Fill the memory with a bit pattern before releasing
		 * it back to the slab allocator, so we can more easily
		 * identify dangling CamelIMAPXCommand pointers. */
		memset (real_ic, 0xaa, sizeof (CamelIMAPXRealCommand));

		/* But leave the reference count set to zero, so
		 * CAMEL_IS_IMAPX_COMMAND can identify it as bad. */
		real_ic->ref_count = 0;

		g_slice_free (CamelIMAPXRealCommand, real_ic);
	}
}

gboolean
camel_imapx_command_check (CamelIMAPXCommand *ic)
{
	CamelIMAPXRealCommand *real_ic;

	real_ic = (CamelIMAPXRealCommand *) ic;

	return (real_ic != NULL && real_ic->ref_count > 0);
}

void
camel_imapx_command_add (CamelIMAPXCommand *ic,
                         const gchar *format,
                         ...)
{
	va_list ap;

	g_return_if_fail (CAMEL_IS_IMAPX_COMMAND (ic));

	if (format != NULL && *format != '\0') {
		va_start (ap, format);
		camel_imapx_command_addv (ic, format, ap);
		va_end (ap);
	}
}

void
camel_imapx_command_addv (CamelIMAPXCommand *ic,
                          const gchar *format,
                          va_list ap)
{
	const gchar *p, *ps, *start;
	guchar c;
	guint width;
	gchar ch;
	gint llong;
	gchar *s;
	gchar *P;
	gint d;
	glong l;
	guint32 f;
	const CamelNamedFlags *F;
	CamelDataWrapper *D;
	CamelSasl *A;
	gchar literal_format[16];
	CamelIMAPXMailbox *mailbox;
	GString *buffer;
	gchar *utf7_name = NULL;
	const gchar *name;
	gboolean use_utf8_string = FALSE;

	g_return_if_fail (CAMEL_IS_IMAPX_COMMAND (ic));

	c (camel_imapx_server_get_tagprefix (ic->is), "adding command, format = '%s'\n", format);

	buffer = ((CamelIMAPXRealCommand *) ic)->buffer;

	p = format;
	ps = format;
	while ((c = *p++) != '\0') {
		switch (c) {
		case '%':
			if (*p == '%') {
				g_string_append_len (buffer, ps, p - ps);
				p++;
				ps = p;
				continue;
			}

			g_string_append_len (buffer, ps, p - ps - 1);
			start = p - 1;
			width = 0;
			llong = 0;

			do {
				c = *p++;
				if (c == '0')
					;
				else if ( c== '-')
					;
				else
					break;
			} while (c);

			do {
				if (g_ascii_isdigit (c))
					width = width * 10 + (c - '0');
				else
					break;
			} while ((c = *p++));

			while (c == 'l') {
				llong++;
				c = *p++;
			}

			switch (c) {
			case 'A': /* auth object - sasl auth, treat as special kind of continuation */
				A = va_arg (ap, CamelSasl *);
				camel_imapx_command_add_part (ic, CAMEL_IMAPX_COMMAND_AUTH, A);
				break;
			case 'D': /* datawrapper */
				D = va_arg (ap, CamelDataWrapper *);
				c (camel_imapx_server_get_tagprefix (ic->is), "got data wrapper '%p'\n", D);
				camel_imapx_command_add_part (ic, CAMEL_IMAPX_COMMAND_DATAWRAPPER, D);
				break;
			case 'P': /* filename path */
				P = va_arg (ap, gchar *);
				c (camel_imapx_server_get_tagprefix (ic->is), "got file path '%s'\n", P);
				camel_imapx_command_add_part (ic, CAMEL_IMAPX_COMMAND_FILE, P);
				break;
			case 't': /* token */
				s = va_arg (ap, gchar *);
				g_string_append (buffer, s);
				break;
			case 's': /* simple string */
				s = va_arg (ap, gchar *);
				use_utf8_string = FALSE;
				c (camel_imapx_server_get_tagprefix (ic->is), "got string '%s'\n", g_str_has_prefix (format, "LOGIN") ? "***" : s);
			output_string:
				if (s && *s) {
					guchar mask = imapx_is_mask (s);

					if (use_utf8_string && !(mask & IMAPX_TYPE_ATOM_CHAR)) {
						g_string_append_c (buffer, '"');
						g_string_append (buffer, s);
						g_string_append_c (buffer, '"');
					} else if (mask & IMAPX_TYPE_ATOM_CHAR) {
						g_string_append (buffer, s);
					} else if (mask & IMAPX_TYPE_TEXT_CHAR) {
						gboolean is_gmail_search = FALSE;

						g_string_append_c (buffer, '"');
						if (ic->job_kind == CAMEL_IMAPX_JOB_UID_SEARCH) {
							is_gmail_search = g_str_has_prefix (format, " X-GM-RAW");

							if (is_gmail_search)
								g_string_append (buffer, "\\\"");
						}

						while (*s) {
							gchar *start = s;

							while (*s && imapx_is_quoted_char (*s))
								s++;
							g_string_append_len (buffer, start, s - start);
							if (*s) {
								g_string_append_c (buffer, '\\');
								g_string_append_c (buffer, *s);
								s++;
							}
						}

						if (is_gmail_search)
							g_string_append (buffer, "\\\"");

						g_string_append_c (buffer, '"');
					} else {
						camel_imapx_command_add_part (ic, CAMEL_IMAPX_COMMAND_STRING, s);
					}
				} else {
					g_string_append (buffer, "\"\"");
				}
				g_free (utf7_name);
				utf7_name = NULL;
				break;
			case 'M': /* CamelIMAPXMailbox */
				mailbox = va_arg (ap, CamelIMAPXMailbox *);
				name = camel_imapx_mailbox_get_name (mailbox);
				if (camel_imapx_server_get_utf8_accept (ic->is)) {
					use_utf8_string = TRUE;
					s = (gchar *) name;
				} else {
					utf7_name = camel_utf8_utf7 (name);
					s = utf7_name;
				}
				goto output_string;
			case 'm': /* UTF-8 mailbox name */
				name = va_arg (ap, gchar *);
				if (camel_imapx_server_get_utf8_accept (ic->is)) {
					use_utf8_string = TRUE;
					s = (gchar *) name;
				} else {
					utf7_name = camel_utf8_utf7 (name);
					s = utf7_name;
				}
				goto output_string;
			case 'F': /* IMAP flags set */
				f = va_arg (ap, guint32);
				F = va_arg (ap, const CamelNamedFlags *);
				imapx_write_flags (buffer, f, F);
				break;
			case 'c':
				d = va_arg (ap, gint);
				ch = d;
				g_string_append_c (buffer, ch);
				break;
			case 'd': /* int/unsigned */
			case 'u':
				if (llong == 1) {
					l = va_arg (ap, glong);
					c (camel_imapx_server_get_tagprefix (ic->is), "got glong '%d'\n", (gint) l);
					memcpy (literal_format, start, p - start);
					literal_format[p - start] = 0;
					g_string_append_printf (buffer, literal_format, l);
				} else if (llong == 2) {
					guint64 i64 = va_arg (ap, guint64);
					c (camel_imapx_server_get_tagprefix (ic->is), "got guint64 '%d'\n", (gint) i64);
					memcpy (literal_format, start, p - start);
					literal_format[p - start] = 0;
					g_string_append_printf (buffer, literal_format, i64);
				} else {
					d = va_arg (ap, gint);
					c (camel_imapx_server_get_tagprefix (ic->is), "got gint '%d'\n", d);
					memcpy (literal_format, start, p - start);
					literal_format[p - start] = 0;
					g_string_append_printf (buffer, literal_format, d);
				}
				break;
			}

			ps = p;
			break;

		case '\\':	/* only for \\ really, we dont support \n\r etc at all */
			c = *p;
			if (c) {
				g_warn_if_fail (c == '\\');
				g_string_append_len (buffer, ps, p - ps);
				p++;
				ps = p;
			}
		}
	}

	g_string_append_len (buffer, ps, p - ps - 1);
}

static gboolean
imapx_file_ends_with_crlf (const gchar *filename)
{
	CamelStream *null_stream, *input_stream;
	gboolean ends_with_crlf;

	g_return_val_if_fail (filename != NULL, FALSE);

	input_stream = camel_stream_fs_new_with_name (filename, O_RDONLY, 0, NULL);
	if (!input_stream)
		return FALSE;

	null_stream = camel_stream_null_new ();
	camel_stream_write_to_stream (input_stream, null_stream, NULL, NULL);
	camel_stream_flush (input_stream, NULL, NULL);
	g_object_unref (input_stream);

	ends_with_crlf = camel_stream_null_get_ends_with_crlf (CAMEL_STREAM_NULL (null_stream));

	g_object_unref (null_stream);

	return ends_with_crlf;
}

void
camel_imapx_command_add_part (CamelIMAPXCommand *ic,
                              CamelIMAPXCommandPartType type,
                              gpointer data)
{
	CamelIMAPXCommandPart *cp;
	GString *buffer;
	guint ob_size = 0;
	gboolean ends_with_crlf = TRUE;

	buffer = ((CamelIMAPXRealCommand *) ic)->buffer;

	/* TODO: literal+? */

	switch (type & CAMEL_IMAPX_COMMAND_MASK) {
	case CAMEL_IMAPX_COMMAND_DATAWRAPPER: {
		CamelObject *ob = data;
		GOutputStream *stream;

		stream = camel_null_output_stream_new ();
		camel_data_wrapper_write_to_output_stream_sync (
			CAMEL_DATA_WRAPPER (ob), stream, NULL, NULL);
		type |= CAMEL_IMAPX_COMMAND_LITERAL_PLUS;
		g_object_ref (ob);
		ob_size = camel_null_output_stream_get_bytes_written (
			CAMEL_NULL_OUTPUT_STREAM (stream));
		ends_with_crlf = camel_null_output_stream_get_ends_with_crlf (CAMEL_NULL_OUTPUT_STREAM (stream));
		g_object_unref (stream);
		break;
	}
	case CAMEL_IMAPX_COMMAND_AUTH: {
		CamelObject *ob = data;
		const gchar *mechanism;

		/* we presume we'll need to get additional data only if we're not authenticated yet */
		g_object_ref (ob);
		mechanism = camel_sasl_get_mechanism (CAMEL_SASL (ob));
		if (camel_sasl_is_xoauth2_alias (mechanism))
			mechanism = "XOAUTH2";
		g_string_append (buffer, mechanism);
		if (!camel_sasl_get_authenticated ((CamelSasl *) ob))
			type |= CAMEL_IMAPX_COMMAND_CONTINUATION;
		break;
	}
	case CAMEL_IMAPX_COMMAND_FILE: {
		gchar *path = data;
		struct stat st;

		if (g_stat (path, &st) == 0) {
			data = g_strdup (data);
			ob_size = st.st_size;

			ends_with_crlf = imapx_file_ends_with_crlf (data);
		} else
			data = NULL;

		type |= CAMEL_IMAPX_COMMAND_LITERAL_PLUS;
		break;
	}
	case CAMEL_IMAPX_COMMAND_STRING:
		data = g_strdup (data);
		ob_size = strlen (data);
		type |= CAMEL_IMAPX_COMMAND_LITERAL_PLUS;
		break;
	default:
		ob_size = 0;
	}

	if (type & CAMEL_IMAPX_COMMAND_LITERAL_PLUS) {
		guint total_size = ob_size;

		if (ic->job_kind == CAMEL_IMAPX_JOB_APPEND_MESSAGE && !ends_with_crlf)
			total_size += 2;

		g_string_append_c (buffer, '{');
		g_string_append_printf (buffer, "%u", total_size);
		if (camel_imapx_server_have_capability (ic->is, IMAPX_CAPABILITY_LITERALPLUS)) {
			g_string_append_c (buffer, '+');
		} else {
			type &= ~CAMEL_IMAPX_COMMAND_LITERAL_PLUS;
			type |= CAMEL_IMAPX_COMMAND_CONTINUATION;
		}
		g_string_append_c (buffer, '}');
	}

	cp = g_malloc0 (sizeof (*cp));
	cp->type = type;
	cp->ob_size = ob_size;
	cp->ob = data;
	cp->data_size = buffer->len;
	cp->data = g_strdup (buffer->str);
	cp->ends_with_crlf = ends_with_crlf;

	g_string_set_size (buffer, 0);

	g_queue_push_tail (&ic->parts, cp);
}

void
camel_imapx_command_close (CamelIMAPXCommand *ic)
{
	GString *buffer;

	g_return_if_fail (CAMEL_IS_IMAPX_COMMAND (ic));

	buffer = ((CamelIMAPXRealCommand *) ic)->buffer;

	if (buffer->len > 5 && g_ascii_strncasecmp (buffer->str, "LOGIN", 5) == 0) {
		c (camel_imapx_server_get_tagprefix (ic->is), "completing command buffer is [%d] 'LOGIN...'\n", (gint) buffer->len);
	} else {
		c (camel_imapx_server_get_tagprefix (ic->is), "completing command buffer is [%d] '%.*s'\n", (gint) buffer->len, (gint) buffer->len, buffer->str);
	}
	if (buffer->len > 0)
		camel_imapx_command_add_part (ic, CAMEL_IMAPX_COMMAND_SIMPLE, NULL);

	g_string_set_size (buffer, 0);
}
