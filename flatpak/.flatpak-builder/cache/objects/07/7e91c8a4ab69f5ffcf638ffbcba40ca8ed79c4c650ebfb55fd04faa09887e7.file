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
 * Authors: Michael Zucchi <notzed@ximian.com>
 */

#include "evolution-data-server-config.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef HAVE_BACKTRACE_SYMBOLS
#include <execinfo.h>
#ifdef HAVE_ELFUTILS_LIBDWFL
#include <elfutils/libdwfl.h>
#include <errno.h>
#include <unistd.h>
#endif
#endif

#include <glib-object.h>

#include "camel-debug.h"

gint camel_verbose_debug;

static GHashTable *debug_table = NULL;

/**
 * camel_debug_init:
 *
 * Init camel debug.
 *
 * CAMEL_DEBUG is set to a comma separated list of modules to debug.
 * The modules can contain module-specific specifiers after a ':', or
 * just act as a wildcard for the module or even specifier.  e.g. 'imap'
 * for imap debug, or 'imap:folder' for imap folder debug.  Additionaly,
 * ':folder' can be used for a wildcard for any folder operations.
 **/
void
camel_debug_init (void)
{
	gchar *d;

	d = g_strdup (getenv ("CAMEL_DEBUG"));
	if (d) {
		gchar *p;

		debug_table = g_hash_table_new (g_str_hash, g_str_equal);
		p = d;
		while (*p) {
			while (*p && *p != ',')
				p++;
			if (*p)
				*p++ = 0;
			g_hash_table_insert (debug_table, d, d);
			d = p;
		}

		if (g_hash_table_lookup (debug_table, "all"))
			camel_verbose_debug = 1;
	}
}

/**
 * camel_debug:
 * @mode: string name of the mode to check for
 *
 * Check to see if a debug mode is activated.  @mode takes one of two forms,
 * a fully qualified 'module:target', or a wildcard 'module' name.  It
 * returns a boolean to indicate if the module or module and target is
 * currently activated for debug output.
 *
 * Returns: Whether the debug @mode is activated
 **/
gboolean
camel_debug (const gchar *mode)
{
	if (camel_verbose_debug)
		return TRUE;

	if (debug_table) {
		gchar *colon;
		gchar *fallback;
		gsize fallback_len;

		if (g_hash_table_lookup (debug_table, mode))
			return TRUE;

		/* Check for fully qualified debug */
		colon = strchr (mode, ':');
		if (colon) {
			fallback_len = strlen (mode) + 1;
			fallback = g_alloca (fallback_len);
			g_strlcpy (fallback, mode, fallback_len);
			colon = (colon - mode) + fallback;
			/* Now check 'module[:*]' */
			*colon = 0;
			if (g_hash_table_lookup (debug_table, fallback))
				return TRUE;
			/* Now check ':subsystem' */
			*colon = ':';
			if (g_hash_table_lookup (debug_table, colon))
				return TRUE;
		}
	}

	return FALSE;
}

static GMutex debug_lock;
/**
 * camel_debug_start:
 * @mode: string name of the mode to start the debug for
 *
 * Start debug output for a given mode, used to make sure debug output
 * is output atomically and not interspersed with unrelated stuff.
 *
 * Returns: %TRUE if mode is set, and in which case, you must
 * call camel_debug_end() when finished any screen output.
 **/
gboolean
camel_debug_start (const gchar *mode)
{
	if (camel_debug (mode)) {
		g_mutex_lock (&debug_lock);
		printf ("Thread %p >\n", g_thread_self ());
		return TRUE;
	}

	return FALSE;
}

/**
 * camel_debug_end:
 *
 * Call this when you're done with your debug output.  If and only if
 * you called camel_debug_start, and if it returns TRUE.
 **/
void
camel_debug_end (void)
{
	printf ("< %p >\n", g_thread_self ());
	g_mutex_unlock (&debug_lock);
}

#if 0
#include <sys/debugreg.h>

static unsigned
i386_length_and_rw_bits (gint len,
                         enum target_hw_bp_type type)
{
  unsigned rw;

  switch (type)
    {
      case hw_execute:
	rw = DR_RW_EXECUTE;
	break;
      case hw_write:
	rw = DR_RW_WRITE;
	break;
      case hw_read:      /* x86 doesn't support data-read watchpoints */
      case hw_access:
	rw = DR_RW_READ;
	break;
#if 0
      case hw_io_access: /* not yet supported */
	rw = DR_RW_IORW;
	break;
#endif
      default:
	internal_error (__FILE__, __LINE__, "Invalid hw breakpoint type %d in i386_length_and_rw_bits.\n", (gint) type);
    }

