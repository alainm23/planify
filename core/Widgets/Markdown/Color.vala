/*
 *
 * Based on Folio
 * https://github.com/toolstack/Folio
 */
 
namespace Color {
	public struct HSL {
		public float h;
		public float s;
		public float l;
	}

	public struct RGB {
		public float r;
		public float g;
		public float b;

		public inline RGB (float r = 0, float g = 0, float b = 0) {
			this.r = r;
			this.g = g;
			this.b = b;
		}

		public inline RGB times (RGB rgb) {
			return RGB (r * rgb.r, g * rgb.g, b * rgb.b);
		}

		public inline RGB multiply (float x) {
			return RGB (r * x, g * x, b * x);
		}

		public inline RGB plus (RGB rgb) {
			return RGB (r + rgb.r, g + rgb.g, b + rgb.b);
		}
	}

	public inline HSL rgb_to_hsl (RGB rgb, out HSL hsl = null) {
		hsl = HSL();
		float s, v;
		Gtk.rgb_to_hsv(rgb.r, rgb.g, rgb.b, out hsl.h, out s, out v);
		hsl.l = v - v * s / 2;
		float m = float.min (hsl.l, 1 - hsl.l);
		hsl.s = (m != 0) ? (v-hsl.l)/m : 0;
		return hsl;
	}

	public inline RGB hsl_to_rgb (HSL hsl, out RGB rgb = null) {
		rgb = RGB();
		float v = hsl.s * float.min (hsl.l, 1 - hsl.l) + hsl.l;
		float s = (v != 0) ? 2-2*hsl.l/v : 0;
		Gtk.hsv_to_rgb(hsl.h, s, v, out rgb.r, out rgb.g, out rgb.b);
		return rgb;
	}

	public inline RGB RGBA_to_rgb (Gdk.RGBA rgba, out RGB rgb = null) {
		rgb = RGB();
		rgb.r = rgba.red;
		rgb.g = rgba.green;
		rgb.b = rgba.blue;
		return rgb;
	}

	public inline Gdk.RGBA rgb_to_RGBA (RGB rgb, out Gdk.RGBA rgba = null) {
		rgba = Gdk.RGBA();
		rgba.red = rgb.r;
		rgba.green = rgb.g;
		rgba.blue = rgb.b;
		rgba.alpha = 1;
		return rgba;
	}

	public inline float get_luminance (float r, float g, float b) {
		return Math.sqrtf (0.299f * r * r + 0.587f * g * g + 0.114f * b * b);
	}

	public inline float get_luminance_photometric (float r, float g, float b) {
		return 0.2126f * r + 0.7152f * g + 0.0722f;
	}

	public inline float get_luminance_digital (float r, float g, float b) {
		return 0.299f * r + 0.587f * g + 0.114f;
	}
}
