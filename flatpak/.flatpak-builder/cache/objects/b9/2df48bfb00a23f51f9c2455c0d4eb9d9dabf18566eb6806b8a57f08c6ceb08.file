/*
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

#if !defined (__LIBEBOOK_CONTACTS_H_INSIDE__) && !defined (LIBEBOOK_CONTACTS_COMPILATION)
#error "Only <libebook-contacts/libebook-contacts.h> should be included directly."
#endif

#ifndef __E_ADDRESS_WESTERN_H__
#define __E_ADDRESS_WESTERN_H__

#include <glib.h>

G_BEGIN_DECLS

/**
 * EAddressWestern:
 * @po_box: PO Box.
 * @extended: TODO, we're not sure what this is.
 * @street: Street name
 * @locality: City or town
 * @region: State or province
 * @postal_code: Postal Code
 * @country: Country
 *
 * Western address structure.
 */
typedef struct {

	/* Public */
	gchar *po_box;
	gchar *extended;  /* I'm not sure what this is. */
	gchar *street;
	gchar *locality;  /* For example, the city or town. */
	gchar *region;	/* The state or province. */
	gchar *postal_code;
	gchar *country;
} EAddressWestern;

GType         e_address_western_get_type (void) G_GNUC_CONST;
EAddressWestern *e_address_western_parse (const gchar *in_address);
void e_address_western_free (EAddressWestern *eaw);
EAddressWestern *e_address_western_copy (EAddressWestern *eaw);

G_END_DECLS

#endif  /* !__E_ADDRESS_WESTERN_H__ */

