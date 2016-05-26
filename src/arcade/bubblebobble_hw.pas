unit bubblebobble_hw;

interface
uses {$IFDEF WINDOWS}windows,{$ENDIF}
     nz80,main_engine,controls_engine,gfx_engine,ym_2203,ym_3812,
     m680x,rom_engine,pal_engine,sound_engine;

procedure Cargar_bublbobl;
procedure bublbobl_principal;
function iniciar_bublbobl:boolean;
procedure reset_bublbobl;
//Main CPU
function bublbobl_getbyte(direccion:word):byte;
procedure bublbobl_putbyte(direccion:word;valor:byte);
//Sub CPU
function bb_misc_getbyte(direccion:word):byte;
procedure bb_misc_putbyte(direccion:word;valor:byte);
//Sound CPU
function bbsnd_getbyte(direccion:word):byte;
procedure bbsnd_putbyte(direccion:word;valor:byte);
procedure bb_sound_update;
procedure snd_irq(irqstate:byte);
//MCU CPU
function mcu_getbyte(direccion:word):byte;
procedure mcu_putbyte(direccion:word;valor:byte);

implementation
const
        bublbobl_rom:array[0..2] of tipo_roms=(
        (n:'a78-06-1.51';l:$8000;p:0;crc:$567934b6),(n:'a78-05-1.52';l:$10000;p:$8000;crc:$9f8ee242),());
        bublbobl_rom2:tipo_roms=(n:'a78-08.37';l:$8000;p:0;crc:$ae11a07b);
        bublbobl_chars:array[0..12] of tipo_roms=(
        (n:'a78-09.12';l:$8000;p:0;crc:$20358c22),(n:'a78-10.13';l:$8000;p:$8000;crc:$930168a9),
        (n:'a78-11.14';l:$8000;p:$10000;crc:$9773e512),(n:'a78-12.15';l:$8000;p:$18000;crc:$d045549b),
        (n:'a78-13.16';l:$8000;p:$20000;crc:$d0af35c5),(n:'a78-14.17';l:$8000;p:$28000;crc:$7b5369a8),
        (n:'a78-15.30';l:$8000;p:$40000;crc:$6b61a413),(n:'a78-16.31';l:$8000;p:$48000;crc:$b5492d97),
        (n:'a78-17.32';l:$8000;p:$50000;crc:$d69762d5),(n:'a78-18.33';l:$8000;p:$58000;crc:$9f243b68),
        (n:'a78-19.34';l:$8000;p:$60000;crc:$66e9438c),(n:'a78-20.35';l:$8000;p:$68000;crc:$9ef863ad),());
        bublbobl_snd: tipo_roms=(n:'a78-07.46';l:$8000;p:0;crc:$4f9a26e8);
        bublbobl_prom: tipo_roms=(n:'a71-25.41';l:$100;p:0;crc:$2d0f8545);
        bublbobl_mcu_rom:tipo_roms=(n:'a78-01.17';l:$1000;p:$f000;crc:$b1bfb53d);
        //Dip
        bublbobl_dip_a:array [0..5] of def_dip=(
        (mask:$5;name:'Mode';number:4;dip:((dip_val:$4;dip_name:'Game - English'),(dip_val:$5;dip_name:'Game - Japanese'),(dip_val:$1;dip_name:'Test (Grid and Inputs)'),(dip_val:$0;dip_name:'Test (RAM and Sound)/Pause'),(),(),(),(),(),(),(),(),(),(),(),())),
        (mask:$2;name:'Flip Screen';number:2;dip:((dip_val:$2;dip_name:'Off'),(dip_val:$0;dip_name:'On'),(),(),(),(),(),(),(),(),(),(),(),(),(),())),
        (mask:$8;name:'Demo Sounds';number:2;dip:((dip_val:$0;dip_name:'Off'),(dip_val:$8;dip_name:'On'),(),(),(),(),(),(),(),(),(),(),(),(),(),())),
        (mask:$30;name:'Coin A';number:4;dip:((dip_val:$10;dip_name:'2C 1C'),(dip_val:$30;dip_name:'1C 1C'),(dip_val:$0;dip_name:'2C 3C'),(dip_val:$20;dip_name:'1C 2C'),(),(),(),(),(),(),(),(),(),(),(),())),
        (mask:$c0;name:'Coin B';number:4;dip:((dip_val:$40;dip_name:'2C 1C'),(dip_val:$c0;dip_name:'1C 1C'),(dip_val:$0;dip_name:'2C 3C'),(dip_val:$80;dip_name:'1C 2C'),(),(),(),(),(),(),(),(),(),(),(),())),());
        bublbobl_dip_b:array [0..5] of def_dip=(
        (mask:$3;name:'Difficulty';number:4;dip:((dip_val:$2;dip_name:'Easy'),(dip_val:$3;dip_name:'Normal'),(dip_val:$1;dip_name:'Hard'),(dip_val:$0;dip_name:'Very Hard'),(),(),(),(),(),(),(),(),(),(),(),())),
        (mask:$c;name:'Bonus Life';number:4;dip:((dip_val:$8;dip_name:'20K 80K 300K'),(dip_val:$c;dip_name:'30K 100K 400K'),(dip_val:$4;dip_name:'40K 200K 500K'),(dip_val:$0;dip_name:'50K 250K 500K'),(),(),(),(),(),(),(),(),(),(),(),())),
        (mask:$30;name:'Lives';number:4;dip:((dip_val:$10;dip_name:'1'),(dip_val:$0;dip_name:'2'),(dip_val:$30;dip_name:'3'),(dip_val:$20;dip_name:'5'),(),(),(),(),(),(),(),(),(),(),(),())),
        (mask:$40;name:'Unknown';number:2;dip:((dip_val:$40;dip_name:'Off'),(dip_val:$0;dip_name:'On'),(),(),(),(),(),(),(),(),(),(),(),(),(),())),
        (mask:$80;name:'ROM Type';number:2;dip:((dip_val:$80;dip_name:'IC52=512kb, IC53=none'),(dip_val:$0;dip_name:'IC52=256kb, IC53=256kb'),(),(),(),(),(),(),(),(),(),(),(),(),(),())),());
