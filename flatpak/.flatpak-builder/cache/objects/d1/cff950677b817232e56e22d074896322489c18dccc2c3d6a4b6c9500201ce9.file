/*
 * libnl-3.0.vapi
 *
 * Copyright (C) 2009-2015 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
 * Copyright (C) 2011 Klaus Kurzmann <mok@fluxnetz.de>
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
 */

[CCode (lower_case_cprefix = "nl_", cheader_filename = "netlink/netlink.h")]
namespace Netlink {

    [CCode (cname = "nl_geterror", cheader_filename = "netlink/netlink.h")]
    public static unowned string strerror( int number );

    [CCode (instance_pos = -1)]
    public delegate void CallbackFunc (Object obj);

    [CCode (cname = "nl_recmsg_msg_cb_t", cheader_filename = "netlink/netlink.h", instance_pos = -1)]
    public delegate int MessageCallbackFunc (Message msg);

    [Compact]
    [CCode (cprefix = "rtnl_addr_", cname = "struct nl_addr", free_function = "", cheader_filename = "netlink/netlink.h")]
    public class Address : Object {
        [CCode (cname = "nl_addr_alloc")]
        public Address();

        public void     put();
        public int      build_add_request (int a, out Message m);
        public int      build_delete_request (int a, out Message m);

        public int      set_label (string label);
        public unowned string   get_label ();

        public void     set_family (int family);
        public int      get_family ();


        public Netlink.Address? get_local();
        public Netlink.Address? get_peer();
        public Netlink.Address? get_broadcast();
        public Netlink.Address? get_anycast();
        public Netlink.Address? get_multicast();

        public void     set_prefixlen (int len);
        public int      get_prefixlen ();

        public int      get_ifindex();
        public int      get_scope();

        public void     set_flags (int flags);
        public void     unset_flags (int flags);
        public int     get_flags ();

        [CCode (cname = "nl_addr_get_len")]
        public int      get_len();

        [CCode (cname = "nl_addr_get_binary_addr")]
        public void*    get_binary_addr();

        [CCode (cname = "nl_addr2str")]
        public unowned string to_stringbuf(char[] buf);

        public string to_string() {
            char[] buf = new char[256];
            return to_stringbuf( buf );
        }
    }

    [Compact]
    [CCode (cprefix = "nla_", cname = "struct nlattr", free_function = "", cheader_filename = "netlink/netlink.h")]
    public class Attribute {
        public static int       attr_size (int payload);
        public static int       total_size (int payload);
        public static int       padlen (int payload);

        public int              type();
        public void*            data();
        public int              len();
        public int              ok (int remaining);
        public Attribute        next (out int remaining);
        public static int       parse (Attribute[] attributes, Attribute head, int len, AttributePolicy? policy = null);
        public int              validate (int len, int maxtype, AttributePolicy? policy = null);
        public Attribute        find (int len, int attrtype);
    }

    [Compact]
    [CCode (cname = "struct nla_policy", free_function = "")]
    public class AttributePolicy {
        [CCode (cname = "")]
        public AttributePolicy( AttributeType type = AttributeType.UNSPEC, uint16 minlen = 0, uint16 maxlen = 65535 )
        {
            this.type = type;
            this.minlen = minlen;
            this.maxlen = maxlen;
        }
        public uint16    type;
        public uint16    minlen;
        public uint16    maxlen;
    }

    [CCode (cprefix = "NLA_", cname = "int", cheader_filename = "netlink/attr.h", has_type_id = false)]
    public enum AttributeType {
        UNSPEC,     // Unspecified type, binary data chunk
        U8,         // 8 bit integer
        U16,        // 16 bit integer
        U32,        // 32 bit integer
        U64,        // 64 bit integer
        STRING,     // NUL terminated character string
        FLAG,       // Flag
        MSECS,      // Micro seconds (64bit)
        NESTED,     // Nested attributes
        TYPE_MAX
    }

    [Compact]
    [CCode (cprefix = "rtnl_addr_", cname = "struct rtnl_addr", free_function = "", cheader_filename = "netlink/route/addr.h")]
    public class RouteAddress : Address {
        [CCode (cname = "rtnl_addr_alloc")]
        public RouteAddress();

        public void     set_ifindex (int index );
        public int      get_ifindex ();

        public void     set_scope (int scope);
        public int      get_scope ();

        public unowned Address get_local();
    }

