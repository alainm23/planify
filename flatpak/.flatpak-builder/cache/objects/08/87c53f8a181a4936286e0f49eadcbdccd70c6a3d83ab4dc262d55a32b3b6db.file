/* -*- Mode: C; tab-width: 8; indent-tabs-mode: t; c-basic-offset: 8 -*- */
/*
 * Copyright (C) 2017 Red Hat, Inc. (www.redhat.com)
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
 */

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_WEBDAV_SESSION_H
#define E_WEBDAV_SESSION_H

#include <glib.h>
#include <libxml/xpath.h>

#include <libedataserver/e-data-server-util.h>
#include <libedataserver/e-soup-session.h>
#include <libedataserver/e-source.h>
#include <libedataserver/e-xml-document.h>

/* Standard GObject macros */
#define E_TYPE_WEBDAV_SESSION \
	(e_webdav_session_get_type ())
#define E_WEBDAV_SESSION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_WEBDAV_SESSION, EWebDAVSession))
#define E_WEBDAV_SESSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_WEBDAV_SESSION, EWebDAVSessionClass))
#define E_IS_WEBDAV_SESSION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_WEBDAV_SESSION))
#define E_IS_WEBDAV_SESSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_WEBDAV_SESSION))
#define E_WEBDAV_SESSION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_WEBDAV_SESSION, EWebDAVSessionClass))

G_BEGIN_DECLS

#define E_WEBDAV_CAPABILITY_CLASS_1			"1"
#define E_WEBDAV_CAPABILITY_CLASS_2			"2"
#define E_WEBDAV_CAPABILITY_CLASS_3			"3"
#define E_WEBDAV_CAPABILITY_ACCESS_CONTROL		"access-control"
#define E_WEBDAV_CAPABILITY_BIND			"bind"
#define E_WEBDAV_CAPABILITY_EXTENDED_MKCOL		"extended-mkcol"
#define E_WEBDAV_CAPABILITY_ADDRESSBOOK			"addressbook"
#define E_WEBDAV_CAPABILITY_CALENDAR_ACCESS		"calendar-access"
#define E_WEBDAV_CAPABILITY_CALENDAR_SCHEDULE		"calendar-schedule"
#define E_WEBDAV_CAPABILITY_CALENDAR_AUTO_SCHEDULE	"calendar-auto-schedule"
#define E_WEBDAV_CAPABILITY_CALENDAR_PROXY		"calendar-proxy"

#define E_WEBDAV_DEPTH_THIS			"0"
#define E_WEBDAV_DEPTH_THIS_AND_CHILDREN	"1"
#define E_WEBDAV_DEPTH_INFINITY			"infinity"

#define E_WEBDAV_CONTENT_TYPE_XML		"application/xml; charset=\"utf-8\""
#define E_WEBDAV_CONTENT_TYPE_CALENDAR		"text/calendar; charset=\"utf-8\""
#define E_WEBDAV_CONTENT_TYPE_VCARD		"text/vcard; charset=\"utf-8\""

#define E_WEBDAV_NS_DAV				"DAV:"
#define E_WEBDAV_NS_CALDAV			"urn:ietf:params:xml:ns:caldav"
#define E_WEBDAV_NS_CARDDAV			"urn:ietf:params:xml:ns:carddav"
#define E_WEBDAV_NS_CALENDARSERVER		"http://calendarserver.org/ns/"
#define E_WEBDAV_NS_ICAL			"http://apple.com/ns/ical/"

typedef struct _EWebDAVSession EWebDAVSession;
typedef struct _EWebDAVSessionClass EWebDAVSessionClass;
typedef struct _EWebDAVSessionPrivate EWebDAVSessionPrivate;

typedef enum {
	E_WEBDAV_RESOURCE_KIND_UNKNOWN,
	E_WEBDAV_RESOURCE_KIND_ADDRESSBOOK,
	E_WEBDAV_RESOURCE_KIND_CALENDAR,
	E_WEBDAV_RESOURCE_KIND_PRINCIPAL,
	E_WEBDAV_RESOURCE_KIND_COLLECTION,
	E_WEBDAV_RESOURCE_KIND_RESOURCE
} EWebDAVResourceKind;

