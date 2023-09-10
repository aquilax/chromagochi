SRC_DIR = ./src
TEMPDIR = ./temp
BUILD_DIR = ./build
EXT_DIR = $(BUILD_DIR)/ext
JS_DIR = $(BUILD_DIR)/js
BUILD_IMAGES = $(BUILD_DIR)/images
VERSION := $(shell jq -r .version manifest.json)
resolutions := 16 19 48 128
ALL_ICONS := $(foreach resolution, $(resolutions), $(BUILD_IMAGES)/icon$(resolution).png)


.PHONY: all
all: clean copy
	cd $(EXT_DIR); zip -r ../chromagochi-$(VERSION).zip *; cd ..

$(JS_DIR)/background.js: $(SRC_DIR)/background.coffee
	coffee -o $@ $<

$(EXT_DIR):
	mkdir -p $(EXT_DIR)

$(JS_DIR):
	mkdir -p $(JS_DIR)

$(BUILD_IMAGES):
	mkdir -p $(BUILD_IMAGES)

$(BUILD_IMAGES)/icon%.png: ./raw/Machovka_rabbit.svg
	inkscape $< -w $* -h $* --export-png=$@

.PHONY: copy
copy: $(JS_DIR) $(JS_DIR)/background.js $(BUILD_IMAGES) $(ALL_ICONS)
	mkdir -p $(EXT_DIR)/assets/js
	mkdir -p $(EXT_DIR)/assets/img
	cp manifest.json $(EXT_DIR)
	cp $(JS_DIR)/*.js $(EXT_DIR)/assets/js
	cp $(BUILD_IMAGES)/* $(EXT_DIR)/assets/img

.PHONY: clean
clean:
	rm -rf $(EXT_DIR)/*

