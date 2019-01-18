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

#include <string.h>
#include <stdlib.h>
#include "gvc.h"

extern "C" {
extern void gv_string_writer_init(GVC_t *gvc);
extern void gv_channel_writer_init(GVC_t *gvc);
extern void gv_writer_reset(GVC_t *gvc);
}

#define agfindattr(x,s) agattrsym(x,s)
#define agraphattr(g,n,s) agattr(g,AGRAPH,n,s)
#define agnodeattr(g,n,s) agattr(g,AGNODE,n,s)
#define agedgeattr(g,n,s) agattr(g,AGEDGE,n,s)

static char emptystring[] = {'\0'};

static GVC_t *gvc;

static void gv_init(void) {
    /* list of builtins, enable demand loading */
    gvc = gvContextPlugins(lt_preloaded_symbols, DEMAND_LOADING);
}

Agraph_t *graph(char *name)
{
    if (!gvc)
        gv_init();
    return agopen(name, Agundirected, 0);
}

Agraph_t *digraph(char *name)
{
    if (!gvc)
        gv_init();
    return agopen(name, Agdirected, 0);
}

Agraph_t *strictgraph(char *name)
{
    if (!gvc)
        gv_init();
    return agopen(name, Agstrictundirected, 0);
}

Agraph_t *strictdigraph(char *name)
{
    if (!gvc)
        gv_init();
    return agopen(name, Agstrictdirected, 0);
}

Agraph_t *readstring(char *string)
{
    if (!gvc)
        gv_init();
    return agmemread(string);
}

Agraph_t *read(FILE *f)
{
    if (!gvc)
        gv_init();
    return agread(f, NULL);
}

Agraph_t *read(const char *filename)
{
    FILE *f;
    Agraph_t *g;

    f = fopen(filename, "r");
    if (!f)
        return NULL;
    if (!gvc)
        gv_init();
    g = agread(f, NULL);
    fclose(f);
    return g;
}

//-------------------------------------------------
Agraph_t *graph(Agraph_t *g, char *name)
{
    if (!gvc)
        gv_init();
    return agsubg(g, name, 1);
}

Agnode_t *node(Agraph_t *g, char *name)
{
    if (!gvc)
        return NULL;
    return agnode(g, name, 1);
}

Agedge_t *edge(Agraph_t* g, Agnode_t *t, Agnode_t *h)
{
    if (!gvc || !t || !h || !g)
        return NULL;
    // edges from/to the protonode are not permitted
    if (AGTYPE(t) == AGRAPH || AGTYPE(h) == AGRAPH)
	return NULL;
    return agedge(g, t, h, NULL, 1);
}

Agedge_t *edge(Agnode_t *t, Agnode_t *h)
{
    return edge(agraphof(t), t, h);
}

// induce tail if necessary
Agedge_t *edge(char *tname, Agnode_t *h)
{
    return edge(node(agraphof(h), tname), h);
}

// induce head if necessary
Agedge_t *edge(Agnode_t *t, char *hname)
{
    return edge(t, node(agraphof(t), hname));
}

// induce tail/head if necessary
Agedge_t *edge(Agraph_t *g, char *tname, char *hname)
{
    return edge(g, node(g, tname), node(g, hname));
}

