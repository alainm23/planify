/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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
 */

/**
 * SECTION: e-reminders-widget
 * @include: libedataserverui/libedataserverui.h
 * @short_description: An #ERemindersWidget to work with past reminders
 *
 * The #ERemindersWidget is a widget which does common tasks on past reminders
 * provided by #EReminderWatcher. The owner should connect to the "changed" signal
 * to be notified on any changes, including when the list of past reminders
 * is either expanded or shrunk, which usually causes the dialog with this
 * widget to be shown or hidden.
 *
 * The widget itself is an #EExtensible.
 *
 * The widget does not listen to #EReminderWatcher::triggered signal.
 **/

#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include "libedataserver/libedataserver.h"
#include "libecal/libecal.h"

#include "libedataserverui-private.h"

#include "e-reminders-widget.h"

#define MAX_CUSTOM_SNOOZE_VALUES 7

struct _ERemindersWidgetPrivate {
	EReminderWatcher *watcher;
	GSettings *settings;
	gboolean is_empty;

	GtkTreeView *tree_view;
	GtkWidget *dismiss_button;
	GtkWidget *dismiss_all_button;
	GtkWidget *snooze_combo;
	GtkWidget *snooze_button;

	GtkWidget *add_snooze_popover;
	GtkWidget *add_snooze_days_spin;
	GtkWidget *add_snooze_hours_spin;
	GtkWidget *add_snooze_minutes_spin;
	GtkWidget *add_snooze_add_button;

	GtkInfoBar *info_bar;

	GCancellable *cancellable;
	guint refresh_idle_id;

	gboolean is_mapped;
	guint overdue_update_id;
	gint64 last_overdue_update; /* in seconds */
	gboolean overdue_update_rounded;

	gboolean updating_snooze_combo;
	gint last_selected_snooze_minutes; /* not the same as the saved value in GSettings */
};

enum {
	CHANGED,
	ACTIVATED,
	LAST_SIGNAL
};

enum {
	PROP_0,
	PROP_WATCHER,
	PROP_EMPTY
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_CODE (ERemindersWidget, e_reminders_widget, GTK_TYPE_GRID,
			 G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL))

static gboolean
reminders_widget_snooze_combo_separator_cb (GtkTreeModel *model,
					    GtkTreeIter *iter,
					    gpointer user_data)
{
	gint32 minutes = -1;

	if (!model || !iter)
		return FALSE;

	gtk_tree_model_get (model, iter, 1, &minutes, -1);

	return !minutes;
}

static GtkWidget *
reminders_widget_new_snooze_combo (void)
{
	GtkWidget *combo;
	GtkListStore *list_store;
	GtkCellRenderer *renderer;

	list_store = gtk_list_store_new (2, G_TYPE_STRING, G_TYPE_INT);

	combo = gtk_combo_box_new_with_model (GTK_TREE_MODEL (list_store));

	g_object_unref (list_store);

	renderer = gtk_cell_renderer_text_new ();
	gtk_cell_layout_pack_start (GTK_CELL_LAYOUT (combo), renderer, TRUE);
	gtk_cell_layout_set_attributes (GTK_CELL_LAYOUT (combo), renderer, "text", 0, NULL);

	gtk_combo_box_set_row_separator_func (GTK_COMBO_BOX (combo),
		reminders_widget_snooze_combo_separator_cb, NULL, NULL);

	return combo;
}

static void
reminders_widget_fill_snooze_combo (ERemindersWidget *reminders,
				    gint preselect_minutes)
{
	const gint predefined_minutes[] = {
		5,
		10,
		15,
		30,
		60,
		24 * 60,
		7 * 24 * 60
	};
	gint ii, last_sel = -1;
	GtkComboBox *combo;
	GtkListStore *list_store;
	GtkTreeIter iter, tosel_iter;
	GVariant *variant;
	gboolean tosel_set = FALSE;
	gboolean any_stored_added = FALSE;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	reminders->priv->updating_snooze_combo = TRUE;

	combo = GTK_COMBO_BOX (reminders->priv->snooze_combo);
	list_store = GTK_LIST_STORE (gtk_combo_box_get_model (combo));

	if (gtk_combo_box_get_active_iter (combo, &iter)) {
		gtk_tree_model_get (GTK_TREE_MODEL (list_store), &iter, 1, &last_sel, -1);
	}

	gtk_list_store_clear (list_store);

	#define add_minutes(_minutes) G_STMT_START {				\
		gint32 minutes = (_minutes);					\
		gchar *text;							\
										\
		text = e_cal_util_seconds_to_string (minutes * 60);		\
		gtk_list_store_append (list_store, &iter);			\
		gtk_list_store_set (list_store, &iter,				\
			0, text,						\
			1, minutes,						\
			-1);							\
		g_free (text);							\
										\
		if (preselect_minutes > 0 && preselect_minutes == minutes) {	\
			tosel_set = TRUE;					\
			tosel_iter = iter;					\
			last_sel = -1;						\
		} else if (last_sel > 0 && minutes == last_sel) {		\
			tosel_set = TRUE;					\
			tosel_iter = iter;					\
		}								\
	} G_STMT_END

	/* Custom user values first */
	variant = g_settings_get_value (reminders->priv->settings, "notify-custom-snooze-minutes");
	if (variant) {
		const gint32 *stored;
		gsize nstored = 0;

		stored = g_variant_get_fixed_array (variant, &nstored, sizeof (gint32));
		if (stored && nstored > 0) {
			for (ii = 0; ii < nstored; ii++) {
				if (stored[ii] > 0) {
					add_minutes (stored[ii]);
					any_stored_added = TRUE;
				}
			}
		}

		g_variant_unref (variant);

		if (any_stored_added) {
			/* Separator */
			gtk_list_store_append (list_store, &iter);
			gtk_list_store_set (list_store, &iter, 1, 0, -1);
		}
	}

	for (ii = 0; ii < G_N_ELEMENTS (predefined_minutes); ii++) {
		add_minutes (predefined_minutes[ii]);
	}

	#undef add_minutes

	/* Separator */
	gtk_list_store_append (list_store, &iter);
	gtk_list_store_set (list_store, &iter, 1, 0, -1);

	gtk_list_store_append (list_store, &iter);
	gtk_list_store_set (list_store, &iter, 0, _("Add custom time…"), 1, -1, -1);

	if (any_stored_added) {
		gtk_list_store_append (list_store, &iter);
		gtk_list_store_set (list_store, &iter, 0, _("Clear custom times"), 1, -2, -1);
	}

	reminders->priv->updating_snooze_combo = FALSE;

	if (tosel_set)
		gtk_combo_box_set_active_iter (combo, &tosel_iter);
	else
		gtk_combo_box_set_active (combo, 0);
}

static void
reminders_widget_custom_snooze_minutes_changed_cb (GSettings *settings,
						   const gchar *key,
						   gpointer user_data)
{
	ERemindersWidget *reminders = user_data;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	reminders_widget_fill_snooze_combo (reminders, -1);
}

