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

/**
 * SECTION: e-collator
 * @include: libedataserver/libedataserver.h
 * @short_description: Collation services for locale sensitive sorting
 *
 * The #ECollator is a wrapper object around ICU collation services and
 * provides features to sort words in locale specific ways. The collator
 * also provides some API for determining features of the active alphabet
 * in the user's locale, and which words should be sorted under which
 * letter in the user's alphabet.
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <string.h>

/* ICU includes */
#include <unicode/uclean.h>
#include <unicode/ucol.h>
#include <unicode/ustring.h>

#include "e-collator.h"
#include "e-alphabet-index-private.h"
#include "e-transliterator-private.h"

#define CONVERT_BUFFER_LEN        512
#define COLLATION_KEY_BUFFER_LEN  1024
#define LOCALE_BUFFER_LEN         256

#define ENABLE_DEBUGGING 0

G_DEFINE_QUARK (e-collator-error-quark, e_collator_error)

G_DEFINE_BOXED_TYPE (ECollator,
		     e_collator,
		     e_collator_ref,
		     e_collator_unref)

struct _ECollator
{
	UCollator       *coll;
	volatile gint    ref_count;

	EAlphabetIndex  *alpha_index;
	gchar          **labels;
	gint             n_labels;
	gint             underflow;
	gint             inflow;
	gint             overflow;

	ETransliterator *transliterator;
};

/*****************************************************
 *                ICU Helper Functions               *
 *****************************************************/
#if ENABLE_DEBUGGING
static void
print_available_locales (void)
{
	UErrorCode status = U_ZERO_ERROR;
	UChar result[100];
	gchar printable[100 * 4];
	gint count, i;

	u_init (&status);

	g_printerr ("List of available locales (default locale is: %s)\n", uloc_getDefault ());

	count = uloc_countAvailable ();
	for (i = 0; i < count; i++) {
		UEnumeration *keywords;
		const gchar *keyword;

		uloc_getDisplayName (uloc_getAvailable (i), NULL, result, 100, &status);

		u_austrncpy (printable, result, sizeof (printable));

		/* print result */
		g_printerr ("\t%s - %s", uloc_getAvailable (i), printable);

		keywords = uloc_openKeywords (uloc_getAvailable (i), &status);
		if (keywords) {
			UErrorCode kstatus = U_ZERO_ERROR;

			g_printerr ("[");

			while ((keyword = uenum_next (keywords, NULL, &kstatus)) != NULL)
				g_printerr (" %s ", keyword);

			g_printerr ("]");

			uenum_close (keywords);
		}
		g_printerr ("\n");
	}
}
#endif

static gchar *
canonicalize_locale (const gchar *posix_locale,
                     gchar **language_code,
                     gchar **country_code,
                     GError **error)
{
	UErrorCode status = U_ZERO_ERROR;
	gchar  locale_buffer[LOCALE_BUFFER_LEN];
	gchar  language_buffer[8];
	gchar  country_buffer[8];
	gchar *icu_locale;
	gchar *final_locale;
	gint   len;
	const gchar *collation_type = NULL;

	len = uloc_canonicalize (posix_locale, locale_buffer, LOCALE_BUFFER_LEN, &status);

	if (U_FAILURE (status)) {
		g_set_error (
			error, E_COLLATOR_ERROR,
			E_COLLATOR_ERROR_INVALID_LOCALE,
			"Failed to interpret locale '%s' (%s)",
			posix_locale,
			u_errorName (status));
		return NULL;
	}

	if (len > LOCALE_BUFFER_LEN) {
		icu_locale = g_malloc (len);

		uloc_canonicalize (posix_locale, icu_locale, len, &status);
	} else {
		icu_locale = g_strndup (locale_buffer, len);
	}

	status = U_ZERO_ERROR;
	len = uloc_getLanguage (icu_locale, language_buffer, 8, &status);
	if (U_FAILURE (status)) {
		g_set_error (
			error, E_COLLATOR_ERROR,
			E_COLLATOR_ERROR_INVALID_LOCALE,
			"Failed to interpret language for locale '%s': %s",
			icu_locale,
			u_errorName (status));
		g_free (icu_locale);
		return NULL;
	}

	status = U_ZERO_ERROR;
	len = uloc_getCountry (icu_locale, country_buffer, 8, &status);
	if (U_FAILURE (status)) {
		g_set_error (
			error, E_COLLATOR_ERROR,
			E_COLLATOR_ERROR_INVALID_LOCALE,
			"Failed to interpret country for locale '%s': %s",
			icu_locale,
			u_errorName (status));
		g_free (icu_locale);
		return NULL;
	}

	/* Add 'phonebook' tailoring to certain locales */
	if (len < 8 &&
	    (strcmp (language_buffer, "de") == 0 ||
	     strcmp (language_buffer, "fi") == 0)) {

		collation_type = "phonebook";
	}

	if (collation_type != NULL)
		final_locale = g_strconcat (icu_locale, "@collation=", collation_type, NULL);
	else {
		final_locale = icu_locale;
		icu_locale = NULL;
	}

	g_free (icu_locale);

	if (language_code)
		*language_code = g_strdup (language_buffer);

	if (country_code)
		*country_code = g_strdup (country_buffer);

	return final_locale;
}

