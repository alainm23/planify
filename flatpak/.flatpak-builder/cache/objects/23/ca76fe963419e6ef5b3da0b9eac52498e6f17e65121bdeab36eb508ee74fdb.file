/* tokyocabinet.vala
 *
 * Copyright (C) 2008-2010  Evan Nemerson
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
 *      Evan Nemerson <evan@coeus-group.com>
 */

namespace TokyoCabinet {
	[CCode (cname = "tcversion")]
	public const string version;

	[CCode (cname = "tcfatalfunc")]
	public delegate void FatalFunc (string msg);
	[CCode (cname = "TCCMP")]
	public delegate int CompareFunc (uint8[] a, uint8[] b);
	[CCode (cname = "TCCODEC")]
	public delegate uint8[] CodecFunc (uint8[] data);
	[CCode (cname = "TCPDPROC")]
	public delegate uint8[] ProcessDuplicateFunc (uint8[] value);
	[CCode (cname = "TCITER")]
	public delegate bool IteratorFunc (uint8[] key, uint8[] data);

	[CCode (lower_case_cprefix = "tc", cheader_filename = "tcutil.h")]
	namespace Memory {
		public static void* malloc (size_t size);
		public static void* calloc (size_t nmemb, size_t size);
		public static void* realloc (void *ptr, size_t size);
		[CCode (cname = "tcmemdup")]
		public static void* copy (void *ptr, size_t size);
		public static string strdup (string str);
		public static void free ([CCode (type = "void*")] void* ptr);

		public static uint8[]? copy_and_free (uint8[]? data) {
			if ( data == null )
				return null;

			uint8[] ret = new uint8[data.length];
			GLib.Memory.copy (ret, data, data.length);
			TokyoCabinet.Memory.free (data);
			return ret;
		}
		public static string? copy_and_free_string (string? str) {
			if ( str == null )
				return null;

			string ret = str;
			TokyoCabinet.Memory.free (str);
			return ret;
		}
	}

	[Compact, CCode (cname = "TCXSTR", cprefix = "tcxstr", free_function = "tcxstrdel", cheader_filename = "tcutil.h", copy_function = "tcxstrdup")]
	public class XString {
		public XString ();
		[CCode (cname = "tcxstrnew2")]
		public XString.from_string (string str);
		[CCode (cname = "tcxstrnew3")]
		public XString.sized (int asiz);
		[CCode (cname = "tcxstrdup")]
		public XString copy ();
		[CCode (cname = "tcxstrcat")]
		public void append (uint8[] data);
		[CCode (cname = "tcxstrcat2")]
		public void append_string (string str);
		public void clear ();
		[PrintfFormat ()]
		public void printf (string format, ...);

		[CCode (cname = "ptr", array_length_cname = "size")]
		public uint8[] data;
		[CCode (cname = "ptr")]
		public string str;
		[CCode (cname = "asize")]
		public int allocated;
	}

	[Compact, CCode (cname = "TCLIST", cprefix = "tclist", free_function = "tclistdel", cheader_filename = "tcutil.h", copy_function = "tclistdup")]
	public class List {
		[CCode (has_target = false)]
		public delegate int CompareDatumFunc (TokyoCabinet.List.Datum a, TokyoCabinet.List.Datum b);

		[CCode (cname = "TCLISTDATUM", has_type_id = false)]
		public struct Datum {
			[CCode (cname = "ptr", array_length_cname = "size")]
			public uint8[] data;
			[CCode (cname = "ptr")]
			public string str;
		}

