/*******************************************************************************
    load_bundle.c
        Copyright (c) 2005 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
        Some rights reserved: <http://creativecommons.org/licenses/by/2.0/>

    ***************************************************************************/

#include "load_bundle.h"
#include <CoreServices/CoreServices.h>
#include <sys/syslimits.h>                        // for PATH_MAX.
#include <mach-o/dyld.h>

mach_error_t
load_bundle_package(
const char *bundlePackageFileSystemRepresentation )
{
    assert( bundlePackageFileSystemRepresentation );
    assert( strlen( bundlePackageFileSystemRepresentation ) );

    mach_error_t err = err_none;

    //	Morph the FSR into a URL.
    CFURLRef bundlePackageURL = NULL;
    if( !err ) {
        bundlePackageURL = CFURLCreateFromFileSystemRepresentation(
            kCFAllocatorDefault,
            (const UInt8*)bundlePackageFileSystemRepresentation,
            strlen(bundlePackageFileSystemRepresentation),
            true );
        if( bundlePackageURL == NULL )
            err = err_load_bundle_url_from_path;
    }

    //	Create bundle.
    CFBundleRef bundle = NULL;
    if( !err ) {
        bundle = CFBundleCreate( kCFAllocatorDefault, bundlePackageURL );
        if( bundle == NULL )
            err = err_load_bundle_create_bundle;
    }

    //	Discover the bundle's executable file.
    CFURLRef bundleExecutableURL = NULL;
    if( !err ) {
        assert( bundle );
        bundleExecutableURL = CFBundleCopyExecutableURL( bundle );
        if( bundleExecutableURL == NULL )
            err = err_load_bundle_package_executable_url;
    }

    //	Morph the executable's URL into an FSR.
    char bundleExecutableFileSystemRepresentation[PATH_MAX];
    if( !err ) {
        assert( bundleExecutableURL );
        if( !CFURLGetFileSystemRepresentation(
            bundleExecutableURL,
            true,
            (UInt8*)bundleExecutableFileSystemRepresentation,
        sizeof(bundleExecutableFileSystemRepresentation) ) ) {
            err = err_load_bundle_path_from_url;
        }
    }

    //	Do the real work.
    if( !err ) {
        assert( strlen(bundleExecutableFileSystemRepresentation) );
        err = load_bundle_executable( bundleExecutableFileSystemRepresentation);
    }

    //	Clean up.
    if( bundleExecutableURL )
        CFRelease( bundleExecutableURL );
    if( bundle )
        CFRelease( bundle );
    if( bundlePackageURL )
        CFRelease( bundlePackageURL );

    return err;
}

mach_error_t
load_bundle_executable(
const char *bundleExecutableFileSystemRepresentation )
{
    assert( bundleExecutableFileSystemRepresentation );

    mach_error_t err = err_none;

    //	Create the object file image.
    NSObjectFileImage image;
    if( !err ) {
        NSObjectFileImageReturnCode imageErr = NSCreateObjectFileImageFromFile(
            bundleExecutableFileSystemRepresentation, &image );
        switch( imageErr ) {
            case NSObjectFileImageFailure:
                err = err_load_bundle_NSObjectFileImageFailure;
                break;
            case NSObjectFileImageSuccess:
                // Not an error.
                break;
            case NSObjectFileImageInappropriateFile:
                err = err_load_bundle_NSObjectFileImageInappropriateFile;
                break;
            case NSObjectFileImageArch:
                err = err_load_bundle_NSObjectFileImageArch;
                break;
            case NSObjectFileImageFormat:
                err = err_load_bundle_NSObjectFileImageFormat;
                break;
            case NSObjectFileImageAccess:
                err = err_load_bundle_NSObjectFileImageAccess;
                break;
            default:
                assert(0);
        }
    }

    #if 0
    //	Ensure we can link the image before actually attempting to link it.
    if( !err ) {
        assert( image );
        unsigned long symbolIndex, symbolCount
            = NSSymbolReferenceCountInObjectFileImage( image );
        for( symbolIndex = 0; !err && symbolIndex < symbolCount;++symbolIndex) {
            if( !NSIsSymbolNameDefined( NSSymbolReferenceNameInObjectFileImage(
                image,
                symbolIndex,
            NULL ) ) ) {
                err = err_load_bundle_undefined_symbol;
            }
        }
    }
    #endif

    //	Link.
    if( !err ) {
        NSModule module = NSLinkModule( image,
            bundleExecutableFileSystemRepresentation,
            NSLINKMODULE_OPTION_BINDNOW
            |NSLINKMODULE_OPTION_PRIVATE
            |NSLINKMODULE_OPTION_RETURN_ON_ERROR );
        if( module == NULL )
            err = err_load_bundle_link_failed;
    }

    return err;
}
