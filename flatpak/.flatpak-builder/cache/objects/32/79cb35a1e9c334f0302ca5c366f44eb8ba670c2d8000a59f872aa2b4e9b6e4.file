/* sqlite3.vala
 *
 * Copyright (C) 2007 Jürg Billeter
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
 * 	Jürg Billeter <j@bitron.ch>
 */

[CCode (lower_case_cprefix = "sqlite3_", cheader_filename = "sqlite3.h")]
namespace Sqlite {
	/* Database Connection Handle */
	[Compact]
	[CCode (free_function = "sqlite3_close", cname = "sqlite3", cprefix = "sqlite3_")]
	public class Database {
		public int busy_timeout (int ms);
		public int changes ();
		[CCode (cname = "sqlite3_exec")]
		public int _exec (string sql, Callback? callback = null, [CCode (type = "char**")] out unowned string? errmsg = null);
		[CCode (cname = "_sqlite3_exec")]
		public int exec (string sql, Callback? callback = null, out string? errmsg = null) {
			unowned string? sqlite_errmsg;
			var ec = this._exec (sql, callback, out sqlite_errmsg);
			if (&errmsg != null) {
				errmsg = sqlite_errmsg;
			}
			Sqlite.Memory.free ((void*) sqlite_errmsg);
			return ec;
		}
		public int extended_result_codes (int onoff);
		public int get_autocommit ();
		public void interrupt ();
		public int64 last_insert_rowid ();
		public int limit (Sqlite.Limit id, int new_val);
		public int total_changes ();
		public int complete (string sql);
		[CCode (cname = "sqlite3_get_table")]
		public int _get_table (string sql, [CCode (array_length = false)] out unowned string[] resultp, out int nrow, out int ncolumn, [CCode (type = "char**")] out unowned string? errmsg = null);
		private static void free_table ([CCode (array_length = false)] string[] result);
		[CCode (cname = "_sqlite3_get_table")]
		public int get_table (string sql, out string[] resultp, out int nrow, out int ncolumn, out string? errmsg = null) {
			unowned string? sqlite_errmsg;
			unowned string[] sqlite_resultp;

			var ec = this._get_table (sql, out sqlite_resultp, out nrow, out ncolumn, out sqlite_errmsg);

			resultp = new string[(nrow + 1) * ncolumn];
			for (var entry = 0 ; entry < resultp.length ; entry++ ) {
				resultp[entry] = sqlite_resultp[entry];
			}
			Sqlite.Database.free_table (sqlite_resultp);

			if (&errmsg != null) {
				errmsg = sqlite_errmsg;
			}
			Sqlite.Memory.free ((void*) sqlite_errmsg);
			return ec;
		}
		public static int open (string filename, out Database db);
		public static int open_v2 (string filename, out Database db, int flags = OPEN_READWRITE | OPEN_CREATE, string? zVfs = null);
		public int errcode ();
		public unowned string errmsg ();
		public unowned Sqlite.Statement next_stmt (Sqlite.Statement? current);
		public int prepare (string sql, int n_bytes, out Statement stmt, out unowned string tail = null);
		public int prepare_v2 (string sql, int n_bytes, out Statement stmt, out unowned string tail = null);
		public int set_authorizer (AuthorizeCallback? auth);
		[CCode (cname = "sqlite3_db_status")]
		public int status (Sqlite.DatabaseStatus op, out int pCurrent, out int pHighwater, int resetFlag = 0);
		public int table_column_metadata (string db_name, string table_name, string column_name, out string? data_type, out string? collation_sequence, out int? not_null, out int? primary_key, out int? auto_increment);
		public void trace (TraceCallback? xtrace);
		public void profile (ProfileCallback? xprofile);
		public void progress_handler (int n_opcodes, Sqlite.ProgressCallback? progress_handler);
		public void commit_hook (CommitCallback? commit_hook);
		public void rollback_hook (RollbackCallback? rollback_hook);
		public void update_hook (UpdateCallback? update_hook);
		public int create_function (string zFunctionName, int nArg, int eTextRep, void * user_data, UserFuncCallback? xFunc, UserFuncCallback? xStep, UserFuncFinishCallback? xFinal);
		public int create_function_v2 (string zFunctionName, int nArg, int eTextRep, void * user_data, UserFuncCallback? xFunc, UserFuncCallback? xStep, UserFuncFinishCallback? xFinal, GLib.DestroyNotify? destroy = null);
		public int create_collation (string zName, int eTextRep, [CCode (delegate_target_pos = 2.9, type = "int (*)(void *, int,  const void *, int,  const void *)")] CompareCallback xCompare);

