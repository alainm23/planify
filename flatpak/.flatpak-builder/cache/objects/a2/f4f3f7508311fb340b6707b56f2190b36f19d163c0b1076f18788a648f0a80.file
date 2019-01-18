/* libnl-1.vapi
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

    [CCode (cname = "callback_func_t", instance_pos = 1)]
    public delegate void Callback (Object obj);

    [Compact]
    [CCode (cprefix = "nl_addr_", cname = "struct nl_addr", free_function = "", cheader_filename = "netlink/addr.h")]
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

        public void     set_prefixlen (int len);
        public int      get_prefixlen ();

        public void     set_scope (int scope);
        public int      get_scope ();

        public void     set_flags (uint flags);
        public void     unset_flags (uint flags);
        public uint     get_flags ();

        public void*    get_binary_addr();

        [CCode (cname = "nl_addr2str")]
        public string   to_string (char[] buf);

    }

    [Compact]
    [CCode (cprefix = "rtnl_addr_", cname = "struct rtnl_addr", free_function = "", cheader_filename = "netlink/route/addr.h")]
    public class RouteAddress : Address {
        [CCode (cname = "rtnl_addr_alloc")]
        public RouteAddress();

        public void     set_ifindex (int index );
        public int      get_ifindex ();

        public unowned RouteAddress get_local();
    }

    [Compact]
    [CCode (cprefix = "nl_cache_", cname = "struct nl_cache", free_function = "nl_cache_free", cheader_filename = "netlink/cache.h")]
    public class Cache {
        public static int alloc_name (string name, out Cache c);

        public void @foreach (Callback cb);
        public void foreach_filter (Object obj, Callback cb);
    }

    [Compact]
    [CCode (cprefix = "nl_link_cache_", cname = "struct nl_cache", free_function = "nl_cache_free", cheader_filename = "netlink/cache.h")]
    public class LinkCache : Cache {
        [CCode (cname = "rtnl_link_name2i")]
        public int name2i (string name);
    }

    [Compact]
    [CCode (cprefix = "nl_addr_cache", cname = "struct nl_cache", free_function = "nl_cache_free", cheader_filename = "netlink/cache.h")]
    public class AddrCache : Cache {
    }

    [Compact]
    [CCode (cname = "struct nl_msg", free_function = "nl_msg_free", cheader_filename = "netlink/msg.h")]
    public class Message {
    }

    [Compact]
    [CCode (cname = "struct nl_handle", free_function = "nl_handle_destroy")]
    public class Socket {
        [CCode (cname = "nl_handle_alloc")]
        public Socket();

        [CCode (cname = "rtnl_link_alloc_cache")]
        public LinkCache link_alloc_cache ();
        [CCode (cname = "rtnl_addr_alloc_cache")]
        public AddrCache addr_alloc_cache ();

        [CCode (cname = "nl_connect")]
        public int connect (int family);
    }

    [Compact]
    [CCode (cname = "struct nl_object", free_function = "nl_object_free", cheader_filename = "netlink/object.h")]
    public class Object {
    }

}
