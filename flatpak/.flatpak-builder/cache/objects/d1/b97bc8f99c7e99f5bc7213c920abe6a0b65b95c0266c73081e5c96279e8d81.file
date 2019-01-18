/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8; coding: utf-8 -*- */
/* gtksourceview.c
 * This file is part of GtkSourceView
 *
 * Copyright (C) 2001 - Mikael Hermansson <tyan@linux.se> and
 *                      Chris Phelps <chicane@reninet.com>
 * Copyright (C) 2002 - Jeroen Zwartepoorte
 * Copyright (C) 2003 - Gustavo Giráldez and Paolo Maggi
 *
 * GtkSourceView is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * GtkSourceView is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#ifdef HAVE_CONFIG_H
#include <config.h>
#endif

#include "gtksourceview.h"

#include <string.h> /* For strlen */

#include <gtk/gtk.h>
#include <gdk/gdkkeysyms.h>
#include <pango/pango-tabs.h>

#include "gtksourcebuffer.h"
#include "gtksourcebuffer-private.h"
#include "gtksourcebufferinternal.h"
#include "gtksourceview-i18n.h"
#include "gtksourceview-enumtypes.h"
#include "gtksourcemark.h"
#include "gtksourcemarkattributes.h"
#include "gtksourcestylescheme.h"
#include "gtksourcecompletionprovider.h"
#include "gtksourcecompletion-private.h"
#include "gtksourcegutter.h"
#include "gtksourcegutter-private.h"
#include "gtksourcegutterrendererlines.h"
#include "gtksourcegutterrenderermarks.h"
#include "gtksourceiter.h"
#include "gtksourcesearchcontext.h"
#include "gtksourcespacedrawer.h"
#include "gtksourcespacedrawer-private.h"

/**
 * SECTION:view
 * @Short_description: Widget that displays a GtkSourceBuffer
 * @Title: GtkSourceView
 * @See_also: #GtkTextView, #GtkSourceBuffer
 *
 * #GtkSourceView is the main class of the GtkSourceView library.
 * Use a #GtkSourceBuffer to display text with a #GtkSourceView.
 *
 * This class provides:
 *  - Show the line numbers;
 *  - Show a right margin;
 *  - Highlight the current line;
 *  - Indentation settings;
 *  - Configuration for the Home and End keyboard keys;
 *  - Configure and show line marks;
 *  - And a few other things.
 *
 * An easy way to test all these features is to use the test-widget mini-program
 * provided in the GtkSourceView repository, in the tests/ directory.
 *
 * # GtkSourceView as GtkBuildable
 *
 * The GtkSourceView implementation of the #GtkBuildable interface exposes the
 * #GtkSourceView:completion object with the internal-child "completion".
 *
 * An example of a UI definition fragment with GtkSourceView:
 * |[
 * <object class="GtkSourceView" id="source_view">
 *   <property name="tab_width">4</property>
 *   <property name="auto_indent">True</property>
 *   <child internal-child="completion">
 *     <object class="GtkSourceCompletion">
 *       <property name="select_on_show">False</property>
 *     </object>
 *   </child>
 * </object>
 * ]|
 */

/*
#define ENABLE_DEBUG
*/
#undef ENABLE_DEBUG

/*
#define ENABLE_PROFILE
*/
#undef ENABLE_PROFILE

#ifdef ENABLE_DEBUG
#define DEBUG(x) (x)
#else
#define DEBUG(x)
#endif

#ifdef ENABLE_PROFILE
#define PROFILE(x) (x)
#else
#define PROFILE(x)
#endif

#define GUTTER_PIXMAP 			16
#define DEFAULT_TAB_WIDTH 		8
#define MAX_TAB_WIDTH			32
#define MAX_INDENT_WIDTH		32

#define DEFAULT_RIGHT_MARGIN_POSITION	80
#define MAX_RIGHT_MARGIN_POSITION	1000

#define RIGHT_MARGIN_LINE_ALPHA		40
#define RIGHT_MARGIN_OVERLAY_ALPHA	15

enum
{
	UNDO,
	REDO,
	SHOW_COMPLETION,
	LINE_MARK_ACTIVATED,
	MOVE_LINES,
	MOVE_WORDS,
	SMART_HOME_END,
	MOVE_TO_MATCHING_BRACKET,
	CHANGE_NUMBER,
	CHANGE_CASE,
	JOIN_LINES,
	N_SIGNALS
};

enum
{
	PROP_0,
	PROP_COMPLETION,
	PROP_SHOW_LINE_NUMBERS,
	PROP_SHOW_LINE_MARKS,
	PROP_TAB_WIDTH,
	PROP_INDENT_WIDTH,
	PROP_AUTO_INDENT,
	PROP_INSERT_SPACES,
	PROP_SHOW_RIGHT_MARGIN,
	PROP_RIGHT_MARGIN_POSITION,
	PROP_SMART_HOME_END,
	PROP_HIGHLIGHT_CURRENT_LINE,
	PROP_INDENT_ON_TAB,
	PROP_DRAW_SPACES,
	PROP_BACKGROUND_PATTERN,
	PROP_SMART_BACKSPACE,
	PROP_SPACE_DRAWER
};

struct _GtkSourceViewPrivate
{
	GtkSourceStyleScheme *style_scheme;
	GdkRGBA *right_margin_line_color;
	GdkRGBA *right_margin_overlay_color;

	GtkSourceSpaceDrawer *space_drawer;

	GHashTable *mark_categories;

	GtkSourceBuffer *source_buffer;

	GtkSourceGutter *left_gutter;
	GtkSourceGutter *right_gutter;

	GtkSourceGutterRenderer *line_renderer;
	GtkSourceGutterRenderer *marks_renderer;

	GdkRGBA current_line_color;

	GtkSourceCompletion *completion;

	guint right_margin_pos;
	gint cached_right_margin_pos;
	guint tab_width;
	gint indent_width;
	GtkSourceSmartHomeEndType smart_home_end;
	GtkSourceBackgroundPatternType background_pattern;
	GdkRGBA background_pattern_color;

	guint tabs_set : 1;
	guint show_line_numbers : 1;
	guint show_line_marks : 1;
	guint auto_indent : 1;
	guint insert_spaces : 1;
	guint highlight_current_line : 1;
	guint indent_on_tab : 1;
	guint show_right_margin  : 1;
	guint current_line_color_set : 1;
	guint background_pattern_color_set : 1;
	guint smart_backspace : 1;
};

typedef struct _MarkCategory MarkCategory;

struct _MarkCategory
{
	GtkSourceMarkAttributes *attributes;
	gint priority;
};

static guint signals[N_SIGNALS];

static void gtk_source_view_buildable_interface_init (GtkBuildableIface *iface);

G_DEFINE_TYPE_WITH_CODE (GtkSourceView, gtk_source_view, GTK_TYPE_TEXT_VIEW,
			 G_ADD_PRIVATE (GtkSourceView)
			 G_IMPLEMENT_INTERFACE (GTK_TYPE_BUILDABLE,
						gtk_source_view_buildable_interface_init))

/* Implement DnD for application/x-color drops */
typedef enum _GtkSourceViewDropTypes {
	TARGET_COLOR = 200
} GtkSourceViewDropTypes;

static const GtkTargetEntry drop_types[] = {
	{(gchar *)"application/x-color", 0, TARGET_COLOR}
};

/* Prototypes. */
static void 	gtk_source_view_dispose			(GObject            *object);
static void 	gtk_source_view_finalize		(GObject            *object);
static void	gtk_source_view_undo 			(GtkSourceView      *view);
static void	gtk_source_view_redo 			(GtkSourceView      *view);
static void	gtk_source_view_show_completion_real	(GtkSourceView      *view);
static GtkTextBuffer * gtk_source_view_create_buffer	(GtkTextView        *view);
static void	remove_source_buffer			(GtkSourceView      *view);
static void	set_source_buffer			(GtkSourceView      *view,
							 GtkTextBuffer      *buffer);
static void	gtk_source_view_populate_popup 		(GtkTextView        *view,
							 GtkWidget          *popup);
static void	gtk_source_view_move_cursor		(GtkTextView        *text_view,
							 GtkMovementStep     step,
							 gint                count,
							 gboolean            extend_selection);
static void	gtk_source_view_delete_from_cursor	(GtkTextView        *text_view,
							 GtkDeleteType       type,
							 gint                count);
static gboolean gtk_source_view_extend_selection	(GtkTextView            *text_view,
							 GtkTextExtendSelection  granularity,
							 const GtkTextIter      *location,
							 GtkTextIter            *start,
							 GtkTextIter            *end);
static void 	gtk_source_view_get_lines		(GtkTextView       *text_view,
							 gint               first_y,
							 gint               last_y,
							 GArray            *buffer_coords,
							 GArray            *line_heights,
							 GArray            *numbers,
							 gint              *countp);
static gboolean gtk_source_view_draw 			(GtkWidget         *widget,
							 cairo_t           *cr);
static void	gtk_source_view_move_lines		(GtkSourceView     *view,
							 gboolean           copy,
							 gint               step);
static void	gtk_source_view_move_words		(GtkSourceView     *view,
							 gint               step);
static gboolean	gtk_source_view_key_press_event		(GtkWidget         *widget,
							 GdkEventKey       *event);
static void	view_dnd_drop 				(GtkTextView       *view,
							 GdkDragContext    *context,
							 gint               x,
							 gint               y,
							 GtkSelectionData  *selection_data,
							 guint              info,
							 guint              timestamp,
							 gpointer           data);
static gint	calculate_real_tab_width 		(GtkSourceView     *view,
							 guint              tab_size,
							 gchar              c);
static void	gtk_source_view_set_property		(GObject           *object,
							 guint              prop_id,
							 const GValue      *value,
							 GParamSpec        *pspec);
static void	gtk_source_view_get_property		(GObject           *object,
							 guint              prop_id,
							 GValue            *value,
							 GParamSpec        *pspec);
static void	gtk_source_view_style_updated		(GtkWidget         *widget);
static void	gtk_source_view_update_style_scheme	(GtkSourceView     *view);
static void	gtk_source_view_draw_layer		(GtkTextView        *view,
							 GtkTextViewLayer   layer,
							 cairo_t           *cr);

static MarkCategory *mark_category_new                  (GtkSourceMarkAttributes *attributes,
                                                         gint priority);
static void          mark_category_free                 (MarkCategory *category);

static void
gtk_source_view_constructed (GObject *object)
{
	GtkSourceView *view = GTK_SOURCE_VIEW (object);

	set_source_buffer (view, gtk_text_view_get_buffer (GTK_TEXT_VIEW (view)));

	G_OBJECT_CLASS (gtk_source_view_parent_class)->constructed (object);
}

static void
gtk_source_view_move_to_matching_bracket (GtkSourceView *view,
					  gboolean       extend_selection)
{
	GtkTextView *text_view = GTK_TEXT_VIEW (view);
	GtkTextBuffer *buffer;
	GtkTextMark *insert_mark;
	GtkTextIter insert;
	GtkTextIter bracket_match;
	GtkSourceBracketMatchType result;

	buffer = gtk_text_view_get_buffer (text_view);
	insert_mark = gtk_text_buffer_get_insert (buffer);
	gtk_text_buffer_get_iter_at_mark (buffer, &insert, insert_mark);

	result = _gtk_source_buffer_find_bracket_match (GTK_SOURCE_BUFFER (buffer),
							&insert,
							NULL,
							&bracket_match);

	if (result == GTK_SOURCE_BRACKET_MATCH_FOUND)
	{
		if (extend_selection)
		{
			gtk_text_buffer_move_mark (buffer, insert_mark, &bracket_match);
		}
		else
		{
			gtk_text_buffer_place_cursor (buffer, &bracket_match);
		}

		gtk_text_view_scroll_mark_onscreen (text_view, insert_mark);
	}
}

static void
gtk_source_view_change_number (GtkSourceView *view,
			       gint           count)
{
	GtkTextView *text_view = GTK_TEXT_VIEW (view);
	GtkTextBuffer *buffer;
	GtkTextIter start, end;
	gchar *str;

	buffer = gtk_text_view_get_buffer (text_view);
	if (!GTK_SOURCE_IS_BUFFER (buffer))
	{
		return;
	}

	if (!gtk_text_buffer_get_selection_bounds (buffer, &start, &end))
	{
		if (!gtk_text_iter_starts_word (&start))
		{
			gtk_text_iter_backward_word_start (&start);
		}

		if (!gtk_text_iter_ends_word (&end))
		{
			gtk_text_iter_forward_word_end (&end);
		}
	}

	str = gtk_text_buffer_get_text (buffer, &start, &end, FALSE);

	if (str != NULL && *str != '\0')
	{
		gchar *p;
		gint64 n;
		glong len;

		len = gtk_text_iter_get_offset (&end) - gtk_text_iter_get_offset (&start);
		g_assert (len > 0);

		n = g_ascii_strtoll (str, &p, 10);

		/* do the action only if strtoll succeeds (p != str) and
		 * the whole string is the number, e.g. not 123abc
		 */
		if ((p - str) == len)
		{
			gchar *newstr;

			newstr = g_strdup_printf ("%"G_GINT64_FORMAT, (n + count));

			gtk_text_buffer_begin_user_action (buffer);
			gtk_text_buffer_delete (buffer, &start, &end);
			gtk_text_buffer_insert (buffer, &start, newstr, -1);
			gtk_text_buffer_end_user_action (buffer);

			g_free (newstr);
		}

		g_free (str);
	}
}

static void
gtk_source_view_change_case (GtkSourceView           *view,
			     GtkSourceChangeCaseType  case_type)
{
	GtkSourceBuffer *buffer;
	GtkTextIter start, end;

	buffer = GTK_SOURCE_BUFFER (gtk_text_view_get_buffer (GTK_TEXT_VIEW (view)));

	gtk_text_view_reset_im_context (GTK_TEXT_VIEW (view));

	if (!gtk_text_buffer_get_selection_bounds (GTK_TEXT_BUFFER (buffer), &start, &end))
	{
		/* if no selection, change the current char */
		gtk_text_iter_forward_char (&end);
	}

	gtk_source_buffer_change_case (buffer, case_type, &start, &end);
}

static void
gtk_source_view_join_lines (GtkSourceView *view)
{
	GtkSourceBuffer *buffer;
	GtkTextIter start;
	GtkTextIter end;

	buffer = GTK_SOURCE_BUFFER (gtk_text_view_get_buffer (GTK_TEXT_VIEW (view)));

	gtk_text_view_reset_im_context (GTK_TEXT_VIEW (view));

	gtk_text_buffer_get_selection_bounds (GTK_TEXT_BUFFER (buffer), &start, &end);

	gtk_source_buffer_join_lines (buffer, &start, &end);
}

