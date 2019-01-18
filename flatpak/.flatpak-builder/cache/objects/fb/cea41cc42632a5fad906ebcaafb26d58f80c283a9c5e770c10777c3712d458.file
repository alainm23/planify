[CCode (cprefix = "FTDI_", lower_case_prefix = "ftdi_", cheader_filename = "ftdi.h")]
namespace FTDI {

	public const int DEFAULT_EEPROM_SIZE;

	[CCode (cname = "enum ftdi_chip_type", cprefix = "TYPE_", has_type_id = false)]
	public enum ChipType {
		AM,
		BM,
		2232C,
		R
	}

	[CCode (cname = "enum ftdi_parity_type", cprefix = "", has_type_id = false)]
	public enum ParityType {
		NONE,
		ODD,
		EVEN,
		MARK,
		SPACE
	}

	[CCode (cname = "enum ftdi_stopbits_type", cprefix = "STOP_", has_type_id = false)]
	public enum StopBitsType {
		BIT_1,
		BIT_15,
		BIT_2
	}

	[CCode (cname = "enum ftdi_bits_type", cprefix = "", has_type_id = false)]
	public enum BitsType {
		BITS_7,
		BITS_8
	}

	[CCode (cname = "enum ftdi_break_type", cprefix="BREAK_", has_type_id = false)]
	public enum BreakType {
		OFF,
		ON,
	}

	[CCode (cprefix = "BITMODE_", cname = "ftdi_mpsse_mode", has_type_id = false)]
	public enum MPSSEMode {
		RESET,
		BITBANG,
		MPSSE,
		SYNCBB,
		MCU,
		OPTO,
		CBUS
	}

	[CCode (cname = "enum ftdi_interface", cprefix = "INTERFACE_", has_type_id = false)]
	public enum Interface {
		ANY,
		A,
		B
	}

	[CCode (cprefix="MPSSE_")]
	namespace ShiftingCommands {
		public const int WRITE_NEG;
		public const int BITMODE;
		public const int READ_NEG;
		public const int LSB;
		public const int DO_WRITE;
		public const int DO_READ;
		public const int WRITE_TMS;
	}

	[CCode (cprefix="")]
	namespace MPSSECommands {
		public const int SET_BITS_LOW;
		public const int SET_BITS_HIGH;
		public const int GET_BITS_LOW;
		public const int GET_BITS_HIGH;
		public const int LOOPBACK_START;
		public const int LOOPBACK_END;
		public const int TCK_DIVISOR;
		public const int SEND_IMMEDIATE;
		public const int WAIT_ON_HIGH;
		public const int WAIT_ON_LOW;
	}

	[CCode (cname="DIV_VALUE")]
	public int div_value (int rate);

	[CCode (cprefix="")]
	namespace HostEmultationModeCommands {
		public const int SEND_IMMEDIATE;
		public const int WAIT_ON_HIGH;
		public const int WAIT_ON_LOW;
		public const int READ_SHORT;
		public const int READ_EXTENDED;
		public const int WRITE_SHORT;
		public const int WRITE_EXTENDED;
	}

	[CCode (cprefix="SIO_")]
	public const int RESET;
	[CCode (cprefix="SIO_")]
	public const int MODEM_CTRL;
	[CCode (cprefix="SIO_")]
	public const int SET_FLOW_CTRL;
	[CCode (cprefix="SIO_")]
	public const int SET_BAUD_RATE;
	[CCode (cprefix="SIO_")]
	public const int SET_DATA;
	[CCode (cprefix="SIO_")]
	public const int RESET_REQUEST_TYPE;
	[CCode (cprefix="SIO_")]
	public const int RESET_REQUEST;
	[CCode (cprefix="SIO_")]
	public const int RESET_SIO;
	[CCode (cprefix="SIO_")]
	public const int RESET_PURGE_RX;
	[CCode (cprefix="SIO_")]
	public const int RESET_PURGE_TX;
	[CCode (cprefix="SIO_")]
	public const int SET_BAUDRATE_REQUEST_TYPE;
	[CCode (cprefix="SIO_")]
	public const int SET_BAUDRATE_REQUEST;
	[CCode (cprefix="SIO_")]
	public const int SET_DATA_REQUEST_TYPE;
	[CCode (cprefix="SIO_")]
	public const int SET_DATA_REQUEST;
	[CCode (cprefix="SIO_")]
	public const int SET_FLOW_CTRL_REQUEST;
	[CCode (cprefix="SIO_")]
	public const int SET_FLOW_CTRL_REQUEST_TYPE;
	[CCode (cprefix="SIO_")]
	public const int DISABLE_FLOW_CTRL;
	[CCode (cprefix="SIO_")]
	public const int RTS_CTS_HS;
	[CCode (cprefix="SIO_")]
	public const int DTR_DSR_HS;
	[CCode (cprefix="SIO_")]
	public const int XON_XOFF_HS;
	[CCode (cprefix="SIO_")]
	public const int SET_MODEM_CTRL_REQUEST_TYPE;
	[CCode (cprefix="SIO_")]
	public const int SET_MODEM_CTRL_REQUEST;
	[CCode (cprefix="SIO_")]
	public const int SET_DTR_MASK;
	[CCode (cprefix="SIO_")]
	public const int SET_DTR_HIGH;
	[CCode (cprefix="SIO_")]
	public const int SET_DTR_LOW;
	[CCode (cprefix="SIO_")]
	public const int SET_RTS_MASK;
	[CCode (cprefix="SIO_")]
	public const int SET_RTS_HIGH;
	[CCode (cprefix="SIO_")]
	public const int SET_RTS_LOW;

