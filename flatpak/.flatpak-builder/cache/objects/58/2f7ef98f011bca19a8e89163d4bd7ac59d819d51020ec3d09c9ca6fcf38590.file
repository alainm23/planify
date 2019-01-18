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

#include "evolution-data-server-config.h"

#include <time.h>

#ifdef HAVE_CANBERRA
#include <canberra-gtk.h>
#endif

#include <glib/gi18n-lib.h>

#ifndef G_OS_WIN32
#include <gio/gdesktopappinfo.h>
#endif

#include "libecal/libecal.h"
#include "libedataserverui/libedataserverui.h"

#include "e-alarm-notify.h"

#ifdef DBUS_SERVICES_PREFIX
#define APPLICATION_ID DBUS_SERVICES_PREFIX "." "org.gnome.Evolution-alarm-notify"
#else
#define APPLICATION_ID "org.gnome.Evolution-alarm-notify"
#endif

struct _EAlarmNotifyPrivate {
	ESourceRegistry *registry;
	EReminderWatcher *watcher;
	GSettings *settings;

	ERemindersWidget *reminders; /* owned by 'window' */
	GtkWidget *window;
	gint window_x;
	gint window_y;
	gint window_width;
	gint window_height;
	gint window_geometry_save_id;

	GMutex dismiss_lock;
	GSList *dismiss; /* EReminderData * */
	GThread *dismiss_thread; /* not referenced, only to know whether it's scheduled */

	GHashTable *notification_ids; /* gchar * ~> NULL, known notifications */
	GtkStatusIcon *status_icon;
	gchar *status_icon_tooltip;
	gint status_icon_blink_id;
	gint status_icon_blink_countdown;
	gint last_n_reminders;
};

