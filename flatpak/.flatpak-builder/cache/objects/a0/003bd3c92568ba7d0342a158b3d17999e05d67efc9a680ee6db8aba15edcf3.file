/* Evolution calendar - iCalendar component object
 *
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
 * Authors: Federico Mena-Quintero <federico@ximian.com>
 */

/**
 * SECTION:e-cal-component
 * @short_description: A convenience interface for interacting with events
 * @include: libebook-contacts/libebook-contacts.h
 *
 * This is the main user facing interface used for representing an event
 * or other component in a given calendar.
 **/

#include "evolution-data-server-config.h"

#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <glib/gi18n-lib.h>
#include <glib/gstdio.h>

#include <libedataserver/libedataserver.h>

#include "e-cal-component.h"
#include "e-cal-time-util.h"

#ifdef G_OS_WIN32
#define getgid() 0
#define getppid() 0
#endif

#define E_CAL_COMPONENT_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_CAL_COMPONENT, ECalComponentPrivate))

G_DEFINE_TYPE (ECalComponent, e_cal_component, G_TYPE_OBJECT)
G_DEFINE_BOXED_TYPE (ECalComponentId,
		e_cal_component_id,
		e_cal_component_id_copy,
		e_cal_component_free_id)
G_DEFINE_BOXED_TYPE (ECalComponentAlarm,
		e_cal_component_alarm,
		e_cal_component_alarm_clone,
		e_cal_component_alarm_free)

/* Extension property for alarm components so that we can reference them by UID */
#define EVOLUTION_ALARM_UID_PROPERTY "X-EVOLUTION-ALARM-UID"

struct attendee {
	icalproperty *prop;
	icalparameter *cutype_param;
	icalparameter *member_param;
	icalparameter *role_param;
	icalparameter *partstat_param;
	icalparameter *rsvp_param;
	icalparameter *delto_param;
	icalparameter *delfrom_param;
	icalparameter *sentby_param;
	icalparameter *cn_param;
	icalparameter *language_param;
};

struct attachment {
	icalproperty *prop;
	icalattach *attach;

	/* for inline attachments, where the file is stored;
	 * it unlinks it on attachment free. */
	gchar *temporary_filename;
};

struct text {
	icalproperty *prop;
	icalparameter *altrep_param;
};

struct datetime {
	icalproperty *prop;
	icalparameter *tzid_param;
};

struct organizer {
	icalproperty *prop;
	icalparameter *sentby_param;
	icalparameter *cn_param;
	icalparameter *language_param;
};

struct period {
	icalproperty *prop;
	icalparameter *value_param;
};

struct recur_id {
	struct datetime recur_time;

	icalparameter *range_param;
};

/* Private part of the CalComponent structure */
struct _ECalComponentPrivate {
	/* The icalcomponent we wrap */
	icalcomponent *icalcomp;

	/* Properties */

	icalproperty *uid;

	icalproperty *status;
	GSList *attendee_list;

	GString *categories_str;

	icalproperty *classification;

	GSList *comment_list; /* list of struct text */

	icalproperty *completed;

	GSList *contact_list; /* list of struct text */

	icalproperty *created;

	GSList *description_list; /* list of struct text */

	struct datetime dtstart;
	struct datetime dtend;

	icalproperty *dtstamp;

	/* The DURATION property can be used instead of the VEVENT DTEND or
	 * the VTODO DUE dates. We do not use it directly ourselves, but we
	 * must be able to handle it from incoming data. If a DTEND or DUE
	 * is requested, we convert the DURATION if necessary. If DTEND or
	 * DUE is set, we remove any DURATION. */
	icalproperty *duration;

	struct datetime due;

	GSList *exdate_list; /* list of struct datetime */
	GSList *exrule_list; /* list of icalproperty objects */

	struct organizer organizer;

	icalproperty *geo;
	icalproperty *last_modified;
	icalproperty *percent;
	icalproperty *priority;

	struct recur_id recur_id;

	GSList *rdate_list; /* list of struct period */

	GSList *rrule_list; /* list of icalproperty objects */

	icalproperty *sequence;

	struct {
		icalproperty *prop;
		icalparameter *altrep_param;
	} summary;

	icalproperty *transparency;
	icalproperty *url;
	icalproperty *location;

	GSList *attachment_list;

	/* Subcomponents */

	GHashTable *alarm_uid_hash;

	/* Whether we should increment the sequence number when piping the
	 * object over the wire.
	 */
	guint need_sequence_inc : 1;
};

/* Private structure for alarms */
struct _ECalComponentAlarm {
	/* Alarm icalcomponent we wrap */
	icalcomponent *icalcomp;

	/* Our extension UID property */
	icalproperty *uid;

	/* Properties */

	icalproperty *action;
	icalproperty *attach; /* FIXME: see scan_alarm_property () below */

	struct {
		icalproperty *prop;
		icalparameter *altrep_param;
	} description;

	icalproperty *duration;
	icalproperty *repeat;
	icalproperty *trigger;

	GSList *attendee_list;
};

/* Does a simple g_free() of the elements of a GSList and then frees the list
 * itself.  Returns NULL.
 */
static GSList *
free_slist (GSList *slist)
{
	g_slist_free_full (slist, (GDestroyNotify) g_free);

	return NULL;
}

/* Used from g_hash_table_foreach_remove() to free the alarm UIDs hash table.
 * We do not need to do anything to individual elements since we were storing
 * the UID pointers inside the icalproperties themselves.
 */
static gboolean
free_alarm_cb (gpointer key,
               gpointer value,
               gpointer data)
{
	return TRUE;
}

static void
free_attachment (struct attachment *attachment)
{
	if (!attachment)
		return;

	icalattach_unref (attachment->attach);

	if (attachment->temporary_filename) {
		gchar *sep;

		g_unlink (attachment->temporary_filename);

		sep = strrchr (attachment->temporary_filename, G_DIR_SEPARATOR);
		if (sep) {
			*sep = '\0';
			g_rmdir (attachment->temporary_filename);
		}
	}

	g_free (attachment->temporary_filename);
	g_free (attachment);
}

/* Frees the internal icalcomponent only if it does not have a parent.  If it
 * does, it means we don't own it and we shouldn't free it.
 */
static void
free_icalcomponent (ECalComponent *comp,
                    gboolean free)
{
	ECalComponentPrivate *priv;

	priv = comp->priv;

	if (!priv->icalcomp)
		return;

	/* Free the mappings */

	priv->uid = NULL;
	priv->recur_id.recur_time.prop = NULL;

	priv->status = NULL;

	g_slist_foreach (priv->attachment_list, (GFunc) free_attachment, NULL);
	g_slist_free (priv->attachment_list);
	priv->attachment_list = NULL;

	g_slist_foreach (priv->attendee_list, (GFunc) g_free, NULL);
	g_slist_free (priv->attendee_list);
	priv->attendee_list = NULL;

	if (priv->categories_str)
		g_string_free (priv->categories_str, TRUE);
	priv->categories_str = NULL;

	priv->classification = NULL;
	priv->comment_list = free_slist (priv->comment_list);
	priv->completed = NULL;
	priv->contact_list = free_slist (priv->contact_list);
	priv->created = NULL;

	priv->description_list = free_slist (priv->description_list);

	priv->dtend.prop = NULL;
	priv->dtend.tzid_param = NULL;

	priv->dtstamp = NULL;

	priv->dtstart.prop = NULL;
	priv->dtstart.tzid_param = NULL;

	priv->due.prop = NULL;
	priv->due.tzid_param = NULL;

	priv->duration = NULL;

	priv->exdate_list = free_slist (priv->exdate_list);

	g_slist_free (priv->exrule_list);
	priv->exrule_list = NULL;

	priv->geo = NULL;
	priv->last_modified = NULL;
	priv->percent = NULL;
	priv->priority = NULL;

	priv->rdate_list = free_slist (priv->rdate_list);

	g_slist_free (priv->rrule_list);
	priv->rrule_list = NULL;

	priv->sequence = NULL;

	priv->summary.prop = NULL;
	priv->summary.altrep_param = NULL;

	priv->transparency = NULL;
	priv->url = NULL;
	priv->location = NULL;

	/* Free the subcomponents */

	g_hash_table_foreach_remove (priv->alarm_uid_hash, free_alarm_cb, NULL);

	/* Free the icalcomponent */

	if (free && icalcomponent_get_parent (priv->icalcomp) == NULL) {
		icalcomponent_free (priv->icalcomp);
		priv->icalcomp = NULL;
	}

	/* Clean up */

	priv->need_sequence_inc = FALSE;
}

static void
cal_component_finalize (GObject *object)
{
	ECalComponentPrivate *priv;

	priv = E_CAL_COMPONENT_GET_PRIVATE (object);

	free_icalcomponent (E_CAL_COMPONENT (object), TRUE);
	g_hash_table_destroy (priv->alarm_uid_hash);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_cal_component_parent_class)->finalize (object);
}