		public int wal_autocheckpoint (int N);
		public int wal_checkpoint (string zDb);
		public void* wal_hook (WALHookCallback cb, string db_name, int page_count);
	}

	[CCode (instance_pos = 0)]
	public delegate int AuthorizeCallback (Sqlite.Action action, string? p1, string? p2, string db_name, string? responsible);
	[CCode (instance_pos = 0)]
	public delegate void TraceCallback (string message);
	[CCode (instance_pos = 0)]
	public delegate void ProfileCallback (string sql, uint64 time);
	public delegate int ProgressCallback ();
	public delegate int CommitCallback ();
	public delegate void RollbackCallback ();
	[CCode (has_target = false)]
	public delegate void UserFuncCallback (Sqlite.Context context, [CCode (array_length_pos = 1.1)] Sqlite.Value[] values);
	[CCode (has_target = false)]
	public delegate void UserFuncFinishCallback (Sqlite.Context context);
	[CCode (instance_pos = 0)]
	public delegate void UpdateCallback (Sqlite.Action action, string dbname, string table, int64 rowid);
	[CCode (instance_pos = 0)]
	public delegate int CompareCallback (int alen, void* a, int blen, void* b);
	[CCode (instance_pos = 0)]
	public delegate int WALHookCallback (Sqlite.Database db, string dbname, int pages);

	public unowned string? compileoption_get (int n);
	public int compileoption_used (string option_name);
	public static int complete (string sql);
	[CCode (sentinel = "")]
	public static int config (Sqlite.Config op, ...);
	public unowned string libversion ();
	public int libversion_number ();
	[PrintfFormat]
	public void log (int error_code, string format, ...);
	public unowned string sourceid ();
	public static int status (Sqlite.Status op, out int pCurrent, out int pHighwater, int resetFlag = 0);
	public static int threadsafe ();

	[CCode (cname = "SQLITE_VERSION")]
	public const string VERSION;
	[CCode (cname = "SQLITE_VERSION_NUMBER")]
	public const int VERSION_NUMBER;
	[CCode (cname = "SQLITE_SOURCE_ID")]
	public const string SOURCE_ID;

	/* Dynamically Typed Value Object */
	[Compact]
	[CCode (cname = "sqlite3_value")]
	public class Value {
		[CCode (cname = "sqlite3_value_blob")]
		public void* to_blob ();
		[CCode (cname = "sqlite3_value_bytes")]
		public int to_bytes ();
		[CCode (cname = "sqlite3_value_double")]
		public double to_double ();
		[CCode (cname = "sqlite3_value_int")]
		public int to_int ();
		[CCode (cname = "sqlite3_value_int64")]
		public int64 to_int64 ();
		[CCode (cname = "sqlite3_value_text")]
		public unowned string to_text ();
		[CCode (cname = "sqlite3_value_type")]
		public int to_type ();
		[CCode (cname = "sqlite3_value_numeric_type")]
		public int to_numeric_type ();
	}

	[CCode (cname = "sqlite3_callback", instance_pos = 0)]
	public delegate int Callback (int n_columns, [CCode (array_length = false)] string[] values, [CCode (array_length = false)] string[] column_names);

