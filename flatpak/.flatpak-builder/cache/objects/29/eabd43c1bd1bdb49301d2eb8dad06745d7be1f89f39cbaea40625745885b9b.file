/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; fill-column: 160 -*- */
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

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include <glib/gstdio.h>

#include "camel-block-file.h"
#include "camel-mempool.h"
#include "camel-object.h"
#include "camel-partition-table.h"
#include "camel-text-index.h"

#define w(x)
#define io(x)
#define d(x) /*(printf ("%s (%d):%s: ",  __FILE__, __LINE__, __PRETTY_FUNCTION__),(x))*/

/* cursor debug */
#define c(x)

#define CAMEL_TEXT_INDEX_MAX_WORDLEN  (36)

#define CAMEL_TEXT_INDEX_LOCK(kf, lock) \
	(g_rec_mutex_lock (&((CamelTextIndex *) kf)->priv->lock))
#define CAMEL_TEXT_INDEX_UNLOCK(kf, lock) \
	(g_rec_mutex_unlock (&((CamelTextIndex *) kf)->priv->lock))

static gint text_index_compress_nosync (CamelIndex *idx);

/* ********************************************************************** */

#define CAMEL_TEXT_INDEX_NAME_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_TEXT_INDEX_NAME, CamelTextIndexNamePrivate))

struct _CamelTextIndexNamePrivate {
	GString *buffer;
	camel_key_t nameid;
	CamelMemPool *pool;
};

CamelTextIndexName *camel_text_index_name_new (CamelTextIndex *idx, const gchar *name, camel_key_t nameid);

/* ****************************** */

#define CAMEL_TEXT_INDEX_CURSOR_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_TEXT_INDEX_CURSOR, CamelTextIndexCursorPrivate))

struct _CamelTextIndexCursorPrivate {
	camel_block_t first;
	camel_block_t next;

	gint record_index;

	gsize record_count;
	camel_key_t *records;

	gchar *current;
};

CamelTextIndexCursor *camel_text_index_cursor_new (CamelTextIndex *idx, camel_block_t data);

/* ****************************** */

#define CAMEL_TEXT_INDEX_KEY_CURSOR_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_TEXT_INDEX_KEY_CURSOR, CamelTextIndexKeyCursorPrivate))

struct _CamelTextIndexKeyCursorPrivate {
	CamelKeyTable *table;

	camel_key_t keyid;
	guint flags;
	camel_block_t data;
	gchar *current;
};

CamelTextIndexKeyCursor *camel_text_index_key_cursor_new (CamelTextIndex *idx, CamelKeyTable *table);

/* ********************************************************************** */

#define CAMEL_TEXT_INDEX_VERSION "TEXT.000"
#define CAMEL_TEXT_INDEX_KEY_VERSION "KEYS.000"

#define CAMEL_TEXT_INDEX_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), CAMEL_TYPE_TEXT_INDEX, CamelTextIndexPrivate))

struct _CamelTextIndexPrivate {
	CamelBlockFile *blocks;
	CamelKeyFile *links;

	CamelKeyTable *word_index;
	CamelPartitionTable *word_hash;

	CamelKeyTable *name_index;
	CamelPartitionTable *name_hash;

	/* Cache of words to write */
	guint word_cache_limit;
	GQueue word_cache;
	GHashTable *words;
	GRecMutex lock;
};

/* Root block of text index */
struct _CamelTextIndexRoot {
	struct _CamelBlockRoot root;

	/* FIXME: the index root could contain a pointer to the hash root */
	camel_block_t word_index_root; /* a keyindex containing the keyid -> word mapping */
	camel_block_t word_hash_root; /* a partitionindex containing word -> keyid mapping */

	camel_block_t name_index_root; /* same, for names */
	camel_block_t name_hash_root;

	guint32 words;		/* total words */
	guint32 names;		/* total names */
	guint32 deleted;	/* deleted names */
	guint32 keys;		/* total key 'chunks' written, used with deleted to determine fragmentation */
};

struct _CamelTextIndexWord {
	camel_block_t data;	/* where the data starts */
	camel_key_t wordid;
	gchar *word;
	guint used;
	camel_key_t names[32];
};

/* ********************************************************************** */
/* CamelTextIndex */
/* ********************************************************************** */

G_DEFINE_TYPE (CamelTextIndex, camel_text_index, CAMEL_TYPE_INDEX)

static void
text_index_dispose (GObject *object)
{
	CamelTextIndexPrivate *priv;

	priv = CAMEL_TEXT_INDEX_GET_PRIVATE (object);

	/* Only run this the first time. */
	if (priv->word_index != NULL)
		camel_index_sync (CAMEL_INDEX (object));

	if (priv->word_index != NULL) {
		g_object_unref (priv->word_index);
		priv->word_index = NULL;
	}

	if (priv->word_hash != NULL) {
		g_object_unref (priv->word_hash);
		priv->word_hash = NULL;
	}

	if (priv->name_index != NULL) {
		g_object_unref (priv->name_index);
		priv->name_index = NULL;
	}

	if (priv->name_hash != NULL) {
		g_object_unref (priv->name_hash);
		priv->name_hash = NULL;
	}

	if (priv->blocks != NULL) {
		g_object_unref (priv->blocks);
		priv->blocks = NULL;
	}

	if (priv->links != NULL) {
		g_object_unref (priv->links);
		priv->links = NULL;
	}

	/* Chain up to parent's dispose () method. */
	G_OBJECT_CLASS (camel_text_index_parent_class)->dispose (object);
}

static void
text_index_finalize (GObject *object)
{
	CamelTextIndexPrivate *priv;

	priv = CAMEL_TEXT_INDEX_GET_PRIVATE (object);

	g_warn_if_fail (g_queue_is_empty (&priv->word_cache));
	g_warn_if_fail (g_hash_table_size (priv->words) == 0);

	g_hash_table_destroy (priv->words);

	g_rec_mutex_clear (&priv->lock);

	/* Chain up to parent's finalize () method. */
	G_OBJECT_CLASS (camel_text_index_parent_class)->finalize (object);
}

/* call locked */
static void
text_index_add_name_to_word (CamelIndex *idx,
                             const gchar *word,
                             camel_key_t nameid)
{
	struct _CamelTextIndexWord *w;
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX (idx)->priv;
	camel_key_t wordid;
	camel_block_t data;
	struct _CamelTextIndexRoot *rb = (struct _CamelTextIndexRoot *) camel_block_file_get_root (p->blocks);

	w = g_hash_table_lookup (p->words, word);
	if (w == NULL) {
		GQueue trash = G_QUEUE_INIT;
		GList *link;
		guint length;

		wordid = camel_partition_table_lookup (p->word_hash, word);
		if (wordid == 0) {
			data = 0;
			wordid = camel_key_table_add (p->word_index, word, 0, 0);
			if (wordid == 0) {
				g_warning (
					"Could not create key entry for word '%s': %s\n",
					word, g_strerror (errno));
				return;
			}
			if (camel_partition_table_add (p->word_hash, word, wordid) == -1) {
				g_warning (
					"Could not create hash entry for word '%s': %s\n",
					word, g_strerror (errno));
				return;
			}
			rb->words++;
			camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
		} else {
			data = camel_key_table_lookup (p->word_index, wordid, NULL, NULL);
			if (data == 0) {
				g_warning (
					"Could not find key entry for word '%s': %s\n",
					word, g_strerror (errno));
				return;
			}
		}

		w = g_malloc0 (sizeof (*w));
		w->word = g_strdup (word);
		w->wordid = wordid;
		w->used = 1;
		w->data = data;

		w->names[0] = nameid;
		g_hash_table_insert (p->words, w->word, w);
		g_queue_push_head (&p->word_cache, w);

		length = p->word_cache.length;
		link = g_queue_peek_tail_link (&p->word_cache);

		while (link != NULL && length > p->word_cache_limit) {
			struct _CamelTextIndexWord *ww = link->data;

			io (printf ("writing key file entry '%s' [%x]\n", ww->word, ww->data));
			if (camel_key_file_write (p->links, &ww->data, ww->used, ww->names) != -1) {
				io (printf ("  new data [%x]\n", ww->data));
				rb->keys++;
				camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
				/* if this call fails - we still point to the old data - not fatal */
				camel_key_table_set_data (
					p->word_index, ww->wordid, ww->data);
				g_hash_table_remove (p->words, ww->word);
				g_queue_push_tail (&trash, link);
				link->data = NULL;
				g_free (ww->word);
				g_free (ww);
				length--;
			}

			link = g_list_previous (link);
		}

		/* Remove deleted words from the cache. */
		while ((link = g_queue_pop_head (&trash)) != NULL)
			g_queue_delete_link (&p->word_cache, link);

	} else {
		g_queue_remove (&p->word_cache, w);
		g_queue_push_head (&p->word_cache, w);
		w->names[w->used] = nameid;
		w->used++;
		if (w->used == G_N_ELEMENTS (w->names)) {
			io (printf ("writing key file entry '%s' [%x]\n", w->word, w->data));
			if (camel_key_file_write (p->links, &w->data, w->used, w->names) != -1) {
				rb->keys++;
				camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
				/* if this call fails - we still point to the old data - not fatal */
				camel_key_table_set_data (
					p->word_index, w->wordid, w->data);
			}
			/* FIXME: what to on error?  lost data? */
			w->used = 0;
		}
	}
}

