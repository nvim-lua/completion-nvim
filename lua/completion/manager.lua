local manager = {}

------------------------------------------------------------------------
--                    plugin variables and states                     --
------------------------------------------------------------------------

-- Global variables table, accessed in scripts as manager.variable_name
manager = {
  -- not used for now...
  -- canTryCompletion = true,
  -- chains              = {},     -- here we store validated chains for each buffer
  -- activeChain         = nil,    -- currently used completion chain

  insertChar          = false,  -- flag for InsertCharPre event, turn off imediately when performing completion
  insertLeave         = false,  -- flag for InsertLeave, prevent every completion if true
  textHover           = false,  -- handle auto hover
  selected            = -1,     -- handle selected items in v:complete-items for auto hover
  changedTick         = 0,      -- handle changeTick
  confirmedCompletion = false,  -- flag for manual confirmation of completion
  forceCompletion     = false,  -- flag for forced manual completion/source change
  chainIndex          = 1,      -- current index in loaded chain
}

-- reset manager
-- called on insertEnter
function manager.init()
  -- manager.activeChain         = nil
  manager.insertLeave         = false
  -- manager.canTryCompletion    = true
  manager.insertChar          = false
  manager.textHover           = false
  manager.selected            = -1
  manager.confirmedCompletion = false
  manager.forceCompletion     = false
  manager.chainIndex          = 1
end

-- TODO: change this when we have proper logger
function manager.debug()
  print(
  'canTryCompletion = '    .. vim.inspect(manager.canTryCompletion)    .. '\n' ..
  'insertChar = '          .. vim.inspect(manager.insertChar)          .. '\n' ..
  'insertLeave = '         .. vim.inspect(manager.insertLeave)         .. '\n' ..
  'textHover = '           .. vim.inspect(manager.textHover)           .. '\n' ..
  'selected = '            .. vim.inspect(manager.selected)            .. '\n' ..
  'changedTick = '         .. vim.inspect(manager.changedTick)         .. '\n' ..
  'confirmedCompletion = ' .. vim.inspect(manager.confirmedCompletion) .. '\n' ..
  'forceCompletion = '     .. vim.inspect(manager.forceCompletion)     .. '\n' ..
  'chainIndex = '          .. vim.inspect(manager.chainIndex)
  )
end

return manager
