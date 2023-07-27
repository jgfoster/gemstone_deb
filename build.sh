#!/bin/bash
# http://www.hackgnar.com/2016/01/simple-deb-package-creation.html 
# https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard 

# sudo apt install -y fakeroot qemu-guest-agent unzip zip

export VERSION="3.6.5"
export PACKAGE_NUM="1"
export PACKAGE_NAME="gemstone-server_${VERSION}-${PACKAGE_NUM}_amd64"
export BUILD_DIR="${PWD}/${PACKAGE_NAME}"
export PRODUCT="/tmp/gemstone-server-$VERSION"
export NAME=GemStone64Bit${VERSION}-x86_64.Linux

# get rid of any existing build directory
chmod -R 777 gemstone-server_* 2>/dev/null
rm -rf gemstone-server_* 2>/dev/null

# get the product tree
if [ ! -f $PRODUCT.zip ]
then
  curl -o $PRODUCT.zip \
    https://downloads.gemtalksystems.com/pub/GemStone64/${VERSION}/${NAME}.zip
fi
if [ ! -d $PRODUCT ]
then
  unzip -d $PRODUCT-1 $PRODUCT.zip
  mv $PRODUCT-1/${NAME} $PRODUCT
  rmdir $PRODUCT-1
fi

echo "create the package environment"
mkdir -p $BUILD_DIR \
  $BUILD_DIR/DEBIAN \
  $BUILD_DIR/etc/gemstone \
  $BUILD_DIR/etc/systemd/system \
  $BUILD_DIR/opt/gemstone \
  $BUILD_DIR/run/gemstone \
  $BUILD_DIR/usr/bin \
  $BUILD_DIR/usr/include/gemstone \
  $BUILD_DIR/usr/lib/gemstone \
  $BUILD_DIR/usr/share/doc/gemstone \
  $BUILD_DIR/usr/share/man/man1 \
  $BUILD_DIR/usr/share/man/man5 \
  $BUILD_DIR/usr/share/man/man8 \
  $BUILD_DIR/usr/share/gemstone \
  $BUILD_DIR/usr/share/gemstone/data \
  $BUILD_DIR/usr/share/man \
  $BUILD_DIR/var/lib/gemstone \
  $BUILD_DIR/var/log/gemstone

echo "copy files from product tree to package environment"
# /etc/gemstone will contain config files
cp artifacts/gs64stone.conf           $BUILD_DIR/etc/gemstone
cp artifacts/gem.conf                 $BUILD_DIR/etc/gemstone
cp $PRODUCT/data/system.conf          $BUILD_DIR/etc/gemstone
cp $PRODUCT/sys/community.starter.key $BUILD_DIR/etc/gemstone/gemstone.key

# /etc/systemd/system contains files to control start/stop of services
cp artifacts/gs64stone.service        $BUILD_DIR/etc/systemd/system/
cp artifacts/gs64ldi.service          $BUILD_DIR/etc/systemd/system/

# /run/gemstone will contain runtime lock files (traditionally /opt/gemstone/locks)

# /usr/bin contains distribution-managed normal user programs (executables)
# the traditional GemStone distribution split these between bin and sys
cp $PRODUCT/bin/copydbf \
  $PRODUCT/bin/gslist \
  $PRODUCT/bin/pageaudit \
  $PRODUCT/bin/pstack \
  $PRODUCT/bin/searchlogs \
  $PRODUCT/bin/startcachewarmer \
  $PRODUCT/bin/startnetldi \
  $PRODUCT/bin/startstone \
  $PRODUCT/bin/statmonitor \
  $PRODUCT/bin/stopnetldi \
  $PRODUCT/bin/stopstone \
  $PRODUCT/bin/superdoit_solo \
  $PRODUCT/bin/superdoit_stone \
  $PRODUCT/bin/topaz \
  $PRODUCT/bin/upgradeImage \
  $PRODUCT/bin/waitstone \
  $PRODUCT/sys/gemnetdebug \
  $PRODUCT/sys/gemnetobject \
  $PRODUCT/sys/gemnetobject_keeplog \
  $PRODUCT/sys/netldid \
  $PRODUCT/sys/pgsvr \
  $PRODUCT/sys/pgsvrmain \
  $PRODUCT/sys/pgsvrmainl \
  $PRODUCT/sys/runadmingcgem \
  $PRODUCT/sys/runcachepgsvr \
  $PRODUCT/sys/runcachewarmergem \
  $PRODUCT/sys/runpageauditgem \
  $PRODUCT/sys/runpgsvr \
  $PRODUCT/sys/runreclaimgcgem \
  $PRODUCT/sys/runstatmonitor \
  $PRODUCT/sys/runsymbolgem \
  $PRODUCT/sys/shrpcmonitor \
  $PRODUCT/sys/startchild \
  $PRODUCT/sys/stoned \
  $BUILD_DIR/usr/bin
