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

/* TODO: This could probably be made a camel object, but it isn't really required */

#include "evolution-data-server-config.h"

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>

#include "camel-folder-thread.h"

#define d(x)
#define m(x)

/*#define TIMEIT*/

#ifdef TIMEIT
#include <sys/time.h>
#endif

G_DEFINE_BOXED_TYPE (CamelFolderThread,
		camel_folder_thread_messages,
		camel_folder_thread_messages_ref,
		camel_folder_thread_messages_unref)

static void
container_add_child (CamelFolderThreadNode *node,
                     CamelFolderThreadNode *child)
{
	d (printf ("\nAdding child %p to parent %p \n", child, node));
	child->next = node->child;
	node->child = child;
	child->parent = node;
}

static void
container_parent_child (CamelFolderThreadNode *parent,
                        CamelFolderThreadNode *child)
{
	CamelFolderThreadNode *c, *node;

	/* are we already the right parent? */
	if (child->parent == parent)
		return;

	/* would this create a loop? */
	node = parent->parent;
	while (node) {
		if (node == child)
			return;
		node = node->parent;
	}

	/* are we unparented? */
	if (child->parent == NULL) {
		container_add_child (parent, child);
		return;
	}

	/* else remove child from its existing parent, and reparent */
	node = child->parent;
	c = (CamelFolderThreadNode *) &node->child;
	d (printf ("scanning children:\n"));
	while (c->next) {
		d (printf (" %p\n", c));
		if (c->next == child) {
			d (printf ("found node %p\n", child));
			c->next = c->next->next;
			child->parent = NULL;
			container_add_child (parent, child);
			return;
		}
		c = c->next;
	}

	printf ("DAMN, we shouldn't  be here!\n");
}

static void
prune_empty (CamelFolderThread *thread,
             CamelFolderThreadNode **cp)
{
	CamelFolderThreadNode *child, *next, *c, *lastc;

	/* yes, this is intentional */
	lastc = (CamelFolderThreadNode *) cp;
	while (lastc->next) {
		c = lastc->next;
		prune_empty (thread, &c->child);

		d (printf (
			"checking message %p %p (%08x%08x)\n", c,
			c->message,
			c->message ? c->message->message_id.id.part.hi : 0,
			c->message ? c->message->message_id.id.part.lo : 0));
		if (c->message == NULL) {
			if (c->child == NULL) {
				d (printf ("removing empty node\n"));
				lastc->next = c->next;
				m (memset (c, 0xfe, sizeof (*c)));
				camel_memchunk_free (thread->node_chunks, c);
				continue;
			}
			if (c->parent || c->child->next == NULL) {
				d (printf ("promoting child\n"));
				lastc->next = c->next; /* remove us */
				child = c->child;
				while (child) {
					next = child->next;

					child->parent = c->parent;
					child->next = lastc->next;
					lastc->next = child;

					child = next;
				}
				continue;
			}
		}
		lastc = c;
	}
}

static void
hashloop (gpointer key,
          gpointer value,
          gpointer data)
{
	CamelFolderThreadNode *c = value;
	CamelFolderThreadNode *tail = data;

	if (c->parent == NULL) {
		c->next = tail->next;
		tail->next = c;
	}
}

static gchar *
skip_list_ids (gchar *s)
{
	gchar *p;

	while (isspace (*s))
		s++;

	while (*s == '[') {
		p = s + 1;

		while (*p && *p != ']' && !isspace (*p))
			p++;

		if (*p != ']')
			break;

		s = p + 1;

		while (isspace (*s))
			s++;

		if (*s == '-' && isspace (s[1]))
			s += 2;

		while (isspace (*s))
			s++;
	}

	return s;
}

static gchar *
get_root_subject (CamelFolderThreadNode *c)
{
	gchar *s, *p;
	CamelFolderThreadNode *scan;

	s = NULL;
	c->re = FALSE;
	if (c->message)
		s = (gchar *) camel_message_info_get_subject (c->message);
	else {
		/* one of the children will always have a message */
		scan = c->child;
		while (scan) {
			if (scan->message) {
				s = (gchar *) camel_message_info_get_subject (scan->message);
				break;
			}
			scan = scan->next;
		}
	}
	if (s != NULL) {
		s = skip_list_ids (s);

		while (*s) {
			while (isspace (*s))
				s++;
			if (s[0] == 0)
				break;
			if ((s[0] == 'r' || s[0]=='R')
			    && (s[1] == 'e' || s[1]=='E')) {
				p = s + 2;
				while (isdigit (*p) || (ispunct (*p) && (*p != ':')))
					p++;
				if (*p == ':') {
					c->re = TRUE;
					s = skip_list_ids (p + 1);
				} else
					break;
			} else
				break;
		}
		if (*s)
			return s;
	}
	return NULL;
}

