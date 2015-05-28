require_relative 'experiment_configuration'

AlexandrovWholeGenomeCancers = SampleInfo.each_in_file(LocalPaths::Secondary::Alexandrov::SamplesSummary)
                                .group_by(&:cancer_type)
                                .select{|cancer_type, samples| samples.any?(&:whole_genome?) }
                                .map{|cancer_type, samples| cancer_type }
                                .to_a.sort

task :load_genome_markup do
  GENOME_MARKUP ||= GENOME_MARKUP_LOADER.load_markup
end

import *FileList['rakelib/processing/*.rake']
