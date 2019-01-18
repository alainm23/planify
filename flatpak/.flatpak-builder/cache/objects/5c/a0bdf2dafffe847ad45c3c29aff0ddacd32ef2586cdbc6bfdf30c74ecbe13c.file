/*
 * camel-enums.h
 *
 * This library is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License
 * for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library. If not, see <http://www.gnu.org/licenses/>.
 *
 */

#if !defined (__CAMEL_H_INSIDE__) && !defined (CAMEL_COMPILATION)
#error "Only <camel/camel.h> can be included directly."
#endif

#ifndef CAMEL_ENUMS_H
#define CAMEL_ENUMS_H

/**
 * CamelAuthenticationResult:
 * @CAMEL_AUTHENTICATION_ERROR:
 *    An error occurred while authenticating.
 * @CAMEL_AUTHENTICATION_ACCEPTED:
 *    Server accepted our authentication attempt.
 * @CAMEL_AUTHENTICATION_REJECTED:
 *    Server rejected our authentication attempt.
 *
 * Authentication result codes used by #CamelService.
 *
 * Since: 3.4
 **/
typedef enum {
	CAMEL_AUTHENTICATION_ERROR,
	CAMEL_AUTHENTICATION_ACCEPTED,
	CAMEL_AUTHENTICATION_REJECTED
} CamelAuthenticationResult;

typedef enum { /*< flags >*/
	CAMEL_FOLDER_HAS_SUMMARY_CAPABILITY = 1 << 0,
	CAMEL_FOLDER_FILTER_RECENT = 1 << 2,
	CAMEL_FOLDER_HAS_BEEN_DELETED = 1 << 3,
	CAMEL_FOLDER_IS_TRASH = 1 << 4,
	CAMEL_FOLDER_IS_JUNK = 1 << 5,
	CAMEL_FOLDER_FILTER_JUNK = 1 << 6
} CamelFolderFlags;

/**
 * CAMEL_FOLDER_TYPE_BIT: (value 10)
 * The folder type bitshift value.
 **/
#define CAMEL_FOLDER_TYPE_BIT (10)

/**
 * CamelFolderInfoFlags:
 * @CAMEL_FOLDER_NOSELECT:
 *    The folder cannot contain messages.
 * @CAMEL_FOLDER_NOINFERIORS:
 *    The folder cannot have child folders.
 * @CAMEL_FOLDER_CHILDREN:
 *    The folder has children (not yet fully implemented).
 * @CAMEL_FOLDER_NOCHILDREN:
 *    The folder does not have children (not yet fully implemented).
 * @CAMEL_FOLDER_SUBSCRIBED:
 *    The folder is subscribed.
 * @CAMEL_FOLDER_VIRTUAL:
 *    The folder is virtual.  Messages cannot be copied or moved to
 *    virtual folders since they are only queries of other folders.
 * @CAMEL_FOLDER_SYSTEM:
 *    The folder is a built-in "system" folder.  System folders
 *    cannot be renamed or deleted.
 * @CAMEL_FOLDER_VTRASH:
 *    The folder is a virtual trash folder.  It cannot be copied to,
 *    and can only be moved to if in an existing folder.
 * @CAMEL_FOLDER_SHARED_TO_ME:
 *    A folder being shared by someone else.
 * @CAMEL_FOLDER_SHARED_BY_ME:
 *    A folder being shared by the user.
 * @CAMEL_FOLDER_TYPE_NORMAL:
 *    The folder is a normal folder.
 * @CAMEL_FOLDER_TYPE_INBOX:
 *    The folder is an inbox folder.
 * @CAMEL_FOLDER_TYPE_OUTBOX:
 *    The folder is an outbox folder.
 * @CAMEL_FOLDER_TYPE_TRASH:
 *    The folder shows deleted messages.
 * @CAMEL_FOLDER_TYPE_JUNK:
 *    The folder shows junk messages.
 * @CAMEL_FOLDER_TYPE_SENT:
 *    The folder shows sent messages.
 * @CAMEL_FOLDER_TYPE_CONTACTS:
 *    The folder contains contacts, instead of mail messages.
 * @CAMEL_FOLDER_TYPE_EVENTS:
 *    The folder contains calendar events, instead of mail messages.
 * @CAMEL_FOLDER_TYPE_MEMOS:
 *    The folder contains memos, instead of mail messages.
 * @CAMEL_FOLDER_TYPE_TASKS:
 *    The folder contains tasks, instead of mail messages.
 * @CAMEL_FOLDER_TYPE_ALL:
 *    This folder contains all the messages. Used by RFC 6154.
 * @CAMEL_FOLDER_TYPE_ARCHIVE:
 *    This folder contains archived messages. Used by RFC 6154.
 * @CAMEL_FOLDER_TYPE_DRAFTS:
 *    This folder contains drafts. Used by RFC 6154.
 * @CAMEL_FOLDER_READONLY:
 *    The folder is read only.
 * @CAMEL_FOLDER_WRITEONLY:
 *    The folder is write only.
 * @CAMEL_FOLDER_FLAGGED:
 *    This folder contains flagged messages. Some clients call this "starred". Used by RFC 6154.
 * @CAMEL_FOLDER_FLAGS_LAST:
 *    The last define bit of the flags. The #CamelProvider can use this and
 *    upper bits to store its own flags.
 *
 * These flags are abstractions.  It's up to the CamelProvider to give
 * them suitable interpretations.  Use #CAMEL_FOLDER_TYPE_MASK to isolate
 * the folder's type.
 **/
