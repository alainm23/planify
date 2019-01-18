[CCode (cprefix = "libusb_", cheader_filename = "libusb.h")]
namespace LibUSB {
	[CCode (cname = "enum libusb_class_code", cprefix = "LIBUSB_CLASS_", has_type_id = false)]
	public enum ClassCode {
		PER_INTERFACE,
		AUDIO,
		COMM,
		HID,
		PRINTER,
		PTP,
		MASS_STORAGE,
		HUB,
		DATA,
		VENDOR_SPEC
	}

	[CCode (cname = "enum libusb_descriptor_type", cprefix = "LIBUSB_DT_", has_type_id = false)]
	public enum DescriptorType {
		DEVICE,
		CONFIG,
		STRING,
		INTERFACE,
		ENDPOINT,
		HID,
		REPORT,
		PHYSICAL,
		HUB
	}

	[CCode (cprefix = "LIBUSB_DT_")]
	namespace DescriptorTypeSize {
		public const int DEVICE_SIZE;
		public const int CONFIG_SIZE;
		public const int INTERFACE_SIZE;
		public const int ENDPOINT_SIZE;
		public const int ENDPOINT_AUDIO_SIZE;
		public const int HUB_NONVAR_SIZE;
	}

	namespace EndpointMask {
		[CCode (cname = "LIBUSB_ENDPOINT_ADDRESS_MASK")]
		public const int ADDRESS;
		[CCode (cname = "LIBUSB_ENDPOINT_DIR_MASK")]
		public const int DIR;
		[CCode (cname = "LIBUSB_ENDPOINT_DIR_MASK")]
		public const int DIRECTION;
	}

	[CCode (cname = "enum libusb_endpoint_direction", cprefix = "LIBUSB_ENDPOINT_", has_type_id = false)]
	public enum EndpointDirection {
		IN,
		OUT,
		[CCode (cname = "LIBUSB_ENDPOINT_DIR_MASK")]
		MASK
	}

	[CCode (cname = "enum libusb_transfer_type", cprefix = "LIBUSB_TRANSFER_TYPE_", has_type_id = false)]
	public enum TransferType {
		CONTROL,
		ISOCHRONOUS,
		BULK,
		INTERRUPT
	}

	[CCode (cname = "enum libusb_standard_request", cprefix = "LIBUSB_REQUEST_", has_type_id = false)]
	public enum StandardRequest {
		GET_STATUS,
		CLEAR_FEATURE,
		SET_FEATURE,
		SET_ADDRESS,
		GET_DESCRIPTOR,
		SET_DESCRIPTOR,
		GET_CONFIGURATION,
		GET_INTERFACE,
		SET_INTERFACE,
		SYNCH_FRAME
	}

	[CCode (cname = "enum libusb_request_type", cprefix = "LIBUSB_REQUEST_TYPE_", has_type_id = false)]
	public enum RequestType {
		STANDARD,
		CLASS,
		VENDOR,
		RESERVED
	}

	[CCode (cname = "enum libusb_request_recipient", cprefix = "LIBUSB_RECIPIENT_", has_type_id = false)]
	public enum RequestRecipient {
		DEVICE,
		INTERFACE,
		ENDPOINT,
		OTHER
	}

	[CCode (cname =	"enum libusb_iso_sync_type", cprefix = "LIBUSB_ISO_SYNC_TYPE_", has_type_id = false)]
	public enum IsoSyncType {
		NONE,
		ASYNC,
		ADAPTIVE,
		SYNC,
		MASK
	}

	[CCode (cname = "enum libusb_iso_usage_type", cprefix = "LIBUSB_ISO_USAGE_TYPE_", has_type_id = false)]
	public enum IsoUsageType {
		DATA,
		FEEDBACK,
		IMPLICIT,
		MASK
	}

	[CCode (cname = "enum libusb_error", cprefix = "LIBUSB_ERROR_", has_type_id = false)]
	public enum Error {
		[CCode (cname = "LIBUSB_SUCCESS")]
		SUCCESS,
		IO,
		INVALID_PARAM,
		ACCESS,
		NO_DEVICE,
		NOT_FOUND,
		BUSY,
		TIMEOUT,
		OVERFLOW,
		PIPE,
		INTERRUPTED,
		NO_MEM,
		NOT_SUPPORTED,
		OTHER
	}

	[CCode (cname = "enum libusb_transfer_flags", cprefix = "LIBUSB_TRANSFER_", has_type_id = false)]
	public enum TransferFlags {
		SHORT_NOT_OK,
		FREE_BUFFER,
		FREE_TRANSFER
	}

	[CCode (cname = "struct libusb_device_descriptor", has_type_id = false)]
	public struct DeviceDescriptor {
		public uint8 bLength;
		public uint8 bDescriptorType;
		public uint16 bcdUSB;
		public uint8 bDeviceClass;
		public uint8 bDeviceSubClass;
		public uint8 bDeviceProtocol;
		public uint8 bMaxPacketSize0;
		public uint16 idVendor;
		public uint16 idProduct;
		public uint16 bcdDevice;
		public uint8 iManufacturer;
		public uint8 iProduct;
		public uint8 iSerialNumber;
		public uint8 bNumConfigurations;

