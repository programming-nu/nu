#
# This Rakefile is used to bootstrap Nu.
# Use it to build "mininush", a simpler and statically-linked
# version of nush, the Nu shell.
#
require 'rake'
require 'rake/clean'

SYSTEM = `uname`.chomp

PREFIX = ENV["PREFIX"] ? ENV["PREFIX"] : "/usr/local" 

if SYSTEM == "Darwin"
  if File.exist? "/usr/lib/libffi.dylib"
    # Use the libffi that ships with OS X.
    FFI_LIB = "-L/usr/lib -lffi"
    FFI_INCLUDE = "-I /usr/include/ffi"
    LEOPARD_CFLAGS = "-DLEOPARD_OBJC2"
  else 
    # Use the libffi that is distributed with Nu.
    FFI_LIB = "-L./libffi -lffi"
    FFI_INCLUDE = "-I ./libffi/include"
    LEOPARD_CFLAGS = ""
  end
else # Linux
  # Use the libffi that is distributed with Linux.
  FFI_LIB = "-lffi"
  FFI_INCLUDE = ""
  LEOPARD_CFLAGS = ""
end

@includes = FFI_INCLUDE + " -I ./include "

if SYSTEM == "Darwin"
  @includes += " -I #{PREFIX}/include" if File.exist? "#{PREFIX}/include"
  @frameworks = %w{Cocoa}
  @libs = %w{objc pcre readline}
  @lib_dirs = []
  @lib_dirs << "#{PREFIX}/lib" if File.exist? "#{PREFIX}/lib"
else
  @includes += " -I /usr/local/include"
  @frameworks = [] # %w{Cocoa}
  @libs = %w{m pcre readline }
  @lib_dirs = []
end


CLEAN.include("*/*.o")
CLOBBER.include("mininush")

@c_files      = FileList['objc/*.c'] 
@objc_files   = FileList['objc/*.m'] + FileList['main/*.m']
@gcc_files   = @objc_files + @c_files
@gcc_objects = @gcc_files.sub(/\.c$/, '.o').sub(/\.m$/, '.o')

@cc = "gcc"
if SYSTEM == "Darwin"
  @cflags = "-g -O2 -Wall -DMACOSX -DDARWIN -DMININUSH -std=gnu99 #{LEOPARD_CFLAGS}"
  @mflags = "-fobjc-exceptions"
else
  @cflags = "-g -O2 -Wall -DLINUX -DMININUSH -std=gnu99 #{LEOPARD_CFLAGS} "
  @mflags = "-fobjc-exceptions -fconstant-string-class=NSConstantString"
end

@ldflags = @frameworks.map {|framework| " -framework #{framework}"}.join
@ldflags += @libs.map {|lib| " -l#{lib}"}.join
@ldflags += @lib_dirs.map {|libdir| " -L#{libdir}"}.join 
@ldflags += " #{FFI_LIB}"
if SYSTEM == "Linux"
  @ldflags += " -lobjc -lNuFound"
  @ldflags += " -Wl,--rpath -Wl,/usr/local/lib"
end

rule ".o" => [".m"] do |t|
  sh "#{@cc} #{@cflags} #{@mflags} #{@includes} -c -o #{t.name} #{t.source}"
end

rule ".o" => [".c"] do |t|
  sh "#{@cc} #{@cflags} #{@includes} -c -o #{t.name} #{t.source}"
end

file "mininush" => @gcc_objects do
  sh "gcc #{@gcc_objects} -g -O2 -o mininush #{@ldflags}"
end

task :default => "mininush"

