/* v4l2.vapi
 *
 * Copyright (C) 2008  Matias De la Puente
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
 * Author:
 * 	Matias De la Puente <mfpuente.ar@gmail.com>
 */

[CCode (lower_case_cprefix="", cprefix="", cheader_filename="linux/videodev2.h")]
namespace V4l2
{
	[CCode (cprefix="V4L2_FIELD_", has_type_id = false)]
	public enum Field
	{
		ANY,
		NONE,
		TOP,
		BOTTOM,
		INTERLACED,
		SEQ_TB,
		SEQ_BT,
		ALTERNATE,
		INTERLACED_TB,
		INTERLACED_BT
	}

	[CCode (cname="V4L2_FIELD_HAS_TOP")]
	public bool field_has_top (uint32 field);
	[CCode (cname="V4L2_FIELD_HAS_BOTTOM")]
	public bool field_has_bottom (uint32 field);
	[CCode (cname="V4L2_FIELD_HAS_BOTH")]
	public bool field_has_both (uint32 field);

	[CCode (cprefix="V4L2_BUF_TYPE_", has_type_id = false)]
	public enum BufferType
	{
		VIDEO_CAPTURE,
		VIDEO_OUTPUT,
		VIDEO_OVERLAY,
		VBI_CAPTURE,
		VBI_OUTPUT,
		SLICED_VBI_CAPTURE,
		SLICED_VBI_OUTPUT,
		VIDEO_OUTPUT_OVERLAY,
		PRIVATE
	}

	[CCode (cprefix="V4L2_CTRL_TYPE_", has_type_id = false)]
	public enum ControlType
	{
		INTEGER,
		BOOLEAN,
		MENU,
		BUTTON,
		INTEGER64,
		CTRL_CLASS
	}

	[CCode (cprefix="V4L2_TUNER_", has_type_id = false)]
	public enum TunerType
	{
		RADIO,
		ANALOG_TV,
		DIGITAL_TV
	}

	[CCode (cprefix="V4L2_MEMORY_", has_type_id = false)]
	public enum Memory
	{
		MMAP,
		USERPTR,
		OVERLAY
	}

	[CCode (cprefix="V4L2_COLORSPACE_", has_type_id = false)]
	public enum Colorspace
	{
		SMPTE170M,
		SMPTE240M,
		REC709,
		BT878,
		470_SYSTEM_M,
		470_SYSTEM_BG,
		JPEG,
		SRGB
	}

	[CCode (cprefix="V4L2_PRIORITY_", has_type_id = false)]
	public enum Priority
	{
		UNSET,
		BACKGROUND,
		INTERACTIVE,
		RECORD,
		DEFAULT
	}

	[CCode (cname="struct v4l2_rect", has_type_id = false)]
	public struct Rect
	{
		public int32 left;
		public int32 top;
		public int32 width;
		public int32 height;
	}

	[CCode (cname="struct v4l2_fract", has_type_id = false)]
	public struct Fraction
	{
		public uint32 numerator;
		public uint32 denominator;
	}

	[CCode (cprefix="V4L2_CAP_", has_type_id = false)]
	public enum Capabilities
	{
		VIDEO_CAPTURE,
		VIDEO_OUTPUT,
		VIDEO_OVERLAY,
		VBI_CAPTURE,
		VBI_OUTPUT,
		SLICED_VBI_CAPTURE,
		SLICED_VBI_OUTPUT,
		RDS_CAPTURE,
		VIDEO_OUTPUT_OVERLAY,
		HW_FREQ_SEEK,
		TUNER,
		AUDIO,
		RADIO,
		READWRITE,
		ASYNCIO,
		STREAMING
	}

	[CCode (cname="struct v4l2_capability", has_type_id = false)]
	public struct Capability
	{
		public unowned string driver;
		public unowned string card;
		public unowned string bus_info;
		public uint32 version;
		public uint32 capabilities;
		public uint32[] reserved;
	}

	[CCode (cprefix="V4L2_PIX_FMT_", has_type_id = false)]
	public enum PixelFormatType
	{
		RGB332,
		RGB444,
		RGB555,
		RGB565,
		RGB555X,
		RGB565X,
		BGR24,
		RGB24,
		BGR32,
		RGB32,
		GREY,
		Y16,
		PAL8,
		YVU410,
		YVU420,
		YUYV,
		UYVY,
		YUV422P,
		YUV411P,
		Y41P,
		YUV444,
		YUV555,
		YUV565,
		YUV32,
		NV12,
		NV21,
		YUV410,
		YUV420,
		YYUV,
		HI240,
		HM12,
		SBGGR8,
		SGBRG8,
		SBGGR16,
		MJPEG,
		JPEG,
		DV,
		MPEG,
		WNVA,
		SN9C10X,
		PWC1,
		PWC2,
		ET61X251,
		SPCA501,
		SPCA505,
		SPCA508,
		SPCA561,
		PAC207,
		PJPG,
		YVYU
	}

