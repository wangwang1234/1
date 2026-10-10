"""第二轮家具精修。全量生成顺序在 env_kit / env_zone_kit 之后。

沿用现有模块名和外包尺寸，不改变战斗碰撞。细节集中于可读的接缝、
结构分件、金属把手和少量使用痕迹，不用随机撒点或高频贴图。
"""
import math
import bpy
from lib import shapes, style
from lib.anim import deg
from assets.env import env_kit, env_zone_kit

W = "M_toon_wood"
C = "M_toon_ceramic"
T = style.MAT_TOON
M = style.MAT_METAL
F = style.MAT_FLAT


def module(name, parts):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    mesh = shapes.join(parts, name+"_mesh")
    shapes.bake_outline_normals(mesh)
    mesh.parent = root
    return root


def counter():
    p = [
        shapes.rounded_box("frame",(0,0,0.3),(1.0,0.68,0.56),0.018,3,"wood_dark",W),
        shapes.rounded_box("top",(0,0,0.6),(1.04,0.72,0.06),0.013,3,"floor_wood_light",W),
        shapes.rounded_box("plinth",(0,0,0.03),(0.96,0.64,0.06),0.009,2,"wood_dark",W),
    ]
    for side in (-1,1):
        for row,z in enumerate((0.20,0.435)):
            p.append(shapes.rounded_box(f"drawer{side}{row}",(0,side*0.343,z),(0.9,0.014,0.205),0.008,2,"wood",W))
            p.append(shapes.rounded_box(f"inset{side}{row}",(0,side*0.352,z),(0.8,0.006,0.14),0.005,2,"floor_wood_light",W))
            for x in (-0.075,0.075):
                p.append(shapes.cylinder(f"mount{side}{row}{x}",(x,side*0.362,z+0.02),0.016,None,0.012,"Y",12,0.002,"gun_dark",M))
            p.append(shapes.capsule(f"handle{side}{row}",(-0.075,side*0.375,z+0.02),(0.075,side*0.375,z+0.02),0.008,8,2,"gun_steel",M))
    # 台面板拼缝、角部磨痕和一处淡淡杯圈；夜光下仍读成木头。
    for x in (-0.17,0.17):
        p.append(shapes.rounded_box(f"join{x}",(x,0,0.6305),(0.003,0.64,0.001),0,1,"floor_wood",F))
    p.append(shapes.torus("cup_ring",(0.26,-0.12,0.632),0.076,0.0025,"Z",32,4,"floor_wood",F,scale=(1,1,0.3)))
    for x,y,length in ((-0.38,0.22,0.075),(0.43,-0.18,0.06)):
        p.append(shapes.rounded_box("worn_edge",(x,y,0.632),(length,0.004,0.001),0,1,"cardboard_light",F,rot=(0,0,deg(-12))))
    return module("env_counter",p)


def detailed_book(color,h=0.62,t=0.12,d=0.44):
    p = env_kit.book(color,h,t,d)
    for side in (-1,1):
        p.append(shapes.rounded_box(f"hinge{side}",(side*(t/2-0.009),-d/2-0.002,h/2),(0.007,0.006,h*0.9),0.002,1,color,T))
    for k in range(5):
        p.append(shapes.rounded_box(f"page_line{k}",(0,d/2+0.003,0.08+k*(h-0.16)/4),(t-0.025,0.001,0.002),0,1,"towel_stripe",F))
    p.append(shapes.rounded_box("bookmark",(0.02,0.035,h+0.003),(0.018,0.23,0.002),0,1,"towel_stripe",F))
    return p


