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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include "camel-block-file.h"
#include "camel-partition-table.h"

/* Do we synchronously write table updates - makes the
 * tables consistent after program crash without sync */
/*#define SYNC_UPDATES*/

#define d(x) /*(printf ("%s (%d):%s: ",  __FILE__, __LINE__, __PRETTY_FUNCTION__),(x))*/
/* key index debug */
#define k(x) /*(printf ("%s (%d):%s: ",  __FILE__, __LINE__, __PRETTY_FUNCTION__),(x))*/

#define CAMEL_PARTITION_TABLE_LOCK(kf, lock) \
	(g_mutex_lock (&(kf)->priv->lock))
#define CAMEL_PARTITION_TABLE_UNLOCK(kf, lock) \
	(g_mutex_unlock (&(kf)->priv->lock))

#define CAMEL_PARTITION_TABLE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_PARTITION_TABLE, CamelPartitionTablePrivate))

struct _CamelPartitionTablePrivate {
	GMutex lock;	/* for locking partition */

	CamelBlockFile *blocks;
	camel_block_t rootid;

	/* we keep a list of partition blocks active at all times */
	GQueue partition;
};

G_DEFINE_TYPE (CamelPartitionTable, camel_partition_table, G_TYPE_OBJECT)

static void
partition_table_finalize (GObject *object)
{
	CamelPartitionTable *table = CAMEL_PARTITION_TABLE (object);
	CamelBlock *bl;

	if (table->priv->blocks != NULL) {
		while ((bl = g_queue_pop_head (&table->priv->partition)) != NULL) {
			camel_block_file_sync_block (table->priv->blocks, bl);
			camel_block_file_unref_block (table->priv->blocks, bl);
		}
		camel_block_file_sync (table->priv->blocks);

		g_object_unref (table->priv->blocks);
	}

	g_mutex_clear (&table->priv->lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_partition_table_parent_class)->finalize (object);
}

static void
camel_partition_table_class_init (CamelPartitionTableClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelPartitionTablePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = partition_table_finalize;
}

static void
camel_partition_table_init (CamelPartitionTable *cpi)
{
	cpi->priv = CAMEL_PARTITION_TABLE_GET_PRIVATE (cpi);

	g_queue_init (&cpi->priv->partition);
	g_mutex_init (&cpi->priv->lock);
}

/* ********************************************************************** */

/*
 * Have 2 hashes:
 * Name -> nameid
 * Word -> wordid
 *
 * nameid is pointer to name file, includes a bit to say if name is deleted
 * wordid is a pointer to word file, includes pointer to start of word entries
 *
 * delete a name -> set it as deleted, do nothing else though
 *
 * lookup word, if nameid is deleted, mark it in wordlist as unused and mark
 * for write (?)
 */

/* ********************************************************************** */

/* This simple hash seems to work quite well */
static camel_hash_t hash_key (const gchar *key)
{
	camel_hash_t hash = 0xABADF00D;

	while (*key) {
		hash = hash * (*key) ^ (*key);
		key++;
	}

	return hash;
}

/* Call with lock held */
static GList *
find_partition (CamelPartitionTable *cpi,
                camel_hash_t id,
                gint *indexp)
{
	gint index, jump;
	CamelPartitionMapBlock *ptb;
	CamelPartitionMap *part;
	GList *head, *link;

	/* first, find the block this key might be in, then binary search the block */
	head = g_queue_peek_head_link (&cpi->priv->partition);

	for (link = head; link != NULL; link = g_list_next (link)) {
		CamelBlock *bl = link->data;

		ptb = (CamelPartitionMapBlock *) &bl->data;
		part = ptb->partition;
		if (ptb->used > 0 && id <= part[ptb->used - 1].hashid) {
			index = ptb->used / 2;
			jump = ptb->used / 4;

			if (jump == 0)
				jump = 1;

			while (1) {
				if (id <= part[index].hashid) {
					if (index == 0 || id > part[index - 1].hashid)
						break;
					index -= jump;
				} else {
					if (index >= ptb->used - 1)
						break;
					index += jump;
				}
				jump = jump / 2;
				if (jump == 0)
					jump = 1;
			}
			*indexp = index;

			return link;
		}
	}

	g_warning ("could not find a partition that could fit!  partition table corrupt!");

	/* This should never be reached */

	return NULL;
}

