all: build-release

build-debug:
	swift build -c debug --product rmud

build-release:
	swift build -c release --product rmud

build-no-warn:
	swift build -Xswiftc -suppress-warnings

run-debug:
	swift run -c debug rmud ${RMUD_EXTRA_FLAGS} 2>&1 | tee rmud.log

run-release:
	swift run -c release rmud ${RMUD_EXTRA_FLAGS} 2>&1 | tee rmud.log

clean:
	swift package clean

tags:
	ctags -R . ../swift-corelibs-foundation

.PHONY: all build run clean tags
