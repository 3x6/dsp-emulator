unit spectrum_misc;

interface

uses lib_sdl2,{$IFDEF WINDOWS}windows,{$ENDIF}
     principal,nz80,z80_sp,spectrum_128k,ay_8910,controls_engine,sysutils,
     forms,lenguaje,spectrum_48k,dialogs,spectrum_3,upd765,cargar_spec,
     gfx_engine,main_engine,graphics,pal_engine,sound_engine,tape_window,
     z80pio,z80daisy,disk_file_format;

const tabla_scr:array[0..191] of word=(
        0,    256, 512, 768,1024,1280,1536,1792,
        32,   288, 544, 800,1056,1312,1568,1824,
        64,   320, 576, 832,1088,1344,1600,1856,
        96,   352, 608, 864,1120,1376,1632,1888,
        128,  384, 640, 896,1152,1408,1664,1920,
        160,  416, 672, 928,1184,1440,1696,1952,
        192,  448, 704, 960,1216,1472,1728,1984,
        224,  480, 736, 992,1248,1504,1760,2016,
        2048,2304,2560,2816,3072,3328,3584,3840,
        2080,2336,2592,2848,3104,3360,3616,3872,
        2112,2368,2624,2880,3136,3392,3648,3904,
        2144,2400,2656,2912,3168,3424,3680,3936,
        2176,2432,2688,2944,3200,3456,3712,3968,
        2208,2464,2720,2976,3232,3488,3744,4000,
        2240,2496,2752,3008,3264,3520,3776,4032,
        2272,2528,2784,3040,3296,3552,3808,4064,
        4096,4352,4608,4864,5120,5376,5632,5888,
        4128,4384,4640,4896,5152,5408,5664,5920,
        4160,4416,4672,4928,5184,5440,5696,5952,
        4192,4448,4704,4960,5216,5472,5728,5984,
        4224,4480,4736,4992,5248,5504,5760,6016,
        4256,4512,4768,5024,5280,5536,5792,6048,
        4288,4544,4800,5056,5312,5568,5824,6080,
        4320,4576,4832,5088,5344,5600,5856,6112);

        spec_paleta:array[0..15] of integer=(
        $000000,$C00000,$0000C0,$C000C0,
        $00C000,$C0C000,$00C0C0,$C0C0C0,
        $000000,$FF0000,$0000FF,$FF00FF,
        $00FF00,$FFFF00,$00FFFF,$FFFFFF);

        gif_paleta:array[0..15] of integer=(
        $000000,$E70000,$0000E7,$E700E7,
        $00E700,$E7E700,$00E7E7,$E7E7E7,
        $000000,$FF0000,$0000FF,$FF00FF,
        $00FF00,$FFFF00,$00FFFF,$FFFFFF);

        cmemory:array[0..127] of byte=(
          6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,
          6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,
          6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,
          6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0,6,5,4,3,2,1,0,0);

type
  tmouse_spectrum=record
    //General
    tipo,botones:byte;
    x,y,x_act,y_act:word;
    //AMX Mouse
    data_a,data_b:byte;
    //Gunstick
    lg_val:byte;
    gs_activa:boolean;
  end;
  tinterface2_spectrum=record
    retraso:dword;
    cargado:boolean;
    hay_if2:boolean;
    rom:array[0..$7FFF] of byte;
  end;
  tborde_spectrum=record
    tipo:byte;
    borde_spectrum:procedure(linea:word);
    buffer:array[0..312*250] of byte;
    color:byte;
    posicion:byte;
  end;
  tulaplus_spectrum=record
    activa:boolean;
    paleta:array[0..63] of byte;
    last_reg:byte;
    mode:byte;
    enabled:boolean;
  end;
var
      ulaplus:tulaplus_spectrum;
      key_spec:array [0..255] of boolean;
      buffer_beeper:array[0..$5FFF] of word;
      spectrum_irq_pos:byte;
      posicion_beep:word;
      key6_0,keyY_P,key1_5,keyQ_T,keyH_ENT,keyCAPS_V,keyA_G,keyB_SPC,kempston:byte;
      buffer_video:array[0..6143] of boolean;
      flash:byte;
      haz_flash,audio_load:boolean;
      testados_sonido,testados_sonido_beeper,samples_audio,samples_beeper:single;
      posicion_beeper:word;
      pantalla_128k,old_7ffd:byte;
      marco:array[0..3] of byte;
      interface2:tinterface2_spectrum;
      jkempston,jcursor,jsinclair1,jsinclair2:boolean;
      issue2,sd_1:boolean;
      retraso:array[0..71000] of byte;
      ft_bus:array[0..71000] of word;
      beeper_filter:boolean;
      fastload:boolean;
      altavoz,beeper_oversample:byte;
      mouse:tmouse_spectrum;
      borde:tborde_spectrum;
      audio_128k,ear_channel:byte;
      kb_0,kb_1,kb_2,kb_3,kb_4:boolean;
      adr_8,adr_9,adr_10,adr_11,adr_12,adr_13,adr_14,adr_15:boolean;

