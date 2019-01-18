/* Evolution calendar system timezone functions
 * Based on gnome-panel's clock-applet system-timezone.c file.
 *
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
 */

#include <glib/gstdio.h>
#include <gio/gio.h>
#include <string.h>
#include "e-cal-system-timezone.h"

#ifndef G_OS_WIN32

#ifdef HAVE_SOLARIS
#define SYSTEM_ZONEINFODIR "/usr/share/lib/zoneinfo/tab"
#else
#define SYSTEM_ZONEINFODIR "/usr/share/zoneinfo"
#endif

#define ETC_TIMEZONE        "/etc/timezone"
#define ETC_TIMEZONE_MAJ    "/etc/TIMEZONE"
#define ETC_RC_CONF         "/etc/rc.conf"
#define ETC_SYSCONFIG_CLOCK "/etc/sysconfig/clock"
#define ETC_CONF_D_CLOCK    "/etc/conf.d/clock"
#define ETC_LOCALTIME       "/etc/localtime"
#define VAR_DB_ZONEINFO     "/var/db/zoneinfo"

#define TZ_MAGIC "TZif"

static gchar *
system_timezone_strip_path_if_valid (const gchar *filename)
{
	gint skip;

	/* In case it's a relative path the '../' references the root (from the /etc) */
	if (filename && g_str_has_prefix (filename, "../"))
		filename += 2;

	if (!filename || !g_str_has_prefix (filename, SYSTEM_ZONEINFODIR "/"))
		return NULL;

	/* Timezone data files also live under posix/ and right/ for some
	 * reason.
	 * FIXME: make sure accepting those files is valid. I think "posix" is
	 * okay, not sure about "right" */
	if (g_str_has_prefix (filename, SYSTEM_ZONEINFODIR "/posix/"))
		skip = strlen (SYSTEM_ZONEINFODIR "/posix/");
	else if (g_str_has_prefix (filename, SYSTEM_ZONEINFODIR "/right/"))
		skip = strlen (SYSTEM_ZONEINFODIR "/right/");
	else
		skip = strlen (SYSTEM_ZONEINFODIR "/");

	return g_strdup (filename + skip);
}

/* Read the soft symlink from /etc/localtime */
static gchar *
system_timezone_read_etc_localtime_softlink (void)
{
	gchar *file;
	gchar *tz;

	if (!g_file_test (ETC_LOCALTIME, G_FILE_TEST_IS_SYMLINK))
		return NULL;

	file = g_file_read_link (ETC_LOCALTIME, NULL);
	tz = system_timezone_strip_path_if_valid (file);
	g_free (file);

	return tz;
}

/* Read from /var/db/zoneinfo, where tzsetup utility on FreeBSD stores the zone name */
static gchar *
system_timezone_read_var_db_zoneinfo (void)
{
	gchar *tz = NULL;

	if (!g_file_get_contents (VAR_DB_ZONEINFO, &tz, NULL, NULL))
		return NULL;

	if (tz)
		g_strchomp (tz);

	if (!tz || !*tz)
		g_clear_pointer (&tz, g_free);

	return tz;
}

static gchar *
system_timezone_read_etc_timezone (GHashTable *ical_zones)
{
	FILE    *etc_timezone;
	GString *reading;
	gint      c;

	etc_timezone = g_fopen (ETC_TIMEZONE, "r");
	if (!etc_timezone)
		return NULL;

	reading = g_string_new ("");

	c = fgetc (etc_timezone);
        /* only get the first line, we'll validate the value later */
	while (c != EOF && !g_ascii_isspace (c)) {
		reading = g_string_append_c (reading, c);
		c = fgetc (etc_timezone);
	}

	fclose (etc_timezone);

	if (reading->str && reading->str[0] != '\0')
		return g_string_free (reading, FALSE);
	else
		g_string_free (reading, TRUE);

	return NULL;
}

/* Read a file that looks like a key-file (but there's no need for groups)
 * and get the last value for a specific key */
