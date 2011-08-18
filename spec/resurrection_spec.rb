# coding: utf-8

require 'spec_helper'

describe 'DBF data resurrection' do
  before :all do
    @dbf_file_path = File.expand_path(File.join(File.dirname(__FILE__), 'resources', 'nacionalidade.dbf'))
  end

  before :each do
    @data_resurrection = DataResurrection::Resuscitator.new(:dbf,
      test_database_settings)
  end

  context 'data acquiring' do
    it "gets data from table" do
      result = @data_resurrection.get_data(@dbf_file_path)
      result.first.should == SAMPLE_FIELDS.first
    end

    it "converts encodings" do
      result = @data_resurrection.get_data(@dbf_file_path, :win1252..:utf8)
      result[1].should == SAMPLE_FIELDS[1]
    end
  end

  context 'creating target table' do
    it 'creates table' do
      data = @data_resurrection.get_data(@dbf_file_path, :win1252..:utf8)
      create_test_database
      @data_resurrection.create_table('nacionalidade', data)
      ActiveRecord::Base.establish_connection(test_database_settings)
      class Nacionalidade < ActiveRecord::Base
        self.table_name = 'nacionalidade'
      end
      nacionalidade = Nacionalidade.new
      SAMPLE_FIELDS[0].each_key {|field| nacionalidade.should respond_to field }
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

