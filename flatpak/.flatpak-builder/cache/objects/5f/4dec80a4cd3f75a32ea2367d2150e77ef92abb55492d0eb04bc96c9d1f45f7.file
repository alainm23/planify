/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */

/* e-source-backend-summary-setup.h - Backend Summary Data Configuration.
 *
 * Copyright (C) 2012 Intel Corporation
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
 * Authors: Tristan Van Berkom <tristanvb@openismus.com>
 */

#if !defined (__LIBEBOOK_CONTACTS_H_INSIDE__) && !defined (LIBEBOOK_CONTACTS_COMPILATION)
#error "Only <libebook-contacts/libebook-contacts.h> should be included directly."
#endif

#ifndef E_SOURCE_BACKEND_SUMMARY_SETUP_H
#define E_SOURCE_BACKEND_SUMMARY_SETUP_H

#include <libedataserver/libedataserver.h>
#include <libebook-contacts/e-contact.h>
#include <libebook-contacts/e-book-contacts-types.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_BACKEND_SUMMARY_SETUP \
	(e_source_backend_summary_setup_get_type ())
#define E_SOURCE_BACKEND_SUMMARY_SETUP(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_BACKEND_SUMMARY_SETUP, ESourceBackendSummarySetup))
#define E_SOURCE_BACKEND_SUMMARY_SETUP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_BACKEND_SUMMARY_SETUP, ESourceBackendSummarySetupClass))
#define E_IS_SOURCE_BACKEND_SUMMARY_SETUP(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_BACKEND_SUMMARY_SETUP))
#define E_IS_SOURCE_BACKEND_SUMMARY_SETUP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_BACKEND_SUMMARY_SETUP))
#define E_SOURCE_BACKEND_SUMMARY_SETUP_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_BACKEND_SUMMARY_SETUP, ESourceBackendSummarySetupClass))

/**
 * E_SOURCE_EXTENSION_BACKEND_SUMMARY_SETUP:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceBackendSummarySetup.  This is also used as a group name in key files.
 *
 * Since: 3.8
 **/
#define E_SOURCE_EXTENSION_BACKEND_SUMMARY_SETUP "Backend Summary Setup"

G_BEGIN_DECLS

typedef struct _ESourceBackendSummarySetup ESourceBackendSummarySetup;
typedef struct _ESourceBackendSummarySetupClass ESourceBackendSummarySetupClass;
typedef struct _ESourceBackendSummarySetupPrivate ESourceBackendSummarySetupPrivate;

/**
 * ESourceBackendSummarySetup:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.8
 **/
struct _ESourceBackendSummarySetup {
	/*< private >*/
	ESourceBackend parent;
	ESourceBackendSummarySetupPrivate *priv;
};

struct _ESourceBackendSummarySetupClass {
	ESourceBackendClass parent_class;
};

GType           e_source_backend_summary_setup_get_type            (void) G_GNUC_CONST;

EContactField  *e_source_backend_summary_setup_get_summary_fields  (ESourceBackendSummarySetup *extension,
								    gint                       *n_fields);
void            e_source_backend_summary_setup_set_summary_fieldsv (ESourceBackendSummarySetup *extension,
								    EContactField              *fields,
								    gint                        n_fields);
void            e_source_backend_summary_setup_set_summary_fields  (ESourceBackendSummarySetup *extension,
								    ...);

EContactField  *e_source_backend_summary_setup_get_indexed_fields  (ESourceBackendSummarySetup *extension,
								    EBookIndexType            **types,
								    gint                       *n_fields);
void            e_source_backend_summary_setup_set_indexed_fieldsv (ESourceBackendSummarySetup *extension,
								    EContactField              *fields,
								    EBookIndexType             *types,
								    gint                        n_fields);
void            e_source_backend_summary_setup_set_indexed_fields  (ESourceBackendSummarySetup *extension,
								    ...);

G_END_DECLS

#endif /* E_SOURCE_BACKEND_SUMMARY_SETUP_H */
