/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2013 Intel Corporation
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
 * Authors: Tristan Van Berkom <tristanvb@openismus.com>
 */

/**
 * SECTION: e-book-client-cursor
 * @include: libebook/libebook.h
 * @short_description: An addressbook cursor
 *
 * The #EBookClientCursor is an iteration based interface for browsing
 * a sorted list of contacts in the addressbook.
 *
 * Aside from the documentation found here, a fully functional example
 * program <link linkend="eds-cursor-example">can be found here</link>.
 *
 * <refsect2 id="cursor-sort-keys">
 * <title>Sort Keys</title>
 * <para>
 * When creating the cursor initially with e_book_client_get_cursor(),
 * a list of #EContactFields must be provided to define the sort order for
 * the newly created cursor. Only contact fields of type %G_TYPE_STRING
 * can potentially be used to define a cursor's sort order.
 * </para>
 * <para>
 * Backends which support cursors may refuse to create a cursor based
 * on the fields specified as sort keys,  if this happens then an
 * %E_CLIENT_ERROR_INVALID_QUERY error will be reported by
 * e_book_client_get_cursor().
 * </para>
 * <para>
 * The default SQLite backend provided with Evolution Data Server
 * only supports #EContactFields that are specified as summary information
 * to be used as sort keys. Whether a contact field is configured to
 * be part of the summary for your addressbook can be verified with
 * e_source_backend_summary_setup_get_summary_fields().
 * </para>
 * <para>
 * The order of sort keys given to e_book_client_get_cursor() defines
 * which sort key will be the primary sort key and which keys will
 * serve as tie breakers where the previous sort keys are exact matches.
 * In the following example we create a typical cursor sorted with
 * %E_CONTACT_FAMILY_NAME as the primary sort key and %E_CONTACT_GIVEN_NAME
 * as a tie breaker.
 * |[
 *     EBookClientCursor *cursor = NULL;
 *     EContactField sort_fields[] = { E_CONTACT_FAMILY_NAME, E_CONTACT_GIVEN_NAME };
 *     EBookCursorSortType sort_types[] = { E_BOOK_CURSOR_SORT_ASCENDING, E_BOOK_CURSOR_SORT_ASCENDING };
 *     GError *error = NULL;
 *
 *     if (e_book_client_get_cursor_sync (book_client, // EBookClient
 *                                        NULL,        // Search Expression
 *                                        sort_fields, // Sort Keys
 *                                        sort_types,  // Ascending / Descending
 *                                        2,           // Number of keys
 *                                        &cursor,     // Return location for cursor
 *                                        NULL,        // GCancellable
 *                                        &error)) {
 *             // Now we have a cursor ...
 *     }
 * ]|
 * </para>
 * <para>
 * Sort order is immutable, if you need to browse content in a different
 * order, then you need to create a separate cursor.
 * </para>
 * </refsect2>
 *
 * <refsect2 id="cursor-state">
 * <title>Understanding cursor state</title>
 * <para>
 * At any given time in a cursor's life cycle, a cursor's internal state will refer to a
 * relative position in a sorted list.
 * </para>
 * <para>
 * There are three basic varieties of cursor states:
 * <itemizedlist>
 *   <listitem>
 *     <para>
 *       Virtual states referring to the beginnng and end of the list.
 *     </para>
 *     <para>
 *       The beginning state is positioned before any contact in the addressbook.
 *       When the cursor is in this state, a call to e_book_client_cursor_step()
 *       will always start reporting contacts from the beginning of the list.
 *       Similarly when in the end state, stepping in reverse will start
 *       reporting contacts from the end of the list.
 *     </para>
 *     <para>
 *       The beginning and end states can be reached by stepping off the
 *       end of the list, or by specifying the %E_BOOK_CURSOR_ORIGIN_BEGIN or
 *       %E_BOOK_CURSOR_ORIGIN_END origins to e_book_client_cursor_step(). The
 *       cursor is also initially positioned before the contact list.
 *     </para>
 *   </listitem>
 *   <listitem>
 *     <para>
 *       States referring to a specific contact.
 *     </para>
 *     <para>
 *       A state which refers to a specific contact in the list of
 *       contacts associated with a given cursor. At the end of any
 *       successful call to e_book_client_cursor_step() with
 *       the %E_BOOK_CURSOR_STEP_MOVE flag specified; the cursor
 *       state is updated with the value of the last result.
 *     </para>
 *   </listitem>
 *   <listitem>
 *     <para>
 *       States referring to an alphabetic position.
 *     </para>
 *     <para>
 *       When a state refers to an
 *       <link linkend="cursor-alphabet">Alphabetic Index</link>,
 *       it refers to a position which is in between contacts.
 *       For instance the alphabetic position "E" refers to a
 *       position after contacts starting with "D" and before contacts
 *       starting with "E".
 *     </para>
 *   </listitem>
 * </itemizedlist>
 * </para>
 * </refsect2>
 *
 * <refsect2 id="cursor-pos-total">
 * <title>Cursor position and total</title>
 * <para>
 * The #EBookClientCursor:position and #EBookClientCursor:total attributes
 * provide feedback about a cursor's position in relation to the addressbook
 * provided the cursor's sort order.
 * </para>
 * <para>
 * The total reflects that total amount of contacts in the addressbook given
 * the cursor's <link linkend="cursor-search">Search Expression</link>. The position
 * is defined as the number of contacts leading up to the cursor position inclusive
 * of the cursor position.
 * </para>
 * <para>
 * To help illustrate how the total and position attributes relate to a sorted list
 * of contacts, we've provided the diagram below. 
 * </para>
 * <inlinegraphic fileref="cursor-positions.png" format="PNG" align="center"></inlinegraphic>
 * <para>
 * The above diagram shows two representations of a sorted contact list, using
 * %E_CONTACT_FAMILY_NAME as the primary sort key and %E_CONTACT_GIVEN_NAME as
 * a secondary sort key. On either side we can see the symbolic positions
 * %E_BOOK_CURSOR_ORIGIN_BEGIN and %E_BOOK_CURSOR_ORIGIN_END.
 * </para>
 * <para>
 * For a given cursor state, the position value will be equal to the total
 * number of contacts leading up to the current cursor state inclusive of the
 * cursor state itself. In the left hand side of the above diagram the cursor
 * points to the fourth contact and the cursor position is also 4. An exception
 * to this is when the cursor state refers to the %E_BOOK_CURSOR_ORIGIN_END position.
 * When the cursor state refers to the end of list, the position property
 * will have a value of (total + 1).
 * </para>
 * <para>
 * Another thing the above diagram illustrates is the effect that an
 * asynchronous addressbook modification has on the cursor. The right
 * hand side of the diagram portrays the result of deleting "Mickey Mouse"
 * from the original list on the left.
 * </para>
 * <para>
 * The cursor state at this time still litteraly refers to "Mickey Mouse",
 * however the number of contacts leading up to "Mickey Mouse" is now 3 
 * instead of 4. As one might have guessed, any addition of a contact
 * which is considered to be less than or equal to "Mickey Mouse" at this point,
 * will cause the position to increase again. In this way, asynchronous
 * addressbook modification might cause the cursor's position and total
 * values to change, but never effect the cursor's state and it's
 * actual position in relation to other contacts in the sorted list.
 * </para>
 * <para>
 * The position and total can be useful for various tasks
 * such as determining "Forward" / "Back" button sensitivity
 * in a browser interface, or displaying some indication
 * of the view window's position in the full contact list.
 * |[
 *     gint position, total;
 *     gdouble percent;
 *
 *     // Fetch the position & total
 *     position = e_book_client_cursor_get_position (cursor);
 *     total    = e_book_client_cursor_get_total (cursor);
 *
 *     // The position can be total + 1 if we're at the end of the
 *     // list, let's ignore that for this calculation.
 *     position = CLAMP (position, 0, total);
 *
 *     // Calculate the percentage.
 *     percent = position * 1.0F / (total - N_DISPLAY_CONTACTS);
 *
 *     // Let the user know the percentage of contacts in the list
 *     // which are positioned before the view position (the
 *     // percentage of the addressbook which the user has seen so far).
 *     update_percentage_of_list_browsed (user_interface, percent);
 * ]|
 * </para>
 * <para>
 * These total and position values are guaranteed to always be coherent, they are
 * updated synchronously upon successful completion of any of the asynchronous
 * cursor API calls, and also updated asynchronously whenever the addressbook
 * changes and a #EBookClientCursor::refresh signal is delivered.
 * </para>
 * <para>
 * Change notifications are guaranteed to only ever be delivered in the #GMainContext which
 * was the thread default main context at cursor creation time.
 * </para>
 * </refsect2>
 *
 * <refsect2 id="cursor-search">
 * <title>Search Expressions</title>
 * <para>
 * The list of contacts associated to a given cursor can be filtered
 * with a search expression generated by e_book_query_to_string(). Since
 * this effects how the data will be traversed in the backend, seach
 * expressions come with the same limitation as sort keys. Backends
 * will report %E_CLIENT_ERROR_INVALID_QUERY for contact fields which
 * are not supported. For the default local addressbook, any fields
 * which are configured in the summary can be used to filter cursor
 * results.
 * </para>
 * <para>
 * Changing the search expression can be done at any time using
 * e_book_client_cursor_set_sexp().
 * The cursor <link linkend="cursor-pos-total">position and total</link>
 * values will be updated synchronously after successfully setting the
 * search expression at which time you might refresh the current
 * view, displaying the new filtered list of contacts at the same
 * cursor position.
 * </para>
 * <inlinegraphic fileref="cursor-positions-filtered.png" format="PNG" align="center"></inlinegraphic>
 * </refsect2>
 *
 * <refsect2 id="cursor-iteration">
 * <title>Iteration with the cursor API</title>
 * <para>
 * The cursor API allows you to iterate through a sorted list of contacts
 * without keeping a potentially large collection of contacts loaded
 * in memory.
 * </para>
 * <para>
 * Iterating through the contact list is done with e_book_client_cursor_step(), this
 * function allows one to move the cursor and fetch the results following the current
 * cursor position.
 * |[
 *     GError *error = NULL;
 *     GSList *results = NULL;
 *     gint n_results;
 *
 *     // Move the cursor forward by 10 contacts and fetch the results.
 *     n_results = e_book_client_cursor_step_sync (cursor,
 *                                                 E_BOOK_CURSOR_STEP_MOVE |
 *                                                 E_BOOK_CURSOR_STEP_FETCH,
 *                                                 E_BOOK_CURSOR_ORIGIN_CURRENT,
 *                                                 10,
 *                                                 &results,
 *                                                 NULL,
 *                                                 &error);
 *
 *     if (n_results < 0)
 *       {
 *         if (g_error_matches (error,
 *                              E_CLIENT_ERROR,
 *                              E_CLIENT_ERROR_OUT_OF_SYNC))
 *           {
 *             // The addressbook has been modified at the same time as
 *             // we asked to step. The appropriate thing to do is wait
 *             // for the "refresh" signal before trying again.
 *             handle_out_of_sync_condition (cursor);
 *           }
 *         else if (g_error_matches (error,
 *                                   E_CLIENT_ERROR,
 *                                   E_CLIENT_ERROR_QUERY_REFUSED))
 *           {
 *             // We asked for 10 contacts but were already positioned
 *             // at the end of the list (or we asked for -10 contacts
 *             // and were positioned at the beginning).
 *             handle_end_of_list_condition (cursor);
 *           }
 *         else
 *           {
 *             // Some error actually occurred
 *             handle_error_condition (cursor, error);
 *           }
 *
 *         g_clear_error (&error);
 *       }
 *     else if (n_results < 10)
 *       {
 *         // Cursor did not traverse as many contacts as requested.
 *         //
 *         // This is not an error but rather an indication that
 *         // the end of the list was reached. The next attempt to
 *         // move the cursor in the same direction will result in
 *         // an E_CLIENT_ERROR_QUERY_REFUSED error.
 *       }
 * ]|
 * In the above example we chose %E_BOOK_CURSOR_ORIGIN_CURRENT as our #EBookCursorOrigin so the above
 * call will traverse 10 contacts following the cursor's current position. One can also choose the
 * %E_BOOK_CURSOR_ORIGIN_BEGIN or %E_BOOK_CURSOR_ORIGIN_END origin to start at the beginning or end
 * of the results at any time.
 * </para>
 * <para>
 * We also specified both of the flags %E_BOOK_CURSOR_STEP_MOVE and %E_BOOK_CURSOR_STEP_FETCH,
 * this means we want to receive results from the addressbook and we also want to modify
 * the current cursor state (move the cursor), these operations can however be done
 * completely independantly of eachother, which is often what is desired for a contact
 * browsing user interface. It is however recommended to move and fetch
 * results in a single pass wherever that makes sense in your application.
 * </para>
 * <para>
 * Because the addressbook might be modified at any time by another application,
 * it's important to handle the %E_CLIENT_ERROR_OUT_OF_SYNC error. This error will occur
 * at any time that the cursor detects an addressbook change while trying to step.
 * Whenever an out of sync condition arises, the cursor should be left alone until the
 * next #EBookClientCursor::refresh signal. The #EBookClientCursor::refresh signal is triggered
 * any time that the addressbook changes and is the right place to refresh the currently
 * loaded content, it is also guaranteed to be triggered after any %E_CLIENT_ERROR_OUT_OF_SYNC
 * error.
 * </para>
 * <para>
 * The diagram below illustrates some scenarios of how the cursor state is updated
 * in calls to e_book_client_cursor_step().
 * </para>
 * <inlinegraphic fileref="cursor-positions-step.png" format="PNG" align="center"></inlinegraphic>
 * </refsect2>
 *
 * <refsect2 id="cursor-alphabet">
 * <title>Alphabetic Indexes</title>
 * <para>
 * The cursor permits navigation of the sorted contact list in terms of alphabetic
 * positions in the list, allowing one to jump from one letter to the next in
 * the active alphabet.
 * </para>
 * <para>
 * The active alphabet itself is represented as an array of UTF-8 strings which are
 * suitable to display a given glyph or alphabetic position in the user's active alphabet.
 * This array of alphabetic position labels is exposed via the #EBookClientCursor:alphabet
 * property and can always be fetched with e_book_client_cursor_get_alphabet().
 * </para>
 * <para>
 * As shown below, each index in the active alphabet array is a potential cursor state
 * which refers to a position before, after or in between contacts in the sorted contact list.
 * Most of the positions in the active alphabet array refer to alphabetic glyhps or positions,
 * however the the 'underflow', 'inflow' and 'overflow' positions represent positions for
 * contacts which sort outside the bounderies of the active alphabet.
 * </para>
 * <inlinegraphic fileref="cursor-alphabetic-indexes.png" format="PNG" align="center"></inlinegraphic>
 * <para>
 * The active alphabet is dynamically resolved from the system locale at startup time and
 * whenever a system locale change notification is delivered to Evolution Data Server. If
 * ever the system locale changes at runtime then a change notification will be delivered
 * for the #EBookClientCursor:alphabet property, this is a good time to refresh the list
 * of alphabetic positions available in a user interface.
 * </para>
 * <para>
 * Using the active alphabet, one can build a user interface which allows the user
 * to navigate to a specific letter in the results. To set the cursor's position
 * directly before any results starting with a specific letter, one can use
 * e_book_client_cursor_set_alphabetic_index().
 * |[
 *     GError *error = NULL;
 *     gint index = currently_selected_index (user_interface);
 *
 *     // At this point 'index' must be a numeric value corresponding
 *     // to one of the positions in the array returned by
 *     // e_book_client_cursor_get_alphabet().
 *     if (!e_book_client_cursor_set_alphabetic_index_sync (cursor,
 *                                                          index,
 *                                                          NULL,
 *                                                          &error))
 *       {
 *         if (g_error_matches (error,
 *                              E_CLIENT_ERROR,
 *                              E_CLIENT_ERROR_OUT_OF_SYNC))
 *           {
 *             // The system locale has changed at the same time
 *             // as we were setting an alphabetic cursor position.
 *             handle_out_of_sync_condition (cursor);
 *           }
 *         else
 *           {
 *             // Some error actually occurred
 *             handle_error_condition (cursor, error);
 *           }
 *
 *         g_clear_error (&error);
 *       }
 * ]|
 * After setting the alphabetic index successfully, you can go ahead
 * and use e_book_client_cursor_step() to load some contacts at the
 * beginning of the given letter.
 * </para>
 * <para>
 * This API can result in an %E_CLIENT_ERROR_OUT_OF_SYNC error. This error will
 * occur at any time that the cursor tries to set the alphabetic index whilst the
 * addressbook is changing its active locale setting. In the case of a dynamic locale
 * change, a change notification will be delivered for the #EBookClientCursor:alphabet
 * property at which point the application should reload anything related to the
 * alphabet (a #EBookClientCursor::refresh signal will also be delivered at this point).
 * </para>
 * <para>
 * While moving through the cursor results using e_book_client_cursor_step(),
 * it can be useful to know which alphabetic position a given contact sorts
 * under. This can be useful if your user interface displays an alphabetic
 * label indicating where the first contact in your view is positioned in
 * the alphabet.
 * </para>
 * <para>
 * One can determine the appropriate index for a given #EContact by calling
 * e_book_client_cursor_get_contact_alphabetic_index() after refreshing
 * the currently displayed contacts in a view.
 * |[
 *     EContact *contact;
 *     const gchar * const *alphabet;
 *     gint index;
 *
 *     // Fetch the first displayed EContact in the view
 *     contact = first_contact_in_the_list (user_interface);
 *
 *     // Calculate the position in the alphabet for this contact
 *     index = e_book_client_cursor_get_contact_alphabetic_index (cursor, contact);
 *
 *     // Fetch the alphabet labels
 *     alphabet = e_book_client_cursor_get_alphabet (cursor, &n_labels,
 *                                                   NULL, NULL, NULL);
 *
 *     // Update label in user interface
 *     set_alphabetic_position_feedback_text (user_interface, alphabet[index]);
 * ]|
 * </para>
 * </refsect2>
 *
 */
