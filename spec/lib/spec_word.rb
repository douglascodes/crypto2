require 'word'
require 'unique'
require 'spec_helper'
include Unique

describe Word do

		h = {"CANALBOAT" => unique_ify("CANALBOAT").length,
		"CANALISED" => unique_ify("CANALISED").length,
		"CANALISES" => unique_ify("CANALISES").length,
		"CANALIZED" => unique_ify("CANALIZED").length,
		"CANALIZES" => unique_ify("CANALIZES").length,
		"CANAVERAL" => unique_ify("CANAVERAL").length,
		"CANCELATE" => unique_ify("CANCELATE").length,
		"CANCELING" => unique_ify("CANCELING").length,
		"CANCELOUS" => unique_ify("CANCELOUS").length,
		"CANCEROUS"	=> unique_ify("CANCEROUS").length,
		"CANDAHARS"	=> unique_ify("CANDAHARS").length,
		"CANDIDACY"	=> unique_ify("CANDIDACY").length,
		"CANDIDATE"	=> unique_ify("CANDIDATE").length
		}
		a = Array.new(28)
		a[9] = h
	let(:dict) {a}
	let(:w) { Word.new("testaword", dict)}
	
  subject {w}

  it { should respond_to( :name, :uniques, :u_length, :length, :possibles, :pattern_value)}

  it "should be able to get a list of possible words from a dictionary" do
  	w.find_possibles(dict).should eq(%w[CANCELOUS CANCEROUS])  	
  end	

  its (:length) { should eq(9)}
  its (:u_length) { should eq(8)}
  its (:pattern_value) { should eq(pattern_create("CANCELOUS"))}
end