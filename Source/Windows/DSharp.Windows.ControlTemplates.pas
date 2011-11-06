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

unit DSharp.Windows.ControlTemplates;

interface

uses
  DSharp.Core.DataTemplates,
  Controls,
  Graphics,
  ImgList,
  Types;

type
  TDrawMode = (dmBeforeCellPaint, dmAfterCellPaint, dmPaintText);

  IControlTemplate = interface(IDataTemplate)
    ['{D8A84E8C-DE21-4DDC-847A-4257A4493A28}']
    function CustomDraw(const Item: TObject; const ColumnIndex: Integer;
      TargetCanvas: TCanvas; CellRect: TRect; ImageList: TCustomImageList;
      DrawMode: TDrawMode): Boolean;
  end;

  TControlTemplate = class(TDataTemplate, IControlTemplate)
  public
    function CustomDraw(const Item: TObject; const ColumnIndex: Integer;
      TargetCanvas: TCanvas; CellRect: TRect; ImageList: TCustomImageList;
      DrawMode: TDrawMode): Boolean; virtual;
  end;

  TControlTemplate<T: class> = class(TDataTemplate<T>, IControlTemplate)
  public
    function CustomDraw(const Item: TObject; const ColumnIndex: Integer;
      TargetCanvas: TCanvas; CellRect: TRect; ImageList: TCustomImageList;
      DrawMode: TDrawMode): Boolean; overload;
    function CustomDraw(const Item: T; const ColumnIndex: Integer;
      TargetCanvas: TCanvas; CellRect: TRect; ImageList: TCustomImageList;
      DrawMode: TDrawMode): Boolean; reintroduce; overload; virtual;
  end;

implementation

{ TControlTemplate }

function TControlTemplate.CustomDraw(const Item: TObject;
  const ColumnIndex: Integer; TargetCanvas: TCanvas; CellRect: TRect;
  ImageList: TCustomImageList; DrawMode: TDrawMode): Boolean;
begin
  Result := False;
end;

{ TControlTemplate<T> }

function TControlTemplate<T>.CustomDraw(const Item: TObject;
  const ColumnIndex: Integer; TargetCanvas: TCanvas; CellRect: TRect;
  ImageList: TCustomImageList; DrawMode: TDrawMode): Boolean;
begin
  Result := CustomDraw(T(Item), ColumnIndex,
    TargetCanvas, CellRect, ImageList, DrawMode);
end;

function TControlTemplate<T>.CustomDraw(const Item: T; const ColumnIndex: Integer;
  TargetCanvas: TCanvas; CellRect: TRect; ImageList: TCustomImageList;
  DrawMode: TDrawMode): Boolean;
begin
  TControlTemplate(Self).CustomDraw(Item, ColumnIndex,
    TargetCanvas, CellRect, ImageList, DrawMode);
end;


end.