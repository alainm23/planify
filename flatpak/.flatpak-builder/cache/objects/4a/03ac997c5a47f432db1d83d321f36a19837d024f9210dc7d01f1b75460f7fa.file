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

%module gv

#ifdef SWIGTCL
// A typemap telling SWIG to ignore an argument for input
// However, we still need to pass a pointer to the C function
%typemap(in,numinputs=0) char *outdata (Tcl_Obj *o) {
     o = Tcl_NewStringObj(NULL, -1);
     $1 = (char*)o;
}
// A typemap defining how to return an argument by appending it to the result
%typemap(argout) char *outdata {
     Tcl_ListObjAppendElement(interp,$result,(Tcl_Obj*)$1);
}

// A typemap telling SWIG to map const char *channelname to Tcl_Channel *chan
%typemap(in) const char *channelname (int mode) {
    $1 = (char*)Tcl_GetChannel(interp, Tcl_GetString($input), &mode);
// FIXME - need to error if chan is NULL or mode not TCL_WRITABLE
}
#endif

#ifdef SWIGJAVA
%typemap(jstype) char* renderresult "byte[]"
%typemap(jtype)  char* renderresult "byte[]"
%typemap(jni) char* renderresult "jbyteArray"
%typemap(in) Agraph_t *ing (int sz) { 
  $1 = *(Agraph_t **)&jarg1; 
  GD_alg($1) = &sz;
}
%typemap(out) char* renderresult { 
    $result = jenv->NewByteArray (sz1);
    jenv->SetByteArrayRegion ($result, 0, sz1, (jbyte*)$1);
    free ($1);
}
#endif

