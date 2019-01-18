/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * gtksourceundomanagerdefault.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 1998, 1999 - Alex Roberts, Evan Lawrence
 * Copyright (C) 2000, 2001 - Chema Celorio, Paolo Maggi
 * Copyright (C) 2002-2005  - Paolo Maggi
 * Copyright (C) 2014, 2015 - Sébastien Wilmet <swilmet@gnome.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include "gtksourceundomanagerdefault.h"
#include <string.h>
#include "gtksourceundomanager.h"

/* unlimited by default */
#define DEFAULT_MAX_UNDO_LEVELS -1

typedef struct _Action		Action;
typedef struct _ActionGroup	ActionGroup;

typedef enum _ActionType
{
	ACTION_TYPE_INSERT,
	ACTION_TYPE_DELETE
} ActionType;

/* A more precise deletion type. But currently it's only a guess, we are not
 * 100% sure of the deletion type. To be sure, we would need to listen to key
 * events on the GtkSourceView widget, which is more complicated than simply
 * listening to the insert-text and delete-range GtkTextBuffer signals.
 */
typedef enum _DeletionType
{
	DELETION_TYPE_SELECTION_DELETED,
	DELETION_TYPE_BACKSPACE_KEY,
	DELETION_TYPE_DELETE_KEY,
	DELETION_TYPE_PROGRAMMATICALLY
} DeletionType;

struct _Action
{
	ActionType type;

	/* Character offset for the start of @text in the GtkTextBuffer. */
	gint start;

	/* Character offset for the end of @text in the GtkTextBuffer. */
	gint end;

	/* Nul-terminated text.
	 * TODO A possible memory optimization is to store the text only when
	 * needed. For an insertion that is located in the history on the undo
	 * side, the text is not needed since it is already present in the
	 * buffer. The same for a deletion on the redo side. But the last action
	 * text is needed for the merging.
	 */
	gchar *text;

	/* Character offsets of the insert and selection bound marks.
	 * They are both -1 or they both match @start or @end.
	 * If the text cursor or the selected text is not related to the action,
	 * the selection is not stored (i.e. -1).
	 * If not -1, when undoing or redoing an action, the insert and
	 * selection bound marks are restored to where they were.
	 * For an insert, @selection_insert and @selection_bound must match
	 * @start, otherwise the selection or cursor position is unrelated to
	 * the insertion.
	 * For a deletion, if @selection_insert and @selection_bound are -1, it
	 * corresponds to DELETION_TYPE_PROGRAMMATICALLY. For all the other
	 * deletion types, the selection is stored.
	 */
	gint selection_insert;
	gint selection_bound;
};

struct _ActionGroup
{
	/* One or several Action's that forms a single undo or redo step. The
	 * most recent action is at the end of the list.
	 * In fact, actions can be grouped with
	 * gtk_text_buffer_begin_user_action() and
	 * gtk_text_buffer_end_user_action().
	 */
	GQueue *actions;

	/* If force_not_mergeable is FALSE, there are dynamic checks to see if
	 * the action group is mergeable. For example if the saved_location is
	 * just after the action group, the action group is not mergeable, so
	 * the saved_location isn't lost.
	 */
	guint force_not_mergeable : 1;
};

struct _GtkSourceUndoManagerDefaultPrivate
{
	/* Weak ref to the buffer. */
	GtkTextBuffer *buffer;

	/* List of ActionGroup's. The most recent ActionGroup is at the end of
	 * the list.
	 */
	GQueue *action_groups;

	/* Current location in 'action_groups', where we are located in the
	 * history. The redo steps are on the right of the pointer, and the undo
	 * steps are on the left. In other words, the next redo step is
	 * location->data. The next undo step is location->prev->data. But the
	 * location should not be seen as a node, it should be seen as a
	 * vertical bar between two nodes, like a GtkTextIter between two
	 * characters.
	 */
	GList *location;

	/* A new ActionGroup that is created when some text is inserted or
	 * deleted in the buffer. As long as a user action is running (when
	 * 'running_user_action' is TRUE) the new actions are inserted into
	 * 'new_action_group'. When the user action ends, we try to merge
	 * 'new_action_group' with the previous ActionGroup in 'action_groups'
	 * (the node on the left of 'location'). If the merging fails, a new
	 * node is inserted on the left of 'location'.
	 */
	ActionGroup *new_action_group;

	/* The number of nested calls to
	 * gtk_source_buffer_begin_not_undoable_action().
	 */
	guint running_not_undoable_actions;

	/* Max number of action groups. */
	gint max_undo_levels;

	/* The location in 'action_groups' where the buffer is saved. I.e. when
	 * gtk_text_buffer_set_modified (buffer, FALSE) was called for the last
	 * time.
	 * NULL is for the end of 'action_groups'.
	 * 'has_saved_location' is FALSE if the history doesn't contain a saved
	 * location.
	 */
	GList *saved_location;
	guint has_saved_location : 1;

	guint can_undo : 1;
	guint can_redo : 1;

	/* Whether we are between a begin-user-action and a end-user-action.
	 * Some operations, like undo and redo, are not allowed during a user
	 * action (it would screw up the history).
	 * At the beginning of a user action, a new action group is created. At
	 * the end of the user action, we try to merge the group with the
	 * previous one. So when an insertion or deletion occurs when
	 * running_user_action is TRUE, we don't need to create a new group. But
	 * when running_user_action is FALSE, we need to put the insertion or
	 * deletion into a new group and try to merge it directly with the
	 * previous group.
	 */
	guint running_user_action : 1;
};

