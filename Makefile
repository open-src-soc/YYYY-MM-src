# Silently include variables overwites.
sinclude local-config.mak

# CONSTANTS SETTING SECTION

## The current "RISC-V Week" edition is anonymous.
RISCV_WEEK?=YYYY-MM

## The public web site repo. URL
SITE_GIT=git@github.com:open-src-soc/$(RISCV_WEEK).git

## The directories involved in producing the site content: SITE_SRC is
## where the web site's source files lives. SITE_PUB is the root of
## the public web site files, i.e. what is actually published
## online. SITE_TMP is where the site is generated by Haskyll, first
## for off line checking through a local ad-hoc Haskyll web sierver,
## then as the base of the final rsync to SITE_DIR. SITE_TMP a
## temporary directory and is not versioned by Git -- see .gitignore.
SITE_PUB:=$(shell pwd)/site.pub
SITE_TMP:=$(shell pwd)/site.tmp
SITE_SRC:=$(shell pwd)/site.src

HAKYLL_DIR=$(shell pwd)/hakyll
HAKYLL_BIN=$(shell pwd)/hakyll/.stack-work
HAKYLL_TMP=$(shell pwd)/cache.tmp

## Better use the same branches for source code and published web
## pages.
SOURCE_BRANCH=master
ONLINE_BRANCH=master

## The files and directories that shall be removed when cleaning the
## local repo. Making clobber will include making clean.
CLEAN_LIST+=*~
CLEAN_LIST+=*/*~
CLEAN_LIST+=*/*/*~
CLEAN_LIST+=$(SITE_TMP)
CLOBBER_LIST+=$(SITE_PUB)
CLOBBER_LIST+=$(HAKYLL_TMP)
CLOBBER_LIST+=$(HAKYLL_BIN)
CLOBBER_LIST+=stack.yaml.lock


# MANAGEMENT OF REMOTES and BRANCHES

## We pull only from 'origin'. Others remotes are considered backup
## and therefore we never pull from them automatically.
REMOTE_PULL:=origin

## We push into all remotes: 'origin' as well as backups remotes.
REMOTE_PUSH:=$(shell git remote)

## We automate pushing and pulling only for branches 'master' and
## 'gh-pages'. Others branches, if any, must be managed manually.
BRANCHES+=master
BRANCHES+=gh-pages


# SHELL OUTPUT COLORING HACKERY.

## Color commands
TPUT_RED:=$(shell tput setaf 1)
TPUT_GRN:=$(shell tput setaf 2)
TPUT_NRM:=$(shell tput sgr0)

## Echo $(2) in color $(1), and execute $(2).
COLOR_AND_EXEC=echo "$(1)$(2)$(TPUT_NRM)" ; $2 ;


# HAKYLL WIZARDRY SECTION

## To build stack. Whatever that means...
.PHONY: stack-build
stack-build:
	( cd $(HAKYLL_DIR) && stack build )

## To rebuild the Hakyll site compiler, and compile the site anew in
## $(SOURCE_TEMP_DIR).
.PHONY: rebuild-site
rebuild-site: stack-build
	( cd $(HAKYLL_DIR) && stack exec site -- rebuild )

## To compile the site in $(SOURCE_TEMP_DIR) with the current Hakyll
## site compiler.
.PHONY: compile-site
compile-site: stack-build
	( cd $(HAKYLL_DIR) && stack exec site -- build )

## To launch a local web server at http://127.0.0.1:8000 and help
## debug the site's contents.
.PHONY: watch-site
watch-site: stack-build
	( cd $(HAKYLL_DIR) && stack exec site -- watch )


# Public web repo. management.

## Clone properly the Github repo. that carries the whole web site.
.PHONY: clone-pub
clone-pub:
	git clone $(SITE_GIT) $(SITE_PUB)
	( cd $(SITE_PUB) && git checkout gh-pages )

# Housekeeping

## Clean-up of the local repo.
.PHONY: clean
clean:
	rm -rf $(CLEAN_LIST)

.PHONY: clobber
clobber: clean
	rm -rf $(CLOBBER_LIST)

## Do a proper 'git pull' and that includes submodules as well.
.PHONY: pull-all
pull-all:
	@$(foreach r,$(REMOTE_PULL),$(foreach b,$(BRANCHES),$(call COLOR_AND_EXEC,$(TPUT_RED),git pull --recurse-submodules $r $b)))

## Push branches of the source repo to all remotes.
.PHONY: push-all
push-all:
	@$(foreach r,$(REMOTE_PUSH),$(foreach b,$(BRANCHES),$(call COLOR_AND_EXEC,$(TPUT_GRN),git push --recurse-submodules=on-demand $r $b)))
	@$(foreach r,$(REMOTE_PUSH),$(foreach b,$(BRANCHES),$(call COLOR_AND_EXEC,$(TPUT_GRN),git push --recurse-submodules=on-demand --tags $r $b)))

## Dump all variables for debug.
.PHONY: variables
variables: \
	_print_RISCV_WEEK \
	_print_SITE_GIT \
	_print_SITE_SRC \
	_print_SITE_TMP \
	_print_SITE_PUB\
	_print_HAKYLL_DIR \
	_print_HAKYLL_BIN \
	_print_HAKYLL_TMP \
	_print_SOURCE_BRANCH \
	_print_ONLINE_BRANCH \
	_print_CLEAN_LIST \
	_print_CLOBBER_LIST \

_print_%:
	@/bin/echo '$*=$($*)'
