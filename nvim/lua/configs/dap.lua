local dap = require("dap")
local dapui = require("dapui")

-- Setup dap-ui
dapui.setup()

-- Auto open/close dap-ui
dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end
dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end
dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end
dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

-- Go debugging (requires dlv)
-- brew install delve
dap.adapters.go = {
  type = "executable",
  command = "dlv",
  args = { "dap" },
}

dap.configurations.go = {
  {
    type = "go",
    name = "Attach",
    mode = "local",
    request = "attach",
    processId = require("dap.utils").pick_process,
    showLog = false,
  },
  {
    type = "go",
    name = "Debug",
    mode = "debug",
    request = "launch",
    program = "${fileDirname}",
    env = {},
    args = {},
  },
}

-- Python debugging (requires debugpy)
-- pip install debugpy
dap.adapters.python = {
  type = "executable",
  command = "python",
  args = { "-m", "debugpy.adapter" },
}

dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch",
    program = "${file}",
    pythonPath = function()
      return os.getenv("VIRTUAL_ENV") .. "/bin/python" or "python"
    end,
  },
}