static void
gtk_source_view_class_init (GtkSourceViewClass *klass)
{
	GObjectClass *object_class;
	GtkTextViewClass *textview_class;
	GtkBindingSet *binding_set;
	GtkWidgetClass *widget_class;

	object_class = G_OBJECT_CLASS (klass);
	textview_class = GTK_TEXT_VIEW_CLASS (klass);
	widget_class = GTK_WIDGET_CLASS (klass);

	object_class->constructed = gtk_source_view_constructed;
	object_class->dispose = gtk_source_view_dispose;
	object_class->finalize = gtk_source_view_finalize;
	object_class->get_property = gtk_source_view_get_property;
	object_class->set_property = gtk_source_view_set_property;

	widget_class->key_press_event = gtk_source_view_key_press_event;
	widget_class->draw = gtk_source_view_draw;
	widget_class->style_updated = gtk_source_view_style_updated;

	textview_class->populate_popup = gtk_source_view_populate_popup;
	textview_class->move_cursor = gtk_source_view_move_cursor;
	textview_class->delete_from_cursor = gtk_source_view_delete_from_cursor;
	textview_class->extend_selection = gtk_source_view_extend_selection;
	textview_class->create_buffer = gtk_source_view_create_buffer;
	textview_class->draw_layer = gtk_source_view_draw_layer;

	klass->undo = gtk_source_view_undo;
	klass->redo = gtk_source_view_redo;
	klass->show_completion = gtk_source_view_show_completion_real;
	klass->move_lines = gtk_source_view_move_lines;
	klass->move_words = gtk_source_view_move_words;

	/**
	 * GtkSourceView:completion:
	 *
	 * The completion object associated with the view
	 */
	g_object_class_install_property (object_class,
					 PROP_COMPLETION,
					 g_param_spec_object ("completion",
							      "Completion",
							      "The completion object associated with the view",
							      GTK_SOURCE_TYPE_COMPLETION,
							      G_PARAM_READABLE |
							      G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:show-line-numbers:
	 *
	 * Whether to display line numbers
	 */
	g_object_class_install_property (object_class,
					 PROP_SHOW_LINE_NUMBERS,
					 g_param_spec_boolean ("show-line-numbers",
							       "Show Line Numbers",
							       "Whether to display line numbers",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));
	/**
	 * GtkSourceView:show-line-marks:
	 *
	 * Whether to display line mark pixbufs
	 */
	g_object_class_install_property (object_class,
					 PROP_SHOW_LINE_MARKS,
					 g_param_spec_boolean ("show-line-marks",
							       "Show Line Marks",
							       "Whether to display line mark pixbufs",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:tab-width:
	 *
	 * Width of a tab character expressed in number of spaces.
	 */
	g_object_class_install_property (object_class,
					 PROP_TAB_WIDTH,
					 g_param_spec_uint ("tab-width",
							    "Tab Width",
							    "Width of a tab character expressed in spaces",
							    1,
							    MAX_TAB_WIDTH,
							    DEFAULT_TAB_WIDTH,
							    G_PARAM_READWRITE |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:indent-width:
	 *
	 * Width of an indentation step expressed in number of spaces.
	 */
	g_object_class_install_property (object_class,
					 PROP_INDENT_WIDTH,
					 g_param_spec_int ("indent-width",
							   "Indent Width",
							   "Number of spaces to use for each step of indent",
							   -1,
							   MAX_INDENT_WIDTH,
							   -1,
							   G_PARAM_READWRITE |
							   G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (object_class,
					 PROP_AUTO_INDENT,
					 g_param_spec_boolean ("auto-indent",
							       "Auto Indentation",
							       "Whether to enable auto indentation",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (object_class,
					 PROP_INSERT_SPACES,
					 g_param_spec_boolean ("insert-spaces-instead-of-tabs",
							       "Insert Spaces Instead of Tabs",
							       "Whether to insert spaces instead of tabs",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:show-right-margin:
	 *
	 * Whether to display the right margin.
	 */
	g_object_class_install_property (object_class,
					 PROP_SHOW_RIGHT_MARGIN,
					 g_param_spec_boolean ("show-right-margin",
							       "Show Right Margin",
							       "Whether to display the right margin",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:right-margin-position:
	 *
	 * Position of the right margin.
	 */
	g_object_class_install_property (object_class,
					 PROP_RIGHT_MARGIN_POSITION,
					 g_param_spec_uint ("right-margin-position",
							    "Right Margin Position",
							    "Position of the right margin",
							    1,
							    MAX_RIGHT_MARGIN_POSITION,
							    DEFAULT_RIGHT_MARGIN_POSITION,
							    G_PARAM_READWRITE |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:smart-home-end:
	 *
	 * Set the behavior of the HOME and END keys.
	 *
	 * Since: 2.0
	 */
	g_object_class_install_property (object_class,
					 PROP_SMART_HOME_END,
					 g_param_spec_enum ("smart-home-end",
							    "Smart Home/End",
							    "HOME and END keys move to first/last "
							    "non whitespace characters on line before going "
							    "to the start/end of the line",
							    GTK_SOURCE_TYPE_SMART_HOME_END_TYPE,
							    GTK_SOURCE_SMART_HOME_END_DISABLED,
							    G_PARAM_READWRITE |
							    G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (object_class,
					 PROP_HIGHLIGHT_CURRENT_LINE,
					 g_param_spec_boolean ("highlight-current-line",
							       "Highlight current line",
							       "Whether to highlight the current line",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));

	g_object_class_install_property (object_class,
					 PROP_INDENT_ON_TAB,
					 g_param_spec_boolean ("indent-on-tab",
							       "Indent on tab",
							       "Whether to indent the selected text when the tab key is pressed",
							       TRUE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:draw-spaces:
	 *
	 * Set if and how the spaces should be visualized.
	 *
	 * For a finer-grained method, there is also the GtkSourceTag's
	 * #GtkSourceTag:draw-spaces property.
	 *
	 * Since: 2.4
	 * Deprecated: 3.24: Use the #GtkSourceSpaceDrawer:matrix property
	 * instead.
	 */
	g_object_class_install_property (object_class,
					 PROP_DRAW_SPACES,
					 g_param_spec_flags ("draw-spaces",
							     "Draw Spaces",
							     "Set if and how the spaces should be visualized",
							     GTK_SOURCE_TYPE_DRAW_SPACES_FLAGS,
							     0,
							     G_PARAM_READWRITE |
							     G_PARAM_STATIC_STRINGS |
							     G_PARAM_DEPRECATED));

	/**
	 * GtkSourceView:background-pattern:
	 *
	 * Draw a specific background pattern on the view.
	 *
	 * Since: 3.16
	 */
	g_object_class_install_property (object_class,
					 PROP_BACKGROUND_PATTERN,
					 g_param_spec_enum ("background-pattern",
							    "Background pattern",
							    "Draw a specific background pattern on the view",
							    GTK_SOURCE_TYPE_BACKGROUND_PATTERN_TYPE,
							    GTK_SOURCE_BACKGROUND_PATTERN_TYPE_NONE,
							    G_PARAM_READWRITE |
							    G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:smart-backspace:
	 *
	 * Whether smart Backspace should be used.
	 *
	 * Since: 3.18
	 */
	g_object_class_install_property (object_class,
					 PROP_SMART_BACKSPACE,
					 g_param_spec_boolean ("smart-backspace",
							       "Smart Backspace",
							       "",
							       FALSE,
							       G_PARAM_READWRITE |
							       G_PARAM_STATIC_STRINGS));

	/**
	 * GtkSourceView:space-drawer:
	 *
	 * The #GtkSourceSpaceDrawer object associated with the view.
	 *
	 * Since: 3.24
	 */
	g_object_class_install_property (object_class,
					 PROP_SPACE_DRAWER,
					 g_param_spec_object ("space-drawer",
							      "Space Drawer",
							      "",
							      GTK_SOURCE_TYPE_SPACE_DRAWER,
							      G_PARAM_READABLE |
							      G_PARAM_STATIC_STRINGS));

	signals[UNDO] =
		g_signal_new ("undo",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceViewClass, undo),
			      NULL, NULL, NULL,
			      G_TYPE_NONE, 0);

	signals[REDO] =
		g_signal_new ("redo",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceViewClass, redo),
			      NULL, NULL, NULL,
			      G_TYPE_NONE, 0);

	/**
	 * GtkSourceView::show-completion:
	 * @view: The #GtkSourceView who emits the signal
	 *
	 * The ::show-completion signal is a key binding signal which gets
	 * emitted when the user requests a completion, by pressing
	 * <keycombo><keycap>Control</keycap><keycap>space</keycap></keycombo>.
	 *
	 * This will create a #GtkSourceCompletionContext with the activation
	 * type as %GTK_SOURCE_COMPLETION_ACTIVATION_USER_REQUESTED.
	 *
	 * Applications should not connect to it, but may emit it with
	 * g_signal_emit_by_name() if they need to activate the completion by
	 * another means, for example with another key binding or a menu entry.
	 */
	signals[SHOW_COMPLETION] =
		g_signal_new ("show-completion",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceViewClass, show_completion),
			      NULL, NULL, NULL,
			      G_TYPE_NONE, 0);

	/**
	 * GtkSourceView::line-mark-activated:
	 * @view: the #GtkSourceView
	 * @iter: a #GtkTextIter
	 * @event: the #GdkEvent that activated the event
	 *
	 * Emitted when a line mark has been activated (for instance when there
	 * was a button press in the line marks gutter). You can use @iter to
	 * determine on which line the activation took place.
	 */
	signals[LINE_MARK_ACTIVATED] =
		g_signal_new ("line-mark-activated",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST,
			      G_STRUCT_OFFSET (GtkSourceViewClass, line_mark_activated),
			      NULL, NULL, NULL,
			      G_TYPE_NONE,
			      2,
			      GTK_TYPE_TEXT_ITER,
			      GDK_TYPE_EVENT | G_SIGNAL_TYPE_STATIC_SCOPE);

	/**
	 * GtkSourceView::move-lines:
	 * @view: the #GtkSourceView which received the signal
	 * @copy: %TRUE if the line should be copied, %FALSE if it should be
	 *   moved. This parameter is deprecated and will be removed in a later
	 *   version, it should be always %FALSE.
	 * @count: the number of lines to move over. Only 1 and -1 are
	 *   supported.
	 *
	 * The ::move-lines signal is a keybinding which gets emitted
	 * when the user initiates moving a line. The default binding key
	 * is Alt+Up/Down arrow. And moves the currently selected lines,
	 * or the current line by @count. For the moment, only
	 * @count of -1 or 1 is valid.
	 *
	 * The @copy parameter is deprecated, it has never been used by
	 * GtkSourceView (the value is always %FALSE) and was buggy.
	 *
	 * Since: 2.10
	 */
	signals[MOVE_LINES] =
		g_signal_new ("move-lines",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceViewClass, move_lines),
			      NULL, NULL, NULL,
			      G_TYPE_NONE, 2,
			      G_TYPE_BOOLEAN,
			      G_TYPE_INT);

	/**
	 * GtkSourceView::move-words:
	 * @view: the #GtkSourceView which received the signal
	 * @count: the number of words to move over
	 *
	 * The ::move-words signal is a keybinding which gets emitted
	 * when the user initiates moving a word. The default binding key
	 * is Alt+Left/Right Arrow and moves the current selection, or the current
	 * word by one word.
	 *
	 * Since: 3.0
	 */
	signals[MOVE_WORDS] =
		g_signal_new ("move-words",
			      G_TYPE_FROM_CLASS (klass),
			      G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
			      G_STRUCT_OFFSET (GtkSourceViewClass, move_words),
			      NULL, NULL, NULL,
			      G_TYPE_NONE, 1,
			      G_TYPE_INT);

	/**
	 * GtkSourceView::smart-home-end:
	 * @view: the #GtkSourceView
	 * @iter: a #GtkTextIter
	 * @count: the count
	 *
	 * Emitted when a the cursor was moved according to the smart home
	 * end setting. The signal is emitted after the cursor is moved, but
	 * during the GtkTextView::move-cursor action. This can be used to find
	 * out whether the cursor was moved by a normal home/end or by a smart
	 * home/end.
	 *
	 * Since: 3.0
	 */
	signals[SMART_HOME_END] =
		g_signal_new ("smart-home-end",
		              G_TYPE_FROM_CLASS (klass),
		              G_SIGNAL_RUN_LAST,
		              0,
		              NULL, NULL, NULL,
		              G_TYPE_NONE,
		              2,
		              GTK_TYPE_TEXT_ITER,
		              G_TYPE_INT);

	/**
	 * GtkSourceView::move-to-matching-bracket:
	 * @view: the #GtkSourceView
	 * @extend_selection: %TRUE if the move should extend the selection
	 *
	 * Keybinding signal to move the cursor to the matching bracket.
	 *
	 * Since: 3.16
	 */
	signals[MOVE_TO_MATCHING_BRACKET] =
		/* we have to do it this way since we do not have any more vfunc slots */
		g_signal_new_class_handler ("move-to-matching-bracket",
		                            G_TYPE_FROM_CLASS (klass),
		                            G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		                            G_CALLBACK (gtk_source_view_move_to_matching_bracket),
		                            NULL, NULL, NULL,
		                            G_TYPE_NONE,
		                            1,
		                            G_TYPE_BOOLEAN);

	/**
	 * GtkSourceView::change-number:
	 * @view: the #GtkSourceView
	 * @count: the number to add to the number at the current position
	 *
	 * Keybinding signal to edit a number at the current cursor position.
	 *
	 * Since: 3.16
	 */
	signals[CHANGE_NUMBER] =
		g_signal_new_class_handler ("change-number",
		                            G_TYPE_FROM_CLASS (klass),
		                            G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		                            G_CALLBACK (gtk_source_view_change_number),
		                            NULL, NULL, NULL,
		                            G_TYPE_NONE,
		                            1,
		                            G_TYPE_INT);

	/**
	 * GtkSourceView::change-case:
	 * @view: the #GtkSourceView
	 * @case_type: the case to use
	 *
	 * Keybinding signal to change case of the text at the current cursor position.
	 *
	 * Since: 3.16
	 */
	signals[CHANGE_CASE] =
		g_signal_new_class_handler ("change-case",
		                            G_TYPE_FROM_CLASS (klass),
		                            G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		                            G_CALLBACK (gtk_source_view_change_case),
		                            NULL, NULL, NULL,
		                            G_TYPE_NONE,
		                            1,
		                            GTK_SOURCE_TYPE_CHANGE_CASE_TYPE);

	/**
	 * GtkSourceView::join-lines:
	 * @view: the #GtkSourceView
	 *
	 * Keybinding signal to join the lines currently selected.
	 *
	 * Since: 3.16
	 */
	signals[JOIN_LINES] =
		g_signal_new_class_handler ("join-lines",
		                            G_TYPE_FROM_CLASS (klass),
		                            G_SIGNAL_RUN_LAST | G_SIGNAL_ACTION,
		                            G_CALLBACK (gtk_source_view_join_lines),
		                            NULL, NULL, NULL,
		                            G_TYPE_NONE,
		                            0);

	binding_set = gtk_binding_set_by_class (klass);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_z,
				      GDK_CONTROL_MASK,
				      "undo", 0);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_z,
				      GDK_CONTROL_MASK | GDK_SHIFT_MASK,
				      "redo", 0);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_F14,
				      0,
				      "undo", 0);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_space,
				      GDK_CONTROL_MASK,
				      "show-completion", 0);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Up,
				      GDK_MOD1_MASK,
				      "move-lines", 2,
				      G_TYPE_BOOLEAN, FALSE,
				      G_TYPE_INT, -1);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Up,
				      GDK_MOD1_MASK,
				      "move-lines", 2,
				      G_TYPE_BOOLEAN, FALSE,
				      G_TYPE_INT, -1);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Down,
				      GDK_MOD1_MASK,
				      "move-lines", 2,
				      G_TYPE_BOOLEAN, FALSE,
				      G_TYPE_INT, 1);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Down,
				      GDK_MOD1_MASK,
				      "move-lines", 2,
				      G_TYPE_BOOLEAN, FALSE,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Left,
				      GDK_MOD1_MASK,
				      "move-words", 1,
				      G_TYPE_INT, -1);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Left,
				      GDK_MOD1_MASK,
				      "move-words", 1,
				      G_TYPE_INT, -1);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Right,
				      GDK_MOD1_MASK,
				      "move-words", 1,
				      G_TYPE_INT, 1);
	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Right,
				      GDK_MOD1_MASK,
				      "move-words", 1,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Up,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_STEPS,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Up,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_STEPS,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Down,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_STEPS,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Down,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_STEPS,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Page_Up,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_PAGES,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Page_Up,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_PAGES,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Page_Down,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_PAGES,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Page_Down,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_PAGES,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_Home,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_ENDS,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_Home,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_ENDS,
				      G_TYPE_INT, -1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_End,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_ENDS,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_KP_End,
				      GDK_MOD1_MASK | GDK_SHIFT_MASK,
				      "move-viewport", 2,
				      GTK_TYPE_SCROLL_STEP, GTK_SCROLL_ENDS,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_percent,
				      GDK_CONTROL_MASK,
				      "move-to-matching-bracket", 1,
				      G_TYPE_BOOLEAN, FALSE);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_a,
				      GDK_CONTROL_MASK | GDK_SHIFT_MASK,
				      "change-number", 1,
				      G_TYPE_INT, 1);

	gtk_binding_entry_add_signal (binding_set,
				      GDK_KEY_x,
				      GDK_CONTROL_MASK | GDK_SHIFT_MASK,
				      "change-number", 1,
				      G_TYPE_INT, -1);
}

static GObject *
gtk_source_view_buildable_get_internal_child (GtkBuildable *buildable,
					      GtkBuilder   *builder,
					      const gchar  *childname)
{
	GtkSourceView *view = GTK_SOURCE_VIEW (buildable);

	if (g_strcmp0 (childname, "completion") == 0)
	{
		return G_OBJECT (gtk_source_view_get_completion (view));
	}

	return NULL;
}

static void
gtk_source_view_buildable_interface_init (GtkBuildableIface *iface)
{
	iface->get_internal_child = gtk_source_view_buildable_get_internal_child;
}

static void
gtk_source_view_set_property (GObject      *object,
			      guint         prop_id,
			      const GValue *value,
			      GParamSpec   *pspec)
{
	GtkSourceView *view;

	g_return_if_fail (GTK_SOURCE_IS_VIEW (object));

	view = GTK_SOURCE_VIEW (object);

	switch (prop_id)
	{
		case PROP_SHOW_LINE_NUMBERS:
			gtk_source_view_set_show_line_numbers (view, g_value_get_boolean (value));
			break;

		case PROP_SHOW_LINE_MARKS:
			gtk_source_view_set_show_line_marks (view, g_value_get_boolean (value));
			break;

		case PROP_TAB_WIDTH:
			gtk_source_view_set_tab_width (view, g_value_get_uint (value));
			break;

		case PROP_INDENT_WIDTH:
			gtk_source_view_set_indent_width (view, g_value_get_int (value));
			break;

		case PROP_AUTO_INDENT:
			gtk_source_view_set_auto_indent (view, g_value_get_boolean (value));
			break;

		case PROP_INSERT_SPACES:
			gtk_source_view_set_insert_spaces_instead_of_tabs (view, g_value_get_boolean (value));
			break;

		case PROP_SHOW_RIGHT_MARGIN:
			gtk_source_view_set_show_right_margin (view, g_value_get_boolean (value));
			break;

		case PROP_RIGHT_MARGIN_POSITION:
			gtk_source_view_set_right_margin_position (view, g_value_get_uint (value));
			break;

		case PROP_SMART_HOME_END:
			gtk_source_view_set_smart_home_end (view, g_value_get_enum (value));
			break;

		case PROP_HIGHLIGHT_CURRENT_LINE:
			gtk_source_view_set_highlight_current_line (view, g_value_get_boolean (value));
			break;

		case PROP_INDENT_ON_TAB:
			gtk_source_view_set_indent_on_tab (view, g_value_get_boolean (value));
			break;

		case PROP_DRAW_SPACES:
			G_GNUC_BEGIN_IGNORE_DEPRECATIONS;
			gtk_source_view_set_draw_spaces (view, g_value_get_flags (value));
			G_GNUC_END_IGNORE_DEPRECATIONS;
			break;

		case PROP_BACKGROUND_PATTERN:
			gtk_source_view_set_background_pattern (view, g_value_get_enum (value));
			break;

		case PROP_SMART_BACKSPACE:
			gtk_source_view_set_smart_backspace (view, g_value_get_boolean (value));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
gtk_source_view_get_property (GObject    *object,
			      guint       prop_id,
			      GValue     *value,
			      GParamSpec *pspec)
{
	GtkSourceView *view;

	g_return_if_fail (GTK_SOURCE_IS_VIEW (object));

	view = GTK_SOURCE_VIEW (object);

	switch (prop_id)
	{
		case PROP_COMPLETION:
			g_value_set_object (value, gtk_source_view_get_completion (view));
			break;

		case PROP_SHOW_LINE_NUMBERS:
			g_value_set_boolean (value, gtk_source_view_get_show_line_numbers (view));
			break;

		case PROP_SHOW_LINE_MARKS:
			g_value_set_boolean (value, gtk_source_view_get_show_line_marks (view));
			break;

		case PROP_TAB_WIDTH:
			g_value_set_uint (value, gtk_source_view_get_tab_width (view));
			break;

		case PROP_INDENT_WIDTH:
			g_value_set_int (value, gtk_source_view_get_indent_width (view));
			break;

		case PROP_AUTO_INDENT:
			g_value_set_boolean (value, gtk_source_view_get_auto_indent (view));
			break;

		case PROP_INSERT_SPACES:
			g_value_set_boolean (value, gtk_source_view_get_insert_spaces_instead_of_tabs (view));
			break;

		case PROP_SHOW_RIGHT_MARGIN:
			g_value_set_boolean (value, gtk_source_view_get_show_right_margin (view));
			break;

		case PROP_RIGHT_MARGIN_POSITION:
			g_value_set_uint (value, gtk_source_view_get_right_margin_position (view));
			break;

		case PROP_SMART_HOME_END:
			g_value_set_enum (value, gtk_source_view_get_smart_home_end (view));
			break;

		case PROP_HIGHLIGHT_CURRENT_LINE:
			g_value_set_boolean (value, gtk_source_view_get_highlight_current_line (view));
			break;

		case PROP_INDENT_ON_TAB:
			g_value_set_boolean (value, gtk_source_view_get_indent_on_tab (view));
			break;

		case PROP_DRAW_SPACES:
			G_GNUC_BEGIN_IGNORE_DEPRECATIONS;
			g_value_set_flags (value, gtk_source_view_get_draw_spaces (view));
			G_GNUC_END_IGNORE_DEPRECATIONS;
			break;

		case PROP_BACKGROUND_PATTERN:
			g_value_set_enum (value, gtk_source_view_get_background_pattern (view));
			break;

		case PROP_SMART_BACKSPACE:
			g_value_set_boolean (value, gtk_source_view_get_smart_backspace (view));
			break;

		case PROP_SPACE_DRAWER:
			g_value_set_object (value, gtk_source_view_get_space_drawer (view));
			break;

		default:
			G_OBJECT_WARN_INVALID_PROPERTY_ID (object, prop_id, pspec);
			break;
	}
}

static void
space_drawer_notify_cb (GtkSourceSpaceDrawer *space_drawer,
			GParamSpec           *pspec,
			GtkSourceView        *view)
{
	gtk_widget_queue_draw (GTK_WIDGET (view));
	g_object_notify (G_OBJECT (view), "draw-spaces");
}

static void
notify_buffer_cb (GtkSourceView *view)
{
	set_source_buffer (view, gtk_text_view_get_buffer (GTK_TEXT_VIEW (view)));
}

static void
gtk_source_view_init (GtkSourceView *view)
{
	GtkStyleContext *context;

	GtkTargetList *target_list;

	view->priv = gtk_source_view_get_instance_private (view);

	view->priv->tab_width = DEFAULT_TAB_WIDTH;
	view->priv->tabs_set = FALSE;
	view->priv->indent_width = -1;
	view->priv->indent_on_tab = TRUE;
	view->priv->smart_home_end = GTK_SOURCE_SMART_HOME_END_DISABLED;
	view->priv->right_margin_pos = DEFAULT_RIGHT_MARGIN_POSITION;
	view->priv->cached_right_margin_pos = -1;

	gtk_text_view_set_left_margin (GTK_TEXT_VIEW (view), 2);
	gtk_text_view_set_right_margin (GTK_TEXT_VIEW (view), 2);

	view->priv->right_margin_line_color = NULL;
	view->priv->right_margin_overlay_color = NULL;

	view->priv->space_drawer = gtk_source_space_drawer_new ();
	g_signal_connect_object (view->priv->space_drawer,
				 "notify",
				 G_CALLBACK (space_drawer_notify_cb),
				 view,
				 0);

	view->priv->mark_categories = g_hash_table_new_full (g_str_hash,
	                                                     g_str_equal,
	                                                     (GDestroyNotify) g_free,
	                                                     (GDestroyNotify) mark_category_free);

	target_list = gtk_drag_dest_get_target_list (GTK_WIDGET (view));
	g_return_if_fail (target_list != NULL);

	gtk_target_list_add_table (target_list, drop_types, G_N_ELEMENTS (drop_types));

	gtk_widget_set_has_tooltip (GTK_WIDGET (view), TRUE);

	g_signal_connect (view,
			  "drag_data_received",
			  G_CALLBACK (view_dnd_drop),
			  NULL);

	g_signal_connect (view,
			  "notify::buffer",
			  G_CALLBACK (notify_buffer_cb),
			  NULL);

	context = gtk_widget_get_style_context (GTK_WIDGET (view));
	gtk_style_context_add_class (context, "sourceview");
}

static void
gtk_source_view_dispose (GObject *object)
{
	GtkSourceView *view = GTK_SOURCE_VIEW (object);

	g_clear_object (&view->priv->completion);
	g_clear_object (&view->priv->left_gutter);
	g_clear_object (&view->priv->right_gutter);
	g_clear_object (&view->priv->style_scheme);
	g_clear_object (&view->priv->space_drawer);

	remove_source_buffer (view);

	/* Disconnect notify buffer because the destroy of the textview will set
	 * the buffer to NULL, and we call get_buffer in the notify which would
	 * reinstate a buffer which we don't want.
	 * There is no problem calling g_signal_handlers_disconnect_by_func()
	 * several times (if dispose() is called several times).
	 */
	g_signal_handlers_disconnect_by_func (view, notify_buffer_cb, NULL);

	G_OBJECT_CLASS (gtk_source_view_parent_class)->dispose (object);
}

static void
gtk_source_view_finalize (GObject *object)
{
	GtkSourceView *view = GTK_SOURCE_VIEW (object);

	if (view->priv->right_margin_line_color != NULL)
	{
		gdk_rgba_free (view->priv->right_margin_line_color);
	}

	if (view->priv->right_margin_overlay_color != NULL)
	{
		gdk_rgba_free (view->priv->right_margin_overlay_color);
	}

	if (view->priv->mark_categories)
	{
		g_hash_table_destroy (view->priv->mark_categories);
	}

	G_OBJECT_CLASS (gtk_source_view_parent_class)->finalize (object);
}

static void
get_visible_region (GtkTextView *text_view,
		    GtkTextIter *start,
		    GtkTextIter *end)
{
	GdkRectangle visible_rect;

	gtk_text_view_get_visible_rect (text_view, &visible_rect);

	gtk_text_view_get_line_at_y (text_view,
				     start,
				     visible_rect.y,
				     NULL);

	gtk_text_view_get_line_at_y (text_view,
				     end,
				     visible_rect.y + visible_rect.height,
				     NULL);

	gtk_text_iter_backward_line (start);
	gtk_text_iter_forward_line (end);
}

static void
highlight_updated_cb (GtkSourceBuffer *buffer,
		      GtkTextIter     *_start,
		      GtkTextIter     *_end,
		      GtkTextView     *text_view)
{
	GtkTextIter start;
	GtkTextIter end;
	GtkTextIter visible_start;
	GtkTextIter visible_end;
	GtkTextIter intersect_start;
	GtkTextIter intersect_end;

#if 0
	{
		static gint nth_call = 0;

		g_message ("%s(view=%p) %d [%d-%d]",
			   G_STRFUNC,
			   text_view,
			   ++nth_call,
			   gtk_text_iter_get_offset (_start),
			   gtk_text_iter_get_offset (_end));
	}
#endif

	start = *_start;
	end = *_end;
	gtk_text_iter_order (&start, &end);

	get_visible_region (text_view, &visible_start, &visible_end);

	if (gtk_text_iter_compare (&end, &visible_start) < 0 ||
	    gtk_text_iter_compare (&visible_end, &start) < 0)
	{
		return;
	}

	if (gtk_text_iter_compare (&start, &visible_start) < 0)
	{
		intersect_start = visible_start;
	}
	else
	{
		intersect_start = start;
	}

	if (gtk_text_iter_compare (&visible_end, &end) < 0)
	{
		intersect_end = visible_end;
	}
	else
	{
		intersect_end = end;
	}

	/* GtkSourceContextEngine sends the highlight-updated signal to notify
	 * the view, and in the view (here) we tell the ContextEngine to update
	 * the highlighting, but only in the visible area. It seems that the
	 * purpose is to reduce the number of tags that the ContextEngine
	 * applies to the buffer.
	 *
	 * A previous implementation of this signal handler queued a redraw on
	 * the view with gtk_widget_queue_draw_area(), instead of calling
	 * directly _gtk_source_buffer_update_syntax_highlight(). The ::draw
	 * handler also calls _gtk_source_buffer_update_syntax_highlight(), so
	 * this had the desired effect, but it was less clear.
	 * See the Git commit 949cd128064201935f90d999544e6a19f8e3baa6.
	 * And: https://bugzilla.gnome.org/show_bug.cgi?id=767565
	 */
	_gtk_source_buffer_update_syntax_highlight (buffer,
						    &intersect_start,
						    &intersect_end,
						    FALSE);
}

static void
search_start_cb (GtkSourceBufferInternal *buffer_internal,
		 GtkSourceSearchContext  *search_context,
		 GtkSourceView           *view)
{
	GtkTextIter visible_start;
	GtkTextIter visible_end;
	GtkSourceBuffer *buffer_search;

	get_visible_region (GTK_TEXT_VIEW (view), &visible_start, &visible_end);

	buffer_search = gtk_source_search_context_get_buffer (search_context);
	g_assert (buffer_search == view->priv->source_buffer);

	_gtk_source_search_context_update_highlight (search_context,
						     &visible_start,
						     &visible_end,
						     FALSE);
}

static void
source_mark_updated_cb (GtkSourceBuffer *buffer,
			GtkSourceMark   *mark,
			GtkTextView     *text_view)
{
	/* TODO do something more intelligent here, namely
	 * invalidate only the area under the mark if possible */
	gtk_widget_queue_draw (GTK_WIDGET (text_view));
}

static void
buffer_style_scheme_changed_cb (GtkSourceBuffer *buffer,
				GParamSpec      *pspec,
				GtkSourceView   *view)
{
	gtk_source_view_update_style_scheme (view);
}

static void
implicit_trailing_newline_changed_cb (GtkSourceBuffer *buffer,
				      GParamSpec      *pspec,
				      GtkSourceView   *view)
{
	/* For drawing or not a trailing newline. */
	gtk_widget_queue_draw (GTK_WIDGET (view));
}

static void
remove_source_buffer (GtkSourceView *view)
{
	if (view->priv->source_buffer != NULL)
	{
		GtkSourceBufferInternal *buffer_internal;

		g_signal_handlers_disconnect_by_func (view->priv->source_buffer,
						      highlight_updated_cb,
						      view);

		g_signal_handlers_disconnect_by_func (view->priv->source_buffer,
						      source_mark_updated_cb,
						      view);

		g_signal_handlers_disconnect_by_func (view->priv->source_buffer,
						      buffer_style_scheme_changed_cb,
						      view);

		g_signal_handlers_disconnect_by_func (view->priv->source_buffer,
						      implicit_trailing_newline_changed_cb,
						      view);

		buffer_internal = _gtk_source_buffer_internal_get_from_buffer (view->priv->source_buffer);

		g_signal_handlers_disconnect_by_func (buffer_internal,
						      search_start_cb,
						      view);

		g_object_unref (view->priv->source_buffer);
		view->priv->source_buffer = NULL;
	}
}

static void
set_source_buffer (GtkSourceView *view,
		   GtkTextBuffer *buffer)
{
	if (buffer == (GtkTextBuffer*) view->priv->source_buffer)
	{
		return;
	}

	remove_source_buffer (view);

	if (GTK_SOURCE_IS_BUFFER (buffer))
	{
		GtkSourceBufferInternal *buffer_internal;

		view->priv->source_buffer = g_object_ref (buffer);

		g_signal_connect (buffer,
				  "highlight-updated",
				  G_CALLBACK (highlight_updated_cb),
				  view);

		g_signal_connect (buffer,
				  "source-mark-updated",
				  G_CALLBACK (source_mark_updated_cb),
				  view);

		g_signal_connect (buffer,
				  "notify::style-scheme",
				  G_CALLBACK (buffer_style_scheme_changed_cb),
				  view);

		g_signal_connect (buffer,
				  "notify::implicit-trailing-newline",
				  G_CALLBACK (implicit_trailing_newline_changed_cb),
				  view);

		buffer_internal = _gtk_source_buffer_internal_get_from_buffer (view->priv->source_buffer);

		g_signal_connect (buffer_internal,
				  "search-start",
				  G_CALLBACK (search_start_cb),
				  view);
	}

	gtk_source_view_update_style_scheme (view);
}

static void
scroll_to_insert (GtkSourceView *view,
		  GtkTextBuffer *buffer)
{
	GtkTextMark *insert;
	GtkTextIter iter;
	GdkRectangle visible, location;

	insert = gtk_text_buffer_get_insert (buffer);
	gtk_text_buffer_get_iter_at_mark (buffer, &iter, insert);

	gtk_text_view_get_visible_rect (GTK_TEXT_VIEW (view), &visible);
	gtk_text_view_get_iter_location (GTK_TEXT_VIEW (view), &iter, &location);

	if (location.y < visible.y || visible.y + visible.height < location.y)
	{
		gtk_text_view_scroll_to_mark (GTK_TEXT_VIEW (view),
					      insert,
					      0.0,
					      TRUE,
					      0.5, 0.5);
	}
	else if (location.x < visible.x || visible.x + visible.width < location.x)
	{
		gdouble position;
		GtkAdjustment *adjustment;

		/* We revert the vertical position of the view because
		 * _scroll_to_iter will cause it to move and the
		 * insert mark is already visible vertically. */

		adjustment = gtk_scrollable_get_vadjustment (GTK_SCROLLABLE (view));
		position = gtk_adjustment_get_value (adjustment);

		/* Must use _to_iter as _to_mark scrolls in an
		 * idle handler and would prevent use from
		 * reverting the vertical position of the view. */
		gtk_text_view_scroll_to_iter (GTK_TEXT_VIEW (view),
					      &iter,
					      0.0,
					      TRUE,
					      0.5, 0.0);

		gtk_adjustment_set_value (adjustment, position);
	}
}

static void
gtk_source_view_undo (GtkSourceView *view)
{
	GtkTextBuffer *buffer;

	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	if (gtk_text_view_get_editable (GTK_TEXT_VIEW (view)) &&
	    GTK_SOURCE_IS_BUFFER (buffer) &&
	    gtk_source_buffer_can_undo (GTK_SOURCE_BUFFER (buffer)))
	{
		gtk_source_buffer_undo (GTK_SOURCE_BUFFER (buffer));
		scroll_to_insert (view, buffer);
	}
}

static void
gtk_source_view_redo (GtkSourceView *view)
{
	GtkTextBuffer *buffer;

	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	if (gtk_text_view_get_editable (GTK_TEXT_VIEW (view)) &&
	    GTK_SOURCE_IS_BUFFER (buffer) &&
	    gtk_source_buffer_can_redo (GTK_SOURCE_BUFFER (buffer)))
	{
		gtk_source_buffer_redo (GTK_SOURCE_BUFFER (buffer));
		scroll_to_insert (view, buffer);
	}
}

static void
gtk_source_view_show_completion_real (GtkSourceView *view)
{
	GtkSourceCompletion *completion;
	GtkSourceCompletionContext *context;

	completion = gtk_source_view_get_completion (view);
	context = gtk_source_completion_create_context (completion, NULL);

	gtk_source_completion_show (completion,
	                            gtk_source_completion_get_providers (completion),
	                            context);
}

static void
menu_item_activate_change_case_cb (GtkWidget   *menu_item,
				   GtkTextView *text_view)
{
	GtkTextBuffer *buffer;
	GtkTextIter start, end;

	buffer = gtk_text_view_get_buffer (text_view);
	if (!GTK_SOURCE_IS_BUFFER (buffer))
	{
		return;
	}

	if (gtk_text_buffer_get_selection_bounds (buffer, &start, &end))
	{
		GtkSourceChangeCaseType case_type;

		case_type = GPOINTER_TO_INT (g_object_get_data (G_OBJECT (menu_item), "change-case"));
		gtk_source_buffer_change_case (GTK_SOURCE_BUFFER (buffer), case_type, &start, &end);
	}
}

static void
menu_item_activate_cb (GtkWidget   *menu_item,
		       GtkTextView *text_view)
{
	const gchar *gtksignal;

	gtksignal = g_object_get_data (G_OBJECT (menu_item), "gtk-signal");
	g_signal_emit_by_name (G_OBJECT (text_view), gtksignal);
}

static void
gtk_source_view_populate_popup (GtkTextView *text_view,
				GtkWidget   *popup)
{
	GtkTextBuffer *buffer;
	GtkMenuShell *menu;
	GtkWidget *menu_item;
	GtkMenuShell *case_menu;

	buffer = gtk_text_view_get_buffer (text_view);
	if (!GTK_SOURCE_IS_BUFFER (buffer))
	{
		return;
	}

	if (!GTK_IS_MENU_SHELL (popup))
	{
		return;
	}

	menu = GTK_MENU_SHELL (popup);

	if (_gtk_source_buffer_is_undo_redo_enabled (GTK_SOURCE_BUFFER (buffer)))
	{
		/* separator */
		menu_item = gtk_separator_menu_item_new ();
		gtk_menu_shell_prepend (menu, menu_item);
		gtk_widget_show (menu_item);

		/* create redo menu_item. */
		menu_item = gtk_menu_item_new_with_mnemonic (_("_Redo"));
		g_object_set_data (G_OBJECT (menu_item), "gtk-signal", (gpointer)"redo");
		g_signal_connect (G_OBJECT (menu_item), "activate",
				  G_CALLBACK (menu_item_activate_cb), text_view);
		gtk_menu_shell_prepend (menu, menu_item);
		gtk_widget_set_sensitive (menu_item,
					  (gtk_text_view_get_editable (text_view) &&
					   gtk_source_buffer_can_redo (GTK_SOURCE_BUFFER (buffer))));
		gtk_widget_show (menu_item);

		/* create undo menu_item. */
		menu_item = gtk_menu_item_new_with_mnemonic (_("_Undo"));
		g_object_set_data (G_OBJECT (menu_item), "gtk-signal", (gpointer)"undo");
		g_signal_connect (G_OBJECT (menu_item), "activate",
				  G_CALLBACK (menu_item_activate_cb), text_view);
		gtk_menu_shell_prepend (menu, menu_item);
		gtk_widget_set_sensitive (menu_item,
					  (gtk_text_view_get_editable (text_view) &&
					   gtk_source_buffer_can_undo (GTK_SOURCE_BUFFER (buffer))));
		gtk_widget_show (menu_item);
	}

	/* separator */
	menu_item = gtk_separator_menu_item_new ();
	gtk_menu_shell_append (menu, menu_item);
	gtk_widget_show (menu_item);

	/* create change case menu */
	case_menu = GTK_MENU_SHELL (gtk_menu_new ());

	menu_item = gtk_menu_item_new_with_mnemonic (_("All _Upper Case"));
	g_object_set_data (G_OBJECT (menu_item), "change-case", GINT_TO_POINTER(GTK_SOURCE_CHANGE_CASE_UPPER));
	g_signal_connect (G_OBJECT (menu_item), "activate",
			  G_CALLBACK (menu_item_activate_change_case_cb), text_view);
	gtk_menu_shell_append (case_menu, menu_item);
	gtk_widget_set_sensitive (menu_item,
				  (gtk_text_view_get_editable (text_view) &&
				   gtk_text_buffer_get_has_selection (buffer)));
	gtk_widget_show (menu_item);

	menu_item = gtk_menu_item_new_with_mnemonic (_("All _Lower Case"));
	g_object_set_data (G_OBJECT (menu_item), "change-case", GINT_TO_POINTER(GTK_SOURCE_CHANGE_CASE_LOWER));
	g_signal_connect (G_OBJECT (menu_item), "activate",
			  G_CALLBACK (menu_item_activate_change_case_cb), text_view);
	gtk_menu_shell_append (case_menu, menu_item);
	gtk_widget_set_sensitive (menu_item,
				  (gtk_text_view_get_editable (text_view) &&
				   gtk_text_buffer_get_has_selection (buffer)));
	gtk_widget_show (menu_item);

	menu_item = gtk_menu_item_new_with_mnemonic (_("_Invert Case"));
	g_object_set_data (G_OBJECT (menu_item), "change-case", GINT_TO_POINTER(GTK_SOURCE_CHANGE_CASE_TOGGLE));
	g_signal_connect (G_OBJECT (menu_item), "activate",
			  G_CALLBACK (menu_item_activate_change_case_cb), text_view);
	gtk_menu_shell_append (case_menu, menu_item);
	gtk_widget_set_sensitive (menu_item,
				  (gtk_text_view_get_editable (text_view) &&
				   gtk_text_buffer_get_has_selection (buffer)));
	gtk_widget_show (menu_item);

	menu_item = gtk_menu_item_new_with_mnemonic (_("_Title Case"));
	g_object_set_data (G_OBJECT (menu_item), "change-case", GINT_TO_POINTER(GTK_SOURCE_CHANGE_CASE_TITLE));
	g_signal_connect (G_OBJECT (menu_item), "activate",
			  G_CALLBACK (menu_item_activate_change_case_cb), text_view);
	gtk_menu_shell_append (case_menu, menu_item);
	gtk_widget_set_sensitive (menu_item,
				  (gtk_text_view_get_editable (text_view) &&
				   gtk_text_buffer_get_has_selection (buffer)));
	gtk_widget_show (menu_item);

	menu_item = gtk_menu_item_new_with_mnemonic (_("C_hange Case"));
	gtk_menu_item_set_submenu (GTK_MENU_ITEM (menu_item), GTK_WIDGET (case_menu));
	gtk_menu_shell_append (menu, menu_item);
	gtk_widget_set_sensitive (menu_item,
				  (gtk_text_view_get_editable (text_view) &&
				   gtk_text_buffer_get_has_selection (buffer)));
	gtk_widget_show (menu_item);
}

static void
move_cursor (GtkTextView       *text_view,
	     const GtkTextIter *new_location,
	     gboolean           extend_selection)
{
	GtkTextBuffer *buffer = gtk_text_view_get_buffer (text_view);
	GtkTextMark *insert = gtk_text_buffer_get_insert (buffer);

	if (extend_selection)
	{
		gtk_text_buffer_move_mark (buffer, insert, new_location);
	}
	else
	{
		gtk_text_buffer_place_cursor (buffer, new_location);
	}

	gtk_text_view_scroll_mark_onscreen (text_view, insert);
}

static void
move_to_first_char (GtkTextView *text_view,
		    GtkTextIter *iter,
		    gboolean     display_line)
{
	GtkTextIter last;

	last = *iter;

	if (display_line)
	{
		gtk_text_view_backward_display_line_start (text_view, iter);
		gtk_text_view_forward_display_line_end (text_view, &last);
	}
	else
	{
		gtk_text_iter_set_line_offset (iter, 0);

		if (!gtk_text_iter_ends_line (&last))
		{
			gtk_text_iter_forward_to_line_end (&last);
		}
	}


	while (gtk_text_iter_compare (iter, &last) < 0)
	{
		gunichar c;

		c = gtk_text_iter_get_char (iter);

		if (g_unichar_isspace (c))
		{
			if (!gtk_text_iter_forward_visible_cursor_position (iter))
			{
				break;
			}
		}
		else
		{
			break;
		}
	}
}

static void
move_to_last_char (GtkTextView *text_view,
		   GtkTextIter *iter,
		   gboolean     display_line)
{
	GtkTextIter first;

	first = *iter;

	if (display_line)
	{
		gtk_text_view_forward_display_line_end (text_view, iter);
		gtk_text_view_backward_display_line_start (text_view, &first);
	}
	else
	{
		if (!gtk_text_iter_ends_line (iter))
		{
			gtk_text_iter_forward_to_line_end (iter);
		}

		gtk_text_iter_set_line_offset (&first, 0);
	}

	while (gtk_text_iter_compare (iter, &first) > 0)
	{
		gunichar c;

		if (!gtk_text_iter_backward_visible_cursor_position (iter))
		{
			break;
		}

		c = gtk_text_iter_get_char (iter);

		if (!g_unichar_isspace (c))
		{
			/* We've gone one cursor position too far. */
			gtk_text_iter_forward_visible_cursor_position (iter);
			break;
		}
	}
}

static void
do_cursor_move_home_end (GtkTextView *text_view,
			 GtkTextIter *cur,
			 GtkTextIter *iter,
			 gboolean     extend_selection,
			 gint         count)
{
	/* if we are clearing selection, we need to move_cursor even
	 * if we are at proper iter because selection_bound may need
	 * to be moved */
	if (!gtk_text_iter_equal (cur, iter) || !extend_selection)
	{
		move_cursor (text_view, iter, extend_selection);
		g_signal_emit (text_view, signals[SMART_HOME_END], 0, iter, count);
	}
}

/* Returns %TRUE if handled. */
static gboolean
move_cursor_smart_home_end (GtkTextView     *text_view,
			    GtkMovementStep  step,
			    gint             count,
			    gboolean         extend_selection)
{
	GtkSourceView *source_view = GTK_SOURCE_VIEW (text_view);
	GtkTextBuffer *buffer = gtk_text_view_get_buffer (text_view);
	gboolean move_display_line;
	GtkTextMark *mark;
	GtkTextIter cur;
	GtkTextIter iter;

	g_assert (step == GTK_MOVEMENT_DISPLAY_LINE_ENDS ||
		  step == GTK_MOVEMENT_PARAGRAPH_ENDS);

	move_display_line = step == GTK_MOVEMENT_DISPLAY_LINE_ENDS;

	mark = gtk_text_buffer_get_insert (buffer);
	gtk_text_buffer_get_iter_at_mark (buffer, &cur, mark);
	iter = cur;

	if (count == -1)
	{
		gboolean at_home;

		move_to_first_char (text_view, &iter, move_display_line);

		if (move_display_line)
		{
			at_home = gtk_text_view_starts_display_line (text_view, &cur);
		}
		else
		{
			at_home = gtk_text_iter_starts_line (&cur);
		}

		switch (source_view->priv->smart_home_end)
		{
			case GTK_SOURCE_SMART_HOME_END_BEFORE:
				if (!gtk_text_iter_equal (&cur, &iter) || at_home)
				{
					do_cursor_move_home_end (text_view,
					                         &cur,
					                         &iter,
					                         extend_selection,
					                         count);
					return TRUE;
				}
				break;

			case GTK_SOURCE_SMART_HOME_END_AFTER:
				if (at_home)
				{
					do_cursor_move_home_end (text_view,
					                         &cur,
					                         &iter,
					                         extend_selection,
					                         count);
					return TRUE;
				}
				break;

			case GTK_SOURCE_SMART_HOME_END_ALWAYS:
				do_cursor_move_home_end (text_view,
				                         &cur,
				                         &iter,
				                         extend_selection,
				                         count);
				return TRUE;

			case GTK_SOURCE_SMART_HOME_END_DISABLED:
			default:
				break;
		}
	}
	else if (count == 1)
	{
		gboolean at_end;

		move_to_last_char (text_view, &iter, move_display_line);

		if (move_display_line)
		{
			GtkTextIter display_end;
			display_end = cur;

			gtk_text_view_forward_display_line_end (text_view, &display_end);
			at_end = gtk_text_iter_equal (&cur, &display_end);
		}
		else
		{
			at_end = gtk_text_iter_ends_line (&cur);
		}

		switch (source_view->priv->smart_home_end)
		{
			case GTK_SOURCE_SMART_HOME_END_BEFORE:
				if (!gtk_text_iter_equal (&cur, &iter) || at_end)
				{
					do_cursor_move_home_end (text_view,
					                         &cur,
					                         &iter,
					                         extend_selection,
					                         count);
					return TRUE;
				}
				break;

			case GTK_SOURCE_SMART_HOME_END_AFTER:
				if (at_end)
				{
					do_cursor_move_home_end (text_view,
					                         &cur,
					                         &iter,
					                         extend_selection,
					                         count);
					return TRUE;
				}
				break;

			case GTK_SOURCE_SMART_HOME_END_ALWAYS:
				do_cursor_move_home_end (text_view,
				                         &cur,
				                         &iter,
				                         extend_selection,
				                         count);
				return TRUE;

			case GTK_SOURCE_SMART_HOME_END_DISABLED:
			default:
				break;
		}
	}

	return FALSE;
}

static void
move_cursor_words (GtkTextView *text_view,
		   gint         count,
		   gboolean     extend_selection)
{
	GtkTextBuffer *buffer;
	GtkTextIter insert;
	GtkTextIter newplace;
	GtkTextIter line_start;
	GtkTextIter line_end;
	gchar *line_text;

	buffer = gtk_text_view_get_buffer (text_view);

	gtk_text_buffer_get_iter_at_mark (buffer,
					  &insert,
					  gtk_text_buffer_get_insert (buffer));

	line_start = line_end = newplace = insert;

	/* Get the text of the current line for RTL analysis */
	gtk_text_iter_set_line_offset (&line_start, 0);
	gtk_text_iter_forward_line (&line_end);
	line_text = gtk_text_iter_get_visible_text (&line_start, &line_end);

	/* Swap direction for RTL to maintain visual cursor movement.
	 * Otherwise, cursor will move in opposite direction which is counter
	 * intuitve and causes confusion for RTL users.
	 */
	if (pango_find_base_dir (line_text, -1) == PANGO_DIRECTION_RTL)
	{
		count *= -1;
	}

	g_free (line_text);

	if (count < 0)
	{
		if (!_gtk_source_iter_backward_visible_word_starts (&newplace, -count))
		{
			gtk_text_iter_set_line_offset (&newplace, 0);
		}
	}
	else if (count > 0)
	{
		if (!_gtk_source_iter_forward_visible_word_ends (&newplace, count))
		{
			gtk_text_iter_forward_to_line_end (&newplace);
		}
	}

	move_cursor (text_view, &newplace, extend_selection);
}

static void
gtk_source_view_move_cursor (GtkTextView     *text_view,
			     GtkMovementStep  step,
			     gint             count,
			     gboolean         extend_selection)
{
	if (!gtk_text_view_get_cursor_visible (text_view))
	{
		goto chain_up;
	}

	gtk_text_view_reset_im_context (text_view);

	switch (step)
	{
		case GTK_MOVEMENT_DISPLAY_LINE_ENDS:
		case GTK_MOVEMENT_PARAGRAPH_ENDS:
			if (move_cursor_smart_home_end (text_view, step, count, extend_selection))
			{
				return;
			}
			break;

		case GTK_MOVEMENT_WORDS:
			move_cursor_words (text_view, count, extend_selection);
			return;

		case GTK_MOVEMENT_LOGICAL_POSITIONS:
		case GTK_MOVEMENT_VISUAL_POSITIONS:
		case GTK_MOVEMENT_DISPLAY_LINES:
		case GTK_MOVEMENT_PARAGRAPHS:
		case GTK_MOVEMENT_PAGES:
		case GTK_MOVEMENT_BUFFER_ENDS:
		case GTK_MOVEMENT_HORIZONTAL_PAGES:
		default:
			break;
	}

chain_up:
	GTK_TEXT_VIEW_CLASS (gtk_source_view_parent_class)->move_cursor (text_view,
									 step,
									 count,
									 extend_selection);
}

static void
gtk_source_view_delete_from_cursor (GtkTextView   *text_view,
				    GtkDeleteType  type,
				    gint           count)
{
	GtkTextBuffer *buffer = gtk_text_view_get_buffer (text_view);
	GtkTextIter insert;
	GtkTextIter start;
	GtkTextIter end;

	if (type != GTK_DELETE_WORD_ENDS)
	{
		GTK_TEXT_VIEW_CLASS (gtk_source_view_parent_class)->delete_from_cursor (text_view,
											type,
											count);
		return;
	}

	gtk_text_view_reset_im_context (text_view);

	gtk_text_buffer_get_iter_at_mark (buffer,
					  &insert,
					  gtk_text_buffer_get_insert (buffer));

	start = insert;
	end = insert;

	if (count > 0)
	{
		if (!_gtk_source_iter_forward_visible_word_ends (&end, count))
		{
			gtk_text_iter_forward_to_line_end (&end);
		}
	}
	else
	{
		if (!_gtk_source_iter_backward_visible_word_starts (&start, -count))
		{
			gtk_text_iter_set_line_offset (&start, 0);
		}
	}

	gtk_text_buffer_delete_interactive (buffer, &start, &end,
					    gtk_text_view_get_editable (text_view));
}

static gboolean
gtk_source_view_extend_selection (GtkTextView            *text_view,
				  GtkTextExtendSelection  granularity,
				  const GtkTextIter      *location,
				  GtkTextIter            *start,
				  GtkTextIter            *end)
{
	if (granularity == GTK_TEXT_EXTEND_SELECTION_WORD)
	{
		_gtk_source_iter_extend_selection_word (location, start, end);
		return GDK_EVENT_STOP;
	}

	return GTK_TEXT_VIEW_CLASS (gtk_source_view_parent_class)->extend_selection (text_view,
										     granularity,
										     location,
										     start,
										     end);
}

static void
gtk_source_view_ensure_redrawn_rect_is_highlighted (GtkSourceView *view,
						    cairo_t       *cr)
{
	GdkRectangle clip;
	GtkTextIter iter1, iter2;

	if (view->priv->source_buffer == NULL ||
	    !gdk_cairo_get_clip_rectangle (cr, &clip))
	{
		return;
	}

	gtk_text_view_get_line_at_y (GTK_TEXT_VIEW (view), &iter1, clip.y, NULL);
	gtk_text_iter_backward_line (&iter1);
	gtk_text_view_get_line_at_y (GTK_TEXT_VIEW (view), &iter2, clip.y + clip.height, NULL);
	gtk_text_iter_forward_line (&iter2);

	DEBUG ({
		g_print ("    draw area: %d - %d\n", clip.y, clip.y + clip.height);
		g_print ("    lines to update: %d - %d\n",
			 gtk_text_iter_get_line (&iter1),
			 gtk_text_iter_get_line (&iter2));
	});

	_gtk_source_buffer_update_syntax_highlight (view->priv->source_buffer,
						    &iter1, &iter2, FALSE);
	_gtk_source_buffer_update_search_highlight (view->priv->source_buffer,
						    &iter1, &iter2, FALSE);
}

/* This function is taken from gtk+/tests/testtext.c */
static void
gtk_source_view_get_lines (GtkTextView *text_view,
			   gint         first_y,
			   gint         last_y,
			   GArray      *buffer_coords,
			   GArray      *line_heights,
			   GArray      *numbers,
			   gint        *countp)
{
	GtkTextIter iter;
	gint count;
	gint last_line_num = -1;

	g_array_set_size (buffer_coords, 0);
	g_array_set_size (numbers, 0);
	if (line_heights != NULL)
		g_array_set_size (line_heights, 0);

	/* Get iter at first y */
	gtk_text_view_get_line_at_y (text_view, &iter, first_y, NULL);

	/* For each iter, get its location and add it to the arrays.
	 * Stop when we pass last_y */
	count = 0;

	while (!gtk_text_iter_is_end (&iter))
	{
		gint y, height;

		gtk_text_view_get_line_yrange (text_view, &iter, &y, &height);

		g_array_append_val (buffer_coords, y);
		if (line_heights)
		{
			g_array_append_val (line_heights, height);
		}

		last_line_num = gtk_text_iter_get_line (&iter);
		g_array_append_val (numbers, last_line_num);

		++count;

		if ((y + height) >= last_y)
			break;

		gtk_text_iter_forward_line (&iter);
	}

	if (gtk_text_iter_is_end (&iter))
	{
		gint y, height;
		gint line_num;

		gtk_text_view_get_line_yrange (text_view, &iter, &y, &height);

		line_num = gtk_text_iter_get_line (&iter);

		if (line_num != last_line_num)
		{
			g_array_append_val (buffer_coords, y);
			if (line_heights)
				g_array_append_val (line_heights, height);
			g_array_append_val (numbers, line_num);
			++count;
		}
	}

	*countp = count;
}

/* Another solution to paint the line background is to use the
 * GtkTextTag:paragraph-background property. But there are several issues:
 * - GtkTextTags are per buffer, not per view. It's better to keep the line
 *   highlighting per view.
 * - There is a problem for empty lines: a text tag can not be applied to an
 *   empty region. And it can not be worked around easily for the last line.
 *
 * See https://bugzilla.gnome.org/show_bug.cgi?id=310847 for more details.
 */
static void
gtk_source_view_paint_line_background (GtkTextView    *text_view,
				       cairo_t        *cr,
				       int             y, /* in buffer coordinates */
				       int             height,
				       const GdkRGBA  *color)
{
	gdouble x1, y1, x2, y2;

	cairo_save (cr);
	cairo_clip_extents (cr, &x1, &y1, &x2, &y2);

	gdk_cairo_set_source_rgba (cr, (GdkRGBA *)color);
	cairo_set_line_width (cr, 1);
	cairo_rectangle (cr, x1 + .5, y + .5, x2 - x1 - 1, height - 1);
	cairo_stroke_preserve (cr);
	cairo_fill (cr);
	cairo_restore (cr);
}

static void
gtk_source_view_paint_marks_background (GtkSourceView *view,
					cairo_t       *cr)
{
	GtkTextView *text_view;
	GdkRectangle clip;
	GArray *numbers;
	GArray *pixels;
	GArray *heights;
	gint y1, y2;
	gint count;
	gint i;

	if (view->priv->source_buffer == NULL ||
	    !gdk_cairo_get_clip_rectangle (cr, &clip))
	{
		return;
	}

	text_view = GTK_TEXT_VIEW (view);

	y1 = clip.y;
	y2 = y1 + clip.height;

	numbers = g_array_new (FALSE, FALSE, sizeof (gint));
	pixels = g_array_new (FALSE, FALSE, sizeof (gint));
	heights = g_array_new (FALSE, FALSE, sizeof (gint));

	/* get the line numbers and y coordinates. */
	gtk_source_view_get_lines (text_view,
	                           y1,
	                           y2,
	                           pixels,
	                           heights,
	                           numbers,
	                           &count);

	if (count == 0)
	{
		gint n = 0;
		gint y;
		gint height;
		GtkTextIter iter;

		gtk_text_buffer_get_start_iter (gtk_text_view_get_buffer (text_view), &iter);
		gtk_text_view_get_line_yrange (text_view, &iter, &y, &height);

		g_array_append_val (pixels, y);
		g_array_append_val (pixels, height);
		g_array_append_val (numbers, n);
		count = 1;
	}

	DEBUG ({
		g_print ("    Painting marks background for line numbers %d - %d\n",
		         g_array_index (numbers, gint, 0),
		         g_array_index (numbers, gint, count - 1));
	});

	for (i = 0; i < count; ++i)
	{
		gint line_to_paint;
		GSList *marks;
		GdkRGBA background;
		int priority;

		line_to_paint = g_array_index (numbers, gint, i);

		marks = gtk_source_buffer_get_source_marks_at_line (view->priv->source_buffer,
		                                                    line_to_paint,
		                                                    NULL);

		priority = -1;

		while (marks != NULL)
		{
			GtkSourceMarkAttributes *attrs;
			gint prio;
			GdkRGBA bg;

			attrs = gtk_source_view_get_mark_attributes (view,
			                                             gtk_source_mark_get_category (marks->data),
			                                             &prio);

			if (attrs != NULL &&
			    prio > priority &&
			    gtk_source_mark_attributes_get_background (attrs, &bg))
			{
				priority = prio;
				background = bg;
			}

			marks = g_slist_delete_link (marks, marks);
		}

		if (priority != -1)
		{
			gtk_source_view_paint_line_background (text_view,
			                                       cr,
			                                       g_array_index (pixels, gint, i),
			                                       g_array_index (heights, gint, i),
			                                       &background);
		}
	}

	g_array_free (heights, TRUE);
	g_array_free (pixels, TRUE);
	g_array_free (numbers, TRUE);
}

static void
gtk_source_view_paint_right_margin (GtkSourceView *view,
				    cairo_t       *cr)
{
	GdkRectangle clip;
	gdouble x;

	GtkTextView *text_view = GTK_TEXT_VIEW (view);

#ifdef ENABLE_PROFILE
	static GTimer *timer = NULL;

	if (timer == NULL)
	{
		timer = g_timer_new ();
	}

	g_timer_start (timer);
#endif

	g_return_if_fail (view->priv->right_margin_line_color != NULL);

	if (!gdk_cairo_get_clip_rectangle (cr, &clip))
	{
		return;
	}

	if (view->priv->cached_right_margin_pos < 0)
	{
		view->priv->cached_right_margin_pos =
			calculate_real_tab_width (view,
						  view->priv->right_margin_pos,
						  '_');
	}

	x = view->priv->cached_right_margin_pos + gtk_text_view_get_left_margin (text_view);

	cairo_save (cr);
	cairo_set_line_width (cr, 1.0);

	if (x + 1 >= clip.x && x <= clip.x + clip.width)
	{
		cairo_move_to (cr, x + 0.5, clip.y);
		cairo_line_to (cr, x + 0.5, clip.y + clip.height);

		gdk_cairo_set_source_rgba (cr, view->priv->right_margin_line_color);
		cairo_stroke (cr);
	}

	/* Only draw the overlay when the style scheme explicitly sets it. */
	if (view->priv->right_margin_overlay_color != NULL && clip.x + clip.width > x + 1)
	{
		/* Draw the rectangle next to the line (x+1). */
		cairo_rectangle (cr,
				 x + 1, clip.y,
				 clip.x + clip.width - (x + 1), clip.height);

		gdk_cairo_set_source_rgba (cr, view->priv->right_margin_overlay_color);
		cairo_fill (cr);
	}

	cairo_restore (cr);

	PROFILE ({
		g_timer_stop (timer);
		g_print ("    gtk_source_view_paint_right_margin time: "
			 "%g (sec * 1000)\n",
			 g_timer_elapsed (timer, NULL) * 1000);
	});
}

static gint
realign (gint  offset,
	 guint align)
{
	if (offset > 0 && align > 0)
	{
		gint padding;

		padding = (align - (offset % align)) % align;
		return offset + padding;
	}

	return 0;
}

static void
gtk_source_view_paint_background_pattern_grid (GtkSourceView *view,
					       cairo_t       *cr)
{
	GdkRectangle clip;
	gint x, y, x2, y2;
	PangoContext *context;
	PangoLayout *layout;
	gint grid_width = 16;
	gint grid_height = 16;

	context = gtk_widget_get_pango_context (GTK_WIDGET (view));
	layout = pango_layout_new (context);
	pango_layout_set_text (layout, "X", 1);
	pango_layout_get_pixel_size (layout, &grid_width, &grid_height);
	g_object_unref (layout);

	/* each character becomes 2 stacked boxes. */
	grid_height = MAX (1, grid_height / 2);
	grid_width = MAX (1, grid_width);

	cairo_save (cr);

	gdk_cairo_get_clip_rectangle (cr, &clip);

	cairo_set_line_width (cr, 1.0);
	gdk_cairo_set_source_rgba (cr, &view->priv->background_pattern_color);

	/* Align our drawing position with a multiple of the grid size. */
	x = realign (clip.x - grid_width, grid_width);
	y = realign (clip.y - grid_height, grid_height);
	x2 = realign (x + clip.width + grid_width * 2, grid_width);
	y2 = realign (y + clip.height + grid_height * 2, grid_height);

	for (; x <= x2; x += grid_width)
	{
		cairo_move_to (cr, x + .5, clip.y - .5);
		cairo_line_to (cr, x + .5, clip.y + clip.height - .5);
	}

	for (; y <= y2; y += grid_height)
	{
		cairo_move_to (cr, clip.x + .5, y - .5);
		cairo_line_to (cr, clip.x + clip.width + .5, y - .5);
	}

	cairo_stroke (cr);
	cairo_restore (cr);
}

static void
gtk_source_view_paint_current_line_highlight (GtkSourceView *view,
					      cairo_t       *cr)
{
	GtkTextBuffer *buffer;
	GtkTextIter cur;
	gint y;
	gint height;

	buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));
	gtk_text_buffer_get_iter_at_mark (buffer,
					  &cur,
					  gtk_text_buffer_get_insert (buffer));
	gtk_text_view_get_line_yrange (GTK_TEXT_VIEW (view), &cur, &y, &height);

	gtk_source_view_paint_line_background (GTK_TEXT_VIEW (view),
					       cr,
					       y, height,
					       &view->priv->current_line_color);
}

static void
gtk_source_view_draw_layer (GtkTextView      *text_view,
			    GtkTextViewLayer  layer,
			    cairo_t          *cr)
{
	GtkSourceView *view;

	view = GTK_SOURCE_VIEW (text_view);

	cairo_save (cr);

	if (layer == GTK_TEXT_VIEW_LAYER_BELOW_TEXT)
	{
		gtk_source_view_ensure_redrawn_rect_is_highlighted (view, cr);

		if (view->priv->background_pattern == GTK_SOURCE_BACKGROUND_PATTERN_TYPE_GRID &&
		    view->priv->background_pattern_color_set)
		{
			gtk_source_view_paint_background_pattern_grid (view, cr);
		}

		if (gtk_widget_is_sensitive (GTK_WIDGET (view)) &&
		    view->priv->highlight_current_line &&
		    view->priv->current_line_color_set)
		{
			gtk_source_view_paint_current_line_highlight (view, cr);
		}

		gtk_source_view_paint_marks_background (view, cr);
	}
	else if (layer == GTK_TEXT_VIEW_LAYER_ABOVE_TEXT)
	{
		/* Draw the right margin vertical line + overlay. */
		if (view->priv->show_right_margin)
		{
			gtk_source_view_paint_right_margin (view, cr);
		}

		if (view->priv->space_drawer != NULL)
		{
			_gtk_source_space_drawer_draw (view->priv->space_drawer, view, cr);
		}
	}

	cairo_restore (cr);
}

static gboolean
gtk_source_view_draw (GtkWidget *widget,
		      cairo_t   *cr)
{
	GtkSourceView *view = GTK_SOURCE_VIEW (widget);
	gboolean event_handled;

#ifdef ENABLE_PROFILE
	static GTimer *timer = NULL;
	if (timer == NULL)
	{
		timer = g_timer_new ();
	}

	g_timer_start (timer);
#endif

	DEBUG ({
		g_print ("> gtk_source_view_draw start\n");
	});

	event_handled = GTK_WIDGET_CLASS (gtk_source_view_parent_class)->draw (widget, cr);

	if (view->priv->left_gutter != NULL)
	{
		_gtk_source_gutter_draw (view->priv->left_gutter, view, cr);
	}

	if (view->priv->right_gutter != NULL)
	{
		_gtk_source_gutter_draw (view->priv->right_gutter, view, cr);
	}

	PROFILE ({
		g_timer_stop (timer);
		g_print ("    gtk_source_view_draw time: %g (sec * 1000)\n",
		         g_timer_elapsed (timer, NULL) * 1000);
	});
	DEBUG ({
		g_print ("> gtk_source_view_draw end\n");
	});

	return event_handled;
}

/* This is a pretty important function... We call it when the tab_stop is changed,
 * and when the font is changed.
 * NOTE: You must change this with the default font for now...
 * It may be a good idea to set the tab_width for each GtkTextTag as well
 * based on the font that we set at creation time
 * something like style_cache_set_tabs_from_font or the like.
 * Now, this *may* not be necessary because most tabs wont be inside of another highlight,
 * except for things like multi-line comments (which will usually have an italic font which
 * may or may not be a different size than the standard one), or if some random language
 * definition decides that it would be spiffy to have a bg color for "start of line" whitespace
 * "^\(\t\| \)+" would probably do the trick for that.
 */
static gint
calculate_real_tab_width (GtkSourceView *view, guint tab_size, gchar c)
{
	PangoLayout *layout;
	gchar *tab_string;
	gint tab_width = 0;

	if (tab_size == 0)
	{
		return -1;
	}

	tab_string = g_strnfill (tab_size, c);
	layout = gtk_widget_create_pango_layout (GTK_WIDGET (view), tab_string);
	g_free (tab_string);

	if (layout != NULL)
	{
		pango_layout_get_pixel_size (layout, &tab_width, NULL);
		g_object_unref (G_OBJECT (layout));
	}
	else
	{
		tab_width = -1;
	}

	return tab_width;
}

static GtkTextBuffer *
gtk_source_view_create_buffer (GtkTextView *text_view)
{
	return GTK_TEXT_BUFFER (gtk_source_buffer_new (NULL));
}


/* ----------------------------------------------------------------------
 * Public interface
 * ----------------------------------------------------------------------
 */

/**
 * gtk_source_view_new:
 *
 * Creates a new #GtkSourceView.
 *
 * By default, an empty #GtkSourceBuffer will be lazily created and can be
 * retrieved with gtk_text_view_get_buffer().
 *
 * If you want to specify your own buffer, either override the
 * #GtkTextViewClass create_buffer factory method, or use
 * gtk_source_view_new_with_buffer().
 *
 * Returns: a new #GtkSourceView.
 */
GtkWidget *
gtk_source_view_new (void)
{
	return g_object_new (GTK_SOURCE_TYPE_VIEW, NULL);
}

/**
 * gtk_source_view_new_with_buffer:
 * @buffer: a #GtkSourceBuffer.
 *
 * Creates a new #GtkSourceView widget displaying the buffer
 * @buffer. One buffer can be shared among many widgets.
 *
 * Returns: a new #GtkSourceView.
 */
GtkWidget *
gtk_source_view_new_with_buffer (GtkSourceBuffer *buffer)
{
	g_return_val_if_fail (GTK_SOURCE_IS_BUFFER (buffer), NULL);

	return g_object_new (GTK_SOURCE_TYPE_VIEW,
			     "buffer", buffer,
			     NULL);
}

/**
 * gtk_source_view_get_show_line_numbers:
 * @view: a #GtkSourceView.
 *
 * Returns whether line numbers are displayed beside the text.
 *
 * Return value: %TRUE if the line numbers are displayed.
 */
gboolean
gtk_source_view_get_show_line_numbers (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->show_line_numbers;
}

/**
 * gtk_source_view_set_show_line_numbers:
 * @view: a #GtkSourceView.
 * @show: whether line numbers should be displayed.
 *
 * If %TRUE line numbers will be displayed beside the text.
 */
void
gtk_source_view_set_show_line_numbers (GtkSourceView *view,
				       gboolean       show)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	show = show != FALSE;

	if (show == view->priv->show_line_numbers)
	{
		return;
	}

	if (view->priv->line_renderer == NULL)
	{
		GtkSourceGutter *gutter;

		gutter = gtk_source_view_get_gutter (view, GTK_TEXT_WINDOW_LEFT);

		view->priv->line_renderer = gtk_source_gutter_renderer_lines_new ();
		g_object_set (view->priv->line_renderer,
		              "alignment-mode", GTK_SOURCE_GUTTER_RENDERER_ALIGNMENT_MODE_FIRST,
		              "yalign", 0.5,
		              "xalign", 1.0,
		              "xpad", 3,
		              NULL);

		gtk_source_gutter_insert (gutter,
		                          view->priv->line_renderer,
		                          GTK_SOURCE_VIEW_GUTTER_POSITION_LINES);
	}

	gtk_source_gutter_renderer_set_visible (view->priv->line_renderer, show);
	view->priv->show_line_numbers = show;

	g_object_notify (G_OBJECT (view), "show_line_numbers");
}

/**
 * gtk_source_view_get_show_line_marks:
 * @view: a #GtkSourceView.
 *
 * Returns whether line marks are displayed beside the text.
 *
 * Return value: %TRUE if the line marks are displayed.
 *
 * Since: 2.2
 */
gboolean
gtk_source_view_get_show_line_marks (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->show_line_marks;
}

static void
gutter_renderer_marks_activate (GtkSourceGutterRenderer *renderer,
				GtkTextIter             *iter,
				const GdkRectangle      *area,
				GdkEvent                *event,
				GtkSourceView           *view)
{
	g_signal_emit (view,
	               signals[LINE_MARK_ACTIVATED],
	               0,
	               iter,
	               event);
}

/**
 * gtk_source_view_set_show_line_marks:
 * @view: a #GtkSourceView.
 * @show: whether line marks should be displayed.
 *
 * If %TRUE line marks will be displayed beside the text.
 *
 * Since: 2.2
 */
void
gtk_source_view_set_show_line_marks (GtkSourceView *view,
				     gboolean       show)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	show = show != FALSE;

	if (show == view->priv->show_line_marks)
	{
		return;
	}

	if (view->priv->marks_renderer == NULL)
	{
		GtkSourceGutter *gutter;

		gutter = gtk_source_view_get_gutter (view, GTK_TEXT_WINDOW_LEFT);

		view->priv->marks_renderer = gtk_source_gutter_renderer_marks_new ();

		gtk_source_gutter_insert (gutter,
		                          view->priv->marks_renderer,
		                          GTK_SOURCE_VIEW_GUTTER_POSITION_MARKS);

		g_signal_connect (view->priv->marks_renderer,
		                  "activate",
		                  G_CALLBACK (gutter_renderer_marks_activate),
		                  view);
	}

	gtk_source_gutter_renderer_set_visible (view->priv->marks_renderer, show);
	view->priv->show_line_marks = show;

	g_object_notify (G_OBJECT (view), "show_line_marks");
}

static gboolean
set_tab_stops_internal (GtkSourceView *view)
{
	PangoTabArray *tab_array;
	gint real_tab_width;

	real_tab_width = calculate_real_tab_width (view, view->priv->tab_width, ' ');

	if (real_tab_width < 0)
	{
		return FALSE;
	}

	tab_array = pango_tab_array_new (1, TRUE);
	pango_tab_array_set_tab (tab_array, 0, PANGO_TAB_LEFT, real_tab_width);

	gtk_text_view_set_tabs (GTK_TEXT_VIEW (view),
				tab_array);
	view->priv->tabs_set = TRUE;

	pango_tab_array_free (tab_array);

	return TRUE;
}

/**
 * gtk_source_view_set_tab_width:
 * @view: a #GtkSourceView.
 * @width: width of tab in characters.
 *
 * Sets the width of tabulation in characters. The #GtkTextBuffer still contains
 * \t characters, but they can take a different visual width in a #GtkSourceView
 * widget.
 */
void
gtk_source_view_set_tab_width (GtkSourceView *view,
			       guint          width)
{
	guint save_width;

	g_return_if_fail (GTK_SOURCE_VIEW (view));
	g_return_if_fail (0 < width && width <= MAX_TAB_WIDTH);

	if (view->priv->tab_width == width)
	{
		return;
	}

	save_width = view->priv->tab_width;
	view->priv->tab_width = width;
	if (set_tab_stops_internal (view))
	{
		g_object_notify (G_OBJECT (view), "tab-width");
	}
	else
	{
		g_warning ("Impossible to set tab width.");
		view->priv->tab_width = save_width;
	}
}

/**
 * gtk_source_view_get_tab_width:
 * @view: a #GtkSourceView.
 *
 * Returns the width of tabulation in characters.
 *
 * Return value: width of tab.
 */
guint
gtk_source_view_get_tab_width (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), DEFAULT_TAB_WIDTH);

	return view->priv->tab_width;
}

/**
 * gtk_source_view_set_indent_width:
 * @view: a #GtkSourceView.
 * @width: indent width in characters.
 *
 * Sets the number of spaces to use for each step of indent when the tab key is
 * pressed. If @width is -1, the value of the #GtkSourceView:tab-width property
 * will be used.
 *
 * The #GtkSourceView:indent-width interacts with the
 * #GtkSourceView:insert-spaces-instead-of-tabs property and
 * #GtkSourceView:tab-width. An example will be clearer: if the
 * #GtkSourceView:indent-width is 4 and
 * #GtkSourceView:tab-width is 8 and
 * #GtkSourceView:insert-spaces-instead-of-tabs is %FALSE, then pressing the tab
 * key at the beginning of a line will insert 4 spaces. So far so good. Pressing
 * the tab key a second time will remove the 4 spaces and insert a \t character
 * instead (since #GtkSourceView:tab-width is 8). On the other hand, if
 * #GtkSourceView:insert-spaces-instead-of-tabs is %TRUE, the second tab key
 * pressed will insert 4 more spaces for a total of 8 spaces in the
 * #GtkTextBuffer.
 *
 * The test-widget program (available in the GtkSourceView repository) may be
 * useful to better understand the indentation settings (enable the space
 * drawing!).
 */
void
gtk_source_view_set_indent_width (GtkSourceView *view,
				  gint           width)
{
	g_return_if_fail (GTK_SOURCE_VIEW (view));
	g_return_if_fail (width == -1 || (0 < width && width <= MAX_INDENT_WIDTH));

	if (view->priv->indent_width != width)
	{
		view->priv->indent_width = width;
		g_object_notify (G_OBJECT (view), "indent-width");
	}
}

/**
 * gtk_source_view_get_indent_width:
 * @view: a #GtkSourceView.
 *
 * Returns the number of spaces to use for each step of indent.
 * See gtk_source_view_set_indent_width() for details.
 *
 * Return value: indent width.
 */
gint
gtk_source_view_get_indent_width (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), 0);

	return view->priv->indent_width;
}