static gchar *
system_timezone_read_key_file (const gchar *filename,
                               const gchar *key)
{
	GIOChannel *channel;
	gchar       *key_eq;
	gchar       *line;
	gchar       *retval;

	if (!g_file_test (filename, G_FILE_TEST_IS_REGULAR))
		return NULL;

	channel = g_io_channel_new_file (filename, "r", NULL);
	if (!channel)
		return NULL;

	key_eq = g_strdup_printf ("%s=", key);
	retval = NULL;

	while (g_io_channel_read_line (channel, &line, NULL,
				       NULL, NULL) == G_IO_STATUS_NORMAL) {
		if (g_str_has_prefix (line, key_eq)) {
			gchar *value;
			gint   len;

			value = line + strlen (key_eq);
			g_strstrip (value);

			len = strlen (value);

			if (value[0] == '\"' && value[len - 1] == '\"') {
				value += 1;
				len -= 2;
			}

			g_free (retval);
			retval = g_strndup (value, len);
			g_strstrip (retval);
		}

		g_free (line);
	}

	g_free (key_eq);
	g_io_channel_unref (channel);

	return retval;
}

/* This works for Fedora and Mandriva */
static gchar *
system_timezone_read_etc_sysconfig_clock (GHashTable *ical_zones)
{
	return system_timezone_read_key_file (
		ETC_SYSCONFIG_CLOCK, "ZONE");
}

/* This works for openSUSE */
static gchar *
system_timezone_read_etc_sysconfig_clock_alt (GHashTable *ical_zones)
{
	return system_timezone_read_key_file (
		ETC_SYSCONFIG_CLOCK, "TIMEZONE");
}

/* This works for Solaris/OpenSolaris */
static gchar *
system_timezone_read_etc_TIMEZONE (GHashTable *ical_zones)
{
	return system_timezone_read_key_file (
		ETC_TIMEZONE_MAJ, "TZ");
}

/* This works for Arch Linux */
static gchar *
system_timezone_read_etc_rc_conf (GHashTable *ical_zones)
{
	return system_timezone_read_key_file (
		ETC_RC_CONF, "TIMEZONE");
}

/* This works for old Gentoo */
static gchar *
system_timezone_read_etc_conf_d_clock (GHashTable *ical_zones)
{
	return system_timezone_read_key_file (
		ETC_CONF_D_CLOCK, "TIMEZONE");
}

static void
update_fallback (gchar **fallback,
                 gchar *adept,
                 GHashTable *ical_zones)
{
	g_return_if_fail (fallback != NULL);

	/* ignore those not available in libical */
	if (adept && ical_zones) {
		if (!g_hash_table_contains (ical_zones, adept) ||
		    (*fallback && g_hash_table_contains (ical_zones, *fallback))) {
			g_free (adept);
			return;
		}
	}

	if (!*fallback) {
		*fallback = adept;
		return;
	}

	if (!adept)
		return;

	if (strlen (*fallback) < strlen (adept)) {
		g_free (*fallback);
		*fallback = adept;
	} else {
		g_free (adept);
	}
}

typedef gboolean (*CompareFiles) (struct stat *a_stat,
				  struct stat *b_stat,
				  const gchar  *a_content,
				  gsize	a_content_len,
				  const gchar  *b_filename);

static gchar *
recursive_compare (struct stat *localtime_stat,
                   const gchar *localtime_content,
                   gsize localtime_content_len,
                   const gchar *file,
                   CompareFiles compare_func,
                   GHashTable *ical_zones,
                   gint deep_level,
                   gchar **fallback)
{
	struct stat file_stat;

	if (g_stat (file, &file_stat) != 0)
		return NULL;

	if (S_ISREG (file_stat.st_mode)) {
		if (compare_func (localtime_stat,
				  &file_stat,
				  localtime_content,
				  localtime_content_len,
				  file)) {
			gchar *tz = system_timezone_strip_path_if_valid (file);

			if (deep_level <= 1 || (ical_zones && g_hash_table_contains (ical_zones, tz))) {
				update_fallback (fallback, tz, ical_zones);
				return NULL;
			}

			if (ical_zones && !g_hash_table_contains (ical_zones, tz)) {
				g_free (tz);
				return NULL;
			}

			return tz;
		} else
			return NULL;
	} else if (S_ISDIR (file_stat.st_mode)) {
		GDir       *dir = NULL;
		gchar       *ret = NULL;
		const gchar *subfile = NULL;
		gchar       *subpath = NULL;

		dir = g_dir_open (file, 0, NULL);
		if (dir == NULL)
			return NULL;

		while ((subfile = g_dir_read_name (dir)) != NULL) {
			subpath = g_build_filename (file, subfile, NULL);

			ret = recursive_compare (
				localtime_stat,
				localtime_content,
				localtime_content_len,
				subpath,
				compare_func,
				ical_zones,
				deep_level + 1,
				fallback);

			g_free (subpath);

			if (ret != NULL)
				break;
		}

		g_dir_close (dir);

		return ret;
	}

	return NULL;
}

