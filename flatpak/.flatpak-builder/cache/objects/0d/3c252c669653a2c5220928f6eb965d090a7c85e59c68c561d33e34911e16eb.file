/* $Id$Revision: */
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

#ifdef __cplusplus
extern "C" {
#endif

#ifndef GVPR_H
#define GVPR_H

#include "cgraph.h"
#ifdef _MSC_VER
typedef int ssize_t;
#endif

/* Bits for flags variable in gvprstate_t.
 * Included here so that calling programs can use the first
 * two in gvpropts.flags
 */
  /* If set, gvpr calls exit() on errors */
#define GV_USE_EXIT 1    
  /* If set, gvpr stores output graphs in gvpropts */
#define GV_USE_OUTGRAPH 2
  /* Use longjmp to return to top-level call in gvpr */
#define GV_USE_JUMP 4
  /* $tvnext has been set but not used */
#define GV_NEXT_SET 8


typedef ssize_t (*gvprwr) (void*, const char *buf, size_t nbyte, void*);
typedef int (*gvpruserfn) (char *);
typedef struct {
    char* name;
    gvpruserfn fn;
} gvprbinding;

typedef struct {
    Agraph_t** ingraphs;      /* NULL-terminated array of input graphs */
    int n_outgraphs;          /* if GV_USE_OUTGRAPH set, output graphs */
    Agraph_t** outgraphs;
    gvprwr out;               /* write function for stdout */
    gvprwr err;               /* write function for stderr */
    int flags;
    gvprbinding* bindings;    /* array of bindings, terminated with {NULL,NULL} */
} gvpropts;

    extern int gvpr (int argc, char *argv[], gvpropts* opts);

#endif

#ifdef __cplusplus
}
#endif
