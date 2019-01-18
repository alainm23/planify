/* gnutls.vapi
 *
 * Copyright (C) 2009  Jiří Zárevúcky
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * As a special exception, if you use inline functions from this file, this
 * file does not by itself cause the resulting executable to be covered by
 * the GNU Lesser General Public License.
 *
 * Author:
 * 	Jiří Zárevúcky <zarevucky.jiri@gmail.com>
 *
 */

[CCode (cprefix = "gnutls_", lower_case_cprefix = "gnutls_", cheader_filename = "gnutls/gnutls.h")]
namespace GnuTLS
{
	[CCode (cname = "LIBGNUTLS_VERSION")]
	public const string VERSION;
	[CCode (cname = "LIBGNUTLS_VERSION_MAJOR")]
	public const int VERSION_MAJOR;
	[CCode (cname = "LIBGNUTLS_VERSION_MINOR")]
	public const int VERSION_MINOR;
	[CCode (cname = "LIBGNUTLS_VERSION_PATCH")]
	public const int VERSION_PATCH;
	[CCode (cname = "LIBGNUTLS_VERSION_NUMBER")]
	public const int VERSION_NUMBER;

	public unowned string? check_version (string? req_version);

	[CCode (cname = "gnutls_cipher_algorithm_t", cprefix = "GNUTLS_CIPHER_", has_type_id = false)]
	public enum CipherAlgorithm {
		UNKNOWN,
		NULL,
		ARCFOUR_128,
		3DES_CBC,
		AES_128_CBC,
		AES_256_CBC,
		ARCFOUR_40,
		CAMELLIA_128_CBC,
		CAMELLIA_256_CBC,
		RC2_40_CBC,
		DES_CBC,

		RIJNDAEL_128_CBC,    // == AES_128_CBC
		RIJNDAEL_256_CBC,    // == AES_256_CBC
		RIJNDAEL_CBC,        // == AES_128_CBC
		ARCFOUR;             // == ARCFOUR_128

		[CCode (cname = "gnutls_cipher_get_key_size")]
		public size_t get_key_size ();
		[CCode (cname = "gnutls_cipher_get_name")]
		public unowned string? get_name ();
		[CCode (cname = "gnutls_mac_get_id")]
		public static CipherAlgorithm from_name (string name);
		[CCode (cname = "gnutls_cipher_list", array_length = "false", array_null_terminated = "true")]
		public static unowned CipherAlgorithm[] list ();
	}

	[CCode (cname = "gnutls_kx_algorithm_t", cprefix = "GNUTLS_KX_", has_type_id = false)]
	public enum KXAlgorithm	{
		UNKNOWN,
		RSA,
		DHE_DSS,
		DHE_RSA,
		ANON_DH,
		SRP,
		RSA_EXPORT,
		SRP_RSA,
		SRP_DSS,
		PSK,
		DHE_PSK;

		[CCode (cname = "gnutls_kx_get_name")]
		public unowned string? get_name ();
		[CCode (cname = "gnutls_kx_get_id")]
		public static KXAlgorithm from_name (string name);
		[CCode (cname = "gnutls_kx_list", array_length = "false", array_null_terminated = "true")]
		public static unowned KXAlgorithm[] list ();
	}

	[CCode (cname = "gnutls_mac_algorithm_t", cprefix = "GNUTLS_MAC_", has_type_id = false)]
	public enum MacAlgorithm {
		UNKNOWN,
		NULL,
		MD5,
		SHA1,
		RMD160,
		MD2,
		SHA256,
		SHA384,
		SHA512;

		[CCode (cname = "gnutls_mac_get_key_size")]
		public size_t get_key_size ();
		[CCode (cname = "gnutls_mac_get_name")]
		public unowned string? get_name ();
		[CCode (cname = "gnutls_mac_get_id")]
		public static MacAlgorithm from_name (string name);
		[CCode (cname = "gnutls_mac_list", array_length = "false", array_null_terminated = "true")]
		public static unowned MacAlgorithm[] list ();
	}

	[CCode (cname = "gnutls_digest_algorithm_t", cprefix = "GNUTLS_DIG_", has_type_id = false)]
	public enum DigestAlgorithm {
		NULL,
		MD5,
		SHA1,
		RMD160,
		MD2,
		SHA224,
		SHA256,
		SHA384,
		SHA512;

		[CCode (cname = "gnutls_fingerprint")]
		public int fingerprint (/* const */ ref Datum data, void* result, ref size_t result_size);
	}

	[CCode (cname = "GNUTLS_MAX_ALGORITHM_NUM")]
	public const int MAX_ALGORITHM_NUM;

	[CCode (cname = "gnutls_pk_algorithm_t", cprefix = "GNUTLS_PK_", has_type_id = false)]
	public enum PKAlgorithm {
		UNKNOWN,
		RSA,
		DSA;

		[CCode (cname = "gnutls_pk_algorithm_get_name")]
		public unowned string? get_name ();
	}

	[CCode (cname = "gnutls_sign_algorithm_t", cprefix = "GNUTLS_SIGN_", has_type_id = false)]
	public enum SignAlgorithm {
		UNKNOWN,
		RSA_SHA1,
		DSA_SHA1,
		RSA_MD5,
		RSA_MD2,
		RSA_RMD160,
		RSA_SHA224,
		RSA_SHA256,
		RSA_SHA384,
		RSA_SHA512;

		[CCode (cname = "gnutls_sign_algorithm_get_name")]
		public unowned string? get_name ();
	}

	[CCode (cname = "gnutls_compression_method_t", cprefix = "GNUTLS_COMP_", has_type_id = false)]
	public enum CompressionMethod {
		UNKNOWN,
		NULL,
		DEFLATE,
		ZLIB,     // == DEFLATE
		LZO;      // only available if gnutls-extra has been initialized

		[CCode (cname = "gnutls_compression_get_name")]
		public unowned string? get_name ();
		[CCode (cname = "gnutls_compression_get_id")]
		public static CompressionMethod from_name (string name);
		[CCode (cname = "gnutls_compression_list", array_length = "false", array_null_terminated = "true")]
		public static unowned CompressionMethod[] list ();
	}

	[CCode (cname = "gnutls_params_type_t", cprefix = "GNUTLS_PARAMS_", has_type_id = false)]
	public enum ParamsType {
		RSA_EXPORT,
		DH
	}

	[CCode (cname = "gnutls_credentials_type_t", cprefix = "GNUTLS_CRD_", has_type_id = false)]
	public enum CredentialsType {
		CERTIFICATE,
		ANON,
		SRP,
		PSK,
		IA
	}

	[CCode (cname = "gnutls_alert_level_t", cprefix = "GNUTLS_AL_", has_type_id = false)]
	public enum AlertLevel {
		WARNING,
		FATAL
	}

	[CCode (cname = "gnutls_alert_description_t", cprefix = "GNUTLS_A_", has_type_id = false)]
	public enum AlertDescription {
		CLOSE_NOTIFY,
		UNEXPECTED_MESSAGE,
		BAD_RECORD_MAC,
		DECRYPTION_FAILED,
		RECORD_OVERFLOW,
		DECOMPRESSION_FAILURE,
		HANDSHAKE_FAILURE,
		SSL3_NO_CERTIFICATE,
		BAD_CERTIFICATE,
		UNSUPPORTED_CERTIFICATE,
		CERTIFICATE_REVOKED,
		CERTIFICATE_EXPIRED,
		CERTIFICATE_UNKNOWN,
		ILLEGAL_PARAMETER,
		UNKNOWN_CA,
		ACCESS_DENIED,
		DECODE_ERROR,
		DECRYPT_ERROR,
		EXPORT_RESTRICTION,
		PROTOCOL_VERSION,
		INSUFFICIENT_SECURITY,
		INTERNAL_ERROR,
		USER_CANCELED,
		NO_RENEGOTIATION,
		UNSUPPORTED_EXTENSION,
		CERTIFICATE_UNOBTAINABLE,
		UNRECOGNIZED_NAME,
		UNKNOWN_PSK_IDENTITY,
		INNER_APPLICATION_FAILURE,
		INNER_APPLICATION_VERIFICATION;

		[CCode (cname = "gnutls_alert_get_name")]
		public unowned string? get_name ();
	}

	[CCode (cname = "gnutls_handshake_description_t", cprefix = "GNUTLS_HANDSHAKE_", has_type_id = false)]
	public enum HandshakeDescription {
		HELLO_REQUEST,
		CLIENT_HELLO,
		SERVER_HELLO,
		CERTIFICATE_PKT,
		SERVER_KEY_EXCHANGE,
		CERTIFICATE_REQUEST,
		SERVER_HELLO_DONE,
		CERTIFICATE_VERIFY,
		CLIENT_KEY_EXCHANGE,
		FINISHED,
		SUPPLEMENTAL
	}

	/* Note that the status bits have different meanings
	 * in openpgp keys and x.509 certificate verification.
	 */
	[Flags]
	[CCode (cname = "gnutls_certificate_status_t", cprefix = "GNUTLS_CERT_", has_type_id = false)]
	public enum CertificateStatus {
		INVALID,             // will be set if the certificate was not verified.
		REVOKED,             // in X.509 this will be set only if CRLs are checked
		SIGNER_NOT_FOUND,
		SIGNER_NOT_CA,
		INSECURE_ALGORITHM
	}

