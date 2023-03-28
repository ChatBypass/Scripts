--[[
 .____                  ________ ___.    _____                           __                
 |    |    __ _______   \_____  \\_ |___/ ____\_ __  ______ ____ _____ _/  |_  ___________ 
 |    |   |  |  \__  \   /   |   \| __ \   __\  |  \/  ___// ___\\__  \\   __\/  _ \_  __ \
 |    |___|  |  // __ \_/    |    \ \_\ \  | |  |  /\___ \\  \___ / __ \|  | (  <_> )  | \/
 |_______ \____/(____  /\_______  /___  /__| |____//____  >\___  >____  /__|  \____/|__|   
         \/          \/         \/    \/                \/     \/     \/                   
          \_Welcome to LuaObfuscator.com   (Alpha 0.2.5) ~  Much Love, Ferib 

]]--

local StrToNumber=tonumber;local Byte=string.byte;local Char=string.char;local Sub=string.sub;local Subg=string.gsub;local Rep=string.rep;local Concat=table.concat;local Insert=table.insert;local LDExp=math.ldexp;local GetFEnv=getfenv or function()return _ENV;end ;local Setmetatable=setmetatable;local PCall=pcall;local Select=select;local Unpack=unpack or table.unpack ;local ToNumber=tonumber;local function VMCall(ByteString,vmenv,...)local DIP=1;local repeatNext;ByteString=Subg(Sub(ByteString,5),"..",function(byte)if (Byte(byte,2)==79) then repeatNext=StrToNumber(Sub(byte,1,1));return "";else local a=Char(StrToNumber(byte,16));if repeatNext then local b=Rep(a,repeatNext);repeatNext=nil;return b;else return a;end end end);local function gBit(Bit,Start,End)if End then local Res=(Bit/(2^(Start-1)))%(2^(((End-1) -(Start-1)) + 1)) ;return Res-(Res%1) ;else local Plc=2^(Start-1) ;return (((Bit%(Plc + Plc))>=Plc) and 1) or 0 ;end end local function gBits8()local a=Byte(ByteString,DIP,DIP);DIP=DIP + 1 ;return a;end local function gBits16()local a,b=Byte(ByteString,DIP,DIP + 2 );DIP=DIP + 2 ;return (b * 256) + a ;end local function gBits32()local a,b,c,d=Byte(ByteString,DIP,DIP + 3 );DIP=DIP + 4 ;return (d * 16777216) + (c * 65536) + (b * 256) + a ;end local function gFloat()local Left=gBits32();local Right=gBits32();local IsNormal=1;local Mantissa=(gBit(Right,1,20) * (2^32)) + Left ;local Exponent=gBit(Right,21,31);local Sign=((gBit(Right,32)==1) and  -1) or 1 ;if (Exponent==0) then if (Mantissa==0) then return Sign * 0 ;else Exponent=1;IsNormal=0;end elseif (Exponent==2047) then return ((Mantissa==0) and (Sign * (1/0))) or (Sign * NaN) ;end return LDExp(Sign,Exponent-1023 ) * (IsNormal + (Mantissa/(2^52))) ;end local function gString(Len)local Str;if  not Len then Len=gBits32();if (Len==0) then return "";end end Str=Sub(ByteString,DIP,(DIP + Len) -1 );DIP=DIP + Len ;local FStr={};for Idx=1, #Str do FStr[Idx]=Char(Byte(Sub(Str,Idx,Idx)));end return Concat(FStr);end local gInt=gBits32;local function _R(...)return {...},Select("#",...);end local function Deserialize()local Instrs={};local Functions={};local Lines={};local Chunk={Instrs,Functions,nil,Lines};local ConstCount=gBits32();local Consts={};for Idx=1,ConstCount do local Type=gBits8();local Cons;if (Type==1) then Cons=gBits8()~=0 ;elseif (Type==2) then Cons=gFloat();elseif (Type==3) then Cons=gString();end Consts[Idx]=Cons;end Chunk[3]=gBits8();for Idx=1,gBits32() do local Descriptor=gBits8();if (gBit(Descriptor,1,1)==0) then local Type=gBit(Descriptor,2,3);local Mask=gBit(Descriptor,4,6);local Inst={gBits16(),gBits16(),nil,nil};if (Type==0) then Inst[3]=gBits16();Inst[4]=gBits16();elseif (Type==1) then Inst[3]=gBits32();elseif (Type==2) then Inst[3]=gBits32() -(2^16) ;elseif (Type==3) then Inst[3]=gBits32() -(2^16) ;Inst[4]=gBits16();end if (gBit(Mask,1,1)==1) then Inst[2]=Consts[Inst[2]];end if (gBit(Mask,2,2)==1) then Inst[3]=Consts[Inst[3]];end if (gBit(Mask,3,3)==1) then Inst[4]=Consts[Inst[4]];end Instrs[Idx]=Inst;end end for Idx=1,gBits32() do Functions[Idx-1 ]=Deserialize();end for Idx=1,gBits32() do Lines[Idx]=gBits32();end return Chunk;end local function Wrap(Chunk,Upvalues,Env)local Instr=Chunk[1];local Proto=Chunk[2];local Params=Chunk[3];return function(...)local VIP=1;local Top= -1;local Args={...};local PCount=Select("#",...) -1 ;local function Loop()local Instr=Instr;local Proto=Proto;local Params=Params;local _R=_R;local Vararg={};local Lupvals={};local Stk={};for Idx=0,PCount do if (Idx>=Params) then Vararg[Idx-Params ]=Args[Idx + 1 ];else Stk[Idx]=Args[Idx + 1 ];end end local Varargsz=(PCount-Params) + 1 ;local Inst;local Enum;while true do Inst=Instr[VIP];Enum=Inst[1];if (Enum<=8) then if (Enum<=3) then if (Enum<=1) then if (Enum>0) then local A=Inst[2];Stk[A]=Stk[A](Unpack(Stk,A + 1 ,Inst[3]));else local A=Inst[2];local B=Stk[Inst[3]];Stk[A + 1 ]=B;Stk[A]=B[Inst[4]];end elseif (Enum==2) then Env[Inst[3]]=Stk[Inst[2]];else Stk[Inst[2]]=Stk[Inst[3]];end elseif (Enum<=5) then if (Enum>4) then Stk[Inst[2]]=Wrap(Proto[Inst[3]],nil,Env);else Stk[Inst[2]]=Env[Inst[3]];end elseif (Enum<=6) then local A=Inst[2];Stk[A](Unpack(Stk,A + 1 ,Inst[3]));elseif (Enum>7) then local A=Inst[2];Stk[A](Stk[A + 1 ]);else Stk[Inst[2]][Inst[3]]=Inst[4];end elseif (Enum<=13) then if (Enum<=10) then if (Enum>9) then Stk[Inst[2]]=Stk[Inst[3]][Inst[4]];else local A=Inst[2];local Results,Limit=_R(Stk[A](Unpack(Stk,A + 1 ,Inst[3])));Top=(Limit + A) -1 ;local Edx=0;for Idx=A,Top do Edx=Edx + 1 ;Stk[Idx]=Results[Edx];end end elseif (Enum<=11) then local A=Inst[2];Stk[A]=Stk[A](Stk[A + 1 ]);elseif (Enum>12) then Stk[Inst[2]]=Upvalues[Inst[3]];else Stk[Inst[2]][Inst[3]]=Stk[Inst[4]];end elseif (Enum<=15) then if (Enum>14) then Stk[Inst[2]]();else do return;end end elseif (Enum<=16) then local NewProto=Proto[Inst[3]];local NewUvals;local Indexes={};NewUvals=Setmetatable({},{__index=function(_,Key)local Val=Indexes[Key];return Val[1][Val[2]];end,__newindex=function(_,Key,Value)local Val=Indexes[Key];Val[1][Val[2]]=Value;end});for Idx=1,Inst[4] do VIP=VIP + 1 ;local Mvm=Instr[VIP];if (Mvm[1]==3) then Indexes[Idx-1 ]={Stk,Mvm[3]};else Indexes[Idx-1 ]={Upvalues,Mvm[3]};end Lupvals[ #Lupvals + 1 ]=Indexes;end Stk[Inst[2]]=Wrap(NewProto,NewUvals,Env);elseif (Enum==17) then local A=Inst[2];Stk[A]=Stk[A](Unpack(Stk,A + 1 ,Top));else Stk[Inst[2]]=Inst[3];end VIP=VIP + 1 ;end end A,B=_R(PCall(Loop));if  not A[1] then local line=Chunk[4][VIP] or "?" ;error("Script error at ["   .. line   .. "]:"   .. A[2] );else return Unpack(A,2,B);end end;end return Wrap(Deserialize(),{},vmenv)(...);end VMCall("LOL!493O0003083O00496E7374616E63652O033O006E657703093O005363722O656E47756903053O004672616D6503083O005549436F726E657203093O00546578744C6162656C030E3O005363726F2O6C696E674672616D65030A3O005465787442752O746F6E030C3O005549477269644C61796F757403043O004E616D6503063O004C616748756203063O00506172656E7403043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C61796572030C3O0057616974466F724368696C6403093O00506C6179657247756903043O004D61696E03103O004261636B67726F756E64436F6C6F723303063O00436F6C6F723302465D6BEF5355D53F028O0003083O00506F736974696F6E03053O005544696D320206D877E0C4D9DE3F02D174414068E4E13F03043O0053697A65025O00107140025O00806340030D3O0045787472656D65436F726E6572030C3O00436F726E657252616469757303043O005544696D026O00484003053O005469746C6502CDBBAF9F056EA13F027FBD47E0C4D5A33F025O00E06E40025O00804A4003043O00466F6E7403043O00456E756D030B3O004C75636B6965737447757903043O005465787403073O004C616720487562030A3O0054657874436F6C6F7233025D514A085655E53F030A3O00546578745363616C65642O0103083O005465787453697A65026O002C40030B3O00546578745772612O70656403073O0045787472656D65030B3O004C6167204F7074696F6E7303063O0041637469766502FD52DB1F4AA1B43F0283F4E4FF2DDFD23F026O006D40025O00C0564003093O004C6167205632202O3F025O00406A40026O00494003063O004C6167205632026O00F03F026O00454003073O004E4F5448494E47026O00594003103O00432O6F6C2043686174204C6167202O3F02F5678BE0899DC83F03083O0043686174204C6167025O0080414003093O00536F72744F72646572030B3O004C61796F75744F7264657203093O00636F726F7574696E6503043O0077726170000E012O0012043O00013O00200A5O0002002O12000100034O000B3O00020002001204000100013O00200A000100010002002O12000200044O000B000100020002001204000200013O00200A000200020002002O12000300054O000B000200020002001204000300013O00200A000300030002002O12000400064O000B000300020002001204000400013O00200A000400040002002O12000500054O000B000400020002001204000500013O00200A000500050002002O12000600074O000B000500020002001204000600013O00200A000600060002002O12000700084O000B000600020002001204000700013O00200A000700070002002O12000800054O000B000700020002001204000800013O00200A000800080002002O12000900084O000B000800020002001204000900013O00200A000900090002002O12000A00054O000B000900020002001204000A00013O00200A000A000A0002002O12000B00054O000B000A00020002001204000B00013O00200A000B000B0002002O12000C00094O000B000B000200020030073O000A000B001204000C000D3O00200A000C000C000E00200A000C000C000F00202O000C000C0010002O12000E00114O0001000C000E000200100C3O000C000C0030070001000A001200100C0001000C3O001204000C00143O00200A000C000C0002002O12000D00153O002O12000E00163O002O12000F00164O0001000C000F000200100C00010013000C001204000C00183O00200A000C000C0002002O12000D00193O002O12000E00163O002O12000F001A3O002O12001000164O0001000C0010000200100C00010017000C001204000C00183O00200A000C000C0002002O12000D00163O002O12000E001C3O002O12000F00163O002O120010001D4O0001000C0010000200100C0001001B000C0030070002000A001E00100C0002000C0001001204000C00203O00200A000C000C0002002O12000D00163O002O12000E00214O0001000C000E000200100C0002001F000C0030070003000A002200100C0003000C0001001204000C00143O00200A000C000C0002002O12000D00153O002O12000E00163O002O12000F00164O0001000C000F000200100C00030013000C001204000C00183O00200A000C000C0002002O12000D00233O002O12000E00163O002O12000F00243O002O12001000164O0001000C0010000200100C00030017000C001204000C00183O00200A000C000C0002002O12000D00163O002O12000E00253O002O12000F00163O002O12001000264O0001000C0010000200100C0003001B000C001204000C00283O00200A000C000C002700200A000C000C002900100C00030027000C0030070003002A002B001204000C00143O00200A000C000C0002002O12000D002D3O002O12000E00163O002O12000F00164O0001000C000F000200100C0003002C000C0030070003002E002F00300700030030003100300700030032002F0030070004000A003300100C0004000C0003001204000C00203O00200A000C000C0002002O12000D00163O002O12000E00214O0001000C000E000200100C0004001F000C0030070005000A003400100C0005000C000100300700050035002F001204000C00143O00200A000C000C0002002O12000D00153O002O12000E00163O002O12000F00164O0001000C000F000200100C00050013000C001204000C00183O00200A000C000C0002002O12000D00363O002O12000E00163O002O12000F00373O002O12001000164O0001000C0010000200100C00050017000C001204000C00183O00200A000C000C0002002O12000D00163O002O12000E00383O002O12000F00163O002O12001000394O0001000C0010000200100C0005001B000C0030070006000A003A00100C0006000C0005001204000C00143O00200A000C000C0002002O12000D002D3O002O12000E00163O002O12000F00164O0001000C000F000200100C00060013000C001204000C00183O00200A000C000C0002002O12000D00163O002O12000E003B3O002O12000F00163O002O120010003C4O0001000C0010000200100C0006001B000C001204000C00283O00200A000C000C002700200A000C000C002900100C00060027000C0030070006002A003D001204000C00143O00200A000C000C0002002O12000D003E3O002O12000E00163O002O12000F00164O0001000C000F000200100C0006002C000C00300700060030003F00300700060032002F0030070007000A004000100C0007000C0006001204000C00203O00200A000C000C0002002O12000D00413O002O12000E00414O0001000C000E000200100C0007001F000C0030070008000A004200100C0008000C0005001204000C00143O00200A000C000C0002002O12000D002D3O002O12000E00163O002O12000F00164O0001000C000F000200100C00080013000C001204000C00183O00200A000C000C0002002O12000D00163O002O12000E00163O002O12000F00433O002O12001000164O0001000C0010000200100C00080017000C001204000C00183O00200A000C000C0002002O12000D00163O002O12000E003B3O002O12000F00163O002O120010003C4O0001000C0010000200100C0008001B000C001204000C00283O00200A000C000C002700200A000C000C002900100C00080027000C0030070008002A0044001204000C00143O00200A000C000C0002002O12000D003E3O002O12000E00163O002O12000F00164O0001000C000F000200100C0008002C000C00300700080030004500300700080032002F0030070009000A004000100C0009000C0008001204000C00203O00200A000C000C0002002O12000D00413O002O12000E00414O0001000C000E000200100C0009001F000C003007000A000A004000100C000A000C0005001204000C00203O00200A000C000C0002002O12000D00413O002O12000E00414O0001000C000E000200100C000A001F000C00100C000B000C0005001204000C00283O00200A000C000C004600200A000C000C004700100C000B0046000C000610000C3O000100012O00033O00013O001204000D00483O00200A000D000D00492O0003000E000C4O000B000D000200022O000F000D000100012O000E3O00013O00013O000D3O0003083O00496E7374616E63652O033O006E6577030B3O004C6F63616C53637269707403063O00506172656E74030B3O004C6167204F7074696F6E7303093O00466972654C61675632030B3O0046697265436861744C6167030A3O004669726543726564697403093O00466972655469746C6503093O004C6167205632202O3F03113O004D6F75736542752O746F6E31436C69636B03073O00436F2O6E65637403103O00432O6F6C2043686174204C6167202O3F001E3O0012043O00013O00200A5O0002002O12000100034O000D00026O00013O0002000200200A00013O000400200A00020001000500020500035O001202000300063O000205000300013O001202000300073O000205000300023O001202000300083O000205000300033O001202000300093O001204000300094O000F000300010001001204000300084O000F00030001000100200A00030002000A00200A00030003000B00202O00030003000C000205000500044O000600030005000100200A00030002000D00200A00030003000B00202O00030003000C000205000500054O00060003000500012O000E3O00013O00063O00043O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403213O00682O7470733A2O2F706173746562696E2E636F6D2F7261772F414E5A5932542O4400083O0012043O00013O001204000100023O00202O000100010003002O12000300044O0009000100034O00115O00022O000F3O000100012O000E3O00017O00083O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004F3O00043O00030A3O006C6F6164737472696E6703043O0067616D65030C3O00482O74704765744173796E6303213O00682O7470733A2O2F706173746562696E2E636F6D2F7261772F43744D383175524E00083O0012043O00013O001204000100023O00202O000100010003002O12000300044O0009000100034O00115O00022O000F3O000100012O000E3O00017O00083O00513O00513O00513O00513O00513O00513O00513O00523O00053O00030D3O0072636F6E736F6C65636C656172030C3O0072636F6E736F6C65696E666F03133O0043686174427970612O73207761732068657265030C3O0072636F6E736F6C657761726E03183O0049206B6E6F77207768617420796F75207468696E6B3O2E00093O0012043O00014O000F3O000100010012043O00023O002O12000100034O00083O000200010012043O00043O002O12000100054O00083O000200012O000E3O00017O00093O00543O00543O00553O00553O00553O00563O00563O00563O00573O00023O00030C3O0072636F6E736F6C656E616D6503173O004C616720487562202D205072696E74205461622E65747600043O0012043O00013O002O12000100024O00083O000200012O000E3O00017O00043O00593O00593O00593O005A3O00013O0003093O00466972654C6167563200033O0012043O00014O000F3O000100012O000E3O00017O00033O005E3O005E3O005F3O00013O00030B3O0046697265436861744C616700033O0012043O00014O000F3O000100012O000E3O00017O00033O00613O00613O00623O001E3O004A3O004A3O004A3O004A3O004A3O004B3O004C3O004F3O004F3O00523O00523O00573O00573O005A3O005A3O005B3O005B3O005C3O005C3O005D3O005D3O005D3O005F3O005D3O00603O00603O00603O00623O00603O00633O000E012O00013O00013O00013O00013O00023O00023O00023O00023O00033O00033O00033O00033O00043O00043O00043O00043O00053O00053O00053O00053O00063O00063O00063O00063O00073O00073O00073O00073O00083O00083O00083O00083O00093O00093O00093O00093O000A3O000A3O000A3O000A3O000B3O000B3O000B3O000B3O000C3O000C3O000C3O000C3O000D3O000E3O000E3O000E3O000E3O000E3O000E3O000E3O000F3O00103O00113O00113O00113O00113O00113O00113O00113O00123O00123O00123O00123O00123O00123O00123O00123O00133O00133O00133O00133O00133O00133O00133O00133O00143O00153O00163O00163O00163O00163O00163O00163O00173O00183O00193O00193O00193O00193O00193O00193O00193O001A3O001A3O001A3O001A3O001A3O001A3O001A3O001A3O001B3O001B3O001B3O001B3O001B3O001B3O001B3O001B3O001C3O001C3O001C3O001C3O001D3O001E3O001E3O001E3O001E3O001E3O001E3O001E3O001F3O00203O00213O00223O00233O00243O00243O00243O00243O00243O00243O00253O00263O00273O00283O00283O00283O00283O00283O00283O00283O00293O00293O00293O00293O00293O00293O00293O00293O002A3O002A3O002A3O002A3O002A3O002A3O002A3O002A3O002B3O002C3O002D3O002D3O002D3O002D3O002D3O002D3O002D3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002E3O002F3O002F3O002F3O002F3O00303O00313O00313O00313O00313O00313O00313O00313O00323O00333O00343O00353O00363O00363O00363O00363O00363O00363O00373O00383O00393O00393O00393O00393O00393O00393O00393O003A3O003A3O003A3O003A3O003A3O003A3O003A3O003A3O003B3O003B3O003B3O003B3O003B3O003B3O003B3O003B3O003C3O003C3O003C3O003C3O003D3O003E3O003E3O003E3O003E3O003E3O003E3O003E3O003F3O00403O00413O00423O00433O00433O00433O00433O00433O00433O00443O00453O00463O00463O00463O00463O00463O00463O00473O00483O00483O00483O00483O00633O00633O00643O00643O00643O00643O00643O00643O00",GetFEnv(),...);
