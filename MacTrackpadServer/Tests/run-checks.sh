#!/bin/sh
set -eu
SERVER_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
CHECK_BUILD_DIR=$(mktemp -d "${TMPDIR:-/tmp}/trackpad-server-checks.XXXXXX")
trap 'rm -rf "$CHECK_BUILD_DIR"' EXIT
xcrun swiftc -swift-version 5 \
  "$SERVER_ROOT/MacTrackpadServer/Modules/Networking/Models/TrackpadCommand.swift" \
  "$SERVER_ROOT/MacTrackpadServer/Modules/Networking/DTOs/TrackpadPacketDTO.swift" \
  "$SERVER_ROOT/MacTrackpadServer/Modules/Networking/Services/UDPServerService.swift" \
  "$SERVER_ROOT/Tests/Modules/Networking/ServerProtocolChecks.swift" \
  -o "$CHECK_BUILD_DIR/server-checks"
"$CHECK_BUILD_DIR/server-checks"
