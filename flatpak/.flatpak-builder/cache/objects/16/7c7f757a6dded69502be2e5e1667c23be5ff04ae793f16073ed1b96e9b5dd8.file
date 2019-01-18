/* $Id$ $Revision$ */
/* vim:set shiftwidth=4 ts=8: */

/*************************************************************************
 * Copyright (c) 2011 AT&T Intellectual Property 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: See CVS logs. Details at http://www.graphviz.org/
 *************************************************************************/

#ifndef GVCOMMON_H
#define GVCOMMON_H

#ifdef __cplusplus
extern "C" {
#endif

    typedef struct GVCOMMON_s {
	char **info;
	char *cmdname;
	int verbose;
	boolean config, auto_outfile_names;
        void (*errorfn) (const char *fmt, ...);
	const char **show_boxes; /* emit code for correct box coordinates */
	const char **lib; 

	/* rendering state */
	int viewNum;     /* current view - 1 based count of views,
			    all pages in all layers */
	const lt_symlist_t *builtins;
	int demand_loading;
    } GVCOMMON_t;

#ifdef __cplusplus
}
#endif
#endif				/* GVCOMMON_H */
