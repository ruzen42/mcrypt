# mcrypt

A simple liboqs + BLAKE3 keys manager implementation written in Haskell.

> **Warning**
> This project is intended for learning and experimentation. It is **not** suitable for protecting real-world data.

## Features

- Dilithium3 key generation
- Public/private key encryption primitives
- Binary key serialization
- Stores keys in `~/.mcrypt`
- Docker image

## Installation

### 'By hand' way
```sh
git clone https://github.com/ruzen42/mcrypt.git
cd mcrypt

cabal build
cabal install
```

or

```sh
stack build
stack install
```

### Via docker image

```sh
docker run ruzen42/mcrypt:latest #or specific tag 
```

## Usage

Generate a new key pair:

```sh
mkey --new main
```

Show an existing public key:

```sh
mkey --get main
```

List all stored keys:

```sh
mkey --list
```

Delete a key:

```sh
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