/* WARNING: This enum and CamelStoreInfoFlags must stay in sync.
 * FIXME: Eliminate the need for two separate types. */
typedef enum { /*< flags >*/
	CAMEL_FOLDER_NOSELECT = 1 << 0,
	CAMEL_FOLDER_NOINFERIORS = 1 << 1,
	CAMEL_FOLDER_CHILDREN = 1 << 2,
	CAMEL_FOLDER_NOCHILDREN = 1 << 3,
	CAMEL_FOLDER_SUBSCRIBED = 1 << 4,
	CAMEL_FOLDER_VIRTUAL = 1 << 5,
	CAMEL_FOLDER_SYSTEM = 1 << 6,
	CAMEL_FOLDER_VTRASH = 1 << 7,
	CAMEL_FOLDER_SHARED_TO_ME = 1 << 8,
	CAMEL_FOLDER_SHARED_BY_ME = 1 << 9,

	CAMEL_FOLDER_TYPE_NORMAL = 0 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_INBOX = 1 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_OUTBOX = 2 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_TRASH = 3 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_JUNK = 4 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_SENT = 5 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_CONTACTS = 6 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_EVENTS = 7 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_MEMOS = 8 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_TASKS = 9 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_ALL = 10 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_ARCHIVE = 11 << CAMEL_FOLDER_TYPE_BIT,
	CAMEL_FOLDER_TYPE_DRAFTS = 12 << CAMEL_FOLDER_TYPE_BIT,

	CAMEL_FOLDER_READONLY = 1 << 16,
	CAMEL_FOLDER_WRITEONLY = 1 << 17,
	CAMEL_FOLDER_FLAGGED = 1 << 18,

	CAMEL_FOLDER_FLAGS_LAST          = 1 << 24
} CamelFolderInfoFlags;

/**
 * CAMEL_FOLDER_TYPE_MASK: (value 64512)
 * The folder type mask value.
 **/
#define CAMEL_FOLDER_TYPE_MASK (0x3F << CAMEL_FOLDER_TYPE_BIT)

/* Note: The HTML elements are escaped in the doc comment intentionally,
 *       to have them shown as expected in generated documentation. */
