# Maintainer: Timo Cramer <timo.cramer@tu-dortmund.de>

pkgname=gbasm-git
_gitname=gbasm
pkgver=
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
	cd $_gitname
	# Use the tag of the last commit
	git describe --always | sed 's|-|.|g'
}

build() {
	cd $_gitname
	make
}

package() {
	cd $_gitname
	make PREFIX="$pkgdir"/usr install
}
