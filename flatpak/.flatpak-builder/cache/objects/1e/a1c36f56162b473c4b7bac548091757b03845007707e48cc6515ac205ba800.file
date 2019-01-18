/*======================================================================
 FILE: icalarray.h
 CREATOR: Damon Chaplin 07 March 2001

 (C) COPYRIGHT 2001, Ximian, Inc.

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/
======================================================================*/

/** @file icalarray.h
 *
 *  @brief An array of arbitrarily-sized elements which grows
 *  dynamically as elements are added.
 */

#ifndef ICALARRAY_H
#define ICALARRAY_H

#include "libical_ical_export.h"

/**
 * @typedef icalarray
 * @brief A struct representing an icalarray object
 */
typedef struct _icalarray icalarray;
struct _icalarray
{
    size_t element_size;
    size_t increment_size;
    size_t num_elements;
    size_t space_allocated;
    void **chunks;
};

/**
 * @brief Creates new ::icalarray object.
 * @param element_size The size of the elements to be held by the array
 * @param increment_size How many extra elements worth of space to allocate on expansion
 * @return The new ::icalarray object
 * @sa icalarray_free()
 *
 * Creates a new ::icalarray object. The parameter @a element_size determines
 * the size of the elements that the array will hold (in bytes). The parameter
 * @a increment_size determines how many extra elements to be allocated when
 * expanding the array for performance reasons (expansions are expensive, since
 * it involves copying all existing elements).
 *
 * @par Error handling
 * If @a element_size or @a increment_size is not at least 1, using the ::icalarray
 * object results in undefined behaviour. If there is an error while creating the
 * object, it returns `NULL` and sets ::icalerrno to ::ICAL_NEWFAILED_ERROR.
 *
 * @par Ownership
 * The returned ::icalarray object is owned by the caller of the function,
 * and needs to be released properly after it's no longer needed with
 * icalarray_free().
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // use array
 * int a = 4;
 * icalarray_append(array, &a);
 * assert(*icalarray_element_at(array, 0) == a);
 *
 * // release memory
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT icalarray *icalarray_new(size_t element_size, size_t increment_size);

/**
 * @brief Copies an existing ::icalarray and it's elements, creating a new one.
 * @param array The array to copy
 * @return A new array, holding all the elements of @a array
 *
 * Creates a new ::icalarray object, copying all the existing elements from
 * @a array as well as it's properties (such as @a element_size and
 * @a increment_size) over.
 *
 * @par Error handling
 * If @a array is `NULL`, this method will return `NULL`. If there was an error
 * allocating memory while creating the copy, it will set ::icalerrno
 * to ::ICAL_ALLOCATION_ERROR.
 *
 * @par Ownership
 * The created copy is owned by the caller of the function, and needs to
 * be released with icalarray_free() after it's no longer being used.
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // fill array
 * int a = 4;
 * icalarray_append(array, &a);
 *
 * // create copy of array
 * icalarray *copy = icalarray_copy(array);
 * assert(*icalarray_element_at(copy, 0) == a);
 *
 * // release arrays
 * icalarray_free(array);
 * icalarray_free(copy);
 * ```
 */
LIBICAL_ICAL_EXPORT icalarray *icalarray_copy(icalarray *array);

/**
 * @brief Frees an array object and everything that it contains.
 * @param array The array to release
 *
 * ### Example
 * ```c
 * // creating an array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // releasing it
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalarray_free(icalarray *array);

/**
 * @brief Appends an element to an array.
 * @param array The array to append the element to
 * @param element The element to append
 *
 * Appends the given @a element to the @a array, reallocating
 * and expanding the array as needed.
 *
 * @par Error handling
 * If @a array or @a element is `NULL`, using this function results
 * in undefined behaviour (most likely a segfault).
 *
 * @par Ownership
 * The @a element does not get consumed by the method, since it creates
 * a copy of it
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // append data to it
 * int data = 42;
 * icalarray_append(array, &data);
 *
 * // release array
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalarray_append(icalarray *array, const void *element);

/**
 * @brief Removes a given element from an array.
 * @brief array The array from which to remove the element
 * @brief position The position of the element to remove
 *
 * Removes the element at the given position from the array.
 *
 * @par Error handling
 * If @a array is `NULL`, using this function results in undefined behaviour.
 * If the array is empty, using this functino results in undefined behaviour.
 * If the @a position is non-existent, it removes the last element.
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 2);
 *
 * // fill array
 * int data;
 * data = 4;
 * icalarray_append(array, &a);
 * data = 9;
 * icalarray_append(array, &a);
 * data = 7;
 * icalarray_append(array, &a);
 * data = 10;
 * icalarray_append(array, &a);
 *
 * // check array
 * assert(*icalarray_element_at(array, 0) == 4);
 * assert(*icalarray_element_at(array, 1) == 9);
 * assert(*icalarray_element_at(array, 2) == 7);
 * assert(*icalarray_element_at(array, 3) == 10);
 *
 * // remove the second element
 * icalarray_remove_element_at(array, 1);
 *
 * // check array
 * assert(*icalarray_element_at(array, 0) == 4);
 * assert(*icalarray_element_at(array, 1) == 7);
 * assert(*icalarray_element_at(array, 2) == 10);
 *
 * // release array
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalarray_remove_element_at(icalarray *array, size_t position);

/**
 * @brief Access an array element
 * @param array The array object in which the element is stored
 * @param position The position of the element to access in the array
 * @return A pointer to the element inside the array
 *
 * Accesses an array element by returning a pointer to it, given an
 * @a array and a valid element @a position.
 *
 * @par Error handling
 * If @a array is `NULL`, using this function results in undefined behaviour.
 * If @a position is not a valid position in the array, using this function
 * results in undefined behaviour.
 *
 * @par Ownership
 * The element is owned by the ::icalarray, it must not be freed by
 * the user.
 *
 * ### Usage
 * ```c
 * // create new array
 * icalarray *array = icalarray_new(sizeof(int), 1);
 *
 * // fill array
 * int a = 4;
 * icalarray_append(array, &a);
 *
 * // access array element
 * int *element = icalarray_element_at(array, 0);
 * assert(element != NULL);
 * assert(*element == a);
 *
 * // change array element
 * *element = 14;
 * assert(*icalarray_element(array) == 14);
 *
 * // release memory
 * icalarray_free(array);
 * ```
 */
LIBICAL_ICAL_EXPORT void *icalarray_element_at(icalarray *array, size_t position);

/**
 * @brief Sorts the elements of an ::icalarray using the given comparison function.
 * @param array The array to sort
 * @param compare The comparison function to use
 *
 * @par Error handling
 * Passing `NULL` as either @a array or @a compare results in undefined
 * behaviour.
 *
 * ### Usage
 * ```c
 * int compare_ints(const void *a, const void *b) {
 *     return *((int*)a) - *((int*)b);
 * }
 *
 * int main(int argc, char *argv[]) {
 *     int numbers[] = {5, 2, 7, 4, 3, 1, 0, 8, 6, 9};
 *
 *     icalarray *array = icalarray_new(sizeof(int), 3);
 *
 *     // fill array
 *     for(int i = 0; i < 10; i++) {
 *         icalarray_append(array, &numbers[i]);
 *     }
 *
 *     // sort array
 *     icalarray_sort(array, compare_ints);
 *
 *     // print numbers
 *     for(int i = 0; i < 10; i++) {
 *         printf("%i\n", *((int*)icalarray_element_at(array, i)));
 *     }
 *
 *     return 0;
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT void icalarray_sort(icalarray *array,
                                        int (*compare) (const void *, const void *));

#endif /* ICALARRAY_H */