var
 memoria_rom:array [0..3,$0..$3FFF] of byte;
 mem_mcu:array[0..$FFFF] of byte;
 mem_prom:array[0..$ff] of byte;
 banco_rom,sound_stat,sound_latch:byte;
 sound_nmi,pending_nmi,video_enable:boolean;
 ddr1,ddr2,ddr3,ddr4:byte;
 port1_in,port1_out,port2_in,port2_out,port3_in,port3_out,port4_in,port4_out:byte;

procedure Cargar_bublbobl;
begin
llamadas_maquina.iniciar:=iniciar_bublbobl;
llamadas_maquina.bucle_general:=bublbobl_principal;
llamadas_maquina.reset:=reset_bublbobl;
llamadas_maquina.fps_max:=59.185606;
end;

function iniciar_bublbobl:boolean;
var
  f:dword;
  memoria_temp:array[0..$7ffff] of byte;
const
  pc_x:array[0..7] of dword=(3, 2, 1, 0, 8+3, 8+2, 8+1, 8+0);
  pc_y:array[0..7] of dword=(0*16, 1*16, 2*16, 3*16, 4*16, 5*16, 6*16, 7*16);
begin
iniciar_bublbobl:=false;
iniciar_audio(false);
//Pantallas:  principal+char y sprites
screen_init(1,512,256,false,true);
iniciar_video(256,224);
//Main CPU
main_z80:=cpu_z80.create(6000000,264);
main_z80.change_ram_calls(bublbobl_getbyte,bublbobl_putbyte);
//Second CPU
sub_z80:=cpu_z80.create(6000000,264);
sub_z80.change_ram_calls(bb_misc_getbyte,bb_misc_putbyte);
//Sound CPU
snd_z80:=cpu_z80.create(3000000,264);
snd_z80.change_ram_calls(bbsnd_getbyte,bbsnd_putbyte);
snd_z80.init_sound(bb_sound_update);
//MCU
main_m6800:=cpu_m6800.create(4000000,264,CPU_M6801);
main_m6800.change_ram_calls(mcu_getbyte,mcu_putbyte);
//Sound Chip
ym2203_0:=ym2203_chip.create(3000000,0.25,0.25);
ym2203_0.change_irq_calls(snd_irq);
ym3812_0:=ym3812_chip.create(YM3526_FM,3000000,0.5);
//cargar roms
if not(cargar_roms(@memoria_temp[0],@bublbobl_rom[0],'bublbobl.zip',0)) then exit;
//poner las roms y los bancos de rom
copymemory(@memoria[0],@memoria_temp[0],$8000);
for f:=0 to 3 do copymemory(@memoria_rom[f,0],@memoria_temp[$8000+(f*$4000)],$4000);
//Segunda CPU
if not(cargar_roms(@mem_misc[0],@bublbobl_rom2,'bublbobl.zip',1)) then exit;
//MCU
if not(cargar_roms(@mem_mcu[0],@bublbobl_mcu_rom,'bublbobl.zip',1)) then exit;
//sonido
if not(cargar_roms(@mem_snd[0],@bublbobl_snd,'bublbobl.zip',1)) then exit;
//proms video
if not(cargar_roms(@mem_prom[0],@bublbobl_prom,'bublbobl.zip',1)) then exit;
//convertir chars
if not(cargar_roms(@memoria_temp[0],@bublbobl_chars,'bublbobl.zip',0)) then exit;
for f:=0 to $7ffff do memoria_temp[f]:=not(memoria_temp[f]); //invertir las roms
init_gfx(0,8,8,$4000);
gfx[0].trans[15]:=true;
gfx_set_desc_data(4,0,16*8,0,4,$4000*16*8+0,$4000*16*8+4);
convert_gfx(0,0,@memoria_temp[0],@pc_x[0],@pc_y[0],false,false);
//DIP
marcade.dswa:=$fe;
marcade.dswb:=$ff;
marcade.dswa_val:=@bublbobl_dip_a;
marcade.dswb_val:=@bublbobl_dip_b;
//final
reset_bublbobl;
iniciar_bublbobl:=true;
end;

