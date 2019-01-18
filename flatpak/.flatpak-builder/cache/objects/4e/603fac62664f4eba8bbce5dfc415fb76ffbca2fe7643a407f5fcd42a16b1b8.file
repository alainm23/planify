/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* Evolution calendar - iCalendar file backend
 *
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 * Copyright (C) 2003 Gergő Érdi
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
 * Authors: Federico Mena-Quintero <federico@ximian.com>
 *          Rodrigo Moya <rodrigo@ximian.com>
 *          Gergő Érdi <cactus@cactus.rulez.org>
 */

#include "evolution-data-server-config.h"

#include <string.h>

#include "e-cal-backend-contacts.h"

#include <glib/gi18n-lib.h>

#include <libebook/libebook.h>
#include <libedataserver/libedataserver.h>

#define E_CAL_BACKEND_CONTACTS_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL_BACKEND_CONTACTS, ECalBackendContactsPrivate))

#define EDC_ERROR(_code) e_data_cal_create_error (_code, NULL)

G_DEFINE_TYPE (
	ECalBackendContacts,
	e_cal_backend_contacts,
	E_TYPE_CAL_BACKEND_SYNC)

typedef enum
{
	CAL_DAYS,
	CAL_HOURS,
	CAL_MINUTES
} CalUnits;

/* Private part of the ECalBackendContacts structure */
struct _ECalBackendContactsPrivate {

	GRecMutex rec_mutex;		/* guards 'addressbooks' */
	GHashTable   *addressbooks;	/* UID -> BookRecord */
	gboolean      addressbook_loaded;

	EBookClientView *book_view;
	GHashTable *tracked_contacts;	/* UID -> ContactRecord */
	GRecMutex tracked_contacts_lock;

	/* properties related to track alarm settings for this backend */
	GSettings *settings;
	guint notifyid;
	guint update_alarms_id;
	gboolean alarm_enabled;
	gint alarm_interval;
	CalUnits alarm_units;

	ESourceRegistryWatcher *registry_watcher;
};

typedef struct _BookRecord {
	volatile gint ref_count;

	GMutex lock;
	ECalBackendContacts *cbc;
	EBookClient *book_client;
	EBookClientView *book_view;
	GCancellable *cancellable;
	gboolean online;
	gulong notify_online_id;
} BookRecord;

typedef struct _ContactRecord {
	ECalBackendContacts *cbc;
	EBookClient *book_client; /* where it comes from */
	EContact	    *contact;
	ECalComponent       *comp_birthday, *comp_anniversary;
} ContactRecord;

#define d(x)

#define ANNIVERSARY_UID_EXT "-anniversary"
#define BIRTHDAY_UID_EXT   "-birthday"

static ECalComponent *
		create_birthday			(ECalBackendContacts *cbc,
						 EContact *contact);
static ECalComponent *
		create_anniversary		(ECalBackendContacts *cbc,
						 EContact *contact);
static void	contacts_modified_cb		(EBookClientView *book_view,
						 const GSList *contacts,
						 gpointer user_data);
static void	contacts_added_cb		(EBookClientView *book_view,
						 const GSList *contacts,
						 gpointer user_data);
static void	contacts_removed_cb		(EBookClientView *book_view,
						 const GSList *contact_ids,
						 gpointer user_data);
static void	e_cal_backend_contacts_add_timezone
						(ECalBackendSync *backend,
						 EDataCal *cal,
						 GCancellable *cancellable,
						 const gchar *tzobj,
						 GError **perror);
static void	setup_alarm			(ECalBackendContacts *cbc,
						 ECalComponent *comp);
static void	book_client_connected_cb	(GObject *source_object,
						 GAsyncResult *result,
						 gpointer user_data);

static gboolean
remove_by_book (gpointer key,
                gpointer value,
                gpointer user_data)
{
	ContactRecord *cr = value;
	EBookClient *book_client = user_data;

	return (cr && cr->book_client == book_client);
}

static void
create_book_record (ECalBackendContacts *cbc,
                    ESource *source)
{
	BookRecord *br;

	br = g_slice_new0 (BookRecord);
	br->ref_count = 1;
	g_mutex_init (&br->lock);
	br->cbc = g_object_ref (cbc);
	br->cancellable = g_cancellable_new ();

	e_book_client_connect (source, 30, br->cancellable, book_client_connected_cb, br);
}

static BookRecord *
book_record_ref (BookRecord *br)
{
	g_return_val_if_fail (br != NULL, NULL);
	g_return_val_if_fail (br->ref_count > 0, NULL);

	g_atomic_int_inc (&br->ref_count);

	return br;
}

static void
book_record_unref (BookRecord *br)
{
	g_return_if_fail (br != NULL);
	g_return_if_fail (br->ref_count > 0);

	if (g_atomic_int_dec_and_test (&br->ref_count)) {
		g_cancellable_cancel (br->cancellable);

		if (br->book_client) {
			g_rec_mutex_lock (&br->cbc->priv->tracked_contacts_lock);
			g_hash_table_foreach_remove (
				br->cbc->priv->tracked_contacts,
				remove_by_book, br->book_client);
			g_rec_mutex_unlock (&br->cbc->priv->tracked_contacts_lock);
		}

		g_mutex_lock (&br->lock);

		if (br->notify_online_id)
			g_signal_handler_disconnect (br->book_client, br->notify_online_id);

		g_clear_object (&br->cbc);
		g_clear_object (&br->cancellable);
		g_clear_object (&br->book_client);
		g_clear_object (&br->book_view);

		g_mutex_unlock (&br->lock);
		g_mutex_clear (&br->lock);

		g_slice_free (BookRecord, br);
	}
}

static void
cancel_and_unref_book_record (BookRecord *br)
{
	g_return_if_fail (br != NULL);

	if (br->cancellable)
		g_cancellable_cancel (br->cancellable);
	book_record_unref (br);
}

