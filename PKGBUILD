# Maintainer: Timo Cramer <timo.cramer@tu-dortmund.de>

pkgname=gbasm-git
_gitname=gbasm
pkgver=r100.f4bcbc8
pkgrel=1
pkgdesc="An assembler for the Z80-like GameBoy"
arch=('i686' 'x86_64' 'armv6h')
url="https://github.com/timocramer/gbasm"
license=('GPL')
makedepends=('git' 'bison')
provides=('gbasm')
source=('git://github.com/timocramer/gbasm.git')
# Because the sources are not static, skip Git checksum:
md5sums=('SKIP')

pkgver() {
	cd "$_gitname"
	printf "r%s.%s" "$(git rev-list --count HEAD)" "$(git rev-parse --short HEAD)"
}

build() {
	cd $_gitname
	make
}

package() {
	cd $_gitname
	make DESTDIR="$pkgdir" PREFIX=/usr install
}
