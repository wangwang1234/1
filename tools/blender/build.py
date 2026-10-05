"""资产构建入口（在 Blender 后台运行）。

    blender --background --python tools/blender/build.py -- --asset chr_hamster
    blender --background --python tools/blender/build.py -- --category weapons
    blender --background --python tools/blender/build.py -- --all
    可选：--no-preview（只导出模型）  --preview-only（只渲染预览）  --list

每个资产脚本 tools/blender/assets/<类别>/<名称>.py 提供 build(ctx)，返回 Built(...)。
输出：模型 game/assets/models/<类别>/<名称>.glb；预览 review/previews/<类别>/<名称>_*.png
"""
import importlib
import importlib.util
import os
import sys
import time
import traceback

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
sys.path.insert(0, HERE)

import bpy  # noqa: E402

from lib import export, materials, preview, style  # noqa: E402

MODELS = os.path.join(ROOT, "game", "assets", "models")
PREVIEWS = os.path.join(ROOT, "review", "previews")
PALETTE = os.path.join(ROOT, "game", "assets", "textures", "palette.png")


class Built:
    def __init__(self, roots, animations=False, previews=None, outline=0.0035, extra_exports=None, after_export=None):
        self.roots = roots                  # 导出的根物体列表
        self.animations = animations
        self.previews = previews            # [(后缀, 视角, {参数})]；None = 默认一组
        self.outline = outline
        self.extra_exports = extra_exports or []   # [(文件名, [物体])] 同一脚本导出多个 glb
        self.after_export = after_export     # 预览前回调（例如摆姿势）


class Ctx:
    def __init__(self, name, category, args):
        self.name = name
        self.category = category
        self.args = args
        self.root = ROOT
        self.Built = Built

    def model_path(self, name=None):
        return os.path.join(MODELS, self.category, (name or self.name) + ".glb")

    def preview_path(self, suffix):
        return os.path.join(PREVIEWS, self.category, f"{self.name}_{suffix}.png")


DEFAULT_PREVIEWS = [
    ("game", "game", {}),
    ("front", "front", {}),
    ("side", "side", {}),
    ("three_quarter", "three_quarter", {}),
]


def discover():
    out = {}
    adir = os.path.join(HERE, "assets")
    for cat in sorted(os.listdir(adir)):
        cdir = os.path.join(adir, cat)
        if not os.path.isdir(cdir):
            continue
        for fn in sorted(os.listdir(cdir)):
            if fn.endswith(".py") and not fn.startswith("_"):
                out[fn[:-3]] = (cat, os.path.join(cdir, fn))
    return out


def fresh_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.unit_settings.system = "METRIC"
    sc.render.fps = 30


def load_module(name, path):
    spec = importlib.util.spec_from_file_location(f"asset_{name}", path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def build_one(name, cat, path, args):
    t0 = time.time()
    fresh_scene()
    materials.palette_image(PALETTE)
    mod = load_module(name, path)
    ctx = Ctx(name, cat, args)
    res = mod.build(ctx)
    if not args.get("preview_only"):
        materials.reset_for_export()
        if res.roots:
            export.export_glb(ctx.model_path(), res.roots, animations=res.animations)
        for (fname, objs) in res.extra_exports:
            export.export_glb(ctx.model_path(fname), objs, animations=False)
    if not args.get("no_preview"):
        if res.after_export:
            res.after_export(ctx)
        objs = []
        for r in res.roots:
            objs.append(r)
            objs.extend(r.children_recursive)
        for (_, eo) in res.extra_exports:
            for r in eo:
                if r not in objs:
                    objs.append(r)
                    objs.extend(r.children_recursive)
        preview.prepare(objs, res.outline)
        specs = res.previews if res.previews is not None else DEFAULT_PREVIEWS
        for (suffix, view, kw) in specs:
            kw = dict(kw)
            light = kw.pop("light", "studio")
            pre = kw.pop("pre", None)
            if pre:
                pre(ctx)
                materials.setup_preview_materials()
            preview.setup_lighting(light)
            only = kw.pop("only", None)
            vis = objs
            if only is not None:
                vis = [o for o in objs if only(o)]
                for o in objs:
                    o.hide_render = o not in vis
            out = kw.pop("out", None)
            preview.render(out or ctx.preview_path(suffix), [o for o in vis if o.type == "MESH" and not o.hide_render], view=view, **kw)
            for o in objs:
                o.hide_render = False
    print(f"[build] {cat}/{name} ok ({time.time() - t0:.1f}s)")


def parse(argv):
    args = {"assets": [], "category": None, "all": False, "no_preview": False, "preview_only": False, "list": False}
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--asset":
            args["assets"].append(argv[i + 1])
            i += 1
        elif a == "--category":
            args["category"] = argv[i + 1]
            i += 1
        elif a == "--all":
            args["all"] = True
        elif a == "--no-preview":
            args["no_preview"] = True
        elif a == "--preview-only":
            args["preview_only"] = True
        elif a == "--list":
            args["list"] = True
        i += 1
    return args


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    args = parse(argv)
    reg = discover()
    if args["list"]:
        for n, (c, _) in reg.items():
            print(f"{c}/{n}")
        return
    names = list(args["assets"])
    if args["category"]:
        names += [n for n, (c, _) in reg.items() if c == args["category"]]
    if args["all"]:
        names = list(reg.keys())
    if not names:
        print("用法：-- --asset <名称> | --category <类别> | --all [--no-preview]")
        return
    failed = []
    for n in names:
        if n not in reg:
            print(f"[build] 未找到资产：{n}")
            failed.append(n)
            continue
        cat, path = reg[n]
        try:
            build_one(n, cat, path, args)
        except Exception:
            traceback.print_exc()
            failed.append(n)
    if failed:
        print("[build] 失败：", ", ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
