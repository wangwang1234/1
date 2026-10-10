"""第三轮：生活场景组合与主要杂物精修。全量构建在所有 env_* 后执行。

物件只放在已有掩体顶面；低矮地面杂物通过 MapView 的净空检查。
按游戏俯视角归纳可读形体，避免用噪声和高密度撒点充数。
"""
import math
import random
import bpy
from lib import shapes, style
from lib.anim import deg

T = style.MAT_TOON
W = "M_toon_wood"
C = "M_toon_ceramic"
F = style.MAT_FLAT
M = style.MAT_METAL
CL = "M_toon_cloth"


def module(name, parts):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    mesh = shapes.join(parts, name + "_mesh")
    shapes.bake_outline_normals(mesh)
    mesh.parent = root
    return root


def move(parts, x=0, y=0, z=0, a=0, scale=1):
    for p in parts:
        shapes.transform(p, loc=(x, y, z), rot=(0, 0, a), scale=(scale,)*3)
    return parts


def book(color="dress_sage", width=.38, depth=.28, height=.065):
    p = [shapes.rounded_box("pages", (0,0,height/2), (width-.016,depth-.025,height-.016), .006,1,"paper",T)]
    for z in (.004,height-.004):
        p.append(shapes.rounded_box("cover",(0,0,z),(width,depth,.008),.008,2,color,T))
    p.append(shapes.rounded_box("spine",(0,-depth/2+.006,height/2),(width,.014,height),.006,2,color,T))
    for k in range(3):
        p.append(shapes.rounded_box("page_line",(width/2-.007,0,.02+k*.011),(.001,depth-.04,.0012),0,1,"towel_stripe",F))
    p.append(shapes.rounded_box("label",(.02,.02,height+.0008),(width*.46,depth*.26,.001),.006,2,"dress_paper",F))
    for y in (.005,.026):
        p.append(shapes.rounded_box("title",(.02,y,height+.002),(width*.3,.003,.001),0,1,"dress_ink",F))
    p.append(shapes.rounded_box("ribbon",(.09,depth/2+.016,height*.5),(.024,.08,.002),0,1,"dress_clay",F))
    return p


def mug(color="dress_sage", r=.1, height=.2):
    p = [shapes.lathe("cup",[(r*.8,0),(r*.87,.012),(r,height-.012),(r*.98,height),(r*.85,height+.003),(r*.82,height-.025),(r*.69,.03)],32,"Z",(0,0,0),color,C),
         shapes.cylinder("coffee",(0,0,height-.033),r*.8,None,.003,"Z",32,0,"dress_coffee",T),
         shapes.torus("handle",(r*1.12,0,height*.52),r*.48,r*.115,"Y",24,6,color,C,scale=(.88,1,1.15)),
         shapes.torus("foot",(0,0,.011),r*.81,.006,"Z",28,4,color,C)]
    return p


def pencil():
    p = [shapes.cylinder("lacquer",(0,0,.019),.014,None,.38,"Y",6,0,"dress_ochre",T),
         shapes.cylinder("wood_tip",(0,.22,.019),.0,.014,.06,"Y",6,0,"cardboard_light",T),
         shapes.cylinder("graphite",(0,.25,.019),.0,.005,.015,"Y",6,0,"dress_ink",T),
         shapes.cylinder("ferrule",(0,-.205,.019),.015,None,.027,"Y",12,.002,"gun_steel",M),
         shapes.cylinder("eraser",(0,-.23,.019),.014,None,.025,"Y",12,.003,"eraser_pink",T)]
    return p


def plate():
    return [shapes.lathe("plate",[(0,.008),(.14,.008),(.18,.019),(.21,.036),(.214,.044),(.2,.047),(.172,.034),(.135,.019),(0,.019)],36,"Z",(0,0,0),"dress_paper",C),
            shapes.torus("glaze_band",(0,0,.042),.195,.0028,"Z",36,4,"dress_sage",F)]