/* Class initialization function for the calendar component object */
static void
e_cal_component_class_init (ECalComponentClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (ECalComponentPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = cal_component_finalize;
}

/* Object initialization function for the calendar component object */
static void
e_cal_component_init (ECalComponent *comp)
{
	comp->priv = E_CAL_COMPONENT_GET_PRIVATE (comp);
	comp->priv->alarm_uid_hash = g_hash_table_new (g_str_hash, g_str_equal);
}

/**
 * e_cal_component_gen_uid:
 *
 * Generates a unique identifier suitable for calendar components.
 *
 * Returns: A unique identifier string.  Every time this function is called
 * a different string is returned.
 *
 * Deprecated: Since 3.26, use e_util_generate_uid() instead
 **/
gchar *
e_cal_component_gen_uid (void)
{
	return e_util_generate_uid ();
}

/**
 * e_cal_component_new:
 *
 * Creates a new empty calendar component object.  Once created, you should set it from an
 * existing #icalcomponent structure by using e_cal_component_set_icalcomponent() or with a
 * new empty component type by using e_cal_component_set_new_vtype().
 *
 * Returns: A newly-created calendar component object.
 **/
ECalComponent *
e_cal_component_new (void)
{
	return E_CAL_COMPONENT (g_object_new (E_TYPE_CAL_COMPONENT, NULL));
}

/**
 * e_cal_component_new_from_string:
 * @calobj: A string representation of an iCalendar component.
 *
 * Creates a new calendar component object from the given iCalendar string.
 *
 * Returns: A calendar component representing the given iCalendar string on
 * success, NULL if there was an error.
 **/
ECalComponent *
e_cal_component_new_from_string (const gchar *calobj)
{
	icalcomponent *icalcomp;

	g_return_val_if_fail (calobj != NULL, NULL);

	icalcomp = icalparser_parse_string (calobj);
	if (!icalcomp)
		return NULL;

	return e_cal_component_new_from_icalcomponent (icalcomp);
}

/**
 * e_cal_component_new_from_icalcomponent:
 * @icalcomp: An #icalcomponent to use
 *
 * Creates a new #ECalComponent which will has set @icalcomp as
 * an inner #icalcomponent. The newly created #ECalComponent takes
 * ownership of the @icalcomp, and if the call
 * to e_cal_component_set_icalcomponent() fails, then @icalcomp
 * is freed.
 *
 * Returns: An #ECalComponent with @icalcomp assigned on success,
 * NULL if the @icalcomp cannot be assigned to #ECalComponent.
 *
 * Since: 3.4
 **/
ECalComponent *
e_cal_component_new_from_icalcomponent (icalcomponent *icalcomp)
{
	ECalComponent *comp;

	g_return_val_if_fail (icalcomp != NULL, NULL);

	comp = e_cal_component_new ();
	if (!e_cal_component_set_icalcomponent (comp, icalcomp)) {
		icalcomponent_free (icalcomp);
		g_object_unref (comp);

		return NULL;
	}

	return comp;
}

/**
 * e_cal_component_clone:
 * @comp: A calendar component object.
 *
 * Creates a new calendar component object by copying the information from
 * another one.
 *
 * Returns: (transfer full): A newly-created calendar component with the same
 * values as the original one.
 **/
ECalComponent *
e_cal_component_clone (ECalComponent *comp)
{
	ECalComponentPrivate *priv;
	ECalComponent *new_comp;
	icalcomponent *new_icalcomp;

	g_return_val_if_fail (comp != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	priv = comp->priv;
	g_return_val_if_fail (priv->need_sequence_inc == FALSE, NULL);

	new_comp = e_cal_component_new ();

	if (priv->icalcomp) {
		new_icalcomp = icalcomponent_new_clone (priv->icalcomp);
		e_cal_component_set_icalcomponent (new_comp, new_icalcomp);
	}

	return new_comp;
}

/* Scans an attachment property */
static void
scan_attachment (GSList **attachment_list,
                 icalproperty *prop)
{
	struct attachment *attachment;

	attachment = g_new0 (struct attachment, 1);
	attachment->prop = prop;

	attachment->attach = icalproperty_get_attach (prop);
	icalattach_ref (attachment->attach);

	*attachment_list = g_slist_append (*attachment_list, attachment);
}

/* Scans an attendee property */
static void
scan_attendee (GSList **attendee_list,
               icalproperty *prop)
{
	struct attendee *attendee;

	attendee = g_new (struct attendee, 1);
	attendee->prop = prop;

	attendee->cutype_param = icalproperty_get_first_parameter (prop, ICAL_CUTYPE_PARAMETER);
	attendee->member_param = icalproperty_get_first_parameter (prop, ICAL_MEMBER_PARAMETER);
	attendee->role_param = icalproperty_get_first_parameter (prop, ICAL_ROLE_PARAMETER);
	attendee->partstat_param = icalproperty_get_first_parameter (prop, ICAL_PARTSTAT_PARAMETER);
	attendee->rsvp_param = icalproperty_get_first_parameter (prop, ICAL_RSVP_PARAMETER);
	attendee->delto_param = icalproperty_get_first_parameter (prop, ICAL_DELEGATEDTO_PARAMETER);
	attendee->delfrom_param = icalproperty_get_first_parameter (prop, ICAL_DELEGATEDFROM_PARAMETER);
	attendee->sentby_param = icalproperty_get_first_parameter (prop, ICAL_SENTBY_PARAMETER);
	attendee->cn_param = icalproperty_get_first_parameter (prop, ICAL_CN_PARAMETER);
	attendee->language_param = icalproperty_get_first_parameter (prop, ICAL_LANGUAGE_PARAMETER);

	*attendee_list = g_slist_append (*attendee_list, attendee);
}

/* Scans a date/time and timezone pair property */
static void
scan_datetime (ECalComponent *comp,
               struct datetime *datetime,
               icalproperty *prop)
{
	datetime->prop = prop;
	datetime->tzid_param = icalproperty_get_first_parameter (prop, ICAL_TZID_PARAMETER);
}

/* Scans an exception date property */
static void
scan_exdate (ECalComponent *comp,
             icalproperty *prop)
{
	ECalComponentPrivate *priv;
	struct datetime *dt;

	priv = comp->priv;

	dt = g_new (struct datetime, 1);
	dt->prop = prop;
	dt->tzid_param = icalproperty_get_first_parameter (prop, ICAL_TZID_PARAMETER);

	priv->exdate_list = g_slist_append (priv->exdate_list, dt);
}

/* Scans and attendee property */
static void
scan_organizer (ECalComponent *comp,
                struct organizer *organizer,
                icalproperty *prop)
{
	organizer->prop = prop;

	organizer->sentby_param = icalproperty_get_first_parameter (prop, ICAL_SENTBY_PARAMETER);
	organizer->cn_param = icalproperty_get_first_parameter (prop, ICAL_CN_PARAMETER);
	organizer->language_param = icalproperty_get_first_parameter (prop, ICAL_LANGUAGE_PARAMETER);
}

/* Scans an icalperiodtype property */
static void
scan_period (ECalComponent *comp,
             GSList **list,
             icalproperty *prop)
{
	struct period *period;

	period = g_new (struct period, 1);
	period->prop = prop;
	period->value_param = icalproperty_get_first_parameter (prop, ICAL_VALUE_PARAMETER);

	*list = g_slist_append (*list, period);
}

/* Scans an icalrecurtype property */
static void
scan_recur_id (ECalComponent *comp,
               struct recur_id *recur_id,
               icalproperty *prop)
{
	scan_datetime (comp, &recur_id->recur_time, prop);

	recur_id->range_param = icalproperty_get_first_parameter (prop, ICAL_RANGE_PARAMETER);
}

/* Scans an icalrecurtype property */
static void
scan_recur (ECalComponent *comp,
            GSList **list,
            icalproperty *prop)
{
	*list = g_slist_append (*list, prop);
}

/* Scans the summary property */
static void
scan_summary (ECalComponent *comp,
              icalproperty *prop)
{
	ECalComponentPrivate *priv;

	priv = comp->priv;

	priv->summary.prop = prop;
	priv->summary.altrep_param = icalproperty_get_first_parameter (prop, ICAL_ALTREP_PARAMETER);
}

/* Scans a text (i.e. text + altrep) property */
static void
scan_text (ECalComponent *comp,
           GSList **text_list,
           icalproperty *prop)
{
	struct text *text;

	text = g_new (struct text, 1);
	text->prop = prop;
	text->altrep_param = icalproperty_get_first_parameter (prop, ICAL_ALTREP_PARAMETER);

	*text_list = g_slist_append (*text_list, text);
}

/* Scans an icalproperty and adds its mapping to the component */
static void
scan_property (ECalComponent *comp,
               icalproperty *prop)
{
	ECalComponentPrivate *priv;
	icalproperty_kind kind;

	priv = comp->priv;

	kind = icalproperty_isa (prop);

	switch (kind) {
	case ICAL_STATUS_PROPERTY:
		priv->status = prop;
		break;

	case ICAL_ATTACH_PROPERTY:
		scan_attachment (&priv->attachment_list, prop);
		break;

	case ICAL_ATTENDEE_PROPERTY:
		scan_attendee (&priv->attendee_list, prop);
		break;

	case ICAL_CATEGORIES_PROPERTY:
		if (icalproperty_get_categories (prop)) {
			const gchar *categories = icalproperty_get_categories (prop);
			if (*categories) {
				if (!priv->categories_str) {
					priv->categories_str = g_string_new (categories);
				} else {
					g_string_append_c (priv->categories_str, ',');
					g_string_append (priv->categories_str, categories);
				}
			}
		}
		break;

	case ICAL_CLASS_PROPERTY:
		priv->classification = prop;
		break;

	case ICAL_COMMENT_PROPERTY:
		scan_text (comp, &priv->comment_list, prop);
		break;

	case ICAL_COMPLETED_PROPERTY:
		priv->completed = prop;
		break;

	case ICAL_CONTACT_PROPERTY:
		scan_text (comp, &priv->contact_list, prop);
		break;

	case ICAL_CREATED_PROPERTY:
		priv->created = prop;
		break;

	case ICAL_DESCRIPTION_PROPERTY:
		scan_text (comp, &priv->description_list, prop);
		break;

	case ICAL_DTEND_PROPERTY:
		scan_datetime (comp, &priv->dtend, prop);
		break;

	case ICAL_DTSTAMP_PROPERTY:
		priv->dtstamp = prop;
		break;

	case ICAL_DTSTART_PROPERTY:
		scan_datetime (comp, &priv->dtstart, prop);
		break;

	case ICAL_DUE_PROPERTY:
		scan_datetime (comp, &priv->due, prop);
		break;

	case ICAL_DURATION_PROPERTY:
		priv->duration = prop;
		break;

	case ICAL_EXDATE_PROPERTY:
		scan_exdate (comp, prop);
		break;

	case ICAL_EXRULE_PROPERTY:
		scan_recur (comp, &priv->exrule_list, prop);
		break;

	case ICAL_GEO_PROPERTY:
		priv->geo = prop;
		break;

	case ICAL_LASTMODIFIED_PROPERTY:
		priv->last_modified = prop;
		break;

	case ICAL_ORGANIZER_PROPERTY:
		scan_organizer (comp, &priv->organizer, prop);
		break;

	case ICAL_PERCENTCOMPLETE_PROPERTY:
		priv->percent = prop;
		break;

	case ICAL_PRIORITY_PROPERTY:
		priv->priority = prop;
		break;

	case ICAL_RECURRENCEID_PROPERTY:
		scan_recur_id (comp, &priv->recur_id, prop);
		break;

	case ICAL_RDATE_PROPERTY:
		scan_period (comp, &priv->rdate_list, prop);
		break;

	case ICAL_RRULE_PROPERTY:
		scan_recur (comp, &priv->rrule_list, prop);
		break;

	case ICAL_SEQUENCE_PROPERTY:
		priv->sequence = prop;
		break;

	case ICAL_SUMMARY_PROPERTY:
		scan_summary (comp, prop);
		break;

	case ICAL_TRANSP_PROPERTY:
		priv->transparency = prop;
		break;

	case ICAL_UID_PROPERTY:
		priv->uid = prop;
		break;

	case ICAL_URL_PROPERTY:
		priv->url = prop;
		break;

	case ICAL_LOCATION_PROPERTY :
		priv->location = prop;
		break;

	default:
		break;
	}
}

/* Gets our alarm UID string from a property that is known to contain it */
static const gchar *
alarm_uid_from_prop (icalproperty *prop)
{
	const gchar *xstr;

	g_return_val_if_fail (icalproperty_isa (prop) == ICAL_X_PROPERTY, NULL);

	xstr = icalproperty_get_x (prop);
	g_return_val_if_fail (xstr != NULL, NULL);

	return xstr;
}

/* Sets our alarm UID extension property on an alarm component.  Returns a
 * pointer to the UID string inside the property itself.
 */
static const gchar *
set_alarm_uid (icalcomponent *alarm,
               const gchar *auid)
{
	icalproperty *prop;
	const gchar *inprop_auid;

	/* Create the new property */

	prop = icalproperty_new_x ((gchar *) auid);
	icalproperty_set_x_name (prop, EVOLUTION_ALARM_UID_PROPERTY);

	icalcomponent_add_property (alarm, prop);

	inprop_auid = alarm_uid_from_prop (prop);
	return inprop_auid;
}

/* Removes any alarm UID extension properties from an alarm subcomponent */
static void
remove_alarm_uid (icalcomponent *alarm)
{
	icalproperty *prop;
	GSList *list, *l;

	list = NULL;

	for (prop = icalcomponent_get_first_property (alarm, ICAL_X_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (alarm, ICAL_X_PROPERTY)) {
		const gchar *xname;

		xname = icalproperty_get_x_name (prop);
		g_return_if_fail (xname != NULL);

		if (strcmp (xname, EVOLUTION_ALARM_UID_PROPERTY) == 0)
			list = g_slist_prepend (list, prop);
	}

	for (l = list; l; l = l->next) {
		prop = l->data;
		icalcomponent_remove_property (alarm, prop);
		icalproperty_free (prop);
	}

	g_slist_free (list);
}

/* Adds an alarm subcomponent to the calendar component's mapping table.  The
 * actual UID with which it gets added may not be the same as the specified one;
 * this function will change it if the table already had an alarm subcomponent
 * with the specified UID.  Returns the actual UID used.
 */
static const gchar *
add_alarm (ECalComponent *comp,
           icalcomponent *alarm,
           const gchar *auid)
{
	ECalComponentPrivate *priv;
	icalcomponent *old_alarm;

	priv = comp->priv;

	/* First we see if we already have an alarm with the requested UID.  In
	 * that case, we need to change the new UID to something else.  This
	 * should never happen, but who knows.
	 */

	old_alarm = g_hash_table_lookup (priv->alarm_uid_hash, auid);
	if (old_alarm != NULL) {
		gchar *new_auid;

		g_message ("add_alarm(): Got alarm with duplicated UID `%s', changing it...", auid);

		remove_alarm_uid (alarm);

		new_auid = e_util_generate_uid ();
		auid = set_alarm_uid (alarm, new_auid);
		g_free (new_auid);
	}

	g_hash_table_insert (priv->alarm_uid_hash, (gchar *) auid, alarm);
	return auid;
}

/* Scans an alarm subcomponent, adds an UID extension property to it (so that we
 * can reference alarms by unique IDs), and adds its mapping to the component.  */
static void
scan_alarm (ECalComponent *comp,
            icalcomponent *alarm)
{
	icalproperty *prop;
	const gchar *auid;
	gchar *new_auid;

	for (prop = icalcomponent_get_first_property (alarm, ICAL_X_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (alarm, ICAL_X_PROPERTY)) {
		const gchar *xname;

		xname = icalproperty_get_x_name (prop);
		g_return_if_fail (xname != NULL);

		if (strcmp (xname, EVOLUTION_ALARM_UID_PROPERTY) == 0) {
			auid = alarm_uid_from_prop (prop);
			add_alarm (comp, alarm, auid);
			return;
		}
	}

	/* The component has no alarm UID property, so we create one. */

	new_auid = e_util_generate_uid ();
	auid = set_alarm_uid (alarm, new_auid);
	g_free (new_auid);

	add_alarm (comp, alarm, auid);
}

/* Scans an icalcomponent for its properties so that we can provide
 * random-access to them.  It also builds a hash table of the component's alarm
 * subcomponents.
 */
static void
scan_icalcomponent (ECalComponent *comp)
{
	ECalComponentPrivate *priv;
	icalproperty *prop;
	icalcompiter iter;

	priv = comp->priv;

	g_return_if_fail (priv->icalcomp != NULL);

	/* Scan properties */

	for (prop = icalcomponent_get_first_property (priv->icalcomp, ICAL_ANY_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (priv->icalcomp, ICAL_ANY_PROPERTY))
		scan_property (comp, prop);

	/* Scan subcomponents */

	for (iter = icalcomponent_begin_component (priv->icalcomp, ICAL_VALARM_COMPONENT);
	     icalcompiter_deref (&iter) != NULL;
	     icalcompiter_next (&iter)) {
		icalcomponent *subcomp;

		subcomp = icalcompiter_deref (&iter);
		scan_alarm (comp, subcomp);
	}
}

/* Ensures that the mandatory calendar component properties (uid, dtstamp) do
 * exist.  If they don't exist, it creates them automatically.
 */
static void
ensure_mandatory_properties (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!priv->uid) {
		gchar *uid;

		uid = e_util_generate_uid ();
		priv->uid = icalproperty_new_uid (uid);
		g_free (uid);

		icalcomponent_add_property (priv->icalcomp, priv->uid);
	}

	if (!priv->dtstamp) {
		struct icaltimetype t;

		t = icaltime_current_time_with_zone (icaltimezone_get_utc_timezone ());

		priv->dtstamp = icalproperty_new_dtstamp (t);
		icalcomponent_add_property (priv->icalcomp, priv->dtstamp);
	}
}

/**
 * e_cal_component_set_new_vtype:
 * @comp: A calendar component object.
 * @type: Type of calendar component to create.
 *
 * Clears any existing component data from a calendar component object and
 * creates a new #icalcomponent of the specified type for it.  The only property
 * that will be set in the new component will be its unique identifier.
 **/
void
e_cal_component_set_new_vtype (ECalComponent *comp,
                               ECalComponentVType type)
{
	ECalComponentPrivate *priv;
	icalcomponent *icalcomp;
	icalcomponent_kind kind;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;

	free_icalcomponent (comp, TRUE);

	if (type == E_CAL_COMPONENT_NO_TYPE)
		return;

	/* Figure out the kind and create the icalcomponent */

	switch (type) {
	case E_CAL_COMPONENT_EVENT:
		kind = ICAL_VEVENT_COMPONENT;
		break;

	case E_CAL_COMPONENT_TODO:
		kind = ICAL_VTODO_COMPONENT;
		break;

	case E_CAL_COMPONENT_JOURNAL:
		kind = ICAL_VJOURNAL_COMPONENT;
		break;

	case E_CAL_COMPONENT_FREEBUSY:
		kind = ICAL_VFREEBUSY_COMPONENT;
		break;

	case E_CAL_COMPONENT_TIMEZONE:
		kind = ICAL_VTIMEZONE_COMPONENT;
		break;

	default:
		g_warn_if_reached ();
		kind = ICAL_NO_COMPONENT;
	}

	icalcomp = icalcomponent_new (kind);
	if (!icalcomp) {
		g_message ("e_cal_component_set_new_vtype(): Could not create the icalcomponent!");
		return;
	}

	/* Scan the component to build our mapping table */

	priv->icalcomp = icalcomp;
	scan_icalcomponent (comp);

	/* Add missing stuff */

	ensure_mandatory_properties (comp);
}

/**
 * e_cal_component_set_icalcomponent:
 * @comp: A calendar component object.
 * @icalcomp: (type long): An #icalcomponent.
 *
 * Sets the contents of a calendar component object from an #icalcomponent
 * structure.  If the @comp already had an #icalcomponent set into it, it will
 * will be freed automatically if the #icalcomponent does not have a parent
 * component itself.
 *
 * Supported component types are VEVENT, VTODO, VJOURNAL, VFREEBUSY, and VTIMEZONE.
 *
 * Returns: TRUE on success, FALSE if @icalcomp is an unsupported component
 * type.
 **/
gboolean
e_cal_component_set_icalcomponent (ECalComponent *comp,
                                   icalcomponent *icalcomp)
{
	ECalComponentPrivate *priv;
	icalcomponent_kind kind;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;

	if (priv->icalcomp == icalcomp)
		return TRUE;

	free_icalcomponent (comp, TRUE);

	if (!icalcomp) {
		priv->icalcomp = NULL;
		return TRUE;
	}

	kind = icalcomponent_isa (icalcomp);

	if (!(kind == ICAL_VEVENT_COMPONENT
	      || kind == ICAL_VTODO_COMPONENT
	      || kind == ICAL_VJOURNAL_COMPONENT
	      || kind == ICAL_VFREEBUSY_COMPONENT
	      || kind == ICAL_VTIMEZONE_COMPONENT))
		return FALSE;

	priv->icalcomp = icalcomp;

	scan_icalcomponent (comp);
	ensure_mandatory_properties (comp);

	return TRUE;
}

/**
 * e_cal_component_get_icalcomponent:
 * @comp: A calendar component object.
 *
 * Queries the #icalcomponent structure that a calendar component object is
 * wrapping.
 *
 * Returns: An #icalcomponent structure, or NULL if the @comp has no
 * #icalcomponent set to it.
 **/
icalcomponent *
e_cal_component_get_icalcomponent (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	priv = comp->priv;

	return priv->icalcomp;
}

/**
 * e_cal_component_rescan:
 * @comp: A calendar component object.
 *
 * Rescans the #icalcomponent being wrapped by the given calendar component. This
 * would replace any value that was changed in the wrapped #icalcomponent.
 */
void
e_cal_component_rescan (ECalComponent *comp)
{
	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	/* Clear everything out */
	free_icalcomponent (comp, FALSE);

	/* Rescan */
	scan_icalcomponent (comp);
	ensure_mandatory_properties (comp);
}

/**
 * e_cal_component_strip_errors:
 * @comp: A calendar component object.
 *
 * Strips all error messages from the calendar component. Those error messages are
 * added to the iCalendar string representation whenever an invalid is used for
 * one of its fields.
 */
void
e_cal_component_strip_errors (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;

	icalcomponent_strip_errors (priv->icalcomp);
}

/**
 * e_cal_component_get_vtype:
 * @comp: A calendar component object.
 *
 * Queries the type of a calendar component object.
 *
 * Returns: The type of the component, as defined by RFC 2445.
 **/
ECalComponentVType
e_cal_component_get_vtype (ECalComponent *comp)
{
	ECalComponentPrivate *priv;
	icalcomponent_kind kind;

	g_return_val_if_fail (comp != NULL, E_CAL_COMPONENT_NO_TYPE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), E_CAL_COMPONENT_NO_TYPE);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, E_CAL_COMPONENT_NO_TYPE);

	kind = icalcomponent_isa (priv->icalcomp);
	switch (kind) {
	case ICAL_VEVENT_COMPONENT:
		return E_CAL_COMPONENT_EVENT;

	case ICAL_VTODO_COMPONENT:
		return E_CAL_COMPONENT_TODO;

	case ICAL_VJOURNAL_COMPONENT:
		return E_CAL_COMPONENT_JOURNAL;

	case ICAL_VFREEBUSY_COMPONENT:
		return E_CAL_COMPONENT_FREEBUSY;

	case ICAL_VTIMEZONE_COMPONENT:
		return E_CAL_COMPONENT_TIMEZONE;

	default:
		/* We should have been loaded with a supported type! */
		g_warn_if_reached ();
		return E_CAL_COMPONENT_NO_TYPE;
	}
}

/**
 * e_cal_component_get_as_string:
 * @comp: A calendar component.
 *
 * Gets the iCalendar string representation of a calendar component.  You should
 * call e_cal_component_commit_sequence() before this function to ensure that the
 * component's sequence number is consistent with the state of the object.
 *
 * Returns: String representation of the calendar component according to
 * RFC 2445.
 **/
gchar *
e_cal_component_get_as_string (ECalComponent *comp)
{
	ECalComponentPrivate *priv;
	gchar *str;

	g_return_val_if_fail (comp != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, NULL);

	/* Ensure that the user has committed the new SEQUENCE */
	g_return_val_if_fail (priv->need_sequence_inc == FALSE, NULL);

	str = icalcomponent_as_ical_string_r (priv->icalcomp);

	return str;
}

/* Used from g_hash_table_foreach(); ensures that an alarm subcomponent
 * has the mandatory properties it needs.
 */
static void
ensure_alarm_properties_cb (gpointer key,
                            gpointer value,
                            gpointer data)
{
	ECalComponent *comp;
	ECalComponentPrivate *priv;
	icalcomponent *alarm;
	icalproperty *prop;
	enum icalproperty_action action;
	const gchar *str;

	alarm = value;

	comp = E_CAL_COMPONENT (data);
	priv = comp->priv;

	prop = icalcomponent_get_first_property (alarm, ICAL_ACTION_PROPERTY);
	if (!prop)
		return;

	action = icalproperty_get_action (prop);

	switch (action) {
	case ICAL_ACTION_DISPLAY:
		/* Ensure we have a DESCRIPTION property */
		prop = icalcomponent_get_first_property (alarm, ICAL_DESCRIPTION_PROPERTY);
		if (prop) {
			if (priv->summary.prop) {
				icalproperty *xprop;

				xprop = icalcomponent_get_first_property (alarm, ICAL_X_PROPERTY);
				while (xprop) {
					str = icalproperty_get_x_name (xprop);
					if (!strcmp (str, "X-EVOLUTION-NEEDS-DESCRIPTION")) {
						icalproperty_set_description (prop, icalproperty_get_summary (priv->summary.prop));

						icalcomponent_remove_property (alarm, xprop);
						icalproperty_free (xprop);
						break;
					}

					xprop = icalcomponent_get_next_property (alarm, ICAL_X_PROPERTY);
				}

				break;
			}
		}

		if (!priv->summary.prop) {
			str = _("Untitled appointment");

			/* add the X-EVOLUTION-NEEDS-DESCRIPTION property */
			prop = icalproperty_new_x ("1");
			icalproperty_set_x_name (prop, "X-EVOLUTION-NEEDS-DESCRIPTION");
			icalcomponent_add_property (alarm, prop);
		} else
			str = icalproperty_get_summary (priv->summary.prop);

		prop = icalproperty_new_description (str);
		icalcomponent_add_property (alarm, prop);

		break;

	default:
		break;
		/* FIXME: add other action types here */
	}
}

/* Ensures that alarm subcomponents have the mandatory properties they need,
 * even when clients may not have set them properly.
 */
static void
ensure_alarm_properties (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	priv = comp->priv;

	g_hash_table_foreach (priv->alarm_uid_hash, ensure_alarm_properties_cb, comp);
}

/**
 * e_cal_component_commit_sequence:
 * @comp: A calendar component object.
 *
 * Increments the sequence number property in a calendar component object if it
 * needs it.  This needs to be done when any of a number of properties listed in
 * RFC 2445 change values, such as the start and end dates of a component.
 *
 * This function must be called before calling e_cal_component_get_as_string() to
 * ensure that the component is fully consistent.
 **/
void
e_cal_component_commit_sequence (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	ensure_alarm_properties (comp);

	if (!priv->need_sequence_inc)
		return;

	if (priv->sequence) {
		gint seq;

		seq = icalproperty_get_sequence (priv->sequence);
		icalproperty_set_sequence (priv->sequence, seq + 1);
	} else {
		/* The component had no SEQUENCE property, so assume that the
		 * default would have been zero.  Since it needed incrementing
		 * anyways, we use a value of 1 here.
		 */
		priv->sequence = icalproperty_new_sequence (1);
		icalcomponent_add_property (priv->icalcomp, priv->sequence);
	}

	priv->need_sequence_inc = FALSE;
}

/**
 * e_cal_component_abort_sequence:
 * @comp: A calendar component object.
 *
 * Aborts the sequence change needed in the given calendar component,
 * which means it will not require a sequence commit (via
 * e_cal_component_commit_sequence()) even if the changes done require a
 * sequence increment.
 */
void
e_cal_component_abort_sequence (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;

	priv->need_sequence_inc = FALSE;
}

/**
 * e_cal_component_get_id:
 * @comp: A calendar component object.
 *
 * Get the ID of the component as a #ECalComponentId.  The return value should
 * be freed with e_cal_component_free_id() when you have finished with it.
 *
 * Returns: the id of the component
 */
ECalComponentId *
e_cal_component_get_id (ECalComponent *comp)
{
	ECalComponentPrivate *priv;
	ECalComponentId *id = NULL;

	g_return_val_if_fail (comp != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, NULL);

	id = g_new0 (ECalComponentId, 1);
	id->uid = g_strdup (icalproperty_get_uid (priv->uid));
	id->rid = e_cal_component_get_recurid_as_string (comp);

	return id;
}

/**
 * e_cal_component_get_uid:
 * @comp: A calendar component object.
 * @uid: (out) (transfer none): Return value for the UID string.
 *
 * Queries the unique identifier of a calendar component object.
 **/
void
e_cal_component_get_uid (ECalComponent *comp,
                         const gchar **uid)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (uid != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	/* This MUST exist, since we ensured that it did */
	g_return_if_fail (priv->uid != NULL);

	*uid = icalproperty_get_uid (priv->uid);
}

/**
 * e_cal_component_set_uid:
 * @comp: A calendar component object.
 * @uid: Unique identifier.
 *
 * Sets the unique identifier string of a calendar component object.
 **/
void
e_cal_component_set_uid (ECalComponent *comp,
                         const gchar *uid)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (uid != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	/* This MUST exist, since we ensured that it did */
	g_return_if_fail (priv->uid != NULL);

	icalproperty_set_uid (priv->uid, (gchar *) uid);
}

static gboolean
case_contains (const gchar *where,
               const gchar *what)
{
	gchar *lwhere, *lwhat;
	gboolean res = FALSE;

	if (!where || !what) {
		return FALSE;
	}

	lwhere = g_ascii_strdown (where, -1);
	lwhat = g_ascii_strdown (what, -1);

	res = lwhere && lwhat && strstr (lwhere, lwhat) != NULL;

	g_free (lwhat);
	g_free (lwhere);

	return res;
}

/* Gets a text list value */
static void
get_attachment_list (ECalComponent *comp,
                     GSList *attachment_list,
                     GSList **al)
{
	GSList *l;
	gint index;

	*al = NULL;

	if (!attachment_list)
		return;

	for (index = 0, l = attachment_list; l; l = l->next, index++) {
		struct attachment *attachment;
		gchar *buf = NULL;

		attachment = l->data;
		g_return_if_fail (attachment->attach != NULL);

		if (icalattach_get_is_url (attachment->attach)) {
			const gchar *data;
			gsize buf_size;

			/* FIXME : this ref count is screwed up
			 * These structures are being leaked.
			 */
			icalattach_ref (attachment->attach);
			data = icalattach_get_url (attachment->attach);
			buf_size = strlen (data);
			buf = g_malloc0 (buf_size + 1);
			icalvalue_decode_ical_string (data, buf, buf_size);
		} else if (attachment->prop) {
			if (!attachment->temporary_filename) {
				icalparameter *encoding_par = icalproperty_get_first_parameter (attachment->prop, ICAL_ENCODING_PARAMETER);
				if (encoding_par) {
					gchar *str_value = icalproperty_get_value_as_string_r (attachment->prop);

					if (str_value) {
						icalparameter_encoding encoding = icalparameter_get_encoding (encoding_par);
						guint8 *data = NULL;
						gsize data_len = 0;

						switch (encoding) {
						case ICAL_ENCODING_8BIT:
							data = (guint8 *) str_value;
							data_len = strlen (str_value);
							str_value = NULL;
							break;
						case ICAL_ENCODING_BASE64:
							data = g_base64_decode (str_value, &data_len);
							break;
						default:
							break;
						}

						if (data) {
							gchar *dir, *id_str;
							ECalComponentId *id = e_cal_component_get_id (comp);

							id_str = g_strconcat (id ? id->uid : NULL, "-", id ? id->rid : NULL, NULL);
							dir = g_build_filename (e_get_user_cache_dir (), "tmp", "calendar", id_str, NULL);
							e_cal_component_free_id (id);
							g_free (id_str);

							if (g_mkdir_with_parents (dir, 0700) >= 0) {
								icalparameter *param;
								gchar *file = NULL;

								for (param = icalproperty_get_first_parameter (attachment->prop, ICAL_X_PARAMETER);
								     param && !file;
								     param = icalproperty_get_next_parameter (attachment->prop, ICAL_X_PARAMETER)) {
									if (case_contains (icalparameter_get_xname (param), "NAME") && icalparameter_get_xvalue (param) && *icalparameter_get_xvalue (param))
										file = g_strdup (icalparameter_get_xvalue (param));
								}

								if (!file)
									file = g_strdup_printf ("%d.dat", index);

								attachment->temporary_filename = g_build_filename (dir, file, NULL);
								if (!g_file_set_contents (attachment->temporary_filename, (const gchar *) data, data_len, NULL)) {
									g_free (attachment->temporary_filename);
									attachment->temporary_filename = NULL;
								}
							}

							g_free (dir);
						}

						g_free (str_value);
						g_free (data);
					}
				}
			}

			if (attachment->temporary_filename)
				buf = g_filename_to_uri (attachment->temporary_filename, NULL, NULL);
		}

		if (buf)
			*al = g_slist_prepend (*al, buf);
	}

	*al = g_slist_reverse (*al);
}

static void
set_attachment_list (icalcomponent *icalcomp,
                     GSList **attachment_list,
                     GSList *al)
{
	GSList *l;

	/* Remove old attachments */

	if (*attachment_list) {
		for (l = *attachment_list; l; l = l->next) {
			struct attachment *attachment;

			attachment = l->data;
			g_return_if_fail (attachment->prop != NULL);
			g_return_if_fail (attachment->attach != NULL);

			icalcomponent_remove_property (icalcomp, attachment->prop);
			free_attachment (attachment);
		}

		g_slist_free (*attachment_list);
		*attachment_list = NULL;
	}
	/* Add in new attachments */

	for (l = al; l; l = l->next) {
		struct attachment *attachment;
		gsize buf_size;
		gchar *buf;

		attachment = g_new0 (struct attachment, 1);
		buf_size = 2 * strlen ((gchar *) l->data);
		buf = g_malloc0 (buf_size);
		icalvalue_encode_ical_string (l->data, buf, buf_size);
		attachment->attach = icalattach_new_from_url ((gchar *) buf);
		attachment->prop = icalproperty_new_attach (attachment->attach);
		icalcomponent_add_property (icalcomp, attachment->prop);
		g_free (buf);
		*attachment_list = g_slist_prepend (*attachment_list, attachment);
	}

	*attachment_list = g_slist_reverse (*attachment_list);
}

/**
 * e_cal_component_get_attachment_list:
 * @comp: A calendar component object
 * @attachment_list: (out) (transfer full) (element-type utf8): Return list of
 * URIs to attachments
 *
 * Queries the attachment properties of the calendar component object. When done,
 * the @attachment_list should be freed by calling g_slist_free().
 **/
void
e_cal_component_get_attachment_list (ECalComponent *comp,
                                     GSList **attachment_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (attachment_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_attachment_list (comp, priv->attachment_list, attachment_list);
}

/**
 * e_cal_component_set_attachment_list:
 * @comp: A calendar component object
 * @attachment_list: (element-type utf8): list of URIs to attachment pointers
 *
 * This currently handles only attachments that are URIs
 * in the file system - not inline binaries.
 *
 * Sets the attachments of a calendar component object
 **/
void
e_cal_component_set_attachment_list (ECalComponent *comp,
                                     GSList *attachment_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_attachment_list (priv->icalcomp, &priv->attachment_list, attachment_list);
}

/**
 * e_cal_component_has_attachments:
 * @comp: A calendar component object.
 *
 * Queries the component to see if it has attachments.
 *
 * Returns: TRUE if there are attachments, FALSE otherwise.
 */
gboolean
e_cal_component_has_attachments (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;

	if (g_slist_length (priv->attachment_list) > 0)
		return TRUE;

	return FALSE;
}

/**
 * e_cal_component_get_num_attachments:
 * @comp: A calendar component object.
 *
 * Get the number of attachments to this calendar component object.
 *
 * Returns: the number of attachments.
 */
gint
e_cal_component_get_num_attachments (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, 0);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), 0);

	priv = comp->priv;

	return g_slist_length (priv->attachment_list) > 0;

}