	[CCode (cname = "gnutls_certificate_request_t", cprefix = "GNUTLS_CERT_", has_type_id = false)]
	public enum CertificateRequest {
		IGNORE,
		REQUEST,
		REQUIRE
	}

//	[CCode (cname = "gnutls_openpgp_crt_status_t", cprefix = "GNUTLS_OPENPGP_", has_type_id = false)]
//	public enum OpenPGP.CertificateStatus {
//		CERT,
//		CERT_FINGERPRINT
//	}
//
//	[CCode (cname = "gnutls_connection_end_t", cprefix = "GNUTLS_", has_type_id = false)]
//	public enum ConnectionEnd {
//		SERVER,
//		CLIENT
//	}

	[CCode (cname = "gnutls_close_request_t", cprefix = "GNUTLS_SHUT_", has_type_id = false)]
	public enum CloseRequest {
		RDWR,
		WR
	}

	[CCode (cname = "gnutls_protocol_t", cprefix = "GNUTLS_", has_type_id = false)]
	public enum Protocol {
		SSL3,
		TLS1,    // == TLS1_0
		TLS1_0,
		TLS1_1,
		TLS1_2,
		[CCode (cname = "GNUTLS_VERSION_UNKNOWN")]
		UNKNOWN;

		[CCode (cname = "gnutls_protocol_get_name")]
		public unowned string? get_name ();
		[CCode (cname = "gnutls_protocol_get_id")]
		public static Protocol from_name (string name);
		[CCode (cname = "gnutls_protocol_list", array_length = "false", array_null_terminated = "true")]
		public static unowned Protocol[] list ();
	}

	[CCode (cname = "gnutls_certificate_type_t", cprefix = "GNUTLS_CRT_", has_type_id = false)]
	public enum CertificateType {
		UNKNOWN,
		X509,
		OPENPGP;

		[CCode (cname = "gnutls_certificate_type_get_name")]
		public unowned string? get_name ();
		[CCode (cname = "gnutls_certificate_type_get_id")]
		public static CertificateType from_name (string name);
		[CCode (cname = "gnutls_certificate_type_list", array_length = "false", array_null_terminated = "true")]
		public static unowned CertificateType[] list ();
	}

	[CCode (cname = "gnutls_certificate_print_formats_t", cprefix = "GNUTLS_CRT_PRINT_", has_type_id = false)]
	public enum CertificatePrintFormats {
		FULL,
		ONELINE,
		UNSIGNED_FULL
	}

	[Flags]
	[CCode (cname = "unsigned int", cprefix = "GNUTLS_KEY_", has_type_id = false)]
	public enum KeyUsage
	{
		DIGITAL_SIGNATURE,
		NON_REPUDIATION,
		KEY_ENCIPHERMENT,
		DATA_ENCIPHERMENT,
		KEY_AGREEMENT,
		KEY_CERT_SIGN,
		CRL_SIGN,
		ENCIPHER_ONLY,
		DECIPHER_ONLY
	}

	[CCode (cname = "gnutls_server_name_type_t", cprefix = "GNUTLS_NAME_", has_type_id = false)]
	public enum ServerNameType {
		DNS;
	}

	// Diffie Hellman parameter handling.
	[Compact]
	[CCode (cname = "struct gnutls_dh_params_int", free_function = "gnutls_dh_params_deinit", lower_case_cprefix = "gnutls_dh_params_")]
	public class DHParams {
		private static int init (out DHParams dh_params);
		public static DHParams create ()
		{
			DHParams result;
			var ret = init (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}

		private int cpy (DHParams source);

		public int import_raw (/* const */ ref Datum prime, /* const */ ref Datum generator);
		public int export_raw (/* const */ ref Datum prime, /* const */ ref Datum generator, out uint bits);
		public int import_pkcs3 (/* const */ ref Datum pkcs3_params, X509.CertificateFormat format);
		public int export_pkcs3 (X509.CertificateFormat format, void* params_data, ref size_t params_data_size);

		[CCode (cname = "gnutls_dh_params_generate2")]
		public int generate (uint bits);
	}

	[Compact]
	[CCode (cname = "struct gnutls_x509_privkey_int", free_function = "gnutls_rsa_params_deinit", lower_case_cprefix = "gnutls_rsa_params_")]
	public class RSAParams {
		private static int init (out RSAParams dh_params);
		public static RSAParams create ()
		{
			RSAParams result = null;
			var ret = init (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}

		private int cpy (RSAParams source);

		public int import_raw (/* const */ ref Datum m, /* const */ ref Datum e, /* const */ ref Datum d, /* const */ ref Datum p, /* const */ ref Datum q, /* const */ ref Datum u);
		public int export_raw (/* const */ ref Datum m, /* const */ ref Datum e, /* const */ ref Datum d, /* const */ ref Datum p, /* const */ ref Datum q, /* const */ ref Datum u, out uint bits);
		public int import_pkcs1 (/* const */ ref Datum pkcs1_params, X509.CertificateFormat format);
		public int export_pkcs1 (X509.CertificateFormat format, void* params_data, ref size_t params_data_size);

		public int generate2 (uint bits);
	}

	[Compact]
	[CCode (cname = "struct gnutls_priority_st", free_function = "gnutls_priority_deinit")]
	public class Priority {
		private static int init (out Priority self, string priority, out char* err_pos);
		public static Priority create (string priority, out ErrorCode err = null, out char* err_pos = null)
		{
			Priority result;
			var ret = init (out result, priority, out err_pos);
			if (&err != null)
				err = (ErrorCode) ret;
			return result;
		}
	}

	[SimpleType]
	[CCode (cname = "gnutls_datum_t", has_type_id = false)]
	public struct Datum {
		public void* data;
		public uint size;
	}

	[CCode (cname = "gnutls_params_st", has_type_id = false)]
	public struct Params {
		public ParamsType type;
		[CCode (cname = "params.dh")]
		public DHParams dh_params;
		[CCode (cname = "params.rsa_export")]
		public RSAParams rsa_params;
		public bool deinit;
	}

	[CCode (cname = "gnutls_params_function *", has_target = false)]
	public delegate int ParamsFunction (Session session, ParamsType type, Params params);

	[CCode (cname = "gnutls_oprfi_callback_func", instance_pos = "1.2")]
	public delegate int OprfiCallbackFunc (Session session,
	                                       [CCode (array_length_pos = "1.8", array_length_type = "size_t")] /* const */ uint8[] in_oprfi,
	                                       [CCode (array_length_pos = "1.8", array_length_type = "size_t")] uint8[] out_oprfi);

	/* Supplemental data, RFC 4680. */
	[CCode (cname = "gnutls_supplemental_data_format_type_t", has_type_id = false)]
	public enum SupplementalDataFormatType {
		USER_MAPPING_DATA;

		[CCode (cname = "gnutls_supplemental_get_name")]
		public unowned string? get_name ();
	}

	[CCode (cname = "TLS_MASTER_SIZE")]
	public const int TLS_MASTER_SIZE;
	[CCode (cname = "TLS_RANDOM_SIZE")]
	public const int TLS_RANDOM_SIZE;

	[CCode (cname = "gnutls_db_store_func", has_target = false)]
	public delegate int DBStoreFunc (void* ptr, Datum key, Datum data);
	[CCode (cname = "gnutls_db_remove_func", has_target = false)]
	public delegate int DBRemoveFunc (void* ptr, Datum key);
	[CCode (cname = "gnutls_db_retr_func", has_target = false)]
	public delegate Datum DBRetrieveFunc (void* ptr, Datum key);

	[CCode (cname = "gnutls_handshake_post_client_hello_func", has_target = false)]
	public delegate int HandshakePostClientHelloFunc (Session session);

	// External signing callback.  Experimental.
	[CCode (cname = "gnutls_sign_func", instance_pos = "1.9")]
	public delegate int SignFunc (Session session, CertificateType cert_type, /* const */ ref Datum cert, /* const */ ref Datum hash, out Datum signature);

	[CCode (cname = "gnutls_pull_func", has_target = false)]
	public delegate ssize_t PullFunc (void* transport_ptr, void* buffer, size_t count);
	[CCode (cname = "gnutls_push_func", has_target = false)]
	public delegate ssize_t PushFunc (void* transport_ptr, void* buffer, size_t count);

	[Compact]
	[CCode (cname = "struct gnutls_session_int", free_function = "gnutls_deinit")]
	public class Session {
		[CCode (cname = "gnutls_init")]
		private static int init (out Session session, int con_end);
		protected static Session? create (int con_end)
		{
			Session result;
			var ret = init (out result, con_end);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}

		[CCode (cname = "gnutls_credentials_set")]
		public int set_credentials (CredentialsType type, void* cred);
		[CCode (cname = "gnutls_credentials_clear")]
		public void clear_credentials ();

		[CCode (cname = "gnutls_handshake")]
		public int handshake ();
		[CCode (cname = "gnutls_bye")]
		public int bye (CloseRequest how);

		[CCode (cname = "gnutls_session_is_resumed")]
		public bool is_resumed ();

		[CCode (cname = "gnutls_alert_get")]
		public AlertDescription get_last_alert ();
		[CCode (cname = "gnutls_alert_send")]
		public int send_alert (AlertLevel level, AlertDescription desc);
		[CCode (cname = "gnutls_alert_send_appropriate")]
		public int send_appropriate_alert (ErrorCode err);

