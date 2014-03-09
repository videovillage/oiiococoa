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

  s.source_files  = 'Classes', 'Classes/**/*.{h,m}'

  s.requires_arc = true

  s.libraries = [
    'z',
    'tiff',
    'OpenImageIO_Util',
    'OpenImageIO',
    'IlmImf',
    'jpeg',
    'Half',
    'Iex',
    'IexMath',
    'IlmThread',
    'Imath',
    'boost_filesystem',
    'boost_regex',
    'boost_thread-mt',
    'boost_system',
    'png15'
  ]

  s.xcconfig = {
    'HEADER_SEARCH_PATHS' => "$(SRCROOT)/Vendor/OpenImageIO/include",
    'LIBRARY_SEARCH_PATHS' => "$(SRCROOT)/Vendor/**"
  }

end
