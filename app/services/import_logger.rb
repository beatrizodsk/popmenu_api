class ImportLogger
  def initialize
    @logs = []
    @counts = Hash.new(0)
  end

  def log_info(message)
    @logs << { level: :info, message: message, timestamp: Time.current }
    @counts[:info] += 1
  end

  def log_warning(message)
    @logs << { level: :warning, message: message, timestamp: Time.current }
    @counts[:warning] += 1
  end

  def log_error(message)
    @logs << { level: :error, message: message, timestamp: Time.current }
    @counts[:error] += 1
  end

  def summary
    { logs: @logs, counts: @counts }
  end
end