//-------------------------------------------------
static char* myagxget(void *obj, Agsym_t *a)
{
    int len;
    char *val, *hs;

    if (!obj || !a)
        return emptystring;
    val = agxget(obj, a);
    if (!val)
        return emptystring;
    if (a->name[0] == 'l' && strcmp(a->name, "label") == 0 && aghtmlstr(val)) {
        len = strlen(val);
        hs = (char*)malloc(len + 3);
        hs[0] = '<';
        strcpy(hs+1, val);
        hs[len+1] = '>';
        hs[len+2] = '\0';
        return hs;
    }
    return val;
}
char *getv(Agraph_t *g, Agsym_t *a)
{
    return myagxget(g, a);
}
char *getv(Agraph_t *g, char *attr)
{
    Agsym_t *a;

    if (!g || !attr)
        return NULL;
    a = agfindattr(agroot(g), attr);
    return myagxget(g, a);
}
static void myagxset(void *obj, Agsym_t *a, char *val)
{
    int len;
    char *hs;

    if (a->name[0] == 'l' && val[0] == '<' && strcmp(a->name, "label") == 0) {
        len = strlen(val);
        if (val[len-1] == '>') {
            hs = strdup(val+1);
                *(hs+len-2) = '\0';
            val = agstrdup_html(agraphof(obj),hs);
            free(hs);
        }
    }
    agxset(obj, a, val);
}
char *setv(Agraph_t *g, Agsym_t *a, char *val)
{
    if (!g || !a || !val)
        return NULL;
    myagxset(g, a, val);
    return val;
}
char *setv(Agraph_t *g, char *attr, char *val)
{
    Agsym_t *a;

    if (!g || !attr || !val)
        return NULL;
    a = agfindattr(agroot(g), attr);
    if (!a)
        a = agraphattr(g->root, attr, emptystring);
    myagxset(g, a, val);
    return val;
}
//-------------------------------------------------
char *getv(Agnode_t *n, Agsym_t *a)
{
    if (!n || !a)
        return NULL;
    if (AGTYPE(n) == AGRAPH) // protonode   
	return NULL;   // FIXME ??
    return myagxget(n, a);
}
char *getv(Agnode_t *n, char *attr)
{
    Agraph_t *g;
    Agsym_t *a;

    if (!n || !attr)
        return NULL;
    if (AGTYPE(n) == AGRAPH) // protonode   
	return NULL;   // FIXME ??
    g = agroot(agraphof(n));
    a = agattr(g, AGNODE, attr, NULL);
    return myagxget(n, a);
}
char *setv(Agnode_t *n, Agsym_t *a, char *val)
{
    if (!n || !a || !val)
        return NULL;
    if (AGTYPE(n) == AGRAPH) // protonode   
	return NULL;   // FIXME ??
    myagxset(n, a, val);
    return val;
}
char *setv(Agnode_t *n, char *attr, char *val)
{
    Agraph_t *g;
    Agsym_t *a;

    if (!n || !attr || !val)
        return NULL;
    if (AGTYPE(n) == AGRAPH) { // protonode   
	g = (Agraph_t*)n;
    	a = agattr(g, AGNODE, attr, val); // create default attribute in psuodo protonode
	    // FIXME? - deal with html in "label" attributes
	return val;
    }
    g = agroot(agraphof(n));
    a = agattr(g, AGNODE, attr, NULL);
    if (!a)
        a = agnodeattr(g, attr, emptystring);
    myagxset(n, a, val);
    return val;
}
//-------------------------------------------------
char *getv(Agedge_t *e, Agsym_t *a)
{
    if (!e || !a)
        return NULL;
    if (AGTYPE(e) == AGRAPH) // protoedge   
	return NULL;   // FIXME ??
    return myagxget(e, a);
}
char *getv(Agedge_t *e, char *attr)
{
    Agraph_t *g;
    Agsym_t *a;

    if (!e || !attr)
        return NULL;
    if (AGTYPE(e) == AGRAPH) // protoedge   
	return NULL;   // FIXME ??
    g = agraphof(agtail(e));
    a = agattr(g, AGEDGE, attr, NULL);
    return myagxget(e, a);
}
char *setv(Agedge_t *e, Agsym_t *a, char *val)
{
    if (!e || !a || !val)
        return NULL;
    if (AGTYPE(e) == AGRAPH) // protoedge   
	return NULL;   // FIXME ??
    myagxset(e, a, val);
    return val;
}
char *setv(Agedge_t *e, char *attr, char *val)
{
    Agraph_t *g;
    Agsym_t *a;

    if (!e || !attr || !val)
        return NULL;
    if (AGTYPE(e) == AGRAPH) { // protoedge   
	g = (Agraph_t*)e;
    	a = agattr(g, AGEDGE, attr, val); // create default attribute in pseudo protoedge
	    // FIXME? - deal with html in "label" attributes
	return val;
    }
    g = agroot(agraphof(agtail(e)));
    a = agattr(g, AGEDGE, attr, NULL);
    if (!a)
        a = agattr(g, AGEDGE, attr, emptystring);
    myagxset(e, a, val);
    return val;
}
//-------------------------------------------------
Agraph_t *findsubg(Agraph_t *g, char *name)
{
    if (!g || !name)
        return NULL;
    return agsubg(g, name, 0);
}

Agnode_t *findnode(Agraph_t *g, char *name)
{
    if (!g || !name)
        return NULL;
    return agnode(g, name, 0);
}

Agedge_t *findedge(Agnode_t *t, Agnode_t *h)
{
    if (!t || !h)
        return NULL;
    if (AGTYPE(t) == AGRAPH || AGTYPE(h) == AGRAPH)
	return NULL;
    return agfindedge(agraphof(t), t, h);
}

Agsym_t *findattr(Agraph_t *g, char *name)
{
    if (!g || !name)
        return NULL;
    return agfindattr(g, name);
}

