# SPDX-License-Identifier: LGPL-2.1-or-later
# Copyright © 2007-2018 ANSSI. All Rights Reserved.
PROGNAME := rm-session
PROGVER := 1.4.5
PKGNAME := ${PROGNAME}-${PROGVER}

PREFIX ?= /usr/local

export PROGNAME PROGVER PKGNAME PREFIX 

all:
	@echo "Nothing to do here, move along"

install:
	${foreach script, ${wildcard sessions/*}, install -D ${script} ${DESTDIR}${PREFIX}/bin/${notdir ${script}} ; }
	${foreach file, ${wildcard etc/*}, install -D ${file} ${DESTDIR}${PREFIX}/etc/${notdir ${file}} ; }
