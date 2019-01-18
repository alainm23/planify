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
//krazy:excludeall=cpp

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "icaltz-util.h"
#include "icalerror.h"
#include "icaltimezone.h"

#include <stdlib.h>

#if defined(sun) && defined(__SVR4)
#include <sys/types.h>
#include <sys/byteorder.h>
#else
#if defined(HAVE_BYTESWAP_H)
#include <byteswap.h>
#endif
#if defined(HAVE_ENDIAN_H)
#include <endian.h>
#else
#if defined(HAVE_SYS_ENDIAN_H)
#include <sys/endian.h>
#if defined(bswap32)
#define bswap_32 bswap32
#else
#define bswap_32 swap32
#endif
#endif
#endif
#endif

#if defined(__OpenBSD__) && !defined(bswap_32)
#define bswap_32 swap32
#endif

#if defined(_MSC_VER)
#if !defined(HAVE_BYTESWAP_H) && !defined(HAVE_SYS_ENDIAN_H) && !defined(HAVE_ENDIAN_H)
#define bswap_16(x) (((x) << 8) & 0xff00) | (((x) >> 8) & 0xff)

#define bswap_32(x) \
(((x) << 24) & 0xff000000) | \
(((x) << 8) & 0xff0000)    | \
(((x) >> 8) & 0xff00)      | \
(((x) >> 24) & 0xff)

#define bswap_64(x) \
((((x) & 0xff00000000000000ull) >> 56) | \
(((x) & 0x00ff000000000000ull) >> 40)  | \
(((x) & 0x0000ff0000000000ull) >> 24)  | \
(((x) & 0x000000ff00000000ull) >> 8)   | \
(((x) & 0x00000000ff000000ull) << 8)   | \
(((x) & 0x0000000000ff0000ull) << 24)  | \
(((x) & 0x000000000000ff00ull) << 40)  | \
(((x) & 0x00000000000000ffull) << 56))
#endif
#include <io.h>
#endif

#if defined(__APPLE__) || defined(__MINGW32__)
#define bswap_16(x) (((x) << 8) & 0xff00) | (((x) >> 8) & 0xff)
#define bswap_32 __builtin_bswap32
#define bswap_64 __builtin_bswap64
#endif

typedef struct
{
    char ttisgmtcnt[4];
    char ttisstdcnt[4];
    char leapcnt[4];
    char timecnt[4];
    char typecnt[4];
    char charcnt[4];
} tzinfo;

static const char *zdir = NULL;

static const char *search_paths[] = {
    "/usr/share/zoneinfo",
    "/usr/lib/zoneinfo",
    "/etc/zoneinfo",
    "/usr/share/lib/zoneinfo"
};

#define EFREAD(buf,size,num,fs) \
if (fread(buf, size, num, fs) < num  && ferror(fs)) {  \
    icalerror_set_errno(ICAL_FILE_ERROR);              \
    goto error;                                        \
}

typedef struct
{
    long int gmtoff;
    unsigned char isdst;
    unsigned int abbr;
    unsigned char isstd;
    unsigned char isgmt;
    char *zname;

} ttinfo;

typedef struct
{
    time_t transition;
    long int change;
} leap;

