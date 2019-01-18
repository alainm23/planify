/* daemon.vapi
 *
 * Copyright (C) 2009 Jukka-Pekka Iivonen
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jukka-Pekka Iivonen <jp0409@jippii.fi>
 */

[CCode (lower_case_cprefix = "daemon_", cheader_filename = "signal.h,libdaemon/daemon.h")]
namespace Daemon {
	[CCode (cname = "int", cprefix = "DAEMON_LOG_", has_type_id = false)]
 	public enum LogFlags {
		SYSLOG,
		STDERR,
		STDOUT,
		AUTO
	}

	[CCode (cname = "int", cprefix = "LOG_", has_type_id = false)]
	public enum LogPriority {
		EMERG,
		ALERT,
		CRIT,
		ERR,
		WARNING,
		NOTICE,
		INFO,
		DEBUG
	}

	[CCode (cname = "int", cprefix = "SIG", has_type_id = false)]
	public enum Sig {
		HUP,
		INT,
		QUIT,
		ILL,
		TRAP,
		ABRT,
		IOT,
		BUS,
		FPE,
		KILL,
		USR1,
		SEGV,
		USR2,
		PIPE,
		ALRM,
		TERM,
		STKFLT,
		CLD,
		CHLD,
		CONT,
		STOP,
		TSTP,
		TTIN,
		TTOU,
		URG,
		XCPU,
		XFSZ,
		VTALRM,
		PROF,
		WINCH,
		POLL,
		IO,
		PWR,
		SYS,
		UNUSED
	}

	public int exec (string dir, out int ret, string prog, ...);

	public GLib.Pid fork ();
	public int retval_init ();
	public void retval_done ();
	public int retval_wait (int timeout);
	public int retval_send (int s);
	public int close_all (int except_fd, ...);
	public int close_allv ([CCode (array_length = false)] int[] except_fds);
	public int unblock_sigs (int except, ...);
	public int unblock_sigsv ([CCode (array_length = false)] int[] except);
	public int reset_sigs (int except, ...);
	public int reset_sigsv ([CCode (array_length = false)] int[] except);

	public static LogFlags log_use;
	public static string log_ident;

	public void log (int prio, string t, ...);
	public unowned string ident_from_argv0 (string argv0);

	public int nonblock (int fd, int b);

	public delegate string PidFileProc ();

	public static string pid_file_ident;
	public static PidFileProc pid_file_proc;

	public unowned string pid_file_proc_default ();
	public int pid_file_create ();
	public int pid_file_remove ();
	public GLib.Pid pid_file_is_running ();
	public int pid_file_kill (Sig s);
	public int pid_file_kill_wait (Sig s, int m);

	public int signal_init (Sig s, ...);
	public int signal_install (Sig s);
	public void signal_done ();
	public int signal_next ();
	public int signal_fd ();
}

