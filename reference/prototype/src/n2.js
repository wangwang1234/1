// ---------- 内容 ----------
const WEAPONS={
  pistol:{name:'手枪',rate:4.2,dmg:14,spd:1150,range:680,spread:0.03,n:1,kind:'bullet',kb:70,mag:12,rl:1.0,snd:'pistol',fx:{fl:15,cone:2.2,side:0,sm:1,sp:3,li:1.6,sh:'brass',shk:0.06,kick:3.5,gk:4}},
  deagle:{name:'沙漠之鹰',rate:1.8,dmg:44,spd:1350,range:780,spread:0.02,n:1,kind:'bullet',kb:240,mag:7,rl:1.3,snd:'deagle',fx:{fl:25,cone:3,side:1,sm:3,sp:7,li:2.8,sh:'brass',shk:0.24,kick:10,gk:10,flip:1}},
  ak47:{name:'AK-47',rate:9,dmg:11.5,spd:1300,range:820,spread:0.045,n:1,kind:'bullet',kb:80,mag:30,rl:1.6,bloom:0.012,bmax:0.11,snd:'ak47',fx:{fl:19,cone:2.8,side:1,sm:1,sp:4,li:2.0,sh:'brass',shk:0.09,kick:4.5,gk:5}},
  smg:{name:'冲锋枪',rate:14,dmg:6.5,spd:1150,range:560,spread:0.08,n:1,kind:'bullet',kb:40,mag:32,rl:1.3,bloom:0.006,bmax:0.08,snd:'smg',fx:{fl:13,cone:2,side:0,sm:1,sp:2,li:1.3,sh:'brass',shk:0.04,kick:2.5,gk:3}},
  shotgun:{name:'霰弹枪',rate:1.15,dmg:11,spd:900,range:430,spread:0.42,n:8,kind:'bullet',kb:130,mag:6,rl:1.9,snd:'shotgun',fx:{fl:27,cone:3.6,side:0,sm:4,sp:10,li:2.9,sh:'red',shk:0.22,kick:8,gk:8,pump:1}},
  sniper:{name:'狙击枪',rate:0.8,dmg:95,spd:2600,range:1500,spread:0,n:1,kind:'bullet',kb:280,pierce:3,mag:5,rl:2.0,snd:'sniper',fx:{fl:26,cone:4.4,side:1,sm:5,sp:6,li:3,sh:'big',shk:0.28,kick:10,gk:9,bolt:1}},
  lmg:{name:'轻机枪',rate:11,dmg:9.5,spd:1250,range:820,spread:0.06,n:1,kind:'bullet',kb:70,mag:100,rl:3.2,bloom:0.005,bmax:0.1,slow:0.72,snd:'lmg',fx:{fl:20,cone:2.8,side:1,sm:1,sp:4,li:2.0,sh:'brass',shk:0.08,kick:4,gk:5}},
  rocket:{name:'火箭筒',rate:1.2,dmg:30,spd:650,range:950,kind:'rocket',aoe:120,aoeDmg:55,kb:320,mag:1,rl:1.5,snd:'rocket',fx:{fl:22,cone:3,side:0,sm:6,sp:6,li:2.4,sh:null,shk:0.22,kick:8,gk:7}},
  katana:{name:'武士刀',rate:2.4,dmg:38,kind:'melee',arc:2.2,reach:88,kb:260,mag:0},
  flame:{name:'喷火器',rate:13,dmg:4.4,spd:380,range:300,spread:0.22,n:1,kind:'flame',kb:10,mag:120,rl:2.0},
  minigun:{name:'加特林',rate:28,dmg:6.5,spd:1250,range:760,spread:0.09,n:1,kind:'bullet',kb:30,mag:200,rl:3.5,slow:0.45,spinup:0.6,snd:'minigun',fx:{fl:18,cone:2.6,side:0,sm:1,sp:3,li:2.2,sh:'brass',shk:0.05,kick:2,gk:2.5}},
  autoshot:{name:'自动霰弹枪',rate:4.5,dmg:8.5,spd:880,range:400,spread:0.36,n:6,kind:'bullet',kb:90,mag:20,rl:2.4,snd:'autoshot',fx:{fl:22,cone:3.2,side:0,sm:2,sp:6,li:2.4,sh:'red',shk:0.12,kick:5,gk:6}},
  amr:{name:'反器材狙击枪',rate:0.55,dmg:160,spd:3200,range:1700,spread:0,n:1,kind:'bullet',kb:420,pierce:6,wallPierce:1,mag:4,rl:2.6,selfKb:240,snd:'amr',fx:{fl:34,cone:5,side:1,sm:8,sp:10,li:3.6,sh:'big',shk:0.42,kick:16,gk:13,bolt:1}},
  dual:{name:'双持手枪',rate:8,dmg:12,spd:1150,range:640,spread:0.05,n:1,kind:'bullet',kb:60,mag:24,rl:1.5,dual:1,snd:'pistol',fx:{fl:14,cone:2.1,side:0,sm:1,sp:3,li:1.6,sh:'brass',shk:0.05,kick:3,gk:3}},
  revolver:{name:'左轮手枪',rate:2.2,dmg:36,spd:1250,range:720,spread:0.02,n:1,kind:'bullet',kb:170,mag:6,rl:1.8,bounce:1,snd:'revolver',fx:{fl:21,cone:2.6,side:1,sm:2,sp:5,li:2.4,sh:null,shk:0.15,kick:7,gk:8,flip:1}},
  gl:{name:'榴弹发射器',rate:1.4,dmg:20,kind:'lob',range:560,aoe:115,aoeDmg:62,kb:300,mag:6,rl:2.2,fuse:1.1,snd:'gl',fx:{fl:16,cone:2,side:0,sm:4,sp:3,li:1.8,sh:null,shk:0.12,kick:6,gk:6}},
  rail:{name:'电磁炮',rate:1.6,dmg:40,kind:'rail',range:1600,mag:4,rl:2.4,kb:350,charge:1.0},
  laser:{name:'激光枪',rate:10,dmg:6,kind:'laser',range:540,mag:100,rl:2.5}};
{const RAR={pistol:'c',deagle:'r',ak47:'c',smg:'c',shotgun:'c',sniper:'r',lmg:'r',rocket:'r',katana:'c',flame:'c',minigun:'l',autoshot:'r',amr:'l',dual:'c',revolver:'c',gl:'r',rail:'l',laser:'r'};for(const k in RAR)WEAPONS[k].rar=RAR[k];}
{const FALL={pistol:[0.6,0.55],deagle:[0.65,0.6],ak47:[0.6,0.6],smg:[0.55,0.5],shotgun:[0.35,0.25],sniper:[1,1],lmg:[0.6,0.6],minigun:[0.5,0.5],autoshot:[0.35,0.25],amr:[1,1],dual:[0.55,0.5],revolver:[0.65,0.6]};for(const k in FALL){WEAPONS[k].eff=FALL[k][0];WEAPONS[k].minF=FALL[k][1];}}
const GADGETS={frag:{name:'手雷',desc:'扔出去 1.5 秒后爆炸',cd:7},molotov:{name:'燃烧瓶',desc:'落地起火，烧一片区域',cd:10},flash:{name:'闪光弹',desc:'致盲附近敌人，玩家会白屏',cd:12},mine:{name:'地雷',desc:'埋在脚下，敌人踩到就炸，最多 3 个',cd:6},sentry:{name:'自动炮台',desc:'放一台小炮台，自动射击 16 秒',cd:18},
  eshield:{name:'能量护盾',desc:'5 秒内获得等于生命上限的护盾',cd:20},smoke:{name:'烟雾弹',desc:'放出一团烟，挡住视线和手电光',cd:14},flare:{name:'照明弹',desc:'照亮一大片 10 秒，全队可见',cd:16},decoy:{name:'诱饵仓鼠',desc:'充气仓鼠吸引火力，还会发出假脚步声',cd:15},jetpack:{name:'喷气背包',desc:'朝准星方向飞过障碍',cd:10},medkit:{name:'急救瓜子包',desc:'3 秒内回复 40% 生命',cd:18},freeze:{name:'冰冻手雷',desc:'冻住范围内的敌人 1.5 秒',cd:14},beacon:{name:'传送信标',desc:'先插信标，再按一次瞬间传回',cd:12}};
const RW={c:1.2,r:0.7,l:0.3},RNAME={c:'普通',r:'稀有',l:'传说'},RCOL={c:'#d9d4e2',r:'#5fb0ff',l:'#ffcf3a'};
const WDESC={pistol:'初始武器，稳定好用',deagle:'大口径手枪，威力大、后坐力强',ak47:'全自动步枪，连射越久越散',smg:'射速极快，近中距离压制',shotgun:'近距离一枪一大片',sniper:'超远射程，一枪穿透多个敌人',lmg:'100 发弹链火力压制，开火时会变慢',rocket:'爆炸范围伤害，拆塔利器',katana:'近战斩击，还能把子弹弹回去',flame:'持续喷火，点燃敌人',minigun:'先转管预热，转起来射速极高，开火时几乎走不动',autoshot:'全自动连喷，近距离清场',amr:'能打穿障碍物，后坐力会把自己往后推',dual:'左右手交替开火，射速翻倍',revolver:'6 发高伤害，子弹会在墙上弹一次',gl:'抛射榴弹，落地弹跳后爆炸，能越过障碍',rail:'按住蓄力，松开射出贯穿一条线的光束',laser:'持续光束，照到的敌人持续掉血'};
const ABIL={strong:{name:'强壮',desc:'生命上限 +15%，体型变大一圈',max:5,ic:'壮'},armor:{name:'护甲',desc:'受到伤害 -7%，穿上防弹背心',max:4,ic:'甲'},regen:{name:'再生',desc:'每秒回血 +2，身上冒绿光',max:4,ic:'✚'},vamp:{name:'吸血',desc:'伤害的 4% 转为生命，露出小獠牙',max:4,ic:'牙'},
  speed:{name:'风火轮',desc:'移速 +8%，换上运动鞋',max:4,ic:'⚡'},dash:{name:'翻滚大师',desc:'翻滚冷却 -15%，撞人有伤害，留下残影',max:3,ic:'↻'},magnet:{name:'大磁铁',desc:'拾取范围 +50%，背上一块磁铁',max:3,ic:'磁'},
  torch:{name:'强光手电',desc:'手电照得更远 +18%，枪上的手电变大',max:4,ic:'光'},wide:{name:'广角镜头',desc:'手电光束更宽',max:3,ic:'◠'},ears:{name:'顺风耳',desc:'听觉范围 +30%，耳朵变大',max:3,ic:'耳'},nvg:{name:'夜视仪',desc:'黑暗中直接看见附近的敌人（每级 +60）',max:3,ic:'夜'},recon:{name:'侦察兵',desc:'打中的敌人全队可见 1.5 秒（每级），帽子插天线',max:3,ic:'侦'},
  rage:{name:'越战越勇',desc:'伤害 +10%，系上红头巾',max:5,ic:'怒'},crit:{name:'幸运瓜子',desc:'暴击率 +8%，帽子上长出四叶草',max:5,ic:'★'},rate:{name:'连点手指',desc:'攻击速度 +8%，枪上多一圈金环',max:5,ic:'»'},frost:{name:'冰霜弹',desc:'命中减速 1 秒（每级 +0.3 秒），枪口结冰',max:3,ic:'❄'},chain:{name:'连锁闪电',desc:'命中有 10% 几率劈出闪电（每级），背上特斯拉线圈',max:3,ic:'ϟ'},
  scholar:{name:'学霸',desc:'获得经验 +12%，戴上眼镜',max:3,ic:'学'},scav:{name:'击杀回弹',desc:'击杀后补充 25% 弹匣（每级），挂上弹药带',max:2,ic:'补'},gcd:{name:'道具大师',desc:'道具冷却 -15%，挂上工具腰包',max:3,ic:'道'},aura:{name:'治疗光环',desc:'自己和身边队友每秒回血 +2',max:3,ic:'环'},banner:{name:'战旗',desc:'身边队友伤害 +6%，背后插一面小旗',max:3,ic:'旗'}};
const TALENTS={undying:{name:'不死鼠',desc:'每条命免死一次，回到 40% 血量'},berserk:{name:'狂暴',desc:'血量低于 40% 时伤害 +40%、射速 +30%'},squad:{name:'召唤小队',desc:'每 20 秒在身边召唤 3 个己方小兵'},giant:{name:'巨型化',desc:'体型变大，生命 +60%、伤害 +15%，不会被击退'},nightvision:{name:'夜视',desc:'手电照得更远，身边 260 内的敌人全队可见'},overdrive:{name:'火力全开',desc:'每次多射 1 发，射速 +20%'},aegis:{name:'王牌护盾',desc:'护盾 +2 层，每 3 秒补一层'},storm:{name:'雷神',desc:'命中有 30% 几率劈出连锁闪电'},detonate:{name:'爆裂击杀',desc:'被你击杀的敌人会原地爆炸'},phantom:{name:'疾风隐身',desc:'翻滚冷却减半，翻滚后隐身 1.5 秒'},vampire:{name:'吸血鬼',desc:'吸血 +15%，每次击杀回 25 血'},bottomless:{name:'无尽弹药',desc:'35% 几率不耗子弹，换弹快 50%'}};
const PETS={chick:{name:'小鸡战友',desc:'冲上去啄附近的敌人'},firefly:{name:'萤火虫',desc:'绕身飞行，电击附近敌人'},hedgehog:{name:'刺猬炮台',desc:'跟在身后，向敌人射尖刺'}};
const SKINS={gold:{name:'金丝熊',fur:'#f2a54a',cream:'#fff3e0'},pudding:{name:'布丁',fur:'#f7d37c',cream:'#fff8e6'},silver:{name:'银狐',fur:'#e4e1ea',cream:'#ffffff'},stripe:{name:'三线',fur:'#b2adbd',cream:'#f6f3f9',stripe:'#5e5868'}},SKIN_IDS=Object.keys(SKINS);
const MOB={roach:{r:11,hp:28,spd:178},rat:{r:19,hp:95,spd:128},boss:{r:46,hp:2600,spd:112}};

// ---------- 状态 ----------
let state='title',G=null,UID=1;
let hams=[],minions=[],mobs=[],structs=[],crates=[],gems=[],pickups=[],pets=[],bullets=[],parts=[],shells=[],decals=[],pops=[],rings=[],feed=[],slashes=[],zaps=[],trails=[],lobs=[],fires=[],mines=[],beams=[];
let hitstop=0,timeScale=1,slowT=0,time=0,RDT=0.016,fxPulse=0,FXK=1,burns=[],wave=null;
const FLASH={flash:{x:0,y:0,h:0,i:0,t:0,max:1},boom:{x:0,y:0,h:0,i:0,t:0,max:1},eflash:{x:0,y:0,h:0,i:0,t:0,max:1}};
const PDEF={spark:[520,1.5,0],dot:[700,1.5,1],fur:[90,3.5,0],star:[160,2.5,0],smoke:[-35,2,0],fire:[-110,2.5,0],flash:[0,0,0],ember:[320,0.6,0]};
const keys=Object.create(null),keyEdge=new Set();
const mouse={x:0,y:0,down:false,rdown:false,has:false};
const TS={move:null,aim:null};const BTN={dash:{p:false,id:null},gad:{p:false,id:null}};
let VIEWS=[];
const fxn=n=>Math.max(1,Math.round(n*FXK));
const EMPTY=[];

// ---------- 特效工具 ----------
function addP(p){if(parts.length>=900)return;const d=PDEF[p.type]||PDEF.flash;p.vx=p.vx||0;p.vy=p.vy||0;p.vh=p.vh||0;p.h=p.h||0;if(p.grav===undefined)p.grav=d[0];if(p.drag===undefined)p.drag=d[1];p.bounce=d[2];p.max=p.life;parts.push(p);}
function pop(x,y,h,text,color='#fff',size=16,life=0.7){if(pops.length>80)pops.shift();pops.push({x,y,h,text,color,size,life,max:life,vh:60});}
function flashL(k,x,y,h,i,life){const L=FLASH[k];L.x=x;L.y=y;L.h=h;L.i=i;L.t=life;L.max=life;}
function decal(d){decals.push(d);if(decals.length>70)decals.shift();}
function ring(x,y,h,r,grow,life,col){rings.push({x,y,h,r,grow,life,max:life,col});if(rings.length>24)rings.shift();}
function sparks(x,y,h,col,n){for(let i=0;i<n;i++){const a=rand(0,TAU),s=rand(90,280);addP({type:'spark',x,y,h,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(20,180),life:rand(0.1,0.22),col,size:1.4});}}
function setWave(x,y,life,r,s){if(wave&&wave.s>s&&wave.t<wave.life*0.6)return;wave={x,y,h:20,t:0,life,r,s};}
function shakeAt(x,y,a,only){for(const v of VIEWS){let k;if(only)k=v.ham===only?1:0;else{const h=v.ham;k=h?clamp(1-Math.hypot(h.x-x,h.y-y)/900,0,1):1;}v.trauma=Math.min(1,v.trauma+a*k);}}
function kickV(h,a,m){if(h&&h.view){h.view.ckx-=Math.cos(a)*m;h.view.cky-=Math.sin(a)*m;}}
function pushToast(v,text,color,dur){if(v.toastQ.some(t=>t.text===text)||(v.toastCur&&v.toastCur.text===text))return;v.toastQ.push({text,color,dur,t:0});if(v.toastQ.length>3)v.toastQ.shift();}
function toastH(h,text,color='#fff',dur=2){if(h&&h.view)pushToast(h.view,text,color,dur);}
function toastAll(text,color='#fff',dur=2.4){for(const v of VIEWS)pushToast(v,text,color,dur);}
function addFeed(text,col){feed.push({text,col,t:0});if(feed.length>5)feed.shift();}
function hn(h){return h.name;}
function muzzle(h,gx,gy,gh,k){const a=h.aim,c=Math.cos(a),s=Math.sin(a),K=FXK;
  addP({type:'flash',x:gx,y:gy,h:gh,life:0.055,size:rand(14,19)*k*(0.7+0.35*K),col:'#fff6c2',dir:a,rot:rand(0,TAU)});flashL('flash',gx,gy,gh+12,2*K*k,0.07);
  addP({type:'smoke',x:gx,y:gy,h:gh,vx:c*55+rand(-15,15),vy:s*55+rand(-15,15),vh:rand(10,30),life:rand(0.35,0.55),size:rand(6,10)*k,grow:30,col:'#8f8aa0'});
  for(let i=0;i<fxn(3);i++){const a2=a+rand(-0.5,0.5),sv=rand(180,380);addP({type:'spark',x:gx,y:gy,h:gh,vx:Math.cos(a2)*sv,vy:Math.sin(a2)*sv,vh:rand(0,90),life:rand(0.06,0.12),col:'#fff2a0',size:1.3});}
  const rx=-s,ry=c;shells.push({x:h.x+c*h.r*0.9+rx*h.r*0.5,y:h.y+s*h.r*0.9+ry*h.r*0.5,z:gh+4,vx:rx*rand(70,130)-c*30,vy:ry*rand(70,130)-s*30,vz:rand(140,220),rot:rand(0,TAU),vr:rand(-20,20),life:3.5});if(shells.length>120)shells.shift();}
