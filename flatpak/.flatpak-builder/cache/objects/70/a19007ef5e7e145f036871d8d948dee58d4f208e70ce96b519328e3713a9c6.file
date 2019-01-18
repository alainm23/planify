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
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gstdio.h>

#include "camel-block-file.h"
#include "camel-file-utils.h"

#define d(x) /*(printf("%s(%d):%s: ",  __FILE__, __LINE__, __PRETTY_FUNCTION__),(x))*/

/* Locks must be obtained in the order defined */

struct _CamelBlockFilePrivate {
	struct _CamelBlockFile *base;

	GMutex root_lock; /* for modifying the root block */
	GMutex cache_lock; /* for refcounting, flag manip, cache manip */
	GMutex io_lock; /* for all io ops */

	guint deleted : 1;

	gchar version[8];
	gchar *path;
	CamelBlockFileFlags flags;

	gint fd;
	gsize block_size;

	CamelBlockRoot *root;
	CamelBlock *root_block;

	/* make private? */
	gint block_cache_limit;
	gint block_cache_count;
	GQueue block_cache;
	GHashTable *blocks;
};

#define CAMEL_BLOCK_FILE_LOCK(kf, lock) (g_mutex_lock(&(kf)->priv->lock))
#define CAMEL_BLOCK_FILE_TRYLOCK(kf, lock) (g_mutex_trylock(&(kf)->priv->lock))
#define CAMEL_BLOCK_FILE_UNLOCK(kf, lock) (g_mutex_unlock(&(kf)->priv->lock))

#define LOCK(x) g_mutex_lock(&x)
#define UNLOCK(x) g_mutex_unlock(&x)

static GMutex block_file_lock;

/* lru cache of block files */
static GQueue block_file_list = G_QUEUE_INIT;
/* list to store block files that are actually intialised */
static GQueue block_file_active_list = G_QUEUE_INIT;
static gint block_file_count = 0;
static gint block_file_threshhold = 10;

static gint sync_nolock (CamelBlockFile *bs);
static gint sync_block_nolock (CamelBlockFile *bs, CamelBlock *bl);

G_DEFINE_TYPE (CamelBlockFile, camel_block_file, G_TYPE_OBJECT)

static gint
block_file_validate_root (CamelBlockFile *bs)
{
	CamelBlockRoot *br;
	struct stat st;
	gint retval;

	br = bs->priv->root;

	retval = fstat (bs->priv->fd, &st);

	d (printf ("Validate root: '%s'\n", bs->priv->path));
	d (printf ("version: %.8s (%.8s)\n", bs->priv->root->version, bs->priv->version));
	d (printf (
		"block size: %d (%d)%s\n",
		br->block_size, bs->priv->block_size,
		br->block_size != bs->priv->block_size ? " BAD":" OK"));
	d (printf (
		"free: %ld (%d add size < %ld)%s\n",
		(glong) br->free,
		br->free / bs->priv->block_size * bs->priv->block_size,
		(glong) st.st_size,
		(br->free > st.st_size) ||
		(br->free % bs->priv->block_size) != 0 ? " BAD":" OK"));
	d (printf (
		"last: %ld (%d and size: %ld)%s\n",
		(glong) br->last,
		br->last / bs->priv->block_size * bs->priv->block_size,
		(glong) st.st_size,
		(br->last != st.st_size) ||
		((br->last % bs->priv->block_size) != 0) ? " BAD": " OK"));
	d (printf (
		"flags: %s\n",
		(br->priv->flags & CAMEL_BLOCK_FILE_SYNC) ? "SYNC" : "unSYNC"));

	if (br->last == 0
	    || memcmp (bs->priv->root->version, bs->priv->version, 8) != 0
	    || br->block_size != bs->priv->block_size
	    || (br->free % bs->priv->block_size) != 0
	    || (br->last % bs->priv->block_size) != 0
	    || retval == -1
	    || st.st_size != br->last
	    || br->free > st.st_size
	    || (br->flags & CAMEL_BLOCK_FILE_SYNC) == 0) {
		return -1;
	}

	return 0;
}

static gint
block_file_init_root (CamelBlockFile *bs)
{
	CamelBlockRoot *br = bs->priv->root;

	memset (br, 0, bs->priv->block_size);
	memcpy (br->version, bs->priv->version, 8);
	br->last = bs->priv->block_size;
	br->flags = CAMEL_BLOCK_FILE_SYNC;
	br->free = 0;
	br->block_size = bs->priv->block_size;

	return 0;
}

