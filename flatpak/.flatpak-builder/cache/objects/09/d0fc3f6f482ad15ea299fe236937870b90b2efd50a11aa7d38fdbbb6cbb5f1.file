/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */

/*
 * e-destination.c
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
 * Authors: Jon Trowbridge <trow@ximian.com>
 *          Chris Toshok <toshok@ximian.com>
 */

/*
 * We should probably make most of the functions in this file a little
 * stupider..  all the work extracting useful info from the
 * EContact/raw text/etc should happen in e_destination_set_contact
 * (and the other setters), not in a bunch of if's in the respective
 * _get_*() functions.
 */

#include "evolution-data-server-config.h"

#include "e-destination.h"

#include <stdlib.h>
#include <ctype.h>
#include <string.h>
#include <libebook/e-book.h>

#include <libxml/xmlmemory.h>
#include <glib/gi18n-lib.h>
#include <camel/camel.h>

#define d(x)

#define E_DESTINATION_GET_PRIVATE(obj) \
	(G_TYPE_INSTANCE_GET_PRIVATE \
	((obj), E_TYPE_DESTINATION, EDestinationPrivate))

G_DEFINE_TYPE (EDestination, e_destination, G_TYPE_OBJECT)

struct _EDestinationPrivate {
	gchar *raw;

	gchar *source_uid;

	EContact *contact;
	gchar *contact_uid;

	gint email_num;

	gchar *name;
	gchar *email;
	gchar *addr;
	gchar *textrep;
	gboolean ignored;

	GList *list_dests;
	GList *list_alldests;

	guint html_mail_override : 1;
	guint wants_html_mail : 1;

	guint show_addresses : 1;

	guint auto_recipient : 1;
};

static gboolean       e_destination_from_contact       (const EDestination *);
static xmlNodePtr     e_destination_xml_encode         (const EDestination *dest);
static gboolean       e_destination_xml_decode         (EDestination *dest, xmlNodePtr node);
static void           e_destination_clear              (EDestination *dest);

/* Signals */

enum {
	CHANGED,
	LAST_SIGNAL
};

enum CONTACT_TYPE {
	NONE,
	CONTACT,
	CONTACT_LIST
};

static guint signals[LAST_SIGNAL] = { 0 };

/* Copied from eab-book-util.c. The name selector also keeps its own copy... */
static gint
utf8_casefold_collate_len (const gchar *str1,
                           const gchar *str2,
                           gint len)
{
	gchar *s1 = g_utf8_casefold (str1, len);
	gchar *s2 = g_utf8_casefold (str2, len);
	gint rv;

	rv = g_utf8_collate (s1, s2);

	g_free (s1);
	g_free (s2);

	return rv;
}

/* Copied from eab-book-util.c. The name selector also keeps its own copy... */
static gint
utf8_casefold_collate (const gchar *str1,
                       const gchar *str2)
{
	return utf8_casefold_collate_len (str1, str2, -1);
}

static void
destination_finalize (GObject *object)
{
	EDestinationPrivate *priv;

	priv = E_DESTINATION_GET_PRIVATE (object);

	e_destination_clear (E_DESTINATION (object));

	g_free (priv->source_uid);

	/* Chain up to parent's finalize() method. */
	G_OBJECT_CLASS (e_destination_parent_class)->finalize (object);
}

static void
e_destination_class_init (EDestinationClass *class)
{
	GObjectClass *object_class;

	g_type_class_add_private (class, sizeof (EDestinationPrivate));

	object_class = G_OBJECT_CLASS (class);
	object_class->finalize = destination_finalize;

	signals[CHANGED] = g_signal_new (
		"changed",
		G_OBJECT_CLASS_TYPE (object_class),
		G_SIGNAL_RUN_LAST,
		G_STRUCT_OFFSET (EDestinationClass, changed),
		NULL, NULL, NULL,
		G_TYPE_NONE, 0);
}

static void
e_destination_init (EDestination *dest)
{
	dest->priv = E_DESTINATION_GET_PRIVATE (dest);
}

/**
 * e_destination_new:
 *
 * Creates a new #EDestination with blank values.
 *
 * Returns: A newly created #EDestination.
 **/
EDestination *
e_destination_new (void)
{
	return g_object_new (E_TYPE_DESTINATION, NULL);
}

/**
 * e_destination_copy:
 * @dest: an #EDestination
 *
 * Creates a new #EDestination identical to @dest.
 *
 * Returns: (transfer full): A newly created #EDestination, identical to @dest.
 */
EDestination *
e_destination_copy (const EDestination *dest)
{
	EDestination *new_dest;
	GList *iter;

	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	new_dest = e_destination_new ();

	new_dest->priv->source_uid = g_strdup (dest->priv->source_uid);
	new_dest->priv->contact_uid = g_strdup (dest->priv->contact_uid);
	new_dest->priv->name = g_strdup (dest->priv->name);
	new_dest->priv->email = g_strdup (dest->priv->email);
	new_dest->priv->addr = g_strdup (dest->priv->addr);
	new_dest->priv->email_num = dest->priv->email_num;
	new_dest->priv->ignored = dest->priv->ignored;

	if (dest->priv->contact)
		new_dest->priv->contact = g_object_ref (dest->priv->contact);

	new_dest->priv->html_mail_override = dest->priv->html_mail_override;
	new_dest->priv->wants_html_mail = dest->priv->wants_html_mail;

	/* deep copy, recursively copy our children */
	for (iter = dest->priv->list_dests; iter != NULL; iter = g_list_next (iter)) {
		new_dest->priv->list_dests = g_list_append (
			new_dest->priv->list_dests,
			e_destination_copy (E_DESTINATION (iter->data)));
	}

	/* XXX other settings? */
	new_dest->priv->raw = g_strdup (dest->priv->raw);

	return new_dest;
}

static void
e_destination_clear (EDestination *dest)
{
	g_free (dest->priv->contact_uid);
	dest->priv->contact_uid = NULL;

	g_free (dest->priv->raw);
	dest->priv->raw = NULL;

	g_free (dest->priv->name);
	dest->priv->name = NULL;

	g_free (dest->priv->email);
	dest->priv->email = NULL;

	g_free (dest->priv->addr);
	dest->priv->addr = NULL;

	g_free (dest->priv->textrep);
	dest->priv->textrep = NULL;

	if (dest->priv->contact) {
		g_object_unref (dest->priv->contact);
		dest->priv->contact = NULL;
	}
	dest->priv->email_num = -1;

	g_list_foreach (dest->priv->list_dests, (GFunc) g_object_unref, NULL);
	g_list_free (dest->priv->list_dests);
	dest->priv->list_dests = NULL;
	g_list_free (dest->priv->list_alldests);
	dest->priv->list_alldests = NULL;
}

