unit shootout_hw;

interface
uses {$IFDEF WINDOWS}windows,{$ENDIF}
     m6502,main_engine,controls_engine,ym_2203,gfx_engine,rom_engine,
     pal_engine,sound_engine,misc_functions;

procedure cargar_shootout;

implementation
const
        shootout_rom:array[0..3] of tipo_roms=(
        (n:'cu00.b1';l:$8000;p:$0;crc:$090edeb6),(n:'cu02.c3';l:$8000;p:$8000;crc:$2a913730),
        (n:'cu01.c1';l:$4000;p:$10000;crc:$8843c3ae),());
        shootout_char:tipo_roms=(n:'cu11.h19';l:$4000;p:$0;crc:$eff00460);
        shootout_sprite:array[0..6] of tipo_roms=(
        (n:'cu04.c7';l:$8000;p:$0;crc:$ceea6b20),(n:'cu03.c5';l:$8000;p:$8000;crc:$b786bb3e),
        (n:'cu06.c10';l:$8000;p:$10000;crc:$2ec1d17f),(n:'cu05.c9';l:$8000;p:$18000;crc:$dd038b85),
        (n:'cu08.c13';l:$8000;p:$20000;crc:$91290933),(n:'cu07.c12';l:$8000;p:$28000;crc:$19b6b94f),());
        shootout_audio:tipo_roms=(n:'cu09.j1';l:$4000;p:$c000;crc:$c4cbd558);
        shootout_tiles:tipo_roms=(n:'cu10.h17';l:$8000;p:$0;crc:$3854c877);
        shootout_pal:tipo_roms=(n:'gb08.k10';l:$100;p:$0;crc:$509c65b6);
var
  mem_bank,mem_bank_dec:array[0..2,0..$3fff] of byte;
  mem_dec:array[0..$7fff] of byte;
  banco,sound_latch:byte;
  bflicker,old_val:boolean;

procedure sprites(prioridad:byte);
var
  f,atrib,x,y:byte;
  nchar:word;
begin
{ 76543210
  xxx-----    bank
  ---x----    vertical size
  ----x---    priority
  -----x--    horizontal flip
  ------x-    flicker
  -------x    enable}
for f:=$7f downto 0 do begin
  atrib:=memoria[$1801+(f*4)];
  if (((atrib and $1)=0) or ((atrib and 8)<>prioridad)) then continue;
  if (((atrib and $2)=1) and (not(bflicker))) then exit;
  nchar:=memoria[$1803+(f*4)]+((atrib shl 3) and $700);
  x:=240-memoria[$1802+(f*4)];
  y:=240-memoria[$1800+(f*4)];
  if (atrib and $10)<>0 then begin //tama�o doble
     nchar:=nchar and $7fe;
     put_gfx_sprite_diff(nchar,64,(atrib and $4)<>0,false,1,0,0);
     put_gfx_sprite_diff(nchar+1,64,(atrib and $4)<>0,false,1,0,16);
     actualiza_gfx_sprite_size(x,y-16,3,16,32);
  end else begin
     put_gfx_sprite(nchar,64,(atrib and $4)<>0,false,1);
     actualiza_gfx_sprite(x,y,3,1);
  end;
end;
end;

procedure update_video_shootout;
var
  f,nchar,color:word;
  x,y,atrib:byte;
begin
for f:=0 to $3ff do begin
  //tiles
  if gfx[2].buffer[f] then begin
    x:=f mod 32;
    y:=f div 32;
    atrib:=memoria[$2c00+f];
    color:=(atrib and $f0) shr 2;
    nchar:=memoria[$2800+f]+((atrib and $07) shl 8);
    put_gfx(x*8,y*8,nchar,color,2,2);
    gfx[2].buffer[f]:=false;
  end;
  //Chars
  if gfx[0].buffer[f] then begin
    x:=f mod 32;
    y:=f div 32;
    atrib:=memoria[$2400+f];
    color:=(atrib and $f0) shr 2;
    nchar:=memoria[$2000+f]+((atrib and $03) shl 8);
    put_gfx_trans(x*8,y*8,nchar,color+128,1,0);
    gfx[0].buffer[f]:=false;
  end;
end;
bflicker:=not(bflicker);
actualiza_trozo(0,0,256,256,2,0,0,256,256,3);
sprites(8);
actualiza_trozo(0,0,256,256,1,0,0,256,256,3);
sprites(0);
actualiza_trozo_final(0,8,256,240,3);
end;