  switch (len)
    {
      case 1:
	return (DR_LEN_1 | rw);
      case 2:
	return (DR_LEN_2 | rw);
      case 4:
	return (DR_LEN_4 | rw);
      case 8:
	if (TARGET_HAS_DR_LEN_8)
	  return (DR_LEN_8 | rw);
      default:
	internal_error (__FILE__, __LINE__, "Invalid hw breakpoint length %d in i386_length_and_rw_bits.\n", len);
    }
}

#define I386_DR_SET_RW_LEN(i,rwlen) \
  do { \
    dr_control_mirror &= ~(0x0f << (DR_CONTROL_SHIFT + DR_CONTROL_SIZE * (i))); \
    dr_control_mirror |= ((rwlen) << (DR_CONTROL_SHIFT + DR_CONTROL_SIZE * (i))); \
  } while (0)

#define I386_DR_LOCAL_ENABLE(i) \
  dr_control_mirror |= (1 << (DR_LOCAL_ENABLE_SHIFT + DR_ENABLE_SIZE * (i)))

#define set_dr(regnum, val) \
		__asm__("movl %0,%%db" #regnum \
			: /* no output */ \
			:"r" (val))

#define get_dr(regnum, val) \
		__asm__("movl %%db" #regnum ", %0" \
			:"=r" (val))

/* fine idea, but it doesn't work, crashes in get_dr :-/ */
void
camel_debug_hwatch (gint wp,
                    gpointer addr)
{
     guint32 control, rw;

     g_return_if_fail (wp <= DR_LASTADDR);
     g_return_if_fail (sizeof (addr) == 4);

     get_dr (7, control);
     /* set watch mode + size */
     rw = DR_RW_WRITE | DR_LEN_4;
     control &= ~(((1 << DR_CONTROL_SIZE) - 1) << (DR_CONTROL_SHIFT + DR_CONTROL_SIZE * wp));
     control |= rw << (DR_CONTROL_SHIFT + DR_CONTROL_SIZE * wp);
     /* set watch enable */
     control |= ( 1<< (DR_LOCAL_ENABLE_SHIFT + DR_ENABLE_SIZE * wp));
     control |= DR_LOCAL_SLOWDOWN;
     control &= ~DR_CONTROL_RESERVED;

     switch (wp) {
     case 0:
	     set_dr (0, addr);
	     break;
     case 1:
	     set_dr (1, addr);
	     break;
     case 2:
	     set_dr (2, addr);
	     break;
     case 3:
	     set_dr (3, addr);
	     break;
     }
     set_dr (7, control);
}

#endif

G_LOCK_DEFINE_STATIC (ptr_tracker);
static GHashTable *ptr_tracker = NULL;

struct pt_data {
	gpointer ptr;
	gchar *info;
	GString *backtrace;
};

static void
free_pt_data (gpointer ptr)
{
	struct pt_data *ptd = ptr;

	if (!ptd)
		return;

	g_free (ptd->info);
	if (ptd->backtrace)
		g_string_free (ptd->backtrace, TRUE);
	g_free (ptd);
}

static void demangle_bt (GString *bt);

static void
dump_left_ptrs_cb (gpointer key,
                   gpointer value,
                   gpointer user_data)
{
	guint *left = user_data;
	struct pt_data *ptd = value;
	gboolean have_info = ptd && ptd->info;
	gboolean have_bt = ptd && ptd->backtrace && ptd->backtrace->str && *ptd->backtrace->str;

	if (have_bt)
		demangle_bt (ptd->backtrace);

	*left = (*left) - 1;

	g_print ("      %p %s%s%s%s%s%s\n", key, have_info ? "(" : "", have_info ? ptd->info : "", have_info ? ")" : "", have_bt ? "\n" : "", have_bt ? ptd->backtrace->str : "", have_bt && *left > 0 ? "\n" : "");
}

#ifdef HAVE_BACKTRACE_SYMBOLS
static guint
by_backtrace_hash (gconstpointer ptr)
{
	const struct pt_data *ptd = ptr;

	if (!ptd || !ptd->backtrace)
		return 0;

	return g_str_hash (ptd->backtrace->str);
}

static gboolean
by_backtrace_equal (gconstpointer ptr1,
                    gconstpointer ptr2)
{
	const struct pt_data *ptd1 = ptr1, *ptd2 = ptr2;

	if ((!ptd1 || !ptd1->backtrace) && (!ptd2 || !ptd2->backtrace))
		return TRUE;

	return ptd1 && ptd1->backtrace && ptd2 && ptd2->backtrace && g_str_equal (ptd1->backtrace->str, ptd2->backtrace->str);
}

