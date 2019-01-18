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
 * Authors: Jeffrey Stedfast <fejj@ximian.com>
 */

/* If building without Kerberos support, this class is an empty shell. */

#include "evolution-data-server-config.h"

#include <errno.h>

#include <string.h>
#include <sys/types.h>

#ifndef _WIN32
#include <netdb.h>
#include <sys/socket.h>
#endif

#include <gio/gio.h>
#include <glib/gi18n-lib.h>

#include "camel-net-utils.h"
#include "camel-network-settings.h"
#include "camel-sasl-gssapi.h"
#include "camel-session.h"

#ifdef HAVE_KRB5

#ifdef HAVE_HEIMDAL_KRB5
#include <krb5.h>
#else
#include <krb5/krb5.h>
#endif /* HAVE_HEIMDAL_KRB5 */

#ifdef HAVE_ET_COM_ERR_H
#include <et/com_err.h>
#else
#ifdef HAVE_COM_ERR_H
#include <com_err.h>
#endif /* HAVE_COM_ERR_H */
#endif /* HAVE_ET_COM_ERR_H */

#ifdef HAVE_MIT_KRB5
#include <gssapi/gssapi.h>
#include <gssapi/gssapi_generic.h>
#endif /* HAVE_MIT_KRB5 */

#ifdef HAVE_HEIMDAL_KRB5
#include <gssapi.h>
#else
#ifdef HAVE_SUN_KRB5
#include <gssapi/gssapi.h>
#include <gssapi/gssapi_ext.h>
extern gss_OID gss_nt_service_name;
#endif /* HAVE_SUN_KRB5 */
#endif /* HAVE_HEIMDAL_KRB5 */

#define CAMEL_SASL_GSSAPI_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_SASL_GSSAPI, CamelSaslGssapiPrivate))

static const char spnego_OID[] = "\x2b\x06\x01\x05\x05\x02";
static const gss_OID_desc gss_mech_spnego = {
	6,
	(gpointer) &spnego_OID
};

#ifndef GSS_C_OID_KRBV5_DES
#define GSS_C_OID_KRBV5_DES GSS_C_NO_OID
#endif

#define DBUS_PATH		"/org/gnome/KrbAuthDialog"
#define DBUS_INTERFACE		"org.gnome.KrbAuthDialog"
#define DBUS_METHOD		"org.gnome.KrbAuthDialog.acquireTgt"

static CamelServiceAuthType sasl_gssapi_auth_type = {
	N_("GSSAPI"),

	N_("This option will connect to the server using "
	   "Kerberos 5 authentication."),

	"GSSAPI",
	FALSE
};

enum {
	GSSAPI_STATE_INIT,
	GSSAPI_STATE_CONTINUE_NEEDED,
	GSSAPI_STATE_COMPLETE,
	GSSAPI_STATE_AUTHENTICATED
};

#define GSSAPI_SECURITY_LAYER_NONE       (1 << 0)
#define GSSAPI_SECURITY_LAYER_INTEGRITY  (1 << 1)
#define GSSAPI_SECURITY_LAYER_PRIVACY    (1 << 2)

#define DESIRED_SECURITY_LAYER  GSSAPI_SECURITY_LAYER_NONE

struct _CamelSaslGssapiPrivate {
	gint state;
	gss_ctx_id_t ctx;
	gss_name_t target;
	gchar *override_host;
	gchar *override_user;
	gss_OID mech, used_mech;
};

#endif /* HAVE_KRB5 */

G_DEFINE_TYPE (CamelSaslGssapi, camel_sasl_gssapi, CAMEL_TYPE_SASL)

#ifdef HAVE_KRB5

