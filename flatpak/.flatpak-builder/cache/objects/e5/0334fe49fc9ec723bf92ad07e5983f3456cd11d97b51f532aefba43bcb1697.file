/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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

#include "camel/camel.h"
#include "libebook-contacts/libebook-contacts.h"

#include "e-book-client.h"

#include "e-book-utils.h"

typedef struct _RecipientCertificatesData {
	GMutex lock;
	GCond cond;
	guint32 flags;
	gboolean is_source; /* if FALSE, then it's EBookClient */
	GHashTable *recipients; /* gchar *email ~> gchar *base64_cert */
	guint has_pending;
	GCancellable *cancellable;
} RecipientCertificatesData;

static void
book_utils_get_recipient_certificates_thread (gpointer data,
					      gpointer user_data)
{
	RecipientCertificatesData *rcd = user_data;
	EContactField field_id;
	GHashTableIter iter;
	gpointer key, value;
	GString *sexp;
	const gchar *fieldname;

	g_return_if_fail (rcd != NULL);

	g_mutex_lock (&rcd->lock);

	if (g_cancellable_is_cancelled (rcd->cancellable)) {
		rcd->has_pending--;
		if (!rcd->has_pending)
			g_cond_signal (&rcd->cond);

		g_mutex_unlock (&rcd->lock);

		return;
	}

	fieldname = e_contact_field_name (E_CONTACT_EMAIL);
	sexp = g_string_new ("");

	g_hash_table_iter_init (&iter, rcd->recipients);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		if (key && !value) {
			if (sexp->len)
				g_string_append_c (sexp, ' ');
			g_string_append_printf (sexp, "(is \"%s\"", fieldname);
			e_sexp_encode_string (sexp, key);
			g_string_append_c (sexp, ')');
		}
	}

	g_mutex_unlock (&rcd->lock);

	field_id = (rcd->flags & CAMEL_RECIPIENT_CERTIFICATE_SMIME) ? E_CONTACT_X509_CERT : E_CONTACT_PGP_CERT;

	if (sexp->len) {
		gchar *prefix;

		prefix = g_strdup_printf ("(and (exists \"%s\") (or ", e_contact_field_name (field_id));
		g_string_prepend (sexp, prefix);
		g_free (prefix);
		g_string_append (sexp, "))");
	}

	if (sexp->len) {
		EBookClient *client;
		GSList *contacts = NULL;

		if (rcd->is_source) {
			client = (EBookClient *) e_book_client_connect_sync (data, 30, rcd->cancellable, NULL);
		} else {
			client = g_object_ref (data);
		}

		if (client && e_book_client_get_contacts_sync (client, sexp->str, &contacts, rcd->cancellable, NULL) && contacts) {
			GSList *link;
			GHashTableIter iter;
			gpointer value;
			gboolean all_done;

			g_mutex_lock (&rcd->lock);

			for (link = contacts; link; link = g_slist_next (link)) {
				EContact *contact = link->data;
				GList *emails, *elink;
				gchar *base64_data = NULL;

				/* Update only those which were not found yet. One could choose the best
				   certificate for S/MIME, but not for PGP easily, thus which is returned
				   depends on the order they had been received (the first recognized
				   is used). */

				emails = e_contact_get (contact, E_CONTACT_EMAIL);

				for (elink = emails; elink; elink = g_list_next (elink)) {
					const gchar *email_address = elink->data;
					gpointer orig_key = NULL, stored_value = NULL;

					if (email_address && g_hash_table_lookup_extended (rcd->recipients, email_address, &orig_key, &stored_value) && !stored_value) {
						if (!base64_data) {
							GList *cert_attrs, *clink;

							cert_attrs = e_contact_get_attributes (contact, field_id);
							for (clink = cert_attrs; clink; clink = g_list_next (clink)) {
								EVCardAttribute *cattr = clink->data;

								if ((field_id == E_CONTACT_X509_CERT && e_vcard_attribute_has_type (cattr, "X509")) ||
								    (field_id == E_CONTACT_PGP_CERT && e_vcard_attribute_has_type (cattr, "PGP"))) {
									GString *decoded;

									decoded = e_vcard_attribute_get_value_decoded (cattr);
									if (decoded && decoded->len) {
										base64_data = g_base64_encode ((const guchar *) decoded->str, decoded->len);
										g_string_free (decoded, TRUE);
										break;
									}

									if (decoded)
										g_string_free (decoded, TRUE);
								}
							}

							g_list_free_full (cert_attrs, (GDestroyNotify) e_vcard_attribute_free);

							/* First insert takes ownership of the base64_data */
							if (base64_data)
								g_hash_table_insert (rcd->recipients, orig_key, base64_data);
						} else {
							g_hash_table_insert (rcd->recipients, orig_key, g_strdup (base64_data));
						}
					}
				}

				g_list_free_full (emails, g_free);
			}

			all_done = TRUE;
			g_hash_table_iter_init (&iter, rcd->recipients);
			while (all_done && g_hash_table_iter_next (&iter, NULL, &value)) {
				all_done = value != NULL;
			}

			g_mutex_unlock (&rcd->lock);

			g_slist_free_full (contacts, g_object_unref);

			/* Do not wait for all books to finish when all recipients have their certificate */
			if (all_done)
				g_cancellable_cancel (rcd->cancellable);
		}

		g_clear_object (&client);
	}

	g_mutex_lock (&rcd->lock);
	rcd->has_pending--;
	if (!rcd->has_pending)
		g_cond_signal (&rcd->cond);
	g_mutex_unlock (&rcd->lock);
}

