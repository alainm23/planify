/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2012 Intel Corporation
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
 * Authors: Rodrigo Moya <rodrigo@ximian.com>
 *          Tristan Van Berkom <tristanvb@openismus.com>
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_DATA_SERVER_UTIL_H
#define E_DATA_SERVER_UTIL_H

#include <sys/types.h>
#include <gio/gio.h>

#include <libedataserver/e-source-enums.h>

G_BEGIN_DECLS

struct tm;
struct _ESource;
struct _ESourceRegistry;

const gchar *	e_get_user_cache_dir		(void);
const gchar *	e_get_user_config_dir		(void);
const gchar *	e_get_user_data_dir		(void);

gboolean	e_util_strv_equal		(gconstpointer v1,
						 gconstpointer v2);
gchar *		e_util_strdup_strip		(const gchar *string);
gint		e_util_strcmp0			(const gchar *str1,
						 const gchar *str2);
gchar *		e_util_strstrcase		(const gchar *haystack,
						 const gchar *needle);
gchar *		e_util_unicode_get_utf8		(const gchar *text,
						 gunichar *out);
const gchar *	e_util_utf8_strstrcase		(const gchar *haystack,
						 const gchar *needle);
const gchar *	e_util_utf8_strstrcasedecomp	(const gchar *haystack,
						 const gchar *needle);
gint		e_util_utf8_strcasecmp		(const gchar *s1,
						 const gchar *s2);
gchar *		e_util_utf8_remove_accents	(const gchar *str);
gchar *		e_util_utf8_decompose		(const gchar *text);
gchar *		e_util_utf8_make_valid		(const gchar *str);
gchar *		e_util_utf8_data_make_valid	(const gchar *data,
						 gsize data_bytes);
gchar *         e_util_utf8_normalize           (const gchar *str);
const gchar *   e_util_ensure_gdbus_string	(const gchar *str,
						 gchar **gdbus_str);
guint64		e_util_gthread_id		(GThread *thread);
void		e_filename_make_safe		(gchar *string);
gchar *		e_filename_mkdir_encoded	(const gchar *basepath,
						 const gchar *fileprefix,
						 const gchar *filename,
						 gint fileindex);

gsize		e_utf8_strftime			(gchar *string,
						 gsize max,
						 const gchar *fmt,
						 const struct tm *tm);
gsize		e_strftime			(gchar *string,
						 gsize max,
						 const gchar *fmt,
						 const struct tm *tm);

gchar **	e_util_slist_to_strv		(const GSList *strings);
GSList *	e_util_strv_to_slist		(const gchar * const *strv);
void		e_util_free_nullable_object_slist
						(GSList *objects);
void		e_util_safe_free_string		(gchar *str);

void		e_queue_transfer		(GQueue *src_queue,
						 GQueue *dst_queue);
GWeakRef *	e_weak_ref_new			(gpointer object);
void		e_weak_ref_free			(GWeakRef *weak_ref);

gboolean	e_file_recursive_delete_sync	(GFile *file,
						 GCancellable *cancellable,
						 GError **error);