/* this can be pretty slow, but not used often */
/* clast cannot be null */
static void
remove_node (CamelFolderThreadNode **list,
             CamelFolderThreadNode *node,
             CamelFolderThreadNode **clast)
{
	CamelFolderThreadNode *c;

	/* this is intentional, even if it looks funny */
	/* if we have a parent, then we should remove it from the parent list,
	 * otherwise we remove it from the root list */
	if (node->parent) {
		c = (CamelFolderThreadNode *) &node->parent->child;
	} else {
		c = (CamelFolderThreadNode *) list;
	}
	while (c->next) {
		if (c->next == node) {
			if (*clast == c->next)
				*clast = c;
			c->next = c->next->next;
			return;
		}
		c = c->next;
	}

	printf ("ERROR: removing node %p failed\n", (gpointer) node);
}

static void
group_root_set (CamelFolderThread *thread,
                CamelFolderThreadNode **cp)
{
	GHashTable *subject_table = g_hash_table_new (g_str_hash, g_str_equal);
	CamelFolderThreadNode *c, *clast, *scan, *container;

	/* gather subject lines */
	d (printf ("gathering subject lines\n"));
	clast = (CamelFolderThreadNode *) cp;
	c = clast->next;
	while (c) {
		c->root_subject = get_root_subject (c);
		if (c->root_subject) {
			container = g_hash_table_lookup (subject_table, c->root_subject);
			if (container == NULL
			    || (container->message == NULL && c->message)
			    || (container->re == TRUE && !c->re)) {
				g_hash_table_insert (subject_table, c->root_subject, c);
			}
		}
		c = c->next;
	}

	/* merge common subjects? */
	clast = (CamelFolderThreadNode *) cp;
	while (clast->next) {
		c = clast->next;
		d (printf ("checking %p %s\n", c, c->root_subject));
		if (c->root_subject
		    && (container = g_hash_table_lookup (subject_table, c->root_subject))
		    && (container != c)) {
			d (printf (" matching %p %s\n", container, container->root_subject));
			if (c->message == NULL && container->message == NULL) {
				d (printf ("merge containers children\n"));
				/* steal the children from c onto container, and unlink c */
				scan = (CamelFolderThreadNode *) &container->child;
				while (scan->next)
					scan = scan->next;
				scan->next = c->child;
				clast->next = c->next;
				m (memset (c, 0xee, sizeof (*c)));
				camel_memchunk_free (thread->node_chunks, c);
				continue;
			} if (c->message == NULL && container->message != NULL) {
				d (printf ("container is non-empty parent\n"));
				remove_node (cp, container, &clast);
				container_add_child (c, container);
			} else if (c->message != NULL && container->message == NULL) {
				d (printf ("container is empty child\n"));
				clast->next = c->next;
				container_add_child (container, c);
				continue;
			} else if (c->re && !container->re) {
				d (printf ("container is re\n"));
				clast->next = c->next;
				container_add_child (container, c);
				continue;
			} else if (!c->re && container->re) {
				d (printf ("container is not re\n"));
				remove_node (cp, container, &clast);
				container_add_child (c, container);
			} else {
				d (printf ("subjects are common %p and %p\n", c, container));

				/* build a phantom node */
				remove_node (cp, container, &clast);
				remove_node (cp, c, &clast);

				scan = camel_memchunk_alloc0 (thread->node_chunks);

				scan->root_subject = c->root_subject;
				scan->re = c->re && container->re;
				scan->next = c->next;
				clast->next = scan;
				container_add_child (scan, c);
				container_add_child (scan, container);
				clast = scan;
				g_hash_table_insert (subject_table, scan->root_subject, scan);
				continue;
			}
		}
		clast = c;
	}
	g_hash_table_destroy (subject_table);
}

struct _tree_info {
	GHashTable *visited;
};

