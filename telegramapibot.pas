unit Telegramapibot;

{$mode objfpc}{$H+}
//{$APPTYPE CONSOLE}
interface

uses
  Classes, SysUtils,fphttpclient, fpjson,opensslsockets,jsonparser;

type bot_info = record    //info about bot. Getme
  id:string;
  is_bot:string;
  first_name:string;
  username:string;
  can_join_groups:string;
  can_read_all_group_messages:string;
  supports_inline_queries:string;
end;

type TGdata = record  //description  from  json. Getupdate
  update_id:string;
  message_id:string;
  message_date:string;
  message_text:string;
  message_caption:string;
  from_id:string;
  from_is_bot:string;
  from_first_name:string;
  from_last_name:string;
  from_username:string;
  from_language_code:string;
  chat_id:string;
  chat_first_name:string;
  chat_last_name:string;
  chat_type:string;
  TypeMessage:string; // type of message: text,audio,document,photo,video,voice
  file_id:string;
  file_name:string;
  mime_type:string;
  file_size:string;
end;

type TGdataArray = array of TGdata;

type BotStatus = record
  Error:boolean;
  ErrorCode:integer;
  DescriptionError:string;
  information:boolean;//true if GetUpdates have  incoming update. false no result[] empty
end;

type
TSimpleBot = class(TObject)
  private const
    URL_API='https://api.telegram.org/bot';
    URL_API_FILE='https://api.telegram.org/file/bot';
  private
    AboutBotInfo:bot_info;
    JsonTG: TGdataArray;
    CheckStatus:BotStatus;
    TokenString:string;
    HTTPClient:TFPHttpClient;
    RespStream: TStringStream;
    procedure CheckWebError(const Status:boolean; var setWebErrors:BotStatus;const RawData:string);
    function checkjson(const x:TJSONData):string;
    function GetCount:integer;
  public
    constructor Create();
    destructor Destroy; override;
    procedure GetMe();
    procedure GetUpdates(const offset:integer);
    procedure Send(const source:string; const data:string; const chat_id:string);
    procedure GetFile(const file_id:string; const FileName:string);
    property Token: string read TokenString write TokenString;
    property Have:BotStatus read CheckStatus;
    property upd:TGdataArray read JsonTG; //update data
    property CountData:integer read GetCount;
    property About:bot_info read AboutBotInfo;
end;

implementation

constructor TSimpleBot.Create();
begin
  inherited;
  RespStream:=TStringStream.Create;
  HTTPClient := TFPHTTPClient.Create(nil);
end;

destructor TSimpleBot.Destroy;
begin
  JsonTG:=nil;
  RespStream.Free;
  HTTPClient.Free;
  inherited;
end;

function TSimpleBot.GetCount: integer;
begin
  Result:=length(JsonTG);
end;

function TSimpleBot.checkjson(const x:TJSONData):String;
begin
  if x =nil then result:='' else result:=x.AsString;
end;

procedure TSimpleBot.CheckWebError(const Status:boolean; var setWebErrors:BotStatus;const RawData:string);
var // Check network error, response error
  y: TJSONData;
begin
  if Status then
  begin
    y:=GetJSON(RawData);
    if y.FindPath('ok').AsBoolean then
      begin
        setWebErrors.Error:=false;
        setWebErrors.DescriptionError:='';
        setWebErrors.ErrorCode:=0;
        y.Free;
      end else
      begin
        setWebErrors.Error:=true;
        setWebErrors.DescriptionError:=y.FindPath('description').AsString;
        setWebErrors.ErrorCode:=y.FindPath('error_code').AsInteger;
        y.Free;
      end;
  end else
    begin
      setWebErrors.Error:=true;
      setWebErrors.DescriptionError:=RawData;
      setWebErrors.ErrorCode:=-1;
      y.Free;
    end;
end;

procedure TSimpleBot.GetMe();
var JSONData: TJSONData;
begin
  RespStream.Clear;
  CheckStatus.information:=false;
  try
    HTTPClient.post(URL_API+TokenString+'/getMe',RespStream);
  except
      on E:Exception do
        begin
          CheckWebError(false,CheckStatus,E.Message);
          exit;
        end;
  end;
  CheckWebError(true,CheckStatus,RespStream.DataString);
  if CheckStatus.Error then exit;
  JSONData:=GetJSON(RespStream.DataString);
  AboutBotInfo.id:=checkjson(JSONData.FindPath('result.id'));
  AboutBotInfo.is_bot:=checkjson(JSONData.FindPath('result.is_bot'));
  AboutBotInfo.first_name:=checkjson(JSONData.FindPath('result.first_name'));
  AboutBotInfo.username:=checkjson(JSONData.FindPath('result.username'));
  AboutBotInfo.can_join_groups:=checkjson(JSONData.FindPath('result.can_join_groups'));
  AboutBotInfo.can_read_all_group_messages:=checkjson(JSONData.FindPath('result.can_read_all_group_messages'));
  AboutBotInfo.supports_inline_queries:=checkjson(JSONData.FindPath('result.supports_inline_queries'));
  CheckStatus.information:=true;
  JSONData.Free;
  RespStream.Clear;
end;

procedure TSimpleBot.GetUpdates(const offset:integer);
const  //GetUpdates
  doctype:array[0..4] of string =('audio','document','photo','video','voice');
var
  ss:string;
  JD,PD: TJSONData;
  JSArray:TJSONArray;
  i,j,k:integer;