static void
block_file_finalize (GObject *object)
{
	CamelBlockFile *bs = CAMEL_BLOCK_FILE (object);
	CamelBlock *bl;

	if (bs->priv->root_block)
		camel_block_file_sync (bs);

	/* remove from lru list */
	LOCK (block_file_lock);

	if (bs->priv->fd != -1)
		block_file_count--;

	/* XXX This is only supposed to be in one block file list
	 *     at a time, but not sure if we can guarantee which,
	 *     so try removing from both lists. */
	g_queue_remove (&block_file_list, bs->priv);
	g_queue_remove (&block_file_active_list, bs->priv);

	UNLOCK (block_file_lock);

	while ((bl = g_queue_pop_head (&bs->priv->block_cache)) != NULL) {
		if (bl->refcount != 0)
			g_warning ("Block '%u' still referenced", bl->id);
		g_free (bl);
	}

	g_hash_table_destroy (bs->priv->blocks);

	if (bs->priv->root_block)
		camel_block_file_unref_block (bs, bs->priv->root_block);
	g_free (bs->priv->path);
	if (bs->priv->fd != -1)
		close (bs->priv->fd);

	g_mutex_clear (&bs->priv->io_lock);
	g_mutex_clear (&bs->priv->cache_lock);
	g_mutex_clear (&bs->priv->root_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_block_file_parent_class)->finalize (object);
}

static void
camel_block_file_class_init (CamelBlockFileClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelBlockFilePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = block_file_finalize;

	class->validate_root = block_file_validate_root;
	class->init_root = block_file_init_root;
}

static guint
block_hash_func (gconstpointer v)
{
	return ((camel_block_t) GPOINTER_TO_UINT (v)) >> CAMEL_BLOCK_SIZE_BITS;
}

static void
camel_block_file_init (CamelBlockFile *bs)
{
	bs->priv = G_TYPE_INSTANCE_GET_PRIVATE (bs, CAMEL_TYPE_BLOCK_FILE, CamelBlockFilePrivate);

	bs->priv->fd = -1;
	bs->priv->block_size = CAMEL_BLOCK_SIZE;
	g_queue_init (&bs->priv->block_cache);
	bs->priv->blocks = g_hash_table_new ((GHashFunc) block_hash_func, NULL);
	/* this cache size and the text index size have been tuned for about the best
	 * with moderate memory usage.  Doubling the memory usage barely affects performance. */
	bs->priv->block_cache_limit = 256;

	bs->priv->base = bs;

	g_mutex_init (&bs->priv->root_lock);
	g_mutex_init (&bs->priv->cache_lock);
	g_mutex_init (&bs->priv->io_lock);

	/* link into lru list */
	LOCK (block_file_lock);
	g_queue_push_head (&block_file_list, bs->priv);
	UNLOCK (block_file_lock);
}

/* 'use' a block file for io */
static gint
block_file_use (CamelBlockFile *bs)
{
	CamelBlockFile *bf;
	GList *link;
	gint err;

	/* We want to:
	 *  remove file from active list
	 *  lock it
	 *
	 * Then when done:
	 *  unlock it
	 *  add it back to end of active list
	 */

	CAMEL_BLOCK_FILE_LOCK (bs, io_lock);

	if (bs->priv->fd != -1)
		return 0;
	else if (bs->priv->deleted) {
		CAMEL_BLOCK_FILE_UNLOCK (bs, io_lock);
		errno = ENOENT;
		return -1;
	} else {
		d (printf ("Turning block file online: %s\n", bs->priv->path));
	}

	if ((bs->priv->fd = g_open (bs->priv->path, bs->priv->flags | O_BINARY, 0600)) == -1) {
		err = errno;
		CAMEL_BLOCK_FILE_UNLOCK (bs, io_lock);
		errno = err;
		return -1;
	}

	LOCK (block_file_lock);

	link = g_queue_find (&block_file_list, bs->priv);
	if (link != NULL) {
		g_queue_unlink (&block_file_list, link);
		g_queue_push_tail_link (&block_file_active_list, link);
	}

	block_file_count++;

	link = g_queue_peek_head_link (&block_file_list);

	while (link != NULL && block_file_count > block_file_threshhold) {
		struct _CamelBlockFilePrivate *nw = link->data;

		/* We never hit the current blockfile here, as its removed from the list first */
		bf = nw->base;
		if (bf->priv->fd != -1) {
			/* Need to trylock, as any of these lock levels might be trying
			 * to lock the block_file_lock, so we need to check and abort if so */
			if (CAMEL_BLOCK_FILE_TRYLOCK (bf, root_lock)) {
				if (CAMEL_BLOCK_FILE_TRYLOCK (bf, cache_lock)) {
					if (CAMEL_BLOCK_FILE_TRYLOCK (bf, io_lock)) {
						d (printf ("[%d] Turning block file offline: %s\n", block_file_count - 1, bf->priv->path));
						sync_nolock (bf);
						close (bf->priv->fd);
						bf->priv->fd = -1;
						block_file_count--;
						CAMEL_BLOCK_FILE_UNLOCK (bf, io_lock);
					}
					CAMEL_BLOCK_FILE_UNLOCK (bf, cache_lock);
				}
				CAMEL_BLOCK_FILE_UNLOCK (bf, root_lock);
			}
		}

		link = g_list_next (link);
	}

	UNLOCK (block_file_lock);

	return 0;
}

