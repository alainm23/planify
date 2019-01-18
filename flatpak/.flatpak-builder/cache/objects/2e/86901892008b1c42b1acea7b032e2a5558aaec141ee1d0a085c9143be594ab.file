/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright 2008
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
 * Authors: Stanislav Slusny <slusnys@gmail.com>
 */

/**
 * SECTION: e-cal-backend-intervaltree
 * @include: libedata-cal/libedata-cal.h
 * @short_description: A utility for calculating intervals and recurrances
 *
 * Implementation of the interval node as described in Introduction to
 * Algorithms book by Cormen et al, chapter 14.3.
 *
 * Basically, the interval tree is the red-black tree, the node key is
 * the start of the interval.
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <string.h>

#include "e-cal-backend-intervaltree.h"

#define d(x) x

#define _TIME_MIN	((time_t) 0)		/* Min valid time_t	*/
#define _TIME_MAX	((time_t) INT_MAX)	/* Max valid time_t	*/
#define DIRECTION_GO_LEFT 0
#define DIRECTION_GO_RIGHT 1

G_DEFINE_TYPE (EIntervalTree, e_intervaltree, G_TYPE_OBJECT)

#define E_INTERVALTREE_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_INTERVALTREE, EIntervalTreePrivate))

typedef struct _EIntervalNode EIntervalNode;

static EIntervalNode *
intervaltree_node_next (EIntervalTree *tree, EIntervalNode *x);

struct _EIntervalNode {
	/* start of the interval - the key of the node */
	time_t start;
	/* end of the interval */
	time_t end;
	/* maximum value of any interval stored in subtree rooted at node */
	time_t max;
	/* minimum value of any interval stored in subtree rooted at node */
	time_t min;
	/* color of the node (red or black) */
	gboolean red;

	ECalComponent *comp;

	/* left child */
	EIntervalNode * left;
	/* right child */
	EIntervalNode * right;
	EIntervalNode * parent;
};

struct _EIntervalTreePrivate {
	EIntervalNode *root;
	EIntervalNode *nil;
	GHashTable *id_node_hash;
	GRecMutex mutex;
};

static inline gint
get_direction (EIntervalNode *x,
               time_t z_start,
               time_t z_end)
{
	if (x->start == z_start)
		return x->end > z_end;

	if (x->start > z_start)
		return DIRECTION_GO_LEFT;
	else
		return DIRECTION_GO_RIGHT;
}

static inline gchar *
component_key (const gchar *uid,
               const gchar *rid)
{
	if (rid)
		return	g_strdup_printf ("%s_%s", uid, rid);
	else
		return g_strdup_printf ("%s", uid);
}

/**
 * compare_intervals:
 *
 * Compares two intervals.
 *
 * Returns: 0 if interval overlaps, -1 if first interval ends before
 * the second starts, 1 otherwise.
 *
 **/
static inline gint
compare_intervals (time_t x_start,
                   time_t x_end,
                   time_t y_start,
                   time_t y_end)
{
	/* assumption: x_start <= x_end */
	/* assumption: y_start <= y_end */

	/* x is left of y */
	if (x_end < y_start)
		return -1;

	/* x is right of y */
	if (y_end < x_start)
		return 1;

	/* x and y overlap */
	return 0;
}

/**
 * left_rotate:
 * @tree: interval tree
 * @x: Node, where will be applied the operation
 * 
 * Carry out left rotation on the node @x in tree @tree.
 * Caller should hold the lock
 **/
static void
left_rotate (EIntervalTree *tree,
             EIntervalNode *x)
{
	EIntervalNode *y;
	EIntervalNode *nil;

	g_return_if_fail (E_IS_INTERVALTREE (tree));
	g_return_if_fail (x != NULL);

	nil = tree->priv->nil;
	y = x->right;
	x->right = y->left;

	if (y->left != nil)
		y->left->parent = x;

	y->parent = x->parent;

	/* instead of checking if x->parent is the root as in the book, we */
	/* count on the root sentinel to implicitly take care of this case */
	if (x == x->parent->left)
		x->parent->left = y;
	else
		x->parent->right = y;

	y->left = x;
	x->parent = y;

	/* update max and min field */
	x->max = MAX (x->left->max, MAX (x->end, x->right->max));
	y->max = MAX (x->max, MAX (y->end, y->right->max));
	x->min = MIN (x->left->min, x->start);
	y->min = MIN (x->min, y->start);
}

