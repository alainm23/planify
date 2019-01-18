/* libxml2.vala
 *
 * Copyright (C) 2006-2008  Jürg Billeter, Raffaele Sandrini, Michael Lawrence
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
 *	Raffaele Sandrini <rasa@gmx.ch>
 *	Michael Lawrence <lawremi@iastate.edu>
 *	Ondřej Jirman <megous@megous.com>
 */

[CCode (gir_namespace = "libxml2", gir_version = "2.0")]
namespace Xml {
	/* nanoftp - minimal FTP implementation */

	[CCode (has_target = false, cname = "ftpDataCallback", cheader_filename = "libxml/nanoftp.h")]
	public delegate void FtpDataCallback (void* userData, [CCode (array_length = false)] char[] data, int len);

	[CCode (has_target = false, cname = "ftpListCallback", cheader_filename = "libxml/nanoftp.h")]
	public delegate void FtpListCallback (void* userData, string filename, string attrib, string owner, string group, ulong size, int links, int year, string month, int day, int hour, int minute);

	[Compact]
	[CCode (cname = "void", free_function = "xmlNanoFTPFreeCtxt", cheader_filename = "libxml/nanoftp.h")]
	public class NanoFTP {
		[CCode (cname = "xmlNanoFTPCheckResponse")]
		public int check_response ();

		[CCode (cname = "xmlNanoFTPCleanup")]
		public static void cleanup ();

		[CCode (cname = "xmlNanoFTPClose")]
		public int close ();

		[CCode (cname = "xmlNanoFTPCloseConnection")]
		public int close_connection ();

		[CCode (cname = "xmlNanoFTPConnect")]
		public int connect ();

		[CCode (cname = "xmlNanoFTPConnectTo")]
		public static NanoFTP* connect_to (string server, int port);

		[CCode (cname = "xmlNanoFTPCwd")]
		public int cwd (string directory);

		[CCode (cname = "xmlNanoFTPDele")]
		public int dele (string file);

		[CCode (cname = "xmlNanoFTPGet")]
		public int get (FtpDataCallback cb, void* user_data, string filename);

		[CCode (cname = "xmlNanoFTPGetConnection")]
		public int get_connection ();

		[CCode (cname = "xmlNanoFTPGetResponse")]
		public int get_response ();

		[CCode (cname = "xmlNanoFTPGetSocket")]
		public int get_socket (string filename);

		[CCode (cname = "xmlNanoFTPInit")]
		public static void init ();

		[CCode (cname = "xmlNanoFTPList")]
		public int list (FtpListCallback cb, void* user_data, string filename);

		[CCode (cname = "xmlNanoFTPNewCtxt")]
		public NanoFTP (string url);

		[CCode (cname = "xmlNanoFTPOpen")]
		public static NanoFTP* open (string url);

		[CCode (cname = "xmlNanoFTPProxy")]
		public static void proxy (string host, int port, string user, string passwd, int type);

		[CCode (cname = "xmlNanoFTPQuit")]
		public int quit ();

		[CCode (cname = "xmlNanoFTPRead")]
		public int read (void* dest, int len);

		[CCode (cname = "xmlNanoFTPScanProxy")]
		public static void scan_proxy (string url);

		[CCode (cname = "xmlNanoFTPUpdateURL")]
		public int update_url (string url);
	}


	/* nanohttp - minimal HTTP implementation */

	[Compact]
	[CCode (cname = "void", cheader_filename = "libxml/nanohttp.h")]
	public class NanoHTTP {
		[CCode (cname = "xmlNanoHTTPAuthHeader")]
		public unowned string auth_header ();

		[CCode (cname = "xmlNanoHTTPCleanup")]
		public static void cleanup ();

		[CCode (cname = "xmlNanoHTTPClose")]
		public int close ();

		[CCode (cname = "xmlNanoHTTPContentLength")]
		public int content_length ();

		[CCode (cname = "xmlNanoHTTPEncoding")]
		public unowned string http_encoding ();

		[CCode (cname = "xmlNanoHTTPFetch")]
		public static int fetch (string url, string filename, out string content_type);

		[CCode (cname = "xmlNanoHTTPInit")]
		public static void init ();

		[CCode (cname = "xmlNanoHTTPMethod")]
		public static NanoHTTP* method (string url, string method, string input, out string content_type, string headers, int ilen);

		[CCode (cname = "xmlNanoHTTPMethodRedir")]
		public static NanoHTTP* method_redir (string url, string method, string input, out string content_type, out string redir, string headers, int ilen);

		[CCode (cname = "xmlNanoHTTPMimeType")]
		public string mime_type ();

		[CCode (cname = "xmlNanoHTTPOpen")]
		public static NanoHTTP* open (string url, out string content_type);

		[CCode (cname = "xmlNanoHTTPOpenRedir")]
		public static NanoHTTP* open_redir (string url, out string content_type, out string redir);

		[CCode (cname = "xmlNanoHTTPRead")]
		public int read (void* dest, int len);

		[CCode (cname = "xmlNanoHTTPRedir")]
		public unowned string redir ();

		[CCode (cname = "xmlNanoHTTPReturnCode")]
		public int return_code ();

		[CCode (cname = "xmlNanoHTTPSave")]
		public int save (string filename);

		[CCode (cname = "xmlNanoHTTPScanProxy")]
		public static void scan_proxy (string URL);
	}


	/* parser - the core parser module */

	[CCode (cheader_filename = "libxml/parser.h")]
	namespace Parser {
		[CCode (cname = "xmlCleanupParser")]
		public static void cleanup ();

		[CCode (cname = "xmlInitParser")]
		public static void init ();

		[CCode (cname = "xmlParseDoc")]
		public static Doc* parse_doc ([CCode (type = "xmlChar*")] string cur);

		[CCode (cname = "xmlParseFile")]
		public static Doc* parse_file (string filename);

		[CCode (cname = "xmlParseMemory")]
		public static Doc* parse_memory (string buffer, int size);