static int decode(const void *ptr)
{
#if defined(sun) && defined(__SVR4)
    if (sizeof(int) == 4) {
#if defined(_BIG_ENDIAN)
        return *(const int *)ptr;
#else
        return BSWAP_32(*(const int *)ptr);
#endif
#else
    if ((BYTE_ORDER == BIG_ENDIAN) && sizeof(int) == 4) {
        return *(const int *)ptr;
    } else if (BYTE_ORDER == LITTLE_ENDIAN && sizeof(int) == 4) {
        return (int)bswap_32(*(const unsigned int *)ptr);
#endif
    } else {
        const unsigned char *p = ptr;
        int result = *p & (1 << (CHAR_BIT - 1)) ? ~0 : 0;

        /* cppcheck-suppress shiftNegativeLHS */
        result = (result << 8) | *p++;
        result = (result << 8) | *p++;
        result = (result << 8) | *p++;
        result = (result << 8) | *p++;

        return result;
    }
}

static char *zname_from_stridx(char *str, size_t idx)
{
    size_t i;
    size_t size;
    char *ret;

    i = idx;
    while (str[i] != '\0') {
        i++;
    }

    size = i - idx;
    str += idx;
    ret = (char *)malloc(size + 1);
    ret = strncpy(ret, str, size);
    ret[size] = '\0';

    return ret;
}

static void set_zonedir(void)
{
    char file_path[MAXPATHLEN];
    const char *fname = ZONES_TAB_SYSTEM_FILENAME;
    size_t i, num_search_paths;

    num_search_paths = sizeof(search_paths) / sizeof(search_paths[0]);
    for (i = 0; i < num_search_paths; i++) {
        snprintf(file_path, MAXPATHLEN, "%s/%s", search_paths[i], fname);
        if (!access(file_path, F_OK | R_OK)) {
            zdir = search_paths[i];
            break;
        }
    }
}

const char *icaltzutil_get_zone_directory(void)
{
    if (!zdir)
        set_zonedir();

    return zdir;
}

static int calculate_pos(icaltimetype icaltime)
{
   static int r_pos[] = {1, 2, 3, -2, -1};
   int pos;

   pos = (icaltime.day - 1) / 7;

   /* Check if pos 3 is the last occurrence of the week day in the month */
   if (pos == 3 && ((icaltime.day + 7) > icaltime_days_in_month(icaltime.month, icaltime.year))) {
       pos = 4;
   }

   return r_pos[pos];
}

static void adjust_dtstart_day_to_rrule(icalcomponent *comp, struct icalrecurrencetype rule)
{
    time_t now, year_start;
    struct icaltimetype start, comp_start, iter_start, itime;
    icalrecur_iterator *iter;

    now = time(NULL);
    itime = icaltime_from_timet_with_zone(now, 0, NULL);
    itime.month = itime.day = 1;
    itime.hour = itime.minute = itime.second = 0;
    year_start = icaltime_as_timet(itime);

    comp_start = icalcomponent_get_dtstart(comp);
    start = icaltime_from_timet_with_zone(year_start, 0, NULL);

    iter = icalrecur_iterator_new(rule, start);
    iter_start = icalrecur_iterator_next(iter);
    icalrecur_iterator_free(iter);

    if (iter_start.day != comp_start.day) {
        comp_start.day = iter_start.day;
        icalcomponent_set_dtstart(comp, comp_start);
    }
}

icalcomponent *icaltzutil_fetch_timezone(const char *location)
{
    tzinfo type_cnts;
    size_t i, num_trans, num_chars, num_leaps, num_isstd, num_isgmt;
    size_t num_types = 0;
    size_t size;
    int pos, sign;
    time_t now = time(NULL);

    const char *zonedir;
    FILE *f = NULL;
    char *full_path = NULL;
    time_t *transitions = NULL;
    char *r_trans = NULL, *temp;
    int *trans_idx = NULL;
    ttinfo *types = NULL;
    char *znames = NULL;
    leap *leaps = NULL;
    char *tzid = NULL;

    int idx, prev_idx;
    icalcomponent *tz_comp = NULL, *comp = NULL;
    icalproperty *icalprop;
    icaltimetype icaltime;
    struct icalrecurrencetype standard_recur;
    struct icalrecurrencetype daylight_recur;
    icaltimetype prev_standard_time = icaltime_null_time();
    icaltimetype prev_daylight_time = icaltime_null_time();
    icaltimetype prev_prev_standard_time;
    icaltimetype prev_prev_daylight_time;
    long prev_standard_gmtoff = 0;
    long prev_daylight_gmtoff = 0;
    icalcomponent *cur_standard_comp = NULL;
    icalcomponent *cur_daylight_comp = NULL;
    icalproperty *cur_standard_rrule_property = NULL;
    icalproperty *cur_daylight_rrule_property = NULL;

    if (icaltimezone_get_builtin_tzdata()) {
        goto error;
    }

    zonedir = icaltzutil_get_zone_directory();
    if (!zonedir) {
        icalerror_set_errno(ICAL_FILE_ERROR);
        goto error;
    }

    size = strlen(zonedir) + strlen(location) + 2;
    full_path = (char *)malloc(size);
    if (full_path == NULL) {
        icalerror_set_errno(ICAL_NEWFAILED_ERROR);
        goto error;
    }
    snprintf(full_path, size, "%s/%s", zonedir, location);
    if ((f = fopen(full_path, "rb")) == 0) {
        icalerror_set_errno(ICAL_FILE_ERROR);
        goto error;
    }

    if (fseek(f, 20, SEEK_SET) != 0) {
        icalerror_set_errno(ICAL_FILE_ERROR);
        goto error;
    }

    EFREAD(&type_cnts, 24, 1, f);

    num_isgmt = (size_t)decode(type_cnts.ttisgmtcnt);
    num_leaps = (size_t)decode(type_cnts.leapcnt);
    num_chars = (size_t)decode(type_cnts.charcnt);
    num_trans = (size_t)decode(type_cnts.timecnt);
    num_isstd = (size_t)decode(type_cnts.ttisstdcnt);
    num_types = (size_t)decode(type_cnts.typecnt);

    transitions = calloc(num_trans, sizeof(time_t));
    if (transitions == NULL) {
        icalerror_set_errno(ICAL_NEWFAILED_ERROR);
        goto error;
    }
    r_trans = calloc(num_trans, 4);
    if (r_trans == NULL) {
        icalerror_set_errno(ICAL_NEWFAILED_ERROR);
        goto error;
    }

    EFREAD(r_trans, 4, num_trans, f);
    temp = r_trans;
    if (num_trans) {
        trans_idx = calloc(num_trans, sizeof(int));
        if (trans_idx == NULL) {
            icalerror_set_errno(ICAL_NEWFAILED_ERROR);
            goto error;
        }
        for (i = 0; i < num_trans; i++) {
            trans_idx[i] = fgetc(f);
            transitions[i] = (time_t) decode(r_trans);
            r_trans += 4;
        }
    }
    r_trans = temp;

    types = calloc(num_types, sizeof(ttinfo));
    if (types == NULL) {
        icalerror_set_errno(ICAL_NEWFAILED_ERROR);
        goto error;
    }
    for (i = 0; i < num_types; i++) {
        unsigned char a[4];
        int c;

        EFREAD(a, 4, 1, f);
        c = fgetc(f);
        types[i].isdst = (unsigned char)c;
        if ((c = fgetc(f)) < 0) {
            break;
        }
        types[i].abbr = (unsigned int)c;
        types[i].gmtoff = decode(a);
    }

    znames = (char *)malloc(num_chars);
    if (znames == NULL) {
        icalerror_set_errno(ICAL_NEWFAILED_ERROR);
        goto error;
    }
    EFREAD(znames, num_chars, 1, f);

    /* We got all the information which we need */

    leaps = calloc(num_leaps, sizeof(leap));
    if (leaps == NULL) {
        icalerror_set_errno(ICAL_NEWFAILED_ERROR);
        goto error;
    }
    for (i = 0; i < num_leaps; i++) {
        char c[4];

        EFREAD(c, 4, 1, f);
        leaps[i].transition = (time_t)decode(c);

        EFREAD(c, 4, 1, f);
        leaps[i].change = decode(c);
    }

    for (i = 0; i < num_isstd; ++i) {
        int c = getc(f);
        types[i].isstd = c != 0;
    }

    while (i < num_types) {
        types[i++].isstd = 0;
    }

    for (i = 0; i < num_isgmt; ++i) {
        int c = getc(f);

        types[i].isgmt = c != 0;
    }

    while (i < num_types) {
        types[i++].isgmt = 0;
    }

    /* Read all the contents now */

    for (i = 0; i < num_types; i++) {
        /* coverity[tainted_data] */
        types[i].zname = zname_from_stridx(znames, types[i].abbr);
    }

    tz_comp = icalcomponent_new(ICAL_VTIMEZONE_COMPONENT);

    /* Add tzid property */
    size = strlen(icaltimezone_tzid_prefix()) + strlen(location) + 1;
    tzid = (char *)malloc(size);
    if (tzid == NULL) {
        icalerror_set_errno(ICAL_NEWFAILED_ERROR);
        goto error;
    }
    snprintf(tzid, size, "%s%s", icaltimezone_tzid_prefix(), location);
    icalprop = icalproperty_new_tzid(tzid);
    icalcomponent_add_property(tz_comp, icalprop);

    icalprop = icalproperty_new_x(location);
    icalproperty_set_x_name(icalprop, "X-LIC-LOCATION");
    icalcomponent_add_property(tz_comp, icalprop);

    prev_idx = 0;
    if (num_trans == 0) {
        prev_idx = idx = 0;
    } else {
        idx = trans_idx[0];
    }

    for (i = 1; i < num_trans; i++) {
        int by_day;
        int is_new_comp = 0;
        time_t start;
        struct icalrecurrencetype *recur;

        prev_idx = idx;
        idx = trans_idx[i];
        start = transitions[i] + types[prev_idx].gmtoff;

        icaltime = icaltime_from_timet_with_zone(start, 0, NULL);
        pos = calculate_pos(icaltime);
        pos < 0 ? (sign = -1): (sign = 1);
        by_day = sign * ((abs(pos) * 8) + icaltime_day_of_week(icaltime));

        // Figure out if the rule has changed since the previous year
        // If it has, update the recurrence rule of the current component and create a new component
        // If it the current component was only valid for one year then remove the recurrence rule
        if (types[idx].isdst) {
            if (cur_daylight_comp) {
                // Check if the pattern for daylight has changed
                // If it has, create a new component and update UNTIL of previous component's RRULE
                if (daylight_recur.by_month[0] != icaltime.month ||
                        daylight_recur.by_day[0] != by_day ||
                        types[prev_idx].gmtoff != prev_daylight_gmtoff) {
                    // Set UNTIL of the previous component's recurrence
                    icaltime_adjust(&prev_daylight_time, 0, 0, 0, -types[prev_idx].gmtoff);
                    prev_daylight_time.zone = icaltimezone_get_utc_timezone();

                    daylight_recur.until = prev_daylight_time;
                    icalproperty_set_rrule(cur_daylight_rrule_property, daylight_recur);

                    cur_daylight_comp = icalcomponent_new(ICAL_XDAYLIGHT_COMPONENT);
                    is_new_comp = 1;
                }
            } else {
                cur_daylight_comp = icalcomponent_new(ICAL_XDAYLIGHT_COMPONENT);
                is_new_comp = 1;
            }

            comp = cur_daylight_comp;
            recur = &daylight_recur;

            if (icaltime_is_null_time(prev_daylight_time)) {
                prev_prev_daylight_time = icaltime;
            } else {
                prev_prev_daylight_time = prev_daylight_time;
            }

            prev_daylight_time = icaltime;
            prev_daylight_gmtoff = types[prev_idx].gmtoff;
        } else {
            if (cur_standard_comp) {
                // Check if the pattern for standard has changed
                // If it has, create a new component and update UNTIL
                // of the previous component's RRULE
                if (standard_recur.by_month[0] != icaltime.month ||
                        standard_recur.by_day[0] != by_day ||
                        types[prev_idx].gmtoff != prev_standard_gmtoff) {
                    icaltime_adjust(&prev_standard_time, 0, 0, 0, -types[prev_idx].gmtoff);
                    prev_standard_time.zone = icaltimezone_get_utc_timezone();

                    standard_recur.until = prev_standard_time;
                    icalproperty_set_rrule(cur_standard_rrule_property, standard_recur);

                    cur_standard_comp = icalcomponent_new(ICAL_XSTANDARD_COMPONENT);
                    is_new_comp = 1;

                    // Are we transitioning on the daylight date?
                    // If so, that means the time zone is switching off of DST
                    // We need to set UNTIL for the daylight component
                    if (cur_daylight_comp && daylight_recur.by_month[0] == icaltime.month &&
                            daylight_recur.by_day[0] == by_day) {
                        icaltime_adjust(&prev_daylight_time, 0, 0, 0, -types[prev_idx].gmtoff);
                        prev_daylight_time.zone = icaltimezone_get_utc_timezone();

                        daylight_recur.until = prev_daylight_time;
                        icalproperty_set_rrule(cur_daylight_rrule_property, daylight_recur);
                    }
                }
            } else {
                cur_standard_comp = icalcomponent_new(ICAL_XSTANDARD_COMPONENT);
                is_new_comp = 1;
            }

            comp = cur_standard_comp;
            recur = &standard_recur;

            if (icaltime_is_null_time(prev_standard_time)) {
                prev_prev_standard_time = icaltime;
            } else {
                prev_prev_standard_time = prev_standard_time;
            }

            prev_standard_time = icaltime;
            prev_standard_gmtoff = types[prev_idx].gmtoff;
        }

        if (is_new_comp) {
            icalprop = icalproperty_new_tzname(types[idx].zname);
            icalcomponent_add_property(comp, icalprop);
            icalprop = icalproperty_new_dtstart(icaltime);
            icalcomponent_add_property(comp, icalprop);
            icalprop = icalproperty_new_tzoffsetfrom(types[prev_idx].gmtoff);
            icalcomponent_add_property(comp, icalprop);
            icalprop = icalproperty_new_tzoffsetto(types[idx].gmtoff);
            icalcomponent_add_property(comp, icalprop);

            // Determine the recurrence rule for the current set of changes
            icalrecurrencetype_clear(recur);
            recur->freq = ICAL_YEARLY_RECURRENCE;
            recur->by_month[0] = icaltime.month;
            recur->by_day[0] = by_day;
            icalprop = icalproperty_new_rrule(*recur);
            icalcomponent_add_property(comp, icalprop);

            if (types[idx].isdst) {
                cur_daylight_rrule_property = icalprop;
            } else {
                cur_standard_rrule_property = icalprop;
            }

            adjust_dtstart_day_to_rrule(comp, *recur);

            icalcomponent_add_component(tz_comp, comp);
        }
    }

    // Check if the last daylight or standard date was before now
    // If so, set the UNTIL date to the second-to-last transition date
    // and then insert a new component to indicate the time zone doesn't transition anymore
    if (cur_daylight_comp && icaltime_as_timet(prev_daylight_time) < now) {
        icaltime_adjust(&prev_prev_daylight_time, 0, 0, 0, -prev_daylight_gmtoff);
        prev_prev_daylight_time.zone = icaltimezone_get_utc_timezone();

        daylight_recur.until = prev_prev_daylight_time;
        icalproperty_set_rrule(cur_daylight_rrule_property, daylight_recur);

        comp = icalcomponent_new(ICAL_XDAYLIGHT_COMPONENT);
        icalprop = icalproperty_new_tzname(types[idx].zname);
        icalcomponent_add_property(comp, icalprop);
        icalprop = icalproperty_new_dtstart(prev_daylight_time);
        icalcomponent_add_property(comp, icalprop);
        icalprop = icalproperty_new_tzoffsetfrom(types[prev_idx].gmtoff);
        icalcomponent_add_property(comp, icalprop);
        icalprop = icalproperty_new_tzoffsetto(types[idx].gmtoff);
        icalcomponent_add_property(comp, icalprop);
        icalcomponent_add_component(tz_comp, comp);
    }

    if (cur_standard_comp && icaltime_as_timet(prev_standard_time) < now) {
        icaltime_adjust(&prev_prev_standard_time, 0, 0, 0, -prev_standard_gmtoff);
        prev_prev_standard_time.zone = icaltimezone_get_utc_timezone();

        standard_recur.until = prev_prev_standard_time;
        icalproperty_set_rrule(cur_standard_rrule_property, standard_recur);

        comp = icalcomponent_new(ICAL_XSTANDARD_COMPONENT);
        icalprop = icalproperty_new_tzname(types[idx].zname);
        icalcomponent_add_property(comp, icalprop);
        icalprop = icalproperty_new_dtstart(prev_standard_time);
        icalcomponent_add_property(comp, icalprop);
        icalprop = icalproperty_new_tzoffsetfrom(types[prev_idx].gmtoff);
        icalcomponent_add_property(comp, icalprop);
        icalprop = icalproperty_new_tzoffsetto(types[idx].gmtoff);
        icalcomponent_add_property(comp, icalprop);
        icalcomponent_add_component(tz_comp, comp);
    }

    if (num_trans <= 1) {
        time_t start;

        if (num_trans == 1) {
            start = transitions[0] + types[prev_idx].gmtoff;
        } else {
            start = 0;
        }

        // This time zone doesn't transition, insert a single VTIMEZONE component
        if (types[idx].isdst) {
            comp = icalcomponent_new(ICAL_XDAYLIGHT_COMPONENT);
        } else {
            comp = icalcomponent_new(ICAL_XSTANDARD_COMPONENT);
        }

        icalprop = icalproperty_new_tzname(types[idx].zname);
        icalcomponent_add_property(comp, icalprop);
        icaltime = icaltime_from_timet_with_zone(start, 0, NULL);
        icalprop = icalproperty_new_dtstart(icaltime);
        icalcomponent_add_property(comp, icalprop);
        icalprop = icalproperty_new_tzoffsetfrom(types[prev_idx].gmtoff);
        icalcomponent_add_property(comp, icalprop);
        icalprop = icalproperty_new_tzoffsetto(types[idx].gmtoff);
        icalcomponent_add_property(comp, icalprop);
        icalcomponent_add_component(tz_comp, comp);
    }

  error:
    if (f)
        fclose(f);

    if (full_path)
        free(full_path);

    if (transitions)
        free(transitions);

    if (r_trans)
        free(r_trans);

    if (trans_idx)
        free(trans_idx);

    if (types) {
        for (i = 0; i < num_types; i++) {
            if (types[i].zname) {
                free(types[i].zname);
            }
        }
        free(types);
    }

    if (znames)
        free(znames);

    if (leaps)
        free(leaps);

    if (tzid)
        free(tzid);

    return tz_comp;
}
