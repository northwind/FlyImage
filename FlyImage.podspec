Pod::Spec.new do |s|
  s.name         = "FlyImage"
  s.version      = "0.5"
  s.summary      = "A simple way to download and render Image on iOS."
  s.description  = "A simple way to download and render Image on iOS."
  s.homepage     = "http://github.com/augmn/FlyImage"
  s.license      = "MIT"
  s.author             = { "norristong" => "norristong_x@qq.com" }

  s.platform     = :ios, "8.0"
  s.source = { :git => 'https://github.com/augmn/FlyImage.git', :tag => s.version.to_s }
  s.source_files  = "FlyImage", "FlyImage/**/*.{h,m}"

  s.frameworks = "ImageIO", 'UIKit'
  s.requires_arc = true
  s.dependency 'AFNetworking', '~> 3.1'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = "FlyImage", 'FlyImage/**/*.{h,m}'
  end

  s.subspec 'WebP' do |webp|
    webp.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) FlyImage_WebP=1' }
    webp.dependency 'FlyImage/Core'
    webp.dependency 'libwebp'
  end

end