static gint
text_index_sync (CamelIndex *idx)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
	struct _CamelTextIndexWord *ww;
	struct _CamelTextIndexRoot *rb;
	gint ret = 0, wfrag, nfrag;

	d (printf ("sync: blocks = %p\n", p->blocks));

	if (p->blocks == NULL || p->links == NULL
	    || p->word_index == NULL || p->word_hash == NULL
	    || p->name_index == NULL || p->name_hash == NULL)
		return 0;

	rb = (struct _CamelTextIndexRoot *) camel_block_file_get_root (p->blocks);

	/* sync/flush word cache */

	CAMEL_TEXT_INDEX_LOCK (idx, lock);

	/* we sync, bump down the cache limits since we dont need them for reading */
	camel_block_file_set_cache_limit (p->blocks, 128);
	/* this doesn't really need to be dropped, its only used in updates anyway */
	p->word_cache_limit = 1024;

	while ((ww = g_queue_pop_head (&p->word_cache))) {
		if (ww->used > 0) {
			io (printf ("writing key file entry '%s' [%x]\n", ww->word, ww->data));
			if (camel_key_file_write (p->links, &ww->data, ww->used, ww->names) != -1) {
				io (printf ("  new data [%x]\n", ww->data));
				rb->keys++;
				camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
				camel_key_table_set_data (
					p->word_index, ww->wordid, ww->data);
			} else {
				ret = -1;
			}
			ww->used = 0;
		}
		g_hash_table_remove (p->words, ww->word);
		g_free (ww->word);
		g_free (ww);
	}

	if (camel_key_table_sync (p->word_index) == -1
	    || camel_key_table_sync (p->name_index) == -1
	    || camel_partition_table_sync (p->word_hash) == -1
	    || camel_partition_table_sync (p->name_hash) == -1)
		ret = -1;

	/* only do the frag/compress check if we did some new writes on this index */
	wfrag = rb->words ? (((rb->keys - rb->words) * 100)/ rb->words) : 0;
	nfrag = rb->names ? ((rb->deleted * 100) / rb->names) : 0;
	d (printf ("  words = %d, keys = %d\n", rb->words, rb->keys));

	if (ret == 0) {
		if (wfrag > 30 || nfrag > 20)
			ret = text_index_compress_nosync (idx);
	}

	ret = ret == -1 ? ret : camel_block_file_sync (p->blocks);

	CAMEL_TEXT_INDEX_UNLOCK (idx, lock);

	return ret;
}

static void
tmp_name (const gchar *in,
          gchar *o,
          gsize o_len)
{
	gchar *s;

	s = strrchr (in, '/');
	if (s) {
		memcpy (o, in, s - in + 1);
		memcpy (o + (s - in + 1), ".#", 2);
		strcpy (o + (s - in + 3), s + 1);
	} else {
		g_snprintf (o, o_len, ".#%s", in);
	}
}

static gint
text_index_compress (CamelIndex *idx)
{
	gint ret;

	CAMEL_TEXT_INDEX_LOCK (idx, lock);

	ret = camel_index_sync (idx);
	if (ret != -1)
		ret = text_index_compress_nosync (idx);

	CAMEL_TEXT_INDEX_UNLOCK (idx, lock);

	return ret;
}

/* Attempt to recover index space by compressing the indices */
static gint
text_index_compress_nosync (CamelIndex *idx)
{
	CamelTextIndex *newidx;
	CamelTextIndexPrivate *newp, *oldp;
	camel_key_t oldkeyid, newkeyid;
	GHashTable *remap;
	guint deleted;
	camel_block_t data, newdata;
	gint i, ret = -1;
	gchar *name = NULL;
	guint flags;
	gchar *newpath, *savepath, *oldpath;
	gsize count, newcount;
	camel_key_t *records, newrecords[256];
	struct _CamelTextIndexRoot *rb;

	i = strlen (idx->path) + 16;
	oldpath = alloca (i);
	newpath = alloca (i);
	savepath = alloca (i);

	g_strlcpy (oldpath, idx->path, i);
	oldpath[strlen (oldpath) - strlen (".index")] = 0;

	tmp_name (oldpath, newpath, i);
	g_snprintf (savepath, i, "%s~", oldpath);

	d (printf ("Old index: %s\n", idx->path));
	d (printf ("Old path: %s\n", oldpath));
	d (printf ("New: %s\n", newpath));
	d (printf ("Save: %s\n", savepath));

	newidx = camel_text_index_new (newpath, O_RDWR | O_CREAT);
	if (newidx == NULL)
		return -1;

	newp = CAMEL_TEXT_INDEX_GET_PRIVATE (newidx);
	oldp = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);

	CAMEL_TEXT_INDEX_LOCK (idx, lock);

	rb = (struct _CamelTextIndexRoot *) camel_block_file_get_root (newp->blocks);

	rb->words = 0;
	rb->names = 0;
	rb->deleted = 0;
	rb->keys = 0;

	/* Process:
	 * For each name we still have:
	 * Add it to the new index & setup remap table
	 *
	 * For each word:
	 * Copy word's data to a new file
	 * Add new word to index (*) (can we just copy blocks?) */

	/* Copy undeleted names to new index file, creating new indices */
	io (printf ("Copying undeleted names to new file\n"));
	remap = g_hash_table_new (NULL, NULL);
	oldkeyid = 0;
	deleted = 0;
	while ((oldkeyid = camel_key_table_next (oldp->name_index, oldkeyid, &name, &flags, &data))) {
		if ((flags&1) == 0) {
			io (printf ("copying name '%s'\n", name));
			newkeyid = camel_key_table_add (
				newp->name_index, name, data, flags);
			if (newkeyid == 0)
				goto fail;
			rb->names++;
			camel_partition_table_add (
				newp->name_hash, name, newkeyid);
			g_hash_table_insert (remap, GINT_TO_POINTER (oldkeyid), GINT_TO_POINTER (newkeyid));
		} else {
			io (printf ("deleted name '%s'\n", name));
		}
		g_free (name);
		name = NULL;
		deleted |= flags;
	}

	/* Copy word data across, remapping/deleting and create new index for it */
	/* We re-block the data into 256 entry lots while we're at it, since we only
	 * have to do 1 at a time and its cheap */
	oldkeyid = 0;
	while ((oldkeyid = camel_key_table_next (oldp->word_index, oldkeyid, &name, &flags, &data))) {
		io (printf ("copying word '%s'\n", name));
		newdata = 0;
		newcount = 0;
		if (data) {
			rb->words++;
			rb->keys++;
		}
		while (data) {
			if (camel_key_file_read (oldp->links, &data, &count, &records) == -1) {
				io (printf ("could not read from old keys at %d for word '%s'\n", (gint) data, name));
				goto fail;
			}
			for (i = 0; i < count; i++) {
				newkeyid = (camel_key_t) GPOINTER_TO_INT (g_hash_table_lookup (remap, GINT_TO_POINTER (records[i])));
				if (newkeyid) {
					newrecords[newcount++] = newkeyid;
					if (newcount == G_N_ELEMENTS (newrecords)) {
						if (camel_key_file_write (newp->links, &newdata, newcount, newrecords) == -1) {
							g_free (records);
							goto fail;
						}
						newcount = 0;
					}
				}
			}
			g_free (records);
		}

		if (newcount > 0) {
			if (camel_key_file_write (newp->links, &newdata, newcount, newrecords) == -1)
				goto fail;
		}

		if (newdata != 0) {
			newkeyid = camel_key_table_add (
				newp->word_index, name, newdata, flags);
			if (newkeyid == 0)
				goto fail;
			camel_partition_table_add (
				newp->word_hash, name, newkeyid);
		}
		g_free (name);
		name = NULL;
	}

	camel_block_file_touch_block (newp->blocks, camel_block_file_get_root_block (newp->blocks));

	if (camel_index_sync (CAMEL_INDEX (newidx)) == -1)
		goto fail;

	/* Rename underlying files to match */
	ret = camel_index_rename (idx, savepath);
	if (ret == -1)
		goto fail;

	/* If this fails, we'll pick up something during restart? */
	ret = camel_index_rename ((CamelIndex *) newidx, oldpath);