		[CCode (cname = "gnutls_cipher_get")]
		public CipherAlgorithm get_cipher ();
		[CCode (cname = "gnutls_kx_get")]
		public KXAlgorithm get_kx ();
		[CCode (cname = "gnutls_mac_get")]
		public MacAlgorithm get_mac ();
		[CCode (cname = "gnutls_compression_get")]
		public CompressionMethod get_compression ();
		[CCode (cname = "gnutls_certificate_type_get")]
		public CertificateType get_certificate_type ();
		[CCode (cname = "gnutls_protocol_get_version")]
		public Protocol get_protocol_version ();
		[CCode (cname = "gnutls_record_get_max_size")]
		public size_t get_max_record_size ();
		[CCode (cname = "gnutls_dh_get_prime_bits")]
		public int get_dh_prime_bits ();
		[CCode (cname = "gnutls_dh_get_secret_bits")]
		public int get_dh_secret_bits ();
		[CCode (cname = "gnutls_dh_get_peers_public_bits")]
		public int get_peers_dh_public_bits ();
		[CCode (cname = "gnutls_dh_get_group")]
		public int get_dh_group (out Datum raw_gen, out Datum raw_prime);
		[CCode (cname = "gnutls_dh_get_pubkey")]
		public int get_dh_pubkey (out Datum raw_key);
		[CCode (cname = "gnutls_rsa_export_get_pubkey")]
		public int get_rsa_export_pubkey (out Datum exponent, out Datum modulus);
		[CCode (cname = "gnutls_rsa_export_get_modulus_bits")]
		public int get_rsa_export_modulus_bits ();

		[CCode (cname = "gnutls_handshake_set_private_extensions")]
		public void allow_private_extensions (bool allow);
		[CCode (cname = "gnutls_handshake_get_last_out")]
		public HandshakeDescription get_last_out_handshake ();
		[CCode (cname = "gnutls_handshake_get_last_in")]
		public HandshakeDescription get_last_in_handshake ();

		[CCode (cname = "gnutls_record_send")]
		public ssize_t send (void* buffer, size_t count);
		[CCode (cname = "gnutls_record_recv")]
		public ssize_t receive (void* buffer, size_t count);

		[CCode (cname = "gnutls_record_get_direction")]
		public int get_last_direction ();

		[CCode (cname = "gnutls_record_check_pending")]
		public size_t check_pending ();

		[CCode (cname = "gnutls_cipher_set_priority")]
		public int set_cipher_priority ([CCode (array_length = "false", array_null_terminated = "true")] CipherAlgorithm[] list);
		[CCode (cname = "gnutls_mac_set_priority")]
		public int set_mac_priority ([CCode (array_length = "false", array_null_terminated = "true")] MacAlgorithm[] list);
		[CCode (cname = "gnutls_compression_set_priority")]
		public int set_compression_priority ([CCode (array_length = "false", array_null_terminated = "true")] CompressionMethod[] list);
		[CCode (cname = "gnutls_kx_set_priority")]
		public int set_kx_priority ([CCode (array_length = "false", array_null_terminated = "true")] KXAlgorithm[] list);
		[CCode (cname = "gnutls_protocol_set_priority")]
		public int set_protocol_priority ([CCode (array_length = "false", array_null_terminated = "true")] Protocol[] list);
		[CCode (cname = "gnutls_certificate_type_set_priority")]
		public int set_certificate_type_priority ([CCode (array_length = "false", array_null_terminated = "true")] CertificateType[] list);

		[CCode (cname = "gnutls_priority_set")]
		public int set_priority (Priority priority);
		[CCode (cname = "gnutls_priority_set_direct")]
		public int set_priority_from_string (string priority, out unowned string err_pos = null);
		[CCode (cname = "gnutls_set_default_priority")]
		public int set_default_priority ();
		[CCode (cname = "gnutls_set_default_export_priority")]
		public int set_default_export_priority ();

		[CCode (cname = "GNUTLS_MAX_SESSION_ID")]
		public const int MAX_SESSION_ID;

		[CCode (cname = "gnutls_session_get_id")]
		public int get_id (void* session_id, ref size_t session_id_size);

		[CCode (cname = "gnutls_session_get_server_random")]
		public void* get_server_random ();
		[CCode (cname = "gnutls_session_get_client_random")]
		public void* get_client_random ();
		[CCode (cname = "gnutls_session_get_master_secret")]
		public void* get_master_secret ();

		[CCode (cname = "gnutls_transport_set_ptr")]
		public void set_transport_ptr (void* ptr);
		[CCode (cname = "gnutls_transport_set_ptr2")]
		public void set_transport_ptr2 (void* recv_ptr, void* send_ptr);
		[CCode (cname = "gnutls_transport_set_lowat")]
		public void set_lowat (int num);
		[CCode (cname = "gnutls_transport_set_push_function")]
		public void set_push_function (PushFunc func);
		[CCode (cname = "gnutls_transport_set_pull_function")]
		public void set_pull_function (PullFunc func);

		[CCode (cname = "gnutls_transport_set_errno")]
		public void set_errno (int err);

		[CCode (cname = "gnutls_session_set_ptr")]
		public void set_ptr (void* ptr);
		[CCode (cname = "gnutls_session_get_ptr")]
		public void* get_ptr ();

		[CCode (cname = "gnutls_auth_get_type")]
		public CredentialsType get_auth_type ();
	//	[CCode (cname = "gnutls_auth_server_get_type")]
	//	public CredentialsType get_server_auth_type ();
	//	[CCode (cname = "gnutls_auth_client_get_type")]
	//	public CredentialsType get_client_auth_type ();

		[CCode (cname = "gnutls_sign_callback_set")]
		public void set_sign_callback (SignFunc func);
		[CCode (cname = "gnutls_sign_callback_get")]
		public SignFunc get_sign_callback ();

		[CCode (cname = "gnutls_certificate_get_peers", array_length_type = "unsigned int")]
		public unowned Datum[]? get_peer_certificates ();
		[CCode (cname = "gnutls_certificate_get_ours")]
		public unowned Datum? get_our_certificate ();

		[CCode (cname = "gnutls_certificate_verify_peers2")]
		public int verify_peer_certificate (out CertificateStatus status);
	}

	[CCode (cname = "struct gnutls_session_int", lower_case_cprefix = "gnutls_", free_function = "gnutls_deinit")]
	public class ClientSession: Session {

		public static ClientSession create ()
		{
			return (ClientSession) Session.create (2);
		}

		[CCode (cname = "gnutls_record_set_max_size")]
		public ssize_t set_max_record_size (size_t size);

		[CCode (cname = "gnutls_dh_set_prime_bits")]
		public void set_dh_prime_bits (uint bits);

		[CCode (cname = "gnutls_server_name_get")]
		public int get_server_name (void* data, out size_t data_length, out ServerNameType type, uint index);

		[CCode (cname = "gnutls_oprfi_enable_client")]
		public void enable_oprfi ([CCode (array_length_pos = "0.9", array_length_type = "size_t")] uint8[] data);

		[CCode (cname = "gnutls_session_set_data")]
		public int set_session_data (void* session_data, size_t session_data_size);
		[CCode (cname = "gnutls_session_get_data")]
		public int get_session_data (void* session_data, out size_t session_data_size);
		[CCode (cname = "gnutls_session_get_data2")]
		public int get_session_data2 (out Datum data);

		[CCode (cname = "gnutls_openpgp_send_cert")]
		public void set_openpgp_send_cert (bool fingerprint_only);

		[CCode (cname = "gnutls_psk_client_get_hint")]
		public unowned string get_psk_hint ();

		[CCode (cname = "gnutls_certificate_client_get_request_status")]
		public int get_certificate_request_status ();
	}

	[CCode (cname = "struct gnutls_session_int", lower_case_cprefix = "gnutls_", free_function = "gnutls_deinit")]
	public class ServerSession: Session {

		public static ServerSession create ()
		{
			return (ServerSession) Session.create (1);
		}

		public int rehandshake ();

		[CCode (cname = "gnutls_session_enable_compatibility_mode")]
		public void enable_compatibility_mode ();

		[CCode (cname = "gnutls_record_disable_padding")]
		public void disable_record_padding ();

		[CCode (cname = "gnutls_server_name_set")]
		public int set_server_name (ServerNameType type, void* data, size_t data_length);

		[CCode (cname = "gnutls_oprfi_enable_server")]
		public void enable_oprfi (OprfiCallbackFunc cb);

		public void db_set_cache_expiration (int seconds);
		public void db_remove_session ();
		public void db_set_retrieve_function (DBRetrieveFunc func);
		public void db_set_remove_function (DBRemoveFunc func);
		public void db_set_store_function (DBStoreFunc func);
		public void db_set_ptr (void* ptr);
		public void* db_get_ptr ();
		public int db_check_entry (Datum session_entry);

		[CCode (cname = "gnutls_handshake_set_post_client_hello_function")]
		public void set_post_client_hello_function (HandshakePostClientHelloFunc func);

		[CCode (cname = "gnutls_handshake_set_max_packet_length")]
		public void set_max_handshake_packet_length (size_t max);

		[CCode (cname = "gnutls_certificate_server_set_request")]
		public void set_certificate_request (CertificateRequest req);

