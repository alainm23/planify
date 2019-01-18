/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
 *
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Gilbert Fang <gilbert.fang@sun.com>
 */

#include "evolution-data-server-config.h"

#include <locale.h>
#include <stdlib.h>
#include <string.h>
#include <glib/gi18n.h>
#include <glib/gstdio.h>

#include <libebook/libebook.h>
#include <libedataserver/libedataserver.h>

#define COMMA_SEPARATOR ","

#define SUCCESS 0
#define FAILED  -1

#define ACTION_NOTHING       0
#define ACTION_LIST_FOLDERS  1
#define ACTION_LIST_CARDS    2

#define DEFAULT_SIZE_NUMBER 100

struct _ActionContext {
	GMainLoop *main_loop;
	guint action_type;

	ESourceRegistry *registry;
	const gchar *output_file;

	/* for cards only */
	gint IsCSV;
	gint IsVCard;
	const gchar *addressbook_source_uid;
};

typedef struct _ActionContext ActionContext;

static void
action_list_folders_init (ActionContext *p_actctx)
{
	ESourceRegistry *registry;
	GList *list, *iter;
	FILE *outputfile = NULL;
	const gchar *extension_name;

	registry = p_actctx->registry;

	if (p_actctx->output_file != NULL) {
		if (!(outputfile = g_fopen (p_actctx->output_file, "w"))) {
			g_warning (_("Can not open file"));
			exit (-1);
		}
	}

	extension_name = E_SOURCE_EXTENSION_ADDRESS_BOOK;
	list = e_source_registry_list_sources (registry, extension_name);

	for (iter = list; iter != NULL; iter = g_list_next (iter)) {
		EClient *client;
		EBookClient *book_client;
		EBookQuery *query;
		ESource *source;
		GSList *contacts = NULL;
		const gchar *display_name;
		const gchar *uid;
		gchar *query_str;
		GError *error = NULL;

		source = E_SOURCE (iter->data);

		client = e_book_client_connect_sync (source, 30, NULL, &error);

		/* Sanity check. */
		g_warn_if_fail (
			((client != NULL) && (error == NULL)) ||
			((client == NULL) && (error != NULL)));

		if (error != NULL) {
			g_warning (
				_("Failed to open client “%s”: %s"),
				e_source_get_display_name (source),
				error->message);
			g_error_free (error);
			continue;
		}

		book_client = E_BOOK_CLIENT (client);

		query = e_book_query_any_field_contains ("");
		query_str = e_book_query_to_string (query);
		e_book_query_unref (query);

		if (!e_book_client_get_contacts_sync (book_client, query_str, &contacts, NULL, NULL))
			contacts = NULL;

		display_name = e_source_get_display_name (source);
		uid = e_source_get_uid (source);

		if (outputfile)
			fprintf (
				outputfile, "\"%s\",\"%s\",%d\n",
				uid, display_name, g_slist_length (contacts));
		else
			printf (
				"\"%s\",\"%s\",%d\n",
				uid, display_name, g_slist_length (contacts));

		g_slist_free_full (contacts, g_object_unref);
		g_object_unref (book_client);
	}

	g_list_free_full (list, (GDestroyNotify) g_object_unref);

	if (outputfile)
		fclose (outputfile);
}

typedef enum _CARD_FORMAT CARD_FORMAT;
typedef enum _DeliveryAddressField DeliveryAddressField;
typedef enum _EContactFieldCSV EContactFieldCSV;
typedef struct _EContactCSVFieldData EContactCSVFieldData;

enum _CARD_FORMAT
{
	CARD_FORMAT_CSV,
	CARD_FORMAT_VCARD
};

enum _DeliveryAddressField
{
	DELIVERY_ADDRESS_STREET,
	DELIVERY_ADDRESS_EXT,
	DELIVERY_ADDRESS_LOCALITY,
	DELIVERY_ADDRESS_REGION,
	DELIVERY_ADDRESS_CODE,
	DELIVERY_ADDRESS_COUNTRY
};

