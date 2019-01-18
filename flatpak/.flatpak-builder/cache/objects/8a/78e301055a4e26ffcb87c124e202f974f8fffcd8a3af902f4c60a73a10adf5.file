/*
 * Authors :
 *  Chenthill Palanisamy <pchenthill@novell.com>
 *
 * Copyright 2007, Novell, Inc.
 *
 * This library is free software; you can redistribute it and/or modify
 * it under the terms of either:
 *
 *   The LGPL as published by the Free Software Foundation, version
 *   2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html
 *
 * Or:
 *
 *   The Mozilla Public License Version 2.0. You may obtain a copy of
 *   the License at http://www.mozilla.org/MPL/
 */

#ifndef ICALTZUTIL_H
#define ICALTZUTIL_H

#include "libical_ical_export.h"
#include "icalcomponent.h"

#if defined(sun) && defined(__SVR4)
#define ZONES_TAB_SYSTEM_FILENAME "tab/zone_sun.tab"
#else
#define ZONES_TAB_SYSTEM_FILENAME "zone.tab"
#endif

LIBICAL_ICAL_EXPORT const char *icaltzutil_get_zone_directory(void);

LIBICAL_ICAL_EXPORT icalcomponent *icaltzutil_fetch_timezone(const char *location);

#endif
