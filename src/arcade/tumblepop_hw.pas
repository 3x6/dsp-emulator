unit tumblepop_hw;

interface
uses {$IFDEF WINDOWS}windows,{$ENDIF}
     m68000,main_engine,controls_engine,gfx_engine,rom_engine,pal_engine,
     oki6295,sound_engine,hu6280,deco_16ic,deco_decr,deco_common;

procedure cargar_tumblep;

implementation
const
        tumblep_rom:array[0..2] of tipo_roms=(
        (n:'hl00-1.f12';l:$40000;p:0;crc:$fd697c1b),(n:'hl01-1.f13';l:$40000;p:$1;crc:$d5a62a3f),());
        tumblep_sound:tipo_roms=(n:'hl02-.f16';l:$10000;p:$0;crc:$a5cab888);
        tumblep_char:tipo_roms=(n:'map-02.rom';l:$80000;p:0;crc:$dfceaa26);
        tumblep_oki:tipo_roms=(n:'hl03-.j15';l:$20000;p:0;crc:$01b81da0);
        tumblep_sprites:array[0..2] of tipo_roms=(
        (n:'map-01.rom';l:$80000;p:0;crc:$e81ffa09),(n:'map-00.rom';l:$80000;p:$1;crc:$8c879cfe),());

var
 rom:array[0..$3ffff] of word;
 ram:array[0..$1fff] of word;

procedure update_video_tumblep;inline;
begin
deco16ic_0.update_pf_2(3,false);
deco16ic_0.update_pf_1(3,true);
deco_sprites_0.draw_sprites;
actualiza_trozo_final(0,8,319,240,3);
end;

procedure eventos_tumblep;
begin
if event.arcade then begin
  //P1
  if arcade_input.up[0] then marcade.in0:=(marcade.in0 and $fe) else marcade.in0:=(marcade.in0 or $1);
  if arcade_input.down[0] then marcade.in0:=(marcade.in0 and $Fd) else marcade.in0:=(marcade.in0 or $2);
  if arcade_input.left[0] then marcade.in0:=(marcade.in0 and $fb) else marcade.in0:=(marcade.in0 or $4);
  if arcade_input.right[0] then marcade.in0:=(marcade.in0 and $F7) else marcade.in0:=(marcade.in0 or $8);
  if arcade_input.but0[0] then marcade.in0:=(marcade.in0 and $ef) else marcade.in0:=(marcade.in0 or $10);
  if arcade_input.but1[0] then marcade.in0:=(marcade.in0 and $df) else marcade.in0:=(marcade.in0 or $20);
  if arcade_input.start[0] then marcade.in0:=(marcade.in0 and $7f) else marcade.in0:=(marcade.in0 or $80);
  //P2
  if arcade_input.up[1] then marcade.in0:=(marcade.in0 and $feff) else marcade.in0:=(marcade.in0 or $100);
  if arcade_input.down[1] then marcade.in0:=(marcade.in0 and $Fdff) else marcade.in0:=(marcade.in0 or $200);
  if arcade_input.left[1] then marcade.in0:=(marcade.in0 and $fbff) else marcade.in0:=(marcade.in0 or $400);
  if arcade_input.right[1] then marcade.in0:=(marcade.in0 and $F7ff) else marcade.in0:=(marcade.in0 or $800);
  if arcade_input.but0[1] then marcade.in0:=(marcade.in0 and $efff) else marcade.in0:=(marcade.in0 or $1000);
  if arcade_input.but1[1] then marcade.in0:=(marcade.in0 and $dfff) else marcade.in0:=(marcade.in0 or $2000);
  if arcade_input.start[1] then marcade.in0:=(marcade.in0 and $7fff) else marcade.in0:=(marcade.in0 or $8000);
  //SYSTEM
  if arcade_input.coin[0] then marcade.in1:=(marcade.in1 and $fe) else marcade.in1:=(marcade.in1 or $1);
  if arcade_input.coin[1] then marcade.in1:=(marcade.in1 and $fd) else marcade.in1:=(marcade.in1 or $2);