    [Compact]
    [CCode (cprefix = "nl_cache_", cname = "struct nl_cache", free_function = "nl_cache_free", cheader_filename = "netlink/netlink.h")]
    public class Cache {
        public static int alloc_name (string name, out Cache c);

        public void @foreach (CallbackFunc cb);
        public void foreach_filter (Object obj, CallbackFunc cb);

        public void  mngt_provide();
        public void  mngt_unprovide();
    }

    [CCode (cname = "int", cprefix = "NL_ACT_", has_type_id = false, cheader_filename = "netlink/cache.h")]
    public enum CacheAction {
        NEW,
        DEL,
        GET,
        SET,
        CHANGE,
    }

    [CCode (cname = "change_func_t", cheader_filename = "netlink/cache.h", instance_pos = -1)]
    public delegate void ChangeCallbackFunc (Cache cache, Object obj, CacheAction act);

    [Compact]
    [CCode (cprefix = "nl_cache_mngr_", cname = "struct nl_cache_mngr", free_function = "nl_cache_mngr_free", cheader_filename = "netlink/cache.h")]
    public class CacheManager {
        public static int alloc (Socket? sk, int protocol, int flags, out CacheManager c);

        public int add_cache(Cache cache, ChangeCallbackFunc cb);
        public int add(string name, ChangeCallbackFunc cb, out unowned Cache cache);

        public int get_fd();
        public int poll(int timeout);

        public int data_ready();
        public void info(DumpParams params);
    }


    [Compact]
    [CCode (cprefix = "nl_cb_", cname = "struct nl_cb", free_function = "", cheader_filename = "netlink/netlink.h")]
    public class Callback {
        [CCode (cname = "nl_cb_alloc")]
        public Callback (CallbackKind kind = CallbackKind.DEFAULT);
        [CCode (cname = "nl_cb_set")]
        public int @set (CallbackType type, CallbackKind kind, MessageCallbackFunc func);
        [CCode (cname = "nl_cb_set_all")]
        public int set_all (CallbackKind kind, MessageCallbackFunc func);
    }

    [CCode (cname = "enum nl_cb_action", cprefix = "NL_", cheader_filename = "netlink/netlink.h", has_type_id = false)]
    public enum CallbackAction {
        OK,         //   Proceed with whatever comes next.
        SKIP,       //   Skip this message.
        STOP,       //   Stop parsing altogether and discard remaining messages.
    }

    [CCode (cname = "enum nl_cb_kind", cprefix = "NL_CB_", cheader_filename = "netlink/netlink.h", has_type_id = false)]
    public enum CallbackKind {
        DEFAULT,    // 	 Default handlers (quiet).
        VERBOSE,    // 	 Verbose default handlers (error messages printed).
        DEBUG,      // 	 Debug handlers for debugging.
        CUSTOM,     // 	 Customized handler specified by the user.
    }

    [CCode (cname = "enum nl_cb_type", cprefix = "NL_CB_", cheader_filename = "netlink/netlink.h", has_type_id = false)]
    public enum CallbackType {
        VALID,      // 	 Message is valid.
        FINISH,     // 	 Last message in a series of multi part messages received.
        OVERRUN,    // 	 Report received that data was lost.
        SKIPPED,    // 	 Message wants to be skipped.
        ACK,        // 	 Message is an acknowledge.
        MSG_IN,     // 	 Called for every message received.
        MSG_OUT,    // 	 Called for every message sent out except for nl_sendto().
        INVALID,    // 	 Message is malformed and invalid.
        SEQ_CHECK,  // 	 Called instead of internal sequence number checking.
        SEND_ACK,   // 	 Sending of an acknowledge message has been requested.
    }

    [Compact]
    [CCode (cprefix = "nl_link_cache_", cname = "struct nl_cache", free_function = "nl_cache_free", cheader_filename = "netlink/netlink.h")]
    public class LinkCache : Cache
    {
        [CCode (cname = "rtnl_link_name2i")]
        public int name2i (string name);
        [CCode (cname = "rtnl_link_i2name")]
        public unowned string i2name( int idx, char[] buffer );
        [CCode (cname = "rtnl_link_get")]
        public CachedLink? get(int idx);
        [CCode (cname = "rtnl_link_get_by_name")]
        public CachedLink? get_by_name(string idx);
    }

    [Compact]
    [CCode (cprefix = "nl_addr_cache", cname = "struct nl_cache", free_function = "nl_cache_free", cheader_filename = "netlink/netlink.h")]
    public class AddrCache : Cache
    {
    }

