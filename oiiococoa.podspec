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
  s.osx.deployment_target = '10.9'

  s.source       = { :git => "https://github.com/videovillage/oiiococoa.git", :tag => s.version.to_s }

  s.source_files  = [
      'Classes',
      'Classes/**/*.{h,m}',
      'Vendor/OpenImageIO/include/**/*.{h,cpp,hpp}',
      'Vendor/libdpx/*.{h,cpp,hpp}'
  ]

  s.requires_arc = true
  s.libraries = ['z', 'stdc++']

  s.private_header_files = ['Vendor/OpenImageIO/include/OpenImageIO/*.{h,hpp}', 'Vendor/libdpx/*.{h,hpp}']

  s.vendored_libraries = [
    'Vendor/libtiff/lib/libtiff.a',
    'Vendor/libtiff/lib/libtiffxx.a',
    'Vendor/xz/lib/liblzma.a',
    'Vendor/OpenImageIO/lib/libOpenImageIO.a',
    'Vendor/OpenImageIO/lib/libOpenImageIO_Util.a',
    'Vendor/openexr/lib/libIlmImf.a',
    'Vendor/jpeg/lib/libjpeg.a',
    'Vendor/ilmbase/lib/libHalf.a',
    'Vendor/ilmbase/lib/libIex.a',
    'Vendor/ilmbase/lib/libIexMath.a',
    'Vendor/ilmbase/lib/libIlmThread.a',
    'Vendor/ilmbase/lib/libImath.a',
    'Vendor/boost/lib/libboost_filesystem.a',
    'Vendor/boost/lib/libboost_regex.a',
    'Vendor/boost/lib/libboost_thread-mt.a',
    'Vendor/boost/lib/libboost_system.a',
    'Vendor/libpng/lib/libpng16.a'
  ]

  s.preserve_paths = "Vendor/**/*.a"

end
