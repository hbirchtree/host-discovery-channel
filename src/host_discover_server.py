#!/usr/bin/python3

import time
from sys import argv

from server_base import *
from databases import *
from app_base import *

from rest_api import *


class Host:
    def __init__(self,host_name,host_ip,last_online = time.time()):
        self.hostname = host_name
        self.ip = host_ip
        self.last_online = last_online


"""
    Get all hosts, regardless of status
"""
def get_all_hosts():
    hosts = query_db("SELECT * FROM HOST;");
    host_list = [Host(h[1],h[2],h[3]) for h in hosts];
    return host_list;


def get_interface_hosts(inf):
    out = []
    # Check for validity
    if inf.subwidth == 0:
        return out;
    # We don't want to really implement this, we cheat for now
    subnet_arr = inf.subnet.split('.')[:int(inf.subwidth/8)]
    subnet_str = ""
    for p in subnet_arr:
        subnet_str += p + "."
    for h in get_all_hosts():
        if h.ip.startswith(subnet_str):
            out += [h]
    return out


class Interface:
    def __init__(self,name,subnet):
        self.name = name;
        self.subnet = subnet.split('/')[0];
        self.subwidth = 0;
        if len(subnet.split('/')) > 1:
            self.subwidth = int(subnet.split('/')[1]);
        self.hosts = get_interface_hosts(self);


"""
    Get all interfaces
"""
def get_all_interfaces():
    infs = query_db("SELECT * FROM INTERFACE;");
    inf_list = [Interface(i[0],i[1]) for i in infs];
    return inf_list;


"""
    For inserting a new or updating an existing host
    We do two queries because it may not exist
"""
def update_host(h):
    inserted = insert_into_db(
            """
            INSERT OR IGNORE
              INTO HOST(HOSTNAME,LAST_IP,LAST_ONLINE)
              VALUES(?,?,datetime(?,'unixepoch','localtime'));
            """,
            (h.hostname,h.ip,h.last_online)
            );
    
    insert_into_db(
            """
            UPDATE HOST
              SET LAST_IP = ?
              WHERE HOSTNAME = ?;
            """,
            (h.ip,h.hostname)
            );


"""
    For inserting a new network interface, or updating one
"""
def update_interface(i):
    insert_into_db(
            """
            INSERT OR IGNORE
              INTO INTERFACE(INTERFACE_ID,SUBNET)
              VALUES(?,?);
            """,
            (i.name,i.subnet+"/"+str(i.subwidth))
            );
    
    insert_into_db(
            """
            UPDATE INTERFACE
              SET SUBNET = ?
              WHERE INTERFACE_ID = ?;
            """,
            (i.subnet+"/"+str(i.subwidth),i.name)
            );

"""
    Primary interface for most users
"""
@app.route("/",methods=['GET'])
def default_route():
    return render_template('display.html',
        name='index',interfaces=get_all_interfaces(),
        categories=("Host","IP address","Last seen"),
        categories_len=3,
        title=app.config['PAGE_TITLE'],
        project=app.config['PROJECT_TITLE']);


if __name__ == "__main__":
    if len(argv) > 1:
        if argv[1] == "host":
            update_host(Host(argv[2],argv[3]));
        elif argv[1] == "inf":
            print("Got ",argv[2],argv[3])
            update_interface(Interface(argv[2],argv[3]));
        exit(0)
    app.run(host='0.0.0.0',port=5001,debug=True);

