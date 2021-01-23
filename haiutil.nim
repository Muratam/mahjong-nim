import strformat, hashes, tables

# 牌
const kHaiStrs* = [
  "🀇","🀈","🀉","🀊","🀋","🀌","🀍","🀎","🀏", # [0 ,9)
  "🀙","🀚","🀛","🀜","🀝","🀞","🀟","🀠","🀡", # [9 ,18)
  "🀐","🀑","🀒","🀓","🀔","🀕","🀖","🀗","🀘", # [18,27)
  "🀀","🀁","🀂","🀃","🀆","🀅","🀄" # [27,31),[31,34)
]
const kHaiMaxKind* = kHaiStrs.len
func toHai*(haiStr: string): int8 =
  for i, str in kHaiStrs:
    if haiStr == str : return i.int8
  assert false
func encode*(hais: seq[int8]): string =
  assert hais.len <= 14
  let counts = hais.toCountTable()
  # 201110111111111 みたいな
  result = ""
  var pre = -1
  for i in 0.int8..<kHaiMaxKind.int8:
    if not counts.contains(i): continue
    if result.len != 0: # 最初は 0 不要
      # 連続していない or 🀇🀙🀐 or 🀀🀁🀂🀃🀆🀅🀄
      if pre != i - 1 or i mod 9 == 0 or i >= 27:
        result &= "0"
    result &= fmt"{counts[i]}"
    pre = i