static gboolean
files_are_identical_inode (struct stat *a_stat,
                           struct stat *b_stat,
                           const gchar *a_content,
                           gsize a_content_len,
                           const gchar *b_filename)
{
	gboolean res = a_stat->st_ino == b_stat->st_ino;

	if (res) {
		const gchar *filename;

		filename = strrchr (b_filename, '/');
		if (filename)
			filename++;
		else
			filename = b_filename;

		/* There is a 'localtime' soft link to /etc/localtime in the
		 * zoneinfo directory on Slackware, thus rather skip this file.
		 */
		res = !g_str_equal (filename, "localtime");
	}

	return res;
}

/* Determine if /etc/localtime is a hard link to some file, by looking at
 * the inodes */
static gchar *
system_timezone_read_etc_localtime_hardlink (GHashTable *ical_zones)
{
	struct stat stat_localtime;
	gchar *retval, *fallback = NULL;

	if (g_stat (ETC_LOCALTIME, &stat_localtime) != 0)
		return NULL;

	if (!S_ISREG (stat_localtime.st_mode))
		return NULL;

	retval = recursive_compare (
		&stat_localtime,
		NULL,
		0,
		SYSTEM_ZONEINFODIR,
		files_are_identical_inode,
		ical_zones,
		0,
		&fallback);

	if (retval)
		g_free (fallback);
	else
		retval = fallback;

	return retval;
}

static gboolean
files_are_identical_content (struct stat *a_stat,
                             struct stat *b_stat,
                             const gchar *a_content,
                             gsize a_content_len,
                             const gchar *b_filename)
{
	gchar  *b_content = NULL;
	gsize  b_content_len = -1;
	gint    cmp;

	if (a_stat->st_size != b_stat->st_size)
		return FALSE;

	if (!g_file_get_contents (b_filename,
				 &b_content, &b_content_len, NULL))
		return FALSE;

	if (a_content_len != b_content_len) {
		g_free (b_content);
		return FALSE;
	}

	cmp = memcmp (a_content, b_content, a_content_len);
	g_free (b_content);

	return (cmp == 0);
}

/* Determine if /etc/localtime is a copy of a timezone file */
static gchar *
system_timezone_read_etc_localtime_content (GHashTable *ical_zones)
{
	static gchar *last_localtime_content = NULL;
	static gsize last_localtime_content_len = -1;
	static gchar *last_timezone = NULL;
	static GRecMutex mutex;

	struct stat stat_localtime;
	gchar *localtime_content = NULL;
	gsize localtime_content_len = -1;
	gchar *retval, *fallback = NULL;

	if (g_stat (ETC_LOCALTIME, &stat_localtime) != 0)
		return NULL;

	if (!S_ISREG (stat_localtime.st_mode))
		return NULL;

	if (!g_file_get_contents (ETC_LOCALTIME,
				  &localtime_content,
				  &localtime_content_len,
				  NULL))
		return NULL;

	g_rec_mutex_lock (&mutex);

	if (last_localtime_content) {
		if (localtime_content_len != last_localtime_content_len
		    || memcmp (localtime_content, last_localtime_content, localtime_content_len) != 0) {
			g_free (last_localtime_content);
			g_free (last_timezone);
			last_localtime_content = NULL;
			last_localtime_content_len = -1;
			last_timezone = NULL;
		} else {
			retval = g_strdup (last_timezone);
			g_rec_mutex_unlock (&mutex);

			g_free (localtime_content);
			return retval;
		}
	}

	retval = recursive_compare (
		&stat_localtime,
		localtime_content,
		localtime_content_len,
		SYSTEM_ZONEINFODIR,
		files_are_identical_content,
		ical_zones,
		0,
		&fallback);

	if (retval)
		g_free (fallback);
	else
		retval = fallback;

	if (retval) {
		last_localtime_content = localtime_content;
		last_localtime_content_len = localtime_content_len;
		last_timezone = g_strdup (retval);
	} else {
		g_free (localtime_content);
	}

	g_rec_mutex_unlock (&mutex);

	return retval;
}

