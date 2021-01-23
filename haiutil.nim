{.checks:off.}
import strformat, hashes, tables, sequtils, sets, random, algorithm, math
import agaristr
template stopwatch(body) = (let t1 = cpuTime();body;stderr.writeLine "TIME:",(cpuTime() - t1) * 1000,"ms")
template loop*(n:int,body) = (for _ in 0..<n: body)
template `max=`*(x,y) = x = max(x,y)
template `min=`*(x,y) = x = min(x,y)

# 牌
type HaiType* = enum Manzu, Pinzu, Souzu, Jihai
type Hai* = int8
type Hais* = ref object
  hais* : CountTable[Hai] # 14枚とする
const kHaiStrs* = [
  "🀇","🀈","🀉","🀊","🀋","🀌","🀍","🀎","🀏","M", # [0 ,8]
  "🀙","🀚","🀛","🀜","🀝","🀞","🀟","🀠","🀡","P", # [10,18]
  "🀐","🀑","🀒","🀓","🀔","🀕","🀖","🀗","🀘","S", # [20,28]
  "🀀","1","🀁","2","🀂","3","🀃","4","🀆","5","🀅","6","🀄"
   # [30,32,34,36,38,40,42]
]
const kAvaiableHais* = @[
  0,1,2,3,4,5,6,7,8,
  10,11,12,13,14,15,16,17,18,
  20,21,22,23,24,25,26,27,28,
  30,32,34,36,38,40,42
].mapIt(it.Hai)

func `$`*(hais: Hais): string =
  result = ""
  for hai in hais.hais.keys: result &= kHaiStrs[hai]
func toHai*(haiStr: string): Hai =
  for i, str in kHaiStrs:
    if haiStr == str : return i.Hai
  assert false
func toHaiType*(hai:Hai): HaiType =
  if hai < 10: return Manzu
  if hai < 20: return Pinzu
  if hai < 30: return Souzu
  return Jihai
func isYaoChuhai*(hai:Hai) : bool =
  if hai >= 30 : return true
  return hai mod 10 in [0, 8]
func isKokushi(hais: Hais): bool =
  var alreadyTwo = false
  for hai, count in hais.hais.pairs:
    if count >= 3: return false
    if not hai.isYaoChuhai(): return false
    if count == 2:
      if alreadyTwo: return false
      alreadyTwo = true
  return true
func isYakuman(hais:Hais): bool =
  assert hais.hais.len == 14
  # TODO: ツモのみ(強制四暗刻)
  # TODO: 鳴きなし
  if hais.isKokushi(): return true
  const kHaku = "🀆".toHai()
  const kHatsu = "🀅".toHai()
  const kChun = "🀄".toHai()
  if hais.hais[kHaku] + hais.hais[kHatsu] + hais.hais[kChun] == 9:
    return true
  const kTon = "🀀".toHai()
  const kNan = "🀁".toHai()
  const kSha = "🀂".toHai()
  const kPei = "🀃".toHai()
  if hais.hais[kTon] + hais.hais[kNan] +
     hais.hais[kSha] + hais.hais[kPei] >= 11:
    return true
  let haiKeys = toSeq(hais.hais.keys())
  let haiTypes = haiKeys.mapIt(it.toHaiType())
  if haiTypes.allIt(it == Jihai): return true
  if haiKeys.allIt(it.toHaiType() != Jihai and it.isYaoChuhai()): return true
  let kRyuisos = @["🀑","🀒","🀓","🀕","🀗","🀅"].mapIt(it.toHai())
  if kRyuisos.mapIt(hais.hais[it]).sum() == 14: return true
  # 5種類なら全部暗刻なので四暗刻
  if hais.hais.len == 5 : return true
  func isChuren(): bool =
    var churenType = Jihai
    if haiTypes.allIt(it == Manzu): churenType = Manzu
    elif haiTypes.allIt(it == Souzu): churenType = Souzu
    elif haiTypes.allIt(it == Pinzu): churenType = Pinzu
    else: return false
    for k, count in hais.hais.pairs:
      if k.isYaoChuhai():
        if count < 3: return false
      else:
        if count == 0: return false
    return true
  if isChuren(): return true
  return false