typedef enum {
	E_WEBDAV_RESOURCE_SUPPORTS_NONE		= 0,
	E_WEBDAV_RESOURCE_SUPPORTS_CONTACTS	= 1 << 0,
	E_WEBDAV_RESOURCE_SUPPORTS_EVENTS	= 1 << 1,
	E_WEBDAV_RESOURCE_SUPPORTS_MEMOS	= 1 << 2,
	E_WEBDAV_RESOURCE_SUPPORTS_TASKS	= 1 << 3,
	E_WEBDAV_RESOURCE_SUPPORTS_FREEBUSY	= 1 << 4,
	E_WEBDAV_RESOURCE_SUPPORTS_TIMEZONE	= 1 << 5,
	E_WEBDAV_RESOURCE_SUPPORTS_LAST		= E_WEBDAV_RESOURCE_SUPPORTS_TIMEZONE
} EWebDAVResourceSupports;

typedef struct _EWebDAVResource {
	EWebDAVResourceKind kind;
	guint32 supports;
	gchar *href;
	gchar *etag;
	gchar *display_name;
	gchar *content_type;
	gsize content_length;
	glong creation_date;
	glong last_modified;
	gchar *description;
	gchar *color;
} EWebDAVResource;

GType		e_webdav_resource_get_type		(void) G_GNUC_CONST;
EWebDAVResource *
		e_webdav_resource_new			(EWebDAVResourceKind kind,
							 guint32 supports,
							 const gchar *href,
							 const gchar *etag,
							 const gchar *display_name,
							 const gchar *content_type,
							 gsize content_length,
							 glong creation_date,
							 glong last_modified,
							 const gchar *description,
							 const gchar *color);
EWebDAVResource *
		e_webdav_resource_copy			(const EWebDAVResource *src);
void		e_webdav_resource_free			(gpointer ptr /* EWebDAVResource * */);

typedef enum {
	E_WEBDAV_LIST_ALL		= 0xFFFFFFFF,
	E_WEBDAV_LIST_NONE		= 0,
	E_WEBDAV_LIST_SUPPORTS		= 1 << 0,
	E_WEBDAV_LIST_ETAG		= 1 << 1,
	E_WEBDAV_LIST_DISPLAY_NAME	= 1 << 2,
	E_WEBDAV_LIST_CONTENT_TYPE	= 1 << 3,
	E_WEBDAV_LIST_CONTENT_LENGTH	= 1 << 4,
	E_WEBDAV_LIST_CREATION_DATE	= 1 << 5,
	E_WEBDAV_LIST_LAST_MODIFIED	= 1 << 6,
	E_WEBDAV_LIST_DESCRIPTION	= 1 << 7,
	E_WEBDAV_LIST_COLOR		= 1 << 8
} EWebDAVListFlags;

/**
 * EWebDAVPropstatTraverseFunc:
 * @webdav: an #EWebDAVSession
 * @xpath_ctx: an #xmlXPathContextPtr
 * @xpath_prop_prefix: (nullable): an XPath prefix for the current prop element, without trailing forward slash
 * @request_uri: a #SoupURI, containing the request URI, maybe redirected by the server
 * @href: (nullable): a full URI to which the property belongs, or %NULL, when not found
 * @status_code: an HTTP status code for this property
 * @user_data: user data, as passed to e_webdav_session_propfind_sync()
 *
 * A callback function for e_webdav_session_propfind_sync(),
 * e_webdav_session_report_sync() and other XML response with DAV:propstat
 * elements traversal functions.
 *
 * The @xpath_prop_prefix can be %NULL only once, for the first time,
 * which is meant to let the caller setup the @xpath_ctx, like to register
 * its own namespaces to it with e_xml_xpath_context_register_namespaces().
 * All other invocations of the function will have @xpath_prop_prefix non-%NULL.
 *
 * Returns: %TRUE to continue traversal of the returned response, %FALSE otherwise.
 *
 * Since: 3.26
 **/
typedef gboolean (* EWebDAVPropstatTraverseFunc)	(EWebDAVSession *webdav,
							 xmlXPathContext *xpath_ctx,
							 const gchar *xpath_prop_prefix,
							 const SoupURI *request_uri,
							 const gchar *href,
							 guint status_code,
							 gpointer user_data);

typedef enum {
	E_WEBDAV_PROPERTY_SET,
	E_WEBDAV_PROPERTY_REMOVE
} EWebDAVPropertyChangeKind;

typedef struct _EWebDAVPropertyChange {
	EWebDAVPropertyChangeKind kind;
	gchar *ns_uri;
	gchar *name;
	gchar *value;
} EWebDAVPropertyChange;

GType		e_webdav_property_change_get_type	(void) G_GNUC_CONST;
EWebDAVPropertyChange *
		e_webdav_property_change_new_set	(const gchar *ns_uri,
							 const gchar *name,
							 const gchar *value);
EWebDAVPropertyChange *
		e_webdav_property_change_new_remove	(const gchar *ns_uri,
							 const gchar *name);
