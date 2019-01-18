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
 */

#ifndef __E_NAME_WESTERN_H__
#define __E_NAME_WESTERN_H__

#if !defined (__LIBEBOOK_CONTACTS_H_INSIDE__) && !defined (LIBEBOOK_CONTACTS_COMPILATION)
#error "Only <libebook-contacts/libebook-contacts.h> should be included directly."
#endif

#include <glib.h>
#include <glib-object.h>

G_BEGIN_DECLS

typedef struct {

	/* Public */
	gchar *prefix;
	gchar *first;
	gchar *middle;
	gchar *nick;
	gchar *last;
	gchar *suffix;

	/* Private */
	gchar *full;
} ENameWestern;

GType         e_name_western_get_type (void) G_GNUC_CONST;
ENameWestern *e_name_western_parse (const gchar   *full_name);
void          e_name_western_free  (ENameWestern *w);
ENameWestern *e_name_western_copy  (ENameWestern *w);

G_END_DECLS

#endif /* __E_NAME_WESTERN_H__ */