static void
reminders_get_reminder_markups (ERemindersWidget *reminders,
				const EReminderData *rd,
				gchar **out_overdue_markup,
				gchar **out_description_markup)
{
	g_return_if_fail (rd != NULL);

	if (out_overdue_markup) {
		gint64 diff;
		gboolean in_future;
		gchar *time_str;

		diff = (g_get_real_time () / G_USEC_PER_SEC) - ((gint64) rd->instance.occur_start);
		in_future = diff < 0;
		if (in_future)
			diff = (-1) * diff;

		/* in minutes */
		if (in_future && (diff % 60) > 0)
			diff += 60;

		diff = diff / 60;

		if (!diff) {
			time_str = g_strdup (C_("overdue", "now"));
		} else if (diff < 60) {
			time_str = g_strdup_printf (g_dngettext (GETTEXT_PACKAGE, "%d minute", "%d minutes", diff), (gint) diff);
		} else if (diff < 24 * 60) {
			gint hours = diff / 60;

			time_str = g_strdup_printf (g_dngettext (GETTEXT_PACKAGE, "%d hour", "%d hours", hours), hours);
		} else if (diff < 7 * 24 * 60) {
			gint days = diff / (24 * 60);

			time_str = g_strdup_printf (g_dngettext (GETTEXT_PACKAGE, "%d day", "%d days", days), days);
		} else if (diff < 54 * 7 * 24 * 60) {
			gint weeks = diff / (7 * 24 * 60);

			time_str = g_strdup_printf (g_dngettext (GETTEXT_PACKAGE, "%d week", "%d weeks", weeks), weeks);
		} else {
			gint years = diff / (366 * 24 * 60);

			time_str = g_strdup_printf (g_dngettext (GETTEXT_PACKAGE, "%d year", "%d years", years), years);
		}

		if (in_future || !diff) {
			*out_overdue_markup = g_markup_printf_escaped ("<span size=\"x-small\">%s</span>", time_str);
		} else {
			*out_overdue_markup = g_markup_printf_escaped ("<span size=\"x-small\">%s\n%s</span>", time_str, C_("overdue", "overdue"));
		}

		g_free (time_str);
	}

	if (out_description_markup) {
		*out_description_markup = e_reminder_watcher_describe_data (reminders->priv->watcher, rd, E_REMINDER_WATCHER_DESCRIBE_FLAG_MARKUP);
	}
}

static void
reminders_widget_overdue_update (ERemindersWidget *reminders)
{
	GtkListStore *list_store;
	GtkTreeModel *model;
	GtkTreeIter iter;
	gboolean any_changed = FALSE;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	model = gtk_tree_view_get_model (reminders->priv->tree_view);
	if (!model)
		return;

	if (!gtk_tree_model_get_iter_first (model, &iter))
		return;

	list_store = GTK_LIST_STORE (model);

	do {
		EReminderData *rd = NULL;

		gtk_tree_model_get (model, &iter,
			E_REMINDERS_WIDGET_COLUMN_REMINDER_DATA, &rd,
			-1);

		if (rd) {
			gchar *overdue_markup = NULL;

			reminders_get_reminder_markups (reminders, rd, &overdue_markup, NULL);
			if (overdue_markup) {
				gchar *current = NULL;

				gtk_tree_model_get (model, &iter,
					E_REMINDERS_WIDGET_COLUMN_OVERDUE, &current,
					-1);

				if (g_strcmp0 (current, overdue_markup) != 0) {
					gtk_list_store_set (list_store, &iter,
						E_REMINDERS_WIDGET_COLUMN_OVERDUE, overdue_markup,
						-1);
					any_changed = TRUE;
				}

				g_free (overdue_markup);
				g_free (current);
			}

			e_reminder_data_free (rd);
		}
	} while (gtk_tree_model_iter_next (model, &iter));

	if (any_changed) {
		GtkTreeViewColumn *column;

		column = gtk_tree_view_get_column (reminders->priv->tree_view, 0);
		if (column)
			gtk_tree_view_column_queue_resize (column);
	}
}

static gboolean
reminders_widget_overdue_update_cb (gpointer user_data)
{
	ERemindersWidget *reminders = user_data;
	gint64 now_seconds, last_update;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_REMINDERS_WIDGET (reminders), FALSE);

	reminders_widget_overdue_update (reminders);

	now_seconds = g_get_real_time () / G_USEC_PER_SEC;
	last_update = reminders->priv->last_overdue_update;
	reminders->priv->last_overdue_update = now_seconds;

	if (!last_update || (
	    (now_seconds - last_update) % 60 > 2 &&
	    (now_seconds - last_update) % 60 < 58)) {
		gint until_minute = 60 - (now_seconds % 60);

		if (until_minute >= 59) {
			reminders->priv->overdue_update_rounded = TRUE;
			until_minute = 60;
		} else {
			reminders->priv->overdue_update_rounded = FALSE;
		}

		reminders->priv->overdue_update_id = g_timeout_add_seconds (until_minute,
			reminders_widget_overdue_update_cb, reminders);

		return FALSE;
	} else if (!reminders->priv->overdue_update_rounded) {
		reminders->priv->overdue_update_rounded = TRUE;
		reminders->priv->overdue_update_id = g_timeout_add_seconds (60,
			reminders_widget_overdue_update_cb, reminders);

		return FALSE;
	}

	return TRUE;
}

static void
reminders_widget_maybe_schedule_overdue_update (ERemindersWidget *reminders)
{
	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (reminders->priv->is_empty || !reminders->priv->is_mapped) {
		if (reminders->priv->overdue_update_id) {
			g_source_remove (reminders->priv->overdue_update_id);
			reminders->priv->overdue_update_id = 0;
		}
	} else if (!reminders->priv->overdue_update_id) {
		gint until_minute = 60 - ((g_get_real_time () / G_USEC_PER_SEC) % 60);

		reminders->priv->last_overdue_update = g_get_real_time () / G_USEC_PER_SEC;

		if (until_minute >= 59) {
			reminders->priv->overdue_update_rounded = TRUE;
			until_minute = 60;
		} else {
			reminders->priv->overdue_update_rounded = FALSE;
		}

		reminders->priv->overdue_update_id = g_timeout_add_seconds (until_minute,
			reminders_widget_overdue_update_cb, reminders);
	}
}

static void
reminders_widget_map (GtkWidget *widget)
{
	ERemindersWidget *reminders;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (widget));

	/* Chain up to parent's method. */
	GTK_WIDGET_CLASS (e_reminders_widget_parent_class)->map (widget);

	reminders = E_REMINDERS_WIDGET (widget);
	reminders->priv->is_mapped = TRUE;

	reminders_widget_maybe_schedule_overdue_update (reminders);
}


static void
reminders_widget_unmap (GtkWidget *widget)
{
	ERemindersWidget *reminders;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (widget));

	/* Chain up to parent's method. */
	GTK_WIDGET_CLASS (e_reminders_widget_parent_class)->unmap (widget);

	reminders = E_REMINDERS_WIDGET (widget);
	reminders->priv->is_mapped = FALSE;

	reminders_widget_maybe_schedule_overdue_update (reminders);
}

static gint
reminders_sort_by_occur (gconstpointer ptr1,
			 gconstpointer ptr2)
{
	const EReminderData *rd1 = ptr1, *rd2 = ptr2;
	gint cmp;

	if (!rd1 || !rd2)
		return rd1 == rd2 ? 0 : rd1 ? 1 : -1;

	if (rd1->instance.occur_start != rd2->instance.occur_start)
		return rd1->instance.occur_start < rd2->instance.occur_start ? -1 : 1;

	if (rd1->instance.trigger != rd2->instance.trigger)
		return rd1->instance.trigger < rd2->instance.trigger ? -1 : 1;

	cmp = g_strcmp0 (rd1->source_uid, rd2->source_uid);
	if (!cmp)
		cmp = g_strcmp0 (rd1->instance.auid, rd2->instance.auid);

	return cmp;
}

static void
reminders_widget_set_is_empty (ERemindersWidget *reminders,
			       gboolean is_empty)
{
	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (!is_empty == !reminders->priv->is_empty)
		return;

	reminders->priv->is_empty = is_empty;

	g_object_notify (G_OBJECT (reminders), "empty");

	reminders_widget_maybe_schedule_overdue_update (reminders);
}

static gint
reminders_widget_invert_tree_path_compare (gconstpointer ptr1,
					   gconstpointer ptr2)
{
	return (-1) * gtk_tree_path_compare (ptr1, ptr2);
}