enum _EContactFieldCSV
{
	E_CONTACT_CSV_FILE_AS,
	E_CONTACT_CSV_FULL_NAME,
	E_CONTACT_CSV_EMAIL_1,
	E_CONTACT_CSV_EMAIL_2,
	E_CONTACT_CSV_EMAIL_3,
	E_CONTACT_CSV_EMAIL_4,
	E_CONTACT_CSV_PHONE_PRIMARY,
	E_CONTACT_CSV_PHONE_ASSISTANT,
	E_CONTACT_CSV_PHONE_BUSINESS,
	E_CONTACT_CSV_PHONE_CALLBACK,
	E_CONTACT_CSV_PHONE_COMPANY,
	E_CONTACT_CSV_PHONE_HOME,
	E_CONTACT_CSV_ORG,
	/*E_CONTACT_CSV_ADDRESS_BUSINESS, */
	E_CONTACT_CSV_ADDRESS_BUSINESS_STREET,
	E_CONTACT_CSV_ADDRESS_BUSINESS_EXT,
	E_CONTACT_CSV_ADDRESS_BUSINESS_CITY,
	E_CONTACT_CSV_ADDRESS_BUSINESS_REGION,
	E_CONTACT_CSV_ADDRESS_BUSINESS_POSTCODE,
	E_CONTACT_CSV_ADDRESS_BUSINESS_COUNTRY,
	/*E_CONTACT_CSV_ADDRESS_HOME, */
	E_CONTACT_CSV_ADDRESS_HOME_STREET,
	E_CONTACT_CSV_ADDRESS_HOME_EXT,
	E_CONTACT_CSV_ADDRESS_HOME_CITY,
	E_CONTACT_CSV_ADDRESS_HOME_REGION,
	E_CONTACT_CSV_ADDRESS_HOME_POSTCODE,
	E_CONTACT_CSV_ADDRESS_HOME_COUNTRY,
	E_CONTACT_CSV_PHONE_MOBILE,
	E_CONTACT_CSV_PHONE_CAR,
	E_CONTACT_CSV_PHONE_BUSINESS_FAX,
	E_CONTACT_CSV_PHONE_HOME_FAX,
	E_CONTACT_CSV_PHONE_BUSINESS_2,
	E_CONTACT_CSV_PHONE_HOME_2,
	E_CONTACT_CSV_PHONE_ISDN,
	E_CONTACT_CSV_PHONE_OTHER,
	E_CONTACT_CSV_PHONE_OTHER_FAX,
	E_CONTACT_CSV_PHONE_PAGER,
	E_CONTACT_CSV_PHONE_RADIO,
	E_CONTACT_CSV_PHONE_TELEX,
	E_CONTACT_CSV_PHONE_TTYTDD,
	/*E_CONTACT_CSV_ADDRESS_OTHER, */
	E_CONTACT_CSV_ADDRESS_OTHER_STREET,
	E_CONTACT_CSV_ADDRESS_OTHER_EXT,
	E_CONTACT_CSV_ADDRESS_OTHER_CITY,
	E_CONTACT_CSV_ADDRESS_OTHER_REGION,
	E_CONTACT_CSV_ADDRESS_OTHER_POSTCODE,
	E_CONTACT_CSV_ADDRESS_OTHER_COUNTRY,
	E_CONTACT_CSV_HOMEPAGE_URL,
	E_CONTACT_CSV_ORG_UNIT,
	E_CONTACT_CSV_OFFICE,
	E_CONTACT_CSV_TITLE,
	E_CONTACT_CSV_ROLE,
	E_CONTACT_CSV_MANAGER,
	E_CONTACT_CSV_ASSISTANT,
	E_CONTACT_CSV_NICKNAME,
	E_CONTACT_CSV_SPOUSE,
	E_CONTACT_CSV_NOTE,
	E_CONTACT_CSV_CALENDAR_URI,
	E_CONTACT_CSV_FREEBUSY_URL,
	/*E_CONTACT_CSV_ANNIVERSARY, */
	E_CONTACT_CSV_ANNIVERSARY_YEAR,
	E_CONTACT_CSV_ANNIVERSARY_MONTH,
	E_CONTACT_CSV_ANNIVERSARY_DAY,
	/*E_CONTACT_CSV_BIRTH_DATE, */
	E_CONTACT_CSV_BIRTH_DATE_YEAR,
	E_CONTACT_CSV_BIRTH_DATE_MONTH,
	E_CONTACT_CSV_BIRTH_DATE_DAY,
	E_CONTACT_CSV_MAILER,
	E_CONTACT_CSV_NAME_OR_ORG,
	E_CONTACT_CSV_CATEGORIES,
	E_CONTACT_CSV_FAMILY_NAME,
	E_CONTACT_CSV_GIVEN_NAME,
	E_CONTACT_CSV_WANTS_HTML,
	E_CONTACT_CSV_IS_LIST,
	E_CONTACT_CSV_MIDDLE_NAME,
	E_CONTACT_CSV_NAME_TITLE,
	E_CONTACT_CSV_NAME_SUFFIX,
	E_CONTACT_CSV_LAST
};

typedef enum {
	DT_STRING,
	DT_BOOLEAN
} EContactCSVDataType;

struct _EContactCSVFieldData
{
	gint csv_field;
	gint contact_field;
	const gchar *csv_name;
	EContactCSVDataType data_type;
};