function onHitFx(x,y,h,col,big){addP({type:'flash',x,y,h,life:0.07,size:(big?15:10)*(0.75+0.3*FXK),col,rot:rand(0,TAU),star:1});sparks(x,y,h,col,fxn(big?6:3));if(big)ring(x,y,h,3,140*FXK,0.16,col);}
function slashFx(h,a,reach,arc){slashes.push({x:h.x,y:h.y,h:h.r*1.1,a,reach,arc,dir:h.swingDir,t:0,life:0.18});for(let i=0;i<fxn(5);i++){const aa=a+rand(-arc/2,arc/2),d=reach*rand(0.7,1.05);addP({type:'spark',x:h.x+Math.cos(aa)*d,y:h.y+Math.sin(aa)*d,h:h.r,vx:-Math.sin(aa)*h.swingDir*260,vy:Math.cos(aa)*h.swingDir*260,vh:rand(0,40),life:0.1,col:'#d8f0ff',size:1.3,grav:0});}}
function deathFx(t,col){const K=FXK,bh=t.r*1.1;hitstop=Math.max(hitstop,0.05+0.02*K);shakeAt(t.x,t.y,0.3*K);setWave(t.x,t.y,0.35,0.55,0.5);
  for(let i=0;i<fxn(16);i++){const a=rand(0,TAU),s=rand(60,260);addP({type:'fur',x:t.x,y:t.y,h:bh,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(60,240),life:rand(0.5,0.95),size:rand(4,7),col:Math.random()<0.5?'#eba557':'#fff2df'});}
  for(let i=0;i<fxn(8);i++){const a=rand(0,TAU),s=rand(80,220);addP({type:'star',x:t.x,y:t.y,h:bh,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(80,240),life:0.65,size:rand(7,11),col:col,glow:1});}
  addP({type:'flash',x:t.x,y:t.y,h:bh,life:0.1,size:30*(0.7+0.35*K),col:'#ffffff',rot:rand(0,TAU),star:1});ring(t.x,t.y,3,10,260*K,0.32,col);ring(t.x,t.y,3,6,170*K,0.42,'#ffffff');SFX.ratDie();}
function smallDeath(t,col,n){for(let i=0;i<fxn(n);i++){const a=rand(0,TAU),s=rand(40,220);addP({type:'dot',x:t.x,y:t.y,h:t.r,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(80,240),life:rand(0.35,0.65),size:rand(2.5,4.5),col});}
  addP({type:'flash',x:t.x,y:t.y,h:t.r,life:0.07,size:t.r*1.3*(0.7+0.35*FXK),col:'#ffe0b0',rot:rand(0,TAU),star:1});ring(t.x,t.y,2,6,150*FXK,0.22,col);}
function bigBoom(x,y,k){const K=FXK;noise(x,y,'boom',1.6,null);{const q=sndAt(x,y);GSFX.boom(q.pan,q.vol,true);}shakeAt(x,y,0.45*K*k);flashL('boom',x,y,60,3.2*K,0.7);fxPulse=Math.max(fxPulse,0.6*K);setWave(x,y,0.6,1.2*k,1);
  addP({type:'flash',x,y,h:40,life:0.12,size:60*k*(0.7+0.35*K),col:'#fff1c0',rot:rand(0,TAU),star:1});
  for(let i=0;i<fxn(18*k);i++){const a=rand(0,TAU),s=rand(30,160);addP({type:'fire',x,y,h:rand(10,60),vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(40,160),life:rand(0.3,0.55),size:rand(30,56)*k});}
  for(let i=0;i<fxn(30*k);i++){const a=rand(0,TAU),s=rand(140,420);addP({type:'ember',x,y,h:rand(10,40),vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(100,320),life:rand(0.6,1.3),size:1.3,col:'#ffb04a'});}
  for(let i=0;i<fxn(14*k);i++)addP({type:'smoke',x:x+rand(-40,40),y:y+rand(-40,40),h:rand(20,50),vx:rand(-40,40),vy:rand(-40,40),vh:rand(40,100),life:rand(1,1.8),size:rand(26,44)*k,grow:30,col:'#35303d'});
  ring(x,y,3,20,420*K*k,0.4,'#ffb066');ring(x,y,3,10,260*K*k,0.55,'#ff6a2a');decal({type:'scorch',x,y,r:110*k,rot:rand(0,TAU),life:30,max:30});}
function rocketBoom(x,y,h,R){const K=FXK;noise(x,y,'boom',1.2,null);{const q=sndAt(x,y);GSFX.boom(q.pan,q.vol,false);}shakeAt(x,y,0.28*K);flashL('boom',x,y,40,2.4*K,0.5);setWave(x,y,0.45,0.7,0.7);
  addP({type:'flash',x,y,h,life:0.09,size:R*0.4*(0.7+0.35*K),col:'#fff1c0',rot:rand(0,TAU),star:1});
  for(let i=0;i<fxn(10);i++){const a=rand(0,TAU),s=rand(30,140);addP({type:'fire',x,y,h:rand(6,h+16),vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(30,120),life:rand(0.22,0.42),size:rand(22,38)});}
  for(let i=0;i<fxn(18);i++){const a=rand(0,TAU),s=rand(120,340);addP({type:'ember',x,y,h:rand(8,26),vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(80,240),life:rand(0.5,1),size:1.2,col:'#ffb04a'});}
  for(let i=0;i<fxn(7);i++)addP({type:'smoke',x:x+rand(-20,20),y:y+rand(-20,20),h:rand(10,30),vx:rand(-30,30),vy:rand(-30,30),vh:rand(30,80),life:rand(0.8,1.3),size:rand(16,26),grow:26,col:'#3a3440'});
  ring(x,y,3,12,R*2.6,0.3,'#ffb066');decal({type:'scorch',x,y,r:R*0.6,rot:rand(0,TAU),life:18,max:18});}
function chainLightning(e,dmg,o){let cur=e;const hit=new Set([e]);for(let k=0;k<2;k++){let nx=null,bd=170*170;hashRange(cur.x,cur.y,170,c=>{if(hit.has(c)||c.isProp||!canHit(o.team,c))return;const d=d2(c.x,c.y,cur.x,cur.y);if(d<bd){bd=d;nx=c;}});if(!nx)break;zaps.push({x0:cur.x,y0:cur.y,h0:cur.r,x1:nx.x,y1:nx.y,h1:nx.r,t:0,life:0.16});dealDmg(nx,dmg,{team:o.team,owner:o,x:cur.x,y:cur.y});hit.add(nx);cur=nx;}SFX.ric();}

// ---------- 空间哈希 ----------
const HC=128,HMAP=new Map();
function hashAll(){HMAP.clear();const add=e=>{const r=e.r,x0=Math.floor((e.x-r)/HC),x1=Math.floor((e.x+r)/HC),y0=Math.floor((e.y-r)/HC),y1=Math.floor((e.y+r)/HC);for(let cx=x0;cx<=x1;cx++)for(let cy=y0;cy<=y1;cy++){const k=cx*1000+cy;let a=HMAP.get(k);if(!a)HMAP.set(k,a=[]);a.push(e);}};
  for(const p of props)if(!p.dead)add(p);for(const d of decoys)if(!d.dead)add(d);for(const h of hams)if(h.alive)add(h);for(const m of minions)if(!m.dead)add(m);for(const m of mobs)if(!m.dead)add(m);for(const s of structs)if(!s.dead)add(s);for(const c of crates)if(!c.dead)add(c);}
function hashAt(x,y){return HMAP.get(Math.floor(x/HC)*1000+Math.floor(y/HC))||EMPTY;}
function hashRange(x,y,r,fn){const x0=Math.floor((x-r)/HC),x1=Math.floor((x+r)/HC),y0=Math.floor((y-r)/HC),y1=Math.floor((y+r)/HC),seen=new Set();for(let cx=x0;cx<=x1;cx++)for(let cy=y0;cy<=y1;cy++){const a=HMAP.get(cx*1000+cy);if(!a)continue;for(const e of a){if(seen.has(e))continue;seen.add(e);fn(e);}}}
function canHit(team,e){if(e.dead||(e.kind==='ham'&&!e.alive))return false;if(team==='neutral')return e.kind==='ham'||e.kind==='minion';return e.team!==team;}
function nearestFoe(team,x,y,R,noCrate=true){let best=null,bd=R*R;hashRange(x,y,R,e=>{if(!canHit(team,e)||e.isProp||(noCrate&&e.kind==='crate')||(e.kind==='base'&&e.shielded))return;const d=d2(x,y,e.x,e.y);if(d<bd){bd=d;best=e;}});return best;}

// ---------- 仓鼠 ----------
function xpNeed(l){return Math.round(24+l*15+l*l*2.4);}
function calcStats(h){const a=h.ab,T=h.tal||{};
  h.st={speed:SPEED0*(1+0.12*(a.speed||0))*(T.giant?0.92:1),maxHp:(100+25*(a.hp||0)+(h.lvl-1)*8)*(T.giant?1.6:1),regen:1.5*(a.regen||0),vamp:0.05*(a.vamp||0)+(T.vampire?0.15:0),crit:0.1*(a.crit||0),critDmg:2+0.5*(a.headshot||0),multi:(a.multi||0)+(T.overdrive?1:0),split:a.split||0,dashCd:1.15*(1-0.2*(a.dash||0))*(T.phantom?0.5:1),dashDmg:(a.dash||0)*18,shield:(a.shield||0)+(T.aegis?2:0),shieldCd:T.aegis?3:8,magnet:95*(1+0.5*(a.magnet||0)),chain:0.15*(a.chain||0)+(T.storm?0.3:0),frost:a.frost||0,
    dmg:(1+0.12*(a.rage||0))*(1+0.03*(h.lvl-1))*(h.crownT>0?1.25:1)*(T.giant?1.15:1),rate:(1+0.12*(a.rate||0))*(T.overdrive?1.2:1),rl:1/((1+0.25*(a.reload||0))*(T.bottomless?1.5:1)),magK:1+0.3*(a.mag||0),
    pierce:a.pierce||0,incend:0.12*(a.incend||0),ric:a.ricochet||0,armor:0.08*(a.armor||0),scav:0.3*(a.scav||0),runngun:!!a.runngun,xpK:1+0.15*(a.scholar||0),demo:1+0.25*(a.demo||0),hunter:1+0.25*(a.hunter||0),gcd:1-0.15*(a.gcd||0),aura:2*(a.aura||0),rangeK:1+0.15*(a.longbarrel||0)};
  h.r=T.giant?21.6:16;
  const f=h.maxHp?h.hp/h.maxHp:1;h.maxHp=h.st.maxHp;h.hp=Math.min(h.maxHp,Math.max(1,f*h.maxHp));}
function makeHam(team,ctl,name,idx,skin){
  const h={kind:'ham',id:UID++,skin:skin||SKIN_IDS[(Math.random()*SKIN_IDS.length)|0],team,ctl,name,idx,x:0,y:0,vx:0,vy:0,r:16,aim:team==='blue'?0:Math.PI,hp:100,maxHp:0,alive:true,respawnT:0,lvl:1,xp:0,xpNext:xpNeed(1),pending:0,choices:null,
    weapon:{id:'pistol',lvl:1},ammo:0,reloadT:0,reloadDur:1,bloom:0,pumpT:0,flipT:0,boltT:0,spin:0,spinA:0,charge:0,chHold:0,dualSide:1,beam:null,beamT:0,gadget:{id:'frag',lvl:1,cd:2},blindT:0,tal:{},talentPend:0,undyUsed:false,air:null,z:0,padCd:0,invisT:0,revealT:0,squadT:20,evo:{a:0,b:0,c:0},stunT:0,eshield:0,eshieldT:0,medT:0,medRate:0,lastShotT:-9,ramp:0,burstN:0,burstT:0,marks:[],markHold:0,markAcc:0,steadyT:0,deployT:0,flameT:0,beacon:null,jetT:0,bannerK:1,swingN:0,shotN:0,dashSpd:1,hasteT:0,dazzleT:0,beams:null,iaidoHit:null,ab:{},petList:[],fireCd:0,dashCd:0,rollT:0,rollA:0,rdx:1,rdy:0,iframes:0,hurtT:0,flash:0,shield:0,shieldT:8,crownT:0,dashHit:null,
    kills:0,deaths:0,bdmg:0,dmgDealt:0,aggroT:-9,swingT:0,swingDir:1,burnBy:null,
    walk:0,moving:false,vr:{v:16,w:0},sq:{v:1,w:0},puff:{v:0,w:0},kick:{v:0,w:0},heat:0,munchT:0,spitT:0,slowT:0,burnT:0,burnAcc:0,
    inp:{mx:0,my:0,ml:0,aim:0,fire:false,dash:false,reload:false,gadget:false,card:-1},view:null,rig:null,ai:null,mwx:0,mwy:0};
  if(ctl==='ai')h.ai={lane:['top','mid','bot'][idx%3],wp:1,state:'push',retarget:0,target:null,jT:rand(12,30),camp:null,strafe:1,strafeT:0,cardT:0,dashT:rand(1,3),stuckT:0,px:0,py:0};
  calcStats(h);h.hp=h.maxHp;h.ammo=magSize(h);placeAtBase(h);h.inp.aim=h.aim;return h;
}
function placeAtBase(h){const b=BASE_POS[h.team],s=h.team==='blue'?1:-1;h.x=b.x+s*165+rand(-30,30);h.y=b.y+rand(-110,110);h.vx=h.vy=0;}
function respawn(h){h.alive=true;calcStats(h);h.hp=h.maxHp;placeAtBase(h);h.iframes=2;h.rollT=0;h.slowT=0;h.burnT=0;h.shield=h.st.shield?1:0;h.ammo=magSize(h);h.reloadT=0;h.bloom=0;h.spin=0;h.charge=0;h.chHold=0;h.beam=null;h.blindT=0;h.undyUsed=false;h.air=null;h.z=0;h.invisT=0;h.stunT=0;h.eshieldT=0;h.eshield=0;h.medT=0;h.ramp=0;h.marks=[];h.deployT=0;h.flameT=0;h.burstN=0;h.jetT=0;if(h.ai){h.ai.wp=1;h.ai.state='push';h.ai.target=null;}ring(h.x,h.y,3,10,200,0.4,TCOL[h.team]);toastH(h,'复活！','#8de0a6',1.2);}
function giveXP(h,n){if(!h||h.kind!=='ham'||h.lvl>=30)return;h.xp+=n*(h.st?h.st.xpK:1);
  while(h.xp>=h.xpNext&&h.lvl<30){h.xp-=h.xpNext;h.lvl++;h.xpNext=xpNeed(h.lvl);h.pending++;calcStats(h);h.hp=Math.min(h.maxHp,h.hp+h.maxHp*0.2);pop(h.x,h.y,h.r*3.2,'+HP','#8de0a6',15,0.8);if(h.lvl%10===0)h.talentPend++;
    SFX.boing(true);h.sq.v=1.3;h.sq.w=0;ring(h.x,h.y,3,h.r,220,0.4,'#ffd166');for(let k=0;k<fxn(10);k++){const a=rand(0,TAU);addP({type:'star',x:h.x,y:h.y,h:30,vx:Math.cos(a)*110,vy:Math.sin(a)*110,vh:rand(60,180),life:0.7,size:7,col:'#ffe27a',glow:1});}
    toastH(h,h.lvl%10===0?`Lv${h.lvl}！解锁一个强大天赋`:`咕咚！升到 Lv${h.lvl}，选一个奖励`,h.lvl%10===0?'#ff9ff0':'#ffd166',2.2);}
  if(h.lvl>=30)h.xp=0;
  if(h.pending>0&&!h.choices)rollChoices(h);}
