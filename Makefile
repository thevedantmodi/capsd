BIN    := $(HOME)/bin/capsd
AGENTS := $(HOME)/Library/LaunchAgents
GUI    := gui/$(shell id -u)

.PHONY: build install remap agents restart uninstall

build:
	swiftc -O capsd.swift -o capsd

install: build
	mkdir -p $(HOME)/bin
	cp capsd $(BIN)

# Activates Caps Lock -> F18 for this session (resets on reboot)
remap:
	hidutil property --set '{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x70000006D}]}'

# Installs launch agents so the remap and capsd start at login.
# launchd refuses quarantined plists (error 5), and install keeps xattrs.
# bootstrap can defer the first spawn, so kickstart both afterwards.
agents:
	mkdir -p $(AGENTS)
	install -m 644 com.local.capsremap.plist $(AGENTS)/
	-xattr -d com.apple.quarantine $(AGENTS)/com.local.capsremap.plist 2>/dev/null
	sed "s|__HOME__|$(HOME)|g" com.local.capsd.plist > $(AGENTS)/com.local.capsd.plist
	-launchctl bootstrap $(GUI) $(AGENTS)/com.local.capsremap.plist
	-launchctl bootstrap $(GUI) $(AGENTS)/com.local.capsd.plist
	-launchctl kickstart $(GUI)/com.local.capsremap
	-launchctl kickstart $(GUI)/com.local.capsd

restart:
	launchctl kickstart -k $(GUI)/com.local.capsd

uninstall:
	-launchctl bootout $(GUI)/com.local.capsd
	-launchctl bootout $(GUI)/com.local.capsremap
	rm -f $(AGENTS)/com.local.capsd.plist $(AGENTS)/com.local.capsremap.plist $(BIN)
	hidutil property --set '{"UserKeyMapping":[]}'
