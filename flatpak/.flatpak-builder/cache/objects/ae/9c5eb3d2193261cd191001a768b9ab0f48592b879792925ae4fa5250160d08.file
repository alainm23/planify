[CCode (cheader_filename="SDL_ttf.h")]
namespace SDLTTF {
	[CCode (cname="TTF_Linked_Version")]
	public static unowned SDL.Version linked();

	[CCode (cname="TTF_ByteSwappedUNICODE")]
	public static void byteswap_unicode(int swapped);

	[CCode (cname="TTF_Init")]
	public static int init();

	[CCode (cname="TTF_WasInit")]
	public static int get_initialized();

	[CCode (cname="TTF_Quit")]
	public static void quit();

	[CCode (cname="int", cprefix="TTF_STYLE_", has_type_id = false)]
	public enum FontStyle {
		NORMAL, BOLD, ITALIC, UNDERLINE
	}// FontStyle

	[CCode (cname="TTF_Font", free_function="TTF_CloseFont")]
	[Compact]
	public class Font {
		[CCode (cname="TTF_OpenFont")]
		public Font(string file, int ptsize);

		[CCode (cname="TTF_OpenFontIndex")]
		public Font.index(string file, int ptsize, long index);

		[CCode (cname="TTF_OpenFontRW")]
		public Font.RW(SDL.RWops src, int freesrc=0, int ptsize);

		[CCode (cname="TTF_OpenFontIndexRW")]
		public Font.RWindex(SDL.RWops src, int freesrc=0, int ptsize, long index);

		[CCode (cname="TTF_GetFontStyle")]
		public FontStyle get_style();

		[CCode (cname="TTF_SetFontStyle")]
		public FontStyle set_style(FontStyle style);

		[CCode (cname="TTF_FontHeight")]
		public int height();

		[CCode (cname="TTF_FontAscent")]
		public int ascent();

		[CCode (cname="TTF_FontDescent")]
		public int descent();

		[CCode (cname="TTF_FontLineSkip")]
		public int lineskip();

		[CCode (cname="TTF_FontFaces")]
		public long faces();

		[CCode (cname="TTF_FontFaceIsFixedWidth")]
		public int is_fixed_width();

		[CCode (cname="TTF_FontFaceFamilyName")]
		public string family();

		[CCode (cname="TTF_FontFaceStyleName")]
		public string style();

		[CCode (cname="TTF_GlyphMetrics")]
		public int metrics(uint16 ch, ref int minx, ref int maxx,
			ref int miny, ref int maxy, ref int advance);

		[CCode (cname="TTF_SizeText")]
		public int size(string text, ref int w, ref int h);

		[CCode (cname="TTF_SizeUTF8")]
		public int size_utf8(string text, ref int w, ref int h);

		[CCode (cname="TTF_SizeUNICODE")]
		public int size_unicode([CCode (array_length = false)] uint16[] text, ref int w, ref int h);

		[CCode (cname="TTF_RenderText_Solid")]
		public SDL.Surface? render(string text, SDL.Color fg);

		[CCode (cname="TTF_RenderUTF8_Solid")]
		public SDL.Surface? render_utf8(string text, SDL.Color fg);

		[CCode (cname="TTF_RenderUNICODE_Solid")]
		public SDL.Surface? render_unicode([CCode (array_length = false)] uint16[] text, SDL.Color fg);

		[CCode (cname="TTF_RenderText_Shaded")]
		public SDL.Surface? render_shaded(string text, SDL.Color fg, SDL.Color bg);

		[CCode (cname="TTF_RenderUTF8_Shaded")]
		public SDL.Surface? render_shaded_utf8(string text, SDL.Color fg, SDL.Color bg);

		[CCode (cname="TTF_RenderUNICODE_Shaded")]
		public SDL.Surface? render_shaded_unicode([CCode (array_length = false)] uint16[] text, SDL.Color fg, SDL.Color bg);

		[CCode (cname="TTF_RenderText_Blended")]
		public SDL.Surface? render_blended(string text, SDL.Color fg);

		[CCode (cname="TTF_RenderUTF8_Blended")]
		public SDL.Surface? render_blended_utf8(string text, SDL.Color fg);

		[CCode (cname="TTF_RenderUNICODE_Blended")]
		public SDL.Surface? render_blended_unicode([CCode (array_length = false)] uint16[] text, SDL.Color fg);
	}// Font
}// SDLTTF
