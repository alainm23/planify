/* libpq.vapi
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
 *	Jukka-Pekka Iivonen <jp0409@jippii.fi>
 */

#if LIBPQ_9_3
[CCode (cprefix = "PQ", cheader_filename = "libpq-fe.h")]
#else
[CCode (cprefix = "PQ", cheader_filename = "postgresql/libpq-fe.h")]
#endif
namespace Postgres {

	[CCode (cname = "ConnStatusType", cprefix = "CONNECTION_", has_type_id = false)]
	public enum ConnectionStatus {
		OK,
		BAD,
		STARTED,
		MADE,
		AWAITING_RESPONSE,
		AUTH_OK,
		SETENV,
		SSL_STARTUP,
		NEEDED
	}

	[CCode (cname = "PostgresPollingStatusType", cprefix = "PGRES_POLLING_", has_type_id = false)]
	public enum PollingStatus {
		FAILED,
		READING,
		WRITING,
		OK,
		ACTIVE
	}

	[CCode (cname = "ExecStatusType", cprefix = "PGRES_", has_type_id = false)]
	public enum ExecStatus {
		EMPTY_QUERY,
		COMMAND_OK,
		TUPLES_OK,
		COPY_OUT,
		COPY_IN,
		BAD_RESPONSE,
		NONFATAL_ERROR,
		FATAL_ERROR
	}

	[CCode (cname = "PGTransactionStatusType", cprefix = "PQTRANS_", has_type_id = false)]
	public enum TransactionStatus {
		IDLE,
		ACTIVE,
		INTRANS,
		INERROR,
		UNKNOWN
	}

	[CCode (cname = "PGVerbosity", cprefix = "PQERRORS_", has_type_id = false)]
	public enum Verbosity {
		TERSE,
		DEFAULT,
		VERBOSE
	}

	[CCode (cname = "int", cprefix = "PG_DIAG_", has_type_id = false)]
	public enum FieldCode {
		SEVERITY,
		SQLSTATE,
		MESSAGE_PRIMARY,
		MESSAGE_DETAIL,
		MESSAGE_HINT,
		STATEMENT_POSITION,
		INTERNAL_POSITION,
		INTERNAL_QUERY,
		CONTEXT,
		SOURCE_FILE,
		SOURCE_LINE,
		SOURCE_FUNCTION
	}

	[CCode (cname = "PGPing", cprefix = "PQPING_", has_type_id = false)]
	public enum Ping {
		OK,
		REJECT,
		NO_RESPONCE,
		NO_ATTEMPT
	}

	[Compact]
	[CCode (cname = "PGnotify", free_function = "PQfreemem")]
	public class Notify {
		public string relname;
		public int    be_pid;
		public string extra;

		private Notify ();
	}

	[CCode (cname = "PQnoticeReceiver")]
	public delegate void NoticeReceiverFunc (void* arg, Result res);

	[CCode (cname = "PQnoticeProcessor")]
	public delegate void NoticeProcessorFunc (void* arg, string message);

	[CCode (cname = "PQprintOpt", has_type_id = false)]
	public struct PrintOpt {
		public bool     header;
		public bool     align;
		public bool     standard;
		public bool     html3;
		public bool     expanded;
		public bool     pager;
		public string   fieldSep;
		public string   tableOpt;
		public string   caption;
		public string[] fieldName;
	}

	[Compact]
	[CCode (cname = "PQconninfoOption", free_function = "PQconninfoFree")]
	public class ConnectionOptions {
		public string keyword;
		public string envvar;
		public string compiled;
		public string val;
		public string label;
		public string dispchar;
		public int    dispsize;
	}

	[CCode (cname = "PQArgBlock", has_type_id = false)]
	public struct ArgBlock {
		public int len;
		public int isint;
	}

	[SimpleType]
	[CCode (cname = "uint", default_value = "0U", type_signature = "u", has_type_id = false)]
	public struct Oid {
	}

	[CCode (cname = "InvalidOid")]
	public const uint InvalidOid;

	[CCode (cname = "PQconnectStart")]
	public Database connect_start (string conninfo);

