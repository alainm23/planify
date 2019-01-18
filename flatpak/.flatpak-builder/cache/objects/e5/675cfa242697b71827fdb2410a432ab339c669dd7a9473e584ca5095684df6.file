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

#if !defined (__LIBEBOOK_CONTACTS_H_INSIDE__) && !defined (LIBEBOOK_CONTACTS_COMPILATION)
#error "Only <libebook-contacts/libebook-contacts.h> should be included directly."
#endif

#ifndef E_PHONE_NUMBER_H
#define E_PHONE_NUMBER_H

/**
 * SECTION: e-phone-number
 * @include: libedataserver/libedataserver.h
 * @short_description: Phone number support
 *
 * This modules provides utility functions for parsing and formatting
 * phone numbers. Under the hood it uses Google's libphonenumber.
 **/

#include <glib-object.h>

G_BEGIN_DECLS

#define E_TYPE_PHONE_NUMBER (e_phone_number_get_type ())
#define E_PHONE_NUMBER_ERROR (e_phone_number_error_quark ())

/**
 * EPhoneNumberFormat:
 * @E_PHONE_NUMBER_FORMAT_E164: format according E.164: "+493055667788".
 * @E_PHONE_NUMBER_FORMAT_INTERNATIONAL: a formatted phone number always
 * starting with the country calling code: "+49 30 55667788".
 * @E_PHONE_NUMBER_FORMAT_NATIONAL: a formatted phone number in national
 * scope, that is without country calling code: "(030) 55667788".
 * @E_PHONE_NUMBER_FORMAT_RFC3966: a tel: URL according to RFC 3966:
 * "tel:+49-30-55667788".
 *
 * The supported formatting rules for phone numbers.
 *
 * Since: 3.8
 **/
typedef enum {
	E_PHONE_NUMBER_FORMAT_E164,
	E_PHONE_NUMBER_FORMAT_INTERNATIONAL,
	E_PHONE_NUMBER_FORMAT_NATIONAL,
	E_PHONE_NUMBER_FORMAT_RFC3966
} EPhoneNumberFormat;

/**
 * EPhoneNumberMatch:
 * @E_PHONE_NUMBER_MATCH_NONE: The phone numbers did not match.
 * @E_PHONE_NUMBER_MATCH_EXACT: The phone numbers matched exactly. Two phone number strings are an exact match
 * if the country code, national phone number, presence of a leading zero for Italian numbers and any
 * extension present are the same.
 * @E_PHONE_NUMBER_MATCH_NATIONAL: The national phone number matched. Two phone number strings match at
 * this strength if either or both has no region specified, and the national phone number 
 * and extensions are the same.
 * @E_PHONE_NUMBER_MATCH_SHORT: The weakest sort of match. Two phone numbers match at
 * this strength if either or both has no region specified, or the region specified is the same, and one national
 * phone number could be a shorter version of the other number. This includes the case where one has an extension specified,
 * and the other does not.
 *
 * The strength of a phone number match.
 *
 * <example>
 * <title>Some examples of phone number matches</title>
 * <para>
 * Let's consider the phone number "+1-221-5423789", then comparing with
 * "+1.221.542.3789" we have get E_PHONE_NUMBER_MATCH_EXACT because country
 * code, region code and local number are matching. Comparing with "2215423789"
 * will result in E_PHONE_NUMBER_MATCH_NATIONAL because the country calling code
 * is missing, but the national portion is matching. Finally comparing with
 * "5423789" gives E_PHONE_NUMBER_MATCH_SHORT. For more detail have a look at
 * the following table:
 *
 * <informaltable border="1" align="center">
 *  <colgroup>
 *   <col width="20%" />
 *   <col width="20%" />
 *   <col width="20%" />
 *   <col width="20%" />
 *   <col width="20%" />
 *  </colgroup>
 *  <tbody>
 *   <tr>
 *    <th></th>
 *    <th align="center">+1-617-5423789</th>
 *    <th align="center">+1-221-5423789</th>
 *    <th align="center">221-5423789</th>
 *    <th align="center">5423789</th>
 *   </tr><tr>
 *    <th align="right">+1-617-5423789</th>
 *    <td align="center">exact</td>
 *    <td align="center">none</td>
 *    <td align="center">none</td>
 *    <td align="center">short</td>
 *   </tr><tr>
 *    <th align="right">+1-221-5423789</th>
 *    <td align="center">none</td>
 *    <td align="center">exact</td>
 *    <td align="center">national</td>
 *    <td align="center">short</td>
 *   </tr><tr>
 *    <th align="right">221-5423789</th>
 *    <td align="center">none</td>
 *    <td align="center">national</td>
 *    <td align="center">national</td>
 *    <td align="center">short</td>
 *   </tr><tr>
 *    <th align="right">5423789</th>
 *    <td align="center">short</td>
 *    <td align="center">short</td>
 *    <td align="center">short</td>
 *    <td align="center">short</td>
 *   </tr>
 *  </tbody>
 * </informaltable>
 * </para>
 * </example>
 *
 * Since: 3.8
 **/
