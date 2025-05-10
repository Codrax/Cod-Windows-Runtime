{***********************************************************}
{               Codruts Windows Runtime Sharing             }
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

unit Cod.WindowsRT.Sharing;

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
  Winapi.ApplicationModel.DataTransfer,

  // Async
  Cod.WindowsRT.AsyncEvents,

  // Cod Utils
  Cod.WindowsRT;

const
  IID_IDataTransferManager: TGUID = '{A5CAEE9B-8708-49D1-8D36-67D25A8DA00C}';

type
  TWindowsSharingManger = class;
  TDataRequest = class;

  // Notify object managers
  TDataTransferManagerDataRequestedEventProc = procedure(Sender: TWindowsSharingManger; Request: TDataRequest) of object;
  TDataTransferManagerDataRequestedEvent = class(TSubscriptionEventHandler<TWindowsSharingManger,
    TDataTransferManagerDataRequestedEventProc>,
      TypedEventHandler_2__IDataTransferManager__IDataRequestedEventArgs,
      TypedEventHandler_2__IDataTransferManager__IDataRequestedEventArgs_Delegate_Base)
  protected
    procedure Subscribe; override;
    procedure Unsubscribe; override;

    procedure Invoke(sender: IDataTransferManager; args: IDataRequestedEventArgs); virtual; safecall;
  end;

  TDataTransferManagerTargetApplicationChosenEventProc = procedure(Sender: TWindowsSharingManger; ApplicationName: string) of object;
  TDataTransferManagerTargetApplicationChosenEvent = class(TSubscriptionEventHandler<TWindowsSharingManger,
    TDataTransferManagerTargetApplicationChosenEventProc>,
      TypedEventHandler_2__IDataTransferManager__ITargetApplicationChosenEventArgs,
      TypedEventHandler_2__IDataTransferManager__ITargetApplicationChosenEventArgs_Delegate_Base)
  protected
    procedure Subscribe; override;
    procedure Unsubscribe; override;

    procedure Invoke(sender: IDataTransferManager; args: ITargetApplicationChosenEventArgs); safecall;
  end;

  // Data request manager
  TDataRequest = class
  private
    FInterface: IDataRequest;

    // Getters
    function GetDeadline: TDateTime;
    function GetRequestedOperation: DataPackageOperation;

    function GetApplicationName: string;
    function GetDescription: string;
    function GetFileTypes: TArray<string>;
    function GetThumbnail: TGraphic;
    function GetTitle: string;

    // Setters
    procedure SetApplicationName(const Value: string);
    procedure SetDescription(const Value: string);
    procedure SetFileTypes(const Value: TArray<string>);
    procedure SetThumbnail(const Value: TGraphic);
    procedure SetTitle(const Value: string);

    procedure SetText(const Value: string);
    procedure SetURI(const Value: string);
    procedure SetHTMLText(const Value: string);
    procedure SetRTFText(const Value: string);
    procedure SetBitmap(const Value: TGraphic);
    procedure SetFiles(const Value: TArray<string>);

  public
    property Interfaced: IDataRequest read FInterface;

    // Properties
    property ApplicationName: string read GetApplicationName write SetApplicationName;
    property Title: string read GetTitle write SetTitle;
    property Description: string read GetDescription write SetDescription;
    property Thumbnail: TGraphic read GetThumbnail write SetThumbnail;
    property FileTypes: TArray<string> read GetFileTypes write SetFileTypes;

    property Text: string write SetText;
    property URI: string write SetURI;
    property HTMLText: string write SetHTMLText;
    property RTFText: string write SetRTFText;
    property Bitmap: TGraphic write SetBitmap;
      property Graphic: TGraphic write SetBitmap; {alias}
    property Files: TArray<string> write SetFiles;

    property Deadline: TDateTime read GetDeadline;
    property RequestedOperation: DataPackageOperation read GetRequestedOperation;

    // Utils
    procedure MarkDeferralComplete;
    procedure MarkFailure(FailureMessage: string);

    // Constructors
    constructor Create(ADataRequest: IDataRequest);
    destructor Destroy; override;
  end;

  // Manager
  TWindowsSharingManger = class
  private
    FInterface: IDataTransferManager; // Manager
    FWindowHandle: HWND;

    FOnDataRequested: TDataTransferManagerDataRequestedEvent;
    FOnTargetApplicationChosen: TDataTransferManagerTargetApplicationChosenEvent;

  public
    property Interfaced: IDataTransferManager read FInterface;

    // Info
    property WindowHandle: HWND read FWindowHandle;

    // Events
    procedure Execute;

    // Constructors
    constructor Create(AWindowHandle: HWND); virtual;
    destructor Destroy; override;
  end;

  TShareData = class
  strict private
    FText, FURI, FHTML, FRTF: string;
    FBitmap: TGraphic;
    FFiles: TArray<string>;

  public
    property Text: string read FText write FText;
    property URI: string read FURI write FURI;

    {The following text types are used when possible, otherwise plain TEXT is used}
    property TextHTML: string read FHTML write FHTML;
    property TextRTF: string read FRTF write FRTF;

    property Graphic: TGraphic read FBitmap write FBitmap;
    property Files: TArray<string> read FFiles write FFiles;
  end;

  TWindowsSharingMangerPredefined = class(TWindowsSharingManger)
  type
    TDataTransferManagerDataRequestedEventEx = class(TDataTransferManagerDataRequestedEvent)
    protected
      Owner: TWindowsSharingMangerPredefined;

      procedure Invoke(sender: IDataTransferManager; args: IDataRequestedEventArgs); override; safecall;
    end;
  private
    FAppName, FTitle, FDescription: string;
    FThumbnail: TGraphic;

    FData: TShareData;

  public
    // Properties
    property AppName: string read FAppName write FAppName;
    property Title: string read FTitle write FTitle;
    property Description: string read FDescription write FDescription;
    property Thumbnail: TGraphic read FThumbnail write FThumbnail;

    property Data: TShareData read FData write FData;

    // Constructors
    constructor Create(AWindowHandle: HWND); override;
    destructor Destroy; override;
  end;

