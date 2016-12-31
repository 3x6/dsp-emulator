﻿unit lib_sdl2;

interface

uses
  Classes,SysUtils,dialogs{$IFDEF WINDOWS},windows{$else},dynlibs,xlib{$endif};

procedure Init_sdl_lib;
procedure close_sdl_lib;

const
  libAUDIO_S16=$8010;
  libSDL_JOYBUTTONDOWN=$603;
  libSDL_JOYBUTTONUP=$604;
  libSDL_JOYAXISMOTION=$600;
  libSDL_MOUSEMOTION=$400;
  libSDL_MOUSEBUTTONDOWN=$401;
  libSDL_MOUSEBUTTONUP=$402;
  libSDL_BUTTON_LEFT=1;
  libSDL_BUTTON_RIGHT=3;
  libSDL_KEYUP=$301;
  libSDL_KEYDOWN=$300;
  libSDL_COMMONEVENT=1;
  libSDL_QUITEV=$100;
  libSDL_WINDOWEVENT=$200;
  libSDL_TSYSWMEVENT=$201;
  libSDL_TEXTEDITING=$302;
  libSDL_TEXTINPUT=$303;
  libSDL_MOUSEWHEEL=$403;
  libSDL_JOYBALLMOTION=$601;
  libSDL_JOYHATMOTION=$602;
  libSDL_JOYDEVICEADDED=$605;
  libSDL_JOYDEVICEREMOVED=$606;
  libSDL_CONTROLLERAXISMOTION=$650;
  libSDL_CONTROLLERBUTTONDOWN=$651;
  libSDL_CONTROLLERBUTTONUP=$652;
  libSDL_CONTROLLERDEVICEADDED=$653;
  libSDL_CONTROLLERDEVICEREMOVED=$654;
  libSDL_CONTROLLERDEVICEREMAPPED=$655;
  libSDL_FINGERDOWN=$700;
  libSDL_FINGERUP=$701;
  libSDL_FINGERMOTION=$702;
  libSDL_DOLLARGESTURE=$800;
  libSDL_DOLLARRECORD=$801;
  libSDL_MULTIGESTURE=$802;
  libSDL_DROPFILE=$1000;
  libSDL_TUSEREVENT=$8000;

  libSDL_INIT_VIDEO=$00000020;
  libSDL_INIT_JOYSTICK=$00000200;
  libSDL_INIT_NOPARACHUTE=$00100000;
  libSDL_INIT_AUDIO=$00000010;
  libSDL_WINDOWPOS_UNDEFINED=$1FFF0000;
  libSDL_WINDOW_FULLSCREEN=$00000001;

{$I lib_sdl2.inc}

