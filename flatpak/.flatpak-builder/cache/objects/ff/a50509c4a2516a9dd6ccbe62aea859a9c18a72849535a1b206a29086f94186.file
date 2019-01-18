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
 *	    Jacob Berkman <jacob@ximian.com>
 */

#include "e-memory.h"

#include <string.h> /* memset() */

/*#define TIMEIT*/

#ifdef TIMEIT
#include <sys/time.h>
#include <unistd.h>

struct timeval timeit_start;

static time_start (const gchar *desc)
{
	gettimeofday (&timeit_start, NULL);
	printf ("starting: %s\n", desc);
}

static time_end (const gchar *desc)
{
	gulong diff;
	struct timeval end;

	gettimeofday (&end, NULL);
	diff = end.tv_sec * 1000 + end.tv_usec / 1000;
	diff -= timeit_start.tv_sec * 1000 + timeit_start.tv_usec / 1000;
	printf (
		"%s took %ld.%03ld seconds\n",
		desc, diff / 1000, diff % 1000);
}
#else
#define time_start(x)
#define time_end(x)
#endif

typedef struct _MemChunkFreeNode {
	struct _MemChunkFreeNode *next;
	guint atoms;
} MemChunkFreeNode;

struct _EMemChunk {
	guint blocksize;	/* number of atoms in a block */
	guint atomsize;	/* size of each atom */
	GPtrArray *blocks;	/* blocks of raw memory */
	struct _MemChunkFreeNode *free;
};

/**
 * e_memchunk_new: (skip)
 * @atomcount: the number of atoms stored in a single malloc'd block of memory
 * @atomsize: the size of each allocation
 *
 * Create a new #EMemChunk header.  Memchunks are an efficient way to
 * allocate and deallocate identical sized blocks of memory quickly, and
 * space efficiently.
 *
 * e_memchunks are effectively the same as gmemchunks, only faster (much),
 * and they use less memory overhead for housekeeping.
 *
 * Returns: a new #EMemChunk
 **/
EMemChunk *
e_memchunk_new (gint atomcount,
                gint atomsize)
{
	EMemChunk *memchunk = g_malloc (sizeof (*memchunk));

	memchunk->blocksize = atomcount;
	memchunk->atomsize = MAX (atomsize, sizeof (MemChunkFreeNode));
	memchunk->blocks = g_ptr_array_new ();
	memchunk->free = NULL;

	return memchunk;
}

/**
 * e_memchunk_alloc: (skip)
 * @memchunk: an #EMemChunk
 *
 * Allocate a new atom size block of memory from an #EMemChunk.
 * Free the returned atom with e_memchunk_free().
 *
 * Returns: (transfer full): an allocated block of memory
 **/
gpointer
e_memchunk_alloc (EMemChunk *memchunk)
{
	gchar *b;
	MemChunkFreeNode *f;
	gpointer mem;

	f = memchunk->free;
	if (f) {
		f->atoms--;
		if (f->atoms > 0) {
			mem = ((gchar *) f) + (f->atoms * memchunk->atomsize);
		} else {
			mem = f;
			memchunk->free = memchunk->free->next;
		}
		return mem;
	} else {
		b = g_malloc (memchunk->blocksize * memchunk->atomsize);
		g_ptr_array_add (memchunk->blocks, b);
		f = (MemChunkFreeNode *) &b[memchunk->atomsize];
		f->atoms = memchunk->blocksize - 1;
		f->next = NULL;
		memchunk->free = f;
		return b;
	}
}

/**
 * e_memchunk_alloc0: (skip)
 * @memchunk: an #EMemChunk
 *
 * Allocate a new atom size block of memory from an #EMemChunk,
 * and fill the memory with zeros.  Free the returned atom with
 * e_memchunk_free().
 *
 * Returns: (transfer full): an allocated block of memory
 **/
gpointer
e_memchunk_alloc0 (EMemChunk *memchunk)
{
	gpointer mem;

	mem = e_memchunk_alloc (memchunk);
	memset (mem, 0, memchunk->atomsize);

	return mem;
}

