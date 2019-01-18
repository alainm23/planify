/*======================================================================
  FILE: icalerror.h
  CREATOR: eric 09 May 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

 The original code is icalerror.h
======================================================================*/

#ifndef ICALERROR_H
#define ICALERROR_H

#include "libical_ical_export.h"
#include <assert.h>
#include <stdio.h>

/**
 * @file icalerror.h
 * @brief Error handling for libical
 *
 * Most routines will set the global error value ::icalerrno on errors.
 * This variable is an enumeration; permissible values can be found in
 * icalerror.h. If the routine returns an enum ::icalerrorenum, then the
 * return value will be the same as ::icalerrno. You can use icalerror_strerror()
 * to get a string that describes the error, or icalerror_perror() to
 * get a string describing the current error set in ::icalerrno.
 */

#define ICAL_SETERROR_ISFUNC

/**
 * @brief Triggered before any error is called
 *
 * This routine is called before any error is triggered.
 * It is called by icalerror_set_errno(), so it does not
 * appear in all of the macros below.
 *
 * This routine can be used while debugging by setting
 * a breakpoint here.
 */
LIBICAL_ICAL_EXPORT void icalerror_stop_here(void);

/**
 * @brief Triggered to abort the process
 *
 * This routine is called to abort the process in the
 * case of an error.
 */
LIBICAL_ICAL_EXPORT void icalerror_crash_here(void);

#ifndef _MSC_VER
#pragma GCC visibility push(default)
#endif
/**
 * @typedef icalerrorenum
 * @enum icalerrorenum
 * @brief Represents the different types of errors that
 *  can be triggered in libical
 *
 * Each of these values represent a different type of error, which
 * is stored in ::icalerrno on exit of the library function (or
 * can be returned, but if it is, ::icalerrno is also set).
 */
typedef enum icalerrorenum
{
    /** No error happened */
    ICAL_NO_ERROR = 0,

    /** A bad argument was passed to a function */
    ICAL_BADARG_ERROR,

    /** An error occurred while creating a new object with a `*_new()` routine */
    ICAL_NEWFAILED_ERROR,

    /** An error occurred while allocating some memory */
    ICAL_ALLOCATION_ERROR,

    /** Malformed data was passed to a function */
    ICAL_MALFORMEDDATA_ERROR,

    /** An error occurred while parsing part of an iCal component */
    ICAL_PARSE_ERROR,

    /** An internal error happened in library code */
    ICAL_INTERNAL_ERROR, /* Like assert --internal consist. prob */

    /** An error happened while working with a file */
    ICAL_FILE_ERROR,

    /** Failure to properly sequence calls to a set of interfaces */
    ICAL_USAGE_ERROR,

    /** An unimplemented function was called */
    ICAL_UNIMPLEMENTED_ERROR,

    /** An unknown error occurred */
    ICAL_UNKNOWN_ERROR  /* Used for problems in input to icalerror_strerror() */
} icalerrorenum;
#ifndef _MSC_VER
#pragma GCC visibility pop
#endif

/**
 * @brief Return the current ::icalerrno value
 * @return A pointer to the current ::icalerrno value
 *
 * Yields a pointer to the current ::icalerrno value. This can
 * be used to access (read from and write to) it.
 *
 * ### Examples
 * ```c
 * assert(*icalerrno_return() == icalerrno);
 * ```
 */
LIBICAL_ICAL_EXPORT icalerrorenum *icalerrno_return(void);

/**
 * @brief Access the current ::icalerrno value
 * @return The current ::icalerrno value
 * @note Pseudo-variable that can be used to access the current
 *  ::icalerrno.
 *
 * ### Usage
 * ```c
 * if(icalerrno == ICAL_PARSE_ERROR) {
 *     // ...
 * }
 *
 * // resets error
 * icalerrno = ICAL_NO_ERROR;
 * ```
 */
#define icalerrno (*(icalerrno_return()))

