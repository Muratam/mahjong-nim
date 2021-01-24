{.checks:off.}
# import nimprof
import strformat, sets, sequtils, random, tables, hashes, times, strutils
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
  var searchCount = 0
  proc calcAgariWithDora(hais:Hais, tsumoHai: Hai) : float =
    var (hansu, fu) = calcAgari(hais, tsumoHai)
    hansu += hais.hais[dora]
    # 雑に30符
    return [
      0,1000,2000,4000,8000,8000,
      12000,12000,16000,16000,16000,
      24000,24000,32000,32000,32000,32000,32000,32000,32000
    ][hansu].float
  proc impl(hais: Hais, knows: Hais, leftTurn: int) : tuple[kiru:Hai, score:float] =
    searchCount += 1
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
    result.kiru = 9
    for kiru in hais.hais.keys:
      var kiruScore = 0.0
      # ツモ切りするような時はまとめて一回の代表元の探索で済ます
      # - 初期状態と比べてメンツ
      # - ドラそばではない
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
            kiruScore += weight * calcAgariWithDora(newHais, tsumo)
          continue
        # シャン点数下がるような進め方はしない(切る牌が悪い)
        if newShantensu > nowShantensu: continue
        # 和了れるなら和了もあり
        var score = 0.0
        if newShantensu == -1:
          score = weight * calcAgariWithDora(newHais, tsumo)
        var newKnows = Hais(hais:knows.hais)
        newKnows.hais.inc tsumo
        let (_, nextScore) = impl(newHais, newKnows, leftTurn - 1)
        score .max= weight * nextScore
        kiruScore += score
      if result.score < kiruScore:
        result.score = kiruScore
        result.kiru = kiru
    # if result.score > 0.0:
    #   echo hais, "*".repeat(leftTurn)," S:", nowShantensu , " ",kHaiStrs[result.kiru], " ", fmt"{result.score:.5}"
  stopwatch:
    let(kiru,score) = impl(hais, knows, leftTurn)
    echo fmt"{hais} | {kHaiStrs[kiru]} {score.int} ({searchCount})"
  return score
# 1000戦(18ツモ or 平均12の正規分布)やって得点の総和を求めるゲームにすれば
# 評価しやすそう
proc solve(haisStr: string, doraHyojiStr: string) : float =
  let hais = haisStr.toHais()
  let doraHyoji = doraHyojiStr.toHai()
  var knows = Hais(hais:hais.hais)
  knows.hais.inc doraHyoji
  let dora = doraHyoji.getDora()
  return calcTsumoScore(hais, dora, knows, 3)

randomize()
# 🀇🀈🀉🀊🀋🀌🀍🀎🀏 🀙🀚🀛🀜🀝🀞🀟🀠🀡 🀐🀑🀒🀓🀔🀕🀖🀗🀘 🀀🀁🀂🀃 🀆🀅🀄
# discard "🀌🀍🀛🀜🀝🀝🀞🀞🀟🀟🀟🀒🀒🀓".solve("🀌")
# discard "🀈🀉🀉🀉🀊🀋🀞🀞🀠🀑🀒🀓🀓🀕".solve("🀂")
# discard "🀉🀊🀋🀌🀎🀚🀚🀜🀞🀕🀖🀃🀃🀃".solve("🀘") # 125
# discard "🀉🀊🀋🀌🀎🀚🀚🀛🀜🀞🀕🀖🀃🀃".solve("🀘") # 126
discard "🀈🀉🀙🀚🀚🀛🀝🀟🀓🀔🀔🀕🀖🀘".solve("🀂") # 132


# - 🀈🀉🀉🀉🀊🀋🀞🀞🀠🀑🀒🀓🀓🀕 は 🀠 か 🀈 か?
#   - 本: 一向聴で 🀠x18, 🀈x15 なので 🀠
#   - 🀠切り(🀈🀉🀉🀉🀊🀋🀞🀞🀑🀒🀓🀓🀕)(有効牌:🀔x4,🀉x1,🀌x4,🀞x2,🀊x3,🀇x4(タンヤオ・ドラなし,愚形🀔待ちリーチ))
#     - 🀔x4 ->
#     - 🀉x1,🀌x4,🀞x2,🀊x3 -> 🀔x4
#     - 🀇x4 -> 🀔x4(タンヤオもドラもなし)
#   - 🀈切り(🀉🀉🀉🀊🀋🀞🀞🀠🀑🀒🀓🀓🀕)(有効牌:🀔x4,🀉x1,🀌x4,🀞x2,🀟x4)
#     - 🀔x4 -> x🀠[🀞x2,🀉x1(p),🀌x4(p)]
#     - 🀉x1,🀌x4,🀞x2,🀟x4 -> 🀔x4
