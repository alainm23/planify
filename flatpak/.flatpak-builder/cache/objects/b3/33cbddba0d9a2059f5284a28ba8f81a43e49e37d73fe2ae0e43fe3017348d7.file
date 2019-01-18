[CCode (cprefix="SDL_", cheader_filename="SDL.h")]
namespace SDL {
	///
	/// Initialization
	///
	[Flags, CCode (cname="int", cprefix="SDL_INIT_", has_type_id = false)]
	public enum InitFlag {
		TIMER, AUDIO, VIDEO, CDROM, JOYSTICK,
		NOPARACHUTE, EVENTTHREAD, EVERYTHING
	}// InitFlag

	[CCode (cname="SDL_Init")]
	public static int init(uint32 flags = SDL.InitFlag.EVERYTHING);

	[CCode (cname="SDL_InitSubSystem")]
	public static int init_subsystem(uint32 flags);

	[CCode (cname="SDL_WasInit")]
	public static uint32 get_initialized(uint32 flags);

	[CCode (cname="SDL_Quit")]
	public static void quit();

	[CCode (cname="SDL_QuitSubSystem")]
	public static void quit_subsystem(uint32 flags);

	[CCode (type_id="SDL_version", cheader_filename="SDL_version.h", cname="SDL_version")]
	public class Version {
		public uchar major;
		public uchar minor;
		public uchar patch;

		[CCode (cheader_filename="SDL_version.h", cname="SDL_Linked_Version")]
		public static unowned Version linked();
	}// Version


