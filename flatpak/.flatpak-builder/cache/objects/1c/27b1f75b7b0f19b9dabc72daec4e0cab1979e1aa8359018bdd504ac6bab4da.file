/* posix.vapi
 *
 * Copyright (C) 2008-2009  Jürg Billeter
 * Copyright (C) 2010 Marco Trevisan (Treviño)
 * Copyright (C) 2013 Nikolay Orliuk
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
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 *  Marco Trevisan (Treviño) <mail@3v1n0.net>
 *  Nikolay Orliuk <virkony@gmail.com>
 */

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Posix {
	[CCode (cheader_filename = "assert.h")]
	public void assert (bool expression);

	[CCode (cheader_filename = "ctype.h")]
	public bool isalnum (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool isalpha (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool isascii (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool iscntrl (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool isdigit (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool isgraph (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool islower (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool isprint (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool ispunct (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool isspace (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool isupper (int c);
	[CCode (cheader_filename = "ctype.h")]
	public bool isxdigit (int c);
	[CCode (cheader_filename = "ctype.h")]
	public int toascii (int c);
	[CCode (cheader_filename = "ctype.h")]
	public int tolower (int c);
	[CCode (cheader_filename = "ctype.h")]
	public int toupper (int c);

	[Compact]
	[CCode (cname = "struct dirent", cheader_filename = "dirent.h")]
	public class DirEnt {
		public ino_t d_ino;
		public off_t d_off;
		public ushort d_reclen;
		public char d_type;
		public char d_name[256];
	}

	[Compact]
	[CCode (cname = "DIR", free_function = "closedir", cheader_filename = "dirent.h")]
	public class Dir {
	}

	[CCode (cheader_filename = "dirent.h")]
	public int dirfd (Dir dir);
	[CCode (cheader_filename = "dirent.h")]
	public Dir? opendir (string filename);
	[CCode (cheader_filename = "dirent.h")]
	public Dir? fdopendir (int fd);
	[CCode (cheader_filename = "dirent.h")]
	public unowned DirEnt? readdir (Dir dir);
	[CCode (cheader_filename = "dirent.h")]
	public void rewinddir (Dir dir);
	[CCode (cheader_filename = "dirent.h")]
	public void seekdir (Dir dir, long pos);
	[CCode (cheader_filename = "dirent.h")]
	public long telldir (Dir dir);

	[CCode (cheader_filename = "errno.h")]
	public int errno;
	[CCode (cheader_filename = "errno.h")]
	public const int E2BIG;
	[CCode (cheader_filename = "errno.h")]
	public const int EACCES;
	[CCode (cheader_filename = "errno.h")]
	public const int EADDRINUSE;
	[CCode (cheader_filename = "errno.h")]
	public const int EADDRNOTAVAIL;
	[CCode (cheader_filename = "errno.h")]
	public const int EAFNOSUPPORT;
	[CCode (cheader_filename = "errno.h")]
	public const int EAGAIN;
	[CCode (cheader_filename = "errno.h")]
	public const int EALREADY;
	[CCode (cheader_filename = "errno.h")]
	public const int EBADF;
	[CCode (cheader_filename = "errno.h")]
	public const int EBADMSG;
	[CCode (cheader_filename = "errno.h")]
	public const int EBUSY;
	[CCode (cheader_filename = "errno.h")]
	public const int ECANCELED;
	[CCode (cheader_filename = "errno.h")]
	public const int ECHILD;
	[CCode (cheader_filename = "errno.h")]
	public const int ECONNABORTED;
	[CCode (cheader_filename = "errno.h")]
	public const int ECONNREFUSED;
	[CCode (cheader_filename = "errno.h")]
	public const int ECONNRESET;
	[CCode (cheader_filename = "errno.h")]
	public const int EDEADLK;
	[CCode (cheader_filename = "errno.h")]
	public const int EDESTADDRREQ;
	[CCode (cheader_filename = "errno.h")]
	public const int EDOM;
	[CCode (cheader_filename = "errno.h")]
	public const int EDQUOT;
	[CCode (cheader_filename = "errno.h")]
	public const int EEXIST;
	[CCode (cheader_filename = "errno.h")]
	public const int EFAULT;
	[CCode (cheader_filename = "errno.h")]
	public const int EFBIG;
	[CCode (cheader_filename = "errno.h")]
	public const int EHOSTUNREACH;
	[CCode (cheader_filename = "errno.h")]
	public const int EIDRM;
	[CCode (cheader_filename = "errno.h")]
	public const int EILSEQ;
	[CCode (cheader_filename = "errno.h")]
	public const int EINPROGRESS;
	[CCode (cheader_filename = "errno.h")]
	public const int EINTR;
	[CCode (cheader_filename = "errno.h")]
	public const int EINVAL;
	[CCode (cheader_filename = "errno.h")]
	public const int EIO;
	[CCode (cheader_filename = "errno.h")]
	public const int EISCONN;
	[CCode (cheader_filename = "errno.h")]
	public const int EISDIR;
	[CCode (cheader_filename = "errno.h")]
	public const int ELOOP;
	[CCode (cheader_filename = "errno.h")]
	public const int EMFILE;
	[CCode (cheader_filename = "errno.h")]
	public const int EMLINK;
	[CCode (cheader_filename = "errno.h")]
	public const int EMSGSIZE;
	[CCode (cheader_filename = "errno.h")]
	public const int EMULTIHOP;
	[CCode (cheader_filename = "errno.h")]
	public const int ENAMETOOLONG;
	[CCode (cheader_filename = "errno.h")]
	public const int ENETDOWN;
	[CCode (cheader_filename = "errno.h")]
	public const int ENETRESET;
	[CCode (cheader_filename = "errno.h")]
	public const int ENETUNREACH;
	[CCode (cheader_filename = "errno.h")]
	public const int ENFILE;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOBUFS;
	[CCode (cheader_filename = "errno.h")]
	public const int ENODATA;
	[CCode (cheader_filename = "errno.h")]
	public const int ENODEV;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOENT;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOEXEC;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOLCK;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOLINK;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOMEM;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOMSG;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOPROTOOPT;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOSPC;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOSR;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOSTR;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOSYS;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOTCONN;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOTDIR;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOTEMPTY;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOTSOCK;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOTSUP;
	[CCode (cheader_filename = "errno.h")]
	public const int ENOTTY;
	[CCode (cheader_filename = "errno.h")]
	public const int ENXIO;
	[CCode (cheader_filename = "errno.h")]
	public const int EOPNOTSUPP;
	[CCode (cheader_filename = "errno.h")]
	public const int EOVERFLOW;
	[CCode (cheader_filename = "errno.h")]
	public const int EPERM;
	[CCode (cheader_filename = "errno.h")]
	public const int EPIPE;
	[CCode (cheader_filename = "errno.h")]
	public const int EPROTO;
	[CCode (cheader_filename = "errno.h")]
	public const int EPROTONOSUPPORT;
	[CCode (cheader_filename = "errno.h")]
	public const int EPROTOTYPE;
	[CCode (cheader_filename = "errno.h")]
	public const int ERANGE;
	[CCode (cheader_filename = "errno.h")]
	public const int EROFS;
	[CCode (cheader_filename = "errno.h")]
	public const int ESPIPE;
	[CCode (cheader_filename = "errno.h")]
	public const int ESRCH;
	[CCode (cheader_filename = "errno.h")]
	public const int ESTALE;
	[CCode (cheader_filename = "errno.h")]
	public const int ETIME;
	[CCode (cheader_filename = "errno.h")]
	public const int ETIMEDOUT;
	[CCode (cheader_filename = "errno.h")]
	public const int ETXTBSY;
	[CCode (cheader_filename = "errno.h")]
	public const int EWOULDBLOCK;
	[CCode (cheader_filename = "errno.h")]
	public const int EXDEV;

	[CCode (cheader_filename = "fcntl.h")]
	public const int F_DUPFD;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_GETFD;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_SETFD;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_GETFL;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_SETFL;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_GETLK;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_SETLK;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_SETLKW;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_GETOWN;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_SETOWN;
	[CCode (cheader_filename = "fcntl.h")]
	public const int FD_CLOEXEC;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_RDLCK;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_UNLCK;
	[CCode (cheader_filename = "fcntl.h")]
	public const int F_WRLCK;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_CREAT;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_EXCL;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_NOCTTY;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_TRUNC;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_APPEND;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_DSYNC;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_NONBLOCK;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_RSYNC;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_SYNC;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_ACCMODE;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_RDONLY;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_RDWR;
	[CCode (cheader_filename = "fcntl.h")]
	public const int O_WRONLY;
	[CCode (cheader_filename = "fcntl.h")]
	public const int POSIX_FADV_NORMAL;
	[CCode (cheader_filename = "fcntl.h")]
	public const int POSIX_FADV_SEQUENTIAL;
	[CCode (cheader_filename = "fcntl.h")]
	public const int POSIX_FADV_RANDOM;
	[CCode (cheader_filename = "fcntl.h")]
	public const int POSIX_FADV_WILLNEED;
	[CCode (cheader_filename = "fcntl.h")]
	public const int POSIX_FADV_DONTNEED;
	[CCode (cheader_filename = "fcntl.h")]
	public const int POSIX_FADV_NOREUSE;
	[CCode (cheader_filename = "fcntl.h")]
	public int creat (string path, mode_t mode);
	[CCode (cheader_filename = "fcntl.h")]
	public int fcntl (int fd, int cmd, ...);
	[CCode (cheader_filename = "fcntl.h")]
	public int open (string path, int oflag, mode_t mode=0);
	[CCode (cheader_filename = "fcntl.h")]
	public int posix_fadvise (int fd, long offset, long len, int advice);
	[CCode (cheader_filename = "fcntl.h")]
	public int posix_fallocate (int fd, long offset, long len);

	[CCode (cname = "struct flock", cheader_filename = "fcntl.h", has_type_id = false)]
	public struct Flock {
		public int l_type;
		public int l_whence;
		public off_t l_start;
		public off_t l_len;
		public pid_t l_pid;
	}

	[CCode(cheader_filename = "fnmatch.h")]
	public int fnmatch (string pattern, string str, int flags = 0);

	[CCode(cheader_filename = "fnmatch.h", feature_test_macro = "_GNU_SOURCE")]
	public const int FNM_CASEFOLD;
	[CCode(cheader_filename = "fnmatch.h", feature_test_macro = "_GNU_SOURCE")]
	public const int FNM_EXTMATCH;
	[CCode(cheader_filename = "fnmatch.h", feature_test_macro = "_GNU_SOURCE")]
	public const int FNM_FILE_NAME;
	[CCode(cheader_filename = "fnmatch.h", feature_test_macro = "_GNU_SOURCE")]
	public const int FNM_LEADING_DIR;
	[CCode(cheader_filename = "fnmatch.h")]
	public const int FNM_NOESCAPE;
	[CCode(cheader_filename = "fnmatch.h")]
	public const int FNM_NOMATCH;
	[CCode(cheader_filename = "fnmatch.h")]
	public const int FNM_PATHNAME;
	[CCode(cheader_filename = "fnmatch.h")]
	public const int FNM_PERIOD;

	[Compact]
	[CCode (cname = "struct group", cheader_filename = "grp.h")]
	public class Group {
		public string gr_name;
		public string gr_passwd;
		public gid_t gr_gid;
		[CCode (array_length = false, array_null_terminated = true)]
		public string[] gr_mem;
	}
	[CCode (cheader_filename = "grp.h")]
	public void endgrent ();
	public unowned Group? getgrent ();
	public void setgrent ();
	[CCode (cheader_filename = "grp.h")]
	public unowned Group? getgrgid (gid_t gid);
	[CCode (cheader_filename = "grp.h")]
	public unowned Group? getgrnam (string name);

	[CCode (cheader_filename = "netinet/in.h")]
	public const int INET_ADDRSTRLEN;
	[CCode (cheader_filename = "netinet/in.h")]
	public const int INET6_ADDRSTRLEN;

	[CCode (cheader_filename = "netinet/in.h", cname = "int", cprefix = "IPPROTO_", has_type_id = false)]
	public enum IPProto {
		IP,
		ICMP,
		IGMP,
		IPIP,
		TCP,
		EGP,
		PUP,
		UDP,
		IDP,
		TP,
		DCCP,
		IPV6,
		RSVP,
		GRE,
		ESP,
		AH,
		MTP,
		BEETPH,
		ENCAP,
		PIM,
		COMP,
		SCTP,
		UDPLITE,
		RAW,
	}

	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_NODELAY;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_MAXSEG;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_CORK;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_KEEPIDLE;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_KEEPINTVL;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_KEEPCNT;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_SYNCNT;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_LINGER2;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_DEFER_ACCEPT;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_WINDOW_CLAMP;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_INFO;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_QUICKACK;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_CONGESTION;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_MD5SIG;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_COOKIE_TRANSACTIONS;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_THIN_LINEAR_TIMEOUTS;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_THIN_DUPACK;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_USER_TIMEOUT;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_REPAIR;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_REPAIR_QUEUE;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_QUEUE_SEQ;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_REPAIR_OPTIONS;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_FASTOPEN;
	[CCode (cheader_filename = "netinet/tcp.h")]
	public const int TCP_TIMESTAMP;

	[CCode (cheader_filename = "arpa/inet.h")]
	public uint32 inet_addr (string host);
	[CCode (cheader_filename = "arpa/inet.h")]
	public unowned string inet_ntoa (InAddr addr);
	[CCode (cheader_filename = "arpa/inet.h")]
	public unowned string? inet_ntop (int af, void* src, uint8[] dst);
	[CCode (cheader_filename = "arpa/inet.h")]
	public int inet_pton (int af, string src, void* dst);
	[CCode (cheader_filename = "arpa/inet.h")]
	public uint32 htonl (uint32 hostlong);
	[CCode (cheader_filename = "arpa/inet.h")]
	public uint32 ntohl (uint32 netlong);
	[CCode (cheader_filename = "arpa/inet.h")]
	public uint16 htons (uint16 hostshort);
	[CCode (cheader_filename = "arpa/inet.h")]
	public uint16 ntohs (uint16 netshort);

	[CCode (cheader_filename = "math.h")]
	public double acos (double x);
	[CCode (cheader_filename = "math.h")]
	public float acosf (float x);
	[CCode (cheader_filename = "math.h")]
	public double asin (double x);
	[CCode (cheader_filename = "math.h")]
	public float asinf (float x);
	[CCode (cheader_filename = "math.h")]
	public double atan (double x);
	[CCode (cheader_filename = "math.h")]
	public float atanf (float x);
	[CCode (cheader_filename = "math.h")]
	public double atan2 (double y, double x);
	[CCode (cheader_filename = "math.h")]
	public float atan2f (float y, float x);
	[CCode (cheader_filename = "math.h")]
	public double cos (double x);
	[CCode (cheader_filename = "math.h")]
	public float cosf (float x);
	[CCode (cheader_filename = "math.h")]
	public double sin (double x);
	[CCode (cheader_filename = "math.h")]
	public float sinf (float x);
	[CCode (cheader_filename = "math.h")]
	public double tan (double x);
	[CCode (cheader_filename = "math.h")]
	public float tanf (float x);
	[CCode (cheader_filename = "math.h")]
	public double cosh (double x);
	[CCode (cheader_filename = "math.h")]
	public float coshf (float x);
	[CCode (cheader_filename = "math.h")]
	public double sinh (double x);
	[CCode (cheader_filename = "math.h")]
	public float sinhf (float x);
	[CCode (cheader_filename = "math.h")]
	public double tanh (double x);
	[CCode (cheader_filename = "math.h")]
	public float tanhf (float x);
	[CCode (cheader_filename = "math.h")]
	public void sincos (double x, out double sinx, out double cosx);
	[CCode (cheader_filename = "math.h")]
	public void sincosf (float x, out float sinx, out float cosx);
	[CCode (cheader_filename = "math.h")]
	public double acosh (double x);
	[CCode (cheader_filename = "math.h")]
	public float acoshf (float x);
	[CCode (cheader_filename = "math.h")]
	public double asinh (double x);
	[CCode (cheader_filename = "math.h")]
	public float asinhf (float x);
	[CCode (cheader_filename = "math.h")]
	public double atanh (double x);
	[CCode (cheader_filename = "math.h")]
	public float atanhf (float x);
	[CCode (cheader_filename = "math.h")]
	public double exp (double x);
	[CCode (cheader_filename = "math.h")]
	public float expf (float x);
	[CCode (cheader_filename = "math.h")]
	public double frexp (double x, out int exponent);
	[CCode (cheader_filename = "math.h")]
	public float frexpf (float x, out int exponent);
	[CCode (cheader_filename = "math.h")]
	public double ldexp (double x, int exponent);
	[CCode (cheader_filename = "math.h")]
	public float ldexpf (float x, int exponent);
	[CCode (cheader_filename = "math.h")]
	public double log (double x);
	[CCode (cheader_filename = "math.h")]
	public float logf (float x);
	[CCode (cheader_filename = "math.h")]
	public double log10 (double x);
	[CCode (cheader_filename = "math.h")]
	public float log10f (float x);
	[CCode (cheader_filename = "math.h")]
	public double modf (double x, out double iptr);
	[CCode (cheader_filename = "math.h")]
	public float modff (float x, out float iptr);
	[CCode (cheader_filename = "math.h", feature_test_macro = "_GNU_SOURCE")]
	public double exp10 (double x);
	[CCode (cheader_filename = "math.h", feature_test_macro = "_GNU_SOURCE")]
	public float exp10f (float x);
	[CCode (cheader_filename = "math.h", feature_test_macro = "_GNU_SOURCE")]
	public double pow10 (double x);
	[CCode (cheader_filename = "math.h", feature_test_macro = "_GNU_SOURCE")]
	public float pow10f (float x);
	[CCode (cheader_filename = "math.h")]
	public double expm1 (double x);
	[CCode (cheader_filename = "math.h")]
	public float expm1f (float x);
	[CCode (cheader_filename = "math.h")]
	public double log1p (double x);
	[CCode (cheader_filename = "math.h")]
	public float log1pf (float x);
	[CCode (cheader_filename = "math.h")]
	public double logb (double x);
	[CCode (cheader_filename = "math.h")]
	public float logbf (float x);
	[CCode (cheader_filename = "math.h")]
	public double exp2 (double x);
	[CCode (cheader_filename = "math.h")]
	public float exp2f (float x);
	[CCode (cheader_filename = "math.h")]
	public double log2 (double x);
	[CCode (cheader_filename = "math.h")]
	public float log2f (float x);
	[CCode (cheader_filename = "math.h")]
	public double pow (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float powf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double sqrt (double x);
	[CCode (cheader_filename = "math.h")]
	public float sqrtf (float x);
	[CCode (cheader_filename = "math.h")]
	public double hypot (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float hypotf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double cbrt (double x);
	[CCode (cheader_filename = "math.h")]
	public float cbrtf (float x);
	[CCode (cheader_filename = "math.h")]
	public double ceil (double x);
	[CCode (cheader_filename = "math.h")]
	public float ceilf (float x);
	[CCode (cheader_filename = "math.h")]
	public double fabs (double x);
	[CCode (cheader_filename = "math.h")]
	public float fabsf (float x);
	[CCode (cheader_filename = "math.h")]
	public double floor (double x);
	[CCode (cheader_filename = "math.h")]
	public float floorf (float x);
	[CCode (cheader_filename = "math.h")]
	public double fmod (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float fmodf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public int isinf (double value);
	[CCode (cheader_filename = "math.h")]
	public int isinff (float value);
	[CCode (cheader_filename = "math.h")]
	public int finite (double value);
	[CCode (cheader_filename = "math.h")]
	public int finitef (float value);
	[CCode (cheader_filename = "math.h")]
	public double drem (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float dremf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double significand (double x);
	[CCode (cheader_filename = "math.h")]
	public float significandf (float x);
	[CCode (cheader_filename = "math.h")]
	public double copysign (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float copysignf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double nan (string tagb);
	[CCode (cheader_filename = "math.h")]
	public float nanf (string tagb);
	[CCode (cheader_filename = "math.h")]
	public int isnan (double value);
	[CCode (cheader_filename = "math.h")]
	public int isnanf (float value);
	[CCode (cheader_filename = "math.h")]
	public double j0 (double x0);
	[CCode (cheader_filename = "math.h")]
	public float j0f (float x0);
	[CCode (cheader_filename = "math.h")]
	public double j1 (double x0);
	[CCode (cheader_filename = "math.h")]
	public float j1f (float x0);
	[CCode (cheader_filename = "math.h")]
	public double jn (int x0, double x1);
	[CCode (cheader_filename = "math.h")]
	public float jnf (int x0, float x1);
	[CCode (cheader_filename = "math.h")]
	public double y0 (double x0);
	[CCode (cheader_filename = "math.h")]
	public float y0f (float x0);
	[CCode (cheader_filename = "math.h")]
	public double y1 (double x0);
	[CCode (cheader_filename = "math.h")]
	public float y1f (float x0);
	[CCode (cheader_filename = "math.h")]
	public double yn (int x0, double x1);
	[CCode (cheader_filename = "math.h")]
	public float ynf (int x0, float x1);
	[CCode (cheader_filename = "math.h")]
	public double erf (double x0);
	[CCode (cheader_filename = "math.h")]
	public float erff (float x0);
	[CCode (cheader_filename = "math.h")]
	public double erfc (double x0);
	[CCode (cheader_filename = "math.h")]
	public float erfcf (float x0);
	[CCode (cheader_filename = "math.h")]
	public double lgamma (double x0);
	[CCode (cheader_filename = "math.h")]
	public float lgammaf (float x0);
	[CCode (cheader_filename = "math.h")]
	public double tgamma (double x0);
	[CCode (cheader_filename = "math.h")]
	public float tgammaf (float x0);
	[CCode (cheader_filename = "math.h")]
	public double gamma (double x0);
	[CCode (cheader_filename = "math.h")]
	public float gammaf (float x0);
	[CCode (cheader_filename = "math.h")]
	public double lgamma_r (double x0, out int signgamp);
	[CCode (cheader_filename = "math.h")]
	public float lgamma_rf (float x0, out int signgamp);
	[CCode (cheader_filename = "math.h")]
	public double rint (double x);
	[CCode (cheader_filename = "math.h")]
	public float rintf (float x);
	[CCode (cheader_filename = "math.h")]
	public double nextafter (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float nextafterf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double nexttoward (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float nexttowardf (float x, double y);
	[CCode (cheader_filename = "math.h")]
	public double remainder (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float remainderf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double scalbn (double x, int n);
	[CCode (cheader_filename = "math.h")]
	public float scalbnf (float x, int n);
	[CCode (cheader_filename = "math.h")]
	public int ilogb (double x);
	[CCode (cheader_filename = "math.h")]
	public int ilogbf (float x);
	[CCode (cheader_filename = "math.h")]
	public double scalbln (double x, long n);
	[CCode (cheader_filename = "math.h")]
	public float scalblnf (float x, long n);
	[CCode (cheader_filename = "math.h")]
	public double nearbyint (double x);
	[CCode (cheader_filename = "math.h")]
	public float nearbyintf (float x);
	[CCode (cheader_filename = "math.h")]
	public double round (double x);
	[CCode (cheader_filename = "math.h")]
	public float roundf (float x);
	[CCode (cheader_filename = "math.h")]
	public double trunc (double x);
	[CCode (cheader_filename = "math.h")]
	public float truncf (float x);
	[CCode (cheader_filename = "math.h")]
	public double remquo (double x, double y, out int quo);
	[CCode (cheader_filename = "math.h")]
	public float remquof (float x, float y, out int quo);
	[CCode (cheader_filename = "math.h")]
	public long lrint (double x);
	[CCode (cheader_filename = "math.h")]
	public long lrintf (float x);
	[CCode (cheader_filename = "math.h")]
	public int64 llrint (double x);
	[CCode (cheader_filename = "math.h")]
	public int64 llrintf (float x);
	[CCode (cheader_filename = "math.h")]
	public long lround (double x);
	[CCode (cheader_filename = "math.h")]
	public long lroundf (float x);
	[CCode (cheader_filename = "math.h")]
	public int64 llround (double x);
	[CCode (cheader_filename = "math.h")]
	public int64 llroundf (float x);
	[CCode (cheader_filename = "math.h")]
	public double fdim (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float fdimf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double fmax (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float fmaxf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double fmin (double x, double y);
	[CCode (cheader_filename = "math.h")]
	public float fminf (float x, float y);
	[CCode (cheader_filename = "math.h")]
	public double fma (double x, double y, double z);
	[CCode (cheader_filename = "math.h")]
	public float fmaf (float x, float y, float z);
	[CCode (cheader_filename = "math.h")]
	public double scalb (double x, double n);
	[CCode (cheader_filename = "math.h")]
	public float scalbf (float x, float n);

	[SimpleType]
	[CCode (cname = "mqd_t", cheader_filename = "mqueue.h", lower_case_cprefix = "mq_", free_function = "mq_close", has_type_id = false)]
	public struct MessageQueue {
		[CCode (cname = "mq_open")]
		public MessageQueue (string name, int oflag, mode_t mode = 0, MqAttr? attr = null);
		public static int unlink (string name);
		public int notify (sigevent_t? notification = null);
		public int getattr (MqAttr attr);
		public int setattr (MqAttr attr, MqAttr? oldattr = null);
		public int send (uint8[] msg, uint prio = 0);
		public int timedsend (uint8[] msg, uint prio, timespec abs_timeout);
		public ssize_t receive (uint8[] msg, out uint prio);
		public ssize_t timedreceive (uint8[] msg, out uint prio, timespec abs_timeout);
	}

	[CCode (cname = "struct mq_attr", cheader_filename = "mqueue.h", destroy_function = "", has_type_id = false)]
	public struct MqAttr {
		public long mq_flags;
		public long mq_maxmsg;
		public long mq_msgsize;
		public long mq_curmsgs;
	}

	[CCode (cheader_filename = "netdb.h")]
	public const int NI_NAMEREQD;
	[CCode (cheader_filename = "netdb.h")]
	public const int NI_DGRAM;
	[CCode (cheader_filename = "netdb.h")]
	public const int NI_NOFQDN;
	[CCode (cheader_filename = "netdb.h")]
	public const int NI_NUMERICHOST;
	[CCode (cheader_filename = "netdb.h")]
	public const int NI_NUMERICSERV;

	[CCode (cheader_filename = "netdb.h,sys/socket.h")]
	public int getnameinfo (SockAddr sa, socklen_t salen, char[] node, char[] service, int flags);

	[CCode (cheader_filename = "poll.h", cname = "struct pollfd", has_type_id = false)]
	public struct pollfd {
		public int fd;
		public int events;
		public int revents;
	}

	[CCode (cheader_filename = "poll.h")]
	public const int POLLIN;
	[CCode (cheader_filename = "poll.h")]
	public const int POLLPRI;
	[CCode (cheader_filename = "poll.h")]
	public const int POLLOUT;
	[CCode (cheader_filename = "poll.h")]
	public const int POLLRDHUP;
	[CCode (cheader_filename = "poll.h")]
	public const int POLLERR;
	[CCode (cheader_filename = "poll.h")]
	public const int POLLHUP;
	[CCode (cheader_filename = "poll.h")]
	public const int POLLNVAL;

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "poll.h", cname = "nfds_t", has_type_id = false)]
	public struct nfds_t {
	}

	[CCode (cheader_filename = "poll.h")]
	public int poll (pollfd[] fds, int timeout);
	[CCode (cheader_filename = "poll.h")]
	public int ppoll (pollfd[] fds, timespec? timeout, sigset_t? sigmask);

	[Compact]
	[CCode (cname = "struct passwd", cheader_filename = "pwd.h")]
	public class Passwd {
		public string pw_name;
		public string pw_passwd;
		public uid_t pw_uid;
		public gid_t pw_gid;
		public string pw_gecos;
		public string pw_dir;
		public string pw_shell;
	}
	[CCode (cheader_filename = "pwd.h")]
	public void endpwent ();
	public unowned Passwd? getpwent ();
	public void setpwent ();
	[CCode (cheader_filename = "pwd.h")]
	public unowned Passwd? getpwnam (string name);
	[CCode (cheader_filename = "pwd.h")]
	public unowned Passwd? getpwuid (uid_t uid);

	[Compact]
	[CCode (cname = "sem_t", cheader_filename = "semaphore.h", cprefix = "SEM_", lower_case_cprefix = "sem_", has_type_id = false, copy_function = "", free_function = "sem_close")]
	public class NamedSemaphore {
		[CCode (cname = "sem_open")]
		public NamedSemaphore (string name, int oflag = 0, mode_t mode = 0, uint val = 0);
		public int getvalue (out int sval);
		public int post ();
		public int wait ();
		public int trywait ();
		public int timedwait (Posix.timespec abs_timeout);
		public static int unlink (string name);
		public const int FAILED;
	}

	[CCode (cheader_filename = "sys/resource.h")]
	public const int PRIO_PROCESS;
	[CCode (cheader_filename = "sys/resource.h")]
	public const int PRIO_PGRP;
	[CCode (cheader_filename = "sys/resource.h")]
	public const int PRIO_USER;

	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.ABRT")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGABRT;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.ALRM")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGALRM;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.BUS")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGBUS;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.CHLD")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGCHLD;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.CONT")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGCONT;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.FPE")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGFPE;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.HUP")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGHUP;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.ILL")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGILL;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.INT")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGINT;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.KILL")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGKILL;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.PIPE")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGPIPE;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.QUIT")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGQUIT;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.SEGV")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGSEGV;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.STOP")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGSTOP;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.TERM")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGTERM;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.TSTP")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGTSTP;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.TTIN")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGTTIN;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.TTOU")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGTTOU;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.USR1")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGUSR1;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.USR2")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGUSR2;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.POLL")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGPOLL;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.PROF")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGPROF;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.SYS")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGSYS;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.TRAP")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGTRAP;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.URG")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGURG;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.VTALRM")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGVTALRM;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.XCPU")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGXCPU;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.XFSZ")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGXFSZ;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.IOT")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGIOT;
	[Version (deprecated = true, deprecated_since = "vala-0.40", replacement = "Posix.Signal.STKFLT")]
	[CCode (cheader_filename = "signal.h")]
	public const int SIGSTKFLT;

	/**
	 * Signal constants
	 */
	[CCode (cheader_filename = "signal.h", cname = "int", cprefix = "SIG", has_type_id = false)]
	public enum Signal {
		/**
		 * Abort signal (ANSI)
		 */
		ABRT,
		/**
		 * Alarm clock signal (POSIX)
		 */
		ALRM,
		/**
		 * Access to an undefined portion of memory signal (4.2 BSD)
		 */
		BUS,
		/**
		 * Child process terminated, stopped or continued signal (POSIX)
		 */
		CHLD,
		/**
		 * Old System V name for CHLD
		 */
		[Version (replacement = "Posix.Signal.CHLD")]
		CLD,
		/**
		 * Continue executing, if stopped, signal (POSIX)
		 */
		CONT,
		/**
		 * Emulator trap
		 */
		EMT,
		/**
		 * Floating-point exception signal (ANSI)
		 */
		FPE,
		/**
		 * Hangup signal (POSIX)
		 */
		HUP,
		/**
		 * Illegal instruction signal (ANSI)
		 */
		ILL,
		/**
		 * Information request
		 */
		INFO,
		/**
		 * Terminal interrupt signal (ANSI)
		 */
		INT,
		/**
		 * I/O now possible (4.2 BSD)
		 */
		IO,
		/**
		 * IOT trap signal (4.2 BSD)
		 */
		IOT,
		/**
		 * Kill signal (cannot be caught or ignored) (POSIX)
		 */
		KILL,
		/**
		 * File lock lost
		 */
		LOST,
		/**
		 * Broken pipe signal (POSIX)
		 */
		PIPE,
		/**
		 * Pollable event occurred signal (System V)
		 */
		POLL,
		/**
		 * Profiling timer expired signal (4.2 BSD)
		 */
		PROF,
		/**
		 * Power failure restart (System V)
		 */
		PWR,
		/**
		 * Terminal quit signal (POSIX)
		 */
		QUIT,
		/**
		 * Memory reference segmentation violation signal (ANSI)
		 */
		SEGV,
		/**
		 * Stack fault signal
		 */
		STKFLT,
		/**
		 * Stop executing signal (cannot be caught or ignored) (POSIX)
		 */
		STOP,
		/**
		 * Bad system call signal
		 */
		SYS,
		/**
		 * Termination signal (ANSI)
		 */
		TERM,
		/**
		 * Trace/breakpoint trap signal (POSIX)
		 */
		TRAP,
		/**
		 * Terminal stop signal (POSIX)
		 */
		TSTP,
		/**
		 * Background read from tty signal (POSIX)
		 */
		TTIN,
		/**
		 * Background write to tty signal (POSIX)
		 */
		TTOU,
		/**
		 * Urgent condition on socket signal (4.2 BSD)
		 */
		URG,
		/**
		 * User-defined signal 1 (POSIX)
		 */
		USR1,
		/**
		 * User-defined signal 2 (POSIX)
		 */
		USR2,
		/**
		 * Virtual timer expired signal (4.2 BSD)
		 */
		VTALRM,
		/**
		 * Window size changed signal (4.3 BSD, Sun)
		 */
		WINCH,
		/**
		 * CPU time limit exceeded signal (4.2 BSD)
		 */
		XCPU,
		/**
		 * File size limit exceeded signal (4.2 BSD)
		 */
		XFSZ,
	}

	[CCode (cheader_filename = "signal.h")]
	public const int SA_NOCLDSTOP;
	[CCode (cheader_filename = "signal.h")]
	public const int SA_NOCLDWAIT;
	[CCode (cheader_filename = "signal.h")]
	public const int SA_NODEFER;
	[CCode (cheader_filename = "signal.h")]
	public const int SA_ONSTACK;
	[CCode (cheader_filename = "signal.h")]
	public const int SA_RESETHAND;
	[CCode (cheader_filename = "signal.h")]
	public const int SA_RESTART;
	[CCode (cheader_filename = "signal.h")]
	public const int SA_SIGINFO;
	[CCode (cheader_filename = "signal.h")]
	public const int SI_USER;
	[CCode (cheader_filename = "signal.h")]
	public const int SI_KERNEL;
	[CCode (cheader_filename = "signal.h")]
	public const int SI_QUEUE;
	[CCode (cheader_filename = "signal.h")]
	public const int SI_TIMER;
	[CCode (cheader_filename = "signal.h")]
	public const int SI_MESGQ;
	[CCode (cheader_filename = "signal.h")]
	public const int SI_ASYNCIO;
	[CCode (cheader_filename = "signal.h")]
	public const int SI_SIGIO;
	[CCode (cheader_filename = "signal.h")]
	public const int SI_TKILL;
	[CCode (cheader_filename = "signal.h")]
	public const int ILL_ILLOPC;
	[CCode (cheader_filename = "signal.h")]
	public const int ILL_ILLOPN;
	[CCode (cheader_filename = "signal.h")]
	public const int ILL_ILLADR;
	[CCode (cheader_filename = "signal.h")]
	public const int ILL_ILLTRP;
	[CCode (cheader_filename = "signal.h")]
	public const int ILL_PRVOPC;
	[CCode (cheader_filename = "signal.h")]
	public const int ILL_PRVREG;
	[CCode (cheader_filename = "signal.h")]
	public const int ILL_COPROC;
	[CCode (cheader_filename = "signal.h")]
	public const int ILL_BADSTK;
	[CCode (cheader_filename = "signal.h")]
	public const int FPE_INTDIV;
	[CCode (cheader_filename = "signal.h")]
	public const int FPE_INTOVF;
	[CCode (cheader_filename = "signal.h")]
	public const int FPE_FLTDIV;
	[CCode (cheader_filename = "signal.h")]
	public const int FPE_FLTOVF;
	[CCode (cheader_filename = "signal.h")]
	public const int FPE_FLTUND;
	[CCode (cheader_filename = "signal.h")]
	public const int FPE_FLTRES;
	[CCode (cheader_filename = "signal.h")]
	public const int FPE_FLTINV;
	[CCode (cheader_filename = "signal.h")]
	public const int FPE_FLTSUB;
	[CCode (cheader_filename = "signal.h")]
	public const int SEGV_MAPERR;
	[CCode (cheader_filename = "signal.h")]
	public const int SEGV_ACCERR;
	[CCode (cheader_filename = "signal.h")]
	public const int BUS_ADRALN;
	[CCode (cheader_filename = "signal.h")]
	public const int BUS_ADRERR;
	[CCode (cheader_filename = "signal.h")]
	public const int BUS_OBJERR;
	[CCode (cheader_filename = "signal.h")]
	public const int BUS_MCEERR_AR;
	[CCode (cheader_filename = "signal.h")]
	public const int BUS_MCEERR_AO;
	[CCode (cheader_filename = "signal.h")]
	public const int TRAP_BRKPT;
	[CCode (cheader_filename = "signal.h")]
	public const int TRAP_TRACE;
	[CCode (cheader_filename = "signal.h")]
	public const int TRAP_BRANCH;
	[CCode (cheader_filename = "signal.h")]
	public const int TRAP_HWBKPT;
	[CCode (cheader_filename = "signal.h")]
	public const int CLD_EXITED;
	[CCode (cheader_filename = "signal.h")]
	public const int CLD_KILLED;
	[CCode (cheader_filename = "signal.h")]
	public const int CLD_DUMPED;
	[CCode (cheader_filename = "signal.h")]
	public const int CLD_TRAPPED;
	[CCode (cheader_filename = "signal.h")]
	public const int CLD_STOPPED;
	[CCode (cheader_filename = "signal.h")]
	public const int CLD_CONTINUED;
	[CCode (cheader_filename = "signal.h")]
	public const int POLL_IN;
	[CCode (cheader_filename = "signal.h")]
	public const int POLL_OUT;
	[CCode (cheader_filename = "signal.h")]
	public const int POLL_MSG;
	[CCode (cheader_filename = "signal.h")]
	public const int POLL_ERR;
	[CCode (cheader_filename = "signal.h")]
	public const int POLL_PRI;
	[CCode (cheader_filename = "signal.h")]
	public const int POLL_HUP;
	[CCode (cheader_filename = "signal.h")]
	public const int SIG_BLOCK;
	[CCode (cheader_filename = "signal.h")]
	public const int SIG_UNBLOCK;
	[CCode (cheader_filename = "signal.h")]
	public const int SIG_SETMASK;

	[SimpleType]
	[IntegerType (rank = 6)]
	[CCode (cname = "pid_t", default_value = "0", cheader_filename = "sys/types.h", has_type_id = false)]
	public struct pid_t {
	}

	[CCode (cname = "struct sigaction", cheader_filename = "signal.h", has_type_id = false)]
	public struct sigaction_t {
		sighandler_t     sa_handler;
		siginfohandler_t sa_sigaction;
		sigset_t         sa_mask;
		int              sa_flags;
	}

	[CCode (cname = "struct sigevent", cheader_filename = "signal.h", has_type_id = false)]
	public struct sigevent_t {
		sigval_t         sigev_value;
		int              sigev_signo;
		int              sigev_notify;
	}

	[SimpleType]
	[CCode (cname = "sigval_t", cheader_filename = "signal.h", has_type_id = false)]
	public struct sigval_t {
		int   sival_int;
		void* sival_ptr;
	}

	[CCode (cname = "siginfo_t", cheader_filename = "signal.h", has_type_id = false)]
	public struct siginfo_t {
		int	     si_signo;
		int      si_errno;
		int      si_code;
		int      si_trapno;
		pid_t    si_pid;
		uid_t    si_uid;
		int      si_status;
		clock_t  si_utime;
		clock_t  si_stime;
		sigval_t si_value;
		int      si_int;
		void*    si_ptr;
		int      si_overrun;
		int      si_timerid;
		void*    si_addr;
		long     si_band;
		int      si_fd;
		short    si_addr_lsb;
	}

	[CCode (cheader_filename = "signal.h")]
	public int kill (pid_t pid, int signum);
	[CCode (cheader_filename = "signal.h")]
	public int killpg (pid_t pgpr, int signum);
	[CCode (cheader_filename = "signal.h")]
	public int raise (int signum);
	[CCode (cheader_filename = "signal.h")]
	public void psignal (int signum, string message);
	[CCode (cheader_filename = "signal.h")]
	public int sigemptyset (out sigset_t sigset);
	[CCode (cheader_filename = "signal.h")]
	public int sigfillset (out sigset_t sigset);
	[CCode (cheader_filename = "signal.h")]
	public int sigaddset (ref sigset_t sigset, int signo);
	[CCode (cheader_filename = "signal.h")]
	public int sigdelset (ref sigset_t sigset, int __signo);
	[CCode (cheader_filename = "signal.h")]
	public int sigismember (sigset_t sigset, int __signo);
	[CCode (cheader_filename = "signal.h")]
	public int sigprocmask (int how, sigset_t sigset, out sigset_t oset);
	[CCode (cheader_filename = "signal.h")]
	public int sigqueue (pid_t pid, int signum, sigval_t val);
	[CCode (cheader_filename = "signal.h")]
	public int sigsuspend (sigset_t sigset);
	[CCode (cheader_filename = "signal.h")]
	public int sigpending (sigset_t sigset);
	[CCode (cheader_filename = "signal.h")]
	public int sigwait (sigset_t sigset, out int sig);
	[CCode (cheader_filename = "signal.h")]
	public int sigaction (int signum, sigaction_t? act, out sigaction_t? oldact);

	[CCode (has_target = false, cheader_filename = "signal.h", feature_test_macro = "_GNU_SOURCE")]
	public delegate void sighandler_t (int signal);

	[CCode (has_target = false, cheader_filename = "signal.h")]
	public delegate void siginfohandler_t (int signal, siginfo_t info, void* data);

	[CCode (cheader_filename = "signal.h")]
	public sighandler_t SIG_DFL;

	[CCode (cheader_filename = "signal.h")]
	public sighandler_t SIG_ERR;

	[CCode (cheader_filename = "signal.h")]
	public sighandler_t SIG_IGN;

	[CCode (cheader_filename = "signal.h")]
	public sighandler_t signal (int signum, sighandler_t? handler);

	[CCode (cheader_filename = "stdio.h")]
	[PrintfFormat]
	public void printf (string format,...);

	[CCode (cheader_filename = "stdlib.h")]
	public void abort ();
	[CCode (cheader_filename = "stdlib.h")]
	public void exit (int status);

	[CCode (cheader_filename = "stdlib.h")]
	public void _exit (int status);

	[CCode (has_target = false)]
	public delegate void AtExitFunc ();

	[CCode (cheader_filename = "stdlib.h")]
	public void atexit (AtExitFunc func);

	[CCode (cheader_filename = "stdlib.h")]
	public int mkstemp (string template);

	[CCode (cheader_filename = "stdlib.h")]
	public int mkostemp (string template, int flags);

	[CCode (cheader_filename = "stdlib.h")]
	public string? realpath (string path, [CCode (array_length = false)] uint8[]? resolved_path = null);

	[CCode (cheader_filename = "stdlib.h")]
	public int posix_openpt (int flags);
	[CCode (cheader_filename = "stdlib.h")]
	public int grantpt (int fd);
	[CCode (cheader_filename = "stdlib.h")]
	public int unlockpt (int fd);
	[CCode (cheader_filename = "stdlib.h")]
	public unowned string? ptsname (int fd);

	[CCode (cheader_filename = "stdlib.h")]
	public int system (string command);

	[CCode (has_target = false, cheader_filename = "stdlib.h", cname = "__compar_fn_t")]
	public delegate int compar_fn_t (void* key1, void* key2);

	[CCode (cheader_filename = "stdlib.h")]
	public void* bsearch (void* key, void* base, size_t nmemb, size_t size, compar_fn_t func);

	[CCode (cheader_filename = "stdlib.h")]
	public void qsort (void* base, size_t nmemb, size_t size, compar_fn_t func);

	[CCode (cheader_filename = "stdlib.h")]
	public void qsort_r (void* base, size_t nmemb, size_t size, compar_fn_t func, void* arg);

	[CCode (cheader_filename = "stdlib.h")]
	public const int EXIT_FAILURE;
	[CCode (cheader_filename = "stdlib.h")]
	public const int EXIT_SUCCESS;

	[CCode (cheader_filename = "string.h")]
	public void* memccpy (void* s1, void* s2, int c, size_t n);
	[CCode (cheader_filename = "string.h")]
	public void* memchr (void* s, int c, size_t n);
	[CCode (cheader_filename = "string.h")]
	public int memcmp (void* s1, void* s2, size_t n);
	[CCode (cheader_filename = "string.h")]
	public void* memcpy (void* s1, void* s2, size_t n);
	[CCode (cheader_filename = "string.h")]
	public void* memmove (void* s1, void* s2, size_t n);
	[CCode (cheader_filename = "string.h")]
	public void* memset (void* s, int c, size_t n);
	[CCode (cheader_filename = "string.h")]
	public unowned string strcat (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public unowned string? strchr (string s, int c);
	[CCode (cheader_filename = "string.h")]
	public int strcmp (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public int strcoll (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public unowned string strcpy (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public size_t strcspn (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public string strdup (string s1);
	[CCode (cheader_filename = "string.h")]
	public unowned string strerror (int errnum);
	[CCode (cheader_filename = "string.h")]
	public int* strerror_r (int errnum, string strerrbuf, size_t buflen);
	[CCode (cheader_filename = "string.h")]
	public size_t strlen (string s);
	[CCode (cheader_filename = "string.h")]
	public unowned string strncat (string s1, string s2, size_t n);
	[CCode (cheader_filename = "string.h")]
	public int strncmp (string s1, string s2, size_t n);
	[CCode (cheader_filename = "string.h")]
	public unowned string strncpy (string s1, string s2, size_t n);
	[CCode (cheader_filename = "string.h")]
	public unowned string? strpbrk (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public unowned string? strrchr (string s, int c);
	[CCode (cheader_filename = "string.h")]
	public unowned string? strsignal (int signum);
	[CCode (cheader_filename = "string.h")]
	public size_t strspn (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public unowned string? strstr (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public unowned string? strtok (string s1, string s2);
	[CCode (cheader_filename = "string.h")]
	public unowned string? strtok_r (string? s, string sep, out unowned string lasts);
	[CCode (cheader_filename = "string.h")]
	public size_t strxfrm (string s1, string s2, size_t n);

	[CCode (cheader_filename = "strings.h")]
	public int ffs (int i);

	[CCode (cheader_filename = "stropts.h")]
	public const int I_PUSH;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_POP;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_LOOK;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_FLUSH;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_FLUSHBAND;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_SETSIG;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_GETSIG;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_FIND;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_PEEK;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_SRDOPT;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_GRDOPT;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_NREAD;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_FDINSERT;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_STR;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_SWROPT;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_GWROPT;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_SENDFD;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_RECVFD;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_LIST;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_ATMARK;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_CKBAND;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_GETBAND;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_CANPUT;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_SETCLTIME;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_GETCLTIME;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_LINK;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_UNLINK;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_PLINK;
	[CCode (cheader_filename = "stropts.h")]
	public const int I_PUNLINK;
	[CCode (cheader_filename = "stropts.h")]
	public const int FLUSHR;
	[CCode (cheader_filename = "stropts.h")]
	public const int FLUSHW;
	[CCode (cheader_filename = "stropts.h")]
	public const int FLUSHRW;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_RDNORM;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_RDBAND;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_INPUT;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_HIPRI;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_OUTPUT;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_WRNORM;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_WRBAND;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_MSG;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_ERROR;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_HANGUP;
	[CCode (cheader_filename = "stropts.h")]
	public const int S_BANDURG;
	[CCode (cheader_filename = "stropts.h")]
	public const int RS_HIPRI;
	[CCode (cheader_filename = "stropts.h")]
	public const int RNORM;
	[CCode (cheader_filename = "stropts.h")]
	public const int RMSGD;
	[CCode (cheader_filename = "stropts.h")]
	public const int RMSGN;
	[CCode (cheader_filename = "stropts.h")]
	public const int RPROTNORN;
	[CCode (cheader_filename = "stropts.h")]
	public const int RPROTDAT;
	[CCode (cheader_filename = "stropts.h")]
	public const int RPROTDIS;
	[CCode (cheader_filename = "stropts.h")]
	public const int SNDZERO;
	[CCode (cheader_filename = "stropts.h")]
	public const int ANYMARK;
	[CCode (cheader_filename = "stropts.h")]
	public const int LASTMARK;
	[CCode (cheader_filename = "stropts.h")]
	public const int MUXID_ALL;
	[CCode (cheader_filename = "stropts.h")]
	public const int MSG_ANY;
	[CCode (cheader_filename = "stropts.h")]
	public const int MSG_BAND;
	[CCode (cheader_filename = "stropts.h")]
	public const int MSG_HIPRI;
	[CCode (cheader_filename = "stropts.h")]
	public const int MORECTL;
	[CCode (cheader_filename = "stropts.h")]
	public const int MOREDATA;
	[CCode (cheader_filename = "sys/ioctl.h", sentinel = "")]
	public int ioctl (int fildes, int request, ...);

	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_CREAT;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_EXCL;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_NOWAIT;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const key_t IPC_PRIVATE;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_RMID;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_SET;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_STAT;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_R;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_W;
	[CCode (cheader_filename = "sys/ipc.h")]
	public const int IPC_M;
	[CCode (cheader_filename = "sys/ipc.h")]
	public key_t ftok (string pathname, int proj_id);

	[CCode (cheader_filename = "syslog.h")]
	public void openlog (string ident, int option, int facility );

	[CCode (cheader_filename = "syslog.h")]
	public int setlogmask (int mask);

	[CCode (cheader_filename = "syslog.h")]
	public int LOG_UPTO (int pri);

	[CCode (cheader_filename = "syslog.h"), PrintfFormat]
	public void syslog (int priority, string format, ... );

	[CCode (cheader_filename = "syslog.h")]
	public void closelog ();

	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_PID;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_CONS;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_ODELAY;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_NDELAY;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_NOWAIT;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_EMERG;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_ALERT;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_CRIT;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_ERR;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_WARNING;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_NOTICE;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_INFO;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_DEBUG;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_KERN;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_USER;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_MAIL;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_DAEMON;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_SYSLOG;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LPR;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_NEWS;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_UUCP;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_CRON;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_AUTHPRIV;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_FTP;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LOCAL0;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LOCAL1;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LOCAL2;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LOCAL3;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LOCAL4;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LOCAL5;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LOCAL6;
	[CCode (cheader_filename = "syslog.h")]
	public const int LOG_LOCAL7;

	[CCode (cheader_filename = "sys/socket.h")]
	public const int SOCK_DGRAM;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int SOCK_RAW;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int SOCK_SEQPACKET;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int SOCK_STREAM;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int AF_UNSPEC;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int AF_INET;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int AF_INET6;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int AF_UNIX;

	[CCode (cheader_filename = "sys/socket.h")]
	public const int SHUT_RD;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int SHUT_WR;
	[CCode (cheader_filename = "sys/socket.h")]
	public const int SHUT_RDWR;

	[CCode (cheader_filename = "netdb.h")]
	public const int AI_PASSIVE;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_CANONNAME;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_NUMERICHOST;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_V4MAPPED;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_ALL;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_ADDRCONFIG;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_IDN;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_CANONIDN;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_IDN_ALLOW_UNASSIGNED;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_IDN_USE_STD3_ASCII_RULES;
	[CCode (cheader_filename = "netdb.h")]
	public const int AI_NUMERICSERV;

	[CCode (cheader_filename = "sys/socket.h", sentinel = "")]
	public int accept (int sfd, ... );
	[CCode (cheader_filename = "sys/socket.h", sentinel = "")]
	public int bind (int sockfd, ...);
	[CCode (cheader_filename = "sys/socket.h",  sentinel = "")]
	public int connect(int sfd, ... );
	[CCode (cheader_filename = "sys/socket.h")]
	public int getsockopt (int sockfd, int level, int optname, void* optval, out socklen_t optlen);
	[CCode (cheader_filename = "sys/socket.h")]
	public int listen (int sfd, int backlog);
	[CCode (cheader_filename = "sys/socket.h")]
	public ssize_t recv (int sockfd, void *buf, size_t len, int flags);
	[CCode (cheader_filename = "sys/socket.h")]
	public ssize_t send (int sockfd, void* buf, size_t len, int flags);
	[CCode (cheader_filename = "sys/socket.h", sentinel = "")]
	public ssize_t sendto (int sockfd, void* buf, size_t len, int flags, ...);
	[CCode (cheader_filename = "sys/socket.h", sentinel = "")]
	public ssize_t sendmsg (int sockfd, ...);
	[CCode (cheader_filename = "sys/socket.h")]
	public int setsockopt (int sockfd, int level, int optname, void* optval, socklen_t optlen);
	[CCode (cheader_filename = "sys/socket.h")]
	public int shutdown (int sockfd, int how);
	[CCode (cheader_filename = "sys/socket.h")]
	public int socket (int domain, int type, int protocol);
	[CCode (cheader_filename = "sys/socket.h")]
	public int socketpair (int domain, int type, int protocol, [CCode (array_length = false)] int[] sv);
	[CCode (cheader_filename = "netdb.h")]
	public int getaddrinfo (string node, string service, AddrInfo hints, out AddrInfo *res);
	[CCode (cheader_filename = "netdb.h")]
	public void freeaddrinfo (AddrInfo *res);
	[CCode (cheader_filename = "netdb.h")]
	public unowned string gai_strerror (int errcode);
	[CCode (cheader_filename = "netdb.h")]
	public unowned HostEnt? gethostbyname (string name);

	[CCode (cname = "socklen_t", cheader_filename = "sys/socket.h", default_value = "0", has_type_id = false)]
	public struct socklen_t : int {
	}

	[SimpleType]
	[CCode (cname = "struct in_addr", cheader_filename = "sys/socket.h,netinet/in.h", destroy_function = "", has_type_id = false)]
	public struct InAddr {
		public uint32 s_addr;
	}

	[CCode (cname = "struct in6_addr", cheader_filename = "sys/socket.h,netinet/in.h", destroy_function = "", has_type_id = false)]
	public struct In6Addr {
		public uint8 s6_addr[16];
	}

	[CCode (cname = "struct sockaddr", cheader_filename = "sys/socket.h", destroy_function = "", has_type_id = false)]
	public struct SockAddr {
		public int sa_family;
		[CCode (array_length = false)]
		public char[] sa_data;
	}

	[CCode (cname = "struct sockaddr_in", cheader_filename = "netinet/in.h", destroy_function = "", has_type_id = false)]
	public struct SockAddrIn {
		public int sin_family;
		public uint16 sin_port;
		public InAddr sin_addr;
	}

	[CCode (cname = "struct sockaddr_in6", cheader_filename = "netinet/in.h", destroy_function = "", has_type_id = false)]
	public struct SockAddrIn6 {
		public int sin6_family;
		public uint16 sin6_port;
		public uint32 sin6_flowinfo;
		public In6Addr sin6_addr;
		public uint32 sin6_scope_id;
	}

	[CCode (cname = "struct addrinfo", cheader_filename = "netdb.h", destroy_function = "", has_type_id = false)]
	public struct AddrInfo {
		public int ai_flags;
		public int ai_family;
		public int ai_socktype;
		public int ai_protocol;
		public socklen_t ai_addrlen;
		public SockAddr *ai_addr;
		public string ai_canonname;
		public AddrInfo *ai_next;
	}

	[Compact]
	[CCode (cname = "struct hostent", cheader_filename = "netdb.h", destroy_function = "", has_type_id = false)]
	public class HostEnt {
		public string h_name;
		[CCode (array_length=false, array_null_terminated=true)]
		public string[] h_aliases;
		public int h_addrtype;
		public int h_length;
		[CCode (array_length=false, array_null_terminated=true)]
		public string[] h_addr_list;
	}

	[CCode (cname = "struct msqid_ds", cheader_filename = "sys/msg.h", free_function = "", has_type_id = false)]
	public struct MsqIdDs {
	}

	[CCode (cname = "short", cheader_filename = "sys/msg.h", cprefix = "MSG_", has_type_id = false)]
	public enum MsqCmd {
		STAT,
		INFO
	}

	[CCode (cheader_filename = "sys/msg.h")]
	public const int MSG_COPY;
	[CCode (cheader_filename = "sys/msg.h")]
	public const int MSG_EXCEPT;
	[CCode (cheader_filename = "sys/msg.h")]
	public const int MSG_NOERROR;
	[CCode (cheader_filename = "sys/msg.h")]
	public int msgctrl (int msqid, MsqCmd cmd, MsqIdDs buf);
	[CCode (cheader_filename = "sys/msg.h")]
	public int msgget (key_t key, int msgflg = 0);
	[CCode (cheader_filename = "sys/msg.h")]
	public ssize_t msgrcv (int msqid, uint8[] buf, long msgtyp = 0, int msgflg = 0);
	[CCode (cheader_filename = "sys/msg.h")]
	public int msgsnd (int msqid, uint8[] buf, int msgflg = 0);

	[CCode (cname = "struct sembuf", cheader_filename = "sys/sem.h", free_function = "", has_type_id = false)]
	public struct SemBuf {
		public ushort sem_num;
		public SemCmd sem_op;
		public short sem_flg;
	}

	[CCode (cname = "short", cheader_filename = "sys/sem.h", cprefix = "", has_type_id = false)]
	public enum SemCmd {
		GETPID,
		GETVAL,
		GETALL,
		GETNCNT,
		GETZCNT,
		SETVAL,
		SETALL,
		IPC_STAT,
		IPC_SET,
		IPC_RMID,
	}

	[CCode (cheader_filename = "sys/sem.h")]
	public const short SEM_UNDO;
	[CCode (cheader_filename = "sys/sem.h")]
	public int semctl (int semid, int semnum, int cmd, ...);
	[CCode (cheader_filename = "sys/sem.h")]
	public int semget (key_t key, int nsems, int semflg = 0);
	[CCode (cheader_filename = "sys/sem.h")]
	public int semop (int semid, SemBuf[] sops);

	[CCode (cheader_filename = "sys/shm.h")]
	public void* shmat (int shmid, void* shmaddr, int shmflg = 0);
	[CCode (cheader_filename = "sys/shm.h")]
	public int shmdt (void* shmaddr);
	[CCode (cheader_filename = "sys/shm.h")]
	public int shmget (key_t key, size_t size, int shmflg = 0);

	[CCode (cheader_filename = "sys/stat.h")]
	public int mkfifo (string filename, mode_t mode);

	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IFMT;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IFBLK;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IFCHR;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IFIFO;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IFREG;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IFDIR;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IFLNK;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IFSOCK;

	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IRWXU;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IRUSR;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IWUSR;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IXUSR;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IRWXG;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IRGRP;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IWGRP;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IXGRP;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IRWXO;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IROTH;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IWOTH;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_IXOTH;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_ISUID;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_ISGID;
	[CCode (cheader_filename = "sys/stat.h")]
	public const mode_t S_ISVTX;

	[CCode (cheader_filename = "sys/stat.h")]
	public bool S_ISBLK (mode_t mode);
	[CCode (cheader_filename = "sys/stat.h")]
	public bool S_ISCHR (mode_t mode);
	[CCode (cheader_filename = "sys/stat.h")]
	public bool S_ISDIR (mode_t mode);
	[CCode (cheader_filename = "sys/stat.h")]
	public bool S_ISFIFO (mode_t mode);
	[CCode (cheader_filename = "sys/stat.h")]
	public bool S_ISREG (mode_t mode);
	[CCode (cheader_filename = "sys/stat.h")]
	public bool S_ISLNK (mode_t mode);
	[CCode (cheader_filename = "sys/stat.h")]
	public bool S_ISSOCK (mode_t mode);

	[CCode (cheader_filename = "sys/stat.h", cname = "struct stat", has_type_id = false)]
	public struct Stat {
		public dev_t st_dev;
		public ino_t st_ino;
		public mode_t st_mode;
		public nlink_t st_nlink;
		public uid_t st_uid;
		public gid_t st_gid;
		public dev_t st_rdev;
		public size_t st_size;
		public timespec st_atim;
		public time_t st_atime;
		public timespec st_mtim;
		public time_t st_mtime;
		public timespec st_ctim;
		public time_t st_ctime;
		public blksize_t st_blksize;
		public blkcnt_t st_blocks;
	}
	[CCode (cheader_filename = "sys/stat.h")]
	int fstat( int fd, out Stat buf);
	[CCode (cheader_filename = "sys/stat.h")]
	int stat (string filename, out Stat buf);
	[CCode (cheader_filename = "sys/stat.h")]
	int lstat (string filename, out Stat buf);

	[CCode (cheader_filename = "sys/stat.h")]
	public int chmod (string filename, mode_t mode);
	[CCode (cheader_filename = "sys/stat.h")]
	public int fchmod (int fd, mode_t mode);
	[CCode (cheader_filename = "sys/stat.h")]
	public mode_t umask (mode_t mask);
	[CCode (cheader_filename = "sys/stat.h")]
	public int mkdir (string path, mode_t mode);
	[CCode (cheader_filename = "sys/types.h,sys/stat.h,fcntl.h,unistd.h")]
	public pid_t mknod (string pathname, mode_t mode, dev_t dev);

	[CCode (cheader_filename = "sys/stat.h")]
	public int utimensat (int dirfd, string pathname, [CCode (array_length = false)] timespec[] times, int flags = 0);
	[CCode (cheader_filename = "sys/stat.h")]
	public int futimens (int fd, [CCode (array_length = false)] timespec[] times);

	[CCode (cheader_filename = "sys/wait.h")]
	public pid_t wait (out int status);
	[CCode (cheader_filename = "sys/wait.h")]
	public pid_t waitpid (pid_t pid, out int status, int options);
	[CCode (cheader_filename = "sys/wait.h")]
	public const int WNOHANG;
	[CCode (cheader_filename = "sys/wait.h")]
	public const int WUNTRACED;
	[CCode (cheader_filename = "sys/wait.h")]
	public const int WCONTINUED;

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/types.h", cname = "key_t", has_type_id = false)]
	public struct key_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/statvfs.h", has_type_id = false)]
	public struct fsblkcnt_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/statvfs.h", has_type_id = false)]
	public struct fsfilcnt_t {
	}

	[CCode (cheader_filename = "sys/statvfs.h", cname = "struct statvfs", has_type_id = false)]
	public struct statvfs {
		public ulong f_bsize;
		public ulong f_frsize;
		public fsblkcnt_t f_blocks;
		public fsblkcnt_t f_bfree;
		public fsblkcnt_t f_bavail;
		public fsfilcnt_t f_files;
		public fsfilcnt_t f_ffree;
		public fsfilcnt_t f_favail;
	}

	[CCode (cheader_filename = "sys/statvfs.h", cname = "statvfs")]
	public int statvfs_exec (string path, out statvfs buf);
	[CCode (cheader_filename = "sys/statvfs.h")]
	public int fstatvfs (int fs, out statvfs buf);

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname="off_t", cheader_filename = "sys/types.h", has_type_id = false)]
	public struct off_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/types.h", has_type_id = false)]
	public struct uid_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/types.h", has_type_id = false)]
	public struct gid_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cname = "mode_t", cheader_filename = "sys/types.h", has_type_id = false)]
	public struct mode_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/types.h", has_type_id = false)]
	public struct dev_t {
	}

	[CCode (cheader_filename = "sys/sysmacros.h")]
	uint major (dev_t dev);
	[CCode (cheader_filename = "sys/sysmacros.h")]
	uint minor (dev_t dev);
	[CCode (cheader_filename = "sys/sysmacros.h")]
	dev_t makedev (int maj, int min);

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/types.h", has_type_id = false)]
	public struct ino_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/types.h", has_type_id = false)]
	public struct nlink_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/types.h", has_type_id = false)]
	public struct blksize_t {
	}

	[SimpleType]
	[IntegerType (rank = 9)]
	[CCode (cheader_filename = "sys/types.h", has_type_id = false)]
	public struct blkcnt_t {
	}

	[CCode (cheader_filename = "time.h", has_type_id = false)]
	[IntegerType (rank = 8)]
	public struct clock_t {
		[CCode (cname = "clock")]
		public clock_t ();
	}

	[CCode (cheader_filename = "time.h")]
	public unowned string? ctime (ref time_t clock);

	[CCode (cname = "struct tm", cheader_filename = "time.h", has_type_id = false)]
	public struct tm {
		public int tm_sec;
		public int tm_min;
		public int tm_hour;
		public int tm_mday;
		public int tm_mon;
		public int tm_year;
		public int tm_wday;
		public int tm_yday;
		public int tm_isdst;
	}

	[CCode (cname = "struct timespec", cheader_filename = "time.h", has_type_id = false)]
	public struct timespec {
		public time_t tv_sec;
		public long tv_nsec;
	}

    [CCode (array_length = false, cheader_filename = "time.h")]
	public string[] tzname;
	[CCode (cheader_filename = "time.h")]
	public const long timezone;
	[CCode (cheader_filename = "time.h")]
	public const int daylight;

	[CCode (cheader_filename = "time.h")]
	public void tzset ();

	[SimpleType]
	[IntegerType]
	[CCode (cheader_filename = "time.h", has_type_id = false)]
	public struct clockid_t {
	}

	[CCode (cheader_filename = "time.h")]
	public const clockid_t CLOCK_REALTIME;
	[CCode (cheader_filename = "time.h")]
	public const clockid_t CLOCK_MONOTONIC;
	[CCode (cheader_filename = "time.h")]
	public const clockid_t CLOCK_PROCESS_CPUTIME_ID;
	[CCode (cheader_filename = "time.h")]
	public const clockid_t CLOCK_THREAD_CPUTIME_ID;
	[CCode (cheader_filename = "time.h")]
	public const clockid_t CLOCK_REALTIME_COARSE;
	[CCode (cheader_filename = "time.h")]
	public const clockid_t CLOCK_MONOTONIC_COARSE;

	[CCode (cheader_filename = "time.h")]
	int clock_gettime (clockid_t clk_id, out timespec tp);

	[CCode (cheader_filename = "sys/time.h,sys/resource.h")]
	public int getpriority (int which, int who);
	[CCode (cheader_filename = "sys/time.h,sys/resource.h")]
	public int setpriority (int which, int who, int prio);

	[CCode (cname = "struct iovec", cheader_filename = "sys/uio.h", has_type_id = false)]
	public struct iovector {
		public void* iov_base;
		public size_t iov_len;
	}

	[CCode (cheader_filename = "unistd.h")]
	public int close (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public int execl (string path, params string[] arg);
	[CCode (cheader_filename = "unistd.h")]
	public int execlp (string path, params string[] arg);
	[CCode (cheader_filename = "unistd.h")]
	public int execv (string path, [CCode (array_length = false, null_terminated = true)] string[] arg);
	[CCode (cheader_filename = "unistd.h")]
	public int execvp (string path, [CCode (array_length = false, null_terminated = true)] string[] arg);
	[CCode (cheader_filename = "unistd.h")]
	public int pipe ([CCode (array_length = false, null_terminated = false)] int[] pipefd);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t read (int fd, void* buf, size_t count);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t pread (int fd, void* buf, size_t count, off_t offset);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t readlink (string path, char[] buf);
	[CCode (cheader_filename = "sys/uio.h")]
	public ssize_t readv (int fd, iovector vector, int iovcnt = 1);
	[CCode (cname = "readv", cheader_filename = "sys/uio.h")]
	public ssize_t read_vectors (int fd, iovector[] vector);
	[CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int setegid (gid_t egid);
	[CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int seteuid (gid_t euid);
	[CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int setgid (gid_t gid);
	[CCode (cheader_filename = "unistd.h,sys/types.h")]
	public int setuid (uid_t uid);
	[CCode (cheader_filename = "unistd.h")]
	public int unlink (string filename);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t write (int fd, void* buf, size_t count);
	[CCode (cheader_filename = "unistd.h")]
	public ssize_t pwrite (int fd, void* buf, size_t count, off_t offset);
	[CCode (cheader_filename = "sys/uio.h")]
	public ssize_t writev (int fd, iovector vector, int iovcnt = 1);
	[CCode (cname = "writev", cheader_filename = "sys/uio.h")]
	public ssize_t write_vectors (int fd, iovector[] vector);
	[CCode (cheader_filename = "unistd.h")]
	public off_t lseek(int fildes, off_t offset, int whence);

	[CCode (cheader_filename = "unistd.h")]
	public const int SEEK_SET;
	[CCode (cheader_filename = "unistd.h")]
	public const int SEEK_CUR;
	[CCode (cheader_filename = "unistd.h")]
	public const int SEEK_END;

	[CCode (cheader_filename = "unistd.h")]
	public pid_t fork ();
	[CCode (cheader_filename = "unistd.h")]
	public pid_t vfork ();
	[CCode (cheader_filename = "unistd.h")]
	public unowned string ttyname (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public int ttyname_r (int fd, char[] buf);
	[CCode (cheader_filename = "unistd.h")]
	public bool isatty (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public int link (string from, string to);
	[CCode (cheader_filename = "unistd.h")]
	public int symlink (string from, string to);
	[CCode (cheader_filename = "unistd.h")]
	public long sysconf (int name);
	[CCode (cheader_filename = "unistd.h")]
	public int rmdir (string path);
	[CCode (cheader_filename = "unistd.h")]
	public pid_t tcgetpgrp (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public int tcsetpgrp (int fd, pid_t pgrp_id);
	[CCode (cheader_filename = "unistd.h")]
	public unowned string getlogin ();
	[CCode (cheader_filename = "unistd.h")]
	public int vhangup ();
	[CCode (cheader_filename = "unistd.h")]
	public int revoke (string file);
	[CCode (cheader_filename = "unistd.h")]
	public int acct (string name);
	[CCode (cheader_filename = "unistd.h")]
	public unowned string getusershell ();
	[CCode (cheader_filename = "unistd.h")]
	public void endusershell ();
	[CCode (cheader_filename = "unistd.h")]
	public void setusershell ();
	[CCode (cheader_filename = "unistd.h")]
	public int chroot (string path);
	[Version (deprecated_since = "POSIX.2", replacement = "termios ECHO flag")]
	[CCode (cheader_filename = "unistd.h")]
	public unowned string? getpass (string prompt);
	[CCode (cheader_filename = "unistd.h", feature_test_macro = "_XOPEN_SOURCE")]
	public unowned string? crypt (string key, string salt);
	[CCode (cheader_filename = "unistd.h")]
	public int getpagesize ();
	[CCode (cheader_filename = "unistd.h")]
	public int getdtablesize ();

	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_ARG_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_CHILD_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_HOST_NAME_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_LOGIN_NAME_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_CLK_TCK;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_OPEN_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_PAGESIZE;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_RE_DUP_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_STREAM_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_SYMLOOP_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_TTY_NAME_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_TZNAME_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_VERSION;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_BASE_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_BC_DIM_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_BC_SCALE_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_BC_STRING_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_COLL_WEIGHTS_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_EXRP_NEST_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_LINE_MAX;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_2_VERSION;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_2_C_DEV;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_2_FORT_DEV;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_2_FORT_RUN;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_2_LOCALEDEF;
	[CCode (cheader_filename = "unistd.h")]
	public const int _SC_2_SW_DEV;

	[CCode (cheader_filename = "unistd.h")]
	public const int STDIN_FILENO;
	[CCode (cheader_filename = "unistd.h")]
	public const int STDOUT_FILENO;
	[CCode (cheader_filename = "unistd.h")]
	public const int STDERR_FILENO;
	[CCode (cheader_filename = "unistd.h")]
	public const int R_OK;
	[CCode (cheader_filename = "unistd.h")]
	public const int W_OK;
	[CCode (cheader_filename = "unistd.h")]
	public const int X_OK;
	[CCode (cheader_filename = "unistd.h")]
	public const int F_OK;

	[CCode (cheader_filename = "unistd.h")]
	public int access (string patchname, int mode);
	[CCode (cheader_filename = "unistd.h")]
	public int euidaccess (string patchname, int mode);
	[CCode (cheader_filename = "unistd.h")]
	public int eaccess (string patchname, int mode);

	[CCode (cheader_filename = "unistd.h")]
	public uint alarm (uint seconds);
	[CCode (cheader_filename = "unistd.h")]
	public uint ualarm (uint useconds);
	[CCode (cheader_filename = "unistd.h")]
	public uint sleep (uint seconds);
	[CCode (cheader_filename = "unistd.h")]
	public uint usleep (uint useconds);
	[CCode (cheader_filename = "unistd.h")]
	public int pause ();
	[CCode (cheader_filename = "unistd.h")]
	public int chown (string filename, uid_t owner, gid_t group);
	[CCode (cheader_filename = "unistd.h")]
	public int fchown (int fd, uid_t owner, gid_t group);
	[CCode (cheader_filename = "unistd.h")]
	public int lchown (string filename, uid_t owner, gid_t group);
	[CCode (cheader_filename = "unistd.h")]
	public int chdir (string filepath);
	[CCode (cheader_filename = "unistd.h")]
	public int fchdir (int file);
	[CCode (cheader_filename = "unistd.h")]
	public int dup (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public int dup2 (int fd1, int fd2);
	[CCode (cheader_filename = "unistd.h")]
	public int gethostname (char[] name);
	[CCode (cheader_filename = "unistd.h")]
	public pid_t getpid ();
	[CCode (cheader_filename = "unistd.h")]
	public pid_t getppid ();
	[CCode (cheader_filename = "unistd.h")]
	public pid_t getpgrp ();
	[CCode (cheader_filename = "unistd.h")]
	public pid_t getpgid (pid_t pid);
	[CCode (cheader_filename = "unistd.h")]
	public int setpgid (pid_t pid, pid_t pgid);
	[CCode (cheader_filename = "unistd.h")]
	public pid_t setpgrp ();
	[CCode (cheader_filename = "unistd.h")]
	public pid_t getsid (pid_t pid);
	[CCode (cheader_filename = "unistd.h")]
	public uid_t getuid ();
	[CCode (cheader_filename = "unistd.h")]
	public uid_t geteuid ();
	[CCode (cheader_filename = "unistd.h")]
	public gid_t getgid ();
	[CCode (cheader_filename = "unistd.h")]
	public gid_t getegid ();
	[CCode (cheader_filename = "unistd.h")]
	public int group_member (gid_t gid);
	[CCode (cheader_filename = "unistd.h")]
	public pid_t setsid ();
	[CCode (cheader_filename = "unistd.h")]
	public pid_t tcgetsid (int fd);

	[CCode (cheader_filename = "unistd.h")]
	public int fsync (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public int fdatasync (int fd);
	[CCode (cheader_filename = "unistd.h")]
	public int sync ();

	[CCode (cheader_filename = "unistd.h")]
	public int ftruncate(int fd, off_t length);
	[CCode (cheader_filename = "unistd.h")]
	public int truncate(string path, off_t length);
	[CCode (cheader_filename = "unistd.h")]
	public int nice (int inc);

	[SimpleType]
	[CCode (cname = "cc_t", cheader_filename = "termios.h", has_type_id = false)]
	[IntegerType (rank = 3, min = 0, max = 255)]
	public struct cc_t {
	}

	[SimpleType]
	[CCode (cname = "speed_t", cheader_filename = "termios.h", has_type_id = false)]
	[IntegerType (rank = 7)]
	public struct speed_t {
	}

	[SimpleType]
	[CCode (cname = "tcflag_t", cheader_filename = "termios.h", has_type_id = false)]
	[IntegerType (rank = 7)]
	public struct tcflag_t {
	}

	[CCode (cname="struct termios", cheader_filename = "termios.h", has_type_id = false)]
	public struct termios
	{
		public tcflag_t c_iflag;
		public tcflag_t c_oflag;
		public tcflag_t c_cflag;
		public tcflag_t c_lflag;
		public cc_t c_line;
		public cc_t c_cc[32];
		public speed_t c_ispeed;
		public speed_t c_ospeed;
	}

	[CCode (cheader_filename = "termios.h")]
	public int tcgetattr (int fd, out termios termios_p);
	[CCode (cheader_filename = "termios.h")]
	public int tcsetattr (int fd, int optional_actions, termios termios_p);
	[CCode (cheader_filename = "termios.h")]
	public int tcsendbreak (int fd, int duration);
	[CCode (cheader_filename = "termios.h")]
	public int tcdrain (int fd);
	[CCode (cheader_filename = "termios.h")]
	public int tcflush (int fd, int queue_selector);
	[CCode (cheader_filename = "termios.h")]
	public int tcflow (int fd, int action);
	[CCode (cheader_filename = "termios.h")]
	public void cfmakeraw (ref termios termios_p);
	[CCode (cheader_filename = "termios.h")]
	public speed_t cfgetispeed (termios termios_p);
	[CCode (cheader_filename = "termios.h")]
	public speed_t cfgetospeed (termios termios_p);
	[CCode (cheader_filename = "termios.h")]
	public int cfsetispeed (ref termios termios_p, speed_t speed);
	[CCode (cheader_filename = "termios.h")]
	public int cfsetospeed (ref termios termios_p, speed_t speed);
	[CCode (cheader_filename = "termios.h")]
	public int cfsetspeed (ref termios termios, speed_t speed);

	//c_iflag
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t IGNBRK;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t BRKINT;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t IGNPAR;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t PARMRK;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t INPCK;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ISTRIP;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t INLCR;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t IGNCR;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t IXON;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t IXANY;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t IXOFF;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ICRNL;

	//c_oflag
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t OPOST;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ONLCR;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t OCRNL;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ONOCR;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ONLRET;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t OFILL;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t NLDLY;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t NL0;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t NL1;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CRDLY;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CR0;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CR1;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CR2;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CR3;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t TABDLY;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t TAB0;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t TAB1;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t TAB2;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t TAB3;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t BSDLY;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t BS0;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t BS1;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t VTDLY;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t VT0;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t VT1;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t FFDLY;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t FF0;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t FF1;

	//c_cflag
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CSIZE;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CS5;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CS6;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CS7;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CS8;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CSTOPB;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CREAD;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t PARENB;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t PARODD;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t HUPCL;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t CLOCAL;

	//c_lflag
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ISIG;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ICANON;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ECHO;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ECHOE;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ECHOK;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t ECHONL;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t NOFLSH;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t TOSTOP;
	[CCode (cheader_filename = "termios.h")]
	public const tcflag_t IEXTEN;

	//c_cc indexes
	[CCode (cheader_filename = "termios.h")]
	public const int VINTR;
	[CCode (cheader_filename = "termios.h")]
	public const int VQUIT;
	[CCode (cheader_filename = "termios.h")]
	public const int VERASE;
	[CCode (cheader_filename = "termios.h")]
	public const int VKILL;
	[CCode (cheader_filename = "termios.h")]
	public const int VEOF;
	[CCode (cheader_filename = "termios.h")]
	public const int VMIN;
	[CCode (cheader_filename = "termios.h")]
	public const int VEOL;
	[CCode (cheader_filename = "termios.h")]
	public const int VTIME;
	[CCode (cheader_filename = "termios.h")]
	public const int VSTART;
	[CCode (cheader_filename = "termios.h")]
	public const int VSTOP;
	[CCode (cheader_filename = "termios.h")]
	public const int VSUSP;

	//optional_actions
	[CCode (cheader_filename = "termios.h")]
	public const int TCSANOW;
	[CCode (cheader_filename = "termios.h")]
	public const int TCSADRAIN;
	[CCode (cheader_filename = "termios.h")]
	public const int TCSAFLUSH;

	//queue_selector
	[CCode (cheader_filename = "termios.h")]
	public const int TCIFLUSH;
	[CCode (cheader_filename = "termios.h")]
	public const int TCOFLUSH;
	[CCode (cheader_filename = "termios.h")]
	public const int TCIOFLUSH;

	//action
	[CCode (cheader_filename = "termios.h")]
	public const int TCOOFF;
	[CCode (cheader_filename = "termios.h")]
	public const int TCOON;
	[CCode (cheader_filename = "termios.h")]
	public const int TCIOFF;
	[CCode (cheader_filename = "termios.h")]
	public const int TCION;

	//speed
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B0;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B50;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B75;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B110;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B134;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B150;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B200;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B300;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B600;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B1200;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B1800;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B2400;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B4800;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B9600;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B19200;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B38400;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B57600;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B115200;
	[CCode (cheader_filename = "termios.h")]
	public const speed_t B230400;

	[CCode (cname = "fd_set", cheader_filename = "sys/select.h", has_type_id = false)]
	public struct fd_set {
	}

	[CCode (cname = "struct timeval", cheader_filename = "sys/time.h", has_type_id = false)]
	public struct timeval {
		public time_t tv_sec;
		public long tv_usec;
		[CCode (cname = "gettimeofday")]
		public int get_time_of_day (void * timezone = null);
		[CCode (cname = "settimeofday")]
		public int set_time_of_day (void * timezone = null);
	}

	[CCode (cname = "sigset_t", cheader_filename = "sys/select.h", has_type_id = false)]
	public struct sigset_t {
	}

	[CCode (cheader_filename = "sys/select.h")]
	public int select (int nfds, fd_set* readfds, fd_set* writefds, fd_set* exceptfds, timeval timeout);
	[CCode (cheader_filename = "sys/select.h")]
	public void FD_CLR (int fd, ref fd_set @set);
	[CCode (cheader_filename = "sys/select.h")]
	public int  FD_ISSET (int fd, fd_set @set);
	[CCode (cheader_filename = "sys/select.h")]
	public void FD_SET (int fd, ref fd_set @set);
	[CCode (cheader_filename = "sys/select.h")]
	public void FD_ZERO (out fd_set @set);
	[CCode (cheader_filename = "sys/select.h")]
	public int pselect (int nfds, fd_set* readfds, fd_set* writefds, fd_set* exceptfds, timespec timeout, sigset_t sigmask);

	// sys/mman.h - Posix mmap(), munmap(), mprotect()
	[CCode (cheader_filename = "sys/mman.h")]
	public void *mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
	[CCode (cheader_filename = "sys/mman.h")]
	public int munmap(void *addr, size_t length);
	[CCode (cheader_filename = "sys/mman.h")]
	public int mprotect(void *addr, size_t len, int prot);
	[CCode (cheader_filename = "sys/mman.h")]
	public const int PROT_READ;
	[CCode (cheader_filename = "sys/mman.h")]
	public const int PROT_WRITE;
	[CCode (cheader_filename = "sys/mman.h")]
	public const int PROT_EXEC;
	[CCode (cheader_filename = "sys/mman.h")]
	public const int MAP_SHARED;
	[CCode (cheader_filename = "sys/mman.h")]
	public const int MAP_PRIVATE;
	[CCode (cheader_filename = "sys/mman.h")]
	public const int MAP_FIXED;
	[CCode (cheader_filename = "sys/mman.h")]
	public void *MAP_FAILED;
	// sys/mman.h - [MLR] Range Memory Locking
	[CCode (cheader_filename = "sys/mman.h")]
	public int mlock(void *addr, size_t len);
	[CCode (cheader_filename = "sys/mman.h")]
	public int munlock(void *addr, size_t len);
	// sys/mman.h - [SHM] Shared Memory
	[CCode (cheader_filename = "sys/mman.h")]
	public int shm_open (string name, int oflag, mode_t mode = 0);
	[CCode (cheader_filename = "sys/mman.h")]
	public int shm_unlink (string name);
	// sys/mman.h - Process Memory Locking
	[CCode (cheader_filename = "sys/mman.h")]
	public const int MCL_CURRENT;
	[CCode (cheader_filename = "sys/mman.h")]
	public const int MCL_FUTURE;
	[CCode (cheader_filename = "sys/mman.h")]
	public int mlockall (int flags);
	[CCode (cheader_filename = "sys/mman.h")]
	public int munlockall ();
	// sys/mman.h - [XSI] X/Open System Interfaces
	[CCode (cheader_filename = "sys/mman.h")]
	public int msync(void *addr, size_t len, int flags);
	[CCode (cheader_filename = "sys/mman.h")]
	public const int MS_ASYNC;
	[CCode (cheader_filename = "sys/mman.h")]
	public const int MS_INVALIDATE;
	[CCode (cheader_filename = "sys/mman.h")]
	public const int MS_SYNC;

	[CCode (cname = "struct utsname", cheader_filename = "sys/utsname.h", has_type_id = false)]
	public struct utsname {
		public unowned string sysname;
		public unowned string nodename;
		public unowned string release;
		public unowned string version;
		public unowned string machine;
		[CCode (cname = "uname")]
		public utsname ();
	}

	[Compact]
	[CCode (cname = "FILE", free_function = "fclose", cheader_filename = "stdio.h")]
	public class FILE {
		[CCode (cname = "EOF", cheader_filename = "stdio.h")]
		public const int EOF;
		[CCode (cname = "SEEK_SET", cheader_filename = "stdio.h")]
		public const int SEEK_SET;
		[CCode (cname = "SEEK_CUR", cheader_filename = "stdio.h")]
		public const int SEEK_CUR;
		[CCode (cname = "SEEK_END", cheader_filename = "stdio.h")]
		public const int SEEK_END;

		[CCode (cname = "fopen")]
		public static FILE? open (string path, string mode);
		[CCode (cname = "fdopen")]
		public static FILE? fdopen (int fildes, string mode);
		[CCode (cname = "popen")]
		public static FILE? popen (string command, string mode);

		[CCode (cname = "fprintf")]
		[PrintfFormat ()]
		public int printf (string format, ...);
		[CCode (cname = "fputc", instance_pos = -1)]
		public int putc (char c);
		[CCode (cname = "fputs", instance_pos = -1)]
		public int puts (string s);
		[CCode (cname = "fwrite", instance_pos = -1)]
		public size_t write (void *ptr, size_t size, size_t nmemb);
		[CCode (cname = "fread", instance_pos = -1)]
		public size_t read (void *ptr, size_t size, size_t nmemb);
		[CCode (cname = "fgetc")]
		public int getc ();
		[CCode (cname = "fgets", instance_pos = -1)]
		public unowned string? gets (char[] s);
		[CCode (cname = "feof")]
		public bool eof ();
		[CCode (cname = "fscanf"), ScanfFormat]
		public int scanf (string format, ...);
		[CCode (cname = "fflush")]
		public int flush ();
		[CCode (cname = "fseek")]
		public int seek (long offset, int whence);
		[CCode (cname = "ftell")]
		public long tell ();
		[CCode (cname = "rewind")]
		public void rewind ();
		[CCode (cname = "fileno")]
		public int fileno ();
		[CCode (cname = "ferror")]
		public int error ();
		[CCode (cname = "clearerr")]
		public void clearerr ();
	}

	public static FILE stderr;
	public static FILE stdout;
	public static FILE stdin;

	[CCode (cheader_filename = "stdio.h")]
	public void perror (string s);

	[CCode(cheader_filename = "sched.h", cprefix = "sched_")]
	namespace Sched {
		[SimpleType]
		[CCode (cname = "struct sched_param", has_type_id = false)]
		public struct Param {
			public int sched_priority;
		}

		public static int setparam(Posix.pid_t pid, ref Sched.Param param);
		public static int getparam(Posix.pid_t pid, out Sched.Param param);

		public static int setscheduler(Posix.pid_t pid, Algorithm policy, ref Sched.Param param);
		public static Algorithm getscheduler(Posix.pid_t pid);

		public static int @yield();

		public static int get_priority_max(int algorithm);
		public static int get_priority_min(int algorithm);

		public static int rr_get_interval(Posix.pid_t pid, out Posix.timespec? interval);

		[CCode (cprefix = "SCHED_", cname = "int", has_type_id = false)]
		public enum Algorithm {
			OTHER,
			FIFO,
			RR,
			BATCH,
			IDLE
		}
	}

	[Compact]
	[CCode(cheader_filename = "sched.h", cname = "cpu_set_t", free_function = "CPU_FREE", copy_function="memcpy")]
	public class CpuSet {
		[CCode(cname = "CPU_ALLOC")]
		public CpuSet(int num = 1);

		[CCode(cname = "CPU_ALLOC_SIZE")]
		public static size_t alloc_size(int num = 1);

		[CCode(cname = "CPU_SETSIZE")]
		public static size_t size;

		[CCode(cname = "CPU_COUNT")]
		public int count();

		[CCode(cname = "CPU_COUNT_S", instance_pos = -1)]
		public int count_sized(size_t num);

		[CCode(cname = "CPU_ZERO")]
		public void zero();

		[CCode(cname = "CPU_ZERO_S", instance_pos = -1)]
		public void zero_sized(size_t num);

		[CCode(cname = "CPU_SET", instance_pos = -1)]
		public void @set(int cpu);

		[CCode(cname = "CPU_SET_S", instance_pos = -1)]
		public void @set_sized(int cpu, size_t num);

		[CCode(cname = "CPU_CLR", instance_pos = -1)]
		public void clr(int cpu);

		[CCode(cname = "CPU_CLR_S", instance_pos = -1)]
		public void clr_sized(int cpu, size_t num);

		[CCode(cname = "CPU_ISSET", instance_pos = -1)]
		public bool is_set(int cpu);

		[CCode(cname = "CPU_ISSET_S", instance_pos = -1)]
		public bool is_set_sized(int cpu, size_t num);

		[CCode(cname = "CPU_EQUAL")]
		public static bool equal(CpuSet cs1, CpuSet cs2);

		public bool is_equal(CpuSet cs) {
			return CpuSet.equal(this, cs);
		}

		[CCode(cname = "CPU_EQUAL_S", instance_pos = -1)]
		public static bool equal_sized(size_t num, CpuSet cs1, CpuSet cs2);

		public bool is_equal_sized(size_t num, CpuSet cs) {
			return CpuSet.equal_sized(num, this, cs);
		}

		[CCode(cname = "CPU_AND", instance_pos = -1)]
		public void and(CpuSet destset, CpuSet srcset);

		[CCode(cname = "CPU_AND_S", instance_pos = -1)]
		public void and_sized(size_t num, CpuSet destset, CpuSet srcset);

		[CCode(cname = "CPU_OR", instance_pos = -1)]
		public void or(CpuSet destset, CpuSet srcset);

		[CCode(cname = "CPU_OR_S", instance_pos = -1)]
		public void or_sized(size_t num, CpuSet destset, CpuSet srcset);

		[CCode(cname = "CPU_XOR", instance_pos = -1)]
		public void xor(CpuSet destset, CpuSet srcset);

		[CCode(cname = "CPU_XOR_S", instance_pos = -1)]
		public void xor_sized(size_t num, CpuSet destset, CpuSet srcset);

		[CCode(cname = "sched_setaffinity", instance_pos = -1)]
		public int setaffinity(size_t num, [CCode(pos = 0)]Posix.pid_t pid = 0);

		[CCode(cname = "sched_getaffinity", instance_pos = -1)]
		public int getaffinity(size_t num, [CCode(pos = 0)]Posix.pid_t pid = 0);

		public static CpuSet init(int num = 1) {
			CpuSet cpus = new CpuSet(num);
			var size = CpuSet.alloc_size(num);
			cpus.zero_sized(size);
			return cpus;
		}
	}

	[CCode (has_target = false)]
	public delegate int GlobErrorFunction (string filename, int errcode);

	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_ERR;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_MARK;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_NOSORT;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_DOOFFS;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_NOCHECK;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_APPEND;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_NOESCAPE;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_PERIOD;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_MAGCHAR;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_ALTDIRFUNC;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_BRACE;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_NOMAGIC;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_TILDE;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_ONLYDIR;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_TILDE_CHECK;

	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_NOSPACE;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_ABORTED;
	[CCode (cheader_filename = "glob.h")]
	public const int GLOB_NOMATCH;

	[CCode (cheader_filename = "glob.h", cname = "glob_t", destroy_function = "globfree", has_type_id = false)]
	public struct Glob {
		[CCode (cname = "gl_pathc")]
		public size_t pathc;
		[CCode (cname = "gl_pathv", array_length = false, array_null_terminated = true)]
		public string[] pathv;
		[CCode (cname = "gl_offs")]
		public size_t offs;

		[CCode (cname = "glob", instance_pos = -1)]
		public int glob (string pattern, int flags = 0, GlobErrorFunction? errfunc = null);
	}

	[CCode (cheader_filename = "langinfo.h", cname = "nl_item", cprefix = "", has_type_id = false)]
	public enum NLItem {
		ABDAY_1,
		ABDAY_2,
		ABDAY_3,
		ABDAY_4,
		ABDAY_5,
		ABDAY_6,
		ABDAY_7,
		DAY_1,
		DAY_2,
		DAY_3,
		DAY_4,
		DAY_5,
		DAY_6,
		DAY_7,
		ABMON_1,
		ABMON_2,
		ABMON_3,
		ABMON_4,
		ABMON_5,
		ABMON_6,
		ABMON_7,
		ABMON_8,
		ABMON_9,
		ABMON_10,
		ABMON_11,
		ABMON_12,
		MON_1,
		MON_2,
		MON_3,
		MON_4,
		MON_5,
		MON_6,
		MON_7,
		MON_8,
		MON_9,
		MON_10,
		MON_11,
		MON_12,
		AM_STR,
		PM_STR,
		D_T_FMT,
		D_FMT,
		T_FMT,
		T_FMT_AMPM,
		ERA,
		ERA_D_FMT,
		ALT_DIGITS,
		ERA_D_T_FMT,
		ERA_T_FMT,
		CODESET,
		CRNCYSTR,
		RADIXCHAR,
		THOUSEP,
		YESEXPR,
		NOEXPR;
		[CCode (cheader_filename = "langinfo.h", cname = "nl_langinfo")]
		public unowned string to_string ();
	}

	[CCode (cheader_filename = "langinfo.h", cname = "nl_item", cprefix = "_NL_TIME_", has_type_id = false)]
	public enum NLTime {
		WEEK_NDAYS,
		WEEK_1STDAY,
		WEEK_1STWEEK,
		FIRST_WEEKDAY,
		FIRST_WORKDAY,
		CAL_DIRECTION,
		TIMEZONE;
		[CCode (cheader_filename = "langinfo.h", cname = "nl_langinfo")]
		public unowned string to_string ();
	}

	[CCode (cheader_filename = "langinfo.h")]
	public unowned string nl_langinfo (NLItem item);

	[CCode (cheader_filename = "unistd.h")]
	public int getopt ([CCode (array_length_pos = 0)] string[] args, string optstring);
	[CCode (cheader_filename = "unistd.h")]
	public static string optarg;
	[CCode (cheader_filename = "unistd.h")]
	public static int optind;
	[CCode (cheader_filename = "unistd.h")]
	public static int opterr;
	[CCode (cheader_filename = "unistd.h")]
	public static int optopt;

	[CCode(cname = "wordexp_t", cheader_filename = "wordexp.h", destroy_function = "wordfree")]
	public struct Wordexp {
		[CCode(cname = "we_wordv", array_length_cname = "we_wordc", array_length_type = "size_t")]
		public string[] words;

		[CCode(cname = "wordexp", instance_pos = 1.1)]
		private int _wordexp (string s, int flags = 0);
		[CCode(cname = "wordfree")]
		private int _wordfree ();

		public int expand (string s, int flags = 0) {
			if (!(WRDE_APPEND in flags || WRDE_REUSE in flags)) {
				_wordfree();
			}
			return _wordexp (s, flags);
		}
		public int append(string s, int flags = 0) {
			return _wordexp (s, flags | WRDE_APPEND);
		}
	}

	[CCode(cheader_filename = "wordexp.h")]
	private const int WRDE_APPEND;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_BADCHAR;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_BADVAL;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_CMDSUB;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_NOCMD;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_NOSPACE;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_REUSE;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_SHOWERR;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_SYNTAX;
	[CCode(cheader_filename = "wordexp.h")]
	public const int WRDE_UNDEF;
}