static void
reminders_widget_select_one_of (ERemindersWidget *reminders,
				GList **inout_previous_paths) /* GtkTreePath * */
{
	GList *link;
	guint len;
	gint to_select = -1;
	gint n_rows;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (!inout_previous_paths || !*inout_previous_paths)
		return;

	n_rows = gtk_tree_model_iter_n_children (gtk_tree_view_get_model (reminders->priv->tree_view), NULL);
	if (n_rows <= 0)
		return;

	*inout_previous_paths = g_list_sort (*inout_previous_paths, reminders_widget_invert_tree_path_compare);

	len = g_list_length (*inout_previous_paths);

	for (link = *inout_previous_paths; link && to_select == -1; link = g_list_next (link), len--) {
		GtkTreePath *path = link->data;
		gint *indices, index;

		if (!path || gtk_tree_path_get_depth (path) != 1)
			continue;

		indices = gtk_tree_path_get_indices (path);
		if (!indices)
			continue;

		index = indices[0] - len + 1;

		if (index >= n_rows)
			to_select = n_rows - 1;
		else
			to_select = index;
	}

	if (to_select >= 0 && to_select < n_rows) {
		GtkTreePath *path;

		path = gtk_tree_path_new_from_indices (to_select, -1);
		if (path) {
			gtk_tree_selection_select_path (gtk_tree_view_get_selection (reminders->priv->tree_view), path);
			gtk_tree_path_free (path);
		}
	}
}

static gboolean
reminders_widget_refresh_content_cb (gpointer user_data)
{
	ERemindersWidget *reminders = user_data;
	GList *previous_paths;
	GSList *past;
	GtkTreeModel *model;
	GtkTreeSelection *selection;
	GtkListStore *list_store;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_REMINDERS_WIDGET (reminders), FALSE);

	reminders->priv->refresh_idle_id = 0;

	model = gtk_tree_view_get_model (reminders->priv->tree_view);
	if (!model)
		return FALSE;

	selection = gtk_tree_view_get_selection (reminders->priv->tree_view);
	previous_paths = gtk_tree_selection_get_selected_rows (selection, NULL);
	list_store = GTK_LIST_STORE (model);

	g_object_ref (model);
	gtk_tree_view_set_model (reminders->priv->tree_view, NULL);

	gtk_list_store_clear (list_store);

	past = e_reminder_watcher_dup_past (reminders->priv->watcher);
	if (past) {
		GSList *link;
		GtkTreeIter iter;

		past = g_slist_sort (past, reminders_sort_by_occur);
		for (link = past; link; link = g_slist_next (link)) {
			const EReminderData *rd = link->data;
			gchar *overdue = NULL, *description = NULL;

			if (!rd || !rd->component)
				continue;

			reminders_get_reminder_markups (reminders, rd, &overdue, &description);

			gtk_list_store_append (list_store, &iter);
			gtk_list_store_set (list_store, &iter,
				E_REMINDERS_WIDGET_COLUMN_OVERDUE, overdue,
				E_REMINDERS_WIDGET_COLUMN_DESCRIPTION, description,
				E_REMINDERS_WIDGET_COLUMN_REMINDER_DATA, rd,
				-1);

			g_free (description);
			g_free (overdue);
		}
	}

	gtk_tree_view_set_model (reminders->priv->tree_view, model);
	g_object_unref (model);

	reminders_widget_set_is_empty (reminders, !past);

	if (past) {
		GtkTreeViewColumn *column;

		column = gtk_tree_view_get_column (reminders->priv->tree_view, 0);
		if (column)
			gtk_tree_view_column_queue_resize (column);

		reminders_widget_select_one_of (reminders, &previous_paths);
	}

	g_list_free_full (previous_paths, (GDestroyNotify) gtk_tree_path_free);
	g_slist_free_full (past, e_reminder_data_free);

	g_signal_emit (reminders, signals[CHANGED], 0, NULL);

	return FALSE;
}

static void
reminders_widget_schedule_content_refresh (ERemindersWidget *reminders)
{
	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (!reminders->priv->refresh_idle_id) {
		reminders->priv->refresh_idle_id = g_idle_add_full (G_PRIORITY_DEFAULT_IDLE,
			reminders_widget_refresh_content_cb, reminders, NULL);
	}
}

static void
reminders_widget_watcher_changed_cb (EReminderWatcher *watcher,
				     gpointer user_data)
{
	ERemindersWidget *reminders = user_data;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	reminders_widget_schedule_content_refresh (reminders);
}

static void
reminders_widget_gather_selected_cb (GtkTreeModel *model,
				     GtkTreePath *path,
				     GtkTreeIter *iter,
				     gpointer user_data)
{
	GSList **inout_selected = user_data;
	EReminderData *rd = NULL;

	g_return_if_fail (inout_selected != NULL);

	gtk_tree_model_get (model, iter, E_REMINDERS_WIDGET_COLUMN_REMINDER_DATA, &rd, -1);

	if (rd)
		*inout_selected = g_slist_prepend (*inout_selected, rd);
}

static void
reminders_widget_do_dismiss_cb (ERemindersWidget *reminders,
				const EReminderData *rd,
				GString *gathered_errors,
				GCancellable *cancellable,
				gpointer user_data)
{
	GError *local_error = NULL;

	if (g_cancellable_is_cancelled (cancellable))
		return;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));
	g_return_if_fail (rd != NULL);

	if (!e_reminder_watcher_dismiss_sync (reminders->priv->watcher, rd, cancellable, &local_error) && local_error && gathered_errors &&
	    !g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		if (gathered_errors->len)
			g_string_append_c (gathered_errors, '\n');
		g_string_append (gathered_errors, local_error->message);
	}

	g_clear_error (&local_error);
}

typedef void (* ForeachSelectedSyncFunc) (ERemindersWidget *reminders,
					  const EReminderData *rd,
					  GString *gathered_errors,
					  GCancellable *cancellable,
					  gpointer user_data);

typedef struct _ForeachSelectedData {
	GSList *selected; /* EReminderData * */
	ForeachSelectedSyncFunc sync_func;
	gpointer user_data;
	GDestroyNotify user_data_destroy;
	gchar *error_prefix;
} ForeachSelectedData;

static void
foreach_selected_data_free (gpointer ptr)
{
	ForeachSelectedData *fsd = ptr;

	if (fsd) {
		g_slist_free_full (fsd->selected, e_reminder_data_free);
		if (fsd->user_data_destroy)
			fsd->user_data_destroy (fsd->user_data);
		g_free (fsd->error_prefix);
		g_free (fsd);
	}
}

static void
reminders_widget_foreach_selected_thread (GTask *task,
					  gpointer source_object,
					  gpointer task_data,
					  GCancellable *cancellable)
{
	ForeachSelectedData *fsd = task_data;
	GString *gathered_errors;
	GSList *link;

	g_return_if_fail (fsd != NULL);
	g_return_if_fail (fsd->selected != NULL);
	g_return_if_fail (fsd->sync_func != NULL);

	if (g_cancellable_is_cancelled (cancellable))
		return;

	gathered_errors = g_string_new ("");

	for (link = fsd->selected; link && !g_cancellable_is_cancelled (cancellable); link = g_slist_next (link)) {
		const EReminderData *rd = link->data;

		fsd->sync_func (source_object, rd, gathered_errors, cancellable, fsd->user_data);
	}

	if (gathered_errors->len) {
		if (fsd->error_prefix) {
			g_string_prepend_c (gathered_errors, '\n');
			g_string_prepend (gathered_errors, fsd->error_prefix);
		}

		g_task_return_new_error (task, G_IO_ERROR, G_IO_ERROR_FAILED, "%s", gathered_errors->str);
	} else {
		g_task_return_boolean (task, TRUE);
	}

	g_string_free (gathered_errors, TRUE);
}