#include "evolution-data-server-config.h"

#include <glib/gi18n-lib.h>

#include <libedataserver/libedataserver.h>
#include <libedata-book/libedata-book.h>

/* Private D-Bus class. */
#include <e-dbus-address-book-cursor.h>

#include "e-book-client.h"
#include "e-book-client-cursor.h"

#define E_BOOK_CLIENT_CURSOR_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_BOOK_CLIENT_CURSOR, EBookClientCursorPrivate))

/* Forward declarations */
typedef struct _SetSexpContext        SetSexpContext;
typedef struct _StepContext           StepContext;
typedef struct _AlphabetIndexContext  AlphabetIndexContext;
typedef enum   _NotificationType      NotificationType;
typedef struct _Notification          Notification;

/* GObjectClass */
static void          book_client_cursor_dispose            (GObject                *object);
static void          book_client_cursor_finalize           (GObject                *object);
static void          book_client_cursor_set_property       (GObject                *object,
							    guint                   property_id,
							    const GValue           *value,
							    GParamSpec             *pspec);
static void          book_client_cursor_get_property       (GObject                *object,
							    guint                   property_id,
							    GValue                 *value,
							    GParamSpec             *pspec);

/* GInitable */
static void	     e_book_client_cursor_initable_init    (GInitableIface         *iface);
static gboolean      book_client_cursor_initable_init      (GInitable              *initable,
							    GCancellable           *cancellable,
							    GError                **error);

/* Private mutators */
static void          book_client_cursor_set_client         (EBookClientCursor      *cursor,
							    EBookClient            *client);
static void          book_client_cursor_set_context        (EBookClientCursor      *cursor,
							    GMainContext           *context);
static GMainContext *book_client_cursor_ref_context        (EBookClientCursor      *cursor);
static gboolean      book_client_cursor_context_is_current (EBookClientCursor      *cursor);
static void          book_client_cursor_set_proxy          (EBookClientCursor      *cursor,
							    EDBusAddressBookCursor *proxy);
static void          book_client_cursor_set_connection     (EBookClientCursor      *cursor,
							    GDBusConnection        *connection);
static void          book_client_cursor_set_direct_cursor  (EBookClientCursor      *cursor,
							    EDataBookCursor        *direct_cursor);
static void          book_client_cursor_set_object_path    (EBookClientCursor      *cursor,
							    const gchar            *object_path);
static void          book_client_cursor_set_locale         (EBookClientCursor      *cursor,
							    const gchar            *locale);
static void          book_client_cursor_set_revision       (EBookClientCursor      *cursor,
							    const gchar            *revision);
static void          book_client_cursor_set_total          (EBookClientCursor      *cursor,
							    gint                    total);
static void          book_client_cursor_set_position       (EBookClientCursor      *cursor,
							    gint                    position);

/* Notifications from other threads */
static void          notification_new_string               (EBookClientCursor      *cursor,
							    NotificationType        type,
							    const gchar            *value);
static void          notification_new_int                  (EBookClientCursor      *cursor,
							    NotificationType        type,
							    gint                    value);
static void          notification_free                     (Notification           *notification);
static void          notification_queue                    (EBookClientCursor      *cursor,
							    Notification           *notification);
static gboolean      notification_dispatch                 (GWeakRef               *weak_ref);

/* Callbacks from EBookClient */
static void	     client_revision_changed_cb            (EClient                *client,
							    const gchar            *prop_name,
							    const gchar            *prop_value,
							    GWeakRef               *weak_ref);
static void	     client_locale_changed_cb              (EBookClient            *book_client,
							    GParamSpec             *pspec,
							    GWeakRef               *weak_ref);

