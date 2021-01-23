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
func toHais*(haiStr: string) : Hais =
  assert haiStr.len == 4 * 14
  var hais = newSeq[string]()
  for i in 0..<14:
    hais &= haiStr[i*4..<i*4+4]
  return Hais(hais:hais.mapIt(it.toHai()).toCountTable())
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
  for hai, count in hais.hais:
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
    for k, count in hais.hais:
      if k.isYaoChuhai():
        if count < 3: return false
      else:
        if count == 0: return false
    return true
  if isChuren(): return true
  return false
let agariHashSet = (func(): HashSet[string] =
  result = initHashSet[string]()
  for str in agariStrs: result.incl str)()
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
func calcAgari*(hais:Hais, tsumoHai: Hai) : tuple[hansu, fu:int] =
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
type Suhais = array[9,int8]
func toInt(x: Suhais): int =
  (x[0].int shl  0) + (x[1].int shl  3) + (x[2].int shl  6) +
  (x[3].int shl  9) + (x[4].int shl 12) + (x[5].int shl 15) +
  (x[6].int shl 18) + (x[7].int shl 27) + (x[8].int shl 30)
type Tsu = tuple[men,toi,taa:int8]
var suhaiTable = initTable[int, Tsu]()
proc calcShantensu*(hais: Hais): int =
  if hais.isAgari(): return -1
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
  proc calcNormal(): int =
    # ここは計算するたびにメモ化していけば、どんどん速くなる
    proc calcMentsuCands(suhais: Suhais): Tsu =
      let suhaiInt = suhais.toInt()
      if suhaiInt in suhaiTable: return suhaiTable[suhaiInt]
      func calcCands(i:int, suhais: Suhais): seq[Tsu] =
        # taatsu, toitsu としてのみ使用する
        if i >= 9: return @[(0i8,0i8,0i8)]
        # 使用しない
        result = calcCands(i+1, suhais)
        # [1,1] [1,2] [1,3] を組み合わせ. メンツは存在しないと仮定
        # - [1,1]
        # - [1,2] / [1,2] [1,2]
        # - [1,3] / [1,3] [1,3]
        # トイツとして使用
        if suhais[i] >= 2:
          var newSuhais = suhais
          newSuhais[i] -= 2
          var tsus = calcCands(i+1, newSuhais)
          for i in 0..<tsus.len: tsus[i].toi += 1
          result &= tsus
        for use in 1i8..2i8:
          if suhais[i] < use: continue
          if i < 7 and suhais[i+1] >= use:
            var newSuhais = suhais
            newSuhais[i] -= use
            newSuhais[i+1] -= use
            var tsus = calcCands(i+1, newSuhais)
            for i in 0..<tsus.len: tsus[i].taa += use
            result &= tsus
          if i < 6 and suhais[i+2] >= use:
            var newSuhais = suhais
            newSuhais[i] -= use
            newSuhais[i+2] -= use
            var tsus = calcCands(i+1, newSuhais)
            for i in 0..<tsus.len: tsus[i].taa += use
            result &= tsus
      func calcTsus(i:int, suhais: Suhais): seq[Tsu] =
        result = @[]
        # 最後まで来たので残りはただのメンツ候補
        if i >= 9: return calcCands(0, suhais)
        # 組み合わせは以下
        # - [1,1,1]
        # - [1,1,1] [1,2,3]
        # - [1,2,3] * 1..4
        # 暗刻として使用
        if suhais[i] >= 3:
          var newSuhais = suhais
          newSuhais[i] -= 3
          var tsus = calcTsus(i+1, newSuhais)
          for i in 0..<tsus.len: tsus[i].men += 1
          result &= tsus
        # 使用しない
        result &= calcTsus(i+1, suhais)
        # 順子として使用
        if i > 6: return
        # 暗刻として使用かつ順子として使用
        if suhais[i] == 4 and suhais[i+1] >= 1 and suhais[i+2] >= 1:
          var newSuhais = suhais
          newSuhais[i] -= 4
          newSuhais[i+1] -= 1
          newSuhais[i+2] -= 1
          var tsus = calcTsus(i+1, newSuhais)
          for i in 0..<tsus.len: tsus[i].men += 2
          result &= tsus
        # 暗刻としては使用せず順子として使用
        for shuntsu in 1i8..4i8:
          if suhais[i] < shuntsu or suhais[i+1] < shuntsu or
              suhais[i+2] < shuntsu: continue
          var newSuhais = suhais
          newSuhais[i] -= shuntsu
          newSuhais[i+1] -= shuntsu
          newSuhais[i+2] -= shuntsu
          var tsus = calcTsus(i+1, newSuhais)
          for i in 0..<tsus.len: tsus[i].men += shuntsu
          result &= tsus

      # 暗刻は0~4つあるので、そのうち何個を暗刻として解釈するか？
      for tsu in calcTsus(0, suhais):
        # mentsu,(toitsu+tatsu),toitsu, tatsu の順で多いものが偉い
        if result.men > tsu.men : continue
        elif result.men < tsu.men: result = tsu
        elif result.toi + result.taa > tsu.toi + tsu.taa : continue
        elif result.toi + result.taa < tsu.toi + tsu.taa: result = tsu
        elif result.toi > tsu.toi : continue
        elif result.toi < tsu.toi : result = tsu
        elif result.taa > tsu.taa : continue
        elif result.taa < tsu.taa : result = tsu
      suhaiTable[suhaiInt] = result
    # mentsu + cand は最大4
    var tsu : Tsu
    var manzus, pinzus, souzus: Suhais
    for k, count in hais.hais:
      # とりあえず字牌は関係ないので計算しておく
      case k.toHaiType():
      of Jihai:
        if count == 2: tsu.toi += 1
        elif count >= 3: tsu.men += 1
      of Manzu: manzus[k mod 10] += count.int8
      of Pinzu: pinzus[k mod 10] += count.int8
      of Souzu: souzus[k mod 10] += count.int8
    let mTsu = manzus.calcMentsuCands()
    let pTsu = pinzus.calcMentsuCands()
    let sTsu = souzus.calcMentsuCands()
    tsu.men += mTsu.men + pTsu.men + sTsu.men
    tsu.toi += mTsu.toi + pTsu.toi + sTsu.toi
    tsu.taa += mTsu.taa + pTsu.taa + sTsu.taa
    # 8 - メンツ*2 - メンツ候補
    var cand = tsu.toi + tsu.taa
    if cand + tsu.men > 4:
      let diff = cand + 4 - tsu.men
      cand = 4 - tsu.men
      if tsu.toi > 0 : cand += 1
    return 8 - cand - 2 * tsu.men
  result = calcChitoitsu()
  result .min= calcKokushi()
  result .min= calcNormal()
  return result

proc agariTest() =
  # 🀇🀈🀉🀊🀋🀌🀍🀎🀏 🀙🀚🀛🀜🀝🀞🀟🀠🀡 🀐🀑🀒🀓🀔🀕🀖🀗🀘 🀀🀁🀂🀃 🀆🀅🀄
  echo "🀑🀒🀓🀓🀔🀕🀗🀗🀗🀆🀆🀄🀄🀄".toHais().calcShantensu()
  echo "🀑🀒🀓🀓🀔🀕🀖🀗🀗🀆🀆🀄🀄🀄".toHais().calcShantensu()
  echo "🀇🀇🀈🀚🀚🀛🀞🀟🀟🀠🀠🀠🀔🀕".toHais().calcShantensu()
  echo "🀌🀍🀛🀜🀝🀝🀞🀞🀟🀟🀟🀒🀒🀓".toHais().calcShantensu()
agariTest()
