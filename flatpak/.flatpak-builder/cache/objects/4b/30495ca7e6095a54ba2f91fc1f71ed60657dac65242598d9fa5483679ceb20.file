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

/**
 * SECTION: e-oauth2-services
 * @include: libedataserver/libedataserver.h
 * @short_description: An extensible object holding all known OAuth2 services
 *
 * The extensible object, which holds all known OAuth2 services. Each
 * #EOAuth2Service extends this object and adds itself to it with
 * e_oauth2_services_add(). The services can be later searched for
 * with e_oauth2_services_find(), which returns the service suitable
 * for the given protocol and/or host name.
 **/

#include "evolution-data-server-config.h"

#include <stdio.h>

#include "e-extensible.h"
#include "e-oauth2-service.h"

/* Known built-in implementations */
#include "e-oauth2-service-google.h"
#include "e-oauth2-service-outlook.h"

#include "e-oauth2-services.h"

struct _EOAuth2ServicesPrivate {
	GMutex property_lock;
	GSList *services; /* EOAuth2Service * */
};

G_DEFINE_TYPE_WITH_CODE (EOAuth2Services, e_oauth2_services, G_TYPE_OBJECT,
	G_IMPLEMENT_INTERFACE (E_TYPE_EXTENSIBLE, NULL))

static GObject *services_singleton = NULL;
G_LOCK_DEFINE_STATIC (services_singleton);

static void
services_singleton_weak_ref_cb (gpointer user_data,
				GObject *object)
{
	G_LOCK (services_singleton);

	g_warn_if_fail (object == services_singleton);
	services_singleton = NULL;

	G_UNLOCK (services_singleton);
}

static GObject *
oauth2_services_constructor (GType type,
			     guint n_construct_params,
			     GObjectConstructParam *construct_params)
{
	GObject *object;

	G_LOCK (services_singleton);

	if (services_singleton) {
		object = g_object_ref (services_singleton);
	} else {
		object = G_OBJECT_CLASS (e_oauth2_services_parent_class)->constructor (type, n_construct_params, construct_params);

		if (object)
			g_object_weak_ref (object, services_singleton_weak_ref_cb, NULL);

		services_singleton = object;
	}

	G_UNLOCK (services_singleton);

	return object;
}

static void
oauth2_services_dispose (GObject *object)
{
	EOAuth2Services *services = E_OAUTH2_SERVICES (object);

	g_mutex_lock (&services->priv->property_lock);
	g_slist_free_full (services->priv->services, g_object_unref);
	g_mutex_unlock (&services->priv->property_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_oauth2_services_parent_class)->dispose (object);
}

static void
oauth2_services_finalize (GObject *object)
{
	EOAuth2Services *services = E_OAUTH2_SERVICES (object);

	g_mutex_clear (&services->priv->property_lock);

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_oauth2_services_parent_class)->finalize (object);
}

static void
oauth2_services_constructed (GObject *object)
{
	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_oauth2_services_parent_class)->constructed (object);

	e_extensible_load_extensions (E_EXTENSIBLE (object));
}

static void
e_oauth2_services_class_init (EOAuth2ServicesClass *klass)
{
	GObjectClass *object_class;

	g_type_class_add_private (klass, sizeof (EOAuth2ServicesPrivate));

	object_class = G_OBJECT_CLASS (klass);
	object_class->dispose = oauth2_services_dispose;
	object_class->finalize = oauth2_services_finalize;
	object_class->constructed = oauth2_services_constructed;
	object_class->constructor = oauth2_services_constructor;

	/* Ensure built-in service types are registered */
	g_type_ensure (E_TYPE_OAUTH2_SERVICE_GOOGLE);
	g_type_ensure (E_TYPE_OAUTH2_SERVICE_OUTLOOK);
}

static void
e_oauth2_services_init (EOAuth2Services *oauth2_services)
{
	oauth2_services->priv = G_TYPE_INSTANCE_GET_PRIVATE (oauth2_services, E_TYPE_OAUTH2_SERVICES, EOAuth2ServicesPrivate);

	g_mutex_init (&oauth2_services->priv->property_lock);
}

/**
 * e_oauth2_services_is_supported:
 *
 * Returns: %TRUE, when evolution-data-server had been compiled
 *    with OAuth2 authentication enabled, %FALSE otherwise.
 *
 * Since: 3.28
 **/