static void
book_record_set_book_view (BookRecord *br,
                           EBookClientView *book_view)
{
	g_return_if_fail (br != NULL);

	g_mutex_lock (&br->lock);

	if (book_view != NULL)
		g_object_ref (book_view);

	if (br->book_view != NULL)
		g_object_unref (br->book_view);

	br->book_view = book_view;

	g_mutex_unlock (&br->lock);
}

static void
cal_backend_contacts_insert_book_record (ECalBackendContacts *cbc,
                                         ESource *source,
                                         BookRecord *br)
{
	g_rec_mutex_lock (&cbc->priv->rec_mutex);

	g_hash_table_insert (
		cbc->priv->addressbooks,
		g_object_ref (source),
		book_record_ref (br));

	g_rec_mutex_unlock (&cbc->priv->rec_mutex);
}

static gboolean
cal_backend_contacts_remove_book_record (ECalBackendContacts *cbc,
                                         ESource *source)
{
	gboolean removed;

	g_rec_mutex_lock (&cbc->priv->rec_mutex);

	removed = g_hash_table_remove (cbc->priv->addressbooks, source);

	g_rec_mutex_unlock (&cbc->priv->rec_mutex);

	return removed;
}

static gpointer
book_record_get_view_thread (gpointer user_data)
{
	BookRecord *br;
	EBookQuery *query;
	EBookClientView *book_view = NULL;
	gchar *query_sexp;
	GError *error = NULL;

	br = user_data;
	g_return_val_if_fail (br != NULL, NULL);

	book_record_set_book_view (br, NULL);

	query = e_book_query_andv (
		e_book_query_orv (
			e_book_query_field_exists (E_CONTACT_FILE_AS),
			e_book_query_field_exists (E_CONTACT_FULL_NAME),
			e_book_query_field_exists (E_CONTACT_GIVEN_NAME),
			e_book_query_field_exists (E_CONTACT_NICKNAME),
			NULL),
		e_book_query_orv (
			e_book_query_field_exists (E_CONTACT_BIRTH_DATE),
			e_book_query_field_exists (E_CONTACT_ANNIVERSARY),
			NULL),
		NULL);
	query_sexp = e_book_query_to_string (query);
	e_book_query_unref (query);

	if (!e_book_client_get_view_sync (br->book_client, query_sexp, &book_view, br->cancellable, &error)) {

		if (!error)
			error = g_error_new_literal (
				E_CLIENT_ERROR,
				E_CLIENT_ERROR_OTHER_ERROR,
				_("Unknown error"));
	}

	/* Sanity check. */
	g_return_val_if_fail (
		((book_view != NULL) && (error == NULL)) ||
		((book_view == NULL) && (error != NULL)), NULL);

	if (error != NULL) {
		ESource *source;

		source = e_client_get_source (E_CLIENT (br->book_client));

		g_warning (
			"%s: Failed to get book view on '%s': %s",
			G_STRFUNC, e_source_get_display_name (source),
			error->message);

		g_clear_error (&error);

		goto exit;
	}

	g_signal_connect (
		book_view, "objects-added",
		G_CALLBACK (contacts_added_cb), br->cbc);
	g_signal_connect (
		book_view, "objects-removed",
		G_CALLBACK (contacts_removed_cb), br->cbc);
	g_signal_connect (
		book_view, "objects-modified",
		G_CALLBACK (contacts_modified_cb), br->cbc);

	e_book_client_view_start (book_view, NULL);

	book_record_set_book_view (br, book_view);

	g_object_unref (book_view);

exit:
	g_free (query_sexp);

	book_record_unref (br);

	return NULL;
}

static void
source_unset_last_credentials_required_args_cb (GObject *source_object,
						GAsyncResult *result,
						gpointer user_data)
{
	GError *error = NULL;

	if (!e_source_unset_last_credentials_required_arguments_finish (E_SOURCE (source_object), result, &error))
		g_debug ("%s: Failed to unset last credentials required arguments for %s: %s",
			G_STRFUNC, e_source_get_display_name (E_SOURCE (source_object)), error ? error->message : "Unknown error");

	g_clear_error (&error);
}

static void
book_client_notify_online_cb (EClient *client,
			      GParamSpec *param,
			      BookRecord *br)
{
	g_return_if_fail (E_IS_BOOK_CLIENT (client));
	g_return_if_fail (br != NULL);

	if ((br->online ? 1 : 0) == (e_client_is_online (client) ? 1 : 0))
		return;

	br->online = e_client_is_online (client);

	if (br->online) {
		ECalBackendContacts *cbc;
		ESource *source;

		cbc = g_object_ref (br->cbc);
		source = g_object_ref (e_client_get_source (client));

		cal_backend_contacts_remove_book_record (cbc, source);
		create_book_record (cbc, source);

		g_clear_object (&source);
		g_clear_object (&cbc);
	}
}

static void
book_client_connected_cb (GObject *source_object,
                          GAsyncResult *result,
                          gpointer user_data)
{
	EClient *client;
	ESource *source;
	GThread *thread;
	BookRecord *br = user_data;
	GError *error = NULL;

	g_return_if_fail (br != NULL);

	client = e_book_client_connect_finish (result, &error);

	/* Sanity check. */
	g_return_if_fail (
		((client != NULL) && (error == NULL)) ||
		((client == NULL) && (error != NULL)));

	if (error != NULL) {
		if (E_IS_BOOK_CLIENT (source_object)) {
			source = e_client_get_source (E_CLIENT (source_object));
			if (source)
				e_source_unset_last_credentials_required_arguments (source, NULL,
					source_unset_last_credentials_required_args_cb, NULL);
		}

		g_warning ("%s: %s", G_STRFUNC, error->message);
		g_error_free (error);
		book_record_unref (br);
		return;
	}

	source = e_client_get_source (client);
	br->book_client = g_object_ref (client);
	br->online = e_client_is_online (client);
	br->notify_online_id = g_signal_connect (client, "notify::online", G_CALLBACK (book_client_notify_online_cb), br);
	cal_backend_contacts_insert_book_record (br->cbc, source, br);

	/* Let it consume the 'br' reference */
	thread = g_thread_new (NULL, book_record_get_view_thread, br);
	g_thread_unref (thread);

	g_object_unref (client);
}