static gchar *
compute_indentation (GtkSourceView *view,
		     GtkTextIter   *cur)
{
	GtkTextIter start;
	GtkTextIter end;
	gunichar ch;

	start = *cur;
	gtk_text_iter_set_line_offset (&start, 0);

	end = start;

	ch = gtk_text_iter_get_char (&end);

	while (g_unichar_isspace (ch) &&
	       (ch != '\n') &&
	       (ch != '\r') &&
	       (gtk_text_iter_compare (&end, cur) < 0))
	{
		if (!gtk_text_iter_forward_char (&end))
		{
			break;
		}

		ch = gtk_text_iter_get_char (&end);
	}

	if (gtk_text_iter_equal (&start, &end))
	{
		return NULL;
	}

	return gtk_text_iter_get_slice (&start, &end);
}

static guint
get_real_indent_width (GtkSourceView *view)
{
	return view->priv->indent_width < 0 ?
	       view->priv->tab_width :
	       (guint) view->priv->indent_width;
}

static gchar *
get_indent_string (guint tabs,
		   guint spaces)
{
	gchar *str;

	str = g_malloc (tabs + spaces + 1);

	if (tabs > 0)
	{
		memset (str, '\t', tabs);
	}

	if (spaces > 0)
	{
		memset (str + tabs, ' ', spaces);
	}

	str[tabs + spaces] = '\0';

	return str;
}