		public List ();
		[CCode (cname = "tclistnew3")]
		public List.from_strings (string s1, ...);
		[CCode (cname = "tclistnew2")]
		public List.sized (int anum);
		[CCode (cname = "tclistdup")]
		public List copy ();
		[CCode (cname = "tclistval")]
		public unowned uint8[]? index (int index);
		[CCode (cname = "tclistval2")]
		public unowned string? index_string (int index);
		public void push (uint8[] data);
		[CCode (cname = "tclistpush2")]
		public void push_string (string str);
		[CCode (cname = "tclistpop")]
		public unowned uint8[] _pop ();
		[CCode (cname = "_vala_tclistpop")]
		public uint8[] pop () {
			return TokyoCabinet.Memory.copy_and_free (this._pop ());
		}
		[CCode (cname = "tclistpop2")]
		public unowned string _pop_string ();
		[CCode (cname = "_vala_tclistpop2")]
		public string pop_string () {
			return TokyoCabinet.Memory.copy_and_free_string (this._pop_string ());
		}
		public void unshift (uint8[] data);
		[CCode (cname = "tclistunshift2")]
		public void unshift_string (string str);
		[CCode (cname = "tclistshift")]
		public unowned uint8[] _shift ();
		[CCode (cname = "_vala_tclistshift")]
		public uint8[] shift () {
			return TokyoCabinet.Memory.copy_and_free (this._shift ());
		}
		[CCode (cname = "tclistshift2")]
		public unowned string _shift_string ();
		[CCode (cname = "_vala_tclistshift2")]
		public string shift_string () {
			return TokyoCabinet.Memory.copy_and_free_string (this._shift_string ());
		}
		public void insert (int index, uint8[] data);
		[CCode (cname = "tclistinsert2")]
		public void insert_string (int index, string str);
		[CCode (cname = "tclistremove")]
		public unowned uint8[] _remove (int index);
		[CCode (cname = "_vala_tclistremove")]
		public uint8[] remove (int index) {
			return TokyoCabinet.Memory.copy_and_free (this._remove (index));
		}
		[CCode (cname = "tclistremove2")]
		public unowned string _remove_string (int index);
		[CCode (cname = "_vala_tclistremove2")]
		public string remove_string (int index) {
			return TokyoCabinet.Memory.copy_and_free_string (this._remove_string (index));
		}
		[CCode (cname = "tclistover")]
		public void replace (int index, uint8[] data);
		[CCode (cname = "tclistover2")]
		public void replace_string (int index, string str);
		[CCode (cname = "tclistsort")]
		public void sort_sensitive ();
		[CCode (cname = "tclistsortci")]
		public void sort_insensitive ();
		public void sort (TokyoCabinet.List.CompareDatumFunc func);
		[CCode (cname = "tclistlsearch")]
		public int linear_search (uint8[] ptr);
		[CCode (cname = "tclistbsearch")]
		public int binary_search (uint8[] ptr);
		public void clear ();
		[CCode (cname = "tclistdump")]
		public unowned uint8[] _dump ();
		[CCode (cname = "_vala_tclistdump")]
		public uint8[] dump () {
			return TokyoCabinet.Memory.copy_and_free (this._dump ());
		}
		public List.load (uint8[] ptr);
		[CCode (cname = "tclistinvert")]
		public void reverse ();
		[PrintfFormat]
		public void push_printf (string fmt, ...);

		[CCode (array_length_cname = "anum")]
		public TokyoCabinet.List.Datum[] array;
		public int start;
		[CCode (cname = "num")]
		public int num_used;
	}

	[Compact, CCode (cname = "TCMAPREC")]
	public class MapRecord {
		[CCode (cname = "ksiz")]
		public int32 key_size;
		[CCode (cname = "vsiz")]
		public int32 value_size;
		public TokyoCabinet.MapRecord left;
		public TokyoCabinet.MapRecord right;
		public TokyoCabinet.MapRecord prev;
		public TokyoCabinet.MapRecord next;
	}

	[Compact, CCode (cname = "TCMAP", cprefix = "tcmap", free_function = "tcmapdel", cheader_filename = "tcutil.h", copy_function = "tcmapdup")]
	public class Map {
		public Map ();
		[CCode (cname = "tcmapnew2")]
		public Map.sized (uint32 bnum);
		[CCode (cname = "tcmapnew3")]
		public Map.from_strings (string key1, string val1, ...);
		[CCode (cname = "tcmapload")]
		public Map.load (uint8[] ptr);
		[CCode (cname = "tcmapdup")]
		public Map copy ();
		[CCode (cname = "tcmapputkeep")]
		public void put (uint8[] key, uint8[] value);
		[CCode (cname = "tcmapputkeep2")]
		public void put_string (string key, string value);
		[CCode (cname = "tcmapput")]
		public bool replace (uint8[] key, uint8[] value);
		[CCode (cname = "tcmapput2")]
		public bool replace_string (string key, string value);
		[CCode (cname = "tcmapputcat")]
		public void append (uint8[] key, uint8[] value);
		[CCode (cname = "tcmapputcat2")]
		public void append_string (string key, string value);
		[CCode (cname = "tcmapout")]
		public bool remove (uint8[] key);
		[CCode (cname = "tcmapout2")]
		public bool remove_string (string key);
		[CCode (cname = "tcmapget")]
		public unowned uint8[]? get (uint8[] key);
		[CCode (cname = "tcmapget2")]
		public unowned string? get_string (string key);
		public bool move (uint8[] key, bool head = true);
		[CCode (cname = "tcmapmove2")]
		public bool move_string (string key, bool head = true);
		[CCode (cname = "tcmapiterinit")]
		public void iterator_init ();
		[CCode (cname = "tcmapiternext")]
		public unowned uint8[] iterator_next ();
		[CCode (cname = "tcmapiternext2")]
		public unowned string? iterator_next_string ();
		[CCode (cname = "tcmapiterval2")]
		public unowned string? iterator_value_string (string key);
		[CCode (cname = "tcmapiterval")]
		public unowned uint8[]? iterator_value (uint8[] key);
		public TokyoCabinet.List keys ();
		[CCode (cname = "tcmapvals")]
		public TokyoCabinet.List values ();
		[CCode (cname = "tcmapaddint")]
		public int add_int (uint8[] key, int num);
		[CCode (cname = "tcmapadddouble")]
		public double add_double (uint8[] key, double num);
		public void clear ();
		[CCode (cname = "tcmapcutfront")]
		public void cut_front (int num);
		[CCode (cname = "tcmapdump")]
		public unowned uint8[] _dump ();
		[CCode (cname = "_vala_tcmapdump")]
		public uint8[] dump () {
			return TokyoCabinet.Memory.copy_and_free (this._dump ());
		}