	///
	/// Error
	///
	[CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum Error {
		ENOMEM, EFREAD, EFWRITE, EFSEEK,
		UNSUPPORTED, LASTERROR
	}// Error

	[CCode (cname="SDL_SetError")]
	public static void set_error(string format, ...);

	[CCode (cname="SDL_GetError")]
	public static unowned string get_error();

	[CCode (cname="SDL_ClearError")]
	public static void clear_error();

	[CCode (cname="SDL_Error")]
	public static void error(Error code);


	///
	/// Video
	///
	[CCode (cname="int", cprefix="SDL_ALPHA_", has_type_id = false)]
	public enum Opacity {
		OPAQUE, TRANSPARENT
	}// Opacity

	[Compact]
	public class Video {
		[CCode (cname="SDL_VideoDriverName")]
		public static unowned string? driver_name(string namebuf, int maxlen);

		[CCode (cname="SDL_SetGamma")]
		public static int set_gamma(float red, float green, float blue);

		[CCode (cname="SDL_SetGammaRamp")]
		public static int set_gamma_ramp(uint16* red, uint16* green, uint16* blue);

		[CCode (cname="SDL_GetGammaRamp")]
		public static int get_gamma_ramp(uint16* red, uint16* green, uint16* blue);

		[CCode (cname="SDL_ListModes")]
		public static void* _list_modes(PixelFormat? format, uint32 flags);

		[CCode (array_length = false, array_null_terminated = true)]
		public static unowned SDL.Rect*[]? list_modes(SDL.PixelFormat? format, uint32 flags, out bool any) {
			var p = SDL.Video._list_modes (format, flags);
			any = ((int) p == -1);
			return any ? null : (SDL.Rect*[]?) p;
		}
	}// Video

	[Flags, CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum SurfaceFlag {
		SWSURFACE, HWSURFACE, ASYNCBLIT, ANYFORMAT, HWPALETTE, DOUBLEBUF,
		FULLSCREEN, OPENGL, OPENGLBLIT, RESIZABLE, NOFRAME, HWACCEL,
		SRCCOLORKEY, RLEACCEL, SRCALPHA
	}// SurfaceFlag

	[CCode (cname="SDL_Surface", free_function="SDL_FreeSurface", copy_function="SDL_DisplayFormat")]
	[Compact]
	public class Surface {
		public uint32 flags;
		public PixelFormat? format;
		public int w;
		public int h;
		public uint16 pitch;
		public void* pixels;
		public int ref_count;

		[CCode (cname="SDL_CreateRGBSurface")]
		public Surface.RGB(uint32 flags, int width, int height, int depth,
			uint32 rmask, uint32 gmask, uint32 bmask, uint32 amask);

		[CCode (cname="SDL_CreateRGBSurfaceFrom")]
		public Surface.from_RGB(void* pixels, int width, int height, int depth,
			int pitch, uint32 rmask, uint32 gmask, uint32 bmask, uint32 amask);

		[CCode (cname="SDL_LoadBMP_RW")]
		public static Surface.load(RWops src, int freesrc=0);

		// Instance methods
		[CCode (cname="SDL_UpdateRects")]
		public void update_rects ([CCode (array_length_pos=0.9)] Rect[] rects);

		[CCode (cname="SDL_UpdateRect")]
		public void update_rect (int32 x, int32 y, uint32 w, uint32 h);

		[CCode (cname="SDL_Flip")]
		public int flip();

		[CCode (cname="SDL_SetColors")]
		public int set_colors ([CCode (array_length_pos=-1)] Color[] colors, int firstcolor = 0);

		[CCode (cname="SDL_SetPalette")]
		public int set_palette (PaletteFlags flags, [CCode (array_length_pos=-1)] Color[] colors, int firstcolor = 0);

		[CCode (cname="SDL_LockSurface")]
		public int do_lock();

		[CCode (cname="SDL_UnlockSurface")]
		public void unlock();

		[CCode (cname="SDL_SaveBMP_RW")]
		public int save(RWops dst, int freedst=0);

		[CCode (cname="SDL_SetColorKey")]
		public int set_colorkey(uint32 flag, uint32 key);

		[CCode (cname="SDL_SetAlpha")]
		public int set_alpha(uint32 flag, uchar alpha);

		[CCode (cname="SDL_SetClipRect")]
		public bool set_cliprect(Rect? rect);

		[CCode (cname="SDL_GetClipRect")]
		public void get_cliprect(out Rect rect);

		[CCode (cname="SDL_ConvertSurface")]
		public Surface? convert(PixelFormat? fmt, uint32 flags);

		[CCode (cname="SDL_UpperBlit")]
		public int blit(Rect? srcrect, Surface dst, Rect? dstrect);

		[CCode (cname="SDL_FillRect")]
		public int fill(Rect? dst, uint32 color);
	}// Surface

	[CCode (cname="SDL_Surface")]
	[Compact]
	public class Screen : Surface {
		[CCode (cname="SDL_GetVideoSurface")]
		public static unowned Screen instance();

		[CCode (cname="SDL_SetVideoMode")]
		public static unowned Screen? set_video_mode(int width, int height, int bpp, uint32 flags);

		[CCode (cname="SDL_VideoModeOK")]
		public static int check_video_mode(int width, int height, int bpp, uint32 flags);
	}// Screen

	[CCode (cname="SDL_PixelFormat", has_copy_function = false, has_destroy_function = false, has_type_id = false)]
	public struct PixelFormat {
		public Palette? palette;
		public uchar BitsPerPixel;
		public uchar BytesPerPixel;
		public uchar Rloss;
		public uchar Gloss;
		public uchar Bloss;
		public uchar Aloss;
		public uchar Rshift;
		public uchar Gshift;
		public uchar Bshift;
		public uchar Ashift;
		public uint32 Rmask;
		public uint32 Gmask;
		public uint32 Bmask;
		public uint32 Amask;

		public uint32 colorkey;
		public uchar alpha;

		[CCode (cname="SDL_MapRGB")]
		public uint32 map_rgb(uchar r, uchar g, uchar b);

		[CCode (cname="SDL_MapRGBA")]
		public uint32 map_rgba(uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="SDL_GetRGB", instance_pos=1.2)]
		public void get_rgb (uint32 pixel, ref uchar r, ref uchar g, ref uchar b);

		[CCode (cname="SDL_GetRGBA", instance_pos=1.2)]
		public void get_rgba (uint32 pixel, ref uchar r, ref uchar g, ref uchar b, ref uchar a);
	}// PixelFormat

	[CCode (cname="SDL_Rect", has_type_id=false)]
	public struct Rect {
		public int16 x;
		public int16 y;
		public uint16 w;
		public uint16 h;
	}// Rect

	[CCode (cname="SDL_Color", has_type_id=false)]
	[SimpleType]
	public struct Color {
		public uchar r;
		public uchar g;
		public uchar b;
		public uchar unused;
	}// Color

	[CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum PaletteFlags {
		LOGPAL, PHYSPAL
	}// PaletteFlags

	[CCode (cname="SDL_Palette", has_copy_function = false, has_destroy_function = false, has_type_id = false)]
	public struct Palette {
		[CCode (array_length_cname="ncolors")]
		public Color[] colors;
	}// Palette

	[CCode (cname="SDL_VideoInfo")]
	[Compact]
	public class VideoInfo {
		public uint32 hw_available	;
		public uint32 wm_available	;
		public uint32 UnusedBits1	;
		public uint32 UnusedBits2	;
		public uint32 blit_hw		;
		public uint32 bliw_hw_CC	;
		public uint32 blit_hw_A	;
		public uint32 blit_sw		;
		public uint32 blit_sw_CC	;
		public uint32 blit_sw_A	;
		public uint32 blit_fill	;
		public uint32 UnusedBits3	;

		public uint32 video_mem;
		public PixelFormat? vfmt;
		public int	current_w;
		public int	current_h;

		[CCode (cname="SDL_GetVideoInfo")]
		public static unowned VideoInfo get();
	}// VideoInfo

	[CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum OverlayFormat {
		YV12_OVERLAY, IYUV_OVERLAY, YUY2_OVERLAY,
		UYVY_OVERLAY, YVYU_OVERLAY
	}// OverlayFormat

	[CCode (cname="SDL_Overlay", free_function="SDL_FreeYUVOverlay")]
	[Compact]
	public class Overlay {
		public uint32 format;
		public int w;
		public int h;
		public int planes;
		uint16* pitches;
		uchar** pixels;

		uint32 hw_overlay;
		uint32 UnusedBits;

		[CCode (cname="SDL_CreateYUVOverlay")]
		public Overlay(int width, int height, OverlayFormat format, Surface display);

		[CCode (cname="SDL_LockYUVOverlay")]
		public int do_lock();

		[CCode (cname="SDL_UnlockYUVOverlay")]
		public void unlock();

		[CCode (cname="SDL_DisplayYUVOverlay")]
		public void display(Rect dst);
	}// Overlay


	///
	/// RWops
	///
	[CCode (cname="SDL_RWops", free_function="SDL_FreeRW")]
	[Compact]
	public class RWops {
		[CCode (cname="SDL_RWFromFile")]
		public RWops.from_file(string file, string mode);

		[CCode (cname="SDL_RWFromMem")]
		public RWops.from_mem(void* mem, int size);
	}// RWops


	///
	/// OpenGL
	///
	[CCode (cname="int", cprefix="SDL_GL_", has_type_id = false)]
	public enum GLattr {
		RED_SIZE, GREEN_SIZE, BLUE_SIZE, ALPHA_SIZE,
		BUFFER_SIZE, DOUBLEBUFFER, DEPTH_SIZE, STENCIL_SIZE,
		ACCUM_RED_SIZE, ACCUM_GREEN_SIZE, ACCUM_BLUE_SIZE,
		ACCUM_ALPHA_SIZE, STEREO, MULTISAMPLEBUFFERS,
		MULTISAMPLESAMPLES, ACCELERATED_VISUAL, SWAP_CONTROL
	}// GLattr

	[CCode (cprefix="SDL_GL_", cheader_filename="SDL.h")]
	[Compact]
	public class GL {
		[CCode (cname="SDL_GL_LoadLibrary")]
		public static int load_library(string path);

		[CCode (cname="SDL_GL_GetProcAddress")]
		public static void* get_proc_address(string proc);

		[CCode (cname="SDL_GL_SetAttribute")]
		public static int set_attribute(GLattr attr, int val);

		[CCode (cname="SDL_GL_GetAttribute")]
		public static int get_attribute(GLattr attr, ref int val);

		[CCode (cname="SDL_GL_SwapBuffers")]
		public static void swap_buffers();
	}// GL


	///
	/// Window manager
	///
	[CCode (cname="int", cprefix="SDL_GRAB_", has_type_id = false)]
	public enum GrabMode {
		QUERY, OFF, ON
	}// GrabMode

	[CCode (cprefix="SDL_WM_", cheader_filename="SDL.h")]
	[Compact]
	public class WindowManager {
		[CCode (cname="SDL_WM_SetCaption")]
		public static void set_caption(string title, string icon);

		[CCode (cname="SDL_WM_GetCaption")]
               public static void get_caption(out string title, out string icon);

		[CCode (cname="SDL_WM_SetIcon")]
		public static void set_icon(Surface icon, uchar* mask);

		[CCode (cname="SDL_WM_IconifyWindow")]
		public static int iconify();

		[CCode (cname="SDL_WM_ToggleFullScreen")]
		public static int toggle_fullscreen(Surface surface);

		[CCode (cname="SDL_WM_GrabInput")]
		public static GrabMode grab_input(GrabMode mode);
	}// WindowManager


	///
	/// Events
	///
	[CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum EventType {
		NOEVENT, ACTIVEEVENT, KEYDOWN, KEYUP, MOUSEMOTION,
		MOUSEBUTTONDOWN, MOUSEBUTTONUP, JOYAXISMOTION,
		JOYBALLMOTION, JOYHATMOTION, JOYBUTTONDOWN, JOYBUTTONUP,
		QUIT, SYSWMEVENT, VIDEORESIZE, VIDEOEXPOSE, USEREVENT,
		NUMEVENTS
	}// EventType

	[CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum EventMask {
		ACTIVEEVENTMASK, KEYDOWNMASK, KEYUPMASK, KEYEVENTMASK,
		MOUSEMOTIONMASK, MOUSEBUTTONDOWNMASK, MOUSEBUTTONUPMASK,
		MOUSEEVENTMASK, JOYAXISMOTIONMASK, JOYBALLMOTIONMASK,
		JOYHATMOTIONMASK, JOYBUTTONDOWNMASK, JOYBUTTONUPMASK,
		JOYEVENTMASK, VIDEORESIZEMASK, VIDEOEXPOSEMASK, QUITMASK,
		SYSWMEVENTMASK
	}// EventMask

	[CCode (cname="SDL_MouseButtonEvent", has_type_id=false)]
	public struct MouseButtonEvent {
		public uchar type;
		public uchar which;
		public uchar button;
		public uchar state;
		public uint16 x;
		public uint16 y;
	}// MouseButtonEvent

	[CCode (cheader_filename="SDL_active.h", cname="int", cprefix="SDL_APP", has_type_id = false)]
	public enum ActiveState {
		MOUSEFOCUS,
		INPUTFOCUS,
		ACTIVE
	}// ActiveState

	[CCode (cname="SDL_ActiveEvent", has_type_id=false)]
	public struct ActiveEvent {
		public uchar type;
		public uchar gain;
		public uchar state;
	}// ActiveEvent

	[CCode (cname="SDL_KeyboardEvent", has_type_id=false)]
	public struct KeyboardEvent {
		public uchar type;
		public uchar which;
		public uchar state;
		public Key keysym;
	}// KeyboardEvent

	[CCode (cname="SDL_MouseMotionEvent", has_type_id=false)]
	public struct MouseMotionEvent {
		public uchar type;
		public uchar which;
		public uchar state;
		public uint16 x;
		public uint16 y;
		public int16 xrel;
		public int16 yrel;
	}// MouseMotionEvent

	[CCode (cname="SDL_JoyAxisEvent", has_type_id=false)]
	public struct JoyAxisEvent {
		public uchar type;
		public uchar which;
		public uchar axis;
		public uint16 @value;
	}// JoyAxisEvent

	[CCode (cname="SDL_JoyBallEvent", has_type_id=false)]
	public struct JoyBallEvent {
		public uchar type;
		public uchar which;
		public uchar ball;
		public int16 xrel;
		public int16 yrel;
	}// JoyBallEvent

	[CCode (cname="SDL_JoyHatEvent", has_type_id=false)]
	public struct JoyHatEvent {
		public uchar type;
		public uchar which;
		public uchar hat;
		public uchar @value;
	}// JoyHatEvent

	[CCode (cname="SDL_JoyButtonEvent", has_type_id=false)]
	public struct JoyButtonEvent {
		public uchar type;
		public uchar which;
		public uchar button;
		public uchar state;
	}// JoyButtonEvent

	[CCode (cname="SDL_ResizeEvent", has_type_id=false)]
	public struct ResizeEvent {
		public uchar type;
		public int w;
		public int h;
	}// ResizeEvent

	[CCode (cname="SDL_ExposeEvent", has_type_id=false)]
	public struct ExposeEvent {
		public uchar type;
	}// ExposeEvent

	[CCode (cname="SDL_QuitEvent", has_type_id=false)]
	public struct QuitEvent {
		public uchar type;
	}// QuitEvent

	[CCode (cname="SDL_UserEvent", has_type_id=false)]
	public struct UserEvent {
		public uchar type;
		public int code;
		public void* data1;
		public void* data2;
	}// UserEvent

	[CCode (cname="SDL_SysWMEvent", has_type_id=false)]
	public struct SysWMEvent {
		public uchar type;
		public weak SysWMmsg msg;
	}// WMEvent

	[CCode (cname="SDL_SysWMmsg", cheader_filename="SDL_syswm.h")]
	public class SysWMmsg {
	}// SysWMmsg

	[CCode (cname="SDL_Event", has_type_id=false)]
	public struct Event {
		public uchar type;
		public ActiveEvent active;
		public KeyboardEvent key;
		public MouseMotionEvent motion;
		public MouseButtonEvent button;
		public JoyAxisEvent jaxis;
		public JoyBallEvent jball;
		public JoyHatEvent jhat;
		public JoyButtonEvent jbutton;
		public ResizeEvent resize;
		public ExposeEvent expose;
		public QuitEvent quit;
		public UserEvent user;
		public SysWMEvent syswm;

		[CCode (cname="SDL_PumpEvents")]
		public static void pump();

		[CCode (cname="SDL_PeepEvents")]
		public static void peep(Event* events, int numevents,
			EventAction action, EventMask mask);

		[CCode (cname="SDL_PollEvent")]
		public static int poll(out Event ev);

		[CCode (cname="SDL_WaitEvent")]
		public static int wait(out Event ev);

		[CCode (cname="SDL_PushEvent")]
		public static int push(Event ev);

		[CCode (cname="SDL_EventState")]
		public static uchar state(uchar type, EventState state);
	}// Event

	[CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum EventAction {
		ADDEVENT, PEEKEVENT, GETEVENT
	}// EventAction

	[CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum EventState {
		QUERY, IGNORE, DISABLE, ENABLE
	}// EventState


	///
	/// Input
	///
	[CCode (cname="int", cprefix="SDL_", has_type_id = false)]
	public enum ButtonState {
		RELEASED, PRESSED
	}// ButtonState

	[CCode (cname="SDL_keysym", has_type_id=false)]
	public struct Key {
		public uchar scancode;
		public KeySymbol sym;
		public KeyModifier mod;
		public uint16 unicode;

		[CCode (cname="SDL_EnableUNICODE")]
		public static int enable_unicode(int enable);

		[CCode (cname="SDL_EnableKeyRepeat")]
		public static int set_repeat(int delay, int interval);

		[CCode (cname="SDL_GetKeyRepeat")]
		public static void get_repeat(ref int delay, ref int interval);

		[CCode (cname="SDL_GetKeyState")]
		public static unowned uchar[] get_keys();

		[CCode (cname="SDL_GetModState")]
		public static KeyModifier get_modifiers();

		[CCode (cname="SDL_SetModState")]
		public static void set_modifiers(KeyModifier modstate);

		[CCode (cname="SDL_GetKeyName")]
		public static unowned string get_name(KeySymbol key);
	}// Key

	[CCode (cname="int", cprefix="SDLK_", cheader_filename="SDL_keysym.h", has_type_id = false)]
	public enum KeySymbol {
		UNKNOWN,
		FIRST,
		BACKSPACE,
		TAB,
		CLEAR,
		RETURN,
		PAUSE,
		ESCAPE,
		SPACE,
		EXCLAIM,
		QUOTEDBL,
		HASH,
		DOLLAR,
		AMPERSAND,
		QUOTE,
		LEFTPAREN,
		RIGHTPAREN,
		ASTERISK,
		PLUS,
		COMMA,
		MINUS,
		PERIOD,
		SLASH,
		ZERO = 48,
		ONE = 49,
		TWO = 50,
		THREE = 51,
		FOUR = 52,
		FIVE = 53,
		SIX = 54,
		SEVEN = 55,
		EIGHT = 56,
		NINE = 57,
		COLON,
		SEMICOLON,
		LESS,
		EQUALS,
		GREATER,
		QUESTION,
		AT,
		/*
		   Skip uppercase letters
		 */
		LEFTBRACKET,
		BACKSLASH,
		RIGHTBRACKET,
		CARET,
		UNDERSCORE,
		BACKQUOTE,
		a,
		b,
		c,
		d,
		e,
		f,
		g,
		h,
		i,
		j,
		k,
		l,
		m,
		n,
		o,
		p,
		q,
		r,
		s,
		t,
		u,
		v,
		w,
		x,
		y,
		z,
		DELETE,
		/* End of ASCII mapped keysyms */

		/* International keyboard syms */
		WORLD_0,		/* 0xA0 */
		WORLD_1,
		WORLD_2,
		WORLD_3,
		WORLD_4,
		WORLD_5,
		WORLD_6,
		WORLD_7,
		WORLD_8,
		WORLD_9,
		WORLD_10,
		WORLD_11,
		WORLD_12,
		WORLD_13,
		WORLD_14,
		WORLD_15,
		WORLD_16,
		WORLD_17,
		WORLD_18,
		WORLD_19,
		WORLD_20,
		WORLD_21,
		WORLD_22,
		WORLD_23,
		WORLD_24,
		WORLD_25,
		WORLD_26,
		WORLD_27,
		WORLD_28,
		WORLD_29,
		WORLD_30,
		WORLD_31,
		WORLD_32,
		WORLD_33,
		WORLD_34,
		WORLD_35,
		WORLD_36,
		WORLD_37,
		WORLD_38,
		WORLD_39,
		WORLD_40,
		WORLD_41,
		WORLD_42,
		WORLD_43,
		WORLD_44,
		WORLD_45,
		WORLD_46,
		WORLD_47,
		WORLD_48,
		WORLD_49,
		WORLD_50,
		WORLD_51,
		WORLD_52,
		WORLD_53,
		WORLD_54,
		WORLD_55,
		WORLD_56,
		WORLD_57,
		WORLD_58,
		WORLD_59,
		WORLD_60,
		WORLD_61,
		WORLD_62,
		WORLD_63,
		WORLD_64,
		WORLD_65,
		WORLD_66,
		WORLD_67,
		WORLD_68,
		WORLD_69,
		WORLD_70,
		WORLD_71,
		WORLD_72,
		WORLD_73,
		WORLD_74,
		WORLD_75,
		WORLD_76,
		WORLD_77,
		WORLD_78,
		WORLD_79,
		WORLD_80,
		WORLD_81,
		WORLD_82,
		WORLD_83,
		WORLD_84,
		WORLD_85,
		WORLD_86,
		WORLD_87,
		WORLD_88,
		WORLD_89,
		WORLD_90,
		WORLD_91,
		WORLD_92,
		WORLD_93,
		WORLD_94,
		WORLD_95,		/* 0xFF */

		/* Numeric keypad */
		KP0,
		KP1,
		KP2,
		KP3,
		KP4,
		KP5,
		KP6,
		KP7,
		KP8,
		KP9,
		KP_PERIOD,
		KP_DIVIDE,
		KP_MULTIPLY,
		KP_MINUS,
		KP_PLUS,
		KP_ENTER,
		KP_EQUALS,

		/* Arrows + Home/End pad */
		UP,
		DOWN,
		RIGHT,
		LEFT,
		INSERT,
		HOME,
		END,
		PAGEUP,
		PAGEDOWN,

		/* Function keys */
		F1,
		F2,
		F3,
		F4,
		F5,
		F6,
		F7,
		F8,
		F9,
		F10,
		F11,
		F12,
		F13,
		F14,
		F15,

		/* Key state modifier keys */
		NUMLOCK,
		CAPSLOCK,
		SCROLLOCK,
		RSHIFT,
		LSHIFT,
		RCTRL,
		LCTRL,
		RALT,
		LALT,
		RMETA,
		LMETA,
		LSUPER,		/* Left "Windows" key */
		RSUPER,		/* Right "Windows" key */
		MODE,		/* "Alt Gr" key */
		COMPOSE,		/* Multi-key compose key */

		/* Miscellaneous function keys */
		HELP,
		PRINT,
		SYSREQ,
		BREAK,
		MENU,
		POWER,		/* Power Macintosh power key */
		EURO,		/* Some european keyboards */
		UNDO,		/* Atari keyboard has Undo */

		/* Add any other keys here */

		LAST
	}// KeySymbol

	[CCode (cname="int", cprefix="KMOD_", cheader_filename="SDL_keysym.h", has_type_id = false)]
	public enum KeyModifier {
		NONE,
		LSHIFT,
		RSHIFT,
		LCTRL,
		RCTRL,
		LALT,
		RALT,
		LMETA,
		RMETA,
		NUM,
		CAPS,
		MODE,
		RESERVED,
		CTRL,
		SHIFT,
		ALT,
		META
	}// KeyModifier

	[CCode (cname="int", cprefix="SDL_BUTTON_", has_type_id = false)]
	public enum MouseButton {
		LEFT, MIDDLE, RIGHT, WHEELUP, WHEELDOWN
	}// Buttons

	[CCode (cname="SDL_Cursor", free_function="SDL_FreeCursor")]
	[Compact]
	public class Cursor {
		public Rect area;
		public int16 hot_x;
		public int16 hot_y;
		public uchar* data;
		public uchar* mask;
		public uchar** save;

		[CCode (cname="SDL_GetMouseState")]
		public static uchar get_state(ref int x, ref int y);

		[CCode (cname="SDL_GetRelativeMouseState")]
		public static uchar get_relative_state(ref int x, ref int y);

		[CCode (cname="SDL_WarpMouse")]
		public static void warp(uint16 x, uint16 y);

		[CCode (cname="SDL_CreateCursor")]
		public Cursor(uchar* data, uchar* mask, int w, int h,
			int hot_x, int hot_y);

		[CCode (cname="SDL_GetCursor")]
		public static Cursor get();

		[CCode (cname="SDL_SetCursor")]
		public static void set(Cursor cursor);

		[CCode (cname="SDL_ShowCursor")]
		public static int show(int toggle);
	}// Cursor

	[CCode (cname="int", cprefix="SDL_HAT_", has_type_id = false)]
	public enum HatValue {
		CENTERED, UP, RIGHT, DOWN, LEFT,
		RIGHTUP, RIGHTDOWN, LEFTUP, LEFTDOWN
	}// HatValue

	[CCode (cname="SDL_Joystick", free_function="SDL_JoystickClose")]
	[Compact]
	public class Joystick {
		[CCode (cname="SDL_JoystickName")]
		public static unowned string get_name(int device_index);

		[CCode (cname="SDL_JoystickOpened")]
		public static int is_open(int device_index);

		[CCode (cname="SDL_JoystickUpdate")]
		public static void update_all();

		[CCode (cname="SDL_JoystickEventState")]
		public static int event_state(EventState state);

		[CCode (cname="SDL_NumJoysticks")]
		public static int count();

		[CCode (cname="SDL_JoystickOpen")]
		public Joystick(int device_index);

		[CCode (cname="SDL_JoystickIndex")]
		public int index();

		[CCode (cname="SDL_JoystickNumAxes")]
		public int num_axes();

		[CCode (cname="SDL_JoystickNumBalls")]
		public int num_balls();

		[CCode (cname="SDL_JoystickNumHats")]
		public int num_hats();

		[CCode (cname="SDL_JoystickNumButtons")]
		public int num_buttons();

		[CCode (cname="SDL_JoystickGetAxis")]
		public int16 get_axis(int axis);

		[CCode (cname="SDL_JoystickGetHat")]
		public HatValue get_hat(int hat);

		[CCode (cname="SDL_JoystickGetBall")]
		public HatValue get_ball(int ball, ref int dx, ref int dy);

		[CCode (cname="SDL_JoystickGetButton")]
		public ButtonState get_button(int button);
	}// Joystick


	///
	/// Audio
	///
	[CCode (cname="int", cprefix="AUDIO_", has_type_id = false)]
	public enum AudioFormat {
		U8, S8, U16LSB, S16LSB, U16MSB, S16MSB, U16, S16,
		U16SYS, S16SYS
	}// AudioFormat

	[CCode (cname="int", cprefix="SDL_AUDIO_", has_type_id = false)]
	public enum AudioStatus {
		STOPPED, PLAYING, PAUSED
	}// AudioStatus

	[CCode (instance_pos = 0.1)]
	public delegate void AudioCallback(uint8[] stream);

	[CCode (cname="SDL_AudioSpec", has_type_id = false)]
	public struct AudioSpec {
		public int freq;
		public AudioFormat format;
		public uchar channels;
		public uchar silence;
		public uint16 samples;
		public uint16 padding;
		public uint32 size;
		[CCode (delegate_target_cname = "userdata")]
		public unowned AudioCallback callback;
	}// AudioSpec

	[CCode (cname="SDL_AudioCVT")]
	[Compact]
	public class AudioConverter {
		public int needed;
		public AudioFormat src_format;
		public AudioFormat dst_format;
		public double rate_incr;

		public uchar* buf;
		public int len;
		public int len_cvt;
		public int len_mult;
		public double len_ratio;
		public int filter_index;

		[CCode (cname="SDL_BuildAudioCVT")]
		public static int build(AudioConverter cvt, AudioFormat src_format,
			uchar src_channels, int src_rate, AudioFormat dst_format,
			uchar dst_channels, int dst_rate);

		[CCode (cname="SDL_ConvertAudio")]
		public int convert();
	}// AudioConverter

	[Compact]
	public class Audio {
		[CCode (cname="SDL_MIX_MAXVOLUME")]
		public const int MIX_MAXVOLUME;

		[CCode (cname="SDL_AudioDriverName")]
		public static unowned string driver_name(string namebuf, int maxlen);

		[CCode (cname="SDL_OpenAudio")]
		public static int open(AudioSpec desired, out AudioSpec obtained);

		[CCode (cname="SDL_GetAudioStatus")]
		public static AudioStatus status();

		[CCode (cname="SDL_PauseAudio")]
		public static void pause(int pause_on);

		[CCode (cname="SDL_LoadWAV_RW")]
		public static unowned AudioSpec? load(RWops src, int freesrc, ref AudioSpec spec, out uint8[] audio_buf);

		[CCode (cname="SDL_FreeWAV")]
		public static void free(uchar* audio_buf);

		[CCode (cname="SDL_MixAudio")]
		public static void mix([CCode (array_length = false)] uchar[] dst, [CCode (array_length = false)] uchar[] src, uint32 len, int volume);

		[CCode (cname="SDL_LockAudio")]
		public static void do_lock();

		[CCode (cname="SDL_UnlockAudio")]
		public static void unlock();

		[CCode (cname="SDL_CloseAudio")]
		public static void close();
	}// Audio


	///
	/// Threading
	///
	public delegate int ThreadFunc ();

	[CCode (cname="SDL_Thread", ref_function="", unref_function="")]
	[Compact]
	public class Thread {
		[CCode (cname="SDL_ThreadID")]
		public static uint32 id();

		[CCode (cname="SDL_CreateThread")]
		public Thread (ThreadFunc f);

		[CCode (cname="SDL_WaitThread")]
		public void wait (out int status = null);
	}// Thread

	[CCode (cname="SDL_mutex", free_function="SDL_DestroyMutex")]
	[Compact]
	public class Mutex {
		[CCode (cname="SDL_CreateMutex")]
		public Mutex();

		[CCode (cname="SDL_mutexP")]
		public int do_lock();

		[CCode (cname="SDL_mutexV")]
		public int unlock();
	}// Mutex

	[CCode (cname="SDL_sem", free_function="SDL_DestroySemaphore")]
	[Compact]
	public class Semaphore {
		[CCode (cname="SDL_CreateSemaphore")]
		public Semaphore(uint32 initial_value);

		[CCode (cname="SDL_SemWait")]
		public int wait();

		[CCode (cname="SDL_SemTryWait")]
		public int try_wait();

		[CCode (cname="SDL_SemWaitTimeout")]
		public int wait_timeout(uint32 ms);

		[CCode (cname="SDL_SemPost")]
		public int post();

		[CCode (cname="SDL_SemValue")]
		public uint32 count();
	}// Semaphore

	[CCode (cname="SDL_cond", free_function="SDL_DestroyCond")]
	[Compact]
	public class Condition {
		[CCode (cname="SDL_CreateCond")]
		public Condition();

		[CCode (cname="SDL_CondSignal")]
		public int @signal();

		[CCode (cname="SDL_CondBroadcast")]
		public int broadcast();

		[CCode (cname="SDL_CondWait")]
		public int wait(Mutex mut);

		[CCode (cname="SDL_CondWaitTimeout")]
		public int wait_timeout(Mutex mut, uint32 ms);
	}// Condition


	///
	/// Timers
	///
	public delegate uint32 TimerCallback (uint32 interval);

	[CCode (cname="struct _SDL_TimerID", ref_function="", unref_function="")]
	[Compact]
	public class Timer {
		[CCode (cname="SDL_RemoveTimer")]
		public bool remove ();

		[CCode (cname="SDL_GetTicks")]
		public static uint32 get_ticks();

		[CCode (cname="SDL_Delay")]
		public static void delay(uint32 ms);

		[CCode (cname="SDL_AddTimer")]
		public Timer (uint32 interval, TimerCallback callback);
	}// Timer
}// SDL
