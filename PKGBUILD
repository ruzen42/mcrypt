# Maintainer: ruzen42 <ruzen@tuta.io>
#
# NOTE: package is named "mrun-crypt", not "mcrypt" — the name "mcrypt"
# (and "mcrypt-bin") is already taken in the AUR by the old libmcrypt-based
# CLI tool, and reusing it would collide with an unrelated package. The
# binaries it installs are still called mcrypt/mkey.
#
# Requires liboqs from the AUR first:
#   yay -S liboqs
# (or: git clone https://aur.archlinux.org/liboqs.git && cd liboqs && makepkg -si)

pkgname=mrun-crypt
pkgver=1.0.1
pkgrel=1
pkgdesc="Post-quantum file signing (ML-DSA-65 / Dilithium3) CLI, with BLAKE3 digests"
arch=('x86_64')
url="https://github.com/you/mrun-crypt"
license=('MIT')
depends=('liboqs' 'gmp' 'openssl')
makedepends=('ghc' 'cabal-install' 'pkgconf')

# Local-source build: this PKGBUILD is meant to live in the project's own
# repo root and build whatever is checked out there ($startdir), not
# download a tarball. source=() left empty on purpose.
source=()
sha256sums=()

build() {
  cd "$startdir"
  cabal update
  cabal build all
}

package() {
  cd "$startdir"
  install -Dm755 "$(cabal list-bin exe:mcrypt)" "$pkgdir/usr/bin/mcrypt"
  install -Dm755 "$(cabal list-bin exe:mkey)"   "$pkgdir/usr/bin/mkey"
}
