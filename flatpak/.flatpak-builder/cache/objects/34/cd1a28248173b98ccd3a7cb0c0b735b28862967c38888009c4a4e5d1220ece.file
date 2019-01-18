/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_WEAK_REF_GROUP_H
#define CAMEL_WEAK_REF_GROUP_H

#include <glib-object.h>

#define CAMEL_TYPE_WEAK_REF_GROUP (camel_weak_ref_group_get_type ())

G_BEGIN_DECLS

typedef struct _CamelWeakRefGroup CamelWeakRefGroup;

GType		camel_weak_ref_group_get_type	(void) G_GNUC_CONST;
CamelWeakRefGroup *
		camel_weak_ref_group_new	(void);
CamelWeakRefGroup *
		camel_weak_ref_group_ref	(CamelWeakRefGroup *group);
void		camel_weak_ref_group_unref	(CamelWeakRefGroup *group);

void		camel_weak_ref_group_set	(CamelWeakRefGroup *group,
						 gpointer object);
gpointer	camel_weak_ref_group_get	(CamelWeakRefGroup *group);

G_END_DECLS

#endif /* CAMEL_WEAK_REF_GROUP_H */
