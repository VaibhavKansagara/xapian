%{
/* python/utilletor.i: custom Python typemaps for xapian-bindings
 *
 * Copyright (C) 2002,2003 James Aylett
 * Copyright (C) 2002,2003,2004,2005,2006,2007,2008,2009,2010,2011,2013,2016,2017,2019 Olly Betts
 * Copyright (C) 2007 Lemur Consulting Ltd
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

%include typemaps.i
%include stl.i

/* Wrap get_description() methods as str(). */
%rename(__str__) get_description;

/* So iterator objects match the Python3 iterator API. */
%rename(__next__) next;

%fragment("XapianSWIG_anystring_as_ptr", "header", fragment="SWIG_AsPtr_std_string") {
/* Utility function which works like SWIG_AsPtr_std_string, but
 * converts unicode strings to UTF-8 simple strings first. */
static int
XapianSWIG_anystring_as_ptr(PyObject * obj, std::string **val)
{
    if (PyUnicode_Check(obj)) {
	PyObject* strobj = PyUnicode_AsUTF8String(obj);
	if (strobj == NULL) return INT_MIN;
	char *p;
	Py_ssize_t len;
	PyBytes_AsStringAndSize(strobj, &p, &len);
	if (val) *val = new std::string(p, len);
	Py_DECREF(strobj);
	return SWIG_NEWOBJ;
    } else if (PyBytes_Check(obj)) {
	char *p;
	Py_ssize_t len;
	PyBytes_AsStringAndSize(obj, &p, &len);
	if (val) *val = new std::string(p, len);
	return SWIG_NEWOBJ;
    } else {
	return SWIG_AsPtr_std_string(obj, val);
    }
}
}

/* These typemaps depends somewhat heavily on the internals of SWIG, so
 * might break with future versions of SWIG.
 */
%typemap(in, fragment="XapianSWIG_anystring_as_ptr") const std::string &(int res = SWIG_OLDOBJ) {
    std::string *ptr = (std::string *)0;
    res = XapianSWIG_anystring_as_ptr($input, &ptr);
    if (!SWIG_IsOK(res)) {
	if (res == INT_MIN) SWIG_fail;
	%argument_fail(res, "$type", $symname, $argnum);
    }
    if (!ptr) {
	%argument_nullref("$type", $symname, $argnum);
    }
    $1 = ptr;
}
%typemap(in, fragment="XapianSWIG_anystring_as_ptr") std::string {
    std::string *ptr = (std::string *)0;
    int res = XapianSWIG_anystring_as_ptr($input, &ptr);
    if (!SWIG_IsOK(res) || !ptr) {
	if (res == INT_MIN) SWIG_fail;
	%argument_fail((ptr ? res : SWIG_TypeError), "$type", $symname, $argnum);
    }
    $1 = *ptr;
    if (SWIG_IsNewObj(res)) delete ptr;
}
%typemap(freearg, noblock=1, match="in") const std::string & {
    if (SWIG_IsNewObj(res$argnum)) %delete($1);
}
%typemap(typecheck, noblock=1, precedence=900) const std::string & {
    if (PyUnicode_Check($input)) {
	$1 = 1;
    } else if (PyBytes_Check($input)) {
	$1 = 1;
    } else {
	int res = SWIG_AsPtr_std_string($input, (std::string**)(0));
	$1 = SWIG_CheckState(res);
    }
}

%typemap(in, fragment="XapianSWIG_anystring_as_ptr") const std::string *(int res = SWIG_OLDOBJ) {
    std::string *ptr = (std::string *)0;
    if ($input != Py_None) {
	res = XapianSWIG_anystring_as_ptr($input, &ptr);
	if (!SWIG_IsOK(res)) {
	    if (res == INT_MIN) SWIG_fail;
	    %argument_fail(res, "$type", $symname, $argnum);
	}
    }
    $1 = ptr;
}
%typemap(freearg, noblock=1, match="in") const std::string * {
    if (SWIG_IsNewObj(res$argnum)) %delete($1);
}
%typemap(typecheck, noblock=1, precedence=900) const std::string * {
    if ($input == Py_None) {
	$1 = 1;
    } else if (PyUnicode_Check($input)) {
	$1 = 1;
    } else if (PyBytes_Check($input)) {
	$1 = 1;
    } else {
	int res = SWIG_AsPtr_std_string($input, (std::string**)(0));
	$1 = SWIG_CheckState(res);
    }
}

/* This typemap is only currently needed for returning a value from the
 * get_description() method of a Stopper subclass to a C++ caller, but might be
 * more generally useful in future.
 */
%typemap(directorout, noblock=1, fragment="XapianSWIG_anystring_as_ptr") std::string {
    std::string *swig_optr = 0;
    int swig_ores;
    {
	PyObject * tmp = $input;
	Py_INCREF(tmp);
	swig_ores = XapianSWIG_anystring_as_ptr(tmp, &swig_optr);
	Py_DECREF(tmp);
    }
    if (!SWIG_IsOK(swig_ores) || !swig_optr) {
	%dirout_fail((swig_optr ? swig_ores : SWIG_TypeError), "$type");
    }
    $result = *swig_optr;
    if (SWIG_IsNewObj(swig_ores)) %delete(swig_optr);
}

%typemap(directorin) (size_t num_tags, const std::string tags[]) {
    PyObject * result = PyList_New(num_tags);
    if (result == 0) {
	return NULL;
    }

    for (size_t i = 0; i != num_tags; ++i) {
	PyObject * str = PyBytes_FromStringAndSize(tags[i].data(), tags[i].size());
	if (str == 0) {
	    Py_DECREF(result);
	    return NULL;
	}

	PyList_SET_ITEM(result, i, str);
    }
    $input = result;
}

/* vim:set syntax=cpp:set noexpandtab: */
