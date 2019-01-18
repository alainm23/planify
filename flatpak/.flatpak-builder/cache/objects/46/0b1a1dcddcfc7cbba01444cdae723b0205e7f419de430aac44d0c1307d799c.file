/*ed.txtcamel-unused.txt-*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
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
 * Authors: Christopher Toshok <toshok@ximian.com>
 *	    Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>

#include <glib/gstdio.h>
#include <glib/gi18n-lib.h>

#include "camel-nntp-folder.h"
#include "camel-nntp-private.h"
#include "camel-nntp-resp-codes.h"
#include "camel-nntp-settings.h"
#include "camel-nntp-store-summary.h"
#include "camel-nntp-store.h"
#include "camel-nntp-summary.h"

#ifdef G_OS_WIN32
#include <winsock2.h>
#include <ws2tcpip.h>
#endif

#define CAMEL_NNTP_STORE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_NNTP_STORE, CamelNNTPStorePrivate))

#define w(x)
#define dd(x) (camel_debug("nntp")?(x):0)

#define NNTP_PORT  119
#define NNTPS_PORT 563

#define DUMP_EXTENSIONS

struct _CamelNNTPStorePrivate {
	GMutex property_lock;
	CamelDataCache *cache;
	CamelNNTPStream *stream;
	CamelNNTPStoreSummary *summary;
	CamelNNTPCapabilities capabilities;
	gchar *current_group;
};

enum {
	PROP_0,
	PROP_CONNECTABLE,
	PROP_HOST_REACHABLE
};

static GInitableIface *parent_initable_interface;

/* Forward Declarations */
static void camel_nntp_store_initable_init (GInitableIface *iface);
static void camel_network_service_init (CamelNetworkServiceInterface *iface);
static void camel_subscribable_init (CamelSubscribableInterface *iface);

G_DEFINE_TYPE_WITH_CODE (
	CamelNNTPStore,
	camel_nntp_store,
	CAMEL_TYPE_OFFLINE_STORE,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		camel_nntp_store_initable_init)
	G_IMPLEMENT_INTERFACE (
		CAMEL_TYPE_NETWORK_SERVICE,
		camel_network_service_init)
	G_IMPLEMENT_INTERFACE (
		CAMEL_TYPE_SUBSCRIBABLE,
		camel_subscribable_init))

static void
nntp_store_reset_state (CamelNNTPStore *nntp_store,
                        CamelNNTPStream *nntp_stream)
{
	if (nntp_stream != NULL)
		g_object_ref (nntp_stream);

	g_mutex_lock (&nntp_store->priv->property_lock);

	g_clear_object (&nntp_store->priv->stream);
	nntp_store->priv->stream = nntp_stream;

	g_free (nntp_store->priv->current_group);
	nntp_store->priv->current_group = NULL;

	nntp_store->priv->capabilities = 0;

	g_mutex_unlock (&nntp_store->priv->property_lock);
}

