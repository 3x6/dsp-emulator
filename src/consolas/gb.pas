unit gb;

interface
uses {$IFDEF WINDOWS}windows,{$ENDIF}file_engine,
     lr35902,main_engine,controls_engine,gfx_engine,timer_engine,dialogs,
     sysutils,gb_sound,rom_engine,misc_functions,pal_engine,gb_mappers,
     sound_engine;

type
  tgameboy=record
            read_io:function (direccion:byte):byte;
            write_io:procedure (direccion:byte;valor:byte);
            video_render:procedure;
            is_gbc:boolean;
  end;
  tgb_head=packed record
    title:array[0..10] of ansichar;
    manu:array[0..3] of ansichar;
    cgb_flag:byte;
    new_license:array[0..1] of byte;
    sbg_flag:byte;
    cart_type:byte;
    rom_size:byte;
    ram_size:byte;
    region:byte;
    license:byte;
    rom_ver:byte;
    head_sum:byte;
    total_sum:word;
  end;

procedure cargar_gb;

var
  ram_enable:boolean;
  gb_head:^tgb_head;

implementation
uses principal;

const
  color_pal:array[0..3] of tcolor=((r:$ff;g:$ff;b:$ff),(r:$aa;g:$aa;b:$aa),(r:$55;g:$55;b:$55),(r:0;g:0;b:0));
  gb_rom:tipo_roms=(n:'dmg_boot.bin';l:$100;p:0;crc:$59c8598e);
  gbc_rom:array[0..1] of tipo_roms=(
  (n:'gbc_boot.1';l:$100;p:0;crc:$779ea374),(n:'gbc_boot.2';l:$700;p:$200;crc:$f741807d));
  GB_CLOCK=4194304;

var
 scroll_x,scroll_y,stat,linea_cont_y,linea_actual,lcd_control,bg_pal,sprt0_pal,sprt1_pal:byte;
 tcontrol,tmodulo,mtimer,prog_timer,ly_compare,window_x,window_y:byte;
 wram_bank:array[0..7,0..$fff] of byte;
 vram_bank:array[0..1,0..$1fff] of byte;
 io_ram,sprt_ram,bg_prio:array[0..$ff] of byte;
 bios_rom:array[0..$8ff] of byte;
 bgc_pal,spc_pal:array[0..$3f] of word;
 enable_bios,rom_exist,bgcolor_inc,spcolor_inc,lcd_ena,hdma_ena:boolean;
 irq_ena,joystick,vram_nbank,wram_nbank,bgcolor_index,spcolor_index:byte;
 hdma_size,hdma_pos,dma_src,dma_dst:word;
 nombre_rom:string;
 hay_nvram,cartucho_cargado:boolean;
 gb_timer,sprites_time:byte;
 gameboy:tgameboy;

procedure sprite_order;
var
  f:byte;
begin
for f:=0 to $27 do begin

end;
end;

procedure draw_sprites(pri:byte);
var
  flipx,flipy:boolean;
  f,x,pal,atrib,pval:byte;
  size,num_char,def_y,tile_val1,tile_val2,long_x,main_x:byte;
  pos_linea:word;
  ptemp:pword;
  pos_y,pos_x:integer;
  n:byte;
begin
n:=0;
sprites_time:=0;
for f:=0 to $27 do begin
  atrib:=sprt_ram[$03+(f*4)];
  pos_y:=sprt_ram[$00+(f*4)];
  if (((atrib and $80)<>pri) or (pos_y=0) or (pos_y>=160)) then continue;
  pos_y:=pos_y-16;
  pos_linea:=linea_actual-pos_y;
  //Size
  size:=8 shl ((lcd_control and 4) shr 2);
  if (pos_linea<size) then begin
      pos_x:=sprt_ram[$01+(f*4)];
      if ((pos_x=0) or (pos_x>=168)) then continue;
      n:=n+1;
      if n=11 then exit;
      sprites_time:=sprites_time+12;
      pos_x:=pos_x-8;
      //Paleta
      pal:=((atrib and $10) shr 2)+4;
      //Num char
      num_char:=sprt_ram[$02+(f*4)];
      flipx:=(atrib and $20)<>0;
      flipy:=(atrib and $40)<>0;
      if size=8 then begin //8x8
        if flipy then def_y:=7-(pos_linea and 7)
          else def_y:=pos_linea and 7;
      end else begin //8x16
        if flipy then begin
          def_y:=7-(pos_linea and 7);
          num_char:=(num_char and $fe)+(not(pos_linea shr 3) and 1);
        end else begin
          def_y:=pos_linea and 7;
          num_char:=(num_char and $fe)+(pos_linea shr 3);
        end;
     end;
     ptemp:=punbuf;
     //Sprites 8x8 o 8x16
     tile_val1:=vram_bank[0,num_char*16+(def_y*2)];
     tile_val2:=vram_bank[0,num_char*16+1+(def_y*2)];
     if flipx then begin
        for x:=0 to 7 do begin
          pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
          if pval=0 then begin
            ptemp^:=paleta[max_colores]
          end else begin
            if ((bg_prio[pos_x+x] and $3f)>f) then begin
                ptemp^:=paleta[pval+pal];
                bg_prio[pos_x+x]:=(bg_prio[pos_x+x] and $c0) or f;
            end else begin
              ptemp^:=paleta[max_colores];
            end;
          end;
          inc(ptemp);
        end;
        putpixel(0,0,8,punbuf,PANT_SPRITES);
     end else begin
        for x:=7 downto 0 do begin
          pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
          if pval=0 then ptemp^:=paleta[max_colores]
            else begin
              if ((bg_prio[pos_x+(7-x)] and $3f)>f) then begin
                ptemp^:=paleta[pval+pal];
                bg_prio[pos_x+(7-x)]:=(bg_prio[pos_x+(7-x)] and $c0) or f;
              end else ptemp^:=paleta[max_colores];
            end;
          inc(ptemp);
        end;
        putpixel(0,0,8,punbuf,PANT_SPRITES);
     end;
     long_x:=8;
     main_x:=0;
     if pos_x<0 then begin
       long_x:=8+pos_x;
       main_x:=abs(pos_x);
       pos_x:=0;
     end;
     if (pos_x+8)>160 then long_x:=160-pos_x;
     actualiza_trozo(main_x,0,long_x,1,PANT_SPRITES,pos_x+7,pos_y+pos_linea,long_x,1,2);
  end;
end;
end;

procedure update_bg;
var
  tile_addr,bg_addr:word;
  f,x,tile_val1,tile_val2,y,pval,linea_pant:byte;
  n2:integer;
  tile_mid:boolean;
  ptemp:pword;
begin
  linea_pant:=linea_actual+scroll_y;
  bg_addr:=$1800+((lcd_control and $8) shl 7);
  tile_mid:=(lcd_control and $10)=0;
  tile_addr:=$1000*byte(tile_mid); //Cuidado! Tiene signo despues
  {if (lcd_control and $10)<>0 then begin
    tile_addr:=$0;
    tile_mid:=false;
  end else begin
    tile_addr:=$1000; //En realidad seria $800, pero tiene signo
    tile_mid:=true;
  end;}
  y:=(linea_pant and $7)*2;
  for f:=0 to 31 do begin
    if tile_mid then n2:=shortint(vram_bank[0,(bg_addr+f+((linea_pant div 8)*32)) and $1fff])
      else n2:=byte(vram_bank[0,(bg_addr+f+((linea_pant div 8)*32)) and $1fff]);
    tile_val1:=vram_bank[0,(n2*16+tile_addr+y) and $1fff];
    tile_val2:=vram_bank[0,(n2*16+tile_addr+1+y) and $1fff];
    ptemp:=punbuf;
    for x:=7 downto 0 do begin
      pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
      if pval<>0 then ptemp^:=paleta[pval]
        else ptemp^:=paleta[max_colores];
      inc(ptemp);
    end; //del for x
    putpixel(f*8,0,8,punbuf,1);
  end; //del for f
  //Scroll X
  if scroll_x<>0 then begin
    actualiza_trozo(0,0,scroll_x,1,1,(256-scroll_x)+7,linea_actual,scroll_x,1,2);
    actualiza_trozo(scroll_x,0,256-scroll_x,1,1,7,linea_actual,256-scroll_x,1,2);
  end else actualiza_trozo(0,0,256,1,1,7,linea_actual,256,1,2);