enum
{
	PROP_0,
	PROP_BUFFER,
	PROP_MAX_UNDO_LEVELS
};

static void gtk_source_undo_manager_iface_init (GtkSourceUndoManagerIface *iface);

static gboolean action_merge (Action *action,
			      Action *new_action);

G_DEFINE_TYPE_WITH_CODE (GtkSourceUndoManagerDefault,
			 gtk_source_undo_manager_default,
			 G_TYPE_OBJECT,
			 G_ADD_PRIVATE (GtkSourceUndoManagerDefault)
                         G_IMPLEMENT_INTERFACE (GTK_SOURCE_TYPE_UNDO_MANAGER,
                                                gtk_source_undo_manager_iface_init))

/* Utilities functions */

static Action *
action_new (void)
{
	Action *action;

	action = g_slice_new0 (Action);

	action->selection_insert = -1;
	action->selection_bound = -1;

	return action;
}

static void
action_free (Action *action)
{
	if (action != NULL)
	{
		g_free (action->text);
		g_slice_free (Action, action);
	}
}

static ActionGroup *
action_group_new (void)
{
	ActionGroup *group;

	group = g_slice_new (ActionGroup);
	group->actions = g_queue_new ();
	group->force_not_mergeable = FALSE;

	return group;
}

static void
action_group_free (ActionGroup *group)
{
	if (group != NULL)
	{
		g_queue_free_full (group->actions, (GDestroyNotify) action_free);
		g_slice_free (ActionGroup, group);
	}
}

static void
update_can_undo_can_redo (GtkSourceUndoManagerDefault *manager)
{
	gboolean can_undo;
	gboolean can_redo;

	if (manager->priv->running_user_action)
	{
		can_undo = FALSE;
		can_redo = FALSE;
	}
	else if (manager->priv->location != NULL)
	{
		can_undo = manager->priv->location->prev != NULL;
		can_redo = TRUE;
	}
	else
	{
		can_undo = manager->priv->action_groups->tail != NULL;
		can_redo = FALSE;
	}

	if (manager->priv->can_undo != can_undo)
	{
		manager->priv->can_undo = can_undo;
		gtk_source_undo_manager_can_undo_changed (GTK_SOURCE_UNDO_MANAGER (manager));
	}

	if (manager->priv->can_redo != can_redo)
	{
		manager->priv->can_redo = can_redo;
		gtk_source_undo_manager_can_redo_changed (GTK_SOURCE_UNDO_MANAGER (manager));
	}
}

static void
clear_all (GtkSourceUndoManagerDefault *manager)
{
	GList *l;

	if (manager->priv->has_saved_location &&
	    manager->priv->saved_location != manager->priv->location)
	{
		manager->priv->has_saved_location = FALSE;
	}

	for (l = manager->priv->action_groups->head; l != NULL; l = l->next)
	{
		ActionGroup *group = l->data;
		action_group_free (group);
	}

	g_queue_clear (manager->priv->action_groups);
	manager->priv->location = NULL;
	manager->priv->saved_location = NULL;

	action_group_free (manager->priv->new_action_group);
	manager->priv->new_action_group = NULL;

	update_can_undo_can_redo (manager);
}

static void
remove_last_action_group (GtkSourceUndoManagerDefault *manager)
{
	ActionGroup *group;

	if (manager->priv->action_groups->length == 0)
	{
		return;
	}

	if (manager->priv->location == manager->priv->action_groups->tail)
	{
		manager->priv->location = NULL;
	}

	if (manager->priv->has_saved_location)
	{
		if (manager->priv->saved_location == NULL)
		{
			manager->priv->has_saved_location = FALSE;
		}
		else if (manager->priv->saved_location == manager->priv->action_groups->tail)
		{
			manager->priv->saved_location = NULL;
		}
	}

	group = g_queue_pop_tail (manager->priv->action_groups);
	action_group_free (group);
}

static void
remove_first_action_group (GtkSourceUndoManagerDefault *manager)
{
	GList *first_node;
	ActionGroup *group;

	first_node = manager->priv->action_groups->head;

	if (first_node == NULL)
	{
		return;
	}

	if (manager->priv->location == first_node)
	{
		manager->priv->location = first_node->next;
	}

	if (manager->priv->has_saved_location &&
	    manager->priv->saved_location == first_node)
	{
		manager->priv->has_saved_location = FALSE;
	}

	group = g_queue_pop_head (manager->priv->action_groups);
	action_group_free (group);
}

static void
check_history_size (GtkSourceUndoManagerDefault *manager)
{
	if (manager->priv->max_undo_levels == -1)
	{
		return;
	}

	if (manager->priv->max_undo_levels == 0)
	{
		clear_all (manager);
		return;
	}

	g_return_if_fail (manager->priv->max_undo_levels > 0);

	while (manager->priv->action_groups->length > (guint)manager->priv->max_undo_levels)
	{
		/* Strip redo action groups first. */
		if (manager->priv->location != NULL)
		{
			remove_last_action_group (manager);
		}
		else
		{
			remove_first_action_group (manager);
		}
	}

	update_can_undo_can_redo (manager);
}

static void
remove_redo_action_groups (GtkSourceUndoManagerDefault *manager)
{
	while (manager->priv->location != NULL)
	{
		remove_last_action_group (manager);
	}
}

