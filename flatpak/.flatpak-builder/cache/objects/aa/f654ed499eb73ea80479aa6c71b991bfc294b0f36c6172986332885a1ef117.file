/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 1999-2008 Novell, Inc. (www.novell.com)
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
 * Authors: Chris Toshok (toshok@ximian.com)
 */

/**
 * SECTION: e-cal-backend-factory
 * @include: libedata-cal/libedata-cal.h
 * @short_description: The factory for creating new calendars
 *
 * This class handles creation of new calendars of various
 * backend types.
 **/

#include "evolution-data-server-config.h"

#include <string.h>

#include "e-cal-backend.h"
#include "e-cal-backend-factory.h"
#include "e-data-cal-factory.h"

G_DEFINE_ABSTRACT_TYPE (
	ECalBackendFactory,
	e_cal_backend_factory,
	E_TYPE_BACKEND_FACTORY)

static EDataCalFactory *
cal_backend_factory_get_data_factory (EBackendFactory *factory)
{
	EExtensible *extensible;

	extensible = e_extension_get_extensible (E_EXTENSION (factory));

	return E_DATA_CAL_FACTORY (extensible);
}

static const gchar *
cal_backend_factory_get_hash_key (EBackendFactory *factory)
{
	ECalBackendFactoryClass *class;
	const gchar *component_name;
	gchar *hash_key;
	gsize length;

	class = E_CAL_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_val_if_fail (class->factory_name != NULL, NULL);

	switch (class->component_kind) {
		case ICAL_VEVENT_COMPONENT:
			component_name = E_SOURCE_EXTENSION_CALENDAR;
			break;
		case ICAL_VTODO_COMPONENT:
			component_name = E_SOURCE_EXTENSION_TASK_LIST;
			break;
		case ICAL_VJOURNAL_COMPONENT:
			component_name = E_SOURCE_EXTENSION_MEMO_LIST;
			break;
		default:
			g_return_val_if_reached (NULL);
	}

	/* Hash Key: FACTORY_NAME ':' COMPONENT_NAME */
	length = strlen (class->factory_name) + strlen (component_name) + 2;
	hash_key = g_alloca (length);
	g_snprintf (
		hash_key, length, "%s:%s",
		class->factory_name, component_name);

	return g_intern_string (hash_key);
}

static EBackend *
cal_backend_factory_new_backend (EBackendFactory *factory,
                                 ESource *source)
{
	ECalBackendFactoryClass *class;
	EDataCalFactory *data_factory;
	ESourceRegistry *registry;

	class = E_CAL_BACKEND_FACTORY_GET_CLASS (factory);
	g_return_val_if_fail (g_type_is_a (
		class->backend_type, E_TYPE_CAL_BACKEND), NULL);

	data_factory = cal_backend_factory_get_data_factory (factory);
	registry = e_data_factory_get_registry (E_DATA_FACTORY (data_factory));

	return g_object_new (
		class->backend_type,
		"kind", class->component_kind,
		"registry", registry,
		"source", source, NULL);
}

static void
e_cal_backend_factory_class_init (ECalBackendFactoryClass *class)
{
	EExtensionClass *extension_class;
	EBackendFactoryClass *factory_class;

	extension_class = E_EXTENSION_CLASS (class);
	extension_class->extensible_type = E_TYPE_DATA_CAL_FACTORY;

	factory_class = E_BACKEND_FACTORY_CLASS (class);
	factory_class->get_hash_key = cal_backend_factory_get_hash_key;
	factory_class->new_backend = cal_backend_factory_new_backend;
}

static void
e_cal_backend_factory_init (ECalBackendFactory *factory)
{
}
