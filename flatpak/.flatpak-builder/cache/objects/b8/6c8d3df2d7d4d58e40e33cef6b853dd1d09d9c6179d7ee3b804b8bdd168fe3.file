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

#include "evolution-data-server-config.h"

#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <libxml/entities.h>
#include <libxml/tree.h>
#include <libxml/xmlmemory.h>

#include <glib/gstdio.h>

#include "e-xml-hash-utils.h"
#include "e-xml-utils.h"

/**
 * e_xml_to_hash:
 * @doc: The #xmlDoc to store in a hash table.
 * @type: The value type to use as a key in the hash table.
 *
 * Creates a #GHashTable representation of the #xmlDoc @doc.
 * If @type is * @E_XML_HASH_TYPE_PROPERTY, all XML nodes will be
 * indexed in the #GHashTable by name. If @type is
 * %E_XML_HASH_TYPE_OBJECT_UID, then XML objects will be indexed in
 * the hash by their UID (other nodes will still be indexed by name).
 *
 * Returns: (transfer full) (element-type utf8 utf8): The newly-created #GHashTable representation
 * of @doc.
 **/
GHashTable *
e_xml_to_hash (xmlDoc *doc,
               EXmlHashType type)
{
	xmlNode *root, *node;
	xmlChar *key, *value;
	GHashTable *hash;

	hash = g_hash_table_new (g_str_hash, g_str_equal);

	root = xmlDocGetRootElement (doc);
	for (node = root->xmlChildrenNode; node; node = node->next) {
		if (node->name == NULL || node->type != XML_ELEMENT_NODE)
			continue;

		if (type == E_XML_HASH_TYPE_OBJECT_UID &&
		    !strcmp ((gchar *) node->name, "object"))
			key = xmlGetProp (node, (xmlChar *)"uid");
		else
			key = xmlStrdup (node->name);

		if (!key) {
			g_warning ("Key not found!!");
			continue;
		}

		value = xmlNodeListGetString (doc, node->xmlChildrenNode, 1);
		if (!value) {
			xmlFree (key);
			g_warning ("Found a key with no value!!");
			continue;
		}

		g_hash_table_insert (
			hash, g_strdup ((gchar *) key),
			g_strdup ((gchar *) value));

		xmlFree (key);
		xmlFree (value);
	}

	return hash;
}

struct save_data {
	EXmlHashType type;
	xmlDoc *doc;
	xmlNode *root;
};

static void
foreach_save_func (gpointer key,
                   gpointer value,
                   gpointer user_data)
{
	struct save_data *sd = user_data;
	xmlNodePtr new_node;
	xmlChar *enc;

	if (sd->type == E_XML_HASH_TYPE_OBJECT_UID) {
		new_node = xmlNewNode (NULL, (xmlChar *)"object");
		xmlNewProp (new_node, (xmlChar *)"uid", (const xmlChar *) key);
	} else
		new_node = xmlNewNode (NULL, (const xmlChar *) key);

	enc = xmlEncodeEntitiesReentrant (sd->doc, value);
	xmlNodeSetContent (new_node, enc);
	xmlFree (enc);

	xmlAddChild (sd->root, new_node);
}

/**
 * e_xml_from_hash: (skip)
 * @hash: (element-type utf8 utf8): The #GHashTable to extract the XML from
 * @type: The #EXmlHashType used to store the XML
 * @root_name: The name to call the new #xmlDoc
 *
 * Uses the key/value pair representation of an XML structure in @hash
 * to build an equivalent #xmlDoc. This is the reverse of e_xml_to_hash().
 *
 * Returns: (transfer full): the #xmlDoc created from the data in @hash
 **/
xmlDoc *
e_xml_from_hash (GHashTable *hash,
                 EXmlHashType type,
                 const gchar *root_name)
{
	xmlDoc *doc;
	struct save_data sd;

	doc = xmlNewDoc ((xmlChar *)"1.0");
	doc->encoding = xmlStrdup ((xmlChar *)"UTF-8");
	sd.type = type;
	sd.doc = doc;
	sd.root = xmlNewDocNode (doc, NULL, (xmlChar *) root_name, NULL);
	xmlDocSetRootElement (doc, sd.root);

	g_hash_table_foreach (hash, foreach_save_func, &sd);
	return doc;
}

static void
free_values (gpointer key,
             gpointer value,
             gpointer data)
{
	g_free (key);
	g_free (value);
}

/**
 * e_xml_destroy_hash:
 * @hash: (element-type utf8 utf8): the #GHashTable to destroy
 *
 * Frees the memory used by @hash and its contents.
 **/
void
e_xml_destroy_hash (GHashTable *hash)
{
	g_hash_table_foreach (hash, free_values, NULL);
	g_hash_table_destroy (hash);
}

/**
 * EXmlHash:
 *
 * A hash table representation of an XML file.
 **/
struct EXmlHash {
	gchar *filename;
	GHashTable *objects;
};

/**
 * e_xmlhash_new: (skip)
 * @filename: the name of an XML file
 *
 * Creates a new #EXmlHash from the file @filename. If @filename does
 * not already exist, an empty #EXmlHash will be created.
 *
 * Returns: (transfer full): The new #EXmlHash structure, or %NULL if unable to parse
 *          @filename.
 **/
EXmlHash *
e_xmlhash_new (const gchar *filename)
{
	EXmlHash *hash;
	xmlDoc *doc = NULL;

	g_return_val_if_fail (filename != NULL, NULL);

	hash = g_new0 (EXmlHash, 1);
	hash->filename = g_strdup (filename);

	if (g_file_test (filename, G_FILE_TEST_EXISTS)) {
		doc = e_xml_parse_file (filename);
		if (!doc) {
			e_xmlhash_destroy (hash);

			return NULL;
		}
		hash->objects = e_xml_to_hash (doc, E_XML_HASH_TYPE_OBJECT_UID);
		xmlFreeDoc (doc);
	} else {
		hash->objects = g_hash_table_new (g_str_hash, g_str_equal);
	}

	return hash;
}

