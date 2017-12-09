BUILDDIR = ./build
TEMPDIR = ./temp

all: clean copy
	cd $(TEMPDIR); zip -r ../$(BUILDDIR)/chromagochi.zip *; cd ..

copy:
	mkdir $(TEMPDIR)/assets
	mkdir $(TEMPDIR)/assets/js
	mkdir $(TEMPDIR)/assets/img
	cp manifest.json $(TEMPDIR)
	cp assets/js/*.js $(TEMPDIR)/assets/js
	cp assets/img/* $(TEMPDIR)/assets/img

clean:
	rm -rf $(TEMPDIR)/*
	rm -rf $(BUILDDIR)/*
