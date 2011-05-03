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

unit System.Bindings.Designtime;

interface

uses
  Classes,
  DesignIntf,
  DesignEditors,
  Generics.Collections,
  System.Bindings,
  TypInfo;

type
  TBindingPropertyFilter = class(TSelectionEditor, ISelectionPropertyFilter)
    procedure FilterProperties(const ASelection: IDesignerSelections;
      const ASelectionProperties: IInterfaceList);
  end;

  TBindingProperty = class(TClassProperty, IProperty, IPropertyKind)
  private
    FBinding: TBinding;
    FBindingGroup: TBindingGroup;
    function FilterFunc(const ATestEditor: IProperty): Boolean;
  public
    function AllEqual: Boolean; override;
    function GetKind: TTypeKind;
    function GetName: string; override;
    procedure GetProperties(Proc: TGetPropProc); override;
    function GetPropInfo: PPropInfo; override;
    function GetPropType: PTypeInfo;
    function GetValue: string; override;

    property Binding: TBinding read FBinding write FBinding;
    property BindingGroup: TBindingGroup read FBindingGroup write FBindingGroup;
  end;

  TSourceProperty = class(TComponentProperty)
  public
    procedure GetValues(Proc: TGetStrProc); override;
    procedure SetValue(const Value: string); override;
  end;

  TSourcePropertyNameProperty = class(TStringProperty)
  public
    function GetAttributes: TPropertyAttributes; override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

  procedure Register;

var
  SupportedClasses: TDictionary<TClass, string>;

implementation

uses
  ComCtrls,
  CommCtrl,
  ExtCtrls,
  StdCtrls,

  Consts,
  RTLConsts,
  Rtti,
  SysUtils;

procedure Register;
var
  LClass: TClass;
begin
  for LClass in SupportedClasses.Keys do
  begin
    RegisterSelectionEditor(LClass, TBindingPropertyFilter);
  end;
  RegisterComponents('Data binding', [TBindingGroup]);
  RegisterPropertyEditor(TypeInfo(TObject), TBinding, 'Source', TSourceProperty);
  RegisterPropertyEditor(TypeInfo(string), TBinding, 'SourcePropertyName', TSourcePropertyNameProperty);
end;

function GetBindingByTarget(ABindingGroup: TBindingGroup; AObject: TObject): TBinding;
var
  LBinding: TBinding;
begin
  Result := nil;
  for LBinding in ABindingGroup.Bindings do
  begin
    if LBinding.Target = AObject then
    begin
      Result := LBinding;
    end;
  end;
  if not Assigned(Result) then
  begin
    Result := TBinding.Create(nil, '', nil, '');
    Result.Active := False;
    Result.Target := AObject;
    ABindingGroup.Bindings.Add(Result);
  end;
end;

function SupportsBinding(AComponent: TPersistent): Boolean;
begin
  Result := SupportedClasses.ContainsKey(AComponent.ClassType);
end;

function GetTargetPropertyName(AComponent: TPersistent): string;
begin
  Result := SupportedClasses[AComponent.ClassType];
end;

{ TBindingPropertyFilter }

procedure TBindingPropertyFilter.FilterProperties(
  const ASelection: IDesignerSelections; const ASelectionProperties: IInterfaceList);
var
  i, k: Integer;
  LProperty: TBindingProperty;
begin
  if ASelection.Count = 1 then
  begin
    if SupportsBinding(ASelection[0]) then
    begin
      for i := 0 to TComponent(ASelection[0]).Owner.ComponentCount - 1 do
      begin
        if TComponent(ASelection[0]).Owner.Components[i] is TBindingGroup then
        begin
          LProperty := TBindingProperty.Create(inherited Designer, 0);
          LProperty.BindingGroup := TComponent(ASelection[0]).Owner.Components[i] as TBindingGroup;
          LProperty.Binding := GetBindingByTarget(LProperty.BindingGroup, ASelection[0] as TObject);
          LProperty.Binding.TargetPropertyName := GetTargetPropertyName(ASelection[0]);
          for k := 0 to ASelectionProperties.Count - 1 do
          begin
            if Supports(ASelectionProperties[k], IProperty)
              and ((ASelectionProperties[k] as IProperty).GetName > 'Binding') then
            begin
              Break;
            end;
          end;
          ASelectionProperties.Insert(k, LProperty);
        end;
      end;
    end;
  end;