/**
 * e_memchunk_free: (skip)
 * @memchunk: an #EMemChunk
 * @mem: address of atom to free
 *
 * Free a single atom back to the free pool of atoms in the given
 * memchunk.
 **/
void
e_memchunk_free (EMemChunk *memchunk,
                 gpointer mem)
{
	MemChunkFreeNode *f;

	/* Put the location back in the free list.  If we knew if the
	 * preceeding or following cells were free, we could merge the
	 * free nodes, but it doesn't really add much. */
	f = mem;
	f->next = memchunk->free;
	memchunk->free = f;
	f->atoms = 1;

	/* We could store the free list sorted - we could then do the above,
	 * and also probably improve the locality of reference properties for
	 * the allocator.  (And it would simplify some other algorithms at
	 * that, but slow this one down significantly.) */
}

/**
 * e_memchunk_empty: (skip)
 * @memchunk: an #EMemChunk
 *
 * Clean out the memchunk buffers.  Marks all allocated memory as free blocks,
 * but does not give it back to the system.  Can be used if the memchunk
 * is to be used repeatedly.
 **/
void
e_memchunk_empty (EMemChunk *memchunk)
{
	MemChunkFreeNode *f, *h = NULL;
	gint i;

	for (i = 0; i < memchunk->blocks->len; i++) {
		f = (MemChunkFreeNode *) memchunk->blocks->pdata[i];
		f->atoms = memchunk->blocksize;
		f->next = h;
		h = f;
	}

	memchunk->free = h;
}

struct _cleaninfo {
	struct _cleaninfo *next;
	gchar *base;
	gint count;
	gint size;		/* just so tree_search has it, sigh */
};

static gint
tree_compare (struct _cleaninfo *a,
              struct _cleaninfo *b)
{
	if (a->base < b->base)
		return -1;
	else if (a->base > b->base)
		return 1;
	return 0;
}

static gint
tree_search (struct _cleaninfo *a,
             gchar *mem)
{
	if (a->base <= mem) {
		if (mem < &a->base[a->size])
			return 0;
		return 1;
	}
	return -1;
}

/**
 * e_memchunk_clean: (skip)
 * @memchunk: an #EMemChunk
 *
 * Scan all empty blocks and check for blocks which can be free'd
 * back to the system.
 *
 * This routine may take a while to run if there are many allocated
 * memory blocks (if the total number of allocations is many times
 * greater than atomcount).
 **/
void
e_memchunk_clean (EMemChunk *memchunk)
{
	GTree *tree;
	gint i;
	MemChunkFreeNode *f;
	struct _cleaninfo *ci, *hi = NULL;

	f = memchunk->free;
	if (memchunk->blocks->len == 0 || f == NULL)
		return;

	/* first, setup the tree/list so we can map
	 * free block addresses to block addresses */
	tree = g_tree_new ((GCompareFunc) tree_compare);
	for (i = 0; i < memchunk->blocks->len; i++) {
		ci = alloca (sizeof (*ci));
		ci->count = 0;
		ci->base = memchunk->blocks->pdata[i];
		ci->size = memchunk->blocksize * memchunk->atomsize;
		g_tree_insert (tree, ci, ci);
		ci->next = hi;
		hi = ci;
	}

	/* now, scan all free nodes, and count them in their tree node */
	while (f) {
		ci = g_tree_search (tree, (GCompareFunc) tree_search, f);
		if (ci) {
			ci->count += f->atoms;
		} else {
			g_warning ("error, can't find free node in memory block\n");
		}
		f = f->next;
	}

	/* if any nodes are all free, free & unlink them */
	ci = hi;
	while (ci) {
		if (ci->count == memchunk->blocksize) {
			MemChunkFreeNode *prev = NULL;

			f = memchunk->free;
			while (f) {
				if (tree_search (ci, (gpointer) f) == 0) {
					/* prune this node from our free-node list */
					if (prev)
						prev->next = f->next;
					else
						memchunk->free = f->next;
				} else {
					prev = f;
				}

				f = f->next;
			}

			g_ptr_array_remove_fast (memchunk->blocks, ci->base);
			g_free (ci->base);
		}
		ci = ci->next;
	}

	g_tree_destroy (tree);
}