procedure reset_bublbobl;
begin
 main_z80.reset;
 sub_z80.reset;
 snd_z80.reset;
 main_m6800.reset;
 ym2203_0.reset;
 YM3812_0.reset;
 reset_audio;
 banco_rom:=0;
 sound_nmi:=false;
 pending_nmi:=false;
 sound_stat:=0;
 marcade.in0:=$b3;
 marcade.in1:=$FF;
 marcade.in2:=$ff;
 sound_latch:=0;
 ddr1:=0;ddr2:=0;ddr3:=0;ddr4:=0;
 port1_in:=0;port1_out:=0;port2_in:=0;port2_out:=0;port3_in:=0;port3_out:=0;port4_in:=0;port4_out:=0;
end;

procedure update_video_bublbobl;inline;
var
    nchar,color:word;
    sx,x,goffs,gfx_offs:word;
    flipx,flipy:boolean;
    prom_line,atrib,atrib2,offs:byte;
    xc,yc,sy,y,gfx_attr,gfx_num:byte;
begin
fill_full_screen(1,$100);
if video_enable then begin
 sx:=0;
 for offs:=0 to $bf do begin
		if ((memoria[$dd00+(offs*4)]=0) and (memoria[$dd01+(offs*4)]=0) and (memoria[$dd02+(offs*4)]=0) and (memoria[$dd03+(offs*4)]=0)) then continue;
		gfx_num:=memoria[$dd01+(offs*4)];
		gfx_attr:=memoria[$dd03+(offs*4)];
		prom_line:=$80+((gfx_num and $e0) shr 1);
		gfx_offs:=(gfx_num and $1f) shl 7;
		if ((gfx_num and $a0)=$a0) then gfx_offs:=gfx_offs or $1000;
		sy:=256-memoria[$dd00+(offs*4)];
		for yc:=0 to $1f do begin
      atrib2:=mem_prom[prom_line+(yc shr 1)];
			if (atrib2 and $08)<>0 then	continue;	// NEXT
			if (atrib2 and $04)=0 then sx:=memoria[$dd02+(offs*4)]+((gfx_attr and $40) shl 2); // next column
			for xc:=0 to 1 do begin
				goffs:=gfx_offs+(xc shl 6)+((yc and 7) shl 1)+((atrib2 and $03) shl 4);
        atrib:=memoria[$c001+goffs];
				nchar:=memoria[$c000+goffs]+((atrib and $03) shl 8)+((gfx_attr and $0f) shl 10);
				color:=(atrib and $3c) shl 2;
				flipx:=(atrib and $40)<>0;
				flipy:=(atrib and $80)<>0;
				x:=sx+xc*8;
				y:=sy+yc*8;
        put_gfx_sprite(nchar,color,flipx,flipy,0);
        actualiza_gfx_sprite(x,y,1,0);
			end;
		end;
		sx:=sx+16;
   end;
end;
actualiza_trozo_final(0,16,256,224,1);
end;