#define myswap(a, b) { gpointer tmp = a; a = b; b = tmp; }
	/* Poke the private data across to the new object */
	/* And change the fd's over, etc? */
	/* Yes: This is a hack */
	myswap (newp->blocks, oldp->blocks);
	myswap (newp->links, oldp->links);
	myswap (newp->word_index, oldp->word_index);
	myswap (newp->word_hash, oldp->word_hash);
	myswap (newp->name_index, oldp->name_index);
	myswap (newp->name_hash, oldp->name_hash);
	myswap (((CamelIndex *) newidx)->path, ((CamelIndex *) idx)->path);
#undef myswap

	ret = 0;
fail:
	CAMEL_TEXT_INDEX_UNLOCK (idx, lock);

	camel_index_delete ((CamelIndex *) newidx);

	g_object_unref (newidx);
	g_free (name);
	g_hash_table_destroy (remap);

	/* clean up temp files always */
	g_snprintf (savepath, i, "%s~.index", oldpath);
	g_unlink (savepath);
	g_snprintf (newpath, i, "%s.data", savepath);
	g_unlink (newpath);

	return ret;
}

static gint
text_index_delete (CamelIndex *idx)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
	gint ret = 0;

	if (camel_block_file_delete (p->blocks) == -1)
		ret = -1;
	if (camel_key_file_delete (p->links) == -1)
		ret = -1;

	return ret;
}

static gint
text_index_rename (CamelIndex *idx,
                   const gchar *path)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
	gchar *newlink, *newblock;
	gsize newlink_len, newblock_len;
	gint err, ret;

	CAMEL_TEXT_INDEX_LOCK (idx, lock);

	newblock_len = strlen (path) + 8;
	newblock = alloca (newblock_len);
	g_snprintf (newblock, newblock_len, "%s.index", path);
	ret = camel_block_file_rename (p->blocks, newblock);
	if (ret == -1) {
		CAMEL_TEXT_INDEX_UNLOCK (idx, lock);
		return -1;
	}

	newlink_len = strlen (path) + 16;
	newlink = alloca (newlink_len);
	g_snprintf (newlink, newlink_len, "%s.index.data", path);
	ret = camel_key_file_rename (p->links, newlink);
	if (ret == -1) {
		err = errno;
		camel_block_file_rename (p->blocks, idx->path);
		CAMEL_TEXT_INDEX_UNLOCK (idx, lock);
		errno = err;
		return -1;
	}

	g_free (idx->path);
	idx->path = g_strdup (newblock);

	CAMEL_TEXT_INDEX_UNLOCK (idx, lock);

	return 0;
}

static gint
text_index_has_name (CamelIndex *idx,
                     const gchar *name)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);

	return camel_partition_table_lookup (p->name_hash, name) != 0;
}

static CamelIndexName *
text_index_add_name (CamelIndex *idx,
                     const gchar *name)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
	camel_key_t keyid;
	CamelIndexName *idn;
	struct _CamelTextIndexRoot *rb = (struct _CamelTextIndexRoot *) camel_block_file_get_root (p->blocks);

	CAMEL_TEXT_INDEX_LOCK (idx, lock);

	/* if we're adding words, up the cache limits a lot */
	if (p->word_cache_limit < 8192) {
		camel_block_file_set_cache_limit (p->blocks, 1024);
		p->word_cache_limit = 8192;
	}

	/* If we have it already replace it */
	keyid = camel_partition_table_lookup (p->name_hash, name);
	if (keyid != 0) {
		/* TODO: We could just update the partition table's
		 * key pointer rather than having to delete it */
		rb->deleted++;
		camel_key_table_set_flags (p->name_index, keyid, 1, 1);
		camel_partition_table_remove (p->name_hash, name);
	}

	keyid = camel_key_table_add (p->name_index, name, 0, 0);
	if (keyid != 0) {
		camel_partition_table_add (p->name_hash, name, keyid);
		rb->names++;
	}

	camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));

	/* TODO: if keyid == 0, we had a failure, we should somehow flag that, but for
	 * now just return a valid object but discard its results, see text_index_write_name */

	CAMEL_TEXT_INDEX_UNLOCK (idx, lock);

	idn = (CamelIndexName *) camel_text_index_name_new ((CamelTextIndex *) idx, name, keyid);

	return idn;
}

/* call locked */
static void
hash_write_word (gchar *word,
                 gpointer data,
                 CamelIndexName *idn)
{
	CamelTextIndexName *tin = (CamelTextIndexName *) idn;

	text_index_add_name_to_word (idn->index, word, tin->priv->nameid);
}

static gint
text_index_write_name (CamelIndex *idx,
                       CamelIndexName *idn)
{
	/* force 'flush' of any outstanding data */
	camel_index_name_add_buffer (idn, NULL, 0);

	/* see text_index_add_name for when this can be 0 */
	if (((CamelTextIndexName *) idn)->priv->nameid != 0) {
		CAMEL_TEXT_INDEX_LOCK (idx, lock);

		g_hash_table_foreach (idn->words, (GHFunc) hash_write_word, idn);

		CAMEL_TEXT_INDEX_UNLOCK (idx, lock);
	}

	return 0;
}

static CamelIndexCursor *
text_index_find_name (CamelIndex *idx,
                      const gchar *name)
{
	/* what was this for, umm */
	return NULL;
}

static void
text_index_delete_name (CamelIndex *idx,
                        const gchar *name)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
	camel_key_t keyid;
	struct _CamelTextIndexRoot *rb = (struct _CamelTextIndexRoot *) camel_block_file_get_root (p->blocks);

	d (printf ("Delete name: %s\n", name));

	/* probably doesn't really need locking, but oh well */
	CAMEL_TEXT_INDEX_LOCK (idx, lock);

	/* We just mark the key deleted, and remove it from the hash table */
	keyid = camel_partition_table_lookup (p->name_hash, name);
	if (keyid != 0) {
		rb->deleted++;
		camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
		camel_key_table_set_flags (p->name_index, keyid, 1, 1);
		camel_partition_table_remove (p->name_hash, name);
	}

	CAMEL_TEXT_INDEX_UNLOCK (idx, lock);
}

