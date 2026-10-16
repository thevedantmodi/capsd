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

# Installs launch agents so the remap and capsd start at login
agents:
	mkdir -p $(AGENTS)
	cp launchd/com.local.capsremap.plist $(AGENTS)/
	sed "s|__HOME__|$(HOME)|g" launchd/com.local.capsd.plist > $(AGENTS)/com.local.capsd.plist
	-launchctl bootstrap $(GUI) $(AGENTS)/com.local.capsremap.plist
	-launchctl bootstrap $(GUI) $(AGENTS)/com.local.capsd.plist

restart:
	launchctl kickstart -k $(GUI)/com.local.capsd

uninstall:
	-launchctl bootout $(GUI)/com.local.capsd
	-launchctl bootout $(GUI)/com.local.capsremap
	rm -f $(AGENTS)/com.local.capsd.plist $(AGENTS)/com.local.capsremap.plist $(BIN)
	hidutil property --set '{"UserKeyMapping":[]}'
