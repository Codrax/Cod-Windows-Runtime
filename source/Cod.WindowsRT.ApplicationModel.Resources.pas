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

unit Cod.WindowsRT.ApplicationModel.Resources;

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

  // Cod Utils
  Cod.WindowsRT;

type
  [WinRTClassNameAttribute('Microsoft.Windows.ApplicationModel.Resources.IResourceManager')]
  IResourceManager = interface(IRandomAccessStream)
  ['{13741D21-87EB-11CE-8081-0080C758527E}']
  end;

  TResourceManager = class(TWinRTGenericImportI<IResourceManager>) end;


implementation

end.