end;

procedure update_window;
var
  tile_addr,bg_addr:word;
  f,x,tile_val1,tile_val2,y,pval,linea_pant:byte;
  n2:integer;
  tile_mid:boolean;
  ptemp:pword;
begin
  if ((linea_actual<window_y) or (window_x>166)) then exit;
  linea_pant:=linea_actual-window_y;
  bg_addr:=$1800+((lcd_control and $40) shl 4);
  tile_mid:=(lcd_control and $10)=0;
  tile_addr:=$1000*byte(tile_mid); //Cuidado! Tiene signo despues
  y:=(linea_pant and $7)*2;
  for f:=0 to 31 do begin
    if tile_mid then n2:=shortint(vram_bank[0,(bg_addr+f+((linea_pant div 8)*32)) and $1fff])
      else n2:=vram_bank[0,(bg_addr+f+((linea_pant div 8)*32)) and $1fff];
    tile_val1:=vram_bank[0,(n2*16+tile_addr+y) and $1fff];
    tile_val2:=vram_bank[0,(n2*16+tile_addr+1+y) and $1fff];
    ptemp:=punbuf;
    for x:=7 downto 0 do begin
      pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
      ptemp^:=paleta[pval];
      inc(ptemp);
    end; //del for x
    putpixel(f*8,0,8,punbuf,1);
  end; //del for f
  actualiza_trozo(0,0,256,1,1,window_x,linea_actual,256,1,2);
end;

procedure update_video_gb;
begin
single_line(7,linea_actual,0,160,2);
if lcd_ena then begin
  fillchar(bg_prio[0],$100,$7f);
  if (lcd_control and 2)<>0 then draw_sprites($80);
  if (lcd_control and 1)<>0 then update_bg;
  if (lcd_control and $20)<>0 then update_window;
  if (lcd_control and 2)<>0 then draw_sprites(0);
end;
end;

//GBC
procedure draw_sprites_gbc(pri:byte);
var
  flipx,flipy:boolean;
  n,f,x,pal,atrib,pval,spr_bank:byte;
  size,num_char,def_y,tile_val1,tile_val2,long_x,main_x:byte;
  pos_linea:word;
  ptemp:pword;
  pos_y,pos_x:integer;
begin
n:=0;
sprites_time:=0;
for f:=0 to $27 do begin
  atrib:=sprt_ram[$03+(f*4)];
  pos_y:=sprt_ram[$00+(f*4)];
  if (((atrib and $80)<>pri) or (pos_y=0) or (pos_y>=160)) then continue;
  pos_y:=pos_y-16;
  pos_linea:=linea_actual-pos_y;
  //Size
  size:=8 shl ((lcd_control and 4) shr 2);
  if (pos_linea<size) then begin
      pos_x:=sprt_ram[$01+(f*4)];
      if ((pos_x=0) or (pos_x>=168)) then continue;
      n:=n+1;
      if n=11 then exit;
      sprites_time:=sprites_time+12;
      pos_x:=pos_x-8;
      //Paleta
      pal:=(atrib and $7)*4;
      //Num char
      spr_bank:=(atrib shr 3) and 1;
      num_char:=sprt_ram[$02+(f*4)];
      flipx:=(atrib and $20)<>0;
      flipy:=(atrib and $40)<>0;
      if size=8 then begin //8x8
        if flipy then def_y:=7-(pos_linea and 7)
          else def_y:=pos_linea and 7;
      end else begin //8x16
        if flipy then begin
          def_y:=7-(pos_linea and 7);
          num_char:=(num_char and $fe)+(not(pos_linea shr 3) and 1);
        end else begin
          def_y:=pos_linea and 7;
          num_char:=(num_char and $fe)+(pos_linea shr 3);
        end;
     end;
     ptemp:=punbuf;
     //Sprites 8x8 o 8x16
     tile_val1:=vram_bank[spr_bank,num_char*16+(def_y*2)];
     tile_val2:=vram_bank[spr_bank,num_char*16+1+(def_y*2)];
     if flipx then begin
        for x:=0 to 7 do begin
          pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
          //Sprite / BG priority
          if pval=0 then ptemp^:=paleta[max_colores]
            else begin
              if (bg_prio[pos_x+x] and $80)<>0 then ptemp^:=paleta[max_colores]
                else begin
                  if ((bg_prio[pos_x+x] and $3f)>f) then begin
                    ptemp^:=paleta[(spc_pal[pval+pal]) and $7fff];
                    bg_prio[pos_x+x]:=(bg_prio[pos_x+x] and $c0) or f;
                  end else ptemp^:=paleta[max_colores];
                end;
            end;
          inc(ptemp);
        end;
        putpixel(0,0,8,punbuf,PANT_SPRITES);
     end else begin
        for x:=7 downto 0 do begin
          pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
          if pval=0 then ptemp^:=paleta[max_colores]
            else begin
              if (bg_prio[pos_x+(7-x)] and $80)<>0 then ptemp^:=paleta[max_colores]
                else begin
                  if ((bg_prio[pos_x+(7-x)] and $3f)>f) then begin
                    ptemp^:=paleta[(spc_pal[pval+pal]) and $7fff];
                    bg_prio[pos_x+(7-x)]:=(bg_prio[pos_x+(7-x)] and $c0) or f;
                  end else ptemp^:=paleta[max_colores];
                end;
            end;
          inc(ptemp);
        end;
        putpixel(0,0,8,punbuf,PANT_SPRITES);
     end;
     long_x:=8;
     main_x:=0;
     if pos_x<0 then begin
       long_x:=8+pos_x;
       main_x:=abs(pos_x);
       pos_x:=0;
     end;
     if (pos_x+8)>160 then long_x:=160-pos_x;
     actualiza_trozo(main_x,0,long_x,1,PANT_SPRITES,pos_x+7,pos_y+pos_linea,long_x,1,2);
  end;
end;
end;

procedure update_bg_gbc;
var
  tile_addr,bg_addr:word;
  f,atrib,tile_bank,tile_pal:byte;
  x,tile_val1,tile_val2,y,pval,linea_pant:byte;
  n2:integer;
  tile_mid:boolean;
  ptemp:pword;