/*  */
%inline %{
/* some language headers (e.g. php.h, ruby.h) leave these defined */
#undef PACKAGE_BUGREPORT
#undef PACKAGE_STRING
#undef PACKAGE_TARNAME
#undef PACKAGE_VERSION
#undef PACKAGE_NAME

#include "config.h"
#include "gvc.h"

/** New graphs */
/*** New empty graph */
extern Agraph_t *graph(char *name);
extern Agraph_t *digraph(char *name);
extern Agraph_t *strictgraph(char *name);
extern Agraph_t *strictdigraph(char *name);
/*** New graph from a dot-syntax string or file */
extern Agraph_t *readstring(char *string);
extern Agraph_t *read(const char *filename);
extern Agraph_t *read(FILE *f);
/*** Add new subgraph to existing graph */
extern Agraph_t *graph(Agraph_t *g, char *name);

/** New nodes */
/*** Add new node to existing graph */
extern Agnode_t *node(Agraph_t *g, char *name);

/** New edges */
/*** Add new edge between existing nodes */
extern Agedge_t *edge(Agnode_t *t, Agnode_t *h);
/*** Add a new edge between an existing tail node, and a named head node which will be induced in the graph if it doesn't already exist */
extern Agedge_t *edge(Agnode_t *t, char *hname);
/*** Add a new edge between an existing head node, and a named tail node which will be induced in the graph if it doesn't already exist */
extern Agedge_t *edge(char *tname, Agnode_t *h);
/*** Add a new edge between named tail  and head nodes which will be induced in the graph if they don't already exist */
extern Agedge_t *edge(Agraph_t *g, char *tname, char *hname);

/** Setting attribute values */
/*** Set value of named attribute of graph/node/edge - creating attribute if necessary */
extern char *setv(Agraph_t *g, char *attr, char *val);
extern char *setv(Agnode_t *n, char *attr, char *val);
extern char *setv(Agedge_t *e, char *attr, char *val);

/*** Set value of existing attribute of graph/node/edge (using attribute handle) */
extern char *setv(Agraph_t *g, Agsym_t *a, char *val);
extern char *setv(Agnode_t *n, Agsym_t *a, char *val);
extern char *setv(Agedge_t *e, Agsym_t *a, char *val);

/** Getting attribute values */
/*** Get value of named attribute of graph/node/edge */
extern char *getv(Agraph_t *g, char *attr);
extern char *getv(Agnode_t *n, char *attr);
extern char *getv(Agedge_t *e, char *attr);

/*** Get value of attribute of graph/node/edge (using attribute handle) */
extern char *getv(Agraph_t *g, Agsym_t *a);
extern char *getv(Agnode_t *n, Agsym_t *a);
extern char *getv(Agedge_t *e, Agsym_t *a);

/** Obtain names from handles */
extern char *nameof(Agraph_t *g);
extern char *nameof(Agnode_t *n);
//extern char *nameof(Agedge_t *e);
extern char *nameof(Agsym_t *a);

/** Find handles from names */
extern Agraph_t *findsubg(Agraph_t *g, char *name);
extern Agnode_t *findnode(Agraph_t *g, char *name);
extern Agedge_t *findedge(Agnode_t *t, Agnode_t *h);

/** */
extern Agsym_t *findattr(Agraph_t *g, char *name);
extern Agsym_t *findattr(Agnode_t *n, char *name);
extern Agsym_t *findattr(Agedge_t *e, char *name);

/** Misc graph navigators returning handles */
extern Agnode_t *headof(Agedge_t *e);
extern Agnode_t *tailof(Agedge_t *e);
extern Agraph_t *graphof(Agraph_t *g);
extern Agraph_t *graphof(Agedge_t *e);
extern Agraph_t *graphof(Agnode_t *n);
extern Agraph_t *rootof(Agraph_t *g);

/** Obtain handles of proto node/edge for setting default attribute values */
extern Agnode_t *protonode(Agraph_t *g);
extern Agedge_t *protoedge(Agraph_t *g);

/** Iterators */
/*** Iteration termination tests */
extern bool ok(Agraph_t *g);
extern bool ok(Agnode_t *n);
extern bool ok(Agedge_t *e);
extern bool ok(Agsym_t *a);

/*** Iterate over subgraphs of a graph */
extern Agraph_t *firstsubg(Agraph_t *g);
extern Agraph_t *nextsubg(Agraph_t *g, Agraph_t *sg);

/*** Iterate over supergraphs of a graph (obscure and rarely useful) */
extern Agraph_t *firstsupg(Agraph_t *g);
extern Agraph_t *nextsupg(Agraph_t *g, Agraph_t *sg);

/*** Iterate over edges of a graph */
extern Agedge_t *firstedge(Agraph_t *g);
extern Agedge_t *nextedge(Agraph_t *g, Agedge_t *e);

/*** Iterate over outedges of a graph */
extern Agedge_t *firstout(Agraph_t *g);
extern Agedge_t *nextout(Agraph_t *g, Agedge_t *e);

/*** Iterate over edges of a node */
extern Agedge_t *firstedge(Agnode_t *n);
extern Agedge_t *nextedge(Agnode_t *n, Agedge_t *e);

/*** Iterate over out-edges of a node */
extern Agedge_t *firstout(Agnode_t *n);
extern Agedge_t *nextout(Agnode_t *n, Agedge_t *e);

/*** Iterate over head nodes reachable from out-edges of a node */
extern Agnode_t *firsthead(Agnode_t *n);
extern Agnode_t *nexthead(Agnode_t *n, Agnode_t *h);

/*** Iterate over in-edges of a graph */
extern Agedge_t *firstin(Agraph_t *g);
extern Agedge_t *nextin(Agnode_t *n, Agedge_t *e);

/*** Iterate over in-edges of a node */
extern Agedge_t *firstin(Agnode_t *n);
extern Agedge_t *nextin(Agraph_t *g, Agedge_t *e);

/*** Iterate over tail nodes reachable from in-edges of a node */
extern Agnode_t *firsttail(Agnode_t *n);
extern Agnode_t *nexttail(Agnode_t *n, Agnode_t *t);

/*** Iterate over nodes of a graph */
extern Agnode_t *firstnode(Agraph_t *g);
extern Agnode_t *nextnode(Agraph_t *g, Agnode_t *n);

/*** Iterate over nodes of an edge */
extern Agnode_t *firstnode(Agedge_t *e);
extern Agnode_t *nextnode(Agedge_t *e, Agnode_t *n);

/*** Iterate over attributes of a graph */
extern Agsym_t *firstattr(Agraph_t *g);
extern Agsym_t *nextattr(Agraph_t *g, Agsym_t *a);

/*** Iterate over attributes of an edge */
extern Agsym_t *firstattr(Agedge_t *e);
extern Agsym_t *nextattr(Agedge_t *e, Agsym_t *a);

/*** Iterate over attributes of a node */
extern Agsym_t *firstattr(Agnode_t *n);
extern Agsym_t *nextattr(Agnode_t *n, Agsym_t *a);

/** Remove graph objects */
extern bool rm(Agraph_t *g);
extern bool rm(Agnode_t *n);
extern bool rm(Agedge_t *e);

/** Layout */
/*** Annotate a graph with layout attributes and values using a specific layout engine */
extern bool layout(Agraph_t *g, const char *engine);

/** Render */
/*** Render a layout into attributes of the graph */
extern bool render(Agraph_t *g); 
/*** Render a layout to stdout */
extern bool render(Agraph_t *g, const char *format);
/*** Render to an open file */
extern bool render(Agraph_t *g, const char *format, FILE *fout);
/*** Render a layout to an unopened file by name */
extern bool render(Agraph_t *g, const char *format, const char *filename);
/*** Render to a string result */
#ifdef SWIGJAVA
extern char* renderresult(Agraph_t *ing, const char *format);
#else
extern void renderresult(Agraph_t *g, const char *format, char *outdata);
/*** Render to an open channel */
extern bool renderchannel(Agraph_t *g, const char *format, const char *channelname);
/*** Render a layout to a malloc'ed string, to be free'd by the caller */
/*** (deprecated - too easy to leak memory) */
/*** (still needed for "eval [gv::renderdata $G tk]" ) */
#endif
extern char* renderdata(Agraph_t *g, const char *format);

/*** Writing graph back to file */
extern bool write(Agraph_t *g, const char *filename);
extern bool write(Agraph_t *g, FILE *f);

/*** Graph transformation tools */
extern bool tred(Agraph_t *g);

%}