static void
reminders_widget_foreach_selected_done_cb (GObject *source_object,
					   GAsyncResult *result,
					   gpointer user_data)
{
	ERemindersWidget *reminders;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (source_object));

	reminders = E_REMINDERS_WIDGET (source_object);
	g_return_if_fail (g_task_is_valid (result, reminders));

	if (!g_task_propagate_boolean (G_TASK (result), &local_error) && local_error) {
		e_reminders_widget_report_error (reminders, NULL, local_error);
	}

	g_clear_error (&local_error);
}

static void
reminders_widget_foreach_selected (ERemindersWidget *reminders,
				   ForeachSelectedSyncFunc sync_func,
				   gpointer user_data,
				   GDestroyNotify user_data_destroy,
				   const gchar *error_prefix)
{
	GtkTreeSelection *selection;
	GSList *selected = NULL; /* EReminderData * */
	GTask *task;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));
	g_return_if_fail (sync_func != NULL);

	selection = gtk_tree_view_get_selection (reminders->priv->tree_view);
	gtk_tree_selection_selected_foreach (selection, reminders_widget_gather_selected_cb, &selected);

	if (selected) {
		ForeachSelectedData *fsd;

		fsd = g_new0 (ForeachSelectedData, 1);
		fsd->selected = selected; /* Takes ownership */
		fsd->sync_func = sync_func;
		fsd->user_data = user_data;
		fsd->user_data_destroy = user_data_destroy;
		fsd->error_prefix = g_strdup (error_prefix);

		task = g_task_new (reminders, reminders->priv->cancellable, reminders_widget_foreach_selected_done_cb, NULL);
		g_task_set_task_data (task, fsd, foreach_selected_data_free);
		g_task_set_check_cancellable (task, FALSE);
		g_task_run_in_thread (task, reminders_widget_foreach_selected_thread);
		g_object_unref (task);
	}
}

static void
reminders_widget_row_activated_cb (GtkTreeView *tree_view,
				   GtkTreePath *path,
				   GtkTreeViewColumn *column,
				   gpointer user_data)
{
	ERemindersWidget *reminders = user_data;
	GtkTreeModel *model;
	GtkTreeIter iter;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (!path)
		return;

	model = gtk_tree_view_get_model (reminders->priv->tree_view);
	if (gtk_tree_model_get_iter (model, &iter, path)) {
		EReminderData *rd = NULL;

		gtk_tree_model_get (model, &iter,
			E_REMINDERS_WIDGET_COLUMN_REMINDER_DATA, &rd,
			-1);

		if (rd) {
			gboolean result = FALSE;

			g_signal_emit (reminders, signals[ACTIVATED], 0, rd, &result);

			if (!result) {
				const gchar *scheme = NULL;
				const gchar *comp_uid = NULL;

				e_cal_component_get_uid (rd->component, &comp_uid);

				switch (e_cal_component_get_vtype (rd->component)) {
					case E_CAL_COMPONENT_EVENT:
						scheme = "calendar:";
						break;
					case E_CAL_COMPONENT_TODO:
						scheme = "task:";
						break;
					case E_CAL_COMPONENT_JOURNAL:
						scheme = "memo:";
						break;
					default:
						break;
				}

				if (scheme && comp_uid && rd->source_uid) {
					GString *uri;
					gchar *tmp;
					GError *error = NULL;

					uri = g_string_sized_new (128);
					g_string_append (uri, scheme);
					g_string_append (uri, "///?");

					tmp = g_uri_escape_string (rd->source_uid, NULL, TRUE);
					g_string_append (uri, "source-uid=");
					g_string_append (uri, tmp);
					g_free (tmp);

					g_string_append (uri, "&");

					tmp = g_uri_escape_string (comp_uid, NULL, TRUE);
					g_string_append (uri, "comp-uid=");
					g_string_append (uri, tmp);
					g_free (tmp);

					if (!g_app_info_launch_default_for_uri (uri->str, NULL, &error) &&
					    !g_error_matches (error, G_IO_ERROR, G_IO_ERROR_NOT_SUPPORTED)) {
						gchar *prefix = g_strdup_printf (_("Failed to launch URI “%s”:"), uri->str);
						e_reminders_widget_report_error (reminders, prefix, error);
						g_free (prefix);
					}

					g_string_free (uri, TRUE);
					g_clear_error (&error);
				}
			}

			e_reminder_data_free (rd);
		}
	}
}

static void
reminders_widget_selection_changed_cb (GtkTreeSelection *selection,
				       gpointer user_data)
{
	ERemindersWidget *reminders = user_data;
	gint nselected;

	g_return_if_fail (GTK_IS_TREE_SELECTION (selection));
	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	nselected = gtk_tree_selection_count_selected_rows (selection);
	gtk_widget_set_sensitive (reminders->priv->snooze_combo, nselected > 0);
	gtk_widget_set_sensitive (reminders->priv->snooze_button, nselected > 0);
	gtk_widget_set_sensitive (reminders->priv->dismiss_button, nselected > 0);
}

static void
reminders_widget_dismiss_button_clicked_cb (GtkButton *button,
					    gpointer user_data)
{
	ERemindersWidget *reminders = user_data;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	g_signal_handlers_block_by_func (reminders->priv->watcher, reminders_widget_watcher_changed_cb, reminders);

	reminders_widget_foreach_selected (reminders, reminders_widget_do_dismiss_cb, NULL, NULL, _("Failed to dismiss reminder:"));

	g_signal_handlers_unblock_by_func (reminders->priv->watcher, reminders_widget_watcher_changed_cb, reminders);

	reminders_widget_watcher_changed_cb (reminders->priv->watcher, reminders);
}

static void
reminders_widget_dismiss_all_done_cb (GObject *source_object,
				      GAsyncResult *result,
				      gpointer user_data)
{
	ERemindersWidget *reminders = user_data;
	GError *local_error = NULL;

	g_return_if_fail (E_IS_REMINDER_WATCHER (source_object));

	if (!e_reminder_watcher_dismiss_all_finish (reminders->priv->watcher, result, &local_error) &&
	    !g_error_matches (local_error, G_IO_ERROR, G_IO_ERROR_CANCELLED)) {
		g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

		e_reminders_widget_report_error (reminders, _("Failed to dismiss all:"), local_error);
	}

	g_clear_error (&local_error);
}

static void
reminders_widget_dismiss_all_button_clicked_cb (GtkButton *button,
						gpointer user_data)
{
	ERemindersWidget *reminders = user_data;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	e_reminder_watcher_dismiss_all (reminders->priv->watcher, reminders->priv->cancellable,
		reminders_widget_dismiss_all_done_cb, reminders);
}

