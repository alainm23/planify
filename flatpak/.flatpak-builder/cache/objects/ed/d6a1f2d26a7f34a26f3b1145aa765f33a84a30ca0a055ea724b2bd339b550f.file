/*
 * module-trust-prompt.c
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

#include <glib/gi18n-lib.h>

#include <libebackend/libebackend.h>
#include "trust-prompt.h"

/* Standard GObject macros */
#define E_TYPE_TRUST_PROMPT (e_trust_prompt_get_type ())
#define E_TRUST_PROMPT(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), E_TYPE_TRUST_PROMPT, ETrustPrompt))

typedef struct _ETrustPrompt ETrustPrompt;
typedef struct _ETrustPromptClass ETrustPromptClass;

struct _ETrustPrompt {
	EUserPrompterServerExtension parent;
};

struct _ETrustPromptClass {
	EUserPrompterServerExtensionClass parent_class;
};

/* Module Entry Points */
void e_module_load (GTypeModule *type_module);
void e_module_unload (GTypeModule *type_module);

/* Forward Declarations */
GType e_trust_prompt_get_type (void);

G_DEFINE_DYNAMIC_TYPE (
	ETrustPrompt,
	e_trust_prompt,
	E_TYPE_USER_PROMPTER_SERVER_EXTENSION)

#define TRUST_PROMPT_DIALOG "ETrustPrompt::trust-prompt"

/* dialog definitions */

/* ETrustPrompt::trust-prompt
 * The dialog expects these parameters:
 *    "host" - host from which the certificate is received
 *    "markup" - markup for the trust prompt, if not set, then "SSL/TLS certificate for '<b>host</b>' is not trusted. Do you wish to accept it?" is used
 *    "certificate" - a base64-encoded DER certificate, for which ask on trust
 *    "certificate-errors" - a hexa-decimal integer (as string) corresponding to GTlsCertificateFlags
 *
 * Result of the dialog is:
 *    0 - reject
 *    1 - accept permanently
 *    2 - accept temporarily
 *   -1 - user didn't choose any of the above
 *
 * The dialog doesn't provide any additional values in the response.
 */

static gchar *
cert_errors_to_reason (GTlsCertificateFlags flags)
{
	struct _convert_table {
		GTlsCertificateFlags flag;
		const gchar *description;
	} convert_table[] = {
		{ G_TLS_CERTIFICATE_UNKNOWN_CA,
		  N_("The signing certificate authority is not known.") },
		{ G_TLS_CERTIFICATE_BAD_IDENTITY,
		  N_("The certificate does not match the expected identity of the site that it was retrieved from.") },
		{ G_TLS_CERTIFICATE_NOT_ACTIVATED,
		  N_("The certificate’s activation time is still in the future.") },
		{ G_TLS_CERTIFICATE_EXPIRED,
		  N_("The certificate has expired.") },
		{ G_TLS_CERTIFICATE_REVOKED,
		  N_("The certificate has been revoked according to the connection’s certificate revocation list.") },
		{ G_TLS_CERTIFICATE_INSECURE,
		  N_("The certificate’s algorithm is considered insecure.") }
	};

	GString *reason = g_string_new ("");
	gint ii;

	for (ii = 0; ii < G_N_ELEMENTS (convert_table); ii++) {
		if ((flags & convert_table[ii].flag) != 0) {
			if (reason->len > 0)
				g_string_append (reason, "\n");

			g_string_append (reason, _(convert_table[ii].description));
		}
	}

	return g_string_free (reason, FALSE);
}

static void
parser_parsed_cb (GcrParser *parser,
                  GcrParsed **out_parsed)
{
	GcrParsed *parsed;

	parsed = gcr_parser_get_parsed (parser);
	g_return_if_fail (parsed != NULL);

	*out_parsed = gcr_parsed_ref (parsed);
}

static gboolean
trust_prompt_show_trust_prompt (EUserPrompterServerExtension *extension,
                                gint prompt_id,
                                const ENamedParameters *parameters)
{
	const gchar *host, *markup, *base64_cert, *cert_errs_str;
	gchar *reason;
	gint64 cert_errs;
	GcrParser *parser;
	GcrParsed *parsed = NULL;
	guchar *data;
	gsize data_length;
	gboolean success = FALSE;
	GError *local_error = NULL;

	g_return_val_if_fail (extension != NULL, FALSE);
	g_return_val_if_fail (parameters != NULL, FALSE);

	/* Continue even if PKCS#11 module registration fails.
	 * Certificate details won't display correctly but the
	 * user can still respond to the prompt. */
	gcr_pkcs11_initialize (NULL, &local_error);
	if (local_error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, local_error->message);
		g_clear_error (&local_error);
	}

	host = e_named_parameters_get (parameters, "host");
	markup = e_named_parameters_get (parameters, "markup");
	base64_cert = e_named_parameters_get (parameters, "certificate");
	cert_errs_str = e_named_parameters_get (parameters, "certificate-errors");

	g_return_val_if_fail (host != NULL, FALSE);
	g_return_val_if_fail (base64_cert != NULL, FALSE);
	g_return_val_if_fail (cert_errs_str != NULL, FALSE);

	cert_errs = g_ascii_strtoll (cert_errs_str, NULL, 16);
	reason = cert_errors_to_reason (cert_errs);

	parser = gcr_parser_new ();

	g_signal_connect (
		parser, "parsed",
		G_CALLBACK (parser_parsed_cb), &parsed);

	data = g_base64_decode (base64_cert, &data_length);
	gcr_parser_parse_data (parser, data, data_length, &local_error);
	g_free (data);

	g_object_unref (parser);

	/* Sanity check. */
	g_warn_if_fail (
		((parsed != NULL) && (local_error == NULL)) ||
		((parsed == NULL) && (local_error != NULL)));

	if (parsed != NULL) {
		success = trust_prompt_show (
			extension, prompt_id, host, markup, parsed, reason);
		gcr_parsed_unref (parsed);
	}

	if (local_error != NULL) {
		g_warning ("%s: %s", G_STRFUNC, local_error->message);
		g_clear_error (&local_error);
		success = FALSE;
	}

	g_free (reason);

	return success;
}
static void
trust_prompt_register_dialogs (EExtension *extension,
                               EUserPrompterServer *server)
{
	e_user_prompter_server_register (server, extension, TRUST_PROMPT_DIALOG);
}

static gboolean
trust_prompt_prompt (EUserPrompterServerExtension *extension,
                     gint prompt_id,
                     const gchar *dialog_name,
                     const ENamedParameters *parameters)
{
	if (g_strcmp0 (dialog_name, TRUST_PROMPT_DIALOG) == 0)
		return trust_prompt_show_trust_prompt (extension, prompt_id, parameters);

	return FALSE;
}

static void
e_trust_prompt_class_init (ETrustPromptClass *class)
{
	EUserPrompterServerExtensionClass *server_extension_class;

	server_extension_class = E_USER_PROMPTER_SERVER_EXTENSION_CLASS (class);
	server_extension_class->register_dialogs = trust_prompt_register_dialogs;
	server_extension_class->prompt = trust_prompt_prompt;
}

static void
e_trust_prompt_class_finalize (ETrustPromptClass *class)
{
}

static void
e_trust_prompt_init (ETrustPrompt *trust_prompt)
{
}

G_MODULE_EXPORT void
e_module_load (GTypeModule *type_module)
{
	e_trust_prompt_register_type (type_module);
}

G_MODULE_EXPORT void
e_module_unload (GTypeModule *type_module)
{
}