	[CCode (cname = "SQLITE_OK")]
	public const int OK;
	[CCode (cname = "SQLITE_ERROR")]
	public const int ERROR;
	[CCode (cname = "SQLITE_INTERNAL")]
	public const int INTERNAL;
	[CCode (cname = "SQLITE_PERM")]
	public const int PERM;
	[CCode (cname = "SQLITE_ABORT")]
	public const int ABORT;
	[CCode (cname = "SQLITE_BUSY")]
	public const int BUSY;
	[CCode (cname = "SQLITE_LOCKED")]
	public const int LOCKED;
	[CCode (cname = "SQLITE_NOMEM")]
	public const int NOMEM;
	[CCode (cname = "SQLITE_READONLY")]
	public const int READONLY;
	[CCode (cname = "SQLITE_INTERRUPT")]
	public const int INTERRUPT;
	[CCode (cname = "SQLITE_IOERR")]
	public const int IOERR;
	[CCode (cname = "SQLITE_CORRUPT")]
	public const int CORRUPT;
	[CCode (cname = "SQLITE_NOTFOUND")]
	public const int NOTFOUND;
	[CCode (cname = "SQLITE_FULL")]
	public const int FULL;
	[CCode (cname = "SQLITE_CANTOPEN")]
	public const int CANTOPEN;
	[CCode (cname = "SQLITE_PROTOCOL")]
	public const int PROTOCOL;
	[CCode (cname = "SQLITE_EMPTY")]
	public const int EMPTY;
	[CCode (cname = "SQLITE_SCHEMA")]
	public const int SCHEMA;
	[CCode (cname = "SQLITE_TOOBIG")]
	public const int TOOBIG;
	[CCode (cname = "SQLITE_CONSTRAINT")]
	public const int CONSTRAINT;
	[CCode (cname = "SQLITE_MISMATCH")]
	public const int MISMATCH;
	[CCode (cname = "SQLITE_MISUSE")]
	public const int MISUSE;
	[CCode (cname = "SQLITE_NOLFS")]
	public const int NOLFS;
	[CCode (cname = "SQLITE_AUTH")]
	public const int AUTH;
	[CCode (cname = "SQLITE_FORMAT")]
	public const int FORMAT;
	[CCode (cname = "SQLITE_RANGE")]
	public const int RANGE;
	[CCode (cname = "SQLITE_NOTADB")]
	public const int NOTADB;
	[CCode (cname = "SQLITE_ROW")]
	public const int ROW;
	[CCode (cname = "SQLITE_DONE")]
	public const int DONE;
	[CCode (cname = "SQLITE_OPEN_READONLY")]
	public const int OPEN_READONLY;
	[CCode (cname = "SQLITE_OPEN_READWRITE")]
	public const int OPEN_READWRITE;
	[CCode (cname = "SQLITE_OPEN_CREATE")]
	public const int OPEN_CREATE;
	[CCode (cname = "SQLITE_OPEN_URI")]
	public const int OPEN_URI;
	[CCode (cname = "SQLITE_OPEN_MEMORY")]
	public const int OPEN_MEMORY;
	[CCode (cname = "SQLITE_OPEN_NOMUTEX")]
	public const int OPEN_NOMUTEX;
	[CCode (cname = "SQLITE_OPEN_FULLMUTEX")]
	public const int OPEN_FULLMUTEX;
	[CCode (cname = "SQLITE_OPEN_SHAREDCACHE")]
	public const int OPEN_SHAREDCACHE;
	[CCode (cname = "SQLITE_OPEN_PRIVATECACHE")]
	public const int OPEN_PRIVATECACHE;
	[CCode (cname = "SQLITE_INTEGER")]
	public const int INTEGER;
	[CCode (cname = "SQLITE_FLOAT")]
	public const int FLOAT;
	[CCode (cname = "SQLITE_BLOB")]
	public const int BLOB;
	[CCode (cname = "SQLITE_NULL")]
	public const int NULL;
	[CCode (cname = "SQLITE3_TEXT")]
	public const int TEXT;
	[CCode (cname = "SQLITE_MUTEX_FAST")]
	public const int MUTEX_FAST;
	[CCode (cname = "SQLITE_MUTEX_RECURSIVE")]
	public const int MUTEX_RECURSIVE;
	[CCode (cname = "SQLITE_UTF8")]
	public const int UTF8;
	[CCode (cname = "SQLITE_UTF16LE")]
	public const int UTF16LE;
	[CCode (cname = "SQLITE_UTF16BE")]
	public const int UTF16BE;
	[CCode (cname = "SQLITE_UTF16")]
	public const int UTF16;
	[CCode (cname = "SQLITE_ANY")]
	public const int ANY;
	[CCode (cname = "SQLITE_UTF16_ALIGNED")]
	public const int UTF16_ALIGNED;