static void
dump_by_backtrace_cb (gpointer key,
                      gpointer value,
                      gpointer user_data)
{
	guint *left = user_data;
	struct pt_data *ptd = key;
	guint count = GPOINTER_TO_UINT (value);

	if (count == 1) {
		dump_left_ptrs_cb (ptd->ptr, ptd, left);
	} else {
		gboolean have_info = ptd && ptd->info;
		gboolean have_bt = ptd && ptd->backtrace && ptd->backtrace->str && *ptd->backtrace->str;

		if (have_bt)
			demangle_bt (ptd->backtrace);

		*left = (*left) - 1;

		g_print ("      %d x %s%s%s%s%s%s\n", count, have_info ? "(" : "", have_info ? ptd->info : "", have_info ? ")" : "", have_bt ? "\n" : "", have_bt ? ptd->backtrace->str : "", have_bt && *left > 0 ? "\n" : "");
	}
}

static void
dump_by_backtrace (GHashTable *ptrs)
{
	GHashTable *by_bt = g_hash_table_new (by_backtrace_hash, by_backtrace_equal);
	GHashTableIter iter;
	gpointer key, value;
	struct ptr_data *ptd;
	guint count;

	g_hash_table_iter_init (&iter, ptrs);
	while (g_hash_table_iter_next (&iter, &key, &value)) {
		guint cnt;

		ptd = value;
		if (!ptd)
			continue;

		cnt = GPOINTER_TO_UINT (g_hash_table_lookup (by_bt, ptd));
		cnt++;

		g_hash_table_insert (by_bt, ptd, GUINT_TO_POINTER (cnt));
	}

	count = g_hash_table_size (by_bt);
	g_hash_table_foreach (by_bt, dump_by_backtrace_cb, &count);
	g_hash_table_destroy (by_bt);
}
#endif /* HAVE_BACKTRACE_SYMBOLS */

static void
dump_tracked_ptrs (gboolean is_at_exit)
{
	G_LOCK (ptr_tracker);

	if (ptr_tracker) {
		g_print ("\n----------------------------------------------------------\n");
		if (g_hash_table_size (ptr_tracker) == 0) {
			g_print ("   All tracked pointers were properly removed\n");
		} else {
			guint count = g_hash_table_size (ptr_tracker);
			g_print ("   Left %d tracked pointers:\n", count);
			#ifdef HAVE_BACKTRACE_SYMBOLS
			dump_by_backtrace (ptr_tracker);
			#else
			g_hash_table_foreach (ptr_tracker, dump_left_ptrs_cb, &count);
			#endif
		}
		g_print ("----------------------------------------------------------\n");
	} else if (!is_at_exit) {
		g_print ("\n----------------------------------------------------------\n");
		g_print ("   Did not track any pointers yet\n");
		g_print ("----------------------------------------------------------\n");
	}

	G_UNLOCK (ptr_tracker);
}

#ifdef HAVE_BACKTRACE_SYMBOLS

#ifdef HAVE_ELFUTILS_LIBDWFL
static Dwfl *
dwfl_get (gboolean reload)
{
	static gchar *debuginfo_path = NULL;
	static Dwfl *dwfl = NULL;
	static gboolean checked_for_dwfl = FALSE;
	static GMutex dwfl_mutex;
	static const Dwfl_Callbacks proc_callbacks = {
		.find_debuginfo = dwfl_standard_find_debuginfo,
		.debuginfo_path = &debuginfo_path,
		.find_elf = dwfl_linux_proc_find_elf
	};

	g_mutex_lock (&dwfl_mutex);

	if (checked_for_dwfl) {
		if (!reload) {
			g_mutex_unlock (&dwfl_mutex);
			return dwfl;
		}

		dwfl_end (dwfl);
		dwfl = NULL;
	}

	checked_for_dwfl = TRUE;

	dwfl = dwfl_begin (&proc_callbacks);
	if (!dwfl) {
		g_mutex_unlock (&dwfl_mutex);
		return NULL;
	}

	errno = 0;
	if (dwfl_linux_proc_report (dwfl, getpid ()) != 0 || dwfl_report_end (dwfl, NULL, NULL) != 0) {
		dwfl_end (dwfl);
		dwfl = NULL;
	}

	g_mutex_unlock (&dwfl_mutex);

	return dwfl;
}

struct getmodules_callback_arg
{
	gpointer addr;
	const gchar *func_name;
	const gchar *file_path;
	gint lineno;
};

static gint
getmodules_callback (Dwfl_Module *module,
                     gpointer *module_userdata_pointer,
                     const gchar *module_name,
                     Dwarf_Addr module_low_addr,
                     gpointer arg_voidp)
{
	struct getmodules_callback_arg *arg = arg_voidp;
	Dwfl_Line *line;

	arg->func_name = dwfl_module_addrname (module, (GElf_Addr) arg->addr);
	line = dwfl_module_getsrc (module, (GElf_Addr) arg->addr);
	if (line) {
		arg->file_path = dwfl_lineinfo (line, NULL, &arg->lineno, NULL, NULL, NULL);
	} else {
		arg->file_path = NULL;
	}

	return arg->func_name ? DWARF_CB_ABORT : DWARF_CB_OK;
}
#endif /* HAVE_ELFUTILS_LIBDWFL */