/**
 * e_memchunk_destroy: (skip)
 * @memchunk: an #EMemChunk
 *
 * Free the memchunk header, and all associated memory.
 **/
void
e_memchunk_destroy (EMemChunk *memchunk)
{
	gint i;

	if (memchunk == NULL)
		return;

	for (i = 0; i < memchunk->blocks->len; i++)
		g_free (memchunk->blocks->pdata[i]);

	g_ptr_array_free (memchunk->blocks, TRUE);

	g_free (memchunk);
}

#if 0

#define CHUNK_SIZE (20)
#define CHUNK_COUNT (32)

#define s(x)

main ()
{
	gint i;
	MemChunk *mc;
	gpointer mem, *last;
	GMemChunk *gmc;
	struct _EStrv *s;

	s = strv_new (8);
	s = strv_set (s, 1, "Testing 1");
	s = strv_set (s, 2, "Testing 2");
	s = strv_set (s, 3, "Testing 3");
	s = strv_set (s, 4, "Testing 4");
	s = strv_set (s, 5, "Testing 5");
	s = strv_set (s, 6, "Testing 7");

	for (i = 0; i < 8; i++) {
		printf ("s[%d] = %s\n", i, strv_get (s, i));
	}

	s (sleep (5));

	printf ("packing ...\n");
	s = strv_pack (s);

	for (i = 0; i < 8; i++) {
		printf ("s[%d] = %s\n", i, strv_get (s, i));
	}

	printf ("setting ...\n");

	s = strv_set_ref (s, 1, "Testing 1 x");

	for (i = 0; i < 8; i++) {
		printf ("s[%d] = %s\n", i, strv_get (s, i));
	}

	printf ("packing ...\n");
	s = strv_pack (s);

	for (i = 0; i < 8; i++) {
		printf ("s[%d] = %s\n", i, strv_get (s, i));
	}

	strv_free (s);

#if 0
	time_start ("Using memchunks");
	mc = memchunk_new (CHUNK_COUNT, CHUNK_SIZE);
	for (i = 0; i < 1000000; i++) {
		mem = memchunk_alloc (mc);
		if ((i & 1) == 0)
			memchunk_free (mc, mem);
	}
	s (sleep (10));
	memchunk_destroy (mc);
	time_end ("allocating 1000000 memchunks, freeing 500k");

	time_start ("Using gmemchunks");
	gmc = g_mem_chunk_new (
		"memchunk", CHUNK_SIZE,
		CHUNK_SIZE * CHUNK_COUNT,
		G_ALLOC_AND_FREE);
	for (i = 0; i < 1000000; i++) {
		mem = g_mem_chunk_alloc (gmc);
		if ((i & 1) == 0)
			g_mem_chunk_free (gmc, mem);
	}
	s (sleep (10));
	g_mem_chunk_destroy (gmc);
	time_end ("allocating 1000000 gmemchunks, freeing 500k");

	time_start ("Using memchunks");
	mc = memchunk_new (CHUNK_COUNT, CHUNK_SIZE);
	for (i = 0; i < 1000000; i++) {
		mem = memchunk_alloc (mc);
	}
	s (sleep (10));
	memchunk_destroy (mc);
	time_end ("allocating 1000000 memchunks");

	time_start ("Using gmemchunks");
	gmc = g_mem_chunk_new (
		"memchunk", CHUNK_SIZE,
		CHUNK_COUNT * CHUNK_SIZE,
		G_ALLOC_ONLY);
	for (i = 0; i < 1000000; i++) {
		mem = g_mem_chunk_alloc (gmc);
	}
	s (sleep (10));
	g_mem_chunk_destroy (gmc);
	time_end ("allocating 1000000 gmemchunks");

	time_start ("Using malloc");
	for (i = 0; i < 1000000; i++) {
		malloc (CHUNK_SIZE);
	}
	time_end ("allocating 1000000 malloc");
#endif

}

#endif