CamelPartitionTable *
camel_partition_table_new (CamelBlockFile *bs,
                           camel_block_t root)
{
	CamelPartitionTable *cpi;
	CamelPartitionMapBlock *ptb;
	CamelPartitionKeyBlock *kb;
	CamelBlock *block, *pblock;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), NULL);

	cpi = g_object_new (CAMEL_TYPE_PARTITION_TABLE, NULL);
	cpi->priv->rootid = root;
	cpi->priv->blocks = g_object_ref (bs);

	/* read the partition table into memory */
	do {
		block = camel_block_file_get_block (bs, root);
		if (block == NULL)
			goto fail;

		ptb = (CamelPartitionMapBlock *) &block->data;

		d (printf ("Adding partition block, used = %d, hashid = %08x\n", ptb->used, ptb->partition[0].hashid));

		/* if we have no data, prime initial block */
		if (ptb->used == 0 && g_queue_is_empty (&cpi->priv->partition) && ptb->next == 0) {
			pblock = camel_block_file_new_block (bs);
			if (pblock == NULL) {
				camel_block_file_unref_block (bs, block);
				goto fail;
			}
			kb = (CamelPartitionKeyBlock *) &pblock->data;
			kb->used = 0;
			ptb->used = 1;
			ptb->partition[0].hashid = 0xffffffff;
			ptb->partition[0].blockid = pblock->id;
			camel_block_file_touch_block (bs, pblock);
			camel_block_file_unref_block (bs, pblock);
			camel_block_file_touch_block (bs, block);
#ifdef SYNC_UPDATES
			camel_block_file_sync_block (bs, block);
#endif
		}

		root = ptb->next;
		camel_block_file_detach_block (bs, block);
		g_queue_push_tail (&cpi->priv->partition, block);
	} while (root);

	return cpi;

fail:
	g_object_unref (cpi);
	return NULL;
}

/* sync our blocks, the caller must still sync the blockfile itself */
gint
camel_partition_table_sync (CamelPartitionTable *cpi)
{
	gint ret = 0;

	g_return_val_if_fail (CAMEL_IS_PARTITION_TABLE (cpi), -1);

	CAMEL_PARTITION_TABLE_LOCK (cpi, lock);

	if (cpi->priv->blocks) {
		GList *head, *link;

		head = g_queue_peek_head_link (&cpi->priv->partition);

		for (link = head; link != NULL; link = g_list_next (link)) {
			CamelBlock *bl = link->data;

			ret = camel_block_file_sync_block (cpi->priv->blocks, bl);
			if (ret == -1)
				goto fail;
		}
	}

fail:
	CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);

	return ret;
}

camel_key_t
camel_partition_table_lookup (CamelPartitionTable *cpi,
                              const gchar *key)
{
	CamelPartitionKeyBlock *pkb;
	CamelPartitionMapBlock *ptb;
	CamelBlock *block, *ptblock;
	camel_hash_t hashid;
	camel_key_t keyid = 0;
	GList *ptblock_link;
	gint index, i;

	g_return_val_if_fail (CAMEL_IS_PARTITION_TABLE (cpi), 0);
	g_return_val_if_fail (key != NULL, 0);

	hashid = hash_key (key);

	CAMEL_PARTITION_TABLE_LOCK (cpi, lock);

	ptblock_link = find_partition (cpi, hashid, &index);
	if (ptblock_link == NULL) {
		CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);
		return 0;
	}

	ptblock = (CamelBlock *) ptblock_link->data;
	ptb = (CamelPartitionMapBlock *) &ptblock->data;
	block = camel_block_file_get_block (
		cpi->priv->blocks, ptb->partition[index].blockid);
	if (block == NULL) {
		CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);
		return 0;
	}

	pkb = (CamelPartitionKeyBlock *) &block->data;

	/* What to do about duplicate hash's? */
	for (i = 0; i < pkb->used; i++) {
		if (pkb->keys[i].hashid == hashid) {
			/* !! need to: lookup and compare string value */
			/* get_key() if key == key ... */
			keyid = pkb->keys[i].keyid;
			break;
		}
	}

	CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);

	camel_block_file_unref_block (cpi->priv->blocks, block);

	return keyid;
}

