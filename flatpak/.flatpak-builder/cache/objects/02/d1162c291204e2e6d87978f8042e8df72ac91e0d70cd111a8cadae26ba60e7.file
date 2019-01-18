/* libesmtp.vapi
 *
 * Copyright (C) 2010  Adrien Bustany
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
 * As a special exception, if you use inline functions from this file, this
 * file does not by itself cause the resulting executable to be covered by
 * the GNU Lesser General Public License.
 *
 * Author:
 * 	Adrien Bustany <abustany@gnome.org>
 */

[CCode (cheader_filename="libesmtp.h")]
namespace Smtp {
	[SimpleType]
	[CCode (cname="smtp_session_t", free_function="smtp_destroy_session", has_type_id = false)]
	public struct Session {
		[CCode (cname="smtp_create_session")]
		public Session ();

		[CCode (cname="smtp_add_message")]
		public Smtp.Message add_message ();
		[CCode (cname="smtp_enumerate_messages")]
		public int enumerate_message (EnumerateMessageCb cb);
		[CCode (cname="smtp_set_server")]
		public int set_server (string hostport);
		[CCode (cname="smtp_set_hostname")]
		public int set_hostname (string hostname);
		[CCode (cname="smtp_set_eventcb")]
		public int set_eventcb (EventCb cb);
		[CCode (cname="smtp_set_monitorcb", instance_pos="1.5")]
		public int set_monitorcb (MonitorCb cb, int headers);
		[CCode (cname="smtp_start_session")]
		public int start_session ();
		[CCode (cname="smtp_set_application_data")]
		public void* set_application_data (void *data);
		[CCode (cname="smtp_get_application_data")]
		public void* get_application_data ();
		[CCode (cname="smtp_option_require_all_recipients")]
		public int option_require_all_recipients (int state);
		[CCode (cname="smtp_auth_set_context")]
		public int auth_set_context (Smtp.AuthContext context);
		[CCode (cname="smtp_set_timeout")]
		public long set_timeout (int which, long value);
		/* Will be enabled if there are SSL bindings
		[CCode (cname="smtp_starttls_set_ctx")]
		public int starttls_set_ctx (SSL.Ctx ctx); */
		[CCode (cname="smtp_etrn_add_node")]
		public EtrnNode etrn_add_node (int option, string node);
		[CCode (cname="smtp_etrn_enumerate_nodes")]
		public int etrn_enumerate_nodes (EtrnEnumerateNodeCb cb);
	}

	[SimpleType]
	[CCode (cname="smtp_message_t", free_function="g_free", has_type_id = false)]
	public struct Message {
		[CCode (cname="smtp_set_reverse_path")]
		public int set_reverse_path (string mailbox);
		[CCode (cname="smtp_add_recipient")]
		public Smtp.Recipient add_recipient (string mailbox);
		[CCode (cname="smtp_enumerate_recipients")]
		public int enumerate_recipients (EnumerateRecipientCb cb);
		[CCode (cname="smtp_set_header", sentinel="")]
		public int set_header (string header, ...);
		[CCode (cname="smtp_set_header_option")]
		public int set_header_option (string header, Smtp.HeaderOption option, ...);
		[CCode (cname="smtp_set_resent_headers")]
		public int set_resent_headers (int onoff);
		[CCode (cname="smtp_set_messagecb")]
		public int set_messagecb (MessageCb cb);
		[CCode (cname="smtp_message_transfer_status")]
		public Smtp.Status transfer_status ();
		[CCode (cname="smtp_reverse_path_status")]
		public Smtp.Status reverse_path_status ();
		[CCode (cname="smtp_message_reset_status")]
		public static int reset_status (Smtp.Recipient recipient);
		[CCode (cname="smtp_dsn_set_ret")]
		public int dsn_set_ret (Smtp.RetFlags flags);
		[CCode (cname="smtp_dsn_set_envid")]
		public int dsn_set_envid (string envid);
		[CCode (cname="smtp_dsn_set_notify")]
		public int dsn_set_notify (NotifyFlags flags);
		[CCode (cname="smtp_dsn_set_orcpt")]
		public int dsn_set_orcpt (string address_type, string address);
		[CCode (cname="smtp_size_set_estimate")]
		public int smtp_size_set_estimate (ulong size);
		[CCode (cname="smtp_8bitmime_set_body")]
		public int @8bitmime_set_body (E8BitMimeBody body);
		[CCode (cname="smtp_deliverby_set_mode")]
		public int deliverby_set_mode (long time, ByMode mode, int trace);
		[CCode (cname="smtp_starttls_enable")]
		public int starttls_enable (StartTlsOption how);
	}

