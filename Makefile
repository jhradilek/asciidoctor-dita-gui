# A makefile for asciidoctor-dita-gui
# Copyright (C) 2024 Jaromir Hradilek

# MIT License
#
# Permission  is hereby granted,  free of charge,  to any person  obtaining
# a copy of  this software  and associated documentation files  (the "Soft-
# ware"),  to deal in the Software  without restriction,  including without
# limitation the rights to use,  copy, modify, merge,  publish, distribute,
# sublicense, and/or sell copies of the Software,  and to permit persons to
# whom the Software is furnished to do so,  subject to the following condi-
# tions:
#
# The above copyright notice  and this permission notice  shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS",  WITHOUT WARRANTY OF ANY KIND,  EXPRESS
# OR IMPLIED,  INCLUDING BUT NOT LIMITED TO  THE WARRANTIES OF MERCHANTABI-
# LITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT
# SHALL THE AUTHORS OR COPYRIGHT HOLDERS  BE LIABLE FOR ANY CLAIM,  DAMAGES
# OR OTHER LIABILITY,  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM,  OUT OF OR IN CONNECTION WITH  THE SOFTWARE  OR  THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

# General information:
NAME    = asciidoctor-dita-gui
VERSION = 0.1.0

# General settings:
SHELL   = /bin/sh

# Source files:
SRCS    = asciidoctor-dita-gui.sh
DOCS    = AUTHORS LICENSE README.md
MANS    = $(NAME).1

# Installation paths:
prefix  = /usr/local
bindir  = $(prefix)/bin
mandir  = $(prefix)/share/man/man1
docdir  = $(prefix)/share/doc/$(NAME)-$(VERSION)

# Command aliases:
INSTALL = /usr/bin/install -c
POD2MAN = /usr/bin/pod2man

# Define the default action:
.PHONY: all
all: $(MANS)

# Install the files to the system:
.PHONY: install
install: $(SRCS) $(DOCS) $(MANS)
	@echo "Preparing installation directories..."
	$(INSTALL) -d $(bindir)
	$(INSTALL) -d $(docdir)
	$(INSTALL) -d $(mandir)
	@echo "Copying executable files..."
	$(INSTALL) -m 755 $(SRCS) $(bindir)/$(NAME)
	@echo "Copying documentation files..."
	$(INSTALL) -m 644 $(DOCS) $(docdir)
	@echo "Copying manual pages..."
	$(INSTALL) -m 644 $(MANS) $(mandir)

# Uninstall the files from the system:
.PHONY: uninstall
uninstall:
	@echo "Removing executable files..."
	-rm -f $(bindir)/$(NAME)
	@echo "Removing documentation files..."
	-rm -f $(addprefix $(docdir)/,$(DOCS))
	@echo "Removing manual pages..."
	-rm -f $(addprefix $(mandir)/,$(MANS))
	@echo "Removing empty directories..."
	-rmdir $(bindir)
	-rmdir $(docdir)
	-rmdir $(mandir)

# Clean up generated files:
.PHONY: clean
clean:
	@echo "Removing generated files..."
	-rm -f $(MANS)

# Generate a man page from the source file:
%.1: %.sh
	$(POD2MAN) --section=1 --name="$(basename $^)" \
	                       --release="Version $(VERSION)" $^ $@