	[CCode (cname="struct v4l2_pix_format", has_type_id = false)]
	public struct PixelFormat
	{
		public uint32 width;
		public uint32 height;
		public uint32 pixelformat;
		public Field field;
		public uint32 bytesperline;
		public uint32 sizeimage;
		public Colorspace colorspace;
		public uint32 priv;
	}

	[CCode (cprefix="V4L2_FMT_FLAG_", has_type_id = false)]
	public enum FormatFlag
	{
		COMPRESSED
	}

	[CCode (cname="struct v4l2_fmtdesc", has_type_id = false)]
	public struct FormatDescriptor
	{
		public uint32 index;
		public BufferType type;
		public uint32 flags;
		public unowned string description;
		public uint pixelformat;
	}

	[CCode (cprefix="V4L2_FRMSIZE_TYPE_", has_type_id = false)]
	public enum FramesizeTypes
	{
		DISCRETE,
		CONTINUOUS,
		STEPWISE
	}

	[CCode (cname="struct v4l2_frmsize_discrete", has_type_id = false)]
	public struct FramesizeDiscrete
	{
		public uint32 width;
		public uint32 height;
	}

	[CCode (cname="struct v4l2_frmsize_stepwise", has_type_id = false)]
	public struct FramesizeStepwise
	{
		public uint32 min_width;
		public uint32 max_width;
		public uint32 step_width;
		public uint32 min_height;
		public uint32 max_height;
		public uint32 step_height;
	}

	[CCode (cname="struct v4l2_frmsizeenum", has_type_id = false)]
	public struct FramsizeEnum
	{
		public uint32 index;
		public uint32 pixel_format;
		public uint32 type;
		public FramesizeDiscrete discrete;
		public FramesizeStepwise stepwise;
	}

	[CCode (cprefix="V4L2_FRMIVAL_TYPE_", has_type_id = false)]
	public enum FrameivalTypes
	{
		DISCRETE,
		CONTINUOUS,
		STEPWISE
	}

	[CCode (cname="struct v4l2_frmival_stepwise", has_type_id = false)]
	public struct FrameivalStepwise
	{
		public Fraction min;
		public Fraction max;
		public Fraction step;
	}

	[CCode (cname="struct v4l2_frmivalenum", has_type_id = false)]
	public struct FrameivalEnum
	{
		public uint32 index;
		public uint32 pixel_format;
		public uint32 width;
		public uint32 height;
		public uint32 type;
		public Fraction discrete;
		public Fraction stepwise;
	}

	[CCode (cname="struct v4l2_timecode", has_type_id = false)]
	public struct Timecode
	{
		public uint	type;
		public uint32 flags;
		public uint8 frames;
		public uint8 seconds;
		public uint8 minutes;
		public uint8 hours;
		public uint8 userbits[4];
	}

	[CCode (cprefix="V4L2_TC_TYPE_", has_type_id = false)]
	public enum TimecodeType
	{
		24FPS,
		25FPS,
		30FPS,
		50FPS,
		60FPS
	}

	[CCode (cprefix="V4L2_TC_FLAGS_", has_type_id = false)]
	public enum TimecodeFlags
	{
		DROPFRAME,
		COLORFRAME
	}

	[CCode (cprefix="V4L2_TC_USERBITS_", has_type_id = false)]
	public enum TimecodeUserbits
	{
		field,
		USERDEFINED,
		8BITCHARS
	}


	[CCode (cname="struct v4l2_jpegcompression", has_type_id = false)]
	public struct JpegCompression
	{
		public int quality;
		public int APPn;
		public int APP_len;
		public char APP_data[60];
		public int COM_len;
		public char COM_data[60];
		public uint32 jpeg_markers;
	}

	[CCode (cprefix="V4L2_JPEG_MARKER_", has_type_id = false)]
	public enum JpegMarker
	{
		DHT,
		DQT,
		DRI,
		COM,
		APP
	}

	[CCode (cname="struct v4l2_requestbuffers", has_type_id = false)]
	public struct RequestBuffers
	{
		public uint32 count;
		public BufferType type;
		public Memory memory;
	}

	[CCode (cname="m", has_type_id = false)]
	public struct M
	{
		public uint32 offset;
		public ulong userptr;
	}

