/*
 * libnl-2.0.vapi
 *
 * Copyright (C) 2009-2015 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
    [CCode (cprefix = "nl_addr_", cname = "struct nl_addr", free_function = "", cheader_filename = "netlink/netlink.h")]
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

        public int      get_len ();

        public void     set_prefixlen (int len);
        public int      get_prefixlen ();

        public void     set_flags (uint flags);
        public void     unset_flags (uint flags);
        public uint     get_flags ();

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
        UNSPEC,
        U8,
        U16,
        U32,
        U64,
        STRING,
        FLAG,
        MSECS,
        NESTED,
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
        OK,
        SKIP,
        STOP,
    }

    [CCode (cname = "enum nl_cb_kind", cprefix = "NL_CB_", cheader_filename = "netlink/netlink.h", has_type_id = false)]
    public enum CallbackKind {
        DEFAULT,
        VERBOSE,
        DEBUG,
        CUSTOM,
    }

    [CCode (cname = "enum nl_cb_type", cprefix = "NL_CB_", cheader_filename = "netlink/netlink.h", has_type_id = false)]
    public enum CallbackType {
        VALID,
        FINISH,
        OVERRUN,
        SKIPPED,
        ACK,
        MSG_IN,
        MSG_OUT,
        INVALID,
        SEQ_CHECK,
        SEND_ACK,
    }

    [Compact]
    [CCode (cprefix = "nl_link_cache_", cname = "struct nl_cache", free_function = "nl_cache_free", cheader_filename = "netlink/netlink.h")]
    public class LinkCache : Cache {
        [CCode (cname = "rtnl_link_name2i")]
        public int name2i (string name);
    }

    [Compact]
    [CCode (cprefix = "nl_addr_cache", cname = "struct nl_cache", free_function = "nl_cache_free", cheader_filename = "netlink/netlink.h")]
    public class AddrCache : Cache {
    }

    [Compact]
    [CCode (cprefix = "nl_msg_", cname = "struct nl_msg", free_function = "nl_msg_free", cheader_filename = "netlink/netlink.h")]
    public class Message {
        public void             dump (Posix.FILE file);
        public int              parse (CallbackFunc func);
        [CCode (cname = "nlmsg_hdr")]
        public MessageHeader    header ();
    }

    [Compact]
    [CCode (cprefix = "nlmsg_", cname = "struct nlmsghdr", free_function = "", cheader_filename = "netlink/netlink.h")]
    public class MessageHeader {
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
        public int              link_alloc_cache (out LinkCache c);
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
    public class Object {

        public unowned string attrs2str	(uint32 attrs, char[] buf);
        public unowned string attr_list (char[] buf);
        public void dump (DumpParams params);

    }

    [CCode (cprefix = "NL_DUMP_", cname = "int", cheader_filename = "netlink/types.h", has_type_id = false)]
    public enum DumpType {
        LINE,
        DETAILS,
        STATS,
        ENV,
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
}