static void
nntp_store_set_property (GObject *object,
                         guint property_id,
                         const GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			camel_network_service_set_connectable (
				CAMEL_NETWORK_SERVICE (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
nntp_store_get_property (GObject *object,
                         guint property_id,
                         GValue *value,
                         GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_CONNECTABLE:
			g_value_take_object (
				value,
				camel_network_service_ref_connectable (
				CAMEL_NETWORK_SERVICE (object)));
			return;

		case PROP_HOST_REACHABLE:
			g_value_set_boolean (
				value,
				camel_network_service_get_host_reachable (
				CAMEL_NETWORK_SERVICE (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
nntp_store_dispose (GObject *object)
{
	CamelNNTPStorePrivate *priv;

	priv = CAMEL_NNTP_STORE_GET_PRIVATE (object);

	/* Only run this the first time. */
	if (priv->summary != NULL) {
		camel_service_disconnect_sync (
			CAMEL_SERVICE (object), TRUE, NULL, NULL);
		camel_store_summary_save (
			CAMEL_STORE_SUMMARY (priv->summary));
	}

	g_clear_object (&priv->cache);
	g_clear_object (&priv->stream);
	g_clear_object (&priv->summary);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (camel_nntp_store_parent_class)->dispose (object);
}

static void
nntp_store_finalize (GObject *object)
{
	CamelNNTPStore *nntp_store = CAMEL_NNTP_STORE (object);
	struct _xover_header *xover, *xn;

	xover = nntp_store->xover;
	while (xover) {
		xn = xover->next;
		g_free (xover);
		xover = xn;
	}

	g_mutex_clear (&nntp_store->priv->property_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_nntp_store_parent_class)->finalize (object);
}

static gint
check_capabilities (CamelNNTPStore *nntp_store,
                    GCancellable *cancellable,
                    GError **error)
{
	CamelNNTPStream *nntp_stream;
	gint ret;
	gchar *line;
	guint len;

	ret = camel_nntp_raw_command_auth (
		nntp_store, cancellable, error, &line, "CAPABILITIES");
	if (ret != 101)
		return -1;

	nntp_stream = camel_nntp_store_ref_stream (nntp_store);

	ret = camel_nntp_stream_line (
		nntp_stream, (guchar **) &line, &len,
		cancellable, error);
	while (ret > 0) {
		while (len > 0 && g_ascii_isspace (*line)) {
			line++;
			len--;
		}

		if (len == 4 && g_ascii_strncasecmp (line, "OVER", len) == 0)
			camel_nntp_store_add_capabilities (
				nntp_store, CAMEL_NNTP_CAPABILITY_OVER);
		if (len == 8 && g_ascii_strncasecmp (line, "STARTTLS", len) == 0)
			camel_nntp_store_add_capabilities (
				nntp_store, CAMEL_NNTP_CAPABILITY_STARTTLS);

		if (len == 1 && g_ascii_strncasecmp (line, ".", len) == 0) {
			ret = 0;
			break;
		}

		ret = camel_nntp_stream_line (
			nntp_stream, (guchar **) &line, &len,
			cancellable, error);
	}

	g_clear_object (&nntp_stream);

	return ret;
}

static struct {
	const gchar *name;
	gint type;
} headers[] = {
	{ "subject", 0 },
	{ "from", 0 },
	{ "date", 0 },
	{ "message-id", 1 },
	{ "references", 0 },
	{ "bytes", 2 },
};

static gint
xover_setup (CamelNNTPStore *nntp_store,
             GCancellable *cancellable,
             GError **error)
{
	CamelNNTPStream *nntp_stream;
	gint ret, i;
	gchar *line;
	guint len;
	guchar c, *p;
	struct _xover_header *xover, *last;

	/* manual override */
	if (nntp_store->xover || getenv ("CAMEL_NNTP_DISABLE_XOVER") != NULL)
		return 0;

	ret = camel_nntp_raw_command_auth (
		nntp_store, cancellable, error, &line, "list overview.fmt");
	if (ret == -1) {
		return -1;
	} else if (ret != 215) {
		/* unsupported command?  ignore */
		return 0;
	}

	last = (struct _xover_header *) &nntp_store->xover;

	nntp_stream = camel_nntp_store_ref_stream (nntp_store);

	/* supported command */
	ret = camel_nntp_stream_line (
		nntp_stream, (guchar **) &line, &len,
		cancellable, error);
	while (ret > 0) {
		p = (guchar *) line;
		xover = g_malloc0 (sizeof (*xover));
		last->next = xover;
		last = xover;
		while ((c = *p++)) {
			if (c == ':') {
				p[-1] = 0;
				for (i = 0; i < G_N_ELEMENTS (headers); i++) {
					if (strcmp (line, headers[i].name) == 0) {
						xover->name = headers[i].name;
						if (strncmp ((gchar *) p, "full", 4) == 0)
							xover->skip = strlen (xover->name) + 1;
						else
							xover->skip = 0;
						xover->type = headers[i].type;
						break;
					}
				}
				break;
			} else {
				p[-1] = g_ascii_tolower (c);
			}
		}

		ret = camel_nntp_stream_line (
			nntp_stream, (guchar **) &line, &len,
			cancellable, error);
	}

	g_clear_object (&nntp_stream);

	return ret;
}

static gboolean
connect_to_server (CamelService *service,
                   GCancellable *cancellable,
                   GError **error)
{
	CamelNNTPStore *nntp_store;
	CamelNNTPStream *nntp_stream = NULL;
	CamelNetworkSettings *network_settings;
	CamelNetworkSecurityMethod method;
	CamelSettings *settings;
	CamelSession *session;
	CamelStream *stream;
	GIOStream *base_stream;
	guchar *buf;
	guint len;
	gchar *host, *user, *mechanism;
	gboolean success = FALSE;

	nntp_store = CAMEL_NNTP_STORE (service);

	session = camel_service_ref_session (service);
	if (!session) {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		return FALSE;
	}

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);
	user = camel_network_settings_dup_user (network_settings);
	method = camel_network_settings_get_security_method (network_settings);
	mechanism = camel_network_settings_dup_auth_mechanism (network_settings);

	g_object_unref (settings);

	base_stream = camel_network_service_connect_sync (
		CAMEL_NETWORK_SERVICE (service), cancellable, error);

	if (base_stream == NULL)
		goto fail;

	stream = camel_stream_new (base_stream);
	nntp_stream = camel_nntp_stream_new (stream);
	g_object_unref (stream);

	/* Read the greeting, if any. */
	if (camel_nntp_stream_line (nntp_stream, &buf, &len, cancellable, error) == -1) {
		g_object_unref (base_stream);
		g_prefix_error (
			error, _("Could not read greeting from %s: "), host);
		goto fail;
	}

	len = strtoul ((gchar *) buf, (gchar **) &buf, 10);
	if (len != 200 && len != 201) {
		while (buf && g_ascii_isspace (*buf))
			buf++;

		g_object_unref (base_stream);
		g_set_error (
			error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
			_("NNTP server %s returned error code %d: %s"),
			host, len, buf);
		goto fail;
	}

	nntp_store_reset_state (nntp_store, nntp_stream);

	if (method == CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT) {
		GIOStream *tls_stream;

		/* May check capabilities, but they are not set yet; as the capability command can fail,
		   try STARTTLS blindly and fail in case it'll fail too. */

		buf = NULL;

		if (camel_nntp_raw_command (nntp_store, cancellable, error, (gchar **) &buf, "STARTTLS") == -1) {
			g_object_unref (base_stream);
			g_prefix_error (
				error,
				_("Failed to issue STARTTLS for NNTP server %s: "),
				host);
			goto fail;
		}

		if (!buf || !*buf || strtoul ((gchar *) buf, (gchar **) &buf, 10) != 382) {
			while (buf && g_ascii_isspace (*buf))
				buf++;

			g_set_error (
				error, CAMEL_ERROR, CAMEL_ERROR_GENERIC,
				_("NNTP server %s doesn’t support STARTTLS: %s"),
				host, (buf && *buf) ? (const gchar *) buf : _("Unknown error"));
			goto exit;
		}

		tls_stream = camel_network_service_starttls (CAMEL_NETWORK_SERVICE (nntp_store), base_stream, error);

		g_clear_object (&base_stream);
		g_clear_object (&nntp_stream);

		if (tls_stream != NULL) {
			stream = camel_stream_new (tls_stream);
			nntp_stream = camel_nntp_stream_new (stream);
			g_object_unref (stream);
			g_object_unref (tls_stream);

			nntp_store_reset_state (nntp_store, nntp_stream);
		} else {
			g_prefix_error (
				error,
				_("Failed to connect to NNTP server %s in secure mode: "),
				host);
			goto exit;
		}
	}

	g_clear_object (&base_stream);

	/* backward compatibility, empty 'mechanism' is a non-migrated account */
	if ((user != NULL && *user != '\0' && (!mechanism || !*mechanism)) ||
	    (mechanism && *mechanism && g_strcmp0 (mechanism, "ANONYMOUS") != 0)) {

		if (!user || !*user) {
			g_set_error_literal (
				error, CAMEL_SERVICE_ERROR,
				CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
				_("Cannot authenticate without a username"));
			goto fail;
		}

		/* XXX No SASL support. */
		if (!camel_session_authenticate_sync (
			session, service, NULL, cancellable, error))
			goto fail;
	}

	/* set 'reader' mode & ignore return code, also ping the server, inn goes offline very quickly otherwise */
	if (camel_nntp_raw_command_auth (nntp_store, cancellable, error, (gchar **) &buf, "mode reader") == -1
	    || camel_nntp_raw_command_auth (nntp_store, cancellable, error, (gchar **) &buf, "date") == -1)
		goto fail;

	if (xover_setup (nntp_store, cancellable, error) == -1)
		goto fail;

	success = TRUE;

	goto exit;

fail:
	nntp_store_reset_state (nntp_store, NULL);

exit:
	g_free (host);
	g_free (user);
	g_free (mechanism);

	g_clear_object (&session);
	g_clear_object (&nntp_stream);

	return success;
}

static gchar *
nntp_store_get_name (CamelService *service,
                     gboolean brief)
{
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	gchar *host;
	gchar *name;

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	host = camel_network_settings_dup_host (network_settings);

	g_object_unref (settings);

	if (brief)
		name = g_strdup_printf ("%s", host);
	else
		name = g_strdup_printf (_("USENET News via %s"), host);

	g_free (host);

	return name;
}

static gboolean
nntp_store_connect_sync (CamelService *service,
                         GCancellable *cancellable,
                         GError **error)
{
	CamelNNTPStore *nntp_store;

	/* Chain up to parent's method. */
	if (!CAMEL_SERVICE_CLASS (camel_nntp_store_parent_class)->connect_sync (service, cancellable, error))
		return FALSE;

	nntp_store = CAMEL_NNTP_STORE (service);

	if (!connect_to_server (service, cancellable, error))
		return FALSE;

	if (check_capabilities (nntp_store, cancellable, NULL) != -1)
		return TRUE;

	/* disconnect and reconnect without capability check */

	nntp_store_reset_state (nntp_store, NULL);

	return connect_to_server (service, cancellable, error);
}

static gboolean
nntp_store_disconnect_sync (CamelService *service,
                            gboolean clean,
                            GCancellable *cancellable,
                            GError **error)
{
	CamelNNTPStore *nntp_store;
	gchar *line;

	nntp_store = CAMEL_NNTP_STORE (service);

	if (clean)
		camel_nntp_raw_command (
			nntp_store, cancellable, NULL, &line, "quit");

	nntp_store_reset_state (nntp_store, NULL);

	/* Chain up to parent's method. */
	return CAMEL_SERVICE_CLASS (camel_nntp_store_parent_class)->disconnect_sync (service, clean, cancellable, error);
}

extern CamelServiceAuthType camel_nntp_anonymous_authtype;
extern CamelServiceAuthType camel_nntp_password_authtype;

static CamelAuthenticationResult
nntp_store_authenticate_sync (CamelService *service,
                              const gchar *mechanism,
                              GCancellable *cancellable,
                              GError **error)
{
	CamelNetworkSettings *network_settings;
	CamelSettings *settings;
	CamelNNTPStore *store;
	CamelAuthenticationResult result;
	const gchar *password;
	gchar *line = NULL;
	gchar *user;
	gint status;

	store = CAMEL_NNTP_STORE (service);

	password = camel_service_get_password (service);

	settings = camel_service_ref_settings (service);

	network_settings = CAMEL_NETWORK_SETTINGS (settings);
	user = camel_network_settings_dup_user (network_settings);

	g_object_unref (settings);

	if (!user || !*user) {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("Cannot authenticate without a username"));
		result = CAMEL_AUTHENTICATION_ERROR;
		goto exit;
	}

	if (password == NULL) {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_CANT_AUTHENTICATE,
			_("Authentication password not available"));
		result = CAMEL_AUTHENTICATION_ERROR;
		goto exit;
	}

	/* XXX Currently only authinfo user/pass is supported. */
	status = camel_nntp_raw_command (
		store, cancellable, error, &line,
		"authinfo user %s", user);
	if (status == NNTP_AUTH_CONTINUE)
		status = camel_nntp_raw_command (
			store, cancellable, error, &line,
			"authinfo pass %s", password);

	switch (status) {
		case NNTP_AUTH_ACCEPTED:
			result = CAMEL_AUTHENTICATION_ACCEPTED;
			break;

		case NNTP_AUTH_REJECTED:
			result = CAMEL_AUTHENTICATION_REJECTED;
			break;

		default:
			result = CAMEL_AUTHENTICATION_ERROR;
			break;
	}

exit:
	g_free (user);

	return result;
}

static GList *
nntp_store_query_auth_types_sync (CamelService *service,
                                  GCancellable *cancellable,
                                  GError **error)
{
	GList *auth_types;

	auth_types = g_list_append (NULL, &camel_nntp_anonymous_authtype);
	auth_types = g_list_append (auth_types, &camel_nntp_password_authtype);

	return auth_types;
}

/*
 * Converts a fully-fledged newsgroup name to a name in short dotted notation,
 * e.g. nl.comp.os.linux.programmeren becomes n.c.o.l.programmeren
 */

static gchar *
nntp_newsgroup_name_short (const gchar *name)
{
	gchar *resptr, *tmp;
	const gchar *ptr2;

	resptr = tmp = g_malloc0 (strlen (name) + 1);

	while ((ptr2 = strchr (name, '.'))) {
		if (ptr2 == name) {
			name++;
			continue;
		}

		*resptr++ = *name;
		*resptr++ = '.';
		name = ptr2 + 1;
	}

	strcpy (resptr, name);
	return tmp;
}

/*
 * This function converts a NNTPStoreSummary item to a FolderInfo item that
 * can be returned by the get_folders() call to the store. Both structs have
 * essentially the same fields.
 */

static CamelFolderInfo *
nntp_folder_info_from_store_info (CamelNNTPStore *store,
                                  gboolean short_notation,
                                  CamelStoreInfo *si)
{
	CamelFolderInfo *fi;

	fi = camel_folder_info_new ();
	fi->full_name = g_strdup (si->path);

	if (short_notation)
		fi->display_name = nntp_newsgroup_name_short (si->path);
	else
		fi->display_name = g_strdup (si->path);

	fi->unread = si->unread;
	fi->total = si->total;
	fi->flags = si->flags;

	return fi;
}

static CamelFolderInfo *
nntp_folder_info_from_name (CamelNNTPStore *store,
                            gboolean short_notation,
                            const gchar *name)
{
	CamelFolderInfo *fi;

	fi = camel_folder_info_new ();
	fi->full_name = g_strdup (name);

	if (short_notation)
		fi->display_name = nntp_newsgroup_name_short (name);
	else
		fi->display_name = g_strdup (name);

	fi->unread = -1;

	return fi;
}

/* handle list/newgroups response */
static CamelStoreInfo *
nntp_store_info_update (CamelNNTPStore *nntp_store,
                        gchar *line,
			gboolean is_folder_list)
{
	CamelNNTPStoreSummary *nntp_store_summary;
	CamelStoreSummary *store_summary;
	CamelNNTPStoreInfo *si, *fsi;
	gchar *relpath, *tmp;
	gsize relpath_len = 0;
	guint32 last = 0, first = 0, new = 0;

	tmp = strchr (line, ' ');
	if (tmp)
		*tmp++ = 0;

	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);

	store_summary = CAMEL_STORE_SUMMARY (nntp_store_summary);
	fsi = si = (CamelNNTPStoreInfo *)
		camel_store_summary_path (store_summary, line);
	if (si == NULL) {
		si = (CamelNNTPStoreInfo *)
			camel_store_summary_info_new (store_summary);

		relpath_len = strlen (line) + 2;
		relpath = g_alloca (relpath_len);
		g_snprintf (relpath, relpath_len, "/%s", line);

		si->info.path = g_strdup (line);
		si->full_name = g_strdup (line); /* why do we keep this? */

		camel_store_summary_add (store_summary, &si->info);
	} else {
		first = si->first;
		last = si->last;
	}

	if (tmp && *tmp >= '0' && *tmp <= '9') {
		last = strtoul (tmp, &tmp, 10);
		if (*tmp == ' ' && tmp[1] >= '0' && tmp[1] <= '9') {
			first = strtoul (tmp + 1, &tmp, 10);
			if (*tmp == ' ' && tmp[1] != 'y')
				si->info.flags |= CAMEL_STORE_INFO_FOLDER_READONLY;
		}
	}

	dd (printf ("store info update '%s' first '%u' last '%u'\n", line, first, last));

	if (si->last) {
		if (last > si->last)
			new = last - si->last;
	} else {
		if (last > first)
			new = last - first;
	}

	si->info.total = last > first ? last - first : (is_folder_list ? -1 : 0);
	si->info.unread += new;	/* this is a _guess_ */
	si->last = last;
	si->first = first;

	if (fsi != NULL)
		camel_store_summary_info_unref (store_summary, &fsi->info);
	else /* TODO see if we really did touch it */
		camel_store_summary_touch (store_summary);

	g_clear_object (&nntp_store_summary);

	return (CamelStoreInfo *) si;
}

static CamelFolderInfo *
nntp_store_get_subscribed_folder_info (CamelNNTPStore *nntp_store,
                                       const gchar *top,
                                       guint flags,
                                       GCancellable *cancellable,
                                       GError **error)
{
	CamelNNTPStoreSummary *nntp_store_summary;
	CamelStoreSummary *store_summary;
	CamelService *service;
	CamelSettings *settings;
	CamelFolderInfo *first = NULL, *last = NULL, *fi = NULL;
	GPtrArray *array;
	gboolean short_folder_names;
	guint ii;

	/* since we do not do a tree, any request that is not for root is sure to give no results */
	if (top != NULL && top[0] != 0)
		return NULL;

	service = CAMEL_SERVICE (nntp_store);

	settings = camel_service_ref_settings (service);

	short_folder_names = camel_nntp_settings_get_short_folder_names (
		CAMEL_NNTP_SETTINGS (settings));

	g_object_unref (settings);

	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);

	store_summary = CAMEL_STORE_SUMMARY (nntp_store_summary);

	array = camel_store_summary_array (store_summary);

	for (ii = 0; ii < array->len; ii++) {
		CamelStoreInfo *si;

		si = g_ptr_array_index (array, ii);

		if ((si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED) == 0)
			continue;

		/* slow mode?  open and update the folder, always! this will
		 * implictly update our storeinfo too; in a very round-about
		 * way */
		if ((flags & CAMEL_STORE_FOLDER_INFO_FAST) == 0) {
			CamelNNTPFolder *folder;
			gchar *line;

			folder = (CamelNNTPFolder *)
				camel_store_get_folder_sync (
				(CamelStore *) nntp_store, si->path,
				0, cancellable, NULL);
			if (folder) {
				CamelFolderChangeInfo *changes = NULL;

				if (camel_nntp_command (nntp_store, cancellable, NULL, folder, NULL, &line, NULL) != -1) {
					if (camel_folder_change_info_changed (folder->changes)) {
						changes = folder->changes;
						folder->changes = camel_folder_change_info_new ();
					}
				}
				if (changes) {
					camel_folder_changed (CAMEL_FOLDER (folder), changes);
					camel_folder_change_info_free (changes);
				}
				g_object_unref (folder);
			}
		}

		fi = nntp_folder_info_from_store_info (
			nntp_store, short_folder_names, si);
		fi->flags |=
			CAMEL_FOLDER_NOINFERIORS |
			CAMEL_FOLDER_NOCHILDREN |
			CAMEL_FOLDER_SYSTEM;
		if (last)
			last->next = fi;
		else
			first = fi;
		last = fi;
	}

	camel_store_summary_array_free (store_summary, array);

	g_clear_object (&nntp_store_summary);

	return first;
}

static CamelFolderInfo *
tree_insert (CamelFolderInfo *root,
             CamelFolderInfo *last,
             CamelFolderInfo *fi)
{
	CamelFolderInfo *kfi;

	if (!root)
		root = fi;
	else if (!last) {
		kfi = root;
		while (kfi->next)
			kfi = kfi->next;
		kfi->next = fi;
		fi->parent = kfi->parent;
	} else {
		if (!last->child) {
			last->child = fi;
			fi->parent = last;
		} else {
			kfi = last->child;
			while (kfi->next)
				kfi = kfi->next;
			kfi->next = fi;
			fi->parent = last;
		}
	}
	return root;
}
/* returns new root */
static CamelFolderInfo *
nntp_push_to_hierarchy (CamelNNTPStore *store,
                        CamelFolderInfo *root,
                        CamelFolderInfo *pfi,
                        GHashTable *known)
{
	CamelFolderInfo *fi, *last = NULL, *kfi;
	gchar *name, *dot;

	g_return_val_if_fail (pfi != NULL, root);
	g_return_val_if_fail (known != NULL, root);

	name = pfi->full_name;
	g_return_val_if_fail (name != NULL, root);

	while (dot = strchr (name, '.'), dot) {
		*dot = '\0';

		kfi = g_hash_table_lookup (known, pfi->full_name);
		if (!kfi) {
			fi = camel_folder_info_new ();
			fi->full_name = g_strdup (pfi->full_name);
			fi->display_name = g_strdup (name);

			fi->unread = -1;
			fi->total = -1;
			fi->flags =
				CAMEL_FOLDER_NOSELECT |
				CAMEL_FOLDER_CHILDREN;

			g_hash_table_insert (known, fi->full_name, fi);
			root = tree_insert (root, last, fi);
			last = fi;
		} else {
			last = kfi;
		}

		*dot = '.';
		name = dot + 1;
	}

	g_free (pfi->display_name);
	pfi->display_name = g_strdup (name);

	return tree_insert (root, last, pfi);
}

static gboolean
nntp_store_path_matches_top (const gchar *path,
			     const gchar *top,
			     gint toplen)
{
	g_return_val_if_fail (path != NULL, FALSE);

	if (toplen <= 0 || !top)
		return TRUE;

	if (strncmp (path, top, toplen) != 0) {
		gchar *short_path;
		gboolean matches = FALSE;

		short_path = nntp_newsgroup_name_short (path);
		if (!short_path)
			return FALSE;

		if (strncmp (short_path, top, toplen) == 0) {
			matches = path[toplen] == 0 || path[toplen] == '.';
		}

		g_free (short_path);

		return matches;
	}

	return path[toplen] == 0 || path[toplen] == '.';
}

/*
 * get folder info, using the information in our StoreSummary
 */
static CamelFolderInfo *
nntp_store_get_cached_folder_info (CamelNNTPStore *nntp_store,
                                   const gchar *top,
                                   guint flags,
                                   GError **error)
{
	CamelNNTPStoreSummary *nntp_store_summary;
	CamelStoreSummary *store_summary;
	CamelService *service;
	CamelSettings *settings;
	CamelFolderInfo *first = NULL, *last = NULL, *fi = NULL;
	GHashTable *known; /* folder name to folder info */
	GPtrArray *array;
	gboolean folder_hierarchy_relative;
	gchar *tmpname;
	gint toplen = top ? strlen (top) : 0;
	gint subscribed_or_flag;
	gint root_or_flag;
	gint recursive_flag;
	gint is_folder_list;
	guint ii;

	subscribed_or_flag =
		(flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIBED) ? 0 : 1;
	root_or_flag =
		(top == NULL || top[0] == '\0') ? 1 : 0;
	recursive_flag =
		(flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE);
	is_folder_list =
		(flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIPTION_LIST);

	service = CAMEL_SERVICE (nntp_store);

	settings = camel_service_ref_settings (service);

	folder_hierarchy_relative =
		camel_nntp_settings_get_folder_hierarchy_relative (
		CAMEL_NNTP_SETTINGS (settings));

	g_object_unref (settings);

	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);

	known = g_hash_table_new (g_str_hash, g_str_equal);

	store_summary = CAMEL_STORE_SUMMARY (nntp_store_summary);

	array = camel_store_summary_array (store_summary);

	for (ii = 0; ii < array->len; ii++) {
		CamelStoreInfo *si;

		si = g_ptr_array_index (array, ii);

		if ((subscribed_or_flag || (si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED))
		    && (root_or_flag || nntp_store_path_matches_top (si->path, top, toplen))) {
			if (recursive_flag || is_folder_list || strchr (si->path + toplen + 1, '.') == NULL) {
				/* add the item */
				fi = nntp_folder_info_from_store_info (nntp_store, FALSE, si);
				if (!fi)
					continue;
				if (folder_hierarchy_relative) {
					g_free (fi->display_name);
					fi->display_name = g_strdup (si->path + ((toplen <= 1) ? 0 : (toplen + 1)));
				}
			} else {
				/* apparently, this is an indirect subitem. if it's not a subitem of
				 * the item we added last, we need to add a portion of this item to
				 * the list as a placeholder */
				if (!last ||
				    strncmp (si->path, last->full_name, strlen (last->full_name)) != 0 ||
				    si->path[strlen (last->full_name)] != '.') {
					gchar *dot;
					tmpname = g_strdup (si->path);
					dot = strchr (tmpname + toplen + 1, '.');
					if (dot)
						*dot = '\0';
					fi = nntp_folder_info_from_name (nntp_store, FALSE, tmpname);
					if (!fi)
						continue;

					fi->flags |= CAMEL_FOLDER_NOSELECT;
					if (folder_hierarchy_relative) {
						g_free (fi->display_name);
						fi->display_name = g_strdup (tmpname + ((toplen <= 1) ? 0 : (toplen + 1)));
					}
					g_free (tmpname);
				} else {
					continue;
				}
			}

			if (fi->full_name && g_hash_table_lookup (known, fi->full_name)) {
				/* a duplicate has been found above */
				camel_folder_info_free (fi);
				continue;
			}

			g_hash_table_insert (known, fi->full_name, fi);

			if (is_folder_list) {
				/* create a folder hierarchy rather than a flat list */
				first = nntp_push_to_hierarchy (nntp_store, first, fi, known);
			} else {
				if (last)
					last->next = fi;
				else
					first = fi;
				last = fi;
			}
		} else if (subscribed_or_flag && first) {
			/* we have already added subitems, but this item is no longer a subitem */
			break;
		}
	}

	camel_store_summary_array_free (store_summary, array);

	g_hash_table_destroy (known);

	g_clear_object (&nntp_store_summary);

	return first;
}

static void
store_info_remove (gpointer key,
                   gpointer value,
                   gpointer data)
{
	CamelStoreSummary *summary = data;
	CamelStoreInfo *si = value;

	camel_store_summary_remove (summary, si);
}

static gint
store_info_sort (gconstpointer a,
		 gconstpointer b,
		 gpointer user_data)
{
	return strcmp ((*(CamelNNTPStoreInfo **) a)->full_name, (*(CamelNNTPStoreInfo **) b)->full_name);
}

/* retrieves the date from the NNTP server */
static gboolean
nntp_get_date (CamelNNTPStore *nntp_store,
               GCancellable *cancellable,
               GError **error)
{
	CamelNNTPStoreSummary *nntp_store_summary;
	guchar *line;
	gint ret;
	gboolean success = FALSE;

	ret = camel_nntp_command (
		nntp_store, cancellable, error, NULL, NULL,
		(gchar **) &line, "date");

	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);
	nntp_store_summary->last_newslist[0] = 0;

	if (ret == 111) {
		const gchar *ptr;

		ptr = (gchar *) line + 3;
		while (*ptr == ' ' || *ptr == '\t')
			ptr++;

		if (strlen (ptr) == NNTP_DATE_SIZE) {
			memcpy (nntp_store_summary->last_newslist, ptr, NNTP_DATE_SIZE);
			success = TRUE;
		}
	}

	g_clear_object (&nntp_store_summary);

	return success;
}