static void
reminders_widget_add_snooze_add_button_clicked_cb (GtkButton *button,
						   gpointer user_data)
{
	ERemindersWidget *reminders = user_data;
	GtkTreeModel *model;
	GtkTreeIter iter;
	gboolean found = FALSE;
	gint new_minutes;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	new_minutes =
		gtk_spin_button_get_value_as_int (GTK_SPIN_BUTTON (reminders->priv->add_snooze_minutes_spin)) +
		(60 * gtk_spin_button_get_value_as_int (GTK_SPIN_BUTTON (reminders->priv->add_snooze_hours_spin))) +
		(24 * 60 * gtk_spin_button_get_value_as_int (GTK_SPIN_BUTTON (reminders->priv->add_snooze_days_spin)));
	g_return_if_fail (new_minutes > 0);

	gtk_widget_hide (reminders->priv->add_snooze_popover);

	model = gtk_combo_box_get_model (GTK_COMBO_BOX (reminders->priv->snooze_combo));
	g_return_if_fail (model != NULL);

	if (gtk_tree_model_get_iter_first (model, &iter)) {
		do {
			gint minutes = 0;

			gtk_tree_model_get (model, &iter, 1, &minutes, -1);

			if (minutes == new_minutes) {
				found = TRUE;
				gtk_combo_box_set_active_iter (GTK_COMBO_BOX (reminders->priv->snooze_combo), &iter);
				break;
			}
		} while (gtk_tree_model_iter_next (model, &iter));
	}

	if (!found) {
		GVariant *variant;
		gint32 array[MAX_CUSTOM_SNOOZE_VALUES] = { 0 }, narray = 0, ii;

		variant = g_settings_get_value (reminders->priv->settings, "notify-custom-snooze-minutes");
		if (variant) {
			const gint32 *stored;
			gsize nstored = 0;

			stored = g_variant_get_fixed_array (variant, &nstored, sizeof (gint32));
			if (stored && nstored > 0) {
				/* Skip the oldest, when too many stored */
				for (ii = nstored >= MAX_CUSTOM_SNOOZE_VALUES ? 1 : 0; ii < MAX_CUSTOM_SNOOZE_VALUES && ii < nstored; ii++) {
					array[narray] = stored[ii];
					narray++;
				}
			}

			g_variant_unref (variant);
		}

		/* Add the new at the end of the array */
		array[narray] = new_minutes;
		narray++;

		variant = g_variant_new_fixed_array (G_VARIANT_TYPE_INT32, array, narray, sizeof (gint32));
		g_settings_set_value (reminders->priv->settings, "notify-custom-snooze-minutes", variant);

		reminders_widget_fill_snooze_combo (reminders, new_minutes);
	}
}

static void
reminders_widget_add_snooze_update_sensitize_cb (GtkSpinButton *spin,
						 gpointer user_data)
{
	ERemindersWidget *reminders = user_data;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	gtk_widget_set_sensitive (reminders->priv->add_snooze_add_button,
		gtk_spin_button_get_value_as_int (GTK_SPIN_BUTTON (reminders->priv->add_snooze_minutes_spin)) +
		gtk_spin_button_get_value_as_int (GTK_SPIN_BUTTON (reminders->priv->add_snooze_hours_spin)) +
		gtk_spin_button_get_value_as_int (GTK_SPIN_BUTTON (reminders->priv->add_snooze_days_spin)) > 0);
}

static void
reminders_widget_snooze_add_custom (ERemindersWidget *reminders)
{
	GtkTreeIter iter;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (!reminders->priv->add_snooze_popover) {
		GtkWidget *widget;
		GtkBox *vbox, *box;

		reminders->priv->add_snooze_days_spin = gtk_spin_button_new_with_range (0.0, 366.0, 1.0);
		reminders->priv->add_snooze_hours_spin = gtk_spin_button_new_with_range (0.0, 23.0, 1.0);
		reminders->priv->add_snooze_minutes_spin = gtk_spin_button_new_with_range (0.0, 59.0, 1.0);

		g_object_set (G_OBJECT (reminders->priv->add_snooze_days_spin),
			"digits", 0,
			"numeric", TRUE,
			"snap-to-ticks", TRUE,
			NULL);

		g_object_set (G_OBJECT (reminders->priv->add_snooze_hours_spin),
			"digits", 0,
			"numeric", TRUE,
			"snap-to-ticks", TRUE,
			NULL);

		g_object_set (G_OBJECT (reminders->priv->add_snooze_minutes_spin),
			"digits", 0,
			"numeric", TRUE,
			"snap-to-ticks", TRUE,
			NULL);

		vbox = GTK_BOX (gtk_box_new (GTK_ORIENTATION_VERTICAL, 2));

		widget = gtk_label_new (_("Set a custom snooze time for"));
		gtk_box_pack_start (vbox, widget, FALSE, FALSE, 0);

		box = GTK_BOX (gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 2));
		g_object_set (G_OBJECT (box),
			"halign", GTK_ALIGN_START,
			"hexpand", FALSE,
			"valign", GTK_ALIGN_CENTER,
			"vexpand", FALSE,
			NULL);

		gtk_box_pack_start (box, reminders->priv->add_snooze_days_spin, FALSE, FALSE, 4);
		/* Translators: this is part of: "Set a custom snooze time for [nnn] days [nnn] hours [nnn] minutes", where the text in "[]" means a separate widget */
		widget = gtk_label_new_with_mnemonic (C_("reminders-snooze", "da_ys"));
		gtk_label_set_mnemonic_widget (GTK_LABEL (widget), reminders->priv->add_snooze_days_spin);
		gtk_box_pack_start (box, widget, FALSE, FALSE, 4);

		gtk_box_pack_start (vbox, GTK_WIDGET (box), FALSE, FALSE, 0);

		box = GTK_BOX (gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 2));
		g_object_set (G_OBJECT (box),
			"halign", GTK_ALIGN_START,
			"hexpand", FALSE,
			"valign", GTK_ALIGN_CENTER,
			"vexpand", FALSE,
			NULL);

		gtk_box_pack_start (box, reminders->priv->add_snooze_hours_spin, FALSE, FALSE, 4);
		/* Translators: this is part of: "Set a custom snooze time for [nnn] days [nnn] hours [nnn] minutes", where the text in "[]" means a separate widget */
		widget = gtk_label_new_with_mnemonic (C_("reminders-snooze", "_hours"));
		gtk_label_set_mnemonic_widget (GTK_LABEL (widget), reminders->priv->add_snooze_hours_spin);
		gtk_box_pack_start (box, widget, FALSE, FALSE, 4);

		gtk_box_pack_start (vbox, GTK_WIDGET (box), FALSE, FALSE, 0);

		box = GTK_BOX (gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 2));
		g_object_set (G_OBJECT (box),
			"halign", GTK_ALIGN_START,
			"hexpand", FALSE,
			"valign", GTK_ALIGN_CENTER,
			"vexpand", FALSE,
			NULL);

		gtk_box_pack_start (box, reminders->priv->add_snooze_minutes_spin, FALSE, FALSE, 4);
		/* Translators: this is part of: "Set a custom snooze time for [nnn] days [nnn] hours [nnn] minutes", where the text in "[]" means a separate widget */
		widget = gtk_label_new_with_mnemonic (C_("reminders-snooze", "_minutes"));
		gtk_label_set_mnemonic_widget (GTK_LABEL (widget), reminders->priv->add_snooze_minutes_spin);
		gtk_box_pack_start (box, widget, FALSE, FALSE, 4);

		gtk_box_pack_start (vbox, GTK_WIDGET (box), FALSE, FALSE, 0);

		reminders->priv->add_snooze_add_button = gtk_button_new_with_mnemonic (_("_Add Snooze time"));
		g_object_set (G_OBJECT (reminders->priv->add_snooze_add_button),
			"halign", GTK_ALIGN_CENTER,
			NULL);

		gtk_box_pack_start (vbox, reminders->priv->add_snooze_add_button, FALSE, FALSE, 0);

		gtk_widget_show_all (GTK_WIDGET (vbox));

		reminders->priv->add_snooze_popover = gtk_popover_new (GTK_WIDGET (reminders));
		gtk_popover_set_position (GTK_POPOVER (reminders->priv->add_snooze_popover), GTK_POS_BOTTOM);
		gtk_container_add (GTK_CONTAINER (reminders->priv->add_snooze_popover), GTK_WIDGET (vbox));
		gtk_container_set_border_width (GTK_CONTAINER (reminders->priv->add_snooze_popover), 6);

		g_signal_connect (reminders->priv->add_snooze_add_button, "clicked",
			G_CALLBACK (reminders_widget_add_snooze_add_button_clicked_cb), reminders);

		g_signal_connect (reminders->priv->add_snooze_days_spin, "value-changed",
			G_CALLBACK (reminders_widget_add_snooze_update_sensitize_cb), reminders);

		g_signal_connect (reminders->priv->add_snooze_hours_spin, "value-changed",
			G_CALLBACK (reminders_widget_add_snooze_update_sensitize_cb), reminders);

		g_signal_connect (reminders->priv->add_snooze_minutes_spin, "value-changed",
			G_CALLBACK (reminders_widget_add_snooze_update_sensitize_cb), reminders);

		reminders_widget_add_snooze_update_sensitize_cb (NULL, reminders);
	}

	if (gtk_combo_box_get_active_iter (GTK_COMBO_BOX (reminders->priv->snooze_combo), &iter)) {
		gint minutes = -1;

		gtk_tree_model_get (gtk_combo_box_get_model (GTK_COMBO_BOX (reminders->priv->snooze_combo)), &iter, 1, &minutes, -1);

		if (minutes > 0) {
			gtk_spin_button_set_value (GTK_SPIN_BUTTON (reminders->priv->add_snooze_minutes_spin), minutes % 60);

			minutes = minutes / 60;
			gtk_spin_button_set_value (GTK_SPIN_BUTTON (reminders->priv->add_snooze_hours_spin), minutes % 24);

			minutes = minutes / 24;
			gtk_spin_button_set_value (GTK_SPIN_BUTTON (reminders->priv->add_snooze_days_spin), minutes);
		}
	}

	gtk_widget_hide (reminders->priv->add_snooze_popover);
	gtk_popover_set_relative_to (GTK_POPOVER (reminders->priv->add_snooze_popover), reminders->priv->snooze_combo);
	gtk_widget_show (reminders->priv->add_snooze_popover);

	gtk_widget_grab_focus (reminders->priv->add_snooze_days_spin);
}

