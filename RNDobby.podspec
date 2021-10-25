
Pod::Spec.new do |s|
  s.name         = "RNDobby"
  s.version      = "1.0.0"
  s.summary      = "RNDobby for react-native app"
  s.description  = <<-DESC
                  RNDobby is kit for react-native app
                   DESC
  s.homepage     = "n/a"
  s.license      = "MIT"
  # s.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  s.author             = "rosepomi"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/rosepomi/react-native-dobby.git", :tag => "master" }
  s.source_files  = "ios/**/*.{h,m}"
  s.requires_arc = true


  s.dependency "React"
  #s.dependency "others"

end

  