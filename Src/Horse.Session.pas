unit MDK.Horse.Session;

interface

uses
 System.SysUtils,
 Horse,
 System.Classes,
 System.JSON;

 type
  THorseSessionMDKJSONObject = reference to function(ASessionJSONObject: TJSONObject): Boolean;
  THorseSessionMDKReq        = reference to function(ASessionReq: THorseRequest): Boolean;

 function HorseSessionMDK(const AFunc: THorseSessionMDKJSONObject): THorseCallback; overload;
 function HorseSessionMDK(const AFunc: THorseSessionMDKReq): THorseCallback; overload
 procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc); overload;

implementation

var
  LHorseSessionReq: THorseSessionMDKReq;
  LHorseSessionJSONObject: THorseSessionMDKJSONObject;

function HorseSessionMDK(const AFunc: THorseSessionMDKJSONObject): THorseCallback;
begin
   LHorseSessionJSONObject := AFunc;
   Result := Middleware;
end;

function HorseSessionMDK(const AFunc: THorseSessionMDKReq): THorseCallback;
begin
   LHorseSessionReq := AFunc;
   Result := Middleware;
end;

procedure Middleware(Req: THorseRequest; Res: THorseResponse; Next: TProc);
var
 LReturn: Boolean;
begin
   try
     LReturn := False;
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
