/*
 * e-source-mail-composition.h
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

#ifndef E_SOURCE_MAIL_COMPOSITION_H
#define E_SOURCE_MAIL_COMPOSITION_H

#include <libedataserver/e-source-extension.h>
#include <libedataserver/e-source-enums.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_MAIL_COMPOSITION \
	(e_source_mail_composition_get_type ())
#define E_SOURCE_MAIL_COMPOSITION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_MAIL_COMPOSITION, ESourceMailComposition))
#define E_SOURCE_MAIL_COMPOSITION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_MAIL_COMPOSITION, ESourceMailCompositionClass))
#define E_IS_SOURCE_MAIL_COMPOSITION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_MAIL_COMPOSITION))
#define E_IS_SOURCE_MAIL_COMPOSITION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_MAIL_COMPOSITION))
#define E_SOURCE_MAIL_COMPOSITION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_MAIL_COMPOSITION, ESourceMailCompositionClass))

/**
 * E_SOURCE_EXTENSION_MAIL_COMPOSITION:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceMailComposition.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_MAIL_COMPOSITION "Mail Composition"

G_BEGIN_DECLS

typedef struct _ESourceMailComposition ESourceMailComposition;
typedef struct _ESourceMailCompositionClass ESourceMailCompositionClass;
typedef struct _ESourceMailCompositionPrivate ESourceMailCompositionPrivate;

/**
 * ESourceMailComposition:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.6
 **/
struct _ESourceMailComposition {
	/*< private >*/
	ESourceExtension parent;
	ESourceMailCompositionPrivate *priv;
};

struct _ESourceMailCompositionClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_mail_composition_get_type
					(void) G_GNUC_CONST;
const gchar * const *
		e_source_mail_composition_get_bcc
					(ESourceMailComposition *extension);
gchar **	e_source_mail_composition_dup_bcc
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_bcc
					(ESourceMailComposition *extension,
					 const gchar * const *bcc);
const gchar * const *
		e_source_mail_composition_get_cc
					(ESourceMailComposition *extension);
gchar **	e_source_mail_composition_dup_cc
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_cc
					(ESourceMailComposition *extension,
					 const gchar * const *cc);
const gchar *	e_source_mail_composition_get_drafts_folder
					(ESourceMailComposition *extension);
gchar *		e_source_mail_composition_dup_drafts_folder
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_drafts_folder
					(ESourceMailComposition *extension,
					 const gchar *drafts_folder);
gboolean	e_source_mail_composition_get_sign_imip
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_sign_imip
					(ESourceMailComposition *extension,
					 gboolean sign_imip);
const gchar *	e_source_mail_composition_get_templates_folder
					(ESourceMailComposition *extension);
gchar *		e_source_mail_composition_dup_templates_folder
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_templates_folder
					(ESourceMailComposition *extension,
					 const gchar *templates_folder);
ESourceMailCompositionReplyStyle
		e_source_mail_composition_get_reply_style
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_reply_style
					(ESourceMailComposition *extension,
					 ESourceMailCompositionReplyStyle reply_style);
EThreeState	e_source_mail_composition_get_start_bottom
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_start_bottom
					(ESourceMailComposition *extension,
					 EThreeState start_bottom);
EThreeState	e_source_mail_composition_get_top_signature
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_top_signature
					(ESourceMailComposition *extension,
					 EThreeState top_signature);
const gchar *	e_source_mail_composition_get_language
					(ESourceMailComposition *extension);
gchar *		e_source_mail_composition_dup_language
					(ESourceMailComposition *extension);
void		e_source_mail_composition_set_language
					(ESourceMailComposition *extension,
					 const gchar *language);

G_END_DECLS

#endif /* E_SOURCE_MAIL_COMPOSITION_H */