static gint
dump_tree_rec (struct _tree_info *info,
               CamelFolderThreadNode *c,
               gint depth)
{
	gint count = 0, indent = depth * 2;

	while (c) {
		if (g_hash_table_lookup (info->visited, c)) {
			printf ("WARNING: NODE REVISITED: %p\n", (gpointer) c);
		} else {
			g_hash_table_insert (info->visited, c, c);
		}
		if (c->message) {
			CamelSummaryMessageID message_id;

			message_id.id.id = camel_message_info_get_message_id (c->message);

			printf (
				"%*s %p Subject: %s <%08x%08x>\n",
				indent, "", (gpointer) c,
				camel_message_info_get_subject (c->message),
				message_id.id.part.hi,
				message_id.id.part.lo);
			count += 1;
		} else {
			printf ("%*s %p <empty>\n", indent, "", (gpointer) c);
		}
		if (c->child)
			count += dump_tree_rec (info, c->child, depth + 1);
		c = c->next;
	}
	return count;
}

gint
camel_folder_threaded_messages_dump (CamelFolderThreadNode *c)
{
	gint count;
	struct _tree_info info;

	info.visited = g_hash_table_new (g_direct_hash, g_direct_equal);
	count = dump_tree_rec (&info, c, 0);
	g_hash_table_destroy (info.visited);
	return count;
}

static gint
sort_node (gconstpointer a,
           gconstpointer b)
{
	const CamelFolderThreadNode *a1 = ((CamelFolderThreadNode **) a)[0];
	const CamelFolderThreadNode *b1 = ((CamelFolderThreadNode **) b)[0];

	/* if we have no message, it must be a dummy node, which
	 * also means it must have a child, just use that as the
	 * sort data (close enough?) */
	if (a1->message == NULL)
		a1 = a1->child;
	if (b1->message == NULL)
		b1 = b1->child;
	if (a1->order == b1->order)
		return 0;
	if (a1->order < b1->order)
		return -1;
	else
		return 1;
}

static void
sort_thread (CamelFolderThreadNode **cp)
{
	CamelFolderThreadNode *c, *head, **carray;
	gint size = 0;

	c = *cp;
	while (c) {
		/* sort the children while we're at it */
		if (c->child)
			sort_thread (&c->child);
		size++;
		c = c->next;
	}
	if (size < 2)
		return;

	carray = g_new (CamelFolderThreadNode *, size);

	c = *cp;
	size = 0;
	while (c) {
		carray[size] = c;
		c = c->next;
		size++;
	}
	qsort (carray, size, sizeof (CamelFolderThreadNode *), sort_node);
	size--;
	head = carray[size];
	head->next = NULL;
	size--;
	do {
		c = carray[size];
		c->next = head;
		head = c;
		size--;
	} while (size >= 0);
	*cp = head;

	g_free (carray);
}

static guint
id_hash (gconstpointer key)
{
	const CamelSummaryMessageID *id = key;

	return id->id.part.lo;
}

static gboolean
id_equal (gconstpointer a,
          gconstpointer b)
{
	return ((const CamelSummaryMessageID *) a)->id.id == ((const CamelSummaryMessageID *) b)->id.id;
}