func calcAgari*(hais:Hais, lastHai: Hai) : tuple[hansu, fu:int] =
  # TODO:リーチ・ドラは無し, 門前だと仮定, ダブル役満以上は無し
  # TODO:カンは無し(三槓子, 四槓子, 嶺上開花)
  # TODO:ツモのみ(for: 対々和, 四暗刻, 三暗刻, 混老頭)
  assert hais.hais.len == 14
  # 先に役満をチェック(TODO:符は適当)
  if hais.isYakuman(): return (13, 20)
  var hansu = 0
  # 役牌, 小三元
  const kBakaze = "🀀".toHai()
  const kJikaze = "🀀".toHai()
  const kHaku = "🀆".toHai()
  const kHatsu = "🀅".toHai()
  const kChun = "🀄".toHai()
  if hais.hais[kBakaze] == 3: hansu += 1
  if hais.hais[kJikaze] == 3: hansu += 1
  if hais.hais[kHaku] == 3: hansu += 1
  if hais.hais[kHatsu] == 3: hansu += 1
  if hais.hais[kChun] == 3: hansu += 1
  if hais.hais[kHaku] + hais.hais[kHatsu] + hais.hais[kChun] == 8: hansu += 2
  # 染め手
  let haiKeys = toSeq(hais.hais.keys())
  let haiTypes = haiKeys.mapIt(it.toHaiType())
  if haiTypes.allIt(it == Manzu): hansu += 6
  elif haiTypes.allIt(it == Souzu): hansu += 6
  elif haiTypes.allIt(it == Pinzu): hansu += 6
  elif haiTypes.allIt(it == Manzu or it == Jihai): hansu += 3
  elif haiTypes.allIt(it == Souzu or it == Jihai): hansu += 3
  elif haiTypes.allIt(it == Pinzu or it == Jihai): hansu += 3
  if haiKeys.allIt(not it.isYaoChuhai()): hansu += 1
  # TODO:
  # 残りは以下で最も飜数が高い組み合わせ(TODO:本当は最も高い点数だがサボり)
  # 1: 一盃口,平和(最後にツモった牌が必要)
  # 2: 三色同順,三色同刻,三暗刻,一気通貫,七対子,混全帯幺九
  # 3: 二盃口,純全帯公九
  return (hansu, 20)

let agariHashSet = (func(): HashSet[string] =
  result = initHashSet[string]()
  for str in agariStrs: result.incl str)()
# 和了かどうか
proc isAgari*(hais: Hais) : bool =
  func encode(hais: Hais): string =
    # 201110111111111 みたいな
    result = ""
    var pre = -1
    for i in kAvaiableHais:
      if not hais.hais.contains(i): continue
      if result.len != 0 and pre != i - 1: # 最初は 0 不要
        result &= "0"
      result &= fmt"{hais.hais[i]}"
      pre = i
  if hais.isKokushi(): return true
  return hais.encode() in agariHashSet
proc getShantensu*(hais: Hais): int =
  if hais.isAgari(): return 0
  func calcChitoitsu(): int =
    result = 6
    if hais.hais.len <= 7: result += 7 - hais.hais.len
    for _, count in hais.hais:
      if count >= 2: result -= 1
  func calcKokushi(): int =
    result = 13
    var hasTwo = false
    for k, count in hais.hais:
      if not k.isYaoChuhai(): continue
      if count >= 2 : hasTwo = true
      result -= 1
    if hasTwo: result -= 1
  # 計算するたびにメモ化していけば、どんどん速くなる
  func calcNormal(): int =
    result = 8
    # - メンツ - メンツ候補
  result = calcChitoitsu()
  result .min= calcKokushi()
  result .min= calcNormal()
  return result

proc agariTest() =
  block:
    let hais = [
      "🀑","🀒","🀓","🀓","🀔","🀕","🀗","🀗","🀗","🀆","🀆","🀄","🀄","🀄"
    ].mapIt(it.toHai()).toCountTable()
    echo Hais(hais:hais).getShantensu()
  block:
    let hais = [
      "🀑","🀒","🀓","🀓","🀔","🀕","🀖","🀗","🀗","🀆","🀆","🀄","🀄","🀄"
    ].mapIt(it.toHai()).toCountTable()
    echo Hais(hais:hais).getShantensu()
agariTest()
