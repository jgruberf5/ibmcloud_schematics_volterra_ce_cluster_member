#!/usr/bin/env python3
import sys
import argparse
import urllib.request
import json
import time

PENDING_TIMEOUT = 300
PENDING_WAIT = 30

# REGISGTRATION_STATES = [ 'NOTSET', 'NEW', 'APPROVED', 'ADMITTED', 'RETIRED', 'FAILED', 'DONE', 'PENDING', 'ONLINE', 'UPGRADING', 'MAINTENANCE' ]

COUNT_REGISTRATION_STATES = ['APPROVED', 'ADMITTED', 'ONLINE']
DELETE_STATES = ['NOTSET', 'RETIRED', 'FAILED']
DECOMISSION_STATES = ['APPROVED', 'ADMITTED', 'ONLINE', 'PENDING']


def get_registrations(site, tenant, token):
    url = "https://%s.console.ves.volterra.io/api/register/namespaces/system/registrations_by_site/%s" % (
        tenant, site)
    headers = {
        "Authorization": "APIToken %s" % token
    }
    try:
        request = urllib.request.Request(
            url, headers=headers, method='GET')
        response = urllib.request.urlopen(request)
        return json.load(response)['items']
    except Exception as ex:
        sys.stderr.write(
            "Can not fetch site registrations for %s: %s\n" % (url, ex))
        sys.exit(1)


def change_registration_state(tenant, token, name, namespace, state, passport, tunnel_type):
    url = "https://%s.console.ves.volterra.io/api/register/namespaces/system/registration/%s/approve" % (
        tenant, name)
    headers = {
        "Authorization": "APIToken %s" % token
    }
    # OTHER STATE
    data = {
        "namespace": namespace,
        "name": name,
        "state": state,
    }
    # APPROVAL STATE
    if state == 2:
        data['passport'] = passport
        data['connected_region'] = ""
        data['tunnel_type'] = tunnel_type
    data = json.dumps(data)
    try:
        request = urllib.request.Request(
            url=url, headers=headers, data=bytes(data.encode('utf-8')), method='POST')
        urllib.request.urlopen(request)
        return True
    except Exception as ex:
        sys.stderr.write(
            "could not approve registration for %s : %s\n" % (url, ex))
        return False


def delete_registration(tenant, token, name, namespace):
    url = "https://%s.console.ves.volterra.io/api/register/namespaces/%s/registrations/%s" % (
        tenant, namespace, name)
    headers = {
        "Authorization": "APIToken %s" % token
    }
    data = {
        "fail_if_referred": False,
        "name": name,
        "namespace": namespace
    }
    data = json.dumps(data)
    try:
        request = urllib.request.Request(
            url=url, headers=headers, data=bytes(data.encode('utf-8')), method='DELETE')
        urllib.request.urlopen(request)
        return True
    except Exception as ex:
        sys.stderr.write(
            "could not delete registration for %s : %s\n" % (url, ex))
        return False


def is_site(site, tenant, token):
    url = "https://%s.console.ves.volterra.io/api/config/namespaces/system/sites/%s" % (
        tenant, site)
    headers = {
        "Authorization": "APIToken %s" % token
    }
    try:
        request = urllib.request.Request(
            url=url, headers=headers, method='GET')
        urllib.request.urlopen(request)
        return True
    except Exception as ex:
        sys.stderr.write(
            "could not get site %s : %s\n" % (url, ex))
        return False


def decomission_site(site, tenant, token):
    url = "https://%s.console.ves.volterra.io/api/register/namespaces/system/site/%s/state" % (
        tenant, site)
    headers = {
        "Authorization": "APIToken %s" % token
    }
    data = {
        "namespace": "system",
        "name": site,
        "state": "DECOMMISSIONING"
    }
    data = json.dumps(data)
    try:
        request = urllib.request.Request(
            url=url, headers=headers, data=bytes(data.encode('utf-8')), method='POST')
        urllib.request.urlopen(request)
    except Exception as ex:
        sys.stderr.write(
            "Can not delete site %s: %s\n" % (url, ex))
        sys.exit(1)