gboolean
camel_partition_table_remove (CamelPartitionTable *cpi,
                              const gchar *key)
{
	CamelPartitionKeyBlock *pkb;
	CamelPartitionMapBlock *ptb;
	CamelBlock *block, *ptblock;
	camel_hash_t hashid;
	GList *ptblock_link;
	gint index, i;

	g_return_val_if_fail (CAMEL_IS_PARTITION_TABLE (cpi), FALSE);
	g_return_val_if_fail (key != NULL, FALSE);

	hashid = hash_key (key);

	CAMEL_PARTITION_TABLE_LOCK (cpi, lock);

	ptblock_link = find_partition (cpi, hashid, &index);
	if (ptblock_link == NULL) {
		CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);
		return TRUE;
	}

	ptblock = (CamelBlock *) ptblock_link->data;
	ptb = (CamelPartitionMapBlock *) &ptblock->data;
	block = camel_block_file_get_block (
		cpi->priv->blocks, ptb->partition[index].blockid);
	if (block == NULL) {
		CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);
		return FALSE;
	}
	pkb = (CamelPartitionKeyBlock *) &block->data;

	/* What to do about duplicate hash's? */
	for (i = 0; i < pkb->used; i++) {
		if (pkb->keys[i].hashid == hashid) {
			/* !! need to: lookup and compare string value */
			/* get_key() if key == key ... */

			/* remove this key */
			pkb->used--;
			for (; i < pkb->used; i++) {
				pkb->keys[i].keyid = pkb->keys[i + 1].keyid;
				pkb->keys[i].hashid = pkb->keys[i + 1].hashid;
			}
			camel_block_file_touch_block (cpi->priv->blocks, block);
			break;
		}
	}

	CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);

	camel_block_file_unref_block (cpi->priv->blocks, block);

	return TRUE;
}

static gint
keys_cmp (gconstpointer ap,
          gconstpointer bp)
{
	const CamelPartitionKey *a = ap;
	const CamelPartitionKey *b = bp;

	if (a->hashid < b->hashid)
		return -1;
	else if (a->hashid > b->hashid)
		return 1;

	return 0;
}