	[CCode (cname = "PQconnectdb")]
	public Database connect_db (string conninfo);

	[CCode (cname = "PQsetdbLogin")]
	public Database set_db_login (string host, string port, string options, string gtty, string db_name, string login, string pwd);

	[CCode (cname = "PQsetdb")]
	public Database set_db (string host, string port, string options, string gtty, string db_name);

	[CCode (cname = "PQconndefaults")]
	public ConnectionOptions get_default_options ();

	[CCode (cname = "PQinitSSL")]
	public void init_ssl (int do_init);

	[CCode (cname = "PQisthreadsafe")]
	public int is_thread_safe ();

	[CCode (cname = "PQresStatus")]
	public unowned string result_status (ExecStatus status);

	[Compact]
	[CCode (free_function = "PQfreeCancel", cname = "PGcancel", cprefix = "PQ")]
	public class Cancel {
		[CCode (cname = "PQcancel")]
		public bool cancel (char[] errbuf, int errbufsize);
	}

	/* Database Connection Handle */
	[Compact]
	[CCode (free_function = "PQfinish", cname = "PGconn", cprefix = "PQ")]
	public class Database {
		[CCode (cname = "PQconnectPoll")]
		public PollingStatus connect_poll ();

		[CCode (cname = "PQresetStart")]
		public int reset_start ();

		[CCode (cname = "PQresetPoll")]
		public PollingStatus reset_poll ();

		[CCode (cname = "PQreset")]
		public void reset ();

		[CCode (cname = "PQgetCancel")]
		public Cancel get_cancel ();

		[CCode (cname = "PQrequestCancel")]
		public int request_cancel ();

		[CCode (cname = "PQdb")]
		public unowned string get_db ();

		[CCode (cname = "PQuser")]
		public unowned string get_user ();

		[CCode (cname = "PQpass")]
		public unowned string get_passwd ();

		[CCode (cname = "PQhost")]
		public unowned string get_host ();

		[CCode (cname = "PQport")]
		public unowned string get_port ();

		[CCode (cname = "PQtty")]
		public unowned string get_tty ();

		[CCode (cname = "PQoptions")]
		public unowned string get_options ();

		[CCode (cname = "PQstatus")]
		public ConnectionStatus get_status ();

		[CCode (cname = "PQtransactionStatus")]
		public TransactionStatus get_transaction_status ();

		[CCode (cname = "PQparameterStatus")]
		public unowned string get_parameter_status (string param_name);

		[CCode (cname = "PQprotocolVersion")]
		public int get_protocol_Version ();

		[CCode (cname = "PQserverVersion")]
		public int get_server_version ();

		[CCode (cname = "PQerrorMessage")]
		public unowned string get_error_message ();

		[CCode (cname = "PQsocket")]
		public int get_socket ();

		[CCode (cname = "PQbackendPID")]
		public int get_backend_pid ();

		[CCode (cname = "PQconnectionNeedsPassword")]
		public int connection_needs_password ();

		[CCode (cname = "PQconnectionUsedPassword")]
		public int connection_used_password ();

		[CCode (cname = "PQclientEncoding")]
		public int get_client_encoding ();

		[CCode (cname = "PQsetClientEncoding")]
		public int set_client_encoding (string encoding);

		[CCode (cname = "PQgetssl")]
		public void* get_ssl ();

		[CCode (cname = "PQsetErrorVerbosity")]
		public Verbosity set_error_verbosity (Verbosity verbosity);

		[CCode (cname = "PQtrace")]
		public void trace (GLib.FileStream debug_port);

		[CCode (cname = "PQuntrace")]
		public void untrace ();

		[CCode (cname = "PQsetNoticeReceiver")]
		public NoticeReceiverFunc set_notice_receiver (NoticeReceiverFunc proc_func, void* arg);

		[CCode (cname = "PQsetNoticeProcessor")]
		public NoticeProcessorFunc set_notice_processor (NoticeProcessorFunc proc_func, void* arg);

		[CCode (cname = "PQexec")]
		public Result exec (string query);

