unit Cod.WindowsRT.AppRegistration;

interface

uses
  // System
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Forms, IOUtils, System.Generics.Collections, Dialogs, Winapi.ActiveX,
  Win.ComObj, DateUtils, Winapi.ShlObj, Winapi.PropKey, Winapi.PropSys,

  // Graphics
  Vcl.Graphics,

  // Windows RT (Runtime)
  Win.WinRT,
  Winapi.Winrt,
  Winapi.Winrt.Utils,
  Winapi.DataRT,

  // Winapi
  Winapi.CommonTypes,
  Winapi.Foundation,
  Winapi.Storage.Streams,

  // Required
  Cod.WindowsRT.AsyncEvents,
  Cod.WindowsRT.Storage,
  Cod.WindowsRT.Runtime.Windows.Media,

  // Cod Utils
  Cod.Files,
  Cod.SysUtils,
  Cod.Windows,
  Cod.WindowsRT,
  Cod.ArrayHelpers,
  Cod.Registry;

type
  TRegistrationOption = (StartMenu, Registry);
  TRegistrationOptions = set of TRegistrationOption;

  TAppRegistration = class
  private
    FAppUserModelID: string;
    FAppName: string;
    FWantsAppIconPath: boolean;
    FAppIconPath: string;
    FAppDescription: string;
    FAppLaunchArguments: string;
    FAppExecutable: string;
    FAppShowInSettings: TWinBool;
    FRegOptions: TRegistrationOptions;

    // App icon
    function GetAppIconCachePath: string;
    function CreateAppIconCache: string;
    procedure DeleteIconCache;

    // Internal
    function GetRegistryKey(Global: boolean): string;
    function GetAppIconPath: string;

  protected
    // App
    function GetApplicationIcon: TIcon; virtual;

    // Getters
    function GetAppName: string; virtual;
    function GetAppUserModelID: string; virtual;
    function GetAppExecutable: string; virtual;

    // Setters
    procedure SetAppName(const Value: string); virtual;
    procedure SetAppUserModelID(const Value: string); virtual;
    procedure SetAppExecutable(const Value: string); virtual;

    // Register
    procedure RegisterRegistryClass(DoRegister: boolean; Global: boolean);
    procedure RegisterStartMenuClass(DoRegister: boolean; Global: boolean);

    // Registered
    function RegisteredStartMenu(Global: boolean): boolean;
    function RegisteredRegistry(Global: boolean): boolean;

    function PartiallyRegistered(Global: boolean): boolean; // partially registered

  public
    // For system use
    property AppUserModelID: string read GetAppUserModelID write SetAppUserModelID;
    property AppExecutable: string read GetAppExecutable write SetAppExecutable;

    property RegistrationOptions: TRegistrationOptions read FRegOptions write FRegOptions;

    // For start menu
    property AppName: string read GetAppName write SetAppName;
    property WantsAppIconPath: boolean read FWantsAppIconPath write FWantsAppIconPath;
    property AppIconPath: string read GetAppIconPath write FAppIconPath; // also supports proper icon formating, such as "C:\icon.ico, 2". Where 2 is the index
    property AppDescription: string read FAppDescription write FAppDescription;
    property AppLaunchArguments: string read FAppLaunchArguments write FAppLaunchArguments;

    // For registry
    property AppShowInSettings: TWinBool read FAppShowInSettings write FAppShowInSettings;

    // Registration status
    function RegisteredAny: boolean; // registered as global or user
    function Registered(Global: boolean): boolean; // full registered

    // Register
    procedure RegisterApp(Global: boolean);
    procedure UnRegisterApp(Global: boolean);

    // Required administrator privileges
    procedure UnRegisterAll;

    // Constructors
    constructor Create;
  end;

  TCurrentAppRegistration = class(TAppRegistration)
  protected
    // App
    function GetApplicationIcon: TIcon; override;

    // Getters
    function GetAppExecutable: string; override;
    function GetAppUserModelID: string; override;

    // Setters
    procedure SetAppUserModelID(const Value: string); override;
  public
    // Do not allow writing
    property AppExecutable: string read GetAppExecutable;
  end;

var
  AppRegistration: TCurrentAppRegistration;

// Shortcut
function InstallShortcut(AppUserModelID, ExePath, ShortcutPath, Description: string; Arguments: string=''; IconPath: string=''; IconIndex: integer=0): boolean;

function RegisterApplication(AppName, AppUserModelID, AppExecutable, Description: string; Arguments: string=''; IconPath: string=''; IconIndex: integer=0; Global: boolean=true): boolean;
function UnRegisterApplication(AppName: string; Global: boolean): boolean;

implementation

