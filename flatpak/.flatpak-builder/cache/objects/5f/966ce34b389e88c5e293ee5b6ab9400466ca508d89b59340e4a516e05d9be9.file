/*
 * Copyright (C) 2015 Red Hat, Inc. (www.redhat.com)
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

#if !defined (__LIBEDATASERVERUI_H_INSIDE__) && !defined (LIBEDATASERVERUI_COMPILATION)
#error "Only <libedataserverui/libedataserverui.h> should be included directly."
#endif

#ifndef E_CREDENTIALS_PROMPTER_H
#define E_CREDENTIALS_PROMPTER_H

#include <glib.h>
#include <glib-object.h>
#include <gio/gio.h>

#include <gtk/gtk.h>

#include <libedataserver/libedataserver.h>

#include <libedataserverui/e-credentials-prompter-impl.h>

/* Standard GObject macros */
#define E_TYPE_CREDENTIALS_PROMPTER \
	(e_credentials_prompter_get_type ())
#define E_CREDENTIALS_PROMPTER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CREDENTIALS_PROMPTER, ECredentialsPrompter))
#define E_CREDENTIALS_PROMPTER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CREDENTIALS_PROMPTER, ECredentialsPrompterClass))
#define E_IS_CREDENTIALS_PROMPTER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CREDENTIALS_PROMPTER))
#define E_IS_CREDENTIALS_PROMPTER_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CREDENTIALS_PROMPTER))
#define E_CREDENTIALS_PROMPTER_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CREDENTIALS_PROMPTER, ECredentialsPrompterClass))

G_BEGIN_DECLS

typedef struct _ECredentialsPrompter ECredentialsPrompter;
typedef struct _ECredentialsPrompterClass ECredentialsPrompterClass;
typedef struct _ECredentialsPrompterPrivate ECredentialsPrompterPrivate;

/**
 * ECredentialsPrompterPromptFlags:
 * @E_CREDENTIALS_PROMPTER_PROMPT_FLAG_NONE:
 *   No flag is set.
 * @E_CREDENTIALS_PROMPTER_PROMPT_FLAG_ALLOW_SOURCE_SAVE:
 *   If set, any source changes during the credentials prompts, like
 *   the "remember-password" or user name changes, will be automatically
 *   stored in the source (written on the disk).
 * @E_CREDENTIALS_PROMPTER_PROMPT_FLAG_ALLOW_STORED_CREDENTIALS:
 *   If set, the stored credentials will be returned first. If there are no
 *   credentials saved, then the user will be asked. Any credentials
 *   reprompt should not have set this flag.
 *
 * An #ECredentialsPrompter prompt flags, influencing behaviour
 * of the e_credentials_prompter_prompt().
 *
 * Since: 3.16
 **/
typedef enum {
	E_CREDENTIALS_PROMPTER_PROMPT_FLAG_NONE				= 0,
	E_CREDENTIALS_PROMPTER_PROMPT_FLAG_ALLOW_SOURCE_SAVE		= 1 << 0,
	E_CREDENTIALS_PROMPTER_PROMPT_FLAG_ALLOW_STORED_CREDENTIALS	= 1 << 1
} ECredentialsPrompterPromptFlags;

/**
 * ECredentialsPrompterLoopPromptFunc:
 * @prompter: an #ECredentialsPrompter
 * @source: an #ESource, as passed to e_credentials_prompter_loop_prompt_sync()
 * @credentials: an #ENamedParameters with provided credentials
 * @out_authenticated: (out): set to %TRUE, when the authentication was successful
 * @user_data: user data, as passed to e_credentials_prompter_loop_prompt_sync()
 * @cancellable: a #GCancellable, as passed to e_credentials_prompter_loop_prompt_sync()
 * @error: a #GError, to get an error, or %NULL
 *
 * Returns: %TRUE to continue the loop (reprompt credentials), unless @authenticated is
 *   also set to %TRUE, or %FALSE on error, as an indication that the loop should
 *   be terminated.
 **/
typedef gboolean (*ECredentialsPrompterLoopPromptFunc) (ECredentialsPrompter *prompter,
							ESource *source,
							const ENamedParameters *credentials,
							gboolean *out_authenticated,
							gpointer user_data,
							GCancellable *cancellable,
							GError **error);
/**
 * ECredentialsPrompter:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.16
 **/
struct _ECredentialsPrompter {
	GObject parent;
	ECredentialsPrompterPrivate *priv;
};

struct _ECredentialsPrompterClass {
	GObjectClass parent_class;

	/* Signals */
	GtkWindow *	(*get_dialog_parent)	(ECredentialsPrompter *prompter);
};

GType		e_credentials_prompter_get_type	(void) G_GNUC_CONST;
ECredentialsPrompter *
		e_credentials_prompter_new	(ESourceRegistry *registry);
ESourceRegistry *
		e_credentials_prompter_get_registry
						(ECredentialsPrompter *prompter);
ESourceCredentialsProvider *
		e_credentials_prompter_get_provider
						(ECredentialsPrompter *prompter);
gboolean	e_credentials_prompter_get_auto_prompt
						(ECredentialsPrompter *prompter);
void		e_credentials_prompter_set_auto_prompt
						(ECredentialsPrompter *prompter,
						 gboolean auto_prompt);
void		e_credentials_prompter_set_auto_prompt_disabled_for
						(ECredentialsPrompter *prompter,
						 ESource *source,
						 gboolean is_disabled);
gboolean	e_credentials_prompter_get_auto_prompt_disabled_for
						(ECredentialsPrompter *prompter,
						 ESource *source);
GtkWindow *	e_credentials_prompter_get_dialog_parent
						(ECredentialsPrompter *prompter);
gboolean	e_credentials_prompter_register_impl
						(ECredentialsPrompter *prompter,
						 const gchar *authentication_method,
						 ECredentialsPrompterImpl *prompter_impl);
void		e_credentials_prompter_unregister_impl
						(ECredentialsPrompter *prompter,
						 const gchar *authentication_method,
						 ECredentialsPrompterImpl *prompter_impl);
void		e_credentials_prompter_process_awaiting_credentials
						(ECredentialsPrompter *prompter);
gboolean	e_credentials_prompter_process_source
						(ECredentialsPrompter *prompter,
						 ESource *source);
void		e_credentials_prompter_prompt	(ECredentialsPrompter *prompter,
						 ESource *source,
						 const gchar *error_text,
						 ECredentialsPrompterPromptFlags flags,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_credentials_prompter_prompt_finish
						(ECredentialsPrompter *prompter,
						 GAsyncResult *result,
						 ESource **out_source,
						 ENamedParameters **out_credentials,
						 GError **error);
void		e_credentials_prompter_complete_prompt_call
						(ECredentialsPrompter *prompter,
						 GSimpleAsyncResult *async_result,
						 ESource *source,
						 const ENamedParameters *credentials,
						 const GError *error);
gboolean	e_credentials_prompter_loop_prompt_sync
						(ECredentialsPrompter *prompter,
						 ESource *source,
						 ECredentialsPrompterPromptFlags flags,
						 ECredentialsPrompterLoopPromptFunc func,
						 gpointer user_data,
						 GCancellable *cancellable,
						 GError **error);
G_END_DECLS

#endif /* E_CREDENTIALS_PROMPTER_H */
