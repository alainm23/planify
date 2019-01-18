/*======================================================================
  FILE: icalparam.h
  CREATOR: eric 20 March 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

/**
 * @file icalparameter.h
 *
 * Functions to work with ical parameter objects, which represent
 * parameters to property objects.
 */

#ifndef ICALPARAMETER_H
#define ICALPARAMETER_H

#include "libical_ical_export.h"
#include "icalderivedparameter.h"

/* Declared in icalderivedparameter.h */
/*typedef struct icalparameter_impl icalparameter;*/

/**
 * @brief Creates new ::icalparameter object.
 * @param kind The kind of ::icalparameter to create.
 * @return An ::icalparameter with the given kind.
 *
 * @par Error handling
 * If there was an internal error regarding
 * memory allocation, it returns `NULL` and sets
 * ::icalerrno to ::ICAL_NEWFAILED_ERROR.
 *
 * @par Ownership
 * Objects created by this method are owned by the caller and
 * must be released with the icalparameter_free() method.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *parameter = icalparameter_new();
 *
 * if(parameter) {
 *     // use parameter ...
 * }
 *
 * // release parameter
 * icalparameter_free(parameter);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter *icalparameter_new(icalparameter_kind kind);

/**
 * @brief Creates new ::icalparameter as a clone of the given one.
 * @param p The existing, non-`NULL` parameter to clone.
 * @return An ::icalparameter that is a clone of the given one.
 *
 * @par Error handling
 * If @a p is `NULL`, it returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR.
 * If there was an internal error cloning the data, it returns `NULL`
 * without reporting any error in ::icalerrno.
 *
 * @par Ownership
 * Objects created by this method are owned by the caller and
 * must be released with the icalparameter_free() method.
 *
 * ### Usage
 * ```x
 * // create an icalparameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * // clone the parameter
 * icalparameter *clone = icalparameter_new_clone(param);
 *
 * if(clone) {
 *     // use clone ...
 * }
 *
 * // release parameters
 * icalparameter_free(param);
 * icalparameter_free(clone);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter *icalparameter_new_clone(icalparameter *p);

/**
 * @brief Create ::icalparameter object from string
 * @param value The string from which to create the ::icalparameter, in the form `"PARAMNAME=VALUE"`
 * @return An ::icalparameter that corresponds to the given string.
 *
 * @par Error handling
 * If there was an internal error copying data, it returns `NULL` and sets
 * ::icalerrno to ::ICAL_NEWFAILED_ERROR. If @a value was `NULL`, it returns
 * `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR. If @a value was malformed,
 * it returns `NULL` and sets ::icalerrno to ::ICAL_MALFORMEDDATA_ERROR.
 *
 * @par Ownership
 * Objects created by this method are owned by the caller and
 * must be released with the icalparameter_free() method.
 *
 * ### Usage
 * ```c
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * if(param) {
 *     // use param ...
 * }
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter *icalparameter_new_from_string(const char *value);

/**
 * @brief Create ::icalparameter of a given @a kind with a given @a value
 * @param kind The kind of ::icalparameter to create
 * @param value The value of the parameter
 * @return An ::icalparameter with the given kind and value.
 *
 * @par Error handling
 * If value is `NULL`, it returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * @par Ownership
 * Objects created by this method are owned by the caller and
 * must be released with the icalparameter_free() method.
 *
 * ### Example
 * ```c
 * // create new parameter
 * icalparameter *param;
 * param = icalparameter_new_from_value_string(ICAL_ROLE_PARAMETER, "CHAIR");
 *
 * // check parameter
 * assert(0 == strcmp(icalparameter_get_iana_name(param), "ROLE"));
 * assert(0 == strcmp(icalparameter_get_iana_value(param), "CHAIR"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter *icalparameter_new_from_value_string(icalparameter_kind kind,
                                                                       const char *value);

/**
 * @brief Frees an ::icalparameter object.
 * @param parameter The icalparameter to free
 *
 * This method needs to be used on all parameter objects returned
 * from any of the `_new()` methods including icalparameter_new(), icalparameter_new_clone(),
 * icalparameter_new_from_string() and icalparameter_new_from_value_string(),
 * when they are not needed anymore and to be released.
 *
 * ### Usage
 * ```c
 * icalparameter *param = icalparameter_new();
 *
 * if(param) {
 *     // use param...
 * }
 *
 * // after use, release it
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_free(icalparameter *parameter);

/**
 * @brief Convert ::icalparameter into an string representation
 * @param parameter The ::icalparameter to convert
 * @return A string representing the parameter according to RFC5445/RFC6868.
 * @sa icalparameter_as_ical_string_r()
 *
 * @par Error handling
 * If there is any error, the method returns `NULL`. Furthermore,
 * if @a parameter is `NULL`, it also sets ::icalerrno to ::ICAL_BADARG_ERROR.
 * If it doesn't recognize the kind of the parameter, it sets ::icalerrno
 * it ::ICAL_BADARG_ERROR. If the parameter is otherwise malformed, it
 * sets ::icalerrno to ::ICAL_MALFORMEDDATA_ERROR.
 *
 * @par Ownership
 * Strings returned by this method are owned by libical, they must
 * not be freed and they may be reclaimed with the next call into
 * the library. A version of this function, which returns strings
 * that are not owned by libical, is icalparameter_as_ical_string_r().
 *
 * ### Usage
 * ```c
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * if(param) {
 *     printf("%s\n", icalparameter_as_ical_string(param));
 * }
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT char *icalparameter_as_ical_string(icalparameter *parameter);

/**
 * @brief Convert ::icalparameter into an string representation
 * @param parameter The ::icalparameter to convert
 * @return A string representing the parameter according to RFC5445/RFC6868.
 * @sa icalparameter_as_ical_string()
 *
 * @par Error handling
 * If there is any error, the method returns `NULL`. Furthermore,
 * if parameter is `NULL`, it also sets ::icalerrno to ::ICAL_BADARG_ERROR.
 * If it doesn't recognize the kind of the parameter, it sets ::icalerrno
 * to ::ICAL_BADARG_ERROR. If the parameter is otherwise malformed, it
 * sets ::icalerrno to ::ICAL_MALFORMEDDATA_ERROR.
 *
 * @par Ownership
 * Strings returned by this method are owned by the caller, thus they need
 * to be manually `free()`d after use. A version of this function which returns
 * strings that do not need to be freed manually is
 * icalparameter_as_ical_string().
 *
 * ### Usage
 * ```c
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * if(param) {
 *     char *str = icalparameter_as_ical_string(param);
 *     printf("%s\n", str);
 *     free(str);
 * }
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT char *icalparameter_as_ical_string_r(icalparameter *parameter);

/**
 * Returns the icalparameter_kind of parameter.
 *
 * @param parameter The icalparameter whose kind to determine
 * @return The icalparameter_kind of the parameter
 *
 * @b Error handling
 * Returns ICAL_NO_PARAMETER when passed NULL.
 *
 * @b Usage
 * @code
 * // create parameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * // check what type of parameter this is
 * assert(icalparameter_isa(param) == ICAL_ROLE_PARAMETER);
 *
 * // release memory
 * icalparameter_free(param);
 * @endcode
 */