static CamelIndexCursor *
text_index_find (CamelIndex *idx,
                 const gchar *word)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
	camel_key_t keyid;
	camel_block_t data = 0;
	guint flags;
	CamelIndexCursor *idc;

	CAMEL_TEXT_INDEX_LOCK (idx, lock);

	keyid = camel_partition_table_lookup (p->word_hash, word);
	if (keyid != 0) {
		data = camel_key_table_lookup (
			p->word_index, keyid, NULL, &flags);
		if (flags & 1)
			data = 0;
	}

	CAMEL_TEXT_INDEX_UNLOCK (idx, lock);

	idc = (CamelIndexCursor *) camel_text_index_cursor_new ((CamelTextIndex *) idx, data);

	return idc;
}

static CamelIndexCursor *
text_index_words (CamelIndex *idx)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);

	return (CamelIndexCursor *) camel_text_index_key_cursor_new ((CamelTextIndex *) idx, p->word_index);
}

static void
camel_text_index_class_init (CamelTextIndexClass *class)
{
	GObjectClass *object_class;
	CamelIndexClass *index_class;

	g_type_class_add_private (class, sizeof (CamelTextIndexPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = text_index_dispose;
	object_class->finalize = text_index_finalize;

	index_class = CAMEL_INDEX_CLASS (class);
	index_class->sync = text_index_sync;
	index_class->compress = text_index_compress;
	index_class->delete_ = text_index_delete;
	index_class->rename = text_index_rename;
	index_class->has_name = text_index_has_name;
	index_class->add_name = text_index_add_name;
	index_class->write_name = text_index_write_name;
	index_class->find_name = text_index_find_name;
	index_class->delete_name = text_index_delete_name;
	index_class->find = text_index_find;
	index_class->words = text_index_words;
}

static void
camel_text_index_init (CamelTextIndex *text_index)
{
	text_index->priv = CAMEL_TEXT_INDEX_GET_PRIVATE (text_index);

	g_queue_init (&text_index->priv->word_cache);
	text_index->priv->words = g_hash_table_new (g_str_hash, g_str_equal);

	/* This cache size and the block cache size have been tuned for
	 * about the best with moderate memory usage.  Doubling the memory
	 * usage barely affects performance. */
	text_index->priv->word_cache_limit = 4096; /* 1024 = 128K */

	g_rec_mutex_init (&text_index->priv->lock);
}

static gchar *
text_index_normalize (CamelIndex *idx,
                      const gchar *in,
                      gpointer data)
{
	gchar *word;

	/* Sigh, this is really expensive */
	/*g_utf8_normalize (in, strlen (in), G_NORMALIZE_ALL);*/
	word = g_utf8_strdown (in, -1);

	return word;
}

CamelTextIndex *
camel_text_index_new (const gchar *path,
                      gint flags)
{
	CamelTextIndex *idx = g_object_new (CAMEL_TYPE_TEXT_INDEX, NULL);
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
	struct _CamelTextIndexRoot *rb;
	gchar *link;
	gsize link_len;
	CamelBlock *bl;

	camel_index_construct ((CamelIndex *) idx, path, flags);
	camel_index_set_normalize ((CamelIndex *) idx, text_index_normalize, NULL);

	p->blocks = camel_block_file_new (
		idx->parent.path, flags, CAMEL_TEXT_INDEX_VERSION, CAMEL_BLOCK_SIZE);
	if (p->blocks == NULL)
		goto fail;

	link_len = strlen (idx->parent.path) + 7;
	link = alloca (link_len);
	g_snprintf (link, link_len, "%s.data", idx->parent.path);
	p->links = camel_key_file_new (link, flags, CAMEL_TEXT_INDEX_KEY_VERSION);

	if (p->links == NULL)
		goto fail;

	rb = (struct _CamelTextIndexRoot *) camel_block_file_get_root (p->blocks);

	if (rb->word_index_root == 0) {
		bl = camel_block_file_new_block (p->blocks);

		if (bl == NULL)
			goto fail;

		rb->word_index_root = bl->id;
		camel_block_file_unref_block (p->blocks, bl);
		camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
	}

	if (rb->word_hash_root == 0) {
		bl = camel_block_file_new_block (p->blocks);

		if (bl == NULL)
			goto fail;

		rb->word_hash_root = bl->id;
		camel_block_file_unref_block (p->blocks, bl);
		camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
	}

	if (rb->name_index_root == 0) {
		bl = camel_block_file_new_block (p->blocks);

		if (bl == NULL)
			goto fail;

		rb->name_index_root = bl->id;
		camel_block_file_unref_block (p->blocks, bl);
		camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
	}

	if (rb->name_hash_root == 0) {
		bl = camel_block_file_new_block (p->blocks);

		if (bl == NULL)
			goto fail;

		rb->name_hash_root = bl->id;
		camel_block_file_unref_block (p->blocks, bl);
		camel_block_file_touch_block (p->blocks, camel_block_file_get_root_block (p->blocks));
	}

	p->word_index = camel_key_table_new (p->blocks, rb->word_index_root);
	p->word_hash = camel_partition_table_new (p->blocks, rb->word_hash_root);
	p->name_index = camel_key_table_new (p->blocks, rb->name_index_root);
	p->name_hash = camel_partition_table_new (p->blocks, rb->name_hash_root);

	if (p->word_index == NULL || p->word_hash == NULL
	    || p->name_index == NULL || p->name_hash == NULL) {
		g_object_unref (idx);
		idx = NULL;
	}

	return idx;

fail:
	g_object_unref (idx);
	return NULL;
}

/* returns 0 if the index exists, is valid, and synced, -1 otherwise */
gint
camel_text_index_check (const gchar *path)
{
	gchar *block, *key;
	gsize block_len, key_len;
	CamelBlockFile *blocks;
	CamelKeyFile *keys;

	block_len = strlen (path) + 7;
	block = alloca (block_len);
	g_snprintf (block, block_len, "%s.index", path);
	blocks = camel_block_file_new (block, O_RDONLY, CAMEL_TEXT_INDEX_VERSION, CAMEL_BLOCK_SIZE);
	if (blocks == NULL) {
		io (printf ("Check failed: No block file: %s\n", g_strerror (errno)));
		return -1;
	}
	key_len = strlen (path) + 12;
	key = alloca (key_len);
	g_snprintf (key, key_len, "%s.index.data", path);
	keys = camel_key_file_new (key, O_RDONLY, CAMEL_TEXT_INDEX_KEY_VERSION);
	if (keys == NULL) {
		io (printf ("Check failed: No key file: %s\n", g_strerror (errno)));
		g_object_unref (blocks);
		return -1;
	}

	g_object_unref (keys);
	g_object_unref (blocks);

	return 0;
}

gint
camel_text_index_rename (const gchar *old,
                         const gchar *new)
{
	gchar *oldname, *newname;
	gsize oldname_len, newname_len;
	gint err;

	/* TODO: camel_text_index_rename should find out if we have an active index and use that instead */

	oldname_len = strlen (old) + 12;
	newname_len = strlen (new) + 12;
	oldname = alloca (oldname_len);
	newname = alloca (newname_len);
	g_snprintf (oldname, oldname_len, "%s.index", old);
	g_snprintf (newname, newname_len, "%s.index", new);

	if (g_rename (oldname, newname) == -1 && errno != ENOENT)
		return -1;

	g_snprintf (oldname, oldname_len, "%s.index.data", old);
	g_snprintf (newname, newname_len, "%s.index.data", new);

	if (g_rename (oldname, newname) == -1 && errno != ENOENT) {
		err = errno;
		g_snprintf (oldname, oldname_len, "%s.index", old);
		g_snprintf (newname, newname_len, "%s.index", new);
		if (g_rename (newname, oldname) == -1) {
			g_warning (
				"%s: Failed to rename '%s' to '%s': %s",
				G_STRFUNC, newname, oldname, g_strerror (errno));
		}
		errno = err;
		return -1;
	}

	return 0;
}

gint
camel_text_index_remove (const gchar *old)
{
	gchar *block, *key;
	gsize block_len, key_len;
	gint ret = 0;

	/* TODO: needs to poke any active indices to remain unlinked */

	block_len = strlen (old) + 12;
	block = alloca (block_len);
	key_len = strlen (old) + 12;
	key = alloca (key_len);
	g_snprintf (block, block_len, "%s.index", old);
	g_snprintf (key, key_len, "%s.index.data", old);

	if (g_unlink (block) == -1 && errno != ENOENT && errno != ENOTDIR)
		ret = -1;
	if (g_unlink (key) == -1 && errno != ENOENT && errno != ENOTDIR)
		ret = -1;

	if (ret == 0)
		errno = 0;

	return ret;
}

/* Debug */
void
camel_text_index_info (CamelTextIndex *idx)
{
	CamelTextIndexPrivate *p = idx->priv;
	struct _CamelTextIndexRoot *rb = (struct _CamelTextIndexRoot *) camel_block_file_get_root (p->blocks);
	gint frag;

	printf ("Path: '%s'\n", idx->parent.path);
	printf ("Version: %u\n", idx->parent.version);
	printf ("Flags: %08x\n", idx->parent.flags);
	printf ("Total words: %u\n", rb->words);
	printf ("Total names: %u\n", rb->names);
	printf ("Total deleted: %u\n", rb->deleted);
	printf ("Total key blocks: %u\n", rb->keys);

	if (rb->words > 0) {
		frag = ((rb->keys - rb->words) * 100)/ rb->words;
		printf ("Word fragmentation: %d%%\n", frag);
	}

	if (rb->names > 0) {
		frag = (rb->deleted * 100)/ rb->names;
		printf ("Name fragmentation: %d%%\n", frag);
	}
}

/* #define DUMP_RAW */

#ifdef DUMP_RAW
enum { KEY_ROOT = 1, KEY_DATA = 2, PARTITION_MAP = 4, PARTITION_DATA = 8 };

static void
add_type (GHashTable *map,
          camel_block_t id,
          gint type)
{
	camel_block_t old;

	old = g_hash_table_lookup (map, id);
	if (old == type)
		return;

	if (old != 0 && old != type)
		g_warning ("block %x redefined as type %d, already type %d\n", id, type, old);
	g_hash_table_insert (map, id, GINT_TO_POINTER (type | old));
}

static void
add_partition (GHashTable *map,
               CamelBlockFile *blocks,
               camel_block_t id)
{
	CamelBlock *bl;
	CamelPartitionMapBlock *pm;
	gint i;

	while (id) {
		add_type (map, id, PARTITION_MAP);
		bl = camel_block_file_get_block (blocks, id);
		if (bl == NULL) {
			g_warning ("couldn't get parition: %x\n", id);
			return;
		}

		pm = (CamelPartitionMapBlock *) &bl->data;
		if (pm->used > G_N_ELEMENTS (pm->partition)) {
			g_warning ("Partition block %x invalid\n", id);
			camel_block_file_unref_block (blocks, bl);
			return;
		}

		for (i = 0; i < pm->used; i++)
			add_type (map, pm->partition[i].blockid, PARTITION_DATA);

		id = pm->next;
		camel_block_file_unref_block (blocks, bl);
	}
}

static void
add_keys (GHashTable *map,
          CamelBlockFile *blocks,
          camel_block_t id)
{
	CamelBlock *rbl, *bl;
	CamelKeyRootBlock *root;
	CamelKeyBlock *kb;

	add_type (map, id, KEY_ROOT);
	rbl = camel_block_file_get_block (blocks, id);
	if (rbl == NULL) {
		g_warning ("couldn't get key root: %x\n", id);
		return;
	}
	root = (CamelKeyRootBlock *) &rbl->data;
	id = root->first;

	while (id) {
		add_type (map, id, KEY_DATA);
		bl = camel_block_file_get_block (blocks, id);
		if (bl == NULL) {
			g_warning ("couldn't get key: %x\n", id);
			break;
		}

		kb = (CamelKeyBlock *) &bl->data;
		id = kb->next;
		camel_block_file_unref_block (blocks, bl);
	}

	camel_block_file_unref_block (blocks, rbl);
}

static void
dump_raw (GHashTable *map,
          gchar *path)
{
	gchar buf[1024];
	gchar line[256];
	gchar *p, c, *e, *a, *o;
	gint v, n, len, i, type;
	gchar hex[16] = "0123456789ABCDEF";
	gint fd;
	camel_block_t id, total;

	fd = g_open (path, O_RDONLY | O_BINARY, 0);
	if (fd == -1)
		return;

	total = 0;
	while ((len = read (fd, buf, 1024)) == 1024) {
		id = total;

		type = g_hash_table_lookup (map, id);
		switch (type) {
		case 0:
			printf (" - unknown -\n");
			break;
		default:
			printf (" - invalid -\n");
			break;
		case KEY_ROOT: {
			CamelKeyRootBlock *r = (CamelKeyRootBlock *) buf;
			printf ("Key root:\n");
			printf ("First: %08x     Last: %08x     Free: %08x\n", r->first, r->last, r->free);
		} break;
		case KEY_DATA: {
			CamelKeyBlock *k = (CamelKeyBlock *) buf;
			printf ("Key data:\n");
			printf ("Next: %08x      Used: %u\n", k->next, k->used);
			for (i = 0; i < k->used; i++) {
				if (i == 0)
					len = sizeof (k->u.keydata);
				else
					len = k->u.keys[i - 1].offset;
				len -= k->u.keys[i].offset;
				printf (
					"[%03d]: %08x %5d %06x %3d '%.*s'\n", i,
					k->u.keys[i].data, k->u.keys[i].offset, k->u.keys[i].flags,
					len, len, k->u.keydata + k->u.keys[i].offset);
			}
		} break;
		case PARTITION_MAP: {
			CamelPartitionMapBlock *m = (CamelPartitionMapBlock *) buf;
			printf ("Partition map\n");
			printf ("Next: %08x      Used: %u\n", m->next, m->used);
			for (i = 0; i < m->used; i++) {
				printf ("[%03d]: %08x -> %08x\n", i, m->partition[i].hashid, m->partition[i].blockid);
			}
		} break;
		case PARTITION_DATA: {
			CamelPartitionKeyBlock *k = (CamelPartitionKeyBlock *) buf;
			printf ("Partition data\n");
			printf ("Used: %u\n", k->used);
		} break;
		}

		printf ("--raw--\n");

		len = 1024;
		p = buf;
		do {
			g_snprintf (line, sizeof (line), "%08x:                                                                      ", total);
			total += 16;
			o = line + 10;
			a = o + 16 * 2 + 2;
			i = 0;
			while (len && i < 16) {
				c = *p++;
				*a++ = isprint (c)?c:'.';
				*o++ = hex[(c>>4)&0x0f];
				*o++ = hex[c&0x0f];
				i++;
				if (i == 8)
					*o++ = ' ';
				len--;
			}
			*a = 0;
			printf ("%s\n", line);
		} while (len);
		printf ("\n");
	}
	close (fd);
}
#endif

/* Debug */
void
camel_text_index_dump (CamelTextIndex *idx)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
#ifndef DUMP_RAW
	camel_key_t keyid;
	gchar *word;
	const gchar *name;
	guint flags;
	camel_block_t data;

	/* Iterate over all names in the file first */

	printf ("UID's in index\n");

	keyid = 0;
	while ((keyid = camel_key_table_next (p->name_index, keyid, &word, &flags, &data))) {
		if ((flags & 1) == 0)
			printf (" %s\n", word);
		else
			printf (" %s (deleted)\n", word);
		g_free (word);
	}

	printf ("Word's in index\n");

	keyid = 0;
	while ((keyid = camel_key_table_next (p->word_index, keyid, &word, &flags, &data))) {
		CamelIndexCursor *idc;

		printf ("Word: '%s':\n", word);

		idc = camel_index_find ((CamelIndex *) idx, word);
		while ((name = camel_index_cursor_next (idc))) {
			printf (" %s", name);
		}
		printf ("\n");
		g_object_unref (idc);
		g_free (word);
	}
#else
	/* a more low-level dump routine */
	GHashTable *block_type = g_hash_table_new (NULL, NULL);
	camel_block_t id;
	struct stat st;
	gint type;

	add_keys (block_type, p->blocks, p->word_index->rootid);
	add_keys (block_type, p->blocks, p->name_index->rootid);

	add_partition (block_type, p->blocks, p->word_hash->rootid);
	add_partition (block_type, p->blocks, p->name_hash->rootid);

	dump_raw (block_type, p->blocks->path);
	g_hash_table_destroy (block_type);
#endif
}

/* more debug stuff */
void
camel_text_index_validate (CamelTextIndex *idx)
{
	CamelTextIndexPrivate *p = CAMEL_TEXT_INDEX_GET_PRIVATE (idx);
	camel_key_t keyid;
	gchar *word;
	const gchar *name;
	guint flags;
	camel_block_t data;
	gchar *oldword;
	camel_key_t *records;
	gsize count;

	GHashTable *names, *deleted, *words, *keys, *name_word, *word_word;

	names = g_hash_table_new (NULL, NULL);
	deleted = g_hash_table_new (NULL, NULL);

	name_word = g_hash_table_new (g_str_hash, g_str_equal);

	words = g_hash_table_new (NULL, NULL);
	keys = g_hash_table_new (NULL, NULL);

	word_word = g_hash_table_new (g_str_hash, g_str_equal);

	/* Iterate over all names in the file first */

	printf ("Checking UID consistency\n");

	keyid = 0;
	while ((keyid = camel_key_table_next (p->name_index, keyid, &word, &flags, &data))) {
		if ((oldword = g_hash_table_lookup (names, GINT_TO_POINTER (keyid))) != NULL
		    || (oldword = g_hash_table_lookup (deleted, GINT_TO_POINTER (keyid))) != NULL) {
			printf ("Warning, name '%s' duplicates key (%x) with name '%s'\n", word, keyid, oldword);
			g_free (word);
		} else {
			g_hash_table_insert (name_word, word, GINT_TO_POINTER (1));
			if ((flags & 1) == 0) {
				g_hash_table_insert (names, GINT_TO_POINTER (keyid), word);
			} else {
				g_hash_table_insert (deleted, GINT_TO_POINTER (keyid), word);
			}
		}
	}

	printf ("Checking WORD member consistency\n");

	keyid = 0;
	while ((keyid = camel_key_table_next (p->word_index, keyid, &word, &flags, &data))) {
		CamelIndexCursor *idc;
		GHashTable *used;

		/* first, check for duplicates of keyid, and data */
		if ((oldword = g_hash_table_lookup (words, GINT_TO_POINTER (keyid))) != NULL) {
			printf ("Warning, word '%s' duplicates key (%x) with name '%s'\n", word, keyid, oldword);
			g_free (word);
			word = oldword;
		} else {
			g_hash_table_insert (words, GINT_TO_POINTER (keyid), word);
		}

		if (data == 0) {
			/* This may not be an issue if things have been removed over time,
			 * though it is a problem if its a fresh index */
			printf ("Word '%s' has no data associated with it\n", word);
		} else {
			if ((oldword = g_hash_table_lookup (keys, GUINT_TO_POINTER (data))) != NULL) {
				printf ("Warning, word '%s' duplicates data (%x) with name '%s'\n", word, data, oldword);
			} else {
				g_hash_table_insert (keys, GUINT_TO_POINTER (data), word);
			}
		}

		if (g_hash_table_lookup (word_word, word) != NULL) {
			printf ("Warning, word '%s' occurs more than once\n", word);
		} else {
			g_hash_table_insert (word_word, word, word);
		}

		used = g_hash_table_new (g_str_hash, g_str_equal);

		idc = camel_index_find ((CamelIndex *) idx, word);
		while ((name = camel_index_cursor_next (idc))) {
			if (g_hash_table_lookup (name_word, name) == NULL) {
				printf ("word '%s' references non-existant name '%s'\n", word, name);
			}
			if (g_hash_table_lookup (used, name) != NULL) {
				printf ("word '%s' uses word '%s' more than once\n", word, name);
			} else {
				g_hash_table_insert (used, g_strdup (name), (gpointer) 1);
			}
		}
		g_object_unref (idc);

		g_hash_table_foreach (used, (GHFunc) g_free, NULL);
		g_hash_table_destroy (used);

		printf ("word '%s'\n", word);

		while (data) {
			printf (" data %x ", data);
			if (camel_key_file_read (p->links, &data, &count, &records) == -1) {
				printf ("Warning, read failed for word '%s', at data '%u'\n", word, data);
				data = 0;
			} else {
				printf ("(%d)\n", (gint) count);
				g_free (records);
			}
		}
	}

	g_hash_table_destroy (names);
	g_hash_table_destroy (deleted);
	g_hash_table_destroy (words);
	g_hash_table_destroy (keys);

	g_hash_table_foreach (name_word, (GHFunc) g_free, NULL);
	g_hash_table_destroy (name_word);

	g_hash_table_foreach (word_word, (GHFunc) g_free, NULL);
	g_hash_table_destroy (word_word);
}

/* ********************************************************************** */
/* CamelTextIndexName */
/* ********************************************************************** */

G_DEFINE_TYPE (CamelTextIndexName, camel_text_index_name, CAMEL_TYPE_INDEX_NAME)

static void
text_index_name_finalize (GObject *object)
{
	CamelTextIndexNamePrivate *priv;

	priv = CAMEL_TEXT_INDEX_NAME_GET_PRIVATE (object);

	g_hash_table_destroy (CAMEL_TEXT_INDEX_NAME (object)->parent.words);

	g_string_free (priv->buffer, TRUE);
	camel_mempool_destroy (priv->pool);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_text_index_name_parent_class)->finalize (object);
}