		[CCode (cname = "libusb_get_device_descriptor", instance_pos = -1)]
		public DeviceDescriptor (Device device);
	}

	[CCode (cname = "struct libusb_endpoint_descriptor", cprefix = "libusb_", has_type_id = false)]
	public struct EndpointDescriptor {
		public uint8 bLength;
		public uint8 bDescriptorType;
		public uint8 bEndpointAddress;
		public uint8 bmAttributes;
		public uint16 wMaxPacketSize;
		public uint8 bInterval;
		public uint8 bRefresh;
		public uint8 bSynchAddress;
		[CCode (array_length_cname = "extra_length")]
		public uint8[] extra;
	}

	[CCode (cname = "struct libusb_interface_descriptor", has_type_id = false)]
	public struct InterfaceDescriptor {
		public uint8 bLength;
		public uint8 bDescriptorType;
		public uint8 bInterfaceNumber;
		public uint8 bAlternateSetting;
		public uint8 bNumEndpoints;
		public uint8 bInterfaceClass;
		public uint8 bInterfaceSubClass;
		public uint8 bInterfaceProtocol;
		public uint8 iInterface;
		[CCode (array_length_cname = "bNumEndpoints", array_length_type = "uint8_t")]
		public EndpointDescriptor[] endpoint;
		[CCode (array_length_cname = "extra_length")]
		public uint8[] extra;
	}

	[CCode (cname = "struct libusb_interface", has_type_id = false)]
	public struct Interface {
		[CCode (array_length_cname = "num_altsetting")]
		public InterfaceDescriptor[] altsetting;
	}

	[Compact, CCode (cname = "struct libusb_config_descriptor", free_function = "libusb_free_config_descriptor")]
	public class ConfigDescriptor {
		public uint8 bLength;
		public uint8 bDescriptorType;
		public uint16 wTotalLength;
		public uint8 bNumInterfaces;
		public uint8 bConfigurationValue;
		public uint8 iConfiguration;
		public uint8 bmAttributes;
		public uint8 MaxPower;
		[CCode (array_length_cname = "bNumInterfaces")]
		public Interface[] @interface;
		[CCode (array_length_cname = "extra_length")]
		public uint8[] extra;
	}


	[Compact, CCode (cname = "libusb_device_handle", cprefix = "libusb_", free_function = "libusb_close")]
	public class DeviceHandle {
		[CCode (cname = "_vala_libusb_device_handle_new")]
		public DeviceHandle (Device device) {
			DeviceHandle handle;
			device.open(out handle);
		}

		[CCode (cname = "libusb_open_device_with_vid_pid")]
		public DeviceHandle.from_vid_pid (Context? context, uint16 vendor_id, uint16 product_id);
		public unowned Device get_device ();
		public int get_configuration (out int config);
		public int set_configuration (int configuration);
		public int claim_interface (int interface_number);
		public int release_interface (int interface_number);
		public int set_interface_alt_setting (int interface_number, int alternate_setting);
		public int clear_halt (uchar endpoint);
		[CCode (cname = "libusb_reset_device")]
		public int reset ();
		public int kernel_driver_active (int @interface);
		public int detach_kernel_driver (int @interface);
		public int attach_kernel_driver (int @interface);

		public int get_string_descriptor_ascii (uint8 desc_index, uint8[] data);
		public int get_descriptor (uint8 desc_type, uint8 desc_index, uint8[] data);
		public int get_string_descriptor (uint desc_index, uint16 langid, uint8[] data);

		public int control_transfer (uint8 bmRequestType, uint8 bRequest, uint16 wValue, uint16 wIndex, [CCode (array_length = false)] uint8[] data, uint16 wLength, uint timeout);
		public int bulk_transfer (uint8 endpoint, uint8[] data, out int transferred, uint timeout);
		public int interrupt_transfer (uint8 endpoint, uint8[] data, out int transferred, uint timeout);
	}

	[Compact, CCode (cname = "libusb_device", cprefix = "libusb_", ref_function = "libusb_ref_device", unref_function = "libusb_unref_device")]
	public class Device {
		public uint8 get_bus_number ();
		public uint8 get_device_address ();
		public int get_max_packet_size (uint8 endpoint);
		public int open (out DeviceHandle handle);

		public int get_active_config_descriptor (out ConfigDescriptor config);
		public int get_config_descriptor (uint8 config_index, out ConfigDescriptor config);
		public int get_config_descriptor_by_value (uint8 ConfigurationValue, out ConfigDescriptor config);
		public int get_device_descriptor (out DeviceDescriptor desc);
	}

