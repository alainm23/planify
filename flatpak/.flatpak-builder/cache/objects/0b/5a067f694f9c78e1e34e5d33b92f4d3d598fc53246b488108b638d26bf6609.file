/*
 * e-cache-reaper.h
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

#ifndef E_CACHE_REAPER_H
#define E_CACHE_REAPER_H

#include <glib.h>

/* Standard GObject macros */
#define E_TYPE_CACHE_REAPER \
	(e_cache_reaper_get_type ())
#define E_CACHE_REAPER(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_CACHE_REAPER, ECacheReaper))
#define E_IS_CACHE_REAPER(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_CACHE_REAPER))

G_BEGIN_DECLS

typedef struct _ECacheReaper ECacheReaper;
typedef struct _ECacheReaperClass ECacheReaperClass;

void	e_cache_reaper_type_register (GTypeModule *type_module);

GType	e_cache_reaper_get_type			(void);

void	e_cache_reaper_add_private_directory	(ECacheReaper *cache_reaper,
						 const gchar *name);
void	e_cache_reaper_remove_private_directory	(ECacheReaper *cache_reaper,
						 const gchar *name);

G_END_DECLS

#endif /* E_CACHE_REAPER_H */
