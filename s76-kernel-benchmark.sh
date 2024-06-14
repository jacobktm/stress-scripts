#!/bin/bash

SCRIPT_PATH=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)
CHROOT_PATH=$HOME/kernel-benchmark
SERIAL_NUM=""

Help()
{
    echo "Usage: s76-kernel-benchmark.sh [options]"
    echo ""
    echo "options:"
    echo "-h        Display this message and exit."
    echo "-s        Serial Number"
}

while getopts ":hs:" option; do
   case $option in
        h) # help text
            Help
            exit;;
        s) # Serial Number
            SERIAL_NUM="-${OPTARG}";;
        \?) # Invalid option
            echo "Error: Invalid option"
	        Help
            exit;;
   esac
done

if [ -e "$CHROOT_PATH" ]; then
    sudo rm -rvf "$CHROOT_PATH"
fi
mkdir -p "$CHROOT_PATH"

tar xvf $SCRIPT_PATH/kernel-benchmark.tar.xz -C $CHROOT_PATH

# Bind mount necessary directories
sudo mount --bind /dev "$CHROOT_PATH/dev"
sudo mount --bind /proc "$CHROOT_PATH/proc"
sudo mount --bind /sys "$CHROOT_PATH/sys"
sudo mount --bind /run "$CHROOT_PATH/run"

touch "$CHROOT_PATH/runtimes.log"

for i in {1..3}; do
    sudo chroot $CHROOT_PATH /bin/bash <<EOF
echo \"$(date): Benchmark start run $i\" > benchmark.log
cd linux
make mrproper
make ARCH=x86_64 allmodconfig
START_TIME=\$(date +%s)
make -j$(nproc) ARCH=x86_64 2>/dev/null
END_TIME=\$(date +%s)
RUN_TIME=\$((END_TIME-START_TIME))
echo "\$RUN_TIME" >> ../runtimes.log
echo \"Benchmark run $i time: \${RUN_TIME} seconds\" >> ../benchmark.log
echo "" >> ../benchmark.log
exit
EOF
cat $CHROOT_PATH/benchmark.log >> "/home/${LOCAL_USER}/Desktop/kernel-benchmark${SERIAL_NUM}.log"
sleep 60
done

# unmount directories
sudo umount "$CHROOT_PATH/dev"
sudo umount "$CHROOT_PATH/sys"
sudo umount "$CHROOT_PATH/run"
sudo umount "$CHROOT_PATH/proc"

# Calculate the average runtime
RUNTIMES=($(cat "$CHROOT_PATH/runtimes.log"))
TOTAL=0
for time in "${RUNTIMES[@]}"; do
    TOTAL=$(($TOTAL+$time))
done
AVERAGE=$((TOTAL / 3))

echo "Average run time: $AVERAGE seconds" >> "/home/${LOCAL_USER}/Desktop/kernel-benchmark${SERIAL_NUM}.log"

sudo rm -rvf "$CHROOT_PATH"