import strformat, sets, sequtils, random, tables, hashes
import agariset,haiutil

# ウザク本の考え方が正しいかを検証するためのコード
# - (鳴いて...と書いてある場合を除く)
# - 赤ドラ周りは仕方なし
# ツモだけで和了れる確率を計算
# 純粋に門前で進める時の指標で、鳴きは無し
# リーチはなし, 天和はなし, ロンもなし
func calcTsumoScore(hais: seq[int8], kawa: seq[int8], leftTurn: int = 10) : float =
  assert hais.len == 14
  # 枝刈り: シャンテン数を戻すことは通常はない
  # - 対象牌がN以上かつ対象牌が来たらシャンテン数を下げる方向に動いてもいい
  # - ドラそば(ドラ±1)は戻しても良い(±2じゃないのは,invalidを超えるのが面倒なため)
  const allowBackHonitsuCount = 7
  const allowBackChinitsuCount = 9
  const allowBackKokushiCount = 9
  # - 何も考えないと 34^{turn} の状態がある
  # - 「聴牌形かつ以後形を固定」とすると、和了期待値は計算できる
  #   - 残り順数に依存するので、一旦無し。組み換えとかあるし
  #   - 和了らない選択肢がある。最良の選択肢を選ぶ
  #   - 極論12312378967811で和了るか？、和了れなかったら0点で,和了れるならその点数が入る
  #   - ツモなのでフリテンは関係ない
  #   - 和了れた場合、リーチをしていたとして計算する
  #     - 相手は十分に賢いので降りると仮定(ロンできない)
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
