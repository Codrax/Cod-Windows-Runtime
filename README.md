# Codrut's Windows Runtime for Delphi
This library integrates a lot of Windows functionality into Delphi X/11 with modern class wrappers and containers. Such implementations are the Windows Notification Manager, which allows for posting notifications to the action center, the Windows Media Transport Controls, which allow an app to register itself as playing media and having controls displayed in the volume popup and action center, the Master Volume manager and a lot of other utilities for working with Windows interfaces such as `IBuffers`, `IRandomAccessStream` and more.

# Registering app UserModelID
Since Windows 7, apps use a feature called the the AppUserModelID. This is a unique app identifier that Windows uses to differentiate your application from others and get information about It.
This is registered in two places, the start menu and the Windows Registry. It is tipically registered when the app is installed, since It adds the shortcut in the start menu. It can be registered Globally(requires administrator privileges) or only for the current user.
Here is where It's registeded:
|  |Start menu |Registry  |
| ------------- | ------------- | ------------- |
| Global | %systemdrive%\ProgramData\Microsoft\Windows\Start Menu\Programs\ | HKEY_LOCAL_MACHINE\Software\Classes\AppUserModelId\ |
| Just current user | shell:Start Menu | HKEY_CURRENT_USER\Software\Classes\AppUserModelId\ |

This library uses a `TAppRegistration` to manage an app's registration to both of this places. In the `Cod.WindowsRT.AppRegistration` there is a `AppRegistration` variabile defined for the current application, of type `TCurrentAppRegistration`.
For the application, during runtime, you will need to set the AppUserModelID once, as such:
```
AppRegistration.AppUserModelID := 'com.codrutsoft.test';
```
If not defined, It will be by default the module name of the executable, such as `firefox.exe`.

Here is an example on how to registed the app, It's reccomended to do this during the installation of the program, but It can also be done during runtime, but It's not reccomended as it means that it will add the start menu shortcut during runtime.
```
with TAppRegistration.Create do
  try
    AppUserModelID := 'com.codrutsoft.test';
    AppExecutable := 'C:\AppName\application.exe';
    AppName := 'Example app name';
    AppIconPath := ''; // location to ico file, can be left blank to create automatically
    AppDescription := 'Very interesting app description.';
    AppLaunchArguments := ''; // launch arguments for start menu shortcut
    AppShowInSettings := false; // show in settings the option to edit notification settings

    // Register
    RegisterApp( false ); // true = global, false = local
  finally
    Free;
  end;
```
To unregisted the app, It's even simpler, also recommended to do during the uninstallation, just call:
```
with TAppRegistration.Create do
  try
    AppUserModelID := 'com.codrutsoft.test';
    AppName := 'Example app name'; // required to delete the start menu shortcut

    // Register
    UnregisterApp( not Settings.UserInstall );
  finally
    Free;
  end;
```

## More about AppUserModelIDs
Once an application is registered with It's ID, It can be opened from the run menu (Win+R) and the following syntax
```
shell:appsfolder\<AppUserModelID>
```

## Documentation for specific units
- [Notification Manager](https://github.com/Codrax/Cod-WinRT-Notification-Manager)
- [Media Controls](https://github.com/Codrax/Cod-WinRT-Media-Controls)

## Screenshots
#### Notification Manager
![284015039-33026b0f-b11a-4c27-993e-69f6850db506](https://github.com/user-attachments/assets/2450a30c-46a7-45b7-a410-77ff8c54e16d)

#### Media Transport Controls
![image](https://github.com/user-attachments/assets/cb3d4cae-f037-406a-878a-ffee8be6c135)