end;

{ TBindingProperty }

function TBindingProperty.AllEqual: Boolean;
begin
  Result := True;
end;

function TBindingProperty.FilterFunc(const ATestEditor: IProperty): Boolean;
begin
  Result := not SameText(ATestEditor.GetName(), 'Target')
    and not SameText(ATestEditor.GetName(), 'TargetPropertyName');
end;

function TBindingProperty.GetKind: TTypeKind;
begin
  Result := tkClass;
end;

function TBindingProperty.GetName: string;
begin
  Result := 'Binding';
end;

procedure TBindingProperty.GetProperties(Proc: TGetPropProc);
var
  Components: IDesignerSelections;
begin
  Components := TDesignerSelections.Create;
  Components.Add(FBinding);
  GetComponentProperties(Components, tkProperties, Designer, Proc, FilterFunc);
end;

function TBindingProperty.GetPropInfo: PPropInfo;
begin
  Result := TRttiInstanceProperty(TRttiContext.Create.GetType(TBindingProperty)
    .GetProperty('Binding')).PropInfo;
end;

function TBindingProperty.GetPropType: PTypeInfo;
begin
  Result := TypeInfo(TBinding);
end;

function TBindingProperty.GetValue: string;
begin
  Result := '(TBinding)';
end;

{ TSourceProperty }

procedure TSourceProperty.GetValues(Proc: TGetStrProc);
begin
  inherited;
end;

procedure TSourceProperty.SetValue(const Value: string);
var
  Component: TComponent;
  LBinding: TBinding;
  LProperty: TRttiProperty;
begin
  LBinding := TBinding(GetComponent(0));

  if Value = '' then
    Component := nil
  else
  begin
    Component := Designer.GetComponent(Value);
    if not (Component is GetTypeData(GetPropType)^.ClassType) then
      raise EDesignPropertyError.CreateRes(@SInvalidPropertyValue);
    if Assigned(LBinding) and (LBinding.Target = Component) then
      raise EDesignPropertyError.Create('Binding source must be different from binding target');
  end;
  SetOrdValue(LongInt(Component));

  if Assigned(LBinding.Source) and (LBinding.SourcePropertyName <> '') then
  begin
    LProperty := TRttiContext.Create.GetType(LBinding.Source.ClassInfo).GetProperty(LBinding.SourcePropertyName);
    if not Assigned(LProperty) then
    begin
      LBinding.SourcePropertyName := '';
    end;
  end;
end;

{ TSourcePropertyNameProperty }

function TSourcePropertyNameProperty.GetAttributes: TPropertyAttributes;
begin
  Result := inherited + [paValueList];
end;

procedure TSourcePropertyNameProperty.GetValues(Proc: TGetStrProc);
var
  LProperty: TRttiProperty;
  LBinding: TBinding;
begin
  LBinding := TBinding(GetComponent(0));
  if Assigned(LBinding.Source) then
  begin
    for LProperty in TRttiContext.Create.GetType(LBinding.Source.ClassInfo).GetProperties do
    begin
      if LProperty.PropertyType.TypeKind <> tkMethod then
      begin
        Proc(LProperty.Name);
      end;
    end;
  end;
end;

initialization
  SupportedClasses := TDictionary<TClass, string>.Create();
  SupportedClasses.Add(TCheckBox, 'Checked');
  SupportedClasses.Add(TColorBox, 'Selected');
  SupportedClasses.Add(TComboBox, 'Text');
  SupportedClasses.Add(TDateTimePicker, 'Date'); // need some review to change binding property depending on state
  SupportedClasses.Add(TEdit, 'Text');
  SupportedClasses.Add(TMonthCalendar, 'Date');
  SupportedClasses.Add(TRadioButton, 'Checked');
  SupportedClasses.Add(TRadioGroup, 'ItemIndex');
  SupportedClasses.Add(TTrackBar, 'Position');

finalization
  SupportedClasses.Free();

end.