EWebDAVPropertyChange *
		e_webdav_property_change_copy		(const EWebDAVPropertyChange *src);
void		e_webdav_property_change_free		(gpointer ptr); /* EWebDAVPropertyChange * */

typedef enum {
	E_WEBDAV_LOCK_EXCLUSIVE,
	E_WEBDAV_LOCK_SHARED
} EWebDAVLockScope;

#define E_WEBDAV_COLLATION_ASCII_NUMERIC_SUFFIX "ascii-numeric"
#define E_WEBDAV_COLLATION_ASCII_NUMERIC "i;" E_WEBDAV_COLLATION_ASCII_NUMERIC_SUFFIX

#define E_WEBDAV_COLLATION_ASCII_CASEMAP_SUFFIX "ascii-casemap"
#define E_WEBDAV_COLLATION_ASCII_CASEMAP "i;" E_WEBDAV_COLLATION_ASCII_CASEMAP_SUFFIX

#define E_WEBDAV_COLLATION_OCTET_SUFFIX "octet"
#define E_WEBDAV_COLLATION_OCTET "i;" E_WEBDAV_COLLATION_OCTET_SUFFIX

#define E_WEBDAV_COLLATION_UNICODE_CASEMAP_SUFFIX "unicode-casemap"
#define E_WEBDAV_COLLATION_UNICODE_CASEMAP "i;" E_WEBDAV_COLLATION_UNICODE_CASEMAP_SUFFIX

typedef enum {
	E_WEBDAV_PRIVILEGE_KIND_UNKNOWN = 0,
	E_WEBDAV_PRIVILEGE_KIND_ABSTRACT,
	E_WEBDAV_PRIVILEGE_KIND_AGGREGATE,
	E_WEBDAV_PRIVILEGE_KIND_COMMON
} EWebDAVPrivilegeKind;

typedef enum {
	E_WEBDAV_PRIVILEGE_HINT_UNKNOWN = 0,
	E_WEBDAV_PRIVILEGE_HINT_READ,
	E_WEBDAV_PRIVILEGE_HINT_WRITE,
	E_WEBDAV_PRIVILEGE_HINT_WRITE_PROPERTIES,
	E_WEBDAV_PRIVILEGE_HINT_WRITE_CONTENT,
	E_WEBDAV_PRIVILEGE_HINT_UNLOCK,
	E_WEBDAV_PRIVILEGE_HINT_READ_ACL,
	E_WEBDAV_PRIVILEGE_HINT_WRITE_ACL,
	E_WEBDAV_PRIVILEGE_HINT_READ_CURRENT_USER_PRIVILEGE_SET,
	E_WEBDAV_PRIVILEGE_HINT_BIND,
	E_WEBDAV_PRIVILEGE_HINT_UNBIND,
	E_WEBDAV_PRIVILEGE_HINT_ALL,
	E_WEBDAV_PRIVILEGE_HINT_CALDAV_READ_FREE_BUSY
} EWebDAVPrivilegeHint;

typedef struct _EWebDAVPrivilege {
	gchar *ns_uri;
	gchar *name;
	gchar *description;
	EWebDAVPrivilegeKind kind;
	EWebDAVPrivilegeHint hint;
} EWebDAVPrivilege;

GType		e_webdav_privilege_get_type		(void) G_GNUC_CONST;
EWebDAVPrivilege *
		e_webdav_privilege_new			(const gchar *ns_uri,
							 const gchar *name,
							 const gchar *description,
							 EWebDAVPrivilegeKind kind,
							 EWebDAVPrivilegeHint hint);
EWebDAVPrivilege *
		e_webdav_privilege_copy			(const EWebDAVPrivilege *src);
void		e_webdav_privilege_free			(gpointer ptr); /* EWebDAVPrivilege * */

typedef enum {
	E_WEBDAV_ACE_PRINCIPAL_UNKNOWN = 0,
	E_WEBDAV_ACE_PRINCIPAL_HREF,
	E_WEBDAV_ACE_PRINCIPAL_ALL,
	E_WEBDAV_ACE_PRINCIPAL_AUTHENTICATED,
	E_WEBDAV_ACE_PRINCIPAL_UNAUTHENTICATED,
	E_WEBDAV_ACE_PRINCIPAL_PROPERTY,
	E_WEBDAV_ACE_PRINCIPAL_SELF,
	E_WEBDAV_ACE_PRINCIPAL_OWNER /* special-case, 'property' with only 'DAV:owner' child */
} EWebDAVACEPrincipalKind;

