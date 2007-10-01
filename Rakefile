#
# This Rakefile is used to bootstrap Nu.
# Use it to build "mininush", a simpler and statically-linked
# version of nush, the Nu shell.
#
require 'rake'
require 'rake/clean'

if File.exist? "/usr/lib/libffi.dylib"
  FFI_LIB = "-L/usr/lib -lffi"
  FFI_INCLUDE = "-I /usr/include/ffi"
else
  FFI_LIB = "-L./libffi -lffi"
  FFI_INCLUDE = "-I ./libffi/include"
end

@include_dirs = %w{/opt/local/include /foo/bar}
@includes = @include_dirs.map{|include| " -I#{include}"}.join

@frameworks = %w{Cocoa}
@libs = %w{objc}
@lib_dirs = []

CLEAN.include("*/*.o")
CLOBBER.include("mininush")

@c_files      = FileList['objc/*.c'] 
@objc_files   = FileList['objc/*.m']
@gcc_files   = @objc_files + @c_files
@gcc_objects = @gcc_files.sub(/\.c$/, '.o').sub(/\.m$/, '.o')

@cc = "gcc"
@cflags = "-g -O2 -Wall #{FFI_INCLUDE} -DMACOSX"
@mflags = "-fobjc-exceptions"
@arch = ""

@ldflags = @frameworks.map {|framework| " -framework #{framework}"}.join
@ldflags += @libs.map {|lib| " -l#{lib}"}.join
@ldflags += @lib_dirs.map {|libdir| " -L#{libdir}"}.join 
@ldflags += " #{FFI_LIB}"

rule ".o" => [".m"] do |t|
  sh "#{@cc} #{@cflags} #{@mflags} #{@arch} #{@includes} -c -o #{t.name} #{t.source}"
end

rule ".o" => [".c"] do |t|
  sh "#{@cc} #{@cflags} #{@arch} #{@includes} -c -o #{t.name} #{t.source}"
end

file "mininush" => @gcc_objects do
  sh "gcc #{@gcc_objects} #{@arch} -g -O2 -o mininush -L/usr/local/lib -L/opt/local/lib -lreadline -lpcre #{FFI_LIB} -framework Cocoa"
end

task :default => "mininush"

