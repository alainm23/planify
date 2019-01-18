/*
 * gnet-2.0 bindings
 * Copyright (C) 2009 Michael B. Trausch <mike@trausch.us>
 * License: GNU LGPL v2.1 as published by the Free Software Foundation.
 *
 * Part of the Vala compiler system.
 *
 * Note that as of GLib 2.22, gnet-2.0 will be deprecated, so software using
 * gnet-2.0 will not be forward compatible to GLib 3.0.  Also, the async
 * methods are mostly unimplemented in these bindings, and these bindings are
 * currently untested.  Please improve them.
 *
 * There are nearly certainly bound to be bugs in here.  What I did was just
 * read the header files for glib-2.0 and re-create as much of them as I could
 * here.  However, some things (such as when a "gchar *" in the header means
 * a char[] over a string) may be incorrect.  Someone who has used the gnet-2.0
 * libraries and who is familiar with Vala ought to review these bindings.
 */
[CCode(cprefix = "G", lower_case_cprefix = "gnet_",
	   cheader_filename = "gnet.h")]
namespace GNet {
	public static void init();

	[Compact]
	[CCode(free_function = "gnet_inetaddr_delete",
		   ref_function = "gnet_inetaddr_ref",
		   unref_function = "gnet_inetaddr_unref")]
	public class InetAddr {
		[CCode(cname = "GNET_INETADDR_MAX_LEN")]
		public const uint8 MAX_BYTES;

		[CCode(cname = "gnet_inetaddr_new_list")]
		public static GLib.List<InetAddr> new_list(string hostname, int port);
		[CCode(cname = "gnet_inetaddr_delete_list")]
		public static void delete_list(GLib.List<InetAddr> list);

		[CCode(cname = "gnet_inetaddr_is_canonical")]
		public static bool is_canonical(string hostname);

		[CCode(cname = "gnet_inetaddr_equal")]
		public static bool equal(InetAddr a1, InetAddr a2);
		[CCode(cname = "gnet_inetaddr_noport_equal")]
		public static bool noport_equal(InetAddr a1, InetAddr a2);

		[CCode(cname = "gnet_inetaddr_hash")]
		public static uint hash(InetAddr a);

		[CCode(cname = "gnet_inetaddr_get_host_name")]
		public static string get_host_name();
		[CCode(cname = "gnet_inetaddr_get_host_addr")]
		public static InetAddr get_host_addr();

		[CCode(cname = "gnet_inetaddr_autodetect_internet_interface")]
		public static InetAddr autodetect_internet_interface();
		[CCode(cname = "gnet_inetaddr_get_internet_interface")]
		public static InetAddr get_internet_interface();
		[CCode(cname = "gnet_inetaddr_get_interface_to")]
		public static InetAddr get_interface_to(InetAddr dest);

		[CCode(cname = "gnet_inetaddr_is_internet_domainname")]
		public static bool is_internet_domainname(string domain);

		[CCode(cname = "gnet_inetaddr_list_interfaces")]
		public static GLib.List<InetAddr> list_interfaces();

		[CCode(cname = "gnet_inetaddr_new")]
		public InetAddr(string hostname, int port);
		[CCode(cname = "gnet_inetaddr_new_nonblock")]
		public InetAddr.nonblock(string hostname, int port);
		[CCode(cname = "gnet_inetaddr_new_bytes")]
		public InetAddr.bytes(char[] bytes);

		[CCode(cname = "gnet_inetaddr_clone")]
		public InetAddr clone();

		[CCode(cname = "gnet_inetaddr_get_name")]
		public string get_name();
		[CCode(cname = "gnet_inetaddr_get_name_nonblock")]
		public string get_name_nonblock();

		[CCode(cname = "gnet_inetaddr_get_length")]
		public int get_length();

		[CCode(cname = "gnet_inetaddr_get_bytes")]
		public void get_bytes(out string buffer);
		[CCode(cname = "gnet_inetaddr_set_bytes")]
		public void set_bytes(char[] bytes);

		[CCode(cname = "gnet_inetaddr_get_canonical_name")]
		public string get_canonical_name();

