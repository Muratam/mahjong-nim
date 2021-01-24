{.checks:off.}
import strformat, sets, sequtils, random, tables, hashes
import haiutil
template stopwatch(body) = (let t1 = cpuTime();body;stderr.writeLine "TIME:",(cpuTime() - t1) * 1000,"ms")
template `max=`*(x,y) = x = max(x,y)
template `min=`*(x,y) = x = min(x,y)

# ウザク本の考え方が正しいかを検証するためのコード
# - (鳴いて...と書いてある場合を除く)
# - 赤ドラ周りは仕方なし
# ツモだけで和了れる確率を計算
# 純粋に門前で進める時の指標で、鳴きは無し
# リーチはなし, 天和はなし, ロンもなし
proc calcTsumoScore(hais: Hais, dora: Hai, knows: Hais, leftTurn: int) : float =
  proc impl(hais: Hais, dora: Hai, knows: Hais, leftTurn: int) : tuple[kiru:Hai, score:float] =
    # assert hais.hais.len == 14
    # 枝刈り: シャンテン数を戻すことは通常はない
    # - 対象牌がN以上かつ対象牌が来たらシャンテン数を下げる方向に動いてもいい
    # - ドラそば(ドラ±1)は戻しても良い(±2じゃないのは,invalidを超えるのが面倒なため)
    # const allowBackHonitsuCount = 7
    # const allowBackChinitsuCount = 9
    # const allowBackKokushiCount = 9
    # - 何も考えないと 34^{turn} の状態がある
    # - 「聴牌形かつ以後形を固定」とすると、和了期待値は計算できる
    #   - 残り順数に依存するので、一旦無し。組み換えとかあるし
    #   - 和了らない選択肢がある。最良の選択肢を選ぶ
    #   - 極論12312378967811で和了るか？、和了れなかったら0点で,和了れるならその点数が入る
    #   - ツモなのでフリテンは関係ない
    #   - 和了れた場合、リーチをしていたとして計算する
    #     - 相手は十分に賢いので降りると仮定(ロンできない)
    #  - 枝刈り+メモ化(7->78->789 と 7->79->789は結構ありうる)
    # どれかを切って(max: 14) * どれかをツモって(34)
    let nowShantensu = hais.calcShantensu()
    var leftHais = (3*9+7) * 4
    for count in knows.hais.values: leftHais -= count
    result.score = 0.0
    for kiru in hais.hais.keys:
      var kiruScore = 0.0
      for tsumo in kAvaiableHais:
        if knows.hais[tsumo] >= 4: continue
        let weight = (4 - knows.hais[tsumo]) / leftHais
        var newHais = Hais(hais:hais.hais)
        newHais.hais.inc kiru, -1
        newHais.hais.inc tsumo
        let newShantensu = newHais.calcShantensu()
        # 最後の順なら絶対に和了るのが得
        if leftTurn <= 1:
          if newShantensu == -1:
            kiruScore += weight * calcAgari(newHais, tsumo).hansu.float
          continue
        # シャン点数下がるような進め方はしない(切る牌が悪い)
        if newShantensu > nowShantensu: continue
        # 和了れるなら和了もあり
        var score = 0.0
        if newShantensu == -1:
          score = weight * calcAgari(newHais, tsumo).hansu.float
        var newKnows = Hais(hais:knows.hais)
        newKnows.hais.inc tsumo
        let (_, nextScore) = impl(newHais, dora, newKnows, leftTurn - 1)
        score .max= weight * nextScore
        kiruScore += score
      if result.score < kiruScore:
        result.score = kiruScore
        result.kiru = kiru
    # echo hais, " : ", leftTurn," : ", nowShantensu , " : ", result
  let(kiru,score) = impl(hais, dora, knows, leftTurn)
  echo "KIRU:", kHaiStrs[kiru]
  return score
# 1000戦(18ツモ or 平均12の正規分布)やって得点の総和を求めるゲームにすれば
# 評価しやすそう
proc solve(haisStr: string, doraHyojiStr: string) : float =
  let hais = haisStr.toHais()
  let doraHyoji = doraHyojiStr.toHai()
  var knows = Hais(hais:hais.hais)
  knows.hais.inc doraHyoji
  let dora = doraHyoji.getDora()
  return calcTsumoScore(hais, dora, knows, 2)

randomize()
echo "🀌🀍🀛🀜🀝🀝🀞🀞🀟🀟🀟🀒🀒🀓".solve("🀌")