static void
gssapi_set_mechanism_exception (gss_OID mech,
				OM_uint32 minor,
				const gchar *additional_error,
				GError **error)
{
	OM_uint32 tmajor, tminor, message_status = 0;
	char *message = NULL;

	do {
		char *message_part;
		char *new_message;
		gss_buffer_desc status_string;

		tmajor = gss_display_status (&tminor, minor, GSS_C_MECH_CODE,
					     mech, &message_status,
					     &status_string);

		if (tmajor != GSS_S_COMPLETE) {
			message_part = g_strdup_printf (
				_("(Unknown GSSAPI mechanism code: %x)"),
				minor);
			message_status = 0;
		} else {
			message_part = g_strdup (status_string.value);
			gss_release_buffer (&tminor, &status_string);
		}
		if (message) {
			new_message = g_strconcat (message, message_part, NULL);
			free (message_part);
		} else {
			new_message = message_part;
		}
		g_free (message);
		message = new_message;
	} while (message_status != 0);

	if (additional_error && *additional_error) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			/* Translators: the first '%s' is replaced with a generic error message,
			   the second '%s' is replaced with additional error information. */
			C_("gssapi_error", "%s (%s)"), message, additional_error);
	} else {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			"%s", message);
	}

	g_free (message);
}

static void
gssapi_set_exception (gss_OID mech,
		      OM_uint32 major,
		      OM_uint32 minor,
		      const gchar *additional_error,
                      GError **error)
{
	const gchar *str;

	switch (major) {
	case GSS_S_BAD_MECH:
		str = _("The specified mechanism is not supported by the "
			"provided credential, or is unrecognized by the "
			"implementation.");
		break;
	case GSS_S_BAD_NAME:
		str = _("The provided target_name parameter was ill-formed.");
		break;
	case GSS_S_BAD_NAMETYPE:
		str = _("The provided target_name parameter contained an "
			"invalid or unsupported type of name.");
		break;
	case GSS_S_BAD_BINDINGS:
		str = _("The input_token contains different channel "
			"bindings to those specified via the "
			"input_chan_bindings parameter.");
		break;
	case GSS_S_BAD_SIG:
		str = _("The input_token contains an invalid signature, or a "
			"signature that could not be verified.");
		break;
	case GSS_S_NO_CRED:
		str = _("The supplied credentials were not valid for context "
			"initiation, or the credential handle did not "
			"reference any credentials.");
		break;
	case GSS_S_NO_CONTEXT:
		str = _("The supplied context handle did not refer to a valid context.");
		break;
	case GSS_S_DEFECTIVE_TOKEN:
		str = _("The consistency checks performed on the input_token failed.");
		break;
	case GSS_S_DEFECTIVE_CREDENTIAL:
		str = _("The consistency checks performed on the credential failed.");
		break;
	case GSS_S_CREDENTIALS_EXPIRED:
		str = _("The referenced credentials have expired.");
		break;
	case GSS_S_FAILURE:
		return gssapi_set_mechanism_exception (mech, minor, additional_error, error);
		break;
	default:
		str = _("Bad authentication response from server.");
	}

	if (additional_error && *additional_error) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			/* Translators: the first '%s' is replaced with a generic error message,
			   the second '%s' is replaced with additional error information. */
			C_("gssapi_error", "%s (%s)"), str, additional_error);
	} else {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			"%s", str);
	}
}

static void
sasl_gssapi_finalize (GObject *object)
{
	CamelSaslGssapi *sasl = CAMEL_SASL_GSSAPI (object);
	guint32 status;

	if (sasl->priv->ctx != GSS_C_NO_CONTEXT)
		gss_delete_sec_context (
			&status, &sasl->priv->ctx, GSS_C_NO_BUFFER);

	if (sasl->priv->target != GSS_C_NO_NAME)
		gss_release_name (&status, &sasl->priv->target);

	g_free (sasl->priv->override_host);
	g_free (sasl->priv->override_user);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_sasl_gssapi_parent_class)->finalize (object);
}

/* DBUS Specific code */

