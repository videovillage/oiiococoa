Pod::Spec.new do |s|

  s.name         = "oiiococoa"
  s.version      = "0.0.1"
  s.summary      = "OpenImageIO for Cocoa"

  s.homepage     = "http://github.com/wilg/oiiococoa"

  s.license      = 'MIT'

  s.author             = { "Wil Gieseler" => "wil@wilgieseler.com" }
  s.social_media_url = "http://twitter.com/wilgieseler"

  s.platform     = :osx
  s.osx.deployment_target = '10.7'

  s.source       = { :git => "http://github.com/wilg/oiiococoa.git", :tag => "0.0.1" }

  s.requires_arc = true

  s.source_files  = [
      'Classes',
      'Classes/**/*.{h,m}',
      'Vendor/OpenImageIO/include/**/*.{h,cpp,hpp}'
  ]

  s.libraries = ['z']

  s.vendored_libraries = [
    'Vendor/libtiff/libtiff.a',
    'Vendor/OpenImageIO/libOpenImageIO.a',
    'Vendor/OpenImageIO/libOpenImageIO_Util.a',
    'Vendor/openexr/libIlmImf.a',
    'Vendor/jpeg/libjpeg.a',
    'Vendor/ilmbase/libHalf.a',
    'Vendor/ilmbase/libIex.a',
    'Vendor/ilmbase/libIexMath.a',
    'Vendor/ilmbase/libIlmThread.a',
    'Vendor/ilmbase/libImath.a',
    'Vendor/boost/libboost_filesystem.a',
    'Vendor/boost/libboost_regex.a',
    'Vendor/boost/libboost_thread-mt.a',
    'Vendor/boost/libboost_system.a',
    'Vendor/libpng/libpng15.a'
  ]

  s.preserve_paths = "Vendoer/**/*.a"

end