#define NOMAP -1
static EContactCSVFieldData csv_field_data[] = {
	{E_CONTACT_CSV_FILE_AS,		E_CONTACT_FILE_AS,	   "", DT_STRING},
	{E_CONTACT_CSV_FULL_NAME,	E_CONTACT_FULL_NAME,       "", DT_STRING},
	{E_CONTACT_CSV_EMAIL_1,		E_CONTACT_EMAIL_1,	   "", DT_STRING},
	{E_CONTACT_CSV_EMAIL_2,		E_CONTACT_EMAIL_2,	   "", DT_STRING},
	{E_CONTACT_CSV_EMAIL_3,		E_CONTACT_EMAIL_3,	   "", DT_STRING},
	{E_CONTACT_CSV_EMAIL_4,		E_CONTACT_EMAIL_4,	   "", DT_STRING},
	{E_CONTACT_CSV_PHONE_PRIMARY,	E_CONTACT_PHONE_PRIMARY,   "", DT_STRING},
	{E_CONTACT_CSV_PHONE_ASSISTANT,	E_CONTACT_PHONE_ASSISTANT, "", DT_STRING},
	{E_CONTACT_CSV_PHONE_BUSINESS,	E_CONTACT_PHONE_BUSINESS,  "", DT_STRING},
	{E_CONTACT_CSV_PHONE_CALLBACK,	E_CONTACT_PHONE_CALLBACK,  "", DT_STRING},
	{E_CONTACT_CSV_PHONE_COMPANY,	E_CONTACT_PHONE_COMPANY,   "", DT_STRING},
	{E_CONTACT_CSV_PHONE_HOME,	E_CONTACT_PHONE_HOME,	   "", DT_STRING},
	{E_CONTACT_CSV_ORG,		E_CONTACT_ORG,		   "", DT_STRING},
	/*E_CONTACT_CSV_ADDRESS_BUSINESS, */
	{E_CONTACT_CSV_ADDRESS_BUSINESS_STREET,	  NOMAP, "Business Address",	      DT_STRING},
	{E_CONTACT_CSV_ADDRESS_BUSINESS_EXT,	  NOMAP, "Business Address2",         DT_STRING},
	{E_CONTACT_CSV_ADDRESS_BUSINESS_CITY,	  NOMAP, "Business Address City",     DT_STRING},
	{E_CONTACT_CSV_ADDRESS_BUSINESS_REGION,	  NOMAP, "Business Address State",    DT_STRING},
	{E_CONTACT_CSV_ADDRESS_BUSINESS_POSTCODE, NOMAP, "Business Address PostCode", DT_STRING},
	{E_CONTACT_CSV_ADDRESS_BUSINESS_COUNTRY,  NOMAP, "Business Address Country",  DT_STRING},
	/*E_CONTACT_CSV_ADDRESS_HOME, */
	{E_CONTACT_CSV_ADDRESS_HOME_STREET,   NOMAP, "Home Address",          DT_STRING},
	{E_CONTACT_CSV_ADDRESS_HOME_EXT,      NOMAP, "Home Address2",         DT_STRING},
	{E_CONTACT_CSV_ADDRESS_HOME_CITY,     NOMAP, "Home Address City",     DT_STRING},
	{E_CONTACT_CSV_ADDRESS_HOME_REGION,   NOMAP, "Home Address State",    DT_STRING},
	{E_CONTACT_CSV_ADDRESS_HOME_POSTCODE, NOMAP, "Home Address PostCode", DT_STRING},
	{E_CONTACT_CSV_ADDRESS_HOME_COUNTRY,  NOMAP, "Home Address Country",  DT_STRING},
	{E_CONTACT_CSV_PHONE_MOBILE,	      E_CONTACT_PHONE_MOBILE,       "", DT_STRING},
	{E_CONTACT_CSV_PHONE_CAR,	      E_CONTACT_PHONE_CAR,          "", DT_STRING},
	{E_CONTACT_CSV_PHONE_BUSINESS_FAX,    E_CONTACT_PHONE_BUSINESS_FAX, "", DT_STRING},
	{E_CONTACT_CSV_PHONE_HOME_FAX,        E_CONTACT_PHONE_HOME_FAX,     "", DT_STRING},
	{E_CONTACT_CSV_PHONE_BUSINESS_2,      E_CONTACT_PHONE_BUSINESS_2,   "", DT_STRING},
	{E_CONTACT_CSV_PHONE_HOME_2,          E_CONTACT_PHONE_HOME_2,       "", DT_STRING},
	{E_CONTACT_CSV_PHONE_ISDN,            E_CONTACT_PHONE_ISDN,         "", DT_STRING},
	{E_CONTACT_CSV_PHONE_OTHER,           E_CONTACT_PHONE_OTHER,        "", DT_STRING},
	{E_CONTACT_CSV_PHONE_OTHER_FAX,       E_CONTACT_PHONE_OTHER_FAX,    "", DT_STRING},
	{E_CONTACT_CSV_PHONE_PAGER,           E_CONTACT_PHONE_PAGER,        "", DT_STRING},
	{E_CONTACT_CSV_PHONE_RADIO,           E_CONTACT_PHONE_RADIO,        "", DT_STRING},
	{E_CONTACT_CSV_PHONE_TELEX,           E_CONTACT_PHONE_TELEX,        "", DT_STRING},
	{E_CONTACT_CSV_PHONE_TTYTDD,          E_CONTACT_PHONE_TTYTDD,       "", DT_STRING},
	/*E_CONTACT_CSV_ADDRESS_OTHER, */
	{E_CONTACT_CSV_ADDRESS_OTHER_STREET,   NOMAP, "Other Address",          DT_STRING},
	{E_CONTACT_CSV_ADDRESS_OTHER_EXT,      NOMAP, "Other Address2",         DT_STRING},
	{E_CONTACT_CSV_ADDRESS_OTHER_CITY,     NOMAP, "Other Address City",     DT_STRING},
	{E_CONTACT_CSV_ADDRESS_OTHER_REGION,   NOMAP, "Other Address State",    DT_STRING},
	{E_CONTACT_CSV_ADDRESS_OTHER_POSTCODE, NOMAP, "Other Address PostCode", DT_STRING},
	{E_CONTACT_CSV_ADDRESS_OTHER_COUNTRY,  NOMAP, "Other Address Country",  DT_STRING},
	{E_CONTACT_CSV_HOMEPAGE_URL,           E_CONTACT_HOMEPAGE_URL, "", DT_STRING},
	{E_CONTACT_CSV_ORG_UNIT,               E_CONTACT_ORG_UNIT,     "", DT_STRING},
	{E_CONTACT_CSV_OFFICE,                 E_CONTACT_OFFICE,       "", DT_STRING},
	{E_CONTACT_CSV_TITLE,                  E_CONTACT_TITLE,        "", DT_STRING},
	{E_CONTACT_CSV_ROLE,                   E_CONTACT_ROLE,         "", DT_STRING},
	{E_CONTACT_CSV_MANAGER,                E_CONTACT_MANAGER,      "", DT_STRING},
	{E_CONTACT_CSV_ASSISTANT,              E_CONTACT_ASSISTANT,    "", DT_STRING},
	{E_CONTACT_CSV_NICKNAME,               E_CONTACT_NICKNAME,     "", DT_STRING},
	{E_CONTACT_CSV_SPOUSE,                 E_CONTACT_SPOUSE,       "", DT_STRING},
	{E_CONTACT_CSV_NOTE,                   E_CONTACT_NOTE,         "", DT_STRING},
	{E_CONTACT_CSV_CALENDAR_URI,           E_CONTACT_CALENDAR_URI, "", DT_STRING},
	{E_CONTACT_CSV_FREEBUSY_URL,           E_CONTACT_FREEBUSY_URL, "", DT_STRING},
	/*E_CONTACT_ANNIVERSARY, */
	{E_CONTACT_CSV_ANNIVERSARY_YEAR,       NOMAP, "Anniversary Year",  DT_STRING},
	{E_CONTACT_CSV_ANNIVERSARY_MONTH,      NOMAP, "Anniversary Month", DT_STRING},
	{E_CONTACT_CSV_ANNIVERSARY_DAY,        NOMAP, "Anniversary Day",   DT_STRING},
	/*E_CONTACT_BIRTH_DATE, */
	{E_CONTACT_CSV_BIRTH_DATE_YEAR,  NOMAP, "Birth Year",  DT_STRING},
	{E_CONTACT_CSV_BIRTH_DATE_MONTH, NOMAP, "Birth Month", DT_STRING},
	{E_CONTACT_CSV_BIRTH_DATE_DAY,   NOMAP, "Birth Day",   DT_STRING},
	{E_CONTACT_CSV_MAILER,           E_CONTACT_MAILER,      "", DT_STRING},
	{E_CONTACT_CSV_NAME_OR_ORG,      E_CONTACT_NAME_OR_ORG, "", DT_STRING},
	{E_CONTACT_CSV_CATEGORIES,       E_CONTACT_CATEGORIES,  "", DT_STRING},
	{E_CONTACT_CSV_FAMILY_NAME,      E_CONTACT_FAMILY_NAME, "", DT_STRING},
	{E_CONTACT_CSV_GIVEN_NAME,       E_CONTACT_GIVEN_NAME,  "", DT_STRING},
	{E_CONTACT_CSV_WANTS_HTML,       E_CONTACT_WANTS_HTML,  "", DT_BOOLEAN},
	{E_CONTACT_CSV_IS_LIST,          E_CONTACT_IS_LIST,     "", DT_BOOLEAN},
	{E_CONTACT_CSV_MIDDLE_NAME,      NOMAP, "middle_name", DT_STRING},
	{E_CONTACT_CSV_NAME_TITLE,       NOMAP, "name_title", DT_STRING},
	{E_CONTACT_CSV_NAME_SUFFIX,      NOMAP, "name_suffix", DT_STRING},
	{E_CONTACT_CSV_LAST,             NOMAP,                 "", DT_STRING}

};