static void
reminders_widget_snooze_combo_changed_cb (GtkComboBox *combo,
					  gpointer user_data)
{
	ERemindersWidget *reminders = user_data;
	GtkTreeIter iter;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (reminders->priv->updating_snooze_combo)
		return;

	if (gtk_combo_box_get_active_iter (combo, &iter)) {
		GtkTreeModel *model;
		gint minutes = -3;

		model = gtk_combo_box_get_model (combo);

		gtk_tree_model_get (model, &iter, 1, &minutes, -1);

		if (minutes > 0) {
			reminders->priv->last_selected_snooze_minutes = minutes;
		} else if (minutes == -1 || minutes == -2) {
			if (reminders->priv->last_selected_snooze_minutes) {
				reminders->priv->updating_snooze_combo = TRUE;

				if (gtk_tree_model_get_iter_first (model, &iter)) {
					do {
						gint stored = -1;

						gtk_tree_model_get (model, &iter, 1, &stored, -1);
						if (stored == reminders->priv->last_selected_snooze_minutes) {
							gtk_combo_box_set_active_iter (combo, &iter);
							break;
						}
					} while (gtk_tree_model_iter_next (model, &iter));
				}

				reminders->priv->updating_snooze_combo = FALSE;
			}

			/* The "Add custom" item was selected */
			if (minutes == -1) {
				reminders_widget_snooze_add_custom (reminders);
			/* The "Clear custom times" item was selected */
			} else if (minutes == -2) {
				g_settings_reset (reminders->priv->settings, "notify-custom-snooze-minutes");
			}
		}
	}
}

static void
reminders_widget_snooze_button_clicked_cb (GtkButton *button,
					   gpointer user_data)
{
	ERemindersWidget *reminders = user_data;
	GtkTreeSelection *selection;
	GSList *selected = NULL, *link;
	GtkTreeIter iter;
	gint minutes = 0;
	gint64 until;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));
	g_return_if_fail (gtk_combo_box_get_active_iter (GTK_COMBO_BOX (reminders->priv->snooze_combo), &iter));

	gtk_tree_model_get (gtk_combo_box_get_model (GTK_COMBO_BOX (reminders->priv->snooze_combo)), &iter, 1, &minutes, -1);

	g_return_if_fail (minutes > 0);

	until = (g_get_real_time () / G_USEC_PER_SEC) + (minutes * 60);

	g_settings_set_int (reminders->priv->settings, "notify-last-snooze-minutes", minutes);

	selection = gtk_tree_view_get_selection (reminders->priv->tree_view);
	gtk_tree_selection_selected_foreach (selection, reminders_widget_gather_selected_cb, &selected);

	g_signal_handlers_block_by_func (reminders->priv->watcher, reminders_widget_watcher_changed_cb, reminders);

	for (link = selected; link; link = g_slist_next (link)) {
		const EReminderData *rd = link->data;

		e_reminder_watcher_snooze (reminders->priv->watcher, rd, until);
	}

	g_slist_free_full (selected, e_reminder_data_free);

	g_signal_handlers_unblock_by_func (reminders->priv->watcher, reminders_widget_watcher_changed_cb, reminders);

	if (selected)
		reminders_widget_watcher_changed_cb (reminders->priv->watcher, reminders);
}

static void
reminders_widget_set_watcher (ERemindersWidget *reminders,
			      EReminderWatcher *watcher)
{
	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));
	g_return_if_fail (E_IS_REMINDER_WATCHER (watcher));
	g_return_if_fail (reminders->priv->watcher == NULL);

	reminders->priv->watcher = g_object_ref (watcher);
}

