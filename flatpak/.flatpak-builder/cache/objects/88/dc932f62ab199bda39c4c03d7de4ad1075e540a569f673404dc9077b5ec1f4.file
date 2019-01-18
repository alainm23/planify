/*
 * e-credentials.h
 *
 * Copyright (C) 2011 Red Hat, Inc. (www.redhat.com)
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

#ifndef EDS_DISABLE_DEPRECATED

/* Do not generate bindings. */
#ifndef __GI_SCANNER__

#ifndef E_CREDENTIALS_H
#define E_CREDENTIALS_H

#include <glib.h>

G_BEGIN_DECLS

typedef struct _ECredentials ECredentials;
typedef struct _ECredentialsPrivate ECredentialsPrivate;

/**
 * ECredentials:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.2
 **/
struct _ECredentials {
	/*< private >*/
	ECredentialsPrivate *priv;
};

/**
 * E_CREDENTIALS_KEY_USERNAME:
 *
 * FIXME Docment me.
 *
 * Since: 3.2
 **/
#define E_CREDENTIALS_KEY_USERNAME	"username"

/**
 * E_CREDENTIALS_KEY_PASSWORD:
 *
 * FIXME Document me.
 *
 * Since: 3.2
 **/
#define E_CREDENTIALS_KEY_PASSWORD	"password"

/**
 * E_CREDENTIALS_KEY_AUTH_METHOD:
 *
 * FIXME Document me.
 *
 * Since: 3.2
 **/
#define E_CREDENTIALS_KEY_AUTH_METHOD	"auth-method"

/**
 * E_CREDENTIALS_KEY_PROMPT_TITLE:
 *
 * FIXME Document me.
 *
 * Since: 3.2
 **/
#define E_CREDENTIALS_KEY_PROMPT_TITLE	"prompt-title"

/**
 * E_CREDENTIALS_KEY_PROMPT_TEXT:
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define E_CREDENTIALS_KEY_PROMPT_TEXT	"prompt-text"

/**
 * E_CREDENTIALS_KEY_PROMPT_REASON:
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define E_CREDENTIALS_KEY_PROMPT_REASON	"prompt-reason"

/**
 * E_CREDENTIALS_KEY_PROMPT_KEY:
 *
 * FIXME: Document me.
 *
 * Since: 3.2
 **/
#define E_CREDENTIALS_KEY_PROMPT_KEY	"prompt-key"

/**
 * E_CREDENTIALS_KEY_PROMPT_FLAGS:
 *
 * FIXME Document me.
 *
 * Since: 3.2
 **/
#define E_CREDENTIALS_KEY_PROMPT_FLAGS	"prompt-flags"

/**
 * E_CREDENTIALS_KEY_FOREIGN_REQUEST:
 *
 * Set to "1" when the ECredentials is used to authenticate
 * other than current EClient.
 *
 * Since: 3.4
 **/
#define E_CREDENTIALS_KEY_FOREIGN_REQUEST "foreign-request"

/**
 * ECredentialsPromptFlags:
 * @E_CREDENTIALS_PROMPT_FLAG_REMEMBER_NEVER: never remember the credentials
 * @E_CREDENTIALS_PROMPT_FLAG_REMEMBER_SESSION: remember the credentials only for the current session
 * @E_CREDENTIALS_PROMPT_FLAG_REMEMBER_FOREVER: remember the credentials forever
 * @E_CREDENTIALS_PROMPT_FLAG_REMEMBER_MASK: a bit-mask of the 'remember' flags
 * @E_CREDENTIALS_PROMPT_FLAG_SECRET: whether hide password letters in the UI
 * @E_CREDENTIALS_PROMPT_FLAG_REPROMPT: whether this is a re-prompt
 * @E_CREDENTIALS_PROMPT_FLAG_ONLINE: only ask if we're online
 * @E_CREDENTIALS_PROMPT_FLAG_DISABLE_REMEMBER: disable the 'remember password' checkbox
 * @E_CREDENTIALS_PROMPT_FLAG_PASSPHRASE: we are asking a passphrase
 *
 * Flags for a credentials prompt.
 *
 * Since: 3.2
 **/
/* this is 1:1 with EPasswordsRememberType */
typedef enum {
	E_CREDENTIALS_PROMPT_FLAG_REMEMBER_NEVER,
	E_CREDENTIALS_PROMPT_FLAG_REMEMBER_SESSION,
	E_CREDENTIALS_PROMPT_FLAG_REMEMBER_FOREVER,
	E_CREDENTIALS_PROMPT_FLAG_REMEMBER_MASK = 0xf,

	E_CREDENTIALS_PROMPT_FLAG_SECRET = 1 << 8, /* whether hide password letters in the UI */
	E_CREDENTIALS_PROMPT_FLAG_REPROMPT = 1 << 9, /* automatically set when username and password is provided */
	E_CREDENTIALS_PROMPT_FLAG_ONLINE = 1 << 10, /* only ask if we're online */
	E_CREDENTIALS_PROMPT_FLAG_DISABLE_REMEMBER = 1 << 11, /* disable the 'remember password' checkbox */
	E_CREDENTIALS_PROMPT_FLAG_PASSPHRASE = 1 << 12 /* We are asking a passphrase */
} ECredentialsPromptFlags;

ECredentials *	e_credentials_new	(void);
ECredentials *	e_credentials_new_strv	(const gchar * const *strv);
ECredentials *	e_credentials_new_args	(const gchar *key, ...) G_GNUC_NULL_TERMINATED;
ECredentials *	e_credentials_new_clone	(const ECredentials *credentials);
void		e_credentials_free	(      ECredentials *credentials);
gchar **	e_credentials_to_strv	(const ECredentials *credentials);
void		e_credentials_set	(      ECredentials *credentials, const gchar *key, const gchar *value);
gchar *		e_credentials_get	(const ECredentials *credentials, const gchar *key);
const gchar *	e_credentials_peek	(      ECredentials *credentials, const gchar *key);
gboolean	e_credentials_equal	(const ECredentials *credentials1, const ECredentials *credentials2);
gboolean	e_credentials_equal_keys (const ECredentials *credentials1, const ECredentials *credentials2, const gchar *key1, ...) G_GNUC_NULL_TERMINATED;
gboolean	e_credentials_has_key	(const ECredentials *credentials, const gchar *key);
guint		e_credentials_keys_size	(const ECredentials *credentials);
GSList *	e_credentials_list_keys	(const ECredentials *credentials);
void		e_credentials_clear	(      ECredentials *credentials);
void		e_credentials_clear_peek (      ECredentials *credentials);

void		e_credentials_util_safe_free_string (gchar *str);
gchar *		e_credentials_util_prompt_flags_to_string (guint prompt_flags); /* bit-or of ECredentialsPromptFlags */
guint		e_credentials_util_string_to_prompt_flags (const gchar *prompt_flags_string); /* bit-or of ECredentialsPromptFlags */

G_END_DECLS

#endif /* E_CREDENTIALS_H */

#endif /* __GI_SCANNER__ */

#endif /* EDS_DISABLE_DEPRECATED */