Agsym_t *findattr(Agnode_t *n, char *name)
{
    if (!n || !name)
        return NULL;
    return agfindattr(n, name);
}

Agsym_t *findattr(Agedge_t *e, char *name)
{
    if (!e || !name)
        return NULL;
    return agfindattr(e, name);
}

//-------------------------------------------------

Agnode_t *headof(Agedge_t *e)
{
    if (!e)
        return NULL;
    if (AGTYPE(e) == AGRAPH)
	return NULL;
    return aghead(e);
}

Agnode_t *tailof(Agedge_t *e)
{
    if (!e)
        return NULL;
    if (AGTYPE(e) == AGRAPH)
	return NULL;
    return agtail(e);
}

Agraph_t *graphof(Agraph_t *g)
{
    if (!g || g == g->root)
        return NULL;
    return agroot(g);
}

Agraph_t *graphof(Agedge_t *e)
{
    if (!e)
        return NULL;
    if (AGTYPE(e) == AGRAPH)
	return (Agraph_t*)e; /* graph of protoedge is itself recast */
    return agraphof(agtail(e));
}

Agraph_t *graphof(Agnode_t *n)
{
    if (!n)
        return NULL;
    if (AGTYPE(n) == AGRAPH)
	return (Agraph_t*)n;  /* graph of protonode is itself recast */
    return agraphof(n);
}

Agraph_t *rootof(Agraph_t *g)
{
    if (!g)
        return NULL;
    return agroot(g);
}

//-------------------------------------------------
Agnode_t *protonode(Agraph_t *g)
{
    if (!g)
        return NULL;
    return (Agnode_t *)g;    // gross abuse of the type system!
}

Agedge_t *protoedge(Agraph_t *g)
{
    if (!g)
        return NULL;
    return (Agedge_t *)g;    // gross abuse of the type system!
}

//-------------------------------------------------
char *nameof(Agraph_t *g)
{
    if (!g)
        return NULL;
    return agnameof(g);
}
char *nameof(Agnode_t *n)
{
    if (!n)
        return NULL;
    if (AGTYPE(n) == AGRAPH)
	return NULL;
    return agnameof(n);
}
//char *nameof(Agedge_t *e)
//{
//    if (!e)
//        return NULL;
//    if (AGTYPE(e) == AGRAPH)
//	return NULL;
//    return agnameof(e);
//}
char *nameof(Agsym_t *a)
{
    if (!a)
        return NULL;
    return a->name;
}

//-------------------------------------------------
bool ok(Agraph_t *g)
{
    if (!g) 
        return false;
    return true;
}
bool ok(Agnode_t *n)
{
    if (!n) 
        return false;
    return true;
}
bool ok(Agedge_t *e)
{
    if (!e) 
        return false;
    return true;
}
bool ok(Agsym_t *a)
{
    if (!a) 
        return false;
    return true;
}
//-------------------------------------------------
Agraph_t *firstsubg(Agraph_t *g)
{
    if (!g)
        return NULL;
    return agfstsubg(g);
}

Agraph_t *nextsubg(Agraph_t *g, Agraph_t *sg)
{

    if (!g || !sg)
        return NULL;
    return agnxtsubg(sg);
}

Agraph_t *firstsupg(Agraph_t *g)
{
    return g->parent;
}

Agraph_t *nextsupg(Agraph_t *g, Agraph_t *sg)
{
    return NULL;
}

Agedge_t *firstout(Agraph_t *g)
{
    Agnode_t *n;
    Agedge_t *e;

    if (!g)
        return NULL;
    for (n = agfstnode(g); n; n = agnxtnode(g, n)) {
	e = agfstout(g, n);
	if (e) return e;
    }
    return NULL;
}

Agedge_t *nextout(Agraph_t *g, Agedge_t *e)
{
    Agnode_t *n;
    Agedge_t *ne;

    if (!g || !e)
        return NULL;
    ne = agnxtout(g, e);
    if (ne)
        return (ne);
    for (n = agnxtnode(g, agtail(e)); n; n = agnxtnode(g, n)) {
	ne = agfstout(g, n);
	if (ne) return ne;
    }
    return NULL;
}

Agedge_t *firstedge(Agraph_t *g)
{
    return firstout(g);
} 

Agedge_t *nextedge(Agraph_t *g, Agedge_t *e)
{
    return nextout(g, e);
} 

Agedge_t *firstout(Agnode_t *n)
{
    if (!n)
        return NULL;
    return agfstout(agraphof(n), n);
}

Agedge_t *nextout(Agnode_t *n, Agedge_t *e)
{
    if (!n || !e)
        return NULL;
    return agnxtout(agraphof(n), e);
}

