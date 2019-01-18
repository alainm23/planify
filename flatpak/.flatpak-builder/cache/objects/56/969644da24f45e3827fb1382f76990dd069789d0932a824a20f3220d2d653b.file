/*
 * Copyright (C) 2008 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#if !defined (__CHAMPLAIN_CHAMPLAIN_H_INSIDE__) && !defined (CHAMPLAIN_COMPILATION)
#error "Only <champlain/champlain.h> can be included directly."
#endif

#ifndef CHAMPLAIN_DEFINES_H
#define CHAMPLAIN_DEFINES_H

#define CHAMPLAIN_API __attribute__((visibility ("default")))

/*
 * The ordinate y of the Mercator projection becomes infinite at the poles
 * and the map must be truncated at some latitude less than ninety degrees.
 *
 * Using a square aspect ratio for the map, the maximum latitude shown is
 * approximately 85.05113 degrees.
 */
#define CHAMPLAIN_MIN_LATITUDE   -85.0511287798
#define CHAMPLAIN_MAX_LATITUDE    85.0511287798
#define CHAMPLAIN_MIN_LONGITUDE -180.0
#define CHAMPLAIN_MAX_LONGITUDE  180.0

typedef struct _ChamplainView ChamplainView;
typedef struct _ChamplainViewClass ChamplainViewClass;

typedef struct _ChamplainMapSource ChamplainMapSource;

#endif