procedure spectrum_config;
function spectrum_mensaje:string;
procedure borde_normal(linea:word);
procedure eventos_spectrum;
function spec_comun:boolean;
procedure spec_cerrar_comun;
function spectrum_tapes:boolean;
procedure grabar_spec;
procedure reset_misc;
procedure spectrum_despues_instruccion(estados_t:byte);
procedure evalua_gunstick;
procedure spec_a_pantalla(posicion_memoria:pbyte;imagen1:Tbitmap);
//AMX Mouse
procedure pio_int_main(state:byte);
function pio_read_porta:byte;
function pio_read_portb:byte;


implementation
uses tap_tzx,snapshot,config;

procedure evalua_gunstick;
var
  gs_temp:byte;
begin
if mouse.gs_activa then begin
    mouse.gs_activa:=false;
    key6_0:=key6_0 or 4;
    kempston:=(kempston and $FB);
    mouse.lg_val:=mouse.lg_val and $ef;
end;
case main_vars.tipo_maquina of
  0,5:gs_temp:=memoria[$5800+mouse.y+mouse.x];
  1,4:gs_temp:=memoria_128k[pantalla_128k,$1800+mouse.y+mouse.x];
  2,3:gs_temp:=memoria_3[pantalla_128k,$1800+mouse.y+mouse.x];
end;
if ((gs_temp=63) or (gs_temp=127)) then begin
  mouse.gs_activa:=true;
  key6_0:=key6_0 And $FB;
  kempston:=(kempston or 4);
  mouse.lg_val:=mouse.lg_val or $10;
end;
end;

procedure spectrum_reset_video;
begin
fillchar(buffer_video[0],6144,1);
fillchar(borde.buffer[0],78000,$80);
end;

procedure borde_normal(linea:word);
var
        linea_actual:word;
begin
if ((main_screen.rapido and ((linea and 7)<>0)) or (borde.tipo=0) or (linea<15) or (linea>302)) then exit;
if borde.buffer[linea]=borde.color then exit;
//poner_linea:=true;
borde.buffer[linea]:=borde.color;
linea_actual:=linea-15;
case linea of
        15..62,255..302:begin
                          single_line(0,linea_actual,borde.color,352,1);
                          actualiza_trozo_simple(0,linea_actual,352,1,1);
                        end;
        63..254:begin
                    single_line(0,linea_actual,borde.color,48,1);
                    actualiza_trozo_simple(0,linea_actual,48,1,1);
                    single_line(304,linea_actual,borde.color,48,1);
                    actualiza_trozo_simple(304,linea_actual,48,1,1);
                end;
        else exit;
end;
end;

procedure teclado_matriz;
begin
end;

