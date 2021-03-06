SRC_DIR = src
BUILD_DIR = build

PREFIX = .
DIST_DIR = ${PREFIX}/dist

PLUGINS = $(shell ls -p ${SRC_DIR} | grep / | xargs)
PLUGINS_JS = $(if ${PLUGINS},$(shell find ${PLUGINS:%=${SRC_DIR}/%/} -name "*.js" 2> /dev/null),"")
PLUGINS_CSS = $(if ${PLUGINS},$(shell find ${PLUGINS:%=${SRC_DIR}/%/} -name "*.css" 2> /dev/null),"")

EXTRA_CSS = ${SRC_DIR}/styles.css\
	${SRC_DIR}/extra.css

JS_MODULES = ${SRC_DIR}/header.txt\
	${SRC_DIR}/intro.js\
	${SRC_DIR}/core.js\
	${PLUGINS_JS}\
	${SRC_DIR}/outro.js

CSS_MODULES = ${SRC_DIR}/header.txt\
	${SRC_DIR}/core.css\
	${PLUGINS_CSS}\
	${EXTRA_CSS}

QTIP = ${DIST_DIR}/jquery.qtip.js
QTIP_MIN = ${DIST_DIR}/jquery.qtip.min.js
QTIP_CSS = ${DIST_DIR}/jquery.qtip.css
QTIP_CSS_MIN = ${DIST_DIR}/jquery.qtip.min.css

QTIP_VER = `cat version.txt`
VER = sed s/@VERSION/${QTIP_VER}/

JS_ENGINE = `which node`
JS_LINT = ${JS_ENGINE} $(BUILD_DIR)/jslint-check.js
JS_MINIFIER = ${JS_ENGINE} ${BUILD_DIR}/uglify.js 
CSS_MINIFIER = java -Xmx96m -jar ${BUILD_DIR}/yuicompressor.jar

DATE=`git log --pretty=format:'%ad' -1`

all: clean qtip lint css min
	@@printf "\n%s" ${PLUGIN_JS}
	@@printf "qTip2 built successfully!\n\n"

${DIST_DIR}:
	@@mkdir -p ${DIST_DIR}

qtip: ${DIST_DIR} ${JS_MODULES}
	@@mkdir -p ${DIST_DIR}

	@@printf "Building qTip2... Success!\n"
	@@printf "\tEnabled plugins: %s\n\n" $(if ${PLUGINS},"${PLUGINS:%/=%}", "None")

	@@cat ${JS_MODULES} | \
		sed 's/Date:./&'"${DATE}"'/' | \
		${VER} > ${QTIP};

css: ${DIST_DIR} ${CSS_MODULES}
	@@printf "Building CSS... "
	@@cat ${CSS_MODULES} | \
		sed 's/Date:./&'"${DATE}"'/' | \
		${VER} > ${QTIP_CSS};
	@@printf "Success!\n"

min: qtip css
	@@if test ! -z ${JS_ENGINE}; then \
		printf "Minifying JS... "; \
		head -18 ${QTIP} > ${QTIP_MIN}; \
		${JS_MINIFIER} ${QTIP} > ${QTIP_MIN}.tmp; \
		sed '$ s#^\( \*/\)\(.\+\)#\1\n\2;#' ${QTIP_MIN}.tmp > ${QTIP_MIN}; \
		rm -rf $(QTIP_MIN).tmp; \
		printf "Success!\n"; \
	else \
		printf "You must have NodeJS installed in order to minify qTip JS.\n"; \
	fi

	@@printf "Minifying CSS... "
	@@${CSS_MINIFIER} ${QTIP_CSS} --type css -o ${QTIP_CSS_MIN}
	@@printf "Success!\n"

lint: qtip
	@@if test ! -z ${JS_ENGINE}; then \
		printf "Checking against JSLint... "; \
		${JS_LINT}; \
	else \
		printf "You must have NodeJS installed in order to test qTip against JSLint."; \
	fi

clean:
	@@printf "Removing distribution directory: %s\n\n" ${DIST_DIR}
	@@rm -rf ${DIST_DIR}