# these files are not distributed with GemStone but used to start/stop it
cp artifacts/gs64ldi              $BUILD_DIR/usr/bin
cp artifacts/gs64stone            $BUILD_DIR/usr/bin
# netldi will look for this in $GEMSTONE/sys so needs to be here as well
# see http://kermit.gemtalksystems.com/bug?bug=50614 for a fix
cp $PRODUCT/sys/services.dat      $BUILD_DIR/usr/bin

# /usr/include/gemstone provides standard include files
cp $PRODUCT/include/*             $BUILD_DIR/usr/include/gemstone

# /usr/lib/gemstone contains libraries for the binaries in /usr/bin
cp $PRODUCT/lib/*.so              $BUILD_DIR/usr/lib/gemstone

# /usr/share/doc/gemstone contains general documentation
cp $PRODUCT/doc/*.txt             $BUILD_DIR/usr/share/doc/gemstone/
cp -r $PRODUCT/licenses           $BUILD_DIR/usr/share/doc/gemstone

# /usr/share/man/ contain man pages in gz format
(cd $PRODUCT/doc/man1/; ls | xargs -I{} tar -czf $BUILD_DIR/usr/share/man/man1/{}.gz {})
(cd $PRODUCT/doc/man5/; ls | xargs -I{} tar -czf $BUILD_DIR/usr/share/man/man5/{}.gz {})
(cd $PRODUCT/doc/man8/; ls | xargs -I{} tar -czf $BUILD_DIR/usr/share/man/man8/{}.gz {})

# /usr/share/ is for architecture-independent (shared) data
# we will use /usr/share/gemstone for the traditional $GEMSTONE
cp -r $PRODUCT/rowan              $BUILD_DIR/usr/share/gemstone
cp -r $PRODUCT/seaside            $BUILD_DIR/usr/share/gemstone
cp -r $PRODUCT/upgrade            $BUILD_DIR/usr/share/gemstone
cp $PRODUCT/bin/extent0*.dbf      $BUILD_DIR/usr/share/gemstone/data

# /var/lib/gemstone will contain the database and transaction logs
# /var/log/gemstone will contain the log files

export DATE=`date +"%a, %d %B %Y %H:%M:%S %z"`
export SIZE=`du -s -k $BUILD_DIR | cut -f1`
# finally, we have the files used to create and install the package
cp artifacts/control              $BUILD_DIR/DEBIAN
sed -i "s/VERSION/$VERSION/g"     $BUILD_DIR/DEBIAN/control
sed -i "s/SIZE/$SIZE/g"           $BUILD_DIR/DEBIAN/control
sed -i "s/DATE/$DATE/g"           $BUILD_DIR/DEBIAN/control
cp artifacts/postinst             $BUILD_DIR/DEBIAN
sed -i "s/VERSION/$VERSION/g"     $BUILD_DIR/DEBIAN/postinst

# build the package
date
time fakeroot dpkg-deb --build $BUILD_DIR   # five minutes?
date

# inspect the package
# dpkg-deb --info ${PACKAGE_NAME}.deb
# view contents of the package
# dpkg-deb --contents ${PACKAGE_NAME}.deb
# install the package
# sudo dpkg --install ${PACKAGE_NAME}.deb
# remove the package
# sudo dpkg --remove ${PACKAGE_NAME}
# sudo apt remove ${PACKAGE_NAME}
