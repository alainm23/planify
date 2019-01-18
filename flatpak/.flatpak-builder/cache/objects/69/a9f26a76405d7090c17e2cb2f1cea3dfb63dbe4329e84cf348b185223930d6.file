/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2012,2013 Intel Corporation
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
 * Authors: Mathias Hasselmann <mathias@openismus.com>
 */

#include "evolution-data-server-config.h"

#include "e-phone-number.h"

#include <glib/gi18n-lib.h>

#include "e-phone-number-private.h"

G_DEFINE_BOXED_TYPE (
	EPhoneNumber, e_phone_number,
	e_phone_number_copy, e_phone_number_free)

G_DEFINE_QUARK (e-phone-number-error-quark, e_phone_number_error)

static const gchar *
e_phone_number_error_to_string (EPhoneNumberError code)
{
	switch (code) {
	case E_PHONE_NUMBER_ERROR_NOT_IMPLEMENTED:
		return _("The library was built without phone number support.");
	case E_PHONE_NUMBER_ERROR_UNKNOWN:
		return _("The phone number parser reported a yet unknown error code.");
	case E_PHONE_NUMBER_ERROR_NOT_A_NUMBER:
		return _("Not a phone number");
	case E_PHONE_NUMBER_ERROR_INVALID_COUNTRY_CODE:
		return _("Invalid country calling code");
	case E_PHONE_NUMBER_ERROR_TOO_SHORT_AFTER_IDD:
		return _("Remaining text after the country calling code is too short for a phone number");
	case E_PHONE_NUMBER_ERROR_TOO_SHORT:
		return _("Text is too short for a phone number");
	case E_PHONE_NUMBER_ERROR_TOO_LONG:
		return _("Text is too long for a phone number");
	}

	return _("Unknown error");
}

void
_e_phone_number_set_error (GError **error,
                           EPhoneNumberError code)
{
	const gchar *message = e_phone_number_error_to_string (code);
	g_set_error_literal (error, E_PHONE_NUMBER_ERROR, code, message);
}

/**
 * e_phone_number_is_supported:
 *
 * Checks if phone number support is available. It is recommended to call this
 * function before using any of the phone-utils functions to ensure that the
 * required functionality is available, and to pick alternative mechanisms if
 * needed.
 *
 * Returns: %TRUE if phone number support is available.
 *
 * Since: 3.8
 **/