static GSList *pre_defined_fields;

static gchar *
escape_string (gchar *orig)
{
	const guchar *p;
	gchar *dest;
	gchar *q;

	if (orig == NULL)
		return g_strdup ("\"\"");

	p = (guchar *) orig;
	/* Each source byte needs maximally two destination chars (\n), and the extra 2 is for the leading and trailing '"' */
	q = dest = g_malloc (strlen (orig) * 2 + 1 + 2);

	*q++ = '\"';
	while (*p)
	{
		switch (*p)
		{
		case '\n':
			*q++ = '\\';
			*q++ = 'n';
			break;
		case '\r':
			*q++ = '\\';
			*q++ = 'r';
			break;
		case '\\':
			*q++ = '\\';
			*q++ = '\\';
			break;
		case '"':
			*q++ = '"';
			*q++ = '"';
			break;
		default:
			*q++ = *p;
		}
		p++;
	}

	*q++ = '\"';
	*q = 0;

	return dest;
}

static gchar *
check_null_pointer (gchar *orig)
{
	gchar *result;
	if (orig == NULL)
		result = g_strdup ("");
	else
		result = g_strdup (orig);
	return result;
}

static gchar *
delivery_address_get_sub_field (const EContactAddress *address,
                                DeliveryAddressField sub_field)
{
	gchar *sub_field_value;
	gchar *str_temp, *str_temp_a;
	if (address != NULL) {
		switch (sub_field) {
		case DELIVERY_ADDRESS_STREET:
			str_temp_a = check_null_pointer (address->po);
			str_temp = check_null_pointer (address->street);
			sub_field_value = g_strdup_printf ("%s %s", str_temp_a, str_temp);
			g_free (str_temp);
			g_free (str_temp_a);
			break;
		case DELIVERY_ADDRESS_EXT:
			sub_field_value = check_null_pointer (address->ext);
			break;
		case DELIVERY_ADDRESS_LOCALITY:
			sub_field_value = check_null_pointer (address->locality);
			break;
		case DELIVERY_ADDRESS_REGION:
			sub_field_value = check_null_pointer (address->region);
			break;
		case DELIVERY_ADDRESS_CODE:
			sub_field_value = check_null_pointer (address->code);
			break;
		case DELIVERY_ADDRESS_COUNTRY:
			sub_field_value = check_null_pointer (address->country);
			break;
		default:
			sub_field_value = g_strdup ("");
		}
	} else {
		sub_field_value = g_strdup ("");
	}
	return sub_field_value;
}

