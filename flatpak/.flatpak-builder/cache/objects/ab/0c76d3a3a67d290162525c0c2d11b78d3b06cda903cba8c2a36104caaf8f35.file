/*======================================================================
 FILE: icalvalue.h
 CREATOR: eric 20 March 1999

 (C) COPYRIGHT 1999, Eric Busboom  <eric@softwarestudio.org>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

#ifndef ICALDERIVEDVALUE_H
#define ICALDERIVEDVALUE_H

#include "libical_ical_export.h"
#include "icalattach.h"
#include "icalrecur.h"
#include "icaltypes.h"

typedef struct icalvalue_impl icalvalue;

LIBICAL_ICAL_EXPORT void icalvalue_set_x(icalvalue *value, const char *v);
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_x(const char *v);
LIBICAL_ICAL_EXPORT const char *icalvalue_get_x(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_recur(struct icalrecurrencetype v);
LIBICAL_ICAL_EXPORT void icalvalue_set_recur(icalvalue *value, struct icalrecurrencetype v);
LIBICAL_ICAL_EXPORT struct icalrecurrencetype icalvalue_get_recur(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_trigger(struct icaltriggertype v);
LIBICAL_ICAL_EXPORT void icalvalue_set_trigger(icalvalue *value, struct icaltriggertype v);
LIBICAL_ICAL_EXPORT struct icaltriggertype icalvalue_get_trigger(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_date(struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalvalue_get_date(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_date(icalvalue *value, struct icaltimetype v);

/**
 * Creates a new icalvalue representing the specified icaltimetype.
 * @param v is an @p icaltimetype
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_datetime(struct icaltimetype v);

/**
 * Returns the icaltimetype corresponding to the specified icalvalue.
 * @param a pointer to an icalvalue.
 * @returns the icaltimetype as datetime.
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT struct icaltimetype icalvalue_get_datetime(const icalvalue *value);

/**
 * Sets an icalvalue for the specified icaltimetype.
 * @param value is a pointer to an icalvalue.
 * @param v is
 * @since 3.0
 */
