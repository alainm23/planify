/*
 * Copyright (C) 2009 Pierre-Luc Beaudoin <pierre-luc@pierlux.com>
 * File inspired by champlain-version.h.in which is
 * Authored By Matthew Allum  <mallum@openedhand.com>
 * Copyright (C) 2006 OpenedHand
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

#ifndef __CHAMPLAIN_VERSION_H__
#define __CHAMPLAIN_VERSION_H__

/**
 * SECTION:champlain-version
 * @short_description: Versioning utility macros
 *
 * Champlain offers a set of macros for checking the version of the library
 * an application was linked to.
 */

/**
 * CHAMPLAIN_MAJOR_VERSION:
 *
 * The major version of libchamplain (1, if %CHAMPLAIN_VERSION is 1.2.3)
 */
#define CHAMPLAIN_MAJOR_VERSION   (0)

/**
 * CHAMPLAIN_MINOR_VERSION:
 *
 * The minor version of libchamplain (2, if %CHAMPLAIN_VERSION is 1.2.3)
 */
#define CHAMPLAIN_MINOR_VERSION   (12)

/**
 * CHAMPLAIN_MICRO_VERSION:
 *
 * The micro version of libchamplain (3, if %CHAMPLAIN_VERSION is 1.2.3)
 */
#define CHAMPLAIN_MICRO_VERSION   (16)

/**
 * CHAMPLAIN_VERSION:
 *
 * The full version of libchamplain, like 1.2.3
 */
#define CHAMPLAIN_VERSION         0.12.16

/**
 * CHAMPLAIN_VERSION_S:
 *
 * The full version of libchamplain, in string form (suited for
 * string concatenation)
 */
#define CHAMPLAIN_VERSION_S       "0.12.16"

/**
 * CHAMPLAIN_VERSION_HEX:
 *
 * Numerically encoded version of libchamplain, like 0x010203
 */
#define CHAMPLAIN_VERSION_HEX     ((CHAMPLAIN_MAJOR_VERSION << 24) | \
                                 (CHAMPLAIN_MINOR_VERSION << 16) | \
                                 (CHAMPLAIN_MICRO_VERSION << 8))

/**
 * CHAMPLAIN_CHECK_VERSION:
 * @major: major version, like 1 in 1.2.3
 * @minor: minor version, like 2 in 1.2.3
 * @micro: micro version, like 3 in 1.2.3
 *
 * Evaluates to %TRUE if the version of libchamplain is greater or equal
 * than @major, @minor and @micro
 */
#define CHAMPLAIN_CHECK_VERSION(major,minor,micro) \
        (CHAMPLAIN_MAJOR_VERSION > (major) || \
         (CHAMPLAIN_MAJOR_VERSION == (major) && CHAMPLAIN_MINOR_VERSION > (minor)) || \
         (CHAMPLAIN_MAJOR_VERSION == (major) && CHAMPLAIN_MINOR_VERSION == (minor) && CHAMPLAIN_MICRO_VERSION >= (micro)))

#endif /* __CHAMPLAIN_VERSION_H__ */