/**
 * e_xmlhash_add:
 * @hash: the #EXmlHash to add an entry to
 * @key: the key to use for the entry
 * @data: the value of the new entry
 *
 * Adds a new key/value pair to the #EXmlHash @hash.
 **/
void
e_xmlhash_add (EXmlHash *hash,
               const gchar *key,
               const gchar *data)
{
	g_return_if_fail (hash != NULL);
	g_return_if_fail (key != NULL);
	g_return_if_fail (data != NULL);

	e_xmlhash_remove (hash, key);
	g_hash_table_insert (hash->objects, g_strdup (key), g_strdup (data));
}

/**
 * e_xmlhash_remove:
 * @hash: the #EXmlHash to remove an entry from
 * @key: the key of the entry to remove
 *
 * Remove the entry in @hash with key equal to @key, if it exists.
 **/
void
e_xmlhash_remove (EXmlHash *hash,
                  const gchar *key)
{
	gpointer orig_key;
	gpointer orig_value;
	gboolean found;

	g_return_if_fail (hash != NULL);
	g_return_if_fail (key != NULL);

	found = g_hash_table_lookup_extended (
		hash->objects, key, &orig_key, &orig_value);
	if (found) {
		g_hash_table_remove (hash->objects, key);
		g_free (orig_key);
		g_free (orig_value);
	}
}

/**
 * e_xmlhash_compare:
 * @hash: the #EXmlHash to compare against
 * @key: the key of the hash entry to compare with
 * @compare_data: the data to compare against the hash entry
 *
 * Compares the value with key equal to @key in @hash against
 * @compare_data.
 *
 * Returns: E_XMLHASH_STATUS_SAME if the value and @compare_data are
 *          equal,E_XMLHASH_STATUS_DIFFERENT if they are different, or
 *          E_XMLHASH_STATUS_NOT_FOUND if there is no entry in @hash with
 *          its key equal to @key.
 **/
EXmlHashStatus
e_xmlhash_compare (EXmlHash *hash,
                   const gchar *key,
                   const gchar *compare_data)
{
	gchar *data;
	gint rc;

	g_return_val_if_fail (hash != NULL, E_XMLHASH_STATUS_NOT_FOUND);
	g_return_val_if_fail (key != NULL, E_XMLHASH_STATUS_NOT_FOUND);
	g_return_val_if_fail (compare_data != NULL, E_XMLHASH_STATUS_NOT_FOUND);

	data = g_hash_table_lookup (hash->objects, key);
	if (!data)
		return E_XMLHASH_STATUS_NOT_FOUND;

	rc = strcmp (data, compare_data);
	if (rc == 0)
		return E_XMLHASH_STATUS_SAME;

	return E_XMLHASH_STATUS_DIFFERENT;
}

typedef struct {
	EXmlHashFunc func;
	gpointer user_data;
} foreach_data_t;

static void
foreach_hash_func (gpointer key,
                   gpointer value,
                   gpointer user_data)
{
	foreach_data_t *data = (foreach_data_t *) user_data;

	data->func ((const gchar *) key, (const gchar *) value, data->user_data);
}

/**
 * e_xmlhash_foreach_key:
 * @hash: an #EXmlHash
 * @func: (scope async): the #EXmlHashFunc to execute on the data in @hash
 * @user_data: the data to pass to @func
 *
 * Executes @func against each key/value pair in @hash.
 **/
void
e_xmlhash_foreach_key (EXmlHash *hash,
                       EXmlHashFunc func,
                       gpointer user_data)
{
	foreach_data_t data;

	g_return_if_fail (hash != NULL);
	g_return_if_fail (func != NULL);

	data.func = func;
	data.user_data = user_data;
	g_hash_table_foreach (hash->objects, foreach_hash_func, &data);
}

/**
 * e_xmlhash_foreach_key_remove:
 * @hash: an #EXmlHash
 * @func: (scope async): the #EXmlHashFunc to execute on the data in @hash
 * @user_data: the data to pass to @func
 *
 * Calls g_hash_table_foreach_remove() on @hash<!-- -->'s internal hash
 * table.  See g_hash_table_foreach_remove() for details.
 **/
void
e_xmlhash_foreach_key_remove (EXmlHash *hash,
                              EXmlHashRemoveFunc func,
                              gpointer user_data)
{
	g_return_if_fail (hash != NULL);
	g_return_if_fail (func != NULL);

	g_hash_table_foreach_remove (hash->objects, (GHRFunc) func, user_data);
}

/**
 * e_xmlhash_write:
 * @hash: The #EXmlHash to write.
 *
 * Writes the XML represented by @hash to the file originally passed
 * to e_xmlhash_new().
 **/
void
e_xmlhash_write (EXmlHash *hash)
{
	xmlDoc *doc;

	g_return_if_fail (hash != NULL);

	doc = e_xml_from_hash (
		hash->objects, E_XML_HASH_TYPE_OBJECT_UID, "xmlhash");

	e_xml_save_file (hash->filename, doc);

	xmlFreeDoc (doc);
}

/**
 * e_xmlhash_destroy:
 * @hash: The #EXmlHash to destroy.
 *
 * Frees the memory associated with @hash.
 **/
void
e_xmlhash_destroy (EXmlHash *hash)
{
	g_return_if_fail (hash != NULL);

	g_free (hash->filename);
	if (hash->objects)
		e_xml_destroy_hash (hash->objects);

	g_free (hash);
}