static CamelFolderInfo *
nntp_store_get_folder_info_all (CamelNNTPStore *nntp_store,
                                const gchar *top,
                                CamelStoreGetFolderInfoFlags flags,
                                GCancellable *cancellable,
                                GError **error)
{
	CamelNNTPStream *nntp_stream = NULL;
	CamelNNTPStoreSummary *nntp_store_summary;
	guint len;
	guchar *line;
	gint ret = -1;
	CamelFolderInfo *fi = NULL;
	gboolean is_folder_list = (flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIPTION_LIST) != 0;

	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);

	if (top == NULL)
		top = "";

	if (top == NULL || top[0] == 0) {
		/* we may need to update */
		if (nntp_store_summary->last_newslist[0] != 0) {
			gchar date[14];
			memcpy (date, nntp_store_summary->last_newslist + 2, 6); /* YYMMDDD */
			date[6] = ' ';
			memcpy (date + 7, nntp_store_summary->last_newslist + 8, 6); /* HHMMSS */
			date[13] = '\0';

			/* Some servers don't support date (!), so fallback if they dont */
			if (!nntp_get_date (nntp_store, cancellable, NULL))
				goto do_complete_list_nodate;

			ret = camel_nntp_command (nntp_store, cancellable, error, NULL, &nntp_stream, (gchar **) &line, "newgroups %s", date);
			if (ret == -1)
				goto error;
			else if (ret != 231) {
				/* newgroups not supported :S so reload the complete list */
				nntp_store_summary->last_newslist[0] = 0;
				goto do_complete_list;
			}

			while ((ret = camel_nntp_stream_line (nntp_stream, &line, &len, cancellable, error)) > 0)
				nntp_store_info_update (nntp_store, (gchar *) line, is_folder_list);
		} else {
			CamelStoreSummary *store_summary;
			CamelStoreInfo *si;
			GPtrArray *array;
			GHashTable *all;
			guint ii;

		do_complete_list:
			/* seems we do need a complete list */
			/* at first, we do a DATE to find out the last load occasion */
			nntp_get_date (nntp_store, cancellable, NULL);
		do_complete_list_nodate:
			ret = camel_nntp_command (nntp_store, cancellable, error, NULL, &nntp_stream, (gchar **) &line, "list");
			if (ret == -1)
				goto error;
			else if (ret != 215) {
				g_set_error (
					error, CAMEL_SERVICE_ERROR,
					CAMEL_SERVICE_ERROR_INVALID,
					_("Error retrieving newsgroups:\n\n%s"), line);
				goto error;
			}

			all = g_hash_table_new (g_str_hash, g_str_equal);

			store_summary = CAMEL_STORE_SUMMARY (nntp_store_summary);
			array = camel_store_summary_array (store_summary);

			for (ii = 0; ii < array->len; ii++) {
				si = g_ptr_array_index (array, ii);
				camel_store_summary_info_ref (store_summary, si);
				g_hash_table_insert (all, si->path, si);
			}

			camel_store_summary_array_free (store_summary, array);

			while ((ret = camel_nntp_stream_line (nntp_stream, &line, &len, cancellable, error)) > 0) {
				si = nntp_store_info_update (nntp_store, (gchar *) line, is_folder_list);
				g_hash_table_remove (all, si->path);
			}

			g_hash_table_foreach (
				all, store_info_remove, nntp_store_summary);
			g_hash_table_destroy (all);
		}

		/* sort the list */
		camel_store_summary_sort (CAMEL_STORE_SUMMARY (nntp_store_summary), store_info_sort, NULL);

		if (ret < 0)
			goto error;

		camel_store_summary_save (
			CAMEL_STORE_SUMMARY (nntp_store_summary));
	}

	fi = nntp_store_get_cached_folder_info (nntp_store, top, flags, error);

 error:
	if (nntp_stream)
		camel_nntp_stream_unlock (nntp_stream);
	g_clear_object (&nntp_stream);
	g_clear_object (&nntp_store_summary);

	return fi;
}