	[Compact, CCode (cname = "libusb_context", cprefix = "libusb_", free_function = "libusb_exit")]
	public class Context {
		protected Context ();
		public static int init (out Context context);
		public void set_debug (int level);
		public ssize_t get_device_list ([CCode (array_length = false)] out Device[] list);
		public DeviceHandle open_device_with_vid_pid (uint16 vendor_id, uint16 product_id);

		public int try_lock_events ();
		public void lock_events ();
		public void unlock_events ();
		public int event_handling_ok ();
		public int event_handler_active ();
		public void lock_event_waiters ();
		public void unlock_event_waiters ();
		public int wait_for_event (Posix.timeval tv);
		public int handle_events_timeout (Posix.timeval tv);
		public int handle_events ();
		public int handle_events_locked (Posix.timeval tv);
		public int get_next_timeout (out Posix.timeval tv);
		public void set_pollfd_notifiers (pollfd_added_cb added_cb, pollfd_removed_cb removed_cb, void* user_data);
		[CCode (array_length = false)]
		public unowned PollFD[] get_pollfds ();
	}

	public static uint16 le16_to_cpu (uint16 n);
	public static uint16 cpu_to_le16 (uint16 n);
	[CCode (cname = "malloc", cheader_filename = "stdlib.h")]
	private static void* malloc (ulong n_bytes);

	[Compact, CCode (cname = "struct libusb_control_setup")]
	public class ControlSetup {
		public uint8 bmRequestType;
		public int8 bRequest;
		public uint16 wValue;
		public uint16 wIndex;
		public uint16 wLength;
	}

	[CCode (cname = "enum libusb_transfer_status", cprefix = "LIBUSB_TRANSFER_", has_type_id = false)]
	public enum TransferStatus {
		COMPLETED,
		ERROR,
		TIMED_OUT,
		CANCELLED,
		STALL,
		NO_DEVICE,
		OVERFLOW
	}

	[CCode (cname = "struct libusb_iso_packet_descriptor", has_type_id = false)]
	public struct IsoPacketDescriptor {
		public uint length;
		public uint actual_length;
		public TransferStatus status;
	}

	[CCode (has_target = false)]
	public delegate void transfer_cb_fn (Transfer transfer);

	[Compact, CCode (cname = "struct libusb_transfer", cprefix = "libusb_", free_function = "libusb_free_transfer")]
	public class Transfer {
		public DeviceHandle dev_handle;
		public uint8 flags;
		public uint8 endpoint;
		public uint8 type;
		public uint timeout;
		public TransferStatus status;
		public int length;
		public int actual_length;
		public transfer_cb_fn @callback;
		public void* user_data;
		[CCode (array_length_cname = "length")]
		public uint8[] buffer;
		public int num_iso_packets;
		[CCode (array_length = false)]
		public IsoPacketDescriptor[] iso_packet_desc;

		[CCode (cname = "libusb_alloc_transfer")]
		public Transfer (int iso_packets = 0);
		[CCode (cname = "libusb_submit_transfer")]
		public int submit ();
		[CCode (cname = "libusb_cancel_transfer")]
		public int cancel ();
		[CCode (cname = "libusb_contrel_transfer_get_data", array_length = false)]
		public unowned char[] control_get_data ();
		[CCode (cname = "libusb_control_transfer_get_setup")]
		public unowned ControlSetup control_get_setup ();

		public static void fill_control_setup ([CCode (array_length = false)] uint8[] buffer, uint8 bmRequestType, uint8 bRequest, uint16 wValue, uint16 wIndex, uint16 wLength);
		public void fill_control_transfer (DeviceHandle dev_handle, [CCode (array_length = false)] uint8[] buffer, transfer_cb_fn @callback, void* user_data, uint timeout);
		public void fill_bulk_transfer (DeviceHandle dev_handle, uint8 endpoint, uint8[] buffer, transfer_cb_fn @callback, void* user_data, uint timeout);
		public void fill_interrupt_transfer (DeviceHandle dev_handle, uint8 endpoint, uint8[] buffer, transfer_cb_fn @callback, void* user_data, uint timeout);
		public void fill_iso_transfer (DeviceHandle dev_handle, uint8 endpoint, uint8[] buffer, int num_iso_packets, transfer_cb_fn @callback, void* user_data, uint timeout);
		public void set_packet_lengths (uint length);
		[CCode (array_length = false)]
		public unowned uint8[] get_iso_packet_buffer (uint packet);
		[CCode (array_length = false)]
		public unowned uint8[] get_iso_packet_buffer_simple (int packet);
	}

	[CCode (has_target = false)]
	public delegate void pollfd_added_cb (int fd, short events, void* user_data);
	[CCode (has_target = false)]
	public delegate void pollfd_removed_cb (int fd, void* user_data);

	[Compact, CCode (cname = "struct libusb_pollfd")]
	public class PollFD {
		public int fd;
		public short events;
	}
}