/* Forward Declarations */
static void	e_alarm_notify_initable_init	(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (EAlarmNotify, e_alarm_notify, GTK_TYPE_APPLICATION,
	G_IMPLEMENT_INTERFACE (G_TYPE_INITABLE, e_alarm_notify_initable_init))

static void
e_alarm_notify_show_window (EAlarmNotify *an,
			    gboolean focus_on_map)
{
	GtkWindow *window;
	gboolean was_visible;

	g_return_if_fail (E_IS_ALARM_NOTIFY (an));

	window = GTK_WINDOW (an->priv->window);

	gtk_window_set_keep_above (window, g_settings_get_boolean (an->priv->settings, "notify-window-on-top"));
	gtk_window_set_focus_on_map (window, focus_on_map);
	gtk_window_set_urgency_hint (window, !focus_on_map);

	was_visible = gtk_widget_get_visible (an->priv->window);

	gtk_window_present (window);

	if (!was_visible)
		gtk_window_move (window, an->priv->window_x, an->priv->window_y);
}

static gboolean
e_alarm_notify_audio (EAlarmNotify *an,
		      const EReminderData *rd,
		      ECalComponentAlarm *alarm)
{
	icalattach *attach = NULL;
	gboolean did_play = FALSE;

	g_return_val_if_fail (an != NULL, FALSE);
	g_return_val_if_fail (rd != NULL, FALSE);
	g_return_val_if_fail (alarm != NULL, FALSE);

	e_cal_component_alarm_get_attach (alarm, &attach);

	if (attach && icalattach_get_is_url (attach)) {
		const gchar *url;

		url = icalattach_get_url (attach);
		if (url && *url) {
			gchar *filename;
			GError *error = NULL;

			filename = g_filename_from_uri (url, NULL, &error);

			if (error != NULL) {
				g_warning ("%s: Failed to convert URI to filename: %s", G_STRFUNC, error->message);
				g_error_free (error);
			} else if (filename && g_file_test (filename, G_FILE_TEST_EXISTS)) {
#ifdef HAVE_CANBERRA
				did_play = ca_context_play (ca_gtk_context_get (), 0,
					CA_PROP_MEDIA_FILENAME, filename,
					NULL) == 0;
#endif
			}

			g_free (filename);
		}
	}

	if (!did_play)
		gdk_beep ();

	if (attach)
		icalattach_unref (attach);

	return FALSE;
}

/* Copy of e_util_is_running_gnome() from Evolution */
static gboolean
e_alarm_notify_is_running_gnome (void)
{
#ifdef G_OS_WIN32
	return FALSE;
#else
	static gint runs_gnome = -1;

	if (runs_gnome == -1) {
		runs_gnome = g_strcmp0 (g_getenv ("XDG_CURRENT_DESKTOP"), "GNOME") == 0 ? 1 : 0;
		if (runs_gnome) {
			GDesktopAppInfo *app_info;

			app_info = g_desktop_app_info_new ("gnome-notifications-panel.desktop");
			if (!app_info) {
				runs_gnome = 0;
			}

			g_clear_object (&app_info);
		}
	}

	return runs_gnome != 0;
#endif
}

static gchar *
e_alarm_notify_build_notif_id (const EReminderData *rd)
{
	GString *string;
	ECalComponentId *id;

	g_return_val_if_fail (rd != NULL, NULL);

	string = g_string_sized_new (32);

	if (rd->source_uid) {
		g_string_append (string, rd->source_uid);
		g_string_append (string, "\n");
	}

	id = e_cal_component_get_id (rd->component);
	if (id) {
		if (id->uid) {
			g_string_append (string, id->uid);
			g_string_append (string, "\n");
		}

		if (id->rid) {
			g_string_append (string, id->rid);
			g_string_append (string, "\n");
		}

		e_cal_component_free_id (id);
	}

	g_string_append_printf (string, "%" G_GINT64_FORMAT, (gint64) rd->instance.trigger);

	return g_string_free (string, FALSE);
}

static gboolean
e_alarm_notify_display (EAlarmNotify *an,
			const EReminderData *rd,
			ECalComponentAlarm *alarm)
{
	gchar *description, *notif_id;

	g_return_val_if_fail (an != NULL, FALSE);
	g_return_val_if_fail (rd != NULL, FALSE);
	g_return_val_if_fail (alarm != NULL, FALSE);

	description = e_reminder_watcher_describe_data (an->priv->watcher, rd, E_REMINDER_WATCHER_DESCRIBE_FLAG_NONE);

	notif_id = e_alarm_notify_build_notif_id (rd);

	if (!g_hash_table_contains (an->priv->notification_ids, notif_id)) {
		GNotification *notification;
		GtkIconInfo *icon_info;
		gchar *detailed_action;

		notification = g_notification_new (_("Reminders"));
		g_notification_set_body (notification, description);

		icon_info = gtk_icon_theme_lookup_icon (gtk_icon_theme_get_default (), "appointment-soon", 48, 0);
		if (icon_info) {
			const gchar *filename;

			filename = gtk_icon_info_get_filename (icon_info);
			if (filename && *filename) {
				GFile *file;
				GIcon *icon;

				file = g_file_new_for_path (filename);
				icon = g_file_icon_new (file);

				if (icon) {
					g_notification_set_icon (notification, icon);
					g_object_unref (icon);
				}

				g_object_unref (file);
			}

			gtk_icon_info_free (icon_info);
		}

		detailed_action = g_action_print_detailed_name ("app.show-reminders", NULL);
		g_notification_set_default_action (notification, detailed_action);
		g_notification_add_button (notification, _("Reminders"), detailed_action);
		g_free (detailed_action);

		g_application_send_notification (G_APPLICATION (an), notif_id, notification);

		g_object_unref (notification);

		g_hash_table_insert (an->priv->notification_ids, notif_id, NULL);
	}

	g_free (an->priv->status_icon_tooltip);
	an->priv->status_icon_tooltip = description; /* takes ownership */

	if (!g_settings_get_boolean (an->priv->settings, "notify-with-tray"))
		e_alarm_notify_show_window (an, FALSE);

	return TRUE;
}

static gboolean
e_alarm_notify_email (EAlarmNotify *an,
		      const EReminderData *rd,
		      ECalComponentAlarm *alarm)
{
	ECalClient *client;

	g_return_val_if_fail (an != NULL, FALSE);
	g_return_val_if_fail (rd != NULL, FALSE);
	g_return_val_if_fail (alarm != NULL, FALSE);

	client = e_reminder_watcher_ref_opened_client (an->priv->watcher, rd->source_uid);
	if (client && !e_client_check_capability (E_CLIENT (client), CAL_STATIC_CAPABILITY_NO_EMAIL_ALARMS)) {
		g_object_unref (client);
		return FALSE;
	}

	g_clear_object (&client);

	/* Do not know how to send an email from here, but an application can write an extension
	   of E_TYPE_REMINDERS_WIDGET, listen for EReminderWatcher::triggered signal and do what
	   is required from that handler. */

	return FALSE;
}

static gboolean
e_alarm_notify_is_blessed_program (GSettings *settings,
				   const gchar *url)
{
	gchar **list;
	gint ii;
	gboolean found = FALSE;

	g_return_val_if_fail (G_IS_SETTINGS (settings), FALSE);
	g_return_val_if_fail (url != NULL, FALSE);

	list = g_settings_get_strv (settings, "notify-programs");

	for (ii = 0; list && list[ii] && !found; ii++) {
		found = g_strcmp0 (list[ii], url) == 0;
	}

	g_strfreev (list);

	return found;
}

static void
e_alarm_notify_save_blessed_program (GSettings *settings,
				     const gchar *url)
{
	gchar **list;
	gint ii;
	GPtrArray *array;

	g_return_if_fail (G_IS_SETTINGS (settings));
	g_return_if_fail (url != NULL);

	array = g_ptr_array_new ();

	list = g_settings_get_strv (settings, "notify-programs");

	for (ii = 0; list && list[ii]; ii++) {
		if (g_strcmp0 (url, list[ii]) != 0)
			g_ptr_array_add (array, list[ii]);
	}

	g_ptr_array_add (array, (gpointer) url);
	g_ptr_array_add (array, NULL);

	g_settings_set_strv (settings, "notify-programs", (const gchar * const *) array->pdata);

	g_ptr_array_free (array, TRUE);
	g_strfreev (list);
}

static gboolean
e_alarm_notify_can_procedure (EAlarmNotify *an,
			      const gchar *cmd,
			      const gchar *url)
{
	GtkWidget *container;
	GtkWidget *dialog;
	GtkWidget *label;
	GtkWidget *checkbox;
	gchar *str;
	gint response;

	if (e_alarm_notify_is_blessed_program (an->priv->settings, url))
		return TRUE;

	dialog = gtk_dialog_new_with_buttons (
		_("Warning"), GTK_WINDOW (an->priv->window), 0,
		_("_No"), GTK_RESPONSE_CANCEL,
		_("_Yes"), GTK_RESPONSE_OK,
		NULL);

	str = g_strdup_printf (
		_("A calendar reminder is about to trigger. "
		"This reminder is configured to run the following program:\n\n"
		"        %s\n\n"
		"Are you sure you want to run this program?"),
		cmd);
	label = gtk_label_new (str);
	gtk_label_set_line_wrap (GTK_LABEL (label), TRUE);
	gtk_label_set_justify (GTK_LABEL (label), GTK_JUSTIFY_LEFT);
	gtk_widget_show (label);

	container = gtk_dialog_get_content_area (GTK_DIALOG (dialog));
	gtk_box_pack_start (GTK_BOX (container), label, TRUE, TRUE, 4);
	g_free (str);

	checkbox = gtk_check_button_new_with_label (_("Do not ask me about this program again"));
	gtk_widget_show (checkbox);
	gtk_box_pack_start (GTK_BOX (container), checkbox, TRUE, TRUE, 4);

	response = gtk_dialog_run (GTK_DIALOG (dialog));

	if (response == GTK_RESPONSE_OK &&
	    gtk_toggle_button_get_active (GTK_TOGGLE_BUTTON (checkbox))) {
		e_alarm_notify_save_blessed_program (an->priv->settings, url);
	}

	gtk_widget_destroy (dialog);

	return response == GTK_RESPONSE_OK;
}

static gboolean
e_alarm_notify_procedure (EAlarmNotify *an,
			  const EReminderData *rd,
			  ECalComponentAlarm *alarm)
{
	ECalComponentText description;
	icalattach *attach;
	const gchar *url;
	gchar *cmd;
	gboolean result = FALSE;

	g_return_val_if_fail (an != NULL, FALSE);
	g_return_val_if_fail (rd != NULL, FALSE);
	g_return_val_if_fail (alarm != NULL, FALSE);

	e_cal_component_alarm_get_attach (alarm, &attach);
	e_cal_component_alarm_get_description (alarm, &description);

	/* If the alarm has no attachment, simply display a notification dialog. */
	if (!attach)
		goto fallback;

	if (!icalattach_get_is_url (attach)) {
		icalattach_unref (attach);
		goto fallback;
	}

	url = icalattach_get_url (attach);
	g_return_val_if_fail (url != NULL, FALSE);

	/* Ask for confirmation before executing the stuff */
	if (description.value)
		cmd = g_strconcat (url, " ", description.value, NULL);
	else
		cmd = (gchar *) url;

	if (e_alarm_notify_can_procedure (an, cmd, url))
		result = g_spawn_command_line_async (cmd, NULL);

	if (cmd != (gchar *) url)
		g_free (cmd);

	icalattach_unref (attach);

	/* Fall back to display notification if we got an error */
	if (!result)
		goto fallback;

	return FALSE;

 fallback:
	return e_alarm_notify_display (an, rd, alarm);
}

/* Returns %TRUE to keep in ERemindersWidget */
static gboolean
e_alarm_notify_process (EAlarmNotify *an,
			const EReminderData *rd,
			gboolean snoozed)
{
	ECalComponentAlarm *alarm;
	ECalComponentAlarmAction action;
	gboolean keep_in_reminders = FALSE;

	g_return_val_if_fail (an != NULL, FALSE);
	g_return_val_if_fail (rd != NULL, FALSE);

	if (e_cal_component_get_vtype (rd->component) == E_CAL_COMPONENT_TODO) {
		icalproperty_status status = ICAL_STATUS_NONE;

		e_cal_component_get_status (rd->component, &status);

		if (status == ICAL_STATUS_COMPLETED &&
		    !g_settings_get_boolean (an->priv->settings, "notify-completed-tasks")) {
			return FALSE;
		}
	}

	alarm = e_cal_component_get_alarm (rd->component, rd->instance.auid);
	if (!alarm)
		return FALSE;

	if (!snoozed && !g_settings_get_boolean (an->priv->settings, "notify-past-events")) {
		ECalComponentAlarmTrigger trigger;
		ECalComponentAlarmRepeat repeat;
		time_t offset = 0, event_relative, orig_trigger_day, today;

		e_cal_component_alarm_get_trigger (alarm, &trigger);
		e_cal_component_alarm_get_repeat (alarm, &repeat);

		switch (trigger.type) {
		case E_CAL_COMPONENT_ALARM_TRIGGER_NONE:
		case E_CAL_COMPONENT_ALARM_TRIGGER_ABSOLUTE:
			break;

		case E_CAL_COMPONENT_ALARM_TRIGGER_RELATIVE_START:
		case E_CAL_COMPONENT_ALARM_TRIGGER_RELATIVE_END:
			offset = icaldurationtype_as_int (trigger.u.rel_duration);
			break;

		default:
			break;
		}

		today = time (NULL);
		event_relative = rd->instance.occur_start - offset;

		#define CLAMP_TO_DAY(x) ((x) - ((x) % (60 * 60 * 24)))

		event_relative = CLAMP_TO_DAY (event_relative);
		orig_trigger_day = CLAMP_TO_DAY (rd->instance.trigger);
		today = CLAMP_TO_DAY (today);

		#undef CLAMP_TO_DAY

		if (event_relative < today && orig_trigger_day < today) {
			e_cal_component_alarm_free (alarm);
			return FALSE;
		}
	}

	e_cal_component_alarm_get_action (alarm, &action);

	switch (action) {
	case E_CAL_COMPONENT_ALARM_AUDIO:
		keep_in_reminders = e_alarm_notify_audio (an, rd, alarm);
		break;

	case E_CAL_COMPONENT_ALARM_DISPLAY:
		keep_in_reminders = e_alarm_notify_display (an, rd, alarm);
		break;

	case E_CAL_COMPONENT_ALARM_EMAIL:
		keep_in_reminders = e_alarm_notify_email (an, rd, alarm);
		break;

	case E_CAL_COMPONENT_ALARM_PROCEDURE:
		keep_in_reminders = e_alarm_notify_procedure (an, rd, alarm);
		break;

	case E_CAL_COMPONENT_ALARM_NONE:
	case E_CAL_COMPONENT_ALARM_UNKNOWN:
		break;
	}

	e_cal_component_alarm_free (alarm);

	return keep_in_reminders;
}

static gpointer
e_alarm_notify_dismiss_thread (gpointer user_data)
{
	EAlarmNotify *an = user_data;
	GSList *dismiss, *link;

	g_return_val_if_fail (E_IS_ALARM_NOTIFY (an), NULL);

	g_mutex_lock (&an->priv->dismiss_lock);
	dismiss = an->priv->dismiss;
	an->priv->dismiss = NULL;
	an->priv->dismiss_thread = NULL;
	g_mutex_unlock (&an->priv->dismiss_lock);

	if (an->priv->watcher) {
		for (link = dismiss; link; link = g_slist_next (link)) {
			EReminderData *rd = link->data;

			if (rd) {
				/* Silently ignore any errors here */
				e_reminder_watcher_dismiss_sync (an->priv->watcher, rd, NULL, NULL);
			}
		}
	}

	g_slist_free_full (dismiss, e_reminder_data_free);
	g_clear_object (&an);

	return NULL;
}

static void
e_alarm_notify_triggered_cb (EReminderWatcher *watcher,
			     const GSList *reminders, /* EReminderData * */
			     gboolean snoozed,
			     gpointer user_data)
{
	EAlarmNotify *an = user_data;
	GSList *link;

	g_return_if_fail (E_IS_ALARM_NOTIFY (an));

	g_mutex_lock (&an->priv->dismiss_lock);

	for (link = (GSList *) reminders; link; link = g_slist_next (link)) {
		const EReminderData *rd = link->data;

		if (rd && !e_alarm_notify_process (an, rd, snoozed)) {
			an->priv->dismiss = g_slist_prepend (an->priv->dismiss, e_reminder_data_copy (rd));
		}
	}

	if (an->priv->dismiss && !an->priv->dismiss_thread) {
		an->priv->dismiss_thread = g_thread_new (NULL, e_alarm_notify_dismiss_thread, g_object_ref (an));
		g_warn_if_fail (an->priv->dismiss_thread != NULL);
		if (an->priv->dismiss_thread)
			g_thread_unref (an->priv->dismiss_thread);
	}

	g_mutex_unlock (&an->priv->dismiss_lock);
}

static void
e_alarm_notify_status_icon_activated_cb (GtkStatusIcon *status_icon,
				         gpointer user_data)
{
	EAlarmNotify *an = user_data;

	g_return_if_fail (E_IS_ALARM_NOTIFY (an));

	if (gtk_widget_get_visible (an->priv->window))
		gtk_widget_set_visible (an->priv->window, FALSE);
	else
		e_alarm_notify_show_window (an, TRUE);

	if (an->priv->status_icon_blink_id > 0) {
		g_source_remove (an->priv->status_icon_blink_id);
		an->priv->status_icon_blink_id = -1;

		if (an->priv->status_icon)
			gtk_status_icon_set_from_icon_name (an->priv->status_icon, "appointment-soon");
	}
}

static gboolean
e_alarm_notify_popup_destroy_idle_cb (gpointer user_data)
{
	GtkWidget *widget = user_data;

	g_return_val_if_fail (GTK_IS_WIDGET (widget), FALSE);

	gtk_widget_destroy (widget);

	return FALSE;
}

static void
e_alarm_notify_schedule_popup_destroy (GtkWidget *widget)
{
	g_idle_add_full (G_PRIORITY_LOW, e_alarm_notify_popup_destroy_idle_cb, widget, NULL);
}

static void
e_alarm_notify_status_icon_popup_menu_cb (GtkStatusIcon *status_icon,
					  guint button,
					  guint activate_time,
					  gpointer user_data)
{
	struct _items {
		const gchar *label;
		const gchar *opt_name;
	} items[] = {
		{ N_("Display reminders in notification area _only"), "notify-with-tray" },
		{ N_("Keep reminder notification window always on _top"), "notify-window-on-top" },
		{ N_("Display reminders for _completed tasks"), "notify-completed-tasks" },
		{ N_("Display reminders for _past events"), "notify-past-events" }
	};

	EAlarmNotify *an = user_data;
	GtkWidget *popup_menu;
	GtkMenuShell *menu_shell;
	GtkWidget *item;
	gint ii;

	g_return_if_fail (E_IS_ALARM_NOTIFY (an));

	popup_menu = gtk_menu_new ();
	menu_shell = GTK_MENU_SHELL (popup_menu);

	item = gtk_menu_item_new_with_label (_("Reminders Options:"));
	gtk_widget_set_sensitive (item, FALSE);
	gtk_menu_shell_append (menu_shell, item);

	item = gtk_separator_menu_item_new ();
	gtk_menu_shell_append (menu_shell, item);

	for (ii = 0; ii < G_N_ELEMENTS (items); ii++) {
		item = gtk_check_menu_item_new_with_mnemonic (_(items[ii].label));
		gtk_menu_shell_append (menu_shell, item);

		g_settings_bind (an->priv->settings, items[ii].opt_name,
			item, "active",
			G_SETTINGS_BIND_DEFAULT);
	}

	g_signal_connect (popup_menu, "deactivate", G_CALLBACK (e_alarm_notify_schedule_popup_destroy), NULL);

	gtk_widget_show_all (popup_menu);

	gtk_menu_popup (GTK_MENU (popup_menu), NULL, NULL, NULL, NULL, button, activate_time);
}

static gboolean
e_alarm_notify_status_icon_blink_cb (gpointer user_data)
{
	EAlarmNotify *an = user_data;
	const gchar *icon_name;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_ALARM_NOTIFY (an), FALSE);

	an->priv->status_icon_blink_countdown--;

	if (!(an->priv->status_icon_blink_countdown & 1) && an->priv->status_icon_blink_countdown > 0)
		icon_name = "appointment-missed";
	else
		icon_name = "appointment-soon";

	if (an->priv->status_icon)
		gtk_status_icon_set_from_icon_name (an->priv->status_icon, icon_name);

	if (an->priv->status_icon_blink_countdown <= 0 || !an->priv->status_icon)
		an->priv->status_icon_blink_id = -1;

	return an->priv->status_icon_blink_id != -1;
}

