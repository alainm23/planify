/*
 * e-source-calendar.c
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

/**
 * SECTION: e-source-calendar
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for a calendar
 *
 * The #ESourceCalendar extension identifies the #ESource as a calendar.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceCalendar *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_CALENDAR);
 * ]|
 **/

#include "e-source-calendar.h"

#include <libedataserver/e-data-server-util.h>

G_DEFINE_TYPE (
	ESourceCalendar,
	e_source_calendar,
	E_TYPE_SOURCE_SELECTABLE)

static void
e_source_calendar_class_init (ESourceCalendarClass *class)
{
	ESourceExtensionClass *extension_class;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_CALENDAR;
}

static void
e_source_calendar_init (ESourceCalendar *extension)
{
}
