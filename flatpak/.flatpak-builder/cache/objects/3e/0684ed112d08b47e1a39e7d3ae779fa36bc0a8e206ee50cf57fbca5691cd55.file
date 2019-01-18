#ifndef _CDT_H
#define _CDT_H		1

#ifdef __cplusplus
extern "C" {
#endif

/*	Public interface for the dictionary library
**
**      Written by Kiem-Phong Vo
*/

#define CDT_VERSION	20050420L

#include <stddef.h>	/* size_t */
#include <string.h>

#ifdef _WIN32
#undef __EXPORT__
#undef __IMPORT__
#define __EXPORT__  __declspec (dllexport)
#define __IMPORT__	__declspec (dllimport)
#endif

typedef struct _dtlink_s	Dtlink_t;
typedef struct _dthold_s	Dthold_t;
typedef struct _dtdisc_s	Dtdisc_t;
typedef struct _dtmethod_s	Dtmethod_t;
typedef struct _dtdata_s	Dtdata_t;
typedef struct _dt_s		Dt_t;
typedef struct _dt_s		Dict_t;	/* for libdict compatibility */
typedef struct _dtstat_s	Dtstat_t;
typedef void*			(*Dtmemory_f)(Dt_t*,void*,size_t,Dtdisc_t*);
typedef void*			(*Dtsearch_f)(Dt_t*,void*,int);
typedef void* 		(*Dtmake_f)(Dt_t*,void*,Dtdisc_t*);
typedef void 			(*Dtfree_f)(Dt_t*,void*,Dtdisc_t*);
typedef int			(*Dtcompar_f)(Dt_t*,void*,void*,Dtdisc_t*);
typedef unsigned int		(*Dthash_f)(Dt_t*,void*,Dtdisc_t*);
typedef int			(*Dtevent_f)(Dt_t*,int,void*,Dtdisc_t*);

struct _dtlink_s
{	Dtlink_t*	right;	/* right child		*/
	union
	{ unsigned int	_hash;	/* hash value		*/
	  Dtlink_t*	_left;	/* left child		*/
	} hl;
};

/* private structure to hold an object */
struct _dthold_s
{	Dtlink_t	hdr;	/* header		*/
	void*		obj;	/* user object		*/
};

/* method to manipulate dictionary structure */
struct _dtmethod_s 
{	Dtsearch_f	searchf; /* search function	*/
	int		type;	/* type of operation	*/
};

/* stuff that may be in shared memory */
struct _dtdata_s
{	int		type;	/* type of dictionary			*/
	Dtlink_t*	here;	/* finger to last search element	*/
	union
	{ Dtlink_t**	_htab;	/* hash table				*/
	  Dtlink_t*	_head;	/* linked list				*/
	} hh;
	int		ntab;	/* number of hash slots			*/
	int		size;	/* number of objects			*/
	int		loop;	/* number of nested loops		*/
	int		minp;	/* min path before splay, always even	*/
				/* for hash dt, > 0: fixed table size 	*/
};

/* structure to hold methods that manipulate an object */
struct _dtdisc_s
{	int		key;	/* where the key begins in an object	*/
	int		size;	/* key size and type			*/
	int		link;	/* offset to Dtlink_t field		*/
	Dtmake_f	makef;	/* object constructor			*/
	Dtfree_f	freef;	/* object destructor			*/
	Dtcompar_f	comparf;/* to compare two objects		*/
	Dthash_f	hashf;	/* to compute hash value of an object	*/
	Dtmemory_f	memoryf;/* to allocate/free memory		*/
	Dtevent_f	eventf;	/* to process events			*/
};

#define DTDISC(dc,ky,sz,lk,mkf,frf,cmpf,hshf,memf,evf) \
	( (dc)->key = (ky), (dc)->size = (sz), (dc)->link = (lk), \
	  (dc)->makef = (mkf), (dc)->freef = (frf), \
	  (dc)->comparf = (cmpf), (dc)->hashf = (hshf), \
	  (dc)->memoryf = (memf), (dc)->eventf = (evf) )

/* the dictionary structure itself */
struct _dt_s
{	Dtsearch_f	searchf;/* search function			*/
	Dtdisc_t*	disc;	/* method to manipulate objs		*/
	Dtdata_t*	data;	/* sharable data			*/
	Dtmemory_f	memoryf;/* function to alloc/free memory	*/
	Dtmethod_t*	meth;	/* dictionary method			*/
	int		type;	/* type information			*/
	int		nview;	/* number of parent view dictionaries	*/
	Dt_t*		view;	/* next on viewpath			*/
	Dt_t*		walk;	/* dictionary being walked		*/
	void*		user;	/* for user's usage			*/
};

/* structure to get status of a dictionary */
struct _dtstat_s
{	int	dt_meth;	/* method type				*/
	int	dt_size;	/* number of elements			*/
	int	dt_n;		/* number of chains or levels		*/
	int	dt_max;		/* max size of a chain or a level	*/
	int*	dt_count;	/* counts of chains or levels by size	*/
};

/* flag set if the last search operation actually found the object */
#define DT_FOUND	0100000

/* supported storage methods */
#define DT_SET		0000001	/* set with unique elements		*/
#define DT_BAG		0000002	/* multiset				*/
#define DT_OSET		0000004	/* ordered set (self-adjusting tree)	*/
#define DT_OBAG		0000010	/* ordered multiset			*/
#define DT_LIST		0000020	/* linked list				*/
#define DT_STACK	0000040	/* stack: insert/delete at top		*/
#define DT_QUEUE	0000100	/* queue: insert at top, delete at tail	*/
#define DT_DEQUE	0000200 /* deque: insert at top, append at tail	*/
#define DT_METHODS	0000377	/* all currently supported methods	*/

/* asserts to dtdisc() */
#define DT_SAMECMP	0000001	/* compare methods equivalent		*/
#define DT_SAMEHASH	0000002	/* hash methods equivalent		*/

/* types of search */
#define DT_INSERT	0000001	/* insert object if not found		*/
#define DT_DELETE	0000002	/* delete object if found		*/
#define DT_SEARCH	0000004	/* look for an object			*/
#define DT_NEXT		0000010	/* look for next element		*/
#define DT_PREV		0000020	/* find previous element		*/
#define DT_RENEW	0000040	/* renewing an object			*/
#define DT_CLEAR	0000100	/* clearing all objects			*/
#define DT_FIRST	0000200	/* get first object			*/
#define DT_LAST		0000400	/* get last object			*/
#define DT_MATCH	0001000	/* find object matching key		*/
#define DT_VSEARCH	0002000	/* search using internal representation	*/
#define DT_ATTACH	0004000	/* attach an object to the dictionary	*/
#define DT_DETACH	0010000	/* detach an object from the dictionary	*/
#define DT_APPEND	0020000	/* used on Dtlist to append an object	*/

/* events */
#define DT_OPEN		1	/* a dictionary is being opened		*/
#define DT_CLOSE	2	/* a dictionary is being closed		*/
#define DT_DISC		3	/* discipline is about to be changed	*/
#define DT_METH		4	/* method is about to be changed	*/
#define DT_ENDOPEN	5	/* dtopen() is done			*/
#define DT_ENDCLOSE	6	/* dtclose() is done			*/
#define DT_HASHSIZE	7	/* setting hash table size		*/

/* public data */
#if defined(_BLD_cdt) && defined(__EXPORT__)
#define extern	__EXPORT__
#endif
#if !defined(_BLD_cdt) && defined(__IMPORT__)
#define extern	__IMPORT__
#endif

extern Dtmethod_t* 	Dtset;
extern Dtmethod_t* 	Dtbag;
extern Dtmethod_t* 	Dtoset;
extern Dtmethod_t* 	Dtobag;
extern Dtmethod_t*	Dtlist;
extern Dtmethod_t*	Dtstack;
extern Dtmethod_t*	Dtqueue;
extern Dtmethod_t*	Dtdeque;

/* compatibility stuff; will go away */
#ifndef KPVDEL
extern Dtmethod_t*	Dtorder;
extern Dtmethod_t*	Dttree;
extern Dtmethod_t*	Dthash;
extern Dtmethod_t	_Dttree;
extern Dtmethod_t	_Dthash;
extern Dtmethod_t	_Dtlist;
extern Dtmethod_t	_Dtqueue;
extern Dtmethod_t	_Dtstack;
#endif

#undef extern

/* public functions */
#if defined(_BLD_cdt) && defined(__EXPORT__)
#define extern	__EXPORT__
#endif

extern Dt_t*		dtopen(Dtdisc_t*, Dtmethod_t*);
extern int		dtclose(Dt_t*);
extern Dt_t*		dtview(Dt_t*, Dt_t*);
extern Dtdisc_t*	dtdisc(Dt_t* dt, Dtdisc_t*, int);
extern Dtmethod_t*	dtmethod(Dt_t*, Dtmethod_t*);

extern Dtlink_t*	dtflatten(Dt_t*);
extern Dtlink_t*	dtextract(Dt_t*);
extern int		dtrestore(Dt_t*, Dtlink_t*);

extern int		dttreeset(Dt_t*, int, int);

extern int		dtwalk(Dt_t*, int(*)(Dt_t*,void*,void*), void*);

extern void*		dtrenew(Dt_t*, void*);

extern int		dtsize(Dt_t*);
extern int		dtstat(Dt_t*, Dtstat_t*, int);
extern unsigned int	dtstrhash(unsigned int, void*, int);

#undef extern

/* internal functions for translating among holder, object and key */
#define _DT(dt)		((Dt_t*)(dt))
#define _DTDSC(dc,ky,sz,lk,cmpf) \
			(ky = dc->key, sz = dc->size, lk = dc->link, cmpf = dc->comparf)
#define _DTLNK(o,lk)	((Dtlink_t*)((char*)(o) + lk) )
#define _DTOBJ(e,lk)	(lk < 0 ? ((Dthold_t*)(e))->obj : (void*)((char*)(e) - lk) )
#define _DTKEY(o,ky,sz)	(void*)(sz < 0 ? *((char**)((char*)(o)+ky)) : ((char*)(o)+ky))

#define _DTCMP(dt,k1,k2,dc,cmpf,sz) \
			(cmpf ? (*cmpf)(dt,k1,k2,dc) : \
			 (sz <= 0 ? strcmp(k1,k2) : memcmp(k1,k2,sz)) )
#define _DTHSH(dt,ky,dc,sz) (dc->hashf ? (*dc->hashf)(dt,ky,dc) : dtstrhash(0,ky,sz) )

/* special search function for tree structure only */
#define _DTMTCH(dt,key,action) \
	do { Dtlink_t* _e; void *_o, *_k, *_key; Dtdisc_t* _dc; \
	     int _ky, _sz, _lk, _cmp; Dtcompar_f _cmpf; \
	     _dc = (dt)->disc; _DTDSC(_dc, _ky, _sz, _lk, _cmpf); \
	     _key = (key); \
	     for(_e = (dt)->data->here; _e; _e = _cmp < 0 ? _e->hl._left : _e->right) \
	     {	_o = _DTOBJ(_e, _lk); _k = _DTKEY(_o, _ky, _sz); \
		if((_cmp = _DTCMP((dt), _key, _k, _dc, _cmpf, _sz)) == 0) \
			break; \
	     } \
	     action (_e ? _o : (void*)0); \
	} while(0)

#define _DTSRCH(dt,obj,action) \
	do { Dtlink_t* _e; void *_o, *_k, *_key; Dtdisc_t* _dc; \
	     int _ky, _sz, _lk, _cmp; Dtcompar_f _cmpf; \
	     _dc = (dt)->disc; _DTDSC(_dc, _ky, _sz, _lk, _cmpf); \
	     _key = _DTKEY(obj, _ky, _sz); \
	     for(_e = (dt)->data->here; _e; _e = _cmp < 0 ? _e->hl._left : _e->right) \
	     {	_o = _DTOBJ(_e, _lk); _k = _DTKEY(_o, _ky, _sz); \
		if((_cmp = _DTCMP((dt), _key, _k, _dc, _cmpf, _sz)) == 0) \
			break; \
	     } \
	     action (_e ? _o : (void*)0); \
	} while(0)

#define DTTREEMATCH(dt,key,action)	_DTMTCH(_DT(dt),(void*)(key),action)
#define DTTREESEARCH(dt,obj,action)	_DTSRCH(_DT(dt),(void*)(obj),action)

#define dtvnext(d)	(_DT(d)->view)
#define dtvcount(d)	(_DT(d)->nview)
#define dtvhere(d)	(_DT(d)->walk)

#define dtlink(d,e)	(((Dtlink_t*)(e))->right)
#define dtobj(d,e)	_DTOBJ((e), _DT(d)->disc->link)
#define dtfinger(d)	(_DT(d)->data->here ? dtobj((d),_DT(d)->data->here):(void*)(0))

#define dtfirst(d)	(*(_DT(d)->searchf))((d),(void*)(0),DT_FIRST)
#define dtnext(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_NEXT)
#define dtleast(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_SEARCH|DT_NEXT)
#define dtlast(d)	(*(_DT(d)->searchf))((d),(void*)(0),DT_LAST)
#define dtprev(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_PREV)
#define dtmost(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_SEARCH|DT_PREV)
#define dtsearch(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_SEARCH)
#define dtmatch(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_MATCH)
#define dtinsert(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_INSERT)
#define dtappend(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_INSERT|DT_APPEND)
#define dtdelete(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_DELETE)
#define dtattach(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_ATTACH)
#define dtdetach(d,o)	(*(_DT(d)->searchf))((d),(void*)(o),DT_DETACH)
#define dtclear(d)	(*(_DT(d)->searchf))((d),(void*)(0),DT_CLEAR)
#define dtfound(d)	(_DT(d)->type & DT_FOUND)

#define DT_PRIME	17109811 /* 2#00000001 00000101 00010011 00110011 */
#define dtcharhash(h,c) (((unsigned int)(h) + (unsigned int)(c)) * DT_PRIME )

#ifdef __cplusplus
}
#endif

#endif /* _CDT_H */
