;; Nukefile for Nu framework and nush, the Nu shell

;; source files
(set @c_files     (filelist "^objc/.*\.c$"))
(set @m_files     (filelist "^objc/.*\.m$"))
(set @nu_files 	  (filelist "^nu/.*\.nu$"))
(set @icon_files  (filelist "^lib/.*\.icns$"))
(set @frameworks  '("Cocoa"))
(set @libs 	  '("edit" "ffi" ))
(set @lib_dirs	  '("/usr/lib" "/usr/local/lib"))
(set @nib_files   '("share/nu/resources/English.lproj/MainMenu.nib"))

;; framework description
(set @framework "Nu")
(set @framework_identifier   "nu.programming.framework")
(set @framework_icon_file    "nu.icns")
(set @framework_initializer  "NuInit")
(set @framework_creator_code "????")

;; build configuration
(set @cc "gcc")
(set @cflags "-g -DMACOSX -I/usr/local/include")
(set @mflags "-fobjc-exceptions") ;; Want to try Apple's new GC? Add this: "-fobjc-gc"

(cond
     ((NSFileManager fileExistsNamed:"/usr/lib/libffi.dylib")
      (set @includes "-I /usr/include/ffi"))
     (t
       (set @includes "-I ./libffi/include")
       (set @lib_dirs (append @lib_dirs '("./libffi")))))

(set @arch '("ppc" "i386"))
;(set @arch nil)

(set @ldflags
     ((list
           "/usr/local/lib/libpcre.a" ;; statically link in pcre since most people won't have it..
           ((@frameworks map: (do (framework) " -framework #{framework}")) join)
           ((@libs map: (do (lib) " -l#{lib}")) join)
           ((@lib_dirs map: (do (libdir) " -L#{libdir}")) join))
      join))

;; Setup the tasks for compilation and framework-building.
;; These are defined in the nuke application source file.
(compilation-tasks)
(framework-tasks)

(task "framework" => "#{@framework_headers_dir}/Nu.h")

(file "#{@framework_headers_dir}/Nu.h" => "objc/Nu.h" @framework_headers_dir is
      (SH "cp objc/Nu.h #{@framework_headers_dir}"))

(task "clobber" => "clean" is
      (SH "rm -rf nush #{@framework_dir} doc"))

(set nush_thin_binaries (NSMutableArray array))
(@arch each: 
       (do (architecture) 
           (set nush_thin_binary "build/#{architecture}/nush")
           (nush_thin_binaries addObject:nush_thin_binary)
           (file nush_thin_binary => "framework" "build/#{architecture}/main.o" is
                 (SH "#{@cc} #{@cflags} -arch #{architecture} -F. -framework Nu build/#{architecture}/main.o #{@ldflags} -o #{(target name)}"))))

(file "nush" => "framework" nush_thin_binaries is
      (SH "lipo -create #{(nush_thin_binaries join)} -output #{(target name)}"))

;; These tests were the first sanity tests for Nu. They require RubyObjC.
(task "test.rb" => "framework" is
      (SH "ruby -rtest/unit -e0 -- -v --pattern '/test_.*\.rb^/'"))

(task "test" => "framework" "nush" is
      (SH "nutest test/test_*.nu"))

(task "doc" is
      (SH "nudoc"))

(task "publish" => "doc" is
      (SH "scp -r doc/* blog.neontology.com:blog/site/public/nudoc-preview"))

(task "default" => "nush")

;; Except for the Nu.framework (installed in /Library/Frameworks), 
;; all scripts and binaries are installed to /usr/local/bin
(set @prefix "/usr/local")

(task "install" => "nush" is
      ('("nuke" "nubile" "enu" "nutest" "nudoc") each: 
        (do (program)
            (SH "sudo cp tools/#{program} #{@prefix}/bin")))
      (SH "sudo cp nush #{@prefix}/bin")
      (SH "sudo rm -rf /Library/Frameworks/#{@framework}.framework")
      (SH "cp -pRfv #{@framework}.framework /Library/Frameworks/#{@framework}.framework")
      (SH "sudo mkdir -p #{@prefix}/share")
      (SH "sudo rm -rf #{@prefix}/share/nu")
      (SH "sudo cp -pRfv share/nu #{@prefix}/share/nu")
      (SH "sudo cp -pRfv examples #{@prefix}/share/nu/examples"))

;; Build a disk image for distributing the framework.
(task "framework_image" => "framework" is
      (SH "rm -rf '#{@framework}.dmg' dmg")
      (SH "mkdir dmg; cp -Rp '#{@framework}.framework' dmg")
      (SH "hdiutil create -srcdir dmg '#{@framework}.dmg' -volname '#{@framework}'")
      (SH "rm -rf dmg"))

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
      (SH "/Developer/Tools/packagemaker -build -f package -p Nu.pkg -d pkg/Description.plist -i pkg/Info.plist")
      (SH "mkdir dmg; mv Nu.pkg dmg")
      (SH "hdiutil create -srcdir dmg Nu.dmg -volname Nu")
      (SH "sudo rm -rf dmg package"))