/* perform actual threading */
static void
thread_summary (CamelFolderThread *thread,
                GPtrArray *summary)
{
	GHashTable *id_table, *no_id_table;
	gint i;
	CamelFolderThreadNode *c, *child, *head;
#ifdef TIMEIT
	struct timeval start, end;
	gulong diff;

	gettimeofday (&start, NULL);
#endif

	id_table = g_hash_table_new_full (id_hash, id_equal, g_free, NULL);
	no_id_table = g_hash_table_new (NULL, NULL);
	for (i = 0; i < summary->len; i++) {
		CamelMessageInfo *mi = summary->pdata[i];
		CamelSummaryMessageID *message_id_copy, message_id;
		const GArray *references;

		camel_message_info_property_lock (mi);

		message_id.id.id = camel_message_info_get_message_id (mi);
		references = camel_message_info_get_references (mi);

		if (message_id.id.id) {
			c = g_hash_table_lookup (id_table, &message_id);
			/* check for duplicate messages */
			if (c && c->order) {
				/* if duplicate, just make out it is a no-id message,  but try and insert it
				 * into the right spot in the tree */
				d (printf ("doing: (duplicate message id)\n"));
				c = camel_memchunk_alloc0 (thread->node_chunks);
				g_hash_table_insert (no_id_table, (gpointer) mi, c);
			} else if (!c) {
				d (printf ("doing : %08x%08x (%s)\n", message_id.id.part.hi, message_id.id.part.lo, camel_message_info_get_subject (mi)));
				c = camel_memchunk_alloc0 (thread->node_chunks);
				message_id_copy = g_new0 (CamelSummaryMessageID, 1);
				message_id_copy->id.id = message_id.id.id;
				g_hash_table_insert (id_table, message_id_copy, c);
			}
		} else {
			d (printf ("doing : (no message id)\n"));
			c = camel_memchunk_alloc0 (thread->node_chunks);
			g_hash_table_insert (no_id_table, (gpointer) mi, c);
		}

		c->message = mi;
		c->order = i + 1;
		child = c;
		if (references) {
			guint jj;

			d (printf ("%s (%s) references:\n", G_STRLOC, G_STRFUNC); )

			for (jj = 0; jj < references->len; jj++) {
				gboolean found = FALSE;

				message_id.id.id = g_array_index (references, guint64, jj);

				/* should never be empty, but just incase */
				if (!message_id.id.id)
					continue;

				c = g_hash_table_lookup (id_table, &message_id);
				if (c == NULL) {
					d (printf ("%s (%s) not found\n", G_STRLOC, G_STRFUNC));
					c = camel_memchunk_alloc0 (thread->node_chunks);
					message_id_copy = g_new0 (CamelSummaryMessageID, 1);
					message_id_copy->id.id = message_id.id.id;
					g_hash_table_insert (id_table, message_id_copy, c);
				} else
					found = TRUE;
				if (c != child) {
					container_parent_child (c, child);
					/* Stop on the first parent found, no need to reparent
					 * it once it's placed in. Also, references are from
					 * parent to root, thus this should do the right thing. */
					if (found)
						break;
				}
				child = c;
			}
		}

		camel_message_info_property_unlock (mi);
	}

	d (printf ("\n\n"));
	/* build a list of root messages (no parent) */
	head = NULL;
	g_hash_table_foreach (id_table, hashloop, &head);
	g_hash_table_foreach (no_id_table, hashloop, &head);

	g_hash_table_destroy (id_table);
	g_hash_table_destroy (no_id_table);

	/* remove empty parent nodes */
	prune_empty (thread, &head);

	/* find any siblings which missed out - but only if we are allowing threading by subject */
	if (thread->subject)
		group_root_set (thread, &head);

#if 0
	printf ("finished\n");
	i = camel_folder_threaded_messages_dump (head);
	printf ("%d count, %d items in tree\n", summary->len, i);
#endif

	sort_thread (&head);

	/* remove any phantom nodes, this could possibly be put in group_root_set()? */
	c = (CamelFolderThreadNode *) &head;
	while (c && c->next) {
		CamelFolderThreadNode *scan, *newtop;

		child = c->next;
		if (child->message == NULL) {
			newtop = child->child;
			newtop->parent = NULL;
			/* unlink pseudo node */
			c->next = newtop;

			/* link its siblings onto the end of its children, fix all parent pointers */
			scan = (CamelFolderThreadNode *) &newtop->child;
			while (scan->next) {
				scan = scan->next;
			}
			scan->next = newtop->next;
			while (scan->next) {
				scan = scan->next;
				scan->parent = newtop;
			}

			/* and link the now 'real' node into the list */
			newtop->next = child->next;
			c = newtop;
			m (memset (child, 0xde, sizeof (*child)));
			camel_memchunk_free (thread->node_chunks, child);
		} else {
			c = child;
		}
	}

	/* this is only debug assertion stuff */
	c = (CamelFolderThreadNode *) &head;
	while (c->next) {
		c = c->next;
		if (c->message == NULL)
			g_warning ("threading missed removing a pseudo node: %s\n", c->root_subject);
		if (c->parent != NULL)
			g_warning ("base node has a non-null parent: %s\n", c->root_subject);
	}

	thread->tree = head;

#ifdef TIMEIT
	gettimeofday (&end, NULL);
	diff = end.tv_sec * 1000 + end.tv_usec / 1000;
	diff -= start.tv_sec * 1000 + start.tv_usec / 1000;
	printf (
		"Message threading %d messages took %ld.%03ld seconds\n",
		summary->len, diff / 1000, diff % 1000);
#endif
}

/**
 * camel_folder_thread_messages_new:
 * @folder: a #CamelFolder
 * @uids: (element-type utf8): The subset of uid's to thread. If %NULL, then thread
 *    all UID-s in the @folder
 * @thread_subject: thread based on subject also
 *
 * Thread a (subset) of the messages in a folder.  And sort the result
 * in summary order.
 *
 * If @thread_subject is %TRUE, messages with
 * related subjects will also be threaded. The default behaviour is to
 * only thread based on message-id.
 *
 * This function is probably to be removed soon.
 *
 * Returns: A CamelFolderThread contianing a tree of CamelFolderThreadNode's
 * which represent the threaded structure of the messages.
 **/
