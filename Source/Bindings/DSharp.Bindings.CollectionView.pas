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

unit DSharp.Bindings.CollectionView;

interface

uses
  Classes,
  DSharp.Bindings.Collections,
  DSharp.Collections,
  DSharp.Core.DataTemplates,
  DSharp.Core.PropertyChangedBase,
  DSharp.Core.Events,
  SysUtils;

type
  TCollectionView = class(TPropertyChangedBase, ICollectionView)
  protected
    FFilter: TPredicate<TObject>;
    FItemIndex: Integer;
    FItems: TStrings;
    FItemsSource: TList<TObject>;
    FItemTemplate: IDataTemplate;
    FOnCollectionChanged: TEvent<TCollectionChangedEvent>;

    procedure DoSourceCollectionChanged(Sender: TObject; Item: TObject;
      Action: TCollectionChangedAction); virtual;
    function GetCurrentItem: TObject; virtual;
    function GetFilter: TPredicate<TObject>; virtual;
    function GetItemsSource: TList<TObject>; virtual;
    function GetItemTemplate: IDataTemplate; virtual;
    function GetOnCollectionChanged: TEvent<TCollectionChangedEvent>;
    procedure SetCurrentItem(const Value: TObject); virtual;
    procedure SetFilter(const Value: TPredicate<TObject>); virtual;
    procedure SetItemsSource(const Value: TList<TObject>); virtual;
    procedure SetItemTemplate(const Value: IDataTemplate); virtual;
    procedure UpdateItems(AClearItems: Boolean = False); virtual;
  public
    property CurrentItem: TObject read GetCurrentItem write SetCurrentItem;
    property Filter: TPredicate<TObject> read GetFilter write SetFilter;
    property ItemsSource: TList<TObject> read GetItemsSource write SetItemsSource;
    property ItemTemplate: IDataTemplate read GetItemTemplate write SetItemTemplate;
    property OnCollectionChanged: TEvent<TCollectionChangedEvent>
      read GetOnCollectionChanged;
  end;

implementation

uses
  DSharp.Core.DataTemplates.Default;

{ TCollectionView }

procedure TCollectionView.DoSourceCollectionChanged(Sender, Item: TObject;
  Action: TCollectionChangedAction);
begin
  // implemented by child classes
end;

function TCollectionView.GetCurrentItem: TObject;
begin
  Result := nil;
end;

function TCollectionView.GetFilter: TPredicate<TObject>;
begin
  Result := FFilter;
end;

function TCollectionView.GetItemsSource: TList<TObject>;
begin
  Result := FItemsSource;
end;

function TCollectionView.GetItemTemplate: IDataTemplate;
begin
  if not Assigned(FItemTemplate) then
  begin
    FItemTemplate := TDefaultDataTemplate.Create();
  end;
  Result := FItemTemplate;
end;

function TCollectionView.GetOnCollectionChanged: TEvent<TCollectionChangedEvent>;
begin
  Result := FOnCollectionChanged.EventHandler;
end;

procedure TCollectionView.SetCurrentItem(const Value: TObject);
begin
  // not implemented yet
end;

procedure TCollectionView.SetFilter(const Value: TPredicate<TObject>);
begin
  FFilter := Value;
  UpdateItems(True);
end;

procedure TCollectionView.SetItemsSource(const Value: TList<TObject>);
var
  LNotifyCollectionChanged: INotifyCollectionChanged;
  LCollectionChanged: TEvent<TCollectionChangedEvent>;
begin
  if FItemsSource <> Value then
  begin
    if Supports(FItemsSource, INotifyCollectionChanged, LNotifyCollectionChanged) then
    begin
      LCollectionChanged := LNotifyCollectionChanged.OnCollectionChanged;
      LCollectionChanged.Remove(DoSourceCollectionChanged);
    end;

    FItemsSource := Value;

    if Assigned(FItemsSource)
      and Supports(FItemsSource, INotifyCollectionChanged, LNotifyCollectionChanged) then
    begin
      LCollectionChanged := LNotifyCollectionChanged.OnCollectionChanged;
      LCollectionChanged.Add(DoSourceCollectionChanged)
    end;
    UpdateItems(True);

    DoPropertyChanged('ItemsSource');
  end;
end;

procedure TCollectionView.SetItemTemplate(const Value: IDataTemplate);
begin
  FItemTemplate := Value;
  UpdateItems(False);
end;

procedure TCollectionView.UpdateItems(AClearItems: Boolean);
begin
  // implemented by child classes
end;

end.