begin
  linea_pant:=linea_actual+scroll_y;
  bg_addr:=$1800+((lcd_control and $8) shl 7);
  tile_mid:=(lcd_control and $10)=0;
  tile_addr:=$1000*byte(tile_mid); //Cuidado! Tiene signo despues
  for f:=0 to 31 do begin
    if tile_mid then n2:=shortint(vram_bank[0,bg_addr+(f+((linea_pant div 8)*32) and $3ff)])
      else n2:=byte(vram_bank[0,bg_addr+(f+((linea_pant div 8)*32) and $3ff)]);
    atrib:=vram_bank[1,bg_addr+(f+((linea_pant div 8)*32) and $3ff)];
    if (atrib and $40)<>0 then y:=(7-(linea_pant and $7))*2
      else y:=(linea_pant and $7)*2;
    tile_bank:=(atrib shr 3) and 1;
    tile_pal:=(atrib and 7) shl 2;
    tile_val1:=vram_bank[tile_bank,(n2*16+tile_addr+y) and $1fff];
    tile_val2:=vram_bank[tile_bank,(n2*16+tile_addr+1+y) and $1fff];
    ptemp:=punbuf;
    if (atrib and $20)<>0 then begin
      for x:=0 to 7 do begin
        pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
        if (pval+tile_pal)<>0 then begin
          ptemp^:=paleta[(bgc_pal[pval+tile_pal]) and $7fff];
          if (((atrib and $80)<>0) and (pval<>0)) then bg_prio[(f*8+x-scroll_x) and $ff]:=bg_prio[(f*8+x-scroll_x) and $ff] or $80;
        end else ptemp^:=paleta[max_colores];
        inc(ptemp);
      end;
    end else begin
      for x:=7 downto 0 do begin
        pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
        if (pval+tile_pal)<>0 then begin
          ptemp^:=paleta[(bgc_pal[pval+tile_pal]) and $7fff];
          if (((atrib and $80)<>0) and (pval<>0)) then bg_prio[(f*8+x-scroll_x) and $ff]:=bg_prio[(f*8+x-scroll_x) and $ff] or $80;
        end else ptemp^:=paleta[max_colores];
        inc(ptemp);
      end;
    end;
    putpixel(f*8,0,8,punbuf,1);
  end;
  //Scroll X
  if scroll_x<>0 then begin
    actualiza_trozo(0,0,scroll_x,1,1,(256-scroll_x)+7,linea_actual,scroll_x,1,2);
    actualiza_trozo(scroll_x,0,256-scroll_x,1,1,7,linea_actual,256-scroll_x,1,2);
  end else actualiza_trozo(0,0,256,1,1,7,linea_actual,256,1,2);
end;

procedure update_window_gbc;
var
  tile_addr,bg_addr:word;
  f,atrib,tile_bank,tile_pal:byte;
  x,tile_val1,tile_val2,y,pval,linea_pant:byte;
  n2:integer;
  tile_mid:boolean;
  ptemp:pword;
begin
  if ((linea_actual<window_y) or (window_x>166)) then exit;
  linea_pant:=linea_actual-window_y;
  bg_addr:=$1800+((lcd_control and $40) shl 4);
  tile_mid:=(lcd_control and $10)=0;
  tile_addr:=$1000*byte(tile_mid); //Cuidado! Tiene signo despues
  for f:=0 to 31 do begin
    if tile_mid then n2:=shortint(vram_bank[0,(bg_addr+f+((linea_pant div 8)*32)) and $1fff])
      else n2:=byte(vram_bank[0,(bg_addr+f+((linea_pant div 8)*32)) and $1fff]);
    atrib:=vram_bank[1,(bg_addr+f+((linea_pant div 8)*32)) and $1fff];
    if (atrib and $40)<>0 then y:=(7-(linea_pant and $7))*2
      else y:=(linea_pant and $7)*2;
    tile_bank:=(atrib shr 3) and 1;
    tile_pal:=(atrib and 7) shl 2;
    tile_val1:=vram_bank[tile_bank,(n2*16+tile_addr+y) and $1fff];
    tile_val2:=vram_bank[tile_bank,(n2*16+tile_addr+1+y) and $1fff];
    ptemp:=punbuf;
    if (atrib and $20)<>0 then begin
      for x:=0 to 7 do begin
        pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
        ptemp^:=paleta[(bgc_pal[pval+tile_pal]) and $7fff];
        inc(ptemp);
      end;
    end else begin
      for x:=7 downto 0 do begin
        pval:=((tile_val1 shr x) and $1)+(((tile_val2 shr x) and $1) shl 1);
        ptemp^:=paleta[(bgc_pal[pval+tile_pal]) and $7fff];
        inc(ptemp);
      end;
    end;
    putpixel(f*8,0,8,punbuf,1);
  end;
  //Pos X
  actualiza_trozo(0,0,256,1,1,window_x,linea_actual,256,1,2);
end;

procedure update_video_gbc;
begin
single_line(7,linea_actual,(bgc_pal[0] and $7fff),160,2);
if lcd_ena then begin
  if (lcd_control and 1)=0 then begin //bg and window loses priority
    update_bg_gbc;
    if (lcd_control and $20)<>0 then update_window_gbc;
    fillchar(bg_prio[0],$100,$7f);
    if (lcd_control and 2)<>0 then draw_sprites_gbc($80);
    if (lcd_control and 2)<>0 then draw_sprites_gbc($0);
  end else begin
    fillchar(bg_prio[0],$100,$7f);
    if (lcd_control and 2)<>0 then draw_sprites_gbc($80);
    update_bg_gbc;
    if (lcd_control and 2)<>0 then draw_sprites_gbc($0);
    if (lcd_control and $20)<>0 then update_window_gbc;
  end;
end;
end;

procedure eventos_gb;
var
  tmp_in0:byte;
begin
if event.arcade then begin
  tmp_in0:=marcade.in0;
  if arcade_input.right[0] then marcade.in0:=(marcade.in0 and $fe) else marcade.in0:=(marcade.in0 or $1);
  if arcade_input.left[0] then marcade.in0:=(marcade.in0 and $fd) else marcade.in0:=(marcade.in0 or $2);
  if arcade_input.up[0] then marcade.in0:=(marcade.in0 and $fb) else marcade.in0:=(marcade.in0 or $4);
  if arcade_input.down[0] then marcade.in0:=(marcade.in0 and $f7) else marcade.in0:=(marcade.in0 or $8);
  if arcade_input.but0[0] then marcade.in0:=(marcade.in0 and $ef) else marcade.in0:=(marcade.in0 or $10);
  if arcade_input.but1[0] then marcade.in0:=(marcade.in0 and $df) else marcade.in0:=(marcade.in0 or $20);
  if arcade_input.coin[0] then marcade.in0:=(marcade.in0 and $bf) else marcade.in0:=(marcade.in0 or $40);
  if arcade_input.start[0] then marcade.in0:=(marcade.in0 and $7f) else marcade.in0:=(marcade.in0 or $80);
  if tmp_in0<>marcade.in0 then lr35902_0.joystick_req:=true;
end;
end;

procedure cerrar_gb;
begin
if hay_nvram then write_file(nombre_rom,@ram_bank[0,0],$2000);
gameboy_sound_close;
freemem(gb_head);
end;

function leer_io(direccion:byte):byte;
var
  tempb:byte;
begin
case direccion of
  $00:leer_io:=joystick;
  $01,$02:leer_io:=$7f; //Serial
  $04:leer_io:=mtimer;
  $05:leer_io:=prog_timer;
  $06:leer_io:=tmodulo;
  $07:leer_io:=$f8 or tcontrol;
  $0f:begin
        tempb:=$e0;
        if lr35902_0.vblank_req then tempb:=tempb or $1;
        if lr35902_0.lcdstat_req  then tempb:=tempb or $2;
        if lr35902_0.timer_req  then tempb:=tempb or $4;
        if lr35902_0.serial_req then tempb:=tempb or $8;
        if lr35902_0.joystick_req  then tempb:=tempb or $10;
        leer_io:=tempb;
      end;
  $10..$26:leer_io:=gb_sound_r(direccion-$10); //Sound
  $30..$3f:leer_io:=gb_wave_r(direccion-$30); //Sound Wav
  $40:leer_io:=lcd_control;
  $41:leer_io:=$80 or stat;
  $42:leer_io:=scroll_y;
  $43:leer_io:=scroll_x;
  $44:leer_io:=linea_cont_y;
  $45:leer_io:=ly_compare;
  $47:leer_io:=bg_pal;
  $48:leer_io:=sprt0_pal;
  $49:leer_io:=sprt1_pal;
  $4a:leer_io:=window_y;
  $4b:leer_io:=window_x;
  $80..$fe:leer_io:=io_ram[direccion];  //high memory
  $ff:leer_io:=irq_ena;
  else begin
    //MessageDlg('IO desconocida leer pos= '+inttohex(direccion and $ff,2), mtInformation,[mbOk], 0);
    //leer_io:=$ff;
    leer_io:=io_ram[direccion];
  end;