/**
 * e_cal_component_get_categories:
 * @comp: A calendar component object.
 * @categories: (out) (transfer none): Return holder for the categories.
 *
 * Queries the categories of the given calendar component. The categories
 * are returned in the @categories argument, which, on success, will contain
 * a comma-separated list of all categories set in the component.
 **/
void
e_cal_component_get_categories (ECalComponent *comp,
                                const gchar **categories)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (categories != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (priv->categories_str)
		*categories = priv->categories_str->str;
	else
		*categories = NULL;
}

static void
remove_all_categories (icalcomponent *icalcomp)
{
	icalproperty *prop, *to_remove;

	g_return_if_fail (icalcomp != NULL);

	prop = icalcomponent_get_first_property (icalcomp, ICAL_CATEGORIES_PROPERTY);
	while (prop) {
		to_remove = prop;
		prop = icalcomponent_get_next_property (icalcomp, ICAL_CATEGORIES_PROPERTY);

		icalcomponent_remove_property (icalcomp, to_remove);
		icalproperty_free (to_remove);
	}
}

/**
 * e_cal_component_set_categories:
 * @comp: A calendar component object.
 * @categories: Comma-separated list of categories.
 *
 * Sets the list of categories for a calendar component.
 **/
void
e_cal_component_set_categories (ECalComponent *comp,
                                const gchar *categories)
{
	ECalComponentPrivate *priv;
	icalproperty *prop;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!categories || !(*categories)) {
		remove_all_categories (priv->icalcomp);
		if (priv->categories_str) {
			g_string_free (priv->categories_str, TRUE);
			priv->categories_str = NULL;
		}

		return;
	}

	remove_all_categories (priv->icalcomp);
	prop = icalproperty_new_categories (categories);
	icalcomponent_add_property (priv->icalcomp, prop);

	if (priv->categories_str)
		g_string_free (priv->categories_str, TRUE);
	priv->categories_str = g_string_new (categories);
}

/**
 * e_cal_component_get_categories_list:
 * @comp: A calendar component object.
 * @categ_list: (out) (transfer full) (element-type utf8): Return value for the
 * list of strings, where each string is a category. This should be freed using
 * e_cal_component_free_categories_list().
 *
 * Queries the list of categories of a calendar component object.  Each element
 * in the returned categ_list is a string with the corresponding category.
 **/
void
e_cal_component_get_categories_list (ECalComponent *comp,
                                     GSList **categ_list)
{
	ECalComponentPrivate *priv;
	icalproperty *prop;
	const gchar *categories;
	const gchar *p;
	const gchar *cat_start;
	gchar *str;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (categ_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!priv->categories_str) {
		*categ_list = NULL;
		return;
	}

	*categ_list = NULL;

	for (prop = icalcomponent_get_first_property (priv->icalcomp, ICAL_CATEGORIES_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (priv->icalcomp, ICAL_CATEGORIES_PROPERTY)) {
		categories = icalproperty_get_categories (prop);
		g_return_if_fail (categories != NULL);

		cat_start = categories;

		for (p = categories; *p; p++) {
			if (*p == ',') {
				str = g_strndup (cat_start, p - cat_start);
				*categ_list = g_slist_prepend (*categ_list, str);

				cat_start = p + 1;
			}
		}

		str = g_strndup (cat_start, p - cat_start);
		*categ_list = g_slist_prepend (*categ_list, str);
	}

	*categ_list = g_slist_reverse (*categ_list);
}

/* Creates a comma-delimited string of categories */
static gchar *
stringify_categories (GSList *categ_list)
{
	GString *s;
	GSList *l;
	gchar *str;

	s = g_string_new (NULL);

	for (l = categ_list; l; l = l->next) {
		g_string_append (s, l->data);

		if (l->next != NULL)
			g_string_append (s, ",");
	}

	str = s->str;
	g_string_free (s, FALSE);

	return str;
}

/**
 * e_cal_component_set_categories_list:
 * @comp: A calendar component object.
 * @categ_list: (element-type utf8): List of strings, one for each category.
 *
 * Sets the list of categories of a calendar component object.
 **/
void
e_cal_component_set_categories_list (ECalComponent *comp,
                                     GSList *categ_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!categ_list) {
		e_cal_component_set_categories (comp, NULL);
	} else {
		gchar *categories_str;

		/* Create a single string of categories */
		categories_str = stringify_categories (categ_list);

		/* Set the categories */
		e_cal_component_set_categories (comp, categories_str);
		g_free (categories_str);
	}
}

/**
 * e_cal_component_get_classification:
 * @comp: A calendar component object.
 * @classif: (out): Return value for the classification.
 *
 * Queries the classification of a calendar component object.  If the
 * classification property is not set on this component, this function returns
 * #E_CAL_COMPONENT_CLASS_NONE.
 **/
void
e_cal_component_get_classification (ECalComponent *comp,
                                    ECalComponentClassification *classif)
{
	ECalComponentPrivate *priv;
	icalproperty_class class;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (classif != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!priv->classification) {
		*classif = E_CAL_COMPONENT_CLASS_NONE;
		return;
	}

	class = icalproperty_get_class (priv->classification);

	switch (class)
	{
	case ICAL_CLASS_PUBLIC:
	  *classif = E_CAL_COMPONENT_CLASS_PUBLIC;
	  break;
	case ICAL_CLASS_PRIVATE:
	  *classif = E_CAL_COMPONENT_CLASS_PRIVATE;
	  break;
	case ICAL_CLASS_CONFIDENTIAL:
	  *classif = E_CAL_COMPONENT_CLASS_CONFIDENTIAL;
	  break;
	default:
	  *classif = E_CAL_COMPONENT_CLASS_UNKNOWN;
	  break;
	}
}

/**
 * e_cal_component_set_classification:
 * @comp: A calendar component object.
 * @classif: Classification to use.
 *
 * Sets the classification property of a calendar component object.  To unset
 * the property, specify E_CAL_COMPONENT_CLASS_NONE for @classif.
 **/
void
e_cal_component_set_classification (ECalComponent *comp,
                                    ECalComponentClassification classif)
{
	ECalComponentPrivate *priv;
	icalproperty_class class;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (classif != E_CAL_COMPONENT_CLASS_UNKNOWN);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (classif == E_CAL_COMPONENT_CLASS_NONE) {
		if (priv->classification) {
			icalcomponent_remove_property (priv->icalcomp, priv->classification);
			icalproperty_free (priv->classification);
			priv->classification = NULL;
		}

		return;
	}

	switch (classif) {
	case E_CAL_COMPONENT_CLASS_PUBLIC:
	  class = ICAL_CLASS_PUBLIC;
		break;

	case E_CAL_COMPONENT_CLASS_PRIVATE:
	  class = ICAL_CLASS_PRIVATE;
		break;

	case E_CAL_COMPONENT_CLASS_CONFIDENTIAL:
	  class = ICAL_CLASS_CONFIDENTIAL;
		break;

	default:
		g_warn_if_reached ();
		class = ICAL_CLASS_NONE;
	}

	if (priv->classification)
		icalproperty_set_class (priv->classification, class);
	else {
		priv->classification = icalproperty_new_class (class);
		icalcomponent_add_property (priv->icalcomp, priv->classification);
	}
}

/* Gets a text list value */
static void
get_text_list (GSList *text_list,
               const gchar *(* get_prop_func) (const icalproperty *prop),
               GSList **tl)
{
	GSList *l;

	*tl = NULL;

	if (!text_list)
		return;

	for (l = text_list; l; l = l->next) {
		struct text *text;
		ECalComponentText *t;
		const gchar *value;

		text = l->data;
		g_return_if_fail (text->prop != NULL);

		value = (* get_prop_func) (text->prop);
		/* Skip empty values */
		if (!value || !*value)
			continue;

		t = g_new (ECalComponentText, 1);
		t->value = value;

		if (text->altrep_param)
			t->altrep = icalparameter_get_altrep (text->altrep_param);
		else
			t->altrep = NULL;

		*tl = g_slist_prepend (*tl, t);
	}

	*tl = g_slist_reverse (*tl);
}

/* Sets a text list value */
static void
set_text_list (ECalComponent *comp,
               icalproperty *(* new_prop_func) (const gchar *value),
               GSList **text_list,
               GSList *tl)
{
	ECalComponentPrivate *priv;
	GSList *l;

	priv = comp->priv;

	/* Remove old texts */

	for (l = *text_list; l; l = l->next) {
		struct text *text;

		text = l->data;
		g_return_if_fail (text->prop != NULL);

		icalcomponent_remove_property (priv->icalcomp, text->prop);
		icalproperty_free (text->prop);
		g_free (text);
	}

	g_slist_free (*text_list);
	*text_list = NULL;

	/* Add in new texts */

	for (l = tl; l; l = l->next) {
		ECalComponentText *t;
		struct text *text;

		t = l->data;
		g_return_if_fail (t->value != NULL);

		text = g_new (struct text, 1);

		text->prop = (* new_prop_func) ((gchar *) t->value);
		icalcomponent_add_property (priv->icalcomp, text->prop);

		if (t->altrep) {
			text->altrep_param = icalparameter_new_altrep ((gchar *) t->altrep);
			icalproperty_add_parameter (text->prop, text->altrep_param);
		} else
			text->altrep_param = NULL;

		*text_list = g_slist_prepend (*text_list, text);
	}

	*text_list = g_slist_reverse (*text_list);
}

/**
 * e_cal_component_get_comment_list:
 * @comp: A calendar component object.
 * @text_list: (out) (transfer full) (element-type ECalComponentText): Return
 * value for the comment properties and their parameters, as a list of
 * #ECalComponentText structures.  This should be freed using the
 * e_cal_component_free_text_list() function.
 *
 * Queries the comments of a calendar component object.  The comment property can
 * appear several times inside a calendar component, and so a list of
 * #ECalComponentText is returned.
 **/