procedure eventos_bublbobl;
begin
if event.arcade then begin
  if arcade_input.right[0] then marcade.in1:=(marcade.in1 and $fd) else marcade.in1:=(marcade.in1 or $2);
  if arcade_input.left[0] then marcade.in1:=(marcade.in1 and $fe) else marcade.in1:=(marcade.in1 or $1);
  if arcade_input.but1[0] then marcade.in1:=(marcade.in1 and $df) else marcade.in1:=(marcade.in1 or $20);
  if arcade_input.but0[0] then marcade.in1:=(marcade.in1 and $ef) else marcade.in1:=(marcade.in1 or $10);
  if arcade_input.right[1] then marcade.in2:=(marcade.in2 and $fd) else marcade.in2:=(marcade.in2 or $2);
  if arcade_input.left[1] then marcade.in2:=(marcade.in2 and $fe) else marcade.in2:=(marcade.in2 or $1);
  if arcade_input.but1[1] then marcade.in2:=(marcade.in2 and $df) else marcade.in2:=(marcade.in2 or $20);
  if arcade_input.but0[1] then marcade.in2:=(marcade.in2 and $ef) else marcade.in2:=(marcade.in2 or $10);
  if arcade_input.coin[0] then  marcade.in0:=(marcade.in0 or $4) else marcade.in0:=(marcade.in0 and $fb);
  if arcade_input.coin[1] then  marcade.in0:=(marcade.in0 or $8) else marcade.in0:=(marcade.in0 and $f7);
  if arcade_input.start[0] then marcade.in1:=(marcade.in1 and $bf) else marcade.in1:=(marcade.in1 or $40);
  if arcade_input.start[1] then marcade.in2:=(marcade.in2 and $bf) else marcade.in2:=(marcade.in2 or $40);
end;
end;

procedure bublbobl_principal;
var
  frame_m,frame_mi,frame_s,frame_mcu:single;
  f:word;
begin
init_controls(false,false,false,true);
frame_m:=main_z80.tframes;
frame_mi:=sub_z80.tframes;
frame_s:=snd_z80.tframes;
frame_mcu:=main_m6800.tframes;
while EmuStatus=EsRuning do begin
 for f:=0 to 263 do begin
  //main
  main_z80.run(frame_m);
  frame_m:=frame_m+main_z80.tframes-main_z80.contador;
  //segunda cpu
  sub_z80.run(frame_mi);
  frame_mi:=frame_mi+sub_z80.tframes-sub_z80.contador;
  //sonido
  snd_z80.run(frame_s);
  frame_s:=frame_s+snd_z80.tframes-snd_z80.contador;
  //mcu
  main_m6800.run(frame_mcu);
  frame_mcu:=frame_mcu+main_m6800.tframes-main_m6800.contador;
  if f=239 then begin
    sub_z80.pedir_irq:=HOLD_LINE;
    main_m6800.pedir_irq:=HOLD_LINE;
    update_video_bublbobl;
  end;
 end;
 eventos_bublbobl;
 video_sync;
end;
end;

function bbsnd_getbyte(direccion:word):byte;
begin
  case direccion of
    $9000:bbsnd_getbyte:=ym2203_0.read_status;
    $9001:bbsnd_getbyte:=ym2203_0.read_reg;
    $a000:bbsnd_getbyte:=ym3812_0.status;
    $a001:bbsnd_getbyte:=ym3812_0.read;
    $b000:bbsnd_getbyte:=sound_latch;
    else bbsnd_getbyte:=mem_snd[direccion];
  end;
end;

procedure bbsnd_putbyte(direccion:word;valor:byte);
begin
if direccion<$8000 then exit;
mem_snd[direccion]:=valor;
case direccion of
  $9000:ym2203_0.control(valor);
  $9001:ym2203_0.write_reg(valor);
  $a000:YM3812_0.control(valor);
  $a001:YM3812_0.write(valor);
  $b000:sound_stat:=valor;
  $b001:begin
          sound_nmi:=true;
          if pending_nmi then begin
              pending_nmi:=false;
              snd_z80.pedir_nmi:=PULSE_LINE;
          end;
        end;
  $b002:sound_nmi:=false;
end;
end;

procedure cambiar_color(dir:word);inline;
var
  tmp_color:byte;
  color:tcolor;
begin
  tmp_color:=buffer_paleta[dir];
  color.r:=pal4bit(tmp_color shr 4);
  color.g:=pal4bit(tmp_color);
  tmp_color:=buffer_paleta[1+dir];
  color.b:=pal4bit(tmp_color shr 4);
  set_pal_color(color,dir shr 1);
end;

function bublbobl_getbyte(direccion:word):byte;
begin
case direccion of
  $8000..$bfff:bublbobl_getbyte:=memoria_rom[banco_rom,(direccion and $3fff)];
  $fa00:bublbobl_getbyte:=sound_stat;
  else bublbobl_getbyte:=memoria[direccion];