implementation


{ TWindowsSharingManger }

constructor TWindowsSharingManger.Create(AWindowHandle: HWND);
begin
  // Info
  FWindowHandle := AWindowHandle;

  // Interface
  FInterface := TDataTransferManager.Interop.GetForWindow(WindowHandle, IID_IDataTransferManager);

  // Events
  FOnDataRequested := TDataTransferManagerDataRequestedEvent.Create(Self);
  FOnTargetApplicationChosen := TDataTransferManagerTargetApplicationChosenEvent.Create(Self);
end;

destructor TWindowsSharingManger.Destroy;
begin
  // Unregister events
  TSubscriptionEventHandlerBase.TryMultiUnsubscribe([
    FOnDataRequested,
    FOnTargetApplicationChosen
  ]);
  FOnDataRequested := nil;
  FOnTargetApplicationChosen := nil;

  // Clear main interface
  FInterface := nil;

  inherited;
end;

procedure TWindowsSharingManger.Execute;
begin
  TDataTransferManager.Interop.ShowShareUIForWindow( FWindowHandle );
end;

{ TDataTransferManagerDataRequestedEvent }

procedure TDataTransferManagerDataRequestedEvent.Invoke(
  sender: IDataTransferManager; args: IDataRequestedEventArgs);
begin
  const Request = TDataRequest.Create(args.Request);
  try
    for var I := 0 to Count-1 do
      if Assigned(Items[I]) then
        Items[I]( Parent, Request );

    // Completed
    Request.MarkDeferralComplete;
  finally
    Request.Free;
  end;
end;

procedure TDataTransferManagerDataRequestedEvent.Subscribe;
begin
  inherited;
  Token := Parent.FInterface.add_DataRequested( Self );
end;

procedure TDataTransferManagerDataRequestedEvent.Unsubscribe;
begin
  inherited;
  Parent.FInterface.remove_DataRequested( Token );
end;

{ TDataTransferManagerTargetApplicationChosenEvent }

procedure TDataTransferManagerTargetApplicationChosenEvent.Invoke(
  sender: IDataTransferManager; args: ITargetApplicationChosenEventArgs);
begin
  const S = args.ApplicationName.ToStringAndDestroy;

  for var I := 0 to Count-1 do
    if Assigned(Items[I]) then
      Items[I]( Parent, S );
end;

procedure TDataTransferManagerTargetApplicationChosenEvent.Subscribe;
begin
  inherited;
  Token := Parent.FInterface.add_TargetApplicationChosen( Self );
end;

procedure TDataTransferManagerTargetApplicationChosenEvent.Unsubscribe;
begin
  inherited;
  Parent.FInterface.remove_TargetApplicationChosen( Token );
end;

{ TDataRequest }

constructor TDataRequest.Create(ADataRequest: IDataRequest);
begin
  FInterface := ADataRequest;
end;

destructor TDataRequest.Destroy;
begin
  FInterface := nil;
  inherited;
end;

function TDataRequest.GetApplicationName: string;
begin
  Result := FInterface.Data.Properties.ApplicationName.ToStringAndDestroy;
end;

function TDataRequest.GetDeadline: TDateTime;
begin
  Result := DateTimeToTDateTime( FInterface.Deadline );
end;

function TDataRequest.GetDescription: string;
begin
  Result := FInterface.Data.Properties.Description.ToStringAndDestroy;
end;

function TDataRequest.GetFileTypes: TArray<string>;
begin
  Result := TStringVectorManager.ToArray( FInterface.Data.Properties.FileTypes );
end;

function TDataRequest.GetRequestedOperation: DataPackageOperation;
begin
  Result := FInterface.Data.RequestedOperation;