	[CCode (cname="struct v4l2_buffer", has_type_id = false)]
	public struct Buffer
	{
		public uint32 index;
		public BufferType type;
		public uint32 bytesused;
		public uint32 flags;
		public Field field;
		public GLib.TimeVal timestamp;
		public Timecode	timecode;
		public uint32 sequence;
		public Memory memory;
		public M m;
		public uint32 length;
		public uint32 input;
		public uint32 reserved;
	}

	[CCode (cprefix="V4L2_BUF_FLAG_", has_type_id = false)]
	public enum BufferFlags
	{
		MAPPED,
		QUEUED,
		DONE,
		KEYFRAME,
		PFRAME,
		BFRAME,
		TIMECODE,
		INPUT
	}

	[CCode (cname="struct v4l2_framebuffer", has_type_id = false)]
	public struct FrameBuffer
	{
		public uint32 capability;
		public uint32 flags;
		public void* @base;
		public PixelFormat fmt;
	}

	[CCode (cprefix="V4L2_FBUF_CAP_", has_type_id = false)]
	public enum FrameBufferCapabilites
	{
		EXTERNOVERLAY,
		CHROMAKEY,
		LIST_CLIPPING,
		BITMAP_CLIPPING,
		LOCAL_ALPHA,
		GLOBAL_ALPHA,
		LOCAL_INV_ALPHA
	}

	[CCode (cprefix="V4L2_FBUF_FLAG_", has_type_id = false)]
	public enum FrameBufferFlags
	{
		PRIMARY,
		OVERLAY,
		CHROMAKEY,
		LOCAL_ALPHA,
		GLOBAL_ALPHA,
		LOCAL_INV_ALPHA
	}

	[CCode (cname="struct v4l2_clip", has_type_id = false)]
	public struct Clip
	{
		public Rect c;
		public Clip* next;
	}

	[CCode (cname="struct v4l2_window", has_type_id = false)]
	public struct Window
	{
		public Rect w;
		public Field field;
		public uint32 chromakey;
		public Clip* clips;
		public uint32 clipcount;
		public void* bitmap;
		public uint8 global_alpha;
	}

	[CCode (cname="struct v4l2_captureparm", has_type_id = false)]
	public struct CaptureParm
	{
		public uint32 capability;
		public uint32 capturemode;
		public Fraction timeperframe;
		public uint32 extendedmode;
		public uint32 readbuffers;
	}

	[CCode (cprefix="V4L2_")]
	public const uint32 MODE_HIGHQUALITY;
	[CCode (cprefix="V4L2_")]
	public const uint32 CAP_TIMEPERFRAME;

	[CCode (cname="struct v4l2_outputparm", has_type_id = false)]
	public struct OutputParm
	{
		public uint32 capability;
		public uint32 outputmode;
		public Fraction timeperframe;
		public uint32 extendedmode;
		public uint32 writebuffers;
	}

	[CCode (cname="struct v4l2_cropcap", has_type_id = false)]
	public struct CropCap
	{
		public BufferType  type;
		public Rect bounds;
		public Rect defrect;
		public Fraction pixelaspect;
	}

	[CCode (cname="struct v4l2_crop", has_type_id = false)]
	public struct Crop
	{
		public BufferType type;
		public Rect c;
	}

	[CCode (cprefix="V4L2_STD_", has_type_id = false)]
	public enum Standards
	{
		PAL_B,
		PAL_B1,
		PAL_G,
		PAL_H,
		PAL_I,
		PAL_D,
		PAL_D1,
		PAL_K,
		PAL_M,
		PAL_N,
		PAL_Nc,
		PAL_60,
		NTSC_M,
		NTSC_M_JP,
		NTSC_443,
		NTSC_M_KR,
		SECAM_B,
		SECAM_D,
		SECAM_G,
		SECAM_H,
		SECAM_K,
		SECAM_K1,
		SECAM_L,
		SECAM_LC,
		ATSC_8_VSB,
		ATSC_16_VSB,
		MN,
		B,
		GH,
		DK,
		PAL_BG,
		PAL_DK,
		PAL,
		NTSC,
		SECAM_DK,
		SECAM,
		525_60,
		625_50,
		ATSC,
		UNKNOWN,
		ALL
	}

	[CCode (cname="v4l2_std_id", has_type_id = false)]
	public struct StdId : uint64 { }

	[CCode (cname="struct v4l2_standard", has_type_id = false)]
	public struct Standard
	{
		public uint32 index;
		public StdId id;
		public unowned string name;
		public Fraction frameperiod;
		public uint32 framelines;
	}

