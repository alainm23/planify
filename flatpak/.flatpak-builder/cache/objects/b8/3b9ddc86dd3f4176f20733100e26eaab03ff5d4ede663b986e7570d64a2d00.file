namespace SDLGraphics {
	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Pixel {
		[CCode (cname="pixelColor")]
		public static int color(SDL.Surface dst, int16 x, int16 y, uint32 color);

		[CCode (cname="pixelRGBA")]
		public static int rgba(SDL.Surface dst, int16 x, int16 y,
			uchar r, uchar g, uchar b, uchar a);
	}// Pixel

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Line {
		[CCode (cname="hlineColor")]
		public static int color_h(SDL.Surface dst, int16 x1, int16 x2,
			int16 y, uint32 color);

		[CCode (cname="hlineRGBA")]
		public static int rgba_h(SDL.Surface dst, int16 x1, int16 x2,
			int16 y, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="vlineColor")]
		public static int color_v(SDL.Surface dst, int16 x, int16 y1,
			int16 y2, uint32 color);

		[CCode (cname="vlineRGBA")]
		public static int rgba_v(SDL.Surface dst, int16 x, int16 y1,
			int16 y2, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="lineColor")]
		public static int color(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, uint32 color);

		[CCode (cname="lineRGBA")]
		public static int rgba(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="aalineColor")]
		public static int color_aa(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, uint32 color);

		[CCode (cname="aalineRGBA")]
		public static int rgba_aa(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, uchar r, uchar g, uchar b, uchar a);
	}// Line

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Rectangle {
		[CCode (cname="rectangleColor")]
		public static int outline_color(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, uint32 color);

		[CCode (cname="rectangleRGBA")]
		public static int outline_rgba(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="boxColor")]
		public static int fill_color(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, uint32 color);

		[CCode (cname="boxRGBA")]
		public static int fill_rgba(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, uchar r, uchar g, uchar b, uchar a);
	}// Rectangle

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Circle {
		[CCode (cname="circleColor")]
		public static int outline_color(SDL.Surface dst, int16 x, int16 y,
			int16 radius, uint32 color);

		[CCode (cname="circleRGBA")]
		public static int outline_rgba(SDL.Surface dst, int16 x, int16 y, int16 radius,
			uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="aacircleColor")]
		public static int outline_color_aa(SDL.Surface dst, int16 x, int16 y,
			int16 radius, uint32 color);

		[CCode (cname="aacircleRGBA")]
		public static int outline_rgba_aa(SDL.Surface dst, int16 x, int16 y, int16 radius,
			uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="filledCircleColor")]
		public static int fill_color(SDL.Surface dst, int16 x, int16 y,
			int16 radius, uint32 color);

		[CCode (cname="filledCircleRGBA")]
		public static int fill_rgba(SDL.Surface dst, int16 x, int16 y, int16 radius,
			uchar r, uchar g, uchar b, uchar a);
	}// Circle

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Ellipse {
		[CCode (cname="ellipseColor")]
		public static int outline_color(SDL.Surface dst, int16 xc, int16 yc,
			int16 rx, int16 ry, uint32 color);

		[CCode (cname="ellipseRGBA")]
		public static int outline_rgba(SDL.Surface dst, int16 xc, int16 yc,
			int16 rx, int16 ry, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="aaellipseColor")]
		public static int outline_color_aa(SDL.Surface dst, int16 xc, int16 yc,
			int16 rx, int16 ry, uint32 color);

		[CCode (cname="aaellipseRGBA")]
		public static int outline_rgba_aa(SDL.Surface dst, int16 xc, int16 yc,
			int16 rx, int16 ry, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="filledEllipseColor")]
		public static int fill_color(SDL.Surface dst, int16 xc, int16 yc,
			int16 rx, int16 ry, uint32 color);

		[CCode (cname="filledEllipseRGBA")]
		public static int fill_rgba(SDL.Surface dst, int16 xc, int16 yc,
			int16 rx, int16 ry, uchar r, uchar g, uchar b, uchar a);
	}// Ellipse

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Arc {
		[CCode (cname="pieColor")]
		public static int outline_color(SDL.Surface dst, int16 x, int16 y, int16 radius,
			int16 start, int16 end, uint32 color);

		[CCode (cname="pieRGBA")]
		public static int outline_rgba(SDL.Surface dst, int16 x, int16 y, int16 radius,
			int16 start, int16 end, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="filledPieColor")]
		public static int fill_color(SDL.Surface dst, int16 x, int16 y, int16 radius,
			int16 start, int16 end, uint32 color);

		[CCode (cname="filledPieRGBA")]
		public static int fill_rgba(SDL.Surface dst, int16 x, int16 y, int16 radius,
			int16 start, int16 end, uchar r, uchar g, uchar b, uchar a);
	}// Arc

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Trigon {
		[CCode (cname="trigonColor")]
		public static int outline_color(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, int16 x3, int16 y3, uint32 color);

		[CCode (cname="trigonRGBA")]
		public static int outline_rgba(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, int16 x3, int16 y3,
			uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="aatrigonColor")]
		public static int outline_color_aa(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, int16 x3, int16 y3, uint32 color);

		[CCode (cname="aatrigonRGBA")]
		public static int outline_rgba_aa(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, int16 x3, int16 y3,
			uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="filledTrigonColor")]
		public static int fill_color(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, int16 x3, int16 y3, uint32 color);

		[CCode (cname="filledTrigonRGBA")]
		public static int fill_rgba(SDL.Surface dst, int16 x1, int16 y1,
			int16 x2, int16 y2, int16 x3, int16 y3,
			uchar r, uchar g, uchar b, uchar a);
	}// Trigon

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Polygon {
		[CCode (cname="polygonColor")]
		public static int outline_color(SDL.Surface dst, [CCode (array_length = false)] int16[] vx, [CCode (array_length = false)] int16[] vy,
			int n, uint32 color);

		[CCode (cname="polygonRGBA")]
		public static int outline_rgba(SDL.Surface dst, [CCode (array_length = false)] int16[] vx, [CCode (array_length = false)] int16[] vy,
			int n, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="aapolygonColor")]
		public static int outline_color_aa(SDL.Surface dst, [CCode (array_length = false)] int16[] vx, [CCode (array_length = false)] int16[] vy,
			int n, uint32 color);

		[CCode (cname="aapolygonRGBA")]
		public static int outline_rgba_aa(SDL.Surface dst, [CCode (array_length = false)] int16[] vx, [CCode (array_length = false)] int16[] vy,
			int n, uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="filledPolygonColor")]
		public static int fill_color(SDL.Surface dst, [CCode (array_length = false)] int16[] vx, [CCode (array_length = false)] int16[] vy,
			int n, uint32 color);

		[CCode (cname="filledPolygonRGBA")]
		public static int fill_rgba(SDL.Surface dst, [CCode (array_length = false)] int16[] vx, [CCode (array_length = false)] int16[] vy,
			int n, uchar r, uchar g, uchar b, uchar a);
	}// Polygon

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class BezierCurve {
		[CCode (cname="bezierColor")]
		public static int color(SDL.Surface dst, [CCode (array_length = false)] int16[] vx, [CCode (array_length = false)] int16[] vy,
			int vertices, int steps, uint32 color);

		[CCode (cname="bezierRGBA")]
		public static int rgba(SDL.Surface dst, [CCode (array_length = false)] int16[] vx, [CCode (array_length = false)] int16[] vy,
			int vertices, int steps, uchar r, uchar g, uchar b, uchar a);
	}// BezierCurve

	[CCode (cheader_filename="SDL_gfxPrimitives.h")]
	[Compact]
	public class Text {
		[CCode (cname="stringColor")]
		public static int color(SDL.Surface dst, int16 x, int16 y, string s, uint32 color);

		[CCode (cname="stringRGBA")]
		public static int rgba(SDL.Surface dst, int16 x, int16 y, string s,
			uchar r, uchar g, uchar b, uchar a);

		[CCode (cname="gfxPrimitivesSetFont")]
		public static int set_font(void* fontdata, int cw, int ch);
	}// Text

	[CCode (cheader_filename="SDL_rotozoom.h")]
	[Compact]
	public class RotoZoom {
		[CCode (cname="rotozoomSurface")]
		public static SDL.Surface rotozoom(SDL.Surface src, double degrees,
			double zoom, int smooth);

		[CCode (cname="rotozoomSurfaceXY")]
		public static SDL.Surface rotozoom_xy(SDL.Surface src, double degrees,
			double zoomx, double zoomy, int smooth);

		[CCode (cname="rotozoomSurfaceSize")]
		public static void rotozoom_size(int width, int height, double degrees,
			double zoom, ref int dstwidth, ref int dstheight);

		[CCode (cname="rotozoomSurfaceSizeXY")]
		public static void rotozoom_size_xy(int width, int height, double degrees,
			double zoomx, double zoomy, ref int dstwidth, ref int dstheight);

		[CCode (cname="zoomSurface")]
		public static SDL.Surface zoom(SDL.Surface src, double zoomx,
			double zoomy, int smooth);

		[CCode (cname="zoomSurfaceSize")]
		public static void zoom_size(int width, int height, double zoomx,
			double zoomy, ref int dstwidth, ref int dstheight);
	}// RotoZoom

	[CCode (cheader_filename="SDL_framerate.h", cname="FPSmanager", free_function="g_free", has_type_id = false)]
       public struct FramerateManager {
		[CCode (cname="SDL_initFramerate")]
		public void init();

		[CCode (cname="SDL_setFramerate")]
		public int set_rate(int rate);

		[CCode (cname="SDL_getFramerate")]
		public int get_rate();

		[CCode (cname="SDL_framerateDelay")]
		public void run();
	}// FramerateManager

	[CCode (cheader_filename="SDL_imageFilter.h")]
	[Compact]
	public class Filter {
		[CCode (cname="SDL_imageFilterMMXdetect")]
		public static int have_mmx();

		[CCode (cname="SDL_imageFilterMMXon")]
		public static void enable_mmx();

		[CCode (cname="SDL_imageFilterMMXoff")]
		public static void disable_mmx();

		[CCode (cname="SDL_imageFilterAdd")]
		public static int add([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterMean")]
		public static int mean([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterSub")]
		public static int subtract([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterAbsDiff")]
		public static int absolute_difference([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterMult")]
		public static int multiply([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterMultNor")]
		public static int multiply_normalized([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterMultDivby2")]
		public static int multiply_half([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterMultDivby4")]
		public static int multiply_quarter([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterBitAnd")]
		public static int and([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterBitOr")]
		public static int or([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterDiv")]
		public static int divide([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] src2, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterBitNegation")]
		public static int negate([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length);

		[CCode (cname="SDL_imageFilterAddByte")]
		public static int add_uchar([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar addend);

		[CCode (cname="SDL_imageFilterAddUint")]
		public static int add_uint([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uint addend);

		[CCode (cname="SDL_imageFilterAddByteToHalf")]
		public static int halve_add_uchar([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar addend);

		[CCode (cname="SDL_imageFilterSubByte")]
		public static int subtract_uchar([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar subtrahend);

		[CCode (cname="SDL_imageFilterSubUint")]
		public static int subtract_uint([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uint subtrahend);

		[CCode (cname="SDL_imageFilterShiftRight")]
		public static int shift_right_uchar([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar shiftcount);

		[CCode (cname="SDL_imageFilterShiftRightUint")]
		public static int shift_right_uint([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uint shiftcount);

		[CCode (cname="SDL_imageFilterMultByByte")]
		public static int multiply_uchar([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar multiplicand);

		[CCode (cname="SDL_imageFilterShiftRightAndMultByByte")]
		public static int shift_right_multiply_uchar([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar shiftcount, uchar multiplicand);

		[CCode (cname="SDL_imageFilterShiftLeftByte")]
		public static int shift_left_uchar([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar shiftcount);

		[CCode (cname="SDL_imageFilterShiftLeftUint")]
		public static int shift_left_uint([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uint shiftcount);

		[CCode (cname="SDL_imageFilterBinarizeUsingThreshold")]
		public static int binarize([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar threshold);

		[CCode (cname="SDL_imageFilterClipToRange")]
		public static int clip([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, uchar min, uchar max);

		[CCode (cname="SDL_imageFilterNormalize")]
		public static int normalize([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int length, int cmin, int cmax, int nmin, int nmax);

		[CCode (cname="SDL_imageFilterConvolveKernel3x3Divide")]
		public static int convolve_3x3_divide([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, [CCode (array_length = false)] int16[] kernel, uchar divisor);

		[CCode (cname="SDL_imageFilterConvolveKernel5x5Divide")]
		public static int convolve_5x5_divide([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, [CCode (array_length = false)] int16[] kernel, uchar divisor);

		[CCode (cname="SDL_imageFilterConvolveKernel7x7Divide")]
		public static int convolve_7x7_divide([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, [CCode (array_length = false)] int16[] kernel, uchar divisor);

		[CCode (cname="SDL_imageFilterConvolveKernel9x9Divide")]
		public static int convolve_9x9_divide([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, [CCode (array_length = false)] int16[] kernel, uchar divisor);

		[CCode (cname="SDL_imageFilterConvolveKernel3x3ShiftRight")]
		public static int convolve_3x3_shift([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, [CCode (array_length = false)] int16[] kernel, uchar shiftcount);

		[CCode (cname="SDL_imageFilterConvolveKernel5x5ShiftRight")]
		public static int convolve_5x5_shift([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, [CCode (array_length = false)] int16[] kernel, uchar shiftcount);

		[CCode (cname="SDL_imageFilterConvolveKernel7x7ShiftRight")]
		public static int convolve_7x7_shift([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, [CCode (array_length = false)] int16[] kernel, uchar shiftcount);

		[CCode (cname="SDL_imageFilterConvolveKernel9x9ShiftRight")]
		public static int convolve_9x9_shift([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, [CCode (array_length = false)] int16[] kernel, uchar shiftcount);

		[CCode (cname="SDL_imageFilterSobelX")]
		public static int sobel([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns);

		[CCode (cname="SDL_imageFilterSobelXShiftRight")]
		public static int sobel_shift([CCode (array_length = false)] uchar[] src1, [CCode (array_length = false)] uchar[] dst, int rows, int columns, uchar shiftcount);
	}// Filter
}// SDLGraphics
