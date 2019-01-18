/*
 * camel-imapx-logger.h
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

#ifndef CAMEL_IMAPX_LOGGER_H
#define CAMEL_IMAPX_LOGGER_H

#include <gio/gio.h>

/* Standard GObject macros */
#define CAMEL_TYPE_IMAPX_LOGGER \
	(camel_imapx_logger_get_type ())
#define CAMEL_IMAPX_LOGGER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_IMAPX_LOGGER, CamelIMAPXLogger))
#define CAMEL_IMAPX_LOGGER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_IMAPX_LOGGER, CamelIMAPXLoggerClass))
#define CAMEL_IS_IMAPX_LOGGER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_IMAPX_LOGGER))
#define CAMEL_IS_IMAPX_LOGGER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_IMAPX_LOGGER))
#define CAMEL_IMAPX_LOGGER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_IMAPX_LOGGER, CamelIMAPXLoggerClass))

G_BEGIN_DECLS

typedef struct _CamelIMAPXLogger CamelIMAPXLogger;
typedef struct _CamelIMAPXLoggerClass CamelIMAPXLoggerClass;
typedef struct _CamelIMAPXLoggerPrivate CamelIMAPXLoggerPrivate;

/**
 * CamelIMAPXLogger:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.12
 **/
struct _CamelIMAPXLogger {
	/*< private >*/
	GObject parent;
	CamelIMAPXLoggerPrivate *priv;
};

struct _CamelIMAPXLoggerClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_imapx_logger_get_type	(void) G_GNUC_CONST;
GConverter *	camel_imapx_logger_new		(gchar prefix);
gchar		camel_imapx_logger_get_prefix	(CamelIMAPXLogger *logger);

G_END_DECLS

#endif /* CAMEL_IMAPX_LOGGER_H */