function rollChoices(h){
  if(h.talentPend>0){const tp=Object.keys(TALENTS).filter(k=>!h.tal[k]),o=[];while(o.length<3&&tp.length)o.push({t:'tal',id:tp.splice((Math.random()*tp.length)|0,1)[0]});if(o.length){h.choices=o;return;}h.talentPend=0;}
  const pool=[];
  if(h.weapon.lvl<5)pool.push({t:'wlvl',id:h.weapon.id,w:2.6});
  for(const id in WEAPONS)if(id!==h.weapon.id)pool.push({t:'weap',id,w:RW[WEAPONS[id].rar]||1});
  if(h.gadget.lvl<4)pool.push({t:'glvl',id:h.gadget.id,w:1.2});for(const id in GADGETS)if(id!==h.gadget.id)pool.push({t:'gad',id,w:RW[GADGETS[id].rar]*0.9});
  for(const id in ABIL){const l=h.ab[id]||0;if(l<ABIL[id].max)pool.push({t:'abil',id,w:2});}
  for(const id in PETS){const p=h.petList.find(q=>q.type===id);if(!p||p.lvl<3)pool.push({t:'pet',id,w:p?1.1:0.9});}
  const out=[];while(out.length<3&&pool.length){let s=0;for(const c of pool)s+=c.w;let r=Math.random()*s,k=0;for(;k<pool.length-1;k++){r-=pool[k].w;if(r<=0)break;}out.push(pool.splice(k,1)[0]);}
  h.choices=out;}
function choiceLabel(h,c){
  if(c.t==='tal')return{type:'天赋',name:TALENTS[c.id].name,lv:'天赋',desc:TALENTS[c.id].desc,rar:'l'};
  if(c.t==='wlvl')return{type:'武器',name:WEAPONS[c.id].name,lv:'Lv'+(h.weapon.lvl+1),desc:'伤害、射速和弹匣提升',rar:WEAPONS[c.id].rar};
  if(c.t==='weap')return{type:'武器',name:WEAPONS[c.id].name,lv:'换上',desc:WDESC[c.id],rar:WEAPONS[c.id].rar};
  if(c.t==='gad')return{type:'道具',name:GADGETS[c.id].name,lv:'换上',desc:GADGETS[c.id].desc,rar:GADGETS[c.id].rar};
  if(c.t==='glvl')return{type:'道具',name:GADGETS[c.id].name,lv:'Lv'+(h.gadget.lvl+1),desc:'冷却更短，效果更强',rar:GADGETS[c.id].rar};
  if(c.t==='abil'){const l=(h.ab[c.id]||0)+1;return{type:'能力',name:ABIL[c.id].name,lv:l>1?'Lv'+l:'新',desc:ABIL[c.id].desc};}
  const p=h.petList.find(q=>q.type===c.id);return{type:'宠物',name:PETS[c.id].name,lv:p?'Lv'+(p.lvl+1):'新',desc:PETS[c.id].desc};}
function applyChoice(h,i){
  const c=h.choices&&h.choices[i];if(!c)return;const lab=choiceLabel(h,c);
  if(c.t==='wlvl')h.weapon.lvl++;else if(c.t==='weap')h.weapon={id:c.id,lvl:1};else if(c.t==='gad')h.gadget={id:c.id,lvl:1,cd:0};else if(c.t==='glvl')h.gadget.lvl++;else if(c.t==='tal'){h.tal[c.id]=true;h.talentPend=Math.max(0,h.talentPend-1);}
  else if(c.t==='abil')h.ab[c.id]=(h.ab[c.id]||0)+1;
  else{const p=h.petList.find(q=>q.type===c.id);if(p)p.lvl++;else{const np=mkPet(c.id,h);h.petList.push(np);pets.push(np);}}
  h.pending=Math.max(0,h.pending-1);h.choices=null;calcStats(h);if(c.id==='shield'&&h.shield<1)h.shield=1;if(c.t==='tal'&&c.id==='aegis')h.shield=h.st.shield;if(c.t==='weap'||c.t==='wlvl'||(c.t==='abil'&&c.id==='mag')){h.ammo=magSize(h);h.reloadT=0;h.bloom=0;h.spin=0;h.charge=0;h.chHold=0;h.beam=null;}
  SFX.open();ring(h.x,h.y,3,h.r,180,0.35,'#ffd166');toastH(h,`获得：${lab.name} ${lab.lv==='新'||lab.lv==='换上'?'':lab.lv}`,'#ffd166',1.6);
  if(h.pending>0)rollChoices(h);}
function mkBullet(kind,by,x,y,h,a,spd,dmg,range,o={}){return{kind,team:by.team,by,owner:by.kind==='ham'?by:null,x,y,h,px:x,py:y,vx:Math.cos(a)*spd,vy:Math.sin(a)*spd,dmg,r:o.r||5,life:range/spd,pierce:o.pierce||0,kb:o.kb||40,aoe:o.aoe||0,aoeDmg:o.aoeDmg||0,hit:new Set(),rot:rand(0,TAU),vr:rand(-12,12),split:1,bounce:o.bounce||0,wp:o.wp||0,inS:null,x0:x,y0:y,eff:o.eff||1,minF:o.minF||1,maxD:range};}
function magSize(h){const W=WEAPONS[h.weapon.id];return W.mag?Math.max(1,Math.round(W.mag*h.st.magK*(1+0.15*(h.weapon.lvl-1)))):0;}
function sndAt(x,y){if(!VIEWS.length)return{pan:0,vol:0};let best=1e9,lx=x;for(const v of VIEWS){const h=v.ham,cx=h?h.x:v.camX,cy=h?h.y:v.camY,d=Math.hypot(x-cx,y-cy);if(d<best){best=d;lx=cx;}}return{pan:clamp((x-lx)/650,-0.9,0.9),vol:Math.pow(clamp(1-best/1500,0,1),1.5)};}
function mobSnd(e,k){const q=sndAt(e.x,e.y);GSFX.shot(k,q.pan,q.vol*0.7);}
function hamSnd(h){const q=sndAt(h.x,h.y);return{pan:q.pan,vol:q.vol*(h.ctl==='ai'?0.75:1)};}
function hitMark(o,e){const v=o&&o.view;if(!v)return;v.hitT=0.14;v.hx=e.x;v.hy=e.y;v.hh=e.r*1.3;v.hk=!!(e.dead||(e.kind==='ham'&&!e.alive));GSFX.hit(0,0.8);}
function startReload(h){const W=WEAPONS[h.weapon.id];if(!W.mag||h.reloadT>0)return;noise(h.x,h.y,'step',0.4,h);h.reloadDur=W.rl*h.st.rl;h.reloadT=h.reloadDur;const q=hamSnd(h);GSFX.reload(q.pan,q.vol,h.reloadDur);}
function gunFx(h,W,gx,gy,gh){h.revealT=0.45;noise(h.x,h.y,'gun',1,h);const F=W.fx,a=h.aim,c=Math.cos(a),s=Math.sin(a),K=FXK,sz=F.fl*(0.75+0.3*K);
  addP({type:'flash',x:gx,y:gy,h:gh,life:0.05+F.fl*0.0012,size:sz*rand(0.9,1.1),col:'#fff6c2',dir:a,cone:F.cone,rot:rand(0,TAU)});
  if(F.side)for(const k of [-1,1])addP({type:'flash',x:gx-c*3,y:gy-s*3,h:gh,life:0.045,size:sz*0.5,col:'#ffd27a',dir:a+k*1.45,cone:1.7,rot:rand(0,TAU)});
  flashL('flash',gx,gy,gh+12,F.li*K,0.07);
  for(let i=0;i<fxn(F.sm);i++)addP({type:'smoke',x:gx+c*rand(0,10),y:gy+s*rand(0,10),h:gh,vx:c*rand(30,90)+rand(-20,20),vy:s*rand(30,90)+rand(-20,20),vh:rand(8,30),life:rand(0.4,0.8),size:rand(6,10)*(F.fl/18),grow:28,col:'#a9a4b6'});
  for(let i=0;i<fxn(F.sp);i++){const a2=a+rand(-0.45,0.45),sv=rand(220,480);addP({type:'spark',x:gx,y:gy,h:gh,vx:Math.cos(a2)*sv,vy:Math.sin(a2)*sv,vh:rand(0,90),life:rand(0.06,0.13),col:'#ffd27a',size:1.3});}
  if(F.sh){const rx=-s,ry=c;shells.push({x:h.x+c*h.r*0.6+rx*h.r*0.5,y:h.y+s*h.r*0.6+ry*h.r*0.5,z:gh+4,vx:rx*rand(90,150)-c*rand(10,40),vy:ry*rand(90,150)-s*rand(10,40),vz:rand(150,240),rot:rand(0,TAU),vr:rand(-22,22),life:4,type:F.sh,tink:0});if(shells.length>160)shells.shift();}
  shakeAt(h.x,h.y,F.shk*K,h);kickV(h,a,F.kick);h.kick.w-=F.gk*14;
  if(F.flip)h.flipT=0.22;if(F.pump)h.pumpT=0.55;if(F.bolt)h.boltT=0.8;}
function sniperTrail(gx,gy,gh,a,range){const c=Math.cos(a),s=Math.sin(a);let L=0;while(L<range&&!pointSolid(gx+c*L,gy+s*L,1))L+=16;trails.push({x0:gx,y0:gy,x1:gx+c*L,y1:gy+s*L,h:gh,t:0,life:0.9});if(trails.length>12)trails.shift();
  for(let i=0;i<fxn(6);i++){const k=Math.random()*Math.min(L,500);addP({type:'smoke',x:gx+c*k,y:gy+s*k,h:gh,vx:rand(-8,8),vy:rand(-8,8),vh:rand(4,12),life:rand(0.6,1),size:rand(4,7),grow:14,col:'#c9c6d2'});}}
function fireWeapon(h){
  const id=h.weapon.id,W=WEAPONS[id],L=h.weapon.lvl,st=h.st,a0=h.aim,c=Math.cos(a0),s=Math.sin(a0),rx=-s,ry=c,R=h.r,gh=R,K=FXK,q=hamSnd(h);
  h.fireCd=1/((W.spinup?6+(W.rate-6)*h.spin:W.rate)*(1+0.1*(L-1))*st.rate);if(W.dual)h.dualSide=-h.dualSide;if(h.tal.berserk&&h.hp<h.maxHp*0.4)h.fireCd/=1.3;
  const so=W.dual?h.dualSide*0.42:0.14,dmg=W.dmg*(1+0.2*(L-1))*st.dmg*(h.tal.berserk&&h.hp<h.maxHp*0.4?1.4:1),ln=(id==='sniper'||id==='lmg'||id==='ak47'||id==='amr'||id==='minigun')?2.6:(id==='smg'||id==='pistol'||id==='dual'||id==='revolver')?1.9:2.2,gx=h.x+c*R*ln+rx*R*so,gy=h.y+s*R*ln+ry*R*so,bx=h.x+c*R*0.8+rx*R*so,by=h.y+s*R*0.8+ry*R*so,tb=h.team==='blue'?'_b':'_r';
  if(W.mag&&!(h.tal.bottomless&&Math.random()<0.35))h.ammo--;
  if(W.kind==='bullet'){
    const n=(W.n||1)+st.multi+(id==='shotgun'?L-1:0),sp=(id==='shotgun'||id==='autoshot')?W.spread:W.spread+h.bloom+(n>1?0.07*(n-1):0),kind=(id==='sniper'||id==='amr')?'snipe':(id==='shotgun'||id==='autoshot')?'pel'+tb:'trc'+tb;
    for(let i=0;i<n;i++){const off=n===1?rand(-sp,sp):(i/(n-1)-0.5)*2*sp+rand(-0.03,0.03);bullets.push(mkBullet(kind,h,bx,by,gh,a0+off,W.spd*rand(0.95,1.05),dmg,W.range*st.rangeK,{eff:W.eff,minF:W.minF,pierce:(W.pierce||0)+(id==='sniper'||id==='amr'?L-1:0)+st.pierce,kb:W.kb,r:(id==='sniper'||id==='amr')?5:4.5,bounce:(W.bounce||0)+st.ric,wp:W.wallPierce||0}));}
    if(W.bloom)h.bloom=Math.min(W.bmax,h.bloom+W.bloom);
    gunFx(h,W,gx,gy,gh);GSFX.shot(W.snd,q.pan,q.vol);
    if(id==='shotgun'){GSFX.pump(q.pan,q.vol);h.vx-=c*120;h.vy-=s*120;}
    else if(id==='sniper'){GSFX.bolt(q.pan,q.vol);sniperTrail(gx,gy,gh,a0,W.range);h.vx-=c*70;h.vy-=s*70;}
    else if(id==='deagle'){h.vx-=c*60;h.vy-=s*60;}
    else if(id==='amr'){GSFX.bolt(q.pan,q.vol);sniperTrail(gx,gy,gh,a0,W.range);h.vx-=c*W.selfKb;h.vy-=s*W.selfKb;setWave(gx,gy,0.3,0.5,0.45);}
  }else if(W.kind==='rocket'){
    bullets.push(mkBullet('rocket',h,bx,by,gh,a0,W.spd,dmg,W.range*st.rangeK,{aoe:W.aoe*(1+0.15*(L-1)),aoeDmg:W.aoeDmg*(1+0.2*(L-1))*st.dmg,kb:W.kb,r:7}));
    gunFx(h,W,gx,gy,gh);GSFX.rocket(q.pan,q.vol);h.vx-=c*90;h.vy-=s*90;
    for(let i=0;i<fxn(6);i++)addP({type:'smoke',x:h.x-c*R*1.2,y:h.y-s*R*1.2,h:gh,vx:-c*rand(80,200)+rand(-30,30),vy:-s*rand(80,200)+rand(-30,30),vh:rand(5,30),life:rand(0.5,0.9),size:rand(10,16),grow:34,col:'#9a94ac'});
    addP({type:'flash',x:h.x-c*R*1.4,y:h.y-s*R*1.4,h:gh,life:0.06,size:16,col:'#ffd27a',dir:a0+Math.PI,cone:2.2,rot:rand(0,TAU)});
  }else if(W.kind==='lob'){
    let tx,ty;if(h.dev==='kbm'&&mouse.has&&h.view){tx=h.mwx;ty=h.mwy;}else{const t=h.ctl==='ai'?h.ai.target:autoAim(h,560);if(t){tx=t.x;ty=t.y;}else{tx=h.x+c*360;ty=h.y+s*360;}}
    const dx=tx-h.x,dy=ty-h.y,d=Math.hypot(dx,dy)||1,dd=clamp(d,90,W.range*st.rangeK);
    throwLob(h,'gnade',h.x+dx/d*dd,h.y+dy/d*dd,{sp:560,fuse:W.fuse,aoe:W.aoe*(1+0.15*(L-1)),dmg:W.aoeDmg*(1+0.2*(L-1))*st.dmg,kb:W.kb,impact:true});
    gunFx(h,W,gx,gy,gh);GSFX.shot('gl',q.pan,q.vol);
  }else if(W.kind==='melee'){
    h.swingT=0.22;h.swingDir=-h.swingDir;const reach=W.reach*(1+0.1*(L-1)),arc=W.arc;GSFX.swish(q.pan,q.vol);
    hashRange(h.x,h.y,reach+60,e=>{if(!canHit(h.team,e))return;const dx=e.x-h.x,dy=e.y-h.y,d=Math.hypot(dx,dy)-e.r;if(d>reach)return;if(Math.abs(angDiff(a0,Math.atan2(dy,dx)))>arc/2&&d>e.r*0.5)return;
      if(dealDmg(e,dmg,{team:h.team,owner:h,x:h.x,y:h.y})>0){knock(e,dx,dy,W.kb);onHitFx(e.x,e.y,e.r,'#e8f4ff',true);hitMark(h,e);}});
    let defl=false;for(const b of bullets){if(b.team===h.team||b.kind==='flame')continue;const dx=b.x-h.x,dy=b.y-h.y;if(dx*dx+dy*dy>(reach+12)*(reach+12))continue;if(Math.abs(angDiff(a0,Math.atan2(dy,dx)))>arc/2)continue;
      const sp=Math.hypot(b.vx,b.vy);b.vx=Math.cos(a0)*sp*1.1;b.vy=Math.sin(a0)*sp*1.1;b.team=h.team;b.owner=h;b.by=h;b.dmg*=1.2;b.hit=new Set();b.life=Math.max(b.life,0.8);if(b.kind==='orb'||b.kind==='rat'||b.kind.startsWith('mpea')||b.kind.startsWith('seed'))b.kind='trc'+tb;pop(b.x,b.y,30,'反弹！','#9fe8ff',13,0.5);sparks(b.x,b.y,b.h,'#9fe8ff',4);defl=true;}
    if(defl)GSFX.ting(q.pan,q.vol);
    slashFx(h,a0,reach,arc);shakeAt(h.x,h.y,0.08*K,h);kickV(h,a0,-4);h.kick.w-=20;
  }else{
    const range=W.range*(1+0.1*(L-1))*st.rangeK;
    for(let i=0;i<1+Math.floor(st.multi/2);i++)bullets.push(mkBullet('flame',h,gx,gy,gh,a0+rand(-W.spread,W.spread),W.spd*rand(0.85,1.1),dmg,range,{r:11,kb:W.kb}));
    if(Math.random()<0.3)flashL('flash',gx,gy,gh+10,1.2*K,0.08);GSFX.flame(q.pan,q.vol);
  }
  h.heat=Math.min(1,h.heat+0.08);
}
function knock(e,dx,dy,kb){if(!kb||e.kind==='base'||e.kind==='turret'||e.kind==='crate'||e.isProp||e.kind==='decoy'||(e.kind==='ham'&&(e.tal.giant||(e.weapon.id==='minigun'&&eL(e,'b')>=3&&G.t-e.lastShotT<0.3))))return;const l=Math.hypot(dx,dy)||1;if(e.kind==='ham'){e.vx+=dx/l*kb;e.vy+=dy/l*kb;}else{const m=e.kind==='boss'?0.15:1;e.kx+=dx/l*kb*m;e.ky+=dy/l*kb*m;}}
function startDash(h,inp){let dx=inp.mx,dy=inp.my;if(Math.hypot(dx,dy)<0.2){dx=Math.cos(h.aim);dy=Math.sin(h.aim);}const l=Math.hypot(dx,dy)||1;h.rdx=dx/l;h.rdy=dy/l;h.rollT=0.3;h.dashCd=h.st.dashCd;h.iframes=0.3;h.sq.v=0.75;h.sq.w=0;h.dashHit=new Set();SFX.roll();if(h.tal.phantom)h.invisT=1.5;
  for(let i=0;i<fxn(6);i++)addP({type:'smoke',x:h.x+rand(-8,8),y:h.y+rand(-6,6),h:4,vx:-h.rdx*rand(30,90)+rand(-30,30),vy:-h.rdy*rand(30,90)+rand(-30,30),vh:rand(10,30),life:rand(0.3,0.5),size:rand(9,14),grow:22,col:'#e9dfcc'});
  for(let i=0;i<fxn(5);i++)addP({type:'spark',x:h.x+rand(-12,12),y:h.y+rand(-12,12),h:rand(8,28),vx:-h.rdx*rand(320,520),vy:-h.rdy*rand(320,520),vh:0,life:rand(0.1,0.16),col:'#ffffff',size:1,grav:0});}
