#!/bin/bash -e
# https://www.debian.org/doc/manuals/maint-guide/index.en.html 
# http://www.hackgnar.com/2016/01/simple-deb-package-creation.html 
# https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard 

# sudo apt install -y fakeroot unzip

# dpkg --info ${PACKAGE_NAME}.deb
# dpkg --contents ${PACKAGE_NAME}.deb
# sudo dpkg --install /tmp/gemstone-server_*.deb
# sudo dpkg --remove gemstone-server
# sudo dpkg --purge gemstone-server
# sudo apt remove gemstone-server

export VERSION="3.6.5"
export PRIORITY="30605"
export PACKAGE_NUM="1"
export PACKAGE_NAME="gemstone-server_${VERSION}-${PACKAGE_NUM}_amd64"
export BUILD_DIR="/tmp/${PACKAGE_NAME}"
export PRODUCT="/tmp/gemstone-server-$VERSION"
export NAME=GemStone64Bit${VERSION}-x86_64.Linux

# get rid of any existing build directory
chmod -R 777 /tmp/gemstone-server_* 2>/dev/null
rm -rf /tmp/gemstone-server_* 2>/dev/null

# get the product tree (skip download and unzip if we have it already)
if [ ! -f $PRODUCT.zip ]; then
  curl -o $PRODUCT.zip \
    https://downloads.gemtalksystems.com/pub/GemStone64/${VERSION}/${NAME}.zip
fi
if [ ! -d $PRODUCT ]; then
  unzip -d $PRODUCT-1 $PRODUCT.zip
  mv $PRODUCT-1/${NAME} $PRODUCT
  rmdir $PRODUCT-1
fi

mkdir -p $BUILD_DIR \
  $BUILD_DIR/DEBIAN \
  $BUILD_DIR/etc/alternatives \
  $BUILD_DIR/etc/cron.daily \
  $BUILD_DIR/etc/gemstone \
  $BUILD_DIR/etc/systemd/system \
  $BUILD_DIR/run/gemstone \
  $BUILD_DIR/usr/bin \
  $BUILD_DIR/usr/lib/gemstone/$VERSION \
  $BUILD_DIR/var/lib/gemstone/data \
  $BUILD_DIR/var/lib/gemstone/tranlogs \
  $BUILD_DIR/var/lib/gemstone/backups \
  $BUILD_DIR/var/log/gemstone

ln -s /run/gemstone $BUILD_DIR/var/lib/gemstone/locks
ln -s /var/log/gemstone $BUILD_DIR/var/lib/gemstone/log

# /etc/cron.daily/ will contain cron job
cp artifacts/cron.daily                   $BUILD_DIR/etc/cron.daily/gemstone

# /etc/gemstone/ will contain config files
cp artifacts/gs64stone.conf               $BUILD_DIR/etc/gemstone
cp artifacts/gem.conf                     $BUILD_DIR/etc/gemstone
cp $PRODUCT/data/system.conf              $BUILD_DIR/etc/gemstone
cp $PRODUCT/sys/community.starter.key     $BUILD_DIR/etc/gemstone/gemstone.key

# /etc/systemd/system/ contains files to control start/stop of services
cp artifacts/gs64stone.service            $BUILD_DIR/etc/systemd/system/
cp artifacts/gs64ldi.service              $BUILD_DIR/etc/systemd/system/

# /run/gemstone will contain runtime lock files (traditionally /opt/gemstone/locks)

# /usr/bin/ has symbolic links to executables
# /usr/lib/gemstone/VERION/ has the product tree
cp -r $PRODUCT/* $BUILD_DIR/usr/lib/gemstone/$VERSION

# /var/lib/gemstone/backups/ will contain backups
# /var/lib/gemstone/data/ will contain the database
# /var/lib/gemstone/tranlogs/ will contain transaction logs

# /var/log/gemstone will contain the log files

export DATE=`date +"%a, %d %B %Y %H:%M:%S %z"`
export SIZE=`du -s -k $BUILD_DIR | cut -f1`
# finally, we have the files used to create and install the package
cp artifacts/templates                  $BUILD_DIR/DEBIAN
cp artifacts/config                     $BUILD_DIR/DEBIAN
cp artifacts/control                    $BUILD_DIR/DEBIAN
cp artifacts/postinst                   $BUILD_DIR/DEBIAN
cp artifacts/prerm                      $BUILD_DIR/DEBIAN
cp artifacts/postrm                     $BUILD_DIR/DEBIAN

sed -i "s/DATE/$DATE/g"                 $BUILD_DIR/DEBIAN/control
sed -i "s/PRIORITY/$PRIORITY/g"         $BUILD_DIR/DEBIAN/postinst
sed -i "s/SIZE/$SIZE/g"                 $BUILD_DIR/DEBIAN/control
sed -i "s/VERSION/$VERSION/g"           $BUILD_DIR/DEBIAN/control
sed -i "s/VERSION/$VERSION/g"           $BUILD_DIR/DEBIAN/postinst
sed -i "s/VERSION/$VERSION/g"           $BUILD_DIR/DEBIAN/postrm
sed -i "s/VERSION/$VERSION/g"           $BUILD_DIR/DEBIAN/prerm

# build the package
date
time fakeroot dpkg-deb --build $BUILD_DIR   # 8+ minutes
date