procedure eventos_spectrum;
begin
if (event.mouse and (mouse.tipo<>0)) then begin
  case mouse.tipo of
    1:begin  //Gunstick
        if raton.y<48 then mouse.y:=0
          else if raton.y>239 then mouse.y:=$ff
            else mouse.y:=(((raton.y-48) and $f8) shl 2);
        if raton.x<48 then mouse.x:=0
          else if raton.x>303 then mouse.x:=$ff
            else mouse.x:=(raton.x-48) shr 3;
        if raton.button1 then begin
           key6_0:=(key6_0 and $fe);
           kempston:=(kempston or $10);
           mouse.lg_val:=mouse.lg_val and $df;
        end else begin
          key6_0:=(key6_0 or 1);
          kempston:=(kempston and $EF);
          mouse.lg_val:=mouse.lg_val or $20;
        end;
      end;
    2:begin
        if raton.y<48 then mouse.y:=$ff
          else if raton.y>239 then mouse.y:=0
            else mouse.y:=255-trunc((raton.y-48)*1.333);
        if raton.x<48 then mouse.x:=0
          else if raton.x>303 then mouse.x:=$ff
            else mouse.x:=raton.x-48;
        if raton.button2 then mouse.botones:=mouse.botones and $FE
          else mouse.botones:=mouse.botones or 1;
        if raton.button1 then mouse.botones:=mouse.botones and $FD
          else mouse.botones:=mouse.botones or 2;
      end;
    3:begin
        if (raton.y<48) then mouse.y:=0
          else if (raton.y>239) then mouse.y:=$e1
            else mouse.y:=trunc((raton.y-48)*1.17647);
        if raton.x<48 then mouse.x:=0
          else if raton.x>303 then mouse.x:=$12b
            else mouse.x:=trunc((raton.x-48)*1.17647);
        if raton.button1 then mouse.botones:=mouse.botones and $7f
          else mouse.botones:=mouse.botones or $80;
        if raton.button2 then mouse.botones:=mouse.botones and $df // $bf
          else mouse.botones:=mouse.botones or $20;
        if mouse.x<>mouse.x_act then begin
          z80pio_astb_w(0,false);
          z80pio_astb_w(0,true);
        end;
        if mouse.y<>mouse.y_act then begin
          z80pio_bstb_w(0,false);
          z80pio_bstb_w(0,true);
        end;
    end;
  end;