function burnTick(e,dt){if(e.burnT>0){e.burnT-=dt;e.burnAcc+=dt;if(Math.random()<0.45)addP({type:'fire',x:e.x+rand(-6,6),y:e.y+rand(-6,6),h:rand(e.r*0.4,e.r*1.6),vx:rand(-10,10),vy:rand(-10,10),vh:rand(30,70),life:rand(0.25,0.45),size:rand(7,11)});if(e.burnAcc>=0.35){e.burnAcc=0;dealDmg(e,2.6*(e.burnK||1),{team:e.burnBy?e.burnBy.team:'neutral',owner:e.burnBy,x:e.x,y:e.y},true);}}}
function updHam(h,dt){
  if(!h.alive){h.respawnT-=dt;if(h.respawnT<=0&&!G.over)respawn(h);return;}
  const st=h.st,inp=h.inp;
  h.fireCd-=dt;h.dashCd-=dt;h.iframes-=dt;h.hurtT=Math.max(0,h.hurtT-dt);h.flash=Math.max(0,h.flash-dt);h.heat=Math.max(0,h.heat-dt*1.8);h.munchT=Math.max(0,h.munchT-dt);h.spitT=Math.max(0,h.spitT-dt);h.swingT=Math.max(0,h.swingT-dt);h.slowT=Math.max(0,h.slowT-dt);h.pumpT=Math.max(0,h.pumpT-dt);h.flipT=Math.max(0,h.flipT-dt);h.boltT=Math.max(0,h.boltT-dt);h.gadget.cd=Math.max(0,h.gadget.cd-dt);h.blindT=Math.max(0,h.blindT-dt);
  if(h.crownT>0){h.crownT-=dt;if(h.crownT<=0)calcStats(h);}
  burnTick(h,dt);if(!h.alive)return;
  h.padCd=Math.max(0,h.padCd-dt);h.invisT=Math.max(0,h.invisT-dt);h.revealT=Math.max(0,h.revealT-dt);
  if(h.tal.squad){h.squadT-=dt;if(h.squadT<=0){h.squadT=20;spawnSquad(h);}}
  if(h.st.aura>0)for(const o of hams)if(o.alive&&o.team===h.team&&o.hp<o.maxHp&&Math.hypot(o.x-h.x,o.y-h.y)<220)o.hp=Math.min(o.maxHp,o.hp+h.st.aura*dt);
  if(evoTick(h,dt,inp))return;
  if(h.air){const A=h.air;A.t+=dt;const k=Math.min(1,A.t/A.dur);h.x=lerp(A.x0,A.x1,k);h.y=lerp(A.y0,A.y1,k);h.z=Math.sin(k*Math.PI)*A.hgt;h.moving=true;h.walk+=dt*8;h.aim=inp.aim;
    spring(h.vr,h.r,240,12,dt);spring(h.sq,1,260,11,dt);spring(h.kick,0,400,22,dt);
    const Wa=WEAPONS[h.weapon.id];if(inp.fire&&h.fireCd<=0&&h.reloadT<=0&&Wa.kind==='bullet'&&(!Wa.mag||h.ammo>0))fireWeapon(h);
    if(Math.random()<0.5)addP({type:'smoke',x:h.x,y:h.y,h:h.z,vx:rand(-20,20),vy:rand(-20,20),life:0.4,size:rand(6,9),grow:16,col:'#e9dfcc'});
    if(k>=1)land(h);return;}
  const ob=BASE_POS[h.team];let heal=st.regen;if(Math.hypot(h.x-ob.x,h.y-ob.y)<340)heal+=14;if(heal>0&&h.hp<h.maxHp)h.hp=Math.min(h.maxHp,h.hp+heal*dt);
  if(st.shield>0&&h.shield<st.shield){h.shieldT-=dt;if(h.shieldT<=0){h.shield++;h.shieldT=st.shieldCd;}}
  spring(h.vr,h.r,240,12,dt);spring(h.sq,1,260,11,dt);spring(h.puff,h.lvl>=30?1:h.xp/h.xpNext,160,9,dt);spring(h.kick,0,400,22,dt);
  if(inp.card>=0){if(h.choices)applyChoice(h,inp.card);inp.card=-1;}
  h.aim=inp.aim;
  if(inp.dash){if(h.dashCd<=0&&h.rollT<=0)startDash(h,inp);inp.dash=false;}
  const Wf=WEAPONS[h.weapon.id],spd=st.speed*(h.slowT>0?0.62:1)*moveMul(h,inp);
  if(h.rollT>0){h.rollT-=dt;const k=Math.max(0,h.rollT/0.3),rs=620*(h.dashSpd||1)*(0.5+0.5*k);h.vx=h.rdx*rs;h.vy=h.rdy*rs;h.rollA+=dt*24;
    if(st.dashDmg>0)hashRange(h.x,h.y,h.r+30,e=>{if(h.dashHit.has(e)||!canHit(h.team,e)||e.kind==='base'||e.kind==='turret')return;if(Math.hypot(e.x-h.x,e.y-h.y)<h.r+e.r+4){h.dashHit.add(e);dealDmg(e,st.dashDmg*st.dmg,{team:h.team,owner:h,x:h.x,y:h.y});knock(e,e.x-h.x,e.y-h.y,220);onHitFx(e.x,e.y,e.r,'#ffffff',false);}});}
  else{h.rollA=0;const acc=inp.ml>0.05?16:11;h.vx=damp(h.vx,inp.mx*spd,acc,dt);h.vy=damp(h.vy,inp.my*spd,acc,dt);}
  const ox=h.x,oy=h.y;h.x+=h.vx*dt;h.y+=h.vy*dt;resolveCircle(h,h.r);
  const moved=Math.hypot(h.x-ox,h.y-oy);h.moving=moved>0.35;h.walk+=moved*0.17;
  if(h.reloadT>0){h.reloadT-=dt;if(h.reloadT<=0){h.reloadT=0;h.ammo=magSize(h);}}
  if(inp.reload){inp.reload=false;if(Wf.mag&&h.ammo<magSize(h))startReload(h);}
  if(Wf.mag&&h.ammo<=0&&h.reloadT<=0)startReload(h);
  if(inp.gadget){inp.gadget=false;if(h.gadget.cd<=0&&h.rollT<=0)useGadget(h);}
  const canShoot=h.rollT<=0&&h.reloadT<=0&&(!Wf.mag||h.ammo>0);
  if(Wf.spinup){if(inp.fire&&h.reloadT<=0){if(h.spin===0){const q=hamSnd(h);GSFX.spin(q.pan,q.vol);}h.spin=Math.min(1,h.spin+dt/(Wf.spinup*spinMul(h)));}else if(!(eL(h,'a')>=9&&G.t-h.lastShotT<3))h.spin=Math.max(0,h.spin-dt/0.9);h.spinA+=h.spin*dt*40;}
  if(Wf.kind==='rail'){
    if(inp.fire&&canShoot){if(h.charge===0){const q=hamSnd(h);GSFX.charge(q.pan,q.vol);}h.charge=Math.min(1,h.charge+dt/(Wf.charge*railChargeMul(h)));if(h.charge>=1)h.chHold+=dt;if(Math.random()<0.6)chargeFx(h);if(h.chHold>0.45)fireRail(h);}
    else if(h.charge>0){if(h.charge>0.15&&canShoot)fireRail(h);else{h.charge=0;h.chHold=0;}}
  }else if(Wf.kind==='laser'){if(inp.fire&&canShoot){h.beamT-=dt;if(h.beamT<=0){h.beamT=0.1;laserTick(h);}}else{h.beam=null;h.beams=null;}}
  else tryFire(h,inp,canShoot,dt);
  h.bloom=Math.max(0,h.bloom-dt*(inp.fire?0.05:0.35));
}

// ---------- AI 仓鼠 ----------
function aimAt(h,t,lead){let tx=t.x,ty=t.y;if(lead&&(t.vx||t.vy)){const d=Math.hypot(tx-h.x,ty-h.y),sp=WEAPONS[h.weapon.id].spd||900,tt=d/sp;tx+=(t.vx||0)*tt*0.7;ty+=(t.vy||0)*tt*0.7;}h.inp.aim=Math.atan2(ty-h.y,tx-h.x)+rand(-0.05,0.05);}
function aiTarget(h){
  let best=null,bs=1e9;const consider=(e,w,maxD)=>{const d=Math.hypot(e.x-h.x,e.y-h.y)-e.r;if(d>maxD)return;if(d*w<bs){bs=d*w;best=e;}};
  const VV=VIS[h.team],sv=e=>VV.has(e)||Math.hypot(e.x-h.x,e.y-h.y)<90;
  for(const e of hams)if(e.alive&&e.team!==h.team&&sv(e))consider(e,0.7,560);
  for(const e of decoys)if(!e.dead&&e.team!==h.team&&sv(e))consider(e,0.55,560);
  for(const e of minions)if(!e.dead&&e.team!==h.team&&sv(e))consider(e,1.0,440);
  for(const e of mobs)if(!e.dead&&(e.target===h||(h.ai.state==='jungle'&&sv(e))))consider(e,0.9,430);
  for(const s of structs)if(!s.dead&&s.team!==h.team&&!(s.kind==='base'&&s.shielded)){const allies=minions.some(m=>!m.dead&&m.team===h.team&&Math.hypot(m.x-s.x,m.y-s.y)<s.range);if(allies||s.kind==='sentry'||s.hp<s.maxHp*0.35)consider(s,1.1,s.range+60);}
  for(const c of crates)if(!c.dead)consider(c,2.4,230);
  if(best&&(!hasLOS(h.x,h.y,best.x,best.y)||(smokes.length&&smokeBlocks(h.x,h.y,best.x,best.y))))return null;
  return best;}
function aiPick(h){let bi=0,bw=-1;h.choices.forEach((c,i)=>{const w=(c.t==='wlvl'?3:c.t==='abil'?2:c.t==='glvl'?1.8:c.t==='pet'?1.6:1)+Math.random()*1.5;if(w>bw){bw=w;bi=i;}});return bi;}
function aiThink(h,dt){
  const ai=h.ai,inp=h.inp;inp.fire=false;inp.dash=false;inp.reload=false;inp.gadget=false;inp.card=-1;inp.mx=0;inp.my=0;inp.ml=0;
  if(!h.alive)return;
  if(h.blindT>0){inp.mx=Math.cos(time*3+h.id);inp.my=Math.sin(time*2.3+h.id);inp.ml=1;return;}
  if(h.choices){ai.cardT+=dt;if(ai.cardT>0.9){ai.cardT=0;inp.card=aiPick(h);}}
  ai.retarget-=dt;if(ai.retarget<=0){ai.retarget=0.25+Math.random()*0.2;ai.target=aiTarget(h);}
  const t=ai.target&&!ai.target.dead&&(ai.target.kind!=='ham'||ai.target.alive)?ai.target:null;
  const W=WEAPONS[h.weapon.id],range=W.kind==='melee'?W.reach*0.85:W.kind==='flame'?W.range*0.8:Math.min((W.range||560)*h.st.rangeK*Math.max(0.45,W.eff||1)*0.95,560);
  const low=h.hp<h.maxHp*0.3;let gx=null,gy=null,fight=false;
  if(low)ai.state='retreat';
  if(ai.state==='retreat'&&h.hp>h.maxHp*0.85)ai.state='push';
  if(t&&!(ai.state==='retreat'&&t.kind!=='ham')){fight=true;const dx=t.x-h.x,dy=t.y-h.y,d=Math.hypot(dx,dy)||1;aimAt(h,t,true);
    if(d<range+t.r)inp.fire=true;
    if(ai.state==='retreat'){const b=BASE_POS[h.team];gx=b.x;gy=b.y;}
    else{const want=W.kind==='melee'?t.r+18:(t.kind==='base'||t.kind==='turret')?range*0.85:range*0.62;
      ai.strafeT-=dt;if(ai.strafeT<=0){ai.strafeT=rand(0.8,1.8);ai.strafe=Math.random()<0.5?-1:1;}
      const ux=dx/d,uy=dy/d,rad=clamp((d-want)/120,-1,1),sw=t.kind==='ham'?0.8:0.3;inp.mx=ux*rad-uy*ai.strafe*sw;inp.my=uy*rad+ux*ai.strafe*sw;}
    ai.dashT-=dt;if(t.kind==='ham'&&ai.dashT<=0&&(h.hurtT>0||Math.random()<0.02)){inp.dash=true;ai.dashT=rand(1.5,3.5);}
  }else{
    if(ai.inv){ai.inv.t-=dt;if(ai.inv.t<=0||Math.hypot(ai.inv.x-h.x,ai.inv.y-h.y)<80)ai.inv=null;}
    ai.jT-=dt;
    if(ai.state==='push'&&ai.jT<=0&&h.lvl<9){ai.jT=rand(25,45);const own=camps.filter(c=>c.alive>0&&(h.team==='blue'?c.x<MIDX:c.x>MIDX));if(own.length){ai.camp=own[(Math.random()*own.length)|0];ai.state='jungle';}}
    if(ai.state==='jungle'){if(!ai.camp||ai.camp.alive<=0)ai.state='push';else{gx=ai.camp.x;gy=ai.camp.y;}}
    if(ai.state==='retreat'){const b=BASE_POS[h.team];gx=b.x;gy=b.y;}
    if(ai.state==='push'){const path=lanePath(h.team,ai.lane),wp=path[Math.min(ai.wp,path.length-1)];gx=wp[0];gy=wp[1];if(Math.hypot(gx-h.x,gy-h.y)<130&&ai.wp<path.length-1)ai.wp++;}
    if(ai.inv&&ai.state!=='retreat'){gx=ai.inv.x;gy=ai.inv.y;}
  }
  if(gx!==null){const F=hasLOS(h.x,h.y,gx,gy)?null:fieldTo(gx,gy),f=fieldDir(F,h.x,h.y,gx,gy);inp.mx=f.x;inp.my=f.y;if(!fight)inp.aim=Math.atan2(f.y,f.x);}
  else if(fight&&t&&!hasLOS(h.x,h.y,t.x,t.y)){const f=fieldDir(fieldTo(t.x,t.y),h.x,h.y,t.x,t.y);inp.mx=f.x;inp.my=f.y;inp.fire=false;}
  if(h.gadget.cd<=0&&Math.random()<dt*0.9&&aiWantGadget(h,t))inp.gadget=true;
  if(!t&&WEAPONS[h.weapon.id].mag&&h.reloadT<=0&&h.ammo<magSize(h)*0.5)inp.reload=true;
  inp.ml=Math.hypot(inp.mx,inp.my);if(inp.ml>1){inp.mx/=inp.ml;inp.my/=inp.ml;inp.ml=1;}
  ai.stuckT=(Math.hypot(h.x-ai.px,h.y-ai.py)<0.6&&inp.ml>0.5)?ai.stuckT+dt:0;ai.px=h.x;ai.py=h.y;if(ai.stuckT>0.8){inp.dash=true;ai.stuckT=0;}
}

// ---------- 宠物 ----------
function mkPet(type,owner){return{kind:'pet',type,owner,team:owner.team,x:owner.x,y:owner.y,h:type==='firefly'?34:0,lvl:1,cd:rand(0.3,1),t:rand(0,5),target:null,vx:0,vy:0,aim:0,dead:false};}
function updPet(p,dt){
  const o=p.owner;p.t+=dt;p.cd-=dt;if(!hams.includes(o)){p.dead=true;return;}
  const ax=o.alive?o.x:BASE_POS[o.team].x,ay=o.alive?o.y:BASE_POS[o.team].y;
  if(p.type==='firefly'){const a=p.t*2.2;p.x=damp(p.x,ax+Math.cos(a)*46,10,dt);p.y=damp(p.y,ay+Math.sin(a)*46,10,dt);p.h=34+Math.sin(p.t*5)*6;
    if(p.cd<=0&&o.alive){const e=nearestFoe(p.team,p.x,p.y,210);if(e){p.cd=Math.max(0.35,0.85-0.12*p.lvl);dealDmg(e,(5+3*p.lvl)*o.st.dmg,{team:p.team,owner:o,x:p.x,y:p.y});zaps.push({x0:p.x,y0:p.y,h0:p.h,x1:e.x,y1:e.y,h1:e.r,t:0,life:0.14});SFX.ric();}}return;}
  if(p.type==='chick'){
    if(p.target&&(p.target.dead||(p.target.kind==='ham'&&!p.target.alive)||Math.hypot(p.target.x-ax,p.target.y-ay)>330))p.target=null;
    if(!p.target&&o.alive&&p.cd<=0)p.target=nearestFoe(p.team,ax,ay,260);
    let tx,ty;if(p.target){tx=p.target.x;ty=p.target.y;}else{const a=o.aim;tx=ax-Math.cos(a)*30-Math.sin(a)*22;ty=ay-Math.sin(a)*30+Math.cos(a)*22;}
    const dx=tx-p.x,dy=ty-p.y,d=Math.hypot(dx,dy)||1,sp=p.target?330:Math.min(320,d*6);p.vx=dx/d*sp;p.vy=dy/d*sp;p.x+=p.vx*dt;p.y+=p.vy*dt;if(d>2)p.aim=Math.atan2(dy,dx);
    if(p.target&&d<p.target.r+12&&p.cd<=0){p.cd=0.55;dealDmg(p.target,(6+4*p.lvl)*o.st.dmg,{team:p.team,owner:o,x:p.x,y:p.y});sparks(p.target.x,p.target.y,14,'#fff2a0',3);SFX.bite();}
  }else{
    const a=o.aim,tx=ax-Math.cos(a)*34+Math.sin(a)*20,ty=ay-Math.sin(a)*34-Math.cos(a)*20;p.x=damp(p.x,tx,6,dt);p.y=damp(p.y,ty,6,dt);
    if(p.cd<=0&&o.alive){const e=nearestFoe(p.team,p.x,p.y,380);if(e){p.cd=Math.max(0.6,1.3-0.15*p.lvl);const base=Math.atan2(e.y-p.y,e.x-p.x);p.aim=base;for(let k=-1;k<=1;k++){const b=mkBullet('spike',p,p.x,p.y,10,base+k*0.18,600,(5+3*p.lvl)*o.st.dmg,420,{r:4,kb:40});b.owner=o;bullets.push(b);}}}
  }
}

