.phony: run docker_run build build_souffle build_elm build_notebook

SOUFFLE_BIN := souffle

build: assets/Main.js

#ELM=docker run --rm --user $(shell id -u) -v $(shell pwd):/opt/app -it elm

build_souffle: souffle.dockerfile
	docker build --pull -t souffle -f souffle.dockerfile .

build_elm: elm.dockerfile
	docker build --pull -t elm -f elm.dockerfile .

build_notebook: build_souffle build_elm assets/* src/*
	docker build -t notebook .

docker_run: build_notebook
	docker run --rm -p 12000:12000 notebook

run: build
	./backend --souffle-bin ${SOUFFLE_BIN}

assets/Main.js: src/*.elm
	elm make src/Main.elm --output=assets/Main.js --optimize

