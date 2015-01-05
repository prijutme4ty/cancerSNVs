require 'interval_notation'

EnsemblExon = Struct.new( :ensembl_gene_id, :ensembl_transcript_id, :exon_chr_start,
                    :exon_chr_end, :constitutive_exon, :exon_rank_in_transcript,
                    :phase, :cDNA_coding_start, :cDNA_coding_end, :genomic_coding_start,
                    :genomic_coding_end, :ensembl_exon_id, :cds_start, :cds_end,
                    :ensembl_protein_id, :chromosome, :gene_start, :gene_end,
                    :transcript_start, :transcript_end, :strand,
                    :associated_gene_name, :associated_gene_db,
                    :five_prime_utr_start, :five_prime_utr_end, :three_prime_utr_start, :three_prime_utr_end,
                    :cds_length, :transcript_count, :description, :gene_biotype ) do

  def exon_region
    if exon_chr_start != exon_chr_end
      IntervalNotation::Syntax::Long.closed_closed(exon_chr_start, exon_chr_end)
    else
      IntervalNotation::Syntax::Long.point(exon_chr_start)
    end
  end

  def transcript_region
    if transcript_start != transcript_end
      IntervalNotation::Syntax::Long.closed_closed(transcript_start, transcript_end)
    else
      IntervalNotation::Syntax::Long.point(transcript_start)
    end
  end

  def gene_region
    if gene_start != gene_end
      IntervalNotation::Syntax::Long.closed_closed(gene_start, gene_end)
    else
      IntervalNotation::Syntax::Long.point(gene_start, gene_end)
    end
  end

  def coding_part_region
    return nil  unless genomic_coding_start && genomic_coding_end
    if genomic_coding_start != genomic_coding_end
      IntervalNotation::Syntax::Long.closed_closed(genomic_coding_start, genomic_coding_end)
    else
      IntervalNotation::Syntax::Long.point(genomic_coding_start)
    end
  end


  def to_s
    [ensembl_gene_id, ensembl_transcript_id, exon_chr_start,
    exon_chr_end, constitutive_exon, exon_rank_in_transcript,
    phase, cDNA_coding_start, cDNA_coding_end, genomic_coding_start,
    genomic_coding_end, ensembl_exon_id, cds_start, cds_end,
    ensembl_protein_id, chromosome, gene_start, gene_end,
    transcript_start, transcript_end, strand,
    associated_gene_name, associated_gene_db,
    five_prime_utr_start, five_prime_utr_end,
    three_prime_utr_start, three_prime_utr_end,
    cds_length, transcript_count, description, gene_biotype].join("\t")
  end

  def self.from_string(str)
    ensembl_gene_id, ensembl_transcript_id, exon_chr_start,
    exon_chr_end, constitutive_exon, exon_rank_in_transcript,
    phase, cDNA_coding_start, cDNA_coding_end, genomic_coding_start,
    genomic_coding_end, ensembl_exon_id, cds_start, cds_end,
    ensembl_protein_id, chromosome, gene_start, gene_end,
    transcript_start, transcript_end, strand,
    associated_gene_name, associated_gene_db,
    five_prime_utr_start, five_prime_utr_end,
    three_prime_utr_start, three_prime_utr_end,
    cds_length, transcript_count, description, gene_biotype = str.chomp.split("\t")

    case constitutive_exon
    when '1'
      constitutive_exon_bool = true
    when '0'
      constitutive_exon_bool = false
    else
      raise 'Unknown constitutive exon value'
    end


    cDNA_coding_start = (cDNA_coding_start && !cDNA_coding_start.empty?) ? cDNA_coding_start.to_i : nil
    cDNA_coding_end = (cDNA_coding_end && !cDNA_coding_end.empty?) ? cDNA_coding_end.to_i : nil

    genomic_coding_start = (genomic_coding_start && !genomic_coding_start.empty?) ? genomic_coding_start.to_i : nil
    genomic_coding_end = (genomic_coding_end && !genomic_coding_end.empty?) ? genomic_coding_end.to_i : nil

    cds_start = (cds_start && !cds_start.empty?) ? cds_start.to_i : nil
    cds_end = (cds_end && !cds_end.empty?) ? cds_end.to_i : nil
    
    case strand
    when '1'
      strand_sym = :+
    when '-1'
      strand_sym = :-
    else
      raise 'Unknown Strand'
    end

    five_prime_utr_start = (five_prime_utr_start && !five_prime_utr_start.empty?) ? five_prime_utr_start.to_i : nil
    five_prime_utr_end = (five_prime_utr_end && !five_prime_utr_end.empty?) ? five_prime_utr_end.to_i : nil
    three_prime_utr_start = (three_prime_utr_start && !three_prime_utr_start.empty?) ? three_prime_utr_start.to_i : nil
    three_prime_utr_end = (three_prime_utr_end && !three_prime_utr_end.empty?) ? three_prime_utr_end.to_i : nil

    cds_length = (cds_length && !cds_length.empty?) ? cds_length.to_i : nil

    EnsemblExon.new(ensembl_gene_id.to_sym, ensembl_transcript_id.to_sym,
                    exon_chr_start.to_i, exon_chr_end.to_i,
                    constitutive_exon_bool, exon_rank_in_transcript.to_i, phase.to_i,
                    cDNA_coding_start, cDNA_coding_end, genomic_coding_start,
                    genomic_coding_end, ensembl_exon_id.to_sym, cds_start, cds_end,
                    ensembl_protein_id, chromosome.to_sym, gene_start.to_i, gene_end.to_i,
                    transcript_start.to_i, transcript_end.to_i, strand_sym,
                    associated_gene_name.to_sym, associated_gene_db.to_sym,
                    five_prime_utr_start, five_prime_utr_end,
                    three_prime_utr_start, three_prime_utr_end,
                    cds_length, transcript_count.to_i, (description || :'').to_sym, (gene_biotype || :'').to_sym)
  end

  def self.each_in_stream(stream, &block)
    stream.each_line.lazy.map{|line| EnsemblExon.from_string(line) }.each(&block)
  end

  def self.each_in_file(filename, &block)
    return enum_for(:each_in_file, filename).lazy  unless block_given?
    File.open(filename) do |f|
      f.readline # skip header
      each_in_stream(f, &block)
    end
  end
end

EnsemblExon::FileHeader = [
  "Ensembl Gene ID", "Ensembl Transcript ID", "Exon Chr Start (bp)",
  "Exon Chr End (bp)", "Constitutive Exon", "Exon Rank in Transcript",
  "phase", "cDNA coding start", "cDNA coding end", "Genomic coding start",
  "Genomic coding end", "Ensembl Exon ID", "CDS Start", "CDS End",
  "Ensembl Protein ID", "Chromosome Name", "Gene Start (bp)", "Gene End (bp)",
  "Transcript Start (bp)", "Transcript End (bp)", "Strand",
  "Associated Gene Name", "Associated Gene DB",
  "5' UTR Start", "5' UTR End", "3' UTR Start", "3' UTR End",
  "CDS Length", "Transcript count", "Description", "Gene Biotype"
]
