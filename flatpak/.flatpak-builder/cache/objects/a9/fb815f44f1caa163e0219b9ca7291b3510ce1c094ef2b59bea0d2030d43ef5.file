/* -*- Mode: C; indent-tabs-mode: t; c-basic-offset: 8; tab-width: 8 -*- */
/* e-cal-backend-factory.h
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
 * Authors: Chris Toshok <toshok@ximian.com>
 */

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_CAL_BACKEND_FACTORY_H
#define E_CAL_BACKEND_FACTORY_H

#include <libical/ical.h>
#include <libebackend/libebackend.h>

/* Standard GObject macros */
#define E_TYPE_CAL_BACKEND_FACTORY \
	(e_cal_backend_factory_get_type ())
#define E_CAL_BACKEND_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CAL_BACKEND_FACTORY, ECalBackendFactory))
#define E_CAL_BACKEND_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CAL_BACKEND_FACTORY, ECalBackendFactoryClass))
#define E_IS_CAL_BACKEND_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CAL_BACKEND_FACTORY))
#define E_IS_CAL_BACKEND_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CAL_BACKEND_FACTORY))
#define E_CAL_BACKEND_FACTORY_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CAL_BACKEND_FACTORY, ECalBackendFactoryClass))

G_BEGIN_DECLS

typedef struct _ECalBackendFactory ECalBackendFactory;
typedef struct _ECalBackendFactoryClass ECalBackendFactoryClass;
typedef struct _ECalBackendFactoryPrivate ECalBackendFactoryPrivate;

/**
 * ECalBackendFactory:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 */
struct _ECalBackendFactory {
	/*< private >*/
	EBackendFactory parent;
	ECalBackendFactoryPrivate *priv;
};

/**
 * ECalBackendFactoryClass:
 * @factory_name: The string identifier for this book backend type
 * @component_kind: The type if component this calendar backend should be created for
 * @backend_type: The #GType to use to build #EBookBackends for this factory
 *
 * Class structure for the #ECalBackendFactory class.
 *
 * Subclasses need to set the factory name and backend type
 * at initialization, the base class will take care of creating
 * backends of the specified type on demand.
 */
struct _ECalBackendFactoryClass {
	/*< private >*/
	EBackendFactoryClass parent_class;

	/*< public >*/
	/* Subclasses just need to set these
	 * class members, we handle the rest. */
	const gchar *factory_name;
	icalcomponent_kind component_kind;
	GType backend_type;
};

GType		e_cal_backend_factory_get_type		(void) G_GNUC_CONST;

G_END_DECLS

#endif /* E_CAL_BACKEND_FACTORY_H */
