"""第三轮主交互物件精修；全量构建时覆盖 prop_kit 的纸箱与台灯。"""
import math
import bpy
from lib import shapes, style
from assets.props import prop_kit

T=style.MAT_TOON
M=style.MAT_METAL
F=style.MAT_FLAT


def lamp():
    p=[shapes.cylinder("weighted_base",(0,0,.024),.144,None,.048,"Z",36,.008,"dress_ink",M),
       shapes.torus("base_lip",(0,0,.041),.137,.006,"Z",36,5,"gun_light",M),
       shapes.cylinder("socket",(0,0,.069),.032,None,.075,"Z",16,.005,"dress_ink",M),
       shapes.cylinder("stem",(0,0,.32),.012,None,.53,"Z",16,.002,"gun_steel",M),
       shapes.cylinder("hinge",(0,0,.59),.027,None,.035,"X",20,.004,"dress_ink",M),
       shapes.cylinder("hinge_screw",(.021,0,.59),.012,None,.009,"X",12,0,"gun_steel",M),
       shapes.lathe("enamel_shade",[(.17,.53),(.17,.54),(.14,.565),(.1,.63),(.06,.675),(.031,.695),(.023,.69),(.05,.67),(.09,.624),(.131,.563),(.161,.535)],40,"Z",(0,0,0),"dress_sage",T,cap_bottom=False),
       shapes.torus("rolled_rim",(0,0,.535),.167,.006,"Z",40,6,"dress_paper",T),
       shapes.cylinder("switch",(.074,-.04,.051),.018,None,.012,"Z",16,.003,"dress_paper",T)]
    for y in (-.03,-.015,0,.015,.03):
        p.append(shapes.rounded_box("vent",(0,y,.687),(.047,.005,.002),.001,1,"dress_ink",F))
    mesh=shapes.join(p,"prop_lamp_mesh")
    bulb=shapes.uv_sphere("bulb",(0,0,.557),(.045,.045,.042),16,8,"bulb",style.MAT_EMISSIVE)
    root=prop_kit._root("prop_lamp",[mesh,bulb])
    shapes.empty("light",(0,0,.5),parent=root)
    return root


def box():
    root=prop_kit.box()
    p=[root.children[0]]
    p.append(shapes.rounded_box("shipping_label",(.19,-.12,.610),(.23,.3,.002),.007,2,"dress_paper",F))
    for k in range(11):
        x=.098+k*.016
        p.append(shapes.rounded_box("barcode",(x,-.175,.612),(.004 if k%3 else .008,.09,.001),0,1,"dress_ink",F))
    for k in range(3):
        p.append(shapes.rounded_box("label_text",(.188,-.09+k*.025,.612),(.15-.027*k,.004,.001),0,1,"dress_ink",F))
    # 胶带折皱与压边都是低对比，顶面从游戏镜头也有信息。
    for y in (-.25,-.17,.16):
        p.append(shapes.rounded_box("tape_crease",(0,y,.610),(.105,.003,.001),0,1,"towel_stripe",F))
    for x in (-.32,.32):
        p.append(shapes.rounded_box("fold",(x,0,.603),(.004,.57,.001),0,1,"cardboard_dark",F))
    bpy.data.objects.remove(root,do_unlink=True)
    return prop_kit._root("prop_box",[shapes.join(p,"prop_box_mesh")])


def build(ctx):
    modules=[lamp(),box()]
    return ctx.Built([],extra_exports=[(r.name,[r]) for r in modules],previews=[],item_previews=[("game",{"res":640}), ("three_quarter",{"res":640})])
