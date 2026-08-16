{***********************************************************}
{     Codruts Windows Runtime ApplicationModel Resources    }
{                                                           }
{                        version 1.0                        }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{                                                           }
{              Copyright 2024 Codrut Software               }
{***********************************************************}

{$SCOPEDENUMS ON}

unit Cod.WindowsRT.UI.Shell;

interface
uses
  // System
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Forms, IOUtils, System.Generics.Collections, Dialogs, ActiveX, ComObj,
  DateUtils, Math,

  // Graphics
  Vcl.Graphics,

  // Windows RT (Runtime)
  Win.WinRT,
  Winapi.Winrt,
  Winapi.Winrt.Utils,
  Winapi.DataRT,
  Winapi.CommonNames,

  // Winapi
  Winapi.CommonTypes,
  Winapi.Foundation,
  Winapi.Storage.Streams,

  // Async
  Cod.WindowsRT.AsyncEvents,
  Cod.WindowsRT.CommonNames,

  // Cod Utils
  Cod.WindowsRT;

type
  IAppListEntry = interface(IInspectable)
    ['{EF00F07F-2108-490A-877A-8A9F17C25FAD}']
    function get_DisplayInfo: IAppDisplayInfo; stdcall;
    property DisplayInfo: IAppDisplayInfo read get_DisplayInfo;
  end;
  IAppListEntry2 = interface(IInspectable)
    ['{D0A618AD-BF35-42AC-AC06-86EEEB41D04B}']
    function get_AppUserModelId: HSTRING; safecall;
    property AppUserModelId: HSTRING read get_AppUserModelId;
  end;
  IAppListEntry3 = interface(IInspectable)
    ['{6099F28D-FC32-470A-BC69-4B061A76EF2E}']
    function LaunchForUserAsync(User: IUser; out operation: PIAsyncOperation_1__Boolean): HRESULT;
  end;
  IAppListEntry4 = interface(IInspectable)
    ['{2A131ED2-56F5-487C-8697-5166F3B33DA0}']
    function get_AppInfo: IAppInfo; safecall;
    property AppInfo: IAppInfo read get_AppInfo;
  end;

  ITaskbarManager = interface(IInspectable)
    ['{87490A19-1AD9-49F4-B2E8-86738DC5AC40}']
    function get_IsSupported(out value: Boolean): HRESULT; stdcall;
    function get_IsPinningAllowed(out value: Boolean): HRESULT; stdcall;
    function IsCurrentAppPinnedAsync(out operation: PIAsyncOperation_1__Boolean): HRESULT; stdcall;
    function RequestPinCurrentAppAsync(out operation: PIAsyncOperation_1__Boolean): HRESULT; stdcall;
  end;
  ITaskbarManager2 = interface(IInspectable)
    ['{79F0A06E-7B02-4911-918C-DEE0BBD20BA4}']
    function IsAppListEntryPinnedAsync(entry: IAppListEntry; out operation: PIAsyncOperation_1__Boolean): HRESULT; stdcall;
    function RequestPinAppListEntryAsync(entry: IAppListEntry; out operation: PIAsyncOperation_1__Boolean): HRESULT; stdcall;
  end;

  [WinRTClassNameAttribute(SFactory_TaskbarManagerDesktopAppSupportStatics)]
  ITaskbarManagerDesktopAppSupportStatics = interface(IInspectable)
    ['{DB32AB74-DE52-4FE6-B7B6-95FF9F8395DF}']
    function GetForApplication(FriendlyName: HSTRING): ITaskbarManager; safecall;
    //function IsSupported: Boolean; safecall;
  end;

  TTaskbarManagerDesktopAppSupportStatics = class(TWinRTGenericImportF<ITaskbarManagerDesktopAppSupportStatics>) end;


implementation

end.
