program IAmHere;

{$Mode objfpc}{$H+}
{$AppType GUI}

uses
  sgeSystemTrayIcon, sgeSystemIcon, sgeSystemTimeEvent,
  Windows;


type
  TApp = class
  private
    FTimeEvent: TsgeSystemTimeEvent;  //Таймерное событие
    FTrayIcon: TsgeSystemTrayIcon;    //Иконка в трее
    FIconOn: TsgeSystemIcon;          //Иконка включено
    FIconOff: TsgeSystemIcon;         //Иконка выключено

    FEnable: Boolean;

    procedure SetEnable(AEnable: Boolean);

    procedure TimerEvent;

    procedure TrayIconMouseDown(Button: TsgeSystemTrayIconMouseButtons);
    procedure TrayIconMouseDblClick(Button: TsgeSystemTrayIconMouseButtons);
  public
    constructor Create;
    destructor  Destroy; override;

    procedure Run;
  end;


var
  App: TApp;


resourcestring
  rsEnable        = 'Включено';
  rsDisable       = 'Выключено';
  rsExit          = 'Выход';
  rsHint          = 'Я здесь';
  rsBaloonCaption = 'Состояние';


procedure TApp.SetEnable(AEnable: Boolean);
var
  H: HICON;
begin
  FEnable := AEnable;

  //Изменить значёк
  if FEnable then
    H := FIconOn.Handle
  else
    H := FIconOff.Handle;
  FTrayIcon.Icon := H;

  //Поправить задачу движения мыши
  FTimeEvent.Enable := FEnable;
end;


procedure TApp.TimerEvent;
type
  tagMOUSEINPUT = record
    dx: LONG;
    dy: LONG;
    mouseData: DWORD;
    dwFlags: DWORD;
    time: DWORD;
    dwExtraInfo: ULONG_PTR;
  end;

  tagINPUT = record
    &type: DWORD;
    Input: tagMOUSEINPUT;
  end;

const
  INPUT_MOUSE = $0;
var
  Input: tagINPUT;
begin
  //Подготовить запись
  ZeroMemory(@Input, SizeOf(Input));
  Input.&type := INPUT_MOUSE;
  Input.Input.dx := 0;
  Input.Input.dy := 0;
  Input.Input.mouseData := 0;
  Input.Input.dwFlags := MOUSEEVENTF_MOVE;
  Input.Input.time := 0;

  //Пошевелить мышку
  SendInput(1, @Input, SizeOf(Input));
end;


procedure TApp.TrayIconMouseDown(Button: TsgeSystemTrayIconMouseButtons);
const
  TID_Active = 1;
  TID_Exit = 2;
var
  Menu: HMENU;
  s: WideString;
  Flags: UINT;
  Pt: TPoint;
  MenuID: UINT;
begin
  if Button <> mbRight then
    Exit;

  //Создать меню
  Menu := 0;
  Menu := CreatePopupMenu;

  //Пункт активность
  Flags := MF_STRING;
  case FEnable of
    True:
    begin
      s := WideString(Utf8ToAnsi(rsEnable));
      Flags := Flags or MF_CHECKED;
    end;

    False:
    begin
      s := WideString(Utf8ToAnsi(rsDisable));
      Flags := Flags or MF_UNCHECKED;
    end;
  end;
  AppendMenuW(Menu, Flags, TID_Active, PWideChar(s));

  //Разделитель
  AppendMenuW(Menu, MF_SEPARATOR, 0, nil);

  //Выход
  AppendMenuW(Menu, MF_STRING, TID_Exit, PWideChar(WideString(Utf8ToAnsi(rsExit))));

  //Вызвать меню
  SetForegroundWindow(FTrayIcon.Handle);
  GetCursorPos(Pt);
  Flags := TPM_LEFTALIGN or TPM_NONOTIFY or TPM_RETURNCMD or TPM_LEFTBUTTON;
  MenuID := UINT(TrackPopupMenuEx(Menu, Flags, Pt.X, Pt.Y, FTrayIcon.Handle, nil));

  //Определить пункт
  case MenuID of
    TID_Active:
      SetEnable(not FEnable);

    TID_Exit:
      PostMessage(FTrayIcon.Handle, WM_QUIT, 0, 0);
  end;

  //Удалить меню
  DestroyMenu(Menu);
end;


procedure TApp.TrayIconMouseDblClick(Button: TsgeSystemTrayIconMouseButtons);
var
  s: String;
begin
  if Button = mbLeft then
  begin
    //Переключить состояние
    SetEnable(not FEnable);

    //Показать сообщение
    if FEnable then
      s := rsEnable
    else
      s := rsDisable;
    FTrayIcon.ShowMessage(rsBaloonCaption, s, mtInfo);
  end;
end;


constructor TApp.Create;
begin
  //Загрузка иконок
  FIconOn := TsgeSystemIcon.CreateFromHinstance('ICON_ON');
  FIconOff := TsgeSystemIcon.CreateFromHinstance('ICON_OFF');

  //Создание иконки в трее
  FTrayIcon := TsgeSystemTrayIcon.Create(FIconOff.Handle, rsHint, True);

  //Назначение обработчиков меню
  FTrayIcon.OnMouseDown := @TrayIconMouseDown;
  FTrayIcon.OnMouseDblClick := @TrayIconMouseDblClick;

  //Таймерное событие
  FTimeEvent := TsgeSystemTimeEvent.Create(1000 * 60, False, @TimerEvent);

  //Включить присутствие
  SetEnable(True);
end;


destructor TApp.Destroy;
begin
  FTimeEvent.Free;

  FTrayIcon.Free;

  FIconOn.Free;
  FIconOff.Free;
end;


procedure TApp.Run;
var
  MSG: TMSG;
begin
  while GetMessage(MSG, 0, 0, 0) do
    DispatchMessage(MSG);
end;


{$R *.res}

begin
  App := TApp.Create;
  App.Run;
  App.Free;
end.