void
e_cal_component_get_comment_list (ECalComponent *comp,
                                  GSList **text_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (text_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_text_list (priv->comment_list, icalproperty_get_comment, text_list);
}

/**
 * e_cal_component_set_comment_list:
 * @comp: A calendar component object.
 * @text_list: (element-type ECalComponentText): List of #ECalComponentText
 * structures.
 *
 * Sets the comments of a calendar component object.  The comment property can
 * appear several times inside a calendar component, and so a list of
 * #ECalComponentText structures is used.
 **/
void
e_cal_component_set_comment_list (ECalComponent *comp,
                                  GSList *text_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_text_list (comp, icalproperty_new_comment, &priv->comment_list, text_list);
}

/**
 * e_cal_component_get_contact_list:
 * @comp: A calendar component object.
 * @text_list: (out) (transfer full) (element-type ECalComponentText): Return
 * value for the contact properties and their parameters, as a list of
 * #ECalComponentText structures.  This should be freed using the
 * e_cal_component_free_text_list() function.
 *
 * Queries the contact of a calendar component object.  The contact property can
 * appear several times inside a calendar component, and so a list of
 * #ECalComponentText is returned.
 **/
void
e_cal_component_get_contact_list (ECalComponent *comp,
                                  GSList **text_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (text_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_text_list (priv->contact_list, icalproperty_get_contact, text_list);
}

/**
 * e_cal_component_set_contact_list:
 * @comp: A calendar component object.
 * @text_list: (element-type ECalComponentText): List of #ECalComponentText
 * structures.
 *
 * Sets the contact of a calendar component object.  The contact property can
 * appear several times inside a calendar component, and so a list of
 * #ECalComponentText structures is used.
 **/
void
e_cal_component_set_contact_list (ECalComponent *comp,
                                  GSList *text_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_text_list (comp, icalproperty_new_contact, &priv->contact_list, text_list);
}

/* Gets a struct icaltimetype value */
static void
get_icaltimetype (icalproperty *prop,
                  struct icaltimetype (*get_prop_func) (const icalproperty *prop),
                                                        struct icaltimetype **t)
{
	if (!prop) {
		*t = NULL;
		return;
	}

	*t = g_new (struct icaltimetype, 1);
	**t = (* get_prop_func) (prop);
}

/* Sets a struct icaltimetype value */
static void
set_icaltimetype (ECalComponent *comp,
                  icalproperty **prop,
                  icalproperty *(*prop_new_func) (struct icaltimetype v),
                  void (* prop_set_func) (icalproperty *prop,
                                          struct icaltimetype v),
                  struct icaltimetype *t)
{
	ECalComponentPrivate *priv;

	priv = comp->priv;

	if (!t) {
		if (*prop) {
			icalcomponent_remove_property (priv->icalcomp, *prop);
			icalproperty_free (*prop);
			*prop = NULL;
		}

		return;
	}

	if (*prop)
		(* prop_set_func) (*prop, *t);
	else {
		*prop = (* prop_new_func) (*t);
		icalcomponent_add_property (priv->icalcomp, *prop);
	}
}

/**
 * e_cal_component_get_completed:
 * @comp: A calendar component object.
 * @t: (out): Return value for the completion date.  This should be freed using the
 * e_cal_component_free_icaltimetype() function.
 *
 * Queries the date at which a calendar compoment object was completed.
 **/
void
e_cal_component_get_completed (ECalComponent *comp,
                               struct icaltimetype **t)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (t != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_icaltimetype (priv->completed, icalproperty_get_completed, t);
}

/**
 * e_cal_component_set_completed:
 * @comp: A calendar component object.
 * @t: Value for the completion date.
 *
 * Sets the date at which a calendar component object was completed.
 **/
void
e_cal_component_set_completed (ECalComponent *comp,
                               struct icaltimetype *t)
{
	ECalComponentPrivate *priv;
	struct icaltimetype tmp_tt;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (t && t->is_date) {
		tmp_tt = *t;
		t = &tmp_tt;

		tmp_tt.is_date = 0;
		tmp_tt.hour = 0;
		tmp_tt.minute = 0;
		tmp_tt.second = 0;
		tmp_tt.zone = icaltimezone_get_utc_timezone ();
	}

	set_icaltimetype (
		comp, &priv->completed,
		icalproperty_new_completed,
		icalproperty_set_completed,
		t);
}

/**
 * e_cal_component_get_created:
 * @comp: A calendar component object.
 * @t: (out): Return value for the creation date.  This should be freed using the
 * e_cal_component_free_icaltimetype() function.
 *
 * Queries the date in which a calendar component object was created in the
 * calendar store.
 **/
void
e_cal_component_get_created (ECalComponent *comp,
                             struct icaltimetype **t)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (t != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_icaltimetype (priv->created, icalproperty_get_created, t);
}

/**
 * e_cal_component_set_created:
 * @comp: A calendar component object.
 * @t: Value for the creation date.
 *
 * Sets the date in which a calendar component object is created in the calendar
 * store.  This should only be used inside a calendar store application, i.e.
 * not by calendar user agents.
 **/
void
e_cal_component_set_created (ECalComponent *comp,
                             struct icaltimetype *t)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_icaltimetype (
		comp, &priv->created,
		icalproperty_new_created,
		icalproperty_set_created,
		t);
}

/**
 * e_cal_component_get_description_list:
 * @comp: A calendar component object.
 * @text_list: (out) (transfer full) (element-type ECalComponentText): Return
 * value for the description properties and their parameters, as a list of
 * #ECalComponentText structures.  This should be freed using the
 * e_cal_component_free_text_list() function.
 *
 * Queries the description of a calendar component object.  Journal components
 * may have more than one description, and as such this function returns a list
 * of #ECalComponentText structures.  All other types of components can have at
 * most one description.
 **/
void
e_cal_component_get_description_list (ECalComponent *comp,
                                      GSList **text_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (text_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_text_list (priv->description_list, icalproperty_get_description, text_list);
}

/**
 * e_cal_component_set_description_list:
 * @comp: A calendar component object.
 * @text_list: (element-type ECalComponentText): List of
 * #ECalComponentText structures.
 *
 * Sets the description of a calendar component object.  Journal components may
 * have more than one description, and as such this function takes in a list of
 * #ECalComponentText structures.  All other types of components can have
 * at most one description.
 **/
void
e_cal_component_set_description_list (ECalComponent *comp,
                                      GSList *text_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_text_list (comp, icalproperty_new_description, &priv->description_list, text_list);
}

/* Gets a date/time and timezone pair */
static void
get_datetime (struct datetime *datetime,
              struct icaltimetype (* get_prop_func) (const icalproperty *prop),
              ECalComponentDateTime *dt)
{
	if (datetime->prop) {
		dt->value = g_new (struct icaltimetype, 1);
		*dt->value = (* get_prop_func) (datetime->prop);
	} else
		dt->value = NULL;

	/* If the icaltimetype has is_utc set, we set "UTC" as the TZID.
	 * This makes the timezone code simpler. */
	if (datetime->tzid_param)
		dt->tzid = g_strdup (icalparameter_get_tzid (datetime->tzid_param));
	else if (dt->value && icaltime_is_utc (*dt->value))
		dt->tzid = g_strdup ("UTC");
	else
		dt->tzid = NULL;
}

/* Sets a date/time and timezone pair */
static void
set_datetime (ECalComponent *comp,
              struct datetime *datetime,
              icalproperty *(* prop_new_func) (struct icaltimetype v),
              void (* prop_set_func) (icalproperty *prop,
                                      struct icaltimetype v),
              ECalComponentDateTime *dt)
{
	ECalComponentPrivate *priv;

	priv = comp->priv;

	/* If we are setting the property to NULL (i.e. removing it), then
	 * we remove it if it exists. */
	if (!dt) {
		if (datetime->prop) {
			icalcomponent_remove_property (priv->icalcomp, datetime->prop);
			icalproperty_free (datetime->prop);

			datetime->prop = NULL;
			datetime->tzid_param = NULL;
		}

		return;
	}

	g_return_if_fail (dt->value != NULL);

	/* If the TZID is set to "UTC", we set the is_utc flag. */
	if (dt->tzid && !strcmp (dt->tzid, "UTC"))
		dt->value->zone = icaltimezone_get_utc_timezone ();
	else if (dt->value->zone == icaltimezone_get_utc_timezone ())
		dt->value->zone = NULL;

	if (datetime->prop) {
		/* make sure no VALUE property is left if not needed */
		icalproperty_remove_parameter_by_kind (datetime->prop, ICAL_VALUE_PARAMETER);

		(* prop_set_func) (datetime->prop, *dt->value);
	} else {
		datetime->prop = (* prop_new_func) (*dt->value);
		icalcomponent_add_property (priv->icalcomp, datetime->prop);
	}

	/* If the TZID is set to "UTC", we don't want to save the TZID. */
	if (dt->tzid && strcmp (dt->tzid, "UTC")) {
		g_return_if_fail (datetime->prop != NULL);

		if (datetime->tzid_param) {
			icalparameter_set_tzid (datetime->tzid_param, (gchar *) dt->tzid);
		} else {
			datetime->tzid_param = icalparameter_new_tzid ((gchar *) dt->tzid);
			icalproperty_add_parameter (datetime->prop, datetime->tzid_param);
		}
	} else if (datetime->tzid_param) {
		icalproperty_remove_parameter_by_kind (datetime->prop, ICAL_TZID_PARAMETER);
		datetime->tzid_param = NULL;
	}
}

/* This tries to get the DTSTART + DURATION for a VEVENT or VTODO. In a
 * VEVENT this is used for the DTEND if no DTEND exists, In a VTOTO it is
 * used for the DUE date if DUE doesn't exist. */
static void
e_cal_component_get_start_plus_duration (ECalComponent *comp,
                                         ECalComponentDateTime *dt)
{
	ECalComponentPrivate *priv;
	struct icaldurationtype duration;

	priv = comp->priv;

	if (!priv->duration)
		return;

	/* Get the DTSTART time. */
	get_datetime (&priv->dtstart, icalproperty_get_dtstart, dt);
	if (!dt->value)
		return;

	duration = icalproperty_get_duration (priv->duration);

	/* The DURATION shouldn't be negative, but just return DTSTART if it
	 * is, i.e. assume it is 0. */
	if (duration.is_neg)
		return;

	/* If DTSTART is a DATE value, then we need to check if the DURATION
	 * includes any hours, minutes or seconds. If it does, we need to
	 * make the DTEND/DUE a DATE-TIME value. */
	duration.days += duration.weeks * 7;
	if (dt->value->is_date) {
		if (duration.hours != 0 || duration.minutes != 0
		    || duration.seconds != 0) {
			dt->value->is_date = 0;
		}
	}

	/* Add on the DURATION. */
	icaltime_adjust (
		dt->value, duration.days, duration.hours,
		duration.minutes, duration.seconds);
}

/**
 * e_cal_component_get_dtend:
 * @comp: A calendar component object.
 * @dt: (out): Return value for the date/time end.  This should be freed with the
 * e_cal_component_free_datetime() function.
 *
 * Queries the date/time end of a calendar component object.
 **/
void
e_cal_component_get_dtend (ECalComponent *comp,
                           ECalComponentDateTime *dt)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (dt != NULL);

	dt->tzid = NULL;
	dt->value = NULL;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_datetime (&priv->dtend, icalproperty_get_dtend, dt);

	/* If we don't have a DTEND property, then we try to get DTSTART
	 * + DURATION. */
	if (!dt->value)
		e_cal_component_get_start_plus_duration (comp, dt);
}

/**
 * e_cal_component_set_dtend:
 * @comp: A calendar component object.
 * @dt: End date/time.
 *
 * Sets the date/time end property of a calendar component object.
 **/
void
e_cal_component_set_dtend (ECalComponent *comp,
                           ECalComponentDateTime *dt)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_datetime (
		comp, &priv->dtend,
		icalproperty_new_dtend,
		icalproperty_set_dtend,
		dt);

	/* Make sure we remove any existing DURATION property, as it can't be
	 * used with a DTEND. If DTEND is set to NULL, i.e. removed, we also
	 * want to remove any DURATION. */
	if (priv->duration) {
		icalcomponent_remove_property (priv->icalcomp, priv->duration);
		icalproperty_free (priv->duration);
		priv->duration = NULL;
	}

	priv->need_sequence_inc = TRUE;
}

/**
 * e_cal_component_get_dtstamp:
 * @comp: A calendar component object.
 * @t: (out): A value for the date/timestamp.
 *
 * Queries the date/timestamp property of a calendar component object, which is
 * the last time at which the object was modified by a calendar user agent.
 **/
void
e_cal_component_get_dtstamp (ECalComponent *comp,
                             struct icaltimetype *t)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (t != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	/* This MUST exist, since we ensured that it did */
	g_return_if_fail (priv->dtstamp != NULL);

	*t = icalproperty_get_dtstamp (priv->dtstamp);
}

/**
 * e_cal_component_set_dtstamp:
 * @comp: A calendar component object.
 * @t: Date/timestamp value.
 *
 * Sets the date/timestamp of a calendar component object.  This should be
 * called whenever a calendar user agent makes a change to a component's
 * properties.
 **/
void
e_cal_component_set_dtstamp (ECalComponent *comp,
                             struct icaltimetype *t)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (t != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	/* This MUST exist, since we ensured that it did */
	g_return_if_fail (priv->dtstamp != NULL);

	icalproperty_set_dtstamp (priv->dtstamp, *t);
}

/**
 * e_cal_component_get_dtstart:
 * @comp: A calendar component object.
 * @dt: (out): Return value for the date/time start.  This should be freed with the
 * e_cal_component_free_datetime() function.
 *
 * Queries the date/time start of a calendar component object.
 **/
void
e_cal_component_get_dtstart (ECalComponent *comp,
                             ECalComponentDateTime *dt)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (dt != NULL);

	dt->tzid = NULL;
	dt->value = NULL;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_datetime (&priv->dtstart, icalproperty_get_dtstart, dt);
}

/**
 * e_cal_component_set_dtstart:
 * @comp: A calendar component object.
 * @dt: Start date/time.
 *
 * Sets the date/time start property of a calendar component object.
 **/
void
e_cal_component_set_dtstart (ECalComponent *comp,
                             ECalComponentDateTime *dt)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_datetime (
		comp, &priv->dtstart,
		icalproperty_new_dtstart,
		icalproperty_set_dtstart,
		dt);

	priv->need_sequence_inc = TRUE;
}

/**
 * e_cal_component_get_due:
 * @comp: A calendar component object.
 * @dt: (out): Return value for the due date/time.  This should be freed with the
 * e_cal_component_free_datetime() function.
 *
 * Queries the due date/time of a calendar component object.
 **/
void
e_cal_component_get_due (ECalComponent *comp,
                         ECalComponentDateTime *dt)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (dt != NULL);

	dt->tzid = NULL;
	dt->value = NULL;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_datetime (&priv->due, icalproperty_get_due, dt);

	/* If we don't have a DTEND property, then we try to get DTSTART
	 * + DURATION. */
	if (!dt->value)
		e_cal_component_get_start_plus_duration (comp, dt);
}

/**
 * e_cal_component_set_due:
 * @comp: A calendar component object.
 * @dt: End date/time.
 *
 * Sets the due date/time property of a calendar component object.
 **/
void
e_cal_component_set_due (ECalComponent *comp,
                         ECalComponentDateTime *dt)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_datetime (
		comp, &priv->due,
		icalproperty_new_due,
		icalproperty_set_due,
		dt);

	/* Make sure we remove any existing DURATION property, as it can't be
	 * used with a DTEND. If DTEND is set to NULL, i.e. removed, we also
	 * want to remove any DURATION. */
	if (priv->duration) {
		icalcomponent_remove_property (priv->icalcomp, priv->duration);
		icalproperty_free (priv->duration);
		priv->duration = NULL;
	}

	priv->need_sequence_inc = TRUE;
}

/* Builds a list of ECalComponentPeriod structures based on a list of icalproperties */
static void
get_period_list (GSList *period_list,
                 struct icaldatetimeperiodtype (* get_prop_func) (const icalproperty *prop),
                 GSList **list)
{
	GSList *l;

	*list = NULL;

	if (!period_list)
		return;

	for (l = period_list; l; l = l->next) {
		struct period *period;
		ECalComponentPeriod *p;
		struct icaldatetimeperiodtype ip;

		period = l->data;
		g_return_if_fail (period->prop != NULL);

		p = g_new (ECalComponentPeriod, 1);

		/* Get start and end/duration */
		ip = (* get_prop_func) (period->prop);

		/* Get value parameter */
		if (period->value_param) {
			icalparameter_value value_type;

			value_type = icalparameter_get_value (period->value_param);

			if (value_type == ICAL_VALUE_DATE || value_type == ICAL_VALUE_DATETIME)
				p->type = E_CAL_COMPONENT_PERIOD_DATETIME;
			else if (value_type == ICAL_VALUE_DURATION)
				p->type = E_CAL_COMPONENT_PERIOD_DURATION;
			else if (value_type == ICAL_VALUE_PERIOD) {
				if (icaldurationtype_is_null_duration (ip.period.duration) || icaldurationtype_is_bad_duration (ip.period.duration))
					p->type = E_CAL_COMPONENT_PERIOD_DATETIME;
				else
					p->type = E_CAL_COMPONENT_PERIOD_DURATION;
			} else {
				g_message (
					"get_period_list(): Unknown value for period %d; "
					"using DATETIME", value_type);
				p->type = E_CAL_COMPONENT_PERIOD_DATETIME;
			}
		} else
			p->type = E_CAL_COMPONENT_PERIOD_DATETIME;

		p->start = ip.period.start;

		if (p->type == E_CAL_COMPONENT_PERIOD_DATETIME)
			p->u.end = ip.period.end;
		else if (p->type == E_CAL_COMPONENT_PERIOD_DURATION)
			p->u.duration = ip.period.duration;
		else
			g_return_if_reached ();

		/* Put in list */

		*list = g_slist_prepend (*list, p);
	}

	*list = g_slist_reverse (*list);
}

/* Sets a period list value */
static void
set_period_list (ECalComponent *comp,
                 icalproperty *(* new_prop_func) (struct icaldatetimeperiodtype period),
                 GSList **period_list,
                 GSList *pl)
{
	ECalComponentPrivate *priv;
	GSList *l;

	priv = comp->priv;

	/* Remove old periods */

	for (l = *period_list; l; l = l->next) {
		struct period *period;

		period = l->data;
		g_return_if_fail (period->prop != NULL);

		icalcomponent_remove_property (priv->icalcomp, period->prop);
		icalproperty_free (period->prop);
		g_free (period);
	}

	g_slist_free (*period_list);
	*period_list = NULL;

	/* Add in new periods */

	for (l = pl; l; l = l->next) {
		ECalComponentPeriod *p;
		struct period *period;
		struct icaldatetimeperiodtype ip = {};
		icalparameter_value value_type;

		g_return_if_fail (l->data != NULL);
		p = l->data;

		/* Create libical value */

		ip.period.start = p->start;

		if (p->type == E_CAL_COMPONENT_PERIOD_DATETIME) {
			value_type = ICAL_VALUE_DATETIME;
			ip.period.end = p->u.end;
		} else if (p->type == E_CAL_COMPONENT_PERIOD_DURATION) {
			value_type = ICAL_VALUE_DURATION;
			ip.period.duration = p->u.duration;
		} else {
			g_return_if_reached ();
		}

		/* Create property */

		period = g_new (struct period, 1);

		period->prop = (* new_prop_func) (ip);
		period->value_param = icalparameter_new_value (value_type);
		icalproperty_add_parameter (period->prop, period->value_param);

		/* Add to list */

		*period_list = g_slist_prepend (*period_list, period);
	}

	*period_list = g_slist_reverse (*period_list);
}

/**
 * e_cal_component_get_exdate_list:
 * @comp: A calendar component object.
 * @exdate_list: (out) (transfer full) (element-type ECalComponentDateTime):
 * Return value for the list of exception dates, as a list of
 * #ECalComponentDateTime structures.  This should be freed using the
 * e_cal_component_free_exdate_list() function.
 *
 * Queries the list of exception date properties in a calendar component object.
 **/
void
e_cal_component_get_exdate_list (ECalComponent *comp,
                                 GSList **exdate_list)
{
	ECalComponentPrivate *priv;
	GSList *l;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (exdate_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	*exdate_list = NULL;

	for (l = priv->exdate_list; l; l = l->next) {
		struct datetime *dt;
		ECalComponentDateTime *cdt;

		dt = l->data;

		cdt = g_new (ECalComponentDateTime, 1);
		cdt->value = g_new (struct icaltimetype, 1);

		*cdt->value = icalproperty_get_exdate (dt->prop);

		if (dt->tzid_param)
			cdt->tzid = g_strdup (icalparameter_get_tzid (dt->tzid_param));
		else
			cdt->tzid = NULL;

		*exdate_list = g_slist_prepend (*exdate_list, cdt);
	}

	*exdate_list = g_slist_reverse (*exdate_list);
}

/**
 * e_cal_component_set_exdate_list:
 * @comp: A calendar component object.
 * @exdate_list: (element-type ECalComponentDateTime): List of
 * #ECalComponentDateTime structures.
 *
 * Sets the list of exception dates in a calendar component object.
 **/
void
e_cal_component_set_exdate_list (ECalComponent *comp,
                                 GSList *exdate_list)
{
	ECalComponentPrivate *priv;
	GSList *l;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	/* Remove old exception dates */

	for (l = priv->exdate_list; l; l = l->next) {
		struct datetime *dt;

		dt = l->data;

		/* Removing the DATE or DATE-TIME property will also remove
		 * any TZID parameter. */
		icalcomponent_remove_property (priv->icalcomp, dt->prop);
		icalproperty_free (dt->prop);
		g_free (dt);
	}

	g_slist_free (priv->exdate_list);
	priv->exdate_list = NULL;

	/* Add in new exception dates */

	for (l = exdate_list; l; l = l->next) {
		ECalComponentDateTime *cdt;
		struct datetime *dt;

		g_return_if_fail (l->data != NULL);
		cdt = l->data;

		g_return_if_fail (cdt->value != NULL);

		dt = g_new (struct datetime, 1);
		dt->prop = icalproperty_new_exdate (*cdt->value);

		if (cdt->tzid) {
			dt->tzid_param = icalparameter_new_tzid ((gchar *) cdt->tzid);
			icalproperty_add_parameter (dt->prop, dt->tzid_param);
		} else
			dt->tzid_param = NULL;

		icalcomponent_add_property (priv->icalcomp, dt->prop);
		priv->exdate_list = g_slist_prepend (priv->exdate_list, dt);
	}

	priv->exdate_list = g_slist_reverse (priv->exdate_list);

	priv->need_sequence_inc = TRUE;
}

/**
 * e_cal_component_has_exdates:
 * @comp: A calendar component object.
 *
 * Queries whether a calendar component object has any exception dates defined
 * for it.
 *
 * Returns: TRUE if the component has exception dates, FALSE otherwise.
 **/
gboolean
e_cal_component_has_exdates (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, FALSE);

	return (priv->exdate_list != NULL);
}

/* Gets a list of recurrence rules */
static void
get_recur_list (GSList *recur_list,
                struct icalrecurrencetype (* get_prop_func) (const icalproperty *prop),
                GSList **list)
{
	GSList *l;

	*list = NULL;

	for (l = recur_list; l; l = l->next) {
		icalproperty *prop;
		struct icalrecurrencetype *r;

		prop = l->data;

		r = g_new (struct icalrecurrencetype, 1);
		*r = (* get_prop_func) (prop);

		*list = g_slist_prepend (*list, r);
	}

	*list = g_slist_reverse (*list);
}

/* Sets a list of recurrence rules */
static void
set_recur_list (ECalComponent *comp,
                icalproperty *(* new_prop_func) (struct icalrecurrencetype recur),
                GSList **recur_list,
                GSList *rl)
{
	ECalComponentPrivate *priv;
	GSList *l;

	priv = comp->priv;

	/* Remove old recurrences */

	for (l = *recur_list; l; l = l->next) {
		icalproperty *prop;

		prop = l->data;
		icalcomponent_remove_property (priv->icalcomp, prop);
		icalproperty_free (prop);
	}

	g_slist_free (*recur_list);
	*recur_list = NULL;

	/* Add in new recurrences */

	for (l = rl; l; l = l->next) {
		icalproperty *prop;
		struct icalrecurrencetype *recur;

		g_return_if_fail (l->data != NULL);
		recur = l->data;

		prop = (* new_prop_func) (*recur);
		icalcomponent_add_property (priv->icalcomp, prop);

		*recur_list = g_slist_prepend (*recur_list, prop);
	}

	*recur_list = g_slist_reverse (*recur_list);
}