	[CCode (cname="struct v4l2_input", has_type_id = false)]
	public struct Input
	{
		public uint32 index;
		public unowned string name;
		public uint32 type;
		public uint32 audioset;
		public uint32 tuner;
		public StdId std;
		public uint32 status;
	}

	[CCode (cprefix="V4L2_INPUT_TYPE_", has_type_id = false)]
	public enum InputType
	{
		TUNER,
		CAMERA
	}

	[CCode (cprefix="V4L2_IN_ST_", has_type_id = false)]
	public enum InputStatus
	{
		NO_POWER,
		NO_SIGNAL,
		NO_COLOR,
		NO_H_LOCK,
		COLOR_KILL,
		NO_SYNC,
		NO_EQU,
		NO_CARRIER,
		MACROVISION,
		NO_ACCESS,
		VTR
	}

	[CCode (cname="struct v4l2_output", has_type_id = false)]
	public struct Output
	{
		public uint32  index;
		public unowned string name;
		public uint32 type;
		public uint32 audioset;
		public uint32 modulator;
		public StdId std;
	}

	[CCode (cprefix="V4L2_OUTPUT_TYPE_", has_type_id = false)]
	public enum OutputType
	{
		MODULATOR,
		ANALOG,
		ANALOGVGAOVERLAY
	}

	[CCode (cname="struct v4l2_control", has_type_id = false)]
	public struct Control
	{
		public uint32 id;
		public int32 @value;
	}

	[CCode (cname="struct v4l2_ext_control", has_type_id = false)]
	public struct ExtControl
	{
		public uint32 id;
		public int32 @value;
		public int64 value64;
		public void* reserved;
	}

	[CCode (cname="struct v4l2_ext_controls", has_type_id = false)]
	public struct ExtControls
	{
		public uint32 ctrl_class;
		public uint32 count;
		public uint32 error_idx;
		public ExtControl* controls;
	}

	[CCode (cprefix="V4L2_CTRL_CLASS_", has_type_id = false)]
	public enum ControlClass
	{
		USER,
		MPEG,
		CAMERA
	}

	[CCode (cprefix="V4L2_")]
	public const uint32 CTRL_ID_MASK;
	[CCode (cname="V4L2_CTRL_ID2CLASS")]
	public uint32 ctrl_id2class (uint32 id);
	[CCode (cname="V4L2_CTRL_DRIVER_PRIV")]
	public uint32 ctrl_driver_priv (uint32 id);

	[CCode (cname="struct v4l2_queryctrl", has_type_id = false)]
	public struct QueryControl
	{
		public uint32 id;
		public ControlType type;
		public unowned string name;
		public int32 minimum;
		public int32 maximum;
		public int32 step;
		public int32 default_value;
		public uint32 flags;
	}

	[CCode (cname="struct v4l2_querymenu", has_type_id = false)]
	public struct QueryMenu
	{
		public uint32 id;
		public uint32 index;
		public unowned string name;
		public uint32 reserved;
	}

	[CCode (cprefix="V4L2_CTRL_FLAG_", has_type_id = false)]
	public enum ControlFlags
	{
		DISABLED,
		GRABBED,
		READ_ONLY,
		UPDATE,
		INACTIVE,
		SLIDER,
		NEXT_CTRL
	}

	[CCode (cprefix="V4L2_CID_", has_type_id = false)]
	public enum UserClassControlIds
	{
		BASE,
		USER_BASE,
		PRIVATE_BASE,
		USER_CLASS,
		BRIGHTNESS,
		CONTRAST,
		SATURATION,
		HUE,
		AUDIO_VOLUME,
		AUDIO_BALANCE,
		AUDIO_BASS,
		AUDIO_TREBLE,
		AUDIO_MUTE,
		AUDIO_LOUDNESS,
		AUTO_WHITE_BALANCE,
		DO_WHITE_BALANCE,
		RED_BALANCE,
		BLUE_BALANCE,
		GAMMA,
		EXPOSURE,
		AUTOGAIN,
		GAIN,
		HFLIP,
		VFLIP,
		POWER_LINE_FREQUENCY,
		HUE_AUTO,
		WHITE_BALANCE_TEMPERATURE,
		SHARPNESS,
		BACKLIGHT_COMPENSATION,
		CHROMA_AGC,
		COLOR_KILLER,
		LASTP1
	}

	[CCode (cprefix="V4L2_CID_POWER_LINE_FREQUENCY_", has_type_id = false)]
	public enum PowerLineFrequency
	{
		DISABLED,
		50HZ,
		60HZ
	}

