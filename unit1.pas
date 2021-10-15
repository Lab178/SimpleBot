unit Unit1;

{$mode objfpc}{$H+}
//{$APPTYPE CONSOLE}
interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Telegramapibot;

  { TForm1 }
  type

  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Memo1: TMemo;
    Memo3: TMemo;
    OpenDialog1: TOpenDialog;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);

  private

  public

  end;

var
  Form1: TForm1;
  Bot:TSimpleBot;
   offset:int64;
implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
  var j:integer;
begin
  memo3.Clear;
  memo1.Clear;
  bot.GetUpdates(0);
  if bot.Have.Error then
  begin
    memo3.Lines.Add(bot.Have.ErrorCode.ToString());
    memo3.Lines.Add(bot.Have.DescriptionError);
    exit;
  end else memo3.Lines.Add('GetUpdates No Errors');
  memo1.Lines.Add('Array parts = '+bot.CountData.ToString());
  if bot.Have.information then
    for j:=0 to bot.CountData-1 do
    begin
      memo1.Lines.Add('=========================='+j.ToString());
      memo1.Lines.Add('update_id = '+bot.upd[j].update_id);
      memo1.Lines.Add('message_id = '+bot.upd[j].message_id);
      memo1.Lines.Add('message_date = '+bot.upd[j].message_date);
      memo1.Lines.Add('message_text = '+bot.upd[j].message_text);
      memo1.Lines.Add('message_caption = '+bot.upd[j].message_caption);
      memo1.Lines.Add('from_id = '+bot.upd[j].from_id);
      memo1.Lines.Add('is_bot = '+bot.upd[j].from_is_bot);
      memo1.Lines.Add('from_first_name = '+bot.upd[j].from_first_name);
      memo1.Lines.Add('from_last_name = '+bot.upd[j].from_last_name);
      memo1.Lines.Add('from_username = '+bot.upd[j].from_username);
      memo1.Lines.Add('from_language_code = '+bot.upd[j].from_language_code);
      memo1.Lines.Add('chat_id = '+bot.upd[j].chat_id);
      memo1.Lines.Add('chat_first_name = '+bot.upd[j].chat_first_name);
      memo1.Lines.Add('chat_last_name = '+bot.upd[j].chat_last_name);
      memo1.Lines.Add('chat_type = '+bot.upd[j].chat_type);
      memo1.Lines.Add('TypeMessage = '+bot.upd[j].TypeMessage);
      memo1.Lines.Add('file_id = '+bot.upd[j].file_id);
      memo1.Lines.Add('file_name = '+bot.upd[j].file_name);
      memo1.Lines.Add('mime_type = '+bot.upd[j].mime_type);
      memo1.Lines.Add('file_size = '+bot.upd[j].file_size);
    end else memo1.Lines.Add('No Data');
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  memo1.Clear;
  bot.GetMe();
  if bot.Have.Error then
  begin
   memo3.Lines.Add(bot.Have.ErrorCode.ToString());
   memo3.Lines.Add(bot.Have.DescriptionError);
   exit;
  end else memo3.Lines.Add('GetMe No Errors');
  memo1.Lines.Add('bot id = '+bot.About.id);
  memo1.Lines.Add('is_bot = '+bot.About.is_bot);
  memo1.Lines.Add('first_name = '+bot.About.first_name);
  memo1.Lines.Add('username = '+bot.About.username);
  memo1.Lines.Add('can_join_groups = '+bot.About.can_join_groups);
  memo1.Lines.Add('can_read_all_group_messages = '+bot.About.can_read_all_group_messages);
  memo1.Lines.Add('supports_inline_queries = '+bot.About.supports_inline_queries);
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  memo3.Clear;
  bot.Token:=edit1.Text;
  if edit1.Text='' then memo3.Lines.Add('Error No Token:');
  memo3.Lines.Add('Select Token:');
  memo3.Lines.Add(edit1.Text);
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  memo3.Clear;
  if (Edit2.Text='') or (Edit3.Text='') then
  begin
    memo3.Lines.Add('File id or name!');
    exit;
  end;
  bot.GetFile(Edit2.Text,Edit3.Text);
  if bot.Have.Error then
  begin
   memo3.Lines.Add(bot.Have.ErrorCode.ToString());
   memo3.Lines.Add(bot.Have.DescriptionError);
   exit;
  end else memo3.Lines.Add('GetFile No Errors');
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  memo3.Clear;
  bot.Send('message',Edit4.Text,Edit5.Text);
  if bot.Have.Error then
  begin
   memo3.Lines.Add(bot.Have.ErrorCode.ToString());
   memo3.Lines.Add(bot.Have.DescriptionError);
  end else memo3.Lines.Add('Send Text No Errors');
end;

procedure TForm1.Button6Click(Sender: TObject);

begin
  memo3.Clear;
  if OpenDialog1.Execute then
  begin
    if  not fileExists(OpenDialog1.Filename) then
    begin
      memo3.Lines.Add('Error file selected');
      exit;
    end;
  end else
    begin
      memo3.Lines.Add('No file selected');
      exit;
    end;
  bot.Send('document',OpenDialog1.Filename,Edit5.Text);
  if bot.Have.Error then
  begin
   memo3.Lines.Add(bot.Have.ErrorCode.ToString());
   memo3.Lines.Add(bot.Have.DescriptionError);
  end else memo3.Lines.Add('Send Text No Errors');
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  bot.Destroy;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  bot:=TSimpleBot.Create;
end;

end.

