/* readline.vapi
 *
 * Copyright (C) 2009  Jukka-Pekka Iivonen <jp0409@jippii.fi>
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

[CCode (lower_case_cprefix = "", cheader_filename = "stdio.h,readline/readline.h")]
namespace Readline {
	[CCode (cname = "free", cheader_filename = "stdlib.h")]
	private void _free (void* p);

	[CCode (cname = "rl_command_func_t", has_target = false)]
	public delegate int      CommandFunc (int a, int b);
	[CCode (cname = "rl_completion_func_t", has_target = false, array_length = false, array_null_terminated = true)]
	public delegate string[]? CompletionFunc (string str, int a, int b);
	[CCode (cname = "rl_compentry_func_t", has_target = false)]
	public delegate string?  CompentryFunc (string str, int a);
	[CCode (cname = "rl_quote_func_t", has_target = false)]
	public delegate string   QuoteFunc (string str, int a, string b);
	[CCode (cname = "rl_dequote_func_t", has_target = false)]
	public delegate string   DequoteFunc (string str, int a);
	[CCode (cname = "rl_compignore_func_t", has_target = false)]
	public delegate int      CompignoreFunc (string[] strs);
	[CCode (cname = "rl_compdisp_func_t", has_target = false)]
	public delegate void     CompdispFunc (string[] s, int a, int b);
	[CCode (cname = "rl_hook_func_t", has_target = false)]
	public delegate int      HookFunc ();
	[CCode (cname = "rl_getc_func_t", has_target = false)]
	public delegate int      GetcFunc (GLib.FileStream s);
	[CCode (cname = "rl_linebuf_func_t", has_target = false)]
	public delegate int      LinebufFunc (string s, int a);
	[CCode (cname = "rl_intfunc_t", has_target = false)]
	public delegate int      IntFunc (int a);
	[CCode (cname = "rl_icpfunc_t", has_target = false)]
	public delegate int      IcpFunc (string s);
	[CCode (cname = "rl_icppfunc_t", has_target = false)]
	public delegate int      IcppFunc (string[] s);
	[CCode (cname = "rl_voidfunc_t", has_target = false)]
	public delegate void     VoidFunc ();
	[CCode (cname = "rl_vintfunc_t", has_target = false)]
	public delegate void     VintFunc (int a);
	[CCode (cname = "rl_vcpfunc_t", has_target = false)]
	public delegate void     VcpFunc (string? s);
	[CCode (cname = "rl_vcppfunc_t", has_target = false)]
	public delegate void     VcppFunc (string[] s);
	[CCode (cname = "rl_cpvfunc_t", has_target = false)]
	public delegate unowned string?   CpvFunc ();
	[CCode (cname = "rl_cpifunc_t", has_target = false)]
	public delegate unowned string?   CpiFunc (int s);

	[CCode (cname = "KEYMAP_ENTRY", has_type_id = false)]
	public struct KeyMap {
		public char type;
		public CommandFunc function;
	}

	[CCode (cname = "KEYMAP_SIZE")]
	public int KEYMAP_SIZE;

	[CCode (cname = "ANYOTHERKEY")]
	public int ANYOTHERKEY;

	[CCode (cname = "KEYMAP_ENTRY_ARRAY")]
	public KeyMap[] KEYMAP_ENTRY_ARRAY;

	[CCode (cname = "Keymap")]
	public KeyMap Keymap;

	[CCode (cname = "ISFUNC")]
	public int ISFUNC;

	[CCode (cname = "ISKMAP")]
	public int ISKMAP;

	[CCode (cname = "ISMACR")]
	public int ISMACR;

	[CCode (cname = "RL_READLINE_VERSION")]
	public const uint READLINE_VERSION;

	[CCode (cname = "RL_VERSION_MAJOR")]
	public const int VERSION_MAJOR;

	[CCode (cname = "RL_VERSION_MINOR")]
	public const int VERSION_MINOR;

	[CCode (cname = "enum undo_code", cprefix = "UNDO_", has_type_id = false)]
	public enum UndoCode {
		DELETE,
		INSERT,
		BEGIN,
		END
	}

	[CCode (cname = "UNDO_LIST", has_type_id = false)]
	public struct UndoList {
		public void*    next;
		public int      start;
		public int      end;
		public string   text;
		public UndoCode what;
	}

	[CCode (cname = "rl_undo_list")]
	public UndoList undo_list;

	[CCode (cname = "FUNMAP", has_type_id = false)]
	public struct FunMap {
		public string      name;
		public CommandFunc function;
	}

	[CCode (cname = "funmap")]
	public FunMap[] funmap;

	[CCode (cname = "rl_digit_argument")]
	public int digit_argument (int a, int b);

	[CCode (cname = "rl_universal_argument")]
	public int universal_argument (int a, int b);

	[CCode (cname = "rl_forward_byte")]
	public int forward_byte (int a, int b);

	[CCode (cname = "rl_forward_char")]
	public int forward_char (int a, int b);

	[CCode (cname = "rl_forward")]
	public int forward (int a, int b);

	[CCode (cname = "rl_backward_byte")]
	public int backward_byte (int a, int b);

	[CCode (cname = "rl_char")]
	public int backward_char (int a, int b);

	[CCode (cname = "rl_backward")]
	public int backward (int a, int b);

	[CCode (cname = "rl_beg_of_line")]
	public int beg_of_line (int a, int b);

	[CCode (cname = "rl_end_of_line")]
	public int end_of_line (int a, int b);

	[CCode (cname = "rl_forward_word")]
	public int forward_word (int a, int b);

	[CCode (cname = "rl_backward_word")]
	public int backward_word (int a, int b);

	[CCode (cname = "rl_refresh_line")]
	public int refresh_line (int a, int b);

	[CCode (cname = "rl_clear_screen")]
	public int clear_screen (int a, int b);

	[CCode (cname = "rl_array_keys")]
	public int arrow_keys (int a, int b);

	[CCode (cname = "rl_insert")]
	public int insert (int a, int b);

	[CCode (cname = "rl_quoted_insert")]
	public int quoted_insert (int a, int b);

	[CCode (cname = "rl_tab_insert")]
	public int tab_insert (int a, int b);

	[CCode (cname = "rl_newline")]
	public int newline (int a, int b);

	[CCode (cname = "rl_do_lowercase_version")]
	public int do_lowercase_version (int a, int b);

	[CCode (cname = "rl_rubout")]
	public int rubout (int a, int b);

	[CCode (cname = "rl_delete")]
	public int del (int a, int b);

	[CCode (cname = "rl_rubout_or_delete")]
	public int rubout_or_delete (int a, int b);

	[CCode (cname = "rl_delete_horizontal_space")]
	public int delete_horizontal_space (int a, int b);

	[CCode (cname = "rl_delete_or_show_completions")]
	public int delete_or_show_completions (int a, int b);

	[CCode (cname = "rl_insert_comment")]
	public int insert_comment (int a, int b);

	[CCode (cname = "rl_upcase_word")]
	public int upcase_word (int a, int b);

	[CCode (cname = "rl_downcase_word")]
	public int downcase_word (int a, int b);

	[CCode (cname = "rl_capitalize_word")]
	public int capitalize_word (int a, int b);

	[CCode (cname = "rl_transpose_words")]
	public int transpose_words (int a, int b);

	[CCode (cname = "rl_transpose_chars")]
	public int transpose_chars (int a, int b);

	[CCode (cname = "rl_char_search")]
	public int char_search (int a, int b);

	[CCode (cname = "rl_backward_char_search")]
	public int backward_char_search (int a, int b);

	[CCode (cname = "rl_beginning_of_history")]
	public int beginning_of_history (int a, int b);

	[CCode (cname = "rl_end_of_history")]
	public int end_of_history (int a, int b);

	[CCode (cname = "rl_get_next_history")]
	public int get_next_history (int a, int b);

	[CCode (cname = "rl_get_previous_history")]
	public int get_previous_history (int a, int b);

	[CCode (cname = "rl_set_mark")]
	public int set_mark (int a, int b);

	[CCode (cname = "rl_exchange_point_and_mark")]
	public int exchange_point_and_mark (int a, int b);

	[CCode (cname = "rl_vi_editing_mode")]
	public int vi_editing_mode (int a, int b);

	[CCode (cname = "rl_emacs_editing_mode")]
	public int emacs_editing_mode (int a, int b);

	[CCode (cname = "rl_overwrite_mode")]
	public int overwrite_mode (int a, int b);

	[CCode (cname = "rl_re_read_init_file")]
	public int re_read_init_file (int a, int b);

	[CCode (cname = "rl_dump_functions")]
	public int dump_functions (int a, int b);

	[CCode (cname = "rl_dump_macros")]
	public int dump_macros (int a, int b);

	[CCode (cname = "rl_dump_variables")]
	public int dump_variables (int a, int b);

	[CCode (cname = "rl_complete")]
	public int complete (int a, int b);

	[CCode (cname = "rl_possible_completions")]
	public int possible_completions (int a, int b);

	[CCode (cname = "rl_insert_completions")]
	public int insert_completions (int a, int b);

	[CCode (cname = "rl_menu_complete")]
	public int menu_complete (int a, int b);

	[CCode (cname = "rl_kill_word")]
	public int kill_word (int a, int b);

	[CCode (cname = "rl_backward_kill_word")]
	public int backward_kill_word (int a, int b);

	[CCode (cname = "rl_kill_line")]
	public int kill_line (int a, int b);

	[CCode (cname = "rl_backward_kill_line")]
	public int backward_kill_line (int a, int b);

	[CCode (cname = "rl_kill_full_line")]
	public int kill_full_line (int a, int b);

	[CCode (cname = "rl_unix_word_rubout")]
	public int unix_word_rubout (int a, int b);

	[CCode (cname = "rl_unix_filename_rubout")]
	public int unix_filename_rubout (int a, int b);

	[CCode (cname = "rl_unix_line_discard")]
	public int unix_line_discard (int a, int b);

	[CCode (cname = "rl_copy_region_to_kill")]
	public int copy_region_to_kill (int a, int b);

	[CCode (cname = "rl_kill_region")]
	public int kill_region (int a, int b);

	[CCode (cname = "rl_copy_forward_word")]
	public int copy_forward_word (int a, int b);

	[CCode (cname = "rl_copy_backward_word")]
	public int copy_backward_word (int a, int b);

	[CCode (cname = "rl_yank")]
	public int yank (int a, int b);

	[CCode (cname = "rl_yank_pop")]
	public int yank_pop (int a, int b);

	[CCode (cname = "rl_yank_nth_arg")]
	public int yank_nth_arg (int a, int b);

	[CCode (cname = "rl_yank_last_arg")]
	public int yank_last_arg (int a, int b);

	[CCode (cname = "rl_paste_from_clipboard")]
	public int paste_from_clipboard (int a, int b);

	[CCode (cname = "rl_reverse_search_history")]
	public int reverse_search_history (int a, int b);

	[CCode (cname = "rl_forward_search_history")]
	public int forward_search_history (int a, int b);

	[CCode (cname = "rl_start_kbd_macro")]
	public int start_kbd_macro (int a, int b);

	[CCode (cname = "rl_end_kbd_macro")]
	public int end_kbd_macro (int a, int b);

	[CCode (cname = "rl_call_last_kbd_macro")]
	public int call_last_kbd_macro (int a, int b);

	[CCode (cname = "rl_revert_line")]
	public int revert_line (int a, int b);

	[CCode (cname = "rl_undo_command")]
	public int undo_command (int a, int b);

	[CCode (cname = "rl_tilde_expand")]
	public int tilde_expand (int a, int b);

	[CCode (cname = "rl_restart_output")]
	public int restart_output (int a, int b);

	[CCode (cname = "rl_stop_output")]
	public int stop_output (int a, int b);

	[CCode (cname = "rl_abort")]
	public int abort (int a, int b);

	[CCode (cname = "rl_tty_status")]
	public int tty_status (int a, int b);

	[CCode (cname = "rl_history_search_forward")]
	public int history_search_forward (int a, int b);

	[CCode (cname = "rl_history_search_backward")]
	public int history_search_backward (int a, int b);

	[CCode (cname = "rl_noninc_forward_search")]
	public int noninc_forward_search (int a, int b);

	[CCode (cname = "rl_noninc_reverse_search")]
	public int noninc_reverse_search (int a, int b);

	[CCode (cname = "rl_noninc_forward_search_again")]
	public int noninc_forward_search_again (int a, int b);

	[CCode (cname = "rl_noninc_reverse_search_again")]
	public int noninc_reverse_search_again (int a, int b);

	[CCode (cname = "rl_insert_close")]
	public int insert_close (int a, int b);

	[CCode (cname = "rl_callback_handler_install")]
	public void callback_handler_install (string prompt, VcpFunc func);

	[CCode (cname = "rl_callback_read_char")]
	public void callback_read_char ();

	[CCode (cname = "rl_callback_handler_remove")]
	public void callback_handler_remove ();

	[CCode (cname = "rl_vi_redo")]
	public int vi_redo (int a, int b);

	[CCode (cname = "rl_vi_undo")]
	public int vi_undo (int a, int b);

	[CCode (cname = "rl_vi_yank_arg")]
	public int vi_yank_arg (int a, int b);

	[CCode (cname = "rl_vi_fetch_history")]
	public int vi_fetch_history (int a, int b);

	[CCode (cname = "rl_vi_search_again")]
	public int vi_search_again (int a, int b);

	[CCode (cname = "rl_vi_search")]
	public int vi_search (int a, int b);

	[CCode (cname = "rl_vi_complete")]
	public int vi_complete (int a, int b);

	[CCode (cname = "rl_vi_tilde_expand")]
	public int vi_tilde_expand (int a, int b);

	[CCode (cname = "rl_vi_prev_word")]
	public int vi_prev_word (int a, int b);

	[CCode (cname = "rl_vi_next_word")]
	public int vi_next_word (int a, int b);

	[CCode (cname = "rl_vi_end_word")]
	public int vi_end_word (int a, int b);

	[CCode (cname = "rl_vi_insert_beg")]
	public int vi_insert_beg (int a, int b);

	[CCode (cname = "rl_vi_append_mode")]
	public int vi_append_mode (int a, int b);

	[CCode (cname = "rl_vi_append_eol")]
	public int vi_append_eol (int a, int b);

	[CCode (cname = "rl_vi_eof_maybe")]
	public int vi_eof_maybe (int a, int b);

	[CCode (cname = "rl_vi_insertion_mode")]
	public int vi_insertion_mode (int a, int b);

	[CCode (cname = "rl_vi_movement_mode")]
	public int vi_movement_mode (int a, int b);

	[CCode (cname = "rl_vi_arg_digit")]
	public int vi_arg_digit (int a, int b);

	[CCode (cname = "rl_vi_change_case")]
	public int vi_change_case (int a, int b);

	[CCode (cname = "rl_vi_put")]
	public int vi_put (int a, int b);

	[CCode (cname = "rl_vi_column")]
	public int vi_column (int a, int b);

	[CCode (cname = "rl_vi_delete_to")]
	public int vi_delete_to (int a, int b);

	[CCode (cname = "rl_vi_change_to")]
	public int vi_change_to (int a, int b);

	[CCode (cname = "rl_vi_yank_to")]
	public int vi_yank_to (int a, int b);

	[CCode (cname = "rl_vi_rubout")]
	public int vi_rubout (int a, int b);

	[CCode (cname = "rl_vi_delete")]
	public int vi_delete (int a, int b);

	[CCode (cname = "rl_vi_back_to_indent")]
	public int vi_back_to_indent (int a, int b);

	[CCode (cname = "rl_vi_first_print")]
	public int vi_first_print (int a, int b);

	[CCode (cname = "rl_vi_char_search")]
	public int vi_char_search (int a, int b);

	[CCode (cname = "rl_vi_match")]
	public int vi_match (int a, int b);

	[CCode (cname = "rl_vi_change_char")]
	public int vi_change_char (int a, int b);

	[CCode (cname = "rl_vi_subst")]
	public int vi_subst (int a, int b);

	[CCode (cname = "rl_vi_overstrike")]
	public int vi_overstrike (int a, int b);

	[CCode (cname = "rl_vi_overstrike_delete")]
	public int vi_overstrike_delete (int a, int b);

	[CCode (cname = "rl_vi_replace")]
	public int vi_replace (int a, int b);

	[CCode (cname = "rl_vi_set_mark")]
	public int vi_set_mark (int a, int b);

	[CCode (cname = "rl_vi_goto_mark")]
	public int vi_goto_mark (int a, int b);

	[CCode (cname = "rl_vi_check")]
	public int vi_check ();

	[CCode (cname = "rl_vi_domove")]
	public int vi_domove (int a, out int b);

	[CCode (cname = "rl_vi_bracktype")]
	public int vi_bracktype (int a);

	[CCode (cname = "rl_vi_start_inserting")]
	public void vi_start_inserting (int a, int b, int c);

	[CCode (cname = "rl_vi_fWord")]
	public int vi_fWord (int a, int b);

	[CCode (cname = "rl_vi_bWord")]
	public int vi_bWord (int a, int b);

	[CCode (cname = "rl_vi_eWord")]
	public int vi_eWord (int a, int b);

	[CCode (cname = "rl_vi_fword")]
	public int vi_fword (int a, int b);

	[CCode (cname = "rl_bword")]
	public int vi_bword (int a, int b);

	[CCode (cname = "rl_vi_eword")]
	public int vi_eword (int a, int b);

	[CCode (cname = "readline")]
	public void* _readline (string? prompt);

	[CCode (cname = "__readline")]
	public string? readline (string? prompt) {
		void* cstr = _readline (prompt);
		if ( cstr == null )
			return null;
		string str = ((string) cstr).dup ();
		_free (cstr);
		return str;
	}

	[CCode (cname = "rl_set_prompt")]
	public int set_prompt (string prompt);

	[CCode (cname = "rl_expand_prompt")]
	public int expand_prompt (string prompt);

	[CCode (cname = "rl_initialize")]
	public int initialize ();

	[CCode (cname = "rl_discard_argument")]
	public int discard_argument ();

	[CCode (cname = "rl_add_defun")]
	public int add_defun (string name, CommandFunc func, int key);

	[CCode (cname = "rl_bind_key")]
	public int bind_key (int key, CommandFunc func);

	[CCode (cname = "rl_bind_key_in_map")]
	public int bind_key_in_map (int key, CommandFunc func, KeyMap map);

	[CCode (cname = "rl_unbind_key")]
	public int unbind_key (int key);

	[CCode (cname = "rl_unbind_key_in_map")]
	public int unbind_key_in_map (int key, KeyMap map);

	[CCode (cname = "rl_bind_key_if_unbound")]
	public int bind_key_if_unbound (int key, CommandFunc func);

	[CCode (cname = "rl_bind_key_if_unbound_in_map")]
	public int bind_key_if_unbound_in_map (int key, CommandFunc func, KeyMap map);

	[CCode (cname = "rl_unbind_function_in_map")]
	public int unbind_function_in_map (CommandFunc func, KeyMap map);

	[CCode (cname = "rl_unbind_command_in_map")]
	public int unbind_command_in_map (string command, KeyMap map);

	[CCode (cname = "rl_bind_keyseq")]
	public int bind_keyseq (string keyseq, CommandFunc func);

	[CCode (cname = "rl_bind_keyseq_in_map")]
	public int bind_keyseq_in_map (string keyseq, CommandFunc func, KeyMap map);

	[CCode (cname = "rl_bind_keyseq_if_unbound")]
	public int bind_keyseq_if_unbound (string keyseq, CommandFunc func);

	[CCode (cname = "rl_bind_keyseq_if_unbound_in_map")]
	public int bind_keyseq_if_unbound_in_map (string keyseq, CommandFunc func, KeyMap map);

	[CCode (cname = "rl_generic_bing")]
	public int generic_bind (int type, string keyseq, string data, KeyMap map);

	[CCode (cname = "rl_variable_value")]
	public string variable_value (string variable);

	[CCode (cname = "rl_variable_bind")]
	public int variable_bind (string variable, string value);

	[CCode (cname = "rl_set_key")]
	public int set_key (string keyseq, CommandFunc func, KeyMap map);

	[CCode (cname = "rl_macro_bind")]
	public int macro_bind (string keyseq, string macro, KeyMap map);

	[CCode (cname = "rl_translate_keyseq")]
	public int translate_keyseq (string a, string b, out int c);

	[CCode (cname = "rl_untranslate_keyseq")]
	public string untranslate_keyseq (int keyseq);

	[CCode (cname = "rl_named_function")]
	public CommandFunc named_function (string name);

	[CCode (cname = "rl_function_of_keyseq")]
	public CommandFunc function_of_keyseq (string keyseq, KeyMap map, out int type);

	[CCode (cname = "rl_list_funmap_names")]
	public void list_funmap_names ();

	[CCode (cname = "rl_invoking_keyseqs_in_map")]
	public unowned string[] invoking_keyseqs_in_map (CommandFunc func, KeyMap map);

	[CCode (cname = "rl_invoking_keyseqs")]
	public unowned string[] invoking_keyseqs (CommandFunc func);

	[CCode (cname = "rl_function_dumper")]
	public void function_dumper (int readable);

	[CCode (cname = "rl_macro_dumper")]
	public void macro_dumper (int readable);

	[CCode (cname = "rl_variable_dumper")]
	public void variable_dumper (int readable);

	[CCode (cname = "rl_read_init_file")]
	public int read_init_file (string filename);

	[CCode (cname = "rl_parse_and_bind")]
	public int parse_and_bind (owned string line);

	[CCode (cname = "rl_make_bare_keymap")]
	public KeyMap make_bare_keymap ();

	[CCode (cname = "rl_copy_keymap")]
	public KeyMap copy_keymap (KeyMap map);

	[CCode (cname = "rl_make_keymap")]
	public KeyMap make_keymap ();

	[CCode (cname = "rl_discard_keymap")]
	public void discard_keymap (KeyMap map);

	[CCode (cname = "rl_get_keymap_by_name")]
	public KeyMap get_keymap_by_name (string name);

	[CCode (cname = "rl_get_keymap_name")]
	public string get_keymap_name (KeyMap map);

	[CCode (cname = "rl_set_keymap")]
	public void set_keymap (KeyMap map);

	[CCode (cname = "rl_get_keymap")]
	public KeyMap get_keymap ();

	[CCode (cname = "rl_set_keymap_from_edit_mode")]
	public void set_keymap_from_edit_mode ();

	[CCode (cname = "rl_get_keymap_name_from_edit_mode")]
	public string get_keymap_name_from_edit_mode ();

	[CCode (cname = "rl_add_funmap_entry")]
	public int add_funmap_entry (string name, CommandFunc func);

	[CCode (cname = "rl_funmap_names")]
	public unowned string[] funmap_names ();

	[CCode (cname = "rl_initialize_funmap")]
	public void initialize_funmap ();

	[CCode (cname = "rl_push_macro_input")]
	public void push_macro_input (string macro);

	[CCode (cname = "rl_add_undo")]
	public void add_undo (UndoCode what, int start, int end, string text);

	[CCode (cname = "rl_free_undo_list")]
	public void free_undo_list ();

	[CCode (cname = "rl_do_undo")]
	public int do_undo ();

	[CCode (cname = "rl_begin_undo_group")]
	public int begin_undo_group ();

	[CCode (cname = "rl_end_undo_group")]
	public int end_undo_group ();

	[CCode (cname = "rl_modifying")]
	public int modifying (int start, int end);

	[CCode (cname = "rl_redisplay")]
	public void redisplay ();

	[CCode (cname = "rl_on_new_line")]
	public int on_new_line ();

	[CCode (cname = "rl_on_new_line_with_prompt")]
	public int on_new_line_with_prompt ();

	[CCode (cname = "rl_forced_update_display")]
	public int forced_update_display ();

	[CCode (cname = "rl_clear_message")]
	public int clear_message ();

	[CCode (cname = "rl_reset_line_state")]
	public int reset_line_state ();

	[CCode (cname = "rl_crlf")]
	public int crlf ();

	[CCode (cname = "rl_message")]
	public int message (string format, ...);

	[CCode (cname = "rl_show_char")]
	public int show_char (int c);

	[CCode (cname = "rl_character_len")]
	public int character_len (int a, int b);

	[CCode (cname = "rl_save_prompt")]
	public void save_prompt ();

	[CCode (cname = "rl_restore_prompt")]
	public void restore_prompt ();

	[CCode (cname = "rl_replace_line")]
	public void replace_line (string text, int clear_undo);

	[CCode (cname = "rl_insert_text")]
	public int insert_text (string text);

	[CCode (cname = "rl_delete_text")]
	public int delete_text (int start, int end);

	[CCode (cname = "rl_kill_text")]
	public int kill_text (int start, int end);

	[CCode (cname = "rl_copy_text")]
	public string copy_text (int start, int end);

	[CCode (cname = "rl_prep_terminal")]
	public void prep_terminal (int meta_flag);

	[CCode (cname = "rl_deprep_terminal")]
	public void deprep_terminal ();

	[CCode (cname = "rl_tty_set_default_bindings")]
	public void tty_set_default_bindings (KeyMap map);

	[CCode (cname = "rl_tty_unset_default_bindings")]
	public void tty_unset_default_bindings (KeyMap map);

	[CCode (cname = "rl_reset_terminal")]
	public int reset_terminal (string terminal_name);

	[CCode (cname = "rl_resize_terminal")]
	public void resize_terminal ();

	[CCode (cname = "rl_set_screen_size")]
	public void set_screen_size (int rows, int cols);

	[CCode (cname = "rl_get_screen_size")]
	public void get_screen_size (out int rows, out int cols);

	[CCode (cname = "rl_reset_screen_size")]
	public void reset_screen_size ();

	[CCode (cname = "rl_get_termcap")]
	public string get_termcap (string cap);

	[CCode (cname = "rl_stuff_char")]
	public int stuff_char (int c);

	[CCode (cname = "rl_execute_next")]
	public int execute_next (int c);

	[CCode (cname = "rl_clear_pending_input")]
	public int clear_pending_input ();

	[CCode (cname = "rl_read_key")]
	public int read_key ();

	[CCode (cname = "rl_getc")]
	public int getc (GLib.FileStream stream);

	[CCode (cname = "rl_set_keyboard_input_timeout")]
	public int set_keyboard_input_timeout (int u);

	[CCode (cname = "rl_extend_line_buffer")]
	public void extend_line_buffer (int len);

	[CCode (cname = "rl_ding")]
	public int ding ();

	[CCode (cname = "rl_alphabetic")]
	public int alphabetic (int c);

	[CCode (cname = "rl_set_signals")]
	public int set_signals ();

	[CCode (cname = "rl_clear_signals")]
	public int clear_signals ();

	[CCode (cname = "rl_cleanup_after_signal")]
	public void cleanup_after_signal ();

	[CCode (cname = "rl_reset_after_signal")]
	public void reset_after_signal ();

	[CCode (cname = "rl_free_line_state")]
	public void free_line_state ();

	[CCode (cname = "rl_set_paren_blink_timeout")]
	public int set_paren_blink_timeout (int u);

	[CCode (cname = "rl_maybe_save_line")]
	public int maybe_save_line ();

	[CCode (cname = "rl_maybe_unsave_line")]
	public int maybe_unsave_line ();

	[CCode (cname = "rl_maybe_replace_line")]
	public int maybe_replace_line ();

	[CCode (cname = "rl_complete_internal")]
	public int complete_internal (int what_to_do);

	[CCode (cname = "rl_display_match_list")]
	public void display_match_list (string[] matches, int len, int max);

	[CCode (cname = "rl_completion_matches", array_length = false, array_null_terminated = true)]
	public unowned string[] completion_matches (string text, CompentryFunc func);

	[CCode (cname = "rl_username_completion_function")]
	public string username_completion_function (string text, int state);

	[CCode (cname = "rl_filename_completion_function")]
	public string filename_completion_function (string text, int state);

	[CCode (cname = "rl_completion_mode")]
	public int completion_mode (CommandFunc func);

	[CCode (cname = "rl_library_version")]
	public unowned string library_version;

	[CCode (cname = "rl_readline_version")]
	public int readline_version;

	[CCode (cname = "rl_gnu_readline_p")]
	public int gnu_readline_p;

	[CCode (cname = "rl_readline_state")]
	public int readline_state;

	[CCode (cname = "rl_editing_mode")]
	public int editing_mode;

	[CCode (cname = "rl_insert_mode")]
	public int insert_mode;

	[CCode (cname = "rl_readline_name")]
	public unowned string readline_name;

	[CCode (cname = "rl_prompt")]
	public string? prompt;

	[CCode (cname = "rl_line_buffer")]
	public string line_buffer;

	[CCode (cname = "rl_point")]
	public int point;

	[CCode (cname = "rl_end")]
	public int end;

	[CCode (cname = "rl_mark")]
	public int mark;

	[CCode (cname = "rl_done")]
	public int done;

	[CCode (cname = "rl_pending_input")]
	public int pending_input;

	[CCode (cname = "rl_dispatching")]
	public int dispatching;

	[CCode (cname = "rl_explicit_arg")]
	public int explicit_arg;

	[CCode (cname = "rl_numeric_arg")]
	public int numeric_arg;

	[CCode (cname = "rl_last_func")]
	public CommandFunc last_func;

	[CCode (cname = "rl_terminal_name")]
	public unowned string terminal_name;

	[CCode (cname = "rl_instream")]
	public GLib.FileStream? instream;

	[CCode (cname = "rl_outstream")]
	public GLib.FileStream? outstream;

	[CCode (cname = "rl_prefer_env_winsize")]
	public int prefer_env_winsize;

	[CCode (cname = "rl_startup_hook")]
	public HookFunc startup_hook;

	[CCode (cname = "rl_pre_input_hook")]
	public HookFunc pre_input_hook;

	[CCode (cname = "rl_event_hook")]
	public HookFunc event_hook;

	[CCode (cname = "rl_getc_function")]
	public GetcFunc getc_function;

	[CCode (cname = "rl_redisplay_function")]
	public VoidFunc redisplay_function;

	[CCode (cname = "rl_prep_term_function")]
	public VintFunc prep_term_function;

	[CCode (cname = "rl_deprep_term_function")]
	public VoidFunc deprep_term_function;

	[CCode (cname = "rl_executing_keymap")]
	public KeyMap executing_keymap;

	[CCode (cname = "rl_binding_keymap")]
	public KeyMap binding_keymap;

	[CCode (cname = "rl_erase_empty_line")]
	public int erase_empty_line;

	[CCode (cname = "rl_already_prompted")]
	public int already_prompted;

	[CCode (cname = "rl_num_chars_to_read")]
	public int num_chars_to_read;

	[CCode (cname = "rl_executing_macro")]
	public string executing_macro;

	[CCode (cname = "rl_catch_signals")]
	public int catch_signals;

	[CCode (cname = "rl_catch_sigwinch")]
	public int catch_sigwinch;

	[CCode (cname = "rl_completion_entry_function")]
	public CompentryFunc completion_entry_function;

	[CCode (cname = "rl_ignore_some_completions_function")]
	public CompignoreFunc ignore_some_completions_function;

	[CCode (cname = "rl_attempted_completion_function")]
	public CompletionFunc attempted_completion_function;

	[CCode (cname = "rl_basic_word_break_characters")]
	public string* basic_word_break_characters;

	[CCode (cname = "rl_completer_word_break_characters")]
	public string* completer_word_break_characters;

	[CCode (cname = "rl_completion_word_break_hook")]
	public CpvFunc completion_word_break_hook;

	[CCode (cname = "rl_completer_quote_characters")]
	public string* completer_quote_characters;

	[CCode (cname = "rl_basic_quote_characters")]
	public string* basic_quote_characters;

	[CCode (cname = "rl_filename_quote_characters")]
	public string* filename_quote_characters;

	[CCode (cname = "rl_special_prefixes")]
	public string* special_prefixes;

	[CCode (cname = "rl_directory_completion_hook")]
	public IcppFunc directory_completion_hook;

	[CCode (cname = "rl_directory_rewrite_hook")]
	public IcppFunc directory_rewrite_hook;

	[CCode (cname = "rl_completion_display_matches_hook")]
	public CompdispFunc completion_display_matches_hook;

	[CCode (cname = "rl_filename_completion_desired")]
	public int filename_completion_desired;

	[CCode (cname = "rl_filename_quoting_desired")]
	public int filename_quoting_desired;

	[CCode (cname = "rl_filename_quoting_function")]
	public QuoteFunc filename_quoting_function;

	[CCode (cname = "rl_filename_dequoting_function")]
	public DequoteFunc filename_dequoting_function;

	[CCode (cname = "rl_char_is_quoted_p")]
	public LinebufFunc char_is_quoted_p;

	[CCode (cname = "rl_attempted_completion_over")]
	public int attempted_completion_over;

	[CCode (cname = "rl_completion_type")]
	public int completion_type;

	[CCode (cname = "rl_completion_query_items")]
	public int completion_query_items;

	[CCode (cname = "rl_completion_append_character")]
	public int completion_append_character;

	[CCode (cname = "rl_completion_suppress_append")]
	public int completion_suppress_append;

	[CCode (cname = "rl_completion_quote_character")]
	public int completion_quote_character;

	[CCode (cname = "rl_completion_found_quote")]
	public int completion_found_quote;

	[CCode (cname = "rl_completion_suppress_quote")]
	public int completion_suppress_quote;

	[CCode (cname = "rl_completion_mark_symlink_dirs")]
	public int completion_mark_symlink_dirs;

	[CCode (cname = "rl_ignore_completion_duplicates")]
	public int ignore_completion_duplicates;

	[CCode (cname = "rl_inhibit_completion")]
	public int inhibit_completion;

	[CCode (cname = "READERR")]
	public const int READERR;

	[CCode (cname = "RL_PROMPT_START_IGNORE")]
	public const char PROMPT_START_IGNORE;

	[CCode (cname = "RL_PROMPT_END_IGNORE")]
	public const char PROMPT_END_IGNORE;

	[CCode (cname = "NO_MATCH")]
	public const int NO_MATCH;

	[CCode (cname = "SINGLE_MATCH")]
	public const int SINGLE_MATCH;

	[CCode (cname = "MULT_MATCH")]
	public const int MULT_MATCH;

	[CCode (cname = "RL_STATE_NONE")]
	public const uint STATE_NONE;

	[CCode (cname = "RL_STATE_INITIALIZING")]
	public const uint STATE_INITIALIZING;

	[CCode (cname = "RL_STATE_INITIALIZED")]
	public const uint STATE_INITIALIZED;

	[CCode (cname = "RL_STATE_TERMPREPPED")]
	public const uint STATE_TERMPREPPED;

	[CCode (cname = "RL_STATE_READCMD")]
	public const uint STATE_READCMD;

	[CCode (cname = "RL_STATE_METANEXT")]
	public const uint STATE_METANEXT;

	[CCode (cname = "RL_STATE_DISPATCHING")]
	public const uint STATE_DISPATCHING;

	[CCode (cname = "RL_STATE_MOREINPUT")]
	public const uint STATE_MOREINPUT;

	[CCode (cname = "RL_STATE_ISEARCH")]
	public const uint STATE_ISEARCH;

	[CCode (cname = "RL_STATE_NSEARCH")]
	public const uint STATE_NSEARCH;

	[CCode (cname = "RL_STATE_SEARCH")]
	public const uint STATE_SEARCH;

	[CCode (cname = "RL_STATE_NUMERICARG")]
	public const uint STATE_NUMERICARG;

	[CCode (cname = "RL_STATE_MACROINPUT")]
	public const uint STATE_MACROINPUT;

	[CCode (cname = "RL_STATE_MACRODEF")]
	public const uint STATE_MACRODEF;

	[CCode (cname = "RL_STATE_OVERWRITE")]
	public const uint STATE_OVERWRITE;

	[CCode (cname = "RL_STATE_COMPLETING")]
	public const uint STATE_COMPLETING;

	[CCode (cname = "RL_STATE_SIGHANDLER")]
	public const uint STATE_SIGHANDLER;

	[CCode (cname = "RL_STATE_UNDOING")]
	public const uint STATE_UNDOING;

	[CCode (cname = "RL_STATE_INPUTDEPENDING")]
	public const uint STATE_INPUTPENDING;

	[CCode (cname = "RL_STATE_TTYCSAVED")]
	public const uint STATE_TTYCSAVED;

	[CCode (cname = "RL_STATE_CALLBACK")]
	public const uint STATE_CALLBACK;

	[CCode (cname = "RL_STATE_VIMOTION")]
	public const uint STATE_VIMOTION;

	[CCode (cname = "RL_STATE_MULTIKEY")]
	public const uint STATE_MULTIKEY;

	[CCode (cname = "RL_STATE_VICMDONCE")]
	public const uint STATE_VICMDONCE;

	[CCode (cname = "RL_STATE_DONE")]
	public const uint STATE_DONE;

	[CCode (cname = "RL_SETSTATE")]
	public uint set_state (uint s);

	[CCode (cname = "RL_UNSETSTATE")]
	public uint unset_state (uint s);

	[CCode (cname = "RL_ISSTATE")]
	public int is_state (uint s);

	[CCode (cname = "struct readline_state", has_type_id = false)]
	public struct State {
		public int point;
		public int end;
		public int mark;
		public string buffer;
		public int buflen;
		public UndoList ul;
		public string prompt;

		public int rlstate;
		public int done;
		public KeyMap kmap;

		public CommandFunc lastfunc;
		public int insmode;
		public int edmode;
		public int kseqlen;
		public GLib.FileStream inf;
		public GLib.FileStream outf;
		public int pendingin;
		public string macro;

		public int catchsigs;
		public int catchsigwinch;

		public char reserved[64];
	}

	[CCode (cname = "rl_save_state")]
	public int save_state (State state);

	[CCode (cname = "rl_restore_state")]
	public int restore_state (State state);

	[CCode (lower_case_cprefix = "", cheader_filename = "readline/history.h")]
	namespace History {
		[CCode (cname = "HIST_ENTRY", has_type_id = false)]
		public struct Entry {
			public string line;
			public string timestamp;
			public void* data;
		}

		[CCode (cname = "HISTORY_STATE", has_type_id = false)]
		public struct State {
			public unowned History.Entry[]? entries;
			public int offset;
			public int length;
			public int size;
			public int flags;
		}

		[CCode (cname = "HS_STIFLED")]
		public int STIFLED;

		[CCode (cname = "using_history")]
		public void using ();

		[CCode (cname = "history_get_history_state")]
		public History.State get_state ();

		[CCode (cname = "history_set_history_state")]
		public void set_state (History.State state);

		[CCode (cname = "add_history")]
		public void add (string line);

		[CCode (cname = "add_history_time")]
		public void add_time (string ts);

		[CCode (cname = "remove_history")]
		public History.Entry? remove (int which);

		[CCode (cname = "free_history_entry")]
		public void* free_entry (History.Entry entry);

		[CCode (cname = "replace_history_entry")]
		public History.Entry? replace_entry (int which, string s, void* data);

		[CCode (cname = "clear_history")]
		public void clear ();

		[CCode (cname = "stifle_history")]
		public void stifle (int max);

		[CCode (cname = "unstifle_history")]
		public int unstifle ();

		[CCode (cname = "history_is_stifled")]
		public int is_stifled ();

		[CCode (cname = "history_list")]
		public unowned History.Entry[] list ();

		[CCode (cname = "where_history")]
		public int where ();

		[CCode (cname = "current_history")]
		public History.Entry? current ();

		[CCode (cname = "history_get")]
		public History.Entry? get (int offset);

		[CCode (cname = "history_get_time")]
		public time_t get_time (History.Entry entry);

		[CCode (cname = "history_total_bytes")]
		public int total_bytes ();

		[CCode (cname = "history_set_pos")]
		public int set_pos (int pos);

		[CCode (cname = "previous_history")]
		public History.Entry? previous ();

		[CCode (cname = "next_history")]
		public History.Entry? next ();

		[CCode (cname = "history_search")]
		public int search (string s, int direction);

		[CCode (cname = "history_search_prefix")]
		public int search_prefix (string prfx, int direction);

		[CCode (cname = "history_search_pos")]
		public int search_pos (string str, int direction, int pos);

		[CCode (cname = "read_history_range")]
		public int read_range (string filename, int from, int to);

		[CCode (cname = "read_history")]
		public int read (string filename);

		[CCode (cname = "write_history")]
		public int write (string filename);

		[CCode (cname = "append_history")]
		public int append (int nelements, string filename);

		[CCode (cname = "history_truncate_file")]
		public int truncate_file (string filename, int nlines);

		[CCode (cname = "history_expand")]
		public int expand (string s, out string[] a);

		[CCode (cname = "history_arg_extract")]
		public string arg_extract (int first, int last, string s);

		[CCode (cname = "get_history_event")]
		public string get_event (string str, out int cindex, int qchar);

		[CCode (cname = "history_tokenize")]
		public string[] tokenize (string s);

		[CCode (cname = "history_base")]
		public int base;

		[CCode (cname = "history_length")]
		public int length;

		[CCode (cname = "history_max_entries")]
		public int max_entries;

		[CCode (cname = "history_expansion_char")]
		public char expansion_char;

		[CCode (cname = "history_subst_char")]
		public char subst_char;

		[CCode (cname = "history_word_delimiter")]
		public string word_delimiters;

		[CCode (cname = "history_comment_char")]
		public char comment_char;

		[CCode (cname = "history_no_expand_chars")]
		public string no_expand_chars;

		[CCode (cname = "history_search_delimiter_chars")]
		public string search_delimiter_chars;

		[CCode (cname = "history_quotes_inhibit_expansion")]
		public int quotes_inhibit_expansion;

		[CCode (cname = "history_write_timestamps")]
		public int write_timestamps;

		[CCode (cname = "max_input_history")]
		public int max_input;

		[CCode (cname = "history_inhibit_expansion_function")]
		public LinebufFunc inhibit_expansion_function;
	}

	[CCode (cname = "control_character_threshold", cheader_filename = "readline/chardefs.h")]
	public const char CONTROL_CHARACTER_THRESHOLD;

	[CCode (cname = "control_character_mask", cheader_filename = "readline/chardefs.h")]
	public const char CONTROL_CHARACTER_MASK;

	[CCode (cname = "meta_character_threshold", cheader_filename = "readline/chardefs.h")]
	public const char META_CHARACTER_THRESHOLD;

	[CCode (cname = "control_character_bit", cheader_filename = "readline/chardefs.h")]
	public const char CONTROL_CHARACTER_BIT;

	[CCode (cname = "meta_character_bit", cheader_filename = "readline/chardefs.h")]
	public const char META_CHARACTER_BIT;

	[CCode (cname = "largest_char", cheader_filename = "readline/chardefs.h")]
	public const char LARGEST_CHARACTER;

	[CCode (cname = "largest_char", cheader_filename = "readline/chardefs.h")]
	public char ctrl_char (char c);

	[CCode (cname = "META_CHAR", cheader_filename = "readline/chardefs.h")]
	public char meta_char (char c);

	[CCode (cname = "CTRL", cheader_filename = "readline/chardefs.h")]
	public char ctrl (char c);

	[CCode (cname = "META", cheader_filename = "readline/chardefs.h")]
	public char meta (char c);

	[CCode (cname = "UNMETA", cheader_filename = "readline/chardefs.h")]
	public char unmeta (char c);

	[CCode (cname = "UNCTRL", cheader_filename = "readline/chardefs.h")]
	public char unctrl (char c);

	[CCode (cname = "NEWLINE", cheader_filename = "readline/chardefs.h")]
	public const char NEWLINE;

	[CCode (cname = "RETURN", cheader_filename = "readline/chardefs.h")]
	public const char RETURN;

	[CCode (cname = "RUBOUT", cheader_filename = "readline/chardefs.h")]
	public const char RUBOUT;

	[CCode (cname = "TAB", cheader_filename = "readline/chardefs.h")]
	public const char TAB;

	[CCode (cname = "ABORT_CHAR", cheader_filename = "readline/chardefs.h")]
	public const char ABORT_CHAR;

	[CCode (cname = "PAGE", cheader_filename = "readline/chardefs.h")]
	public const char PAGE;

	[CCode (cname = "SPACE", cheader_filename = "readline/chardefs.h")]
	public const char SPACE;

	[CCode (cname = "ESC", cheader_filename = "readline/chardefs.h")]
	public const char ESC;
}

