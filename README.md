# mrun-crypt

A minimal RSA implementation written in Haskell.

> **Warning**
> This project is intended for learning and experimentation. It is **not** suitable for protecting real-world data.

## Features

- Pure Haskell implementation
- RSA key generation
- Public/private key encryption primitives
- Binary key serialization
- Stores keys in `~/.mcrypt`
- No external cryptography libraries

## Installation

```bash
git clone https://github.com/ruzen42/mcrypto.git
cd mcrypto

cabal build # or stack
```

or

```bash
stack build
```

## Usage

Generate a new key pair:

```bash
mkey --new main
```

Show an existing key:

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

## Library Usage

```haskell
import Crypt.Gen
import Crypt.Encrypt
import Crypt.Decrypt

main :: IO ()
main = do
    (pub, prv) <- newIOKeys

    let
        message = 42
        cipher  = encrypt pub message
        plain   = decrypt prv cipher

    print cipher
    print plain
```

## Project Structure

```text
src/
├── Crypt.hs
├── Crypt/
│   ├── Gen.hs
│   ├── Encrypt.hs
│   ├── Decrypt.hs
│   └── IO.hs
```

## Current Implementation

- Fast modular exponentiation
- Extended Euclidean algorithm
- RSA key generation
- Binary key storage
- Prime generation using trial division

## Planned

- [ ] Miller–Rabin primality test
- [ ] 256/512/1024-bit key generation
- [ ] OAEP padding
- [ ] Digital signatures
- [ ] PEM export/import
- [ ] Fingerprints
- [ ] RandomGen polymorphism
- [ ] Better CLI
- [ ] Benchmarks
- [ ] Tests

## Security Notice

This implementation is educational.

It currently:

- uses trial-division primality testing;
- does not implement OAEP or PKCS#1 padding;
- stores private keys unencrypted;
- has not been audited.

Do **not** use this project to protect sensitive information.

## License

MIT