static void
block_file_unuse (CamelBlockFile *bs)
{
	GList *link;

	LOCK (block_file_lock);
	link = g_queue_find (&block_file_active_list, bs->priv);
	if (link != NULL) {
		g_queue_unlink (&block_file_active_list, link);
		g_queue_push_tail_link (&block_file_list, link);
	}
	UNLOCK (block_file_lock);

	CAMEL_BLOCK_FILE_UNLOCK (bs, io_lock);
}

/*
 * o = camel_cache_get (c, key);
 * camel_cache_unref (c, key);
 * camel_cache_add (c, key, o);
 * camel_cache_remove (c, key);
 */

/**
 * camel_block_file_new:
 * @path: a path with file name of the the new #CamelBlockFile
 * @flags: file open flags to use
 * @version: a version string
 * @block_size: block size, currently ignored
 *
 * Allocate a new block file, stored at @path.  @version contains an 8 character
 * version string which must match the head of the file, or the file will be
 * intitialised.
 *
 * @block_size is currently ignored and is set to CAMEL_BLOCK_SIZE.
 *
 * Returns: The new block file, or NULL if it could not be created.
 **/
CamelBlockFile *
camel_block_file_new (const gchar *path,
                      gint flags,
                      const gchar version[8],
                      gsize block_size)
{
	CamelBlockFileClass *class;
	CamelBlockFile *bs;

	bs = g_object_new (CAMEL_TYPE_BLOCK_FILE, NULL);
	memcpy (bs->priv->version, version, 8);
	bs->priv->path = g_strdup (path);
	bs->priv->flags = flags;

	bs->priv->root_block = camel_block_file_get_block (bs, 0);
	if (bs->priv->root_block == NULL) {
		g_object_unref (bs);
		return NULL;
	}
	camel_block_file_detach_block (bs, bs->priv->root_block);
	bs->priv->root = (CamelBlockRoot *) &bs->priv->root_block->data;

	/* we only need these flags on first open */
	bs->priv->flags &= ~(O_CREAT | O_EXCL | O_TRUNC);

	class = CAMEL_BLOCK_FILE_GET_CLASS (bs);

	/* Do we need to init the root block? */
	if (class->validate_root (bs) == -1) {
		d (printf ("Initialise root block: %.8s\n", version));

		class->init_root (bs);
		camel_block_file_touch_block (bs, bs->priv->root_block);
		if (block_file_use (bs) == -1) {
			g_object_unref (bs);
			return NULL;
		}
		if (sync_block_nolock (bs, bs->priv->root_block) == -1
		    || ftruncate (bs->priv->fd, bs->priv->root->last) == -1) {
			block_file_unuse (bs);
			g_object_unref (bs);
			return NULL;
		}
		block_file_unuse (bs);
	}

	return bs;
}

/**
 * camel_block_file_get_root:
 * @bs: a #CamelBlockFile
 *
 * Returns: (transfer none): A #CamelBlockRoot of @bs.
 *
 * Since: 3.24
 **/
CamelBlockRoot *
camel_block_file_get_root (CamelBlockFile *bs)
{
	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), NULL);

	return bs->priv->root;
}

/**
 * camel_block_file_get_root_block:
 * @bs: a #CamelBlockFile
 *
 * Returns: (transfer none): A root #CamelBlock of @bs.
 *
 * Since: 3.24
 **/
CamelBlock *
camel_block_file_get_root_block (CamelBlockFile *bs)
{
	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), NULL);

	return bs->priv->root_block;
}

/**
 * camel_block_file_get_cache_limit:
 * @bs: a #CamelBlockFile
 *
 * Returns: Current block cache limit of @bs.
 *
 * Since: 3.24
 **/
gint
camel_block_file_get_cache_limit (CamelBlockFile *bs)
{
	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), -1);

	return bs->priv->block_cache_limit;
}

/**
 * camel_block_file_set_cache_limit:
 * @bs: a #CamelBlockFile
 * @block_cache_limit: a new block cache limit to set
 *
 * Sets a new block cache limit for @bs.
 *
 * Since: 3.24
 **/
void
camel_block_file_set_cache_limit (CamelBlockFile *bs,
				  gint block_cache_limit)
{
	g_return_if_fail (CAMEL_IS_BLOCK_FILE (bs));

	bs->priv->block_cache_limit = block_cache_limit;
}

/**
 * camel_block_file_rename:
 * @bs: a #CamelBlockFile
 * @path: path with filename to rename to
 *
 * Renames existing block file to a new @path.
 *
 * Returns: 0 on success, -1 on error; errno is set on failure
 **/
gint
camel_block_file_rename (CamelBlockFile *bs,
                         const gchar *path)
{
	gint ret;
	struct stat st;
	gint err;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), -1);
	g_return_val_if_fail (path != NULL, -1);

	CAMEL_BLOCK_FILE_LOCK (bs, io_lock);

	ret = g_rename (bs->priv->path, path);
	if (ret == -1) {
		/* Maybe the rename actually worked */
		err = errno;
		if (g_stat (path, &st) == 0
		    && g_stat (bs->priv->path, &st) == -1
		    && errno == ENOENT)
			ret = 0;
		errno = err;
	}

	if (ret != -1) {
		g_free (bs->priv->path);
		bs->priv->path = g_strdup (path);
	}

	CAMEL_BLOCK_FILE_UNLOCK (bs, io_lock);

	return ret;
}

