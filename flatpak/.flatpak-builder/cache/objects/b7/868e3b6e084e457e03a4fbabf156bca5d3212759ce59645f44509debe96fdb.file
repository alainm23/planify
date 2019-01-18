/*======================================================================
 FILE: icalparser.h
 CREATOR: eric 20 April 1999

 (C) COPYRIGHT 2000, Eric Busboom <eric@softwarestudio.org>
     http://www.softwarestudio.org

 This library is free software; you can redistribute it and/or modify
 it under the terms of either:

    The LGPL as published by the Free Software Foundation, version
    2.1, available at: http://www.gnu.org/licenses/lgpl-2.1.html

 Or:

    The Mozilla Public License Version 2.0. You may obtain a copy of
    the License at http://www.mozilla.org/MPL/

  The original code is icalparser.h
======================================================================*/

#ifndef ICALPARSER_H
#define ICALPARSER_H

#include "libical_ical_export.h"
#include "icalcomponent.h"

/**
 * @file  icalparser.h
 * @brief Line-oriented parsing.
 *
 * This file provides methods to parse iCalendar-formatted data
 * into the structures provided by this library.
 *
 * ### Usage
 * Create a new parser via icalparser_new_parser(), then add lines one at
 * a time with icalparser_add_line(). icalparser_add_line() will return
 * non-zero when it has finished with a component.
 */

/**
 * @struct icalparser_impl
 * @typedef icalparser
 * @private
 *
 * Implementation of the icalparser struct, which holds the
 * state for the current parsing operation.
 */
typedef struct icalparser_impl icalparser;

/**
 * @enum icalparser_state
 * @typedef icalparser_state
 * @brief Represents the current state of the parser
 */
typedef enum icalparser_state
{
    /** An error occurred while parsing. */
    ICALPARSER_ERROR,

    /** Parsing was successful. */
    ICALPARSER_SUCCESS,

    /** Currently parsing the begin of a component */
    ICALPARSER_BEGIN_COMP,

    /** Currently parsing the end of the component */
    ICALPARSER_END_COMP,

    /** Parsing is currently in progress */
    ICALPARSER_IN_PROGRESS
} icalparser_state;

typedef char *(*icalparser_line_gen_func) (char *s, size_t size, void *d);

/**
 * @brief Creates a new ::icalparser.
 * @return An ::icalparser object
 *
 * @par Error handling
 * On error, it returns `NULL` and sets ::icalerrno to
 * ::ICAL_NEWFAILED_ERROR.
 *
 * @par Ownership
 * All ::icalparser objects created with this function need to be
 * freed using the icalparser_free() function.
 *
 * ### Usage
 * ```c
 * // create new parser
 * icalparser *parser = icalparser_new();
 *
 * // do something with it...
 *
 * // free parser
 * icalparser_free(parser);
 * ```
 */
LIBICAL_ICAL_EXPORT icalparser *icalparser_new(void);

/**
 * @brief Adds a single line to be parsed by the ::icalparser.
 * @param parser The parser to use
 * @param str A string representing a single line of RFC5545-formatted iCalendar data
 * @return When this was the last line of the component to be parsed,
 *  it returns the icalcomponent, otherwise it returns `NULL`.
 * @sa icalparser_parse()
 *
 * @par Error handling
 * -   If @a parser is `NULL`, it returns `NULL` and sets ::icalerrno to
 *     ::ICAL_BADARG_ERROR.
 * -   If @a line is empty, if returns `NULL`
 * -   If @a line is `NULL`, it returns `NULL` and sets the @a parser's ::icalparser_state to
 *     ::ICALPARSER_ERROR.
 * -   For errors during parsing, the functions can set the ::icalparser_state to
 *     ::ICALPARSER_ERROR and/or return components of the type ::ICAL_XLICINVALID_COMPONENT,
 *     or components with properties of the type ::ICAL_XLICERROR_PROPERTY.
 *
 * @par Ownership
 * Ownership of the @a str is transferred to libical upon calling this
 * method. The returned ::icalcomponent is owned by the caller and needs
 * to be `free()`d with the appropriate method after it's no longer needed.
 *
 * ### Example
 * ```c
 * char* read_stream(char *s, size_t size, void *d)
 * {
       return fgets(s, (int)size, (FILE*)d);
 * }
 *
 * void parse()
 * {
 *     char* line;
 *     FILE* stream;
 *     icalcomponent *component;
 *
 *     icalparser *parser = icalparser_new();
 *     stream = fopen(argv[1],"r");
 *
 *     icalparser_set_gen_data(parser, stream);
 *
 *     do{
 *         // get a single content line
 *         line = icalparser_get_line(parser, read_stream);
 *
 *         // add that line to the parser
 *         c = icalparser_add_line(parser,line);
 *
 *         // once we parsed a component, print it
 *         if (c != 0) {
 *             printf("%s", icalcomponent_as_ical_string(c));
 *             icalcomponent_free(c);
 *         }
 *     } while (line != 0);
 *
 *     icalparser_free(parser);
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalparser_add_line(icalparser *parser, char *str);

/**
 * @brief Cleans out an ::icalparser and returns whatever it has parsed so far.
 * @param parser The ::icalparser to clean
 * @return The parsed ::icalcomponent
 *
 * @par Error handling
 * If @a parser is `NULL`, it returns `NULL` and sets ::icalerrno to
 * ::ICAL_BADARG_ERROR. For parsing errors, it inserts an `X-LIC-ERROR`
 * property into the affected components.
 *
 * @par Ownership
 * The returned ::icalcomponent is property of the caller and needs to be
 * free'd with icalcomponent_free() after use.
 *
 * This will parse components even if it hasn't encountered a proper
 * `END` tag for it yet and return them, as well as clearing any intermediate
 * state resulting from being in the middle of parsing something so the
 * parser can be used to parse something new.
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalparser_clean(icalparser *parser);

/**
 * @brief Returns current state of the icalparser
 * @param parser The (valid, non-`NULL`) parser object
 * @return The current state of the icalparser, as an ::icalparser_state
 *
 * ### Example
 * ```c
 * icalparser *parser = icalparser_new();
 *
 * // use icalparser...
 *
 * if(icalparser_get_state(parser) == ICALPARSER_ERROR) {
 *     // handle error
 * } else {
 *     // ...
 * }
 * ```
 *
 * icalparser_free(parser);
 */
