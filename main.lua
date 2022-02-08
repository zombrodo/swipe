local Swipe = require "swipe"

local font = love.graphics.newFont("assets/wakuwaku.otf", 36)

local keyboard = Swipe.new(
  love.graphics.getWidth() / 2,
  (love.graphics.getHeight() / 2) + 40,
  { "a", "n", "g", "l", "u", "r", "a" },
  {
    textFont = font
  }
)

local lastWord = love.graphics.newText(font, "")

function love.draw()
  keyboard:draw()
  love.graphics.draw(
    lastWord,
    love.graphics.getWidth() / 2,
    40,
    0,
    1,
    1,
    lastWord:getWidth() / 2,
    lastWord:getHeight() / 2
  )
end

-- =============================================================================
-- Mouse
-- =============================================================================

function love.mousepressed(x, y, button)
  keyboard:start(button, x, y)

  local text = keyboard:get()
  if text then
    lastWord:set(keyboard:get())
  end
end

function love.mousemoved(x, y)
  keyboard:moved(x, y)

  local text = keyboard:get()
  if text then
    lastWord:set(keyboard:get())
  end
end

function love.mousereleased(x, y, button)
  local result = keyboard:stop(button)
  if result then
    lastWord:set(result)
  end
end

-- =============================================================================
-- Touch
-- =============================================================================

function love.touchpressed(id, x, y)
  keyboard:start(id, x, y)

  local text = keyboard:get()
  if text then
    lastWord:set(keyboard:get())
  end
end

function love.touchmoved(id, x, y)
  keyboard:touchMoved(id, x, y)

  local text = keyboard:get()
  if text then
    lastWord:set(keyboard:get())
  end
end

function love.touchreleased(id, x, y)
  local result = keyboard:stop(id)
  if result then
    lastWord:set(result)
  end
end


