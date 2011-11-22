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

unit DSharp.PresentationModel.NameTransformer;

interface

uses
  DSharp.Collections;

type
  TRule = class
  private
    FReplacePattern: string;
    FReplacementValue: string;
  public
    constructor Create(const ReplacePattern, ReplacementValue: string);
    property ReplacePattern: string read FReplacePattern;
    property ReplacementValue: string read FReplacementValue;
  end;

  INameTransformer = interface
    procedure AddRule(const ReplacePattern, ReplacementValue: string);
    function Transform(const Source: string): IEnumerable<string>;
  end;

  TNameTransformer = class(TObjectList<TRule>, INameTransformer)
  public
    procedure AddRule(const ReplacePattern, ReplacementValue: string);
    function Transform(const Source: string): IEnumerable<string>;
  end;

implementation

uses
  DSharp.Core.RegularExpressions;

{ TRule }

constructor TRule.Create(const ReplacePattern, ReplacementValue: string);
begin
  FReplacePattern := ReplacePattern;
  FReplacementValue := ReplacementValue
end;

{ TNameTransformer }

procedure TNameTransformer.AddRule(const ReplacePattern,
  ReplacementValue: string);
begin
  Add(TRule.Create(ReplacePattern, ReplacementValue));
end;

function TNameTransformer.Transform(const Source: string): IEnumerable<string>;
var
  LNameList: TList<string>;
  LRule: TRule;
begin
  LNameList := TList<string>.Create;

  for LRule in Self do
  begin
    if TRegEx.IsMatch(Source, LRule.ReplacePattern) then
    begin
      LNameList.Add(TRegEx.Replace(Source, LRule.ReplacePattern, LRule.ReplacementValue));
    end;
  end;

  Result := LNameList;
end;

end.