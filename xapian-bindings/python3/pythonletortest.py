# Tests of Python-specific parts of the xapian bindings.
#
# Copyright (C) 2007 Lemur Consulting Ltd
# Copyright (C) 2008,2009,2010,2011,2013,2014,2015,2016,2019 Olly Betts
# Copyright (C) 2010,2011 Richard Boulton
#
# This program is free software you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation either version 2 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301
# USA

import os
import random
import shutil
import sys
import tempfile
import xapian
import xapianletor

try:
    import threading
    have_threads = True
except ImportError:
    have_threads = False

from testsuite import *

def setup_database_one():
    """Set database with 1 document.

    """
    db = xapian.WritableDatabase('', xapian.DB_BACKEND_INMEMORY)
    doc = xapian.Document()
    termgen = xapian.TermGenerator()
    termgen.set_document(doc)
    termgen.set_stemmer(xapian.Stem('en'))

    termgen.index_text("Tigers are solitary animals", 1, "S")
    termgen.index_text("Might be that only one Tiger is good enough to "
			     "Take out a ranker, a Tiger is a good way to "
			     "check if a test is working or Tiger not. Tiger."
			     "What if the next line contains no Tigers? Would "
			     "it make a difference to your ranker ?  Tigers  "
			     "for the win.", 1, "XD")
    termgen.index_text("The will.")
    termgen.increase_termpos()
    termgen.index_text("Tigers would not be caught if one calls out the "
			     "Tiger from the den. This document is to check if "
			     "in the massive dataset, you forget the sense of "
			     "something you would not like to stop.")
    db.add_document(doc)
    expect(db.get_doccount(), 1)
    return db

def setup_database_two():
    """Set database with 2 documents.

    """
    db = xapian.WritableDatabase('', xapian.DB_BACKEND_INMEMORY)
    doc = xapian.Document()
    termgen = xapian.TermGenerator()
    termgen.set_document(doc)
    termgen.set_stemmer(xapian.Stem("en"))
    termgen.index_text("Lions, Tigers, Bears and Giraffes", 1, "S")
    termgen.index_text("This paragraph talks about lions and tigers and "
			     "bears (oh, my!). It mentions giraffes, "
			     "but that's not really very important. Lions "
			     "and tigers are big cats, so they must be really "
			     "cuddly. Bears are famous for being cuddly, at "
			     "least when they're teddy bears.", 1, "XD")
    termgen.index_text("Lions, Tigers, Bears and Giraffes")
    termgen.increase_termpos()
    termgen.index_text("This paragraph talks about lions and tigers and "
			     "bears (oh, my!). It mentions giraffes, "
			     "but that's not really very important. Lions "
			     "and tigers are big cats, so they must be really "
			     "cuddly. Bears are famous for being cuddly, at "
			     "least when they're teddy bears.")
    db.add_document(doc)
    doc.clear_terms()
    termgen.index_text("Lions, Tigers and Bears", 1, "S")
    termgen.index_text("This is the paragraph of interest. Tigers are "
			     "massive beasts - I wouldn't want to meet a "
			     "hungry one anywhere. Lions are scary even when "
			     "lyin' down. Bears are scary even when bare. "
			     "Together I suspect they'd be less scary, as the "
			     "tigers, lions, and bears would all keep each "
			     "other busy. On the other hand, bears don't live "
			     "in the same continent as far as I know.", 1,
			     "XD")
    termgen.index_text("Lions, Tigers and Bears")
    termgen.increase_termpos()
    termgen.index_text("This is the paragraph of interest. Tigers are "
			     "massive beasts - I wouldn't want to meet a "
			     "hungry one anywhere. Lions are scary even when "
			     "lyin' down. Bears are scary even when bare. "
			     "Together I suspect they'd be less scary, as the "
			     "tigers, lions, and bears would all keep each "
			     "other busy. On the other hand, bears don't live "
			     "in the same continent as far as I know.")
    db.add_document(doc)
    expect(db.get_doccount(), 2)
    return db

def setup_database_three():
    """Set database with 3 documents.

    """
    db = xapian.WritableDatabase('', xapian.DB_BACKEND_INMEMORY)
    doc = xapian.Document()
    termgen = xapian.TermGenerator()
    termgen.set_document(doc)
    termgen.set_stemmer(xapian.Stem("en"))
    termgen.index_text("The will", 1, "S")
    termgen.index_text("The will are considered stop words in xapian and "
			     "would be thrown off, so the query I want to say "
			     "is score, yes, score. The Score of a game is "
			     "the determining factor of a game, the score is "
			     "what matters at the end of the day. so my advise "
			     "to everyone is to Score it!.", 1, "XD")
    termgen.index_text("Score might be something else too, but this para "
			     "refers to score only at an abstract. Scores are "
			     "in general scoring. Score it!")
    termgen.increase_termpos()
    termgen.index_text("Score score score is important.")
    db.add_document(doc)
    doc.clear_terms()
    termgen.index_text("Score score score score score score", 1, "S")
    termgen.index_text("it might have an absurdly high rank in the qrel "
			     "file or might have no rank at all in another. "
			     "Look out for this as a testcase, might be edgy "
			     "good luck and may this be with you.", 1, "XD")
    termgen.index_text("Another irrelevant paragraph to make sure the tf "
			     "values are down, but this increases idf values "
			     "but let's see how this works out.")
    termgen.increase_termpos()
    termgen.index_text("Nothing to do with the query.")
    db.add_document(doc)
    doc.clear_terms()
    termgen.index_text("Document has nothing to do with score", 1, "S")
    termgen.index_text("This is just to check if score is given a higher "
			     "score if it is in the subject or not. Nothing "
			     "special, just juding scores by the look of it. "
			     "Some more scores but a bad qrel should be enough "
			     "to make sure it is ranked down.", 1, "XD")
    termgen.index_text("Score might be something else too, but this para "
			     "refers to score only at an abstract. Scores are "
			     "in general scoring. Score it!")
    termgen.increase_termpos()
    termgen.index_text("Score score score is important.")
    db.add_document(doc)
    expect(db.get_doccount(), 3)
    return db

def test_createfeaturevector():
    db = setup_database_two()
    enquire = xapian.Enquire(db)
    enquire.set_query(xapian.Query("lions"))
    mset = enquire.get_mset(0, 10)

    expect(mset.size(), 2)
    fl = xapianletor.FeatureList()
    fv = fl.create_feature_vectors(mset, xapian.Query("lions"), db)
    expect(fv.size(), 2)
#     expect(fv[0].get_fcount(), 19)
#     expect(fv[1].get_fcount(), 19)

def test_import_letor_star():
    """Test that "from xapianletor import *" works.

    It's not normally good style to use it, but it should work anyway!

    """
    import test_xapian_letor_star

result = True

# Run all tests (ie, callables with names starting "test_").
def run():
    global result
    if not runtests(globals(), sys.argv[1:]):
        result = False

print("Running tests without threads")
run()

if have_threads:
    print("Running tests with threads")

    # This testcase seems to just block when run in a thread under Python 3
    # on some plaforms.  It fails with 3.2.3 on Debian wheezy, but passes
    # with the exact same package version on Debian unstable not long after
    # the jessie release.  The issue it's actually serving to regression
    # test for is covered by running it without threads, so just disable it
    # rather than risk test failures that don't seem to indicate a problem
    # in Xapian.
    del test_import_letor_star

    t = threading.Thread(name='test runner', target=run)
    t.start()
    # Block until the thread has completed so the thread gets a chance to exit
    # with error status.
    t.join()

if not result:
    sys.exit(1)

# vim:syntax=python:set expandtab: