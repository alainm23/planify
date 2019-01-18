/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-sendmail-provider.c: sendmail provider registration code
 *
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
 * Authors :
 *   Dan Winship <danw@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <camel/camel.h>
#include <glib/gi18n-lib.h>

#include "camel-sendmail-transport.h"

static CamelProvider sendmail_provider = {
	"sendmail",
	N_("Sendmail"),

	N_("For delivering mail by passing it to the “sendmail” program "
	   "on the local system."),

	"mail",

	0, /* flags */

	0, /* url_flags */

	NULL,  /* conf entries */

	NULL,  /* port entries */

	/* ... */
};

void
camel_provider_module_init (void)
{
	sendmail_provider.object_types[CAMEL_PROVIDER_TRANSPORT] =
		CAMEL_TYPE_SENDMAIL_TRANSPORT;

	sendmail_provider.url_hash = (GHashFunc) camel_url_hash;
	sendmail_provider.url_equal = (GEqualFunc) camel_url_equal;
	sendmail_provider.translation_domain = GETTEXT_PACKAGE;

	camel_provider_register (&sendmail_provider);
}