gint
camel_partition_table_add (CamelPartitionTable *cpi,
                           const gchar *key,
                           camel_key_t keyid)
{
	camel_hash_t hashid, partid;
	gint index, newindex = 0; /* initialisation of this and pkb/nkb is just to silence compiler */
	CamelPartitionMapBlock *ptb, *ptn;
	CamelPartitionKeyBlock *kb, *newkb, *nkb = NULL, *pkb = NULL;
	CamelBlock *block, *ptblock, *ptnblock;
	gint i, half, len;
	CamelPartitionKey keys[CAMEL_BLOCK_SIZE / 4];
	GList *ptblock_link;
	gint ret = -1;

	g_return_val_if_fail (CAMEL_IS_PARTITION_TABLE (cpi), -1);
	g_return_val_if_fail (key != NULL, -1);

	hashid = hash_key (key);

	CAMEL_PARTITION_TABLE_LOCK (cpi, lock);
	ptblock_link = find_partition (cpi, hashid, &index);
	if (ptblock_link == NULL) {
		CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);
		return -1;
	}

	ptblock = (CamelBlock *) ptblock_link->data;
	ptb = (CamelPartitionMapBlock *) &ptblock->data;
	block = camel_block_file_get_block (
		cpi->priv->blocks, ptb->partition[index].blockid);
	if (block == NULL) {
		CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);
		return -1;
	}
	kb = (CamelPartitionKeyBlock *) &block->data;

	/* TODO: Keep the key array in sorted order, cheaper lookups and split operation */

	if (kb->used < G_N_ELEMENTS (kb->keys)) {
		/* Have room, just put it in */
		kb->keys[kb->used].hashid = hashid;
		kb->keys[kb->used].keyid = keyid;
		kb->used++;
	} else {
		CamelBlock *newblock = NULL, *nblock = NULL, *pblock = NULL;

		/* Need to split?  See if previous or next has room, then split across that instead */

		/* TODO: Should look at next/previous partition table block as well ... */

		if (index > 0) {
			pblock = camel_block_file_get_block (
				cpi->priv->blocks, ptb->partition[index - 1].blockid);
			if (pblock == NULL)
				goto fail;
			pkb = (CamelPartitionKeyBlock *) &pblock->data;
		}
		if (index < (ptb->used - 1)) {
			nblock = camel_block_file_get_block (
				cpi->priv->blocks, ptb->partition[index + 1].blockid);
			if (nblock == NULL) {
				if (pblock)
					camel_block_file_unref_block (cpi->priv->blocks, pblock);
				goto fail;
			}
			nkb = (CamelPartitionKeyBlock *) &nblock->data;
		}

		if (pblock && pkb->used < G_N_ELEMENTS (kb->keys)) {
			if (nblock && nkb->used < G_N_ELEMENTS (kb->keys)) {
				if (pkb->used < nkb->used) {
					newindex = index + 1;
					newblock = nblock;
				} else {
					newindex = index - 1;
					newblock = pblock;
				}
			} else {
				newindex = index - 1;
				newblock = pblock;
			}
		} else {
			if (nblock && nkb->used < G_N_ELEMENTS (kb->keys)) {
				newindex = index + 1;
				newblock = nblock;
			}
		}

		/* We had no room, need to split across another block */
		if (newblock == NULL) {
			/* See if we have room in the partition table for this block or need to split that too */
			if (ptb->used >= G_N_ELEMENTS (ptb->partition)) {
				/* TODO: Could check next block to see if it'll fit there first */
				ptnblock = camel_block_file_new_block (cpi->priv->blocks);
				if (ptnblock == NULL) {
					if (nblock)
						camel_block_file_unref_block (cpi->priv->blocks, nblock);
					if (pblock)
						camel_block_file_unref_block (cpi->priv->blocks, pblock);
					goto fail;
				}
				camel_block_file_detach_block (cpi->priv->blocks, ptnblock);

				/* split block and link on-disk, always sorted */
				ptn = (CamelPartitionMapBlock *) &ptnblock->data;
				ptn->next = ptb->next;
				ptb->next = ptnblock->id;
				len = ptb->used / 2;
				ptn->used = ptb->used - len;
				ptb->used = len;
				memcpy (ptn->partition, &ptb->partition[len], ptn->used * sizeof (ptb->partition[0]));

				/* link in-memory */
				g_queue_insert_after (
					&cpi->priv->partition,
					ptblock_link, ptnblock);

				/* write in right order to ensure structure */
				camel_block_file_touch_block (cpi->priv->blocks, ptnblock);
#ifdef SYNC_UPDATES
				camel_block_file_sync_block (cpi->priv->blocks, ptnblock);
#endif
				if (index > len) {
					camel_block_file_touch_block (cpi->priv->blocks, ptblock);
#ifdef SYNC_UPDATES
					camel_block_file_sync_block (cpi->priv->blocks, ptblock);
#endif
					index -= len;
					ptb = ptn;
					ptblock = ptnblock;
				}
			}

			/* try get newblock before modifying existing */
			newblock = camel_block_file_new_block (cpi->priv->blocks);
			if (newblock == NULL) {
				if (nblock)
					camel_block_file_unref_block (cpi->priv->blocks, nblock);
				if (pblock)
					camel_block_file_unref_block (cpi->priv->blocks, pblock);
				goto fail;
			}

			for (i = ptb->used - 1; i > index; i--) {
				ptb->partition[i + 1].hashid = ptb->partition[i].hashid;
				ptb->partition[i + 1].blockid = ptb->partition[i].blockid;
			}
			ptb->used++;

			newkb = (CamelPartitionKeyBlock *) &newblock->data;
			newkb->used = 0;
			newindex = index + 1;

			ptb->partition[newindex].hashid = ptb->partition[index].hashid;
			ptb->partition[newindex].blockid = newblock->id;

			if (nblock)
				camel_block_file_unref_block (cpi->priv->blocks, nblock);
			if (pblock)
				camel_block_file_unref_block (cpi->priv->blocks, pblock);
		} else {
			newkb = (CamelPartitionKeyBlock *) &newblock->data;

			if (newblock == pblock) {
				if (nblock)
					camel_block_file_unref_block (cpi->priv->blocks, nblock);
			} else {
				if (pblock)
					camel_block_file_unref_block (cpi->priv->blocks, pblock);
			}
		}

		/* sort keys to find midpoint */
		len = kb->used;
		memcpy (keys, kb->keys, sizeof (kb->keys[0]) * len);
		memcpy (keys + len, newkb->keys, sizeof (newkb->keys[0]) * newkb->used);
		len += newkb->used;
		keys[len].hashid = hashid;
		keys[len].keyid = keyid;
		len++;
		qsort (keys, len, sizeof (keys[0]), keys_cmp);

		/* Split keys, fix partition table */
		half = len / 2;
		partid = keys[half - 1].hashid;

		if (index < newindex) {
			memcpy (kb->keys, keys, sizeof (keys[0]) * half);
			kb->used = half;
			memcpy (newkb->keys, keys + half, sizeof (keys[0]) * (len - half));
			newkb->used = len - half;
			ptb->partition[index].hashid = partid;
		} else {
			memcpy (newkb->keys, keys, sizeof (keys[0]) * half);
			newkb->used = half;
			memcpy (kb->keys, keys + half, sizeof (keys[0]) * (len - half));
			kb->used = len - half;
			ptb->partition[newindex].hashid = partid;
		}

		camel_block_file_touch_block (cpi->priv->blocks, ptblock);
#ifdef SYNC_UPDATES
		camel_block_file_sync_block (cpi->priv->blocks, ptblock);
#endif
		camel_block_file_touch_block (cpi->priv->blocks, newblock);
		camel_block_file_unref_block (cpi->priv->blocks, newblock);
	}

	camel_block_file_touch_block (cpi->priv->blocks, block);
	camel_block_file_unref_block (cpi->priv->blocks, block);

	ret = 0;