static void
e_alarm_notify_reminders_changed_cb (ERemindersWidget *reminders,
				     gpointer user_data)
{
	EAlarmNotify *an = user_data;
	GtkTreeView *tree_view;
	gint n_reminders = 0;

	g_return_if_fail (E_IS_ALARM_NOTIFY (an));

	tree_view = e_reminders_widget_get_tree_view (an->priv->reminders);
	if (tree_view) {
		GtkTreeModel *model;

		model = gtk_tree_view_get_model (tree_view);
		n_reminders = gtk_tree_model_iter_n_children (model, NULL);
	}

	/* This is to update tray icon only, which is not used in GNOME */
	if (!e_alarm_notify_is_running_gnome ()) {
		if (n_reminders <= 0) {
			if (an->priv->status_icon) {
				gtk_status_icon_set_visible (an->priv->status_icon, FALSE);
				g_clear_object (&an->priv->status_icon);
			}
		} else {
			if (!an->priv->status_icon) {
				an->priv->status_icon = gtk_status_icon_new ();
				gtk_status_icon_set_title (an->priv->status_icon, _("Reminders"));
				gtk_status_icon_set_from_icon_name (an->priv->status_icon, "appointment-soon");

				g_signal_connect (an->priv->status_icon, "activate",
					G_CALLBACK (e_alarm_notify_status_icon_activated_cb), an);

				g_signal_connect (an->priv->status_icon, "popup-menu",
					G_CALLBACK (e_alarm_notify_status_icon_popup_menu_cb), an);
			}

			if (n_reminders == 1 && an->priv->status_icon_tooltip) {
				gtk_status_icon_set_tooltip_text (an->priv->status_icon, an->priv->status_icon_tooltip);
			} else {
				gchar *str;

				str = g_strdup_printf (g_dngettext (GETTEXT_PACKAGE,
					"You have %d reminder", "You have %d reminders",
					n_reminders), n_reminders);
				gtk_status_icon_set_tooltip_text (an->priv->status_icon, str);
				g_free (str);
			}

			gtk_status_icon_set_visible (an->priv->status_icon, TRUE);

			if (an->priv->status_icon_blink_id <= 0 &&
			    an->priv->last_n_reminders < n_reminders) {
				an->priv->status_icon_blink_countdown = 30;
				an->priv->status_icon_blink_id = e_named_timeout_add (500, e_alarm_notify_status_icon_blink_cb, an);
			}
		}
	}

	an->priv->last_n_reminders = n_reminders;

	g_clear_pointer (&an->priv->status_icon_tooltip, g_free);

	if (n_reminders <= 0 && an->priv->window)
		gtk_widget_set_visible (an->priv->window, FALSE);

	/* If any reminders were snoozed or dismissed remove their notifications as well */
	if (g_hash_table_size (an->priv->notification_ids)) {
		GHashTable *notification_ids;

		notification_ids = an->priv->notification_ids;
		an->priv->notification_ids = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);

		if (n_reminders > 0) {
			GSList *past, *link;

			past = e_reminder_watcher_dup_past (an->priv->watcher);
			for (link = past; link; link = g_slist_next (link)) {
				EReminderData *rd = link->data;
				gchar *notif_id;

				if (!rd)
					continue;

				notif_id = e_alarm_notify_build_notif_id (rd);
				if (g_hash_table_remove (notification_ids, notif_id))
					g_hash_table_insert (an->priv->notification_ids, notif_id, NULL);
				else
					g_free (notif_id);
			}

			g_slist_free_full (past, e_reminder_data_free);
		}

		if (g_hash_table_size (notification_ids)) {
			GApplication *application = G_APPLICATION (an);
			GHashTableIter iter;
			gpointer key;

			g_hash_table_iter_init (&iter, notification_ids);
			while (g_hash_table_iter_next (&iter, &key, NULL)) {
				const gchar *notif_id = key;

				if (notif_id)
					g_application_withdraw_notification (application, notif_id);
			}
		}

		g_hash_table_destroy (notification_ids);
	}
}