		[CCode (cname = "gnutls_certificate_send_x509_rdn_sequence")]
		public void disable_sending_x509_rdn_sequence (bool disable);

		[CCode (cname = "gnutls_psk_server_get_username")]
		public unowned string get_psk_username ();

		[CCode (cheader_filename = "gnutls/openpgp.h", cname = "gnutls_openpgp_set_recv_key_function")]
		public void set_openpgp_recv_key_function (OpenPGP.RecvKeyFunc func);
	}


	[Compact]
	[CCode (cname = "struct gnutls_anon_server_credentials_st", free_function = "gnutls_anon_free_server_credentials")]
	public class AnonServerCredentials
	{
		[CCode (cname = "gnutls_anon_allocate_server_credentials")]
		private static int allocate (out AnonServerCredentials credentials);
		public static AnonServerCredentials create ()
		{
			AnonServerCredentials result;
			var ret = allocate (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}


		[CCode (cname = "gnutls_anon_set_server_dh_params")]
		public void set_dh_params (DHParams dh_params);

	//	[CCode (cname = "gnutls_anon_set_server_params_function")]
	//	public void set_server_params_function (ParamsFunction func);

		[CCode (cname = "gnutls_anon_set_params_function")]
		public void set_params_function (ParamsFunction func);
	}

	[Compact]
	[CCode (cname = "struct gnutls_anon_client_credentials_st", free_function = "gnutls_anon_free_client_credentials")]
	public class AnonClientCredentials
	{
		[CCode (cname = "gnutls_anon_allocate_client_credentials")]
		private static int allocate (out AnonClientCredentials credentials);
		public static AnonClientCredentials create ()
		{
			AnonClientCredentials result;
			var ret = allocate (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}
	}

	[CCode (cheader_filename = "gnutls/x509.h", cprefix = "GNUTLS_")]
	namespace X509
	{
		// Some OIDs usually found in Distinguished names, or
		// in Subject Directory Attribute extensions.

		public const string OID_X520_COUNTRY_NAME;
		public const string OID_X520_ORGANIZATION_NAME;
		public const string OID_X520_ORGANIZATIONAL_UNIT_NAME;
		public const string OID_X520_COMMON_NAME;
		public const string OID_X520_LOCALITY_NAME;
		public const string OID_X520_STATE_OR_PROVINCE_NAME;

		public const string OID_X520_INITIALS;
		public const string OID_X520_GENERATION_QUALIFIER;
		public const string OID_X520_SURNAME;
		public const string OID_X520_GIVEN_NAME;
		public const string OID_X520_TITLE;
		public const string OID_X520_DN_QUALIFIER;
		public const string OID_X520_PSEUDONYM;

		public const string OID_LDAP_DC;
		public const string OID_LDAP_UID;

		// The following should not be included in DN.

		public const string OID_PKCS9_EMAIL;

		public const string OID_PKIX_DATE_OF_BIRTH;
		public const string OID_PKIX_PLACE_OF_BIRTH;
		public const string OID_PKIX_GENDER;
		public const string OID_PKIX_COUNTRY_OF_CITIZENSHIP;
		public const string OID_PKIX_COUNTRY_OF_RESIDENCE;

		// Key purpose Object Identifiers.

		public const string KP_TLS_WWW_SERVER;
		public const string KP_TLS_WWW_CLIENT;
		public const string KP_CODE_SIGNING;
		public const string KP_EMAIL_PROTECTION;
		public const string KP_TIME_STAMPING;
		public const string KP_OCSP_SIGNING;
		public const string KP_ANY;


		[CCode (cname = "gnutls_x509_crt_fmt_t", cprefix = "GNUTLS_X509_FMT_", has_type_id = false)]
		public enum CertificateFormat {
			DER,
			PEM
		}

		[Flags]
		[CCode (cname = "gnutls_certificate_import_flags", cprefix = "GNUTLS_X509_CRT_", has_type_id = false)]
		public enum CertificateImportFlags {
			/* Fail if the certificates in the buffer are more than the space
			* allocated for certificates. The error code will be
			* GNUTLS_E_SHORT_MEMORY_BUFFER.
			*/
			LIST_IMPORT_FAIL_IF_EXCEED    // == 1
		}

		[Flags]
		[CCode (cname = "unsigned int", cprefix = "GNUTLS_CRL_REASON_", has_type_id = false)]
		public enum RevocationReasons {
			UNUSED,
			KEY_COMPROMISE,
			CA_COMPROMISE,
			AFFILIATION_CHANGED,
			SUPERSEEDED,
			CESSATION_OF_OPERATION,
			CERTIFICATE_HOLD,
			PRIVILEGE_WITHDRAWN,
			AA_COMPROMISE
		}

		[Flags]
		[CCode (cname = "gnutls_certificate_verify_flags", cprefix = "GNUTLS_VERIFY_", has_type_id = false)]
		public enum CertificateVerifyFlags
		{
			// If set a signer does not have to be a certificate authority. This
			// flag should normaly be disabled, unless you know what this means.
			DISABLE_CA_SIGN,

			// Allow only trusted CA certificates that have version 1.  This is
			// safer than GNUTLS_VERIFY_ALLOW_ANY_X509_V1_CA_CRT, and should be
			// used instead. That way only signers in your trusted list will be
			// allowed to have certificates of version 1.
			ALLOW_X509_V1_CA_CRT,

			// If a certificate is not signed by anyone trusted but exists in
			// the trusted CA list do not treat it as trusted.
			DO_NOT_ALLOW_SAME,

			// Allow CA certificates that have version 1 (both root and
			// intermediate). This might be dangerous since those haven't the
			// basicConstraints extension. Must be used in combination with
			// GNUTLS_VERIFY_ALLOW_X509_V1_CA_CRT.
			ALLOW_ANY_X509_V1_CA_CRT,

			// Allow certificates to be signed using the broken MD2 algorithm.
			ALLOW_SIGN_RSA_MD2,

			// Allow certificates to be signed using the broken MD5 algorithm.
			ALLOW_SIGN_RSA_MD5
		}

		[CCode (cname = "gnutls_x509_subject_alt_name_t", has_type_id = false)]
		public enum SubjectAltName {
			DNSNAME,
			RFC822NAME,
			URI,
			IPADDRESS,
			OTHERNAME,
			DN,

			OTHERNAME_XMPP
		}

		[Compact]
		[CCode (cname = "void", cprefix = "gnutls_x509_dn_", free_function = "gnutls_x509_dn_deinit")]
		public class DN
		{
			private static int init (out DN dn);
			public static DN create ()
			{
				DN result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int get_rdn_ava (int irdn, int iava, out unowned Ava ava);

			public int import (ref Datum data);
			public int export (CertificateFormat format, void* output, ref size_t output_size);

		}

		// RDN handling.
		public int rdn_get (ref Datum idn, char* buf, ref size_t buf_size);
		public int rdn_get_oid (ref Datum idn, int index, void* buf, ref size_t buf_size);
		public int rdn_get_by_oid (ref Datum idn, string oid, int index, uint raw_flag, void* buf, ref size_t buf_size);

		[SimpleType]
		[CCode (cname = "gnutls_x509_ava_st", has_type_id = false)]
		public struct Ava
		{
			[CCode (cname = "oid.data", array_length_cname = "oid.size")]
			uint8[] oid;
			[CCode (cname = "value.data", array_length_cname = "value.size")]
			uint8[] value;
			ulong value_tag;
		}

