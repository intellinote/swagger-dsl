#-------------------------------------------------------------------------------
# NOTE: Try `make help` for a list of popular targets
#-------------------------------------------------------------------------------

# CONFIGURATION
################################################################################

# COFFEE & NODE ################################################################
COFFEE_EXE ?= ./node_modules/.bin/coffee
NODE_EXE ?= node
COFFEE_COMPILE ?= $(COFFEE_EXE) -c
COFFEE_COMPILE_ARGS ?=
COFFEE_SRCS ?= $(wildcard lib/*.coffee *.coffee)
COFFEE_TEST_SRCS ?= $(wildcard test/*.coffee)
COFFEE_JS ?= ${COFFEE_SRCS:.coffee=.js}
COFFEE_TEST_JS ?= ${COFFEE_TEST_SRCS:.coffee=.js}

# NPM ##########################################################################
NPM_EXE ?= npm
PACKAGE_JSON ?= package.json
NODE_MODULES ?= node_modules
MODULE_DIR ?= module
NPM_ARGS ?= --silent

# PACKAGING ####################################################################
PACKAGE_VERSION ?= $(shell $(NODE_EXE) -e "console.log(require('./$(PACKAGE_JSON)').version)")
PACKAGE_NAME ?= $(shell $(NODE_EXE) -e "console.log(require('./$(PACKAGE_JSON)').name)")
TMP_PACKAGE_DIR ?= packaging-$(PACKAGE_NAME)-v$(PACKAGE_VERSION)-tmp
PACKAGE_DIR ?= $(PACKAGE_NAME)-$(PACKAGE_VERSION)

# MOCHA ########################################################################
MOCHA_EXE ?= ./node_modules/.bin/mocha
TEST ?= $(wildcard test/test-*.coffee)
MOCHA_TESTS ?= $(TEST)
MOCHA_TEST_PATTERN ?=
MOCHA_TIMEOUT ?=-t 2000
MOCHA_TEST_ARGS  ?= -R list --compilers coffee:coffee-script/register $(MOCHA_TIMEOUT) $(MOCHA_TEST_PATTERN)
MOCHA_EXTRA_ARGS ?=

# COVERAGE #####################################################################
LIB ?= lib
LIB_COV ?= lib-cov
COVERAGE_REPORT ?= docs/coverage.html
COVERAGE_TMP_DIR ?=  ./cov-tmp
COVERAGE_EXE ?= ./node_modules/.bin/coffeeCoverage
COVERAGE_ARGS ?= -e migration --initfile $(LIB_COV)/coffee-coverage-init.js
MOCHA_COV_ARGS  ?= --require $(LIB_COV)/coffee-coverage-init.js --globals "_\$$jscoverage" --compilers coffee:coffee-script/register -R html-cov -t 20000

# MARKDOWN #####################################################################
MARKDOWN_TOC ?= ./node_modules/.bin/toc
MARKDOWN_SRCS ?= $(shell find . -type f -name '*.md' | grep -v node_modules | grep -v module)
MARKDOWN_TOCED ?= ${MARKDOWN_SRCS:.md=.md-toc}
MARKDOWN_PROCESSOR ?= node -e "var h=require('highlight.js'),m=require('marked'),c='';process.stdin.on('data',function(b){c+=b.toString();});process.stdin.on('end',function(){m.setOptions({gfm:true,highlight:function(x,l){if(l){return h.highlight(l,x).value;}else{return x;}}});console.log(m(c))});process.stdin.resume();"
MARKDOWN_HTML ?= ${MARKDOWN_TOCED:.md-toc=.html}
MARKDOWN_PREFIX ?= "<html><head><style>`cat docs/styles/markdown.css`</style><body>"
MARKDOWN_SUFFIX ?= "</body></html>"
LITCOFFEE_PROCESSOR ?= node -e "var h=require('highlight.js'),m=require('marked'),c='';process.stdin.on('data',function(b){c+=b.toString();});process.stdin.on('end',function(){m.setOptions({gfm:true,highlight:function(x){return h.highlight('coffee',x).value;}});console.log(m(c))});process.stdin.resume();"
LITCOFFEE_SRCS ?= $(shell find . -type f -name '*.litcoffee' | grep -v node_modules | grep -v module)
LITCOFFEE_HTML ?= ${LITCOFFEE_SRCS:.litcoffee=.html}
LITCOFFEE_TOCED ?= ${LITCOFFEE_SRCS:.litcoffee=.md-toc}

# OTHER ########################################################################
DOCCO_EXE ?= ./node_modules/.bin/docco

################################################################################
# META-TARGETS AND SIMILAR

# `.SUFFIXES` - reset suffixes in case any were previously defined
.SUFFIXES:

# `.PHONY` - make targets that aren't actually files
.PHONY: all coffee clean clean-coverage clean-docco clean-docs clean-js clean-markdown clean-module clean-node-modules clean-test-module-install coverage docco docs fully-clean-node-modules js markdown module targets test test-module-install todo

# `all` - the default target
all: help

# `targets` - list targets that are not likely to be "meta" targets like .PHONY or .SUFFIXES
targets:
	@grep -E "^[^ #.$$]+:( |$$)" Makefile | sort | cut -d ":" -f 1

# `todo` - list todo and related comments found in source files
todo:
	@grep -C 0 --exclude-dir=node_modules --exclude-dir=.git --exclude=#*# --exclude=.#* --exclude=*.html  --exclude=Makefile  -IrHE "(TODO)|(FIXME)|(XXX)" *


# `FIND-CHANGE-ME` - list the `CHANGE-ME` markers that indicate places where the repository template needs to be modified when creating a new project
FIND-CHANGE-ME:
	@grep -C 0 --exclude-dir=node_modules --exclude-dir=.git --exclude=#*# --exclude=.#* --exclude=*.html -IrHE "\-[C]HANGE-ME-" *

# @echo " test-module-install - generate an npm module and validate it"
help:
	@echo ""
	@echo "--------------------------------------------------------------------------------"
	@echo "HERE ARE SOME POPULAR AND USEFUL TARGETS IN THIS MAKEFILE."
	@echo "--------------------------------------------------------------------------------"
	@echo ""
	@echo "SET UP"
	@echo " install      - install npm dependencies (i.e., 'npm install')"
	@echo "                (also aliased as 'npm' and 'node_modules')"
	@echo ""
	@echo "AUTOMATED TESTS"
	@echo " test         - run the unit-test suite"
	@echo " coverage     - generate a unit-test coverage report"
	@echo ""
	@echo "DOCUMENTATION"
	@echo " markdown     - generate HTML versions of various *.md and *.litcoffee files"
	@echo " docco        - generate annotated source code view using docco"
	@echo " docs         - generate all of the above"
	@echo ""
	@echo "BUILD"
	@echo " js           - generate JavaScript files from CoffeeScript files"
	@echo " module       - create a packaged npm module for deployment"
	@echo " test-module-install"
	@echo "              - create a packaged npm module for deployment and then"
	@echo "                validate that the module can be installed"
	@echo ""
	@echo "CLEAN UP"
	@echo " clean        - remove generated files and directories (except node_modules)"
	@echo " really-clean - truly remove all generated files and directories"
	@echo ""
	@echo "OTHER"
	@echo " todo         - search source code for TODO items"
	@echo " targets      - generate a list of most available make targets"
	@echo " help         - this listing"
	@echo ""
	@echo "--------------------------------------------------------------------------------"
	@echo ""

################################################################################
# CLEAN UP TARGETS

clean: clean-coverage clean-docco clean-docs clean-js clean-module clean-test-module-install clean-node-modules clean-bin

clean-test-module-install:
	rm -rf ../testing-module-install

clean-module:
	rm -rf $(MODULE_DIR)
	rm -rf $(PACKAGE_DIR)
	rm -rf $(PACKAGE_DIR).tgz

clean-node-modules:
	$(NPM_EXE) $(NPM_ARGS) prune &

really-clean: clean really-clean-node-modules

really-clean-node-modules: # deletes rather that simply pruning node_modules
	rm -rf $(NODE_MODULES)

clean-js:
	rm -f $(COFFEE_JS) $(COFFEE_TEST_JS)

clean-coverage:
	rm -rf $(JSCOVERAGE_TMP_DIR)
	rm -rf $(LIB_COV)
	rm -f $(COVERAGE_REPORT)
	(rmdir --ignore-fail-on-non-empty docs) || true

clean-docs: clean-markdown clean-docco

clean-docco:
	rm -rf docs/docco
	(rmdir --ignore-fail-on-non-empty docs) || true

clean-markdown:
	rm -rf $(MARKDOWN_HTML)
	rm -rf $(LITCOFFEE_HTML)
	(rmdir --ignore-fail-on-non-empty docs) || true

################################################################################
# NPM TARGETS

# TODO - confirm that all JSON files in config directory are valid when packaging

module: js bin test docs coverage
	mkdir -p $(MODULE_DIR)
	cp $(PACKAGE_JSON) $(MODULE_DIR)
	cp -r bin $(MODULE_DIR)
	cp -r lib $(MODULE_DIR)
	cp *.txt $(MODULE_DIR)
	cp README.md $(MODULE_DIR)
	mv module $(PACKAGE_DIR)
	tar -czf $(PACKAGE_DIR).tgz $(PACKAGE_DIR)

test-module-install: clean-test-module-install js test docs coverage module
	mkdir ../testing-module-install; cd ../testing-module-install; npm install "$(CURDIR)/$(PACKAGE_DIR).tgz"; node -e "require('assert').ok(require('swagger-dsl'));" && ./node_modules/.bin/swagger-dsl --help && cd $(CURDIR) && rm -rf ../testing-module-install && echo "\n\n\n<<<<<<< It worked! >>>>>>\n\n\n"

$(NODE_MODULES): $(PACKAGE_JSON)
	$(NPM_EXE) $(NPM_ARGS) prune
	$(NPM_EXE) $(NPM_ARGS) install
	touch $(NODE_MODULES) # touch the module dir so it looks younger than `package.json`

npm: $(NODE_MODULES) # an alias
install: $(NODE_MODULES) # an alias

################################################################################
# COFFEE TARGETS

coffee: $(NODE_MODULES)
	rm -rf $(LIB_COV)

js: coffee $(COFFEE_JS) $(COFFEE_TEST_JS)

.SUFFIXES: .js .coffee
.coffee.js:
	$(COFFEE_COMPILE) $(COFFEE_COMPILE_ARGS) $<
$(COFFEE_JS_OBJ): $(NODE_MODULES) $(COFFEE_SRCS) $(COFFEE_TEST_SRCS)

coffee-bin:
	$(foreach f,$(shell ls ./lib/swagger-dsl.coffee 2>/dev/null),chmod a+x "$(f)" && cp bin/.shebang.sh "bin/`basename $(f) | sed 's/.......$$//'`";)

bin: coffee-bin

clean-bin:
	$(foreach f,$(shell ls ./lib/swagger-dsl.coffee 2>/dev/null),rm -rf "bin/`basename $(f) | sed 's/.......$$//'`";)

################################################################################
# TEST TARGETS

test: $(MOCHA_TESTS) $(NODE_MODULES)
	$(MOCHA_EXE) $(MOCHA_TEST_ARGS) ${MOCHA_EXTRA_ARGS} $(MOCHA_TESTS)

test-watch: $(MOCHA_TESTS) $(NODE_MODULES)
	$(MOCHA_EXE) --watch $(MOCHA_TEST_ARGS) ${MOCHA_EXTRA_ARGS} $(MOCHA_TESTS)

coverage: $(COFFEE_SRCS) $(COFFEE_TEST_SRCS) $(MOCHA_TESTS) $(NODE_MODULES)
	rm -rf $(COVERAGE_TMP_DIR)
	rm -rf $(LIB_COV)
	mkdir -p $(COVERAGE_TMP_DIR)
	cp -r $(LIB)/* $(COVERAGE_TMP_DIR)/.
	$(COVERAGE_EXE) $(COVERAGE_ARGS) $(COVERAGE_TMP_DIR) $(LIB_COV)
	mkdir -p `dirname $(COVERAGE_REPORT)`
	$(MOCHA_EXE) $(MOCHA_COV_ARGS) $(MOCHA_TESTS) > $(COVERAGE_REPORT)
	rm -rf $(COVERAGE_TMP_DIR)
	rm -rf $(LIB_COV)

################################################################################
# MARKDOWN & OTHER DOC TARGETS

docs: markdown docco

.SUFFIXES: .md-toc .md
.md.md-toc:
	cp "$<" "$@"
	$(MARKDOWN_TOC) "$@"
$(MARKDOWN_TOCCED_OBJ): $(MARKDOWN_SRCS)

# (echo $(MARKDOWN_PREFIX) > $@) && ($(MARKDOWN_PROCESSOR) $(MARKDOWN_PROCESSOR_ARGS) $< | sed "s/<!-- toc -->/<div id=TofC>/"  | sed "s/<!-- toc stop -->/<\/div>/" >> $@) && (echo $(MARKDOWN_SUFFIX) >> $@)
.SUFFIXES: .html .md-toc
.md-toc.html:
	(echo $(MARKDOWN_PREFIX) > $@) && (cat "$<" | $(MARKDOWN_PROCESSOR) | sed "s/<!-- toc -->/<div id=TofC>/"  | sed "s/<!-- toc stop -->/<div style=\"font-size: 0.9em; text-align: right\"><a href=\".\" >[up]<\/a> <a href=\"javascript:back(-1)\">[back]<\/a><\/div><\/div>/" >> $@) && (echo $(MARKDOWN_SUFFIX) >> $@)
$(MARKDOWN_HTML_OBJ): $(MARKDOWN_TOCCED_OBJ)

.SUFFIXES: .litcoffee-toc .litcoffee
.litcoffee.litcoffee-toc:
	cp "$<" "$@"
	$(MARKDOWN_TOC) "$@"
$(LITCOFFEE_TOCCED_OBJ): $(LITCOFFEE_SRCS)

.SUFFIXES: .html .litcoffee-toc
.litcoffee-toc.html:
	 (echo $(MARKDOWN_PREFIX) > $@) && (cat "$<" | $(LITCOFFEE_PROCESSOR) | sed "s/<!-- toc -->/<div id=TofC>/"  | sed "s/<!-- toc stop -->/<div style=\"font-size: 0.9em; text-align: right\"><a href=\".\" >[up]<\/a> <a href=\"javascript:back(-1)\">[back]<\/a><\/div><\/div>/" >> $@) && (echo $(MARKDOWN_SUFFIX) >> $@)
 $(LITCOFFEE_HTML_OBJ): $(LITCOFFEE_TOCCED_OBJ)  docs/styles/markdown.css

$(MARKDOWN_HTML): docs/styles/markdown.css
$(LITCOFFEE_HTML): docs/styles/markdown.css
markdown: $(MARKDOWN_HTML) $(LITCOFFEE_HTML) $(NODE_MODULES)

html: markdown

docco: $(COFFEE_SRCS) $(NODE_MODULES)
	rm -rf docs/docco
	mkdir -p docs
	mv docs docs-temporarily-renamed-so-docco-doesnt-clobber-it
	$(DOCCO_EXE) $(COFFEE_SRCS)
	mv docs docs-temporarily-renamed-so-docco-doesnt-clobber-it/docco
	mv docs-temporarily-renamed-so-docco-doesnt-clobber-it docs

.SUFFIXES: .coffee
.coffee:
	$(COFFEE_EXE) $< >  $@
