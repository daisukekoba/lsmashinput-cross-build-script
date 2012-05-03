#!/bin/sh

# ----------------------------------------------------------------------------
# Copyright (c) 2012, KOBAYASHI Daisuke
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# ----------------------------------------------------------------------------

work=$PWD
prefix=$work/_build
host=i686-w64-mingw32
crossprefix=${host}-
gcc_version=4.6.2

PATH=$PATH:/usr/local/$host/$gcc_version/bin

clone_lsmashworks()
{
  [ -d L-SMASH-Works ] && return
  git clone https://github.com/VFR-maniac/L-SMASH-Works.git
}
clone_lsmash()
{
  [ -d l-smash ] && return
  git clone https://code.google.com/p/l-smash/
}
clone_libav()
{
  [ -d libav ] && return
  git clone https://github.com/VFR-maniac/libav.git
}
clone_zlib()
{
  [ -d zlib ] && return
  git clone https://github.com/VFR-maniac/zlib.git
}
clone_ffms()
{
  [ -d ffmpegsource ] && return
  git clone https://github.com/VFR-maniac/ffmpegsource.git
}


build_lsmash()
{
  [ -d $prefix/lsmash ] && return
  mkdir -p $work/l-smash/_build
  cd $work/l-smash/_build
  ../configure --prefix=$prefix/lsmash --cross-prefix=$crossprefix
  make lib && make install-lib
}
build_libav()
{
  [ -d $prefix/libav ] && return
  mkdir -p $work/libav/_build
  cd $work/libav/_build
  local disables=$(echo "doc avconv avprobe avplay avdevice \
  	avfilter network hwaccels encoders muxers outdevs devices filters" \
  	| sed 's/\([[:alpha:]]\{1,\}\)/--disable-\1/g')
  ../configure --prefix=$prefix/libav \
  	--enable-cross-compile --cross-prefix=$crossprefix \
  	--target-os=mingw32 --arch=x86 \
  	--enable-gpl --disable-yasm --disable-debug $disables \
  	--extra-cflags="-I$prefix/zlib/include" \
  	--extra-ldflags="-L$prefix/zlib/lib"
  make && make install
}
build_zlib()
{
  [ -d $prefix/zlib ] && return
  cd $work/zlib
  CC=${crossprefix}gcc AR=${crossprefix}ar \
  	CPP=${crossprefix}cpp RANLIB=${crossprefix}ranlib \
  	LDSHARED=${crossprefix}gcc \
  	sh ./configure --prefix=$prefix/zlib --static
  make && make install
}
build_ffms()
{
  [ -d $prefix/ffms ] && return
  mkdir -p $work/ffmpegsource/_build
  cd $work/ffmpegsource/_build
  local libavlibs=$(echo "avformat avcodec swscale avutil" \
  	| sed 's/\([[:alpha:]]\{1,\}\)/-l\1/g')
  ../configure --prefix=$prefix/ffms --host=$host \
  	--with-zlib=$prefix/zlib \
  	LIBAV_CFLAGS="-I$prefix/libav/include -I$prefix/zlib/include" \
  	LIBAV_LIBS="-L$prefix/libav/lib $libavlibs -L$prefix/zlib/lib -lz"
  make && make install
}
build_lsmashinput()
{
  mkdir -p $work/L-SMASH-Works/AviUtl/_build
  cd $work/L-SMASH-Works/AviUtl/_build
  sh ../configure --cross-prefix=$crossprefix \
  	--extra-cflags="-I$prefix/lsmash/include -I$prefix/libav/include \
  	-I$prefix/ffms/include -I$prefix/zlib/include" \
  	--extra-ldflags="-L$prefix/lsmash/lib -L$prefix/libav/lib \
  	-L$prefix/ffms/lib -L$prefix/zlib/lib" \
  	--extra-libs="-lz"
  make
  cp lsmashdumper.auf lsmashinput.aui lsmashmuxer.auf $prefix
}


echo "--> cloning repository ------------------------------"
clone_lsmashworks
clone_lsmash
clone_libav
clone_zlib
clone_ffms

echo "--> building lsmash ---------------------------------"
build_lsmash
echo "--> building zlib -----------------------------------"
build_zlib
echo "--> building libav ----------------------------------"
build_libav
echo "--> building ffms -----------------------------------"
build_ffms
echo "--> building lsmashinput ----------------------------"
build_lsmashinput
echo "--> done --------------------------------------------"

