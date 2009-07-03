;; Nukefile for Nu framework and nush, the Nu shell

(global VERSION '(0 4 0)) #(major minor tweak)

(task "version" is
      (set now (NSCalendarDate date))
      (set version <<-END
#define NU_VERSION "#{(VERSION first)}.#{(VERSION second)}.#{(VERSION third)}"
#define NU_VERSION_MAJOR #{(VERSION first)}
#define NU_VERSION_MINOR #{(VERSION second)}
#define NU_VERSION_TWEAK #{(VERSION third)}
#define NU_RELEASE_DATE "#{(now yearOfCommonEra)}-#{(now monthOfYear)}-#{(now dayOfMonth)}"
#define NU_RELEASE_YEAR  #{(now yearOfCommonEra)}
#define NU_RELEASE_MONTH #{(now monthOfYear)}
#define NU_RELEASE_DAY   #{(now dayOfMonth)}
END)
      (version writeToFile:"objc/version.h" atomically:NO encoding:NSUTF8StringEncoding error:(set error (NuReference new))))

;; read environment for prefix and destroot
(let ((env ((NSProcessInfo processInfo) environment)))
     (if (env objectForKey:"PREFIX")
         (then (set @prefix (env objectForKey:"PREFIX")))
         (else (set @prefix "/usr/local")))
     (if (env objectForKey:"DESTDIR")
         (then (set @destdir (env objectForKey:"DESTDIR")))
         (else (set @destdir ""))))

;; source files
(set @c_files     (filelist "^objc/.*\.c$"))
(set @m_files     (filelist "^objc/.*\.m$"))
(@m_files unionSet:(filelist "^baked/.*\.m$"))
(set @nu_files    (filelist "^nu/.*\.nu$"))
(set @icon_files  (filelist "^lib/.*\.icns$"))
(set @nib_files   '("share/nu/resources/English.lproj/MainMenu.nib"))

;; libraries
(set @frameworks (NSMutableArray array))
(set @inc_dirs   (NSMutableArray arrayWithList:(list "/usr/include")))
(set @lib_dirs   (NSMutableArray arrayWithList:(list "/usr/lib")))
(set @libs       (NSMutableArray arrayWithList:(list "objc" "ffi" "pcre")))

(@inc_dirs addObjectsFromList:(list "./include" "./include/Nu"))
(ifDarwin
         (then (@frameworks addObject:"Cocoa")
               (@libs       addObject:"edit"))
         (else (@libs       addObjectsFromList:(list "readline" "m" "gnustep-base"))
               (@inc_dirs   addObject:"/usr/include/GNUstep/Headers")
               ;; this will be set by gnustep-config:
               ;; (@lib_dirs   addObject:"/usr/lib/GNUstep/System/Library/Libraries")
               ))

(if (NSFileManager directoryExistsNamed:"#{@prefix}/include") (@inc_dirs addObject:"#{@prefix}/include"))
(if (NSFileManager directoryExistsNamed:"#{@prefix}/lib") (@lib_dirs addObject:"#{@prefix}/lib"))

(ifDarwin
         (then (if (NSFileManager fileExistsNamed:"/usr/lib/libffi.dylib")
                   (then ;; Use the libffi that ships with OS X.
                         (@inc_dirs addObject:"/usr/include/ffi"))
                   (else ;; Use the libffi that is distributed with Nu.
                         (@inc_dirs addObject:"./libffi/include")
                         (@lib_dirs addObject:"./libffi")))))

(set @pcre_prefix "")
(let ((pcre_config ((NSString stringWithShellCommand:"which pcre-config 2>/dev/null") chomp)))
     (if pcre_config
         (then (set @pcre_prefix ((NSString stringWithShellCommand:"#{pcre_config} --prefix") chomp))
               (@inc_dirs addObject:"#{@pcre_prefix}/include")
               (@lib_dirs addObject:"#{@pcre_prefix}/lib"))))

;; framework description
(set @framework "Nu")
(set @framework_identifier   "nu.programming.framework")
(set @framework_icon_file    "nu.icns")
(ifDarwin (then (set @framework_initializer  "NuInit")))
(set @framework_creator_code "????")

;; for Linux, we build Nu as a dynamic library
(set @dylib "libNu")

;; build configuration
(set @cc "gcc")
(set @leopard "")
(set @sdk
     (cond ((NSFileManager directoryExistsNamed:"/Developer/SDKs/MacOSX10.5.sdk")
            (set @leopard "-DLEOPARD_OBJC2 -D__OBJC2__")
            ("-isysroot /Developer/SDKs/MacOSX10.5.sdk"))
           ((NSFileManager directoryExistsNamed:"/Developer/SDKs/MacOSX10.4u.sdk")
            ("-isysroot /Developer/SDKs/MacOSX10.4u.sdk"))
           (else "")))

(ifDarwin
         (then (set @cflags "-Wall -g -O2 -DDARWIN -DMACOSX #{@sdk} #{@leopard} -std=gnu99")
               (set @mflags "-fobjc-exceptions")) ;; Want to try Apple's new GC? Add this: "-fobjc-gc"
         (else (set @cflags "-Wall -DLINUX -g -std=gnu99 ")
               ;; (set @mflags "-fobjc-exceptions -fconstant-string-class=NSConstantString")
               (set @mflags ((NSString stringWithShellCommand:"gnustep-config --objc-flags") chomp))))

(ifDarwin
         (then (set @arch '("ppc" "i386")))) ;; build a universal binary
;; or set this to just build for your chosen platform
;;(set @arch '("i386"))

(set @includes
     ((@inc_dirs map: (do (inc) " -I#{inc}")) join))
(set @ldflags
     ((list
           (cond  ;; statically link in pcre since most people won't have it..
                  ((NSFileManager fileExistsNamed:"#{@pcre_prefix}/lib/libpcre.a") "#{@pcre_prefix}/lib/libpcre.a")
                  ((NSFileManager fileExistsNamed:"/usr/lib/libpcre.a") "/usr/lib/libpcre.a")
                  ((NSFileManager fileExistsNamed:"#{@prefix}/lib/libpcre.a") "#{@prefix}/lib/libpcre.a")
                  (else (NSException raise:"NukeBuildError" format:"Can't find static pcre library (libpcre.a).")))
           ((@frameworks map: (do (framework) " -framework #{framework}")) join)
           ((@libs map: (do (lib) " -l#{lib}")) join)
           (ifDarwin
                    (then ((@lib_dirs map:
                        (do (libdir) " -L#{libdir}")) join))
                    (else ((@lib_dirs map:
                        (do (libdir) " -L#{libdir} -Wl,--rpath #{libdir}")) join))))
     join))

(ifDarwin
         (set @public_headers (filelist "include/Nu/Nu.h")))

;; Setup the tasks for compilation and framework-building.
;; These are defined in the nuke application source file.
(compilation-tasks)
(ifDarwin
         (then (framework-tasks))
         (else (dylib-tasks)))

(task "clobber" => "clean" is
      (ifDarwin
               (SH "rm -rf nush #{@framework_dir} doc"))
      ((filelist "^examples/[^/]*$") each:
       (do (example-dir)
           (if ((NSFileManager defaultManager) fileExistsAtPath:(+ example-dir "/Nukefile"))
               (SH "cd #{example-dir}; nuke clobber")))))

(ifLinux
      (set @gnustep_flags ((NSString stringWithShellCommand:"gnustep-config --base-libs") chomp)))


(set nush_thin_binaries (NSMutableArray array))
(@arch each:
       (do (architecture)
           (set nush_thin_binary "build/#{architecture}/nush")
           (nush_thin_binaries addObject:nush_thin_binary)
           (ifDarwin
                    (then
                         (file nush_thin_binary => "framework" "build/#{architecture}/main.o" is
                               (SH "#{@cc} #{@cflags} #{@mflags} main/main.m -arch #{architecture} -F. -framework Nu #{@ldflags} -o #{(target name)}")))
                    (else
                         (file nush_thin_binary => "dylib" (@c_objects objectForKey:architecture) (@m_objects objectForKey:architecture) is
                               (SH "#{@cc} #{@cflags} #{@mflags} main/main.m #{@library_executable_name} #{@ldflags} #{@gnustep_flags} -o #{(target name)}"))))))

(file "nush" => "framework" nush_thin_binaries is
      (ifDarwin
               (then (SH "lipo -create #{(nush_thin_binaries join)} -output #{(target name)}"))
               (else (SH "cp '#{(nush_thin_binaries objectAtIndex:0)}' '#{(target name)}'"))))

;; These tests were the first sanity tests for Nu. They require RubyObjC.
(task "test.rb" => "framework" is
      (SH "ruby -rtest/unit -e0 -- -v --pattern '/test_.*\.rb^/'"))

(task "test" => "framework" "nush" is
      (SH "./nush tools/nutest test/test_*.nu"))

(task "doc" is
      (SH "nudoc"))

(task "publish-doc" is
      (SH "nudoc -site programming.nu")
      (SH "scp -r doc programming.nu:/Sites/programming.nu/public/"))

(task "default" => "nush")

;; Except for the Nu.framework (installed in /Library/Frameworks),
;; all scripts and binaries are installed to #{@prefix}/bin

(set @installprefix "#{@destdir}#{@prefix}")

(task "install" => "nush" is
      ('("nuke" "nubile" "nutemplate" "nutest" "nudoc" "nubake" "nutmbundle") each:
        (do (program)
            (SH "sudo cp tools/#{program} #{@installprefix}/bin")))
      (SH "sudo cp nush #{@installprefix}/bin")
      (ifDarwin
               ;; install the framework
               (SH "sudo rm -rf #{@destdir}/Library/Frameworks/#{@framework}.framework")
               (SH "ditto #{@framework}.framework #{@destdir}/Library/Frameworks/#{@framework}.framework"))
      (if (eq (uname) "Linux")
          ;; install the dynamic library
          (SH "sudo cp #{@library_executable_name} #{@installprefix}/lib")
          ;; copy the headers
          (SH "sudo rm -rf #{@installprefix}/include/Nu")
          (SH "sudo cp -rp include/Nu #{@installprefix}/include")
	  (SH "sudo cp -rp nu/ #{@installprefix}/share/libNu"))
      (SH "sudo mkdir -p #{@installprefix}/share")
      (SH "sudo rm -rf #{@installprefix}/share/nu")
      (SH "sudo cp -rp share/nu #{@installprefix}/share/nu")
      (ifDarwin
               (SH "sudo ditto examples #{@installprefix}/share/nu/examples")))

;; Build a disk image for distributing the framework.
(task "framework_image" => "framework" is
      (SH "rm -rf '#{@framework}.dmg' dmg")
      (SH "mkdir dmg; cp -Rp '#{@framework}.framework' dmg")
      (SH "hdiutil create -srcdir dmg '#{@framework}.dmg' -volname '#{@framework}'")
      (SH "rm -rf dmg"))

(if (NSFileManager fileExistsNamed:"/Developer/usr/bin/packagemaker")
    (then (set PACKAGEMAKER "/Developer/usr/bin/packagemaker"))
    (else (set PACKAGEMAKER "/Developer/Tools/packagemaker")))

;; Build an installer and wrap it in a disk image.
(task "installer" => "framework" "nush" is
      (SH "sudo rm -rf package dmg Nu.dmg")
      (SH "mkdir -p package/Library/Frameworks")
      (SH "mkdir -p package/usr/local/bin")
      (SH "mkdir -p package/usr/local/share")
      (SH "cp -pRfv #{@framework}.framework package/Library/Frameworks/#{@framework}.framework")
      (SH "cp -pRfv share/nu package/usr/local/share")
      (SH "cp -pRfv examples package/usr/local/share/nu")
      (SH "cp nush package/usr/local/bin")
      (SH "cp tools/* package/usr/local/bin")
      (SH "sudo chown -R root package")
      (SH "sudo chgrp -R admin package")
      (SH "#{PACKAGEMAKER} -build -f package -p Nu.pkg -d pkg/Description.plist -i pkg/Info.plist")
      (SH "mkdir dmg; mv Nu.pkg dmg")
      (set imagefile "Nu-#{(VERSION first)}.#{(VERSION second)}.#{(VERSION third)}.dmg")
      (SH "sudo rm -f #{imagefile}")
      (SH "hdiutil create -srcdir dmg #{imagefile} -volname Nu")
      (SH "sudo rm -rf dmg package"))

;; alias for installer task
(task "dmg" => "installer")

;; Create a tgz file of the Nu sources.
(task "archive" is
      (SH <<-END
git archive --format=tar --prefix=Nu-#{(VERSION first)}.#{(VERSION second)}.#{(VERSION third)}/ HEAD |\
gzip -c > Nu-#{(VERSION first)}.#{(VERSION second)}.#{(VERSION third)}.tgz
END))

;; "Bake" nu source files into compilable Objective-C files.
(task "bake" is
      (set nu_files (((NSString stringWithShellCommand:"ls nu/*.nu") chomp) componentsSeparatedByString:"\n"))
      (nu_files each:
           (do (nu_file)
               (set basename (((nu_file pathComponents) lastObject) stringByDeletingPathExtension))
               (set command "nubake #{nu_file} -n 'baked_#{basename}' -o baked/baked_#{basename}.m")
               (puts command)
               (system command))))