/**
 * e_book_utils_get_recipient_certificates_sync:
 * @registry: an #ESourceRegistry
 * @only_clients: (element-type EBookClient) (nullable): optional #GSList of
 *    the #EBookClient objects to search for the certificates in, or %NULL
 * @flags: bit-or of #CamelRecipientCertificateFlags
 * @recipients: (element-type utf8): a #GPtrArray of recipients' email addresses
 * @out_certificates: (element-type utf8) (out): a #GSList of gathered certificates
 *    encoded in base64
 * @cancellable: optional #GCancellable object, or %NULL
 * @error: return location for a #GError, or %NULL
 *
 * Synchronously searches for @recipients S/MIME or PGP certificates either
 * in provided @only_clients #EBookClient, or, when %NULL, in each found
 * address book configured for auto-completion.
 *
 * This function can be used within camel_session_get_recipient_certificates_sync()
 * implementation.
 *
 * Returns: %TRUE when no fatal error occurred, %FALSE otherwise.
 *
 * Since: 3.30
 **/
gboolean
e_book_utils_get_recipient_certificates_sync (ESourceRegistry *registry,
					      const GSList *only_clients,
					      guint32 flags,
					      const GPtrArray *recipients,
					      GSList **out_certificates,
					      GCancellable *cancellable,
					      GError **error)
{
	GSList *clients, *link; /* contains either EBookClient or ESource objects */
	RecipientCertificatesData rcd;
	GThreadPool *thread_pool;
	guint ii;

	g_return_val_if_fail (E_IS_SOURCE_REGISTRY (registry), FALSE);
	g_return_val_if_fail (recipients != NULL, FALSE);
	g_return_val_if_fail (out_certificates != NULL, FALSE);

	*out_certificates = NULL;

	clients = g_slist_copy_deep ((GSList *) only_clients, (GCopyFunc) g_object_ref, NULL);

	if (!clients) {
		GList *sources, *llink;

		sources = e_source_registry_list_enabled (registry, E_SOURCE_EXTENSION_ADDRESS_BOOK);

		for (llink = sources; llink; llink = g_list_next (llink)) {
			ESource *source = llink->data;

			/* Default is TRUE, thus when not there, then include it */
			if (!e_source_has_extension (source, E_SOURCE_EXTENSION_AUTOCOMPLETE) ||
			    e_source_autocomplete_get_include_me (e_source_get_extension (source, E_SOURCE_EXTENSION_AUTOCOMPLETE)))
				clients = g_slist_prepend (clients, g_object_ref (source));
		}

		g_list_free_full (sources, g_object_unref);
	}

	/* Not a fatal error, there's just no address book to search in */
	if (!clients)
		return TRUE;

	g_mutex_init (&rcd.lock);
	g_cond_init (&rcd.cond);
	rcd.flags = flags;
	rcd.is_source = !only_clients;
	rcd.has_pending = 0;
	rcd.recipients = g_hash_table_new_full (camel_strcase_hash, camel_strcase_equal, NULL, g_free);
	rcd.cancellable = camel_operation_new_proxy (cancellable);

	for (ii = 0; ii < recipients->len; ii++) {
		g_hash_table_insert (rcd.recipients, recipients->pdata[ii], NULL);
	}

	thread_pool = g_thread_pool_new (book_utils_get_recipient_certificates_thread, &rcd, 10, FALSE, NULL);

	g_mutex_lock (&rcd.lock);

	for (link = clients; link && !g_cancellable_is_cancelled (cancellable); link = g_slist_next (link)) {
		g_thread_pool_push (thread_pool, link->data, NULL);
		rcd.has_pending++;
	}

	while (rcd.has_pending) {
		g_cond_wait (&rcd.cond, &rcd.lock);
	}
	g_mutex_unlock (&rcd.lock);

	g_thread_pool_free (thread_pool, TRUE, TRUE);

	for (ii = 0; ii < recipients->len; ii++) {
		gchar *base64_data;

		base64_data = g_hash_table_lookup (rcd.recipients, recipients->pdata[ii]);
		if (base64_data && *base64_data) {
			*out_certificates = g_slist_prepend (*out_certificates, base64_data);
			/* Move ownership of the base64_data to out_certificates */
			g_warn_if_fail (g_hash_table_steal (rcd.recipients, recipients->pdata[ii]));
		} else {
			*out_certificates = g_slist_prepend (*out_certificates, NULL);
		}
	}

	*out_certificates = g_slist_reverse (*out_certificates);

	g_hash_table_destroy (rcd.recipients);
	g_clear_object (&rcd.cancellable);
	g_mutex_clear (&rcd.lock);
	g_cond_clear (&rcd.cond);
	g_slist_free_full (clients, g_object_unref);

	return TRUE;
}