	public const int URB_USERCONTEXT_COOKIE;

	[CCode (cname = "struct ftdi_device_list", destroy_function = "ftdi_list_free", has_type_id = false)]
	public struct DeviceList {
		public DeviceList* next;
		public USB.Device* dev;
	}

	[CCode (cname = "struct ftdi_eeprom", cprefix="ftdi_eeprom_", has_type_id = false)]
	public struct EEPROM {
		public int vendor_id;
		public int product_id;
		public int self_powered;
		public int remote_wakeup;
		public int BM_type_chip;
		public int in_is_isochronous;
		public int out_is_isochronous;
		public int suspend_pull_downs;
		public int use_serial;
		public int change_usb_version;
		public int usb_version;
		public int max_power;
		public unowned string manufacturer;
		public unowned string product;
		public unowned string serial;
		public int size;
		public void initdefaults ();
		public int build ([CCode (array_length = false)] uchar[] output);
          public int decode (uchar[] buffer);
	}

	[Compact]
	[CCode (cname = "struct ftdi_context", cprefix ="ftdi_", free_function="ftdi_free")]
	public class Context {
		[CCode (cname = "ftdi_new")]
		public Context ();
		public int init ();
		public void deinit ();
		public int set_interface (Interface iface);
		public void set_usbdev (USB.DeviceHandle usbdev);
		public int usb_find_all (out DeviceList devlist, int vendor, int product);
		public int usb_get_strings (USB.Device usbdev, [CCode (array_length = false)] char[] manufacturer, int manufacturer_len, [CCode (array_length = false)] char[] description, int description_len, [CCode (array_length = false)] char[] serial, int serial_len);
		public int usb_open_dev (USB.Device usbdev);
		public int usb_open (int vendor, int product);
		public int usb_open_desc (int vendor, int product, string description, string serial);
		public int usb_reset ();
		public int usb_purge_rx_buffers ();
		public int usb_purge_tx_buffers ();
		public int usb_purge_buffers ();
		public int usb_close ();
		public int set_baudrate (int baudrate);
		public int set_line_property (BitsType bits, StopBitsType sbit, ParityType parity);
		public int set_line_property2 (BitsType bits, StopBitsType sbit, ParityType parity, BreakType break_type);
		public int write_data (uchar[] buf);
		public int write_data_set_chunksize (int chunksize);
		public int write_data_get_chunksize (out int chunksize);
		public int read_data (uchar[] buf);
		public int read_data_set_chunksize (int chunksize);
		public int read_data_get_chunksize (out int chunksize);
		public int write_data_async (uchar[] buf);
		public void async_complete (int wait_for_more);
		public int enable_bitbang (uchar bitmask);
		public int disable_bitbang ();
		public int set_bitmode (uchar bitmask, uchar mode);
		public int read_pins (out uchar pins);
		public int set_latency_timer (uchar latency);
		public int get_latency_timer (out uchar latency);
		public int poll_modem_status (out ushort status);
		public int setflowctrl (int flowctrl);
		public int setdtr_rts (int dtr, int rts);
		public int setdtr (int state);
		public int setrts (int state);
		public int set_event_char (uchar eventch, uchar enable);
		public int set_error_char (uchar errorch, uchar enable);
		public void eeprom_setsize (EEPROM eeprom, int size);
		public int read_eeprom ([CCode (array_length = false)] uchar[] eeprom);
		public int read_chipid (out uint chipid);
		public int read_eeprom_getsize (uchar[] eeprom);
		public int write_eeprom ([CCode (array_length = false)] uchar[] eeprom);
		public int erase_eeprom ();
		public unowned string get_error_string ();

		public USB.DeviceHandle usb_dev;
		public int usb_read_timeout;
		public int usb_write_timeout;
		public ChipType type;
		public int baudrate;
		public uchar bitbang_enabled;
		[CCode (array_length = false)]
		public uchar[] readbuffer;
		public uint readbuffer_offset;
		public uint readbuffer_remaining;
		public uint readbuffer_chunksize;
		public uint writebuffer_chunksize;
		public int @interface;
		public int index;
		public int in_ep;
		public int out_ep;
		public uchar bitbang_mode;
		public int eeprom_size;
		public unowned string error_str;
		[CCode (array_length_cname = "async_usb_buffer_size")]
		public char[] async_usb_buffer;
	}
}