typedef enum {
	E_WEBDAV_ACE_FLAG_UNKNOWN	= 0,
	E_WEBDAV_ACE_FLAG_GRANT		= 1 << 0,
	E_WEBDAV_ACE_FLAG_DENY		= 1 << 1,
	E_WEBDAV_ACE_FLAG_INVERT	= 1 << 2,
	E_WEBDAV_ACE_FLAG_PROTECTED	= 1 << 3,
	E_WEBDAV_ACE_FLAG_INHERITED	= 1 << 4
} EWebDAVACEFlag;

typedef struct _EWebDAVAccessControlEntry {
	EWebDAVACEPrincipalKind principal_kind;
	gchar *principal_href; /* valid only if principal_kind is E_WEBDAV_ACE_PRINCIPAL_HREF */
	guint32 flags; /* bit-or of EWebDAVACEFlag */
	gchar *inherited_href; /* valid only if flags contain E_WEBDAV_ACE_INHERITED */
	GSList *privileges; /* EWebDAVPrivilege * */
} EWebDAVAccessControlEntry;

GType		e_webdav_access_control_entry_get_type	(void) G_GNUC_CONST;
EWebDAVAccessControlEntry *
		e_webdav_access_control_entry_new	(EWebDAVACEPrincipalKind principal_kind,
							 const gchar *principal_href,
							 guint32 flags, /* bit-or of EWebDAVACEFlag */
							 const gchar *inherited_href);
EWebDAVAccessControlEntry *
		e_webdav_access_control_entry_copy	(const EWebDAVAccessControlEntry *src);
void		e_webdav_access_control_entry_free	(gpointer ptr); /* EWebDAVAccessControlEntry * */
void		e_webdav_access_control_entry_append_privilege
							(EWebDAVAccessControlEntry *ace,
							 EWebDAVPrivilege *privilege);
GSList *	e_webdav_access_control_entry_get_privileges
							(EWebDAVAccessControlEntry *ace); /* EWebDAVPrivilege * */

typedef enum {
	E_WEBDAV_ACL_RESTRICTION_NONE			= 0,
	E_WEBDAV_ACL_RESTRICTION_GRANT_ONLY		= 1 << 0,
	E_WEBDAV_ACL_RESTRICTION_NO_INVERT		= 1 << 1,
	E_WEBDAV_ACL_RESTRICTION_DENY_BEFORE_GRANT	= 1 << 2,
	E_WEBDAV_ACL_RESTRICTION_REQUIRED_PRINCIPAL	= 1 << 3
} EWebDAVACLRestrictions;

/**
 * EWebDAVSession:
 *
 * Contains only private data that should be read and manipulated using the
 * functions below.
 *
 * Since: 3.26
 **/
struct _EWebDAVSession {
	/*< private >*/
	ESoupSession parent;
	EWebDAVSessionPrivate *priv;
};

struct _EWebDAVSessionClass {
	ESoupSessionClass parent_class;

	/* Padding for future expansion */
	gpointer reserved[10];
};

GType		e_webdav_session_get_type		(void) G_GNUC_CONST;

EWebDAVSession *e_webdav_session_new			(ESource *source);
SoupRequestHTTP *
		e_webdav_session_new_request		(EWebDAVSession *webdav,
							 const gchar *method,
							 const gchar *uri,
							 GError **error);
gboolean	e_webdav_session_replace_with_detailed_error
							(EWebDAVSession *webdav,
							 SoupRequestHTTP *request,
							 const GByteArray *response_data,
							 gboolean ignore_multistatus,
							 const gchar *prefix,
							 GError **inout_error);
gchar *		e_webdav_session_ensure_full_uri	(EWebDAVSession *webdav,
							 const SoupURI *request_uri,
							 const gchar *href);
