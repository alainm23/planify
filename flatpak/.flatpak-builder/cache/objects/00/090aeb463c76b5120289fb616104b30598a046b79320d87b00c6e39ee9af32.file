/* Evolution calendar - iCalendar file backend
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
 * Authors: Federico Mena-Quintero <federico@ximian.com>
 */

#ifndef E_CAL_BACKEND_HTTP_H
#define E_CAL_BACKEND_HTTP_H

#include <libedata-cal/libedata-cal.h>

#define E_TYPE_CAL_BACKEND_HTTP \
	(e_cal_backend_http_get_type ())
#define E_CAL_BACKEND_HTTP(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_BACKEND_HTTP, ECalBackendHttp))
#define E_CAL_BACKEND_HTTP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_BACKEND_HTTP, ECalBackendHttpClass))
#define E_IS_CAL_BACKEND_HTTP(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_BACKEND_HTTP))
#define E_IS_CAL_BACKEND_HTTP_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_BACKEND_HTTP))
#define E_CAL_BACKEND_HTTP_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_BACKEND_HTTP, ECalBackendHttpClass))

G_BEGIN_DECLS

typedef struct _ECalBackendHttp ECalBackendHttp;
typedef struct _ECalBackendHttpClass ECalBackendHttpClass;
typedef struct _ECalBackendHttpPrivate ECalBackendHttpPrivate;

struct _ECalBackendHttp {
	ECalMetaBackend backend;
	ECalBackendHttpPrivate *priv;
};

struct _ECalBackendHttpClass {
	ECalMetaBackendClass parent_class;
};

GType		e_cal_backend_http_get_type	(void);

G_END_DECLS

#endif /* E_CAL_BACKEND_HTTP_H */