    [Compact]
    [CCode (cprefix = "nl_msg_", cname = "struct nl_msg", free_function = "nl_msg_free", cheader_filename = "netlink/netlink.h")]
    public class Message
    {
        public void             dump (Posix.FILE file);
        public int              parse (CallbackFunc func);
        [CCode (cname = "nlmsg_hdr")]
        public MessageHeader    header ();
    }

    [Compact]
    [CCode (cprefix = "nlmsg_", cname = "struct nlmsghdr", free_function = "", cheader_filename = "netlink/netlink.h")]
    public class MessageHeader
    {
        // field access
        public uint32 nlmsg_len;
        public uint16 nlmsg_type;
        public uint16 nlmsg_flags;
        public uint32 nlmsg_seq;
        public uint32 nlmsg_pid;

        // size calculations
        public static int       msg_size (int payload);
        public static int       total_size (int payload);
        public static int       padlen (int payload);

        // payload access
        public void*            data ();
        public int              len ();
        public void*            tail ();

        // attribute access
        public Attribute        attrdata (int hdrlen);
        public int              attrlen (int hdrlen);

        // message parsing
        public bool             valid_hdr (int hdrlen);
        public bool             ok (int remaining);
        public MessageHeader    next (out int remaining);
        public int              parse (int hdrlen, [CCode (array_length = "false")] out Attribute[] attributes, AttributeType maxtype, AttributePolicy? policy = null);
        public Attribute?       find_attr (int hdrlen, AttributeType type);
        public int              validate (int hdrlen, AttributeType maxtype, AttributePolicy policy);
    }

    [Compact]
    [CCode (cprefix = "nl_socket_", cname = "struct nl_sock", free_function = "nl_socket_free")]
    public class Socket {
        [CCode (cname = "nl_socket_alloc")]
        public Socket();

        [CCode (cname = "rtnl_link_alloc_cache")]
        public int              link_alloc_cache (int family, out LinkCache c);
        [CCode (cname = "rtnl_addr_alloc_cache")]
        public int              addr_alloc_cache (out AddrCache c);

        // connection management
        [CCode (cname = "nl_close")]
        public int              close ();
        [CCode (cname = "nl_connect")]
        public int              connect (int family);

        // group management
        public int              add_memberships (int group, ...);
        public int              add_membership (int group);
        public int              drop_memberships (int group, ...);
        public int              drop_membership (int group);
        public uint32           get_peer_port ();
        public void             set_peer_port (uint32 port);

        // callback management
        public Callback         get_cb ();
        public void             set_cb (Callback cb);
        public int              modify_cb (CallbackType type, CallbackKind kind, MessageCallbackFunc callback);

        // configuration
        public int              set_buffer_size (int rxbuf, int txbuf);
        public int              set_passcred (bool on);
        public int              recv_pktinfo (bool on);

        public void             disable_seq_check ();
        public uint             use_seq ();
        public void             disable_auto_ack ();
        public void             enable_auto_ack ();

        public int              get_fd ();
        public int              set_nonblocking ();
        public void             enable_msg_peek ();
        public void             disable_msg_peek ();

        // receiving messages
        [CCode (cname = "nl_recv")]
        public int              recv (out Linux.Netlink.SockAddrNl addr, out char[] buf, out Linux.Socket.ucred cred);

        [CCode (cname = "nl_recvmsgs")]
        public int              recvmsgs (Callback cb);

        [CCode (cname = "nl_recvmsgs_default")]
        public int              recvmsgs_default ();

        [CCode (cname = "nl_wait_for_ack")]
        public int              wait_for_ack ();
    }

    [Compact]
    [CCode (cprefix = "nl_object_", cname = "struct nl_object", free_function = "nl_object_free", cheader_filename = "netlink/object.h")]
    public class Object
    {
        public uint32 ce_mask;

        public unowned string attrs2str	(uint32 attrs, char[] buf);
        public unowned string attr_list (char[] buf);
        public void dump (DumpParams params);

    }

    [CCode (cprefix = "NL_DUMP_", cname = "int", cheader_filename = "netlink/types.h", has_type_id = false)]
    public enum DumpType {
        LINE,           // Dump object briefly on one line
        DETAILS,        // Dump all attributes but no statistics
        STATS,          // Dump all attributes including statistics
    }