def main():
    ap = argparse.ArgumentParser(
        prog='site_registration_actions',
        usage='%(prog)s.py [options]',
        description='preforms Volterra API node registrations and site delete actions'
    )
    ap.add_argument(
        '--action',
        help='action to perform: [registernodes deleteregistrations sitedelete]',
        required=True
    )
    ap.add_argument(
        '--site',
        help='Volterra site name',
        required=True
    )
    ap.add_argument(
        '--tenant',
        help='Volterra site tenant',
        required=True
    )
    ap.add_argument(
        '--token',
        help='Volterra API token',
        required=True
    )
    ap.add_argument(
        '--ssl',
        help='Allow SSL tunnels',
        required=False,
        default='true'
    )
    ap.add_argument(
        '--ipsec',
        help='Allow SSL tunnels',
        required=False,
        default='true'
    )
    ap.add_argument(
        '--size',
        help='Node(s) in cluster to register',
        required=True,
        default=1,
        type=int
    )
    ap.add_argument(
        '--delay',
        help='seconds to delay before processing',
        required=False,
        default=0,
        type=int
    )
    ap.add_argument(
        '--nodes',
        help='comma separated list of nodes names to delete from Volterra',
        required=False,
        default='',
    )
    args = ap.parse_args()

    if args.action == "registernodes":
        if args.delay > 0:
            sys.stdout.write(
                "delaying polling for CE pending registrations for %d seconds..\n" % args.delay)
            sys.stdout.flush()
            time.sleep(args.delay)
        end_time = time.time() + PENDING_TIMEOUT
        counted_registrations = 0
        while (end_time - time.time()) > 0:
            registrations = get_registrations(
                args.site, args.tenant, args.token)
            if not registrations:
                sys.stdout.write(
                    "no registrations pending approval.. retrying in %d seconds.\n" % PENDING_WAIT)
                sys.stdout.flush()
                time.sleep(PENDING_WAIT)
            else:
                for reg in registrations:
                    if reg['object']['status']['current_state'] == "PENDING":
                        passport = reg['get_spec']['passport']
                        passport['tenant'] = reg['tenant']
                        passport['cluster_size'] = args.size
                        tunnel_type = 'SITE_TO_SITE_TUNNEL_IPSEC'
                        if args.ssl == 'true' and args.ipsec == 'true':
                            tunnel_type = 'SITE_TO_SITE_TUNNEL_IPSEC_OR_SSL'
                        elif args.ssl == 'true':
                            tunnel_type = 'SITE_TO_SITE_TUNNEL_SSL'
                        if change_registration_state(args.tenant, args.token, reg['name'], reg['namespace'], 2, passport, tunnel_type):
                            sys.stdout.write("approved registration %s for node %s\n" % (
                                reg['name'], reg['get_spec']['infra']['hostname']))
                            counted_registrations = counted_registrations + 1
                    elif reg['object']['status']['current_state'] in COUNT_REGISTRATION_STATES:
                        counted_registrations = counted_registrations + 1
                    if counted_registrations == args.size:
                        sys.exit(0)
        sys.stderr.write(
            "no registrations pending approval after %d seconds.. giving up.\n" % PENDING_TIMEOUT)
        sys.stdout.flush()

    if args.action == "deleteregistrations":
        counted_registrations = 0
        registrations = get_registrations(
            args.site, args.tenant, args.token)
        if not registrations:
            sys.stdout.write(
                "no registrations to delete.\n")
        else:
            nodes = args.nodes.split(',')
            for reg in registrations:
                if reg['get_spec']['infra']['hostname'] in nodes:
                    if reg['object']['status']['current_state'] in DECOMISSION_STATES:
                        change_registration_state(
                            args.tenant, args.token, reg['name'], reg['namespace'], 4, None, None)
                    elif reg['object']['status']['current_state'] in DELETE_STATES:
                        delete_registration(
                            args.tenant, args.token, reg['name'], reg['namespace'])

    if args.action == "sitedelete":
        if is_site(args.site, args.tenant, args.token):
            registrations = get_registrations(
                args.site, args.tenant, args.token)
            nodes = args.nodes.split(',')
            processed_registrations = []
            for reg in registrations:
                if reg['object']['status']['current_state'] in DECOMISSION_STATES:
                    if nodes and reg['get_spec']['infra']['hostname'] in nodes:
                        sys.stdout.write(
                            "decomissioning node registration for node %s\n" % reg['get_spec']['infra']['hostname'])
                        change_registration_state(
                            args.tenant, args.token, reg['name'], reg['namespace'], 4, None, None)
                        processed_registrations.append(reg['name'])
                    else:
                        sys.stdout.write(
                            "decomissioning node registration for node %s\n" % reg['get_spec']['infra']['hostname'])
                        change_registration_state(
                            args.tenant, args.token, reg['name'], reg['namespace'], 4, None, None)
                        processed_registrations.append(reg['name'])
                elif reg['object']['status']['current_state'] in DELETE_STATES:
                    if nodes and reg['get_spec']['infra']['hostname'] in nodes:
                        sys.stdout.write(
                            "deleting node registration for node %s\n" % reg['get_spec']['infra']['hostname'])
                        delete_registration(
                            args.tenant, args.token, reg['name'], reg['namespace'])
                        processed_registrations.append(reg['name'])
                    else:
                        sys.stdout.write(
                            "deleting node registration for node %s\n" % reg['get_spec']['infra']['hostname'])
                        delete_registration(
                            args.tenant, args.token, reg['name'], reg['namespace'])
                        processed_registrations.append(reg['name'])
            registrations = get_registrations(
                args.site, args.tenant, args.token)
            unprocessed_registations = 0
            for reg in registrations:
                if reg['name'] not in processed_registrations:
                    unprocessed_registations = unprocessed_registations + 1
            if unprocessed_registations == 0:
                decomission_site(args.site, args.tenant, args.token)
            else:
                sys.stdout.write(
                    "not decommissioning site because it has %d remaining nodes\n" % unprocessed_registations)
        else:
            sys.stdout.write("could not find site with name %s\n" % args.site)
    sys.exit(0)


if __name__ == '__main__':
    main()