/* Try to merge @new_group into @group. Returns TRUE if merged. It is up to the
 * caller to free @new_group.
 */
static gboolean
action_group_merge (ActionGroup *group,
		    ActionGroup *new_group)
{
	Action *action;
	Action *new_action;

	g_assert (group != NULL);
	g_assert (new_group != NULL);

	if (new_group->actions->length == 0)
	{
		return TRUE;
	}

	if (group->force_not_mergeable ||
	    new_group->force_not_mergeable ||
	    group->actions->length > 1 ||
	    new_group->actions->length > 1)
	{
		return FALSE;
	}

	action = g_queue_peek_head (group->actions);
	new_action = g_queue_peek_head (new_group->actions);

	return action_merge (action, new_action);
}

/* Try to merge the new action group with the previous one (the one located on
 * the left of priv->location). If the merge fails, a new node is inserted into
 * the history.
 */
static void
insert_new_action_group (GtkSourceUndoManagerDefault *manager)
{
	GList *prev_node = NULL;
	ActionGroup *prev_group = NULL;
	ActionGroup *new_group = manager->priv->new_action_group;
	gboolean can_merge = TRUE;

	if (new_group == NULL || new_group->actions->length == 0)
	{
		return;
	}

	remove_redo_action_groups (manager);
	g_assert (manager->priv->location == NULL);

	prev_node = manager->priv->action_groups->tail;

	if (prev_node != NULL)
	{
		prev_group = prev_node->data;

		/* If the previous group is empty, it means that it was not correctly
		 * inserted into the history.
		 */
		g_assert_cmpuint (prev_group->actions->length, >, 0);
	}

	/* If the saved_location is equal to the current location, the two
	 * ActionGroups cannot be merged, to not lose the saved_location.
	 */
	if (manager->priv->has_saved_location &&
	    manager->priv->saved_location == manager->priv->location)
	{
		g_assert (manager->priv->saved_location == NULL);
		can_merge = FALSE;
	}

	if (can_merge &&
	    prev_group != NULL &&
	    action_group_merge (prev_group, new_group))
	{
		/* new_group merged into prev_group */
		action_group_free (manager->priv->new_action_group);
		manager->priv->new_action_group = NULL;

		update_can_undo_can_redo (manager);
		return;
	}

	g_queue_push_tail (manager->priv->action_groups, new_group);
	manager->priv->new_action_group = NULL;

	if (manager->priv->has_saved_location &&
	    manager->priv->saved_location == NULL)
	{
		manager->priv->saved_location = manager->priv->action_groups->tail;
	}

	/* "Archive" prev_group. It will never be mergeable again. If the user
	 * does some undo's to return to this location, a new action won't be
	 * merged with an "archived" action group.
	 */
	if (prev_group != NULL)
	{
		prev_group->force_not_mergeable = TRUE;
	}

	check_history_size (manager);
	update_can_undo_can_redo (manager);
}

static void
insert_action (GtkSourceUndoManagerDefault *manager,
	       Action                      *new_action)
{
	ActionGroup *new_group;

	g_assert (new_action != NULL);

	if (manager->priv->new_action_group == NULL)
	{
		manager->priv->new_action_group = action_group_new ();
	}

	new_group = manager->priv->new_action_group;

	/* Inside a group, don't try to merge the actions. It is needed to keep
	 * them separate so when undoing or redoing, the cursor position is set
	 * at the right place.
	 * For example with the search and replace, we replace all occurrences
	 * of 'a' by '' (i.e. delete all a's). The text "aaba" becomes "b". On
	 * undo, the cursor position should be placed at "a|aba", not "aa|ba"
	 * (but it's a detail).
	 */
	g_queue_push_tail (new_group->actions, new_action);

	/* An action is mergeable only for an insertion or deletion of a single
	 * character. If the text contains several characters, the new_action
	 * can for example come from a copy/paste.
	 */
	if (new_action->end - new_action->start > 1 ||
	    g_str_equal (new_action->text, "\n"))
	{
		new_group->force_not_mergeable = TRUE;
	}

	if (!manager->priv->running_user_action)
	{
		insert_new_action_group (manager);
	}
}

static void
delete_text (GtkTextBuffer *buffer,
	     gint           start,
	     gint           end)
{
	GtkTextIter start_iter;
	GtkTextIter end_iter;

	gtk_text_buffer_get_iter_at_offset (buffer, &start_iter, start);
	gtk_text_buffer_get_iter_at_offset (buffer, &end_iter, end);

	gtk_text_buffer_begin_user_action (buffer);
	gtk_text_buffer_delete (buffer, &start_iter, &end_iter);
	gtk_text_buffer_end_user_action (buffer);
}

static void
insert_text (GtkTextBuffer *buffer,
	     gint           offset,
	     const gchar   *text)
{
	GtkTextIter iter;

	gtk_text_buffer_get_iter_at_offset (buffer, &iter, offset);

	gtk_text_buffer_begin_user_action (buffer);
	gtk_text_buffer_insert (buffer, &iter, text, -1);
	gtk_text_buffer_end_user_action (buffer);
}

static gunichar
get_last_char (const gchar *text)
{
	gchar *pos;

	pos = g_utf8_find_prev_char (text, text + strlen (text));

	if (pos == NULL)
	{
		return '\0';
	}

	return g_utf8_get_char (pos);
}

/* ActionInsert implementation */