/**
 * e_cal_component_get_exrule_list:
 * @comp: A calendar component object.
 * @recur_list: (out) (element-type icalrecurrencetype) (transfer full): List of
 * exception rules as struct #icalrecurrencetype structures.  This should be
 * freed using the e_cal_component_free_recur_list() function.
 *
 * Queries the list of exception rule properties of a calendar component
 * object.
 **/
void
e_cal_component_get_exrule_list (ECalComponent *comp,
                                 GSList **recur_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (recur_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_recur_list (priv->exrule_list, icalproperty_get_exrule, recur_list);
}

/**
 * e_cal_component_get_exrule_property_list:
 * @comp: A calendar component object.
 * @recur_list: (out) (transfer none) (element-type icalrecurrencetype):
 *
 * Queries the list of exception rule properties of a calendar component object.
 *
 * Returns: a list of exception rule properties
 **/
void
e_cal_component_get_exrule_property_list (ECalComponent *comp,
                                          GSList **recur_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (recur_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	*recur_list = priv->exrule_list;
}

/**
 * e_cal_component_set_exrule_list:
 * @comp: A calendar component object.
 * @recur_list: (element-type icalrecurrencetype): List of struct
 * #icalrecurrencetype structures.
 *
 * Sets the list of exception rules in a calendar component object.
 **/
void
e_cal_component_set_exrule_list (ECalComponent *comp,
                                 GSList *recur_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_recur_list (comp, icalproperty_new_exrule, &priv->exrule_list, recur_list);

	priv->need_sequence_inc = TRUE;
}

/**
 * e_cal_component_has_exrules:
 * @comp: A calendar component object.
 *
 * Queries whether a calendar component object has any exception rules defined
 * for it.
 *
 * Returns: TRUE if the component has exception rules, FALSE otherwise.
 **/
gboolean
e_cal_component_has_exrules (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, FALSE);

	return (priv->exrule_list != NULL);
}

/**
 * e_cal_component_has_exceptions:
 * @comp: A calendar component object
 *
 * Queries whether a calendar component object has any exception dates
 * or exception rules.
 *
 * Returns: TRUE if the component has exceptions, FALSE otherwise.
 **/
gboolean
e_cal_component_has_exceptions (ECalComponent *comp)
{
	return e_cal_component_has_exdates (comp) || e_cal_component_has_exrules (comp);
}

/**
 * e_cal_component_get_geo:
 * @comp: A calendar component object.
 * @geo: (out): Return value for the geographic position property.  This should be
 * freed using the e_cal_component_free_geo() function.
 *
 * Gets the geographic position property of a calendar component object.
 **/
void
e_cal_component_get_geo (ECalComponent *comp,
                         struct icalgeotype **geo)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (geo != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (priv->geo) {
		*geo = g_new (struct icalgeotype, 1);
		**geo = icalproperty_get_geo (priv->geo);
	} else
		*geo = NULL;
}

/**
 * e_cal_component_set_geo:
 * @comp: A calendar component object.
 * @geo: Value for the geographic position property.
 *
 * Sets the geographic position property on a calendar component object.
 **/
void
e_cal_component_set_geo (ECalComponent *comp,
                         struct icalgeotype *geo)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!geo) {
		if (priv->geo) {
			icalcomponent_remove_property (priv->icalcomp, priv->geo);
			icalproperty_free (priv->geo);
			priv->geo = NULL;
		}

		return;
	}

	if (priv->geo)
		icalproperty_set_geo (priv->geo, *geo);
	else {
		priv->geo = icalproperty_new_geo (*geo);
		icalcomponent_add_property (priv->icalcomp, priv->geo);
	}
}

/**
 * e_cal_component_get_last_modified:
 * @comp: A calendar component object.
 * @t: Return value for the last modified time value.
 *
 * Queries the time at which a calendar component object was last modified in
 * the calendar store.
 **/
void
e_cal_component_get_last_modified (ECalComponent *comp,
                                   struct icaltimetype **t)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (t != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_icaltimetype (priv->last_modified, icalproperty_get_lastmodified, t);
}

/**
 * e_cal_component_set_last_modified:
 * @comp: A calendar component object.
 * @t: Value for the last time modified.
 *
 * Sets the time at which a calendar component object was last stored in the
 * calendar store.  This should not be called by plain calendar user agents.
 **/
void
e_cal_component_set_last_modified (ECalComponent *comp,
                                   struct icaltimetype *t)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_icaltimetype (
		comp, &priv->last_modified,
		icalproperty_new_lastmodified,
		icalproperty_set_lastmodified,
		t);
}

/**
 * e_cal_component_get_organizer:
 * @comp:  A calendar component object
 * @organizer: (out): A value for the organizer
 *
 * Queries the organizer property of a calendar component object
 **/
void
e_cal_component_get_organizer (ECalComponent *comp,
                               ECalComponentOrganizer *organizer)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (organizer != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (priv->organizer.prop)
		organizer->value = icalproperty_get_organizer (priv->organizer.prop);
	else
		organizer->value = NULL;

	if (priv->organizer.sentby_param)
		organizer->sentby = icalparameter_get_sentby (priv->organizer.sentby_param);
	else
		organizer->sentby = NULL;

	if (priv->organizer.cn_param)
		organizer->cn = icalparameter_get_sentby (priv->organizer.cn_param);
	else
		organizer->cn = NULL;

	if (priv->organizer.language_param)
		organizer->language = icalparameter_get_sentby (priv->organizer.language_param);
	else
		organizer->language = NULL;

}

/**
 * e_cal_component_set_organizer:
 * @comp:  A calendar component object.
 * @organizer: Value for the organizer property
 *
 * Sets the organizer of a calendar component object
 **/
void
e_cal_component_set_organizer (ECalComponent *comp,
                               ECalComponentOrganizer *organizer)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!organizer) {
		if (priv->organizer.prop) {
			icalcomponent_remove_property (priv->icalcomp, priv->organizer.prop);
			icalproperty_free (priv->organizer.prop);

			priv->organizer.prop = NULL;
			priv->organizer.sentby_param = NULL;
			priv->organizer.cn_param = NULL;
			priv->organizer.language_param = NULL;
		}

		return;
	}

	g_return_if_fail (organizer->value != NULL);

	if (priv->organizer.prop)
		icalproperty_set_organizer (priv->organizer.prop, (gchar *) organizer->value);
	else {
		priv->organizer.prop = icalproperty_new_organizer ((gchar *) organizer->value);
		icalcomponent_add_property (priv->icalcomp, priv->organizer.prop);
	}

	if (organizer->sentby) {
		g_return_if_fail (priv->organizer.prop != NULL);

		if (priv->organizer.sentby_param)
			icalparameter_set_sentby (
				priv->organizer.sentby_param,
				(gchar *) organizer->sentby);
		else {
			priv->organizer.sentby_param = icalparameter_new_sentby (
				(gchar *) organizer->sentby);
			icalproperty_add_parameter (
				priv->organizer.prop,
				priv->organizer.sentby_param);
		}
	} else if (priv->organizer.sentby_param) {
		icalproperty_remove_parameter_by_kind (priv->organizer.prop, ICAL_SENTBY_PARAMETER);
		priv->organizer.sentby_param = NULL;
	}

	if (organizer->cn) {
		g_return_if_fail (priv->organizer.prop != NULL);

		if (priv->organizer.cn_param)
			icalparameter_set_cn (
				priv->organizer.cn_param,
				(gchar *) organizer->cn);
		else {
			priv->organizer.cn_param = icalparameter_new_cn (
				(gchar *) organizer->cn);
			icalproperty_add_parameter (
				priv->organizer.prop,
				priv->organizer.cn_param);
		}
	} else if (priv->organizer.cn_param) {
		icalproperty_remove_parameter_by_kind (priv->organizer.prop, ICAL_CN_PARAMETER);
		priv->organizer.cn_param = NULL;
	}

	if (organizer->language) {
		g_return_if_fail (priv->organizer.prop != NULL);

		if (priv->organizer.language_param)
			icalparameter_set_language (
				priv->organizer.language_param,
				(gchar *) organizer->language);
		else {
			priv->organizer.language_param = icalparameter_new_language (
				(gchar *) organizer->language);
			icalproperty_add_parameter (
				priv->organizer.prop,
				priv->organizer.language_param);
		}
	} else if (priv->organizer.language_param) {
		icalproperty_remove_parameter_by_kind (priv->organizer.prop, ICAL_LANGUAGE_PARAMETER);
		priv->organizer.language_param = NULL;
	}

}

/**
 * e_cal_component_has_organizer:
 * @comp: A calendar component object.
 *
 * Check whether a calendar component object has an organizer or not.
 *
 * Returns: TRUE if there is an organizer, FALSE otherwise.
 **/
gboolean
e_cal_component_has_organizer (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;

	return priv->organizer.prop != NULL;
}

/**
 * e_cal_component_get_percent:
 * @comp: A calendar component object.
 * @percent: (out): Return value for the percent-complete property.  This should be
 * freed using the e_cal_component_free_percent() function.
 *
 * Queries the percent-complete property of a calendar component object.
 **/
void
e_cal_component_get_percent (ECalComponent *comp,
                             gint **percent)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (percent != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (priv->percent) {
		*percent = g_new (int, 1);
		**percent = icalproperty_get_percentcomplete (priv->percent);
	} else
		*percent = NULL;
}

/**
 * e_cal_component_set_percent_as_int:
 * @comp: an #ECalComponent
 * @percent: a percent to set, or -1 to remove the property
 *
 * Sets percent complete as integer. The @percent can be between 0 and 100, inclusive.
 * A special value -1 can be used to remove the percent complete property.
 *
 * Since: 2.28
 **/
void
e_cal_component_set_percent_as_int (ECalComponent *comp,
                                    gint percent)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (percent == -1) {
		if (priv->percent) {
			icalcomponent_remove_property (priv->icalcomp, priv->percent);
			icalproperty_free (priv->percent);
			priv->percent = NULL;
		}

		return;
	}

	g_return_if_fail (percent >= 0 && percent <= 100);

	if (priv->percent)
		icalproperty_set_percentcomplete (priv->percent, percent);
	else {
		priv->percent = icalproperty_new_percentcomplete (percent);
		icalcomponent_add_property (priv->icalcomp, priv->percent);
	}

}

/**
 * e_cal_component_get_percent_as_int:
 * @comp: an #ECalComponent
 *
 * Get percent complete as an integer value
 *
 * Returns: percent complete as an integer value, -1 when the @comp doesn't have the property
 *
 * Since: 2.28
 **/
gint
e_cal_component_get_percent_as_int (ECalComponent *comp)
{
	ECalComponentPrivate *priv;
	gint percent;

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, -1);

	if (priv->percent) {
		percent = icalproperty_get_percentcomplete (priv->percent);
	} else
		percent = -1;

	return percent;
}

/**
 * e_cal_component_set_percent:
 * @comp: A calendar component object.
 * @percent: Value for the percent-complete property.
 *
 * Sets the percent-complete property of a calendar component object.
 **/
void
e_cal_component_set_percent (ECalComponent *comp,
                             gint *percent)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!percent) {
		if (priv->percent) {
			icalcomponent_remove_property (priv->icalcomp, priv->percent);
			icalproperty_free (priv->percent);
			priv->percent = NULL;
		}

		return;
	}

	g_return_if_fail (*percent >= 0 && *percent <= 100);

	if (priv->percent)
		icalproperty_set_percentcomplete (priv->percent, *percent);
	else {
		priv->percent = icalproperty_new_percentcomplete (*percent);
		icalcomponent_add_property (priv->icalcomp, priv->percent);
	}
}

/**
 * e_cal_component_get_priority:
 * @comp: A calendar component object.
 * @priority: (out): Return value for the priority property.  This should be freed using
 * the e_cal_component_free_priority() function.
 *
 * Queries the priority property of a calendar component object.
 **/
void
e_cal_component_get_priority (ECalComponent *comp,
                              gint **priority)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (priority != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (priv->priority) {
		*priority = g_new (int, 1);
		**priority = icalproperty_get_priority (priv->priority);
	} else
		*priority = NULL;
}

/**
 * e_cal_component_set_priority:
 * @comp: A calendar component object.
 * @priority: Value for the priority property.
 *
 * Sets the priority property of a calendar component object.
 **/
void
e_cal_component_set_priority (ECalComponent *comp,
                              gint *priority)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!priority) {
		if (priv->priority) {
			icalcomponent_remove_property (priv->icalcomp, priv->priority);
			icalproperty_free (priv->priority);
			priv->priority = NULL;
		}

		return;
	}

	g_return_if_fail (*priority >= 0 && *priority <= 9);

	if (priv->priority)
		icalproperty_set_priority (priv->priority, *priority);
	else {
		priv->priority = icalproperty_new_priority (*priority);
		icalcomponent_add_property (priv->icalcomp, priv->priority);
	}
}

/**
 * e_cal_component_get_recurid:
 * @comp: A calendar component object.
 * @recur_id: (out): Return value for the recurrence id property
 *
 * Queries the recurrence id property of a calendar component object.
 **/
void
e_cal_component_get_recurid (ECalComponent *comp,
                             ECalComponentRange *recur_id)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (recur_id != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	recur_id->type = E_CAL_COMPONENT_RANGE_SINGLE;

	get_datetime (
		&priv->recur_id.recur_time,
		icalproperty_get_recurrenceid,
		&recur_id->datetime);
}

/**
 * e_cal_component_get_recurid_as_string:
 * @comp: A calendar component object.
 *
 * Gets the recurrence ID property as a string.
 *
 * Returns: the recurrence ID as a string.
 */
gchar *
e_cal_component_get_recurid_as_string (ECalComponent *comp)
{
	ECalComponentRange range;
	struct icaltimetype tt;

	if (!e_cal_component_is_instance (comp))
		return NULL;

	e_cal_component_get_recurid (comp, &range);
	if (!range.datetime.value) {
		e_cal_component_free_range (&range);
		return g_strdup ("0");
	}

	tt = *range.datetime.value;
	e_cal_component_free_range (&range);

	return icaltime_is_valid_time (tt) && !icaltime_is_null_time (tt) ?
		icaltime_as_ical_string_r (tt) : g_strdup ("0");
}

/**
 * e_cal_component_set_recurid:
 * @comp: A calendar component object.
 * @recur_id: Value for the recurrence id property.
 *
 * Sets the recurrence id property of a calendar component object.
 **/
void
e_cal_component_set_recurid (ECalComponent *comp,
                             ECalComponentRange *recur_id)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_datetime (
		comp, &priv->recur_id.recur_time,
		icalproperty_new_recurrenceid,
		icalproperty_set_recurrenceid,
		recur_id ? &recur_id->datetime : NULL);
}

/**
 * e_cal_component_get_rdate_list:
 * @comp: A calendar component object.
 * @period_list: (out) (transfer full) (element-type ECalComponentPeriod):
 * Return value for the list of recurrence dates, as a list of
 * #ECalComponentPeriod structures.  This should be freed using
 * e_cal_component_free_period_list()
 *
 * Queries the list of recurrence date properties in a calendar component
 * object.
 **/
void
e_cal_component_get_rdate_list (ECalComponent *comp,
                                GSList **period_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (period_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_period_list (priv->rdate_list, icalproperty_get_rdate, period_list);
}

/**
 * e_cal_component_set_rdate_list:
 * @comp: A calendar component object.
 * @period_list: (element-type ECalComponentPeriod): List of
 * #ECalComponentPeriod structures
 *
 * Sets the list of recurrence dates in a calendar component object.
 **/
void
e_cal_component_set_rdate_list (ECalComponent *comp,
                                GSList *period_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_period_list (comp, icalproperty_new_rdate, &priv->rdate_list, period_list);

	priv->need_sequence_inc = TRUE;
}

/**
 * e_cal_component_has_rdates:
 * @comp: A calendar component object.
 *
 * Queries whether a calendar component object has any recurrence dates defined
 * for it.
 *
 * Returns: TRUE if the component has recurrence dates, FALSE otherwise.
 **/
gboolean
e_cal_component_has_rdates (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, FALSE);

	return (priv->rdate_list != NULL);
}

/**
 * e_cal_component_get_rrule_list:
 * @comp: A calendar component object.
 * @recur_list: (out) (transfer full) (element-type icalrecurrencetype): List of
 * recurrence rules as struct #icalrecurrencetype structures.  This should be
 * freed using e_cal_component_free_recur_list().
 *
 * Queries the list of recurrence rule properties of a calendar component
 * object.
 **/
