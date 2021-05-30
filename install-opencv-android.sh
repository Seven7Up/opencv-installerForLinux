#!/bin/bash

WD="$(pwd)"
### DONT FORGET TO CHANGE THIS IF YOU HAVED INSTALL NDK IN YOUR MACHINE
NDK_PATH="$WD/ndk/android-ndk-r22b"

get_ndk(){
    wget -O ndk.zip https://dl.google.com/android/repository/android-ndk-r21e-linux-x86_64.zip
    unzip ndk.zip -d ndk
    rm -f ndk.zip
}

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
    cmake \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
    -DANDROID_NDK="$NDK_PATH" \
    -DANDROID_NATIVE_API_LEVEL=android-24 \
    -DBUILD_JAVA=OFF \
    -DBUILD_ANDROID_EXAMPLES=OFF \
    -DBUILD_ANDROID_PROJECTS=OFF \
    -DANDROID_STL=c++_static \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DANDROID_ABI=arm64-v8a \
    -DOPENCV_EXTRA_MODULES_PATH="$WD/opencv_contrib-master/modules" \
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
    ### This file is unuseful and make it more complex for the system
    ### Lot of tools include <opencv2/...> which it will return an error
    mv /usr/include/opencv2 /usr/local/include/.
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
    cat > /usr/lib/pkgconfig/opencv.pc << EOF
# Package Information for pkg-config

prefix=/usr
libdir=${prefix}/lib
includedir=${prefix}/include/opencv2

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

if [ "$(id -u)" -ne 0 ]; then
   echo "$(basename $0): must be run as root" >&2
   exit 1
fi

which_ndk="$(locate ndk)"
if ! [ "$which_ndk" ]; then
    get_ndk || die "Failed to get ndk!"
else
    echo "DONT FORGET TO CHANE NDK PATH IN THE SCRIPT FILE\!"
    sleep 4
fi

get_opencv || die "Coudn't get opencv repo!"
install_opencv || die "Coudn't install opencv!"
post_installation || die "Coudn't finish post installation!"
setup_cv_libs || die "Couldn't setup all opencv libraries!"
echo ""
echo "YOU GET IT, ENJOY!!"
opencv_version="$(pkg-config --modversion opencv)"
echo "Opencv version: $opencv_version"
