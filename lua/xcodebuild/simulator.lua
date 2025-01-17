local notifications = require("xcodebuild.notifications")
local projectConfig = require("xcodebuild.project_config")
local xcode = require("xcodebuild.xcode")
local logs = require("xcodebuild.logs")
local config = require("xcodebuild.config").options
local events = require("xcodebuild.events")
local helpers = require("xcodebuild.helpers")
local util = require("xcodebuild.util")

local M = {
  currentJobId = nil,
}

function M.run_app(waitForDebugger, callback)
  if not helpers.validate_project() then
    return
  end

  if config.logs.auto_close_on_app_launch then
    logs.close_logs()
  end

  local settings = projectConfig.settings

  if settings.platform == "macOS" then
    notifications.send("Launching application...")
    local path = settings.appPath .. "/Contents/MacOS/" .. settings.productName

    M.currentJobId = vim.fn.jobstart(path, { detach = true })
    notifications.send("Application has been launched")
    util.call(callback)
  else
    if settings.productName then
      xcode.kill_app(settings.productName)
    end

    notifications.send("Installing application...")
    M.currentJobId = xcode.install_app(settings.destination, settings.appPath, function()
      M.currentJobId = xcode.launch_app(settings.destination, settings.bundleId, waitForDebugger, function()
        notifications.send("Application has been launched")
        events.application_launched()
        util.call(callback)
      end)
    end)
  end
end

function M.boot_simulator(callback)
  if not helpers.validate_project() then
    return
  end

  if projectConfig.settings.platform == "macOS" then
    notifications.send_error("Your selected device is macOS.")
    return
  end

  notifications.send("Booting simulator...")
  xcode.boot_simulator(projectConfig.settings.destination, function()
    notifications.send("Simulator booted")
    util.call(callback)
  end)
end

function M.uninstall_app(callback)
  if not helpers.validate_project() then
    return
  end

  local settings = projectConfig.settings
  if settings.platform == "macOS" then
    notifications.send_error("macOS apps cannot be uninstalled")
    return
  end

  notifications.send("Uninstalling application...")
  M.currentJobId = xcode.uninstall_app(settings.destination, settings.bundleId, function()
    notifications.send("Application has been uninstalled")
    util.call(callback)
  end)
end

return M
