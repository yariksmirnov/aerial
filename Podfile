use_frameworks!
inhibit_all_warnings!

abstract_target 'Aerial' do
	pod 'ObjectMapper'
	pod 'XCGLogger', '~> 4.0.0'	
	pod 'Dollar'

	target 'AerialiOS' do 
		platform :ios, '9.0'
		pod 'CocoaLumberjack'
	end

	target 'Halfpipe' do
		platform :osx, '10.12'
        pod 'MASPreferences'
        pod 'PureLayout'
	end
end