// ---------- 小兵 ----------
function spawnWave(){for(const team of TEAMS)for(const lane of ['top','mid','bot'])for(let i=0;i<3;i++)G.spawnQ.push({team,lane,t:G.t+i*0.7});G.spawnQ.sort((a,b)=>a.t-b.t);}
function mkMinion(team,lane){const path=lanePath(team,lane),p=path[0];return{kind:'minion',id:UID++,team,lane,path,wp:1,x:p[0]+rand(-24,24),y:p[1]+rand(-24,24),vx:0,vy:0,kx:0,ky:0,r:12,hp:70*G.minMul,maxHp:70*G.minMul,cd:rand(0.3,1.1),dmg:6*G.minMul,target:null,tT:0,walk:0,aim:team==='blue'?0:Math.PI,flash:0,dead:false,slowT:0,burnT:0,burnAcc:0,burnBy:null};}
function minionTarget(m){let best=null,bs=1e9;hashRange(m.x,m.y,320,e=>{if(!canHit(m.team,e)||e.team==='neutral'||(e.kind==='base'&&e.shielded))return;const d=Math.hypot(e.x-m.x,e.y-m.y)-e.r;if(d>300)return;const w=e.kind==='minion'?1:e.kind==='ham'?1.3:1.6;if(d*w<bs){bs=d*w;best=e;}});return best;}
function updMinion(m,dt){
  m.flash=Math.max(0,m.flash-dt);m.slowT=Math.max(0,m.slowT-dt);m.revealT=Math.max(0,(m.revealT||0)-dt);burnTick(m,dt);if(m.dead)return;
  if(m.stun>0){m.stun-=dt;m.vx*=0.85;m.vy*=0.85;return;}
  m.kx=damp(m.kx,0,9,dt);m.ky=damp(m.ky,0,9,dt);m.cd-=dt;m.tT-=dt;
  if(m.tT<=0){m.tT=0.3+Math.random()*0.1;m.target=minionTarget(m);}
  const t=m.target&&!m.target.dead&&(m.target.kind!=='ham'||m.target.alive)?m.target:null,sp=95*(m.slowT>0?0.6:1);let mx=0,my=0;
  if(t){const dx=t.x-m.x,dy=t.y-m.y,d=Math.hypot(dx,dy)||1;m.aim=Math.atan2(dy,dx);if(d>230+t.r){mx=dx/d;my=dy/d;}else if(m.cd<=0){m.cd=rand(0.9,1.2);const a=m.aim+rand(-0.06,0.06);bullets.push(mkBullet(m.team==='blue'?'mpea_b':'mpea_r',m,m.x+Math.cos(a)*14,m.y+Math.sin(a)*14,11,a,520,m.dmg,320,{r:4,kb:20}));mobSnd(m,'minion');m.revealT=0.4;noise(m.x,m.y,'gun',0.35,m);}}
  else{const wp=m.path[Math.min(m.wp,m.path.length-1)],dx=wp[0]-m.x,dy=wp[1]-m.y,d=Math.hypot(dx,dy)||1;if(d<70&&m.wp<m.path.length-1)m.wp++;mx=dx/d;my=dy/d;m.aim=Math.atan2(dy,dx);}
  m.vx=damp(m.vx,mx*sp,6,dt);m.vy=damp(m.vy,my*sp,6,dt);const ox=m.x,oy=m.y;m.x+=(m.vx+m.kx)*dt;m.y+=(m.vy+m.ky)*dt;resolveCircle(m,m.r);m.walk+=Math.hypot(m.x-ox,m.y-oy)*0.2;
}

// ---------- 野怪 ----------
function mkMob(type,camp,x,y){const T=MOB[type];return{kind:type,id:UID++,team:'neutral',camp,x,y,hx:x,hy:y,vx:0,vy:0,kx:0,ky:0,r:T.r,hp:T.hp,maxHp:T.hp,spd:T.spd,target:null,aim:rand(0,TAU),heading:rand(0,TAU),t:rand(0,5),ph:rand(0,TAU),wt:0,tx:x,ty:y,cd:rand(0.6,1.4),tele:0,burst:0,bt:0,flash:0,stun:0,slowT:0,burnT:0,burnAcc:0,burnBy:null,dead:false,walk:0,recoil:0,leash:type==='boss'?700:520,returning:false,ringT:4,sumT:9,losT:0,st:0,sdir:1,bcd:0,rig:null};}
function spawnCamp(c){const n=c.type==='roach'?6:3;for(let i=0;i<n;i++)mobs.push(mkMob(c.type,c,c.x+rand(-40,40),c.y+rand(-40,40)));c.alive=n;c.resp=1e9;}
function aggro(e,o){if(e.dead||!o||(o.kind!=='ham'&&o.kind!=='minion'))return;const grp=e.camp?mobs.filter(m=>m.camp===e.camp&&!m.dead):[e];for(const m of grp)if(!m.target){m.target=o;m.returning=false;}}
function mobShoot(e,a,kind,spd,dmg,r){e.revealT=0.4;if(Math.random()<0.5)noise(e.x,e.y,'monster',e.kind==='boss'?1.3:0.8,e);bullets.push(mkBullet(kind,e,e.x+Math.cos(a)*e.r,e.y+Math.sin(a)*e.r,e.r*0.95,a,spd,dmg,700,{r,kb:30}));}
function updMob(e,dt){
  e.t+=dt;e.flash=Math.max(0,e.flash-dt);e.slowT=Math.max(0,e.slowT-dt);e.revealT=Math.max(0,(e.revealT||0)-dt);e.recoil=Math.max(0,e.recoil-dt*8);burnTick(e,dt);if(e.dead)return;
  e.kx=damp(e.kx,0,9,dt);e.ky=damp(e.ky,0,9,dt);let t=e.target;
  if(t&&(t.dead||(t.kind==='ham'&&!t.alive)||Math.hypot(e.x-e.hx,e.y-e.hy)>e.leash||Math.hypot(t.x-e.x,t.y-e.y)>760)){e.target=t=null;e.returning=true;e.tele=0;e.burst=0;}
  if(!t&&!e.returning){e.losT-=dt;if(e.losT<=0){e.losT=0.3;const R=e.kind==='roach'?190:e.kind==='rat'?260:320;let f=null;hashRange(e.x,e.y,R,c=>{if(f)return;if(((c.kind==='ham'&&c.alive)||c.kind==='minion')&&Math.hypot(c.x-e.x,c.y-e.y)<R&&hasLOS(e.x,e.y,c.x,c.y))f=c;});if(f){aggro(e,f);t=e.target;}}}
  const sp=e.spd*(e.slowT>0?0.6:1);
  if(e.stun>0){e.stun-=dt;e.vx=damp(e.vx,0,8,dt);e.vy=damp(e.vy,0,8,dt);}
  else if(e.returning){const dx=e.hx-e.x,dy=e.hy-e.y,d=Math.hypot(dx,dy);if(d<30)e.returning=false;else{e.vx=damp(e.vx,dx/d*sp*1.2,6,dt);e.vy=damp(e.vy,dy/d*sp*1.2,6,dt);}e.hp=Math.min(e.maxHp,e.hp+e.maxHp*0.3*dt);}
  else if(!t){e.wt-=dt;if(e.wt<=0){e.wt=rand(1,2.6);const a=rand(0,TAU),rr=rand(0,e.kind==='roach'?50:110);e.tx=e.hx+Math.cos(a)*rr;e.ty=e.hy+Math.sin(a)*rr;}const tx=e.tx-e.x,ty=e.ty-e.y,tl=Math.hypot(tx,ty);if(tl>8){e.vx=damp(e.vx,tx/tl*sp*0.4,6,dt);e.vy=damp(e.vy,ty/tl*sp*0.4,6,dt);e.aim=Math.atan2(ty,tx);}else{e.vx=damp(e.vx,0,8,dt);e.vy=damp(e.vy,0,8,dt);}}
  else{const dx=t.x-e.x,dy=t.y-e.y,d=Math.hypot(dx,dy)||1,ta=Math.atan2(dy,dx),los=hasLOS(e.x,e.y,t.x,t.y);
    if(e.kind==='roach'){let mx,my;if(los){mx=dx/d;my=dy/d;}else{const f=fieldDir(fieldTo(t.x,t.y),e.x,e.y,t.x,t.y);mx=f.x;my=f.y;}const z=Math.sin(e.t*10+e.ph)*0.5;const px=-my,py=mx;mx+=px*z;my+=py*z;const ml=Math.hypot(mx,my)||1;e.vx=damp(e.vx,mx/ml*sp,9,dt);e.vy=damp(e.vy,my/ml*sp,9,dt);e.bcd-=dt;if(d<e.r+t.r+5&&e.bcd<=0){e.bcd=0.8;SFX.bite();dealDmg(t,5,{team:'neutral',owner:null,x:e.x,y:e.y});knock(t,dx,dy,140);}}
    else if(e.kind==='rat'){
      if(e.tele>0||e.burst>0){e.vx=damp(e.vx,0,10,dt);e.vy=damp(e.vy,0,10,dt);if(e.tele>0){e.aim=turnTo(e.aim,ta,2.4*dt);e.tele-=dt;if(e.tele<=0){e.burst=3;e.bt=0;}}else{e.bt-=dt;if(e.bt<=0){mobShoot(e,e.aim+rand(-0.06,0.06),'rat',430,7,5);mobSnd(e,'rat');e.recoil=1;e.burst--;e.bt=0.1;if(e.burst<=0)e.cd=rand(1.2,2);flashL('eflash',e.x+Math.cos(e.aim)*e.r*2,e.y+Math.sin(e.aim)*e.r*2,e.r+10,1.5,0.07);}}}
      else{e.cd-=dt;if(los&&d<470){e.st-=dt;if(e.st<=0){e.st=rand(0.9,1.9);e.sdir=Math.random()<0.5?-1:1;}const ux=dx/d,uy=dy/d,rad=clamp((d-250)/120,-1,1),mx=ux*rad-uy*e.sdir*0.75,my=uy*rad+ux*e.sdir*0.75,ml=Math.hypot(mx,my)||1;e.vx=damp(e.vx,mx/ml*sp,6,dt);e.vy=damp(e.vy,my/ml*sp,6,dt);e.aim=turnTo(e.aim,ta,6*dt);if(e.cd<=0){e.tele=0.45;e.cd=99;}}
        else{const f=fieldDir(fieldTo(t.x,t.y),e.x,e.y,t.x,t.y);e.vx=damp(e.vx,f.x*sp,6,dt);e.vy=damp(e.vy,f.y*sp,6,dt);e.aim=turnTo(e.aim,Math.atan2(f.y,f.x),6*dt);}}}
    else{e.aim=turnTo(e.aim,ta,3*dt);const want=260,rad=clamp((d-want)/150,-1,1);e.vx=damp(e.vx,dx/d*rad*sp,4,dt);e.vy=damp(e.vy,dy/d*rad*sp,4,dt);
      e.cd-=dt;e.ringT-=dt;e.sumT-=dt;
      if(e.cd<=0&&los){e.cd=1.8;for(let k=-2;k<=2;k++)mobShoot(e,ta+k*0.16,'orb',430,9,7);mobSnd(e,'rat');e.recoil=1;flashL('eflash',e.x,e.y,60,2,0.1);}
      if(e.ringT<=0){e.ringT=5.2;for(let k=0;k<18;k++)mobShoot(e,k/18*TAU+e.t,'orb',300,8,7);ring(e.x,e.y,4,e.r,300,0.35,'#ff7fd0');SFX.thud();shakeAt(e.x,e.y,0.2);}
      if(e.sumT<=0){e.sumT=11;const n=mobs.filter(m=>m.summoned&&!m.dead).length;for(let k=0;k<2&&n+k<4;k++){const m=mkMob('rat',null,e.x+rand(-60,60),e.y+rand(-60,60));m.hx=e.hx;m.hy=e.hy;m.summoned=true;m.target=t;mobs.push(m);ring(m.x,m.y,3,8,140,0.3,'#c9cbd4');}}}}
  e.x+=(e.vx+e.kx)*dt;e.y+=(e.vy+e.ky)*dt;resolveCircle(e,e.r);
  if(e.kind!=='roach')e.walk+=Math.hypot(e.vx,e.vy)*dt*0.17;
  if(Math.hypot(e.vx,e.vy)>8)e.heading=turnTo(e.heading,Math.atan2(e.vy,e.vx),12*dt);
}

// ---------- 建筑 ----------
function mkStruct(kind,team,x,y){const B=kind==='base';return{kind,id:UID++,team,x,y,r:B?110:34,hp:B?5200:1700,maxHp:B?5200:1700,cd:rand(0.5,1),range:B?560:480,dmg:B?40:30,aim:team==='blue'?0:Math.PI,target:null,tT:0,flash:0,dead:false,shielded:B,alt:0};}
function structTarget(s){let best=null,bs=1e9;hashRange(s.x,s.y,s.range,e=>{if(e.team===s.team||e.team==='neutral'||e.kind==='base'||e.kind==='turret')return;if(e.kind==='ham'&&!e.alive)return;const d=Math.hypot(e.x-s.x,e.y-s.y)-e.r;if(d>s.range)return;let w=d;if(e.kind==='ham')w*=e.aggroT>G.t?0.3:1.6;if(w<bs){bs=w;best=e;}});return best;}
function updStruct(s,dt){
  if(s.dead)return;s.flash=Math.max(0,s.flash-dt);s.cd-=dt;s.tT-=dt;
  if(s.kind==='sentry'){s.life-=dt;if(s.life<=0){s.dead=true;smallDeath(s,TCOL[s.team],8);return;}}
  if(s.kind==='base')s.shielded=structs.filter(t=>t.kind==='turret'&&t.team===s.team&&!t.dead).length>=3;
  if(s.tT<=0){s.tT=0.25;s.target=structTarget(s);}
  const t=s.target&&!s.target.dead&&(s.target.kind!=='ham'||s.target.alive)?s.target:null;
  if(s.kind==='sentry'){if(t){const a=Math.atan2(t.y-s.y,t.x-s.x);s.aim=turnTo(s.aim,a,10*dt);if(s.cd<=0&&Math.abs(angDiff(s.aim,a))<0.25){s.cd=0.22;const gx=s.x+Math.cos(s.aim)*20,gy=s.y+Math.sin(s.aim)*20,b=mkBullet(s.team==='blue'?'trc_b':'trc_r',s,gx,gy,24,s.aim+rand(-0.05,0.05),1100,s.dmg,s.range+60,{r:4,kb:30});b.owner=s.owner;bullets.push(b);noise(s.x,s.y,'gun',0.5,s);addP({type:'flash',x:gx,y:gy,h:24,life:0.04,size:9,col:'#fff6c2',dir:s.aim,rot:rand(0,TAU)});mobSnd(s,'sentry');}}return;}
  if(t){const a=Math.atan2(t.y-s.y,t.x-s.x);s.aim=turnTo(s.aim,a,6*dt);if(s.cd<=0&&Math.abs(angDiff(s.aim,a))<0.3){s.cd=s.kind==='base'?0.8:1;s.alt^=1;const off=s.kind==='base'?(s.alt?15:-15):0,gh=s.kind==='base'?96:60,gx=s.x+Math.cos(s.aim)*s.r*0.9-Math.sin(s.aim)*off,gy=s.y+Math.sin(s.aim)*s.r*0.9+Math.cos(s.aim)*off;
    bullets.push(mkBullet(s.team==='blue'?'seed_b':'seed_r',s,gx,gy,gh,a,720,s.dmg,s.range+80,{r:8,kb:120}));addP({type:'flash',x:gx,y:gy,h:gh,life:0.06,size:16,col:TCOL[s.team],dir:s.aim,rot:rand(0,TAU)});mobSnd(s,'turret');}}
}

