/* linux.vapi
 *
 * Copyright (C) 2009-2015 Michael 'Mickey' Lauer <mlauer@vanille-media.de>
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
 */

[CCode (cprefix = "", lower_case_cprefix = "")]
namespace Linux {

    /*
     * Console
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Console {

        /* constants */

        [CCode (cheader_filename = "linux/kd.h")]
        public const int GIO_FONT;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int PIO_FONT;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int GIO_FONTX;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int PIO_FONTX;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int PIO_FONTRESET;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int GIO_CMAP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int PIO_CMAP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KIOCSOUND;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDMKTONE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGETLED;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSETLED;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGKBTYPE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KB_84;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KB_101;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KB_OTHER;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDADDIO;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDDELIO;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDENABIO;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDDISABIO;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSETMODE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGETMODE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDMAPDISP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDUNMAPDISP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int E_TABSZ;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int GIO_SCRNMAP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int PIO_SCRNMAP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int GIO_UNISCRNMAP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int PIO_UNISCRNMAP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int GIO_UNIMAP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int PIO_UNIMAP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int PIO_UNIMAPCLR;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int UNI_DIRECT_BASE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int UNI_DIRECT_MASK;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGKBMODE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSKBMODE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGKBMETA;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSKBMETA;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGKBLED;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSKBLED;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int K_NORMTAB;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int K_SHIFTTAB;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int K_ALTTAB;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int K_ALTSHIFTTAB;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGKBSENT;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSKBSENT;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGKBDIACR;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSKBDIACR;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGKBDIACRUC;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSKBDIACRUC;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDGETKEYCODE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSETKEYCODE;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDSIGACCEPT;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDKBDREP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KDFONTOP;
        [CCode (cheader_filename = "linux/kd.h")]
        public const int KD_FONT_FLAG_DONT_RECALC;

        /* enums */

        [CCode (cprefix = "KD_FONT_OP_", has_type_id = false, cheader_filename = "linux/kd.h")]
        public enum FontOperationCode {
            SET,
            GET,
            SET_DEFAULT,
            COPY
        }

        [CCode (cprefix = "K_", has_type_id = false, cheader_filename = "linux/kd.h")]
        public enum KeyboardMode {
            RAW,
            XLATE,
            MEDIUMRAW,
            UNICODE
        }

        [CCode (cprefix = "K_", has_type_id = false, cheader_filename = "linux/kd.h")]
        public enum LedMode {
            SCROLLLOCK,
            NUMLOCK,
            CAPSLOCK
        }

        [CCode (cprefix = "LED_", has_type_id = false, cheader_filename = "linux/kd.h")]
        public enum LedType {
            SCR,
            NUM,
            CAP
        }

        [CCode (cprefix = "KD_", has_type_id = false, cheader_filename = "linux/kd.h")]
        public enum TerminalMode {
            TEXT,
            GRAPHICS
        }

        [CCode (cprefix = "K_", has_type_id = false, cheader_filename = "linux/kd.h")]
        public enum MetaMode {
            METABIT,
            ESCPREFIX
        }

        /* structs */

