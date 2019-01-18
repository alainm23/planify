/*
 * Copyright © 2013 Intel Corporation
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef FOLKS_REDECLARE_INTERNAL_API_H
#define FOLKS_REDECLARE_INTERNAL_API_H

#include <folks/folks.h>

/* These functions are marked 'internal', which means Vala makes them ABI
 * but omits them from header files.
 *
 * We can't just tell valac to generate an "internal" VAPI and header
 * via -h and --internal-vapi, because the "internal" header redefines
 * things like "typedef struct _FolksPersonaStore FolksPersonaStore"
 * which are an error if redefined; so you can only include the "internal"
 * header or the "public" one, never both. If we use the "internal"
 * VAPI then libfolks-eds' "public" header ends up trying to include
 * the "internal" header of libfolks, which is unacceptable.
 *
 * Redundant declarations of functions and macros, unlike typedefs, are
 * allowed by C as long as they have identical content. We ought to be able
 * to check that these declarations match what Vala is currently generating
 * by including this header when compiling libfolks. Unfortunately,
 * if we do that we can't include <folks/folks.h>, because Vala-generated
 * C code redeclares local Vala-generated types, functions, etc. rather than
 * just including <folks/folks.h>, and then the typedefs conflict.
 */

void folks_persona_store_set_is_user_set_default (FolksPersonaStore* self,
    gboolean value);

#endif
