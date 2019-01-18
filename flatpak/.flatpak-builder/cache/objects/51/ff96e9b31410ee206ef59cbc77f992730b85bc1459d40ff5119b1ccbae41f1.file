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

#include "camel-mempool.h"

#include <string.h>

typedef struct _MemPoolNode {
	struct _MemPoolNode *next;

	gint free;
} MemPoolNode;

typedef struct _MemPoolThresholdNode {
	struct _MemPoolThresholdNode *next;
} MemPoolThresholdNode;

#define ALIGNED_SIZEOF(t)	((sizeof (t) + G_MEM_ALIGN - 1) & -G_MEM_ALIGN)

struct _CamelMemPool {
	gint blocksize;
	gint threshold;
	guint align;
	struct _MemPoolNode *blocks;
	struct _MemPoolThresholdNode *threshold_blocks;
};

/**
 * camel_mempool_new: (skip)
 * @blocksize: The base blocksize to use for all system alocations.
 * @threshold: If the allocation exceeds the threshold, then it is
 * allocated separately and stored in a separate list.
 * @flags: Alignment options: CAMEL_MEMPOOL_ALIGN_STRUCT uses native
 * struct alignment, CAMEL_MEMPOOL_ALIGN_WORD aligns to 16 bits (2 bytes),
 * and CAMEL_MEMPOOL_ALIGN_BYTE aligns to the nearest byte.  The default
 * is to align to native structures.
 *
 * Create a new mempool header.  Mempools can be used to efficiently
 * allocate data which can then be freed as a whole.
 *
 * Mempools can also be used to efficiently allocate arbitrarily
 * aligned data (such as strings) without incurring the space overhead
 * of aligning each allocation (which is not required for strings).
 *
 * However, each allocation cannot be freed individually, only all
 * or nothing.
 *
 * Returns: (transfer full): a newly allocated #CamelMemPool
 *
 * Since: 2.32
 **/
CamelMemPool *
camel_mempool_new (gint blocksize,
                   gint threshold,
                   CamelMemPoolFlags flags)
{
	CamelMemPool *pool;

	pool = g_slice_new0 (CamelMemPool);
	if (threshold >= blocksize)
		threshold = blocksize * 2 / 3;
	pool->blocksize = blocksize;
	pool->threshold = threshold;
	pool->blocks = NULL;
	pool->threshold_blocks = NULL;

	switch (flags & CAMEL_MEMPOOL_ALIGN_MASK) {
	case CAMEL_MEMPOOL_ALIGN_STRUCT:
	default:
		pool->align = G_MEM_ALIGN - 1;
		break;
	case CAMEL_MEMPOOL_ALIGN_WORD:
		pool->align = 2 - 1;
		break;
	case CAMEL_MEMPOOL_ALIGN_BYTE:
		pool->align = 1 - 1;
	}
	return pool;
}

/**
 * camel_mempool_alloc: (skip)
 * @pool: a #CamelMemPool
 * @size: requested size to allocate
 *
 * Allocate a new data block in the mempool.  Size will
 * be rounded up to the mempool's alignment restrictions
 * before being used.
 *
 * Since: 2.32
 **/
gpointer
camel_mempool_alloc (CamelMemPool *pool,
                     register gint size)
{
	size = (size + pool->align) & (~(pool->align));
	if (size >= pool->threshold) {
		MemPoolThresholdNode *n;

		n = g_malloc (ALIGNED_SIZEOF (*n) + size);
		n->next = pool->threshold_blocks;
		pool->threshold_blocks = n;
		return (gchar *) n + ALIGNED_SIZEOF (*n);
	} else {
		register MemPoolNode *n;

		n = pool->blocks;
		if (n && n->free >= size) {
			n->free -= size;
			return (gchar *) n + ALIGNED_SIZEOF (*n) + n->free;
		}

		/* maybe we could do some sort of the free blocks based on size, but
		 * it doubt its worth it at all */

		n = g_malloc (ALIGNED_SIZEOF (*n) + pool->blocksize);
		n->next = pool->blocks;
		pool->blocks = n;
		n->free = pool->blocksize - size;
		return (gchar *) n + ALIGNED_SIZEOF (*n) + n->free;
	}
}

/**
 * camel_mempool_strdup: (skip)
 * @pool: a #CamelMemPool
 * @str:
 *
 * Since: 2.32
 **/
gchar *
camel_mempool_strdup (CamelMemPool *pool,
                      const gchar *str)
{
	gchar *out;
	gsize out_len;

	out_len = strlen (str) + 1;
	out = camel_mempool_alloc (pool, out_len);
	g_strlcpy (out, str, out_len);

	return out;
}

/**
 * camel_mempool_flush: (skip)
 * @pool: a #CamelMemPool
 * @freeall: free all system allocated blocks as well
 *
 * Flush used memory and mark allocated blocks as free.
 *
 * If @freeall is %TRUE, then all allocated blocks are free'd
 * as well.  Otherwise only blocks above the threshold are
 * actually freed, and the others are simply marked as empty.
 *
 * Since: 2.32
 **/
void
camel_mempool_flush (CamelMemPool *pool,
                     gint freeall)
{
	MemPoolThresholdNode *tn, *tw;
	MemPoolNode *pw, *pn;

	tw = pool->threshold_blocks;
	while (tw) {
		tn = tw->next;
		g_free (tw);
		tw = tn;
	}
	pool->threshold_blocks = NULL;

	if (freeall) {
		pw = pool->blocks;
		while (pw) {
			pn = pw->next;
			g_free (pw);
			pw = pn;
		}
		pool->blocks = NULL;
	} else {
		pw = pool->blocks;
		while (pw) {
			pw->free = pool->blocksize;
			pw = pw->next;
		}
	}
}

/**
 * camel_mempool_destroy: (skip)
 * @pool: a #CamelMemPool
 *
 * Free all memory associated with a mempool.
 *
 * Since: 2.32
 **/
void
camel_mempool_destroy (CamelMemPool *pool)
{
	if (pool) {
		camel_mempool_flush (pool, 1);
		g_slice_free (CamelMemPool, pool);
	}
}