end;
if event.keyboard then begin
  if ((keyboard[KEYBOARD_F1]) and cinta_tzx.cargada) then begin
    if cinta_tzx.play_tape then tape_window1.fStopCinta(nil)
      else tape_window1.fPlayCinta(nil);
  end;
  if ((keyboard[KEYBOARD_F5]) and (main_vars.tipo_maquina=2)) then begin
    clear_disk(0);
    change_caption(llamadas_maquina.caption);
  end;
  if false then teclado_matriz
    else copymemory(@key_spec[0],@keyboard[0],256);
  if key_spec[KEYBOARD_1] then key1_5:=(key1_5 And $FE) else key1_5:=(key1_5 or 1);
  if key_spec[KEYBOARD_2] then key1_5:=(key1_5 And $FD) else key1_5:=(key1_5 or 2);
  if key_spec[KEYBOARD_3] then key1_5:=key1_5 And $FB else key1_5:=key1_5 or 4;
  if key_spec[KEYBOARD_4] then key1_5:=key1_5 And $F7 else key1_5:=key1_5 or 8;
  if key_spec[KEYBOARD_5] then key1_5:=key1_5 And $EF else key1_5:=key1_5 or $10;
  if key_spec[KEYBOARD_0] then key6_0:=key6_0 And $FE else key6_0:=key6_0 or 1;
  if key_spec[KEYBOARD_9] then key6_0:=key6_0 And $FD else key6_0:=key6_0 or 2;
  if key_spec[KEYBOARD_8] then key6_0:=key6_0 And $FB else key6_0:=key6_0 or 4;
  if key_spec[KEYBOARD_7] then key6_0:=key6_0 And $F7 else key6_0:=key6_0 or 8;
  if key_spec[KEYBOARD_6] then key6_0:=key6_0 And $EF else key6_0:=key6_0 or $10;
  if key_spec[KEYBOARD_Q] then keyQ_T:=keyQ_T And $FE else keyQ_T:=keyQ_T or 1;
  if key_spec[KEYBOARD_W] then keyQ_T:=keyQ_T And $FD else keyQ_T:=keyQ_T or 2;
  if key_spec[KEYBOARD_E] then keyQ_T:=keyQ_T And $FB else keyQ_T:=keyQ_T or 4;
  if key_spec[KEYBOARD_R] then keyQ_T:=keyQ_T And $F7 else keyQ_T:=keyQ_T or 8;
  if key_spec[KEYBOARD_T] then keyQ_T:=keyQ_T And $EF else keyQ_T:=keyQ_T or $10;
  if key_spec[KEYBOARD_P] then keyY_P:=keyY_P And $FE else keyY_P:=keyY_P or 1;
  if key_spec[KEYBOARD_O] then keyY_P:=keyY_P And $FD else keyY_P:=keyY_P or 2;
  if key_spec[KEYBOARD_I] then keyY_P:=keyY_P And $FB else keyY_P:=keyY_P or 4;
  if key_spec[KEYBOARD_U] then keyY_P:=keyY_P And $F7 else keyY_P:=keyY_P or 8;
  if key_spec[KEYBOARD_Y] then keyY_P:=keyY_P And $EF else keyY_P:=keyY_P or $10;
  if key_spec[KEYBOARD_RETURN] then keyH_ENT:=keyH_ENT And $FE else keyH_ENT:=keyH_ENT or 1;
  if key_spec[KEYBOARD_L] then keyH_ENT:=keyH_ENT And $FD else keyH_ENT:=keyH_ENT or 2;
  if key_spec[KEYBOARD_K] then keyH_ENT:=keyH_ENT And $FB else keyH_ENT:=keyH_ENT or 4;
  if key_spec[KEYBOARD_J] then keyH_ENT:=keyH_ENT And $F7 else keyH_ENT:=keyH_ENT or 8;
  if key_spec[KEYBOARD_H] then keyH_ENT:=keyH_ENT And $EF else keyH_ENT:=keyH_ENT or $10;
  if key_spec[KEYBOARD_A] then keyA_G:=keyA_G And $FE else keyA_G:=keyA_G or 1;
  if key_spec[KEYBOARD_S] then keyA_G:=keyA_G And $FD else keyA_G:=keyA_G or 2;
  if key_spec[KEYBOARD_D] then keyA_G:=keyA_G And $FB else keyA_G:=keyA_G or 4;
  if key_spec[KEYBOARD_F] then keyA_G:=keyA_G And $F7 else keyA_G:=keyA_G or 8;
  if key_spec[KEYBOARD_G] then keyA_G:=keyA_G And $EF else keyA_G:=keyA_G or $10;
  if (key_spec[KEYBOARD_LCTRL] or key_spec[KEYBOARD_RCTRL]) then keyCAPS_V:=(keyCAPS_V And $FE) else keyCAPS_V:=(keyCAPS_V or 1);
  if key_spec[KEYBOARD_Z] then keyCAPS_V:=keyCAPS_V And $FD else keyCAPS_V:=keyCAPS_V or 2;
  if key_spec[KEYBOARD_X] then keyCAPS_V:=keyCAPS_V And $FB else keyCAPS_V:=keyCAPS_V or 4;
  if key_spec[KEYBOARD_C] then keyCAPS_V:=keyCAPS_V And $F7 else keyCAPS_V:=keyCAPS_V or 8;
  if key_spec[KEYBOARD_V] then keyCAPS_V:=keyCAPS_V And $EF else keyCAPS_V:=keyCAPS_V or $10;
  if key_spec[KEYBOARD_SPACE] then keyB_SPC:=keyB_SPC And $FE else keyB_SPC:=keyB_SPC or 1;
  if (key_spec[KEYBOARD_LSHIFT] or key_spec[KEYBOARD_RSHIFT]) then keyB_SPC:=keyB_SPC And $FD else keyB_SPC:=keyB_SPC or 2;
  if key_spec[KEYBOARD_M] then keyB_SPC:=keyB_SPC And $FB else keyB_SPC:=keyB_SPC or 4;
  if key_spec[KEYBOARD_N] then keyB_SPC:=keyB_SPC And $F7 else keyB_SPC:=keyB_SPC or 8;
  if key_spec[KEYBOARD_B] then keyB_SPC:=keyB_SPC And $EF else keyB_SPC:=keyB_SPC or $10;
  //Teclas del Spectrum +  y siguientes
  if key_spec[KEYBOARD_FILA2_T2] then begin //CAPS+1 Edit
    key1_5:=(key1_5 And $FE);
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_capslock] then begin //CAPS+2
    key1_5:=key1_5 And $FD;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_FILA0_T1] then begin //CAPS+3 True Video
    key1_5:=key1_5 And $FB;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_FILA0_T2] then begin //CAPS+4 Inv Video
    key1_5:=key1_5 And $F7;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_LEFT] then begin //CAPS+5
    key1_5:=key1_5 And $EF;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_DOWN] then begin //CAPS+6
    key6_0:=key6_0 And $EF;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_UP] then begin //CAPS+7
    key6_0:=key6_0 And $F7;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_RIGHT] then begin //CAPS+8
    key6_0:=key6_0 And $FB;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_FILA0_T0] then begin //CAPS+9 Graphics
    key6_0:=key6_0 And $FD;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_BACKSPACE] then begin //CAPS+0
    key6_0:=key6_0 and $FE;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_escape] then begin //CAPS+SPACE Break
    keyB_SPC:=keyB_SPC And $FE;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_tab] then begin //CAPS+SHIFT Extended Mode
    keyB_SPC:=keyB_SPC And $FD;
    keyCAPS_V:=keyCAPS_V and $FE;
  end;
  if key_spec[KEYBOARD_FILA3_T0] then begin // "
    keyB_SPC:=keyB_SPC And $FD;
    keyY_P:=keyY_P And $FE;
  end;
  if key_spec[KEYBOARD_FILA3_T3] then begin // ;
    keyB_SPC:=keyB_SPC And $FD;
    keyY_P:=keyY_P And $FD;
  end;
  if key_spec[KEYBOARD_FILA3_T2] then begin // .
    keyB_SPC:=keyB_SPC And $FD;
    keyB_SPC:=keyB_SPC And $FB;
  end;
  if key_spec[KEYBOARD_FILA3_T1] then begin // ,
    keyB_SPC:=keyB_SPC And $FD;
    keyB_SPC:=keyB_SPC And $F7;
  end;
