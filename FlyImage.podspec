Pod::Spec.new do |s|
  s.name         = "FlyImage"
  s.version      = "0.9"
  s.summary      = "Download, cache, render small images with UIImageView category"
  s.description  = "FlyImage takes the advantages of SDWebImage, FastImageCache and AFNetworking, is a simple and high performance image library."
  s.homepage     = "https://github.com/northwind/FlyImage"
  s.license      = "MIT"
  s.author             = { "norristong" => "norristong_x@qq.com" }

  s.platform     = :ios, "8.0"
  s.source = { :git => 'https://github.com/northwind/FlyImage.git' }
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