		[CCode (array_length_cname = "bnum", array_length_type = "guint32")]
		public TokyoCabinet.MapRecord[] buckets;
		public TokyoCabinet.MapRecord first;
		public TokyoCabinet.MapRecord last;
		public TokyoCabinet.MapRecord cur;
		[CCode (cname = "rnum")]
		public uint64 num_records;
		[CCode (cname = "msiz")]
		public uint64 size;
	}

	[Compact, CCode (cname = "TCTREE", cprefix = "tctree", free_function = "tctreedel", cheader_filename = "tcutil.h", copy_function = "tctreedup")]
	public class Tree {
		[CCode (cname = "TREECMP")]
		public delegate int Compare (uint8[] a, uint8[] b);

		[Compact, CCode (cname = "TCTREEREC")]
		public class Record {
			[CCode (cname = "ksiz")]
			public int32 key_size;
			[CCode (cname = "vsiz")]
			public int32 value_size;
			TokyoCabinet.Tree.Record left;
			TokyoCabinet.Tree.Record right;
		}

		[CCode (cname = "tctreecmplexical")]
		public static int compare_lexical (uint8[] a, uint8[] b);
		[CCode (cname = "tctreecmpdecimal")]
		public static int compare_decimal (uint8[] a, uint8[] b);
		[CCode (cname = "tctreecmpint32")]
		public static int compare_int32 (uint8[] a, uint8[] b);
		[CCode (cname = "tctreecmpint64")]
		public static int compare_int64 (uint8[] a, uint8[] b);

		[CCode (cname = "tctreenew2")]
		public Tree (TokyoCabinet.Tree.Compare cmp = TokyoCabinet.Tree.compare_lexical);
		public Tree.load (uint8[] data, TokyoCabinet.Tree.Compare cmp = TokyoCabinet.Tree.compare_lexical);
		[CCode (cname = "tctreedup")]
		public Tree copy ();
		[CCode (cname = "tctreeput")]
		public void replace (uint8[] key, uint8[] value);
		[CCode (cname = "tctreeput2")]
		public void replace_string (string key, string value);
		[CCode (cname = "tctreeputkeep")]
		public bool put (uint8[] key, uint8[] value);
		[CCode (cname = "tctreeputkeep2")]
		public bool put_string (string key, string value);
		[CCode (cname = "tctreeputcat")]
		public void append (uint8[] key, uint8[] value);
		[CCode (cname = "tctreeputcat2")]
		public void append_string (string key, string value);
		[CCode (cname = "tctreeout")]
		public bool remove (uint8[] key);
		[CCode (cname = "tctreeout2")]
		public bool remove_string (string key);
		[CCode (cname = "tctreeget")]
		public unowned uint8[]? get (uint8[] key);
		[CCode (cname = "tctreeget2")]
		public unowned string? get_string (string key);
		[CCode (cname = "tctreeiterinit")]
		public void iterator_init ();
		[CCode (cname = "tctreeiternext")]
		public unowned uint8[]? iterator_next ();
		[CCode (cname = "tctreeiternext2")]
		public unowned string? iterator_next_string ();
		[CCode (cname = "tctreeiterval")]
		public unowned uint8[]? iterator_value (uint8[] key);
		[CCode (cname = "tctreeiterval2")]
		public unowned string? iterator_value_string (string key);
		[CCode (cname = "tctreekeys")]
		public TokyoCabinet.List get_keys ();
		[CCode (cname = "tctreevals")]
		public TokyoCabinet.List get_values ();
		[CCode (cname = "tctreeaddint")]
		public int add_int (uint8[] key, int num);
		[CCode (cname = "tctreeadddouble")]
		public double add_double (uint8[] key, double num);
		public void clear ();
		[CCode (cname = "tctreedump")]
		public unowned uint8[] _dump ();
		[CCode (cname = "tctreedump")]
		public uint8[] dump () {
			return TokyoCabinet.Memory.copy_and_free (this._dump ());
		}

		public TokyoCabinet.Tree.Record root;
		public TokyoCabinet.Tree.Record cur;
		public uint64 rnum;
		public uint64 msiz;
		[CCode (delegate_target = false)]
		public TokyoCabinet.Tree.Compare cmp;
	}

