platform :ios, '8.0'

def smart_pod(name, options = nil)
    dir = name.split('/', 2).first;
    if File.directory?('../'+dir)
        pod name, :path=> '../'+dir
    else
        pod name, options
    end
end

target 'HiPDA' do

pod 'AFNetworking', '1.3.3'
pod 'SDWebImage', :git => "https://github.com/wujichao/SDWebImage.git", :commit => "8a468e2"
pod 'MTLog'
pod 'RegexKitLite'
#pod 'SVProgressHUD', '1.0'
pod 'ZAActivityBar'
pod 'JSQSystemSoundPlayer', '~>1.5'
#pod 'JSMessagesViewController'
pod 'ALActionBlocks'
pod 'NSString+Emoji'
pod 'FMDB'
pod 'MCSwipeTableViewCell'
pod 'SAMKeychain', '~> 1.5.2'
pod 'RETableViewManager', '1.6'
pod 'CTAssetsPickerController', :git => "https://github.com/wujichao/CTAssetsPickerController.git"
#pod 'CTAssetsPickerController', :path => '../CTAssetsPickerController'
pod 'Qiniu', :git => 'https://github.com/qiniu/objc-sdk.git', :branch => 'AFNetworking-1.x'
pod 'Mantle', '1.5.4'
pod 'Objective-LevelDB'
pod 'Masonry'
pod 'ReactiveCocoa', '~>2.0'
pod 'AnimatedGIFImageSerialization'
pod 'SVPullToRefresh'
smart_pod 'MLeaksFinder', '~>0.2.0'
pod 'BlocksKit'
pod 'Reveal-SDK', :configurations => ['Debug']
pod 'CocoaLumberjack'
pod 'SSZipArchive'
pod 'KVOController'
pod '1PasswordExtension', '~> 1.8.4'
pod 'PromisesObjC', '1.2.3'

# JSPatch
#smart_pod 'JSPatch', '~> 1.1.3'
#smart_pod 'JSPatch/Extensions'
#smart_pod 'JSPatch/JPCFunction'
#smart_pod 'JSPatch/JPBlock'
#smart_pod 'JSPatch/JPCFunctionBinder'

end

# https://github.com/zwaldowski/BlocksKit/issues/283
# https://fabric.io/solo2/ios/apps/wujichao.hipda/issues/57e1d31d0aeb16625b87148a/sessions/20df982d4d524f58a810ddc9a3b15958
pre_install do
    system("sed -i '' '/UITextField/d' Pods/BlocksKit/BlocksKit/BlocksKit+UIKit.h")
    system('rm Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.h')
    system('rm Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.m')
end
