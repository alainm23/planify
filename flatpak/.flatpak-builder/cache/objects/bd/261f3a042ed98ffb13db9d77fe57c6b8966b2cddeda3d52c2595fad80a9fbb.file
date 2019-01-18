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
 * Authors: Bertrand Guiheneuf <bertrand@helixcode.com>
 */

#ifndef CAMEL_H
#define CAMEL_H

#define __CAMEL_H_INSIDE__

#include <camel/camel-address.h>
#include <camel/camel-async-closure.h>
#include <camel/camel-block-file.h>
#include <camel/camel-certdb.h>
#include <camel/camel-charset-map.h>
#include <camel/camel-cipher-context.h>
#include <camel/camel-data-cache.h>
#include <camel/camel-data-wrapper.h>
#include <camel/camel-db.h>
#include <camel/camel-debug.h>
#include <camel/camel-enums.h>
#include <camel/camel-enumtypes.h>
#include <camel/camel-file-utils.h>
#include <camel/camel-filter-driver.h>
#include <camel/camel-filter-input-stream.h>
#include <camel/camel-filter-output-stream.h>
#include <camel/camel-filter-search.h>
#include <camel/camel-folder.h>
#include <camel/camel-folder-search.h>
#include <camel/camel-folder-summary.h>
#include <camel/camel-folder-thread.h>
#include <camel/camel-gpg-context.h>
#include <camel/camel-html-parser.h>
#include <camel/camel-iconv.h>
#include <camel/camel-index.h>
#include <camel/camel-internet-address.h>
#include <camel/camel-junk-filter.h>
#include <camel/camel-local-settings.h>
#include <camel/camel-lock.h>
#include <camel/camel-lock-client.h>
#include <camel/camel-lock-helper.h>
#include <camel/camel-medium.h>
#include <camel/camel-memchunk.h>
#include <camel/camel-mempool.h>
#include <camel/camel-message-info.h>
#include <camel/camel-message-info-base.h>
#include <camel/camel-mime-filter.h>
#include <camel/camel-mime-filter-basic.h>
#include <camel/camel-mime-filter-bestenc.h>
#include <camel/camel-mime-filter-canon.h>
#include <camel/camel-mime-filter-charset.h>
#include <camel/camel-mime-filter-crlf.h>
#include <camel/camel-mime-filter-enriched.h>
#include <camel/camel-mime-filter-from.h>
#include <camel/camel-mime-filter-gzip.h>
#include <camel/camel-mime-filter-html.h>
#include <camel/camel-mime-filter-index.h>
#include <camel/camel-mime-filter-linewrap.h>
#include <camel/camel-mime-filter-pgp.h>
#include <camel/camel-mime-filter-progress.h>
#include <camel/camel-mime-filter-tohtml.h>
#include <camel/camel-mime-filter-windows.h>
#include <camel/camel-mime-filter-yenc.h>
#include <camel/camel-mime-message.h>
#include <camel/camel-mime-parser.h>
#include <camel/camel-mime-part.h>
#include <camel/camel-mime-part-utils.h>
#include <camel/camel-mime-utils.h>
#include <camel/camel-movemail.h>
#include <camel/camel-msgport.h>
#include <camel/camel-multipart.h>
#include <camel/camel-multipart-encrypted.h>
#include <camel/camel-multipart-signed.h>
#include <camel/camel-named-flags.h>
#include <camel/camel-name-value-array.h>
#include <camel/camel-net-utils.h>
#include <camel/camel-network-service.h>
#include <camel/camel-nntp-address.h>
#include <camel/camel-null-output-stream.h>
#include <camel/camel-object.h>
#include <camel/camel-object-bag.h>
#include <camel/camel-offline-folder.h>
#include <camel/camel-offline-settings.h>
#include <camel/camel-offline-store.h>
#include <camel/camel-operation.h>
#include <camel/camel-partition-table.h>
#include <camel/camel-provider.h>
#include <camel/camel-sasl.h>
#include <camel/camel-sasl-anonymous.h>
#include <camel/camel-sasl-cram-md5.h>
#include <camel/camel-sasl-digest-md5.h>
#include <camel/camel-sasl-gssapi.h>
#include <camel/camel-sasl-login.h>
#include <camel/camel-sasl-ntlm.h>
#include <camel/camel-sasl-plain.h>
#include <camel/camel-sasl-popb4smtp.h>
#include <camel/camel-sasl-xoauth2.h>
#include <camel/camel-sasl-xoauth2-google.h>
#include <camel/camel-sasl-xoauth2-outlook.h>
#include <camel/camel-service.h>
#include <camel/camel-session.h>
#include <camel/camel-settings.h>
#include <camel/camel-sexp.h>
#include <camel/camel-smime-context.h>
#include <camel/camel-store.h>
#include <camel/camel-store-settings.h>
#include <camel/camel-store-summary.h>
#include <camel/camel-stream.h>
#include <camel/camel-stream-buffer.h>
#include <camel/camel-stream-filter.h>
#include <camel/camel-stream-fs.h>
#include <camel/camel-stream-mem.h>
#include <camel/camel-stream-null.h>
#include <camel/camel-stream-process.h>
#include <camel/camel-string-utils.h>
#include <camel/camel-subscribable.h>
#include <camel/camel-text-index.h>
#include <camel/camel-transport.h>
#include <camel/camel-trie.h>
#include <camel/camel-uid-cache.h>
#include <camel/camel-url.h>
#include <camel/camel-url-scanner.h>
#include <camel/camel-utf8.h>
#include <camel/camel-utils.h>
#include <camel/camel-vee-data-cache.h>
#include <camel/camel-vee-folder.h>
#include <camel/camel-vee-message-info.h>
#include <camel/camel-vee-store.h>
#include <camel/camel-vee-summary.h>
#include <camel/camel-vtrash-folder.h>
#include <camel/camel-weak-ref-group.h>

#undef __CAMEL_H_INSIDE__

G_BEGIN_DECLS

extern gint camel_application_is_exiting;

gint camel_init (const gchar *certdb_dir, gboolean nss_init);
void camel_shutdown (void);

GBinding *	camel_binding_bind_property	(gpointer source,
						 const gchar *source_property,
						 gpointer target,
						 const gchar *target_property,
						 GBindingFlags flags);
GBinding *	camel_binding_bind_property_full(gpointer source,
						 const gchar *source_property,
						 gpointer target,
						 const gchar *target_property,
						 GBindingFlags flags,
						 GBindingTransformFunc transform_to,
						 GBindingTransformFunc transform_from,
						 gpointer user_data,
						 GDestroyNotify notify);
GBinding *	camel_binding_bind_property_with_closures
						(gpointer source,
						 const gchar *source_property,
						 gpointer target,
						 const gchar *target_property,
						 GBindingFlags flags,
						 GClosure *transform_to,
						 GClosure *transform_from);

G_END_DECLS

#endif /* CAMEL_H */