static gboolean
e_alarm_notify_window_geometry_save_cb (gpointer user_data)
{
	EAlarmNotify *an = user_data;

	if (g_source_is_destroyed (g_main_current_source ()))
		return FALSE;

	g_return_val_if_fail (E_IS_ALARM_NOTIFY (an), FALSE);

	an->priv->window_geometry_save_id = 0;

	if (an->priv->settings) {
		#define set_if_changed(_name, _value) G_STMT_START { \
			if (g_settings_get_int (an->priv->settings, _name) != _value) \
				g_settings_set_int (an->priv->settings, _name, _value); \
			} G_STMT_END

		set_if_changed ("notify-window-x", an->priv->window_x);
		set_if_changed ("notify-window-y", an->priv->window_y);
		set_if_changed ("notify-window-width", an->priv->window_width);
		set_if_changed ("notify-window-height", an->priv->window_height);

		#undef set_if_changed
	}

	return FALSE;
}

static gboolean
e_alarm_notify_window_configure_event_cb (GtkWidget *widget,
					  GdkEvent *event,
					  gpointer user_data)
{
	EAlarmNotify *an = user_data;

	g_return_val_if_fail (E_IS_ALARM_NOTIFY (an), FALSE);

	if (an->priv->window && an->priv->settings && gtk_widget_get_visible (an->priv->window)) {
		gint pos_x = an->priv->window_x, pos_y = an->priv->window_y;
		gint width = an->priv->window_width, height = an->priv->window_height;

		gtk_window_get_position (GTK_WINDOW (an->priv->window), &pos_x, &pos_y);
		gtk_window_get_size (GTK_WINDOW (an->priv->window), &width, &height);

		if (pos_x != an->priv->window_x || pos_y != an->priv->window_y ||
		    width != an->priv->window_width || height != an->priv->window_height) {
			an->priv->window_x = pos_x;
			an->priv->window_y = pos_y;
			an->priv->window_width = width;
			an->priv->window_height = height;

			if (an->priv->window_geometry_save_id > 0)
				g_source_remove (an->priv->window_geometry_save_id);

			an->priv->window_geometry_save_id = e_named_timeout_add_seconds (1,
				e_alarm_notify_window_geometry_save_cb, an);
		}
	}

	return FALSE;
}

