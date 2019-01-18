/*
 * Copyright (C) 2015 Red Hat, Inc. (www.redhat.com)
 * Copyright (C) 2018 Red Hat, Inc. (www.redhat.com)
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

#ifndef E_CREDENTIALS_PROMPTER_IMPL_OAUTH2_H
#define E_CREDENTIALS_PROMPTER_IMPL_OAUTH2_H

#include <glib.h>
#include <glib-object.h>

#include <libedataserverui/e-credentials-prompter-impl.h>

/* Standard GObject macros */
#define E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2 \
	(e_credentials_prompter_impl_oauth2_get_type ())
#define E_CREDENTIALS_PROMPTER_IMPL_OAUTH2(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2, ECredentialsPrompterImplOAuth2))
#define E_CREDENTIALS_PROMPTER_IMPL_OAUTH2_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2, ECredentialsPrompterImplOAuth2Class))
#define E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2))
#define E_IS_CREDENTIALS_PROMPTER_IMPL_OAUTH2_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2))
#define E_CREDENTIALS_PROMPTER_IMPL_OAUTH2_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_CREDENTIALS_PROMPTER_IMPL_OAUTH2, ECredentialsPrompterImplOAuth2Class))

G_BEGIN_DECLS

typedef struct _ECredentialsPrompterImplOAuth2 ECredentialsPrompterImplOAuth2;
typedef struct _ECredentialsPrompterImplOAuth2Class ECredentialsPrompterImplOAuth2Class;
typedef struct _ECredentialsPrompterImplOAuth2Private ECredentialsPrompterImplOAuth2Private;

/**
 * ECredentialsPrompterImplOAuth2:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.28
 **/
struct _ECredentialsPrompterImplOAuth2 {
	ECredentialsPrompterImpl parent;
	ECredentialsPrompterImplOAuth2Private *priv;
};

struct _ECredentialsPrompterImplOAuth2Class {
	ECredentialsPrompterImplClass parent_class;
};

GType		e_credentials_prompter_impl_oauth2_get_type	(void) G_GNUC_CONST;
ECredentialsPrompterImpl *
		e_credentials_prompter_impl_oauth2_new	(void);

G_END_DECLS

#endif /* E_CREDENTIALS_PROMPTER_IMPL_OAUTH2_H */
