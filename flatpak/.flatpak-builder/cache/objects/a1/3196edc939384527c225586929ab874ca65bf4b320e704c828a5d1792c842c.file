/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/* e-vcard.h
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
 * Authors: Chris Toshok (toshok@ximian.com)
 */

#if !defined (__LIBEBOOK_CONTACTS_H_INSIDE__) && !defined (LIBEBOOK_CONTACTS_COMPILATION)
#error "Only <libebook-contacts/libebook-contacts.h> should be included directly."
#endif

#ifndef _EVCARD_H
#define _EVCARD_H

#include <glib-object.h>

G_BEGIN_DECLS

#define EVC_ADR				"ADR"
#define EVC_BDAY			"BDAY"
#define EVC_CALURI			"CALURI"
#define EVC_CATEGORIES			"CATEGORIES"
#define EVC_EMAIL			"EMAIL"
#define EVC_ENCODING			"ENCODING"
#define EVC_FBURL			"FBURL"
#define EVC_FN				"FN"

/**
 * EVC_GEO:
 *
 * Since: 1.12
 **/
#define EVC_GEO				"GEO"

/* XXX should this be X-EVOLUTION-ICSCALENDAR? */
#define EVC_ICSCALENDAR			"ICSCALENDAR"
#define EVC_KEY				"KEY"
#define EVC_LABEL			"LABEL"
#define EVC_LOGO			"LOGO"
#define EVC_MAILER			"MAILER"
#define EVC_NICKNAME			"NICKNAME"
#define EVC_N				"N"
#define EVC_NOTE			"NOTE"
#define EVC_ORG				"ORG"
#define EVC_PHOTO			"PHOTO"
#define EVC_PRODID			"PRODID"
#define EVC_QUOTEDPRINTABLE		"QUOTED-PRINTABLE"
#define EVC_REV				"REV"
#define EVC_ROLE			"ROLE"
#define EVC_TEL				"TEL"
#define EVC_TITLE			"TITLE"
#define EVC_TYPE			"TYPE"
#define EVC_UID				"UID"
#define EVC_URL				"URL"
#define EVC_VALUE			"VALUE"
#define EVC_VERSION			"VERSION"

#define EVC_X_AIM			"X-AIM"
#define EVC_X_ANNIVERSARY		"X-EVOLUTION-ANNIVERSARY"
#define EVC_X_ASSISTANT			"X-EVOLUTION-ASSISTANT"
#define EVC_X_BIRTHDAY			"X-EVOLUTION-BIRTHDAY"
#define EVC_X_BLOG_URL			"X-EVOLUTION-BLOG-URL"
#define EVC_X_CALLBACK			"X-EVOLUTION-CALLBACK"
#define EVC_X_COMPANY			"X-EVOLUTION-COMPANY"
#define EVC_X_DEST_CONTACT_UID		"X-EVOLUTION-DEST-CONTACT-UID"
#define EVC_X_DEST_EMAIL_NUM		"X-EVOLUTION-DEST-EMAIL-NUM"
#define EVC_X_DEST_HTML_MAIL		"X-EVOLUTION-DEST-HTML-MAIL"
#define EVC_X_DEST_SOURCE_UID		"X-EVOLUTION-DEST-SOURCE-UID"
#define EVC_X_E164			"X-EVOLUTION-E164"
#define EVC_X_FILE_AS			"X-EVOLUTION-FILE-AS"
#define EVC_X_GADUGADU			"X-GADUGADU"
#define EVC_X_GROUPWISE			"X-GROUPWISE"
#define EVC_X_ICQ			"X-ICQ"
#define EVC_X_JABBER			"X-JABBER"
#define EVC_X_LIST_SHOW_ADDRESSES	"X-EVOLUTION-LIST-SHOW-ADDRESSES"
#define EVC_X_LIST			"X-EVOLUTION-LIST"

/**
 * EVC_X_LIST_NAME:
 *
 * Since: 3.2
 **/
#define EVC_X_LIST_NAME			"X-EVOLUTION-LIST-NAME"

#define EVC_X_MANAGER			"X-EVOLUTION-MANAGER"
#define EVC_X_MSN			"X-MSN"
#define EVC_X_RADIO			"X-EVOLUTION-RADIO"

/**
 * EVC_X_SKYPE:
 *
 * Since: 2.26
 **/
#define EVC_X_SKYPE			"X-SKYPE"

/**
 * EVC_X_GOOGLE_TALK:
 *
 * Since: 3.2
 **/
#define EVC_X_GOOGLE_TALK		"X-GOOGLE-TALK"

/**
 * EVC_X_TWITTER:
 *
 * Twitter name(s).
 *
 * Since: 3.6
 **/
#define EVC_X_TWITTER			"X-TWITTER"

/**
 * EVC_X_SIP:
 *
 * Since: 2.26
 **/
#define EVC_X_SIP			"X-SIP"