procedure eventos_shootout;
begin
if event.arcade then begin
  if arcade_input.right[0] then marcade.in0:=marcade.in0 and $fe else marcade.in0:=marcade.in0 or 1;
  if arcade_input.left[0] then marcade.in0:=marcade.in0 and $fd else marcade.in0:=marcade.in0 or 2;
  if arcade_input.up[0] then marcade.in0:=marcade.in0 and $fb else marcade.in0:=marcade.in0 or 4;
  if arcade_input.down[0] then marcade.in0:=marcade.in0 and $f7 else marcade.in0:=marcade.in0 or 8;
  if arcade_input.but0[0] then marcade.in0:=marcade.in0 and $ef else marcade.in0:=marcade.in0 or $10;
  if arcade_input.but1[0] then marcade.in0:=marcade.in0 and $df else marcade.in0:=marcade.in0 or $20;
  if (arcade_input.coin[0] and not(old_val)) then begin
      marcade.in2:=marcade.in2 and $bf;
      marcade.in1:=marcade.in1 and $7f;
      m6502_0.change_nmi(ASSERT_LINE);
  end else begin
      marcade.in2:=(marcade.in2 or $40);
      marcade.in1:=(marcade.in1 or $80);
      m6502_0.change_nmi(CLEAR_LINE);
  end;
  old_val:=arcade_input.coin[0];
  if arcade_input.start[0] then marcade.in0:=marcade.in0 and $bf else marcade.in0:=marcade.in0 or $40;
  if arcade_input.start[1] then marcade.in0:=marcade.in0 and $7f else marcade.in0:=marcade.in0 or $80;
end;
end;

procedure principal_shootout;
var
  frame_m,frame_s:single;
  f:byte;
begin
init_controls(false,false,false,true);
frame_m:=m6502_0.tframes;
frame_s:=m6502_1.tframes;
while EmuStatus=EsRuning do begin
 for f:=0 to $ff do begin
   m6502_0.run(frame_m);
   frame_m:=frame_m+m6502_0.tframes-m6502_0.contador;
   m6502_1.run(frame_s);
   frame_s:=frame_s+m6502_1.tframes-m6502_1.contador;
   case f of
      30:marcade.in2:=marcade.in2 and $7f;
      247:begin
            marcade.in2:=marcade.in2 or $80;
            update_video_shootout;
          end;
   end;
 end;
 eventos_shootout;
 video_sync;
end;
end;

function getbyte_shootout(direccion:word):byte;
begin
case direccion of
  0..$fff,$1004..$19ff,$2000..$2fff:getbyte_shootout:=memoria[direccion];
  $1000:getbyte_shootout:=$bf;
  $1001:getbyte_shootout:=marcade.in0;
  $1002:getbyte_shootout:=marcade.in1;
  $1003:getbyte_shootout:=marcade.in2;
  $4000..$7fff:if m6502_0.opcode then getbyte_shootout:=mem_bank_dec[banco,direccion and $3fff]
                  else getbyte_shootout:=mem_bank[banco,direccion and $3fff];
  $8000..$ffff:if m6502_0.opcode then getbyte_shootout:=mem_dec[direccion and $7fff]
                  else getbyte_shootout:=memoria[direccion];
end;
end;

procedure putbyte_shootout(direccion:word;valor:byte);
begin
if direccion>$3fff then exit;
case direccion of
  0..$fff,$1004..$19ff:memoria[direccion]:=valor;
  $1000:banco:=valor and $f;
  $1003:begin
          sound_latch:=valor;
          m6502_1.change_nmi(ASSERT_LINE);
        end;
  $2000..$27ff:begin
                  gfx[0].buffer[direccion and $3ff]:=true;
                  memoria[direccion]:=valor;
               end;
  $2800..$2fff:begin
                  gfx[2].buffer[direccion and $3ff]:=true;
                  memoria[direccion]:=valor;
               end;
end;
end;

function getbyte_snd_shootout(direccion:word):byte;
begin
case direccion of
  0..$7ff,$c000..$ffff:getbyte_snd_shootout:=mem_snd[direccion];
  $4000:getbyte_snd_shootout:=ym2203_0.status;
  $4001:getbyte_snd_shootout:=ym2203_0.read;
  $a000:begin
          getbyte_snd_shootout:=sound_latch;
          m6502_1.change_nmi(CLEAR_LINE);
        end;
end;
end;

procedure putbyte_snd_shootout(direccion:word;valor:byte);
begin
if direccion>$bfff then exit;
case direccion of
  0..$7ff:mem_snd[direccion]:=valor;
  $4000:ym2203_0.control(valor);
  $4001:ym2203_0.write(valor);
end;
end;

procedure shootout_sound_update;
begin
  ym2203_0.Update;
end;

procedure snd_irq(irqstate:byte);
begin
  m6502_1.change_irq(irqstate);
end;

//Main
procedure reset_shootout;
begin
m6502_0.reset;
m6502_1.reset;
ym2203_0.reset;
reset_audio;
marcade.in0:=$ff;
marcade.in1:=$3f;
marcade.in2:=$7f;
bflicker:=false;
banco:=0;
sound_latch:=0;
old_val:=false;
end;

function iniciar_shootout:boolean;
var
  colores:tpaleta;
  f:word;
  mem_temp:array[0..$7fff] of byte;
  memoria_temp:array[0..$2ffff] of byte;
