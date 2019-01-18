/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-debug-log.h: Ring buffer for logging debug messages
 *
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
 * Authors: Federico Mena-Quintero <federico@novell.com>
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_DEBUG_LOG_H
#define E_DEBUG_LOG_H

#include <glib.h>

/**
 * E_DEBUG_LOG_DOMAIN_USER:
 *
 * Since: 2.32
 **/
#define E_DEBUG_LOG_DOMAIN_USER "USER" /* always enabled */

/**
 * E_DEBUG_LOG_DOMAIN_GLOG:
 *
 * Since: 2.32
 **/
#define E_DEBUG_LOG_DOMAIN_GLOG "GLog" /* used for GLog messages; don't use it yourself */

/**
 * E_DEBUG_LOG_DOMAIN_CAL_QUERIES:
 *
 * Since: 2.32
 **/
#define E_DEBUG_LOG_DOMAIN_CAL_QUERIES "CalQueries" /* used for calendar queries analysis */

G_BEGIN_DECLS

void		e_debug_log			(gboolean is_milestone,
						 const gchar *domain,
						 const gchar *format,
						 ...);
void		e_debug_logv			(gboolean is_milestone,
						 const gchar *domain,
						 const gchar *format,
						 va_list args);
gboolean	e_debug_log_load_configuration	(const gchar *filename,
						 GError **error);
void		e_debug_log_enable_domains	(const gchar **domains,
						 gint n_domains);
void		e_debug_log_disable_domains	(const gchar **domains,
						 gint n_domains);
gboolean	e_debug_log_is_domain_enabled	(const gchar *domain);
gboolean	e_debug_log_dump		(const gchar *filename,
						 GError **error);
gboolean	e_debug_log_dump_to_dated_file	(GError **error);
void		e_debug_log_set_max_lines	(gint num_lines);
gint		e_debug_log_get_max_lines	(void);

/* For testing only */
void		e_debug_log_clear		(void);

G_END_DECLS

#endif /* E_DEBUG_LOG_H */