static void
action_insert_undo (GtkTextBuffer *buffer,
		    Action        *action)
{
	g_assert_cmpint (action->type, ==, ACTION_TYPE_INSERT);

	delete_text (buffer, action->start, action->end);
}

static void
action_insert_redo (GtkTextBuffer *buffer,
		    Action        *action)
{
	g_assert_cmpint (action->type, ==, ACTION_TYPE_INSERT);

	insert_text (buffer, action->start, action->text);
}

static gboolean
action_insert_merge (Action *action,
		     Action *new_action)
{
	gint new_text_length;
	gunichar new_char;
	gunichar last_char;
	gchar *merged_text;

	g_assert_cmpint (action->type, ==, ACTION_TYPE_INSERT);
	g_assert_cmpint (new_action->type, ==, ACTION_TYPE_INSERT);

	new_text_length = new_action->end - new_action->start;
	g_assert_cmpint (new_text_length, ==, 1);

	new_char = g_utf8_get_char (new_action->text);
	g_assert (new_char != '\n');

	if (action->end != new_action->start)
	{
		return FALSE;
	}

	last_char = get_last_char (action->text);

	/* If I type character by character the text "hello world", there will
	 * be two actions: "hello" and " world". If I click on undo, only
	 * "hello" remains, not the space. The space makes sense only when
	 * a second word is present.
	 * Note that the spaces or tabs at the beginning of a line (for code
	 * indentation) are removed with the first word of the line. For example
	 * if I type character by character "  return FALSE;", there are two
	 * actions: "  return" and " FALSE;". If I undo two times, maybe I still
	 * want the indentation. But with auto-indent, when we press Enter to
	 * create a newline, the indentation is part of the action that adds the
	 * newline, i.e. we have the three actions "\n  ", "return" and
	 * " FALSE;".
	 */
	if ((new_char == ' ' || new_char == '\t') &&
	    (last_char != ' ' && last_char != '\t'))
	{
		return FALSE;
	}

	merged_text = g_strdup_printf ("%s%s", action->text, new_action->text);

	g_free (action->text);
	action->text = merged_text;

	action->end = new_action->end;

	/* No need to update the selection, action->start is not modified. */
	g_assert ((action->selection_insert == -1 &&
		   action->selection_bound == -1) ||
		  (action->selection_insert == action->start &&
		   action->selection_bound == action->start));

	return TRUE;
}

static void
action_insert_restore_selection (GtkTextBuffer *buffer,
				 Action        *action,
				 gboolean       undo)
{
	GtkTextIter iter;

	g_assert_cmpint (action->type, ==, ACTION_TYPE_INSERT);

	/* No need to take into account action->selection_insert and
	 * action->selection_bound, because:
	 * - If they are both -1, we still want to place the cursor correctly,
	 *   as done below, because if the cursor is not moved the user won't
	 *   see the modification.
	 * - If they are set, their values are both action->start, so the undo
	 *   works as expeceted in this case. The redo is also the expected
	 *   behavior because after inserting a character the cursor is _after_
	 *   the character, not before.
	 */

	if (undo)
	{
		gtk_text_buffer_get_iter_at_offset (buffer, &iter, action->start);
	}
	else /* redo */
	{
		gtk_text_buffer_get_iter_at_offset (buffer, &iter, action->end);
	}

	gtk_text_buffer_place_cursor (buffer, &iter);
}

/* ActionDelete implementation */

static void
action_delete_undo (GtkTextBuffer *buffer,
		    Action        *action)
{
	g_assert_cmpint (action->type, ==, ACTION_TYPE_DELETE);

	insert_text (buffer, action->start, action->text);
}

static void
action_delete_redo (GtkTextBuffer *buffer,
		    Action        *action)
{
	g_assert_cmpint (action->type, ==, ACTION_TYPE_DELETE);

	delete_text (buffer, action->start, action->end);
}

static DeletionType
get_deletion_type (Action *action)
{
	g_assert_cmpint (action->type, ==, ACTION_TYPE_DELETE);

	if (action->selection_insert == -1)
	{
		g_assert_cmpint (action->selection_bound, ==, -1);
		return DELETION_TYPE_PROGRAMMATICALLY;
	}

	if (action->selection_insert == action->end &&
	    action->selection_bound == action->end)
	{
		return DELETION_TYPE_BACKSPACE_KEY;
	}

	if (action->selection_insert == action->start &&
	    action->selection_bound == action->start)
	{
		return DELETION_TYPE_DELETE_KEY;
	}

	g_assert (action->selection_insert == action->start ||
		  action->selection_insert == action->end);
	g_assert (action->selection_bound == action->start ||
		  action->selection_bound == action->end);

	return DELETION_TYPE_SELECTION_DELETED;
}