/* ContactRecord methods */
static ContactRecord *
contact_record_new (ECalBackendContacts *cbc,
                    EBookClient *book_client,
                    EContact *contact)
{
	ContactRecord *cr = g_new0 (ContactRecord, 1);

	cr->cbc = cbc;
	cr->book_client = book_client;
	cr->contact = contact;
	cr->comp_birthday = create_birthday (cbc, contact);
	cr->comp_anniversary = create_anniversary (cbc, contact);

	if (cr->comp_birthday)
		e_cal_backend_notify_component_created (E_CAL_BACKEND (cbc), cr->comp_birthday);

	if (cr->comp_anniversary)
		e_cal_backend_notify_component_created (E_CAL_BACKEND (cbc), cr->comp_anniversary);

	g_object_ref (G_OBJECT (contact));

	return cr;
}

static void
contact_record_free (ContactRecord *cr)
{
	ECalComponentId *id;

	g_object_unref (G_OBJECT (cr->contact));

	/* Remove the birthday event */
	if (cr->comp_birthday) {
		id = e_cal_component_get_id (cr->comp_birthday);
		e_cal_backend_notify_component_removed (E_CAL_BACKEND (cr->cbc), id, cr->comp_birthday, NULL);

		e_cal_component_free_id (id);
		g_object_unref (G_OBJECT (cr->comp_birthday));
	}

	/* Remove the anniversary event */
	if (cr->comp_anniversary) {
		id = e_cal_component_get_id (cr->comp_anniversary);

		e_cal_backend_notify_component_removed (E_CAL_BACKEND (cr->cbc), id, cr->comp_anniversary, NULL);

		e_cal_component_free_id (id);
		g_object_unref (G_OBJECT (cr->comp_anniversary));
	}

	g_free (cr);
}

/* ContactRecordCB methods */
typedef struct _ContactRecordCB {
        ECalBackendContacts *cbc;
        ECalBackendSExp     *sexp;
	gboolean	     as_string;
        GSList              *result;
} ContactRecordCB;

static ContactRecordCB *
contact_record_cb_new (ECalBackendContacts *cbc,
                       ECalBackendSExp *sexp,
                       gboolean as_string)
{
	ContactRecordCB *cb_data = g_new (ContactRecordCB, 1);

	cb_data->cbc = cbc;
	cb_data->sexp = sexp;
	cb_data->as_string = as_string;
	cb_data->result = NULL;

	return cb_data;
}

static void
contact_record_cb_free (ContactRecordCB *cb_data,
                        gboolean can_free_result)
{
	if (can_free_result) {
		if (cb_data->as_string)
			g_slist_foreach (cb_data->result, (GFunc) g_free, NULL);
		g_slist_free (cb_data->result);
	}

	g_free (cb_data);
}

static void
contact_record_cb (gpointer key,
                   gpointer value,
                   gpointer user_data)
{
	ETimezoneCache *timezone_cache;
	ContactRecordCB *cb_data = user_data;
	ContactRecord   *record = value;
	gpointer data;

	timezone_cache = E_TIMEZONE_CACHE (cb_data->cbc);

	if (record->comp_birthday && e_cal_backend_sexp_match_comp (cb_data->sexp, record->comp_birthday, timezone_cache)) {
		if (cb_data->as_string)
			data = e_cal_component_get_as_string (record->comp_birthday);
		else
			data = record->comp_birthday;

		cb_data->result = g_slist_prepend (cb_data->result, data);
	}

	if (record->comp_anniversary && e_cal_backend_sexp_match_comp (cb_data->sexp, record->comp_anniversary, timezone_cache)) {
		if (cb_data->as_string)
			data = e_cal_component_get_as_string (record->comp_anniversary);
		else
			data = record->comp_anniversary;

		cb_data->result = g_slist_prepend (cb_data->result, data);
	}
}

static gboolean
ecb_contacts_watcher_filter_cb (ESourceRegistryWatcher *watcher,
				ESource *source,
				gpointer user_data)
{
	ESourceContacts *extension;

	g_return_val_if_fail (E_IS_SOURCE (source), FALSE);

	extension = e_source_get_extension (source, E_SOURCE_EXTENSION_CONTACTS_BACKEND);

	return extension && e_source_contacts_get_include_me (extension);
}

static void
ecb_contacts_watcher_appeared_cb (ESourceRegistryWatcher *watcher,
				  ESource *source,
				  gpointer user_data)
{
	ECalBackendContacts *cbcontacts = user_data;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_CAL_BACKEND_CONTACTS (cbcontacts));

	cal_backend_contacts_remove_book_record (cbcontacts, source);
	create_book_record (cbcontacts, source);
}

static void
ecb_contacts_watcher_disappeared_cb (ESourceRegistryWatcher *watcher,
				     ESource *source,
				     gpointer user_data)
{
	ECalBackendContacts *cbcontacts = user_data;

	g_return_if_fail (E_IS_SOURCE (source));
	g_return_if_fail (E_IS_CAL_BACKEND_CONTACTS (cbcontacts));

	cal_backend_contacts_remove_book_record (cbcontacts, source);
}

static gboolean
cal_backend_contacts_load_sources (gpointer user_data)
{
	ECalBackendContacts *cbcontacts = user_data;

	g_return_val_if_fail (E_IS_CAL_BACKEND_CONTACTS (cbcontacts), FALSE);

	e_source_registry_watcher_reclaim (cbcontacts->priv->registry_watcher);

	return FALSE;
}

/************************************************************************************/