LIBICAL_ICAL_EXPORT icalparameter_kind icalparameter_isa(icalparameter *parameter);

/**
 * Determine if the given param is an icalparameter
 * @param param The libical-originated object to check
 * @return 1 if the object is an icalparameter, 0 otherwise.
 * @note This function expects to be given an object originating from
 *  libical - if this function is passed anything that is not from
 *  libical, it's behavior is undefined.
 *
 * @b Error handling
 * When given a `NULL` object, it returns 0.
 *
 * @b Usage
 * ```c
 * // create parameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=CHAIR");
 *
 * // check if it's a parameter
 * assert(icalparameter_isa_parameter(param));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalparameter_isa_parameter(void *param);

/* Access the name of an X parameter */

/**
 * @brief Sets the X-name of @a param to @a v
 * @param param The ::icalparameter to change
 * @param v The X-name to set @a param to
 * @sa icalparameter_get_xname()
 *
 * @par Error handling
 * If either @a param or @a v are `NULL`, it sets ::icalerrno to ::ICAL_BARARG_ERROR.
 * If there is an error acquiring memory, it sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The passed string @a v stays in the ownership of the caller - libical
 * creates a copy of it.
 *
 * ### Usage
 * ```c
 * // creates new parameter
 * icalparameter *param = icalparameter_new();
 *
 * // sets xname
 * icalparameter_set_xname(param, "X-TEST");
 *
 * // compare xname
 * assert(0 == strcmp(icalparameter_get_xname(param), "X-TEST"));
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_xname(icalparameter *param, const char *v);

/**
 * @brief Returns the X-name of @a param
 * @param param The ::icalparameter whose X-name is to be returned
 * @return A string representing the X-name of @a param
 * @sa icalparameter_set_xname()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR when a `NULL`
 * is passed instead of an ::icalparameter.
 *
 * @par Ownership
 * The string that is returned stays owned by libical and must not
 * be freed by the caller.
 *
 * ### Usage
 * ```c
 * // creates new parameter
 * icalparameter *param = icalparameter_new();
 *
 * // sets xname
 * icalparameter_set_xname(param, "X-TEST");
 *
 * // compare xname
 * assert(0 == strcmp(icalparameter_get_xname(param), "X-TEST"));
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_get_xname(icalparameter *param);

/**
 * @brief Sets the X-value of @a param to @a v
 * @param param The ::icalparameter to change
 * @param v The X-value to set @a param to
 * @sa icalparameter_get_xvalue()
 *
 * @par Error handling
 * If either @a param or @a v are `NULL`, it sets ::icalerrno to ::ICAL_BARARG_ERROR.
 * If there is an error acquiring memory, it sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The passed string @a v stays in the ownership of the caller - libical
 * creates a copy of it.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *param = icalparameter_new_from_string("X-TEST=FAIL");
 *
 * // set test to success
 * icalparameter_set_xvalue(param, "SUCCESS");
 *
 * // check that it worked
 * assert(0 == strcmp(icalparameter_get_xvalue(param), "SUCCESS"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_xvalue(icalparameter *param, const char *v);

/**
 * @brief Returns the X-value of @a param
 * @param param The ::icalparameter whose X-value is to be returned
 * @return A string representing the X-value of @a param
 * @sa icalparameter_set_xvalue()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR when a `NULL`
 * is passed instead of an ::icalparameter.
 *
 * @par Ownership
 * The string that is returned stays owned by libical and must not
 * be freed by the caller.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *param = icalparameter_new_from_string("X-TEST=FAIL");
 *
 * // set test to success
 * icalparameter_set_xvalue(param, "SUCCESS");
 *
 * // check that it worked
 * assert(0 == strcmp(icalparameter_get_xvalue(param), "SUCCESS"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_get_xvalue(icalparameter *param);

/* Access the name of an IANA parameter */