	[Compact, CCode (cname = "TCMDB", cprefix = "tcmdb", free_function = "tctreedel", cheader_filename = "tcutil.h")]
	public class MDB {
		public MDB ();
		public MDB.with_num_buckets (uint32 bnum);
		public void replace (uint8[] key, uint8[] value);
		[CCode (cname = "tcmdbput2")]
		public void replace_string (string key, string value);
		[CCode (cname = "tcmdbputkeep")]
		public bool put (uint8[] key, uint8[] value);
		[CCode (cname = "tcmdbputkeep2")]
		public bool put_string (string key, string value);
		[CCode (cname = "tcmdbputcat")]
		public void append (uint8[] key, uint8[] value);
		[CCode (cname = "tcmdbputcat2")]
		public void append_string (string key, string value);
		[CCode (cname = "tcmdbout")]
		public bool remove (uint8[] key);
		[CCode (cname = "tcmdbout2")]
		public bool remove_string (string key);
		[CCode (cname = "tcmdbget2")]
		public unowned string? get_string (string key);
		[CCode (cname = "tcmdbget")]
		public unowned uint8[]? get (uint8[] key);
		[CCode (cname = "tcmdbvsiz")]
		public int value_size (uint8[] key);
		[CCode (cname = "tcmdbvsiz2")]
		public int value_size_string (string key);
		[CCode (cname = "tcmdbiterinit")]
		public void iterator_init ();
		[CCode (cname = "tcmdbiternext")]
		public uint8[]? iterator_next ();
		[CCode (cname = "tcmdbiternext2")]
		public unowned string? iterator_next_string ();
		[CCode (cname = "tcmdbfwmkeys")]
		public TokyoCabinet.List forward_matching_keys (uint8[] pbuf, int max);
		[CCode (cname = "tcmdbfwmkeys2")]
		public TokyoCabinet.List forward_matching_keys_string (string pstr, int max);
		[CCode (cname = "tcmdbrnum")]
		public uint64 get_length ();
		[CCode (cname = "tcmdbmsiz")]
		public uint64 get_size ();
		[CCode (cname = "tcmdbaddint")]
		public int add_int (uint8[] key, int num);
		[CCode (cname = "tcmdbadddouble")]
		public double add_double (uint8[] key, double num);
		[CCode (cname = "tcmdbvanish")]
		public void clear ();
		[CCode (cname = "tcmdbcutfront")]
		public void cut_front (int num);

		public uint64 length { get { return this.get_length (); } }
		public uint64 size { get { return this.get_size (); } }
	}

	[Compact, CCode (cname = "TCNDB", cprefix = "tcndb", free_function = "tcndbdel", cheader_filename = "tcutil.h")]
	public class NDB {
		[CCode (cname = "tcndbnew2")]
		public NDB (TokyoCabinet.BDB.Compare cmp = TokyoCabinet.Tree.compare_lexical, void * cmpop = null);
		public void replace (uint8[] key, uint8[] value);
		[CCode (cname = "tcndbput2")]
		public void replace_string (string key, string value);
		[CCode (cname = "tcndbputkeep")]
		public bool put (uint8[] key, uint8[] value);
		[CCode (cname = "tcndbputkeep2")]
		public bool put_string (string key, string value);
		[CCode (cname = "tcndbputcat")]
		public bool append (uint8[] key, uint8[] value);
		[CCode (cname = "tcndbputcat2")]
		public bool append_string (string key, string value);
		[CCode (cname = "tcndbout")]
		public bool remove (uint8[] key);
		[CCode (cname = "tcndbout2")]
		public bool remove_string (string key);
		[CCode (cname = "tcndbget")]
		private unowned uint8[]? _get (uint8[] key);
		[CCode (cname = "_vala_tcndbget")]
		public uint8[]? get (uint8[] key) {
			return TokyoCabinet.Memory.copy_and_free (this._get (key));
		}
		public string? get_string (string key) {
			unowned uint8[] kbuf = (uint8[]) key;
			kbuf.length = (int) key.size ();
			return (string) this.get (kbuf);
		}
		[CCode (cname = "tcndbvsiz")]
		public int value_size (uint8[] key);
		[CCode (cname = "tcndbvsiz2")]
		public int value_size_string (string key);
		[CCode (cname = "tcndbiterinit")]
		public void iterator_init ();
		[CCode (cname = "tcndbiterinit2")]
		public void iterator_init_before (uint8[] key);
		[CCode (cname = "tcndbiterinit3")]
		public void iterator_init_before_string (string key);
		[CCode (cname = "tcndbiternext")]
		public unowned uint8[]? _iterator_next ();
		public uint8[]? iterator_next () {
			return TokyoCabinet.Memory.copy_and_free (this._iterator_next ());
		}
		[CCode (cname = "tcndbiternext2")]
		public unowned string? _iterator_next_string ();
		public string? iterator_next_string () {
			return TokyoCabinet.Memory.copy_and_free_string (this._iterator_next_string ());
		}
		[CCode (cname = "tcndbfwmkeys")]
		public TokyoCabinet.List forward_matching_keys (uint8[] pbuf, int max);
		[CCode (cname = "tcndbfwnkeys2")]
		public TokyoCabinet.List forward_matching_keys_string (string pstr, int max);
		[CCode (cname = "tcndbrnum")]
		public uint64 get_length ();
		[CCode (cname = "tcndbmsiz")]
		public uint64 get_size ();
		[CCode (cname = "tcndbaddint")]
		public int add_int (uint8[] key, int num);
		[CCode (cname = "tcndbadddouble")]
		public double add_double (uint8[] key, double num);
		[CCode (cname = "tcndbvanish")]
		public void clear ();
		[CCode (cname = "tcndbcutfringe")]
		public void cut_fringe (int num);