static void
contacts_modified_cb (EBookClientView *book_view,
                      const GSList *contacts,
                      gpointer user_data)
{
	ECalBackendContacts *cbc = E_CAL_BACKEND_CONTACTS (user_data);
	EBookClient *book_client;
	const GSList *ii;

	book_client = e_book_client_view_ref_client (book_view);
	if (book_client == NULL)
		return;

	g_rec_mutex_lock (&cbc->priv->tracked_contacts_lock);

	for (ii = contacts; ii; ii = ii->next) {
		EContact *contact = E_CONTACT (ii->data);
		const gchar *uid = e_contact_get_const (contact, E_CONTACT_UID);
		EContactDate *birthday, *anniversary;

		/* Because this is a change of contact, then always remove old tracked data
		 * and if possible, add with (possibly) new values.
		*/
		g_hash_table_remove (cbc->priv->tracked_contacts, (gchar *) uid);

		birthday = e_contact_get (contact, E_CONTACT_BIRTH_DATE);
		anniversary = e_contact_get (contact, E_CONTACT_ANNIVERSARY);

		if (birthday || anniversary) {
			ContactRecord *cr = contact_record_new (cbc, book_client, contact);
			g_hash_table_insert (cbc->priv->tracked_contacts, g_strdup (uid), cr);
		}

		e_contact_date_free (birthday);
		e_contact_date_free (anniversary);
	}

	g_rec_mutex_unlock (&cbc->priv->tracked_contacts_lock);

	g_object_unref (book_client);
}

static void
contacts_added_cb (EBookClientView *book_view,
                   const GSList *contacts,
                   gpointer user_data)
{
	ECalBackendContacts *cbc = E_CAL_BACKEND_CONTACTS (user_data);
	EBookClient *book_client;
	const GSList *ii;

	book_client = e_book_client_view_ref_client (book_view);
	if (book_client == NULL)
		return;

	g_rec_mutex_lock (&cbc->priv->tracked_contacts_lock);

	/* See if any new contacts have BIRTHDAY or ANNIVERSARY fields */
	for (ii = contacts; ii; ii = ii->next) {
		EContact *contact = E_CONTACT (ii->data);
		EContactDate *birthday, *anniversary;

		birthday = e_contact_get (contact, E_CONTACT_BIRTH_DATE);
		anniversary = e_contact_get (contact, E_CONTACT_ANNIVERSARY);

		if (birthday || anniversary) {
			ContactRecord *cr = contact_record_new (cbc, book_client, contact);
			const gchar    *uid = e_contact_get_const (contact, E_CONTACT_UID);

			g_hash_table_insert (cbc->priv->tracked_contacts, g_strdup (uid), cr);
		}

		e_contact_date_free (birthday);
		e_contact_date_free (anniversary);
	}

	g_rec_mutex_unlock (&cbc->priv->tracked_contacts_lock);

	g_object_unref (book_client);
}

static void
contacts_removed_cb (EBookClientView *book_view,
                     const GSList *contact_ids,
                     gpointer user_data)
{
	ECalBackendContacts *cbc = E_CAL_BACKEND_CONTACTS (user_data);
	const GSList *ii;

	g_rec_mutex_lock (&cbc->priv->tracked_contacts_lock);

	/* Stop tracking these */
	for (ii = contact_ids; ii; ii = ii->next)
		g_hash_table_remove (cbc->priv->tracked_contacts, ii->data);

	g_rec_mutex_unlock (&cbc->priv->tracked_contacts_lock);
}

/************************************************************************************/
static struct icaltimetype
cdate_to_icaltime (EContactDate *cdate)
{
	struct icaltimetype ret = icaltime_null_time ();

	ret.year = cdate->year;
	ret.month = cdate->month;
	ret.day = cdate->day;
	ret.is_date = TRUE;
	ret.zone = NULL;
	ret.is_daylight = FALSE;

	ret.hour = ret.minute = ret.second = 0;

	return ret;
}

static void
manage_comp_alarm_update (ECalBackendContacts *cbc,
                          ECalComponent *comp)
{
	gchar *old_comp_str, *new_comp_str;
	ECalComponent *old_comp;

	g_return_if_fail (cbc != NULL);
	g_return_if_fail (comp != NULL);

	old_comp = e_cal_component_clone (comp);
	setup_alarm (cbc, comp);

	old_comp_str = e_cal_component_get_as_string (old_comp);
	new_comp_str = e_cal_component_get_as_string (comp);

	/* check if component changed and notify if so */
	if (old_comp_str && new_comp_str && !g_str_equal (old_comp_str, new_comp_str))
		e_cal_backend_notify_component_modified (E_CAL_BACKEND (cbc), old_comp, comp);

	g_free (old_comp_str);
	g_free (new_comp_str);
	g_object_unref (old_comp);
}

static void
update_alarm_cb (gpointer key,
                 gpointer value,
                 gpointer user_data)
{
	ECalBackendContacts *cbc = user_data;
	ContactRecord   *record = value;

	g_return_if_fail (cbc != NULL);
	g_return_if_fail (record != NULL);

	if (record->comp_birthday)
		manage_comp_alarm_update (cbc, record->comp_birthday);

	if (record->comp_anniversary)
		manage_comp_alarm_update (cbc, record->comp_anniversary);
}

static gboolean
update_tracked_alarms_cb (gpointer user_data)
{
	ECalBackendContacts *cbc = user_data;

	g_return_val_if_fail (cbc != NULL, FALSE);

	g_rec_mutex_lock (&cbc->priv->tracked_contacts_lock);
	g_hash_table_foreach (cbc->priv->tracked_contacts, update_alarm_cb, cbc);
	g_rec_mutex_unlock (&cbc->priv->tracked_contacts_lock);

	cbc->priv->update_alarms_id = 0;

	return FALSE;
}

#define BA_CONF_ENABLED		"contacts-reminder-enabled"
#define BA_CONF_INTERVAL	"contacts-reminder-interval"
#define BA_CONF_UNITS		"contacts-reminder-units"

static void
alarm_config_changed_cb (GSettings *settings,
                         const gchar *key,
                         gpointer user_data)
{
	ECalBackendContacts *cbc = user_data;

	g_return_if_fail (cbc != NULL);

	if (g_strcmp0 (key, BA_CONF_ENABLED) != 0 &&
	    g_strcmp0 (key, BA_CONF_INTERVAL) != 0 &&
	    g_strcmp0 (key, BA_CONF_UNITS) != 0)
		return;

	setup_alarm (cbc, NULL);

	if (!cbc->priv->update_alarms_id)
		cbc->priv->update_alarms_id = g_idle_add (update_tracked_alarms_cb, cbc);
}