/**
 * CamelMimeFilterToHTMLFlags:
 * @CAMEL_MIME_FILTER_TOHTML_PRE:
 *     Enclose the content in &lt;pre&gt; ... &lt;/pre&gt; tags.
 * @CAMEL_MIME_FILTER_TOHTML_CONVERT_NL:
 *     Convert newline characters to &lt;br&gt; tags.
 * @CAMEL_MIME_FILTER_TOHTML_CONVERT_SPACES:
 *     Convert space and tab characters to a non-breaking space (&amp;nbsp;).
 * @CAMEL_MIME_FILTER_TOHTML_CONVERT_URLS:
 *     Convert recognized URLs to &lt;a href="foo"&gt;foo&lt;/a&gt;.
 * @CAMEL_MIME_FILTER_TOHTML_MARK_CITATION:
 *     Color quoted lines (lines beginning with '&gt;').
 * @CAMEL_MIME_FILTER_TOHTML_CONVERT_ADDRESSES:
 *     Convert mailto: URLs to &lt;a href="mailto:foo"&gt;mailto:foo&lt;/a&gt;.
 * @CAMEL_MIME_FILTER_TOHTML_ESCAPE_8BIT:
 *     Convert 8-bit characters to escaped hexdecimal (&amp;#nnn;).
 * @CAMEL_MIME_FILTER_TOHTML_CITE:
 *     Prefix each line with "&gt; ".
 * @CAMEL_MIME_FILTER_TOHTML_PRESERVE_8BIT:
 *     This flag is not used by #CamelMimeFilterToHTML.
 * @CAMEL_MIME_FILTER_TOHTML_FORMAT_FLOWED:
 *     This flag is not used by #CamelMimeFilterToHTML.
 * @CAMEL_MIME_FILTER_TOHTML_QUOTE_CITATION:
 *     Group lines beginning with one or more '&gt;' characters in
 *     &lt;blockquote type="cite"&gt; ... &lt;/blockquote&gt; tags. The tags
 *     are nested according to the number of '&gt;' characters.
 *
 * Flags for converting text/plain content into text/html.
 **/
typedef enum { /*< flags >*/
	CAMEL_MIME_FILTER_TOHTML_PRE = 1 << 0,
	CAMEL_MIME_FILTER_TOHTML_CONVERT_NL = 1 << 1,
	CAMEL_MIME_FILTER_TOHTML_CONVERT_SPACES = 1 << 2,
	CAMEL_MIME_FILTER_TOHTML_CONVERT_URLS = 1 << 3,
	CAMEL_MIME_FILTER_TOHTML_MARK_CITATION = 1 << 4,
	CAMEL_MIME_FILTER_TOHTML_CONVERT_ADDRESSES = 1 << 5,
	CAMEL_MIME_FILTER_TOHTML_ESCAPE_8BIT = 1 << 6,
	CAMEL_MIME_FILTER_TOHTML_CITE = 1 << 7,
	CAMEL_MIME_FILTER_TOHTML_PRESERVE_8BIT = 1 << 8,
	CAMEL_MIME_FILTER_TOHTML_FORMAT_FLOWED = 1 << 9,
	CAMEL_MIME_FILTER_TOHTML_QUOTE_CITATION = 1 << 10
} CamelMimeFilterToHTMLFlags;

/**
 * CAMEL_STORE_INFO_FOLDER_TYPE_BIT: (value 10)
 * The folder store info type bitshift value.
 **/
#define CAMEL_STORE_INFO_FOLDER_TYPE_BIT (10)

/* WARNING: This enum and CamelFolderInfoFlags must stay in sync.
 * FIXME: Eliminate the need for two separate types. */
typedef enum { /*< flags >*/
	CAMEL_STORE_INFO_FOLDER_NOSELECT = 1 << 0,
	CAMEL_STORE_INFO_FOLDER_NOINFERIORS = 1 << 1,
	CAMEL_STORE_INFO_FOLDER_CHILDREN = 1 << 2,
	CAMEL_STORE_INFO_FOLDER_NOCHILDREN = 1 << 3,
	CAMEL_STORE_INFO_FOLDER_SUBSCRIBED = 1 << 4,
	CAMEL_STORE_INFO_FOLDER_VIRTUAL = 1 << 5,
	CAMEL_STORE_INFO_FOLDER_SYSTEM = 1 << 6,
	CAMEL_STORE_INFO_FOLDER_VTRASH = 1 << 7,
	CAMEL_STORE_INFO_FOLDER_SHARED_TO_ME = 1 << 8,
	CAMEL_STORE_INFO_FOLDER_SHARED_BY_ME = 1 << 9,

	CAMEL_STORE_INFO_FOLDER_TYPE_NORMAL = 0 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_INBOX = 1 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_OUTBOX = 2 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_TRASH = 3 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_JUNK = 4 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_SENT = 5 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_CONTACTS = 6 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_EVENTS = 7 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_MEMOS = 8 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_TASKS = 9 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_ALL = 10 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_ARCHIVE = 11 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,
	CAMEL_STORE_INFO_FOLDER_TYPE_DRAFTS = 12 << CAMEL_STORE_INFO_FOLDER_TYPE_BIT,

	CAMEL_STORE_INFO_FOLDER_READONLY = 1 << 16,
	CAMEL_STORE_INFO_FOLDER_WRITEONLY = 1 << 17,
	CAMEL_STORE_INFO_FOLDER_FLAGGED = 1 << 18,

	CAMEL_STORE_INFO_FOLDER_LAST          = 1 << 24  /*< skip >*/
} CamelStoreInfoFlags;