// ---------- 箱子、经验、拾取 ----------
function mkCrate(spot){return{kind:'crate',id:UID++,team:'neutral',x:spot.x,y:spot.y,r:spot.big?32:22,hp:spot.big?170:42,maxHp:spot.big?170:42,flash:0,dead:false,spot,big:spot.big};}
function dropGem(x,y,xp){if(gems.length>280)return;const a=rand(0,TAU),s=rand(60,180);gems.push({x,y,z:12,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vz:rand(160,280),xp,t:0,ph:rand(0,TAU),big:xp>=9});}
function mkPickup(type,x,y){const a=rand(0,TAU);return{type,x,y,z:14,vx:Math.cos(a)*90,vy:Math.sin(a)*90,vz:220,t:0,ph:rand(0,TAU)};}
function itemPhys(g,dt){if(g.vx||g.vy){g.x+=g.vx*dt;g.y+=g.vy*dt;const f=Math.exp(-(g.z>0?1.2:7)*dt);g.vx*=f;g.vy*=f;if(g.z<=0&&Math.abs(g.vx)<4&&Math.abs(g.vy)<4){g.vx=0;g.vy=0;}if(resolveCircle(g,6)){g.vx*=-0.4;g.vy*=-0.4;}}if(g.z>0||g.vz){g.vz-=1100*dt;g.z+=g.vz*dt;if(g.z<=0){g.z=0;g.vz=g.vz<-120?-g.vz*0.35:0;}}}
function updGems(dt){
  for(let i=gems.length-1;i>=0;i--){const g=gems[i];g.t+=dt;itemPhys(g,dt);
    if(g.t>0.35){let best=null,bd=1e9;for(const h of hams){if(!h.alive)continue;const d=Math.hypot(h.x-g.x,h.y-g.y);if(d<h.st.magnet&&d<bd){bd=d;best=h;}}
      if(best){const d=bd||1,sp=420+(1-d/best.st.magnet)*520;g.x+=(best.x-g.x)/d*sp*dt;g.y+=(best.y-g.y)/d*sp*dt;if(d<best.r+8){gems.splice(i,1);giveXP(best,g.xp);best.munchT=0.25;best.puff.w+=5;SFX.munch(clamp(best.puff.v,0,1));continue;}}}
    if(g.t>50)gems.splice(i,1);}
  for(let i=pickups.length-1;i>=0;i--){const p=pickups[i];p.t+=dt;itemPhys(p,dt);if(p.t<0.4)continue;
    for(const h of hams){if(!h.alive||Math.hypot(h.x-p.x,h.y-p.y)>h.r+14)continue;pickups.splice(i,1);h.hp=Math.min(h.maxHp,h.hp+35);pop(h.x,h.y,h.r*2.8,'+35','#8de0a6',16,0.7);SFX.munch(0.5);ring(h.x,h.y,3,h.r,120,0.3,'#8de0a6');break;}
    if(p.t>60&&pickups[i]===p)pickups.splice(i,1);}
}

// ---------- 伤害 ----------
function dealDmg(t,dmg,src,quiet){
  if(t.dead||(t.kind==='ham'&&!t.alive))return 0;
  if(t.isProp){propHit(t,dmg,src.owner);return dmg;}
  if(t.kind==='ham'){if(t.iframes>0)return 0;if(t.eshieldT>0&&t.eshield>0){const ab=Math.min(t.eshield,dmg);t.eshield-=ab;dmg-=ab;if(Math.random()<0.4)ring(t.x,t.y,t.r,t.r*1.5,60,0.2,'#7fe3ff');if(dmg<=0.01)return 0;}if(t.shield>0){t.shield--;t.shieldT=8;ring(t.x,t.y,t.r*1.2,6,120,0.25,'#9fe8ff');pop(t.x,t.y,t.r*2.6,'护盾','#9fe8ff',13,0.5);SFX.ric();return 0;}}
  if(t.kind==='base'&&t.shielded){if(Math.random()<0.3)sparks(src.x||t.x,src.y||t.y,60,'#9fe8ff',2);t.shieldHit=0.15;return 0;}
  if((t.kind==='base'||t.kind==='turret')&&G.sudden)dmg*=2;
  const o=src.owner;let crit=false;
  if(o&&o.kind==='ham'){if(t.kind==='base'||t.kind==='turret'||t.kind==='sentry')dmg*=o.st.demo;else if(t.team==='neutral'&&t.kind!=='crate')dmg*=o.st.hunter;if(quiet&&o.tal.berserk&&o.hp<o.maxHp*0.4)dmg*=1.4;}
  {const cc=o&&o.kind==='ham'?o.st.crit+(src.critAdd||0):0;if(o&&o.kind==='ham'&&!quiet&&(src.forceCrit||(cc>0&&Math.random()<cc))){dmg*=o.st.critDmg;crit=true;}}
  if(t.suppT>G.t)dmg*=1.2;if(o&&o.kind==='ham')dmg*=o.bannerK||1;
  if(t.kind==='ham'){if(t.weapon.id==='minigun'&&G.t-t.lastShotT<0.3){const mb=eL(t,'b');dmg*=mb>=9?0.75:mb>=6?0.9:1;}if(o&&o.kind==='ham')dmg=Math.min(dmg,t.maxHp*0.55);}
  if(t.kind==='ham'){dmg*=1-t.st.armor;if(t.hp-dmg<=0&&t.tal.undying&&!t.undyUsed){t.undyUsed=true;t.hp=t.maxHp*0.4;t.iframes=2;ring(t.x,t.y,3,t.r,240,0.45,'#ffd166');pop(t.x,t.y,t.r*3,'不死！','#ffd166',18,1);toastH(t,'不死鼠发动！','#ffd166',1.6);return 0;}}
  t.hp-=dmg;t.flash=0.09;
  if(t.kind==='ham'){t.hurtT=0.3;if(o&&o.kind==='ham')o.aggroT=G.t+2.5;SFX.hurt();shakeAt(t.x,t.y,0.2,t);if(t.view)t.view.pulse=1;}
  if(o&&o.kind==='ham'){o.dmgDealt+=dmg;if(t.kind==='base'||t.kind==='turret')o.bdmg+=dmg;if(o.st.vamp>0&&o.alive)o.hp=Math.min(o.maxHp,o.hp+dmg*o.st.vamp);}
  if(t.team==='neutral'&&t.kind!=='crate'){const att=o||(src.by&&src.by.kind==='minion'?src.by:null);if(att)aggro(t,att);}
  if(!quiet||crit)pop(t.x+rand(-8,8),t.y+rand(-6,6),t.r*2.2+12,(crit?'暴击 ':'')+Math.round(dmg),crit?'#ffd166':t.kind==='ham'?'#ff8a8a':'#ffffff',crit?17:13,0.55);
  if(t.hp<=0)killEnt(t,src);
  return dmg;
}
function xpNear(o,t,n){if(o&&o.kind==='ham'){giveXP(o,n);for(const h of hams)if(h!==o&&h.alive&&h.team===o.team&&Math.hypot(h.x-t.x,h.y-t.y)<600)giveXP(h,Math.round(n*0.4));}
  else{const team=o?o.team:null;for(const h of hams)if(h.alive&&(!team||h.team===team)&&Math.hypot(h.x-t.x,h.y-t.y)<650)giveXP(h,Math.round(n*0.5));}}
function killEnt(t,src){
  onKill(t,src);
  const o=src.owner||src.by||null;
  {const K=src.owner&&src.owner.kind==='ham'?src.owner:null;if(K&&K.alive&&t.kind!=='crate'&&t.team!==K.team){if(K.tal.vampire)K.hp=Math.min(K.maxHp,K.hp+25);if(K.st.scav>0&&WEAPONS[K.weapon.id].mag){const m=magSize(K);K.ammo=Math.min(m,K.ammo+Math.ceil(m*K.st.scav));}if(K.tal.detonate&&(t.kind==='ham'||t.kind==='minion'||t.kind==='roach'||t.kind==='rat'))detQ.push({x:t.x,y:t.y,team:K.team,owner:K,t:0.08});}}
  switch(t.kind){
    case'ham':{t.alive=false;t.hp=0;t.deaths++;t.respawnT=Math.min(14,4+t.lvl*0.6);const killer=src.owner&&src.owner.kind==='ham'?src.owner:null;
      if(killer){killer.kills++;giveXP(killer,22+t.lvl*6);addFeed(`${killer.name} 击败了 ${t.name}`,TCOL[killer.team]);toastH(killer,`击败 ${t.name}！`,'#ffd166',1.5);}else addFeed(`${t.name} 倒下了`,'#cfc6d8');
      for(let i=0;i<4+Math.floor(t.lvl/2);i++)dropGem(t.x,t.y,5);deathFx(t,TCOL[t.team]);toastH(t,'被打倒了…','#ff8a7a',2);break;}
    case'minion':t.dead=true;xpNear(o,t,7);smallDeath(t,TCOL[t.team],8);SFX.roachDie();break;
    case'roach':case'rat':{t.dead=true;if(t.camp){t.camp.alive--;if(t.camp.alive<=0)t.camp.resp=G.t+(t.camp.type==='roach'?50:70);}xpNear(src.owner,t,t.kind==='rat'?16:6);if(Math.random()<(t.kind==='rat'?0.8:0.3))dropGem(t.x,t.y,t.kind==='rat'?8:5);
      if(t.kind==='rat'){deathFx(t,'#c9cbd4');pop(t.x,t.y,t.r*2.8,'吱！','#ffb3c1',18,0.8);}else{smallDeath(t,'#7a4a22',12);decal({type:'splat',x:t.x,y:t.y,r:rand(14,20),rot:rand(0,TAU),life:25,max:25});SFX.roachDie();}break;}
    case'boss':{t.dead=true;G.bossNext=G.t+150;const k=src.owner&&src.owner.kind==='ham'?src.owner:null;
      if(k){giveXP(k,160);for(const h of hams)if(h.team===k.team){giveXP(h,70);h.crownT=60;calcStats(h);}addFeed(`${k.name} 击败了鼠王！`,'#ffd166');toastAll(`${TNAME[k.team]}击败鼠王，全队获得王冠加成！`,'#ffd166',3);}
      for(let i=0;i<10;i++)dropGem(t.x,t.y,10);bigBoom(t.x,t.y,1.1);break;}
    case'turret':{t.dead=true;for(const h of hams)if(h.team!==t.team)giveXP(h,45);addFeed(`${TNAME[t.team]}的炮台被摧毁`,TCOL[ENEMY[t.team]]);toastAll(`${TNAME[t.team]}的炮台被摧毁了`,TCOL[ENEMY[t.team]],2.4);bigBoom(t.x,t.y,0.9);break;}
    case'base':{t.dead=true;bigBoom(t.x,t.y,1.6);G.over=true;G.winner=ENEMY[t.team];G.endT=3;slowT=1.2;timeScale=0.35;toastAll(`${TNAME[G.winner]}打爆了对方的仓鼠窝！`,TCOL[G.winner],3);break;}
    case'sentry':t.dead=true;smallDeath(t,TCOL[t.team],10);break;
    case'crate':{t.dead=true;const sp=t.spot;if(sp){sp.cur=null;sp.resp=G.t+(sp.big?90:40);}const n=t.big?12:randi(3,5);for(let i=0;i<n;i++)dropGem(t.x,t.y,t.big?9:6);if(Math.random()<(t.big?1:0.35))pickups.push(mkPickup('cheese',t.x,t.y));
      smallDeath(t,'#d9a35a',10);SFX.open();break;}
  }
}

// ---------- 子弹 ----------
function onBulletHit(b,e){
  if(b.kind==='rocket'){explode(b);return;}
  let dm=b.dmg;if(b.eff<1){const d=Math.hypot(b.x-b.x0,b.y-b.y0),e0=b.maxD*b.eff;if(d>e0)dm*=lerp(1,b.minF,clamp((d-e0)/Math.max(1,b.maxD-e0),0,1));}
  if(dealDmg(e,dm,{team:b.team,owner:b.owner,by:b.by,x:b.x,y:b.y})>0&&b.owner)hitMark(b.owner,e);
  const l=Math.hypot(b.vx,b.vy)||1;knock(e,b.vx/l,b.vy/l,b.kb);
  if(b.kind==='flame'){e.burnT=2.5;e.burnBy=b.owner;return;}
  const big=b.kind==='snipe'||b.kind.startsWith('trc')||b.kind.startsWith('seed');onHitFx(b.x,b.y,b.h,b.kind==='snipe'?'#bff4ff':b.team==='blue'?'#bfe0ff':b.team==='red'?'#ffc8c8':'#ffb3e6',big);SFX.hit();
  const o=b.owner;
  if(o&&o.kind==='ham'&&o.alive){
    if(o.st.incend>0&&Math.random()<o.st.incend){e.burnT=2.2;e.burnBy=o;}
    if(o.st.frost>0){e.slowT=0.8+0.6*o.st.frost;addP({type:'star',x:e.x,y:e.y,h:e.r,vh:30,life:0.4,size:7,col:'#bfefff',glow:1,grav:0});}
    if(o.st.chain>0&&Math.random()<o.st.chain)chainLightning(e,b.dmg*0.45,o);
    if(o.st.split>0&&b.split>0&&b.kind!=='spike'){const a=Math.atan2(b.vy,b.vx);for(const k of [-1,1]){const nb=mkBullet(b.team==='blue'?'pel_b':'pel_r',o,b.x,b.y,b.h,a+k*0.55,l*0.75,b.dmg*0.35*(1+0.25*(o.st.split-1)),220,{r:3.5,kb:20});nb.split=0;nb.hit.add(e);bullets.push(nb);}}
  }
}
function explode(b){const R=b.aoe;rocketBoom(b.x,b.y,b.h,R);hashRange(b.x,b.y,R+60,e=>{if(!canHit(b.team,e))return;const d=Math.hypot(e.x-b.x,e.y-b.y)-e.r;if(d>R)return;const f=1-Math.max(0,d)/R*0.5;dealDmg(e,(b.aoeDmg+b.dmg)*f,{team:b.team,owner:b.owner,by:b.by,x:b.x,y:b.y});knock(e,e.x-b.x,e.y-b.y,b.kb*f);});}
function bulletEnd(b,wall){const bx=b.x-b.vx*0.012,by=b.y-b.vy*0.012;
  if(b.kind==='rocket'){b.x=bx;b.y=by;explode(b);return;}
  if(b.kind==='flame')return;
  if(wall){sparks(bx,by,b.h,b.team==='blue'?'#bfe0ff':b.team==='red'?'#ffc8c8':'#ffb3e6',fxn(4));addP({type:'smoke',x:bx,y:by,h:b.h,vx:rand(-20,20),vy:rand(-20,20),vh:rand(5,25),life:0.4,size:5,grow:24,col:'#9a94ac'});SFX.wall();}}
function updBullets(dt){
  for(let i=bullets.length-1;i>=0;i--){const b=bullets[i];let dead=false;if(b.home)homeB(b,dt);if(b.splitAt&&Math.hypot(b.x-b.x0,b.y-b.y0)>b.splitAt){splitB(b);bullets[i]=bullets[bullets.length-1];bullets.pop();continue;}
    if(b.kind==='flame'){const f=Math.exp(-1.8*dt);b.vx*=f;b.vy*=f;b.r+=dt*22;if(Math.random()<0.8)addP({type:'fire',x:b.x,y:b.y,h:b.h,vx:b.vx*0.3+rand(-20,20),vy:b.vy*0.3+rand(-20,20),vh:rand(10,40),life:rand(0.18,0.32),size:b.r*rand(0.9,1.4)});}
    if(b.kind==='rocket'&&Math.random()<0.8){addP({type:'smoke',x:b.x,y:b.y,h:b.h,vx:rand(-15,15),vy:rand(-15,15),vh:rand(5,20),life:rand(0.4,0.7),size:rand(6,10),grow:22,col:'#a29cb4'});addP({type:'fire',x:b.x-b.vx*0.02,y:b.y-b.vy*0.02,h:b.h,vx:-b.vx*0.1,vy:-b.vy*0.1,life:0.12,size:rand(8,12)});}
    const sp=Math.hypot(b.vx,b.vy),steps=Math.max(1,Math.ceil(sp*dt/12)),sdt=dt/steps;
    for(let s=0;s<steps&&!dead;s++){
      b.px=b.x;b.py=b.y;b.x+=b.vx*sdt;b.y+=b.vy*sdt;
      const sd=solidAt(b.x,b.y,b.kind==='flame'?2:b.r*0.5);
      if(sd){const fresh=b.inS!==sd;b.inS=sd;if(fresh&&sd.prop)propHit(sd.prop,b.dmg,b.owner);
        if(b.wp&&(sd.kind!=='wall'||b.wp>1)){if(fresh){sparks(b.x,b.y,b.h,'#ffe2a8',fxn(6));addP({type:'smoke',x:b.x,y:b.y,h:b.h,vx:rand(-30,30),vy:rand(-30,30),vh:rand(10,40),life:0.6,size:10,grow:30,col:'#c8b89a'});}}
        else if(b.bounce>0){b.bounce--;const hx=solidAt(b.px+b.vx*sdt,b.py,b.r*0.5),hy=solidAt(b.px,b.py+b.vy*sdt,b.r*0.5);if(hx||!hy)b.vx=-b.vx;if(hy||!hx)b.vy=-b.vy;b.x=b.px;b.y=b.py;b.hit=new Set();b.dmg*=b.bounceK||0.85;if(b.homeAfter)b.home=b.homeAfter;b.inS=null;sparks(b.x,b.y,b.h,'#ffe2a8',fxn(5));{const q=sndAt(b.x,b.y);GSFX.ric(q.pan,q.vol);}continue;}
        else{dead=true;bulletEnd(b,true);break;}}else b.inS=null;
      const cand=hashAt(b.x,b.y);
      for(let k=0;k<cand.length;k++){const e=cand[k];if(b.hit.has(e)||e===b.by||!canHit(b.team,e))continue;const rr=e.r+b.r;if(d2(b.x,b.y,e.x,e.y)>=rr*rr)continue;
        b.hit.add(e);onBulletHit(b,e);if(b.kind==='rocket'){dead=true;break;}if(b.kind==='flame')continue;if(b.pierce>0){b.pierce--;continue;}dead=true;break;}
    }
    if(!dead){b.life-=dt;b.rot+=b.vr*dt;if(b.kind==='coin')0;if(b.life<=0){dead=true;bulletEnd(b,false);}}
    if(dead){bullets[i]=bullets[bullets.length-1];bullets.pop();}
  }
}

