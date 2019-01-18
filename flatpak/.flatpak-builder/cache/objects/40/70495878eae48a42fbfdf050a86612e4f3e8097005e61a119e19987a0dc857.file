/*======================================================================
 FILE: icalattach.h
 CREATOR: acampi 28 May 02

 (C) COPYRIGHT 2002, Andrea Campi <a.campi@inet.it>

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

/**
 * @file icalattach.h
 * @brief A set of functions to handle iCal attachments.
 *
 * With the `ATTACH` property, the iCal standard defines a way to
 * associate a document object with a calendar component.
 *
 * These are represented with ::icalattach objects in libical.
 * This file contains functions to create and work with these
 * objects.
 */

#ifndef ICALATTACH_H
#define ICALATTACH_H

#include "libical_ical_export.h"

/**
 * @typedef icalattach
 * @brief An iCal attach object representing a link to a document object.
 *
 * Represents an association with a document object. ::icalattach objects
 * are reference counted, meaning that if the last reference to them is
 * removed (with icalattach_unref()), they are destroyed.
 */
typedef struct icalattach_impl icalattach;

/**
 * @typedef icalattach_free_fn_t
 * @brief (*unused*) Function to be called to free the data of an ::icalattach object.
 * @warning Currently not used
 *
 * This function type is used to free the data from an ::icalattach object created
 * with icalattach_new_from_data(). It is currently not used
 */
typedef void (*icalattach_free_fn_t) (unsigned char *data, void *user_data);

/**
 * @brief Create new ::icalattach object from a URL.
 * @param url The URL to create the object from
 * @return An ::icalattach object with the given URL as association
 * @sa icalattach_unref()
 *
 * @par Error handling
 * If @a url is `NULL`, it returns `NULL` and sets ::icalerrno to
 * ::ICAL_BADARG_ERROR. If there was an error allocating memory, it
 * returns `NULL` and sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The returned ::icalattach object is owned by the caller of the function.
 * ::icalattach objects are reference counted, which means that after
 * use, icalattach_unref() needs to be called to signal that they are
 * not used anymore.
 *
 * ### Usage
 * ```c
 * // creates new
 * icalattach *attach = icalattach_new_from_url("http://example.com");
 *
 * // checks it
 * assert(icalattach_get_is_url(attach));
 * assert(0 == strcmp(icalattach_get_url(attach), "http://example.com"));
 *
 * // release it
 * icalattach_unref(attach);
 * ```
 */
LIBICAL_ICAL_EXPORT icalattach *icalattach_new_from_url(const char *url);

/**
 * @brief Create new ::icalattach object from data.
 * @param data The data to create the ::icalattach from
 * @param free_fn (*unused*) The function to free the data
 * @param free_fn_data (*unused*) Data to pass to the @a free_fn
 * @return An ::icalattach object with the given data
 * @sa icalattach_unref()
 *
 * @par Error handling
 * If @a url is `NULL`, it returns `NULL` and sets ::icalerrno to
 * ::ICAL_BADARG_ERROR. If there was an error allocating memory, it
 * returns `NULL` and sets `errno` to `ENOMEM`.
 *
 * @par Ownership
 * The returned ::icalattach object is owned by the caller of the function.
 * ::icalattach objects are reference counted, which means that after
 * use, icalattach_unref() needs to be called to signal that they are
 * not used anymore.
 */
LIBICAL_ICAL_EXPORT icalattach *icalattach_new_from_data(const char *data,
                                                         icalattach_free_fn_t free_fn,
                                                         void *free_fn_data);

/**
 * @brief Increments reference count of the ::icalattach.
 * @param attach The object to increase the reference count of
 * @sa icalattach_unref()
 *
 * @par Error handling
 * If @a attach is `NULL`, or the reference count is smaller than 0,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * @par Ownership
 * By increasing the refcount of @a attach, you are signaling that
 * you are using it, and it is the owner's responsibility to call
 * icalattach_unref() after it's no longer used.
 */
LIBICAL_ICAL_EXPORT void icalattach_ref(icalattach *attach);

/**
 * @brief Decrements reference count of the ::icalattach.
 * @param attach The object to decrease the reference count of
 * @sa icalattach_ref()
 *
 * Decreases the reference count of @a attach. If this was the
 * last user of the object, it is freed.
 *
 * @par Error handling
 * If @a attach is `NULL`, or the reference count is smaller than 0,
 * it sets ::icalerrno to ::ICAL_BADARG_ERROR.
 *
 * @par Ownership
 * Calling this function releases the icalattach back to the library,
 * and it must not be used afterwards.
 *
 * ### Usage
 * ```c
 * // creates new
 * icalattach *attach = icalattach_new_from_url("http://example.com");
 *
 * // release it
 * icalattach_unref(attach);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalattach_unref(icalattach *attach);

/**
 * @brief Determines if @a attach is an URL.
 * @param attach the ::icalattach object to check
 * @return 1 if it is a URL, otherwise 0.
 * @sa icalattach_get_url()
 *
 * @par Error handling
 * Returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR if
 * @a attach is `NULL`.
 *
 * ### Usage
 * ```c
 * // creates new
 * icalattach *attach = icalattach_new_from_url("http://example.com");
 *
 * // checks if it is a URL
 * assert(icalattach_get_is_url(attach));
 *
 * // release it
 * icalattach_unref(attach);
 * ```
 */
LIBICAL_ICAL_EXPORT int icalattach_get_is_url(icalattach *attach);

/**
 * @brief Returns the URL of the ::icalattach object.
 * @param attach The object from which to return the URL
 * @return The URL of the object
 * @sa icalattach_get_is_url()
 *
 * Returns the URL of the ::icalattach object.
 *
 * @par Error handling
 * Returns `NULL` and set ::icalerrno to ::ICAL_BADARG_ERROR if
 * @a attach is `NULL`. Undefined behaviour if the object is not
 * a URL (check with icalattach_get_is_url()).
 *
 * @par Ownership
 * The string returned is owned by libical and must not be freed
 * by the caller.
 *
 * # Usage
 * ```c
 * // creates new
 * icalattach *attach = icalattach_new_from_url("http://example.com");
 *
 * // checks it
 * assert(icalattach_get_is_url(attach));
 * assert(0 == strcmp(icalattach_get_url(attach), "http://example.com"));
 *
 * // release it
 * icalattach_unref(attach);
 * ```
 */
LIBICAL_ICAL_EXPORT const char *icalattach_get_url(icalattach *attach);

/**
 * @brief Returns the data of the ::icalattach object.
 * @param attach The object from which to return the data
 * @return The data of the object
 * @sa icalattach_get_is_url()
 *
 * Returns the URL of the ::icalattach object.
 *
 * @par Error handling
 * Returns `NULL` and set ::icalerrno to ::ICAL_BADARG_ERROR if
 * @a attach is `NULL`. Undefined behaviour if the object is
 * a URL (check with icalattach_get_is_url()).
 *
 * @par Ownership
 * The string returned is owned by libical and must not be freed
 * by the caller.
 */
LIBICAL_ICAL_EXPORT unsigned char *icalattach_get_data(icalattach *attach);

#endif /* !ICALATTACH_H */
