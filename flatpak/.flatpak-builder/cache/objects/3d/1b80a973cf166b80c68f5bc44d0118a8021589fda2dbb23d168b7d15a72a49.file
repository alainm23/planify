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

#ifndef E_CREDENTIALS_PROMPTER_IMPL_H
#define E_CREDENTIALS_PROMPTER_IMPL_H

#include <glib.h>
#include <glib-object.h>

#include <libedataserver/libedataserver.h>

/* Standard GObject macros */
#define E_TYPE_CREDENTIALS_PROMPTER_IMPL \
	(e_credentials_prompter_impl_get_type ())
#define E_CREDENTIALS_PROMPTER_IMPL(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CREDENTIALS_PROMPTER_IMPL, ECredentialsPrompterImpl))
#define E_CREDENTIALS_PROMPTER_IMPL_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CREDENTIALS_PROMPTER_IMPL, ECredentialsPrompterImplClass))
#define E_IS_CREDENTIALS_PROMPTER_IMPL(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CREDENTIALS_PROMPTER_IMPL))
#define E_IS_CREDENTIALS_PROMPTER_IMPL_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CREDENTIALS_PROMPTER_IMPL))
#define E_CREDENTIALS_PROMPTER_IMPL_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CREDENTIALS_PROMPTER_IMPL, ECredentialsPrompterImplClass))

G_BEGIN_DECLS

typedef struct _ECredentialsPrompterImpl ECredentialsPrompterImpl;
typedef struct _ECredentialsPrompterImplClass ECredentialsPrompterImplClass;
typedef struct _ECredentialsPrompterImplPrivate ECredentialsPrompterImplPrivate;

struct _ECredentialsPrompter;

/**
 * ECredentialsPrompterImpl:
 *
 * Credentials prompter implementation base structure. The descendants
 * implement ECredentialsPrompterImpl::prompt(), which is used to
 * prompt for credentials. The descendants are automatically registered
 * into an #ECredentialsPrompter.
 *
 * Since: 3.16
 **/
struct _ECredentialsPrompterImpl {
	EExtension parent;
	ECredentialsPrompterImplPrivate *priv;
};

struct _ECredentialsPrompterImplClass {
	EExtensionClass parent_class;

	const gchar * const *authentication_methods; /* NULL-terminated array of methods to register with */

	/* Methods */

	void	(*process_prompt)	(ECredentialsPrompterImpl *prompter_impl,
					 gpointer prompt_id,
					 ESource *auth_source,
					 ESource *cred_source,
					 const gchar *error_text,
					 const ENamedParameters *credentials);
	void	(*cancel_prompt)	(ECredentialsPrompterImpl *prompter_impl,
					 gpointer prompt_id);

	/* Signals */

	void	(*prompt_finished)	(ECredentialsPrompterImpl *prompter_impl,
					 gpointer prompt_id,
					 const ENamedParameters *credentials);
};

GType		e_credentials_prompter_impl_get_type	(void);
struct _ECredentialsPrompter *
		e_credentials_prompter_impl_get_credentials_prompter
							(ECredentialsPrompterImpl *prompter_impl);
void		e_credentials_prompter_impl_prompt	(ECredentialsPrompterImpl *prompter_impl,
							 gpointer prompt_id,
							 ESource *auth_source,
							 ESource *cred_source,
							 const gchar *error_text,
							 const ENamedParameters *credentials);
void		e_credentials_prompter_impl_prompt_finish
							(ECredentialsPrompterImpl *prompter_impl,
							 gpointer prompt_id,
							 const ENamedParameters *credentials);
void		e_credentials_prompter_impl_cancel_prompt
							(ECredentialsPrompterImpl *prompter_impl,
							 gpointer prompt_id);

G_END_DECLS

#endif /* E_CREDENTIALS_PROMPTER_IMPL_H */