gboolean
e_oauth2_services_is_supported (void)
{
#ifdef ENABLE_OAUTH2
	return TRUE;
#else
	return FALSE;
#endif
}

/**
 * e_oauth2_services_new:
 *
 * Creates a new #EOAuth2Services instance.
 *
 * Returns: (transfer full): an #EOAuth2Services
 *
 * Since: 3.28
 **/
EOAuth2Services *
e_oauth2_services_new (void)
{
	return g_object_new (E_TYPE_OAUTH2_SERVICES, NULL);
}

/**
 * e_oauth2_services_add:
 * @services: an #EOAuth2Services
 * @service: an #EOAuth2Service to add
 *
 * Adds the @service to the list of known OAuth2 services into @services.
 * It also adds a reference to @service.
 *
 * Since: 3.28
 **/
void
e_oauth2_services_add (EOAuth2Services *services,
		       EOAuth2Service *service)
{
	GSList *link;

	g_return_if_fail (E_IS_OAUTH2_SERVICES (services));
	g_return_if_fail (E_IS_OAUTH2_SERVICE (service));

	g_mutex_lock (&services->priv->property_lock);

	for (link = services->priv->services; link; link = g_slist_next (link)) {
		if (link->data == service)
			break;
	}

	if (!link)
		services->priv->services = g_slist_prepend (services->priv->services, g_object_ref (service));

	g_mutex_unlock (&services->priv->property_lock);
}

/**
 * e_oauth2_services_remove:
 * @services: an #EOAuth2Services
 * @service: an #EOAuth2Service to remove
 *
 * Removes the @service from the list of known services in @services.
 * The function does nothing, if the @service had not been added.
 *
 * Since: 3.28
 **/
void
e_oauth2_services_remove (EOAuth2Services *services,
			  EOAuth2Service *service)
{
	GSList *link;

	g_return_if_fail (E_IS_OAUTH2_SERVICES (services));
	g_return_if_fail (E_IS_OAUTH2_SERVICE (service));

	g_mutex_lock (&services->priv->property_lock);

	for (link = services->priv->services; link; link = g_slist_next (link)) {
		if (link->data == service) {
			g_object_unref (service);
			services->priv->services = g_slist_remove (services->priv->services, service);
			break;
		}
	}

	g_mutex_unlock (&services->priv->property_lock);
}

/**
 * e_oauth2_services_list:
 * @services: an #EOAuth2Services
 *
 * Lists all currently known services, which had been added
 * with e_oauth2_services_add(). Free the returned #GSList with
 * g_slist_remove_full (known_services, g_object_unref);
 * when no longer needed.
 *
 * Returns: (transfer full) (element-type EOAuth2Service): a newly allocated #GSList
 *    with all currently known #EOAuth2Service referenced instances
 *
 * Since: 3.28
 **/
GSList *
e_oauth2_services_list (EOAuth2Services *services)
{
	GSList *result;

	g_return_val_if_fail (E_IS_OAUTH2_SERVICES (services), NULL);

	g_mutex_lock (&services->priv->property_lock);

	result = g_slist_copy_deep (services->priv->services, (GCopyFunc) g_object_ref, NULL);

	g_mutex_unlock (&services->priv->property_lock);

	return result;
}

/**
 * e_oauth2_services_find:
 * @services: an #EOAuth2Services
 * @source: an #ESource
 *
 * Searches the list of currently known OAuth2 services for the one which
 * can be used with the given @source.
 *
 * The returned #EOAuth2Service is referenced for thread safety, if found.
 *
 * Returns: (transfer full) (nullable): a referenced #EOAuth2Service, which can be used
 *    with given @source, or %NULL, when none was found.
 *
 * Since: 3.28
 **/
EOAuth2Service *
e_oauth2_services_find (EOAuth2Services *services,
			ESource *source)
{
	GSList *link;
	EOAuth2Service *result = NULL;

	g_return_val_if_fail (E_IS_OAUTH2_SERVICES (services), NULL);
	g_return_val_if_fail (E_IS_SOURCE (source), NULL);

	g_mutex_lock (&services->priv->property_lock);

	for (link = services->priv->services; link; link = g_slist_next (link)) {
		EOAuth2Service *service = link->data;

		if (e_oauth2_service_can_process (service, source)) {
			result = g_object_ref (service);
			break;
		}
	}

	g_mutex_unlock (&services->priv->property_lock);

	return result;
}