// ---------- 分离 ----------
function separate(){
  const mv=[];for(const h of hams)if(h.alive&&!h.air)mv.push(h);for(const m of minions)if(!m.dead)mv.push(m);for(const e of mobs)if(!e.dead)mv.push(e);
  const C=64,grid=new Map();for(const a of mv){const k=Math.floor(a.x/C)*10000+Math.floor(a.y/C);let l=grid.get(k);if(!l)grid.set(k,l=[]);l.push(a);}
  for(const a of mv){const cx=Math.floor(a.x/C),cy=Math.floor(a.y/C);for(let i=-1;i<=1;i++)for(let j=-1;j<=1;j++){const l=grid.get((cx+i)*10000+cy+j);if(!l)continue;for(const b of l){if(b.id<=a.id)continue;const rr=a.r+b.r,dx=a.x-b.x,dy=a.y-b.y,dd=dx*dx+dy*dy;if(dd<rr*rr&&dd>1e-4){const d=Math.sqrt(dd),p=(rr-d)/2,nx=dx/d,ny=dy/d,wa=a.kind==='boss'?0.2:1,wb=b.kind==='boss'?0.2:1;a.x+=nx*p*wa;a.y+=ny*p*wa;b.x-=nx*p*wb;b.y-=ny*p*wb;}}}}
  for(const s of structs){if(s.dead)continue;for(const a of mv){const rr=a.r+s.r,dx=a.x-s.x,dy=a.y-s.y,dd=dx*dx+dy*dy;if(dd<rr*rr&&dd>1e-4){const d=Math.sqrt(dd);a.x=s.x+dx/d*rr;a.y=s.y+dy/d*rr;}}}
  for(const c of crates){if(c.dead)continue;for(const a of mv){const rr=a.r+c.r,dx=a.x-c.x,dy=a.y-c.y,dd=dx*dx+dy*dy;if(dd<rr*rr&&dd>1e-4){const d=Math.sqrt(dd);a.x=c.x+dx/d*rr;a.y=c.y+dy/d*rr;}}}
  for(const a of mv)resolveCircle(a,a.r);
}

// ---------- 特效更新 ----------
function updFX(dt){
  for(let i=parts.length-1;i>=0;i--){const p=parts[i];p.life-=dt;if(p.life<=0){parts[i]=parts[parts.length-1];parts.pop();continue;}if(p.drag){const f=Math.exp(-p.drag*dt);p.vx*=f;p.vy*=f;p.vh*=f;}p.vh-=p.grav*dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.h+=p.vh*dt;if(p.h<0){p.h=0;if(p.bounce&&p.vh<-40){p.vh*=-0.35;p.vx*=0.6;p.vy*=0.6;}else{p.vh=0;p.vx*=0.85;p.vy*=0.85;}}if(p.grow)p.size+=p.grow*dt;}
  for(let i=shells.length-1;i>=0;i--){const s=shells[i];s.life-=dt;if(s.life<=0){shells.splice(i,1);continue;}if(s.z>0||s.vz){s.vz-=900*dt;s.z+=s.vz*dt;if(s.z<=0){s.z=0;if(s.vz<-60){if((s.tink=(s.tink||0)+1)<=2){const q=sndAt(s.x,s.y);if(q.vol>0.25)GSFX.tink(q.pan,q.vol*(s.type==='red'?0.5:0.85));}s.vz*=-0.4;s.vx*=0.6;s.vy*=0.6;s.vr*=0.5;}else s.vz=0;}}const f=Math.exp(-(s.z>0?0.5:6)*dt);s.vx*=f;s.vy*=f;s.x+=s.vx*dt;s.y+=s.vy*dt;s.rot+=s.vr*dt;}
  for(let i=decals.length-1;i>=0;i--){decals[i].life-=dt;if(decals[i].life<=0)decals.splice(i,1);}
  for(let i=pops.length-1;i>=0;i--){const p=pops[i];p.life-=dt;p.h+=p.vh*dt;p.vh*=Math.exp(-3*dt);if(p.life<=0)pops.splice(i,1);}
  for(let i=rings.length-1;i>=0;i--){const r=rings[i];r.life-=dt;r.r+=r.grow*dt;if(r.life<=0)rings.splice(i,1);}
  for(let i=slashes.length-1;i>=0;i--){slashes[i].t+=dt;if(slashes[i].t>=slashes[i].life)slashes.splice(i,1);}
  for(let i=zaps.length-1;i>=0;i--){zaps[i].t+=dt;if(zaps[i].t>=zaps[i].life)zaps.splice(i,1);}
  for(let i=trails.length-1;i>=0;i--){trails[i].t+=dt;if(trails[i].t>=trails[i].life)trails.splice(i,1);}
  for(let i=noises.length-1;i>=0;i--){noises[i].t+=dt;if(noises[i].t>=noises[i].life)noises.splice(i,1);}
  for(let i=beams.length-1;i>=0;i--){beams[i].t+=dt;if(beams[i].t>=beams[i].life)beams.splice(i,1);}
  for(let i=feed.length-1;i>=0;i--){feed[i].t+=dt;if(feed[i].t>6)feed.splice(i,1);}
  for(const k in FLASH)if(FLASH[k].t>0)FLASH[k].t-=dt;
  fxPulse=Math.max(0,fxPulse-dt*2.5);
  if(wave){wave.t+=dt;if(wave.t>=wave.life)wave=null;}
}

// ---------- 世界 ----------
function setupWorld(){
  hams=[];minions=[];mobs=[];structs=[];crates=[];gems=[];pickups=[];pets=[];bullets=[];parts=[];shells=[];decals=[];pops=[];rings=[];feed=[];slashes=[];zaps=[];trails=[];lobs=[];fires=[];mines=[];beams=[];noises=[];smokes=[];flares=[];decoys=[];zones=[];corrs=[];burns=[];wave=null;
  for(const k in FLASH)FLASH[k].t=0;
  G={t:0,waveNext:15,spawnQ:[],bossNext:120,boss:null,over:false,winner:null,endT:0,sudden:false,minMul:1};
  for(const team of TEAMS){structs.push(mkStruct('base',team,BASE_POS[team].x,BASE_POS[team].y));for(const p of TURRETS[team])structs.push(mkStruct('turret',team,p[0],p[1]));}
  for(const c of camps){c.alive=0;c.resp=0;spawnCamp(c);}
  for(const s of crateSpots){s.cur=null;s.resp=s.big?45:rand(0,6);}
  setupProps();for(const p of padSpots){p.cd=0;p.anim=0;}detQ=[];VIS.blue.clear();VIS.red.clear();visT=0;
  hitstop=0;timeScale=1;slowT=0;
}
function update(dt){
  G.t+=dt;
  if(!G.over){
    if(G.t>=G.waveNext){G.waveNext+=30;spawnWave();if(G.t<20)toastAll('第一波小兵出发了','#cfe8ff',2);}
    while(G.spawnQ.length&&G.spawnQ[0].t<=G.t){const q=G.spawnQ.shift();if(minions.length<96)minions.push(mkMinion(q.team,q.lane));}
    if(!G.boss&&G.t>=G.bossNext){G.boss=mkMob('boss',null,BOSS_POS.x,BOSS_POS.y);mobs.push(G.boss);toastAll('鼠王出现在地图上方正中！','#ffd166',3);addFeed('鼠王出现了','#ffd166');}
    if(G.boss&&G.boss.dead)G.boss=null;
    for(const c of camps)if(c.alive<=0&&G.t>=c.resp)spawnCamp(c);
    for(const s of crateSpots)if(!s.cur&&G.t>=s.resp){s.cur=mkCrate(s);crates.push(s.cur);}
    if(!G.sudden&&G.t>=720){G.sudden=true;G.minMul=1.5;toastAll('加速决战！建筑受到双倍伤害','#ff8a7a',3.5);}
  }
  hashAll();
  visT-=dt;if(visT<=0){visT=0.08;computeVis();}
  for(const h of hams)if(h.ctl==='ai')aiThink(h,dt);
  for(const h of hams)updHam(h,dt);
  for(const p of pets)updPet(p,dt);
  for(const m of minions)updMinion(m,dt);
  for(const e of mobs)updMob(e,dt);
  for(const s of structs)updStruct(s,dt);
  updPads(dt);updProps(dt);
  separate();updBullets(dt);updLobs(dt);updFires(dt);updMines(dt);updEvoWorld(dt);updGems(dt);updFX(dt);
  if(structs.some(q=>q.dead&&q.kind==='sentry'))structs=structs.filter(q=>!(q.dead&&q.kind==='sentry'));
  if(minions.some(m=>m.dead))minions=minions.filter(m=>!m.dead);
  if(mobs.some(m=>m.dead))mobs=mobs.filter(m=>!m.dead);
  if(crates.some(c=>c.dead))crates=crates.filter(c=>!c.dead);
  if(pets.some(p=>p.dead))pets=pets.filter(p=>!p.dead);
  updCams(dt);
  if(G.over){G.endT-=dt;if(G.endT<=0&&state==='play')endMatch(G.winner);}
}

// ---------- 新武器与战术道具 ----------
function solidAt(x,y,r){for(const s of solids){if(s.off)continue;if(s.c){const rr=s.r+r;if(d2(x,y,s.x,s.y)<rr*rr)return s;}else if(x+r>s.x&&x-r<s.x+s.w&&y+r>s.y&&y-r<s.y+s.h)return s;}return null;}
function throwLob(h,kind,tx,ty,o){const dx=tx-h.x,dy=ty-h.y,d=Math.max(40,Math.hypot(dx,dy)),sp=o.sp||520,t=d/sp;lobs.push({kind,team:h.team,owner:h.kind==='ham'?h:null,x:h.x+dx/d*h.r,y:h.y+dy/d*h.r,z:h.r*1.2,vx:dx/d*sp,vy:dy/d*sp,vz:450*t,fuse:o.fuse!=null?o.fuse:null,aoe:o.aoe||0,dmg:o.dmg||0,kb:o.kb||0,impact:!!o.impact,lvl:o.lvl||1,rot:0,t:0});if(lobs.length>40)lobs.shift();}
function updLobs(dt){
  for(let i=lobs.length-1;i>=0;i--){const b=lobs[i];b.t+=dt;b.rot+=dt*12;let boom=false;
    const nx=b.x+b.vx*dt,ny=b.y+b.vy*dt;
    if(solidAt(nx,ny,5)){const hx=solidAt(nx,b.y,5),hy=solidAt(b.x,ny,5);if(hx||!hy)b.vx*=-0.5;if(hy||!hx)b.vy*=-0.5;if(b.kind==='molo')boom=true;}else{b.x=nx;b.y=ny;}
    b.vz-=900*dt;b.z+=b.vz*dt;
    if(b.z<=2){b.z=2;if(b.kind==='molo')boom=true;else if(b.vz<-60){b.vz=-b.vz*0.38;b.vx*=0.6;b.vy*=0.6;const q=sndAt(b.x,b.y);GSFX.clank(q.pan,q.vol*0.6);}else{b.vz=0;const f=Math.exp(-6*dt);b.vx*=f;b.vy*=f;}}
    if(b.impact&&b.z<40)for(const e of hashAt(b.x,b.y)){if(!canHit(b.team,e))continue;if(d2(b.x,b.y,e.x,e.y)<(e.r+8)*(e.r+8)){boom=true;break;}}
    if(b.fuse!=null){b.fuse-=dt;if(b.fuse<=0)boom=true;}
    if(b.t>6)boom=true;
    if(Math.random()<0.5)addP({type:'smoke',x:b.x,y:b.y,h:b.z,vx:rand(-10,10),vy:rand(-10,10),vh:rand(5,15),life:0.35,size:rand(3,5),grow:10,col:'#b8b4c4'});
    if(b.kind==='molo'&&Math.random()<0.7)addP({type:'fire',x:b.x,y:b.y,h:b.z+12,vh:20,life:0.18,size:rand(5,8)});
    if(boom){lobs.splice(i,1);lobBoom(b);}}}
function blast(x,y,R,dmg,team,owner,kb){rocketBoom(x,y,12,R);let hit=null;hashRange(x,y,R+60,e=>{if(!canHit(team,e))return;const d=Math.hypot(e.x-x,e.y-y)-e.r;if(d>R)return;const f=1-Math.max(0,d)/R*0.5;if(dealDmg(e,dmg*f,{team,owner,x,y})>0)hit=e;knock(e,e.x-x,e.y-y,kb*f);});if(hit&&owner)hitMark(owner,hit);}
function lobBoom(b){
  if(b.kind==='gnade'||b.kind==='frag')blast(b.x,b.y,b.aoe,b.dmg,b.team,b.owner,b.kb);
  else if(b.kind==='molo'){fires.push({x:b.x,y:b.y,r:95+10*(b.lvl-1),t:0,life:4.5+0.5*(b.lvl-1),team:b.team,owner:b.owner,dps:12*(1+0.25*(b.lvl-1)),tick:0});const q=sndAt(b.x,b.y);GSFX.glass(q.pan,q.vol);noise(b.x,b.y,'boom',0.8,null);flashL('boom',b.x,b.y,30,1.8*FXK,0.4);
    for(let k=0;k<fxn(14);k++){const a=rand(0,TAU),s=rand(60,200);addP({type:'fire',x:b.x,y:b.y,h:8,vx:Math.cos(a)*s,vy:Math.sin(a)*s,vh:rand(40,120),life:rand(0.3,0.6),size:rand(14,24)});}sparks(b.x,b.y,8,'#bfe8ff',fxn(6));decal({type:'scorch',x:b.x,y:b.y,r:80,rot:rand(0,TAU),life:12,max:12});}
  else if(b.kind==='flsh')flashBang(b);}
function flashBang(b){const R=290,q=sndAt(b.x,b.y);noise(b.x,b.y,'boom',1.2,null);GSFX.bang(q.pan,q.vol);flashL('boom',b.x,b.y,40,4.5,0.35);addP({type:'flash',x:b.x,y:b.y,h:20,life:0.18,size:70,col:'#ffffff',rot:0,star:1});ring(b.x,b.y,3,10,600,0.35,'#ffffff');shakeAt(b.x,b.y,0.25);
  for(const h of hams){if(!h.alive||h.team===b.team)continue;const d=Math.hypot(h.x-b.x,h.y-b.y);if(d>R||!hasLOS(b.x,b.y,h.x,h.y))continue;const k=clamp(1.2-d/R,0.4,1);if(h.view)h.view.flashT=Math.max(h.view.flashT||0,2.0*k);else h.blindT=Math.max(h.blindT,2.2*k);}
  for(const m of minions)if(!m.dead&&m.team!==b.team&&Math.hypot(m.x-b.x,m.y-b.y)<R)m.stun=1.6;
  for(const e of mobs)if(!e.dead&&Math.hypot(e.x-b.x,e.y-b.y)<R)e.stun=1.6;}
function updFires(dt){for(let i=fires.length-1;i>=0;i--){const f=fires[i];f.t+=dt;f.tick-=dt;const k=f.t/f.life;
  if(Math.random()<dt*28*FXK){const a=rand(0,TAU),r=Math.sqrt(Math.random())*f.r;addP({type:'fire',x:f.x+Math.cos(a)*r,y:f.y+Math.sin(a)*r*0.8,h:rand(2,10),vx:rand(-10,10),vy:rand(-10,10),vh:rand(40,90),life:rand(0.3,0.6),size:rand(14,26)*(1-k*0.5)});}
  if(Math.random()<dt*5)addP({type:'smoke',x:f.x+rand(-f.r,f.r)*0.6,y:f.y+rand(-f.r,f.r)*0.5,h:rand(20,40),vx:rand(-10,10),vy:rand(-10,10),vh:rand(30,60),life:rand(1,1.6),size:rand(20,34),grow:20,col:'#3a3440'});
  if(f.tick<=0){f.tick=0.25;hashRange(f.x,f.y,f.r+40,e=>{if(!canHit(f.team,e)||e.kind==='crate')return;if(Math.hypot(e.x-f.x,e.y-f.y)<f.r+e.r*0.5){dealDmg(e,f.dps*0.25,{team:f.team,owner:f.owner,x:f.x,y:f.y},true);e.burnT=Math.max(e.burnT||0,1.2);e.burnBy=f.owner;}});}
  if(f.t>=f.life)fires.splice(i,1);}}
function placeMine(h){const own=mines.filter(m=>m.owner===h);if(own.length>=3)mines.splice(mines.indexOf(own[0]),1);mines.push({x:h.x,y:h.y,team:h.team,owner:h,arm:0.8,lvl:h.gadget.lvl,t:0});const q=hamSnd(h);GSFX.beep(q.pan,q.vol);}
function updMines(dt){for(let i=mines.length-1;i>=0;i--){const m=mines[i];m.t+=dt;if(m.arm>0){m.arm-=dt;continue;}let trig=false;hashRange(m.x,m.y,60,e=>{if(trig||!canHit(m.team,e)||e.isProp||e.kind==='crate'||e.kind==='base'||e.kind==='turret'||e.kind==='sentry')return;if(Math.hypot(e.x-m.x,e.y-m.y)<e.r+30)trig=true;});if(trig){mines.splice(i,1);blast(m.x,m.y,110,90*(1+0.25*(m.lvl-1)),m.team,m.owner,360);}}}
function placeSentry(h){for(const s of structs)if(s.kind==='sentry'&&s.owner===h)s.dead=true;const a=h.aim,L=h.gadget.lvl;const s={kind:'sentry',id:UID++,team:h.team,owner:h,x:h.x+Math.cos(a)*34,y:h.y+Math.sin(a)*34,r:16,hp:140*(1+0.25*(L-1)),maxHp:1,cd:0.5,range:380,dmg:7*(1+0.2*(L-1)),aim:a,target:null,tT:0,flash:0,dead:false,life:16+2*(L-1),alt:0};s.maxHp=s.hp;resolveCircle(s,s.r);structs.push(s);ring(s.x,s.y,3,8,140,0.3,TCOL[h.team]);const q=hamSnd(h);GSFX.beep(q.pan,q.vol);}
function gadgetTarget(h){let tx,ty;if(h.dev==='kbm'&&mouse.has&&h.view){tx=h.mwx;ty=h.mwy;}else{const t=h.ctl==='ai'?h.ai.target:autoAim(h,520);if(t&&Math.hypot(t.x-h.x,t.y-h.y)<560){tx=t.x;ty=t.y;}else{tx=h.x+Math.cos(h.aim)*300;ty=h.y+Math.sin(h.aim)*300;}}
  const dx=tx-h.x,dy=ty-h.y,d=Math.hypot(dx,dy)||1,dd=clamp(d,80,520);return{x:h.x+dx/d*dd,y:h.y+dy/d*dd};}
