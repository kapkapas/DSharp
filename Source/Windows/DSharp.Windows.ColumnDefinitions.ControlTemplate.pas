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

unit DSharp.Windows.ColumnDefinitions.ControlTemplate;

interface

uses
  DSharp.Windows.ColumnDefinitions,
  DSharp.Windows.ControlTemplates;

type
  TColumnDefinitionsControlTemplate = class(TControlTemplate)
  protected
    FColumnDefinitions: TColumnDefinitions;
  public
    constructor Create(AColumnDefinitions: TColumnDefinitions);

    function CustomDraw(const Item: TObject; const ColumnIndex: Integer;
      TargetCanvas: TCanvas; CellRect: TRect; ImageList: TCustomImageList;
      DrawMode: TDrawMode): Boolean; override;
    function GetImageIndex(const Item: TObject;
      const ColumnIndex: Integer): Integer; override;

    function GetText(const Item: TObject; const ColumnIndex: Integer): string; override;
    procedure SetText(const Item: TObject; const ColumnIndex: Integer;
      const Value: string); override;

    property ColumnDefinitions: TColumnDefinitions read FColumnDefinitions;
  end;

implementation

uses
  DSharp.Core.Expressions;

{ TColumnDefinitionsControlTemplate }

constructor TColumnDefinitionsControlTemplate.Create(
  AColumnDefinitions: TColumnDefinitions);
begin
  inherited Create;
  FColumnDefinitions := AColumnDefinitions;
end;

function TColumnDefinitionsControlTemplate.CustomDraw(const Item: TObject;
  const ColumnIndex: Integer; TargetCanvas: TCanvas; CellRect: TRect;
  ImageList: TCustomImageList; DrawMode: TDrawMode): Boolean;
begin
  if Assigned(Item) and Assigned(FColumnDefinitions)
    and (ColumnIndex < FColumnDefinitions.Count) and (ColumnIndex > -1) then
  begin
    if Assigned(FColumnDefinitions[ColumnIndex].OnCustomDraw) then
    begin
      Result := FColumnDefinitions[ColumnIndex].OnCustomDraw(FColumnDefinitions.Owner,
        FColumnDefinitions[ColumnIndex], Item,
        TargetCanvas, CellRect, ImageList, DrawMode);
    end
    else
    begin
      Result := inherited;
    end;
  end
  else
  begin
    Result := inherited;
  end;
end;

function TColumnDefinitionsControlTemplate.GetImageIndex(const Item: TObject;
  const ColumnIndex: Integer): Integer;
var
  LColumnDefinition: TColumnDefinition;
begin
  if Assigned(Item) and Assigned(FColumnDefinitions)
    and (ColumnIndex < FColumnDefinitions.Count) and (ColumnIndex > -1) then
  begin
    LColumnDefinition := FColumnDefinitions[ColumnIndex];

    if Assigned(LColumnDefinition.OnGetImageIndex) then
    begin
      Result := LColumnDefinition.OnGetImageIndex(
        FColumnDefinitions.Owner, LColumnDefinition, Item);
    end else
    if Assigned(LColumnDefinition.ImageIndexPropertyExpression) then
    begin
      (LColumnDefinition.ImageIndexPropertyExpression.Expression as IParameterExpression).Value := Item;
      Result := LColumnDefinition.ImageIndexPropertyExpression.Value.AsOrdinal;
    end else
    begin
      Result := inherited;
    end;
  end
  else
  begin
    Result := inherited;
  end;
end;

function TColumnDefinitionsControlTemplate.GetText(const Item: TObject;
  const ColumnIndex: Integer): string;
var
  LColumnDefinition: TColumnDefinition;
begin
  if Assigned(Item) and Assigned(FColumnDefinitions)
    and (ColumnIndex < FColumnDefinitions.Count) and (ColumnIndex > -1) then
  begin
    LColumnDefinition := FColumnDefinitions[ColumnIndex];

    if Assigned(LColumnDefinition.OnGetText) then
    begin
      Result := LColumnDefinition.OnGetText(
        FColumnDefinitions.Owner, LColumnDefinition, Item);
    end else
    if Assigned(LColumnDefinition.TextPropertyExpression) then
    begin
      (LColumnDefinition.TextPropertyExpression.Expression as IParameterExpression).Value := Item;
      Result := LColumnDefinition.TextPropertyExpression.Value.ToString;
    end else
    begin
      Result := inherited;
    end;
  end
  else
  begin
    Result := inherited;
  end;
end;

procedure TColumnDefinitionsControlTemplate.SetText(const Item: TObject;
  const ColumnIndex: Integer; const Value: string);
var
  LColumnDefinition: TColumnDefinition;
begin
  if Assigned(Item) and Assigned(FColumnDefinitions)
    and (ColumnIndex < FColumnDefinitions.Count) and (ColumnIndex > -1) then
  begin
    LColumnDefinition := FColumnDefinitions[ColumnIndex];

    if Assigned(LColumnDefinition.OnSetText) then
    begin
      LColumnDefinition.OnSetText(
        FColumnDefinitions.Owner, LColumnDefinition, Item, Value);
    end else
    if Assigned(LColumnDefinition.TextPropertyExpression) then
    begin
      (LColumnDefinition.TextPropertyExpression.Expression as IParameterExpression).Value := Item;
      LColumnDefinition.TextPropertyExpression.Value := Value;
    end;
  end;
end;

end.