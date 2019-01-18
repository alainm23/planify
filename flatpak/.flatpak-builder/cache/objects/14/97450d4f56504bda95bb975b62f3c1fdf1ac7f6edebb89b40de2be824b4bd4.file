/* lua.vapi
 *
 * Copyright (C) 2008-2009 pancake, Frederik
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
 * Authors:
 * 	pancake <youterm.com>
 * 	Frederik
 */

[CCode (lower_case_cprefix = "lua_", cheader_filename = "lua.h")]
namespace Lua {

	/* Constants */

	public const string VERSION;
	public const string RELEASE;
	public const int VERSION_NUM;
	public const string COPYRIGHT;
	public const string AUTHORS;

	// mark for precompiled code (`<esc>Lua')
	public const string SIGNATURE;

	// option for multiple returns in `lua_pcall' and `lua_call'
	public const int MULTRET;

	[CCode (cheader_filename = "lauxlib.h", has_type_id = false)]
	public enum Reference
	{
		[CCode (cname = "LUA_REFNIL")]
		NIL,
		[CCode (cname = "LUA_NOREF")]
		NONE
	}

	// pseudo-indices

	[CCode (cheader_filename = "lua.h")]
	namespace PseudoIndex {
		[CCode (cname = "LUA_REGISTRYINDEX")]
		public const int REGISTRY;
		[CCode (cname = "LUA_ENVIRONINDEX")]
		public const int ENVIRONMENT;
		[CCode (cname = "LUA_GLOBALSINDEX")]
		public const int GLOBALS;
		[CCode (cname = "lua_upvalueindex")]
		public int for_upvalue (int i);
	}

	// thread status

	[CCode (cprefix = "LUA_", cname = "int", has_type_id = false)]
	public enum ThreadStatus {
		YIELD,
		ERRRUN,
		ERRSYNTAX,
		ERRMEM,
		ERRERR
	}

	// basic types

	[CCode (cprefix = "LUA_T", cname = "int", has_type_id = false)]
	public enum Type {
		NONE,
		NIL,
		BOOLEAN,
		LIGHTUSERDATA,
		NUMBER,
		STRING,
		TABLE,
		FUNCTION,
		USERDATA,
		THREAD
	}

	[CCode (cprefix = "LUA_GC", cname = "int", has_type_id = false)]
	public enum GarbageCollection {
		STOP,
		RESTART,
		COLLECT,
		COUNT,
		COUNTB,
		STEP,
		[CCode (cname = "LUA_GCSETPAUSE")]
		SET_PAUSE,
		[CCode (cname = "LUA_GCSETSTEPMUL")]
		SET_STEP_MUL
	}

	// Event codes

	[CCode (cprefix = "LUA_HOOK", cname = "int", has_type_id = false)]
	public enum EventHook {
		CALL,
		RET,
		LINE,
		COUNT,
		TAILRET
	}

	// Event masks

	[Flags]
	[CCode (cprefix = "LUA_MASK", cname = "int", has_type_id = false)]
	public enum EventMask {
		CALL,
		RET,
		LINE,
		COUNT
	}

	// minimum Lua stack available to a C function
	public const int MINSTACK;


	/* Function prototypes */

	[CCode (cname = "lua_CFunction", has_target = false)]
	public delegate int CallbackFunc (LuaVM vm);

	// functions that read/write blocks when loading/dumping Lua chunks

	// NOTE - implicitly passed: user data (instance) as 2rd parameter
	//        implicitly returned: resulting array length as out parameter (3rd)
	[CCode (cname = "lua_Reader", instance_pos = 1.1)]
	public delegate char[] ReaderFunc (LuaVM vm);

	// NOTE - implicitly passed: array length as 3rd parameter,
	//                           user data (instance) as last parameter
	[CCode (cname = "lua_Writer", instance_pos = -1)]
	public delegate int WriterFunc (LuaVM vm, char[] p);

	// prototype for memory-allocation functions
	// NOTE - implicitly passed: user data (instance) as 1st parameter
	[CCode (cname = "lua_Alloc", instance_pos = 0.9)]
	public delegate void* AllocFunc (void* ptr, size_t osize, size_t nsize);

	// Function to be called by the debuger in specific events
	[CCode (cname = "lua_Hook", has_target = false)]
	public delegate void HookFunc (LuaVM vm, ref Debug ar);

	[SimpleType]
	[CCode (cname = "lua_Debug", has_type_id = false)]
	public struct Debug {
		public EventHook event;
		public unowned string name;
		[CCode (cname = "namewhat")]
		public unowned string name_what;
		public unowned string what;
		public unowned string source;
		[CCode (cname = "currentline")]
		public int current_line;
		public int nups;
		[CCode (cname = "linedefined")]
		public int line_defined;
		[CCode (cname = "lastlinedefined")]
		public int last_line_defined;
	}

