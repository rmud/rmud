all: build

build:
	swift build

run:
	swift build -c debug
	swift run -c debug rmud -p 5000 ${RMUD_SWIFT_TEST_EXTRA_PARAMS} 2>&1 | tee rmud.log

clean:
	swift package clean

tags:
	ctags -R . ../swift-corelibs-foundation

.PHONY: all build run clean tags