/* Callbacks from EDBusAddressBookCursor */
static void	     proxy_total_changed_cb                (EDBusAddressBookCursor *proxy,
							    GParamSpec             *pspec,
							    GWeakRef               *weak_ref);
static void	     proxy_position_changed_cb             (EDBusAddressBookCursor *proxy,
							    GParamSpec             *pspec,
							    GWeakRef               *weak_ref);

/* Callbacks from EDataBookCursor */
static void	     dra_total_changed_cb                  (EDataBookCursor        *direct_cursor,
							    GParamSpec             *pspec,
							    EBookClientCursor      *cursor);
static void	     dra_position_changed_cb               (EDataBookCursor        *direct_cursor,
							    GParamSpec             *pspec,
							    EBookClientCursor      *cursor);

/* Threaded method call contexts */
static SetSexpContext       *set_sexp_context_new          (const gchar            *sexp);
static void                  set_sexp_context_free         (SetSexpContext         *context);
static void                  set_sexp_thread               (GSimpleAsyncResult     *simple,
							    GObject                *source_object,
							    GCancellable           *cancellable);
static StepContext          *step_context_new              (const gchar            *revision,
							    EBookCursorStepFlags    flags,
							    EBookCursorOrigin       origin,
							    gint                    count);
static void                  step_context_free             (StepContext            *context);
static void                  step_thread                   (GSimpleAsyncResult     *simple,
							    GObject                *source_object,
							    GCancellable           *cancellable);
static AlphabetIndexContext *alphabet_index_context_new    (gint                    index,
							    const gchar            *locale);
static void                  alphabet_index_context_free   (AlphabetIndexContext   *context);
static void                  alphabet_index_thread         (GSimpleAsyncResult     *simple,
							    GObject                *source_object,
							    GCancellable           *cancellable);

enum _NotificationType {
	REVISION_CHANGED = 0,
	LOCALE_CHANGED,
	TOTAL_CHANGED,
	POSITION_CHANGED,
	N_NOTIFICATION_TYPES
};

struct _Notification {
	GWeakRef cursor;
	NotificationType type;
	GValue value;
};

struct _EBookClientCursorPrivate {
	/* Strong reference to the EBookClient and
	 * to the GMainContext in which notifications
	 * should be delivered to the EBookClientCursor user */
	EBookClient  *client;
	GMainContext *main_context;
	GMutex        main_context_lock;

	/* Connection with the addressbook cursor over D-Bus */
	EDBusAddressBookCursor *dbus_proxy;
	GDBusConnection        *connection;
	gchar                  *object_path;

	/* Direct Read Access to the addressbook cursor */
	EDataBookCursor *direct_cursor;

	/* A local copy of the #EContactFields we are
	 * sorting by (field names)
	 */
	gchar **sort_fields;

	/* Keep a handle on the current locale according
	 * to the EBookClient, this is also how we
	 * derive the active alphabet
	 */
	gchar *locale;

	/* Keep a handle on the revision, we need to
	 * hold on to the currently known revision for
	 * DRA mode cursors. Also we trigger the
	 * refresh signal in normal mode whenever the
	 * revision changes
	 */
	gchar *revision;

	/* A handy collator which we change with locale changes.
	 */
	ECollator *collator;
	gint       n_labels; /* The amount of labels in the active alphabet */

	/* Client side positional values */
	gint    position;
	gint    total;

	/* Make sure all notifications are delivered in a single idle callback */
	GSource      *notification_source;
	Notification *notification[N_NOTIFICATION_TYPES];
	GMutex        notifications_lock;

	/* Signal connection ids */
	gulong revision_changed_id;
	gulong locale_changed_id;
	gulong proxy_total_changed_id;
	gulong proxy_position_changed_id;
	gulong dra_total_changed_id;
	gulong dra_position_changed_id;
};

enum {
	PROP_0,
	PROP_SORT_FIELDS,
	PROP_CLIENT,
	PROP_CONTEXT,
	PROP_CONNECTION,
	PROP_OBJECT_PATH,
	PROP_DIRECT_CURSOR,
	PROP_ALPHABET,
	PROP_TOTAL,
	PROP_POSITION,
};

enum {
	REFRESH,
	LAST_SIGNAL
};

static guint signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_CODE (
	EBookClientCursor,
	e_book_client_cursor,
	G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_book_client_cursor_initable_init))

/****************************************************
 *                  GObjectClass                    *
 ****************************************************/
static void
e_book_client_cursor_class_init (EBookClientCursorClass *class)
{
	GObjectClass *object_class;

	object_class = G_OBJECT_CLASS (class);
	object_class->dispose = book_client_cursor_dispose;
	object_class->finalize = book_client_cursor_finalize;
	object_class->set_property = book_client_cursor_set_property;
	object_class->get_property = book_client_cursor_get_property;

	/**
	 * EBookClientCursor:sort-fields:
	 *
	 * The #EContactField names to sort this cursor with
	 *
	 * <note><para>This is an internal parameter for constructing the
	 * cursor, to construct the cursor use e_book_client_get_cursor().
	 * </para></note>
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_SORT_FIELDS,
		g_param_spec_boxed (
			"sort-fields",
			"Sort Fields",
			"The #EContactField names to sort this cursor with",
			G_TYPE_STRV,
			G_PARAM_WRITABLE |
			G_PARAM_CONSTRUCT_ONLY));

	/**
	 * EBookClientCursor:client:
	 *
	 * The #EBookClient which this cursor was created for
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_CLIENT,
		g_param_spec_object (
			"client",
			"Client",
			"The EBookClient for the cursor",
			E_TYPE_BOOK_CLIENT,
			G_PARAM_READWRITE |
			G_PARAM_CONSTRUCT_ONLY));

	/**
	 * EBookClientCursor:context:
	 *
	 * The #GMainContext in which the #EBookClient created this cursor.
	 *
	 * <note><para>This is an internal parameter for constructing the
	 * cursor, to construct the cursor use e_book_client_get_cursor().
	 * </para></note>
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_CONTEXT,
		g_param_spec_boxed (
			"context",
			"Context",
			"The GMainContext in which this cursor was created",
			G_TYPE_MAIN_CONTEXT,
			G_PARAM_WRITABLE |
			G_PARAM_CONSTRUCT_ONLY));

	/**
	 * EBookClientCursor:connection:
	 *
	 * The #GDBusConnection to the addressbook server.
	 *
	 * <note><para>This is an internal parameter for constructing the
	 * cursor, to construct the cursor use e_book_client_get_cursor().
	 * </para></note>
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_CONNECTION,
		g_param_spec_object (
			"connection",
			"Connection",
			"The GDBusConnection used "
			"to create the D-Bus proxy",
			G_TYPE_DBUS_CONNECTION,
			G_PARAM_WRITABLE |
			G_PARAM_CONSTRUCT_ONLY));

	/**
	 * EBookClientCursor:object-path:
	 *
	 * The D-Bus object path to find the server side cursor object.
	 *
	 * <note><para>This is an internal parameter for constructing the
	 * cursor, to construct the cursor use e_book_client_get_cursor().
	 * </para></note>
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_OBJECT_PATH,
		g_param_spec_string (
			"object-path",
			"Object Path",
			"The object path used "
			"to create the D-Bus proxy",
			NULL,
			G_PARAM_WRITABLE |
			G_PARAM_CONSTRUCT_ONLY |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EBookClientCursor:direct-cursor:
	 *
	 * The direct handle to the #EDataBookCursor for direct read access mode.
	 *
	 * <note><para>This is an internal parameter for constructing the
	 * cursor, to construct the cursor use e_book_client_get_cursor().
	 * </para></note>
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_DIRECT_CURSOR,
		g_param_spec_object (
			"direct-cursor",
			"Direct Cursor",
			"The EDataBookCursor for direct read access",
			E_TYPE_DATA_BOOK_CURSOR,
			G_PARAM_WRITABLE |
			G_PARAM_CONSTRUCT_ONLY));

	/**
	 * EBookClientCursor:alphabet:
	 *
	 * The currently <link linkend="cursor-alphabet">active alphabet</link>.
	 * 
	 * The value is a %NULL terminated array of strings,
	 * each string is suitable to display a specific letter
	 * in the active alphabet.
	 *
	 * Indexes from this array can later be used with 
	 * e_book_client_cursor_set_alphabetic_index().
	 *
	 * This property will automatically change if the
	 * active locale of the addressbook server changes.
	 *
	 * Property change notifications are guaranteed to be
	 * delivered in the #GMainContext which was the thread
	 * default context at cursor creation time.
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_ALPHABET,
		g_param_spec_boxed (
			"alphabet",
			"Alphabet",
			"The active alphabet",
			G_TYPE_STRV,
			G_PARAM_READABLE |
			G_PARAM_STATIC_STRINGS));

	/**
	 * EBookClientCursor:total:
	 *
	 * The total number of contacts which satisfy the cursor's query.
	 *
	 * Property change notifications are guaranteed to be
	 * delivered in the #GMainContext which was the thread
	 * default context at cursor creation time.
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_TOTAL,
		g_param_spec_int (
			"total",
			"Total",
			"The total contacts for this cursor's query",
			0, G_MAXINT, 0,
			G_PARAM_READABLE));

	/**
	 * EBookClientCursor:position:
	 *
	 * The current cursor position in the cursor's result list.
	 *
	 * More specifically, the cursor position is defined as
	 * the number of contacts leading up to the current
	 * cursor position, inclusive of the current cursor
	 * position.
	 *
	 * If the position value is 0, then the cursor is positioned
	 * before the contact list in the symbolic %E_BOOK_CURSOR_ORIGIN_BEGIN
	 * position. If the position value is greater than 
	 * #EBookClientCursor:total, this indicates that the cursor is
	 * positioned after the contact list in the symbolic
	 * %E_BOOK_CURSOR_ORIGIN_END position.
	 *
	 * Property change notifications are guaranteed to be
	 * delivered in the #GMainContext which was the thread
	 * default context at cursor creation time.
	 *
	 * Since: 3.12
	 */
	g_object_class_install_property (
		object_class,
		PROP_POSITION,
		g_param_spec_int (
			"position",
			"Position",
			"The current cursor position",
			0, G_MAXINT, 0,
			G_PARAM_READABLE));

	/**
	 * EBookClientCursor::refresh:
	 * @cursor: The #EBookClientCursor which needs to be refreshed
	 *
	 * Indicates that the addressbook has been modified and
	 * that any content currently being displayed from the current
	 * cursor position should be reloaded.
	 *
	 * This signal is guaranteed to be delivered in the #GMainContext
	 * which was the thread default context at cursor creation time.
	 *
	 * Since: 3.12
	 */
	signals[REFRESH] = g_signal_new (
		"refresh",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EBookClientCursorClass, refresh),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);

	g_type_class_add_private (class, sizeof (EBookClientCursorPrivate));
}