LIBICAL_ICAL_EXPORT icalparser_state icalparser_get_state(icalparser *parser);

/**
 * @brief Frees an ::icalparser object.
 * @param parser The ::icalparser to be freed.
 *
 * ### Example
 * ```c
 * icalparser *parser = icalparser_new();
 *
 * // use parser ...
 *
 * icalparser_free(parser);
 * ```
 */
LIBICAL_ICAL_EXPORT void icalparser_free(icalparser *parser);

/**
 * @brief Message oriented parsing.
 * @param parser The parser to use
 * @param line_gen_func A function that returns one content line per invocation
 * @return The parsed icalcomponent
 * @sa icalparser_parse_string()
 *
 * Reads an icalcomponent using the supplied @a line_gen_func, returning the parsed
 * component (or `NULL` on error).
 *
 * @par Error handling
 * -   If @a parser is `NULL`, it returns `NULL` and sets ::icalerrno to ::ICAL_BADARG_ERROR.
 * -   If data read by @a line_gen_func is empty, if returns `NULL`
 * -   If data read by @a line_gen_func is `NULL`, it returns `NULL`
 *     and sets the @a parser's ::icalparser_state to ::ICALPARSER_ERROR.
 * -   For errors during parsing, the functions can set the ::icalparser_state to
 *     ::ICALPARSER_ERROR and/or return components of the type ::ICAL_XLICINVALID_COMPONENT,
 *     or components with properties of the type ::ICAL_XLICERROR_PROPERTY.
 *
 * @par Ownership
 * The returned ::icalcomponent is owned by the caller of the function, and
 * needs to be `free()`d with the appropriate method when no longer needed.
 *
 * ### Example
 * ```c
 * char* read_stream(char *s, size_t size, void *d)
 * {
       return fgets(s, (int)size, (FILE*)d);
 * }
 *
 * void parse()
 * {
 *     char* line;
 *     FILE* stream;
 *     icalcomponent *component;
 *
 *     icalparser *parser = icalparser_new();
 *     stream = fopen(argv[1],"r");
 *
 *     icalparser_set_gen_data(parser, stream);
 *
 *     // use the parse method to parse the input data
 *     component = icalparser_parse(parser, read_stream);
 *
 *     // once we parsed a component, print it
 *     printf("%s", icalcomponent_as_ical_string(c));
 *     icalcomponent_free(c);
 *
 *     icalparser_free(parser);
 * }
 * ```
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalparser_parse(icalparser *parser,
                                                    icalparser_line_gen_func line_gen_func);

/**
 * @brief Sets the data that icalparser_parse will give to the line_gen_func
 * as the parameter 'd'.
 * @param parser The icalparser this applies to
 * @param data The pointer which will be passed to the line_gen_func as argument `d`
 *
 * If you use any of the icalparser_parser() or icalparser_get_line() functions,
 * the @a line_gen_func that they expect has a third `void* d` argument. This function
 * sets what will be passed to your @a line_gen_function as such argument.
 */
LIBICAL_ICAL_EXPORT void icalparser_set_gen_data(icalparser *parser, void *data);

/**
 * @brief Parse a string and return the parsed ::icalcomponent.
 * @param str The iCal formatted data to be parsed
 * @return An ::icalcomponent representing the iCalendar
 *
 * @par Error handling
 * On error, returns `NULL` and sets ::icalerrno
 *
 * @par Ownership
 * The returned ::icalcomponent is owned by the caller of the function, and
 * needs to be free'd with the appropriate functions after use.
 *
 * ### Example
 * ```c
 * char *ical_string;
 *
 * // parse ical_string
 * icalcomponent *component = icalparser_parse_string(ical_string);
 *
 * if(!icalerrno || component == NULL) {
 *     // use component ...
 * }
 *
 * // release component
 * icalcomponent_free(component);
 * ```
 */
LIBICAL_ICAL_EXPORT icalcomponent *icalparser_parse_string(const char *str);

/***********************************************************************
 * Parser support functions
 ***********************************************************************/

/**
 * @brief Given a line generator function, return a single iCal content line.
 * @return Aa pointer to a single line of data or `NULL` if it reached
 *  end of file reading from the @a line_gen_func. Note that the pointer
 *  returned is owned by libical and must not be `free()`d by the user.
 * @param parser The parser object to use
 * @param line_gen_func The function to use for reading data
 *
 * This function uses the supplied @a line_gen_func to read data in,
 * until it has read a full line, and returns the full line.
 * To supply arbitrary data (as the parameter @a d) to your @a line_gen_func,
 * call icalparser_set_gen_data().
 */
LIBICAL_ICAL_EXPORT char *icalparser_get_line(icalparser *parser,
                                              icalparser_line_gen_func line_gen_func);

LIBICAL_ICAL_EXPORT char *icalparser_string_line_generator(char *out, size_t buf_size, void *d);

#endif /* !ICALPARSE_H */
