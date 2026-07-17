// Loosely based on icu-uc.vapi from Geary project which in turn is based on the Dino project.

[CCode (cheader_filename = "unicode/uloc.h")]
namespace ICU {

    [CCode (cname = "UChar")]
	[IntegerType (rank = 5, min = 0, max = 65535)]
	public struct Char {}

	[CCode (cname = "UErrorCode", cprefix = "U_", cheader_filename = "unicode/utypes.h")]
	public enum ErrorCode {
		ZERO_ERROR,
		INVALID_CHAR_FOUND,
		INDEX_OUTOFBOUNDS_ERROR,
		BUFFER_OVERFLOW_ERROR,
		STRINGPREP_PROHIBITED_ERROR,
		UNASSIGNED_CODE_POINT_FOUND,
		IDNA_STD3_ASCII_RULES_ERROR;

		[CCode (cname = "u_errorName")]
		public unowned string errorName();

		[CCode (cname = "U_SUCCESS")]
		public bool is_success();

		[CCode (cname = "U_FAILURE")]
		public bool is_failure();
	}

    [CCode (cname = "uloc_getDisplayLanguage")]
    public int c_get_display_language (
        string locale,
        string display_locale,
        [CCode (array_length = false)] Char[] dest,
        int dest_capacity,
        ref ErrorCode error
    );

    public string get_display_language (string locale, string display_locale) {
        ICU.ErrorCode status = ICU.ErrorCode.ZERO_ERROR;

        ICU.Char[] tmp = new ICU.Char[256];

        int len = ICU.c_get_display_language (
            locale,
            display_locale,
            tmp,
            tmp.length,
            ref status
        );

        if (status.is_failure () || len <= 0) {
            return "Unknown";
        }

        try {
            return GLib.convert ((string)((uint8[]) tmp), len * 2, "UTF-8", "UTF-16");
        }  catch (GLib.ConvertError e) {
            return "Unknown";
        }
    }
}
