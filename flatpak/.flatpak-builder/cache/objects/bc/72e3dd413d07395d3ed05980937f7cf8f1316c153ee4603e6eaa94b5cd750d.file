/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* camel-sendmail-transport.c: Sendmail-based transport class
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
 * Authors: Dan Winship <danw@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>

#include <glib/gi18n-lib.h>

#include "camel-sendmail-settings.h"
#include "camel-sendmail-transport.h"

G_DEFINE_TYPE (
	CamelSendmailTransport,
	camel_sendmail_transport, CAMEL_TYPE_TRANSPORT)

static gchar *
sendmail_get_name (CamelService *service,
                   gboolean brief)
{
	if (brief)
		return g_strdup (_("sendmail"));
	else
		return g_strdup (_("Mail delivery via the sendmail program"));
}

static GPtrArray *
parse_sendmail_args (const gchar *binary,
                     const gchar *args,
                     const gchar *from_addr,
                     CamelAddress *recipients)
{
	GPtrArray *args_arr;
	gint ii, len, argc = 0;
	gchar **argv = NULL;

	g_return_val_if_fail (binary != NULL, NULL);
	g_return_val_if_fail (args != NULL, NULL);
	g_return_val_if_fail (from_addr != NULL, NULL);

	len = camel_address_length (recipients);

	args_arr = g_ptr_array_new_full (5, g_free);
	g_ptr_array_add (args_arr, g_strdup (binary));

	if (args && g_shell_parse_argv (args, &argc, &argv, NULL) && argc > 0 && argv) {
		for (ii = 0; ii < argc; ii++) {
			const gchar *arg = argv[ii];

			if (g_strcmp0 (arg, "%F") == 0) {
				g_ptr_array_add (args_arr, g_strdup (from_addr));
			} else if (g_strcmp0 (arg, "%R") == 0) {
				gint jj;

				for (jj = 0; jj < len; jj++) {
					const gchar *addr = NULL;

					if (!camel_internet_address_get (
						CAMEL_INTERNET_ADDRESS (recipients), jj, NULL, &addr)) {

						/* should not happen, as the array is checked beforehand */

						g_ptr_array_free (args_arr, TRUE);
						g_strfreev (argv);

						return NULL;
					}

					g_ptr_array_add (args_arr, g_strdup (addr));
				}
			} else {
				g_ptr_array_add (args_arr, g_strdup (arg));
			}
		}

		g_strfreev (argv);
	}

	g_ptr_array_add (args_arr, NULL);

	return args_arr;
}

