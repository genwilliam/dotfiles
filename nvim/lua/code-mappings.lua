local M = {}

function M.tab(cmp)
  return cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.confirm { select = true }
      return
    end

    fallback()
  end, { "i", "s" })
end

function M.enter(cmp)
  return cmp.mapping(function(fallback)
    if cmp.visible() then
      cmp.confirm { select = true }
      return
    end

    fallback()
  end, { "i", "s" })
end

return M