static gboolean
send_dbus_message (const gchar *name,
		   GError **out_error)
{
	gint success = FALSE;
	GError *error = NULL;
	GDBusConnection *connection;
	GDBusMessage *message, *reply;

	connection = g_bus_get_sync (G_BUS_TYPE_SESSION, NULL, &error);
	if (error) {
		g_prefix_error (&error, _("Could not get session bus:"));
		g_propagate_error (out_error, error);
		return FALSE;
	}

	g_dbus_connection_set_exit_on_close (connection, FALSE);

	/* Create a new message on the DBUS_INTERFACE */
	message = g_dbus_message_new_method_call (DBUS_INTERFACE, DBUS_PATH, DBUS_INTERFACE, "acquireTgt");
	if (!message) {
		g_object_unref (connection);
		return FALSE;
	}

	/* Appends the data as an argument to the message */
	if (strchr (name, '\\'))
		name = strchr (name, '\\');
	g_dbus_message_set_body (message, g_variant_new ("(s)", name));

	/* Sends the message: Have a 300 sec wait timeout  */
	reply = g_dbus_connection_send_message_with_reply_sync (connection, message, G_DBUS_SEND_MESSAGE_FLAGS_NONE, 300 * 1000, NULL, NULL, &error);

	if (!error && reply) {
		if (g_dbus_message_to_gerror (reply, &error)) {
			g_object_unref (reply);
			reply = NULL;
		}
	}

	if (error) {
		g_dbus_error_strip_remote_error (error);
		if (out_error) {
			if (g_error_matches (error, G_DBUS_ERROR, G_DBUS_ERROR_SERVICE_UNKNOWN)) {
				GError *new_error = g_error_new (G_DBUS_ERROR, G_DBUS_ERROR_SERVICE_UNKNOWN,
					_("Cannot ask for Kerberos ticket. Obtain the ticket manually, like on command line with “kinit” or"
					  " open “Online Accounts” in “Settings” and add the Kerberos account there. Reported error was: %s"),
					error->message);
				g_clear_error (&error);
				error = new_error;
			}

			g_propagate_error (out_error, error);
		} else {
			g_error_free (error);
		}
	}

	if (reply) {
		GVariant *body = g_dbus_message_get_body (reply);

		if (body)
			g_variant_get (body, "(b)", &success);

		g_object_unref (reply);
	}

	/* Free the message */
	g_object_unref (message);
	g_object_unref (connection);

	return success;
}

/* END DBus stuff */

