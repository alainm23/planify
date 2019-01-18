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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_PARTITION_TABLE_H
#define CAMEL_PARTITION_TABLE_H

#include <camel/camel-block-file.h>

/* Standard GObject macros */
#define CAMEL_TYPE_PARTITION_TABLE \
	(camel_partition_table_get_type ())
#define CAMEL_PARTITION_TABLE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_PARTITION_TABLE, CamelPartitionTable))
#define CAMEL_PARTITION_TABLE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_PARTITION_TABLE, CamelPartitionTableClass))
#define CAMEL_IS_PARTITION_TABLE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_PARTITION_TABLE))
#define CAMEL_IS_PARTITION_TABLE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_PARTITION_TABLE))
#define CAMEL_PARTITION_TABLE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_PARTITION_TABLE, CamelPartitionTableClass))

#define CAMEL_TYPE_KEY_TABLE \
	(camel_key_table_get_type ())
#define CAMEL_KEY_TABLE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), CAMEL_TYPE_KEY_TABLE, CamelKeyTable))
#define CAMEL_KEY_TABLE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), CAMEL_TYPE_KEY_TABLE, CamelKeyTableClass))
#define CAMEL_IS_KEY_TABLE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), CAMEL_TYPE_KEY_TABLE))
#define CAMEL_IS_KEY_TABLE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), CAMEL_TYPE_KEY_TABLE))
#define CAMEL_KEY_TABLE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), CAMEL_TYPE_KEY_TABLE, CamelKeyTableClass))

G_BEGIN_DECLS

/* ********************************************************************** */

/* CamelPartitionTable - index of key to keyid */

typedef guint32 camel_hash_t;	/* a hashed key */

typedef struct _CamelPartitionKey CamelPartitionKey;
typedef struct _CamelPartitionKeyBlock CamelPartitionKeyBlock;
typedef struct _CamelPartitionMap CamelPartitionMap;
typedef struct _CamelPartitionMapBlock CamelPartitionMapBlock;

typedef struct _CamelPartitionTable CamelPartitionTable;
typedef struct _CamelPartitionTableClass CamelPartitionTableClass;
typedef struct _CamelPartitionTablePrivate CamelPartitionTablePrivate;

struct _CamelPartitionKey {
	camel_hash_t hashid;
	camel_key_t keyid;
};

struct _CamelPartitionKeyBlock {
	guint32 used;
	struct _CamelPartitionKey keys[(CAMEL_BLOCK_SIZE - 4) / sizeof (struct _CamelPartitionKey)];
};

struct _CamelPartitionMap {
	camel_hash_t hashid;
	camel_block_t blockid;
};

struct _CamelPartitionMapBlock {
	camel_block_t next;
	guint32 used;
	struct _CamelPartitionMap partition[(CAMEL_BLOCK_SIZE - 8) / sizeof (struct _CamelPartitionMap)];
};

struct _CamelPartitionTable {
	GObject parent;
	CamelPartitionTablePrivate *priv;
};

struct _CamelPartitionTableClass {
	GObjectClass parent;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_partition_table_get_type	(void);
CamelPartitionTable *
		camel_partition_table_new	(CamelBlockFile *bs,
						 camel_block_t root);
gint		camel_partition_table_sync	(CamelPartitionTable *cpi);
gint		camel_partition_table_add	(CamelPartitionTable *cpi,
						 const gchar *key,
						 camel_key_t keyid);
camel_key_t	camel_partition_table_lookup	(CamelPartitionTable *cpi,
						 const gchar *key);
gboolean	camel_partition_table_remove	(CamelPartitionTable *cpi,
						 const gchar *key);

/* ********************************************************************** */

/* CamelKeyTable - index of keyid to key and flag and data mapping */

typedef struct _CamelKeyBlock CamelKeyBlock;
typedef struct _CamelKeyRootBlock CamelKeyRootBlock;

typedef struct _CamelKeyTable CamelKeyTable;
typedef struct _CamelKeyTableClass CamelKeyTableClass;
typedef struct _CamelKeyTablePrivate CamelKeyTablePrivate;

struct _CamelKeyRootBlock {
	camel_block_t first;
	camel_block_t last;
	camel_key_t free;	/* free list */
};

struct _CamelKeyKey {
	camel_block_t data;
	guint offset : 10;
	guint flags : 22;
};

struct _CamelKeyBlock {
	camel_block_t next;
	guint32 used;
	union {
		struct _CamelKeyKey keys[(CAMEL_BLOCK_SIZE - 8) / sizeof (struct _CamelKeyKey)];
		gchar keydata[CAMEL_BLOCK_SIZE - 8];
	} u;
};

#define CAMEL_KEY_TABLE_MAX_KEY (128) /* max size of any key */

struct _CamelKeyTable {
	GObject parent;
	CamelKeyTablePrivate *priv;
};

struct _CamelKeyTableClass {
	GObjectClass parent;

	/* Padding for future expansion */
	gpointer reserved[20];
};

GType		camel_key_table_get_type	(void);
CamelKeyTable *	camel_key_table_new		(CamelBlockFile *bs,
						 camel_block_t root);
gint		camel_key_table_sync		(CamelKeyTable *ki);
camel_key_t	camel_key_table_add		(CamelKeyTable *ki,
						 const gchar *key,
						 camel_block_t data,
						 guint flags);
gboolean	camel_key_table_set_data	(CamelKeyTable *ki,
						 camel_key_t keyid,
						 camel_block_t data);
gboolean	camel_key_table_set_flags	(CamelKeyTable *ki,
						 camel_key_t keyid,
						 guint flags,
						 guint set);
camel_block_t	camel_key_table_lookup		(CamelKeyTable *ki,
						 camel_key_t keyid,
						 gchar **key,
						 guint *flags);
camel_key_t	camel_key_table_next		(CamelKeyTable *ki,
						 camel_key_t next,
						 gchar **keyp,
						 guint *flagsp,
						 camel_block_t *datap);

G_END_DECLS

#endif /* CAMEL_PARTITION_TABLE_H */