end;
if event.arcade then begin
  if mouse.tipo=3 then begin
    if arcade_input.but0[0] then mouse.botones:=mouse.botones and $bf
          else mouse.botones:=mouse.botones or $40;
  end;
  if jkempston then begin
    if arcade_input.up[0] then kempston:=(kempston or 8) else kempston:=(kempston and $F7);
    if arcade_input.down[0] then kempston:=(kempston or 4) else kempston:=(kempston and $FB);
    if arcade_input.left[0] then kempston:=(kempston or 2) else kempston:=(kempston and $FD);
    if arcade_input.right[0] then kempston:=(kempston or 1) else kempston:=(kempston and $FE);
    if arcade_input.but0[0] then kempston:=(kempston or $10) else kempston:=(kempston and $EF);
  end;
  if jcursor then begin
    if arcade_input.left[0] then key1_5:=(key1_5 And $EF) else key1_5:=(key1_5 or $10);
    if arcade_input.but0[0] then key6_0:=(key6_0 And $FE) else key6_0:=(key6_0 or 1);
    if arcade_input.right[0] then key6_0:=(key6_0 And $FB) else key6_0:=(key6_0 or 4);
    if arcade_input.up[0] then key6_0:=(key6_0 And $F7) else key6_0:=(key6_0 or 8);
    if arcade_input.down[0] then key6_0:=(key6_0 And $EF) else key6_0:=(key6_0 or $10);
  end;
  if jsinclair1 then begin
    if arcade_input.but0[0] then key6_0:=key6_0 And $FE else key6_0:=key6_0 or 1;
    if arcade_input.up[0] then key6_0:=key6_0 And $FD else key6_0:=key6_0 or 2;
    if arcade_input.down[0] then key6_0:=key6_0 And $FB else key6_0:=key6_0 or 4;
    if arcade_input.right[0] then key6_0:=key6_0 And $F7 else key6_0:=key6_0 or 8;
    if arcade_input.left[0] then key6_0:=key6_0 And $EF else key6_0:=key6_0 or $10;
  end;
  if jsinclair2 then begin
    if arcade_input.left[0] then key1_5:=(key1_5 And $FE) else key1_5:=(key1_5 or 1);
    if arcade_input.right[0] then key1_5:=(key1_5 And $FD) else key1_5:=(key1_5 or 2);
    if arcade_input.down[0] then key1_5:=key1_5 And $FB else key1_5:=key1_5 or 4;
    if arcade_input.up[0] then key1_5:=key1_5 And $F7 else key1_5:=key1_5 or 8;
    if arcade_input.but0[0] then key1_5:=key1_5 And $EF else key1_5:=key1_5 or $10;
  end;
end;
end;

function spec_comun:boolean;
var
        colores:tpaleta;
        f,npal:byte;
begin
spec_comun:=false;
spec_z80:=cpu_z80_sp.create(1,1);
if borde.tipo=2 then begin
  case main_vars.tipo_maquina of
    0,5:borde.borde_spectrum:=borde_48_full;
    1,2,3,4:borde.borde_spectrum:=borde_128_full;
  end;
end else borde.borde_spectrum:=borde_normal;
principal1.BitBtn10.Glyph:=nil;
principal1.ImageList2.GetBitmap(3,principal1.BitBtn10.Glyph);
principal1.BitBtn14.Glyph:=nil;
principal1.imagelist2.GetBitmap(0,principal1.BitBtn14.Glyph);
//Tape Stop and Fastload enabled
fastload:=true;
cinta_tzx.play_tape:=false;
tape_window1.BitBtn1.Enabled:=true;
tape_window1.BitBtn2.Enabled:=false;
main_vars.mensaje_general:='';
main_vars.frames_sec:=0;
screen_init(1,352,288);
iniciar_video(352,288);
npal:=16;
for f:=0 to 15 do begin
  colores[f].b:=spec_paleta[f] shr 16;
  colores[f].g:=(spec_paleta[f] shr 8) and $FF;
  colores[f].r:=spec_paleta[f] and $FF;