/**
 * camel_block_file_delete:
 * @bs: a #CamelBlockFile
 *
 * Deletes existing block file.
 *
 * Returns: 0 on success, -1 on error.
 **/
gint
camel_block_file_delete (CamelBlockFile *bs)
{
	gint ret;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), -1);

	CAMEL_BLOCK_FILE_LOCK (bs, io_lock);

	if (bs->priv->fd != -1) {
		LOCK (block_file_lock);
		block_file_count--;
		UNLOCK (block_file_lock);
		close (bs->priv->fd);
		bs->priv->fd = -1;
	}

	bs->priv->deleted = TRUE;
	ret = g_unlink (bs->priv->path);

	CAMEL_BLOCK_FILE_UNLOCK (bs, io_lock);

	return ret;

}

/**
 * camel_block_file_new_block: (skip)
 * @bs: a #CamelBlockFile
 *
 * Allocate a new block, return a pointer to it.  Old blocks
 * may be flushed to disk during this call.
 *
 * Returns: The block, or NULL if an error occurred.
 **/
CamelBlock *
camel_block_file_new_block (CamelBlockFile *bs)
{
	CamelBlock *bl;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), NULL);

	CAMEL_BLOCK_FILE_LOCK (bs, root_lock);

	if (bs->priv->root->free) {
		bl = camel_block_file_get_block (bs, bs->priv->root->free);
		if (bl == NULL)
			goto fail;
		bs->priv->root->free = ((camel_block_t *) bl->data)[0];
	} else {
		bl = camel_block_file_get_block (bs, bs->priv->root->last);
		if (bl == NULL)
			goto fail;
		bs->priv->root->last += CAMEL_BLOCK_SIZE;
	}

	bs->priv->root_block->flags |= CAMEL_BLOCK_DIRTY;

	bl->flags |= CAMEL_BLOCK_DIRTY;
	memset (bl->data, 0, CAMEL_BLOCK_SIZE);
fail:
	CAMEL_BLOCK_FILE_UNLOCK (bs, root_lock);

	return bl;
}

/**
 * camel_block_file_free_block:
 * @bs: a #CamelBlockFile
 * @id: a #camel_block_t
 *
 *
 **/
gint
camel_block_file_free_block (CamelBlockFile *bs,
                             camel_block_t id)
{
	CamelBlock *bl;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), -1);

	bl = camel_block_file_get_block (bs, id);
	if (bl == NULL)
		return -1;

	CAMEL_BLOCK_FILE_LOCK (bs, root_lock);

	((camel_block_t *) bl->data)[0] = bs->priv->root->free;
	bs->priv->root->free = bl->id;
	bs->priv->root_block->flags |= CAMEL_BLOCK_DIRTY;
	bl->flags |= CAMEL_BLOCK_DIRTY;
	camel_block_file_unref_block (bs, bl);

	CAMEL_BLOCK_FILE_UNLOCK (bs, root_lock);

	return 0;
}

/**
 * camel_block_file_get_block: (skip)
 * @bs: a #CamelBlockFile
 * @id: a #camel_block_t
 *
 * Retreive a block @id.
 *
 * Returns: The block, or NULL if blockid is invalid or a file error
 * occurred.
 **/
CamelBlock *
camel_block_file_get_block (CamelBlockFile *bs,
                            camel_block_t id)
{
	CamelBlock *bl;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), NULL);

	/* Sanity check: Dont allow reading of root block (except before its been read)
	 * or blocks with invalid block id's */
	if ((bs->priv->root == NULL && id != 0)
	    || (bs->priv->root != NULL && (id > bs->priv->root->last || id == 0))
	    || (id % bs->priv->block_size) != 0) {
		errno = EINVAL;
		return NULL;
	}

	CAMEL_BLOCK_FILE_LOCK (bs, cache_lock);

	bl = g_hash_table_lookup (bs->priv->blocks, GUINT_TO_POINTER (id));

	d (printf ("Get  block %08x: %s\n", id, bl?"cached":"must read"));

	if (bl == NULL) {
		GQueue trash = G_QUEUE_INIT;
		GList *link;

		/* LOCK io_lock */
		if (block_file_use (bs) == -1) {
			CAMEL_BLOCK_FILE_UNLOCK (bs, cache_lock);
			return NULL;
		}

		bl = g_malloc0 (sizeof (*bl));
		bl->id = id;
		if (lseek (bs->priv->fd, id, SEEK_SET) == -1 ||
		    camel_read (bs->priv->fd, (gchar *) bl->data, CAMEL_BLOCK_SIZE, NULL, NULL) == -1) {
			block_file_unuse (bs);
			CAMEL_BLOCK_FILE_UNLOCK (bs, cache_lock);
			g_free (bl);
			return NULL;
		}

		bs->priv->block_cache_count++;
		g_hash_table_insert (bs->priv->blocks, GUINT_TO_POINTER (bl->id), bl);

		/* flush old blocks */
		link = g_queue_peek_tail_link (&bs->priv->block_cache);

		while (link != NULL && bs->priv->block_cache_count > bs->priv->block_cache_limit) {
			CamelBlock *flush = link->data;

			if (flush->refcount == 0) {
				if (sync_block_nolock (bs, flush) != -1) {
					g_hash_table_remove (bs->priv->blocks, GUINT_TO_POINTER (flush->id));
					g_queue_push_tail (&trash, link);
					link->data = NULL;
					g_free (flush);
					bs->priv->block_cache_count--;
				}
			}

			link = g_list_previous (link);
		}

		/* Remove deleted blocks from the cache. */
		while ((link = g_queue_pop_head (&trash)) != NULL)
			g_queue_delete_link (&bs->priv->block_cache, link);

		/* UNLOCK io_lock */
		block_file_unuse (bs);
	} else {
		g_queue_remove (&bs->priv->block_cache, bl);
	}

	g_queue_push_head (&bs->priv->block_cache, bl);
	bl->refcount++;

	CAMEL_BLOCK_FILE_UNLOCK (bs, cache_lock);

	d (printf ("Got  block %08x\n", id));

	return bl;
}

