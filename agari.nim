import strformat, sets, sequtils, random, tables, hashes
import agariset
# import ,strutils,,math, algorithm

# 牌
const kHaiStrs = [
  "🀇","🀈","🀉","🀊","🀋","🀌","🀍","🀎","🀏", # [0 ,9)
  "🀙","🀚","🀛","🀜","🀝","🀞","🀟","🀠","🀡", # [9 ,18)
  "🀐","🀑","🀒","🀓","🀔","🀕","🀖","🀗","🀘", # [18,27)
  "🀀","🀁","🀂","🀃","🀆","🀅","🀄" # [27,31),[31,34)
]
const kHaiMaxKind = kHaiStrs.len
const kHaiMaxIndex = kHaiMaxKind * 4
type Hai = object
  kind : int #
  number : int   # 4枚あるので0,1,2,3. 問題なければこの値に関係なく動作させるように書く
func ToHai(index: int): Hai =
  result.kind = index div 4
  result.number = index mod 4
func ToHai(haiStr: string): Hai =
  for i, str in kHaiStrs:
    if haiStr != str : continue
    result.kind = i
    result.number = 0
    return
  assert false
func FromHai(hai: Hai): int =
  return hai.kind + hai.kind * 4
func hash(hai: Hai): Hash = hai.kind
func `$`(hai: Hai): string =
  return fmt"{kHaiStrs[hai.kind]}"
func encode(hais: seq[Hai]): string =
  assert hais.len == 14
  let counts = hais.mapIt(it.kind).toCountTable()
  # 201110111111111 みたいな
  result = ""
  var pre = -1
  for i in 0..<kHaiMaxKind:
    if not counts.contains(i): continue
    if result.len != 0: # 最初は 0 不要
      # 連続していない or 🀇🀙🀐 or 🀀🀁🀂🀃🀆🀅🀄
      if pre != i - 1 or i mod 9 == 0 or i >= 27:
        result &= "0"
    result &= fmt"{counts[i]}"
    pre = i

func tenpaiTest() =   discard
  # 34種入れてみてテンパイ形か確認すればいい
  # 点数の期待値がそのままその形の評価値になる？(平場・東1・鳴きなしを仮定)
  # - 点数が高くても和了りが難しければ価値が薄い
  # - 赤やドラは価値が高い。多面張は和了やすいので価値が高い
  # - ツモられると損なので、「和了ること」自体の価値の重みは大きい(安くても和了れると偉い)が、そこは考慮しない
  # 12 よりも 13 のほうが価値が高い。4をツモったときに 34 に張り替えられる。
  # ほかがタンヤオな時の 12 は、微妙な形の時の12より価値が高い。2 4 に張り替えて点数が高くなる
  # - 和了形で無いなら張り替えがあるとして、それを考える
  #   - 和了系から更に高めを狙うことは一旦考えない
  #   - N順待てるのNに依存して変わる. N = 1~8で試してみるといいか
  #     発展的には、N巡まで和了られない確率をかければ期待値になる
  # - 14枚のうち適当に張り替えてみて,

# 一向聴なら、「張り替える」

randomize()
proc agariTest() =
  block:
    var testHais = [
      "🀑","🀒","🀓","🀓","🀔","🀕","🀗","🀗","🀗","🀆","🀆","🀄","🀄","🀄"
    ].mapIt(it.ToHai())
    testHais.shuffle()
    echo testHais.encode()
    echo agariHashSet.contains(testHais.encode())
  block:
    var testHais = [
      "🀑","🀒","🀓","🀓","🀔","🀕","🀖","🀗","🀗","🀆","🀆","🀄","🀄","🀄"
    ].mapIt(it.ToHai())
    testHais.shuffle()
    echo testHais.encode()
    echo agariHashSet.contains(testHais.encode())
# agariTest()
block: # テンパイ
  var testHais = [
    "🀑","🀒","🀓","🀓","🀔","🀕","🀗","🀗","🀗","🀆","🀆","🀄","🀄"
  ].mapIt(it.ToHai())
