/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
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

#include "evolution-data-server-config.h"

#include <string.h>
#include <time.h>

#include <glib/gi18n-lib.h>

#include "camel-sasl-popb4smtp.h"
#include "camel-service.h"
#include "camel-session.h"
#include "camel-store.h"

#define CAMEL_SASL_POPB4SMTP_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SASL_POPB4SMTP, CamelSaslPOPB4SMTPPrivate))

struct _CamelSaslPOPB4SMTPPrivate {
	gint placeholder;  /* allow for future expansion */
};

static CamelServiceAuthType sasl_popb4smtp_auth_type = {
	N_("POP before SMTP"),

	N_("This option will authorise a POP connection before attempting SMTP"),

	"POPB4SMTP",
	FALSE,
};

/* last time the pop was accessed (through the auth method anyway), *time_t */
static GHashTable *poplast;

/* use 1 hour as our pop timeout */
#define POPB4SMTP_TIMEOUT (60*60)

static GMutex lock;
#define POPB4SMTP_LOCK(l) g_mutex_lock(&l)
#define POPB4SMTP_UNLOCK(l) g_mutex_unlock(&l)

G_DEFINE_TYPE (CamelSaslPOPB4SMTP, camel_sasl_popb4smtp, CAMEL_TYPE_SASL)

static GByteArray *
sasl_popb4smtp_challenge_sync (CamelSasl *sasl,
                               GByteArray *token,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelService *service;
	CamelSession *session;
	time_t now, *timep;
	const gchar *type_name;
	gchar *pop_uid;

	service = camel_sasl_get_service (sasl);
	session = camel_service_ref_session (service);
	if (!session)
		return NULL;

	camel_sasl_set_authenticated (sasl, FALSE);

	pop_uid = camel_session_get_password (
		session, service, _("POP Source UID"),
		"popb4smtp_uid", 0, error);

	if (pop_uid != NULL)
		service = camel_session_ref_service (session, pop_uid);
	else
		service = NULL;

	g_object_unref (session);

	if (service == NULL) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("POP Before SMTP authentication "
			"using an unknown transport"));
		g_free (pop_uid);
		return NULL;
	}

	type_name = G_OBJECT_TYPE_NAME (service);

	if (!CAMEL_IS_STORE (service)) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("POP Before SMTP authentication attempted "
			"with a %s service"), type_name);
		goto exit;
	}

	if (strstr (type_name, "POP") == NULL) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("POP Before SMTP authentication attempted "
			"with a %s service"), type_name);
		goto exit;
	}

	/* check if we've done it before recently in this session */
	now = time (NULL);

	/* need to lock around the whole thing until finished with timep */

	POPB4SMTP_LOCK (lock);

	timep = g_hash_table_lookup (poplast, pop_uid);
	if (timep) {
		if ((*timep + POPB4SMTP_TIMEOUT) > now) {
			camel_sasl_set_authenticated (sasl, TRUE);
			POPB4SMTP_UNLOCK (lock);
			goto exit;
		}
	} else {
		timep = g_malloc0 (sizeof (*timep));
		g_hash_table_insert (poplast, g_strdup (pop_uid), timep);
	}

	/* connect to pop session */
	if (camel_service_connect_sync (service, cancellable, error)) {
		camel_sasl_set_authenticated (sasl, TRUE);
		*timep = now;
	} else {
		camel_sasl_set_authenticated (sasl, FALSE);
		*timep = 0;
	}

	POPB4SMTP_UNLOCK (lock);

exit:
	g_object_unref (service);
	g_free (pop_uid);

	return NULL;
}

static void
camel_sasl_popb4smtp_class_init (CamelSaslPOPB4SMTPClass *class)
{
	CamelSaslClass *sasl_class;

	g_type_class_add_private (class, sizeof (CamelSaslPOPB4SMTPPrivate));

	sasl_class = CAMEL_SASL_CLASS (class);
	sasl_class->auth_type = &sasl_popb4smtp_auth_type;
	sasl_class->challenge_sync = sasl_popb4smtp_challenge_sync;

	poplast = g_hash_table_new (g_str_hash, g_str_equal);
}

static void
camel_sasl_popb4smtp_init (CamelSaslPOPB4SMTP *sasl)
{
	sasl->priv = CAMEL_SASL_POPB4SMTP_GET_PRIVATE (sasl);
}