		public uint64 length { get { return this.get_length (); } }
		public uint64 size { get { return this.get_size (); } }
	}

	[CCode (cname = "int", cprefix = "TCE", cheader_filename = "tchdb.h", has_type_id = false)]
	public enum ErrorCode {
		SUCCESS,
		THREAD,
		INVALID,
		NOFILE,
		NOPERM,
		META,
		RHEAD,
		OPEN,
		CLOSE,
		TRUNC,
		SYNC,
		STAT,
		SEEK,
		READ,
		WRITE,
		MMAP,
		LOCK,
		UNLINK,
		RENAME,
		MKDIR,
		RMDIR,
		KEEP,
		NOREC,
		MISC
	}

	[Compact, CCode (cname = "TCHDB", cprefix = "tchdb", free_function = "tchdbdel", cheader_filename = "tchdb.h")]
	public class HDB {
		[Flags, CCode (cname = "uint8_t", cprefix = "HDBT", cheader_filename = "tchdb.h", has_type_id = false)]
		public enum TuningOption {
			LARGE,
			DEFLATE,
			BZIP,
			TCBS,
			EXCODEC
		}

		[Flags, CCode (cname = "uint8_t", cprefix = "HDBO", cheader_filename = "tchdb.h", has_type_id = false)]
		public enum OpenMode {
			READER,
			WRITER,
			CREAT,
			TRUNC,
			NOLCK,
			LCKNB,
			TSYNC
		}

		[CCode (cname = "tchdberrstr")]
		public static unowned string get_error_message (TokyoCabinet.ErrorCode ecode);
		public HDB ();
		[CCode (cname = "tchdberrcode")]
		public TokyoCabinet.ErrorCode get_error_code ();
		[CCode (cname = "tchdbsetmutex")]
		public bool set_mutex ();
		[CCode (cname = "tchdbtune")]
		public bool tune (int64 bnum, int8 apow, int8 fpow, TokyoCabinet.HDB.TuningOption opts);
		[CCode (cname = "tchdbsetcache")]
		public bool set_cache (int32 rcnum);
		[CCode (cname = "tchdbsetxmsiz")]
		public bool setxmsiz (int64 xmsiz);
		[CCode (cname = "tchdbopen")]
		public bool open (string path, TokyoCabinet.HDB.OpenMode omode);
		[CCode (cname = "tchdbclose")]
		public bool close ();
		[CCode (cname = "tchdbput")]
		public bool replace (uint8[] key, uint8[] value);
		[CCode (cname = "tchdbput2")]
		public bool replace_string (string key, string value);
		[CCode (cname = "tchdbputkeep")]
		public bool put (uint8[] key, uint8[] value);
		[CCode (cname = "tchdbputkeep2")]
		public bool put_string (string key, string value);
		[CCode (cname = "tchdbputcat")]
		public bool append (uint8[] key, uint8[] value);
		[CCode (cname = "tchdbputcat2")]
		public bool append_string (string key, string value);
		[CCode (cname = "tchdbputasync")]
		public bool replace_async (uint8[] key, uint8[] ksiz);
		[CCode (cname = "tchdbputasync2")]
		public bool replace_async_string (string key, string value);
		[CCode (cname = "tchdbout")]
		public bool remove (uint8[] key);
		[CCode (cname = "tchdbout2")]
		public bool remove_string (string key);
		[CCode (cname = "tchdbget3")]
		public int _get (uint8[] kbuf, uint8[] vbuf);
		[CCode (cname = "_vala_tchdbget")]
		public uint8[]? get (uint8[] key) {
			int vsiz = this.value_size (key);
			if ( vsiz < 0 )
				return null;

			var vbuf = new uint8[vsiz];
			this._get (key, vbuf);
			return vbuf;
		}
		[CCode (cname = "_vala_tchdbget2")]
		public string? get_string (string key) {
			unowned uint8[] kbuf = (uint8[]) key;
			kbuf.length = (int) key.size ();
			return (string) this.get (kbuf);
		}
		[CCode (cname = "tchdbvsiz")]
		public int value_size (uint8[] key);
		[CCode (cname = "tchdbvsiz2")]
		public int value_size_string (string key);
		[CCode (cname = "tchdbfwmkeys")]
		public TokyoCabinet.List forward_matching_keys (uint8[] pbuf, int max);
		[CCode (cname = "tchdbfwmkeys2")]
		public TokyoCabinet.List forward_matching_keys_string (string pstr, int max);
		[CCode (cname = "tchdbaddint")]
		public int add_int (uint8[] key, int num);
		[CCode (cname = "tchdbadddouble")]
		public double add_double (uint8[] key, double num);
		[CCode (cname = "tchdbsync")]
		public bool sync ();
		[CCode (cname = "tchdboptimize")]
		public bool optimize (int64 bnum, int8 apow, int8 fpow, TuningOption opts);
		[CCode (cname = "tchdbvanish")]
		public bool clear ();
		[CCode (cname = "tchdbcopy")]
		public bool copy (string path);
		[CCode (cname = "tchdbpath")]
		public unowned string path ();
		[CCode (cname = "tchdbrnum")]
		public uint64 get_length ();
		[CCode (cname = "tchdbfsiz")]
		public uint64 get_size ();