		[CCode (cname = "xmlReadDoc")]
		public static Doc* read_doc ([CCode (type = "xmlChar*")] string cur, string? url = null, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReadFd")]
		public static Doc* read_fd (int fd, string? base_url = null, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReadFile")]
		public static Doc* read_file (string filename, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReadMemory")]
		public static Doc* read_memory (string text, int len, string? url = null, string? encoding = null, int options = 0);
	}

	[CCode (cname = "xmlParserOption", cprefix = "XML_PARSE_", cheader_filename = "libxml/parser.h", has_type_id = false)]
	public enum ParserOption {
		RECOVER,
		NOENT,
		DTDLOAD,
		DTDATTR,
		DTDVALID,
		NOERROR,
		NOWARNING,
		PEDANTIC,
		NOBLANKS,
		SAX1,
		XINCLUDE,
		NONET,
		NODICT,
		NSCLEAN,
		NOCDATA,
		NOXINCNODE,
		COMPACT,
		OLD10,
		NOBASEFIX,
		HUGE,
		OLDSAX,
		IGNORE_ENC,
		BIG_LINES,
	}

	[CCode (cname = "xmlCharEncoding", cprefix = "XML_CHAR_ENCODING_", cheader_filename = "libxml/encoding.h", has_type_id = false)]
	public enum CharEncoding {
		ERROR,
		NONE,
		UTF8,
		UTF16LE,
		UTF16BE,
		UCS4LE,
		UCS4BE,
		EBCDIC,
		UCS4_2143,
		UCS4_3412,
		UCS2,
		[CCode (cname = "XML_CHAR_ENCODING_8859_1")]
		ISO_8859_1,
		[CCode (cname = "XML_CHAR_ENCODING_8859_2")]
		ISO_8859_2,
		[CCode (cname = "XML_CHAR_ENCODING_8859_3")]
		ISO_8859_3,
		[CCode (cname = "XML_CHAR_ENCODING_8859_4")]
		ISO_8859_4,
		[CCode (cname = "XML_CHAR_ENCODING_8859_5")]
		ISO_8859_5,
		[CCode (cname = "XML_CHAR_ENCODING_8859_6")]
		ISO_8859_6,
		[CCode (cname = "XML_CHAR_ENCODING_8859_7")]
		ISO_8859_7,
		[CCode (cname = "XML_CHAR_ENCODING_8859_8")]
		ISO_8859_8,
		[CCode (cname = "XML_CHAR_ENCODING_8859_9")]
		ISO_8859_9,
		ISO_2022_JP,
		SHIFT_JIS,
		EUC_JP,
		ASCII,
	}

	/* tree - interfaces for tree manipulation */

	[CCode (cheader_filename = "libxml/tree.h")]
	namespace Tree {
		[CCode (cname = "xmlGetCompressMode")]
		public static int get_compress_mode ();

		[CCode (cname = "xmlIsXHTML")]
		public static int is_xhtml ([CCode (type = "xmlChar*")] string system_id, [CCode (type = "xmlChar*")] string public_id);

		[CCode (cname = "xmlSetCompressMode")]
		public static void set_compress_mode (int mode);

		[CCode (cname = "xmlValidateName")]
		public static int validate_name ([CCode (type = "const xmlChar*")] string name, bool trim_spaces = false);

		[CCode (cname = "xmlValidateQName")]
		public static int validate_q_name ([CCode (type = "const xmlChar*")] string value, bool trim_spaces = false);

		[CCode (cname = "xmlValidateNCName")]
		public static int validate_nc_name ([CCode (type = "const xmlChar*")] string value, bool trim_spaces = false);

		[CCode (cname = "xmlValidateNamesValue")]
		public static int validate_names_value ([CCode (type = "const xmlChar*")] string value);

		[CCode (cname = "xmlValidateNameValue")]
		public static int validate_name_value ([CCode (type = "const xmlChar*")] string value);

		[CCode (cname = "xmlValidateAttributeValue")]
		public static int validate_attribute_value (AttributeType type, [CCode (type = "const xmlChar*")] string value);

		[CCode (cname = "xmlValidateNMToken")]
		public static int validate_nm_token ([CCode (type = "const xmlChar*")] string value, bool trim_spaces = false);

		[CCode (cname = "xmlValidateNmtokensValue")]
		public static int validate_nm_tokens_value ([CCode (type = "const xmlChar*")] string value);

		[CCode (cname = "xmlValidateNmtokenValue")]
		public static int validate_nm_token_value ([CCode (type = "const xmlChar*")] string value);
	}

	[Compact]
	[CCode (cname = "xmlAttr", free_function = "xmlFreeProp", cheader_filename = "libxml/tree.h")]
	public class Attr {
		public ElementType type;
		[CCode (type = "xmlChar*")]
		public weak string name;
		public Node* children;
		public Node* last;
		public Node* parent;
		public Attr* next;
		public Attr* prev;
		public Doc* doc;
		public Ns* ns;
		public AttributeType atype;

		[CCode (cname = "xmlRemoveProp")]
		public int remove();
	}

	[Compact]
	[CCode (cname = "xmlAttribute", cheader_filename = "libxml/tree.h")]
	public class Attribute {
		public ElementType type;
		[CCode (type = "xmlChar*")]
		public weak string name;
		public Node* children;
		public Node* last;
		public Dtd* parent;
		public Node* next;
		public Node* prev;
		public Doc* doc;
		public Attribute* nexth;
		public AttributeType atype;
		public AttributeDefault def;
		[CCode (type = "xmlChar*")]
		public weak string default_value;
		[CCode (type = "xmlChar*")]
		public weak string prefix;
		[CCode (type = "xmlChar*")]
		public weak string elem;
	}

	[CCode (cname = "xmlAttributeDefault", cprefix = "XML_ATTRIBUTE_", cheader_filename = "libxml/tree.h", has_type_id = false)]
	public enum AttributeDefault {
		NONE,
		REQUIRED,
		IMPLIED,
		FIXED
	}

	[CCode (cname = "xmlAttributeType", cprefix = "XML_ATTRIBUTE_", cheader_filename = "libxml/tree.h", has_type_id = false)]
	public enum AttributeType {
		CDATA,
		ID,
		IDREF ,
		IDREFS,
		ENTITY,
		ENTITIES,
		NMTOKEN,
		NMTOKENS,
		ENUMERATION,
		NOTATION
	}

	[Compact]
	[CCode (cname = "xmlBuffer", free_function = "xmlBufferFree", cheader_filename = "libxml/tree.h")]
	public class Buffer {
		[CCode (cname = "xmlBufferCreate")]
		public Buffer ();

		[CCode (cname = "xmlBufferContent")]
		public unowned string content ();

		[CCode (cname = "xmlNodeDump")]
		public int node_dump (Xml.Doc *doc, Xml.Node *cur, int level, int format);
	}

	[Compact]
	[CCode (cname = "xmlDoc", free_function = "xmlFreeDoc", cheader_filename = "libxml/tree.h,libxml/parser.h")]
	public class Doc {
		public ElementType type;
		public string name;
		public Node* children;
		public Node* last;
		public Node* parent;
		public Node* next;
		public Node* prev;
		public Doc* doc;
		public int compression;
		public int standalone;
		[CCode (cname = "intSubset")]
		public Dtd* int_subset;
		[CCode (cname = "extSubset")]
		public Dtd* ext_subset;
		[CCode (cname = "oldNs")]
		public Ns* old_ns;
		[CCode (type = "xmlChar*")]
		public weak string version;
		[CCode (type = "xmlChar*")]
		public weak string encoding;
		[CCode (cname = "URL", type = "xmlChar*")]
		public weak string url;
		public int charset;

		[CCode (cname = "xmlCopyDoc")]
		public Doc* copy (int recursive);

		[CCode (cname = "xmlCreateIntSubset")]
		public Dtd* create_int_subset ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string external_id, [CCode (type = "xmlChar*")] string system_id);

		[CCode (cname = "xmlDocDump", instance_pos = -1)]
		public int dump (GLib.FileStream f);

		[CCode (cname = "xmlDocDumpFormatMemory")]
		public void dump_memory_format ([CCode (type = "xmlChar*")] out string mem, out int len = null, bool format = true);

		[CCode (cname = "xmlDocDumpFormatMemoryEnc")]
		public void dump_memory_enc_format ([CCode (type = "xmlChar**")] out string mem, out int len = null, string enc = "UTF-8", bool format = true);

		[CCode (cname = "xmlDocDumpMemory")]
		public void dump_memory ([CCode (type = "xmlChar**")] out string mem, out int len = null);

		[CCode (cname = "xmlDocDumpMemoryEnc")]
		public void dump_memory_enc ([CCode (type = "xmlChar**")] out string mem, out int len = null, string enc = "UTF-8");

		[CCode (cname = "xmlDocFormatDump", instance_pos = 1.1)]
		public int dump_format (GLib.FileStream f, bool format = true);

		[CCode (cname = "xmlDocGetRootElement")]
		public Node* get_root_element();

		[CCode (cname = "xmlDocSetRootElement")]
		public Node* set_root_element(Node* root);

		[CCode (cname = "xmlElemDump", instance_pos = 1.1)]
		public void elem_dump (GLib.FileStream f, Node* cur);

		[CCode (cname = "xmlGetDocCompressMode")]
		public int get_compress_mode ();

		[CCode (cname = "xmlNewCDataBlock")]
		public Node* new_cdata_block ([CCode (type = "xmlChar*")] string content, int len);

		[CCode (cname = "xmlNewCharRef")]
		public Node* new_char_ref ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlNewDoc")]
		public Doc ([CCode (type = "xmlChar*")] string? version = null);

		[CCode (cname = "xmlNewDocComment")]
		public Node* new_comment ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlNewDocFragment")]
		public Node* new_fragment ();

		[CCode (cname = "xmlNewDocNode")]
		public Node* new_node (Ns* ns, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? content = null);

		[CCode (cname = "xmlNewDocNodeEatName")]
		public Node* new_node_eat_name (Ns* ns, [CCode (type = "xmlChar*")] owned string name, [CCode (type = "xmlChar*")] string? content = null);

		[CCode (cname = "xmlNewDocPI")]
		public Node* new_pi ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlNewDocProp")]
		public Attr* new_prop ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string value);

		[CCode (cname = "xmlNewDocRawNode")]
		public Node* new_raw_node (Ns* ns, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? content = null);

		[CCode (cname = "xmlNewDocText")]
		public Node* new_text ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlNewDocTextLen")]
		public Node* new_text_len ([CCode (type = "xmlChar*")] string content, int len);

		[CCode (cname = "xmlNewReference")]
		public Node* new_reference ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlGetNsList")]
		public Ns* get_ns_list (Node* node);

		[CCode (cname = "xmlNodeListGetRawString", type = "xmlChar*")]
		public string node_list_get_raw_string (Node* list, bool in_line);

		[CCode (cname = "xmlNodeListGetString", type = "xmlChar*")]
		public string node_list_get_string (Node* list, bool in_line);

		[CCode (cname = "xmlSaveFile", instance_pos = -1)]
		public int save_file (string filename);

		[CCode (cname = "xmlSaveFileEnc", instance_pos = 1.1)]
		public void save_file_enc (string filename, string enc = "UTF-8");

		[CCode (cname = "xmlSaveFormatFile", instance_pos = 1.1)]
		public int save_format_file (string filename, int format);

		[CCode (cname = "xmlSaveFormatFileEnc", instance_pos = 1.1)]
		public void save_format_file_enc (string filename, string enc = "UTf-8", bool format = true);

		[CCode (cname = "xmlSetDocCompressMode")]
		public void set_compress_mode (int mode);

		[CCode (cname = "xmlStringGetNodeList")]
		public Node* string_get_node_list (string str);

		[CCode (cname = "xmlStringLenGetNodeList")]
		public Node* string_len_get_node_list (string str, int len);

		[CCode (cname = "xmlSearchNs")]
		public Ns* search_ns(Node* node, string? prefix);

		[CCode (cname = "xmlSearchNsByHref")]
		public Ns* search_ns_by_href(Node* node, string? href);
	}

	[Compact]
	[CCode (cname = "xmlDtd", free_function="xmlFreeDtd", cheader_filename = "libxml/tree.h")]
	public class Dtd {
		public ElementType type;
		[CCode (type = "xmlChar*")]
		public string name;
		public Node* children;
		public Node* last;
		public Node* parent;
		public Node* next;
		public Node* prev;
		public Doc* doc;
		public Xml.HashTable* entities;

		[CCode (cname = "ExternalID", type = "xmlChar*")]
		public weak string external_id;
		[CCode (cname = "SystemID", type = "xmlChar*")]
		public weak string system_id;

		[CCode (cname = "xmlNewDtd")]
		public Dtd (Doc* doc, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string external_id, [CCode (type = "xmlChar*")] string system_id);

		[CCode (cname = "xmlCopyDtd")]
		public Dtd* copy();
	}

	[Compact]
	[CCode (cname = "xmlElement", cheader_filename = "libxml/tree.h")]
	public class Element {
		public ElementType type;
		[CCode (type = "xmlChar*")]
		public weak string name;
		public Node* children;
		public Node* last;
		public Dtd* parent;
		public Node* next;
		public Node* prev;
		public Doc* doc;
		public Attribute* attributes;
		[CCode (type = "xmlChar*")]
		public weak string prefix;
	}

	[CCode (cname = "xmlElementType", cprefix = "XML_", cheader_filename = "libxml/tree.h", has_type_id = false)]
	public enum ElementType {
		ELEMENT_NODE,
		ATTRIBUTE_NODE,
		TEXT_NODE,
		CDATA_SECTION_NODE,
		ENTITY_REF_NODE,
		ENTITY_NODE,
		PI_NODE,
		COMMENT_NODE,
		DOCUMENT_NODE,
		DOCUMENT_TYPE_NODE,
		DOCUMENT_FRAG_NODE,
		NOTATION_NODE,
		HTML_DOCUMENT_NODE,
		DTD_NODE,
		ELEMENT_DECL,
		ATTRIBUTE_DECL,
		ENTITY_DECL,
		NAMESPACE_DECL,
		XINCLUDE_START,
		XINCLUDE_END,
		DOCB_DOCUMENT_NODE
	}