function useGadget(h){const G0=GADGETS[h.gadget.id],L=h.gadget.lvl,q=hamSnd(h);h.gadget.cd=G0.cd*(1-0.15*(L-1))*h.st.gcd;
  if(h.gadget.id==='mine'){placeMine(h);return;}if(h.gadget.id==='sentry'){placeSentry(h);return;}
  const p=gadgetTarget(h);GSFX.throw(q.pan,q.vol);h.spitT=0.2;
  if(h.gadget.id==='frag')throwLob(h,'frag',p.x,p.y,{sp:420,fuse:1.5,aoe:130,dmg:70*(1+0.2*(L-1)),kb:380});
  else if(h.gadget.id==='molotov')throwLob(h,'molo',p.x,p.y,{sp:420,lvl:L});
  else throwLob(h,'flsh',p.x,p.y,{sp:460,fuse:1.0});}
function chargeFx(h){const c=Math.cos(h.aim),s=Math.sin(h.aim),gx=h.x+c*h.r*2.4,gy=h.y+s*h.r*2.4,a=rand(0,TAU),r=rand(18,34);addP({type:'star',x:gx+Math.cos(a)*r,y:gy+Math.sin(a)*r,h:h.r+rand(-8,8),vx:-Math.cos(a)*r*4,vy:-Math.sin(a)*r*4,vh:0,life:0.22,size:4,col:'#9fe8ff',glow:1,grav:0,drag:0});}
function fireRail(h){h.revealT=0.45;noise(h.x,h.y,'gun',1.1,h);const W=WEAPONS.rail,L=h.weapon.lvl,c=Math.cos(h.aim),s=Math.sin(h.aim),R=h.r,ch=h.charge;h.charge=0;h.chHold=0;h.ammo--;h.fireCd=0.3;
  const gx=h.x+c*R*2.4,gy=h.y+s*R*2.4,gh=R;let Lr=0;const RR=W.range*h.st.rangeK;while(Lr<RR&&!pointSolid(gx+c*Lr,gy+s*Lr,1))Lr+=10;const x1=gx+c*Lr,y1=gy+s*Lr,dmg=(W.dmg+140*ch)*(1+0.2*(L-1))*h.st.dmg;let hit=null;
  for(const list of [hams,minions,mobs,structs,crates])for(const e of list){if(!canHit(h.team,e))continue;const t=clamp((e.x-gx)*c+(e.y-gy)*s,0,Lr),px=gx+c*t,py=gy+s*t;if(Math.hypot(e.x-px,e.y-py)<e.r+10*(0.5+ch)){if(dealDmg(e,dmg,{team:h.team,owner:h,x:px,y:py})>0)hit=e;knock(e,c,s,W.kb*ch);onHitFx(e.x,e.y,e.r,'#bff4ff',true);}}
  for(const p of props){if(p.dead)continue;const t=clamp((p.x-gx)*c+(p.y-gy)*s,0,Lr+20);if(Math.hypot(p.x-gx-c*t,p.y-gy-s*t)<p.r+12)propHit(p,dmg,h);}
  if(hit)hitMark(h,hit);beams.push({x0:gx,y0:gy,x1,y1,h:gh,t:0,life:0.4,w:3+6*ch,col:h.team});
  for(let i=0;i<fxn(18*ch+6);i++){const k=Math.random()*Lr;addP({type:'star',x:gx+c*k,y:gy+s*k,h:gh+rand(-4,4),vx:rand(-30,30),vy:rand(-30,30),vh:rand(10,50),life:rand(0.3,0.6),size:rand(4,7),col:'#9fe8ff',glow:1,grav:0});}
  addP({type:'flash',x:gx,y:gy,h:gh,life:0.1,size:26+20*ch,col:'#bff4ff',dir:h.aim,cone:3,rot:rand(0,TAU)});flashL('flash',gx,gy,gh+12,3.5*FXK,0.12);ring(x1,y1,gh,6,200,0.25,'#9fe8ff');sparks(x1,y1,gh,'#bff4ff',fxn(8));
  shakeAt(h.x,h.y,(0.15+0.3*ch)*FXK,h);kickV(h,h.aim,6+10*ch);h.vx-=c*(80+180*ch);h.vy-=s*(80+180*ch);h.kick.w-=120;const q=hamSnd(h);GSFX.rail(q.pan,q.vol,ch);setWave(gx,gy,0.3,0.5*ch,0.5);}
function laserTick(h){h.revealT=0.3;if(Math.random()<0.3)noise(h.x,h.y,'gun',0.55,h);const W=WEAPONS.laser,L=h.weapon.lvl,c=Math.cos(h.aim),s=Math.sin(h.aim),R=h.r,gx=h.x+c*R*2.3,gy=h.y+s*R*2.3,gh=R,range=W.range*(1+0.08*(L-1))*h.st.rangeK;h.ammo--;
  let d=0,hit=null;while(d<range){const x=gx+c*d,y=gy+s*d;{const sd=pointSolid(x,y,1);if(sd){if(sd.prop)propHit(sd.prop,W.dmg*h.st.dmg,h);break;}}for(const e of hashAt(x,y)){if(!canHit(h.team,e))continue;if(d2(x,y,e.x,e.y)<e.r*e.r){hit=e;break;}}if(hit)break;d+=8;}
  h.beam={x0:gx,y0:gy,x1:gx+c*d,y1:gy+s*d,h:gh,hit:!!hit,t:time};
  if(hit){if(dealDmg(hit,W.dmg*(1+0.2*(L-1))*h.st.dmg,{team:h.team,owner:h,x:hit.x,y:hit.y},true)>0)hitMark(h,hit);if(Math.random()<0.5){hit.burnT=Math.max(hit.burnT||0,0.6);hit.burnBy=h;}}
  sparks(gx+c*d,gy+s*d,gh,h.team==='blue'?'#9fe8ff':'#ff9fb4',fxn(2));const q=hamSnd(h);GSFX.laser(q.pan,q.vol);flashL('flash',gx,gy,gh+10,0.8*FXK,0.12);}

// ---------- 场景互动：灯、爆炸桶、纸箱、弹射装置 ----------
let props=[],detQ=[];
const PROPDEF={lamp:{r:14,hp:30,resp:45,ht:70},barrel:{r:18,hp:40,resp:50,ht:44},box:{r:40,hp:140,resp:60,ht:60}};
function setupProps(){props=[];for(let i=solids.length-1;i>=0;i--)if(solids[i].prop)solids.splice(i,1);
  for(const d of propSpots){const D=PROPDEF[d.kind],p={kind:d.kind,isProp:true,id:UID++,team:'neutral',x:d.x,y:d.y,r:D.r,hp:D.hp,maxHp:D.hp,dead:false,flash:0,respT:0,solid:null,rot:(d.x*0.013+d.y*0.007)%TAU};
    p.solid=d.kind==='box'?{x:d.x-35,y:d.y-35,w:70,h:70,kind:'pbox',ht:D.ht,prop:p}:{c:true,x:d.x,y:d.y,r:D.r,kind:'p'+d.kind,ht:D.ht,prop:p};solids.push(p.solid);props.push(p);navPatch(p);}}
function navPatch(p){if(!NAV.pass)return;const R=70,c0=Math.max(0,Math.floor((p.x-R)/NAV.cell)),c1=Math.min(NAV.gc-1,Math.floor((p.x+R)/NAV.cell)),r0=Math.max(0,Math.floor((p.y-R)/NAV.cell)),r1=Math.min(NAV.gr-1,Math.floor((p.y+R)/NAV.cell));for(let j=r0;j<=r1;j++)for(let i=c0;i<=c1;i++)NAV.pass[j*NAV.gc+i]=overlapsSolid((i+0.5)*NAV.cell,(j+0.5)*NAV.cell,20)?0:1;FCACHE.clear();}
function propHit(p,dmg,owner){if(p.dead)return;p.hp-=dmg;p.flash=0.1;if(p.kind==='box'&&Math.random()<0.5)addP({type:'dot',x:p.x+rand(-20,20),y:p.y+rand(-20,20),h:rand(20,50),vx:rand(-90,90),vy:rand(-90,90),vh:rand(60,160),life:0.5,size:3,col:'#c89359'});if(p.hp<=0)destroyProp(p,owner);}
function destroyProp(p,owner){p.dead=true;p.solid.off=true;navPatch(p);p.respT=G.t+PROPDEF[p.kind].resp;const q=sndAt(p.x,p.y);
  if(p.kind==='barrel')blastAll(p.x,p.y,150,85,owner);
  else if(p.kind==='lamp'){GSFX.glass(q.pan,q.vol);noise(p.x,p.y,'boom',0.6,null);sparks(p.x,p.y,60,'#fff1c0',fxn(10));for(let i=0;i<fxn(8);i++)addP({type:'dot',x:p.x,y:p.y,h:60,vx:rand(-120,120),vy:rand(-120,120),vh:rand(40,140),life:rand(0.4,0.8),size:2.5,col:'#e8f6ff'});flashL('flash',p.x,p.y,60,1.5,0.15);}
  else{SFX.open();for(let i=0;i<fxn(16);i++){const a=rand(0,TAU),sp=rand(60,240);addP({type:'fur',x:p.x,y:p.y,h:rand(10,50),vx:Math.cos(a)*sp,vy:Math.sin(a)*sp,vh:rand(60,200),life:rand(0.5,1),size:rand(5,9),col:Math.random()<0.5?'#c89359':'#e6c58a'});}addP({type:'smoke',x:p.x,y:p.y,h:20,life:0.8,size:40,grow:30,col:'#b8a07a'});}}
function blastAll(x,y,R,dmg,owner){rocketBoom(x,y,20,R);shakeAt(x,y,0.35);setWave(x,y,0.4,0.8,0.7);let hit=null;
  hashRange(x,y,R+60,e=>{if(e.kind==='base'||e.kind==='turret'||e.dead||(e.kind==='ham'&&!e.alive))return;const d=Math.hypot(e.x-x,e.y-y)-e.r;if(d>R)return;const f=1-Math.max(0,d)/R*0.5,ow=owner&&e.team!==owner.team?owner:null;if(dealDmg(e,dmg*f,{team:'neutral',owner:ow,x,y})>0&&ow&&!e.isProp)hit=e;knock(e,e.x-x,e.y-y,320*f);});
  if(hit&&owner)hitMark(owner,hit);}
function updProps(dt){for(const p of props){p.flash=Math.max(0,p.flash-dt);if(p.dead&&G.t>=p.respT){let blocked=false;for(const h of hams)if(h.alive&&Math.hypot(h.x-p.x,h.y-p.y)<p.r+h.r+20)blocked=true;if(!blocked){p.dead=false;p.hp=p.maxHp;p.solid.off=false;navPatch(p);}else p.respT=G.t+2;}}
  for(let i=detQ.length-1;i>=0;i--){const d=detQ[i];d.t-=dt;if(d.t<=0){detQ.splice(i,1);blast(d.x,d.y,90,45,d.team,d.owner,220);}}}
function updPads(dt){for(const p of padSpots){p.anim=Math.max(0,p.anim-dt);}
  for(const h of hams){if(!h.alive||h.air||h.padCd>0)continue;for(const p of padSpots)if(d2(h.x,h.y,p.x,p.y)<30*30){launch(h,p);break;}}}
function launch(h,p){h.air={t:0,dur:1.15,x0:h.x,y0:h.y,x1:p.tx+rand(-25,25),y1:p.ty+rand(-25,25),hgt:170};h.padCd=1.6;h.rollT=0;h.vx=h.vy=0;p.anim=0.35;SFX.boing(true);noise(p.x,p.y,'pad',0.8,h);const q=hamSnd(h);GSFX.throw(q.pan,q.vol);ring(p.x,p.y,3,10,200,0.35,'#ffd166');shakeAt(p.x,p.y,0.15,h);toastH(h,'起飞！','#ffd166',0.9);}
function land(h){h.air=null;h.z=0;resolveCircle(h,h.r);ring(h.x,h.y,3,10,220,0.35,'#ffe2a8');for(let i=0;i<fxn(10);i++){const a=rand(0,TAU);addP({type:'smoke',x:h.x,y:h.y,h:4,vx:Math.cos(a)*rand(80,200),vy:Math.sin(a)*rand(80,200),vh:rand(10,40),life:rand(0.4,0.7),size:rand(10,16),grow:24,col:'#e9dfcc'});}
  shakeAt(h.x,h.y,0.3,h);SFX.thud();h.sq.v=0.6;h.sq.w=0;hashRange(h.x,h.y,120,e=>{if(!canHit(h.team,e)||e.kind==='base'||e.kind==='turret'||e.isProp)return;if(Math.hypot(e.x-h.x,e.y-h.y)<90+e.r){dealDmg(e,25*h.st.dmg,{team:h.team,owner:h,x:h.x,y:h.y});knock(e,e.x-h.x,e.y-h.y,260);}});}
function spawnSquad(h){let best=null;for(const l of ['top','mid','bot']){const p=lanePath(h.team,l);p.forEach((q,i)=>{const d=d2(q[0],q[1],h.x,h.y);if(!best||d<best.d)best={l,i,d};});}
  for(let i=0;i<3;i++){const m=mkMinion(h.team,best.l);m.x=h.x+rand(-30,30);m.y=h.y+rand(-30,30);m.wp=Math.min(best.i+1,m.path.length-1);minions.push(m);}ring(h.x,h.y,3,10,180,0.35,TCOL[h.team]);toastH(h,'小队报到！','#8de0a6',1.2);}
// ---------- 黑暗视野（全队共享） ----------
const VIS={blue:new Set(),red:new Set()};let visT=0;
function litBy(L,e){for(const s of L){const dx=e.x-s.x,dy=e.y-s.y,d=Math.hypot(dx,dy);if(d>s.r+e.r)continue;if(s.dir!==undefined&&d>e.r+24){const c=(dx*Math.cos(s.dir)+dy*Math.sin(s.dir))/(d||1);if(c<s.cos)continue;}if(s.los&&d>e.r+30&&!hasLOS(s.x,s.y,e.x,e.y))continue;return true;}return false;}
function computeVis(){const sh=[];for(const p of props)if(p.kind==='lamp'&&!p.dead)sh.push({x:p.x,y:p.y,r:300,los:true});for(const f of fires)sh.push({x:f.x,y:f.y,r:f.r+90,los:true});if(FLASH.boom.t>0)sh.push({x:FLASH.boom.x,y:FLASH.boom.y,r:340,los:true});
  for(const team of TEAMS){const V=VIS[team];V.clear();const L=sh.slice();
    for(const h of hams)if(h.alive&&h.team===team){const nv=!!h.tal.nightvision;L.push({x:h.x,y:h.y,r:(nv?260:150)+h.r,los:!nv});L.push({x:h.x,y:h.y,r:540*(nv?1.6:1),dir:h.aim,cos:0.8,los:true});}
    for(const s of structs)if(!s.dead&&s.team===team)L.push({x:s.x,y:s.y,r:s.kind==='base'?620:s.kind==='turret'?s.range+30:220,los:true});
    for(const m of minions)if(!m.dead&&m.team===team)L.push({x:m.x,y:m.y,r:120,los:true});
    const test=e=>{if(e.revealT>0||litBy(L,e))V.add(e);};
    for(const h of hams)if(h.alive&&h.team!==team&&(h.invisT<=0||h.revealT>0))test(h);
    for(const m of minions)if(!m.dead&&m.team!==team)test(m);
    for(const e of mobs)if(!e.dead)test(e);
    for(const s of structs)if(!s.dead&&s.kind==='sentry'&&s.team!==team)test(s);
    for(const m of mines)if(m.team!==team){m.r=10;test(m);}}}

// ---------- 听觉 ----------
let noises=[];
function noise(x,y,type,loud,src){noises.push({x,y,type,loud,src:src||null,team:src&&src.team&&src.team!=='neutral'?src.team:null,t:0,life:type==='boom'?1.4:type==='step'?0.55:0.9});if(noises.length>90)noises.shift();if(type!=='step')aiHear(x,y,loud,src);}
function aiHear(x,y,loud,src){const R=900*loud;for(const h of hams){if(h.ctl!=='ai'||!h.alive||(src&&src.team===h.team)||h.ai.target)continue;const d=Math.hypot(h.x-x,h.y-y);if(d>R)continue;if(!h.ai.inv||d<Math.hypot(h.x-h.ai.inv.x,h.y-h.ai.inv.y))h.ai.inv={x:x+rand(-60,60),y:y+rand(-60,60),t:5};}}
function wRange(h){const W=WEAPONS[h.weapon.id];return W.kind==='melee'?W.reach*(1+0.1*(h.weapon.lvl-1)):(W.range||0)*h.st.rangeK;}
