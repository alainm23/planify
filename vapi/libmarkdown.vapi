[CCode (cprefix = "mkd")]
namespace Markdown {

    [Compact]
    [CCode (cheader_filename = "mkdio.h", cname = "MMIOT", free_function = "mkd_cleanup")]
    public class Document {

        [CCode (cname = "mkd_string")]
        public Document (uint8[] data, int flag = 0);

        [CCode (cname = "gfm_string")]
        public Document.gfm_format (uint8[] data, int flag = 0);

        [CCode (cname = "mkd_compile")]
        public void compile (int flag = 0);

        [CCode (cname = "mkd_document")]
        public int get_document (out unowned string result);
    }
}