require_relative 'histogram_fitting'

class MotifHistogramFitter
  # Constructor accepts a hash, where keys are motif names, values ar HistogramFitters
  def initialize(fitters, raise_on_missing: true)
    @fitters = fitters
    @raise_on_missing = raise_on_missing
  end

  def fit_element(motif_name, object, &block)
    if @fitters[motif_name]
      @fitters[motif_name].fit_element(object, &block)
    elsif @raise_on_missing # otherwise do nothing
      raise 'An attept to fit an element(motif) which never was in original distribution'
    end
  end

  def goal_total
    @goal_total ||= @fitters.each_value.map(&:goal_total).inject(0, &:+)
  end

  def current_total
    @fitters.each_value.map(&:current_total).inject(0, &:+)
  end

  def fitting_percentage
    100.0 * current_total / goal_total
  end

  def fitted?
    current_total >= goal_total
  end

  def print_discrepancies(output_stream: $stderr)
    if fitted?
      output_stream.puts "Mutations fitted"
    else
      output_stream.puts "Mutations not fitted (#{fitting_percentage}%)"
      @fitters.each do |motif_name, fitter|
        if !fitter.fitted?
          output_stream.puts motif_name
          fitter.print_discrepancies(output_stream: output_stream)
        end
      end
    end
  end
end
