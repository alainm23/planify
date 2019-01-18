/* Compile-time assert-like macros.

   Imported from gnulib 20090701 and adapted to Telepathy namespace.

   Copyright (C) 2005, 2006 Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License as published by
   the Free Software Foundation; either version 2.1 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* Written by Paul Eggert, Bruno Haible, and Jim Meyering.  */

#ifndef __TP_IN_UTIL_H__
#error Not to be used directly, #include <telepathy-glib/util.h> instead
#endif

#ifndef TP_VERIFY_H
# define TP_VERIFY_H 1

/* Each of these macros verifies that its argument R is nonzero.  To
   be portable, R should be an integer constant expression.  Unlike
   assert (R), there is no run-time overhead.

   There are two macros, since no single macro can be used in all
   contexts in C.  verify_true (R) is for scalar contexts, including
   integer constant expression contexts.  verify (R) is for declaration
   contexts, e.g., the top level.

   Symbols ending in "__" are private to this header.

   The code below uses several ideas.

   * The first step is ((R) ? 1 : -1).  Given an expression R, of
     integral or boolean or floating-point type, this yields an
     expression of integral type, whose value is later verified to be
     constant and nonnegative.

   * Next this expression W is wrapped in a type
     struct verify_type__ { unsigned int verify_error_if_negative_size__: W; }.
     If W is negative, this yields a compile-time error.  No compiler can
     deal with a bit-field of negative size.

     One might think that an array size check would have the same
     effect, that is, that the type struct { unsigned int dummy[W]; }
     would work as well.  However, inside a function, some compilers
     (such as C++ compilers and GNU C) allow local parameters and
     variables inside array size expressions.  With these compilers,
     an array size check would not properly diagnose this misuse of
     the verify macro:

       void function (int n) { verify (n < 0); }

   * For the verify macro, the struct verify_type__ will need to
     somehow be embedded into a declaration.  To be portable, this
     declaration must declare an object, a constant, a function, or a
     typedef name.  If the declared entity uses the type directly,
     such as in

       struct dummy {...};
       typedef struct {...} dummy;
       extern struct {...} *dummy;
       extern void dummy (struct {...} *);
       extern struct {...} *dummy (void);

     two uses of the verify macro would yield colliding declarations
     if the entity names are not disambiguated.  A workaround is to
     attach the current line number to the entity name:

       #define GL_CONCAT0(x, y) x##y
       #define GL_CONCAT(x, y) GL_CONCAT0 (x, y)
       extern struct {...} * GL_CONCAT(dummy,__LINE__);

     But this has the problem that two invocations of verify from
     within the same macro would collide, since the __LINE__ value
     would be the same for both invocations.

     A solution is to use the sizeof operator.  It yields a number,
     getting rid of the identity of the type.  Declarations like

       extern int dummy [sizeof (struct {...})];
       extern void dummy (int [sizeof (struct {...})]);
       extern int (*dummy (void)) [sizeof (struct {...})];

     can be repeated.

   * Should the implementation use a named struct or an unnamed struct?
     Which of the following alternatives can be used?

       extern int dummy [sizeof (struct {...})];
       extern int dummy [sizeof (struct verify_type__ {...})];
       extern void dummy (int [sizeof (struct {...})]);
       extern void dummy (int [sizeof (struct verify_type__ {...})]);
       extern int (*dummy (void)) [sizeof (struct {...})];
       extern int (*dummy (void)) [sizeof (struct verify_type__ {...})];

     In the second and sixth case, the struct type is exported to the
     outer scope; two such declarations therefore collide.  GCC warns
     about the first, third, and fourth cases.  So the only remaining
     possibility is the fifth case:

       extern int (*dummy (void)) [sizeof (struct {...})];

   * This implementation exploits the fact that GCC does not warn about
     the last declaration mentioned above.  If a future version of GCC
     introduces a warning for this, the problem could be worked around
     by using code specialized to GCC, e.g.,:

       #if 4 <= __GNUC__
       # define verify(R) \
	   extern int (* verify_function__ (void)) \
		      [__builtin_constant_p (R) && (R) ? 1 : -1]
       #endif

   * In C++, any struct definition inside sizeof is invalid.
     Use a template type to work around the problem.  */


/* Verify requirement R at compile-time, as an integer constant expression.
   Return 1.  */

# ifdef __cplusplus
template <int w>
  struct tp_verify_type__ { unsigned int verify_error_if_negative_size__: w; };
#  define tp_verify_true(R) \
     (!!sizeof (tp_verify_type__<(R) ? 1 : -1>))
# else
#  define tp_verify_true(R) \
     (!!sizeof \
      (struct { unsigned int verify_error_if_negative_size__: (R) ? 1 : -1; }))
# endif

/* Verify requirement R at compile-time, as a declaration without a
   trailing ';'.  */

# define tp_verify(R) extern int (* tp_verify_function__ (void)) [tp_verify_true (R)]

#endif