/**
 * gtk_source_view_indent_lines:
 * @view: a #GtkSourceView.
 * @start: #GtkTextIter of the first line to indent
 * @end: #GtkTextIter of the last line to indent
 *
 * Inserts one indentation level at the beginning of the specified lines. The
 * empty lines are not indented.
 *
 * Since: 3.16
 */
void
gtk_source_view_indent_lines (GtkSourceView *view,
			      GtkTextIter   *start,
			      GtkTextIter   *end)
{
	GtkTextBuffer *buf;
	gboolean bracket_hl;
	GtkTextMark *start_mark, *end_mark;
	gint start_line, end_line;
	gchar *tab_buffer = NULL;
	guint tabs = 0;
	guint spaces = 0;
	gint i;

	if (view->priv->completion != NULL)
	{
		gtk_source_completion_block_interactive (view->priv->completion);
	}

	buf = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	bracket_hl = gtk_source_buffer_get_highlight_matching_brackets (GTK_SOURCE_BUFFER (buf));
	gtk_source_buffer_set_highlight_matching_brackets (GTK_SOURCE_BUFFER (buf), FALSE);

	start_mark = gtk_text_buffer_create_mark (buf, NULL, start, FALSE);
	end_mark = gtk_text_buffer_create_mark (buf, NULL, end, FALSE);

	start_line = gtk_text_iter_get_line (start);
	end_line = gtk_text_iter_get_line (end);

	if ((gtk_text_iter_get_visible_line_offset (end) == 0) &&
	    (end_line > start_line))
	{
		end_line--;
	}

	if (view->priv->insert_spaces)
	{
		spaces = get_real_indent_width (view);

		tab_buffer = g_strnfill (spaces, ' ');
	}
	else if (view->priv->indent_width > 0 &&
	         view->priv->indent_width != (gint)view->priv->tab_width)
	{
		guint indent_width;

		indent_width = get_real_indent_width (view);
		spaces = indent_width % view->priv->tab_width;
		tabs = indent_width / view->priv->tab_width;

		tab_buffer = get_indent_string (tabs, spaces);
	}
	else
	{
		tabs = 1;
		tab_buffer = g_strdup ("\t");
	}

	gtk_text_buffer_begin_user_action (buf);

	for (i = start_line; i <= end_line; i++)
	{
		GtkTextIter iter;
		GtkTextIter iter2;
		guint replaced_spaces = 0;

		gtk_text_buffer_get_iter_at_line (buf, &iter, i);

		/* Don't add indentation on completely empty lines, to not add
		 * trailing spaces.
		 * Note that non-empty lines containing only whitespaces are
		 * indented like any other non-empty line, because those lines
		 * already contain trailing spaces, some users use those
		 * whitespaces to more easily insert text at the right place
		 * without the need to insert the indentation each time.
		 */
		if (gtk_text_iter_ends_line (&iter))
		{
			continue;
		}

		/* add spaces always after tabs, to avoid the case
		 * where "\t" becomes "  \t" with no visual difference */
		while (gtk_text_iter_get_char (&iter) == '\t')
		{
			gtk_text_iter_forward_char (&iter);
		}

		/* if tabs are allowed try to merge the spaces
		 * with the tab we are going to insert (if any) */
		iter2 = iter;
		while (!view->priv->insert_spaces &&
		       (gtk_text_iter_get_char (&iter2) == ' ') &&
			replaced_spaces < view->priv->tab_width)
		{
			++replaced_spaces;

			gtk_text_iter_forward_char (&iter2);
		}

		if (replaced_spaces > 0)
		{
			gchar *indent_buf;
			guint t, s;

			t = tabs + (spaces + replaced_spaces) / view->priv->tab_width;
			s = (spaces + replaced_spaces) % view->priv->tab_width;
			indent_buf = get_indent_string (t, s);

			gtk_text_buffer_delete (buf, &iter, &iter2);
			gtk_text_buffer_insert (buf, &iter, indent_buf, -1);

			g_free (indent_buf);
		}
		else
		{
			gtk_text_buffer_insert (buf, &iter, tab_buffer, -1);
		}
	}

	gtk_text_buffer_end_user_action (buf);

	g_free (tab_buffer);

	gtk_source_buffer_set_highlight_matching_brackets (GTK_SOURCE_BUFFER (buf), bracket_hl);

	if (view->priv->completion != NULL)
	{
		gtk_source_completion_unblock_interactive (view->priv->completion);
	}

	gtk_text_view_scroll_mark_onscreen (GTK_TEXT_VIEW (view),
					    gtk_text_buffer_get_insert (buf));

	/* revalidate iters */
	gtk_text_buffer_get_iter_at_mark (buf, start, start_mark);
	gtk_text_buffer_get_iter_at_mark (buf, end, end_mark);

	gtk_text_buffer_delete_mark (buf, start_mark);
	gtk_text_buffer_delete_mark (buf, end_mark);
}

