/*
 * e-cache-reaper-utils.h
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

#ifndef E_CACHE_REAPER_UTILS_H
#define E_CACHE_REAPER_UTILS_H

#include <gio/gio.h>

G_BEGIN_DECLS

gboolean	e_reap_trash_directory_sync	(GFile *trash_directory,
						 gint expiry_in_days,
						 GCancellable *cancellable,
						 GError **error);
void		e_reap_trash_directory		(GFile *trash_directory,
						 gint expiry_in_days,
						 gint io_priority,
						 GCancellable *cancellable,
						 GAsyncReadyCallback callback,
						 gpointer user_data);
gboolean	e_reap_trash_directory_finish	(GFile *trash_directory,
						 GAsyncResult *result,
						 GError **error);

G_END_DECLS

#endif /* E_CACHE_REAPER_UTILS_H */

