/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*-
 *
 * Copyright (C) 2018 Matthias Klumpp <matthias@tenstral.net>
 *
 * Licensed under the GNU Lesser General Public License Version 2.1
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the license, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#if !defined (__APPSTREAM_H) && !defined (AS_COMPILATION)
#error "Only <appstream.h> can be included directly."
#endif

#ifndef __AS_RELATION_H
#define __AS_RELATION_H

#include <glib-object.h>

G_BEGIN_DECLS

#define AS_TYPE_RELATION (as_relation_get_type ())
G_DECLARE_DERIVABLE_TYPE (AsRelation, as_relation, AS, RELATION, GObject)

struct _AsRelationClass
{
	GObjectClass		parent_class;
	/*< private >*/
	void (*_as_reserved1)	(void);
	void (*_as_reserved2)	(void);
	void (*_as_reserved3)	(void);
	void (*_as_reserved4)	(void);
	void (*_as_reserved5)	(void);
	void (*_as_reserved6)	(void);
};

/**
 * AsRelationKind:
 * @AS_RELATION_KIND_UNKNOWN:		Unknown kind
 * @AS_RELATION_KIND_REQUIRES:		The referenced item is required by the component
 * @AS_RELATION_KIND_RECOMMENDS:	The referenced item is recommended
 *
 * Type of a component's relation to other items.
 **/
typedef enum  {
	AS_RELATION_KIND_UNKNOWN,
	AS_RELATION_KIND_REQUIRES,
	AS_RELATION_KIND_RECOMMENDS,
	/*< private >*/
	AS_RELATION_KIND_LAST
} AsRelationKind;

/**
 * AsRelationItemKind:
 * @AS_RELATION_ITEM_KIND_UNKNOWN:	Unknown kind
 * @AS_RELATION_ITEM_KIND_ID:		A component ID
 * @AS_RELATION_ITEM_KIND_MODALIAS:	A hardware modalias
 * @AS_RELATION_ITEM_KIND_KERNEL:	An operating system kernel (like Linux)
 * @AS_RELATION_ITEM_KIND_MEMORY:	A system RAM requirement
 *
 * Type of the item an #AsRelation is for.
 **/
typedef enum  {
	AS_RELATION_ITEM_KIND_UNKNOWN,
	AS_RELATION_ITEM_KIND_ID,
	AS_RELATION_ITEM_KIND_MODALIAS,
	AS_RELATION_ITEM_KIND_KERNEL,
	AS_RELATION_ITEM_KIND_MEMORY,
	/*< private >*/
	AS_RELATION_ITEM_KIND_LAST
} AsRelationItemKind;

/**
 * AsRelationCompare:
 * @AS_RELATION_COMPARE_UNKNOWN:	Comparison predicate invalid or not known
 * @AS_RELATION_COMPARE_EQ:		Equal to
 * @AS_RELATION_COMPARE_NE:		Not equal to
 * @AS_RELATION_COMPARE_LT:		Less than
 * @AS_RELATION_COMPARE_GT:		Greater than
 * @AS_RELATION_COMPARE_LE:		Less than or equal to
 * @AS_RELATION_COMPARE_GE:		Greater than or equal to
 *
 * The relational comparison type.
 **/
typedef enum {
	AS_RELATION_COMPARE_UNKNOWN,
	AS_RELATION_COMPARE_EQ,
	AS_RELATION_COMPARE_NE,
	AS_RELATION_COMPARE_LT,
	AS_RELATION_COMPARE_GT,
	AS_RELATION_COMPARE_LE,
	AS_RELATION_COMPARE_GE,
	/*< private >*/
	AS_RELATION_COMPARE_LAST
} AsRelationCompare;

const gchar		*as_relation_kind_to_string (AsRelationKind kind);
AsRelationKind		as_relation_kind_from_string (const gchar *kind_str);

const gchar		*as_relation_item_kind_to_string (AsRelationItemKind kind);
AsRelationItemKind	as_relation_item_kind_from_string (const gchar *kind_str);

AsRelationCompare	as_relation_compare_from_string (const gchar *compare_str);
const gchar		*as_relation_compare_to_string (AsRelationCompare compare);
const gchar		*as_relation_compare_to_symbols_string (AsRelationCompare compare);

AsRelation		*as_relation_new (void);

AsRelationKind		as_relation_get_kind (AsRelation *relation);
void			as_relation_set_kind (AsRelation *relation,
						AsRelationKind kind);

AsRelationItemKind	as_relation_get_item_kind (AsRelation *relation);
void			as_relation_set_item_kind (AsRelation *relation,
						   AsRelationItemKind kind);

AsRelationCompare	as_relation_get_compare (AsRelation *relation);
void			as_relation_set_compare (AsRelation *relation,
						 AsRelationCompare compare);

const gchar		*as_relation_get_version (AsRelation *relation);
void			as_relation_set_version (AsRelation *relation,
						  const gchar *version);

const gchar		*as_relation_get_value (AsRelation *relation);
gint			as_relation_get_value_int (AsRelation *relation);
void			as_relation_set_value (AsRelation *relation,
					        const gchar *value);

gboolean		as_relation_version_compare (AsRelation *relation,
						     const gchar *version,
						     GError **error);

G_END_DECLS

#endif /* __AS_RELATION_H */