static const gchar *
addr_lookup (gpointer addr,
             const gchar **file_path,
             gint *lineno,
             const gchar *fallback)
{
#ifdef HAVE_ELFUTILS_LIBDWFL
	Dwfl *dwfl = dwfl_get (FALSE);
	struct getmodules_callback_arg arg;
	static GMutex mutex;

	if (!dwfl)
		return NULL;

	arg.addr = addr;
	arg.func_name = NULL;
	arg.file_path = NULL;
	arg.lineno = -1;

	g_mutex_lock (&mutex);

	dwfl_getmodules (dwfl, getmodules_callback, &arg, 0);

	if (!arg.func_name && fallback && strstr (fallback, "/lib") != fallback && strstr (fallback, "/usr/lib") != fallback) {
		dwfl = dwfl_get (TRUE);
		if (dwfl)
			dwfl_getmodules (dwfl, getmodules_callback, &arg, 0);
	}

	g_mutex_unlock (&mutex);

	*file_path = arg.file_path;
	*lineno = arg.lineno;

	return arg.func_name;
#else /* HAVE_ELFUTILS_LIBDWFL */
	return NULL;
#endif /* HAVE_ELFUTILS_LIBDWFL */
}

#endif /* HAVE_BACKTRACE_SYMBOLS */

static void
demangle_bt (GString *bt)
{
#ifdef HAVE_BACKTRACE_SYMBOLS
	gchar **btparts;
	gint ii;
	gboolean any_changed = FALSE;

	if (!bt || !bt->len)
		return;

	btparts = g_strsplit (bt->str, "\n", -1);
	if (!btparts)
		return;

	g_string_truncate (bt, 0);

	for (ii = 0; btparts[ii]; ii++) {
		gint lineno = -1;
		const gchar *file_path = NULL;
		const gchar *str, *bt_sym;
		gpointer btptr = NULL;

		if (!g_str_has_prefix (btparts[ii], "0x") ||
		    !strchr (btparts[ii], '\t') ||
		    sscanf (btparts[ii], "%p\t", &btptr) != 1) {
			btptr = NULL;
		}

		if (btptr) {
			bt_sym = strchr (btparts[ii], '\t');
			if (bt_sym)
				bt_sym++;
		} else {
			bt_sym = NULL;
		}

		if (!bt_sym || !*bt_sym) {
			if (bt->len)
				g_string_append_c (bt, '\n');
			g_string_append (bt, btparts[ii]);
			continue;
		}

		str = addr_lookup (btptr, &file_path, &lineno, bt_sym);

		if (!str) {
			str = btparts[ii];
			file_path = NULL;
			lineno = -1;
		}

		if (!str)
			continue;

		any_changed = TRUE;
		if (bt->len)
			g_string_append (bt, "\n\t   by ");
		g_string_append (bt, str);
		if (str != btparts[ii])
			g_string_append (bt, "()");

		if (file_path && lineno > 0) {
			const gchar *lastsep = strrchr (file_path, G_DIR_SEPARATOR);
			g_string_append_printf (bt, " at %s:%d", lastsep ? lastsep + 1 : file_path, lineno);
		}
	}

	g_strfreev (btparts);

	if (bt->len != 0 && any_changed)
		g_string_insert (bt, 0, "\t   at ");
#endif /* HAVE_BACKTRACE_SYMBOLS */
}

static GString *
get_current_backtrace (void)
{
#ifdef HAVE_BACKTRACE_SYMBOLS
	#define MAX_BT_DEPTH 50
	gint nptrs, ii;
	gpointer bt[MAX_BT_DEPTH + 1];
	gchar **bt_syms;
	GString *bt_str;

	nptrs = backtrace (bt, MAX_BT_DEPTH + 1);
	if (nptrs <= 2)
		return NULL;

	bt_syms = backtrace_symbols (bt, nptrs);
	if (!bt_syms)
		return NULL;

	bt_str = g_string_new ("");
	for (ii = 2; ii < nptrs; ii++) {
		if (bt_str->len)
			g_string_append (bt_str, "\n");
		g_string_append_printf (bt_str, "%p\t%s", bt[ii], bt_syms[ii]);
	}

	g_free (bt_syms);

	if (bt_str->len == 0) {
		g_string_free (bt_str, TRUE);
		bt_str = NULL;
	}

	return bt_str;

	#undef MAX_BT_DEPTH
#else /* HAVE_BACKTRACE_SYMBOLS */
	return NULL;
#endif /* HAVE_BACKTRACE_SYMBOLS */
}