end;
if not(ulaplus.activa) then begin
  for f:=16 to 79 do begin  //los colores iniciales de la ULA+
    colores[f].b:=0;
    colores[f].g:=0;
    colores[f].r:=0;
  end;
  npal:=80;
end;
set_pal(colores,npal);
haz_flash:=false;
old_cursor:=sdl_getcursor;
sdl_setcursor(sdl_createcursor(@cdata,@cmask,16,16,7,7));
if mouse.tipo<>0 then sdl_showcursor(1)
  else sdl_showcursor(0);
ear_channel:=init_channel; //iniciar un canal para el ear (el otro lo inicia el AY si hace falta)
spec_comun:=true;
if cinta_tzx.cargada then tape_window1.Show;
end;

procedure reset_misc;
begin
spec_z80.reset;
reset_audio;
posicion_beep:=0;
if cinta_tzx.cargada then cinta_tzx.play_once:=false;
key6_0:=$ff;keyY_P:=$ff;keyQ_T:=$ff;key1_5:=$ff;keyH_ENT:=$ff;keyA_G:=$FF;keyCAPS_V:=$FF;keyB_SPC:=$FF;
kempston:=0;
mouse.lg_val:=$20;
flash:=0;
spectrum_irq_pos:=0;
cinta_tzx.value:=0;
altavoz:=0;
spec_z80.im2_lo:=$ff;
fillchar(borde.buffer[0],78000,$80);
fillchar(buffer_beeper[0],$6000,0);
if not(ulaplus.enabled) then begin
  ulaplus.activa:=false;
  fillchar(ulaplus.paleta[0],64,0);
  ulaplus.last_reg:=0;
end;
kb_0:=false;
kb_1:=false;
kb_2:=false;
kb_3:=false;
kb_4:=false;
adr_8:=false;
adr_9:=false;
adr_10:=false;
adr_11:=false;
adr_12:=false;
adr_13:=false;
adr_14:=false;
adr_15:=false;
if mouse.tipo=3 then begin
  z80pio_init(0,pio_int_main,pio_read_porta,nil,nil,pio_read_portb);
  z80daisy_init(Z80_PIO_TYPE);
  z80pio_reset(0);
  spec_z80.daisy:=true;
end;
mouse.x:=0;
mouse.y:=0;
mouse.x_act:=0;
mouse.y_act:=0;
mouse.botones:=$FF;
mouse.data_a:=0;
mouse.data_b:=0;
if interface2.hay_if2 then begin
  interface2.cargado:=false;
  interface2.retraso:=0;
  copymemory(@memoria[0],@interface2.rom[0],$4000);
end;
spectrum_reset_video;
end;

procedure spec_cerrar_comun;
begin
sdl_setcursor(old_cursor);
rom_cambiada_48:=false;
if main_vars.tipo_maquina=2 then begin
  ResetFDC;
  clear_disk(0);
end;
end;

function spectrum_tapes:boolean;
begin
load_spec.show;
while load_spec.showing do application.HandleMessage;
spectrum_tapes:=true;
end;

procedure grabar_spec;
var
  nombre:string;
  correcto:boolean;
begin
principal1.savedialog1.InitialDir:=Directory.spectrum_snap;
if ((main_vars.tipo_maquina=2) or (main_vars.tipo_maquina=3)) then principal1.saveDialog1.Filter := 'SZX Format (*.SZX)|*.SZX|Z80 Format (*.Z80)|*.Z80|DSP Format (*.DSP)|*.DSP'
  else principal1.saveDialog1.Filter := 'SZX Format (*.SZX)|*.SZX|Z80 Format (*.Z80)|*.Z80|DSP Format (*.DSP)|*.DSP|SNA Format (*.SNA)|*.SNA';