static void
e_alarm_notify_action_activate_cb (GSimpleAction *action,
				   GVariant *parameter,
				   gpointer user_data)
{
	EAlarmNotify *an = user_data;
	const gchar *name;

	g_return_if_fail (G_IS_ACTION (action));
	g_return_if_fail (E_IS_ALARM_NOTIFY (an));

	name = g_action_get_name (G_ACTION (action));
	g_return_if_fail (name != NULL);

	if (g_str_equal (name, "show-reminders")) {
		e_alarm_notify_show_window (an, TRUE);
	} else {
		g_warning ("%s: Unknown app. action '%s'", G_STRFUNC, name);
	}
}

static void
e_alarm_notify_startup (GApplication *application)
{
	const GActionEntry actions[] = {
		{ "show-reminders", e_alarm_notify_action_activate_cb, NULL, NULL, NULL }
	};

	/* Chain up to parent's method. */
	G_APPLICATION_CLASS (e_alarm_notify_parent_class)->startup (application);

	/* Keep the application running. */
	g_application_hold (application);

	g_action_map_add_action_entries (G_ACTION_MAP (application), actions, G_N_ELEMENTS (actions), application);
}

static void
e_alarm_notify_activate (GApplication *application)
{
	EAlarmNotify *an = E_ALARM_NOTIFY (application);

	if (g_application_get_is_remote (application)) {
		g_application_quit (application);
		return;
	}

	g_return_if_fail (an->priv->registry != NULL);

	an->priv->watcher = e_reminder_watcher_new (an->priv->registry);
	an->priv->reminders = e_reminders_widget_new (an->priv->watcher);
	an->priv->settings = g_object_ref (e_reminders_widget_get_settings (an->priv->reminders));

	g_object_set (G_OBJECT (an->priv->reminders),
		"halign", GTK_ALIGN_FILL,
		"hexpand", TRUE,
		"valign", GTK_ALIGN_FILL,
		"vexpand", TRUE,
		NULL);

	an->priv->window = gtk_application_window_new (GTK_APPLICATION (an));
	gtk_window_set_title (GTK_WINDOW (an->priv->window), _("Reminders"));
	gtk_window_set_icon_name (GTK_WINDOW (an->priv->window), "appointment-soon");
	gtk_window_set_default_size (GTK_WINDOW (an->priv->window),
		g_settings_get_int (an->priv->settings, "notify-window-width"),
		g_settings_get_int (an->priv->settings, "notify-window-height"));
	an->priv->window_x = g_settings_get_int (an->priv->settings, "notify-window-x");
	an->priv->window_y = g_settings_get_int (an->priv->settings, "notify-window-y");

	gtk_container_add (GTK_CONTAINER (an->priv->window), GTK_WIDGET (an->priv->reminders));

	gtk_window_set_keep_above (GTK_WINDOW (an->priv->window), g_settings_get_boolean (an->priv->settings, "notify-window-on-top"));

	g_signal_connect (an->priv->watcher, "triggered",
		G_CALLBACK (e_alarm_notify_triggered_cb), an);

	g_signal_connect (an->priv->reminders, "changed",
		G_CALLBACK (e_alarm_notify_reminders_changed_cb), an);

	g_signal_connect (an->priv->window, "configure-event",
		G_CALLBACK (e_alarm_notify_window_configure_event_cb), an);

	g_signal_connect (an->priv->window, "delete-event",
		G_CALLBACK (gtk_widget_hide_on_delete), an);
}