static gboolean
nonempty (const gchar *s)
{
	gunichar c;
	if (s == NULL)
		return FALSE;
	while (*s) {
		c = g_utf8_get_char (s);
		if (!g_unichar_isspace (c))
			return TRUE;
		s = g_utf8_next_char (s);
	}
	return FALSE;
}

/**
 * e_destination_empty:
 * @dest: an #EDestination
 *
 * Checks if @dest is blank.
 *
 * Returns: %TRUE if @dest is empty, %FALSE otherwise.
 */
gboolean
e_destination_empty (const EDestination *dest)

{
	EDestinationPrivate *p;

	g_return_val_if_fail (E_IS_DESTINATION (dest), TRUE);

	p = dest->priv;

	return !(p->contact != NULL
		 || (p->source_uid && *p->source_uid)
		 || (p->contact_uid && *p->contact_uid)
		 || (nonempty (p->raw))
		 || (nonempty (p->name))
		 || (nonempty (p->email))
		 || (nonempty (p->addr))
		 || (p->list_dests != NULL));
}

/**
 * e_destination_equal:
 * @a: an #EDestination
 * @b: an #EDestination
 *
 * Checks if @a and @b are equal.
 *
 * Returns: %TRUE if the destinations are equal, %FALSE otherwise.
 **/
gboolean
e_destination_equal (const EDestination *a,
                     const EDestination *b)
{
	const EDestinationPrivate *pa, *pb;
	const gchar *na, *nb;

	g_return_val_if_fail (E_IS_DESTINATION (a), FALSE);
	g_return_val_if_fail (E_IS_DESTINATION (b), FALSE);

	if (a == b)
		return TRUE;

	pa = a->priv;
	pb = b->priv;

	/* Check equality of contacts. */
	if (pa->contact || pb->contact) {
		if (!(pa->contact && pb->contact))
			return FALSE;

		if (pa->contact == pb->contact || !strcmp (e_contact_get_const (pa->contact, E_CONTACT_UID),
							   e_contact_get_const (pb->contact, E_CONTACT_UID)))
			return TRUE;

		return FALSE;
	}

	/* Just in case name returns NULL */
	na = e_destination_get_name (a);
	nb = e_destination_get_name (b);
	if ((na || nb) && !(na && nb && !utf8_casefold_collate (na, nb)))
		return FALSE;

	if (!g_ascii_strcasecmp (e_destination_get_email (a), e_destination_get_email (b)))
		return TRUE;
	else
		return FALSE;
}

static void
remove_empty_subgroups (EDestination *dest,
			GHashTable *lists_hash)
{
	EDestination *s_dest;
	GSList *to_remove = NULL, *siter;
	GList *iter;

	if (!dest)
		return;

	for (iter = dest->priv->list_dests; iter; iter = g_list_next (iter)) {
		s_dest = iter->data;

		remove_empty_subgroups (s_dest, lists_hash);

		if (g_hash_table_lookup (lists_hash, s_dest) &&
		    !s_dest->priv->list_dests)
			to_remove = g_slist_prepend (to_remove, s_dest);
	}

	for (siter = to_remove; siter; siter = g_slist_next (siter)) {
		s_dest = siter->data;

		dest->priv->list_dests = g_list_remove (dest->priv->list_dests, s_dest);
		dest->priv->list_alldests = g_list_remove (dest->priv->list_alldests, s_dest);
	}

	g_slist_free_full (to_remove, g_object_unref);
}

/**
 * e_destination_set_contact:
 * @dest: an #EDestination
 * @contact: an #EContact
 * @email_num: an email index
 *
 * Sets @dest to point to one of @contact's e-mail addresses
 * indicated by @email_num.
 **/