	[CCode (cprefix="V4L2_CID_MPEG_", has_type_id = false)]
	public enum MpegClassControlIds
	{
		BASE,
		CLASS,
		STREAM_TYPE,
		STREAM_PID_PMT,
		STREAM_PID_AUDIO,
		STREAM_PID_VIDEO,
		STREAM_PID_PCR,
		STREAM_PES_ID_AUDIO,
		STREAM_PES_ID_VIDEO,
		STREAM_VBI_FMT,
		AUDIO_SAMPLING_FREQ,
		AUDIO_ENCODING,
		AUDIO_L1_BITRATE,
		AUDIO_L2_BITRATE,
		AUDIO_L3_BITRATE,
		AUDIO_MODE,
		AUDIO_MODE_EXTENSION,
		AUDIO_EMPHASIS,
		AUDIO_CRC,
		AUDIO_MUTE,
		VIDEO_ENCODING,
		VIDEO_ASPECT,
		VIDEO_B_FRAMES,
		VIDEO_GOP_SIZE,
		VIDEO_GOP_CLOSURE,
		VIDEO_PULLDOWN,
		VIDEO_BITRATE_MODE,
		VIDEO_BITRATE,
		VIDEO_BITRATE_PEAK,
		VIDEO_TEMPORAL_DECIMATION,
		VIDEO_MUTE,
		VIDEO_MUTE_YUV
	}

	[CCode (cprefix="V4L2_MPEG_STREAM_TYPE_", has_type_id = false)]
	public enum MpegStreamType
	{
		MPEG2_PS,
		MPEG2_TS,
		MPEG1_SS,
		MPEG2_DVD,
		MPEG1_VCD,
		MPEG2_SVCD
	}

	[CCode (cprefix="V4L2_MPEG_STREAM_VBI_FMT_", has_type_id = false)]
	public enum MpegStreamVbiFmt
	{
		NONE,
		IVTV
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_SAMPLING_FREQ_", has_type_id = false)]
	public enum MpegAudioSamplingFreq
	{
		@44100,
		@48000,
		@32000
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_ENCODING_", has_type_id = false)]
	public enum MpegAudioEncoding
	{
		LAYER_1,
		LAYER_2,
		LAYER_3
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_L1_BITRATE_", has_type_id = false)]
	public enum MpegAudioL1Bitrate
	{
		32K,
		64K,
		96K,
		128K,
		160K,
		192K,
		224K,
		256K,
		288K,
		320K,
		352K,
		384K,
		416K,
		448K
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_L2_BITRATE_", has_type_id = false)]
	public enum MpegAudioL2Bitrate
	{
		32K,
		48K,
		56K,
		64K,
		80K,
		96K,
		112K,
		128K,
		160K,
		192K,
		224K,
		256K,
		320K,
		384K
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_L3_BITRATE_", has_type_id = false)]
	public enum MpegAudioL3Bitrate
	{
		32K,
		40K,
		48K,
		56K,
		64K,
		80K,
		96K,
		112K,
		128K,
		160K,
		192K,
		224K,
		256K,
		320K,
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_MODE_", has_type_id = false)]
	public enum MpegAudioMode
	{
		STEREO,
		JOINT_STEREO,
		DUAL,
		MONO
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_MODE_EXTENSION_", has_type_id = false)]
	public enum MpegAudioModeExtension
	{
		BOUND_4,
		BOUND_8,
		BOUND_12,
		BOUND_16
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_EMPHASIS_", has_type_id = false)]
	public enum MpegAudioEmphasis
	{
		NONE,
		50_DIV_15_uS,
		CCITT_J17,
	}

	[CCode (cprefix="V4L2_MPEG_AUDIO_CRC_", has_type_id = false)]
	public enum MpegAudioCrc
	{
		NONE,
		CRC16
	}

	[CCode (cprefix="V4L2_MPEG_VIDEO_ENCODING_", has_type_id = false)]
	public enum MpegVideoEncoding
	{
		MPEG_1,
		MPEG_2
	}

	[CCode (cprefix="V4L2_MPEG_VIDEO_ASPECT_", has_type_id = false)]
	public enum MpegVideoAspect
	{
		1x1,
		4x3,
		16x9,
		221x100
	}

	[CCode (cprefix="V4L2_MPEG_VIDEO_BITRATE_MODE_", has_type_id = false)]
	public enum MpegVideoBitrateMode
	{
		VBR,
		CBR
	}