Agnode_t *firsthead(Agnode_t *n)
{
    Agedge_t *e;

    if (!n)
        return NULL;
    e = agfstout(agraphof(n), n);
    if (!e)
        return NULL;
    return aghead(e);
}

Agnode_t *nexthead(Agnode_t *n, Agnode_t *h)
{
    Agedge_t *e;
    Agraph_t *g;

    if (!n || !h)
        return NULL;
    g = agraphof(n);
    e = agfindedge(g, n, h);
    if (!e)
        return NULL;
    do {
        e = agnxtout(g, AGMKOUT(e));
        if (!e)
            return NULL;
    } while (aghead(e) == h);
    return aghead(e);
}

Agedge_t *firstedge(Agnode_t *n)
{
    if (!n)
        return NULL;
    return agfstedge(agraphof(n), n);
} 

Agedge_t *nextedge(Agnode_t *n, Agedge_t *e)
{
    if (!n || !e)
        return NULL;
    return agnxtedge(agraphof(n), e, n); 
} 

Agedge_t *firstin(Agraph_t *g)
{
    Agnode_t *n;

    if (!g)
        return NULL;
    n = agfstnode(g);
    if (!n)
        return NULL;
    return agfstin(g, n);
}

Agedge_t *nextin(Agraph_t *g, Agedge_t *e)
{
    Agnode_t *n;
    Agedge_t *ne;

    if (!g || !e)
        return NULL;
    ne = agnxtin(g, e);
    if (ne)
        return (ne);
    n = agnxtnode(g, aghead(e));
    if (!n)
        return NULL;
    return agfstin(g, n);
}

Agedge_t *firstin(Agnode_t *n)
{
    if (!n)
        return NULL;
    return agfstin(agraphof(n), n);
}

Agedge_t *nextin(Agnode_t *n, Agedge_t *e)
{
    if (!n || !e)
        return NULL;
    return agnxtin(agraphof(n), e);
}

Agnode_t *firsttail(Agnode_t *n)
{
    Agedge_t *e;

    if (!n)
        return NULL;
    e = agfstin(agraphof(n), n);
    if (!e)
        return NULL;
    return agtail(e);
}

Agnode_t *nexttail(Agnode_t *n, Agnode_t *t)
{
    Agedge_t *e;
    Agraph_t *g;

    if (!n || !t)
        return NULL;
    g = agraphof(n);
    e = agfindedge(g, t, n);
    if (!e)
        return NULL;
    do {
        e = agnxtin(g, AGMKIN(e));
        if (!e)
            return NULL;
    } while (agtail(e) == t);
    return agtail(e);
}

Agnode_t *firstnode(Agraph_t *g)
{
    if (!g)
        return NULL;
    return agfstnode(g);
}

Agnode_t *nextnode(Agraph_t *g, Agnode_t *n)
{
    if (!g || !n)
        return NULL;
    return agnxtnode(g, n);
}

Agnode_t *firstnode(Agedge_t *e)
{
    if (!e)
        return NULL;
    return agtail(e);
}

Agnode_t *nextnode(Agedge_t *e, Agnode_t *n)
{
    if (!e || n != agtail(e))
        return NULL;
    return aghead(e);
}

Agsym_t *firstattr(Agraph_t *g)
{
    if (!g)
        return NULL;
    g = agroot(g);
    return agnxtattr(g,AGRAPH,NULL);
}

Agsym_t *nextattr(Agraph_t *g, Agsym_t *a)
{
    if (!g || !a)
        return NULL;
    g = agroot(g);
    return agnxtattr(g,AGRAPH,a);
}

Agsym_t *firstattr(Agnode_t *n)
{
    Agraph_t *g;

    if (!n)
        return NULL;
    g = agraphof(n);
    return agnxtattr(g,AGNODE,NULL);
}

Agsym_t *nextattr(Agnode_t *n, Agsym_t *a)
{
    Agraph_t *g;

    if (!n || !a)
        return NULL;
    g = agraphof(n);
    return agnxtattr(g,AGNODE,a);
}

Agsym_t *firstattr(Agedge_t *e)
{
    Agraph_t *g;

    if (!e)
        return NULL;
    g = agraphof(agtail(e));
    return agnxtattr(g,AGEDGE,NULL);
}

Agsym_t *nextattr(Agedge_t *e, Agsym_t *a)
{
    Agraph_t *g;

    if (!e || !a)
        return NULL;
    g = agraphof(agtail(e));
    return agnxtattr(g,AGEDGE,a);
}