	[SimpleType]
	[CCode (cname="smtp_session_t", free_function="g_free", has_type_id = false)]
	public struct Recipient {
		[CCode (cname="smtp_recipient_check_complete")]
		public int check_complete ();
		[CCode (cname="smtp_recipient_reset_status")]
		public int reset_status ();
		[CCode (cname="smtp_recipient_set_application_data")]
		public void set_application_data (void *data);
		[CCode (cname="smtp_recipient_get_application_data")]
		public void get_application_data ();
	}

	[CCode (cname="smtp_status_t", has_type_id = false)]
	public struct Status {
		int code;
		string text;
		int enh_struct;
		int enh_subject;
		int enh_detail;
	}

	[SimpleType]
	[CCode (cname="smtp_etrn_node_t", has_type_id = false)]
	public struct EtrnNode {
		[CCode (cname="smtp_etrn_node_status")]
		public Smtp.Status node_status ();
		[CCode (cname="smtp_etrn_set_application_data")]
		public void* set_application_data (void *data);
		[CCode (cname="smtp_etrn_get_application_data")]
		public void* get_application_data ();
	}

	[SimpleType]
	[CCode (cname="auth_context_t", cheader_filename="auth-client.h", free_function="auth_destroy_context", has_type_id = false)]
	public struct AuthContext {
		[CCode (cname="auth_set_mechanism_flags")]
		public int set_mechanism_flags (uint @set, uint clear);
		[CCode (cname="auth_set_mechanism_ssf")]
		public int set_mechanism_ssf (int min_ssf);
		[CCode (cname="auth_set_interact_cb")]
		public int set_interact_cb (AuthInteract interact);
		[CCode (cname="auth_client_enabled")]
		public int client_enabled ();
		[CCode (cname="auth_set_mechanism")]
		public int set_mechanism (string name);
		[CCode (cname="auth_mechanism_name")]
		public string mechanism_name ();
		[CCode (cname="auth_response")]
		public string response (string challenge, int len);
		[CCode (cname="auth_get_ssf")]
		public int get_ssf ();
		[CCode (cname="auth_set_external_id")]
		public int set_external_id (string identity);
	}

	[CCode (cname="auth_client_request_t", cheader_filename="auth-client.h", has_type_id = false)]
	public struct AuthClientRequest {
		string name;
		uint flags;
		string prompt;
		uint size;
	}

	// the "what" parameter must be 0
	// if buf_len is not enough, SMTP_ERR_INVAL error will be set. 32 is generally enough
	[CCode (cname="smtp_version")]
	public static int version (string buf, string buf_len, int what);

	[CCode (cname="smtp_errno")]
	public static int errno ();

	[CCode (cname="smtp_strerror")]
	public static string strerror (int error, string buf, string buflen);

	[CCode (cname="auth_client_init", cheader_filename="auth-client.h")]
	public static void auth_client_init ();

	[CCode (cname="auth_client_exit", cheader_filename="auth-client.h")]
	public static void auth_client_exit ();

	[CCode (cname="auth_encode", cheader_filename="auth-client.h")]
	public static void auth_encode (out string dstbuf, out int dstlen, string srcbuf, int srclen, void *arg);

	[CCode (cname="auth_decode", cheader_filename="auth-client.h")]
	public static void auth_decode (out string dstbuf, out int dstlen, string srcbuf, int srclen, void *arg);

	[CCode (cname="auth_create_context", cheader_filename="auth-client.h")]
	public static AuthContext auth_create_context ();

	[CCode (cname="smtp_enumerate_messagecb_t")]
	public delegate void EnumerateMessageCb (Smtp.Message message);

	[CCode (cname="smtp_enumerate_recipientcb_t")]
	public delegate void EnumerateRecipientCb (Smtp.Recipient recipient, string mailbox);

	[CCode (cname="smtp_messagecb_t")]
	public delegate unowned string MessageCb (out string buf, out int len);

	[CCode (cname="smtp_eventcb_t", instance_pos="2.5")]
	public delegate void EventCb (Smtp.Session session, int event_no, ...);

	[CCode (cname="smtp_monitorcb_t")]
	public delegate void MonitorCb (string buf, int buflen, int writing);

	[CCode (cname="smtp_starttls_passwordcb_t")]
	public delegate int StartTlsPasswordCb (string buf, int buflen, int rwflag);

	[CCode (cname="smtp_etrn_enumerate_nodecb_t")]
	public delegate void EtrnEnumerateNodeCb (Smtp.EtrnNode node, int option, string domain);