static void
text_index_name_add_word (CamelIndexName *idn,
                          const gchar *word)
{
	CamelTextIndexNamePrivate *p = ((CamelTextIndexName *) idn)->priv;

	if (g_hash_table_lookup (idn->words, word) == NULL) {
		gchar *w = camel_mempool_strdup (p->pool, word);

		g_hash_table_insert (idn->words, w, w);
	}
}

/* Why?
 * Because it doesn't hang/loop forever on bad data
 * Used to clean up utf8 before it gets further */

static inline guint32
camel_utf8_next (const guchar **ptr,
                 const guchar *ptrend)
{
	register guchar *p = (guchar *) * ptr;
	register guint c;
	register guint32 v;
	gint l;

	if (p == ptrend)
		return 0;

	while ((c = *p++)) {
		if (c < 0x80) {
			*ptr = p;
			return c;
		} else if ((c&0xe0) == 0xc0) {
			v = c & 0x1f;
			l = 1;
		} else if ((c&0xf0) == 0xe0) {
			v = c & 0x0f;
			l = 2;
		} else if ((c&0xf8) == 0xf0) {
			v = c & 0x07;
			l = 3;
		} else if ((c&0xfc) == 0xf8) {
			v = c & 0x03;
			l = 4;
		} else if ((c&0xfe) == 0xfc) {
			v = c & 0x01;
			l = 5;
		} else
			/* Invalid, ignore and look for next start gchar if room */
			if (p == ptrend) {
				return 0;
			} else {
				continue;
			}

		/* bad data or truncated buffer */
		if (p + l > ptrend)
			return 0;

		while (l && ((c = *p) & 0xc0) == 0x80) {
			p++;
			l--;
			v = (v << 6) | (c & 0x3f);
		}

		/* valid gchar */
		if (l == 0) {
			*ptr = p;
			return v;
		}

		/* else look for a start gchar again */
	}

	return 0;
}