typedef enum {
	E_PHONE_NUMBER_MATCH_NONE,
	E_PHONE_NUMBER_MATCH_EXACT,
	E_PHONE_NUMBER_MATCH_NATIONAL = 1024,
	E_PHONE_NUMBER_MATCH_SHORT = 2048
} EPhoneNumberMatch;

/**
 * EPhoneNumberError:
 * @E_PHONE_NUMBER_ERROR_NOT_IMPLEMENTED: the library was built without phone
 * number support
 * @E_PHONE_NUMBER_ERROR_UNKNOWN: the phone number parser reported a yet
 * unknown error code.
 * @E_PHONE_NUMBER_ERROR_INVALID_COUNTRY_CODE: the supplied phone number has an
 * invalid country calling code.
 * @E_PHONE_NUMBER_ERROR_NOT_A_NUMBER: the supplied text is not a phone number.
 * @E_PHONE_NUMBER_ERROR_TOO_SHORT_AFTER_IDD: the remaining text after the
 * country calling code is to short for a phone number.
 * @E_PHONE_NUMBER_ERROR_TOO_SHORT: the text is too short for a phone number.
 * @E_PHONE_NUMBER_ERROR_TOO_LONG: the text is too long for a phone number.
 *
 * Numeric description of a phone number related error.
 *
 * Since: 3.8
 **/
typedef enum {
	E_PHONE_NUMBER_ERROR_NOT_IMPLEMENTED,
	E_PHONE_NUMBER_ERROR_UNKNOWN,
	E_PHONE_NUMBER_ERROR_NOT_A_NUMBER,
	E_PHONE_NUMBER_ERROR_INVALID_COUNTRY_CODE,
	E_PHONE_NUMBER_ERROR_TOO_SHORT_AFTER_IDD,
	E_PHONE_NUMBER_ERROR_TOO_SHORT,
	E_PHONE_NUMBER_ERROR_TOO_LONG
} EPhoneNumberError;

/**
 * EPhoneNumberCountrySource:
 * @E_PHONE_NUMBER_COUNTRY_FROM_FQTN:
 *   the EPhoneNumber was build from a fully qualified telephone number
 *   that contained a valid country calling code
 * @E_PHONE_NUMBER_COUNTRY_FROM_IDD:
 *   the parsed phone number started with the current locale's international
 *   call prefix, followed by a valid country calling code
 * @E_PHONE_NUMBER_COUNTRY_FROM_DEFAULT:
 *   the parsed phone didn't start with a (recognizable) country calling code,
 *   the code was chosen by checking the current locale settings
 *
 * The origin of a parsed EPhoneNumber's country calling code.
 *
 * Since: 3.8
 **/
typedef enum {
	E_PHONE_NUMBER_COUNTRY_FROM_FQTN = 1,
	E_PHONE_NUMBER_COUNTRY_FROM_IDD = 5,
	E_PHONE_NUMBER_COUNTRY_FROM_DEFAULT = 20
} EPhoneNumberCountrySource;

/**
 * EPhoneNumber:
 *
 * This opaque type describes a parsed phone number. It can be copied using
 * e_phone_number_copy(). To release it call e_phone_number_free().
 *
 * Since: 3.8
 **/
typedef struct _EPhoneNumber EPhoneNumber;

GType			e_phone_number_get_type		(void);
GQuark			e_phone_number_error_quark	(void);

gboolean		e_phone_number_is_supported	(void) G_GNUC_CONST;
gint			e_phone_number_get_country_code_for_region
							(const gchar *region_code,
							 GError **error);
gchar *			e_phone_number_get_default_region
							(GError **error);

EPhoneNumber *		e_phone_number_from_string	(const gchar *phone_number,
							 const gchar *region_code,
							 GError **error);
gchar *			e_phone_number_to_string	(const EPhoneNumber *phone_number,
							 EPhoneNumberFormat format);
gint			e_phone_number_get_country_code	(const EPhoneNumber *phone_number,
							 EPhoneNumberCountrySource *source);
gchar *			e_phone_number_get_national_number
							(const EPhoneNumber *phone_number);

EPhoneNumberMatch	e_phone_number_compare		(const EPhoneNumber *first_number,
							 const EPhoneNumber *second_number);
EPhoneNumberMatch	e_phone_number_compare_strings	(const gchar *first_number,
							 const gchar *second_number,
							 GError **error);
EPhoneNumberMatch	e_phone_number_compare_strings_with_region
							(const gchar *first_number,
							 const gchar *second_number,
							 const gchar *region_code,
							 GError **error);

EPhoneNumber *		e_phone_number_copy		(const EPhoneNumber *phone_number);
void			e_phone_number_free		(EPhoneNumber *phone_number);

G_END_DECLS

#endif /* E_PHONE_NUMBER_H */
