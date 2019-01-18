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

#include "evolution-data-server-config.h"

#include "e-alphabet-index-private.h"

/* C++ standard library */
#include <string>
#include <memory>

/* system headers */
#ifdef HAVE_CODESET
#include <langinfo.h>
#endif
#include <locale.h>

/* ICU headers */
#include <unicode/alphaindex.h>

using icu::AlphabeticIndex;
using icu::Locale;
using icu::UnicodeString;

struct _EAlphabetIndex {
	AlphabeticIndex *priv;
};

/* Create an AlphabetIndex for a given language code (normally
 * language codes are 2 letter codes, eg. 'en' = English 'es' = Spanish.
 */
EAlphabetIndex *
_e_alphabet_index_cxx_new_for_language (const gchar *language)
{
	UErrorCode status = U_ZERO_ERROR;
	EAlphabetIndex *alphabet_index;

	g_return_val_if_fail (language != NULL, NULL);

	alphabet_index = g_slice_new (EAlphabetIndex);
	alphabet_index->priv = new AlphabeticIndex (Locale (language), status);

	return alphabet_index;
}

/* Frees an EAlphabetIndex and it's associated resources
 */
void
_e_alphabet_index_cxx_free (EAlphabetIndex *alphabet_index)
{
	if (alphabet_index) {
		delete alphabet_index->priv;
		g_slice_free (EAlphabetIndex, alphabet_index);
	}
}

/* Fetch the given index where 'word' should sort
 */
gint
_e_alphabet_index_cxx_get_index (EAlphabetIndex  *alphabet_index,
				 const gchar     *word)
{
	UErrorCode status = U_ZERO_ERROR;
	UnicodeString string;
	gint index;

	g_return_val_if_fail (alphabet_index != NULL, -1);
	g_return_val_if_fail (word != NULL, -1);

	string = icu::UnicodeString::fromUTF8 (word);
	index = alphabet_index->priv->getBucketIndex (string, status);

	return index;
}

/* Fetch the list of labels in the alphabetic index.
 *
 * Returns an array of UTF-8 labels for each alphabetic
 * index position 'n_labels' long, the returned array
 * of strings can be freed with g_strfreev()
 *
 * The underflow, overflow and inflow parameters will be
 * set to the appropriate indexes (reffers to indexes in the
 * returned labels).
 */
gchar **
_e_alphabet_index_cxx_get_labels (EAlphabetIndex  *alphabet_index,
				  gint            *n_labels,
				  gint            *underflow,
				  gint            *inflow,
				  gint            *overflow)
{
	UErrorCode status = U_ZERO_ERROR;
	gchar **labels = NULL;
	gint count, i;

	g_return_val_if_fail (alphabet_index != NULL, NULL);
	g_return_val_if_fail (n_labels != NULL, NULL);
	g_return_val_if_fail (underflow != NULL, NULL);
	g_return_val_if_fail (inflow != NULL, NULL);
	g_return_val_if_fail (overflow != NULL, NULL);

	count = alphabet_index->priv->getBucketCount (status);

	labels = g_new0 (gchar *, count + 1);

	/* In case they are missing, they should be set to -1 */
	*underflow = *inflow = *overflow = -1;

	/* Iterate over the AlphabeticIndex and collect UTF-8 versions
	 * of the bucket labels
	 */
	alphabet_index->priv->resetBucketIterator (status);

	for (i = 0; alphabet_index->priv->nextBucket (status); i++) {
		UAlphabeticIndexLabelType label_type;
		UnicodeString ustring;
		std::string string;

		label_type = alphabet_index->priv->getBucketLabelType ();

		switch (label_type) {
		case U_ALPHAINDEX_UNDERFLOW: *underflow = i; break;
		case U_ALPHAINDEX_INFLOW:    *inflow    = i; break;
		case U_ALPHAINDEX_OVERFLOW:  *overflow  = i; break;
		case U_ALPHAINDEX_NORMAL:  /* do nothing */  break;
		}

		/* This is annoyingly heavy but not a function called
		 * very often, this could be improved by calling icu::UnicodeString::toUTF8()
		 * and implementing ICU's ByteSync class using glib's memory allocator.
		 */
		ustring   = alphabet_index->priv->getBucketLabel ();
		string    = ustring.toUTF8String (string);
		labels[i] = g_strdup (string.c_str());
	}

	*n_labels = count;

	return labels;
}
