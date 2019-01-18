[CCode (cheader_filename = "magic.h")]
namespace LibMagic {
	[Compact]
	[CCode (cname = "struct magic_set", cprefix = "magic_", free_function = "magic_close")]
	public class Magic {
		[CCode (cname = "magic_open")]
		public Magic (Flags flags = Flags.NONE);
		public unowned string? error ();
		public int errno ();
		public unowned string? file (string filename);
		public unowned string? buffer (void *buffer, size_t length);
		public int setflags (int flags);
		public int check (string? filename = null);
		public int compile (string? filename = null);
		public int load (string? filename = null);
	}

	[Flags]
	[CCode (cprefix = "MAGIC_", cname = "int", has_type_id = false)]
	public enum Flags {
		NONE,
		DEBUG,
		SYMLINK,
		COMPRESS,
		DEVICES,
		MIME_TYPE,
		MIME_ENCODING,
		CONTINUE,
		CHECK,
		PRESERVE_ATIME,
		RAW,
		ERROR,
		NO_CHECK_ATYPE,
		NO_CHECK_ASCII,
		NO_CHECK_COMPRESS,
		NO_CHECK_ELF,
		NO_CHECK_FORTRAN,
		NO_CHECK_SOFT,
		NO_CHECK_TAR,
		NO_CHECK_TOKENS,
		NO_CHECK_TROFF
	}
}
