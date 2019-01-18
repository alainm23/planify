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

#if !defined (__LIBEBOOK_H_INSIDE__) && !defined (LIBEBOOK_COMPILATION)
#error "Only <libebook/libebook.h> should be included directly."
#endif

#ifndef E_BOOK_UTILS_H
#define E_BOOK_UTILS_H

#include <libedataserver/libedataserver.h>

G_BEGIN_DECLS

gboolean	e_book_utils_get_recipient_certificates_sync
							(ESourceRegistry *registry,
							 const GSList *only_clients, /* EBookClient * */
							 guint32 flags, /* bit-or of CamelRecipientCertificateFlags */
							 const GPtrArray *recipients, /* gchar * */
							 GSList **out_certificates, /* gchar * */
							 GCancellable *cancellable,
							 GError **error);

G_END_DECLS

#endif /* E_BOOK_UTILS_H */
