/* zlib.vala
 *
 * Copyright (C) 2006-2009  Raffaele Sandrini, Jürg Billeter, Evan Nemerson
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
 *	Raffaele Sandrini <raffaele@sandrini.ch>
 * 	Jürg Billeter <j@bitron.ch>
 * 	Evan Nemerson <evan@polussystems.com>
 * 	Jörn Magens <joernmagens@gmx.de>
 */

using GLib;

[CCode (lower_case_cprefix = "", cheader_filename = "zlib.h")]
namespace ZLib {
	[CCode (cname="int", cprefix="Z_", has_type_id = false)]
	public enum Flush {
		NO_FLUSH,
		SYNC_FLUSH,
		FULL_FLUSH,
		FINISH,
		BLOCK
	}
	[CCode (cname="int", cprefix="Z_", has_type_id = false)]
	public enum Status {
		OK,
		STREAM_END,
		NEED_DICT,
		ERRNO,
		STREAM_ERROR,
		DATA_ERROR,
		MEM_ERROR,
		BUF_ERROR,
		VERSION_ERROR
	}
	[CCode (cname="int", cprefix="Z_", has_type_id = false)]
	public enum Level {
		NO_COMPRESSION,
		BEST_SPEED,
		BEST_COMPRESSION,
		DEFAULT_COMPRESSION
	}
	[CCode (cname="int", cprefix="Z_", has_type_id = false)]
	public enum Strategy {
		DEFAULT_STRATEGY,
		FILTERED,
		HUFFMAN_ONLY,
		RLE,
		FIXED
	}
	[CCode (cname="int", cprefix="Z_", has_type_id = false)]
	public enum Data {
		BINARY,
		ASCII,
		UNKNOWN
	}
	[CCode (cname="int", cprefix="Z_", has_type_id = false)]
	public enum Algorithm {
		DEFLATED
	}
	[CCode (cname="int", cprefix="Z_", has_type_id = false)]
	public enum Initial {
		NULL
	}
	namespace VERSION {
		[CCode (cname = "ZLIB_VERSION")]
		public const string STRING;
		[CCode (cname = "ZLIB_VERNUM")]
		public const int NUMBER;
		[CCode (cname = "ZLIB_VER_MAJOR")]
		public const int MAJOR;
		[CCode (cname = "ZLIB_VER_MINOR")]
		public const int MINOR;
		[CCode (cname = "ZLIB_VER_REVISION")]
		public const int REVISION;
	}
	[CCode (cname = "z_stream", destroy_function = "deflateEnd", has_type_id = false)]
	public struct Stream {
		[CCode (array_length_cname = "avail_in", array_length_type = "ulong")]
		public unowned uint8[] next_in;
		public uint avail_in;
		public ulong total_in;

		[CCode (array_length_cname = "avail_out", array_length_type = "ulong")]
		public unowned uint8[] next_out;
		public uint avail_out;
		public ulong total_out;

		public string? msg;
		public int data_type;
		public ulong adler;
	}
	[CCode (cname = "z_stream", destroy_function = "deflateEnd", has_type_id = false)]
	public struct DeflateStream : Stream {
		[CCode (cname = "deflateInit")]
		public DeflateStream (int level = Level.DEFAULT_COMPRESSION);
		[CCode (cname = "deflateInit2")]
		public DeflateStream.full (int level = Level.DEFAULT_COMPRESSION, int method = Algorithm.DEFLATED, int windowBits = 15, int memLevel = 8, int strategy = Strategy.DEFAULT_STRATEGY);
		[CCode (cname = "deflate")]
		public int deflate (int flush);
		[CCode (cname = "deflateSetDictionary")]
		public int set_dictionary ([CCode (array_length_type = "guint")] uint8[] dictionary);
		[CCode (cname = "deflateCopy", instance_pos = 0)]
		public int copy (DeflateStream dest);
		[CCode (cname = "deflateReset")]
		public int reset ();
		[CCode (cname = "deflateParams")]
		public int params (int level, int strategy);
		[CCode (cname = "deflateTune")]
		public int tune (int good_length, int max_lazy, int nice_length, int max_chain);
		[CCode (cname = "deflateBound")]
		public ulong bound (ulong sourceLen);
		[CCode (cname = "deflatePrime")]
		public int prime (int bits, int value);
		[CCode (cname = "deflateSetHeader")]
		public int set_header (GZHeader head);
	}
	[CCode (cname = "z_stream", destroy_function = "inflateEnd", has_type_id = false)]
	public struct InflateStream : Stream {
		[CCode (cname = "inflateInit")]
		public InflateStream ();
		[CCode (cname = "inflateInit2")]
		public InflateStream.full (int windowBits);
		[CCode (cname = "inflate")]
		public int inflate (int flush);
		[CCode (cname = "inflateSetDictionary")]
		public int set_dictionary ([CCode (array_length_type = "guint")] uint8[] dictionary);
		[CCode (cnmae = "inflateSync")]
		public int sync ();
		public int reset ();
		public int prime (int bits, int value);
		public int get_header (out GZHeader head);
	}
	[CCode (lower_case_cprefix = "", cheader_filename = "zlib.h")]
	namespace Utility {
		[CCode (cname = "compress2")]
		public static int compress ([CCode (array_length = false)] uint8[] dest, ref ulong dest_length, [CCode (array_length_type = "gulong")] uint8[] source, int level = Level.DEFAULT_COMPRESSION);
		[CCode (cname = "compressBound")]
		public static int compress_bound (ulong sourceLen);
		public static int uncompress ([CCode (array_length = false)] uint8[] dest, ref ulong dest_length, [CCode (array_length_type = "gulong")] uint8[] source);
		public static ulong adler32 (ulong crc = 0UL, [CCode (array_length_type = "guint")] uint8[]? buf = null);
		public static ulong crc32 (ulong crc = 0UL, [CCode (array_length_type = "guint")] uint8[]? buf = null);
	}
	[CCode (cname = "gz_header", has_type_id = false)]
	public struct GZHeader {
		public int text;
		public ulong time;
		public int xflags;
		public int os;
		[CCode (array_length_cname = "extra_len", array_length_type = "guint")]
		public uint8[] extra;
		public uint extra_max;
		public string? name;
		public uint name_max;
		public string comment;
		[CCode (cname = "comm_max")]
		public uint comment_max;
		public int hcrc;
		public int done;
	}
	[CCode (cname = "gzFile", cprefix = "gz", free_function = "gzclose")]
	[Compact]
	public class GZFileStream {
		public static GZFileStream open (string path, string mode = "rb");
		public static GZFileStream dopen (int fd, string mode);
		public int setparams (int level, int strategy);
		public int read (uint8[] buf);
		public int write (uint8[] buf);
		[PrintfFormat]
		public int printf (string format, ...);
		public int puts (string s);
		public unowned string gets (char[] buf);
		public int flush (int flush);
		public int rewind ();
		public bool eof ();
		public bool direct ();
	}
}

