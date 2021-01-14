import sequtils,strutils,algorithm,math
# ,future,macros,strformat,times,random,os,tables
# 鳴きは無いと過程, 偶然役は(条件が同一なので)省く
type Yaku1 = enum
  一盃口, 中, 発, 白, 断么九,平和,自風,場風
type Yaku2 = enum
  三色同順,三色同刻,三暗刻,一気通貫,
  七対子,混全帯幺九,三槓子,混老頭,小三元,対々和
type Yaku3 = enum 二盃口,純全帯公九, 混一色
type Yaku6 = enum 清一色
type Yaku13 = enum 国士無双, 四暗刻, 大三元, 小四喜, 大四喜,
  九蓮宝燈, 緑一色, 字一色, 清老頭, 四槓子