def cookie(x=0,y=0,z=0):
    rng = random.Random(57)
    p = [shapes.cylinder("biscuit",(0,0,.022),.14,None,.044,"Z",24,.009,"dress_biscuit",T)]
    for k in range(8):
        a=k*2.4; r=.035+.068*(k%3)/2
        p.append(shapes.uv_sphere("chocolate",(math.cos(a)*r,math.sin(a)*r,.046),(.014,.021,.004),8,4,"dress_coffee",T))
    for k in range(14):
        a=k*math.tau/14
        p.append(shapes.uv_sphere("crust",(.136*math.cos(a),.136*math.sin(a),.022),(.007,.007,.011),6,4,"dress_ochre",T))
    return move(p,x,y,z)


def pen_cup():
    p=[shapes.lathe("holder",[(.067,0),(.078,.01),(.078,.18),(.074,.19),(.062,.186),(.061,.025)],24,"Z",(0,0,0),"dress_ink",T)]
    for k in range(3):
        objs=pencil()
        for obj in objs:
            shapes.transform(obj,rot=(deg(78+k*4),deg(-9+k*8),0),scale=(.75,)*3,loc=(-.03+k*.03,0,.21))
        p.extend(objs)
    return p


def study_tray():
    p=[shapes.rounded_box("felt",(0,0,.006),(.96,.55,.012),.016,2,"dress_felt",CL)]
    p += move(book("dress_ink"),-.16,.035,.012,deg(-7))
    p += move(mug("dress_sage",.09,.19),.31,.06,.014)
    p += move(pencil(),-.13,-.195,.015,deg(78))
    p += move(pen_cup(),-.37,.14,.014,scale=.82)
    p.append(shapes.rounded_box("note",(.15,-.14,.014),(.15,.12,.002),0,1,"dress_paper",F,rot=(0,0,deg(-12))))
    for k in range(3):
        p.append(shapes.rounded_box("note_ink",(.15,-.12-k*.023,.016),(.1,.004,.001),0,1,"dress_ink",F))
    return module("env_dress_study",p)


def kitchen_tray():
    p=[shapes.rounded_box("linen",(-.16,0,.004),(.62,.52,.008),.012,2,"dress_paper",CL)]
    for x in (-.425,-.405):
        p.append(shapes.rounded_box("linen_border",(x,0,.009),(.006,.46,.001),0,1,"dress_sage",F))
    p += move(plate(),-.14,0,.012)
    p += cookie(-.15,-.03,.026)
    p += move(mug("dress_clay",.09,.18),.31,.07,.01)
    p.append(shapes.capsule("spoon_handle",(.17,-.1,.018),(.36,-.1,.018),.012,8,2,"gun_steel",M))
    p.append(shapes.uv_sphere("spoon_bowl",(.15,-.1,.018),(.045,.022,.006),16,6,"gun_steel",M))
    p.append(shapes.rounded_box("teabag",(.36,-.18,.015),(.09,.07,.014),.007,2,"dress_paper",T))
    return module("env_dress_kitchen",p)


def living_tray():
    p=move(book("dress_clay",.46,.33,.065),-.17,.015,0,deg(4))
    p+=move(book("dress_ink",.39,.29,.055),-.14,0,.065,deg(-8))
    p+=move(mug("dress_paper",.09,.17),.31,.055)
    p.append(shapes.rounded_box("remote",(.18,-.16,.025),(.35,.1,.05),.018,2,"dress_ink",T))
    for x in (.1,.14,.18,.22,.26):
        p.append(shapes.rounded_box("button",(x,-.16,.051),(.013,.018,.002),.003,1,"gun_light",F))
    return module("env_dress_living",p)