/* All purpose character encoding function, encodes text
 * to a UChar from UTF-8 and first ensures that the string
 * is valid UTF-8
 */
static const UChar *
convert_to_ustring (const gchar *string,
                    UChar *buffer,
                    gint buffer_len,
                    gint *result_len,
                    UChar **free_me,
                    GError **error)
{
	UErrorCode status = U_ZERO_ERROR;
	const gchar *source_utf8;
	gchar *alloc_utf8 = NULL;
	gint   converted_len = 0;
	UChar *converted_buffer;

	/* First make sure we're dealing with utf8 */
	if (g_utf8_validate (string, -1, NULL))
		source_utf8 = string;
	else {
		alloc_utf8 = e_util_utf8_make_valid (string);
		source_utf8 = alloc_utf8;
	}

	/* First pass, try converting to UChar in the given buffer */
	converted_buffer = u_strFromUTF8Lenient (
		buffer,
		buffer_len,
		&converted_len,
		source_utf8,
		-1,
		&status);

	/* Set the result length right away... */
	*result_len = converted_len;

	if (U_FAILURE (status)) {
		converted_buffer = NULL;
		goto out;
	}

	/* Second pass, allocate a buffer big enough and then convert */
	if (converted_len > buffer_len) {
		*free_me = g_new (UChar, converted_len);

		converted_buffer = u_strFromUTF8Lenient (
			*free_me,
			converted_len,
			NULL,
			source_utf8,
			-1,
			&status);

		if (U_FAILURE (status)) {
			g_free (*free_me);
			*free_me = NULL;
			converted_buffer = NULL;
			goto out;
		}
	}

 out:
	g_free (alloc_utf8);

	if (U_FAILURE (status))
		g_set_error (
			error, E_COLLATOR_ERROR,
			E_COLLATOR_ERROR_CONVERSION,
			"Error occured while converting character encoding (%s)",
			u_errorName (status));

	return converted_buffer;
}

/*****************************************************
 *                        API                        *
 *****************************************************/

/**
 * e_collator_new:
 * @locale: The locale under which to sort
 * @error: (allow-none): A location to store a #GError from the #E_COLLATOR_ERROR domain
 *
 * Creates a new #ECollator for the given @locale,
 * the returned collator should be freed with e_collator_unref().
 *
 * Returns: (transfer full): A newly created #ECollator.
 *
 * Since: 3.12
 */
ECollator *
e_collator_new (const gchar *locale,
                GError **error)
{
	return e_collator_new_interpret_country (locale, NULL, error);
}