static void
reminders_widget_set_property (GObject *object,
			       guint property_id,
			       const GValue *value,
			       GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_WATCHER:
			reminders_widget_set_watcher (
				E_REMINDERS_WIDGET (object),
				g_value_get_object (value));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
reminders_widget_get_property (GObject *object,
			       guint property_id,
			       GValue *value,
			       GParamSpec *pspec)
{
	switch (property_id) {
		case PROP_WATCHER:
			g_value_set_object (
				value, e_reminders_widget_get_watcher (
				E_REMINDERS_WIDGET (object)));
			return;

		case PROP_EMPTY:
			g_value_set_boolean (
				value, e_reminders_widget_is_empty (
				E_REMINDERS_WIDGET (object)));
			return;
	}

	G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
}

static void
reminders_widget_constructed (GObject *object)
{
	ERemindersWidget *reminders = E_REMINDERS_WIDGET (object);
	GtkWidget *scrolled_window;
	GtkListStore *list_store;
	GtkTreeSelection *selection;
	GtkTreeViewColumn *column;
	GtkCellRenderer *renderer;
	GtkWidget *widget;
	GtkBox *box;

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_reminders_widget_parent_class)->constructed (object);

	scrolled_window = gtk_scrolled_window_new (NULL, NULL);
	g_object_set (G_OBJECT (scrolled_window),
		"halign", GTK_ALIGN_FILL,
		"hexpand", TRUE,
		"valign", GTK_ALIGN_FILL,
		"vexpand", TRUE,
		"hscrollbar-policy", GTK_POLICY_NEVER,
		"vscrollbar-policy", GTK_POLICY_AUTOMATIC,
		"shadow-type", GTK_SHADOW_IN,
		NULL);

	gtk_grid_attach (GTK_GRID (reminders), scrolled_window, 0, 0, 1, 1);

	list_store = gtk_list_store_new (E_REMINDERS_WIDGET_N_COLUMNS,
		G_TYPE_STRING, /* E_REMINDERS_WIDGET_COLUMN_OVERDUE */
		G_TYPE_STRING, /* E_REMINDERS_WIDGET_COLUMN_DESCRIPTION */
		E_TYPE_REMINDER_DATA); /* E_REMINDERS_WIDGET_COLUMN_REMINDER_DATA */

	reminders->priv->tree_view = GTK_TREE_VIEW (gtk_tree_view_new_with_model (GTK_TREE_MODEL (list_store)));

	g_object_unref (list_store);

	g_object_set (G_OBJECT (reminders->priv->tree_view),
		"halign", GTK_ALIGN_FILL,
		"hexpand", TRUE,
		"valign", GTK_ALIGN_FILL,
		"vexpand", TRUE,
		"activate-on-single-click", FALSE,
		"enable-search", FALSE,
		"fixed-height-mode", TRUE,
		"headers-visible", FALSE,
		"hover-selection", FALSE,
		NULL);

	gtk_container_add (GTK_CONTAINER (scrolled_window), GTK_WIDGET (reminders->priv->tree_view));

	gtk_tree_view_set_tooltip_column (reminders->priv->tree_view, E_REMINDERS_WIDGET_COLUMN_DESCRIPTION);

	/* Headers not visible, thus column's caption is not localized */
	gtk_tree_view_insert_column_with_attributes (reminders->priv->tree_view, -1, "Overdue",
		gtk_cell_renderer_text_new (), "markup", E_REMINDERS_WIDGET_COLUMN_OVERDUE, NULL);

	renderer = gtk_cell_renderer_text_new ();
	g_object_set (G_OBJECT (renderer),
		"ellipsize", PANGO_ELLIPSIZE_END,
		NULL);

	gtk_tree_view_insert_column_with_attributes (reminders->priv->tree_view, -1, "Description",
		renderer, "markup", E_REMINDERS_WIDGET_COLUMN_DESCRIPTION, NULL);

	column = gtk_tree_view_get_column (reminders->priv->tree_view, 0);
	gtk_tree_view_column_set_sizing (column, GTK_TREE_VIEW_COLUMN_GROW_ONLY);

	column = gtk_tree_view_get_column (reminders->priv->tree_view, 1);
	gtk_tree_view_column_set_expand (column, TRUE);

	reminders->priv->dismiss_button = gtk_button_new_with_mnemonic (_("_Dismiss"));
	reminders->priv->dismiss_all_button = gtk_button_new_with_mnemonic (_("Dismiss _All"));
	reminders->priv->snooze_combo = reminders_widget_new_snooze_combo ();
	reminders->priv->snooze_button = gtk_button_new_with_mnemonic (_("_Snooze"));

	reminders_widget_fill_snooze_combo (reminders,
		g_settings_get_int (reminders->priv->settings, "notify-last-snooze-minutes"));

	box = GTK_BOX (gtk_button_box_new (GTK_ORIENTATION_HORIZONTAL));
	g_object_set (G_OBJECT (box),
		"halign", GTK_ALIGN_END,
		"hexpand", TRUE,
		"valign", GTK_ALIGN_CENTER,
		"vexpand", FALSE,
		"margin-top", 4,
		NULL);

	widget = gtk_label_new ("");

	gtk_box_pack_start (box, reminders->priv->snooze_combo, FALSE, FALSE, 0);
	gtk_box_pack_start (box, reminders->priv->snooze_button, FALSE, FALSE, 0);
	gtk_box_pack_start (box, widget, FALSE, FALSE, 0);
	gtk_box_pack_start (box, reminders->priv->dismiss_button, FALSE, FALSE, 0);
	gtk_box_pack_start (box, reminders->priv->dismiss_all_button, FALSE, FALSE, 0);

	gtk_button_box_set_child_non_homogeneous (GTK_BUTTON_BOX (box), reminders->priv->snooze_combo, TRUE);
	gtk_button_box_set_child_non_homogeneous (GTK_BUTTON_BOX (box), widget, TRUE);

	gtk_grid_attach (GTK_GRID (reminders), GTK_WIDGET (box), 0, 1, 1, 1);

	gtk_widget_show_all (GTK_WIDGET (reminders));

	selection = gtk_tree_view_get_selection (reminders->priv->tree_view);
	gtk_tree_selection_set_mode (selection, GTK_SELECTION_MULTIPLE);

	g_signal_connect (reminders->priv->tree_view, "row-activated",
		G_CALLBACK (reminders_widget_row_activated_cb), reminders);

	g_signal_connect (selection, "changed",
		G_CALLBACK (reminders_widget_selection_changed_cb), reminders);

	g_signal_connect (reminders->priv->snooze_button, "clicked",
		G_CALLBACK (reminders_widget_snooze_button_clicked_cb), reminders);

	g_signal_connect (reminders->priv->dismiss_button, "clicked",
		G_CALLBACK (reminders_widget_dismiss_button_clicked_cb), reminders);

	g_signal_connect (reminders->priv->dismiss_all_button, "clicked",
		G_CALLBACK (reminders_widget_dismiss_all_button_clicked_cb), reminders);

	g_signal_connect (reminders->priv->watcher, "changed",
		G_CALLBACK (reminders_widget_watcher_changed_cb), reminders);

	g_signal_connect (reminders->priv->snooze_combo, "changed",
		G_CALLBACK (reminders_widget_snooze_combo_changed_cb), reminders);

	g_signal_connect (reminders->priv->settings, "changed::notify-custom-snooze-minutes",
		G_CALLBACK (reminders_widget_custom_snooze_minutes_changed_cb), reminders);

	e_binding_bind_property (reminders, "empty",
		reminders->priv->dismiss_all_button, "sensitive",
		G_BINDING_SYNC_CREATE | G_BINDING_INVERT_BOOLEAN);

	e_binding_bind_property (reminders, "empty",
		scrolled_window, "sensitive",
		G_BINDING_SYNC_CREATE | G_BINDING_INVERT_BOOLEAN);

	_libedataserverui_load_modules ();

	e_extensible_load_extensions (E_EXTENSIBLE (object));

	reminders_widget_schedule_content_refresh (reminders);
}

static void
reminders_widget_dispose (GObject *object)
{
	ERemindersWidget *reminders = E_REMINDERS_WIDGET (object);

	g_cancellable_cancel (reminders->priv->cancellable);

	if (reminders->priv->refresh_idle_id) {
		g_source_remove (reminders->priv->refresh_idle_id);
		reminders->priv->refresh_idle_id = 0;
	}

	if (reminders->priv->overdue_update_id) {
		g_source_remove (reminders->priv->overdue_update_id);
		reminders->priv->overdue_update_id = 0;
	}

	if (reminders->priv->watcher)
		g_signal_handlers_disconnect_by_data (reminders->priv->watcher, reminders);

	if (reminders->priv->settings)
		g_signal_handlers_disconnect_by_data (reminders->priv->settings, reminders);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_reminders_widget_parent_class)->dispose (object);
}

static void
reminders_widget_finalize (GObject *object)
{
	ERemindersWidget *reminders = E_REMINDERS_WIDGET (object);

	g_clear_object (&reminders->priv->watcher);
	g_clear_object (&reminders->priv->settings);
	g_clear_object (&reminders->priv->cancellable);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_reminders_widget_parent_class)->finalize (object);
}

