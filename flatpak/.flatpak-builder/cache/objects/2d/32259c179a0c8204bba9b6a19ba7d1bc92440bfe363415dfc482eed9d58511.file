/*
 * e-source-mail-submission.h
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

#if !defined (__LIBEDATASERVER_H_INSIDE__) && !defined (LIBEDATASERVER_COMPILATION)
#error "Only <libedataserver/libedataserver.h> should be included directly."
#endif

#ifndef E_SOURCE_MAIL_SUBMISSION_H
#define E_SOURCE_MAIL_SUBMISSION_H

#include <libedataserver/e-source-extension.h>

/* Standard GObject macros */
#define E_TYPE_SOURCE_MAIL_SUBMISSION \
	(e_source_mail_submission_get_type ())
#define E_SOURCE_MAIL_SUBMISSION(obj) \
	(G_TYPE_CHECK_INSTANCE_CAST \
	((obj), E_TYPE_SOURCE_MAIL_SUBMISSION, ESourceMailSubmission))
#define E_SOURCE_MAIL_SUBMISSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_CAST \
	((cls), E_TYPE_SOURCE_MAIL_SUBMISSION, ESourceMailSubmissionClass))
#define E_IS_SOURCE_MAIL_SUBMISSION(obj) \
	(G_TYPE_CHECK_INSTANCE_TYPE \
	((obj), E_TYPE_SOURCE_MAIL_SUBMISSION))
#define E_IS_SOURCE_MAIL_SUBMISSION_CLASS(cls) \
	(G_TYPE_CHECK_CLASS_TYPE \
	((cls), E_TYPE_SOURCE_MAIL_SUBMISSION))
#define E_SOURCE_MAIL_SUBMISSION_GET_CLASS(obj) \
	(G_TYPE_INSTANCE_GET_CLASS \
	((obj), E_TYPE_SOURCE_MAIL_SUBMISSION, ESourceMailSubmissionClass))

/**
 * E_SOURCE_EXTENSION_MAIL_SUBMISSION:
 *
 * Pass this extension name to e_source_get_extension() to access
 * #ESourceMailSubmission.  This is also used as a group name in key files.
 *
 * Since: 3.6
 **/
#define E_SOURCE_EXTENSION_MAIL_SUBMISSION "Mail Submission"

G_BEGIN_DECLS

typedef struct _ESourceMailSubmission ESourceMailSubmission;
typedef struct _ESourceMailSubmissionClass ESourceMailSubmissionClass;
typedef struct _ESourceMailSubmissionPrivate ESourceMailSubmissionPrivate;

/**
 * ESourceMailSubmission:
 *
 * Contains only private data that should be read and manipulated using the
 * function below.
 *
 * Since: 3.6
 **/
struct _ESourceMailSubmission {
	/*< private >*/
	ESourceExtension parent;
	ESourceMailSubmissionPrivate *priv;
};

struct _ESourceMailSubmissionClass {
	ESourceExtensionClass parent_class;
};

GType		e_source_mail_submission_get_type
					(void) G_GNUC_CONST;
const gchar *	e_source_mail_submission_get_sent_folder
					(ESourceMailSubmission *extension);
gchar *		e_source_mail_submission_dup_sent_folder
					(ESourceMailSubmission *extension);
void		e_source_mail_submission_set_sent_folder
					(ESourceMailSubmission *extension,
					 const gchar *sent_folder);
gboolean	e_source_mail_submission_get_use_sent_folder
					(ESourceMailSubmission *extension);
void		e_source_mail_submission_set_use_sent_folder
					(ESourceMailSubmission *extension,
					 gboolean use_sent_folder);
const gchar *	e_source_mail_submission_get_transport_uid
					(ESourceMailSubmission *extension);
gchar *		e_source_mail_submission_dup_transport_uid
					(ESourceMailSubmission *extension);
void		e_source_mail_submission_set_transport_uid
					(ESourceMailSubmission *extension,
					 const gchar *transport_uid);
gboolean	e_source_mail_submission_get_replies_to_origin_folder
					(ESourceMailSubmission *extension);
void		e_source_mail_submission_set_replies_to_origin_folder
					(ESourceMailSubmission *extension,
					 gboolean replies_to_origin_folder);

G_END_DECLS

#endif /* E_SOURCE_MAIL_SUBMISSION_H */
