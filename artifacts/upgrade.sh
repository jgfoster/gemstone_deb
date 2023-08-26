#! /bin/sh -e

export upgradeDir=$GEMSTONE/upgrade

. $GEMSTONE/bin/misc.sh
defaultErrorControl

tmpObjSize=100000
export stoneName=gs64stone

# Make sure the topazerrors.log file goes into $upgradeLogDir, not pwd.
GS_TOPAZ_ERROR_LOG_DIR=$upgradeLogDir
export GS_TOPAZ_ERROR_LOG_DIR
# create a gem config file to use; note that this will also be used in postconv

cat <<EOF >$upgradeLogDir/conversion.conf
GEM_TEMPOBJ_CACHE_SIZE = $tmpObjSize;
GEM_NATIVE_CODE_ENABLED=0;
EOF

# Disable extended character tables for image upgrade.
export GS_DISABLE_CHARACTER_TABLE_LOAD=1

# ensure topazerrors.log only contains errors for this run
rm -f $upgradeLogDir/topazerrors.log

$GEMSTONE/bin/topaz -i -l -e $upgradeLogDir/conversion.conf < $upgradeDir/upgradeImage.topaz> $upgradeLogDir/topaz.log 2>&1

topaz_stat=$?
if [ $topaz_stat -eq 0 ]; then
  exit 0
else
  >&2 echo "ERROR: topaz exited with status $topaz_stat."
  >&2 echo "Please check these files for errors:"
  >&2 echo "  $upgradeLogDir/topazerrors.log"
  >&2 echo "  $upgradeLogDir/topaz.log"
  >&2 echo "and check latest version of:"
  >&2 echo "  $upgradeLogDir/upgradeImage*.out"
  >&2 echo " "
  exit $topaz_stat
fi