static gsize
text_index_name_add_buffer (CamelIndexName *idn,
                            const gchar *buffer,
                            gsize len)
{
	CamelTextIndexNamePrivate *p = CAMEL_TEXT_INDEX_NAME_GET_PRIVATE (idn);
	const guchar *ptr, *ptrend;
	guint32 c;
	gchar utf8[8];
	gint utf8len;

	if (buffer == NULL) {
		if (p->buffer->len) {
			camel_index_name_add_word (idn, p->buffer->str);
			g_string_truncate (p->buffer, 0);
		}
		return 0;
	}

	ptr = (const guchar *) buffer;
	ptrend = (const guchar *) buffer + len;
	while ((c = camel_utf8_next (&ptr, ptrend))) {
		if (g_unichar_isalnum (c)) {
			c = g_unichar_tolower (c);
			utf8len = g_unichar_to_utf8 (c, utf8);
			utf8[utf8len] = 0;
			g_string_append (p->buffer, utf8);
		} else {
			if (p->buffer->len > 0 && p->buffer->len <= CAMEL_TEXT_INDEX_MAX_WORDLEN) {
				text_index_name_add_word (idn, p->buffer->str);
				/*camel_index_name_add_word (idn, p->buffer->str);*/
			}

			g_string_truncate (p->buffer, 0);
		}
	}

	return 0;
}