		// Can these be bound as a "port" property?
		[CCode(cname = "gnet_inetaddr_get_port")]
		public int get_port();
		[CCode(cname = "gnet_inetaddr_set_port")]
		public void set_port(int port);

		[CCode(cname = "gnet_inetaddr_is_internet")]
		public bool is_internet();
		[CCode(cname = "gnet_inetaddr_is_private")]
		public bool is_private();
		[CCode(cname = "gnet_inetaddr_is_reserved")]
		public bool is_reserved();
		[CCode(cname = "gnet_inetaddr_is_loopback")]
		public bool is_loopback();
		[CCode(cname = "gnet_inetaddr_is_multicast")]
		public bool is_multicast();
		[CCode(cname = "gnet_inetaddr_is_broadcast")]
		public bool is_broadcast();

		[CCode(cname = "gnet_inetaddr_is_ipv4")]
		public bool is_ipv4();
		[CCode(cname = "gnet_inetaddr_is_ipv6")]
		public bool is_ipv6();
	}

	public class IOChannel {
		[CCode(name = "gnet_io_channel_writen")]
		public static GLib.IOError writen(GLib.IOChannel chan, string buf,
										  size_t len, out size_t bytes_written);

		[CCode(name = "gnet_io_channel_readn")]
		public static GLib.IOError readn(GLib.IOChannel chan, string buf,
										 size_t len, out size_t bytes_read);
		[CCode(name = "gnet_io_channel_readline")]
		public static GLib.IOError readline(GLib.IOChannel chan, string buf,
											size_t len, out size_t bytes_read);
		[CCode(name = "gnet_io_channel_readline_strdup")]
		public static GLib.IOError readline_strdup(GLib.IOChannel chan,
												   out string buf,
												   size_t bytes_read);
	}

	[Compact]
	[CCode(free_function = "gnet_udp_socket_delete",
		   ref_function = "gnet_udp_socket_ref",
		   unref_function = "gnet_udp_socket_unref")]
	public class UdpSocket {
		[CCode(cname = "gnet_udp_socket_new")]
		public UdpSocket();
		[CCode(cname = "gnet_udp_socket_new_with_port")]
		public UdpSocket.with_port(int port);
		[CCode(cname = "gnet_udp_socket_new_full")]
		public UdpSocket.full(InetAddr iface, int port);

		[CCode(cname = "gnet_udp_socket_get_io_channel")]
		public GLib.IOChannel get_io_channel();
		[CCode(cname = "gnet_udp_socket_get_local_inetaddr")]
		public InetAddr get_local_inetaddr();

		[CCode(cname = "gnet_udp_socket_send")]
		public int send(string buf, int len, InetAddr dest);
		[CCode(cname = "gnet_udp_socket_receive")]
		public int receive(string buf, int len, InetAddr src);
		[CCode(cname = "gnet_udp_socket_has_packet")]
		public bool has_packet();

		[CCode(cname = "gnet_udp_socket_get_ttl")]
		public int get_ttl();
		[CCode(cname = "gnet_udp_socket_set_ttl")]
		public int set_ttl(int ttl);
	}

	public enum NetTOS {
		NONE,
		LOWDELAY,
		THROUGHPUT,
		RELIABILITY,
		LOWCOST
	}

	[Compact]
	[CCode(free_function = "gnet_tcp_socket_delete",
		   ref_function = "gnet_tcp_socket_ref",
		   unref_function = "gnet_tcp_socket_unref")]
	public class TcpSocket {
		[CCode(cname = "gnet_tcp_socket_connect")]
		public static TcpSocket connect(string hostname, int port);

		[CCode(cname = "gnet_tcp_socket_new")]
		public TcpSocket(InetAddr addr);
		[CCode(cname = "gnet_tcp_socket_new_direct")]
		public TcpSocket.direct(InetAddr addr);

		[CCode(cname = "gnet_tcp_socket_get_io_channel")]
		public GLib.IOChannel get_io_channel();
		[CCode(cname = "gnet_tcp_socket_get_remote_inetaddr")]
		public InetAddr get_remote_inetaddr();
		[CCode(cname = "gnet_tcp_socket_get_local_inetaddr")]
		public InetAddr get_local_inetaddr();
	}