bool rm(Agraph_t *g)
{
    if (!g)
        return false;
#if 0
    Agraph_t* sg;
    for (sg = agfstsubg (g); sg; sg = agnxtsubg (sg))
	rm(sg);
    if (g == agroot(g))
	agclose(g);
    else
        agdelete(agparent(g), g);
#endif
    /* The rm function appears to have the semantics of agclose, so
     * we should just do that, and let cgraph take care of all the
     * details.
     */
    agclose(g);
    return true;
}

bool rm(Agnode_t *n)
{
    if (!n)
        return false;
    // removal of the protonode is not permitted
    if (agnameof(n)[0] == '\001' && strcmp (agnameof(n), "\001proto") ==0)
        return false;
    agdelete(agraphof(n), n);
    return true;
}

bool rm(Agedge_t *e)
{
    if (!e)
        return false;
    // removal of the protoedge is not permitted
    if ((agnameof(aghead(e))[0] == '\001' && strcmp (agnameof(aghead(e)), "\001proto") == 0)
     || (agnameof(agtail(e))[0] == '\001' && strcmp (agnameof(agtail(e)), "\001proto") == 0))
        return false;
    agdelete(agroot(agraphof(aghead(e))), e);
    return true;
}

bool layout(Agraph_t *g, const char *engine)
{
    int err;

    if (!g)
        return false;
    err = gvFreeLayout(gvc, g);  /* ignore errors */
    err = gvLayout(gvc, g, engine);
    return (! err);
}

// annotate the graph with layout information
bool render(Agraph_t *g)
{
    if (!g)
        return false;
    attach_attrs(g);
    return true;
}

// render to stdout
bool render(Agraph_t *g, const char *format)
{
    int err;

    if (!g)
        return false;
    err = gvRender(gvc, g, format, stdout);
    return (! err);
}

// render to an open FILE
bool render(Agraph_t *g, const char *format, FILE *f)
{
    int err;

    if (!g)
        return false;
    err = gvRender(gvc, g, format, f);
    return (! err);
}

// render to an open channel  
bool renderchannel(Agraph_t *g, const char *format, const char *channelname)
{
    int err;

    if (!g)
        return false;
    gv_channel_writer_init(gvc);
    err = gvRender(gvc, g, format, (FILE*)channelname);
    gv_writer_reset (gvc);   /* Reset to default */
    return (! err);
}

// render to a filename 
bool render(Agraph_t *g, const char *format, const char *filename)
{
    int err;

    if (!g)
        return false;
    err = gvRenderFilename(gvc, g, format, filename);
    return (! err);
}

typedef struct {
    char* data;
    int sz;       /* buffer size */
    int len;      /* length of array */
} BA;

// render to string result, using binding-dependent gv_string_writer()
char* renderresult(Agraph_t *g, const char *format)
{
    BA ba;

    if (!g)
        return NULL;
    if (!GD_alg(g))
        return NULL;
    ba.sz = BUFSIZ;
    ba.data = (char*)malloc(ba.sz*sizeof(char));  /* must be freed by wrapper code */
    ba.len = 0;
    gv_string_writer_init(gvc);
    (void)gvRender(gvc, g, format, (FILE*)&ba);
    gv_writer_reset (gvc);   /* Reset to default */
    *((int*)GD_alg(g)) = ba.len;
    return ba.data;
}

// render to string result, using binding-dependent gv_string_writer()
void renderresult(Agraph_t *g, const char *format, char *outdata)
{
    if (!g)
        return;
    gv_string_writer_init(gvc);
    (void)gvRender(gvc, g, format, (FILE*)outdata);
    gv_writer_reset (gvc);   /* Reset to default */
}

// render to a malloc'ed data string, to be free'd by caller.
char* renderdata(Agraph_t *g, const char *format)
{
    int err;
    char *data;
    unsigned int length;

    if (!g)
	return NULL;
    err = gvRenderData(gvc, g, format, &data, &length);
    if (err)
	return NULL;
    data = (char*)realloc(data, length + 1);
    return data;
}

bool write(Agraph_t *g, FILE *f)
{
    int err;

    if (!g)
        return false;
    err = agwrite(g, f);
    return (! err);
}

bool write(Agraph_t *g, const char *filename)
{
    FILE *f;
    int err;

    if (!g)
        return false;
    f = fopen(filename, "w");
    if (!f)
        return false;
    err = agwrite(g, f);
    fclose(f);
    return (! err);
}

bool tred(Agraph_t *g)
{
    int err;

    if (!g)
        return false;
    err = gvToolTred(g);
    return (! err);
}

