function love.conf(t)
  t.identity = "lipanek"
  t.version = "11.4"
  t.window.title = "Lipánek"
  t.window.icon = nil
  t.window.width = 0
  t.window.height = 0
  t.window.minwidth = 720
  t.window.minheight = 480
  t.window.fullscreen = true
  t.window.fullscreentype = "desktop"

  t.modules.audio = false
  t.modules.data = false
  t.modules.joystick = false
  t.modules.math = false
  t.modules.sound = false
  t.modules.system = false
  t.modules.thread = false
  t.modules.touch = false
  t.modules.video = false
end