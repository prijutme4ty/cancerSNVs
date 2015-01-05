$:.unshift File.absolute_path('../../lib', __dir__)
require 'set'
require 'sequence_with_snp'
require 'optparse'
require 'mutation_context'
require 'site_info'
require 'breast_cancer_snv'
require 'import_information'

requested_mutation_types = nil
requested_mutation_contexts = nil
show_possible_mutation_types_and_exit = false
OptionParser.new do |opts|
  opts.banner = "Usage:\n" +
                "   #{opts.program_name} <SNV infos> <site fold-changes file> [options]\n" +
                "   <site fold-changes> | #{opts.program_name} <SNV infos> [options]"

  opts.separator 'Options:'
  opts.on('--mutation-types POSS_TYPES', "Specify possible mutation types", "(e.g. `Intronic,Promoter`)") {|value|
    requested_mutation_types = value.split(',').map(&:downcase).map(&:to_sym).to_set
  }

  opts.on('--contexts POSS_CONTEXTS',  "Specify possible mutation contexts (e.g. `TCN,NCG`)",
                                        "`N` represents any-nucleotide placeholder. `N`-s are independent",
                                        "Context is a 3nt string, with center representing a mutation" ) {|value|
    requested_mutation_contexts = value.upcase.split(',').map{|context| MutationContext.from_string(context) }
  }

  opts.on('--possible-mutation-types', 'Show possible mutation types and exit') {
    show_possible_mutation_types_and_exit = true
  }

end.parse!(ARGV)

if requested_mutation_contexts
  requested_mutation_contexts = (requested_mutation_contexts + requested_mutation_contexts.map(&:revcomp)).uniq
else
  requested_mutation_contexts = [MutationContext.new('N','N','N')]
end

raise 'Specify SNV infos file'  unless mutations_markup_filename = ARGV[0] # './source_data/SNV_infos.txt'

if show_possible_mutation_types_and_exit
  puts BreastCancerSNV.each_substitution_in_file(mutations_markup_filename).flat_map(&:mut_types).inject(Set.new, &:merge).to_a
  exit
end

snvs = BreastCancerSNV.each_substitution_in_file(mutations_markup_filename).map{|snv| [snv.variant_id, snv] }.to_h

if $stdin.tty?
  site_fold_changes_filename = ARGV[2] # './source_data/sites_cancer.txt'
  site_iterator = MutatatedSiteInfo.each_site(site_fold_changes_filename)
else
  site_iterator = MutatatedSiteInfo.each_site_in_stream($stdin)
end

site_iterator.map{|site, snv|
  [site, snvs[site.normalized_snp_name]]
}.select{|site, snv|
  (snv.cage_peak? && !snv.exon_coding?) || (snv.intronic? && !snv.in_repeat?)
}.select{|site, snv|
  requested_mutation_contexts.any?{|requested_context| requested_context.match?(snv.context_before_snv_plus_strand) }
}.select{|site, snv|
  !requested_mutation_types || requested_mutation_types.intersect?(snv.mut_types)
}.each{|site, snv|
  puts site.line
}