static gboolean
sendmail_send_to_sync (CamelTransport *transport,
                       CamelMimeMessage *message,
                       CamelAddress *from,
                       CamelAddress *recipients,
		       gboolean *out_sent_message_saved,
                       GCancellable *cancellable,
                       GError **error)
{
	CamelNameValueArray *previous_headers = NULL;
	const gchar *header_name = NULL, *header_value = NULL;
	const gchar *from_addr, *addr;
	GPtrArray *argv_arr;
	gint i, len, fd[2], nullfd, wstat;
	CamelStream *filter;
	CamelMimeFilter *crlf;
	sigset_t mask, omask;
	CamelStream *out;
	CamelSendmailSettings *settings;
	const gchar *binary = SENDMAIL_PATH;
	gchar *custom_binary = NULL, *custom_args = NULL;
	gboolean success;
	pid_t pid;
	guint ii;

	success = camel_internet_address_get (
		CAMEL_INTERNET_ADDRESS (from), 0, NULL, &from_addr);

	if (!success) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Failed to read From address"));
		return FALSE;
	}

	settings = CAMEL_SENDMAIL_SETTINGS (camel_service_ref_settings (CAMEL_SERVICE (transport)));

	if (!camel_sendmail_settings_get_send_in_offline (settings)) {
		CamelSession *session;
		gboolean is_online;

		session = camel_service_ref_session (CAMEL_SERVICE (transport));
		is_online = session && camel_session_get_online (session);
		g_clear_object (&session);

		if (!is_online) {
			g_set_error (
				error, CAMEL_SERVICE_ERROR, CAMEL_SERVICE_ERROR_UNAVAILABLE,
				_("Message send in offline mode is disabled"));
			return FALSE;
		}
	}

	if (camel_sendmail_settings_get_use_custom_binary (settings)) {
		custom_binary = camel_sendmail_settings_dup_custom_binary (settings);
		if (custom_binary && *custom_binary)
			binary = custom_binary;
	}

	if (camel_sendmail_settings_get_use_custom_args (settings)) {
		custom_args = camel_sendmail_settings_dup_custom_args (settings);
		/* means no arguments used */
		if (!custom_args)
			custom_args = g_strdup ("");
	}

	g_object_unref (settings);

	len = camel_address_length (recipients);
	for (i = 0; i < len; i++) {
		success = camel_internet_address_get (
			CAMEL_INTERNET_ADDRESS (recipients), i, NULL, &addr);

		if (!success) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Could not parse recipient list"));
			g_free (custom_binary);
			g_free (custom_args);

			return FALSE;
		}
	}

	argv_arr = parse_sendmail_args (
		binary,
		custom_args ? custom_args : "-i -f %F -- %R",
		from_addr,
		recipients);

	if (!argv_arr) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("Could not parse arguments"));

		g_free (custom_binary);
		g_free (custom_args);

		return FALSE;
	}

	/* unlink the bcc headers */
	previous_headers = camel_medium_dup_headers (CAMEL_MEDIUM (message));
	camel_medium_remove_header (CAMEL_MEDIUM (message), "Bcc");

	if (pipe (fd) == -1) {
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not create pipe to “%s”: %s: "
			"mail not sent"), binary, g_strerror (errno));

		/* restore the bcc headers */
		for (ii = 0; camel_name_value_array_get (previous_headers, ii, &header_name, &header_value); ii++) {
			if (!g_ascii_strcasecmp (header_name, "Bcc")) {
				camel_medium_add_header (CAMEL_MEDIUM (message), header_name, header_value);
			}
		}

		camel_name_value_array_free (previous_headers);
		g_free (custom_binary);
		g_free (custom_args);
		g_ptr_array_free (argv_arr, TRUE);

		return FALSE;
	}

	/* Block SIGCHLD so the calling application doesn't notice
	 * sendmail exiting before we do.
	 */
	sigemptyset (&mask);
	sigaddset (&mask, SIGCHLD);
	sigprocmask (SIG_BLOCK, &mask, &omask);

	pid = fork ();
	switch (pid) {
	case -1:
		g_set_error (
			error, G_IO_ERROR,
			g_io_error_from_errno (errno),
			_("Could not fork “%s”: %s: "
			"mail not sent"), binary, g_strerror (errno));
		close (fd[0]);
		close (fd[1]);
		sigprocmask (SIG_SETMASK, &omask, NULL);

		/* restore the bcc headers */
		for (ii = 0; camel_name_value_array_get (previous_headers, ii, &header_name, &header_value); ii++) {
			if (!g_ascii_strcasecmp (header_name, "Bcc")) {
				camel_medium_add_header (CAMEL_MEDIUM (message), header_name, header_value);
			}
		}

		camel_name_value_array_free (previous_headers);
		g_free (custom_binary);
		g_free (custom_args);
		g_ptr_array_free (argv_arr, TRUE);

		return FALSE;
	case 0:
		/* Child process */
		nullfd = open ("/dev/null", O_RDWR);
		dup2 (fd[0], STDIN_FILENO);
		if (nullfd != -1) {
			/*dup2 (nullfd, STDOUT_FILENO);
			  dup2 (nullfd, STDERR_FILENO);*/
			close (nullfd);
		}
		close (fd[1]);

		execv (binary, (gchar **) argv_arr->pdata);
		_exit (255);
	}

	g_ptr_array_free (argv_arr, TRUE);

	/* Parent process. Write the message out. */
	close (fd[0]);
	out = camel_stream_fs_new_with_fd (fd[1]);

	/* XXX Workaround for lame sendmail implementations
	 *     that can't handle CRLF eoln sequences. */
	filter = camel_stream_filter_new (out);
	crlf = camel_mime_filter_crlf_new (
		CAMEL_MIME_FILTER_CRLF_DECODE,
		CAMEL_MIME_FILTER_CRLF_MODE_CRLF_ONLY);
	camel_stream_filter_add (CAMEL_STREAM_FILTER (filter), crlf);
	g_object_unref (crlf);
	g_object_unref (out);

	out = (CamelStream *) filter;
	if (camel_data_wrapper_write_to_stream_sync (
		CAMEL_DATA_WRAPPER (message), out, cancellable, error) == -1
	    || camel_stream_close (out, cancellable, error) == -1) {
		g_object_unref (out);
		g_prefix_error (error, _("Could not send message: "));

		/* Wait for sendmail to exit. */
		while (waitpid (pid, &wstat, 0) == -1 && errno == EINTR)
			;

		sigprocmask (SIG_SETMASK, &omask, NULL);

		/* restore the bcc headers */
		for (ii = 0; camel_name_value_array_get (previous_headers, ii, &header_name, &header_value); ii++) {
			if (!g_ascii_strcasecmp (header_name, "Bcc")) {
				camel_medium_add_header (CAMEL_MEDIUM (message), header_name, header_value);
			}
		}

		camel_name_value_array_free (previous_headers);
		g_free (custom_binary);
		g_free (custom_args);

		return FALSE;
	}

	g_object_unref (out);

	/* Wait for sendmail to exit. */
	while (waitpid (pid, &wstat, 0) == -1 && errno == EINTR)
		;

	sigprocmask (SIG_SETMASK, &omask, NULL);

	/* restore the bcc headers */
	for (ii = 0; camel_name_value_array_get (previous_headers, ii, &header_name, &header_value); ii++) {
		if (!g_ascii_strcasecmp (header_name, "Bcc")) {
			camel_medium_add_header (CAMEL_MEDIUM (message), header_name, header_value);
		}
	}

	camel_name_value_array_free (previous_headers);

	if (!WIFEXITED (wstat)) {
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("“%s” exited with signal %s: mail not sent."),
			binary, g_strsignal (WTERMSIG (wstat)));
		g_free (custom_binary);
		g_free (custom_args);

		return FALSE;
	} else if (WEXITSTATUS (wstat) != 0) {
		if (WEXITSTATUS (wstat) == 255) {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("Could not execute “%s”: mail not sent."),
				binary);
		} else {
			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("“%s” exited with status %d: "
				"mail not sent."),
				binary, WEXITSTATUS (wstat));
		}
		g_free (custom_binary);
		g_free (custom_args);

		return FALSE;
	}

	g_free (custom_binary);
	g_free (custom_args);

	return TRUE;
}

static void
camel_sendmail_transport_class_init (CamelSendmailTransportClass *class)
{
	CamelServiceClass *service_class;
	CamelTransportClass *transport_class;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->get_name = sendmail_get_name;
	service_class->settings_type = CAMEL_TYPE_SENDMAIL_SETTINGS;

	transport_class = CAMEL_TRANSPORT_CLASS (class);
	transport_class->send_to_sync = sendmail_send_to_sync;
}

static void
camel_sendmail_transport_init (CamelSendmailTransport *sendmail_transport)
{
}