	[Compact]
	[CCode(free_function = "gnet_tcp_socket_delete",
		   ref_function = "gnet_tcp_socket_ref",
		   unref_function = "gnet_tcp_socket_unref",
		   cname = "GTcpSocket*")]
	public class TcpServerSocket {
		[CCode(cname = "gnet_tcp_socket_server_new")]
		public TcpServerSocket();
		[CCode(cname = "gnet_tcp_socket_server_new_with_port")]
		public TcpServerSocket.with_port(int port);
		[CCode(cname = "gnet_tcp_socket_server_new_full")]
		public TcpServerSocket.full(InetAddr iface, int port);

		[CCode(cname = "gnet_tcp_socket_server_accept")]
		public TcpSocket accept();
		[CCode(cname = "gnet_tcp_socket_server_accept_nonblock")]
		public TcpSocket accept_nonblock();

		[CCode(cname = "gnet_tcp_socket_get_port")]
		public int get_port();
	}

	[Compact]
	[CCode(free_function = "gnet_mcast_socket_delete",
		   ref_function = "gnet_mcast_socket_ref",
		   unref_function = "gnet_mcast_socket_unref",
		   cname = "GMcastSocket*")]
	public class MulticastSocket {
		[CCode(cname = "gnet_mcast_socket_new")]
		public MulticastSocket();
		[CCode(cname = "gnet_mcast_socket_new_with_port")]
		public MulticastSocket.with_port(int port);
		[CCode(cname = "gnet_mcast_socket_new_full")]
		public MulticastSocket.full(InetAddr iface, int port);

		[CCode(cname = "gnet_mcast_socket_get_io_channel")]
		public GLib.IOChannel get_io_channel();
		[CCode(cname = "gnet_mcast_socket_get_local_inetaddr")]
		public GLib.IOChannel get_local_inetaddr();

		[CCode(cname = "gnet_mcast_socket_join_group")]
		public int join_group(InetAddr addr);
		[CCode(cname = "gnet_mcast_socket_leave_group")]
		public int leave_group(InetAddr addr);

		[CCode(cname = "gnet_mcast_socket_get_ttl")]
		public int get_ttl();
		[CCode(cname = "gnet_mcast_socket_set_ttl")]
		public int set_ttl(int ttl);

		[CCode(cname = "gnet_mcast_socket_is_loopback")]
		public int is_loopback();
		[CCode(cname = "gnet_mcast_socket_set_loopback")]
		public int set_loopback(bool enable);

		[CCode(cname = "gnet_mcast_socket_send")]
		public int send(string buf, int len, InetAddr dst);
		[CCode(cname = "gnet_mcast_socket_receive")]
		public int receive(string buf, int len, InetAddr src);
		[CCode(cname = "gnet_mcast_socket_has_packet")]
		public bool has_packet();

		[CCode(cname = "gnet_mcast_socket_to_udp_socket")]
		public UdpSocket to_udp_socket();
	}

	#if GNET_EXPERIMENTAL
	public class Socks {
		[CCode(cname = "GNET_SOCKS_PORT")]
		public const int SOCKS_PORT;

		[CCode(cname = "GNET_SOCKS_VERSION")]
		public const int SOCKS_VERSION;

		[CCode(cname = "gnet_socks_get_enabled")]
		public static bool get_enabled();
		[CCode(cname = "gnet_socks_set_enabled")]
		public static void set_enabled();

		[CCode(cname = "gnet_socks_get_server")]
		public static InetAddr get_server();
		[CCode(cname = "gnet_socks_set_server")]
		public static void set_server(InetAddr inetaddr);

		[CCode(cname = "gnet_socks_get_version")]
		public static int get_version();
		[CCode(cname = "gnet_socks_set_version")]
		public static void set_version(int version);
	}
	#endif