void
e_cal_component_get_rrule_list (ECalComponent *comp,
                                GSList **recur_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (recur_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_recur_list (priv->rrule_list, icalproperty_get_rrule, recur_list);
}

/**
 * e_cal_component_get_rrule_property_list:
 * @comp: A calendar component object.
 * @recur_list: (out) (transfer none) (element-type icalrecurrencetype): Returns
 * a list of recurrence rule properties.
 *
 * Queries a list of recurrence rule properties of a calendar component object.
 **/
void
e_cal_component_get_rrule_property_list (ECalComponent *comp,
                                         GSList **recur_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (recur_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	*recur_list = priv->rrule_list;
}

/**
 * e_cal_component_set_rrule_list:
 * @comp: A calendar component object.
 * @recur_list: (element-type icalrecurrencetype): List of struct
 * #icalrecurrencetype structures.
 *
 * Sets the list of recurrence rules in a calendar component object.
 **/
void
e_cal_component_set_rrule_list (ECalComponent *comp,
                                GSList *recur_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_recur_list (comp, icalproperty_new_rrule, &priv->rrule_list, recur_list);

	priv->need_sequence_inc = TRUE;
}

/**
 * e_cal_component_has_rrules:
 * @comp: A calendar component object.
 *
 * Queries whether a calendar component object has any recurrence rules defined
 * for it.
 *
 * Returns: TRUE if the component has recurrence rules, FALSE otherwise.
 **/
gboolean
e_cal_component_has_rrules (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, FALSE);

	return (priv->rrule_list != NULL);
}

/**
 * e_cal_component_has_recurrences:
 * @comp: A calendar component object
 *
 * Queries whether a calendar component object has any recurrence dates or
 * recurrence rules.
 *
 * Returns: TRUE if the component has recurrences, FALSE otherwise.
 **/
gboolean
e_cal_component_has_recurrences (ECalComponent *comp)
{
	return e_cal_component_has_rdates (comp) || e_cal_component_has_rrules (comp);
}

/* Counts the elements in the by_xxx fields of an icalrecurrencetype */
static gint
count_by_xxx (gshort *field,
              gint max_elements)
{
	gint i;

	for (i = 0; i < max_elements; i++)
		if (field[i] == ICAL_RECURRENCE_ARRAY_MAX)
			break;

	return i;
}

/**
 * e_cal_component_has_simple_recurrence:
 * @comp: A calendar component object.
 *
 * Checks whether the given calendar component object has simple recurrence
 * rules or more complicated ones.
 *
 * Returns: TRUE if it has a simple recurrence rule, FALSE otherwise.
 */
gboolean
e_cal_component_has_simple_recurrence (ECalComponent *comp)
{
	GSList *rrule_list;
	struct icalrecurrencetype *r;
	gint n_by_second, n_by_minute, n_by_hour;
	gint n_by_day, n_by_month_day, n_by_year_day;
	gint n_by_week_no, n_by_month, n_by_set_pos;
	gint len, i;
	gboolean simple = FALSE;

	if (!e_cal_component_has_recurrences (comp))
		return TRUE;

	e_cal_component_get_rrule_list (comp, &rrule_list);
	len = g_slist_length (rrule_list);
	if (len > 1
	    || e_cal_component_has_rdates (comp)
	    || e_cal_component_has_exrules (comp))
		goto cleanup;

	/* Down to one rule, so test that one */
	r = rrule_list->data;

	/* Any funky frequency? */
	if (r->freq == ICAL_SECONDLY_RECURRENCE
	    || r->freq == ICAL_MINUTELY_RECURRENCE
	    || r->freq == ICAL_HOURLY_RECURRENCE)
		goto cleanup;

	/* Any funky BY_* */
#define N_HAS_BY(field) (count_by_xxx (field, G_N_ELEMENTS (field)))

	n_by_second = N_HAS_BY (r->by_second);
	n_by_minute = N_HAS_BY (r->by_minute);
	n_by_hour = N_HAS_BY (r->by_hour);
	n_by_day = N_HAS_BY (r->by_day);
	n_by_month_day = N_HAS_BY (r->by_month_day);
	n_by_year_day = N_HAS_BY (r->by_year_day);
	n_by_week_no = N_HAS_BY (r->by_week_no);
	n_by_month = N_HAS_BY (r->by_month);
	n_by_set_pos = N_HAS_BY (r->by_set_pos);

	if (n_by_second != 0
	    || n_by_minute != 0
	    || n_by_hour != 0)
		goto cleanup;

	switch (r->freq) {
	case ICAL_DAILY_RECURRENCE:
		if (n_by_day != 0
		    || n_by_month_day != 0
		    || n_by_year_day != 0
		    || n_by_week_no != 0
		    || n_by_month != 0
		    || n_by_set_pos != 0)
			goto cleanup;

		simple = TRUE;
		break;

	case ICAL_WEEKLY_RECURRENCE:
		if (n_by_month_day != 0
		    || n_by_year_day != 0
		    || n_by_week_no != 0
		    || n_by_month != 0
		    || n_by_set_pos != 0)
			goto cleanup;

		for (i = 0; i < 8 && r->by_day[i] != ICAL_RECURRENCE_ARRAY_MAX; i++) {
			gint pos;
			pos = icalrecurrencetype_day_position (r->by_day[i]);

			if (pos != 0)
				goto cleanup;
		}

		simple = TRUE;
		break;

	case ICAL_MONTHLY_RECURRENCE:
		if (n_by_year_day != 0
		    || n_by_week_no != 0
		    || n_by_month != 0
		    || n_by_set_pos > 1)
			goto cleanup;

		if (n_by_month_day == 1) {
			gint nth;

			if (n_by_set_pos != 0)
				goto cleanup;

			nth = r->by_month_day[0];
			if (nth < 1 && nth != -1)
				goto cleanup;

		} else if (n_by_day == 1) {
			enum icalrecurrencetype_weekday weekday;
			gint pos;

			/* Outlook 2000 uses BYDAY=TU;BYSETPOS=2, and will not
			 * accept BYDAY=2TU. So we now use the same as Outlook
			 * by default. */

			weekday = icalrecurrencetype_day_day_of_week (r->by_day[0]);
			pos = icalrecurrencetype_day_position (r->by_day[0]);

			if (pos == 0) {
				if (n_by_set_pos != 1)
					goto cleanup;
				pos = r->by_set_pos[0];
			} else if (pos < 0) {
				goto cleanup;
			}

			switch (weekday) {
			case ICAL_MONDAY_WEEKDAY:
			case ICAL_TUESDAY_WEEKDAY:
			case ICAL_WEDNESDAY_WEEKDAY:
			case ICAL_THURSDAY_WEEKDAY:
			case ICAL_FRIDAY_WEEKDAY:
			case ICAL_SATURDAY_WEEKDAY:
			case ICAL_SUNDAY_WEEKDAY:
				break;

			default:
				goto cleanup;
			}
		} else {
			goto cleanup;
		}

		simple = TRUE;
		break;

	case ICAL_YEARLY_RECURRENCE:
		if (n_by_day != 0
		    || n_by_month_day != 0
		    || n_by_year_day != 0
		    || n_by_week_no != 0
		    || n_by_month != 0
		    || n_by_set_pos != 0)
			goto cleanup;

		simple = TRUE;
		break;

	default:
		goto cleanup;
	}

 cleanup:
	e_cal_component_free_recur_list (rrule_list);

	return simple;
}

/**
 * e_cal_component_is_instance:
 * @comp: A calendar component object.
 *
 * Checks whether a calendar component object is an instance of a recurring
 * event.
 *
 * Returns: TRUE if it is an instance, FALSE if not.
 */
gboolean
e_cal_component_is_instance (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;

	return !(priv->recur_id.recur_time.prop == NULL);
}

/**
 * e_cal_component_get_sequence:
 * @comp: A calendar component object.
 * @sequence: (out): Return value for the sequence number.  This should be freed using
 * e_cal_component_free_sequence().
 *
 * Queries the sequence number of a calendar component object.
 **/
void
e_cal_component_get_sequence (ECalComponent *comp,
                              gint **sequence)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (sequence != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!priv->sequence) {
		*sequence = NULL;
		return;
	}

	*sequence = g_new (int, 1);
	**sequence = icalproperty_get_sequence (priv->sequence);
}

/**
 * e_cal_component_set_sequence:
 * @comp: A calendar component object.
 * @sequence: Sequence number value.
 *
 * Sets the sequence number of a calendar component object.  Normally this
 * function should not be called, since the sequence number is incremented
 * automatically at the proper times.
 **/
void
e_cal_component_set_sequence (ECalComponent *comp,
                              gint *sequence)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	priv->need_sequence_inc = FALSE;

	if (!sequence) {
		if (priv->sequence) {
			icalcomponent_remove_property (priv->icalcomp, priv->sequence);
			icalproperty_free (priv->sequence);
			priv->sequence = NULL;
		}

		return;
	}

	if (priv->sequence)
		icalproperty_set_sequence (priv->sequence, *sequence);
	else {
		priv->sequence = icalproperty_new_sequence (*sequence);
		icalcomponent_add_property (priv->icalcomp, priv->sequence);
	}
}

/**
 * e_cal_component_get_status:
 * @comp: A calendar component object.
 * @status: (out): Return value for the status value.  It is set to #ICAL_STATUS_NONE
 * if the component has no status property.
 *
 * Queries the status property of a calendar component object.
 **/
void
e_cal_component_get_status (ECalComponent *comp,
                            icalproperty_status *status)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (status != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!priv->status) {
		*status = ICAL_STATUS_NONE;
		return;
	}

	*status = icalproperty_get_status (priv->status);
}

/**
 * e_cal_component_set_status:
 * @comp: A calendar component object.
 * @status: Status value.  You should use #ICAL_STATUS_NONE if you want to unset
 * this property.
 *
 * Sets the status property of a calendar component object.
 **/
void
e_cal_component_set_status (ECalComponent *comp,
                            icalproperty_status status)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	priv->need_sequence_inc = TRUE;

	if (status == ICAL_STATUS_NONE) {
		if (priv->status) {
			icalcomponent_remove_property (priv->icalcomp, priv->status);
			icalproperty_free (priv->status);
			priv->status = NULL;
		}

		return;
	}

	if (priv->status) {
		icalproperty_set_status (priv->status, status);
	} else {
		priv->status = icalproperty_new_status (status);
		icalcomponent_add_property (priv->icalcomp, priv->status);
	}
}

/**
 * e_cal_component_get_summary:
 * @comp: A calendar component object.
 * @summary: (out): Return value for the summary property and its parameters.
 *
 * Queries the summary of a calendar component object.
 **/
void
e_cal_component_get_summary (ECalComponent *comp,
                             ECalComponentText *summary)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (summary != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (priv->summary.prop)
		summary->value = icalproperty_get_summary (priv->summary.prop);
	else
		summary->value = NULL;

	if (priv->summary.altrep_param)
		summary->altrep = icalparameter_get_altrep (priv->summary.altrep_param);
	else
		summary->altrep = NULL;
}

typedef struct {
	gchar *old_summary;
	const gchar *new_summary;
} SetAlarmDescriptionData;

static void
set_alarm_description_cb (gpointer key,
                          gpointer value,
                          gpointer user_data)
{
	icalcomponent *alarm;
	icalproperty *icalprop, *desc_prop;
	SetAlarmDescriptionData *sadd;
	gboolean changed = FALSE;
	const gchar *old_summary = NULL;
	gboolean free_description = FALSE;

	alarm = value;
	sadd = user_data;

	/* set the new description on the alarm */
	desc_prop = icalcomponent_get_first_property (alarm, ICAL_DESCRIPTION_PROPERTY);
	if (desc_prop) {
		old_summary = icalproperty_get_description (desc_prop);
	} else {
		desc_prop = icalproperty_new_description (sadd->new_summary);
		free_description = TRUE;
	}

	/* remove the X-EVOLUTION-NEEDS_DESCRIPTION property */
	icalprop = icalcomponent_get_first_property (alarm, ICAL_X_PROPERTY);
	while (icalprop) {
		const gchar *x_name;

		x_name = icalproperty_get_x_name (icalprop);
		if (!strcmp (x_name, "X-EVOLUTION-NEEDS-DESCRIPTION")) {
			icalcomponent_remove_property (alarm, icalprop);
			icalproperty_free (icalprop);

			icalproperty_set_description (desc_prop, sadd->new_summary);
			changed = TRUE;
			break;
		}

		icalprop = icalcomponent_get_next_property (alarm, ICAL_X_PROPERTY);
	}

	if (!changed) {
		if (!strcmp (old_summary ? old_summary : "", sadd->old_summary ? sadd->old_summary : "")) {
			icalproperty_set_description (desc_prop, sadd->new_summary);
		}
	}

	if (free_description)
		icalproperty_free (desc_prop);
}

/**
 * e_cal_component_set_summary:
 * @comp: A calendar component object.
 * @summary: Summary property and its parameters.
 *
 * Sets the summary of a calendar component object.
 **/
void
e_cal_component_set_summary (ECalComponent *comp,
                             ECalComponentText *summary)
{
	ECalComponentPrivate *priv;
	SetAlarmDescriptionData sadd;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!summary) {
		if (priv->summary.prop) {
			icalcomponent_remove_property (priv->icalcomp, priv->summary.prop);
			icalproperty_free (priv->summary.prop);

			priv->summary.prop = NULL;
			priv->summary.altrep_param = NULL;
		}

		return;
	}

	g_return_if_fail (summary->value != NULL);

	if (priv->summary.prop) {
		/* Make a copy, to avoid use-after-free */
		sadd.old_summary = g_strdup (icalproperty_get_summary (priv->summary.prop));
		icalproperty_set_summary (priv->summary.prop, (gchar *) summary->value);
	} else {
		sadd.old_summary = NULL;
		priv->summary.prop = icalproperty_new_summary ((gchar *) summary->value);
		icalcomponent_add_property (priv->icalcomp, priv->summary.prop);
	}

	if (summary->altrep) {
		g_return_if_fail (priv->summary.prop != NULL);

		if (priv->summary.altrep_param)
			icalparameter_set_altrep (
				priv->summary.altrep_param,
				(gchar *) summary->altrep);
		else {
			priv->summary.altrep_param = icalparameter_new_altrep (
				(gchar *) summary->altrep);
			icalproperty_add_parameter (
				priv->summary.prop,
				priv->summary.altrep_param);
		}
	} else if (priv->summary.altrep_param) {
		icalproperty_remove_parameter_by_kind (priv->summary.prop, ICAL_ALTREP_PARAMETER);
		priv->summary.altrep_param = NULL;
	}

	/* look for alarms that need a description */
	sadd.new_summary = summary->value;
	g_hash_table_foreach (priv->alarm_uid_hash, set_alarm_description_cb, &sadd);

	g_free (sadd.old_summary);
}

/**
 * e_cal_component_get_transparency:
 * @comp: A calendar component object.
 * @transp: (out): Return value for the time transparency.
 *
 * Queries the time transparency of a calendar component object.
 **/
void
e_cal_component_get_transparency (ECalComponent *comp,
                                  ECalComponentTransparency *transp)
{
	ECalComponentPrivate *priv;
	icalproperty_transp ical_transp;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (transp != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!priv->transparency) {
		*transp = E_CAL_COMPONENT_TRANSP_NONE;
		return;
	}

	ical_transp = icalproperty_get_transp (priv->transparency);

	switch (ical_transp)
	{
	case ICAL_TRANSP_TRANSPARENT:
	case ICAL_TRANSP_TRANSPARENTNOCONFLICT:
	  *transp = E_CAL_COMPONENT_TRANSP_TRANSPARENT;
	  break;

	case ICAL_TRANSP_OPAQUE:
	case ICAL_TRANSP_OPAQUENOCONFLICT:
	  *transp = E_CAL_COMPONENT_TRANSP_OPAQUE;
	  break;

	default:
	  *transp = E_CAL_COMPONENT_TRANSP_UNKNOWN;
	  break;
	}
}

/**
 * e_cal_component_set_transparency:
 * @comp: A calendar component object.
 * @transp: Time transparency value.
 *
 * Sets the time transparency of a calendar component object.
 **/
void
e_cal_component_set_transparency (ECalComponent *comp,
                                  ECalComponentTransparency transp)
{
	ECalComponentPrivate *priv;
	icalproperty_transp ical_transp;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (transp != E_CAL_COMPONENT_TRANSP_UNKNOWN);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (transp == E_CAL_COMPONENT_TRANSP_NONE) {
		if (priv->transparency) {
			icalcomponent_remove_property (priv->icalcomp, priv->transparency);
			icalproperty_free (priv->transparency);
			priv->transparency = NULL;
		}

		return;
	}

	switch (transp) {
	case E_CAL_COMPONENT_TRANSP_TRANSPARENT:
	  ical_transp = ICAL_TRANSP_TRANSPARENT;
		break;

	case E_CAL_COMPONENT_TRANSP_OPAQUE:
	  ical_transp = ICAL_TRANSP_OPAQUE;
		break;

	default:
		g_warn_if_reached ();
		ical_transp = ICAL_TRANSP_NONE;
	}

	if (priv->transparency)
		icalproperty_set_transp (priv->transparency, ical_transp);
	else {
		priv->transparency = icalproperty_new_transp (ical_transp);
		icalcomponent_add_property (priv->icalcomp, priv->transparency);
	}
}

/**
 * e_cal_component_get_url:
 * @comp: A calendar component object.
 * @url: (out) (transfer none): Return value for the URL.
 *
 * Queries the uniform resource locator property of a calendar component object.
 **/
void
e_cal_component_get_url (ECalComponent *comp,
                         const gchar **url)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (url != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (priv->url)
		*url = icalproperty_get_url (priv->url);
	else
		*url = NULL;
}

/**
 * e_cal_component_set_url:
 * @comp: A calendar component object.
 * @url: URL value.
 *
 * Sets the uniform resource locator property of a calendar component object.
 **/
void
e_cal_component_set_url (ECalComponent *comp,
                         const gchar *url)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!url || !(*url)) {
		if (priv->url) {
			icalcomponent_remove_property (priv->icalcomp, priv->url);
			icalproperty_free (priv->url);
			priv->url = NULL;
		}

		return;
	}

	if (priv->url)
		icalproperty_set_url (priv->url, (gchar *) url);
	else {
		priv->url = icalproperty_new_url ((gchar *) url);
		icalcomponent_add_property (priv->icalcomp, priv->url);
	}
}

/* Gets a text list value */
static void
get_attendee_list (GSList *attendee_list,
                   GSList **al)
{
	GSList *l;

	*al = NULL;

	if (!attendee_list)
		return;

	for (l = attendee_list; l; l = l->next) {
		struct attendee *attendee;
		ECalComponentAttendee *a;

		attendee = l->data;
		g_return_if_fail (attendee->prop != NULL);

		a = g_new0 (ECalComponentAttendee, 1);
		a->value = icalproperty_get_attendee (attendee->prop);

		if (attendee->member_param)
			a->member = icalparameter_get_member (attendee->member_param);
		if (attendee->cutype_param)
			a->cutype = icalparameter_get_cutype (attendee->cutype_param);
		else
			a->cutype = ICAL_CUTYPE_UNKNOWN;
		if (attendee->role_param)
			a->role = icalparameter_get_role (attendee->role_param);
		else
			a->role = ICAL_ROLE_REQPARTICIPANT;
		if (attendee->partstat_param)
			a->status = icalparameter_get_partstat (attendee->partstat_param);
		else
			a->status = ICAL_PARTSTAT_NEEDSACTION;
		if (attendee->rsvp_param && icalparameter_get_rsvp (attendee->rsvp_param) == ICAL_RSVP_TRUE)
			a->rsvp = TRUE;
		else
			a->rsvp = FALSE;
		if (attendee->delfrom_param)
			a->delfrom = icalparameter_get_delegatedfrom (attendee->delfrom_param);
		if (attendee->delto_param)
			a->delto = icalparameter_get_delegatedto (attendee->delto_param);
		if (attendee->sentby_param)
			a->sentby = icalparameter_get_sentby (attendee->sentby_param);
		if (attendee->cn_param)
			a->cn = icalparameter_get_cn (attendee->cn_param);
		if (attendee->language_param)
			a->language = icalparameter_get_language (attendee->language_param);

		*al = g_slist_prepend (*al, a);
	}

	*al = g_slist_reverse (*al);
}

/* Sets a text list value */
static void
set_attendee_list (icalcomponent *icalcomp,
                   GSList **attendee_list,
                   GSList *al)
{
	GSList *l;

	/* Remove old attendees */

	for (l = *attendee_list; l; l = l->next) {
		struct attendee *attendee;

		attendee = l->data;
		g_return_if_fail (attendee->prop != NULL);

		icalcomponent_remove_property (icalcomp, attendee->prop);
		icalproperty_free (attendee->prop);
		g_free (attendee);
	}

	g_slist_free (*attendee_list);
	*attendee_list = NULL;

	/* Add in new attendees */

	for (l = al; l; l = l->next) {
		ECalComponentAttendee *a;
		struct attendee *attendee;

		a = l->data;
		g_return_if_fail (a->value != NULL);

		attendee = g_new0 (struct attendee, 1);

		attendee->prop = icalproperty_new_attendee (a->value);
		icalcomponent_add_property (icalcomp, attendee->prop);

		if (a->member) {
			attendee->member_param = icalparameter_new_member (a->member);
			icalproperty_add_parameter (attendee->prop, attendee->member_param);
		}

		attendee->cutype_param = icalparameter_new_cutype (a->cutype);
		icalproperty_add_parameter (attendee->prop, attendee->cutype_param);

		attendee->role_param = icalparameter_new_role (a->role);
		icalproperty_add_parameter (attendee->prop, attendee->role_param);

		attendee->partstat_param = icalparameter_new_partstat (a->status);
		icalproperty_add_parameter (attendee->prop, attendee->partstat_param);

		if (a->rsvp)
			attendee->rsvp_param = icalparameter_new_rsvp (ICAL_RSVP_TRUE);
		else
			attendee->rsvp_param = icalparameter_new_rsvp (ICAL_RSVP_FALSE);
		icalproperty_add_parameter (attendee->prop, attendee->rsvp_param);

		if (a->delfrom) {
			attendee->delfrom_param = icalparameter_new_delegatedfrom (a->delfrom);
			icalproperty_add_parameter (attendee->prop, attendee->delfrom_param);
		}
		if (a->delto) {
			attendee->delto_param = icalparameter_new_delegatedto (a->delto);
			icalproperty_add_parameter (attendee->prop, attendee->delto_param);
		}
		if (a->sentby) {
			attendee->sentby_param = icalparameter_new_sentby (a->sentby);
			icalproperty_add_parameter (attendee->prop, attendee->sentby_param);
		}
		if (a->cn) {
			attendee->cn_param = icalparameter_new_cn (a->cn);
			icalproperty_add_parameter (attendee->prop, attendee->cn_param);
		}
		if (a->language) {
			attendee->language_param = icalparameter_new_language (a->language);
			icalproperty_add_parameter (attendee->prop, attendee->language_param);
		}

		*attendee_list = g_slist_prepend (*attendee_list, attendee);
	}

	*attendee_list = g_slist_reverse (*attendee_list);
}

/**
 * e_cal_component_get_attendee_list:
 * @comp: A calendar component object.
 * @attendee_list: (out) (transfer full) (element-type ECalComponentAttendee):
 * Return value for the attendee property. This should be freed using
 * e_cal_component_free_attendee_list().
 *
 * Queries the attendee properties of the calendar component object
 **/