#define EVC_X_SPOUSE			"X-EVOLUTION-SPOUSE"
#define EVC_X_TELEX			"X-EVOLUTION-TELEX"
#define EVC_X_TTYTDD			"X-EVOLUTION-TTYTDD"
#define EVC_X_VIDEO_URL			"X-EVOLUTION-VIDEO-URL"
#define EVC_X_WANTS_HTML		"X-MOZILLA-HTML"
#define EVC_X_YAHOO			"X-YAHOO"

/**
 * EVC_X_BOOK_UID:
 *
 * Since: 3.6
 **/
#define EVC_X_BOOK_UID			"X-EVOLUTION-BOOK-UID"

/* Constants for Evo contact lists only */

/**
 * EVC_CONTACT_LIST:
 *
 * Since: 3.2
 **/
#define EVC_CONTACT_LIST		"X-EVOLUTION-CONTACT-LIST-INFO"

/**
 * EVC_PARENT_CL:
 *
 * Since: 3.2
 **/
#define EVC_PARENT_CL			"X-EVOLUTION-PARENT-UID"

/**
 * EVC_CL_UID:
 *
 * Since: 3.2
 **/
#define EVC_CL_UID			"X-EVOLUTION-CONTACT-LIST-UID"

#ifndef EDS_DISABLE_DEPRECATED
#define EVC_X_DEST_EMAIL		"X-EVOLUTION-DEST-EMAIL"
#define EVC_X_DEST_NAME			"X-EVOLUTION-DEST-NAME"
#endif /* EDS_DISABLE_DEPRECATED */

typedef enum {
	EVC_FORMAT_VCARD_21,
	EVC_FORMAT_VCARD_30
} EVCardFormat;

#define E_TYPE_VCARD            (e_vcard_get_type ())
#define E_VCARD(obj)            (G_TYPE_CHECK_INSTANCE_CAST ((obj), E_TYPE_VCARD, EVCard))
#define E_VCARD_CLASS(klass)    (G_TYPE_CHECK_CLASS_CAST ((klass), E_TYPE_VCARD, EVCardClass))
#define E_IS_VCARD(obj)         (G_TYPE_CHECK_INSTANCE_TYPE ((obj), E_TYPE_VCARD))
#define E_IS_VCARD_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), E_TYPE_VCARD))
#define E_VCARD_GET_CLASS(obj)  (G_TYPE_INSTANCE_GET_CLASS ((obj), E_TYPE_VCARD, EVCardClass))

#define E_TYPE_VCARD_ATTRIBUTE  (e_vcard_attribute_get_type ())

#define E_TYPE_VCARD_PARAM_ATTRIBUTE  (e_vcard_attribute_param_get_type ())

/**
 * E_VCARD_21_VALID_PROPERTIES:
 *
 * FIXME: Document me!
 *
 * Since: 3.4
 **/
#define E_VCARD_21_VALID_PROPERTIES \
	"ADR,ORG,N,AGENT,LOGO,PHOTO,LABEL,FN,TITLE,SOUND,VERSION,TEL," \
	"EMAIL,TZ,GEO,NOTE,URL,BDAY,ROLE,REV,UID,KEY,MAILER"

/**
 * E_VCARD_21_VALID_PARAMETERS:
 *
 * FIXME: Document me!
 *
 * Since: 3.4
 **/
#define E_VCARD_21_VALID_PARAMETERS \
	"TYPE,VALUE,ENCODING,CHARSET,LANGUAGE,DOM,INTL,POSTAL,PARCEL," \
	"HOME,WORK,PREF,VOICE,FAX,MSG,CELL,PAGER,BBS,MODEM,CAR,ISDN,VIDEO," \
	"AOL,APPLELINK,ATTMAIL,CIS,EWORLD,INTERNET,IBMMAIL,MCIMAIL," \
	"POWERSHARE,PRODIGY,TLX,X400,GIF,CGM,WMF,BMP,MET,PMB,DIB,PICT,TIFF," \
	"PDF,PS,JPEG,QTIME,MPEG,MPEG2,AVI,WAVE,AIFF,PCM,X509,PGP"

typedef struct _EVCard EVCard;
typedef struct _EVCardClass EVCardClass;
typedef struct _EVCardPrivate EVCardPrivate;
typedef struct _EVCardAttribute EVCardAttribute;
typedef struct _EVCardAttributeParam EVCardAttributeParam;

struct _EVCard {
	GObject parent;
	/*< private >*/
	EVCardPrivate *priv;
};

struct _EVCardClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	void (*_ebook_reserved0) (void);
	void (*_ebook_reserved1) (void);
	void (*_ebook_reserved2) (void);
	void (*_ebook_reserved3) (void);
	void (*_ebook_reserved4) (void);
};

GType   e_vcard_get_type                     (void);

void    e_vcard_construct                    (EVCard *evc, const gchar *str);
void    e_vcard_construct_with_uid           (EVCard *evc, const gchar *str, const gchar *uid);
void    e_vcard_construct_full               (EVCard *evc, const gchar *str, gssize len, const gchar *uid);
EVCard * e_vcard_new                          (void);
EVCard * e_vcard_new_from_string              (const gchar *str);

gboolean e_vcard_is_parsed (EVCard *evc);

gchar *   e_vcard_to_string                    (EVCard *evc, EVCardFormat format);