var
  sdl_dll_handle:int64;
  SDL_Init:function(flags:Cardinal):LongInt; cdecl;
  SDL_WasInit:function(flags:Cardinal):Cardinal; cdecl;
  SDL_Quit:procedure;cdecl;
  SDL_LoadBMP_RW:function(src:libsdlp_RWops;freesrc:LongInt):libsdlp_Surface;cdecl;
  SDL_CreateRGBSurface:function(flags:Cardinal;width:LongInt;height:LongInt;depth:LongInt;Rmask:Cardinal;Gmask:Cardinal;Bmask:Cardinal;Amask:Cardinal):libsdlp_Surface;cdecl;
  SDL_UpperBlit:function(src:libsdlp_Surface;const srcrect:libsdlp_rect;dst:libsdlp_Surface;dstrect:libsdlp_rect):LongInt;cdecl;
  SDL_FreeSurface:procedure(surface:libsdlp_Surface);cdecl;
  SDL_SaveBMP_RW:function(surface:libsdlp_Surface;dst:libsdlp_RWops;freedst:LongInt):LongInt;cdecl;
  SDL_SetColorKey:function(surface:libsdlp_Surface;flag:LongInt;key:Cardinal):LongInt;cdecl;
  SDL_JoystickUpdate:procedure;cdecl;
  SDL_JoystickGetAxis:function(joystick:libsdlp_joystick;axis:LongInt):smallint;cdecl;
  SDL_NumJoysticks:function:LongInt;cdecl;
  SDL_JoystickName:function(joystick:libsdlp_joystick):PAnsiChar;cdecl;
  SDL_JoystickNumButtons:function(joystick:libsdlp_joystick):LongInt;cdecl;
  SDL_JoystickOpen:function(device_index:LongInt):libsdlp_joystick;cdecl;
  SDL_JoystickClose:procedure(joystick:libsdlp_joystick);cdecl;
  SDL_JoystickGetButton:function(joystick:libsdlp_joystick;button:LongInt):byte;cdecl;
  SDL_JoystickNumHats:function(joystick: libsdlp_joystick):LongInt;cdecl;
  SDL_EventState:function(type_:Cardinal;state:LongInt):byte;cdecl;
  SDL_PollEvent:function(event:libSDLp_Event):LongInt;cdecl;
  SDL_GetCursor:function:libsdlP_cursor;cdecl;
  SDL_CreateCursor:function(const data:pbyte;const mask:pbyte;w:LongInt;h:LongInt;hot_x:LongInt;hot_y:LongInt):libsdlP_cursor;cdecl;
  SDL_CreateSystemCursor:function(id:word):libsdlP_cursor;cdecl;
  SDL_FreeCursor:procedure(cursor:libsdlP_Cursor);cdecl;
  SDL_SetCursor:procedure(cursor:libsdlP_cursor);cdecl;
  SDL_ShowCursor:function(toggle:LongInt):LongInt;cdecl;
  SDL_DestroyWindow:procedure(window:libsdlP_Window);cdecl;
  SDL_VideoQuit:procedure;cdecl;
  SDL_SetWindowSize:procedure(window:libsdlP_Window;w:LongInt;h:LongInt);cdecl;
  SDL_GetWindowSurface:function(window:libsdlP_Window):libsdlp_Surface;cdecl;
  SDL_CreateWindowFrom:function(const data:Pointer):libsdlP_Window;cdecl;
  SDL_CreateWindow:function(const title:PAnsiChar;x:LongInt;y:LongInt;w:LongInt;h:LongInt;flags:Cardinal):libsdlP_Window;cdecl;
  SDL_UpdateWindowSurface:function(window:libsdlP_Window):LongInt;cdecl;
  SDL_RWFromFile:function(const _file:PAnsiChar;const mode:PAnsiChar):libsdlp_RWops;cdecl;
  SDL_GetRGB:procedure(pixel:Cardinal;const format:libsdlp_PixelFormat;r:pbyte;g:pbyte;b:pbyte);cdecl;
  SDL_MapRGB:function(const format:libsdlp_PixelFormat;r:byte;g:byte;b:byte):Cardinal;cdecl;
  SDL_MapRGBA:function(const format:libsdlp_PixelFormat;r:byte;g:byte;b:byte;a:byte):Cardinal;cdecl;
  SDL_GetKeyboardState:function(numkeys:PInteger):pbyte;cdecl;
  {$ifdef fpc}
  SDL_SetError:function(const fmt:PAnsiChar):LongInt;cdecl;
  SDL_GetError:function:PAnsiChar;cdecl;
  SDL_GetTicks:function:Cardinal;cdecl;
  SDL_SetWindowTitle:procedure(window:libsdlP_Window;const title:PAnsiChar);cdecl;
  SDL_RaiseWindow:procedure (window: libsdlP_Window);cdecl;
  //Audio
  SDL_OpenAudio:function(desired:libsdlp_AudioSpec;obtained:libsdlp_AudioSpec):Integer;cdecl;
  SDL_CloseAudio:procedure;cdecl;
  SDL_QueueAudio:function (dev:libsdl_AudioDeviceID;const data:pointer;len:Cardinal):Integer;cdecl;
  SDL_PauseAudio:procedure (pause_on: Integer);cdecl;
  SDL_ClearQueuedAudio:procedure (dev:libsdl_AudioDeviceID);cdecl;
  {$endif}

implementation

procedure Init_sdl_lib;
begin
{$ifdef darwin}
sdl_dll_Handle:=LoadLibrary('libSDL2.dylib');
{$endif}
{$ifdef linux}
sdl_dll_Handle:=LoadLibrary('libSDL2.so');
if sdl_dll_Handle=0 then sdl_dll_Handle:=LoadLibrary('libSDL2.so.0');
if sdl_dll_Handle=0 then sdl_dll_Handle:=LoadLibrary('libSDL2-2.0.so.0');
{$endif}
{$ifdef windows}
sdl_dll_Handle:=LoadLibrary('sdl2.dll');
{$endif}
if sdl_dll_Handle=0 then begin
  MessageDlg('SDL2 library not found.'+chr(10)+chr(13)+'Please read the documentation!', mtError,[mbOk], 0);
  halt(0);