        [CCode (cname = "struct kbdiacr", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct Diacritic {
            public uchar diacr;
            public uchar base;
            public uchar result;
        }

        [CCode (cname = "struct kbdiacrs", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct Diacritics {
            public uint kb_cnt;
            public Diacritic kbdiacr[256];
        }

        [CCode (cname = "struct kbdiacruc", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct Diacruc {
            public uint diacr;
            public uint base;
            public uint result;
        }

        [CCode (cname = "struct kbdiacrsuc", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct Diacrucs {
            public uint kb_cnt;
            public Diacruc kbdiacruc[256];
        }

        [CCode (cname = "struct console_font", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct Font {
            public uint width;
            public uint height;
            public uint charcount;
            public uchar* data;
        }

        [CCode (cname = "struct consolefontdesc", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct FontDescription {
            public uint16 charcount;
            public uint16 charheight;
            public string chardata;
        }

        [CCode (cname = "struct console_font_op", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct FontOperation {
            public FontOperationCode op;
            public uint flags;
            public uint width;
            public uint height;
            public uint charcount;
            public uchar* data;
        }

        [CCode (cname = "struct kbkeycode", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct KeyCode {
            public uint scancode;
            public uint keycode;
        }

        [CCode (cname = "struct kbentry", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct KeyboardEntry {
            public uchar kb_table;
            public uchar kb_index;
            public uint16 kb_value;
        }

        [CCode (cname = "struct kbsentry", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct KeyboardEntries {
            public uchar kb_func;
            public uchar kb_string[512];
        }

        [CCode (cname = "struct kbd_repeat", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct KeyRepeat {
            public int delay;
            public int period;
        }

        [CCode (cname = "struct unipair", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct UniPair {
            public uint16 unicode;
            public uint16 fontpos;
        }

        [CCode (cname = "struct unimapdesc", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct UniMapDesc {
            public uint16 entry_ct;
            UniPair entries;
        }

        [CCode (cname = "struct unimapinit", has_type_id = false, cheader_filename = "linux/kd.h")]
        public struct UniMapInit {
            public uint16 advised_hashsize;
            public uint16 advised_hashstep;
            public uint16 advised_hashlevel;
        }
    }

    /*
     * EventFd
     */
    [CCode (cprefix = "EFD_", has_type_id = false, cheader_filename = "sys/eventfd.h")]
    public enum EventFdFlags {
        CLOEXEC,
        NONBLOCK
    }

    [CCode (cheader_filename = "sys/eventfd.h")]
    public int eventfd (uint count = 0, EventFdFlags flags = 0);
    public int eventfd_read (int fd, out uint64 value);
    public int eventfd_write (int fd, uint64 value);

    /*
     * Epoll
     */
    [CCode (cprefix = "EPOLL_", has_type_id = false, cheader_filename = "sys/epoll.h")]
    public enum EpollFdFlags {
        CLOEXEC,
    }

    [CCode (cheader_filename = "sys/epoll.h", has_type_id = false, cname = "union epoll_data")]
    public struct EpollData {
        public void* ptr;
        public int fd;
        public uint32 u32;
        public uint64 u64;
    }

    [CCode (cheader_filename = "sys/epoll.h", has_type_id = false, cname = "struct epoll_event")]
    public struct EpollEvent {
        public uint32 events;
        public EpollData data;
    }

    [CCode (cheader_filename = "sys/epoll.h")]
    public int epoll_create (int size = 0);
    [CCode (cheader_filename = "sys/epoll.h")]
    public int epoll_create1 (int flags = 0);
    [CCode (cheader_filename = "sys/epoll.h")]
    public int epoll_wait (int epfd, EpollEvent[] events, int timeout);
    [CCode (cheader_filename = "sys/epoll.h")]
    public int epoll_pwait (int epfd, EpollEvent[] events, Posix.sigset_t? sigmask, int timeout);
    [CCode (cheader_filename = "sys/epoll.h")]
    public int epoll_ctl (int epfd, int op, int fd, EpollEvent? ev);
    [CCode (cheader_filename = "sys/epoll.h")]
    public const int EPOLLIN;
    [CCode (cheader_filename = "sys/epoll.h")]
    public const int EPOLLOUT;
    [CCode (cheader_filename = "sys/epoll.h")]
    public const int EPOLLERR;
    [CCode (cheader_filename = "sys/epoll.h")]
    public const int EPOLLHUP;
    [CCode (cheader_filename = "sys/epoll.h")]
    public const int EPOLLET;
    [CCode (cheader_filename = "sys/epoll.h")]
    public const int EPOLL_CTL_ADD;
    [CCode (cheader_filename = "sys/epoll.h")]
    public const int EPOLL_CTL_MOD;
    [CCode (cheader_filename = "sys/epoll.h")]
    public const int EPOLL_CTL_DEL;

    /*
     * Framebuffer
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Framebuffer {

        /* ioctls */
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGET_VSCREENINFO;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOPUT_VSCREENINFO;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGET_FSCREENINFO;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGETCMAP;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOPUTCMAP;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOPAN_DISPLAY;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIO_CURSOR;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGET_MONITORSPEC;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOPUT_MONITORSPEC;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOSWITCH_MONIBIT;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGET_CON2FBMAP;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOPUT_CON2FBMAP;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOBLANK;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGET_VBLANK;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIO_ALLOC;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIO_FREE;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGET_GLYPH;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGET_HWCINFO;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOPUT_MODEINFO;
        [CCode (cheader_filename = "linux/fb.h")]
        public const int FBIOGET_DISPINFO;

        /* enums */

        [CCode (cname = "guint32", cprefix = "FB_TYPE_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Type {
            PACKED_PIXELS,
            PLANES,
            INTERLEAVED_PLANES,
            TEXT,
            VGA_PLANES
        }

        [CCode (cname = "guint32", cprefix = "FB_ACTIVATE_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Activate {
            NOW,
            NXTOPEN,
            TEST,
            MASK,
            VBL,
            [CCode (cname = "FB_CHANGE_CMAP_VBL")]
            CHANGE_CMAP_VBL,
            ALL,
            FORCE,
            INV_MODE
        }

        [CCode (cname = "guint32", cprefix = "FB_ACCEL_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Accel {
            NONE
        }

        [CCode (cname = "guint32", cprefix = "FB_AUX_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Aux {
             TEXT_MDA,
             TEXT_CGA,
             TEXT_S3_MMIO,
             TEXT_MGA_STEP16,
             TEXT_MGA_STEP8,
             TEXT_SVGA_GROUP,
             TEXT_SVGA_MASK,
             TEXT_SVGA_STEP2,
             TEXT_SVGA_STEP4,
             TEXT_SVGA_STEP8,
             TEXT_SVGA_STEP16,
             TEXT_SVGA_LAST,
             VGA_PLANES_VGA4,
             VGA_PLANES_CFB4,
             VGA_PLANES_CFB8
        }

        [CCode (cprefix = "FB_BLANK_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Blank {
            UNBLANK,
            NORMAL,
            VSYNC_SUSPEND,
            HSYNC_SUSPEND,
            POWERDOWN
        }

        [CCode (cprefix = "FB_CUR_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Cur {
            SETIMAGE,
            SETPOS,
            SETHOT,
            SETCMAP,
            SETSHAPE,
            SETSIZE,
            SETALL
        }

        [CCode (cname = "guint32", cprefix = "ROP_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Rop {
            COPY,
            XOR
        }

        [CCode (cprefix = "FB_ROTATE_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Rotate {
            UR,
            CW,
            UD,
            CCW
        }

        [CCode (cname = "guint32", cprefix = "FB_SYNC_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Sync {
            HOR_HIGH_ACT,
            VERT_HIGH_ACT,
            EXT,
            COMP_HIGH_ACT,
            BROADCAST,
            ON_GREEN
        }

        [CCode (cname = "guint32", cprefix = "FB_VISUAL_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Visual {
            MONO01,
            MONO10,
            TRUECOLOR,
            PSEUDOCOLOR,
            DIRECTCOLOR,
            STATIC_PSEUDOCOLOR
        }

        [CCode (cname = "guint32", cprefix = "FB_VMODE_", has_type_id = false, cheader_filename = "linux/fb.h")]
        public enum Vmode {
            NONINTERLACED,
            INTERLACED,
            DOUBLE,
            ODD_FLD_FIRST,
            MASK,
            YWRAP,
            SMOOTH_XPAN,
            CONUPDATE
        }

        /* structures */

        [CCode (cname = "struct fb_bitfield", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct BitField {
            public uint32 offset;
            public uint32 length;
            public uint32 msb_right;
        }

        [CCode (cname = "struct fb_cmap", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct Cmap {
            public uint32 start;
            public uint32 len;
            public uint16* red;
            public uint16* green;
            public uint16* blue;
            public uint16* transp;
        }

        [CCode (cname = "struct fb_con2fbmap", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct Con2FbMap {
            public uint32 console;
            public uint32 framebuffer;
        }

        [CCode (cname = "struct fbcurpos", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct CurPos {
            public uint16 x;
            public uint16 y;
        }

        [CCode (cname = "struct fb_cursor", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct Cursor {
            public uint16 set;
            public uint16 enable;
            public uint16 rop;
            string mask;
            public CurPos hot;
            public Image image;
        }

        [CCode (cname = "struct fb_copyarea", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct CopyArea {
            public uint32 dx;
            public uint32 dy;
            public uint32 width;
            public uint32 height;
            public uint32 sx;
            public uint32 sy;
        }

        [CCode (cname = "struct fb_fillrect", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct FillRect {
            public uint32 dx;
            public uint32 dy;
            public uint32 width;
            public uint32 height;
            public uint32 color;
            public Rop rop;
        }

        [CCode (cname = "struct fb_image", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct Image {
            public uint32 dx;
            public uint32 dy;
            public uint32 width;
            public uint32 height;
            public uint32 fg_color;
            public uint32 bg_color;
            public uint8 depth;
            public char* data;
            public Cmap cmap;
        }

        [CCode (cname = "struct fb_fix_screeninfo", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct FixScreenInfo {
            public char id[16];
            public long smem_start;
            public uint32 smem_len;
            public Type type;
            public Aux type_aux;
            public Visual visual;
            public uint16 xpanstep;
            public uint16 ypanstep;
            public uint16 ywrapstep;
            public uint32 line_length;
            public long mmio_start;
            public uint32 mmio_len;
            public Accel accel;
        }

        [CCode (cname = "struct fb_var_screeninfo", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct VarScreenInfo {
            public uint32 xres;
            public uint32 yres;
            public uint32 xres_virtual;
            public uint32 yres_virtual;
            public uint32 xoffset;
            public uint32 yoffset;
            public uint32 bits_per_pixel;
            public uint32 grayscale;
            public BitField red;
            public BitField green;
            public BitField blue;
            public BitField transp;
            public uint32 nonstd;
            public Activate activate;
            public uint32 height;
            public uint32 width;
            public uint32 pixclock;
            public uint32 left_margin;
            public uint32 right_margin;
            public uint32 upper_margin;
            public uint32 lower_margin;
            public uint32 hsync_len;
            public uint32 vsync_len;
            public Sync sync;
            public Vmode vmode;
            public uint32 rotate;
        }

        [CCode (cname = "struct fb_vblank", has_type_id = false, cheader_filename = "linux/fb.h")]
        public struct Vblank {
            public uint32 flags;
            public uint32 count;
            public uint32 vcount;
            public uint32 hcount;
        }

        [CCode (lower_case_cprefix = "omapfb_", has_type_id = false, cheader_filename = "linux/omapfb.h")]
        namespace OMAP {
            [CCode (cname = "int", has_type_id = false, cprefix = "OMAPFB_")]
            public enum IOCTL {
                MIRROR,
                SYNC_GFX,
                VSYNC,
                SET_UPDATE_MODE,
                GET_CAPS,
                GET_UPDATE_MODE,
                LCD_TEST,
                CTRL_TEST,
                UPDATE_WINDOW_OLD,
                SET_COLOR_KEY,
                GET_COLOR_KEY,
                SETUP_PLANE,
                QUERY_PLANE,
                UPDATE_WINDOW,
                SETUP_MEM,
                QUERY_MEM,
                WAITFORVSYNC,
                MEMORY_READ,
                GET_OVERLAY_COLORMODE,
                WAITFORGO,
                GET_VRAM_INFO,
                SET_TEARSYNC
            }

            [Flags, CCode (cname = "int", has_type_id = false, prefix = "OMAPFB_CAPS_")]
            public enum Caps {
                GENERIC_MASK,
                LCDC_MASK,
                PANEL_MASK,

                MANUAL_UPDATE,
                TEARSYNC,
                PLANE_RELOCATE_MEM,
                PLANE_SCALE,
                WINDOW_PIXEL_DOUBLE,
                WINDOW_SCALE,
                WINDOW_OVERLAY,
                WINDOW_ROTATE,
                SET_BACKLIGHT,
            }

            [Flags, CCode (cname = "int", has_type_id = false, cprefix = "OMAPFB_FORMAT_FLAG_")]
            public enum Format {
                [CCode (cname = "OMAPFB_FORMAT_MASK")]
                MASK,

                DOUBLE,
                TEARSYNC,
                FORCE_VSYNC,
                ENABLE_OVERLAY,
                DISABLE_OVERLAY
            }

            [CCode (cname = "int", has_type_id = false, cprefix = "OMAPFB_MEMTYPE_")]
            public enum MemType {
                SDRAM,
                SRAM,
                MAX
            }

            [CCode (cname = "enum omapfb_color_format", has_type_id = false, cprefix = "OMAPFB_COLOR_")]
            public enum ColorFormat {
                RGB565,
                YUV422,
                YUV420,
                CLUT_8BPP,
                CLUT_4BPP,
                CLUT_2BPP,
                CLUT_1BPP,
                RGB444,
                YUY422,

                ARGB16,
                RGB24U,
                RGB24P,
                ARGB32,
                RGBA32,
                RGBX32,
            }

            [CCode (cname = "omapfb_update_window", has_type_id = false)]
            public struct UpdateWindow {
                public uint32 x;
                public uint32 y;
                public uint32 width;
                public uint32 height;
                public uint32 format;
                public uint32 out_x;
                public uint32 out_y;
                public uint32 out_width;
                public uint32 out_height;
            }

            [CCode (cname = "enum omapfb_plane", has_type_id = false, cprefix = "OMAPFB_PLANE_")]
            public enum Plane {
                GFX,
                VID1,
                VID2
            }

            [CCode (cname = "enum omapfb_channel_out", has_type_id = false, cprefix = "OMAPFB_CHANNEL_OUT_")]
            public enum ChannelOut {
                LCD,
                DIGIT
            }

            [CCode (cname = "struct omapfb_plane_info", has_type_id = false)]
            public struct PlaneInfo {
                public uint32 pos_x;
                public uint32 pos_y;
                public uint8 enabled;
                public uint8 channel_out;
                public uint8 mirror;
                public uint32 out_width;
                public uint32 out_height;
            }

            [CCode (cname = "struct omapfb_mem_info", has_type_id = false)]
            public struct MemInfo {
                public uint32 size;
                public uint8 type;
            }

            [CCode (cname = "struct omapfb_caps", has_type_id = false)]
            public struct Capabilities {
                public uint32 ctrl;
                public uint32 plane_color;
                public uint32 wnd_color;
            }

            [CCode (cname = "enum omapfb_color_key_type", has_type_id = false, cprefix = "OMAPFB_COLOR_KEY_")]
            public enum ColorKeyType {
                DISABLED,
                GFX_DST,
                VID_SRC
            }

            [CCode (cname = "struct omapfb_color_key", has_type_id = false)]
            public struct ColorKey {
                public uint8 channel_out;
                public uint32 background;
                public uint32 trans_key;
                public uint8 key_type;
            }

            [CCode (cname = "enum omapfb_update_mode", has_type_id = false)]
            public enum UpdateMode {
                [CCode (cname = "OMAPFB_UPDATE_DISABLED")]
                DISABLED,
                [CCode (cname = "OMAPFB_AUTO_UPDATE")]
                AUTO,
                [CCode (cname = "OMAPFB_MANUAL_UPDATE")]
                MANUAL
            }

            [CCode (cname = "struct omapfb_memory_read", has_type_id = false)]
            public struct MemoryRead {
                public uint16 x;
                public uint16 y;
                public uint16 w;
                public uint16 h;
                public size_t buffer_size;
                public void* buffer;
            }

            [CCode (cname = "struct omapfb_ovl_colormode", has_type_id = false)]
            public struct OvlColorMode {
                public uint8 overlay_idx;
                public uint8 mode_idx;
                public uint32 bits_per_pixel;
                public uint32 nonstd;
                public Framebuffer.BitField red;
                public Framebuffer.BitField green;
                public Framebuffer.BitField blue;
                public Framebuffer.BitField transp;
            }

            [CCode (cname = "struct omapfb_vram_info", has_type_id = false)]
            public struct VRamInfo {
                public uint32 total;
                public uint32 free;
                public uint32 largest_free_block;
            }

            [CCode (cname = "struct omapfb_tearsync_info", has_type_id = false)]
            public struct TearSyncInfo {
                public uint8 enabled;
                public uint16 line;
            }
        }
    }

    // Non-Posix file control constants, -D _GNU_SOURCE
    [CCode (cheader_filename = "fcntl.h", feature_test_macro = "_GNU_SOURCE")]
    public const int O_DIRECT;
    [CCode (cheader_filename = "fcntl.h", feature_test_macro = "_GNU_SOURCE")]
    public const int O_NOATIME;
    [CCode (cheader_filename = "fcntl.h", feature_test_macro = "_GNU_SOURCE")]
    public const int O_PATH;
    [CCode (cheader_filename = "fcntl.h", feature_test_macro = "_GNU_SOURCE")]
    public const int O_TMPFILE;

    /*
     * Gsm
     */
    namespace Gsm {

        [CCode (cname = "GSMIOC_GETCONF", cheader_filename = "linux/gsmmux.h")]
        public const int GSMIOC_GETCONF;
        [CCode (cname = "GSMIOC_SETCONF", cheader_filename = "linux/gsmmux.h")]
        public const int GSMIOC_SETCONF;

        [CCode (cname = "struct gsm_config", has_type_id = false, cheader_filename = "linux/gsmmux.h")]
        public struct Config {
            public uint adaption;
            public uint encapsulation;
            public uint initiator;
            public uint t1;
            public uint t2;
            public uint t3;
            public uint n2;
            public uint mru;
            public uint mtu;
            public uint k;
            public uint i;
        }
    }

    /*
     * I2C and System Management Bus
     */
    [CCode (cprefix = "I2C_", lower_case_cprefix = "i2c_")]
    namespace I2C {

        const int SLAVE;

        [CCode (cprefix = "", lower_case_cprefix = "i2c_smbus_")]
        namespace SMBUS {
            int32 write_byte_data_masked (int file, uint8 mask, uint8 command, uint8 value)
            {
                int32 result = read_byte_data (file, command);
                if (result == -1)
                {
                    return -1;
                }
                uint8 oldvalue = (uint8) result & 0xff;
                return write_byte_data (file, command, oldvalue | (value & mask) );
            }

            //[CCode (cheader_filename = "i2c.h")]
            //int32 access(int file, char read_write, uint8 command, int size, union data *data);
            [CCode (cheader_filename = "i2c.h")]
            int32 write_quick (int file, uint8 value);
            [CCode (cheader_filename = "i2c.h")]
            int32 read_byte (int file);
            [CCode (cheader_filename = "i2c.h")]
            int32 write_byte (int file, uint8 value);
            [CCode (cheader_filename = "i2c.h")]
            int32 read_byte_data (int file, uint8 command);
            [CCode (cheader_filename = "i2c.h")]
            int32 write_byte_data (int file, uint8 command, uint8 value);
            [CCode (cheader_filename = "i2c.h")]
            int32 read_word_data (int file, uint8 command);
            [CCode (cheader_filename = "i2c.h")]
            int32 write_word_data (int file, uint8 command, uint16 value);
            [CCode (cheader_filename = "i2c.h")]
            int32 process_call (int file, uint8 command, uint16 value);
            [CCode (cheader_filename = "i2c.h")]
            int32 read_block_data (int file, uint8 command, [CCode (array_length=false)] uint8[] values);
            [CCode (cheader_filename = "i2c.h")]
            int32 write_block_data (int file, uint8 command, [CCode (array_length_pos = 2.3)] uint8[] values);
            [CCode (cheader_filename = "i2c.h")]
            int32 read_i2c_block_data (int file, uint8 command, [CCode (array_length_pos = 2.3)] uint8[] values);
            [CCode (cheader_filename = "i2c.h")]
            int32 write_i2c_block_data (int file, uint8 command, [CCode (array_length_pos = 2.3)] uint8[] values);
            [CCode (cheader_filename = "i2c.h")]
            int32 block_process_call (int file, uint8 command, [CCode (array_length_pos = 2.3)] uint8[] values);
        }
    }

    /*
     * Inotify
     */
    [CCode (cname = "struct inotify_event", has_type_id = false, cheader_filename = "sys/inotify.h")]
    public struct InotifyEvent {
        public int wd;
        public uint32 mask;
        public uint32 cookie;
        public uint32 len;
        public string name;
    }

    [Flags, CCode (cname = "int", cprefix = "IN_", has_type_id = false, cheader_filename = "sys/inotify.h")]

    public enum InotifyFlags {
        CLOEXEC,
        NONBLOCK
    }

    [Flags, CCode (cname = "int", cprefix = "IN_", has_type_id = false, cheader_filename = "sys/inotify.h")]
    public enum InotifyMaskFlags {
        ACCESS,
        ATTRIB,
        CLOSE,
        CLOSE_WRITE,
        CLOSE_NOWRITE,
        CREATE,
        DELETE,
        DELETE_SELF,
        MODIFY,
        MOVE,
        MOVE_SELF,
        MOVED_FROM,
        MOVED_TO,
        OPEN,
        DONT_FOLLOW,
        MASK_ADD,
        ONESHOT,
        ONLYDIR,
        IGNORED,
        ISDIR,
        Q_OVERFLOW,
        UNMOUNT
    }

    [CCode (cname = "inotify_init1", cheader_filename = "sys/inotify.h")]
    public int inotify_init (InotifyFlags flags = 0);
    public int inotify_add_watch (int fd, string pathname, InotifyMaskFlags mask);
    public int inotify_rm_watch (int fd, int wd);

    /*
     * RfKill
     */
    [CCode (cname = "struct rfkill_event", has_type_id = false, cheader_filename = "linux/rfkill.h")]
    public struct RfKillEvent {
        public uint32 idx;
        public RfKillType type;
        public RfKillOp op;
        public uint8 soft;
        public uint8 hard;
    }

    [CCode (cname = "guint8", cprefix = "RFKILL_OP_", has_type_id = false, cheader_filename = "linux/rfkill.h")]
    public enum RfKillOp {
        ADD,
        DEL,
        CHANGE,
        CHANGE_ALL
    }

    [CCode (cname = "guint8", cprefix = "RFKILL_STATE_", has_type_id = false, cheader_filename = "linux/rfkill.h")]
    public enum RfKillState {
        SOFT_BLOCKED,
        UNBLOCKED,
        HARD_BLOCKED
    }

    [CCode (cname = "guint8", cprefix = "RFKILL_TYPE_", has_type_id = false, cheader_filename = "linux/rfkill.h")]
    public enum RfKillType {
        ALL,
        WLAN,
        BLUETOOTH,
        UWB,
        WIMAX,
        WWAN,
        GPS,
        FM,
        NFC
    }

    /*
     * SignalFd
     */
    [CCode (cprefix = "SFD_", has_type_id = false, cheader_filename = "sys/signalfd.h")]
    public enum SignalFdFlags {
        CLOEXEC,
        NONBLOCK
    }

    [CCode (cheader_filename = "sys/signalfd.h")]
    public int signalfd (int fd, Posix.sigset_t mask, SignalFdFlags flags = 0);

    /*
     * Misc non-posix additions
     */
    [CCode (cheader_filename = "dirent.h", has_type_id = false)]
    public enum DirEntType {
        DT_UNKNOWN,
        DT_FIFO,
        DT_CHR,
        DT_DIR,
        DT_BLK,
        DT_REG,
        DT_LNK,
        DT_SOCK,
        DT_WHT
    }

    [CCode (cheader_filename = "errno.h", feature_test_macro = "_GNU_SOURCE")]
    public const string program_invocation_name;
    [CCode (cheader_filename = "errno.h", feature_test_macro = "_GNU_SOURCE")]
    public const string program_invocation_short_name;

    [Version (deprecated_since = "vala-0.26", replacement = "Backtrace.get"), CCode (cheader_filename = "execinfo.h")]
    public int backtrace (void* buffer, int size);

    [Version (deprecated_since = "vala-0.26", replacement = "Backtrace.symbols"), CCode (cheader_filename = "execinfo.h", array_length = false)]
    public (unowned string)[]? backtrace_symbols (void* buffer, int size);

    [Version (deprecated_since = "vala-0.26", replacement = "Backtrace.symbols_fd"), CCode (cheader_filename = "execinfo.h")]
    public void backtrace_symbols_fd (void* buffer, int size, int fd);

    namespace Backtrace {
      [CCode (cname = "backtrace", cheader_filename = "execinfo.h")]
      public int @get (void*[] buffer);
      [CCode (cname = "backtrace_symbols", cheader_filename = "execinfo.h", array_length = false)]
      private (unowned string)[]? _symbols (void*[] buffer);
      [CCode (cname = "_vala_backtrace_symbols")]
      public (unowned string)[]? symbols (void*[] buffer) {
        (unowned string)[]? s = _symbols (buffer);
        s.length = buffer.length;
        return s;
      }
      [CCode (cheader_filename = "execinfo.h")]
      public void symbols_fd (void*[] buffer, int fd);
    }

    [CCode (cheader_filename = "signal.h")]
    public void psiginfo (Posix.siginfo_t pinfo, string message);

    [CCode (cheader_filename = "unistd.h", feature_test_macro = "_GNU_SOURCE")]
    public int dup3 (int oldfd, int newfd, int flags);

    [CCode (cheader_filename = "sys/types.h,unistd.h")]
    public int getgroups ([CCode (array_length_pos = 0.9)] Posix.gid_t[]? list = null);
    [CCode (cheader_filename = "unistd.h", feature_test_macro = "_GNU_SOURCE")]
    public int getresgid (out Posix.gid_t rgid, out Posix.gid_t egid, out Posix.gid_t sgid);
    [CCode (cheader_filename = "unistd.h", feature_test_macro = "_GNU_SOURCE")]
    public int getresuid (out Posix.uid_t ruid, out Posix.uid_t euid, out Posix.uid_t suid);
    [CCode (cheader_filename = "sys/types.h,grp.h,unistd.h")]
    public int setgroups ([CCode (array_length_pos = 0.9)] Posix.gid_t[] list);
    [CCode (cheader_filename = "unistd.h", feature_test_macro = "_GNU_SOURCE")]
    public int setresgid (Posix.gid_t rgid, Posix.gid_t egid, Posix.gid_t sgid);
    [CCode (cheader_filename = "unistd.h", feature_test_macro = "_GNU_SOURCE")]
    public int setresuid (Posix.uid_t ruid, Posix.uid_t euid, Posix.uid_t suid);

    [CCode (cheader_filename = "unistd.h")]
    public int sethostname (string name, size_t len);

    // additional sysconf(3) constants
    [CCode (cheader_filename = "unistd.h")]
    public const int _SC_PHYS_PAGES;
    [CCode (cheader_filename = "unistd.h")]
    public const int _SC_AVPHYS_PAGES;
    [CCode (cheader_filename = "unistd.h")]
    public const int _SC_NPROCESSORS_CONF;
    [CCode (cheader_filename = "unistd.h")]
    public const int _SC_NPROCESSORS_ONLN;

    [CCode (cheader_filename = "arpa/inet.h")]
    public int inet_aton (string cp, out Posix.InAddr addr);

    [CCode (cheader_filename = "sys/ioctl.h", sentinel = "")]
    public int ioctl (int fd, int request, ...);

    [CCode (cname = "makedev", cheader_filename = "sys/types.h")]
    public Posix.dev_t makedev (int maj, int min);
    [CCode (cname = "major", cheader_filename = "sys/types.h")]
    public int major (Posix.dev_t dev);
    [CCode (cname = "minor", cheader_filename = "sys/types.h")]
    public int minor (Posix.dev_t dev);

    [CCode (cname = "unsigned long int", cprefix = "MS_", has_type_id = false, cheader_filename = "sys/mount.h,linux/fs.h")]
    public enum MountFlags {
        RDONLY,
        NOSUID,
        NODEV,
        NOEXEC,
        SYNCHRONOUS,
        REMOUNT,
        MANDLOCK,
        DIRSYNC,
        NOATIME,
        NODIRATIME,
        BIND,
        MOVE,
        REC,
        SILENT,
        POSIXACL,
        UNBINDABLE,
        PRIVATE,
        SLAVE,
        SHARED,
        RELATIME,
        KERNMOUNT,
        I_VERSION,
        STRICTATIME,
        BORN,
        ACTIVE,
        NOUSER
    }

    [CCode (cname = "int", cprefix = "MNT_", has_type_id = false, cheader_filename = "sys/mount.h")]
    public enum UnmountFlags {
        FORCE,                /* Force unmounting.  */
        DETACH,               /* Just detach from the tree.  */
        EXPIRE                /* Mark for expiry.  */
    }

    [CCode (cheader_filename = "sys/mount.h")]
    public int mount (string source, string target, string filesystemtype, MountFlags flags = 0, string options = "");
    [CCode (cheader_filename = "sys/mount.h")]
    public int umount (string target);
    [CCode (cheader_filename = "sys/mount.h")]
    public int umount2 (string target, UnmountFlags flags);

    [CCode (cname = "struct winsize", has_type_id = false, cheader_filename = "termios.h", destroy_function = "")]
    public struct winsize {
        public ushort ws_row;
        public ushort ws_col;
        public ushort ws_xpixel;
        public ushort ws_ypixel;
    }

    [CCode (cheader_filename = "pty.h")]
    public Posix.pid_t forkpty (out int amaster,
                                [CCode (array_length=false, array_null_terminated=true)] char[] name,
                                Posix.termios? termp,
                                winsize? winp);

    [CCode (cheader_filename = "pty.h")]
    public int openpty (out int amaster,
                        out int aslave,
                        [CCode (array_length=false, array_null_terminated=true)] char[] name,
                        Posix.termios? termp,
                        winsize? winp);

    [CCode (cprefix = "RB_", has_type_id = false, cheader_filename = "unistd.h,sys/reboot.h")]
    public enum RebootCommands {
         AUTOBOOT,
         HALT_SYSTEM,
         ENABLE_CAD,
         DISABLE_CAD,
         POWER_OFF
    }

    [CCode (cheader_filename = "unistd.h,sys/reboot.h")]
    public int reboot (RebootCommands cmd);

    [CCode (cprefix = "CLONE_", has_type_id = false, cheader_filename = "sched.h")]
    public enum CloneFlags {
        FILES,
        FS,
        NEWNS
    }

    [CCode (cheader_filename = "sched.h")]
    public int unshare (CloneFlags flags);

    [CCode (cheader_filename = "sys/time.h")]
    public int adjtime (Posix.timeval delta, Posix.timeval? olddelta = null);

    // adjtimex(2)
    [CCode (cprefix = "ADJ_", has_type_id = false, cheader_filename = "sys/timex.h")]
    public enum AdjustModes {
        OFFSET,
        FREQUENCY,
        MAXERROR,
        ESTERROR,
        STATUS,
        TIMECONST,
        TICK,
        OFFSET_SINGLESHOT
    }

    [CCode (cheader_filename = "sys/timex.h")]
    public const int TIME_OK;
    [CCode (cheader_filename = "sys/timex.h")]
    public const int TIME_INS;
    [CCode (cheader_filename = "sys/timex.h")]
    public const int TIME_DEL;
    [CCode (cheader_filename = "sys/timex.h")]
    public const int TIME_OOP;
    [CCode (cheader_filename = "sys/timex.h")]
    public const int TIME_WAIT;
    [CCode (cheader_filename = "sys/timex.h")]
    public const int TIME_BAD;

    // adjtimex(2)
    [CCode (cname = "struct timex", has_type_id = false, cheader_filename = "sys/timex.h")]
    public struct timex {
        public AdjustModes modes;   /* mode selector */
        public long offset;         /* time offset (usec) */
        public long freq;           /* frequency offset (scaled ppm) */
        public long maxerror;       /* maximum error (usec) */
        public long esterror;       /* estimated error (usec) */
        public int status;          /* clock command/status */
        public long constant;       /* pll time constant */
        public long precision;      /* clock precision (usec) (read-only) */
        public long tolerance;      /* clock frequency tolerance (ppm) (read-only) */
        public Posix.timeval time;  /* current time (read-only) */
        public long tick;           /* usecs between clock ticks */
    }

    [CCode (cheader_filename = "sys/timex.h")]
    public int adjtimex (Linux.timex buf);

    [CCode (cheader_filename = "time.h")]
    public time_t timegm (GLib.Time t);

    [CCode (cheader_filename = "time.h")]
    public const Posix.clockid_t CLOCK_MONOTONIC_RAW;

    [CCode (cheader_filename = "utmp.h")]
    public int login_tty (int fd);

    // emulate gettid(2) for which no glib wrapper exists via syscall
    public Posix.pid_t gettid() {
        return (Posix.pid_t) syscall( SysCall.gettid );
    }

    // syscall(2)
    [CCode (cprefix = "SYS_", has_type_id = false, cname = "int")]
    public enum SysCall {
        gettid
    }

    [CCode (cname = "syscall", cheader_filename = "unistd.h,sys/syscall.h")]
    public int syscall (int number, ...);

    // mremap(2)
    [CCode (cprefix = "MREMAP_", has_type_id = false, cheader_filename = "sys/mman.h")]
    public enum MremapFlags {
        MAYMOVE,
        FIXED
    }

    [CCode (cheader_filename = "sys/mman.h")]
    public void *mremap (void *old_address, size_t old_size, size_t new_size, MremapFlags flags);

    /*
     * Network
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Network {

        // interface consts, structs, and methods
        [CCode (cname = "IFNAMSIZ", cheader_filename = "sys/socket.h,linux/if.h")]
        public const int INTERFACE_NAME_SIZE;

        [CCode (cheader_filename = "net/if.h")]
        public uint if_nametoindex (string ifname);
        [CCode (cheader_filename = "net/if.h")]
        public unowned string if_indextoname (uint ifindex, string ifname);
        [CCode (cheader_filename = "net/if.h")]
        public IfNameindex if_nameindex ();

        [CCode (cname = "int", cprefix = "IFF_", has_type_id = false, cheader_filename = "sys/socket.h,linux/if.h")]
        public enum IfFlag {
            UP,
            BROADCAST,
            DEBUG,
            LOOPBACK,
            POINTOPOINT,
            NOTRAILERS,
            RUNNING,
            NOARP,
            PROMISC,
            ALLMULTI,
            MASTER,
            SLAVE,
            PORTSEL,
            AUTOMEDIA,
            DYNAMIC
        }

        [CCode (cname = "struct if_nameindex", has_type_id = false, cheader_filename = "sys/socket.h,linux/if.h", destroy_function = "if_freenameindex")]
        public struct IfNameindex {
            public uint if_index;
            public string if_name;
        }

        [CCode (cname = "struct ifmap", has_type_id = false, cheader_filename = "sys/socket.h,linux/if.h", destroy_function = "")]
        public struct IfMap {
            public ulong mem_start;
            public ulong mem_end;
            public short base_addr;
            public uchar irq;
            public uchar dma;
            public uchar port;
        }

        [CCode (cname = "struct ifreq", has_type_id = false, cheader_filename = "netinet/in.h,linux/if.h", destroy_function = "")]
        public struct IfReq {
            [CCode (array_length = false)]
            public char[] ifr_name;
            public Posix.SockAddr ifr_addr;
            public Posix.SockAddr ifr_dstaddr;
            public Posix.SockAddr ifr_broadaddr;
            public Posix.SockAddr ifr_netmask;
            public Posix.SockAddr ifr_hwaddr;
            public short ifr_flags;
            public int ifr_metric;
            public int ifr_mtu;
            public IfMap ifr_map;
            public char[] ifr_slave;
            public string ifr_data;
            public int ifr_ifindex;
            public int ifr_bandwidth;
            public int ifr_qlen;
            public char[] ifr_newname;
        }

        [CCode (cname = "struct ifconf", has_type_id = false, cheader_filename = "sys/socket.h,linux/if.h", destroy_function = "")]
        public struct IfConf {
            public int ifc_len;
            public string ifc_buf;
            public IfReq ifc_req;
        }

        [CCode (cname = "struct ifaddrmsg", has_type_id = false, cheader_filename = "linux/if_addr.h", destroy_function = "")]
        public struct IfAddrMsg {
            public uint8 ifa_family;
            public uint8 ifa_prefixlen;
            public uint8 ifa_flags;
            public uint8 ifa_scope;
            public uint32 ifa_index;
        }

        [Compact, CCode (cname = "struct ifaddrs", cheader_filename = "sys/types.h,ifaddrs.h", free_function = "freeifaddrs", has_type_id = false)]
        public class IfAddrs {
                public unowned IfAddrs? ifa_next;
                public string ifa_name;
                public uint ifa_flags;
                public Posix.SockAddr? ifa_addr;
                public Posix.SockAddr? ifa_netmask;
                [CCode (cname = "ifa_ifu.ifu_broadaddr")]
                public Posix.SockAddr? ifa_ifu_broadaddr;
                [CCode (cname = "ifa_ifu.ifu_dstaddr")]
                public Posix.SockAddr? ifa_ifu_dstaddr;
                public void* ifa_data;
        }

        [CCode (cname = "getifaddrs")]
        public static int getifaddrs (out IfAddrs ifap);

        [CCode (cprefix = "IFA_", has_type_id = false, cheader_filename = "linux/if_addr.h")]
        public enum IfAddrType {
            UNSPEC,
            ADDRESS,
            LOCAL,
            LABEL,
            BROADCAST,
            ANYCAST,
            CACHEINFO,
            MULTICAST
        }

        [CCode (cheader_filename = "linux/if_addr.h")]
        public int IFA_PAYLOAD (Linux.Netlink.NlMsgHdr nlh);
        [CCode (cheader_filename = "linux/if_addr.h")]
        public Linux.Netlink.RtAttr* IFA_RTA (Linux.Network.IfAddrMsg* msg);

        [CCode (cprefix = "ARPHRD_", has_type_id = false, cheader_filename = "linux/if_arp.h")]
        public enum IfArpHeaderType {
            NETROM,
            ETHER,
            EETHER,
            AX25,
            PRONET,
            CHAOS,
            IEEE802,
            ARCNET,
            APPLETLK,
            DLCI,
            ATM,
            METRICOM,
            IEEE1394,
            EUI64,
            INFINIBAND,
            SLIP,
            CSLIP,
            SLIP6,
            CSLIP6,
            RSRVD,
            ADAPT,
            ROSE,
            X25,
            HWX25,
            CAN,
            PPP,
            CISCO,
            HDLC,
            LAPB,
            DDCMP,
            RAWHDLC,
            TUNNEL,
            TUNNEL6,
            FRAD,
            SKIP,
            LOOPBACK,
            LOCALTLK,
            FDDI,
            BIF,
            SIT,
            IPDDP,
            IPGRE,
            PIMREG,
            HIPPI,
            ASH,
            ECONET,
            IRDA,
            FCPP,
            FCAL,
            FCPL,
            FCFABRIC,
            IEEE802_TR,
            IEEE80211,
            IEEE80211_PRISM,
            IEEE80211_RADIOTAP,
            IEEE802154,
            PHONET,
            PHONET_PIPE,
            CAIF,
            VOID,
            NONE
        }

        [CCode (cprefix = "ARPOP_", has_type_id = false, cheader_filename = "linux/if_arp.h")]
        public enum IfArpOpcode {
            REQUEST,
            REPLY,
            RREQUEST,
            RREPLY,
            InREQUEST,
            InREPLY,
            ARPOP_NAK
        }

        // route consts, structs, and methods
        [CCode (cname = "struct rtentry", has_type_id = false, cheader_filename = "net/route.h", destroy_function = "")]
        public struct RtEntry {
            public Posix.SockAddr rt_dst;
            public Posix.SockAddr rt_gateway;
            public Posix.SockAddr rt_genmask;
            public RtFlag rt_flags;
            public short rt_metric;
            public string rt_dev;
            public ulong rt_mtu;
            public ulong rt_window;
            public ushort rt_irtt;
        }

        [CCode (cname = "ushort", cprefix = "RTF_", has_type_id = false, cheader_filename = "net/route.h")]
        public enum RtFlag {
            UP,
            GATEWAY,
            HOST,
            REINSTATE,
            DYNAMIC,
            MODIFIED,
            MTU,
            WINDOW,
            IRTT,
            REJECT,
            STATIC,
            XRESOLVE,
            NOFORWARD,
            THROW,
            NOPMTUDISC
        }

        /* ioctls */
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCADDRT;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCDELRT;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCRTMSG;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFNAME;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFLINK;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFCONF;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFFLAGS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFFLAGS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFDSTADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFDSTADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFBRDADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFBRDADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFNETMASK;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFNETMASK;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFMETRIC;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFMETRIC;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFMEM;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFMEM;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFMTU;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFMTU;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFNAME;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFHWADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFENCAP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFENCAP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFHWADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFSLAVE;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFSLAVE;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCADDMULTI;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCDELMULTI;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFINDEX;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFPFLAGS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFPFLAGS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCDIFADDR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFHWBROADCAST;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFCOUNT;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFBR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFBR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFTXQLEN;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFTXQLEN;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCDARP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGARP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSARP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCDRARP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGRARP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSRARP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCGIFMAP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCSIFMAP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCADDDLCI;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int SIOCDELDLCI;
    }

    /*
     * Input subsystem
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Input {

        /*
         * subsystem structures
         */

        [CCode (cname = "struct input_event", has_type_id = false, cheader_filename = "linux/input.h")]
        public struct Event {
            public Posix.timeval time;
            public uint16 type;
            public uint16 code;
            public int32 value;
        }

        [CCode (cname = "struct input_id", has_type_id = false, cheader_filename = "linux/input.h")]
        public struct Id {
            public uint16 bustype;
            public uint16 vendor;
            public uint16 product;
            public uint16 version;
        }

        [CCode (cname = "struct input_absinfo", has_type_id = false, cheader_filename = "linux/input.h")]
        public struct AbsInfo {
            public int32 value;
            public int32 minimum;
            public int32 maximum;
            public int32 fuzz;
            public int32 flat;
        }

        /*
         * ioctls
         */

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGVERSION;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGID;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGREP;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCSREP;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGKEYCODE;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCSKEYCODE;

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGNAME( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGPHYS( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGUNIQ( uint len );

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGKEY( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGLED( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGSND( uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGSW( uint len );

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGBIT( uint ev, uint len );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCGABS( uint abs );
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public int EVIOCSABS( uint abs );

        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCSFF;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCRMFF;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGEFFECTS;
        [CCode (cheader_filename = "linux/input.h,sys/ioctl.h")]
        public const int EVIOCGRAB;

        /*
         * event types
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_SYN;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_KEY;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_REL;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_ABS;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_MSC;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_SW;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_LED;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_SND;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_REP;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_FF;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_PWR;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_FF_STATUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const uint16 EV_MAX;

        /*
         * synchronization events
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int SYN_REPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SYN_CONFIG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SYN_MT_REPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SYN_DROPPED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SYN_MAX;

        /*
         * keys, switches, buttons, etc.
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RESERVED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ESC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_0;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MINUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EQUAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BACKSPACE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TAB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_Q;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_W;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_E;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_R;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_T;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_U;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_I;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_O;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_P;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTBRACE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTBRACE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ENTER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTCTRL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_A;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_S;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_D;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_G;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_H;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_J;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_K;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_L;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SEMICOLON;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_APOSTROPHE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GRAVE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTSHIFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BACKSLASH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_Z;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_C;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_V;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_B;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_N;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_M;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COMMA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DOT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SLASH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTSHIFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPASTERISK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTALT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SPACE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAPSLOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F10;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMLOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCROLLLOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPMINUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPPLUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KP0;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPDOT;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZENKAKUHANKAKU;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_102ND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F11;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F12;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KATAKANA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HIRAGANA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HENKAN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KATAKANAHIRAGANA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MUHENKAN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPJPCOMMA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPENTER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTCTRL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPSLASH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SYSRQ;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTALT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LINEFEED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HOME;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAGEUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_END;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAGEDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DELETE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MACRO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MUTE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VOLUMEDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VOLUMEUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_POWER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPEQUAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPPLUSMINUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAUSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCALE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPCOMMA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HANGEUL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HANGUEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HANJA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_YEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFTMETA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHTMETA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COMPOSE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_STOP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AGAIN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROPS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UNDO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FRONT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COPY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_OPEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PASTE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FIND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CUT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HELP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MENU;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CALC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SETUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SLEEP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WAKEUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FILE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SENDFILE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DELETEFILE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_XFER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROG1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROG2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WWW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MSDOS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COFFEE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCREENLOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DIRECTION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CYCLEWINDOWS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BOOKMARKS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_COMPUTER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BACK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FORWARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CLOSECD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EJECTCD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EJECTCLOSECD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEXTSONG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PLAYPAUSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PREVIOUSSONG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_STOPCD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RECORD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_REWIND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PHONE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ISO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CONFIG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HOMEPAGE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_REFRESH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EXIT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MOVE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EDIT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCROLLUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCROLLDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPLEFTPAREN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KPRIGHTPAREN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_REDO;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F13;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F14;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F15;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F16;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F17;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F18;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F19;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F20;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F21;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F22;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F23;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_F24;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PLAYCD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAUSECD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROG3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROG4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DASHBOARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SUSPEND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CLOSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PLAY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FASTFORWARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BASSBOOST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PRINT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_HP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SOUND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_QUESTION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EMAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CHAT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SEARCH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CONNECT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FINANCE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SHOP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ALTERASE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CANCEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESSDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESSUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MEDIA;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SWITCHVIDEOMODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDILLUMTOGGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDILLUMDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDILLUMUP;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SEND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_REPLY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FORWARDMAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SAVE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DOCUMENTS;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BATTERY;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BLUETOOTH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WLAN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UWB;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UNKNOWN;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VIDEO_NEXT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VIDEO_PREV;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESS_CYCLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESS_AUTO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESS_ZERO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DISPLAY_OFF;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WWAN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WIMAX;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RFKILL;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MICMUTE;

        /* Code 255 is reserved for special needs of AT keyboard driver */

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_MISC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_0;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_9;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_MOUSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_LEFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_RIGHT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_MIDDLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_SIDE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_EXTRA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_FORWARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BACK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TASK;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_JOYSTICK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_THUMB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_THUMB2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOP2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_PINKIE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_BASE6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_DEAD;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_GAMEPAD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_A;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_B;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_C;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_Z;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TL2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TR2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_SELECT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_START;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_MODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_THUMBL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_THUMBR;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_DIGI;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_PEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_RUBBER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_BRUSH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_PENCIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_AIRBRUSH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_FINGER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_MOUSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_LENS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_QUINTTAP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOUCH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_STYLUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_STYLUS2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_DOUBLETAP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_TRIPLETAP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TOOL_QUADTAP;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_WHEEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_GEAR_DOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_GEAR_UP;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_OK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SELECT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GOTO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CLEAR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_POWER2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_OPTION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_INFO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TIME;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VENDOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ARCHIVE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PROGRAM;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CHANNEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FAVORITES;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EPG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PVR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MHP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LANGUAGE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TITLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SUBTITLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ANGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZOOM;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KEYBOARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCREEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TV;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TV2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VCR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VCR2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SAT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SAT2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TAPE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RADIO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TUNER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PLAYER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TEXT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DVD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AUX;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MP3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AUDIO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VIDEO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DIRECTORY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LIST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MEMO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CALENDAR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GREEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_YELLOW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BLUE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CHANNELUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CHANNELDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FIRST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LAST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEXT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RESTART;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SLOW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SHUFFLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BREAK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PREVIOUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DIGITS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TEEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TWEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VIDEOPHONE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GAMES;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZOOMIN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZOOMOUT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ZOOMRESET;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WORDPROCESSOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EDITOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SPREADSHEET;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_GRAPHICSEDITOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PRESENTATION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DATABASE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEWS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VOICEMAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ADDRESSBOOK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MESSENGER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DISPLAYTOGGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESS_TOGGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SPELLCHECK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LOGOFF;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DOLLAR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_EURO;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FRAMEBACK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FRAMEFORWARD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CONTEXT_MENU;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MEDIA_REPEAT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_10CHANNELSUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_10CHANNELSDOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_IMAGES;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DEL_EOL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DEL_EOS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_INS_LINE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DEL_LINE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_ESC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F10;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F11;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F12;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_D;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_E;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_F;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_S;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FN_B;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRL_DOT10;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_0;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_STAR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_POUND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_A;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_B;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_C;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_D;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA_FOCUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_WPS_BUTTON;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TOUCHPAD_TOGGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TOUCHPAD_ON;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TOUCHPAD_OFF;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA_ZOOMIN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA_ZOOMOUT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA_UP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA_DOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA_LEFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CAMERA_RIGHT;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ATTENDANT_ON;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ATTENDANT_OFF;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ATTENDANT_TOGGLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LIGHTS_TOGGLE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_DPAD_UP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_DPAD_DOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_DPAD_LEFT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_DPAD_RIGHT;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ALS_TOGGLE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BUTTONCONFIG;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_TASKMANAGER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_JOURNAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_CONTROLPANEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_APPSELECT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SCREENSAVER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VOICECOMMAND;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESS_MIN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_BRIGHTNESS_MAX;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDINPUTASSIST_PREV;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDINPUTASSIST_NEXT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDINPUTASSIST_PREVGROUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDINPUTASSIST_NEXTGROUP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDINPUTASSIST_ACCEPT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_KBDINPUTASSIST_CANCEL;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHT_UP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_RIGHT_DOWN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFT_UP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_LEFT_DOWN;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_ROOT_MENU;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MEDIA_TOP_MENU;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_11;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NUMERIC_12;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_AUDIO_DESC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_3D_MODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_NEXT_FAVORITE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_STOP_RECORD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_PAUSE_RECORD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_VOD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_UNMUTE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_FASTREVERSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_SLOWREVERSE;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_DATA;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY1;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY2;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY3;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY4;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY5;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY6;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY7;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY8;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY9;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY10;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY11;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY12;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY13;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY14;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY15;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY16;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY17;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY18;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY19;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY20;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY21;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY22;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY23;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY24;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY25;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY26;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY27;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY28;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY29;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY30;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY31;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY32;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY33;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY34;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY35;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY36;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY37;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY38;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY39;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BTN_TRIGGER_HAPPY40;

        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MIN_INTERESTING;
        [CCode (cheader_filename = "linux/input.h")]
        public const int KEY_MAX;

        /*
        * Relative axes
        */

        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_Z;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_RX;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_RY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_RZ;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_HWHEEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_DIAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_WHEEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_MISC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REL_MAX;

        /*
         * Absolute axes
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_Z;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_RX;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_RY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_RZ;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_THROTTLE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_RUDDER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_WHEEL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_GAS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_BRAKE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT0X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT0Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT1X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT1Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT2X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT2Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT3X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_HAT3Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_PRESSURE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_DISTANCE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_TILT_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_TILT_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_TOOL_WIDTH;

        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_VOLUME;

        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MISC;

        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_SLOT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_TOUCH_MAJOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_TOUCH_MINOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_WIDTH_MAJOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_WIDTH_MINOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_ORIENTATION;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_POSITION_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_POSITION_Y;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_TOOL_TYPE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_BLOB_ID;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_TRACKING_ID;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_PRESSURE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_DISTANCE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_TOOL_X;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MT_TOOL_Y;

        [CCode (cheader_filename = "linux/input.h")]
        public const int ABS_MAX;

        /*
         * Switch events
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_LID;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_TABLET_MODE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_HEADPHONE_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_RFKILL_ALL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_RADIO;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_MICROPHONE_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_DOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_LINEOUT_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_JACK_PHYSICAL_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_VIDEOOUT_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_CAMERA_LENS_COVER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_KEYPAD_SLIDE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_FRONT_PROXIMITY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_ROTATE_LOCK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_LINEIN_INSERT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_MUTE_DEVICE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_PEN_INSERTED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SW_MAX;

        /*
         * Misc events
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_SERIAL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_PULSELED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_GESTURE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_RAW;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_SCAN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_TIMESTAMP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MSC_MAX;

        /*
         * LEDs
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_NUML;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_CAPSL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_SCROLLL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_COMPOSE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_KANA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_SLEEP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_SUSPEND;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_MUTE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_MISC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_MAIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_CHARGING;
        [CCode (cheader_filename = "linux/input.h")]
        public const int LED_MAX;

        /*
         * Autorepeat values
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int REP_DELAY;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REP_PERIOD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int REP_MAX;

        /*
         * Sounds
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int SND_CLICK;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SND_BELL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SND_TONE;
        [CCode (cheader_filename = "linux/input.h")]
        public const int SND_MAX;

        /*
         * IDs.
         */

        [CCode (cheader_filename = "linux/input.h")]
        public const int ID_BUS;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ID_VENDOR;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ID_PRODUCT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int ID_VERSION;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_PCI;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_ISAPNP;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_USB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_HIL;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_BLUETOOTH;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_VIRTUAL;

        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_ISA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_I8042;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_XTKBD;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_RS232;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_GAMEPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_PARPORT;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_AMIGA;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_ADB;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_I2C;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_HOST;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_GSC;
        [CCode (cheader_filename = "linux/input.h")]
        public const int BUS_ATARI;

        /* MT_TOOL types */
        [CCode (cheader_filename = "linux/input.h")]
        public const int MT_TOOL_FINGER;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MT_TOOL_PEN;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MT_TOOL_PALM;
        [CCode (cheader_filename = "linux/input.h")]
        public const int MT_TOOL_MAX;

        /* Values describing the status of a force-feedback effect */
        [CCode (cheader_filename = "linux/input.h")]
        public const int FF_STATUS_STOPPED;
        [CCode (cheader_filename = "linux/input.h")]
        public const int FF_STATUS_PLAYING;
        [CCode (cheader_filename = "linux/input.h")]
        public const int FF_STATUS_MAX;
    }

    /*
     * Netlink subsystem
     */
    [CCode (cprefix = "", lower_case_cprefix = "", cheader_filename = "linux/netlink.h")]
    namespace Netlink {

        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ROUTE;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_UNUSED;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_USERSOCK;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_FIREWALL;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_INET_DIAG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_NFLOG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_XFRM;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_SELINUX;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ISCSI;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_AUDIT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_FIB_LOOKUP;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_CONNECTOR;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_NETFILTER;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_IP6_FW;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_DNRTMSG;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_KOBJECT_UEVENT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_GENERIC;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_SCSITRANSPORT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ECRYPTFS;

        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_ADD_MEMBERSHIP;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_DROP_MEMBERSHIP;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_PKTINFO;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_BROADCAST_ERROR;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NETLINK_NO_ENOBUFS;

        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_REQUEST;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_MULTI;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_ACK;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_ECHO;

        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_ROOT;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_MATCH;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_ATOMIC;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_DUMP;

        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_REPLACE;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_EXCL;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_CREATE;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLM_F_APPEND;

        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLMSG_ALIGNTO;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLMSG_NOOP;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLMSG_ERROR;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLMSG_DONE;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLMSG_OVERRUN;
        [CCode (cheader_filename = "linux/netlink.h")]
        public const int NLMSG_MIN_TYPE;

        /* netlink action macros, we bind them as functions for convenience */
        [CCode (cheader_filename = "linux/netlink.h")]
        public void NLMSG_ALIGN (int len);
        [CCode (cheader_filename = "linux/netlink.h")]
        public int NLMSG_HDRLEN ();
        [CCode (cheader_filename = "linux/netlink.h")]
        public int NLMSG_LENGTH (int len);
        [CCode (cheader_filename = "linux/netlink.h")]
        public void NLMSG_SPACE (int len);
        [CCode (cheader_filename = "linux/netlink.h")]
        public void* NLMSG_DATA (NlMsgHdr nlh);
        [CCode (cheader_filename = "linux/netlink.h")]
        public unowned NlMsgHdr NLMSG_NEXT (NlMsgHdr nlh, int len);
        [CCode (cheader_filename = "linux/netlink.h")]
        public bool NLMSG_OK (NlMsgHdr nlh, int len);
        [CCode (cheader_filename = "linux/netlink.h")]
        public int NLMSG_PAYLOAD (NlMsgHdr nlh, int len);

        // netlink socket, can be used instead of sockaddr
        [CCode (cname = "struct sockaddr_nl", has_type_id = false, cheader_filename = "linux/netlink.h", destroy_function = "")]
        public struct SockAddrNl {
            public int nl_family;
            public ushort nl_pad;
            public uint32 nl_pid;
            public uint32 nl_groups;
        }

        // netlink message header
        [CCode (cname = "struct nlmsghdr", has_type_id = false, cheader_filename = "linux/netlink.h", destroy_function = "")]
        public struct NlMsgHdr {
            public uint32 nlmsg_len;
            public uint16 nlmsg_type;
            public uint16 nlmsg_flags;
            public uint32 nlmsg_seq;
            public uint32 nlmsg_pid;
        }

        // netlink error message
        [CCode (cname = "struct nlmsgerr", has_type_id = false, cheader_filename = "linux/netlink.h", destroy_function = "")]
        public struct NlMsgErr {
            public int error;
            public NlMsgHdr msg;
        }

        // rtnetlink multicast groups ( userland compatibility values )
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_LINK;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_NOTIFY;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_NEIGH;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_TC;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV4_IFADDR;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV4_MROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV4_ROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV4_RULE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV6_IFADDR;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV6_MROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV6_ROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV6_IFINFO;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_DECnet_IFADDR;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_DECnet_ROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTMGRP_IPV6_PREFIX;

        // rtnetlink multicast groups ( 1 << group )
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_NONE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_LINK;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_NOTIFY;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_NEIGH;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_TC;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV4_IFADDR;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV4_MROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV4_ROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV4_RULE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV6_IFADDR;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV6_MROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV6_ROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV6_IFINFO;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_DECnet_IFADDR;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_NOP2;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_DECnet_ROUTE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_DECnet_RULE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_NOP4;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV6_PREFIX;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_IPV6_RULE;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_ND_USEROPT;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_PHONET_IFADDR;
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public const int RTNLGRP_PHONET_ROUTE;

        /* rtnetlink action macros, we bind them as functions for convenience */
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public void RTA_ALIGN (int len);
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public int RTA_HDRLEN ();
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public int RTA_LENGTH (int len);
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public void RTA_SPACE (int len);
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public void* RTA_DATA (RtAttr* rta);
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public RtAttr* RTA_NEXT (RtAttr* rta, int len);
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public bool RTA_OK (RtAttr* rta, int len);
        [CCode (cheader_filename = "linux/rtnetlink.h")]
        public void* RTA_PAYLOAD (RtAttr* rta, int len);

        /*
        [CCode (cheader_filename = "sys/socket.h", sentinel = "")]
        public int bind (int sockfd, SockAddrNl addr, ulong length);
        */

        // rtnetlink info message
        [CCode (cname = "struct ifinfomsg", has_type_id = false, cheader_filename = "linux/rtnetlink.h", destroy_function = "")]
        public struct IfInfoMsg {
            public uchar ifi_family;
            public uchar __ifi_pad;
            public ushort ifi_type;
            public int ifi_index;
            public uint32 ifi_flags;
            public uint32 ifi_change;
        }

        // rtnetlink attribute
        [CCode (cname = "struct rtattr", has_type_id = false, cheader_filename = "linux/rtnetlink.h", destroy_function = "")]
        public struct RtAttr {
            public ushort rta_len;
            public ushort rta_type;
        }

        // rtnetlink routing / discovery messages
        [CCode (cprefix = "RTM_", has_type_id = false, cheader_filename = "linux/rtnetlink.h")]
        public enum RtMessageType {
            NEWLINK,
            DELLINK,
            GETLINK,
            SETLINK,
            NEWADDR,
            DELADDR,
            GETADDR,
            NEWROUTE,
            DELROUTE,
            GETROUTE,
            NEWNEIGH,
            DELNEIGH,
            GETNEIGH,
            NEWRULE,
            DELRULE,
            GETRULE,
            NEWQDISC,
            DELQDISC,
            GETQDISC,
            NEWTCLASS,
            DELTCLASS,
            GETTCLASS,
            NEWTFILTER,
            DELTFILTER,
            GETTFILTER,
            NEWACTION,
            DELACTION,
            GETACTION,
            NEWPREFIX,
            GETMULTICAST,
            GETANYCAST,
            NEWNEIGHTBL,
            GETNEIGHTBL,
            SETNEIGHTBL,
        }
    }

    /*
     * Real time clock subsystem
     */

    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Rtc {

        [CCode (cname = "struct rtc_time", cheader_filename = "linux/rtc.h", has_type_id = false)]
        public struct Time {
            public int tm_sec;
            public int tm_min;
            public int tm_hour;
            public int tm_mday;
            public int tm_mon;
            public int tm_year;
            public int tm_wday;
            public int tm_yday;
            public int tm_isdst;
        }

        [CCode (cname = "struct rtc_wkalrm", has_type_id = false, cheader_filename = "linux/rtc.h")]
        public struct WakeAlarm {
            public char enabled;
            public char pending;
            public Linux.Rtc.Time time;
        }

        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_RD_TIME;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_SET_TIME;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_WKALM_RD;
        [CCode (cheader_filename = "linux/rtc.h,sys/ioctl.h")]
        public const int RTC_WKALM_SET;
    }

    /*
     * Socket extensions (non-posix)
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Socket {
        [CCode (cheader_filename = "sys/socket.h")]
        public const int AF_NETLINK;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int AF_PHONET;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int AF_UNSPEC;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SOCK_NONBLOCK;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SOCK_CLOEXEC;

        [CCode (cname = "struct ucred", has_type_id = false, cheader_filename = "linux/socket.h", destroy_function = "")]
        public struct ucred {
            public uint32 pid;
            public uint32 uid;
            public uint32 gid;
        }

        /* setsockopt(2) level constants */
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_IP;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_TCP;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_UDP;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_IPV6;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_ICMPV6;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_SCTP;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_UDPLITE;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_RAW;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_IPX;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_AX25;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_ATALK;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_NETROM;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_ROSE;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_DECNET;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_X25;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_PACKET;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_ATM;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_AAL;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_IRDA;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_NETBEUI;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_LLC;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_DCCP;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_NETLINK;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_TIPC;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_RXRPC;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_PPPOL2TP;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_BLUETOOTH;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_PNPIPE;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_RDS;
        [CCode (cheader_filename = "linux/socket.h")]
        public const int SOL_IUCV;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SOL_SOCKET;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_DEBUG;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_REUSEADDR;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_TYPE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_ERROR;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_DONTROUTE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_BROADCAST;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_SNDBUF;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_RCVBUF;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_SNDBUFFORCE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_RCVBUFFORCE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_KEEPALIVE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_OOBINLINE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_NO_CHECK;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_PRIORITY;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_LINGER;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_BSDCOMPAT;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_REUSEPORT;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_PASSCRED;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_PEERCRED;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_RCVLOWAT;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_SNDLOWAT;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_RCVTIMEO;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_SNDTIMEO;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_SECURITY_AUTHENTICATION;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_SECURITY_ENCRYPTION_TRANSPORT;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_SECURITY_ENCRYPTION_NETWORK;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_BINDTODEVICE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_ATTACH_FILTER;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_DETACH_FILTER;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_GET_FILTER;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_PEERNAME;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_TIMESTAMP;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SCM_TIMESTAMP;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_ACCEPTCONN;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_PEERSEC;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_PASSSEC;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_TIMESTAMPNS;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SCM_TIMESTAMPNS;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_MARK;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_TIMESTAMPING;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SCM_TIMESTAMPING;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_PROTOCOL;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_DOMAIN;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_RXQ_OVFL;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_WIFI_STATUS;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SCM_WIFI_STATUS;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_PEEK_OFF;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_NOFCS;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_LOCK_FILTER;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_SELECT_ERR_QUEUE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_BUSY_POLL;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_MAX_PACING_RATE;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_BPF_EXTENSIONS;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_INCOMING_CPU;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_ATTACH_BPF;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_DETACH_BPF;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_ATTACH_REUSEPORT_CBPF;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_ATTACH_REUSEPORT_EBPF;
        [CCode (cheader_filename = "sys/socket.h")]
        public const int SO_CNX_ADVICE;
    }

    /*
     * SPI (Serial Peripheral Interface)
     */

    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Spi {

        [CCode (cname = "spi_ioc_transfer", has_type_id = false, cheader_filename = "linux/spi/spidev.h")]
        public struct IocTransfer {
            public uint64  tx_buf;
            public uint64  rx_buf;

            public uint32  len;
            public uint32  speed_hz;

            public uint16  delay_usecs;
            public uint8   bits_per_word;
            public uint8   cs_change;
            public uint32  pad;
        }

        /* mode constants */
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_CPHA;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_CPOL;

        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_MODE_0;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_MODE_1;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_MODE_2;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_MODE_3;

        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_CS_HIGH;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_LSB_FIRST;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_3WIRE;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_LOOP;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_NO_CS;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_READY;

        /* size */
        public int SPI_MSGSIZE(int N);
        public int SPI_IOC_MESSAGE(int N);

        /* ioctls */
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_IOC_RD_MODE;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_IOC_WR_MODE;

        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_IOC_RD_LSB_FIRST;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_IOC_WR_LSB_FIRST;

        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_IOC_RD_BITS_PER_WORD;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_IOC_WR_BITS_PER_WORD;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_IOC_RD_MAX_SPEED_HZ;
        [CCode (cheader_filename = "linux/spi/spidev.h")]
        public const int SPI_IOC_WR_MAX_SPEED_HZ;
    }

    /*
     * Terminal input/output
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace Termios {

        /*
         * non-posix functions
         */
        [CCode (cheader_filename = "stdlib.h")]
        public int ptsname_r (int fd, char[] buf);

        /*
         * non-posix flags
         */
        [CCode (cheader_filename = "termios.h")]
        public const int OLCUC;

        /*
         * non-posix constants
         */

        // flow control
        [CCode (cheader_filename = "termios.h")]
        public const int CRTSCTS;
        // v24 modem lines
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_LE;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_DTR;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_RTS;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_ST;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_SR;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_CTS;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_CARM;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_RNG;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_DSR;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_OUT1;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_OUT2;
        [CCode (cheader_filename = "termios.h")]
        public const int TIOCM_LOOP;
        // baud rates
        [CCode (cheader_filename = "termios.h")]
        public const int B460800;
        [CCode (cheader_filename = "termios.h")]
        public const int B500000;
        [CCode (cheader_filename = "termios.h")]
        public const int B576000;
        [CCode (cheader_filename = "termios.h")]
        public const int B921600;
        [CCode (cheader_filename = "termios.h")]
        public const int B1000000;
        [CCode (cheader_filename = "termios.h")]
        public const int B1152000;
        [CCode (cheader_filename = "termios.h")]
        public const int B1500000;
        [CCode (cheader_filename = "termios.h")]
        public const int B2000000;
        [CCode (cheader_filename = "termios.h")]
        public const int B2500000;
        [CCode (cheader_filename = "termios.h")]
        public const int B3000000;
        [CCode (cheader_filename = "termios.h")]
        public const int B3500000;
        [CCode (cheader_filename = "termios.h")]
        public const int B4000000;
        // misc
        [CCode (cheader_filename = "termios.h")]
        public const Posix.tcflag_t CBAUD;
        [CCode (cheader_filename = "termios.h")]
        public const Posix.tcflag_t CBAUDEX;
        [CCode (cheader_filename = "termios.h")]
        public const Posix.tcflag_t ECHOCTL;
        [CCode (cheader_filename = "termios.h")]
        public const Posix.tcflag_t ECHOPRT;
        [CCode (cheader_filename = "termios.h")]
        public const Posix.tcflag_t ECHOKE;

        /*
         * ioctls
         */
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCGETS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETSW;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETSF;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCGETA;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETA;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETAW;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETAF;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSBRK;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCXONC;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCFLSH;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCEXCL;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCNXCL;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSCTTY;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGPGRP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSPGRP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCOUTQ;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSTI;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGWINSZ;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSWINSZ;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCMGET;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCMBIS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCMBIC;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCMSET;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGSOFTCAR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSSOFTCAR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int FIONREAD;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCINQ;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCLINUX;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCCONS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGSERIAL;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSSERIAL;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCPKT;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int FIONBIO;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCNOTTY;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSETD;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGETD;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSBRKP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSBRK;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCCBRK;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGSID;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCGETS2;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETS2;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETSW2;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETSF2;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGRS485;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSRS485;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGPTN;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSPTLCK;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCGETX;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETX;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETXF;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TCSETXW;

        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int FIONCLEX;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int FIOCLEX;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int FIOASYNC;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSERCONFIG;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSERGWILD;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSERSWILD;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGLCKTRMIOS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSLCKTRMIOS;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSERGSTRUCT;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSERGETLSR;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSERGETMULTI;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSERSETMULTI;

        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCMIWAIT;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGICOUNT;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCGHAYESESP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSHAYESESP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int FIOQSIZE;

        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCPKT_DATA;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCPKT_FLUSHREAD;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCPKT_FLUSHWRITE;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCPKT_STOP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCPKT_START;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCPKT_NOSTOP;
        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCPKT_DOSTOP;

        [CCode (cheader_filename = "sys/ioctl.h")]
        public const int TIOCSER_TEMT;
    }

    /*
     * Userspace Input
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace UserspaceInput {
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int VERSION;

        [CCode (cheader_filename = "linux/uinput.h")]
        public const int EV_UINPUT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_FF_UPLOAD;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_FF_ERASE;

        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_DEV_CREATE;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_DEV_DESTROY;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_EVBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_KEYBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_RELBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_ABSBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_MSCBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_LEDBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_SNDBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_FFBIT;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_PHYS;
        [CCode (cheader_filename = "linux/uinput.h")]
        public const int UI_SET_SWBIT;

        [CCode (cname = "struct uinput_user_dev", cheader_filename = "linux/uinput.h")]
        struct UserDevice
        {
            char name[80];
            Input.Id id;
            int ff_effects_max;
            int absmax[64];
            int absmin[64];
            int absfuzz[64];
            int absflat[64];
        }
    }

    /*
     * Virtual Terminal
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace VirtualTerminal {

        /* constants */

        [CCode (cheader_filename = "linux/vt.h")]
        public const int MIN_NR_CONSOLES;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int MAX_NR_CONSOLES;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int MAX_NR_USER_CONSOLES;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_OPENQRY;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_GETMODE;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_SETMODE;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_AUTO;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_PROCESS;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_ACKACQ;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_GETSTATE;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_SENDSIG;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_RELDISP;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_ACTIVATE;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_WAITACTIVE;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_DISALLOCATE;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_RESIZE;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_RESIZEX;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_LOCKSWITCH;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_UNLOCKSWITCH;
        [CCode (cheader_filename = "linux/vt.h")]
        public const int VT_GETHIFONTMASK;

        /* structs */

        [CCode (cname = "struct vt_mode", has_type_id = false, cheader_filename = "linux/vt.h")]
        public struct Mode {
            public char mode;
            public char waitv;
            public int16 relsig;
            public int16 acqsig;
            public int16 frsig;
        }

        [CCode (cname = "struct vt_stat", has_type_id = false, cheader_filename = "linux/vt.h")]
        public struct Stat {
            public uint16 v_active;
            public uint16 v_signal;
            public uint16 v_state;
        }

        [CCode (cname = "struct vt_sizes", has_type_id = false, cheader_filename = "linux/vt.h")]
        public struct Sizes {
            public uint16 v_rows;
            public uint16 v_cols;
            public uint16 v_scrollsize;
        }

        [CCode (cname = "struct vt_consize", has_type_id = false, cheader_filename = "linux/vt.h")]
        public struct Consize {
            public uint16 v_rows;
            public uint16 v_cols;
            public uint16 v_vlin;
            public uint16 v_clin;
            public uint16 v_vcol;
            public uint16 v_ccol;
        }
    }

    /*
     * Wireless Extensions (WEXT) Infrastructure
     */
    [CCode (cprefix = "", lower_case_cprefix = "")]
    namespace WirelessExtensions {

        [CCode (cname = "struct iw_point", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwPoint
        {
            public void *pointer;
            public uint16 length;
            public uint16 flags;
        }

        [CCode (cname = "struct iw_param", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwParam
        {
            public int32 value;
            public uint8 fixed;
            public uint8 disabled;
            public uint16 flags;
        }

        [CCode (cname = "struct iw_freq", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwFreq
        {
            public int32 m;
            public int16 e;
            public uint8 i;
            public uint8 flags;
        }

        [CCode (cname = "struct iw_quality", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwQuality
        {
            public uint8 qual;
            public uint8 level;
            public uint8 noise;
            public uint8 updated;
        }

        [CCode (cname = "struct iwreq_data", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwReqData
        {
            [CCode (array_length = false)]
            public string name;
            public IwPoint essid;
            public IwParam nwid;
            public IwFreq freq;
            public IwParam sens;
            public IwParam bitrate;
            public IwParam txpower;
            public IwParam rts;
            public IwParam frag;
            public uint32 mode;
            public IwParam retry;
            public IwPoint encoding;
            public IwParam power;
            public IwQuality qual;
            public Posix.SockAddr ap_addr;
            public Posix.SockAddr addr;
            public IwParam param;
            public IwPoint data;
        }

        [CCode (cname = "struct iwreq", has_type_id = false, cheader_filename = "linux/wireless.h", destroy_function = "")]
        public struct IwReq
        {
            [CCode (array_length = false)]
            public char[] ifr_name;
            public IwReqData u;
        }

        /* constants */
        // TBD

        /* ioctls */
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWCOMMIT;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWNAME;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWNWID;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWNWID;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWFREQ;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWFREQ;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWMODE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWMODE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWSENS;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWSENS;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWRANGE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWRANGE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWPRIV;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWPRIV;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWSTATS;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWSTATS;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWSPY;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWSPY;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWTHRSPY;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWTHRSPY;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWAP;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWAP;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWAPLIST;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWSCAN;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWSCAN;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWESSID;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWESSID;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWNICKN;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWNICKN;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWRATE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWRATE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWRTS;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWRTS;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWFRAG;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWFRAG;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWTXPOW;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWTXPOW;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWRETRY;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWRETRY;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWENCODE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWENCODE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWPOWER;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWPOWER;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWGENIE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWGENIE;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWMLME;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWAUTH;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWAUTH;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWENCODEEXT;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCGIWENCODEEXT;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCSIWPMKSA;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCIWFIRSTPRIV;
        [CCode (cheader_filename = "linux/wireless.h")]
        public const int SIOCIWLASTPRIV;
    }

}
