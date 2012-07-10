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
    FUseColumnDefinitions: Boolean;
    FView: TCollectionView;
    procedure DoColumnDefinitionsChanged(Sender: TObject; const Item: TColumnDefinition;
      Action: TCollectionNotification);
    procedure ReadColumnDefinitions(Reader: TReader);
    procedure SetAction(const Value: TBasicAction);
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
    procedure DoSourceCollectionChanged(Sender: TObject; const Item: TObject;
      Action: TCollectionChangedAction); virtual;
    function GetCurrentItem: TObject; virtual;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure InitColumns; virtual;
    procedure InitControl; virtual;
    procedure InitEvents; virtual;
    procedure InitProperties; virtual;
    procedure Loaded; override;
    procedure SetCurrentItem(const Value: TObject); virtual;
    property UpdateCount: Integer read FUpdateCount;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure ApplyFilter; virtual;

    procedure BeginUpdate; virtual;
    procedure EndUpdate; virtual;

    function GetItemTemplate(const Item: TObject): IDataTemplate; overload;
    procedure Refresh; virtual;

    property ColumnDefinitions: IColumnDefinitions
      read FColumnDefinitions write SetColumnDefinitions;
    property View: TCollectionView read FView implements ICollectionView;
  published
    property Action: TBasicAction read FAction write SetAction;
    property ImageList: TCustomImageList read FImageList write SetImageList;
    property OnDoubleClick: TNotifyEvent read FOnDoubleClick write FOnDoubleClick;
    property PopupMenu: TPopupMenu read FPopupMenu write SetPopupMenu;
    property UseColumnDefinitions: Boolean
      read FUseColumnDefinitions write FUseColumnDefinitions default True;
  end;

  TCollectionViewPresenterAdapter = class(TCollectionView)
  private
    FPresenter: TCustomPresenter;
  protected
    procedure DoFilterChanged(Sender: TObject); override;
    procedure DoItemPropertyChanged(ASender: TObject; APropertyName: string;
      AUpdateTrigger: TUpdateTrigger = utPropertyChanged); override;
    procedure DoSourceCollectionChanged(Sender: TObject; const Item: TObject;
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
  FColumnDefinitions.OnNotify.Add(DoColumnDefinitionsChanged);
  FUseColumnDefinitions := True;
  FView.ItemTemplate := TColumnDefinitionsControlTemplate.Create(FColumnDefinitions);
end;

destructor TCustomPresenter.Destroy;
begin
  if Assigned(FColumnDefinitions) then
  begin
    FColumnDefinitions.OnNotify.Remove(DoColumnDefinitionsChanged);
  end;
  FView.Free();
  inherited;
end;

procedure TCustomPresenter.ApplyFilter;
begin

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

procedure TCustomPresenter.DoColumnDefinitionsChanged(Sender: TObject;
  const Item: TColumnDefinition; Action: TCollectionNotification);
begin
  if not (csDesigning in ComponentState) then
  begin
    InitColumns();
  end;
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

procedure TCustomPresenter.DoSourceCollectionChanged(Sender: TObject;
  const Item: TObject; Action: TCollectionChangedAction);
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
  if [csDesigning, csDestroying] * ComponentState = [] then
  begin
    InitColumns();
    InitEvents();
    InitProperties();
    Refresh();
  end;
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
  if not (csDesigning in ComponentState) then
  begin
    InitColumns();
    Refresh();
  end;
end;

procedure TCustomPresenter.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if Operation = opRemove then
  begin
    if AComponent = FAction then
    begin
      SetAction(nil);
    end;
    if AComponent = FImageList then
    begin
      SetImageList(nil);
    end;
    if AComponent = FPopupMenu then
    begin
      SetPopupMenu(nil);
    end;
  end;
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

procedure TCustomPresenter.SetAction(const Value: TBasicAction);
begin
  if FAction <> Value then
  begin
    if Assigned(FAction) then
    begin
      FAction.RemoveFreeNotification(Self);
    end;

    FAction := Value;

    if Assigned(FAction) then
    begin
      FAction.FreeNotification(Self);
    end;
  end;
end;

procedure TCustomPresenter.SetColumnDefinitions(
  const Value: IColumnDefinitions);
begin
  if Assigned(FColumnDefinitions) then
  begin
    FColumnDefinitions.OnNotify.Remove(DoColumnDefinitionsChanged);
    if FColumnDefinitions.Owner = Self then
    begin
      if (FView.ItemTemplate is TColumnDefinitionsControlTemplate)
        and ((FView.ItemTemplate as TColumnDefinitionsControlTemplate).ColumnDefinitions = FColumnDefinitions) then
      begin
        (FView.ItemTemplate as TColumnDefinitionsControlTemplate).ColumnDefinitions := Value;
      end;
    end;
  end;
  FColumnDefinitions := Value;
  if Assigned(FColumnDefinitions) then
  begin
    FColumnDefinitions.OnNotify.Add(DoColumnDefinitionsChanged);
  end;
  InitColumns();
end;

procedure TCustomPresenter.SetCurrentItem(const Value: TObject);
begin
  DoPropertyChanged('View');
end;

procedure TCustomPresenter.SetImageList(const Value: TCustomImageList);
begin
  if FImageList <> Value then
  begin
    if Assigned(FImageList) then
    begin
      FImageList.RemoveFreeNotification(Self);
    end;

    FImageList := Value;

    if Assigned(FImageList) then
    begin
      FImageList.FreeNotification(Self);
    end;

    InitControl();
  end;
end;

procedure TCustomPresenter.SetPopupMenu(const Value: TPopupMenu);
begin
  if FPopupMenu <> Value then
  begin
    if Assigned(FPopupMenu) then
    begin
      FPopupMenu.RemoveFreeNotification(Self);
    end;

    FPopupMenu := Value;

    if Assigned(FPopupMenu) then
    begin
      FPopupMenu.FreeNotification(Self);
    end;

    InitControl();
  end;
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

procedure TCollectionViewPresenterAdapter.DoFilterChanged(Sender: TObject);
begin
  FPresenter.ApplyFilter;
end;

procedure TCollectionViewPresenterAdapter.DoItemPropertyChanged(
  ASender: TObject; APropertyName: string; AUpdateTrigger: TUpdateTrigger);
begin
  inherited;

  NotifyPropertyChanged(FPresenter, Self, 'View');
end;

procedure TCollectionViewPresenterAdapter.DoSourceCollectionChanged(
  Sender: TObject; const Item: TObject; Action: TCollectionChangedAction);
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
