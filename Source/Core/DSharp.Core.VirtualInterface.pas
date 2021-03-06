(*
  Copyright (c) 2011-2012, Stefan Glienke
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are met:

  - Redistributions of source code must retain the above copyright notice,
    this list of conditions and the following disclaimer.
  - Redistributions in binary form must reproduce the above copyright notice,
    this list of conditions and the following disclaimer in the documentation
    and/or other materials provided with the distribution.
  - Neither the name of this library nor the names of its contributors may be
    used to endorse or promote products derived from this software without
    specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
  POSSIBILITY OF SUCH DAMAGE.
*)

unit DSharp.Core.VirtualInterface;

interface

{$I DSharp.inc}

{$IFDEF CPUX64}
  {$MESSAGE WARN 'Not supported on 64-bit because of several bugs in Delphi'}
  // http://qc.embarcadero.com/wc/qcmain.aspx?d=102627
  // http://qc.embarcadero.com/wc/qcmain.aspx?d=99028
{$ENDIF}

uses
  DSharp.Core.MethodIntercept,
  Generics.Collections,
  Rtti,
{$IF CompilerVersion = 22}
  RttiPatch,
{$IFEND}
  TypInfo;

type
  TVirtualInterface = class(TInterfacedObject, IInterface)
  private
    FVirtualMethodTable: Pointer;
    FInstance: IInterface;
    FInterfaceID: TGUID;
    FMethodIntercepts: TMethodIntercepts;
    FOnInvoke: TMethodInvokeEvent;
    FTypeInfo: PTypeInfo;
    class var FContext: TRttiContext;
    function Virtual_AddRef: Integer; stdcall;
    function Virtual_Release: Integer; stdcall;
    function VirtualQueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
  protected
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
    function QueryInterface(const IID: TGUID; out Obj): HResult; virtual; stdcall;

    procedure DoInvoke(UserData: Pointer;
      const Args: TArray<TValue>; out Result: TValue);
    procedure ErrorProc;
  public
    constructor Create(TypeInfo: PTypeInfo); overload;
    constructor Create(TypeInfo: PTypeInfo;
      InvokeEvent: TMethodInvokeEvent); overload;
    destructor Destroy; override;
    property Instance: IInterface read FInstance write FInstance;
    property InterfaceID: TGUID read FInterfaceID;
    property OnInvoke: TMethodInvokeEvent read FOnInvoke write FOnInvoke;
    property TypeInfo: PTypeInfo read FTypeInfo;
  end;

implementation

uses
  RTLConsts,
  SysUtils;

{ TVirtualInterface }

constructor TVirtualInterface.Create(TypeInfo: PTypeInfo);
var
  i: Integer;
  LMaxVirtualIndex: SmallInt;
  LMethod: TRttiMethod;
  LMethods: TArray<TRttiMethod>;
  LType: TRttiType;
type
  PVtable = ^TVtable;
  TVtable = array[0..MaxInt div SizeOf(Pointer) - 1] of Pointer;
begin
  FTypeInfo := TypeInfo;
  LType := FContext.GetType(TypeInfo);
  FInterfaceID := TRttiInterfaceType(LType).GUID;
  FMethodIntercepts := TObjectList<TMethodIntercept>.Create();

  LMaxVirtualIndex := 2;
  LMethods := LType.GetMethods();

  for LMethod in LMethods do
  begin
    if LMaxVirtualIndex < LMethod.VirtualIndex then
    begin
      LMaxVirtualIndex := LMethod.VirtualIndex;
    end;
    FMethodIntercepts.Add(TMethodIntercept.Create(LMethod, DoInvoke));
  end;

  FVirtualMethodTable := AllocMem(SizeOf(Pointer) * (LMaxVirtualIndex + 1));

  PVtable(FVirtualMethodTable)^[0] := @TVirtualInterface.VirtualQueryInterface;
  PVtable(FVirtualMethodTable)^[1] := @TVirtualInterface.Virtual_AddRef;
  PVtable(FVirtualMethodTable)^[2] := @TVirtualInterface.Virtual_Release;

  for i := 0 to Pred(FMethodIntercepts.Count) do
  begin
    PVtable(FVirtualMethodTable)^[FMethodIntercepts[i].VirtualIndex] := FMethodIntercepts[i].CodeAddress;
  end;

  for i := 3 to LMaxVirtualIndex do
  begin
    if not Assigned(PVtable(FVirtualMethodTable)^[i]) then
    begin
      PVtable(FVirtualMethodTable)^[i] := @TVirtualInterface.ErrorProc;
    end;
  end;
end;

constructor TVirtualInterface.Create(TypeInfo: PTypeInfo;
  InvokeEvent: TMethodInvokeEvent);
begin
  Create(TypeInfo);
  FOnInvoke := InvokeEvent;
end;

destructor TVirtualInterface.Destroy;
begin
  if Assigned(FVirtualMethodTable) then
  begin
    FreeMem(FVirtualMethodTable);
  end;
  FMethodIntercepts.Free;
  inherited;
end;

procedure TVirtualInterface.DoInvoke(UserData: Pointer;
  const Args: TArray<TValue>; out Result: TValue);
begin
  if Assigned(FOnInvoke) then
  begin
    FOnInvoke(TMethodIntercept(UserData).Method, Args, Result);
  end;
end;

procedure TVirtualInterface.ErrorProc;
begin
  raise EInsufficientRtti.CreateRes(@SInsufficientRtti);
end;

function TVirtualInterface.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if IID = FInterfaceID then
  begin
    _AddRef();
    Pointer(Obj) := @FVirtualMethodTable;
    Result := S_OK;
  end
  else
  begin
    if Assigned(FInstance) then
    begin
      Result := FInstance.QueryInterface(IID, Obj);
    end
    else
    begin
      Result := inherited;
    end;
  end;
end;

function TVirtualInterface.VirtualQueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result := TVirtualInterface(PByte(Self) -
    (PByte(@Self.FVirtualMethodTable) - PByte(Self))).QueryInterface(IID, Obj);
end;

function TVirtualInterface.Virtual_AddRef: Integer;
begin
  Result := TVirtualInterface(PByte(Self) -
    (PByte(@Self.FVirtualMethodTable) - PByte(Self)))._AddRef();
end;

function TVirtualInterface.Virtual_Release: Integer;
begin
  Result := TVirtualInterface(PByte(Self) -
    (PByte(@Self.FVirtualMethodTable) - PByte(Self)))._Release();
end;

function TVirtualInterface._AddRef: Integer;
begin
  Result := inherited;
end;

function TVirtualInterface._Release: Integer;
begin
  Result := inherited;
end;

end.
