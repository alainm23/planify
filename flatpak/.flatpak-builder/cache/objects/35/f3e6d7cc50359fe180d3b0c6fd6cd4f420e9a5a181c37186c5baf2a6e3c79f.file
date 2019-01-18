/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Evolution calendar factory
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

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_DATA_CAL_FACTORY_H
#define E_DATA_CAL_FACTORY_H

#include <libebackend/libebackend.h>

/* Standard GObject macros */
#define E_TYPE_DATA_CAL_FACTORY \
	(e_data_cal_factory_get_type ())
#define E_DATA_CAL_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_DATA_CAL_FACTORY, EDataCalFactory))
#define E_DATA_CAL_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_DATA_CAL_FACTORY,  EDataCalFactoryClass))
#define E_IS_DATA_CAL_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_DATA_CAL_FACTORY))
#define E_IS_DATA_CAL_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_DATA_CAL_FACTORY))
#define E_DATA_CAL_FACTORY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_DATA_CAL_FACTORY, EDataCalFactoryClass))

/**
 * EDS_CALENDAR_MODULES:
 *
 * This environment variable configures where the calendar
 * factory loads its backend modules from.
 */
#define EDS_CALENDAR_MODULES    "EDS_CALENDAR_MODULES"

/**
 * EDS_SUBPROCESS_CAL_PATH:
 *
 * This environment variable configures where the calendar
 * factory subprocess is located in.
 */
#define EDS_SUBPROCESS_CAL_PATH "EDS_SUBPROCESS_CAL_PATH"

G_BEGIN_DECLS

typedef struct _EDataCalFactory EDataCalFactory;
typedef struct _EDataCalFactoryClass EDataCalFactoryClass;
typedef struct _EDataCalFactoryPrivate EDataCalFactoryPrivate;

struct _EDataCalFactory {
	EDataFactory parent;
	EDataCalFactoryPrivate *priv;
};

struct _EDataCalFactoryClass {
	EDataFactoryClass parent_class;
};

GType		e_data_cal_factory_get_type	(void);
EDBusServer *	e_data_cal_factory_new		(gint backend_per_process,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* E_DATA_CAL_FACTORY_H */
