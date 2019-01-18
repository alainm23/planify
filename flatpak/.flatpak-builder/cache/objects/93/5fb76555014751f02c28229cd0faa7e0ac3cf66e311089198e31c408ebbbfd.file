/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2014 Red Hat, Inc. (www.redhat.com)
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
 * Authors: Fabiano Fidêncio <fidencio@redhat.com>
 */

/*
 * This class handles and creates #EBackend objects from inside
 * their own subprocesses and also serves as the layer that does
 * the communication between #EDataCalFactory and #EBackend
 */

#include "evolution-data-server-config.h"

#include <locale.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <glib/gi18n-lib.h>

#include "e-cal-backend.h"
#include "e-cal-backend-factory.h"
#include "e-data-cal.h"
#include "e-subprocess-cal-factory.h"

#include <e-dbus-subprocess-backend.h>

/*
 * FIXME: Remove this when there's a build time dependency on libical
 * 3.0.4 (where this is fixed). See
 * https://github.com/libical/libical/pull/335 and the implementation in
 * https://github.com/libical/libical/blob/master/src/libical/icalversion.h.cmake.
 */
#if defined(ICAL_CHECK_VERSION) && defined(ICAL_MAJOR_VERSION) && defined(ICAL_MINOR_VERSION) && defined(ICAL_MICRO_VERSION)
#undef ICAL_CHECK_VERSION
#define ICAL_CHECK_VERSION(major,minor,micro)                          \
    (ICAL_MAJOR_VERSION > (major) ||                                   \
    (ICAL_MAJOR_VERSION == (major) && ICAL_MINOR_VERSION > (minor)) || \
    (ICAL_MAJOR_VERSION == (major) && ICAL_MINOR_VERSION == (minor) && \
    ICAL_MICRO_VERSION >= (micro)))
#else
#if defined(ICAL_CHECK_VERSION)
#undef ICAL_CHECK_VERSION
#endif
#define ICAL_CHECK_VERSION(major,minor,micro) (0)
#endif

/* Forward Declarations */
static void	e_subprocess_cal_factory_initable_init
						(GInitableIface *iface);

G_DEFINE_TYPE_WITH_CODE (
	ESubprocessCalFactory,
	e_subprocess_cal_factory,
	E_TYPE_SUBPROCESS_FACTORY,
	G_IMPLEMENT_INTERFACE (
		G_TYPE_INITABLE,
		e_subprocess_cal_factory_initable_init))

static gchar *
subprocess_cal_factory_open (ESubprocessFactory *subprocess_factory,
			     EBackend *backend,
			     GDBusConnection *connection,
			     gpointer data,
			     GCancellable *cancellable,
			     GError **error)
{
	EDataCal *data_cal;
	gchar *object_path;

	/* If the backend already has an EDataCal installed, return its
	 * object path.  Otherwise we need to install a new EDataCal. */
	data_cal = e_cal_backend_ref_data_cal (E_CAL_BACKEND (backend));

	if (data_cal != NULL) {
		object_path = g_strdup (e_data_cal_get_object_path (data_cal));
	} else {
		object_path = e_subprocess_factory_construct_path ();

		/* The EDataCal will attach itself to ECalBackend,
		 * so no need to call e_cal_backend_set_data_cal(). */
		data_cal = e_data_cal_new (
			E_CAL_BACKEND (backend),
			connection, object_path, error);

		if (data_cal != NULL) {
			e_subprocess_factory_set_backend_callbacks (
				subprocess_factory, backend, data);
		} else {
			g_free (object_path);
			object_path = NULL;
		}
	}

	g_clear_object (&data_cal);

	return object_path;
}

static EBackend *
subprocess_cal_factory_ref_backend (ESourceRegistry *registry,
				     ESource *source,
				     const gchar *backend_factory_type_name)
{
	ECalBackendFactoryClass *backend_factory_class;
	GType backend_factory_type;

	backend_factory_type = g_type_from_name (backend_factory_type_name);
	if (!backend_factory_type)
		return NULL;

	backend_factory_class = g_type_class_ref (backend_factory_type);
	if (!backend_factory_class)
		return NULL;

	return g_object_new (
		backend_factory_class->backend_type,
		"kind", backend_factory_class->component_kind,
		"registry", registry,
		"source", source, NULL);
}

static void
e_subprocess_cal_factory_class_init (ESubprocessCalFactoryClass *class)
{
	ESubprocessFactoryClass *subprocess_factory_class;

	subprocess_factory_class = E_SUBPROCESS_FACTORY_CLASS (class);
	subprocess_factory_class->ref_backend = subprocess_cal_factory_ref_backend;
	subprocess_factory_class->open_data = subprocess_cal_factory_open;
}

static void
e_subprocess_cal_factory_initable_init (GInitableIface *iface)
{
}

static void
e_subprocess_cal_factory_init (ESubprocessCalFactory *subprocess_factory)
{
}

ESubprocessCalFactory *
e_subprocess_cal_factory_new (GCancellable *cancellable,
			       GError **error)
{
#if !ICAL_CHECK_VERSION(3, 0, 2)
	icalarray *builtin_timezones;
	gint ii;
#endif

#ifdef HAVE_ICAL_UNKNOWN_TOKEN_HANDLING
	ical_set_unknown_token_handling_setting (ICAL_DISCARD_TOKEN);
#endif

#ifdef HAVE_ICALTZUTIL_SET_EXACT_VTIMEZONES_SUPPORT
	icaltzutil_set_exact_vtimezones_support (0);
#endif

#if !ICAL_CHECK_VERSION(3, 0, 2)
	/* XXX Pre-load all built-in timezones in libical.
	 *
	 *     Built-in time zones in libical 0.43 are loaded on demand,
	 *     but not in a thread-safe manner, resulting in a race when
	 *     multiple threads call icaltimezone_load_builtin_timezone()
	 *     on the same time zone.  Until built-in time zone loading
	 *     in libical is made thread-safe, work around the issue by
	 *     loading all built-in time zones now, so libical's internal
	 *     time zone array will be fully populated before any threads
	 *     are spawned.
	 *
	 *     This is apparently fixed with additional locking in
	 *     libical 3.0.1 and 3.0.2:
	 *     https://github.com/libical/libical/releases/tag/v3.0.1
	 *     https://github.com/libical/libical/releases/tag/v3.0.2
	 */
	builtin_timezones = icaltimezone_get_builtin_timezones ();
	for (ii = 0; ii < builtin_timezones->num_elements; ii++) {
		icaltimezone *zone;

		zone = icalarray_element_at (builtin_timezones, ii);

		/* We don't care about the component right now,
		 * we just need some function that will trigger
		 * icaltimezone_load_builtin_timezone(). */
		icaltimezone_get_component (zone);
	}
#endif

	return g_initable_new (
		E_TYPE_SUBPROCESS_CAL_FACTORY,
		cancellable, error, NULL);
}
