{.checks:off.}
import agaristr
import hashes, sets, strutils, algorithm, sequtils, times
template stopwatch(body) = (let t1 = cpuTime();body;stderr.writeLine "TIME:",(cpuTime() - t1) * 1000,"ms")
template loop*(n:int,body) = (for _ in 0..<n: body)
template `max=`*(x,y) = x = max(x,y)
template `min=`*(x,y) = x = min(x,y)
# string -> int に圧縮
func bit3x17*(code:string) : int =
  result = 0
  for i, x in code:
    result += (x.ord - '0'.ord) shl (i * 3)
# 12333 でも 66678 でも同じ
# 12333 でも 33321 でも同じ
# 和了: 9362 => 2272
type Hais = ref object
  strs : seq[string]
func hash(h:Hais):Hash = h.strs.hash
func `==`(a,b: Hais): bool = a.strs == b.strs
func `$`(h:Hais):string = $h.strs
func strReversed(str:string) : string =
  if str.len <= 1 : return str
  result = newStringOfCap(str.len)
  for c in str.reversed : result.add c
func compress(hais:Hais) : Hais =
  func haiNormalize(str: string) : string =
    if str.len <= 1 : return str
    var rev = newStringOfCap(str.len)
    for c in str.reversed : rev.add c
    return if str < rev: str else: rev
  # return hais
  return Hais(strs: hais.strs.map(haiNormalize).sorted())
iterator deleteds(hais:Hais): Hais =
  # - 塊は「[1,4]」「連続する長さは最大9」
  # - -1の置換:
  #   - 2~4なら-1
  #   - 1ならそこでsplit(消えるかも)
  for i, str in hais.strs:
    for j, c in str:
      var newH = Hais(strs:hais.strs)
      if c >= '2': newH.strs[i][j] = chr(c.ord - 1)
      else:
        if str.len == 1: newH.strs.delete(i,i)
        elif j == 0 : newH.strs[i] = newH.strs[i][1..^1]
        elif j == str.len - 1: newH.strs[i] = newH.strs[i][0..^2]
        else:
          newH.strs &= newH.strs[i][j+1..^1]
          newH.strs[i] = newH.strs[i][0..<j]
      yield newH.compress()
iterator adds(hais:Hais): Hais =
  # - 塊は「[1,4]」「連続する長さは最大9」
  # - +1の置換:
  #   - 0~3なら+1
  #   - 塊の長さが8以下なら塊の左右に1を追加
  #   - 合わせた長さが8以下なら, 1でjoin
  for i, str in hais.strs:
    for j, c in str:
      if c == '4' : continue
      var newH = Hais(strs:hais.strs)
      newH.strs[i][j] = chr(c.ord + 1)
      yield newH.compress()
    if str.len > 8: continue
    block:
      var newH = Hais(strs:hais.strs)
      newH.strs[i].add '1'
      yield newH.compress()
    block:
      var newH = Hais(strs:hais.strs)
      newH.strs[i] =  '1' & newH.strs[i]
      yield newH.compress()
  # [0..<hais.strs.len] から2組選んでjoin
  for i in 0..<hais.strs.len-1:
    for j in i+1..<hais.strs.len:
      if hais.strs[i].len + hais.strs[j].len >= 9: continue
      let sis = [hais.strs[i], hais.strs[i].strReversed]
      let sjs = [hais.strs[j], hais.strs[j].strReversed]
      for si in sis:
        for sj in sjs:
          block:
            var newH = Hais(strs:hais.strs)
            newH.strs[j] = si & '1' & sj
            newH.strs.delete(i,i)
            yield newH.compress()
          block:
            var newH = Hais(strs:hais.strs)
            newH.strs[j] = sj & '1' & si
            newH.strs.delete(i,i)
            yield newH.compress()

func getAddsHaisHashSet(baseSet: HashSet[Hais]) : HashSet[Hais] =
  result = initHashSet[Hais]()
  for hais in baseSet:
    for hai in hais.adds:
      result.incl hai

func getDeletesHaisHashSet(baseSet: HashSet[Hais]) : HashSet[Hais] =
  result = initHashSet[Hais]()
  for hais in baseSet:
    for hai in hais.deleteds:
      result.incl hai


