/*******************************************************************************
	mach_inject_bundle_stub.h
		Copyright (c) 2005 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://creativecommons.org/licenses/by/2.0/>
		
	Design inspired by SCPatchLoader, by Jon Gotow of St. Clair Software:
		<http://www.stclairsoft.com>

	***************************************************************************/

#ifndef		_mach_inject_bundle_stub_
#define		_mach_inject_bundle_stub_

#include <stddef.h> // for ptrdiff_t

typedef	struct	{
	ptrdiff_t	codeOffset;
	char		bundlePackageFileSystemRepresentation[1];
}	mach_inject_bundle_stub_param;

#endif	//	_mach_inject_bundle_stub_