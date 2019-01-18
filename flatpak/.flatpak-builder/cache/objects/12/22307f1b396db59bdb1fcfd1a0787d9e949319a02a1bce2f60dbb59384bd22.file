/* mysql.vala
 *
 * Copyright (C) 2008, 2010 Jukka-Pekka Iivonen
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

[CCode (lower_case_cprefix = "mysql_", cheader_filename = "mysql/mysql.h")]
namespace Mysql {
	[CCode (cname = "unsigned long", cprefix = "CLIENT_", has_type_id = false)]
	public enum ClientFlag {
		LONG_PASSWORD,
		FOUND_ROWS,
		LONG_FLAG,
		CONNECT_WITH_DB,
		NO_SCHEMA,
		COMPRESS,
		ODBC,
		LOCAL_FILES,
		IGNORE_SPACE,
		PROTOCOL_41,
		INTERACTIVE,
		SSL,
		IGNORE_SIGPIPE,
		TRANSACTIONS,
		RESERVED,
		SECURE_CONNECTION,
		MULTI_STATEMENTS,
		MULTI_RESULTS,
		SSL_VERIFY_SERVER_CERT,
		REMEMBER_OPTIONS
	}

	[CCode (cname = "enum_mysql_set_option", cprefix = "MYSQL_OPTION_", has_type_id = false)]
	public enum SetOption {
		MULTI_STATEMENTS_ON,
		MULTI_STATEMENTS_OFF
	}

	[CCode (cname = "mysql_option", cprefix = "MYSQL_", has_type_id = false)]
	public enum Option {
		OPT_CONNECT_TIMEOUT,
		OPT_COMPRESS,
		OPT_NAMED_PIPE,
		INIT_COMMAND,
		READ_DEFAULT_FILE,
		READ_DEFAULT_GROUP,
		SET_CHARSET_DIR,
		SET_CHARSET_NAME,
		OPT_LOCAL_INFILE,
		OPT_PROTOCOL,
		SHARED_MEMORY_BASE_NAME,
		OPT_READ_TIMEOUT,
		OPT_WRITE_TIMEOUT,
		OPT_USE_RESULT,
		OPT_USE_REMOTE_CONNECTION,
		OPT_USE_EMBEDDED_CONNECTION,
		OPT_GUESS_CONNECTION,
		SET_CLIENT_IP,
		SECURE_AUTH,
		REPORT_DATA_TRUNCATION,
		OPT_RECONNECT,
		OPT_SSL_VERIFY_SERVER_CERT
	}

	[CCode (cname = "enum enum_field_types", cprefix = "MYSQL_TYPE_", has_type_id = false)]
	public enum FieldType {
		DECIMAL,
		TINY,
		SHORT,
		LONG,
		FLOAT,
		DOUBLE,
		NULL,
		TIMESTAMP,
		LONGLONG,
		INT24,
		DATE,
		TIME,
		DATETIME,
		YEAR,
		NEWDATE,
		VARCHAR,
		BIT,
		NEWDECIMAL,
		ENUM,
		SET,
		TINY_BLOB,
		MEDIUM_BLOB,
		LONG_BLOB,
		BLOB,
		VAR_STRING,
		STRING,
		GEOMETRY
	}

	[CCode (cname = "guint", has_type_id = false)]
	public enum FieldFlag {
		[CCode (cname = "NOT_NULL_FLAG")]
		NOT_NULL,
		[CCode (cname = "PRI_KEY_FLAG")]
		PRI_KEY,
		[CCode (cname = "UNIQUE_FLAG")]
		UNIQUE_KEY,
		[CCode (cname = "MULTIPLE_KEY_FLAG")]
		MULTIPLE_KEY,
		[CCode (cname = "BLOB_FLAG")]
		BLOB,
		[CCode (cname = "UNSIGNED_FLAG")]
		UNSIGNED,
		[CCode (cname = "ZEROFILL_FLAG")]
		ZEROFILL,
		[CCode (cname = "BINARY_FLAG")]
		BINARY,
		[CCode (cname = "ENUM_FLAG")]
		ENUM,
		[CCode (cname = "AUTO_INCREMENT_FLAG")]
		AUTO_INCREMENT,
		[CCode (cname = "TIMESTAMP_FLAG")]
		TIMESTAMP,
		[CCode (cname = "SET_FLAG")]
		SET,
		[CCode (cname = "NO_DEFAULT_VALUE_FLAG")]
		NO_DEFAULT_VALUE,
		[CCode (cname = "ON_UPDATE_NOW_FLAG")]
		ON_UPDATE_NOW,
		[CCode (cname = "NUM_FLAG")]
		NUM,
		[CCode (cname = "PART_KEY_FLAG")]
		PART_KEY,
		[CCode (cname = "GROUP_FLAG")]
		GROUP,
		[CCode (cname = "UNIQUE_FLAG")]
		UNIQUE,
		[CCode (cname = "BINCMP_FLAG")]
		BINCMP,
		[CCode (cname = "GET_FIXED_FIELDS_FLAG")]
		GET_FIXED_FIELDS,
		[CCode (cname = "FIELD_IN_PART_FUNC_FLAG")]
		FIELD_IN_PART_FUNC,
		[CCode (cname = "FIELD_IN_ADD_INDEX")]
		FIELD_IN_ADD_INDEX,
		[CCode (cname = "FIELD_IS_RENAMED")]
		FIELD_IS_RENAMED
	}

	[CCode (cname = "enum_cursor_type", cprefix = "CURSOR_TYPE_", has_type_id = false)]
	public enum CursorType {
		NO_CURSOR,
		READ_ONLY,
		FOR_UPDATE,
		SCROLLABLE
	}

	[Compact]
	[CCode (free_function = "mysql_close", cname = "MYSQL", cprefix = "mysql_")]
	public class Database {
		[CCode (cname = "mysql_init")]
		public Database (Database? mysql = null);

		public ulong affected_rows ();
		public bool autocommit (bool mode);
		public bool change_user (string username, string passwd, string? dbname = null);
		public unowned string character_set_name ();
		public bool commit ();
		public int dump_debug_info ();
		public uint errno ();
		public unowned string error ();
		public unowned string get_host_info ();
		public uint get_proto_info ();
		public unowned string get_server_info ();
		public ulong get_server_version ();
		public unowned string get_ssl_cipher ();
		public unowned string info ();
		public ulong insert_id ();
		public int kill (ulong pid);
		public Result? list_dbs (string? wild = null);
		public Result? list_fields (string table, string? wild = null);
		public Result? list_processes ();
		public Result? list_tables (string? wild = null);
		public bool more_results ();
		public int next_result ();
		public int options (Option option, string arg);
		public int ping ();
		public int query (string stmt_str);
		public bool real_connect (string? host = null, string? username = null, string? passwd = null, string? dbname = null, uint port = 0, string? unix_socket = null, ClientFlag client_flag = 0);
		public ulong real_escape_string (string to, string from, ulong length);
		public int real_query (string query, ulong len);
		public int reload ();
		public bool rollback ();
		public int select_db (string dbname);
		public int set_character_set (string csname);
		public void set_local_infile_default ();
		public int set_server_option (SetOption option);
		public unowned string sqlstate ();
		public int shutdown (int shutdown_level);
		public bool ssl_set (string key, string cert, string ca, string capath, string cipher);
		public unowned string stat ();
		public Result? store_result ();
		public ulong thread_id ();
		public Result? use_result ();
		public uint warning_count ();
	}

	[Compact]
	[CCode (free_function = "mysql_free_result", cname = "MYSQL_RES", cprefix = "mysql_")]
	public class Result {
		public bool eof ();
		public Field* fetch_field ();
		public Field* fetch_field_direct (uint field_nbr);

		[CCode (cname = "mysql_fetch_fields", array_length = false)]
		public unowned Field[] _fetch_fields ();
		[CCode (cname = "_vala_mysql_fetch_fields")]
		public unowned Field[] fetch_fields () {
			unowned Field[] fields = this._fetch_fields ();
			fields.length = (int) this.num_fields ();
			return fields;
		}

		[CCode (cname = "mysql_fetch_lengths", array_length = false)]
		public unowned ulong[] _fetch_lengths ();
		[CCode (cname = "_vala_mysql_fetch_lengths")]
		public unowned ulong[] fetch_lengths () {
			unowned ulong[] lengths = this._fetch_lengths ();
			lengths.length = (int) this.num_fields ();
			return lengths;
		}

		[CCode (cname = "mysql_fetch_row", array_length = false)]
		public unowned string[]? _fetch_row ();
		[CCode (cname = "_vala_mysql_fetch_row")]
		public unowned string[]? fetch_row () {
			unowned string[]? row = this._fetch_row ();
			row.length = (int) this.num_fields ();
			return row;
		}

		public uint fetch_count ();
		public uint num_fields ();
		public uint num_rows ();

		public bool data_seek (ulong offset);
	}
	[CCode (cname = "MYSQL_FIELD", has_type_id = false)]
	public struct Field {
		public unowned string name;
		public unowned string org_name;
		public unowned string table;
		public unowned string org_table;
		public unowned string db;
		public unowned string catalog;
		public unowned string def;
		public ulong length;
		public ulong max_length;
		public uint name_length;
		public uint org_name_length;
		public uint table_length;
		public uint org_table_length;
		public uint db_length;
		public uint catalog_length;
		public uint def_length;
		public uint flags;
		public uint decimals;
		public uint charsetnr;
		public FieldType type;
		public void *extension;
	}

	public unowned string get_client_info ();
	public ulong get_client_version ();
	public void debug (string msg);
	public ulong hex_string (string to, string from, ulong length);
	public void library_end ();
	public int library_init ([CCode (array_length_pos = 0.1)] string[] argv, [CCode (array_length = false, array_null_terminated = true)] string[]? groups = null);
	public void server_end ();
	public int server_init ([CCode (array_length_pos = 0.1)] string[] argv, [CCode (array_length = false, array_null_terminated = true)] string[]? groups = null);
	public void thread_end ();
	public bool thread_init ();
	public uint thread_safe ();
}

