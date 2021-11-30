unit Horse.Session;

interface

uses
 System.SysUtils,
 Horse,
 System.Classes,
 System.JSON;

 type
  THorseSessionJSONObject = reference to function(ASessionJSONObject: TJSONObject): Boolean;
  THorseSessionReq        = reference to function(ASessionReq: THorseRequest): Boolean;

 function HorseSession(const AFunc: THorseSessionJSONObject): THorseCallback; overload;
 function HorseSession(const AFunc: THorseSessionReq): THorseCallback; overload
 procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc); overload;

implementation

var
  LHorseSessionReq: THorseSessionReq;
  LHorseSessionJSONObject: THorseSessionJSONObject;

function HorseSession(const AFunc: THorseSessionJSONObject): THorseCallback;
begin
   LHorseSessionJSONObject := AFunc;
   Result := Middleware;
end;

function HorseSession(const AFunc: THorseSessionReq): THorseCallback;
begin
   LHorseSessionReq := AFunc;
   Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
 LReturn: Boolean;
begin
   try
     if Assigned(LHorseSessionJSONObject)then
       LReturn := LHorseSessionJSONObject(Req.Session<TJSONObject>)
     else if Assigned(LHorseSessionReq)then
       LReturn := LHorseSessionReq(Req);

     if not LReturn then
     begin
        Res.Send('Unauthorized').Status(THTTPStatus.Unauthorized);
        raise EHorseCallbackInterrupted.Create;
     end;
   except
     on E: EHorseException do
       Raise;
     on E: exception do
     begin
       Res.Send(E.Message).Status(THTTPStatus.InternalServerError);
       raise EHorseCallbackInterrupted.Create;
     end;
   end;

   Next();
end;

end.