static void
dump_left_at_exit_cb (void)
{
	dump_tracked_ptrs (TRUE);

	G_LOCK (ptr_tracker);
	if (ptr_tracker) {
		g_hash_table_destroy (ptr_tracker);
		ptr_tracker = NULL;
	}
	G_UNLOCK (ptr_tracker);
}

/**
 * camel_pointer_tracker_track_with_info:
 * @ptr: pointer to add to the pointer tracker
 * @info: info to print in tracker summary
 *
 * Adds pointer to the pointer tracker, with associated information,
 * which is printed in summary of pointer tracker printed by
 * camel_pointer_tracker_dump(). For convenience can be used
 * camel_pointer_tracker_track(), which adds place of the caller
 * as @info. Added pointer should be removed with pair function
 * camel_pointer_tracker_untrack().
 *
 * Since: 3.6
 **/
void
camel_pointer_tracker_track_with_info (gpointer ptr,
                                       const gchar *info)
{
	struct pt_data *ptd;

	g_return_if_fail (ptr != NULL);

	G_LOCK (ptr_tracker);
	if (!ptr_tracker) {
		ptr_tracker = g_hash_table_new_full (g_direct_hash, g_direct_equal, NULL, free_pt_data);
		atexit (dump_left_at_exit_cb);
	}

	ptd = g_new0 (struct pt_data, 1);
	ptd->ptr = ptr;
	ptd->info = g_strdup (info);
	ptd->backtrace = get_current_backtrace ();

	g_hash_table_insert (ptr_tracker, ptr, ptd);

	G_UNLOCK (ptr_tracker);
}

/**
 * camel_pointer_tracker_untrack:
 * @ptr: pointer to remove from the tracker
 *
 * Removes pointer from the pointer tracker. It's an error to try
 * to remove pointer which was not added to the tracker by
 * camel_pointer_tracker_track() or camel_pointer_tracker_track_with_info(),
 * or a pointer which was already removed.
 *
 * Since: 3.6
 **/
void
camel_pointer_tracker_untrack (gpointer ptr)
{
	g_return_if_fail (ptr != NULL);

	G_LOCK (ptr_tracker);

	if (!ptr_tracker)
		g_printerr ("Pointer tracker not initialized, thus cannot remove %p\n", ptr);
	else if (!g_hash_table_lookup (ptr_tracker, ptr))
		g_printerr ("Pointer %p is not tracked\n", ptr);
	else
		g_hash_table_remove (ptr_tracker, ptr);

	G_UNLOCK (ptr_tracker);
}

/**
 * camel_pointer_tracker_dump:
 *
 * Prints information about currently stored pointers
 * in the pointer tracker. This is called automatically
 * on application exit if camel_pointer_tracker_track() or
 * camel_pointer_tracker_track_with_info() was called.
 *
 * Note: If the library is configured with --enable-backtraces,
 * then also backtraces where the pointer was added is printed
 * in the summary.
 *
 * Since: 3.6
 **/
void
camel_pointer_tracker_dump (void)
{
	dump_tracked_ptrs (FALSE);
}

/**
 * camel_debug_get_backtrace:
 *
 * Gets current backtrace leading to this function call and demangles it.
 *
 * Returns: Current backtrace, or %NULL, if cannot determine it.
 *
 * Note: Getting backtraces only works if the library was
 * configured with --enable-backtraces.
 *
 * See also camel_debug_get_raw_backtrace()
 *
 * Since: 3.12
 **/
GString *
camel_debug_get_backtrace (void)
{
	GString *bt;

	bt = get_current_backtrace ();

	if (!bt)
		return NULL;

	demangle_bt (bt);

	return bt;
}

/**
 * camel_debug_get_raw_backtrace:
 *
 * Gets current raw backtrace leading to this function call.
 * This is quicker than camel_debug_get_backtrace(), because it
 * doesn't demangle the backtrace. To demangle it (replace addresses
 * with actual function calls and eventually line numbers, if
 * available) call camel_debug_demangle_backtrace().
 *
 * Returns: Current raw backtrace, or %NULL, if cannot determine it.
 *
 * Note: Getting backtraces only works if the library was
 * configured with --enable-backtraces.
 *
 * See also camel_debug_get_backtrace()
 *
 * Since: 3.30
 **/
GString *
camel_debug_get_raw_backtrace (void)
{
	return get_current_backtrace ();
}

/**
 * camel_debug_demangle_backtrace:
 * @bt: (inout) (nullable): a #GString with a raw backtrace, or %NULL
 *
 * Demangles @bt, possibly got from camel_debug_get_raw_backtrace(), by
 * replacing addresses with actual function calls and eventually line numbers, if
 * available. It modifies lines of @bt, but skips those it cannot parse.
 *
 * Note: Getting backtraces only works if the library was
 * configured with --enable-backtraces.
 *
 * See also camel_debug_get_raw_backtrace()
 *
 * Since: 3.30
 **/
