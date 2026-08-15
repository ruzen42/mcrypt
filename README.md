# mcrypt

A simple liboqs + BLAKE3 keys manager implementation written in Haskell.

> **Warning**
> This project is intended for learning and experimentation. It is **not** suitable for protecting real-world data.

## Features

- Dilithium3 key generation
- Public/private key encryption primitives
- Binary key serialization
- Stores keys in `~/.mcrypt`

## Installation

```bash
git clone https://github.com/ruzen42/mcrypt.git
cd mcrypto

cabal build
cabal install
```

or

```bash
stack build
stack install
```

## Usage

Generate a new key pair:

```bash
mkey --new main
```

Show an existing public key:

```bash
mkey --get main
```

List all stored keys:

```bash
mkey --list
```

Delete a key:

```bash
mkey --delete main
```

## Directory Layout

Generated keys are stored inside the user's home directory.

```text
~/.mcrypt/
├── main/
│   ├── public
│   └── private
├── work/
│   ├── public
│   └── private
└── backup/
    ├── public
    └── private
```

## Current Implementation

- Dilithium3 + BLAKE3 file signing
- Binary key storage
- post kvantum safe

## Planned

- [ ] OAEP padding
- [ ] Digital signatures
- [ ] PEM export/import
- [ ] Fingerprints
- [ ] TPM2 support  
- [ ] Better CLI
- [ ] Benchmarks
- [ ] Tests

## Security Notice

This implementation is educational.

Do **not** use this project to protect sensitive information.

## License

MIT