if principal1.savedialog1.execute then begin
        nombre:=principal1.savedialog1.FileName;
        case principal1.SaveDialog1.FilterIndex of
          1:nombre:=changefileext(nombre,'.szx');
          2:nombre:=changefileext(nombre,'.z80');
          3:nombre:=changefileext(nombre,'.dsp');
          4:nombre:=changefileext(nombre,'.sna');
        end;
        if FileExists(nombre) then begin
            if MessageDlg(leng[main_vars.idioma].mensajes[3], mtWarning, [mbYes]+[mbNo],0)=7 then exit;
        end;
        case principal1.SaveDialog1.FilterIndex of
          1:correcto:=grabar_szx(nombre);
          2:correcto:=grabar_z80(nombre,false);
          3:correcto:=grabar_z80(nombre,true);
          4:correcto:=grabar_sna(nombre);
        end;
        if not(correcto) then MessageDlg('No se ha podido guardar el snapshot!',mtError,[mbOk],0)
          else Directory.spectrum_snap:=extractfiledir(principal1.savedialog1.FileName)+main_vars.cadena_dir;
end;
end;

procedure spectrum_despues_instruccion(estados_t:byte);
var
  audio:pinteger;
  audio_buff:array[0..3] of integer;
  beeper,f,h:word;
  spec_z80_reg:npreg_z80;
begin
//Longitud de la IRQ probado con el Soldier of Fortune
spectrum_irq_pos:=spectrum_irq_pos+estados_t;
if ((spectrum_irq_pos>31) and (spec_z80.pedir_irq<>CLEAR_LINE)) then spec_z80.pedir_irq:=CLEAR_LINE;
if sound_status.hay_sonido then begin
  testados_sonido:=testados_sonido+estados_t;
  testados_sonido_beeper:=testados_sonido_beeper+estados_t;
  if testados_sonido_beeper>=samples_beeper then begin
    testados_sonido_beeper:=testados_sonido_beeper-samples_beeper;
    if ((cinta_tzx.play_tape and not(cinta_tzx.es_tap)) and audio_load) then beeper:=cinta_tzx.value
      else beeper:=altavoz;
    if beeper<>0 then buffer_beeper[posicion_beeper]:=$1fff
        else buffer_beeper[posicion_beeper]:=0;
    posicion_beeper:=posicion_beeper+1;
  end;
  if testados_sonido>=samples_audio then begin
    testados_sonido:=testados_sonido-samples_audio;
    if ((main_vars.tipo_maquina<>0) and (main_vars.tipo_maquina<>5)) then begin
      case audio_128k of
        0:tsample[ay8910_0.get_sample_num,sound_status.posicion_sonido]:=ay8910_0.update_internal^;
        1,2:begin
            audio:=ay8910_0.update_internal;
            copymemory(@audio_buff[0],pbyte(audio),4*2);
            tsample[ay8910_0.get_sample_num,sound_status.posicion_sonido]:=(audio_buff[1]*2+audio_buff[2]);
            sound_status.posicion_sonido:=sound_status.posicion_sonido+1;
            tsample[ear_channel,sound_status.posicion_sonido]:=tsample[ear_channel,sound_status.posicion_sonido-1];
            tsample[ay8910_0.get_sample_num,sound_status.posicion_sonido]:=(audio_buff[3]*2+audio_buff[2]);
          end;
      end;
    end;
    if sound_status.posicion_sonido=(sound_status.long_sample-1) then begin
      //Resampleado del beeper
      for f:=0 to (sound_status.long_sample-1) do begin
          beeper:=0;
          for h:=0 to beeper_oversample-1 do beeper:=beeper+(buffer_beeper[(f*beeper_oversample)+h]);
          tsample[ear_channel,f]:=beeper div beeper_oversample;
      end;
      if beeper_filter then for f:=1 to (sound_status.long_sample-1) do tsample[ear_channel,f]:=(tsample[ear_channel,f]+tsample[ear_channel,f-1]) shr 1;
      posicion_beeper:=0;
      play_sonido;
    end else sound_status.posicion_sonido:=sound_status.posicion_sonido+1;
  end;
end;
if cinta_tzx.cargada then begin
    spec_z80_reg:=spec_z80.get_internal_r;
    if cinta_tzx.play_tape then begin
      if (fastload and (cinta_tzx.datos_tzx[cinta_tzx.indice_cinta].tipo_bloque=$10) and not(cinta_tzx.en_pausa)) then begin
        if (spec_z80_reg.pc=$056b) then play_cinta_tap(spec_z80_reg);
      end else begin
        cinta_tzx.estados:=cinta_tzx.estados+estados_t;
        play_cinta_tzx;
      end;
    end else begin
      if ((spec_z80_reg.pc=$0556) and not(cinta_tzx.play_once)) then begin
       cinta_tzx.play_once:=true;
       if not(cinta_tzx.es_tap) then main_screen.rapido:=true;
       tape_window1.fPlayCinta(nil);
      end;
    end;