void
e_cal_component_get_attendee_list (ECalComponent *comp,
                                   GSList **attendee_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (attendee_list != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	get_attendee_list (priv->attendee_list, attendee_list);
}

/**
 * e_cal_component_set_attendee_list:
 * @comp: A calendar component object.
 * @attendee_list: (element-type ECalComponentAttendee): Values for attendee
 * properties
 *
 * Sets the attendees of a calendar component object
 **/
void
e_cal_component_set_attendee_list (ECalComponent *comp,
                                   GSList *attendee_list)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	set_attendee_list (priv->icalcomp, &priv->attendee_list, attendee_list);
}

/**
 * e_cal_component_has_attendees:
 * @comp: A calendar component object.
 *
 * Queries a calendar component object for the existence of attendees.
 *
 * Returns: TRUE if there are attendees, FALSE if not.
 */
gboolean
e_cal_component_has_attendees (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;

	if (g_slist_length (priv->attendee_list) > 0)
		return TRUE;

	return FALSE;
}

/**
 * e_cal_component_get_location:
 * @comp: A calendar component object
 * @location: (out) (transfer none): Return value for the location.
 *
 * Queries the location property of a calendar component object.
 **/
void
e_cal_component_get_location (ECalComponent *comp,
                              const gchar **location)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (location != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (priv->location)
		*location = icalproperty_get_location (priv->location);
	else
		*location = NULL;
}

/**
 * e_cal_component_set_location:
 * @comp: A calendar component object.
 * @location: Location value.
 *
 * Sets the location property of a calendar component object.
 **/
void
e_cal_component_set_location (ECalComponent *comp,
                              const gchar *location)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	if (!location || !(*location)) {
		if (priv->location) {
			icalcomponent_remove_property (priv->icalcomp, priv->location);
			icalproperty_free (priv->location);
			priv->location = NULL;
		}

		return;
	}

	if (priv->location)
		icalproperty_set_location (priv->location, (gchar *) location);
	else {
		priv->location = icalproperty_new_location ((gchar *) location);
		icalcomponent_add_property (priv->icalcomp, priv->location);
	}
}



/**
 * e_cal_component_free_categories_list:
 * @categ_list: (element-type utf8): List of category strings
 *
 * Frees a list of category strings.
 **/
void
e_cal_component_free_categories_list (GSList *categ_list)
{
	GSList *l;

	for (l = categ_list; l; l = l->next)
		g_free (l->data);

	g_slist_free (categ_list);
}

/**
 * e_cal_component_free_datetime:
 * @dt: A date/time structure.
 *
 * Frees a date/time structure.
 **/
void
e_cal_component_free_datetime (ECalComponentDateTime *dt)
{
	g_return_if_fail (dt != NULL);

	g_free (dt->value);
	g_free ((gchar *) dt->tzid);

	dt->value = NULL;
	dt->tzid = NULL;
}

/**
 * e_cal_component_free_range:
 * @range: A #ECalComponentRange.
 *
 * Frees an #ECalComponentRange structure.
 */
void
e_cal_component_free_range (ECalComponentRange *range)
{
	g_return_if_fail (range != NULL);

	e_cal_component_free_datetime (&range->datetime);
}

/**
 * e_cal_component_free_exdate_list:
 * @exdate_list: (element-type ECalComponentDateTime): List of
 * #ECalComponentDateTime structures
 *
 * Frees a list of #ECalComponentDateTime structures as returned by the
 * e_cal_component_get_exdate_list() function.
 **/
void
e_cal_component_free_exdate_list (GSList *exdate_list)
{
	GSList *l;

	for (l = exdate_list; l; l = l->next) {
		ECalComponentDateTime *cdt;

		g_return_if_fail (l->data != NULL);
		cdt = l->data;

		g_return_if_fail (cdt->value != NULL);
		g_free (cdt->value);
		g_free ((gchar *) cdt->tzid);

		g_free (cdt);
	}

	g_slist_free (exdate_list);
}

/**
 * e_cal_component_free_geo:
 * @geo: An #icalgeotype structure.
 *
 * Frees a struct #icalgeotype structure as returned by the calendar component
 * functions.
 **/
void
e_cal_component_free_geo (struct icalgeotype *geo)
{
	g_return_if_fail (geo != NULL);

	g_free (geo);
}

/**
 * e_cal_component_free_icaltimetype:
 * @t: An #icaltimetype structure.
 *
 * Frees a struct #icaltimetype value as returned by the calendar component
 * functions.
 **/
void
e_cal_component_free_icaltimetype (struct icaltimetype *t)
{
	g_return_if_fail (t != NULL);

	g_free (t);
}

/**
 * e_cal_component_free_percent:
 * @percent: Percent value.
 *
 * Frees a percent value as returned by the e_cal_component_get_percent()
 * function.
 **/
void
e_cal_component_free_percent (gint *percent)
{
	g_return_if_fail (percent != NULL);

	g_free (percent);
}

/**
 * e_cal_component_free_priority:
 * @priority: Priority value.
 *
 * Frees a priority value as returned by the e_cal_component_get_priority()
 * function.
 **/
void
e_cal_component_free_priority (gint *priority)
{
	g_return_if_fail (priority != NULL);

	g_free (priority);
}

/**
 * e_cal_component_free_period_list:
 * @period_list: (element-type ECalComponentPeriod): List of
 * #ECalComponentPeriod structures
 *
 * Frees a list of #ECalComponentPeriod structures.
 **/
void
e_cal_component_free_period_list (GSList *period_list)
{
	g_slist_foreach (period_list, (GFunc) g_free, NULL);
	g_slist_free (period_list);
}

/**
 * e_cal_component_free_recur_list:
 * @recur_list: (element-type icalrecurrencetype): List of struct
 * #icalrecurrencetype structures.
 *
 * Frees a list of struct #icalrecurrencetype structures.
 **/
void
e_cal_component_free_recur_list (GSList *recur_list)
{
	g_slist_foreach (recur_list, (GFunc) g_free, NULL);
	g_slist_free (recur_list);
}

/**
 * e_cal_component_free_sequence:
 * @sequence: Sequence number value.
 *
 * Frees a sequence number value.
 **/
void
e_cal_component_free_sequence (gint *sequence)
{
	g_return_if_fail (sequence != NULL);

	g_free (sequence);
}

/**
 * e_cal_component_free_id:
 * @id: an #ECalComponentId
 *
 * Frees the @id.
 **/
void
e_cal_component_free_id (ECalComponentId *id)
{
	g_return_if_fail (id != NULL);

	g_free (id->uid);
	g_free (id->rid);

	g_free (id);
}

/**
 * e_cal_component_id_new:
 * @uid: a unique ID string
 * @rid: (allow-none): an optional recurrence ID string
 *
 * Creates a new #ECalComponentId from @uid and @rid, which should be
 * freed with e_cal_component_free_id().
 *
 * Returns: an #ECalComponentId
 *
 * Since: 3.10
 **/
ECalComponentId *
e_cal_component_id_new (const gchar *uid,
                        const gchar *rid)
{
	ECalComponentId *id;

	g_return_val_if_fail (uid != NULL, NULL);

	/* Normalize an empty recurrence ID to NULL. */
	if (rid != NULL && *rid == '\0')
		rid = NULL;

	id = g_new0 (ECalComponentId, 1);
	id->uid = g_strdup (uid);
	id->rid = g_strdup (rid);

	return id;
}

/**
 * e_cal_component_id_copy:
 * @id: an #ECalComponentId
 *
 * Returns a newly-allocated copy of @id, which should be freed with
 * e_cal_component_free_id().
 *
 * Returns: a newly-allocated copy of @id
 *
 * Since: 3.10
 **/
ECalComponentId *
e_cal_component_id_copy (const ECalComponentId *id)
{
	g_return_val_if_fail (id != NULL, NULL);

	return e_cal_component_id_new (id->uid, id->rid);
}

/**
 * e_cal_component_id_hash:
 * @id: an #ECalComponentId
 *
 * Generates a hash value for @id.
 *
 * Returns: a hash value for @id
 *
 * Since: 3.10
 **/
guint
e_cal_component_id_hash (const ECalComponentId *id)
{
	guint uid_hash;
	guint rid_hash;

	g_return_val_if_fail (id != NULL, 0);

	uid_hash = g_str_hash (id->uid);
	rid_hash = (id->rid != NULL) ? g_str_hash (id->rid) : 0;

	return uid_hash ^ rid_hash;
}

/**
 * e_cal_component_id_equal:
 * @id1: the first #ECalComponentId
 * @id2: the second #ECalComponentId
 *
 * Compares two #ECalComponentId structs for equality.
 *
 * Returns: %TRUE if @id1 and @id2 are equal
 *
 * Since: 3.10
 **/
gboolean
e_cal_component_id_equal (const ECalComponentId *id1,
                          const ECalComponentId *id2)
{
	gboolean uids_equal;
	gboolean rids_equal;

	if (id1 == id2)
		return TRUE;

	/* Safety check before we dereference. */
	g_return_val_if_fail (id1 != NULL, FALSE);
	g_return_val_if_fail (id2 != NULL, FALSE);

	uids_equal = (g_strcmp0 (id1->uid, id2->uid) == 0);
	rids_equal = (g_strcmp0 (id1->rid, id2->rid) == 0);

	return uids_equal && rids_equal;
}

/**
 * e_cal_component_free_text_list:
 * @text_list: (element-type ECalComponentText): List of #ECalComponentText
 * structures.
 *
 * Frees a list of #ECalComponentText structures.  This function should only be
 * used to free lists of text values as returned by the other getter functions
 * of #ECalComponent.
 **/
void
e_cal_component_free_text_list (GSList *text_list)
{
	g_slist_foreach (text_list, (GFunc) g_free, NULL);
	g_slist_free (text_list);
}

/**
 * e_cal_component_free_attendee_list:
 * @attendee_list: (element-type ECalComponentAttendee): List of attendees
 *
 * Frees a list of #ECalComponentAttendee structures.
 *
 **/
void
e_cal_component_free_attendee_list (GSList *attendee_list)
{
	g_slist_foreach (attendee_list, (GFunc) g_free, NULL);
	g_slist_free (attendee_list);
}



/**
 * e_cal_component_has_alarms:
 * @comp: A calendar component object.
 *
 * Checks whether the component has any alarms.
 *
 * Returns: TRUE if the component has any alarms.
 **/
gboolean
e_cal_component_has_alarms (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_val_if_fail (comp != NULL, FALSE);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), FALSE);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, FALSE);

	return g_hash_table_size (priv->alarm_uid_hash) != 0;
}

/**
 * e_cal_component_add_alarm:
 * @comp: A calendar component.
 * @alarm: An alarm.
 *
 * Adds an alarm subcomponent to a calendar component.  You should have created
 * the @alarm by using e_cal_component_alarm_new(); it is invalid to use a
 * #ECalComponentAlarm structure that came from e_cal_component_get_alarm().  After
 * adding the alarm, the @alarm structure is no longer valid because the
 * internal structures may change and you should get rid of it by using
 * e_cal_component_alarm_free().
 **/
void
e_cal_component_add_alarm (ECalComponent *comp,
                           ECalComponentAlarm *alarm)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (alarm != NULL);

	priv = comp->priv;

	add_alarm (comp, alarm->icalcomp, icalproperty_get_x (alarm->uid));
	icalcomponent_add_component (priv->icalcomp, alarm->icalcomp);
}

/**
 * e_cal_component_remove_alarm:
 * @comp: A calendar component.
 * @auid: UID of the alarm to remove.
 *
 * Removes an alarm subcomponent from a calendar component.  If the alarm that
 * corresponds to the specified @auid had been fetched with
 * e_cal_component_get_alarm(), then those alarm structures will be invalid; you
 * should get rid of them with e_cal_component_alarm_free() before using this
 * function.
 **/
void
e_cal_component_remove_alarm (ECalComponent *comp,
                              const gchar *auid)
{
	ECalComponentPrivate *priv;
	icalcomponent *alarm;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));
	g_return_if_fail (auid != NULL);

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	alarm = g_hash_table_lookup (priv->alarm_uid_hash, auid);
	if (!alarm)
		return;

	g_hash_table_remove (priv->alarm_uid_hash, auid);
	icalcomponent_remove_component (priv->icalcomp, alarm);
	icalcomponent_free (alarm);
}

static gboolean
for_each_remove_all_alarms (gpointer key,
                            gpointer value,
                            gpointer data)
{
	ECalComponent *comp = E_CAL_COMPONENT (data);
	ECalComponentPrivate *priv;
	icalcomponent *alarm = value;

	priv = comp->priv;

	icalcomponent_remove_component (priv->icalcomp, alarm);
	icalcomponent_free (alarm);

	return TRUE;
}

/**
 * e_cal_component_remove_all_alarms:
 * @comp: A calendar component
 *
 * Remove all alarms from the calendar component
 **/
void
e_cal_component_remove_all_alarms (ECalComponent *comp)
{
	ECalComponentPrivate *priv;

	g_return_if_fail (comp != NULL);
	g_return_if_fail (E_IS_CAL_COMPONENT (comp));

	priv = comp->priv;
	g_return_if_fail (priv->icalcomp != NULL);

	g_hash_table_foreach_remove (priv->alarm_uid_hash, for_each_remove_all_alarms, comp);
}

/* Scans an icalproperty from a calendar component and adds its mapping to our
 * own alarm structure.
 */
static void
scan_alarm_property (ECalComponentAlarm *alarm,
                     icalproperty *prop)
{
	icalproperty_kind kind;
	const gchar *xname;

	kind = icalproperty_isa (prop);

	switch (kind) {
	case ICAL_ACTION_PROPERTY:
		alarm->action = prop;
		break;

	case ICAL_ATTACH_PROPERTY:
		/* FIXME: mail alarms may have any number of these, not just one */
		alarm->attach = prop;
		break;

	case ICAL_DESCRIPTION_PROPERTY:
		alarm->description.prop = prop;
		alarm->description.altrep_param = icalproperty_get_first_parameter (
			prop, ICAL_ALTREP_PARAMETER);
		break;

	case ICAL_DURATION_PROPERTY:
		alarm->duration = prop;
		break;

	case ICAL_REPEAT_PROPERTY:
		alarm->repeat = prop;
		break;

	case ICAL_TRIGGER_PROPERTY:
		alarm->trigger = prop;
		break;

	case ICAL_ATTENDEE_PROPERTY:
		scan_attendee (&alarm->attendee_list, prop);
		break;

	case ICAL_X_PROPERTY:
		xname = icalproperty_get_x_name (prop);
		g_return_if_fail (xname != NULL);

		if (strcmp (xname, EVOLUTION_ALARM_UID_PROPERTY) == 0)
			alarm->uid = prop;

		break;

	default:
		break;
	}
}

/* Creates a ECalComponentAlarm from a libical alarm subcomponent */
static ECalComponentAlarm *
make_alarm (icalcomponent *subcomp)
{
	ECalComponentAlarm *alarm;
	icalproperty *prop;

	alarm = g_new (ECalComponentAlarm, 1);

	alarm->icalcomp = subcomp;
	alarm->uid = NULL;

	alarm->action = NULL;
	alarm->attach = NULL;
	alarm->description.prop = NULL;
	alarm->description.altrep_param = NULL;
	alarm->duration = NULL;
	alarm->repeat = NULL;
	alarm->trigger = NULL;
	alarm->attendee_list = NULL;

	for (prop = icalcomponent_get_first_property (subcomp, ICAL_ANY_PROPERTY);
	     prop;
	     prop = icalcomponent_get_next_property (subcomp, ICAL_ANY_PROPERTY))
		scan_alarm_property (alarm, prop);

	g_return_val_if_fail (alarm->uid != NULL, NULL);

	return alarm;
}

/**
 * e_cal_component_get_alarm_uids:
 * @comp: A calendar component.
 *
 * Builds a list of the unique identifiers of the alarm subcomponents inside a
 * calendar component.
 *
 * Returns: (element-type utf8) (transfer full): List of unique identifiers for
 * alarms.  This should be freed using cal_obj_uid_list_free().
 **/
GList *
e_cal_component_get_alarm_uids (ECalComponent *comp)
{
	ECalComponentPrivate *priv;
	icalcompiter iter;
	GList *l;

	g_return_val_if_fail (comp != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, NULL);

	l = NULL;
	for (iter = icalcomponent_begin_component (priv->icalcomp, ICAL_VALARM_COMPONENT);
	     icalcompiter_deref (&iter) != NULL;
	     icalcompiter_next (&iter)) {
		icalcomponent *subcomp;
		icalproperty *prop;

		subcomp = icalcompiter_deref (&iter);
		for (prop = icalcomponent_get_first_property (subcomp, ICAL_X_PROPERTY);
		     prop;
		     prop = icalcomponent_get_next_property (subcomp, ICAL_X_PROPERTY)) {
			const gchar *xname;

			xname = icalproperty_get_x_name (prop);
			g_return_val_if_fail (xname != NULL, NULL);

			if (strcmp (xname, EVOLUTION_ALARM_UID_PROPERTY) == 0) {
				const gchar *auid;

				auid = alarm_uid_from_prop (prop);
				l = g_list_append (l, g_strdup (auid));
			}
		}
	}

	return l;
}

/**
 * e_cal_component_get_alarm:
 * @comp: A calendar component.
 * @auid: Unique identifier for the sought alarm subcomponent.
 *
 * Queries a particular alarm subcomponent of a calendar component.
 *
 * Returns: The alarm subcomponent that corresponds to the specified @auid,
 * or %NULL if no alarm exists with that UID.  This should be freed using
 * e_cal_component_alarm_free().
 **/
ECalComponentAlarm *
e_cal_component_get_alarm (ECalComponent *comp,
                           const gchar *auid)
{
	ECalComponentPrivate *priv;
	icalcomponent *alarm;

	g_return_val_if_fail (comp != NULL, NULL);
	g_return_val_if_fail (E_IS_CAL_COMPONENT (comp), NULL);

	priv = comp->priv;
	g_return_val_if_fail (priv->icalcomp != NULL, NULL);

	g_return_val_if_fail (auid != NULL, NULL);

	alarm = g_hash_table_lookup (priv->alarm_uid_hash, auid);

	if (alarm)
		return make_alarm (alarm);
	else
		return NULL;
}

/**
 * e_cal_component_alarms_free:
 * @alarms: Component alarms structure.
 *
 * Frees a #ECalComponentAlarms structure.
 **/
void
e_cal_component_alarms_free (ECalComponentAlarms *alarms)
{
	GSList *l;

	g_return_if_fail (alarms != NULL);

	if (alarms->comp != NULL)
		g_object_unref (alarms->comp);

	for (l = alarms->alarms; l; l = l->next) {
		ECalComponentAlarmInstance *instance = l->data;

		if (instance != NULL) {
			g_free (instance->auid);
			g_free (instance);
		} else
			g_warn_if_reached ();
	}

	g_slist_free (alarms->alarms);
	g_free (alarms);
}

/**
 * e_cal_component_alarm_new:
 *
 * Create a new alarm object.
 *
 * Returns: a new alarm component
 **/
ECalComponentAlarm *
e_cal_component_alarm_new (void)
{
	ECalComponentAlarm *alarm;
	gchar *new_auid;

	alarm = g_new (ECalComponentAlarm, 1);

	alarm->icalcomp = icalcomponent_new (ICAL_VALARM_COMPONENT);

	new_auid = e_util_generate_uid ();
	alarm->uid = icalproperty_new_x (new_auid);
	icalproperty_set_x_name (alarm->uid, EVOLUTION_ALARM_UID_PROPERTY);
	icalcomponent_add_property (alarm->icalcomp, alarm->uid);
	g_free (new_auid);

	alarm->action = NULL;
	alarm->attach = NULL;
	alarm->description.prop = NULL;
	alarm->description.altrep_param = NULL;
	alarm->duration = NULL;
	alarm->repeat = NULL;
	alarm->trigger = NULL;
	alarm->attendee_list = NULL;

	return alarm;
}

