# Aero-packages

Official ecosystem package registry for the [Aero] programming language.
Every package here can be installed into your project with one command:

```bash
aero install <name>
```

## Install a package

Run inside your project root (the folder containing `Aero.toml`):

```bash
aero install aero-base64      # exact match
aero install aero-json        # installs recursively with its dependencies
aero install                  # interactive picker
```

Installing fetches the package index (`packages.json`) from the latest GitHub
Release, verifies the SHA-256 checksum of every archive, extracts each package
into `deps/<name>/`, resolves the whole dependency tree recursively, and writes
the path dependency back into your `Aero.toml` `[dependencies]` table. FFI
packages bundle their static libraries, so no system toolchain is required.

## Available packages (51)

**Serialization** — base32 · base58 · base64 · bson · cbor · flatbuffers ·
hex · html-escape · json · msgpack · prost · ron · serde · serde-derive ·
serde-json · serde-toml · serde-yaml · toml · xml · yaml

**Networking & databases** — tcp (Winsock2 FFI) · http (HTTP/1.1) ·
web (Router / Extract / Middleware) · redis (RESP client) ·
postgres (PG v3 wire client) · sqlite (self-contained FFI driver)

**Text & data structures** — csv · glob · html · inflector · levenshtein ·
mime · punycode · regex · rope · slug · unicode · url

**Algorithms & containers** — bitset · bitvec · graph · lru · priority-queue ·
ring-buffer · skiplist · trie · union-find

**Utilities** — bench · cli · config · log

## Requirements

- Aero 1.2.0+ (`aero --version`), enforced via the `requires_aero` field.

## Development

Repackage all crates and regenerate `packages.json`:

```bash
./scripts/pack.sh v1.2.0
```

The script validates every crate's description, system-library declaration and
dependency tree before producing `dist/*.zip` + `dist/packages.json`.

## License

MIT — see [LICENSE](LICENSE).

[Aero]: https://github.com/SereinCin/Aero