	public class Pack {
		[CCode(cname = "gnet_pack")]
		[PrintfFormat]
		public static int pack(string format, string buf, int len, ...);
		[CCode(cname = "gnet_pack_strdup")]
		[PrintfFormat]
		public static int pack_strdup(string format, out string buf, ...);

		[CCode(cname = "gnet_calcsize")]
		[PrintfFormat]
		public static int calcsize(string format, ...);

		[CCode(cname = "gnet_unpack")]
		public static int unpack(string format, string buf, int len, ...);
	}

	[Compact]
	[CCode(free_function = "gnet_uri_delete",
		   ref_function = "g_object_ref",
		   unref_function = "g_object_unref")]
	public class URI {
		public string scheme;
		public string userinfo;
		public string hostname;
		public int port;
		public string path;
		public string query;
		public string fragment;

		[CCode(cname = "gnet_uri_equal")]
		public static bool equal(URI u1, URI u2);
		[CCode(cname = "gnet_uri_hash")]
		public static uint hash(URI u);

		// If I understand this right, u should be allocated, but not setup.
		[CCode(cname = "gnet_uri_parse_inplace")]
		public static bool parse_inplace(URI* u,
										 string uri, string hostname, int len);

		[CCode(cname = "gnet_uri_new")]
		public URI(string uri);
		[CCode(cname = "gnet_uri_new_fields")]
		public URI.fields(string scheme, string hostname, int port,
						  string path);
		[CCode(cname = "gnet_uri_new_fields_all")]
		public URI.fields_all(string scheme, string userinfo, string hostname,
							  int port, string path, string query,
							  string fragment);

		[CCode(cname = "gnet_uri_clone")]
		public URI clone();

		[CCode(cname = "gnet_uri_escape")]
		public void escape();
		[CCode(cname = "gnet_uri_unescape")]
		public void unescape();

		[CCode(cname = "gnet_uri_get_string")]
		public string get_string();
		[CCode(cname = "gnet_uri_get_string")]
		public string to_string();

		[CCode(cname = "gnet_uri_set_scheme")]
		public void set_scheme(string scheme);
		[CCode(cname = "gnet_uri_set_userinfo")]
		public void set_userinfo(string userinfo);
		[CCode(cname = "gnet_uri_set_hostname")]
		public void set_hostname(string hostname);
		[CCode(cname = "gnet_uri_set_port")]
		public void set_port(int port);
		[CCode(cname = "gnet_uri_set_path")]
		public void set_path(string path);
		[CCode(cname = "gnet_uri_set_query")]
		public void set_query(string query);
		[CCode(cname = "gnet_uri_set_fragment")]
		public void set_fragment(string fragment);
	}

	public enum ConnHttpHeaderFlags {
		[CCode(cname = "GNET_CONN_HTTP_FLAG_SKIP_HEADER_CHECK")]
		SKIP_HEADER_CHECK = 1
	}

	public enum ConnHttpMethod {
		GET,
		POST
	}

	[CCode(cname = "GConnHttpError",
		   cprefix = "GNET_CONN_HTTP_ERROR_")]
	public errordomain HttpError {
		UNSPECIFIED,
		PROTOCOL_UNSUPPORTED,
		HOSTNAME_RESOLUTION
	}

	[CCode(cname = "GConnHttpEventType", cprefix="GNET_CONN_HTTP_")]
	public enum HttpEventType {
		RESOLVED,
		CONNECTED,
		RESPONSE,
		REDIRECT,
		DATA_PARTIAL,
		DATA_COMPLETE,
		TIMEOUT,
		ERROR
	}

	public struct ConnHttpEvent {
		public HttpEventType type;
	}

	public struct ConnHttpEventResolved {
		public InetAddr ia;
	}

	public struct ConnHttpEventRedirect {
		public uint num_redirects;
		public uint max_redirects;
		public string new_location;
		public bool auto_redirect;
	}

	public struct ConnHttpEventResponse {
		public uint response_code;
		public string[] header_fields;
		public string[] header_values;
	}

	public struct ConnHttpEventData {
		public uint64 content_length;
		public uint64 data_received;
		public string buf;
		public size_t buf_len;
	}

	public struct ConnHttpEventError {
		public HttpError code;
		public string message;
	}

