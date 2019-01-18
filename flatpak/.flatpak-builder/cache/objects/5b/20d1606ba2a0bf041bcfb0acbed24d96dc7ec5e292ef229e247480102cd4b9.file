/*
 * e-user-prompter.h
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

#if !defined (__LIBEBACKEND_H_INSIDE__) && !defined (LIBEBACKEND_COMPILATION)
#error "Only <libebackend/libebackend.h> should be included directly."
#endif

#ifndef E_USER_PROMPTER_H
#define E_USER_PROMPTER_H

#include <glib.h>
#include <libedataserver/libedataserver.h>

/* Standard GObject macros */
#define E_TYPE_USER_PROMPTER \
	(e_user_prompter_get_type ())
#define E_USER_PROMPTER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_USER_PROMPTER, EUserPrompter))
#define E_USER_PROMPTER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_USER_PROMPTER, EUserPrompterClass))
#define E_IS_USER_PROMPTER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_USER_PROMPTER))
#define E_IS_USER_PROMPTER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_USER_PROMPTER))
#define E_USER_PROMPTER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_USER_PROMPTER, EUserPrompterClass))

G_BEGIN_DECLS

typedef struct _EUserPrompter EUserPrompter;
typedef struct _EUserPrompterClass EUserPrompterClass;
typedef struct _EUserPrompterPrivate EUserPrompterPrivate;

/**
 * EUserPrompter:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.8
 **/
struct _EUserPrompter {
	/*< private >*/
	GObject parent;
	EUserPrompterPrivate *priv;
};

struct _EUserPrompterClass {
	GObjectClass parent;
};

GType		e_user_prompter_get_type	(void) G_GNUC_CONST;
EUserPrompter *	e_user_prompter_new		(void);
void		e_user_prompter_prompt		(EUserPrompter *prompter,
						 const gchar *type,
						 const gchar *title,
						 const gchar *primary_text,
						 const gchar *secondary_text,
						 gboolean use_markup,
						 GList *button_captions,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gint		e_user_prompter_prompt_finish	(EUserPrompter *prompter,
						 GAsyncResult *result,
						 GError **error);
gint		e_user_prompter_prompt_sync	(EUserPrompter *prompter,
						 const gchar *type,
						 const gchar *title,
						 const gchar *primary_text,
						 const gchar *secondary_text,
						 gboolean use_markup,
						 GList *button_captions,
						 GCancellable *cancellable,
						 GError **error);
void		e_user_prompter_extension_prompt
						(EUserPrompter *prompter,
						 const gchar *dialog_name,
						 const ENamedParameters *in_parameters,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gint		e_user_prompter_extension_prompt_finish
						(EUserPrompter *prompter,
						 GAsyncResult *result,
						 ENamedParameters *out_values,
						 GError **error);
gint		e_user_prompter_extension_prompt_sync
						(EUserPrompter *prompter,
						 const gchar *dialog_name,
						 const ENamedParameters *in_parameters,
						 ENamedParameters *out_values,
						 GCancellable *cancellable,
						 GError **error);

G_END_DECLS

#endif /* E_USER_PROMPTER_H */