/**
 * CAMEL_STORE_INFO_FOLDER_TYPE_MASK: (value 64512)
 * The folder store info type mask value.
 **/
#define CAMEL_STORE_INFO_FOLDER_TYPE_MASK  (0x3F << CAMEL_STORE_INFO_FOLDER_TYPE_BIT)

/**
 * CamelFetchHeadersType:
 * @CAMEL_FETCH_HEADERS_BASIC:
 *     Fetch only basic headers (Date, From, To, Subject, etc.).
 * @CAMEL_FETCH_HEADERS_BASIC_AND_MAILING_LIST:
 *     Fetch all basic headers and mailing list headers.
 * @CAMEL_FETCH_HEADERS_ALL:
 *     Fetch all available message headers.
 *
 * Describes what headers to fetch when downloading message summaries.
 *
 * Since: 3.2
 **/
typedef enum {
	CAMEL_FETCH_HEADERS_BASIC,
	CAMEL_FETCH_HEADERS_BASIC_AND_MAILING_LIST,
	CAMEL_FETCH_HEADERS_ALL
} CamelFetchHeadersType;

/**
 * CamelJunkStatus:
 * @CAMEL_JUNK_STATUS_ERROR:
 *     An error occurred while invoking the junk filter.
 * @CAMEL_JUNK_STATUS_INCONCLUSIVE:
 *     The junk filter could not determine whether the message is junk.
 * @CAMEL_JUNK_STATUS_MESSAGE_IS_JUNK:
 *     The junk filter believes the message is junk.
 * @CAMEL_JUNK_STATUS_MESSAGE_IS_NOT_JUNK:
 *     The junk filter believes the message is not junk.
 *
 * These are result codes used when passing messages through a junk filter.
 **/
typedef enum {
	CAMEL_JUNK_STATUS_ERROR,
	CAMEL_JUNK_STATUS_INCONCLUSIVE,
	CAMEL_JUNK_STATUS_MESSAGE_IS_JUNK,
	CAMEL_JUNK_STATUS_MESSAGE_IS_NOT_JUNK
} CamelJunkStatus;

typedef enum {
	CAMEL_MIME_FILTER_BASIC_INVALID,
	CAMEL_MIME_FILTER_BASIC_BASE64_ENC,
	CAMEL_MIME_FILTER_BASIC_BASE64_DEC,
	CAMEL_MIME_FILTER_BASIC_QP_ENC,
	CAMEL_MIME_FILTER_BASIC_QP_DEC,
	CAMEL_MIME_FILTER_BASIC_UU_ENC,
	CAMEL_MIME_FILTER_BASIC_UU_DEC
} CamelMimeFilterBasicType;

typedef enum {
	CAMEL_MIME_FILTER_CRLF_ENCODE,
	CAMEL_MIME_FILTER_CRLF_DECODE
} CamelMimeFilterCRLFDirection;

typedef enum {
	CAMEL_MIME_FILTER_CRLF_MODE_CRLF_DOTS,
	CAMEL_MIME_FILTER_CRLF_MODE_CRLF_ONLY
} CamelMimeFilterCRLFMode;

typedef enum {
	CAMEL_MIME_FILTER_GZIP_MODE_ZIP,
	CAMEL_MIME_FILTER_GZIP_MODE_UNZIP
} CamelMimeFilterGZipMode;

typedef enum {
	CAMEL_MIME_FILTER_YENC_DIRECTION_ENCODE,
	CAMEL_MIME_FILTER_YENC_DIRECTION_DECODE
} CamelMimeFilterYencDirection;