void
camel_debug_demangle_backtrace (GString *bt)
{
	if (bt)
		demangle_bt (bt);
}

G_LOCK_DEFINE_STATIC (ref_unref_backtraces);
static GQueue *ref_unref_backtraces = NULL;
static guint total_ref_unref_backtraces = 0;

typedef struct _BacktraceLine
{
	gchar *function;
	gchar *file;
	gint lineno;
} BacktraceLine;

static void
backtrace_line_free (gpointer ptr)
{
	BacktraceLine *btline = ptr;

	if (btline) {
		g_free (btline->function);
		g_free (btline->file);
		g_free (btline);
	}
}

typedef enum {
	BACKTRACE_TYPE_OTHER,
	BACKTRACE_TYPE_REF,
	BACKTRACE_TYPE_UNREF
} BacktraceType;

typedef struct _Backtrace
{
	BacktraceType type;
	guint object_ref_count;
	GSList *lines; /* BacktraceLine */
} Backtrace;

static void
backtrace_free (gpointer ptr)
{
	Backtrace *bt = ptr;

	if (bt) {
		g_slist_free_full (bt->lines, backtrace_line_free);
		g_free (bt);
	}
}

static BacktraceLine *
parse_backtrace_line (const gchar *line)
{
	gchar **parts;
	gint ii, lineno = 0;
	gchar *function = NULL, *filename = NULL;

	if (!line)
		return NULL;

	while (*line == ' ' || *line == '\t')
		line++;

	parts = g_strsplit (line, " ", -1);
	if (!parts || !*parts) {
		g_strfreev (parts);
		return NULL;
	}

	for (ii = 0; parts[ii]; ii++) {
		const gchar *part = parts[ii];

		if (!*part)
			continue;

		if (ii == 1) {
			function = g_strdup (part);
		} else if (ii == 3 && function) {
			gchar **file;

			file = g_strsplit (part, ":", -1);
			if (file && file[0] && file[1]) {
				filename = g_strdup (file[0]);
				lineno = g_ascii_strtoll (file[1], NULL, 10);
			} else {
				filename = g_strdup (part);
			}

			g_strfreev (file);
		}
	}

	g_strfreev (parts);

	if (function) {
		BacktraceLine *btline;

		btline = g_new0 (BacktraceLine, 1);
		btline->function = function;
		btline->file = filename;
		btline->lineno = lineno;

		return btline;
	}

	g_free (function);
	g_free (filename);

	return NULL;
}

static Backtrace *
parse_backtrace (const GString *backtrace,
		 guint object_ref_count)
{
	Backtrace *bt;
	gchar **btlines;
	gint ii;

	if (!backtrace)
		return NULL;

	btlines = g_strsplit (backtrace->str, "\n", -1);
	if (!btlines || !*btlines) {
		g_strfreev (btlines);
		return NULL;
	}

	bt = g_new0 (Backtrace, 1);
	bt->object_ref_count = object_ref_count;

	for (ii = 0; btlines[ii]; ii++) {
		if (ii >= 1) {
			BacktraceLine *btline = parse_backtrace_line (btlines[ii]);

			if (!btline)
				continue;

			bt->lines = g_slist_prepend (bt->lines, btline);

			if (ii == 1) {
				if (g_strcmp0 (btline->function, "g_object_ref()") == 0) {
					bt->type = BACKTRACE_TYPE_REF;
				} else if (g_strcmp0 (btline->function, "g_object_unref()") == 0) {
					bt->type = BACKTRACE_TYPE_UNREF;
				} else {
					bt->type = BACKTRACE_TYPE_OTHER;
				}
			}
		}
	}

	g_strfreev (btlines);

	bt->lines = g_slist_reverse (bt->lines);

	return bt;
}

static void
print_backtrace (Backtrace *bt,
		 gint index)
{
	GSList *link;

	if (!bt)
		return;

	g_print ("      Backtrace[%d] %s %d~>%d:\n", index,
		bt->type == BACKTRACE_TYPE_REF ? "ref" :
		bt->type == BACKTRACE_TYPE_UNREF ? "unref" : "other",
		bt->object_ref_count, bt->object_ref_count + (bt->type == BACKTRACE_TYPE_REF ? 1 : bt->type == BACKTRACE_TYPE_UNREF ? -1 : 0));

	for (link = bt->lines; link; link = g_slist_next (link)) {
		BacktraceLine *btline = link->data;

		g_print ("         %s %s", link == bt->lines ? "at" : "by", btline->function);

		if (btline->file) {
			if (btline->lineno > 0) {
				g_print (" at %s:%d\n", btline->file, btline->lineno);
			} else {
				g_print (" at %s\n", btline->file);
			}
		} else {
			g_print ("\n");
		}
	}

	g_print ("\n");
}

