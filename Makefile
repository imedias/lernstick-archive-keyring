TRUSTED-LIST := $(patsubst active-keys/add-%,trusted.gpg/lernstick-archive-%.gpg,$(wildcard active-keys/add-*))
TMPRING := trusted.gpg/build-area

GPG_OPTIONS := --no-options --no-default-keyring --no-auto-check-trustdb --trustdb-name ./trustdb.gpg

build: verify-indices keyrings/lernstick-archive-keyring.gpg keyrings/lernstick-archive-removed-keys.gpg verify-results $(TRUSTED-LIST)

verify-indices: keyrings/team-members.gpg
	gpg ${GPG_OPTIONS} \
		--keyring keyrings/team-members.gpg \
		--verify active-keys/index.gpg active-keys/index
	gpg ${GPG_OPTIONS} \
		--keyring keyrings/team-members.gpg \
		--verify removed-keys/index.gpg removed-keys/index

verify-results: keyrings/team-members.gpg keyrings/lernstick-archive-keyring.gpg keyrings/lernstick-archive-removed-keys.gpg
	gpg ${GPG_OPTIONS} \
		--keyring keyrings/team-members.gpg --verify \
		keyrings/lernstick-archive-keyring.gpg.asc \
		keyrings/lernstick-archive-keyring.gpg
	gpg ${GPG_OPTIONS} \
		--keyring keyrings/team-members.gpg --verify \
		keyrings/lernstick-archive-removed-keys.gpg.asc \
		keyrings/lernstick-archive-removed-keys.gpg
	#FIXME: Do we need to verify the created keyrings in trusted.gpg.d, too?
	#	Maybe "just" checking that no key is added if we merge, but how…

keyrings/lernstick-archive-keyring.gpg: active-keys/index
	jetring-build -I $@ active-keys

keyrings/lernstick-archive-removed-keys.gpg: removed-keys/index
	jetring-build -I $@ removed-keys

keyrings/team-members.gpg: team-members/index
	jetring-build -I $@ team-members

$(TRUSTED-LIST) :: trusted.gpg/lernstick-archive-%.gpg : active-keys/add-% active-keys/index
	mkdir -p $(TMPRING) trusted.gpg
	grep -F $(shell basename $<) -- active-keys/index > $(TMPRING)/index
	cp $< $(TMPRING)
	jetring-build -I $@ $(TMPRING)
	rm -rf $(TMPRING)

clean:
	rm -f keyrings/lernstick-archive-keyring.gpg \
		keyrings/lernstick-archive-keyring.gpg~ \
		keyrings/lernstick-archive-keyring.gpg.lastchangeset
	rm -f keyrings/lernstick-archive-removed-keys.gpg \
		keyrings/lernstick-archive-removed-keys.gpg~ \
		keyrings/lernstick-archive-removed-keys.gpg.lastchangeset
	rm -f keyrings/team-members.gpg \
		keyrings/team-members.gpg~ \
		keyrings/team-members.gpg.lastchangeset
	rm -rf $(TMPRING) trusted.gpg trustdb.gpg
	rm -f keyrings/*.cache

install: build
	install -d $(DESTDIR)/usr/share/keyrings/
	cp keyrings/lernstick-archive-keyring.gpg $(DESTDIR)/usr/share/keyrings/
	cp keyrings/lernstick-archive-removed-keys.gpg $(DESTDIR)/usr/share/keyrings/
	install -d $(DESTDIR)/etc/apt/trusted.gpg.d/
	cp $(shell find trusted.gpg/ -name '*.gpg' -type f) $(DESTDIR)/etc/apt/trusted.gpg.d/

.PHONY: verify-indices verify-results clean build install
