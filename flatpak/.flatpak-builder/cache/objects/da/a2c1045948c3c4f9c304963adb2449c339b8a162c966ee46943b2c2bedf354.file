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

#if !defined (__LIBEDATASERVERUI_H_INSIDE__) && !defined (LIBEDATASERVERUI_COMPILATION)
#error "Only <libedataserverui/libedataserverui.h> should be included directly."
#endif

#ifndef E_REMINDERS_WIDGET_H
#define E_REMINDERS_WIDGET_H

#include <gtk/gtk.h>
#include <libecal/libecal.h>

/* Standard GObject macros */
#define E_TYPE_REMINDERS_WIDGET \
	(e_reminders_widget_get_type ())
#define E_REMINDERS_WIDGET(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_REMINDERS_WIDGET, ERemindersWidget))
#define E_REMINDERS_WIDGET_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_REMINDERS_WIDGET, ERemindersWidgetClass))
#define E_IS_REMINDERS_WIDGET(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_REMINDERS_WIDGET))
#define E_IS_REMINDERS_WIDGET_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_REMINDERS_WIDGET))
#define E_REMINDERS_WIDGET_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_REMINDERS_WIDGET, ERemindersWidgetClass))

G_BEGIN_DECLS

enum {
	E_REMINDERS_WIDGET_COLUMN_OVERDUE,	/* gchar *, markup with time to start/overdue description */
	E_REMINDERS_WIDGET_COLUMN_DESCRIPTION,	/* gchar *, markup describing the reminder, not component's DESCRIPTION property */
	E_REMINDERS_WIDGET_COLUMN_REMINDER_DATA,/* EReminderData * */
	E_REMINDERS_WIDGET_N_COLUMNS
};

typedef struct _ERemindersWidget ERemindersWidget;
typedef struct _ERemindersWidgetClass ERemindersWidgetClass;
typedef struct _ERemindersWidgetPrivate ERemindersWidgetPrivate;

/**
 * ERemindersWidget:
 *
 * Contains only private data that should be read and manipulated using
 * the functions below.
 *
 * Since: 3.30
 **/
struct _ERemindersWidget {
	/*< private >*/
	GtkGrid parent;
	ERemindersWidgetPrivate *priv;
};

/**
 * ERemindersWidgetClass:
 *
 * Class structure for the #ERemindersWidget class.
 *
 * Since: 3.30
 **/
struct _ERemindersWidgetClass {
	/*< private >*/
	GtkGridClass parent_class;

	/* Signals and methods */
	void		(* changed)		(ERemindersWidget *reminders);
	gboolean	(* activated)		(ERemindersWidget *reminders,
						 const EReminderData *rd);

	/* Padding for future expansion */
	gpointer reserved[10];
};

GType		e_reminders_widget_get_type	(void) G_GNUC_CONST;

ERemindersWidget *
		e_reminders_widget_new		(EReminderWatcher *watcher);
EReminderWatcher *
		e_reminders_widget_get_watcher	(ERemindersWidget *reminders);
GSettings *	e_reminders_widget_get_settings	(ERemindersWidget *reminders);
gboolean	e_reminders_widget_is_empty	(ERemindersWidget *reminders);
GtkTreeView *	e_reminders_widget_get_tree_view(ERemindersWidget *reminders);
void		e_reminders_widget_report_error	(ERemindersWidget *reminders,
						 const gchar *prefix,
						 const GError *error);

G_END_DECLS

#endif /* E_REMINDERS_WIDGET_H */