CamelFolderThread *
camel_folder_thread_messages_new (CamelFolder *folder,
                                  GPtrArray *uids,
                                  gboolean thread_subject)
{
	CamelFolderThread *thread;
	GPtrArray *summary;
	GPtrArray *fsummary = NULL;
	gint i;

	thread = g_malloc (sizeof (*thread));
	thread->refcount = 1;
	thread->subject = thread_subject;
	thread->tree = NULL;
	thread->node_chunks = camel_memchunk_new (32, sizeof (CamelFolderThreadNode));
	thread->folder = g_object_ref (folder);

	camel_folder_summary_prepare_fetch_all (camel_folder_get_folder_summary (folder), NULL);
	thread->summary = summary = g_ptr_array_new ();

	/* prefer given order from the summary order */
	if (!uids) {
		fsummary = camel_folder_summary_get_array (camel_folder_get_folder_summary (folder));
		uids = fsummary;
	}

	for (i = 0; i < uids->len; i++) {
		CamelMessageInfo *info;
		gchar *uid = uids->pdata[i];

		info = camel_folder_get_message_info (folder, uid);
		if (info)
			g_ptr_array_add (summary, info);
		/* FIXME: Check if the info is leaking */
	}

	if (fsummary)
		camel_folder_summary_free_array (fsummary);

	thread_summary (thread, summary);

	return thread;
}

/* add any still there, in the existing order */
static void
add_present_rec (CamelFolderThread *thread,
                 GHashTable *have,
                 GPtrArray *summary,
                 CamelFolderThreadNode *node)
{
	while (node) {
		CamelMessageInfo *info;
		const gchar *uid;

		/* XXX Casting away const. */
		info = (CamelMessageInfo *) node->message;
		uid = camel_message_info_get_uid (info);

		if (g_hash_table_lookup (have, uid)) {
			g_hash_table_remove (have, uid);
			g_ptr_array_add (summary, info);
		} else {
			g_clear_object (&info);
		}

		if (node->child)
			add_present_rec (thread, have, summary, node->child);
		node = node->next;
	}
}

/**
 * camel_folder_thread_messages_apply:
 * @thread: a #CamelFolderThread
 * @uids: (element-type utf8) (transfer none): a #GPtrArray array of UID-s
 *
 * Adds new @uids into the threaded tree.
 **/
void
camel_folder_thread_messages_apply (CamelFolderThread *thread,
                                    GPtrArray *uids)
{
	gint i;
	GPtrArray *all;
	GHashTable *table;
	CamelMessageInfo *info;

	all = g_ptr_array_new ();
	table = g_hash_table_new (g_str_hash, g_str_equal);
	for (i = 0; i < uids->len; i++)
		g_hash_table_insert (table, uids->pdata[i], uids->pdata[i]);

	add_present_rec (thread, table, all, thread->tree);

	/* add any new ones, in supplied order */
	for (i = 0; i < uids->len; i++)
		if (g_hash_table_lookup (table, uids->pdata[i]) && (info = camel_folder_get_message_info (thread->folder, uids->pdata[i])))
			g_ptr_array_add (all, info);

	g_hash_table_destroy (table);

	thread->tree = NULL;
	camel_memchunk_destroy (thread->node_chunks);
	thread->node_chunks = camel_memchunk_new (32, sizeof (CamelFolderThreadNode));
	thread_summary (thread, all);

	g_ptr_array_free (thread->summary, TRUE);
	thread->summary = all;
}

/**
 * camel_folder_thread_messages_ref:
 * @thread: a #CamelFolderThread
 *
 * Increase the reference of @thread
 *
 * Returns: the referenced @thread
 **/
CamelFolderThread *
camel_folder_thread_messages_ref (CamelFolderThread *thread)
{
	thread->refcount++;
	return thread;
}

/**
 * camel_folder_thread_messages_unref:
 * @thread: a #CamelFolderThread
 *
 * Free all memory associated with the thread descriptor @thread.
 **/
void
camel_folder_thread_messages_unref (CamelFolderThread *thread)
{
	if (thread->refcount > 1) {
		thread->refcount--;
		return;
	}

	if (thread->folder) {
		gint i;

		for (i = 0; i < thread->summary->len; i++)
			g_clear_object (&thread->summary->pdata[i]);
		g_ptr_array_free (thread->summary, TRUE);
		g_object_unref (thread->folder);
	}
	camel_memchunk_destroy (thread->node_chunks);
	g_free (thread);
}

