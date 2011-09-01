(*
  Copyright (c) 2011, Stefan Glienke
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

unit DSharp.Core.Plugins;

interface

uses
  Generics.Collections,
  Rtti,
  TypInfo;

function Supports(const ModuleName: string; IID: TGUID; out Intf): Boolean; overload;

type
  TObjectHelper = class helper for TObject
  public
    function AsType<T: IInterface>: T;
  end;

  TVirtualObjectInterface = class(TVirtualInterface)
  private
    FInstance: TObject;
    FMethods: TDictionary<Integer, TRttiMethod>;
    procedure DoInvoke(Method: TRttiMethod;
      const Args: TArray<TValue>; out Result: TValue);
  public
    constructor Create(PIID: PTypeInfo; AInstance: TObject);
    destructor Destroy; override;
  end;

implementation

uses
  RTLConsts,
  SysUtils,
  Windows;

var
  Context: TRttiContext;

type
  TVirtualLibraryInterface = class(TVirtualInterface)
  private
    FLibrayHandle: THandle;
    FMethods: TDictionary<string, Pointer>;
    procedure DoInvoke(Method: TRttiMethod;
      const Args: TArray<TValue>; out Result: TValue);
  public
    constructor Create(PIID: PTypeInfo; ALibraryHandle: THandle);
    destructor Destroy; override;
  end;

function Supports(const ModuleName: string; IID: TGUID; out Intf): Boolean; overload;
var
  LType: TRttiType;
  LLibraryHandle: THandle;
  LVirtualLibraryInterface: IInterface;
begin
  Result := False;
  LLibraryHandle := 0;
  try
    LLibraryHandle := LoadLibrary(PChar(ModuleName));
    if LLibraryHandle <> 0 then
    begin
      LType := nil;
      // bit ugly but no other way to get from guid to the interface
      for LType in Context.GetTypes do
        if (LType is TRttiInterfaceType)
          and (TRttiInterfaceType(LType).GUID = IID) then
          Break;
      if Assigned(LType) then
        LVirtualLibraryInterface := TVirtualLibraryInterface.Create(
          LType.Handle, LLibraryHandle);
      Result := Supports(
        LVirtualLibraryInterface, TRttiInterfaceType(LType).GUID, Intf);
    end;
  except
    FreeLibrary(LLibraryHandle);
  end;
end;

{ TVirtualLibraryInterface }

constructor TVirtualLibraryInterface.Create(PIID: PTypeInfo; ALibraryHandle: THandle);
var
  LType: TRttiType;
  LMethods: TArray<TRttiMethod>;
  LMethod: TRttiMethod;
  LMethodPointer: Pointer;
begin
  FLibrayHandle := ALibraryHandle;
  FMethods := TDictionary<string, Pointer>.Create();
  LType := Context.GetType(PIID);
  LMethods := LType.GetMethods;
  for LMethod in LMethods do
  begin
    if LMethod.VirtualIndex > 2 then
    begin
      LMethodPointer := GetProcAddress(FLibrayHandle, PChar(LMethod.Name));
      if Assigned(LMethodPointer) then
        FMethods.Add(LMethod.Name, LMethodPointer)
      else
        raise ENotSupportedException.CreateFmt('Method not found: "%s"', [LMethod.Name]);
    end;
  end;

  inherited Create(PIID, DoInvoke);
end;

destructor TVirtualLibraryInterface.Destroy;
begin
  FMethods.Free();
  FreeLibrary(FLibrayHandle);
  inherited;
end;

procedure TVirtualLibraryInterface.DoInvoke(Method: TRttiMethod;
  const Args: TArray<TValue>; out Result: TValue);
var
  i: Integer;
  LArgs: TArray<TValue>;
  LParams: TArray<TRttiParameter>;
begin
  LParams := Method.GetParameters();

  if Pred(Length(Args)) <> Length(LParams) then
    raise EInvocationError.CreateRes(@SParameterCountMismatch);

  SetLength(LArgs, Length(LParams));

  for i := Low(LArgs) to High(LArgs) do
  begin
    if LParams[i].ParamType = nil then
    begin
      LArgs[i] := TValue.From<Pointer>(Args[Succ(i)].GetReferenceToRawData);
    end
    else
    begin
      if LParams[i].Flags * [pfVar, pfOut] <> [] then
      begin
        if LParams[i].ParamType.Handle <> Args[Succ(i)].TypeInfo then
          raise EInvalidCast.CreateRes(@SByRefArgMismatch);
        LArgs[i] := TValue.From<Pointer>(Args[Succ(i)].GetReferenceToRawData);
      end
      else
      begin
        LArgs[i] := Args[Succ(i)].Cast(LParams[i].ParamType.Handle);
      end;
    end;
  end;

  if Method.ReturnType = nil then
  begin
    Result := Invoke(FMethods[Method.Name], LArgs, Method.CallingConvention, nil);
  end
  else
  begin
    Result := Invoke(FMethods[Method.Name], LArgs, Method.CallingConvention, Method.ReturnType.Handle);
  end;
end;

{ TVirtualDuckInterface }

constructor TVirtualObjectInterface.Create(PIID: PTypeInfo; AInstance: TObject);
var
  i: Integer;
  LType: TRttiType;
  LMethods: TArray<TRttiMethod>;
  LMethod: TRttiMethod;
  LInstanceType: TRttiType;
  LInstanceMethod: TRttiMethod;
  LParams1, LParams2: TArray<TRttiParameter>;
  LFound: Boolean;
begin
  FInstance := AInstance;
  FMethods := TObjectDictionary<Integer, TRttiMethod>.Create([doOwnsValues]);
  LType := Context.GetType(PIID);
  LMethods := LType.GetMethods;
  LInstanceType := Context.GetType(AInstance.ClassInfo);
  for LMethod in LMethods do
  begin
    if LMethod.VirtualIndex > 2 then
    begin
      for LInstanceMethod in LInstanceType.GetMethods() do
      begin
        if SameText(LMethod.Name, LInstanceMethod.Name) then
        begin
          LParams1 := LMethod.GetParameters();
          LParams2 := LInstanceMethod.GetParameters();
          if Length(LParams1) = Length(LParams2) then
          begin
            LFound := True;
            for i := Low(LParams1) to High(LParams1) do
            begin
              if LParams1[i].ParamType <> LParams2[i].ParamType then
              begin
                LFound := False;
                Break;
              end;
            end;

            if LFound then
            begin
              FMethods.Add(LMethod.VirtualIndex, LInstanceMethod);
              Break;
            end;
          end;
        end;
      end;
    end;
  end;

  inherited Create(PIID, DoInvoke);
end;

destructor TVirtualObjectInterface.Destroy;
begin
  FMethods.Free();
  inherited;
end;

procedure TVirtualObjectInterface.DoInvoke(Method: TRttiMethod;
  const Args: TArray<TValue>; out Result: TValue);
var
  i: Integer;
  LArgs: TArray<TValue>;
  LParams: TArray<TRttiParameter>;
begin
  if FMethods.ContainsKey(Method.VirtualIndex) then
  begin
    LParams := Method.GetParameters();

    if Pred(Length(Args)) <> Length(LParams) then
      raise EInvocationError.CreateRes(@SParameterCountMismatch);

    SetLength(LArgs, Length(LParams));

    for i := Low(LArgs) to High(LArgs) do
    begin
      if LParams[i].ParamType = nil then
      begin
        LArgs[i] := TValue.From<Pointer>(Args[Succ(i)].GetReferenceToRawData);
      end
      else
      begin
        if LParams[i].Flags * [pfVar, pfOut] <> [] then
        begin
          if LParams[i].ParamType.Handle <> Args[Succ(i)].TypeInfo then
            raise EInvalidCast.CreateRes(@SByRefArgMismatch);
          LArgs[i] := TValue.From<Pointer>(Args[Succ(i)].GetReferenceToRawData);
        end
        else
        begin
          LArgs[i] := Args[Succ(i)].Cast(LParams[i].ParamType.Handle);
        end;
      end;
    end;

    if FMethods[Method.VirtualIndex].IsClassMethod then
    begin
      Result := FMethods[Method.VirtualIndex].Invoke(FInstance.ClassType, LArgs);
    end
    else
    begin
      Result := FMethods[Method.VirtualIndex].Invoke(FInstance, LArgs);
    end;
  end;
end;

{ TObjectHelper }

function TObjectHelper.AsType<T>: T;
var
  LContext: TRttiContext;
  LType: TRttiType;
  LVirtualInterface: IInterface;
begin
  LType := LContext.GetType(TypeInfo(T));
  if LType is TRttiInterfaceType then
  begin
    LVirtualInterface := TVirtualObjectInterface.Create(LType.Handle, Self);
    Supports(LVirtualInterface, TRttiInterfaceType(LType).GUID, Result);
  end;
end;

end.