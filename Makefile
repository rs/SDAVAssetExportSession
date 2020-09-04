build:
	swift build

release: clean
	swift build --configuration=release --build-path ./Release

clean:
	rm -rf ./.build