/**
 * CamelNetworkSecurityMethod:
 * @CAMEL_NETWORK_SECURITY_METHOD_NONE:
 *   Use an unencrypted network connection.
 * @CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT:
 *   Use SSL by connecting to an alternate port number.
 * @CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT:
 *   Use SSL or TLS by connecting to the standard port and invoking
 *   STARTTLS before authenticating.  This is the recommended method.
 *
 * Methods for establishing an encrypted (or unencrypted) network connection.
 *
 * Since: 3.2
 **/
typedef enum {
	CAMEL_NETWORK_SECURITY_METHOD_NONE,
	CAMEL_NETWORK_SECURITY_METHOD_SSL_ON_ALTERNATE_PORT,
	CAMEL_NETWORK_SECURITY_METHOD_STARTTLS_ON_STANDARD_PORT
} CamelNetworkSecurityMethod;

typedef enum {
	CAMEL_PROVIDER_CONF_END,
	CAMEL_PROVIDER_CONF_SECTION_START,
	CAMEL_PROVIDER_CONF_SECTION_END,
	CAMEL_PROVIDER_CONF_CHECKBOX,
	CAMEL_PROVIDER_CONF_CHECKSPIN,
	CAMEL_PROVIDER_CONF_ENTRY,
	CAMEL_PROVIDER_CONF_LABEL,
	CAMEL_PROVIDER_CONF_HIDDEN,
	CAMEL_PROVIDER_CONF_OPTIONS,
	CAMEL_PROVIDER_CONF_PLACEHOLDER
} CamelProviderConfType;

/**
 * CamelProviderFlags:
 * @CAMEL_PROVIDER_IS_REMOTE:
 *   Provider works with remote data.
 * @CAMEL_PROVIDER_IS_LOCAL:
 *   Provider can be used as a backend for local folder tree folders.
 *   (Not just the opposite of #CAMEL_PROVIDER_IS_REMOTE.)
 * @CAMEL_PROVIDER_IS_SOURCE:
 *   Mail arrives there, so it should be offered as an option in the
 *   mail config dialog.
 * @CAMEL_PROVIDER_IS_STORAGE:
 *   Mail is stored there.  It will appear in the folder tree.
 * @CAMEL_PROVIDER_IS_EXTERNAL:
 *   Provider appears in the folder tree but is not created by the
 *   mail component.
 * @CAMEL_PROVIDER_HAS_LICENSE:
 *   Provider configuration first needs the license to be accepted.
 *   (No longer used.)
 * @CAMEL_PROVIDER_ALLOW_REAL_TRASH_FOLDER:
 *   Provider may use a real trash folder instead of a virtual folder.
 * @CAMEL_PROVIDER_ALLOW_REAL_JUNK_FOLDER:
 *   Provider may use a real junk folder instead of a virtual folder.
 * @CAMEL_PROVIDER_DISABLE_SENT_FOLDER:
 *   Provider requests to not use the Sent folder when sending with it.
 * @CAMEL_PROVIDER_SUPPORTS_SSL:
 *   Provider supports SSL/TLS connections.
 * @CAMEL_PROVIDER_SUPPORTS_MOBILE_DEVICES:
 *  Download limited set of emails instead of operating on full cache.
 * @CAMEL_PROVIDER_SUPPORTS_BATCH_FETCH:
 *  Support to fetch messages in batch.
 * @CAMEL_PROVIDER_SUPPORTS_PURGE_MESSAGE_CACHE:
 *  Support to remove oldest downloaded messages to conserve space.
 *
 **/
typedef enum { /*< flags >*/
	CAMEL_PROVIDER_IS_REMOTE = 1 << 0,
	CAMEL_PROVIDER_IS_LOCAL = 1 << 1,
	CAMEL_PROVIDER_IS_EXTERNAL = 1 << 2,
	CAMEL_PROVIDER_IS_SOURCE = 1 << 3,
	CAMEL_PROVIDER_IS_STORAGE = 1 << 4,
	CAMEL_PROVIDER_SUPPORTS_SSL = 1 << 5,
	CAMEL_PROVIDER_HAS_LICENSE = 1 << 6,
	CAMEL_PROVIDER_DISABLE_SENT_FOLDER = 1 << 7,
	CAMEL_PROVIDER_ALLOW_REAL_TRASH_FOLDER = 1 << 8,
	CAMEL_PROVIDER_ALLOW_REAL_JUNK_FOLDER = 1 << 9,
	CAMEL_PROVIDER_SUPPORTS_MOBILE_DEVICES = 1 << 10,
	CAMEL_PROVIDER_SUPPORTS_BATCH_FETCH = 1 << 11,
	CAMEL_PROVIDER_SUPPORTS_PURGE_MESSAGE_CACHE = 1 << 12
} CamelProviderFlags;

