local Swipe = {
  _VERSION = '1.0.0',
  _DESCRIPTION = 'Swipe, a radial keyboard for Love2d',
  _URL = 'https://github.com/zombrodo/swipe',
  _LICENSE = [[
    MIT License
    Copyright (c) 2022 Jack Robinson
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
  ]]
}
Swipe.__index = Swipe

local defaultOptions = {
  -- Wheel
  wheelColour = { 0.890, 0.890, 0.890 },
  wheelRadius =  150,
  drawWheel = true,
  -- Text
  textColour = { 0.133, 0.133, 0.133 },
  textFont = love.graphics.newFont(),
  -- Selected
  selectedColour = { 0.843, 0.176, 0.631 },
  selectionRadius = 30
}

-- Merges table `b` into table `a`, such that if a key exists in `a` and `b`,
-- the value on `b` will end up in the result
local function merge(a, b)
  for k, v in pairs(b) do
    a[k] = v
  end
  return a
end

-- Returns the distance between `(x1, y1)` and `(x2, y2)`
local function distance(x1, y1, x2, y2)
  return math.sqrt(math.pow((x2 - x1), 2) + math.pow((y2 - y1), 2))
end

-- Checks to see if a point `(x, y)` is within the circle centered on `(ox, oy)`
-- with the radius `r`. Returns `true` if so, else `false`.
local function inBounds(ox, oy, x, y, r)
  return distance(ox, oy, x, y) < r
end

-- Returns a table consisting of the result of calling `fn` on every element in
-- the collection `coll`.
local function map(coll, fn)
  local result = {}
  for i, elem in ipairs(coll) do
    table.insert(result, fn(elem, i))
  end
  return result
end

-- Returns a new Swipe keyboard. Takes `(cx, cy)` the center of the keyboard,
-- a table of `initialLetters` and optionally, `options`.
--
-- Options takes:
-- - `wheelColour`: the colour of the wheel (background) - defaults to a grey
-- - `wheelRadius`: the radius of the wheel - defaults to `150`
-- - `drawWheel`: whether or not to draw the wheel - defaults to `true`
-- - `textColour`: the colour of the letters on the wheel - defaults to a black
-- - `textFont`: the font to use for the letters - defaults to Love's default
-- - `selectedColour`: the colour of the selected highlight - defaults to pink
-- - `selectionRadius`: the radius of the selection - defaults to 30
function Swipe.new(cx, cy, initialLetters, options)
  local self = setmetatable({}, Swipe)
  self.isSwiping = false
  self.swipingId = nil
  self.cx = cx
  self.cy = cy
  self.options = merge(defaultOptions, options or {})
  self.letters = {}

  self.__letters = {}
  self.__step = 0
  self.__selected = {}
  self:setLetters(initialLetters)

  return self
end

-- Set the letters of the Keyboard.
function Swipe:setLetters(letters)
  self.__step = (2 * math.pi) / #letters
  self.__letters = map(
    letters,
    function(letter, index)
      local text = love.graphics.newText(
          self.options.textFont,
          string.upper(letter)
        )

      return {
        text = text,
        size = math.max(text:getWidth(), text:getHeight()),
        letter = letter,
        selected = false,
        index = index
      }
    end
  )
end

-- Check to see if the point `(x, y)` is in bounds of the Keyboard. Returns true
-- if so, otherwise false.
function Swipe:inBounds(x, y)
  return inBounds(self.cx, self.cy, x, y, self.options.wheelRadius)
end

-- Internal: Returns the position of a 'Letter' table on the radius of the
-- wheel. Not intended to be used externally.
function Swipe:__letterPosition(letter)
  local theta = (letter.index - 1) * self.__step
  local r = self.options.wheelRadius - letter.size
  local cx = self.cx + r * math.sin(theta)
  local cy = self.cy + r * math.cos(theta)
  return cx, cy
end

-- Internal: Returns true if point `(x, y)` is in the bounds of the provided
-- `Letter` table. Not intended to be used externally.
function Swipe:__isHovering(letter, x, y)
  local cx, cy = self:__letterPosition(letter)
  return inBounds(cx, cy, x, y, self.options.selectionRadius)
