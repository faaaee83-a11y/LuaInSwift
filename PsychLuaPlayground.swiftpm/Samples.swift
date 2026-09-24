let sampleScripts: [(String, String)] = [
("basic.lua", #"""
-- コールバックと、数値・文字列の扱いを確かめる
local flash = 0

function onCreate()
  debugPrint('create: ' .. songName .. ' bpm=' .. bpm)
end

function onCreatePost()
  setProperty('health', 1.5)
end

function onStepHit()
  flash = flash + 1
end

function onBeatHit()
  if curBeat % 4 == 0 then
    triggerEvent('Add Camera Zoom', '0.015', '0.03')
  end
end

function onUpdate(elapsed)
  setProperty('camHUD.alpha', 0.5 + 0.5 * math.sin(getSongPosition() / 500))
  setProperty('health', getProperty('health') - elapsed * 0.01)
end
"""#),
("sprites.lua", #"""
-- スプライト、タイマー、Tween と、そのコールバックを確かめる
function onCreate()
  makeLuaSprite('bg', 'stageback', -600, -200)
  setObjectCamera('bg', 'camGame')
  addLuaSprite('bg', false)
  runTimer('start', 1)
end

function onTimerCompleted(tag, loops, loopsLeft)
  if tag == 'start' then
    doTweenX('bgX', 'bg', 0, 1, 'quadOut')
    doTweenAlpha('bgA', 'bg', 0.5, 1, 'linear')
    playSound('scrollMenu', 0.8)
  end
end

function onTweenCompleted(tag)
  if tag == 'bgX' then debugPrint('tween done') end
end
"""#),
]
