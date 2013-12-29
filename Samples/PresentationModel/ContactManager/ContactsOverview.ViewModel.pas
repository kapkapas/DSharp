unit ContactsOverview.ViewModel;

interface

uses
  Contact,
  ContactManager.Interfaces,
  DSharp.Collections,
  DSharp.PresentationModel;

type
  TContactsOverviewViewModel = class(TScreen, IContactsOverviewViewModel)
  private
    [Import('DemoData.Contacts')]
    FContacts: IList;
    [ImportLazy]
    FContactDetails: IContactDetailsViewModel;
    FSelectedContact: TContact;
    [Import]
    FWindowManager: IWindowManager;
    function GetCanDeleteContact: Boolean;
    function GetCanEditContact: Boolean;
    function GetSelectedContact: TContact;
    procedure SetSelectedContact(const Value: TContact);
  protected
    property WindowManager: IWindowManager read FWindowManager;
  public
    procedure AddNewContact; virtual;
    procedure EditContact; virtual;
    procedure DeleteContact; virtual;

    property CanDeleteContact: Boolean read GetCanDeleteContact;
    property CanEditContact: Boolean read GetCanEditContact;
    property ContactDetails: IContactDetailsViewModel read FContactDetails;
    property Contacts: IList read FContacts;
    property SelectedContact: TContact read GetSelectedContact
      write SetSelectedContact;
  end;

implementation

{ TDSharp.PresentationModel.ContactManagerViewModel }

procedure TContactsOverviewViewModel.AddNewContact;
var
  LContact: TContact;
begin
  LContact := TContact.Create();
  ContactDetails.Contact := LContact;

  if WindowManager.ShowDialog(ContactDetails) = mrOk then
  begin
    FContacts.Add(LContact);
    SelectedContact := LContact;
  end
  else
  begin
    LContact.Free();
  end;
end;

procedure TContactsOverviewViewModel.DeleteContact;
begin
  if WindowManager.MessageDlg
    ('Do you really want to delete the selected contact?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then
  begin
    FContacts.Remove(FSelectedContact);
  end;
end;

procedure TContactsOverviewViewModel.EditContact;
begin
  FContactDetails.Contact := FSelectedContact;

  WindowManager.ShowDialog(FContactDetails);
end;

function TContactsOverviewViewModel.GetCanDeleteContact: Boolean;
begin
  Result := Assigned(FSelectedContact) and (FSelectedContact is TContact) and
    not(FSelectedContact as TContact).IsUser;
end;

function TContactsOverviewViewModel.GetCanEditContact: Boolean;
begin
  Result := Assigned(FSelectedContact);
end;

function TContactsOverviewViewModel.GetSelectedContact: TContact;
begin
  Result := FSelectedContact;
end;

procedure TContactsOverviewViewModel.SetSelectedContact(const Value: TContact);
begin
  FSelectedContact := Value;
  NotifyOfPropertyChange('CanDeleteContact');
  NotifyOfPropertyChange('CanEditContact');
  NotifyOfPropertyChange('SelectedContact');
end;

initialization

TContactsOverviewViewModel.ClassName;

end.