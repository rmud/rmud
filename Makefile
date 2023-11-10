all: build-release

build-debug:
	swift build -c debug

build-release:
	swift build -c release

build-no-warn:
	swift build -Xswiftc -suppress-warnings

run-debug:
	swift build -c debug
	swift run -c debug rmud -p 5000 ${RMUD_EXTRA_PARAMS} 2>&1 | tee rmud.log

run-release:
	swift build -c release
	swift run -c release rmud -p 5000 ${RMUD_EXTRA_PARAMS} 2>&1 | tee rmud.log

clean:
	swift package clean

tags:
	ctags -R . ../swift-corelibs-foundation

.PHONY: all build run clean tags