	public delegate void ConnHttpFunc(ConnHttp c, ConnHttpEvent event);

	[Compact]
	[CCode(free_function = "gnet_conn_http_delete",
		   ref_function = "g_object_ref",
		   unref_function = "g_object_unref")]
	public class ConnHttp {
		[CCode(cname = "gnet_http_get")]
		public static bool do_get(string url, out string buf, out size_t len,
								  out uint response);

		[CCode(cname = "gnet_conn_http_new")]
		public ConnHttp();

		[CCode(cname = "gnet_conn_http_set_uri")]
		public bool set_uri(string uri);
		[CCode(cname = "gnet_conn_http_set_escaped_uri")]
		public bool set_escaped_uri(string uri);

		[CCode(cname = "gnet_conn_http_set_header")]
		public bool set_header(string field, string value,
							   ConnHttpHeaderFlags flags);

		[CCode(cname = "gnet_conn_http_set_max_redirects")]
		public void set_max_redirects(uint num);

		[CCode(cname = "gnet_conn_http_set_timeout")]
		public void set_timeout(uint timeout);

		[CCode(cname = "gnet_conn_http_set_user_agent")]
		public bool set_user_agent(string agent);

		[CCode(cname = "gnet_conn_http_set_method")]
		public bool set_method(ConnHttpMethod method, string post_data,
							   size_t post_data_len);

		[CCode(cname = "gnet_conn_http_set_main_context")]
		public bool set_main_context(GLib.MainContext ctx);

		[CCode(cname = "gnet_conn_http_run")]
		public bool run(ConnHttpFunc f);

		[CCode(cname = "gnet_conn_http_steal_buffer")]
		public bool steal_buffer(out string buf, out size_t len);

		[CCode(cname = "gnet_conn_http_cancel")]
		public void cancel();
	}

	[CCode(cname = "GConnEventType", cprefix="GNET_CONN_")]
	public enum ConnEventType {
		ERROR,
		CONNECT,
		CLOSE,
		TIMEOUT,
		READ,
		WRITE,
		READABLE,
		WRITABLE
	}

	public struct ConnEvent {
		public ConnEventType type;
		public string buffer;
		public int length;
	}

	public delegate void ConnFunc(Conn c, ConnEvent evt);

	[Compact]
	[CCode(free_function = "gnet_conn_delete",
		   ref_function = "gnet_conn_ref",
		   unref_function = "gnet_conn_unref")]
	public class Conn {
		[CCode(cname = "gnet_conn_new")]
		public Conn(string hostname, int port, ConnFunc cf);
		[CCode(cname = "gnet_conn_new_inetaddr")]
		public Conn.inetaddr(InetAddr inetaddr, ConnFunc cf);
		[CCode(cname = "gnet_conn_new_socket")]
		public Conn.socket(TcpSocket s, ConnFunc cf);

		[CCode(cname = "gnet_conn_set_callback")]
		public void set_callback(ConnFunc cf);
		[CCode(cname = "gnet_conn_set_callback")]
		public void set_delegate(ConnFunc cf);

		[CCode(cname = "gnet_conn_set_main_context")]
		public bool set_main_context(GLib.MainContext ctx);

		[CCode(cname = "gnet_conn_connect")]
		public void connect();
		[CCode(cname = "gnet_conn_disconnect")]
		public void disconnect();
		[CCode(cname = "gnet_conn_is_connected")]
		public bool is_connected();

		[CCode(cname = "gnet_conn_read")]
		public void read();
		[CCode(cname = "gnet_conn_readn")]
		public void readn(int len);
		[CCode(cname = "gnet_conn_readline")]
		public void readline();

		[CCode(cname = "gnet_conn_write")]
		public void write(string buf, int len);
		[CCode(cname = "gnet_conn_write_direct")]
		public void write_direct(string buf, int len,
								 GLib.DestroyNotify buffer_destroy_cb);