end;
end;

procedure escribe_io(direccion,valor:byte);
var
  f:byte;
  addrs:word;
begin
case direccion of
  $00:begin
         joystick:=$cf or valor;
         if (valor and $20)=0 then joystick:=joystick and ($f0 or (marcade.in0 shr 4));
         if (valor and $10)=0 then joystick:=joystick and ($f0 or marcade.in0);
      end;
  $01,$02:; //Serial
  $04:mtimer:=0;
  $05:prog_timer:=valor;
  $06:tmodulo:=valor;
  $07:begin  //timer control
        tcontrol:=valor and $7;
        case (valor and $3) of
          0:timer[gb_timer].time_final:=GB_CLOCK/4096;
          1:timer[gb_timer].time_final:=GB_CLOCK/262144;
          2:timer[gb_timer].time_final:=GB_CLOCK/65536;
          3:timer[gb_timer].time_final:=GB_CLOCK/16384;
        end;
        timer[gb_timer].actual_time:=0;
        timer[gb_timer].enabled:=(valor and $4)<>0;
      end;
  $0f:begin //irq request
        lr35902_0.vblank_req:=(valor and $1)<>0;
        lr35902_0.lcdstat_req:=(valor and $2)<>0;
        lr35902_0.timer_req:=(valor and $4)<>0;
        lr35902_0.serial_req:=(valor and $8)<>0;
        lr35902_0.joystick_req:=(valor and $10)<>0;
      end;
  $10..$26:gb_sound_w(direccion-$10,valor); //Sound
  $30..$3f:gb_wave_w(direccion and $f,valor); //Sound Wav
  $40:begin
        lcd_control:=valor;
        lcd_ena:=(valor and $80)<>0;
      end;
  $41:stat:=(stat and $7) or (valor and $f8);
  $42:scroll_y:=valor;
  $43:scroll_x:=valor;
  $44:linea_cont_y:=0;
  $45:ly_compare:=valor;
  $46:begin //DMA trans OAM
        addrs:=valor shl 8;
        for f:=0 to $9f do begin
          case addrs of
            $0000..$7fff:sprt_ram[f]:=memoria[addrs];
            $8000..$9fff:sprt_ram[f]:=vram_bank[0,addrs and $1fff];
            $a000..$bfff:sprt_ram[f]:=ram_bank[0,addrs and $1fff];
            $c000..$cfff,$e000..$efff:sprt_ram[f]:=wram_bank[0,addrs and $fff];
            $d000..$dfff,$f000..$fdff:sprt_ram[f]:=wram_bank[1,addrs and $fff];
            $fe00..$fe9f:sprt_ram[f]:=sprt_ram[addrs and $ff];
            $ff00..$ffff:sprt_ram[f]:=io_ram[addrs and $ff];
          end;
          addrs:=addrs+1;
        end;
        lr35902_0.contador:=lr35902_0.contador+160;
      end;
  $47:begin
        bg_pal:=valor;
        set_pal_color(color_pal[(valor shr 0) and $3],0);
        set_pal_color(color_pal[(valor shr 2) and $3],1);
        set_pal_color(color_pal[(valor shr 4) and $3],2);
        set_pal_color(color_pal[(valor shr 6) and $3],3);
      end;
  $48:begin //sprt0
        sprt0_pal:=valor;
        set_pal_color(color_pal[(valor shr 0) and $3],4);
        set_pal_color(color_pal[(valor shr 2) and $3],5);
        set_pal_color(color_pal[(valor shr 4) and $3],6);
        set_pal_color(color_pal[(valor shr 6) and $3],7);
      end;
  $49:begin
        sprt1_pal:=valor;
        set_pal_color(color_pal[(valor shr 0) and $3],8);
        set_pal_color(color_pal[(valor shr 2) and $3],9);
        set_pal_color(color_pal[(valor shr 4) and $3],10);
        set_pal_color(color_pal[(valor shr 6) and $3],11);
      end;
  $4a:window_y:=valor;
  $4b:window_x:=valor;
  $50:enable_bios:=(valor=0);  //enable/disable ROM
  $80..$fe:io_ram[direccion]:=valor;  //high memory
  $ff:begin  //irq enable
        irq_ena:=valor;
        lr35902_0.vblank_ena:=(valor and $1)<>0;
        lr35902_0.lcdstat_ena:=(valor and $2)<>0;
        lr35902_0.timer_ena:=(valor and $4)<>0;
        lr35902_0.serial_ena:=(valor and $8)<>0;
        lr35902_0.joystick_ena:=(valor and $10)<>0;
      end;
  else io_ram[direccion]:=valor;
  //MessageDlg('IO desconocida escribe pos= '+inttohex(direccion and $ff,2)+' - '+inttohex(valor,2), mtInformation,[mbOk], 0);
end;
end;

//Color GB
function leer_io_gbc(direccion:byte):byte;
var
  tempb:byte;
begin
case direccion of
  $00:leer_io_gbc:=joystick;
  $01,$02:leer_io_gbc:=$7f; //Serial
  $04:leer_io_gbc:=mtimer;
  $05:leer_io_gbc:=prog_timer;
  $06:leer_io_gbc:=tmodulo;
  $07:leer_io_gbc:=$f8 or tcontrol;
  $0f:begin
        tempb:=$e0;
        if lr35902_0.vblank_req then tempb:=tempb or $1;
        if lr35902_0.lcdstat_req  then tempb:=tempb or $2;
        if lr35902_0.timer_req  then tempb:=tempb or $4;
        if lr35902_0.serial_req then tempb:=tempb or $8;
        if lr35902_0.joystick_req then tempb:=tempb or $10;
        leer_io_gbc:=tempb;
      end;
  $10..$26:leer_io_gbc:=gb_sound_r(direccion-$10); //Sound
//  $27..$2f:leer_io_gbc:=io_ram[direccion];
  $30..$3f:leer_io_gbc:=gb_wave_r(direccion and $f); //Sound Wav
  $40:leer_io_gbc:=lcd_control;
  $41:leer_io_gbc:=$80 or stat;
  $42:leer_io_gbc:=scroll_y;
  $43:leer_io_gbc:=scroll_x;
  $44:leer_io_gbc:=linea_cont_y;
  $45:leer_io_gbc:=ly_compare;
  $47:leer_io_gbc:=bg_pal;
  $48:leer_io_gbc:=sprt0_pal;
  $49:leer_io_gbc:=sprt1_pal;
  $4a:leer_io_gbc:=window_y;
  $4b:leer_io_gbc:=window_x;
  $4d:leer_io_gbc:=(lr35902_0.speed shl 7)+$7e+byte(lr35902_0.change_speed);
  $4f:leer_io_gbc:=$fe or vram_nbank;
  $51..$54:leer_io_gbc:=$ff;
  $55:if hdma_ena then leer_io_gbc:=hdma_pos
        else leer_io_gbc:=$ff;
  $68:leer_io_gbc:=bgcolor_index;
  $69:if (bgcolor_index and 1)<>0 then leer_io_gbc:=bgc_pal[bgcolor_index shr 1] shr 8
        else leer_io_gbc:=bgc_pal[bgcolor_index shr 1] and $ff;
  $6a:leer_io_gbc:=spcolor_index;
  $6b:if (spcolor_index and 1)<>0 then leer_io_gbc:=spc_pal[spcolor_index shr 1] shr 8
        else leer_io_gbc:=spc_pal[spcolor_index shr 1] and $ff;
  $70:leer_io_gbc:=$f8 or wram_nbank;
  $80..$fe:leer_io_gbc:=io_ram[direccion];  //high memory
  $ff:leer_io_gbc:=irq_ena;
  else begin
    //MessageDlg('IO desconocida leer pos= '+inttohex(direccion and $ff,2), mtInformation,[mbOk], 0);
    leer_io_gbc:=io_ram[direccion];
  end;