/* When called with NULL, then just refresh local static variables on setup change from the user. */
static void
setup_alarm (ECalBackendContacts *cbc,
             ECalComponent *comp)
{
	ECalComponentAlarm *alarm;
	ECalComponentAlarmTrigger trigger;
	ECalComponentText summary;

	g_return_if_fail (cbc != NULL);

	if (!comp || cbc->priv->alarm_interval == -1) {
		gchar *str;

		if (cbc->priv->alarm_interval == -1) {
			/* initial setup, hook callback for changes too */
			cbc->priv->notifyid = g_signal_connect (cbc->priv->settings,
				"changed", G_CALLBACK (alarm_config_changed_cb), cbc);
		}

		cbc->priv->alarm_enabled = g_settings_get_boolean (cbc->priv->settings, BA_CONF_ENABLED);
		cbc->priv->alarm_interval = g_settings_get_int (cbc->priv->settings, BA_CONF_INTERVAL);

		str = g_settings_get_string (cbc->priv->settings, BA_CONF_UNITS);
		if (str && !strcmp (str, "days"))
			cbc->priv->alarm_units = CAL_DAYS;
		else if (str && !strcmp (str, "hours"))
			cbc->priv->alarm_units = CAL_HOURS;
		else
			cbc->priv->alarm_units = CAL_MINUTES;

		g_free (str);

		if (cbc->priv->alarm_interval <= 0)
			cbc->priv->alarm_interval = 1;

		if (!comp)
			return;
	}

	/* ensure no alarms left */
	e_cal_component_remove_all_alarms (comp);

	/* do not want alarms, return */
	if (!cbc->priv->alarm_enabled)
		return;

	alarm = e_cal_component_alarm_new ();
	e_cal_component_get_summary (comp, &summary);
	e_cal_component_alarm_set_description (alarm, &summary);
	e_cal_component_alarm_set_action (alarm, E_CAL_COMPONENT_ALARM_DISPLAY);

	trigger.type = E_CAL_COMPONENT_ALARM_TRIGGER_RELATIVE_START;

	memset (&trigger.u.rel_duration, 0, sizeof (trigger.u.rel_duration));

	trigger.u.rel_duration.is_neg = TRUE;

	switch (cbc->priv->alarm_units) {
	case CAL_MINUTES:
		trigger.u.rel_duration.minutes = cbc->priv->alarm_interval;
		break;

	case CAL_HOURS:
		trigger.u.rel_duration.hours = cbc->priv->alarm_interval;
		break;

	case CAL_DAYS:
		trigger.u.rel_duration.days = cbc->priv->alarm_interval;
		break;

	default:
		g_warning ("%s: wrong units %d\n", G_STRFUNC, cbc->priv->alarm_units);
		e_cal_component_alarm_free (alarm);
		return;
	}

	e_cal_component_alarm_set_trigger (alarm, trigger);
	e_cal_component_add_alarm (comp, alarm);
	e_cal_component_alarm_free (alarm);
}

#undef BA_CONF_ENABLED
#undef BA_CONF_INTERVAL
#undef BA_CONF_UNITS

/* Contact -> Event creator */
static ECalComponent *
create_component (ECalBackendContacts *cbc,
                  const gchar *uid,
                  EContactDate *cdate,
                  const gchar *summary)
{
	ECalComponent             *cal_comp;
	ECalComponentText          comp_summary;
	icalcomponent             *ical_comp;
	icalproperty		  *prop;
	struct icaltimetype        itt;
	ECalComponentDateTime      dt;
	struct icalrecurrencetype  r;
	gchar			  *since_year;
	GSList recur_list;

	g_return_val_if_fail (E_IS_CAL_BACKEND_CONTACTS (cbc), NULL);

	if (!cdate)
		return NULL;

	ical_comp = icalcomponent_new (ICAL_VEVENT_COMPONENT);

	since_year = g_strdup_printf ("%04d", cdate->year);
	prop = icalproperty_new_x (since_year);
	icalproperty_set_x_name (prop, "X-EVOLUTION-SINCE-YEAR");
	icalcomponent_add_property (ical_comp, prop);
	g_free (since_year);

	/* Create the event object */
	cal_comp = e_cal_component_new ();
	e_cal_component_set_icalcomponent (cal_comp, ical_comp);

	/* Set uid */
	d (g_message ("Creating UID: %s", uid));
	e_cal_component_set_uid (cal_comp, uid);

	/* Set all-day event's date from contact data */
	itt = cdate_to_icaltime (cdate);
	dt.value = &itt;
	dt.tzid = NULL;
	e_cal_component_set_dtstart (cal_comp, &dt);

	itt = cdate_to_icaltime (cdate);
	icaltime_adjust (&itt, 1, 0, 0, 0);
	dt.value = &itt;
	dt.tzid = NULL;
	/* We have to add 1 day to DTEND, as it is not inclusive. */
	e_cal_component_set_dtend (cal_comp, &dt);

	/* Create yearly recurrence */
	icalrecurrencetype_clear (&r);
	r.freq = ICAL_YEARLY_RECURRENCE;
	r.interval = 1;
	recur_list.data = &r;
	recur_list.next = NULL;
	e_cal_component_set_rrule_list (cal_comp, &recur_list);

	/* Create summary */
	comp_summary.value = summary;
	comp_summary.altrep = NULL;
	e_cal_component_set_summary (cal_comp, &comp_summary);

	/* Set category and visibility */
	if (g_str_has_suffix (uid, ANNIVERSARY_UID_EXT))
		e_cal_component_set_categories (cal_comp, _("Anniversary"));
	else if (g_str_has_suffix (uid, BIRTHDAY_UID_EXT))
		e_cal_component_set_categories (cal_comp, _("Birthday"));

	e_cal_component_set_classification (cal_comp, E_CAL_COMPONENT_CLASS_PRIVATE);

	/* Birthdays/anniversaries are shown as free time */
	e_cal_component_set_transparency (cal_comp, E_CAL_COMPONENT_TRANSP_TRANSPARENT);

	/* setup alarms if required */
	setup_alarm (cbc, cal_comp);

	/* Don't forget to call commit()! */
	e_cal_component_commit_sequence (cal_comp);

	return cal_comp;
}