end

-- Internal: Begins to track a `Letter` table as `selected`. Not intended to be
-- used externally.
function Swipe:__track(letter)
  -- Prevent double ups - either it's the first letter, or we check to make sure
  -- we're not trying to add the same index twice
  if #self.__selected == 0
    or (letter.index ~= self.__selected[#self.__selected].index
    and not letter.selected )then
    letter.selected = true
    table.insert(self.__selected, letter)
  end
end

local function asLetter(letter) return letter.letter end

-- Returns a table cotnaining the letters that are currently selected, in the
-- order in which they were selected. If the keyboard is not currently swiping,
-- returns `nil`
function Swipe:get()
  if self.isSwiping then
    return map(self.__selected, asLetter)
  end
end

-- Starts a "typing" action on the Keyboard from point `(x, y)`. Once swiping,
-- all the checks for picking which letters were hovered are enabled until
-- `stop` is called.
-- Tracks a unique `id` to ensure that the pointer being moved is the same
-- throughout the process of 'typing'. Generally this would either be the mouse
-- button pressed, or the id of the touch event.
function Swipe:start(id, x, y)
  if not self.isSwiping then
    self.isSwiping = true
    self.swipingId = id
    for i, letter in ipairs(self.__letters) do
      if self:__isHovering(letter, x, y) then
        self:__track(letter)
      end
    end
  end
end

-- Updates the swiping state. Use this if your input is a mouse. If you're using
-- touch behaviours, prefer `touchMoved`. Takes `(x, y)` as the current position
-- of the pointer.
-- Returns a table containing the letters currently selected in order.
function Swipe:moved(x, y)
  if not self.isSwiping or not self:inBounds(x, y) then
    return
  end

  for i, letter in ipairs(self.__letters) do
    if self:__isHovering(letter, x, y) then
      self:__track(letter)
    end
  end
end

-- Updates the swiping state, taking heed to the `id` of the input. Use this if
-- you are using touch behaviours, otherwise prefer 'moved'. Takes `id` of the
-- input (same as what was passed to `start`), and `(x, y)`, the current
-- position of the pointer.
function Swipe:touchMoved(id, x, y)
  if id == self.swipingId then
    self:moved(x, y)
  end
end

-- Ends a "typing" action on the keyboard. Takes in the `id` used to identify
-- the pointers provided on start. All state is cleared once this is called.
-- Returns a table containing the letters in the order they were selected.
function Swipe:stop(id)
  if self.isSwiping and id == self.swipingId then
    self.isSwiping = false
    self.swipingId = nil
    for i, letter in ipairs(self.__letters) do
      letter.selected = false
    end

    local result = self:get()

    self.__selected = {}
    return result
  end
end

-- Draws the Keyboard. Position is defined by the `options` table provided on
-- construction.
function Swipe:draw()
  love.graphics.push("all")
  -- Background
  if self.options.drawWheel then
    love.graphics.setColor(self.options.wheelColour)
    love.graphics.circle("fill", self.cx, self.cy, self.options.wheelRadius)
  end
  -- Selected Letters
  if #self.__selected > 1 then
    love.graphics.setColor(self.options.selectedColour)
    love.graphics.setLineWidth(10)
    for i = 1, #self.__selected - 1 do
      local x1, y1 = self:__letterPosition(self.__selected[i])
      local x2, y2 = self:__letterPosition(self.__selected[i + 1])
      love.graphics.line(x1, y1, x2, y2)
    end
  end
  -- Letters
  love.graphics.setColor(self.options.textColour)
  for i, letter in ipairs(self.__letters) do
    local x, y = self:__letterPosition(letter)

    if letter.selected then
      love.graphics.setColor(self.options.selectedColour)
      love.graphics.circle("fill", x, y, self.options.selectionRadius)
      love.graphics.setColor(self.options.textColour)
    end

    love.graphics.draw(
      letter.text,
      x,
      y,
      0,
      1,
      1,
      letter.text:getWidth() / 2,
      letter.text:getHeight() / 2
    )
  end
  love.graphics.pop()
end

return Swipe