/**
 * right_rotate:
 * @tree: interval tree
 * @y: Node, where will be applied the operation
 * 
 * Carry out right rotation on the node @y in tree @tree.
 * Caller should hold the lock
 **/
static void
right_rotate (EIntervalTree *tree,
              EIntervalNode *y)
{
	EIntervalNode *x;
	EIntervalNode *nil;

	g_return_if_fail (E_IS_INTERVALTREE (tree));
	g_return_if_fail (y != NULL);

	nil = tree->priv->nil;
	x = y->left;
	y->left = x->right;

	if (nil != x->right)
		x->right->parent = y;

	x->parent = y->parent;

	if (y == y->parent->left)
		y->parent->left = x;
	else
		y->parent->right = x;

	x->right = y;
	y->parent = x;

	/* update max and min field */
	y->max = MAX (y->left->max, MAX (y->right->max, y->end));
	x->max = MAX (x->left->max, MAX (y->max, x->end));
	y->min = MIN (y->left->min, y->start);
	x->min = MIN (x->left->min, x->start);
}

static void
fixup_min_max_fields (EIntervalTree *tree,
                      EIntervalNode *node)
{
	while (node && node != tree->priv->root) {
		node->max = MAX (node->end, MAX (node->left->max, node->right->max));
		node->min = MIN (node->start, node->left->min);

		node = node->parent;
	}
}

/* Caller should hold the lock */
static void
binary_tree_insert (EIntervalTree *tree,
                    EIntervalNode *z)
{
	EIntervalNode *x;
	EIntervalNode *y;
	EIntervalNode *nil;

	g_return_if_fail (E_IS_INTERVALTREE (tree));
	g_return_if_fail (z != NULL);

	nil = tree->priv->nil;

	z->left = z->right = nil;
	y = tree->priv->root;
	x = tree->priv->root->left;

	while (x != nil) {
		y = x;

		if (get_direction (x, z->start, z->end) == DIRECTION_GO_LEFT)
			x = x->left;
		else
			x = x->right;
	}

	z->parent = y;

	if ((y == tree->priv->root) || (get_direction (y, z->start, z->end) == DIRECTION_GO_LEFT))
		y->left = z;
	else
		y->right = z;

	/* update min and max fields */
	y->min = MIN (y->left->min, y->start);
	y->max = MAX (y->left->max, MAX (y->end, y->right->max));
}

static EIntervalNode *
intervaltree_node_next (EIntervalTree *tree,
                        EIntervalNode *x)
{
	EIntervalNode *y, *nil, *root;

	g_return_val_if_fail (E_IS_INTERVALTREE (tree), NULL);
	g_return_val_if_fail (x != NULL, NULL);

	g_return_val_if_fail (x != tree->priv->nil, NULL);

	nil = tree->priv->nil;
	root = tree->priv->root;

	if (nil != (y = x->right)) {
		/* find out minimum of right subtree of x (assignment to y is ok) */
		while (y->left != nil)
			y = y->left;

		return y;
	}

	y = x->parent;

	while (x == y->right) {
		x = y;
		y = y->parent;
	}

	if (y == root)
		return nil;

	return y;
}