static gboolean
e_alarm_notify_initable (GInitable *initable,
			 GCancellable *cancellable,
			 GError **error)
{
	EAlarmNotify *an = E_ALARM_NOTIFY (initable);

	an->priv->registry = e_source_registry_new_sync (cancellable, error);

	return an->priv->registry != NULL;
}

static void
e_alarm_notify_dispose (GObject *object)
{
	EAlarmNotify *an = E_ALARM_NOTIFY (object);

	if (an->priv->watcher)
		g_signal_handlers_disconnect_by_data (an->priv->watcher, an);

	if (an->priv->reminders)
		g_signal_handlers_disconnect_by_data (an->priv->reminders, an);

	if (an->priv->status_icon_blink_id > 0) {
		g_source_remove (an->priv->status_icon_blink_id);
		an->priv->status_icon_blink_id = -1;
	}

	if (an->priv->window_geometry_save_id > 0) {
		g_source_remove (an->priv->window_geometry_save_id);
		an->priv->window_geometry_save_id = 0;
	}

	if (an->priv->status_icon) {
		gtk_status_icon_set_visible (an->priv->status_icon, FALSE);
		g_clear_object (&an->priv->status_icon);
	}

	if (an->priv->window) {
		g_signal_handlers_disconnect_by_data (an->priv->window, an);

		gtk_widget_destroy (an->priv->window);
		an->priv->window = NULL;
		an->priv->reminders = NULL;
	}

	g_clear_object (&an->priv->registry);
	g_clear_object (&an->priv->watcher);
	g_clear_object (&an->priv->settings);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_alarm_notify_parent_class)->dispose (object);
}