static gboolean
backtrace_matches (const Backtrace *match_bt,
		   const Backtrace *find_bt,
		   gint lines_tolerance)
{
	GSList *mlink, *flink;
	gint lines_matched = 0;
	gint lt, ii;

	if (!match_bt || !find_bt || !find_bt->lines || !match_bt->lines)
		return FALSE;

	flink = find_bt->lines;
	mlink = NULL;
	lt = lines_tolerance;
	do {
		gboolean found = FALSE;
		BacktraceLine *fline = flink->data;

		if (!fline)
			return FALSE;

		for (mlink = match_bt->lines, ii = 0; mlink && ii <= lines_tolerance; mlink = g_slist_next (mlink), ii++) {
			BacktraceLine *mline = mlink->data;

			if (!mline)
				return FALSE;

			found = g_strcmp0 (fline->function, mline->function) == 0;
			if (found)
				break;
		}

		if (found)
			break;

		lt--;
		if (lt >= 0)
			flink = g_slist_next (flink);
		else
			flink = NULL;
	} while (flink);

	if (!flink)
		return FALSE;

	for (mlink = g_slist_next (mlink), flink = g_slist_next (flink);
	     mlink && flink;
	     mlink = g_slist_next (mlink), flink = g_slist_next (flink)) {
		BacktraceLine *mline, *fline;

		mline = mlink->data;
		fline = flink->data;

		if (!mline || !fline)
			break;

		if (g_strcmp0 (mline->function, fline->function) != 0 ||
		    g_strcmp0 (mline->file, fline->file) != 0 ||
		    mline->lineno != fline->lineno) {
			break;
		}

		lines_matched++;
	}

	return (!mlink && !flink) || (lines_matched > 40 && (!mlink || !flink));
}

static gboolean
backtrace_matches_ref (const Backtrace *match_bt,
		       const Backtrace *find_bt,
		       gint lines_tolerance)
{
	if (!match_bt || match_bt->type != BACKTRACE_TYPE_REF)
		return FALSE;

	return backtrace_matches (match_bt, find_bt, lines_tolerance);
}

static gboolean
remove_matching_ref_backtrace (GQueue *backtraces,
			       const Backtrace *unref_backtrace)
{
	GList *link;
	gint up_bts = 2, up_lines = 1;

	g_return_val_if_fail (backtraces != NULL, FALSE);
	g_return_val_if_fail (unref_backtrace != NULL, FALSE);
	g_return_val_if_fail (unref_backtrace->type != BACKTRACE_TYPE_REF, FALSE);

	if (unref_backtrace->lines && unref_backtrace->lines->next && unref_backtrace->lines->next->data) {
		BacktraceLine *btline = unref_backtrace->lines->next->data;

		if (g_strcmp0 ("g_value_object_free_value()", btline->function) == 0)
			up_lines = 5;
		else if (g_strcmp0 ("g_object_notify()", btline->function) == 0)
			up_bts = 5;
	}

	for (link = g_queue_peek_tail_link (backtraces); link && up_bts > 0; link = g_list_previous (link), up_bts--) {
		Backtrace *bt = link->data;
		gint inc_up_lines = 0;

		if (!bt || bt->type != BACKTRACE_TYPE_REF)
			continue;

		if (bt->lines && bt->lines->next && bt->lines->next->data) {
			BacktraceLine *btline = bt->lines->next->data;

			if (g_strcmp0 ("g_weak_ref_get()", btline->function) == 0)
				inc_up_lines = 2;
		}

		if (backtrace_matches_ref (bt, unref_backtrace, up_lines + inc_up_lines)) {
			g_queue_delete_link (backtraces, link);
			backtrace_free (bt);

			return TRUE;
		}
	}

	return FALSE;
}

static void
dump_ref_unref_backtraces (gboolean is_at_exit)
{
	G_LOCK (ref_unref_backtraces);

	if (ref_unref_backtraces) {
		g_print ("\n----------------------------------------------------------\n");
		if (g_queue_get_length (ref_unref_backtraces) == 0) {
			g_print ("   All ref/unref backtraces were properly matched\n");
		} else {
			guint count = g_queue_get_length (ref_unref_backtraces), refs = 0, unrefs = 0, others = 0;
			GList *link;

			for (link = g_queue_peek_head_link (ref_unref_backtraces); link; link = g_list_next (link)) {
				Backtrace *bt = link->data;

				if (!bt)
					continue;

				if (bt->type == BACKTRACE_TYPE_REF)
					refs++;
				else if (bt->type == BACKTRACE_TYPE_UNREF)
					unrefs++;
				else
					others++;
			}

			g_print ("   Left %u (ref(%u)/unref(%u)/other(%u)) backtraces of %u pushed total:\n", count, refs, unrefs, others, total_ref_unref_backtraces);

			for (count = 0, link = g_queue_peek_head_link (ref_unref_backtraces); link; link = g_list_next (link), count++) {
				Backtrace *bt = link->data;

				if (!bt)
					continue;

				print_backtrace (bt, count);
			}
		}
		g_print ("----------------------------------------------------------\n");
	} else if (!is_at_exit) {
		g_print ("\n----------------------------------------------------------\n");
		g_print ("   Did not receive any ref/unref backtraces yet\n");
		g_print ("----------------------------------------------------------\n");
	}

	G_UNLOCK (ref_unref_backtraces);
}