end;
end;

procedure dma_trans(size:word);
var
  f,src_addr:word;
  temp:byte;
begin
src_addr:=dma_src;
for f:=0 to (size-1) do begin
  case src_addr of
    $0000..$7fff:temp:=memoria[src_addr];
    $8000..$9fff:temp:=vram_bank[vram_nbank,src_addr and $1fff];
    $a000..$bfff:if @gb_mapper.ext_ram_getbyte<>nil then temp:=gb_mapper.ext_ram_getbyte(src_addr and $1fff);
    $c000..$cfff,$e000..$efff:temp:=wram_bank[0,src_addr and $fff];
    $d000..$dfff,$f000..$fdff:temp:=wram_bank[wram_nbank,src_addr and $fff];
    $fe00..$fe9f:temp:=sprt_ram[src_addr and $ff];
    $ff00..$ffff:temp:=io_ram[src_addr and $ff];
  end;
  vram_bank[vram_nbank,(dma_dst+f) and $1fff]:=temp;
  src_addr:=src_addr+1;
end;
end;

procedure escribe_io_gbc(direccion,valor:byte);
var
  addrs:word;
  f:byte;
begin
io_ram[direccion]:=valor;
case direccion of
  $00:begin
          joystick:=$cf or valor;
          if (valor and $20)=0 then joystick:=joystick and ($d0 or (marcade.in0 shr 4));
          if (valor and $10)=0 then joystick:=joystick and ($e0 or marcade.in0);
      end;
  $01,$02:; //Serial
  $04:mtimer:=0;
  $05:prog_timer:=valor;
  $06:tmodulo:=valor;
  $07:begin  //timer control
        tcontrol:=valor and $7;
        case (valor and $3) of
          0:timer[gb_timer].time_final:=GB_CLOCK/4096;
          1:timer[gb_timer].time_final:=GB_CLOCK/262144;
          2:timer[gb_timer].time_final:=GB_CLOCK/65536;
          3:timer[gb_timer].time_final:=GB_CLOCK/16384;
        end;
        timer[gb_timer].actual_time:=0;
        timer[gb_timer].enabled:=(valor and $4)<>0;
      end;
  $0f:begin //irq request
        lr35902_0.vblank_req:=(valor and $1)<>0;
        lr35902_0.lcdstat_req:=(valor and $2)<>0;
        lr35902_0.timer_req:=(valor and $4)<>0;
        lr35902_0.serial_req:=(valor and $8)<>0;
        lr35902_0.joystick_req:=(valor and $10)<>0;
      end;
  $10..$26:gb_sound_w(direccion-$10,valor); //Sound
  //$27..$2f:io_ram[direccion]:=valor;
  $30..$3f:gb_wave_w(direccion and $f,valor); //Sound Wav
  $40:begin
        lcd_control:=valor;
        lcd_ena:=(valor and $80)<>0;
      end;
  $41:stat:=(stat and $7) or (valor and $f8);
  $42:scroll_y:=valor;
  $43:scroll_x:=valor;
  $44:linea_cont_y:=0;
  $45:ly_compare:=valor;
  $46:begin //DMA trans OAM
        addrs:=valor shl 8;
        for f:=0 to $9f do begin
          case addrs of
            $0000..$3fff:sprt_ram[f]:=rom_bank[0,addrs];
            $4000..$7fff:sprt_ram[f]:=rom_bank[rom_nbank,addrs and $3fff];
            $8000..$9fff:sprt_ram[f]:=vram_bank[vram_nbank,addrs and $1fff];
            $a000..$bfff:if @gb_mapper.ext_ram_getbyte<>nil then sprt_ram[f]:=gb_mapper.ext_ram_getbyte(direccion and $1fff);
            $c000..$cfff,$e000..$efff:sprt_ram[f]:=wram_bank[0,addrs and $fff];
            $d000..$dfff,$f000..$fdff:sprt_ram[f]:=wram_bank[wram_nbank,addrs and $fff];
            $fe00..$fe9f:sprt_ram[f]:=sprt_ram[addrs and $ff];
            $ff00..$ffff:sprt_ram[f]:=io_ram[addrs and $ff];
          end;
          addrs:=addrs+1;
        end;
        lr35902_0.contador:=lr35902_0.contador+160;
      end;
  $47:bg_pal:=valor;
  $48:sprt0_pal:=valor;
  $49:sprt1_pal:=valor;
  $4a:window_y:=valor;
  $4b:window_x:=valor;
//  $4c:io_ram[direccion]:=valor;  //????
  $4d:lr35902_0.change_speed:=(valor and 1)<>0;  //Cambiar velocidad
  $4f:vram_nbank:=valor and 1; //VRAM Bank
  $50:enable_bios:=(valor=0);  //enable/disable ROM
  $51:dma_src:=(dma_src and $ff) or (valor shl 8);
  $52:dma_src:=(dma_src and $ff00) or (valor and $f0);
  $53:dma_dst:=(dma_dst and $ff) or ((valor and $1f) shl 8);
  $54:dma_dst:=(dma_dst and $ff00) or (valor and $f0);
  $55:if (valor and $80)<>0 then begin
          hdma_size:=(valor and $7f)+1;
          hdma_ena:=true;
          hdma_pos:=0;
      end else begin
          dma_trans((valor+1)*$10);
          lr35902_0.contador:=lr35902_0.contador+(32 shl lr35902_0.speed);
      end;
  $56:;
  $68:begin
        bgcolor_inc:=(valor and $80)<>0;
        bgcolor_index:=valor and $3f;
      end;
  $69:begin
        if (bgcolor_index and 1)<>0 then bgc_pal[bgcolor_index shr 1]:=(bgc_pal[bgcolor_index shr 1] and $ff) or (valor shl 8)
          else bgc_pal[bgcolor_index shr 1]:=(bgc_pal[bgcolor_index shr 1] and $ff00) or valor;
        if bgcolor_inc then bgcolor_index:=(bgcolor_index+1) and $3f;
      end;
  $6a:begin
        spcolor_inc:=(valor and $80)<>0;
        spcolor_index:=valor and $3f;
      end;
  $6b:begin
        if (spcolor_index and 1)<>0 then spc_pal[spcolor_index shr 1]:=(spc_pal[spcolor_index shr 1] and $ff) or (valor shl 8)
          else spc_pal[spcolor_index shr 1]:=(spc_pal[spcolor_index shr 1] and $ff00) or valor;
        if spcolor_inc then spcolor_index:=(spcolor_index+1) and $3f;
      end;
  $70:begin
        wram_nbank:=valor and 7;
        if wram_nbank=0 then wram_nbank:=1;
       end;
  $7e,$7f:;
//  $80..$fe:io_ram[direccion]:=valor;  //high memory
  $ff:begin  //irq enable
        irq_ena:=valor;
        lr35902_0.vblank_ena:=(valor and $1)<>0;
        lr35902_0.lcdstat_ena:=(valor and $2)<>0;
        lr35902_0.timer_ena:=(valor and $4)<>0;
        lr35902_0.serial_ena:=(valor and $8)<>0;
        lr35902_0.joystick_ena:=(valor and $10)<>0;
      end;
//  else io_ram[direccion]:=valor;//MessageDlg('IO desconocida escribe pos= '+inttohex(direccion and $ff,2)+' - '+inttohex(valor,2), mtInformation,[mbOk], 0);
end;
end;