	[CCode (cname = "int", cprefix = "SQLITE_", has_type_id = false)]
	public enum Action {
		CREATE_INDEX,
		CREATE_TABLE,
		CREATE_TEMP_INDEX,
		CREATE_TEMP_TABLE,
		CREATE_TEMP_TRIGGER,
		CREATE_TEMP_VIEW,
		CREATE_TRIGGER,
		CREATE_VIEW,
		DELETE,
		DROP_INDEX,
		DROP_TABLE,
		DROP_TEMP_INDEX,
		DROP_TEMP_TABLE,
		DROP_TEMP_TRIGGER,
		DROP_TEMP_VIEW,
		DROP_TRIGGER,
		DROP_VIEW,
		INSERT,
		PRAGMA,
		READ,
		SELECT,
		TRANSACTION,
		UPDATE,
		ATTACH,
		DETACH,
		ALTER_TABLE,
		REINDEX,
		ANALYZE,
		CREATE_VTABLE,
		DROP_VTABLE,
		FUNCTION,
		SAVEPOINT,
		COPY
	}

	[CCode (cname = "int", cprefix = "SQLITE_CONFIG_", has_type_id = false)]
	public enum Config {
		SINGLETHREAD,
		MULTITHREAD,
		SERIALIZED,
		MALLOC,
		GETMALLOC,
		SCRATCH,
		PAGECACHE,
		HEAP,
		MEMSTATUS,
		MUTEX,
		GETMUTEX,
		LOOKASIDE,
		PCACHE,
		GETPCACHE,
		LOG,
	}

	[CCode (cname = "int", cprefix = "SQLITE_DBSTATUS_", has_type_id = false)]
	public enum DatabaseStatus {
		LOOKASIDE_USED
	}

	[CCode (cname = "int", cprefix = "SQLITE_LIMIT_", has_type_id = false)]
	public enum Limit {
		LENGTH,
		SQL_LENGTH,
		COLUMN,
		EXPR_DEPTH,
		COMPOUND_SELECT,
		VDBE_OP,
		FUNCTION_ARG,
		ATTACHED,
		LIKE_PATTERN_LENGTH,
		VARIABLE_NUMBER,
		TRIGGER_DEPTH
	}

	[CCode (cname = "int", cprefix = "SQLITE_STMTSTATUS_", has_type_id = false)]
	public enum StatementStatus {
		FULLSCAN_STEP,
		SORT
	}

	[CCode (cname = "int", cprefix = "SQLITE_STATUS_", has_type_id = false)]
	public enum Status {
		MEMORY_USED,
		PAGECACHE_USED,
		PAGECACHE_OVERFLOW,
		SCRATCH_USED,
		SCRATCH_OVERFLOW,
		MALLOC_SIZE,
		PARSER_STACK,
		PAGECACHE_SIZE,
		SCRATCH_SIZE
	}