	[Compact]
	[CCode (cname = "xmlElementContent", free_function = "xmlFreeElementContent", cheader_filename = "libxml/tree.h")]
	public class ElementContent {
		[CCode (cname = "xmlNewElementContent")]
		ElementContent ([CCode (type = "xmlChar*")] string name, ElementContentType type);

		public ElementContentType type;
		public ElementContentOccur ocur;
		[CCode (type = "xmlChar*")]
		public const string name;
		public ElementContent c1;
		public ElementContent c2;
		public ElementContent parent;
		[CCode (type = "xmlChar*")]
		public const string prefix;
	}

	[CCode (cname = "xmlElementContentType", cprefix = "XML_ELEMENT_CONTENT_", cheader_filename = "libxml/tree.h", has_type_id = false)]
	public enum ElementContentType {
		PCDATA,
		ELEMENT,
		SEQ,
		OR
	}

	[CCode (cname = "xmlElementContentOccur", cprefix = "XML_ELEMENT_CONTENT_", cheader_filename = "libxml/tree.h", has_type_id = false)]
	public enum ElementContentOccur {
		ONCE,
		OPT,
		MULT,
		PLUS
	}

	[Compact]
	[CCode (cname = "xmlEntity", cheader_filename = "libxml/tree.h")]
	public struct Entity {
		public void* private;
		public ElementType type;
		[CCode (type = "xmlChar*")]
		public const string name;
		public Node* children;
		public Node* last;
		public Dtd* parent;
		public Node* next;
		public Node* prev;
		public Doc* doc;
		[CCode (type = "xmlChar*")]
		public string orig;
		[CCode (type = "xmlChar*")]
		public string content;
		public int length;
		public EntityType etype;
		[CCode (cname = "ExternalID", type = "xmlChar*")]
		public const string external_id;
		[CCode (cname = "SystemID", type = "xmlChar*")]
		public const string system_id;
		public Entity* nexte;
		[CCode (cname = "URI", type = "xmlChar*")]
		public const string uri;
		public int owner;
		public int checked;
	}

	[CCode (cname = "xmlEntityType", cprefix = "XML_", cheader_filename = "libxml/tree.h", has_type_id = false)]
	public enum EntityType {
		INTERNAL_GENERAL_ENTITY,
		EXTERNAL_GENERAL_PARSED_ENTITY,
		EXTERNAL_GENERAL_UNPARSED_ENTITY,
		INTERNAL_PARAMETER_ENTITY,
		EXTERNAL_PARAMETER_ENTITY,
		INTERNAL_PREDEFINED_ENTITY
	}

	[Compact]
	[CCode (cname = "xmlEnumeration", cheader_filename = "libxml/tree.h")]
	public struct Enumeration {
		public Enumeration* next;
		[CCode (type = "xmlChar*")]
		public const string name;
	}

	[CCode (has_target = false, cname = "xmlHashScannerFull", cheader_filename = "libxml/hash.h")]
	public delegate void HashScannerFull (void *payload, void *user_data, string name, string name2, string name3);

	[CCode (has_target = false, cname = "xmlHashDeallocator", cheader_filename = "libxml/hash.h")]
	public delegate void HashDeallocator (void *payload, string name);

	[Compact]
	[CCode (cname = "xmlHashTable", cheader_filename="libxml/hash.h")]
	public class HashTable {
		[CCode (cname = "xmlHashCreate")]
		public HashTable (int size);

		[CCode (cname = "xmlHashAddEntry")]
		public int add_entry (string name, void *user_data);

		[CCode (cname = "xmlHashFree")]
		public void free (HashDeallocator? f);

		[CCode (cname = "xmlHashLookup")]
		public void *lookup (string name);

		[CCode (cname = "xmlHashRemoveEntry")]
		public int remove_entry (string name, HashDeallocator? f);

		[CCode (cname = "xmlHashScanFull")]
		public void scan_full (HashScannerFull f, void *user_data);

		[CCode (cname = "xmlHashSize")]
		public int size ();
	}

	[Compact]
	[CCode (cname = "xmlNode", free_function = "xmlFreeNode", cheader_filename = "libxml/tree.h")]
	public class Node {
		public ElementType type;
		[CCode (type = "xmlChar*")]
		public weak string name;
		public Node* children;
		public Node* last;
		public Node* parent;
		public Node* next;
		public Node* prev;
		public Doc* doc;
		public Ns* ns;
		[CCode (type = "xmlChar*")]
		public string content;
		public Attr* properties;
		[CCode (cname = "nsDef")]
		public Ns* ns_def;
		public ushort line;
		public ushort extra;

		[CCode (cname = "xmlAddChild")]
		public Node* add_child (Node* cur);

		[CCode (cname = "xmlAddChildList")]
		public Node* add_child_list (Node* cur);

		[CCode (cname = "xmlAddNextSibling")]
		public Node* add_next_sibling (Node* elem);

		[CCode (cname = "xmlAddPrevSibling")]
		public Node* add_prev_sibling (Node* elem);

		[CCode (cname = "xmlAddSibling")]
		public Node* add_sibling (Node* elem);

		[CCode (cname = "xmlCopyNode")]
		public Node* copy (int extended);

		[CCode (cname = "xmlCopyNodeList")]
		public Node copy_list ();

		[CCode (cname = "xmlCopyProp")]
		public Attr* copy_prop (Attr* prop);

		[CCode (cname = "xmlCopyPropList")]
		public Attr* copy_prop_list (Attr* props);

		[CCode (cname = "xmlDocCopyNode")]
		public Node* doc_copy (Doc* doc, int extended);

		[CCode (cname = "xmlDocCopyNodeList")]
		public Node* doc_copy_list (Doc* doc);

		[CCode (cname = "xmlFreeNodeList")]
		public void free_list ();

		[CCode (cname = "xmlGetLastChild")]
		public Node* get_last_child ();

		[CCode (cname = "xmlGetLineNo")]
		public long get_line_no ();

		[CCode (cname = "xmlGetNoNsProp", type = "xmlChar*")]
		public string? get_no_ns_prop ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlGetNodePath", type = "xmlChar*")]
		public string get_path ();

		[CCode (cname = "xmlGetNsProp", type = "xmlChar*")]
		public string? get_ns_prop ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string ns);

		[CCode (cname = "xmlGetProp", type = "xmlChar*")]
		public string? get_prop ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlHasNsProp")]
		public Attr* has_ns_prop ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? name_space);

		[CCode (cname = "xmlHasProp")]
		public Attr* has_prop ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlIsBlankNode")]
		public int is_blank ();

		[CCode (cname = "xmlNewChild")]
		public Node* new_child (Ns* ns, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? content = null);

		[CCode (cname = "xmlNewNs")]
		public Ns* new_ns ([CCode (type = "xmlChar*")] string href, [CCode (type = "xmlChar*")] string prefix);

		[CCode (cname = "xmlNewNsProp")]
		public Attr* new_ns_prop (Ns* ns, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string value);