end;
//sdl
@SDL_Init:=GetProcAddress(sdl_dll_Handle,'SDL_Init');
@SDL_WasInit:=GetProcAddress(sdl_dll_Handle,'SDL_WasInit');
@SDL_Quit:=GetProcAddress(sdl_dll_Handle,'SDL_Quit');
//surface
@SDL_LoadBMP_RW:=GetProcAddress(sdl_dll_Handle,'SDL_LoadBMP_RW');
@SDL_CreateRGBSurface:=GetProcAddress(sdl_dll_Handle,'SDL_CreateRGBSurface');
@SDL_UpperBlit:=GetProcAddress(sdl_dll_Handle,'SDL_UpperBlit');
@SDL_FreeSurface:=GetProcAddress(sdl_dll_Handle,'SDL_FreeSurface');
@SDL_SaveBMP_RW:=GetProcAddress(sdl_dll_Handle,'SDL_SaveBMP_RW');
@SDL_SetColorKey:=GetProcAddress(sdl_dll_Handle,'SDL_SetColorKey');
//joystick
@SDL_JoystickUpdate:=GetProcAddress(sdl_dll_Handle,'SDL_JoystickUpdate');
@SDL_JoystickGetAxis:=GetProcAddress(sdl_dll_Handle,'SDL_JoystickGetAxis');
@SDL_NumJoysticks:=GetProcAddress(sdl_dll_Handle,'SDL_NumJoysticks');
@SDL_JoystickName:=GetProcAddress(sdl_dll_Handle,'SDL_JoystickName');
@SDL_JoystickNumButtons:=GetProcAddress(sdl_dll_Handle,'SDL_JoystickNumButtons');
@SDL_JoystickOpen:=GetProcAddress(sdl_dll_Handle,'SDL_JoystickOpen');
@SDL_JoystickClose:=GetProcAddress(sdl_dll_Handle,'SDL_JoystickClose');
@SDL_JoystickGetButton:=GetProcAddress(sdl_dll_Handle,'SDL_JoystickGetButton');
@SDL_JoystickNumHats:=GetProcAddress(sdl_dll_Handle,'SDL_JoystickNumHats');
//events
@SDL_EventState:=GetProcAddress(sdl_dll_Handle,'SDL_EventState');
@SDL_PollEvent:=GetProcAddress(sdl_dll_Handle,'SDL_PollEvent');
//mouse
@SDL_GetCursor:=GetProcAddress(sdl_dll_Handle,'SDL_GetCursor');
@SDL_CreateCursor:=GetProcAddress(sdl_dll_Handle,'SDL_CreateCursor');
@SDL_SetCursor:=GetProcAddress(sdl_dll_Handle,'SDL_SetCursor');
@SDL_ShowCursor:=GetProcAddress(sdl_dll_Handle,'SDL_ShowCursor');
@SDL_CreateSystemCursor:=GetProcAddress(sdl_dll_Handle,'SDL_CreateSystemCursor');
@SDL_FreeCursor:=GetProcAddress(sdl_dll_Handle,'SDL_FreeCursor');
//video
@SDL_DestroyWindow:=GetProcAddress(sdl_dll_Handle,'SDL_DestroyWindow');
@SDL_VideoQuit:=GetProcAddress(sdl_dll_Handle,'SDL_VideoQuit');
@SDL_SetWindowSize:=GetProcAddress(sdl_dll_Handle,'SDL_SetWindowSize');
@SDL_GetWindowSurface:=GetProcAddress(sdl_dll_Handle,'SDL_GetWindowSurface');
@SDL_CreateWindowFrom:=GetProcAddress(sdl_dll_Handle,'SDL_CreateWindowFrom');
@SDL_CreateWindow:=GetProcAddress(sdl_dll_Handle,'SDL_CreateWindow');
@SDL_UpdateWindowSurface:=GetProcAddress(sdl_dll_Handle,'SDL_UpdateWindowSurface');
//rwops
@SDL_RWFromFile:=GetProcAddress(sdl_dll_Handle,'SDL_RWFromFile');
//pixels
@SDL_GetRGB:=GetProcAddress(sdl_dll_Handle,'SDL_GetRGB');
@SDL_MapRGB:=GetProcAddress(sdl_dll_Handle,'SDL_MapRGB');
@SDL_MapRGBA:=GetProcAddress(sdl_dll_Handle,'SDL_MapRGBA');
//keyboard
@SDL_GetKeyboardState:=GetProcAddress(sdl_dll_Handle,'SDL_GetKeyboardState');
{$ifdef fpc}
//error
@SDL_SetError:=GetProcAddress(sdl_dll_Handle,'SDL_SetError');
@SDL_GetError:=GetProcAddress(sdl_dll_Handle,'SDL_GetError');
//timer
@SDL_GetTicks:=GetProcAddress(sdl_dll_Handle,'SDL_GetTicks');
//video
@SDL_SetWindowTitle:=GetProcAddress(sdl_dll_Handle,'SDL_SetWindowTitle');
@SDL_RaiseWindow:=GetProcAddress(sdl_dll_Handle,'SDL_RaiseWindow');
//Audio
@SDL_OpenAudio:=GetProcAddress(sdl_dll_Handle,'SDL_OpenAudio');
@SDL_CloseAudio:=GetProcAddress(sdl_dll_Handle,'SDL_CloseAudio');
@SDL_QueueAudio:=GetProcAddress(sdl_dll_Handle,'SDL_QueueAudio');
@SDL_PauseAudio:=GetProcAddress(sdl_dll_Handle,'SDL_PauseAudio');
@SDL_ClearQueuedAudio:=GetProcAddress(sdl_dll_Handle,'SDL_ClearQueuedAudio');
{$endif}
end;

procedure close_sdl_lib;
begin
if sdl_dll_handle<>0 then begin
   FreeLibrary(sdl_dll_Handle);
   sdl_dll_handle:=0;
end;
end;

end.