		[Compact]
		[CCode (cname = "struct gnutls_x509_crt_int", cprefix = "gnutls_x509_crt_", free_function = "gnutls_x509_crt_deinit")]
		public class Certificate
		{
			private static int init (out Certificate cert);
			public static Certificate create ()
			{
				Certificate result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int import (ref Datum data, CertificateFormat format);
			public int export (CertificateFormat format, void* output, ref size_t output_size);

			public static int list_import ([CCode (array_length = "false")] Certificate[]? certs,
			                               ref uint cert_max, ref Datum data,
			                               CertificateFormat format, bool fail_if_exceed);



			public int get_issuer_dn (char* buf, ref size_t buf_size);
			public int get_issuer_dn_oid (int index, void* oid, ref size_t oid_size);
			public int get_issuer_dn_by_oid (string oid, int index, uint raw_flag, void* buf, ref size_t buf_size);

			public int get_dn (char* buf, ref size_t buf_size);
			public int get_dn_oid (int index, void* oid, ref size_t oid_size);
			public int get_dn_by_oid (string oid, int index, uint raw_flag, void* buf, ref size_t buf_size);


			public int get_subject (out DN dn);
			public int get_issuer (out DN dn);

			public bool check_hostname (string hostname);

			public SignAlgorithm get_signature_algorithm ();

			public int get_signature (char* sig, ref size_t sig_size);

			public int get_version ();

			public int get_key_id (uint flags, uchar* output, ref size_t output_size);

			public int set_authority_key_id (void* id, size_t id_size);
			public int get_authority_key_id (void* ret, ref size_t ret_size, out bool critical);

			public int get_subject_key_id (void* ret, ref size_t ret_size, out bool critical);

			public int get_crl_dist_points (uint seq, void* ret, ref size_t ret_size, out RevocationReasons reason_flags, out bool critical);
			public int set_crl_dist_points (SubjectAltName type, void* data_string, RevocationReasons reason_flags);
			public int cpy_crl_dist_points (Certificate source);

			public time_t get_activation_time ();
			public time_t get_expiration_time ();

			public int get_serial (void* result, ref size_t result_size);

			public PKAlgorithm get_pk_algorithm (out uint bits);
			public int get_pk_rsa_raw (out Datum modulus, out Datum exponent);
			public int get_pk_dsa_raw (out Datum p, out Datum q, out Datum g, out Datum y);

			public int get_subject_alt_name (uint seq, void* ret, ref size_t ret_size, out bool critical);
			public int get_subject_alt_name2 (uint seq, void* ret, ref size_t ret_size, out SubjectAltName ret_type, out bool critical);

			public int get_subject_alt_othername_oid (uint seq, void* ret, ref size_t ret_size);

			public int get_ca_status (out bool critical);

			public int get_basic_constraints (out bool critical, out int ca, out int pathlen);

			public int get_key_usage (out KeyUsage key_usage, out bool critical);
			public int set_key_usage (KeyUsage usage);

			public int get_proxy (out bool critical, out int pathlen, [CCode (array_length = "false")] out char[] policyLanguage, out char[] policy);

			public bool dn_oid_known (string oid);

			public int get_extension_oid (int index, void* oid, ref size_t oid_size);
			public int get_extension_by_oid (string oid, int index, void* buf, ref size_t buf_size, out bool critical);

			public int get_extension_info (int index, void* oid, ref size_t oid_size, out bool critical);
			public int get_extension_data (int index, void* data, ref size_t data_size);

			public int set_extension_by_oid (string oid, void* buf, size_t buf_size, bool critical);
			public int set_dn_by_oid (string oid, uint raw_flag, void* name, uint name_size);
			public int set_issuer_dn_by_oid (string oid, uint raw_flag, void* name, uint name_size);
			public int set_version (uint version);
			public int set_key (PrivateKey key);
			public int set_ca_status (uint ca);
			public int set_basic_constraints (uint ca, int pathLenConstraint);
			public int set_subject_alternative_name (SubjectAltName type, string data_string);

			public int sign (Certificate issuer, PrivateKey issuer_key);
			public int sign2 (Certificate issuer, PrivateKey issuer_key, DigestAlgorithm alg, uint flags);

			public int set_activation_time (time_t act_time);
			public int set_expiration_time (time_t exp_time);
			public int set_serial (void* serial, size_t serial_size);

			public int set_subject_key_id (void* id, size_t id_size);
			public int set_proxy_dn (Certificate eecrt, uint raw_flag, void* name, uint name_size);
			public int set_proxy (int pathLenConstraint, string policyLanguage, [CCode (array_length_type = "size_t")] uint8[] policy);

			public int print (CertificatePrintFormats format, out Datum output);

			public int get_raw_issuer_dn (out unowned Datum start);
			public int get_raw_dn (out unowned Datum start);

			public int verify_data (uint flags, ref Datum data, ref Datum signature);

			private int set_crq (CertificateRequest crq);

			// verification

			public int check_issuer (Certificate issuer);
			public static int list_verify (Certificate[] cert_list, Certificate[] CA_list, Certificate[] CLR_list, CertificateVerifyFlags flags, out CertificateStatus verify);
			public int verify (Certificate[] CA_list, CertificateVerifyFlags flags, out CertificateStatus verify);
			public int check_revocation (CRL[] crl_list);
			public int get_fingerprint (DigestAlgorithm algo, void* buf, ref size_t buf_size);
			public int get_key_purpose_oid (int index, void* oid, ref size_t oid_size, out bool critical);
			public int set_key_purpose_oid (string oid, bool critical);
		}

		[Compact]
		[CCode (cname = "struct gnutls_x509_crl_int", free_function = "gnutls_x509_crl_deinit", cprefix = "gnutls_x509_crl_")]
		public class CRL
		{
			private static int init (out CRL crl);
			public static CRL create ()
			{
				CRL result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int import (ref Datum data, CertificateFormat format);
			public int export (CertificateFormat format, void* output, ref size_t output_size);

			public int get_issuer_dn (char* buf, ref size_t buf_size);
			public int get_issuer_dn_by_oid (string oid, int index, uint raw_flag, void* buf, ref size_t buf_size);

			public int get_dn_oid (int index, void* oid, ref size_t oid_size);

			public int get_signature_algorithm ();
			public int get_signature (char* sig, ref size_t sig_size);
			public int get_version ();

			public time_t get_this_update ();
			public time_t get_next_update ();

			public int get_crt_count ();
			public int get_crt_serial (int index, uchar* serial, ref size_t serial_size, out time_t t);

			// aliases for previous two
			public int get_certificate_count ();
			public int get_certificate (int index, uchar* serial, ref size_t serial_size, out time_t t);

			public int check_issuer (Certificate issuer);

			public int verify (Certificate[] ca_list, CertificateVerifyFlags flags, out CertificateStatus verify);

			// CRL writing

			public int set_version (uint version);
			public int sign (Certificate issuer, PrivateKey issuer_key);
			public int sign2 (Certificate issuer, PrivateKey issuer_key, DigestAlgorithm algo, uint flags);

			public int set_this_update (time_t act_time);
			public int set_next_update (time_t exp_time);

			public int set_crt_serial (void* serial, size_t serial_size, time_t revocation_time);
			public int set_crt (Certificate crt, time_t revocation_time);

			public int print (CertificatePrintFormats format, out Datum output);
		}

		[Compact]
		[CCode (cname = "struct gnutls_pkcs7_int", cprefix = "gnutls_pkcs7_", free_function = "gnutls_pkcs7_deinit")]
		public class PKCS7
		{
			private static int init (out PKCS7 pkcs7);
			public static PKCS7 create ()
			{
				PKCS7 result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int import (ref Datum data, CertificateFormat format);
			public int export (CertificateFormat format, void* output, ref size_t output_size);

			public int get_crt_count ();
			public int get_crt_raw (int index, void* certificate, ref size_t certificate_size);
			public int set_crt_raw (ref Datum crt);
			public int set_crt (Certificate crt);
			public int delete_crt (int index);

			public int get_crl_count ();
			public int get_crl_raw (int index, void* crl, ref size_t crl_size);
			public int set_crl_raw (ref Datum crt);
			public int set_crl (CRL crl);
			public int delete_crl (int index);
		}

		// Flags for the gnutls_x509_privkey_export_pkcs8() function.
		[Flags]
		[CCode (cname = "gnutls_pkcs_encrypt_flags_t", cprefix = "GNUTLS_PKCS_", has_type_id = false)]
		public enum PKCSEncryptFlags {
			PLAIN,
			USE_PKCS12_3DES,
			USE_PKCS12_ARCFOUR,
			USE_PKCS12_RC2_40,
			USE_PBES2_3DES
		}

		[Compact]
		[CCode (cname = "struct gnutls_x509_privkey_int", cprefix = "gnutls_x509_privkey_", free_function = "gnutls_x509_privkey_deinit")]
		public class PrivateKey
		{
			private static int init (out PrivateKey key);
			public static PrivateKey create ()
			{
				PrivateKey result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int cpy (PrivateKey source);

			public int import (ref Datum data, CertificateFormat format);
			public int import_pkcs8 (ref Datum data, CertificateFormat format, string? password, PKCSEncryptFlags flags);
			public int import_rsa_raw (ref Datum m, ref Datum e, ref Datum d, ref Datum p, ref Datum q, ref Datum u);
			public int import_dsa_raw (ref Datum p, ref Datum q, ref Datum g, ref Datum y, ref Datum x);

			public int export (CertificateFormat format, void* output, ref size_t output_size);
			public int export_pkcs8 (CertificateFormat format, string password, PKCSEncryptFlags flags, void* output, ref size_t output_size);
			public int export_rsa_raw (out Datum m, out Datum e, out Datum d, out Datum p, out Datum q, out Datum u);
			public int export_dsa_raw (out Datum p, out Datum q, out Datum g, out Datum y, out Datum x);

			public int fix ();
			public int generate (PKAlgorithm algo, uint bits, uint flags = 0);

			public int get_pk_algorithm ();
			public int get_key_id (uint flags, uchar* output, ref size_t output_size);

			// Signing stuff

			public int sign_data (DigestAlgorithm digest, uint flags, ref Datum data, void* signature, ref size_t signature_size);
			public int verify_data (uint flags, ref Datum data, ref Datum signature);
			public int sign_hash (ref Datum hash, out Datum signature);
		}

		[Compact]
		[CCode (cname = "struct gnutls_x509_crq_int", cprefix = "gnutls_x509_crq_", free_function = "gnutls_x509_crq_deinit")]
		public class CertificateRequest
		{
			private static int init (out CertificateRequest request);
			public static CertificateRequest create ()
			{
				CertificateRequest result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int import (ref Datum data, CertificateFormat format);
			public int export (CertificateFormat format, void* output, ref size_t output_size);

			public int get_pk_algorithm (out uint bits);
			public int get_dn (char* buf, ref size_t buf_size);
			public int get_dn_oid (int index, void* oid, ref size_t oid_size);
			public int get_dn_by_oid (string oid, int index, uint raw_flag, void* buf, ref size_t buf_size);
			public int set_dn_by_oid (string oid, uint raw_flag, void* name, uint name_size);

			public int set_version (uint version);

			public int set_key (PrivateKey key);

			public int sign (PrivateKey key);
			public int sign2 (PrivateKey key, DigestAlgorithm algo, uint flags);

			public int set_challenge_password (string pass);
			public int get_challenge_password (char* pass, ref size_t pass_size);

			public int set_attribute_by_oid (string oid, void* buf, size_t buf_size);
			public int get_attribute_by_oid (string oid, int index, void* buf, ref size_t buf_size);
		}