fail:
	CAMEL_PARTITION_TABLE_UNLOCK (cpi, lock);

	return ret;
}

/* ********************************************************************** */

#define CAMEL_KEY_TABLE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_KEY_TABLE, CamelKeyTablePrivate))

#define CAMEL_KEY_TABLE_LOCK(kf, lock) \
	(g_mutex_lock (&(kf)->priv->lock))
#define CAMEL_KEY_TABLE_UNLOCK(kf, lock) \
	(g_mutex_unlock (&(kf)->priv->lock))

struct _CamelKeyTablePrivate {
	GMutex lock;	/* for locking key */

	CamelBlockFile *blocks;

	camel_block_t rootid;

	CamelKeyRootBlock *root;
	CamelBlock *root_block;
};

G_DEFINE_TYPE (CamelKeyTable, camel_key_table, G_TYPE_OBJECT)

static void
key_table_finalize (GObject *object)
{
	CamelKeyTable *table = CAMEL_KEY_TABLE (object);

	if (table->priv->blocks) {
		if (table->priv->root_block) {
			camel_block_file_sync_block (table->priv->blocks, table->priv->root_block);
			camel_block_file_unref_block (table->priv->blocks, table->priv->root_block);
		}
		camel_block_file_sync (table->priv->blocks);
		g_object_unref (table->priv->blocks);
	}

	g_mutex_clear (&table->priv->lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_key_table_parent_class)->finalize (object);
}

static void
camel_key_table_class_init (CamelKeyTableClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelKeyTablePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = key_table_finalize;
}

static void
camel_key_table_init (CamelKeyTable *table)
{
	table->priv = CAMEL_KEY_TABLE_GET_PRIVATE (table);
	g_mutex_init (&table->priv->lock);
}