/**
 * e_cal_component_alarm_clone:
 * @alarm: An alarm subcomponent.
 *
 * Creates a new alarm subcomponent by copying the information from another one.
 *
 * Returns: A newly-created alarm subcomponent with the same values as the
 * original one.  Should be freed with e_cal_component_alarm_free().
 **/
ECalComponentAlarm *
e_cal_component_alarm_clone (ECalComponentAlarm *alarm)
{
	icalcomponent *icalcomp;

	g_return_val_if_fail (alarm != NULL, NULL);

	icalcomp = icalcomponent_new_clone (alarm->icalcomp);
	return make_alarm (icalcomp);
}

/**
 * e_cal_component_alarm_free:
 * @alarm: A calendar alarm.
 *
 * Frees an alarm structure.
 **/
void
e_cal_component_alarm_free (ECalComponentAlarm *alarm)
{
	GSList *l;

	g_return_if_fail (alarm != NULL);
	g_return_if_fail (alarm->icalcomp != NULL);

	if (icalcomponent_get_parent (alarm->icalcomp) == NULL)
		icalcomponent_free (alarm->icalcomp);

	alarm->icalcomp = NULL;
	alarm->uid = NULL;
	alarm->action = NULL;
	alarm->attach = NULL;
	alarm->description.prop = NULL;
	alarm->description.altrep_param = NULL;
	alarm->duration = NULL;
	alarm->repeat = NULL;
	alarm->trigger = NULL;

	for (l = alarm->attendee_list; l != NULL; l = l->next)
		g_free (l->data);
	g_slist_free (alarm->attendee_list);
	alarm->attendee_list = NULL;

	g_free (alarm);
}

/**
 * e_cal_component_alarm_get_uid:
 * @alarm: An alarm subcomponent.
 *
 * Queries the unique identifier of an alarm subcomponent.
 *
 * Returns: UID of the alarm.
 **/
const gchar *
e_cal_component_alarm_get_uid (ECalComponentAlarm *alarm)
{
	g_return_val_if_fail (alarm != NULL, NULL);

	return alarm_uid_from_prop (alarm->uid);
}

/**
 * e_cal_component_alarm_get_action:
 * @alarm: An alarm.
 * @action: (out): Return value for the alarm's action type.
 *
 * Queries the action type of an alarm.
 **/
void
e_cal_component_alarm_get_action (ECalComponentAlarm *alarm,
                                  ECalComponentAlarmAction *action)
{
	enum icalproperty_action ipa;

	g_return_if_fail (alarm != NULL);
	g_return_if_fail (action != NULL);
	g_return_if_fail (alarm->icalcomp != NULL);

	if (!alarm->action) {
		*action = E_CAL_COMPONENT_ALARM_NONE;
		return;
	}

	ipa = icalproperty_get_action (alarm->action);

	switch (ipa) {
	case ICAL_ACTION_AUDIO:
		*action = E_CAL_COMPONENT_ALARM_AUDIO;
		break;

	case ICAL_ACTION_DISPLAY:
		*action = E_CAL_COMPONENT_ALARM_DISPLAY;
		break;

	case ICAL_ACTION_EMAIL:
		*action = E_CAL_COMPONENT_ALARM_EMAIL;
		break;

	case ICAL_ACTION_PROCEDURE:
		*action = E_CAL_COMPONENT_ALARM_PROCEDURE;
		break;

	case ICAL_ACTION_NONE:
		*action = E_CAL_COMPONENT_ALARM_NONE;
		break;

	default:
		*action = E_CAL_COMPONENT_ALARM_UNKNOWN;
	}
}

/**
 * e_cal_component_alarm_set_action:
 * @alarm: An alarm.
 * @action: Action type.
 *
 * Sets the action type for an alarm.
 **/
void
e_cal_component_alarm_set_action (ECalComponentAlarm *alarm,
                                  ECalComponentAlarmAction action)
{
	enum icalproperty_action ipa;

	g_return_if_fail (alarm != NULL);
	g_return_if_fail (action != E_CAL_COMPONENT_ALARM_NONE);
	g_return_if_fail (action != E_CAL_COMPONENT_ALARM_UNKNOWN);
	g_return_if_fail (alarm->icalcomp != NULL);

	switch (action) {
	case E_CAL_COMPONENT_ALARM_AUDIO:
		ipa = ICAL_ACTION_AUDIO;
		break;

	case E_CAL_COMPONENT_ALARM_DISPLAY:
		ipa = ICAL_ACTION_DISPLAY;
		break;

	case E_CAL_COMPONENT_ALARM_EMAIL:
		ipa = ICAL_ACTION_EMAIL;
		break;

	case E_CAL_COMPONENT_ALARM_PROCEDURE:
		ipa = ICAL_ACTION_PROCEDURE;
		break;

	default:
		g_warn_if_reached ();
		ipa = ICAL_ACTION_NONE;
	}

	if (alarm->action)
		icalproperty_set_action (alarm->action, ipa);
	else {
		alarm->action = icalproperty_new_action (ipa);
		icalcomponent_add_property (alarm->icalcomp, alarm->action);
	}
}

/**
 * e_cal_component_alarm_get_attach:
 * @alarm: An alarm.
 * @attach: (out): Return value for the attachment; should be freed using icalattach_unref().
 *
 * Queries the attachment property of an alarm.
 **/
void
e_cal_component_alarm_get_attach (ECalComponentAlarm *alarm,
                                  icalattach **attach)
{
	g_return_if_fail (alarm != NULL);
	g_return_if_fail (attach != NULL);
	g_return_if_fail (alarm->icalcomp != NULL);

	if (alarm->attach) {
		*attach = icalproperty_get_attach (alarm->attach);
		icalattach_ref (*attach);
	} else
		*attach = NULL;
}

/**
 * e_cal_component_alarm_set_attach:
 * @alarm: An alarm.
 * @attach: Attachment property or NULL to remove an existing property.
 *
 * Sets the attachment property of an alarm.
 **/
void
e_cal_component_alarm_set_attach (ECalComponentAlarm *alarm,
                                  icalattach *attach)
{
	g_return_if_fail (alarm != NULL);
	g_return_if_fail (alarm->icalcomp != NULL);

	if (alarm->attach) {
		icalcomponent_remove_property (alarm->icalcomp, alarm->attach);
		icalproperty_free (alarm->attach);
		alarm->attach = NULL;
	}

	if (attach) {
		alarm->attach = icalproperty_new_attach (attach);
		icalcomponent_add_property (alarm->icalcomp, alarm->attach);
	}
}

/**
 * e_cal_component_alarm_get_description:
 * @alarm: An alarm.
 * @description: (out): Return value for the description property and its parameters.
 *
 * Queries the description property of an alarm.
 **/
void
e_cal_component_alarm_get_description (ECalComponentAlarm *alarm,
                                       ECalComponentText *description)
{
	g_return_if_fail (alarm != NULL);
	g_return_if_fail (description != NULL);
	g_return_if_fail (alarm->icalcomp != NULL);

	if (alarm->description.prop)
		description->value = icalproperty_get_description (alarm->description.prop);
	else
		description->value = NULL;

	if (alarm->description.altrep_param)
		description->altrep = icalparameter_get_altrep (alarm->description.altrep_param);
	else
		description->altrep = NULL;
}

/**
 * e_cal_component_alarm_set_description:
 * @alarm: An alarm.
 * @description: Description property and its parameters, or NULL for no description.
 *
 * Sets the description property of an alarm.
 **/
void
e_cal_component_alarm_set_description (ECalComponentAlarm *alarm,
                                       ECalComponentText *description)
{
	g_return_if_fail (alarm != NULL);
	g_return_if_fail (alarm->icalcomp != NULL);

	if (alarm->description.prop) {
		icalcomponent_remove_property (alarm->icalcomp, alarm->description.prop);
		icalproperty_free (alarm->description.prop);

		alarm->description.prop = NULL;
		alarm->description.altrep_param = NULL;
	}

	if (!description)
		return;

	g_return_if_fail (description->value != NULL);

	alarm->description.prop = icalproperty_new_description (description->value);
	icalcomponent_add_property (alarm->icalcomp, alarm->description.prop);

	if (description->altrep) {
		alarm->description.altrep_param = icalparameter_new_altrep (
			(gchar *) description->altrep);
		icalproperty_add_parameter (
			alarm->description.prop,
			alarm->description.altrep_param);
	}
}

/**
 * e_cal_component_alarm_get_repeat:
 * @alarm: An alarm.
 * @repeat: (out): Return value for the repeat/duration properties.
 *
 * Queries the repeat/duration properties of an alarm.
 **/
void
e_cal_component_alarm_get_repeat (ECalComponentAlarm *alarm,
                                  ECalComponentAlarmRepeat *repeat)
{
	g_return_if_fail (alarm != NULL);
	g_return_if_fail (repeat != NULL);
	g_return_if_fail (alarm->icalcomp != NULL);

	if (!(alarm->repeat && alarm->duration)) {
		repeat->repetitions = 0;
		memset (&repeat->duration, 0, sizeof (repeat->duration));
		return;
	}

	repeat->repetitions = icalproperty_get_repeat (alarm->repeat);
	repeat->duration = icalproperty_get_duration (alarm->duration);
}

/**
 * e_cal_component_alarm_set_repeat:
 * @alarm: An alarm.
 * @repeat: Repeat/duration values.  To remove any repetitions from the alarm,
 * set the @repeat.repetitions to 0.
 *
 * Sets the repeat/duration values for an alarm.
 **/
void
e_cal_component_alarm_set_repeat (ECalComponentAlarm *alarm,
                                  ECalComponentAlarmRepeat repeat)
{
	g_return_if_fail (alarm != NULL);
	g_return_if_fail (repeat.repetitions >= 0);
	g_return_if_fail (alarm->icalcomp != NULL);

	/* Delete old properties */

	if (alarm->repeat) {
		icalcomponent_remove_property (alarm->icalcomp, alarm->repeat);
		icalproperty_free (alarm->repeat);
		alarm->repeat = NULL;
	}

	if (alarm->duration) {
		icalcomponent_remove_property (alarm->icalcomp, alarm->duration);
		icalproperty_free (alarm->duration);
		alarm->duration = NULL;
	}

	/* Set the new properties */

	if (repeat.repetitions == 0)
		return; /* For zero extra repetitions the properties should not exist */

	alarm->repeat = icalproperty_new_repeat (repeat.repetitions);
	icalcomponent_add_property (alarm->icalcomp, alarm->repeat);

	alarm->duration = icalproperty_new_duration (repeat.duration);
	icalcomponent_add_property (alarm->icalcomp, alarm->duration);
}

/**
 * e_cal_component_alarm_get_trigger:
 * @alarm: An alarm.
 * @trigger: (out): Return value for the trigger time.
 *
 * Queries the trigger time for an alarm.
 **/
void
e_cal_component_alarm_get_trigger (ECalComponentAlarm *alarm,
                                   ECalComponentAlarmTrigger *trigger)
{
	icalparameter *param;
	struct icaltriggertype t;
	gboolean relative;

	g_return_if_fail (alarm != NULL);
	g_return_if_fail (trigger != NULL);
	g_return_if_fail (alarm->icalcomp != NULL);

	if (!alarm->trigger) {
		trigger->type = E_CAL_COMPONENT_ALARM_TRIGGER_NONE;
		return;
	}

	/* Get trigger type */

	param = icalproperty_get_first_parameter (alarm->trigger, ICAL_VALUE_PARAMETER);
	if (param) {
		icalparameter_value value;

		value = icalparameter_get_value (param);

		switch (value) {
		case ICAL_VALUE_DURATION:
			relative = TRUE;
			break;

		case ICAL_VALUE_DATETIME:
			relative = FALSE;
			break;

		default:
			g_message (
				"e_cal_component_alarm_get_trigger(): "
				"Unknown value for trigger "
				"value %d; using RELATIVE", value);

			relative = TRUE;
			break;
		}
	} else
		relative = TRUE;

	/* Get trigger value and the RELATED parameter */

	t = icalproperty_get_trigger (alarm->trigger);

	if (relative) {
		trigger->u.rel_duration = t.duration;

		param = icalproperty_get_first_parameter (alarm->trigger, ICAL_RELATED_PARAMETER);
		if (param) {
			icalparameter_related rel;

			rel = icalparameter_get_related (param);

			switch (rel) {
			case ICAL_RELATED_START:
				trigger->type = E_CAL_COMPONENT_ALARM_TRIGGER_RELATIVE_START;
				break;

			case ICAL_RELATED_END:
				trigger->type = E_CAL_COMPONENT_ALARM_TRIGGER_RELATIVE_END;
				break;

			default:
				g_return_if_reached ();
			}
		} else
			trigger->type = E_CAL_COMPONENT_ALARM_TRIGGER_RELATIVE_START;
	} else {
		trigger->u.abs_time = t.time;
		trigger->type = E_CAL_COMPONENT_ALARM_TRIGGER_ABSOLUTE;
	}
}

/**
 * e_cal_component_alarm_set_trigger:
 * @alarm: An alarm.
 * @trigger: Trigger time structure.
 *
 * Sets the trigger time of an alarm.
 **/
void
e_cal_component_alarm_set_trigger (ECalComponentAlarm *alarm,
                                   ECalComponentAlarmTrigger trigger)
{
	struct icaltriggertype t;
	icalparameter *param;
	icalparameter_value value_type;
	icalparameter_related related;

	g_return_if_fail (alarm != NULL);
	g_return_if_fail (trigger.type != E_CAL_COMPONENT_ALARM_TRIGGER_NONE);
	g_return_if_fail (alarm->icalcomp != NULL);

	/* Delete old trigger */

	if (alarm->trigger) {
		icalcomponent_remove_property (alarm->icalcomp, alarm->trigger);
		icalproperty_free (alarm->trigger);
		alarm->trigger = NULL;
	}

	/* Set the value */

	related = ICAL_RELATED_START; /* Keep GCC happy */

	t.time = icaltime_null_time ();
	t.duration = icaldurationtype_null_duration ();
	switch (trigger.type) {
	case E_CAL_COMPONENT_ALARM_TRIGGER_RELATIVE_START:
		t.duration = trigger.u.rel_duration;
		value_type = ICAL_VALUE_DURATION;
		related = ICAL_RELATED_START;
		break;

	case E_CAL_COMPONENT_ALARM_TRIGGER_RELATIVE_END:
		t.duration = trigger.u.rel_duration;
		value_type = ICAL_VALUE_DURATION;
		related = ICAL_RELATED_END;
		break;

	case E_CAL_COMPONENT_ALARM_TRIGGER_ABSOLUTE:
		t.time = trigger.u.abs_time;
		value_type = ICAL_VALUE_DATETIME;
		break;

	default:
		g_return_if_reached ();
	}

	alarm->trigger = icalproperty_new_trigger (t);
	icalcomponent_add_property (alarm->icalcomp, alarm->trigger);

	/* Value parameters */

	param = icalproperty_get_first_parameter (alarm->trigger, ICAL_VALUE_PARAMETER);
	if (param)
		icalparameter_set_value (param, value_type);
	else {
		param = icalparameter_new_value (value_type);
		icalproperty_add_parameter (alarm->trigger, param);
	}

	/* Related parameter */

	if (trigger.type != E_CAL_COMPONENT_ALARM_TRIGGER_ABSOLUTE) {
		param = icalproperty_get_first_parameter (alarm->trigger, ICAL_RELATED_PARAMETER);

		if (param)
			icalparameter_set_related (param, related);
		else {
			param = icalparameter_new_related (related);
			icalproperty_add_parameter (alarm->trigger, param);
		}
	}
}

/**
 * e_cal_component_alarm_get_attendee_list:
 * @alarm: An alarm.
 * @attendee_list: (out) (transfer full) (element-type ECalComponentAttendee): Return value for the list of attendees.
 *
 * Gets the list of attendees associated with an alarm.
 */
void
e_cal_component_alarm_get_attendee_list (ECalComponentAlarm *alarm,
                                         GSList **attendee_list)
{
	g_return_if_fail (alarm != NULL);

	get_attendee_list (alarm->attendee_list, attendee_list);
}

/**
 * e_cal_component_alarm_set_attendee_list:
 * @alarm: An alarm.
 * @attendee_list: (element-type ECalComponentAttendee): List of attendees.
 *
 * Sets the list of attendees for an alarm.
 */
void
e_cal_component_alarm_set_attendee_list (ECalComponentAlarm *alarm,
                                         GSList *attendee_list)
{
	g_return_if_fail (alarm != NULL);

	set_attendee_list (alarm->icalcomp, &alarm->attendee_list, attendee_list);
}

/**
 * e_cal_component_alarm_has_attendees:
 * @alarm: An alarm.
 *
 * Queries an alarm to see if it has attendees associated with it.
 *
 * Returns: TRUE if there are attendees in the alarm, FALSE if not.
 */
gboolean
e_cal_component_alarm_has_attendees (ECalComponentAlarm *alarm)
{

	g_return_val_if_fail (alarm != NULL, FALSE);

	if (g_slist_length (alarm->attendee_list) > 0)
		return TRUE;

	return FALSE;
}

/**
 * e_cal_component_alarm_get_icalcomponent:
 * @alarm: An alarm.
 *
 * Get the icalcomponent associated with the given #ECalComponentAlarm.
 *
 * Returns: the icalcomponent.
 */
icalcomponent *
e_cal_component_alarm_get_icalcomponent (ECalComponentAlarm *alarm)
{
	g_return_val_if_fail (alarm != NULL, NULL);
	return alarm->icalcomp;
}

/* Returns TRUE if both strings match, i.e. they are both NULL or the
 * strings are equal. */
static gboolean
e_cal_component_strings_match (const gchar *string1,
                               const gchar *string2)
{
	if (string1 == NULL || string2 == NULL)
		return (string1 == string2) ? TRUE : FALSE;

	if (!strcmp (string1, string2))
		return TRUE;

	return FALSE;
}

/**
 * e_cal_component_event_dates_match:
 * @comp1: A calendar component object.
 * @comp2: A calendar component object.
 *
 * Checks if the DTSTART and DTEND properties of the 2 components match.
 * Note that the events may have different recurrence properties which are not
 * taken into account here.
 *
 * Returns: TRUE if the DTSTART and DTEND properties of the 2 components match.
 **/
gboolean
e_cal_component_event_dates_match (ECalComponent *comp1,
                                   ECalComponent *comp2)
{
	ECalComponentDateTime comp1_dtstart, comp1_dtend;
	ECalComponentDateTime comp2_dtstart, comp2_dtend;
	gboolean retval = TRUE;

	e_cal_component_get_dtstart (comp1, &comp1_dtstart);
	e_cal_component_get_dtend   (comp1, &comp1_dtend);
	e_cal_component_get_dtstart (comp2, &comp2_dtstart);
	e_cal_component_get_dtend   (comp2, &comp2_dtend);

	/* If either value is NULL they must both be NULL to match. */
	if (comp1_dtstart.value == NULL || comp2_dtstart.value == NULL) {
		if (comp1_dtstart.value != comp2_dtstart.value) {
			retval = FALSE;
			goto out;
		}
	} else {
		if (icaltime_compare (*comp1_dtstart.value,
				      *comp2_dtstart.value)) {
			retval = FALSE;
			goto out;
		}
	}

	if (comp1_dtend.value == NULL || comp2_dtend.value == NULL) {
		if (comp1_dtend.value != comp2_dtend.value) {
			retval = FALSE;
			goto out;
		}
	} else {
		if (icaltime_compare (*comp1_dtend.value,
				      *comp2_dtend.value)) {
			retval = FALSE;
			goto out;
		}
	}

	/* Now check the timezones. */
	if (!e_cal_component_strings_match (comp1_dtstart.tzid,
					  comp2_dtstart.tzid)) {
		retval = FALSE;
		goto out;
	}

	if (!e_cal_component_strings_match (comp1_dtend.tzid,
					  comp2_dtend.tzid)) {
		retval = FALSE;
	}

 out:

	e_cal_component_free_datetime (&comp1_dtstart);
	e_cal_component_free_datetime (&comp1_dtend);
	e_cal_component_free_datetime (&comp2_dtstart);
	e_cal_component_free_datetime (&comp2_dtend);

	return retval;
}

