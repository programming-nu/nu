/*******************************************************************************
	mach_inject_bundle.h
		Copyright (c) 2005 Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
		Some rights reserved: <http://creativecommons.org/licenses/by/2.0/>

	***************************************************************************/
	
/***************************************************************************//**
	@mainpage	mach_inject_bundle
	@author		Jonathan 'Wolf' Rentzsch: <http://rentzsch.com>
	
	Higher-level interface for mach_inject. This framework, intended to be
	embedded into your application, allows you to "inject and forget" an
	arbitrary bundle into an arbitrary process. It supplies the primitive code
	block that gets squirted across the address spaces
	(mach_inject_bundle_stub), which was the trickiest thing to write.

	It's a Cocoa framework right now, but I intend to make it usable from Carbon
	apps as well. Indeed, it already may be -- it doesn't use Cocoa or
	Objective-C at all. I just haven't tried yet.
	
	@todo	Supply a higher-level interface to specifying processes than just a
			process ID. I'm thinking offering lookup via application ID
			("com.apple.Finder") and via type/creator ('FNDR', 'MACS').

	***************************************************************************/

#ifndef		_mach_inject_bundle_
#define		_mach_inject_bundle_

#include <sys/types.h>
#include <mach/error.h>

#ifdef	__cplusplus
	extern	"C"	{
#endif

#define	err_mach_inject_bundle_couldnt_load_framework_bundle	(err_local|1)
#define	err_mach_inject_bundle_couldnt_find_injection_bundle	(err_local|2)
#define	err_mach_inject_bundle_couldnt_load_injection_bundle	(err_local|3)
#define	err_mach_inject_bundle_couldnt_find_inject_entry_symbol	(err_local|4)

/***************************************************************************//**
	
	
	@param	bundlePackageFileSystemRepresentation	->	Required pointer
	@param	pid										->	
	@result					<-	mach_error_t

	***************************************************************************/

	mach_error_t
mach_inject_bundle_pid(
		const char	*bundlePackageFileSystemRepresentation,
		pid_t		pid );

#ifdef	__cplusplus
	}
#endif
#endif	//	_mach_inject_bundle_