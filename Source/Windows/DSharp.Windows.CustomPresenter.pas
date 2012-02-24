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

unit DSharp.Windows.CustomPresenter;

interface

uses
  Classes,
  DSharp.Bindings.Collections,
  DSharp.Bindings.CollectionView,
  DSharp.Bindings.Notifications,
  DSharp.Collections,
  DSharp.Core.DataTemplates,
  DSharp.Core.Events,
  DSharp.Windows.ColumnDefinitions,
  Menus,
  SysUtils;

type
  TCustomPresenter = class(TComponent, ICollectionView, INotifyPropertyChanged)
  private
    FAction: TBasicAction;
    FColumnDefinitions: IColumnDefinitions;
    FImageList: TCustomImageList;
    FNotifyPropertyChanged: INotifyPropertyChanged;
    FOnDoubleClick: TNotifyEvent;
    FPopupMenu: TPopupMenu;
    FUpdateCount: Integer;
    FView: TCollectionView;
    procedure ReadColumnDefinitions(Reader: TReader);
    procedure SetColumnDefinitions(const Value: IColumnDefinitions);
    procedure SetImageList(const Value: TCustomImageList);
    procedure SetPopupMenu(const Value: TPopupMenu);
    property NotifyPropertyChanged: INotifyPropertyChanged
      read FNotifyPropertyChanged implements INotifyPropertyChanged;
    procedure WriteColumnDefinitions(Writer: TWriter);
  protected
    procedure DefineProperties(Filer: TFiler); override;
    procedure DoDblClick(Sender: TObject); virtual;
    procedure DoPropertyChanged(const APropertyName: string;
      AUpdateTrigger: TUpdateTrigger = utPropertyChanged);
    procedure DoSourceCollectionChanged(Sender: TObject; Item: TObject;
      Action: TCollectionChangedAction); virtual;
    function GetCurrentItem: TObject; virtual;
    procedure SetCurrentItem(const Value: TObject); virtual;
    procedure InitColumns; virtual;
    procedure InitControl; virtual;
    procedure InitEvents; virtual;
    procedure InitProperties; virtual;
    procedure Loaded; override;
    property UpdateCount: Integer read FUpdateCount;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;

    function GetItemTemplate(const Item: TObject): IDataTemplate; overload;
    procedure Refresh; virtual;

    property ColumnDefinitions: IColumnDefinitions
      read FColumnDefinitions write SetColumnDefinitions;
    property View: TCollectionView read FView implements ICollectionView;
  published
    property Action: TBasicAction read FAction write FAction;
    property ImageList: TCustomImageList read FImageList write SetImageList;
    property OnDoubleClick: TNotifyEvent read FOnDoubleClick write FOnDoubleClick;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
  end;

  TCollectionViewPresenterAdapter = class(TCollectionView)
  private
    FPresenter: TCustomPresenter;
  protected
    procedure DoItemPropertyChanged(ASender: TObject; APropertyName: string;
      AUpdateTrigger: TUpdateTrigger = utPropertyChanged); override;
    procedure DoSourceCollectionChanged(Sender: TObject; Item: TObject;
      Action: TCollectionChangedAction); override;
    function GetCurrentItem: TObject; override;
    procedure SetCurrentItem(const Value: TObject); override;
    procedure UpdateItems(AClearItems: Boolean = False); override;
  public
    constructor Create(Presenter: TCustomPresenter);
  end;

implementation

uses
  DSharp.Windows.ColumnDefinitions.ControlTemplate;

{ TCustomPresenter }

constructor TCustomPresenter.Create(AOwner: TComponent);
begin
  inherited;
  FNotifyPropertyChanged := TNotifyPropertyChanged.Create(Self);
  FView := TCollectionViewPresenterAdapter.Create(Self);

  FColumnDefinitions := TColumnDefinitions.Create(Self);
  FView.ItemTemplate := TColumnDefinitionsControlTemplate.Create(FColumnDefinitions);
end;

destructor TCustomPresenter.Destroy;
begin
  FView.Free();
  inherited;
end;

procedure TCustomPresenter.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TCustomPresenter.DefineProperties(Filer: TFiler);
begin
  inherited;
  Filer.DefineProperty('ColumnDefinitions', ReadColumnDefinitions, WriteColumnDefinitions, True);
end;

procedure TCustomPresenter.DoDblClick(Sender: TObject);
begin
  if Assigned(FOnDoubleClick) and Assigned(FAction)
    and not DelegatesEqual(@FOnDoubleClick, @FAction.OnExecute) then
  begin
    FOnDoubleClick(Self);
  end else
  if not (csDesigning in ComponentState) and Assigned(FAction) then
  begin
    FAction.Execute();
  end else
  if Assigned(FOnDoubleClick) then
  begin
    FOnDoubleClick(Self);
  end;
