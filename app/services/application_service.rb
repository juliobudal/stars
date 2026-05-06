class ApplicationService
  Result = Data.define(:success, :error, :data) do
    def success? = success
  end

  def self.call(...) = new(...).call

  private

  def ok(data = nil) = Result.new(success: true, error: nil, data: data)
  def fail_with(error, data: nil) = Result.new(success: false, error: error, data: data)
end
