-- clear_space.lua
-- 指定した幅・奥行き・高さの空間を掘り、床面を指定ブロックで敷き詰める
-- 使い方: clear_space <幅> <奥行き> <高さ> <床ブロック名>
-- 例: clear_space 9 9 3 dirt

local args = {...}
local width     = tonumber(args[1]) or 5
local depth     = tonumber(args[2]) or 5
local height    = tonumber(args[3]) or 3
local floorItem = args[4] and ("minecraft:" .. args[4]) or nil

-- 名前でスロットを検索して選択する
local function selectItem(itemName)
  for slot = 1, 16 do
    local item = turtle.getItemDetail(slot)
    if item and item.name == itemName and item.count > 0 then
      turtle.select(slot)
      return true
    end
  end
  return false
end

-- 足元(1段下)を判定し、指定ブロックでなければ掘って敷き直す
local function handleFloor()
  if not floorItem then return end  -- 床処理が不要なら何もしない

  local success, data = turtle.inspectDown()

  if success and data.name == floorItem then
    -- すでに指定ブロック → 何もしない
    return
  end

  if success then
    turtle.digDown()
  end

  if selectItem(floorItem) then
    turtle.placeDown()
  else
    print("床ブロック切れ: " .. floorItem .. " を補充してください")
  end
end

-- 前方を掘りながら1マス進む(床処理つき)
local function digForwardWithFloor()
  while turtle.detect() do
    turtle.dig()
  end
  turtle.forward()
  handleFloor()
end

-- 前方を掘りながら1マス進む(床処理なし・上層用)
local function digForward()
  while turtle.detect() do
    turtle.dig()
  end
  turtle.forward()
end

-- 1つの層をスネーク走査で掘る(床処理の有無を切り替え可能)
local function clearLayer(w, d, withFloor)
  local goingForward = true
  local moveFn = withFloor and digForwardWithFloor or digForward

  for i = 1, w do
    for j = 1, d - 1 do
      moveFn()
    end

    if i < w then
      if goingForward then
        turtle.turnRight()
        moveFn()
        turtle.turnRight()
      else
        turtle.turnLeft()
        moveFn()
        turtle.turnLeft()
      end
      goingForward = not goingForward
    end
  end
end

-- 層を積み上げながら掘る
local function clearSpace(w, d, h)
  handleFloor()  -- 開始位置の足元も最初にチェック

  for layer = 1, h do
    clearLayer(w, d, layer == 1)  -- 1層目だけ床処理あり

    if layer < h then
      while turtle.detectUp() do
        turtle.digUp()
      end
      turtle.up()
    end
  end
end

print("空間を掘削中: 幅" .. width .. " 奥行き" .. depth .. " 高さ" .. height)
if floorItem then
  print("床ブロック: " .. floorItem)
end

clearSpace(width, depth, height)
print("完了しました")