static gboolean
action_delete_merge (Action *action,
		     Action *new_action)
{
	gint new_text_length;
	gunichar new_char;
	DeletionType deletion_type;
	DeletionType new_deletion_type;

	g_assert_cmpint (action->type, ==, ACTION_TYPE_DELETE);
	g_assert_cmpint (new_action->type, ==, ACTION_TYPE_DELETE);

	new_text_length = new_action->end - new_action->start;
	g_assert_cmpint (new_text_length, ==, 1);

	new_char = g_utf8_get_char (new_action->text);
	g_assert (new_char != '\n');

	deletion_type = get_deletion_type (action);
	new_deletion_type = get_deletion_type (new_action);

	if (deletion_type != new_deletion_type)
	{
		return FALSE;
	}

	switch (deletion_type)
	{
		/* If the user has selected some text and then has deleted it,
		 * it should be seen as a single action group, not mergeable.  A
		 * good reason for that is to correctly restore the selection.
		 */
		case DELETION_TYPE_SELECTION_DELETED:
			return FALSE;

		/* For memory use it would be better to take it into account,
		 * but the code is simpler like that.
		 */
		case DELETION_TYPE_PROGRAMMATICALLY:
			return FALSE;

		/* Two Backspaces or two Deletes must follow each other. In
		 * "abc", if the cursor is at offset 2 and I press the Backspace
		 * key, then move the cursor after 'c' and press Backspace
		 * again, the two deletes won't be merged, since there was a
		 * cursor movement in between.
		 */

		case DELETION_TYPE_DELETE_KEY:
			/* Not consecutive deletes. */
			if (action->start != new_action->start)
			{
				return FALSE;
			}
			break;

		case DELETION_TYPE_BACKSPACE_KEY:
			/* Not consecutive backspaces. */
			if (action->start != new_action->end)
			{
				return FALSE;
			}
			break;

		default:
			g_assert_not_reached ();
	}

	/* Delete key pressed several times. */
	if (action->start == new_action->start)
	{
		gunichar last_char;
		gchar *merged_text;

		last_char = get_last_char (action->text);

		/* Same as action_insert_merge(). */
		if ((new_char == ' ' || new_char == '\t') &&
		    (last_char != ' ' && last_char != '\t'))
		{
			return FALSE;
		}

		merged_text = g_strdup_printf ("%s%s", action->text, new_action->text);

		g_free (action->text);
		action->text = merged_text;

		action->end += new_text_length;

		/* No need to update the selection, action->start is not
		 * modified.
		 */
		g_assert_cmpint (action->selection_insert, ==, action->start);
		g_assert_cmpint (action->selection_bound, ==, action->start);

		return TRUE;
	}

	/* Backspace key pressed several times. */
	if (action->start == new_action->end)
	{
		gunichar last_char;
		gchar *merged_text;

		/* The last char deleted, but since it's with the Backspace key,
		 * it's the first char in action->text.
		 */
		last_char = g_utf8_get_char (action->text);

		/* Same as action_insert_merge(). */
		if ((new_char != ' ' && new_char != '\t') &&
		    (last_char == ' ' || last_char == '\t'))
		{
			return FALSE;
		}

		merged_text = g_strdup_printf ("%s%s", new_action->text, action->text);

		g_free (action->text);
		action->text = merged_text;

		action->start = new_action->start;

		/* No need to update the selection, action->end is not modified. */
		g_assert_cmpint (action->selection_insert, ==, action->end);
		g_assert_cmpint (action->selection_bound, ==, action->end);

		return TRUE;
	}

	g_assert_not_reached ();
	return FALSE;
}

static void
action_delete_restore_selection (GtkTextBuffer *buffer,
				 Action        *action,
				 gboolean       undo)
{

	g_assert_cmpint (action->type, ==, ACTION_TYPE_DELETE);

	if (undo)
	{
		if (action->selection_insert == -1)
		{
			GtkTextIter iter;

			g_assert_cmpint (action->selection_bound, ==, -1);

			gtk_text_buffer_get_iter_at_offset (buffer, &iter, action->end);
			gtk_text_buffer_place_cursor (buffer, &iter);
		}
		else
		{
			GtkTextIter insert_iter;
			GtkTextIter bound_iter;

			gtk_text_buffer_get_iter_at_offset (buffer,
							    &insert_iter,
							    action->selection_insert);

			gtk_text_buffer_get_iter_at_offset (buffer,
							    &bound_iter,
							    action->selection_bound);

			gtk_text_buffer_select_range (buffer, &insert_iter, &bound_iter);
		}
	}
	else /* redo */
	{
		GtkTextIter iter;

		gtk_text_buffer_get_iter_at_offset (buffer, &iter, action->start);
		gtk_text_buffer_place_cursor (buffer, &iter);
	}
}

/* Action interface.
 * The Action struct can be seen as an interface. All the explicit case analysis
 * on the action type are grouped in this code section. This can easily be
 * modified as an object-oriented architecture with polymorphism.
 */

static void
action_undo (GtkTextBuffer *buffer,
	     Action        *action)
{
	g_assert (action != NULL);

	switch (action->type)
	{
		case ACTION_TYPE_INSERT:
			action_insert_undo (buffer, action);
			break;

		case ACTION_TYPE_DELETE:
			action_delete_undo (buffer, action);
			break;

		default:
			g_return_if_reached ();
			break;
	}
}

static void
action_redo (GtkTextBuffer *buffer,
	     Action        *action)
{
	g_assert (action != NULL);

	switch (action->type)
	{
		case ACTION_TYPE_INSERT:
			action_insert_redo (buffer, action);
			break;

		case ACTION_TYPE_DELETE:
			action_delete_redo (buffer, action);
			break;

		default:
			g_return_if_reached ();
			break;
	}
}

/* Try to merge @new_action into @action. Returns TRUE if merged. It is up to
 * the caller to free @new_action if needed.
 */
