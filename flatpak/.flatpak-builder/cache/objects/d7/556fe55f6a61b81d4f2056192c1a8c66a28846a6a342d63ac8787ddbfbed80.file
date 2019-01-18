/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_DEBUG_H
#define CAMEL_DEBUG_H

#include <glib.h>

/* This is how the basic debug checking strings should be done */
#define CAMEL_DEBUG_IMAP "imap"
#define CAMEL_DEBUG_IMAP_FOLDER "imap:folder"

G_BEGIN_DECLS

void camel_debug_init (void);
gboolean camel_debug (const gchar *mode);

gboolean camel_debug_start (const gchar *mode);
void camel_debug_end (void);

/**
 * CAMEL_CHECK_GERROR:
 * @object: a #GObject descendant
 * @method: a method which was run
 * @expr: an expression to test, which evaluates to %TRUE or %FALSE
 * @error: a pointer to a pointer of a #GError, set by the @method
 *
 * This sanity checks return values and #GError.  If returning
 * failure, make sure the #GError is set.  If returning success,
 * make sure the #GError is NOT set.
 *
 * Example:
 *
 *     success = class->foo (object, some_data, error);
 *     CAMEL_CHECK_GERROR (object, foo, success, error);
 *     return success;
 *
 * Since: 2.32
 */
#define CAMEL_CHECK_GERROR(object, method, expr, error) \
	G_STMT_START { \
	if (expr) { \
		if ((error) != NULL && *(error) != NULL) { \
			g_warning ( \
				"%s::%s() set its GError " \
				"but then reported success", \
				G_OBJECT_TYPE_NAME (object), \
				G_STRINGIFY (method)); \
			g_warning ( \
				"Error message was: %s", \
				(*(error))->message); \
		} \
	} else { \
		if ((error) != NULL && *(error) == NULL) { \
			g_warning ( \
				"%s::%s() reported failure " \
				"without setting its GError", \
				G_OBJECT_TYPE_NAME (object), \
				G_STRINGIFY (method)); \
		} \
	} \
	} G_STMT_END

/**
 * CAMEL_CHECK_LOCAL_GERROR:
 * @object: a #GObject descendant
 * @method: a method which was run
 * @expr: an expression to test, which evaluates to %TRUE or %FALSE
 * @error: a pointer to a #GError, set by the @method
 *
 * Same as CAMEL_CHECK_GERROR, but for direct #GError pointers.
 *
 * Example:
 *
 *     success = class->foo (object, some_data, &local_error);
 *     CAMEL_CHECK_LOCAL_GERROR (object, foo, success, local_error);
 *     return success;
 *
 * Since: 3.12
 */
#define CAMEL_CHECK_LOCAL_GERROR(object, method, expr, error) \
	G_STMT_START { \
	if (expr) { \
		if ((error) != NULL) { \
			g_warning ( \
				"%s::%s() set its GError " \
				"but then reported success", \
				G_OBJECT_TYPE_NAME (object), \
				G_STRINGIFY (method)); \
			g_warning ( \
				"Error message was: %s", \
				((error))->message); \
		} \
	} else { \
		if ((error) == NULL) { \
			g_warning ( \
				"%s::%s() reported failure " \
				"without setting its GError", \
				G_OBJECT_TYPE_NAME (object), \
				G_STRINGIFY (method)); \
		} \
	} \
	} G_STMT_END
/**
 * camel_pointer_tracker_track:
 * @ptr: pointer to add to pointer tracker
 *
 * Adds pointer 'ptr' to pointer tracker. Usual use case is to add object
 * to the tracker in GObject::init and remove it from tracker within
 * GObject::finalize. Since the tracker's functions are called, the application
 * prints summary of the pointers on console on exit. If everything gone right
 * then it prints message about all tracked pointers were removed. Otherwise
 * it prints summary of left pointers in the tracker. Added pointer should
 * be removed with pair function camel_pointer_tracker_untrack().
 *
 * See camel_pointer_tracker_dump(), camel_pointer_tracker_track_with_info().
 *
 * Since: 3.6
 **/
#define camel_pointer_tracker_track(ptr) \
	(camel_pointer_tracker_track_with_info ((ptr), G_STRFUNC))

void		camel_pointer_tracker_track_with_info
						(gpointer ptr,
						 const gchar *info);
void		camel_pointer_tracker_untrack	(gpointer ptr);
void		camel_pointer_tracker_dump	(void);

GString *	camel_debug_get_backtrace	(void);
GString *	camel_debug_get_raw_backtrace	(void);
void		camel_debug_demangle_backtrace	(GString *bt);

void		camel_debug_ref_unref_push_backtrace
						(const GString *backtrace,
						 guint object_ref_count);
void		camel_debug_ref_unref_push_backtrace_for_object
						(gpointer _object);
void		camel_debug_ref_unref_dump_backtraces
						(void);

G_END_DECLS

#endif /* CAMEL_DEBUG_H */