let agariHais = agariStrs.mapIt(Hais(strs:it.split("0")))
var agariHashSet* = initHashSet[Hais]()
var compAgaris14* = initHashSet[Hais]()
stopwatch:
  for hais in agariHais:
    agariHashSet.incl hais
    compAgaris14.incl hais.compress()
  echo "和了 : ", compAgaris14.len, " (base: ", agariHashSet.len, ")"
stopwatch:
  var compTempais13* = compAgaris14.getDeletesHaisHashSet()
  echo "聴牌 : ", compTempais13.len
stopwatch:
  var sumSet14 = compAgaris14
  var sumSet13 = compTempais13
  var compTempais14 = compTempais13.getAddsHaisHashSet()
  # 聴牌+1 かつ 和了は存在しない
  compTempais14 = compTempais14 - sumSet14
  sumSet14 = sumSet14 + compTempais14
  echo "聴牌+1 : ", compTempais14.len
stopwatch:
  var comp1s13 = compTempais14.getDeletesHaisHashSet()
  comp1s13 = comp1s13 - sumSet13
  sumSet13 = sumSet13 + comp1s13
  echo "一向聴 : ", comp1s13.len
stopwatch:
  var comp1s14 = comp1s13.getAddsHaisHashSet()
  comp1s14 = comp1s14 - sumSet14
  sumSet14 = sumSet14 + comp1s14
  echo "一向聴+1 : ", comp1s14.len
stopwatch:
  var comp2s13 = comp1s14.getDeletesHaisHashSet()
  comp2s13 = comp2s13 - sumSet13
  sumSet13 = sumSet13 + comp2s13
  echo "二向聴 : ", comp2s13.len
stopwatch:
  var comp2s14 = comp2s13.getAddsHaisHashSet()
  comp2s14 = comp2s14 - sumSet14
  sumSet14 = sumSet14 + comp2s14
  echo "二向聴+1 : ", comp2s14.len
stopwatch:
  var comp3s13 = comp2s14.getDeletesHaisHashSet()
  comp3s13 = comp3s13 - sumSet13
  sumSet13 = sumSet13 + comp3s13
  echo "三向聴 : ", comp3s13.len
stopwatch:
  var comp3s14 = comp3s13.getAddsHaisHashSet()
  comp3s14 = comp3s14 - sumSet14
  sumSet14 = sumSet14 + comp3s14
  echo "三向聴+1 : ", comp3s14.len
stopwatch:
  var comp4s13 = comp3s14.getDeletesHaisHashSet()
  comp4s13 = comp4s13 - sumSet13
  sumSet13 = sumSet13 + comp4s13
  echo "四向聴 : ", comp4s13.len
stopwatch:
  var comp4s14 = comp4s13.getAddsHaisHashSet()
  comp4s14 = comp4s14 - sumSet14
  sumSet14 = sumSet14 + comp4s14
  echo "四向聴+1 : ", comp4s14.len
stopwatch:
  var comp5s13 = comp4s14.getDeletesHaisHashSet()
  comp5s13 = comp5s13 - sumSet13
  sumSet13 = sumSet13 + comp5s13
  echo "五向聴 : ", comp5s13.len
stopwatch:
  var comp5s14 = comp5s13.getAddsHaisHashSet()
  comp5s14 = comp5s14 - sumSet14
  sumSet14 = sumSet14 + comp5s14
  echo "五向聴+1 : ", comp5s14.len
stopwatch:
  var comp6s13 = comp5s14.getDeletesHaisHashSet()
  comp6s13 = comp6s13 - sumSet13
  sumSet13 = sumSet13 + comp6s13
  echo comp6s13
  echo "六向聴 : ", comp6s13.len
stopwatch:
  var comp6s14 = comp6s13.getAddsHaisHashSet()
  comp6s14 = comp6s14 - sumSet14
  sumSet14 = sumSet14 + comp6s14
  echo comp6s14
  echo "六向聴+1 : ", comp6s14.len
stopwatch:
  var comp7s13 = comp6s14.getDeletesHaisHashSet()
  comp7s13 = comp7s13 - sumSet13
  sumSet13 = sumSet13 + comp7s13
  echo comp7s13
  echo "七向聴 : ", comp7s13.len
  # これは0 のはず、チートイツがあるので

# つまり、そのencode規則の中で、最も