CamelKeyTable *
camel_key_table_new (CamelBlockFile *bs,
                     camel_block_t root)
{
	CamelKeyTable *ki;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), NULL);

	ki = g_object_new (CAMEL_TYPE_KEY_TABLE, NULL);

	ki->priv->blocks = g_object_ref (bs);
	ki->priv->rootid = root;

	ki->priv->root_block = camel_block_file_get_block (bs, ki->priv->rootid);
	if (ki->priv->root_block == NULL) {
		g_object_unref (ki);
		ki = NULL;
	} else {
		camel_block_file_detach_block (bs, ki->priv->root_block);
		ki->priv->root = (CamelKeyRootBlock *) &ki->priv->root_block->data;

		k (printf ("Opening key index\n"));
		k (printf (" first %u\n last %u\n free %u\n", ki->priv->root->first, ki->priv->root->last, ki->priv->root->free));
	}

	return ki;
}

gint
camel_key_table_sync (CamelKeyTable *ki)
{
	g_return_val_if_fail (CAMEL_IS_KEY_TABLE (ki), -1);

#ifdef SYNC_UPDATES
	return 0;
#else
	return camel_block_file_sync_block (ki->priv->blocks, ki->priv->root_block);
#endif
}

camel_key_t
camel_key_table_add (CamelKeyTable *ki,
                     const gchar *key,
                     camel_block_t data,
                     guint flags)
{
	CamelBlock *last, *next;
	CamelKeyBlock *kblast, *kbnext;
	gint len, left;
	guint offset;
	camel_key_t keyid = 0;

	g_return_val_if_fail (CAMEL_IS_KEY_TABLE (ki), 0);
	g_return_val_if_fail (key != NULL, 0);

	/* Maximum key size = 128 chars */
	len = strlen (key);
	if (len > CAMEL_KEY_TABLE_MAX_KEY)
		len = 128;

	CAMEL_KEY_TABLE_LOCK (ki, lock);

	if (ki->priv->root->last == 0) {
		last = camel_block_file_new_block (ki->priv->blocks);
		if (last == NULL)
			goto fail;
		ki->priv->root->last = ki->priv->root->first = last->id;
		camel_block_file_touch_block (ki->priv->blocks, ki->priv->root_block);
		k (printf ("adding first block, first = %u\n", ki->priv->root->first));
	} else {
		last = camel_block_file_get_block (
			ki->priv->blocks, ki->priv->root->last);
		if (last == NULL)
			goto fail;
	}

	kblast = (CamelKeyBlock *) &last->data;

	if (kblast->used >= 127)
		goto fail;

	if (kblast->used > 0) {
		/*left = &kblast->u.keydata[kblast->u.keys[kblast->used-1].offset] - (gchar *)(&kblast->u.keys[kblast->used+1]);*/
		left = kblast->u.keys[kblast->used - 1].offset - sizeof (kblast->u.keys[0]) * (kblast->used + 1);
		d (printf (
			"key '%s' used = %d (%d), filled = %d, left = %d  len = %d?\n",
			key, kblast->used, kblast->used * sizeof (kblast->u.keys[0]),
			sizeof (kblast->u.keydata) - kblast->u.keys[kblast->used - 1].offset,
			left, len));
		if (left < len) {
			next = camel_block_file_new_block (ki->priv->blocks);
			if (next == NULL) {
				camel_block_file_unref_block (ki->priv->blocks, last);
				goto fail;
			}
			kbnext = (CamelKeyBlock *) &next->data;
			kblast->next = next->id;
			ki->priv->root->last = next->id;
			d (printf ("adding new block, first = %u, last = %u\n", ki->priv->root->first, ki->priv->root->last));
			camel_block_file_touch_block (ki->priv->blocks, ki->priv->root_block);
			camel_block_file_touch_block (ki->priv->blocks, last);
			camel_block_file_unref_block (ki->priv->blocks, last);
			kblast = kbnext;
			last = next;
		}
	}

	if (kblast->used > 0)
		offset = kblast->u.keys[kblast->used - 1].offset - len;
	else
		offset = sizeof (kblast->u.keydata) - len;

	kblast->u.keys[kblast->used].flags = flags;
	kblast->u.keys[kblast->used].data = data;
	kblast->u.keys[kblast->used].offset = offset;
	memcpy (kblast->u.keydata + offset, key, len);

	keyid = (last->id & (~(CAMEL_BLOCK_SIZE - 1))) | kblast->used;

	kblast->used++;

	if (kblast->used >=127) {
		g_warning ("Invalid value for used %d\n", kblast->used);
		keyid = 0;
		goto fail;
	}

	camel_block_file_touch_block (ki->priv->blocks, last);
	camel_block_file_unref_block (ki->priv->blocks, last);

#ifdef SYNC_UPDATES
	camel_block_file_sync_block (ki->priv->blocks, ki->priv->root_block);
#endif
fail:
	CAMEL_KEY_TABLE_UNLOCK (ki, lock);

	return keyid;
}

