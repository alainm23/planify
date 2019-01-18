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

#ifndef E_OAUTH2_SERVICE_OUTLOOK_H
#define E_OAUTH2_SERVICE_OUTLOOK_H

#include <libedataserver/e-oauth2-service-base.h>

/* Standard GObject macros */
#define E_TYPE_OAUTH2_SERVICE_OUTLOOK \
	(e_oauth2_service_outlook_get_type ())
#define E_OAUTH2_SERVICE_OUTLOOK(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_OAUTH2_SERVICE_OUTLOOK, EOAuth2ServiceOutlook))
#define E_OAUTH2_SERVICE_OUTLOOK_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_OAUTH2_SERVICE_OUTLOOK, EOAuth2ServiceOutlookClass))
#define E_IS_OAUTH2_SERVICE_OUTLOOK(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_OAUTH2_SERVICE_OUTLOOK))
#define E_IS_OAUTH2_SERVICE_OUTLOOK_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_OAUTH2_SERVICE_OUTLOOK))
#define E_OAUTH2_SERVICE_OUTLOOK_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_OAUTH2_SERVICE_OUTLOOK, EOAuth2ServiceOutlookClass))

G_BEGIN_DECLS

typedef struct _EOAuth2ServiceOutlook EOAuth2ServiceOutlook;
typedef struct _EOAuth2ServiceOutlookClass EOAuth2ServiceOutlookClass;

struct _EOAuth2ServiceOutlook {
	EOAuth2ServiceBase parent;
};

struct _EOAuth2ServiceOutlookClass {
	EOAuth2ServiceBaseClass parent_class;
};

GType		e_oauth2_service_outlook_get_type	(void) G_GNUC_CONST;

G_END_DECLS

#endif /* E_OAUTH2_SERVICE_OUTLOOK_H */