static ECalComponent *
create_birthday (ECalBackendContacts *cbc,
                 EContact *contact)
{
	EContactDate  *cdate;
	ECalComponent *cal_comp;
	gchar          *summary;
	const gchar    *name;
	gchar *uid;

	cdate = e_contact_get (contact, E_CONTACT_BIRTH_DATE);
	name = e_contact_get_const (contact, E_CONTACT_FILE_AS);
	if (!name || !*name)
		name = e_contact_get_const (contact, E_CONTACT_FULL_NAME);
	if (!name || !*name)
		name = e_contact_get_const (contact, E_CONTACT_NICKNAME);
	if (!name)
		name = "";

	uid = g_strdup_printf ("%s%s", (gchar *) e_contact_get_const (contact, E_CONTACT_UID), BIRTHDAY_UID_EXT);
	summary = g_strdup_printf (_("Birthday: %s"), name);

	cal_comp = create_component (cbc, uid, cdate, summary);

	e_contact_date_free (cdate);
	g_free (uid);
	g_free (summary);

	return cal_comp;
}

static ECalComponent *
create_anniversary (ECalBackendContacts *cbc,
                    EContact *contact)
{
	EContactDate  *cdate;
	ECalComponent *cal_comp;
	gchar          *summary;
	const gchar    *name;
	gchar *uid;

	cdate = e_contact_get (contact, E_CONTACT_ANNIVERSARY);
	name = e_contact_get_const (contact, E_CONTACT_FILE_AS);
	if (!name || !*name)
		name = e_contact_get_const (contact, E_CONTACT_FULL_NAME);
	if (!name || !*name)
		name = e_contact_get_const (contact, E_CONTACT_NICKNAME);
	if (!name)
		name = "";

	uid = g_strdup_printf ("%s%s", (gchar *) e_contact_get_const (contact, E_CONTACT_UID), ANNIVERSARY_UID_EXT);
	summary = g_strdup_printf (_("Anniversary: %s"), name);

	cal_comp = create_component (cbc, uid, cdate, summary);

	e_contact_date_free (cdate);
	g_free (uid);
	g_free (summary);

	return cal_comp;
}

/************************************************************************************/
/* Calendar backend method implementations */

/* First the empty stubs */

static gchar *
e_cal_backend_contacts_get_backend_property (ECalBackend *backend,
                                             const gchar *prop_name)
{
	g_return_val_if_fail (prop_name != NULL, FALSE);

	if (g_str_equal (prop_name, CLIENT_BACKEND_PROPERTY_CAPABILITIES)) {
		return NULL;

	} else if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_CAL_EMAIL_ADDRESS) ||
		   g_str_equal (prop_name, CAL_BACKEND_PROPERTY_ALARM_EMAIL_ADDRESS)) {
		/* A contact backend has no particular email address associated
		 * with it (although that would be a useful feature some day).
		 */
		return NULL;

	} else if (g_str_equal (prop_name, CAL_BACKEND_PROPERTY_DEFAULT_OBJECT)) {
		return NULL;
	}

	/* Chain up to parent's get_backend_property() method. */
	return E_CAL_BACKEND_CLASS (e_cal_backend_contacts_parent_class)->
		get_backend_property (backend, prop_name);
}

static void
e_cal_backend_contacts_get_object (ECalBackendSync *backend,
                                   EDataCal *cal,
                                   GCancellable *cancellable,
                                   const gchar *uid,
                                   const gchar *rid,
                                   gchar **object,
                                   GError **perror)
{
	ECalBackendContacts *cbc = E_CAL_BACKEND_CONTACTS (backend);
	ECalBackendContactsPrivate *priv = cbc->priv;
	ContactRecord *record;
	gchar *real_uid;

	if (!uid) {
		g_propagate_error (perror, EDC_ERROR (ObjectNotFound));
		return;
	} else if (g_str_has_suffix (uid, ANNIVERSARY_UID_EXT))
		real_uid = g_strndup (uid, strlen (uid) - strlen (ANNIVERSARY_UID_EXT));
	else if (g_str_has_suffix (uid, BIRTHDAY_UID_EXT))
		real_uid = g_strndup (uid, strlen (uid) - strlen (BIRTHDAY_UID_EXT));
	else {
		g_propagate_error (perror, EDC_ERROR (ObjectNotFound));
		return;
	}

	g_rec_mutex_lock (&priv->tracked_contacts_lock);
	record = g_hash_table_lookup (priv->tracked_contacts, real_uid);
	g_free (real_uid);

	if (!record) {
		g_rec_mutex_unlock (&priv->tracked_contacts_lock);
		g_propagate_error (perror, EDC_ERROR (ObjectNotFound));
		return;
	}

	if (record->comp_birthday && g_str_has_suffix (uid, BIRTHDAY_UID_EXT)) {
		*object = e_cal_component_get_as_string (record->comp_birthday);
		g_rec_mutex_unlock (&priv->tracked_contacts_lock);

		d (g_message ("Return birthday: %s", *object));
		return;
	}

	if (record->comp_anniversary && g_str_has_suffix (uid, ANNIVERSARY_UID_EXT)) {
		*object = e_cal_component_get_as_string (record->comp_anniversary);
		g_rec_mutex_unlock (&priv->tracked_contacts_lock);

		d (g_message ("Return anniversary: %s", *object));
		return;
	}

	g_rec_mutex_unlock (&priv->tracked_contacts_lock);

	d (g_message ("Returning nothing for uid: %s", uid));

	g_propagate_error (perror, EDC_ERROR (ObjectNotFound));
}