static gboolean
action_merge (Action *action,
	      Action *new_action)
{
	g_assert (action != NULL);
	g_assert (new_action != NULL);

	if (action->type != new_action->type)
	{
		return FALSE;
	}

	switch (action->type)
	{
		case ACTION_TYPE_INSERT:
			return action_insert_merge (action, new_action);

		case ACTION_TYPE_DELETE:
			return action_delete_merge (action, new_action);

		default:
			g_return_val_if_reached (FALSE);
			break;
	}
}

/* Restore the selection (or cursor position) according to @action.
 * If @undo is TRUE, @action has just been undone. If @undo is FALSE, @action
 * has just been redone.
 */
static void
action_restore_selection (GtkTextBuffer *buffer,
			  Action        *action,
			  gboolean       undo)
{
	g_assert (action != NULL);

	switch (action->type)
	{
		case ACTION_TYPE_INSERT:
			action_insert_restore_selection (buffer, action, undo);
			break;

		case ACTION_TYPE_DELETE:
			action_delete_restore_selection (buffer, action, undo);
			break;

		default:
			g_return_if_reached ();
			break;
	}
}

/* Buffer signal handlers */

static void
set_selection_bounds (GtkTextBuffer *buffer,
		      Action        *action)
{
	GtkTextMark *insert_mark;
	GtkTextMark *bound_mark;
	GtkTextIter insert_iter;
	GtkTextIter bound_iter;

	insert_mark = gtk_text_buffer_get_insert (buffer);
	bound_mark = gtk_text_buffer_get_selection_bound (buffer);

	gtk_text_buffer_get_iter_at_mark (buffer, &insert_iter, insert_mark);
	gtk_text_buffer_get_iter_at_mark (buffer, &bound_iter, bound_mark);

	action->selection_insert = gtk_text_iter_get_offset (&insert_iter);
	action->selection_bound = gtk_text_iter_get_offset (&bound_iter);
}

static void
insert_text_cb (GtkTextBuffer               *buffer,
		GtkTextIter                 *location,
		const gchar                 *text,
		gint                         length,
		GtkSourceUndoManagerDefault *manager)
{
	Action *action = action_new ();

	action->type = ACTION_TYPE_INSERT;
	action->start = gtk_text_iter_get_offset (location);
	action->text = g_strndup (text, length);
	action->end = action->start + g_utf8_strlen (action->text, -1);

	set_selection_bounds (buffer, action);

	if (action->selection_insert != action->selection_bound ||
	    action->selection_insert != action->start)
	{
		action->selection_insert = -1;
		action->selection_bound = -1;
	}
	else
	{
		/* The insertion occurred at the cursor. */
		g_assert_cmpint (action->selection_insert, ==, action->start);
		g_assert_cmpint (action->selection_bound, ==, action->start);
	}

	insert_action (manager, action);
}

static void
delete_range_cb (GtkTextBuffer               *buffer,
		 GtkTextIter                 *start,
		 GtkTextIter                 *end,
		 GtkSourceUndoManagerDefault *manager)
{
	Action *action = action_new ();

	action->type = ACTION_TYPE_DELETE;
	action->start = gtk_text_iter_get_offset (start);
	action->end = gtk_text_iter_get_offset (end);
	action->text = gtk_text_buffer_get_slice (buffer, start, end, TRUE);

	g_assert_cmpint (action->start, <, action->end);

	set_selection_bounds (buffer, action);

	if ((action->selection_insert != action->start &&
	     action->selection_insert != action->end) ||
	    (action->selection_bound != action->start &&
	     action->selection_bound != action->end))
	{
		action->selection_insert = -1;
		action->selection_bound = -1;
	}

	insert_action (manager, action);
}

static void
begin_user_action_cb (GtkTextBuffer               *buffer,
		      GtkSourceUndoManagerDefault *manager)
{
	manager->priv->running_user_action = TRUE;
	update_can_undo_can_redo (manager);
}

static void
end_user_action_cb (GtkTextBuffer               *buffer,
		    GtkSourceUndoManagerDefault *manager)
{
	insert_new_action_group (manager);

	manager->priv->running_user_action = FALSE;
	update_can_undo_can_redo (manager);
}

static void
modified_changed_cb (GtkTextBuffer               *buffer,
		     GtkSourceUndoManagerDefault *manager)
{
	if (gtk_text_buffer_get_modified (buffer))
	{
		/* It can happen for example when the file on disk has been
		 * deleted.
		 */
		if (manager->priv->has_saved_location &&
		    manager->priv->saved_location == manager->priv->location &&
		    (manager->priv->new_action_group == NULL ||
		     manager->priv->new_action_group->actions->length == 0))
		{
			manager->priv->has_saved_location = FALSE;
		}
	}

	/* saved */
	else
	{
		/* Saving a buffer during a user action is allowed, the user
		 * action is split.
		 * FIXME and/or a warning should be printed?
		 */
		if (manager->priv->running_user_action)
		{
			insert_new_action_group (manager);
		}

		manager->priv->saved_location = manager->priv->location;
		manager->priv->has_saved_location = TRUE;
	}
}

static void
block_signal_handlers (GtkSourceUndoManagerDefault *manager)
{
	if (manager->priv->buffer == NULL)
	{
		return;
	}

	g_signal_handlers_block_by_func (manager->priv->buffer,
					 insert_text_cb,
					 manager);

	g_signal_handlers_block_by_func (manager->priv->buffer,
					 delete_range_cb,
					 manager);

	g_signal_handlers_block_by_func (manager->priv->buffer,
					 modified_changed_cb,
					 manager);
}

