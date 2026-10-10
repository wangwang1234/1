"""画面升级第一轮：薄缝地板、克制的地毯纹样、有真实口沿的陶盆。

只替换原有模块，不改变地图障碍尺寸、分区或碰撞。与资产管线相同：
blender --background --python tools/blender/build.py -- --asset env_visual_kit
"""
import math
import random
import bpy
from lib import shapes, style
from lib.anim import deg

T = style.MAT_TOON
F = style.MAT_FLAT


def module(name, parts):
    root = bpy.data.objects.new(name, None)
    bpy.context.scene.collection.objects.link(root)
    mesh = shapes.join(parts, name + "_mesh")
    shapes.bake_outline_normals(mesh)
    mesh.parent = root
    return root


def wood_floor():
    rng = random.Random(43)
    p = [shapes.rounded_box("underlay", (0, 0, -0.025), (2, 2, 0.035), 0, 1, "floor_wood_dark", T)]
    for i in range(8):
        x = -1 + (i + 0.5) * 0.25
        cut = (-0.66, 0.22, 0.68, -0.15)[i % 4]
        edges = [-1, cut, 1]
        for k, (a, b) in enumerate(zip(edges[:-1], edges[1:])):
            color = "floor_wood_light" if (i + k) % 5 == 0 else "floor_wood"
            p.append(shapes.rounded_box(f"board{i}_{k}", (x, (a+b)*0.5, -0.005), (0.246, b-a-0.006, 0.015), 0.003, 2, color, T))
        # 少量长形木结，避免原版每块板上的黑圆点重复成图案。
        if i in (2, 6):
            p.append(shapes.uv_sphere(f"knot{i}", (x+0.03, rng.uniform(-0.6,0.6), 0.003), (0.008,0.045,0.0007), 12, 3, "floor_wood_dark", F))
    return module("env_floor_wood", p)


def tile_floor():
    p = [shapes.rounded_box("grout", (0,0,-0.02), (2,2,0.03), 0,1,"wood_dark",T)]
    for i in range(4):
        for j in range(4):
            c = "tile_cream" if (i+j)%2==0 else "tile_terracotta"
            p.append(shapes.rounded_box(f"tile{i}{j}",(-0.75+i*0.5,-0.75+j*0.5,-0.002),(0.492,0.492,0.018),0.005,2,c,T))
    return module("env_floor_tile",p)


def carpet_floor():
    p = [shapes.rounded_box("cloth", (0,0,-0.006), (2,2,0.016),0,1,"carpet",T)]
    # 稀疏的同色织纹，保留空白；连续纹理在 Godot 材质里加。
    for i in range(4):
        for j in range(4):
            if (i+j)%2==0:
                for side in (-1,1):
                    p.append(shapes.rounded_box(f"stitch{i}{j}{side}",(-0.75+i*0.5+side*0.018,-0.75+j*0.5,0.003),(0.018,0.085,0.001),0,1,"carpet_light",F,rot=(0,0,deg(side*35))))
    return module("env_floor_carpet",p)


def ceramic_pot():
    p=[shapes.lathe("ceramic",[(0.3,0),(0.31,0.04),(0.41,0.41),(0.438,0.44),(0.451,0.46),(0.451,0.51),(0.435,0.53),(0.402,0.525),(0.394,0.492)],48,"Z",(0,0,0),"tile_terracotta",T),
       shapes.cylinder("soil",(0,0,0.481),0.392,None,0.014,"Z",40,0,"wood_dark",T),
       shapes.torus("foot",(0,0,0.025),0.30,0.012,"Z",40,6,"tile_cream",T)]
    rng=random.Random(12)
    for k in range(10):
        a=k*math.tau/10; rr=rng.uniform(0.23,0.36)
        p.append(shapes.uv_sphere(f"pebble{k}",(math.cos(a)*rr,math.sin(a)*rr,0.492),(0.015,0.023,0.01),8,4,"seed_shell",T))
    for ring,(n,rr,h,size) in enumerate(((8,0.27,0.555,0.15),(6,0.16,0.625,0.13),(4,0.065,0.69,0.10))):
        for k in range(n):
            a=k/n*math.tau+ring*0.41
            leaf=shapes.quad_sphere(f"leaf{ring}{k}",(0,0,0),(size*0.58,size,size*0.32),2,"clover_dark" if ring==0 else "clover",T)
            shapes.transform(leaf,rot=(deg(-37+ring*14),0,0)); shapes.transform(leaf,loc=(0,rr*0.6,0)); shapes.transform(leaf,rot=(0,0,a)); shapes.transform(leaf,loc=(0,0,h)); p.append(leaf)
    return module("env_pot",p)


def build(ctx):
    modules=[wood_floor(),tile_floor(),carpet_floor(),ceramic_pot()]
    return ctx.Built([],extra_exports=[(m.name,[m]) for m in modules],previews=[],item_previews=[("game",{})])