static void
e_alarm_notify_finalize (GObject *object)
{
	EAlarmNotify *an = E_ALARM_NOTIFY (object);

	g_free (an->priv->status_icon_tooltip);
	g_mutex_clear (&an->priv->dismiss_lock);
	g_slist_free_full (an->priv->dismiss, e_reminder_data_free);
	g_hash_table_destroy (an->priv->notification_ids);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_alarm_notify_parent_class)->finalize (object);
}

static void
e_alarm_notify_class_init (EAlarmNotifyClass *klass)
{
	GObjectClass *object_class;
	GApplicationClass *application_class;

	g_type_class_add_private (klass, sizeof (EAlarmNotifyPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->dispose = e_alarm_notify_dispose;
	object_class->finalize = e_alarm_notify_finalize;

	application_class = G_APPLICATION_CLASS (klass);
	application_class->startup = e_alarm_notify_startup;
	application_class->activate = e_alarm_notify_activate;
}

static void
e_alarm_notify_initable_init (GInitableIface *iface)
{
	iface->init = e_alarm_notify_initable;
}

static void
e_alarm_notify_init (EAlarmNotify *an)
{
	an->priv = G_TYPE_INSTANCE_GET_PRIVATE (an, E_TYPE_ALARM_NOTIFY, EAlarmNotifyPrivate);
	an->priv->notification_ids = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);
	an->priv->last_n_reminders = G_MAXINT32;

	g_mutex_init (&an->priv->dismiss_lock);
}

/*
 * e_alarm_notify_new:
 *
 * Creates a new #EAlarmNotify object.
 *
 * Returns: (transfer full): a newly-created #EAlarmNotify
 **/
EAlarmNotify *
e_alarm_notify_new (GCancellable *cancellable,
		    GError **error)
{
	return g_initable_new (
		E_TYPE_ALARM_NOTIFY, cancellable, error,
		"application-id", APPLICATION_ID,
		NULL);
}
