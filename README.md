# gemstone_deb
Debian package creation for GemStone/S 64 Bit

To install GemStone on your system:

```shell
sudo curl -o /etc/apt/sources.list.d/gemstone.sources \
  http://alpha-ppa.gemtalksystems.com/gemstone.sources
sudo curl -o /etc/apt/keyrings/gemstone.gpg \
  http://alpha-ppa.gemtalksystems.com/gemstone.gpg
sudo apt update && sudo apt install gemstone-server
```

To "preseed" answers for a non-interactive install, do the following:

```shell
echo gemstone-server gemstone-server/password password mySecret | debconf-set-selections
echo gemstone-server gemstone-server/password-confirm password mySecret | debconf-set-selections
echo gemstone-server gemstone-server/unicode-comparison boolean yes | debconf-set-selections
export DEBIAN_FRONTEND=noninteractive
sudo apt update -q && sudo apt install -q -y gemstone-server
```