typedef gchar * (*GetSystemTimezone) (GHashTable *ical_zones);
/* The order of the functions here define the priority of the methods used
 * to find the timezone. First method has higher priority. */
static GetSystemTimezone get_system_timezone_methods_config[] = {
	/* reading various config files */
	system_timezone_read_etc_timezone,
	system_timezone_read_etc_sysconfig_clock,
	system_timezone_read_etc_sysconfig_clock_alt,
	system_timezone_read_etc_TIMEZONE,
	system_timezone_read_etc_rc_conf,
	/* reading deprecated config files */
	system_timezone_read_etc_conf_d_clock,
	NULL
};

static GetSystemTimezone get_system_timezone_methods_slow[] = {
	/* reading /etc/timezone directly. Expensive since we have to stat
	 * many files, but it returns always correct values, even on KDE */
	system_timezone_read_etc_localtime_content,
	system_timezone_read_etc_localtime_hardlink,
	NULL
};

static gboolean
system_timezone_is_valid (const gchar *tz,
                          GHashTable *ical_zones)
{
	const gchar *c;

	if (tz == NULL)
		return FALSE;

	for (c = tz; *c != '\0'; c++) {
		if (!(g_ascii_isalnum (*c) ||
		    *c == '/' || *c == '-' || *c == '_'))
			return FALSE;
	}

	if (ical_zones == NULL)
		return TRUE;

	return g_hash_table_contains (ical_zones, tz);
}

static gchar *
system_timezone_find (void)
{
	GHashTable *ical_zones;
	icalarray *builtin_timezones;
	gint ii;
	gchar *tz, *config_tz = NULL;

	/* return only timezones known to libical */
	ical_zones = g_hash_table_new_full (g_str_hash, g_str_equal, g_free, NULL);
	g_hash_table_add (ical_zones, g_strdup ("UTC"));

	builtin_timezones = icaltimezone_get_builtin_timezones ();
	for (ii = 0; ii < builtin_timezones->num_elements; ii++) {
		icaltimezone *zone;
		const gchar *location;

		zone = icalarray_element_at (builtin_timezones, ii);
		if (!zone)
			continue;

		location = icaltimezone_get_location (zone);
		if (location)
			g_hash_table_add (
				ical_zones, g_strdup (location));
	}

	/* softlink is the best option, it points to the correct file */
	tz = system_timezone_read_etc_localtime_softlink ();
	if (!tz)
		tz = system_timezone_read_var_db_zoneinfo ();
	if (system_timezone_is_valid (tz, ical_zones)) {
		g_hash_table_destroy (ical_zones);
		return tz;
	}

	g_free (tz);

	config_tz = NULL;

	/* read correct timezone name from config file; checking
	 * on /etc/localtime content can pick wrong timezone name,
	 * even the file is same
	 */
	for (ii = 0; get_system_timezone_methods_config[ii] != NULL; ii++) {
		config_tz = get_system_timezone_methods_config[ii] (ical_zones);

		if (system_timezone_is_valid (config_tz, ical_zones)) {
			break;
		}

		g_free (config_tz);
		config_tz = NULL;
	}

	if (config_tz) {
		struct stat stat_localtime;
		gchar *localtime_content = NULL;
		gsize localtime_content_len = -1;

		if (g_stat (ETC_LOCALTIME, &stat_localtime) == 0 &&
		    S_ISREG (stat_localtime.st_mode) &&
		    g_file_get_contents (ETC_LOCALTIME,
					 &localtime_content,
					 &localtime_content_len,
					 NULL)) {
			struct stat stat_config_tz;
			gchar *filename;

			filename = g_build_filename (
				SYSTEM_ZONEINFODIR, config_tz, NULL);

			if (filename &&
			    g_stat (filename, &stat_config_tz) == 0 &&
			    files_are_identical_content (&stat_localtime,
				&stat_config_tz,
				localtime_content,
				localtime_content_len,
				filename)) {
				g_free (filename);
				g_free (localtime_content);
				g_hash_table_destroy (ical_zones);

				/* Corresponding file name to config_tz matches
				 * /etc/localtime, thus that's the correct one.
				 * Return it as system timezone; bonus is that
				 * it might match configured system timezone
				 * name too. */
				return config_tz;
			}
			g_free (filename);
		}

		g_free (localtime_content);
	}

	for (ii = 0; get_system_timezone_methods_slow[ii] != NULL; ii++) {
		tz = get_system_timezone_methods_slow[ii] (ical_zones);

		if (system_timezone_is_valid (tz, ical_zones)) {
			g_hash_table_destroy (ical_zones);
			g_free (config_tz);
			return tz;
		}

		g_free (tz);
	}

	g_hash_table_destroy (ical_zones);

	return config_tz;
}

