# coding: utf-8

require 'spec_helper'

describe 'DBF data resurrection' do
  before :each do
    @data_resurrection = DataResurrection::Resuscitator.new(:dbf, :active_record => :data_settings)
  end

  context 'data acquiring' do
    it "gets data from table" do
      dbf_file_path = File.expand_path(File.join(File.dirname(__FILE__), 'resources', 'nacionalidade.dbf'))
      result = @data_resurrection.get_data(dbf_file_path)
      result.first.should == SAMPLE_FIELDS.first
    end
  end
end

SAMPLE_FIELDS = [
  {
    'nr' => 3,
    'ds' => 'ALEMANHA',
    'ad_patr' => 'ALEMAO',
    'cd_nac' => 30
  },
  {
    'nr' => 4,
    'ds' => 'ESTADOS UNIDOS DA AMÉRICA',
    'ad_patr' => 'AMERICANO',
    'cd_nac' => 36
  }
]