/**
 * e_oauth2_services_guess:
 * @services: an #EOAuth2Services
 * @protocol: (nullable): a protocol to search the service for, like "imap", or %NULL
 * @hostname: (nullable): a host name to search the service for, like "server.example.com", or %NULL
 *
 * Searches the list of currently known OAuth2 services for the one which
 * can be used with the given @protocol and/or @hostname.
 * Any of @protocol and @hostname can be %NULL, but not both.
 * It's up to each #EOAuth2Service to decide, which of the arguments
 * are important and whether all or only any of them can be required.
 *
 * The returned #EOAuth2Service is referenced for thread safety, if found.
 *
 * Returns: (transfer full) (nullable): a referenced #EOAuth2Service, which can be used
 *    with given constraints, or %NULL, when none was found.
 *
 * Since: 3.28
 **/
EOAuth2Service *
e_oauth2_services_guess (EOAuth2Services *services,
			 const gchar *protocol,
			 const gchar *hostname)
{
	GSList *link;
	EOAuth2Service *result = NULL;

	g_return_val_if_fail (E_IS_OAUTH2_SERVICES (services), NULL);
	g_return_val_if_fail (protocol || hostname, NULL);

	g_mutex_lock (&services->priv->property_lock);

	for (link = services->priv->services; link; link = g_slist_next (link)) {
		EOAuth2Service *service = link->data;

		if (e_oauth2_service_guess_can_process (service, protocol, hostname)) {
			result = g_object_ref (service);
			break;
		}
	}

	g_mutex_unlock (&services->priv->property_lock);

	return result;
}

static gboolean
e_oauth2_services_can_check_auth_method (const gchar *auth_method)
{
	return auth_method && *auth_method &&
	       e_oauth2_services_is_supported () &&
	       g_strcmp0 (auth_method, "none") != 0 &&
	       g_strcmp0 (auth_method, "plain/password") != 0;
}

/**
 * e_oauth2_services_is_oauth2_alias:
 * @services: an #EOAuth2Services
 * @auth_method: (nullable): an authentication method, or %NULL
 *
 * Returns: whether exists any #EOAuth2Service, with the same name as @auth_method.
 *
 * See: e_oauth2_services_is_oauth2_alias_static()
 *
 * Since: 3.28
 **/
gboolean
e_oauth2_services_is_oauth2_alias (EOAuth2Services *services,
				   const gchar *auth_method)
{
	GSList *link;

	g_return_val_if_fail (E_IS_OAUTH2_SERVICES (services), FALSE);

	if (!e_oauth2_services_can_check_auth_method (auth_method))
		return FALSE;

	g_mutex_lock (&services->priv->property_lock);

	for (link = services->priv->services; link; link = g_slist_next (link)) {
		EOAuth2Service *service = link->data;
		const gchar *name;

		name = e_oauth2_service_get_name (service);

		if (name && g_ascii_strcasecmp (name, auth_method) == 0)
			break;
	}

	g_mutex_unlock (&services->priv->property_lock);

	return link != NULL;
}

/**
 * e_oauth2_services_is_oauth2_alias_static:
 * @auth_method: (nullable): an authentication method, or %NULL
 *
 * This is the same as e_oauth2_services_is_oauth2_alias(), except
 * it creates its own #EOAuth2Services instance and frees it at the end.
 * The #EOAuth2Services is implemented as a singleton, thus it won't be
 * much trouble, as long as there is something else having created one
 * instance.
 *
 * Returns: whether exists any #EOAuth2Service, with the same name as @auth_method.
 *
 * Since: 3.28
 **/
gboolean
e_oauth2_services_is_oauth2_alias_static (const gchar *auth_method)
{
	EOAuth2Services *services;
	gboolean is_alias;

	if (!e_oauth2_services_can_check_auth_method (auth_method))
		return FALSE;

	services = e_oauth2_services_new ();
	is_alias = e_oauth2_services_is_oauth2_alias (services, auth_method);
	g_clear_object (&services);

	return is_alias;
}
