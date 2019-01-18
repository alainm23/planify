/*
 * camel-imapx-logger.c
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

/**
 * SECTION: camel-imapx-logger
 * @include: camel-imapx-logger.h
 * @short_description: Log input/output streams
 *
 * #CamelIMAPXLogger is a simple #GConverter that just echos data to standard
 * output if the I/O debugging setting is enabled ('CAMEL_DEBUG=imapx:io').
 * Attaches to the #GInputStream and #GOutputStream.
 **/

#include "evolution-data-server-config.h"

#include "camel-imapx-logger.h"

#include <string.h>

#include "camel-imapx-utils.h"

#define CAMEL_IMAPX_LOGGER_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_IMAPX_LOGGER, CamelIMAPXLoggerPrivate))

struct _CamelIMAPXLoggerPrivate {
	gchar prefix;
};

enum {
	PROP_0,
	PROP_PREFIX
};

/* Forward Declarations */
static void	camel_imapx_logger_interface_init
						(GConverterIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	CamelIMAPXLogger,
	camel_imapx_logger,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_CONVERTER,
		camel_imapx_logger_interface_init))

static void
imapx_logger_set_prefix (CamelIMAPXLogger *logger,
                         gchar prefix)
{
	logger->priv->prefix = prefix;
}

static void
imapx_logger_set_property (GObject *object,
                           guint property_id,
                           const GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_PREFIX:
			imapx_logger_set_prefix (
				CAMEL_IMAPX_LOGGER (object),
				g_value_get_schar (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
imapx_logger_get_property (GObject *object,
                           guint property_id,
                           GValue *value,
                           GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_PREFIX:
			g_value_set_schar (
				value,
				camel_imapx_logger_get_prefix (
				CAMEL_IMAPX_LOGGER (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static GConverterResult
imapx_logger_convert (GConverter *converter,
                      gconstpointer inbuf,
                      gsize inbuf_size,
                      gpointer outbuf,
                      gsize outbuf_size,
                      GConverterFlags flags,
                      gsize *bytes_read,
                      gsize *bytes_written,
                      GError **error)
{
	CamelIMAPXLoggerPrivate *priv;
	GConverterResult result;
	gsize min_size;
	const gchar *login_start;

	priv = CAMEL_IMAPX_LOGGER_GET_PRIVATE (converter);

	min_size = MIN (inbuf_size, outbuf_size);

	if (inbuf && min_size)
		memcpy (outbuf, inbuf, min_size);
	*bytes_read = *bytes_written = min_size;

	login_start = g_strstr_len (outbuf, min_size, " LOGIN ");
	if (login_start > (const gchar *) outbuf) {
		const gchar *space = g_strstr_len (outbuf, min_size, " ");

		if (space == login_start) {
			camel_imapx_debug (
				io, priv->prefix, "I/O: '%.*s ...'\n",
				(gint) (login_start - ((const gchar *) outbuf) + 6), (gchar *) outbuf);
		} else {
			/* To print the command the other way */
			login_start = NULL;
		}
	}

	if (!login_start) {
		/* Skip ending '\n' '\r'; it may sometimes show wrong data,
		   when the input is divided into wrong chunks, but it will
		   usually work as is needed, no extra new-lines in the log */
		while (min_size > 0 && (((gchar *) outbuf)[min_size - 1] == '\r' || ((gchar *) outbuf)[min_size - 1] == '\n'))
			min_size--;

		camel_imapx_debug (
			io, priv->prefix, "I/O: '%.*s'\n",
			(gint) min_size, (gchar *) outbuf);
	}

	if ((flags & G_CONVERTER_INPUT_AT_END) != 0)
		result = G_CONVERTER_FINISHED;
	else if ((flags & G_CONVERTER_FLUSH) != 0)
		result = G_CONVERTER_FLUSHED;
	else
		result = G_CONVERTER_CONVERTED;

	return result;
}

static void
imapx_logger_reset (GConverter *converter)
{
	/* Nothing to do. */
}

static void
camel_imapx_logger_class_init (CamelIMAPXLoggerClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelIMAPXLoggerPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = imapx_logger_set_property;
	object_class->get_property = imapx_logger_get_property;

	g_object_class_install_property (
		object_class,
		PROP_PREFIX,
		g_param_spec_char (
			"prefix",
			"Prefix",
			"Output prefix to distinguish connections",
			0x20, 0x7F, '*',
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));
}

static void
camel_imapx_logger_interface_init (GConverterIface *iface)
{
	iface->convert = imapx_logger_convert;
	iface->reset = imapx_logger_reset;
}

static void
camel_imapx_logger_init (CamelIMAPXLogger *logger)
{
	logger->priv = CAMEL_IMAPX_LOGGER_GET_PRIVATE (logger);
}

/**
 * camel_imapx_logger_new:
 * @prefix: a prefix character
 *
 * Creates a new #CamelIMAPXLogger.  Each output line generated by the
 * logger will have a prefix string that includes the @prefix character
 * to distinguish it from other active loggers.
 *
 * Returns: a #CamelIMAPXLogger
 *
 * Since: 3.12
 **/
GConverter *
camel_imapx_logger_new (gchar prefix)
{
	return g_object_new (
		CAMEL_TYPE_IMAPX_LOGGER,
		"prefix", prefix, NULL);
}

/**
 * camel_imapx_logger_get_prefix:
 * @logger: a #CamelIMAPXLogger
 *
 * Returns the prefix character passed to camel_imapx_logger_new().
 *
 * Returns: the prefix character
 *
 * Since: 3.12
 **/
gchar
camel_imapx_logger_get_prefix (CamelIMAPXLogger *logger)
{
	g_return_val_if_fail (CAMEL_IS_IMAPX_LOGGER (logger), 0);

	return logger->priv->prefix;
}