static gboolean
nntp_store_can_refresh_folder (CamelStore *store,
                               CamelFolderInfo *info,
                               GError **error)
{
	/* any nntp folder can be refreshed */
	return TRUE;
}

static CamelFolder *
nntp_store_get_folder_sync (CamelStore *store,
                            const gchar *folder_name,
                            CamelStoreGetFolderFlags flags,
                            GCancellable *cancellable,
                            GError **error)
{
	return camel_nntp_folder_new (
		store, folder_name, cancellable, error);
}

static CamelFolderInfo *
nntp_store_get_folder_info_sync (CamelStore *store,
                                 const gchar *top,
                                 CamelStoreGetFolderInfoFlags flags,
                                 GCancellable *cancellable,
                                 GError **error)
{
	CamelNNTPStore *nntp_store = CAMEL_NNTP_STORE (store);
	CamelServiceConnectionStatus status;
	CamelFolderInfo *first = NULL;

	status = camel_service_get_connection_status (CAMEL_SERVICE (store));

	dd (printf (
		"g_f_i: fast %d subscr %d recursive %d top \"%s\"\n",
		flags & CAMEL_STORE_FOLDER_INFO_FAST,
		flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIBED,
		flags & CAMEL_STORE_FOLDER_INFO_RECURSIVE,
		top ? top:""));

	if (flags & CAMEL_STORE_FOLDER_INFO_SUBSCRIBED) {
		first = nntp_store_get_subscribed_folder_info (
			nntp_store, top, flags, cancellable, error);
	} else if (status == CAMEL_SERVICE_CONNECTED) {
		first = nntp_store_get_folder_info_all (
			nntp_store, top, flags, cancellable, error);
	} else {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete "
			"this operation"));
	}

	return first;
}