void		e_file_recursive_delete		(GFile *file,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_file_recursive_delete_finish	(GFile *file,
						 GAsyncResult *result,
						 GError **error);

GBinding *	e_binding_bind_property		(gpointer source,
						 const gchar *source_property,
						 gpointer target,
						 const gchar *target_property,
						 GBindingFlags flags);
GBinding *	e_binding_bind_property_full	(gpointer source,
						 const gchar *source_property,
						 gpointer target,
						 const gchar *target_property,
						 GBindingFlags flags,
						 GBindingTransformFunc transform_to,
						 GBindingTransformFunc transform_from,
						 gpointer user_data,
						 GDestroyNotify notify);
GBinding *	e_binding_bind_property_with_closures
						(gpointer source,
						 const gchar *source_property,
						 gpointer target,
						 const gchar *target_property,
						 GBindingFlags flags,
						 GClosure *transform_to,
						 GClosure *transform_from);
/* Useful GBinding transform functions */
gboolean	e_binding_transform_enum_value_to_nick
						(GBinding *binding,
						 const GValue *source_value,
						 GValue *target_value,
						 gpointer not_used);
gboolean	e_binding_transform_enum_nick_to_value
						(GBinding *binding,
						 const GValue *source_value,
						 GValue *target_value,
						 gpointer not_used);

gboolean	e_enum_from_string		(GType enum_type,
						 const gchar *string,
						 gint *enum_value);
const gchar *	e_enum_to_string		(GType enum_type,
						 gint enum_value);

typedef struct _EAsyncClosure EAsyncClosure;

EAsyncClosure *	e_async_closure_new		(void);
GAsyncResult *	e_async_closure_wait		(EAsyncClosure *closure);
void		e_async_closure_free		(EAsyncClosure *closure);
void		e_async_closure_callback	(GObject *object,
						 GAsyncResult *result,
						 gpointer closure);

#ifdef G_OS_WIN32
const gchar *	e_util_get_prefix		(void) G_GNUC_CONST;
const gchar *	e_util_get_cp_prefix		(void) G_GNUC_CONST;
const gchar *	e_util_get_localedir		(void) G_GNUC_CONST;
gchar *		e_util_replace_prefix		(const gchar *configure_time_prefix,
						 const gchar *runtime_prefix,
						 const gchar *configure_time_path);
void		e_util_win32_initialize		(void);
#endif

/* utility functions for easier processing of named parameters */

/**
 * ENamedParameters:
 *
 * Since: 3.8
 **/
struct _ENamedParameters;
typedef struct _ENamedParameters ENamedParameters;

#define E_TYPE_NAMED_PARAMETERS (e_named_parameters_get_type ())

GType           e_named_parameters_get_type     (void) G_GNUC_CONST;
ENamedParameters *
		e_named_parameters_new		(void);
ENamedParameters *
		e_named_parameters_new_strv	(const gchar * const *strv);
ENamedParameters *
		e_named_parameters_new_string	(const gchar *str);
ENamedParameters *
		e_named_parameters_new_clone	(const ENamedParameters *parameters);
void		e_named_parameters_free		(ENamedParameters *parameters);
void		e_named_parameters_clear	(ENamedParameters *parameters);
void		e_named_parameters_assign	(ENamedParameters *parameters,
						 const ENamedParameters *from);
void		e_named_parameters_set		(ENamedParameters *parameters,
						 const gchar *name,
						 const gchar *value);
const gchar *	e_named_parameters_get		(const ENamedParameters *parameters,
						 const gchar *name);
gchar **	e_named_parameters_to_strv	(const ENamedParameters *parameters);
gchar *		e_named_parameters_to_string	(const ENamedParameters *parameters);
gboolean	e_named_parameters_test		(const ENamedParameters *parameters,
						 const gchar *name,
						 const gchar *value,
						 gboolean case_sensitively);
gboolean	e_named_parameters_exists	(const ENamedParameters *parameters,
						 const gchar *name);
guint		e_named_parameters_count	(const ENamedParameters *parameters);
gchar *		e_named_parameters_get_name	(const ENamedParameters *parameters,
						 gint index);

#define e_named_timeout_add(interval, function, data) \
	(e_timeout_add_with_name ( \
		G_PRIORITY_DEFAULT, (interval), \
		"[" PACKAGE "] " G_STRINGIFY (function), \
		(function), (data), NULL))

#define e_named_timeout_add_full(priority, interval, function, data, notify) \
	(e_timeout_add_with_name ( \
		(priority), (interval), \
		"[" PACKAGE "] " G_STRINGIFY (function), \
		(function), (data), (notify)))

#define e_named_timeout_add_seconds(interval, function, data) \
	(e_timeout_add_seconds_with_name ( \
		G_PRIORITY_DEFAULT, (interval), \
		"[" PACKAGE "] " G_STRINGIFY (function), \
		(function), (data), NULL))

#define e_named_timeout_add_seconds_full(priority, interval, function, data, notify) \
	(e_timeout_add_seconds_with_name ( \
		(priority), (interval), \
		"[" PACKAGE "] " G_STRINGIFY (function), \
		(function), (data), (notify)))

guint		e_timeout_add_with_name		(gint priority,
						 guint interval,
						 const gchar *name,
						 GSourceFunc function,
						 gpointer data,
						 GDestroyNotify notify);
guint		e_timeout_add_seconds_with_name	(gint priority,
						 guint interval,
						 const gchar *name,
						 GSourceFunc function,
						 gpointer data,
						 GDestroyNotify notify);

#ifndef EDS_DISABLE_DEPRECATED
void		e_util_free_string_slist	(GSList *strings);
void		e_util_free_object_slist	(GSList *objects);
GSList *	e_util_copy_string_slist	(GSList *copy_to,
						 const GSList *strings);
GSList *	e_util_copy_object_slist	(GSList *copy_to,
						 const GSList *objects);
gint		e_data_server_util_get_dbus_call_timeout
						(void);
void		e_data_server_util_set_dbus_call_timeout
						(gint timeout_msec);

#endif /* EDS_DISABLE_DEPRECATED */

gboolean	e_source_registry_debug_enabled	(void);
void		e_source_registry_debug_print	(const gchar *format,
						 ...) G_GNUC_PRINTF (1, 2);
void		e_util_debug_print		(const gchar *domain,
						 const gchar *format,
						 ...) G_GNUC_PRINTF (2, 3);
void		e_util_debug_printv		(const gchar *domain,
						 const gchar *format,
						 va_list args);

/**
 * ETypeFunc:
 * @type: a #GType
 * @user_data: user data passed to e_type_traverse()
 *
 * Specifies the type of functions passed to e_type_traverse().
 *
 * Since: 3.4
 **/
typedef void	(*ETypeFunc)			(GType type,
						 gpointer user_data);
void		e_type_traverse			(GType parent_type,
						 ETypeFunc func,
						 gpointer user_data);

gchar *		e_util_get_source_full_name	(struct _ESourceRegistry *registry,
						 struct _ESource *source);

void		e_util_unref_in_thread		(gpointer object);

gchar *		e_util_generate_uid		(void);

gboolean	e_util_identity_can_send	(struct _ESourceRegistry *registry,
						 struct _ESource *identity_source);
gboolean	e_util_can_use_collection_as_credential_source
						(struct _ESource *collection_source,
						 struct _ESource *child_source);

G_END_DECLS

#endif /* E_DATA_SERVER_UTIL_H */