#if 0
/**
 * camel_folder_thread_messages_new_summary:
 * @summary: Array of CamelMessageInfo's to thread.
 *
 * Thread a list of MessageInfo's.  The summary must remain valid for the
 * life of the CamelFolderThread created by this function, and it is upto the
 * caller to ensure this.
 *
 * Returns: A CamelFolderThread contianing a tree of CamelFolderThreadNode's
 * which represent the threaded structure of the messages.
 **/
CamelFolderThread *
camel_folder_thread_messages_new_summary (GPtrArray *summary)
{
	CamelFolderThread *thread;

#ifdef TIMEIT
	struct timeval start, end;
	gulong diff;

	gettimeofday (&start, NULL);
#endif

	thread = g_malloc (sizeof (*thread));
	thread->refcount = 1;
	thread->tree = NULL;
	thread->node_chunks = camel_memchunk_new (32, sizeof (CamelFolderThreadNode));
	thread->folder = NULL;
	thread->summary = NULL;

	thread_summary (thread, summary);

	return thread;
}

/* scan the list in depth-first fashion */
static void
build_summary_rec (GHashTable *have,
                   GPtrArray *summary,
                   CamelFolderThreadNode *node)
{
	while (node) {
		if (node->message)
			g_hash_table_insert (have, (gchar *) camel_message_info_get_uid (node->message), node->message);
		g_ptr_array_add (summary, node);
		if (node->child)
			build_summary_rec (have, summary, node->child);
		node = node->next;
	}
}

void
camel_folder_thread_messages_add (CamelFolderThread *thread,
                                  GPtrArray *summary)
{
	GPtrArray *all;
	gint i;
	GHashTable *table;

	/* Instead of working out all the complex in's and out's of
	 * trying to do an incremental summary generation, just redo the whole
	 * thing with the summary in the current order - so it comes out
	 * in the same order */

	all = g_ptr_array_new ();
	table = g_hash_table_new (g_str_hash, g_str_equal);
	build_summary_rec (table, all, thread->tree);
	for (i = 0; i < summary->len; i++) {
		CamelMessageInfo *info = summary->pdata[i];

		/* check its not already there, we dont want duplicates */
		if (g_hash_table_lookup (table, camel_message_info_get_uid (info)) == NULL)
			g_ptr_array_add (all, info);
	}
	g_hash_table_destroy (table);

	/* reset the tree, and rebuild fully */
	thread->tree = NULL;
	camel_memchunk_empty (thread->node_chunks);
	thread_summary (thread, all);
}

static void
remove_uid_node_rec (CamelFolderThread *thread,
                     GHashTable *table,
                     CamelFolderThreadNode **list,
                     CamelFolderThreadNode *parent)
{
	CamelFolderThreadNode *prev = NULL;
	CamelFolderThreadNode *node, *next, *child, *rest;

	node = (CamelFolderThreadNode *) list;
	next = node->next;
	while (next) {

		if (next->child)
			remove_uid_node_rec (thread, table, &next->child, next);

		/* do we have a node to remove? */
		if (next->message && g_hash_table_lookup (table, (gchar *) camel_message_info_get_uid (node->message))) {
			child = next->child;
			if (child) {
				/*
				 * node
				 * next
				 * child
				 * lchild
				 * rest
				 *
				 * becomes:
				 * node
				 * child
				 * lchild
				 * rest
				 */

				rest = next->next;
				node->next = child;
				camel_memchunk_free (thread->node_chunks, next);
				next = child;
				do {
					lchild = child;
					child->parent = parent;
					child = child->next;
				} while (child);
				lchild->next = rest;
			} else {
				/*
				 * node
				 * next
				 * rest
				 * becomes:
				 * node
				 * rest */
				node->next = next->next;
				camel_memchunk_free (thread->node_chunks, next);
				next = node->next;
			}
		} else {
			node = next;
			next = node->next;
		}
	}
}

void
camel_folder_thread_messages_remove (CamelFolderThread *thread,
                                     GPtrArray *uids)
{
	GHashTable *table;
	gint i;

	table = g_hash_table_new (g_str_hash, g_str_equal);
	for (i = 0; i < uids->len; i++)
		g_hash_table_insert (table, uids->pdata[i], uids->pdata[i]);

	remove_uid_node_rec (thread, table, &thread->tree, NULL);
	g_hash_table_destroy (table);
}

#endif