/**
 * camel_block_file_detach_block:
 * @bs: a #CamelBlockFile
 * @bl: a #CamelBlock
 *
 * Detatch a block from the block file's cache.  The block should
 * be unref'd or attached when finished with.  The block file will
 * perform no writes of this block or flushing of it if the cache
 * fills.
 **/
void
camel_block_file_detach_block (CamelBlockFile *bs,
                               CamelBlock *bl)
{
	g_return_if_fail (CAMEL_IS_BLOCK_FILE (bs));
	g_return_if_fail (bl != NULL);

	CAMEL_BLOCK_FILE_LOCK (bs, cache_lock);

	g_hash_table_remove (bs->priv->blocks, GUINT_TO_POINTER (bl->id));
	g_queue_remove (&bs->priv->block_cache, bl);
	bl->flags |= CAMEL_BLOCK_DETACHED;

	CAMEL_BLOCK_FILE_UNLOCK (bs, cache_lock);
}

/**
 * camel_block_file_attach_block:
 * @bs: a #CamelBlockFile
 * @bl: a #CamelBlock
 *
 * Reattach a block that has been detached.
 **/
void
camel_block_file_attach_block (CamelBlockFile *bs,
                               CamelBlock *bl)
{
	g_return_if_fail (CAMEL_IS_BLOCK_FILE (bs));
	g_return_if_fail (bl != NULL);

	CAMEL_BLOCK_FILE_LOCK (bs, cache_lock);

	g_hash_table_insert (bs->priv->blocks, GUINT_TO_POINTER (bl->id), bl);
	g_queue_push_tail (&bs->priv->block_cache, bl);
	bl->flags &= ~CAMEL_BLOCK_DETACHED;

	CAMEL_BLOCK_FILE_UNLOCK (bs, cache_lock);
}

/**
 * camel_block_file_touch_block:
 * @bs: a #CamelBlockFile
 * @bl: a #CamelBlock
 *
 * Mark a block as dirty.  The block will be written to disk if
 * it ever expires from the cache.
 **/
void
camel_block_file_touch_block (CamelBlockFile *bs,
                              CamelBlock *bl)
{
	g_return_if_fail (CAMEL_IS_BLOCK_FILE (bs));
	g_return_if_fail (bl != NULL);

	CAMEL_BLOCK_FILE_LOCK (bs, root_lock);
	CAMEL_BLOCK_FILE_LOCK (bs, cache_lock);

	bl->flags |= CAMEL_BLOCK_DIRTY;

	if ((bs->priv->root->flags & CAMEL_BLOCK_FILE_SYNC) && bl != bs->priv->root_block) {
		d (printf ("turning off sync flag\n"));
		bs->priv->root->flags &= ~CAMEL_BLOCK_FILE_SYNC;
		bs->priv->root_block->flags |= CAMEL_BLOCK_DIRTY;
		camel_block_file_sync_block (bs, bs->priv->root_block);
	}

	CAMEL_BLOCK_FILE_UNLOCK (bs, cache_lock);
	CAMEL_BLOCK_FILE_UNLOCK (bs, root_lock);
}

/**
 * camel_block_file_unref_block:
 * @bs: a #CamelBlockFile
 * @bl: a #CamelBlock
 *
 * Mark a block as unused.  If a block is used it will not be
 * written to disk, or flushed from memory.
 *
 * If a block is detatched and this is the last reference, the
 * block will be freed.
 **/
void
camel_block_file_unref_block (CamelBlockFile *bs,
                              CamelBlock *bl)
{
	g_return_if_fail (CAMEL_IS_BLOCK_FILE (bs));
	g_return_if_fail (bl != NULL);

	CAMEL_BLOCK_FILE_LOCK (bs, cache_lock);

	if (bl->refcount == 1 && (bl->flags & CAMEL_BLOCK_DETACHED))
		g_free (bl);
	else
		bl->refcount--;

	CAMEL_BLOCK_FILE_UNLOCK (bs, cache_lock);
}

