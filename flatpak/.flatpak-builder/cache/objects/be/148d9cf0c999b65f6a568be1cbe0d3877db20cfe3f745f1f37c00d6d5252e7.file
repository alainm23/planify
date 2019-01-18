/* bzlib.vapi
 *
 * Copyright (C) 2008 Maciej Piechotka
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
 * 	Maciej Piechotka <uzytkownik2@gmail.com>
 */

[CCode (cheader_filename = "bzlib.h")]
namespace BZLib {
	[CCode (cname = "int", cprefix = "BZ_", has_type_id = false)]
	public enum Action {
		RUN,
		FLUSH,
		FINISH
	}

	[CCode (cname = "int", cprefix = "BZ_", has_type_id = false)]
	public enum Status {
		OK,
		RUN_OK,
		FLUSH_OK,
		FINISH_OK,
		STREAM_END,
		SEQUENCE_ERROR,
		MEM_ERROR,
		DATA_ERROR,
		DATA_ERROR_MAGICK,
		IO_ERROR,
		UNEXPECTED_EOF,
		OUTBUFF_FULL,
		CONFIG_ERROR
	}

	[CCode (cname = "bz_stream", has_type_id = false)]
	public struct Stream {
		public string next_in;
		public uint avail_in;
		public uint totoal_in_lo32;
		public uint total_in_hi32;
		public string next_out;
		public uint avail_out;
		public uint totoal_out_lo32;
		public uint total_out_hi32;
		public void *state;
		public void *opaque;
		[CCode (cname = "BZ2_bzCompressInit")]
		public Status compress_init (int block_size_100k, int verbosity, int work_factor);
		[CCode (cname = "BZ2_bzCompress")]
		public Status compress (Action action);
		[CCode (cname = "BZ2_bzCompressEnd")]
		public Status compress_end ();
		[CCode (cname = "BZ2_bzDecompressInit")]
		public Status decompress_init (int verbosity, int small);
		[CCode (cname = "BZ2_bzDecompress")]
		public Status decompress ();
		[CCode (cname = "BZ2_bzDecompressEnd")]
		public Status decompress_end ();
	}

	[CCode (cname = "BZFILE", cprefix = "BZ2_bz", free_function = "BZ2_bzclose")]
	[Compact]
	public class BZFileStream {
		public static BZFileStream open (string path, string mode = "rb");
		public static BZFileStream dopen (int fd, string mode);
		public int read (uint8[] buf);
		public int write (uint8[] buf);
		public unowned string error (out Status status);
	}
}