static void
unblock_signal_handlers (GtkSourceUndoManagerDefault *manager)
{
	if (manager->priv->buffer == NULL)
	{
		return;
	}

	g_signal_handlers_unblock_by_func (manager->priv->buffer,
					   insert_text_cb,
					   manager);

	g_signal_handlers_unblock_by_func (manager->priv->buffer,
					   delete_range_cb,
					   manager);

	g_signal_handlers_unblock_by_func (manager->priv->buffer,
					   modified_changed_cb,
					   manager);
}

static void
set_buffer (GtkSourceUndoManagerDefault *manager,
            GtkTextBuffer               *buffer)
{
	g_assert (manager->priv->buffer == NULL);

	if (buffer == NULL)
	{
		return;
	}

	manager->priv->buffer = buffer;

	g_object_add_weak_pointer (G_OBJECT (buffer),
				   (gpointer *)&manager->priv->buffer);

	g_signal_connect_object (buffer,
				 "insert-text",
				 G_CALLBACK (insert_text_cb),
				 manager,
				 0);

	g_signal_connect_object (buffer,
				 "delete-range",
				 G_CALLBACK (delete_range_cb),
				 manager,
				 0);

	g_signal_connect_object (buffer,
				 "begin-user-action",
				 G_CALLBACK (begin_user_action_cb),
				 manager,
				 0);

	g_signal_connect_object (buffer,
				 "end-user-action",
				 G_CALLBACK (end_user_action_cb),
				 manager,
				 0);

	g_signal_connect_object (buffer,
				 "modified-changed",
				 G_CALLBACK (modified_changed_cb),
				 manager,
				 0);

	modified_changed_cb (manager->priv->buffer, manager);
}

/* GObject construction, destruction and properties */

static void
gtk_source_undo_manager_default_set_property (GObject      *object,
                                              guint         prop_id,
                                              const GValue *value,
                                              GParamSpec   *pspec)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (object);

	switch (prop_id)
	{
		case PROP_BUFFER:
			set_buffer (manager, g_value_get_object (value));
			break;

		case PROP_MAX_UNDO_LEVELS:
			gtk_source_undo_manager_default_set_max_undo_levels (manager, g_value_get_int (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_undo_manager_default_get_property (GObject    *object,
                                              guint       prop_id,
                                              GValue     *value,
                                              GParamSpec *pspec)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (object);

	switch (prop_id)
	{
		case PROP_BUFFER:
			g_value_set_object (value, manager->priv->buffer);
			break;

		case PROP_MAX_UNDO_LEVELS:
			g_value_set_int (value, manager->priv->max_undo_levels);
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_undo_manager_default_dispose (GObject *object)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (object);

	if (manager->priv->buffer != NULL)
	{
		g_object_remove_weak_pointer (G_OBJECT (manager->priv->buffer),
					      (gpointer *)&manager->priv->buffer);

		manager->priv->buffer = NULL;
	}

	G_OBJECT_CLASS (gtk_source_undo_manager_default_parent_class)->dispose (object);
}

static void
gtk_source_undo_manager_default_finalize (GObject *object)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (object);

	g_queue_free_full (manager->priv->action_groups,
			   (GDestroyNotify) action_group_free);

	action_group_free (manager->priv->new_action_group);

	G_OBJECT_CLASS (gtk_source_undo_manager_default_parent_class)->finalize (object);
}

static void
gtk_source_undo_manager_default_class_init (GtkSourceUndoManagerDefaultClass *klass)
{
	GObjectClass *object_class = G_OBJECT_CLASS (klass);

	object_class->set_property = gtk_source_undo_manager_default_set_property;
	object_class->get_property = gtk_source_undo_manager_default_get_property;
	object_class->dispose = gtk_source_undo_manager_default_dispose;
	object_class->finalize = gtk_source_undo_manager_default_finalize;

	g_object_class_install_property (object_class,
	                                 PROP_BUFFER,
	                                 g_param_spec_object ("buffer",
	                                                      "Buffer",
	                                                      "The text buffer to add undo support on",
	                                                      GTK_TYPE_TEXT_BUFFER,
	                                                      G_PARAM_READWRITE |
							      G_PARAM_CONSTRUCT_ONLY |
							      G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (object_class,
	                                 PROP_MAX_UNDO_LEVELS,
	                                 g_param_spec_int ("max-undo-levels",
	                                                   "Max Undo Levels",
	                                                   "Number of undo levels for the buffer",
	                                                   -1,
	                                                   G_MAXINT,
	                                                   DEFAULT_MAX_UNDO_LEVELS,
	                                                   G_PARAM_READWRITE |
							   G_PARAM_STATIC_STRINGS));
}

static void
gtk_source_undo_manager_default_init (GtkSourceUndoManagerDefault *manager)
{
	manager->priv = gtk_source_undo_manager_default_get_instance_private (manager);

	manager->priv->action_groups = g_queue_new ();
	manager->priv->max_undo_levels = DEFAULT_MAX_UNDO_LEVELS;
}

/* Interface implementation */

static gboolean
gtk_source_undo_manager_can_undo_impl (GtkSourceUndoManager *undo_manager)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (undo_manager);
	return manager->priv->can_undo;
}

static gboolean
gtk_source_undo_manager_can_redo_impl (GtkSourceUndoManager *undo_manager)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (undo_manager);
	return manager->priv->can_redo;
}

static void
restore_modified_state (GtkSourceUndoManagerDefault *manager,
			GList                       *old_location,
			GList                       *new_location)
{
	if (manager->priv->has_saved_location)
	{
		if (old_location == manager->priv->saved_location)
		{
			gtk_text_buffer_set_modified (manager->priv->buffer, TRUE);
		}
		else if (new_location == manager->priv->saved_location)
		{
			gtk_text_buffer_set_modified (manager->priv->buffer, FALSE);
		}
	}
}

static void
gtk_source_undo_manager_undo_impl (GtkSourceUndoManager *undo_manager)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (undo_manager);
	GList *old_location;
	GList *new_location;
	ActionGroup *group;
	Action *action;
	GList *l;

	g_return_if_fail (manager->priv->can_undo);

	old_location = manager->priv->location;

	if (old_location != NULL)
	{
		new_location = manager->priv->location->prev;
	}
	else
	{
		new_location = manager->priv->action_groups->tail;
	}

	g_assert (new_location != NULL);

	group = new_location->data;
	g_assert_cmpuint (group->actions->length, >, 0);

	block_signal_handlers (manager);

	for (l = group->actions->tail; l != NULL; l = l->prev)
	{
		action = l->data;
		action_undo (manager->priv->buffer, action);
	}

	restore_modified_state (manager, old_location, new_location);

	/* After an undo, place the cursor at the first action in the group. For
	 * a search and replace, it will be the first occurrence in the buffer.
	 */
	action = g_queue_peek_head (group->actions);
	action_restore_selection (manager->priv->buffer, action, TRUE);

	unblock_signal_handlers (manager);

	manager->priv->location = new_location;
	update_can_undo_can_redo (manager);
}

static void
gtk_source_undo_manager_redo_impl (GtkSourceUndoManager *undo_manager)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (undo_manager);
	GList *old_location;
	GList *new_location;
	ActionGroup *group;
	GList *l;

	g_return_if_fail (manager->priv->can_redo);

	old_location = manager->priv->location;
	g_assert (old_location != NULL);

	new_location = old_location->next;

	group = old_location->data;

	block_signal_handlers (manager);

	for (l = group->actions->head; l != NULL; l = l->next)
	{
		Action *action = l->data;
		action_redo (manager->priv->buffer, action);

		/* For a redo, place the cursor at the first action in the
		 * group. For an undo the first action is also chosen, so when
		 * undoing/redoing a search and replace, the cursor position
		 * stays at the first occurrence and the user can see the
		 * replacement easily.
		 * For a redo, if we choose the last action in the group, when
		 * undoing/redoing a search and replace, the cursor position
		 * will jump between the first occurrence and the last
		 * occurrence. Staying at the same place is probably better.
		 */
		if (l == group->actions->head)
		{
			action_restore_selection (manager->priv->buffer, action, FALSE);
		}
	}

	restore_modified_state (manager, old_location, new_location);

	unblock_signal_handlers (manager);

	manager->priv->location = new_location;
	update_can_undo_can_redo (manager);
}