#else /* G_OS_WIN32 */
#include <windows.h>

struct timezone_map_entry {
	const gchar *windows_string;
	const gchar *olson_string;
};

static gchar *
windows_timezone_string_to_olson (const gchar *windows_tz)
{
	/* source: http://www.chronos-st.org/Windows-to-Olson.txt */
	static const struct timezone_map_entry timezone_map[] = {
		{ "Afghanistan", "Asia/Kabul" },
		{ "Afghanistan Standard Time", "Asia/Kabul" },
		{ "Alaskan", "America/Anchorage" },
		{ "Alaskan Standard Time", "America/Anchorage" },
		{ "Arab", "Asia/Riyadh" },
		{ "Arab Standard Time", "Asia/Riyadh" },
		{ "Arabian", "Asia/Muscat" },
		{ "Arabian Standard Time", "Asia/Muscat" },
		{ "Arabic Standard Time", "Asia/Baghdad" },
		{ "Atlantic", "America/Halifax" },
		{ "Atlantic Standard Time", "America/Halifax" },
		{ "AUS Central", "Australia/Darwin" },
		{ "AUS Central Standard Time", "Australia/Darwin" },
		{ "AUS Eastern", "Australia/Sydney" },
		{ "AUS Eastern Standard Time", "Australia/Sydney" },
		{ "Azerbaijan Standard Time", "Asia/Baku" },
		{ "Azores", "Atlantic/Azores" },
		{ "Azores Standard Time", "Atlantic/Azores" },
		{ "Bangkok", "Asia/Bangkok" },
		{ "Bangkok Standard Time", "Asia/Bangkok" },
		{ "Beijing", "Asia/Shanghai" },
		{ "Canada Central", "America/Regina" },
		{ "Canada Central Standard Time", "America/Regina" },
		{ "Cape Verde Standard Time", "Atlantic/Cape_Verde" },
		{ "Caucasus", "Asia/Yerevan" },
		{ "Caucasus Standard Time", "Asia/Yerevan" },
		{ "Cen. Australia", "Australia/Adelaide" },
		{ "Cen. Australia Standard Time", "Australia/Adelaide" },
		{ "Central", "America/Chicago" },
		{ "Central America Standard Time", "America/Regina" },
		{ "Central Asia", "Asia/Dhaka" },
		{ "Central Asia Standard Time", "Asia/Dhaka" },
		{ "Central Brazilian Standard Time", "America/Manaus" },
		{ "Central Europe", "Europe/Prague" },
		{ "Central Europe Standard Time", "Europe/Prague" },
		{ "Central European", "Europe/Belgrade" },
		{ "Central European Standard Time", "Europe/Belgrade" },
		{ "Central Pacific", "Pacific/Guadalcanal" },
		{ "Central Pacific Standard Time", "Pacific/Guadalcanal" },
		{ "Central Standard Time", "America/Chicago" },
		{ "Central Standard Time (Mexico)", "America/Mexico_City" },
		{ "China", "Asia/Shanghai" },
		{ "China Standard Time", "Asia/Shanghai" },
		{ "Dateline", "GMT-1200" },
		{ "Dateline Standard Time", "GMT-1200" },
		{ "E. Africa", "Africa/Nairobi" },
		{ "E. Africa Standard Time", "Africa/Nairobi" },
		{ "E. Australia", "Australia/Brisbane" },
		{ "E. Australia Standard Time", "Australia/Brisbane" },
		{ "E. Europe", "Europe/Minsk" },
		{ "E. Europe Standard Time", "Europe/Minsk" },
		{ "E. South America", "America/Sao_Paulo" },
		{ "E. South America Standard Time", "America/Sao_Paulo" },
		{ "Eastern", "America/New_York" },
		{ "Eastern Standard Time", "America/New_York" },
		{ "Egypt", "Africa/Cairo" },
		{ "Egypt Standard Time", "Africa/Cairo" },
		{ "Ekaterinburg", "Asia/Yekaterinburg" },
		{ "Ekaterinburg Standard Time", "Asia/Yekaterinburg" },
		{ "Fiji", "Pacific/Fiji" },
		{ "Fiji Standard Time", "Pacific/Fiji" },
		{ "FLE", "Europe/Helsinki" },
		{ "FLE Standard Time", "Europe/Helsinki" },
		{ "Georgian Standard Time", "Asia/Tbilisi" },
		{ "GFT", "Europe/Athens" },
		{ "GFT Standard Time", "Europe/Athens" },
		{ "GMT", "Europe/London" },
		{ "GMT Standard Time", "Europe/London" },
		{ "GMT Standard Time", "GMT" },
		{ "Greenland Standard Time", "America/Godthab" },
		{ "Greenwich", "GMT" },
		{ "Greenwich Standard Time", "GMT" },
		{ "GTB", "Europe/Athens" },
		{ "GTB Standard Time", "Europe/Athens" },
		{ "Hawaiian", "Pacific/Honolulu" },
		{ "Hawaiian Standard Time", "Pacific/Honolulu" },
		{ "India", "Asia/Calcutta" },
		{ "India Standard Time", "Asia/Calcutta" },
		{ "Iran", "Asia/Tehran" },
		{ "Iran Standard Time", "Asia/Tehran" },
		{ "Israel", "Asia/Jerusalem" },
		{ "Israel Standard Time", "Asia/Jerusalem" },
		{ "Jordan Standard Time", "Asia/Amman" },
		{ "Korea", "Asia/Seoul" },
		{ "Korea Standard Time", "Asia/Seoul" },
		{ "Mexico", "America/Mexico_City" },
		{ "Mexico Standard Time", "America/Mexico_City" },
		{ "Mexico Standard Time 2", "America/Chihuahua" },
		{ "Mid-Atlantic", "Atlantic/South_Georgia" },
		{ "Mid-Atlantic Standard Time", "Atlantic/South_Georgia" },
		{ "Middle East Standard Time", "Asia/Beirut" },
		{ "Mountain", "America/Denver" },
		{ "Mountain Standard Time", "America/Denver" },
		{ "Mountain Standard Time (Mexico)", "America/Chihuahua" },
		{ "Myanmar Standard Time", "Asia/Rangoon" },
		{ "N. Central Asia Standard Time", "Asia/Novosibirsk" },
		{ "Namibia Standard Time", "Africa/Windhoek" },
		{ "Nepal Standard Time", "Asia/Katmandu" },
		{ "New Zealand", "Pacific/Auckland" },
		{ "New Zealand Standard Time", "Pacific/Auckland" },
		{ "Newfoundland", "America/St_Johns" },
		{ "Newfoundland Standard Time", "America/St_Johns" },
		{ "North Asia East Standard Time", "Asia/Ulaanbaatar" },
		{ "North Asia Standard Time", "Asia/Krasnoyarsk" },
		{ "Pacific", "America/Los_Angeles" },
		{ "Pacific SA", "America/Santiago" },
		{ "Pacific SA Standard Time", "America/Santiago" },
		{ "Pacific Standard Time", "America/Los_Angeles" },
		{ "Pacific Standard Time (Mexico)", "America/Tijuana" },
		{ "Prague Bratislava", "Europe/Prague" },
		{ "Romance", "Europe/Paris" },
		{ "Romance Standard Time", "Europe/Paris" },
		{ "Russian", "Europe/Moscow" },
		{ "Russian Standard Time", "Europe/Moscow" },
		{ "SA Eastern", "America/Buenos_Aires" },
		{ "SA Eastern Standard Time", "America/Buenos_Aires" },
		{ "SA Pacific", "America/Bogota" },
		{ "SA Pacific Standard Time", "America/Bogota" },
		{ "SA Western", "America/Caracas" },
		{ "SA Western Standard Time", "America/Caracas" },
		{ "Samoa", "Pacific/Apia" },
		{ "Samoa Standard Time", "Pacific/Apia" },
		{ "Saudi Arabia", "Asia/Riyadh" },
		{ "Saudi Arabia Standard Time", "Asia/Riyadh" },
		{ "SE Asia", "Asia/Bangkok" },
		{ "SE Asia Standard Time", "Asia/Bangkok" },
		{ "Singapore", "Asia/Singapore" },
		{ "Singapore Standard Time", "Asia/Singapore" },
		{ "South Africa", "Africa/Harare" },
		{ "South Africa Standard Time", "Africa/Harare" },
		{ "Sri Lanka", "Asia/Colombo" },
		{ "Sri Lanka Standard Time", "Asia/Colombo" },
		{ "Sydney Standard Time", "Australia/Sydney" },
		{ "Taipei", "Asia/Taipei" },
		{ "Taipei Standard Time", "Asia/Taipei" },
		{ "Tasmania", "Australia/Hobart" },
		{ "Tasmania Standard Time", "Australia/Hobart" },
		{ "Tasmania Standard Time", "Australia/Hobart" },
		{ "Tokyo", "Asia/Tokyo" },
		{ "Tokyo Standard Time", "Asia/Tokyo" },
		{ "Tonga Standard Time", "Pacific/Tongatapu" },
		{ "US Eastern", "America/Indianapolis" },
		{ "US Eastern Standard Time", "America/Indianapolis" },
		{ "US Mountain", "America/Phoenix" },
		{ "US Mountain Standard Time", "America/Phoenix" },
		{ "Vladivostok", "Asia/Vladivostok" },
		{ "Vladivostok Standard Time", "Asia/Vladivostok" },
		{ "W. Australia", "Australia/Perth" },
		{ "W. Australia Standard Time", "Australia/Perth" },
		{ "W. Central Africa Standard Time", "Africa/Luanda" },
		{ "W. Europe", "Europe/Berlin" },
		{ "W. Europe Standard Time", "Europe/Berlin" },
		{ "Warsaw", "Europe/Warsaw" },
		{ "West Asia", "Asia/Karachi" },
		{ "West Asia Standard Time", "Asia/Karachi" },
		{ "West Pacific", "Pacific/Guam" },
		{ "West Pacific Standard Time", "Pacific/Guam" },
		{ "Western Brazilian Standard Time", "America/Rio_Branco" },
		{ "Yakutsk", "Asia/Yakutsk" },
		{ "Yakutsk Standard Time", "Asia/Yakutsk" },
		{ 0, 0 } // end marker
	};

	gint i;

	for (i = 0; timezone_map[i].windows_string && windows_tz; i++) {
		gint res = strcmp ( timezone_map[i].windows_string, windows_tz);
		if (res > 0)
			return NULL;
		if (res == 0) {
			return g_strdup (timezone_map[i].olson_string);
		}
	}

	return NULL;
}