procedure gb_principal;
var
  frame_m:single;
begin
if not(cartucho_cargado) then exit;
init_controls(false,false,false,true);
frame_m:=lr35902_0.tframes;
while EmuStatus=EsRuning do begin
  linea_cont_y:=0;
  for linea_actual:=0 to 153 do begin
    lr35902_0.run(frame_m);
    frame_m:=frame_m+lr35902_0.tframes-lr35902_0.contador;
    if linea_actual<144 then gameboy.video_render;  //Modos 2-3-0
    linea_cont_y:=linea_cont_y+1;
  end;
  eventos_gb;
  actualiza_trozo(7,0,160,144,2,0,0,160,144,pant_temp);
  video_sync;
end;
end;

function gb_getbyte(direccion:word):byte;
begin
case direccion of
  //ROM bank 0
  $0..$ff,$200..$8ff:if enable_bios then gb_getbyte:=bios_rom[direccion]
                        else gb_getbyte:=memoria[direccion];
  $0100..$1ff,$900..$3fff:gb_getbyte:=memoria[direccion];
  //ROM bank 1
  $4000..$7fff:gb_getbyte:=memoria[direccion];
  //video ram
  $8000..$9fff:gb_getbyte:=vram_bank[vram_nbank,direccion and $1fff];
  //external (cartridge) RAM
  $a000..$bfff:if @gb_mapper.ext_ram_getbyte<>nil then gb_getbyte:=gb_mapper.ext_ram_getbyte(direccion);
  //RAM bank 0
  $c000..$cfff,$e000..$efff:gb_getbyte:=wram_bank[0,direccion and $fff];
  //RAM bank 1
  $d000..$dfff,$f000..$fdff:gb_getbyte:=wram_bank[wram_nbank,direccion and $fff];
  //Sprites OAM
  $fe00..$fe9f:gb_getbyte:=sprt_ram[direccion and $ff];
  $fea0..$feff:if not(gameboy.is_gbc) then gb_getbyte:=0
                  else begin
                        case (direccion and $ff) of
                         $a0..$cf:gb_getbyte:=memoria[direccion];
                         $d0..$ff:gb_getbyte:=memoria[$fec0+(direccion and $f)];
                        end;
                  end;
  //IO Ram
  $ff00..$ffff:gb_getbyte:=gameboy.read_io(direccion and $ff);
end;
end;

procedure gb_putbyte(direccion:word;valor:byte);
begin
case direccion of
  $0000..$7fff:if @gb_mapper.rom_putbyte<>nil then gb_mapper.rom_putbyte(direccion,valor);
  //video ram
  $8000..$9fff:vram_bank[vram_nbank,direccion and $1fff]:=valor;
  //external (cartridge) RAM
  $a000..$bfff:if @gb_mapper.ext_ram_putbyte<>nil then gb_mapper.ext_ram_putbyte(direccion,valor);
  //RAM bank 0
  $c000..$cfff,$e000..$efff:wram_bank[0,direccion and $fff]:=valor;
  //RAM bank 1
  $d000..$dfff,$f000..$fdff:wram_bank[wram_nbank,direccion and $fff]:=valor;
  //Sprites OAM
  $fe00..$fe9f:sprt_ram[direccion and $ff]:=valor;
  $fea0..$feff:if gameboy.is_gbc then begin
                  case (direccion and $ff) of
                    $a0..$cf:memoria[direccion]:=valor;
                    $d0..$ff:memoria[$fec0+(direccion and $f)]:=valor;
                  end;
               end;
  //IO Ram
  $ff00..$ffff:gameboy.write_io(direccion and $ff,valor);
end;
end;

procedure gb_despues_instruccion(estados_t:word);
var
  lcd_compare,lcd_mode:boolean;
begin
lcd_compare:=false;
lcd_mode:=false;
case lr35902_0.contador of
  4:begin
      //LY compare
      case linea_actual of
        0:; //Noy hay comparacion!!!
        1..153:if linea_actual=ly_compare then begin
              lcd_compare:=(stat and $40)<>0;
              stat:=stat or $4;
           end else stat:=stat and $fb;
      end;
      case linea_actual of
        0..143:begin
                 lcd_mode:=((stat and $20)<>0) and ((stat and 3)<>2);
                 stat:=(stat and $fc) or $2;
               end;
        144:begin
              //IRQ
              if lcd_ena then lr35902_0.vblank_req:=true;
              //Status 1
              lcd_mode:=((stat and $30)<>0) and ((stat and 3)<>1);
              stat:=(stat and $fc) or $1;
            end;
      end;
  end;
  12:if (linea_actual=153) then begin
        if ly_compare=0 then begin
          lcd_compare:=(stat and $40)<>0;
          stat:=stat or $4;
        end else stat:=stat and $fb;
  end;
  80:if linea_actual<144 then stat:=(stat and $fc) or $3;
  252..600:if ((linea_actual<144) and ((sprites_time+252)=lr35902_0.contador)) then begin
                lcd_mode:=((stat and $8)<>0) and ((stat and 3)<>0);
                stat:=stat and $fc;
           end;
end;
lr35902_0.lcdstat_req:=lr35902_0.lcdstat_req or lcd_compare or lcd_mode;
end;

procedure gbc_despues_instruccion(estados_t:word);
var
  lcd_compare,lcd_mode:boolean;
begin
lcd_compare:=false;
lcd_mode:=false;
if lr35902_0.changed_speed then begin
  lr35902_0.tframes:=((GB_CLOCK shl lr35902_0.speed)/154)/llamadas_maquina.fps_max;
  sound_engine_change_clock(GB_CLOCK shl lr35902_0.speed);
  lr35902_0.changed_speed:=false;
end;
if lr35902_0.speed<>0 then begin //Double speed
  case lr35902_0.contador of
    4:begin
      //LY compare
      case linea_actual of
        0:; //Noy hay comparacion!!!
        1..153:if linea_actual=ly_compare then begin
              lcd_compare:=(stat and $40)<>0;
              stat:=stat or $4;
           end else stat:=stat and $fb;
      end;
      case linea_actual of
        0..143:begin
                 lcd_mode:=((stat and $20)<>0) and ((stat and 3)<>2);
                 stat:=(stat and $fc) or $2;
               end;
        144:begin
              //IRQ
              if lcd_ena then lr35902_0.vblank_req:=true;
              //Status 1
              lcd_mode:=((stat and $30)<>0) and ((stat and 3)<>1);
              stat:=(stat and $fc) or $1;
            end;
      end;
  end;
  16:if (linea_actual=153) then begin
        if ly_compare=0 then begin
          lcd_compare:=(stat and $40)<>0;
          stat:=stat or $4;
        end else stat:=stat and $fb;
  end;
  160:if linea_actual<144 then stat:=(stat and $fc) or $3;
  496..1200:if (linea_actual<144) then begin
              if ((sprites_time+496)=lr35902_0.contador) then begin
                lcd_mode:=((stat and $8)<>0) and ((stat and 3)<>0);
                stat:=stat and $fc;
              end;
              if (lr35902_0.contador=616) then begin
                if hdma_ena then begin
                  dma_trans($10);
                  dma_src:=dma_src+$10;
                  dma_dst:=dma_dst+$10;
                  hdma_pos:=hdma_pos+1;
                  if hdma_pos=hdma_size then hdma_ena:=false;
                  lr35902_0.contador:=lr35902_0.contador+16;
              end;
              end;
            end;
  end;