gboolean
e_phone_number_is_supported (void)
{
#ifdef ENABLE_PHONENUMBER

	return TRUE;

#else /* ENABLE_PHONENUMBER */

	return FALSE;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_get_country_code_for_region:
 * @region_code: (allow-none): a two-letter country code, a locale name, or
 * %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Retrieves the preferred country calling code for @region_code,
 * e.g. 358 for "fi" or 1 for "en_US@UTF-8".
 *
 * If %NULL is passed for @region_code the default region as returned by
 * e_phone_number_get_default_region() is used.
 *
 * Returns: a valid country calling code, or zero if an unknown region
 * code was passed.
 *
 * Since: 3.8
 */
gint
e_phone_number_get_country_code_for_region (const gchar *region_code,
                                            GError **error)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_get_country_code_for_region (region_code);

#else /* ENABLE_PHONENUMBER */

	_e_phone_number_set_error (error, E_PHONE_NUMBER_ERROR_NOT_IMPLEMENTED);
	return 0;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_get_default_region:
 * @error: (out): a #GError to set an error, if any
 *
 * Retrieves the current two-letter country code that's used by default for
 * parsing phone numbers in e_phone_number_from_string(). It can be useful
 * to store this number before parsing a bigger number of phone numbers.
 *
 * The result of this functions depends on the current setup of the
 * %LC_ADDRESS category: If that category provides a reasonable value
 * for %_NL_ADDRESS_COUNTRY_AB2 this value is returned. Otherwise the
 * locale name configured for %LC_ADDRESS is parsed.
 *
 * Returns: (transfer full): a newly allocated string containing the
 * current locale's two-letter code for phone number parsing.
 *
 * Since: 3.8
 */
gchar *
e_phone_number_get_default_region (GError **error)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_get_default_region ();

#else /* ENABLE_PHONENUMBER */

	_e_phone_number_set_error (error, E_PHONE_NUMBER_ERROR_NOT_IMPLEMENTED);
	return NULL;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_from_string:
 * @phone_number: the phone number to parse
 * @region_code: (allow-none): a two-letter country code, or %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Parses the string passed in @phone_number. Note that no validation is
 * performed whether the recognized phone number is valid for a particular
 * region.
 *
 * The two-letter country code passed in @region_code only is used if the
 * @phone_number is not written in international format. The application's
 * default region as returned by e_phone_number_get_default_region() is used
 * if @region_code is %NULL.
 *
 * If the number is guaranteed to start with a '+' followed by the country
 * calling code, then "ZZ" can be passed for @region_code.
 *
 * Returns: (transfer full): a new EPhoneNumber instance on success,
 * or %NULL on error. Call e_phone_number_free() to release this instance.
 *
 * Since: 3.8
 **/
EPhoneNumber *
e_phone_number_from_string (const gchar *phone_number,
                            const gchar *region_code,
                            GError **error)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_from_string (phone_number, region_code, error);

#else /* ENABLE_PHONENUMBER */

	_e_phone_number_set_error (error, E_PHONE_NUMBER_ERROR_NOT_IMPLEMENTED);
	return NULL;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_to_string:
 * @phone_number: the phone number to format
 * @format: the phone number format to apply
 *
 * Describes the @phone_number according to the rules applying to @format.
 *
 * Returns: (transfer full): A formatted string for @phone_number.
 *
 * Since: 3.8
 **/
gchar *
e_phone_number_to_string (const EPhoneNumber *phone_number,
                          EPhoneNumberFormat format)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_to_string (phone_number, format);

#else /* ENABLE_PHONENUMBER */

	/* The EPhoneNumber instance must be invalid. We'd also bail out with
	 * a warning if phone numbers are supported. Any code triggering this
	 * is broken and should be fixed. */
	g_warning ("%s: The library was built without phone number support.", G_STRFUNC);
	return NULL;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_get_country_code:
 * @phone_number: the phone number to query
 * @source: an optional location for storing the phone number's origin, or %NULL
 *
 * Queries the @phone_number's country calling code and optionally stores the country
 * calling code's origin in @source. For instance when parsing "+1-617-5423789" this
 * function would return one and assing E_PHONE_NUMBER_COUNTRY_FROM_FQTN to @source.
 *
 * Returns: A valid country calling code, or zero if no code is known.
 *
 * Since: 3.8
 **/
gint
e_phone_number_get_country_code (const EPhoneNumber *phone_number,
                                 EPhoneNumberCountrySource *source)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_get_country_code (phone_number, source);

#else /* ENABLE_PHONENUMBER */

	/* The EPhoneNumber instance must be invalid. We'd also bail out with
	 * a warning if phone numbers are supported. Any code triggering this
	 * is broken and should be fixed. */
	g_warning ("%s: The library was built without phone number support.", G_STRFUNC);
	return 0;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_get_national_number:
 * @phone_number: the phone number to query
 *
 * Queries the national portion of @phone_number without any call-out
 * prefixes. For instance when parsing "+1-617-5423789" this function would
 * return the string "6175423789".
 *
 * Returns: (transfer full): The national portion of @phone_number.
 *
 * Since: 3.8
 **/
gchar *
e_phone_number_get_national_number (const EPhoneNumber *phone_number)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_get_national_number (phone_number);

#else /* ENABLE_PHONENUMBER */

	/* The EPhoneNumber instance must be invalid. We'd also bail out with
	 * a warning if phone numbers are supported. Any code triggering this
	 * is broken and should be fixed. */
	g_warning ("%s: The library was built without phone number support.", G_STRFUNC);
	return NULL;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_compare:
 * @first_number: the first EPhoneNumber to compare
 * @second_number: the second EPhoneNumber to compare
 *
 * Compares two phone numbers.
 *
 * Returns: The quality of matching for the two phone numbers.
 *
 * Since: 3.8
 **/
EPhoneNumberMatch
e_phone_number_compare (const EPhoneNumber *first_number,
                        const EPhoneNumber *second_number)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_compare (first_number, second_number);

#else /* ENABLE_PHONENUMBER */

	/* The EPhoneNumber instance must be invalid. We'd also bail out with
	 * a warning if phone numbers are supported. Any code triggering this
	 * is broken and should be fixed. */
	g_warning ("%s: The library was built without phone number support.", G_STRFUNC);
	return E_PHONE_NUMBER_MATCH_NONE;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_compare_strings:
 * @first_number: the first EPhoneNumber to compare
 * @second_number: the second EPhoneNumber to compare
 * @error: (out): a #GError to set an error, if any
 *
 * Compares two phone numbers.
 *
 * Returns: The quality of matching for the two phone numbers.
 *
 * Since: 3.8
 **/
EPhoneNumberMatch
e_phone_number_compare_strings (const gchar *first_number,
                                const gchar *second_number,
                                GError **error)
{
	return e_phone_number_compare_strings_with_region (
		first_number, second_number, NULL, error);
}

/**
 * e_phone_number_compare_strings_with_region:
 * @first_number: the first EPhoneNumber to compare
 * @second_number: the second EPhoneNumber to compare
 * @region_code: (allow-none): a two-letter country code, or %NULL
 * @error: (out): a #GError to set an error, if any
 *
 * Compares two phone numbers within the context of @region_code.
 *
 * Returns: The quality of matching for the two phone numbers.
 *
 * Since: 3.8
 **/
EPhoneNumberMatch
e_phone_number_compare_strings_with_region (const gchar *first_number,
                                            const gchar *second_number,
                                            const gchar *region_code,
                                            GError **error)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_compare_strings (
		first_number, second_number, region_code, error);

#else /* ENABLE_PHONENUMBER */

	_e_phone_number_set_error (error, E_PHONE_NUMBER_ERROR_NOT_IMPLEMENTED);
	return E_PHONE_NUMBER_MATCH_NONE;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_copy:
 * @phone_number: the EPhoneNumber to copy
 *
 * Makes a copy of @phone_number.
 *
 * Returns: (transfer full): A newly allocated EPhoneNumber instance.
 * Call e_phone_number_free() to release this instance.
 *
 * Since: 3.8
 **/
EPhoneNumber *
e_phone_number_copy (const EPhoneNumber *phone_number)
{
#ifdef ENABLE_PHONENUMBER

	return _e_phone_number_cxx_copy (phone_number);

#else /* ENABLE_PHONENUMBER */

	/* Without phonenumber support there are no instances.
	 * Any non-NULL value is a programming error in this setup. */
	g_warn_if_fail (phone_number == NULL);
	return NULL;

#endif /* ENABLE_PHONENUMBER */
}

/**
 * e_phone_number_free:
 * @phone_number: the EPhoneNumber to free
 *
 * Released the memory occupied by @phone_number.
 *
 * Since: 3.8
 **/
void
e_phone_number_free (EPhoneNumber *phone_number)
{
#ifdef ENABLE_PHONENUMBER

	_e_phone_number_cxx_free (phone_number);

#else /* ENABLE_PHONENUMBER */

	/* Without phonenumber support there are no instances.
	 * Any non-NULL value is a programming error in this setup. */
	g_warn_if_fail (phone_number == NULL);

#endif /* ENABLE_PHONENUMBER */
}