/**
 * @brief Sets the IANA name of @a param to @a v
 * @param param The icalparameter to change
 * @param v The IANA name to set @a param to
 * @sa icalparameter_get_iana_name()
 *
 * @par Error handling
 * If either @a param or @a v are `NULL`, it sets ::icalerrno to ::ICAL_BARARG_ERROR.
 * If there is an error acquiring memory, it sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The passed string @a v stays in the ownership of the caller - libical
 * creates a copy of it.
 *
 * ### Usage
 * ```c
 * // creates new parameter
 * icalparameter *param = icalparameter_new();
 *
 * // sets iana name
 * icalparameter_set_iana_name(param, "ROLE");
 *
 * // compare iana name
 * assert(0 == strcmp(icalparameter_get_iana_name(param), "X-TEST"));
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_iana_name(icalparameter *param, const char *v);

/**
 * @brief Returns the IANA name of @a param
 * @param param The ::icalparameter whose IANA name is to be returned
 * @return A string representing the IANA name of @a param
 * @sa icalparameter_set_iana_name()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR when a `NULL`
 * is passed instead of an ::icalparameter.
 *
 * @par Ownership
 * The string that is returned stays owned by libical and must not
 * be freed by the caller.
 *
 * ### Usage
 * ```c
 * // creates new parameter
 * icalparameter *param = icalparameter_new();
 *
 * // sets iana name
 * icalparameter_set_iana_name(param, "X-TEST");
 *
 * // compare iana name
 * assert(0 == strcmp(icalparameter_get_iana_name(param), "X-TEST"));
 *
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_get_iana_name(icalparameter *param);

/**
 * @brief Sets the IANA value of @a param to @a v
 * @param param The ::icalparameter to change
 * @param v The IANA value to set @a param to
 * @sa icalparameter_get_iana_value()
 *
 * @par Error handling
 * If either @a param or @a v are `NULL`, it sets ::icalerrno to ::ICAL_BARARG_ERROR.
 * If there is an error acquiring memory, it sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The passed string @a v stays in the ownership of the caller - libical
 * creates a copy of it.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=ATTENDEE");
 *
 * // set role to chair
 * icalparameter_set_iana_value(param, "CHAIR");
 *
 * // check that it worked
 * assert(0 == strcmp(icalparameter_get_iana_value(param), "SUCCESS"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparameter_set_iana_value(icalparameter *param, const char *v);

/**
 * @brief Returns the IANA value of @a param
 * @param param The ::icalparameter whose value is to be returned
 * @return A string representing the value of @a param
 * @sa icalparameter_set_iana_value()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR when a `NULL`
 * is passed instead of an ::icalparameter.
 *
 * @par Ownership
 * The string that is returned stays owned by libical and must not
 * be freed by the caller.
 *
 * ### Usage
 * ```c
 * // create new parameter
 * icalparameter *param = icalparameter_new_from_string("ROLE=ATTENDEE");
 *
 * // set role to chair
 * icalparameter_set_iana_value(param, "CHAIR");
 *
 * // check that it worked
 * assert(0 == strcmp(icalparameter_get_iana_value(param), "SUCCESS"));
 *
 * // release memory
 * icalparameter_free(param);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_get_iana_value(icalparameter *param);

/**
 * @brief Determines if two parameters have the same name
 * @param param1 First parameter to compare
 * @param param2 Second parameter to compare
 * @return 1 if they have the same name, 0 otherwise.
 *
 * @par Error handling
 * If either of @a param1 or @a param2 are `NULL`, it returns 0 and sets
 * ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * @par Ownership
 * Does not take ownership of either ::icalparameter.
 *
 * ### Example
 * ```c
 * // create two parameters
 * icalparameter *param1 = icalparameter_new_from_string("ROLE=CHAIR");
 * icalparameter *param2 = icalparameter_new_from_string("EMAIL=mailto@example.com");
 *
 * // compare parameter names for equality
 * assert(icalparameter_has_same_name(param1, param2) == 0);
 *
 * // release memory
 * icalparameter_free(param1);
 * icalparameter_free(param2);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalparameter_has_same_name(icalparameter *param1, icalparameter *param2);

/* Convert enumerations */