static gint
e_contact_csv_get_contact_field (EContactFieldCSV csv_field)
{
	return csv_field_data[csv_field].contact_field;
}

static EContactCSVDataType
e_contact_csv_get_data_type (EContactFieldCSV csv_field)
{
	return csv_field_data[csv_field].data_type;
}

static gchar *
e_contact_csv_get_name (EContactFieldCSV csv_field)
{
	gint contact_field;
	gchar *name;
	gchar *quoted_name;

	contact_field = e_contact_csv_get_contact_field (csv_field);

	if (contact_field != NOMAP) {
		name = g_strdup (e_contact_field_name (contact_field));
	} else {
		name = g_strdup (csv_field_data[csv_field].csv_name);
	}
	quoted_name = escape_string (name);
	g_free (name);
	return quoted_name;
}

static gchar *
e_contact_csv_get (EContact *contact,
                   EContactFieldCSV csv_field)
{
	gint contact_field;
	gchar *field_value = NULL;
	gchar *quoted_field_value;

	EContactAddress *delivery_address = NULL;
	EContactDate *date;
	EContactName *name;

	contact_field = e_contact_csv_get_contact_field (csv_field);

	if (contact_field != NOMAP) {
		field_value = e_contact_get (contact, contact_field);
		if (e_contact_csv_get_data_type (csv_field) == DT_BOOLEAN) {
			field_value = g_strdup ((GPOINTER_TO_INT (field_value)) ? "TRUE" : "FALSE");
		}
	} else {
		switch (csv_field) {
		case E_CONTACT_CSV_ADDRESS_HOME_STREET:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_HOME);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_STREET);
			break;
		case E_CONTACT_CSV_ADDRESS_HOME_EXT:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_HOME);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_EXT);
			break;
		case E_CONTACT_CSV_ADDRESS_HOME_CITY:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_HOME);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_LOCALITY);
			break;
		case E_CONTACT_CSV_ADDRESS_HOME_REGION:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_HOME);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_REGION);
			break;
		case E_CONTACT_CSV_ADDRESS_HOME_POSTCODE:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_HOME);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_CODE);
			break;
		case E_CONTACT_CSV_ADDRESS_HOME_COUNTRY:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_HOME);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_COUNTRY);
			break;
		case E_CONTACT_CSV_ADDRESS_BUSINESS_STREET:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_WORK);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_STREET);
			break;
		case E_CONTACT_CSV_ADDRESS_BUSINESS_EXT:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_WORK);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_EXT);
			break;
		case E_CONTACT_CSV_ADDRESS_BUSINESS_CITY:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_WORK);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_LOCALITY);
			break;
		case E_CONTACT_CSV_ADDRESS_BUSINESS_REGION:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_WORK);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_REGION);
			break;
		case E_CONTACT_CSV_ADDRESS_BUSINESS_POSTCODE:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_WORK);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_CODE);
			break;
		case E_CONTACT_CSV_ADDRESS_BUSINESS_COUNTRY:
			delivery_address = e_contact_get (contact, E_CONTACT_ADDRESS_WORK);
			field_value = delivery_address_get_sub_field (delivery_address, DELIVERY_ADDRESS_COUNTRY);
			break;
		case E_CONTACT_CSV_BIRTH_DATE_YEAR:
			date = e_contact_get (contact, E_CONTACT_BIRTH_DATE);
			if (date) {
				field_value = g_strdup_printf ("%04d", date->year);
				e_contact_date_free (date);
			}
			break;

		case E_CONTACT_CSV_BIRTH_DATE_MONTH:
			date = e_contact_get (contact, E_CONTACT_BIRTH_DATE);
			if (date) {
				field_value = g_strdup_printf ("%04d", date->month);
				e_contact_date_free (date);
			}
			break;

		case E_CONTACT_CSV_BIRTH_DATE_DAY:
			date = e_contact_get (contact, E_CONTACT_BIRTH_DATE);
			if (date) {
				field_value = g_strdup_printf ("%04d", date->day);
				e_contact_date_free (date);
			}
			break;
		case E_CONTACT_CSV_NAME_TITLE:
		case E_CONTACT_CSV_MIDDLE_NAME:
		case E_CONTACT_CSV_NAME_SUFFIX:
			field_value = NULL;
			name = e_contact_get (contact, E_CONTACT_NAME);
			if (name) {
				if (csv_field == E_CONTACT_CSV_NAME_TITLE)
					field_value = g_strdup (name->prefixes);
				else if (csv_field == E_CONTACT_CSV_MIDDLE_NAME)
					field_value = g_strdup (name->additional);
				else if (csv_field == E_CONTACT_CSV_NAME_SUFFIX)
					field_value = g_strdup (name->suffixes);

				e_contact_name_free (name);
			}
			break;

		default:
			break;
		}
	}

	/* checking to avoid the NULL pointer */
	if (field_value == NULL)
		field_value = g_strdup ("");

	quoted_field_value = escape_string (field_value);
	g_free (field_value);

	if (delivery_address)
		e_contact_address_free (delivery_address);

	return quoted_field_value;
}