static void
e_book_client_cursor_init (EBookClientCursor *cursor)
{
	cursor->priv = E_BOOK_CLIENT_CURSOR_GET_PRIVATE (cursor);

	g_mutex_init (&cursor->priv->main_context_lock);
	g_mutex_init (&cursor->priv->notifications_lock);
}

static void
book_client_cursor_dispose (GObject *object)
{
	EBookClientCursor *cursor = E_BOOK_CLIENT_CURSOR (object);
	EBookClientCursorPrivate *priv = cursor->priv;
	gint i;

	book_client_cursor_set_direct_cursor (cursor, NULL);
	book_client_cursor_set_client (cursor, NULL);
	book_client_cursor_set_proxy (cursor, NULL);
	book_client_cursor_set_connection (cursor, NULL);
	book_client_cursor_set_context (cursor, NULL);

	g_mutex_lock (&cursor->priv->notifications_lock);
	if (priv->notification_source) {
		g_source_destroy (priv->notification_source);
		g_source_unref (priv->notification_source);
		priv->notification_source = NULL;
	}

	for (i = 0; i < N_NOTIFICATION_TYPES; i++) {
		notification_free (priv->notification[i]);
		priv->notification[i] = NULL;
	}
	g_mutex_unlock (&cursor->priv->notifications_lock);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_book_client_cursor_parent_class)->dispose (object);
}

static void
book_client_cursor_finalize (GObject *object)
{
	EBookClientCursor        *cursor = E_BOOK_CLIENT_CURSOR (object);
	EBookClientCursorPrivate *priv = cursor->priv;

	g_free (priv->locale);
	g_free (priv->revision);
	g_free (priv->object_path);
	if (priv->sort_fields)
		g_strfreev (priv->sort_fields);
	if (priv->collator)
		e_collator_unref (priv->collator);
	g_mutex_clear (&priv->main_context_lock);
	g_mutex_clear (&cursor->priv->notifications_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_book_client_cursor_parent_class)->finalize (object);
}

static void
book_client_cursor_set_property (GObject *object,
                                 guint property_id,
                                 const GValue *value,
                                 GParamSpec *pspec)
{
	EBookClientCursor        *cursor = E_BOOK_CLIENT_CURSOR (object);
	EBookClientCursorPrivate *priv = cursor->priv;

	switch (property_id) {
	case PROP_SORT_FIELDS:
		priv->sort_fields = g_value_dup_boxed (value);
		break;

	case PROP_CLIENT:
		book_client_cursor_set_client (
			E_BOOK_CLIENT_CURSOR (object),
			g_value_get_object (value));
		break;

	case PROP_CONTEXT:
		book_client_cursor_set_context (
			E_BOOK_CLIENT_CURSOR (object),
			g_value_get_boxed (value));
		break;

	case PROP_CONNECTION:
		book_client_cursor_set_connection (
			E_BOOK_CLIENT_CURSOR (object),
			g_value_get_object (value));
		break;

	case PROP_OBJECT_PATH:
		book_client_cursor_set_object_path (
			E_BOOK_CLIENT_CURSOR (object),
			g_value_get_string (value));
		break;

	case PROP_DIRECT_CURSOR:
		book_client_cursor_set_direct_cursor (
			E_BOOK_CLIENT_CURSOR (object),
			g_value_get_object (value));
		break;

	default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;
	}
}

static void
book_client_cursor_get_property (GObject *object,
                                 guint property_id,
                                 GValue *value,
                                 GParamSpec *pspec)
{
	switch (property_id) {
	case PROP_CLIENT:
		g_value_take_object (
			value,
			e_book_client_cursor_ref_client (
				E_BOOK_CLIENT_CURSOR (object)));
		break;

	case PROP_ALPHABET:
		g_value_set_boxed (
			value,
			e_book_client_cursor_get_alphabet (
				E_BOOK_CLIENT_CURSOR (object),
				NULL, NULL, NULL, NULL));
		break;

	case PROP_TOTAL:
		g_value_set_int (
			value,
			e_book_client_cursor_get_total (
				E_BOOK_CLIENT_CURSOR (object)));
		break;

	case PROP_POSITION:
		g_value_set_int (
			value,
			e_book_client_cursor_get_position (
				E_BOOK_CLIENT_CURSOR (object)));
		break;

	default:
		G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
		break;

	}
}

/****************************************************
 *                    GInitable                     *
 ****************************************************/
static void
e_book_client_cursor_initable_init (GInitableIface *iface)
{
	iface->init = book_client_cursor_initable_init;
}

static gboolean
book_client_cursor_initable_init (GInitable *initable,
                                  GCancellable *cancellable,
                                  GError **error)
{
	EBookClientCursor        *cursor = E_BOOK_CLIENT_CURSOR (initable);
	EBookClientCursorPrivate *priv = cursor->priv;
	EDBusAddressBookCursor   *proxy;
	gchar                    *bus_name;

	/* We only need a proxy for regular access, no need in DRA mode */
	if (priv->direct_cursor)
		return TRUE;

	bus_name = e_client_dup_bus_name (E_CLIENT (priv->client));

	proxy = e_dbus_address_book_cursor_proxy_new_sync (
		priv->connection,
		G_DBUS_PROXY_FLAGS_NONE,
		bus_name,
		priv->object_path,
		cancellable, error);

	g_free (bus_name);

	if (!proxy)
		return FALSE;

	book_client_cursor_set_proxy (cursor, proxy);
	g_object_unref (proxy);

	return TRUE;
}

/****************************************************
 *                Private Mutators                  *
 ****************************************************
 *
 * All private mutators are called either in the thread
 * which e_book_client_get_cursor() was originally called,
 * or in the object construction process where there is
 * a well known strong reference to the EBookClientCursor
 * instance.
 */
static void
book_client_cursor_set_client (EBookClientCursor *cursor,
                               EBookClient *client)
{
	EBookClientCursorPrivate *priv = cursor->priv;

	g_return_if_fail (client == NULL || E_IS_BOOK_CLIENT (client));

	/* Clients can't really change, but we set up this
	 * mutator style code just to manage the signal connections
	 * we watch on the client, we need to disconnect them properly.
	 */
	if (priv->client != client) {

		if (priv->client) {

			/* Disconnect signals */
			g_signal_handler_disconnect (priv->client, priv->revision_changed_id);
			g_signal_handler_disconnect (priv->client, priv->locale_changed_id);
			priv->revision_changed_id = 0;
			priv->locale_changed_id = 0;
			g_object_unref (priv->client);
		}

		/* Set the new client */
		priv->client = client;

		if (priv->client) {
			gchar *revision = NULL;

			/* Connect signals */
			priv->revision_changed_id =
				g_signal_connect_data (
					client, "backend-property-changed",
					G_CALLBACK (client_revision_changed_cb),
					e_weak_ref_new (cursor),
					(GClosureNotify) e_weak_ref_free,
					0);
			priv->locale_changed_id =
				g_signal_connect_data (
					client, "notify::locale",
					G_CALLBACK (client_locale_changed_cb),
					e_weak_ref_new (cursor),
					(GClosureNotify) e_weak_ref_free,
					0);

			/* Load initial locale & revision */
			book_client_cursor_set_locale (cursor, e_book_client_get_locale (priv->client));

			/* This loads a cached D-Bus property, no D-Bus activity */
			e_client_get_backend_property_sync (
				E_CLIENT (priv->client),
				CLIENT_BACKEND_PROPERTY_REVISION,
				&revision, NULL, NULL);
			book_client_cursor_set_revision (cursor, revision);
			g_free (revision);

			g_object_ref (priv->client);
		}
	}
}

static void
book_client_cursor_set_connection (EBookClientCursor *cursor,
                                   GDBusConnection *connection)
{
	EBookClientCursorPrivate *priv = cursor->priv;

	g_return_if_fail (connection == NULL || G_IS_DBUS_CONNECTION (connection));

	if (priv->connection != connection) {

		if (priv->connection)
			g_object_unref (priv->connection);

		priv->connection = connection;

		if (priv->connection)
			g_object_ref (priv->connection);
	}
}

static void
proxy_dispose_cb (GObject *source_object,
                  GAsyncResult *result,
                  gpointer user_data)
{
	GError *local_error = NULL;

	e_dbus_address_book_cursor_call_dispose_finish (
		E_DBUS_ADDRESS_BOOK_CURSOR (source_object), result, &local_error);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_warning ("%s: %s", G_STRFUNC, local_error->message);
		g_error_free (local_error);
	}
}

static void
book_client_cursor_set_proxy (EBookClientCursor *cursor,
                              EDBusAddressBookCursor *proxy)
{
	EBookClientCursorPrivate *priv = cursor->priv;

	g_return_if_fail (proxy == NULL || E_DBUS_IS_ADDRESS_BOOK_CURSOR (proxy));

	if (priv->dbus_proxy != proxy) {

		if (priv->dbus_proxy) {
			g_signal_handler_disconnect (priv->dbus_proxy, priv->proxy_total_changed_id);
			g_signal_handler_disconnect (priv->dbus_proxy, priv->proxy_position_changed_id);
			priv->proxy_total_changed_id = 0;
			priv->proxy_position_changed_id = 0;

			/* Call D-Bus dispose() asynchronously
			 * so we don't block in our dispose() phase.*/
			e_dbus_address_book_cursor_call_dispose (
				priv->dbus_proxy, NULL,
				proxy_dispose_cb, NULL);

			g_object_unref (priv->dbus_proxy);
		}

		priv->dbus_proxy = proxy;

		if (priv->dbus_proxy) {
			gint position, total;

			priv->proxy_total_changed_id =
				g_signal_connect_data (
					priv->dbus_proxy, "notify::total",
					G_CALLBACK (proxy_total_changed_cb),
					e_weak_ref_new (cursor),
					(GClosureNotify) e_weak_ref_free,
					0);
			priv->proxy_position_changed_id =
				g_signal_connect_data (
					priv->dbus_proxy, "notify::position",
					G_CALLBACK (proxy_position_changed_cb),
					e_weak_ref_new (cursor),
					(GClosureNotify) e_weak_ref_free,
					0);

			/* Set initial values */
			total = e_dbus_address_book_cursor_get_total (proxy);
			position = e_dbus_address_book_cursor_get_position (proxy);
			book_client_cursor_set_total (cursor, total);
			book_client_cursor_set_position (cursor, position);

			g_object_ref (priv->dbus_proxy);
		}
	}
}

static void
book_client_cursor_set_context (EBookClientCursor *cursor,
                                GMainContext *context)
{
	EBookClientCursorPrivate *priv = cursor->priv;

	g_mutex_lock (&cursor->priv->main_context_lock);

	if (priv->main_context != context) {
		if (priv->main_context)
			g_main_context_unref (priv->main_context);

		priv->main_context = context;

		if (priv->main_context)
			g_main_context_ref (priv->main_context);
	}

	g_mutex_unlock (&cursor->priv->main_context_lock);
}