typedef enum {
	CAMEL_PROVIDER_STORE,
	CAMEL_PROVIDER_TRANSPORT,
	CAMEL_NUM_PROVIDER_TYPES  /*< skip >*/
} CamelProviderType;

typedef enum {
	CAMEL_SASL_ANON_TRACE_EMAIL,
	CAMEL_SASL_ANON_TRACE_OPAQUE,
	CAMEL_SASL_ANON_TRACE_EMPTY
} CamelSaslAnonTraceType;

/**
 * CamelRecipientCertificateFlags:
 * @CAMEL_RECIPIENT_CERTIFICATE_SMIME: Retrieve S/MIME certificates; this cannot be used
 *    together with @CAMEL_RECIPIENT_CERTIFICATE_PGP
 * @CAMEL_RECIPIENT_CERTIFICATE_PGP: Retrieve PGP keys; this cannot be used
 *    together with @CAMEL_RECIPIENT_CERTIFICATE_SMIME.
 *
 * Flags used to camel_session_get_recipient_certificates_sync() call.
 *
 * Since: 3.30
 **/
typedef enum { /*< flags >*/
	CAMEL_RECIPIENT_CERTIFICATE_SMIME = 1 << 0,
	CAMEL_RECIPIENT_CERTIFICATE_PGP = 1 << 1
} CamelRecipientCertificateFlags;

/**
 * CamelServiceConnectionStatus:
 * @CAMEL_SERVICE_DISCONNECTED:
 *   #CamelService is disconnected from a remote server.
 * @CAMEL_SERVICE_CONNECTING:
 *   #CamelService is connecting to a remote server.
 * @CAMEL_SERVICE_CONNECTED:
 *   #CamelService is connected to a remote server.
 * @CAMEL_SERVICE_DISCONNECTING:
 *   #CamelService is disconnecting from a remote server.
 *
 * Connection status returned by camel_service_get_connection_status().
 *
 * Since: 3.6
 **/
typedef enum {
	CAMEL_SERVICE_DISCONNECTED,
	CAMEL_SERVICE_CONNECTING,
	CAMEL_SERVICE_CONNECTED,
	CAMEL_SERVICE_DISCONNECTING
} CamelServiceConnectionStatus;

typedef enum {
	CAMEL_SESSION_ALERT_INFO,
	CAMEL_SESSION_ALERT_WARNING,
	CAMEL_SESSION_ALERT_ERROR
} CamelSessionAlertType;

/**
 * CamelSortType:
 * @CAMEL_SORT_ASCENDING:
 *   Sorting is in ascending order.
 * @CAMEL_SORT_DESCENDING:
 *   Sorting is in descending order.
 *
 * Determines the direction of a sort.
 *
 * Since: 3.2
 **/
typedef enum {
	CAMEL_SORT_ASCENDING,
	CAMEL_SORT_DESCENDING
} CamelSortType;

typedef enum { /*< flags >*/
	CAMEL_STORE_VTRASH = 1 << 0,
	CAMEL_STORE_VJUNK = 1 << 1,
	CAMEL_STORE_PROXY = 1 << 2,
	CAMEL_STORE_IS_MIGRATING = 1 << 3,
	CAMEL_STORE_REAL_JUNK_FOLDER = 1 << 4,
	CAMEL_STORE_CAN_EDIT_FOLDERS = 1 << 5,
	CAMEL_STORE_USE_CACHE_DIR = 1 << 6,
	CAMEL_STORE_CAN_DELETE_FOLDERS_AT_ONCE = 1 << 7,
	CAMEL_STORE_SUPPORTS_INITIAL_SETUP = 1 << 8
} CamelStoreFlags;