end;

procedure TCustomPresenter.DoPropertyChanged(const APropertyName: string;
  AUpdateTrigger: TUpdateTrigger);
begin
  NotifyPropertyChanged.DoPropertyChanged(APropertyName, AUpdateTrigger);
end;

procedure TCustomPresenter.DoSourceCollectionChanged(Sender, Item: TObject;
  Action: TCollectionChangedAction);
begin
  if FUpdateCount = 0 then
  begin
    Refresh();
  end;
end;

procedure TCustomPresenter.EndUpdate;
begin
  if FUpdateCount > 0 then
  begin
    Dec(FUpdateCount);
    if FUpdateCount = 0 then
    begin
      Refresh;
    end;
  end;
end;

function TCustomPresenter.GetCurrentItem: TObject;
begin
  Result := nil; // implemented by descendants
end;

function TCustomPresenter.GetItemTemplate(const Item: TObject): IDataTemplate;
begin
  Result := nil;

  if Assigned(FView.ItemTemplate) then
  begin
    Result := FView.ItemTemplate.GetItemTemplate(Item);
  end
end;

procedure TCustomPresenter.InitColumns;
begin
  // implemented by descendants
end;

procedure TCustomPresenter.InitControl;
begin
  InitColumns();
  InitEvents();
  InitProperties();
  Refresh();
end;

procedure TCustomPresenter.InitEvents;
begin
  // implemented by descendants
end;

procedure TCustomPresenter.InitProperties;
begin
  // implemented by descendants
end;

procedure TCustomPresenter.Loaded;
begin
  inherited;
  InitColumns();
  Refresh();
end;

procedure TCustomPresenter.ReadColumnDefinitions(Reader: TReader);
begin
  Reader.ReadValue();
  Reader.ReadCollection(FColumnDefinitions as TCollection);
end;

procedure TCustomPresenter.Refresh;
begin
  // implemented by descendants
end;

procedure TCustomPresenter.SetColumnDefinitions(
  const Value: IColumnDefinitions);
begin
  if Assigned(FColumnDefinitions) and (FColumnDefinitions.Owner = Self) then
  begin
    if (FView.ItemTemplate is TColumnDefinitionsControlTemplate)
      and ((FView.ItemTemplate as TColumnDefinitionsControlTemplate).ColumnDefinitions = FColumnDefinitions) then
    begin
      (FView.ItemTemplate as TColumnDefinitionsControlTemplate).ColumnDefinitions := Value;
    end;
  end;
  FColumnDefinitions := Value;
  InitColumns();
end;

procedure TCustomPresenter.SetCurrentItem(const Value: TObject);
begin
  DoPropertyChanged('View');
end;

procedure TCustomPresenter.SetImageList(const Value: TCustomImageList);
begin
  FImageList := Value;
  InitControl();
end;

procedure TCustomPresenter.SetPopupMenu(const Value: TPopupMenu);
begin
  FPopupMenu := Value;
  InitControl();
end;

procedure TCustomPresenter.WriteColumnDefinitions(Writer: TWriter);
begin
  Writer.WriteCollection(FColumnDefinitions as TColumnDefinitions);
end;

{ TCollectionViewPresenterAdapter }

constructor TCollectionViewPresenterAdapter.Create(Presenter: TCustomPresenter);
begin
  inherited Create;
  FPresenter := Presenter;
end;

procedure TCollectionViewPresenterAdapter.DoItemPropertyChanged(
  ASender: TObject; APropertyName: string; AUpdateTrigger: TUpdateTrigger);
begin
  inherited;

  NotifyPropertyChanged(FPresenter, Self, 'View');
end;

procedure TCollectionViewPresenterAdapter.DoSourceCollectionChanged(Sender,
  Item: TObject; Action: TCollectionChangedAction);
begin
  inherited;

  FPresenter.DoSourceCollectionChanged(Sender, Item, Action);

  NotifyPropertyChanged(FPresenter, Self, 'View');
end;

function TCollectionViewPresenterAdapter.GetCurrentItem: TObject;
begin
  Result := FPresenter.GetCurrentItem();
end;

procedure TCollectionViewPresenterAdapter.SetCurrentItem(const Value: TObject);
begin
  FPresenter.SetCurrentItem(Value);
end;

procedure TCollectionViewPresenterAdapter.UpdateItems(AClearItems: Boolean);
begin
  inherited;

  if not (csDestroying in FPresenter.ComponentState) then
  begin
    FPresenter.Refresh();

    NotifyPropertyChanged(FPresenter, Self, 'View');
  end;
end;

end.
