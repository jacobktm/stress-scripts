#!/bin/bash

if ! ./s76setuptestpy.py; then
    cp pip/python.tar.xz ~/
    pushd ~/
        tar xvf python.tar.xz
        rm -rvf python.tar.xz
    popd
fi