end;
end;

procedure bublbobl_putbyte(direccion:word;valor:byte);
begin
if direccion<$c000 then exit;
memoria[direccion]:=valor;
case direccion of
        $f800..$f9ff:if buffer_paleta[direccion and $1ff]<>valor then begin
                        buffer_paleta[direccion and $1ff]:=valor;
                        cambiar_color(direccion and $1fe);
                     end;
        $fa00:begin
                if sound_nmi then snd_z80.pedir_nmi:=PULSE_LINE
                  else pending_nmi:=true;
                sound_latch:=valor;
              end;
        $fa03:if valor<>0 then snd_z80.pedir_reset:=ASSERT_LINE
                else snd_z80.pedir_reset:=CLEAR_LINE;
        $fb40:begin
                banco_rom:=(valor xor 4) and 7;
                if (valor and $10)<>0 then sub_z80.pedir_reset:=CLEAR_LINE
                    else sub_z80.pedir_reset:=ASSERT_LINE;
                if (valor and $20)<>0 then main_m6800.pedir_reset:=CLEAR_LINE
                    else main_m6800.pedir_reset:=ASSERT_LINE;
                video_enable:=(valor and $40)<>0;
                main_screen.flip_main_screen:=(valor and $80)<>0;
              end;
end;
end;

function bb_misc_getbyte(direccion:word):byte;
begin
  case direccion of
    $e000..$f7ff:bb_misc_getbyte:=memoria[direccion];
      else bb_misc_getbyte:=mem_misc[direccion];
  end;
end;

procedure bb_misc_putbyte(direccion:word;valor:byte);
begin
if direccion<$8000 then exit;
mem_misc[direccion]:=valor;
case direccion of
  $e000..$f7ff:memoria[direccion]:=valor;
end;
end;

procedure bb_sound_update;
begin
  ym2203_0.Update;
  YM3812_0.update;
end;

procedure snd_irq(irqstate:byte);
begin
  if (irqstate=1) then snd_z80.pedir_irq:=ASSERT_LINE
    else snd_z80.pedir_irq:=CLEAR_LINE;
end;

function mcu_getbyte(direccion:word):byte;
begin
case direccion of
  $0:mcu_getbyte:=ddr1;
  $1:mcu_getbyte:=ddr2;
  $2:begin //port1
        port1_in:=marcade.in0;
        mcu_getbyte:=(port1_out and ddr1) or (port1_in and not(ddr1));
     end;
  $3:mcu_getbyte:=(port2_out and ddr2) or (port2_in and not(ddr2)); //port2
  $4:mcu_getbyte:=ddr3;
  $5:mcu_getbyte:=ddr4;
  $6:mcu_getbyte:=(port3_out and ddr3) or (port3_in and not(ddr3)); //port3
  $7:mcu_getbyte:=(port4_out and ddr4) or (port4_in and not(ddr4)); //port4
      else mcu_getbyte:=mem_mcu[direccion];
end;
end;

procedure mcu_putbyte(direccion:word;valor:byte);
var
  address:word;
begin
if direccion>$efff then exit;
mem_mcu[direccion]:=valor;
case direccion of
  $0:ddr1:=valor;
  $1:ddr2:=valor;
  $2:begin //port1
       if (((port1_out and $40)<>0) and ((not(valor) and $40)<>0)) then begin
          main_z80.im2_lo:=memoria[$fc00];
          main_z80.pedir_irq:=HOLD_LINE;
	      end;
	      port1_out:=valor;
     end;
  $3:begin //port2
        if (((not(port2_out) and $10)<>0) and ((valor and $10)<>0)) then begin
		      address:=port4_out or ((valor and $0f) shl 8);
      		if (port1_out and $80)<>0 then begin //read
      			if ((address and $0800)=$0000) then	begin
              case (address and $3) of
                0:port3_in:=marcade.dswa;
                1:port3_in:=marcade.dswb;
                2:port3_in:=marcade.in1;
                3:port3_in:=marcade.in2;
              end;
      			end else begin
              if ((address and $0c00)=$0c00) then port3_in:=memoria[$fc00+(address and $03ff)];
            end;
          end	else begin //write
      			if ((address and $0c00)=$0c00) then memoria[$fc00+(address and $03ff)]:=port3_out;
		      end;
        end;
	      port2_out:=valor;
     end;
  $4:ddr3:=valor;
  $5:ddr4:=valor;
  $6:port3_out:=valor;
  $7:port4_out:=valor;
end;
end;

end.