		public uint64 length { get { return this.get_length (); } }
		public uint64 size { get { return this.get_size (); } }
	}

	[Compact, CCode (cname = "TCBDB", cprefix = "tcbdb", free_function = "tcbdbdel", cheader_filename = "tcbdb.h")]
	public class BDB {
		[CCode (cname = "BDBCMP")]
		public delegate int Compare (uint8[] a, uint8[] b);

		[Compact, CCode (cname = "BDBCUR", cprefix = "tcbdbcur", free_function = "tcbdbcurdel", cheader_filename = "tcbdb.h")]
		public class Cursor {
			[CCode (cname = "int", cprefix = "BDBCP", has_type_id = false)]
			public enum PutMode {
				CURRENT,
				BEFORE,
				AFTER
			}

			[CCode (cname = "tcbdbcurnew")]
			public Cursor (TokyoCabinet.BDB bdb);
			public bool first ();
			public bool last ();
			public bool jump (uint8[] key);
			[CCode (cname = "tcbdbcurjump2")]
			public bool jump_string (string key);
			[CCode (cname = "tcbdbcurprev")]
			public bool previous ();
			public bool next ();
			public bool put (uint8[] value, TokyoCabinet.BDB.Cursor.PutMode cpmode);
			[CCode (cname = "tcbdbput2")]
			public bool put_string (string value, TokyoCabinet.BDB.Cursor.PutMode cpmode);
			[CCode (cname = "tcbdbcurout")]
			public bool remove ();
			[CCode (cname = "tcbdbcurkey3")]
			public unowned uint8[]? key ();
			[CCode (cname = "_vala_tcbdbcurkey2")]
			public unowned string? key_string () {
				return (string) this.key ();
			}
			[CCode (cname = "tcbdbcurval3")]
			public unowned uint8[]? value ();
			[CCode (cname = "_vala_tcbdbcurval2")]
			public unowned string? value_string () {
				return (string) this.value ();
			}
			[CCode (cname = "tcbdbcurrec")]
			public bool record (TokyoCabinet.XString kxstr, TokyoCabinet.XString vxstr);
		}

		[Flags, CCode (cname = "int", cprefix = "BDBO", cheader_filename = "tcbdb.h", has_type_id = false)]
		public enum OpenMode {
			READER,
			WRITER,
			CREAT,
			TRUNC,
			NOLCK,
			LCKNB
		}

		[Flags, CCode (cname = "uint8_t", cprefix = "BDBT", cheader_filename = "tcbdb.h", has_type_id = false)]
		public enum TuningOption {
			LARGE,
			DEFLATE,
			BZIP,
			TCBS,
			EXCODEC
		}