		[Compact]
		[CCode (cheader_filename = "gnutls/pkcs12.h", cname = "struct gnutls_pkcs12_int", cprefix = "gnutls_pkcs12_", free_function = "gnutls_pkcs12_deinit")]
		public class PKCS12
		{
			private static int init (out PKCS12 request);
			public static PKCS12 create ()
			{
				PKCS12 result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int import (ref Datum data, CertificateFormat format, uint flags);
			public int export (CertificateFormat format, void* output, ref size_t output_size);

			public int get_bag (int index, PKCS12Bag bag);
			public int set_bag (PKCS12Bag bag);

			public int generate_mac (string pass);
			public int verify_mac (string pass);
		}

		[CCode (cheader_filename = "gnutls/pkcs12.h", cname = "gnutls_pkcs12_bag_type_t", cprefix = "GNUTLS_BAG_", has_type_id = false)]
		public enum PKCS12BagType {
			EMPTY,
			PKCS8_ENCRYPTED_KEY,
			PKCS8_KEY,
			CERTIFICATE,
			CRL,
			ENCRYPTED,
			UNKNOWN
		}

		[Compact]
		[CCode (cheader_filename = "gnutls/pkcs12.h", cname = "struct gnutls_pkcs12_bag_int", cprefix = "gnutls_pkcs12_bag_", free_function = "gnutls_pkcs12_bag_deinit")]
		public class PKCS12Bag {
			private static int init (out PKCS12Bag request);
			public static PKCS12Bag create ()
			{
				PKCS12Bag result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int decrypt (string pass);
			public int encrypt (string pass, PKCSEncryptFlags flags);

			public PKCS12BagType get_type (int index);
			public int get_data (int index, out Datum data);
			public int set_data (PKCS12BagType type, ref Datum data);
			public int set_crl (CRL crl);
			public int set_crt (Certificate crt);

			public int get_count ();

			public int get_key_id (int index, out Datum id);
			public int set_key_id (int index, ref Datum id);

			public int get_friendly_name (int index, out unowned string name);
			public int set_friendly_name (int index, string name);
		}
	}

	[CCode (cheader_filename = "gnutls/openpgp.h")]
	namespace OpenPGP
	{
		[CCode (has_target = false)]
		public delegate int RecvKeyFunc (Session session, uint8[] keyfpr, out Datum key);

		[CCode (cname = "gnutls_openpgp_crt_fmt_t", cprefix = "GNUTLS_OPENPGP_FMT_", has_type_id = false)]
		public enum CertificateFormat {
			RAW,
			BASE64
		}

		[Compact]
		[CCode (cname = "struct gnutls_openpgp_crt_int", cprefix = "gnutls_openpgp_crt_", free_function = "gnutls_openpgp_crt_deinit")]
		public class Certificate
		{
			private static int init (out Certificate crt);
			public static Certificate create ()
			{
				Certificate result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int import (ref Datum data, CertificateFormat format);
			public int export (CertificateFormat format, void* output, ref size_t output_size);

			public int print (CertificatePrintFormats format, out Datum output);

			public int get_key_usage (out KeyUsage key_usage);
			public int get_fingerprint (void* fpr, ref size_t fpr_size);
			public int get_subkey_fingerprint (uint index, void* fpr, ref size_t fpr_size);

			public int get_name (int index, char* buf, ref size_t buf_size);

			public PKAlgorithm get_pk_algorithm (out uint bits);

			public int get_version ();

			public time_t get_creation_time ();
			public time_t get_expiration_time ();

			// keyid is 8 bytes
			public int get_key_id (uchar* keyid);

			public int check_hostname (string hostname);

			public int get_revoked_status ();

			public int get_subkey_count ();
			public int get_subkey_idx (/*const*/ uchar* keyid);
			public int get_subkey_revoked_status (uint idx);

			public PKAlgorithm get_subkey_pk_algorithm (uint idx, out uint bits);

			public time_t get_subkey_creation_time (uint idx);
			public time_t get_subkey_expiration_time (uint idx);

			public int get_subkey_id (uint idx, uchar* keyid);
			public int get_subkey_usage (uint idx, out KeyUsage key_usage);

			public int get_pk_dsa_raw (out Datum p, out Datum q, out Datum g, out Datum y);
			public int get_pk_rsa_raw (out Datum m, out Datum e);

			public int get_subkey_pk_dsa_raw (uint index, out Datum p, out Datum q, out Datum g, out Datum y);
			public int get_subkey_pk_rsa_raw (uint index, out Datum m, out Datum e);

			public int get_preferred_key_id (uchar* keyid);
			public int set_preferred_key_id (/* const */ uchar* keyid);

			public int verify_ring (Keyring keyring, uint flags, out CertificateStatus verify);
			public int verify_self (uint flags, out CertificateStatus verify);
		}

		[Compact]
		[CCode (cname = "struct gnutls_openpgp_privkey_int", cprefix = "gnutls_openpgp_privkey_", free_function = "gnutls_openpgp_privkey_deinit")]
		public class PrivateKey
		{
			private static int init (out PrivateKey key);
			public static PrivateKey create ()
			{
				PrivateKey result = null;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public PKAlgorithm get_pk_algorithm (out uint bits);

			public int import (ref Datum data, CertificateFormat format, string pass, uint flags);
			public int export (CertificateFormat format, string password, uint flags, void* output, ref size_t output_size);

			public int sign_hash (ref Datum hash, out Datum signature);
			public int get_fingerprint (void* fpr, ref size_t fpr_size);
			public int get_subkey_fingerprint (uint idx, void* fpr, ref size_t fpr_size);

			public int get_key_id (uchar* keyid);
			public int get_subkey_count ();
			public int get_subkey_idx (/*const*/ uchar* keyid);

			public int get_subkey_revoked_status (uint index);
			public int get_revoked_status ();

			public PKAlgorithm get_subkey_pk_algorithm (uint idx, out uint bits);

			public time_t get_subkey_expiration_time (uint idx);
			public time_t get_subkey_creation_time (uint idx);

			public int get_subkey_id (uint idx, uchar* keyid);

			public int export_subkey_dsa_raw (uint idx, out Datum p, out Datum q, out Datum g, out Datum y, out Datum x);
			public int export_subkey_rsa_raw (uint idx, out Datum m, out Datum e, out Datum d, out Datum p, out Datum q, out Datum u);

			public int export_dsa_raw (out Datum p, out Datum q, out Datum g, out Datum y, out Datum x);
			public int export_rsa_raw (out Datum m, out Datum e, out Datum d, out Datum p, out Datum q, out Datum u);

			public int set_preferred_key_id (/*const*/ uchar* keyid);
			public int get_preferred_key_id (uchar* keyid);

			public int get_auth_subkey (uchar* keyid, uint flag);
		}

		[Compact]
		[CCode (cname = "struct gnutls_openpgp_keyring_int", cprefix = "gnutls_openpgp_keyring_", free_function = "gnutls_openpgp_keyring_deinit")]
		public class Keyring
		{
			private static int init (out Keyring keyring);
			public static Keyring create ()
			{
				Keyring result;
				var ret = init (out result);
				if (ret != 0)
					GLib.error ("%s", ((ErrorCode)ret).to_string ());
				return result;
			}

			public int import (ref Datum data, CertificateFormat format);
			public int check_id (/*const*/ uchar* keyid, uint flags);

			public int get_crt_count ();
			public int get_crt (uint index, out Certificate cert);
		}
	}


	[CCode (cname = "gnutls_certificate_client_retrieve_function *", has_target = false)]
	public delegate int ClientCertificateRetrieveFunction (Session session, Datum[] req_ca_rdn, PKAlgorithm[] pk_algos, out RetrStruct st);
	[CCode (cname = "gnutls_certificate_server_retrieve_function *", has_target = false)]
	public delegate int ServerCertificateRetrieveFunction (Session session, out RetrStruct st);