static CamelFolderInfo *
nntp_store_create_folder_sync (CamelStore *store,
                               const gchar *parent_name,
                               const gchar *folder_name,
                               GCancellable *cancellable,
                               GError **error)
{
	g_set_error (
		error, CAMEL_FOLDER_ERROR,
		CAMEL_FOLDER_ERROR_INVALID,
		_("You cannot create a folder in a News store: "
		"subscribe instead."));

	return NULL;
}

static gboolean
nntp_store_rename_folder_sync (CamelStore *store,
                               const gchar *old_name,
                               const gchar *new_name_in,
                               GCancellable *cancellable,
                               GError **error)
{
	g_set_error (
		error, CAMEL_FOLDER_ERROR,
		CAMEL_FOLDER_ERROR_INVALID,
		_("You cannot rename a folder in a News store."));

	return FALSE;
}

static gboolean
nntp_store_delete_folder_sync (CamelStore *store,
                               const gchar *folder_name,
                               GCancellable *cancellable,
                               GError **error)
{
	CamelSubscribable *subscribable;
	CamelSubscribableInterface *iface;

	subscribable = CAMEL_SUBSCRIBABLE (store);
	iface = CAMEL_SUBSCRIBABLE_GET_INTERFACE (subscribable);

	iface->unsubscribe_folder_sync (
		subscribable, folder_name, cancellable, NULL);

	g_set_error (
		error, CAMEL_FOLDER_ERROR,
		CAMEL_FOLDER_ERROR_INVALID,
		_("You cannot remove a folder in a News store: "
		"unsubscribe instead."));

	return FALSE;
}

/* nntp stores part of its data in user_data_dir and part in user_cache_dir,
 * thus check whether to migrate based on folders.db file */
static void
nntp_migrate_to_user_cache_dir (CamelService *service)
{
	const gchar *user_data_dir, *user_cache_dir;
	gchar *udd_folders_db, *ucd_folders_db;

	g_return_if_fail (service != NULL);
	g_return_if_fail (CAMEL_IS_SERVICE (service));

	user_data_dir = camel_service_get_user_data_dir (service);
	user_cache_dir = camel_service_get_user_cache_dir (service);

	g_return_if_fail (user_data_dir != NULL);
	g_return_if_fail (user_cache_dir != NULL);

	udd_folders_db = g_build_filename (user_data_dir, "folders.db", NULL);
	ucd_folders_db = g_build_filename (user_cache_dir, "folders.db", NULL);

	/* migrate only if the source directory exists and the destination doesn't */
	if (g_file_test (udd_folders_db, G_FILE_TEST_EXISTS) &&
	    !g_file_test (ucd_folders_db, G_FILE_TEST_EXISTS)) {
		gchar *parent_dir;

		parent_dir = g_path_get_dirname (user_cache_dir);
		g_mkdir_with_parents (parent_dir, S_IRWXU);
		g_free (parent_dir);

		if (g_rename (user_data_dir, user_cache_dir) == -1) {
			g_debug ("%s: Failed to migrate '%s' to '%s': %s", G_STRFUNC, user_data_dir, user_cache_dir, g_strerror (errno));
		} else if (g_mkdir_with_parents (user_data_dir, S_IRWXU) != -1) {
			gchar *udd_ev_store_summary, *ucd_ev_store_summary;

			udd_ev_store_summary = g_build_filename (user_data_dir, ".ev-store-summary", NULL);
			ucd_ev_store_summary = g_build_filename (user_cache_dir, ".ev-store-summary", NULL);

			/* return back the .ev-store-summary file, it's saved in user_data_dir */
			if (g_rename (ucd_ev_store_summary, udd_ev_store_summary) == -1)
				g_debug ("%s: Failed to return back '%s' to '%s': %s", G_STRFUNC, ucd_ev_store_summary, udd_ev_store_summary, g_strerror (errno));
		}
	}

	g_free (udd_folders_db);
	g_free (ucd_folders_db);
}

static gboolean
nntp_store_initable_init (GInitable *initable,
                          GCancellable *cancellable,
                          GError **error)
{
	CamelDataCache *nntp_cache;
	CamelNNTPStore *nntp_store;
	CamelStore *store;
	CamelService *service;
	const gchar *user_data_dir;
	const gchar *user_cache_dir;
	gchar *filename;

	nntp_store = CAMEL_NNTP_STORE (initable);
	store = CAMEL_STORE (initable);
	service = CAMEL_SERVICE (initable);

	camel_store_set_flags (store, camel_store_get_flags (store) | CAMEL_STORE_USE_CACHE_DIR);
	nntp_migrate_to_user_cache_dir (service);

	/* Chain up to parent interface's init() method. */
	if (!parent_initable_interface->init (initable, cancellable, error))
		return FALSE;

	service = CAMEL_SERVICE (initable);
	user_data_dir = camel_service_get_user_data_dir (service);
	user_cache_dir = camel_service_get_user_cache_dir (service);

	if (g_mkdir_with_parents (user_data_dir, S_IRWXU) == -1) {
		g_set_error_literal (
			error, G_FILE_ERROR,
			g_file_error_from_errno (errno),
			g_strerror (errno));
		return FALSE;
	}

	filename = g_build_filename (
		user_data_dir, ".ev-store-summary", NULL);
	nntp_store->priv->summary = camel_nntp_store_summary_new ();
	camel_store_summary_set_filename (
		CAMEL_STORE_SUMMARY (nntp_store->priv->summary), filename);
	camel_store_summary_load (
		CAMEL_STORE_SUMMARY (nntp_store->priv->summary));
	g_free (filename);

	/* setup store-wide cache */
	nntp_cache = camel_data_cache_new (user_cache_dir, error);
	if (nntp_cache == NULL)
		return FALSE;

	/* Default cache expiry - 2 weeks old, or not visited in 5 days */
	camel_data_cache_set_expire_age (nntp_cache, 60 * 60 * 24 * 14);
	camel_data_cache_set_expire_access (nntp_cache, 60 * 60 * 24 * 5);

	camel_binding_bind_property (nntp_store, "online",
		nntp_cache, "expire-enabled",
		G_BINDING_SYNC_CREATE);

	nntp_store->priv->cache = nntp_cache;  /* takes ownership */

	return TRUE;
}