		[CCode (cname = "xmlNewProp")]
		public Attr* new_prop ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string value);

		[CCode (cname = "xmlNewTextChild")]
		public Node* new_text_child (Ns* ns, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlNodeAddContent")]
		public void add_content ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlNodeAddContentLen")]
		public void add_content_len ([CCode (type = "xmlChar*")] string content, int len);

		[CCode (cname = "xmlNodeGetContent", type = "xmlChar*")]
		public string get_content();

		[CCode (cname = "xmlNodeGetLang", type = "xmlChar*")]
		public string get_lang();

		[CCode (cname = "xmlNodeGetSpacePreserve")]
		public int get_space_preserve();

		[CCode (cname = "xmlNodeIsText")]
		public int is_text();

		[CCode (cname = "xmlNodeSetContent")]
		public void set_content ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlNodeSetContentLen")]
		public void set_content_len ([CCode (type = "xmlChar*")] string content, int len);

		[CCode (cname = "xmlNodeSetLang")]
		public void set_lang ([CCode (type = "xmlChar*")] string val);

		[CCode (cname = "xmlNodeSetName")]
		public void set_name ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlNodeSetSpacePreserve")]
		public void set_space_preserve (int val);

		[CCode (cname = "xmlReplaceNode")]
		public Node* replace (Node* cur);

		[CCode (cname = "xmlNewComment")]
		public Node.comment ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlNewNode")]
		public Node (Ns* ns, [CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlNewNodeEatName")]
		public Node.eat_name (Ns* ns, [CCode (type = "xmlChar*")] owned string name);

		[CCode (cname = "xmlNewText")]
		public Node.text ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlNewTextLen")]
		public Node.text_len ([CCode (type = "xmlChar*")] string content, int len);

		[CCode (cname = "xmlNewPI")]
		public Node.pi ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlSetListDoc")]
		public void set_list_doc (Doc* doc);

		[CCode (cname = "xmlSetNs")]
		public void set_ns (Ns* ns);

		[CCode (cname = "xmlSetNsProp")]
		public Attr* set_ns_prop (Ns* ns, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? value);

		[CCode (cname = "xmlSetProp")]
		public Attr* set_prop ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? value);

		[CCode (cname = "xmlSetTreeDoc")]
		public void set_tree_doc (Doc* doc);

		[CCode (cname = "xmlTextConcat")]
		public int text_concat ([CCode (type = "xmlChar*")] string content, int len);

		[CCode (cname = "xmlTextMerge")]
		public Node* text_merge (Node* second);

		[CCode (cname = "xmlUnlinkNode")]
		public void unlink ();

		[CCode (cname = "xmlUnsetNsProp")]
		public int unset_ns_prop (Ns* ns, [CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlUnsetProp")]
		public int unset_prop ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlNextElementSibling")]
		public Node* next_element_sibling ();

		[CCode (cname = "xmlPreviousElementSibling")]
		public Node* previous_element_sibling ();

		[CCode (cname = "xmlFirstElementChild")]
		public Node* first_element_child ();

		[CCode (cname = "xmlLastElementChild")]
		public Node* last_element_child ();

		[CCode (cname = "xmlChildElementCount")]
		public ulong child_element_count ();
	}

	[Compact]
	[CCode (cname = "xmlNs", free_function= "xmlFreeNs", cheader_filename = "libxml/tree.h")]
	public class Ns {
		[CCode (cname = "xmlNewNs")]
		public Ns (Xml.Node* node, [CCode (type = "xmlChar*")] string href, [CCode (type = "xmlChar*")] string prefix);
		public Ns* next;
		public ElementType type;
		[CCode (type = "xmlChar*")]
		public string href;
		[CCode (type = "xmlChar*")]
		public string prefix;
		public Doc* context;
	}

	[Compact]
	[CCode (cname = "xmlParserCtxt", free_function = "xmlFreeParserCtxt", cheader_filename = "libxml/parser.h")]
	public class ParserCtxt {
		public SAXHandler* sax;
		[CCode (cname = "userData")]
		public void* user_data;

		[CCode (cname = "xmlNewParserCtxt")]
		public ParserCtxt ();

		[CCode (cname = "xmlCreatePushParserCtxt")]
		public ParserCtxt.create_push (Xml.SAXHandler* sax, void* user_data, [CCode (array_length = false)] char[] data, int len, string? filename = null);

		[CCode (cname = "xmlCreateIOParserCtxt")]
		public ParserCtxt.create_io (Xml.SAXHandler* sax, void* user_data, Xml.InputReadCallback ioread, Xml.InputCloseCallback ioclose, void* ioctx, string? encoding = null);

		[CCode (cname = "xmlCreateDocParserCtxt")]
		public ParserCtxt.create_doc ([CCode (type = "xmlChar*")] string cur);

		[CCode (cname = "xmlParseChunk")]
		public int parse_chunk ([CCode (array_length = false)] char[] data, int size, bool terminate);

		[CCode (cname = "xmlParseDocument")]
		public int parse_document ();

		[CCode (cname = "xmlCtxtResetPush")]
		public void reset_push ([CCode (array_length = false)] char[] data, int len, string? filename = null, string? encoding = null);

		[CCode (cname = "xmlCtxtReset")]
		public void reset ();

		[CCode (cname = "xmlCtxtInit")]
		public void init ();

		[CCode (cname = "xmlCtxtClear")]
		public void clear ();

		[CCode (cname = "xmlCtxtUseOptions")]
		public int use_options (int options);

		[CCode (cname = "xmlCtxtReadDoc")]
		public Doc* read_doc ([CCode (type = "xmlChar*")] string cur, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlCtxtReadFile")]
		public Doc* read_file (string filename, string? encoding = null, int options = 0);

		[CCode (cname = "xmlCtxtReadMemory")]
		public Doc* read_memory ([CCode (array_length = false)] char[] buffer, int size, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlCtxtReadFd")]
		public Doc* read_fd (int fd, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlCtxtReadIO")]
		public Doc* read_io (Xml.InputReadCallback ioread, Xml.InputCloseCallback ioclose, void* ioctx, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlCtxtGetLastError")]
		public Error* get_last_error ();

		[CCode (cname = "xmlCtxtResetLastError")]
		public Error* reset_last_error ();
	}


	/* uri - library of generic URI related routines */

	[Compact]
	[CCode (cname = "xmlURI", free_function = "xmlFreeURI", cheader_filename = "libxml/uri.h")]
	public class URI {
		[CCode (cname = "xmlBuildRelativeURI", type = "xmlChar*")]
		public static string build_relative ([CCode (type = "xmlChar*")] string uri, [CCode (type = "xmlChar*")] string @base);

		[CCode (cname = "xmlBuildURI", type = "xmlChar*")]
		public static string build ([CCode (type = "xmlChar*")] string URI, [CCode (type = "xmlChar*")] string @base);

		[CCode (cname = "xmlCanonicPath", type = "xmlChar*")]
		public static string canonic_path ([CCode (type = "xmlChar*")] string path);

		[CCode (cname = "xmlCreateURI")]
		public URI ();

		[CCode (cname = "xmlNormalizeURIPath")]
		public static int normalize_uri_path (string path);

		[CCode (cname = "xmlParseURI")]
		public static URI? parse (string str);

		[CCode (cname = "xmlParseURIRaw")]
		public static URI? parse_raw (string str, bool raw);

		[CCode (cname = "xmlParseURIReference")]
		public int parse_reference (string str);

		[CCode (cname = "xmlPathToURI", type = "xmlChar*")]
		public static string path_to_uri ([CCode (type = "xmlChar*")] string path);

		[CCode (cname = "xmlPrintURI", instance_pos = -1)]
		public void print (GLib.FileStream stream);

		[CCode (cname = "xmlSaveUri", type = "xmlChar*")]
		public string save ();

		[CCode (cname = "xmlURIEscape", type = "xmlChar*")]
		public static string escape ([CCode (type = "xmlChar*")] string str);

		[CCode (cname = "xmlURIEscapeStr", type = "xmlChar*")]
		public static string escape_str ([CCode (type = "xmlChar*")] string str, [CCode (type = "xmlChar*")] string list);

		[CCode (cname = "xmlURIUnescapeString")]
		public static string unescape_string (string str, int len, string? target);

		public string scheme;
		public string opaque;
		public string authority;
		public string server;
		public string user;
		public int port;
		public string path;
		public string query;
		public string fragment;
		public int cleanup;
		public string query_raw;
	}


	/* xmlIO - interface for the I/O interfaces used by the parser */

	[CCode (has_target = false, cname = "xmlInputCloseCallback", cheader_filename = "libxml/xmlIO.h")]
	public delegate int InputCloseCallback (void* context);

	[CCode (has_target = false, cname = "xmlInputReadCallback", cheader_filename = "libxml/xmlIO.h")]
	public delegate int InputReadCallback (void* context, [CCode (array_length = false)] char[] buffer, int len);

	[CCode (has_target = false, cname = "xmlInputMatchCallback", cheader_filename = "libxml/xmlIO.h")]
	public delegate int InputMatchCallback (string filename);

	[CCode (has_target = false, cname = "xmlInputOpenCallback", cheader_filename = "libxml/xmlIO.h")]
	public delegate void* InputOpenCallback (string filename);

	[CCode (has_target = false, cname = "xmlOutputMatchCallback", cheader_filename = "libxml/xmlIO.h")]
	public delegate int OutputMatchCallback (string filename);

	[CCode (has_target = false, cname = "xmlOutputOpenCallback", cheader_filename = "libxml/xmlIO.h")]
	public delegate void* OutputOpenCallback (string filename);

	[CCode (has_target = false, cname = "xmlOutputWriteCallback", cheader_filename = "libxml/xmlIO.h")]
	public delegate int OutputWriteCallback (void* context, [CCode (array_length = false)] char[] buffer, int len);

	[CCode (has_target = false, cname = "xmlOutputCloseCallback", cheader_filename = "libxml/xmlIO.h")]
	public delegate int OutputCloseCallback (void * context);

	[CCode (cname = "xmlRegisterInputCallbacks", cheader_filename = "libxml/xmlIO.h")]
	public int registerInputCallbacks (InputMatchCallback matchFunc, InputOpenCallback openFunc, InputReadCallback readFunc, InputCloseCallback closeFunc);

	[CCode (cname = "xmlRegisterOutputCallbacks", cheader_filename = "libxml/xmlIO.h")]
	public int registerOutputCallbacks(OutputMatchCallback matchFunc, OutputOpenCallback openFunc, OutputWriteCallback writeFunc, OutputCloseCallback closeFunc);

	/* xmlschemas - incomplete XML Schemas structure implementation */

	[Compact]
	[CCode (cname = "xmlSchema", free_function = "xmlSchemaFree", cheader_filename = "libxml/xmlschemas.h")]
	public class Schema {
		[CCode (cname = "xmlSchemaDump", instance_pos = -1)]
		public void dump (GLib.FileStream output);
	}

	[Compact]
	[CCode (cname = "xmlSchemaParserCtxt", free_function = "xmlSchemaFreeParserCtxt", cheader_filename = "libxml/xmlschemas.h")]
	public class SchemaParserCtxt {
		[CCode (cname = "xmlSchemaNewParserCtxt")]
		public SchemaParserCtxt (string URL);
		[CCode (cname = "xmlSchemaNewDocParserCtxt")]
		public SchemaParserCtxt.from_doc (Xml.Doc doc);
		[CCode (cname = "xmlSchemaNewMemParserCtxt")]
		public SchemaParserCtxt.from_buffer (uint8[] buffer);
		[CCode (cname = "xmlSchemaParse")]
		public Xml.Schema parse ();
	}

	[Compact]
	[CCode (cname = "xmlSchemaValidCtxt", free_function = "xmlSchemaFreeValidCtxt", cheader_filename = "libxml/xmlschemas.h")]
	public class SchemaValidCtxt {
		[CCode (cname = "xmlSchemaNewValidCtxt")]
		public SchemaValidCtxt (Xml.Schema schema);
		[CCode (cname = "xmlSchemaValidateDoc")]
		public int validate_doc (Xml.Doc doc);
	}

	/* xmlsave */

	[Compact]
	[CCode (cname = "xmlSaveCtxt", free_function = "xmlSaveClose", cheader_filename = "libxml/xmlsave.h")]
	public class SaveCtxt {
		[CCode (cname = "xmlSaveToIO")]
		public SaveCtxt.to_io (OutputWriteCallback iowrite, OutputCloseCallback ioclose, void * ioctx = null, string? encoding = null, int options = 0);

		[CCode (cname = "xmlSaveClose")]
		public int close ();
		[CCode (cname = "xmlSaveFlush")]
		public int flush ();
		[CCode (cname = "xmlSaveDoc")]
		public int save_doc (Xml.Doc *doc);
		[CCode (cname = "xmlSaveTree")]
		public int save_tree (Xml.Node *node);
	}

	/* xmlwriter - the XMLWriter implementation */

	[Compact]
	[CCode (cname = "xmlTextWriter", free_function = "xmlFreeTextWriter", cheader_filename = "libxml/xmlwriter.h")]
	public class TextWriter {
		[CCode (cname = "xmlNewTextWriterFilename")]
		public TextWriter.filename (string uri, bool compression = false);

		[CCode (cname = "xmlNewTextWriterDoc")]
		public TextWriter.doc (out Doc doc, bool compression = false);

		[CCode (cname = "xmlNewTextWriterMemory")]
		public TextWriter.memory (Buffer buffer, bool compression = false);

		[CCode (cname = "xmlNewTextWriterPushParser")]
		public TextWriter.parser (ParserCtxt ctxt, bool compression = false);

		[CCode (cname = "xmlNewTextWriterTree")]
		public TextWriter.tree (Doc doc, Node node, bool compression = false);

		[CCode (cname = "xmlTextWriterFlush")]
		public int flush ();

		[CCode (cname = "xmlTextWriterSetIndent")]
		public int set_indent (bool indent);

		[CCode (cname = "xmlTextWriterSetIndentString")]
		public int set_indent_string ([CCode (type = "xmlChar*")] string str);

		/* End */
		[CCode (cname = "xmlTextWriterEndCDATA")]
		public int end_cdata ();

		[CCode (cname = "xmlTextWriterEndComment")]
		public int end_comment ();

		[CCode (cname = "xmlTextWriterEndDocument")]
		public int end_document ();

		[CCode (cname = "xmlTextWriterEndElement")]
		public int end_element ();

		[CCode (cname = "xmlTextWriterEndAttribute")]
		public int end_attribute ();

		[CCode (cname = "xmlTextWriterEndDTD")]
		public int end_dtd ();

		[CCode (cname = "xmlTextWriterEndDTDAttlist")]
		public int end_dtd_attlist ();

		[CCode (cname = "xmlTextWriterEndDTDElement")]
		public int end_dtd_element ();

		[CCode (cname = "xmlTextWriterEndDTDEntity")]
		public int end_dtd_entity ();

		/* Start */

		[CCode (cname = "xmlTextWriterStartCDATA")]
		public int start_cdata ();

		[CCode (cname = "xmlTextWriterStartComment")]
		public int start_comment ();

		[CCode (cname = "xmlTextWriterStartDocument")]
		public int start_document (string? version = null, string? encoding = null, string? standalone = null);

		[CCode (cname = "xmlTextWriterStartElement")]
		public int start_element ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlTextWriterStartElementNS")]
		public int start_element_ns ([CCode (type = "xmlChar*")] string prefix, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? namespaceURI);

		[CCode (cname = "xmlTextWriterStartAttribute")]
		public int start_attribute ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlTextWriterStartAttributeNS")]
		public int start_attribute_ns ([CCode (type = "xmlChar*")] string? prefix, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? namespaceURI);

		[CCode (cname = "xmlTextWriterStartDTD")]
		public int start_dtd ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? pubid, [CCode (type = "xmlChar*")] string? sysid);

		[CCode (cname = "xmlTextWriterStartDTDAttlist")]
		public int start_dtd_attlist ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlTextWriterStartDTDElement")]
		public int start_dtd_element ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlTextWriterStartDTDEntity")]
		public int start_dtd_entity (bool pe, [CCode (type = "xmlChar*")] string name);

		/* write */

		[CCode (cname = "xmlTextWriterWriteAttribute")]
		public int write_attribute ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteAttributeNS")]
		public int write_attribute_ns ([CCode (type = "xmlChar*")] string? prefix, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? namespaceURI, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteElement")]
		public int write_element ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteElementNS")]
		public int write_element_ns ([CCode (type = "xmlChar*")] string prefix, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string namespaceURI, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteBase64")]
		public int write_base64 (void* data, int start, int length);

		[CCode (cname = "xmlTextWriterWriteComment")]
		public int write_comment ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteCDATA")]
		public int write_cdata ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWritePI")]
		public int write_pi ([CCode (type = "xmlChar*")] string target, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteString")]
		public int write_string ([CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteDocType")]
		public int write_document_type ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? pubid, [CCode (type = "xmlChar*")] string? sysid, [CCode (type = "xmlChar*")] string? subset);

		[CCode (cname = "xmlTextWriterWriteDTD")]
		public int write_dtd ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? pubid, [CCode (type = "xmlChar*")] string? sysid, [CCode (type = "xmlChar*")] string? subset);

		[CCode (cname = "xmlTextWriterWriteDTDAttlist")]
		public int write_dtd_attlist ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteDTDElement")]
		public int write_dtd_element ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteDTDEntity")]
		public int write_dtd_entity ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? pubid, [CCode (type = "xmlChar*")] string? sysid, [CCode (type = "xmlChar*")] string ndataid, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteDTDExternalEntity")]
		public int write_dtd_external_entity (bool pe, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? pubid, [CCode (type = "xmlChar*")] string? sysid, [CCode (type = "xmlChar*")] string ndataid);

		[CCode (cname = "xmlTextWriterWriteDTDExternalEntityContents")]
		public int write_dtd_external_entity_contents ([CCode (type = "xmlChar*")] string? pubid, [CCode (type = "xmlChar*")] string? sysid, [CCode (type = "xmlChar*")] string ndataid);

		[CCode (cname = "xmlTextWriterWriteDTDInternalEntity")]
		public int write_dtd_internal_entity (bool pe, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string content);

		[CCode (cname = "xmlTextWriterWriteDTDNotation")]
		public int write_dtd_notation ([CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string? pubid, [CCode (type = "xmlChar*")] string? sysid);

		/* formatted */

		[CCode (cname = "xmlTextWriterWriteFormatAttribute")]
		public int format_attribute ([CCode (type = "xmlChar*")] string name, string format, ...);

		[CCode (cname = "xmlTextWriterWriteFormatAttributeNS")]
		public int format_attribute_ns ([CCode (type = "xmlChar*")] string prefix, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string namespaceURI, string format, ...);

		[CCode (cname = "xmlTextWriterWriteFormatCDATA")]
		public int format_cdata (string format, ...);

		[CCode (cname = "xmlTextWriterWriteFormatComment")]
		public int format_comment (string format, ...);

		[CCode (cname = "xmlTextWriterWriteFormatElement")]
		public int format_element ([CCode (type = "xmlChar*")] string name, string format, ...);

		[CCode (cname = "xmlTextWriterWriteFormatElementNS")]
		public int format_element_ns ([CCode (type = "xmlChar*")] string prefix, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string namespaceURI, string format, ...);

		[CCode (cname = "xmlTextWriterWriteFormatString")]
		public int format_string (string format, ...);
	}

	/* xmlreader - the XMLReader implementation */

	[CCode (cname = "xmlParserProperties", cprefix = "XML_PARSER_", cheader_filename = "libxml/xmlreader.h", has_type_id = false)]
	public enum ParserProperties {
		LOADDTD,
		DEFAULTATTRS,
		VALIDATE,
		SUBST_ENTITIES
	}

	[CCode (cname = "xmlParserSeverities", cprefix = "XML_PARSER_SEVERITY_", cheader_filename = "libxml/xmlreader.h", has_type_id = false)]
	public enum ParserSeverities {
		VALIDITY_WARNING,
		VALIDITY_ERROR,
		WARNING,
		ERROR
	}

	[CCode (cname = "xmlReaderTypes", cheader_filename = "libxml/xmlreader.h", has_type_id = false)]
	public enum ReaderType {
		NONE,
		ELEMENT,
		ATTRIBUTE,
		TEXT,
		CDATA,
		ENTITY_REFERENCE,
		ENTITY,
		PROCESSING_INSTRUCTION,
		COMMENT,
		DOCUMENT,
		DOCUMENT_TYPE,
		DOCUMENT_FRAGMENT,
		NOTATION,
		WHITESPACE,
		SIGNIFICANT_WHITESPACE,
		END_ELEMENT,
		END_ENTITY,
		XML_DECLARATION
	}

	[Compact]
	[CCode (cname = "xmlTextReader", free_function = "xmlFreeTextReader", cheader_filename = "libxml/xmlreader.h")]
	public class TextReader {
		[CCode (cname = "xmlNewTextReaderFilename")]
		public TextReader.filename (string uri);

		[CCode (cname = "xmlReaderForDoc")]
		public TextReader.for_doc ([CCode (type = "xmlChar*")] string cur, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderForFd")]
		public TextReader.for_fd (int fd, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderForFile")]
		public TextReader.for_file (string filename, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderForIO")]
		public TextReader.for_io (InputReadCallback ioread, InputCloseCallback ioclose, void* ioctx, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderForMemory")]
		public TextReader.for_memory ([CCode (array_length = false)] char[] buffer, int size, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderNewDoc")]
		public int new_doc ([CCode (type = "xmlChar*")] string cur, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderNewFd")]
		public int new_fd (int fd, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderNewFile")]
		public int new_file (string filename, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderNewIO")]
		public int new_io (InputReadCallback ioread, InputCloseCallback ioclose, void* ioctx, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderNewMemory")]
		public int new_memory ([CCode (array_length = false)] char[] buffer, int size, string url, string? encoding = null, int options = 0);

		[CCode (cname = "xmlReaderNewWalker")]
		public int new_walker (Doc* doc);

		[CCode (cname = "xmlReaderWalker")]
		public TextReader.walker (Doc* doc);

		[CCode (cname = "xmlTextReaderAttributeCount")]
		public int attribute_count ();

		[CCode (cname = "xmlTextReaderBaseUri", type = "xmlChar*")]
		public string base_uri ();

		[CCode (cname = "xmlTextReaderByteConsumed")]
		public long byte_consumed ();

		[CCode (cname = "xmlTextReaderClose")]
		public int close ();

		[CCode (cname = "xmlTextReaderConstBaseUri", type = "xmlChar*")]
		public unowned string const_base_uri ();

		[CCode (cname = "xmlTextReaderConstEncoding", type = "xmlChar*")]
		public unowned string const_encoding ();

		[CCode (cname = "xmlTextReaderConstLocalName", type = "xmlChar*")]
		public unowned string const_local_name ();

		[CCode (cname = "xmlTextReaderConstName", type = "xmlChar*")]
		public unowned string const_name ();

		[CCode (cname = "xmlTextReaderConstNamespaceUri", type = "xmlChar*")]
		public unowned string const_namespace_uri ();

		[CCode (cname = "xmlTextReaderConstPrefix", type = "xmlChar*")]
		public unowned string const_prefix ();

		[CCode (cname = "xmlTextReaderConstString", type = "xmlChar*")]
		public unowned string const_string ([CCode (type = "xmlChar*")] string str);

		[CCode (cname = "xmlTextReaderConstValue", type = "xmlChar*")]
		public unowned string const_value ();

		[CCode (cname = "xmlTextReaderConstXmlLang", type = "xmlChar*")]
		public unowned string const_xml_lang ();

		[CCode (cname = "xmlTextReaderConstXmlVersion", type = "xmlChar*")]
		public unowned string const_xml_version ();

		[CCode (cname = "xmlTextReaderCurrentDoc")]
		public Doc* current_doc ();

		[CCode (cname = "xmlTextReaderCurrentNode")]
		public Node* current_node ();

		[CCode (cname = "xmlTextReaderDepth")]
		public int depth ();

		[CCode (cname = "xmlTextReaderExpand")]
		public Node* expand ();

		[CCode (cname = "xmlTextReaderGetAttribute", type = "xmlChar*")]
		public string get_attribute (string name);

		[CCode (cname = "xmlTextReaderGetAttributeNo", type = "xmlChar*")]
		public string get_attribute_no (int no);

		[CCode (cname = "xmlTextReaderGetAttributeNs", type = "xmlChar*")]
		public string get_attribute_ns ([CCode (type = "xmlChar*")] string local_name, [CCode (type = "xmlChar*")] string namespace_uri);

		[CCode (cname = "xmlTextReaderGetErrorHandler")]
		public void get_error_handler (out TextReaderErrorFunc f, void** arg);

		[CCode (cname = "xmlTextReaderGetParserColumnNumber")]
		public int get_parser_column_number ();

		[CCode (cname = "xmlTextReaderGetParserLineNumber")]
		public int get_parser_line_number ();

		[CCode (cname = "xmlTextReaderGetParserProp")]
		public int get_parser_prop (int prop);

		[CCode (cname = "xmlTextReaderHasAttributes")]
		public int has_attributes ();

		[CCode (cname = "xmlTextReaderHasValue")]
		public int has_value ();

		[CCode (cname = "xmlTextReaderIsDefault")]
		public int is_default ();

		[CCode (cname = "xmlTextReaderIsEmptyElement")]
		public int is_empty_element ();

		[CCode (cname = "xmlTextReaderIsNamespaceDecl")]
		public int is_namespace_decl ();

		[CCode (cname = "xmlTextReaderIsValid")]
		public int is_valid ();

		[CCode (cname = "xmlTextReaderLocalName", type = "xmlChar*")]
		public string local_name ();

		[CCode (cname = "xmlTextReaderLookupNamespace", type = "xmlChar*")]
		public string lookup_namespace ([CCode (type = "xmlChar*")] string prefix);

		[CCode (cname = "xmlTextReaderMoveToAttribute")]
		public int move_to_attribute ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "xmlTextReaderMoveToAttributeNo")]
		public int move_to_attribute_no (int no);

		[CCode (cname = "xmlTextReaderMoveToAttributeNs")]
		public int move_to_attribute_ns ([CCode (type = "xmlChar*")] string local_name, [CCode (type = "xmlChar*")] string namespace_uri);

		[CCode (cname = "xmlTextReaderMoveToElement")]
		public int move_to_element ();

		[CCode (cname = "xmlTextReaderMoveToFirstAttribute")]
		public int move_to_first_attribute ();

		[CCode (cname = "xmlTextReaderMoveToNextAttribute")]
		public int move_to_next_attribute ();

		[CCode (cname = "xmlTextReaderName", type = "xmlChar*")]
		public string name ();

		[CCode (cname = "xmlTextReaderNamespaceUri", type = "xmlChar*")]
		public string namespace_uri ();

		[CCode (cname = "xmlTextReaderNext")]
		public int next ();

		[CCode (cname = "xmlTextReaderNextSibling")]
		public int next_sibling ();

		[CCode (cname = "xmlTextReaderNodeType")]
		public int node_type ();

		[CCode (cname = "xmlTextReaderNormalization")]
		public int normalization ();

		[CCode (cname = "xmlTextReaderPrefix", type = "xmlChar*")]
		public string prefix ();

		[CCode (cname = "xmlTextReaderPreserve")]
		public Node* preserve ();

		[CCode (cname = "xmlTextReaderPreservePattern")]
		public int preserve_pattern ([CCode (type = "xmlChar*")] string pattern, [CCode (array_length = false, type = "xmlChar**")] string[] namespaces);

		[CCode (cname = "xmlTextReaderQuoteChar")]
		public int quote_char ();

		[CCode (cname = "xmlTextReaderRead")]
		public int read ();

		[CCode (cname = "xmlTextReaderReadAttributeValue")]
		public int read_attribute_value ();

		[CCode (cname = "xmlTextReaderReadInnerXml", type = "xmlChar*")]
		public string read_inner_xml ();

		[CCode (cname = "xmlTextReaderReadOuterXml", type = "xmlChar*")]
		public string read_outer_xml ();

		[CCode (cname = "xmlTextReaderReadState")]
		public int read_state ();

		[CCode (cname = "xmlTextReaderReadString", type = "xmlChar*")]
		public string read_string ();

		[CCode (cname = "xmlTextReaderSchemaValidate")]
		public int schema_validate (string xsd);

		[CCode (cname = "xmlTextReaderSchemaValidateCtxt")]
		public int schema_validate_ctxt (SchemaValidCtxt* ctxt, int options);

		[CCode (cname = "xmlTextReaderSetErrorHandler")]
		public void set_error_handler (TextReaderErrorFunc f, void* arg);

		[CCode (cname = "xmlTextReaderSetParserProp")]
		public int set_parser_prop (SchemaValidCtxt* ctxt, int options);

		[CCode (cname = "xmlTextReaderStandalone")]
		public int standalone ();

		[CCode (cname = "xmlTextReaderValue", type = "xmlChar*")]
		public string value ();

		[CCode (cname = "xmlTextReaderXmlLang", type = "xmlChar*")]
		public string xml_lang ();
	}

	[Compact]
	[CCode (cname = "void", cheader_filename = "libxml/xmlreader.h")]
	public class TextReaderLocator {
	}

	[CCode (cname = "xmlTextReaderMode", cprefix = "XML_TEXTREADER_MODE_", cheader_filename = "libxml/xmlreader.h", has_type_id = false)]
	public enum TextReaderMode {
		INITIAL,
		INTERACTIVE,
		ERROR,
		EOF,
		CLOSED,
		READING
	}

	[CCode (has_target = false)]
	public delegate void TextReaderErrorFunc (void* arg, string msg, ParserSeverities severity, TextReaderLocator* locator);


	/* xpath - XML Path Language implementation */

	[CCode (cheader_filename = "libxml/xpath.h")]
	namespace XPath {
		[CCode (cname = "xmlXPathOrderDocElems")]
		public static long order_doc_elements (Doc* doc);

		[Compact]
		[CCode (cname = "xmlNodeSet", free_function="xmlXPathFreeNodeSet", cheader_filename = "libxml/xpath.h")]
		public class NodeSet {
			[CCode (cname = "xmlXPathNodeSetGetLength")]
			public int length ();

			[CCode (cname = "xmlXPathNodeSetIsEmpty")]
			public bool is_empty ();

			[CCode (cname = "xmlXPathNodeSetItem")]
			public Node* item (int index);
		}

		[Compact]
		[CCode (cname = "xmlXPathContext", free_function = "xmlXPathFreeContext", cheader_filename = "libxml/xpath.h")]
		public class Context {
			public Doc* doc;
			public Node* node;

			[CCode (cname = "xmlXPathContextSetCache")]
			public int set_cache (int active, int value, int options);

			[CCode (cname = "xmlXPathEval", instance_pos = -1)]
			public Object* eval ([CCode (type = "xmlChar*")] string str);

			[CCode (cname = "xmlXPathEvalExpression", instance_pos = -1)]
			public Object* eval_expression ([CCode (type = "xmlChar*")] string str);

			[CCode (cname = "xmlXPathRegisterNs", cheader_filename = "libxml/xpathInternals.h")]
			public int register_ns ([CCode (type = "xmlChar*")] string prefix, [CCode (type = "xmlChar*")] string ns_uri);

			[CCode (cname = "xmlXPathNewContext")]
			public Context (Doc* doc);
		}

		[CCode (cname = "xmlXPathError", cprefix = "XPATH_", cheader_filename = "libxml/xpath.h", has_type_id = false)]
		public enum Error {
			EXPRESSION_OK,
			NUMBER_ERROR,
			UNFINISHED_LITERAL_ERROR,
			START_LITERAL_ERROR,
			VARIABLE_REF_ERROR,
			UNDEF_VARIABLE_ERROR,
			INVALID_PREDICATE_ERROR,
			EXPR_ERROR,
			UNCLOSED_ERROR,
			UNKNOWN_FUNC_ERROR,
			INVALID_OPERAND,
			INVALID_TYPE,
			INVALID_ARITY,
			INVALID_CTXT_SIZE,
			INVALID_CTXT_POSITION,
			MEMORY_ERROR,
			[CCode (cname = "XPTR_SYNTAX_ERROR")]
			XPTR_SYNTAX_ERROR,
			[CCode (cname = "XPTR_RESOURCE_ERROR")]
			XPTR_RESOURCE_ERROR,
			[CCode (cname = "XPTR_SUB_RESOURCE_ERROR")]
			XPTR_SUB_RESOURCE_ERROR,
			UNDEF_PREFIX_ERROR,
			ENCODING_ERROR,
			INVALID_CHAR_ERROR,
			INVALID_CTXT
		}

		[Compact]
		[CCode (cname = "xmlXPathObject", free_function="xmlXPathFreeObject", cheader_filename = "libxml/xpath.h")]
		public class Object {
			public ObjectType type;
			public NodeSet* nodesetval;
			public int boolval;
			public double floatval;
			[CCode (type = "xmlChar*")]
			public string stringval;
			public void* user;
			public int index;
			public void* user2;
			public int index2;
		}

		[CCode (cname = "xmlXPathObjectType", cprefix = "XPATH_", cheader_filename = "libxml/xpath.h", has_type_id = false)]
		public enum ObjectType {
			UNDEFINED,
			NODESET,
			BOOLEAN,
			NUMBER,
			STRING,
			POINT,
			RANGE,
			LOCATIONSET,
			USERS,
			XSLT_TREE
		}
	}

	/* SAX CALLBACKS */

	[CCode (cname = "attributeDeclSAXFunc", has_target = false)]
	public delegate void attributeDeclSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string elem, [CCode (type = "xmlChar*")] string fullname, int type, int def, [CCode (type = "xmlChar*")] string defaultValue, Enumeration* tree);

	[CCode (cname = "attributeSAXFunc", has_target = false)]
	public delegate void attributeSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string value);

	[CCode (cname = "cdataBlockSAXFunc", has_target = false)]
	public delegate void cdataBlockSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string value, int len);

	[CCode (cname = "charactersSAXFunc", has_target = false)]
	public delegate void charactersSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string ch, int len);

	[CCode (cname = "commentsSAXFunc", has_target = false)]
	public delegate void commentSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string value);

	[CCode (cname = "elementDeclSAXFunc", has_target = false)]
	public delegate void elementDeclSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name, int type, ElementContent content);

	[CCode (cname = "endDocumentSAXFunc", has_target = false)]
	public delegate void endDocumentSAXFunc (void* ctx);

	[CCode (cname = "endElementNsSAX2Func", has_target = false)]
	public delegate void endElementNsSAX2Func (void* ctx, [CCode (type = "xmlChar*")] string localname, [CCode (type = "xmlChar*")] string prefix, [CCode (type = "xmlChar*")] string URI);

	[CCode (cname = "endElementSAXFunc", has_target = false)]
	public delegate void endElementSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name);

	[CCode (cname = "entityDeclSAXFunc", has_target = false)]
	public delegate void entityDeclSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name, int type, [CCode (type = "xmlChar*")] string publicId, [CCode (type = "xmlChar*")] string systemId, [CCode (type = "xmlChar*")] string content);

	[CCode (cname = "errorSAXFunc", has_target = false)]
	public delegate void errorSAXFunc (void* ctx, string msg, ...);

	[CCode (cname = "externalSubsetSAXFunc", has_target = false)]
	public delegate void externalSubsetSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string ExternalID, [CCode (type = "xmlChar*")] string SystemID);

	[CCode (cname = "fatalErrorSAXFunc", has_target = false)]
	public delegate void fatalErrorSAXFunc (void* ctx, string msg, ...);

	[CCode (cname = "getEntitySAXFunc", has_target = false)]
	public delegate Entity* getEntitySAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name);

	[CCode (cname = "getParameterEntitySAXFunc", has_target = false)]
	public delegate Entity* getParameterEntitySAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name);

	[CCode (cname = "hasExternalSubsetSAXFunc", has_target = false)]
	public delegate int hasExternalSubsetSAXFunc (void* ctx);

	[CCode (cname = "hasInternalSubsetSAXFunc", has_target = false)]
	public delegate int hasInternalSubsetSAXFunc (void* ctx);

	[CCode (cname = "ignorableWhitespaceSAXFunc", has_target = false)]
	public delegate void ignorableWhitespaceSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string ch, int len);

	[CCode (cname = "internalSubsetSAXFunc", has_target = false)]
	public delegate void internalSubsetSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string ExternalID, [CCode (type = "xmlChar*")] string SystemID);

	[CCode (cname = "isStandaloneSAXFunc", has_target = false)]
	public delegate int isStandaloneSAXFunc (void* ctx);

	[CCode (cname = "notationDeclSAXFunc", has_target = false)]
	public delegate void notationDeclSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string publicId, [CCode (type = "xmlChar*")] string systemId);

	[CCode (cname = "processingInstructionSAXFunc", has_target = false)]
	public delegate void processingInstructionSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string target, [CCode (type = "xmlChar*")] string data);

	[CCode (cname = "referenceSAXFunc", has_target = false)]
	public delegate void referenceSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name);

	// [CCode (cname = "resolveEntitySAXFunc", has_target = false)]
	// public delegate ParserInput resolveEntitySAXFunc (void* ctx, [CCode (type = "xmlChar*")] string publicId, [CCode (type = "xmlChar*")] string systemId);

	// [CCode (cname = "setDocumentLocatorSAXFunc", has_target = false)]
	// public delegate void setDocumentLocatorSAXFunc (void* ctx, SAXLocator loc);

	[CCode (cname = "startDocumentSAXFunc", has_target = false)]
	public delegate void startDocumentSAXFunc (void* ctx);

	[CCode (cname = "startElementNsSAX2Func", has_target = false)]
	public delegate void startElementNsSAX2Func (void* ctx, [CCode (type = "xmlChar*")] string localname, [CCode (type = "xmlChar*")] string prefix, [CCode (type = "xmlChar*")] string URI, int nb_namespaces, [CCode (array_length = false, array_null_terminated = true, type = "xmlChar**")] string[] namespaces, int nb_attributes, int nb_defaulted, [CCode (array_length = false, type = "xmlChar**")] string[] attributes);

	[CCode (cname = "startElementSAXFunc", has_target = false)]
	public delegate void startElementSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name, [CCode (array_length = false, array_null_terminated = true, type = "xmlChar**")] string[] atts);

	[CCode (cname = "unparsedEntityDeclSAXFunc", has_target = false)]
	public delegate void unparsedEntityDeclSAXFunc (void* ctx, [CCode (type = "xmlChar*")] string name, [CCode (type = "xmlChar*")] string publicId, [CCode (type = "xmlChar*")] string systemId, [CCode (type = "xmlChar*")] string notationName);

	[CCode (cname = "warningSAXFunc", has_target = false)]
	public delegate void warningSAXFunc (void* ctx, string msg, ...);

	[CCode (cname ="xmlStructuredErrorFunc", has_target = false)]
	public delegate void xmlStructuredErrorFunc (void* ctx, Error* error);

	[Compact]
	[CCode (cname = "xmlSAXHandler", cheader_filename = "libxml/parser.h")]
	public struct SAXHandler {
		[CCode (cname = "internalSubset")]
		public internalSubsetSAXFunc internalSubset;
		[CCode (cname = "isStandalone")]
		public isStandaloneSAXFunc is_standalone;
		[CCode (cname = "hasInternalSubset")]
		public hasInternalSubsetSAXFunc hasInternalSubset;
		[CCode (cname = "hasExternalSubset")]
		public hasExternalSubsetSAXFunc hasExternalSubset;
		// public resolveEntitySAXFunc resolveEntity;
		[CCode (cname = "getEntity")]
		public getEntitySAXFunc getEntity;
		[CCode (cname = "entityDecl")]
		public entityDeclSAXFunc entityDecl;
		[CCode (cname = "notationDecl")]
		public notationDeclSAXFunc notationDecl;
		[CCode (cname = "attributeDecl")]
		public attributeDeclSAXFunc attributeDecl;
		[CCode (cname = "elementDecl")]
		public elementDeclSAXFunc elementDecl;
		[CCode (cname = "unparsedEntityDecl")]
		public unparsedEntityDeclSAXFunc unparsedEntityDecl;
		// public setDocumentLocatorSAXFunc setDocumentLocator;
		[CCode (cname = "startDocument")]
		public startDocumentSAXFunc startDocument;
		[CCode (cname = "endDocument")]
		public endDocumentSAXFunc endDocument;
		[CCode (cname = "startElement")]
		public startElementSAXFunc startElement;
		[CCode (cname = "endElement")]
		public endElementSAXFunc endElement;
		public referenceSAXFunc reference;
		public charactersSAXFunc characters;
		[CCode (cname = "ignorableWhitespace")]
		public ignorableWhitespaceSAXFunc ignorableWhitespace;
		[CCode (cname = "processingInstruction")]
		public processingInstructionSAXFunc processingInstruction;
		public commentSAXFunc comment;
		public warningSAXFunc warning;
		public errorSAXFunc error;
		[CCode (cname = "fatalError")]
		public fatalErrorSAXFunc fatalError;
		[CCode (cname = "getParameterEntity")]
		public getParameterEntitySAXFunc getParameterEntity;
		[CCode (cname = "cdataBlock")]
		public cdataBlockSAXFunc cdataBlock;
		[CCode (cname = "externalSubset")]
		public externalSubsetSAXFunc externalSubset;
		public uint initialized;
		[CCode (cname = "startElementNs")]
		public startElementNsSAX2Func startElementNs;
		[CCode (cname = "endElementNs")]
		public endElementNsSAX2Func endElementNs;
		public xmlStructuredErrorFunc serror;

		[CCode (cname = "xmlSAXUserParseMemory")]
		public int user_parse_memory (void* user_data, string buffer, int size);
		[CCode (cname = "xmlSAXUserParseFile")]
		public int user_parse_file (void* user_data, string filename);
	}


	/* xmlerror - error handling */

	[Compact]
	[CCode (cname = "xmlError", cheader_filename = "libxml/xmlerror.h")]
	public struct Error {
		public int domain;
		public int code;
		public string message;
		public ErrorLevel level;
		public string file;
		public int line;
		public string str1;
		public string str2;
		public string str3;
		public int int1;
		public int int2;
		public void* ctx;
		public void* node;
	}

	[CCode (cname = "xmlErrorLevel", cprefix = "XML_ERR_", cheader_filename = "libxml/xmlerror.h", has_type_id = false)]
	public enum ErrorLevel {
		NONE = 0,
		WARNING = 1,
		ERROR = 2,
		FATAL = 3
	}

	[CCode (cname = "xmlGetLastError", cheader_filename = "libxml/xmlerror.h")]
	public static Error* get_last_error ();

	[CCode (cname = "xmlResetLastError", cheader_filename = "libxml/xmlerror.h")]
	public static void reset_last_error ();
}

