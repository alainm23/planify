/*======================================================================
  FILE: icalrestriction.h
  CREATOR: eric 24 April 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 The original code is icalrestriction.h

 Contributions from:
    Graham Davison (g.m.davison@computer.org)
======================================================================*/

#ifndef ICALRESTRICTION_H
#define ICALRESTRICTION_H

/**
 * @file icalrestriction.h
 * @brief Functions to check if an ::icalcomponent meets the restrictions
 *  imposed by the standard.
 */

#include "libical_ical_export.h"
#include "icalcomponent.h"
#include "icalproperty.h"

/**
 * @brief The kinds of icalrestrictions there are
 *
 * These must stay in this order for icalrestriction_compare to work
 */
typedef enum icalrestriction_kind
{
    /** No restriction */
    ICAL_RESTRICTION_NONE = 0, /* 0 */

    /** Zero */
    ICAL_RESTRICTION_ZERO, /* 1 */

    /** One */
    ICAL_RESTRICTION_ONE, /* 2 */

    /** Zero or more */
    ICAL_RESTRICTION_ZEROPLUS, /* 3 */

    /** One or more */
    ICAL_RESTRICTION_ONEPLUS, /* 4 */

    /** Zero or one */
    ICAL_RESTRICTION_ZEROORONE, /* 5 */

    /** Zero or one, exclusive with another property */
    ICAL_RESTRICTION_ONEEXCLUSIVE, /* 6 */

    /** Zero or one, mutual with another property */
    ICAL_RESTRICTION_ONEMUTUAL, /* 7 */

    /** Unknown */
    ICAL_RESTRICTION_UNKNOWN    /* 8 */
} icalrestriction_kind;

/**
 * @brief Checks if the given @a count is in accordance with the given
 *  restriction, @a restr.
 * @param restr The restriction to apply to the @a count
 * @param count The amount present that is to be checked against the restriction
 * @return 1 if the restriction is met, 0 if not
 *
 * ### Example
 * ```c
 * assert(icalrestriction_compare(ICALRESTRICTION_ONEPLUS, 5) == true);
 * assert(icalrestriction_compare(ICALRESTRICTION_NONE,    3) == false);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalrestriction_compare(icalrestriction_kind restr, int count);

/**
 * @brief Checks if a given `VCALENDAR` meets all the restrictions imposed by
 *  the standard.
 * @param comp The `VCALENDAR` component to check
 * @return 1 if the restrictions are met, 0 if not
 *
 * @par Error handling
 * Returns 0 and sets ::icalerrno if `NULL` is passed as @a comp, or if the
 * component is not a `VCALENDAR`.
 *
 * ### Example
 * ```c
 * icalcomponent *component = // ...
 *
 * // check component
 * assert(icalrestriction_check(component) == true);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalrestriction_check(icalcomponent *comp);

#endif /* !ICALRESTRICTION_H */