	[Compact]
	[CCode (free_function = "lua_close", cname = "lua_State", cprefix = "lua_")]
	public class LuaVM {

		// state manipulation

		[CCode (cname = "(lua_State*) luaL_newstate")]
		public LuaVM ();
		[CCode (cname = "lua_newstate")]
		// NOTE: user data (instance) gets passed implicitly
		public LuaVM.with_alloc_func (AllocFunc f);
		[CCode (cname = "lua_newthread")]
		public unowned LuaVM new_thread ();

		[CCode (cname = "lua_atpanic")]
		public CallbackFunc at_panic (CallbackFunc f);

		// basic stack manipulation

		[CCode (cname = "lua_gettop")]
		public int get_top ();
		[CCode (cname = "lua_settop")]
		public void set_top (int index);
		[CCode (cname = "lua_pushvalue")]
		public void push_value (int index);
		public void remove (int index);
		public void insert (int index);
		public void replace (int index);
		[CCode (cname = "lua_checkstack")]
		public bool check_stack (int size);

		public static void xmove (LuaVM from, LuaVM to, int n);

		// access functions (stack -> C)

		[CCode (cname = "lua_isnumber")]
		public bool is_number (int index);
		[CCode (cname = "lua_isstring")]
		public bool is_string (int index);
		[CCode (cname = "lua_iscfunction")]
		public bool is_cfunction (int index);
		[CCode (cname = "lua_isuserdata")]
		public bool is_userdata (int index);
		public Lua.Type type (int index);
		[CCode (cname = "lua_typename")]
		public unowned string type_name (Lua.Type type);

		public bool equal (int index1, int index2);
		[CCode (cname = "lua_rawequal")]
		public bool raw_equal (int index1, int index2);
		[CCode (cname = "lua_lessthan")]
		public bool less_than (int index1, int index2);

		[CCode (cname = "lua_tonumber")]
		public double to_number (int index);
		[CCode (cname = "lua_tointeger")]
		public int to_integer (int index);
		[CCode (cname = "lua_toboolean")]
		public bool to_boolean (int index);
		[CCode (cname = "lua_tolstring")]
		public unowned string to_lstring (int index, out size_t size);
		[CCode (cname = "lua_tocfunction")]
		public CallbackFunc to_cfunction (int index);
		[CCode (cname = "lua_touserdata")]
		public void* to_userdata (int index);
		[CCode (cname = "lua_tothread")]
		public unowned LuaVM? to_thread (int index);
		[CCode (cname = "lua_topointer")]
		public /* const */ void* to_pointer (int index);

		// push functions (C -> stack)
		[CCode (cname = "lua_pushnil")]
		public void push_nil ();
		[CCode (cname = "lua_pushnumber")]
		public void push_number (double n);
		[CCode (cname = "lua_pushinteger")]
		public void push_integer (int n);
		[CCode (cname = "lua_pushlstring")]
		public void push_lstring (string s, size_t size);
		[CCode (cname = "lua_pushstring")]
		public void push_string (string s);
		[CCode (cname = "lua_pushfstring")]
		public unowned string push_fstring (string fmt, ...);
		[CCode (cname = "lua_pushcclosure")]
		public void push_cclosure (CallbackFunc f, int n);
		[CCode (cname = "lua_pushboolean")]
		public void push_boolean (int b);
		[CCode (cname = "lua_pushlightuserdata")]
		public void push_lightuserdata (void* p);
		[CCode (cname = "lua_pushthread")]
		public bool push_thread ();

		// get functions (Lua -> stack)
		[CCode (cname = "lua_gettable")]
		public void get_table (int index);
		[CCode (cname = "lua_getfield")]
		public void get_field (int index, string k);
		[CCode (cname = "lua_rawget")]
		public void raw_get (int index);
		[CCode (cname = "lua_rawgeti")]
		public void raw_geti (int index, int n);
		[CCode (cname = "lua_createtable")]
		public void create_table (int narr, int nrec);
		[CCode (cname = "lua_newuserdata")]
		public void* new_userdata (size_t sz);
		[CCode (cname = "lua_getmetatable")]
		public int get_metatable (int objindex);
		[CCode (cname = "lua_getfenv")]
		public void get_fenv (int index);

