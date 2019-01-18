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
 * SECTION: e-oauth2-service-base
 * @include: libebackend/libebackend.h
 * @short_description: An abstract base class for #EOAuth2Service implementations
 *
 * An abstract base class, which can be used by any #EOAuth2Service
 * implementation. It registers itself to #EOAuth2Services at the end
 * of its constructed method. The descendant implements the #EOAuth2ServiceInterface.
 **/

#include "evolution-data-server-config.h"

#include "e-extension.h"
#include "e-oauth2-services.h"

#include "e-oauth2-service-base.h"

G_DEFINE_ABSTRACT_TYPE (EOAuth2ServiceBase, e_oauth2_service_base, E_TYPE_EXTENSION)

static void
oauth2_service_base_constructed (GObject *object)
{
	EExtensible *extensible;

	extensible = e_extension_get_extensible (E_EXTENSION (object));

	/* Chain up to parent's method. */
	G_OBJECT_CLASS (e_oauth2_service_base_parent_class)->constructed (object);

	e_oauth2_services_add (E_OAUTH2_SERVICES (extensible), E_OAUTH2_SERVICE (object));
}

static void
e_oauth2_service_base_class_init (EOAuth2ServiceBaseClass *klass)
{
	GObjectClass *object_class;
	EExtensionClass *extension_class;

	object_class = G_OBJECT_CLASS (klass);
	object_class->constructed = oauth2_service_base_constructed;

	extension_class = E_EXTENSION_CLASS (klass);
	extension_class->extensible_type = E_TYPE_OAUTH2_SERVICES;
}

static void
e_oauth2_service_base_init (EOAuth2ServiceBase *base)
{
}
