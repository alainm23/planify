/*======================================================================
 FILE: icalclassify.h
 CREATOR: eric 21 Aug 2000

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
 =========================================================================*/

#ifndef ICALCLASSIFY_H
#define ICALCLASSIFY_H

#include "libical_icalss_export.h"
#include "icalset.h"
#include "icalcomponent.h"

LIBICAL_ICALSS_EXPORT icalproperty_xlicclass icalclassify(icalcomponent *c,
                                                          icalcomponent *match, const char *user);

LIBICAL_ICALSS_EXPORT icalcomponent *icalclassify_find_overlaps(icalset *set,
                                                                icalcomponent *comp);

#endif /* ICALCLASSIFY_H */
