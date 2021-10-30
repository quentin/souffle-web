.phony: all

all: assets/Main.js

ELM=docker run --rm --user $(shell id -u) -v $(shell pwd):/opt/app -it elm

assets/Main.js: src/*.elm
	$(ELM) make src/Main.elm --output=assets/Main.js #--optimize

