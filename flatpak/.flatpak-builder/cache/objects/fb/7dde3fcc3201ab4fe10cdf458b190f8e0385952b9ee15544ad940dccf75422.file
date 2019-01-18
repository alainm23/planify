/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_OAUTH2_SERVICES_H
#define E_OAUTH2_SERVICES_H

#include <glib-object.h>

#include <libedataserver/e-oauth2-service.h>

/* Standard GObject macros */
#define E_TYPE_OAUTH2_SERVICES \
	(e_oauth2_services_get_type ())
#define E_OAUTH2_SERVICES(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_OAUTH2_SERVICES, EOAuth2Services))
#define E_OAUTH2_SERVICES_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_OAUTH2_SERVICES, EOAuth2ServicesClass))
#define E_IS_OAUTH2_SERVICES(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_OAUTH2_SERVICES))
#define E_IS_OAUTH2_SERVICES_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_OAUTH2_SERVICES))
#define E_OAUTH2_SERVICES_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_OAUTH2_SERVICES, EOAuth2ServicesClass))

G_BEGIN_DECLS

typedef struct _EOAuth2Services EOAuth2Services;
typedef struct _EOAuth2ServicesClass EOAuth2ServicesClass;
typedef struct _EOAuth2ServicesPrivate EOAuth2ServicesPrivate;

/**
 * EOAuth2Services:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.28
 **/
struct _EOAuth2Services {
	/*< private >*/
	GObject parent;
	EOAuth2ServicesPrivate *priv;
};

struct _EOAuth2ServicesClass {
	GObjectClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[10];
};

gboolean	e_oauth2_services_is_supported		(void);

GType		e_oauth2_services_get_type		(void) G_GNUC_CONST;

EOAuth2Services *
		e_oauth2_services_new			(void);
void		e_oauth2_services_add			(EOAuth2Services *services,
							 EOAuth2Service *service);
void		e_oauth2_services_remove		(EOAuth2Services *services,
							 EOAuth2Service *service);
GSList *	e_oauth2_services_list			(EOAuth2Services *services);
EOAuth2Service *
		e_oauth2_services_find			(EOAuth2Services *services,
							 ESource *source);
EOAuth2Service *
		e_oauth2_services_guess			(EOAuth2Services *services,
							 const gchar *protocol,
							 const gchar *hostname);
gboolean	e_oauth2_services_is_oauth2_alias	(EOAuth2Services *services,
							 const gchar *auth_method);
gboolean	e_oauth2_services_is_oauth2_alias_static
							(const gchar *auth_method);

G_END_DECLS

#endif /* E_OAUTH2_SERVICES_H */