static void
e_cal_backend_contacts_get_free_busy (ECalBackendSync *backend,
                                      EDataCal *cal,
                                      GCancellable *cancellable,
                                      const GSList *users,
                                      time_t start,
                                      time_t end,
                                      GSList **freebusy,
                                      GError **perror)
{
	/* Birthdays/anniversaries don't count as busy time */

	icalcomponent *vfb = icalcomponent_new_vfreebusy ();
	icaltimezone *utc_zone = icaltimezone_get_utc_timezone ();
	gchar *calobj;

#if 0
	icalproperty *prop;
	icalparameter *param;

	prop = icalproperty_new_organizer (address);
	if (prop != NULL && cn != NULL) {
		param = icalparameter_new_cn (cn);
		icalproperty_add_parameter (prop, param);
	}
	if (prop != NULL)
		icalcomponent_add_property (vfb, prop);
#endif

	icalcomponent_set_dtstart (vfb, icaltime_from_timet_with_zone (start, FALSE, utc_zone));
	icalcomponent_set_dtend (vfb, icaltime_from_timet_with_zone (end, FALSE, utc_zone));

	calobj = icalcomponent_as_ical_string_r (vfb);
	*freebusy = g_slist_append (NULL, calobj);
	icalcomponent_free (vfb);

	/* WRITE ME */
	/* Success */
}

static void
e_cal_backend_contacts_receive_objects (ECalBackendSync *backend,
                                        EDataCal *cal,
                                        GCancellable *cancellable,
                                        const gchar *calobj,
                                        GError **perror)
{
	g_propagate_error (perror, EDC_ERROR (PermissionDenied));
}

static void
e_cal_backend_contacts_send_objects (ECalBackendSync *backend,
                                     EDataCal *cal,
                                     GCancellable *cancellable,
                                     const gchar *calobj,
                                     GSList **users,
                                     gchar **modified_calobj,
                                     GError **perror)
{
	*users = NULL;
	*modified_calobj = NULL;
	/* TODO: Investigate this */
	g_propagate_error (perror, EDC_ERROR (PermissionDenied));
}

/* Then the real implementations */

static void
e_cal_backend_contacts_notify_online_cb (ECalBackend *backend,
                                         GParamSpec *pspec)
{
	e_cal_backend_set_writable (backend, FALSE);
}

static void
e_cal_backend_contacts_open (ECalBackendSync *backend,
                             EDataCal *cal,
                             GCancellable *cancellable,
                             gboolean only_if_exists,
                             GError **perror)
{
	ECalBackendContacts *cbc = E_CAL_BACKEND_CONTACTS (backend);
	ECalBackendContactsPrivate *priv = cbc->priv;

	if (priv->addressbook_loaded)
		return;

	/* Local source is always connected. */
	e_source_set_connection_status (e_backend_get_source (E_BACKEND (backend)),
		E_SOURCE_CONNECTION_STATUS_CONNECTED);

	priv->addressbook_loaded = TRUE;
	e_cal_backend_set_writable (E_CAL_BACKEND (backend), FALSE);
	e_backend_set_online (E_BACKEND (backend), TRUE);
}

/* Add_timezone handler for the file backend */
static void
e_cal_backend_contacts_add_timezone (ECalBackendSync *backend,
                                     EDataCal *cal,
                                     GCancellable *cancellable,
                                     const gchar *tzobj,
                                     GError **error)
{
	icalcomponent *tz_comp;
	icaltimezone *zone;

	tz_comp = icalparser_parse_string (tzobj);
	if (!tz_comp) {
		g_propagate_error (error, EDC_ERROR (InvalidObject));
		return;
	}

	if (icalcomponent_isa (tz_comp) != ICAL_VTIMEZONE_COMPONENT) {
		g_propagate_error (error, EDC_ERROR (InvalidObject));
		return;
	}

	zone = icaltimezone_new ();
	icaltimezone_set_component (zone, tz_comp);
	e_timezone_cache_add_timezone (E_TIMEZONE_CACHE (backend), zone);
	icaltimezone_free (zone, TRUE);
}

static void
e_cal_backend_contacts_get_object_list (ECalBackendSync *backend,
                                        EDataCal *cal,
                                        GCancellable *cancellable,
                                        const gchar *sexp_string,
                                        GSList **objects,
                                        GError **perror)
{
	ECalBackendContacts *cbc = E_CAL_BACKEND_CONTACTS (backend);
	ECalBackendContactsPrivate *priv = cbc->priv;
	ECalBackendSExp *sexp = e_cal_backend_sexp_new (sexp_string);
	ContactRecordCB *cb_data;

	if (!sexp) {
		g_propagate_error (perror, EDC_ERROR (InvalidQuery));
		return;
	}

	cb_data = contact_record_cb_new (cbc, sexp, TRUE);

	g_rec_mutex_lock (&priv->tracked_contacts_lock);
	g_hash_table_foreach (priv->tracked_contacts, contact_record_cb, cb_data);
	g_rec_mutex_unlock (&priv->tracked_contacts_lock);

	*objects = cb_data->result;

	contact_record_cb_free (cb_data, FALSE);
}

static void
e_cal_backend_contacts_start_view (ECalBackend *backend,
                                   EDataCalView *query)
{
	ECalBackendContacts *cbc = E_CAL_BACKEND_CONTACTS (backend);
	ECalBackendContactsPrivate *priv = cbc->priv;
	ECalBackendSExp *sexp;
	ContactRecordCB *cb_data;

	sexp = e_data_cal_view_get_sexp (query);
	if (!sexp) {
		GError *error = EDC_ERROR (InvalidQuery);
		e_data_cal_view_notify_complete (query, error);
		g_error_free (error);
		return;
	}

	cb_data = contact_record_cb_new (cbc, sexp, FALSE);

	g_rec_mutex_lock (&priv->tracked_contacts_lock);
	g_hash_table_foreach (priv->tracked_contacts, contact_record_cb, cb_data);
	e_data_cal_view_notify_components_added (query, cb_data->result);
	g_rec_mutex_unlock (&priv->tracked_contacts_lock);

	contact_record_cb_free (cb_data, TRUE);

	e_data_cal_view_notify_complete (query, NULL /* Success */);
}

/***********************************************************************************
 */

