Pod::Spec.new do |s|
  s.name         = "Nu"
  s.version      = "2.0.1"
  s.summary      = "A short description of Nu."
  s.homepage     = "http://programming.nu/about"
  s.license      = 'Apache License, v. 2.0'
  s.author       = { "dreamwieber" => "gregorywieber@gmail.com" }
  s.source       = { :git => "https://github.com/dreamwieber/nu" }
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.source_files = 'objc/*.{h,m}'
  s.ios.source_files = 'libffi/*.{h,S,c}'
  s.public_header_files = 'objc/*.h'
  s.resources = 'nu/*.nu'
  s.framework  = 'Foundation'
  s.osx.libraries = 'edit', 'ffi'
end