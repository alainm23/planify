[CCode (cheader_filename = "enchant.h")]
namespace Enchant {
	public unowned string get_version ();

	public delegate void BrokerDescribeFn (string provider_name, string provider_desc, string provider_dll_file);
	public delegate void DictDescribeFn (string lang_tag, string provider_name, string provider_desc, string provider_file);

	[Compact]
	[CCode (free_function = "enchant_broker_free")]
	public class Broker {
		[CCode (cname = "enchant_broker_init")]
		public Broker ();

		public unowned Dict request_dict (string tag);
		public unowned Dict request_pwl_dict (string pwl);
		public void free_dict (Dict dict);
		public int dict_exists (string tag);
		public void set_ordering (string tag, string ordering);
		public void describe (BrokerDescribeFn fn);
		public void list_dicts (DictDescribeFn fn);
		public unowned string get_error ();
	}

	[Compact]
	public class Dict {
		public int check (string word, long len = -1);
		[CCode (array_length_type = "size_t")]
		public unowned string[] suggest (string word, long len = -1);
		public void free_string_list ([CCode (array_length = false)] string[] string_list);
		public void add_to_session (string word, long len = -1);
		public int is_in_session (string word, long len = -1);
		public void store_replacement ( string mis, long mis_len, string cor, long cor_len);
		public void add_to_pwl ( string word, long len = -1);
		public void describe (DictDescribeFn fn);
		public unowned string get_error ();
	}
}