	[CCode (cprefix="V4L2_CID_MPEG_CX2341X_", has_type_id = false)]
	public enum MpegCx2341xClassControlIds
	{
		BASE,
		VIDEO_SPATIAL_FILTER_MODE,
		VIDEO_SPATIAL_FILTER,
		VIDEO_LUMA_SPATIAL_FILTER_TYPE,
		VIDEO_CHROMA_SPATIAL_FILTER_TYPE,
		VIDEO_TEMPORAL_FILTER_MODE,
		VIDEO_TEMPORAL_FILTER,
		VIDEO_MEDIAN_FILTER_TYPE,
		VIDEO_LUMA_MEDIAN_FILTER_BOTTOM,
		VIDEO_LUMA_MEDIAN_FILTER_TOP,
		VIDEO_CHROMA_MEDIAN_FILTER_BOTTOM,
		VIDEO_CHROMA_MEDIAN_FILTER_TOP,
		STREAM_INSERT_NAV_PACKETS
	}

	[CCode (cprefix="V4L2_MPEG_CX2341X_VIDEO_SPATIAL_FILTER_MODE_", has_type_id = false)]
	public enum MpegCx2341xVideoSpatialFilterMode
	{
		MANUAL,
		AUTO,
	}

	[CCode (cprefix="V4L2_MPEG_CX2341X_VIDEO_LUMA_SPATIAL_FILTER_TYPE_", has_type_id = false)]
	public enum MpegCx2341xVideoLumaSpatialFilterType
	{
		OFF,
		1D_HOR,
		1D_VERT,
		2D_HV_SEPARABLE,
		2D_SYM_NON_SEPARABLE,
	}

	[CCode (cprefix="V4L2_MPEG_CX2341X_VIDEO_CHROMA_SPATIAL_FILTER_TYPE_", has_type_id = false)]
	public enum MpegCx2341xVideoChromaSpatialFilterType
	{
		OFF,
		1D_HOR
	}

	[CCode (cprefix="V4L2_MPEG_CX2341X_VIDEO_TEMPORAL_FILTER_MODE_", has_type_id = false)]
	public enum MpegCx2341xVideoTemporalFilterMode
	{
		MANUAL,
		AUTO
	}

	[CCode (cprefix="V4L2_MPEG_CX2341X_VIDEO_MEDIAN_FILTER_TYPE_", has_type_id = false)]
	public enum MpegCx2341xVideoMedianFilterType
	{
		OFF,
		HOR,
		VERT,
		HOR_VERT,
		DIAG
	}

	[CCode (cprefix="V4L2_CID_", has_type_id = false)]
	public enum CameraClassControlIds
	{
		CAMERA_CLASS_BASE,
		CAMERA_CLASS,
		EXPOSURE_AUTO,
		EXPOSURE_ABSOLUTE,
		EXPOSURE_AUTO_PRIORITY,
		PAN_RELATIVE,
		TILT_RELATIVE,
		PAN_RESET,
		TILT_RESET,
		PAN_ABSOLUTE,
		TILT_ABSOLUTE,
		FOCUS_ABSOLUTE,
		FOCUS_RELATIVE,
		FOCUS_AUTO
	}

	[CCode (cprefix="V4L2_EXPOSURE_", has_type_id = false)]
	public enum ExposureAutoType
	{
		AUTO,
		MANUAL,
		SHUTTER_PRIORITY,
		APERTURE_PRIORITY
	}

	[CCode (cname="struct v4l2_tuner", has_type_id = false)]
	public struct Tuner
	{
		public uint32 index;
		public unowned string name;
		public TunerType type;
		public uint32 capability;
		public uint32 rangelow;
		public uint32 rangehigh;
		public uint32 rxsubchans;
		public uint32 audmode;
		public int32 @signal;
		public int32 afc;
	}

	[CCode (cname="struct v4l2_modulator", has_type_id = false)]
	public struct Modulator
	{
		public uint32 index;
		public unowned string name;
		public uint32 capability;
		public uint32 rangelow;
		public uint32 rangehigh;
		public uint32 txsubchans;
	}

	[CCode (cprefix="V4L2_TUNER_CAP_", has_type_id = false)]
	public enum TunerCapabilities
	{
		LOW,
		NORM,
		STEREO,
		LANG2,
		SAP,
		LANG1
	}

	[CCode (cprefix="V4L2_TUNER_SUB_", has_type_id = false)]
	public enum TunerSubs
	{
		MONO,
		STEREO,
		LANG2,
		SAP,
		LANG1
	}

	[CCode (cprefix="V4L2_TUNER_MODE_", has_type_id = false)]
	public enum TunerModes
	{
		MONO,
		STEREO,
		LANG2,
		SAP,
		LANG1,
		LANG1_LANG2
	}