function GetAppStartMenuLocation(AppName: string; Global: boolean): string;
begin
  if Global then
    Result := ReplaceWinPath('%systemdrive%\ProgramData\Microsoft\Windows\Start Menu\Programs\')
  else
    Result := IncludeTrailingPathDelimiter(ReplaceWinPath('shell:Start Menu')) + 'Programs\';
  Result := Result+ValidateFileName(AppName)+'.lnk';
end;

function RegisterApplication(AppName, AppUserModelID, AppExecutable, Description, Arguments, IconPath: string; IconIndex: integer; Global: boolean): boolean;
begin
  Result := InstallShortcut(AppUserModelID, AppExecutable, GetAppStartMenuLocation(AppName, Global), Description, Arguments, IconPath, IconIndex);
end;

function UnRegisterApplication(AppName: string; Global: boolean): boolean;
var
  APath: string;
begin
  APath := GetAppStartMenuLocation(AppName, Global);
  Result := false;
  try
    if TFile.Exists(APath) then
      TFile.Delete(APath);
    Result := true;
  except
  end;
end;

function InstallShortcut(AppUserModelID, ExePath, ShortcutPath, Description, Arguments, IconPath: string; IconIndex: integer): boolean;
var
  newShortcut: IShellLink;

  persistFileSave: IPersistFile;
  newShortcutProperties: IPropertyStore;

  propVariant: TPropVariant;
begin
  newShortcut:= CreateComObject(CLSID_ShellLink) as IShellLink;

  // Add data
  with newShortcut do
  begin
    SetArguments(PChar(Arguments));
    SetDescription(PChar(Description));
    SetPath(PChar(ExePath));
    SetWorkingDirectory(PChar( ExtractFileDir(ExePath) ));

    if IconPath <> '' then
      SetIconLocation(PChar(IconPath), 0);
  end;

  // Property store
  newShortcutProperties := newShortcut as IPropertyStore;

  propVariant.vt := VT_BSTR;
  propVariant.bstrVal := Pchar(AppUserModelID);

  if not Succeeded(newShortcutProperties.SetValue(PKEY_AppUserModel_ID, propVariant)) then
    Exit( false );
  if not Succeeded(newShortcutProperties.Commit) then
    Exit( false );

  // Save
  persistFileSave := newShortcut as IPersistFile;
  Result := Succeeded( persistFileSave.Save(PWChar(WideString(ShortcutPath)), FALSE) );
end;

{ TAppRegistration }

constructor TAppRegistration.Create;
begin
  // Init
  FWantsAppIconPath := true;
  FRegOptions := [TRegistrationOption.StartMenu, TRegistrationOption.Registry];
end;

function TAppRegistration.CreateAppIconCache: string;
begin
  Result := GetAppIconCachePath;

  const Icon = GetApplicationIcon;

  if Icon <> nil then
    Icon.SaveToFile(Result)
  else
    Result := '';
end;

procedure TAppRegistration.DeleteIconCache;
begin
  const Path = GetAppIconCachePath;

  if TFile.Exists(Path) then
    TFile.Delete(Path);
end;

function TAppRegistration.GetAppExecutable: string;
begin
  Result := FAppExecutable;
end;

function TAppRegistration.GetAppIconCachePath: string;
var
  NotifFolder: string;
begin
  NotifFolder := IncludeTrailingPathDelimiter(
    ReplaceEnviromentVariabiles('%localappdata%')
    ) + 'Microsoft\Windows\Notifications\ActionCenter';

  // Result
  Result := Format('%S\%S.ico', [NotifFolder, AppUserModelID]);

  // Ensure directory valid
  if not TDirectory.Exists(NotifFolder) then
    TDirectory.CreateDirectory(NotifFolder);
end;

function TAppRegistration.GetAppIconPath: string;
begin
  if (FAppIconPath <> '') or not WantsAppIconPath then
    Result := FAppIconPath
  else
    Result := CreateAppIconCache;
end;

function TAppRegistration.GetApplicationIcon: TIcon;
begin
  Result := nil;
  if not TFile.Exists(AppExecutable) then
    Exit;

  Result := TIcon.Create;
  try
    GetIconStrIcon(AppExecutable, Result);
  except
    Result.Free;
    Result := nil;
  end;
end;

function TAppRegistration.GetAppName: string;
begin
  if FAppName = '' then
    Result := ExtractFileName( AppExecutable)
  else
    Result := FAppName;
end;

function TAppRegistration.GetAppUserModelID: string;
begin
  Result := FAppUserModelID;
end;

function TAppRegistration.GetRegistryKey(Global: boolean): string;
begin
  const Modal = AppUserModelID;
  if Modal = '' then
    Exit('');

  if Global then
    Result := 'HKEY_LOCAL_MACHINE\Software\Classes\AppUserModelId\'+Modal
  else
    Result := 'HKEY_CURRENT_USER\Software\Classes\AppUserModelId\'+Modal;
end;

function TAppRegistration.PartiallyRegistered(Global: boolean): boolean;
begin
  Result := RegisteredStartMenu(Global) or RegisteredRegistry(Global);
end;

procedure TAppRegistration.RegisterApp(Global: boolean);
begin
  if AppUserModelID = '' then
    raise Exception.Create('App User Model ID is empty.');
    
  // Register StartMenu App User Modal ID
  if TRegistrationOption.StartMenu in RegistrationOptions then
    RegisterStartMenuClass( true, Global );

  // Register registry
  if TRegistrationOption.Registry in RegistrationOptions then
    RegisterRegistryClass( true, Global );
end;

function TAppRegistration.Registered(Global: boolean): boolean;
begin
  Result := RegisteredStartMenu(Global) and RegisteredRegistry(Global);
end;

function TAppRegistration.RegisteredAny: boolean;
begin
  Result := Registered(false) or Registered(true);
end;

function TAppRegistration.RegisteredRegistry(Global: boolean): boolean;
begin
  Result := TQuickReg.KeyExists( GetRegistryKey(Global) );
end;

function TAppRegistration.RegisteredStartMenu(Global: boolean): boolean;
begin
  Result := TFile.Exists(GetAppStartMenuLocation(AppName, Global));
end;

procedure TAppRegistration.RegisterRegistryClass(DoRegister: boolean; Global: boolean);
const
  REG_VALUE_NAME = 'DisplayName';
  REG_VALUE_ICON = 'IconUri';
var
  Registry: TWinRegistry;
begin
  const Key = GetRegistryKey(Global);

  Registry := TWinRegistry.Create;
  try
    // Register
    if DoRegister then begin
      if not Registry.KeyExists(Key) then
        if not Registry.CreateKey(Key) then
          raise Exception.Create('Could not create registry class.');

      // Write values
      Registry.WriteValue(Key, REG_VALUE_NAME, GetAppName);
      const AppIcon = AppIconPath;
      if WantsAppIconPath and TFile.Exists(AppIcon) then
        Registry.WriteValue(Key, REG_VALUE_ICON, AppIconPath)
      else
        Registry.DeleteValue(Key, REG_VALUE_ICON);

      if AppShowInSettings.Initiated then
        Registry.WriteValue(Key, 'ShowInSettings', AppShowInSettings.ToInteger);
    end
      else
    // Unregister
    if Registry.KeyExists( Key ) then
      if not Registry.DeleteKey( Key ) then
        raise Exception.Create('Could not delete registry class.');

  finally
    Registry.Free;
  end;
end;

procedure TAppRegistration.RegisterStartMenuClass(DoRegister: boolean; Global: boolean);
begin
  if DoRegister then begin
    var IconIndex: word;
    var IconPath: string;
    ExtractIconDataEx(AppIconPath, IconPath, IconIndex);

    if not RegisterApplication(GetAppName, AppUserModelID, AppExecutable, AppDescription, AppLaunchArguments, IconPath, IconIndex, Global) then
      raise Exception.Create('Failed to register application in start menu.');
  end
    else
  if not UnRegisterApplication(GetAppName, Global) then
    raise Exception.Create('Failed to unregister application in start menu.');
end;

procedure TAppRegistration.SetAppExecutable(const Value: string);
begin
  FAppExecutable := Value;
end;

procedure TAppRegistration.SetAppName(const Value: string);
begin
  FAppName := Value;
end;

procedure TAppRegistration.SetAppUserModelID(const Value: string);
begin
  FAppUserModelID := Value;
end;

procedure TAppRegistration.UnRegisterAll;
begin
  if PartiallyRegistered( false ) then
    UnRegisterApp( false );
  if PartiallyRegistered( true ) then
    UnRegisterApp( true );
end;

procedure TAppRegistration.UnRegisterApp(Global: boolean);
begin
  if AppUserModelID = '' then
    raise Exception.Create('App User Model ID is empty.');

  // unregister all, regardless of RegistrationOptions

  // UnRegister App User Modal ID
  RegisterStartMenuClass( false, Global );

  // UnRegister registry
  RegisterRegistryClass( false, Global );

  // Delete cache if there is one
  DeleteIconCache;
end;

{ TCurrentAppRegistration }

{ TCurrentAppRegistration }

function TCurrentAppRegistration.GetAppExecutable: string;
begin
  Result := TCurrentProcess.GetAppExecutable;
end;

function TCurrentAppRegistration.GetApplicationIcon: TIcon;
begin
  Result := TIcon.Create;
  try
    Result.Assign( Application.Icon );
  except
    Result.Free;

    // Get previous method
    Result := inherited;
  end;
end;

function TCurrentAppRegistration.GetAppUserModelID: string;
begin
  Result := TCurrentProcess.GetAppUserModelID;
end;

procedure TCurrentAppRegistration.SetAppUserModelID(const Value: string);
begin
  TCurrentProcess.SetAppUserModelID( Value );
end;

initialization
  AppRegistration := TCurrentAppRegistration.Create;

finalization
  AppRegistration.Free;
end.