static gchar *
e_contact_csv_get_header_line (GSList *csv_all_fields)
{

	guint field_number;
	gint csv_field;
	gchar **field_name_array;
	gchar *header_line;

	gint loop_counter;

	field_number = g_slist_length (csv_all_fields);
	field_name_array = g_new0 (gchar *, field_number + 1);

	for (loop_counter = 0; loop_counter < field_number; loop_counter++) {
		csv_field = GPOINTER_TO_INT (g_slist_nth_data (csv_all_fields, loop_counter));
		*(field_name_array + loop_counter) = e_contact_csv_get_name (csv_field);
	}

	header_line = g_strjoinv (COMMA_SEPARATOR, field_name_array);

	for (loop_counter = 0; loop_counter < field_number; loop_counter++) {
		g_free (*(field_name_array + loop_counter));
	}
	g_free (field_name_array);

	return header_line;

}

static gchar *
e_contact_to_csv (EContact *contact,
                  GSList *csv_all_fields)
{
	guint field_number;
	gint csv_field;
	gchar **field_value_array;
	gchar *aline;

	gint loop_counter;

	field_number = g_slist_length (csv_all_fields);
	field_value_array = g_new0 (gchar *, field_number + 1);

	for (loop_counter = 0; loop_counter < field_number; loop_counter++) {
		csv_field = GPOINTER_TO_INT (g_slist_nth_data (csv_all_fields, loop_counter));
		*(field_value_array + loop_counter) = e_contact_csv_get (contact, csv_field);
	}

	aline = g_strjoinv (COMMA_SEPARATOR, field_value_array);

	for (loop_counter = 0; loop_counter < field_number; loop_counter++) {
		g_free (*(field_value_array + loop_counter));
	}
	g_free (field_value_array);

	return aline;

}

static gchar *
e_contact_get_csv (EContact *contact,
                   GSList *csv_all_fields)
{
	gchar *aline;
	GList *emails;
	guint n_emails;
	gchar *full_name;

	emails = e_contact_get_attributes (contact, E_CONTACT_EMAIL);
	n_emails = g_list_length (emails);
	full_name = e_contact_get (contact, E_CONTACT_FULL_NAME);
	if (n_emails > 4)
		g_warning ("%s: only 4 out of %i emails have been exported", full_name, n_emails);
	g_free (full_name);
	g_list_free_full (emails, (GDestroyNotify) e_vcard_attribute_free);

	aline = e_contact_to_csv (contact, csv_all_fields);
	return aline;
}