	[CCode (cname="struct v4l2_frequency", has_type_id = false)]
	public struct Frequency
	{
		public uint32 tuner;
		public TunerType type;
		public uint32 frequency;
	}

	[CCode (cname="struct v4l2_hw_freq_seek", has_type_id = false)]
	public struct HwFreqSeek
	{
		public uint32 tuner;
		public TunerType type;
		public uint32 seek_upward;
		public uint32 wrap_around;
	}

	[CCode (cname="struct v4l2_audio", has_type_id = false)]
	public struct Audio
	{
		public uint32 index;
		public unowned string name;
		public uint32 capability;
		public uint32 mode;
	}

	[CCode (cprefix="V4L2_AUDCAP_", has_type_id = false)]
	public enum AudioCapabilities
	{
		STEREO,
		AVL
	}

	[CCode (cprefix="V4L2_")]
	public const uint32 AUDMODE_AVL;

	[CCode (cname="struct v4l2_audioout", has_type_id = false)]
	public struct AudioOut
	{
		public uint32 index;
		public unowned string name;
		public uint32 capability;
		public uint32 mode;
	}

	[CCode (cprefix="V4L2_ENC_IDX_FRAME_", has_type_id = false)]
	public enum EncIdxFrame
	{
		I,
		P,
		B,
		MASK
	}

	[CCode (cname="struct v4l2_enc_idx_entry", has_type_id = false)]
	public struct EncIdxEntry
	{
		public uint64 offset;
		public uint64 pts;
		public uint32 length;
		public uint32 flags;
	}

	[CCode (cprefix="V4L2_")]
	public const int ENC_IDX_ENTRIES;

	[CCode (cname="struct v4l2_enc_idx", has_type_id = false)]
	public struct EncIdx
	{
		public uint32 entries;
		public uint32 entries_cap;
		public EncIdxEntry[] entry;
	}

	[CCode (cprefix="V4L2_ENC_CMD_", has_type_id = false)]
	public enum EncCmd
	{
		START,
		STOP,
		PAUSE,
		RESUME,
		STOP_AT_GOP_END
	}

	[CCode (cname="struct raw", has_type_id = false)]
	public struct Raw
	{
		public uint32 data[8];
	}

	[CCode (cname="struct v4l2_encoder_cmd", has_type_id = false)]
	public struct EncoderCmd
	{
		public uint32 cmd;
		public uint32 flags;
		public Raw raw;
	}

	[CCode (cname="struct v4l2_vbi_format", has_type_id = false)]
	public struct VbiFormat
	{
		public uint32 sampling_rate;
		public uint32 offset;
		public uint32 samples_per_line;
		public uint32 sample_format;
		public int32 start[2];
		public uint32 count[2];
		public uint32 flags;
	}

	[CCode (cprefix="V4L2_VBI_", has_type_id = false)]
	public enum VbiFlags
	{
		UNSYNC,
		INTERLACED
	}

	[CCode (cname="struct v4l2_sliced_vbi_format", has_type_id = false)]
	public struct SlicedVbiFormat
	{
		public uint16 service_set;
		public uint16[] service_lines;
		public uint32 io_size;
		public uint32[] reserved;
	}

	[CCode (cprefix="V4L2_SLICED_", has_type_id = false)]
	public enum SlicedType
	{
		ELETEXT_B,
		VPS,
		CAPTION_525,
		WSS_625,
		VBI_525,
		VBI_625,
		T
	}

	[CCode (cname="struct v4l2_sliced_vbi_cap", has_type_id = false)]
	public struct SlicedVbiCap
	{
		public uint16 service_set;
		public uint16[] service_lines;
		public BufferType type;
	}

	[CCode (cname="struct v4l2_sliced_vbi_data", has_type_id = false)]
	public struct SlicedVbiData
	{
		public uint32 id;
		public uint32 field;
		public uint32 line;
		public uint8 data[48];
	}

	[CCode (has_type_id = false)]
	public struct Fmt
	{
		public PixelFormat pix;
		public Window win;
		public VbiFormat vbi;
		public SlicedVbiFormat sliced;
		public uint8 raw_data[200];
	}

	[CCode (cname="struct v4l2_format", has_type_id = false)]
	public struct Format
	{
		public BufferType type;
		public Fmt fmt;
	}

	[CCode (has_type_id = false)]
	public struct Parm
	{
		public CaptureParm capture;
		public OutputParm output;
		public uint8 raw_data[200];
	}

