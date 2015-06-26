require_relative 'tf_ontology'
require_relative 'uniprot_reader'

def uniprot_acs_by_id(uniprot_ac)
  result = UniprotEntry.each_in_file(@uniprots_filename)
                      .group_by(&:uniprot_id)
                      .map{|uniprot_id, uniprots|
                        [uniprot_id, uniprots.map(&:uniprot_ac)]
                      }.to_h
  result.default_proc = ->(h,k){h[k] = [] }
  result
end

##################################

class MotifFamilyRecognizerByUniprotAC
  def initialize(tf_classification, deepness)
    @deepness = deepness
    @tf_classification = tf_classification
  end

  def subtree_groups
    @subtree_groups ||= @tf_classification.tf_groups(@deepness)
  end

  private def subtree_root_by_uniprot_ac
    @subtree_root_by_uniprot_id ||= begin
      result = Hash.new{|h,k| h[k] = [] }

      subtree_groups.each{|group_root, group_leafs|
        group_leafs.flat_map(&:uniprot_ACs).uniq.each{|uniprot_ac|
          result[uniprot_ac] << group_root
        }
      }
      result
    end
  end

  # In most cases Uniprot refers the only leaf, but in some cases it refers several leafs in different subtrees.
  # So we return an array of subfamilies
  def subfamilies_by_uniprot_ac(uniprot_ac)
    subtree_root_by_uniprot_ac[uniprot_ac]
  end

  def subfamilies_by_multiple_uniprot_acs(uniprot_acs)
    uniprot_acs.flat_map{|uniprot_ac|
      subfamilies_by_uniprot_ac(uniprot_ac)
    }.uniq
  end
end

#########################

class MotifFamilyRecognizerByUniprotID
  def initialize(motif_family_recognizer_by_uniprot_ac, uniprot_acs_by_id)
    @motif_family_recognizer_by_uniprot_ac = motif_family_recognizer_by_uniprot_ac
    @uniprot_acs_by_id = uniprot_acs_by_id
  end

  # In most cases Uniprot refers the only leaf, but in some cases it refers several leafs in different subtrees.
  # So we return an array of subfamilies
  def subfamilies_by_uniprot_id(uniprot_id)
    @motif_family_recognizer_by_uniprot_ac.subfamilies_by_multiple_uniprot_acs( uniprot_acs_by_id[uniprot_id] )
  end

  def subfamilies_by_multiple_uniprot_ids(uniprot_ids)
    uniprot_ids.flat_map{|uniprot_id|
      subfamilies_by_uniprot_id(uniprot_id)
    }.uniq
  end
end

###################################

class MotifFamilyRecognizerByMotif
  def initialize(recognizer_by_uniprot_ids, uniprots_by_motif)
    @recognizer_by_uniprot_ids = recognizer_by_uniprot_ids
    @uniprots_by_motif = uniprots_by_motif
  end

  def subfamilies_by_motif(motif)
    uniprots = @uniprots_by_motif[motif] || []
    @recognizer_by_uniprot_ids.subfamilies_by_multiple_uniprot_ids( uniprots )
  end

  def subfamilies_by_multiple_motifs(motifs)
    motifs.flat_map{|motif|
      subfamilies_by_motif(motif)
    }.uniq
  end
end