namespace Html {
	[CCode (cname = "htmlIsBooleanAttr", cheader_filename = "libxml/HTMLtree.h")]
	public static int is_boolean_attr ([CCode (type = "xmlChar*")] string name);

	[CCode (cname = "UTF8ToHtml", cheader_filename = "libxml/HTMLparser.h")]
	public static int utf8_to_html ([CCode (array_length = false)] char[] outdata, ref int outlen, [CCode (array_length = false)] char[] indata, ref int inlen);

	[CCode (cname = "htmlEncodeEntities", cheader_filename = "libxml/HTMLparser.h")]
	public static int encode_entities ([CCode (array_length = false)] char[] outdata, ref int outlen, [CCode (array_length = false)] char[] indata, ref int inlen, char quote_char = '\0');

	[CCode (cname = "htmlIsScriptAttribute", cheader_filename = "libxml/HTMLparser.h")]
	public static bool is_script_attribute ([CCode (type = "xmlChar*")] string name);

	[CCode (cname = "htmlHandleOmittedElem", cheader_filename = "libxml/HTMLparser.h")]
	public static bool handle_omitted_elem (bool val);

	[CCode (cname = "htmlParserOption", cprefix = "HTML_PARSE_", cheader_filename = "libxml/HTMLparser.h", has_type_id = false)]
	public enum ParserOption {
		RECOVER,
		NOERROR,
		NOWARNING,
		PEDANTIC,
		NOBLANKS,
		NONET,
		COMPACT,
	}