static GMainContext *
book_client_cursor_ref_context (EBookClientCursor *cursor)
{
	GMainContext *main_context = NULL;

	/* This is called from D-Bus callbacks which will fire from
	 * whichever thread the EBookClient created the EBookClientCursor
	 * in, and also from EBookClient signal callbacks which get
	 * fired in the thread that the EBookClient was created in,
	 * which might not be the same thread that e_book_client_get_cursor()
	 * was called from.
	 */
	g_mutex_lock (&cursor->priv->main_context_lock);

	if (cursor->priv->main_context)
		main_context = g_main_context_ref (cursor->priv->main_context);

	g_mutex_unlock (&cursor->priv->main_context_lock);

	return main_context;
}

static gboolean
book_client_cursor_context_is_current (EBookClientCursor *cursor)
{
	GMainContext *main_context, *current_context;
	gboolean is_current = FALSE;

	main_context = book_client_cursor_ref_context (cursor);
	current_context = g_main_context_ref_thread_default ();

	if (main_context) {

		is_current = (main_context == current_context);

		g_main_context_unref (main_context);
	}

	g_main_context_unref (current_context);

	return is_current;
}

/* Secretly shared API */
void book_client_delete_direct_cursor (EBookClient *client,
				       EDataBookCursor *cursor);

static void
book_client_cursor_set_direct_cursor (EBookClientCursor *cursor,
                                      EDataBookCursor *direct_cursor)
{
	EBookClientCursorPrivate *priv = cursor->priv;

	g_return_if_fail (direct_cursor == NULL || E_IS_DATA_BOOK_CURSOR (direct_cursor));

	if (priv->direct_cursor != direct_cursor) {

		if (priv->direct_cursor) {

			g_signal_handler_disconnect (priv->direct_cursor, priv->dra_total_changed_id);
			g_signal_handler_disconnect (priv->direct_cursor, priv->dra_position_changed_id);
			priv->dra_total_changed_id = 0;
			priv->dra_position_changed_id = 0;

			/* Tell EBookClient to delete the cursor
			 *
			 * This should only happen in ->dispose()
			 * before releasing our strong reference to the EBookClient
			 */
			g_warn_if_fail (priv->client != NULL);
			book_client_delete_direct_cursor (
				priv->client,
				priv->direct_cursor);

			g_object_unref (priv->direct_cursor);
		}

		priv->direct_cursor = direct_cursor;

		if (priv->direct_cursor) {
			GError *error = NULL;
			gchar *freeme = NULL;
			gint total, position;

			priv->dra_total_changed_id =
				g_signal_connect (
					priv->direct_cursor, "notify::total",
					G_CALLBACK (dra_total_changed_cb),
					cursor);
			priv->dra_position_changed_id =
				g_signal_connect (
					priv->direct_cursor, "notify::position",
					G_CALLBACK (dra_position_changed_cb),
					cursor);

			/* Load initial locale */
			if (priv->direct_cursor &&
			    !e_data_book_cursor_load_locale (priv->direct_cursor,
							     &freeme, NULL, &error)) {
				g_warning (
					"Error loading locale in direct read access cursor: %s",
					error->message);
				g_clear_error (&error);
			}
			g_free (freeme);

			/* Set initial values */
			total = e_data_book_cursor_get_total (priv->direct_cursor);
			position = e_data_book_cursor_get_position (priv->direct_cursor);
			book_client_cursor_set_total (cursor, total);
			book_client_cursor_set_position (cursor, position);

			g_object_ref (priv->direct_cursor);
		}
	}
}

static void
book_client_cursor_set_object_path (EBookClientCursor *cursor,
                                    const gchar *object_path)
{
	g_return_if_fail (cursor->priv->object_path == NULL);

	cursor->priv->object_path = g_strdup (object_path);
}

static void
book_client_cursor_set_locale (EBookClientCursor *cursor,
                               const gchar *locale)
{
	EBookClientCursorPrivate *priv = cursor->priv;
	GError                   *error = NULL;

	if (g_strcmp0 (priv->locale, locale) == 0)
		return;

	g_free (priv->locale);
	if (priv->collator)
		e_collator_unref (priv->collator);

	priv->locale = g_strdup (locale);
	priv->collator = e_collator_new (locale, &error);

	if (!priv->collator) {
		g_warning (
			"Error loading collator for locale '%s': %s",
			locale, error->message);
		g_clear_error (&error);
		return;
	}

	e_collator_get_index_labels (
		priv->collator,
		&priv->n_labels,
		NULL, NULL, NULL);

	/* The server side EDataBookCursor should have already
	 * reset its cursor values internally and notified
	 * a new total & position value, however we need to
	 * explicitly load the new locale for DRA cursors.
	 */
	if (priv->direct_cursor &&
	    !e_data_book_cursor_load_locale (priv->direct_cursor, NULL, NULL, &error)) {
		g_warning (
			"Error loading locale in direct read access cursor: %s",
			error->message);
		g_clear_error (&error);
	}

	/* Notify the alphabet change */
	g_object_notify (G_OBJECT (cursor), "alphabet");

	/* The alphabet changing should have been enough,
	 * but still trigger a refresh
	 */
	g_signal_emit (cursor, signals[REFRESH], 0);
}

static void
book_client_cursor_set_revision (EBookClientCursor *cursor,
                                 const gchar *revision)
{
	EBookClientCursorPrivate *priv = cursor->priv;

	if (g_strcmp0 (priv->revision, revision) != 0) {

		g_free (priv->revision);
		priv->revision = g_strdup (revision);

		/* In DRA mode we need to reload our local
		 * total / position calculations with EDataBookCursor APIs
		 */
		if (priv->direct_cursor) {
			GError *error = NULL;

			if (!e_data_book_cursor_recalculate (priv->direct_cursor, NULL, &error)) {
				g_warning ("Error calcualting cursor position: %s", error->message);
			} else {
				g_object_freeze_notify (G_OBJECT (cursor));
				book_client_cursor_set_total (cursor, e_data_book_cursor_get_total (priv->direct_cursor));
				book_client_cursor_set_position (cursor, e_data_book_cursor_get_position (priv->direct_cursor));
				g_object_thaw_notify (G_OBJECT (cursor));
			}
		}

		/* The addressbook has changed, need a refresh */
		g_signal_emit (cursor, signals[REFRESH], 0);
	}
}

static void
book_client_cursor_set_total (EBookClientCursor *cursor,
                              gint total)
{
	EBookClientCursorPrivate *priv = cursor->priv;

	if (priv->total != total) {
		priv->total = total;
		g_object_notify (G_OBJECT (cursor), "total");
	}
}

static void
book_client_cursor_set_position (EBookClientCursor *cursor,
                                 gint position)
{
	EBookClientCursorPrivate *priv = cursor->priv;

	if (priv->position != position) {
		priv->position = position;
		g_object_notify (G_OBJECT (cursor), "position");
	}
}

/****************************************************
 *         Notifications from other threads         *
 ****************************************************
 *
 * The notification subsystem takes care of calling
 * our private mutator functions from the thread in
 * which e_book_client_get_cursor() was originally
 * called, where it's safe to emit signals on the
 * EBookClientCursor instance.
 *
 * The notification functions, notification_new_string()
 * and notification_new_int() must be called where
 * a strong reference to the EBookClientCursor exists.
 */

static void
notification_new_string (EBookClientCursor *cursor,
                         NotificationType type,
                         const gchar *value)
{
	Notification *notification = g_slice_new0 (Notification);

	notification->type = type;
	g_weak_ref_init (&notification->cursor, cursor);

	g_value_init (&notification->value, G_TYPE_STRING);
	g_value_set_string (&notification->value, value);

	notification_queue (cursor, notification);
}

static void
notification_new_int (EBookClientCursor *cursor,
                      NotificationType type,
                      gint value)
{
	Notification *notification = g_slice_new0 (Notification);

	notification->type = type;
	g_weak_ref_init (&notification->cursor, cursor);

	g_value_init (&notification->value, G_TYPE_INT);
	g_value_set_int (&notification->value, value);

	notification_queue (cursor, notification);
}

static void
notification_free (Notification *notification)
{
	if (notification) {
		g_weak_ref_clear (&notification->cursor);
		g_value_unset (&notification->value);
		g_slice_free (Notification, notification);
	}
}

static void
notification_queue (EBookClientCursor *cursor,
                    Notification *notification)
{
	EBookClientCursorPrivate *priv = cursor->priv;
	GMainContext *context;

	g_mutex_lock (&cursor->priv->notifications_lock);

	notification_free (priv->notification[notification->type]);
	priv->notification[notification->type] = notification;

	context = book_client_cursor_ref_context (cursor);

	if (context && priv->notification_source == NULL) {
		/* Hold on to a reference, release our reference in dispatch() */
		priv->notification_source = g_idle_source_new ();
		g_source_set_callback (
			priv->notification_source,
			(GSourceFunc) notification_dispatch,
			e_weak_ref_new (cursor),
			(GDestroyNotify) e_weak_ref_free);
		g_source_attach (priv->notification_source, context);
		g_main_context_unref (context);
	}

	g_mutex_unlock (&cursor->priv->notifications_lock);
}

static gboolean
notification_dispatch (GWeakRef *weak_ref)
{
	EBookClientCursor *cursor;
	EBookClientCursorPrivate *priv;
	Notification *notification[N_NOTIFICATION_TYPES];
	gint i;

	cursor = g_weak_ref_get (weak_ref);
	if (!cursor)
		return FALSE;

	priv = cursor->priv;

	/* Collect notifications now and let notifications
	 * be queued from other threads after this point
	 */
	g_mutex_lock (&cursor->priv->notifications_lock);

	for (i = 0; i < N_NOTIFICATION_TYPES; i++) {
		notification[i] = priv->notification[i];
		priv->notification[i] = NULL;
	}

	g_source_unref (priv->notification_source);
	priv->notification_source = NULL;
	g_mutex_unlock (&cursor->priv->notifications_lock);

	g_object_freeze_notify (G_OBJECT (cursor));

	if (notification[TOTAL_CHANGED])
		book_client_cursor_set_total (
			cursor,
			g_value_get_int (&(notification[TOTAL_CHANGED]->value)));

	if (notification[POSITION_CHANGED])
		book_client_cursor_set_position (
			cursor,
			g_value_get_int (&(notification[POSITION_CHANGED]->value)));

	if (notification[REVISION_CHANGED])
		book_client_cursor_set_revision (
			cursor,
			g_value_get_string (&(notification[REVISION_CHANGED]->value)));

	if (notification[LOCALE_CHANGED])
		book_client_cursor_set_locale (
			cursor,
			g_value_get_string (&(notification[LOCALE_CHANGED]->value)));

	g_object_thaw_notify (G_OBJECT (cursor));

	for (i = 0; i < N_NOTIFICATION_TYPES; i++)
		notification_free (notification[i]);

	g_object_unref (cursor);

	return FALSE;
}

