[CCode (lower_case_cprefix = "orc_", cheader_filename = "orc/orc.h")]
namespace Orc {
	[Compact]
	public class Program {
		public Program ();
		public Program.dss (int size1, int size2, int size3);

		public unowned string get_name ();

		public void add_temporary (int size, owned string name);
		public void add_source (int size, owned string name);
		public void add_destination (int size, owned string name);
		public void add_constant (int size, owned string name);
		public void add_accumulator (int size, owned string name);
		public void add_parameter (int size, owned string name);

		public void append (string opcode, int arg0, int arg1, int arg2);
		public void append_str (string opcode, string arg0, string arg1, string arg2);
		public void append_ds (string opcode, int arg0, int arg1);
		public void append_ds_str (string opcode, string arg0, string arg1);

		public Orc.CompileResult compile ();

		public string get_asm_code ();
		public int find_var_by_name (string name);

		public void set_2d();
	}

	[Compact]
	public class Compiler {
	}

	[CCode (has_type_id = false)]
	public enum CompileResult {
		OK,
		UNKNOWN_COMPILE,
		MISSING_RULE,
		UNKNOWN_PARSE,
		PARSE,
		VARIABLE;

		[CCode (cname = "ORC_COMPILE_RESULT_IS_SUCCESSFUL")]
		public bool is_successful ();
		[CCode (cname = "ORC_COMPILE_RESULT_IS_FATAL")]
		public bool is_fatal ();
	}

	[Compact]
	public class Executor {
		[CCode (cname = "orc_executor_new")]
		public Executor (Orc.Program p);

		public void set_array (int _var, void* ptr);
		public void set_array_str (string _var, void* ptr);

		public void set_n (int n);

		public void emulate ();
		public void run ();

		public int get_accumulator (int n);
		public int get_accumulator_str (string name);
		public int set_param (int n, int val);
		public int set_param_str (string name, int val);

		public void set_program (Orc.Program p);

		public void set_2d ();
		public void set_m (int n);
		public void set_stride (int _var, int stride);
	}

	[CCode (cprefix = "ORC_DEBUG_", has_type_id = false)]
	public enum DebugLevel {
		NONE,
		ERROR,
		WARNING,
		INFO,
		DEBUG,
		LOG
	}

	namespace Debug {
		public void set_level (Orc.DebugLevel l);
	}

	public static void init ();
}

