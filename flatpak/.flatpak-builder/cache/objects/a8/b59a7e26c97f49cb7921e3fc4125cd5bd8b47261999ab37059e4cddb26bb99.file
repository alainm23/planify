/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2014 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__LIBEDATA_CAL_H_INSIDE__) && !defined (LIBEDATA_CAL_COMPILATION)
#error "Only <libedata-cal/libedata-cal.h> should be included directly."
#endif

#ifndef E_SUBPROCESS_CAL_FACTORY_H
#define E_SUBPROCESS_CAL_FACTORY_H

#include <libebackend/libebackend.h>

/* Standard GObject macros */
#define E_TYPE_SUBPROCESS_CAL_FACTORY \
	(e_subprocess_cal_factory_get_type ())
#define E_SUBPROCESS_CAL_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SUBPROCESS_CAL_FACTORY, ESubprocessCalFactory))
#define E_SUBPROCESS_CAL_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SUBPROCESS_CAL_FACTORY, ESubprocessCalFactoryClass))
#define E_IS_SUBPROCESS_CAL_FACTORY(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SUBPROCESS_CAL_FACTORY))
#define E_IS_SUBPROCESS_CAL_FACTORY_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SUBPROCESS_CAL_FACTORY))
#define E_SUBPROCESS_CAL_FACTORY_GET_CLASS(cls) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SUBPROCESS_CAL_FACTORY, ESubprocessCalFactoryClass))

G_BEGIN_DECLS

typedef struct _ESubprocessCalFactory ESubprocessCalFactory;
typedef struct _ESubprocessCalFactoryClass ESubprocessCalFactoryClass;
typedef struct _ESubprocessCalFactoryPrivate ESubprocessCalFactoryPrivate;

struct _ESubprocessCalFactory {
	ESubprocessFactory parent;
	ESubprocessCalFactoryPrivate *priv;
};

struct _ESubprocessCalFactoryClass {
	ESubprocessFactoryClass parent_class;
};

GType		e_subprocess_cal_factory_get_type	(void) G_GNUC_CONST;
ESubprocessCalFactory *
		e_subprocess_cal_factory_new		(GCancellable *cancellable,
							 GError **error);

G_END_DECLS

#endif /* E_SUBPROCESS_CAL_FACTORY_H */