	[CCode (cname="auth_interact_t", cheader_filename="auth-client.h")]
	public delegate int AuthInteract (AuthClientRequest request, out string result, int fields);

	[CCode (cname="auth_response_t", cheader_filename="auth-client.h")]
	public delegate string AuthResponse (void *ctx, string challenge, int len, AuthInteract interact);

	[CCode (cname="auth_recode_t", cheader_filename="auth-client.h", has_target=false)]
	public delegate int AuthRecode (void *ctx, out string dstbuf, out int dstlen, string srcbuf, int srclen);

	[CCode (cname="header_option", cprefix="Hdr_", has_type_id = false)]
	public enum HeaderOption {
		OVERRIDE,
		PROHIBIT
	}

	[CCode (cname="ret_flags", cprefix="Ret_", has_type_id = false)]
	public enum RetFlags {
		NOTSET,
		FULL,
		HDRS
	}

	[CCode (cname="notify_flags", cprefix="Notify_", has_type_id = false)]
	public enum NotifyFlags {
		NOTSET,
		NEVER,
		SUCCESS,
		FAILURE,
		DELAY
	}

	[CCode (cname="e8bitmime_body", cprefix="E8bitmime_", has_type_id = false)]
	public enum E8BitMimeBody {
		NOTSET,
		@7BIT,
		@8BITMIME,
		BINARYMIME
	}

	[CCode (cname="by_mode", cprefix="By_", has_type_id = false)]
	public enum ByMode {
		NOTSET,
		NOTIFY,
		RETURN
	}

	[CCode (cname="starttls_option", cprefix="Starttls_", has_type_id = false)]
	public enum StartTlsOption {
		DISABLED,
		ENABLED,
		REQUIRED
	}

	[CCode (cname="SMTP_EV_CONNECT")]
	public const uint EV_CONNECT;
	[CCode (cname="SMTP_EV_MAILSTATUS")]
	public const uint EV_MAILSTATUS;
	[CCode (cname="SMTP_EV_RCPTSTATUS")]
	public const uint EV_RCPTSTATUS;
	[CCode (cname="SMTP_EV_MESSAGEDATA")]
	public const uint EV_MESSAGEDATA;
	[CCode (cname="SMTP_EV_MESSAGESENT")]
	public const uint EV_MESSAGESENT;
	[CCode (cname="SMTP_EV_DISCONNECT")]
	public const uint EV_DISCONNECT;
	[CCode (cname="SMTP_EV_ETRNSTATUS")]
	public const uint EV_ETRNSTATUS;
	[CCode (cname="SMTP_EV_EXTNA_DSN")]
	public const uint EV_EXTNA_DSN;
	[CCode (cname="SMTP_EV_EXTNA_8BITMIME")]
	public const uint EV_EXTNA_8BITMIME;
	[CCode (cname="SMTP_EV_EXTNA_STARTTLS")]
	public const uint EV_EXTNA_STARTTLS;
	[CCode (cname="SMTP_EV_EXTNA_ETRN")]
	public const uint EV_EXTNA_ETRN;
	[CCode (cname="SMTP_EV_EXTNA_CHUNKING")]
	public const uint EV_EXTNA_CHUNKING;
	[CCode (cname="SMTP_EV_EXTNA_BINARYMIME")]
	public const uint EV_EXTNA_BINARYMIME;
	[CCode (cname="SMTP_EV_DELIVERBY_EXPIRED")]
	public const uint EV_DELIVERBY_EXPIRED;
	[CCode (cname="SMTP_EV_WEAK_CIPHER")]
	public const uint EV_WEAK_CIPHER;
	[CCode (cname="SMTP_EV_STARTTLS_OK")]
	public const uint EV_STARTTLS_OK;
	[CCode (cname="SMTP_EV_INVALID_PEER_CERTIFICATE")]
	public const uint EV_INVALID_PEER_CERTIFICATE;
	[CCode (cname="SMTP_EV_NO_PEER_CERTIFICATE")]
	public const uint EV_NO_PEER_CERTIFICATE;
	[CCode (cname="SMTP_EV_WRONG_PEER_CERTIFICATE")]
	public const uint EV_WRONG_PEER_CERTIFICATE;
	[CCode (cname="SMTP_EV_NO_CLIENT_CERTIFICATE")]
	public const uint EV_NO_CLIENT_CERTIFICATE;
	[CCode (cname="SMTP_EV_UNUSABLE_CLIENT_CERTIFICATE")]
	public const uint EV_UNUSABLE_CLIENT_CERTIFICATE;
	[CCode (cname="SMTP_EV_UNUSABLE_CA_LIST")]
	public const uint EV_UNUSABLE_CA_LIST;

