/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2016 Red Hat, Inc. (www.redhat.com)
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
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <string.h>

#include "camel-utils.h"

/**
 * camel_util_bdata_get_number:
 * @bdata_ptr: a backend specific data (bdata) pointer
 * @default_value: a value to return, when no data can be read
 *
 * Reads a numeric data from the @bdata_ptr and moves the @bdata_ptr
 * after that number. If the number cannot be read, then the @default_value
 * is returned instead and the @bdata_ptr is left unchanged. The number
 * might be previously stored with the camel_util_bdata_put_number().
 *
 * Returns: The read number, or the @default_value, if the @bdata_ptr doesn't
 *    point to a number.
 *
 * Since: 3.24
 **/
gint64
camel_util_bdata_get_number (/* const */ gchar **bdata_ptr,
			     gint64 default_value)
{
	gint64 result;
	gchar *endptr;

	g_return_val_if_fail (bdata_ptr != NULL, default_value);

	if (!bdata_ptr || !*bdata_ptr || !**bdata_ptr)
		return default_value;

	if (**bdata_ptr == ' ')
		*bdata_ptr += 1;

	if (!**bdata_ptr)
		return default_value;

	endptr = *bdata_ptr;

	result = g_ascii_strtoll (*bdata_ptr, &endptr, 10);

	if (endptr == *bdata_ptr)
		result = default_value;
	else
		*bdata_ptr = endptr;

	return result;
}

/**
 * camel_util_bdata_put_number:
 * @bdata_str: a #GString to store a backend specific data (bdata)
 * @value: a value to store
 *
 * Puts the number @value at the end of the @bdata_str. In case the @bdata_str
 * is not empty a space is added before the numeric @value. The stored value
 * can be read back with the camel_util_bdata_get_number().
 *
 * Since: 3.24
 **/
void
camel_util_bdata_put_number (GString *bdata_str,
			     gint64 value)
{
	g_return_if_fail (bdata_str != NULL);

	if (bdata_str->len && bdata_str->str[bdata_str->len - 1] != ' ')
		g_string_append_c (bdata_str, ' ');

	g_string_append_printf (bdata_str, "%" G_GINT64_FORMAT, value);
}

/**
 * camel_util_bdata_get_string:
 * @bdata_ptr: a backend specific data (bdata) pointer
 * @default_value: a value to return, when no data can be read
 *
 * Reads a string data from the @bdata_ptr and moves the @bdata_ptr
 * after that string. If the string cannot be read, then the @default_value
 * is returned instead and the @bdata_ptr is left unchanged. The string
 * might be previously stored with the camel_util_bdata_put_string().
 *
 * Returns: (transfer full): Newly allocated string, which was read, or
 *    dupped the @default_value, if the @bdata_ptr doesn't point to a string.
 *    Free returned pointer with g_free() when done with it.
 *
 * Since: 3.24
 **/
gchar *
camel_util_bdata_get_string (/* const */ gchar **bdata_ptr,
			     const gchar *default_value)
{
	gint64 length, has_length;
	gchar *orig_bdata_ptr;
	gchar *result;

	g_return_val_if_fail (bdata_ptr != NULL, NULL);

	orig_bdata_ptr = *bdata_ptr;

	length = camel_util_bdata_get_number (bdata_ptr, -1);

	/* might be a '-' sign */
	if (*bdata_ptr && **bdata_ptr == '-')
		*bdata_ptr += 1;
	else
		length = -1;

	if (length < 0 || !*bdata_ptr || !**bdata_ptr || *bdata_ptr == orig_bdata_ptr) {
		*bdata_ptr = orig_bdata_ptr;

		return g_strdup (default_value);
	}

	if (!length)
		return g_strdup ("");

	has_length = strlen (*bdata_ptr);
	if (has_length < length)
		length = has_length;

	result = g_strndup (*bdata_ptr, length);
	*bdata_ptr += length;

	return result;
}

/**
 * camel_util_bdata_put_string:
 * @bdata_str: a #GString to store a backend specific data (bdata)
 * @value: a value to store
 *
 * Puts the string @value at the end of the @bdata_str. In case the @bdata_str
 * is not empty a space is added before the string @value. The stored value
 * can be read back with the camel_util_bdata_get_string().
 *
 * The strings are encoded as "length-value", quotes for clarity only.
 *
 * Since: 3.24
 **/
void
camel_util_bdata_put_string (GString *bdata_str,
			     const gchar *value)
{
	g_return_if_fail (bdata_str != NULL);
	g_return_if_fail (value != NULL);

	camel_util_bdata_put_number (bdata_str, strlen (value));

	g_string_append_printf (bdata_str, "-%s", value);
}

/**
 * camel_time_value_apply:
 * @src_time: a time_t to apply the value to, or -1 to use the current time
 * @unit: a #CamelTimeUnit
 * @value: a value to apply
 *
 * Applies the given time @value in unit @unit to the @src_time.
 * Use negative value to subtract it. The time part is rounded
 * to the beginning of the day.
 *
 * Returns: @src_time modified by the given parameters as date, with
 *    the time part being beginning of the day.
 *
 * Since: 3.24
 **/
time_t
camel_time_value_apply (time_t src_time,
			CamelTimeUnit unit,
			gint value)
{
	GDate dt;
	struct tm tm;

	g_return_val_if_fail (unit >= CAMEL_TIME_UNIT_DAYS && unit <= CAMEL_TIME_UNIT_YEARS, src_time);

	if (src_time == (time_t) -1)
		src_time = time (NULL);

	if (!value)
		return src_time;

	g_date_clear (&dt, 1);

	g_date_set_time_t (&dt, src_time);

	switch (unit) {
	case CAMEL_TIME_UNIT_DAYS:
		if (value > 0)
			g_date_add_days (&dt, value);
		else
			g_date_subtract_days (&dt, (-1) * value);
		break;
	case CAMEL_TIME_UNIT_WEEKS:
		if (value > 0)
			g_date_add_days (&dt, value * 7);
		else
			g_date_subtract_days (&dt, (-1) * value * 7);
		break;
	case CAMEL_TIME_UNIT_MONTHS:
		if (value > 0)
			g_date_add_months (&dt, value);
		else
			g_date_subtract_months (&dt, (-1) * value);
		break;
	case CAMEL_TIME_UNIT_YEARS:
		if (value > 0)
			g_date_add_years (&dt, value);
		else
			g_date_subtract_years (&dt, (-1) * value);
		break;
	}

	g_date_to_struct_tm (&dt, &tm);

	tm.tm_sec = 0;
	tm.tm_min = 0;
	tm.tm_hour = 0;

	return mktime (&tm);
}