/* Finalize handler for the contacts backend */
static void
e_cal_backend_contacts_finalize (GObject *object)
{
	ECalBackendContactsPrivate *priv;

	priv = E_CAL_BACKEND_CONTACTS_GET_PRIVATE (object);

	if (priv->update_alarms_id) {
		g_source_remove (priv->update_alarms_id);
		priv->update_alarms_id = 0;
	}

	g_hash_table_destroy (priv->addressbooks);
	g_hash_table_destroy (priv->tracked_contacts);
	if (priv->notifyid)
		g_signal_handler_disconnect (priv->settings, priv->notifyid);

	g_object_unref (priv->settings);
	g_rec_mutex_clear (&priv->rec_mutex);
	g_rec_mutex_clear (&priv->tracked_contacts_lock);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cal_backend_contacts_parent_class)->finalize (object);
}

static void
e_cal_backend_contacts_dispose (GObject *object)
{
	ECalBackendContacts *cbcontacts = E_CAL_BACKEND_CONTACTS (object);

	g_clear_object (&cbcontacts->priv->registry_watcher);

	/* Chain up to parent's dispose() method. */
	G_OBJECT_CLASS (e_cal_backend_contacts_parent_class)->dispose (object);
}

static void
e_cal_backend_contacts_constructed (GObject *object)
{
	ECalBackendContacts *cbcontacts = E_CAL_BACKEND_CONTACTS (object);
	ESourceRegistry *registry;

	/* Chain up to parent's constructed() method. */
	G_OBJECT_CLASS (e_cal_backend_contacts_parent_class)->constructed (object);

	registry = e_cal_backend_get_registry (E_CAL_BACKEND (cbcontacts));

	cbcontacts->priv->registry_watcher = e_source_registry_watcher_new (registry, E_SOURCE_EXTENSION_ADDRESS_BOOK);

	g_signal_connect (cbcontacts->priv->registry_watcher, "filter",
		G_CALLBACK (ecb_contacts_watcher_filter_cb), cbcontacts);

	g_signal_connect (cbcontacts->priv->registry_watcher, "appeared",
		G_CALLBACK (ecb_contacts_watcher_appeared_cb), cbcontacts);

	g_signal_connect (cbcontacts->priv->registry_watcher, "disappeared",
		G_CALLBACK (ecb_contacts_watcher_disappeared_cb), cbcontacts);

	/* Load address book sources from an idle callback
	 * to avoid deadlocking e_data_factory_ref_backend(). */
	g_idle_add_full (G_PRIORITY_DEFAULT_IDLE, cal_backend_contacts_load_sources,
		g_object_ref (object), g_object_unref);
}

/* Object initialization function for the contacts backend */
static void
e_cal_backend_contacts_init (ECalBackendContacts *cbc)
{
	cbc->priv = E_CAL_BACKEND_CONTACTS_GET_PRIVATE (cbc);

	g_rec_mutex_init (&cbc->priv->rec_mutex);
	g_rec_mutex_init (&cbc->priv->tracked_contacts_lock);

	cbc->priv->addressbooks = g_hash_table_new_full (
		(GHashFunc) e_source_hash,
		(GEqualFunc) e_source_equal,
		(GDestroyNotify) g_object_unref,
		(GDestroyNotify) cancel_and_unref_book_record);

	cbc->priv->tracked_contacts = g_hash_table_new_full (
		(GHashFunc) g_str_hash,
		(GEqualFunc) g_str_equal,
		(GDestroyNotify) g_free,
		(GDestroyNotify) contact_record_free);

	cbc->priv->settings = g_settings_new ("org.gnome.evolution-data-server.calendar");
	cbc->priv->notifyid = 0;
	cbc->priv->update_alarms_id = 0;
	cbc->priv->alarm_enabled = FALSE;
	cbc->priv->alarm_interval = -1;
	cbc->priv->alarm_units = CAL_MINUTES;

	g_signal_connect (
		cbc, "notify::online",
		G_CALLBACK (e_cal_backend_contacts_notify_online_cb), NULL);
}

static void
e_cal_backend_contacts_create_objects (ECalBackendSync *backend,
                                       EDataCal *cal,
                                       GCancellable *cancellable,
                                       const GSList *calobjs,
                                       GSList **uids,
                                       GSList **new_components,
                                       GError **perror)
{
	g_propagate_error (perror, EDC_ERROR (PermissionDenied));
}

/* Class initialization function for the contacts backend */
static void
e_cal_backend_contacts_class_init (ECalBackendContactsClass *class)
{
	GObjectClass *object_class;
	ECalBackendClass *backend_class;
	ECalBackendSyncClass *sync_class;

	g_type_class_add_private (class, sizeof (ECalBackendContactsPrivate));

	object_class = (GObjectClass *) class;
	backend_class = (ECalBackendClass *) class;
	sync_class = (ECalBackendSyncClass *) class;

	object_class->finalize = e_cal_backend_contacts_finalize;
	object_class->dispose = e_cal_backend_contacts_dispose;
	object_class->constructed = e_cal_backend_contacts_constructed;

	/* Execute one method at a time. */
	backend_class->use_serial_dispatch_queue = TRUE;

	backend_class->get_backend_property = e_cal_backend_contacts_get_backend_property;

	sync_class->open_sync = e_cal_backend_contacts_open;
	sync_class->create_objects_sync = e_cal_backend_contacts_create_objects;
	sync_class->receive_objects_sync = e_cal_backend_contacts_receive_objects;
	sync_class->send_objects_sync = e_cal_backend_contacts_send_objects;
	sync_class->get_object_sync = e_cal_backend_contacts_get_object;
	sync_class->get_object_list_sync = e_cal_backend_contacts_get_object_list;
	sync_class->add_timezone_sync = e_cal_backend_contacts_add_timezone;
	sync_class->get_free_busy_sync = e_cal_backend_contacts_get_free_busy;

	backend_class->start_view = e_cal_backend_contacts_start_view;

	/* Register our ESource extension. */
	E_TYPE_SOURCE_CONTACTS;
}
