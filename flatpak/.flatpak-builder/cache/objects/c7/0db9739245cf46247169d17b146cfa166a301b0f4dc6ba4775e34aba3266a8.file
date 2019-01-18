/*
 * e-source-memo-list.c
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
 * SECTION: e-source-memo-list
 * @include: libedataserver/libedataserver.h
 * @short_description: #ESource extension for a memo list
 *
 * The #ESourceCalendar extension identifies the #ESource as a memo list.
 *
 * Access the extension as follows:
 *
 * |[
 *   #include <libedataserver/libedataserver.h>
 *
 *   ESourceCalendar *extension;
 *
 *   extension = e_source_get_extension (source, E_SOURCE_EXTENSION_MEMO_LIST);
 * ]|
 **/

#include "e-source-memo-list.h"

#include <libedataserver/e-data-server-util.h>

G_DEFINE_TYPE (
	ESourceMemoList,
	e_source_memo_list,
	E_TYPE_SOURCE_SELECTABLE)

static void
e_source_memo_list_class_init (ESourceMemoListClass *class)
{
	ESourceExtensionClass *extension_class;

	extension_class = E_SOURCE_EXTENSION_CLASS (class);
	extension_class->name = E_SOURCE_EXTENSION_MEMO_LIST;
}

static void
e_source_memo_list_init (ESourceMemoList *extension)
{
}
