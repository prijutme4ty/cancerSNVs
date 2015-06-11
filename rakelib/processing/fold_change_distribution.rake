def fold_change_distribution_task(input_files:, output_folder:, task_name:,
                                  only_actual_sites: false,
                                  pvalue_cutoff: 0.0005,
                                  only_substitutions_in_core: false)
  directory output_folder do
    options = []
    options << '--only-sites' << pvalue_cutoff.to_s  if only_actual_sites
    options << '--only-core'  if only_substitutions_in_core

    ruby 'fold_change_distribution.rb',
          output_folder,
          *input_files,
          *options
  end
  task task_name => output_folder
end

desc 'Fold change distribution profiles for each motif across cancer and control datasets'
task 'fold_change_distribution' => ['fold_change_distribution:Alexandrov', 'fold_change_distribution:NikZainal', 'fold_change_distribution:YeastApobec']

task 'fold_change_distribution:Alexandrov'
AlexandrovWholeGenomeCancers.each do |cancer_type|
  task 'fold_change_distribution:Alexandrov' => "fold_change_distribution:Alexandrov:#{cancer_type}"
  Configuration::Alexandrov.contexts_by_cancer_type(cancer_type).each do |context|
    task "fold_change_distribution:Alexandrov:#{cancer_type}" => "fold_change_distribution:Alexandrov:#{cancer_type}:#{context}"
    
    input_folder = File.join(LocalPaths::Secondary::Fitting, 'Alexandrov', cancer_type.to_s, context.to_s)
    input_files = Configuration::Alexandrov::Datasets.map{|dataset| File.join(input_folder, "sites_#{dataset}.txt") }
    output_folder = File.join('results/motif_statistics/fold_change_distribution', 'Alexandrov', cancer_type.to_s, context.to_s)

    fold_change_distribution_task(input_files: input_files , output_folder: output_folder , task_name: "fold_change_distribution:Alexandrov:#{cancer_type}:#{context}")
  end
end

task 'fold_change_distribution:NikZainal'
Configuration::NikZainalContexts.each do |context|
  task 'fold_change_distribution:NikZainal' => "fold_change_distribution:NikZainal:#{context}"

  input_folder = File.join(LocalPaths::Secondary::Fitting, 'NikZainal', context.to_s)
  input_files = Configuration::NikZainal::Datasets.map{|dataset| File.join(input_folder, "sites_#{dataset}.txt") }
  output_folder = File.join('results/motif_statistics/fold_change_distribution', 'NikZainal', context.to_s)

  fold_change_distribution_task(input_files: input_files , output_folder: output_folder , task_name: "fold_change_distribution:NikZainal:#{context}")
end

task 'fold_change_distribution:YeastApobec'
YeastApobecSamples.each do |sample|
  task 'fold_change_distribution:YeastApobec' => "fold_change_distribution:YeastApobec:#{sample}"
  Configuration::YeastApobec.contexts_by_cancer_type(sample).each do |context| # not actually a cancer type but sample name
    task "fold_change_distribution:YeastApobec:#{sample}" => "fold_change_distribution:YeastApobec:#{sample}:#{context}"
    
    input_folder = File.join(LocalPaths::Secondary::Fitting, 'YeastApobec', sample.to_s, context.to_s)
    input_files = Configuration::YeastApobec::Datasets.map{|dataset| File.join(input_folder, "sites_#{dataset}.txt") }
    output_folder = File.join('results/motif_statistics/fold_change_distribution', 'YeastApobec', sample.to_s, context.to_s)

    fold_change_distribution_task(input_files: input_files , output_folder: output_folder , task_name: "fold_change_distribution:YeastApobec:#{sample}:#{context}")
  end
end
