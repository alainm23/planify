/*
 * e-source-mail-transport.h
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_MAIL_TRANSPORT_H
#define E_SOURCE_MAIL_TRANSPORT_H

#include <libedataserver/e-source-backend.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_MAIL_TRANSPORT \
	(e_source_mail_transport_get_type ())
#define E_SOURCE_MAIL_TRANSPORT(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_MAIL_TRANSPORT, ESourceMailTransport))
#define E_SOURCE_MAIL_TRANSPORT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_MAIL_TRANSPORT, ESourceMailTransportClass))
#define E_IS_SOURCE_MAIL_TRANSPORT(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_MAIL_TRANSPORT))
#define E_IS_SOURCE_MAIL_TRANSPORT_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_MAIL_TRANSPORT))
#define E_SOURCE_MAIL_TRANSPORT_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_MAIL_TRANSPORT, ESourceMailTransportClass))

/**
 * E_SOURCE_EXTENSION_MAIL_TRANSPORT:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceMailTransport.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_MAIL_TRANSPORT "Mail Transport"

G_BEGIN_DECLS

typedef struct _ESourceMailTransport ESourceMailTransport;
typedef struct _ESourceMailTransportClass ESourceMailTransportClass;
typedef struct _ESourceMailTransportPrivate ESourceMailTransportPrivate;

/**
 * ESourceMailTransport:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceMailTransport {
	/*< private >*/
	ESourceBackend parent;
	ESourceMailTransportPrivate *priv;
};

struct _ESourceMailTransportClass {
	ESourceBackendClass parent_class;
};

GType		e_source_mail_transport_get_type
						(void) G_GNUC_CONST;

G_END_DECLS

#endif /* E_SOURCE_MAIL_TRANSPORT_H */