/**
 * CamelStoreGetFolderInfoFlags:
 * @CAMEL_STORE_FOLDER_INFO_FAST:
 * @CAMEL_STORE_FOLDER_INFO_RECURSIVE:
 * @CAMEL_STORE_FOLDER_INFO_SUBSCRIBED:
 * @CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL:
 *   Do not include virtual trash or junk folders.
 * @CAMEL_STORE_FOLDER_INFO_SUBSCRIPTION_LIST:
 *   Fetch only the subscription list. Clients should use this
 *   flag for requesting the list of folders available for
 *   subscription. Used in Exchange / IMAP connectors for public
 *   folder fetching.
 * @CAMEL_STORE_FOLDER_INFO_REFRESH:
 *   Treat this call as a request to refresh the folder summary;
 *   for remote accounts it can be to re-fetch fresh folder
 *   content from the server and update the local cache.
 **/
typedef enum { /*< flags >*/
	CAMEL_STORE_FOLDER_INFO_FAST = 1 << 0,
	CAMEL_STORE_FOLDER_INFO_RECURSIVE = 1 << 1,
	CAMEL_STORE_FOLDER_INFO_SUBSCRIBED = 1 << 2,
	CAMEL_STORE_FOLDER_INFO_NO_VIRTUAL = 1 << 3,
	CAMEL_STORE_FOLDER_INFO_SUBSCRIPTION_LIST = 1 << 4,
	CAMEL_STORE_FOLDER_INFO_REFRESH = 1 << 5
} CamelStoreGetFolderInfoFlags;

typedef enum { /*< flags >*/
	CAMEL_STORE_READ = 1 << 0,
	CAMEL_STORE_WRITE = 1 << 1
} CamelStorePermissionFlags;

/* Note: If you change this, make sure you change the
 *       'encodings' array in camel-mime-part.c. */
typedef enum {
	CAMEL_TRANSFER_ENCODING_DEFAULT,
	CAMEL_TRANSFER_ENCODING_7BIT,
	CAMEL_TRANSFER_ENCODING_8BIT,
	CAMEL_TRANSFER_ENCODING_BASE64,
	CAMEL_TRANSFER_ENCODING_QUOTEDPRINTABLE,
	CAMEL_TRANSFER_ENCODING_BINARY,
	CAMEL_TRANSFER_ENCODING_UUENCODE,
	CAMEL_TRANSFER_NUM_ENCODINGS
} CamelTransferEncoding;

/**
 * CamelThreeState:
 * @CAMEL_THREE_STATE_OFF: the three-state value is Off
 * @CAMEL_THREE_STATE_ON: the three-state value is On
 * @CAMEL_THREE_STATE_INCONSISTENT: the three-state value is neither On, nor Off
 *
 * Describes a three-state value, which can be either Off, On or Inconsistent.
 *
 * Since: 3.22
 **/
typedef enum {
	CAMEL_THREE_STATE_OFF = 0,
	CAMEL_THREE_STATE_ON,
	CAMEL_THREE_STATE_INCONSISTENT
} CamelThreeState;

/**
 * CamelCompareType:
 * @CAMEL_COMPARE_CASE_INSENSITIVE: compare case insensitively
 * @CAMEL_COMPARE_CASE_SENSITIVE: compare case sensitively
 *
 * Declares the compare type to use.
 *
 * Since: 3.24
 **/
typedef enum {
	CAMEL_COMPARE_CASE_INSENSITIVE,
	CAMEL_COMPARE_CASE_SENSITIVE
} CamelCompareType;

/**
 * CamelTimeUnit:
 * @CAMEL_TIME_UNIT_DAYS: days
 * @CAMEL_TIME_UNIT_WEEKS: weeks
 * @CAMEL_TIME_UNIT_MONTHS: months
 * @CAMEL_TIME_UNIT_YEARS: years
 *
 * Declares time unit, which serves to interpret the time value,
 * like in #CamelOfflineSettings.
 *
 * Since: 3.24
 **/
typedef enum {
	CAMEL_TIME_UNIT_DAYS = 1,
	CAMEL_TIME_UNIT_WEEKS,
	CAMEL_TIME_UNIT_MONTHS,
	CAMEL_TIME_UNIT_YEARS
} CamelTimeUnit;

#endif /* CAMEL_ENUMS_H */
