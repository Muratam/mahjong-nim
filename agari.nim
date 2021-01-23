import strformat, sets, sequtils, random, tables, hashes
import agariset,haiutil

# ツモだけで和了れる確率を計算
# 純粋に門前で進める時の指標
func calcTsumoScore(hais: seq[int8],kawa: seq[int8], leftTurn: int = 10) : float =
  # 枝刈り: シャンテン数を戻すことは通常はない
  #      : ドラそば(ドラ±2), 一番多い色(7以上), 国士無双(7以上) なら戻しても良い
  # - 何も考えないと 34^{turn} の状態がある
  #  - 「聴牌形かつ形固定」とすると、和了期待値は計算できる
  #  - 枝刈り+メモ化(7->78->789 と 7->79->789は結構ありうる)
  #


# import ,strutils,,math, algorithm
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
  #   枝刈りとして、貪欲に良くなる方良くなる方にあげていくとよい
  # - 和了れる確率は N = 1 から決定的に求められる
  #   雑に枝刈りすればよさそう
  # 一向聴なら、「張り替える」

# 1000戦(18ツモ or 平均12の正規分布)やって得点の総和を求めるゲームにすれば
# 評価しやすそう

randomize()
# 3bit * 最大17なので、int64に入る
proc agariTest() =
  block:
    var testHais = [
      "🀑","🀒","🀓","🀓","🀔","🀕","🀗","🀗","🀗","🀆","🀆","🀄","🀄","🀄"
    ].mapIt(it.toHai())
    testHais.shuffle()
    echo testHais.encode()
    echo agariHashSet.contains(testHais.encode())
  block:
    var testHais = [
      "🀑","🀒","🀓","🀓","🀔","🀕","🀖","🀗","🀗","🀆","🀆","🀄","🀄","🀄"
    ].mapIt(it.toHai())
    testHais.shuffle()
    echo testHais.encode()
    echo agariHashSet.contains(testHais.encode())
agariTest()
block: # テンパイ
  var testHais = [
    "🀑","🀒","🀓","🀓","🀔","🀕","🀗","🀗","🀗","🀆","🀆","🀄","🀄"
  ].mapIt(it.toHai())