/**
 * gtk_source_view_unindent_lines:
 * @view: a #GtkSourceView.
 * @start: #GtkTextIter of the first line to indent
 * @end: #GtkTextIter of the last line to indent
 *
 * Removes one indentation level at the beginning of the
 * specified lines.
 *
 * Since: 3.16
 */
void
gtk_source_view_unindent_lines (GtkSourceView *view,
				GtkTextIter   *start,
				GtkTextIter   *end)
{
	GtkTextBuffer *buf;
	gboolean bracket_hl;
	GtkTextMark *start_mark, *end_mark;
	gint start_line, end_line;
	gint tab_width;
	gint indent_width;
	gint i;

	if (view->priv->completion != NULL)
	{
		gtk_source_completion_block_interactive (view->priv->completion);
	}

	buf = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	bracket_hl = gtk_source_buffer_get_highlight_matching_brackets (GTK_SOURCE_BUFFER (buf));
	gtk_source_buffer_set_highlight_matching_brackets (GTK_SOURCE_BUFFER (buf), FALSE);

	start_mark = gtk_text_buffer_create_mark (buf, NULL, start, FALSE);
	end_mark = gtk_text_buffer_create_mark (buf, NULL, end, FALSE);

	start_line = gtk_text_iter_get_line (start);
	end_line = gtk_text_iter_get_line (end);

	if ((gtk_text_iter_get_visible_line_offset (end) == 0) &&
	    (end_line > start_line))
	{
		end_line--;
	}

	tab_width = view->priv->tab_width;
	indent_width = get_real_indent_width (view);

	gtk_text_buffer_begin_user_action (buf);

	for (i = start_line; i <= end_line; i++)
	{
		GtkTextIter iter, iter2;
		gint to_delete = 0;
		gint to_delete_equiv = 0;

		gtk_text_buffer_get_iter_at_line (buf, &iter, i);

		iter2 = iter;

		while (!gtk_text_iter_ends_line (&iter2) &&
		       to_delete_equiv < indent_width)
		{
			gunichar c;

			c = gtk_text_iter_get_char (&iter2);
			if (c == '\t')
			{
				to_delete_equiv += tab_width - to_delete_equiv % tab_width;
				++to_delete;
			}
			else if (c == ' ')
			{
				++to_delete_equiv;
				++to_delete;
			}
			else
			{
				break;
			}

			gtk_text_iter_forward_char (&iter2);
		}

		if (to_delete > 0)
		{
			gtk_text_iter_set_line_offset (&iter2, to_delete);
			gtk_text_buffer_delete (buf, &iter, &iter2);
		}
	}

	gtk_text_buffer_end_user_action (buf);

	gtk_source_buffer_set_highlight_matching_brackets (GTK_SOURCE_BUFFER (buf), bracket_hl);

	if (view->priv->completion != NULL)
	{
		gtk_source_completion_unblock_interactive (view->priv->completion);
	}

	gtk_text_view_scroll_mark_onscreen (GTK_TEXT_VIEW (view),
					    gtk_text_buffer_get_insert (buf));

	/* revalidate iters */
	gtk_text_buffer_get_iter_at_mark (buf, start, start_mark);
	gtk_text_buffer_get_iter_at_mark (buf, end, end_mark);

	gtk_text_buffer_delete_mark (buf, start_mark);
	gtk_text_buffer_delete_mark (buf, end_mark);
}

