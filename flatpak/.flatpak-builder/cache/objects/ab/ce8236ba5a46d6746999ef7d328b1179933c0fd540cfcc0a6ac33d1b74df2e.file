/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_XML_HASH_UTILS_H
#define E_XML_HASH_UTILS_H

#include <glib.h>
#include <libxml/parser.h>

G_BEGIN_DECLS

/**
 * EXmlHashType:
 * @E_XML_HASH_TYPE_OBJECT_UID: Use the object UID as the hash key.
 * @E_XML_HASH_TYPE_PROPERTY: Use the property name as the hash key.
 **/
typedef enum {
	E_XML_HASH_TYPE_OBJECT_UID,
	E_XML_HASH_TYPE_PROPERTY
} EXmlHashType;

GHashTable *	e_xml_to_hash			(xmlDoc *doc,
						 EXmlHashType type);
xmlDoc *	e_xml_from_hash			(GHashTable *hash,
						 EXmlHashType type,
						 const gchar *root_name);
void		e_xml_destroy_hash		(GHashTable *hash);

/**
 * EXmlHashStatus:
 * @E_XMLHASH_STATUS_SAME: The compared values are the same.
 * @E_XMLHASH_STATUS_DIFFERENT: The compared values are different.
 * @E_XMLHASH_STATUS_NOT_FOUND: The key to compare against was not found.
 **/
typedef enum {
	E_XMLHASH_STATUS_SAME,
	E_XMLHASH_STATUS_DIFFERENT,
	E_XMLHASH_STATUS_NOT_FOUND
} EXmlHashStatus;

typedef void		(*EXmlHashFunc)		(const gchar *key,
						 const gchar *value,
						 gpointer user_data);
typedef gboolean	(*EXmlHashRemoveFunc)	(const gchar *key,
						 const gchar *value,
						 gpointer user_data);

typedef struct EXmlHash EXmlHash;

EXmlHash *	e_xmlhash_new			(const gchar *filename);
void		e_xmlhash_add			(EXmlHash *hash,
						 const gchar *key,
						 const gchar *data);
void		e_xmlhash_remove		(EXmlHash *hash,
						 const gchar *key);
EXmlHashStatus	e_xmlhash_compare		(EXmlHash *hash,
						 const gchar *key,
						 const gchar *compare_data);
void		e_xmlhash_foreach_key		(EXmlHash *hash,
						 EXmlHashFunc func,
						 gpointer user_data);
void		e_xmlhash_foreach_key_remove	(EXmlHash *hash,
						 EXmlHashRemoveFunc func,
						 gpointer user_data);
void		e_xmlhash_write			(EXmlHash *hash);
void		e_xmlhash_destroy		(EXmlHash *hash);

G_END_DECLS

#endif /* E_XML_HASH_UTILS_H */
