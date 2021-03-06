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
    
    make -j$(nproc --all)

    # Install it
    make install
    ldconfig
}

post_installation(){
    # Removing unused files
    rm -f $WD/opencv_contrib.zip
    rm -f $WD/opencv.zip

    ### In latest version of opencv, opencv create a folder in /usr/local/include with name as opencv4
    ### This file is unuseful and make it more complex for the system
    ### Lot of tools include <opencv2/...> which it will return an error
    mv /usr/local/include/opencv4/opencv2 /usr/local/include/.
    rm -rf /usr/local/include/opencv4
}

setup_cv_libs(){
    opencvLibs="$(ls -l /usr/include/opencv2 | grep drwx | cut -d ' ' -f 11)"

    for lib in $opencvLibs; do
        cat > "/usr/lib/pkgconfig/opencv_${lib}.pc" << EOF
# Package Information for pkg-config

prefix=/usr
libdir=\${prefix}/lib
includedir=\${prefix}/include/opencv2/${lib}

Name: OpenCV
Description: Open Source Computer Vision Library - OpenCV lib: ${lib}
Version: 4.5.1
Libs: -L\${libdir}
Cflags: -I\${includedir}
EOF

    opencvLibs_pc="${opencvLibs_pc} -l${lib}"
done

    ### This file is useful while compiling your project
    ### You need just run: g++ -g -Wall -o main main.cpp `pkg-config --cflags --libs opencv`
    cat > /usr/lib/pkgconfig/opencv.pc << EOF
# Package Information for pkg-config

prefix=/usr
exec_prefix=${prefix}/local
libdir=${prefix}/lib
includedir=${exec_prefix}/include/opencv2

Name: OpenCV
Description: Open Source Computer Vision Library
Version: 4.5.1
Libs: -L${libdir}${opencvLibs_pc}
Libs.private: -ldl -lm -lpthread -lrt
Cflags: -I${includedir}
EOF
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
post_installation || die "Coudn't finish post installation!"
setup_cv_libs || die "Couldn't setup all opencv libraries!"
echo ""
echo "YOU GET IT, ENJOY!!"
opencv_version="$(pkg-config --modversion opencv)"
echo "Opencv version: $opencv_version"
