/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Evolution calendar - generic backend class
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
 * Authors: Rodrigo Moya <rodrigo@ximian.com>
 */

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_CAL_BACKEND_UTIL_H
#define E_CAL_BACKEND_UTIL_H

#include <libedataserver/libedataserver.h>

#include <libedata-cal/e-cal-backend.h>

G_BEGIN_DECLS

/*
 * Functions for accessing mail configuration
 */

gboolean	e_cal_backend_mail_account_get_default
						(ESourceRegistry *registry,
						 gchar **address,
						 gchar **name);
gboolean	e_cal_backend_mail_account_is_valid
						(ESourceRegistry *registry,
						 const gchar *user,
						 gchar **name);
gboolean	e_cal_backend_user_declined	(ESourceRegistry *registry,
                                                 icalcomponent *icalcomp);

G_END_DECLS

#endif /* E_CAL_BACKEND_UTIL_H */
