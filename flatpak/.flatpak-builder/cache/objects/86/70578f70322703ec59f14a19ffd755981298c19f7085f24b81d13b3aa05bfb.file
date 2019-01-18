/*
 * e-source-autocomplete.h
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

#ifndef E_SOURCE_AUTOCOMPLETE_H
#define E_SOURCE_AUTOCOMPLETE_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_AUTOCOMPLETE \
	(e_source_autocomplete_get_type ())
#define E_SOURCE_AUTOCOMPLETE(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_AUTOCOMPLETE, ESourceAutocomplete))
#define E_SOURCE_AUTOCOMPLETE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_AUTOCOMPLETE, ESourceAutocompleteClass))
#define E_IS_SOURCE_AUTOCOMPLETE(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_AUTOCOMPLETE))
#define E_IS_SOURCE_AUTOCOMPLETE_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_AUTOCOMPLETE))
#define E_SOURCE_AUTOCOMPLETE_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_AUTOCOMPLETE, ESourceAutocompleteClass))

/**
 * E_SOURCE_EXTENSION_AUTOCOMPLETE:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceAutocomplete.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_AUTOCOMPLETE "Autocomplete"

G_BEGIN_DECLS

typedef struct _ESourceAutocomplete ESourceAutocomplete;
typedef struct _ESourceAutocompleteClass ESourceAutocompleteClass;
typedef struct _ESourceAutocompletePrivate ESourceAutocompletePrivate;

/**
 * ESourceAutocomplete:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceAutocomplete {
	/*< private >*/
	ESourceExtension parent;
	ESourceAutocompletePrivate *priv;
};

struct _ESourceAutocompleteClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_autocomplete_get_type
					(void) G_GNUC_CONST;
gboolean	e_source_autocomplete_get_include_me
					(ESourceAutocomplete *extension);
void		e_source_autocomplete_set_include_me
					(ESourceAutocomplete *extension,
					 gboolean include_me);

G_END_DECLS

#endif /* E_SOURCE_AUTOCOMPLETE_H */
