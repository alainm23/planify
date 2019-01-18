/*======================================================================
 FILE: icalvalue.c
 CREATOR: eric 02 May 1999

 (C) COPYRIGHT 1999, Eric Busboom <eric@softwarestudio.org>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 Contributions from:
   Graham Davison (g.m.davison@computer.org)
======================================================================*/

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "icalderivedvalue.h"
#include "icalvalue.h"
#include "icalvalueimpl.h"
#include "icalerror.h"
#include "icalmemory.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>

struct icalvalue_impl *icalvalue_new_impl(icalvalue_kind kind);

/* This map associates each of the value types with its string
   representation */
struct icalvalue_kind_map
{
    icalvalue_kind kind;
    char name[20];
};

static const struct icalvalue_kind_map value_map[38]={
    {ICAL_ACTION_VALUE,"ACTION"},
    {ICAL_ATTACH_VALUE,"ATTACH"},
    {ICAL_BINARY_VALUE,"BINARY"},
    {ICAL_BOOLEAN_VALUE,"BOOLEAN"},
    {ICAL_BUSYTYPE_VALUE,"BUSYTYPE"},
    {ICAL_CALADDRESS_VALUE,"CAL-ADDRESS"},
    {ICAL_CARLEVEL_VALUE,"CAR-LEVEL"},
    {ICAL_CLASS_VALUE,"CLASS"},
    {ICAL_CMD_VALUE,"CMD"},
    {ICAL_DATE_VALUE,"DATE"},
    {ICAL_DATETIME_VALUE,"DATE-TIME"},
    {ICAL_DATETIMEDATE_VALUE,"DATE-TIME-DATE"},
    {ICAL_DATETIMEPERIOD_VALUE,"DATE-TIME-PERIOD"},
    {ICAL_DURATION_VALUE,"DURATION"},
    {ICAL_FLOAT_VALUE,"FLOAT"},
    {ICAL_GEO_VALUE,"GEO"},
    {ICAL_INTEGER_VALUE,"INTEGER"},
    {ICAL_METHOD_VALUE,"METHOD"},
    {ICAL_PERIOD_VALUE,"PERIOD"},
    {ICAL_POLLCOMPLETION_VALUE,"POLLCOMPLETION"},
    {ICAL_POLLMODE_VALUE,"POLLMODE"},
    {ICAL_QUERY_VALUE,"QUERY"},
    {ICAL_QUERYLEVEL_VALUE,"QUERY-LEVEL"},
    {ICAL_RECUR_VALUE,"RECUR"},
    {ICAL_REQUESTSTATUS_VALUE,"REQUEST-STATUS"},
    {ICAL_STATUS_VALUE,"STATUS"},
    {ICAL_STRING_VALUE,"STRING"},
    {ICAL_TASKMODE_VALUE,"TASKMODE"},
    {ICAL_TEXT_VALUE,"TEXT"},
    {ICAL_TRANSP_VALUE,"TRANSP"},
    {ICAL_TRIGGER_VALUE,"TRIGGER"},
    {ICAL_URI_VALUE,"URI"},
    {ICAL_UTCOFFSET_VALUE,"UTC-OFFSET"},
    {ICAL_X_VALUE,"X"},
    {ICAL_XLICCLASS_VALUE,"X-LIC-CLASS"},
    {ICAL_NO_VALUE,""}
};
icalvalue *icalvalue_new_action(enum icalproperty_action v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_ACTION_VALUE);
    icalvalue_set_action((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_action(icalvalue *value, enum icalproperty_action v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_ACTION_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_action icalvalue_get_action(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_ACTION_NONE;
    }
    icalerror_check_value_type(value, ICAL_ACTION_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_boolean(int v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_BOOLEAN_VALUE);
    icalvalue_set_boolean((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_boolean(icalvalue *value, int v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_BOOLEAN_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_int = v;
    icalvalue_reset_kind(impl);
}

int icalvalue_get_boolean(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return 0;
    }
    icalerror_check_value_type(value, ICAL_BOOLEAN_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_int;
}

icalvalue *icalvalue_new_busytype(enum icalproperty_busytype v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_BUSYTYPE_VALUE);
    icalvalue_set_busytype((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_busytype(icalvalue *value, enum icalproperty_busytype v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_BUSYTYPE_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_busytype icalvalue_get_busytype(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_BUSYTYPE_NONE;
    }
    icalerror_check_value_type(value, ICAL_BUSYTYPE_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_caladdress(const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rz((v != 0), "v");

    impl = icalvalue_new_impl(ICAL_CALADDRESS_VALUE);
    icalvalue_set_caladdress((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_caladdress(icalvalue *value, const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");
    icalerror_check_arg_rv((v != 0), "v");

    icalerror_check_value_type(value, ICAL_CALADDRESS_VALUE);
    impl = (struct icalvalue_impl *)value;
    if (impl->data.v_string != 0) {
        free((void *)impl->data.v_string);
    }

    impl->data.v_string = icalmemory_strdup(v);

    if (impl->data.v_string == 0) {
        errno = ENOMEM;
    }

    icalvalue_reset_kind(impl);
}

const char * icalvalue_get_caladdress(const icalvalue *value)
{
    icalerror_check_arg_rz((value != 0), "value");
    icalerror_check_value_type(value, ICAL_CALADDRESS_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_string;
}

icalvalue *icalvalue_new_carlevel(enum icalproperty_carlevel v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_CARLEVEL_VALUE);
    icalvalue_set_carlevel((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_carlevel(icalvalue *value, enum icalproperty_carlevel v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_CARLEVEL_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_carlevel icalvalue_get_carlevel(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_CARLEVEL_NONE;
    }
    icalerror_check_value_type(value, ICAL_CARLEVEL_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_cmd(enum icalproperty_cmd v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_CMD_VALUE);
    icalvalue_set_cmd((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_cmd(icalvalue *value, enum icalproperty_cmd v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_CMD_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_cmd icalvalue_get_cmd(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_CMD_NONE;
    }
    icalerror_check_value_type(value, ICAL_CMD_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_duration(struct icaldurationtype v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_DURATION_VALUE);
    icalvalue_set_duration((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_duration(icalvalue *value, struct icaldurationtype v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_DURATION_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_duration = v;
    icalvalue_reset_kind(impl);
}

struct icaldurationtype icalvalue_get_duration(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return icaldurationtype_null_duration();
    }
    icalerror_check_value_type(value, ICAL_DURATION_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_duration;
}

icalvalue *icalvalue_new_float(float v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_FLOAT_VALUE);
    icalvalue_set_float((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_float(icalvalue *value, float v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_FLOAT_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_float = v;
    icalvalue_reset_kind(impl);
}

float icalvalue_get_float(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return 0.0;
     }
    icalerror_check_value_type(value, ICAL_FLOAT_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_float;
}

icalvalue *icalvalue_new_integer(int v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_INTEGER_VALUE);
    icalvalue_set_integer((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_integer(icalvalue *value, int v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_INTEGER_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_int = v;
    icalvalue_reset_kind(impl);
}

int icalvalue_get_integer(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return 0;
    }
    icalerror_check_value_type(value, ICAL_INTEGER_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_int;
}

icalvalue *icalvalue_new_method(enum icalproperty_method v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_METHOD_VALUE);
    icalvalue_set_method((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_method(icalvalue *value, enum icalproperty_method v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_METHOD_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_method icalvalue_get_method(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_METHOD_NONE;
    }
    icalerror_check_value_type(value, ICAL_METHOD_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_period(struct icalperiodtype v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_PERIOD_VALUE);
    icalvalue_set_period((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_period(icalvalue *value, struct icalperiodtype v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_PERIOD_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_period = v;
    icalvalue_reset_kind(impl);
}

struct icalperiodtype icalvalue_get_period(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return icalperiodtype_null_period();
    }
    icalerror_check_value_type(value, ICAL_PERIOD_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_period;
}

icalvalue *icalvalue_new_pollcompletion(enum icalproperty_pollcompletion v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_POLLCOMPLETION_VALUE);
    icalvalue_set_pollcompletion((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_pollcompletion(icalvalue *value, enum icalproperty_pollcompletion v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_POLLCOMPLETION_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_pollcompletion icalvalue_get_pollcompletion(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_POLLCOMPLETION_NONE;
    }
    icalerror_check_value_type(value, ICAL_POLLCOMPLETION_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_pollmode(enum icalproperty_pollmode v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_POLLMODE_VALUE);
    icalvalue_set_pollmode((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_pollmode(icalvalue *value, enum icalproperty_pollmode v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_POLLMODE_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_pollmode icalvalue_get_pollmode(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_POLLMODE_NONE;
    }
    icalerror_check_value_type(value, ICAL_POLLMODE_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_query(const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rz((v != 0), "v");

    impl = icalvalue_new_impl(ICAL_QUERY_VALUE);
    icalvalue_set_query((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_query(icalvalue *value, const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");
    icalerror_check_arg_rv((v != 0), "v");

    icalerror_check_value_type(value, ICAL_QUERY_VALUE);
    impl = (struct icalvalue_impl *)value;
    if (impl->data.v_string != 0) {
        free((void *)impl->data.v_string);
    }

    impl->data.v_string = icalmemory_strdup(v);

    if (impl->data.v_string == 0) {
        errno = ENOMEM;
    }

    icalvalue_reset_kind(impl);
}

const char * icalvalue_get_query(const icalvalue *value)
{
    icalerror_check_arg_rz((value != 0), "value");
    icalerror_check_value_type(value, ICAL_QUERY_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_string;
}

icalvalue *icalvalue_new_querylevel(enum icalproperty_querylevel v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_QUERYLEVEL_VALUE);
    icalvalue_set_querylevel((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_querylevel(icalvalue *value, enum icalproperty_querylevel v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_QUERYLEVEL_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_querylevel icalvalue_get_querylevel(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_QUERYLEVEL_NONE;
    }
    icalerror_check_value_type(value, ICAL_QUERYLEVEL_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_requeststatus(struct icalreqstattype v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_REQUESTSTATUS_VALUE);
    icalvalue_set_requeststatus((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_requeststatus(icalvalue *value, struct icalreqstattype v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_REQUESTSTATUS_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_requeststatus = v;
    icalvalue_reset_kind(impl);
}

struct icalreqstattype icalvalue_get_requeststatus(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return icalreqstattype_from_string("0.0");
    }
    icalerror_check_value_type(value, ICAL_REQUESTSTATUS_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_requeststatus;
}

icalvalue *icalvalue_new_status(enum icalproperty_status v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_STATUS_VALUE);
    icalvalue_set_status((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_status(icalvalue *value, enum icalproperty_status v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_STATUS_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_status icalvalue_get_status(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_STATUS_NONE;
    }
    icalerror_check_value_type(value, ICAL_STATUS_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_string(const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rz((v != 0), "v");

    impl = icalvalue_new_impl(ICAL_STRING_VALUE);
    icalvalue_set_string((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_string(icalvalue *value, const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");
    icalerror_check_arg_rv((v != 0), "v");

    icalerror_check_value_type(value, ICAL_STRING_VALUE);
    impl = (struct icalvalue_impl *)value;
    if (impl->data.v_string != 0) {
        free((void *)impl->data.v_string);
    }

    impl->data.v_string = icalmemory_strdup(v);

    if (impl->data.v_string == 0) {
        errno = ENOMEM;
    }

    icalvalue_reset_kind(impl);
}

const char * icalvalue_get_string(const icalvalue *value)
{
    icalerror_check_arg_rz((value != 0), "value");
    icalerror_check_value_type(value, ICAL_STRING_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_string;
}

icalvalue *icalvalue_new_taskmode(enum icalproperty_taskmode v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_TASKMODE_VALUE);
    icalvalue_set_taskmode((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_taskmode(icalvalue *value, enum icalproperty_taskmode v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_TASKMODE_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_taskmode icalvalue_get_taskmode(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_TASKMODE_NONE;
    }
    icalerror_check_value_type(value, ICAL_TASKMODE_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_text(const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rz((v != 0), "v");

    impl = icalvalue_new_impl(ICAL_TEXT_VALUE);
    icalvalue_set_text((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_text(icalvalue *value, const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");
    icalerror_check_arg_rv((v != 0), "v");

    icalerror_check_value_type(value, ICAL_TEXT_VALUE);
    impl = (struct icalvalue_impl *)value;
    if (impl->data.v_string != 0) {
        free((void *)impl->data.v_string);
    }

    impl->data.v_string = icalmemory_strdup(v);

    if (impl->data.v_string == 0) {
        errno = ENOMEM;
    }

    icalvalue_reset_kind(impl);
}

const char * icalvalue_get_text(const icalvalue *value)
{
    icalerror_check_arg_rz((value != 0), "value");
    icalerror_check_value_type(value, ICAL_TEXT_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_string;
}

icalvalue *icalvalue_new_transp(enum icalproperty_transp v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_TRANSP_VALUE);
    icalvalue_set_transp((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_transp(icalvalue *value, enum icalproperty_transp v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_TRANSP_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_transp icalvalue_get_transp(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_TRANSP_NONE;
    }
    icalerror_check_value_type(value, ICAL_TRANSP_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_uri(const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rz((v != 0), "v");

    impl = icalvalue_new_impl(ICAL_URI_VALUE);
    icalvalue_set_uri((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_uri(icalvalue *value, const char * v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");
    icalerror_check_arg_rv((v != 0), "v");

    icalerror_check_value_type(value, ICAL_URI_VALUE);
    impl = (struct icalvalue_impl *)value;
    if (impl->data.v_string != 0) {
        free((void *)impl->data.v_string);
    }

    impl->data.v_string = icalmemory_strdup(v);

    if (impl->data.v_string == 0) {
        errno = ENOMEM;
    }

    icalvalue_reset_kind(impl);
}

const char * icalvalue_get_uri(const icalvalue *value)
{
    icalerror_check_arg_rz((value != 0), "value");
    icalerror_check_value_type(value, ICAL_URI_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_string;
}

icalvalue *icalvalue_new_utcoffset(int v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_UTCOFFSET_VALUE);
    icalvalue_set_utcoffset((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_utcoffset(icalvalue *value, int v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_UTCOFFSET_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_int = v;
    icalvalue_reset_kind(impl);
}

int icalvalue_get_utcoffset(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return 0;
    }
    icalerror_check_value_type(value, ICAL_UTCOFFSET_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_int;
}

icalvalue *icalvalue_new_xlicclass(enum icalproperty_xlicclass v)
{
    struct icalvalue_impl *impl;

    impl = icalvalue_new_impl(ICAL_XLICCLASS_VALUE);
    icalvalue_set_xlicclass((icalvalue *)impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_xlicclass(icalvalue *value, enum icalproperty_xlicclass v)
{
    struct icalvalue_impl *impl;
    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_XLICCLASS_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;
    icalvalue_reset_kind(impl);
}

enum icalproperty_xlicclass icalvalue_get_xlicclass(const icalvalue *value)
{
    icalerror_check_arg((value != 0), "value");
    if (!value) {
        return ICAL_XLICCLASS_NONE;
    }
    icalerror_check_value_type(value, ICAL_XLICCLASS_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

int icalvalue_kind_is_valid(const icalvalue_kind kind)
{
    int i = 0;
    int num_values = (int)(sizeof(value_map) / sizeof(value_map[0]));

    if (kind == ICAL_ANY_VALUE) {
        return 0;
    }

    num_values--;
    do {
        if (value_map[i].kind == kind) {
            return 1;
        }
    } while (i++ < num_values);

    return 0;
}

const char *icalvalue_kind_to_string(const icalvalue_kind kind)
{
    int i, num_values;

    num_values = (int)(sizeof(value_map) / sizeof(value_map[0]));
    for (i = 0; i < num_values; i++) {
        if (value_map[i].kind == kind) {
            return value_map[i].name;
        }
    }

    return 0;
}

icalvalue_kind icalvalue_string_to_kind(const char *str)
{
    int i, num_values;

    if (str == 0) {
        return ICAL_NO_VALUE;
    }

    num_values = (int)(sizeof(value_map) / sizeof(value_map[0]));
    for (i = 0; i < num_values; i++) {
        if (strcasecmp(value_map[i].name, str) == 0) {
            return value_map[i].kind;
        }
    }

    return ICAL_NO_VALUE;
}

icalvalue *icalvalue_new_x(const char *v)
{
    struct icalvalue_impl *impl;

    icalerror_check_arg_rz((v != 0), "v");

    impl = icalvalue_new_impl(ICAL_X_VALUE);

    icalvalue_set_x((icalvalue *) impl, v);
    return (icalvalue *) impl;
}

void icalvalue_set_x(icalvalue *impl, const char *v)
{
    icalerror_check_arg_rv((impl != 0), "value");
    icalerror_check_arg_rv((v != 0), "v");

    if (impl->x_value != 0) {
        free((void *)impl->x_value);
    }

    impl->x_value = icalmemory_strdup(v);

    if (impl->x_value == 0) {
        errno = ENOMEM;
    }
}

const char *icalvalue_get_x(const icalvalue *value)
{
    icalerror_check_arg_rz((value != 0), "value");
    icalerror_check_value_type(value, ICAL_X_VALUE);
    return value->x_value;
}

/* Recur is a special case, so it is not auto generated. */
icalvalue *icalvalue_new_recur(struct icalrecurrencetype v)
{
    struct icalvalue_impl *impl = icalvalue_new_impl(ICAL_RECUR_VALUE);

    icalvalue_set_recur((icalvalue *) impl, v);

    return (icalvalue *) impl;
}

void icalvalue_set_recur(icalvalue *impl, struct icalrecurrencetype v)
{
    icalerror_check_arg_rv((impl != 0), "value");
    icalerror_check_value_type(value, ICAL_RECUR_VALUE);

    if (impl->data.v_recur != 0) {
        free(impl->data.v_recur->rscale);
        free(impl->data.v_recur);
        impl->data.v_recur = 0;
    }

    impl->data.v_recur = malloc(sizeof(struct icalrecurrencetype));

    if (impl->data.v_recur == 0) {
        icalerror_set_errno(ICAL_NEWFAILED_ERROR);
        return;
    } else {
        memcpy(impl->data.v_recur, &v, sizeof(struct icalrecurrencetype));

        if (v.rscale) impl->data.v_recur->rscale = icalmemory_strdup(v.rscale);
    }
}

struct icalrecurrencetype icalvalue_get_recur(const icalvalue *value)
{
    struct icalrecurrencetype rt;

    icalrecurrencetype_clear(&rt);

    icalerror_check_arg_rx((value != 0), "value", rt);
    icalerror_check_value_type(value, ICAL_RECUR_VALUE);

    return *(value->data.v_recur);
}

icalvalue *icalvalue_new_trigger(struct icaltriggertype v)
{
    struct icalvalue_impl *impl = icalvalue_new_impl(ICAL_TRIGGER_VALUE);

    icalvalue_set_trigger((icalvalue *) impl, v);

    return (icalvalue *) impl;
}

void icalvalue_set_trigger(icalvalue *value, struct icaltriggertype v)
{
    icalerror_check_arg_rv((value != 0), "value");

    if (!icaltime_is_null_time(v.time)) {
        value->kind = ICAL_DATETIME_VALUE;
        icalvalue_set_datetime(value, v.time);
    } else {
        value->kind = ICAL_DURATION_VALUE;
        icalvalue_set_duration(value, v.duration);
    }
}

struct icaltriggertype icalvalue_get_trigger(const icalvalue *impl)
{
    struct icaltriggertype tr;

    tr.duration = icaldurationtype_from_int(0);
    tr.time = icaltime_null_time();

    icalerror_check_arg_rx((impl != 0), "value", tr);

    if (impl->kind == ICAL_DATETIME_VALUE) {
        tr.duration = icaldurationtype_from_int(0);
        tr.time = impl->data.v_time;
    } else if (impl->kind == ICAL_DURATION_VALUE) {
        tr.time = icaltime_null_time();
        tr.duration = impl->data.v_duration;
    } else {
        tr.duration = icaldurationtype_from_int(0);
        tr.time = icaltime_null_time();
        icalerror_set_errno(ICAL_BADARG_ERROR);
    }

    return tr;
}

icalvalue *icalvalue_new_date(struct icaltimetype v)
{
    struct icalvalue_impl *impl = icalvalue_new_impl(ICAL_DATE_VALUE);

    icalvalue_set_date((icalvalue *) impl, v);
    return (icalvalue *) impl;
}

void icalvalue_set_date(icalvalue *value, struct icaltimetype v)
{
    icalerror_check_arg_rv((icaltime_is_date(v)), "v");

    icalvalue_set_datetimedate(value, v);
}

struct icaltimetype icalvalue_get_date(const icalvalue *value)
{
    struct icaltimetype dt;

    dt = icaltime_null_date();

    icalerror_check_arg_rx((value != 0), "value", dt);
    icalerror_check_arg_rx((value->kind == ICAL_DATE_VALUE), "value->kind", dt);

    return ((struct icalvalue_impl *)value)->data.v_time;
}

icalvalue *icalvalue_new_datetime(struct icaltimetype v)
{
    struct icalvalue_impl *impl = icalvalue_new_impl(ICAL_DATETIME_VALUE);

    icalvalue_set_datetime((icalvalue *) impl, v);
    return (icalvalue *) impl;
}

void icalvalue_set_datetime(icalvalue *value, struct icaltimetype v)
{
    icalerror_check_arg_rv((!icaltime_is_date(v)), "v");

    icalvalue_set_datetimedate(value, v);
}

struct icaltimetype icalvalue_get_datetime(const icalvalue *value)
{
    /* For backwards compatibility, fetch both DATE and DATE-TIME */
    return icalvalue_get_datetimedate(value);
}

icalvalue *icalvalue_new_datetimedate(struct icaltimetype v)
{
    struct icalvalue_impl *impl = icalvalue_new_impl(ICAL_DATETIME_VALUE);

    icalvalue_set_datetimedate((icalvalue *) impl, v);
    return (icalvalue *) impl;
}

void icalvalue_set_datetimedate(icalvalue *value, struct icaltimetype v)
{
    struct icalvalue_impl *impl;

    if (!icaltime_is_valid_time(v)) {
        icalerror_set_errno(ICAL_BADARG_ERROR);
        return;
    }

    icalerror_check_arg_rv((value != 0), "value");
    icalerror_check_arg_rv(((value->kind == ICAL_DATETIME_VALUE) ||
                            (value->kind == ICAL_DATE_VALUE)),
                           "value->kind");

    impl = (struct icalvalue_impl *)value;
    impl->data.v_time = v;

    icalvalue_reset_kind(impl);
}

struct icaltimetype icalvalue_get_datetimedate(const icalvalue *value)
{
    struct icaltimetype dt;

    dt = icaltime_null_time();

    icalerror_check_arg_rx((value != 0), "value", dt);
    icalerror_check_arg_rx(((value->kind == ICAL_DATETIME_VALUE) ||
                            (value->kind == ICAL_DATE_VALUE)),
                           "value->kind", dt);

    return ((struct icalvalue_impl *)value)->data.v_time;
}

/* DATE-TIME-PERIOD is a special case, and is not auto generated */

icalvalue *icalvalue_new_datetimeperiod(struct icaldatetimeperiodtype v)
{
    struct icalvalue_impl *impl = icalvalue_new_impl(ICAL_DATETIMEPERIOD_VALUE);

    icalvalue_set_datetimeperiod(impl, v);

    return (icalvalue *) impl;
}

void icalvalue_set_datetimeperiod(icalvalue *impl, struct icaldatetimeperiodtype v)
{
    icalerror_check_arg_rv((impl != 0), "value");

    icalerror_check_value_type(value, ICAL_DATETIMEPERIOD_VALUE);

    if (!icaltime_is_null_time(v.time)) {
        impl->kind = ICAL_DATETIME_VALUE;
        icalvalue_set_datetimedate(impl, v.time);
    } else if (!icalperiodtype_is_null_period(v.period)) {
        if (!icalperiodtype_is_valid_period(v.period)) {
            icalerror_set_errno(ICAL_BADARG_ERROR);
            return;
        }
        impl->kind = ICAL_PERIOD_VALUE;
        icalvalue_set_period(impl, v.period);
    } else {
        icalerror_set_errno(ICAL_BADARG_ERROR);
    }
}

struct icaldatetimeperiodtype icalvalue_get_datetimeperiod(const icalvalue *impl)
{
    struct icaldatetimeperiodtype dtp;

    dtp.period = icalperiodtype_null_period();
    dtp.time = icaltime_null_time();

    icalerror_check_arg_rx((impl != 0), "value", dtp);
    icalerror_check_value_type(value, ICAL_DATETIMEPERIOD_VALUE);

    if (impl->kind == ICAL_DATETIME_VALUE || impl->kind == ICAL_DATE_VALUE) {
        dtp.period = icalperiodtype_null_period();
        dtp.time = impl->data.v_time;
    } else if (impl->kind == ICAL_PERIOD_VALUE) {
        dtp.period = impl->data.v_period;
        dtp.time = icaltime_null_time();
    } else {
        dtp.period = icalperiodtype_null_period();
        dtp.time = icaltime_null_time();
        icalerror_set_errno(ICAL_BADARG_ERROR);
    }

    return dtp;
}

icalvalue *icalvalue_new_class(enum icalproperty_class v)
{
    struct icalvalue_impl *impl = icalvalue_new_impl(ICAL_CLASS_VALUE);

    icalvalue_set_class((icalvalue *) impl, v);
    return (icalvalue *) impl;
}

void icalvalue_set_class(icalvalue *value, enum icalproperty_class v)
{
    struct icalvalue_impl *impl;

    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_CLASS_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_enum = v;

    icalvalue_reset_kind(impl);
}

enum icalproperty_class icalvalue_get_class(const icalvalue *value)
{
    icalproperty_class pr;

    pr = ICAL_CLASS_NONE;

    icalerror_check_arg_rx((value != NULL), "value", pr);
    icalerror_check_arg((value != 0), "value");
    icalerror_check_value_type(value, ICAL_CLASS_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_enum;
}

icalvalue *icalvalue_new_geo(struct icalgeotype v)
{
    struct icalvalue_impl *impl = icalvalue_new_impl(ICAL_GEO_VALUE);

    icalvalue_set_geo((icalvalue *) impl, v);
    return (icalvalue *) impl;
}

void icalvalue_set_geo(icalvalue *value, struct icalgeotype v)
{
    struct icalvalue_impl *impl;

    icalerror_check_arg_rv((value != 0), "value");

    icalerror_check_value_type(value, ICAL_GEO_VALUE);
    impl = (struct icalvalue_impl *)value;

    impl->data.v_geo = v;

    icalvalue_reset_kind(impl);
}

struct icalgeotype icalvalue_get_geo(const icalvalue *value)
{
    struct icalgeotype gt;

    gt.lat = 255.0;
    gt.lon = 255.0;

    icalerror_check_arg_rx((value != 0), "value", gt);
    icalerror_check_value_type(value, ICAL_GEO_VALUE);
    return ((struct icalvalue_impl *)value)->data.v_geo;
}

icalvalue *icalvalue_new_attach(icalattach *attach)
{
    struct icalvalue_impl *impl;

    icalerror_check_arg_rz((attach != NULL), "attach");

    impl = icalvalue_new_impl(ICAL_ATTACH_VALUE);
    if (!impl) {
        errno = ENOMEM;
        return NULL;
    }

    icalvalue_set_attach((icalvalue *) impl, attach);
    return (icalvalue *) impl;
}

void icalvalue_set_attach(icalvalue *value, icalattach *attach)
{
    struct icalvalue_impl *impl;

    icalerror_check_arg_rv((value != NULL), "value");
    icalerror_check_value_type(value, ICAL_ATTACH_VALUE);
    icalerror_check_arg_rv((attach != NULL), "attach");

    impl = (struct icalvalue_impl *)value;

    icalattach_ref(attach);

    if (impl->data.v_attach)
        icalattach_unref(impl->data.v_attach);

    impl->data.v_attach = attach;
}

icalattach *icalvalue_get_attach(const icalvalue *value)
{
    icalerror_check_arg_rz((value != NULL), "value");
    icalerror_check_value_type(value, ICAL_ATTACH_VALUE);

    return value->data.v_attach;
}

icalvalue *icalvalue_new_binary(const char * v)
{
    struct icalvalue_impl *impl;

    icalerror_check_arg_rz((v != NULL), "v");

    impl = icalvalue_new_impl(ICAL_BINARY_VALUE);
    if (!impl) {
        errno = ENOMEM;
        return NULL;
    }

    icalvalue_set_binary((icalvalue *) impl, v);
    return (icalvalue*)impl;
}

void icalvalue_set_binary(icalvalue *value, const char * v)
{
    struct icalvalue_impl *impl;

    icalerror_check_arg_rv((value != NULL), "value");
    icalerror_check_value_type(value, ICAL_BINARY_VALUE);
    icalerror_check_arg_rv((v != NULL), "v");

    impl = (struct icalvalue_impl *)value;

    if (impl->data.v_attach)
        icalattach_unref(impl->data.v_attach);

    impl->data.v_attach = icalattach_new_from_data(v, NULL, 0);
}

const char *icalvalue_get_binary(const icalvalue *value)
{
    icalerror_check_arg_rz((value != 0), "value");
    icalerror_check_value_type(value, ICAL_BINARY_VALUE);
    return (const char *) icalattach_get_data(value->data.v_attach);
}

/* The remaining interfaces are 'new', 'set' and 'get' for each of the value
   types */

/* Everything below this line is machine generated. Do not edit. */