def shelf():
    p=[
        shapes.rounded_box("back",(0,0.18,0.5),(2.0,0.06,1.0),0.009,2,"wood_dark",W),
        shapes.rounded_box("board",(0,0,0.03),(2.0,0.42,0.06),0.009,2,"wood",W),
        shapes.rounded_box("top",(0,0,0.98),(2.04,0.44,0.05),0.009,2,"floor_wood_light",W)
    ]
    for x in (-0.98,0.98):
        p.append(shapes.rounded_box(f"upright{x}",(x,0,0.51),(0.035,0.42,0.94),0.006,2,"wood",W))
    for x in (-0.96,0.96):
        for z in (0.15,0.86):
            p.append(shapes.cylinder(f"screw{x}{z}",(x,-0.216,z),0.009,None,0.003,"Y",8,0,"gun_steel",M))
    colors=("book_blue","book_green","book_yellow","book_purple","book_red","book_orange")
    x=-0.9
    for i in range(11):
        t=(0.12,0.16,0.13)[i%3]; h=(0.72,0.85,0.64,0.77)[i%4]
        objs=detailed_book(colors[i%6],h,t,0.36)
        for obj in objs:
            shapes.transform(obj,rot=(0,deg(-4 if i==4 else 0),0),loc=(x+t/2,-0.02,0.06))
        p.extend(objs); x+=t+0.017
    return module("env_shelf",p)


def cabinet():
    root=env_zone_kit.cabinet()
    mesh=root.children[0]
    # 给木件明确的材质种类，玻璃/金属仍保留独立表面。
    for i,mat in enumerate(mesh.data.materials):
        if mat.name==T: mesh.data.materials[i]=shapes.ensure_material(W)
    p=[mesh]
    for x in (-0.5,0.5):
        for z in (0.43,1.4):
            p.append(shapes.rounded_box(f"rail{x}{z}",(x,-0.03,z),(0.8,0.008,0.025),0.003,2,"floor_wood_light",W))
        for z in (0.38,1.45):
            p.append(shapes.rounded_box(f"hinge{x}{z}",(x+(-0.4 if x<0 else 0.4),-0.037,z),(0.022,0.012,0.05),0.003,2,"gun_dark",M))
    # 金属铭牌，文字归纳成细线，避免虚构文字乱码。
    p.append(shapes.rounded_box("maker_plate",(0.66,-0.029,0.38),(0.1,0.004,0.043),0.005,2,"brass",M))
    bpy.data.objects.remove(root,do_unlink=True)
    return module("env_cabinet",p)


def fridge():
    root=env_zone_kit.fridge(); p=[root.children[0]]
    for z in (0.64,1.63):
        p.append(shapes.rounded_box(f"seal{z}",(0,-0.025,z),(1.86,0.014,0.009),0.002,1,"can_grey_dark",T))
    for x in (-0.91,0.91):
        p.append(shapes.rounded_box(f"seal_side{x}",(x,-0.025,1.13),(0.008,0.014,0.96),0.002,1,"can_grey_dark",T))
    p.append(shapes.rounded_box("badge",(0.68,-0.027,1.44),(0.17,0.008,0.052),0.006,2,"gun_steel",M))
    # 少量低饱和磨痕，避开识别色；格栅增加底部一道卷边。
    p.append(shapes.rounded_box("vent_lip",(0,-0.036,0.07),(1.78,0.014,0.024),0.005,2,"gun_steel",M))
    for x,z in ((-0.67,0.73),(0.35,0.79)):
        p.append(shapes.rounded_box("scuff",(x,-0.023,z),(0.07,0.002,0.007),0,1,"towel_cream",F,rot=(0,deg(-9),0)))
    bpy.data.objects.remove(root,do_unlink=True)
    return module("env_fridge",p)


def sofa_skirt():
    # 低饱和织物代替亮紫塑料，仍保持现有 2 米段和 0.36 米高度。
    p=[shapes.rounded_box("cloth",(0,0.08,0.26),(2,0.16,0.2),0.018,3,"carpet","M_toon_cloth")]
    for i in range(8):
        x=-0.88+i*0.25
        p.append(shapes.capsule(f"fold{i}",(x,-0.004,0.17),(x+0.018,-0.004,0.34),0.009,6,1,"carpet_light","M_toon_cloth"))
    for z in (0.18,0.33):
        p.append(shapes.rounded_box(f"seam{z}",(0,-0.009,z),(1.95,0.003,0.004),0,1,"towel_stripe",F))
    return module("env_sofa_skirt",p)


def build(ctx):
    modules=[counter(),shelf(),cabinet(),fridge(),sofa_skirt()]
    for color in ("book_blue","book_red","book_green","book_yellow","book_purple","book_orange"):
        modules.append(module("env_"+color,detailed_book(color)))
    return ctx.Built([],extra_exports=[(m.name,[m]) for m in modules],previews=[],item_previews=[("game",{"res":512})])