/**
 * e_collator_new_interpret_country:
 * @locale: The locale under which to sort
 * @country_code: (allow-none) (out) (transfer full): A location to store the interpreted country code from @locale 
 * @error: (allow-none): A location to store a #GError from the #E_COLLATOR_ERROR domain
 *
 * Creates a new #ECollator for the given @locale,
 * the returned collator should be freed with e_collator_unref().
 *
 * In addition, this also reliably interprets the country
 * code from the @locale string and stores it to @country_code.
 *
 * Returns: (transfer full): A newly created #ECollator.
 *
 * Since: 3.12
 */
ECollator *
e_collator_new_interpret_country (const gchar *locale,
                                  gchar **country_code,
                                  GError **error)
{
	ECollator *collator;
	UCollator *coll;
	UErrorCode status = U_ZERO_ERROR;
	gchar     *icu_locale;
	gchar     *language_code = NULL;
	gchar     *local_country_code = NULL;

	g_return_val_if_fail (locale && locale[0], NULL);

#if ENABLE_DEBUGGING
	print_available_locales ();
#endif

	icu_locale = canonicalize_locale (
		locale,
		&language_code,
		&local_country_code,
		error);
	if (!icu_locale)
		return NULL;

	coll = ucol_open (icu_locale, &status);

	if (U_FAILURE (status)) {
		g_set_error (
			error, E_COLLATOR_ERROR,
			E_COLLATOR_ERROR_OPEN,
			"Unable to open collator for locale '%s' (%s)",
			icu_locale,
			u_errorName (status));

		g_free (language_code);
		g_free (local_country_code);
		g_free (icu_locale);
		ucol_close (coll);
		return NULL;
	}

	g_free (icu_locale);

	ucol_setStrength (coll, UCOL_DEFAULT_STRENGTH);

	collator = g_slice_new0 (ECollator);
	collator->coll = coll;
	collator->ref_count = 1;

	/* In Chinese we use transliteration services to sort latin 
	 * names interleaved with Chinese names in a latin AlphabeticIndex
	 */
	if (g_strcmp0 (language_code, "zh") == 0)
		collator->transliterator = _e_transliterator_cxx_new ("Han-Latin");

	collator->alpha_index = _e_alphabet_index_cxx_new_for_language (language_code);
	collator->labels = _e_alphabet_index_cxx_get_labels (
		collator->alpha_index,
		&collator->n_labels,
		&collator->underflow,
		&collator->inflow,
		&collator->overflow);

	g_free (language_code);

	if (country_code)
		*country_code = local_country_code;
	else
		g_free (local_country_code);

	return collator;
}

/**
 * e_collator_ref:
 * @collator: An #ECollator
 *
 * Increases the reference count of @collator.
 *
 * Returns: (transfer full): @collator
 *
 * Since: 3.12
 */
ECollator *
e_collator_ref (ECollator *collator)
{
	g_return_val_if_fail (collator != NULL, NULL);

	g_atomic_int_inc (&collator->ref_count);

	return collator;
}

/**
 * e_collator_unref:
 * @collator: An #ECollator
 *
 * Decreases the reference count of @collator.
 * If the reference count reaches 0 then the collator is freed
 *
 * Since: 3.12
 */
void
e_collator_unref (ECollator *collator)
{
	g_return_if_fail (collator != NULL);

	if (g_atomic_int_dec_and_test (&collator->ref_count)) {

		if (collator->coll)
			ucol_close (collator->coll);

		_e_alphabet_index_cxx_free (collator->alpha_index);
		g_strfreev (collator->labels);

		/* The transliterator is only used for specialized sorting in some locales,
		 * notably Chinese locales
		 */
		if (collator->transliterator)
			_e_transliterator_cxx_free (collator->transliterator);

		g_slice_free (ECollator, collator);
	}
}

/**
 * e_collator_generate_key:
 * @collator: An #ECollator
 * @str: The string to generate a collation key for
 * @error: (allow-none): A location to store a #GError from the #E_COLLATOR_ERROR domain
 *
 * Generates a collation key for @str, the result of comparing
 * two collation keys with strcmp() will be the same result
 * of calling e_collator_collate() on the same original strings.
 *
 * This function will first ensure that @str is valid UTF-8 encoded.
 *
 * Returns: (transfer full): A collation key for @str, or %NULL on failure with @error set.
 *
 * Since: 3.12
 */