end else begin
  case lr35902_0.contador of
    0:begin
      //LY compare
      case linea_actual of
        0:; //Noy hay comparacion!!!
        1..153:if linea_actual=ly_compare then begin
              lcd_compare:=(stat and $40)<>0;
              stat:=stat or $4;
           end else stat:=stat and $fb;
      end;
      case linea_actual of
        0..143:begin
                 lcd_mode:=((stat and $20)<>0) and ((stat and 3)<>2);
                 stat:=(stat and $fc) or $2;
               end;
        144:begin
              //IRQ
              if lcd_ena then lr35902_0.vblank_req:=true;
              //Status 1
              lcd_mode:=((stat and $30)<>0) and ((stat and 3)<>1);
              stat:=(stat and $fc) or $1;
            end;
      end;
  end;
  8:if (linea_actual=153) then begin
        if ly_compare=0 then begin
          lcd_compare:=(stat and $40)<>0;
          stat:=stat or $4;
        end else stat:=stat and $fb;
  end;
  80:if linea_actual<144 then stat:=(stat and $fc) or $3;
  248..600:if (linea_actual<144) then begin
              if ((sprites_time+248)=lr35902_0.contador) then begin   //H-Blank
                lcd_mode:=((stat and $8)<>0) and ((stat and 3)<>0);
                stat:=stat and $fc;
              end;
              if (lr35902_0.contador=368) then begin
                if hdma_ena then begin
                  dma_trans($10);
                  dma_src:=dma_src+$10;
                  dma_dst:=dma_dst+$10;
                  hdma_pos:=hdma_pos+1;
                  if hdma_pos=hdma_size then hdma_ena:=false;
                  lr35902_0.contador:=lr35902_0.contador+8;
                end;
              end;
           end;
  end;
end;
lr35902_0.lcdstat_req:=lr35902_0.lcdstat_req or lcd_compare or lcd_mode;
end;

//Sonido and timers
procedure gb_main_timer;
begin
  mtimer:=mtimer+1;
end;

//Main
procedure reset_gb;
var
  lr_reg:reg_lr;
begin
 lr35902_0.tframes:=(GB_CLOCK/154)/llamadas_maquina.fps_max;
 sound_engine_change_clock(GB_CLOCK);
 lr35902_0.reset;
 reset_audio;
 gameboy_sound_reset;
 scroll_x:=0;
 scroll_y:=0;
 stat:=0;
 tmodulo:=0;
 mtimer:=0;
 prog_timer:=0;
 rom_mode:=false;
 ram_enable:=false;
 map_enable:=false;
 rom_nbank:=0;
 ram_nbank:=0;
 vram_nbank:=0;
 wram_nbank:=1;
 linea_cont_y:=0;
 ly_compare:=$ff;
 irq_ena:=0;
 marcade.in0:=$ff;
 joystick:=$ff;
 hdma_ena:=false;
 lcd_control:=$80;
 lcd_ena:=true;
 if not(rom_exist) then begin
   enable_bios:=false;
   lr_reg.pc:=$100;
   lr_reg.sp:=$fffe;
   lr_reg.f.z:=true;
   lr_reg.f.n:=false;
   if (gb_head.cgb_flag and $80)<>0 then begin
     lr_reg.a:=$11;
     lr_reg.f.h:=false;
     lr_reg.f.c:=false;
     lr_reg.BC.w:=$0;
     lr_reg.DE.w:=$ff56;
     lr_reg.HL.w:=$000d;
   end else begin
     lr_reg.a:=$01;
     lr_reg.f.h:=true;
     lr_reg.f.c:=true;
     lr_reg.BC.w:=$0013;
     lr_reg.DE.w:=$00D8;
     lr_reg.HL.w:=$014D;
     escribe_io(05,00);
     escribe_io(06,00);
     escribe_io(07,00);
     escribe_io($10,$80);
     escribe_io($11,$bf);
     escribe_io($12,$f3);
     escribe_io($14,$bf);
     escribe_io($16,$3f);
     escribe_io($17,$00);
     escribe_io($19,$bf);
     escribe_io($1a,$7f);
     escribe_io($1b,$f);
     escribe_io($1c,$9f);
     escribe_io($1e,$bf);
     escribe_io($20,$ff);
     escribe_io($21,$00);
     escribe_io($22,$00);
     escribe_io($23,$bf);
     escribe_io($24,$77);
     escribe_io($25,$f3);
     escribe_io($26,$f1);
     escribe_io($40,$91);
     escribe_io($42,$00);
     escribe_io($43,$00);
     escribe_io($45,$00);
     escribe_io($47,$fc);
     escribe_io($48,$ff);
     escribe_io($49,$ff);
     escribe_io($4a,$00);
     escribe_io($4b,$00);
     escribe_io($00,$00);
   end;
   lr35902_0.set_internal_r(@lr_reg);
  end else enable_bios:=true;
end;

procedure gb_prog_timer;
begin
  prog_timer:=prog_timer+1;
  if prog_timer=0 then begin
    prog_timer:=tmodulo;
    lr35902_0.timer_req:=true; //timer request irq
  end;
end;

type
  tgb_logo=packed record
    none1:array[0..$103] of byte;
    logo:array[0..$2f] of byte;
  end;

function abrir_gb:boolean;
const
  main_logo:array[0..$2f] of byte=(
  $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D,
  $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99,
  $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E);
var
  mal:boolean;
  extension,nombre_file,RomFile,dir:string;
  datos,ptemp:pbyte;
  longitud,crc:integer;
  f,h:word;
  colores:tpaleta;
  gb_logo:^tgb_logo;
