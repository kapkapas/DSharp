unit AppViewModel;

interface

uses
  AppInterfaces,
  DSharp.PresentationModel;

type
  TAppViewModel = class(TScreen, IAppViewModel)
  strict private
    FCount: Integer;
  strict protected
    function GetCount(): Integer; virtual;
    procedure SetCount(const Value: Integer); virtual;
  public
    constructor Create(); override;
    property Count: Integer read GetCount write SetCount;
  end;

implementation

constructor TAppViewModel.Create();
begin
  inherited Create();
  DisplayName := IAppViewModel_DisplayName;
end;

function TAppViewModel.GetCount(): Integer;
begin
  Result := FCount;
end;

procedure TAppViewModel.SetCount(const Value: Integer);
begin
  if Count <> Value then
  begin
    FCount := Value;
    NotifyOfPropertyChange('Count');
  end;
end;

initialization
  TAppViewModel.ClassName;
end.