/* mostly for debugging */
void    e_vcard_dump_structure               (EVCard *evc);

/* attributes */
GType            e_vcard_attribute_get_type          (void);
EVCardAttribute *e_vcard_attribute_new               (const gchar *attr_group, const gchar *attr_name);
void             e_vcard_attribute_free              (EVCardAttribute *attr);
EVCardAttribute *e_vcard_attribute_copy              (EVCardAttribute *attr);
void             e_vcard_remove_attributes           (EVCard *evc, const gchar *attr_group, const gchar *attr_name);
void             e_vcard_remove_attribute            (EVCard *evc, EVCardAttribute *attr);
void             e_vcard_append_attribute            (EVCard *evc, EVCardAttribute *attr);
void             e_vcard_append_attribute_with_value (EVCard *evcard, EVCardAttribute *attr, const gchar *value);
void             e_vcard_append_attribute_with_values (EVCard *evcard, EVCardAttribute *attr, ...);
void             e_vcard_add_attribute               (EVCard *evc, EVCardAttribute *attr);
void             e_vcard_add_attribute_with_value    (EVCard *evcard, EVCardAttribute *attr, const gchar *value);
void             e_vcard_add_attribute_with_values   (EVCard *evcard, EVCardAttribute *attr, ...);
void             e_vcard_attribute_add_value         (EVCardAttribute *attr, const gchar *value);
void             e_vcard_attribute_add_value_decoded (EVCardAttribute *attr, const gchar *value, gint len);
void             e_vcard_attribute_add_values        (EVCardAttribute *attr, ...);
void             e_vcard_attribute_remove_value      (EVCardAttribute *attr, const gchar *s);
void             e_vcard_attribute_remove_values     (EVCardAttribute *attr);
void             e_vcard_attribute_remove_params     (EVCardAttribute *attr);
void             e_vcard_attribute_remove_param      (EVCardAttribute *attr, const gchar *param_name);
void             e_vcard_attribute_remove_param_value (EVCardAttribute *attr, const gchar *param_name, const gchar *s);

/* attribute parameters */
GType                 e_vcard_attribute_param_get_type        (void);
EVCardAttributeParam * e_vcard_attribute_param_new             (const gchar *name);
void                  e_vcard_attribute_param_free            (EVCardAttributeParam *param);
EVCardAttributeParam * e_vcard_attribute_param_copy            (EVCardAttributeParam *param);
void                  e_vcard_attribute_add_param             (EVCardAttribute *attr, EVCardAttributeParam *param);
void                  e_vcard_attribute_add_param_with_value  (EVCardAttribute *attr,
							       EVCardAttributeParam *param, const gchar *value);
void                  e_vcard_attribute_add_param_with_values (EVCardAttribute *attr,
							       EVCardAttributeParam *param, ...);

void                  e_vcard_attribute_param_add_value       (EVCardAttributeParam *param,
							       const gchar *value);
void                  e_vcard_attribute_param_add_values      (EVCardAttributeParam *param,
							       ...);
void                  e_vcard_attribute_param_remove_values   (EVCardAttributeParam *param);

/* EVCard* accessors.  nothing returned from these functions should be
 * freed by the caller. */
EVCardAttribute *e_vcard_get_attribute        (EVCard *evc, const gchar *name);
EVCardAttribute *e_vcard_get_attribute_if_parsed	(EVCard *evc, const gchar *name);
GList *           e_vcard_get_attributes       (EVCard *evcard);
const gchar *      e_vcard_attribute_get_group  (EVCardAttribute *attr);
const gchar *      e_vcard_attribute_get_name   (EVCardAttribute *attr);
GList *           e_vcard_attribute_get_values (EVCardAttribute *attr);  /* GList elements are of type gchar * */
GList *           e_vcard_attribute_get_values_decoded (EVCardAttribute *attr); /* GList elements are of type GString * */

/* special accessors for single valued attributes */
gboolean              e_vcard_attribute_is_single_valued      (EVCardAttribute *attr);
gchar *                 e_vcard_attribute_get_value             (EVCardAttribute *attr);
GString *              e_vcard_attribute_get_value_decoded     (EVCardAttribute *attr);

GList *           e_vcard_attribute_get_params       (EVCardAttribute *attr);
GList *           e_vcard_attribute_get_param        (EVCardAttribute *attr, const gchar *name);
const gchar *      e_vcard_attribute_param_get_name   (EVCardAttributeParam *param);
GList *           e_vcard_attribute_param_get_values (EVCardAttributeParam *param);

/* special TYPE= parameter predicate (checks for TYPE=@typestr */
gboolean         e_vcard_attribute_has_type         (EVCardAttribute *attr, const gchar *typestr);

/* Utility functions. */
gchar *            e_vcard_escape_string (const gchar *s);
gchar *            e_vcard_unescape_string (const gchar *s);

void		e_vcard_util_set_x_attribute	(EVCard *vcard,
						 const gchar *x_name,
						 const gchar *value);
gchar *		e_vcard_util_dup_x_attribute	(EVCard *vcard,
						 const gchar *x_name);

G_END_DECLS

#endif /* _EVCARD_H */
