{***********************************************************}
{               Codruts Windows Runtime Storage             }
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

unit Cod.WindowsRT.Storage;

interface
uses
  // System
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Forms, IOUtils, System.Generics.Collections, Dialogs, Winapi.ActiveX,
  Win.ComObj, DateUtils, Math,

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
  [WinRTClassNameAttribute('Windows.Storage.Streams.InMemoryRandomAccessStream')]
  IInMemoryRandomAccessStream = interface(IRandomAccessStream)
  ['{905A0FE1-BC53-11DF-8C49-001E4FC686DA}']
  end;

  // Storage file
  [WinRTClassNameAttribute(SWindows_Storage_StorageFile)]
  IStorageFileStatics = interface(IInspectable)
  ['{5984C710-DAF2-43C8-8BB4-A4D3EACFD03F}']
    function GetFileFromPathAsync(filePath: HSTRING): IAsyncOperation_1__IStorageFile; safecall;
  end;

  [WinRTClassNameAttribute(SWindows_Storage_StorageFolder)]
  IStorageFolderStatics = interface(IInspectable)
  ['{08F327FF-85D5-48B9-AEE9-28511E339F9F}']
    function GetFolderFromPathAsync(filePath: HSTRING): IAsyncOperation_1__IStorageFolder; safecall;
  end;

  // References
  TStorageFileReference = class(TWinRTGenericImportS<IStorageFileStatics>)
  public
    // -> IRandomAccessStreamReferenceStatics
    function GetFileFromPathAsync(filePath: HSTRING): IAsyncOperation_1__IStorageFile; safecall;
  end;
  TStorageFolderReference = class(TWinRTGenericImportS<IStorageFolderStatics>)
  public
    // -> IRandomAccessStreamReferenceStatics
    function GetFolderFromPathAsync(path: HSTRING): IAsyncOperation_1__IStorageFolder; safecall;
  end;

  //
  TStorageFile = class
    class function CreateFromPath(Path: string): IStorageFile; static;
  end;
  TStorageFolder = class
    class function CreateFromPath(Path: string): IStorageFolder; static;
  end;
  TStorageItem = class
    class function QueryFromInspectable(Item: IInspectable): IStorageItem; static;
  end;

  // In Memory Random Access Stream
  TInMemoryRandomAccessStream = class(TWinRTGenericImportI<IInMemoryRandomAccessStream>) end;

// IBuffer utilities
function BufferToBytes(Buffer: IBuffer): TBytes;
function BytesToBuffer(Bytes: TBytes): IBuffer;

// RandomAccessStream
function CreateRandomAccessStream: IRandomAccessStream;

function RandomAccessStreamRead(Stream: IRandomAccessStream; From, Length: int64): TBytes;
function RandomAccessStreamGetContents(Stream: IRandomAccessStream): TBytes;

procedure RandomAccessStreamWrite(Stream: IRandomAccessStream; AtPosition: int64; Data: TBytes);
procedure RandomAccessStreamAppend(Stream: IRandomAccessStream; Data: TBytes);
function RandomAccessStreamMakeWithData(Data: TBytes): IRandomAccessStream;

implementation

function BufferToBytes(Buffer: IBuffer): TBytes;
var
  Reader: IDataReader;
begin
  // Get reader
  Reader := TDataReader.FromBuffer(Buffer);

  // Read to bytes
  SetLength(Result, Buffer.Length);

  // Read bytes
  Reader.ReadBytes(Buffer.Length, @Result[0]);
end;

function BytesToBuffer(Bytes: TBytes): IBuffer;
var
  Writer: IDataWriter;
begin
  // Create writer
  Writer := TDataWriter.Create;

  // Write data
  Writer.WriteBytes(Length(Bytes), @Bytes[0]);

  Result := Writer.DetachBuffer;
end;

function CreateRandomAccessStream: IRandomAccessStream;
begin
  Result := TInMemoryRandomAccessStream.Create;
  // LEGACY STREAM CREATION VERSION
  {begin
  const Item = TInstanceFactory.CreateNamed<IInspectable>('Windows.Storage.Streams.InMemoryRandomAccessStream');

  if Supports(Item, IRandomAccessStream) then
    Item.QueryInterface(IRandomAccessStream, Result);}
end;

function RandomAccessStreamRead(Stream: IRandomAccessStream; From, Length: int64): TBytes;
var
  Buffer: IBuffer;
begin
  if not Stream.CanRead then
    raise Exception.Create('Stream does not support reading.');

  // Make buffer
  Buffer := TBuffer.Create( Length );

  // Get data async
  TAsyncAwait.Await(
    Stream.GetInputStreamAt(From).ReadAsync(Buffer, Length, InputStreamOptions.None)
    );

  // Convert
  Result := BufferToBytes(Buffer);
end;

function RandomAccessStreamGetContents(Stream: IRandomAccessStream): TBytes;
begin
  Result := RandomAccessStreamRead(Stream, 0, Stream.Size);
end;

procedure RandomAccessStreamWrite(Stream: IRandomAccessStream; AtPosition: int64; Data: TBytes);
var
  NewSize: integer;
  Buffer: IBuffer;
begin
  NewSize := Math.Max(integer(Stream.Size), AtPosition+Length(Data));
  Stream.Size := NewSize;

  // Buffer
  Buffer := BytesToBuffer( Data );

  // Get data async
  TAsyncAwait.Await(
    Stream.GetOutputStreamAt(AtPosition).WriteAsync(Buffer)
    );

  // Clear
  Buffer := nil;
end;

procedure RandomAccessStreamAppend(Stream: IRandomAccessStream; Data: TBytes);
begin
  RandomAccessStreamWrite(Stream, Stream.Size, Data);
end;

function RandomAccessStreamMakeWithData(Data: TBytes): IRandomAccessStream;
begin
  Result := CreateRandomAccessStream;

  RandomAccessStreamAppend(Result, Data);
end;

{ TStorageFileReference }

function TStorageFileReference.GetFileFromPathAsync(
  filePath: HSTRING): IAsyncOperation_1__IStorageFile;
begin
  Result := Statics.GetFileFromPathAsync(filePath);
end;

{ TStorageFile }

class function TStorageFile.CreateFromPath(Path: string): IStorageFile;
var
  STR: HSTRING;
  Event: IAsyncOperation_1__IStorageFile;
begin
  STR := HSTRING.Create( Path );
  try
    // Get event
    Event := TStorageFileReference.Statics.GetFileFromPathAsync( STR );
  finally
    STR.Free;
  end;

  // Await finalization
  Await(Event, Application.ProcessMessages);

  // Result
  Result := Event.GetResults;
end;

{ TStorageFolder }

class function TStorageFolder.CreateFromPath(Path: string): IStorageFolder;
var
  STR: HSTRING;
  Event: IAsyncOperation_1__IStorageFolder;
begin
  STR := HSTRING.Create( Path );
  try
    // Get event
    Event := TStorageFolderReference.Statics.GetFolderFromPathAsync( STR );
  finally
    STR.Free;
  end;

  // Await finalization
  Await(Event, Application.ProcessMessages);

  // Result
  Result := Event.GetResults;
end;

{ TStorageFolderReference }

function TStorageFolderReference.GetFolderFromPathAsync(
  path: HSTRING): IAsyncOperation_1__IStorageFolder;
begin
  Result := Statics.GetFolderFromPathAsync(path);
end;

{ TStorageItem }

class function TStorageItem.QueryFromInspectable(
  Item: IInspectable): IStorageItem;
begin
  Result := nil;
  if Supports(Item, IStorageItem) then
    Item.QueryInterface(IStorageItem, Result);
end;

end.