/**
 * @brief Returns a string representing the given ::icalparameter_kind
 * @param kind The icalparameter_kind
 * @return A string representing kind
 *
 * @par Error handling
 * When passed a non-existing ::icalparameter_kind, it returns `NULL`.
 *
 * @par Ownership
 * The string that is returned by this function is owned by libical and
 * must not be freed by the caller.
 *
 * ### Usage
 * ```c
 * assert(0 == strcmp(icalparameter_kind_to_string(ICAL_ROLE_PARAMETER), "ROLE"));
 * assert(0 == strcmp(icalparameter_kind_to_string(ICAL_EMAIL_PARAMETER), "EMAIL));
 * assert(0 == strcmp(icalparameter_kind_to_string(ICAL_ID_PARAMETER), "ID"));
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalparameter_kind_to_string(icalparameter_kind kind);

/**
 * @brief Returns the ::icalparameter_kind for a given string
 * @param string A string describing an icalparameter_kind
 * @return An icalparameter_kind
 *
 * @par Error handling
 * Returns ::ICAL_NO_PARAMETER if @a string is `NULL`.
 * If it can't find the parameter, depending on
 * the ical_get_unknown_token_handling_setting(), it returns either
 * ::ICAL_NO_PARAMETER or ::ICAL_IANA_PARAMETER.
 *
 * @par Ownership
 * Does not take ownership of @a string.
 *
 * ### Usage
 * ```c
 * assert(icalparameter_string_to_kind("ROLE")  == ICAL_ROLE_PARAMETER);
 * assert(icalparameter_string_to_kind("EMAIL") == ICAL_EMAIL_PARAMETER);
 * assert(icalparameter_string_to_kind("ID")    == ICAL_ID_PARAMETER);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparameter_kind icalparameter_string_to_kind(const char *string);

/**
 * @brief Checks the validity of a ::icalparameter_kind
 * @param kind The icalparameter_kind
 * @return 1 if if the kind is valid, 0 otherwise
 *
 * ### Usage
 * ```c
 * assert(icalparameter_kind_is_valid(ICAL_ROLE_PARAMETER));
 * ```
 * @since 3.0.4
 */
LIBICAL_ICAL_EXPORT int icalparameter_kind_is_valid(const icalparameter_kind kind);

#endif