const
    pc_x:array[0..7] of dword=(($2000*8)+0, ($2000*8)+1, ($2000*8)+2, ($2000*8)+3, 0, 1, 2, 3);
    pc_y:array[0..7] of dword=(0*8, 1*8, 2*8, 3*8, 4*8, 5*8, 6*8, 7*8);
    ps_x:array[0..15] of dword=(128+0, 128+1, 128+2, 128+3, 128+4, 128+5, 128+6, 128+7, 0, 1, 2, 3, 4, 5, 6, 7);
    ps_y:array[0..15] of dword=(0*8, 1*8, 2*8, 3*8, 4*8, 5*8, 6*8, 7*8, 8*8, 9*8, 10*8, 11*8, 12*8, 13*8, 14*8, 15*8);
    pt_x:array[0..7] of dword=(($4000*8)+0, ($4000*8)+1, ($4000*8)+2, ($4000*8)+3, 0, 1, 2, 3);
    pt_y:array[0..7] of dword=(0*8, 1*8, 2*8, 3*8, 4*8, 5*8, 6*8, 7*8);
begin
iniciar_shootout:=false;
iniciar_audio(false);
//Chars trans
screen_init(1,256,256,true);
screen_init(2,256,256);
screen_init(3,256,256,false,true);
iniciar_video(256,240);
//Main CPU
m6502_0:=cpu_m6502.create(2000000,256,TCPU_M6502);
m6502_0.change_ram_calls(getbyte_shootout,putbyte_shootout);
//sound CPU
m6502_1:=cpu_m6502.create(1500000,256,TCPU_M6502);
m6502_1.change_ram_calls(getbyte_snd_shootout,putbyte_snd_shootout);
m6502_1.init_sound(shootout_sound_update);
//Sound Chip
ym2203_0:=ym2203_chip.create(1500000);
ym2203_0.change_irq_calls(snd_irq);
//cargar roms
if not(cargar_roms(@memoria_temp[0],@shootout_rom[0],'shootout.zip',0)) then exit;
//Copio las ROM en su sitio
copymemory(@memoria[$8000],@memoria_temp[0],$8000);
copymemory(@mem_bank[0,0],@memoria_temp[$8000],$4000);
copymemory(@mem_bank[1,0],@memoria_temp[$c000],$4000);
copymemory(@mem_bank[2,0],@memoria_temp[$10000],$4000);
//Y las desencripto
for f:=0 to $7fff do mem_dec[f]:=BITSWAP8(memoria[f+$8000],7,5,6,4,3,2,1,0);
for f:=0 to $3fff do begin
  mem_bank_dec[0,f]:=BITSWAP8(mem_bank[0,f],7,5,6,4,3,2,1,0);
  mem_bank_dec[1,f]:=BITSWAP8(mem_bank[1,f],7,5,6,4,3,2,1,0);;
  mem_bank_dec[2,f]:=BITSWAP8(mem_bank[2,f],7,5,6,4,3,2,1,0);;
end;
//Roms audio
if not(cargar_roms(@mem_snd[0],@shootout_audio,'shootout.zip',1)) then exit;
//Cargar chars
if not(cargar_roms(@memoria_temp[0],@shootout_char,'shootout.zip',1)) then exit;
init_gfx(0,8,8,1024);
gfx[0].trans[0]:=true;
gfx_set_desc_data(2,0,8*8,0,4);
convert_gfx(0,0,@memoria_temp[0],@pc_x[0],@pc_y[0],false,false);
//sprites
if not(cargar_roms(@memoria_temp[0],@shootout_sprite[0],'shootout.zip',0)) then exit;
init_gfx(1,16,16,2048);
gfx[1].trans[0]:=true;
gfx_set_desc_data(3,0,32*8,0*$10000*8,1*$10000*8,2*$10000*8);
convert_gfx(1,0,@memoria_temp[0],@ps_x[0],@ps_y[0],false,false);
//tiles
if not(cargar_roms(@memoria_temp[0],@shootout_tiles,'shootout.zip',1)) then exit;
//mover para sacar tiles
copymemory(@mem_temp[0],@memoria_temp[0],$2000);
copymemory(@mem_temp[$4000],@memoria_temp[$2000],$2000);
copymemory(@mem_temp[$2000],@memoria_temp[$4000],$2000);
copymemory(@mem_temp[$6000],@memoria_temp[$6000],$2000);
init_gfx(2,8,8,2048);
gfx_set_desc_data(2,0,8*8,0,4);
convert_gfx(2,0,@mem_temp[0],@pt_x[0],@pt_y[0],false,false);
//poner la paleta
if not(cargar_roms(@memoria_temp[0],@shootout_pal,'shootout.zip',1)) then exit;
for f:=0 to 255 do begin
    colores[f].r:=$21*((memoria_temp[f] shr 0) and 1)+$47*((memoria_temp[f] shr 1) and 1)+$97*((memoria_temp[f] shr 2) and 1);
    colores[f].g:=$21*((memoria_temp[f] shr 3) and 1)+$47*((memoria_temp[f] shr 4) and 1)+$97*((memoria_temp[f] shr 5) and 1);
    colores[f].b:=$21*0+$47*((memoria_temp[f] shr 6) and 1)+$97*((memoria_temp[f] shr 7) and 1);
end;
set_pal(colores,256);
//final
reset_shootout;
iniciar_shootout:=true;
end;

procedure Cargar_shootout;
begin
llamadas_maquina.iniciar:=iniciar_shootout;
llamadas_maquina.bucle_general:=principal_shootout;
llamadas_maquina.reset:=reset_shootout;
end;

end.
