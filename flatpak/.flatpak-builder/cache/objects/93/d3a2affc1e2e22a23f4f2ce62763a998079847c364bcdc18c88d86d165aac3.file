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

#ifndef XDOT_H
#define XDOT_H
#include <stdio.h>
#ifdef WIN32
#include <windows.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

#define INITIAL_XDOT_CAPACITY 512

typedef enum {
    xd_none,
    xd_linear,
    xd_radial
} xdot_grad_type;

typedef struct {
    float frac;
    char* color;
} xdot_color_stop;

typedef struct {
    double x0, y0;
    double x1, y1;
    int n_stops;
    xdot_color_stop* stops;
} xdot_linear_grad;

typedef struct {
    double x0, y0, r0;
    double x1, y1, r1;
    int n_stops;
    xdot_color_stop* stops;
} xdot_radial_grad;

typedef struct {
    xdot_grad_type type;
    union {
	char* clr;
	xdot_linear_grad ling;
	xdot_radial_grad ring;
    } u;
} xdot_color;

typedef enum {
    xd_left, xd_center, xd_right
} xdot_align;

typedef struct {
    double x, y, z;
} xdot_point;

typedef struct {
    double x, y, w, h;
} xdot_rect;

typedef struct {
    int cnt;
    xdot_point* pts;
} xdot_polyline;

typedef struct {
  double x, y;
  xdot_align align;
  double width;
  char* text;
} xdot_text;

typedef struct {
    xdot_rect pos;
    char* name;
} xdot_image;

typedef struct {
    double size;
    char* name;
} xdot_font;

typedef enum {
    xd_filled_ellipse, xd_unfilled_ellipse,
    xd_filled_polygon, xd_unfilled_polygon,
    xd_filled_bezier,  xd_unfilled_bezier,
    xd_polyline,       xd_text,
    xd_fill_color,     xd_pen_color, xd_font, xd_style, xd_image,
    xd_grad_fill_color,     xd_grad_pen_color,
    xd_fontchar
} xdot_kind; 
    
typedef enum {
    xop_ellipse,
    xop_polygon,
    xop_bezier,
    xop_polyline,       xop_text,
    xop_fill_color,     xop_pen_color, xop_font, xop_style, xop_image,
    xop_grad_color,
    xop_fontchar
} xop_kind; 
    
typedef struct _xdot_op xdot_op;
typedef void (*drawfunc_t)(xdot_op*, int);
typedef void (*freefunc_t)(xdot_op*);

struct _xdot_op {
    xdot_kind kind;
    union {
      xdot_rect ellipse;       /* xd_filled_ellipse, xd_unfilled_ellipse */
      xdot_polyline polygon;   /* xd_filled_polygon, xd_unfilled_polygon */
      xdot_polyline polyline;  /* xd_polyline */
      xdot_polyline bezier;    /* xd_filled_bezier,  xd_unfilled_bezier */
      xdot_text text;          /* xd_text */
      xdot_image image;        /* xd_image */
      char* color;             /* xd_fill_color, xd_pen_color */
      xdot_color grad_color;   /* xd_grad_fill_color, xd_grad_pen_color */
      xdot_font font;          /* xd_font */
      char* style;             /* xd_style */
      unsigned int fontchar;   /* xd_fontchar */
    } u;
    drawfunc_t drawfunc;
};

#define XDOT_PARSE_ERROR 1

typedef struct {
    int cnt;  /* no. of xdot ops */
    int sz;   /* sizeof structure containing xdot_op as first field */
    xdot_op* ops;
    freefunc_t freefunc;
    int flags;
} xdot;

typedef struct {
    int cnt;  /* no. of xdot ops */
    int n_ellipse;
    int n_polygon;
    int n_polygon_pts;
    int n_polyline;
    int n_polyline_pts;
    int n_bezier;
    int n_bezier_pts;
    int n_text;
    int n_font;
    int n_style;
    int n_color;
    int n_image;
    int n_gradcolor;
    int n_fontchar;
} xdot_stats;

/* ops are indexed by xop_kind */
extern xdot* parseXDotF (char*, drawfunc_t opfns[], int sz);
extern xdot* parseXDotFOn (char*, drawfunc_t opfns[], int sz, xdot*);
extern xdot* parseXDot (char*);
extern char* sprintXDot (xdot*);
extern void fprintXDot (FILE*, xdot*);
extern void jsonXDot (FILE*, xdot*);
extern void freeXDot (xdot*);
extern int statXDot (xdot*, xdot_stats*);
extern xdot_grad_type colorTypeXDot (char*);
extern char* parseXDotColor (char* cp, xdot_color* clr);
extern void freeXDotColor (xdot_color*);

#ifdef __cplusplus
}
#endif
#endif
