.phony: all

all: assets/Main.js

assets/Main.js: src/*.elm
	elm make src/Main.elm --output=assets/Main.js #--optimize

