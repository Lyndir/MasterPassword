build: mkdir-es5 es5/mpw-js/pbkdf2.js es5/mpw-js/scrypt.js es5/mpw-js/mpw.js es5/setImmediate-polyfill.js

mkdir-es5:
	mkdir -p es5
	mkdir -p es5/mpw-js

es5/%: $*
	babel $* -o $@ --presets es2015 --source-maps

clean:
	rm -rf es5 2>/dev/null

update:
	git submodule update --init --recursive
	git submodule foreach git pull origin master