	[CCode (cname = "htmlStatus", cprefix = "HTML_", cheader_filename = "libxml/HTMLparser.h", has_type_id = false)]
	public enum Status {
		NA,
		INVALID,
		DEPRECATED,
		VALID,
		REQUIRED,
	}

	[Compact]
	[CCode (cname = "xmlNode", cheader_filename = "libxml/HTMLparser.h")]
	public class Node : Xml.Node {
		[CCode (cname = "htmlNodeStatus")]
		public Status status (bool legacy);
	}

	[Compact]
	[CCode (cname = "xmlDoc", cheader_filename = "libxml/HTMLtree.h,libxml/HTMLparser.h")]
	public class Doc : Xml.Doc {
		[CCode (cname = "htmlNewDoc")]
		public Doc ([CCode (type = "xmlChar*")] string? uri = null, string? external_id = null);

		[CCode (cname = "htmlNewDocNoDtD")]
		public Doc.new_no_dtd ([CCode (type = "xmlChar*")] string? uri = null, string? external_id = null);

		[CCode (cname = "htmlSAXParseDoc")]
		public static Doc* sax_parse_doc ([CCode (type = "xmlChar*")] string cur, string? encoding, Xml.SAXHandler* sax, void* user_data = null);

		[CCode (cname = "htmlSAXParseFile")]
		public static Doc* sax_parse_file (string filename, string? encoding, Xml.SAXHandler* sax, void* user_data = null);