static void
camel_text_index_name_class_init (CamelTextIndexNameClass *class)
{
	GObjectClass *object_class;
	CamelIndexNameClass *index_name_class;

	g_type_class_add_private (class, sizeof (CamelTextIndexNamePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = text_index_name_finalize;

	index_name_class = CAMEL_INDEX_NAME_CLASS (class);
	index_name_class->add_word = text_index_name_add_word;
	index_name_class->add_buffer = text_index_name_add_buffer;
}

static void
camel_text_index_name_init (CamelTextIndexName *text_index_name)
{
	text_index_name->priv =
		CAMEL_TEXT_INDEX_NAME_GET_PRIVATE (text_index_name);

	text_index_name->parent.words = g_hash_table_new (
		g_str_hash, g_str_equal);

	text_index_name->priv->buffer = g_string_new ("");
	text_index_name->priv->pool =
		camel_mempool_new (256, 128, CAMEL_MEMPOOL_ALIGN_BYTE);
}

CamelTextIndexName *
camel_text_index_name_new (CamelTextIndex *idx,
                           const gchar *name,
                           camel_key_t nameid)
{
	CamelTextIndexName *idn = g_object_new (CAMEL_TYPE_TEXT_INDEX_NAME, NULL);
	CamelIndexName *cin = &idn->parent;
	CamelTextIndexNamePrivate *p = CAMEL_TEXT_INDEX_NAME_GET_PRIVATE (idn);

	cin->index = g_object_ref (idx);
	cin->name = camel_mempool_strdup (p->pool, name);
	p->nameid = nameid;

	return idn;
}

/* ********************************************************************** */
/* CamelTextIndexCursor */
/* ********************************************************************** */

G_DEFINE_TYPE (CamelTextIndexCursor, camel_text_index_cursor, CAMEL_TYPE_INDEX_CURSOR)

static void
text_index_cursor_finalize (GObject *object)
{
	CamelTextIndexCursorPrivate *priv;

	priv = CAMEL_TEXT_INDEX_CURSOR_GET_PRIVATE (object);

	g_free (priv->records);
	g_free (priv->current);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_text_index_cursor_parent_class)->finalize (object);
}

static const gchar *
text_index_cursor_next (CamelIndexCursor *idc)
{
	CamelTextIndexCursorPrivate *p = CAMEL_TEXT_INDEX_CURSOR_GET_PRIVATE (idc);
	CamelTextIndexPrivate *tip = CAMEL_TEXT_INDEX_GET_PRIVATE (idc->index);
	guint flags;

	c (printf ("Going to next cursor for word with data '%08x' next %08x\n", p->first, p->next));

	do {
		while (p->record_index >= p->record_count) {
			g_free (p->records);
			p->records = NULL;
			p->record_index = 0;
			p->record_count = 0;
			if (p->next == 0)
				return NULL;
			if (camel_key_file_read (tip->links, &p->next, &p->record_count, &p->records) == -1)
				return NULL;
		}

		g_free (p->current);
		p->current = NULL;
		flags = 0;

		camel_key_table_lookup (
			tip->name_index, p->records[p->record_index],
			&p->current, &flags);
		if (flags & 1) {
			g_free (p->current);
			p->current = NULL;
		}
		p->record_index++;
	} while (p->current == NULL);

	return p->current;
}

static void
camel_text_index_cursor_class_init (CamelTextIndexCursorClass *class)
{
	GObjectClass *object_class;
	CamelIndexCursorClass *index_cursor_class;

	g_type_class_add_private (class, sizeof (CamelTextIndexCursorPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = text_index_cursor_finalize;

	index_cursor_class = CAMEL_INDEX_CURSOR_CLASS (class);
	index_cursor_class->next = text_index_cursor_next;
}

static void
camel_text_index_cursor_init (CamelTextIndexCursor *text_index_cursor)
{
	text_index_cursor->priv =
		CAMEL_TEXT_INDEX_CURSOR_GET_PRIVATE (text_index_cursor);
}

CamelTextIndexCursor *
camel_text_index_cursor_new (CamelTextIndex *idx,
                             camel_block_t data)
{
	CamelTextIndexCursor *idc = g_object_new (CAMEL_TYPE_TEXT_INDEX_CURSOR, NULL);
	CamelIndexCursor *cic = &idc->parent;
	CamelTextIndexCursorPrivate *p = CAMEL_TEXT_INDEX_CURSOR_GET_PRIVATE (idc);

	cic->index = g_object_ref (idx);
	p->first = data;
	p->next = data;
	p->record_count = 0;
	p->record_index = 0;

	return idc;
}

/* ********************************************************************** */
/* CamelTextIndexKeyCursor */
/* ********************************************************************** */

G_DEFINE_TYPE (CamelTextIndexKeyCursor, camel_text_index_key_cursor, CAMEL_TYPE_INDEX_CURSOR)

static void
text_index_key_cursor_dispose (GObject *object)
{
	CamelTextIndexKeyCursorPrivate *priv;

	priv = CAMEL_TEXT_INDEX_KEY_CURSOR_GET_PRIVATE (object);

	if (priv->table != NULL) {
		g_object_unref (priv->table);
		priv->table = NULL;
	}

	/* Chain up parent's dispose() method. */
	G_OBJECT_CLASS (camel_text_index_key_cursor_parent_class)->dispose (object);
}

static void
text_index_key_cursor_finalize (GObject *object)
{
	CamelTextIndexKeyCursorPrivate *priv;

	priv = CAMEL_TEXT_INDEX_KEY_CURSOR_GET_PRIVATE (object);

	g_free (priv->current);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (camel_text_index_key_cursor_parent_class)->finalize (object);
}

static const gchar *
text_index_key_cursor_next (CamelIndexCursor *idc)
{
	CamelTextIndexKeyCursorPrivate *p = CAMEL_TEXT_INDEX_KEY_CURSOR_GET_PRIVATE (idc);

	c (printf ("Going to next cursor for keyid %08x\n", p->keyid));

	g_free (p->current);
	p->current = NULL;

	while ((p->keyid = camel_key_table_next (p->table, p->keyid, &p->current, &p->flags, &p->data))) {
		if ((p->flags & 1) == 0) {
			return p->current;
		} else {
			g_free (p->current);
			p->current = NULL;
		}
	}

	return NULL;
}

static void
camel_text_index_key_cursor_class_init (CamelTextIndexKeyCursorClass *class)
{
	GObjectClass *object_class;
	CamelIndexCursorClass *index_cursor_class;

	g_type_class_add_private (class, sizeof (CamelTextIndexKeyCursorPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = text_index_key_cursor_dispose;
	object_class->finalize = text_index_key_cursor_finalize;

	index_cursor_class = CAMEL_INDEX_CURSOR_CLASS (class);
	index_cursor_class->next = text_index_key_cursor_next;
}

static void
camel_text_index_key_cursor_init (CamelTextIndexKeyCursor *text_index_key_cursor)
{
	text_index_key_cursor->priv =
		CAMEL_TEXT_INDEX_KEY_CURSOR_GET_PRIVATE (text_index_key_cursor);

	text_index_key_cursor->priv->keyid = 0;
	text_index_key_cursor->priv->flags = 0;
	text_index_key_cursor->priv->data = 0;
	text_index_key_cursor->priv->current = NULL;
}

CamelTextIndexKeyCursor *
camel_text_index_key_cursor_new (CamelTextIndex *idx,
                                 CamelKeyTable *table)
{
	CamelTextIndexKeyCursor *idc = g_object_new (CAMEL_TYPE_TEXT_INDEX_KEY_CURSOR, NULL);
	CamelIndexCursor *cic = &idc->parent;
	CamelTextIndexKeyCursorPrivate *p = CAMEL_TEXT_INDEX_KEY_CURSOR_GET_PRIVATE (idc);

	cic->index = g_object_ref (idx);
	p->table = g_object_ref (table);

	return idc;
}

/* ********************************************************************** */

#define m(x)

#if 0

struct _CamelIndexRoot {
	struct _CamelBlockRoot root;

	camel_block_t word_root; /* a keyindex containing the keyid -> word mapping */
	camel_block_t word_hash_root; /* a partitionindex containing word -> keyid mapping */

	camel_block_t name_root; /* same, for names */
	camel_block_t name_hash_root;
};

gchar wordbuffer[] = "This is a buffer of multiple words.  Some of the words are duplicates"
" while other words are the same, some are in difFerenT Different different case cAsE casE,"
" with,with:with;with-with'with\"'\"various punctuation as well.  So much for those Words. and 10"
" numbers in a row too 1,2,3,4,5,6,7,8,9,10!  Yay!.";

gint
main (gint argc,
      gchar **argv)
{
#if 0
	CamelBlockFile *bs;
	CamelKeyTable *ki;
	CamelPartitionTable *cpi;
	CamelBlock *keyroot, *partroot;
	struct _CamelIndexRoot *root;
	FILE *fp;
	gchar line[256], *key;
	camel_key_t keyid;
	gint index = 0, flags, data;
#endif
	CamelIndex *idx;
	CamelIndexName *idn;
	CamelIndexCursor *idc;
	const gchar *word;
	gint i;

	printf ("Camel text index tester!\n");

	camel_init (NULL, 0);

	idx = (CamelIndex *) camel_text_index_new ("textindex", O_CREAT | O_RDWR | O_TRUNC);

#if 1
	camel_index_compress (idx);

	return 0;
#endif

	for (i = 0; i < 100; i++) {
		gchar name[16];

		g_snprintf (name, sizeof (name), "%d", i);
		printf ("Adding words to name '%s'\n", name);
		idn = camel_index_add_name (idx, name);
		camel_index_name_add_buffer (idn, wordbuffer, sizeof (wordbuffer) - 1);
		camel_index_write_name (idx, idn);
		g_object_unref (idn);
	}

	printf ("Looking up which names contain word 'word'\n");
	idc = camel_index_find (idx, "words");
	while ((word = camel_index_cursor_next (idc)) != NULL) {
		printf (" name is '%s'\n", word);
	}
	g_object_unref (idc);
	printf ("done.\n");

	printf ("Looking up which names contain word 'truncate'\n");
	idc = camel_index_find (idx, "truncate");
	while ((word = camel_index_cursor_next (idc)) != NULL) {
		printf (" name is '%s'\n", word);
	}
	g_object_unref (idc);
	printf ("done.\n");

	camel_index_sync (idx);
	g_object_unref (idx);

#if 0
	bs = camel_block_file_new ("blocks", "TESTINDX", CAMEL_BLOCK_SIZE);

	root = (struct _CamelIndexRoot *) camel_block_file_get_root (bs);
	if (root->word_root == 0) {
		keyroot = camel_block_file_new_block (bs);
		root->word_root = keyroot->id;
		camel_block_file_touch_block (bs, camel_block_file_get_root_block (bs));
	}
	if (root->word_hash_root == 0) {
		partroot = camel_block_file_new_block (bs);
		root->word_hash_root = partroot->id;
		camel_block_file_touch_block (bs, camel_block_file_get_root_block (bs));
	}

	ki = camel_key_table_new (bs, root->word_root);
	cpi = camel_partition_table_new (bs, root->word_hash_root);

	fp = fopen ("/usr/dict/words", "r");
	if (fp == NULL) {
		perror ("fopen");
		return 1;
	}

	while (fgets (line, sizeof (line), fp) != NULL) {
		line[strlen (line) - 1] = 0;

		/* see if its already there */
		keyid = camel_partition_table_lookup (cpi, line);
		if (keyid == 0) {
			m (printf ("Adding word '%s' %d\n", line, index));

			keyid = camel_key_table_add (ki, line, index, 0);
			m (printf (" key = %08x\n", keyid));

			camel_partition_table_add (cpi, line, keyid);

			m (printf ("Lookup word '%s'\n", line));
			keyid = camel_partition_table_lookup (cpi, line);
			m (printf (" key = %08x\n", keyid));
		}

		m (printf ("Lookup key %08x\n", keyid));

		camel_key_table_set_flags (ki, keyid, index, 1);

		data = camel_key_table_lookup (ki, keyid, &key, &flags);
		m (printf (" word = '%s' %d %04x\n", key, data, flags));

		g_return_val_if_fail (data == index && strcmp (key, line) == 0, -1);

		g_free (key);

		index++;
	}

	printf ("Scanning again\n");
	fseek (fp, SEEK_SET, 0);
	index = 0;
	while (fgets (line, sizeof (line), fp) != NULL) {
		line[strlen (line) - 1] = 0;
		m (printf ("Lookup word '%s' %d\n", line, index));
		keyid = camel_partition_table_lookup (cpi, line);
		m (printf (" key = %08d\n", keyid));

		m (printf ("Lookup key %08x\n", keyid));
		data = camel_key_table_lookup (ki, keyid, &key, &flags);
		m (printf (" word = '%s' %d\n", key, data));

		g_return_val_if_fail (data == index && strcmp (key, line) == 0, -1);

		g_free (key);

		index++;
	}
	fclose (fp);

	printf ("Freeing partition index\n");
	camel_partition_table_free (cpi);

	printf ("Syncing block file\n");
	camel_block_file_sync (bs);
#endif
	return 0;
}

#endif
