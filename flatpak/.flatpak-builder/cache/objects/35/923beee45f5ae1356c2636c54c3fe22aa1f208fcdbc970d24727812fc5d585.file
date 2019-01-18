/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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
 */

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "camel-sasl-xoauth2-google.h"

static CamelServiceAuthType sasl_xoauth2_google_auth_type = {
	N_("OAuth2 (Google)"),
	N_("This option will use an OAuth 2.0 "
	   "access token to connect to the Google server"),
	"Google",
	FALSE
};

G_DEFINE_TYPE (CamelSaslXOAuth2Google, camel_sasl_xoauth2_google, CAMEL_TYPE_SASL_XOAUTH2)

static void
camel_sasl_xoauth2_google_class_init (CamelSaslXOAuth2GoogleClass *klass)
{
	CamelSaslClass *sasl_class;

	sasl_class = CAMEL_SASL_CLASS (klass);
	sasl_class->auth_type = &sasl_xoauth2_google_auth_type;
}

static void
camel_sasl_xoauth2_google_init (CamelSaslXOAuth2Google *sasl)
{
}