		[CCode (cname = "tcbdberrmsg")]
		public static unowned string get_error_message (TokyoCabinet.ErrorCode ecode);
		public BDB ();
		[CCode (cname = "tcbdbecode")]
		public TokyoCabinet.ErrorCode get_error_code ();
		[CCode (cname = "tcbdbsetmutex")]
		public bool set_mutex ();
		[CCode (cname = "tcbdbsetcmpfunc")]
		public bool set_compare_func (TokyoCabinet.BDB.Compare cmp);
		[CCode (cname = "tcbdbtune")]
		public bool tune (int32 lmemb, int32 nmemb, int64 bnum, int8 apow, int8 fpow, TokyoCabinet.BDB.TuningOption opts);
		[CCode (cname = "tcbdbsetxmsiz")]
		public bool set_extra_mapped_size (int64 xmsiz);
		[CCode (cname = "tcbdbopen")]
		public bool open (string path, TokyoCabinet.BDB.OpenMode mode = TokyoCabinet.BDB.OpenMode.READER | TokyoCabinet.BDB.OpenMode.WRITER | TokyoCabinet.BDB.OpenMode.CREAT);
		[CCode (cname = "tcbdbclose")]
		public bool close ();
		[CCode (cname = "tcbdbput")]
		public bool replace (uint8[] key, uint8[] value);
		[CCode (cname = "tcbdbput2")]
		public bool replace_string (string key, string value);
		[CCode (cname = "tcbdbputkeep")]
		public bool put (uint8[] key, uint8[] value);
		[CCode (cname = "tcbdbputkeep2")]
		public bool put_string (string key, string value);
		[CCode (cname = "tcbdbputcat")]
		public bool append (uint8[] key, uint8[] value);
		[CCode (cname = "tcbdbputcat2")]
		public bool append_string (string key, string value);
		[CCode (cname = "tcbdbputdup")]
		public bool put_duplicate (uint8[] key, uint8[] value);
		[CCode (cname = "tcbdbputdup2")]
		public bool put_duplicate_string (string key, string value);
		[CCode (cname = "tcbdbout")]
		public bool remove (uint8[] key);
		[CCode (cname = "tcbdbout2")]
		public bool remove_string (string key);
		[CCode (cname = "tcbdbget3")]
		private unowned uint8[]? _get (uint8[] key);
		[CCode (cname = "tcbdbsetdfunit")]
		public bool set_defragment_unit (int32 dfunit);
		[CCode (cname = "_vala_tcbdbget")]
		public uint8[]? get (uint8[] key) {
			return this._get (key);
		}
		public string? get_string (string key) {
			unowned uint8[] k = (uint8[]) key;
			k.length = (int) key.size ();
			return (string) this._get (k);
		}
		[CCode (cname = "tcbdbget4")]
		public TokyoCabinet.List get_list (uint8[] key);
		[CCode (cname = "tcbdbvnum")]
		public int value_count (uint8[] key);
		[CCode (cname = "tcbdbvnum2")]
		public int value_count_string (string key);
		[CCode (cname = "tcbdbvsiz")]
		public int value_size (uint8[] key);
		[CCode (cname = "tcbdbvsiz2")]
		public int value_size_string (string key);
		[CCode (cname = "tcbdbrange")]
		public TokyoCabinet.List range (uint8[] bkey, bool binc, uint8[] ekey, bool einc, int max);
		[CCode (cname = "tcbdbrange2")]
		public TokyoCabinet.List range_string (string bkey, bool binc, string ekey, bool einc, int max);
		[CCode (cname = "tcbdbfwmkeys")]
		public TokyoCabinet.List forward_matching_keys (uint8[] pbuf, int max);
		[CCode (cname = "tcbdbfwmkeys2")]
		public TokyoCabinet.List forward_matching_keys_string (string pstr, int max);
		[CCode (cname = "tcbdbaddint")]
		public int add_int (uint8[] key, int num);
		[CCode (cname = "tcbdbadddouble")]
		public double add_double (uint8[] key, double num);
		[CCode (cname = "tcbdbsync")]
		public bool sync ();
		[CCode (cname = "tcbdboptimize")]
		public bool optimize (int32 lmemb, int32 nmemb, int64 bnum, int8 apow, int8 fpow, TuningOption opts);
		[CCode (cname = "tcbdbvanish")]
		public bool clear ();
		[CCode (cname = "tcbdbcopy")]
		public bool copy (string path);
		[CCode (cname = "tcbdbtranbegin")]
		public bool transaction_begin ();
		[CCode (cname = "tcbdbtrancommit")]
		public bool transaction_commit ();
		[CCode (cname = "tcbdbtranabort")]
		public bool transaction_abort ();
		[CCode (cname = "tcbdbpath")]
		public unowned string path ();
		[CCode (cname = "tcbdbrnum")]
		public uint64 get_length ();
		[CCode (cname = "tcbdbfsiz")]
		public uint64 get_size ();
		[CCode (cname = "tcbdbcurnew")]
		public BDB.Cursor iterator ();

		public uint64 length { get { return this.get_length (); } }
		public uint64 size { get { return this.get_size (); } }
	}

	[Compact, CCode (cname = "TCFDB", cprefix = "tcfdb", free_function = "tcfdbdel", cheader_filename = "tcfdb.h")]
	public class FDB {
		[CCode (cname = "FDBIDMIN")]
		public const int IDMIN;
		[CCode (cname = "FDBIDMAX")]
		public const int IDMAX;
		[CCode (cname = "FDBIDPREV")]
		public const int IDPREV;
		[CCode (cname = "FDBIDNEXT")]
		public const int IDNEXT;

