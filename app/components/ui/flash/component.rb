class Ui::Flash::Component < ApplicationComponent
  DISMISS_AFTER = 2200

  def initialize(dismissible: true)
    super
    @dismissible = dismissible
  end

  private

  def toast_class_for(flash_type)
    case flash_type.to_s
    when "notice", "success" then "success"
    when "alert", "error" then "danger"
    else "primary"
    end
  end

  def toast_bg_class_for(flash_type)
    case flash_type.to_s
    when "notice", "success" then "bg-success"
    when "alert", "error" then "bg-destructive"
    else "bg-primary"
    end
  end

  def icon_for(flash_type)
    case flash_type.to_s
    when "notice", "success" then "check"
    when "alert", "error" then "close"
    else "sparkle"
    end
  end
end