gchar *
e_collator_generate_key (ECollator *collator,
                         const gchar *str,
                         GError **error)
{
	UChar  source_buffer[CONVERT_BUFFER_LEN];
	UChar *free_me = NULL;
	const UChar *source;
	gchar stack_buffer[COLLATION_KEY_BUFFER_LEN];
	gchar *collation_key;
	gint key_len, source_len = 0;
	gint alphabet_index;
	gchar *translit_str = NULL;
	const gchar *input_str;

	g_return_val_if_fail (collator != NULL, NULL);
	g_return_val_if_fail (str != NULL, NULL);

	/* We may need to perform a conversion before generating the sort key */
	if (collator->transliterator) {
		translit_str = _e_transliterator_cxx_transliterate (collator->transliterator, str);
		input_str = translit_str;
	} else {
		input_str = str;
	}

	source = convert_to_ustring (
		input_str,
		source_buffer,
		CONVERT_BUFFER_LEN,
		&source_len,
		&free_me,
		error);

	if (!source) {
		g_free (translit_str);
		g_free (free_me);
		return NULL;
	}

	/* Get the numerical index for this string */
	alphabet_index = _e_alphabet_index_cxx_get_index (collator->alpha_index, input_str);

	/* First try to generate a key in a predefined buffer size */
	key_len = ucol_getSortKey (
		collator->coll, source, source_len,
		(guchar *) stack_buffer, COLLATION_KEY_BUFFER_LEN);

	if (key_len > COLLATION_KEY_BUFFER_LEN) {

		/* Stack buffer wasn't large enough, regenerate into a new buffer
		 * (add a byte for a trailing NULL char)
		 *
		 * Note we allocate 4 extra chars to hold the prefixed alphabetic
		 * index into the first 4 charachters (the 5th extra char is the trailing
		 * null character).
		 */
		collation_key = g_malloc (key_len + 5);

		/* Format the alphabetic index into the first 4 chars */
		snprintf (collation_key, key_len, "%03d-", alphabet_index);

		/* Get the sort key and put it in &collation_key[4] */
		ucol_getSortKey (
			collator->coll, source, source_len,
			(guchar *)(collation_key + 4), key_len);

		/* Just being paranoid, make sure we're null terminated since the API
		 * doesn't specify if the result length is null character inclusive
		 */
		collation_key[key_len + 4] = '\0';
	} else {
		GString *string = g_string_new (NULL);

		/* Format the alphabetic index into the first 4 chars */
		g_string_append_printf (string, "%03d-", alphabet_index);

		/* Insert the rest of the sort key from the stack buffer into the allocated buffer */
		g_string_insert_len (string, 4, stack_buffer, key_len);

		collation_key = g_string_free (string, FALSE);
	}

	g_free (free_me);
	g_free (translit_str);

	return (gchar *) collation_key;
}

/**
 * e_collator_generate_key_for_index:
 * @collator: An #ECollator
 * @index: An index into the alphabetic labels
 *
 * Generates a sort key for the given alphabetic @index.
 *
 * The generated sort key is guaranteed to sort below
 * any sort keys for words beginning with any variant of
 * the given letter.
 *
 * For instance, a sort key generated for the index 5 of
 * a latin alphabet, where the fifth index is 'E' will sort
 * below any sort keys generated for words starting with
 * the characters 'e', 'E', 'é', 'É', 'è' or 'È'. It will also
 * sort above any sort keys generated for words starting with
 * the characters 'd' or 'D'.
 *
 * Returns: (transfer full): A sort key for the given index
 *
 * Since: 3.12
 */
gchar *
e_collator_generate_key_for_index (ECollator *collator,
                                   gint index)
{
	g_return_val_if_fail (collator != NULL, NULL);
	g_return_val_if_fail (index >= 0 && index < collator->n_labels, NULL);

	return g_strdup_printf ("%03d", index);
}