		[CCode (cname = "PQexecParams")]
		public Result exec_params (string command, int n_params, [CCode (array_length = false)] Oid[]? param_types, [CCode (array_length = false)] string[]? param_values, [CCode (array_length = false)] int[]? param_lengths, [CCode (array_length = false)] int[]? param_formats, int result_format);

		[CCode (cname = "PQprepare")]
		public Result prepare (string stmt_name, string query, [CCode (array_length_pos = 2.9)] Oid[]? param_types);

		[CCode (cname = "PQexecPrepared")]
		public Result exec_prepared (string stmt_name, int n_params, [CCode (array_length = false)] string[]? param_values, [CCode (array_length = false)] int[]? param_lengths, [CCode (array_length = false)] int[]? param_formats, int result_format);

		[CCode (cname = "PQsendQuery")]
		public int send_query (string query);

		[CCode (cname = "PQsendQueryParams")]
		public int send_query_params (string command, int n_params, [CCode (array_length = false)] Oid[]? param_types, [CCode (array_length = false)] string[]? param_values, [CCode (array_length = false)] int[]? param_lengths, [CCode (array_length = false)] int[]? param_formats, int result_format);

		[CCode (cname = "PQsendPrepare")]
		public int send_prepare (string stmt_name, string query, [CCode (array_length_pos = 2.9)] Oid[]? param_types);

		[CCode (cname = "PQsendQueryPrepared")]
		public int send_query_prepared (string stmt_name, int n_params, [CCode (array_length = false)] string[]? param_values, [CCode (array_length = false)] int[]? param_lengths, [CCode (array_length = false)] int[]? param_formats, int resultFormat);

		[CCode (cname = "PQgetResult")]
		public Result get_result ();

		[CCode (cname = "PQisBusy")]
		public int is_busy ();

		[CCode (cname = "PQconsumeInput")]
		public int consume_input ();

		[CCode (cname = "PQnotifies")]
		public Notify get_notifies ();

		[CCode (cname = "PQputCopyData")]
		public int put_copy_data (string buffer, int nbytes);

		[CCode (cname = "PQputCopyEnd")]
		public int put_copy_end (string error_msg);

		[CCode (cname = "PQgetCopyData")]
		public int get_copy_data (string[] buffer, int async);

		[CCode (cname = "PQsetnonblocking")]
		public int set_non_blocking (int arg);

		[CCode (cname = "PQisnonblocking")]
		public int is_non_blocking ();

		[CCode (cname = "PQping")]
		public Ping ping();
		 
		[CCode (cname = "PQpingParams")]
		public Ping ping_params(string keywords, string values, int expand_dbname);

		[CCode (cname = "PQflush")]
		public int flush ();

		[CCode (cname = "PQfn")]
		public Result fn (int fnid, int[] result_buf, out int result_len, int result_is_int, ArgBlock args, int nargs);

		[CCode (cname = "PQdescribePrepared")]
		public Result describe_prepared (string stmt);

		[CCode (cname = "PQdescribePortal")]
		public Result describe_portal (string portal);

		[CCode (cname = "PQsendDescribePrepared")]
		public int send_describe_prepared (string stmt);

		[CCode (cname = "PQsendDescribePortal")]
		public int send_describe_portal (string portal);

		[CCode (cname = "PQmakeEmptyPGresult")]
		public Result make_empty_result (ExecStatus status);

		[CCode (cname = "PQescapeStringConn")]
		public size_t escape_string_conn (string to, string from, size_t length, out int error);

		[CCode (cname = "PQescapeByteaConn")]
		public uchar[] escape_bytea_conn (string from, size_t from_length, out size_t to_length);

		[CCode (cname = "lo_open")]
		public int lo_open (int lobj_id, int mode);

		[CCode (cname = "lo_close")]
		public int lo_close (int fd);

		[CCode (cname = "lo_read")]
		public int lo_read (int fd, string buf, size_t len);

		[CCode (cname = "lo_write")]
		public int lo_write (int fd, string buf, size_t len);

		[CCode (cname = "lo_lseek")]
		public int lo_lseek (int fd, int offset, int whence);

