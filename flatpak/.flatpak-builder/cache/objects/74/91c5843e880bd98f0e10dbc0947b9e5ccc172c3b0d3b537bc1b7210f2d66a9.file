/* taglib_c.vapi
 *
 * Copyright (C) 2009 Andreas Brauchli
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
 * 	Andreas Brauchli <a.brauchli@elementarea.net>
 */

[CCode (cprefix = "TagLib_", lower_case_cprefix = "taglib_", cheader_filename = "tag_c.h")]
namespace TagLib
{
	public static void set_strings_unicode (bool unicode);
	/* TagLib can keep track of strings that are created when outputting tag values
	 * and clear them using taglib_tag_clear_strings().  This is enabled by default.
	 * However if you wish to do more fine grained management of strings, you can do
	 * so by setting a management to FALSE.
	 */
	public static void set_string_management_enabled (bool management);

	[CCode (free_function = "taglib_file_free")]
	[Compact]
	public class File
	{
		public File (string filename);
		public File.type (string filename, FileType type);

		public bool is_valid ();
		public unowned Tag tag {
			[CCode (cname = "taglib_file_tag")]
			get;
		}
		public unowned AudioProperties audioproperties {
			[CCode (cname = "taglib_file_audioproperties")]
			get;
		}
		public bool save ();
	}

	[CCode (free_function = "")]
	[Compact]
	public class Tag
	{
		public unowned string title {
			[CCode (cname = "taglib_tag_title")]
			get;
			set;
		}
		public unowned string artist {
			[CCode (cname = "taglib_tag_artist")]
			get;
			set;
		}
		public unowned string album {
			[CCode (cname = "taglib_tag_album")]
			get;
			set;
		}
		public unowned string comment {
			[CCode (cname = "taglib_tag_comment")]
			get;
			set;
		}
		public unowned string genre {
			[CCode (cname = "taglib_tag_genre")]
			get;
			set;
		}
		public uint year {
			[CCode (cname = "taglib_tag_year")]
			get;
			set;
		}
		public uint track {
			[CCode (cname = "taglib_tag_track")]
			get;
			set;
		}

		public static void free_strings ();
	}

	[CCode (free_function = "", cname = "TagLib_AudioProperties")]
	[Compact]
	[Immutable]
	public class AudioProperties
	{
		public int length {
			[CCode (cname = "taglib_audioproperties_length")]
			get;
		}
		public int bitrate {
			[CCode (cname = "taglib_audioproperties_bitrate")]
			get;
		}
		public int samplerate {
			[CCode (cname = "taglib_audioproperties_samplerate")]
			get;
		}
		public int channels {
			[CCode (cname = "taglib_audioproperties_channels")]
			get;
		}
	}

	[CCode (cname = "TagLib_File_Type", cprefix = "TagLib_File_", has_type_id = false)]
	public enum FileType
	{
		MPEG,
		OggVorbis,
		FLAC,
		MPC,
		OggFlac,
		WavPack,
		Speex,
		TrueAudio
	}

	namespace ID3v2 {
		[CCode (cname = "taglib_id3v2_set_default_text_encoding")]
		public void set_default_text_encoding (Encoding encoding);

		[CCode (cname = "TagLib_ID3v2_Encoding", cprefix = "TagLib_ID3v2_", has_type_id = false)]
		public enum Encoding {
			Latin1,
			UTF16,
			UTF16BE,
			UTF8
		}
	}
}