gboolean
camel_key_table_set_data (CamelKeyTable *ki,
                          camel_key_t keyid,
                          camel_block_t data)
{
	CamelBlock *bl;
	camel_block_t blockid;
	gint index;
	CamelKeyBlock *kb;

	g_return_val_if_fail (CAMEL_IS_KEY_TABLE (ki), FALSE);
	g_return_val_if_fail (keyid != 0, FALSE);

	blockid = keyid & (~(CAMEL_BLOCK_SIZE - 1));
	index = keyid & (CAMEL_BLOCK_SIZE - 1);

	bl = camel_block_file_get_block (ki->priv->blocks, blockid);
	if (bl == NULL)
		return FALSE;
	kb = (CamelKeyBlock *) &bl->data;

	CAMEL_KEY_TABLE_LOCK (ki, lock);

	if (kb->u.keys[index].data != data) {
		kb->u.keys[index].data = data;
		camel_block_file_touch_block (ki->priv->blocks, bl);
	}

	CAMEL_KEY_TABLE_UNLOCK (ki, lock);

	camel_block_file_unref_block (ki->priv->blocks, bl);

	return TRUE;
}

gboolean
camel_key_table_set_flags (CamelKeyTable *ki,
                           camel_key_t keyid,
                           guint flags,
                           guint set)
{
	CamelBlock *bl;
	camel_block_t blockid;
	gint index;
	CamelKeyBlock *kb;
	guint old;

	g_return_val_if_fail (CAMEL_IS_KEY_TABLE (ki), FALSE);
	g_return_val_if_fail (keyid != 0, FALSE);

	blockid = keyid & (~(CAMEL_BLOCK_SIZE - 1));
	index = keyid & (CAMEL_BLOCK_SIZE - 1);

	bl = camel_block_file_get_block (ki->priv->blocks, blockid);
	if (bl == NULL)
		return FALSE;
	kb = (CamelKeyBlock *) &bl->data;

	if (kb->used >=127 || index >= kb->used) {
		g_warning ("Block %x: Invalid index or content: index %d used %d\n", blockid, index, kb->used);
		return FALSE;
	}

	CAMEL_KEY_TABLE_LOCK (ki, lock);

	old = kb->u.keys[index].flags;
	if ((old & set) != (flags & set)) {
		kb->u.keys[index].flags = (old & (~set)) | (flags & set);
		camel_block_file_touch_block (ki->priv->blocks, bl);
	}

	CAMEL_KEY_TABLE_UNLOCK (ki, lock);

	camel_block_file_unref_block (ki->priv->blocks, bl);

	return TRUE;
}