static gint
get_line_offset_in_equivalent_spaces (GtkSourceView *view,
				      GtkTextIter   *iter)
{
	GtkTextIter i;
	gint tab_width;
	gint n = 0;

	tab_width = view->priv->tab_width;

	i = *iter;
	gtk_text_iter_set_line_offset (&i, 0);

	while (!gtk_text_iter_equal (&i, iter))
	{
		gunichar c;

		c = gtk_text_iter_get_char (&i);
		if (c == '\t')
		{
			n += tab_width - n % tab_width;
		}
		else
		{
			++n;
		}

		gtk_text_iter_forward_char (&i);
	}

	return n;
}

static void
insert_tab_or_spaces (GtkSourceView *view,
		      GtkTextIter   *start,
		      GtkTextIter   *end)
{
	GtkTextBuffer *buf;
	gchar *tab_buf;
	gint cursor_offset = 0;

	if (view->priv->insert_spaces)
	{
		gint indent_width;
		gint pos;
		gint spaces;

		indent_width = get_real_indent_width (view);

		/* CHECK: is this a performance problem? */
		pos = get_line_offset_in_equivalent_spaces (view, start);
		spaces = indent_width - pos % indent_width;

		tab_buf = g_strnfill (spaces, ' ');
	}
	else if (view->priv->indent_width > 0 &&
	         view->priv->indent_width != (gint)view->priv->tab_width)
	{
		GtkTextIter iter;
		gint i;
		gint tab_width;
		gint indent_width;
		gint from;
		gint to;
		gint preceding_spaces = 0;
		gint following_tabs = 0;
		gint equiv_spaces;
		gint tabs;
		gint spaces;

		tab_width = view->priv->tab_width;
		indent_width = get_real_indent_width (view);

		/* CHECK: is this a performance problem? */
		from = get_line_offset_in_equivalent_spaces (view, start);
		to = indent_width * (1 + from / indent_width);
		equiv_spaces = to - from;

		/* extend the selection to include
		 * preceding spaces so that if indentation
		 * width < tab width, two conseutive indentation
		 * width units get compressed into a tab */
		iter = *start;
		for (i = 0; i < tab_width; ++i)
		{
			gtk_text_iter_backward_char (&iter);

			if (gtk_text_iter_get_char (&iter) == ' ')
			{
				++preceding_spaces;
			}
			else
			{
				break;
			}
		}

		gtk_text_iter_backward_chars (start, preceding_spaces);

		/* now also extend the selection to the following tabs
		 * since we do not want to insert spaces before a tab
		 * since it may have no visual effect */
		while (gtk_text_iter_get_char (end) == '\t')
		{
			++following_tabs;
			gtk_text_iter_forward_char (end);
		}

		tabs = (preceding_spaces + equiv_spaces) / tab_width;
		spaces = (preceding_spaces + equiv_spaces) % tab_width;

		tab_buf = get_indent_string (tabs + following_tabs, spaces);

		cursor_offset = gtk_text_iter_get_offset (start) +
			        tabs +
		                (following_tabs > 0 ? 1 : spaces);
	}
	else
	{
		tab_buf = g_strdup ("\t");
	}

	buf = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	gtk_text_buffer_begin_user_action (buf);

	gtk_text_buffer_delete (buf, start, end);
	gtk_text_buffer_insert (buf, start, tab_buf, -1);

	/* adjust cursor position if needed */
	if (cursor_offset > 0)
	{
		GtkTextIter iter;

		gtk_text_buffer_get_iter_at_offset (buf, &iter, cursor_offset);
		gtk_text_buffer_place_cursor (buf, &iter);
	}

	gtk_text_buffer_end_user_action (buf);

	g_free (tab_buf);
}

static void
gtk_source_view_move_words (GtkSourceView *view,
			    gint           step)
{
	GtkTextBuffer *buf;
	GtkTextIter s, e, ns, ne;
	GtkTextMark *nsmark, *nemark;
	gchar *old_text, *new_text;

	buf = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	if (step == 0 || gtk_text_view_get_editable (GTK_TEXT_VIEW (view)) == FALSE)
	{
		return;
	}

	gtk_text_buffer_get_selection_bounds (buf, &s, &e);

	if (gtk_text_iter_compare (&s, &e) == 0)
	{
		if (!gtk_text_iter_starts_word (&s))
		{
			if (!gtk_text_iter_inside_word (&s) && !gtk_text_iter_ends_word (&s))
			{
				return;
			}
			else
			{
				gtk_text_iter_backward_word_start (&s);
			}
		}

		if (!gtk_text_iter_starts_word (&s))
		{
			return;
		}

		e = s;

		if (!gtk_text_iter_ends_word (&e))
		{
			if (!gtk_text_iter_forward_word_end (&e))
			{
				gtk_text_iter_forward_to_end (&e);
			}

			if (!gtk_text_iter_ends_word (&e))
			{
				return;
			}
		}
	}

	/* Swap the selection with the next or previous word, based on step */
	if (step > 0)
	{
		ne = e;

		if (!gtk_text_iter_forward_word_ends (&ne, step))
		{
			gtk_text_iter_forward_to_end (&ne);
		}

		if (!gtk_text_iter_ends_word (&ne) || gtk_text_iter_equal (&ne, &e))
		{
			return;
		}

		ns = ne;

		if (!gtk_text_iter_backward_word_start (&ns))
		{
			return;
		}
	}
	else
	{
		ns = s;

		if (!gtk_text_iter_backward_word_starts (&ns, -step))
		{
			return;
		}

		ne = ns;

		if (!gtk_text_iter_forward_word_end (&ne))
		{
			return;
		}
	}

	if (gtk_text_iter_in_range (&ns, &s, &e) ||
	    gtk_text_iter_in_range (&ne, &s, &e))
	{
		return;
	}

	old_text = gtk_text_buffer_get_text (buf, &s, &e, TRUE);
	new_text = gtk_text_buffer_get_text (buf, &ns, &ne, TRUE);

	gtk_text_buffer_begin_user_action (buf);

	nsmark = gtk_text_buffer_create_mark (buf, NULL, &ns, TRUE);
	nemark = gtk_text_buffer_create_mark (buf, NULL, &ne, FALSE);

	gtk_text_buffer_delete (buf, &s, &e);
	gtk_text_buffer_insert (buf, &s, new_text, -1);

	gtk_text_buffer_get_iter_at_mark (buf, &ns, nsmark);
	gtk_text_buffer_get_iter_at_mark (buf, &ne, nemark);

	gtk_text_buffer_delete (buf, &ns, &ne);
	gtk_text_buffer_insert (buf, &ns, old_text, -1);

	ne = ns;
	gtk_text_buffer_get_iter_at_mark (buf, &ns, nsmark);

	gtk_text_buffer_select_range (buf, &ns, &ne);

	gtk_text_buffer_delete_mark (buf, nsmark);
	gtk_text_buffer_delete_mark (buf, nemark);

	gtk_text_buffer_end_user_action (buf);

	gtk_text_view_scroll_mark_onscreen (GTK_TEXT_VIEW (view),
	                                    gtk_text_buffer_get_insert (buf));

	g_free (old_text);
	g_free (new_text);
}

