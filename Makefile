.PHONY: all docker

DOCS=$(docs/**.md)

all: docker

docker:
	docker build -t snikket -f docker/Dockerfile .

site: mkdocs.yml $(DOCS)
	echo $(DOCS)
	mkdocs

docs/_po/snikket-server-docs.pot: po4a.conf $(DOCS)
	po4a \
	  --package-name snikket-server \
	  --package-version vcs \
	  --copyright-holder "Snikket Team <team@snikket.org>" \
	  po4a.conf