def study_notes():
    p = move(book("dress_sage",.36,.27,.055),-.25,.09,0,deg(5))
    p.append(shapes.rounded_box("draft",(.11,-.035,.003),(.53,.41,.006),.007,1,"dress_paper",T))
    for k in range(5):
        p.append(shapes.rounded_box("draft_line",(.10,.1-k*.028,.007),(.34-.04*(k%2),.003,.001),0,1,"towel_stripe",F))
    for x in (-.05,.095,.23):
        p.append(shapes.torus("sketch",(x,-.13,.008),.038,.002,"Z",20,4,"dress_ink",F,scale=(1,1,.4)))
    p += move(pencil(),.35,.09,.01,deg(15),.62)
    p.append(shapes.torus("tape",(-.34,-.13,.02),.055,.025,"Z",24,6,"dress_ochre",T))
    p.append(shapes.rounded_box("eraser",(-.16,-.14,.012),(.10,.06,.025),.006,2,"eraser_pink",T))
    return module("env_dress_study_notes",p)


def kitchen_prep():
    p=[shapes.rounded_box("board",(-.08,0,.012),(.64,.5,.024),.025,3,"floor_wood_light",W)]
    p.append(shapes.rounded_box("board_handle",(.29,0,.011),(.2,.13,.022),.025,2,"floor_wood_light",W))
    for x,y in ((-.26,-.13),(-.04,.02)):
        p.append(shapes.cylinder("fruit_slice",(x,y,.045),.085,None,.026,"Z",24,.004,"dress_ochre",T))
        p.append(shapes.cylinder("fruit_inside",(x,y,.059),.072,None,.001,"Z",24,0,"dress_paper",F))
        for k in range(6):
            a=k*math.tau/6
            p.append(shapes.rounded_box("segment",(x+math.cos(a)*.038,y+math.sin(a)*.038,.060),(.052,.003,.001),0,1,"dress_ochre",F,rot=(0,0,a)))
    p.append(shapes.rounded_box("blade",(-.13,.17,.03),(.23,.057,.006),.006,2,"gun_steel",M,rot=(0,0,deg(-8))))
    p.append(shapes.rounded_box("knife_grip",(.07,.142,.035),(.15,.044,.021),.008,2,"dress_ink",T,rot=(0,0,deg(-8))))
    p.append(shapes.rounded_box("folded_linen",(.35,-.16,.01),(.19,.15,.02),.009,2,"dress_paper",CL))
    return module("env_dress_kitchen_prep",p)


def living_games():
    p=[]
    for x,y,c,a in ((-.30,.08,"dress_sage",8),(-.10,-.12,"dress_clay",-12),(.09,.06,"dress_ochre",18)):
        p.append(shapes.rounded_box("block",(x,y,.05),(.14,.14,.10),.013,2,c,T,rot=(0,0,deg(a))))
        p.append(shapes.rounded_box("stamp",(x,y,.101),(.06,.06,.001),.009,1,"dress_paper",F,rot=(0,0,deg(a))))
    p.append(shapes.rounded_box("playing_card",(.31,-.01,.003),(.21,.33,.006),.015,2,"dress_paper",T,rot=(0,0,deg(-12))))
    p.append(shapes.torus("card_print",(.31,-.01,.007),.045,.004,"Z",20,4,"dress_clay",F,scale=(1,1,.4)))
    return module("env_dress_living_games",p)


def paper():
    p=[shapes.rounded_box("page",(0,0,.002),(.57,.75,.004),.008,2,"dress_paper",T)]
    p.append(shapes.rounded_box("header",(-.14,.27,.005),(.17,.025,.001),0,1,"dress_ink",F))
    for k in range(7):
        length=(.39,.41,.3,.37,.43,.25,.35)[k]
        p.append(shapes.rounded_box("text",(-.21+length/2,.18-k*.043,.005),(length,.004,.001),0,1,"towel_stripe",F))
    for x,y in ((-.13,-.18),(.09,-.19)):
        p.append(shapes.torus("diagram",(x,y,.006),.055,.003,"Z",20,4,"dress_sage",F,scale=(1,1,.25)))
    return module("env_deco_paper",p)