static GByteArray *
sasl_gssapi_challenge_sync (CamelSasl *sasl,
                            GByteArray *token,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelSaslGssapiPrivate *priv;
	OM_uint32 major, minor, flags, time;
	gss_buffer_desc inbuf, outbuf;
	GByteArray *challenge = NULL;
	gss_buffer_t input_token;
	gint conf_state;
	gss_qop_t qop;
	gchar *str;
	struct addrinfo *ai, hints;
	const gchar *service_name;
	gchar *host = NULL;
	gchar *user = NULL;
	GError *krb_error = NULL;

	priv = CAMEL_SASL_GSSAPI_GET_PRIVATE (sasl);

	service_name = camel_sasl_get_service_name (sasl);

	if (priv->override_host && priv->override_user) {
		host = g_strdup (priv->override_host);
		user = g_strdup (priv->override_user);
	}

	if (!host || !user) {
		CamelNetworkSettings *network_settings;
		CamelSettings *settings;
		CamelService *service;

		service = camel_sasl_get_service (sasl);

		settings = camel_service_ref_settings (service);
		g_return_val_if_fail (CAMEL_IS_NETWORK_SETTINGS (settings), NULL);

		network_settings = CAMEL_NETWORK_SETTINGS (settings);
		host = camel_network_settings_dup_host (network_settings);
		user = camel_network_settings_dup_user (network_settings);

		g_object_unref (settings);
	}

	g_return_val_if_fail (user != NULL, NULL);

	if (!host || !*host) {
		g_free (host);
		host = g_strdup ("localhost");
	}

	switch (priv->state) {
	case GSSAPI_STATE_INIT:
		memset (&hints, 0, sizeof (hints));
		hints.ai_flags = AI_CANONNAME;
		ai = camel_getaddrinfo (
			host, NULL, &hints, cancellable, error);
		if (ai == NULL)
			goto exit;

		/* HTTP authentication should be SPNEGO not just KRB5 */
		if (!strcmp (service_name, "HTTP"))
			priv->mech = (gss_OID)&gss_mech_spnego;

		str = g_strdup_printf ("%s@%s", service_name, ai->ai_canonname);
		camel_freeaddrinfo (ai);

		inbuf.value = str;
		inbuf.length = strlen (str);
		major = gss_import_name (&minor, &inbuf, GSS_C_NT_HOSTBASED_SERVICE, &priv->target);
		g_free (str);

		if (major != GSS_S_COMPLETE) {
			gssapi_set_exception (priv->mech, major, minor, NULL, error);
			goto exit;
		}

		input_token = GSS_C_NO_BUFFER;

		goto challenge;
		break;
	case GSSAPI_STATE_CONTINUE_NEEDED:
		if (token == NULL) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Bad authentication response from server."));
			goto exit;
		}

		inbuf.value = token->data;
		inbuf.length = token->len;
		input_token = &inbuf;

	challenge:
		major = gss_init_sec_context (
			&minor, GSS_C_NO_CREDENTIAL,
			&priv->ctx, priv->target,
			priv->mech,
			GSS_C_MUTUAL_FLAG |
			GSS_C_REPLAY_FLAG |
			GSS_C_SEQUENCE_FLAG,
			0, GSS_C_NO_CHANNEL_BINDINGS,
			input_token, &priv->used_mech, &outbuf, &flags, &time);

		switch (major) {
		case GSS_S_COMPLETE:
			priv->state = GSSAPI_STATE_COMPLETE;
			break;
		case GSS_S_CONTINUE_NEEDED:
			priv->state = GSSAPI_STATE_CONTINUE_NEEDED;
			break;
		default:
			if (priv->used_mech == GSS_C_OID_KRBV5_DES &&
			    major == (OM_uint32) GSS_S_FAILURE &&
			    (minor == (OM_uint32) KRB5KRB_AP_ERR_TKT_EXPIRED ||
			     minor == (OM_uint32) KRB5KDC_ERR_NEVER_VALID) &&
			    send_dbus_message (user, &krb_error))
					goto challenge;

			gssapi_set_exception (priv->used_mech, major, minor, krb_error ? krb_error->message : NULL, error);
			g_clear_error (&krb_error);
			goto exit;
		}

		challenge = g_byte_array_new ();
		g_byte_array_append (challenge, outbuf.value, outbuf.length);
#ifndef HAVE_HEIMDAL_KRB5
		gss_release_buffer (&minor, &outbuf);
#endif
		break;
	case GSSAPI_STATE_COMPLETE:
		if (token == NULL) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Bad authentication response from server."));
			goto exit;
		}

		inbuf.value = token->data;
		inbuf.length = token->len;

		major = gss_unwrap (&minor, priv->ctx, &inbuf, &outbuf, &conf_state, &qop);
		if (major != GSS_S_COMPLETE) {
			gssapi_set_exception (priv->used_mech, major, minor, NULL, error);
			goto exit;
		}

		if (outbuf.length < 4) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Bad authentication response from server."));
#ifndef HAVE_HEIMDAL_KRB5
			gss_release_buffer (&minor, &outbuf);
#endif
			goto exit;
		}

		/* check that our desired security layer is supported */
		if ((((guchar *) outbuf.value)[0] & DESIRED_SECURITY_LAYER) != DESIRED_SECURITY_LAYER) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Unsupported security layer."));
#ifndef HAVE_HEIMDAL_KRB5
			gss_release_buffer (&minor, &outbuf);
#endif
			goto exit;
		}

		inbuf.length = 4 + strlen (user);
		inbuf.value = str = g_malloc (inbuf.length);
		memcpy (inbuf.value, outbuf.value, 4);
		str[0] = DESIRED_SECURITY_LAYER;
		memcpy (str + 4, user, inbuf.length - 4);