static gint
sync_block_nolock (CamelBlockFile *bs,
                   CamelBlock *bl)
{
	d (printf ("Sync block %08x: %s\n", bl->id, (bl->priv->flags & CAMEL_BLOCK_DIRTY)?"dirty":"clean"));

	if (bl->flags & CAMEL_BLOCK_DIRTY) {
		if (lseek (bs->priv->fd, bl->id, SEEK_SET) == -1
		    || write (bs->priv->fd, bl->data, CAMEL_BLOCK_SIZE) != CAMEL_BLOCK_SIZE) {
			return -1;
		}
		bl->flags &= ~CAMEL_BLOCK_DIRTY;
	}

	return 0;
}

static gint
sync_nolock (CamelBlockFile *bs)
{
	GList *head, *link;
	gint work = FALSE;

	head = g_queue_peek_head_link (&bs->priv->block_cache);

	for (link = head; link != NULL; link = g_list_next (link)) {
		CamelBlock *bl = link->data;

		if (bl->flags & CAMEL_BLOCK_DIRTY) {
			work = TRUE;
			if (sync_block_nolock (bs, bl) == -1)
				return -1;
		}
	}

	if (!work
	    && (bs->priv->root_block->flags & CAMEL_BLOCK_DIRTY) == 0
	    && (bs->priv->root->flags & CAMEL_BLOCK_FILE_SYNC) != 0)
		return 0;

	d (printf ("turning on sync flag\n"));

	bs->priv->root->flags |= CAMEL_BLOCK_FILE_SYNC;
	bs->priv->root_block->flags |= CAMEL_BLOCK_DIRTY;

	return sync_block_nolock (bs, bs->priv->root_block);
}

/**
 * camel_block_file_sync_block:
 * @bs: a #CamelBlockFile
 * @bl: a #CamelBlock
 *
 * Flush a block to disk immediately.  The block will only
 * be flushed to disk if it is marked as dirty (touched).
 *
 * Returns: -1 on io error.
 **/
gint
camel_block_file_sync_block (CamelBlockFile *bs,
                             CamelBlock *bl)
{
	gint ret;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), -1);
	g_return_val_if_fail (bl != NULL, -1);

	/* LOCK io_lock */
	if (block_file_use (bs) == -1)
		return -1;

	ret = sync_block_nolock (bs, bl);

	block_file_unuse (bs);

	return ret;
}

/**
 * camel_block_file_sync:
 * @bs: a #CamelBlockFile
 *
 * Sync all dirty blocks to disk, including the root block.
 *
 * Returns: -1 on io error.
 **/
gint
camel_block_file_sync (CamelBlockFile *bs)
{
	gint ret;

	g_return_val_if_fail (CAMEL_IS_BLOCK_FILE (bs), -1);

	CAMEL_BLOCK_FILE_LOCK (bs, root_lock);
	CAMEL_BLOCK_FILE_LOCK (bs, cache_lock);

	/* LOCK io_lock */
	if (block_file_use (bs) == -1)
		ret = -1;
	else {
		ret = sync_nolock (bs);
		block_file_unuse (bs);
	}

	CAMEL_BLOCK_FILE_UNLOCK (bs, cache_lock);
	CAMEL_BLOCK_FILE_UNLOCK (bs, root_lock);

	return ret;
}

/* ********************************************************************** */

struct _CamelKeyFilePrivate {
	struct _CamelKeyFile *base;
	GMutex lock;
	guint deleted : 1;

	FILE *fp;
	gchar *path;
	gint flags;
	goffset last;
};

#define CAMEL_KEY_FILE_LOCK(kf, lock) (g_mutex_lock(&(kf)->priv->lock))
#define CAMEL_KEY_FILE_TRYLOCK(kf, lock) (g_mutex_trylock(&(kf)->priv->lock))
#define CAMEL_KEY_FILE_UNLOCK(kf, lock) (g_mutex_unlock(&(kf)->priv->lock))

static GMutex key_file_lock;

/* lru cache of block files */
static GQueue key_file_list = G_QUEUE_INIT;
static GQueue key_file_active_list = G_QUEUE_INIT;
static gint key_file_count = 0;
static const gint key_file_threshhold = 10;

G_DEFINE_TYPE (CamelKeyFile, camel_key_file, G_TYPE_OBJECT)

static void
key_file_finalize (GObject *object)
{
	CamelKeyFile *kf = CAMEL_KEY_FILE (object);

	LOCK (key_file_lock);

	/* XXX This is only supposed to be in one key file list
	 *     at a time, but not sure if we can guarantee which,
	 *     so try removing from both lists. */
	g_queue_remove (&key_file_list, kf->priv);
	g_queue_remove (&key_file_active_list, kf->priv);

	if (kf->priv->fp) {
		key_file_count--;
		fclose (kf->priv->fp);
	}

	UNLOCK (key_file_lock);

	g_free (kf->priv->path);

	g_mutex_clear (&kf->priv->lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_key_file_parent_class)->finalize (object);
}