		[CCode (cname = "htmlParseFile")]
		public static Doc* parse_file (string filename, string? encoding);

		[CCode (cname = "htmlReadDoc")]
		public static Doc* read_doc ([CCode (type = "xmlChar*")] string cur, string url, string? encoding = null, int options = 0);

		[CCode (cname = "htmlReadMemory")]
		public static Doc* read_memory ([CCode (array_length = false)] char[] buffer, int size, string url, string? encoding = null, int options = 0);

		[CCode (cname = "htmlReadFd")]
		public static Doc* read_fd (int fd, string url, string? encoding = null, int options = 0);

		[CCode (cname = "htmlReadIO")]
		public static Doc* read_io (Xml.InputReadCallback ioread, Xml.InputCloseCallback ioclose, void* ioctx, string url, string? encoding = null, int options = 0);

		[CCode (cname = "htmlGetMetaEncoding", type = "xmlChar*")]
		public string get_meta_encoding ();

		[CCode (cname = "htmlSetMetaEncoding")]
		public int set_meta_encoding ([CCode (type = "xmlChar*")] string encoding);

		[CCode (cname = "htmlDocDumpMemory")]
		public void dump_memory ([CCode (type = "xmlChar**")] out string mem, out int len = null);

		[CCode (cname = "htmlDocDumpMemoryFormat")]
		public void dump_memory_format ([CCode (type = "xmlChar**")] out string mem, out int len = null, bool format = true);

