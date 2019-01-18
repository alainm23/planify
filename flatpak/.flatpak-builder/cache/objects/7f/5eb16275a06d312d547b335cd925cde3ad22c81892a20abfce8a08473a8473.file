/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2013 Intel Corporation
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#include <glib.h>
#include <libedataserver/e-source-enumtypes.h>
#include <libedataserver/e-data-server-util.h>

#ifndef E_COLLATOR_H
#define E_COLLATOR_H

/**
 * E_COLLATOR_ERROR:
 *
 * An error domain for collation errors
 *
 * Since: 3.12
 */
#define E_COLLATOR_ERROR (e_collator_error_quark ())

#define E_TYPE_COLLATOR (e_collator_get_type ())

G_BEGIN_DECLS

/**
 * ECollatorError:
 * @E_COLLATOR_ERROR_OPEN: An error occured trying to open a collator and access collation data.
 * @E_COLLATOR_ERROR_CONVERSION: An error occurred converting character encodings
 * @E_COLLATOR_ERROR_INVALID_LOCALE: A malformed locale name was given to e_collator_new()
 *
 * Errors from the #E_COLLATOR_ERROR domain.
 */
typedef enum {
	E_COLLATOR_ERROR_OPEN,
	E_COLLATOR_ERROR_CONVERSION,
	E_COLLATOR_ERROR_INVALID_LOCALE
} ECollatorError;

/**
 * ECollator:
 *
 * An opaque object used for locale specific string comparisons
 * and sort ordering.
 *
 * Since: 3.12
 */
typedef struct _ECollator ECollator;

GType                e_collator_get_type         (void);
GQuark               e_collator_error_quark      (void);
ECollator           *e_collator_new              (const gchar     *locale,
						  GError         **error);
ECollator           *e_collator_new_interpret_country
                                                 (const gchar     *locale,
						  gchar          **country_code,
						  GError         **error);
ECollator           *e_collator_ref              (ECollator       *collator);
void                 e_collator_unref            (ECollator       *collator);
gchar               *e_collator_generate_key     (ECollator       *collator,
						  const gchar     *str,
						  GError         **error);
gchar               *e_collator_generate_key_for_index
                                                 (ECollator       *collator,
						  gint             index);
gboolean             e_collator_collate          (ECollator       *collator,
						  const gchar     *str_a,
						  const gchar     *str_b,
						  gint            *result,
						  GError         **error);
const gchar *const  *e_collator_get_index_labels (ECollator       *collator,
						  gint            *n_labels,
						  gint            *underflow,
						  gint            *inflow,
						  gint            *overflow);
gint                 e_collator_get_index        (ECollator       *collator,
						  const gchar     *str);

G_END_DECLS

#endif /* E_COLLATOR_H */
