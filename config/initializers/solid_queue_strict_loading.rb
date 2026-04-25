Rails.application.config.to_prepare do
  if defined?(SolidQueue::Record)
    SolidQueue::Record.strict_loading_by_default = false
  end
end
