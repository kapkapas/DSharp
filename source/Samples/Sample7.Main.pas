unit Sample7.Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Sample7.Customer, Collections.Base, Collections.Lists, StdCtrls;

type
  TForm3 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    Edit1: TEdit;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    { Private declarations }
    customers: TObjectList<TCustomer>;
    filter1: TFunc<TCustomer, Boolean>;
    filter2: TFunc<TCustomer, Boolean>;
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.dfm}

uses
  Rtti,
  StrUtils,
  System.Expressions,
  System.Lambda;

type
  TStartsTextExpression = class(TBinaryExpression)
  public
    function Compile: TValue; override;
  end;

function TStartsTextExpression.Compile: TValue;
begin
  Result := TValue.From<Boolean>(StrUtils.StartsText(Left.Compile.ToString, Right.Compile.ToString));
end;

function StartsText(SubText, Text: Variant): IExpression;
var
  LLeft, LRight: IExpression;
begin
  LRight := ExpressionStack.Pop();
  LLeft := ExpressionStack.Pop();
  Result := TStartsTextExpression.Create(LLeft, LRight);
  ExpressionStack.Push(Result);
end;

procedure TForm3.Button1Click(Sender: TObject);
var
  cust: TCustomer;
begin
  for cust in customers.Where(filter1) do
  begin
    Memo1.Lines.Add(cust.ToString);
  end;
end;

procedure TForm3.Button2Click(Sender: TObject);
var
  cust: TCustomer;
begin
  for cust in customers.Where(filter2) do
  begin
    Memo1.Lines.Add(cust.ToString);
  end;
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  filter1 := TLambda.Make<TCustomer, Boolean>(Arg1.CustomerId = 'ALFKI');
  filter2 := TLambda.Make<TCustomer, Boolean>(StartsText(Arg(Edit1).Text, Arg1.CompanyName));

  customers := TObjectList<TCustomer>.Create();
  customers.Add(TCustomer.Create('ALFKI', 'Alfreds Futterkiste'));
  customers.Add(TCustomer.Create('ANATR', 'Ana Trujillo Emparedados y helados'));
  customers.Add(TCustomer.Create('ANTON', 'Antonio Moreno Taquer�a'));
  customers.Add(TCustomer.Create('AROUT', 'Around the Horn'));
  customers.Add(TCustomer.Create('BERGS', 'Berglunds snabbk�p'));
  customers.Add(TCustomer.Create('BLAUS', 'Blauer See Delikatessen'));
end;

procedure TForm3.FormDestroy(Sender: TObject);
begin
  customers.Free();
end;

end.
