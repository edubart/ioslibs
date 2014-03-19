#!/bin/sh

# clean
rm -rf all
mkdir -p all/{include,lib}


cp -R {libpng,lua,boost,chipmunk,physfs,openssl,freetype}/ios/{include,lib} all/

# SDL
cp -R sdl2/SDL2-2.0.2/include all/include/SDL2
cp sdl2/SDL2-2.0.2/Xcode-iOS/SDL/build/Release-universal/*.a all/lib/
