/* curses.vala
 *
 * Copyright (c) 2007 Ed Schouten <ed@fxq.nl>
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

[CCode (lower_case_cprefix = "", cheader_filename = "curses.h")]
namespace Curses {
	public const int COLORS;
	public const int COLOR_PAIRS;

	[SimpleType]
	[CCode (cname = "short", has_type_id = false, default_value = "0")]
	[IntegerType (rank = 4, min = -32768, max = 32767)]
	public struct Color : short {
		public const Curses.Color BLACK;
		public const Curses.Color RED;
		public const Curses.Color GREEN;
		public const Curses.Color YELLOW;
		public const Curses.Color BLUE;
		public const Curses.Color MAGENTA;
		public const Curses.Color CYAN;
		public const Curses.Color WHITE;
	}

	[CCode (has_type_id = false)]
	public enum Acs {
		ULCORNER, LLCORNER, URCORNER, LRCORNER, LTEE, RTEE,
		BTEE, TTEE, HLINE, VLINE, PLUS, S1, S9, DIAMOND,
		CKBOARD, DEGREE, PLMINUS, BULLET, LARROW, RARROW,
		DARROW, UARROW, BOARD, LANTERN, BLOCK, S3, S7, LEQUAL,
		GEQUAL, PI, NEQUAL, STERLING, BSSB, SSBB, BBSS, SBBS,
		SBSS, SSSB, SSBS, BSSS, BSBS, SBSB, SSSS
	}

	public Window stdscr;
	public Window curscr;
	public Window newscr;

	public const int LINES;
	public const int COLS;
	public const int TABSIZE;

	public const int ESCDELAY;

	[Compact]
	[CCode (copy_function = "dupwin", free_function = "delwin", cname = "WINDOW", cprefix = "")]
	public class Window {
		public int box(ulong verch, ulong horch);
		public int clearok(bool bf);
		public int copywin(Window dstwin, int sminrow, int smincol, int dminrow, int dmincol, int dmaxrow, int dmaxcol, int overlay);
		public Window derwin(int nlines, int ncols, int begin_y, int begin_x);
		[CCode (cname = "dupwin")]
		public Window copy();
		public ulong getbkgd();
		public static Window getwin(GLib.FileStream filep);
		public void idcok(bool bf);
		public int idlok(bool bf);
		public void immedok(bool bf);
		public int intrflush(bool bf);
		public bool is_linetouched(int line);
		public bool is_wintouched();
		public int keypad(bool bf);
		public int leaveok(bool bf);
		public int meta(bool bf);
		public int mvderwin(int par_y, int par_x);
		[CCode (cname = "mvwaddch")]
		public int mvaddch(int y, int x, ulong ch);
		[CCode (cname = "mvwaddchnstr")]
		public int mvaddchnstr(int y, int x, [CCode (array_length = false)] ulong[] chstr, int n);
		[CCode (cname = "mvwaddchstr")]
		public int mvaddchstr(int y, int x, [CCode (array_length = false)] ulong[] chstr);
		[CCode (cname = "mvwaddnstr")]
		public int mvaddnstr(int y, int x, string str, int n);
		[CCode (cname = "mvwaddstr")]
		public int mvaddstr(int y, int x, string str);
		[CCode (cname = "mvwchgat")]
		public int mvchgat(int y, int x, int n, ulong attr, short color);
		[CCode (cname = "mvwdelch")]
		public int mvdelch(int y, int x);
		[CCode (cname = "mvwgetch")]
		public int mvgetch(int y, int x);
		[CCode (cname = "mvwgetnstr")]
		public int mvgetnstr(int y, int x, string str, int n);
		[CCode (cname = "mvwgetstr")]
		public int mvgetstr(int y, int x, string str);
		[CCode (cname = "mvwhline")]
		public int mvhline(int y, int x, ulong ch, int n);
		public int mvwin(int y, int x);
		[CCode (cname = "mvwinch")]
		public ulong mvinch(int y, int x);
		[CCode (cname = "mvwinchnstr")]
		public int mvinchnstr(int y, int x, [CCode (array_length = false)] ulong[] chstr, int n);
		[CCode (cname = "mvwinchstr")]
		public int mvinchstr(int y, int x, [CCode (array_length = false)] ulong[] chstr);
		[CCode (cname = "mvwinnstr")]
		public int mvinnstr(int y, int x, string str, int n);
		[CCode (cname = "mvwinsch")]
		public int mvinsch(int y, int x, ulong ch);
		[CCode (cname = "mvwinsnstr")]
		public int mvinsnstr(int y, int x, string str, int n);
		[CCode (cname = "mvwinsstr")]
		public int mvinsstr(int y, int x, string str);
		[CCode (cname = "mvwinstr")]
		public int mvinstr(int y, int x, string str);
		[CCode (cname = "mvwprintw")]
		[PrintfLike]
		public int mvprintw(int y, int x, string str, ...);
		[CCode (cname = "mvwscanw")]
		[PrintfLike]
		public int mvscanw(int y, int x, string str, ...);
		[CCode (cname = "mvwvline")]
		public int mvvline(int y, int x, ulong ch, int n);
		[CCode (cname = "newwin")]
		public Window(int nlines, int ncols, int begin_y, int begin_x);
		public int nodelay(bool bf);
		public int notimeout(bool bf);
		public int overlay(Window win);
		public int overwrite(Window win);
		public int putwin(GLib.FileStream filep);
		public int redrawwin();
		public int scroll();
		public int scrollok(bool bf);
		public Window subpad(int nlines, int ncols, int begin_y, int begin_x);
		public Window subwin(int nlines, int ncols, int begin_y, int begin_x);
		public int syncok(bool bf);
		public int touchline(int start, int count);
		public int touchwin();
		public int untouchwin();
		[CCode (cname = "waddch")]
		public int addch(ulong ch);
		public int waddchnstr([CCode (array_length = false)] ulong[] chstr, int n);
		public int waddchstr([CCode (array_length = false)] ulong[] chstr);
		public int waddnstr(string str, int n);
		[CCode (cname = "waddstr")]
		public int addstr(string str);
		[CCode (cname = "wattron")]
		public int attron(ulong attrs);
		[CCode (cname = "wattroff")]
		public int attroff(ulong attrs);
		[CCode (cname = "wattrset")]
		public int attrset(ulong attrs);
		[CCode (cname = "wattr_get")]
		public int attr_get(ref ulong attrs, ref ulong pair);
		[CCode (cname = "wattr_on")]
		public int attr_on(ulong attrs);
		[CCode (cname = "wattr_off")]
		public int attr_off(ulong attrs);
		[CCode (cname = "wattr_set")]
		public int attr_set(ulong attrs, short pair);
		[CCode (cname = "wbkgd")]
		public int bkgd(ulong ch);
		[CCode (cname = "wbkgdset")]
		public void bkgdset(ulong ch);
		[CCode (cname = "wborder")]
		public int border(ulong ls, ulong rs, ulong ts, ulong bs, ulong tl, ulong tr, ulong bl, ulong br);
		[CCode (cname = "wchgat")]
		public int chgat(int n, ulong attr, short color);
		[CCode (cname = "wclear")]
		public int clear();
		[CCode (cname = "wclrtobot")]
		public int clrtobot();
		[CCode (cname = "wclrtoeol")]
		public int clrtoeol();
		[CCode (cname = "wcolor_set")]
		public int color_set(short color_pair_number);
		[CCode (cname = "wcursyncup")]
		public void cursyncup();
		[CCode (cname = "wdelch")]
		public int delch();
		[CCode (cname = "wdeleteln")]
		public int deleteln();
		[CCode (cname = "wechochar")]
		public int echochar(ulong ch);
		[CCode (cname = "werase")]
		public int erase();
		[CCode (cname = "wgetch")]
		public int getch();
		[CCode (cname = "wgetnstr")]
		public int getnstr(string str, int n);
		[CCode (cname = "wgetstr")]
		public int getstr(string str);
		[CCode (cname = "whline")]
		public int hline(ulong ch, int n);
		[CCode (cname = "winch")]
		public ulong inch();
		[CCode (cname = "winchnstr")]
		public int inchnstr([CCode (array_length = false)] ulong[] chstr, int n);
		[CCode (cname = "winchstr")]
		public int inchstr([CCode (array_length = false)] ulong[] chstr);
		[CCode (cname = "winnstr")]
		public int innstr(string str, int n);
		[CCode (cname = "winsch")]
		public int insch(ulong ch);
		[CCode (cname = "winsdelln")]
		public int insdelln(int n);
		[CCode (cname = "winsertln")]
		public int insertln();
		[CCode (cname = "winsnstr")]
		public int insnstr(string str, int n);
		[CCode (cname = "winsstr")]
		public int insstr(string str);
		[CCode (cname = "winstr")]
		public int instr(string str);
		[CCode (cname = "wmove")]
		public int move(int y, int x);
		[CCode (cname = "wresize")]
		public int resize(int h, int w);
		[CCode (cname = "wnoutrefresh")]
		public int noutrefresh();
		[CCode (cname = "wprintw")]
		[PrintfLike]
		public int printw(string str, ...);
		[CCode (cname = "vw_printw")]
		public int vprintw(string str, va_list args);
		[CCode (cname = "wredrawln")]
		public int redrawln(int beg_line, int num_lines);
		[CCode (cname = "wrefresh")]
		public int refresh();
		[CCode (cname = "wscanw")]
		[PrintfLike]
		public int scanw(string str, ...);
		[CCode (cname = "vw_scanw")]
		public int vscanw(string str, va_list args);
		[CCode (cname = "wscrl")]
		public int scrl(int n);
		[CCode (cname = "wsetscrreg")]
		public int setscrreg(int top, int bot);
		[CCode (cname = "wstandout")]
		public int standout();
		[CCode (cname = "wstandend")]
		public int standend();
		[CCode (cname = "wsyncdown")]
		public void syncdown();
		[CCode (cname = "wsyncup")]
		public void syncup();
		[CCode (cname = "wtimeout")]
		public void timeout(int delay);
		[CCode (cname = "wtouchln")]
		public int touchln(int y, int n, int changed);
		[CCode (cname = "wvline")]
		public int vline(ulong ch, int n);
	}

	[Compact]
	[CCode (copy_function = "dupwin", free_function = "delwin", cname = "WINDOW", cprefix = "")]
	public class Pad : Window {
		[CCode (cname = "newpad")]
		public Pad(int nlines, int ncols);
		[CCode (cname = "pechochar")]
		public int echochar(ulong ch);
		[CCode (cname = "pnoutrefresh")]
		public int noutrefresh(int pminrow, int pmincol, int sminrow, int smincol, int smaxrow, int smaxcol);
		[CCode (cname = "prefresh")]
		public int refresh(int pminrow, int pmincol, int sminrow, int smincol, int smaxrow, int smaxcol);
	}

	[Compact]
	[CCode (free_function = "delscreen", cname = "SCREEN", cprefix = "")]
	public class Screen {
		[CCode (cname = "newterm")]
		public Screen(string str, GLib.FileStream outfd, GLib.FileStream infd);
		public unowned Screen set_term();
	}

	public int addch(ulong ch);
	public int addchnstr([CCode (array_length = false)] ulong[] chstr, int n);
	public int addchstr([CCode (array_length = false)] ulong[] chstr);
	public int addnstr(string str, int n);
	public int addstr(string str);
	public int attroff(ulong attr);
	public int attron(ulong attr);
	public int attrset(ulong attr);
	public int attr_get(ref ulong attrs, ref short pair);
	public int attr_off(ulong attrs);
	public int attr_on(ulong attrs);
	public int attr_set(ulong attrs, short pair);
	public int baudrate();
	public int beep();
	public int bkgd(ulong ch);
	public void bkgdset(ulong ch);
	public int border(ulong ls, ulong rs, ulong ts, ulong bs, ulong tl, ulong tr, ulong bl, ulong br);
	public bool can_change_color();
	public int cbreak();
	public int chgat(int n, ulong attr, short color);
	public int clear();
	public int clrtobot();
	public int clrtoeol();
	public int color_content(short color, ref short r, ref short g, ref short b);
	public int color_set(short color_pair_number);
	public int COLOR_PAIR(int n);
	public int curs_set(int visibility);
	public int def_prog_mode();
	public int def_shell_mode();
	public int delay_output(int ms);
	public int delch();
	public int deleteln();
	public int doupdate();
	public int echo();
	public int echochar(ulong ch);
	public int erase();
	public int endwin();
	public char erasechar();
	public void filter();
	public int flash();
	public int flushinp();
	public int getch();
	public int getnstr(string str, int n);
	public int getstr(string str);
	public int halfdelay(int tenths);
	public bool has_colors();
	public bool has_ic();
	public bool has_il();
	public int hline(ulong ch, int n);
	public ulong inch();
	public int inchnstr([CCode (array_length = false)] ulong[] chstr, int n);
	public int inchstr([CCode (array_length = false)] ulong[] chstr);
	public unowned Window initscr();
	public int init_color(short color, short r, short g, short b);
	public int init_pair(short pair, Color f, Color b);
	public int innstr(string str, int n);
	public int insch(ulong ch);
	public int insdelln(int n);
	public int insertln();
	public int insnstr(string str, int n);
	public int insstr(string str);
	public int instr(string str);
	public bool isendwin();
	public string keyname(int c);
	public char killchar();
	public string ulongname();
	public int move(int y, int x);
	public int mvaddch(int y, int x, ulong ch);
	public int mvaddchnstr(int y, int x, [CCode (array_length = false)] ulong[] chstr, int n);
	public int mvaddchstr(int y, int x, [CCode (array_length = false)] ulong[] chstr);
	public int mvaddnstr(int y, int x, string str, int n);
	public int mvaddstr(int y, int x, string str);
	public int mvchgat(int y, int x, int n, ulong attr, short color);
	public int mvcur(int oldrow, int oldcol, int newrow, int newcol);
	public int mvdelch(int y, int x);
	public int mvgetch(int y, int x);
	public int mvgetnstr(int y, int x, string str, int n);
	public int mvgetstr(int y, int x, string str);
	public int mvhline(int y, int x, ulong ch, int n);
	public ulong mvinch(int y, int x);
	public int mvinchnstr(int y, int x, [CCode (array_length = false)] ulong[] chstr, int n);
	public int mvinchstr(int y, int x, [CCode (array_length = false)] ulong[] chstr);
	public int mvinnstr(int y, int x, string str, int n);
	public int mvinsch(int y, int x, ulong ch);
	public int mvinsnstr(int y, int x, string str, int n);
	public int mvinsstr(int y, int x, string str);
	public int mvinstr(int y, int x, string str);
	[PrintfLike]
	public int mvprintw(int y, int x, string str, ...);
	[PrintfLike]
	public int mvscanw(int y, int x, string str, ...);
	public int mvvline(int y, int x, ulong ch, int n);
	public int napms(int ms);
	public int nl();
	public int nocbreak();
	public int noecho();
	public int nonl();
	public void noqiflush();
	public int noraw();
	public int pair_content(short pair, ref Color f, ref Color b);
	public int PAIR_NUMBER(int attrs);
	[PrintfLike]
	public int printw(string str, ...);
	public void qiflush();
	public int raw();
	public int refresh();
	public int resetty();
	public int reset_prog_mode();
	public int reset_shell_mode();
	public delegate int RipofflineInitFunc(Window win, int n);
	public int ripoffline(int line, RipofflineInitFunc init);
	public int savetty();
	[PrintfLike]
	public int scanw(string str, ...);
	public int scr_dump(string str);
	public int scr_init(string str);
	public int scrl(int n);
	public int scr_restore(string str);
	public int scr_set(string str);
	public int setscrreg(int top, int bot);
	public int slk_attroff(ulong attrs);
	public int slk_attr_off(ulong attrs);
	public int slk_attron(ulong attrs);
	public int slk_attr_on(ulong attrs);
	public int slk_attrset(ulong attrs);
	public ulong slk_attr();
	public int slk_attr_set(ulong attrs, short pair);
	public int slk_clear();
	public int slk_color(short color_pair_number);
	public int slk_init(int fmt);
	public string slk_label(int labnum);
	public int slk_noutrefresh();
	public int slk_refresh();
	public int slk_restore();
	public int slk_set(int labnum, string label, int fmt);
	public int slk_touch();
	public int standout();
	public int standend();
	public int start_color();
	public ulong termattrs();
	public string termname();
	public void timeout(int delay);
	public int typeahead(int fd);
	public int ungetch(int ch);
	public void use_env(bool bf);
	public int vidattr(ulong attrs);
	public delegate int VidputsPutcFunc(char ch);
	public int vidputs(ulong attrs, VidputsPutcFunc putc);
	public int vline(ulong ch, int n);

	[CCode (cprefix = "A_", has_type_id = false)]
	public enum Attribute {
		NORMAL, ATTRIBUTES, CHARTEXT, COLOR, STANDOUT,
		UNDERLINE, REVERSE, BLINK, DIM, BOLD, ALTCHARSET, INVIS,
		PROTECT, HORIZONTAL, LEFT, LOW, RIGHT, TOP, VERTICAL
	}

	[CCode (has_type_id = false)]
	public enum Key {
		CODE_YES, MIN, BREAK, SRESET, RESET, DOWN, UP, LEFT,
		RIGHT, HOME, BACKSPACE, F0, /* XXX F(n), */ DL, IL, DC,
		IC, EIC, CLEAR, EOS, EOL, SF, SR, NPAGE, PPAGE, STAB,
		CTAB, CATAB, ENTER, PRINT, LL, A1, A3, B2, C1, C3, BTAB,
		BEG, CANCEL, CLOSE, COMMAND, COPY, CREATE, END, EXIT,
		FIND, HELP, MARK, MESSAGE, MOVE, NEXT, OPEN, OPTIONS,
		PREVIOUS, REDO, REFERENCE, REFRESH, REPLACE, RESTART,
		RESUME, SAVE, SBEG, SCANCEL, SCOMMAND, SCOPY, SCREATE,
		SDC, SDL, SELECT, SEND, SEOL, SEXIT, SFIND, SHELP,
		SHOME, SIC, SLEFT, SMESSAGE, SMOVE, SNEXT, SOPTIONS,
		SPREVIOUS, SPRINT, SREDO, SREPLACE, SRIGHT, SRSUME,
		SSAVE, SSUSPEND, SUNDO, SUSPEND, UNDO, MOUSE, RESIZE,
		EVENT, MAX
	}

	/* TODO: mouse + wide char support */
	[CCode (cname="MEVENT", has_type_id = false)]
	public struct MouseEvent {
		short id;
		int x;
		int y;
		int z;
		long bstate;
	}

	[CCode (cprefix="", has_type_id = false)]
	public enum MouseMask {
		ALL_MOUSE_EVENTS,
		REPORT_MOUSE_POSITION
	}

	[CCode (has_type_id = false)]
	public enum Button {
		SHIFT,
		CTRL,
		ALT,
	}

	[CCode (has_type_id = false)]
	public enum Button1 {
		PRESSED,
		RELEASED,
		CLICKED,
		DOUBLE_CLICKED,
		TRIPLE_CLICKED
	}

	[CCode (has_type_id = false)]
	public enum Button2 {
		PRESSED,
		RELEASED,
		CLICKED,
		DOUBLE_CLICKED,
		TRIPLE_CLICKED
	}

	[CCode (has_type_id = false)]
	public enum Button3 {
		PRESSED,
		RELEASED,
		CLICKED,
		DOUBLE_CLICKED,
		TRIPLE_CLICKED
	}

	[CCode (has_type_id = false)]
	public enum Button4 {
		PRESSED,
		RELEASED,
		CLICKED,
		DOUBLE_CLICKED,
		TRIPLE_CLICKED
	}

	[CCode (has_type_id = false)]
	public enum Button5 {
		PRESSED,
		RELEASED,
		CLICKED,
		DOUBLE_CLICKED,
		TRIPLE_CLICKED
	}

	public bool getmouse(out MouseEvent me);
	public int mouseinterval(int erval);
	public int mousemask(MouseMask @new, out MouseMask old);
}