		[CCode (cname = "htmlDocDump", instance_pos = -1)]
		public int dump (GLib.FileStream f);

		[CCode (cname = "htmlSaveFile", instance_pos = -1)]
		public int save_file (string filename);

		[CCode (cname = "htmlNodeDumpFile", instance_pos = 1.1)]
		public int node_dump_file (GLib.FileStream file, Xml.Node* node);

		[CCode (cname = "htmlNodeDumpFileFormat", instance_pos = 1.1)]
		public int node_dump_file_format (GLib.FileStream file, string enc = "UTF-8", bool format = true);

		[CCode (cname = "htmlSaveFileEnc", instance_pos = 1.1)]
		public int save_file_enc (string filename, string enc = "UTF-8");

		[CCode (cname = "htmlSaveFileFormat", instance_pos = 1.1)]
		public int save_file_format (string filename, string enc = "UTF-8", bool format = true);

		[CCode (cname = "htmlIsAutoClosed")]
		public bool is_auto_closed (Node* elem);

		[CCode (cname = "htmlAutoCloseTag")]
		public bool auto_close_tag ([CCode (type = "xmlChar*")] string name, Node* elem);
	}

	[Compact]
	[CCode (cname = "htmlElemDesc", cheader_filename = "libxml/HTMLparser.h")]
	public class ElemDesc {
		public weak string name;
		[CCode (cname = "startTag")]
		public bool start_tag;
		[CCode (cname = "endTag")]
		public bool end_tag;
		[CCode (cname = "saveEndTag")]
		public bool save_end_tag;
		public bool empty;
		public bool depr;
		public char dtd;
		public bool isinline;
		public weak string desc;
		public weak string[] subelts;
		public weak string defaultsubelt;
		public weak string[] attrs_opt;
		public weak string[] attrs_depr;
		public weak string[] attrs_req;

		[CCode (cname = "htmlTagLookup")]
		public static ElemDesc* tag_lookup ([CCode (type = "xmlChar*")] string tag);

		[CCode (cname = "htmlAttrAllowed")]
		public Status attr_allowed ([CCode (type = "xmlChar*")] string attr, bool legacy);

		[CCode (cname = "htmlElementAllowedHere")]
		public bool allowed_here ([CCode (type = "xmlChar*")] string elt);

		[CCode (cname = "htmlElementAllowedHereDesc")]
		public bool allowed_here_desc (ElemDesc* child);

		[CCode (cname = "htmlElementStatusHere")]
		public Status status_here (ElemDesc* child);

		[Ccode (cname = "htmlDefaultSubelement")]
		public unowned string default_subelement ();

		[Ccode (cname = "htmlRequiredAttrs")]
		public unowned string[] required_attrs ();
	}

	[Compact]
	[CCode (cname = "htmlEntityDesc", cheader_filename = "libxml/HTMLParser.h")]
	public class EntityDesc
	{
		public uint value;
		public weak string name;
		public weak string desc;

		[CCode (cname = "htmlEntityLookup")]
		public static EntityDesc* lookup ([CCode (type = "xmlChar*")] string name);

		[CCode (cname = "htmlEntityValueLookup")]
		public static EntityDesc* value_lookup (uint value);
	}

	[Compact]
	[CCode (cname = "htmlParserCtxt", free_function = "htmlFreeParserCtxt", cheader_filename = "libxml/HTMLparser.h")]
	public class ParserCtxt : Xml.ParserCtxt {
		[CCode (cname = "htmlNewParserCtxt")]
		public ParserCtxt ();

		[CCode (cname = "htmlCreateMemoryParserCtxt")]
		public ParserCtxt.create_memory ([CCode (array_length = false)] char[] buffer, int size);

		[CCode (cname = "htmlCreatePushParserCtxt")]
		public ParserCtxt.create_push (Xml.SAXHandler* sax, void* user_data, [CCode (array_length = false)] char[] data, int len, string? filename = null, Xml.CharEncoding enc = Xml.CharEncoding.NONE);

		[CCode (cname = "htmlParseChunk")]
		public int parse_chunk ([CCode (array_length = false)] char[] data, int size, bool terminate);

		[CCode (cname = "htmlParseEntityRef")]
		public EntityDesc* parse_entity_ref ([CCode (type = "xmlChar**")] out string entity_name);

		[CCode (cname = "htmlParseCharRef")]
		public int parse_char_ref ();

		[CCode (cname = "htmlParseElement")]
		public void parse_element ();

		[CCode (cname = "htmlParseDocument")]
		public int parse_document ();

		[CCode (cname = "htmlCtxtReset")]
		public void reset ();

		[CCode (cname = "htmlCtxtUseOptions")]
		public int use_options (int options);

		[CCode (cname = "htmlCtxtReadDoc")]
		public Doc* read_doc ([CCode (type = "xmlChar*")] string cur, string url, string? encoding = null, int options = 0);

		[CCode (cname = "htmlCtxtReadFile")]
		public Doc* read_file (string filename, string? encoding = null, int options = 0);

		[CCode (cname = "htmlCtxtReadMemory")]
		public Doc* read_memory ([CCode (array_length = false)] char[] buffer, int size, string url, string? encoding = null, int options = 0);

		[CCode (cname = "htmlCtxtReadFd")]
		public Doc* read_fd (int fd, string url, string? encoding = null, int options = 0);

		[CCode (cname = "htmlCtxtReadIO")]
		public Doc* read_io (Xml.InputReadCallback ioread, Xml.InputCloseCallback ioclose, void* ioctx, string url, string? encoding = null, int options = 0);
	}
}