end;
end;

procedure tumblep_principal;
var
  frame_m,frame_s:single;
  f:byte;
begin
init_controls(false,false,false,true);
frame_m:=m68000_0.tframes;
frame_s:=h6280_0.tframes;
while EmuStatus=EsRuning do begin
 for f:=0 to $ff do begin
   m68000_0.run(frame_m);
   frame_m:=frame_m+m68000_0.tframes-m68000_0.contador;
   h6280_0.run(frame_s);
   frame_s:=frame_s+h6280_0.tframes-h6280_0.contador;
   case f of
      247:begin
            m68000_0.irq[6]:=HOLD_LINE;
            update_video_tumblep;
            marcade.in1:=marcade.in1 or $8;
          end;
      255:marcade.in1:=marcade.in1 and $f7;
   end;
 end;
 eventos_tumblep;
 video_sync;
end;
end;

function tumblep_getword(direccion:dword):word;
begin
case direccion of
  $0..$7ffff:tumblep_getword:=rom[direccion shr 1];
  $120000..$123fff:tumblep_getword:=ram[(direccion and $3fff) shr 1];
  $180000..$18000f:case (direccion and $f) of
                    $0:tumblep_getword:=marcade.in0;
                    $2:tumblep_getword:=$feff; //dsw
                    $8:tumblep_getword:=marcade.in1;
                    $a,$c:tumblep_getword:=0;
                      else tumblep_getword:=$ffff;
                   end;
  $1a0000..$1a07ff:tumblep_getword:=deco_sprites_0.ram[(direccion and $7ff) shr 1];
  $320000..$320fff:tumblep_getword:=deco16ic_0.pf1.data[(direccion and $fff) shr 1];
  $322000..$322fff:tumblep_getword:=deco16ic_0.pf2.data[(direccion and $fff) shr 1];
end;
end;

procedure cambiar_color(tmp_color,numero:word);inline;
var
  color:tcolor;
begin
  color.b:=pal4bit(tmp_color shr 8);
  color.g:=pal4bit(tmp_color shr 4);
  color.r:=pal4bit(tmp_color);
  set_pal_color(color,numero);
  case numero of
    $100..$1ff:deco16ic_0.pf1.buffer_color[(numero shr 4) and $f]:=true;
    $200..$2ff:deco16ic_0.pf2.buffer_color[(numero shr 4) and $f]:=true;
  end;
end;

procedure tumblep_putword(direccion:dword;valor:word);
begin
if direccion<$80000 then exit;
case direccion of
  $100000:begin
            deco16_sound_latch:=valor and $ff;
            h6280_0.set_irq_line(0,HOLD_LINE);
          end;
  $120000..$123fff:ram[(direccion and $3fff) shr 1]:=valor;
  $140000..$1407ff:if (buffer_paleta[(direccion and $7ff) shr 1]<>valor) then begin
                      buffer_paleta[(direccion and $7ff) shr 1]:=valor;
                      cambiar_color(valor,(direccion and $7ff) shr 1);
                   end;
  $18000c:;
  $1a0000..$1a07ff:deco_sprites_0.ram[(direccion and $7ff) shr 1]:=valor;
  $300000..$30000f:deco16ic_0.control_w((direccion and $f) shr 1,valor);
  $320000..$320fff:begin
                      deco16ic_0.pf1.data[(direccion and $fff) shr 1]:=valor;
                      deco16ic_0.pf1.buffer[(direccion and $fff) shr 1]:=true
                   end;
  $322000..$322fff:begin
                      deco16ic_0.pf2.data[(direccion and $fff) shr 1]:=valor;
                      deco16ic_0.pf2.buffer[(direccion and $fff) shr 1]:=true
                   end;
  $340000..$3407ff:deco16ic_0.pf1.rowscroll[(direccion and $7ff) shr 1]:=valor;
  $342000..$3427ff:deco16ic_0.pf2.rowscroll[(direccion and $7ff) shr 1]:=valor;
end;
end;