	[CCode (cname="Timeout_OVERRIDE_RFC2822_MINIMUM")]
	public const long TIMEOUT_OVERRIDE_RFC2822_MINIMUM;

	[CCode (cname="SMTP_ERR_NOTHING_TO_DO")]
	public const uint ERR_NOTHING_TO_DO;
	[CCode (cname="SMTP_ERR_DROPPED_CONNECTION")]
	public const uint ERR_DROPPED_CONNECTION;
	[CCode (cname="SMTP_ERR_INVALID_RESPONSE_SYNTAX")]
	public const uint ERR_INVALID_RESPONSE_SYNTAX;
	[CCode (cname="SMTP_ERR_STATUS_MISMATCH")]
	public const uint ERR_STATUS_MISMATCH;
	[CCode (cname="SMTP_ERR_INVALID_RESPONSE_STATUS")]
	public const uint ERR_INVALID_RESPONSE_STATUS;
	[CCode (cname="SMTP_ERR_INVAL")]
	public const uint ERR_INVAL;
	[CCode (cname="SMTP_ERR_EXTENSION_NOT_AVAILABLE")]
	public const uint ERR_EXTENSION_NOT_AVAILABLE;
	[CCode (cname="SMTP_ERR_HOST_NOT_FOUND")]
	public const uint ERR_HOST_NOT_FOUND;
	[CCode (cname="SMTP_ERR_NO_ADDRESS")]
	public const uint ERR_NO_ADDRESS;
	[CCode (cname="SMTP_ERR_NO_RECOVERY")]
	public const uint ERR_NO_RECOVERY;
	[CCode (cname="SMTP_ERR_TRY_AGAIN")]
	public const uint ERR_TRY_AGAIN;
	[CCode (cname="SMTP_ERR_EAI_AGAIN")]
	public const uint ERR_EAI_AGAIN;
	[CCode (cname="SMTP_ERR_EAI_FAIL")]
	public const uint ERR_EAI_FAIL;
	[CCode (cname="SMTP_ERR_EAI_MEMORY")]
	public const uint ERR_EAI_MEMORY;
	[CCode (cname="SMTP_ERR_EAI_ADDRFAMILY")]
	public const uint ERR_EAI_ADDRFAMILY;
	[CCode (cname="SMTP_ERR_EAI_NODATA")]
	public const uint ERR_EAI_NODATA;
	[CCode (cname="SMTP_ERR_EAI_FAMILY")]
	public const uint ERR_EAI_FAMILY;
	[CCode (cname="SMTP_ERR_EAI_BADFLAGS")]
	public const uint ERR_EAI_BADFLAGS;
	[CCode (cname="SMTP_ERR_EAI_NONAME")]
	public const uint ERR_EAI_NONAME;
	[CCode (cname="SMTP_ERR_EAI_SERVICE")]
	public const uint ERR_EAI_SERVICE;
	[CCode (cname="SMTP_ERR_EAI_SOCKTYPE")]
	public const uint ERR_EAI_SOCKTYPE;
	[CCode (cname="SMTP_ERR_UNTERMINATED_RESPONSE")]
	public const uint ERR_UNTERMINATED_RESPONSE;
	[CCode (cname="SMTP_ERR_CLIENT_ERROR")]
	public const uint ERR_CLIENT_ERROR;
	[CCode (cname="SMTP_CB_READING")]
	public const uint CB_READING;
	[CCode (cname="SMTP_CB_WRITING")]
	public const uint CB_WRITING;
	[CCode (cname="SMTP_CB_HEADERS")]
	public const uint CB_HEADERS;

	[CCode (cname="AUTH_USER", cheader_filename="auth-client.h")]
	public static uint AUTH_USER;
	[CCode (cname="AUTH_REALM", cheader_filename="auth-client.h")]
	public static uint AUTH_REALM;
	[CCode (cname="AUTH_PASS", cheader_filename="auth-client.h")]
	public static uint AUTH_PASS;

	[CCode (cname="AUTH_PLUGIN_ANONYMOUS", cheader_filename="auth-client.h")]
	public static uint AUTH_PLUGIN_ANONYMOUS;
	[CCode (cname="AUTH_PLUGIN_PLAIN", cheader_filename="auth-client.h")]
	public static uint AUTH_PLUGIN_PLAIN;
	[CCode (cname="AUTH_PLUGIN_EXTERNAL", cheader_filename="auth-client.h")]
	public static uint AUTH_PLUGIN_EXTERNAL;
}
