# {.checks:off.}
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
func compress(hais:Hais) : Hais =
  func haiNormalize(str: string) : string =
    if str.len <= 1 : return str
    var rev = newStringOfCap(str.len)
    for c in str.reversed : rev.add c
    return if str < rev: str else: rev
  return Hais(strs: hais.strs.map(haiNormalize).sorted())
iterator deleteds(hais:Hais): Hais =
  # - 塊は「[1,4]」「連続する長さは最大9」
  # - -1の置換:
  #   - 2~4なら-1
  #   - 1ならそこでsplit(消えるかも)
  for i, str in hais.strs:
    for j, c in str:
      var newH = Hais(strs:hais.strs)
      if c == '4': newH.strs[i][j] = '3'
      elif c == '3': newH.strs[i][j] = '2'
      elif c == '2': newH.strs[i][j] = '1'
      else:
        if str.len == 1: newH.strs.delete(i,i)
        elif j == 0 : newH.strs[i] = newH.strs[i][1..^1]
        elif j == str.len - 1: newH.strs[i] = newH.strs[i][0..^2]
        else:
          newH.strs &= newH.strs[i][j+1..^1]
          newH.strs[i] = newH.strs[i][0..<j]
      yield newH.compress()

let agariHais = agariStrs.mapIt(Hais(strs:it.split("0")))
var agariHashSet* = initHashSet[Hais]()
var compressedAgariHashSet* = initHashSet[Hais]()
stopwatch:
  for hais in agariHais:
    agariHashSet.incl hais
    compressedAgariHashSet.incl hais.compress()
echo "和了 : ", agariHashSet.len, " / ", compressedAgariHashSet.len
var compressed1stHashSet* = initHashSet[Hais]()
stopwatch:
  for hais in compressedAgariHashSet:
    for hai in hais.deleteds:
      compressed1stHashSet.incl hai
      # echo hais, ":", hai
    # - +1の置換:
    #   - 0~3なら+1
    #   - 塊の長さが8以下なら塊の左右に1を追加
    #   - 合わせた長さが8以下なら, 1でjoin
echo "-1 : ", compressed1stHashSet.len