//Main
procedure reset_tumblep;
begin
 m68000_0.reset;
 deco16ic_0.reset;
 deco_sprites_0.reset;
 deco16_snd_simple_reset;
 reset_audio;
 marcade.in0:=$ffff;
 marcade.in1:=$f7;
end;

function iniciar_tumblep:boolean;
const
  pc_x:array[0..7] of dword=(0, 1, 2, 3, 4, 5, 6, 7);
  pc_y:array[0..7] of dword=(0*16, 1*16, 2*16, 3*16, 4*16, 5*16, 6*16, 7*16);
  pt_x:array[0..15] of dword=(256,257,258,259,260,261,262,263,
  0, 1, 2, 3, 4, 5, 6, 7);
  pt_y:array[0..15] of dword=(0*16, 1*16, 2*16, 3*16, 4*16, 5*16, 6*16, 7*16,
  8*16,9*16,10*16,11*16,12*16,13*16,14*16,15*16);
  ps_x:array[0..15] of dword=(512,513,514,515,516,517,518,519,
   0, 1, 2, 3, 4, 5, 6, 7);
  ps_y:array[0..15] of dword=(0*32, 1*32, 2*32, 3*32, 4*32, 5*32, 6*32, 7*32,
	  8*32, 9*32,10*32,11*32,12*32,13*32,14*32,15*32 );
var
  memoria_temp:pbyte;
begin
iniciar_tumblep:=false;
iniciar_audio(false);
deco16ic_0:=chip_16ic.create(1,2,$100,$100,$f,$f,0,1,0,16,nil,nil);
deco_sprites_0:=tdeco16_sprite.create(2,3,304,0,$1fff);
screen_init(3,512,512,false,true);
iniciar_video(319,240);
//Main CPU
m68000_0:=cpu_m68000.create(14000000,$100);
m68000_0.change_ram16_calls(tumblep_getword,tumblep_putword);
//Sound CPU
deco16_snd_simple_init(32220000 div 8,32220000,nil);
getmem(memoria_temp,$100000);
//cargar roms
if not(cargar_roms16w(@rom[0],@tumblep_rom[0],'tumblep.zip',0)) then exit;
//cargar sonido
if not(cargar_roms(@mem_snd[0],@tumblep_sound,'tumblep.zip',1)) then exit;
//OKI rom
if not(cargar_roms(oki_6295_0.get_rom_addr,@tumblep_oki,'tumblep.zip',1)) then exit;
//convertir chars}
if not(cargar_roms(memoria_temp,@tumblep_char,'tumblep.zip',1)) then exit;
deco56_decrypt_gfx(memoria_temp,$80000);
init_gfx(0,8,8,$4000);
gfx[0].trans[0]:=true;
gfx_set_desc_data(4,0,16*8,$4000*16*8+8,$4000*16*8+0,8,0);
convert_gfx(0,0,memoria_temp,@pc_x[0],@pc_y[0],false,false);
//Tiles
init_gfx(1,16,16,$1000);
gfx[1].trans[0]:=true;
gfx_set_desc_data(4,0,32*16,$1000*32*16+8,$1000*32*16+0,8,0);
convert_gfx(1,0,memoria_temp,@pt_x[0],@pt_y[0],false,false);
//Sprites
if not(cargar_roms16b(memoria_temp,@tumblep_sprites[0],'tumblep.zip',0)) then exit;
init_gfx(2,16,16,$2000);
gfx[2].trans[0]:=true;
gfx_set_desc_data(4,0,32*32,24,8,16,0);
convert_gfx(2,0,memoria_temp,@ps_x[0],@ps_y[0],false,false);
//final
freemem(memoria_temp);
reset_tumblep;
iniciar_tumblep:=true;
end;

procedure Cargar_tumblep;
begin
llamadas_maquina.bucle_general:=tumblep_principal;
llamadas_maquina.iniciar:=iniciar_tumblep;
llamadas_maquina.reset:=reset_tumblep;
llamadas_maquina.fps_max:=58;
end;

end.
