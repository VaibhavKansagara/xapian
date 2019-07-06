%{
/* xapianletor-headers.i: Getting SWIG to parse Xapian's C++ headers.
 *
 * Copyright 2004,2006,2011,2012,2013,2014,2015,2016,2017,2019 Olly Betts
 * Copyright 2014 Assem Chelli
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
 * USA
 */
%}

/* Ignore these functions: */
%ignore Xapian::iterator_rewind;
%ignore Xapian::iterator_valid;

/* Ignore anything ending in an underscore, which is for internal use only: */
%rename("$ignore", regexmatch$name="_$") "";

/* A class which can usefully be subclassed in the target language. */
%define SUBCLASSABLE(NS, CLASS)
    %ignore NS::CLASS::clone;
    %ignore NS::CLASS::serialise;
    %ignore NS::CLASS::unserialise;
    %#ifdef XAPIAN_SWIG_DIRECTORS
    %feature(director) NS::CLASS;
    %#endif
%enddef

/* A class which is only useful to wrap if the target language allows
 * subclassing of wrapped classes (what SWIG calls "director support").
 */
#ifdef XAPIAN_SWIG_DIRECTORS
#define SUBCLASSABLE_ONLY(NS, CLASS) SUBCLASSABLE(NS, CLASS)
#else
#define SUBCLASSABLE_ONLY(NS, CLASS) %ignore NS::CLASS;
#endif

#ifdef SWIGTCL
/* Tcl needs copy constructors it seems. */
%define STANDARD_IGNORES(NS, CLASS)
    %ignore NS::CLASS::internal;
    %ignore NS::CLASS::CLASS(Internal*);
    %ignore NS::CLASS::CLASS(Internal&);
    %ignore NS::CLASS::operator=;
    %ignore NS::CLASS::CLASS(CLASS &&);
%enddef
#else
%define STANDARD_IGNORES(NS, CLASS)
    %ignore NS::CLASS::internal;
    %ignore NS::CLASS::CLASS(Internal*);
    %ignore NS::CLASS::CLASS(Internal&);
    %ignore NS::CLASS::operator=;
    %ignore NS::CLASS::CLASS(const CLASS &);
    %ignore NS::CLASS::CLASS(CLASS &&);
%enddef
#endif

#ifdef SWIGCSHARP
/* In C#, next and prev return the iterator object. */
#define INC_OR_DEC(METHOD, OP, NS, CLASS, RET_TYPE) NS::CLASS METHOD() { return OP(*self); }
#elif defined SWIGJAVA
/* In Java, next and prev return the result of dereferencing the iterator. */
#define INC_OR_DEC(METHOD, OP, NS, CLASS, RET_TYPE) RET_TYPE METHOD() { return *(OP(*self)); }
#else
/* Otherwise, next and prev return void. */
#define INC_OR_DEC(METHOD, OP, NS, CLASS, RET_TYPE) void METHOD() { OP(*self); }
#endif

/* For other languages, SWIG already renames operator() suitably. */
#if defined SWIGJAVA || defined SWIGPHP || defined SWIGTCL
%rename(apply) *::operator();
#elif defined SWIGCSHARP
%rename(Apply) *::operator();
#endif

/* We use %ignore and %extend rather than %rename on operator* so that any
 * pattern rename used to match local naming conventions applies to
 * DEREF_METHOD.
 */
%define INPUT_ITERATOR_METHODS(NS, CLASS, RET_TYPE, DEREF_METHOD)
    STANDARD_IGNORES(NS, CLASS)
    %ignore NS::CLASS::operator++;
    %ignore NS::CLASS::operator*;
    %extend NS::CLASS {
	bool equals(const NS::CLASS & o) const { return *self == o; }
	RET_TYPE DEREF_METHOD() const { return **self; }
	INC_OR_DEC(next, ++, NS, CLASS, RET_TYPE)
    }
%enddef

%define RANDOM_ACCESS_ITERATOR_METHODS(NS, CLASS, RET_TYPE, DEREF_METHOD)
    INPUT_ITERATOR_METHODS(NS, CLASS, RET_TYPE, DEREF_METHOD)
    %ignore NS::CLASS::operator--;
    %ignore NS::CLASS::operator+=;
    %ignore NS::CLASS::operator-=;
    %ignore NS::CLASS::operator+;
    %ignore NS::CLASS::operator-;
    %extend NS::CLASS {
	INC_OR_DEC(prev, --, NS, CLASS, RET_TYPE)
    }
%enddef

%define CONSTANT(TYPE, NS, NAME)
    %ignore NS::NAME;
    %constant TYPE NAME = NS::NAME;
%enddef

/* Ignore these for all classes: */
%ignore operator==;
%ignore operator!=;
%ignore operator<;
%ignore operator>;
%ignore operator<=;
%ignore operator>=;
%ignore operator+;
%ignore difference_type;
%ignore iterator_category;
%ignore value_type;
%ignore max_size;
%ignore swap;
%ignore iterator;
%ignore const_iterator;
%ignore size_type;
%ignore unserialise(const char **, const char *);
%ignore release();

%include <xapian-letor.h>

// Disable errors about not including headers individually.
#define XAPIANLETOR_IN_XAPIANLETOR_H

/* The Error subclasses are handled separately for languages where we wrap
 * them. */
/* %include <xapian-letor/letor_error.h> */

#if defined SWIGCSHARP || defined SWIGJAVA

/* C# and Java don't allow functions outside a class so we can't use SWIG's
 * %nspace feature here.  Instead we pretend to SWIG that the C++
 * Xapian::Remote namespace is actually a Xapian::Remote class with public
 * static functions.  The code SWIG generates will work fine, and we get
 * xapian.Remote.open() in Java and Xapian.Remote.open() in C#.
 */

#endif
