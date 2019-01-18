/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2012-2014 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "as-enums.h"

/**
 * SECTION:as-enums
 * @short_description: Some enums used by various other modules
 * @include: appstream.h
 */

/**
 * as_url_kind_to_string:
 * @url_kind: the %AsUrlKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @url_kind
 **/
const gchar*
as_url_kind_to_string (AsUrlKind url_kind)
{
	if (url_kind == AS_URL_KIND_HOMEPAGE)
		return "homepage";
	if (url_kind == AS_URL_KIND_BUGTRACKER)
		return "bugtracker";
	if (url_kind == AS_URL_KIND_FAQ)
		return "faq";
	if (url_kind == AS_URL_KIND_HELP)
		return "help";
	if (url_kind == AS_URL_KIND_DONATION)
		return "donation";
	if (url_kind == AS_URL_KIND_TRANSLATE)
		return "translate";
	if (url_kind == AS_URL_KIND_CONTACT)
		return "contact";
	return "unknown";
}

/**
 * as_url_kind_from_string:
 * @url_kind: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a #AsUrlKind or %AS_URL_KIND_UNKNOWN for unknown
 **/
AsUrlKind
as_url_kind_from_string (const gchar *url_kind)
{
	if (g_strcmp0 (url_kind, "homepage") == 0)
		return AS_URL_KIND_HOMEPAGE;
	if (g_strcmp0 (url_kind, "bugtracker") == 0)
		return AS_URL_KIND_BUGTRACKER;
	if (g_strcmp0 (url_kind, "faq") == 0)
		return AS_URL_KIND_FAQ;
	if (g_strcmp0 (url_kind, "help") == 0)
		return AS_URL_KIND_HELP;
	if (g_strcmp0 (url_kind, "donation") == 0)
		return AS_URL_KIND_DONATION;
	if (g_strcmp0 (url_kind, "translate") == 0)
		return AS_URL_KIND_TRANSLATE;
	if (g_strcmp0 (url_kind, "contact") == 0)
		return AS_URL_KIND_CONTACT;
	return AS_URL_KIND_UNKNOWN;
}

/**
 * as_urgency_kind_to_string:
 * @urgency_kind: the %AsUrgencyKind.
 *
 * Converts the enumerated value to an text representation.
 *
 * Returns: string version of @urgency_kind
 *
 * Since: 0.6.5
 **/
const gchar*
as_urgency_kind_to_string (AsUrgencyKind urgency_kind)
{
	if (urgency_kind == AS_URGENCY_KIND_LOW)
		return "low";
	if (urgency_kind == AS_URGENCY_KIND_MEDIUM)
		return "medium";
	if (urgency_kind == AS_URGENCY_KIND_HIGH)
		return "high";
	if (urgency_kind == AS_URGENCY_KIND_CRITICAL)
		return "critical";
	return "unknown";
}

/**
 * as_urgency_kind_from_string:
 * @urgency_kind: the string.
 *
 * Converts the text representation to an enumerated value.
 *
 * Returns: a %AsUrgencyKind or %AS_URGENCY_KIND_UNKNOWN for unknown
 *
 * Since: 0.6.5
 **/
AsUrgencyKind
as_urgency_kind_from_string (const gchar *urgency_kind)
{
	if (g_strcmp0 (urgency_kind, "low") == 0)
		return AS_URGENCY_KIND_LOW;
	if (g_strcmp0 (urgency_kind, "medium") == 0)
		return AS_URGENCY_KIND_MEDIUM;
	if (g_strcmp0 (urgency_kind, "high") == 0)
		return AS_URGENCY_KIND_HIGH;
	if (g_strcmp0 (urgency_kind, "critical") == 0)
		return AS_URGENCY_KIND_CRITICAL;
	return AS_URGENCY_KIND_UNKNOWN;
}