static const gchar *
nntp_store_get_service_name (CamelNetworkService *service,
                             CamelNetworkSecurityMethod method)
{
	const gchar *service_name;

	switch (method) {
		case CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
			service_name = "nntps";
			break;

		default:
			service_name = "nntp";
			break;
	}

	return service_name;
}

static guint16
nntp_store_get_default_port (CamelNetworkService *service,
                             CamelNetworkSecurityMethod method)
{
	guint16 default_port;

	switch (method) {
		case CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
			default_port = NNTPS_PORT;
			break;

		default:
			default_port = NNTP_PORT;
			break;
	}

	return default_port;
}

static gboolean
nntp_store_folder_is_subscribed (CamelSubscribable *subscribable,
                                 const gchar *folder_name)
{
	CamelNNTPStore *nntp_store;
	CamelNNTPStoreSummary *nntp_store_summary;
	CamelStoreSummary *store_summary;
	CamelStoreInfo *si;
	gint truth = FALSE;

	nntp_store = CAMEL_NNTP_STORE (subscribable);
	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);

	store_summary = CAMEL_STORE_SUMMARY (nntp_store_summary);
	si = camel_store_summary_path (store_summary, folder_name);

	if (si != NULL) {
		truth = (si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED) != 0;
		camel_store_summary_info_unref (store_summary, si);
	}

	g_clear_object (&nntp_store_summary);

	return truth;
}

static gboolean
nntp_store_subscribe_folder_sync (CamelSubscribable *subscribable,
                                  const gchar *folder_name,
                                  GCancellable *cancellable,
                                  GError **error)
{
	CamelNNTPStore *nntp_store;
	CamelNNTPStoreSummary *nntp_store_summary;
	CamelStoreSummary *store_summary;
	CamelService *service;
	CamelSettings *settings;
	CamelStoreInfo *si;
	gboolean short_folder_names;
	gboolean success = TRUE;

	service = CAMEL_SERVICE (subscribable);

	settings = camel_service_ref_settings (service);

	short_folder_names = camel_nntp_settings_get_short_folder_names (
		CAMEL_NNTP_SETTINGS (settings));

	g_object_unref (settings);

	nntp_store = CAMEL_NNTP_STORE (subscribable);
	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);

	store_summary = CAMEL_STORE_SUMMARY (nntp_store_summary);
	si = camel_store_summary_path (store_summary, folder_name);

	if (si == NULL) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID,
			_("You cannot subscribe to this newsgroup:\n\n"
			"No such newsgroup. The selected item is a "
			"probably a parent folder."));
		success = FALSE;
	} else {
		if (!(si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED)) {
			CamelFolderInfo *fi;

			si->flags |= CAMEL_STORE_INFO_FOLDER_SUBSCRIBED;

			fi = nntp_folder_info_from_store_info (
				nntp_store, short_folder_names, si);
			fi->flags |=
				CAMEL_FOLDER_NOINFERIORS |
				CAMEL_FOLDER_NOCHILDREN;

			camel_store_summary_touch (store_summary);
			camel_store_summary_save (store_summary);

			camel_subscribable_folder_subscribed (
				subscribable, fi);

			camel_folder_info_free (fi);
		}

		camel_store_summary_info_unref (store_summary, si);
	}

	g_clear_object (&nntp_store_summary);

	return success;
}

static gboolean
nntp_store_unsubscribe_folder_sync (CamelSubscribable *subscribable,
                                    const gchar *folder_name,
                                    GCancellable *cancellable,
                                    GError **error)
{
	CamelNNTPStore *nntp_store;
	CamelNNTPStoreSummary *nntp_store_summary;
	CamelStoreSummary *store_summary;
	CamelService *service;
	CamelSettings *settings;
	CamelStoreInfo *si;
	gboolean short_folder_names;
	gboolean success = TRUE;

	service = CAMEL_SERVICE (subscribable);

	settings = camel_service_ref_settings (service);

	short_folder_names = camel_nntp_settings_get_short_folder_names (
		CAMEL_NNTP_SETTINGS (settings));

	g_object_unref (settings);

	nntp_store = CAMEL_NNTP_STORE (subscribable);
	nntp_store_summary = camel_nntp_store_ref_summary (nntp_store);

	store_summary = CAMEL_STORE_SUMMARY (nntp_store_summary);
	si = camel_store_summary_path (store_summary, folder_name);

	if (si == NULL) {
		g_set_error (
			error, CAMEL_FOLDER_ERROR,
			CAMEL_FOLDER_ERROR_INVALID,
			_("You cannot unsubscribe to this newsgroup:\n\n"
			"newsgroup does not exist!"));
		success = FALSE;
	} else {
		if (si->flags & CAMEL_STORE_INFO_FOLDER_SUBSCRIBED) {
			CamelFolderInfo *fi;

			si->flags &= ~CAMEL_STORE_INFO_FOLDER_SUBSCRIBED;

			fi = nntp_folder_info_from_store_info (
				nntp_store, short_folder_names, si);

			camel_store_summary_touch (store_summary);
			camel_store_summary_save (store_summary);

			camel_subscribable_folder_unsubscribed (
				subscribable, fi);

			camel_folder_info_free (fi);
		}

		camel_store_summary_info_unref (store_summary, si);
	}

	g_clear_object (&nntp_store_summary);

	return success;
}

