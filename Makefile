all: build-release

build-debug:
	swift build -c debug

build-release:
	swift build -c release

build-no-warn:
	swift build -Xswiftc -suppress-warnings

run-debug:
	swift run -c debug -- -p 5000 ${RMUD_EXTRA_PARAMS} 2>&1 | tee rmud.log

run-release:
	swift run -c release -- -p 5000 ${RMUD_EXTRA_PARAMS} 2>&1 | tee rmud.log

clean:
	swift package clean

tags:
	ctags -R . ../swift-corelibs-foundation

.PHONY: all build run clean tags
