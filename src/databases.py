#!/usr/bin/python3

from app_base import *

"""
  Database functions, pretty stock
"""

# Connecting to database on start
def connect_to_database():
    return sqlite3.connect(app.config['DATABASE']);

# Opening the database at start of program or for a query
def open_db():
    db = getattr(g,'_database',None);
    if db == None:
        db = g._database = connect_to_database();
    db.row_factory = sqlite3.Row;
    return db;

# Initializing the database on first run
def init_db():
    with app.app_context():
        db = open_db();
        with app.open_resource(app.config['DATABASE_SCHEMA'],mode='r') as f:
            db.cursor().executescript(f.read());
        db.commit();

@app.teardown_appcontext
def close_db(exception):
    db = getattr(g,'_database',None);
    if db != None:
        db.close();

"""
  Custom database helper functions
"""

# General database query
def query_db(query,args=(),one=False):
    with app.app_context():
        with open_db() as db:
            cur = db.execute(query,args);
            rd = cur.fetchall();
            cur.close();
            db.commit();
            return (rd[0] if rd else None) if one else rd;

# General database query
def insert_into_db(query,args=(),one=False):
    with app.app_context():
        keys = []
        with open_db() as db:
            cur = db.execute(query,args);
            rd = cur.fetchall();
            key = cur.lastrowid;
            cur.close();
            db.commit();
            keys += [key];
        return keys;


def get_project_data():
    pinfo = {};
    pinfo['title'] = app.config['PROJECT_TITLE'];
    pinfo['max_binsize'] = app.config['MAX_CONTENT_LENGTH'];
    return pinfo;
