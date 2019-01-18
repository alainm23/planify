/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */

/*
 * e-destination.h
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

#if !defined (__LIBEBOOK_H_INSIDE__) && !defined (LIBEBOOK_COMPILATION)
#error "Only <libebook/libebook.h> should be included directly."
#endif

#ifndef __E_DESTINATION_H__
#define __E_DESTINATION_H__

#include <libebook-contacts/libebook-contacts.h>
#include <libebook/e-book.h>
#include <libebook/e-book-client.h>
#include <libxml/tree.h>

/* Standard GObject macros */
#define E_TYPE_DESTINATION \
	(e_destination_get_type ())
#define E_DESTINATION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_DESTINATION, EDestination))
#define E_DESTINATION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_DESTINATION, EDestinationClass))
#define E_IS_DESTINATION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_DESTINATION))
#define E_IS_DESTINATION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_DESTINATION))
#define E_DESTINATION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_DESTINATION, EDestinationClass))

G_BEGIN_DECLS

typedef struct _EDestination EDestination;
typedef struct _EDestinationClass EDestinationClass;
typedef struct _EDestinationPrivate EDestinationPrivate;

struct _EDestination {
	GObject object;
	EDestinationPrivate *priv;
};

struct _EDestinationClass {
	GObjectClass parent_class;

	/* Signals */
	void		(*changed)		(EDestination *destination);

	/* Padding for future expansion */
	void		(*_ebook_reserved1)	(void);
	void		(*_ebook_reserved2)	(void);
	void		(*_ebook_reserved3)	(void);
	void		(*_ebook_reserved4)	(void);
};

GType		e_destination_get_type		(void) G_GNUC_CONST;

EDestination *	e_destination_new		(void);
EDestination *	e_destination_copy		(const EDestination *dest);

gboolean	e_destination_empty		(const EDestination *dest);
gboolean	e_destination_equal		(const EDestination *a,
						 const EDestination *b);

/* for use with EDestinations that wrap a particular contact */
void		e_destination_set_contact	(EDestination *dest,
						 EContact *contact,
						 gint email_num);
void		e_destination_set_contact_uid	(EDestination *dest,
						 const gchar *uid,
						 gint email_num);
void		e_destination_set_client	(EDestination *dest,
						 EBookClient *client);
EContact *	e_destination_get_contact	(const EDestination *dest);
const gchar *	e_destination_get_source_uid	(const EDestination *dest);
const gchar *	e_destination_get_contact_uid	(const EDestination *dest);
gint		e_destination_get_email_num	(const EDestination *dest);

/* for use with EDestinations built up from strings
 * (not corresponding to contacts in a user's address books) */
void		e_destination_set_name		(EDestination *dest,
						 const gchar *name);
void		e_destination_set_email		(EDestination *dest,
						 const gchar *email);
const gchar *	e_destination_get_name		(const EDestination *dest);
const gchar *	e_destination_get_email		(const EDestination *dest);
const gchar *	e_destination_get_address	(const EDestination *dest);

gboolean	e_destination_is_evolution_list	(const EDestination *dest);
gboolean	e_destination_list_show_addresses
						(const EDestination *dest);
const GList *	e_destination_list_get_dests	(const EDestination *dest);
const GList *	e_destination_list_get_root_dests
						(const EDestination *dest);
gboolean	e_destination_is_ignored	(const EDestination *dest);
void		e_destination_set_ignored	(EDestination *dest,
						 gboolean ignored);

/* If true, they want HTML mail. */
gboolean	e_destination_get_html_mail_pref
						(const EDestination *dest);
void		e_destination_set_html_mail_pref
						(EDestination *dest,
						 gboolean flag);

/* used by the evolution composer to manage automatic recipients
 *
 * XXX should probably be implemented using a more neutral/extensible
 * approach instead of a hardcoded evolution-only flag. */
gboolean	e_destination_is_auto_recipient	(const EDestination *dest);
void		e_destination_set_auto_recipient
						(EDestination *dest,
						 gboolean value);

/* set an EDestination (name/email, not contact) from a free form string. */
void		e_destination_set_raw		(EDestination *dest,
						 const gchar *raw);

/* generate a plain-text representation of an EDestination */
const gchar *	e_destination_get_textrep	(const EDestination *dest,
						 gboolean include_email);
gchar *		e_destination_get_textrepv	(EDestination **destv);

/* XML export/import routines. */
gchar *		e_destination_export		(const EDestination *dest);
gchar *		e_destination_exportv		(EDestination **destv);
EDestination *	e_destination_import		(const gchar *str);
EDestination **	e_destination_importv		(const gchar *str);

/* EVCard "export" routines */
void		e_destination_export_to_vcard_attribute
						(EDestination *dest,
						 EVCardAttribute *attr);

void		e_destination_freev		(EDestination **destv);

#ifndef EDS_DISABLE_DEPRECATED
#ifndef __GI_SCANNER__
void		e_destination_set_book		(EDestination *dest,
						 EBook *book);
#endif /* __GI_SCANNER__ */
#endif /* EDS_DISABLE_DEPRECATED */

G_END_DECLS

#endif /* __E_DESTINATION_H__ */