static gboolean
buffer_contains_trailing_newline (GtkTextBuffer *buffer)
{
	GtkTextIter iter;
	gunichar ch;

	gtk_text_buffer_get_end_iter (buffer, &iter);
	gtk_text_iter_backward_char (&iter);
	ch = gtk_text_iter_get_char (&iter);

	return (ch == '\n' || ch == '\r');
}

/* FIXME could be a function of GtkSourceBuffer, it's also useful for the
 * FileLoader.
 */
static void
remove_trailing_newline (GtkTextBuffer *buffer)
{
	GtkTextIter start;
	GtkTextIter end;

	gtk_text_buffer_get_end_iter (buffer, &end);
	start = end;

	gtk_text_iter_set_line_offset (&start, 0);

	if (gtk_text_iter_ends_line (&start) &&
	    gtk_text_iter_backward_line (&start))
	{
		if (!gtk_text_iter_ends_line (&start))
		{
			gtk_text_iter_forward_to_line_end (&start);
		}

		gtk_text_buffer_delete (buffer, &start, &end);
	}
}

static void
gtk_source_view_move_lines (GtkSourceView *view,
			    gboolean       copy,
			    gint           step)
{
	GtkTextBuffer *buffer;
	GtkTextIter start;
	GtkTextIter end;
	GtkTextIter insert_pos;
	GtkTextMark *start_mark;
	GtkTextMark *end_mark;
	gchar *text;
	gboolean initially_contains_trailing_newline;
	gboolean down;

	if (copy)
	{
		g_warning ("The 'copy' parameter of GtkSourceView::move-lines is deprecated.");
	}

	if (step != 1 && step != -1)
	{
		g_warning ("The 'count' parameter of GtkSourceView::move-lines should be either 1 or -1.");
	}

	buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	if (step == 0 || !gtk_text_view_get_editable (GTK_TEXT_VIEW (view)))
	{
		return;
	}

	/* FIXME: for now we just handle a step of one line */

	down = step > 0;

	gtk_text_buffer_get_selection_bounds (buffer, &start, &end);

	/* Get the entire lines, including the paragraph terminator. */
	gtk_text_iter_set_line_offset (&start, 0);
	if (!gtk_text_iter_starts_line (&end) ||
	    gtk_text_iter_get_line (&start) == gtk_text_iter_get_line (&end))
	{
		gtk_text_iter_forward_line (&end);
	}

	if ((!down && gtk_text_iter_is_start (&start)) ||
	    (down && gtk_text_iter_is_end (&end)))
	{
		/* Nothing to do, and the undo/redo history must remain
		 * unchanged.
		 */
		return;
	}

	start_mark = gtk_text_buffer_create_mark (buffer, NULL, &start, TRUE);
	end_mark = gtk_text_buffer_create_mark (buffer, NULL, &end, FALSE);

	gtk_text_buffer_begin_user_action (buffer);

	initially_contains_trailing_newline = buffer_contains_trailing_newline (buffer);

	if (!initially_contains_trailing_newline)
	{
		/* Insert a trailing newline. */
		gtk_text_buffer_get_end_iter (buffer, &end);
		gtk_text_buffer_insert (buffer, &end, "\n", -1);
	}

	/* At this point all lines finish with a newline or carriage return, so
	 * there are no special cases for the last line.
	 */

	gtk_text_buffer_get_iter_at_mark (buffer, &start, start_mark);
	gtk_text_buffer_get_iter_at_mark (buffer, &end, end_mark);
	gtk_text_buffer_delete_mark (buffer, start_mark);
	gtk_text_buffer_delete_mark (buffer, end_mark);
	start_mark = NULL;
	end_mark = NULL;

	text = gtk_text_buffer_get_text (buffer, &start, &end, TRUE);

	if (!copy)
	{
		gtk_text_buffer_delete (buffer, &start, &end);
	}

	if (down)
	{
		insert_pos = end;
		gtk_text_iter_forward_line (&insert_pos);
	}
	else
	{
		insert_pos = start;
		gtk_text_iter_backward_line (&insert_pos);
	}

	start_mark = gtk_text_buffer_create_mark (buffer, NULL, &insert_pos, TRUE);

	gtk_text_buffer_insert (buffer, &insert_pos, text, -1);
	g_free (text);

	/* Select the moved text. */
	gtk_text_buffer_get_iter_at_mark (buffer, &start, start_mark);
	gtk_text_buffer_delete_mark (buffer, start_mark);

	gtk_text_buffer_select_range (buffer, &start, &insert_pos);

	if (!initially_contains_trailing_newline)
	{
		remove_trailing_newline (buffer);
	}

	gtk_text_buffer_end_user_action (buffer);

	gtk_text_view_scroll_mark_onscreen (GTK_TEXT_VIEW (view),
					    gtk_text_buffer_get_insert (buffer));
}

static gboolean
do_smart_backspace (GtkSourceView *view)
{
	GtkTextBuffer *buffer;
	gboolean default_editable;
	GtkTextIter insert;
	GtkTextIter end;
	GtkTextIter leading_end;
	guint visual_column;
	gint indent_width;

	buffer = GTK_TEXT_BUFFER (view->priv->source_buffer);
	default_editable = gtk_text_view_get_editable (GTK_TEXT_VIEW (view));

	if (gtk_text_buffer_get_selection_bounds (buffer, &insert, &end))
	{
		return FALSE;
	}

	/* If the line isn't empty up to our cursor, ignore. */
	_gtk_source_iter_get_leading_spaces_end_boundary (&insert, &leading_end);
	if (gtk_text_iter_compare (&leading_end, &insert) < 0)
	{
		return FALSE;
	}

	visual_column = gtk_source_view_get_visual_column (view, &insert);
	indent_width = view->priv->indent_width;
	if (indent_width <= 0)
	{
		indent_width = view->priv->tab_width;
	}

	g_return_val_if_fail (indent_width > 0, FALSE);

	/* If the cursor is not at an indent_width boundary, it probably means
	 * that we want to adjust the spaces.
	 */
	if ((gint)visual_column < indent_width)
	{
		return FALSE;
	}

	if ((visual_column % indent_width) == 0)
	{
		guint target_column;

		g_assert ((gint)visual_column >= indent_width);
		target_column = visual_column - indent_width;

		while (gtk_source_view_get_visual_column (view, &insert) > target_column)
		{
			gtk_text_iter_backward_cursor_position (&insert);
		}

		gtk_text_buffer_begin_user_action (buffer);
		gtk_text_buffer_delete_interactive (buffer, &insert, &end, default_editable);
		while (gtk_source_view_get_visual_column (view, &insert) < target_column)
		{
			if (!gtk_text_buffer_insert_interactive (buffer, &insert, " ", 1, default_editable))
			{
				break;
			}
		}
		gtk_text_buffer_end_user_action (buffer);

		return TRUE;
	}

	return FALSE;
}

static gboolean
do_ctrl_backspace (GtkSourceView *view)
{
	GtkTextBuffer *buffer;
	GtkTextIter insert;
	GtkTextIter end;
	GtkTextIter leading_end;
	gboolean default_editable;

	buffer = GTK_TEXT_BUFFER (view->priv->source_buffer);
	default_editable = gtk_text_view_get_editable (GTK_TEXT_VIEW (view));

	if (gtk_text_buffer_get_selection_bounds (buffer, &insert, &end))
	{
		return FALSE;
	}

	/* A <Control>BackSpace at the beginning of the line should only move us to the
	 * end of the previous line. Anything more than that is non-obvious because it requires
	 * looking in a position other than where the cursor is.
	 */
	if ((gtk_text_iter_get_line_offset (&insert) == 0) &&
	    (gtk_text_iter_get_line (&insert) > 0))
	{
		gtk_text_iter_backward_cursor_position (&insert);
		gtk_text_buffer_delete_interactive (buffer, &insert, &end, default_editable);
		return TRUE;
	}

	/* If only leading whitespaces are on the left of the cursor, delete up
	 * to the zero position.
	 */
	_gtk_source_iter_get_leading_spaces_end_boundary (&insert, &leading_end);
	if (gtk_text_iter_compare (&insert, &leading_end) <= 0)
	{
		gtk_text_iter_set_line_offset (&insert, 0);
		gtk_text_buffer_delete_interactive (buffer, &insert, &end, default_editable);
		return TRUE;
	}

	return FALSE;
}

static gboolean
gtk_source_view_key_press_event (GtkWidget   *widget,
				 GdkEventKey *event)
{
	GtkSourceView *view;
	GtkTextBuffer *buf;
	GtkTextIter cur;
	GtkTextMark *mark;
	guint modifiers;
	gint key;
	gboolean editable;

	view = GTK_SOURCE_VIEW (widget);
	buf = gtk_text_view_get_buffer (GTK_TEXT_VIEW (widget));

	editable = gtk_text_view_get_editable (GTK_TEXT_VIEW (widget));

	/* Be careful when testing for modifier state equality:
	 * caps lock, num lock,etc need to be taken into account */
	modifiers = gtk_accelerator_get_default_mod_mask ();

	key = event->keyval;

	mark = gtk_text_buffer_get_insert (buf);
	gtk_text_buffer_get_iter_at_mark (buf, &cur, mark);

	if ((key == GDK_KEY_Return || key == GDK_KEY_KP_Enter) &&
	    !(event->state & GDK_SHIFT_MASK) &&
	    view->priv->auto_indent)
	{
		/* Auto-indent means that when you press ENTER at the end of a
		 * line, the new line is automatically indented at the same
		 * level as the previous line.
		 * SHIFT+ENTER allows to avoid autoindentation.
		 */
		gchar *indent = NULL;

		/* Calculate line indentation and create indent string. */
		indent = compute_indentation (view, &cur);

		if (indent != NULL)
		{
			/* Allow input methods to internally handle a key press event.
			 * If this function returns TRUE, then no further processing should be done
			 * for this keystroke. */
			if (gtk_text_view_im_context_filter_keypress (GTK_TEXT_VIEW (view), event))
			{
				g_free (indent);
				return GDK_EVENT_STOP;
			}

			/* If an input method has inserted some text while handling the key press event,
			 * the cur iterm may be invalid, so get the iter again */
			gtk_text_buffer_get_iter_at_mark (buf, &cur, mark);

			/* Insert new line and auto-indent. */
			gtk_text_buffer_begin_user_action (buf);
			gtk_text_buffer_insert (buf, &cur, "\n", 1);
			gtk_text_buffer_insert (buf, &cur, indent, strlen (indent));
			g_free (indent);
			gtk_text_buffer_end_user_action (buf);
			gtk_text_view_scroll_mark_onscreen (GTK_TEXT_VIEW (widget),
							    mark);
			return GDK_EVENT_STOP;
		}
	}

	/* if tab or shift+tab:
	 * with shift+tab key is GDK_ISO_Left_Tab (yay! on win32 and mac too!)
	 */
	if ((key == GDK_KEY_Tab || key == GDK_KEY_KP_Tab || key == GDK_KEY_ISO_Left_Tab) &&
	    ((event->state & modifiers) == 0 ||
	     (event->state & modifiers) == GDK_SHIFT_MASK) &&
	    editable &&
	    gtk_text_view_get_accepts_tab (GTK_TEXT_VIEW (view)))
	{
		GtkTextIter s, e;
		gboolean has_selection;

		has_selection = gtk_text_buffer_get_selection_bounds (buf, &s, &e);

		if (view->priv->indent_on_tab)
		{
			/* shift+tab: always unindent */
			if (event->state & GDK_SHIFT_MASK)
			{
				_gtk_source_buffer_save_and_clear_selection (GTK_SOURCE_BUFFER (buf));
				gtk_source_view_unindent_lines (view, &s, &e);
				_gtk_source_buffer_restore_selection (GTK_SOURCE_BUFFER (buf));
				return GDK_EVENT_STOP;
			}

			/* tab: if we have a selection which spans one whole line
			 * or more, we mass indent, if the selection spans less then
			 * the full line just replace the text with \t
			 */
			if (has_selection &&
			    ((gtk_text_iter_starts_line (&s) && gtk_text_iter_ends_line (&e)) ||
			     (gtk_text_iter_get_line (&s) != gtk_text_iter_get_line (&e))))
			{
				_gtk_source_buffer_save_and_clear_selection (GTK_SOURCE_BUFFER (buf));
				gtk_source_view_indent_lines (view, &s, &e);
				_gtk_source_buffer_restore_selection (GTK_SOURCE_BUFFER (buf));
				return GDK_EVENT_STOP;
			}
		}

		insert_tab_or_spaces (view, &s, &e);
		return GDK_EVENT_STOP;
	}

	if (key == GDK_KEY_BackSpace)
	{
		if ((event->state & modifiers) == 0)
		{
			if (view->priv->smart_backspace && do_smart_backspace (view))
			{
				return GDK_EVENT_STOP;
			}
		}
		else if ((event->state & modifiers) == GDK_CONTROL_MASK)
		{
			if (do_ctrl_backspace (view))
			{
				return GDK_EVENT_STOP;
			}
		}
	}

	return GTK_WIDGET_CLASS (gtk_source_view_parent_class)->key_press_event (widget, event);
}

/**
 * gtk_source_view_get_auto_indent:
 * @view: a #GtkSourceView.
 *
 * Returns whether auto-indentation of text is enabled.
 *
 * Returns: %TRUE if auto indentation is enabled.
 */
gboolean
gtk_source_view_get_auto_indent (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->auto_indent;
}

/**
 * gtk_source_view_set_auto_indent:
 * @view: a #GtkSourceView.
 * @enable: whether to enable auto indentation.
 *
 * If %TRUE auto-indentation of text is enabled.
 *
 * When Enter is pressed to create a new line, the auto-indentation inserts the
 * same indentation as the previous line. This is <emphasis>not</emphasis> a
 * "smart indentation" where an indentation level is added or removed depending
 * on the context.
 */
void
gtk_source_view_set_auto_indent (GtkSourceView *view,
				 gboolean       enable)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	enable = enable != FALSE;

	if (view->priv->auto_indent != enable)
	{
		view->priv->auto_indent = enable;
		g_object_notify (G_OBJECT (view), "auto_indent");
	}
}

/**
 * gtk_source_view_get_insert_spaces_instead_of_tabs:
 * @view: a #GtkSourceView.
 *
 * Returns whether when inserting a tabulator character it should
 * be replaced by a group of space characters.
 *
 * Returns: %TRUE if spaces are inserted instead of tabs.
 */
gboolean
gtk_source_view_get_insert_spaces_instead_of_tabs (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->insert_spaces;
}

/**
 * gtk_source_view_set_insert_spaces_instead_of_tabs:
 * @view: a #GtkSourceView.
 * @enable: whether to insert spaces instead of tabs.
 *
 * If %TRUE a tab key pressed is replaced by a group of space characters. Of
 * course it is still possible to insert a real \t programmatically with the
 * #GtkTextBuffer API.
 */
void
gtk_source_view_set_insert_spaces_instead_of_tabs (GtkSourceView *view,
						   gboolean       enable)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	enable = enable != FALSE;

	if (view->priv->insert_spaces != enable)
	{
		view->priv->insert_spaces = enable;
		g_object_notify (G_OBJECT (view), "insert_spaces_instead_of_tabs");
	}
}

/**
 * gtk_source_view_get_indent_on_tab:
 * @view: a #GtkSourceView.
 *
 * Returns whether when the tab key is pressed the current selection
 * should get indented instead of replaced with the \t character.
 *
 * Return value: %TRUE if the selection is indented when tab is pressed.
 */
gboolean
gtk_source_view_get_indent_on_tab (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->indent_on_tab;
}

/**
 * gtk_source_view_set_indent_on_tab:
 * @view: a #GtkSourceView.
 * @enable: whether to indent a block when tab is pressed.
 *
 * If %TRUE, when the tab key is pressed when several lines are selected, the
 * selected lines are indented of one level instead of being replaced with a \t
 * character. Shift+Tab unindents the selection.
 *
 * If the first or last line is not selected completely, it is also indented or
 * unindented.
 *
 * When the selection doesn't span several lines, the tab key always replaces
 * the selection with a normal \t character.
 */
void
gtk_source_view_set_indent_on_tab (GtkSourceView *view,
				   gboolean       enable)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	enable = enable != FALSE;

	if (view->priv->indent_on_tab != enable)
	{
		view->priv->indent_on_tab = enable;
		g_object_notify (G_OBJECT (view), "indent_on_tab");
	}
}

static void
view_dnd_drop (GtkTextView      *view,
	       GdkDragContext   *context,
	       gint              x,
	       gint              y,
	       GtkSelectionData *selection_data,
	       guint             info,
	       guint             timestamp,
	       gpointer          data)
{

	GtkTextIter iter;

	if (info == TARGET_COLOR)
	{
		guint16 *vals;
		gchar string[] = "#000000";
		gint buffer_x;
		gint buffer_y;
		gint length = gtk_selection_data_get_length (selection_data);

		if (length < 0)
		{
			return;
		}

		if (gtk_selection_data_get_format (selection_data) != 16 || length != 8)
		{
			g_warning ("Received invalid color data\n");
			return;
		}

		vals = (gpointer) gtk_selection_data_get_data (selection_data);

		vals[0] /= 256;
	        vals[1] /= 256;
		vals[2] /= 256;

		g_snprintf (string, sizeof (string), "#%02X%02X%02X", vals[0], vals[1], vals[2]);

		gtk_text_view_window_to_buffer_coords (view,
						       GTK_TEXT_WINDOW_TEXT,
						       x,
						       y,
						       &buffer_x,
						       &buffer_y);
		gtk_text_view_get_iter_at_location (view, &iter, buffer_x, buffer_y);

		if (gtk_text_view_get_editable (view))
		{
			gtk_text_buffer_insert (gtk_text_view_get_buffer (view),
						&iter,
						string,
						strlen (string));
			gtk_text_buffer_place_cursor (gtk_text_view_get_buffer (view),
						&iter);
		}

		/*
		 * FIXME: Check if the iter is inside a selection
		 * If it is, remove the selection and then insert at
		 * the cursor position - Paolo
		 */

		return;
	}
}

/**
 * gtk_source_view_get_highlight_current_line:
 * @view: a #GtkSourceView.
 *
 * Returns whether the current line is highlighted.
 *
 * Return value: %TRUE if the current line is highlighted.
 */
gboolean
gtk_source_view_get_highlight_current_line (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->highlight_current_line;
}