static void
camel_nntp_store_class_init (CamelNNTPStoreClass *class)
{
	GObjectClass *object_class;
	CamelServiceClass *service_class;
	CamelStoreClass *store_class;

	g_type_class_add_private (class, sizeof (CamelNNTPStorePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->set_property = nntp_store_set_property;
	object_class->get_property = nntp_store_get_property;
	object_class->dispose = nntp_store_dispose;
	object_class->finalize = nntp_store_finalize;

	service_class = CAMEL_SERVICE_CLASS (class);
	service_class->settings_type = CAMEL_TYPE_NNTP_SETTINGS;
	service_class->get_name = nntp_store_get_name;
	service_class->connect_sync = nntp_store_connect_sync;
	service_class->disconnect_sync = nntp_store_disconnect_sync;
	service_class->authenticate_sync = nntp_store_authenticate_sync;
	service_class->query_auth_types_sync = nntp_store_query_auth_types_sync;

	store_class = CAMEL_STORE_CLASS (class);
	store_class->can_refresh_folder = nntp_store_can_refresh_folder;
	store_class->get_folder_sync = nntp_store_get_folder_sync;
	store_class->get_folder_info_sync = nntp_store_get_folder_info_sync;
	store_class->create_folder_sync = nntp_store_create_folder_sync;
	store_class->delete_folder_sync = nntp_store_delete_folder_sync;
	store_class->rename_folder_sync = nntp_store_rename_folder_sync;

	/* Inherited from CamelNetworkService. */
	g_object_class_override_property (
		object_class,
		PROP_CONNECTABLE,
		"connectable");

	/* Inherited from CamelNetworkService. */
	g_object_class_override_property (
		object_class,
		PROP_HOST_REACHABLE,
		"host-reachable");
}

static void
camel_nntp_store_initable_init (GInitableIface *iface)
{
	parent_initable_interface = g_type_interface_peek_parent (iface);

	iface->init = nntp_store_initable_init;
}

static void
camel_network_service_init (CamelNetworkServiceInterface *iface)
{
	iface->get_service_name = nntp_store_get_service_name;
	iface->get_default_port = nntp_store_get_default_port;
}

static void
camel_subscribable_init (CamelSubscribableInterface *iface)
{
	iface->folder_is_subscribed = nntp_store_folder_is_subscribed;
	iface->subscribe_folder_sync = nntp_store_subscribe_folder_sync;
	iface->unsubscribe_folder_sync = nntp_store_unsubscribe_folder_sync;
}

static void
camel_nntp_store_init (CamelNNTPStore *nntp_store)
{
	nntp_store->priv = CAMEL_NNTP_STORE_GET_PRIVATE (nntp_store);

	g_mutex_init (&nntp_store->priv->property_lock);

	/* Clear the default flags.  We don't want a virtual Junk or Trash
	 * folder and the user can't create/delete/rename newsgroup folders. */
	camel_store_set_flags (CAMEL_STORE (nntp_store), 0);
}

/**
 * camel_nntp_store_ref_cache:
 * @nntp_store: a #CamelNNTPStore
 *
 * Returns the #CamelDataCache for @nntp_store.
 *
 * The returned #CamelDataCache is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelDataCache
 **/
CamelDataCache *
camel_nntp_store_ref_cache (CamelNNTPStore *nntp_store)
{
	CamelDataCache *cache = NULL;

	g_return_val_if_fail (CAMEL_IS_NNTP_STORE (nntp_store), NULL);

	g_mutex_lock (&nntp_store->priv->property_lock);

	if (nntp_store->priv->cache != NULL)
		cache = g_object_ref (nntp_store->priv->cache);

	g_mutex_unlock (&nntp_store->priv->property_lock);

	return cache;
}

/**
 * camel_nntp_store_ref_stream:
 * @nntp_store: a #CamelNNTPStore
 *
 * Returns the #CamelNNTPStream for @nntp_store.
 *
 * The returned #CamelNNTPStream is referenced for thread-safety and must
 * be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelNNTPStream
 **/
CamelNNTPStream *
camel_nntp_store_ref_stream (CamelNNTPStore *nntp_store)
{
	CamelNNTPStream *stream = NULL;

	g_return_val_if_fail (CAMEL_IS_NNTP_STORE (nntp_store), NULL);

	g_mutex_lock (&nntp_store->priv->property_lock);

	if (nntp_store->priv->stream != NULL)
		stream = g_object_ref (nntp_store->priv->stream);

	g_mutex_unlock (&nntp_store->priv->property_lock);

	return stream;
}

/**
 * camel_nntp_store_ref_summary:
 * @nntp_store: a #CamelNNTPStore
 *
 * Returns the #CamelNNTPStoreSummary for @nntp_store.
 *
 * The returned #CamelNNTPStoreSummary is referenced for thread-safety and
 * must be unreferenced with g_object_unref() when finished with it.
 *
 * Returns: a #CamelNNTPStoreSummary
 **/
CamelNNTPStoreSummary *
camel_nntp_store_ref_summary (CamelNNTPStore *nntp_store)
{
	CamelNNTPStoreSummary *summary = NULL;

	g_return_val_if_fail (CAMEL_IS_NNTP_STORE (nntp_store), NULL);

	g_mutex_lock (&nntp_store->priv->property_lock);

	if (nntp_store->priv->summary != NULL)
		summary = g_object_ref (nntp_store->priv->summary);

	g_mutex_unlock (&nntp_store->priv->property_lock);

	return summary;
}

/**
 * camel_nntp_store_get_current_group:
 * @nntp_store: a #CamelNNTPStore
 *
 * Returns the currently selected newsgroup name, or %NULL if no newsgroup
 * is selected.
 *
 * Returns: the currently selected newsgroup name, or %NULL
 **/
const gchar *
camel_nntp_store_get_current_group (CamelNNTPStore *nntp_store)
{
	g_return_val_if_fail (CAMEL_IS_NNTP_STORE (nntp_store), NULL);

	return nntp_store->priv->current_group;
}

/**
 * camel_nntp_store_dup_current_group:
 * @nntp_store: a #CamelNNTPStore
 *
 * Thread-safe variation of camel_nntp_store_get_current_group().
 * Use this function when accessing @nntp_store from multiple threads.
 *
 * The returned string should be freed with g_free() when no longer needed.
 *
 * Returns: a newly-allocated string, or %NULL
 **/
gchar *
camel_nntp_store_dup_current_group (CamelNNTPStore *nntp_store)
{
	const gchar *protected;
	gchar *duplicate;

	g_return_val_if_fail (CAMEL_IS_NNTP_STORE (nntp_store), NULL);

	g_mutex_lock (&nntp_store->priv->property_lock);

	protected = camel_nntp_store_get_current_group (nntp_store);
	duplicate = g_strdup (protected);

	g_mutex_unlock (&nntp_store->priv->property_lock);

	return duplicate;
}

/**
 * camel_nntp_store_set_current_group:
 * @nntp_store: a #CamelNNTPStore
 * @current_group: a newsgroup name
 *
 * Sets the name of the currently selected newsgroup.
 **/
void
camel_nntp_store_set_current_group (CamelNNTPStore *nntp_store,
                                    const gchar *current_group)
{
	g_return_if_fail (CAMEL_IS_NNTP_STORE (nntp_store));

	g_mutex_lock (&nntp_store->priv->property_lock);

	if (g_strcmp0 (current_group, nntp_store->priv->current_group) == 0) {
		g_mutex_unlock (&nntp_store->priv->property_lock);
		return;
	}

	g_free (nntp_store->priv->current_group);
	nntp_store->priv->current_group = g_strdup (current_group);

	g_mutex_unlock (&nntp_store->priv->property_lock);
}

/**
 * camel_nntp_store_add_capabilities:
 * @nntp_store: a #CamelNNTPStore
 * @caps: #CamelNNTPCapabilities to add
 *
 * Adds @caps to the set of known capabilities for @nntp_store.
 **/
void
camel_nntp_store_add_capabilities (CamelNNTPStore *nntp_store,
                                   CamelNNTPCapabilities caps)
{
	g_return_if_fail (CAMEL_IS_NNTP_STORE (nntp_store));

	g_mutex_lock (&nntp_store->priv->property_lock);

	nntp_store->priv->capabilities |= caps;

	g_mutex_unlock (&nntp_store->priv->property_lock);
}

/**
 * camel_nntp_store_has_capabilities:
 * @nntp_store: a #CamelNNTPStore
 * @caps: #CamelNNTPCapabilities to check
 *
 * Returns whether the set of known capabilities for @nntp_store includes
 * ALL the capabilities specified by @caps.
 *
 * Returns: %TRUE if @nntp_store includes ALL capabilities in @caps
 **/
gboolean
camel_nntp_store_has_capabilities (CamelNNTPStore *nntp_store,
                                   CamelNNTPCapabilities caps)
{
	gboolean result;

	g_return_val_if_fail (CAMEL_IS_NNTP_STORE (nntp_store), FALSE);

	g_mutex_lock (&nntp_store->priv->property_lock);

	result = ((nntp_store->priv->capabilities & caps) == caps);

	g_mutex_unlock (&nntp_store->priv->property_lock);

	return result;
}

/**
 * camel_nntp_store_remove_capabilities:
 * @nntp_store: a #CamelNNTPStore
 * @caps: #CamelNNTPCapabilities to remove
 *
 * Removes @caps from the set of known capablities for @nntp_store.
 **/
void
camel_nntp_store_remove_capabilities (CamelNNTPStore *nntp_store,
                                      CamelNNTPCapabilities caps)
{
	g_return_if_fail (CAMEL_IS_NNTP_STORE (nntp_store));

	g_mutex_lock (&nntp_store->priv->property_lock);

	nntp_store->priv->capabilities &= ~caps;

	g_mutex_unlock (&nntp_store->priv->property_lock);
}

/* Enter owning lock */
gint
camel_nntp_raw_commandv (CamelNNTPStore *nntp_store,
                         GCancellable *cancellable,
                         GError **error,
                         gchar **line,
                         const gchar *fmt,
                         va_list ap)
{
	CamelNNTPStream *nntp_stream;
	GString *buffer;
	const guchar *p, *ps;
	guchar c;
	gchar *s;
	gint d;
	guint u, u2;

	nntp_stream = camel_nntp_store_ref_stream (nntp_store);
	g_return_val_if_fail (nntp_stream != NULL, -1);
	g_return_val_if_fail (nntp_stream->mode != CAMEL_NNTP_STREAM_DATA, -1);

	camel_nntp_stream_set_mode (nntp_stream, CAMEL_NNTP_STREAM_LINE);

	p = (const guchar *) fmt;
	ps = (const guchar *) p;

	buffer = g_string_sized_new (256);

	while ((c = *p++)) {
		gchar *strval = NULL;

		switch (c) {
		case '%':
			c = *p++;
			g_string_append_len (
				buffer, (const gchar *) ps,
				p - ps - (c == '%' ? 1 : 2));
			ps = p;
			switch (c) {
			case 's':
				s = va_arg (ap, gchar *);
				g_string_append (buffer, s);
				break;
			case 'd':
				d = va_arg (ap, gint);
				g_string_append_printf (buffer, "%d", d);
				break;
			case 'u':
				u = va_arg (ap, guint);
				g_string_append_printf (buffer, "%u", u);
				break;
			case 'm':
				s = va_arg (ap, gchar *);
				g_string_append_printf (buffer, "<%s>", s);
				break;
			case 'r':
				u = va_arg (ap, guint);
				u2 = va_arg (ap, guint);
				if (u == u2)
					g_string_append_printf (
						buffer, "%u", u);
				else
					g_string_append_printf (
						buffer, "%u-%u", u, u2);
				break;
			default:
				g_warning ("Passing unknown format to nntp_command: %c\n", c);
			}

			g_free (strval);
			strval = NULL;
		}
	}

	g_string_append_len (buffer, (const gchar *) ps, p - ps - 1);
	g_string_append_len (buffer, "\r\n", 2);

	if (camel_stream_write (
		CAMEL_STREAM (nntp_stream),
		buffer->str, buffer->len,
		cancellable, error) == -1)
		goto ioerror;

	if (camel_nntp_stream_line (nntp_stream, (guchar **) line, &u, cancellable, error) == -1)
		goto ioerror;

	u = strtoul (*line, NULL, 10);

	/* Handle all switching to data mode here, to make callers job easier */
	if (u == 215 || (u >= 220 && u <=224) || (u >= 230 && u <= 231))
		camel_nntp_stream_set_mode (nntp_stream, CAMEL_NNTP_STREAM_DATA);

	goto exit;

ioerror:
	g_prefix_error (error, _("NNTP Command failed: "));
	u = -1;

exit:
	g_clear_object (&nntp_stream);
	g_string_free (buffer, TRUE);

	return u;
}

gint
camel_nntp_raw_command (CamelNNTPStore *nntp_store,
                        GCancellable *cancellable,
                        GError **error,
                        gchar **line,
                        const gchar *fmt,
                        ...)
{
	gint ret;
	va_list ap;

	va_start (ap, fmt);
	ret = camel_nntp_raw_commandv (
		nntp_store, cancellable, error, line, fmt, ap);
	va_end (ap);

	return ret;
}

/* use this where you also need auth to be handled, i.e. most cases where you'd try raw command */
gint
camel_nntp_raw_command_auth (CamelNNTPStore *nntp_store,
                             GCancellable *cancellable,
                             GError **error,
                             gchar **line,
                             const gchar *fmt,
                             ...)
{
	CamelService *service;
	CamelSession *session;
	gint ret, retry, go;
	va_list ap;

	service = CAMEL_SERVICE (nntp_store);
	session = camel_service_ref_session (service);
	if (!session) {
		g_set_error_literal (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_UNAVAILABLE,
			_("You must be working online to complete this operation"));
		return -1;
	}

	retry = 0;

	do {
		go = FALSE;
		retry++;

		va_start (ap, fmt);
		ret = camel_nntp_raw_commandv (
			nntp_store, cancellable, error, line, fmt, ap);
		va_end (ap);

		if (ret == NNTP_AUTH_REQUIRED) {
			go = camel_session_authenticate_sync (
				session, service, NULL, cancellable, error);
			if (!go)
				ret = -1;
		}
	} while (retry < 3 && go);

	g_object_unref (session);

	return ret;
}

gint
camel_nntp_command (CamelNNTPStore *nntp_store,
                    GCancellable *cancellable,
                    GError **error,
                    CamelNNTPFolder *folder,
		    CamelNNTPStream **out_nntp_stream,
                    gchar **line,
                    const gchar *fmt,
                    ...)
{
	CamelNNTPStream *nntp_stream = NULL;
	CamelServiceConnectionStatus status;
	CamelService *service;
	CamelSession *session;
	gboolean success;
	const gchar *full_name = NULL;
	const guchar *p;
	va_list ap;
	gint ret, retry;
	guint u;
	GError *local_error = NULL;

	service = CAMEL_SERVICE (nntp_store);
	status = camel_service_get_connection_status (service);

	if (status != CAMEL_SERVICE_CONNECTED) {
		g_set_error (
			error, CAMEL_SERVICE_ERROR,
			CAMEL_SERVICE_ERROR_NOT_CONNECTED,
			_("Not connected."));
		ret = -1;
		goto exit;
	}

	if (folder != NULL)
		full_name = camel_folder_get_full_name (CAMEL_FOLDER (folder));

	retry = 0;
	do {
		gboolean need_group_command;
		gchar *current_group;

		retry++;

		nntp_stream = camel_nntp_store_ref_stream (nntp_store);

		if (nntp_stream == NULL) {
			gboolean success;

			success = camel_service_connect_sync (
				service, cancellable, error);

			if (!success) {
				ret = -1;
				goto exit;
			}

			/* If we successfully connected then
			 * we should obtain a CamelNNTPStream. */
			nntp_stream = camel_nntp_store_ref_stream (nntp_store);
			if (!nntp_stream) {
				g_set_error (
					error, CAMEL_SERVICE_ERROR,
					CAMEL_SERVICE_ERROR_NOT_CONNECTED,
					_("Not connected."));
				ret = -1;
				goto exit;
			}
		}

		camel_nntp_stream_lock (nntp_stream);

		/* Check for unprocessed data, !*/
		if (nntp_stream->mode == CAMEL_NNTP_STREAM_DATA) {
			g_warning ("Unprocessed data left in stream, flushing");
			while (camel_nntp_stream_getd (nntp_stream, (guchar **) &p, &u, cancellable, error) > 0)
				;
		}
		camel_nntp_stream_set_mode (nntp_stream, CAMEL_NNTP_STREAM_LINE);

		current_group =
			camel_nntp_store_dup_current_group (nntp_store);
		need_group_command =
			(full_name != NULL) &&
			(g_strcmp0 (current_group, full_name) != 0);
		g_free (current_group);

		if (need_group_command) {
			ret = camel_nntp_raw_command_auth (
				nntp_store, cancellable, &local_error,
				line, "group %s", full_name);
			if (ret == 211) {
				if (camel_nntp_folder_selected (folder, *line, cancellable, &local_error) < 0) {
					camel_nntp_store_set_current_group (nntp_store, NULL);
					ret = -1;
					goto error;
				}
				camel_nntp_store_set_current_group (nntp_store, full_name);
			} else {
				camel_nntp_store_set_current_group (nntp_store, NULL);
				goto error;
			}
		}

		/* dummy fmt, we just wanted to select the folder */
		if (fmt == NULL) {
			ret = 0;
			goto exit;
		}

		va_start (ap, fmt);
		ret = camel_nntp_raw_commandv (
			nntp_store, cancellable, &local_error, line, fmt, ap);
		va_end (ap);
	error:
		switch (ret) {
		case NNTP_AUTH_REQUIRED:
			session = camel_service_ref_session (service);
			if (session) {
				success = camel_session_authenticate_sync (
					session, service, NULL, cancellable, error);
				g_object_unref (session);
			} else {
				success = FALSE;
				g_set_error_literal (
					error, CAMEL_SERVICE_ERROR,
					CAMEL_SERVICE_ERROR_UNAVAILABLE,
					_("You must be working online to complete this operation"));
			}

			if (!success) {
				ret = -1;
				goto exit;
			}
			retry--;
			ret = -1;
			continue;
		case 411:	/* no such group */
			g_set_error (
				error, CAMEL_FOLDER_ERROR,
				CAMEL_FOLDER_ERROR_INVALID,
				_("No such folder: %s"), *line);
			ret = -1;
			goto exit;
		case 400:	/* service discontinued */
		case 401:	/* wrong client state - this should quit but this is what the old code did */
		case 503:	/* information not available - this should quit but this is what the old code did (?) */
			if (camel_service_get_connection_status (service) != CAMEL_SERVICE_CONNECTING) {
				/* Reset the cancellable, thus the disconnect attempt can succeed. */
				if (g_cancellable_is_cancelled (cancellable))
					g_cancellable_reset (cancellable);

				camel_service_disconnect_sync (
					service, FALSE, cancellable, NULL);
			}
			ret = -1;
			continue;
		case -1:	/* i/o error */
			if (camel_service_get_connection_status (service) != CAMEL_SERVICE_CONNECTING) {
				/* Reset the cancellable, thus the disconnect attempt can succeed. */
				if (g_cancellable_is_cancelled (cancellable))
					g_cancellable_reset (cancellable);

				camel_service_disconnect_sync (
					service, FALSE, cancellable, NULL);
			}
			if (g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED) || retry >= 3) {
				g_propagate_error (error, local_error);
				ret = -1;
				goto exit;
			}
			g_clear_error (&local_error);
			break;
		}

		if (ret == -1) {
			camel_nntp_stream_unlock (nntp_stream);
			g_clear_object (&nntp_stream);
		}

	} while (ret == -1 && retry < 3);

 exit:
	if (nntp_stream) {
		if (ret != -1 && out_nntp_stream)
			*out_nntp_stream = g_object_ref (nntp_stream);
		else
			camel_nntp_stream_unlock (nntp_stream);
	}

	g_clear_object (&nntp_stream);

	return ret;
}
