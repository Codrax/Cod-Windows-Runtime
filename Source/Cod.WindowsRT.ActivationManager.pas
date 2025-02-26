{***********************************************************}
{               Codruts Windows Media Controls              }
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

unit Cod.WindowsRT.ActivationManager;

interface

uses
  // System
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Forms, IOUtils, System.Generics.Collections, Dialogs, ActiveX, ComObj,
  DateUtils, ShlObj,

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

  // Media
  Winapi.Media,

  // Required
  Cod.WindowsRT.AsyncEvents,
  Cod.WindowsRT.Storage,
  Cod.WindowsRT.Runtime.Windows.Media,

  // Resources
  Cod.WindowsRT.Exceptions,
  Cod.WindowsRT.ResourceStrings,

  // Cod Utils
  Cod.WindowsRT,
  Cod.Registry;

const
  CLSID_ApplicationActivationManager: TGUID = '{45BA127D-10A8-46EA-8AB7-56EA9078943C}';

type
  ActivateOptions = (
    None = 0,
    DesignMode = 1,
    NoErrorUI = 2,
    NoSplashScreen = 4
  );

  [TWinRTGUIDAttribute('{45BA127D-10A8-46EA-8AB7-56EA9078943C}')]
  IApplicationActivationManager = interface(IUnknown)
    ['{2e941141-7f97-4756-ba1d-9decde894a3d}']
    function ActivateApplication(appUserModelId: PWideChar; arguments: PWideChar; options: ActivateOptions; out processId: DWORD): HResult; stdcall;
    function ActivateForFile(appUserModelId: PWideChar; itemArray: IShellItemArray; verb: PWideChar; out processId: DWORD): HResult; stdcall;
    function ActivateForProtocol(appUserModelId: PWideChar; itemArray: IShellItemArray; out processId: DWORD): HResult; stdcall;
  end;

  TApplicationActivationManager = class(TComObjGenericImort<IApplicationActivationManager>) end;

implementation

end.