		[CCode (cname = "lo_creat")]
		public int lo_creat (int mode);

		[CCode (cname = "lo_create")]
		public int lo_create (int lobj_id);

		[CCode (cname = "lo_tell")]
		public int lo_tell (int fd);

		[CCode (cname = "lo_truncate")]
		public int lo_truncate (int fd, size_t len);

		[CCode (cname = "lo_unlink")]
		public int lo_unlink (int lobj_id);

		[CCode (cname = "lo_import")]
		public int lo_import (string filename);

		[CCode (cname = "lo_export")]
		public int lo_export (int lobj_id, string filename);
	}

	[CCode (cname = "pgthreadlock_t")]
	public delegate void ThreadLockFunc (int acquire);

	[CCode (cname = "PQregisterThreadLock")]
	public ThreadLockFunc register_thread_lock (ThreadLockFunc newhandler);

	[CCode (cname = "PQunescapeBytea")]
	public uchar[] unescape_bytea (uchar[] strtext, out size_t retbuflen);

	[Compact]
	[CCode (free_function = "PQclear", cname = "PGresult", cprefix = "PQ")]
	public class Result {
		[CCode (cname = "PQresultStatus")]
		public ExecStatus get_status ();

		[CCode (cname = "PQresultErrorMessage")]
		public unowned string get_error_message ();

		[CCode (cname = "PQresultErrorField")]
		public unowned string get_error_field (FieldCode field_code);

		[CCode (cname = "PQntuples")]
		public int get_n_tuples ();

		[CCode (cname = "PQnfields")]
		public int get_n_fields ();

		[CCode (cname = "PQbinaryTuples")]
		public bool is_binary_tuples ();

		[CCode (cname = "PQfname")]
		public unowned string get_field_name (int field_num);

		[CCode (cname = "PQfnumber")]
		public int get_field_number (string field_name);

		[CCode (cname = "PQftable")]
		public Oid get_field_table (int field_num);

		[CCode (cname = "PQftablecol")]
		public int get_field_table_col (int field_num);

		[CCode (cname = "PQfformat")]
		public int get_field_format (int field_num);

		[CCode (cname = "PQftype")]
		public Oid get_field_type (int field_num);

		[CCode (cname = "PQfsize")]
		public int get_fsize (int field_num);

		[CCode (cname = "PQfmod")]
		public int get_field_mod (int field_num);

		[CCode (cname = "PQcmdStatus")]
		public unowned string get_cmd_status ();

		[CCode (cname = "PQoidValue")]
		public Oid get_oid_value ();

		[CCode (cname = "PQcmdTuples")]
		public unowned string get_cmd_tuples ();

		[CCode (cname = "PQgetvalue")]
		public unowned string get_value (int tup_num, int field_num);

		[CCode (cname = "PQgetlength")]
		public int get_length (int tup_num, int field_num);

		[CCode (cname = "PQgetisnull")]
		public bool is_null (int tup_num, int field_num);

		[CCode (cname = "PQnparams")]
		public int get_n_params ();

		[CCode (cname = "PQparamtype")]
		public int get_param_type (int param_num);
	}

	[CCode (cname = "PQfreemem")]
	public void free_mem (void* ptr);

	[CCode (cname = "PQprint")]
	public void print (GLib.FileStream fout, Result res, PrintOpt ps);

	[CCode (cname = "PQmblen")]
	public int mb_len (string s, int encoding);

	[CCode (cname = "PQdsplen")]
	public int dsp_len (string s, int encoding);

	[CCode (cname = "PQenv2encoding")]
	public int env2encoding ();

	[CCode (cname = "PQencryptPassword")]
	public unowned string encrypt_password (string passwd, string user);

	[CCode (cname = "pg_char_to_encoding")]
	public int char_to_encoding (string name);

	[CCode (cname = "pg_encoding_to_char")]
	public unowned string encoding_to_char (int encoding);

	[CCode (cname = "pg_valid_server_encoding_id")]
	public int valid_server_encoding_id (int encoding);
}

