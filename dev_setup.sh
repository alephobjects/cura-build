#!/bin/bash

mkdir -p build-devenv
cd build-devenv
cmake .. && make || exit
rm -rf ../devenv/bin ../devenv/lib ../devenv/share
mkdir -p ../devenv
cp -r inst/bin inst/lib inst/share ../devenv
cd ../devenv
git clone https://code.alephobjects.com/diffusion/CT/cura-lulzbot.git cura
git clone https://code.alephobjects.com/diffusion/U/uranium.git
rm -rf share/uranium share/cura lib/cura lib/uranium lib/python3/dist-packages/cura lib/python3/dist-packages/UM
cat > cura.sh <<EOF
#!/bin/bash

LD_LIBRARY_PATH=./lib PYTHONPATH=cura:uranium:./lib/python3/dist-packages QT_PLUGIN_PATH=./lib/plugins QML2_IMPORT_PATH=./lib/qml QT_QPA_FONTDIR=./lib/fonts python3.5 ./bin/cura-lulzbot "\$@"
EOF
chmod +x ./cura.sh