	/* SQL Statement Object */
	[Compact]
	[CCode (free_function = "sqlite3_finalize", cname = "sqlite3_stmt", cprefix = "sqlite3_")]
	public class Statement {
		public int bind_parameter_count ();
		public int bind_parameter_index (string name);
		public unowned string bind_parameter_name (int index);
		public int clear_bindings ();
		public int column_count ();
		public int data_count ();
		public unowned Database db_handle ();
		public int reset ();
		[CCode (cname = "sqlite3_stmt_status")]
		public int status (Sqlite.StatementStatus op, int resetFlg = 0);
		public int step ();
		public int bind_blob (int index, void* value, int n, GLib.DestroyNotify? destroy_notify = null);
		public int bind_double (int index, double value);
		public int bind_int (int index, int value);
		public int bind_int64 (int index, int64 value);
		public int bind_null (int index);
		[CCode (cname = "sqlite3_bind_text")]
		public int _bind_text (int index, string value, int n = -1, GLib.DestroyNotify? destroy_notify = null);
		public int bind_text (int index, owned string value, int n = -1, GLib.DestroyNotify destroy_notify = GLib.g_free);
		public int bind_value (int index, Value value);
		public int bind_zeroblob (int index, int n);
		public void* column_blob (int col);
		public int column_bytes (int col);
		public double column_double (int col);
		public int column_int (int col);
		public int64 column_int64 (int col);
		public unowned string? column_text (int col);
		public int column_type (int col);
		public unowned Value column_value (int col);
		public unowned string column_name (int index);
		public unowned string column_database_name (int col);
		public unowned string column_table_name (int col);
		public unowned string column_origin_name (int col);
		public unowned string sql ();
	}

	namespace Memory {
		[CCode (cname = "sqlite3_malloc")]
		public static void* malloc (int n_bytes);
		[CCode (cname = "sqlite3_realloc")]
		public static void* realloc (void* mem, int n_bytes);
		[CCode (cname = "sqlite3_free")]
		public static void free (void* mem);
		[CCode (cname = "sqlite3_release_memory")]
		public static int release (int bytes);
		[CCode (cname = "sqlite3_memory_used")]
		public static int64 used ();
		[CCode (cname = "sqlite3_memory_highwater")]
		public static int64 highwater (int reset = 0);
		[Version (deprecated_since = "3.7.2", replacement = "Sqlite.Memory.soft_heap_limit64")]
		[CCode (cname = "sqlite3_soft_heap_limit")]
		public static void soft_heap_limit (int limit);
		[CCode (cname = "sqlite3_soft_heap_limit64")]
		public static int64 soft_heap_limit64 (int64 limit = -1);
	}

	[Compact]
	[CCode (cname = "sqlite3_mutex")]
	public class Mutex {
		[CCode (cname = "sqlite3_mutex_alloc")]
		public Mutex (int mutex_type = MUTEX_RECURSIVE);
		public void enter ();
		public int held ();
		public int notheld ();
		public int @try ();
		public void leave ();
	}

	[Compact, CCode (cname = "sqlite3_context", cprefix = "sqlite3_")]
	public class Context {
		public void result_blob (owned uint8[] data, GLib.DestroyNotify? destroy_notify = GLib.g_free);
		public void result_double (double value);
		public void result_error (string value, int error_code);
		public void result_error_toobig ();
		public void result_error_nomem ();
		public void result_error_code (int error_code);
		public void result_int (int value);
		public void result_int64 (int64 value);
		public void result_null ();
		public void result_text (owned string value, int length = -1, GLib.DestroyNotify? destroy_notify = GLib.g_free);
		public void result_value (Sqlite.Value value);
		public void result_zeroblob (int n);

		[CCode (simple_generics = true)]
		public unowned T user_data<T> ();
		[CCode (simple_generics = true)]
		public void set_auxdata<T> (int N, owned T data);
		[CCode (simple_generics = true)]
		public unowned T get_auxdata<T> (int N);
		[CCode (cname = "sqlite3_context_db_handle")]
		public unowned Database db_handle ();
		[CCode (cname = "sqlite3_aggregate_context")]
		public void * aggregate (int n_bytes);
	}

	[Compact, CCode (cname = "sqlite3_backup", free_function = "sqlite3_backup_finish", cprefix = "sqlite3_backup_")]
	public class Backup {
		[CCode (cname = "sqlite3_backup_init")]
		public Backup (Database dest, string dest_name, Database source, string source_name);
		public int step (int nPage);
		public int remaining ();
		public int pagecount ();
	}
}

