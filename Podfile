MIN_DEPLOYMENT_TARGET = '26.0'

platform :osx, MIN_DEPLOYMENT_TARGET

source 'https://github.com/MacDownApp/cocoapods-specs.git'  # Patched libraries.
source 'https://cdn.cocoapods.org/'

project 'MacDown.xcodeproj'

inhibit_all_warnings!

target "MacDown" do
  pod 'handlebars-objc', '~> 1.4'
  pod 'hoedown', '~> 3.0.7', :inhibit_warnings => false
  pod 'JJPluralForm', '~> 2.1'
  pod 'LibYAML', '~> 0.1'
  pod 'M13OrderedDictionary', '~> 1.1'
  pod 'MASPreferences', '~> 1.3'
  pod 'PAPreferences', '~> 0.5'
  pod 'Sparkle', '~> 2.6'
end

target "MacDownTests" do
  pod 'PAPreferences', '~> 0.5'
end

target "macdown-cmd" do
  pod 'GBCli', '~> 1.1'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      target_version = config.build_settings['MACOSX_DEPLOYMENT_TARGET']
      if target_version.nil? || target_version.to_f < MIN_DEPLOYMENT_TARGET.to_f
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = MIN_DEPLOYMENT_TARGET
      end
      config.build_settings['EXCLUDED_ARCHS[sdk=*]'] = 'x86_64'
      config.build_settings['ARCHS'] = 'arm64'
      if target.name == 'handlebars-objc'
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      end
    end
  end
end

post_integrate do |installer|
  user_project = installer.aggregate_targets.map(&:user_project).compact.uniq.first
  next unless user_project

  pods_ref = user_project.files.find { |f| f.path == 'Pods/Pods.xcodeproj' }
  unless pods_ref
    pods_ref = user_project.main_group.new_file('Pods/Pods.xcodeproj')
  end

  pods_project = installer.pods_project
  pairs = {
    'macdown-cmd' => ['GBCli', 'Pods-macdown-cmd'],
    'MacDown' => ['Pods-MacDown'],
    'MacDownTests' => ['Pods-MacDownTests'],
  }

  pairs.each do |user_target_name, pod_target_names|
    user_target = user_project.targets.find { |t| t.name == user_target_name }
    next unless user_target

    pod_target_names.each do |pod_name|
      pod_target = pods_project.targets.find { |t| t.name == pod_name }
      next unless pod_target
      next if user_target.dependencies.any? { |d| d.name == pod_name }

      proxy = user_project.new(Xcodeproj::Project::Object::PBXContainerItemProxy)
      proxy.container_portal = pods_ref.uuid
      proxy.proxy_type = '1'
      proxy.remote_global_id_string = pod_target.uuid
      proxy.remote_info = pod_name

      dependency = user_project.new(Xcodeproj::Project::Object::PBXTargetDependency)
      dependency.name = pod_name
      dependency.target_proxy = proxy
      user_target.dependencies << dependency
    end
  end

  user_project.save
end