/****************************************************
 *             Callbacks from EBookClient           *
 ****************************************************/
static void
client_revision_changed_cb (EClient *client,
                            const gchar *prop_name,
                            const gchar *prop_value,
                            GWeakRef *weak_ref)
{
	EBookClientCursor *cursor;

	if (g_strcmp0 (prop_name, CLIENT_BACKEND_PROPERTY_REVISION) != 0)
		return;

	cursor = g_weak_ref_get (weak_ref);
	if (cursor) {
		notification_new_string (cursor, REVISION_CHANGED, prop_value);
		g_object_unref (cursor);
	}
}

static void
client_locale_changed_cb (EBookClient *book_client,
                          GParamSpec *pspec,
                          GWeakRef *weak_ref)
{
	EBookClientCursor *cursor;

	cursor = g_weak_ref_get (weak_ref);
	if (cursor) {
		notification_new_string (cursor, LOCALE_CHANGED, e_book_client_get_locale (book_client));
		g_object_unref (cursor);
	}
}

/****************************************************
 *       Callbacks from EDBusAddressBookCursor      *
 ****************************************************/
static void
proxy_total_changed_cb (EDBusAddressBookCursor *proxy,
                         GParamSpec *pspec,
                         GWeakRef *weak_ref)
{
	EBookClientCursor *cursor;

	cursor = g_weak_ref_get (weak_ref);
	if (cursor) {
		notification_new_int (cursor, TOTAL_CHANGED,
				      e_dbus_address_book_cursor_get_total (proxy));
		g_object_unref (cursor);
	}
}

static void
proxy_position_changed_cb (EDBusAddressBookCursor *proxy,
                           GParamSpec *pspec,
                           GWeakRef *weak_ref)
{
	EBookClientCursor *cursor;

	cursor = g_weak_ref_get (weak_ref);
	if (cursor) {
		notification_new_int (cursor, POSITION_CHANGED,
				      e_dbus_address_book_cursor_get_position (proxy));
		g_object_unref (cursor);
	}
}

/****************************************************
 *       Callbacks from EDBusAddressBookCursor      *
 ****************************************************/
static void
dra_total_changed_cb (EDataBookCursor *direct_cursor,
                      GParamSpec *pspec,
                      EBookClientCursor *cursor)
{
	notification_new_int (cursor, TOTAL_CHANGED,
			      e_data_book_cursor_get_total (direct_cursor));
}

static void
dra_position_changed_cb (EDataBookCursor *direct_cursor,
                         GParamSpec *pspec,
                         EBookClientCursor *cursor)
{
	notification_new_int (cursor, POSITION_CHANGED,
			      e_data_book_cursor_get_position (direct_cursor));
}

/****************************************************
 *           Threaded method call contexts          *
 ****************************************************
 *
 * This subsystem is simply a toolbox of helper functions
 * to execute synchronous D-Bus method calls while providing
 * an asynchronous API.
 *
 * We choose this method of asynchronous D-Bus calls only
 * to be consistent with the rest of the libebook library.
 */
struct _StepContext {
	gchar *revision;
	EBookCursorStepFlags flags;
	EBookCursorOrigin origin;
	gint count;
	GSList *contacts;
	guint new_total;
	guint new_position;
	gint n_results;
};

struct _AlphabetIndexContext {
	gint index;
	gchar *locale;
	guint new_total;
	guint new_position;
};

struct _SetSexpContext {
	gchar *sexp;
	guint new_total;
	guint new_position;
};

static SetSexpContext *
set_sexp_context_new (const gchar *sexp)
{
	SetSexpContext *context = g_slice_new0 (SetSexpContext);

	context->sexp = g_strdup (sexp);

	return context;
}

static void
set_sexp_context_free (SetSexpContext *context)
{
	if (context) {
		g_free (context->sexp);
		g_slice_free (SetSexpContext, context);
	}
}

static gboolean
set_sexp_sync_internal (EBookClientCursor *cursor,
                        const gchar *sexp,
                        guint *new_total,
                        guint *new_position,
                        GCancellable *cancellable,
                        GError **error)
{
	EBookClientCursorPrivate *priv;
	gchar *utf8_sexp;
	GError *local_error = NULL;

	priv = cursor->priv;

	if (priv->direct_cursor) {

		if (!e_data_book_cursor_set_sexp (priv->direct_cursor,
						  sexp, cancellable, error))
			return FALSE;

		*new_total = e_data_book_cursor_get_total (priv->direct_cursor);
		*new_position = e_data_book_cursor_get_position (priv->direct_cursor);

		return TRUE;
	}

	utf8_sexp = e_util_utf8_make_valid (sexp);
	e_dbus_address_book_cursor_call_set_query_sync (
		priv->dbus_proxy,
		utf8_sexp,
		new_total,
		new_position,
		cancellable,
		&local_error);
	g_free (utf8_sexp);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static void
set_sexp_thread (GSimpleAsyncResult *simple,
                 GObject *source_object,
                 GCancellable *cancellable)
{
	SetSexpContext *context;
	GError *local_error = NULL;

	context = g_simple_async_result_get_op_res_gpointer (simple);
	set_sexp_sync_internal (
		E_BOOK_CLIENT_CURSOR (source_object),
		context->sexp,
		&context->new_total,
		&context->new_position,
		cancellable,
		&local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

static StepContext *
step_context_new (const gchar *revision,
                  EBookCursorStepFlags flags,
                  EBookCursorOrigin origin,
                  gint count)
{
	StepContext *context = g_slice_new0 (StepContext);

	context->revision = g_strdup (revision);
	context->flags = flags;
	context->origin = origin;
	context->count = count;
	context->n_results = 0;

	return context;
}

static void
step_context_free (StepContext *context)
{
	if (context) {
		g_free (context->revision);
		g_slist_free_full (context->contacts, g_object_unref);
		g_slice_free (StepContext, context);
	}
}

static gint
step_sync_internal (EBookClientCursor *cursor,
                    const gchar *revision,
                    EBookCursorStepFlags flags,
                    EBookCursorOrigin origin,
                    gint count,
                    GSList **out_contacts,
                    guint *new_total,
                    guint *new_position,
                    GCancellable *cancellable,
                    GError **error)
{
	EBookClientCursorPrivate *priv;
	GError *local_error = NULL;
	gchar **vcards = NULL;
	gint n_results = -1;

	priv = cursor->priv;

	if (priv->direct_cursor) {
		GSList *results = NULL, *l;
		GSList *contacts = NULL;

		n_results = e_data_book_cursor_step (
			priv->direct_cursor,
			revision,
			flags,
			origin,
			count,
			&results,
			cancellable,
			error);
		if (n_results < 0)
			return n_results;

		for (l = results; l; l = l->next) {
			gchar *vcard = l->data;
			EContact *contact = e_contact_new_from_vcard (vcard);

			if (contact)
				contacts = g_slist_prepend (contacts, contact);
		}

		g_slist_free_full (results, (GDestroyNotify) g_free);

		if (out_contacts)
			*out_contacts = g_slist_reverse (contacts);
		else
			g_slist_free_full (contacts, g_object_unref);

		*new_total = e_data_book_cursor_get_total (priv->direct_cursor);
		*new_position = e_data_book_cursor_get_position (priv->direct_cursor);

		return n_results;
	}

	e_dbus_address_book_cursor_call_step_sync (
		priv->dbus_proxy,
		revision,
		flags,
		origin,
		count,
		&n_results,
		&vcards,
		new_total,
		new_position,
		cancellable,
		&local_error);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return -1;
	}

	if (vcards != NULL) {
		EContact *contact;
		GSList *tmp = NULL;
		gint i;

		for (i = 0; vcards[i] != NULL; i++) {
			contact = e_contact_new_from_vcard (vcards[i]);
			tmp = g_slist_prepend (tmp, contact);
		}

		if (out_contacts)
			*out_contacts = g_slist_reverse (tmp);
		else
			g_slist_free_full (tmp, g_object_unref);

		g_strfreev (vcards);
	}

	return n_results;
}

static void
step_thread (GSimpleAsyncResult *simple,
             GObject *source_object,
             GCancellable *cancellable)
{
	StepContext *context;
	GError *local_error = NULL;

	context = g_simple_async_result_get_op_res_gpointer (simple);

	context->n_results = step_sync_internal (
		E_BOOK_CLIENT_CURSOR (source_object),
		context->revision,
		context->flags,
		context->origin,
		context->count,
		&(context->contacts),
		&context->new_total,
		&context->new_position,
		cancellable, &local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

static AlphabetIndexContext *
alphabet_index_context_new (gint index,
                            const gchar *locale)
{
	AlphabetIndexContext *context = g_slice_new0 (AlphabetIndexContext);

	context->index = index;
	context->locale = g_strdup (locale);

	return context;
}

static void
alphabet_index_context_free (AlphabetIndexContext *context)
{
	if (context) {
		g_free (context->locale);
		g_slice_free (AlphabetIndexContext, context);
	}
}

static gboolean
set_alphabetic_index_sync_internal (EBookClientCursor *cursor,
                                    gint index,
                                    const gchar *locale,
                                    guint *new_total,
                                    guint *new_position,
                                    GCancellable *cancellable,
                                    GError **error)
{
	EBookClientCursorPrivate *priv;
	GError *local_error = NULL;

	priv = cursor->priv;

	if (priv->direct_cursor) {

		if (!e_data_book_cursor_set_alphabetic_index (priv->direct_cursor,
							      index,
							      locale,
							      cancellable,
							      error))
			return FALSE;

		*new_total = e_data_book_cursor_get_total (priv->direct_cursor);
		*new_position = e_data_book_cursor_get_position (priv->direct_cursor);

		return TRUE;
	}

	e_dbus_address_book_cursor_call_set_alphabetic_index_sync (
		cursor->priv->dbus_proxy,
		index, locale,
		new_total,
		new_position,
		cancellable,
		&local_error);

	if (local_error != NULL) {
		g_dbus_error_strip_remote_error (local_error);
		g_propagate_error (error, local_error);
		return FALSE;
	}

	return TRUE;
}

static void
alphabet_index_thread (GSimpleAsyncResult *simple,
                       GObject *source_object,
                       GCancellable *cancellable)
{
	AlphabetIndexContext *context;
	GError *local_error = NULL;

	context = g_simple_async_result_get_op_res_gpointer (simple);

	set_alphabetic_index_sync_internal (
		E_BOOK_CLIENT_CURSOR (source_object),
		context->index,
		context->locale,
		&context->new_total,
		&context->new_position,
		cancellable,
		&local_error);

	if (local_error != NULL)
		g_simple_async_result_take_error (simple, local_error);
}

/****************************************************
 *                         API                      *
 ****************************************************/
/**
 * e_book_client_cursor_ref_client:
 * @cursor: an #EBookClientCursor
 *
 * Returns the #EBookClientCursor:client associated with @cursor.
 *
 * The returned #EBookClient is referenced because the cursor
 * does not keep a strong reference to the client.
 *
 * Unreference the #EBookClient with g_object_unref() when finished with it.
 *
 * Returns: (transfer full): an #EBookClient
 *
 * Since: 3.12
 */
EBookClient *
e_book_client_cursor_ref_client (EBookClientCursor *cursor)
{
	g_return_val_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor), NULL);

	return g_object_ref (cursor->priv->client);
}

/**
 * e_book_client_cursor_get_alphabet:
 * @cursor: an #EBookClientCursor
 * @n_labels: (out) (allow-none): The number of labels in the active alphabet
 * @underflow: (allow-none) (out): The underflow index, for any words which sort below the active alphabet
 * @inflow: (allow-none) (out): The inflow index, for any words which sort between the active alphabets (if there is more than one)
 * @overflow: (allow-none) (out): The overflow index, for any words which sort above the active alphabet
 *
 * Fetches the array of displayable labels for the <link linkend="cursor-alphabet">active alphabet</link>.
 *
 * The active alphabet is based on the current locale configuration of the
 * addressbook, and can be a different alphabet for locales requiring non-Latin
 * language scripts. These UTF-8 labels are appropriate to display in a user
 * interface to represent the alphabetic position of the cursor in the user's
 * native alphabet.
 *
 * The @underflow, @inflow and @overflow parameters allow one to observe which
 * indexes Evolution Data Server is using to store words which sort outside
 * of the alphabet, for instance words from foreign language scripts and
 * words which start with numeric characters, or other types of character.
 *
 * While the @underflow and @overflow are for words which sort below or
 * above the active alphabets, the @inflow index is for words which sort
 * in between multiple concurrently active alphabets. The active alphabet
 * array might contain more than one alphabet for locales where it is
 * very common or expected to have names in Latin script as well as names
 * in another script.
 *
 * Returns: (array zero-terminated=1) (element-type utf8) (transfer none):
 *   The array of displayable labels for each index in the active alphabet.
 *
 * Since: 3.12
 */
const gchar * const *
e_book_client_cursor_get_alphabet (EBookClientCursor *cursor,
                                   gint *n_labels,
                                   gint *underflow,
                                   gint *inflow,
                                   gint *overflow)
{
	EBookClientCursorPrivate *priv;

	g_return_val_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor), NULL);

	priv = cursor->priv;

	return e_collator_get_index_labels (
		priv->collator,
		n_labels,
		underflow,
		inflow,
		overflow);
}