	[Compact]
	[CCode (cname = "struct gnutls_certificate_credentials_st",
	        free_function = "gnutls_certificate_free_credentials",
	        cprefix = "gnutls_certificate_")]
	public class CertificateCredentials
	{
		[CCode (cname = "gnutls_certificate_allocate_credentials")]
		private static int allocate (out CertificateCredentials credentials);
		public static CertificateCredentials create ()
		{
			CertificateCredentials result;
			var ret = allocate (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}

		public void free_keys ();
		public void free_cas  ();
		public void free_ca_names ();
		public void free_crls ();

		public void set_dh_params (DHParams dh_params);
		public void set_rsa_export_params (RSAParams rsa_params);
		public void set_verify_flags (X509.CertificateVerifyFlags flags);
		public void set_verify_limits (uint max_bits, uint max_depth);

		public int set_x509_trust (X509.Certificate[] ca_list);
		public int set_x509_trust_file (string cafile, X509.CertificateFormat type);
		public int set_x509_trust_mem (/* const */ ref Datum cadata, X509.CertificateFormat type);

		public int set_x509_crl (X509.CRL[] crl_list);
		public int set_x509_crl_file (string crlfile, X509.CertificateFormat type);
		public int set_x509_crl_mem (/* const */ ref Datum crldata, X509.CertificateFormat type);

		public int set_x509_key (X509.Certificate[] cert_list, X509.PrivateKey key);
		public int set_x509_key_file (string certfile, string keyfile, X509.CertificateFormat type);
		public int set_x509_key_mem (/* const */ ref Datum certdata, /* const */ ref Datum keydata, X509.CertificateFormat type);

		public int set_x509_simple_pkcs12_file (string pkcs12file, X509.CertificateFormat type, string? password = null);

		public void get_x509_cas ([CCode (array_length_type = "unsigned int")] out unowned X509.Certificate[] x509_ca_list);
		public void get_x509_crls ([CCode (array_length_type = "unsigned int")] out unowned X509.CRL[] x509_crl_list);


		[CCode (cname = "gnutls_certificate_client_set_retrieve_function")]
		public void set_client_certificate_retrieve_function (ClientCertificateRetrieveFunction func);
		[CCode (cname = "gnutls_certificate_server_set_retrieve_function")]
		public void set_server_certificate_retrieve_function (ServerCertificateRetrieveFunction func);

		[CCode (cname = "gnutls_certificate_set_params_function")]
		public void set_params_function (ParamsFunction func);

		// OpenPGP stuff

		public int set_openpgp_key (OpenPGP.Certificate key, OpenPGP.PrivateKey pkey);

		public int set_openpgp_key_file (string certfile, string keyfile, OpenPGP.CertificateFormat format);
		public int set_openpgp_key_mem (ref Datum cert, ref Datum key, OpenPGP.CertificateFormat format);
		public int set_openpgp_key_file2 (string certfile, string keyfile, string keyid, OpenPGP.CertificateFormat format);
		public int set_openpgp_key_mem2 (ref Datum cert, ref Datum key, string keyid, OpenPGP.CertificateFormat format);

		public int set_openpgp_keyring_mem (uchar* data, size_t data_size, OpenPGP.CertificateFormat format);
		public int set_openpgp_keyring_file (string file, OpenPGP.CertificateFormat format);

		public void get_openpgp_keyring (out unowned OpenPGP.Keyring keyring);
	}

	[CCode (cname = "gnutls_malloc")]
	public void* malloc (size_t size);
	[CCode (cname = "gnutls_secure_malloc")]
	public void* secure_malloc (size_t size);
	[CCode (cname = "gnutls_realloc")]
	public void* realloc (void* ptr, size_t new_size);
	[CCode (cname = "gnutls_calloc")]
	public void* calloc (size_t count, size_t block_size);
	[CCode (cname = "gnutls_free")]
	public void free (void* ptr);

	[CCode (cname = "gnutls_free")]
	public void free_data ([CCode (array_length = false)] owned uint[] data);

	[CCode (cname = "gnutls_strdup")]
	public string strdup (string str);

	[CCode (cname = "gnutls_alloc_function", has_target = false)]
	public delegate void* AllocFunction (size_t size);
	[CCode (cname = "gnutls_calloc_function", has_target = false)]
	public delegate void* CallocFunction (size_t count, size_t block_size);
	[CCode (cname = "gnutls_is_secure_function", has_target = false)]
	public delegate int IsSecureFunction (void* ptr);
	[CCode (cname = "gnutls_free_function", has_target = false)]
	public delegate void FreeFunction (void* ptr);
	[CCode (cname = "gnutls_realloc_function", has_target = false)]
	public delegate void* ReallocFunction (void* ptr, size_t new_size);

	public int global_init ();
	public void global_deinit ();

	[CCode (cname = "gnutls_global_set_mem_functions")]
	public void set_mem_functions (AllocFunction alloc_func, AllocFunction secure_alloc_func,
	                               IsSecureFunction is_secure_func, ReallocFunction realloc_func,
	                               FreeFunction free_func);

	[CCode (cname = "gnutls_log_func", has_target = false)]
	public delegate void LogFunc (int level, string msg);
	[CCode (cname = "gnutls_global_set_log_function")]
	public void set_log_function (LogFunc func);
	[CCode (cname = "gnutls_global_set_log_level")]
	public void set_log_level (int level);

	[CCode (cname = "gnutls_transport_set_global_errno")]
	public void set_global_errno (int err);

// SRP stuff

	[CCode (cname = "gnutls_srp_server_credentials_function *", has_target = false)]
	public delegate int SRPServerCredentialsFunction (Session session, string username,
                                                       out Datum salt, out Datum verifier,
                                                       out Datum generator, out Datum prime);

	[Compact]
	[CCode (cname = "struct gnutls_srp_server_credentials_st", free_function = "gnutls_srp_free_server_credentials")]
	public class SRPServerCredentials
	{
		[CCode (cname = "gnutls_srp_allocate_server_credentials")]
		private static int allocate (out SRPServerCredentials sc);
		public static SRPServerCredentials create ()
		{
			SRPServerCredentials result = null;
			var ret = allocate (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}

		[CCode (cname = "gnutls_srp_set_server_credentials_file")]
		public int set_credentials_file (string password_file, string password_conf_file);

		[CCode (cname = "gnutls_srp_server_get_username")]
		public string get_username ();

		[CCode (cname = "gnutls_srp_set_server_credentials_function")]
		public void set_credentials_function (SRPServerCredentialsFunction func);
	}

	[CCode (cname = "gnutls_srp_client_credentials_function *", has_target = false)]
	public delegate int SRPClientCredentialsFunction (Session session, out string username, out string password);

	[Compact]
	[CCode (cname = "struct gnutls_srp_client_credentials_st", free_function = "gnutls_srp_free_client_credentials")]
	public class SRPClientCredentials
	{
		[CCode (cname = "gnutls_srp_allocate_client_credentials")]
		private static int allocate (out SRPClientCredentials sc);
		public static SRPClientCredentials create ()
		{
			SRPClientCredentials result;
			var ret = allocate (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}

		[CCode (cname = "gnutls_srp_set_client_credentials")]
		public int set_credentials (string username, string password);

		[CCode (cname = "gnutls_srp_set_client_credentials_function")]
		public void set_credentials_function (SRPClientCredentialsFunction func);
	}

	//  extern int gnutls_srp_verifier (const char *username,
	//			  const char *password,
	//			  const gnutls_datum_t * salt,
	//			  const gnutls_datum_t * generator,
	//			  const gnutls_datum_t * prime,
	//			  gnutls_datum_t * res);

	public int srp_verifier (string username, string password, /* const */ ref Datum salt, /* const */ ref Datum generator, /* const */ ref Datum prime, out Datum result);

	// The static parameters defined in draft-ietf-tls-srp-05
	// Those should be used as input to gnutls_srp_verifier().

	public const Datum srp_2048_group_prime;
	public const Datum srp_2048_group_generator;

	public const Datum srp_1536_group_prime;
	public const Datum srp_1536_group_generator;

	public const Datum srp_1024_group_prime;
	public const Datum srp_1024_group_generator;

	public int srp_base64_encode (/* const */ ref Datum data, [CCode (array_length = "false")] char[] result, ref size_t result_size);
	public int srp_base64_encode_alloc (/* const */ ref Datum data, out Datum result);

	public int srp_base64_decode (/* const */ ref Datum b64_data, [CCode (array_length = false)] uint8[] result, ref size_t result_size);
	public int srp_base64_decode_alloc (/* const */ ref Datum b64_data, out Datum result);






// PSK stuff

	[CCode (cname = "gnutls_psk_key_flags", cprefix = "GNUTLS_PSK_KEY_", has_type_id = false)]
	public enum PSKKeyFlags
	{
		RAW,
		HEX
	}

	[CCode (cname = "gnutls_psk_server_credentials_function *", has_target = false)]
	public delegate int PSKServerCredentialsFunction (Session session, string username, /* const */ ref Datum key);

	[Compact]
	[CCode (cname = "struct gnutls_psk_server_credentials_st", free_function = "gnutls_psk_free_server_credentials")]
	public class PSKServerCredentials
	{
		[CCode (cname = "gnutls_psk_allocate_server_credentials")]
		private static int allocate (out PSKServerCredentials sc);
		public static PSKServerCredentials create ()
		{
			PSKServerCredentials result;
			var ret = allocate (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}

		[CCode (cname = "gnutls_psk_set_server_credentials_file")]
		public int set_credentials_file (string password_file);

		[CCode (cname = "gnutls_psk_set_server_credentials_hint")]
		public int set_credentials_hint (string hint);

		[CCode (cname = "gnutls_psk_set_server_credentials_function")]
		public void set_credentials_function (PSKServerCredentialsFunction func);

		[CCode (cname = "gnutls_psk_set_server_dh_params")]
		public void set_dh_params (DHParams dh_params);

		[CCode (cname = "gnutls_psk_set_server_params_function")] // also gnutls_psk_set_params_function
		public void set_params_function (ParamsFunction func);
	}

	[CCode (cname = "gnutls_psk_client_credentials_function *", has_target = false)]
	public delegate int PSKClientCredentialsFunction (Session session, out string username, out Datum key);