gboolean	e_webdav_session_options_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 GHashTable **out_capabilities,
							 GHashTable **out_allows,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_post_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *data,
							 gsize data_length,
							 gchar **out_content_type,
							 GByteArray **out_content,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_propfind_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *depth,
							 const EXmlDocument *xml,
							 EWebDAVPropstatTraverseFunc func,
							 gpointer func_user_data,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_proppatch_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const EXmlDocument *xml,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_report_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *depth,
							 const EXmlDocument *xml,
							 EWebDAVPropstatTraverseFunc func,
							 gpointer func_user_data,
							 gchar **out_content_type,
							 GByteArray **out_content,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_mkcol_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_mkcol_addressbook_sync	(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *display_name,
							 const gchar *description,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_mkcalendar_sync	(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *display_name,
							 const gchar *description,
							 const gchar *color,
							 guint32 supports, /* bit-or of EWebDAVResourceSupports */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_get_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 gchar **out_href,
							 gchar **out_etag,
							 GOutputStream *out_stream,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_get_data_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 gchar **out_href,
							 gchar **out_etag,
							 gchar **out_bytes,
							 gsize *out_length,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_put_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *etag,
							 const gchar *content_type,
							 GInputStream *stream,
							 gchar **out_href,
							 gchar **out_etag,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_put_data_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *etag,
							 const gchar *content_type,
							 const gchar *bytes,
							 gsize length,
							 gchar **out_href,
							 gchar **out_etag,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_delete_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *depth,
							 const gchar *etag,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_copy_sync		(EWebDAVSession *webdav,
							 const gchar *source_uri,
							 const gchar *destination_uri,
							 const gchar *depth,
							 gboolean can_overwrite,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_move_sync		(EWebDAVSession *webdav,
							 const gchar *source_uri,
							 const gchar *destination_uri,
							 gboolean can_overwrite,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_lock_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *depth,
							 gint32 lock_timeout,
							 const EXmlDocument *xml,
							 gchar **out_lock_token,
							 xmlDoc **out_xml_response,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_refresh_lock_sync	(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *lock_token,
							 gint32 lock_timeout,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_unlock_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *lock_token,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_traverse_multistatus_response
							(EWebDAVSession *webdav,
							 const SoupMessage *message,
							 const GByteArray *xml_data,
							 EWebDAVPropstatTraverseFunc func,
							 gpointer func_user_data,
							 GError **error);
gboolean	e_webdav_session_traverse_mkcol_response
							(EWebDAVSession *webdav,
							 const SoupMessage *message,
							 const GByteArray *xml_data,
							 EWebDAVPropstatTraverseFunc func,
							 gpointer func_user_data,
							 GError **error);
gboolean	e_webdav_session_traverse_mkcalendar_response
							(EWebDAVSession *webdav,
							 const SoupMessage *message,
							 const GByteArray *xml_data,
							 EWebDAVPropstatTraverseFunc func,
							 gpointer func_user_data,
							 GError **error);
gboolean	e_webdav_session_getctag_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 gchar **out_ctag,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_list_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const gchar *depth,
							 guint32 flags, /* bit-or of EWebDAVListFlags */
							 GSList **out_resources, /* EWebDAVResource * */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_update_properties_sync	(EWebDAVSession *webdav,
							 const gchar *uri,
							 const GSList *changes, /* EWebDAVPropertyChange * */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_lock_resource_sync	(EWebDAVSession *webdav,
							 const gchar *uri,
							 EWebDAVLockScope lock_scope,
							 gint32 lock_timeout,
							 const gchar *owner,
							 gchar **out_lock_token,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_acl_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const EXmlDocument *xml,
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_get_supported_privilege_set_sync
							(EWebDAVSession *webdav,
							 const gchar *uri,
							 GNode **out_privileges, /* EWebDAVPrivilege * */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_get_current_user_privilege_set_sync
							(EWebDAVSession *webdav,
							 const gchar *uri,
							 GSList **out_privileges, /* EWebDAVPrivilege * */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_get_acl_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 GSList **out_entries, /* EWebDAVAccessControlEntry * */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_get_acl_restrictions_sync
							(EWebDAVSession *webdav,
							 const gchar *uri,
							 guint32 *out_restrictions, /* bit-or of EWebDAVACLRestrictions */
							 EWebDAVACEPrincipalKind *out_principal_kind,
							 GSList **out_principal_hrefs, /* gchar * */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_get_principal_collection_set_sync
							(EWebDAVSession *webdav,
							 const gchar *uri,
							 GSList **out_principal_hrefs, /* gchar * */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_set_acl_sync		(EWebDAVSession *webdav,
							 const gchar *uri,
							 const GSList *entries, /* EWebDAVAccessControlEntry * */
							 GCancellable *cancellable,
							 GError **error);
gboolean	e_webdav_session_principal_property_search_sync
							(EWebDAVSession *webdav,
							 const gchar *uri,
							 gboolean apply_to_principal_collection_set,
							 const gchar *match_ns_uri,
							 const gchar *match_property,
							 const gchar *match_value,
							 GSList **out_principals, /* EWebDAVResource * */
							 GCancellable *cancellable,
							 GError **error);
gchar *		e_webdav_session_util_maybe_dequote	(gchar *text);
void		e_webdav_session_util_free_privileges	(GNode *privileges); /* EWebDAVPrivilege * */

G_END_DECLS

#endif /* E_WEBDAV_SESSION_H */