end;

function TDataRequest.GetThumbnail: TGraphic;
begin
  if FInterface.Data.Properties.Thumbnail = nil then
    Exit(nil);
  Result := TRandomAccessStreamReferenceManager.ReadGraphic(FInterface.Data.Properties.Thumbnail);
end;

function TDataRequest.GetTitle: string;
begin
  Result := FInterface.Data.Properties.Title.ToStringAndDestroy;
end;

procedure TDataRequest.MarkDeferralComplete;
begin
  FInterface.GetDeferral.Complete;
end;

procedure TDataRequest.MarkFailure(FailureMessage: string);
begin
  FInterface.FailWithDisplayText( HString.Create(FailureMessage) );
end;

procedure TDataRequest.SetApplicationName(const Value: string);
begin
  FInterface.Data.Properties.ApplicationName := HString.Create(Value);
end;

procedure TDataRequest.SetBitmap(const Value: TGraphic);
begin
  FInterface.Data.SetBitmap(
    TRandomAccessStreamReferenceManager.WriteGraphic( Value )
   );
end;

procedure TDataRequest.SetDescription(const Value: string);
begin
  FInterface.Data.Properties.Description := HString.Create(Value);
end;

procedure TDataRequest.SetFiles(const Value: TArray<string>);
//var
  //Items: IIterable_1__IStorageItem;
  //Enum: TEnumerator<IStorageItem>;
begin
  raise Exception.Create('Not implemented.');
  {
  Enum := TEnumerator<IStorageItem>.Create;

  FInterface.Data.SetStorageItems( Items, true );

  }
end;

procedure TDataRequest.SetFileTypes(const Value: TArray<string>);
begin
  TStringVectorManager.WriteArrayTo(Value, FInterface.Data.Properties.FileTypes)
end;

procedure TDataRequest.SetHTMLText(const Value: string);
begin
  FInterface.Data.SetHtmlFormat( HString.Create(Value) );
end;

procedure TDataRequest.SetRTFText(const Value: string);
begin
  FInterface.Data.SetRtf( HString.Create(Value) );
end;

procedure TDataRequest.SetText(const Value: string);
begin
  FInterface.Data.SetText( HString.Create(Value) );
end;

procedure TDataRequest.SetThumbnail(const Value: TGraphic);
begin
  FInterface.Data.Properties.Thumbnail := TRandomAccessStreamReferenceManager.WriteGraphic(Value);
end;

procedure TDataRequest.SetTitle(const Value: string);
begin
  FInterface.Data.Properties.Title := HString.Create(Value);
end;

procedure TDataRequest.SetURI(const Value: string);
begin
  FInterface.Data.SetUri( TURI.CreateUri( HString.Create(Value) ) );
end;

{ TWindowsSharingMangerPredefined.TDataTransferManagerDataRequestedEventEx }

procedure TWindowsSharingMangerPredefined.TDataTransferManagerDataRequestedEventEx.Invoke(
  sender: IDataTransferManager; args: IDataRequestedEventArgs);
begin
  const Request = TDataRequest.Create(args.Request);
  try
    Request.ApplicationName := Owner.FAppName;
    Request.Title := Owner.FTitle;
    Request.Description := Owner.FDescription;
    if Owner.Thumbnail <> nil then
      Request.Thumbnail := Owner.Thumbnail;

    if Owner.Data.Text <> '' then
      Request.Text := Owner.Data.Text;
    if Owner.Data.URI <> '' then
      Request.URI := Owner.Data.URI;
    if Owner.Data.TextHTML <> '' then
      Request.HTMLText := Owner.Data.TextHTML;
    if Owner.Data.TextRTF <> '' then
      Request.RTFText := Owner.Data.TextRTF;
    if Owner.Data.Graphic <> nil then
      Request.Graphic := Owner.Data.Graphic;
    if Length(Owner.Data.Files) > 0 then
      Request.Files := Owner.Data.Files;

    // Ensure functinality
    if Request.ApplicationName = '' then
      Request.ApplicationName := TCurrentProcess.GetAppModuleName;
    if Request.Title = '' then
      Request.Title := Format('Share from "%S"', [TCurrentProcess.GetAppModuleName]);

    // Inherit
    inherited;
  finally
    Request.Free;
  end;
end;

{ TWindowsSharingMangerPredefined }

constructor TWindowsSharingMangerPredefined.Create(AWindowHandle: HWND);
begin
  inherited;

  FData := TShareData.Create;

  // Custom on data
  FOnDataRequested := nil;
  FOnDataRequested := TDataTransferManagerDataRequestedEventEx.Create(Self);
  FOnDataRequested.AlwaysSubscribed := true;

  TDataTransferManagerDataRequestedEventEx(FOnDataRequested).Owner := Self;
end;

destructor TWindowsSharingMangerPredefined.Destroy;
begin
  FreeAndNil( FData );

  inherited;
end;

end.