static void
camel_key_file_class_init (CamelKeyFileClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (CamelKeyFilePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = key_file_finalize;
}

static void
camel_key_file_init (CamelKeyFile *kf)
{
	kf->priv = G_TYPE_INSTANCE_GET_PRIVATE (kf, CAMEL_TYPE_KEY_FILE, CamelKeyFilePrivate);
	kf->priv->base = kf;

	g_mutex_init (&kf->priv->lock);

	LOCK (key_file_lock);
	g_queue_push_head (&key_file_list, kf->priv);
	UNLOCK (key_file_lock);
}

/* 'use' a key file for io */
static gint
key_file_use (CamelKeyFile *ks)
{
	CamelKeyFile *kf;
	gint err, fd;
	const gchar *flag;
	GList *link;

	/* We want to:
	 *  remove file from active list
	 *  lock it
 *
	 * Then when done:
	 *  unlock it
	 *  add it back to end of active list
	*/

	/* TODO: Check header on reset? */

	CAMEL_KEY_FILE_LOCK (ks, lock);

	if (ks->priv->fp != NULL)
		return 0;
	else if (ks->priv->deleted) {
		CAMEL_KEY_FILE_UNLOCK (ks, lock);
		errno = ENOENT;
		return -1;
	} else {
		d (printf ("Turning key file online: '%s'\n", bs->priv->path));
	}

	if ((ks->priv->flags & O_ACCMODE) == O_RDONLY)
		flag = "rb";
	else
		flag = "a+b";

	if ((fd = g_open (ks->priv->path, ks->priv->flags | O_BINARY, 0600)) == -1
	    || (ks->priv->fp = fdopen (fd, flag)) == NULL) {
		err = errno;
		if (fd != -1)
			close (fd);
		CAMEL_KEY_FILE_UNLOCK (ks, lock);
		errno = err;
		return -1;
	}

	LOCK (key_file_lock);

	link = g_queue_find (&key_file_list, ks->priv);
	if (link != NULL) {
		g_queue_unlink (&key_file_list, link);
		g_queue_push_tail_link (&key_file_active_list, link);
	}

	key_file_count++;

	link = g_queue_peek_head_link (&key_file_list);
	while (link != NULL && key_file_count > key_file_threshhold) {
		struct _CamelKeyFilePrivate *nw = link->data;

		/* We never hit the current keyfile here, as its removed from the list first */
		kf = nw->base;
		if (kf->priv->fp != NULL) {
			/* Need to trylock, as any of these lock levels might be trying
			 * to lock the key_file_lock, so we need to check and abort if so */
			if (CAMEL_BLOCK_FILE_TRYLOCK (kf, lock)) {
				d (printf ("Turning key file offline: %s\n", kf->priv->path));
				fclose (kf->priv->fp);
				kf->priv->fp = NULL;
				key_file_count--;
				CAMEL_BLOCK_FILE_UNLOCK (kf, lock);
			}
		}

		link = g_list_next (link);
	}

	UNLOCK (key_file_lock);

	return 0;
}

static void
key_file_unuse (CamelKeyFile *kf)
{
	GList *link;

	LOCK (key_file_lock);
	link = g_queue_find (&key_file_active_list, kf->priv);
	if (link != NULL) {
		g_queue_unlink (&key_file_active_list, link);
		g_queue_push_tail_link (&key_file_list, link);
	}
	UNLOCK (key_file_lock);

	CAMEL_KEY_FILE_UNLOCK (kf, lock);
}

/**
 * camel_key_file_new:
 * @path: a filename with path of the #CamelKeyFile to create
 * @flags: open flags
 * @version: Version string (header) of file.  Currently
 * written but not checked.
 *
 * Create a new key file.  A linked list of record blocks.
 *
 * Returns: A new key file, or NULL if the file could not
 * be opened/created/initialised.
 **/
CamelKeyFile *
camel_key_file_new (const gchar *path,
                    gint flags,
                    const gchar version[8])
{
	CamelKeyFile *kf;
	goffset last;
	gint err;

	d (printf ("New key file '%s'\n", path));

	kf = g_object_new (CAMEL_TYPE_KEY_FILE, NULL);
	kf->priv->path = g_strdup (path);
	kf->priv->fp = NULL;
	kf->priv->flags = flags;
	kf->priv->last = 8;

	if (key_file_use (kf) == -1) {
		g_object_unref (kf);
		kf = NULL;
	} else {
		fseek (kf->priv->fp, 0, SEEK_END);
		last = ftell (kf->priv->fp);
		if (last == 0) {
			fwrite (version, sizeof (gchar), 8, kf->priv->fp);
			last += 8;
		}
		kf->priv->last = last;

		err = ferror (kf->priv->fp);
		key_file_unuse (kf);

		/* we only need these flags on first open */
		kf->priv->flags &= ~(O_CREAT | O_EXCL | O_TRUNC);

		if (err) {
			g_object_unref (kf);
			kf = NULL;
		}
	}

	return kf;
}

gint
camel_key_file_rename (CamelKeyFile *kf,
                       const gchar *path)
{
	gint ret;
	struct stat st;
	gint err;

	g_return_val_if_fail (CAMEL_IS_KEY_FILE (kf), -1);
	g_return_val_if_fail (path != NULL, -1);

	CAMEL_KEY_FILE_LOCK (kf, lock);

	ret = g_rename (kf->priv->path, path);
	if (ret == -1) {
		/* Maybe the rename actually worked */
		err = errno;
		if (g_stat (path, &st) == 0
		    && g_stat (kf->priv->path, &st) == -1
		    && errno == ENOENT)
			ret = 0;
		errno = err;
	}

	if (ret != -1) {
		g_free (kf->priv->path);
		kf->priv->path = g_strdup (path);
	}

	CAMEL_KEY_FILE_UNLOCK (kf, lock);

	return ret;
}

gint
camel_key_file_delete (CamelKeyFile *kf)
{
	gint ret;

	g_return_val_if_fail (CAMEL_IS_KEY_FILE (kf), -1);

	CAMEL_KEY_FILE_LOCK (kf, lock);

	if (kf->priv->fp) {
		LOCK (key_file_lock);
		key_file_count--;
		UNLOCK (key_file_lock);
		fclose (kf->priv->fp);
		kf->priv->fp = NULL;
	}

	kf->priv->deleted = TRUE;
	ret = g_unlink (kf->priv->path);

	CAMEL_KEY_FILE_UNLOCK (kf, lock);

	return ret;

}

/**
 * camel_key_file_write:
 * @kf: a #CamelKeyFile
 * @parent: a #camel_block_t
 * @len: how many @records to write
 * @records: (array length=len): an array of #camel_key_t to write
 *
 * Write a new list of records to the key file.
 *
 * Returns: -1 on io error.  The key file will remain unchanged.
 **/
gint
camel_key_file_write (CamelKeyFile *kf,
                      camel_block_t *parent,
                      gsize len,
                      camel_key_t *records)
{
	camel_block_t next;
	guint32 size;
	gint ret = -1;

	g_return_val_if_fail (CAMEL_IS_KEY_FILE (kf), -1);
	g_return_val_if_fail (parent != NULL, -1);
	g_return_val_if_fail (records != NULL, -1);

	d (printf ("write key %08x len = %d\n", *parent, len));

	if (len == 0) {
		d (printf (" new parent = %08x\n", *parent));
		return 0;
	}

	/* LOCK */
	if (key_file_use (kf) == -1)
		return -1;

	size = len;

	/* FIXME: Use io util functions? */
	next = kf->priv->last;
	if (fseek (kf->priv->fp, kf->priv->last, SEEK_SET) == -1)
		return -1;

	fwrite (parent, sizeof (*parent), 1, kf->priv->fp);
	fwrite (&size, sizeof (size), 1, kf->priv->fp);
	fwrite (records, sizeof (records[0]), len, kf->priv->fp);

	if (ferror (kf->priv->fp)) {
		clearerr (kf->priv->fp);
	} else {
		kf->priv->last = ftell (kf->priv->fp);
		*parent = next;
		ret = len;
	}

	/* UNLOCK */
	key_file_unuse (kf);

	d (printf (" new parent = %08x\n", *parent));

	return ret;
}

/**
 * camel_key_file_read:
 * @kf: a #CamelKeyFile
 * @start: The record pointer.  This will be set to the next record pointer on success.
 * @len: Number of records read, if != NULL.
 * @records: (array length=len) (nullable): Records, allocated, must be freed with g_free, if != NULL.
 *
 * Read the next block of data from the key file.  Returns the number of
 * records.
 *
 * Returns: -1 on io error.
 **/
gint
camel_key_file_read (CamelKeyFile *kf,
                     camel_block_t *start,
                     gsize *len,
                     camel_key_t **records)
{
	guint32 size;
	glong pos;
	camel_block_t next;
	gint ret = -1;

	g_return_val_if_fail (CAMEL_IS_KEY_FILE (kf), -1);
	g_return_val_if_fail (start != NULL, -1);

	pos = *start;
	if (pos == 0)
		return 0;

	/* LOCK */
	if (key_file_use (kf) == -1)
		return -1;

	if (fseek (kf->priv->fp, pos, SEEK_SET) == -1
	    || fread (&next, sizeof (next), 1, kf->priv->fp) != 1
	    || fread (&size, sizeof (size), 1, kf->priv->fp) != 1
	    || size > 1024) {
		clearerr (kf->priv->fp);
		goto fail;
	}

	if (len)
		*len = size;

	if (records) {
		camel_key_t *keys = g_malloc (size * sizeof (camel_key_t));

		if (fread (keys, sizeof (camel_key_t), size, kf->priv->fp) != size) {
			g_free (keys);
			goto fail;
		}
		*records = keys;
	}

	*start = next;

	ret = 0;
fail:
	/* UNLOCK */
	key_file_unuse (kf);

	return ret;
}
