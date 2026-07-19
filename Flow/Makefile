APP_NAME = Flow
BUILD_DIR = build
APP_DIR = $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR = $(APP_DIR)/Contents
MACOS_DIR = $(CONTENTS_DIR)/MacOS
RESOURCES_DIR = $(CONTENTS_DIR)/Resources

SOURCES = Sources/main.m Sources/FLProject.m Sources/FLProjectStore.m Sources/FLApplicationController.m

all: $(MACOS_DIR)/$(APP_NAME)

test:
	mkdir -p $(BUILD_DIR)
	clang -framework Foundation -lsqlite3 -o $(BUILD_DIR)/StoreSmokeTest Tests/StoreSmokeTest.m Sources/FLProject.m Sources/FLProjectStore.m
	$(BUILD_DIR)/StoreSmokeTest

$(MACOS_DIR)/$(APP_NAME): $(SOURCES) Resources/AppIcon.icns
	mkdir -p $(MACOS_DIR)
	mkdir -p $(RESOURCES_DIR)
	clang -framework Cocoa -lsqlite3 -o $@ $(SOURCES)
	cp Resources/AppIcon.icns $(RESOURCES_DIR)/AppIcon.icns
	printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' '<plist version="1.0"><dict><key>CFBundleExecutable</key><string>Flow</string><key>CFBundleIdentifier</key><string>com.flowapp.Flow</string><key>CFBundleName</key><string>Flow</string><key>CFBundleIconFile</key><string>AppIcon</string><key>CFBundlePackageType</key><string>APPL</string></dict></plist>' > $(CONTENTS_DIR)/Info.plist

clean:
	rm -rf $(BUILD_DIR)