		// set functions (stack -> Lua)
		[CCode (cname = "lua_settable")]
		public void set_table (int index);
		[CCode (cname = "lua_setfield")]
		public void set_field (int index, string k);
		[CCode (cname = "lua_rawset")]
		public void raw_set (int index);
		[CCode (cname = "lua_rawseti")]
		public void raw_seti (int index, int n);
		[CCode (cname = "lua_setmetatable")]
		public int set_metatable (int objindex);
		[CCode (cname = "lua_setfenv")]
		public bool set_fenv (int index);

		// call functions
		public void call (int nargs = 0, int nresults = 0);
		public int pcall (int nargs = 0, int nresults = 0, int errfunc = 0);
		public int cpcall (CallbackFunc fun, void* ud = null);

		// NOTE: user data (instance) gets passed implicitly
		public int load (ReaderFunc reader, string chunkname);
		// NOTE: user data (instance) gets passed implicitly
		public int dump (WriterFunc writer);

		// coroutine functions
		public int yield (int nresults);
		public int resume (int narg);
		public int status ();

		// garbage-collection function and options

		public int gc (GarbageCollection what, int data);

		// miscellaneous functions

		public int error ();
		public int next (int index);
		public void concat (int n);
		[CCode (cname = "lua_getallocf")]
		// NOTE: user data (instance) implicitly returned as out parameter
		public AllocFunc get_alloc_func ();
		[CCode (cname = "lua_setallocf")]
		// NOTE: user data (instance) gets passed implicitly
		public void set_alloc_func (AllocFunc f);

		// some useful macros

		public void pop (int n);
		[CCode (cname = "lua_newtable")]
		public void new_table ();
		public void register (string name, CallbackFunc f);
		[CCode (cname = "lua_pushcfunction")]
		public void push_cfunction (CallbackFunc f);
		public size_t strlen (int index);

		[CCode (cname = "lua_isfunction")]
		public bool is_function (int n);
		[CCode (cname = "lua_istable")]
		public bool is_table (int n);
		[CCode (cname = "lua_islightuserdata")]
		public bool is_lightuserdata (int n);
		[CCode (cname = "lua_isnil")]
		public bool is_nil (int n);
		[CCode (cname = "lua_isboolean")]
		public bool is_boolean (int n);
		[CCode (cname = "lua_isthread")]
		public bool is_thread (int n);
		[CCode (cname = "lua_isnone")]
		public bool is_none (int n);
		[CCode (cname = "lua_isnoneornil")]
		public bool is_none_or_nil (int n);

		[CCode (cname = "lua_pushliteral")]
		public void push_literal (string s);

		[CCode (cname = "lua_setglobal")]
		public void set_global (string name);
		[CCode (cname = "lua_getglobal")]
		public void get_global (string name);

		[CCode (cname = "lua_tostring")]
		public unowned string to_string (int index);

		// Debug API

		[CCode (cname = "lua_getstack")]
		public bool get_stack (int level, ref Debug ar);
		[CCode (cname = "lua_getinfo")]
		public bool get_info (string what, ref Debug ar);
		[CCode (cname = "lua_getlocal")]
		public unowned string? get_local (ref Debug ar, int n);
		[CCode (cname = "lua_setlocal")]
		public unowned string? set_local (ref Debug ar, int n);
		[CCode (cname = "lua_getupvalue")]
		public unowned string? get_upvalue (int funcindex, int n);
		[CCode (cname = "lua_setupvalue")]
		public unowned string? set_upvalue (int funcindex, int n);

		[CCode (cname = "lua_sethook")]
		public bool set_hook (HookFunc func, EventMask mask, int count);
		[CCode (cname = "lua_gethook")]
		public HookFunc get_hook ();
		[CCode (cname = "lua_gethookmask")]
		public EventMask get_hook_mask ();
		[CCode (cname = "lua_gethookcount")]
		public int get_hook_count ();

		// Auxiliary library functions

		[CCode (cname = "luaL_openlibs")]
		public void open_libs ();
		[CCode (cname = "luaL_loadbuffer")]
		public int load_buffer (char[] buffer, string? name = null);
		[CCode (cname = "luaL_loadstring")]
		public int load_string (string s);
		[CCode (cname = "luaL_loadfile", cheader_filename = "lauxlib.h")]
		public int load_file (string filename);
		[CCode (cname = "luaL_dofile", cheader_filename = "lauxlib.h")]
		public bool do_file (string filename);
		[CCode (cname = "luaL_dostring", cheader_filename = "lauxlib.h")]
		public bool do_string (string str);
		[CCode (cname = "luaL_ref", cheader_filename = "lauxlib.h")]
		public int reference (int t);
		[CCode (cname = "luaL_unref", cheader_filename = "lauxlib.h")]
		public void unreference (int t);
	}
}
