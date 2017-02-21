Pod::Spec.new do |s|
  s.name         = "FXDanmaku"
  s.version      = "v1.0.0"
  s.summary      = "High-performance danmaku with GCD, reusable items and customize configurations."

  s.homepage     = "https://github.com/ShawnFoo/"
  s.license      = { :type => "MIT", :file => "LICENSE" }

  s.author             = { "Shawn Foo" => "fu4904@gmail.com" }
  s.platform     = :ios
  s.ios.deployment_target = "7.0"

  s.source       = { :git => "https://github.com/ShawnFoo/FXDanmaku.git", :tag => s.version }
  s.source_files  = "FXDanmaku/*.{h,m}"
  s.framework  = "UIKit"
  s.requires_arc = true
end