def rug():
    p=[shapes.rounded_box("rug",(0,0,.008),(2.35,1.35,.016),.02,2,"dress_felt",CL)]
    for x in (-1.08,1.08):
        p.append(shapes.rounded_box("edge",(x,0,.017),(.025,1.21,.001),0,1,"dress_sage",F))
    for y in (-.59,.59):
        p.append(shapes.rounded_box("edge",(0,y,.017),(2.17,.025,.001),0,1,"dress_sage",F))
    for x in (-.75,0,.75):
        diamond=shapes.rounded_box("motif",(x,0,.018),(.36,.36,.001),0,1,"dress_sage",F,rot=(0,0,deg(45)))
        p.append(diamond)
        p.append(shapes.rounded_box("motif_center",(x,0,.019),(.25,.25,.001),0,1,"dress_felt",F,rot=(0,0,deg(45))))
    for x in (-1.19,1.19):
        for k in range(18):
            p.append(shapes.rounded_box("fringe",(x,-.57+k*.066,.007),(.07,.012,.01),.003,1,"dress_paper",CL))
    return module("env_dress_rug",p)


def kitchen_rug():
    p=[shapes.rounded_box("woven_mat",(0,0,.008),(2.3,1.32,.016),.018,2,"dress_sage",CL)]
    for x in (-1.0,-.96, .96,1.0):
        p.append(shapes.rounded_box("stripe",(x,0,.017),(.019,1.2,.001),0,1,"dress_paper",F))
    for y in (-.55,.55):
        p.append(shapes.rounded_box("hem",(0,y,.017),(2.05,.035,.001),0,1,"dress_felt",F))
    for x in (-1.17,1.17):
        for k in range(18):
            p.append(shapes.rounded_box("tassel",(x,-.57+k*.066,.007),(.075,.012,.008),.003,1,"dress_paper",CL))
    return module("env_dress_kitchen_rug",p)


def notebook():
    return module("env_deco_notebook",book("dress_sage",.58,.42,.065))


def puzzle():
    # 完整的拼图轮廓，凹槽不是涂黑的圆斑。
    points=[(-.15,-.15),(-.04,-.15),(-.04,-.2),(.04,-.2),(.04,-.15),(.15,-.15),(.15,-.04),(.2,-.04),(.2,.04),(.15,.04),(.15,.15),(.04,.15),(.04,.1),(-.04,.1),(-.04,.15),(-.15,.15),(-.15,.04),(-.1,.04),(-.1,-.04),(-.15,-.04)]
    p=[shapes.extrude_profile("piece",points,.016,center=(0,0,.008),plane="XY",bevel=.003,color="dress_sage")]
    p.append(shapes.rounded_box("print",(0,-.03,.017),(.18,.11,.001),.004,1,"dress_ochre",F,rot=(0,0,deg(25))))
    return module("env_deco_puzzle",p)


def wood_floor():
    p=[shapes.rounded_box("sub",(0,0,-.026),(2,2,.03),0,1,"floor_wood_dark",T)]
    for i in range(8):
        x=-1+(i+.5)*.25
        cut=(-.62,.24,.68,-.12)[i%4]
        for k,(a,b) in enumerate(zip((-1,cut),(cut,1))):
            color="floor_wood_light" if (i+k)%7==0 else "floor_wood"
            p.append(shapes.rounded_box("plank",(x,(a+b)/2,-.009),(.246,b-a-.004,.012),.002,1,color,T))
    return module("env_floor_wood",p)


def carpet():
    return module("env_floor_carpet",[shapes.rounded_box("cloth",(0,0,-.004),(2,2,.012),0,1,"dress_felt",T)])


def build(ctx):
    modules=[study_tray(),kitchen_tray(),living_tray(),study_notes(),kitchen_prep(),living_games(),paper(),notebook(),puzzle(),rug(),kitchen_rug(),wood_floor(),carpet(),module("env_deco_cookie",cookie())]
    return ctx.Built([],extra_exports=[(r.name,[r]) for r in modules],previews=[],item_previews=[("game",{"res":640})])