camel_block_t
camel_key_table_lookup (CamelKeyTable *ki,
                        camel_key_t keyid,
                        gchar **keyp,
                        guint *flags)
{
	CamelBlock *bl;
	camel_block_t blockid;
	gint index, len, off;
	gchar *key;
	CamelKeyBlock *kb;

	g_return_val_if_fail (CAMEL_IS_KEY_TABLE (ki), 0);
	g_return_val_if_fail (keyid != 0, 0);

	if (keyp)
		*keyp = NULL;
	if (flags)
		*flags = 0;

	blockid = keyid & (~(CAMEL_BLOCK_SIZE - 1));
	index = keyid & (CAMEL_BLOCK_SIZE - 1);

	bl = camel_block_file_get_block (ki->priv->blocks, blockid);
	if (bl == NULL)
		return 0;

	kb = (CamelKeyBlock *) &bl->data;

	if (kb->used >=127 || index >= kb->used) {
		g_warning ("Block %x: Invalid index or content: index %d used %d\n", blockid, index, kb->used);
		return 0;
	}

	CAMEL_KEY_TABLE_LOCK (ki, lock);

	blockid = kb->u.keys[index].data;
	if (flags)
		*flags = kb->u.keys[index].flags;

	if (keyp) {
		off = kb->u.keys[index].offset;
		if (index == 0)
			len = sizeof (kb->u.keydata) - off;
		else
			len = kb->u.keys[index - 1].offset - off;
		*keyp = key = g_malloc (len+1);
		memcpy (key, kb->u.keydata + off, len);
		key[len] = 0;
	}

	CAMEL_KEY_TABLE_UNLOCK (ki, lock);

	camel_block_file_unref_block (ki->priv->blocks, bl);

	return blockid;
}

/* iterate through all keys */
camel_key_t
camel_key_table_next (CamelKeyTable *ki,
                      camel_key_t next,
                      gchar **keyp,
                      guint *flagsp,
                      camel_block_t *datap)
{
	CamelBlock *bl;
	CamelKeyBlock *kb;
	camel_block_t blockid;
	gint index;

	g_return_val_if_fail (CAMEL_IS_KEY_TABLE (ki), 0);

	if (keyp)
		*keyp = NULL;
	if (flagsp)
		*flagsp = 0;
	if (datap)
		*datap = 0;

	CAMEL_KEY_TABLE_LOCK (ki, lock);

	if (next == 0) {
		next = ki->priv->root->first;
		if (next == 0) {
			CAMEL_KEY_TABLE_UNLOCK (ki, lock);
			return 0;
		}
	} else
		next++;

	do {
		blockid = next & (~(CAMEL_BLOCK_SIZE - 1));
		index = next & (CAMEL_BLOCK_SIZE - 1);

		bl = camel_block_file_get_block (ki->priv->blocks, blockid);
		if (bl == NULL) {
			CAMEL_KEY_TABLE_UNLOCK (ki, lock);
			return 0;
		}

		kb = (CamelKeyBlock *) &bl->data;

		/* see if we need to goto the next block */
		if (index >= kb->used) {
			/* FIXME: check for loops */
			next = kb->next;
			camel_block_file_unref_block (ki->priv->blocks, bl);
			bl = NULL;
		}
	} while (bl == NULL);

	/* invalid block data */
	if ((kb->u.keys[index].offset >= sizeof (kb->u.keydata)
	     /*|| kb->u.keys[index].offset < kb->u.keydata - (gchar *)&kb->u.keys[kb->used])*/
	     || kb->u.keys[index].offset < sizeof (kb->u.keys[0]) * kb->used
	    || (index > 0 &&
		(kb->u.keys[index - 1].offset >= sizeof (kb->u.keydata)
		 /*|| kb->u.keys[index-1].offset < kb->u.keydata - (gchar *)&kb->u.keys[kb->used]))) {*/
		 || kb->u.keys[index - 1].offset < sizeof (kb->u.keys[0]) * kb->used)))) {
		g_warning ("Block %u invalid scanning keys", bl->id);
		camel_block_file_unref_block (ki->priv->blocks, bl);
		CAMEL_KEY_TABLE_UNLOCK (ki, lock);
		return 0;
	}

	if (datap)
		*datap = kb->u.keys[index].data;

	if (flagsp)
		*flagsp = kb->u.keys[index].flags;

	if (keyp) {
		gint len, off = kb->u.keys[index].offset;
		gchar *key;

		if (index == 0)
			len = sizeof (kb->u.keydata) - off;
		else
			len = kb->u.keys[index - 1].offset - off;
		*keyp = key = g_malloc (len+1);
		memcpy (key, kb->u.keydata + off, len);
		key[len] = 0;
	}

	CAMEL_KEY_TABLE_UNLOCK (ki, lock);

	camel_block_file_unref_block (ki->priv->blocks, bl);

	return next;
}

/* ********************************************************************** */