/**
 * gtk_source_view_set_highlight_current_line:
 * @view: a #GtkSourceView.
 * @highlight: whether to highlight the current line.
 *
 * If @highlight is %TRUE the current line will be highlighted.
 */
void
gtk_source_view_set_highlight_current_line (GtkSourceView *view,
					    gboolean       highlight)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	highlight = highlight != FALSE;

	if (view->priv->highlight_current_line != highlight)
	{
		view->priv->highlight_current_line = highlight;

		gtk_widget_queue_draw (GTK_WIDGET (view));

		g_object_notify (G_OBJECT (view), "highlight_current_line");
	}
}

/**
 * gtk_source_view_get_show_right_margin:
 * @view: a #GtkSourceView.
 *
 * Returns whether a right margin is displayed.
 *
 * Return value: %TRUE if the right margin is shown.
 */
gboolean
gtk_source_view_get_show_right_margin (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->show_right_margin;
}

/**
 * gtk_source_view_set_show_right_margin:
 * @view: a #GtkSourceView.
 * @show: whether to show a right margin.
 *
 * If %TRUE a right margin is displayed.
 */
void
gtk_source_view_set_show_right_margin (GtkSourceView *view,
				       gboolean       show)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	show = show != FALSE;

	if (view->priv->show_right_margin != show)
	{
		view->priv->show_right_margin = show;

		gtk_widget_queue_draw (GTK_WIDGET (view));

		g_object_notify (G_OBJECT (view), "show-right-margin");
	}
}

/**
 * gtk_source_view_get_right_margin_position:
 * @view: a #GtkSourceView.
 *
 * Gets the position of the right margin in the given @view.
 *
 * Return value: the position of the right margin.
 */
guint
gtk_source_view_get_right_margin_position (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), DEFAULT_RIGHT_MARGIN_POSITION);

	return view->priv->right_margin_pos;
}

/**
 * gtk_source_view_set_right_margin_position:
 * @view: a #GtkSourceView.
 * @pos: the width in characters where to position the right margin.
 *
 * Sets the position of the right margin in the given @view.
 */
void
gtk_source_view_set_right_margin_position (GtkSourceView *view,
					   guint          pos)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));
	g_return_if_fail (1 <= pos && pos <= MAX_RIGHT_MARGIN_POSITION);

	if (view->priv->right_margin_pos != pos)
	{
		view->priv->right_margin_pos = pos;
		view->priv->cached_right_margin_pos = -1;

		gtk_widget_queue_draw (GTK_WIDGET (view));

		g_object_notify (G_OBJECT (view), "right-margin-position");
	}
}

/**
 * gtk_source_view_set_smart_backspace:
 * @view: a #GtkSourceView.
 * @smart_backspace: whether to enable smart Backspace handling.
 *
 * When set to %TRUE, pressing the Backspace key will try to delete spaces
 * up to the previous tab stop.
 *
 * Since: 3.18
 */
void
gtk_source_view_set_smart_backspace (GtkSourceView *view,
                                     gboolean       smart_backspace)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	smart_backspace = smart_backspace != FALSE;

	if (smart_backspace != view->priv->smart_backspace)
	{
		view->priv->smart_backspace = smart_backspace;
		g_object_notify (G_OBJECT (view), "smart-backspace");
	}
}

/**
 * gtk_source_view_get_smart_backspace:
 * @view: a #GtkSourceView.
 *
 * Returns %TRUE if pressing the Backspace key will try to delete spaces
 * up to the previous tab stop.
 *
 * Returns: %TRUE if smart Backspace handling is enabled.
 *
 * Since: 3.18
 */
gboolean
gtk_source_view_get_smart_backspace (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->smart_backspace;
}

/**
 * gtk_source_view_set_smart_home_end:
 * @view: a #GtkSourceView.
 * @smart_home_end: the desired behavior among #GtkSourceSmartHomeEndType.
 *
 * Set the desired movement of the cursor when HOME and END keys
 * are pressed.
 */
void
gtk_source_view_set_smart_home_end (GtkSourceView             *view,
				    GtkSourceSmartHomeEndType  smart_home_end)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	if (view->priv->smart_home_end != smart_home_end)
	{
		view->priv->smart_home_end = smart_home_end;
		g_object_notify (G_OBJECT (view), "smart_home_end");
	}
}

/**
 * gtk_source_view_get_smart_home_end:
 * @view: a #GtkSourceView.
 *
 * Returns a #GtkSourceSmartHomeEndType end value specifying
 * how the cursor will move when HOME and END keys are pressed.
 *
 * Returns: a #GtkSourceSmartHomeEndType value.
 */
GtkSourceSmartHomeEndType
gtk_source_view_get_smart_home_end (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), FALSE);

	return view->priv->smart_home_end;
}

/**
 * gtk_source_view_set_draw_spaces:
 * @view: a #GtkSourceView.
 * @flags: #GtkSourceDrawSpacesFlags specifing how white spaces should
 * be displayed
 *
 * Set if and how the spaces should be visualized. Specifying @flags as 0 will
 * disable display of spaces.
 *
 * For a finer-grained method, there is also the GtkSourceTag's
 * #GtkSourceTag:draw-spaces property.
 *
 * Deprecated: 3.24: Use gtk_source_space_drawer_set_types_for_locations()
 * instead.
 */
void
gtk_source_view_set_draw_spaces (GtkSourceView            *view,
				 GtkSourceDrawSpacesFlags  flags)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	if (view->priv->space_drawer == NULL)
	{
		return;
	}

	_gtk_source_space_drawer_set_flags (view->priv->space_drawer, flags);
}

/**
 * gtk_source_view_get_draw_spaces:
 * @view: a #GtkSourceView
 *
 * Returns the #GtkSourceDrawSpacesFlags specifying if and how spaces
 * should be displayed for this @view.
 *
 * Returns: the #GtkSourceDrawSpacesFlags, 0 if no spaces should be drawn.
 * Deprecated: 3.24: Use gtk_source_space_drawer_get_types_for_locations()
 * instead.
 */
GtkSourceDrawSpacesFlags
gtk_source_view_get_draw_spaces (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), 0);

	if (view->priv->space_drawer == NULL)
	{
		return 0;
	}

	return _gtk_source_space_drawer_get_flags (view->priv->space_drawer);
}

/**
 * gtk_source_view_get_visual_column:
 * @view: a #GtkSourceView.
 * @iter: a position in @view.
 *
 * Determines the visual column at @iter taking into consideration the
 * #GtkSourceView:tab-width of @view.
 *
 * Returns: the visual column at @iter.
 */
guint
gtk_source_view_get_visual_column (GtkSourceView     *view,
				   const GtkTextIter *iter)
{
	gunichar tab_char;
	GtkTextIter position;
	guint column, indent_width;

	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), 0);
	g_return_val_if_fail (iter != NULL, 0);

	tab_char = g_utf8_get_char ("\t");

	column = 0;
	indent_width = get_real_indent_width (view);

	position = *iter;
	gtk_text_iter_set_line_offset (&position, 0);

	while (!gtk_text_iter_equal (&position, iter))
	{
		if (gtk_text_iter_get_char (&position) == tab_char)
		{
			column += (indent_width - (column % indent_width));
		}
		else
		{
			++column;
		}

		/* FIXME: this does not handle invisible text correctly, but
		 * gtk_text_iter_forward_visible_cursor_position is too slow */
		if (!gtk_text_iter_forward_char (&position))
		{
			break;
		}
	}

	return column;
}

static void
update_background_pattern_color (GtkSourceView *view)
{
	if (view->priv->style_scheme == NULL)
	{
		view->priv->background_pattern_color_set = FALSE;
		return;
	}

	view->priv->background_pattern_color_set =
		_gtk_source_style_scheme_get_background_pattern_color (view->priv->style_scheme,
								       &view->priv->background_pattern_color);
}

static void
update_current_line_color (GtkSourceView *view)
{
	if (view->priv->style_scheme == NULL)
	{
		view->priv->current_line_color_set = FALSE;
		return;
	}

	view->priv->current_line_color_set =
		_gtk_source_style_scheme_get_current_line_color (view->priv->style_scheme,
								 &view->priv->current_line_color);
}

static void
update_right_margin_colors (GtkSourceView *view)
{
	GtkWidget *widget = GTK_WIDGET (view);

	if (view->priv->right_margin_line_color != NULL)
	{
		gdk_rgba_free (view->priv->right_margin_line_color);
		view->priv->right_margin_line_color = NULL;
	}

	if (view->priv->right_margin_overlay_color != NULL)
	{
		gdk_rgba_free (view->priv->right_margin_overlay_color);
		view->priv->right_margin_overlay_color = NULL;
	}

	if (view->priv->style_scheme != NULL)
	{
		GtkSourceStyle *style;

		style = _gtk_source_style_scheme_get_right_margin_style (view->priv->style_scheme);

		if (style != NULL)
		{
			gchar *color_str = NULL;
			gboolean color_set;
			GdkRGBA color;

			g_object_get (style,
				      "foreground", &color_str,
				      "foreground-set", &color_set,
				      NULL);

			if (color_set &&
			    color_str != NULL &&
			    gdk_rgba_parse (&color, color_str))
			{
				view->priv->right_margin_line_color = gdk_rgba_copy (&color);
				view->priv->right_margin_line_color->alpha =
					RIGHT_MARGIN_LINE_ALPHA / 255.;
			}

			g_free (color_str);
			color_str = NULL;

			g_object_get (style,
				      "background", &color_str,
				      "background-set", &color_set,
				      NULL);

			if (color_set &&
			    color_str != NULL &&
			    gdk_rgba_parse (&color, color_str))
			{
				view->priv->right_margin_overlay_color = gdk_rgba_copy (&color);
				view->priv->right_margin_overlay_color->alpha =
					RIGHT_MARGIN_OVERLAY_ALPHA / 255.;
			}

			g_free (color_str);
		}
	}

	if (view->priv->right_margin_line_color == NULL)
	{
		GtkStyleContext *context;
		GdkRGBA color;

		context = gtk_widget_get_style_context (widget);
		gtk_style_context_save (context);
		gtk_style_context_set_state (context, GTK_STATE_FLAG_NORMAL);
		gtk_style_context_get_color (context,
					     gtk_style_context_get_state (context),
					     &color);
		gtk_style_context_restore (context);

		view->priv->right_margin_line_color = gdk_rgba_copy (&color);
		view->priv->right_margin_line_color->alpha =
			RIGHT_MARGIN_LINE_ALPHA / 255.;
	}
}

static void
update_style (GtkSourceView *view)
{
	update_background_pattern_color (view);
	update_current_line_color (view);
	update_right_margin_colors (view);

	if (view->priv->space_drawer != NULL)
	{
		_gtk_source_space_drawer_update_color (view->priv->space_drawer, view);
	}

	gtk_widget_queue_draw (GTK_WIDGET (view));
}

static void
gtk_source_view_update_style_scheme (GtkSourceView *view)
{
	GtkTextBuffer *buffer;
	GtkSourceStyleScheme *new_scheme = NULL;

	buffer = gtk_text_view_get_buffer (GTK_TEXT_VIEW (view));

	if (GTK_SOURCE_IS_BUFFER (buffer))
	{
		new_scheme = gtk_source_buffer_get_style_scheme (GTK_SOURCE_BUFFER (buffer));
	}

	if (view->priv->style_scheme == new_scheme)
	{
		return;
	}

	if (view->priv->style_scheme != NULL)
	{
		_gtk_source_style_scheme_unapply (view->priv->style_scheme, view);
	}

	g_set_object (&view->priv->style_scheme, new_scheme);

	if (view->priv->style_scheme != NULL)
	{
		_gtk_source_style_scheme_apply (view->priv->style_scheme, view);
	}

	update_style (view);
}

static void
gtk_source_view_style_updated (GtkWidget *widget)
{
	GtkSourceView *view = GTK_SOURCE_VIEW (widget);

	/* Call default handler first. */
	if (GTK_WIDGET_CLASS (gtk_source_view_parent_class)->style_updated != NULL)
	{
		GTK_WIDGET_CLASS (gtk_source_view_parent_class)->style_updated (widget);
	}

	/* Re-set tab stops, but only if we already modified them, i.e.
	 * do nothing with good old 8-space tabs.
	 */
	if (view->priv->tabs_set)
	{
		set_tab_stops_internal (view);
	}

	/* Make sure the margin position is recalculated on next redraw. */
	view->priv->cached_right_margin_pos = -1;

	update_style (view);
}

static MarkCategory *
mark_category_new (GtkSourceMarkAttributes *attributes,
		   gint                     priority)
{
	MarkCategory* category = g_slice_new (MarkCategory);

	category->attributes = g_object_ref (attributes);
	category->priority = priority;

	return category;
}

static void
mark_category_free (MarkCategory *category)
{
	if (category != NULL)
	{
		g_object_unref (category->attributes);
		g_slice_free (MarkCategory, category);
	}
}

/**
 * gtk_source_view_get_completion:
 * @view: a #GtkSourceView.
 *
 * Gets the #GtkSourceCompletion associated with @view. The returned object is
 * guaranteed to be the same for the lifetime of @view. Each #GtkSourceView
 * object has a different #GtkSourceCompletion.
 *
 * Returns: (transfer none): the #GtkSourceCompletion associated with @view.
 */
GtkSourceCompletion *
gtk_source_view_get_completion (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), NULL);

	if (view->priv->completion == NULL)
	{
		view->priv->completion = gtk_source_completion_new (view);
	}

	return view->priv->completion;
}

/**
 * gtk_source_view_get_gutter:
 * @view: a #GtkSourceView.
 * @window_type: the gutter window type.
 *
 * Returns the #GtkSourceGutter object associated with @window_type for @view.
 * Only GTK_TEXT_WINDOW_LEFT and GTK_TEXT_WINDOW_RIGHT are supported,
 * respectively corresponding to the left and right gutter. The line numbers
 * and mark category icons are rendered in the left gutter.
 *
 * Since: 2.8
 *
 * Returns: (transfer none): the #GtkSourceGutter.
 */
GtkSourceGutter *
gtk_source_view_get_gutter (GtkSourceView     *view,
			    GtkTextWindowType  window_type)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), NULL);
	g_return_val_if_fail (window_type == GTK_TEXT_WINDOW_LEFT ||
	                      window_type == GTK_TEXT_WINDOW_RIGHT, NULL);

	if (window_type == GTK_TEXT_WINDOW_LEFT)
	{
		if (view->priv->left_gutter == NULL)
		{
			view->priv->left_gutter = _gtk_source_gutter_new (view, window_type);
		}

		return view->priv->left_gutter;
	}
	else
	{
		if (view->priv->right_gutter == NULL)
		{
			view->priv->right_gutter = _gtk_source_gutter_new (view, window_type);
		}

		return view->priv->right_gutter;
	}
}

/**
 * gtk_source_view_set_mark_attributes:
 * @view: a #GtkSourceView.
 * @category: the category.
 * @attributes: mark attributes.
 * @priority: priority of the category.
 *
 * Sets attributes and priority for the @category.
 */
void
gtk_source_view_set_mark_attributes (GtkSourceView           *view,
				     const gchar             *category,
				     GtkSourceMarkAttributes *attributes,
				     gint                     priority)
{
	MarkCategory *mark_category;

	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));
	g_return_if_fail (category != NULL);
	g_return_if_fail (GTK_SOURCE_IS_MARK_ATTRIBUTES (attributes));
	g_return_if_fail (priority >= 0);

	mark_category = mark_category_new (attributes, priority);
	g_hash_table_replace (view->priv->mark_categories,
	                      g_strdup (category),
	                      mark_category);
}

/**
 * gtk_source_view_get_mark_attributes:
 * @view: a #GtkSourceView.
 * @category: the category.
 * @priority: place where priority of the category will be stored.
 *
 * Gets attributes and priority for the @category.
 *
 * Returns: (transfer none): #GtkSourceMarkAttributes for the @category.
 * The object belongs to @view, so it must not be unreffed.
 */
GtkSourceMarkAttributes *
gtk_source_view_get_mark_attributes (GtkSourceView *view,
				     const gchar   *category,
				     gint          *priority)
{
	MarkCategory *mark_category;

	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), NULL);
	g_return_val_if_fail (category != NULL, NULL);

	mark_category = g_hash_table_lookup (view->priv->mark_categories,
	                                     category);

	if (mark_category != NULL)
	{
		if (priority != NULL)
		{
			*priority = mark_category->priority;
		}

		return mark_category->attributes;
	}

	return NULL;
}

/**
 * gtk_source_view_set_background_pattern:
 * @view: a #GtkSourceView.
 * @background_pattern: the #GtkSourceBackgroundPatternType.
 *
 * Set if and how the background pattern should be displayed.
 *
 * Since: 3.16
 */
void
gtk_source_view_set_background_pattern (GtkSourceView                  *view,
					GtkSourceBackgroundPatternType  background_pattern)
{
	g_return_if_fail (GTK_SOURCE_IS_VIEW (view));

	if (view->priv->background_pattern != background_pattern)
	{
		view->priv->background_pattern = background_pattern;

		gtk_widget_queue_draw (GTK_WIDGET (view));

		g_object_notify (G_OBJECT (view), "background-pattern");
	}
}

/**
 * gtk_source_view_get_background_pattern:
 * @view: a #GtkSourceView
 *
 * Returns the #GtkSourceBackgroundPatternType specifying if and how
 * the background pattern should be displayed for this @view.
 *
 * Returns: the #GtkSourceBackgroundPatternType.
 * Since: 3.16
 */
GtkSourceBackgroundPatternType
gtk_source_view_get_background_pattern (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), GTK_SOURCE_BACKGROUND_PATTERN_TYPE_NONE);

	return view->priv->background_pattern;
}

/**
 * gtk_source_view_get_space_drawer:
 * @view: a #GtkSourceView.
 *
 * Gets the #GtkSourceSpaceDrawer associated with @view. The returned object is
 * guaranteed to be the same for the lifetime of @view. Each #GtkSourceView
 * object has a different #GtkSourceSpaceDrawer.
 *
 * Returns: (transfer none): the #GtkSourceSpaceDrawer associated with @view.
 * Since: 3.24
 */
GtkSourceSpaceDrawer *
gtk_source_view_get_space_drawer (GtkSourceView *view)
{
	g_return_val_if_fail (GTK_SOURCE_IS_VIEW (view), NULL);

	return view->priv->space_drawer;
}