	[CCode (cname="struct v4l2_streamparm", has_type_id = false)]
	public struct StreamParm
	{
		public BufferType type;
		public unowned Parm parm;
	}

	[CCode (cprefix="V4L2_CHIP_MATCH_", has_type_id = false)]
	public enum ChipMatch
	{
		HOST,
		I2C_DRIVER,
		I2C_ADDR
	}

	[CCode (cname="struct v4l2_register", has_type_id = false)]
	public struct Register
	{
		public uint32 match_type;
		public uint32 match_chip;
		public uint64 reg;
		public uint64 val;
	}

	[CCode (cname="struct v4l2_chip_ident", has_type_id = false)]
	public struct ChipIdent
	{
		public uint32 match_type;
		public uint32 match_chip;
		public uint32 ident;
		public uint32 revision;
	}

	public const int VIDIOC_QUERYCAP;
	public const int VIDIOC_RESERVED;
	public const int VIDIOC_ENUM_FMT;
	public const int VIDIOC_G_FMT;
	public const int VIDIOC_S_FMT;
	public const int VIDIOC_REQBUFS;
	public const int VIDIOC_QUERYBUF;
	public const int VIDIOC_G_FBUF;
	public const int VIDIOC_S_FBUF;
	public const int VIDIOC_OVERLAY;
	public const int VIDIOC_QBUF;
	public const int VIDIOC_DQBUF;
	public const int VIDIOC_STREAMON;
	public const int VIDIOC_STREAMOFF;
	public const int VIDIOC_G_PARM;
	public const int VIDIOC_S_PARM;
	public const int VIDIOC_G_STD;
	public const int VIDIOC_S_STD;
	public const int VIDIOC_ENUMSTD;
	public const int VIDIOC_ENUMINPUT;
	public const int VIDIOC_G_CTRL;
	public const int VIDIOC_S_CTRL;
	public const int VIDIOC_G_TUNER;
	public const int VIDIOC_S_TUNER;
	public const int VIDIOC_G_AUDIO;
	public const int VIDIOC_S_AUDIO;
	public const int VIDIOC_QUERYCTRL;
	public const int VIDIOC_QUERYMENU;
	public const int VIDIOC_G_INPUT;
	public const int VIDIOC_S_INPUT;
	public const int VIDIOC_G_OUTPUT;
	public const int VIDIOC_S_OUTPUT;
	public const int VIDIOC_ENUMOUTPUT;
	public const int VIDIOC_G_AUDOUT;
	public const int VIDIOC_S_AUDOUT;
	public const int VIDIOC_G_MODULATOR;
	public const int VIDIOC_S_MODULATOR;
	public const int VIDIOC_G_FREQUENCY;
	public const int VIDIOC_S_FREQUENCY;
	public const int VIDIOC_CROPCAP;
	public const int VIDIOC_G_CROP;
	public const int VIDIOC_S_CROP;
	public const int VIDIOC_G_JPEGCOMP;
	public const int VIDIOC_S_JPEGCOMP;
	public const int VIDIOC_QUERYSTD;
	public const int VIDIOC_TRY_FMT;
	public const int VIDIOC_ENUMAUDIO;
	public const int VIDIOC_ENUMAUDOUT;
	public const int VIDIOC_G_PRIORITY;
	public const int VIDIOC_S_PRIORITY;
	public const int VIDIOC_G_SLICED_VBI_CAP;
	public const int VIDIOC_LOG_STATUS;
	public const int VIDIOC_G_EXT_CTRLS;
	public const int VIDIOC_S_EXT_CTRLS;
	public const int VIDIOC_TRY_EXT_CTRLS;
	public const int VIDIOC_ENUM_FRAMESIZES;
	public const int VIDIOC_ENUM_FRAMEINTERVALS;
	public const int VIDIOC_G_ENC_INDEX;
	public const int VIDIOC_ENCODER_CMD;
	public const int VIDIOC_TRY_ENCODER_CMD;
	public const int VIDIOC_DBG_S_REGISTER;
	public const int VIDIOC_DBG_G_REGISTER;
	public const int VIDIOC_G_CHIP_IDENT;
	public const int VIDIOC_S_HW_FREQ_SEEK;
	public const int VIDIOC_OVERLAY_OLD;
	public const int VIDIOC_S_PARM_OLD;
	public const int VIDIOC_S_CTRL_OLD;
	public const int VIDIOC_G_AUDIO_OLD;
	public const int VIDIOC_G_AUDOUT_OLD;
	public const int VIDIOC_CROPCAP_OLD;
	public const int BASE_VIDIOC_PRIVATE;
}
