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

#ifndef E_ALPHABET_INDEX_PRIVATE_H
#define E_ALPHABET_INDEX_PRIVATE_H

#include <glib-object.h>

G_BEGIN_DECLS

#if __GNUC__ >= 4
#  define E_ALPHABET_INDEX_LOCAL __attribute__ ((visibility ("hidden")))
#else
#  define E_ALPHABET_INDEX_LOCAL
#endif

/**
 * EAlphabetIndex:
 *
 * A private opaque type describing an alphabetic index
 *
 * Since: 3.10
 **/
typedef struct _EAlphabetIndex EAlphabetIndex;

/* defined in e-alphabet-index-private.cpp, and used by by e-collator.c */

E_ALPHABET_INDEX_LOCAL EAlphabetIndex *_e_alphabet_index_cxx_new_for_language (const gchar     *language);
E_ALPHABET_INDEX_LOCAL void            _e_alphabet_index_cxx_free             (EAlphabetIndex  *alphabet_index);
E_ALPHABET_INDEX_LOCAL gint            _e_alphabet_index_cxx_get_index        (EAlphabetIndex  *alphabet_index,
									       const gchar     *word);
E_ALPHABET_INDEX_LOCAL gchar         **_e_alphabet_index_cxx_get_labels       (EAlphabetIndex  *alphabet_index,
									       gint            *n_labels,
									       gint            *underflow,
									       gint            *inflow,
									       gint            *overflow);

G_END_DECLS

#endif /* E_ALPHABET_INDEX_PRIVATE_H */