/* Caller should hold the lock */
static void
intervaltree_fixup_deletion (EIntervalTree *tree,
                             EIntervalNode *x)
{
	EIntervalNode *root = tree->priv->root->left;
	EIntervalNode *w;

	while ((!x->red) && (root != x)) {
		if (!x->parent)
			break;

		if (x == x->parent->left) {
			w = x->parent->right;

			if (w->red) {
				w->red = FALSE;
				x->parent->red = TRUE;
				left_rotate (tree, x->parent);
				w = x->parent->right;
			}

			if ((!w->right->red) && (!w->left->red)) {
				w->red = TRUE;
				x = x->parent;
			} else {
				if (!w->right->red) {
					w->left->red = FALSE;
					w->red = TRUE;
					right_rotate (tree, w);
					w = x->parent->right;
				}

				w->red = x->parent->red;
				x->parent->red = FALSE;
				w->right->red = FALSE;
				left_rotate (tree, x->parent);
				x = root; /* this is to exit while loop */
			}
		} else {
			w = x->parent->left;

			if (w->red) {
				w->red = FALSE;
				x->parent->red = TRUE;
				right_rotate (tree, x->parent);
				w = x->parent->left;
			}

			if ((!w->right->red) && (!w->left->red)) {
				w->red = TRUE;
				x = x->parent;
			} else {
				if (!w->left->red) {
					w->right->red = FALSE;
					w->red = TRUE;
					left_rotate (tree, w);
					w = x->parent->left;
				}

				w->red = x->parent->red;
				x->parent->red = FALSE;
				w->left->red = FALSE;
				right_rotate (tree, x->parent);
				x = root; /* this is to exit while loop */
			}
		}
	}

	x->red = 0;
}

/** Caller should hold the lock. **/
static EIntervalNode *
intervaltree_search_component (EIntervalTree *tree,
                               const gchar *searched_uid,
                               const gchar *searched_rid)
{
	EIntervalNode *node;
	gchar *key;

	g_return_val_if_fail (E_IS_INTERVALTREE (tree), NULL);
	g_return_val_if_fail (searched_uid != NULL, NULL);

	if (!searched_uid) {
		g_warning (
			"Searching the interval tree, the component "
			" does not have a valid UID skipping it\n");

		return NULL;
	}

	key = component_key (searched_uid, searched_rid);
	node = g_hash_table_lookup (tree->priv->id_node_hash, key);
	g_free (key);

	return node;
}

static void
intervaltree_finalize (GObject *object)
{
	EIntervalTreePrivate *priv;

	priv = E_INTERVALTREE_GET_PRIVATE (object);

	g_free (priv->root);
	g_free (priv->nil);

	if (priv->id_node_hash != NULL)
		g_hash_table_destroy (priv->id_node_hash);

	g_rec_mutex_clear (&priv->mutex);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_intervaltree_parent_class)->finalize (object);
}

static void
e_intervaltree_class_init (EIntervalTreeClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EIntervalTreePrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = intervaltree_finalize;
}

static void
e_intervaltree_init (EIntervalTree *tree)
{
	EIntervalNode *root, *nil;

	tree->priv = E_INTERVALTREE_GET_PRIVATE (tree);

	tree->priv->nil = nil = g_new (EIntervalNode, 1);
	nil->parent = nil->left = nil->right = nil;
	nil->red = FALSE;
	nil->start = nil->end = nil->max = _TIME_MIN;
	nil->min = _TIME_MAX;

	tree->priv->root = root = g_new (EIntervalNode, 1);
	root->parent = root->left = root->right = nil;
	root->red = FALSE;
	root->start = _TIME_MAX;
	root->end = 0;
	root->max = _TIME_MAX;
	root->min = _TIME_MIN;

	g_rec_mutex_init (&tree->priv->mutex);

	tree->priv->id_node_hash = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) NULL);
}

/**
 * e_intervaltree_new:
 *
 * Creates a new #EIntervalTree.
 *
 * Returns: The newly-created #EIntervalTree.
 *
 * Since: 2.32
 **/
EIntervalTree *
e_intervaltree_new (void)
{
	return g_object_new (E_TYPE_INTERVALTREE, NULL);
}

/**
 * e_intervaltree_insert:
 * @tree: interval tree
 * @start: start of the interval
 * @end: end of the interval
 * @comp: Component
 * 
 * Since: 2.32
 **/