static void
set_pre_defined_field (GSList **pre_defined_fields)
{
	*pre_defined_fields = NULL;

	#define add(x) *pre_defined_fields = g_slist_append (*pre_defined_fields, GINT_TO_POINTER (x))

	add (E_CONTACT_CSV_NAME_TITLE);
	add (E_CONTACT_CSV_GIVEN_NAME);
	add (E_CONTACT_CSV_MIDDLE_NAME);
	add (E_CONTACT_CSV_FAMILY_NAME);
	add (E_CONTACT_CSV_NAME_SUFFIX);
	add (E_CONTACT_CSV_FULL_NAME);
	add (E_CONTACT_CSV_NICKNAME);
	add (E_CONTACT_CSV_EMAIL_1);
	add (E_CONTACT_CSV_EMAIL_2);
	add (E_CONTACT_CSV_EMAIL_3);
	add (E_CONTACT_CSV_EMAIL_4);
	add (E_CONTACT_CSV_WANTS_HTML);
	add (E_CONTACT_CSV_PHONE_BUSINESS);
	add (E_CONTACT_CSV_PHONE_HOME);
	add (E_CONTACT_CSV_PHONE_BUSINESS_FAX);
	add (E_CONTACT_CSV_PHONE_PAGER);
	add (E_CONTACT_CSV_PHONE_MOBILE);
	add (E_CONTACT_CSV_ADDRESS_HOME_STREET);
	add (E_CONTACT_CSV_ADDRESS_HOME_EXT);
	add (E_CONTACT_CSV_ADDRESS_HOME_CITY);
	add (E_CONTACT_CSV_ADDRESS_HOME_REGION);
	add (E_CONTACT_CSV_ADDRESS_HOME_POSTCODE);
	add (E_CONTACT_CSV_ADDRESS_HOME_COUNTRY);
	add (E_CONTACT_CSV_ADDRESS_BUSINESS_STREET);
	add (E_CONTACT_CSV_ADDRESS_BUSINESS_EXT);
	add (E_CONTACT_CSV_ADDRESS_BUSINESS_CITY);
	add (E_CONTACT_CSV_ADDRESS_BUSINESS_REGION);
	add (E_CONTACT_CSV_ADDRESS_BUSINESS_POSTCODE);
	add (E_CONTACT_CSV_ADDRESS_BUSINESS_COUNTRY);
	add (E_CONTACT_CSV_TITLE);
	add (E_CONTACT_CSV_OFFICE);
	add (E_CONTACT_CSV_ORG);
	add (E_CONTACT_CSV_HOMEPAGE_URL);
	add (E_CONTACT_CSV_CALENDAR_URI);
	add (E_CONTACT_CSV_BIRTH_DATE_YEAR);
	add (E_CONTACT_CSV_BIRTH_DATE_MONTH);
	add (E_CONTACT_CSV_BIRTH_DATE_DAY);
	add (E_CONTACT_CSV_NOTE);

	#undef add
}

static gint
output_n_cards_file (FILE *outputfile,
                     GSList *contacts,
                     gint size,
                     gint begin_no,
                     CARD_FORMAT format)
{
	gint i;
	if (format == CARD_FORMAT_VCARD) {
		for (i = begin_no; i < size + begin_no; i++) {
			EContact *contact = g_slist_nth_data (contacts, i);
			gchar *vcard = e_vcard_to_string (E_VCARD (contact), EVC_FORMAT_VCARD_30);
			fprintf (outputfile, "%s\n", vcard);
			g_free (vcard);
		}
	} else if (format == CARD_FORMAT_CSV) {
		gchar *csv_fields_name;

		if (!pre_defined_fields)
			set_pre_defined_field (&pre_defined_fields);

		csv_fields_name = e_contact_csv_get_header_line (pre_defined_fields);
		fprintf (outputfile, "%s\n", csv_fields_name);
		g_free (csv_fields_name);

		for (i = begin_no; i < size + begin_no; i++) {
			EContact *contact = g_slist_nth_data (contacts, i);
			gchar *csv = e_contact_get_csv (contact, pre_defined_fields);
			fprintf (outputfile, "%s\n", csv);
			g_free (csv);
		}
	}

	return SUCCESS;

}

static void
action_list_cards (GSList *contacts,
                   ActionContext *p_actctx)
{
	FILE *outputfile;
	long length;
	CARD_FORMAT format;

	length = g_slist_length (contacts);

	if (length <= 0) {
		g_warning ("Couldn't load addressbook correctly!!!! %s####", p_actctx->addressbook_source_uid ?
				p_actctx->addressbook_source_uid : "NULL");
		exit (-1);
	}

	if (p_actctx->output_file == NULL) {
		outputfile = stdout;
	} else {
		/* fopen output file */
		if (!(outputfile = g_fopen (p_actctx->output_file, "w"))) {
			g_warning (_("Can not open file"));
			exit (-1);
		}
	}

	if (p_actctx->IsVCard == TRUE)
		format = CARD_FORMAT_VCARD;
	else
		format = CARD_FORMAT_CSV;

	output_n_cards_file (outputfile, contacts, length, 0, format);

	if (p_actctx->output_file != NULL) {
		fclose (outputfile);
	}
}

static void
action_list_cards_init (ActionContext *p_actctx)
{
	ESourceRegistry *registry;
	EClient *client;
	EBookClient *book_client;
	EBookQuery *query;
	ESource *source;
	GSList *contacts = NULL;
	const gchar *uid;
	gchar *query_str;
	GError *error = NULL;

	registry = p_actctx->registry;
	uid = p_actctx->addressbook_source_uid;

	if (uid != NULL)
		source = e_source_registry_ref_source (registry, uid);
	else
		source = e_source_registry_ref_default_address_book (registry);

	if (!source) {
		g_warning (
			"Couldn't load addressbook %s: Addressbook doesn't exist",
			p_actctx->addressbook_source_uid ?
			p_actctx->addressbook_source_uid :
			"'default'");
		exit (-1);
	}

	client = e_book_client_connect_sync (source, 30, NULL, &error);

	g_object_unref (source);

	/* Sanity check. */
	g_return_if_fail (
		((client != NULL) && (error == NULL)) ||
		((client == NULL) && (error != NULL)));

	if (error != NULL) {
		g_warning (
			"Couldn't load addressbook %s: %s",
			p_actctx->addressbook_source_uid ?
			p_actctx->addressbook_source_uid :
			"'default'", error->message);
		g_error_free (error);
		exit (-1);
	}

	book_client = E_BOOK_CLIENT (client);

	query = e_book_query_any_field_contains ("");
	query_str = e_book_query_to_string (query);
	e_book_query_unref (query);

	if (e_book_client_get_contacts_sync (book_client, query_str, &contacts, NULL, &error)) {
		action_list_cards (contacts, p_actctx);
		g_slist_free_full (contacts, g_object_unref);
	}

	g_object_unref (book_client);

	if (error != NULL) {
		g_warning ("Failed to get contacts: %s", error->message);
		g_error_free (error);
	}
}