#ifndef HAVE_HEIMDAL_KRB5
		gss_release_buffer (&minor, &outbuf);
#endif

		major = gss_wrap (&minor, priv->ctx, FALSE, qop, &inbuf, &conf_state, &outbuf);
		if (major != GSS_S_COMPLETE) {
			gssapi_set_exception (priv->used_mech, major, minor, NULL, error);
			g_free (str);
			goto exit;
		}

		g_free (str);
		challenge = g_byte_array_new ();
		g_byte_array_append (challenge, outbuf.value, outbuf.length);

#ifndef HAVE_HEIMDAL_KRB5
		gss_release_buffer (&minor, &outbuf);
#endif

		priv->state = GSSAPI_STATE_AUTHENTICATED;

		camel_sasl_set_authenticated (sasl, TRUE);
		break;
	default:
		break;
	}

exit:
	g_free (host);
	g_free (user);

	return challenge;
}

#endif /* HAVE_KRB5 */

static void
camel_sasl_gssapi_class_init (CamelSaslGssapiClass *class)
{
#ifdef HAVE_KRB5
	GObjectClass *object_class;
	CamelSaslClass *sasl_class;

	g_type_class_add_private (class, sizeof (CamelSaslGssapiPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = sasl_gssapi_finalize;

	sasl_class = CAMEL_SASL_CLASS (class);
	sasl_class->auth_type = &sasl_gssapi_auth_type;
	sasl_class->challenge_sync = sasl_gssapi_challenge_sync;
#endif /* HAVE_KRB5 */
}

static void
camel_sasl_gssapi_init (CamelSaslGssapi *sasl)
{
#ifdef HAVE_KRB5
	sasl->priv = CAMEL_SASL_GSSAPI_GET_PRIVATE (sasl);
	sasl->priv->state = GSSAPI_STATE_INIT;
	sasl->priv->ctx = GSS_C_NO_CONTEXT;
	sasl->priv->target = GSS_C_NO_NAME;
	sasl->priv->override_host = NULL;
	sasl->priv->override_user = NULL;
	sasl->priv->mech = GSS_C_OID_KRBV5_DES;
#endif /* HAVE_KRB5 */
}

/**
 * camel_sasl_gssapi_is_available:
 *
 * Returns: Whether the GSSAPI/KRB5 sasl authentication mechanism is available,
 *    which means whether Camel was built with KRB5 enabled.
 *
 * Since: 3.12
 **/
gboolean
camel_sasl_gssapi_is_available (void)
{
#ifdef HAVE_KRB5
	return TRUE;
#else /* HAVE_KRB5 */
	return FALSE;
#endif /* HAVE_KRB5 */
}

/**
 * camel_sasl_gssapi_override_host_and_user:
 * @sasl: a #CamelSaslGssapi
 * @override_host: (nullable): Host name to use during challenge processing; can be %NULL
 * @override_user: (nullable): User name to use during challenge processing; can be %NULL
 *
 * Set host and user to use, instead of those in CamelService's settings.
 * It's both or none, aka either set both, or the settings values are used.
 * This is used to not require CamelService instance at all.
 *
 * Since: 3.12
 **/
void
camel_sasl_gssapi_override_host_and_user (CamelSaslGssapi *sasl,
                                          const gchar *override_host,
                                          const gchar *override_user)
{
	g_return_if_fail (CAMEL_IS_SASL_GSSAPI (sasl));

#ifdef HAVE_KRB5
	if (sasl->priv->override_host != override_host) {
		g_free (sasl->priv->override_host);
		sasl->priv->override_host = g_strdup (override_host);
	}

	if (sasl->priv->override_user != override_user) {
		g_free (sasl->priv->override_user);
		sasl->priv->override_user = g_strdup (override_user);
	}
#else /* HAVE_KRB5 */
	g_warning ("%s: KRB5 not available", G_STRFUNC);
#endif /* HAVE_KRB5 */
}
