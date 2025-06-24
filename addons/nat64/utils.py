#!/usr/bin/env python3
# microk8s/addons/nat64/utils.py
import os
import click

def NeedsRoot():
    """Require we run the script as root (sudo)."""
    if os.geteuid() != 0:
        click.echo("Elevated permissions are needed for this addon.", err=True)
        click.echo("Please try again, this time using 'sudo'.", err=True)
        exit(1)
