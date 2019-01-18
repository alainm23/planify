/* avahi-common.vala
 *
 * Copyright (C) 2009  Sebastian Noack
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
 *  Sebastian Noack <sebastian.noack@gmail.com>
 */

[CCode(cprefix="Ga", lower_case_cprefix="ga_")]
namespace Avahi {
    /* Network addresses */

	[SimpleType]
	[CCode(cheader_filename="avahi-common/address.h", cname="AvahiProtocol", cprefix="AVAHI_PROTO_", lower_case_cprefix="avahi_proto_", has_type_id = false)]
	public enum Protocol {
		INET,
		INET6,
		UNSPEC;

		[CCode(cname="avahi_af_to_proto")]
		public static Protocol from_af(int af);

		public unowned string to_string();
		public int to_af();

		[CCode(cname="AVAHI_PROTO_VALID")]
		public bool is_valid();
	}

	[SimpleType]
	[CCode(cheader_filename="avahi-common/address.h", cname="AvahiIfIndex", has_type_id = false)]
	public struct Interface {
		[CCode(cname="AVAHI_IF_UNSPEC")]
		public static Interface UNSPEC;

		[CCode(cname="AVAHI_IF_VALID")]
		public bool is_valid();
	}

	[CCode(cheader_filename="avahi-common/address.h", cname="AvahiAddress", cprefix="avahi_address_", has_type_id = false)]
	public struct Address {
		public Protocol proto;

		[CCode(cname="AVAHI_ADDRESS_STR_MAX")]
		public static size_t STR_MAX;

		[CCode(cname="avahi_address_parse", instance_pos=-1)]
		public Address.parse(string s, Protocol proto=Protocol.UNSPEC);

		[CCode(cname="avahi_address_snprint", instance_pos=-1)]
		public unowned string to_string(char[] dest=new char[STR_MAX]);
		public int cmp(Address other);
	}


	/* Linked list of strings used for DNS TXT record data */

	[CCode(cheader_filename="avahi-common/defs.h", cname="AVAHI_SERVICE_COOKIE_INVALID")]
	public const uint32 SERVICE_COOKIE_INVALID;

	[Compact]
	[CCode(cheader_filename="avahi-common/strlst.h", cname="AvahiStringList", cprefix="avahi_string_list_", dup_function="avahi_string_list_copy", free_function="avahi_string_list_free")]
	public class StringList {
		public StringList next;
		[CCode(array_length_cname="size")]
		public char[] text;

		public StringList(string? txt=null, ...);
		public StringList.from_array(string[] array);

		[ReturnsModifiedPointer()]
		public void add(string text);
		[ReturnsModifiedPointer()]
		[PrintfFormat]
		public void add_printf(string format, ...);
		[ReturnsModifiedPointer()]
		public void add_arbitrary(char[] text);
		[ReturnsModifiedPointer()]
		public void add_anonymous(size_t size);
		[ReturnsModifiedPointer()]
		public void add_many(...);

		public string to_string();
		public int equal(StringList other);
		public StringList copy();
		[ReturnsModifiedPointer()]
		public void reverse();
		public uint length();

		public unowned StringList find(string key);
		public bool get_pair(out string key, out char[] value);
		[ReturnsModifiedPointer()]
		public void add_pair(string key, string? value);
		[ReturnsModifiedPointer()]
		public void add_pair_arbitrary(string key, char[] value);
		public uint32 get_service_cookie();

		[CCode(cname="avahi_string_list_serialize")]
		private size_t _serialize(char[] dest);
		[CCode(cname="avahi_string_list_serialize_dup")]
		public char[] serialize() {
			char[] dest = new char[this.length() * 256];
			dest.length = (int) _serialize(dest);
			return dest;
		}

		[CCode(cname="avahi_string_list_parse")]
		public static int deserialize (char[] data, out StringList dest);
	}


	/* Domain name utility functions */

	[CCode(cheader_filename="avahi-common/domain.h", lower_case_cprefix="avahi_")]
	namespace Domain {
		public const size_t DOMAIN_NAME_MAX;
		public const size_t LABEL_MAX;

		[CCode(cname="avahi_normalize_name_strdup")]
		public string normalize_name(string s);
		[CCode(cname="avahi_domain_equal")]
		public bool equal(string a, string b);
		[CCode(cname="avahi_domain_hash")]
		public uint hash(string name);
		public unowned string? get_type_from_subtype(string s);
		public unowned string? unescape_label(ref unowned string name, char[] dest=new char[LABEL_MAX]);

		[CCode (cname="avahi_escape_label")]
		private string? _escape_label(char* src, size_t src_len, ref char* dest, ref size_t dest_len);
		[CCode (cname = "_vala_avahi_escape_label")]
		public string? escape_label(string s) {
			size_t len = LABEL_MAX * 4;
			char* dest = new char[len];
			return _escape_label(s, s.length, ref dest, ref len);
		}

		[CCode (cname = "avahi_service_name_join")]
		public int _service_name_join ([CCode (array_length_type = "size_t")] uint8[] dest, string name, string type, string domain);
		[CCode (cname = "_avahi_service_name_join")]
		public int join_service_name (out string? dest, string name, string type, string domain) {
			uint8[] dest_data = new uint8[DOMAIN_NAME_MAX];
			int errno = _service_name_join (dest_data, name, type, domain);
			dest = (errno >= 0) ? (string) dest_data : null;
			return errno;
		}

		[CCode (cname = "avahi_service_name_split")]
		public int _service_name_split(string src, [CCode (array_length_type = "size_t")] uint8[] name, [CCode (array_length_type = "size_t")] uint8[] type, [CCode (array_length_type = "size_t")] uint8[] domain);

		[CCode(cname = "_vala_avahi_service_name_split")]
		public int split_service_name (string src, out string name, out string type, out string domain) {
			uint8[] name_data = new uint8[LABEL_MAX];
			uint8[] type_data = new uint8[DOMAIN_NAME_MAX];
			uint8[] domain_data = new uint8[DOMAIN_NAME_MAX];

			int errno = _service_name_split (src, name_data, type_data, domain_data);

			if (errno >= 0) {
				name = (string) name_data;
				type = (string) type_data;
				domain = (string) domain_data;
			}

			return errno;
		}

		public bool is_valid_service_type_generic(string s);
		public bool is_valid_service_type_strict(string s);
		public bool is_valid_service_subtype(string s);
		public bool is_valid_domain_name(string s);
		public bool is_valid_service_name(string s);
		public bool is_valid_host_name(string s);
		public bool is_valid_fqdn(string s);

		[CCode(cheader_filename="avahi-common/address.h")]
		public unowned string reverse_lookup_name(Address addr, char[] dest=new char[DOMAIN_NAME_MAX]);
	}

	[CCode(cheader_filename="avahi-common/alternative.h", lower_case_cprefix="avahi_alternative_")]
	namespace Alternative {
		public string host_name(string s);
		public string service_name(string s);
	}


	/* Entry group */

	[Flags]
	[CCode(cheader_filename="avahi-common/defs.h", cname="AvahiPublishFlags", cprefix="AVAHI_PUBLISH_", has_type_id = false)]
	public enum PublishFlags {
		UNIQUE,
		NO_PROBE,
		NO_ANNOUNCE,
		ALLOW_MULTIPLE,
		NO_REVERSE,
		NO_COOKIE,
		UPDATE,
		USE_WIDE_AREA,
		USE_MULTICAST
	}
}
