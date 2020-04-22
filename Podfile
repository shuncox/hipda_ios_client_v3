platform :ios, '9.0'

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
pod 'SDWebImage', '3.7.4'
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
pod '1PasswordExtension', '~> 1.8.6'
pod 'PromisesObjC', '1.2.3'
pod 'QCloudCOSXML'

pod 'QMUIKit/QMUIComponents/QMUIImagePickerLibrary', '~> 4.0.0'
pod 'QMUIKit/QMUIComponents/QMUITheme', '~> 4.0.0'

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
    system("sed -i '' '/UIWebView/d' Pods/BlocksKit/BlocksKit/BlocksKit+UIKit.h")
    system("sed -i '' '/UIWebView/d' Pods/QMUIKit/QMUIKit/UIKitExtensions/UIView+QMUI.m")
    system('rm Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.h')
    system('rm Pods/BlocksKit/BlocksKit/UIKit/UITextField+BlocksKit.m')
    system('rm Pods/BlocksKit/BlocksKit/UIKit/UIWebView+BlocksKit.h')
    system('rm Pods/BlocksKit/BlocksKit/UIKit/UIWebView+BlocksKit.m')
end