void
e_destination_set_contact (EDestination *dest,
                           EContact *contact,
                           gint email_num)
{
	g_return_if_fail (dest && E_IS_DESTINATION (dest));
	g_return_if_fail (contact && E_IS_CONTACT (contact));

	if (dest->priv->contact != contact ) {

		e_destination_clear (dest);

		dest->priv->contact = e_contact_duplicate (contact);

		dest->priv->contact_uid = e_contact_get (dest->priv->contact, E_CONTACT_UID);

		dest->priv->email_num = email_num;

		dest->priv->ignored = FALSE;

		/* handle the mailing list case */
		if (e_contact_get (dest->priv->contact, E_CONTACT_IS_LIST)) {
			gint list_length;
			GList *attr, *attrs;
			GHashTable *hash_table, *lists_hash;
			gint list_iterations = 0;
			gint lists_count = 0;

			hash_table = g_hash_table_new_full (
				g_str_hash, g_str_equal,
				(GDestroyNotify) g_free, NULL);
			lists_hash = g_hash_table_new (g_direct_hash, g_direct_equal);

			g_hash_table_insert (hash_table, g_strdup ("0"), dest);

			e_destination_set_name (
				dest,
				e_contact_get_const (
					dest->priv->contact,
					E_CONTACT_FILE_AS));

			attrs = g_list_copy (e_vcard_get_attributes (E_VCARD (dest->priv->contact)));
			list_length = g_list_length (attrs);

			attr = attrs;
			while (list_length) {
				EDestination *parent_dest;
				gint type;
				gboolean remove = FALSE; /* Can item be removed from attrs list? */

				GList *params, *param, *value;
				const gchar *parent_id;

				param = e_vcard_attribute_get_param (attr->data, EVC_PARENT_CL);
				if (param)
					parent_id = param->data;
				else
					parent_id = "0";

				/* This is so just that we don't have to call g_ascii_strcasecmp more times */
				if (g_ascii_strcasecmp (EVC_CONTACT_LIST, e_vcard_attribute_get_name (attr->data)) == 0) {
					lists_count++;
					type = CONTACT_LIST;
				} else if (g_ascii_strcasecmp (EVC_EMAIL, e_vcard_attribute_get_name (attr->data)) == 0) {
					type = CONTACT;
				} else {
					type = NONE;
					remove = TRUE;
				}

				/* Is parent of current attribute already in the tree? */
				parent_dest = g_hash_table_lookup (hash_table, parent_id);
				/* Make sure that when parent with parent_id does not exist the item will be appended to root
				 * destination. */
				if (parent_dest == NULL && lists_count == 0 && list_iterations > 0) {
					parent_id = "0";
					parent_dest = dest;
				}
				if (type != NONE && parent_dest) {
					gchar *id = NULL;
					gint set_email_num = 0;
					EDestination *s_dest;

					s_dest = e_destination_new ();
					s_dest->priv->ignored = FALSE;

					params = e_vcard_attribute_get_params (attr->data);
					for (param = params; param; param = param->next) {
						const gchar *param_name = e_vcard_attribute_param_get_name (param->data);
						if ((g_ascii_strcasecmp (param_name, EVC_CL_UID) == 0) ||
						    (g_ascii_strcasecmp (param_name, EVC_X_DEST_CONTACT_UID) == 0)) {
							value = e_vcard_attribute_param_get_values (param->data);
							id = value ? g_strdup (value->data) : NULL;
						} else if (g_ascii_strcasecmp (param_name, EVC_X_DEST_EMAIL_NUM) == 0) {
							value = e_vcard_attribute_param_get_values (param->data);
							set_email_num = value ? atoi (value->data) : -1;
						} else if (!g_ascii_strcasecmp (param_name, EVC_X_DEST_HTML_MAIL)) {
							value = e_vcard_attribute_param_get_values (param->data);
							e_destination_set_html_mail_pref (s_dest, value ? !g_ascii_strcasecmp (value->data, "true") : FALSE);
						}
					}

					if (type == CONTACT) {
						CamelInternetAddress *addr;
						const gchar *name, *email;
						gchar *raw;

						raw = e_vcard_attribute_get_value (attr->data);
						addr = camel_internet_address_new ();
						if (camel_address_unformat (CAMEL_ADDRESS (addr), raw) > 0 &&
						    camel_internet_address_get (addr, 0, &name, &email)) {
							e_destination_set_name (s_dest, name);
							e_destination_set_email (s_dest, email);

							dest->priv->list_alldests = g_list_append (dest->priv->list_alldests, s_dest);
						}

						g_object_unref (addr);
						g_free (raw);
					} else {
						gchar *name = e_vcard_attribute_get_value (attr->data);
						e_destination_set_name (s_dest, name);
						g_free (name);

						if (id)
							g_hash_table_insert (hash_table, g_strdup (id), s_dest);
						lists_count--;

						g_hash_table_insert (lists_hash, s_dest, GINT_TO_POINTER (1));
					}

					if (id) {
						e_destination_set_contact_uid (s_dest, id, set_email_num);
						g_free (id);
					}

					parent_dest->priv->list_dests = g_list_append (parent_dest->priv->list_dests, s_dest);

					remove = TRUE;
				}

				/* Go to next attribute */
				if (attr->next) {
					attr = attr->next;
					if (remove) {
						attrs = g_list_delete_link (attrs, attr->prev);
						list_length--;
					}
					continue;
				/* Or return to first attribute */
				} else if (attrs) {
					if (remove) {
						attrs = g_list_delete_link (attrs, attr);
						list_length--;
					}
					attr = attrs;
					list_iterations++;
					continue;
				/* When all attribute are processed, leave. */
				} else {
					break;
				}
			}

			remove_empty_subgroups (dest, lists_hash);

			g_hash_table_unref (lists_hash);
			g_hash_table_unref (hash_table);
			g_list_free (attrs);
		} else {
			/* handle the normal contact case */
			/* is there anything to do here? */
		}

		g_signal_emit (dest, signals[CHANGED], 0);
	} else if (dest->priv->email_num != email_num) {
		/* Splitting here would help the contact lists not rebuiding, so that it remembers ignored values */

		/* increase ref counter, because e_destination_clear calls g_object_unref, but we want to keep the contact */
		g_object_ref (contact);

		e_destination_clear (dest);

		dest->priv->contact = contact;

		dest->priv->contact_uid = e_contact_get (dest->priv->contact, E_CONTACT_UID);

		dest->priv->email_num = email_num;

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

/**
 * e_destination_set_book:
 * @dest: an #EDestination
 * @book: an #EBook
 *
 * Specify the source @dest's contact comes from. This is useful
 * if you need to update the contact later.
 *
 * Deprecated: 3.2: Use e_destination_set_client() instead.
 **/
void
e_destination_set_book (EDestination *dest,
                        EBook *book)
{
	ESource *source;
	const gchar *uid;

	g_return_if_fail (dest && E_IS_DESTINATION (dest));
	g_return_if_fail (book && E_IS_BOOK (book));

	source = e_book_get_source (book);
	uid = e_source_get_uid (source);
	g_return_if_fail (uid != NULL);

	if (!dest->priv->source_uid || strcmp (uid, dest->priv->source_uid)) {
		g_free (dest->priv->source_uid);
		dest->priv->source_uid = g_strdup (uid);

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

/**
 * e_destination_set_client:
 * @dest: an #EDestination
 * @client: an #EBookClient
 *
 * Specify the source @dest's contact comes from. This is useful
 * if you need to update the contact later.
 *
 * Since: 3.2
 **/
void
e_destination_set_client (EDestination *dest,
                          EBookClient *client)
{
	ESource *source;
	const gchar *uid;

	g_return_if_fail (dest && E_IS_DESTINATION (dest));
	g_return_if_fail (client && E_IS_BOOK_CLIENT (client));

	source = e_client_get_source (E_CLIENT (client));
	uid = e_source_get_uid (source);
	g_return_if_fail (uid != NULL);

	if (!dest->priv->source_uid || strcmp (uid, dest->priv->source_uid)) {
		g_free (dest->priv->source_uid);
		dest->priv->source_uid = g_strdup (uid);

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

/**
 * e_destination_set_contact_uid:
 * @dest: an #EDestination
 * @uid: a unique contact ID
 * @email_num: an email index
 *
 * Sets @dest to point to one of the contact specified by @uid's e-mail
 * addresses indicated by @email_num.
 **/
void
e_destination_set_contact_uid (EDestination *dest,
                               const gchar *uid,
                               gint email_num)
{
	g_return_if_fail (dest && E_IS_DESTINATION (dest));
	g_return_if_fail (uid != NULL);

	if (dest->priv->contact_uid == NULL
	    || strcmp (dest->priv->contact_uid, uid)
	    || dest->priv->email_num != email_num) {

		g_free (dest->priv->contact_uid);
		dest->priv->contact_uid = g_strdup (uid);
		dest->priv->email_num = email_num;

		/* If we already have a contact, remove it unless it's uid matches the one
		 * we just set. */
		if (dest->priv->contact && strcmp (uid,
						   e_contact_get_const (dest->priv->contact, E_CONTACT_UID))) {
			g_object_unref (dest->priv->contact);
			dest->priv->contact = NULL;
		}

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

static void
e_destination_set_source_uid (EDestination *dest,
                              const gchar *uid)
{
	g_return_if_fail (dest && E_IS_DESTINATION (dest));
	g_return_if_fail (uid != NULL);

	if (dest->priv->source_uid == NULL
	    || strcmp (dest->priv->source_uid, uid)) {

		g_free (dest->priv->source_uid);
		dest->priv->source_uid = g_strdup (uid);

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

/**
 * e_destination_set_name:
 * @dest: an #EDestination
 * @name: the destination's full name
 *
 * Sets the full name of @dest's addressee.
 **/
void
e_destination_set_name (EDestination *dest,
                        const gchar *name)
{
	gboolean changed = FALSE;

	g_return_if_fail (E_IS_DESTINATION (dest));

	if (name == NULL) {
		if (dest->priv->name != NULL) {
			g_free (dest->priv->name);
			dest->priv->name = NULL;
			changed = TRUE;
		}
	} else if (dest->priv->name == NULL || strcmp (dest->priv->name, name)) {
		g_free (dest->priv->name);
		dest->priv->name = g_strdup (name);
		changed = TRUE;
	}

	if (changed) {
		g_free (dest->priv->addr);
		dest->priv->addr = NULL;
		g_free (dest->priv->textrep);
		dest->priv->textrep = NULL;

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

/**
 * e_destination_set_email:
 * @dest: an #EDestination
 * @email: the destination's e-mail address
 *
 * Sets the e-mail address of @dest's addressee.
 **/
void
e_destination_set_email (EDestination *dest,
                         const gchar *email)
{
	gboolean changed = FALSE;

	g_return_if_fail (E_IS_DESTINATION (dest));

	if (email == NULL) {
		if (dest->priv->email != NULL) {
			g_free (dest->priv->addr);
			dest->priv->addr = NULL;
			changed = TRUE;
		}
	} else if (dest->priv->email == NULL || strcmp (dest->priv->email, email)) {
		g_free (dest->priv->email);
		dest->priv->email = g_strdup (email);
		changed = TRUE;
	}

	if (changed) {
		g_free (dest->priv->addr);
		dest->priv->addr = NULL;
		g_free (dest->priv->textrep);
		dest->priv->textrep = NULL;

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

static gboolean
e_destination_from_contact (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), FALSE);
	return dest->priv->contact != NULL || dest->priv->source_uid != NULL || dest->priv->contact_uid != NULL;
}

/**
 * e_destination_is_auto_recipient:
 * @dest: an #EDestination
 *
 * Checks if @dest is flagged as an automatic recipient, meaning
 * it was not explicitly specified by the user. This can be used
 * to hide it from some UI elements.
 *
 * Returns: %TRUE if destination is an auto recipient, %FALSE otherwise.
 **/
gboolean
e_destination_is_auto_recipient (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), FALSE);

	return dest->priv->auto_recipient;
}

/**
 * e_destination_set_auto_recipient:
 * @dest: an #EDestination
 * @value: the auto recipient flag
 *
 * Sets the flag indicating if @dest is an automatic recipient, meaning
 * it was not explicitly specified by the user. This can be used
 * to hide it from some UI elements.
 **/
void
e_destination_set_auto_recipient (EDestination *dest,
                                  gboolean value)
{
	g_return_if_fail (dest && E_IS_DESTINATION (dest));

	dest->priv->auto_recipient = value;

	g_signal_emit (dest, signals[CHANGED], 0);
}

/**
 * e_destination_get_contact:
 * @dest: an #EDestination
 *
 * Gets the contact @dest is pointing to, if any.
 *
 * Returns: (transfer none) (nullable): An #EContact, or %NULL if none was set.
 **/
EContact *
e_destination_get_contact (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	return dest->priv->contact;
}

/**
 * e_destination_get_contact_uid:
 * @dest: an #EDestination
 *
 * Gets the unique contact ID @dest is pointing to, if any.
 *
 * Returns: (nullable): A unique contact ID, or %NULL if none was set.
 */
const gchar *
e_destination_get_contact_uid (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	return dest->priv->contact_uid;
}

/**
 * e_destination_get_source_uid:
 * @dest: an #EDestination
 *
 * Gets the unique source ID @dest is pointing to, if any. The source
 * ID specifies which address book @dest's contact came from.
 *
 * Returns: (nullable): A unique source ID, or %NULL if none was set.
 */
const gchar *
e_destination_get_source_uid (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	return dest->priv->source_uid;
}

/**
 * e_destination_get_email_num:
 * @dest: an #EDestination
 *
 * Gets the index of the e-mail address of the contact that
 * @dest is pointing to, if any.
 *
 * Returns: The e-mail index, or -1 if none was set.
 **/
gint
e_destination_get_email_num (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), -1);

	if (dest->priv->contact == NULL && (dest->priv->source_uid == NULL || dest->priv->contact_uid == NULL))
		return -1;

	return dest->priv->email_num;
}

/**
 * e_destination_get_name:
 * @dest: an #EDestination
 *
 * Gets the full name of @dest's addressee, or if the addressee is
 * a contact list, the name the list was filed under.
 *
 * Returns: (nullable): The full name of the addressee, or %NULL if none was set.
 **/
const gchar *
e_destination_get_name (const EDestination *dest)
{
	EDestinationPrivate *priv;

	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	priv = (EDestinationPrivate *) dest->priv; /* cast out const */

	if (priv->name == NULL) {
		if (priv->contact != NULL) {
			priv->name = e_contact_get (priv->contact, E_CONTACT_FULL_NAME);

			if (priv->name == NULL || *priv->name == '\0') {
				g_free (priv->name);
				priv->name = e_contact_get (priv->contact, E_CONTACT_FILE_AS);
			}

			if (priv->name == NULL || *priv->name == '\0') {
				g_free (priv->name);
				if (e_contact_get (priv->contact, E_CONTACT_IS_LIST))
					priv->name = g_strdup (_("Unnamed List"));
				else
					priv->name = g_strdup (e_destination_get_email (dest));
			}
		}
		else if (priv->raw != NULL) {
			CamelInternetAddress *addr = camel_internet_address_new ();

			if (camel_address_unformat (CAMEL_ADDRESS (addr), priv->raw)) {
				const gchar *camel_name = NULL;

				if (camel_internet_address_get (addr, 0, &camel_name, NULL))
					priv->name = g_strdup (camel_name);
			}

			g_object_unref (addr);
		}
	}

	return priv->name;
}

/**
 * e_destination_is_ignored:
 * @dest: an #EDestination
 *
 * Check if @dest is to be ignored.
 *
 * Returns: %TRUE if this destination should be ignored, else %FALSE.
 */
gboolean
e_destination_is_ignored (const EDestination *dest)
{
	return dest->priv->ignored;
}

/**
 * e_destination_set_ignored:
 * @dest: an #EDestination
 * @ignored: %TRUE if this #EDestination should be ignored.
 *
 * Set the ignore flag on a #EDestination.
 */
void
e_destination_set_ignored (EDestination *dest,
                           gboolean ignored)
{
	dest->priv->ignored = ignored;
}

/**
 * e_destination_get_email:
 * @dest: an #EDestination
 *
 * Gets the e-mail address of @dest's addressee.
 *
 * Returns: An e-mail address, or an empty string if none was set.
 **/
const gchar *
e_destination_get_email (const EDestination *dest)
{
	EDestinationPrivate *priv;

	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	priv = (EDestinationPrivate *) dest->priv; /* cast out const */

	if (priv->email == NULL) {
		if (priv->contact != NULL) {
			/* Pull the address out of the card. */
			GList *email = e_contact_get (priv->contact, E_CONTACT_EMAIL);
			if (email) {
				gchar *e = g_list_nth_data (email, priv->email_num);

				if (e)
					priv->email = g_strdup (e);
			}
			if (email) {
				g_list_foreach (email, (GFunc) g_free, NULL);
				g_list_free (email);
			}

		} else if (priv->raw != NULL) {
			CamelInternetAddress *addr = camel_internet_address_new ();

			if (camel_address_unformat (CAMEL_ADDRESS (addr), priv->raw)) {
				const gchar *camel_email = NULL;
				if (camel_internet_address_get (addr, 0, NULL, &camel_email))
					priv->email = g_strdup (camel_email);
			}

			g_object_unref (addr);
		}

		/* Force e-mail to be non-null... */
		if (priv->email == NULL) {
			priv->email = g_strdup ("");
		}
	}

	return priv->email;
}

/* Helper function to e_destination_get_address capable of recursively
 * iterating through structured destinations list */
static void
destination_get_address (const EDestination *dest,
                         CamelInternetAddress *addr)
{
	const GList *iter;

	if (e_destination_is_evolution_list (dest)) {

		for (iter = dest->priv->list_dests; iter; iter = iter->next) {
			EDestination *list_dest = E_DESTINATION (iter->data);

			destination_get_address (list_dest, addr);
		}

	} else if (!dest->priv->ignored) {
		const gchar *name, *email;
		name = e_destination_get_name (dest);
		email = e_destination_get_email (dest);

		if (nonempty (name) && nonempty (email))
			camel_internet_address_add (addr, name, email);
		else if (nonempty (email))
			camel_address_decode (CAMEL_ADDRESS (addr), email);
		else /* this case loses i suppose, but there's
			nothing we can do here */
			camel_address_decode (CAMEL_ADDRESS (addr), name);
	}
}

/**
 * e_destination_get_address:
 * @dest: an #EDestination
 *
 * Gets the encoded name and email address, or in the case of lists, the
 * encoded list of email addresses, from @dest.  The returned string is
 * suitable for use in an email header, but not for displaying to users.
 *
 * Returns: (nullable): an encoded destination string suitable for use in an
 *          email header, or %NULL if the destination was empty
 **/
const gchar *
e_destination_get_address (const EDestination *dest)
{
	EDestinationPrivate *priv;
	CamelInternetAddress *addr = camel_internet_address_new ();

	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	priv = (EDestinationPrivate *) dest->priv; /* cast out const */

	if (priv->addr) {
		g_free (priv->addr);
		priv->addr = NULL;
	}

	if (e_destination_is_evolution_list (dest)) {
		destination_get_address (dest, addr);
		priv->addr = camel_address_encode (CAMEL_ADDRESS (addr));
	} else if (priv->raw) {
		if (camel_address_unformat (CAMEL_ADDRESS (addr), priv->raw))
			priv->addr = camel_address_encode (CAMEL_ADDRESS (addr));
	} else {
		destination_get_address (dest, addr);
		priv->addr = camel_address_encode (CAMEL_ADDRESS (addr));
	}

	g_object_unref (addr);

	return priv->addr;
}

/**
 * e_destination_set_raw:
 * @dest: an #EDestination
 * @raw: an unparsed string
 *
 * Sets @dest to point to the name and e-mail address resulting from
 * parsing the supplied string. Useful for user input.
 **/
void
e_destination_set_raw (EDestination *dest,
                       const gchar *raw)
{
	g_return_if_fail (E_IS_DESTINATION (dest));
	g_return_if_fail (raw != NULL);

	if (dest->priv->raw == NULL || strcmp (dest->priv->raw, raw)) {

		e_destination_clear (dest);
		dest->priv->raw = g_strdup (raw);

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

/**
 * e_destination_get_textrep:
 * @dest: an #EDestination
 * @include_email: whether to include the e-mail address
 *
 * Generates a textual representation of @dest, suitable for referring
 * to the destination during user interaction.
 *
 * Returns: A textual representation of the destination.
 **/
const gchar *
e_destination_get_textrep (const EDestination *dest,
                           gboolean include_email)
{
	const gchar *name, *email;

	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	if (dest->priv->raw)
		return dest->priv->raw;

	name = e_destination_get_name (dest);
	email = e_destination_get_email (dest);

	if (e_destination_from_contact (dest) && name != NULL && (!include_email || !email || !*email))
		return name;

	/* Make sure that our address gets quoted properly */
	if (name && email && dest->priv->textrep == NULL) {
		CamelInternetAddress *addr = camel_internet_address_new ();

		camel_internet_address_add (addr, name, email);
		g_free (dest->priv->textrep);
		dest->priv->textrep = camel_address_format (CAMEL_ADDRESS (addr));
		g_object_unref (addr);
	}

	if (dest->priv->textrep != NULL)
		return dest->priv->textrep;

	if (email)
		return email;

	return "";
}

/**
 * e_destination_is_evolution_list:
 * @dest: an #EDestination
 *
 * Checks if @dest is a list of addresses.
 *
 * Returns: %TRUE if destination is a list, %FALSE if it is an individual.
 **/
gboolean
e_destination_is_evolution_list (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), FALSE);

	return dest->priv->list_dests != NULL;
}

/**
 * e_destination_list_show_addresses:
 * @dest: an #EDestination
 *
 * If @dest is a list, checks if the addresses in the list
 * should be presented to the user during interaction.
 *
 * Returns: %TRUE if addresses should be shown, %FALSE otherwise.
 **/
gboolean
e_destination_list_show_addresses (const EDestination *dest)
{
	g_return_val_if_fail (E_IS_DESTINATION (dest), FALSE);

	if (dest->priv->contact != NULL)
		return GPOINTER_TO_UINT (e_contact_get (dest->priv->contact, E_CONTACT_LIST_SHOW_ADDRESSES));

	return dest->priv->show_addresses;
}

/**
 * e_destination_list_get_root_dests:
 * @dest: an #EDestination
 *
 * If @dest is a list, gets the list of EDestinations assigned directly
 * to @dest.
 * The list and its elements belong to @dest, and should not be freed.
 *
 * Returns: (element-type EDestination) (transfer none): A list of elements of type #EDestination, or %NULL.
 *
 * Since: 3.2
 **/
const GList *
e_destination_list_get_root_dests (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	if (!e_destination_is_evolution_list (dest))
		return NULL;

	return dest->priv->list_dests;
}

/**
 * e_destination_list_get_dests:
 * @dest: an #EDestination
 *
 * If @dest is a list, gets recursively list of all destinations.
 * Everything returned from this function belongs to @dest and
 * thus should not be freed.
 *
 * Returns: (element-type EDestination) (transfer none): A list of elements of type #EDestination, or %NULL.
 *
 * Since: 3.2
 **/
const GList *
e_destination_list_get_dests (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	if (!e_destination_is_evolution_list (dest))
		return NULL;

	if (!dest->priv->list_alldests) {
		GList *iter;
		for (iter = dest->priv->list_dests; iter; iter = iter->next) {
			if (e_destination_is_evolution_list (iter->data)) {
				GList *l = g_list_copy ((GList *) e_destination_list_get_dests (iter->data));
				dest->priv->list_alldests = g_list_concat (dest->priv->list_alldests, l);
			} else {
				dest->priv->list_alldests = g_list_append (dest->priv->list_alldests, iter->data);
			}
		}
	}

	return dest->priv->list_alldests;
}

/**
 * e_destination_get_html_mail_pref:
 * @dest: an #EDestination
 *
 * Check if @dest wants to get mail formatted as HTML.
 *
 * Returns: %TRUE if destination wants HTML, %FALSE if not.
 **/
gboolean
e_destination_get_html_mail_pref (const EDestination *dest)
{
	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), FALSE);

	if (dest->priv->html_mail_override || dest->priv->contact == NULL)
		return dest->priv->wants_html_mail;

	return e_contact_get (dest->priv->contact, E_CONTACT_WANTS_HTML) ? TRUE : FALSE;
}

/**
 * e_destination_set_html_mail_pref:
 * @dest: an #EDestination
 * @flag: whether the destination wants HTML mail
 *
 * Specifies whether @dest wants to get mail formatted as HTML.
 **/
void
e_destination_set_html_mail_pref (EDestination *dest,
                                  gboolean flag)
{
	g_return_if_fail (dest && E_IS_DESTINATION (dest));

	dest->priv->html_mail_override = TRUE;
	if (dest->priv->wants_html_mail != flag) {
		dest->priv->wants_html_mail = flag;

		g_signal_emit (dest, signals[CHANGED], 0);
	}
}

/*
 * Destination import/export
 */

/**
 * e_destination_get_textrepv:
 * @destv: (array zero-terminated=1): %NULL-terminated array of pointers to #EDestination
 *
 * Generates a joint text representation of all the #EDestination
 * elements in @destv.
 *
 * Returns: The text representation of @destv.
 **/
gchar *
e_destination_get_textrepv (EDestination **destv)
{
	gint i, j, len = 0;
	gchar **strv;
	gchar *str;

	g_return_val_if_fail (destv, NULL);

	/* Q: Please tell me this is only for assertion
	 * reasons. If this is considered to be ok behavior then you
	 * shouldn't use g_return's. Just a reminder;-)
	 *
	 * A: Yes, this is just an assertion.  (Though it does find the
	 * length of the vector in the process...)
	*/
	while (destv[len]) {
		g_return_val_if_fail (E_IS_DESTINATION (destv[len]), NULL);
		len++;
	}

	strv = g_new0 (gchar *, len + 1);
	for (i = 0, j = 0; destv[i]; i++) {
		if (!e_destination_empty (destv[i])) {
			const gchar *addr = e_destination_get_address (destv[i]);
			strv[j++] = addr ? (gchar *) addr : (gchar *) "";
		}
	}

	str = g_strjoinv (", ", strv);

	g_free (strv);

	return str;
}

/**
 * e_destination_xml_encode:
 * @dest: an #EDestination
 *
 * Generates an XML tree from @dest.
 *
 * Returns: Pointer to the root node of the XML tree.
 **/
static xmlNodePtr
e_destination_xml_encode (const EDestination *dest)
{
	xmlNodePtr dest_node;
	const gchar *str;

	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	dest_node = xmlNewNode (NULL, (xmlChar *)"destination");

	str = e_destination_get_name (dest);
	if (str)
		xmlNewTextChild (dest_node, NULL, (xmlChar *)"name", (xmlChar *) str);

	if (!e_destination_is_evolution_list (dest)) {
		str = e_destination_get_email (dest);
		if (str)
			xmlNewTextChild (dest_node, NULL, (xmlChar *)"email", (xmlChar *) str);
	} else {
		GList *iter = dest->priv->list_dests;

		while (iter) {
			EDestination *list_dest = E_DESTINATION (iter->data);
			xmlNodePtr list_node = xmlNewNode (NULL, (xmlChar *)"list_entry");

			str = e_destination_get_name (list_dest);
			if (str) {
				xmlChar *escaped = xmlEncodeEntitiesReentrant (NULL, (xmlChar *) str);
				xmlNewTextChild (list_node, NULL, (xmlChar *)"name", escaped);
				xmlFree (escaped);
			}

			str = e_destination_get_email (list_dest);
			if (str) {
				xmlChar *escaped = xmlEncodeEntitiesReentrant (NULL, (xmlChar *) str);
				xmlNewTextChild (list_node, NULL, (xmlChar *)"email", escaped);
				xmlFree (escaped);
			}

			xmlAddChild (dest_node, list_node);

			iter = g_list_next (iter);
		}

		xmlNewProp (dest_node, (xmlChar *)"is_list", (xmlChar *)"yes");
		xmlNewProp (
			dest_node, (xmlChar *)"show_addresses",
			e_destination_list_show_addresses (dest) ?
			(xmlChar *)"yes" : (xmlChar *)"no");
	}

	str = e_destination_get_source_uid (dest);
	if (str) {
		xmlChar *escaped = xmlEncodeEntitiesReentrant (NULL, (xmlChar *) str);
		xmlNewTextChild (dest_node, NULL, (xmlChar *)"source_uid", escaped);
		xmlFree (escaped);
	}

	str = e_destination_get_contact_uid (dest);
	if (str) {
		gchar buf[16];

		xmlNodePtr uri_node = xmlNewTextChild (dest_node, NULL, (xmlChar *)"card_uid", (xmlChar *) str);
		g_snprintf (buf, 16, "%d", e_destination_get_email_num (dest));
		xmlNewProp (uri_node, (xmlChar *)"email_num", (xmlChar *) buf);
	}

	xmlNewProp (
		dest_node, (xmlChar *)"html_mail",
		e_destination_get_html_mail_pref (dest) ?
		(xmlChar *)"yes" : (xmlChar *)"no");

	xmlNewProp (
		dest_node, (xmlChar *)"auto_recipient",
		e_destination_is_auto_recipient (dest) ?
		(xmlChar *)"yes" : (xmlChar *)"no");

	return dest_node;
}

/**
 * e_destination_xml_decode:
 * @dest: an #EDestination
 * @node: the root node of an XML tree
 *
 * Initializes @dest based on the information encoded in the
 * XML tree under @node.
 *
 * Returns: %TRUE if the XML tree was well-formed, %FALSE otherwise.
 **/
static gboolean
e_destination_xml_decode (EDestination *dest,
                          xmlNodePtr node)
{
	gchar *name = NULL, *email = NULL, *source_uid = NULL, *card_uid = NULL;
	gboolean is_list = FALSE, show_addr = FALSE, auto_recip = FALSE;
	gboolean html_mail = FALSE;
	GList *list_dests = NULL;
	gint email_num = -1;
	gchar *tmp;

	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), FALSE);
	g_return_val_if_fail (node != NULL, FALSE);

	if (strcmp ((gchar *) node->name, "destination"))
		return FALSE;

	tmp = (gchar *) xmlGetProp (node, (xmlChar *)"html_mail");
	if (tmp) {
		html_mail = !strcmp (tmp, "yes");
		xmlFree (tmp);
	}

	tmp = (gchar *) xmlGetProp (node, (xmlChar *)"is_list");
	if (tmp) {
		is_list = !strcmp (tmp, "yes");
		xmlFree (tmp);
	}

	tmp = (gchar *) xmlGetProp (node, (xmlChar *)"show_addresses");
	if (tmp) {
		show_addr = !strcmp (tmp, "yes");
		xmlFree (tmp);
	}

	tmp = (gchar *) xmlGetProp (node, (xmlChar *)"auto_recipient");
	if (tmp) {
		auto_recip = !strcmp (tmp, "yes");
		xmlFree (tmp);
	}

	node = node->xmlChildrenNode;
	while (node) {
		if (!strcmp ((gchar *) node->name, "name")) {
			tmp = (gchar *) xmlNodeGetContent (node);
			g_free (name);
			name = g_strdup (tmp);
			xmlFree (tmp);
		} else if (!is_list && !strcmp ((gchar *) node->name, "email")) {
			tmp = (gchar *) xmlNodeGetContent (node);
			g_free (email);
			email = g_strdup (tmp);
			xmlFree (tmp);
		} else if (is_list && !strcmp ((gchar *) node->name, "list_entry")) {
			xmlNodePtr subnode = node->xmlChildrenNode;
			gchar *list_name = NULL, *list_email = NULL;

			while (subnode) {
				if (!strcmp ((gchar *) subnode->name, "name")) {
					tmp = (gchar *) xmlNodeGetContent (subnode);
					g_free (list_name);
					list_name = g_strdup (tmp);
					xmlFree (tmp);
				} else if (!strcmp ((gchar *) subnode->name, "email")) {
					tmp = (gchar *) xmlNodeGetContent (subnode);
					g_free (list_email);
					list_email = g_strdup (tmp);
					xmlFree (tmp);
				}

				subnode = subnode->next;
			}

			if (list_name || list_email) {
				EDestination *list_dest = e_destination_new ();

				if (list_name)
					e_destination_set_name (list_dest, list_name);
				if (list_email)
					e_destination_set_email (list_dest, list_email);

				g_free (list_name);
				g_free (list_email);

				list_dests = g_list_append (list_dests, list_dest);
			}
		} else if (!strcmp ((gchar *) node->name, "source_uid")) {
			tmp = (gchar *) xmlNodeGetContent (node);
			g_free (source_uid);
			source_uid = g_strdup (tmp);
			xmlFree (tmp);
		} else if (!strcmp ((gchar *) node->name, "card_uid")) {
			tmp = (gchar *) xmlNodeGetContent (node);
			g_free (card_uid);
			card_uid = g_strdup (tmp);
			xmlFree (tmp);

			tmp = (gchar *) xmlGetProp (node, (xmlChar *)"email_num");
			email_num = atoi (tmp);
			xmlFree (tmp);
		}

		node = node->next;
	}

	e_destination_clear (dest);

	if (name) {
		e_destination_set_name (dest, name);
		g_free (name);
	}
	if (email) {
		e_destination_set_email (dest, email);
		g_free (email);
	}
	if (source_uid) {
		e_destination_set_source_uid (dest, source_uid);
		g_free (source_uid);
	}
	if (card_uid) {
		e_destination_set_contact_uid (dest, card_uid, email_num);
		g_free (card_uid);
	}
	if (list_dests)
		dest->priv->list_dests = list_dests;

	dest->priv->html_mail_override = TRUE;
	dest->priv->wants_html_mail = html_mail;

	dest->priv->show_addresses = show_addr;

	dest->priv->auto_recipient = auto_recip;

	return TRUE;
}

static gchar *
null_terminate_and_remove_extra_whitespace (xmlChar *xml_in,
                                            gint size)
{
	gboolean skip_white = FALSE;
	gchar *xml, *r, *w;

	if (xml_in == NULL || size <= 0)
		return NULL;

	xml = g_strndup ((gchar *) xml_in, size);
	r = w = xml;

	while (*r) {
		if (*r == '\n' || *r == '\r') {
			skip_white = TRUE;
		} else {
			gunichar c = g_utf8_get_char (r);
			gboolean is_space = g_unichar_isspace (c);

			*w = *r;

			if (!(skip_white && is_space))
				w++;
			if (!is_space)
				skip_white = FALSE;
		}
		r = g_utf8_next_char (r);
	}

	*w = '\0';

	return xml;
}

/**
 * e_destination_export:
 * @dest: an #EDestination
 *
 * Exports a destination to an XML document.
 *
 * Returns: An XML string, allocated with g_malloc.
 **/
gchar *
e_destination_export (const EDestination *dest)
{
	xmlNodePtr dest_node;
	xmlDocPtr dest_doc;
	xmlChar *buffer = NULL;
	gint size = -1;
	gchar *str;

	g_return_val_if_fail (dest && E_IS_DESTINATION (dest), NULL);

	dest_node = e_destination_xml_encode (dest);
	if (dest_node == NULL)
		return NULL;

	dest_doc = xmlNewDoc ((xmlChar *) XML_DEFAULT_VERSION);
	xmlDocSetRootElement (dest_doc, dest_node);

	xmlDocDumpMemory (dest_doc, &buffer, &size);
	xmlFreeDoc (dest_doc);

	str = null_terminate_and_remove_extra_whitespace (buffer, size);
	xmlFree (buffer);

	return str;
}

/**
 * e_destination_import:
 * @str: an XML string
 *
 * Creates an #EDestination from an XML document.
 *
 * Returns: (transfer full) (nullable): An #EDestination, or %NULL if the document was not
 * well-formed.
 **/
EDestination *
e_destination_import (const gchar *str)
{
	EDestination *dest = NULL;
	xmlDocPtr dest_doc;

	if (!(str && *str))
		return NULL;

	dest_doc = xmlParseMemory ((gchar *) str, strlen (str));
	if (dest_doc && dest_doc->xmlRootNode) {
		dest = e_destination_new ();
		if (!e_destination_xml_decode (dest, dest_doc->xmlRootNode)) {
			g_object_unref (dest);
			dest = NULL;
		}
	}
	xmlFreeDoc (dest_doc);

	return dest;
}

/**
 * e_destination_exportv:
 * @destv: (array zero-terminated=1): a %NULL-terminated array of pointers to #EDestination
 *
 * Exports multiple #EDestination elements to a single XML document.
 *
 * Returns: An XML string, allocated with g_malloc.
 **/
gchar *
e_destination_exportv (EDestination **destv)
{
	xmlDocPtr destv_doc;
	xmlNodePtr destv_node;
	xmlChar *buffer = NULL;
	gint i, size = -1;
	gchar *str;

	if (destv == NULL || *destv == NULL)
		return NULL;

	destv_doc = xmlNewDoc ((xmlChar *) XML_DEFAULT_VERSION);
	destv_node = xmlNewNode (NULL, (xmlChar *)"destinations");
	xmlDocSetRootElement (destv_doc, destv_node);

	for (i = 0; destv[i]; i++) {
		if (!e_destination_empty (destv[i])) {
			xmlNodePtr dest_node = e_destination_xml_encode (destv[i]);
			if (dest_node)
				xmlAddChild (destv_node, dest_node);
		}
	}

	xmlDocDumpMemory (destv_doc, &buffer, &size);
	xmlFreeDoc (destv_doc);

	str = null_terminate_and_remove_extra_whitespace (buffer, size);
	xmlFree (buffer);

	return str;
}

/**
 * e_destination_importv:
 * @str: an XML string
 *
 * Creates an array of pointers to #EDestination elements
 * from an XML document.
 *
 * Returns: (transfer full) (array zero-terminated=1): A %NULL-terminated
 * array of pointers to #EDestination elements.
 **/
EDestination **
e_destination_importv (const gchar *str)
{
	GPtrArray *dest_array = NULL;
	xmlDocPtr destv_doc;
	xmlNodePtr node;
	EDestination **destv = NULL;

	if (!(str && *str))
		return NULL;

	destv_doc = xmlParseMemory ((gchar *) str, strlen (str));
	if (destv_doc == NULL)
		return NULL;

	node = destv_doc->xmlRootNode;

	if (strcmp ((gchar *) node->name, "destinations"))
		goto finished;

	node = node->xmlChildrenNode;

	dest_array = g_ptr_array_new ();

	while (node) {
		EDestination *dest;

		dest = e_destination_new ();
		if (e_destination_xml_decode (dest, node) && !e_destination_empty (dest)) {
			g_ptr_array_add (dest_array, dest);
		} else {
			g_object_unref (dest);
		}

		node = node->next;
	}

	/* we need destv to be NULL terminated */
	g_ptr_array_add (dest_array, NULL);

	destv = (EDestination **) dest_array->pdata;
	g_ptr_array_free (dest_array, FALSE);

 finished:
	xmlFreeDoc (destv_doc);

	return destv;
}

/**
 * e_destination_freev:
 * @destv: (array zero-terminated=1): a %NULL-terminated array of pointers to #EDestination
 *
 * Unrefs the elements of @destv and frees @destv itself.
 **/
void
e_destination_freev (EDestination **destv)
{
	gint i;

	if (destv) {
		for (i = 0; destv[i] != NULL; ++i) {
			g_object_unref (destv[i]);
		}
		g_free (destv);
	}

}

/**
 * e_destination_export_to_vcard_attribute:
 * @dest: an #EDestination
 * @attr: an #EVCardAttribute
 *
 * Exports the contact information from @dest to parameters
 * and values in @attr, suitable for an address book.
 **/
void
e_destination_export_to_vcard_attribute (EDestination *dest,
                                         EVCardAttribute *attr)
{
	e_vcard_attribute_remove_values (attr);
	e_vcard_attribute_remove_params (attr);

	if (e_destination_get_contact_uid (dest))
		e_vcard_attribute_add_param_with_value (
			attr,
			e_vcard_attribute_param_new (EVC_X_DEST_CONTACT_UID),
			e_destination_get_contact_uid (dest));
	if (e_destination_get_source_uid (dest))
		e_vcard_attribute_add_param_with_value (
			attr,
			e_vcard_attribute_param_new (EVC_X_DEST_SOURCE_UID),
			e_destination_get_source_uid (dest));
	if (-1 != e_destination_get_email_num (dest)) {
		gchar buf[10];
		g_snprintf (buf, sizeof (buf), "%d", e_destination_get_email_num (dest));
		e_vcard_attribute_add_param_with_value (
			attr,
			e_vcard_attribute_param_new (EVC_X_DEST_EMAIL_NUM),
			buf);
	}
	e_vcard_attribute_add_param_with_value (
		attr,
		e_vcard_attribute_param_new (EVC_X_DEST_HTML_MAIL),
		e_destination_get_html_mail_pref (dest) ? "TRUE" : "FALSE");

	if (e_destination_get_address (dest))
		e_vcard_attribute_add_value (attr, e_destination_get_address (dest));
}