begin
  CheckStatus.information:=false;
  RespStream.Clear;
  if offset = 0 then ss:=URL_API+TokenString+'/getUpdates' else
          ss:= URL_API+TokenString+'/getUpdates?offset='+offset.ToString();
  try
    HTTPClient.post(ss,RespStream);
  except
    on E:Exception do
      begin
         CheckWebError(false,CheckStatus,E.Message);
         exit;
      end;
  end;
  CheckWebError(true,CheckStatus,RespStream.DataString);
  if CheckStatus.Error then exit;
  PD:=GetJSON(RespStream.DataString);
  JSArray:=TJSONArray(PD.FindPath('result'));
  i:=JSArray.Count;
  if i=0 then
    begin
      PD.Free;
      JsonTG:=nil;
      setLength(JsonTG,1);
      exit;
    end;
  JsonTG:=nil;
  setLength(JsonTG,i);
  for j:=0 to i-1 do
  begin
    JD:=GetJSON(JSArray.Items[j].AsJSON);
    JsonTG[j].update_id:=checkjson(JD.FindPath('update_id'));
    JsonTG[j].message_id:=checkjson(JD.FindPath('message.message_id'));
    JsonTG[j].message_date:=checkjson(JD.FindPath('message.date'));
    JsonTG[j].message_text:=checkjson(JD.FindPath('message.text'));
    JsonTG[j].message_caption:=checkjson(JD.FindPath('message.caption'));
    JsonTG[j].from_id:=checkjson(JD.FindPath('message.from.id'));
    JsonTG[j].from_is_bot:=checkjson(JD.FindPath('message.from.is_bot'));
    JsonTG[j].from_first_name:=checkjson(JD.FindPath('message.from.first_name'));
    JsonTG[j].from_last_name:=checkjson(JD.FindPath('message.from.last_name'));
    JsonTG[j].from_language_code:=checkjson(JD.FindPath('message.from.language_code'));
    JsonTG[j].from_username:=checkjson(JD.FindPath('message.from.username'));
    JsonTG[j].chat_id:=checkjson(JD.FindPath('message.chat.id'));
    JsonTG[j].chat_first_name:=checkjson(JD.FindPath('message.chat.first_name'));
    JsonTG[j].chat_last_name:=checkjson(JD.FindPath('message.chat.last_name'));
    JsonTG[j].chat_type:=checkjson(JD.FindPath('message.chat.type'));
    JsonTG[j].TypeMessage:='text';
    for k:=0 to 4 do
    begin
      if JD.FindPath('message.'+doctype[k])= nil then continue;
      JsonTG[j].TypeMessage:=doctype[k];
      JsonTG[j].file_id:=checkjson(JD.FindPath('message.'+doctype[k]+'.file_id'));
      JsonTG[j].file_name:=checkjson(JD.FindPath('message.'+doctype[k]+'.file_name'));
      JsonTG[j].mime_type:=checkjson(JD.FindPath('message.'+doctype[k]+'.mime_type'));
      JsonTG[j].file_size:=checkjson(JD.FindPath('message.'+doctype[k]+'.file_size'));
      break;
    end;
    JD.free;
  end;
  CheckStatus.information:=true;
  PD.Free;
  RespStream.Clear;
end;

procedure TSimpleBot.GetFile(const file_id:string; const FileName:string);
var   //GetFile(file_id, file name)
  FS: TStream;
  s:string;
  y: TJSONData;
begin
  RespStream.Clear;
  try
    HTTPClient.Post(URL_API+TokenString+'/getFile?file_id='+file_id,RespStream);
    CheckWebError(true,CheckStatus,RespStream.DataString);
    if CheckStatus.Error then exit;
    y:=GetJSON(RespStream.DataString);
    s:=y.FindPath('result.file_path').AsString;
    y.Free;
    FS:= TFileStream.Create(FileName,fmCreate or fmOpenWrite);
    HTTPClient.get(URL_API_FILE+TokenString+'/'+s,FS);
    FS.Free;
  except
  on E:Exception do
    begin
      CheckWebError(false,CheckStatus,E.Message);
      y.Free;
      FS.Free;
      exit;
    end;
  end;
  CheckStatus.Error:=false;
  CheckStatus.DescriptionError:='';
  CheckStatus.ErrorCode:=0;
end;

procedure TSimpleBot.Send(const source:string; const data:string; const chat_id:string);
var            //Source ('message'-text,'photo_Url'-text url image
  line:string; // 'photo','audio','document'- file); data(text , local file name)
begin
  RespStream.Clear;
  case source of
    'message': line:=URL_API+TokenString+'/sendMessage?chat_id='+chat_id+'&text='+data;  //HTTPClient.post
    'photo' : line:=URL_API+TokenString+'/sendPhoto?chat_id='+chat_id;//'photo';//'photo',fileload,RespStream); ; hTTPClient.FileFormPost
    'photo_Url': line:=URL_API+TokenString+'/sendPhoto?chat_id='+chat_id+'&photo='+data;//HTTPClient.Post
    'audio': line:=URL_API+TokenString+'/sendAudio?chat_id='+chat_id;//'audio',file_mp3_load,RespStream);FileFormPost
    'document': line:=URL_API+TokenString+'/sendDocument?chat_id='+chat_id;//,'document',file_Document_load,RespStream);FileFormPost
    'emoji': line:=URL_API+TokenString+'/sendDice?chat_id='+chat_id+'&'+'emoji='+data;//,RespStream);Post
  else
    begin
      CheckStatus.Error:=true;
      CheckStatus.DescriptionError:='Source label error';
      CheckStatus.ErrorCode:=-1;
    end;
  end;
  try
    case source of
      'message','photo_Url','emoji':HTTPClient.post(line,RespStream);
      'photo','audio','document':HTTPClient.FileFormPost(line,source,data,RespStream);  //data-- file name
    end;
  except
    on E:Exception do
      begin
        CheckWebError(false,CheckStatus,E.Message);
        exit;
      end;
  end;
  CheckWebError(true,CheckStatus,RespStream.DataString);
end;

end.

