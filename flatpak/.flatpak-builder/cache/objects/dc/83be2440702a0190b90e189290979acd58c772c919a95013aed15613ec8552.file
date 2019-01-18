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

#ifndef GV_TYPES_H
#define GV_TYPES_H

/* Define if you want CGRAPH */
#define WITH_CGRAPH 1

#include <stdio.h>
#include <assert.h>
#include <signal.h>

typedef unsigned char boolean;
#ifndef NOT
#define NOT(v) (!(v))
#endif
#ifndef FALSE
#define FALSE 0
#endif
#ifndef TRUE
#define TRUE NOT(FALSE)
#endif

#include "geom.h"
#include "gvcext.h"
#include "pathgeom.h"
#include "textspan.h"
#include "cgraph.h"

#ifdef __cplusplus
extern "C" {
#endif

    typedef int (*qsort_cmpf) (const void *, const void *);
    typedef int (*bsearch_cmpf) (const void *, const void *);
    typedef struct Agraph_s graph_t;
    typedef struct Agnode_s node_t;
    typedef struct Agedge_s edge_t;
    typedef struct Agsym_s attrsym_t;
#define TAIL_ID "tailport"
#define HEAD_ID "headport"

    typedef struct htmllabel_t htmllabel_t;

    typedef union inside_t {
	struct {
	    pointf* p;
	    double* r;
	} a;
	struct {
	    node_t* n;
	    boxf*    bp;
	} s;
    } inside_t;

    typedef struct port {	/* internal edge endpoint specification */
	pointf p;		/* aiming point relative to node center */
	double theta;		/* slope in radians */
	boxf *bp;		/* if not null, points to bbox of 
				 * rectangular area that is port target
				 */
	boolean	defined;        /* if true, edge has port info at this end */
	boolean	constrained;    /* if true, constraints such as theta are set */
	boolean clip;           /* if true, clip end to node/port shape */
	boolean dyna;           /* if true, assign compass point dynamically */
	unsigned char order;	/* for mincross */
	unsigned char side;	/* if port is on perimeter of node, this
                                 * contains the bitwise OR of the sides (TOP,
                                 * BOTTOM, etc.) it is on. 
                                 */
	char *name;		/* port name, if it was explicitly given, otherwise NULL */
    } port;

    typedef struct {
	boolean(*swapEnds) (edge_t * e);	/* Should head and tail be swapped? */
	boolean(*splineMerge) (node_t * n);	/* Is n a node in the middle of an edge? */
	boolean ignoreSwap;                     /* Test for swapped edges if false */
	boolean isOrtho;                        /* Orthogonal routing used */
    } splineInfo;

    typedef struct pathend_t {
	boxf nb;			/* the node box */
	pointf np;		/* node port */
	int sidemask;
	int boxn;
	boxf boxes[20];
    } pathend_t;

    typedef struct path {	/* internal specification for an edge spline */
	port start, end;
	int nbox;		/* number of subdivisions */
	boxf *boxes;		/* rectangular regions of subdivision */
	void *data;
    } path;

    typedef struct bezier {
	pointf *list;
	int size;
	int sflag, eflag;
	pointf sp, ep;
    } bezier;

    typedef struct splines {
	bezier *list;
	int size;
	boxf bb;
    } splines;

    typedef struct textlabel_t {
	char *text, *fontname, *fontcolor;
	int charset;
	double fontsize;
	pointf dimen; /* the diagonal size of the label (estimated by layout) */
	pointf space; /* the diagonal size of the space for the label */
		      /*   the rendered label is aligned in this box */
		      /*   space does not include pad or margin */
	pointf pos;   /* the center of the space for the label */
	union {
	    struct {
		textspan_t *span;
		short nspans;
	    } txt;
	    htmllabel_t *html;
	} u;
	char valign;  /* 't' 'c' 'b' */
	boolean set;  /* true if position is set */
	boolean html; /* true if html label */
    } textlabel_t;

    typedef struct polygon_t {	/* mutable shape information for a node */
	int regular;		/* true for symmetric shapes */
	int peripheries;	/* number of periphery lines */
	int sides;		/* number of sides */
	double orientation;	/* orientation of shape (+ve degrees) */
	double distortion;	/* distortion factor - as in trapezium */
	double skew;		/* skew factor - as in parallelogram */
	int option;		/* ROUNDED, DIAGONAL corners, etc. */
	pointf *vertices;	/* array of vertex points */
    } polygon_t;

    typedef struct stroke_t {	/* information about a single stroke */
	/* we would have called it a path if that term wasn't already used */
	int nvertices;		/* number of points in the stroke */
	int flags;		/* stroke style flags */
	pointf *vertices;	/* array of vertex points */
    } stroke_t;

/* flag definitions for stroke_t */
#define STROKE_CLOSED (1 << 0)
#define STROKE_FILLED (1 << 1)
#define STROKE_PENDOWN (1 << 2)
#define STROKE_VERTICES_ALLOCATED (1 << 3)

    typedef struct shape_t {	/* mutable shape information for a node */
	int nstrokes;		/* number of strokes in array */
	stroke_t *strokes;	/* array of strokes */
	/* The last stroke must always be closed, but can be pen_up.
	 * It is used as the clipping path */
    } shape_t;

    typedef struct shape_functions {	/* read-only shape functions */
	void (*initfn) (node_t *);	/* initializes shape from node u.shape_info structure */
	void (*freefn) (node_t *);	/* frees  shape from node u.shape_info structure */
	 port(*portfn) (node_t *, char *, char *);	/* finds aiming point and slope of port */
	 boolean(*insidefn) (inside_t * inside_context, pointf);	/* clips incident gvc->e spline on shape of gvc->n */
	int (*pboxfn)(node_t* n, port* p, int side, boxf rv[], int *kptr); /* finds box path to reach port */
	void (*codefn) (GVJ_t * job, node_t * n);	/* emits graphics code for node */
    } shape_functions;

    typedef enum { SH_UNSET, SH_POLY, SH_RECORD, SH_POINT, SH_EPSF} shape_kind;

    typedef struct shape_desc {	/* read-only shape descriptor */
	char *name;		/* as read from graph file */
	shape_functions *fns;
	polygon_t *polygon;	/* base polygon info */
	boolean usershape;
    } shape_desc;

#include "usershape.h"		/* usershapes needed by gvc */

    typedef struct nodequeue {
	node_t **store, **limit, **head, **tail;
    } nodequeue;

    typedef struct adjmatrix_t {
	int nrows, ncols;
	char *data;
    } adjmatrix_t;

    typedef struct rank_t {
	int n;			/* number of nodes in this rank  */
	node_t **v;		/* ordered list of nodes in rank    */
	int an;			/* globally allocated number of nodes   */
	node_t **av;		/* allocated list of nodes in rank  */
	double ht1, ht2;	/* height below/above centerline    */
	double pht1, pht2;	/* as above, but only primitive nodes   */
	boolean candidate;	/* for transpose () */
	boolean valid;
	int cache_nc;		/* caches number of crossings */
	adjmatrix_t *flat;
    } rank_t;

    typedef enum { R_NONE =
	    0, R_VALUE, R_FILL, R_COMPRESS, R_AUTO, R_EXPAND } ratio_t;

    typedef struct layout_t {
	double quantum;
	double scale;
	double ratio;		/* set only if ratio_kind == R_VALUE */
	double dpi;
	pointf margin;
	pointf page;
	pointf size;
	boolean filled;
	boolean landscape;
	boolean centered;
	ratio_t ratio_kind;
	void* xdots;
	char* id;
    } layout_t;

/* for "record" shapes */
    typedef struct field_t {
	pointf size;		/* its dimension */
	boxf b;			/* its placement in node's coordinates */
	int n_flds;
	textlabel_t *lp;	/* n_flds == 0 */
	struct field_t **fld;	/* n_flds > 0 */
	char *id;		/* user's identifier */
	unsigned char LR;	/* if box list is horizontal (left to right) */
	unsigned char sides;    /* sides of node exposed to field */
    } field_t;

    typedef struct nlist_t {
	node_t **list;
	int size;
    } nlist_t;

    typedef struct elist {
	edge_t **list;
	int size;
    } elist;

#define GUI_STATE_ACTIVE    (1<<0)
#define GUI_STATE_SELECTED  (1<<1)
#define GUI_STATE_VISITED   (1<<2)
#define GUI_STATE_DELETED   (1<<3)

#define elist_fastapp(item,L) do {L.list[L.size++] = item; L.list[L.size] = NULL;} while(0)
#define elist_append(item,L)  do {L.list = ALLOC(L.size + 2,L.list,edge_t*); L.list[L.size++] = item; L.list[L.size] = NULL;} while(0)
#define alloc_elist(n,L)      do {L.size = 0; L.list = N_NEW(n + 1,edge_t*); } while (0)
#define free_list(L)          do {if (L.list) free(L.list);} while (0)

typedef enum {NATIVEFONTS,PSFONTS,SVGFONTS} fontname_kind;

    typedef struct Agraphinfo_t {
	Agrec_t hdr;
	/* to generate code */
	layout_t *drawing;
	textlabel_t *label;	/* if the cluster has a title */
	boxf bb;			/* bounding box */
	pointf border[4];	/* sizes of margins for graph labels */
	unsigned char gui_state; /* Graph state for GUI ops */
	unsigned char has_labels;
	boolean has_images;
	unsigned char charset; /* input character set */
	int rankdir;
	double ht1, ht2;	/* below and above extremal ranks */
	unsigned short flags;
	void *alg;
	GVC_t *gvc;	/* context for "globals" over multiple graphs */
	void (*cleanup) (graph_t * g);   /* function to deallocate layout-specific data */

#ifndef DOT_ONLY
	/* to place nodes */
	node_t **neato_nlist;
	int move;
	double **dist, **spring, **sum_t, ***t;
	unsigned short ndim;
	unsigned short odim;
#endif
#ifndef NEATO_ONLY
	/* to have subgraphs */
	int n_cluster;
	graph_t **clust;	/* clusters are in clust[1..n_cluster] !!! */
	graph_t *dotroot;
	node_t *nlist;
	rank_t *rank;
	graph_t *parent;        /* containing cluster (not parent subgraph) */
	int level;		/* cluster nesting level (not node level!) */
	node_t	*minrep, *maxrep;	/* set leaders for min and max rank */

	/* fast graph node list */
	nlist_t comp;
	/* connected components */
	node_t *minset, *maxset;	/* set leaders */
	long n_nodes;
	/* includes virtual */
	short minrank, maxrank;

	/* various flags */
	boolean has_flat_edges;
	boolean has_sourcerank;
	boolean has_sinkrank;
	unsigned char	showboxes;
	fontname_kind fontnames;		/* to override mangling in SVG */

	int nodesep, ranksep;
	node_t *ln, *rn;	/* left, right nodes of bounding box */

	/* for clusters */
	node_t *leader, **rankleader;
	boolean expanded;
	char installed;
	char set_type;
	char label_pos;
	boolean exact_ranksep;
#endif

    } Agraphinfo_t;

#define GD_parent(g) (((Agraphinfo_t*)AGDATA(g))->parent)
#define GD_level(g) (((Agraphinfo_t*)AGDATA(g))->level)
#define GD_drawing(g) (((Agraphinfo_t*)AGDATA(g))->drawing)
#define GD_bb(g) (((Agraphinfo_t*)AGDATA(g))->bb)
#define GD_gvc(g) (((Agraphinfo_t*)AGDATA(g))->gvc)
#define GD_cleanup(g) (((Agraphinfo_t*)AGDATA(g))->cleanup)
#define GD_dist(g) (((Agraphinfo_t*)AGDATA(g))->dist)
#define GD_alg(g) (((Agraphinfo_t*)AGDATA(g))->alg)
#define GD_border(g) (((Agraphinfo_t*)AGDATA(g))->border)
#define GD_cl_cnt(g) (((Agraphinfo_t*)AGDATA(g))->cl_nt)
#define GD_clust(g) (((Agraphinfo_t*)AGDATA(g))->clust)
#define GD_dotroot(g) (((Agraphinfo_t*)AGDATA(g))->dotroot)
#define GD_comp(g) (((Agraphinfo_t*)AGDATA(g))->comp)
#define GD_exact_ranksep(g) (((Agraphinfo_t*)AGDATA(g))->exact_ranksep)
#define GD_expanded(g) (((Agraphinfo_t*)AGDATA(g))->expanded)
#define GD_flags(g) (((Agraphinfo_t*)AGDATA(g))->flags)
#define GD_gui_state(g) (((Agraphinfo_t*)AGDATA(g))->gui_state)
#define GD_charset(g) (((Agraphinfo_t*)AGDATA(g))->charset)
#define GD_has_labels(g) (((Agraphinfo_t*)AGDATA(g))->has_labels)
#define GD_has_images(g) (((Agraphinfo_t*)AGDATA(g))->has_images)
#define GD_has_flat_edges(g) (((Agraphinfo_t*)AGDATA(g))->has_flat_edges)
#define GD_has_sourcerank(g)	(((Agraphinfo_t*)AGDATA(g))->has_sourcerank)
#define GD_has_sinkrank(g)	(((Agraphinfo_t*)AGDATA(g))->has_sinkrank)
#define GD_ht1(g) (((Agraphinfo_t*)AGDATA(g))->ht1)
#define GD_ht2(g) (((Agraphinfo_t*)AGDATA(g))->ht2)
#define GD_inleaf(g) (((Agraphinfo_t*)AGDATA(g))->inleaf)
#define GD_installed(g) (((Agraphinfo_t*)AGDATA(g))->installed)
#define GD_label(g) (((Agraphinfo_t*)AGDATA(g))->label)
#define GD_leader(g) (((Agraphinfo_t*)AGDATA(g))->leader)
#define GD_rankdir2(g) (((Agraphinfo_t*)AGDATA(g))->rankdir)
#define GD_rankdir(g) (((Agraphinfo_t*)AGDATA(g))->rankdir & 0x3)
#define GD_flip(g) (GD_rankdir(g) & 1)
#define GD_realrankdir(g) ((((Agraphinfo_t*)AGDATA(g))->rankdir) >> 2)
#define GD_realflip(g) (GD_realrankdir(g) & 1)
#define GD_ln(g) (((Agraphinfo_t*)AGDATA(g))->ln)
#define GD_maxrank(g) (((Agraphinfo_t*)AGDATA(g))->maxrank)
#define GD_maxset(g) (((Agraphinfo_t*)AGDATA(g))->maxset)
#define GD_minrank(g) (((Agraphinfo_t*)AGDATA(g))->minrank)
#define GD_minset(g) (((Agraphinfo_t*)AGDATA(g))->minset)
#define GD_minrep(g) (((Agraphinfo_t*)AGDATA(g))->minrep)
#define GD_maxrep(g) (((Agraphinfo_t*)AGDATA(g))->maxrep)
#define GD_move(g) (((Agraphinfo_t*)AGDATA(g))->move)
#define GD_n_cluster(g) (((Agraphinfo_t*)AGDATA(g))->n_cluster)
#define GD_n_nodes(g) (((Agraphinfo_t*)AGDATA(g))->n_nodes)
#define GD_ndim(g) (((Agraphinfo_t*)AGDATA(g))->ndim)
#define GD_odim(g) (((Agraphinfo_t*)AGDATA(g))->odim)
#define GD_neato_nlist(g) (((Agraphinfo_t*)AGDATA(g))->neato_nlist)
#define GD_nlist(g) (((Agraphinfo_t*)AGDATA(g))->nlist)
#define GD_nodesep(g) (((Agraphinfo_t*)AGDATA(g))->nodesep)
#define GD_outleaf(g) (((Agraphinfo_t*)AGDATA(g))->outleaf)
#define GD_rank(g) (((Agraphinfo_t*)AGDATA(g))->rank)
#define GD_rankleader(g) (((Agraphinfo_t*)AGDATA(g))->rankleader)
#define GD_ranksep(g) (((Agraphinfo_t*)AGDATA(g))->ranksep)
#define GD_rn(g) (((Agraphinfo_t*)AGDATA(g))->rn)
#define GD_set_type(g) (((Agraphinfo_t*)AGDATA(g))->set_type)
#define GD_label_pos(g) (((Agraphinfo_t*)AGDATA(g))->label_pos)
#define GD_showboxes(g) (((Agraphinfo_t*)AGDATA(g))->showboxes)
#define GD_fontnames(g) (((Agraphinfo_t*)AGDATA(g))->fontnames)
#define GD_spring(g) (((Agraphinfo_t*)AGDATA(g))->spring)
#define GD_sum_t(g) (((Agraphinfo_t*)AGDATA(g))->sum_t)
#define GD_t(g) (((Agraphinfo_t*)AGDATA(g))->t)

    typedef struct Agnodeinfo_t {
	Agrec_t hdr;
	shape_desc *shape;
	void *shape_info;
	pointf coord;
	double width, height;  /* inches */
	boxf bb;
	double ht, lw, rw;
	textlabel_t *label;
	textlabel_t *xlabel;
	void *alg;
	char state;
	unsigned char gui_state; /* Node state for GUI ops */
	boolean clustnode;

#ifndef DOT_ONLY
	unsigned char pinned;
	int id, heapindex, hops;
	double *pos, dist;
#endif
#ifndef NEATO_ONLY
	unsigned char showboxes;
	boolean  has_port;
	node_t* rep;
	node_t *set;

	/* fast graph */
	char node_type, mark, onstack;
	char ranktype, weight_class;
	node_t *next, *prev;
	elist in, out, flat_out, flat_in, other;
	graph_t *clust;

	/* for union-find and collapsing nodes */
	int UF_size;
	node_t *UF_parent;
	node_t *inleaf, *outleaf;

	/* for placing nodes */
	int rank, order;	/* initially, order = 1 for ordered edges */
	double mval;
	elist save_in, save_out;

	/* for network-simplex */
	elist tree_in, tree_out;
	edge_t *par;
	int low, lim;
	int priority;

	double pad[1];
#endif

    } Agnodeinfo_t;

#define ND_id(n) (((Agnodeinfo_t*)AGDATA(n))->id)
#define ND_alg(n) (((Agnodeinfo_t*)AGDATA(n))->alg)
#define ND_UF_parent(n) (((Agnodeinfo_t*)AGDATA(n))->UF_parent)
#define ND_set(n) (((Agnodeinfo_t*)AGDATA(n))->set)
#define ND_UF_size(n) (((Agnodeinfo_t*)AGDATA(n))->UF_size)
#define ND_bb(n) (((Agnodeinfo_t*)AGDATA(n))->bb)
#define ND_clust(n) (((Agnodeinfo_t*)AGDATA(n))->clust)
#define ND_coord(n) (((Agnodeinfo_t*)AGDATA(n))->coord)
#define ND_dist(n) (((Agnodeinfo_t*)AGDATA(n))->dist)
#define ND_flat_in(n) (((Agnodeinfo_t*)AGDATA(n))->flat_in)
#define ND_flat_out(n) (((Agnodeinfo_t*)AGDATA(n))->flat_out)
#define ND_gui_state(n) (((Agnodeinfo_t*)AGDATA(n))->gui_state)
#define ND_has_port(n) (((Agnodeinfo_t*)AGDATA(n))->has_port)
#define ND_rep(n) (((Agnodeinfo_t*)AGDATA(n))->rep)
#define ND_heapindex(n) (((Agnodeinfo_t*)AGDATA(n))->heapindex)
#define ND_height(n) (((Agnodeinfo_t*)AGDATA(n))->height)
#define ND_hops(n) (((Agnodeinfo_t*)AGDATA(n))->hops)
#define ND_ht(n) (((Agnodeinfo_t*)AGDATA(n))->ht)
#define ND_in(n) (((Agnodeinfo_t*)AGDATA(n))->in)
#define ND_inleaf(n) (((Agnodeinfo_t*)AGDATA(n))->inleaf)
#define ND_label(n) (((Agnodeinfo_t*)AGDATA(n))->label)
#define ND_xlabel(n) (((Agnodeinfo_t*)AGDATA(n))->xlabel)
#define ND_lim(n) (((Agnodeinfo_t*)AGDATA(n))->lim)
#define ND_low(n) (((Agnodeinfo_t*)AGDATA(n))->low)
#define ND_lw(n) (((Agnodeinfo_t*)AGDATA(n))->lw)
#define ND_mark(n) (((Agnodeinfo_t*)AGDATA(n))->mark)
#define ND_mval(n) (((Agnodeinfo_t*)AGDATA(n))->mval)
#define ND_n_cluster(n) (((Agnodeinfo_t*)AGDATA(n))->n_cluster)
#define ND_next(n) (((Agnodeinfo_t*)AGDATA(n))->next)
#define ND_node_type(n) (((Agnodeinfo_t*)AGDATA(n))->node_type)
#define ND_onstack(n) (((Agnodeinfo_t*)AGDATA(n))->onstack)
#define ND_order(n) (((Agnodeinfo_t*)AGDATA(n))->order)
#define ND_other(n) (((Agnodeinfo_t*)AGDATA(n))->other)
#define ND_out(n) (((Agnodeinfo_t*)AGDATA(n))->out)
#define ND_outleaf(n) (((Agnodeinfo_t*)AGDATA(n))->outleaf)
#define ND_par(n) (((Agnodeinfo_t*)AGDATA(n))->par)
#define ND_pinned(n) (((Agnodeinfo_t*)AGDATA(n))->pinned)
#define ND_pos(n) (((Agnodeinfo_t*)AGDATA(n))->pos)
#define ND_prev(n) (((Agnodeinfo_t*)AGDATA(n))->prev)
#define ND_priority(n) (((Agnodeinfo_t*)AGDATA(n))->priority)
#define ND_rank(n) (((Agnodeinfo_t*)AGDATA(n))->rank)
#define ND_ranktype(n) (((Agnodeinfo_t*)AGDATA(n))->ranktype)
#define ND_rw(n) (((Agnodeinfo_t*)AGDATA(n))->rw)
#define ND_save_in(n) (((Agnodeinfo_t*)AGDATA(n))->save_in)
#define ND_save_out(n) (((Agnodeinfo_t*)AGDATA(n))->save_out)
#define ND_shape(n) (((Agnodeinfo_t*)AGDATA(n))->shape)
#define ND_shape_info(n) (((Agnodeinfo_t*)AGDATA(n))->shape_info)
#define ND_showboxes(n) (((Agnodeinfo_t*)AGDATA(n))->showboxes)
#define ND_state(n) (((Agnodeinfo_t*)AGDATA(n))->state)
#define ND_clustnode(n) (((Agnodeinfo_t*)AGDATA(n))->clustnode)
#define ND_tree_in(n) (((Agnodeinfo_t*)AGDATA(n))->tree_in)
#define ND_tree_out(n) (((Agnodeinfo_t*)AGDATA(n))->tree_out)
#define ND_weight_class(n) (((Agnodeinfo_t*)AGDATA(n))->weight_class)
#define ND_width(n) (((Agnodeinfo_t*)AGDATA(n))->width)
#define ND_xsize(n) (ND_lw(n)+ND_rw(n))
#define ND_ysize(n) (ND_ht(n))

    typedef struct Agedgeinfo_t {
	Agrec_t hdr;
	splines *spl;
	port tail_port, head_port;
	textlabel_t *label, *head_label, *tail_label, *xlabel;
	char edge_type;
	char adjacent;          /* true for flat edge with adjacent nodes */
	char label_ontop;
	unsigned char gui_state; /* Edge state for GUI ops */
	edge_t *to_orig;	/* for dot's shapes.c    */
	void *alg;

#ifndef DOT_ONLY
	double factor;
	double dist;
	Ppolyline_t path;
#endif
#ifndef NEATO_ONLY
	unsigned char showboxes;
	boolean conc_opp_flag;
	short xpenalty;
	int weight;
	int cutvalue, tree_index;
	short count;
	unsigned short minlen;
	edge_t *to_virt;
#endif
    } Agedgeinfo_t;

#define ED_alg(e) (((Agedgeinfo_t*)AGDATA(e))->alg)
#define ED_conc_opp_flag(e) (((Agedgeinfo_t*)AGDATA(e))->conc_opp_flag)
#define ED_count(e) (((Agedgeinfo_t*)AGDATA(e))->count)
#define ED_cutvalue(e) (((Agedgeinfo_t*)AGDATA(e))->cutvalue)
#define ED_edge_type(e) (((Agedgeinfo_t*)AGDATA(e))->edge_type)
#define ED_adjacent(e) (((Agedgeinfo_t*)AGDATA(e))->adjacent)
#define ED_factor(e) (((Agedgeinfo_t*)AGDATA(e))->factor)
#define ED_gui_state(e) (((Agedgeinfo_t*)AGDATA(e))->gui_state)
#define ED_head_label(e) (((Agedgeinfo_t*)AGDATA(e))->head_label)
#define ED_head_port(e) (((Agedgeinfo_t*)AGDATA(e))->head_port)
#define ED_label(e) (((Agedgeinfo_t*)AGDATA(e))->label)
#define ED_xlabel(e) (((Agedgeinfo_t*)AGDATA(e))->xlabel)
#define ED_label_ontop(e) (((Agedgeinfo_t*)AGDATA(e))->label_ontop)
#define ED_minlen(e) (((Agedgeinfo_t*)AGDATA(e))->minlen)
#define ED_path(e) (((Agedgeinfo_t*)AGDATA(e))->path)
#define ED_showboxes(e) (((Agedgeinfo_t*)AGDATA(e))->showboxes)
#define ED_spl(e) (((Agedgeinfo_t*)AGDATA(e))->spl)
#define ED_tail_label(e) (((Agedgeinfo_t*)AGDATA(e))->tail_label)
#define ED_tail_port(e) (((Agedgeinfo_t*)AGDATA(e))->tail_port)
#define ED_to_orig(e) (((Agedgeinfo_t*)AGDATA(e))->to_orig)
#define ED_to_virt(e) (((Agedgeinfo_t*)AGDATA(e))->to_virt)
#define ED_tree_index(e) (((Agedgeinfo_t*)AGDATA(e))->tree_index)
#define ED_xpenalty(e) (((Agedgeinfo_t*)AGDATA(e))->xpenalty)
#define ED_dist(e) (((Agedgeinfo_t*)AGDATA(e))->dist)
#define ED_weight(e) (((Agedgeinfo_t*)AGDATA(e))->weight)

#define ag_xget(x,a) agxget(x,a)
#define SET_RANKDIR(g,rd) (GD_rankdir2(g) = rd)
#define agfindedge(g,t,h) (agedge(g,t,h,NULL,0))
#define agfindnode(g,n) (agnode(g,n,0))
#define agfindgraphattr(g,a) (agattr(g,AGRAPH,a,NULL))
#define agfindnodeattr(g,a) (agattr(g,AGNODE,a,NULL))
#define agfindedgeattr(g,a) (agattr(g,AGEDGE,a,NULL))

    typedef struct {
	int flags;
    } gvlayout_features_t;

#ifdef __cplusplus
}
#endif
#endif
