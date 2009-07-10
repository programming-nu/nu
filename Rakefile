#
# This Rakefile is used to bootstrap Nu.
# Use it to build "mininush", a simpler and statically-linked
# version of nush, the Nu shell.
#
require 'rake'
require 'rake/clean'

SYSTEM = `uname`.chomp

PREFIX = ENV['PREFIX'] || '/usr/local'

@frameworks = []
@inc_dirs = %w{./include}
@libs = %w{objc ffi pcre}
@lib_dirs = []

if SYSTEM == 'Darwin'
  @frameworks << 'Cocoa'
  @libs += %w{edit}
else
  @libs += %w{readline m}
end

@inc_dirs << "#{PREFIX}/include" if File.exist? "#{PREFIX}/include"
@lib_dirs << "#{PREFIX}/lib" if File.exists? "#{PREFIX}/lib"

if SYSTEM == 'Darwin'
  if File.exist? '/usr/lib/libffi.dylib'
    # Use the libffi that ships with OS X.
    @inc_dirs << '/usr/include/ffi'
  else 
    # Use the libffi that is distributed with Nu.
    @inc_dirs << './libffi/include'
    @lib_dirs << './libffi'
  end
end

PCRE_CONFIG = `which pcre-config 2>/dev/null`.chomp
if PCRE_CONFIG
  prefix = `#{PCRE_CONFIG} --prefix`.chomp
  @inc_dirs << "#{prefix}/include"
  @lib_dirs << "#{prefix}/lib"
end

@leopard_cflags = ''
if File.exists? '/Developer/SDKs/MacOSX10.5.sdk'
  @leopard_cflags = '-DLEOPARD_OBJC2'
end

CLEAN.include('*/*.o')
CLOBBER.include('mininush')

@c_files      = FileList['objc/*.c'] 
@objc_files   = FileList['objc/*.m'] + FileList['main/*.m']
@gcc_files   = @objc_files + @c_files
@gcc_objects = @gcc_files.sub(/\.c$/, '.o').sub(/\.m$/, '.o')

@cc = "gcc"
if SYSTEM == "Darwin"
  @cflags = "-g -O2 -Wall -DMACOSX -DDARWIN -DMININUSH -std=gnu99 #{@leopard_cflags}"
  @mflags = "-fobjc-exceptions"
else
  @cflags = "-g -O2 -Wall -DLINUX -DMININUSH -std=gnu99 #{@leopard_cflags}"
  # @mflags = "-fobjc-exceptions -fconstant-string-class=NSConstantString"
  @mflags = `gnustep-config --objc-flags`.chomp
end

@cflags += @inc_dirs.map {|inc| " -I#{inc}"}.join
@ldflags = @frameworks.map {|framework| " -framework #{framework}"}.join
@ldflags += @libs.map {|lib| " -l#{lib}"}.join
@ldflags += @lib_dirs.map {|libdir| " -L#{libdir}"}.join 
if SYSTEM == "Linux"
  # @ldflags += " -lobjc -lNuFound"
  @ldflags += " "
  @ldflags += `gnustep-config --base-libs`.chomp
  @ldflags += " -Wl,--rpath -Wl,/usr/local/lib"
end

rule ".o" => [".m"] do |t|
  sh "#{@cc} #{@cflags} #{@mflags} -c -o #{t.name} #{t.source}"
end

rule ".o" => [".c"] do |t|
  sh "#{@cc} #{@cflags} -c -o #{t.name} #{t.source}"
end

file "mininush" => @gcc_objects do
  sh "gcc #{@gcc_objects} -g -O2 -o mininush #{@ldflags}"
end

task :default => "mininush"

