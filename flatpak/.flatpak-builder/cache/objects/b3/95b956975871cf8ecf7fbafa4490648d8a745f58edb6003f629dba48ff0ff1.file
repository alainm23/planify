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

#ifndef TEXTSPAN_H
#define TEXTSPAN_H

#ifdef __cplusplus
extern "C" {
#endif

/* Bold, Italic, Underline, Sup, Sub, Strike */
/* Stored in textfont_t.flags, which is 7 bits, so full */
/* Probably should be moved to textspan_t */
#define HTML_BF   (1 << 0)
#define HTML_IF   (1 << 1)
#define HTML_UL   (1 << 2)
#define HTML_SUP  (1 << 3)
#define HTML_SUB  (1 << 4)
#define HTML_S    (1 << 5)
#define HTML_OL   (1 << 6)

    typedef struct _PostscriptAlias {
        char* name;
        char* family;
        char* weight;
        char* stretch;
        char* style;
        int xfig_code;
	char* svg_font_family;
	char* svg_font_weight;
	char* svg_font_style;
    } PostscriptAlias;

    /* font information
     * If name or color is NULL, or size < 0, that attribute
     * is unspecified. 
     */
    typedef struct {
	char*  name;
	char*  color;
	PostscriptAlias *postscript_alias;
	double size;
	unsigned int flags:7;  /* HTML_UL, HTML_IF, HTML_BF, etc. */
	unsigned int cnt:(sizeof(unsigned int) * 8 - 7);   /* reference count */
    } textfont_t;

    /* atomic unit of text emitted using a single htmlfont_t */
    typedef struct {
	char *str;      /* stored in utf-8 */
	textfont_t *font;
	void *layout;
	void (*free_layout) (void *layout);   /* FIXME - this is ugly */
	double yoffset_layout, yoffset_centerline;
 	pointf size;
	char just;	/* 'l' 'n' 'r' */ /* FIXME */
    } textspan_t;

#ifdef __cplusplus
}
#endif
#endif
