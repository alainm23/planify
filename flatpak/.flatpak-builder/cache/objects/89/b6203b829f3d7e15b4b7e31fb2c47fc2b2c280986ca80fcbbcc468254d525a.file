/*
 * e-source-mail-transport.c
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
 * SECTION: e-source-mail-transport
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for an email transport
 *
 * The #ESourceMailTransport extension identifies the #ESource as a
 * mail transport which describes where to send outgoing messages.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceMailTransport *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_MAIL_TRANSPORT);
 * ]|
 **/

#include "e-source-mail-transport.h"

#define E_SOURCE_MAIL_TRANSPORT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_SOURCE_MAIL_TRANSPORT, ESourceMailTransportPrivate))

G_DEFINE_TYPE (
	ESourceMailTransport,
	e_source_mail_transport,
	E_TYPE_SOURCE_BACKEND)

static void
e_source_mail_transport_class_init (ESourceMailTransportClass *class)
{
	ESourceExtensionClass *extension_class;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_MAIL_TRANSPORT;
}

static void
e_source_mail_transport_init (ESourceMailTransport *extension)
{
}