		[CCode (cname = "tcfdberrmsg")]
		public unowned string get_error_message (TokyoCabinet.ErrorCode ecode);
		[CCode (cname = "tcfdbnew")]
		public FDB ();
		[CCode (cname = "tcfdbecode")]
		public TokyoCabinet.ErrorCode get_error_code ();
		[CCode (cname = "tcfdbsetmutex")]
		public bool set_mutex ();
		[CCode (cname = "tcfdbtune")]
		public bool tune (int32 width = 0, int64 limsiz = 0);
		[CCode (cname = "tcfdbclose")]
		public bool close ();
		[CCode (cname = "tcfdbput")]
		public bool replace (int64 id, uint8[] value);
		[CCode (cname = "tcfdbputkeep")]
		public bool put (int64 id, uint8[] value);
		[CCode (cname = "tcfdbputcat")]
		public bool append (int64 id, uint8[] value);
		[CCode (cname = "tcfdbout")]
		public bool remove (int64 id);
		[CCode (cname = "tcfdbget4")]
		public int _get (int64 id, uint8[] value);
		[CCode (cname = "_vala_tcfdbget")]
		public uint8[]? get (int64 id) {
			var vsiz = this.get_value_size (id);
			if ( vsiz < 0 )
				return null;

			var vbuf = new uint8[vsiz];
			this._get (id, vbuf);
			return vbuf;
		}
		[CCode (cname = "tcfdbvsiz")]
		public int get_value_size (int64 id);
		[CCode (cname = "tcfdbiterinit")]
		public bool iterator_init ();
		[CCode (cname = "tcfdbiternext")]
		public uint64 iterator_next ();
		[CCode (cname = "tcfdbaddint")]
		public int add_int (int64 id, int num);
		[CCode (cname = "tcfdbadddouble")]
		public double add_double (int64 id, double num);
		[CCode (cname = "tcfdbsync")]
		public bool sync ();
		[CCode (cname = "tcfdboptimize")]
		public bool optimize (int32 width = 0, int64 limsiz = 0);
		[CCode (cname = "tcfdbvanish")]
		public bool clear ();
		[CCode (cname = "tcfdbcopy")]
		public bool copy (string path);
		[CCode (cname = "tcfdbpath")]
		public unowned string path ();
		[CCode (cname = "tcfdbrnum")]
		public uint64 get_length ();
		[CCode (cname = "tcfdbfsiz")]
		public uint64 get_size ();

		public uint64 length { get { return this.get_length (); } }
		public uint64 size { get { return this.get_size (); } }
	}

	[Compact, CCode (cname = "TCADB", cprefix = "tcadb", free_function = "tcadbdel", cheader_filename = "tcadb.h")]
	public class ADB {
		[CCode (cname = "tcadbnew")]
		public ADB ();
		[CCode (cname = "tcadbopen")]
		public bool open (string name);
		[CCode (cname = "tcadbclose")]
		public bool close ();
		[CCode (cname = "tcadbput")]
		public bool replace (uint8[] key, uint8[] vsiz);
		[CCode (cname = "tcadbput2")]
		public bool replace_string (string key, string value);
		[CCode (cname = "tcadbputkeep")]
		public bool put (uint8[] key, uint8[] value);
		[CCode (cname = "tcadbputkeep2")]
		public bool put_string (string key, string value);
		[CCode (cname = "tcadbputcat")]
		public bool append (uint8[] key, uint8[] value);
		[CCode (cname = "tcadbputcat2")]
		public bool append_string (string key, string value);
		[CCode (cname = "tcadbout")]
		public bool remove (uint8[] key);
		[CCode (cname = "tcadbout2")]
		public bool remove_string (string key);
		[CCode (cname = "tcadbget")]
		public unowned uint8[]? _get (uint8[] key);
		[CCode (cname = "_vala_tcadbget")]
		public uint8[]? get (uint8[] key) {
			return TokyoCabinet.Memory.copy_and_free (this._get (key));
		}
		[CCode (cname = "tcadbget2")]
		public unowned string? _get_string (string key);
		public string? get_string (string key) {
			return TokyoCabinet.Memory.copy_and_free_string (this._get_string (key));
		}
		[CCode (cname = "tcadbvsiz")]
		public int value_size (uint8[] key);
		[CCode (cname = "tcadbvsiz2")]
		public int value_size_string (string key);
		[CCode (cname = "tcadbiterinit")]
		public bool iterator_init ();

		[CCode (cname = "tcadbiternext")]
		public unowned uint8[]? _iterator_next ();
		[CCode (cname = "_vala_tcadbiternext")]
		public uint8[]? iterator_next () {
			return TokyoCabinet.Memory.copy_and_free (this._iterator_next ());
		}
		[CCode (cname = "tcadbiternext2")]
		public unowned string? _iterator_next_string ();
		[CCode (cname = "_vala_tcadbiternext")]
		public string? iterator_next_string () {
			return TokyoCabinet.Memory.copy_and_free_string (this._iterator_next_string ());
		}

		[CCode (cname = "tcadbfwmkeys")]
		public TokyoCabinet.List forward_matching_keys (uint8[] pbuf, int max);
		[CCode (cname = "tcadbfwmkeys2")]
		public TokyoCabinet.List forward_matching_keys_string (string pstr, int max);
		[CCode (cname = "tcadbaddint")]
		public int add_int (uint8[] key, int num);
		[CCode (cname = "tcadbadddouble")]
		public double add_double (uint8[] key, double num);
		[CCode (cname = "tcadbsync")]
		public bool sync ();
		[CCode (cname = "tcadbvanish")]
		public bool clear ();
		[CCode (cname = "tcadbcopy")]
		public bool copy (string path);
		[CCode (cname = "tcadbrnum")]
		public uint64 get_length ();
		[CCode (cname = "tcadbsize")]
		public uint64 get_size ();

		public uint64 length { get { return this.get_length (); } }
		public uint64 size { get { return this.get_size (); } }
	}
}