LIBICAL_ICAL_EXPORT void icalvalue_set_datetime(icalvalue *value, struct icaltimetype v);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_datetimedate(struct icaltimetype v);
LIBICAL_ICAL_EXPORT struct icaltimetype icalvalue_get_datetimedate(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_datetimedate(icalvalue *value, struct icaltimetype v);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_datetimeperiod(struct icaldatetimeperiodtype v);
LIBICAL_ICAL_EXPORT void icalvalue_set_datetimeperiod(icalvalue *value,
                                                      struct icaldatetimeperiodtype v);
LIBICAL_ICAL_EXPORT struct icaldatetimeperiodtype icalvalue_get_datetimeperiod(const icalvalue *
                                                                               value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_geo(struct icalgeotype v);
LIBICAL_ICAL_EXPORT struct icalgeotype icalvalue_get_geo(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_geo(icalvalue *value, struct icalgeotype v);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_attach(icalattach *attach);
LIBICAL_ICAL_EXPORT void icalvalue_set_attach(icalvalue *value, icalattach *attach);
LIBICAL_ICAL_EXPORT icalattach *icalvalue_get_attach(const icalvalue *value);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_binary(const char *v);
LIBICAL_ICAL_EXPORT void icalvalue_set_binary(icalvalue *value, const char *v);
LIBICAL_ICAL_EXPORT const char *icalvalue_get_binary(const icalvalue *value);

LIBICAL_ICAL_EXPORT void icalvalue_reset_kind(icalvalue *value);

typedef enum icalvalue_kind {
   ICAL_ANY_VALUE=5000,
    ICAL_ACTION_VALUE=5027,
    ICAL_ATTACH_VALUE=5003,
    ICAL_BINARY_VALUE=5011,
    ICAL_BOOLEAN_VALUE=5021,
    ICAL_BUSYTYPE_VALUE=5032,
    ICAL_CALADDRESS_VALUE=5023,
    ICAL_CARLEVEL_VALUE=5016,
    ICAL_CLASS_VALUE=5019,
    ICAL_CMD_VALUE=5010,
    ICAL_DATE_VALUE=5002,
    ICAL_DATETIME_VALUE=5028,
    ICAL_DATETIMEDATE_VALUE=5036,
    ICAL_DATETIMEPERIOD_VALUE=5015,
    ICAL_DURATION_VALUE=5020,
    ICAL_FLOAT_VALUE=5013,
    ICAL_GEO_VALUE=5004,
    ICAL_INTEGER_VALUE=5017,
    ICAL_METHOD_VALUE=5030,
    ICAL_PERIOD_VALUE=5014,
    ICAL_POLLCOMPLETION_VALUE=5034,
    ICAL_POLLMODE_VALUE=5033,
    ICAL_QUERY_VALUE=5001,
    ICAL_QUERYLEVEL_VALUE=5012,
    ICAL_RECUR_VALUE=5026,
    ICAL_REQUESTSTATUS_VALUE=5009,
    ICAL_STATUS_VALUE=5005,
    ICAL_STRING_VALUE=5007,
    ICAL_TASKMODE_VALUE=5035,
    ICAL_TEXT_VALUE=5008,
    ICAL_TRANSP_VALUE=5006,
    ICAL_TRIGGER_VALUE=5024,
    ICAL_URI_VALUE=5018,
    ICAL_UTCOFFSET_VALUE=5029,
    ICAL_X_VALUE=5022,
    ICAL_XLICCLASS_VALUE=5025,
   ICAL_NO_VALUE=5031
} icalvalue_kind ;

#define ICALPROPERTY_FIRST_ENUM 10000

typedef enum icalproperty_action {
    ICAL_ACTION_X = 10000,
    ICAL_ACTION_AUDIO = 10001,
    ICAL_ACTION_DISPLAY = 10002,
    ICAL_ACTION_EMAIL = 10003,
    ICAL_ACTION_PROCEDURE = 10004,
    ICAL_ACTION_NONE = 10099
} icalproperty_action;

typedef enum icalproperty_busytype {
    ICAL_BUSYTYPE_X = 10100,
    ICAL_BUSYTYPE_BUSY = 10101,
    ICAL_BUSYTYPE_BUSYUNAVAILABLE = 10102,
    ICAL_BUSYTYPE_BUSYTENTATIVE = 10103,
    ICAL_BUSYTYPE_NONE = 10199
} icalproperty_busytype;

typedef enum icalproperty_carlevel {
    ICAL_CARLEVEL_X = 10200,
    ICAL_CARLEVEL_CARNONE = 10201,
    ICAL_CARLEVEL_CARMIN = 10202,
    ICAL_CARLEVEL_CARFULL1 = 10203,
    ICAL_CARLEVEL_NONE = 10299
} icalproperty_carlevel;

typedef enum icalproperty_class {
    ICAL_CLASS_X = 10300,
    ICAL_CLASS_PUBLIC = 10301,
    ICAL_CLASS_PRIVATE = 10302,
    ICAL_CLASS_CONFIDENTIAL = 10303,
    ICAL_CLASS_NONE = 10399
} icalproperty_class;

typedef enum icalproperty_cmd {
    ICAL_CMD_X = 10400,
    ICAL_CMD_ABORT = 10401,
    ICAL_CMD_CONTINUE = 10402,
    ICAL_CMD_CREATE = 10403,
    ICAL_CMD_DELETE = 10404,
    ICAL_CMD_GENERATEUID = 10405,
    ICAL_CMD_GETCAPABILITY = 10406,
    ICAL_CMD_IDENTIFY = 10407,
    ICAL_CMD_MODIFY = 10408,
    ICAL_CMD_MOVE = 10409,
    ICAL_CMD_REPLY = 10410,
    ICAL_CMD_SEARCH = 10411,
    ICAL_CMD_SETLOCALE = 10412,
    ICAL_CMD_NONE = 10499
} icalproperty_cmd;

typedef enum icalproperty_method {
    ICAL_METHOD_X = 10500,
    ICAL_METHOD_PUBLISH = 10501,
    ICAL_METHOD_REQUEST = 10502,
    ICAL_METHOD_REPLY = 10503,
    ICAL_METHOD_ADD = 10504,
    ICAL_METHOD_CANCEL = 10505,
    ICAL_METHOD_REFRESH = 10506,
    ICAL_METHOD_COUNTER = 10507,
    ICAL_METHOD_DECLINECOUNTER = 10508,
    ICAL_METHOD_CREATE = 10509,
    ICAL_METHOD_READ = 10510,
    ICAL_METHOD_RESPONSE = 10511,
    ICAL_METHOD_MOVE = 10512,
    ICAL_METHOD_MODIFY = 10513,
    ICAL_METHOD_GENERATEUID = 10514,
    ICAL_METHOD_DELETE = 10515,
    ICAL_METHOD_POLLSTATUS = 10516,
    ICAL_METHOD_NONE = 10599
} icalproperty_method;

typedef enum icalproperty_pollcompletion {
    ICAL_POLLCOMPLETION_X = 10600,
    ICAL_POLLCOMPLETION_SERVER = 10601,
    ICAL_POLLCOMPLETION_SERVERSUBMIT = 10602,
    ICAL_POLLCOMPLETION_SERVERCHOICE = 10603,
    ICAL_POLLCOMPLETION_CLIENT = 10604,
    ICAL_POLLCOMPLETION_NONE = 10699
} icalproperty_pollcompletion;

typedef enum icalproperty_pollmode {
    ICAL_POLLMODE_X = 10700,
    ICAL_POLLMODE_BASIC = 10701,
    ICAL_POLLMODE_NONE = 10799
} icalproperty_pollmode;

typedef enum icalproperty_querylevel {
    ICAL_QUERYLEVEL_X = 10800,
    ICAL_QUERYLEVEL_CALQL1 = 10801,
    ICAL_QUERYLEVEL_CALQLNONE = 10802,
    ICAL_QUERYLEVEL_NONE = 10899
} icalproperty_querylevel;

typedef enum icalproperty_status {
    ICAL_STATUS_X = 10900,
    ICAL_STATUS_TENTATIVE = 10901,
    ICAL_STATUS_CONFIRMED = 10902,
    ICAL_STATUS_COMPLETED = 10903,
    ICAL_STATUS_NEEDSACTION = 10904,
    ICAL_STATUS_CANCELLED = 10905,
    ICAL_STATUS_INPROCESS = 10906,
    ICAL_STATUS_DRAFT = 10907,
    ICAL_STATUS_FINAL = 10908,
    ICAL_STATUS_SUBMITTED = 10909,
    ICAL_STATUS_PENDING = 10910,
    ICAL_STATUS_FAILED = 10911,
    ICAL_STATUS_DELETED = 10912,
    ICAL_STATUS_NONE = 10999
} icalproperty_status;

typedef enum icalproperty_taskmode {
    ICAL_TASKMODE_X = 11200,
    ICAL_TASKMODE_AUTOMATICCOMPLETION = 11201,
    ICAL_TASKMODE_AUTOMATICFAILURE = 11202,
    ICAL_TASKMODE_AUTOMATICSTATUS = 11203,
    ICAL_TASKMODE_NONE = 11299
} icalproperty_taskmode;

typedef enum icalproperty_transp {
    ICAL_TRANSP_X = 11000,
    ICAL_TRANSP_OPAQUE = 11001,
    ICAL_TRANSP_OPAQUENOCONFLICT = 11002,
    ICAL_TRANSP_TRANSPARENT = 11003,
    ICAL_TRANSP_TRANSPARENTNOCONFLICT = 11004,
    ICAL_TRANSP_NONE = 11099
} icalproperty_transp;

typedef enum icalproperty_xlicclass {
    ICAL_XLICCLASS_X = 11100,
    ICAL_XLICCLASS_PUBLISHNEW = 11101,
    ICAL_XLICCLASS_PUBLISHUPDATE = 11102,
    ICAL_XLICCLASS_PUBLISHFREEBUSY = 11103,
    ICAL_XLICCLASS_REQUESTNEW = 11104,
    ICAL_XLICCLASS_REQUESTUPDATE = 11105,
    ICAL_XLICCLASS_REQUESTRESCHEDULE = 11106,
    ICAL_XLICCLASS_REQUESTDELEGATE = 11107,
    ICAL_XLICCLASS_REQUESTNEWORGANIZER = 11108,
    ICAL_XLICCLASS_REQUESTFORWARD = 11109,
    ICAL_XLICCLASS_REQUESTSTATUS = 11110,
    ICAL_XLICCLASS_REQUESTFREEBUSY = 11111,
    ICAL_XLICCLASS_REPLYACCEPT = 11112,
    ICAL_XLICCLASS_REPLYDECLINE = 11113,
    ICAL_XLICCLASS_REPLYDELEGATE = 11114,
    ICAL_XLICCLASS_REPLYCRASHERACCEPT = 11115,
    ICAL_XLICCLASS_REPLYCRASHERDECLINE = 11116,
    ICAL_XLICCLASS_ADDINSTANCE = 11117,
    ICAL_XLICCLASS_CANCELEVENT = 11118,
    ICAL_XLICCLASS_CANCELINSTANCE = 11119,
    ICAL_XLICCLASS_CANCELALL = 11120,
    ICAL_XLICCLASS_REFRESH = 11121,
    ICAL_XLICCLASS_COUNTER = 11122,
    ICAL_XLICCLASS_DECLINECOUNTER = 11123,
    ICAL_XLICCLASS_MALFORMED = 11124,
    ICAL_XLICCLASS_OBSOLETE = 11125,
    ICAL_XLICCLASS_MISSEQUENCED = 11126,
    ICAL_XLICCLASS_UNKNOWN = 11127,
    ICAL_XLICCLASS_NONE = 11199
} icalproperty_xlicclass;

#define ICALPROPERTY_LAST_ENUM 11300

/* ACTION */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_action(enum icalproperty_action v);
LIBICAL_ICAL_EXPORT enum icalproperty_action icalvalue_get_action(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_action(icalvalue *value, enum icalproperty_action v);

/* BOOLEAN */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_boolean(int v);
LIBICAL_ICAL_EXPORT int icalvalue_get_boolean(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_boolean(icalvalue *value, int v);

/* BUSYTYPE */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_busytype(enum icalproperty_busytype v);
LIBICAL_ICAL_EXPORT enum icalproperty_busytype icalvalue_get_busytype(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_busytype(icalvalue *value, enum icalproperty_busytype v);

/* CAL-ADDRESS */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_caladdress(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_caladdress(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_caladdress(icalvalue *value, const char * v);

/* CAR-LEVEL */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_carlevel(enum icalproperty_carlevel v);
LIBICAL_ICAL_EXPORT enum icalproperty_carlevel icalvalue_get_carlevel(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_carlevel(icalvalue *value, enum icalproperty_carlevel v);

/* CMD */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_cmd(enum icalproperty_cmd v);
LIBICAL_ICAL_EXPORT enum icalproperty_cmd icalvalue_get_cmd(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_cmd(icalvalue *value, enum icalproperty_cmd v);

/* DURATION */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_duration(struct icaldurationtype v);
LIBICAL_ICAL_EXPORT struct icaldurationtype icalvalue_get_duration(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_duration(icalvalue *value, struct icaldurationtype v);

/* FLOAT */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_float(float v);
LIBICAL_ICAL_EXPORT float icalvalue_get_float(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_float(icalvalue *value, float v);

/* INTEGER */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_integer(int v);
LIBICAL_ICAL_EXPORT int icalvalue_get_integer(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_integer(icalvalue *value, int v);

/* METHOD */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_method(enum icalproperty_method v);
LIBICAL_ICAL_EXPORT enum icalproperty_method icalvalue_get_method(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_method(icalvalue *value, enum icalproperty_method v);

/* PERIOD */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_period(struct icalperiodtype v);
LIBICAL_ICAL_EXPORT struct icalperiodtype icalvalue_get_period(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_period(icalvalue *value, struct icalperiodtype v);

/* POLLCOMPLETION */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_pollcompletion(enum icalproperty_pollcompletion v);
LIBICAL_ICAL_EXPORT enum icalproperty_pollcompletion icalvalue_get_pollcompletion(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_pollcompletion(icalvalue *value, enum icalproperty_pollcompletion v);

/* POLLMODE */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_pollmode(enum icalproperty_pollmode v);
LIBICAL_ICAL_EXPORT enum icalproperty_pollmode icalvalue_get_pollmode(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_pollmode(icalvalue *value, enum icalproperty_pollmode v);

/* QUERY */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_query(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_query(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_query(icalvalue *value, const char * v);

/* QUERY-LEVEL */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_querylevel(enum icalproperty_querylevel v);
LIBICAL_ICAL_EXPORT enum icalproperty_querylevel icalvalue_get_querylevel(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_querylevel(icalvalue *value, enum icalproperty_querylevel v);

/* REQUEST-STATUS */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_requeststatus(struct icalreqstattype v);
LIBICAL_ICAL_EXPORT struct icalreqstattype icalvalue_get_requeststatus(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_requeststatus(icalvalue *value, struct icalreqstattype v);

/* STATUS */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_status(enum icalproperty_status v);
LIBICAL_ICAL_EXPORT enum icalproperty_status icalvalue_get_status(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_status(icalvalue *value, enum icalproperty_status v);

/* STRING */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_string(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_string(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_string(icalvalue *value, const char * v);

/* TASKMODE */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_taskmode(enum icalproperty_taskmode v);
LIBICAL_ICAL_EXPORT enum icalproperty_taskmode icalvalue_get_taskmode(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_taskmode(icalvalue *value, enum icalproperty_taskmode v);

/* TEXT */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_text(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_text(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_text(icalvalue *value, const char * v);

/* TRANSP */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_transp(enum icalproperty_transp v);
LIBICAL_ICAL_EXPORT enum icalproperty_transp icalvalue_get_transp(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_transp(icalvalue *value, enum icalproperty_transp v);

/* URI */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_uri(const char * v);
LIBICAL_ICAL_EXPORT const char * icalvalue_get_uri(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_uri(icalvalue *value, const char * v);

/* UTC-OFFSET */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_utcoffset(int v);
LIBICAL_ICAL_EXPORT int icalvalue_get_utcoffset(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_utcoffset(icalvalue *value, int v);

/* X-LIC-CLASS */
LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_xlicclass(enum icalproperty_xlicclass v);
LIBICAL_ICAL_EXPORT enum icalproperty_xlicclass icalvalue_get_xlicclass(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_xlicclass(icalvalue *value, enum icalproperty_xlicclass v);

LIBICAL_ICAL_EXPORT icalvalue *icalvalue_new_class(enum icalproperty_class v);
LIBICAL_ICAL_EXPORT enum icalproperty_class icalvalue_get_class(const icalvalue *value);
LIBICAL_ICAL_EXPORT void icalvalue_set_class(icalvalue *value, enum icalproperty_class v);
#endif /*ICALVALUE_H*/