/**
 * @brief Change if errors are fatal
 * @param fatal If true, libical aborts after a call to icalerror_set_error()
 * @warning NOT THREAD SAFE: it is recommended that you do not change
 *  this in a multithreaded program.
 *
 * ### Usage
 * ```c
 * icalerror_set_errors_are_fatal(true); // default
 * icalerror_set_errors_are_fatal(false);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_set_errors_are_fatal(int fatal);

/**
 * @brief Determine if errors are fatal
 * @return True if libical errors are fatal
 *
 * ### Usage
 * ```c
 * if(icalerror_get_errors_are_fatal()) {
 *     // since errors are fatal, this will abort the
 *     // program.
 *     icalerror_set_errno(ICAL_PARSE_ERROR);
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT int icalerror_get_errors_are_fatal(void);

/* Warning messages */

/**
 * @def icalerror_warn(message)
 * @brief Prints a formatted warning message to stderr
 * @param message Warning message to print
 *
 * ### Usage
 * ```c
 * icalerror_warn("Non-standard tag encountered");
 * ```
 */

#ifdef __GNUC__ca
#define icalerror_warn(message) \
{fprintf(stderr, "%s(), %s:%d: %s\n", __FUNCTION__, __FILE__, __LINE__, message);}
#else /* __GNU_C__ */
#define icalerror_warn(message) \
{fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, message);}
#endif /* __GNU_C__ */

/**
 * @brief Reset icalerrno to ::ICAL_NO_ERROR
 *
 * ### Usage
 * ```c
 * if(icalerrno == ICAL_PARSE_ERROR) {
 *     // ignore parsing errors
 *     icalerror_clear_errno();
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_clear_errno(void);

/**
 * @enum icalerrorstate
 * @typedef icalerrorstate
 * @brief Determine if an error is fatal or non-fatal.
 */
typedef enum icalerrorstate
{
    /** Fatal */
    ICAL_ERROR_FATAL,

    /** Non-fatal */
    ICAL_ERROR_NONFATAL,

    /** Fatal if icalerror_errors_are_fatal(), non-fatal otherwise. */
    ICAL_ERROR_DEFAULT,

    /** Asked state for an unknown error type */
    ICAL_ERROR_UNKNOWN
} icalerrorstate;

/**
 * @brief Find description string for error
 * @param e The type of error that occurred
 * @return A string describing the error that occurred
 *
 * @par Error handling
 * If the type of error @a e wasn't found, it returns the description
 * for ::ICAL_UNKNOWN_ERROR.
 *
 * @par Ownership
 * The string that is returned is owned by the library and must not
 * be free'd() by the user.
 *
 * ### Usage
 * ```c
 * if(icalerrno != ICAL_NO_ERROR) {
 *     printf("%s\n", icalerror_strerror(icalerrno));
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalerror_strerror(icalerrorenum e);

/**
 * @brief Return the description string for the current error in ::icalerrno
 *
 * @par Error handling
 * If the type of error @a e wasn't found, it returns the description
 * for ::ICAL_UNKNOWN_ERROR.
 *
 * @par Ownership
 * The string that is returned is owned by the library and must not
 * be free'd() by the user.
 *
 * ### Usage
 * ```c
 * if(icalerrno != ICAL_NO_ERROR) {
 *     printf("%s\n", icalerror_perror());
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalerror_perror(void);

/**
 * @brief Prints backtrace
 * @note Only works on systems that support it (HAVE_BACKTRACE enabled).
 *
 * ### Usage
 * ```
 * if(icalerrno != ICAL_NO_ERROR) {
 *     ical_bt();
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT void ical_bt(void);

/**
 * @brief Set the ::icalerrorstate for a given ::icalerrorenum @a error
 * @param error The error to change
 * @param state The new error state of the error
 *
 * Sets the severity of a given error. For example, it can be used to
 * set the severity of an ::ICAL_PARSE_ERROR to be an ::ICAL_ERROR_NONFATAL.
 *
 * ### Usage
 * ```c
 * icalerror_set_error_state(ICAL_PARSE_ERROR, ICAL_ERROR_NONFATAL);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_set_error_state(icalerrorenum error, icalerrorstate state);

/**
 * @brief Get the error state (severity) for a given error
 * @param error The error to examine
 * @return Returns the severity of the error
 */
LIBICAL_ICAL_EXPORT icalerrorstate icalerror_get_error_state(icalerrorenum error);