end;
//Cargar ROMS 32k Interface II
if interface2.hay_if2 and not(interface2.cargado) then begin
  interface2.retraso:=interface2.retraso+estados_t;
  if interface2.retraso>10500000 then begin
    interface2.cargado:=true;
    copymemory(@memoria[0],@interface2.rom[$4000],$4000);
  end;
end;
end;

function spectrum_mensaje:string;
begin
if cinta_tzx.play_tape then
  spectrum_mensaje:='    '+leng[main_vars.idioma].mensajes[1]+': '+inttostr(datos_totales_tzx);
end;

procedure spectrum_config;
begin
ConfigSP.show;
while ConfigSP.Showing do application.ProcessMessages;
end;

procedure spec_a_pantalla(posicion_memoria:pbyte;imagen1:tbitmap);
var
  x,y,f,atrib,video_col,color,color2:byte;
  pos_video:word;
  pvideo:pbyte;
begin
imagen1.Height:=192;
imagen1.Width:=256;
x:=0;
for y:=0 to 191 do begin
  pos_video:=(y shr 3) shl 5;
  for f:=0 to 31 do begin
    pvideo:=posicion_memoria;
    inc(pvideo,$1800+pos_video);
    atrib:=pvideo^;
    pvideo:=posicion_memoria;
    inc(pvideo,tabla_scr[y]+f);
    video_col:=pvideo^;
    color2:=(atrib shr 3) and 7;
    color:=atrib and 7;
    if (atrib and 64)<>0 then begin inc(color,8);inc(color2,8);end;
    if (video_col and 128)<>0 then imagen1.Canvas.Pixels[x,y]:=gif_paleta[color] else imagen1.Canvas.Pixels[x,y]:=gif_paleta[color2];inc(x);
    if (video_col and 64)<>0 then imagen1.Canvas.Pixels[x,y]:=gif_paleta[color] else imagen1.Canvas.Pixels[x,y]:=gif_paleta[color2];inc(x);
    if (video_col and 32)<>0 then imagen1.Canvas.Pixels[x,y]:=gif_paleta[color] else imagen1.Canvas.Pixels[x,y]:=gif_paleta[color2];inc(x);
    if (video_col and 16)<>0 then imagen1.Canvas.Pixels[x,y]:=gif_paleta[color] else imagen1.Canvas.Pixels[x,y]:=gif_paleta[color2];inc(x);
    if (video_col and 8)<>0 then imagen1.Canvas.Pixels[x,y]:=gif_paleta[color] else imagen1.Canvas.Pixels[x,y]:=gif_paleta[color2];inc(x);
    if (video_col and 4)<>0 then imagen1.Canvas.Pixels[x,y]:=gif_paleta[color] else imagen1.Canvas.Pixels[x,y]:=gif_paleta[color2];inc(x);
    if (video_col and 2)<>0 then imagen1.Canvas.Pixels[x,y]:=gif_paleta[color] else imagen1.Canvas.Pixels[x,y]:=gif_paleta[color2];inc(x);
    if (video_col and 1)<>0 then imagen1.Canvas.Pixels[x,y]:=gif_paleta[color] else imagen1.Canvas.Pixels[x,y]:=gif_paleta[color2];inc(x);
    inc(pos_video);
  end;
end;
end;

procedure pio_int_main(state:byte);
begin
if mouse.x<>mouse.x_act then begin
  if mouse.x_act<mouse.x then begin
    mouse.data_a:=0;
    mouse.x_act:=mouse.x_act+1;
  end else begin
    mouse.data_a:=1;
    mouse.x_act:=mouse.x_act-1;
  end;
  z80_pio[0].m_port[PORT_A].m_ip:=true;
end;
if mouse.y<>mouse.y_act then begin
  if mouse.y_act<mouse.y then begin
    mouse.data_b:=1;
    mouse.y_act:=mouse.y_act+1;
  end else begin
    mouse.data_b:=0;
    mouse.y_act:=mouse.y_act-1;
  end;
  z80_pio[0].m_port[PORT_B].m_ip:=true;
end;
end;

function pio_read_porta:byte;
begin
  pio_read_porta:=mouse.data_a;
end;

function pio_read_portb:byte;
begin
  pio_read_portb:=mouse.data_b;
end;

end.