static gboolean
call_main_loop_quit_idle_cb (gpointer user_data)
{
	g_main_loop_quit (user_data);

	return FALSE;
}

static gpointer
addressbook_export_thread (gpointer user_data)
{
	ActionContext *actctx = user_data;

	g_return_val_if_fail (actctx != NULL, NULL);

	/* do actions */
	if (actctx->action_type == ACTION_LIST_FOLDERS) {
		action_list_folders_init (actctx);

	} else if (actctx->action_type == ACTION_LIST_CARDS) {
		action_list_cards_init (actctx);

	} else {
		g_warning (_("Unhandled error"));
		exit (-1);
	}

	g_idle_add (call_main_loop_quit_idle_cb, actctx->main_loop);

	return NULL;
}

static gboolean
addressbook_export_start_idle (gpointer user_data)
{
	ActionContext *actctx = user_data;
	GThread *thread;

	g_return_val_if_fail (actctx != NULL, FALSE);

	thread = g_thread_new (NULL, addressbook_export_thread, actctx);
	g_thread_unref (thread);

	return FALSE;
}

/* Command-Line Options */
static gchar *opt_output_file = NULL;
static gboolean opt_list_folders_mode = FALSE;
static gchar *opt_output_format = NULL;
static gchar *opt_addressbook_source_uid = NULL;
static gchar **opt_remaining = NULL;

static GOptionEntry entries[] = {
	{ "output", '\0', 0,
	  G_OPTION_ARG_STRING, &opt_output_file,
	  N_("Specify the output file instead of standard output"),
	  N_("OUTPUTFILE") },
	{ "list-addressbook-folders", 'l', 0,
	  G_OPTION_ARG_NONE, &opt_list_folders_mode,
	  N_("List local address book folders") },
	{ "format", '\0', 0,
	  G_OPTION_ARG_STRING, &opt_output_format,
	  N_("Show cards as vcard or csv file"),
	  N_("[vcard|csv]") },
	{ G_OPTION_REMAINING, '\0', 0,
	  G_OPTION_ARG_STRING_ARRAY, &opt_remaining },
	{ NULL }
};

gint
main (gint argc,
      gchar **argv)
{
	ActionContext actctx;
	GOptionContext *context;
	GError *error = NULL;
	gint IsCSV = FALSE;
	gint IsVCard = FALSE;

#ifdef G_OS_WIN32
	e_util_win32_initialize ();
#endif

	setlocale (LC_ALL, "");
	bindtextdomain (GETTEXT_PACKAGE, LOCALEDIR);
	bind_textdomain_codeset (GETTEXT_PACKAGE, "UTF-8");
	textdomain (GETTEXT_PACKAGE);

	context = g_option_context_new (NULL);
	g_option_context_add_main_entries (context, entries, GETTEXT_PACKAGE);
	if (!g_option_context_parse (context, &argc, &argv, &error)) {
		g_printerr ("%s\n", error->message);
		g_error_free (error);
		exit (-1);
	}

	actctx.action_type = ACTION_NOTHING;
	actctx.registry = e_source_registry_new_sync (NULL, &error);
	if (error != NULL) {
		g_printerr ("%s\n", error->message);
		g_error_free (error);
		exit (-1);
	}

	/* Parsing Parameter */
	if (opt_remaining && g_strv_length (opt_remaining) > 0)
		opt_addressbook_source_uid = g_strdup (opt_remaining[0]);

	if (opt_list_folders_mode) {
		actctx.action_type = ACTION_LIST_FOLDERS;
		if (opt_addressbook_source_uid != NULL || opt_output_format != NULL) {
			g_warning (_("Command line arguments error, please use --help option to see the usage."));
			exit (-1);
		}
	} else {

		actctx.action_type = ACTION_LIST_CARDS;

		/* check the output format */
		if (opt_output_format == NULL) {
			IsVCard = TRUE;
		} else {
			IsCSV = !strcmp (opt_output_format, "csv");
			IsVCard = !strcmp (opt_output_format, "vcard");
			if (IsCSV == FALSE && IsVCard == FALSE) {
				g_warning (_("Only support csv or vcard format."));
				exit (-1);
			}
		}
	}

	actctx.output_file = opt_output_file;
	actctx.IsCSV = IsCSV;
	actctx.IsVCard = IsVCard;
	actctx.addressbook_source_uid = opt_addressbook_source_uid;

	g_idle_add (addressbook_export_start_idle, &actctx);

	actctx.main_loop = g_main_loop_new (NULL, FALSE);

	g_main_loop_run (actctx.main_loop);

	g_object_unref (actctx.registry);
	g_main_loop_unref (actctx.main_loop);

	return 0;
}