static void
gtk_source_undo_manager_begin_not_undoable_action_impl (GtkSourceUndoManager *undo_manager)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (undo_manager);
	manager->priv->running_not_undoable_actions++;

	if (manager->priv->running_not_undoable_actions == 1)
	{
		block_signal_handlers (manager);
	}
}

static void
gtk_source_undo_manager_end_not_undoable_action_impl (GtkSourceUndoManager *undo_manager)
{
	GtkSourceUndoManagerDefault *manager = GTK_SOURCE_UNDO_MANAGER_DEFAULT (undo_manager);

	g_return_if_fail (manager->priv->running_not_undoable_actions > 0);

	manager->priv->running_not_undoable_actions--;

	if (manager->priv->running_not_undoable_actions == 0)
	{
		unblock_signal_handlers (manager);
		clear_all (manager);
		modified_changed_cb (manager->priv->buffer, manager);
	}
}

static void
gtk_source_undo_manager_iface_init (GtkSourceUndoManagerIface *iface)
{
	iface->can_undo = gtk_source_undo_manager_can_undo_impl;
	iface->can_redo = gtk_source_undo_manager_can_redo_impl;
	iface->undo = gtk_source_undo_manager_undo_impl;
	iface->redo = gtk_source_undo_manager_redo_impl;
	iface->begin_not_undoable_action = gtk_source_undo_manager_begin_not_undoable_action_impl;
	iface->end_not_undoable_action = gtk_source_undo_manager_end_not_undoable_action_impl;
}

/* Public functions */

void
gtk_source_undo_manager_default_set_max_undo_levels (GtkSourceUndoManagerDefault *manager,
                                                     gint                         max_undo_levels)
{
	g_return_if_fail (GTK_SOURCE_IS_UNDO_MANAGER_DEFAULT (manager));
	g_return_if_fail (max_undo_levels >= -1);

	if (manager->priv->max_undo_levels != max_undo_levels)
	{
		if (max_undo_levels == 0)
		{
			/* disable the undo manager */
			block_signal_handlers (manager);
		}
		else if (manager->priv->max_undo_levels == 0)
		{
			unblock_signal_handlers (manager);
			modified_changed_cb (manager->priv->buffer, manager);
		}

		manager->priv->max_undo_levels = max_undo_levels;
		check_history_size (manager);

		g_object_notify (G_OBJECT (manager), "max-undo-levels");
	}
}
