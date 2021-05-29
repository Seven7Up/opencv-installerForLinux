#!/bin/bash

WD="$(pwd)"

install_independent(){
    ### Most linux had this packages, However, you can comment this line of code
    apt-get install -y gcc g++ make wget unzip
    apt-get install -y cmake
}

get_opencv(){
    # Download opencv
    ### I'm getting zip file not colone it with git because download size if compressed
    ### from ~360MB to ~80MB
    echo "Getting opencv"
    wget -O opencv.zip https://github.com/opencv/opencv/archive/master.zip 
    unzip opencv.zip

    echo "Getting opencv_contrib"
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/master.zip
    unzip opencv_contrib.zip
}

install_opencv(){
    # Create build directory and switch into it
    mkdir -p build
    cd build

    # Configuration
    cmake -DOPENCV_EXTRA_MODULES_PATH="$WD/opencv_contrib-master/modules" \
        "$WD/opencv-master"

    # Install it
    make install
    ldconfig
}

post_installation(){
    # Removing unused files
    rm -f $WD/opencv_contrib.zip
    rm -f $WD/opencv.zip

    ### In latest version of opencv, opencv create a folder in /usr/local/include with name as opencv4
    ### This file is unsuful and make it more complex for the system
    ### Lot of tools include <opencv2/...> which it will return an error
    mv /usr/local/include/opencv4/opencv2 /usr/local/include/.
    rm -rf /usr/local/include/opencv4
}

die(){
    echo "$@" >&2
    exit 1
}

if [ $(id -u) -ne 0 ]; then
   echo "$(basename $0): must be run as root" >&2
   exit 1
fi

get_opencv || die "Coudn't get opencv repo!"
install_opencv || die "Coudn't install opencv!"
post_installation || die "Coudn't finish post installation"
echo ""
echo "YOU GET IT, ENJOY!!"
