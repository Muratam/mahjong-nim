{.checks:off.}
import strformat, hashes, tables, sequtils, sets, random, algorithm
import agaristr
template stopwatch(body) = (let t1 = cpuTime();body;stderr.writeLine "TIME:",(cpuTime() - t1) * 1000,"ms")
template loop*(n:int,body) = (for _ in 0..<n: body)
template `max=`*(x,y) = x = max(x,y)
template `min=`*(x,y) = x = min(x,y)

# 牌
type HaiType* = enum Manzu, Pinzu, Souzu, Jihai
type Hai* = int8
type Hais* = ref object
  hais* : seq[Hai] # ソートされているとする. 14枚とする
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
  for hai in hais.hais: result &= kHaiStrs[hai]
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

let agariHashSet = (func(): HashSet[string] =
  result = initHashSet[string]()
  for str in agariStrs: result.incl str)()
# 和了かどうか
proc isAgari*(hais: Hais) : bool =
  func encode(hais: Hais): string =
    # 201110111111111 みたいな
    let counts = hais.hais.toCountTable()
    result = ""
    var pre = -1
    for i in kAvaiableHais:
      if not counts.contains(i): continue
      if result.len != 0 and pre != i - 1: # 最初は 0 不要
        result &= "0"
      result &= fmt"{counts[i]}"
      pre = i
  return hais.encode() in agariHashSet
proc getShantensu*(hais: Hais): int =
  if hais.isAgari(): return 0
  let counts = hais.hais.toCountTable()
  func calcChitoitsu(): int =
    result = 6
    if counts.len <= 7: result += 7 - counts.len
    for _, count in counts:
      if count >= 2: result -= 1
  func calcKokushi(): int =
    result = 13
    var hasTwo = false
    for k, count in counts:
      if not k.isYaoChuhai(): continue
      if count >= 2 : hasTwo = true
      result -= 1
    if hasTwo: result -= 1
  func calcNormal(): int =
    result = 8
    # - メンツ - メンツ候補
  result = calcChitoitsu()
  result .min= calcKokushi()
  result .min= calcNormal()
  return result

# 3bit * 最大17なので、int64に入る
proc agariTest() =
  block:
    var hais = [
      "🀑","🀒","🀓","🀓","🀔","🀕","🀗","🀗","🀗","🀆","🀆","🀄","🀄","🀄"
    ].mapIt(it.toHai())
    hais.sort()
    echo Hais(hais:hais).getShantensu()
  block:
    var hais = [
      "🀑","🀒","🀓","🀓","🀔","🀕","🀖","🀗","🀗","🀆","🀆","🀄","🀄","🀄"
    ].mapIt(it.toHai())
    hais.sort()
    echo Hais(hais:hais).getShantensu()
agariTest()