gboolean
e_intervaltree_insert (EIntervalTree *tree,
                       time_t start,
                       time_t end,
                       ECalComponent *comp)
{
	EIntervalNode *y;
	EIntervalNode *x;
	EIntervalNode *newNode;
	const gchar *uid;
	gchar *rid;

	g_return_val_if_fail (E_IS_INTERVALTREE (tree), FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	g_rec_mutex_lock (&tree->priv->mutex);

	e_cal_component_get_uid (comp, &uid);
	rid = e_cal_component_get_recurid_as_string (comp);
	e_intervaltree_remove (tree, uid, rid);

	x = g_new (EIntervalNode, 1);
	x->min = x->start = start;
	x->max = x->end = end;
	x->comp = g_object_ref (comp);

	binary_tree_insert (tree, x);
	newNode = x;
	x->red = TRUE;

	fixup_min_max_fields (tree, x->parent);
	while (x->parent->red) {
		/* use sentinel instead of checking for root */
		if (x->parent == x->parent->parent->left) {
			y = x->parent->parent->right;

			if (y->red) {
				x->parent->red = FALSE;
				y->red = FALSE;
				x->parent->parent->red = TRUE;
				x = x->parent->parent;
			} else {
				if (x == x->parent->right) {
					x = x ->parent;
					left_rotate (tree, x);
				}

				x->parent->red = FALSE;
				x->parent->parent->red = TRUE;
				right_rotate (tree, x->parent->parent);
			}
		} else {
			/* case for x->parent == x->parent->parent->right */
			y = x->parent->parent->left;

			if (y->red) {
				x->parent->red = FALSE;
				y->red = FALSE;
				x->parent->parent->red = TRUE;
				x = x->parent->parent;
			} else {
				if (x == x->parent->left) {
					x = x->parent;
					right_rotate (tree, x);
				}

				x->parent->red = FALSE;
				x->parent->parent->red = TRUE;
				left_rotate (tree, x->parent->parent);
			}
		}
	}

	tree->priv->root->left->red = FALSE;
	g_hash_table_insert (
		tree->priv->id_node_hash,
		component_key (uid, rid), newNode);
	g_free (rid);

	g_rec_mutex_unlock (&tree->priv->mutex);

	return TRUE;
}

/**
 * e_intervaltree_remove:
 * @tree: an #EIntervalTree
 * @uid: the uid of the component to remove
 * @rid: the recurrance id of the component to remove
 *
 * Since: 2.32
 **/
gboolean
e_intervaltree_remove (EIntervalTree *tree,
                       const gchar *uid,
                       const gchar *rid)
{
	EIntervalNode *y = NULL;
	EIntervalNode *x = NULL;
	EIntervalNode *z = NULL;
	EIntervalNode *nil, *root;
	gchar *key;

	g_return_val_if_fail (E_IS_INTERVALTREE (tree), FALSE);

	nil = tree->priv->nil;
	root = tree->priv->root;
	g_rec_mutex_lock (&tree->priv->mutex);

	z = intervaltree_search_component (tree, uid, rid);

	if (!z || z == nil) {
		g_rec_mutex_unlock (&tree->priv->mutex);
		return FALSE;
	}

	y = ((z->left == nil) || (z->right == nil)) ? z :
		intervaltree_node_next (tree, z);
	g_return_val_if_fail (y, FALSE);
	x = (y->left == nil) ? y->right : y->left;
	g_return_val_if_fail (x, FALSE);
	/* y is to be spliced out. x is it's only child */

	x->parent = y->parent;

	if (root && root == x->parent)
		root->left = x;
	else if (y->parent) {
		if (y == y->parent->left)
			y->parent->left = x;
		else
			y->parent->right = x;
	}

	if (z && y != z) {
		/* y (the succesor of z) is the node to be spliced out */
		g_return_val_if_fail (y != tree->priv->nil, FALSE);

		y->max = _TIME_MIN;
		y->min = _TIME_MAX;
		y->left = z->left;
		y->right = z->right;
		y->parent = z->parent;
		z->left->parent = z->right->parent = y;

		if (z->parent) {
			if (z == z->parent->left)
				z->parent->left = y;
			else
				z->parent->right = y;

		}

		fixup_min_max_fields (tree, x->parent);

		if (!(y->red)) {
			y->red = z->red;
			intervaltree_fixup_deletion (tree, x);
		}
		else
			y->red = z->red;
	} else {
		/* z is the node to be spliced out */

		fixup_min_max_fields (tree, x->parent);

		if (!(y->red))
			intervaltree_fixup_deletion (tree, x);
	}

	key = component_key (uid, rid);
	g_hash_table_remove (tree->priv->id_node_hash, key);
	g_free (key);

	g_object_unref (z->comp);
	g_free (z);
	g_rec_mutex_unlock (&tree->priv->mutex);

	return TRUE;
}

/**
 * e_intervaltree_search:
 * @tree: interval tree
 * @start: start of the interval
 * @end: end of the interval
 * 
 * Returns: list of nodes that overlaps given interval or %NULL.
 *
 * Since: 2.32
 **/
GList *
e_intervaltree_search (EIntervalTree *tree,
                       time_t start,
                       time_t end)
{
	EIntervalNode *node;
	GList *list = NULL;
	GList *stack_start = NULL, *pos;

	g_return_val_if_fail (E_IS_INTERVALTREE (tree), NULL);

	g_rec_mutex_lock (&tree->priv->mutex);

	stack_start = pos = g_list_insert (
		stack_start, tree->priv->root->left, -1);

	while (pos != NULL) {
		node = (EIntervalNode *) pos->data;

		if (node != tree->priv->nil) {
			if (compare_intervals (node->start, node->end, start, end) == 0) {
				list = g_list_insert (list, node->comp, -1);
				g_object_ref (node->comp);
			}

			if (compare_intervals (node->left->min, node->left->max, start, end) == 0)
				pos = g_list_insert (pos, node->left, -1);

			if (compare_intervals (node->right->min, node->right->max, start, end) == 0)
				pos = g_list_insert (pos, node->right, -1);
		}

		pos = pos->next;
	}

	g_list_free (stack_start);

	g_rec_mutex_unlock (&tree->priv->mutex);

	return list;
}

/**
 * e_intervaltree_destroy:
 * @tree: an #EIntervalTree
 *
 * Since: 2.32
 **/
void
e_intervaltree_destroy (EIntervalTree *tree)
{
	EIntervalNode *node;
	GList *stack_start = NULL, *pos;

	g_return_if_fail (E_IS_INTERVALTREE (tree));

	stack_start = pos = g_list_insert (
		stack_start, tree->priv->root->left, -1);

	while (pos != NULL) {
		node = (EIntervalNode *) pos->data;

		if (node != tree->priv->nil) {
			pos = g_list_insert (pos, node->left, -1);
			pos = g_list_insert (pos, node->right, -1);

			g_object_unref (node->comp);
			g_free (node);
		}

		pos = pos->next;
	}

	g_list_free (stack_start);
	g_object_unref (tree);
}

#ifdef E_INTERVALTREE_DEBUG
static void
e_intervaltree_node_dump (EIntervalTree *tree,
                          EIntervalNode *node,
                          gint indent)
{
	/*
	gchar start_time[32] = {0}, end_time[32] = {0};
	struct tm tm_start_time, tm_end_time;
 *
	localtime_r (&node->start, &tm_start_time);
	localtime_r (&node->end, &tm_end_time);
	strftime (start_time, sizeof (start_time), "%Y-%m-%d T%H:%M:%S", &tm_start_time);
	strftime (end_time, sizeof (end_time), "%Y-%m-%d T%H:%M:%S", &tm_end_time);
	g_print ("%*s[%s - %s]\n", indent, "", start_time, end_time);
	*/
	if (node != tree->priv->nil) {
		g_print (
			"%*s[%" G_GINT64_FORMAT "- %" G_GINT64_FORMAT "] [%" G_GINT64_FORMAT "- %" G_GINT64_FORMAT "] red %d\n", indent, "", (gint64) node->start,
			(gint64) node->end, (gint64) node->min, (gint64) node->max, node->red);
	} else {
		g_print ("%*s[ - ]\n", indent, "");
		return;
	}

	e_intervaltree_node_dump (tree, node->left, indent + 2);
	e_intervaltree_node_dump (tree, node->right, indent + 2);
}

void
e_intervaltree_dump (EIntervalTree *tree)
{
	g_return_if_fail (E_IS_INTERVALTREE (tree));

	if (tree->priv->root)
		  e_intervaltree_node_dump (tree, tree->priv->root, 0);
}
#endif