#define MAX_VALUE_NAME 4096

static gchar *
system_timezone_win32_query_registry (void)
{
	DWORD type;
	DWORD size;
	LONG res;
	DWORD i;

	static HKEY reg_key = (HKEY) INVALID_HANDLE_VALUE;
	static HKEY reg_subkey = (HKEY) INVALID_HANDLE_VALUE;
	gchar timeZone[MAX_VALUE_NAME] = "";
	gchar timeZoneStd[MAX_VALUE_NAME] = "";
	gchar subKey[MAX_VALUE_NAME] = "";

	res = RegOpenKeyExA (
		HKEY_LOCAL_MACHINE,
		"SYSTEM\\CurrentControlSet\\Control\\TimeZoneInformation", 0,
		KEY_READ, &reg_key);
	if (res != ERROR_SUCCESS) {
		g_debug ("Could not find system timezone! (1)\n");
		return NULL;
	}

	/* On Windows Vista, Windows Server 2008 and later,
	 * the Windows timezone name is the value of 'TimeZoneKeyName' */

	size = MAX_VALUE_NAME;
	res = RegQueryValueExA (
		reg_key, "TimeZoneKeyName", 0, &type, (LPBYTE) timeZone, &size);

	if (type == REG_SZ && res == ERROR_SUCCESS) {
		RegCloseKey (reg_key);
		g_debug ("Windows Timezone String (1): %s\n", timeZone);
		return g_strdup (timeZone);
	}

	/* On older Windows, we must first find the value of 'StandardName' */

	res = RegQueryValueExA (
		reg_key, "StandardName", 0, &type, (LPBYTE) timeZone, &size);

	if (type != REG_SZ || res != ERROR_SUCCESS) {
		RegCloseKey (reg_key);
		g_debug ("Could not find system timezone! (2)\n");
		return NULL;
	}

	RegCloseKey (reg_key);

	/* Windows NT and its family */
	res = RegOpenKeyExA (
		HKEY_LOCAL_MACHINE,
		"SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Time Zones",
		0, KEY_READ, &reg_key);
	if (res != ERROR_SUCCESS) {
		g_debug ("Could not find the timezone! (3)\n");
		return NULL;
	}

	for (i = 0, res = ERROR_SUCCESS; res != ERROR_NO_MORE_ITEMS; i++) {
		size = MAX_VALUE_NAME;
		res = RegEnumKeyEx (reg_key, i, subKey, &size, NULL, NULL, NULL, NULL);
		if (res == ERROR_SUCCESS) {
			res = RegOpenKeyExA (
				reg_key, subKey, 0, KEY_READ, &reg_subkey);
			if (res != ERROR_SUCCESS)
				continue;
			size = MAX_VALUE_NAME;
			res = RegQueryValueExA (
				reg_subkey, "Std", 0, &type,
				(LPBYTE) timeZoneStd, &size);
			RegCloseKey (reg_subkey);
			if (type != REG_SZ || res != ERROR_SUCCESS) {
				continue;
			}
			if (g_strcmp0 (timeZone,timeZoneStd) == 0) {
				RegCloseKey (reg_key);
				g_debug ("Windows Timezone String (2): %s\n", subKey);
				return g_strdup (subKey);
			}
		}
	}

	g_debug ("Could not find system timezone! (3)\n");
	RegCloseKey (reg_key);
	return NULL;
}

#endif /* G_OS_WIN32 */

/**
 * e_cal_system_timezone_get_location:
 *
 * Fetches the system timezone location string.
 *
 * Note: Since 3.4 the returned timezone location is either NULL or
 * an equivalent within known libical timezones.
 *
 * The returned string should be freed with g_free().
 *
 * Returns: (transfer full): system timezone location string, or %NULL on an error.
 *
 * Since: 2.28
 **/
gchar *
e_cal_system_timezone_get_location (void)
{
#ifndef G_OS_WIN32
	return system_timezone_find ();
#else
	gchar *windows_timezone_string = NULL;
	gchar *olson_timezone_string = NULL;

	if (!(windows_timezone_string = system_timezone_win32_query_registry ()))
		return NULL;
	olson_timezone_string =
		windows_timezone_string_to_olson (windows_timezone_string);
	g_free (windows_timezone_string);
	if (!olson_timezone_string)
		return NULL;
	g_debug ("Olson Timezone String: %s\n", olson_timezone_string);
	return olson_timezone_string;
#endif
}
