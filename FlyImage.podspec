Pod::Spec.new do |s|
  s.name         = "FlyImage"
  s.version      = "0.9"
  s.summary      = "Download, cache, render small images with UIImageView category"
  s.description  = 	'FlyImage takes the advantages of SDWebImage, FastImageCache and AFNetworking, '      \
  				   	'is a simple and high performance image library.Features: '      \
					'High Performance, reduce memory operations while rendering, avoid Memory warning caused by image; ' \
					'Store and retrieve different size of small images in one memory file, smooth scrolling; ' \
					'Simple, support UIImageView, CALayer category; ' \
					'An asynchronous image downloader; ' \
					'Support WebP format; ' \
					'Support mmap to improve I/O performace;'

  s.homepage     = "https://github.com/northwind/FlyImage"
  s.license      = "MIT"
  s.author             = { "norristong" => "norristong_x@qq.com" }

  s.platform     = :ios, "8.0"
  s.source = { :git => 'https://github.com/northwind/FlyImage.git', :tag => s.version.to_s }
  s.source_files  = "FlyImage", "FlyImage/**/*.{h,m}"

  s.frameworks = "ImageIO", 'UIKit'
  s.requires_arc = true
  s.dependency 'AFNetworking', '~> 3.1'

  s.default_subspec = 'Core'

  s.subspec 'Core' do |core|
    core.source_files = "FlyImage", 'FlyImage/**/*.{h,m}'
  end

  s.subspec 'WebP' do |webp|
    webp.xcconfig = { 
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) FLYIMAGE_WEBP=1',
      'USER_HEADER_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/libwebp/src'
    }    
    webp.dependency 'FlyImage/Core'
    webp.dependency 'libwebp'
  end

end
