/*
 * e-source-goa.h
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_GOA_H
#define E_SOURCE_GOA_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_GOA \
	(e_source_goa_get_type ())
#define E_SOURCE_GOA(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_GOA, ESourceGoa))
#define E_SOURCE_GOA_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_GOA, ESourceGoaClass))
#define E_IS_SOURCE_GOA(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_GOA))
#define E_IS_SOURCE_GOA_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_GOA))
#define E_SOURCE_GOA_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_GOA, ESourceGoaClass))

/**
 * E_SOURCE_EXTENSION_GOA:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceGoa.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_GOA "GNOME Online Accounts"

G_BEGIN_DECLS

typedef struct _ESourceGoa ESourceGoa;
typedef struct _ESourceGoaClass ESourceGoaClass;
typedef struct _ESourceGoaPrivate ESourceGoaPrivate;

/**
 * ESourceGoa:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceGoa {
	/*< private >*/
	ESourceExtension parent;
	ESourceGoaPrivate *priv;
};

struct _ESourceGoaClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_goa_get_type		(void) G_GNUC_CONST;
const gchar *	e_source_goa_get_account_id	(ESourceGoa *extension);
gchar *		e_source_goa_dup_account_id	(ESourceGoa *extension);
void		e_source_goa_set_account_id	(ESourceGoa *extension,
						 const gchar *account_id);
const gchar *	e_source_goa_get_calendar_url	(ESourceGoa *extension);
gchar *		e_source_goa_dup_calendar_url	(ESourceGoa *extension);
void		e_source_goa_set_calendar_url	(ESourceGoa *extension,
						 const gchar *calendar_url);
const gchar *	e_source_goa_get_contacts_url	(ESourceGoa *extension);
gchar *		e_source_goa_dup_contacts_url	(ESourceGoa *extension);
void		e_source_goa_set_contacts_url	(ESourceGoa *extension,
						 const gchar *contacts_url);
const gchar *	e_source_goa_get_name		(ESourceGoa *extension);
gchar *		e_source_goa_dup_name		(ESourceGoa *extension);
void		e_source_goa_set_name		(ESourceGoa *extension,
						 const gchar *name);
const gchar *	e_source_goa_get_address	(ESourceGoa *extension);
gchar *		e_source_goa_dup_address	(ESourceGoa *extension);
void		e_source_goa_set_address	(ESourceGoa *extension,
						 const gchar *address);

G_END_DECLS

#endif /* E_SOURCE_GOA_H */

