let g:android_sdk = "~/.android-sdk/"
let g:android_tools = g:android_sdk . "tools/"
let g:android_platform_tools = g:android_sdk . "platform-tools/"

let g:android = g:android_tools . "android"
let g:adb = g:android_platform_tools . "adb"

function! AdtSDKManager()

  silent echom "Launching Android SDK Manager"
  silent exec "!".g:android."&"
  silent echom "Android SDK Manager launched"

endfunction

function! AdtAVDManager()
 
  silent echom "Launching Android AVD Manager"
  silent exec "!".g:android ." avd&"
  silent echom "Android AVD Manager launched"

endfunction


function! AdtBuild()
  echo "Building in Debug mode..."
  let output = system("ant debug")
  
  
  if output =~ "Build failed"
    echo "Build failed"
  elseif output =~ "BUILD SUCCESSFUL"
    echo "Build Successful"
  else
    echo "Something wrong occured"
    echo output
  endif

endfunction

function! AdtInstall()
  echo "Installing..."
  let output = system("ant installd")


  if output =~ "BUILD SUCCESSFUL"
    echo "Installed successfuly"
  else
    echo output
  end

endfunction

function! AdtRun() 

  let devices = AdtGetDeviceList()
  let device_number = AdtAskWhichDevice()

  let package = AdtGetPackage()
  let main_activity = AdtGetMainActivity()

  silent echom "Launching ".main_activity
  silent exec "!".g:adb." -s ".devices[device_number]." shell am start -n ".package."/.".main_activity
  silent echom "Launched ".main_activity
  

endfunction


function! AdtGetDeviceList() 

  let output = system(g:adb." devices | sed -e '$d' -e '1d' -e 's/\\s\\w\\+//'")

  return split(output)

endfunction

function! AdtGetDeviceVersion(device)

  let output = system(g:adb." -s ".a:device." shell getprop ro.build.version.release")

  return split(output)[0]

endfunction

function! AdtAskWhichDevice()
  call inputsave()
  let devices = AdtGetDeviceList()
  let i = 0
  for device in devices
    let i += 1
    echo i.": ".device." [Android ".AdtGetDeviceVersion(device)."]"
  endfor
  let device_number = input("Which device: ")
  call inputrestore()

  return str2nr(device_number) - 1
endfunction

function! AdtIsAndroidProject()
  
  let output = system("ls")

  if (output =~ "AndroidManifest.xml")
    return 1
  else
    return 0
  endif

endfunction

function! AdtGetPackage()

  return system("cat AndroidManifest.xml | grep package | sed -e 's/package=\"\\(.*\\)\"/\\1/' -e 's/ *//' | tr -d '\\n'")

endfunction

function! AdtGetMainActivity()

  " Requires xml2
  return system("xml2 < AndroidManifest.xml | grep -Pzo '/manifest/application/activity/@android:name=.*\\n(.*\\n)+.*MAIN' | grep '/manifest/application/activity/@android:name' | tail -n 1 | sed 's/.*=\\(.*\\)$/\\1/' | sed 's/.*[.]\\(.*\\)$/\\1/'")

endfunction


function! AdtCreateProject()

  "target_id
  "project name
  "path
  "activity
  "package

  call inputsave()
  let project_name = input("Project name [AndroidProject]: ")
  if strlen(project_name) == 0
    let project_name = "AndroidProject"
  endif
  call inputrestore()

  call inputsave()
  let path = input("Path [AndroidProject]: ")
  if strlen(path) == 0
    let path = "AndroidProject"
  endif
  call inputrestore()

  call inputsave()
  let activity = input("Main activity name [MainActivity]: ")
  if strlen(activity) == 0
    let activity = "MainActivity"
  endif
  call inputrestore()

  call inputsave()
  let package = input("Package [com.example]: ")
  if strlen(package) == 0
    let package = "com.example"
  endif
  call inputrestore()

  redraw
  let targets = AdtGetTargetList()
  let i = 1
  for target in targets
    echo i.": ".target
    let i += 1
  endfor

  call inputsave()
  let target = input("Which target [1]: ")
  if strlen(target) == 0
    let target = 1
  endif
  call inputrestore() 

  let target = targets[target]

  silent echom "Creating project ".project_name
  silent exec "!".g:android." create project --target \"".target."\" --name \"".project_name."\" --path \"".path."\" --activity \"".activity."\" --package \"".package."\""
  silent echom project_name." project created"

  silent exec "cd ".path

endfunction

function! AdtGetTargetList()

  let output = system(g:android." list target | grep \"id:\" | sed 's/.*\"\\(.*\\)\"/\\1/' | grep android")
  
  return split(output)

endfunction

function! AdtBuildAndRunDebug()

  call AdtBuild()
  call AdtInstall()
  call AdtRun()

endfunction
