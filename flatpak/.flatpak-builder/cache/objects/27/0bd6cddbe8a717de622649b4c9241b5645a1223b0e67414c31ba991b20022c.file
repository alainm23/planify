/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2008 Novell, Inc.
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
 */

/* Manages bags of weakly-referenced GObjects. */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_OBJECT_BAG_H
#define CAMEL_OBJECT_BAG_H

#include <glib.h>

G_BEGIN_DECLS

typedef struct _CamelObjectBag CamelObjectBag;
typedef gpointer (*CamelCopyFunc) (gconstpointer object);

CamelObjectBag *camel_object_bag_new		(GHashFunc key_hash_func,
						 GEqualFunc key_equal_func,
						 CamelCopyFunc key_copy_func,
						 GFreeFunc key_free_func);
gpointer	camel_object_bag_get		(CamelObjectBag *bag,
						 gconstpointer key);
gpointer	camel_object_bag_peek		(CamelObjectBag *bag,
						 gconstpointer key);
gpointer	camel_object_bag_reserve	(CamelObjectBag *bag,
						 gconstpointer key);
void		camel_object_bag_add		(CamelObjectBag *bag,
						 gconstpointer key,
						 gpointer object);
void		camel_object_bag_abort		(CamelObjectBag *bag,
						 gconstpointer key);
void		camel_object_bag_rekey		(CamelObjectBag *bag,
						 gpointer object,
						 gconstpointer new_key);
GPtrArray *	camel_object_bag_list		(CamelObjectBag *bag);
void		camel_object_bag_remove		(CamelObjectBag *bag,
						 gpointer object);
void		camel_object_bag_destroy	(CamelObjectBag *bag);

G_END_DECLS

#endif /* CAMEL_OBJECT_BAG_H */