    [CCode (cname = "struct nl_dump_params", free_function = "", cheader_filename = "netlink/types.h", has_type_id = false)]
    public struct DumpParams {
        public DumpType dp_type;
        public int dp_prefix;
        public bool dp_print_index;
        public bool dp_dump_msgtype;
        public unowned Posix.FILE dp_fd;
        public unowned string dp_buf;
        public size_t dp_buflen;
    }

    [Compact]
    [CCode (cprefix = "rtnl_link_", cname = "struct rtnl_link", free_function = "rtnl_link_destroy", cheader_filename = "netlink/route/link.h")]
    public class Link
    {
	    public unowned string get_name();
	    public Netlink.Address? get_addr();
	    public Netlink.Address? get_broadcast();
	    public uint get_flags();
	    public int get_family();
	    public uint get_arptype();
	    public int get_ifindex();
	    public uint get_mtu();
	    public uint get_txqlen();
        public uint get_weight();
        public unowned string? get_qdisc();
    }

    [Compact]
    [CCode (cprefix = "rtnl_link_", cname = "struct rtnl_link", free_function = "rtnl_link_put", cheader_filename = "netlink/route/link.h")]
    public class CachedLink : Link
    {
    }


    [Compact]
    [CCode (cprefix = "rtnl_route_", cname = "struct rtnl_route", cheader_filename = "netlink/route/route.h")]
    public class Route
    {
        public uint32 get_table();
        public uint8 get_scope();
        public uint8 get_tos();
        public uint8 get_protocol();
        public uint32 get_priority();
        public uint8 get_family();
        public Netlink.Address? get_dst();
        public Netlink.Address? get_src();
        public uint8 get_type();
        public uint32 get_flags();
        public int get_metric();
        public Netlink.Address? get_pref_src();
        public int get_iif();
    }

    [Compact]
    [CCode (cprefix = "rtnl_neigh_", cname = "struct rtnl_neigh", cheader_filename = "netlink/route/neighbour.h")]
    public class Neighbour
    {
        public int get_state();
        public uint get_flags();
        public int get_ifindex();
        public Netlink.Address? get_lladdr();
        public Netlink.Address? get_dst();
        public int get_type();
        public int get_family();
    }

    [Compact]
    [CCode (cprefix = "rtnl_rule_", cname = "struct rtnl_rule", cheader_filename = "netlink/route/rule.h")]
    public class Rule
    {
        public int get_family();
        public uint32 get_prio();
        public uint32 get_mark();
        public uint32 get_mask();
        public uint32 get_table();
        public uint8 get_dsfield();
        public Netlink.Address? get_src();
        public Netlink.Address? get_dst();
        public uint8 get_action();
        public unowned string? get_iif();
        public unowned string? get_oif();
        public uint32 get_realms();
        public uint32 get_goto();
    }

    [Compact]
    [CCode (cprefix = "rtnl_qdisc_", cname = "struct rtnl_qdisc", cheader_filename = "netlink/route/qdisc.h")]
    public class Qdisc
    {
        public int get_ifindex();
        public uint32 get_handle();
        public uint32 get_parent();
        public unowned string? get_kind();
        public uint64 get_stat();
    }

    [CCode (cname = "nl_nlmsgtype2str", cheader_filename = "netlink/msg.h")]
    public unowned string msgType2Str( int type, char[] buf );
    [CCode (cname = "nl_af2str", cheader_filename = "netlink/addr.h")]
    public unowned string af2Str( int family, char[] buf );
    [CCode (cname = "nl_llproto2str", cheader_filename = "netlink/utils.h")]
    public unowned string llproto2Str( uint proto, char[] buf );
    [CCode (cname = "rtnl_link_flags2str", cheader_filename = "netlink/route/link.h")]
    public unowned string linkFlags2Str( uint flags, char[] buf );
    [CCode (cname = "rtnl_scope2str", cheader_filename = "netlink/route/rtnl.h")]
    public unowned string routeScope2Str( int scope, char[] buf );
    [CCode (cname = "nl_rtntype2str", cheader_filename = "netlink/netlink.h")]
    public unowned string routeType2Str( int type, char[] buf );
    [CCode (cname = "rtnl_addr_flags2str", cheader_filename = "netlink/netlink.h")]
    public unowned string addrFlags2Str( int flags, char[] buf );
    [CCode (cname = "rtnl_neigh_flags2str", cheader_filename = "netlink/netlink.h")]
    public unowned string neighFlags2Str( uint flags, char[] buf );
    [CCode (cname = "rtnl_neigh_state2str", cheader_filename = "netlink/netlink.h")]
    public unowned string neighState2Str( int state, char[] buf );

}
