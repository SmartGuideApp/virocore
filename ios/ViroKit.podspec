 Pod::Spec.new do |s|
  s.name                = 'ViroKit'
  s.version             = '1.0'
  s.summary             = 'Framework containing the ViroRenderer'
  s.source              = { :path => '.' } # source is required, but path will be defined in user's Podfile (this value will be ignored).
  s.homepage            = 'http://viromedia.com'
  s.license             = {:type => 'Copyright', :text => "Copyright 2018 ViroMedia, Inc" }
  s.author              = 'Viro Media'
  s.requires_arc        = true
  s.platform            = :ios, '10.0'
  s.dependency          = 'React'
  s.vendored_frameworks = 'ViroKit.xcframework'
end