begin
  if not(OpenRom(StGb,RomFile)) then begin
    abrir_gb:=true;
    exit;
  end;
  getmem(gb_logo,sizeof(tgb_logo));
  abrir_gb:=false;
  gameboy.read_io:=leer_io;
  gameboy.write_io:=escribe_io;
  gameboy.video_render:=update_video_gb;
  gameboy.is_gbc:=false;
  lr35902_0.change_despues_instruccion(gb_despues_instruccion);
  extension:=extension_fichero(RomFile);
  if extension='ZIP' then begin
    if not(search_file_from_zip(RomFile,'*.gb',nombre_file,longitud,crc,false)) then
      if not(search_file_from_zip(RomFile,'*.gbc',nombre_file,longitud,crc,false)) then exit;
    getmem(datos,longitud);
    if not(load_file_from_zip(RomFile,nombre_file,datos,longitud,crc,true)) then begin
      freemem(datos);
      freemem(gb_logo);
      exit;
    end;
  end else begin
    if ((extension<>'GB') and (extension<>'GBC')) then exit;
    if not(read_file_size(RomFile,longitud)) then exit;
    getmem(datos,longitud);
    if not(read_file(RomFile,datos,longitud)) then begin
      freemem(datos);
      freemem(gb_logo);
      exit;
    end;
    nombre_file:=extractfilename(RomFile);
  end;
  ptemp:=datos;
  //Comprobar si hay una cabecera extra delante, detras me da igual...
  copymemory(gb_logo,ptemp,sizeof(tgb_logo));
  if (longitud mod $2000)<>0 then begin
    mal:=true;
    //Esta delante? --> No estara el logo de Nintendo
    for f:=0 to $2f do begin
       mal:=(main_logo[f]=gb_logo.logo[f]);
       if not(mal) then break;
    end;
    if not(mal) then inc(ptemp,longitud mod $2000);
  end;
  inc(ptemp,sizeof(tgb_logo));
  copymemory(gb_head,ptemp,sizeof(tgb_head));
  dec(ptemp,sizeof(tgb_logo));
  //Is GBC?
  if (gb_head.cgb_flag and $80)<>0 then begin
    gameboy.read_io:=leer_io_gbc;
    gameboy.write_io:=escribe_io_gbc;
    gameboy.video_render:=update_video_gbc;
    gameboy.is_gbc:=true;
    lr35902_0.change_despues_instruccion(gbc_despues_instruccion);
  end;
  if hay_nvram then write_file(nombre_rom,@ram_bank[0,0],$2000);
  nombre_rom:=Directory.Arcade_nvram+ChangeFileExt(nombre_file,'.nv');
  hay_nvram:=false;
  gb_head.rom_size:=(32 shl gb_head.rom_size) div 16;
  if gb_head.rom_size=0 then gb_head.rom_size:=1;
  gb_mapper.ext_ram_getbyte:=nil;
  gb_mapper.ext_ram_putbyte:=nil;
  gb_mapper.rom_putbyte:=nil;
  for f:=0 to (gb_head.rom_size-1) do begin
    copymemory(@rom_bank[f,0],ptemp,$4000);
    inc(ptemp,$4000);
  end;
  //El banco 0+1 siempre es el mismo
  copymemory(@memoria[$0],@rom_bank[0,0],$4000);
  copymemory(@memoria[$4000],@rom_bank[1,0],$4000);
  mal:=true;
  case gb_head.cart_type of
    0:mal:=false; //No mapper
    $01..$03:begin  //mbc1
          gb_mapper.rom_putbyte:=gb_putbyte_mbc1;
          case gb_head.cart_type of
            1:;
            2:begin //RAM
                gb_mapper.ext_ram_getbyte:=gb_get_ext_ram_mbc1;
                gb_mapper.ext_ram_putbyte:=gb_put_ext_ram_mbc1;
              end;
            3:begin //RAM + Battery
                gb_mapper.ext_ram_getbyte:=gb_get_ext_ram_mbc1;
                gb_mapper.ext_ram_putbyte:=gb_put_ext_ram_mbc1;
                if gb_head.ram_size<>0 then begin
                    if read_file_size(nombre_rom,longitud) then read_file(nombre_rom,@ram_bank[0,0],longitud);
                    hay_nvram:=true;
                end;
            end;
          end;
        mal:=false;
      end;
      $05,$06:begin //mbc2
        gb_mapper.rom_putbyte:=gb_putbyte_mbc2;
        case gb_head.cart_type of
          5:;
          6:begin //RAM + Battery
              gb_mapper.ext_ram_getbyte:=gb_get_ext_ram_mbc2;
              gb_mapper.ext_ram_putbyte:=gb_put_ext_ram_mbc2;
              if gb_head.ram_size<>0 then begin
                  if read_file_size(nombre_rom,longitud) then read_file(nombre_rom,@ram_bank[0,0],longitud);
                  hay_nvram:=true;
              end;
          end;
        end;
        mal:=false;
      end;
      $0d:begin
            gb_mapper.rom_putbyte:=gb_putbyte_mmm01;
            gb_mapper.ext_ram_getbyte:=gb_get_ext_ram_mmm01;
            gb_mapper.ext_ram_putbyte:=gb_put_ext_ram_mmm01;
            mal:=false;
          end;
      $19..$1e:begin //mbc5
          gb_mapper.rom_putbyte:=gb_putbyte_mbc5;
          case gb_head.cart_type of
            $19,$1c:;
            $1a,$1d:begin //RAM
                      gb_mapper.ext_ram_getbyte:=gb_get_ext_ram_mbc5;
                      gb_mapper.ext_ram_putbyte:=gb_put_ext_ram_mbc5;
                    end;
            $1b,$1e:begin //RAM + Battery
                      gb_mapper.ext_ram_getbyte:=gb_get_ext_ram_mbc5;
                      gb_mapper.ext_ram_putbyte:=gb_put_ext_ram_mbc5;
                      if gb_head.ram_size<>0 then begin
                          if read_file_size(nombre_rom,longitud) then read_file(nombre_rom,@ram_bank[0,0],longitud);
                          hay_nvram:=true;
                      end;
                    end;
          end;
          mal:=false;
         end;
      $ff:begin //HuC-1
            gb_mapper.rom_putbyte:=gb_putbyte_huc1;
            gb_mapper.ext_ram_getbyte:=gb_get_ext_ram_huc1;
            gb_mapper.ext_ram_putbyte:=gb_put_ext_ram_huc1;
            if gb_head.ram_size<>0 then begin
              if read_file_size(nombre_rom,longitud) then read_file(nombre_rom,@ram_bank[0,0],longitud);
              hay_nvram:=true;
            end;
            mal:=false;
          end;
      else MessageDlg('Mapper '+inttohex(gb_head.cart_type,2)+' no implementado', mtInformation,[mbOk], 0);
  end;
  if not(mal) then begin
    if (gb_head.cgb_flag and $80)<>0 then begin //GameBoy Color
      dir:=directory.arcade_list_roms[find_rom_multiple_dirs('gbcolor.zip')];
      llamadas_maquina.open_file:=gb_head.title;
      rom_exist:=false;
      if carga_rom_zip(dir+'gbcolor.zip',gbc_rom[0].n,@bios_rom[0],gbc_rom[0].l,gbc_rom[0].crc,false) then
        if rom_exist or carga_rom_zip(dir+'gbcolor.zip',gbc_rom[1].n,@bios_rom[gbc_rom[1].p],gbc_rom[1].l,gbc_rom[1].crc,false) then rom_exist:=true;
      //Iniciar Paletas
      for h:=0 to $7fff do begin
        colores[h].r:=(h and $1F) shl 3;
    	  colores[h].g:=((h shr 5) and $1F) shl 3;
    	  colores[h].b:=((h shr 10) and $1F) shl 3;
      end;
      set_pal(colores,$8000);
      for f:=0 to $1f do bgc_pal[f]:=$7fff;
      for f:=0 to $1f do spc_pal[f]:=0;
    end else begin
      dir:=directory.arcade_list_roms[find_rom_multiple_dirs('gameboy.zip')];
      rom_exist:=carga_rom_zip(dir+'gameboy.zip',gb_rom.n,@bios_rom[0],gb_rom.l,gb_rom.crc,false);
      llamadas_maquina.open_file:=gb_head.title+gb_head.manu+ansichar(gb_head.cgb_flag);
    end;
    abrir_gb:=true;
  end else llamadas_maquina.open_file:='';
  change_caption;
  cartucho_cargado:=true;
  freemem(datos);
  freemem(gb_logo);
  reset_gb;
  directory.GameBoy:=ExtractFilePath(romfile);
end;

function iniciar_gb:boolean;
begin
iniciar_audio(true);
//Pantallas:  principal+char y sprites
screen_init(1,256,1,true);
screen_init(2,256+166+7,154);  //256 pantalla normal + 166 window + 7 de desplazamiento
iniciar_video(160,144);
//Main CPU
lr35902_0:=cpu_lr.Create(GB_CLOCK,154); //154 lineas, 456 estados t por linea
lr35902_0.change_ram_calls(gb_getbyte,gb_putbyte);
lr35902_0.init_sound(gameboy_sound_update);
//Timers internos de la GB
init_timer(0,GB_CLOCK/16384,gb_main_timer,true);
gb_timer:=init_timer(0,GB_CLOCK/4096,gb_prog_timer,false);
//Sound Chips
gameboy_sound_ini(FREQ_BASE_AUDIO);
//cargar roms
hay_nvram:=false;
//final
getmem(gb_head,sizeof(tgb_head));
iniciar_gb:=abrir_gb;
end;

procedure Cargar_gb;
begin
principal1.BitBtn10.Glyph:=nil;
principal1.imagelist2.GetBitmap(2,principal1.BitBtn10.Glyph);
principal1.BitBtn10.OnClick:=principal1.fLoadCartucho;
llamadas_maquina.iniciar:=iniciar_gb;
llamadas_maquina.bucle_general:=gb_principal;
llamadas_maquina.close:=cerrar_gb;
llamadas_maquina.reset:=reset_gb;
llamadas_maquina.fps_max:=59.727500569605832763727500569606;
llamadas_maquina.cartuchos:=abrir_gb;
cartucho_cargado:=false;
end;

end.