static void
dump_left_ref_unref_backtraces_at_exit_cb (void)
{
	dump_ref_unref_backtraces (TRUE);

	G_LOCK (ref_unref_backtraces);

	if (ref_unref_backtraces) {
		g_queue_free_full (ref_unref_backtraces, backtrace_free);
		ref_unref_backtraces = NULL;
	}

	G_UNLOCK (ref_unref_backtraces);
}

/**
 * camel_debug_ref_unref_push_backtrace:
 * @backtrace: a backtrace to push, taken from camel_debug_get_backtrace()
 * @object_ref_count: the current object reference count when the push is done
 *
 * Adds this backtrace into the set of backtraces related to some object
 * reference counting issues debugging. This is usually called inside g_object_ref()
 * and g_object_unref(). If the backtrace corresponds to a g_object_unref()
 * call, and a corresponding g_object_ref() backtrace is found in the current list,
 * then the previous backtrace is removed and this one is skipped.
 *
 * Any left backtraces in the list are printed at the application end.
 *
 * A convenient function camel_debug_ref_unref_push_backtrace_for_object()
 * is provided too.
 *
 * Since: 3.20
 **/
void
camel_debug_ref_unref_push_backtrace (const GString *backtrace,
				      guint object_ref_count)
{
	Backtrace *bt;

	g_return_if_fail (backtrace != NULL);

	G_LOCK (ref_unref_backtraces);

	total_ref_unref_backtraces++;

	bt = parse_backtrace (backtrace, object_ref_count);
	if (!bt) {
		G_UNLOCK (ref_unref_backtraces);
		g_warn_if_fail (bt != NULL);
		return;
	}

	if (!ref_unref_backtraces) {
		ref_unref_backtraces = g_queue_new ();
		atexit (dump_left_ref_unref_backtraces_at_exit_cb);
	}

	if (bt->type != BACKTRACE_TYPE_UNREF || !remove_matching_ref_backtrace (ref_unref_backtraces, bt)) {
		g_queue_push_tail (ref_unref_backtraces, bt);
	} else {
		backtrace_free (bt);
	}

	G_UNLOCK (ref_unref_backtraces);
}

/**
 * camel_debug_ref_unref_push_backtrace_for_object:
 * @_object: a #GObject, for which add the backtrace
 *
 * Gets current backtrace of this call and adds it to the list
 * of backtraces with camel_debug_ref_unref_push_backtrace().
 *
 * Usual usage would be, once GNOME bug 758358 is applied to the GLib sources,
 * or a patched GLib is used, to call this function in an object init() function,
 * like this:
 *
 * static void
 * my_object_init (MyObject *obj)
 * {
 *    camel_debug_ref_unref_push_backtrace_for_object (obj);
 *    g_track_object_ref_unref (obj, (GFunc) camel_debug_ref_unref_push_backtrace_for_object, NULL);
 * }
 *
 * Note that the g_track_object_ref_unref() can track only one pointer, thus make
 * sure you track the right one (add some logic if multiple objects are created at once).
 *
 * Since: 3.20
 **/
void
camel_debug_ref_unref_push_backtrace_for_object (gpointer _object)
{
	GString *backtrace;
	GObject *object;

	g_return_if_fail (G_IS_OBJECT (_object));

	object = G_OBJECT (_object);

	backtrace = camel_debug_get_backtrace ();
	if (backtrace) {
		camel_debug_ref_unref_push_backtrace (backtrace, object->ref_count);
		g_string_free (backtrace, TRUE);
	}
}

/**
 * camel_debug_ref_unref_dump_backtraces:
 *
 * Prints current backtraces stored with camel_debug_ref_unref_push_backtrace()
 * or with camel_debug_ref_unref_push_backtrace_for_object().
 *
 * It's usually not needed to use this function, as the left backtraces, if any,
 * are printed at the end of the application.
 *
 * Since: 3.20
 **/
void
camel_debug_ref_unref_dump_backtraces (void)
{
	dump_ref_unref_backtraces (FALSE);
}
