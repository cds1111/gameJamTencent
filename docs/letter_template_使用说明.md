# LetterTemplate 使用说明

## 功能概述

`LetterTemplate` 是一个可放进关卡里的字母实体模板。

它支持：

- 直接输入一个字母并显示
- 作为实体参与碰撞
- 通过 `Shift` 能力在大小写之间切换
- 切换时同步修改显示大小和碰撞箱大小


## 相关文件

- 场景：`res://scenes/interactables/LetterTemplate.tscn`
- 脚本：`res://scripts/interactables/LetterTemplate.gd`
- Shift 能力：`res://scripts/abilities/Ability_CaseToggle.gd`
- Shift 模式入口：`res://scripts/player/player_shift_handler.gd`


## 如何使用模板

1. 在关卡场景中实例化 `LetterTemplate.tscn`
2. 选中该节点，在 Inspector 中设置导出参数
3. 至少填写 `character`

常用参数说明：

- `character`
  - 要显示的字母
  - 只会取第一个字符
- `start_uppercase`
  - 是否以大写状态开始
- `uppercase_texture`
  - 大写状态使用的贴图
  - 如果留空，则回退为文字显示
- `lowercase_texture`
  - 小写状态使用的贴图
  - 如果留空，则回退为文字显示
- `uppercase_collision_size`
  - 大写状态的碰撞箱尺寸
- `lowercase_collision_size`
  - 小写状态的碰撞箱尺寸
- `uppercase_visual_scale`
  - 大写状态的显示缩放
- `lowercase_visual_scale`
  - 小写状态的显示缩放


## Shift 切换大小写

目前已经新增一个 Shift 能力：`CaseToggle`

触发方式：

- 按下 `Shift`
- 会发送一次 `shift_ability_used("CaseToggle")`
- 所有监听该信号的 `LetterTemplate` 都会执行一次大小写切换

切换内容包括：

- 字母显示内容
- 字母显示缩放
- 实体碰撞箱大小


## 如何让玩家使用这个能力

有两种方式：

1. 在代码或场景里把玩家的 `shift_mode` 设置为 `CASE_TOGGLE`
2. 在关卡的 `LevelController.starting_ability` 中指定 `Ability_CaseToggle.gd`

注意：

- `player_shift_handler.gd` 中已经加入 `CASE_TOGGLE`
- 现有旧模式编号不要手动乱改，避免影响已有场景配置


## 当前显示方案

当前模板支持两种显示方式：

1. 贴图显示
   - 给 `uppercase_texture` 和 `lowercase_texture` 分别指定图片
2. 文本回退显示
   - 如果贴图为空，会使用模板内部的像素字体显示字母

也就是说，现在即使还没准备好字母贴图，也可以先把逻辑和碰撞跑起来。


## 现阶段限制

- 目前不会自动从整张字母图集中裁切某个字符
- `character` 只取第一个字符
- `CaseToggle` 是广播式切换，默认会影响场景里所有 `LetterTemplate`


## 后续可扩展方向

- 从字母图集中自动裁切大写/小写字符
- 只让特定分组的字母响应切换
- 为大小写切换加入动画或音效