/**
 * e_book_client_cursor_get_total:
 * @cursor: an #EBookClientCursor
 *
 * Fetches the total number of contacts in the addressbook
 * which match @cursor's query
 *
 * Returns: The total number of contacts matching @cursor's query
 *
 * Since: 3.12
 */
gint
e_book_client_cursor_get_total (EBookClientCursor *cursor)
{
	g_return_val_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor), -1);

	return cursor->priv->total;
}

/**
 * e_book_client_cursor_get_position:
 * @cursor: an #EBookClientCursor
 *
 * Fetches the number of contacts leading up to the current
 * cursor position, inclusive of the current cursor position.
 *
 * The position value can be anywhere from 0 to the total
 * number of contacts plus one. A value of 0 indicates
 * that the cursor is positioned before the contact list in
 * the symbolic %E_BOOK_CURSOR_ORIGIN_BEGIN state. If
 * the position is greater than the total, as returned by
 * e_book_client_cursor_get_total(), then the cursor is positioned
 * after the last contact in the symbolic %E_BOOK_CURSOR_ORIGIN_END position.
 *
 * Returns: The current cursor position
 *
 * Since: 3.12
 */
gint
e_book_client_cursor_get_position (EBookClientCursor *cursor)
{
	g_return_val_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor), -1);

	return cursor->priv->position;
}

/**
 * e_book_client_cursor_set_sexp:
 * @cursor: an #EBookClientCursor
 * @sexp: the new search expression for @cursor
 * @cancellable: (allow-none): a #GCancellable to optionally cancel this operation while in progress
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Sets the <link linkend="cursor-search">Search Expression</link> for the cursor.
 *
 * See: e_book_client_cursor_set_sexp_sync().
 *
 * This asynchronous call is completed with a call to
 * e_book_client_cursor_set_sexp_finish() from the specified @callback.
 *
 * Since: 3.12
 */
void
e_book_client_cursor_set_sexp (EBookClientCursor *cursor,
                               const gchar *sexp,
                               GCancellable *cancellable,
                               GAsyncReadyCallback callback,
                               gpointer user_data)
{

	GSimpleAsyncResult *simple;
	SetSexpContext *context;

	g_return_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor));
	g_return_if_fail (callback != NULL);

	context = set_sexp_context_new (sexp);
	simple = g_simple_async_result_new (
		G_OBJECT (cursor),
		callback, user_data,
		e_book_client_cursor_set_sexp);

	g_simple_async_result_set_check_cancellable (simple, cancellable);
	g_simple_async_result_set_op_res_gpointer (
		simple, context,
		(GDestroyNotify) set_sexp_context_free);

	g_simple_async_result_run_in_thread (
		simple, set_sexp_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_cursor_set_sexp_finish:
 * @cursor: an #EBookClientCursor
 * @result: a #GAsyncResult
 * @error: (out) (allow-none): return location for a #GError, or %NULL
 *
 * Completes an asynchronous call initiated by e_book_client_cursor_set_sexp(), reporting
 * whether the new search expression was accepted.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set.
 *
 * Since: 3.12
 */
gboolean
e_book_client_cursor_set_sexp_finish (EBookClientCursor *cursor,
                                      GAsyncResult *result,
                                      GError **error)
{
	GSimpleAsyncResult *simple;
	SetSexpContext *context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (cursor),
		e_book_client_cursor_set_sexp), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	/* If we are in the thread where the cursor was created, 
	 * then synchronize the new total & position right away
	 */
	if (book_client_cursor_context_is_current (cursor)) {
		g_object_freeze_notify (G_OBJECT (cursor));
		book_client_cursor_set_total (cursor, context->new_total);
		book_client_cursor_set_position (cursor, context->new_position);
		g_object_thaw_notify (G_OBJECT (cursor));
	}

	return TRUE;
}

/**
 * e_book_client_cursor_set_sexp_sync:
 * @cursor: an #EBookClientCursor
 * @sexp: the new search expression for @cursor
 * @cancellable: (allow-none): a #GCancellable to optionally cancel this operation while in progress
 * @error: (out) (allow-none): return location for a #GError, or %NULL
 *
 * Sets the <link linkend="cursor-search">Search Expression</link> for the cursor.
 *
 * A side effect of setting the search expression is that the
 * <link linkend="cursor-pos-total">position and total</link>
 * properties will be updated.
 *
 * If this method is called from the same thread context in which
 * the cursor was created, then the updates to the #EBookClientCursor:position
 * and #EBookClientCursor:total properties are guaranteed to be delivered
 * synchronously upon successful completion of setting the search expression.
 * Otherwise, notifications will be delivered asynchronously in the cursor's
 * original thread context.
 *
 * If the backend does not support the given search expression,
 * an %E_CLIENT_ERROR_INVALID_QUERY error will be set.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set.
 *
 * Since: 3.12
 */
gboolean
e_book_client_cursor_set_sexp_sync (EBookClientCursor *cursor,
                                    const gchar *sexp,
                                    GCancellable *cancellable,
                                    GError **error)
{
	gboolean success;
	guint new_total = 0, new_position = 0;

	g_return_val_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor), FALSE);

	success = set_sexp_sync_internal (
		cursor,
		sexp,
		&new_total,
		&new_position,
		cancellable,
		error);

	/* If we are in the thread where the cursor was created, 
	 * then synchronize the new total & position right away
	 */
	if (success && book_client_cursor_context_is_current (cursor)) {
		g_object_freeze_notify (G_OBJECT (cursor));
		book_client_cursor_set_total (cursor, new_total);
		book_client_cursor_set_position (cursor, new_position);
		g_object_thaw_notify (G_OBJECT (cursor));
	}

	return success;
}

/**
 * e_book_client_cursor_step:
 * @cursor: an #EBookClientCursor
 * @flags: The #EBookCursorStepFlags for this step
 * @origin: The #EBookCursorOrigin from whence to step
 * @count: a positive or negative amount of contacts to try and fetch
 * @cancellable: (allow-none): a #GCancellable to optionally cancel this operation while in progress
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * <link linkend="cursor-iteration">Steps the cursor through the results</link> by 
 * a maximum of @count and fetch the results traversed.
 *
 * See: e_book_client_cursor_step_sync().
 *
 * This asynchronous call is completed with a call to
 * e_book_client_cursor_step_finish() from the specified @callback.
 *
 * Since: 3.12
 */
void
e_book_client_cursor_step (EBookClientCursor *cursor,
                           EBookCursorStepFlags flags,
                           EBookCursorOrigin origin,
                           gint count,
                           GCancellable *cancellable,
                           GAsyncReadyCallback callback,
                           gpointer user_data)
{
	GSimpleAsyncResult *simple;
	StepContext *context;

	g_return_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor));
	g_return_if_fail (callback != NULL);

	context = step_context_new (
		cursor->priv->revision,
		flags, origin, count);
	simple = g_simple_async_result_new (
		G_OBJECT (cursor),
		callback, user_data,
		e_book_client_cursor_step);

	g_simple_async_result_set_check_cancellable (simple, cancellable);
	g_simple_async_result_set_op_res_gpointer (
		simple, context,
		(GDestroyNotify) step_context_free);

	g_simple_async_result_run_in_thread (
		simple, step_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_cursor_step_finish:
 * @cursor: an #EBookClientCursor
 * @result: a #GAsyncResult
 * @out_contacts: (element-type EContact) (out) (transfer full) (allow-none): return location for a #GSList of #EContact
 * @error: (out) (allow-none): return location for a #GError, or %NULL
 *
 * Completes an asynchronous call initiated by e_book_client_cursor_step(), fetching
 * any contacts which might have been returned by the call.
 *
 * Returns: The number of contacts traversed if successful, otherwise -1 is
 * returned and @error is set.
 *
 * Since: 3.12
 */
gint
e_book_client_cursor_step_finish (EBookClientCursor *cursor,
                                  GAsyncResult *result,
                                  GSList **out_contacts,
                                  GError **error)
{
	GSimpleAsyncResult *simple;
	StepContext *context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (cursor),
		e_book_client_cursor_step), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return -1;

	if (out_contacts != NULL) {
		*out_contacts = context->contacts;
		context->contacts = NULL;
	}

	/* If we are in the thread where the cursor was created, 
	 * then synchronize the new total & position right away
	 */
	if (book_client_cursor_context_is_current (cursor)) {
		g_object_freeze_notify (G_OBJECT (cursor));
		book_client_cursor_set_total (cursor, context->new_total);
		book_client_cursor_set_position (cursor, context->new_position);
		g_object_thaw_notify (G_OBJECT (cursor));
	}

	return context->n_results;
}