static void
e_reminders_widget_class_init (ERemindersWidgetClass *klass)
{
	GObjectClass *object_class;
	GtkWidgetClass *widget_class;

	g_type_class_add_private (klass, sizeof (ERemindersWidgetPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->set_property = reminders_widget_set_property;
	object_class->get_property = reminders_widget_get_property;
	object_class->constructed = reminders_widget_constructed;
	object_class->dispose = reminders_widget_dispose;
	object_class->finalize = reminders_widget_finalize;

	widget_class = GTK_WIDGET_CLASS (klass);
	widget_class->map = reminders_widget_map;
	widget_class->unmap = reminders_widget_unmap;

	/**
	 * ERemindersWidget::watcher:
	 *
	 * An #EReminderWatcher used to work with reminders.
	 *
	 * Since: 3.30
	 **/
	g_object_class_install_property (
		object_class,
		PROP_WATCHER,
		g_param_spec_object (
			"watcher",
			"Reminder Watcher",
			"The reminder watcher used to work with reminders",
			E_TYPE_REMINDER_WATCHER,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ERemindersWidget::empty:
	 *
	 * Set to %TRUE when there's no past reminder in the widget.
	 *
	 * Since: 3.30
	 **/
	g_object_class_install_property (
		object_class,
		PROP_EMPTY,
		g_param_spec_boolean (
			"empty",
			"Empty",
			"Whether there are no past reminders",
			TRUE,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	/**
	 * ERemindersWidget:changed:
	 * @reminders: an #ERemindersWidget
	 *
	 * A signal being called to notify about changes in the past reminders list.
	 *
	 * Since: 3.30
	 **/
	signals[CHANGED] = g_signal_new (
		"changed",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET (ERemindersWidgetClass, changed),
		NULL,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_NONE, 0,
		G_TYPE_NONE);

	/**
	 * ERemindersWidget:activated:
	 * @reminders: an #ERemindersWidget
	 * @rd: an #EReminderData
	 *
	 * A signal being called when the user activates one of the past reminders in the tree view.
	 * The @rd corresponds to the activated reminder.
	 *
	 * Returns: %TRUE, when the further processing of this signal should be stopped, %FALSE otherwise.
	 *
	 * Since: 3.30
	 **/
	signals[ACTIVATED] = g_signal_new (
		"activated",
		G_OBJECT_CLASS_TYPE (klass),
		G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		G_STRUCT_OFFSET (ERemindersWidgetClass, activated),
		g_signal_accumulator_first_wins,
		NULL,
		g_cclosure_marshal_generic,
		G_TYPE_BOOLEAN, 1,
		E_TYPE_REMINDER_DATA);
}

static void
e_reminders_widget_init (ERemindersWidget *reminders)
{
	reminders->priv = G_TYPE_INSTANCE_GET_PRIVATE (reminders, E_TYPE_REMINDERS_WIDGET, ERemindersWidgetPrivate);
	reminders->priv->settings = g_settings_new ("org.gnome.evolution-data-server.calendar");
	reminders->priv->cancellable = g_cancellable_new ();
	reminders->priv->is_empty = TRUE;
	reminders->priv->is_mapped = FALSE;
}

/**
 * e_reminders_widget_new:
 * @watcher: an #EReminderWatcher
 *
 * Creates a new instance of #ERemindersWidget. It adds its own reference
 * on the @watcher.
 *
 * Returns: (transfer full): a new instance of #ERemindersWidget.
 *
 * Since: 3.30
 **/
ERemindersWidget *
e_reminders_widget_new (EReminderWatcher *watcher)
{
	g_return_val_if_fail (E_IS_REMINDER_WATCHER (watcher), NULL);

	return g_object_new (E_TYPE_REMINDERS_WIDGET,
		"watcher", watcher,
		NULL);
}

/**
 * e_reminders_widget_get_watcher:
 * @reminders: an #ERemindersWidget
 *
 * Returns: (transfer none): an #EReminderWatcher with which the @reminders had
 *    been created. Do on unref it, it's owned by the @reminders.
 *
 * Since: 3.30
 **/
EReminderWatcher *
e_reminders_widget_get_watcher (ERemindersWidget *reminders)
{
	g_return_val_if_fail (E_IS_REMINDERS_WIDGET (reminders), NULL);

	return reminders->priv->watcher;
}

/**
 * e_reminders_widget_get_settings:
 * @reminders: an #ERemindersWidget
 *
 * Returns: (transfer none): a #GSettings pointing to org.gnome.evolution-data-server.calendar
 *    used by the @reminders widget.
 *
 * Since: 3.30
 **/
GSettings *
e_reminders_widget_get_settings (ERemindersWidget *reminders)
{
	g_return_val_if_fail (E_IS_REMINDERS_WIDGET (reminders), NULL);

	return reminders->priv->settings;
}

/**
 * e_reminders_widget_is_empty:
 * @reminders: an #ERemindersWidget
 *
 * Returns: %TRUE, when there is no past reminder left, %FALSE otherwise.
 *
 * Since: 3.30
 **/
gboolean
e_reminders_widget_is_empty (ERemindersWidget *reminders)
{
	g_return_val_if_fail (E_IS_REMINDERS_WIDGET (reminders), FALSE);

	return reminders->priv->is_empty;
}

/**
 * e_reminders_widget_get_tree_view:
 * @reminders: an #ERemindersWidget
 *
 * Returns: (transfer none): a #GtkTreeView with past reminders. It's owned
 *    by the @reminders widget.
 *
 * Since: 3.30
 **/
GtkTreeView *
e_reminders_widget_get_tree_view (ERemindersWidget *reminders)
{
	g_return_val_if_fail (E_IS_REMINDERS_WIDGET (reminders), NULL);

	return reminders->priv->tree_view;
}

static void
reminders_widget_error_response_cb (GtkInfoBar *info_bar,
				    gint response_id,
				    gpointer user_data)
{
	ERemindersWidget *reminders = user_data;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (reminders->priv->info_bar == info_bar) {
		gtk_widget_destroy (GTK_WIDGET (reminders->priv->info_bar));
		reminders->priv->info_bar = NULL;
	}
}

/**
 * e_reminders_widget_report_error:
 * @reminders: an #ERemindersWidget
 * @prefix: (nullable): an optional prefix to show before the error message, or %NULL for none
 * @error: (nullable): a #GError to show the message from in the UI, or %NULL for unknown error
 *
 * Shows a warning in the GUI with the @error message, optionally prefixed
 * with @prefix. When @error is %NULL, an "Unknown error" message is shown
 * instead.
 *
 * Since: 3.30
 **/
void
e_reminders_widget_report_error (ERemindersWidget *reminders,
				 const gchar *prefix,
				 const GError *error)
{
	GtkLabel *label;
	const gchar *message;
	gchar *tmp = NULL;

	g_return_if_fail (E_IS_REMINDERS_WIDGET (reminders));

	if (error)
		message = error->message;
	else
		message = _("Unknown error");

	if (prefix && *prefix) {
		if (gtk_widget_get_direction (GTK_WIDGET (reminders)) == GTK_TEXT_DIR_RTL)
			tmp = g_strconcat (message, " ", prefix, NULL);
		else
			tmp = g_strconcat (prefix, " ", message, NULL);

		message = tmp;
	}

	if (reminders->priv->info_bar) {
		gtk_widget_destroy (GTK_WIDGET (reminders->priv->info_bar));
		reminders->priv->info_bar = NULL;
	}

	reminders->priv->info_bar = GTK_INFO_BAR (gtk_info_bar_new ());
	gtk_info_bar_set_message_type (reminders->priv->info_bar, GTK_MESSAGE_ERROR);
	gtk_info_bar_set_show_close_button (reminders->priv->info_bar, TRUE);

	label = GTK_LABEL (gtk_label_new (message));
	gtk_label_set_max_width_chars (label, 120);
	gtk_label_set_line_wrap (label, TRUE);
	gtk_label_set_selectable (label, TRUE);
	gtk_container_add (GTK_CONTAINER (gtk_info_bar_get_content_area (reminders->priv->info_bar)), GTK_WIDGET (label));
	gtk_widget_show (GTK_WIDGET (label));
	gtk_widget_show (GTK_WIDGET (reminders->priv->info_bar));

	g_signal_connect (reminders->priv->info_bar, "response", G_CALLBACK (reminders_widget_error_response_cb), reminders);

	gtk_grid_attach (GTK_GRID (reminders), GTK_WIDGET (reminders->priv->info_bar), 0, 2, 1, 1);

	g_free (tmp);
}