/**
 * @brief Read an error from a string
 * @param str The error name string
 * @return An ::icalerrorenum representing the error
 *
 * @par Error handling
 * If the error specified in @a str can't be found, instead
 * ::ICAL_UNKNOWN_ERROR is returned.
 *
 * ### Usage
 * ```c
 * assert(icalerror_error_from_string("PARSE") == ICAL_PARSE_ERROR);
 * assert(icalerror_error_from_string("NONSENSE") == ICAL_UNKNOWN_ERROR);
 * ```
 */
LIBICAL_ICAL_EXPORT icalerrorenum icalerror_error_from_string(const char *str);

/**
 * @def icalerror_set_errno(x)
 * @brief Sets the ::icalerrno to a given error
 * @param x The error to set ::icalerrno to
 *
 * Sets ::icalerrno to the error given in @a x. Additionally, if
 * the error is an ::ICAL_ERROR_FATAL or if it's an ::ICAL_ERROR_DEFAULT
 * and ::ICAL_ERRORS_ARE_FATAL is true, it prints a warning to @a stderr
 * and aborts the process.
 *
 * ### Usage
 * ```c
 * icalerror_set_errno(ICAL_PARSE_ERROR);
 * ```
 */
#if !defined(ICAL_SETERROR_ISFUNC)
#define icalerror_set_errno(x) \
icalerrno = x; \
if(icalerror_get_error_state(x) == ICAL_ERROR_FATAL || \
   (icalerror_get_error_state(x) == ICAL_ERROR_DEFAULT && \
    icalerror_get_errors_are_fatal() == 1)){              \
   icalerror_warn(icalerror_strerror(x)); \
   ical_bt(); \
   assert(0); \
} }
#else
/**
 * @brief Sets the ::icalerrno to a given error
 * @param x The error to set ::icalerrno to
 *
 * Sets ::icalerrno to the error given in @a x. Additionally, if
 * the error is an ::ICAL_ERROR_FATAL or if it's an ::ICAL_ERROR_DEFAULT
 * and ::ICAL_ERRORS_ARE_FATAL is true, it prints a warning to @a stderr
 * and aborts the process.
 *
 * ### Usage
 * ```c
 * icalerror_set_errno(ICAL_PARSE_ERROR);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_set_errno(icalerrorenum x);
#endif

/**
 * @def ICAL_ERRORS_ARE_FATAL
 * @brief Determines if all libical errors are fatal and lead to
 *  the process aborting.
 *
 * If set to 1, all libical errors are fatal and lead to the
 * process aborting upon encountering on. Otherwise, errors
 * are nonfatal.
 *
 * Can be checked with libical_get_errors_are_fatal().
 */

#if !defined(ICAL_ERRORS_ARE_FATAL)
#define ICAL_ERRORS_ARE_FATAL 0
#endif

#if ICAL_ERRORS_ARE_FATAL == 1
#undef NDEBUG
#endif

#define icalerror_check_value_type(value,type);
#define icalerror_check_property_type(value,type);
#define icalerror_check_parameter_type(value,type);
#define icalerror_check_component_type(value,type);

/* Assert with a message */
/**
 * @def icalerror_assert(test, message)
 * @brief Assert with a message
 * @param test The assertion to test
 * @param message The message to print on failure of assertion
 *
 * Tests the given assertion @a test, and if it fails, prints the
 * @a message given on @a stderr as a warning and aborts the process.
 * This only works if ::ICAL_ERRORS_ARE_FATAL is true, otherwise
 * does nothing.
 */
#if ICAL_ERRORS_ARE_FATAL == 1

#ifdef __GNUC__
#define icalerror_assert(test,message) \
if (!(test)) { \
    fprintf(stderr, "%s(), %s:%d: %s\n", __FUNCTION__, __FILE__, __LINE__, message); \
    icalerror_stop_here(); \
    abort();}
#else /*__GNUC__*/
#define icalerror_assert(test,message) \
if (!(test)) { \
    fprintf(stderr, "%s:%d: %s\n", __FILE__, __LINE__, message); \
    icalerror_stop_here(); \
    abort();}
#endif /*__GNUC__*/

#else /* ICAL_ERRORS_ARE_FATAL */
#define icalerror_assert(test,message)
#endif /* ICAL_ERRORS_ARE_FATAL */