/**
 * e_book_client_cursor_step_sync:
 * @cursor: an #EBookClientCursor
 * @flags: The #EBookCursorStepFlags for this step
 * @origin: The #EBookCursorOrigin from whence to step
 * @count: a positive or negative amount of contacts to try and fetch
 * @out_contacts: (element-type EContact) (out) (transfer full) (allow-none): return location for a #GSList of #EContact
 * @cancellable: (allow-none): a #GCancellable to optionally cancel this operation while in progress
 * @error: (out) (allow-none): return location for a #GError, or %NULL
 *
 * <link linkend="cursor-iteration">Steps the cursor through the results</link> by 
 * a maximum of @count and fetch the results traversed.
 *
 * If @count is negative, then the cursor will move backwards.
 *
 * If @cursor reaches the beginning or end of the query results, then the
 * returned list might not contain the amount of desired contacts, or might
 * return no results if the cursor currently points to the last contact.
 * Reaching the end of the list is not considered an error condition. Attempts
 * to step beyond the end of the list after having reached the end of the list
 * will however trigger an %E_CLIENT_ERROR_QUERY_REFUSED error.
 *
 * If %E_BOOK_CURSOR_STEP_FETCH is specified in @flags, a pointer to
 * a %NULL #GSList pointer should be provided for the @results parameter.
 *
 * If %E_BOOK_CURSOR_STEP_MOVE is specified in @flags, then the cursor's
 * state will be modified and the <link linkend="cursor-pos-total">position</link>
 * property will be updated as a result.
 *
 * If this method is called from the same thread context in which
 * the cursor was created, then the updates to the #EBookClientCursor:position
 * property are guaranteed to be delivered synchronously upon successful completion
 * of moving the cursor. Otherwise, notifications will be delivered asynchronously
 * in the cursor's original thread context.
 *
 * If this method completes with an %E_CLIENT_ERROR_OUT_OF_SYNC error, it is an
 * indication that the addressbook has been modified and it would be unsafe to
 * move the cursor at this time. Any %E_CLIENT_ERROR_OUT_OF_SYNC error is guaranteed
 * to be followed by an #EBookClientCursor::refresh signal at which point any content
 * should be reloaded.
 *
 * Returns: The number of contacts traversed if successful, otherwise -1 is
 * returned and @error is set.
 *
 * Since: 3.12
 */
gint
e_book_client_cursor_step_sync (EBookClientCursor *cursor,
                                EBookCursorStepFlags flags,
                                EBookCursorOrigin origin,
                                gint count,
                                GSList **out_contacts,
                                GCancellable *cancellable,
                                GError **error)
{
	guint new_total = 0, new_position = 0;
	gint retval;

	g_return_val_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor), FALSE);

	retval = step_sync_internal (
		cursor, cursor->priv->revision,
		flags, origin, count,
		out_contacts, &new_total, &new_position,
		cancellable, error);

	/* If we are in the thread where the cursor was created, 
	 * then synchronize the new total & position right away
	 */
	if (retval >= 0 && book_client_cursor_context_is_current (cursor)) {
		g_object_freeze_notify (G_OBJECT (cursor));
		book_client_cursor_set_total (cursor, new_total);
		book_client_cursor_set_position (cursor, new_position);
		g_object_thaw_notify (G_OBJECT (cursor));
	}

	return retval;
}

/**
 * e_book_client_cursor_set_alphabetic_index:
 * @cursor: an #EBookClientCursor
 * @index: the alphabetic index
 * @cancellable: (allow-none): a #GCancellable to optionally cancel this operation while in progress
 * @callback: callback to call when a result is ready
 * @user_data: user data for the @callback
 *
 * Sets the current cursor position to point to an <link linkend="cursor-alphabet">Alphabetic Index</link>.
 *
 * See: e_book_client_cursor_set_alphabetic_index_sync().
 *
 * This asynchronous call is completed with a call to
 * e_book_client_cursor_set_alphabetic_index_finish() from the specified @callback.
 *
 * Since: 3.12
 */
void
e_book_client_cursor_set_alphabetic_index (EBookClientCursor *cursor,
                                           gint index,
                                           GCancellable *cancellable,
                                           GAsyncReadyCallback callback,
                                           gpointer user_data)
{
	GSimpleAsyncResult *simple;
	AlphabetIndexContext *context;

	g_return_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor));
	g_return_if_fail (index >= 0 && index < cursor->priv->n_labels);
	g_return_if_fail (callback != NULL);

	context = alphabet_index_context_new (index, cursor->priv->locale);
	simple = g_simple_async_result_new (
		G_OBJECT (cursor),
		callback, user_data,
		e_book_client_cursor_set_alphabetic_index);

	g_simple_async_result_set_check_cancellable (simple, cancellable);
	g_simple_async_result_set_op_res_gpointer (
		simple, context,
		(GDestroyNotify) alphabet_index_context_free);

	g_simple_async_result_run_in_thread (
		simple, alphabet_index_thread,
		G_PRIORITY_DEFAULT, cancellable);

	g_object_unref (simple);
}

/**
 * e_book_client_cursor_set_alphabetic_index_finish:
 * @cursor: an #EBookClientCursor
 * @result: a #GAsyncResult
 * @error: (out) (allow-none): return location for a #GError, or %NULL
 *
 * Completes an asynchronous call initiated by e_book_client_cursor_set_alphabetic_index().
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set.
 *
 * Since: 3.12
 */
gboolean
e_book_client_cursor_set_alphabetic_index_finish (EBookClientCursor *cursor,
                                                  GAsyncResult *result,
                                                  GError **error)
{
	GSimpleAsyncResult *simple;
	AlphabetIndexContext *context;

	g_return_val_if_fail (
		g_simple_async_result_is_valid (
		result, G_OBJECT (cursor),
		e_book_client_cursor_set_alphabetic_index), FALSE);

	simple = G_SIMPLE_ASYNC_RESULT (result);
	context = g_simple_async_result_get_op_res_gpointer (simple);

	if (g_simple_async_result_propagate_error (simple, error))
		return FALSE;

	/* If we are in the thread where the cursor was created, 
	 * then synchronize the new total & position right away
	 */
	if (book_client_cursor_context_is_current (cursor)) {
		g_object_freeze_notify (G_OBJECT (cursor));
		book_client_cursor_set_total (cursor, context->new_total);
		book_client_cursor_set_position (cursor, context->new_position);
		g_object_thaw_notify (G_OBJECT (cursor));
	}

	return TRUE;
}

/**
 * e_book_client_cursor_set_alphabetic_index_sync:
 * @cursor: an #EBookClientCursor
 * @index: the alphabetic index
 * @cancellable: (allow-none): a #GCancellable to optionally cancel this operation while in progress
 * @error: (out) (allow-none): return location for a #GError, or %NULL
 *
 * Sets the cursor to point to an <link linkend="cursor-alphabet">Alphabetic Index</link>.
 *
 * After setting the alphabetic index, for example the
 * index for letter 'E', then further calls to e_book_client_cursor_step()
 * will return results starting with the letter 'E' (or results starting
 * with the last result in 'D' when navigating through cursor results
 * in reverse).
 *
 * The passed index must be a valid index into the alphabet parameters
 * returned by e_book_client_cursor_get_alphabet().
 *
 * If this method is called from the same thread context in which
 * the cursor was created, then the updates to the #EBookClientCursor:position
 * property are guaranteed to be delivered synchronously upon successful completion
 * of moving the cursor. Otherwise, notifications will be delivered asynchronously
 * in the cursor's original thread context.
 *
 * If this method completes with an %E_CLIENT_ERROR_OUT_OF_SYNC error, it is an
 * indication that the addressbook has been set into a new locale and it would be
 * unsafe to set the alphabetic index at this time. If you receive an out of sync
 * error from this method, then you should wait until a #EBookClientCursor:alphabet
 * property change notification is delivered and then proceed to load the new
 * alphabet before trying to set any alphabetic index.
 *
 * Returns: %TRUE on success, otherwise %FALSE is returned and @error is set.
 *
 * Since: 3.12
 */
gboolean
e_book_client_cursor_set_alphabetic_index_sync (EBookClientCursor *cursor,
                                                gint index,
                                                GCancellable *cancellable,
                                                GError **error)
{
	guint new_total = 0, new_position = 0;
	gboolean success;

	g_return_val_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor), FALSE);
	g_return_val_if_fail (index >= 0 && index < cursor->priv->n_labels, FALSE);

	success = set_alphabetic_index_sync_internal (
		cursor, index, cursor->priv->locale,
		&new_total, &new_position, cancellable, error);

	/* If we are in the thread where the cursor was created, 
	 * then synchronize the new total & position right away
	 */
	if (success && book_client_cursor_context_is_current (cursor)) {
		g_object_freeze_notify (G_OBJECT (cursor));
		book_client_cursor_set_total (cursor, new_total);
		book_client_cursor_set_position (cursor, new_position);
		g_object_thaw_notify (G_OBJECT (cursor));
	}

	return success;
}

/**
 * e_book_client_cursor_get_contact_alphabetic_index:
 * @cursor: an #EBookClientCursor
 * @contact: the #EContact to check
 *
 * Checks which alphabetic index @contact would be sorted
 * into according to @cursor.
 *
 * So long as the active #EBookClientCursor:alphabet does
 * not change, the returned index will be a valid position
 * in the array of labels returned by e_book_client_cursor_get_alphabet().
 *
 * If the index returned by this function is needed for
 * any extended period of time, it should be recalculated
 * whenever the #EBookClientCursor:alphabet changes.
 *
 * Returns: The alphabetic index of @contact in @cursor.
 *
 * Since: 3.12
 */
gint
e_book_client_cursor_get_contact_alphabetic_index (EBookClientCursor *cursor,
                                                   EContact *contact)
{
	EBookClientCursorPrivate *priv;
	EContactField field;
	const gchar *value;
	gint index = 0;

	g_return_val_if_fail (E_IS_BOOK_CLIENT_CURSOR (cursor), 0);
	g_return_val_if_fail (E_IS_CONTACT (contact), 0);

	priv = cursor->priv;

	if (priv->collator && priv->sort_fields) {

		/* Find the alphabetic index according to the primary
		 * cursor sort key 
		 */
		field = e_contact_field_id (priv->sort_fields[0]);
		value = e_contact_get_const (contact, field);
		index = e_collator_get_index (priv->collator, value ? value : "");
	}

	return index;
}