	[Compact]
	[CCode (cname = "struct gnutls_psk_client_credentials_st", free_function = "gnutls_psk_free_client_credentials")]
	public class PSKClientCredentials
	{
		[CCode (cname = "gnutls_psk_allocate_client_credentials")]
		private static int allocate (out PSKClientCredentials sc);
		public static PSKClientCredentials create ()
		{
			PSKClientCredentials result;
			var ret = allocate (out result);
			if (ret != 0)
				GLib.error ("%s", ((ErrorCode)ret).to_string ());
			return result;
		}

		[CCode (cname = "gnutls_psk_set_client_credentials")]
		public int set_credentials (string username, /* const */ ref Datum key, PSKKeyFlags format);

		[CCode (cname = "gnutls_psk_set_client_credentials_function")]
		public void set_credentials_function (PSKClientCredentialsFunction func);
	}

	public int hex_encode (/* const */ ref Datum data, [CCode (array_length = "false")] char[] result, ref size_t result_size);
	public int hex_decode (/* const */ ref Datum hex_data, [CCode (array_length = "false")] char[] result, ref size_t result_size);

	public int psk_netconf_derive_key (string password, string psk_identity, string psk_identity_hint, out Datum output_key);

////

	[SimpleType]
	[CCode (cname = "gnutls_retr_st", has_type_id = false)]
	public struct RetrStruct
	{
		public CertificateType type;
		[CCode (cname = "cert.x509", array_length_cname = "ncerts", array_length_type = "unsigned int")]
		public X509.Certificate[] cert_x509;
		[CCode (cname = "cert.pgp")]
		public OpenPGP.Certificate cert_pgp;
		[CCode (cname = "key.x509")]
		public X509.PrivateKey key_x509;
		[CCode (cname = "key.pgp")]
		public OpenPGP.PrivateKey key_pgp;
		public uint deinit_all;
	}

	public int pem_base64_encode (string msg, /* const */ ref Datum data, void* result, ref size_t result_size);
	public int pem_base64_decode (string header, /* const */ ref Datum b64_data, void* result, ref size_t result_size);

	public int pem_base64_encode_alloc (string msg, /* const */ ref Datum data, out Datum result);
	public int pem_base64_decode_alloc (string header, /* const */ ref Datum b64_data, out Datum result);

	public int hex2bin (string hex_data, size_t hex_size, void* bin_data, ref size_t bin_size);

	// returns cipher suite name or null if index is out of bounds
	public unowned string? cipher_suite_info (size_t index, [CCode (array_length = "false")] char[] cs_id, out KXAlgorithm kx,
	                                         out CipherAlgorithm cipher, out MacAlgorithm mac,
	                                         out Protocol version);

	public unowned string? cipher_suite_get_name (KXAlgorithm kx, CipherAlgorithm cipher, MacAlgorithm mac);

	public int prf (Session session, size_t label_size, string label, bool server_random_first,
	                size_t extra_size, void* extra, size_t output_size, void* output);

	public int prf_raw (Session session, size_t label_size, string label,
	                    size_t seed_size, void* seed, size_t output_size, void* output);

	// Gnutls error codes. The mapping to a TLS alert is also shown in comments.
	[CCode (cname = "int", cprefix = "GNUTLS_E_", lower_case_cprefix = "gnutls_error_", has_type_id = false)]
	public enum ErrorCode {

		SUCCESS,
		UNKNOWN_COMPRESSION_ALGORITHM,
		UNKNOWN_CIPHER_TYPE,
		LARGE_PACKET,
		UNSUPPORTED_VERSION_PACKET,	// GNUTLS_A_PROTOCOL_VERSION
		UNEXPECTED_PACKET_LENGTH,	// GNUTLS_A_RECORD_OVERFLOW
		INVALID_SESSION,
		FATAL_ALERT_RECEIVED,
		UNEXPECTED_PACKET,	// GNUTLS_A_UNEXPECTED_MESSAGE
		WARNING_ALERT_RECEIVED,
		ERROR_IN_FINISHED_PACKET,
		UNEXPECTED_HANDSHAKE_PACKET,
		UNKNOWN_CIPHER_SUITE,	// GNUTLS_A_HANDSHAKE_FAILURE
		UNWANTED_ALGORITHM,
		MPI_SCAN_FAILED,
		DECRYPTION_FAILED,	// GNUTLS_A_DECRYPTION_FAILED, GNUTLS_A_BAD_RECORD_MAC
		MEMORY_ERROR,
		DECOMPRESSION_FAILED,  // GNUTLS_A_DECOMPRESSION_FAILURE
		COMPRESSION_FAILED,
		AGAIN,
		EXPIRED,
		DB_ERROR,
		SRP_PWD_ERROR,
		INSUFFICIENT_CREDENTIALS,

		HASH_FAILED,
		BASE64_DECODING_ERROR,

		MPI_PRINT_FAILED,
		REHANDSHAKE,     // GNUTLS_A_NO_RENEGOTIATION
		GOT_APPLICATION_DATA,
		RECORD_LIMIT_REACHED,
		ENCRYPTION_FAILED,

		PK_ENCRYPTION_FAILED,
		PK_DECRYPTION_FAILED,
		PK_SIGN_FAILED,
		X509_UNSUPPORTED_CRITICAL_EXTENSION,
		KEY_USAGE_VIOLATION,
		NO_CERTIFICATE_FOUND,	// GNUTLS_A_BAD_CERTIFICATE
		INVALID_REQUEST,
		SHORT_MEMORY_BUFFER,
		INTERRUPTED,
		PUSH_ERROR,
		PULL_ERROR,
		RECEIVED_ILLEGAL_PARAMETER,    // GNUTLS_A_ILLEGAL_PARAMETER
		REQUESTED_DATA_NOT_AVAILABLE,
		PKCS1_WRONG_PAD,
		RECEIVED_ILLEGAL_EXTENSION,
		INTERNAL_ERROR,
		DH_PRIME_UNACCEPTABLE,
		FILE_ERROR,
		TOO_MANY_EMPTY_PACKETS,
		UNKNOWN_PK_ALGORITHM,

		// returned if libextra functionality was requested but
		// gnutls_global_init_extra() was not called.

		INIT_LIBEXTRA,
		LIBRARY_VERSION_MISMATCH,

		// returned if you need to generate temporary RSA
		// parameters. These are needed for export cipher suites.

		NO_TEMPORARY_RSA_PARAMS,

		LZO_INIT_FAILED,
		NO_COMPRESSION_ALGORITHMS,
		NO_CIPHER_SUITES,

		OPENPGP_GETKEY_FAILED,
		PK_SIG_VERIFY_FAILED,

		ILLEGAL_SRP_USERNAME,
		SRP_PWD_PARSING_ERROR,
		NO_TEMPORARY_DH_PARAMS,

		// For certificate and key stuff

		ASN1_ELEMENT_NOT_FOUND,
		ASN1_IDENTIFIER_NOT_FOUND,
		ASN1_DER_ERROR,
		ASN1_VALUE_NOT_FOUND,
		ASN1_GENERIC_ERROR,
		ASN1_VALUE_NOT_VALID,
		ASN1_TAG_ERROR,
		ASN1_TAG_IMPLICIT,
		ASN1_TYPE_ANY_ERROR,
		ASN1_SYNTAX_ERROR,
		ASN1_DER_OVERFLOW,
		OPENPGP_UID_REVOKED,
		CERTIFICATE_ERROR,
		CERTIFICATE_KEY_MISMATCH,
		UNSUPPORTED_CERTIFICATE_TYPE,	// GNUTLS_A_UNSUPPORTED_CERTIFICATE
		X509_UNKNOWN_SAN,
		OPENPGP_FINGERPRINT_UNSUPPORTED,
		X509_UNSUPPORTED_ATTRIBUTE,
		UNKNOWN_HASH_ALGORITHM,
		UNKNOWN_PKCS_CONTENT_TYPE,
		UNKNOWN_PKCS_BAG_TYPE,
		INVALID_PASSWORD,
		MAC_VERIFY_FAILED,	// for PKCS #12 MAC
		CONSTRAINT_ERROR,

		WARNING_IA_IPHF_RECEIVED,
		WARNING_IA_FPHF_RECEIVED,

		IA_VERIFY_FAILED,

		UNKNOWN_ALGORITHM,

		BASE64_ENCODING_ERROR,
		INCOMPATIBLE_CRYPTO_LIBRARY,
		INCOMPATIBLE_LIBTASN1_LIBRARY,

		OPENPGP_KEYRING_ERROR,
		X509_UNSUPPORTED_OID,

		RANDOM_FAILED,
		BASE64_UNEXPECTED_HEADER_ERROR,

		OPENPGP_SUBKEY_ERROR,

		CRYPTO_ALREADY_REGISTERED,

		HANDSHAKE_TOO_LARGE,

		UNIMPLEMENTED_FEATURE,

		APPLICATION_ERROR_MAX, // -65000
		APPLICATION_ERROR_MIN;  // -65500

		[CCode (cname = "gnutls_error_is_fatal")]
		public bool is_fatal ();
		[CCode (cname = "gnutls_error_to_alert")]
		public AlertDescription to_alert (out AlertLevel level);
		[CCode (cname = "gnutls_perror")]
		public void print ();
		[CCode (cname = "gnutls_strerror")]
		public unowned string to_string ();
	}
}