/**
 * @brief Checks the assertion @a test and raises error on failure
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * ### Example
 * ```c
 * void test_function(icalcomponent *component) {
 *    icalerror_check_arg(component != 0, "component");
 *
 *    // use component
 * }
 * ```
 */
#define icalerror_check_arg(test,arg) \
if (!(test)) { \
    icalerror_set_errno(ICAL_BADARG_ERROR); \
}

/**
 * @brief Checks the assertion @a test and raises error on failure, returns void
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR and causes the enclosing
 * function to return `void`.
 *
 * ### Example
 * ```c
 * void test_function(icalcomponent *component) {
 *    icalerror_check_arg_rv(component != 0, "component");
 *
 *    // use component
 * }
 * ```
 */
#define icalerror_check_arg_rv(test,arg) \
if (!(test)) { \
    icalerror_set_errno(ICAL_BADARG_ERROR); \
    return; \
}

/**
 * @brief Checks the assertion @a test and raises error on failure, returns 0
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR and causes the enclosing
 * function to return `0`.
 *
 * ### Example
 * ```c
 * int test_function(icalcomponent *component) {
 *    icalerror_check_arg_rz(component != 0, "component");
 *
 *    // use component
 *    return icalcomponent_count_kinds(component, ICAL_ANY_COMPONENT);
 * }
 * ```
 */
#define icalerror_check_arg_rz(test,arg) \
if (!(test)) { \
    icalerror_set_errno(ICAL_BADARG_ERROR); \
    return 0; \
}

/**
 * @brief Checks the assertion @a test and raises error on failure, returns @a error
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 * @param error What to return on error
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it aborts the process with `assert(0)` and causes the enclosing
 * function to return @a error.
 *
 * ### Example
 * ```c
 * icalcomponent *test_function(icalcomponent *component) {
 *    icalerror_check_arg_re(component != 0, "component", NULL);
 *
 *    // use component
 *    return icalcomponent_get_first_real_component(component);
 * }
 * ```
 */
#define icalerror_check_arg_re(test,arg,error) \
if (!(test)) { \
    icalerror_stop_here(); \
    assert(0); \
    return error; \
}

/**
 * @brief Checks the assertion @a test and raises error on failure, returns @a x
 * @param test The assertion to check
 * @param arg  The argument involved (as a string)
 * @param x    What to return on error
 *
 * This function checks the assertion @a test, which is used to
 * test if the parameter @a arg is correct. If the assertion fails,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR and causes the enclosing
 * function to return @a x.
 *
 * ### Example
 * ```c
 * icalcomponent *test_function(icalcomponent *component) {
 *    icalerror_check_arg_rx(component != 0, "component", NULL);
 *
 *    // use component
 *    return icalcomponent_get_first_real_component(component);
 * }
 * ```
 */
#define icalerror_check_arg_rx(test,arg,x) \
if (!(test)) { \
    icalerror_set_errno(ICAL_BADARG_ERROR); \
    return x; \
}

/* String interfaces to set an error to NONFATAL and restore it to its original value */

/**
 * @brief Suppresses a given error
 * @param error The name of the error to suppress
 * @return The previous icalerrorstate (severity)
 *
 * Calling this function causes the given error to be listed as
 * ::ICAL_ERROR_NONFATAL, and thus suppressed. Error states can be
 * restored with icalerror_restore().
 *
 * ### Usage
 * ```c
 * // suppresses internal errors
 * icalerror_supress("INTERNAL");
 * ```
 */
LIBICAL_ICAL_EXPORT icalerrorstate icalerror_supress(const char *error);

/**
 * Assign the given error the given icalerrorstate (severity)
 * @param error The error in question
 * @param es The icalerrorstate (severity) to set it to
 *
 * Calling the function changes the ::icalerrorstate of the given error.
 *
 * ### Usage
 * ```c
 * // suppress internal errors
 * icalerror_supress("INTERNAL");
 *
 * // ...
 *
 * // restore internal errors
 * icalerror_restore("INTERNAL", ICAL_ERROR_DEFAULT);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalerror_restore(const char *error, icalerrorstate es);

#endif /* !ICALERROR_H */