		[CCode(cname = "gnet_conn_set_watch_readable")]
		public void set_watch_readable(bool enable);
		[CCode(cname = "gnet_conn_set_watch_writable")]
		public void set_watch_writable(bool enable);
		[CCode(cname = "gnet_conn_set_watch_error")]
		public void set_watch_error(bool enable);

		[CCode(cname = "gnet_conn_timeout")]
		public void timeout(uint timeout);
	}

	public delegate void ServerFunc(Server s, Conn c);

	[Compact]
	[CCode(free_function = "gnet_server_delete",
		   ref_function = "gnet_server_ref",
		   unref_function = "gnet_server_unref")]
	public class Server {
		public InetAddr iface;
		public int port;
		public TcpSocket socket;
		public uint ref_count;
		public ServerFunc func;
		public void* user_data;

		[CCode(cname = "gnet_server_new")]
		public Server(InetAddr iface, int port, ServerFunc f);
	}

	[Compact]
	[CCode(free_function = "gnet_md5_delete",
		   ref_function = "g_object_ref",
		   unref_function = "g_object_unref")]
	public class MD5 {
		[CCode(cname = "GNET_MD5_HASH_LENGTH")]
		public const int HASH_LENGTH;

		[CCode(cname = "gnet_md5_equal")]
		public static bool equal(MD5 m1, MD5 m2);
		[CCode(cname = "gnet_md5_hash")]
		public static uint hash(MD5 m);

		[CCode(cname = "gnet_md5_new_incremental")]
		public MD5();
		[CCode(cname = "gnet_md5_new")]
		public MD5.buf(char[] buf);
		[CCode(cname = "gnet_md5_new_string")]
		public MD5.str(string buf);

		[CCode(cname = "gnet_md5_clone")]
		public MD5 clone();

		[CCode(cname = "gnet_md5_update")]
		public void update(char[] buf);
		[CCode(cname = "gnet_md5_final")]
		public void final();

		[CCode(cname = "gnet_md5_get_digest")]
		public string get_digest();
		[CCode(cname = "gnet_md5_get_string")]
		public string get_string();

		[CCode(cname = "gnet_md5_copy_string")]
		public void copy_string(string buf);
	}

	[Compact]
	[CCode(free_function = "gnet_sha_delete",
		   ref_function = "g_object_ref",
		   unref_function = "g_object_unref")]
	public class SHA {
		[CCode(cname = "GNET_SHA_HASH_LENGTH")]
		public const int HASH_LENGTH;

		[CCode(cname = "gnet_sha_equal")]
		public static bool equal(SHA s1, SHA s2);
		[CCode(cname = "gnet_sha_hash")]
		public static uint hash(SHA s);

		[CCode(cname = "gnet_sha_new_incremental")]
		public SHA();
		[CCode(cname = "gnet_sha_new")]
		public SHA.buf(char[] buf);
		[CCode(cname = "gnet_sha_new_string")]
		public SHA.str(string buf);

		[CCode(cname = "gnet_sha_update")]
		public void update(char[] buf);
		[CCode(cname = "gnet_sha_final")]
		public void final();

		[CCode(cname = "gnet_sha_clone")]
		public SHA clone();

		[CCode(cname = "gnet_sha_get_digest")]
		public string get_digest();
		[CCode(cname = "gnet_sha_get_string")]
		public string get_string();

		[CCode(cname = "gnet_sha_copy_string")]
		public void copy_string(string buf);
	}

	[CCode(cname = "GIPv6Policy", cprefix = "GIPV6_POLICY_")]
	public enum IPv6Policy {
		IPV4_THEN_IPV6,
		IPV6_THEN_IPV4,
		IPV4_ONLY,
		IPV6_ONLY
	}

	public class IPv6 {
		[CCode(cname = "gnet_ipv6_get_policy")]
		public static IPv6Policy get_policy();

		[CCode(cname = "gnet_ipv6_set_policy")]
		public static void set_policy(IPv6Policy policy);
	}

	public class Base64 {
		[CCode(cname = "gnet_base64_encode")]
		public static string encode(char[] src, out int dstlen, bool strict);
		[CCode(cname = "gnet_base64_decode")]
		public static string decode(char[] src, out int dstlen);
	}
}