/**
 * e_collator_collate:
 * @collator: An #ECollator
 * @str_a: (allow-none): A string to compare
 * @str_b: (allow-none): The string to compare with @str_a
 * @result: (out): A location to store the comparison result
 * @error: (allow-none): A location to store a #GError from the #E_COLLATOR_ERROR domain
 *
 * Compares @str_a with @str_b, the order of strings is determined by the parameters of @collator.
 *
 * The @result will be set to integer less than, equal to, or greater than zero if @str_a is found,
 * respectively, to be less than, to match, or be greater than @str_b.
 *
 * Either @str_a or @str_b can be %NULL, %NULL strings are considered to sort below other strings.
 *
 * This function will first ensure that both strings are valid UTF-8.
 *
 * Returns: %TRUE on success, otherwise if %FALSE is returned then @error will be set.
 *
 * Since: 3.12
 */
gboolean
e_collator_collate (ECollator *collator,
                    const gchar *str_a,
                    const gchar *str_b,
                    gint *result,
                    GError **error)
{
	gchar *sort_key_a, *sort_key_b;

	g_return_val_if_fail (collator != NULL, -1);
	g_return_val_if_fail (result != NULL, -1);

	if (!str_a || !str_b) {
		*result = g_strcmp0 (str_a, str_b);
		return TRUE;
	}

	sort_key_a = e_collator_generate_key (collator, str_a, error);
	if (!sort_key_a)
		return FALSE;

	sort_key_b = e_collator_generate_key (collator, str_b, error);
	if (!sort_key_b) {
		g_free (sort_key_a);
		return FALSE;
	}

	*result = strcmp (sort_key_a, sort_key_b);

	g_free (sort_key_a);
	g_free (sort_key_b);

	return TRUE;
}

/**
 * e_collator_get_index_labels:
 * @collator: An #ECollator
 * @n_labels: (out): The number of labels/indexes available for @collator
 * @underflow: (allow-none) (out): The underflow index, for any words which sort below the active alphabet(s)
 * @inflow: (allow-none) (out): The inflow index, for any words which sort between the active alphabets (if there is more than one)
 * @overflow: (allow-none) (out): The overflow index, for any words which sort above the active alphabet(s)
 *
 * Fetches the displayable labels and index positions for the active alphabet.
 *
 * Returns: (array zero-terminated=1) (element-type utf8) (transfer none):
 *   The array of displayable labels for each index in the active alphabet(s).
 *
 * Since: 3.12
 */
const gchar *const  *
e_collator_get_index_labels (ECollator *collator,
                             gint *n_labels,
                             gint *underflow,
                             gint *inflow,
                             gint *overflow)
{
	g_return_val_if_fail (collator != NULL, NULL);

	if (n_labels)
		*n_labels = collator->n_labels;
	if (underflow)
		*underflow = collator->underflow;
	if (inflow)
		*inflow = collator->inflow;
	if (overflow)
		*overflow = collator->overflow;

	return (const gchar *const  *) collator->labels;
}

/**
 * e_collator_get_index:
 * @collator: An #ECollator
 * @str: A string
 *
 * Checks which index, as determined by e_collator_get_index_labels(),
 * that @str should sort under.
 *
 * Returns: The alphabetic index under which @str would sort
 *
 * Since: 3.12
 */
gint
e_collator_get_index (ECollator *collator,
                      const gchar *str)
{
	gint index;
	gchar *translit_str = NULL;
	const gchar *input_str;

	g_return_val_if_fail (collator != NULL, -1);
	g_return_val_if_fail (str != NULL, -1);

	/* We may need to perform a conversion before generating the sort key */
	if (collator->transliterator) {
		translit_str = _e_transliterator_cxx_transliterate (collator->transliterator, str);
		input_str = translit_str;
	} else {
		input_str = str;
	}

	index = _e_alphabet_index_cxx_get_index (collator->alpha_index, input_str);

	g_free (translit_str);

	return index;
}
