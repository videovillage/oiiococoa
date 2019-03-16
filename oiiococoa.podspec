Pod::Spec.new do |s|

  s.name         = "oiiococoa"
  s.version      = begin; File.read('VERSION'); rescue; '9000.0.0'; end
  s.summary      = "OpenImageIO for Cocoa"

  s.homepage     = "http://github.com/videovillage/oiiococoa"

  s.license      = 'MIT'

  s.author             = { "Wil Gieseler" => "wil@wilgieseler.com",
                            "Greg Cotten" => "gregcotten@gmail.com" }
  s.social_media_url = "http://twitter.com/wilgieseler"

  s.platform     = :osx
  s.osx.deployment_target = '10.12'
  s.frameworks = ['Accelerate']

  s.source       = { :git => "https://github.com/videovillage/oiiococoa.git", :tag => s.version.to_s }

  s.source_files  = [
      'Classes',
      'Classes/**/*.{h,m}',
      'Vendor/**/include/**/*.{h,hpp}',
      'Vendor/libdpx/*.{h,cpp,hpp}'
  ]

  s.requires_arc = true
  s.libraries = ['z', 'stdc++']

  s.private_header_files = ['Vendor/**/include/**/*.{h,hpp}', 'Vendor/libdpx/*.{h,hpp}']

  s.vendored_libraries = [
    'Vendor/**/lib/*.a'
  ]

  s.preserve_paths = "Vendor/**/lib/*.a"

end
